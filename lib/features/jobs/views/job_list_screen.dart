import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../tenant/bloc/tenant_bloc.dart';
import '../../tenant/bloc/tenant_state.dart';
import '../bloc/job_bloc.dart';
import '../bloc/job_event.dart';
import '../bloc/job_state.dart';
import 'widgets/job_card.dart';

class JobListScreen extends StatefulWidget {
  const JobListScreen({super.key});

  @override
  State<JobListScreen> createState() => _JobListScreenState();
}

class _JobListScreenState extends State<JobListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<JobBloc>().add(const FetchJobsEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String text) {
    context.read<JobBloc>().add(FetchJobsEvent(query: text.trim().isEmpty ? null : text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tenantState = context.watch<TenantBloc>().state;
    final tenant = tenantState is TenantSelected ? tenantState.tenant : null;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            if (tenant?.logoUrl != null && tenant!.logoUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: CachedNetworkImage(
                  imageUrl: tenant.logoUrl!,
                  height: 30,
                  width: 30,
                  fit: BoxFit.contain,
                  errorWidget: (_, _, _) => const Icon(Icons.apartment, size: 24),
                ),
              )
            else
              const Icon(Icons.apartment, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tenant?.name ?? 'SmartHire Career',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${tenant?.code ?? 'portal'}.smarthire.top',
                    style: TextStyle(fontSize: 11, color: theme.colorScheme.outline),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Đổi công ty',
            icon: const Icon(Icons.swap_horiz_rounded),
            onPressed: () {
              context.go('/select-tenant');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            color: theme.scaffoldBackgroundColor,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm vị trí tuyển dụng, kỹ năng...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _onSearch('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              ),
              onSubmitted: _onSearch,
            ),
          ),

          // Main Jobs Content
          Expanded(
            child: BlocBuilder<JobBloc, JobState>(
              builder: (context, state) {
                if (state is JobLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is JobError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline_rounded, size: 48, color: theme.colorScheme.error),
                          const SizedBox(height: 12),
                          Text(
                            state.message,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => context.read<JobBloc>().add(const FetchJobsEvent()),
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Thử lại'),
                          ),
                        ],
                      ),
                    ),
                  );
                } else if (state is JobLoaded) {
                  final jobs = state.jobs;
                  if (jobs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off_rounded, size: 54, color: theme.colorScheme.outline),
                          const SizedBox(height: 12),
                          const Text(
                            'Hiện chưa có vị trí tuyển dụng nào phù hợp.',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Vui lòng quay lại sau hoặc thử từ khóa khác.',
                            style: TextStyle(fontSize: 13, color: theme.colorScheme.outline),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<JobBloc>().add(RefreshJobsEvent());
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: jobs.length,
                      itemBuilder: (context, index) {
                        final job = jobs[index];
                        return JobCard(
                          job: job,
                          onTap: () {
                            context.push('/jobs/${job.id}', extra: job);
                          },
                        );
                      },
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}

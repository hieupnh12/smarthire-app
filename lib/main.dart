import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'core/di/injection.dart';
import 'core/routes/app_router.dart';
import 'core/storage/storage_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_event.dart';
import 'features/jobs/bloc/job_bloc.dart';
import 'features/tenant/bloc/tenant_bloc.dart';
import 'features/tenant/bloc/tenant_event.dart';
import 'features/tenant/bloc/tenant_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo các dịch vụ nền tảng (Storage, Network, Repositories)
  await initDependencies();

  runApp(const SmartHireApp());
}

class SmartHireApp extends StatefulWidget {
  const SmartHireApp({super.key});

  @override
  State<SmartHireApp> createState() => _SmartHireAppState();
}

class _SmartHireAppState extends State<SmartHireApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final storageService = getIt<StorageService>();
    _router = createAppRouter(storageService);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<TenantBloc>(
          create: (_) => getIt<TenantBloc>()..add(LoadCachedTenantEvent()),
        ),
        BlocProvider<AuthBloc>(
          create: (_) => getIt<AuthBloc>()..add(CheckAuthStatusEvent()),
        ),
        BlocProvider<JobBloc>(
          create: (_) => getIt<JobBloc>(),
        ),
      ],
      child: BlocBuilder<TenantBloc, TenantState>(
        builder: (context, tenantState) {
          // Dynamic theme theo màu thương hiệu của công ty (nếu có cấu hình)
          Color? brandColor;
          if (tenantState is TenantSelected) {
            brandColor = AppTheme.parseHexColor(tenantState.tenant.primaryColor);
          }

          return MaterialApp.router(
            title: 'SmartHire Candidate',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.getTheme(dynamicPrimary: brandColor),
            routerConfig: _router,
          );
        },
      ),
    );
  }
}

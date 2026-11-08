import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/job_repository.dart';
import 'job_event.dart';
import 'job_state.dart';

class JobBloc extends Bloc<JobEvent, JobState> {
  final JobRepository _repository;

  JobBloc(this._repository) : super(JobInitial()) {
    on<FetchJobsEvent>(_onFetchJobs);
    on<RefreshJobsEvent>(_onRefreshJobs);
  }

  Future<void> _onFetchJobs(FetchJobsEvent event, Emitter<JobState> emit) async {
    emit(JobLoading());
    try {
      final jobs = await _repository.getPublicJobs(search: event.query);
      emit(JobLoaded(jobs: jobs, query: event.query));
    } catch (e) {
      emit(JobError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onRefreshJobs(RefreshJobsEvent event, Emitter<JobState> emit) async {
    final currentQuery = state is JobLoaded ? (state as JobLoaded).query : null;
    try {
      final jobs = await _repository.getPublicJobs(search: currentQuery);
      emit(JobLoaded(jobs: jobs, query: currentQuery));
    } catch (e) {
      emit(JobError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}

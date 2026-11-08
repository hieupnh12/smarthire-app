import 'package:equatable/equatable.dart';
import '../models/job_model.dart';

abstract class JobState extends Equatable {
  const JobState();

  @override
  List<Object?> get props => [];
}

class JobInitial extends JobState {}

class JobLoading extends JobState {}

class JobLoaded extends JobState {
  final List<JobModel> jobs;
  final String? query;

  const JobLoaded({required this.jobs, this.query});

  @override
  List<Object?> get props => [jobs, query];
}

class JobError extends JobState {
  final String message;

  const JobError(this.message);

  @override
  List<Object?> get props => [message];
}

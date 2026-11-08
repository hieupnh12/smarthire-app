import 'package:equatable/equatable.dart';

abstract class JobEvent extends Equatable {
  const JobEvent();

  @override
  List<Object?> get props => [];
}

class FetchJobsEvent extends JobEvent {
  final String? query;

  const FetchJobsEvent({this.query});

  @override
  List<Object?> get props => [query];
}

class RefreshJobsEvent extends JobEvent {}

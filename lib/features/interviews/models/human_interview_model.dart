import 'package:equatable/equatable.dart';
import '../../../core/utils/json_parsers.dart';

class InterviewParticipantModel extends Equatable {
  final int userId;
  final String name;
  final String email;
  final String role;

  const InterviewParticipantModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
  });

  factory InterviewParticipantModel.fromJson(Map<String, dynamic> json) {
    return InterviewParticipantModel(
      userId: parseInt(json['userId']),
      name: json['name'] as String? ?? 'Người phỏng vấn',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'CO_INTERVIEWER',
    );
  }

  @override
  List<Object?> get props => [userId, name, email, role];
}

class InterviewConfigurationModel extends Equatable {
  final String? rubric;
  final String? provider;
  final String? emailTemplate;
  final String? notes;
  final bool attachCalendar;
  final String? rescheduleReason;
  final DateTime? requestedStart;
  final DateTime? requestedEnd;

  const InterviewConfigurationModel({
    this.rubric,
    this.provider,
    this.emailTemplate,
    this.notes,
    this.attachCalendar = false,
    this.rescheduleReason,
    this.requestedStart,
    this.requestedEnd,
  });

  factory InterviewConfigurationModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const InterviewConfigurationModel();
    return InterviewConfigurationModel(
      rubric: json['rubric'] as String?,
      provider: json['provider'] as String?,
      emailTemplate: json['emailTemplate'] as String?,
      notes: json['notes'] as String?,
      attachCalendar: json['attachCalendar'] as bool? ?? false,
      rescheduleReason: json['rescheduleReason'] as String?,
      requestedStart: parseDateTime(json['requestedStart']),
      requestedEnd: parseDateTime(json['requestedEnd']),
    );
  }

  @override
  List<Object?> get props => [
        rubric,
        provider,
        emailTemplate,
        notes,
        attachCalendar,
        rescheduleReason,
        requestedStart,
        requestedEnd,
      ];
}

class HumanInterviewModel extends Equatable {
  final int id;
  final int applicationId;
  final int jobId;
  final String jobTitle;
  final int candidateId;
  final String candidateName;
  final String candidateEmail;
  final String round;
  final String mode;
  final String status;
  final DateTime start;
  final DateTime end;
  final String? meetingUrl;
  final String? location;
  final InterviewConfigurationModel configuration;
  final List<InterviewParticipantModel> participants;

  const HumanInterviewModel({
    required this.id,
    required this.applicationId,
    required this.jobId,
    required this.jobTitle,
    required this.candidateId,
    required this.candidateName,
    required this.candidateEmail,
    required this.round,
    required this.mode,
    required this.status,
    required this.start,
    required this.end,
    this.meetingUrl,
    this.location,
    this.configuration = const InterviewConfigurationModel(),
    this.participants = const [],
  });

  factory HumanInterviewModel.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    final parsedStart = parseDateTime(json['start']) ?? now;
    final parsedEnd = parseDateTime(json['end']) ?? parsedStart.add(const Duration(hours: 1));
    final rawParticipants = json['participants'];
    final parsedParticipants = rawParticipants is List
        ? rawParticipants
            .whereType<Map<String, dynamic>>()
            .map(InterviewParticipantModel.fromJson)
            .toList()
        : const <InterviewParticipantModel>[];

    return HumanInterviewModel(
      id: parseInt(json['id']),
      applicationId: parseInt(json['applicationId']),
      jobId: parseInt(json['jobId']),
      jobTitle: json['jobTitle'] as String? ?? 'Phỏng vấn tuyển dụng',
      candidateId: parseInt(json['candidateId']),
      candidateName: json['candidateName'] as String? ?? '',
      candidateEmail: json['candidateEmail'] as String? ?? '',
      round: json['round'] as String? ?? 'TECHNICAL',
      mode: json['mode'] as String? ?? 'ONLINE',
      status: json['status'] as String? ?? 'PROPOSED',
      start: parsedStart,
      end: parsedEnd,
      meetingUrl: json['meetingUrl'] as String?,
      location: json['location'] as String?,
      configuration: InterviewConfigurationModel.fromJson(
        json['configuration'] is Map<String, dynamic>
            ? json['configuration'] as Map<String, dynamic>
            : null,
      ),
      participants: parsedParticipants,
    );
  }

  int get durationMinutes {
    final mins = end.difference(start).inMinutes;
    return mins > 0 ? mins : 0;
  }

  bool get isInactive => status == 'CANCELLED' || status == 'DONE';

  bool isUpcoming(DateTime now) => !end.isBefore(now) && !isInactive;

  bool canConfirm(DateTime now) => status == 'PROPOSED' && start.isAfter(now);

  bool canReschedule(DateTime now) =>
      (status == 'PROPOSED' || status == 'CONFIRMED' || status == 'RESCHEDULE_REQUESTED') &&
      start.isAfter(now);

  @override
  List<Object?> get props => [
        id,
        applicationId,
        jobId,
        jobTitle,
        candidateId,
        candidateName,
        candidateEmail,
        round,
        mode,
        status,
        start,
        end,
        meetingUrl,
        location,
        configuration,
        participants,
      ];
}

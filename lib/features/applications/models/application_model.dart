import 'package:equatable/equatable.dart';

class ApplicationModel extends Equatable {
  final int id;
  final int jobId;
  final String jobTitle;
  final String status;
  final String? stageName;
  final DateTime? createdAt;
  final double? matchingScore;

  const ApplicationModel({
    required this.id,
    required this.jobId,
    required this.jobTitle,
    required this.status,
    this.stageName,
    this.createdAt,
    this.matchingScore,
  });

  factory ApplicationModel.fromJson(Map<String, dynamic> json) {
    DateTime? created;
    if (json['createdAt'] != null) {
      try {
        created = DateTime.parse(json['createdAt'] as String);
      } catch (_) {}
    }

    return ApplicationModel(
      id: json['id'] as int? ?? 0,
      jobId: json['jobId'] as int? ?? 0,
      jobTitle: json['jobTitle'] as String? ?? 'Vị trí ứng tuyển',
      status: json['status'] as String? ?? 'APPLIED',
      stageName: json['stageName'] as String?,
      createdAt: created,
      matchingScore: (json['matchingScore'] is num)
          ? (json['matchingScore'] as num).toDouble()
          : null,
    );
  }

  @override
  List<Object?> get props => [id, jobId, jobTitle, status, stageName, createdAt, matchingScore];
}

import '../../../core/utils/json_parsers.dart';

class MobileConfigModel {
  final String minSupportedVersion;
  final String latestVersion;
  final bool forceUpdate;
  final String updateUrl;
  final bool maintenanceMode;
  final Map<String, bool> features;
  final DateTime? serverTime;

  const MobileConfigModel({
    required this.minSupportedVersion,
    required this.latestVersion,
    required this.forceUpdate,
    required this.updateUrl,
    required this.maintenanceMode,
    required this.features,
    this.serverTime,
  });

  factory MobileConfigModel.fromJson(Map<String, dynamic> json) {
    final rawFeatures = json['features'] as Map<String, dynamic>? ?? {};
    final featureMap = rawFeatures.map((k, v) => MapEntry(k, v == true));

    return MobileConfigModel(
      minSupportedVersion: json['minSupportedVersion']?.toString() ?? '1.0.0',
      latestVersion: json['latestVersion']?.toString() ?? '1.0.0',
      forceUpdate: json['forceUpdate'] == true,
      updateUrl: json['updateUrl']?.toString() ?? '',
      maintenanceMode: json['maintenanceMode'] == true,
      features: featureMap,
      serverTime: parseDateTime(json['serverTime']),
    );
  }
}

class NextInterviewItemModel {
  final int id;
  final String title;
  final String interviewType;
  final String status;
  final DateTime? scheduledStart;
  final DateTime? scheduledEnd;
  final String? meetingLink;

  const NextInterviewItemModel({
    required this.id,
    required this.title,
    required this.interviewType,
    required this.status,
    this.scheduledStart,
    this.scheduledEnd,
    this.meetingLink,
  });

  factory NextInterviewItemModel.fromJson(Map<String, dynamic> json) {
    return NextInterviewItemModel(
      id: parseInt(json['id']),
      title: json['title']?.toString() ?? '',
      interviewType: json['interviewType']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      scheduledStart: parseDateTime(json['scheduledStart']),
      scheduledEnd: parseDateTime(json['scheduledEnd']),
      meetingLink: json['meetingLink']?.toString(),
    );
  }
}

class RecentApplicationItemModel {
  final int id;
  final int jobId;
  final String jobTitle;
  final String status;
  final DateTime? appliedAt;

  const RecentApplicationItemModel({
    required this.id,
    required this.jobId,
    required this.jobTitle,
    required this.status,
    this.appliedAt,
  });

  factory RecentApplicationItemModel.fromJson(Map<String, dynamic> json) {
    return RecentApplicationItemModel(
      id: parseInt(json['id']),
      jobId: parseInt(json['jobId']),
      jobTitle: json['jobTitle']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      appliedAt: parseDateTime(json['appliedAt']),
    );
  }
}

class MobileDashboardModel {
  final String candidateName;
  final String candidateEmail;
  final int totalApplications;
  final int activeApplications;
  final int upcomingInterviewsCount;
  final int pendingAssessmentsCount;
  final int unreadNotificationsCount;
  final NextInterviewItemModel? nextInterview;
  final RecentApplicationItemModel? recentApplication;

  const MobileDashboardModel({
    required this.candidateName,
    required this.candidateEmail,
    required this.totalApplications,
    required this.activeApplications,
    required this.upcomingInterviewsCount,
    required this.pendingAssessmentsCount,
    required this.unreadNotificationsCount,
    this.nextInterview,
    this.recentApplication,
  });

  factory MobileDashboardModel.fromJson(Map<String, dynamic> json) {
    final nextRaw = json['nextInterview'];
    final recentRaw = json['recentApplication'];

    return MobileDashboardModel(
      candidateName: json['candidateName']?.toString() ?? '',
      candidateEmail: json['candidateEmail']?.toString() ?? '',
      totalApplications: parseInt(json['totalApplications']),
      activeApplications: parseInt(json['activeApplications']),
      upcomingInterviewsCount: parseInt(json['upcomingInterviewsCount']),
      pendingAssessmentsCount: parseInt(json['pendingAssessmentsCount']),
      unreadNotificationsCount: parseInt(json['unreadNotificationsCount']),
      nextInterview: nextRaw is Map<String, dynamic> ? NextInterviewItemModel.fromJson(nextRaw) : null,
      recentApplication: recentRaw is Map<String, dynamic> ? RecentApplicationItemModel.fromJson(recentRaw) : null,
    );
  }
}

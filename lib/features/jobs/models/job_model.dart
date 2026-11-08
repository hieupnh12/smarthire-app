import 'package:equatable/equatable.dart';

class JobModel extends Equatable {
  final int id;
  final String title;
  final String? description;
  final String? responsibilities;
  final String? benefits;
  final String? location;
  final String? employmentType;
  final String? workMode;
  final String? department;
  final DateTime? deadline;
  final String? salary;
  final double? minYearsExperience;
  final String? educationLevel;
  final List<String> skills;
  final bool acceptingApplications;

  const JobModel({
    required this.id,
    required this.title,
    this.description,
    this.responsibilities,
    this.benefits,
    this.location,
    this.employmentType,
    this.workMode,
    this.department,
    this.deadline,
    this.salary,
    this.minYearsExperience,
    this.educationLevel,
    this.skills = const [],
    this.acceptingApplications = true,
  });

  factory JobModel.fromJson(Map<String, dynamic> json) {
    DateTime? deadlineDate;
    if (json['deadline'] != null) {
      try {
        deadlineDate = DateTime.parse(json['deadline'] as String);
      } catch (_) {}
    }

    List<String> parsedSkills = [];
    if (json['skills'] is List) {
      parsedSkills = (json['skills'] as List).map((e) => e.toString()).toList();
    }

    return JobModel(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? 'Vị trí tuyển dụng',
      description: json['description'] as String?,
      responsibilities: json['responsibilities'] as String?,
      benefits: json['benefits'] as String?,
      location: json['location'] as String?,
      employmentType: json['employmentType'] as String?,
      workMode: json['workMode'] as String?,
      department: json['department'] as String?,
      deadline: deadlineDate,
      salary: json['salary'] as String?,
      minYearsExperience: (json['minYearsExperience'] is num)
          ? (json['minYearsExperience'] as num).toDouble()
          : null,
      educationLevel: json['educationLevel'] as String?,
      skills: parsedSkills,
      acceptingApplications: json['acceptingApplications'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        responsibilities,
        benefits,
        location,
        employmentType,
        workMode,
        department,
        deadline,
        salary,
        minYearsExperience,
        educationLevel,
        skills,
        acceptingApplications,
      ];
}

import 'package:equatable/equatable.dart';
import '../../../core/utils/json_parsers.dart';

class ApplicationModel extends Equatable {
  final int id;
  final int jobId;
  final String jobTitle;
  final String status;
  final String? stageName;
  final DateTime? createdAt;
  final double? matchingScore;
  final String? jobLocation;
  final String? jobDepartment;
  final String? jobWorkMode;
  final String? jobEmploymentType;
  final bool withdrawable;

  const ApplicationModel({
    required this.id,
    required this.jobId,
    required this.jobTitle,
    required this.status,
    this.stageName,
    this.createdAt,
    this.matchingScore,
    this.jobLocation,
    this.jobDepartment,
    this.jobWorkMode,
    this.jobEmploymentType,
    this.withdrawable = false,
  });

  factory ApplicationModel.fromJson(Map<String, dynamic> json) {
    return ApplicationModel(
      id: parseInt(json['id']),
      jobId: parseInt(json['jobId']),
      jobTitle: json['jobTitle'] as String? ?? 'Vị trí ứng tuyển',
      status: json['status'] as String? ?? 'NEW',
      stageName: json['stageName'] as String?,
      createdAt: parseDateTime(json['createdAt']),
      matchingScore: parseDouble(json['matchingScore']),
      jobLocation: json['jobLocation'] as String?,
      jobDepartment: json['jobDepartment'] as String?,
      jobWorkMode: json['jobWorkMode'] as String?,
      jobEmploymentType: json['jobEmploymentType'] as String?,
      withdrawable: json['withdrawable'] as bool? ?? false,
    );
  }

  List<String> get metaTags => [
        if (jobDepartment != null && jobDepartment!.trim().isNotEmpty) jobDepartment!.trim(),
        if (jobLocation != null && jobLocation!.trim().isNotEmpty) jobLocation!.trim(),
        if (jobWorkMode != null && jobWorkMode!.trim().isNotEmpty) jobWorkMode!.trim(),
        if (jobEmploymentType != null && jobEmploymentType!.trim().isNotEmpty)
          jobEmploymentType!.trim(),
      ];

  @override
  List<Object?> get props => [
        id,
        jobId,
        jobTitle,
        status,
        stageName,
        createdAt,
        matchingScore,
        jobLocation,
        jobDepartment,
        jobWorkMode,
        jobEmploymentType,
        withdrawable,
      ];
}

class CvRefModel extends Equatable {
  final int id;
  final String originalFilename;
  final String status;
  final DateTime? createdAt;
  final DateTime? retainUntil;
  final bool expired;

  const CvRefModel({
    required this.id,
    required this.originalFilename,
    required this.status,
    this.createdAt,
    this.retainUntil,
    this.expired = false,
  });

  factory CvRefModel.fromJson(Map<String, dynamic> json) {
    return CvRefModel(
      id: parseInt(json['id']),
      originalFilename: json['originalFilename'] as String? ?? 'CV.pdf',
      status: json['status'] as String? ?? '',
      createdAt: parseDateTime(json['createdAt']),
      retainUntil: parseDateTime(json['retainUntil']),
      expired: json['expired'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [id, originalFilename, status, createdAt, retainUntil, expired];
}

class ApplicationHistoryModel extends Equatable {
  final String? fromStatus;
  final String toStatus;
  final String? note;
  final DateTime? createdAt;
  final int? changedBy;

  const ApplicationHistoryModel({
    this.fromStatus,
    required this.toStatus,
    this.note,
    this.createdAt,
    this.changedBy,
  });

  factory ApplicationHistoryModel.fromJson(Map<String, dynamic> json) {
    return ApplicationHistoryModel(
      fromStatus: json['fromStatus'] as String?,
      toStatus: json['toStatus'] as String? ?? '',
      note: json['note'] as String?,
      createdAt: parseDateTime(json['createdAt']),
      changedBy: json['changedBy'] is num ? (json['changedBy'] as num).toInt() : null,
    );
  }

  @override
  List<Object?> get props => [fromStatus, toStatus, note, createdAt, changedBy];
}

class RoundItemModel extends Equatable {
  final String status;
  final double? score;
  final double? threshold;
  final bool? passed;
  final double? weight;

  const RoundItemModel({
    required this.status,
    this.score,
    this.threshold,
    this.passed,
    this.weight,
  });

  factory RoundItemModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const RoundItemModel(status: 'NOT_STARTED');
    return RoundItemModel(
      status: json['status'] as String? ?? 'NOT_STARTED',
      score: parseDouble(json['score']),
      threshold: parseDouble(json['threshold']),
      passed: json['passed'] as bool?,
      weight: parseDouble(json['weight']),
    );
  }

  @override
  List<Object?> get props => [status, score, threshold, passed, weight];
}

class ScreeningRoundsModel extends Equatable {
  final RoundItemModel cv;
  final RoundItemModel aiInterview;
  final RoundItemModel assessment;
  final DateTime? aiInterviewInvitedAt;

  const ScreeningRoundsModel({
    required this.cv,
    required this.aiInterview,
    required this.assessment,
    this.aiInterviewInvitedAt,
  });

  factory ScreeningRoundsModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const ScreeningRoundsModel(
        cv: RoundItemModel(status: 'NOT_STARTED'),
        aiInterview: RoundItemModel(status: 'NOT_STARTED'),
        assessment: RoundItemModel(status: 'NOT_STARTED'),
      );
    }
    return ScreeningRoundsModel(
      cv: RoundItemModel.fromJson(json['cv'] as Map<String, dynamic>?),
      aiInterview: RoundItemModel.fromJson(json['aiInterview'] as Map<String, dynamic>?),
      assessment: RoundItemModel.fromJson(json['assessment'] as Map<String, dynamic>?),
      aiInterviewInvitedAt: parseDateTime(json['aiInterviewInvitedAt']),
    );
  }

  @override
  List<Object?> get props => [cv, aiInterview, assessment, aiInterviewInvitedAt];
}

class GateScoreModel extends Equatable {
  final double score;
  final bool passed;
  final bool complete;
  final double? cvScore;
  final double? aiInterviewScore;
  final double? assessmentScore;
  final double? passThreshold;

  const GateScoreModel({
    required this.score,
    required this.passed,
    required this.complete,
    this.cvScore,
    this.aiInterviewScore,
    this.assessmentScore,
    this.passThreshold,
  });

  factory GateScoreModel.fromJson(Map<String, dynamic> json) {
    return GateScoreModel(
      score: parseDouble(json['score']) ?? 0,
      passed: json['passed'] as bool? ?? false,
      complete: json['complete'] as bool? ?? false,
      cvScore: parseDouble(json['cvScore']),
      aiInterviewScore: parseDouble(json['aiInterviewScore']),
      assessmentScore: parseDouble(json['assessmentScore']),
      passThreshold: parseDouble(json['passThreshold']),
    );
  }

  @override
  List<Object?> get props => [
        score,
        passed,
        complete,
        cvScore,
        aiInterviewScore,
        assessmentScore,
        passThreshold,
      ];
}

class ApplicationDetailModel extends Equatable {
  final int id;
  final int jobId;
  final String jobTitle;
  final String status;
  final DateTime? createdAt;
  final DateTime? withdrawnAt;
  final String? rejectReason;
  final String? withdrawReason;
  final String? cvScreeningStatus;
  final String? screeningMode;
  final bool withdrawable;
  final String? jobLocation;
  final String? jobDepartment;
  final String? jobWorkMode;
  final String? jobEmploymentType;
  final List<CvRefModel> cvs;
  final List<ApplicationHistoryModel> history;
  final ScreeningRoundsModel? rounds;
  final GateScoreModel? gateScore;

  const ApplicationDetailModel({
    required this.id,
    required this.jobId,
    required this.jobTitle,
    required this.status,
    this.createdAt,
    this.withdrawnAt,
    this.rejectReason,
    this.withdrawReason,
    this.cvScreeningStatus,
    this.screeningMode,
    this.withdrawable = false,
    this.jobLocation,
    this.jobDepartment,
    this.jobWorkMode,
    this.jobEmploymentType,
    this.cvs = const [],
    this.history = const [],
    this.rounds,
    this.gateScore,
  });

  factory ApplicationDetailModel.fromJson(Map<String, dynamic> json) {
    final rawCvs = json['cvs'];
    final rawHistory = json['history'];

    return ApplicationDetailModel(
      id: parseInt(json['id']),
      jobId: parseInt(json['jobId']),
      jobTitle: json['jobTitle'] as String? ?? 'Vị trí ứng tuyển',
      status: json['status'] as String? ?? 'NEW',
      createdAt: parseDateTime(json['createdAt']),
      withdrawnAt: parseDateTime(json['withdrawnAt']),
      rejectReason: json['rejectReason'] as String?,
      withdrawReason: json['withdrawReason'] as String?,
      cvScreeningStatus: json['cvScreeningStatus'] as String?,
      screeningMode: json['screeningMode'] as String?,
      withdrawable: json['withdrawable'] as bool? ?? false,
      jobLocation: json['jobLocation'] as String?,
      jobDepartment: json['jobDepartment'] as String?,
      jobWorkMode: json['jobWorkMode'] as String?,
      jobEmploymentType: json['jobEmploymentType'] as String?,
      cvs: rawCvs is List
          ? rawCvs.whereType<Map<String, dynamic>>().map(CvRefModel.fromJson).toList()
          : const [],
      history: rawHistory is List
          ? rawHistory
              .whereType<Map<String, dynamic>>()
              .map(ApplicationHistoryModel.fromJson)
              .toList()
          : const [],
      rounds: json['rounds'] is Map<String, dynamic>
          ? ScreeningRoundsModel.fromJson(json['rounds'] as Map<String, dynamic>)
          : null,
      gateScore: json['gateScore'] is Map<String, dynamic>
          ? GateScoreModel.fromJson(json['gateScore'] as Map<String, dynamic>)
          : null,
    );
  }

  List<String> get metaTags => [
        if (jobDepartment != null && jobDepartment!.trim().isNotEmpty) jobDepartment!.trim(),
        if (jobLocation != null && jobLocation!.trim().isNotEmpty) jobLocation!.trim(),
        if (jobWorkMode != null && jobWorkMode!.trim().isNotEmpty) jobWorkMode!.trim(),
        if (jobEmploymentType != null && jobEmploymentType!.trim().isNotEmpty)
          jobEmploymentType!.trim(),
      ];

  @override
  List<Object?> get props => [
        id,
        jobId,
        jobTitle,
        status,
        createdAt,
        withdrawnAt,
        rejectReason,
        withdrawReason,
        cvScreeningStatus,
        screeningMode,
        withdrawable,
        jobLocation,
        jobDepartment,
        jobWorkMode,
        jobEmploymentType,
        cvs,
        history,
        rounds,
        gateScore,
      ];
}

class CvEvaluationModel extends Equatable {
  final double score;
  final double? threshold;
  final bool passed;
  final String? explanation;
  final String? candidateAdvice;
  final List<String> matchedSkills;
  final List<String> partialSkills;
  final List<String> missingSkills;
  final List<String> requiredMissingSkills;
  final double? requiredYears;
  final double? candidateYears;
  final String? requiredEducation;
  final String? candidateEducation;

  const CvEvaluationModel({
    required this.score,
    this.threshold,
    required this.passed,
    this.explanation,
    this.candidateAdvice,
    this.matchedSkills = const [],
    this.partialSkills = const [],
    this.missingSkills = const [],
    this.requiredMissingSkills = const [],
    this.requiredYears,
    this.candidateYears,
    this.requiredEducation,
    this.candidateEducation,
  });

  factory CvEvaluationModel.fromJson(Map<String, dynamic> json) {
    return CvEvaluationModel(
      score: parseDouble(json['score']) ?? 0,
      threshold: parseDouble(json['threshold']),
      passed: json['passed'] as bool? ?? false,
      explanation: json['explanation'] as String?,
      candidateAdvice: json['candidateAdvice'] as String?,
      matchedSkills: parseStringList(json['matchedSkills']),
      partialSkills: parseStringList(json['partialSkills']),
      missingSkills: parseStringList(json['missingSkills']),
      requiredMissingSkills: parseStringList(json['requiredMissingSkills']),
      requiredYears: parseDouble(json['requiredYears']),
      candidateYears: parseDouble(json['candidateYears']),
      requiredEducation: json['requiredEducation'] as String?,
      candidateEducation: json['candidateEducation'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        score,
        threshold,
        passed,
        explanation,
        candidateAdvice,
        matchedSkills,
        partialSkills,
        missingSkills,
        requiredMissingSkills,
        requiredYears,
        candidateYears,
        requiredEducation,
        candidateEducation,
      ];
}

class AiInterviewEvaluationModel extends Equatable {
  final int id;
  final int attemptNumber;
  final String status;
  final double? score;
  final double? passingScore;
  final bool? passed;
  final DateTime? completedAt;
  final String? summary;
  final String? strengths;
  final String? weaknesses;
  final Map<String, double> criteria;

  const AiInterviewEvaluationModel({
    required this.id,
    required this.attemptNumber,
    required this.status,
    this.score,
    this.passingScore,
    this.passed,
    this.completedAt,
    this.summary,
    this.strengths,
    this.weaknesses,
    this.criteria = const {},
  });

  factory AiInterviewEvaluationModel.fromJson(Map<String, dynamic> json) {
    final rawCriteria = json['criteria'];
    final parsedCriteria = <String, double>{};
    if (rawCriteria is Map) {
      rawCriteria.forEach((key, value) {
        final score = parseDouble(value);
        if (score != null) {
          parsedCriteria[key.toString()] = score;
        }
      });
    }

    return AiInterviewEvaluationModel(
      id: parseInt(json['id']),
      attemptNumber: parseInt(json['attemptNumber'], fallback: 1),
      status: json['status'] as String? ?? 'CREATED',
      score: parseDouble(json['score']),
      passingScore: parseDouble(json['passingScore']),
      passed: json['passed'] as bool?,
      completedAt: parseDateTime(json['completedAt']),
      summary: json['summary'] as String?,
      strengths: json['strengths'] as String?,
      weaknesses: json['weaknesses'] as String?,
      criteria: parsedCriteria,
    );
  }

  @override
  List<Object?> get props => [
        id,
        attemptNumber,
        status,
        score,
        passingScore,
        passed,
        completedAt,
        summary,
        strengths,
        weaknesses,
        criteria,
      ];
}

class AssessmentEvaluationModel extends Equatable {
  final int id;
  final String testTitle;
  final String status;
  final double? score;
  final double? passingScore;
  final bool? passed;
  final DateTime? submittedAt;

  const AssessmentEvaluationModel({
    required this.id,
    required this.testTitle,
    required this.status,
    this.score,
    this.passingScore,
    this.passed,
    this.submittedAt,
  });

  factory AssessmentEvaluationModel.fromJson(Map<String, dynamic> json) {
    return AssessmentEvaluationModel(
      id: parseInt(json['id']),
      testTitle: json['testTitle'] as String? ?? 'Bài kiểm tra năng lực',
      status: json['status'] as String? ?? 'NOT_STARTED',
      score: parseDouble(json['score']),
      passingScore: parseDouble(json['passingScore']),
      passed: json['passed'] as bool?,
      submittedAt: parseDateTime(json['submittedAt']),
    );
  }

  @override
  List<Object?> get props => [id, testTitle, status, score, passingScore, passed, submittedAt];
}

class CandidateEvaluationModel extends Equatable {
  final CvEvaluationModel? cv;
  final List<AiInterviewEvaluationModel> aiInterviews;
  final List<AssessmentEvaluationModel> assessments;

  const CandidateEvaluationModel({
    this.cv,
    this.aiInterviews = const [],
    this.assessments = const [],
  });

  factory CandidateEvaluationModel.fromJson(Map<String, dynamic> json) {
    final rawAi = json['aiInterviews'];
    final rawAssessments = json['assessments'];

    return CandidateEvaluationModel(
      cv: json['cv'] is Map<String, dynamic>
          ? CvEvaluationModel.fromJson(json['cv'] as Map<String, dynamic>)
          : null,
      aiInterviews: rawAi is List
          ? rawAi
              .whereType<Map<String, dynamic>>()
              .map(AiInterviewEvaluationModel.fromJson)
              .toList()
          : const [],
      assessments: rawAssessments is List
          ? rawAssessments
              .whereType<Map<String, dynamic>>()
              .map(AssessmentEvaluationModel.fromJson)
              .toList()
          : const [],
    );
  }

  @override
  List<Object?> get props => [cv, aiInterviews, assessments];
}

class SubmissionQuestionModel extends Equatable {
  final int id;
  final String questionText;
  final String questionType;
  final int points;
  final int questionOrder;

  const SubmissionQuestionModel({
    required this.id,
    required this.questionText,
    required this.questionType,
    required this.points,
    required this.questionOrder,
  });

  factory SubmissionQuestionModel.fromJson(Map<String, dynamic> json) {
    return SubmissionQuestionModel(
      id: parseInt(json['id']),
      questionText: json['questionText'] as String? ?? '',
      questionType: json['questionType'] as String? ?? 'MULTIPLE_CHOICE',
      points: parseInt(json['points']),
      questionOrder: parseInt(json['questionOrder'], fallback: 1),
    );
  }

  @override
  List<Object?> get props => [id, questionText, questionType, points, questionOrder];
}

class SubmissionAnswerModel extends Equatable {
  final int questionId;
  final double? score;
  final double? suggestedScore;
  final Map<String, dynamic>? evaluation;

  const SubmissionAnswerModel({
    required this.questionId,
    this.score,
    this.suggestedScore,
    this.evaluation,
  });

  factory SubmissionAnswerModel.fromJson(Map<String, dynamic> json) {
    return SubmissionAnswerModel(
      questionId: parseInt(json['questionId']),
      score: parseDouble(json['score']),
      suggestedScore: parseDouble(json['suggestedScore']),
      evaluation: json['evaluation'] is Map<String, dynamic>
          ? json['evaluation'] as Map<String, dynamic>
          : null,
    );
  }

  bool get hasEvaluation =>
      evaluation != null || score != null || suggestedScore != null;

  @override
  List<Object?> get props => [questionId, score, suggestedScore, evaluation];
}

class AssessmentSubmissionDetailModel extends Equatable {
  final int id;
  final String title;
  final List<SubmissionQuestionModel> questions;
  final List<SubmissionAnswerModel> answers;

  const AssessmentSubmissionDetailModel({
    required this.id,
    required this.title,
    this.questions = const [],
    this.answers = const [],
  });

  factory AssessmentSubmissionDetailModel.fromJson(Map<String, dynamic> json) {
    final rawQuestions = json['questions'];
    final rawAnswers = json['answers'];
    return AssessmentSubmissionDetailModel(
      id: parseInt(json['id']),
      title: json['title'] as String? ?? '',
      questions: rawQuestions is List
          ? rawQuestions
              .whereType<Map<String, dynamic>>()
              .map(SubmissionQuestionModel.fromJson)
              .toList()
          : const [],
      answers: rawAnswers is List
          ? rawAnswers
              .whereType<Map<String, dynamic>>()
              .map(SubmissionAnswerModel.fromJson)
              .toList()
          : const [],
    );
  }

  @override
  List<Object?> get props => [id, title, questions, answers];
}

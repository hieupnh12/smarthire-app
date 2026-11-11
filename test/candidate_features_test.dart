import 'package:flutter_test/flutter_test.dart';
import 'package:smarthire_app/features/applications/models/application_model.dart';
import 'package:smarthire_app/features/applications/utils/application_labels.dart';
import 'package:smarthire_app/features/interviews/models/human_interview_model.dart';
import 'package:smarthire_app/features/interviews/utils/interview_labels.dart';
import 'package:smarthire_app/features/notifications/models/notification_models.dart';

void main() {
  group('HumanInterviewModel & InterviewLabels', () {
    test('parses InterviewView JSON and evaluates upcoming/confirm/reschedule flags', () {
      final futureStart = DateTime.now().toUtc().add(const Duration(days: 2));
      final futureEnd = futureStart.add(const Duration(minutes: 45));

      final interview = HumanInterviewModel.fromJson({
        'id': 12,
        'applicationId': 34,
        'jobId': 56,
        'jobTitle': 'Senior Flutter Engineer',
        'candidateId': 78,
        'candidateName': 'Nguyen Van A',
        'candidateEmail': 'a@example.com',
        'round': 'TECHNICAL',
        'mode': 'ONLINE',
        'status': 'PROPOSED',
        'start': futureStart.toIso8601String(),
        'end': futureEnd.toIso8601String(),
        'meetingUrl': '/meet/human/12',
        'location': null,
        'configuration': {
          'rubric': 'TECHNICAL',
          'provider': 'SMARTHIRE',
          'emailTemplate': 'STANDARD',
          'notes': 'Chuẩn bị demo sản phẩm.',
          'attachCalendar': true,
        },
        'participants': [
          {
            'userId': 1,
            'name': 'Tran Tech Lead',
            'email': 'lead@acme.com',
            'role': 'LEAD',
          },
        ],
      });

      final now = DateTime.now();
      expect(interview.durationMinutes, equals(45));
      expect(interview.isUpcoming(now), isTrue);
      expect(interview.canConfirm(now), isTrue);
      expect(interview.canReschedule(now), isTrue);
      expect(interview.participants.first.role, equals('LEAD'));
      expect(
        InterviewLabels.resolveMeetingUrl(interview.meetingUrl, 'acme'),
        equals('https://acme.smarthire.top/meet/human/12'),
      );
      expect(InterviewLabels.statusLabel(interview.status), equals('Chờ xác nhận'));
    });

    test('cancelled or past interviews cannot be confirmed or rescheduled', () {
      final pastStart = DateTime.now().toUtc().subtract(const Duration(days: 1));
      final pastEnd = pastStart.add(const Duration(hours: 1));

      final pastInterview = HumanInterviewModel.fromJson({
        'id': 20,
        'applicationId': 34,
        'jobId': 56,
        'jobTitle': 'Backend Engineer',
        'round': 'CULTURE',
        'mode': 'OFFLINE',
        'status': 'CONFIRMED',
        'start': pastStart.toIso8601String(),
        'end': pastEnd.toIso8601String(),
        'location': 'Tầng 10, Hà Nội',
      });

      final now = DateTime.now();
      expect(pastInterview.isUpcoming(now), isFalse);
      expect(pastInterview.canConfirm(now), isFalse);
      expect(pastInterview.canReschedule(now), isFalse);
    });
  });

  group('Notification Models', () {
    test('normalizes missing notification categories to enabled defaults', () {
      final normalized = NotificationCategoryMeta.normalizePreferences([
        const NotificationPreferenceModel(
          category: 'HUMAN_INTERVIEW',
          webEnabled: true,
          emailEnabled: false,
        ),
      ]);

      expect(normalized.length, equals(4));
      final human = normalized.firstWhere((p) => p.category == 'HUMAN_INTERVIEW');
      final app = normalized.firstWhere((p) => p.category == 'APPLICATION');
      expect(human.webEnabled, isTrue);
      expect(human.emailEnabled, isFalse);
      expect(app.webEnabled, isTrue);
      expect(app.emailEnabled, isTrue);
    });

    test('extracts navigation path from payloadJson', () {
      final item = NotificationItemModel.fromJson({
        'id': 5,
        'type': 'INTERVIEW_INVITE',
        'title': 'Lịch phỏng vấn mới',
        'payloadJson': '{"path":"/candidate/applications/42"}',
      });

      expect(item.isRead, isFalse);
      expect(item.extractPath(), equals('/applications/42'));
    });
  });

  group('ApplicationDetailModel, CandidateEvaluationModel & Labels', () {
    test('parses application detail with history and round scores', () {
      final detail = ApplicationDetailModel.fromJson({
        'id': 99,
        'jobId': 15,
        'jobTitle': 'Backend Java Developer',
        'status': 'ASSESSMENT',
        'withdrawable': true,
        'jobDepartment': 'Engineering',
        'jobLocation': 'Hà Nội',
        'history': [
          {
            'fromStatus': 'NEW',
            'toStatus': 'ASSESSMENT',
            'note': 'CV passed screening; opened the assessment round',
            'createdAt': '2026-11-09T10:00:00Z',
          },
          {
            'fromStatus': null,
            'toStatus': 'NEW',
            'note': 'Applied',
            'createdAt': '2026-11-09T09:00:00Z',
          },
        ],
        'rounds': {
          'cv': {'status': 'PASSED', 'score': 82.5, 'threshold': 70, 'passed': true},
          'aiInterview': {'status': 'INVITED', 'score': null, 'threshold': 70, 'passed': null},
          'assessment': {'status': 'GRADED', 'score': 90, 'threshold': 60, 'passed': true},
        },
      });

      expect(detail.history.length, equals(2));
      expect(detail.rounds?.cv.passed, isTrue);
      expect(detail.rounds?.cv.score, equals(82.5));
      expect(detail.rounds?.assessment.score, equals(90.0));
      expect(ApplicationLabels.pipelineIndex(detail.status), equals(2));
    });

    test('parses candidate round evaluations across CV, AI interview and assessment', () {
      final evaluation = CandidateEvaluationModel.fromJson({
        'cv': {
          'score': 82.5,
          'threshold': 70,
          'passed': true,
          'explanation': 'Kinh nghiệm Java & Spring Boot phù hợp.',
          'matchedSkills': ['Java', 'Spring Boot'],
          'partialSkills': ['Docker'],
          'missingSkills': ['Kubernetes'],
          'requiredMissingSkills': [],
          'requiredYears': 2,
          'candidateYears': 3,
        },
        'aiInterviews': [
          {
            'id': 101,
            'attemptNumber': 1,
            'status': 'SCORED',
            'score': 78.0,
            'passingScore': 70.0,
            'passed': true,
            'summary': 'Trả lời rõ ràng và logic.',
            'strengths': 'Hiểu sâu về Spring.',
            'weaknesses': 'Cần nói ngắn gọn hơn.',
            'criteria': {
              'TECHNICAL_KNOWLEDGE': 80,
              'COMMUNICATION': 76,
            },
          },
        ],
        'assessments': [
          {
            'id': 202,
            'testTitle': 'Java Backend Test',
            'status': 'GRADED',
            'score': 90,
            'passingScore': 60,
            'passed': true,
          },
        ],
      });

      expect(evaluation.cv?.matchedSkills, contains('Spring Boot'));
      expect(evaluation.aiInterviews.single.criteria['TECHNICAL_KNOWLEDGE'], equals(80.0));
      expect(evaluation.assessments.single.testTitle, equals('Java Backend Test'));
      expect(
        ApplicationLabels.localizeAiComment('All test cases passed successfully.'),
        equals('Tất cả các ca kiểm thử đều vượt qua thành công.'),
      );
    });
  });
}


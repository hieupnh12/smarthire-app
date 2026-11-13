import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smarthire_app/features/assessments/views/candidate_assessment_list_screen.dart';
import 'package:smarthire_app/features/auth/bloc/auth_bloc.dart';
import 'package:smarthire_app/features/auth/bloc/auth_event.dart';
import 'package:smarthire_app/features/auth/models/user_model.dart';
import 'package:smarthire_app/features/auth/repositories/auth_repository.dart';
import 'package:smarthire_app/features/auth/views/login_screen.dart';
import 'package:smarthire_app/features/tenant/bloc/tenant_bloc.dart';
import 'package:smarthire_app/features/tenant/models/tenant_info.dart';
import 'package:smarthire_app/features/tenant/repositories/tenant_repository.dart';

class _FakeAuthRepository implements AuthRepository {
  UserModel? userToLogin;
  Object? errorToThrow;

  @override
  UserModel? getCachedUser() => null;

  @override
  Future<UserModel?> checkCurrentUser() async => null;

  @override
  Future<UserModel?> loginWithGoogle() async {
    if (errorToThrow != null) throw errorToThrow!;
    return userToLogin;
  }

  @override
  Future<void> logout() async {}
}

class _FakeTenantRepository implements TenantRepository {
  @override
  Future<void> clearTenant() async {}

  @override
  TenantInfo? getCachedTenant() => const TenantInfo(code: 'se36', name: 'Se36');

  @override
  Future<TenantInfo> lookupTenant(String code) async =>
      TenantInfo(code: code, name: code);
}

void main() {
  testWidgets(
    'CandidateAssessmentListScreen hides login prompt once AuthBloc is Authenticated',
    (tester) async {
      final repo = _FakeAuthRepository()
        ..userToLogin = const UserModel(
          id: 1,
          email: 'candidate@example.com',
          fullName: 'Nguyen Van A',
          role: 'CANDIDATE',
          workspace: 'CANDIDATE',
        );
      final authBloc = AuthBloc(repo);

      await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: const MaterialApp(
            home: CandidateAssessmentListScreen(),
          ),
        ),
      );

      expect(find.text('Chế độ Khách · Chưa đăng nhập trên app'), findsOneWidget);
      expect(find.text('Đăng nhập ngay'), findsOneWidget);

      await tester.runAsync(() async {
        authBloc.add(GoogleLoginEvent());
        await Future<void>.delayed(Duration.zero);
      });
      await tester.pump();

      expect(find.text('Đăng nhập ngay'), findsNothing);
      expect(find.text('Luyện Phỏng Vấn với AI'), findsOneWidget);
      expect(find.text('Bài Test Năng Lực Kỹ Thuật (FE-05)'), findsOneWidget);
    },
  );

  testWidgets(
    'LoginScreen displays persistent inline failure banner when Google Sign-In throws',
    (tester) async {
      final repo = _FakeAuthRepository()
        ..errorToThrow = Exception(
          'Đăng nhập Google thất bại do ứng dụng Android chưa khớp SHA-1.',
        );
      final authBloc = AuthBloc(repo);
      final tenantBloc = TenantBloc(_FakeTenantRepository());

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: authBloc),
            BlocProvider<TenantBloc>.value(value: tenantBloc),
          ],
          child: const MaterialApp(home: LoginScreen()),
        ),
      );

      await tester.runAsync(() async {
        authBloc.add(GoogleLoginEvent());
        await Future<void>.delayed(Duration.zero);
      });
      await tester.pump();

      final bannerContainer = find.ancestor(
        of: find.text('Đăng nhập chưa thành công (vẫn ở chế độ Khách)'),
        matching: find.byType(Container),
      ).first;
      expect(
        find.text('Đăng nhập chưa thành công (vẫn ở chế độ Khách)'),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: bannerContainer,
          matching: find.text('Đăng nhập Google thất bại do ứng dụng Android chưa khớp SHA-1.'),
        ),
        findsOneWidget,
      );
    },
  );
}

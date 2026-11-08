import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/google_auth_service.dart';
import '../network/dio_client.dart';
import '../storage/storage_service.dart';
import '../../features/applications/repositories/application_repository.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/repositories/auth_repository.dart';
import '../../features/jobs/bloc/job_bloc.dart';
import '../../features/jobs/repositories/job_repository.dart';
import '../../features/tenant/bloc/tenant_bloc.dart';
import '../../features/tenant/repositories/tenant_repository.dart';

final getIt = GetIt.instance;

Future<void> initDependencies() async {
  // Local storage
  final prefs = await SharedPreferences.getInstance();
  const secureStorage = FlutterSecureStorage();

  getIt.registerSingleton<StorageService>(StorageService(prefs, secureStorage));

  // Network & Auth Services
  getIt.registerLazySingleton<DioClient>(() => DioClient(getIt<StorageService>()));
  getIt.registerLazySingleton<GoogleAuthService>(() => GoogleAuthService());

  // Repositories
  getIt.registerLazySingleton<TenantRepository>(
    () => TenantRepository(getIt<DioClient>(), getIt<StorageService>()),
  );
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepository(
      getIt<DioClient>(),
      getIt<StorageService>(),
      getIt<GoogleAuthService>(),
    ),
  );
  getIt.registerLazySingleton<JobRepository>(
    () => JobRepository(getIt<DioClient>()),
  );
  getIt.registerLazySingleton<ApplicationRepository>(
    () => ApplicationRepository(getIt<DioClient>()),
  );

  // Blocs
  getIt.registerFactory<TenantBloc>(() => TenantBloc(getIt<TenantRepository>()));
  getIt.registerFactory<AuthBloc>(() => AuthBloc(getIt<AuthRepository>()));
  getIt.registerFactory<JobBloc>(() => JobBloc(getIt<JobRepository>()));
}

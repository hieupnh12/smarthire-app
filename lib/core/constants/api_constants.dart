class ApiConstants {
  ApiConstants._();

  static const String productionBaseUrl = 'https://smarthire.top/api/v1';
  static const String localReverseBaseUrl = 'http://localhost:8080/api/v1';
  static const String emulatorBaseUrl = 'http://10.0.2.2:8080/api/v1';
  static const String lanBaseUrl = 'http://172.16.0.26:8080/api/v1';

  // Mặc định dùng Production để hoạt động ngay trên điện thoại thật qua Wi-Fi/4G
  static const String defaultBaseUrl = productionBaseUrl;

  static const String tenantHeader = 'X-Tenant-ID';
  static const String authHeader = 'Authorization';

  // Google OAuth Web Client ID (dùng chung với backend để lấy idToken hợp lệ)
  static const String googleServerClientId =
      '271448374588-fbke1m9munvcv9lp1ss498rae2d2pj2p.apps.googleusercontent.com';

  // Master Endpoints
  static const String masterTenantCheckSubdomain = '/master/tenants/check-subdomain';

  // Public Tenant Endpoints
  static const String publicLanding = '/public/landing';
  static const String publicJobs = '/public/jobs';

  // Candidate Auth Endpoints
  static const String candidateGoogleLogin = '/tenant/auth/google';
  static const String candidateRefresh = '/tenant/auth/refresh';
  static const String candidateProfile = '/tenant/auth/me';
  static const String candidateLogout = '/tenant/auth/logout';

  // Application Endpoints
  static const String candidateApplications = '/applications';
  static const String uploadCv = '/cvs/upload';

  // Assessment, AI Interview & Human Interview
  static const String candidateAssessments = '/assessments';
  static const String candidateInterviews = '/interviews';
  static const String candidateMyInterviews = '/interviews/mine';
  static const String candidateSubmissions = '/submissions';

  // Notifications
  static const String notifications = '/notifications';
  static const String notificationPreferences = '/notifications/preferences';
}

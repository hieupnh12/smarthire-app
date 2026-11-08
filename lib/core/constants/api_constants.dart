class ApiConstants {
  ApiConstants._();

  // Mặc định cho kết nối USB qua adb reverse hoặc máy thật cùng mạng Wi-Fi
  static const String defaultBaseUrl = 'http://localhost:8080/api/v1';
  static const String lanBaseUrl = 'http://172.20.10.3:8080/api/v1';
  static const String productionBaseUrl = 'https://smarthire.top/api/v1';

  static const String tenantHeader = 'X-Tenant-ID';
  static const String authHeader = 'Authorization';

  // Google OAuth Web Client ID (dùng chung với backend để lấy idToken hợp lệ)
  static const String googleServerClientId =
      '271448374588-fbke1m9munvcv9lp1ss498rae2d2pj2p.apps.googleusercontent.com';

  // Master Endpoints
  static const String masterTenantCheckSubdomain = '/master/tenants/check-subdomain';

  // Public Tenant Endpoints
  static const String publicLanding = '/public/landing';
  static const String publicJobs = '/jobs/public';

  // Candidate Auth Endpoints
  static const String candidateGoogleLogin = '/tenant/auth/google';
  static const String candidateProfile = '/tenant/auth/me';
  static const String candidateLogout = '/tenant/auth/logout';

  // Application Endpoints
  static const String candidateApplications = '/applications';
  static const String uploadCv = '/cvs/upload';

  // Assessment & AI Interview
  static const String candidateAssessments = '/assessments';
  static const String candidateInterviews = '/interviews';
}

/// Development-only configuration.
/// ⚠️ Set [skipAuth] to false before building for production!
class DevConfig {
  /// Toggle to skip login/register screen during development.
  static const bool skipAuth = true;

  /// Pre-generated 365-day token for dev user (PATIENT role).
  /// User: Sophal Taingchhay | Email: sophaltangchhay@gmail.com | Phone: +855855962579460
  static const String devAccessToken =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIyNjI5ZTM5Ny00OTU1LTQ2ZjUtYTk5OS0xODEwM2QzYWE5ZDkiLCJwaG9uZU51bWJlciI6Iis4NTU4NTU5NjI1Nzk0NjAiLCJyb2xlIjoiUEFUSUVOVCIsImlhdCI6MTc3Mjk3ODU1OCwiZXhwIjoxODA0NTE0NTU4fQ.VLBTstS47EC17og9vNlWHMNzFxlha_-YSRES07wbln0';

  /// Refresh token from last login (valid 7 days — re-login if expired).
  static const String devRefreshToken =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIyNjI5ZTM5Ny00OTU1LTQ2ZjUtYTk5OS0xODEwM2QzYWE5ZDkiLCJwaG9uZU51bWJlciI6Iis4NTU4NTU5NjI1Nzk0NjAiLCJyb2xlIjoiUEFUSUVOVCIsImlhdCI6MTc3Mjk3ODU1OCwiZXhwIjoxNzczNTgzMzU4fQ.Q8gKGZ-F43jjVREm0_PoyL8lJmZPqcNU5UFOp8COLe4';

  /// Dev user profile — mirrors what the backend returns.
  static const Map<String, dynamic> devUser = {
    'id': '2629e397-4955-46f5-a999-18103d3aa9d9',
    'role': 'PATIENT',
    'firstName': 'Sophal',
    'lastName': 'Taingchhay',
    'fullName': null,
    'phoneNumber': '+855855962579460',
    'email': 'sophaltangchhay@gmail.com',
    'gender': 'FEMALE',
    'dateOfBirth': '2004-10-02T00:00:00.000Z',
    'language': 'KHMER',
    'theme': 'LIGHT',
    'accountStatus': 'ACTIVE',
    'gracePeriodMinutes': 30,
    'failedLoginAttempts': 0,
  };
}

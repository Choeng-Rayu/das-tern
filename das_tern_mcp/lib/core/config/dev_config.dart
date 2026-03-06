/// Development-only configuration.
/// ⚠️ Set [skipAuth] to false before building for production!
class DevConfig {
  /// Toggle to skip login/register screen during development.
  static const bool skipAuth = true;

  /// Pre-generated 365-day token for dev user (PATIENT role).
  /// User: Dev User | Email: dev@dev.com | Phone: +85500000000
  static const String devAccessToken =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI1NDBiMjYyZi1kZjE0LTQxM2UtOWNmOS0wOWQxZGIyOWQ3MTgiLCJwaG9uZU51bWJlciI6Iis4NTUwMDAwMDAwMCIsInJvbGUiOiJQQVRJRU5UIiwiaWF0IjoxNzcxOTk5OTUyLCJleHAiOjE4MDM1MzU5NTJ9.45d6ZNyL6YijqxvCBT0hYOplrKjrjYTX4Y_Bmb5MXWI';

  /// Refresh token from last login (valid 7 days — re-login if expired).
  static const String devRefreshToken =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI1NDBiMjYyZi1kZjE0LTQxM2UtOWNmOS0wOWQxZGIyOWQ3MTgiLCJwaG9uZU51bWJlciI6Iis4NTUwMDAwMDAwMCIsInJvbGUiOiJQQVRJRU5UIiwiaWF0IjoxNzcxOTk5OTQ0LCJleHAiOjE3NzI2MDQ3NDR9.8ovk92luVnVdcI94fYyOlyPbJgFwcX79vCHdFmuATho';

  /// Dev user profile — mirrors what the backend returns.
  static const Map<String, dynamic> devUser = {
    'id': '540b262f-df14-413e-9cf9-09d1db29d718',
    'role': 'PATIENT',
    'firstName': 'Dev',
    'lastName': 'User',
    'fullName': null,
    'phoneNumber': '+85500000000',
    'email': 'dev@dev.com',
    'gender': 'MALE',
    'dateOfBirth': '1990-01-01T00:00:00.000Z',
    'language': 'KHMER',
    'theme': 'LIGHT',
    'accountStatus': 'PENDING_VERIFICATION',
    'gracePeriodMinutes': 30,
    'failedLoginAttempts': 0,
  };
}

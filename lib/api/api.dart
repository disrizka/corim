class ApiConfig {
  static const String baseUrl = "https://corim-api.eon.id/";
  static const String contentTypeJson = "application/json";
}

class Endpoints {
  static const String login = "auth/login";
  static const String refreshToken = "auth/refresh-token";
  static const String clients = "clients";
}

class StorageKeys {
  static const String accessToken = "access_token";
  static const String refreshToken = "refresh_token";
  static const String loginTime = "login_time";
  static const String userName = "user_name";
}

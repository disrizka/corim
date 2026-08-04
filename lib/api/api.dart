class ApiConfig {
  static const String baseUrl = "https://corim-api.eon.id/";
  static const String contentTypeJson = "application/json";

  static const String storageBaseUrl = '${baseUrl}storage/';
}

class Endpoints {
  static const String login = "auth/login";
  static const String refreshToken = "auth/refresh-token";
  static const String profile = "profile";
  static const String clients = "clients";
  static String clientDetail(String id) => "clients/$id";
  static const String projects = "projects";
  static String projectDetail(String id) => "projects/$id";
  static String projectSalesStatusQuotations(String id) =>
      "projects/$id/sales-status-quotations";
  static String projectDeliveryStatus(String id) =>
      "projects/$id/delivery-status";

  static const String notifications = "notifications";
  static String notificationDetail(String id) => "notifications/$id";
  static String notificationAction(String id) => "notifications/$id/action";

  static const String expensesEmployee = "finance/expenses-employee";
  static String expensesEmployeeDetail(String id) =>
      "finance/expenses-employee/$id";
}

class StorageKeys {
  static const String accessToken = "access_token";
  static const String refreshToken = "refresh_token";
  static const String loginTime = "login_time";
  static const String userName = "user_name";
}

class AppConstants {
  static const String baseUrl = 'https://tontineapp-backend-33pp.onrender.com/api';

  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userTypeKey = 'user_type';
  static const String userDataKey = 'user_data';

  // Assets
  static const String logoPath = 'assets/images/logo.png';

  static const int otpLength = 6;
  static const int otpResendSeconds = 60;
  static const int defaultPageSize = 20;

  static const Map<String, String> contributionTypes = {
    'MONEY': 'Argent',
  };

  static const Map<String, String> frequencyUnits = {
    'DAYS': 'Jours',
    'WEEKS': 'Semaines',
    'MONTHS': 'Mois',
  };

  static const Map<String, String> contributionStatuses = {
    'PENDING': 'En attente',
    'RECEIVED': 'Reçue',
    'LATE': 'En retard',
  };
}
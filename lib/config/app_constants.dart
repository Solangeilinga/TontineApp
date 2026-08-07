class AppConstants {
  static const String baseUrl = 'https://tontineapp-backend-33pp.onrender.com/api';

  // ⚠️ À VÉRIFIER : je ne connais pas l'URL exacte de la page politique de
  // confidentialité sur ton site vitrine — je n'ai que son contenu (que tu
  // m'as collé), pas son adresse. J'ai mis une URL plausible basée sur ton
  // domaine (contact@matontine.app) ; remplace-la par la vraie avant de
  // publier. C'est la SEULE ligne à corriger, le lien est déjà branché
  // partout où il doit l'être (voir tenant_register_screen.dart,
  // member_join_screen.dart, tenant_profile_screen.dart, member_profile_screen.dart).
  static const String privacyPolicyUrl = 'https://matontine.app/confidentialite';

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
class AppConstants {
  AppConstants._();

  // API
  static const String baseUrl = 'https://instrutorlegal.org';
  static const String apiUrl = '$baseUrl/api';
  static const Duration apiTimeout = Duration(seconds: 30);

  // Storage Keys
  static const String authTokenKey = 'auth_token';
  static const String userDataKey = 'user_data';
  static const String notificationPrefsKey = 'notification_prefs';

  // App Info
  static const String appName = 'Instrutor Legal Pro';
  static const String appTagline = 'CNH + Barata Com Quem é Legalizado';
  static const String supportPhone = '5561995693166';
  static const String supportEmail = 'contato@instrutorlegal.org';
  static const String instagramUrl = 'https://www.instagram.com/instrutor.legal/';

  // Validation
  static const int minPasswordLength = 6;
  static const int phoneLength = 11;
  static const int cpfLength = 11;

  // Pagination
  static const int defaultPageSize = 20;

  // Cache
  static const Duration cacheValidDuration = Duration(minutes: 5);

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
}

class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const String login = '/auth/login';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';

  // Instrutor
  static String dashboard(String userId) => '/instrutor/dashboard/$userId';
  static String aulas(String userId) => '/instrutor/aulas/$userId';
  static String alunos(String userId) => '/instrutor/alunos/$userId';
  static String perfil(String userId) => '/instrutor/perfil/$userId';

  // Aulas
  static String aulaConfirmar(String aulaId) => '/aulas/$aulaId/confirmar';
  static String aulaCancelar(String aulaId) => '/aulas/$aulaId/cancelar';
  static String aulaRealizar(String aulaId) => '/aulas/$aulaId/realizar';
  static String aulaStatus(String aulaId) => '/aulas/$aulaId/status';

  // Usuário
  static String usuario(String userId) => '/usuarios/$userId';
  static String alterarSenha(String userId) => '/usuarios/$userId/senha';

  // Mensagens
  static String conversas(String userId) => '/instrutor/mensagens/$userId';
  static String mensagens(String userId, String outroId) => '/instrutor/mensagens/$userId/$outroId';
  static String countNaoLidas(String userId) => '/mensagens/count/nao-lidas/$userId';
  static const String enviarMensagem = '/mensagens';

  // Notificações
  static String notificacoes(String userId) => '/notificacoes/$userId';
  static String marcarLida(String notifId) => '/notificacoes/$notifId/lida';
}

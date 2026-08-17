/// Nomes de rota usados pelo aplicativo.
///
/// As rotas `legacy*` permanecem ativas durante a migração para que telas
/// antigas continuem funcionando até serem movidas para os novos módulos.
abstract final class AppRoutes {
  static const splash = '/';
  static const auth = '/auth';
  static const login = '/login';
  static const onboarding = '/onboarding';
  static const home = '/home';

  static const legacyLogin = '/tela_login';
  static const legacyOnboarding = '/tela_onboarding';
  static const legacyHome = '/tela_inicial';
}

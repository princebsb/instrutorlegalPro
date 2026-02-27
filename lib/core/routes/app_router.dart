import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/aulas/screens/aulas_screen.dart';
import '../../features/aulas/screens/agenda_screen.dart';
import '../../features/alunos/screens/alunos_screen.dart';
import '../../features/mensagens/screens/mensagens_screen.dart';
import '../../features/mensagens/screens/conversa_screen.dart';
import '../../features/perfil/screens/perfil_screen.dart';
import '../../features/configuracoes/screens/configuracoes_screen.dart';
import '../../features/configuracoes/screens/alterar_senha_screen.dart';

class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const forgotPassword = '/esqueci-senha';
  static const dashboard = '/dashboard';
  static const aulas = '/aulas';
  static const agenda = '/agenda';
  static const alunos = '/alunos';
  static const mensagens = '/mensagens';
  static const conversa = '/conversa';
  static const perfil = '/perfil';
  static const configuracoes = '/configuracoes';
  static const alterarSenha = '/alterar-senha';
}

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final authProvider = context.read<AuthProvider>();
      final isAuthenticated = authProvider.isAuthenticated;
      final isAuthRoute = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.forgotPassword;
      final isSplash = state.matchedLocation == AppRoutes.splash;

      if (isSplash) return null;

      if (!isAuthenticated && !isAuthRoute) {
        return AppRoutes.login;
      }

      if (isAuthenticated && isAuthRoute) {
        return AppRoutes.dashboard;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.aulas,
        builder: (context, state) => const AulasScreen(),
      ),
      GoRoute(
        path: AppRoutes.agenda,
        builder: (context, state) => const AgendaScreen(),
      ),
      GoRoute(
        path: AppRoutes.alunos,
        builder: (context, state) => const AlunosScreen(),
      ),
      GoRoute(
        path: AppRoutes.mensagens,
        builder: (context, state) => const MensagensScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.conversa}/:id',
        builder: (context, state) {
          final conversaId = state.pathParameters['id']!;
          final extra = state.extra as Map<String, dynamic>?;
          return ConversaScreen(
            conversaId: conversaId,
            nomeContato: extra?['nomeContato'] ?? 'Conversa',
          );
        },
      ),
      GoRoute(
        path: AppRoutes.perfil,
        builder: (context, state) => const PerfilScreen(),
      ),
      GoRoute(
        path: AppRoutes.configuracoes,
        builder: (context, state) => const ConfiguracoesScreen(),
      ),
      GoRoute(
        path: AppRoutes.alterarSenha,
        builder: (context, state) => const AlterarSenhaScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Página não encontrada',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.matchedLocation,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.dashboard),
              child: const Text('Voltar ao início'),
            ),
          ],
        ),
      ),
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/notification_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_router.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../../shared/widgets/bottom_nav_bar.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _api = ApiService();
  bool _isLoading = true;

  Map<String, dynamic> _estatisticas = {
    'aulasAgendadas': 0,
    'totalAlunos': 0,
    'avaliacaoMedia': 0.0,
    'receitaMensal': 0.0,
    'mensagensNaoLidas': 0,
  };
  List<Map<String, dynamic>> _proximasAulas = [];
  Map<String, dynamic> _desempenho = {
    'aulasRealizadasMes': 0,
    'horasAulaMes': 0,
    'avaliacoesMes': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadDashboard();
    _startNotificationPolling();
  }

  void _startNotificationPolling() {
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      context.read<NotificationProvider>().startPolling(user.id);
    }
  }

  Future<void> _loadDashboard() async {
    setState(() => _isLoading = true);

    final user = context.read<AuthProvider>().user;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await _api.get(ApiEndpoints.dashboard(user.id));

      if (response != null) {
        setState(() {
          if (response['estatisticas'] != null) {
            _estatisticas = Map<String, dynamic>.from(response['estatisticas']);
          }
          if (response['proximasAulas'] != null) {
            _proximasAulas = List<Map<String, dynamic>>.from(
              response['proximasAulas'].map((a) => Map<String, dynamic>.from(a)),
            );
          }
          if (response['desempenho'] != null) {
            _desempenho = Map<String, dynamic>.from(response['desempenho']);
          }
        });
      }
    } catch (e) {
      // Usar dados mock
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateAulaStatus(String aulaId, String action) async {
    try {
      String endpoint;
      switch (action) {
        case 'confirmar':
          endpoint = ApiEndpoints.aulaConfirmar(aulaId);
          break;
        case 'cancelar':
          endpoint = ApiEndpoints.aulaCancelar(aulaId);
          break;
        default:
          return;
      }

      await _api.patch(endpoint);
      await _loadDashboard();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Aula ${action == 'confirmar' ? 'confirmada' : 'cancelada'} com sucesso!'),
            backgroundColor: action == 'confirmar' ? AppColors.success : AppColors.warning,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao $action aula: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final notificationProvider = context.watch<NotificationProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
          onRefresh: _loadDashboard,
          color: AppColors.primary,
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: true,
                backgroundColor: AppColors.white,
                elevation: 0,
                automaticallyImplyLeading: false,
                title: const AppLogoHorizontal(height: 36),
                actions: [
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined),
                        onPressed: () => _showNotificationsSheet(context),
                      ),
                      if (notificationProvider.hasUnread)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildGreeting(user?.primeiroNome ?? 'Instrutor'),
                    const SizedBox(height: 16),
                    _buildAlertaAulasPendentes(),
                    const SizedBox(height: 24),
                    _buildStatsCards(),
                    const SizedBox(height: 24),
                    _buildDesempenhoCard(),
                    const SizedBox(height: 24),
                    _buildProximasAulas(),
                    const SizedBox(height: 24),
                    _buildQuickActions(),
                    const SizedBox(height: 100),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0,
        unreadMessages: _estatisticas['mensagensNaoLidas'] ?? 0,
      ),
    );
  }

  Widget _buildGreeting(String nome) {
    final hora = DateTime.now().hour;
    String saudacao;
    IconData icon;

    if (hora < 12) {
      saudacao = 'Bom dia';
      icon = Icons.wb_sunny_outlined;
    } else if (hora < 18) {
      saudacao = 'Boa tarde';
      icon = Icons.wb_sunny;
    } else {
      saudacao = 'Boa noite';
      icon = Icons.nightlight_outlined;
    }

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '$saudacao,',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                nome,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => context.go(AppRoutes.perfil),
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: Center(
              child: Text(
                context.read<AuthProvider>().user?.iniciais ?? 'I',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildAlertaAulasPendentes() {
    // Contar aulas com status 'agendada' (aguardando confirmação)
    final aulasPendentes = _proximasAulas.where((a) =>
      (a['status'] ?? '').toString().toLowerCase() == 'agendada'
    ).length;

    if (aulasPendentes == 0) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () => context.go(AppRoutes.aulas),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.warningLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.warning.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_active,
                color: AppColors.warning,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    aulasPendentes == 1
                        ? 'Você tem 1 aula aguardando confirmação!'
                        : 'Você tem $aulasPendentes aulas aguardando confirmação!',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Text(
                    'Toque para ver e confirmar',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.warning,
            ),
          ],
        ),
      ),
    ).animate().fadeIn().shake(delay: 500.ms, duration: 500.ms, hz: 2);
  }

  Widget _buildStatsCards() {
    final avaliacao = (_estatisticas['avaliacaoMedia'] ?? 0.0).toDouble();

    final stats = [
      {
        'icon': Icons.calendar_today,
        'label': 'Aulas Agendadas',
        'value': _estatisticas['aulasAgendadas']?.toString() ?? '0',
        'color': AppColors.info,
      },
      {
        'icon': Icons.people,
        'label': 'Total Alunos',
        'value': _estatisticas['totalAlunos']?.toString() ?? '0',
        'color': AppColors.success,
      },
      {
        'icon': Icons.star,
        'label': 'Avaliação',
        'value': avaliacao > 0 ? avaliacao.toStringAsFixed(1) : '—',
        'color': AppColors.warning,
      },
      {
        'icon': Icons.trending_up,
        'label': 'Aulas no Mês',
        'value': '${_desempenho['aulasRealizadasMes'] ?? 0}',
        'color': AppColors.primary,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.8,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppColors.cardShadow,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (stat['color'] as Color).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  stat['icon'] as IconData,
                  color: stat['color'] as Color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stat['value'] as String,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      stat['label'] as String,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate(delay: (100 * index).ms).fadeIn().slideY(begin: 0.2);
      },
    );
  }

  Widget _buildDesempenhoCard() {
    final aulasRealizadas = _desempenho['aulasRealizadasMes'] ?? 0;
    final horas = _desempenho['horasAulaMes'] ?? 0;
    final avaliacoes = _desempenho['avaliacoesMes'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.buttonShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Desempenho Mensal',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildDesempenhoItem('$aulasRealizadas', 'Aulas'),
              Container(width: 1, height: 40, color: Colors.white30),
              _buildDesempenhoItem('${horas}h', 'Horas'),
              Container(width: 1, height: 40, color: Colors.white30),
              _buildDesempenhoItem('$avaliacoes', 'Avaliações'),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2);
  }

  Widget _buildDesempenhoItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: AppColors.white.withOpacity(0.8),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildProximasAulas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Próximas Aulas',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextButton(
              onPressed: () => context.go(AppRoutes.aulas),
              child: const Text('Ver todas'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_proximasAulas.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.gray200),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 48,
                  color: AppColors.gray400,
                ),
                const SizedBox(height: 12),
                Text(
                  'Nenhuma aula agendada',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Suas próximas aulas aparecerão aqui',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _proximasAulas.length.clamp(0, 3),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final aula = _proximasAulas[index];
              return _buildAulaCard(aula);
            },
          ),
      ],
    ).animate().fadeIn(delay: 500.ms);
  }

  Widget _buildAulaCard(Map<String, dynamic> aula) {
    final dataLabel = aula['data']?.toString() ?? '';
    final horario = aula['horario']?.toString() ?? '';
    final status = aula['status'] ?? 'agendada';
    final isPendente = status == 'agendada';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 70,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    dataLabel,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      aula['aluno'] ?? 'Aluno',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 14, color: AppColors.gray500),
                        const SizedBox(width: 4),
                        Text(
                          horario,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.location_on_outlined, size: 14, color: AppColors.gray500),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            aula['local'] ?? 'Local a definir',
                            style: Theme.of(context).textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Botão de mensagem
              if (aula['aluno_usuario_id'] != null)
                IconButton(
                  onPressed: () {
                    context.push(
                      '${AppRoutes.conversa}/${aula['aluno_usuario_id']}',
                      extra: {
                        'nomeContato': aula['aluno'] ?? 'Aluno',
                        'banido': false,
                      },
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline),
                  color: AppColors.primary,
                  tooltip: 'Enviar mensagem',
                ),
              _buildStatusBadge(status),
            ],
          ),
          if (isPendente) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _updateAulaStatus(aula['id'].toString(), 'cancelar'),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Recusar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _updateAulaStatus(aula['id'].toString(), 'confirmar'),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Confirmar'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status.toLowerCase()) {
      case 'confirmada':
        bgColor = AppColors.successLight;
        textColor = AppColors.success;
        label = 'Confirmada';
        break;
      case 'agendada':
        bgColor = AppColors.warningLight;
        textColor = AppColors.warning;
        label = 'Aguardando';
        break;
      case 'realizada':
        bgColor = AppColors.infoLight;
        textColor = AppColors.info;
        label = 'Realizada';
        break;
      case 'cancelada':
        bgColor = AppColors.errorLight;
        textColor = AppColors.error;
        label = 'Cancelada';
        break;
      default:
        bgColor = AppColors.gray100;
        textColor = AppColors.gray600;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ações Rápidas',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.calendar_month,
                label: 'Gerenciar Agenda',
                color: AppColors.primary,
                onTap: () => context.go(AppRoutes.agenda),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                icon: Icons.chat_bubble_outline,
                label: 'Mensagens',
                color: AppColors.info,
                onTap: () => context.go(AppRoutes.mensagens),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Minha Carteira',
                color: AppColors.success,
                onTap: () => context.go(AppRoutes.carteira),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                icon: Icons.people_outline,
                label: 'Meus Alunos',
                color: AppColors.warning,
                onTap: () => context.go(AppRoutes.alunos),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.settings_outlined,
                label: 'Configurações',
                color: AppColors.secondary,
                onTap: () => context.go(AppRoutes.configuracoes),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(child: SizedBox()),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 600.ms);
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.gray200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNotificationsSheet(BuildContext context) {
    final notificationProvider = context.read<NotificationProvider>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.gray300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Notificações', style: Theme.of(context).textTheme.titleLarge),
                    if (notificationProvider.hasUnread)
                      TextButton(
                        onPressed: () {
                          final user = context.read<AuthProvider>().user;
                          if (user != null) {
                            notificationProvider.markAllAsRead(user.id);
                          }
                        },
                        child: const Text('Marcar todas como lidas'),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: notificationProvider.notifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.notifications_none, size: 64, color: AppColors.gray400),
                            const SizedBox(height: 16),
                            Text(
                              'Nenhuma notificação',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: notificationProvider.notifications.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final notif = notificationProvider.notifications[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: notif.lida ? AppColors.gray100 : AppColors.primarySurface,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.notifications,
                                color: notif.lida ? AppColors.gray500 : AppColors.primary,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              notif.titulo,
                              style: TextStyle(fontWeight: notif.lida ? FontWeight.normal : FontWeight.w600),
                            ),
                            subtitle: Text(notif.mensagem, maxLines: 2, overflow: TextOverflow.ellipsis),
                            onTap: () => notificationProvider.markAsRead(notif.id),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

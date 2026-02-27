import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/bottom_nav_bar.dart';

class AulasScreen extends StatefulWidget {
  const AulasScreen({super.key});

  @override
  State<AulasScreen> createState() => _AulasScreenState();
}

class _AulasScreenState extends State<AulasScreen> with SingleTickerProviderStateMixin {
  final _api = ApiService();
  late TabController _tabController;

  List<Map<String, dynamic>> _todasAulas = [];
  bool _isLoading = true;

  final _filtros = ['Todas', 'Aguardando', 'Confirmadas', 'Realizadas', 'Canceladas'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _filtros.length, vsync: this);
    _loadAulas();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAulas() async {
    setState(() => _isLoading = true);

    final user = context.read<AuthProvider>().user;
    if (user == null) {
      debugPrint('[AULAS] Usuário não autenticado (user == null), não é possível carregar aulas');
      setState(() => _isLoading = false);
      return;
    }

    debugPrint('[AULAS] Carregando aulas para userId: ${user.id}');

    try {
      final response = await _api.get(ApiEndpoints.aulas(user.id));
      final List<dynamic> data = response is List ? response : (response['aulas'] ?? []);

      debugPrint('[AULAS] Recebidas ${data.length} aulas da API');

      setState(() {
        _todasAulas = data.map((a) => Map<String, dynamic>.from(a)).toList();
      });
    } catch (e) {
      debugPrint('[AULAS] Erro ao carregar aulas: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar aulas: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _getAulasFiltradas(int tabIndex) {
    if (tabIndex == 0) return _todasAulas;

    final statusFiltro = {
      1: 'aguardando',
      2: 'confirmada',
      3: 'realizada',
      4: 'cancelada',
    };

    return _todasAulas.where((a) {
      return (a['status'] ?? '').toString().toLowerCase() == statusFiltro[tabIndex];
    }).toList();
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
        case 'realizar':
          endpoint = ApiEndpoints.aulaRealizar(aulaId);
          break;
        default:
          return;
      }

      await _api.patch(endpoint);
      await _loadAulas();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Aula atualizada com sucesso!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar aula: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Minhas Aulas'),
        backgroundColor: AppColors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _filtros.map((f) => Tab(text: f)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(_filtros.length, (index) {
          return _buildAulasList(index);
        }),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }

  Widget _buildAulasList(int tabIndex) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final aulas = _getAulasFiltradas(tabIndex);

    if (aulas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.calendar_today_outlined, size: 80, color: AppColors.gray300),
              const SizedBox(height: 24),
              Text(
                'Nenhuma aula encontrada',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAulas,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: aulas.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return _buildAulaCard(aulas[index]).animate(delay: (50 * index).ms).fadeIn().slideY(begin: 0.1);
        },
      ),
    );
  }

  Widget _buildAulaCard(Map<String, dynamic> aula) {
    final dataHora = DateTime.tryParse(aula['data_hora'] ?? '') ?? DateTime.now();
    final status = (aula['status'] ?? 'aguardando').toString().toLowerCase();
    final valor = (aula['valor'] ?? 120.0).toDouble();

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
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    (aula['aluno_nome'] ?? 'A')[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      aula['aluno_nome'] ?? 'Aluno',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.gray100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Cat. ${aula['categoria'] ?? 'B'}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.gray600),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'R\$ ${valor.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(status),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.gray50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: AppColors.gray500),
                const SizedBox(width: 6),
                Text(
                  DateFormat('dd/MM/yyyy').format(dataHora),
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, size: 14, color: AppColors.gray500),
                const SizedBox(width: 6),
                Text(
                  DateFormat('HH:mm').format(dataHora),
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.location_on_outlined, size: 14, color: AppColors.gray500),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    aula['local_partida'] ?? 'Local a definir',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          if (status == 'aguardando') ...[
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
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _updateAulaStatus(aula['id'].toString(), 'confirmar'),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Confirmar'),
                  ),
                ),
              ],
            ),
          ],
          if (status == 'confirmada') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _updateAulaStatus(aula['id'].toString(), 'cancelar'),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Cancelar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _updateAulaStatus(aula['id'].toString(), 'realizar'),
                    icon: const Icon(Icons.done_all, size: 18),
                    label: const Text('Realizada'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
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

    switch (status) {
      case 'confirmada':
        bgColor = AppColors.successLight;
        textColor = AppColors.success;
        label = 'Confirmada';
        break;
      case 'aguardando':
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
        style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

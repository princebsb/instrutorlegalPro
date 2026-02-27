import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/bottom_nav_bar.dart';

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  final _api = ApiService();
  bool _isLoading = true;

  DateTime _currentWeekStart = DateTime.now();
  List<Map<String, dynamic>> _aulas = [];

  @override
  void initState() {
    super.initState();
    _currentWeekStart = _getWeekStart(DateTime.now());
    _loadAulas();
  }

  DateTime _getWeekStart(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  void _previousWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.subtract(const Duration(days: 7));
    });
    _loadAulas();
  }

  void _nextWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.add(const Duration(days: 7));
    });
    _loadAulas();
  }

  Future<void> _loadAulas() async {
    setState(() => _isLoading = true);

    final user = context.read<AuthProvider>().user;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    final weekEnd = _currentWeekStart.add(const Duration(days: 6));

    try {
      final response = await _api.get(
        ApiEndpoints.aulas(user.id),
        queryParams: {
          'data_inicio': _currentWeekStart.toIso8601String().split('T')[0],
          'data_fim': weekEnd.toIso8601String().split('T')[0],
        },
      );
      final List<dynamic> data = response is List ? response : (response['aulas'] ?? []);

      setState(() {
        _aulas = data.map((a) => Map<String, dynamic>.from(a)).toList();
      });
    } catch (e) {
      setState(() {
        _aulas = [];
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _getAulasForDay(DateTime day) {
    return _aulas.where((a) {
      final dataHora = DateTime.tryParse(a['data_hora'] ?? '');
      if (dataHora == null) return false;
      return dataHora.year == day.year && dataHora.month == day.month && dataHora.day == day.day;
    }).toList()
      ..sort((a, b) {
        final dateA = DateTime.tryParse(a['data_hora'] ?? '') ?? DateTime.now();
        final dateB = DateTime.tryParse(b['data_hora'] ?? '') ?? DateTime.now();
        return dateA.compareTo(dateB);
      });
  }

  int get _totalAulasSemana => _aulas.length;
  int get _aulasConfirmadas => _aulas.where((a) => a['status'] == 'confirmada').length;

  @override
  Widget build(BuildContext context) {
    final weekEnd = _currentWeekStart.add(const Duration(days: 6));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Agenda'),
        backgroundColor: AppColors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Week navigation
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _previousWeek,
                ),
                Column(
                  children: [
                    Text(
                      '${DateFormat('dd MMM').format(_currentWeekStart)} - ${DateFormat('dd MMM').format(weekEnd)}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_totalAulasSemana aulas | $_aulasConfirmadas confirmadas',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _nextWeek,
                ),
              ],
            ),
          ),

          // Week grid
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadAulas,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: 7,
                      itemBuilder: (context, index) {
                        final day = _currentWeekStart.add(Duration(days: index));
                        final aulasDay = _getAulasForDay(day);
                        final isToday = _isToday(day);

                        return _buildDayCard(day, aulasDay, isToday)
                            .animate(delay: (50 * index).ms)
                            .fadeIn()
                            .slideX(begin: 0.05);
                      },
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }

  bool _isToday(DateTime day) {
    final now = DateTime.now();
    return day.year == now.year && day.month == now.month && day.day == now.day;
  }

  Widget _buildDayCard(DateTime day, List<Map<String, dynamic>> aulas, bool isToday) {
    final dayNames = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: isToday ? Border.all(color: AppColors.primary, width: 2) : null,
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: [
          // Day header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isToday ? AppColors.primarySurface : AppColors.gray50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Text(
                  dayNames[day.weekday - 1],
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isToday ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('dd/MM').format(day),
                  style: TextStyle(
                    color: isToday ? AppColors.primary : AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                if (isToday) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Hoje',
                      style: TextStyle(color: AppColors.white, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  '${aulas.length} ${aulas.length == 1 ? 'aula' : 'aulas'}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),

          // Aulas
          if (aulas.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Sem aulas',
                style: TextStyle(color: AppColors.gray400, fontSize: 13),
              ),
            )
          else
            ...aulas.map((aula) => _buildAulaItem(aula)),
        ],
      ),
    );
  }

  Widget _buildAulaItem(Map<String, dynamic> aula) {
    final dataHora = DateTime.tryParse(aula['data_hora'] ?? '') ?? DateTime.now();
    final status = (aula['status'] ?? 'aguardando').toString().toLowerCase();

    Color statusColor;
    switch (status) {
      case 'confirmada':
        statusColor = AppColors.success;
        break;
      case 'aguardando':
        statusColor = AppColors.warning;
        break;
      case 'realizada':
        statusColor = AppColors.info;
        break;
      case 'cancelada':
        statusColor = AppColors.error;
        break;
      default:
        statusColor = AppColors.gray400;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.gray200, width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            DateFormat('HH:mm').format(dataHora),
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  aula['aluno_nome'] ?? 'Aluno',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  'Cat. ${aula['categoria'] ?? 'B'} • ${aula['local_partida'] ?? ''}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

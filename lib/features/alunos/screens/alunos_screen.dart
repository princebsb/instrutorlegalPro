import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_router.dart';
import '../../../shared/widgets/bottom_nav_bar.dart';
import '../../../shared/widgets/custom_text_field.dart';

class AlunosScreen extends StatefulWidget {
  const AlunosScreen({super.key});

  @override
  State<AlunosScreen> createState() => _AlunosScreenState();
}

class _AlunosScreenState extends State<AlunosScreen> {
  final _api = ApiService();
  final _searchController = TextEditingController();

  List<Map<String, dynamic>> _alunos = [];
  List<Map<String, dynamic>> _alunosFiltrados = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlunos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAlunos() async {
    setState(() => _isLoading = true);

    final user = context.read<AuthProvider>().user;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await _api.get(ApiEndpoints.alunos(user.id));
      final List<dynamic> data = response is List ? response : (response['alunos'] ?? []);

      setState(() {
        _alunos = data.map((a) => Map<String, dynamic>.from(a)).toList();
        _alunosFiltrados = _alunos;
      });
    } catch (e) {
      // Mock data
      setState(() {
        _alunos = [
          {
            'id': '1',
            'nome': 'Carlos Souza',
            'categoria': 'B',
            'aulas_realizadas': 12,
            'progresso': 40.0,
            'avaliacao': 4.8,
            'telefone': '11999999999',
            'email': 'carlos@email.com',
            'proxima_aula': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
          },
          {
            'id': '2',
            'nome': 'Ana Paula Lima',
            'categoria': 'A',
            'aulas_realizadas': 8,
            'progresso': 27.0,
            'avaliacao': 5.0,
            'telefone': '11988888888',
            'email': 'ana@email.com',
            'proxima_aula': null,
          },
          {
            'id': '3',
            'nome': 'Pedro Santos',
            'categoria': 'AB',
            'aulas_realizadas': 20,
            'progresso': 67.0,
            'avaliacao': 4.5,
            'telefone': '11977777777',
            'email': 'pedro@email.com',
            'proxima_aula': DateTime.now().add(const Duration(days: 3)).toIso8601String(),
          },
        ];
        _alunosFiltrados = _alunos;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterAlunos(String query) {
    setState(() {
      if (query.isEmpty) {
        _alunosFiltrados = _alunos;
      } else {
        _alunosFiltrados = _alunos.where((a) {
          final nome = (a['nome'] ?? '').toString().toLowerCase();
          return nome.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Meus Alunos (${_alunos.length})'),
        backgroundColor: AppColors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.white,
            child: CustomTextField(
              controller: _searchController,
              hint: 'Buscar aluno...',
              prefixIcon: const Icon(Icons.search),
              onChanged: _filterAlunos,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _alunosFiltrados.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadAlunos,
                        child: GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.72,
                          ),
                          itemCount: _alunosFiltrados.length,
                          itemBuilder: (context, index) {
                            return _buildAlunoCard(_alunosFiltrados[index])
                                .animate(delay: (50 * index).ms)
                                .fadeIn()
                                .scale(begin: const Offset(0.95, 0.95));
                          },
                        ),
                      ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 2),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, size: 80, color: AppColors.gray300),
            const SizedBox(height: 24),
            Text(
              'Nenhum aluno encontrado',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Seus alunos aparecerão aqui quando agendarem aulas',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlunoCard(Map<String, dynamic> aluno) {
    final nome = aluno['nome'] ?? 'Aluno';
    final categoria = aluno['categoria'] ?? 'B';
    final aulasRealizadas = aluno['aulas_realizadas'] ?? 0;
    final progresso = (aluno['progresso'] ?? 0.0).toDouble();
    final avaliacao = aluno['avaliacao'] != null ? (aluno['avaliacao']).toDouble() : null;
    final iniciais = _getIniciais(nome);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppColors.primarySurface,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                iniciais,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Nome
          Text(
            nome,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          // Categoria e rating
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.gray100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Cat. $categoria',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.gray600),
                ),
              ),
              if (avaliacao != null) ...[
                const SizedBox(width: 6),
                const Icon(Icons.star, size: 12, color: AppColors.warning),
                const SizedBox(width: 2),
                Text(
                  avaliacao.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ],
          ),

          const SizedBox(height: 8),

          // Progresso
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$aulasRealizadas aulas',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  Text(
                    '${progresso.toInt()}%',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (progresso / 100).clamp(0, 1),
                  backgroundColor: AppColors.gray200,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  minHeight: 6,
                ),
              ),
            ],
          ),

          const Spacer(),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildIconAction(Icons.phone, () {
                final tel = aluno['telefone'];
                if (tel != null) launchUrl(Uri.parse('tel:$tel'));
              }),
              _buildIconAction(Icons.chat_bubble_outline, () {
                context.push(
                  '${AppRoutes.conversa}/${aluno['id']}',
                  extra: {'nomeContato': nome},
                );
              }),
              _buildIconAction(Icons.email_outlined, () {
                final email = aluno['email'];
                if (email != null) launchUrl(Uri.parse('mailto:$email'));
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconAction(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: AppColors.primary),
      ),
    );
  }

  String _getIniciais(String nome) {
    final partes = nome.split(' ');
    if (partes.length >= 2) {
      return '${partes.first[0]}${partes.last[0]}'.toUpperCase();
    }
    return nome.isNotEmpty ? nome[0].toUpperCase() : 'A';
  }
}

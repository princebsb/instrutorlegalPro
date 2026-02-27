import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/bottom_nav_bar.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/custom_button.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _api = ApiService();
  final _formKey = GlobalKey<FormState>();

  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _cpfController = TextEditingController();
  final _dataNascController = TextEditingController();
  final _cepController = TextEditingController();
  final _enderecoController = TextEditingController();
  final _numeroController = TextEditingController();
  final _complementoController = TextEditingController();
  final _bairroController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _estadoController = TextEditingController();
  final _biografiaController = TextEditingController();
  final _valorAulaController = TextEditingController();

  final _phoneMask = MaskTextInputFormatter(mask: '(##) #####-####');
  final _cpfMask = MaskTextInputFormatter(mask: '###.###.###-##');
  final _cepMask = MaskTextInputFormatter(mask: '#####-###');
  final _dataMask = MaskTextInputFormatter(mask: '##/##/####');

  bool _isLoading = false;
  bool _isEditing = false;

  // Dados do instrutor
  List<String> _categoriasHabilitadas = [];
  final _todasCategorias = ['A', 'B', 'AB', 'C', 'D', 'E'];

  // Stats
  double _avaliacao = 0.0;
  int _totalAulas = 0;
  int _aprovados = 0;
  int _experiencia = 0;

  @override
  void initState() {
    super.initState();
    _loadPerfil();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    _cpfController.dispose();
    _dataNascController.dispose();
    _cepController.dispose();
    _enderecoController.dispose();
    _numeroController.dispose();
    _complementoController.dispose();
    _bairroController.dispose();
    _cidadeController.dispose();
    _estadoController.dispose();
    _biografiaController.dispose();
    _valorAulaController.dispose();
    super.dispose();
  }

  Future<void> _loadPerfil() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    // Fill from user data
    _nomeController.text = user.nomeCompleto;
    _emailController.text = user.email;
    _telefoneController.text = user.telefone ?? '';
    _cpfController.text = user.cpf ?? '';
    _dataNascController.text = user.dataNascimento ?? '';
    _cepController.text = user.cep ?? '';
    _enderecoController.text = user.endereco ?? '';
    _numeroController.text = user.numero ?? '';
    _complementoController.text = user.complemento ?? '';
    _bairroController.text = user.bairro ?? '';
    _cidadeController.text = user.cidade ?? '';
    _estadoController.text = user.estado ?? '';

    try {
      final response = await _api.get(ApiEndpoints.perfil(user.id));

      if (response != null) {
        setState(() {
          _biografiaController.text = response['biografia'] ?? '';
          _valorAulaController.text = (response['valor_aula'] ?? 120.0).toString();
          _avaliacao = (response['nota_media'] ?? 0.0).toDouble();
          _totalAulas = response['total_aulas_dadas'] ?? 0;
          _aprovados = response['alunos_aprovados'] ?? 0;
          _experiencia = response['anos_experiencia'] ?? 0;

          if (response['categorias_habilitadas'] != null) {
            if (response['categorias_habilitadas'] is List) {
              _categoriasHabilitadas = List<String>.from(response['categorias_habilitadas']);
            } else if (response['categorias_habilitadas'] is String) {
              _categoriasHabilitadas = (response['categorias_habilitadas'] as String)
                  .split(',')
                  .map((e) => e.trim())
                  .toList();
            }
          }
        });
      }
    } catch (e) {
      // Use defaults
      _valorAulaController.text = '120';
    }
  }

  Future<void> _savePerfil() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.updateProfile({
      'nome_completo': _nomeController.text,
      'email': _emailController.text,
      'telefone': _telefoneController.text.replaceAll(RegExp(r'\D'), ''),
      'cpf': _cpfController.text.replaceAll(RegExp(r'\D'), ''),
      'data_nascimento': _dataNascController.text,
      'cep': _cepController.text.replaceAll(RegExp(r'\D'), ''),
      'endereco': _enderecoController.text,
      'numero': _numeroController.text,
      'complemento': _complementoController.text,
      'bairro': _bairroController.text,
      'cidade': _cidadeController.text,
      'estado': _estadoController.text,
      'biografia': _biografiaController.text,
      'categorias_habilitadas': _categoriasHabilitadas,
      'valor_aula': double.tryParse(_valorAulaController.text) ?? 120.0,
    });

    setState(() {
      _isLoading = false;
      if (success) _isEditing = false;
    });

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil atualizado com sucesso!'), backgroundColor: AppColors.success),
        );
      } else if (authProvider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authProvider.error!), backgroundColor: AppColors.error),
        );
        authProvider.clearError();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        backgroundColor: AppColors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          if (!_isEditing)
            TextButton.icon(
              onPressed: () => setState(() => _isEditing = true),
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Editar'),
            )
          else
            TextButton(
              onPressed: () => setState(() => _isEditing = false),
              child: const Text('Cancelar'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar and name
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 3),
                      ),
                      child: Center(
                        child: Text(
                          user?.iniciais ?? 'I',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user?.nomeCompleto ?? 'Instrutor',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ).animate().fadeIn(),

              const SizedBox(height: 16),

              // Stats
              _buildStatsRow(),

              const SizedBox(height: 24),

              // Dados pessoais
              _buildSectionTitle('Dados Pessoais'),
              const SizedBox(height: 12),

              CustomTextField(
                label: 'Nome Completo',
                controller: _nomeController,
                enabled: _isEditing,
                prefixIcon: const Icon(Icons.person_outline),
                validator: (v) => v == null || v.isEmpty ? 'Informe o nome' : null,
              ),
              const SizedBox(height: 16),

              CustomTextField(
                label: 'E-mail',
                controller: _emailController,
                enabled: _isEditing,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: const Icon(Icons.email_outlined),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'Telefone',
                      controller: _telefoneController,
                      enabled: _isEditing,
                      keyboardType: TextInputType.phone,
                      prefixIcon: const Icon(Icons.phone_outlined),
                      inputFormatters: [_phoneMask],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      label: 'CPF',
                      controller: _cpfController,
                      enabled: _isEditing,
                      keyboardType: TextInputType.number,
                      prefixIcon: const Icon(Icons.badge_outlined),
                      inputFormatters: [_cpfMask],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              CustomTextField(
                label: 'Data de Nascimento',
                controller: _dataNascController,
                enabled: _isEditing,
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(Icons.calendar_today_outlined),
                inputFormatters: [_dataMask],
              ),

              const SizedBox(height: 24),

              // Endereço
              _buildSectionTitle('Endereço'),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: CustomTextField(
                      label: 'CEP',
                      controller: _cepController,
                      enabled: _isEditing,
                      keyboardType: TextInputType.number,
                      inputFormatters: [_cepMask],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 3,
                    child: CustomTextField(
                      label: 'Endereço',
                      controller: _enderecoController,
                      enabled: _isEditing,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'Número',
                      controller: _numeroController,
                      enabled: _isEditing,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: CustomTextField(
                      label: 'Bairro',
                      controller: _bairroController,
                      enabled: _isEditing,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              CustomTextField(
                label: 'Complemento',
                controller: _complementoController,
                enabled: _isEditing,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: CustomTextField(
                      label: 'Cidade',
                      controller: _cidadeController,
                      enabled: _isEditing,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      label: 'UF',
                      controller: _estadoController,
                      enabled: _isEditing,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Dados profissionais
              _buildSectionTitle('Dados Profissionais'),
              const SizedBox(height: 12),

              CustomTextField(
                label: 'Biografia',
                controller: _biografiaController,
                enabled: _isEditing,
                maxLines: 4,
                hint: 'Conte um pouco sobre você e sua experiência...',
              ),
              const SizedBox(height: 16),

              // Categorias habilitadas
              const Text(
                'Categorias Habilitadas',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _todasCategorias.map((cat) {
                  final isSelected = _categoriasHabilitadas.contains(cat);
                  return FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: _isEditing
                        ? (selected) {
                            setState(() {
                              if (selected) {
                                _categoriasHabilitadas.add(cat);
                              } else {
                                _categoriasHabilitadas.remove(cat);
                              }
                            });
                          }
                        : null,
                    selectedColor: AppColors.primarySurface,
                    checkmarkColor: AppColors.primary,
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              CustomTextField(
                label: 'Valor da Aula (R\$)',
                controller: _valorAulaController,
                enabled: _isEditing,
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(Icons.attach_money),
              ),

              const SizedBox(height: 32),

              if (_isEditing)
                CustomButton(
                  text: 'Salvar Alterações',
                  onPressed: _savePerfil,
                  isLoading: _isLoading,
                  icon: Icons.save,
                ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 4),
    );
  }

  Widget _buildStatsRow() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Icons.star, _avaliacao > 0 ? _avaliacao.toStringAsFixed(1) : '—', 'Avaliação'),
          _buildStatItem(Icons.school, '$_totalAulas', 'Aulas'),
          _buildStatItem(Icons.emoji_events, '$_aprovados', 'Aprovados'),
          _buildStatItem(Icons.timer, '${_experiencia}a', 'Experiência'),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

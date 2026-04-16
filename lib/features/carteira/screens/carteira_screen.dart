import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/bottom_nav_bar.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/custom_button.dart';

class CarteiraScreen extends StatefulWidget {
  const CarteiraScreen({super.key});

  @override
  State<CarteiraScreen> createState() => _CarteiraScreenState();
}

class _CarteiraScreenState extends State<CarteiraScreen> {
  final _api = ApiService();
  bool _isLoading = true;
  String _filtroSelecionado = 'todos';

  Map<String, dynamic> _estatisticas = {
    'total_recebidos': 0,
    'total_pendentes': 0,
    'valor_recebido': 0.0,
    'valor_pendente': 0.0,
    'total_aulas_realizadas': 0,
    'valor_liquido_aulas': 0.0,
  };

  List<Map<String, dynamic>> _transferencias = [];

  // Chave PIX
  String? _chavePix;
  String? _tipoChavePix;

  @override
  void initState() {
    super.initState();
    _loadCarteira();
  }

  Future<void> _loadCarteira() async {
    setState(() => _isLoading = true);

    final user = context.read<AuthProvider>().user;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await _api.get(ApiEndpoints.carteira(user.id));

      if (response != null) {
        setState(() {
          if (response['estatisticas'] != null) {
            _estatisticas = Map<String, dynamic>.from(response['estatisticas']);
          }
          if (response['transferencias'] != null) {
            _transferencias = List<Map<String, dynamic>>.from(
              response['transferencias'].map((t) => Map<String, dynamic>.from(t)),
            );
          }
        });
      }

      // Carregar dados do perfil para pegar chave PIX
      final perfilResponse = await _api.get(ApiEndpoints.perfil(user.id));
      if (perfilResponse != null && perfilResponse['instrutor'] != null) {
        setState(() {
          _chavePix = perfilResponse['instrutor']['chave_pix'];
          _tipoChavePix = perfilResponse['instrutor']['tipo_chave_pix'];
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar carteira: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _transferenciasFiltradas {
    if (_filtroSelecionado == 'todos') return _transferencias;
    return _transferencias
        .where((t) => t['status'] == _filtroSelecionado)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Minha Carteira'),
        backgroundColor: AppColors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.pix),
            onPressed: _showPixConfigModal,
            tooltip: 'Configurar Chave PIX',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadCarteira,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Saldo disponível
                    _buildSaldoCard(),

                    const SizedBox(height: 16),

                    // Chave PIX
                    _buildChavePixCard(),

                    const SizedBox(height: 16),

                    // Resumo Cards
                    _buildResumoCards(),

                    const SizedBox(height: 24),

                    // Filtros
                    _buildFiltros(),

                    const SizedBox(height: 16),

                    // Título
                    Text(
                      'Histórico de Transferências',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),

                    const SizedBox(height: 12),

                    // Lista de transferências
                    _buildListaTransferencias(),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildSaldoCard() {
    final valorRecebido = (_estatisticas['valor_recebido'] as num?)?.toDouble() ?? 0.0;
    final valorPendente = (_estatisticas['valor_pendente'] as num?)?.toDouble() ?? 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Total Recebido',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'R\$ ${valorRecebido.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (valorPendente > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.pending,
                    color: Colors.white70,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'R\$ ${valorPendente.toStringAsFixed(2)} pendente',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1);
  }

  Widget _buildChavePixCard() {
    final hasChavePix = _chavePix != null && _chavePix!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasChavePix ? AppColors.successLight : AppColors.warningLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasChavePix
              ? AppColors.success.withOpacity(0.3)
              : AppColors.warning.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: hasChavePix
                  ? AppColors.success.withOpacity(0.2)
                  : AppColors.warning.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.pix,
              color: hasChavePix ? AppColors.success : AppColors.warning,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasChavePix ? 'Chave PIX Cadastrada' : 'Cadastre sua Chave PIX',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: hasChavePix ? AppColors.success : AppColors.warning,
                  ),
                ),
                if (hasChavePix)
                  Text(
                    '${_getTipoChaveLabel(_tipoChavePix)}: ${_mascaraChavePix(_chavePix!)}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  )
                else
                  const Text(
                    'Configure para receber seus pagamentos',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: _showPixConfigModal,
            child: Text(hasChavePix ? 'Alterar' : 'Cadastrar'),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildResumoCards() {
    final totalRecebidos = (_estatisticas['total_recebidos'] as num?)?.toInt() ?? 0;
    final totalPendentes = (_estatisticas['total_pendentes'] as num?)?.toInt() ?? 0;
    final totalAulas = (_estatisticas['total_aulas_realizadas'] as num?)?.toInt() ?? 0;

    final cards = [
      {
        'label': 'Recebidos',
        'valor': totalRecebidos.toString(),
        'color': AppColors.success,
        'bgColor': AppColors.successLight,
        'icon': Icons.check_circle,
      },
      {
        'label': 'Pendentes',
        'valor': totalPendentes.toString(),
        'color': AppColors.warning,
        'bgColor': AppColors.warningLight,
        'icon': Icons.pending,
      },
      {
        'label': 'Aulas',
        'valor': totalAulas.toString(),
        'color': AppColors.info,
        'bgColor': AppColors.infoLight,
        'icon': Icons.school,
      },
    ];

    return Row(
      children: cards.map((card) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(
              right: card != cards.last ? 8 : 0,
            ),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: card['bgColor'] as Color,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: (card['color'] as Color).withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  card['icon'] as IconData,
                  color: card['color'] as Color,
                  size: 20,
                ),
                const SizedBox(height: 8),
                Text(
                  card['valor'] as String,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: card['color'] as Color,
                  ),
                ),
                Text(
                  card['label'] as String,
                  style: TextStyle(
                    fontSize: 11,
                    color: (card['color'] as Color).withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildFiltros() {
    final filtros = [
      {'id': 'todos', 'label': 'Todos'},
      {'id': 'concluida', 'label': 'Recebidos'},
      {'id': 'pendente', 'label': 'Pendentes'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filtros.map((filtro) {
          final isSelected = _filtroSelecionado == filtro['id'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filtro['label']!),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _filtroSelecionado = filtro['id']!);
              },
              selectedColor: AppColors.primarySurface,
              checkmarkColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildListaTransferencias() {
    if (_transferenciasFiltradas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              const Icon(
                Icons.receipt_long,
                size: 64,
                color: AppColors.gray400,
              ),
              const SizedBox(height: 16),
              Text(
                'Nenhuma transferência encontrada',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Suas transferências aparecerão aqui',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.gray500,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _transferenciasFiltradas.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildTransferenciaCard(_transferenciasFiltradas[index]);
      },
    );
  }

  Widget _buildTransferenciaCard(Map<String, dynamic> transferencia) {
    final dataSolicitacao = DateTime.tryParse(
            transferencia['data_solicitacao']?.toString() ?? '') ??
        DateTime.now();
    final status = transferencia['status']?.toString() ?? 'pendente';
    final valor = (transferencia['valor_liquido'] as num?)?.toDouble() ?? 0.0;
    final alunoNome = transferencia['aluno_nome']?.toString() ?? 'Aluno';

    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (status) {
      case 'concluida':
        statusColor = AppColors.success;
        statusLabel = 'Recebido';
        statusIcon = Icons.check_circle;
        break;
      case 'erro':
        statusColor = AppColors.error;
        statusLabel = 'Erro';
        statusIcon = Icons.error;
        break;
      default:
        statusColor = AppColors.warning;
        statusLabel = 'Pendente';
        statusIcon = Icons.pending;
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
        border: Border(
          left: BorderSide(color: statusColor, width: 4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Aula com $alunoNome',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: AppColors.gray500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('dd/MM/yyyy').format(dataSolicitacao),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'R\$ ${valor.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getTipoChaveLabel(String? tipo) {
    switch (tipo?.toLowerCase()) {
      case 'cpf':
        return 'CPF';
      case 'cnpj':
        return 'CNPJ';
      case 'email':
        return 'E-mail';
      case 'telefone':
        return 'Telefone';
      case 'aleatoria':
        return 'Chave Aleatória';
      default:
        return 'Chave';
    }
  }

  String _mascaraChavePix(String chave) {
    if (chave.length <= 8) return chave;
    return '${chave.substring(0, 4)}****${chave.substring(chave.length - 4)}';
  }

  void _showPixConfigModal() {
    final chaveController = TextEditingController(text: _chavePix);
    String tipoSelecionado = _tipoChavePix ?? 'cpf';
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.gray300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'Configurar Chave PIX',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Configure sua chave PIX para receber os pagamentos das aulas.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tipo de chave
                  const Text(
                    'Tipo de Chave',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildTipoChip('cpf', 'CPF', tipoSelecionado, (t) {
                        setModalState(() => tipoSelecionado = t);
                      }),
                      _buildTipoChip('cnpj', 'CNPJ', tipoSelecionado, (t) {
                        setModalState(() => tipoSelecionado = t);
                      }),
                      _buildTipoChip('email', 'E-mail', tipoSelecionado, (t) {
                        setModalState(() => tipoSelecionado = t);
                      }),
                      _buildTipoChip('telefone', 'Telefone', tipoSelecionado, (t) {
                        setModalState(() => tipoSelecionado = t);
                      }),
                      _buildTipoChip('aleatoria', 'Aleatória', tipoSelecionado, (t) {
                        setModalState(() => tipoSelecionado = t);
                      }),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Campo da chave
                  CustomTextField(
                    label: 'Chave PIX',
                    controller: chaveController,
                    hint: _getHintByTipo(tipoSelecionado),
                    keyboardType: _getKeyboardByTipo(tipoSelecionado),
                    prefixIcon: const Icon(Icons.pix),
                  ),
                  const SizedBox(height: 24),

                  // Botões
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: AppColors.gray300),
                          ),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: CustomButton(
                          text: 'Salvar',
                          isLoading: isLoading,
                          onPressed: () async {
                            setModalState(() => isLoading = true);

                            try {
                              final user = context.read<AuthProvider>().user;
                              if (user == null) return;

                              await _api.patch(
                                ApiEndpoints.chavePix(user.id),
                                body: {
                                  'chave_pix': chaveController.text,
                                  'tipo_chave_pix': tipoSelecionado,
                                },
                              );

                              setState(() {
                                _chavePix = chaveController.text;
                                _tipoChavePix = tipoSelecionado;
                              });

                              if (mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Chave PIX salva com sucesso!'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Erro ao salvar: $e'),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            } finally {
                              setModalState(() => isLoading = false);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTipoChip(
    String tipo,
    String label,
    String selecionado,
    Function(String) onSelect,
  ) {
    final isSelected = tipo == selecionado;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelect(tipo),
      selectedColor: AppColors.primarySurface,
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  String _getHintByTipo(String tipo) {
    switch (tipo) {
      case 'cpf':
        return '000.000.000-00';
      case 'cnpj':
        return '00.000.000/0000-00';
      case 'email':
        return 'seu@email.com';
      case 'telefone':
        return '+55 11 99999-9999';
      case 'aleatoria':
        return 'Cole sua chave aleatória';
      default:
        return '';
    }
  }

  TextInputType _getKeyboardByTipo(String tipo) {
    switch (tipo) {
      case 'cpf':
      case 'cnpj':
      case 'telefone':
        return TextInputType.number;
      case 'email':
        return TextInputType.emailAddress;
      default:
        return TextInputType.text;
    }
  }
}

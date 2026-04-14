import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/app_constants.dart';

class ConversaScreen extends StatefulWidget {
  final String conversaId;
  final String nomeContato;
  final bool banido;

  const ConversaScreen({
    super.key,
    required this.conversaId,
    required this.nomeContato,
    this.banido = false,
  });

  @override
  State<ConversaScreen> createState() => _ConversaScreenState();
}

class _ConversaScreenState extends State<ConversaScreen> {
  final _api = ApiService();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  List<Map<String, dynamic>> _mensagens = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isBanned = false;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _isBanned = widget.banido;
    _loadMensagens();
    _startPolling();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _loadMensagens(silent: true),
    );
  }

  Future<void> _loadMensagens({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);

    final user = context.read<AuthProvider>().user;
    if (user == null) {
      if (!silent) setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await _api.get(
        ApiEndpoints.mensagens(user.id, widget.conversaId),
      );
      final List<dynamic> data = response is List ? response : (response['mensagens'] ?? []);
      final newMessages = data.map((m) => Map<String, dynamic>.from(m)).toList();

      if (newMessages.length != _mensagens.length) {
        setState(() { _mensagens = newMessages; });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Erro ao carregar mensagens: $e');
    } finally {
      if (!silent) {
        setState(() => _isLoading = false);
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending || _isBanned) return;

    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    setState(() => _isSending = true);
    _messageController.clear();

    final tempMessage = {
      'id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
      'remetente_id': user.id,
      'mensagem': text,
      'data_envio': DateTime.now().toIso8601String(),
      'lida': false,
      'enviada': true,
    };

    setState(() { _mensagens.add(tempMessage); });
    _scrollToBottom();

    try {
      final response = await _api.post(
        ApiEndpoints.enviarMensagem,
        body: {
          'remetente_id': user.id,
          'destinatario_id': widget.conversaId,
          'mensagem': text,
        },
      );

      // Verificar se a mensagem foi censurada
      if (response != null && response is Map) {
        final censurada = response['censurada'] == true;
        final alerta = response['alerta'];

        if (censurada && alerta != null && mounted) {
          final nivel = alerta['nivel'] ?? 0;
          final mensagemAlerta = alerta['mensagem'] ?? '';

          _showCensorAlert(nivel, mensagemAlerta);
        }

        // Verificar se foi banido
        if (response['banido'] == true && mounted) {
          setState(() => _isBanned = true);
          _showBannedAlert();
        }
      }
    } catch (e) {
      // Verificar se erro é de banimento
      if (e.toString().contains('banido') || e.toString().contains('403')) {
        if (mounted) {
          setState(() => _isBanned = true);
          _showBannedAlert();
        }
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showCensorAlert(int nivel, String mensagem) {
    Color backgroundColor;
    IconData icon;

    switch (nivel) {
      case 1:
        backgroundColor = Colors.orange.shade600;
        icon = Icons.warning_amber;
        break;
      case 2:
        backgroundColor = Colors.red.shade600;
        icon = Icons.error;
        break;
      case 3:
        backgroundColor = Colors.red.shade900;
        icon = Icons.block;
        break;
      default:
        backgroundColor = Colors.orange.shade600;
        icon = Icons.warning_amber;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                mensagem,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: Duration(seconds: nivel >= 2 ? 8 : 5),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showBannedAlert() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.block, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Sua conta foi suspensa por violar as regras da plataforma.',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade900,
        duration: const Duration(seconds: 10),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _sendLocation() async {
    if (_isBanned) return;

    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Permissão de localização negada')),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permissão de localização negada permanentemente')),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      final locationMessage = '📍 Localização: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';

      setState(() => _isSending = true);

      final tempMessage = {
        'id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
        'remetente_id': user.id,
        'mensagem': locationMessage,
        'data_envio': DateTime.now().toIso8601String(),
        'lida': false,
        'enviada': true,
      };

      setState(() { _mensagens.add(tempMessage); });
      _scrollToBottom();

      await _api.post(
        ApiEndpoints.enviarMensagem,
        body: {
          'remetente_id': user.id,
          'destinatario_id': widget.conversaId,
          'mensagem': locationMessage,
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar localização: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: AppColors.gray100,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: _isBanned ? Colors.red : AppColors.primarySurface,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  widget.nomeContato[0].toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _isBanned ? Colors.white : AppColors.primary,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.nomeContato,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _isBanned ? Colors.red.shade700 : null,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (_isBanned) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'BANIDO',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (_isBanned)
                    Text(
                      'Usuário banido',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.red.shade400,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Banner de banimento
          if (_isBanned)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.red.shade50,
              child: Row(
                children: [
                  Icon(Icons.block, color: Colors.red.shade700, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Este aluno foi banido da plataforma',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          'Violou as regras ao compartilhar contatos.',
                          style: TextStyle(
                            color: Colors.red.shade600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _mensagens.length,
                    itemBuilder: (context, index) {
                      final mensagem = _mensagens[index];
                      // Backend retorna 'enviada' como boolean (true = instrutor enviou)
                      final enviada = mensagem['enviada'];
                      final isMe = enviada == true ||
                                   enviada == 'true' ||
                                   enviada == 1 ||
                                   mensagem['remetente_id']?.toString() == user?.id;
                      return _buildMessage(mensagem, isMe);
                    },
                  ),
          ),

          // Input area
          if (_isBanned)
            Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
              color: Colors.red.shade50,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  children: [
                    Icon(Icons.block, color: Colors.red.shade500, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      'Conversa bloqueada',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Este aluno foi banido por violar as regras.',
                      style: TextStyle(
                        color: Colors.red.shade600,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              padding: EdgeInsets.only(
                left: 16, right: 16, top: 12,
                bottom: MediaQuery.of(context).padding.bottom + 12,
              ),
              decoration: BoxDecoration(
                color: AppColors.white,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.location_on_outlined),
                    color: AppColors.primary,
                    onPressed: _sendLocation,
                    tooltip: 'Enviar localização',
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.gray100,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        focusNode: _focusNode,
                        decoration: const InputDecoration(
                          hintText: 'Digite sua mensagem...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    child: IconButton(
                      icon: _isSending
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(AppColors.white)),
                            )
                          : const Icon(Icons.send),
                      color: AppColors.white,
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessage(Map<String, dynamic> mensagem, bool isMe) {
    final text = mensagem['mensagem'] ?? '';
    final dataStr = mensagem['dataEnvio']?.toString() ?? mensagem['data_envio']?.toString();
    final data = dataStr != null ? DateTime.tryParse(dataStr) : null;
    final lida = mensagem['lida'] ?? false;
    final isLocation = text.startsWith('📍 Localização:');

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : AppColors.gray100,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(color: AppColors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (isLocation)
              _buildLocationMessage(text, isMe)
            else
              Text(
                text,
                style: TextStyle(color: isMe ? AppColors.white : AppColors.textPrimary, fontSize: 15),
              ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (data != null)
                  Text(
                    DateFormat('HH:mm').format(data),
                    style: TextStyle(fontSize: 11, color: isMe ? AppColors.white.withOpacity(0.7) : AppColors.gray500),
                  ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    lida ? Icons.done_all : Icons.done,
                    size: 14,
                    color: lida ? AppColors.white : AppColors.white.withOpacity(0.7),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationMessage(String text, bool isMe) {
    final match = RegExp(r'(-?\d+\.?\d*),\s*(-?\d+\.?\d*)').firstMatch(text);
    final lat = match?.group(1) ?? '';
    final lng = match?.group(2) ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.location_on, color: isMe ? AppColors.white : AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Localização compartilhada',
              style: TextStyle(color: isMe ? AppColors.white : AppColors.textPrimary, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildMapButton('Google Maps', Icons.map, isMe, () async {
              final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
              if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
            }),
            const SizedBox(width: 8),
            _buildMapButton('Waze', Icons.navigation, isMe, () async {
              final url = Uri.parse('https://waze.com/ul?ll=$lat,$lng&navigate=yes');
              if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildMapButton(String label, IconData icon, bool isMe, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isMe ? AppColors.white.withOpacity(0.2) : AppColors.primarySurface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isMe ? AppColors.white : AppColors.primary),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 12, color: isMe ? AppColors.white : AppColors.primary, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

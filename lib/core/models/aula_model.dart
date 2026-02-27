class AulaModel {
  final String id;
  final String? alunoId;
  final String? alunoNome;
  final String? instrutorId;
  final String categoria;
  final DateTime dataHora;
  final DateTime? dataCriacao;
  final int duracao;
  final String? local;
  final String status;
  final double valor;
  final String? observacoes;

  AulaModel({
    required this.id,
    this.alunoId,
    this.alunoNome,
    this.instrutorId,
    this.categoria = 'B',
    required this.dataHora,
    this.dataCriacao,
    this.duracao = 50,
    this.local,
    this.status = 'aguardando',
    this.valor = 120.0,
    this.observacoes,
  });

  factory AulaModel.fromJson(Map<String, dynamic> json) {
    return AulaModel(
      id: json['id']?.toString() ?? '',
      alunoId: json['aluno_id']?.toString() ?? json['alunoId']?.toString(),
      alunoNome: json['aluno_nome'] ?? json['alunoNome'],
      instrutorId: json['instrutor_id']?.toString() ?? json['instrutorId']?.toString(),
      categoria: json['categoria'] ?? 'B',
      dataHora: json['data_hora'] != null ? DateTime.parse(json['data_hora']) : DateTime.now(),
      dataCriacao: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      duracao: json['duracao'] ?? 50,
      local: json['local_partida'] ?? json['local'],
      status: json['status'] ?? 'aguardando',
      valor: (json['valor'] ?? 120.0).toDouble(),
      observacoes: json['observacoes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'aluno_id': alunoId,
      'aluno_nome': alunoNome,
      'instrutor_id': instrutorId,
      'categoria': categoria,
      'data_hora': dataHora.toIso8601String(),
      'duracao': duracao,
      'local_partida': local,
      'status': status,
      'valor': valor,
      'observacoes': observacoes,
    };
  }

  String get statusFormatado {
    switch (status.toLowerCase()) {
      case 'aguardando': return 'Aguardando';
      case 'confirmada': return 'Confirmada';
      case 'realizada': return 'Realizada';
      case 'cancelada': return 'Cancelada';
      default: return status;
    }
  }

  String get valorFormatado => 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';

  bool get isPendente => status.toLowerCase() == 'aguardando';
  bool get isConfirmada => status.toLowerCase() == 'confirmada';
  bool get isRealizada => status.toLowerCase() == 'realizada';
  bool get isCancelada => status.toLowerCase() == 'cancelada';
}

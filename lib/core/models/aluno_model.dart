class AlunoModel {
  final String id;
  final String? usuarioId;
  final String nome;
  final String? categoria;
  final int aulasRealizadas;
  final String? proximaAula;
  final double progresso;
  final double? avaliacao;
  final String? telefone;
  final String? email;

  AlunoModel({
    required this.id,
    this.usuarioId,
    required this.nome,
    this.categoria,
    this.aulasRealizadas = 0,
    this.proximaAula,
    this.progresso = 0.0,
    this.avaliacao,
    this.telefone,
    this.email,
  });

  factory AlunoModel.fromJson(Map<String, dynamic> json) {
    return AlunoModel(
      id: json['id']?.toString() ?? '',
      usuarioId: json['usuario_id']?.toString() ?? json['usuarioId']?.toString(),
      nome: json['nome'] ?? json['nome_completo'] ?? json['nomeCompleto'] ?? '',
      categoria: json['categoria'] ?? json['categoria_pretendida'],
      aulasRealizadas: json['aulas_realizadas'] ?? json['aulasRealizadas'] ?? 0,
      proximaAula: json['proxima_aula'] ?? json['proximaAula'],
      progresso: (json['progresso'] ?? 0.0).toDouble(),
      avaliacao: json['avaliacao'] != null ? (json['avaliacao']).toDouble() : null,
      telefone: json['telefone'],
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'usuario_id': usuarioId,
      'nome': nome,
      'categoria': categoria,
      'aulas_realizadas': aulasRealizadas,
      'proxima_aula': proximaAula,
      'progresso': progresso,
      'avaliacao': avaliacao,
      'telefone': telefone,
      'email': email,
    };
  }

  String get iniciais {
    final partes = nome.split(' ');
    if (partes.length >= 2) {
      return '${partes.first[0]}${partes.last[0]}'.toUpperCase();
    }
    return nome.isNotEmpty ? nome[0].toUpperCase() : 'A';
  }

  String get primeiroNome => nome.split(' ').first;
}

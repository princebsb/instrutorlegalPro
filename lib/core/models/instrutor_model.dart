class InstrutorModel {
  final String id;
  final String? biografia;
  final List<String> categoriasHabilitadas;
  final double valorAula;
  final double notaMedia;
  final int totalAvaliacoes;
  final int totalAulasDadas;
  final int anosExperiencia;
  final int alunosAprovados;

  InstrutorModel({
    required this.id,
    this.biografia,
    this.categoriasHabilitadas = const [],
    this.valorAula = 120.0,
    this.notaMedia = 0.0,
    this.totalAvaliacoes = 0,
    this.totalAulasDadas = 0,
    this.anosExperiencia = 0,
    this.alunosAprovados = 0,
  });

  factory InstrutorModel.fromJson(Map<String, dynamic> json) {
    List<String> categorias = [];
    if (json['categorias_habilitadas'] != null) {
      if (json['categorias_habilitadas'] is List) {
        categorias = List<String>.from(json['categorias_habilitadas']);
      } else if (json['categorias_habilitadas'] is String) {
        categorias = (json['categorias_habilitadas'] as String).split(',').map((e) => e.trim()).toList();
      }
    }

    return InstrutorModel(
      id: json['id']?.toString() ?? '',
      biografia: json['biografia'],
      categoriasHabilitadas: categorias,
      valorAula: (json['valor_aula'] ?? json['valorAula'] ?? 120.0).toDouble(),
      notaMedia: (json['nota_media'] ?? json['notaMedia'] ?? 0.0).toDouble(),
      totalAvaliacoes: json['total_avaliacoes'] ?? json['totalAvaliacoes'] ?? 0,
      totalAulasDadas: json['total_aulas_dadas'] ?? json['totalAulasDadas'] ?? 0,
      anosExperiencia: json['anos_experiencia'] ?? json['anosExperiencia'] ?? 0,
      alunosAprovados: json['alunos_aprovados'] ?? json['alunosAprovados'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'biografia': biografia,
      'categorias_habilitadas': categoriasHabilitadas,
      'valor_aula': valorAula,
      'nota_media': notaMedia,
      'total_avaliacoes': totalAvaliacoes,
      'total_aulas_dadas': totalAulasDadas,
      'anos_experiencia': anosExperiencia,
      'alunos_aprovados': alunosAprovados,
    };
  }

  String get categoriasFormatadas => categoriasHabilitadas.join(', ');

  String get valorAulaFormatado => 'R\$ ${valorAula.toStringAsFixed(2).replaceAll('.', ',')}';
}

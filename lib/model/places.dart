// lib/model/places.dart

class PontoTuristico {
  final String nome;
  final String endereco;
  final String categoria;
  final int tempoMinutos;
  final String descricao;
  final double latitude;
  final double longitude;
  final double rating;
  final int totalAvaliacoes;
  final double distanciaMetros;
  final String? photoName;   // Places API (New) usa 'name' do objeto photo
  final String placeId;
  final String? telefone;
  final String? website;
  final bool? aberto;
  final List<String>? horarios;

  PontoTuristico({
    required this.nome,
    required this.endereco,
    required this.categoria,
    required this.tempoMinutos,
    required this.descricao,
    required this.latitude,
    required this.longitude,
    this.rating = 0.0,
    this.totalAvaliacoes = 0,
    this.distanciaMetros = 0.0,
    this.photoName,
    this.placeId = '',
    this.telefone,
    this.website,
    this.aberto,
    this.horarios,
  });

  String get distanciaFormatada {
    if (distanciaMetros < 1000) {
      return '${distanciaMetros.toStringAsFixed(0)}m';
    }
    return '${(distanciaMetros / 1000).toStringAsFixed(1)}km';
  }

  String get statusAberto {
    if (aberto == null) return '';
    return aberto! ? 'Aberto agora' : 'Fechado';
  }

  factory PontoTuristico.mesclar(
    Map<String, dynamic> dadosGoogle,
    Map<String, dynamic> dadosGemini,
  ) {
    return PontoTuristico(
      nome:            dadosGoogle['nome'] ?? 'Lugar sem nome',
      endereco:        dadosGemini['endereco'] ?? dadosGoogle['endereco'] ?? '',
      categoria:       dadosGemini['categoria'] ?? 'Passeio',
      tempoMinutos:    dadosGemini['tempoMinutos'] ?? 60,
      descricao:       dadosGemini['descricao'] ?? 'Sem descrição disponível.',
      latitude:        (dadosGoogle['latitude'] ?? 0.0).toDouble(),
      longitude:       (dadosGoogle['longitude'] ?? 0.0).toDouble(),
      rating:          (dadosGoogle['rating'] ?? 0.0).toDouble(),
      totalAvaliacoes: dadosGoogle['totalAvaliacoes'] ?? 0,
      distanciaMetros: (dadosGoogle['distanciaMetros'] ?? 0.0).toDouble(),
      photoName:       dadosGoogle['photoName'],
      placeId:         dadosGoogle['placeId'] ?? '',
      telefone:        dadosGoogle['telefone'],
      website:         dadosGoogle['website'],
      aberto:          dadosGoogle['aberto'],
      horarios:        dadosGoogle['horarios'] != null
          ? List<String>.from(dadosGoogle['horarios'])
          : null,
    );
  }
}

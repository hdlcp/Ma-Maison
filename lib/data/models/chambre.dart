class Chambre {
  final int? id;
  final String numero;
  final String? taille;
  final String type;
  final int maisonId;
  final bool estOccupee;

  Chambre({
    this.id,
    required this.numero,
    this.taille,
    required this.type,
    required this.maisonId,
    this.estOccupee = false,
  });

  factory Chambre.fromMap(Map<String, dynamic> map) {
    return Chambre(
      id: map['id'],
      numero: map['numero'],
      taille: map['taille'],
      type: map['type'],
      maisonId: map['maison_id'],
      estOccupee: map['est_occupee'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'numero': numero,
      'taille': taille,
      'type': type,
      'maison_id': maisonId,
      'est_occupee': estOccupee ? 1 : 0,
    };
  }
}

class Maison {
  final int? id;
  final String nom;
  final String adresse;
  final DateTime dateCreation;
  final double prixParDefaut;

  Maison({
    this.id,
    required this.nom,
    required this.adresse,
    DateTime? dateCreation,
    this.prixParDefaut = 0.0,
  }) : dateCreation = dateCreation ?? DateTime.now();

  factory Maison.fromMap(Map<String, dynamic> map) {
    return Maison(
      id: map['id'],
      nom: map['nom'],
      adresse: map['adresse'],
      dateCreation: DateTime.parse(map['date_creation']),
      prixParDefaut: map['prix_par_defaut'] ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'adresse': adresse,
      'date_creation': dateCreation.toIso8601String(),
      'prix_par_defaut': prixParDefaut,
    };
  }
}

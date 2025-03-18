class Locataire {
  final int? id;
  final String nom;
  final String? prenom;
  final String? telephone;
  final String? email;
  final DateTime dateEntree;
  final int chambreId;
  final String periodePaiement;
  final double montantLoyer;

  Locataire({
    this.id,
    required this.nom,
    this.prenom,
    this.telephone,
    this.email,
    required this.dateEntree,
    required this.chambreId,
    required this.periodePaiement,
    required this.montantLoyer,
  });

  factory Locataire.fromMap(Map<String, dynamic> map) {
    return Locataire(
      id: map['id'],
      nom: map['nom'],
      prenom: map['prenom'],
      telephone: map['telephone'],
      email: map['email'],
      dateEntree: DateTime.parse(map['date_entree']),
      chambreId: map['chambre_id'],
      periodePaiement: map['periode_paiement'],
      montantLoyer: map['montant_loyer'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      'telephone': telephone,
      'email': email,
      'date_entree': dateEntree.toIso8601String().substring(0, 10),
      'chambre_id': chambreId,
      'periode_paiement': periodePaiement,
      'montant_loyer': montantLoyer,
    };
  }

  String get nomComplet => prenom != null ? '$prenom $nom' : nom;
}

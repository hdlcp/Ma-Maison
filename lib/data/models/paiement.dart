// Enum pour les statuts de paiement
class StatutPaiement {
  static const String paye = 'payé';
  static const String partiel = 'partiel';
  static const String impaye = 'impayé';
  static const String enRetard = 'en retard';
}

class Paiement {
  final int? id;
  final int locataireId;
  final DateTime dateEcheance;
  final DateTime? datePaiement;
  final double montant;
  final String statut;
  final String? methodePaiement;
  final String? notes;

  Paiement({
    this.id,
    required this.locataireId,
    required this.dateEcheance,
    this.datePaiement,
    required this.montant,
    required this.statut,
    this.methodePaiement,
    this.notes,
  });

  factory Paiement.fromMap(Map<String, dynamic> map) {
    return Paiement(
      id: map['id'],
      locataireId: map['locataire_id'],
      dateEcheance: DateTime.parse(map['date_echeance']),
      datePaiement:
          map['date_paiement'] != null
              ? DateTime.parse(map['date_paiement'])
              : null,
      montant: map['montant'],
      statut: map['statut'],
      methodePaiement: map['methode_paiement'],
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'locataire_id': locataireId,
      'date_echeance': dateEcheance.toIso8601String().substring(0, 10),
      'date_paiement': datePaiement?.toIso8601String().substring(0, 10),
      'montant': montant,
      'statut': statut,
      'methode_paiement': methodePaiement,
      'notes': notes,
    };
  }
}

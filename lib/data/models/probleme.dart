class Probleme {
  final int? id;
  final int? maisonId;
  final int? chambreId;
  final String type;
  final String urgence;
  final String description;
  final DateTime dateSignalement;
  final String? photoUrl;
  final String statut;
  final String? notes;

  Probleme({
    this.id,
    this.maisonId,
    this.chambreId,
    required this.type,
    required this.urgence,
    required this.description,
    DateTime? dateSignalement,
    this.photoUrl,
    String? statut,
    this.notes,
  }) : dateSignalement = dateSignalement ?? DateTime.now(),
       statut = statut ?? 'signalé';

  factory Probleme.fromMap(Map<String, dynamic> map) {
    return Probleme(
      id: map['id'],
      maisonId: map['maison_id'],
      chambreId: map['chambre_id'],
      type: map['type'],
      urgence: map['urgence'],
      description: map['description'],
      dateSignalement: DateTime.parse(map['date_signalement']),
      photoUrl: map['photo_url'],
      statut: map['statut'],
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'maison_id': maisonId,
      'chambre_id': chambreId,
      'type': type,
      'urgence': urgence,
      'description': description,
      'date_signalement': dateSignalement.toIso8601String().substring(0, 10),
      'photo_url': photoUrl,
      'statut': statut,
      'notes': notes,
    };
  }

  // Types de problèmes prédéfinis
  static List<String> getTypesList() {
    return [
      'Plomberie',
      'Électricité',
      'Structure',
      'Chauffage',
      'Climatisation',
      'Sécurité',
      'Meubles',
      'Appareils',
      'Autre',
    ];
  }

  // Niveaux d'urgence prédéfinis
  static List<String> getUrgencesList() {
    return ['Faible', 'Moyenne', 'Élevée', 'Critique'];
  }

  // Statuts possibles
  static List<String> getStatutsList() {
    return ['signalé', 'en cours', 'résolu', 'annulé'];
  }
}

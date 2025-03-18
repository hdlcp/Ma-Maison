import 'package:gestion_locative/data/database/database_helper.dart';
import 'package:gestion_locative/data/models/paiement.dart';
import 'package:gestion_locative/data/models/locataire.dart';
import 'package:sqflite/sqflite.dart';

class PaiementRepository {
  final dbHelper = DatabaseHelper.instance;

  Future<List<Paiement>> getAllPaiements() async {
    final db = await dbHelper.database;
    final result = await db.query('paiements', orderBy: 'date_echeance DESC');
    return result.map((map) => Paiement.fromMap(map)).toList();
  }

  Future<List<Map<String, dynamic>>> getRecentPaiements(int limit) async {
    final db = await dbHelper.database;

    const query = '''
      SELECT 
        p.id, p.montant, p.statut, p.date_paiement,
        l.nom, l.prenom
      FROM paiements p
      JOIN locataires l ON p.locataire_id = l.id
      ORDER BY p.date_paiement DESC NULLS LAST, p.date_echeance DESC
      LIMIT ?
    ''';

    final result = await db.rawQuery(query, [limit]);
    return result;
  }

  Future<Map<String, dynamic>> getPaiementStats() async {
    final db = await dbHelper.database;

    // Obtenir le montant total des paiements payés
    final totalPaye =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT SUM(montant) FROM paiements WHERE statut = "payé"',
          ),
        ) ??
        0;

    // Obtenir le montant total des paiements en cours
    final totalEnCours =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT SUM(montant) FROM paiements WHERE statut = "en cours"',
          ),
        ) ??
        0;

    // Obtenir le nombre de paiements en retard
    final nombreRetard =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM paiements WHERE statut IN ("impayé", "en retard")',
          ),
        ) ??
        0;

    return {
      'totalPaye': totalPaye,
      'totalEnCours': totalEnCours,
      'nombreRetard': nombreRetard,
    };
  }

  Future<int> updatePaiementStatut(int id, String statut) async {
    final db = await dbHelper.database;
    return await db.update(
      'paiements',
      {
        'statut': statut,
        'date_paiement':
            statut == 'payé'
                ? DateTime.now().toIso8601String().substring(0, 10)
                : null,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Récupérer les paiements en retard
  Future<List<Paiement>> getPaiementsEnRetard() async {
    final db = await dbHelper.database;
    final result = await db.query(
      'paiements',
      where: 'statut IN (?, ?)',
      whereArgs: ['impayé', 'en retard'],
      orderBy: 'date_echeance ASC',
    );

    return result.map((map) => Paiement.fromMap(map)).toList();
  }

  // Récupérer un paiement par son ID
  Future<Paiement> getPaiementById(int id) async {
    final db = await dbHelper.database;
    final maps = await db.query('paiements', where: 'id = ?', whereArgs: [id]);

    if (maps.isNotEmpty) {
      return Paiement.fromMap(maps.first);
    }

    throw Exception('Paiement non trouvé');
  }

  // Insérer un nouveau paiement
  Future<int> insertPaiement(Paiement paiement) async {
    final db = await dbHelper.database;
    return await db.insert('paiements', paiement.toMap());
  }

  // Mettre à jour un paiement existant
  Future<int> updatePaiement(Paiement paiement) async {
    final db = await dbHelper.database;
    return await db.update(
      'paiements',
      paiement.toMap(),
      where: 'id = ?',
      whereArgs: [paiement.id],
    );
  }

  // Récupérer le locataire associé à un paiement
  Future<Locataire?> getLocataireForPaiement(int paiementId) async {
    final db = await dbHelper.database;

    final paiements = await db.query(
      'paiements',
      where: 'id = ?',
      whereArgs: [paiementId],
    );

    if (paiements.isEmpty) {
      return null;
    }

    final locataireId = paiements.first['locataire_id'] as int;
    final locataires = await db.query(
      'locataires',
      where: 'id = ?',
      whereArgs: [locataireId],
    );

    if (locataires.isEmpty) {
      return null;
    }

    return Locataire.fromMap(locataires.first);
  }

  // Générer des paiements récurrents pour tous les locataires
  Future<Map<String, dynamic>> genererPaiementsRecurrents() async {
    final db = await dbHelper.database;
    int paiementsGeneres = 0;
    List<int> locatairesAvecErreurs = [];

    try {
      // Récupérer tous les locataires actifs
      final locataires = await db.query('locataires');

      for (final locataireMap in locataires) {
        try {
          final locataire = Locataire.fromMap(locataireMap);
          if (locataire.id == null) continue;

          // Vérifier si un paiement existe déjà pour ce mois
          final maintenant = DateTime.now();
          final premierJourDuMois = DateTime(
            maintenant.year,
            maintenant.month,
            1,
          );
          final dernierJourDuMois = DateTime(
            maintenant.year,
            maintenant.month + 1,
            0,
          );

          final paiementsExistants = await db.query(
            'paiements',
            where: 'locataire_id = ? AND date_echeance BETWEEN ? AND ?',
            whereArgs: [
              locataire.id,
              premierJourDuMois.toIso8601String().substring(0, 10),
              dernierJourDuMois.toIso8601String().substring(0, 10),
            ],
          );

          if (paiementsExistants.isEmpty) {
            // Déterminer la date d'échéance en fonction de la période de paiement
            DateTime dateEcheance;
            switch (locataire.periodePaiement) {
              case 'mensuel':
                // Habituellement le 5 du mois en cours
                dateEcheance = DateTime(maintenant.year, maintenant.month, 5);
                if (dateEcheance.isBefore(maintenant)) {
                  // Si nous sommes déjà passé le 5, utiliser le mois prochain
                  dateEcheance = DateTime(
                    maintenant.year,
                    maintenant.month + 1,
                    5,
                  );
                }
                break;
              case 'trimestriel':
                // Déterminer le trimestre actuel
                int trimestre = ((maintenant.month - 1) ~/ 3) + 1;
                // Premier jour du prochain trimestre
                dateEcheance = DateTime(
                  maintenant.year,
                  (trimestre * 3) + 1,
                  5,
                );
                break;
              case 'semestriel':
                // Déterminer le semestre actuel
                int semestre = ((maintenant.month - 1) ~/ 6) + 1;
                // Premier jour du prochain semestre
                dateEcheance = DateTime(maintenant.year, (semestre * 6) + 1, 5);
                break;
              case 'annuel':
                // Utiliser le même jour et mois que la date d'entrée, mais pour l'année suivante
                dateEcheance = DateTime(
                  locataire.dateEntree.year +
                      (maintenant.year - locataire.dateEntree.year) +
                      1,
                  locataire.dateEntree.month,
                  locataire.dateEntree.day,
                );
                break;
              default:
                // Par défaut, mensuel au 5 du mois
                dateEcheance = DateTime(maintenant.year, maintenant.month, 5);
            }

            // Créer le nouveau paiement
            final nouveauPaiement = {
              'locataire_id': locataire.id,
              'date_echeance': dateEcheance.toIso8601String().substring(0, 10),
              'montant': locataire.montantLoyer,
              'statut': 'en cours',
              'date_paiement': null,
              'methode_paiement': null,
              'notes':
                  'Généré automatiquement le ${maintenant.toIso8601String().substring(0, 10)}',
            };

            await db.insert('paiements', nouveauPaiement);
            paiementsGeneres++;
          }
        } catch (e) {
          if (locataireMap['id'] != null) {
            locatairesAvecErreurs.add(locataireMap['id'] as int);
          }
        }
      }

      return {
        'success': true,
        'paiementsGeneres': paiementsGeneres,
        'locatairesAvecErreurs': locatairesAvecErreurs,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'paiementsGeneres': paiementsGeneres,
        'locatairesAvecErreurs': locatairesAvecErreurs,
      };
    }
  }
}

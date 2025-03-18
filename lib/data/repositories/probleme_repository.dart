import 'package:gestion_locative/data/database/database_helper.dart';
import 'package:gestion_locative/data/models/probleme.dart';
import 'package:gestion_locative/data/models/maison.dart';
import 'package:gestion_locative/data/models/chambre.dart';

class ProblemeRepository {
  final dbHelper = DatabaseHelper.instance;

  // Récupérer tous les problèmes
  Future<List<Probleme>> getAllProblemes() async {
    final db = await dbHelper.database;
    final result = await db.query(
      'problemes',
      orderBy: 'date_signalement DESC',
    );
    return result.map((map) => Probleme.fromMap(map)).toList();
  }

  // Récupérer les problèmes non résolus
  Future<List<Probleme>> getProblemesByStatut(String statut) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'problemes',
      where: 'statut = ?',
      whereArgs: [statut],
      orderBy: 'date_signalement DESC',
    );
    return result.map((map) => Probleme.fromMap(map)).toList();
  }

  // Récupérer un problème par son ID
  Future<Probleme> getProblemeById(int id) async {
    final db = await dbHelper.database;
    final maps = await db.query('problemes', where: 'id = ?', whereArgs: [id]);

    if (maps.isNotEmpty) {
      return Probleme.fromMap(maps.first);
    }

    throw Exception('Problème non trouvé');
  }

  // Ajouter un nouveau problème
  Future<int> insertProbleme(Probleme probleme) async {
    final db = await dbHelper.database;
    return await db.insert('problemes', probleme.toMap());
  }

  // Mettre à jour un problème existant
  Future<int> updateProbleme(Probleme probleme) async {
    final db = await dbHelper.database;
    return await db.update(
      'problemes',
      probleme.toMap(),
      where: 'id = ?',
      whereArgs: [probleme.id],
    );
  }

  // Mettre à jour le statut d'un problème
  Future<int> updateStatutProbleme(int id, String statut) async {
    final db = await dbHelper.database;
    return await db.update(
      'problemes',
      {'statut': statut},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Supprimer un problème
  Future<int> deleteProbleme(int id) async {
    final db = await dbHelper.database;
    return await db.delete('problemes', where: 'id = ?', whereArgs: [id]);
  }

  // Récupérer la maison associée à un problème
  Future<Maison?> getMaisonForProbleme(int problemeId) async {
    final db = await dbHelper.database;
    final probleme = await getProblemeById(problemeId);

    if (probleme.maisonId == null) return null;

    final maisonMaps = await db.query(
      'maisons',
      where: 'id = ?',
      whereArgs: [probleme.maisonId],
    );

    if (maisonMaps.isEmpty) return null;

    return Maison.fromMap(maisonMaps.first);
  }

  // Récupérer la chambre associée à un problème
  Future<Chambre?> getChambreForProbleme(int problemeId) async {
    final db = await dbHelper.database;
    final probleme = await getProblemeById(problemeId);

    if (probleme.chambreId == null) return null;

    final chambreMaps = await db.query(
      'chambres',
      where: 'id = ?',
      whereArgs: [probleme.chambreId],
    );

    if (chambreMaps.isEmpty) return null;

    return Chambre.fromMap(chambreMaps.first);
  }

  // Récupérer des statistiques sur les problèmes
  Future<Map<String, dynamic>> getProblemeStats() async {
    final db = await dbHelper.database;

    final totalProblemes = await db.rawQuery('SELECT COUNT(*) FROM problemes');
    final totalNonResolus = await db.rawQuery(
      'SELECT COUNT(*) FROM problemes WHERE statut != "résolu"',
    );
    final totalUrgent = await db.rawQuery(
      'SELECT COUNT(*) FROM problemes WHERE urgence IN ("Élevée", "Critique") AND statut != "résolu"',
    );

    return {
      'totalProblemes': totalProblemes.first['COUNT(*)'] as int,
      'totalNonResolus': totalNonResolus.first['COUNT(*)'] as int,
      'totalUrgent': totalUrgent.first['COUNT(*)'] as int,
    };
  }
}

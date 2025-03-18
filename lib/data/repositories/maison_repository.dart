import 'package:gestion_locative/data/database/database_helper.dart';
import 'package:gestion_locative/data/models/maison.dart';
import 'package:gestion_locative/data/models/chambre.dart';
import 'package:sqflite/sqflite.dart';

class MaisonRepository {
  final dbHelper = DatabaseHelper.instance;

  Future<List<Maison>> getAllMaisons() async {
    final db = await dbHelper.database;
    final result = await db.query('maisons');
    return result.map((map) => Maison.fromMap(map)).toList();
  }

  Future<Maison> getMaisonById(int id) async {
    final db = await dbHelper.database;
    final maps = await db.query('maisons', where: 'id = ?', whereArgs: [id]);

    if (maps.isNotEmpty) {
      return Maison.fromMap(maps.first);
    }

    throw Exception('Maison non trouvée');
  }

  Future<int> insertMaison(Maison maison) async {
    final db = await dbHelper.database;
    return await db.insert('maisons', maison.toMap());
  }

  Future<int> updateMaison(Maison maison) async {
    final db = await dbHelper.database;
    return await db.update(
      'maisons',
      maison.toMap(),
      where: 'id = ?',
      whereArgs: [maison.id],
    );
  }

  Future<int> deleteMaison(int id) async {
    final db = await dbHelper.database;
    return await db.delete('maisons', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>> getMaisonStats() async {
    final db = await dbHelper.database;

    // Obtenir le nombre total de maisons
    final maisonCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM maisons'),
    );

    // Obtenir le nombre total de chambres
    final chambreCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM chambres'),
    );

    // Obtenir le nombre de locataires (chambres occupées)
    final locataireCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM locataires'),
    );

    // Calculer le pourcentage d'occupation
    final occupationRate =
        chambreCount != null && chambreCount > 0
            ? (locataireCount ?? 0) / chambreCount * 100
            : 0.0;

    return {
      'maisonCount': maisonCount ?? 0,
      'chambreCount': chambreCount ?? 0,
      'locataireCount': locataireCount ?? 0,
      'occupationRate': occupationRate.toStringAsFixed(1),
    };
  }

  Future<List<Map<String, dynamic>>> getMaisonsWithStats() async {
    final db = await dbHelper.database;

    const query = '''
      SELECT 
        m.id, m.nom, m.adresse,
        COUNT(DISTINCT c.id) AS nombre_chambres,
        COUNT(DISTINCT l.id) AS nombre_locataires
      FROM maisons m
      LEFT JOIN chambres c ON m.id = c.maison_id
      LEFT JOIN locataires l ON c.id = l.chambre_id
      GROUP BY m.id
    ''';

    final result = await db.rawQuery(query);
    return result;
  }

  // Méthode pour récupérer les chambres d'une maison
  Future<List<Chambre>> getChambresForMaison(int maisonId) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'chambres',
      where: 'maison_id = ?',
      whereArgs: [maisonId],
    );

    return result.map((map) => Chambre.fromMap(map)).toList();
  }

  // Méthode pour récupérer une chambre par son ID
  Future<Chambre?> getChambreById(int id) async {
    final db = await dbHelper.database;
    final maps = await db.query('chambres', where: 'id = ?', whereArgs: [id]);

    if (maps.isNotEmpty) {
      return Chambre.fromMap(maps.first);
    }

    return null;
  }

  // Méthode pour ajouter une chambre
  Future<int> insertChambre(Chambre chambre) async {
    final db = await dbHelper.database;
    return await db.insert('chambres', chambre.toMap());
  }
}

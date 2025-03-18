import 'package:gestion_locative/data/database/database_helper.dart';
import 'package:gestion_locative/data/models/locataire.dart';

class LocataireRepository {
  final dbHelper = DatabaseHelper.instance;

  Future<List<Locataire>> getAllLocataires() async {
    final db = await dbHelper.database;
    final result = await db.query('locataires');
    return result.map((map) => Locataire.fromMap(map)).toList();
  }

  Future<Locataire> getLocataireById(int id) async {
    final db = await dbHelper.database;
    final maps = await db.query('locataires', where: 'id = ?', whereArgs: [id]);

    if (maps.isNotEmpty) {
      return Locataire.fromMap(maps.first);
    }

    throw Exception('Locataire non trouvé');
  }

  Future<int> insertLocataire(Locataire locataire) async {
    final db = await dbHelper.database;
    return await db.insert('locataires', locataire.toMap());
  }

  Future<int> updateLocataire(Locataire locataire) async {
    final db = await dbHelper.database;
    return await db.update(
      'locataires',
      locataire.toMap(),
      where: 'id = ?',
      whereArgs: [locataire.id],
    );
  }

  Future<int> deleteLocataire(int id) async {
    final db = await dbHelper.database;
    return await db.delete('locataires', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Locataire>> getLocatairesForChambre(int chambreId) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'locataires',
      where: 'chambre_id = ?',
      whereArgs: [chambreId],
    );
    return result.map((map) => Locataire.fromMap(map)).toList();
  }
}

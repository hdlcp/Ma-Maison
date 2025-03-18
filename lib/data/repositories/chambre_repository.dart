import 'package:gestion_locative/data/database/database_helper.dart';
import 'package:gestion_locative/data/models/chambre.dart';

class ChambreRepository {
  final dbHelper = DatabaseHelper.instance;

  // Récupérer une chambre par son ID
  Future<Chambre?> getChambreById(int id) async {
    final db = await dbHelper.database;
    final maps = await db.query('chambres', where: 'id = ?', whereArgs: [id]);

    if (maps.isNotEmpty) {
      return Chambre.fromMap(maps.first);
    }

    return null;
  }

  // Mettre à jour le statut d'occupation d'une chambre
  Future<int> updateChambreOccupation(int id, bool estOccupee) async {
    final db = await dbHelper.database;
    return await db.update(
      'chambres',
      {'est_occupee': estOccupee ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

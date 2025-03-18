import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('gestion_locative.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE maisons (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nom TEXT NOT NULL,
      adresse TEXT NOT NULL,
      date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      prix_par_defaut REAL DEFAULT 0.0
    )
    ''');

    await db.execute('''
    CREATE TABLE chambres (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      numero TEXT NOT NULL,
      taille TEXT,
      type TEXT NOT NULL,
      maison_id INTEGER NOT NULL,
      est_occupee INTEGER DEFAULT 0,
      FOREIGN KEY (maison_id) REFERENCES maisons(id) ON DELETE CASCADE
    )
    ''');

    await db.execute('''
    CREATE TABLE locataires (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nom TEXT NOT NULL,
      prenom TEXT,
      telephone TEXT,
      email TEXT,
      date_entree DATE NOT NULL,
      chambre_id INTEGER NOT NULL,
      periode_paiement TEXT NOT NULL,
      montant_loyer REAL NOT NULL,
      FOREIGN KEY (chambre_id) REFERENCES chambres(id) ON DELETE CASCADE
    )
    ''');

    await db.execute('''
    CREATE TABLE paiements (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      locataire_id INTEGER NOT NULL,
      date_echeance DATE NOT NULL,
      date_paiement DATE,
      montant REAL NOT NULL,
      statut TEXT NOT NULL,
      methode_paiement TEXT,
      notes TEXT,
      FOREIGN KEY (locataire_id) REFERENCES locataires(id) ON DELETE CASCADE
    )
    ''');

    await db.execute('''
    CREATE TABLE problemes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      maison_id INTEGER,
      chambre_id INTEGER,
      type TEXT NOT NULL,
      urgence TEXT NOT NULL,
      description TEXT NOT NULL,
      date_signalement DATE NOT NULL,
      photo_url TEXT,
      statut TEXT NOT NULL,
      notes TEXT,
      FOREIGN KEY (maison_id) REFERENCES maisons(id) ON DELETE SET NULL,
      FOREIGN KEY (chambre_id) REFERENCES chambres(id) ON DELETE SET NULL
    )
    ''');

    // Insérer des données de test
    await _insertTestData(db);
  }

  Future _insertTestData(Database db) async {
    // Insérer des maisons de test
    await db.insert('maisons', {
      'nom': 'Résidence Alpha',
      'adresse': '123 Rue Principale',
      'prix_par_defaut': 25000.0,
    });

    await db.insert('maisons', {
      'nom': 'Villa Omega',
      'adresse': '45 Avenue Centrale',
      'prix_par_defaut': 30000.0,
    });

    // Insérer des chambres de test
    for (int i = 1; i <= 5; i++) {
      await db.insert('chambres', {
        'numero': 'A$i',
        'type': i % 2 == 0 ? 'double' : 'simple',
        'taille': '${12 + i} m²',
        'maison_id': 1,
        'est_occupee': i <= 3 ? 1 : 0, // Les 3 premières chambres sont occupées
      });
    }

    for (int i = 1; i <= 3; i++) {
      await db.insert('chambres', {
        'numero': 'B$i',
        'type': 'simple',
        'taille': '${14 + i} m²',
        'maison_id': 2,
        'est_occupee': i <= 3 ? 1 : 0, // Toutes les chambres sont occupées
      });
    }

    // Insérer des locataires de test
    final locataires = [
      {
        'nom': 'Dupont',
        'prenom': 'Marie',
        'telephone': '0600000001',
        'email': 'marie@example.com',
        'date_entree': '2023-01-01',
        'chambre_id': 1,
        'periode_paiement': 'mensuel',
        'montant_loyer': 30000.0,
      },
      {
        'nom': 'Martin',
        'prenom': 'Thomas',
        'telephone': '0600000002',
        'email': 'thomas@example.com',
        'date_entree': '2023-02-01',
        'chambre_id': 2,
        'periode_paiement': 'mensuel',
        'montant_loyer': 25000.0,
      },
      {
        'nom': 'Benamar',
        'prenom': 'Ahmed',
        'telephone': '0600000003',
        'email': 'ahmed@example.com',
        'date_entree': '2023-03-01',
        'chambre_id': 3,
        'periode_paiement': 'mensuel',
        'montant_loyer': 22000.0,
      },
    ];

    for (var locataire in locataires) {
      int id = await db.insert('locataires', locataire);

      // Créer des paiements pour chaque locataire
      await db.insert('paiements', {
        'locataire_id': id,
        'date_echeance':
            DateTime.now().add(Duration(days: -15)).toString().substring(0, 10),
        'date_paiement':
            DateTime.now().add(Duration(days: -13)).toString().substring(0, 10),
        'montant': locataire['montant_loyer'],
        'statut': 'payé',
        'methode_paiement': 'espèces',
      });

      // Paiement du mois en cours
      await db.insert('paiements', {
        'locataire_id': id,
        'date_echeance':
            DateTime.now().add(Duration(days: 15)).toString().substring(0, 10),
        'date_paiement': id != 2
            ? DateTime.now().add(Duration(days: -2)).toString().substring(0, 10)
            : null,
        'montant': locataire['montant_loyer'],
        'statut': id != 2 ? 'payé' : 'en cours',
        'methode_paiement': id != 2 ? 'espèces' : null,
      });
    }

    // Ajouter un paiement en retard pour le test
    await db.insert('paiements', {
      'locataire_id': 1,
      'date_echeance':
          DateTime.now().add(Duration(days: -5)).toString().substring(0, 10),
      'date_paiement': null,
      'montant': 30000.0,
      'statut': 'impayé',
      'methode_paiement': null,
      'notes': 'Relance à effectuer',
    });
  }

  // 🔴 Supprimer toutes les données de toutes les tables
  Future<void> clearDatabase() async {
    final db = await database;
    final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'");

    for (var table in tables) {
      String tableName = table['name'] as String;
      await db.delete(tableName);
    }
  }
}

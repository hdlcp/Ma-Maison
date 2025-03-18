# README - Application de Gestion Locative

## Aperçu du Projet

Cette application mobile développée avec Flutter permet de gérer des maisons, leurs chambres et les locataires associés. Elle offre un suivi efficace des paiements de loyer et fonctionne en mode hors-ligne grâce à SQLite.

## Fonctionnalités Principales

1. **Gestion des Maisons**: Ajout, modification et suppression de maisons
2. **Gestion des Chambres**: Organisation des chambres par maison 
3. **Gestion des Locataires**: Suivi des occupants par chambre
4. **Suivi des Paiements**: Contrôle des loyers (payés, en cours, impayés, en retard)
5. **Fonctionnement Hors-ligne**: Toutes les données sont stockées localement

## Architecture de la Base de Données SQLite

### Structure des Tables

```sql
-- Table des maisons
CREATE TABLE maisons (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nom TEXT NOT NULL,
    adresse TEXT NOT NULL,
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table des chambres
CREATE TABLE chambres (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    numero TEXT NOT NULL,
    taille TEXT,
    type TEXT NOT NULL,  -- 'simple', 'double', etc.
    maison_id INTEGER NOT NULL,
    FOREIGN KEY (maison_id) REFERENCES maisons(id) ON DELETE CASCADE
);

-- Table des locataires
CREATE TABLE locataires (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nom TEXT NOT NULL,
    prenom TEXT,
    telephone TEXT,
    email TEXT,
    date_entree DATE NOT NULL,
    chambre_id INTEGER NOT NULL,
    periode_paiement TEXT NOT NULL, -- 'mensuel', 'trimestriel', etc.
    montant_loyer REAL NOT NULL,
    FOREIGN KEY (chambre_id) REFERENCES chambres(id) ON DELETE CASCADE
);

-- Table des paiements
CREATE TABLE paiements (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    locataire_id INTEGER NOT NULL,
    date_echeance DATE NOT NULL,
    date_paiement DATE,
    montant REAL NOT NULL,
    statut TEXT NOT NULL, -- 'payé', 'en cours', 'impayé', 'en retard'
    methode_paiement TEXT, -- 'espèces', 'virement', 'chèque', etc.
    notes TEXT,
    FOREIGN KEY (locataire_id) REFERENCES locataires(id) ON DELETE CASCADE
);

-- Table de configuration
CREATE TABLE configuration (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    cle TEXT UNIQUE NOT NULL,
    valeur TEXT NOT NULL
);

-- Trigger pour générer automatiquement les paiements lors de l'ajout d'un locataire
CREATE TRIGGER generer_paiements_apres_insertion
AFTER INSERT ON locataires
BEGIN
    -- Générer le premier paiement pour le nouveau locataire
    INSERT INTO paiements (locataire_id, date_echeance, montant, statut)
    VALUES (NEW.id, 
            CASE 
                WHEN NEW.periode_paiement = 'mensuel' THEN date(NEW.date_entree, '+1 month')
                WHEN NEW.periode_paiement = 'trimestriel' THEN date(NEW.date_entree, '+3 month')
                ELSE date(NEW.date_entree, '+1 month')
            END,
            NEW.montant_loyer,
            'en cours');
END;

-- Vue pour afficher les paiements en retard
CREATE VIEW paiements_en_retard AS
SELECT 
    l.nom || ' ' || COALESCE(l.prenom, '') AS nom_locataire,
    m.nom AS nom_maison,
    c.numero AS numero_chambre,
    p.date_echeance,
    p.montant,
    julianday('now') - julianday(p.date_echeance) AS jours_retard
FROM paiements p
JOIN locataires l ON p.locataire_id = l.id
JOIN chambres c ON l.chambre_id = c.id
JOIN maisons m ON c.maison_id = m.id
WHERE p.statut IN ('impayé', 'en retard')
AND p.date_echeance < date('now');

-- Vue pour le tableau de bord
CREATE VIEW dashboard AS
SELECT 
    m.nom AS maison,
    COUNT(DISTINCT c.id) AS nombre_chambres,
    COUNT(DISTINCT l.id) AS nombre_locataires,
    SUM(CASE WHEN p.statut = 'payé' THEN p.montant ELSE 0 END) AS loyers_payes,
    SUM(CASE WHEN p.statut IN ('impayé', 'en retard') THEN p.montant ELSE 0 END) AS loyers_impayes
FROM maisons m
LEFT JOIN chambres c ON m.id = c.maison_id
LEFT JOIN locataires l ON c.id = l.chambre_id
LEFT JOIN paiements p ON l.id = p.locataire_id
GROUP BY m.id;
```

### Relations entre Tables

- Une **maison** peut avoir plusieurs **chambres** (relation one-to-many)
- Une **chambre** peut avoir plusieurs **locataires** (relation one-to-many)
- Un **locataire** peut avoir plusieurs **paiements** (relation one-to-many)

## Écrans de l'Application

1. **Écran d'Accueil / Dashboard**
   - Liste des maisons avec statistiques (nombre de chambres, taux d'occupation)
   - Aperçu des paiements en retard
   - Menu d'accès rapide aux fonctionnalités

2. **Gestion des Maisons**
   - Liste des maisons avec options d'ajout/modification/suppression
   - Visualisation des détails d'une maison (adresse, nombre de chambres, etc.)

3. **Détails d'une Maison**
   - Liste des chambres de la maison
   - Taux d'occupation
   - Total des revenus générés/attendus

4. **Gestion des Chambres**
   - Liste des chambres d'une maison sélectionnée
   - Ajout/modification/suppression de chambres
   - Consultation des détails d'une chambre (type, taille, locataires)

5. **Détails d'une Chambre**
   - Informations sur la chambre (numéro, type, taille)
   - Liste des locataires actuels
   - Historique des occupations

6. **Gestion des Locataires**
   - Liste des locataires avec filtres (par maison, par statut de paiement)
   - Ajout/modification/suppression de locataires
   - Détails d'un locataire (informations personnelles, historique de paiement)

7. **Suivi des Paiements**
   - Tableau de bord des paiements (payés, en cours, impayés, en retard)
   - Calendrier des échéances
   - Génération de rappels de paiement

8. **Paramètres**
   - Configurations générales de l'application
   - Options d'exportation/importation des données
   - Sauvegarde et restauration

## Fonctionnalités Supplémentaires Suggérées

1. **Système de Rappels**
   - Notifications automatiques pour les loyers à payer
   - Rappels personnalisables (quelques jours avant l'échéance)

2. **Génération de Quittances**
   - Création de quittances de loyer PDF
   - Option de partage direct avec les locataires (WhatsApp, email)

3. **Tableau de Bord Analytique**
   - Graphiques sur les revenus mensuels/annuels
   - Taux d'occupation par maison/période
   - Statistiques de paiement (à temps, en retard, etc.)

4. **Gestion des Contrats**
   - Stockage des contrats de location
   - Alertes pour les fins de contrat
   - Modèles de contrats personnalisables

5. **Gestion des Charges**
   - Suivi des dépenses liées aux maisons (eau, électricité, etc.)
   - Calcul de la rentabilité par propriété

## Implémentation Technique

### Installation et Configuration SQLite avec Flutter

```dart
// Ajout des dépendances dans pubspec.yaml
// dependencies:
//   sqflite: ^2.3.0
//   path: ^1.8.3

// Importer les packages
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// Configuration de la base de données
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
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }
  
  Future _createDB(Database db, int version) async {
    // Création des tables ici 
    // (insérer les scripts SQL définis ci-dessus)
  }
}
```

### Exemples de Requêtes SQL Essentielles

1. **Récupérer les maisons avec nombre de chambres et locataires**:
```sql
SELECT 
  m.id, m.nom, m.adresse,
  COUNT(DISTINCT c.id) AS nombre_chambres,
  COUNT(DISTINCT l.id) AS nombre_locataires
FROM maisons m
LEFT JOIN chambres c ON m.id = c.maison_id
LEFT JOIN locataires l ON c.id = l.chambre_id
GROUP BY m.id;
```

2. **Obtenir les paiements en retard**:
```sql
SELECT 
  l.nom, l.prenom, m.nom AS maison, c.numero AS chambre,
  p.montant, p.date_echeance,
  julianday('now') - julianday(p.date_echeance) AS jours_retard
FROM paiements p
JOIN locataires l ON p.locataire_id = l.id
JOIN chambres c ON l.chambre_id = c.id
JOIN maisons m ON c.maison_id = m.id
WHERE p.statut IN ('impayé', 'en retard')
AND p.date_echeance < date('now')
ORDER BY jours_retard DESC;
```

3. **Mettre à jour le statut des paiements**:
```sql
-- Mettre à jour les paiements en retard
UPDATE paiements
SET statut = 'en retard'
WHERE date_echeance < date('now')
AND statut = 'en cours';

-- Marquer un paiement comme payé
UPDATE paiements
SET statut = 'payé',
    date_paiement = date('now')
WHERE id = ?;
```

## Conseils de Développement

1. **Initialisation de la Base de Données**
   - Créez un script d'initialisation qui s'exécute au premier lancement
   - Incluez la création de toutes les tables et des données de test

2. **Mise à Jour de la Structure**
   - Implémentez un système de version pour la base de données
   - Gérez les migrations lors des mises à jour de l'application

3. **Performance**
   - Utilisez des index sur les colonnes fréquemment consultées
   - Optimisez les requêtes pour éviter les jointures complexes quand possible

4. **Sécurité**
   - Intégrez un système de sauvegarde automatique
   - Implémentez l'exportation/importation des données

## Prochaines Étapes

1. Développement du prototype initial avec les fonctionnalités de base
2. Tests utilisateurs pour valider l'ergonomie et l'expérience utilisateur
3. Ajout progressif des fonctionnalités avancées
4. Publication sur le Google Play Store et l'App Store pour distribution

---

Ce projet offre une solution complète et autonome pour la gestion locative, avec un accent particulier sur la simplicité d'utilisation et la fiabilité, même en l'absence de connexion Internet.

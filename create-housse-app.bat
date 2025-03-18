@echo off
echo Correction de la structure du projet gestion_locative...

cd gestion_locative

:: Création manuelle du fichier pubspec.yaml correct
echo name: gestion_locative > pubspec.yaml
echo description: Application de gestion locative. >> pubspec.yaml
echo publish_to: 'none' >> pubspec.yaml
echo version: 1.0.0+1 >> pubspec.yaml
echo. >> pubspec.yaml
echo environment: >> pubspec.yaml
echo   sdk: '>=3.2.3 <4.0.0' >> pubspec.yaml
echo. >> pubspec.yaml
echo dependencies: >> pubspec.yaml
echo   flutter: >> pubspec.yaml
echo     sdk: flutter >> pubspec.yaml
echo   sqflite: ^2.3.0 >> pubspec.yaml
echo   path: ^1.8.3 >> pubspec.yaml
echo   provider: ^6.0.5 >> pubspec.yaml
echo   intl: ^0.18.1 >> pubspec.yaml
echo   pdf: ^3.10.4 >> pubspec.yaml
echo   fl_chart: ^0.63.0 >> pubspec.yaml
echo   shared_preferences: ^2.2.1 >> pubspec.yaml
echo   local_auth: ^2.1.7 >> pubspec.yaml
echo   cupertino_icons: ^1.0.6 >> pubspec.yaml
echo. >> pubspec.yaml
echo dev_dependencies: >> pubspec.yaml
echo   flutter_test: >> pubspec.yaml
echo     sdk: flutter >> pubspec.yaml
echo   flutter_lints: ^3.0.0 >> pubspec.yaml
echo. >> pubspec.yaml
echo flutter: >> pubspec.yaml
echo   uses-material-design: true >> pubspec.yaml

:: Créer la structure de dossiers
echo Création de la structure de dossiers...

:: Assets
mkdir assets
mkdir assets\fonts
mkdir assets\images
mkdir assets\translations

:: Config
mkdir lib\config
type nul > lib\config\constants.dart
type nul > lib\config\routes.dart
type nul > lib\config\themes.dart
type nul > lib\config\app_config.dart

:: Data
mkdir lib\data
mkdir lib\data\database
mkdir lib\data\database\migrations
mkdir lib\data\database\tables
type nul > lib\data\database\database_helper.dart
type nul > lib\data\database\tables\maisons_table.dart
type nul > lib\data\database\tables\chambres_table.dart
type nul > lib\data\database\tables\locataires_table.dart
type nul > lib\data\database\tables\paiements_table.dart

:: Models
mkdir lib\data\models
type nul > lib\data\models\maison.dart
type nul > lib\data\models\chambre.dart
type nul > lib\data\models\locataire.dart
type nul > lib\data\models\paiement.dart
type nul > lib\data\models\configuration.dart

:: Repositories
mkdir lib\data\repositories
type nul > lib\data\repositories\base_repository.dart
type nul > lib\data\repositories\maison_repository.dart
type nul > lib\data\repositories\chambre_repository.dart
type nul > lib\data\repositories\locataire_repository.dart
type nul > lib\data\repositories\paiement_repository.dart

:: Services
mkdir lib\data\services
type nul > lib\data\services\auth_service.dart
type nul > lib\data\services\notification_service.dart
type nul > lib\data\services\pdf_service.dart
type nul > lib\data\services\backup_service.dart
type nul > lib\data\services\analytics_service.dart

:: Logic
mkdir lib\logic
mkdir lib\logic\blocs
mkdir lib\logic\blocs\maison
mkdir lib\logic\blocs\chambre
mkdir lib\logic\blocs\locataire
mkdir lib\logic\blocs\paiement
mkdir lib\logic\providers
type nul > lib\logic\providers\maison_provider.dart
type nul > lib\logic\providers\chambre_provider.dart
type nul > lib\logic\providers\locataire_provider.dart
type nul > lib\logic\providers\paiement_provider.dart

:: Presentation
mkdir lib\presentation
mkdir lib\presentation\screens
mkdir lib\presentation\widgets
mkdir lib\presentation\navigation

:: Presentation - Screens
mkdir lib\presentation\screens\dashboard
mkdir lib\presentation\screens\maisons
mkdir lib\presentation\screens\chambres
mkdir lib\presentation\screens\locataires
mkdir lib\presentation\screens\paiements
mkdir lib\presentation\screens\analytics
mkdir lib\presentation\screens\settings
type nul > lib\presentation\screens\maisons\maisons_list_screen.dart
type nul > lib\presentation\screens\maisons\maison_detail_screen.dart
type nul > lib\presentation\screens\maisons\maison_form_screen.dart
type nul > lib\presentation\screens\chambres\chambres_list_screen.dart
type nul > lib\presentation\screens\chambres\chambre_detail_screen.dart
type nul > lib\presentation\screens\chambres\chambre_form_screen.dart
type nul > lib\presentation\screens\locataires\locataires_list_screen.dart
type nul > lib\presentation\screens\locataires\locataire_detail_screen.dart
type nul > lib\presentation\screens\locataires\locataire_form_screen.dart
type nul > lib\presentation\screens\paiements\paiements_list_screen.dart
type nul > lib\presentation\screens\paiements\paiement_detail_screen.dart
type nul > lib\presentation\screens\paiements\paiement_form_screen.dart
type nul > lib\presentation\screens\analytics\revenue_chart_screen.dart
type nul > lib\presentation\screens\analytics\occupancy_chart_screen.dart
type nul > lib\presentation\screens\settings\settings_screen.dart
type nul > lib\presentation\screens\settings\backup_screen.dart
type nul > lib\presentation\screens\settings\about_screen.dart

:: Presentation - Widgets
mkdir lib\presentation\widgets\common
mkdir lib\presentation\widgets\maison
mkdir lib\presentation\widgets\chambre
mkdir lib\presentation\widgets\locataire
mkdir lib\presentation\widgets\paiement
mkdir lib\presentation\widgets\charts
type nul > lib\presentation\widgets\common\custom_app_bar.dart
type nul > lib\presentation\widgets\common\custom_drawer.dart
type nul > lib\presentation\widgets\common\loading_indicator.dart
type nul > lib\presentation\widgets\common\error_display.dart

:: Presentation - Navigation
type nul > lib\presentation\navigation\app_router.dart
type nul > lib\presentation\navigation\navigation_service.dart

:: Utils
mkdir lib\utils
type nul > lib\utils\date_utils.dart
type nul > lib\utils\currency_utils.dart
type nul > lib\utils\form_validators.dart
type nul > lib\utils\extensions.dart
type nul > lib\utils\logger.dart

:: Tests
mkdir test\data
mkdir test\data\repositories
mkdir test\data\models
mkdir test\logic
mkdir test\logic\blocs
mkdir test\presentation
mkdir test\presentation\screens
mkdir integration_test

:: Installation des dépendances
echo Installation des packages...
flutter pub get

echo Structure du projet complétée avec succès!
echo Vous pouvez maintenant commencer à développer votre application de gestion locative.
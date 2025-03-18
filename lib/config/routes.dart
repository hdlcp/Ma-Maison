import 'package:flutter/material.dart';
import 'package:gestion_locative/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:gestion_locative/presentation/screens/maisons/maisons_list_screen.dart';
import 'package:gestion_locative/presentation/screens/maisons/maison_detail_screen.dart';
import 'package:gestion_locative/presentation/screens/maisons/maison_form_screen.dart';
import 'package:gestion_locative/presentation/screens/chambres/chambres_list_screen.dart';
import 'package:gestion_locative/presentation/screens/chambres/chambre_form_screen.dart';
import 'package:gestion_locative/presentation/screens/paiements/paiements_list_screen.dart';
import 'package:gestion_locative/presentation/screens/paiements/paiement_detail_screen.dart';
import 'package:gestion_locative/presentation/screens/paiements/paiement_form_screen.dart';
import 'package:gestion_locative/presentation/screens/paiements/paiements_generation_screen.dart';
import 'package:gestion_locative/presentation/screens/locataires/locataires_list_screen.dart';
import 'package:gestion_locative/presentation/screens/locataires/locataire_form_screen.dart';
import 'package:gestion_locative/presentation/screens/analytics/analytics_screen.dart';
import 'package:gestion_locative/presentation/screens/problemes/probleme_form_screen.dart';
import 'package:gestion_locative/presentation/screens/settings/settings_screen.dart';
import 'package:gestion_locative/data/models/maison.dart';
import 'package:gestion_locative/data/models/paiement.dart';
import 'package:gestion_locative/data/models/locataire.dart';
import 'package:gestion_locative/data/models/probleme.dart';
import 'package:gestion_locative/data/models/chambre.dart';

class AppRoutes {
  static const String dashboard = '/';
  static const String maisons = '/maisons';
  static const String maisonForm = '/maisons/form';
  static const String maisonDetail = '/maisons/detail';
  static const String chambres = '/chambres';
  static const String chambreForm = '/chambres/form';
  static const String locataires = '/locataires';
  static const String locataireForm = '/locataires/form';
  static const String paiements = '/paiements';
  static const String paiementForm = '/paiements/form';
  static const String paiementDetail = '/paiements/detail';
  static const String paiementsGeneration = '/paiements/generation';
  static const String problemeForm = '/problemes/form';
  static const String analytics = '/analytics';
  static const String settings = '/settings';

  static Map<String, Widget Function(BuildContext)> get routes => {
    dashboard: (context) => const DashboardScreen(),
    maisons: (context) => const MaisonsListScreen(),
    maisonForm: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Maison?;
      return MaisonFormScreen(maison: args);
    },
    maisonDetail: (context) {
      final arguments = ModalRoute.of(context)?.settings.arguments;
      if (arguments != null && arguments is int) {
        return MaisonDetailScreen(maisonId: arguments);
      }
      return const MaisonsListScreen();
    },
    chambres: (context) => const ChambresListScreen(),
    locataires: (context) => const LocatairesListScreen(),
    locataireForm: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Locataire?;
      return LocataireFormScreen(locataire: args);
    },
    paiements: (context) => const PaiementsListScreen(),
    paiementDetail: (context) {
      final paiementId = ModalRoute.of(context)?.settings.arguments as int;
      return PaiementDetailScreen(paiementId: paiementId);
    },
    paiementForm: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Paiement?;
      return PaiementFormScreen(paiement: args);
    },
    paiementsGeneration: (context) => const PaiementsGenerationScreen(),
    analytics: (context) => const AnalyticsScreen(),
    chambreForm: (context) {
      // Récupérer les arguments
      final args = ModalRoute.of(context)?.settings.arguments;

      if (args is Chambre) {
        // Cas de modification d'une chambre existante
        return ChambreFormScreen(chambre: args);
      } else if (args is Map<String, dynamic> && args.containsKey('maisonId')) {
        // Cas d'ajout d'une chambre pour une maison spécifique
        return ChambreFormScreen(maisonId: args['maisonId'] as int);
      }

      // Cas d'ajout d'une chambre sans maison spécifiée
      return const ChambreFormScreen();
    },
    problemeForm: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Probleme?;
      return ProblemeFormScreen(probleme: args);
    },
    settings: (context) => const SettingsScreen(),
    // Les autres routes seront ajoutées au fur et à mesure de l'implémentation des écrans
  };
}

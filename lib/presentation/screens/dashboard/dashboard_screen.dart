import 'package:flutter/material.dart';
import 'package:gestion_locative/config/constants.dart';
import 'package:gestion_locative/config/routes.dart';
import 'package:gestion_locative/data/models/maison.dart';
import 'package:gestion_locative/data/models/paiement.dart';
import 'package:gestion_locative/data/models/locataire.dart';
import 'package:gestion_locative/data/repositories/maison_repository.dart';
import 'package:gestion_locative/data/repositories/paiement_repository.dart';
import 'package:gestion_locative/presentation/widgets/common/custom_drawer.dart';
import 'package:gestion_locative/presentation/widgets/common/loading_indicator.dart';
import 'package:gestion_locative/presentation/widgets/dashboard/info_card.dart';
import 'package:gestion_locative/presentation/widgets/dashboard/maison_card.dart';
import 'package:gestion_locative/presentation/widgets/dashboard/paiement_item.dart';
import 'package:gestion_locative/presentation/widgets/dashboard/section_header.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final MaisonRepository _maisonRepository = MaisonRepository();
  final PaiementRepository _paiementRepository = PaiementRepository();

  bool _isLoading = true;
  List<Maison> _maisons = [];
  Map<int, int> _chambresCountByMaison = {};
  Map<int, int> _chambresOccupeesCountByMaison = {};
  List<Map<String, dynamic>> _paiementsEnRetard = [];

  int _totalChambresOccupees = 0;
  double _totalMontantPaiements = 0;
  int _totalPaiementsEnRetard = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Chargement des maisons
      final maisons = await _maisonRepository.getAllMaisons();
      _maisons = maisons;

      // Réinitialiser les compteurs
      _totalChambresOccupees = 0;
      _totalMontantPaiements = 0.0;
      _chambresCountByMaison = {};
      _chambresOccupeesCountByMaison = {};

      // Calculer les statistiques pour chaque maison
      for (final maison in maisons) {
        final chambres = await _maisonRepository.getChambresForMaison(
          maison.id!,
        );
        final occupees = chambres.where((c) => c.estOccupee).length;

        _chambresCountByMaison[maison.id!] = chambres.length;
        _chambresOccupeesCountByMaison[maison.id!] = occupees;

        _totalChambresOccupees += occupees;
      }

      // Charger les paiements en retard
      final paiements = await _paiementRepository.getPaiementsEnRetard();
      _totalPaiementsEnRetard = paiements.length;

      // Récupérer les détails des locataires pour ces paiements
      _paiementsEnRetard = [];
      for (final paiement in paiements) {
        // Additionner le montant de tous les paiements en retard
        _totalMontantPaiements += paiement.montant;

        if (_paiementsEnRetard.length >= 5)
          break; // Limiter à 5 pour le dashboard

        final locataire = await _paiementRepository.getLocataireForPaiement(
          paiement.id!,
        );
        if (locataire != null) {
          _paiementsEnRetard.add({
            'paiement': paiement,
            'locataire': locataire,
          });
        }
      }
    } catch (e) {
      // Gérer les erreurs
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement des données: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      drawer: const CustomDrawer(),
      body:
          _isLoading
              ? const LoadingIndicator(message: 'Chargement des données...')
              : RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatisticsSection(),
                      const SizedBox(height: 24),
                      _buildMaisonsSection(),
                      const SizedBox(height: 24),
                      _buildPaiementsSection(),
                      const SizedBox(height: 24),
                      _buildActionsRapidesSection(),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildStatisticsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Aperçu général', icon: Icons.analytics),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            InfoCard(
              title: 'Maisons',
              value: _maisons.length.toString(),
              icon: Icons.home,
              color: AppColors.primary,
              onTap: () => Navigator.pushNamed(context, AppRoutes.maisons),
            ),
            InfoCard(
              title: 'Occupation',
              value: '$_totalChambresOccupees locataires',
              icon: Icons.bed,
              color: AppColors.info,
              onTap: () => Navigator.pushNamed(context, AppRoutes.locataires),
            ),
            InfoCard(
              title: 'Retard',
              value: _totalPaiementsEnRetard.toString(),
              icon: Icons.warning,
              color: AppColors.danger,
              onTap: () => Navigator.pushNamed(context, AppRoutes.paiements),
            ),
            InfoCard(
              title: 'Total dû',
              value: '${_totalMontantPaiements.toInt()} FCFA',
              icon: Icons.monetization_on,
              color: AppColors.warning,
              onTap: () => Navigator.pushNamed(context, AppRoutes.paiements),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMaisonsSection() {
    if (_maisons.isEmpty) {
      return _buildEmptySection(
        'Aucune maison ajoutée',
        'Ajoutez votre première maison pour commencer à gérer vos biens.',
        AppRoutes.maisonForm,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Mes maisons',
          icon: Icons.home,
          onViewAll: () => Navigator.pushNamed(context, AppRoutes.maisons),
        ),
        ...List.generate(_maisons.length > 3 ? 3 : _maisons.length, (index) {
          final maison = _maisons[index];
          return MaisonCard(
            maison: maison,
            chambresCount: _chambresCountByMaison[maison.id!] ?? 0,
            chambresOccupees: _chambresOccupeesCountByMaison[maison.id!] ?? 0,
            onTap:
                () => Navigator.pushNamed(
                  context,
                  AppRoutes.maisonDetail,
                  arguments: maison.id,
                ),
          );
        }),
        if (_maisons.length > 3)
          Align(
            alignment: Alignment.center,
            child: TextButton.icon(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.maisons),
              icon: const Icon(Icons.list),
              label: Text(
                'Voir les ${_maisons.length - 3} autres maisons',
                style: TextStyle(color: Theme.of(context).primaryColor),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPaiementsSection() {
    if (_paiementsEnRetard.isEmpty) {
      return _buildEmptySection(
        'Aucun paiement en retard',
        'Tous les paiements sont à jour. Excellent travail!',
        null,
        icon: Icons.check_circle,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Paiements en retard',
          icon: Icons.warning,
          onViewAll: () => Navigator.pushNamed(context, AppRoutes.paiements),
        ),
        const SizedBox(height: 8),
        ...List.generate(_paiementsEnRetard.length, (index) {
          final item = _paiementsEnRetard[index];
          final Paiement paiement = item['paiement'];
          final Locataire locataire = item['locataire'];

          return PaiementItem(
            paiement: paiement,
            locataire: locataire,
            onTap:
                () => Navigator.pushNamed(
                  context,
                  AppRoutes.paiementDetail,
                  arguments: paiement.id,
                ),
          );
        }),
        if (_totalPaiementsEnRetard > _paiementsEnRetard.length)
          Align(
            alignment: Alignment.center,
            child: TextButton.icon(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.paiements,
                  arguments: {'filter': 'en_retard'},
                );
              },
              icon: const Icon(Icons.warning),
              label: Text(
                'Voir les ${_totalPaiementsEnRetard - _paiementsEnRetard.length} autres paiements en retard',
                style: TextStyle(color: Theme.of(context).primaryColor),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptySection(
    String title,
    String subtitle,
    String? routeToAdd, {
    IconData icon = Icons.info,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[700]),
          ),
          if (routeToAdd != null) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, routeToAdd),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionsRapidesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Actions rapides', icon: Icons.flash_on),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Ajouter une maison',
                Icons.home_outlined,
                AppColors.primary,
                () => Navigator.pushNamed(context, AppRoutes.maisonForm),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildActionButton(
                'Ajouter un locataire',
                Icons.person_add_outlined,
                AppColors.info,
                () => Navigator.pushNamed(context, AppRoutes.locataireForm),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Enregistrer un paiement',
                Icons.payment_outlined,
                AppColors.success,
                () => Navigator.pushNamed(context, AppRoutes.paiementForm),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildActionButton(
                'Signaler un problème',
                Icons.report_problem_outlined,
                AppColors.warning,
                () => Navigator.pushNamed(context, AppRoutes.problemeForm),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color.withOpacity(0.8),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:gestion_locative/config/constants.dart';
import 'package:gestion_locative/config/routes.dart';
import 'package:gestion_locative/data/models/chambre.dart';
import 'package:gestion_locative/data/models/locataire.dart';
import 'package:gestion_locative/data/models/maison.dart';
import 'package:gestion_locative/data/repositories/locataire_repository.dart';
import 'package:gestion_locative/data/repositories/maison_repository.dart';
import 'package:gestion_locative/presentation/widgets/common/custom_drawer.dart';
import 'package:gestion_locative/presentation/widgets/common/loading_indicator.dart';
import 'package:intl/intl.dart';

class LocatairesListScreen extends StatefulWidget {
  const LocatairesListScreen({Key? key}) : super(key: key);

  @override
  State<LocatairesListScreen> createState() => _LocatairesListScreenState();
}

class _LocatairesListScreenState extends State<LocatairesListScreen> {
  final LocataireRepository _locataireRepository = LocataireRepository();
  final MaisonRepository _maisonRepository = MaisonRepository();

  bool _isLoading = true;
  List<Locataire> _locataires = [];
  Map<int, Chambre> _chambres = {};
  Map<int, Maison> _maisons = {};

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
      // Charger tous les locataires
      final locataires = await _locataireRepository.getAllLocataires();

      // Pour chaque locataire, récupérer sa chambre
      final Map<int, Chambre> chambres = {};
      final Map<int, Maison> maisons = {};

      for (final locataire in locataires) {
        // Récupérer la chambre du locataire si elle n'est pas déjà en cache
        if (!chambres.containsKey(locataire.chambreId)) {
          final chambre = await _maisonRepository.getChambreById(
            locataire.chambreId,
          );
          if (chambre != null) {
            chambres[locataire.chambreId] = chambre;

            // Récupérer la maison associée à la chambre
            if (!maisons.containsKey(chambre.maisonId)) {
              final maison = await _maisonRepository.getMaisonById(
                chambre.maisonId,
              );
              maisons[chambre.maisonId] = maison;
            }
          }
        }
      }

      setState(() {
        _locataires = locataires;
        _chambres = chambres;
        _maisons = maisons;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des locataires: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _deleteLocataire(Locataire locataire) async {
    try {
      await _locataireRepository.deleteLocataire(locataire.id!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Locataire ${locataire.nomComplet} supprimé'),
            backgroundColor: AppColors.success,
          ),
        );
      }

      _loadData(); // Recharger la liste
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Locataires'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      drawer: const CustomDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed:
            () => Navigator.pushNamed(
              context,
              AppRoutes.locataireForm,
            ).then((_) => _loadData()),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
      body:
          _isLoading
              ? const LoadingIndicator(message: 'Chargement des locataires...')
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_locataires.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Aucun locataire trouvé',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ajoutez des locataires pour commencer',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed:
                  () => Navigator.pushNamed(
                    context,
                    AppRoutes.locataireForm,
                  ).then((_) => _loadData()),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter un locataire'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    // Créer une map pour regrouper les locataires par maison
    final Map<int, List<Locataire>> locatairesByMaison = {};

    for (final locataire in _locataires) {
      final chambre = _chambres[locataire.chambreId];
      if (chambre != null) {
        final maisonId = chambre.maisonId;
        if (!locatairesByMaison.containsKey(maisonId)) {
          locatairesByMaison[maisonId] = [];
        }
        locatairesByMaison[maisonId]!.add(locataire);
      }
    }

    // Créer la liste des locataires regroupés par maison
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: locatairesByMaison.length,
        itemBuilder: (context, index) {
          final maisonId = locatairesByMaison.keys.elementAt(index);
          final maison = _maisons[maisonId];
          final locatairesForMaison = locatairesByMaison[maisonId]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête de la maison
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.home, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      maison?.nom ?? 'Maison inconnue',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Liste des locataires pour cette maison
              ...locatairesForMaison.map((locataire) {
                final chambre = _chambres[locataire.chambreId];
                return _buildLocataireCard(locataire, chambre);
              }).toList(),

              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLocataireCard(Locataire locataire, Chambre? chambre) {
    final formatter = NumberFormat.currency(symbol: '', decimalDigits: 0);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: () => _showLocataireDetailsDialog(locataire, chambre),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: const Icon(Icons.person, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          locataire.nomComplet,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (chambre != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Chambre ${chambre.numero}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${formatter.format(locataire.montantLoyer)} FCFA',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd/MM/yyyy').format(locataire.dateEntree),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _showEditLocataireDialog(locataire),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Modifier'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _showDeleteLocataireDialog(locataire),
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text('Supprimer'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLocataireDetailsDialog(Locataire locataire, Chambre? chambre) {
    final formatter = NumberFormat.currency(symbol: '', decimalDigits: 0);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(locataire.nomComplet),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(
                    'Date d\'entrée',
                    DateFormat('dd/MM/yyyy').format(locataire.dateEntree),
                  ),
                  _buildDetailRow(
                    'Loyer mensuel',
                    '${formatter.format(locataire.montantLoyer)} FCFA',
                  ),
                  _buildDetailRow(
                    'Période de paiement',
                    locataire.periodePaiement,
                  ),
                  if (locataire.telephone != null &&
                      locataire.telephone!.isNotEmpty)
                    _buildDetailRow('Téléphone', locataire.telephone!),
                  if (locataire.email != null && locataire.email!.isNotEmpty)
                    _buildDetailRow('Email', locataire.email!),
                  if (chambre != null) ...[
                    const Divider(),
                    _buildDetailRow('Chambre', 'N° ${chambre.numero}'),
                    _buildDetailRow('Type', chambre.type),
                    if (chambre.taille != null && chambre.taille!.isNotEmpty)
                      _buildDetailRow('Taille', chambre.taille!),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showEditLocataireDialog(locataire);
                },
                child: const Text('Modifier'),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
            ],
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showEditLocataireDialog(Locataire locataire) {
    // Naviguer vers la page du formulaire de locataire avec le locataire à modifier
    Navigator.pushNamed(
      context,
      AppRoutes.locataireForm,
      arguments: locataire,
    ).then((_) => _loadData());
  }

  void _showDeleteLocataireDialog(Locataire locataire) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Supprimer le locataire'),
            content: Text(
              'Êtes-vous sûr de vouloir supprimer le locataire ${locataire.nomComplet} ? Cette action ne peut pas être annulée.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _deleteLocataire(locataire);
                },
                child: const Text('Supprimer'),
                style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              ),
            ],
          ),
    );
  }
}

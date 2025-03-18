import 'package:flutter/material.dart';
import 'package:gestion_locative/config/constants.dart';
import 'package:gestion_locative/config/routes.dart';
import 'package:gestion_locative/data/models/maison.dart';
import 'package:gestion_locative/data/repositories/maison_repository.dart';
import 'package:gestion_locative/presentation/widgets/common/custom_drawer.dart';
import 'package:gestion_locative/presentation/widgets/common/loading_indicator.dart';
import 'package:gestion_locative/presentation/widgets/dashboard/maison_card.dart';

class MaisonsListScreen extends StatefulWidget {
  const MaisonsListScreen({Key? key}) : super(key: key);

  @override
  State<MaisonsListScreen> createState() => _MaisonsListScreenState();
}

class _MaisonsListScreenState extends State<MaisonsListScreen> {
  final MaisonRepository _maisonRepository = MaisonRepository();

  bool _isLoading = true;
  List<Maison> _maisons = [];
  Map<int, int> _chambresCountByMaison = {};
  Map<int, int> _chambresOccupeesCountByMaison = {};

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
      // Charger toutes les maisons
      final maisons = await _maisonRepository.getAllMaisons();

      // Réinitialiser les maps
      final Map<int, int> chambresCountByMaison = {};
      final Map<int, int> chambresOccupeesCountByMaison = {};

      // Calculer les statistiques pour chaque maison
      for (final maison in maisons) {
        if (maison.id == null) continue;

        final chambres = await _maisonRepository.getChambresForMaison(
          maison.id!,
        );
        final occupees = chambres.where((c) => c.estOccupee).length;

        chambresCountByMaison[maison.id!] = chambres.length;
        chambresOccupeesCountByMaison[maison.id!] = occupees;
      }

      setState(() {
        _maisons = maisons;
        _chambresCountByMaison = chambresCountByMaison;
        _chambresOccupeesCountByMaison = chambresOccupeesCountByMaison;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      // Gérer les erreurs
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement des maisons: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Maisons'),
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
              AppRoutes.maisonForm,
            ).then((_) => _loadData()),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
      body:
          _isLoading
              ? const LoadingIndicator(message: 'Chargement des maisons...')
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_maisons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Aucune maison trouvée',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ajoutez votre première maison en cliquant sur le bouton +',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _maisons.length,
        itemBuilder: (context, index) {
          final maison = _maisons[index];
          return Dismissible(
            key: Key('maison-${maison.id}'),
            background: Container(
              color: AppColors.danger,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            direction: DismissDirection.endToStart,
            confirmDismiss: (direction) async {
              return await showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Confirmation'),
                      content: Text(
                        'Êtes-vous sûr de vouloir supprimer la maison "${maison.nom}" ?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Annuler'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Supprimer'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.danger,
                          ),
                        ),
                      ],
                    ),
              );
            },
            onDismissed: (direction) async {
              try {
                await _maisonRepository.deleteMaison(maison.id!);
                _loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Maison "${maison.nom}" supprimée'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erreur lors de la suppression: $e'),
                    backgroundColor: AppColors.danger,
                  ),
                );
              }
            },
            child: MaisonCard(
              maison: maison,
              chambresCount: _chambresCountByMaison[maison.id!] ?? 0,
              chambresOccupees: _chambresOccupeesCountByMaison[maison.id!] ?? 0,
              onTap: () {
                if (maison.id != null) {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.chambres,
                    arguments: {'maisonId': maison.id, 'maisonNom': maison.nom},
                  ).then((_) => _loadData());
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Impossible d\'afficher les chambres de cette maison',
                      ),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }
}

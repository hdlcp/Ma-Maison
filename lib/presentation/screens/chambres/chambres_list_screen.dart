import 'package:flutter/material.dart';
import 'package:gestion_locative/config/constants.dart';
import 'package:gestion_locative/config/routes.dart';
import 'package:gestion_locative/data/models/chambre.dart';
import 'package:gestion_locative/data/models/maison.dart';
import 'package:gestion_locative/data/repositories/maison_repository.dart';
import 'package:gestion_locative/presentation/widgets/common/custom_drawer.dart';
import 'package:gestion_locative/presentation/widgets/common/loading_indicator.dart';

class ChambresListScreen extends StatefulWidget {
  const ChambresListScreen({Key? key}) : super(key: key);

  @override
  State<ChambresListScreen> createState() => _ChambresListScreenState();
}

class _ChambresListScreenState extends State<ChambresListScreen> {
  final MaisonRepository _maisonRepository = MaisonRepository();

  bool _isLoading = true;
  List<Map<String, dynamic>> _chambresWithMaison = [];

  // Paramètres pour filtrer les chambres d'une maison spécifique
  int? _maisonId;
  String? _maisonNom;

  @override
  void initState() {
    super.initState();

    // Récupérer les arguments de la route si disponibles
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final arguments = ModalRoute.of(context)?.settings.arguments;
      if (arguments != null && arguments is Map<String, dynamic>) {
        setState(() {
          _maisonId = arguments['maisonId'];
          _maisonNom = arguments['maisonNom'];
        });
      }
      _loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final chambresWithMaison = <Map<String, dynamic>>[];

      if (_maisonId != null) {
        // Cas où on veut les chambres d'une maison spécifique
        final maison = await _maisonRepository.getMaisonById(_maisonId!);
        final chambres = await _maisonRepository.getChambresForMaison(
          _maisonId!,
        );

        // Stocker les chambres avec leur maison associée
        for (final chambre in chambres) {
          chambresWithMaison.add({'chambre': chambre, 'maison': maison});
        }
      } else {
        // Cas où on veut toutes les chambres
        final maisons = await _maisonRepository.getAllMaisons();

        // Pour chaque maison, récupérer ses chambres
        for (final maison in maisons) {
          if (maison.id == null) continue;

          final chambres = await _maisonRepository.getChambresForMaison(
            maison.id!,
          );

          // Stocker les chambres avec leur maison associée
          for (final chambre in chambres) {
            chambresWithMaison.add({'chambre': chambre, 'maison': maison});
          }
        }
      }

      // Trier par maison et numéro de chambre
      chambresWithMaison.sort((a, b) {
        final maisonA = a['maison'] as Maison;
        final maisonB = b['maison'] as Maison;
        final chambreA = a['chambre'] as Chambre;
        final chambreB = b['chambre'] as Chambre;

        final maisonComp = maisonA.nom.compareTo(maisonB.nom);
        if (maisonComp != 0) return maisonComp;

        return chambreA.numero.compareTo(chambreB.numero);
      });

      setState(() {
        _chambresWithMaison = chambresWithMaison;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des chambres: $e'),
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
        title: Text(
          _maisonNom != null
              ? 'Chambres de ${_maisonNom}'
              : 'Toutes les Chambres',
        ),
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
              ? const LoadingIndicator(message: 'Chargement des chambres...')
              : _buildContent(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(
            context,
            AppRoutes.chambreForm,
            arguments: _maisonId != null ? {'maisonId': _maisonId} : null,
          ).then((_) => _loadData());
        },
        child: const Icon(Icons.add),
        tooltip: 'Ajouter une chambre',
      ),
    );
  }

  Widget _buildContent() {
    if (_chambresWithMaison.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bedroom_parent_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune chambre trouvée',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ajoutez des chambres à vos maisons pour commencer',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.maisons),
              icon: const Icon(Icons.home),
              label: const Text('Aller aux Maisons'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _chambresWithMaison.length,
        itemBuilder: (context, index) {
          final item = _chambresWithMaison[index];
          final chambre = item['chambre'] as Chambre;
          final maison = item['maison'] as Maison;

          // Vérifier s'il faut ajouter un en-tête de maison
          final bool showHeader =
              index == 0 ||
              (item['maison'] as Maison).id !=
                  (_chambresWithMaison[index - 1]['maison'] as Maison).id;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showHeader) ...[
                if (index > 0) const SizedBox(height: 16),
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
                      const Icon(
                        Icons.home,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        maison.nom,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
              _buildChambreCard(chambre, maison),
            ],
          );
        },
      ),
    );
  }

  Widget _buildChambreCard(Chambre chambre, Maison maison) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: () => _showChambreDetailsDialog(chambre, maison),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color:
                      chambre.estOccupee
                          ? AppColors.success.withOpacity(0.1)
                          : AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  chambre.estOccupee ? Icons.bed : Icons.bed_outlined,
                  color:
                      chambre.estOccupee
                          ? AppColors.success
                          : AppColors.warning,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chambre ${chambre.numero}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Type: ${chambre.type.substring(0, 1).toUpperCase() + chambre.type.substring(1)}${chambre.taille != null ? ' • ${chambre.taille}' : ''}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      chambre.estOccupee
                          ? AppColors.success.withOpacity(0.1)
                          : AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  chambre.estOccupee ? 'Occupée' : 'Libre',
                  style: TextStyle(
                    color:
                        chambre.estOccupee
                            ? AppColors.success
                            : AppColors.warning,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChambreDetailsDialog(Chambre chambre, Maison maison) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Chambre ${chambre.numero}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Maison', maison.nom),
                _buildDetailRow('Type', chambre.type),
                if (chambre.taille != null)
                  _buildDetailRow('Taille', chambre.taille!),
                _buildDetailRow(
                  'Statut',
                  chambre.estOccupee ? 'Occupée' : 'Libre',
                ),
                _buildDetailRow(
                  'Prix estimé',
                  '${maison.prixParDefaut.toInt()} FCFA',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(
                    context,
                    AppRoutes.maisonDetail,
                    arguments: maison.id,
                  );
                },
                child: const Text('Voir la Maison'),
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
            width: 80,
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
}

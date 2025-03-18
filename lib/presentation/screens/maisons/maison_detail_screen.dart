import 'package:flutter/material.dart';
import 'package:gestion_locative/config/constants.dart';
import 'package:gestion_locative/config/routes.dart';
import 'package:gestion_locative/data/models/chambre.dart';
import 'package:gestion_locative/data/models/maison.dart';
import 'package:gestion_locative/data/repositories/maison_repository.dart';
import 'package:gestion_locative/presentation/widgets/common/loading_indicator.dart';
import 'package:intl/intl.dart';

class MaisonDetailScreen extends StatefulWidget {
  final int maisonId;

  const MaisonDetailScreen({Key? key, required this.maisonId})
    : super(key: key);

  @override
  State<MaisonDetailScreen> createState() => _MaisonDetailScreenState();
}

class _MaisonDetailScreenState extends State<MaisonDetailScreen> {
  final MaisonRepository _maisonRepository = MaisonRepository();
  final formatter = NumberFormat.currency(symbol: '', decimalDigits: 0);

  bool _isLoading = true;
  Maison? _maison;
  List<Chambre> _chambres = [];
  int _chambresOccupees = 0;
  double _revenuTotal = 0.0;

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
      // Charger la maison
      final maison = await _maisonRepository.getMaisonById(widget.maisonId);

      // Charger les chambres associées
      final chambres = await _maisonRepository.getChambresForMaison(
        widget.maisonId,
      );
      final chambresOccupees = chambres.where((c) => c.estOccupee).length;

      // Calculer le revenu total (nombre de chambres occupées * prix par défaut)
      final revenuTotal = chambresOccupees * maison.prixParDefaut;

      setState(() {
        _maison = maison;
        _chambres = chambres;
        _chambresOccupees = chambresOccupees;
        _revenuTotal = revenuTotal;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      // Gérer les erreurs
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement des données: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_maison?.nom ?? 'Détails de la maison'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.pushNamed(
                context,
                AppRoutes.maisonForm,
                arguments: _maison,
              ).then((_) => _loadData());
            },
            tooltip: 'Modifier',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddChambreDialog(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
        tooltip: 'Ajouter une chambre',
      ),
      body:
          _isLoading
              ? const LoadingIndicator(message: 'Chargement des détails...')
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_maison == null) {
      return const Center(
        child: Text('Impossible de charger les détails de la maison'),
      );
    }

    final occupancyRate =
        _chambres.isNotEmpty
            ? (_chambresOccupees / _chambres.length * 100).toInt()
            : 0;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMaisonHeader(),
            const SizedBox(height: 24),
            _buildStatsSection(occupancyRate),
            const SizedBox(height: 24),
            _buildChambresSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildMaisonHeader() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.home,
                    color: AppColors.primary,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _maison!.nom,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _maison!.adresse,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: Colors.grey[300]),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoItem(
                  'Date de création',
                  DateFormat('dd/MM/yyyy').format(_maison!.dateCreation),
                ),
                _buildInfoItem(
                  'Prix par défaut',
                  '${formatter.format(_maison!.prixParDefaut)} FCFA',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildStatsSection(int occupancyRate) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistiques',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem(
                  'Chambres',
                  '${_chambresOccupees}/${_chambres.length}',
                  Icons.meeting_room,
                  AppColors.primary,
                ),
                _buildStatItem(
                  'Occupation',
                  '$occupancyRate%',
                  Icons.person,
                  AppColors.info,
                ),
                _buildStatItem(
                  'Revenu estimé',
                  '${formatter.format(_revenuTotal)}',
                  Icons.monetization_on,
                  AppColors.success,
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value:
                  _chambres.isNotEmpty
                      ? _chambresOccupees / _chambres.length
                      : 0,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                _getOccupancyColor(occupancyRate),
              ),
              minHeight: 6,
              borderRadius: BorderRadius.circular(6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildChambresSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Chambres',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (_chambres.isNotEmpty)
              Text(
                '${_chambres.length} au total',
                style: TextStyle(color: Colors.grey[600]),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_chambres.isEmpty)
          _buildEmptyChambresList()
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _chambres.length,
            itemBuilder: (context, index) {
              final chambre = _chambres[index];
              return _buildChambreItem(chambre);
            },
          ),
      ],
    );
  }

  Widget _buildChambreItem(Chambre chambre) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
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
            color: chambre.estOccupee ? AppColors.success : AppColors.warning,
          ),
        ),
        title: Text(
          'Chambre ${chambre.numero}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Type: ${chambre.type}${chambre.taille != null ? ' • Taille: ${chambre.taille}' : ''}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
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
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => _showChambreOptions(chambre),
            ),
          ],
        ),
        onTap: () {
          // Navigation vers la page de détail de la chambre à implémenter
          // Pour le moment, affichons juste un dialogue
          _showChambreDetailDialog(chambre);
        },
      ),
    );
  }

  Widget _buildEmptyChambresList() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.meeting_room_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune chambre ajoutée',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ajoutez des chambres pour cette maison',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showAddChambreDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter une chambre'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddChambreDialog() {
    final numeroController = TextEditingController();
    final tailleController = TextEditingController();
    String type = 'simple';

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Ajouter une chambre'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: numeroController,
                    decoration: const InputDecoration(
                      labelText: 'Numéro/Nom de la chambre*',
                      hintText: 'Ex: A1, 101, Studio Est...',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: tailleController,
                    decoration: const InputDecoration(
                      labelText: 'Taille (optionnel)',
                      hintText: 'Ex: 15 m²',
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: type,
                    decoration: const InputDecoration(
                      labelText: 'Type de chambre*',
                    ),
                    items:
                        ['simple', 'double', 'triple', 'suite']
                            .map(
                              (t) => DropdownMenuItem(
                                value: t,
                                child: Text(
                                  t.substring(0, 1).toUpperCase() +
                                      t.substring(1),
                                ),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        type = value;
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (numeroController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Le numéro de chambre est requis'),
                        backgroundColor: AppColors.danger,
                      ),
                    );
                    return;
                  }

                  final chambre = Chambre(
                    numero: numeroController.text.trim(),
                    taille:
                        tailleController.text.trim().isNotEmpty
                            ? tailleController.text.trim()
                            : null,
                    type: type,
                    maisonId: widget.maisonId,
                  );

                  // Ajouter la chambre au repository
                  try {
                    await _maisonRepository.insertChambre(chambre);
                    Navigator.of(context).pop();

                    // Recharger les données
                    _loadData();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Chambre ajoutée avec succès'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur lors de l\'ajout: $e'),
                        backgroundColor: AppColors.danger,
                      ),
                    );
                  }
                },
                child: const Text('Ajouter'),
              ),
            ],
          ),
    );
  }

  void _showChambreDetailDialog(Chambre chambre) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Chambre ${chambre.numero}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Type', chambre.type),
                if (chambre.taille != null)
                  _buildDetailRow('Taille', chambre.taille!),
                _buildDetailRow(
                  'Statut',
                  chambre.estOccupee ? 'Occupée' : 'Libre',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fermer'),
              ),
            ],
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  void _showChambreOptions(Chambre chambre) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Modifier'),
                  onTap: () {
                    Navigator.pop(context);
                    // Implémenter la modification de chambre
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.person_add_alt_1),
                  title: const Text('Ajouter un locataire'),
                  onTap: () {
                    Navigator.pop(context);
                    // Implémenter l'ajout de locataire
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.toggle_on,
                    color:
                        chambre.estOccupee
                            ? AppColors.success
                            : AppColors.warning,
                  ),
                  title: Text(
                    chambre.estOccupee
                        ? 'Marquer comme libre'
                        : 'Marquer comme occupée',
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    // Implémenter le changement de statut
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: AppColors.danger),
                  title: const Text('Supprimer'),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteChambreDialog(chambre);
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _showDeleteChambreDialog(Chambre chambre) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Supprimer la chambre'),
            content: Text(
              'Êtes-vous sûr de vouloir supprimer la chambre ${chambre.numero} ? Cette action ne peut pas être annulée.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () {
                  // Implémenter la suppression de chambre
                  Navigator.of(context).pop();
                  // Recharger les données
                  _loadData();
                },
                child: const Text('Supprimer'),
                style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              ),
            ],
          ),
    );
  }

  Color _getOccupancyColor(int rate) {
    if (rate < 50) return AppColors.warning;
    if (rate < 80) return AppColors.info;
    return AppColors.success;
  }
}

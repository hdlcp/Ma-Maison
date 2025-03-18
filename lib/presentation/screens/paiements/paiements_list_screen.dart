import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:gestion_locative/config/constants.dart';
import 'package:gestion_locative/config/routes.dart';
import 'package:gestion_locative/data/models/locataire.dart';
import 'package:gestion_locative/data/models/paiement.dart';
import 'package:gestion_locative/data/repositories/paiement_repository.dart';
import 'package:gestion_locative/presentation/widgets/common/custom_drawer.dart';
import 'package:gestion_locative/presentation/widgets/common/loading_indicator.dart';
import 'package:gestion_locative/presentation/widgets/dashboard/paiement_item.dart';
import 'package:intl/intl.dart';

class PaiementsListScreen extends StatefulWidget {
  const PaiementsListScreen({Key? key}) : super(key: key);

  @override
  State<PaiementsListScreen> createState() => _PaiementsListScreenState();
}

class _PaiementsListScreenState extends State<PaiementsListScreen> {
  final PaiementRepository _paiementRepository = PaiementRepository();
  final formatter = NumberFormat.currency(symbol: '', decimalDigits: 0);

  bool _isLoading = true;
  List<Paiement> _paiements = [];
  Map<int, Locataire> _locataires = {};
  String _filterStatus = 'tous';

  @override
  void initState() {
    super.initState();
    _loadData();

    // Appliquer le filtre s'il est passé en argument
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final Object? arguments = ModalRoute.of(context)?.settings.arguments;
      if (arguments != null && arguments is Map<String, dynamic>) {
        final filter = arguments['filter'];
        if (filter != null && filter is String) {
          setState(() {
            _filterStatus = filter;
          });
        }
      }
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Charger tous les paiements
      final paiements = await _paiementRepository.getAllPaiements();
      final locataires = <int, Locataire>{};

      // Charger les locataires associés
      for (final paiement in paiements) {
        if (paiement.id == null) continue;

        final locataire = await _paiementRepository.getLocataireForPaiement(
          paiement.id!,
        );
        if (locataire != null) {
          locataires[paiement.id!] = locataire;
        }
      }

      setState(() {
        _paiements = paiements;
        _locataires = locataires;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des paiements: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  // Filtrer les paiements selon le statut sélectionné
  List<Paiement> _getFilteredPaiements() {
    if (_filterStatus == 'tous') {
      return _paiements;
    } else if (_filterStatus == 'en_retard') {
      return _paiements
          .where(
            (p) =>
                p.statut == StatutPaiement.impaye ||
                p.statut == StatutPaiement.enRetard,
          )
          .toList();
    } else if (_filterStatus == 'payés') {
      return _paiements.where((p) => p.statut == StatutPaiement.paye).toList();
    } else if (_filterStatus == 'en_cours') {
      return _paiements
          .where((p) => p.statut == StatutPaiement.partiel)
          .toList();
    }
    return _paiements;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paiements'),
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
              AppRoutes.paiementForm,
            ).then((_) => _loadData()),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child:
                _isLoading
                    ? const LoadingIndicator(
                      message: 'Chargement des paiements...',
                    )
                    : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _buildFilterChip('Tous', 'tous'),
            const SizedBox(width: 8),
            _buildFilterChip('En retard', 'en_retard', color: AppColors.danger),
            const SizedBox(width: 8),
            _buildFilterChip('Payés', 'payés', color: AppColors.success),
            const SizedBox(width: 8),
            _buildFilterChip('En cours', 'en_cours', color: AppColors.warning),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, {Color? color}) {
    final isSelected = _filterStatus == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      selectedColor:
          color?.withOpacity(0.2) ?? AppColors.primary.withOpacity(0.2),
      checkmarkColor: color ?? AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? (color ?? AppColors.primary) : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (selected) {
        setState(() {
          _filterStatus = value;
        });
      },
    );
  }

  Widget _buildContent() {
    final filteredPaiements = _getFilteredPaiements();

    if (filteredPaiements.isEmpty) {
      String message;

      switch (_filterStatus) {
        case 'en_retard':
          message = 'Aucun paiement en retard';
          break;
        case 'payés':
          message = 'Aucun paiement complété';
          break;
        case 'en_cours':
          message = 'Aucun paiement en cours';
          break;
        default:
          message = 'Aucun paiement trouvé';
      }

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.payments_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Les paiements apparaîtront ici',
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
        itemCount: filteredPaiements.length,
        itemBuilder: (context, index) {
          final paiement = filteredPaiements[index];
          final locataire = _locataires[paiement.id];

          if (locataire == null) {
            return const SizedBox.shrink();
          }

          return PaiementItem(
            paiement: paiement,
            locataire: locataire,
            onTap:
                () => Navigator.pushNamed(
                  context,
                  AppRoutes.paiementDetail,
                  arguments: paiement.id,
                ).then((_) => _loadData()),
          );
        },
      ),
    );
  }
}

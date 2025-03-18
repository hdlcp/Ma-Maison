import 'package:flutter/material.dart';
import 'package:gestion_locative/config/constants.dart';
import 'package:gestion_locative/data/models/chambre.dart';
import 'package:gestion_locative/data/models/locataire.dart';
import 'package:gestion_locative/data/models/maison.dart';
import 'package:gestion_locative/data/models/paiement.dart';
// ignore: unused_import
import 'package:gestion_locative/data/repositories/chambre_repository.dart';
import 'package:gestion_locative/data/repositories/maison_repository.dart';
import 'package:gestion_locative/data/repositories/paiement_repository.dart';
import 'package:gestion_locative/presentation/widgets/common/loading_indicator.dart';
import 'package:intl/intl.dart';

class PaiementDetailScreen extends StatefulWidget {
  final int paiementId;

  const PaiementDetailScreen({Key? key, required this.paiementId})
    : super(key: key);

  @override
  State<PaiementDetailScreen> createState() => _PaiementDetailScreenState();
}

class _PaiementDetailScreenState extends State<PaiementDetailScreen> {
  final PaiementRepository _paiementRepository = PaiementRepository();
  final MaisonRepository _maisonRepository = MaisonRepository();

  bool _isLoading = true;
  bool _isSaving = false;

  Paiement? _paiement;
  Locataire? _locataire;
  Chambre? _chambre;
  Maison? _maison;

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
      // Charger le paiement
      final paiement = await _paiementRepository.getPaiementById(
        widget.paiementId,
      );

      // Charger le locataire associé
      final locataire = await _paiementRepository.getLocataireForPaiement(
        widget.paiementId,
      );

      if (locataire != null) {
        // Charger la chambre du locataire
        final chambre = await _maisonRepository.getChambreById(
          locataire.chambreId,
        );

        if (chambre != null) {
          // Charger la maison qui contient la chambre
          final maison = await _maisonRepository.getMaisonById(
            chambre.maisonId,
          );

          setState(() {
            _paiement = paiement;
            _locataire = locataire;
            _chambre = chambre;
            _maison = maison;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement du paiement: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Mettre à jour le statut du paiement
  Future<void> _updatePaiementStatus(String newStatus) async {
    if (_paiement == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await _paiementRepository.updatePaiementStatut(
        widget.paiementId,
        newStatus,
      );

      // Recharger les données pour mettre à jour l'UI
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Statut mis à jour: $newStatus'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la mise à jour: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails du Paiement'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadData,
          ),
        ],
      ),
      body:
          _isLoading
              ? const LoadingIndicator(message: 'Chargement des détails...')
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_paiement == null || _locataire == null) {
      return const Center(
        child: Text('Impossible de charger les détails du paiement'),
      );
    }

    final formatter = NumberFormat.currency(symbol: '', decimalDigits: 0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusCard(),
          const SizedBox(height: 24),

          // Section Informations de Paiement
          _buildSectionTitle('Informations de Paiement'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildInfoRow(
                    'Montant',
                    '${formatter.format(_paiement!.montant)} FCFA',
                  ),
                  _buildInfoRow(
                    'Échéance',
                    DateFormat('dd/MM/yyyy').format(_paiement!.dateEcheance),
                  ),
                  if (_paiement!.datePaiement != null)
                    _buildInfoRow(
                      'Date de paiement',
                      DateFormat('dd/MM/yyyy').format(_paiement!.datePaiement!),
                    ),
                  if (_paiement!.methodePaiement != null &&
                      _paiement!.methodePaiement!.isNotEmpty)
                    _buildInfoRow('Méthode', _paiement!.methodePaiement!),
                  if (_paiement!.notes != null && _paiement!.notes!.isNotEmpty)
                    _buildInfoRow('Notes', _paiement!.notes!),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Section Informations du Locataire
          _buildSectionTitle('Informations du Locataire'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildInfoRow('Nom', _locataire!.nomComplet),
                  if (_locataire!.telephone != null &&
                      _locataire!.telephone!.isNotEmpty)
                    _buildInfoRow('Téléphone', _locataire!.telephone!),
                  if (_locataire!.email != null &&
                      _locataire!.email!.isNotEmpty)
                    _buildInfoRow('Email', _locataire!.email!),
                  _buildInfoRow(
                    'Date d\'entrée',
                    DateFormat('dd/MM/yyyy').format(_locataire!.dateEntree),
                  ),
                  _buildInfoRow(
                    'Loyer mensuel',
                    '${formatter.format(_locataire!.montantLoyer)} FCFA',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Section Informations sur le Logement
          if (_chambre != null && _maison != null) ...[
            _buildSectionTitle('Informations sur le Logement'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildInfoRow('Maison', _maison!.nom),
                    _buildInfoRow('Adresse', _maison!.adresse),
                    _buildInfoRow('Chambre', 'N° ${_chambre!.numero}'),
                    _buildInfoRow('Type', _chambre!.type),
                    if (_chambre!.taille != null &&
                        _chambre!.taille!.isNotEmpty)
                      _buildInfoRow('Taille', _chambre!.taille!),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 32),

          // Boutons d'action
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    if (_paiement == null) return const SizedBox.shrink();

    late Color statusColor;
    late IconData statusIcon;

    if (_paiement!.statut == StatutPaiement.paye) {
      statusColor = AppColors.success;
      statusIcon = Icons.check_circle;
    } else if (_paiement!.statut == StatutPaiement.impaye ||
        _paiement!.statut == StatutPaiement.enRetard) {
      statusColor = AppColors.danger;
      statusIcon = Icons.warning;
    } else if (_paiement!.statut == StatutPaiement.partiel) {
      statusColor = AppColors.warning;
      statusIcon = Icons.watch_later;
    } else {
      statusColor = AppColors.info;
      statusIcon = Icons.info;
    }

    return Card(
      color: statusColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withOpacity(0.5), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getStatusText(_paiement!.statut),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getStatusDescription(_paiement!),
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case StatutPaiement.paye:
        return 'Payé';
      case StatutPaiement.partiel:
        return 'Partiellement payé';
      case StatutPaiement.impaye:
        return 'Impayé';
      case StatutPaiement.enRetard:
        return 'En retard';
      default:
        return 'Inconnu';
    }
  }

  String _getStatusDescription(Paiement paiement) {
    switch (paiement.statut) {
      case StatutPaiement.paye:
        return 'Paiement effectué le ${DateFormat('dd/MM/yyyy').format(paiement.datePaiement!)}';
      case StatutPaiement.partiel:
        return 'Paiement partiel reçu, reste à compléter';
      case StatutPaiement.impaye:
      case StatutPaiement.enRetard:
        final daysLate =
            DateTime.now().difference(paiement.dateEcheance).inDays;
        return 'Paiement en retard de $daysLate jours';
      default:
        return 'Statut du paiement inconnu';
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_paiement == null) return const SizedBox.shrink();

    // Si le paiement est déjà payé, juste montrer un message
    if (_paiement!.statut == StatutPaiement.paye) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.success),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Ce paiement a été marqué comme payé',
                style: TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Si le paiement n'est pas payé, montrer les options de changement de statut
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed:
              _isSaving
                  ? null
                  : () => _updatePaiementStatus(StatutPaiement.paye),
          icon: const Icon(Icons.check),
          label: const Text('Marquer comme payé'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(height: 10),
        if (_paiement!.statut != StatutPaiement.partiel) ...[
          OutlinedButton.icon(
            onPressed:
                _isSaving
                    ? null
                    : () => _updatePaiementStatus(StatutPaiement.partiel),
            icon: const Icon(Icons.watch_later),
            label: const Text('Marquer comme partiellement payé'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.warning,
              side: const BorderSide(color: AppColors.warning),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (_paiement!.statut != StatutPaiement.impaye &&
            _paiement!.statut != StatutPaiement.enRetard) ...[
          OutlinedButton.icon(
            onPressed:
                _isSaving
                    ? null
                    : () => _updatePaiementStatus(StatutPaiement.impaye),
            icon: const Icon(Icons.cancel),
            label: const Text('Marquer comme impayé'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: AppColors.danger),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      ],
    );
  }
}

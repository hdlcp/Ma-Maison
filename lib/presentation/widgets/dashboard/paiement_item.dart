import 'package:flutter/material.dart';
import 'package:gestion_locative/data/models/paiement.dart';
import 'package:gestion_locative/data/models/locataire.dart';
import 'package:gestion_locative/config/constants.dart';
import 'package:intl/intl.dart';

class PaiementItem extends StatelessWidget {
  final Paiement paiement;
  final Locataire locataire;
  final VoidCallback onTap;

  const PaiementItem({
    Key? key,
    required this.paiement,
    required this.locataire,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(symbol: '', decimalDigits: 0);

    final bool isLate = _isPaymentLate();
    final int daysOverdue = _getDaysOverdue();

    return Card(
      elevation: isLate ? 3 : 1,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side:
            isLate
                ? const BorderSide(color: AppColors.danger, width: 1)
                : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _buildStatusIndicator(context),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      locataire.nom,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Échéance: ${DateFormat('dd/MM/yyyy').format(paiement.dateEcheance)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (isLate) ...[
                      const SizedBox(height: 4),
                      Text(
                        'En retard de $daysOverdue jours',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.danger,
                          fontWeight: FontWeight.bold,
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
                    '${formatter.format(paiement.montant)} FCFA',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getStatusText(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _getStatusColor(),
                      fontWeight: FontWeight.w500,
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

  Widget _buildStatusIndicator(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _getStatusColor(),
      ),
    );
  }

  Color _getStatusColor() {
    if (paiement.statut == StatutPaiement.paye) {
      return AppColors.success;
    } else if (_isPaymentLate()) {
      return AppColors.danger;
    } else if (paiement.statut == StatutPaiement.partiel) {
      return AppColors.warning;
    } else {
      return AppColors.info;
    }
  }

  String _getStatusText() {
    switch (paiement.statut) {
      case StatutPaiement.paye:
        return 'Payé';
      case StatutPaiement.partiel:
        return 'Partiel';
      case StatutPaiement.impaye:
        return _isPaymentLate() ? 'En retard' : 'Non payé';
      default:
        return 'Non payé';
    }
  }

  bool _isPaymentLate() {
    if (paiement.statut == StatutPaiement.paye) return false;

    final now = DateTime.now();
    return now.isAfter(paiement.dateEcheance) &&
        paiement.statut != StatutPaiement.paye;
  }

  int _getDaysOverdue() {
    if (!_isPaymentLate()) return 0;

    final now = DateTime.now();
    return now.difference(paiement.dateEcheance).inDays;
  }
}

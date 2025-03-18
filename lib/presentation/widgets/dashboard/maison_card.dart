import 'package:flutter/material.dart';
import 'package:gestion_locative/config/constants.dart';
import 'package:gestion_locative/data/models/maison.dart';

class MaisonCard extends StatelessWidget {
  final Maison maison;
  final int chambresCount;
  final int chambresOccupees;
  final VoidCallback onTap;

  const MaisonCard({
    Key? key,
    required this.maison,
    required this.chambresCount,
    required this.chambresOccupees,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final occupancyRate =
        chambresCount > 0
            ? (chambresOccupees / chambresCount * 100).toInt()
            : 0;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.home, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          maison.nom,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          maison.adresse,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[600]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoColumn(
                    context,
                    'Chambres',
                    '$chambresOccupees/$chambresCount',
                  ),
                  _buildInfoColumn(context, 'Occupation', '$occupancyRate%'),
                  _buildInfoColumn(
                    context,
                    'Loyer estimé',
                    '${_calculateEstimatedRent()} FCFA',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: chambresCount > 0 ? chambresOccupees / chambresCount : 0,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getOccupancyColor(occupancyRate),
                ),
                minHeight: 5,
                borderRadius: BorderRadius.circular(5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoColumn(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Color _getOccupancyColor(int rate) {
    if (rate < 50) return Colors.orange;
    if (rate < 80) return Colors.blue;
    return Colors.green;
  }

  String _calculateEstimatedRent() {
    // Cette méthode devrait calculer le loyer estimé pour la maison
    // Pour l'instant, nous utilisons une valeur fictive
    return (maison.prixParDefaut * chambresOccupees).toString();
  }
}

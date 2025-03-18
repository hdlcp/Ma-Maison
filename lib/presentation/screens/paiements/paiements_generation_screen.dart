import 'package:flutter/material.dart';
import 'package:gestion_locative/config/constants.dart';
import 'package:gestion_locative/data/repositories/paiement_repository.dart';
import 'package:gestion_locative/data/repositories/locataire_repository.dart';
import 'package:gestion_locative/presentation/widgets/common/custom_drawer.dart';

class PaiementsGenerationScreen extends StatefulWidget {
  const PaiementsGenerationScreen({Key? key}) : super(key: key);

  @override
  State<PaiementsGenerationScreen> createState() =>
      _PaiementsGenerationScreenState();
}

class _PaiementsGenerationScreenState extends State<PaiementsGenerationScreen> {
  final PaiementRepository _paiementRepository = PaiementRepository();
  final LocataireRepository _locataireRepository = LocataireRepository();

  bool _isLoading = false;
  bool _isGenerated = false;
  int _paiementsGeneres = 0;
  List<int> _locatairesAvecErreurs = [];
  String? _errorMessage;

  int _totalLocataires = 0;

  @override
  void initState() {
    super.initState();
    _loadLocatairesCount();
  }

  Future<void> _loadLocatairesCount() async {
    try {
      final locataires = await _locataireRepository.getAllLocataires();
      setState(() {
        _totalLocataires = locataires.length;
      });
    } catch (e) {
      // Ignorer l'erreur, c'est juste pour l'affichage
    }
  }

  Future<void> _genererPaiements() async {
    setState(() {
      _isLoading = true;
      _isGenerated = false;
      _errorMessage = null;
    });

    try {
      final resultat = await _paiementRepository.genererPaiementsRecurrents();

      setState(() {
        _isLoading = false;
        _isGenerated = true;
        _paiementsGeneres = resultat['paiementsGeneres'];
        _locatairesAvecErreurs = resultat['locatairesAvecErreurs'] ?? [];

        if (resultat['success'] != true) {
          _errorMessage = resultat['error'] ?? 'Erreur inconnue';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Génération de paiements')),
      drawer: const CustomDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(),
            const SizedBox(height: 24),

            if (_isGenerated) _buildResultCard(),

            const Spacer(),
            _buildGenerateButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'Informations',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Cette fonctionnalité vous permet de générer automatiquement les paiements '
            'pour tous vos locataires actifs, en fonction de leur période de paiement.',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          const Text(
            '• Pour les paiements mensuels : le 5 du mois en cours ou suivant',
            style: TextStyle(fontSize: 14),
          ),
          const Text(
            '• Pour les paiements trimestriels : le 5 du premier mois du prochain trimestre',
            style: TextStyle(fontSize: 14),
          ),
          const Text(
            '• Pour les paiements semestriels : le 5 du premier mois du prochain semestre',
            style: TextStyle(fontSize: 14),
          ),
          const Text(
            '• Pour les paiements annuels : même jour que la date d\'entrée, année suivante',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          Text(
            'Nombre total de locataires : $_totalLocataires',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Note : Les paiements ne seront pas dupliqués si des paiements existent déjà pour le mois en cours.',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    final bool hasErrors =
        _errorMessage != null || _locatairesAvecErreurs.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            hasErrors
                ? AppColors.warning.withOpacity(0.1)
                : AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasErrors ? AppColors.warning : AppColors.success,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasErrors ? Icons.warning : Icons.check_circle,
                color: hasErrors ? AppColors.warning : AppColors.success,
              ),
              const SizedBox(width: 8),
              Text(
                hasErrors
                    ? 'Génération avec avertissements'
                    : 'Génération réussie',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: hasErrors ? AppColors.warning : AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Paiements générés : $_paiementsGeneres',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          if (_locatairesAvecErreurs.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Erreurs pour ${_locatairesAvecErreurs.length} locataire(s)',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.warning,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              'Erreur : $_errorMessage',
              style: TextStyle(fontSize: 14, color: AppColors.danger),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _genererPaiements,
        icon:
            _isLoading
                ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                : const Icon(Icons.play_arrow),
        label: Text(
          _isLoading ? 'Génération en cours...' : 'Générer les paiements',
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}

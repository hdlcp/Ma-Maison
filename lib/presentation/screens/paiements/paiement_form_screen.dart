import 'package:flutter/material.dart';
import 'package:gestion_locative/config/constants.dart';
import 'package:gestion_locative/data/models/locataire.dart';
import 'package:gestion_locative/data/models/paiement.dart';
import 'package:gestion_locative/data/repositories/locataire_repository.dart';
import 'package:gestion_locative/data/repositories/paiement_repository.dart';
import 'package:gestion_locative/presentation/widgets/common/loading_indicator.dart';
import 'package:intl/intl.dart';

class PaiementFormScreen extends StatefulWidget {
  final Paiement? paiement; // Si null, c'est un ajout, sinon une modification

  const PaiementFormScreen({Key? key, this.paiement}) : super(key: key);

  @override
  State<PaiementFormScreen> createState() => _PaiementFormScreenState();
}

class _PaiementFormScreenState extends State<PaiementFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final PaiementRepository _paiementRepository = PaiementRepository();
  final LocataireRepository _locataireRepository = LocataireRepository();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;
  List<Locataire> _locataires = [];

  // Contrôleurs pour les champs de formulaire
  final _montantController = TextEditingController();
  final _dateEcheanceController = TextEditingController();
  final _datePaiementController = TextEditingController();
  final _notesController = TextEditingController();

  // Valeurs pour les champs de sélection
  Locataire? _selectedLocataire;
  String _selectedStatut = StatutPaiement.impaye;
  String _selectedMethode = 'espèces';

  final List<String> _methodePaiements = [
    'espèces',
    'virement',
    'chèque',
    'mobile money',
  ];

  @override
  void initState() {
    super.initState();
    _isEditing = widget.paiement != null;
    _loadData();
  }

  @override
  void dispose() {
    _montantController.dispose();
    _dateEcheanceController.dispose();
    _datePaiementController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Charger tous les locataires
      final locataires = await _locataireRepository.getAllLocataires();

      setState(() {
        _locataires = locataires;

        // Si c'est une modification, préremplir les champs
        if (_isEditing) {
          final paiement = widget.paiement!;
          _montantController.text = paiement.montant.toString();
          _dateEcheanceController.text = DateFormat(
            'yyyy-MM-dd',
          ).format(paiement.dateEcheance);

          if (paiement.datePaiement != null) {
            _datePaiementController.text = DateFormat(
              'yyyy-MM-dd',
            ).format(paiement.datePaiement!);
          }

          if (paiement.notes != null) {
            _notesController.text = paiement.notes!;
          }

          _selectedStatut = paiement.statut;

          if (paiement.methodePaiement != null &&
              paiement.methodePaiement!.isNotEmpty) {
            _selectedMethode = paiement.methodePaiement!;
          }

          // Sélectionner le locataire (à implémenter)
          _findLocataireById(paiement.locataireId);
        } else {
          // Valeurs par défaut pour un nouveau paiement
          _dateEcheanceController.text = DateFormat(
            'yyyy-MM-dd',
          ).format(DateTime.now().add(const Duration(days: 30)));
          _selectedLocataire = locataires.isNotEmpty ? locataires.first : null;

          if (_selectedLocataire != null) {
            _montantController.text =
                _selectedLocataire!.montantLoyer.toString();
          }
        }

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des données: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _findLocataireById(int locataireId) {
    for (var locataire in _locataires) {
      if (locataire.id == locataireId) {
        setState(() {
          _selectedLocataire = locataire;
        });
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier le paiement' : 'Nouveau paiement'),
      ),
      body:
          _isLoading
              ? const LoadingIndicator(message: 'Chargement des données...')
              : _buildForm(),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFormHeader(),
            const SizedBox(height: 24),

            // Sélection du locataire
            _buildSectionTitle('Locataire'),
            DropdownButtonFormField<Locataire>(
              decoration: const InputDecoration(
                labelText: 'Sélectionner un locataire',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              value: _selectedLocataire,
              items:
                  _locataires.map((locataire) {
                    return DropdownMenuItem<Locataire>(
                      value: locataire,
                      child: Text(locataire.nomComplet),
                    );
                  }).toList(),
              onChanged: (Locataire? newValue) {
                setState(() {
                  _selectedLocataire = newValue;

                  // Mettre à jour le montant
                  if (_selectedLocataire != null) {
                    _montantController.text =
                        _selectedLocataire!.montantLoyer.toString();
                  }
                });
              },
              validator:
                  (value) =>
                      value == null
                          ? 'Veuillez sélectionner un locataire'
                          : null,
            ),
            const SizedBox(height: 24),

            // Informations de paiement
            _buildSectionTitle('Informations de paiement'),
            TextFormField(
              controller: _montantController,
              decoration: const InputDecoration(
                labelText: 'Montant (FCFA)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer un montant';
                }
                if (double.tryParse(value) == null ||
                    double.parse(value) <= 0) {
                  return 'Veuillez entrer un montant valide';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Date d'échéance
            TextFormField(
              controller: _dateEcheanceController,
              decoration: InputDecoration(
                labelText: 'Date d\'échéance',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.calendar_today),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.date_range),
                  onPressed: () => _selectDate(_dateEcheanceController),
                ),
              ),
              readOnly: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez sélectionner une date d\'échéance';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Statut et méthode de paiement
            _buildSectionTitle('Statut et méthode'),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Statut du paiement',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.info),
              ),
              value: _selectedStatut,
              items: [
                DropdownMenuItem(
                  value: StatutPaiement.impaye,
                  child: const Text('Impayé'),
                ),
                DropdownMenuItem(
                  value: StatutPaiement.enRetard,
                  child: const Text('En retard'),
                ),
                DropdownMenuItem(
                  value: StatutPaiement.partiel,
                  child: const Text('Partiellement payé'),
                ),
                DropdownMenuItem(
                  value: StatutPaiement.paye,
                  child: const Text('Payé'),
                ),
              ],
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedStatut = newValue;

                    // Si payé, définir la date de paiement à aujourd'hui si vide
                    if (newValue == StatutPaiement.paye &&
                        _datePaiementController.text.isEmpty) {
                      _datePaiementController.text = DateFormat(
                        'yyyy-MM-dd',
                      ).format(DateTime.now());
                    }
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Si payé ou partiellement payé, afficher la date de paiement et la méthode
            if (_selectedStatut == StatutPaiement.paye ||
                _selectedStatut == StatutPaiement.partiel) ...[
              TextFormField(
                controller: _datePaiementController,
                decoration: InputDecoration(
                  labelText: 'Date de paiement',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.calendar_today),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.date_range),
                    onPressed: () => _selectDate(_datePaiementController),
                  ),
                ),
                readOnly: true,
                validator: (value) {
                  if (_selectedStatut == StatutPaiement.paye &&
                      (value == null || value.isEmpty)) {
                    return 'Veuillez sélectionner une date de paiement';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Méthode de paiement',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.payment),
                ),
                value: _selectedMethode,
                items:
                    _methodePaiements.map((methode) {
                      return DropdownMenuItem<String>(
                        value: methode,
                        child: Text(
                          methode.substring(0, 1).toUpperCase() +
                              methode.substring(1),
                        ),
                      );
                    }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedMethode = newValue;
                    });
                  }
                },
              ),
            ],
            const SizedBox(height: 16),

            // Notes (optionnel)
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optionnel)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),

            // Bouton de soumission
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child:
                    _isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                          _isEditing
                              ? 'Mettre à jour le paiement'
                              : 'Enregistrer le paiement',
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            _isEditing ? Icons.edit : Icons.add_circle,
            color: AppColors.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditing ? 'Modifier le paiement' : 'Nouveau paiement',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isEditing
                      ? 'Modifiez les informations de ce paiement'
                      : 'Enregistrez un nouveau paiement pour un locataire',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final DateTime initialDate =
        controller.text.isNotEmpty
            ? DateFormat('yyyy-MM-dd').parse(controller.text)
            : DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        controller.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || _selectedLocataire == null) {
      // Formulaire invalide, montrer une notification
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs obligatoires'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final double montant = double.parse(_montantController.text);
      final DateTime dateEcheance = DateFormat(
        'yyyy-MM-dd',
      ).parse(_dateEcheanceController.text);

      DateTime? datePaiement;
      if (_datePaiementController.text.isNotEmpty) {
        datePaiement = DateFormat(
          'yyyy-MM-dd',
        ).parse(_datePaiementController.text);
      }

      final String? methodePaiement =
          (_selectedStatut == StatutPaiement.paye ||
                  _selectedStatut == StatutPaiement.partiel)
              ? _selectedMethode
              : null;

      final String? notes =
          _notesController.text.isNotEmpty ? _notesController.text : null;

      if (_isEditing) {
        // Mettre à jour un paiement existant
        final updatedPaiement = Paiement(
          id: widget.paiement!.id,
          locataireId: _selectedLocataire!.id!,
          dateEcheance: dateEcheance,
          datePaiement: datePaiement,
          montant: montant,
          statut: _selectedStatut,
          methodePaiement: methodePaiement,
          notes: notes,
        );

        await _paiementRepository.updatePaiement(updatedPaiement);
      } else {
        // Créer un nouveau paiement
        final newPaiement = Paiement(
          locataireId: _selectedLocataire!.id!,
          dateEcheance: dateEcheance,
          datePaiement: datePaiement,
          montant: montant,
          statut: _selectedStatut,
          methodePaiement: methodePaiement,
          notes: notes,
        );

        await _paiementRepository.insertPaiement(newPaiement);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Paiement mis à jour avec succès'
                  : 'Paiement enregistré avec succès',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}

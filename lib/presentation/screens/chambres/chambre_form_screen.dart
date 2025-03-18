import 'package:flutter/material.dart';
import 'package:gestion_locative/data/models/chambre.dart';
import 'package:gestion_locative/data/repositories/maison_repository.dart';
import 'package:gestion_locative/config/constants.dart';

class ChambreFormScreen extends StatefulWidget {
  final Chambre? chambre;
  final int? maisonId;

  const ChambreFormScreen({Key? key, this.chambre, this.maisonId})
    : super(key: key);

  @override
  State<ChambreFormScreen> createState() => _ChambreFormScreenState();
}

class _ChambreFormScreenState extends State<ChambreFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final MaisonRepository _maisonRepository = MaisonRepository();

  final _numeroController = TextEditingController();
  final _tailleController = TextEditingController();
  final _typeController = TextEditingController();

  bool _estOccupee = false;
  int? _selectedMaisonId;
  List<Map<String, dynamic>> _maisons = [];
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadMaisons();

    // Initialiser avec les données existantes ou les valeurs par défaut
    if (widget.chambre != null) {
      _numeroController.text = widget.chambre!.numero;
      _tailleController.text = widget.chambre!.taille ?? '';
      _typeController.text = widget.chambre!.type;
      _estOccupee = widget.chambre!.estOccupee;
      _selectedMaisonId = widget.chambre!.maisonId;
    } else if (widget.maisonId != null) {
      _selectedMaisonId = widget.maisonId;
    }
  }

  Future<void> _loadMaisons() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final maisons = await _maisonRepository.getAllMaisons();
      setState(() {
        _maisons =
            maisons
                .map((maison) => {'id': maison.id, 'nom': maison.nom})
                .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des maisons: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _saveChambre() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Vérifier si une maison est sélectionnée
    if (_selectedMaisonId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une maison'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final chambre = Chambre(
        id: widget.chambre?.id,
        maisonId: _selectedMaisonId!,
        numero: _numeroController.text.trim(),
        taille:
            _tailleController.text.trim().isEmpty
                ? null
                : _tailleController.text.trim(),
        type: _typeController.text.trim(),
        estOccupee: _estOccupee,
      );

      if (widget.chambre == null) {
        // Création d'une nouvelle chambre
        await _maisonRepository.insertChambre(chambre);
      } else {
        // Mise à jour d'une chambre existante
        await _maisonRepository.insertChambre(chambre);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.chambre == null
                  ? 'Chambre créée avec succès'
                  : 'Chambre mise à jour avec succès',
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
            content: Text('Erreur lors de l\'enregistrement: $e'),
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

  @override
  void dispose() {
    _numeroController.dispose();
    _tailleController.dispose();
    _typeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.chambre == null
              ? 'Ajouter une chambre'
              : 'Modifier la chambre',
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_maisons.isNotEmpty &&
                          (_selectedMaisonId == null ||
                              widget.maisonId == null))
                        DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            labelText: 'Maison',
                            border: OutlineInputBorder(),
                          ),
                          value: _selectedMaisonId,
                          items:
                              _maisons
                                  .map(
                                    (maison) => DropdownMenuItem<int>(
                                      value: maison['id'],
                                      child: Text(maison['nom']),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedMaisonId = value;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Veuillez sélectionner une maison';
                            }
                            return null;
                          },
                        ),
                      if (_selectedMaisonId != null && widget.maisonId != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Text(
                            'Maison: ${_maisons.firstWhere((m) => m['id'] == _selectedMaisonId, orElse: () => {'nom': 'Inconnue'})['nom']}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _numeroController,
                        decoration: const InputDecoration(
                          labelText: 'Numéro de chambre',
                          hintText: 'Exemple: A1, 101, etc.',
                          prefixIcon: Icon(Icons.meeting_room),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer un numéro';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _typeController,
                        decoration: const InputDecoration(
                          labelText: 'Type de chambre',
                          hintText: 'Exemple: Simple, Double, Suite, etc.',
                          prefixIcon: Icon(Icons.category),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer un type';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _tailleController,
                        decoration: const InputDecoration(
                          labelText: 'Taille',
                          hintText:
                              'Exemple: Petite, Moyenne, Grande, 12m², etc.',
                          prefixIcon: Icon(Icons.square_foot),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Chambre occupée?'),
                        value: _estOccupee,
                        onChanged: (value) {
                          setState(() {
                            _estOccupee = value;
                          });
                        },
                        activeColor: AppColors.primary,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isSaving ? null : _saveChambre,
                        child:
                            _isSaving
                                ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text('Enregistrement...'),
                                  ],
                                )
                                : Text(
                                  widget.chambre == null
                                      ? 'Ajouter'
                                      : 'Mettre à jour',
                                ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}

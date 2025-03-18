import 'package:flutter/material.dart';
import 'package:gestion_locative/config/constants.dart';
import 'package:gestion_locative/data/models/chambre.dart';
import 'package:gestion_locative/data/models/maison.dart';
import 'package:gestion_locative/data/models/probleme.dart';
import 'package:gestion_locative/data/repositories/maison_repository.dart';
import 'package:gestion_locative/data/repositories/probleme_repository.dart';
import 'package:intl/intl.dart';

class ProblemeFormScreen extends StatefulWidget {
  final Probleme?
  probleme; // Si null, c'est un ajout, sinon c'est une modification

  const ProblemeFormScreen({Key? key, this.probleme}) : super(key: key);

  @override
  State<ProblemeFormScreen> createState() => _ProblemeFormScreenState();
}

class _ProblemeFormScreenState extends State<ProblemeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProblemeRepository _problemeRepository = ProblemeRepository();
  final MaisonRepository _maisonRepository = MaisonRepository();

  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();

  // Valeurs du formulaire
  int? _maisonSelectionnee;
  int? _chambreSelectionnee;
  String _typeProbleme = Probleme.getTypesList().first;
  String _urgence = Probleme.getUrgencesList().first;
  DateTime _dateSignalement = DateTime.now();
  String _statut = Probleme.getStatutsList().first;

  // États
  bool _isLoading = false;
  bool _isEditing = false;
  bool _isChambresLoading = false;

  // Données pour les dropdowns
  List<Maison> _maisons = [];
  List<Chambre> _chambresDisponibles = [];
  Map<int, List<Chambre>> _chambresByMaison = {};

  @override
  void initState() {
    super.initState();
    _isEditing = widget.probleme != null;
    _loadMaisons();

    if (_isEditing) {
      _initFormWithProbleme();
    }
  }

  Future<void> _loadMaisons() async {
    try {
      final maisons = await _maisonRepository.getAllMaisons();
      final Map<int, List<Chambre>> chambresByMaison = {};

      // Chargement des chambres pour chaque maison
      for (final maison in maisons) {
        if (maison.id != null) {
          final chambres = await _maisonRepository.getChambresForMaison(
            maison.id!,
          );
          chambresByMaison[maison.id!] = chambres;
        }
      }

      setState(() {
        _maisons = maisons;
        _chambresByMaison = chambresByMaison;

        // Sélectionner la première maison par défaut si on ajoute un nouveau problème
        if (!_isEditing && maisons.isNotEmpty && maisons[0].id != null) {
          _maisonSelectionnee = maisons[0].id;
          _updateChambresDisponibles();
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement des maisons: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  void _initFormWithProbleme() {
    final probleme = widget.probleme!;

    // Remplir les champs avec les valeurs existantes
    _maisonSelectionnee = probleme.maisonId;
    _chambreSelectionnee = probleme.chambreId;
    _typeProbleme = probleme.type;
    _urgence = probleme.urgence;
    _dateSignalement = probleme.dateSignalement;
    _statut = probleme.statut;
    _descriptionController.text = probleme.description;
    _notesController.text = probleme.notes ?? '';

    if (_maisonSelectionnee != null) {
      _updateChambresDisponibles();
    }
  }

  Future<void> _updateChambresDisponibles() async {
    if (_maisonSelectionnee == null) {
      setState(() {
        _chambresDisponibles = [];
        _chambreSelectionnee = null;
      });
      return;
    }

    setState(() {
      _isChambresLoading = true;
    });

    try {
      // Récupérer toutes les chambres de la maison
      final chambres = _chambresByMaison[_maisonSelectionnee] ?? [];

      setState(() {
        _chambresDisponibles = chambres;
        _isChambresLoading = false;

        // Si nous sommes en mode édition, conserver la chambre sélectionnée
        if (_isEditing && widget.probleme?.chambreId != null) {
          if (_chambresDisponibles.any(
            (c) => c.id == widget.probleme!.chambreId,
          )) {
            _chambreSelectionnee = widget.probleme!.chambreId;
          } else {
            _chambreSelectionnee =
                _chambresDisponibles.isNotEmpty
                    ? _chambresDisponibles[0].id
                    : null;
          }
        } else if (_chambresDisponibles.isNotEmpty) {
          _chambreSelectionnee = _chambresDisponibles[0].id;
        } else {
          _chambreSelectionnee = null;
        }
      });
    } catch (e) {
      setState(() {
        _isChambresLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement des chambres: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Modifier le problème' : 'Signaler un problème',
        ),
      ),
      body: _buildForm(),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête du formulaire
            _buildFormHeader(),
            const SizedBox(height: 24),

            // Localisation du problème
            const Text(
              'Localisation du problème',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Sélection de la maison
            DropdownButtonFormField<int>(
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Maison*',
                prefixIcon: Icon(Icons.home),
                border: OutlineInputBorder(),
              ),
              value: _maisonSelectionnee,
              items:
                  _maisons.map((maison) {
                    return DropdownMenuItem<int>(
                      value: maison.id,
                      child: Text(maison.nom),
                    );
                  }).toList(),
              validator: (value) {
                if (value == null) {
                  return 'Veuillez sélectionner une maison';
                }
                return null;
              },
              onChanged: (value) {
                setState(() {
                  _maisonSelectionnee = value;
                  _chambreSelectionnee =
                      null; // Réinitialiser la chambre sélectionnée
                });
                _updateChambresDisponibles();
              },
            ),
            const SizedBox(height: 16),

            // Sélection de la chambre (optionnelle)
            _isChambresLoading
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<int?>(
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Chambre (optionnelle)',
                    prefixIcon: Icon(Icons.bedroom_parent),
                    border: OutlineInputBorder(),
                  ),
                  value: _chambreSelectionnee,
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text(
                        'Espace commun / Non spécifique',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    ..._chambresDisponibles.map((chambre) {
                      return DropdownMenuItem<int?>(
                        value: chambre.id,
                        child: Text(
                          'Chambre ${chambre.numero} (${chambre.type})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _chambreSelectionnee = value;
                    });
                  },
                ),
            const SizedBox(height: 24),

            // Informations sur le problème
            const Text(
              'Informations sur le problème',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Type de problème
            DropdownButtonFormField<String>(
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Type de problème*',
                prefixIcon: Icon(Icons.category),
                border: OutlineInputBorder(),
              ),
              value: _typeProbleme,
              items:
                  Probleme.getTypesList().map((type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _typeProbleme = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Niveau d'urgence
            DropdownButtonFormField<String>(
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Niveau d\'urgence*',
                prefixIcon: Icon(Icons.priority_high),
                border: OutlineInputBorder(),
              ),
              value: _urgence,
              items:
                  Probleme.getUrgencesList().map((urgence) {
                    return DropdownMenuItem<String>(
                      value: urgence,
                      child: Text(urgence),
                    );
                  }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _urgence = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Description du problème
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description du problème*',
                hintText: 'Décrivez le problème en détail...',
                prefixIcon: Icon(Icons.description),
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'La description est obligatoire';
                }
                if (value.length < 10) {
                  return 'La description doit faire au moins 10 caractères';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Date de signalement
            InkWell(
              onTap: () => _selectDate(context),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date de signalement*',
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                child: Text(DateFormat('dd/MM/yyyy').format(_dateSignalement)),
              ),
            ),
            const SizedBox(height: 16),

            if (_isEditing) ...[
              // Statut du problème (seulement en mode édition)
              DropdownButtonFormField<String>(
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Statut*',
                  prefixIcon: Icon(Icons.info_outline),
                  border: OutlineInputBorder(),
                ),
                value: _statut,
                items:
                    Probleme.getStatutsList().map((statut) {
                      return DropdownMenuItem<String>(
                        value: statut,
                        child: Text(statut),
                      );
                    }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _statut = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
            ],

            // Notes (optionnel)
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optionnel)',
                hintText:
                    'Informations complémentaires, actions entreprises...',
                prefixIcon: Icon(Icons.note),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),

            // Bouton de soumission
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child:
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                          _isEditing
                              ? 'Mettre à jour le problème'
                              : 'Signaler le problème',
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                _isEditing ? Icons.edit : Icons.report_problem,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEditing
                          ? 'Modifier les informations'
                          : 'Nouveau signalement',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isEditing
                          ? 'Modifiez les informations du problème signalé'
                          : 'Remplissez le formulaire pour signaler un nouveau problème',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_isEditing && widget.probleme != null) ...[
          const SizedBox(height: 12),
          Text(
            'Date de signalement: ${DateFormat('dd/MM/yyyy').format(widget.probleme!.dateSignalement)}',
            style: TextStyle(
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateSignalement,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _dateSignalement) {
      setState(() {
        _dateSignalement = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final description = _descriptionController.text.trim();
        final notes = _notesController.text.trim();

        if (_maisonSelectionnee == null) {
          throw Exception('Veuillez sélectionner une maison');
        }

        if (_isEditing) {
          // Mettre à jour un problème existant
          final updatedProbleme = Probleme(
            id: widget.probleme!.id,
            maisonId: _maisonSelectionnee,
            chambreId: _chambreSelectionnee,
            type: _typeProbleme,
            urgence: _urgence,
            description: description,
            dateSignalement: _dateSignalement,
            photoUrl: widget.probleme!.photoUrl,
            statut: _statut,
            notes: notes.isEmpty ? null : notes,
          );

          await _problemeRepository.updateProbleme(updatedProbleme);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Problème mis à jour avec succès'),
                backgroundColor: AppColors.success,
              ),
            );
            Navigator.pop(context, true);
          }
        } else {
          // Créer un nouveau signalement de problème
          final newProbleme = Probleme(
            maisonId: _maisonSelectionnee,
            chambreId: _chambreSelectionnee,
            type: _typeProbleme,
            urgence: _urgence,
            description: description,
            dateSignalement: _dateSignalement,
            statut: 'signalé',
            notes: notes.isEmpty ? null : notes,
          );

          await _problemeRepository.insertProbleme(newProbleme);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Problème signalé avec succès'),
                backgroundColor: AppColors.success,
              ),
            );
            Navigator.pop(context, true);
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${e.toString()}'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
}

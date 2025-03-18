import 'package:flutter/material.dart';
import 'package:gestion_locative/config/constants.dart';
import 'package:gestion_locative/data/models/chambre.dart';
import 'package:gestion_locative/data/models/locataire.dart';
import 'package:gestion_locative/data/models/maison.dart';
import 'package:gestion_locative/data/repositories/locataire_repository.dart';
import 'package:gestion_locative/data/repositories/maison_repository.dart';
import 'package:intl/intl.dart';

class LocataireFormScreen extends StatefulWidget {
  final Locataire?
  locataire; // Si null, c'est un ajout, sinon c'est une modification

  const LocataireFormScreen({Key? key, this.locataire}) : super(key: key);

  @override
  State<LocataireFormScreen> createState() => _LocataireFormScreenState();
}

class _LocataireFormScreenState extends State<LocataireFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final LocataireRepository _locataireRepository = LocataireRepository();
  final MaisonRepository _maisonRepository = MaisonRepository();

  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _montantLoyerController = TextEditingController();

  DateTime _dateEntree = DateTime.now();
  String _periodePaiement = 'mensuel';
  int? _maisonSelectionnee;
  int? _chambreSelectionnee;

  bool _isLoading = false;
  bool _isEditing = false;
  bool _isChambresLoading = false;

  List<Maison> _maisons = [];
  List<Chambre> _chambresDisponibles = [];
  Map<int, List<Chambre>> _chambresByMaison = {};

  @override
  void initState() {
    super.initState();
    _isEditing = widget.locataire != null;
    _loadMaisons();

    if (_isEditing) {
      _initFormWithLocataire();
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

        // Sélectionner la première maison par défaut si on ajoute un nouveau locataire
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

  void _initFormWithLocataire() async {
    final locataire = widget.locataire!;

    // Remplir les champs avec les valeurs existantes
    _nomController.text = locataire.nom;
    _prenomController.text = locataire.prenom ?? '';
    _telephoneController.text = locataire.telephone ?? '';
    _emailController.text = locataire.email ?? '';
    _montantLoyerController.text = locataire.montantLoyer.toString();
    _dateEntree = locataire.dateEntree;
    _periodePaiement = locataire.periodePaiement;
    _chambreSelectionnee = locataire.chambreId;

    // Charger la maison associée à la chambre
    try {
      final chambre = await _maisonRepository.getChambreById(
        locataire.chambreId,
      );
      if (chambre != null) {
        setState(() {
          _maisonSelectionnee = chambre.maisonId;
        });
        await _updateChambresDisponibles(includeOccupied: true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement des détails: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _updateChambresDisponibles({
    bool includeOccupied = false,
  }) async {
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

      // Filtrer pour n'avoir que les chambres disponibles (sauf en mode édition)
      List<Chambre> chambresFiltered;
      if (includeOccupied) {
        // En mode édition, inclure la chambre occupée par le locataire actuel
        chambresFiltered =
            chambres
                .where(
                  (c) =>
                      !c.estOccupee ||
                      (widget.locataire != null &&
                          c.id == widget.locataire!.chambreId),
                )
                .toList();
      } else {
        // Sinon, uniquement les chambres libres
        chambresFiltered = chambres.where((c) => !c.estOccupee).toList();
      }

      setState(() {
        _chambresDisponibles = chambresFiltered;
        _isChambresLoading = false;

        // Sélectionner la première chambre disponible si la liste n'est pas vide et qu'on n'est pas en mode édition
        if (_chambresDisponibles.isNotEmpty) {
          // Si on est en mode édition, garder la chambre actuelle si possible
          if (_isEditing && widget.locataire != null) {
            if (_chambresDisponibles.any(
              (c) => c.id == widget.locataire!.chambreId,
            )) {
              _chambreSelectionnee = widget.locataire!.chambreId;
            } else {
              _chambreSelectionnee = _chambresDisponibles[0].id;
            }
          } else if (_chambreSelectionnee == null ||
              !_chambresDisponibles.any((c) => c.id == _chambreSelectionnee)) {
            _chambreSelectionnee = _chambresDisponibles[0].id;
          }
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
    _nomController.dispose();
    _prenomController.dispose();
    _telephoneController.dispose();
    _emailController.dispose();
    _montantLoyerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Modifier le locataire' : 'Ajouter un locataire',
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

            // Informations personnelles
            const Text(
              'Informations personnelles',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Champ Nom
            TextFormField(
              controller: _nomController,
              decoration: const InputDecoration(
                labelText: 'Nom*',
                hintText: 'Ex: Dupont',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le nom est obligatoire';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Champ Prénom
            TextFormField(
              controller: _prenomController,
              decoration: const InputDecoration(
                labelText: 'Prénom',
                hintText: 'Ex: Marie',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Champ Téléphone
            TextFormField(
              controller: _telephoneController,
              decoration: const InputDecoration(
                labelText: 'Téléphone',
                hintText: 'Ex: 06 12 34 56 78',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),

            // Champ Email
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'Ex: exemple@email.com',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final emailRegex = RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  );
                  if (!emailRegex.hasMatch(value)) {
                    return 'Format d\'email invalide';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Informations de logement
            const Text(
              'Informations de logement',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Sélection de la maison
            DropdownButtonFormField<int>(
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

            // Sélection de la chambre
            _isChambresLoading
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                    labelText: 'Chambre*',
                    prefixIcon: Icon(Icons.bedroom_parent),
                    border: OutlineInputBorder(),
                  ),
                  value: _chambreSelectionnee,
                  items:
                      _chambresDisponibles.map((chambre) {
                        return DropdownMenuItem<int>(
                          value: chambre.id,
                          child: Text(
                            'Chambre ${chambre.numero} (${chambre.type})',
                          ),
                        );
                      }).toList(),
                  validator: (value) {
                    if (value == null) {
                      return 'Veuillez sélectionner une chambre';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    setState(() {
                      _chambreSelectionnee = value;
                    });
                  },
                  disabledHint:
                      _maisonSelectionnee == null
                          ? const Text('Sélectionnez d\'abord une maison')
                          : _chambresDisponibles.isEmpty
                          ? const Text('Aucune chambre disponible')
                          : null,
                ),
            const SizedBox(height: 24),

            // Informations de paiement
            const Text(
              'Informations de paiement',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Date d'entrée
            InkWell(
              onTap: () => _selectDate(context),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date d\'entrée*',
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                child: Text(DateFormat('dd/MM/yyyy').format(_dateEntree)),
              ),
            ),
            const SizedBox(height: 16),

            // Période de paiement
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Période de paiement*',
                prefixIcon: Icon(Icons.schedule),
                border: OutlineInputBorder(),
              ),
              value: _periodePaiement,
              items: [
                const DropdownMenuItem(
                  value: 'mensuel',
                  child: Text('Mensuel'),
                ),
                const DropdownMenuItem(
                  value: 'trimestriel',
                  child: Text('Trimestriel'),
                ),
                const DropdownMenuItem(
                  value: 'semestriel',
                  child: Text('Semestriel'),
                ),
                const DropdownMenuItem(value: 'annuel', child: Text('Annuel')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _periodePaiement = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Montant du loyer
            TextFormField(
              controller: _montantLoyerController,
              decoration: const InputDecoration(
                labelText: 'Montant du loyer (FCFA)*',
                hintText: 'Ex: 25000',
                prefixIcon: Icon(Icons.monetization_on),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le montant du loyer est obligatoire';
                }
                if (double.tryParse(value) == null ||
                    double.parse(value) <= 0) {
                  return 'Veuillez entrer un montant valide';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),

            // Bouton de soumission
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed:
                    _chambresDisponibles.isEmpty || _isLoading
                        ? null
                        : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child:
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                          _isEditing
                              ? 'Enregistrer les modifications'
                              : 'Ajouter le locataire',
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
                _isEditing ? Icons.edit : Icons.person_add,
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
                          : 'Nouveau locataire',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isEditing
                          ? 'Modifiez les informations du locataire'
                          : 'Ajoutez un nouveau locataire à votre gestion',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_isEditing && widget.locataire != null) ...[
          const SizedBox(height: 12),
          Text(
            'Date d\'arrivée: ${DateFormat('dd/MM/yyyy').format(widget.locataire!.dateEntree)}',
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
      initialDate: _dateEntree,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _dateEntree) {
      setState(() {
        _dateEntree = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final nom = _nomController.text.trim();
        final prenom = _prenomController.text.trim();
        final telephone = _telephoneController.text.trim();
        final email = _emailController.text.trim();
        final montantLoyer = double.parse(_montantLoyerController.text.trim());

        if (_chambreSelectionnee == null) {
          throw Exception('Veuillez sélectionner une chambre');
        }

        if (_isEditing) {
          // Mettre à jour un locataire existant
          final updatedLocataire = Locataire(
            id: widget.locataire!.id,
            nom: nom,
            prenom: prenom.isEmpty ? null : prenom,
            telephone: telephone.isEmpty ? null : telephone,
            email: email.isEmpty ? null : email,
            dateEntree: _dateEntree,
            chambreId: _chambreSelectionnee!,
            periodePaiement: _periodePaiement,
            montantLoyer: montantLoyer,
          );

          await _locataireRepository.updateLocataire(updatedLocataire);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Locataire mis à jour avec succès'),
                backgroundColor: AppColors.success,
              ),
            );
            Navigator.pop(context, true);
          }
        } else {
          // Créer un nouveau locataire
          final newLocataire = Locataire(
            nom: nom,
            prenom: prenom.isEmpty ? null : prenom,
            telephone: telephone.isEmpty ? null : telephone,
            email: email.isEmpty ? null : email,
            dateEntree: _dateEntree,
            chambreId: _chambreSelectionnee!,
            periodePaiement: _periodePaiement,
            montantLoyer: montantLoyer,
          );

          await _locataireRepository.insertLocataire(newLocataire);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Locataire ajouté avec succès'),
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

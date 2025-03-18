import 'package:flutter/material.dart';
import 'package:gestion_locative/config/constants.dart';
import 'package:gestion_locative/data/models/maison.dart';
import 'package:gestion_locative/data/repositories/maison_repository.dart';

class MaisonFormScreen extends StatefulWidget {
  final Maison? maison; // Si null, c'est un ajout, sinon c'est une modification

  const MaisonFormScreen({Key? key, this.maison}) : super(key: key);

  @override
  State<MaisonFormScreen> createState() => _MaisonFormScreenState();
}

class _MaisonFormScreenState extends State<MaisonFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final MaisonRepository _maisonRepository = MaisonRepository();

  final _nomController = TextEditingController();
  final _adresseController = TextEditingController();
  final _prixParDefautController = TextEditingController();

  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.maison != null;

    if (_isEditing) {
      // Remplir les champs avec les valeurs existantes
      _nomController.text = widget.maison!.nom;
      _adresseController.text = widget.maison!.adresse;
      _prixParDefautController.text = widget.maison!.prixParDefaut.toString();
    } else {
      // Valeur par défaut pour un nouveau bien
      _prixParDefautController.text = '25000';
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _adresseController.dispose();
    _prixParDefautController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier la maison' : 'Ajouter une maison'),
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

            // Champ Nom
            TextFormField(
              controller: _nomController,
              decoration: const InputDecoration(
                labelText: 'Nom de la maison*',
                hintText: 'Ex: Villa Harmonie, Résidence Les Pins...',
                prefixIcon: Icon(Icons.home),
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

            // Champ Adresse
            TextFormField(
              controller: _adresseController,
              decoration: const InputDecoration(
                labelText: 'Adresse*',
                hintText: 'Ex: 123 Rue Principale, Ville',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'L\'adresse est obligatoire';
                }
                return null;
              },
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Champ Prix par défaut
            TextFormField(
              controller: _prixParDefautController,
              decoration: const InputDecoration(
                labelText: 'Prix par défaut (FCFA)*',
                hintText: 'Ex: 25000',
                prefixIcon: Icon(Icons.monetization_on),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le prix par défaut est obligatoire';
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
                              ? 'Enregistrer les modifications'
                              : 'Ajouter la maison',
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
                _isEditing ? Icons.edit : Icons.add_home,
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
                          : 'Nouvelle maison',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isEditing
                          ? 'Modifiez les informations de votre maison'
                          : 'Ajoutez une nouvelle maison à votre portfolio',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_isEditing) ...[
          const SizedBox(height: 12),
          Text(
            'Date de création: ${widget.maison!.dateCreation.day}/${widget.maison!.dateCreation.month}/${widget.maison!.dateCreation.year}',
            style: TextStyle(
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final nom = _nomController.text.trim();
        final adresse = _adresseController.text.trim();
        final prixParDefaut = double.parse(
          _prixParDefautController.text.trim(),
        );

        if (_isEditing) {
          // Mettre à jour une maison existante
          final updatedMaison = Maison(
            id: widget.maison!.id,
            nom: nom,
            adresse: adresse,
            dateCreation: widget.maison!.dateCreation,
            prixParDefaut: prixParDefaut,
          );

          await _maisonRepository.updateMaison(updatedMaison);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Maison mise à jour avec succès'),
                backgroundColor: AppColors.success,
              ),
            );
            Navigator.pop(context, true);
          }
        } else {
          // Créer une nouvelle maison
          final newMaison = Maison(
            nom: nom,
            adresse: adresse,
            prixParDefaut: prixParDefaut,
          );

          await _maisonRepository.insertMaison(newMaison);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Maison ajoutée avec succès'),
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

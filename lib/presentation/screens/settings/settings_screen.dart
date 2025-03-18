import 'package:flutter/material.dart';
import 'package:gestion_locative/config/constants.dart';
import 'package:gestion_locative/presentation/widgets/common/custom_drawer.dart';
import 'package:gestion_locative/data/database/database_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  String _currency = 'FCFA';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
            tooltip: 'Sauvegarder',
          ),
        ],
      ),
      drawer: const CustomDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Général'),
          _buildSettingSwitch(
            'Mode sombre',
            'Activer le thème sombre',
            Icons.dark_mode,
            _darkModeEnabled,
            (value) {
              setState(() {
                _darkModeEnabled = value;
              });
            },
          ),
          const Divider(),
          _buildSettingSwitch(
            'Notifications',
            'Recevoir des alertes pour les paiements en retard',
            Icons.notifications,
            _notificationsEnabled,
            (value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
          ),
          const Divider(),
          _buildSettingDropdown(
            'Devise',
            'Choisir la devise utilisée dans l\'application',
            Icons.currency_exchange,
            _currency,
            ['FCFA', 'EUR', 'USD', 'XAF'],
            (value) {
              if (value != null) {
                setState(() {
                  _currency = value;
                });
              }
            },
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Données'),
          _buildActionTile(
            'Sauvegarde',
            'Sauvegarder vos données sur le cloud',
            Icons.backup,
            () {
              _showNotImplementedDialog('Sauvegarde');
            },
          ),
          const Divider(),
          _buildActionTile(
            'Restauration',
            'Restaurer vos données depuis le cloud',
            Icons.restore,
            () {
              _showNotImplementedDialog('Restauration');
            },
          ),
          const Divider(),
          _buildActionTile(
            'Effacer les données',
            'Supprimer toutes les données de l\'application',
            Icons.delete_forever,
            () {
              _showClearDataConfirmation();
            },
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  void _saveSettings() {
    // Simule la sauvegarde des paramètres
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Paramètres sauvegardés'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildSettingSwitch(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
    );
  }

  Widget _buildSettingDropdown(
    String title,
    String subtitle,
    IconData icon,
    String value,
    List<String> options,
    Function(String?) onChanged,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: DropdownButton<String>(
        value: value,
        items: options.map((option) {
          return DropdownMenuItem<String>(
            value: option,
            child: Text(option),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildActionTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? AppColors.danger : AppColors.primary,
      ),
      title: Text(
        title,
        style: TextStyle(color: isDestructive ? AppColors.danger : null),
      ),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }

  void _showNotImplementedDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$feature non disponible'),
        content: Text(
          'La fonctionnalité "$feature" n\'est pas encore implémentée.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showClearDataConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Effacer les données ?'),
        content: const Text(
          'Cette action supprimera définitivement toutes vos données. Cette action ne peut pas être annulée.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();

              // 🔴 Supprime toutes les données SQLite
              await DatabaseHelper.instance.clearDatabase();

              // 🔴 Affiche un message de confirmation
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Toutes les données ont été supprimées.'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

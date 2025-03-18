import 'package:flutter/material.dart';
import 'package:gestion_locative/config/constants.dart';
import 'package:gestion_locative/config/routes.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.home_work,
                    size: 30,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Gestion Locative',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Simplifiez votre gestion',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.dashboard,
            title: 'Tableau de bord',
            route: AppRoutes.dashboard,
          ),
          _buildDrawerItem(
            context,
            icon: Icons.home,
            title: 'Maisons',
            route: AppRoutes.maisons,
          ),
          _buildDrawerItem(
            context,
            icon: Icons.bedroom_parent,
            title: 'Chambres',
            route: AppRoutes.chambres,
          ),
          _buildDrawerItem(
            context,
            icon: Icons.people,
            title: 'Locataires',
            route: AppRoutes.locataires,
          ),
          _buildMenuItem(
            context,
            title: 'Paiements',
            icon: Icons.payment,
            route: AppRoutes.paiements,
          ),
          _buildMenuItem(
            context,
            title: 'Génération de paiements',
            icon: Icons.repeat,
            route: AppRoutes.paiementsGeneration,
          ),
          const Divider(),
          _buildMenuItem(
            context,
            title: 'Analytiques',
            icon: Icons.analytics,
            route: AppRoutes.analytics,
          ),
          _buildDrawerItem(
            context,
            icon: Icons.settings,
            title: 'Paramètres',
            route: AppRoutes.settings,
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
  }) {
    final bool isSelected = ModalRoute.of(context)?.settings.name == route;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Theme.of(context).primaryColor : null,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Theme.of(context).primaryColor : null,
          fontWeight: isSelected ? FontWeight.bold : null,
        ),
      ),
      selected: isSelected,
      onTap: () {
        if (!isSelected) {
          Navigator.pop(context); // Ferme le drawer
          Navigator.pushReplacementNamed(context, route);
        }
      },
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String route,
  }) {
    final bool isSelected = ModalRoute.of(context)?.settings.name == route;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Theme.of(context).primaryColor : null,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Theme.of(context).primaryColor : null,
          fontWeight: isSelected ? FontWeight.bold : null,
        ),
      ),
      selected: isSelected,
      onTap: () {
        if (!isSelected) {
          Navigator.pop(context); // Ferme le drawer
          Navigator.pushReplacementNamed(context, route);
        }
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:gestion_locative/config/routes.dart';

void main() async {
  // Cette ligne est CRUCIALE - elle s'assure que Flutter est initialisé
  WidgetsFlutterBinding.ensureInitialized();

  // Ajoutez un délai pour s'assurer que SQFlite a le temps de s'initialiser
  await Future.delayed(const Duration(milliseconds: 500));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestion Locative',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      initialRoute: AppRoutes.dashboard,
      onGenerateRoute: (settings) {
        // On vérifie d'abord si la route est définie dans notre table AppRoutes.routes
        if (AppRoutes.routes.containsKey(settings.name)) {
          return MaterialPageRoute(
            builder: (context) => AppRoutes.routes[settings.name]!(context),
          );
        }

        // Gérer les routes inconnues ou non enregistrées
        return null;
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'accueil/accueil_screen.dart';
import 'vehicules/vehicules_screen.dart';
import 'di/di_screen.dart';
import 'maintenance/maintenance_screen.dart';
import 'inspections/inspections_screen.dart';

/// Coquille de l'application : 5 onglets, chacun garde son état.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  void _ouvrir(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    // Barre d'état : texte clair sur l'en-tête violet de l'accueil, foncé ailleurs
    final style = _index == 0 ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: style.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: [
            AccueilScreen(ouvrirOnglet: _ouvrir),
            const SafeArea(bottom: false, child: VehiculesScreen()),
            const SafeArea(bottom: false, child: DiScreen()),
            const SafeArea(bottom: false, child: MaintenanceScreen()),
            const SafeArea(bottom: false, child: InspectionsScreen()),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _ouvrir,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Accueil',
            ),
            NavigationDestination(
              icon: Icon(Icons.directions_car_outlined),
              selectedIcon: Icon(Icons.directions_car_rounded),
              label: 'Véhicules',
            ),
            NavigationDestination(
              icon: Icon(Icons.campaign_outlined),
              selectedIcon: Icon(Icons.campaign_rounded),
              label: 'Signalements',
            ),
            NavigationDestination(
              icon: Icon(Icons.event_repeat_outlined),
              selectedIcon: Icon(Icons.event_repeat_rounded),
              label: 'Entretien',
            ),
            NavigationDestination(
              icon: Icon(Icons.fact_check_outlined),
              selectedIcon: Icon(Icons.fact_check_rounded),
              label: 'Inspections',
            ),
          ],
        ),
      ),
    );
  }
}

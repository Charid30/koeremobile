import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/services/auth_provider.dart';
import '../core/constants/app_theme.dart';
import 'vehicules/vehicules_screen.dart';
import 'di/di_screen.dart';
import 'maintenance/maintenance_screen.dart';
import 'inspections/inspections_screen.dart';
import 'profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  final _screens = const [
    VehiculesScreen(),
    DiScreen(),
    MaintenanceScreen(),
    InspectionsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SOFARY'),
        actions: [
          if (user != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: PopupMenuButton<String>(
                offset: const Offset(0, 40),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.primaryLight,
                  child: Text(
                    (user['prenom'] as String? ?? 'U').substring(0, 1).toUpperCase(),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primary),
                  ),
                ),
                onSelected: (v) async {
                  if (v == 'logout') {
                    final nav = Navigator.of(context);
                    await auth.logout();
                    nav.pushReplacementNamed('/login');
                  } else if (v == 'profil') {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    enabled: false,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${user['prenom']} ${user['nom']}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      Text(user['email'] ?? '', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    ]),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'profil',
                    child: Row(children: [
                      Icon(Icons.person_outline, size: 18, color: AppTheme.textSecondary),
                      SizedBox(width: 10),
                      Text('Mon profil'),
                    ]),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(value: 'logout', child: Text('Déconnexion', style: TextStyle(color: AppTheme.danger))),
                ],
              ),
            ),
        ],
      ),
      body: _screens[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.directions_car_outlined), selectedIcon: Icon(Icons.directions_car), label: 'Véhicules'),
          NavigationDestination(icon: Icon(Icons.build_circle_outlined), selectedIcon: Icon(Icons.build_circle), label: 'Interventions'),
          NavigationDestination(icon: Icon(Icons.engineering_outlined), selectedIcon: Icon(Icons.engineering), label: 'Maintenance'),
          NavigationDestination(icon: Icon(Icons.checklist_outlined), selectedIcon: Icon(Icons.checklist), label: 'Inspections'),
        ],
      ),
    );
  }
}

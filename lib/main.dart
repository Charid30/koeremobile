import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_theme.dart';
import 'core/services/auth_provider.dart';
import 'core/utils/navigator_key.dart';
import 'features/auth/login_screen.dart';
import 'features/home_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider()..checkAuth(),
      child: const KoereApp(),
    ),
  );
}

class KoereApp extends StatelessWidget {
  const KoereApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SOFARY',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      navigatorKey: navigatorKey,
      initialRoute: '/splash',
      routes: {
        '/splash': (_) => const _SplashScreen(),
        '/login':  (_) => const LoginScreen(),
        '/home':   (_) => const HomeScreen(),
      },
    );
  }
}

class _SplashScreen extends StatefulWidget {
  const _SplashScreen();

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    await auth.checkAuth();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(auth.isLoggedIn ? '/home' : '/login');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Image(image: AssetImage('assets/images/logo.png'), width: 140, height: 140),
          SizedBox(height: 24),
          CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
        ]),
      ),
    );
  }
}

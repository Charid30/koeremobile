import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../utils/error_handler.dart';

/// Vue d'erreur plein écran avec bouton "Réessayer".
class ErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  final String? title;

  const ErrorView({super.key, required this.error, required this.onRetry, this.title});

  @override
  Widget build(BuildContext context) {
    final appErr = parseError(error);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: appErr.isNetwork ? const Color(0xFFFFF7ED) : const Color(0xFFFEF2F2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              appErr.isNetwork ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
              color: appErr.isNetwork ? AppTheme.warning : AppTheme.danger,
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title ?? (appErr.isNetwork ? 'Pas de connexion' : 'Une erreur est survenue'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            appErr.message,
            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 44,
            child: ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 24),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Affiche un SnackBar d'erreur standardisé.
void showErrorSnack(BuildContext context, Object error) {
  if (!context.mounted) return;
  final appErr = error is AppError ? error : parseError(error);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_outline, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(appErr.message, style: const TextStyle(fontSize: 13))),
      ]),
      backgroundColor: AppTheme.danger,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 4),
    ));
}

/// Affiche un SnackBar de succès standardisé.
void showSuccessSnack(BuildContext context, String message) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(message, style: const TextStyle(fontSize: 13))),
      ]),
      backgroundColor: AppTheme.success,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 3),
    ));
}

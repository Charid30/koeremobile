/// Droits d'action, calqués sur les règles @Roles de l'API (et sur
/// koerefrontend/src/core/auth/permissions.ts). L'appli s'en sert pour
/// n'afficher que les boutons que le serveur acceptera.
const _permissions = <String, List<String>>{
  'vehicule.creer': ['ADMIN', 'RESPONSABLE_PARC'],
  'vehicule.modifier': ['ADMIN', 'RESPONSABLE_PARC'],
  'vehicule.supprimer': ['ADMIN'],
  'inspection.creer': ['ADMIN', 'RESPONSABLE_MAINTENANCE', 'MECANICIEN', 'CHAUFFEUR'],
  'inspection.modifier': ['ADMIN', 'RESPONSABLE_MAINTENANCE'],
  'inspection.supprimer': ['ADMIN', 'RESPONSABLE_MAINTENANCE'],
  'di.creer': ['ADMIN', 'RESPONSABLE_PARC', 'RESPONSABLE_MAINTENANCE', 'MECANICIEN', 'CHAUFFEUR'],
  'di.traiter': ['ADMIN', 'RESPONSABLE_PARC', 'RESPONSABLE_MAINTENANCE'],
  'di.supprimer': ['ADMIN', 'RESPONSABLE_PARC'],
  'maintenance.creer': ['ADMIN', 'RESPONSABLE_MAINTENANCE', 'RESPONSABLE_PARC'],
  'maintenance.executer': ['ADMIN', 'RESPONSABLE_MAINTENANCE', 'MECANICIEN'],
};

bool autorise(String? role, String action) => role != null && (_permissions[action]?.contains(role) ?? false);

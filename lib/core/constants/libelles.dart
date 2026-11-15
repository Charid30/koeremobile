import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Ton d'un statut : décide des couleurs de la pastille.
enum Ton { neutre, info, succes, attention, danger, marque }

/// Libellé + ton d'une valeur d'énumération de l'API.
class Libelle {
  final String texte;
  final Ton ton;
  final IconData? icone;
  const Libelle(this.texte, this.ton, [this.icone]);
}

Libelle _trouver(Map<String, Libelle> table, String? code) => table[code] ?? Libelle(code ?? '—', Ton.neutre);

/// Couleurs (fond, texte) associées à un ton.
(Color, Color) couleursTon(Ton ton) => switch (ton) {
  Ton.succes => (const Color(0xFFDCFCE7), const Color(0xFF15803D)),
  Ton.attention => (const Color(0xFFFFF4E5), const Color(0xFFB45309)),
  Ton.danger => (const Color(0xFFFEE2E2), const Color(0xFFB91C1C)),
  Ton.info => (const Color(0xFFE0F2FE), const Color(0xFF0369A1)),
  Ton.marque => (AppTheme.primaryLight, AppTheme.primary),
  Ton.neutre => (const Color(0xFFF1F0F5), AppTheme.textSecondary),
};

// ── Véhicules ─────────────────────────────────────────────────────────────
const vehiculeStatuts = <String, Libelle>{
  'DISPONIBLE': Libelle('Disponible', Ton.succes, Icons.check_circle_rounded),
  'EN_CIRCULATION': Libelle('En circulation', Ton.info, Icons.route_rounded),
  'EN_MAINTENANCE': Libelle('En maintenance', Ton.attention, Icons.build_rounded),
  'EN_ATTENTE_REPARATION_EXTERNE': Libelle('Réparation externe', Ton.attention, Icons.store_rounded),
  'EN_ATTENTE_PIECES': Libelle('Attente pièces', Ton.attention, Icons.inventory_2_rounded),
  'IMMOBILISE': Libelle('Immobilisé', Ton.danger, Icons.block_rounded),
  'ACCIDENTE': Libelle('Accidenté', Ton.danger, Icons.car_crash_rounded),
  'HORS_SERVICE': Libelle('Hors service', Ton.neutre, Icons.do_not_disturb_on_rounded),
};
Libelle vehiculeStatut(String? s) => _trouver(vehiculeStatuts, s);

const vehiculeTypes = <String, Libelle>{
  'VOITURE': Libelle('Voiture', Ton.neutre, Icons.directions_car_rounded),
  'CAMION': Libelle('Camion', Ton.neutre, Icons.local_shipping_rounded),
  'EQUIPEMENT_SPECIAL': Libelle('Équipement spécial', Ton.neutre, Icons.precision_manufacturing_rounded),
  'ENGIN_TP': Libelle('Engin TP', Ton.neutre, Icons.agriculture_rounded),
};
Libelle vehiculeType(String? t) => vehiculeTypes[t] ?? Libelle(t ?? '—', Ton.neutre, Icons.directions_car_rounded);

/// Engins et équipements se suivent en heures moteur, les autres en km.
bool compteHeures(String? type) => type == 'ENGIN_TP' || type == 'EQUIPEMENT_SPECIAL';

const carburants = <String, String>{
  'ESSENCE': 'Essence',
  'DIESEL': 'Diesel',
  'ELECTRIQUE': 'Électrique',
  'HYBRIDE': 'Hybride',
  'GPL': 'GPL',
};

// ── Signalements (demandes d'intervention) ───────────────────────────────
const diStatuts = <String, Libelle>{
  'EN_ATTENTE': Libelle('En attente', Ton.attention, Icons.schedule_rounded),
  'PRISE_EN_CHARGE': Libelle('Prise en charge', Ton.info, Icons.handyman_rounded),
  'TRAITEE': Libelle('Traitée', Ton.succes, Icons.check_circle_rounded),
  'REJETEE': Libelle('Rejetée', Ton.neutre, Icons.cancel_rounded),
};
Libelle diStatut(String? s) => _trouver(diStatuts, s);

const priorites = <String, Libelle>{
  'FAIBLE': Libelle('Faible', Ton.neutre, Icons.keyboard_arrow_down_rounded),
  'NORMALE': Libelle('Normale', Ton.marque, Icons.remove_rounded),
  'URGENTE': Libelle('Urgente', Ton.attention, Icons.keyboard_arrow_up_rounded),
  'CRITIQUE': Libelle('Critique', Ton.danger, Icons.priority_high_rounded),
};
Libelle priorite(String? p) => _trouver(priorites, p);

// ── Inspections ──────────────────────────────────────────────────────────
const inspectionStatuts = <String, Libelle>{
  'CONFORME': Libelle('Conforme', Ton.succes, Icons.verified_rounded),
  'PARTIEL': Libelle('Partiel', Ton.attention, Icons.rule_rounded),
  'NON_CONFORME': Libelle('Non conforme', Ton.danger, Icons.report_rounded),
};
Libelle inspectionStatut(String? s) => _trouver(inspectionStatuts, s);

const inspectionTypes = <String, String>{
  'PRE_DEPART': 'Pré-départ',
  'PERIODIQUE': 'Périodique',
  'RETOUR_MISSION': 'Retour de mission',
  'TECHNIQUE': 'Technique',
};
String inspectionType(String? t) => inspectionTypes[t] ?? (t ?? '—');

// ── Ordres de travail ────────────────────────────────────────────────────
const otStatuts = <String, Libelle>{
  'EN_ATTENTE_VALIDATION': Libelle('À valider', Ton.attention),
  'PLANIFIE': Libelle('Planifié', Ton.info),
  'EN_COURS': Libelle('En cours', Ton.marque),
  'EN_ATTENTE_PIECES': Libelle('Attente pièces', Ton.attention),
  'EN_ATTENTE_PRESTATAIRE': Libelle('Attente prestataire', Ton.attention),
  'TERMINE': Libelle('Terminé', Ton.succes),
  'CONTROLE': Libelle('Contrôlé', Ton.succes),
  'CLOTURE': Libelle('Clôturé', Ton.neutre),
  'ANNULE': Libelle('Annulé', Ton.neutre),
};
Libelle otStatut(String? s) => _trouver(otStatuts, s);

// ── Rôles ────────────────────────────────────────────────────────────────
const roles = <String, String>{
  'ADMIN': 'Administrateur',
  'RESPONSABLE_PARC': 'Responsable parc',
  'RESPONSABLE_MAINTENANCE': 'Responsable maintenance',
  'MECANICIEN': 'Mécanicien',
  'CHAUFFEUR': 'Chauffeur',
  'DIRECTION': 'Direction',
};
String role(String? r) => roles[r] ?? (r ?? '');

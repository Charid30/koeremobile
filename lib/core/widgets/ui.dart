import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../constants/libelles.dart';
import '../utils/format.dart';

/// Kit d'interface partagé par tous les écrans : un seul endroit pour
/// l'apparence des pastilles, cartes, listes vides, chargements, etc.

// ── Pastille de statut ───────────────────────────────────────────────────
class Pastille extends StatelessWidget {
  final Libelle libelle;
  final bool icone;
  final bool grande;
  const Pastille(this.libelle, {super.key, this.icone = false, this.grande = false});

  @override
  Widget build(BuildContext context) {
    final (fond, texte) = couleursTon(libelle.ton);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: grande ? 10 : 8, vertical: grande ? 5 : 3),
      decoration: BoxDecoration(color: fond, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icone && libelle.icone != null) ...[
            Icon(libelle.icone, size: grande ? 14 : 12, color: texte),
            const SizedBox(width: 4),
          ] else ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: texte, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            libelle.texte,
            style: TextStyle(fontSize: grande ? 12.5 : 11.5, fontWeight: FontWeight.w600, color: texte, height: 1.2),
          ),
        ],
      ),
    );
  }
}

// ── Pastille d'icône colorée (carré arrondi) ─────────────────────────────
class IconeTon extends StatelessWidget {
  final IconData icone;
  final Ton ton;
  final double taille;
  const IconeTon(this.icone, {super.key, this.ton = Ton.marque, this.taille = 44});

  @override
  Widget build(BuildContext context) {
    final (fond, texte) = couleursTon(ton);
    return Container(
      width: taille,
      height: taille,
      decoration: BoxDecoration(color: fond, borderRadius: BorderRadius.circular(taille * 0.3)),
      child: Icon(icone, color: texte, size: taille * 0.5),
    );
  }
}

// ── Carte (cliquable si onTap) ───────────────────────────────────────────
class Carte extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? bordureGauche;
  const Carte({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(14),
    this.bordureGauche,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: bordureGauche == null
              ? Padding(padding: padding, child: child)
              : IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(width: 4, color: bordureGauche),
                      Expanded(
                        child: Padding(padding: padding, child: child),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

// ── Titre de section ─────────────────────────────────────────────────────
class TitreSection extends StatelessWidget {
  final String titre;
  final String? action;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;
  const TitreSection(
    this.titre, {
    super.key,
    this.action,
    this.onAction,
    this.padding = const EdgeInsets.fromLTRB(4, 20, 4, 10),
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: padding,
    child: Row(
      children: [
        Expanded(
          child: Text(
            titre,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
          ),
        ),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              action!,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primary),
            ),
          ),
      ],
    ),
  );
}

// ── Groupe de lignes « libellé : valeur » ────────────────────────────────
class LigneInfo {
  final IconData icone;
  final String libelle;
  final String? valeur;
  final Widget? fin;
  const LigneInfo(this.icone, this.libelle, this.valeur, {this.fin});
}

class GroupeInfos extends StatelessWidget {
  final String? titre;
  final List<LigneInfo> lignes;
  const GroupeInfos({super.key, this.titre, required this.lignes});

  @override
  Widget build(BuildContext context) {
    final visibles = lignes.where((l) => (l.valeur != null && l.valeur!.trim().isNotEmpty) || l.fin != null).toList();
    if (visibles.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (titre != null) TitreSection(titre!),
        Carte(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < visibles.length; i++) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Icon(visibles[i].icone, size: 18, color: AppTheme.textSecondary),
                      const SizedBox(width: 12),
                      Text(visibles[i].libelle, style: const TextStyle(fontSize: 13.5, color: AppTheme.textSecondary)),
                      const SizedBox(width: 12),
                      Expanded(
                        child:
                            visibles[i].fin ??
                            Text(
                              visibles[i].valeur!,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                      ),
                    ],
                  ),
                ),
                if (i < visibles.length - 1) const Divider(height: 1, indent: 44),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ── Tuile chiffre clé ────────────────────────────────────────────────────
class TuileChiffre extends StatelessWidget {
  final String valeur;
  final String libelle;
  final IconData icone;
  final Ton ton;
  final VoidCallback? onTap;
  const TuileChiffre({
    super.key,
    required this.valeur,
    required this.libelle,
    required this.icone,
    this.ton = Ton.marque,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final (_, couleur) = couleursTon(ton);
    return Carte(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconeTon(icone, ton: ton, taille: 34),
          const SizedBox(height: 12),
          Text(
            valeur,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: couleur, height: 1),
          ),
          const SizedBox(height: 4),
          Text(
            libelle,
            maxLines: 2,
            style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondary, height: 1.25),
          ),
        ],
      ),
    );
  }
}

// ── Barre de recherche ───────────────────────────────────────────────────
class ChampRecherche extends StatelessWidget {
  final String indice;
  final ValueChanged<String> onChanged;
  const ChampRecherche({super.key, required this.indice, required this.onChanged});

  @override
  Widget build(BuildContext context) => TextField(
    onChanged: onChanged,
    textInputAction: TextInputAction.search,
    decoration: InputDecoration(
      hintText: indice,
      prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary),
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
      isDense: true,
    ),
  );
}

// ── Filtres en puces défilantes ──────────────────────────────────────────
class Filtre {
  final String? valeur;
  final String libelle;
  final int? nombre;
  const Filtre(this.valeur, this.libelle, [this.nombre]);
}

class BarreFiltres extends StatelessWidget {
  final List<Filtre> filtres;
  final String? actif;
  final ValueChanged<String?> onChanged;
  const BarreFiltres({super.key, required this.filtres, required this.actif, required this.onChanged});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 36,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filtres.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (_, i) {
        final f = filtres[i];
        final selection = f.valeur == actif;
        return GestureDetector(
          onTap: () => onChanged(f.valeur),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selection ? AppTheme.brand : Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: selection ? AppTheme.brand : AppTheme.border),
            ),
            child: Text(
              f.nombre != null ? '${f.libelle}  ${f.nombre}' : f.libelle,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selection ? Colors.white : AppTheme.textPrimary,
              ),
            ),
          ),
        );
      },
    ),
  );
}

// ── État vide ────────────────────────────────────────────────────────────
class EtatVide extends StatelessWidget {
  final IconData icone;
  final String titre;
  final String? message;
  final String? action;
  final VoidCallback? onAction;
  const EtatVide({super.key, required this.icone, required this.titre, this.message, this.action, this.onAction});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(color: AppTheme.primaryLight, shape: BoxShape.circle),
          child: Icon(icone, size: 34, color: AppTheme.primary),
        ),
        const SizedBox(height: 16),
        Text(
          titre,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
        ),
        if (message != null) ...[
          const SizedBox(height: 6),
          Text(
            message!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13.5, color: AppTheme.textSecondary, height: 1.5),
          ),
        ],
        if (action != null) ...[
          const SizedBox(height: 18),
          FilledButton.tonal(
            onPressed: onAction,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryLight,
              foregroundColor: AppTheme.primary,
              minimumSize: const Size(0, 42),
            ),
            child: Text(action!),
          ),
        ],
      ],
    ),
  );
}

/// Liste défilante qui accepte le « tirer pour actualiser » même vide.
class ListeVide extends StatelessWidget {
  final Widget child;
  const ListeVide({super.key, required this.child});

  @override
  Widget build(BuildContext context) => ListView(physics: const AlwaysScrollableScrollPhysics(), children: [child]);
}

// ── Squelette de chargement ──────────────────────────────────────────────
class ChargementListe extends StatefulWidget {
  final int lignes;
  const ChargementListe({super.key, this.lignes = 6});

  @override
  State<ChargementListe> createState() => _ChargementListeState();
}

class _ChargementListeState extends State<ChargementListe> with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Widget _bloc(double l, double h) => Container(
    width: l,
    height: h,
    decoration: BoxDecoration(color: const Color(0xFFE9E6F0), borderRadius: BorderRadius.circular(6)),
  );

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: Tween(begin: 0.45, end: 1.0).animate(_anim),
    child: ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: widget.lignes,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, _) => Carte(
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: const Color(0xFFE9E6F0), borderRadius: BorderRadius.circular(13)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [_bloc(120, 12), const SizedBox(height: 8), _bloc(180, 10)],
              ),
            ),
            _bloc(60, 18),
          ],
        ),
      ),
    ),
  );
}

// ── Avatar à initiales ───────────────────────────────────────────────────
class Avatar extends StatelessWidget {
  final String? prenom;
  final String? nom;
  final double taille;
  final bool clair;
  const Avatar({super.key, this.prenom, this.nom, this.taille = 36, this.clair = false});

  @override
  Widget build(BuildContext context) => Container(
    width: taille,
    height: taille,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: clair ? Colors.white.withValues(alpha: 0.18) : AppTheme.primaryLight,
      border: clair ? Border.all(color: Colors.white.withValues(alpha: 0.35)) : null,
    ),
    child: Text(
      initiales(prenom, nom),
      style: TextStyle(
        fontSize: taille * 0.38,
        fontWeight: FontWeight.w700,
        color: clair ? Colors.white : AppTheme.primary,
      ),
    ),
  );
}

// ── En-tête de page (titre + sous-titre) pour les onglets ────────────────
class EnTeteOnglet extends StatelessWidget {
  final String titre;
  final String? sousTitre;
  final Widget? action;
  const EnTeteOnglet({super.key, required this.titre, this.sousTitre, this.action});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titre,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              if (sousTitre != null) ...[
                const SizedBox(height: 2),
                Text(sousTitre!, style: const TextStyle(fontSize: 13.5, color: AppTheme.textSecondary)),
              ],
            ],
          ),
        ),
        if (action != null) action!,
      ],
    ),
  );
}

// ── Bouton d'action rapide (icône + libellé) ─────────────────────────────
class ActionRapide extends StatelessWidget {
  final IconData icone;
  final String libelle;
  final Ton ton;
  final VoidCallback onTap;
  const ActionRapide({
    super.key,
    required this.icone,
    required this.libelle,
    required this.onTap,
    this.ton = Ton.marque,
  });

  @override
  Widget build(BuildContext context) => Carte(
    onTap: onTap,
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
    child: Column(
      children: [
        IconeTon(icone, ton: ton, taille: 40),
        const SizedBox(height: 8),
        Text(
          libelle,
          textAlign: TextAlign.center,
          maxLines: 2,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary, height: 1.2),
        ),
      ],
    ),
  );
}

// ── Rangée de boutons de même largeur, espacés ───────────────────────────
class RangeeEgale extends StatelessWidget {
  final List<Widget> enfants;
  final double espace;
  const RangeeEgale({super.key, required this.enfants, this.espace = 10});

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (var i = 0; i < enfants.length; i++) ...[if (i > 0) SizedBox(width: espace), Expanded(child: enfants[i])],
    ],
  );
}

// ── Choix de priorité (4 boutons colorés) ────────────────────────────────
class ChoixPriorite extends StatelessWidget {
  final String valeur;
  final ValueChanged<String> onChanged;
  const ChoixPriorite({super.key, required this.valeur, required this.onChanged});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (final e in priorites.entries) ...[
        if (e.key != priorites.keys.first) const SizedBox(width: 8),
        Expanded(
          child: Builder(
            builder: (_) {
              final choisi = e.key == valeur;
              final (fond, texte) = couleursTon(e.value.ton);
              return GestureDetector(
                onTap: () => onChanged(e.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: choisi ? fond : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: choisi ? texte : AppTheme.border, width: choisi ? 1.5 : 1),
                  ),
                  child: Column(
                    children: [
                      Icon(e.value.icone, size: 18, color: choisi ? texte : AppTheme.textSecondary),
                      const SizedBox(height: 2),
                      Text(
                        e.value.texte,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: choisi ? texte : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ],
  );
}

import 'package:flutter_test/flutter_test.dart';
import 'package:koere_mobile/core/constants/libelles.dart';
import 'package:koere_mobile/core/constants/permissions.dart';
import 'package:koere_mobile/core/utils/format.dart';

void main() {
  group('format', () {
    test('nombre avec séparateur de milliers', () {
      expect(nombre(125400), '125 400');
      expect(nombre(0), '0');
      expect(nombre(null), '—');
      expect(nombre('abc'), '—');
    });

    test('initiales', () {
      expect(initiales('Kevin', 'Bationo'), 'KB');
      expect(initiales('awa', null), 'A');
      expect(initiales(null, null), '?');
    });

    test('date courte', () {
      expect(dateCourte('2026-03-05T10:00:00'), '05/03/2026');
      expect(dateCourte(null), '—');
    });
  });

  group('libellés', () {
    test('statuts connus et inconnus', () {
      expect(diStatut('TRAITEE').texte, 'Traitée');
      expect(inspectionStatut('NON_CONFORME').ton, Ton.danger);
      expect(vehiculeStatut('INCONNU').texte, 'INCONNU');
      expect(compteHeures('ENGIN_TP'), isTrue);
      expect(compteHeures('VOITURE'), isFalse);
    });
  });

  group('permissions', () {
    test('suivent les règles de l’API', () {
      expect(autorise('CHAUFFEUR', 'di.creer'), isTrue);
      expect(autorise('CHAUFFEUR', 'di.traiter'), isFalse);
      expect(autorise('ADMIN', 'vehicule.supprimer'), isTrue);
      expect(autorise(null, 'di.creer'), isFalse);
    });
  });
}

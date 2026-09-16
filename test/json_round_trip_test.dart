import 'package:amt/models/armour.dart';
import 'package:amt/models/enums.dart';
import 'package:amt/models/weapon.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Un arma de parada sigue siendo de parada al copiarse por JSON', () {
    final weapon = Weapon(
      name: 'Espada',
      turn: 0,
      attack: 100,
      defense: 210,
      defenseType: DefenseType.parry,
      damage: 50,
      size: WeaponSize.big,
      known: KnownType.unknown,
    );

    final copy = Weapon.fromJson(weapon.toJson())!;

    expect(copy.defenseType, DefenseType.parry);
    expect(copy.size, WeaponSize.big);
    expect(copy.known, KnownType.unknown);
  });

  test('La planilla sigue leyéndose igual', () {
    final weapon = Weapon.fromJson({'nombre': 'Arma', 'defensaTipo': 'Esq', 'tamanio': 'Enorme', 'conocimiento': 'Distinta'})!;

    expect(weapon.defenseType, DefenseType.dodge);
    expect(weapon.size, WeaponSize.big);
    expect(weapon.known, KnownType.unknown);
  });

  test('La ubicación de la armadura sobrevive al JSON', () {
    for (final location in ArmourLocation.values) {
      expect(Armour.fromJson(Armour(location: location).toJson())!.location, location);
    }
    expect(Armour.fromJson({'Localizacion': 'Peto'})!.location, ArmourLocation.breastplate);
  });
}

import 'dart:math';

import 'package:amt/models/models.dart';
import 'package:uuid/uuid.dart';

/// Reglas de Combate de Masas (Los Bestiarios, "Sistemas de combate
/// alternativos").
///
/// Un grupo de enemigos se resuelve como un único adversario con acumulación de
/// daño, con algunas reglas propias: suma la vida de sus miembros, gana un bono
/// de ataque según cuántos son, se defiende con su defensa media sin tirar y es
/// inmune a los críticos.
abstract class MassRules {
  /// Tabla 1: bono a la habilidad de ataque según el número de miembros.
  static int attackBonus(int members) {
    if (members >= 100) return 150;
    if (members >= 50) return 130;
    if (members >= 25) return 110;
    if (members >= 15) return 90;
    if (members >= 10) return 70;
    if (members >= 5) return 50;
    if (members >= 3) return 30;
    return 0;
  }

  /// Tabla 2: multiplicador al daño base de un ataque en área contra una masa,
  /// según cuántos miembros alcanza.
  ///
  /// La tabla solapa sus tramos ("2 a 3" y "3 a 4", "25 a 100" y "100+"); se
  /// resuelve dando a cada borde el tramo inferior. Nunca puede usar más
  /// enemigos de los que tiene la masa.
  static int areaDamageMultiplier({required int targets, required int members}) {
    final reached = min<int>(targets, members);

    if (reached >= 1000) return 25;
    if (reached > 100) return 15;
    if (reached >= 25) return 10;
    if (reached >= 10) return 5;
    if (reached >= 5) return 4;
    if (reached >= 4) return 3;
    if (reached >= 2) return 2;
    return 1;
  }

  /// Puntos de vida del conjunto, para [members] miembros iguales.
  static int hitPoints({required int memberHitPoints, required int members, required bool damageAccumulation}) {
    if (members <= 1) return memberHitPoints;

    if (!damageAccumulation) {
      // Se suman los PV de cada uno redondeados a la baja en grupos de 50. Pasados
      // los 100 miembros, cada uno extra suma 10, o 25 si tiene 250 PV o más.
      final rounded = (memberHitPoints ~/ 50) * 50;
      final extra = max<int>(0, members - 100);

      return rounded * min<int>(members, 100) + extra * (memberHitPoints < 250 ? 10 : 25);
    }

    // Con acumulación: el primero aporta sus PV redondeados a la baja en grupos
    // de 100 y cada miembro adicional la mitad de eso. Pasados los 50, cada uno
    // extra suma 100, o 250 si tiene 1.000 PV o más.
    final base = (memberHitPoints ~/ 100) * 100;
    final extra = max<int>(0, members - 50);

    return base + (min<int>(members, 50) - 1) * (base ~/ 2) + extra * (memberHitPoints < 1000 ? 100 : 250);
  }

  /// Miembros que siguen en pie según la vida que le queda al conjunto.
  ///
  /// Es una aproximación: reparte la vida máxima en partes iguales, cuando en
  /// una masa con acumulación el primer miembro aporta el doble que el resto.
  static int membersAlive(Character mass) {
    final members = mass.profile.massSize ?? 1;
    final life = mass.state.getConsumable(ConsumableType.hitPoints);

    if (life == null || life.maxValue <= 0 || members <= 0) return members;

    final perMember = life.maxValue / members;

    return (life.actualValue / perMember).ceil().clamp(0, members);
  }

  /// Arma una masa con [members] copias de [member].
  static Character create(Character member, int members) {
    final mass = member.copyWith(uuid: const Uuid().v4());
    final damageAccumulation = member.profile.damageAccumulation ?? false;
    final total = hitPoints(
      memberHitPoints: member.profile.hitPoints,
      members: members,
      damageAccumulation: damageAccumulation,
    );

    mass.profile
      ..name = 'Masa de ${member.profile.name.split('#').first.trim()} ($members)'
      ..massSize = members
      ..hitPoints = total
      // A efectos de juego actúa como una criatura con acumulación de daño.
      ..damageAccumulation = true;

    final life = mass.state.getConsumable(ConsumableType.hitPoints);

    if (life != null && life.name.isNotEmpty) {
      life
        ..maxValue = total
        ..actualValue = total;
    }

    // Las armas se copian antes de tocarlas, para no alterar al original.
    // El daño físico sube un 50 %; el de conjuros y poderes se dobla.
    mass.combat = CombatData(
      armour: mass.combat.armour,
      ambidextrous: mass.combat.ambidextrous,
      styleTables: mass.combat.styleTables,
      martialArts: mass.combat.martialArts,
      weapons: [
        for (final weapon in member.combat.weapons)
          weapon.copy()..damage = _isSupernatural(weapon) ? weapon.damage * 2 : (weapon.damage * 1.5).floor(),
      ],
    );

    return mass;
  }

  static bool _isSupernatural(Weapon weapon) {
    final text = '${weapon.type ?? ''} ${weapon.name}'.toLowerCase();

    return text.contains('mistic') || text.contains('místic') || text.contains('psiquic') || text.contains('psíquic');
  }
}

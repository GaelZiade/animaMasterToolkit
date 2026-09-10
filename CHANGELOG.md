# Changelog

Versión alternativa de [Anima Master Toolkit](https://github.com/aoalejo/animaMasterToolkit)
mantenida en [GaelZiade/animaMasterToolkit](https://github.com/GaelZiade/animaMasterToolkit).

Todos los cambios parten de `9116a97`, el último commit del proyecto original.
Las referencias de reglas son al **Core Exxet** salvo que se indique otra cosa.

## Reglas de combate

### Corregido

- **La defensa final ya no puede quedar negativa.** Los modificadores pueden
  sumar un total negativo, pero el resultado se limita a 0. El desglose muestra
  el valor sin limitar para que se vea por qué. (Cierra
  [#50](https://github.com/aoalejo/animaMasterToolkit/issues/50))
- **Espacio reducido** no coincidía con la Tabla 43: la Parada estaba en 0 en
  vez de −40 y la Acción Física en −40 en vez de −20.
- **Valores de modificadores que no coincidían con los manuales:**
  - Desarmar estaba en −20, el valor con Tabla de Desarme; el Core dice −40.
  - Dolor extremo aplicaba −60 al ataque; es −80 a toda acción. Dolor, Dolor
    extremo y Miedo no afectaban a la iniciativa, que sufre la mitad del
    negativo (Estados y Accidentes).
  - Seraphite no sumaba su bono al ataque (+20, o +30 en grado Arcano).
  - Shephon sumaba +60 por su cuenta, además de la Defensa total; ahora es una
    variante de la Defensa total.
- Erratas en los textos que se muestran en pantalla: «Absorición»,
  «coontraataque», «Critico» sin tilde.

### Añadido

- **Reglas de acumulación de daño que faltaban** (avanza
  [#47](https://github.com/aoalejo/animaMasterToolkit/issues/47)). La aplicación
  ya resolvía la defensa, la absorción con sorpresa, la mitad del nivel de
  crítico y la ausencia de contraataque, pero enunciaba sin aplicar otras dos:
  - **Ataque en área.** Si cubre al menos la mitad del cuerpo de una criatura
    con acumulación, el daño se dobla (p. 99). Se activa con una casilla que
    solo aparece cuando el defensor acumula daño.
  - **Crítico superior a 50.** El ser no puede actuar en ese asalto.
- **Los estados del personaje se ven en el desglose.** La ceguera, el dolor o el
  cansancio ya se aplicaban, pero iban sumados dentro de la habilidad base y no
  había forma de saber que estaban actuando. Ahora son una línea propia.
- **Reserva de Ki unificada** como regla fija (Dominus Exxet, reglas
  opcionales). Un personaje con Ki repartido dejaba cinco o seis consumibles
  (`Ki/AGI`, `Ki/VOL`…) de los que la tabla mostraba uno solo.
- **Masas de enemigos** (cierra
  [#46](https://github.com/aoalejo/animaMasterToolkit/issues/46)), con las
  reglas de Combate de Masas del Bestiario. Desde las opciones de un personaje
  se elige cuántos miembros tiene y se crea un único adversario que:
  - suma la vida de todos con las dos fórmulas del manual, la normal y la de
    criaturas con acumulación;
  - gana el bono de ataque de la Tabla 1 según los miembros que siguen en pie;
  - aumenta un 50 % el daño físico y dobla el de conjuros y poderes;
  - se defiende con su defensa media como Defensa Final, sin tirar y sin
    penalizadores por ataques adicionales;
  - es inmune a los críticos;
  - recibe el multiplicador de la Tabla 2 cuando lo atacan en área, según
    cuántos miembros alcanza el ataque.
- **Escudo sobrenatural para criaturas con acumulación**, la regla que faltaba
  de [#47](https://github.com/aoalejo/animaMasterToolkit/issues/47). Una
  criatura con acumulación que tenga Proyección puede defenderse con un escudo
  mágico o psíquico aplicando −80, y si se lo superan pierde la acción (p. 99).
- **Ataques adicionales** (p. 91). La tarjeta de ataque calcula el tope, un
  ataque más por cada 100 de HA de la ficha, y el penalizador que aplican todos
  los ataques declarados:
  - según el tamaño del arma: −20 pequeña, −30 media, −40 grande. Se lee de la
    planilla; si falta, se deduce del nombre con las tablas de armas del Core, y
    en los dos casos se puede corregir desde la tarjeta;
  - **ataques extra** fuera del tope: segunda arma (−40, o −10 con
    Ambidestría), patada de Tae Kwon Do (−30, −20 o sin penalizador según el
    grado) y técnica de Ki sin penalizador. Son un grupo de modificadores
    situacionales de selección única, como las zonas apuntadas. Los que
    corresponden al personaje por su ficha aparecen primero y marcados con ★,
    sin ocultar el resto, y el que está activo se ve en la tarjeta de ataque
    con un botón para quitarlo;
  - **Tabla de Ataque Encadenado**: armas grandes como medias y medias como
    pequeñas. La tarjeta lo muestra como «Arma M como P»;
  - **Tabla de Ataque Adicional**: un ataque más al tope, con el penalizador
    habitual. No está en los manuales digitalizados; viene de la planilla y de
    la Pantalla del Director;
  - **Kempo** (Dominus Exxet, que manda sobre el Core): −15 en grado base, −10
    en avanzado y un ataque extra en supremo. Solo sin armas;
  - desarmado sin arte marcial aplica −20, como un arma pequeña.

  Ambidestría, las dos tablas y los grados de Kempo y Tae Kwon Do se marcan en la
  ficha del personaje, y al importar se leen de la planilla: las ventajas de la
  hoja Principal, las Tablas de Estilos y las artes marciales de Combate. El
  tamaño de cada arma sale de la Tabla de Armas y Escudos; con dos armas, el de
  la más grande. Verificado contra tres planillas reales. Los personajes
  cargados antes de este cambio arrancan con todo apagado hasta reimportarlos.
- **Maniobras y estados de los manuales que faltaban**, auditados contra el Core
  (situaciones de combate, ataques específicos, defensas especiales, Estados y
  Accidentes) y el Dominus (Tablas de Estilo y Artes Marciales):
  - maniobras: Derribo, Ataque en área, Engatillar, Crítico secundario, dejar
    inconsciente sin arma contundente, moverse más de ¼ del movimiento, Apartar
    a otro y Resistir el golpe;
  - variantes de cada maniobra según la tabla o el arte marcial que reduce su
    penalizador: Sambo, Grappling, Pankration, Aikido, Emp, Malla-yuddha,
    Capoeira, Kuan, Soo Bahk, Hanja, Batto jutsu y las tablas de Área,
    Precisión, Desarme, Ataque Inusual, Presa Inusual, Guardaespaldas y
    Movimiento en Espacios Reducidos;
  - bonos de artes marciales: Kung Fu (+10, +20 o +40 con Asakusen arcano),
    Asakusen, Xing Quan (+10, +20, +30) y contraataque con Boxeo avanzado;
  - estados: Dolor leve, Fascinación, Incapacitado y Recién estabilizado.

  Cada maniobra es un grupo de selección única con sus variantes. Las que
  corresponden al personaje por sus tablas y artes marciales aparecen primero y
  marcadas con ★ al atacar, al defenderse y en los estados.
- **Defensas sin penalizador.** Cuando el defensor tiene algo que lo otorga, la
  tarjeta de defensa muestra cuántas defensas del asalto no aplican el
  penalizador por defensas adicionales, ya cargado: Lama (1 o 2), Lama Tsu (2
  más, o todas en Arcano) y Tabla de 2ª Arma: Estilo Defensivo (1 con dos
  armas). Para cualquier otro, como un PNJ sin ficha, se activa a mano, y un
  botón la quita y la vuelve a 0, incluso a quien la tiene por ficha.
- **Un solo catálogo de modificadores.** El panel del personaje y el de
  Situacionales tenían listas distintas: la Defensa total, Shephon o el vuelo
  solo existían como estados y no aparecían al defenderse. Ahora comparten el
  catálogo completo, y cada tirada muestra los que la afectan.
- **Tablas y artes marciales en la ficha.** Se importan todas de la planilla y se
  editan como una lista, con el catálogo de los manuales para elegir o un
  nombre propio. Reemplazan a los interruptores de Ataque Encadenado, Ataque
  Adicional, Kempo y Tae Kwon Do, que ahora se leen de esa lista.

  Quedan fuera por no tener valores cerrados o no estar en los manuales
  digitalizados: Tabla de Combate a Ciegas (sin regla de redondeo), Terror,
  críticos, frío, electricidad y desangramiento (penalizadores variables, que
  se cargan a mano), los bonos al crítico y el bono doble de contraataque de
  Selene.

## Importación de fichas

### Corregido

- **La importación de planillas de Excel funciona sin servidor.** Dependía de un
  conversor externo que solo acepta peticiones desde el dominio publicado, así
  que fallaba al ejecutar la aplicación en local por CORS, y fallaba en
  silencio.

  El intento anterior de leerlas en local está comentado en
  `lib/utils/local_excel_parser.dart` por dos motivos que resultaron ser
  limitaciones del paquete `excel`, no del formato: tardaba «hasta 15 minutos» y
  no leía el resultado de las fórmulas. Excel guarda el valor calculado junto a
  cada fórmula en el mismo XML, y solo hacen falta una veintena de rangos fijos.
  El lector propio tarda unos 200 ms por ficha.

  `lib/utils/xlsx/sheet_to_json.dart` es la traducción de `ExportJson.bas`, la
  macro que la propia planilla usa para exportarse, así que produce el mismo
  JSON. Verificado contra cinco fichas reales: guerrero, tecnicista, maestro en
  armas, hechicero y mentalista en planilla Akuma Exxet.
- **La acumulación de daño nunca sobrevivía a la importación**, por dos motivos
  encadenados: la planilla exporta el campo como `acumDanio` y la aplicación lo
  guardaba como `acumulacionDeDanio`, y el valor de la celda es «Sí» o «No»,
  mientras que la conversión a booleano solo entendía `true` y `false`. Afectaba
  también a `uruboros`.
- **Los CVs libres y los conjuros libres no se importaban.** Los CVs no los
  exportaba ni la macro original, así que el consumible de CV no se creaba nunca.
- **Los errores de importación se muestran.** Antes se guardaban en un campo que
  no leía nadie, y un archivo con problemas cortaba la carga del resto.
- **El Ki ya no arranca en 1.** Se creaba con valor actual 1 mientras el Zeon y
  los CVs se creaban llenos.
- **La proyección mágica y la psíquica solo se añaden como arma si el personaje
  invirtió PD en ellas.** La planilla muestra un valor de proyección para
  cualquiera, salido solo de sus características, así que antes todos recibían
  dos armas inútiles. La fila se localiza por etiqueta y no por número, porque
  variantes como la Akuma Exxet corren las filas de la hoja de PDs.

## Interfaz

### Añadido

- **Modo oscuro** con preferencia persistente y conmutador en la barra superior.
  Arranca siguiendo el tema del sistema. Ni blanco ni negro puros.
- **Panel de modificadores buscable y agrupado.** Mostraba unos cuatro
  modificadores a la vez y obligaba a desplazarse por más de cincuenta
  interruptores. Ahora crece hasta el 85 % de la pantalla, tiene buscador y
  reparte en columnas.

  Los modificadores que se excluyen entre sí van en un desplegable de selección
  única: las 16 zonas apuntadas, los grados de ceguera, parálisis y dolor, el
  cansancio, la actitud de combate y diez grupos más. Ya no se pueden declarar
  combinaciones imposibles como apuntar a dos zonas a la vez.
- **El desglose de resultados es una tabla**, no una línea de texto corrido con
  paréntesis anidados. Un sumando por fila, los términos en cero ocultos, signo
  y color según sume o reste, y cifras tabulares.
- **Estado vacío** en la tabla de personajes.
- **El recurso que sigue la tabla se elige solo y se puede cambiar a mano.**
  Antes era siempre el Ki. Ahora es CV si el personaje tiene psiquismo, Zeon si
  tiene proyección mágica, y Ki en el resto de los casos; el indicador es un
  menú para cambiarlo.
- **El tipo de crítico se preselecciona** según el arma empuñada. Arrancaba
  siempre en Energía, así que la absorción se calculaba contra la TA equivocada
  salvo que se tocara el selector.
- **Ficha de personaje compacta.** Era una tabla ancha con diez columnas de
  dificultad por fila. Ahora sigue la lógica de un bloque del bestiario:
  vitales, características, resistencias y combate arriba; habilidades
  agrupadas por las categorías del manual, con la escalera de dificultades al
  tocar cada una; vías, conjuros y disciplinas en secciones plegables.

### Corregido

- **Numeración de copias** (cierra
  [#45](https://github.com/aoalejo/animaMasterToolkit/issues/45)). Duplicar un
  personaje ya numerado apilaba sufijos: «PJ», «PJ #2», «PJ #2 #3»… Ahora se
  numera siempre sobre el nombre base.
- **Contraste del modo oscuro.** Los nueve iconos SVG se dibujaban con su
  relleno original en negro. Los chips y cabeceras usaban `colorScheme.primary`
  como relleno, que en Material 3 oscuro es un tono claro pensado para texto.
- **Formas de pastilla y números recortados.** El radio de tarjeta convertía en
  óvalo a cualquier tarjeta baja, que son casi todas. Los contadores de
  consumibles se dibujaban como burbujas y perdían dígitos.
- **El indicador circular de vida deformaba la cifra.** Pasa a ser una barra.
- **El cartel de bienvenida cortaba el texto a media línea**: sacaba su alto del
  ancho de la pantalla. También se reescribió, porque describía una migración
  del guardado local a la nube que ya no le dice nada a nadie.
- **Auditoría de Web Interface Guidelines**: `web/index.html` era un shell de 69
  bytes sin `<head>`; 21 botones de icono no tenían nombre accesible; la tabla
  de personajes construía todas las filas sin virtualizar; no se respetaba
  `prefers-reduced-motion`.
- **Fuera el progreso simulado de la importación**, un temporizador de 250 ms por
  archivo que no reflejaba avance real y no dejaba terminar antes.

## Mantenimiento

- **El proyecto vuelve a compilar con un Flutter actual.** `flutter_localizations`
  exige `intl ^0.20.3` y el `pubspec` fijaba `^0.19.0`, así que las dependencias
  no resolvían.
- Los globs de exclusión de `analysis_options.yaml` estaban bajo `linter.rules`,
  donde `exclude` no es una regla válida.
- Se ignoran las localizaciones que genera `flutter gen-l10n` y no usa nadie.

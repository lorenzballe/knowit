// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'Astut';

  @override
  String get plusName => 'Astut+';

  @override
  String get tabToday => 'Hoy';

  @override
  String get tabExplore => 'Explorar';

  @override
  String get tabProfile => 'Perfil';

  @override
  String signInNotConnected(String provider) {
    return 'El acceso con $provider aún no está conectado. Tus tarjetas se quedan en este dispositivo.';
  }

  @override
  String couldNotSignInCarryOn(String label) {
    return 'No se pudo iniciar sesión con $label. Puedes seguir sin cuenta.';
  }

  @override
  String streakDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n días',
      one: '1 día',
    );
    return '$_temp0';
  }

  @override
  String get freezeKeptStreak => 'Un freeze salvó la racha';

  @override
  String countWord(String n) {
    String _temp0 = intl.Intl.selectLogic(n, {
      '1': 'una',
      '2': 'dos',
      '3': 'tres',
      '4': 'cuatro',
      '5': 'cinco',
      '6': 'seis',
      '7': 'siete',
      '8': 'ocho',
      '9': 'nueve',
      '10': 'diez',
      'other': '$n',
    });
    return '$_temp0';
  }

  @override
  String dayRead(int n, String word) {
    return 'Día $n · $word leídas';
  }

  @override
  String shelfEyebrow(String word) {
    return 'LAS $word DE HOY · DESLIZA PARA REPASAR';
  }

  @override
  String weekLine(int days) {
    return 'Tu semana · $days de 7 cumplidos';
  }

  @override
  String get tapToFlip => 'TOCA PARA GIRAR';

  @override
  String get shareThisCard => 'Compartir esta tarjeta';

  @override
  String get removeFromSaved => 'Quitar de guardadas';

  @override
  String get saveThisPill => 'Guardar esta píldora';

  @override
  String get shareThisPill => 'Compartir esta píldora';

  @override
  String cardOf(int k, int n) {
    return 'Tarjeta $k de $n';
  }

  @override
  String hoursMinutes(int h, int m) {
    return '$h h $m min';
  }

  @override
  String tomorrowsFiveOpenIn(String when) {
    return 'Las cinco de mañana se abren en $when';
  }

  @override
  String topicOpensTomorrow(String topic, String when) {
    return '$topic abre las cinco de mañana, en $when';
  }

  @override
  String get exploreTodaysBest => 'Explora lo mejor de hoy';

  @override
  String get fiveMore => 'Cinco más';

  @override
  String get unlockFiveExtra => 'Desbloquea cinco píldoras extra';

  @override
  String nothingInYet(String subject) {
    return 'Todavía no hay nada en $subject.';
  }

  @override
  String get here => 'esta sección';

  @override
  String get todaysShelf => 'La estantería de hoy';

  @override
  String get sameForEveryone => 'Igual para todos, y solo hoy';

  @override
  String get onesThatAskTheMost => 'Las que más preguntan';

  @override
  String get acrossEveryone => 'Entre todos, no solo en tu mezcla';

  @override
  String becauseSitsAtFull(String name) {
    return 'Porque $name está al máximo';
  }

  @override
  String get olderFromTurnedUp => 'Tarjetas antiguas de los temas que subiste';

  @override
  String moreOn(String name) {
    return 'Más sobre $name';
  }

  @override
  String get subjectReadMost => 'El tema del que más has leído';

  @override
  String monthOf(String name) {
    return 'Un mes de $name';
  }

  @override
  String get somewhereToStart => 'Un punto de partida que no es hoy';

  @override
  String get searchEveryCard => 'Buscar en todas las tarjetas';

  @override
  String nothingForYet(String query) {
    return 'Todavía nada para \"$query\".';
  }

  @override
  String matching(int n) {
    return '$n coincidencias';
  }

  @override
  String get all => 'Todos';

  @override
  String get theArchive => 'El archivo';

  @override
  String results(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n resultados',
      one: '1 resultado',
    );
    return '$_temp0';
  }

  @override
  String cardsTapADay(int n) {
    return '$n tarjetas. Toca un día para abrirlo.';
  }

  @override
  String get whatYouHaveCovered => 'Lo que has cubierto';

  @override
  String searchNCards(int n) {
    return 'Buscar en $n tarjetas';
  }

  @override
  String get cancel => 'Cancelar';

  @override
  String nCards(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n tarjetas',
      one: '1 tarjeta',
    );
    return '$_temp0';
  }

  @override
  String get yesterday => 'Ayer';

  @override
  String get noPillsMatchFilter =>
      'Ninguna píldora coincide aún con ese filtro.';

  @override
  String nothingForTryTopic(String query) {
    return 'Nada para \"$query\". Prueba con un tema.';
  }

  @override
  String get saved => 'Guardadas';

  @override
  String get removedFromSaved => 'Quitada de guardadas.';

  @override
  String get undo => 'Deshacer';

  @override
  String get nothingKeptYet => 'Aún no has guardado nada';

  @override
  String nInTopic(int n, String topic) {
    return '$n en $topic';
  }

  @override
  String get keepTheOnesYoullUse => 'Guarda las que de verdad vas a usar';

  @override
  String get backToTodaysFive => 'VOLVER A LAS CINCO DE HOY';

  @override
  String get archive => 'Archivo';

  @override
  String get yourWeek => 'Tu semana';

  @override
  String get nothingThisWeekYet =>
      'Nada todavía esta semana. Cinco tarjetas la empiezan.';

  @override
  String keptDaysOfSeven(int days) {
    return 'Cumplida: $days días de siete.';
  }

  @override
  String daysOfSevenFiveKeeps(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days días de siete.',
      one: '1 día de siete.',
    );
    return '$_temp0 Con cinco, la semana cuenta.';
  }

  @override
  String get howSureAgainstHowRight =>
      'Cuánta seguridad, frente a cuánto acierto';

  @override
  String get sureAndWrong => 'Seguro, y equivocado';

  @override
  String get worthGoingBackTo =>
      'Las que merece la pena repasar. Equivocarte en algo de lo que estabas seguro es la única forma barata de descubrir lo que crees de verdad.';

  @override
  String get whereThisIsGoing => 'Hacia dónde va esto';

  @override
  String ofNRight(int n) {
    return 'de $n acertadas';
  }

  @override
  String get sayHowSureOnMore =>
      'Di cuánto estás seguro en unas cuantas más y la app te dirá cuánto vale esa seguridad.';

  @override
  String confidenceOff(int gap) {
    return 'Tu seguridad estaba a $gap puntos de lo que realmente sabías.';
  }

  @override
  String confidenceClosing(int gap, int before) {
    return 'Tu seguridad se desvió $gap puntos, frente a $before la semana pasada. Se está cerrando.';
  }

  @override
  String confidenceOpened(int gap, int before) {
    return 'Tu seguridad se desvió $gap puntos, frente a $before la semana pasada. Se ha abierto.';
  }

  @override
  String nextRung(String name) {
    return 'Siguiente: $name';
  }

  @override
  String youSaidPercentSure(int n) {
    return 'Dijiste $n% seguro';
  }

  @override
  String rungName(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'day_one': 'Día uno',
      'reading': 'Leyendo',
      'answering': 'Respondiendo',
      'saying_how_sure': 'Diciendo cuánto',
      'calibrated': 'Calibrado',
      'holding': 'Reteniendo',
      'sharp': 'Agudo',
      'other': '$id',
    });
    return '$_temp0';
  }

  @override
  String rungClaim(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'day_one': 'Todo el mundo empieza aquí.',
      'reading': 'El hábito ha empezado.',
      'answering': 'Te comprometes antes de girar la tarjeta.',
      'saying_how_sure': 'Pones un número a lo que crees saber.',
      'calibrated': 'Lo que dices saber, lo sabes.',
      'holding': 'Se queda contigo semanas después.',
      'sharp': 'Seguro cuando debes, y acertado cuando lo estás.',
      'other': '$id',
    });
    return '$_temp0';
  }

  @override
  String stepRead(int n) {
    return '$n tarjetas más por leer';
  }

  @override
  String stepAnswer(int n) {
    return '$n tarjetas más por responder';
  }

  @override
  String stepJudge(int n) {
    return '$n respuestas más diciendo cuánto estás seguro';
  }

  @override
  String stepHold(int n) {
    return '$n tarjetas más por retener';
  }

  @override
  String stepGap(int gap, int target) {
    return 'tu seguridad se desvía $gap puntos; con $target basta';
  }

  @override
  String stepBeforeJudged(int n) {
    return '$n respuestas más antes de que la app juzgue tu seguridad';
  }

  @override
  String stepThenRung(String step, String name) {
    return '$step → $name';
  }

  @override
  String rungOfTotal(int at, int of) {
    return '$at / $of';
  }

  @override
  String get signOutQuestion => '¿Cerrar sesión?';

  @override
  String get signOutBody =>
      'Tu racha, tus píldoras guardadas y tu historial se quedan en tu cuenta. Esto los borra de este dispositivo.';

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String get signedInRecordOnAccount =>
      'Sesión iniciada. Tu racha y tu historial ya están en tu cuenta.';

  @override
  String couldNotSignInWith(String label) {
    return 'No se pudo iniciar sesión con $label.';
  }

  @override
  String get signInNotAvailableBuild =>
      'Iniciar sesión no está disponible en esta versión.';

  @override
  String get startOverQuestion => '¿Empezar de cero?';

  @override
  String get startOverBody =>
      'Borra todo en este dispositivo (racha, píldoras guardadas, respuestas, tu historial de juicios, temas y plan) y vuelve a abrir la introducción.';

  @override
  String get wipeIt => 'Borrar';

  @override
  String get yourRecord => 'Tu historial';

  @override
  String get appearance => 'Apariencia';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get yourTopics => 'Tus temas';

  @override
  String get edit => 'Editar';

  @override
  String get howWellYouKnowYourself => 'Cuánto te conoces';

  @override
  String get isTheGapClosing => '¿Se está cerrando la brecha?';

  @override
  String get movesYouKeepMissing => 'Las jugadas que sigues fallando';

  @override
  String get dailyNudge => 'Aviso diario';

  @override
  String everyDayAt(String time) {
    return 'Cada día a las $time';
  }

  @override
  String get yourFivePillsBeforeCoffee =>
      'Tus 5 píldoras, antes del primer café.';

  @override
  String get browserOnlySpeaksOpen =>
      'Un navegador solo habla mientras está abierto, así que esto necesita la versión para móvil.';

  @override
  String get nudgeOff => 'Aviso apagado.';

  @override
  String nudgeOnEveryDayAt(String time) {
    return 'Aviso activo, cada día a las $time.';
  }

  @override
  String get nudgeOnSystemSaidNo =>
      'Aviso activo, pero el sistema dijo que no. Activa las notificaciones de Astut en los ajustes.';

  @override
  String get nudgeOnNeedsPhone =>
      'Aviso activo. Para recibirlo hace falta la versión para móvil.';

  @override
  String get howMuchYouKnow => 'Cuánto sabes';

  @override
  String savedN(int n) {
    return 'Guardadas · $n';
  }

  @override
  String get manageSubscription => 'Gestionar suscripción';

  @override
  String get howPillsAreWritten => 'Cómo se escriben las píldoras';

  @override
  String get signingIn => 'Iniciando sesión…';

  @override
  String get signInWithApple => 'Iniciar sesión con Apple';

  @override
  String get signInWithGoogle => 'Iniciar sesión con Google';

  @override
  String acrossNAnswersHowSure(int n) {
    return 'En $n respuestas dijiste cuánto estabas seguro. Esto es lo que pasó.';
  }

  @override
  String get perfectlyCalibratedLine =>
      'Una persona perfectamente calibrada acierta el 70% de las veces cuando dice 70%.';

  @override
  String get notEnoughAnswersYet => 'Aún no hay suficientes respuestas';

  @override
  String get confidenceMatchesAccuracy =>
      'Tu seguridad coincide con tu precisión';

  @override
  String overconfidentBy(int points) {
    return 'Te sobra seguridad: $points puntos';
  }

  @override
  String underconfidentBy(int points) {
    return 'Te falta seguridad: $points puntos';
  }

  @override
  String saidPercent(int n) {
    return 'Dijiste $n%';
  }

  @override
  String rightPercentOf(int pct, int right, int count) {
    return 'acertaste el $pct% ($right de $count)';
  }

  @override
  String moreOfThisToCome(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n contextos más por venir',
      one: '1 contexto más por venir',
    );
    return '$_temp0';
  }

  @override
  String get seeEveryPrincipleWithPlus =>
      'Ve todos los principios con Astut plus';

  @override
  String moreBeingTracked(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n más en seguimiento',
      one: '1 más en seguimiento',
    );
    return '$_temp0';
  }

  @override
  String get shareMyRecord => 'COMPARTIR MI HISTORIAL';

  @override
  String lastCallsAgainstFirst(int n) {
    return 'Tus últimas $n respuestas, frente a las primeras $n';
  }

  @override
  String closedByPoints(int n) {
    return 'Se cerró $n puntos';
  }

  @override
  String openedByPoints(int n) {
    return 'Se abrió $n puntos';
  }

  @override
  String get holdingSteady => 'Se mantiene';

  @override
  String get measurementRunningPlus =>
      'La medición está en marcha. Astut+ te muestra hacia dónde va.';

  @override
  String firstN(int n) {
    return 'Primeras $n';
  }

  @override
  String lastN(int n) {
    return 'Últimas $n';
  }

  @override
  String get trackingMoreClosely =>
      'Tu seguridad sigue tu precisión más de cerca que antes.';

  @override
  String get distanceHasGrown =>
      'La distancia ha crecido. Merece la pena frenar antes de comprometerte.';

  @override
  String get noRealMovementYet =>
      'Aún no hay movimiento real. Esto lleva semanas, no días.';

  @override
  String get seeWhichWay => 'VER HACIA DÓNDE';

  @override
  String get spotOn => 'exacto';

  @override
  String pointsOver(int n) {
    return '$n de más';
  }

  @override
  String pointsUnder(int n) {
    return '$n de menos';
  }

  @override
  String get plusNameCaps => 'ASTUT+';

  @override
  String get sevenDaysFree => '7 días gratis';

  @override
  String get watchTheGapMove => 'Mira cómo se mueve la brecha.';

  @override
  String get measurementFreeForever =>
      'La medición es gratis y siempre lo será. Astut+ es lo que te dice hacia dónde va.';

  @override
  String get seeThePlans => 'VER LOS PLANES';

  @override
  String get recordStartsToday => 'Tu historial empieza hoy.';

  @override
  String dayWord(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'días',
      one: 'día',
    );
    return '$_temp0';
  }

  @override
  String pillReadWord(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'píldoras leídas',
      one: 'píldora leída',
    );
    return '$_temp0';
  }

  @override
  String nPillsRead(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n píldoras leídas',
      one: '1 píldora leída',
    );
    return '$_temp0';
  }

  @override
  String nWeeksKept(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n semanas cumplidas',
      one: '1 semana cumplida',
    );
    return '$_temp0';
  }

  @override
  String nComingBack(int n) {
    return '$n de vuelta';
  }

  @override
  String nFreezesInHand(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n freezes disponibles',
      one: '1 freeze disponible',
    );
    return '$_temp0';
  }

  @override
  String get freePlan => 'Plan gratuito';

  @override
  String get streakReset => 'Racha reiniciada';

  @override
  String youMissedDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Te saltaste\n$n días.',
      one: 'Te saltaste\nun día.',
    );
    return '$_temp0';
  }

  @override
  String bestStreakStillRecord(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n días siguen siendo',
      one: 'Un día sigue siendo',
    );
    return '$_temp0 tu récord. Lee las cinco de hoy y el contador vuelve a empezar desde uno.';
  }

  @override
  String get whileYouWereAway => 'Mientras no estabas';

  @override
  String pillsWentUnread(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n píldoras quedaron sin leer',
      one: '1 píldora quedó sin leer',
    );
    return '$_temp0';
  }

  @override
  String stillMostKeptTopic(String topic) {
    return '$topic sigue siendo el tema que más guardas';
  }

  @override
  String cardsDueBackToday(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n tarjetas que acertaste vuelven hoy',
      one: '1 tarjeta que acertaste vuelve hoy',
    );
    return '$_temp0';
  }

  @override
  String get startAgainWithTodaysFive =>
      'Empezar de nuevo con las cinco de hoy';

  @override
  String moveMyReminderTo(String time) {
    return 'Mover mi recordatorio a las $time';
  }

  @override
  String dailyNudgeMovedTo(String time) {
    return 'Aviso diario movido a las $time.';
  }

  @override
  String get whatYouAlready => 'Lo que ya ';

  @override
  String get know => 'sabes';

  @override
  String get knowIntro =>
      'Los temas que más subiste. Cambia lo que un día te pide en cada uno (sólido recibe preguntas, curioso recibe explicaciones), no cuánto recibes de él.';

  @override
  String get startWithMyFirstCards => 'Empezar con mis primeras tarjetas';

  @override
  String get skipForNow => 'Saltar por ahora';

  @override
  String get levelCurious => 'Curioso';

  @override
  String get levelSome => 'Algo';

  @override
  String get levelSolid => 'Sólido';

  @override
  String get save => 'Guardar';

  @override
  String subjectsInTheMix(int n, int total) {
    return '$n de $total temas en la mezcla';
  }

  @override
  String get yourSpace => 'Tu ';

  @override
  String get mix => 'mezcla';

  @override
  String get everythingIsInDrag =>
      'Está todo dentro. Arrastra un tema hacia abajo para ver menos, o hasta cero para quitarlo.';

  @override
  String get next => 'Siguiente';

  @override
  String get whatShouldWeTalkAbout => '¿De qué hablamos?';

  @override
  String get fivePillsADayPick =>
      'Cinco píldoras al día, escritas cada mañana. Elige los temas que quieres en la mezcla; puedes cambiarlos después.';

  @override
  String nSelected(int n) {
    return '$n seleccionados';
  }

  @override
  String startWithNTopics(int n) {
    return 'Empezar con $n temas';
  }

  @override
  String saveNTopics(int n) {
    return 'Guardar $n temas';
  }

  @override
  String pickAtLeastN(int n) {
    return 'Elige al menos $n';
  }

  @override
  String get swipeToSeeMore => 'Desliza para ver más';

  @override
  String get tagline =>
      'Cinco cosas inteligentes al día, listas para usar en una conversación';

  @override
  String get introTopicsTitle => 'Doce temas, cinco píldoras';

  @override
  String get introTopicsLine =>
      'Escritas cada mañana, y comprobadas contra una fuente.';

  @override
  String get introQuestionTitle => 'Una pregunta, luego la respuesta';

  @override
  String get introQuestionLine =>
      'Cada píldora lleva la frase que merece decirse en voz alta.';

  @override
  String get introMixTitle => 'Tú eliges la mezcla';

  @override
  String get introMixLine => 'Baja un tema para ver menos, o apágalo del todo.';

  @override
  String get introThirtyTitle => 'Treinta segundos al día';

  @override
  String get introThirtyLine =>
      'Una notificación, cinco tarjetas y una racha que no querrás romper.';

  @override
  String get continueWithApple => 'Continuar con Apple';

  @override
  String get continueWithGoogle => 'Continuar con Google';

  @override
  String get continueWithEmail => 'Continuar con el correo';

  @override
  String get termsLine =>
      'Al registrarte aceptas nuestros Términos del servicio y la Política de privacidad';

  @override
  String get skip => 'Saltar';

  @override
  String get tapToRevealLower => 'toca para descubrir';

  @override
  String get barMoveCaps => 'LA FRASE DE BAR';

  @override
  String get theBarMoveCaps => 'LA FRASE DE BAR';

  @override
  String get dayStreakCaps => 'DÍAS DE RACHA';

  @override
  String sourceLabel(String source) {
    return 'Fuente · $source';
  }

  @override
  String get perkRecordTitle => 'Tu historial en el tiempo';

  @override
  String get perkRecordLine =>
      'Si la brecha entre cuánto estabas seguro y cuánto acertaste se está cerrando de verdad.';

  @override
  String get perkPrinciplesTitle => 'Todos los principios que has encontrado';

  @override
  String get perkPrinciplesLine =>
      'No solo los tres que peor llevas: todos, y los contextos que aún no has visto.';

  @override
  String get perkFreezesTitle => 'Tres freezes de racha, no uno';

  @override
  String get perkFreezesLine =>
      'Suficiente para un fin de semana fuera. Una racha que solo puedes perder es una racha que acaba yéndose.';

  @override
  String get perkExtraTitle => '5 píldoras extra cada día';

  @override
  String get perkExtraLine =>
      'Un segundo set se desbloquea en cuanto terminas el primero.';

  @override
  String get perkArchiveTitle => 'El archivo completo';

  @override
  String get perkArchiveLine =>
      'Cada píldora que has leído, buscable por tema.';

  @override
  String get perkTopicsTitle => 'Elige tus propios temas';

  @override
  String get perkTopicsLine =>
      'Inclina la mezcla hacia lo que de verdad te gusta.';

  @override
  String get plusIsActive => 'ASTUT+ ESTÁ ACTIVO';

  @override
  String tryFreeThen(String price, String suffix) {
    return 'Prueba 7 días gratis, luego $price$suffix';
  }

  @override
  String get trialStartedNoPayment =>
      'Prueba iniciada. No hay pago conectado en esta versión.';

  @override
  String get thatDidNotGoThrough => 'Eso no se completó.';

  @override
  String get plusIsBack => 'Astut+ ha vuelto.';

  @override
  String get nothingToRestore => 'Nada que restaurar en esta cuenta.';

  @override
  String get findOutIfBetter => 'Descubre si de verdad estás mejorando.';

  @override
  String get perYear => 'al año';

  @override
  String aMonth(String price) {
    return '$price al mes';
  }

  @override
  String savePercent(int n) {
    return 'AHORRA $n%';
  }

  @override
  String get perMonth => 'al mes';

  @override
  String get billedMonthly => 'cobro mensual';

  @override
  String get cancelTheTrial => 'Cancelar la prueba';

  @override
  String get cancelAnyTime => 'Cancela cuando quieras';

  @override
  String get cancelAnyTimeNoPayment =>
      'Cancela cuando quieras · No se cobra nada en esta versión';

  @override
  String get restorePurchases => 'Restaurar compras';

  @override
  String get everythingOpensNothingCharged => 'Se abre todo. No se cobra nada.';

  @override
  String dayN(int n) {
    return 'DÍA $n';
  }

  @override
  String get reminderTwoDaysBefore =>
      'Un recordatorio, dos días antes de renovarse.';

  @override
  String get itRenewsUnlessCancelled =>
      'Se renueva, salvo que hayas cancelado. Puedes hacerlo cuando quieras.';

  @override
  String get howTheFreeWeekWorks => 'CÓMO FUNCIONA LA SEMANA GRATIS';

  @override
  String planPrice(String label, String price, String per) {
    return '$label, $price $per';
  }

  @override
  String get pickASideNoRightAnswer =>
      'Elige un bando. No hay respuesta correcta.';

  @override
  String get estimateCloseEnough => 'Estima. Acercarte cuenta.';

  @override
  String get tapToReveal => 'Toca para descubrir';

  @override
  String closeEnoughItIs(String answer) {
    return 'Cerca · es $answer';
  }

  @override
  String youSaidItIsCounted(String given, String answer, String band) {
    return 'Dijiste $given · es $answer, y $band cuenta';
  }

  @override
  String get youGotIt => 'Acertaste';

  @override
  String youSaidItIs(String given, String answer) {
    return 'Dijiste $given · es $answer';
  }

  @override
  String get almostEveryoneGetsThisWrong => 'Casi todo el mundo falla esta';

  @override
  String lineYouSaidSure(String line, int pct) {
    return '$line · dijiste $pct% seguro';
  }

  @override
  String get giveMeANudge => 'Dame una pista';

  @override
  String get beingRightMattersLess =>
      'Acertar importa menos que saber con qué frecuencia aciertas.';

  @override
  String get writeItBeforeTheirs => 'Escríbelo antes de leer el suyo.';

  @override
  String get youAnsweredThisOne => 'Esta ya la respondiste.';

  @override
  String difficultyLabel(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'easy': 'Fácil',
      'medium': 'Media',
      'hard': 'Difícil',
      'other': '$id',
    });
    return '$_temp0';
  }

  @override
  String commitBeforeYouTurn(String difficulty) {
    return '$difficulty · comprométete antes de girarla.';
  }

  @override
  String get yourAnswer => 'Tu respuesta';

  @override
  String get checkMyAnswer => 'Comprobar mi respuesta';

  @override
  String get howSureAreYou => '¿Cuánto estás seguro?';

  @override
  String percentSure(int n) {
    return '$n por ciento seguro';
  }

  @override
  String get inOneLineWhy => 'En una línea: ¿por qué?';

  @override
  String get because => 'Porque…';

  @override
  String get nowShowMeTheOtherSide => 'Ahora muéstrame el otro lado';

  @override
  String get skipShowMeAnyway => 'Saltar: muéstramelo igual';

  @override
  String get youTookCaps => 'ELEGISTE';

  @override
  String get putSimplyCaps => 'EN POCAS PALABRAS';

  @override
  String get explainLikeImThree => 'Explícamelo como a un niño';

  @override
  String get whatTheOtherSideSaysCaps => 'LO QUE DICE EL OTRO LADO';

  @override
  String get whatTheOtherSideSays => 'Lo que dice el otro lado';

  @override
  String theTrap(String trap) {
    return 'La trampa: $trap';
  }

  @override
  String youTookTheSide(String side) {
    return 'Elegiste el bando: $side';
  }

  @override
  String atPercentSure(int n) {
    return ' con un $n% de seguridad';
  }

  @override
  String youGotThisOne(String sure) {
    return 'Esta la acertaste$sure';
  }

  @override
  String youSaidAnswer(String answer, String sure) {
    return 'Dijiste $answer$sure';
  }

  @override
  String get swipeForTheNextOne => 'Desliza para la siguiente';

  @override
  String get thatWasTheOnlyOne => 'Era la única';

  @override
  String indexOfN(int i, int n) {
    return '$i/$n';
  }

  @override
  String get couldNotRenderCard => 'No se pudo dibujar la tarjeta.';

  @override
  String get textCopiedInstead => 'Se copió el texto en su lugar.';

  @override
  String get copiedToClipboard => 'Copiado al portapapeles.';

  @override
  String get rendering => 'Dibujando…';

  @override
  String get theSourceGoesWithIt => 'La fuente va con ella';

  @override
  String get fiveADayALittleSharper => 'Cinco al día. Un poco más agudo.';

  @override
  String get shareMyDay => 'Compartir';

  @override
  String climbedTo(String rung) {
    return 'Hoy has subido a $rung';
  }

  @override
  String rightOfAsked(int right, int asked) {
    return '$right de $asked correctas';
  }

  @override
  String saidSure(int sure) {
    return '$sure% de seguridad';
  }

  @override
  String cardsCameBack(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n tarjetas han vuelto — respóndelas otra vez',
      one: '1 tarjeta ha vuelto — respóndela otra vez',
    );
    return '$_temp0';
  }

  @override
  String get cameBack => 'Han vuelto';

  @override
  String get holdACardYouLike => 'Si te gusta, mantenla';

  @override
  String likedToday(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n me gusta hoy',
      one: '1 me gusta hoy',
    );
    return '$_temp0';
  }

  @override
  String get liked => 'Me gusta';

  @override
  String likedN(int n) {
    return 'Me gusta · $n';
  }

  @override
  String get nothingLikedYet => 'Todavía nada que te guste';

  @override
  String get likeThisPill => 'Me gusta esta píldora';

  @override
  String get removeFromLiked => 'Quitar de me gusta';

  @override
  String get removedFromLiked => 'Quitada de me gusta.';

  @override
  String get lessLikeThis => 'Menos como esta';

  @override
  String get whatYouLikedLandsHere => 'Las que volverías a leer';

  @override
  String get holdToLikeLandsHere =>
      'Mantén pulsada una tarjeta que te guste y aterriza aquí — y la app te da más así.';

  @override
  String get tapTheBookmarkLandsHere =>
      'Toca el marcador en cualquier píldora y aterriza aquí — las que cambiaron tu forma de pensar, guardadas.';

  @override
  String get nudgeTitle => 'Tus cinco están listas';

  @override
  String get nudgeFreezeTitle => 'Tu congelación aguanta';

  @override
  String nudgeFreezeBody(String question) {
    return 'Ayer está cubierto. Hoy: $question';
  }

  @override
  String get nudgeSureTitle => 'De esta estabas seguro';

  @override
  String nudgeSureBody(String question, int sure) {
    return '$question — dijiste $sure%.';
  }

  @override
  String nudgeTwoWeeksTitle(int read) {
    return 'Hace dos semanas habías leído $read tarjetas';
  }

  @override
  String nudgeTwoWeeksBody(int gap, String question) {
    return 'Tu confianza estaba $gap puntos desviada. Hoy: $question';
  }

  @override
  String nudgeTwoWeeksBodyNoGap(int answered, String question) {
    return '$answered respondidas hasta ahora. Hoy: $question';
  }

  @override
  String get friends => 'Amigos';

  @override
  String friendsN(int n) {
    return 'Amigos · $n';
  }

  @override
  String get yourFriendCode => 'Tu código de amigo';

  @override
  String get codeCopied => 'Código copiado.';

  @override
  String get addAFriend => 'Añadir un amigo';

  @override
  String get theirCode => 'Su código';

  @override
  String get add => 'Añadir';

  @override
  String get noFriendsYet =>
      'Nadie todavía. Intercambia códigos con un amigo y comparad rachas y calibración — nunca respuestas.';

  @override
  String get friendsNeedAnAccount =>
      'Comparar requiere la app del teléfono y una cuenta. Tus códigos se guardan.';

  @override
  String get noReaderWithCode => 'Ningún lector con ese código.';

  @override
  String get thatsYourOwnCode => 'Ese es tu propio código.';

  @override
  String pointsOff(int n) {
    return '$n puntos de desvío';
  }

  @override
  String get notMeasuredYet => 'aún sin medir';

  @override
  String get thisWeekByCalibration => 'Esta semana, por calibración';

  @override
  String get notYetToday => 'hoy todavía no';

  @override
  String nOfSeven(int n) {
    return '$n de 7';
  }

  @override
  String get you => 'Tú';

  @override
  String get todaysQuestion => 'La pregunta de hoy';

  @override
  String get right => 'correcta';

  @override
  String get wrong => 'incorrecta';

  @override
  String rightAtSure(int sure) {
    return 'correcta, $sure% de seguridad';
  }

  @override
  String wrongAtSure(int sure) {
    return 'incorrecta, $sure% de seguridad';
  }

  @override
  String get yourJourney => 'Tu viaje';

  @override
  String get thePath => 'El camino';

  @override
  String get youAreHere => 'ESTÁS AQUÍ';

  @override
  String reachedOn(String date) {
    return 'Alcanzado el $date';
  }

  @override
  String readSoFar(int n, int of) {
    return '$n de $of leídas hasta ahora';
  }

  @override
  String nRead(int n) {
    return '$n leídas';
  }

  @override
  String levelNamed(int n, String name) {
    return 'Nivel $n · $name';
  }

  @override
  String get topLevel => 'Nivel máximo';

  @override
  String plusNToday(int n) {
    return '+$n hoy';
  }

  @override
  String stillWithYouOf(int n, int total) {
    return 'aún contigo · $n de $total';
  }

  @override
  String get stillWithYouNothing => 'aún contigo · nada respondido';

  @override
  String get calibrationPointsOff => 'calibración · puntos de desvío';

  @override
  String get calibrationNotMeasured => 'calibración · sin medir';

  @override
  String inARowBest(int n) {
    return 'seguidos · récord $n';
  }

  @override
  String movesYouCanSpot(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'trucos que detectas',
      one: 'truco que detectas',
    );
    return '$_temp0';
  }

  @override
  String nCardsIsAbout(int n) {
    return '$n tarjetas son como';
  }

  @override
  String nonFictionBooks(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'libros de no ficción',
      one: 'libro de no ficción',
    );
    return '$_temp0';
  }

  @override
  String hoursOfDocumentaries(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'horas de documentales',
      one: 'hora de documentales',
    );
    return '$_temp0';
  }

  @override
  String lectures(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'clases',
      one: 'clase',
    );
    return '$_temp0';
  }

  @override
  String inTotalACard(String time) {
    return '$time en total · unos 40 segundos por tarjeta';
  }

  @override
  String get bySubject => 'Por materia';

  @override
  String get readOfTheShelf => 'leídas · del estante';

  @override
  String get toSayTonight => 'Para contar esta noche';

  @override
  String get anotherOne => 'Otra';

  @override
  String get saidIt => 'Contada';

  @override
  String get saidAlready => 'Contada';

  @override
  String justMinutes(int m) {
    return '$m min';
  }

  @override
  String get pts => 'puntos';

  @override
  String nStillWithYou(int n) {
    return '$n aún contigo';
  }

  @override
  String nMoves(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n trucos',
      one: '1 truco',
    );
    return '$_temp0';
  }

  @override
  String get scoreStartsToday => 'Tu puntuación empieza con las cinco de hoy.';
}

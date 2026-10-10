// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'Astute';

  @override
  String get plusName => 'Astute+';

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
    return 'LAS $word DE HOY';
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
  String magicUnlock(int days) {
    return 'Prueba $days días gratis';
  }

  @override
  String get getPlus => 'Hazte Astute+';

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
  String get deleteAccount => 'Eliminar cuenta';

  @override
  String get deletingAccount => 'Eliminando tu cuenta…';

  @override
  String get deleteAccountQuestion => '¿Eliminar tu cuenta?';

  @override
  String get deleteAccountBody =>
      'Tu cuenta, su copia de seguridad y el tablero que ven tus amigos se eliminan para siempre, y este dispositivo vuelve a empezar desde el principio. Esto no cancela Astute+: la suscripción se gestiona en los ajustes del App Store.';

  @override
  String get deleteAccountConfirm => 'Eliminar para siempre';

  @override
  String get accountDeleted => 'Tu cuenta se ha eliminado.';

  @override
  String get couldNotDeleteAccount =>
      'No se ha podido eliminar la cuenta. Inténtalo de nuevo en un momento.';

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
  String get journeyButtonLine =>
      'Tu nivel, las jugadas que sigues fallando, tu semana en preguntas';

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
      'Aviso activo, pero el sistema dijo que no. Activa las notificaciones de Astute en los ajustes.';

  @override
  String get nudgeOnNeedsPhone =>
      'Aviso activo. Para recibirlo hace falta la versión para móvil.';

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
      'Ve todos los principios con Astute plus';

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
      'La medición está en marcha. Astute+ te muestra hacia dónde va.';

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
  String get plusNameCaps => 'ASTUTE+';

  @override
  String trialDaysFree(int days) {
    return '$days días gratis';
  }

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
  String subjectsInTheMix(int n, int total) {
    return '$n de $total temas en la mezcla';
  }

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
  String get introTopicsTitle => 'Dieciocho temas, cinco píldoras';

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
  String introNotifyWhen(String time) {
    return 'Mañana, $time';
  }

  @override
  String get introNotifyLine => 'Tus cinco están listas. Día 1.';

  @override
  String get introOneOfFive => '1 DE 5';

  @override
  String get introDayOne => 'DÍA 1';

  @override
  String get introTapTomorrow => 'TOCA MAÑANA PARA DESCUBRIRLO';

  @override
  String get introDayOneTomorrow => 'DÍA 1 · MAÑANA';

  @override
  String get introDaySevenStreak => 'DÍA 7 · PRIMERA RACHA';

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
  String get barMoveCaps => 'LO QUE TE LLEVAS';

  @override
  String get theBarMoveCaps => 'LA FRASE DE BAR';

  @override
  String get widgetFootPlain => 'Cinco cartas, dos minutos.';

  @override
  String widgetFootStreak(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Racha de $n días',
      one: 'Racha de 1 día',
    );
    return '$_temp0';
  }

  @override
  String get widgetFootDone => 'Hecho por hoy';

  @override
  String get widgetStreakStart =>
      'Lee las cinco de hoy para empezar una racha.';

  @override
  String get widgetFiveTitle => 'LAS CINCO DE HOY';

  @override
  String widgetFiveRead(int n) {
    return '$n de 5 leídas';
  }

  @override
  String get widgetFiveDone => 'Las cinco, leídas';

  @override
  String get widgetFiveWaiting => 'Te esperan cinco cartas nuevas';

  @override
  String get dayStreakCaps => 'DÍAS DE RACHA';

  @override
  String sourceLabel(String source) {
    return 'Fuente · $source';
  }

  @override
  String get perkArchiveTitle => 'Todo tu archivo';

  @override
  String get perkArchiveLine => 'Cada día que has leído, para siempre.';

  @override
  String get plusIsActive => 'ASTUTE+ ESTÁ ACTIVO';

  @override
  String tryFreeThen(int days, String price, String suffix) {
    return '$days días gratis, luego $price$suffix';
  }

  @override
  String subscribeFor(String price, String suffix) {
    return 'Suscríbete por $price$suffix';
  }

  @override
  String get noChargeTodayCancel => 'Sin cargo hoy · cancela cuando quieras';

  @override
  String get chargedTodayCancel => 'Se cobra hoy · cancela cuando quieras';

  @override
  String get everyCardForYouMark => 'ti.';

  @override
  String get trialStartedNoPayment =>
      'Prueba iniciada. No hay pago conectado en esta versión.';

  @override
  String get thatDidNotGoThrough => 'Eso no se completó.';

  @override
  String get plusIsBack => 'Astute+ ha vuelto.';

  @override
  String get nothingToRestore => 'Nada que restaurar en esta cuenta.';

  @override
  String get planYearly => 'Anual';

  @override
  String get planMonthly => 'Mensual';

  @override
  String get perYearShort => '/año';

  @override
  String get perMonthShort => '/mes';

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
  String get termsOfUse => 'Términos de uso';

  @override
  String get privacyPolicy => 'Privacidad';

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
  String get topLevel => 'Nivel máximo';

  @override
  String plusNToday(int n) {
    return '+$n hoy';
  }

  @override
  String get bySubject => 'Por materia';

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

  @override
  String get anonymousUsage => 'Datos de uso';

  @override
  String get anonymousUsageLine =>
      'Cómo se usa la app —qué se lee, se guarda y se dice, y qué falla— para que las próximas cartas sean mejores. Nunca tu nombre, tu correo ni lo que escribes.';

  @override
  String get usageOn => 'Compartidos, sin tu nombre ni tus palabras.';

  @override
  String get usageOff => 'Ya no se mide nada.';

  @override
  String get yourMix => 'Tu mezcla';

  @override
  String get genresLine =>
      'Toca un género para saltarlo. Mantenlo pulsado y las tres ramas de dentro se abren justo debajo.';

  @override
  String get insideGenre => 'Dentro';

  @override
  String nOfSixOn(int n, int total) {
    return '$n de $total activos';
  }

  @override
  String get offInYourMix => 'fuera de tu mezcla';

  @override
  String continueGenresOn(int on, int total) {
    return 'Continuar · $on de $total géneros activos';
  }

  @override
  String get mixRarely => 'Rara vez';

  @override
  String get mixSometimes => 'A veces';

  @override
  String get mixOften => 'A menudo';

  @override
  String get mixALot => 'Mucho';

  @override
  String get mixFull => 'Al máximo';

  @override
  String get forYouChip => 'PARA TI';

  @override
  String get againChip => 'DE NUEVO';

  @override
  String get magicLine =>
      'Cinco cartas al día elegidas para ti: de tu mezcla, a tu nivel, nunca una ya leída. Desde mañana.';

  @override
  String get everyCardForYou => 'Cada carta, elegida para ti.';

  @override
  String get perkOwnTitle => 'Cinco cartas al día, todas tuyas';

  @override
  String get perkOwnLine =>
      'De tus ramas, a tu nivel, nunca una ya leída. Gratis tienes dos al día.';

  @override
  String get plusCardHeadline => 'Las cinco, tuyas.';

  @override
  String get plusCardLine =>
      'Cinco cartas al día de tu mezcla, a tu nivel. Tu viaje. Todo tu archivo.';

  @override
  String get continueFree => 'Continuar gratis';

  @override
  String get archiveBeforeThisWeek => 'Antes de esta semana';

  @override
  String get weekKeptThreeOwn =>
      'Una semana seguida: mañana tres de las cinco son tuyas.';

  @override
  String get perkJourneyLine =>
      'Tu nivel, cada tema rama por rama, lo que se quedó, y la carta para contar esta noche.';

  @override
  String get topOfTheWeek => 'Top de la semana';

  @override
  String get topOfTheMonth => 'Top del mes';

  @override
  String topIn(String subject) {
    return 'Top en $subject';
  }

  @override
  String get topLineWeek =>
      'Las que más gustaron, se guardaron y se contaron en los últimos 7 días';

  @override
  String get topLineMonth =>
      'Las que más gustaron, se guardaron y se contaron en los últimos 30 días';

  @override
  String get topWeek => 'Semana';

  @override
  String get topMonth => 'Mes';

  @override
  String topReaders(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n lectores',
      one: '1 lector',
    );
    return '$_temp0';
  }

  @override
  String get topEmpty =>
      'Aún no hay nada en la lista. Cada carta que te gusta, guardas o cuentas suma.';

  @override
  String get readMark => 'Leída';

  @override
  String get lovedSinceTheStart => 'Las más queridas desde el principio';

  @override
  String lovedIn(String subject) {
    return 'Las más queridas en $subject';
  }

  @override
  String get lovedLine =>
      'Lo que más han guardado los lectores y tú aún no has leído';

  @override
  String get forYouShelf => 'Para ti';

  @override
  String get forYouLine => 'Lo que tu lectura pone primero';

  @override
  String get exploreOffline =>
      'Estás sin conexión. Esto es Explorar tal como se leyó por última vez.';

  @override
  String get askYourselfCaps => 'PREGÚNTATE';

  @override
  String get themeMyths => 'Mitos derribados';

  @override
  String get themeMythsLine => 'Lo que casi todos creen, y por qué es falso';

  @override
  String get themeParadoxes => 'Paradojas';

  @override
  String get themeParadoxesLine =>
      'Dos cosas ciertas que no deberían serlo a la vez';

  @override
  String get themeNumbers => 'Números que sorprenden';

  @override
  String get themeNumbersLine => 'Donde la cifra es el giro';

  @override
  String get themePractical => 'Para usar hoy';

  @override
  String get themePracticalLine => 'Algo que probar antes de esta noche';

  @override
  String get themeOrigins => 'De dónde viene';

  @override
  String get themeOriginsLine => 'El origen de cosas que usas cada día';

  @override
  String get themeStories => 'Historias reales';

  @override
  String get themeStoriesLine => 'Cosas que pasaron de verdad';

  @override
  String get themeDebates => 'Elige un bando';

  @override
  String get themeDebatesLine =>
      'No hay respuesta correcta, solo un argumento mejor';

  @override
  String get themeWorkItOut => 'Haz la cuenta';

  @override
  String get themeWorkItOutLine => 'Un número que sacar de cabeza';

  @override
  String get themeSeen => 'Para ver';

  @override
  String get themeSeenLine => 'Cartas que dibujan su idea';

  @override
  String get themeSharpest => 'Para los más agudos';

  @override
  String get themeSharpestLine => 'Las cartas más difíciles que hay';

  @override
  String get themePast0 => 'El mundo antiguo';

  @override
  String get themePast1 => 'Del siglo XVII al XIX';

  @override
  String get themePast2 => 'El siglo pasado';

  @override
  String get themePastLine => 'Una época distinta cada vez que vuelve';

  @override
  String get themePlace0 => 'Asia y Oriente Medio';

  @override
  String get themePlace1 => 'Las Américas';

  @override
  String get themePlace2 => 'Europa';

  @override
  String get themePlaceLine =>
      'Una parte del mundo distinta cada vez que vuelve';

  @override
  String get themeTrueOrFalse => '¿Verdadero o falso?';

  @override
  String get themeTrueOrFalseLine =>
      'Decide antes de girarla. Casi todos fallan';

  @override
  String get themeReasoning => 'Solo razonar';

  @override
  String get themeReasoningLine =>
      'Nada que memorizar: solo una forma de pensarlo';

  @override
  String get themeIdeas => 'Grandes ideas';

  @override
  String get themeIdeasLine =>
      'La teoría detrás de las cosas, una idea cada vez';

  @override
  String get themeCurious => 'Solo curiosidad';

  @override
  String get themeCuriousLine => 'Por el gusto de saber el porqué';

  @override
  String get themeMoving => 'En movimiento';

  @override
  String get themeMovingLine =>
      'Lo que está cambiando ahora, y por qué importa';

  @override
  String get themeHowItWorks => 'Cómo funciona de verdad';

  @override
  String get themeHowItWorksLine =>
      'El mecanismo detrás de algo que ves cada día';

  @override
  String get themePuzzles => 'Acertijos';

  @override
  String get themePuzzlesLine => 'Enigmas para un lápiz y un minuto';

  @override
  String get weekRecapCaps => 'ESTA SEMANA TE PREGUNTASTE';

  @override
  String get weekRecapLine => 'Las preguntas que te dejaron tus cartas';

  @override
  String weekRecapMore(int n) {
    return '$n más de tu semana con Plus';
  }

  @override
  String get plusInTheApp =>
      'Astute+ está en la app: descarga Astute en iPhone o Android para empezar tu prueba gratuita.';

  @override
  String get purchaseComplete => 'Compra completada.';

  @override
  String get successWelcome =>
      'Bienvenido a Astute+. Las cinco cartas de hoy están listas.';

  @override
  String successWelcomeNamed(String name) {
    return 'Bienvenido a Astute+, $name. Las cinco cartas de hoy están listas.';
  }

  @override
  String get successFiveCards => '5 cartas al día';

  @override
  String get successArchive => 'Todo el archivo';

  @override
  String successPlanName(String plan) {
    return 'Astute+ $plan';
  }

  @override
  String successFreeUntil(String date, String price, String suffix) {
    return 'Gratis hasta el $date, luego $price$suffix';
  }

  @override
  String successRenewsLine(String date, String price, String suffix) {
    return 'Se renueva el $date · $price$suffix';
  }

  @override
  String get successReceipt => 'Recibo';

  @override
  String get letsStart => 'Empecemos';

  @override
  String successFootFirstCharge(String date) {
    return 'Primer cargo el $date · cancela cuando quieras';
  }

  @override
  String successFootRenews(String date) {
    return 'Se renueva el $date · cancela cuando quieras';
  }

  @override
  String get tryToday => 'PRUÉBALO HOY';

  @override
  String minutesShort(int n) {
    return '$n MIN';
  }

  @override
  String get sideOr => 'o';

  @override
  String get nextStep => 'Siguiente paso';

  @override
  String get showAllSteps => 'Ver todo';

  @override
  String get revealSeePicture => 'Ver el dibujo';

  @override
  String get revealPlayScene => 'Pruébalo tú';

  @override
  String get revealBackToAnswer => 'Volver a la respuesta';

  @override
  String get revealShowWorking => 'Ver el razonamiento';

  @override
  String get sceneLockIn => 'CONFIRMAR';

  @override
  String get sceneYou => 'TÚ';

  @override
  String get sceneTruth => 'REAL';

  @override
  String get sceneTryAgain => 'Otra vez';

  @override
  String get sceneDrawHint => 'Dibuja tu apuesta con el dedo';

  @override
  String get sceneHoldHint => 'Mantén pulsado';

  @override
  String get sceneSwipeHint => 'Desliza o toca';

  @override
  String get sceneTapToPick => 'Toca tu elección';

  @override
  String get sceneShowMe => 'Muéstramelo';

  @override
  String get sceneYourGuess => 'Tu apuesta';

  @override
  String sceneNOfM(int n, int m) {
    return '$n de $m';
  }

  @override
  String get reportProblem => 'Informar de un problema';

  @override
  String get reportedThanks => 'Enviado. Gracias.';

  @override
  String get reportTitle => '¿Qué falla en esta tarjeta?';

  @override
  String get reportLead =>
      'Revisamos cada aviso con las fuentes y corregimos la tarjeta.';

  @override
  String get reportFact => 'Un dato es incorrecto';

  @override
  String get reportAnswer => 'La respuesta marcada como correcta está mal';

  @override
  String get reportSource => 'La fuente no lo respalda';

  @override
  String get reportUnclear => 'Es confuso';

  @override
  String get reportTypo => 'Una errata o una línea rota';

  @override
  String get reportOther => 'Otra cosa';

  @override
  String get reportNoteHint => 'Algo que nos ayude a comprobarlo (opcional)';

  @override
  String get reportSend => 'Enviar';

  @override
  String get reportSentToast => 'Gracias. Lo revisaremos.';

  @override
  String get journeyPointsOff => 'puntos de desvío';

  @override
  String journeyOffNotYet(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n respuestas más diciendo cuánto, y se mide.',
      one: 'Una respuesta más diciendo cuánto, y se mide.',
    );
    return '$_temp0';
  }

  @override
  String get journeyYourScore => 'Tu puntuación';

  @override
  String journeyPointsUnit(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'puntos',
      one: 'punto',
    );
    return '$_temp0';
  }

  @override
  String journeyGainedIn(String n) {
    return '+$n en 4 semanas';
  }

  @override
  String journeyWeekSoFar(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'En lo que va de semana, has ganado $n puntos.',
      one: 'En lo que va de semana, has ganado 1 punto.',
    );
    return '$_temp0';
  }

  @override
  String journeyWeekOf(int n, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'La semana del $date ganaste $n puntos.',
      one: 'La semana del $date ganaste 1 punto.',
    );
    return '$_temp0';
  }

  @override
  String journeyCards(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n tarjetas',
      one: '1 tarjeta',
    );
    return '$_temp0';
  }

  @override
  String journeyScoreCaption(String date) {
    return 'Tu puntuación al final de cada semana desde el $date. Toca un punto para ver esa semana.';
  }

  @override
  String journeyLevelOf(int n, int of) {
    return 'Nivel $n de $of';
  }

  @override
  String journeyStepFrom(String what, String rung) {
    return '$what\npara $rung';
  }

  @override
  String journeyToGoCards(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n tarjetas',
      one: '1 tarjeta',
    );
    return '$_temp0';
  }

  @override
  String journeyToGoAnswers(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n respuestas',
      one: '1 respuesta',
    );
    return '$_temp0';
  }

  @override
  String journeyToGoSure(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n respuestas diciendo cuánto',
      one: '1 respuesta diciendo cuánto',
    );
    return '$_temp0';
  }

  @override
  String journeyToGoHeld(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n tarjetas retenidas',
      one: '1 tarjeta retenida',
    );
    return '$_temp0';
  }

  @override
  String journeyToGoPoints(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n puntos',
      one: '1 punto',
    );
    return '$_temp0';
  }

  @override
  String get journeyWorth => 'Lo que vale';

  @override
  String journeyBooks(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n libros',
      one: '1 libro',
    );
    return '$_temp0';
  }

  @override
  String journeyOrDocumentaries(int h) {
    return 'o $h h de documentales';
  }

  @override
  String journeyToFirstBook(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'faltan $n para el primer libro',
      one: 'falta 1 para el primer libro',
    );
    return '$_temp0';
  }

  @override
  String get journeyInARow => 'Seguidos';

  @override
  String journeyDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n días',
      one: '1 día',
    );
    return '$_temp0';
  }

  @override
  String journeyBestActive(int best, int active, int days) {
    return 'Récord $best · $active de $days';
  }

  @override
  String journeySubjectsOf(int n, int of) {
    return '$n de $of';
  }

  @override
  String journeySubjectsDashed(String month) {
    return 'temas · a trazos: $month';
  }

  @override
  String get journeySubjects => 'temas';

  @override
  String get journeyHowHard => 'Dificultad';

  @override
  String get journeyOfThree => 'de 3';

  @override
  String get journeyHardNow => 'Las tarjetas que abres.';

  @override
  String journeyHardThen(String v, String month) {
    return 'Las tarjetas que abres. $v en $month';
  }

  @override
  String get journeyReadingTime => 'Tiempo de lectura';

  @override
  String journeyHoursMinutes(int h, String m) {
    return '$h h $m';
  }

  @override
  String journeyMinutes(int m) {
    return '$m min';
  }

  @override
  String journeyMinAWeek(int now, int was) {
    return '$now min a la semana, antes $was';
  }

  @override
  String journeyMinThisWeek(int m) {
    return '$m min esta semana';
  }

  @override
  String get journeyTimedFromToday => 'Se cuenta desde hoy';

  @override
  String journeyPointsOffFrom(int was) {
    return 'puntos de desvío, antes $was';
  }

  @override
  String journeyRungOrLess(String rung, int n) {
    return '$rung · $n o menos';
  }

  @override
  String get journeyRightWhenSure => 'Acierto si estás seguro';

  @override
  String journeyFromIn(String v, String month) {
    return 'Era el $v en $month';
  }

  @override
  String get journeySureNone => 'Todavía no has dicho 80 % o más';

  @override
  String get journeyMovesTitle => 'Trucos que detectas';

  @override
  String journeyOfN(int n) {
    return 'de $n';
  }

  @override
  String journeyNewest(String name) {
    return 'Último: $name';
  }

  @override
  String get journeyNoneYet => 'Todavía nada';

  @override
  String journeyStillWithYou(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'tarjetas aún contigo',
      one: 'tarjeta aún contigo',
    );
    return '$_temp0';
  }

  @override
  String journeyRecallDays(int right, int of, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days días',
      one: 'un día',
    );
    return '$right de $of tras $_temp0';
  }

  @override
  String journeyRecallWeeks(int right, int of, int weeks) {
    String _temp0 = intl.Intl.pluralLogic(
      weeks,
      locale: localeName,
      other: '$weeks semanas',
      one: 'una semana',
    );
    return '$right de $of tras $_temp0';
  }

  @override
  String journeyActiveDays(int active, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days días',
      one: '1 día',
    );
    return '$active de $_temp0';
  }

  @override
  String get journeyMostlyMorning => 'Sobre todo por la mañana';

  @override
  String get journeyMostlyAfternoon => 'Sobre todo por la tarde';

  @override
  String get journeyMostlyEvening => 'Sobre todo por la noche';

  @override
  String get journeyMostlyNight => 'Sobre todo de madrugada';

  @override
  String get journeyInTime => 'En el tiempo';

  @override
  String journeyYears(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '$nString años';
  }

  @override
  String journeyFromEra(String era) {
    return 'desde $era hasta hoy';
  }

  @override
  String get journeyEraAncient => 'la Antigüedad';

  @override
  String get journeyEraMedieval => 'la Edad Media';

  @override
  String get journeyEraEarlyModern => 'el siglo XVI';

  @override
  String get journeyEraNineteenth => 'el siglo XIX';

  @override
  String get journeyEraTwentieth => 'el siglo XX';

  @override
  String get journeyEraRecent => '2000';

  @override
  String get journeyNothingDated => 'nada con fecha todavía';

  @override
  String get journeyInPlace => 'En el mundo';

  @override
  String journeyRegions(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n regiones',
      one: '1 región',
    );
    return '$_temp0';
  }

  @override
  String journeyPlacesAndSpace(String list) {
    return '$list y el espacio';
  }

  @override
  String get journeyRegionAmericas => 'América';

  @override
  String get journeyRegionEurope => 'Europa';

  @override
  String get journeyRegionAsia => 'Asia';

  @override
  String get journeyRegionOceania => 'Oceanía';

  @override
  String get journeyRegionAfrica => 'África';

  @override
  String get journeyRegionMiddleEast => 'Oriente Medio';

  @override
  String get journeyNoPlace => 'ningún lugar todavía';

  @override
  String get journeyTopics => 'Subtemas';

  @override
  String journeyMet(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n descubiertos',
      one: '1 descubierto',
    );
    return '$_temp0';
  }

  @override
  String journeyTopicsMost(int n, String subject) {
    return '$n de ellos en $subject';
  }

  @override
  String get journeyWords => 'Palabras';

  @override
  String journeyNew(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n nuevas',
      one: '1 nueva',
    );
    return '$_temp0';
  }

  @override
  String get aMove => 'Una jugada';

  @override
  String get anotherOne => 'Otra';

  @override
  String answerIs(String said) {
    return 'Respuesta: $said';
  }

  @override
  String get answeredAlready => 'Ya respondida';

  @override
  String get anyCard => 'Cualquier tema, cualquier estantería, una tarjeta';

  @override
  String betN(int n) {
    return 'Apostar $n';
  }

  @override
  String get betSlip => 'Tu boleto';

  @override
  String get betWord => 'Apostar';

  @override
  String get biggerLabel => 'Mayor';

  @override
  String get biggerNote => 'Cada cifra es la respuesta de una tarjeta.';

  @override
  String biggerScore(int right, int asked) {
    return 'Acertaste $right de $asked.';
  }

  @override
  String get biggerYouGotIt => 'Mayor · acertaste';

  @override
  String cameBackAfterDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Después de $n días',
      one: 'Después de un día',
    );
    return '$_temp0';
  }

  @override
  String get cameBackAfterWeek => 'Después de una semana';

  @override
  String cameBackAfterWeeks(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Después de $n semanas',
      one: 'Después de una semana',
    );
    return '$_temp0';
  }

  @override
  String get check => 'Comprobar';

  @override
  String closerDone(String said, int right, int steps) {
    return 'Es $said. Acertaste $right de $steps.';
  }

  @override
  String closerNoLess(String v) {
    return 'No: es menos de $v.';
  }

  @override
  String closerNoMore(String v) {
    return 'No: es más de $v.';
  }

  @override
  String get closerStart => 'Tres pasos para acercarte.';

  @override
  String closerYesLess(String v) {
    return 'Bien: es menos de $v.';
  }

  @override
  String closerYesMore(String v) {
    return 'Bien: es más de $v.';
  }

  @override
  String get corrections => 'Fe de erratas';

  @override
  String get didYouKnow => '¿Lo sabías?';

  @override
  String get didYouKnowLine =>
      'Dale la vuelta y luego: ¿nuevo para ti, o ya lo sabías?';

  @override
  String get dragToSet => 'Arrastra para fijar';

  @override
  String get dykAgain => 'Otra vez';

  @override
  String dykKnew(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Sabías $n',
      one: 'Sabías 1',
      zero: 'No sabías ninguna',
    );
    return '$_temp0';
  }

  @override
  String dykNew(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n nuevas para ti',
      one: '1 nueva para ti',
      zero: 'Nada nuevo hoy',
    );
    return '$_temp0';
  }

  @override
  String get editionEnd => 'Esta es la edición de hoy';

  @override
  String get editionTomorrow => 'La de mañana sale por la mañana';

  @override
  String get eraAncient => 'El mundo antiguo';

  @override
  String get eraAncientWhen => 'Antes del 500';

  @override
  String get eraEarlyModern => 'La Edad Moderna';

  @override
  String get eraEarlyModernWhen => 'De 1500 a 1800';

  @override
  String get eraMedieval => 'La Edad Media';

  @override
  String get eraMedievalWhen => 'Del 500 al 1500';

  @override
  String eraMore(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n más de esta época',
      one: '1 más de esta época',
    );
    return '$_temp0';
  }

  @override
  String get eraNineteenth => 'El siglo XIX';

  @override
  String get eraNineteenthWhen => 'De 1800 a 1900';

  @override
  String get eraRecent => 'Este siglo';

  @override
  String get eraRecentWhen => 'Desde 2000';

  @override
  String get eraRulerNow => 'Ahora';

  @override
  String get eraRulerOld => 'Antigüedad';

  @override
  String get eraShortAncient => 'Antigüedad';

  @override
  String get eraShortEarlyModern => '1500–1800';

  @override
  String get eraShortMedieval => 'Edad Media';

  @override
  String get eraShortNineteenth => 'Siglo XIX';

  @override
  String get eraShortRecent => 'Siglo XXI';

  @override
  String get eraShortTwentieth => 'Siglo XX';

  @override
  String get eraTwentieth => 'El siglo pasado';

  @override
  String get eraTwentiethWhen => 'De 1900 a 2000';

  @override
  String get fewCards => 'En unas pocas tarjetas';

  @override
  String get fewCardsLine => 'Cuando una sola tarjeta no basta para explicarlo';

  @override
  String get firstLabel => 'Desde';

  @override
  String get forYouNow => 'Para ti, ahora';

  @override
  String get goNarrow => 'Ve estrecho cuando estés seguro: paga el triple.';

  @override
  String get hardBadge => 'Difícil';

  @override
  String hidesIn(String where) {
    return 'En $where';
  }

  @override
  String get howSure => '¿Qué tan seguro estoy, y por qué?';

  @override
  String get inNumbers => 'En cifras';

  @override
  String inRange(int pts, String said) {
    return 'Dentro: +$pts puntos. Es $said.';
  }

  @override
  String inYourMoves(int n) {
    return 'En tus jugadas · $n×';
  }

  @override
  String itIs(String said) {
    return 'Es $said.';
  }

  @override
  String get knewIt => 'Lo sabía';

  @override
  String get less => 'Menos';

  @override
  String get lookFirst => 'Mira el gráfico antes de creerte el titular.';

  @override
  String get markTried => 'Hecho';

  @override
  String minutesLabel(int n) {
    return '$n min';
  }

  @override
  String missedRange(String said) {
    return 'Fallaste: es $said.';
  }

  @override
  String get modeBigger => '¿Cuál es mayor?';

  @override
  String get modeBiggerLine => 'Dos cifras que puedes deducir. Toca la mayor';

  @override
  String get modeCloser => 'Cada vez más cerca';

  @override
  String get modeCloserLine =>
      'Tres pasos de más o menos para acercarte al número';

  @override
  String get modePick => 'Elige una';

  @override
  String get modePickLine => 'Tres cifras. Decide antes de abrir la tarjeta';

  @override
  String get modeRange => 'Apuesta a un rango';

  @override
  String get modeRangeLine => 'Cuanto más estrecho, más paga, si aciertas';

  @override
  String get modeSlide => 'Muévelo';

  @override
  String get modeSlideLine =>
      'Primero fija tu respuesta y luego mira cuánto te has desviado';

  @override
  String get modeStake => 'Haz tu apuesta';

  @override
  String modeStakeLine(int n) {
    return '$n puntos al día. Si ganas, doblas tu apuesta';
  }

  @override
  String get monthShelfLine => 'Un tema nuevo cada mes, igual para todos';

  @override
  String moodMeta(int cards, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      cards,
      locale: localeName,
      other: '$cards tarjetas',
      one: '1 tarjeta',
    );
    return '$_temp0 · $minutes min';
  }

  @override
  String get moodTime => 'El tiempo que tienes';

  @override
  String get moodTitle => 'Tu ánimo, tus minutos';

  @override
  String get moodTone => 'Tono';

  @override
  String get more => 'Más';

  @override
  String moreOrLess(String v) {
    return '¿Más o menos de $v?';
  }

  @override
  String get moveComparedToWhat => 'Comparado con qué';

  @override
  String get moveComparedToWhatLine =>
      'Un cambio no significa nada sin un grupo de control';

  @override
  String get moveSampling => 'La muestra';

  @override
  String get moveSamplingLine =>
      'Quién acaba en la muestra decide lo que puede decir';

  @override
  String mythDeckHint(int at, int of) {
    return '$at de $of · desliza para pasarla';
  }

  @override
  String nOfM(int at, int of) {
    return '$at de $of';
  }

  @override
  String get newMove => 'Nueva para ti';

  @override
  String get newToMe => 'Nuevo para mí';

  @override
  String get notEnoughPoints => 'No tienes puntos suficientes';

  @override
  String get notSureLine => 'Una tarjeta de cualquier rincón de Astute';

  @override
  String get notSureTitle => '¿No sabes por dónde empezar?';

  @override
  String get openWord => 'Abrir';

  @override
  String get pickOneFirst => 'Elige una primero';

  @override
  String pointsToday(int n) {
    return '+$n hoy';
  }

  @override
  String get puzzleOfTheDay => 'El acertijo del día';

  @override
  String rangeWidth(int w, int pts) {
    return '±$w · $pts pts';
  }

  @override
  String get rightLastTime => 'Acertada la última vez';

  @override
  String get sameForEveryoneCaps => 'Igual para todos';

  @override
  String get sayFalse => 'Falso';

  @override
  String get sayTrue => 'Verdadero';

  @override
  String get seriesAnchors => 'Primeras impresiones';

  @override
  String get seriesGrowth => 'Números que se desbocan';

  @override
  String seriesMeta(int n, int m) {
    return '$n tarjetas · unos $m min';
  }

  @override
  String get seriesOdds => 'Probabilidades que engañan';

  @override
  String get seriesRetold => 'La historia, contada otra vez';

  @override
  String seriesStrand(String name) {
    return '$name, en unas pocas tarjetas';
  }

  @override
  String get seriesStudies => 'Por qué los estudios engañan';

  @override
  String showAllN(int n) {
    return 'Mostrar las $n';
  }

  @override
  String get showFewer => 'Mostrar menos';

  @override
  String get sixtyAgain => 'Jugar otra vez';

  @override
  String sixtyIn(int s) {
    return 'en $s segundos';
  }

  @override
  String get sixtyLine =>
      'Ocho verdadero o falso. Déjate llevar por la intuición';

  @override
  String get sixtyPerfect => 'Las ocho bien.';

  @override
  String sixtyScore(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n bien hasta ahora',
      one: '1 bien hasta ahora',
      zero: 'Ninguna bien todavía',
    );
    return '$_temp0';
  }

  @override
  String get sixtySecondsFor => 'segundos para ocho\nverdadero o falso';

  @override
  String sixtySecondsLeft(int s) {
    return '$s s';
  }

  @override
  String get sixtyStart => 'Empezar';

  @override
  String get sixtyTimeUp => 'antes de que se acabara el tiempo';

  @override
  String get sixtyTitle => 'Sesenta segundos';

  @override
  String slideAverage(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'De media, $n puntos de diferencia.',
      one: 'De media, 1 punto de diferencia.',
      zero: 'De media, exacto.',
    );
    return '$_temp0';
  }

  @override
  String get slideNote =>
      'Fíjalo, compruébalo. Lo que cuenta es cuánto te desvías.';

  @override
  String slideOff(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Te desviaste $n puntos.',
      one: 'Te desviaste 1 punto.',
      zero: 'Exacto.',
    );
    return '$_temp0';
  }

  @override
  String get slipEmpty =>
      'Aún no hay apuestas. Cada una que hagas aparecerá aquí.';

  @override
  String get stakeLabel => 'Apuesta';

  @override
  String stepOf(int at, int of) {
    return 'Paso $at de $of';
  }

  @override
  String get surpriseMe => 'Sorpréndeme';

  @override
  String get tapIfBigger => 'Toca si es mayor';

  @override
  String get tapToTurn => 'Toca para darle la vuelta';

  @override
  String get tfRight => 'Correcto. Ábrela para saber por qué.';

  @override
  String tfWrong(String side) {
    return 'Es $side. Ábrela para saber por qué.';
  }

  @override
  String theAnswer(String said) {
    return 'La respuesta: $said.';
  }

  @override
  String get theAstute => 'The Astute';

  @override
  String get theLead => 'Apertura';

  @override
  String get throughTime => 'A través del tiempo';

  @override
  String get throughTimeLine =>
      'Del mundo antiguo a este año. Arrastra para viajar';

  @override
  String get todayLabel => 'Hoy';

  @override
  String get todaysEdition => 'Edición de hoy';

  @override
  String get toneCurious => 'Curioso';

  @override
  String get toneLight => 'Ligero';

  @override
  String get toneSerious => 'Serio';

  @override
  String get toneTough => 'Difícil';

  @override
  String get unmaskBack => 'Muéstralo como se publicó';

  @override
  String get unmaskFlipped => 'Ponlo del derecho';

  @override
  String get unmaskLine => 'Mismos números, otra imagen';

  @override
  String get unmaskStretched => 'Usa una escala justa';

  @override
  String get unmaskTitle => 'Desenmascara el gráfico';

  @override
  String get unmaskTotals => 'Haz justa la comparación';

  @override
  String get unmaskTruncated => 'Empieza el eje en cero';

  @override
  String get unmaskWindow => 'Muestra la serie completa';

  @override
  String get whatIfTrue => '¿Y si fuera verdad?';

  @override
  String get whatIfTrueLine =>
      'Tarjetas que siguen trabajando después de cerrarlas';

  @override
  String get whatYouBelieve => 'Lo que crees';

  @override
  String get wrongLastTime => 'Fallada la última vez';

  @override
  String youLose(int n) {
    return 'Pierdes $n.';
  }

  @override
  String youWin(int n) {
    return 'Ganas $n.';
  }

  @override
  String get yourPick => 'Tu elección';
}

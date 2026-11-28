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
  String get freezeKeptStreak => 'Un comodín salvó la racha';

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
  String dayTitle(int n) {
    return 'Día $n';
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
  String get saveThisPill => 'Guardar esta tarjeta';

  @override
  String get shareThisPill => 'Compartir esta tarjeta';

  @override
  String get share => 'Compartir';

  @override
  String cardOf(int k, int n) {
    return 'Tarjeta $k de $n';
  }

  @override
  String tomorrowsFiveOpenIn(String when) {
    return 'Las cinco de mañana · en $when';
  }

  @override
  String topicOpensTomorrow(String topic, String when) {
    return 'Mañana: $topic · en $when';
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
    return 'Todavía nada para «$query».';
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
      'Ninguna tarjeta coincide aún con ese filtro.';

  @override
  String nothingForTryTopic(String query) {
    return 'Nada para «$query». Prueba con un tema.';
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
  String get backToTodaysFive => 'Volver a las cinco de hoy';

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
    return 'Estabas seguro al $n%';
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
  String scoreLevel(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'curiosity': 'Curiosidad',
      'observation': 'Observación',
      'method': 'Método',
      'judgement': 'Criterio',
      'insight': 'Perspicacia',
      'discernment': 'Discernimiento',
      'acumen': 'Sagacidad',
      'other': '$id',
    });
    return '$_temp0';
  }

  @override
  String get levelUpTitle => 'Nuevo nivel';

  @override
  String levelUpGain(String skill, String n) {
    return 'Lo que más creció esta semana: $skill, $n';
  }

  @override
  String levelUpAnswers(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n respuestas hasta ahora.',
      one: 'Una respuesta hasta ahora.',
    );
    return '$_temp0';
  }

  @override
  String get levelLabel => 'Nivel';

  @override
  String levelPointsTo(int n, String level) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n puntos para $level',
      one: '1 punto para $level',
    );
    return '$_temp0';
  }

  @override
  String levelAnswersTo(int n, String level) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n respuestas para $level',
      one: '1 respuesta para $level',
    );
    return '$_temp0';
  }

  @override
  String get levelTop => 'El nivel más alto';

  @override
  String get levelShareTitle => 'Comparte tu nivel';

  @override
  String get signOutQuestion => '¿Cerrar sesión?';

  @override
  String get signOutBody =>
      'Tu racha, tus tarjetas guardadas y tu historial se quedan en tu cuenta. Esto los borra de este dispositivo.';

  @override
  String get deleteAccount => 'Eliminar cuenta';

  @override
  String get deletingAccount => 'Eliminando tu cuenta…';

  @override
  String get deleteAccountQuestion => '¿Eliminar tu cuenta?';

  @override
  String deleteAccountBody(String store) {
    String _temp0 = intl.Intl.selectLogic(store, {
      'apple': 'la suscripción se gestiona en los ajustes del App Store.',
      'google': 'la suscripción se gestiona en Google Play, en Pagos y suscripciones.',
      'other': 'la suscripción se gestiona en la tienda donde la compraste.',
    });
    return 'Tu cuenta y su copia de seguridad se eliminan para siempre, y este dispositivo vuelve a empezar desde el principio. Esto no cancela Astute+: $_temp0';
  }

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
      'Borra todo en este dispositivo (racha, tarjetas guardadas, respuestas, tu historial de juicios, temas y plan) y vuelve a abrir la introducción.';

  @override
  String get wipeIt => 'Borrar';

  @override
  String get yourRecord => 'Tu historial';

  @override
  String get profileTodayFive => 'Las cinco de hoy';

  @override
  String profileTodayOf(int read, int of) {
    return '$read de $of';
  }

  @override
  String profileTodayToRead(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n por leer',
      one: '1 por leer',
    );
    return '$_temp0';
  }

  @override
  String get profileJourneyScores => 'Todas tus puntuaciones, semana a semana';

  @override
  String profileInARowLabel(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'días seguidos',
      one: 'día seguido',
    );
    return '$_temp0';
  }

  @override
  String get profileWeekTitle => 'Últimos 7 días';

  @override
  String profileWeekPoints(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'puntos',
      one: 'punto',
    );
    return '$_temp0';
  }

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
      'Tus 5 tarjetas, antes del primer café.';

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
  String get yourCards => 'Tus tarjetas';

  @override
  String get emptyLikedHint => 'Mantén pulsada una tarjeta que te guste';

  @override
  String get emptySavedHint => 'Toca el marcador de una tarjeta';

  @override
  String get lastSevenDays => 'Últimos 7 días';

  @override
  String get accountSection => 'Cuenta';

  @override
  String get aboutSection => 'Acerca de';

  @override
  String get manageSubscription => 'Gestionar suscripción';

  @override
  String get howPillsAreWritten => 'Cómo se escriben las tarjetas';

  @override
  String get howTitle => 'Cada tarjeta de aquí la escribe un modelo de IA.';

  @override
  String get howIntro =>
      'Preferimos decirlo de entrada antes de que lo descubras tú. Así llega una tarjeta hasta ti.';

  @override
  String get howStep1Title => 'Escrita antes, por un modelo';

  @override
  String get howStep1Line =>
      'Cada tarjeta sigue un solo encargo: una pregunta que merece la pena, una respuesta que explica el porqué y una jugada que puedes volver a usar.';

  @override
  String get howStep2Title => 'Con sus fuentes, y leída por un crítico';

  @override
  String get howStep2Line =>
      'Cada tarjeta dice de dónde vienen sus datos, y tres de cada cuatro llevan al original con un toque, para que puedas comprobarlo tú. La mayoría las lee un segundo modelo que hace de crítico, y lo que no puede confirmar va a una lista que revisa una persona. Esa lista aún no está vacía.';

  @override
  String get howStep3Title => 'Cinco, repartidas cada mañana';

  @override
  String get howStep3Line =>
      'De los temas que elegiste, tarjetas que aún no has leído. Una que acertaste vuelve más adelante, para ver si se te quedó.';

  @override
  String get howStep4Title => 'Los lectores la mantienen honesta';

  @override
  String get howStep4Line =>
      'Cuando suficientes lectores dicen que una tarjeta está mal, deja de repartirse hasta que una persona la revisa.';

  @override
  String get howReportTitle => '¿Has encontrado un error?';

  @override
  String get howReportLine =>
      'Toca la banderita junto a la fuente de una tarjeta para denunciarla.';

  @override
  String get howFoot =>
      'Leemos cada aviso, y preferimos corregir una tarjeta antes que defenderla.';

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
  String get shareMyRecord => 'Compartir mi historial';

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
  String get seeThePlans => 'Ver los planes';

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
      other: 'tarjetas leídas',
      one: 'tarjeta leída',
    );
    return '$_temp0';
  }

  @override
  String nPillsRead(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n tarjetas leídas',
      one: '1 tarjeta leída',
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
      other: '$n comodines disponibles',
      one: '1 comodín disponible',
    );
    return '$_temp0';
  }

  @override
  String get freePlan => 'Plan gratuito';

  @override
  String get welcomeBack => 'Bienvenido de nuevo';

  @override
  String get comebackTitle => 'Qué bien verte de nuevo.';

  @override
  String get comebackStillYours => 'Sigue siendo tuyo';

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
  String get reminderAskTitle => '¿Cuándo quieres que te avisemos?';

  @override
  String get reminderAskLine =>
      'Una notificación al día, con una pregunta de tus tarjetas.';

  @override
  String get reminderAskTrialLine =>
      'Te avisaremos dos días antes de que termine tu prueba gratuita.';

  @override
  String get reminderAskMorning => 'Por la mañana';

  @override
  String get reminderAskLunch => 'A mediodía';

  @override
  String get reminderAskEvening => 'Por la tarde';

  @override
  String get reminderAskOther => 'Otra hora';

  @override
  String get reminderAskPick => 'Tú eliges';

  @override
  String get reminderAskUsual => 'Cuando sueles leer';

  @override
  String get reminderAskYes => 'Avísame';

  @override
  String get reminderAskNotNow => 'Ahora no';

  @override
  String get placeAskTitle => 'Tarjetas sobre el lugar donde vives';

  @override
  String get placeAskLine =>
      'De vez en cuando, Astute te repartirá una tarjeta sobre el lugar donde vives — su historia, su ciencia, sus sorpresas.';

  @override
  String get placeOnlyCity =>
      'Solo se guarda tu ciudad, nunca tu ubicación exacta.';

  @override
  String get placeAskPreviewLine => 'Cerca de ti · Módena';

  @override
  String get placeAskPreviewQuestion =>
      'La Ghirlandina está inclinada. ¿Cuánto?';

  @override
  String get placeAskYes => 'Usar mi ubicación';

  @override
  String get placeAskNotNow => 'Ahora no';

  @override
  String get placeRowTitle => 'Dónde vives';

  @override
  String get placeRowOff => 'Desactivado';

  @override
  String get placeRowOffLine =>
      'Actívalo para recibir tarjetas sobre el lugar donde vives.';

  @override
  String get placeSwitchOn => 'Activar';

  @override
  String get placeUseNow => 'Usar mi ubicación ahora';

  @override
  String get placeRemove => 'Quitar';

  @override
  String placeSetTo(String place) {
    return 'Dónde vives: $place';
  }

  @override
  String get placeRemoved => 'Quitado. Astute ya no guarda dónde vives.';

  @override
  String get placeNotFound =>
      'Ahora mismo no se ha podido saber dónde estás. Astute lo volverá a intentar otro día.';

  @override
  String get placeDeniedNote =>
      'No pasa nada. Puedes activarlo en Perfil cuando quieras.';

  @override
  String get placeServicesOff =>
      'La ubicación está desactivada en este teléfono. Actívala en los ajustes y vuelve a intentarlo.';

  @override
  String get placeNotHere => 'Este dispositivo no puede decir dónde estás.';

  @override
  String get placeSettingsTitle => 'La ubicación está desactivada para Astute';

  @override
  String get placeSettingsBody =>
      'Para recibir tarjetas sobre el lugar donde vives, permite que Astute use tu ubicación en los ajustes. Solo se guarda tu ciudad.';

  @override
  String get placeSettingsOpen => 'Abrir ajustes';

  @override
  String trialWarningTitle(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Tu prueba gratuita de Astute+ termina dentro de $days días.',
      one: 'Tu prueba gratuita de Astute+ termina mañana.',
      zero: 'Tu prueba gratuita de Astute+ termina hoy.',
    );
    return '$_temp0';
  }

  @override
  String trialWarningBody(String date, String price, String path) {
    return 'El $date empieza tu año de suscripción por $price. Para seguir, no tienes que hacer nada. Para cancelar: $path.';
  }

  @override
  String trialEndsNotice(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Tu prueba gratuita termina dentro de $days días',
      one: 'Tu prueba gratuita termina mañana',
      zero: 'Tu prueba gratuita termina hoy',
    );
    return '$_temp0';
  }

  @override
  String get trialNoticeManage => 'Gestionar';

  @override
  String subjectsInTheMix(int n, int total) {
    return '$n de $total temas en la mezcla';
  }

  @override
  String get everythingIsInDrag =>
      'Está todo dentro. Desliza un tema hacia la izquierda para ver menos, o hasta el final para quitarlo.';

  @override
  String get next => 'Siguiente';

  @override
  String get whatShouldWeTalkAbout => '¿De qué hablamos?';

  @override
  String get fivePillsADayPick =>
      'Cinco tarjetas al día, nuevas cada mañana. Elige los temas que quieres en la mezcla; puedes cambiarlos después.';

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
      'Entiende el porqué de las cosas y cuánto puedes fiarte de lo que sabes';

  @override
  String get introTopicsTitle => 'Veinte temas, cinco tarjetas';

  @override
  String get introTopicsLine =>
      'Escritas antes por un modelo, y cada una cita su fuente.';

  @override
  String get introQuestionTitle =>
      'Una pregunta, cuánta seguridad, luego el porqué';

  @override
  String get introQuestionLine =>
      'Primero di cuánta seguridad tienes. Con el tiempo verás cuánto vale tu «seguro».';

  @override
  String get introMixTitle => 'Tú eliges la mezcla';

  @override
  String get introMixLine => 'Baja un tema para ver menos, o apágalo del todo.';

  @override
  String get introThirtyTitle => 'Dos minutos al día';

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
  String get startReading => 'Empezar a leer';

  @override
  String get haveAnAccount => '¿Ya tienes cuenta?';

  @override
  String get signInLink => 'Inicia sesión';

  @override
  String get signInWelcomeTitle => 'Hola de nuevo';

  @override
  String get signInWelcomeLine =>
      'Inicia sesión y tu racha, tus tarjetas guardadas y tu historial vuelven contigo.';

  @override
  String get keepStreakOnNewPhone => 'Lleva tu racha a un móvil nuevo';

  @override
  String get keepStreakTitle => 'No pierdas tu racha';

  @override
  String get keepStreakLine =>
      'Inicia sesión y un móvil nuevo seguirá donde lo deja este: tu racha, tus tarjetas guardadas, tu historial.';

  @override
  String get signInNotNow => 'Ahora no';

  @override
  String subjectName(String topic) {
    String _temp0 = intl.Intl.selectLogic(topic, {
      'thinking': 'Pensamiento',
      'science': 'Ciencia',
      'maths': 'Matemáticas',
      'space': 'Espacio',
      'psychology': 'Psicología',
      'economics': 'Economía',
      'technology': 'Tecnología',
      'history': 'Historia',
      'human_body': 'Cuerpo humano',
      'philosophy': 'Filosofía',
      'pop_culture': 'Cultura pop',
      'nature': 'Naturaleza',
      'language': 'Lenguaje',
      'weird_facts': 'Rarezas',
      'sport': 'Deporte',
      'cinema': 'Cine',
      'music': 'Música',
      'art': 'Arte',
      'medicine': 'Medicina',
      'food': 'Comida',
      'life': 'Vida',
      'other': '$topic',
    });
    return '$_temp0';
  }

  @override
  String get cardsInEnglishNote =>
      'Por ahora, las tarjetas están en inglés; la app habla tu idioma.';

  @override
  String termsLine(String terms, String privacy) {
    return 'Al continuar aceptas nuestros $terms y la $privacy';
  }

  @override
  String get termsLineTerms => 'Términos de uso';

  @override
  String get termsLinePrivacy => 'Política de privacidad';

  @override
  String get skip => 'Saltar';

  @override
  String get tapToRevealLower => 'toca para descubrir';

  @override
  String get barMoveCaps => 'LO QUE TE LLEVAS';

  @override
  String get widgetFootPlain => 'Cinco tarjetas, dos minutos.';

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
  String get widgetFiveWaiting => 'Te esperan cinco tarjetas nuevas';

  @override
  String get widgetShelfTitle => 'LA ESTANTERÍA DE HOY';

  @override
  String get widgetShelfFrom => 'De la estantería de hoy';

  @override
  String get dayStreakCaps => 'DÍAS DE RACHA';

  @override
  String sourceLabel(String source) {
    return 'Fuente · $source';
  }

  @override
  String sourceLabelKind(String kind, String source) {
    return '$kind · $source';
  }

  @override
  String deeperFootLabel(String source) {
    return 'Profundiza. Fuente: $source';
  }

  @override
  String get sourceKindPaper => 'Estudio';

  @override
  String get sourceKindBook => 'Libro';

  @override
  String get sourceKindInstitution => 'Institución';

  @override
  String get sourceKindDocument => 'Documento';

  @override
  String get sourceKindData => 'Datos';

  @override
  String get sourceKindReference => 'Obra de referencia';

  @override
  String get sourceKindNews => 'Periódico';

  @override
  String get sourceKindCompany => 'Fuente de la empresa';

  @override
  String get sourceKindStandard => 'Norma técnica';

  @override
  String get sourceKindArithmetic => 'Cálculo';

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
  String get paywallRecordTitle => 'Descubre cuánto sabes de verdad.';

  @override
  String get paywallRecordMark => 'de verdad.';

  @override
  String get paywallRecordLine =>
      'Cada día dices cuánta seguridad tienes. Astute+ te muestra si se cierra la brecha entre seguridad y acierto, y las jugadas que sigues fallando.';

  @override
  String paywallRecordOver(int sure, int right) {
    return 'Dices tener un $sure% de seguridad y aciertas el $right% de las veces. Astute+ te muestra si esa brecha se cierra, y las jugadas que sigues fallando.';
  }

  @override
  String paywallRecordUnder(int sure, int right) {
    return 'Dices tener un $sure% de seguridad y aciertas el $right% de las veces: sabes más de lo que crees. Astute+ te muestra si esa brecha se cierra.';
  }

  @override
  String paywallRecordEven(int sure, int right) {
    return 'Dices tener un $sure% de seguridad y aciertas el $right% de las veces: casi a la par. Astute+ te muestra si se mantiene, y las jugadas que sigues fallando.';
  }

  @override
  String get paywallOutcomeTitle => 'Que nadie te engañe.';

  @override
  String get paywallOutcomeMark => 'engañe.';

  @override
  String get paywallOutcomeLine =>
      'Cinco tarjetas al día a tu nivel. Las que fallas vuelven hasta que se te quedan. Y te ves cambiar, semana a semana.';

  @override
  String get paywallFiveTitle => 'Las cinco, tuyas.';

  @override
  String get paywallFiveMark => 'tuyas.';

  @override
  String get paywallFiveLine =>
      'Gratis, dos de las cinco se eligen para ti, tres tras una semana seguida. Astute+ elige las cinco de tus ramas, a tu nivel, y te devuelve las que fallas.';

  @override
  String get paywallReadTitle => 'Lo que has leído, día a día.';

  @override
  String get paywallReadMark => 'día a día.';

  @override
  String get paywallReadLine =>
      'Los días que has leído últimamente, del más reciente al más antiguo. Toca uno para abrir sus cinco tarjetas, y una tarjeta para releerla.';

  @override
  String get perkGapTitle => 'Mira cómo se cierra la brecha';

  @override
  String get perkGapLine =>
      'Tu viaje, semana a semana: cuánta seguridad frente a cuánto acierto, y las jugadas que sigues fallando.';

  @override
  String get perkOwnFiveTitle => 'Cinco tarjetas tuyas';

  @override
  String get perkOwnFiveLine =>
      'Cada día, a tu nivel, y las que fallas vuelven.';

  @override
  String get perkReadTitle => 'Lo que has leído';

  @override
  String get perkReadLine =>
      'Tus últimos días, cada uno con sus cinco tarjetas, listos para abrirse otra vez.';

  @override
  String get perkAskTitle => 'Tu asistente';

  @override
  String get perkAskLine => 'Te explica cada tarjeta y te pone a prueba.';

  @override
  String get perkCoachTitle => 'Un coach cada semana';

  @override
  String get perkCoachLine => 'Dónde fallas y qué practicar después.';

  @override
  String get perkNew => 'NUEVO';

  @override
  String get threeTitle => 'Las tres de hoy';

  @override
  String threeStep(int n, int total) {
    return '$n de $total';
  }

  @override
  String get threeSame =>
      'Las mismas tres para todos hoy. Un minuto, más o menos.';

  @override
  String threeYouSaid(String guess) {
    return 'Dijiste $guess.';
  }

  @override
  String threePoints(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '+$n puntos',
      one: '+1 punto',
      zero: 'Ningún punto',
    );
    return '$_temp0';
  }

  @override
  String get threeNext => 'Siguiente';

  @override
  String get threeSeeScore => 'Ver tu puntuación';

  @override
  String get threeDone => 'Las tres de hoy · hecho';

  @override
  String get threeYou => 'Tú';

  @override
  String whyMissing(String move) {
    return 'Un paso que se te escapa: $move';
  }

  @override
  String whyMoveAgain(String move) {
    return '$move, de vuelta en un caso nuevo';
  }

  @override
  String get whyAgain => 'Vuelve para una segunda mirada';

  @override
  String whyGoal(String goal) {
    return 'Para tu objetivo: $goal';
  }

  @override
  String whyLiked(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Como $n cartas que te gustaron',
      one: 'Como una carta que te gustó',
    );
    return '$_temp0';
  }

  @override
  String whyHard(String subject) {
    return 'Una difícil: en $subject eres fuerte';
  }

  @override
  String whyLevel(String subject) {
    return 'A tu nivel en $subject';
  }

  @override
  String whyGentle(String subject) {
    return 'Una entrada fácil a $subject';
  }

  @override
  String whyYourSubject(String subject) {
    return 'De $subject, una de tus materias';
  }

  @override
  String get whyRandom => 'Sacada al azar de tus materias';

  @override
  String get whyTitle => 'Por qué esta carta';

  @override
  String whyTrains(String move) {
    return 'Entrena: $move';
  }

  @override
  String whyMet(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Te lo encontraste $n veces.',
      one: 'Te lo encontraste una vez.',
    );
    return '$_temp0';
  }

  @override
  String whyRight(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Bien $n veces.',
      one: 'Bien una vez.',
      zero: 'Aún ninguna bien.',
    );
    return '$_temp0';
  }

  @override
  String whyLevelRow(String subject) {
    return 'Tu nivel en $subject';
  }

  @override
  String whyLevelWord(String level) {
    String _temp0 = intl.Intl.selectLogic(level, {
      'starting': 'Empezando',
      'some': 'En camino',
      'strong': 'Fuerte',
      'other': 'En camino',
    });
    return '$_temp0';
  }

  @override
  String get whyLastMetRow => 'La última vez con este paso';

  @override
  String whyDaysAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Hace $n días',
      one: 'Ayer',
      zero: 'Hoy',
    );
    return '$_temp0';
  }

  @override
  String get whyGoalRow => 'Tu objetivo';

  @override
  String get whyLikedRow => 'Cartas parecidas que te gustaron';

  @override
  String get whyRandomLine =>
      'En el plan gratuito, parte de cada día se saca al azar de las materias que elegiste.';

  @override
  String get whyPlusLine =>
      'Con Astute+ las cinco se eligen para ti: a tu nivel, según lo que te gusta, y vuelven los pasos que se te escapan.';

  @override
  String get whyMakeMine => 'Que las cinco sean mías';

  @override
  String get whyMore => 'Más como esta';

  @override
  String get whyMoreDone => 'Anotado: más como esta';

  @override
  String get whyLess => 'Menos';

  @override
  String get whyTune => 'Ajusta tu mezcla';

  @override
  String get searchTry => 'Prueba';

  @override
  String get searchByNeed => 'Por necesidad';

  @override
  String get searchByKind => 'Por tipo';

  @override
  String kindName(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'play': 'Para jugar',
      'quiz': 'Quiz',
      'estimate': 'Estimaciones',
      'debate': 'Debates',
      'quick': 'Lecturas rápidas',
      'other': 'Cartas',
    });
    return '$_temp0';
  }

  @override
  String kindCards(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n cartas',
      one: '1 carta',
    );
    return '$_temp0';
  }

  @override
  String get areaUsefulFor => 'Te sirve para';

  @override
  String areaPaths(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n recorridos · diez cartas cada uno',
      one: 'Un recorrido · diez cartas',
    );
    return '$_temp0';
  }

  @override
  String get areaMoves => 'Los pasos que entrenas aquí';

  @override
  String get areaMoreCards => 'Más cartas para esto';

  @override
  String get pathKicker => 'Recorrido';

  @override
  String pathMeta(String subject, int n, int minutes) {
    return '$subject · $n cartas · unos $minutes min';
  }

  @override
  String pathPartOf(int part, int parts) {
    return 'Parte $part de $parts';
  }

  @override
  String pathTrains(String moves) {
    return 'Entrena: $moves';
  }

  @override
  String pathReadOf(int n, int total) {
    return '$n de $total leídas';
  }

  @override
  String get pathFreeTag => 'Gratis';

  @override
  String get pathStart => 'Empezar el recorrido';

  @override
  String pathContinueAt(int n) {
    return 'Seguir · carta $n';
  }

  @override
  String get pathContinue => 'Seguir';

  @override
  String get notesTitle => 'Notas';

  @override
  String get noteYours => 'Tu nota';

  @override
  String get noteAdd => 'Añadir una nota';

  @override
  String get noteEdit => 'Editar';

  @override
  String get noteSave => 'Guardar';

  @override
  String get noteDelete => 'Borrar la nota';

  @override
  String get noteHint => '¿Qué quieres recordar de esta tarjeta?';

  @override
  String get notesEmpty =>
      'Aún no hay notas. Abre una tarjeta que hayas guardado y escribe lo que quieras recordar.';

  @override
  String get pathUnlock => 'Desbloquea todos los recorridos';

  @override
  String get pathFreeLine =>
      'Las dos primeras cartas de cada recorrido son gratis.';

  @override
  String pathNextPart(int n) {
    return 'Parte $n: más a fondo';
  }

  @override
  String pathDeeperLine(int n) {
    return '$n cartas más del mismo tema, más difíciles.';
  }

  @override
  String get pathAgain => 'Leerlo otra vez';

  @override
  String get subjectKicker => 'Materia';

  @override
  String subjectReadOf(int n, int total) {
    return '$n de $total cartas leídas';
  }

  @override
  String subjectRight(int right, int answered) {
    return '$right bien de $answered respondidas';
  }

  @override
  String subjectToNext(int n, int level) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n respuestas correctas para el nivel $level',
      one: 'Una respuesta correcta para el nivel $level',
    );
    return '$_temp0';
  }

  @override
  String get subjectLevel => 'Nivel';

  @override
  String get subjectNext => 'La siguiente para ti';

  @override
  String get subjectNextLine => 'Un escalón por encima de tu nivel.';

  @override
  String subjectInside(String subject) {
    return 'Dentro de $subject';
  }

  @override
  String get journeySubjectsTap => 'Toca una materia para ver su página.';

  @override
  String moveName(String move) {
    String _temp0 = intl.Intl.selectLogic(move, {
      'baseRate': 'Tasas base',
      'survivorship': 'Supervivientes',
      'regression': 'Regresión a la media',
      'confirmation': 'Confirmación',
      'anchoring': 'Anclaje',
      'sampling': 'Muestra',
      'confounding': 'Factores de confusión',
      'counterfactual': 'Comparado con qué',
      'multipleComparisons': 'Muchos intentos',
      'availability': 'Disponibilidad',
      'sunkCost': 'Costes hundidos',
      'conjunction': 'Conjunción',
      'conditional': 'Probabilidad condicionada',
      'independence': 'Independencia',
      'coincidence': 'Coincidencias',
      'exponential': 'Crecimiento exponencial',
      'reflection': 'La respuesta rápida',
      'simpson': 'Agregados',
      'estimation': 'Estimación',
      'computation': 'Hacer la cuenta',
      'other': 'Razonamiento',
    });
    return '$_temp0';
  }

  @override
  String moveLine(String move) {
    String _temp0 = intl.Intl.selectLogic(move, {
      'baseRate':
          'Lo preciso que es un test no es lo probable que sea en tu caso',
      'survivorship': 'Los datos que tienes son los que sobrevivieron',
      'regression': 'Los extremos vuelven solos hacia la media',
      'confirmation': 'Buscar un sí no es una prueba',
      'anchoring': 'El primer número dicho mueve todos los que siguen',
      'sampling': 'Quién entra en la muestra decide lo que puede decir',
      'confounding': 'Quizá otra cosa causa las dos',
      'counterfactual': 'Un cambio no dice nada sin un control',
      'multipleComparisons': 'Prueba bastantes cosas y una pasará',
      'availability': 'Fácil de imaginar no es lo mismo que frecuente',
      'sunkCost': 'Lo gastado, gastado está: solo se decide lo que queda',
      'conjunction':
          'Los detalles hacen una historia más creíble y menos probable',
      'conditional': 'Lo que te dicen cambia las probabilidades',
      'independence': 'El azar no tiene memoria',
      'coincidence': 'Lo raro es común cuando hay muchos intentos',
      'exponential': 'Nadie tiene intuición para lo que se duplica',
      'reflection': 'La respuesta que llega primero es la que hay que revisar',
      'simpson':
          'Un todo puede inclinarse hacia donde no se inclina ninguna parte',
      'estimation': 'Divide lo imposible en cosas que puedes estimar',
      'computation': 'Un problema que puedes terminar de verdad',
      'other': 'Razonamiento',
    });
    return '$_temp0';
  }

  @override
  String get threeSend => 'Enviarlo';

  @override
  String get threeWhy => 'Ver el porqué';

  @override
  String threeYesterday(int score) {
    return 'Las tres de ayer: $score de 300.';
  }

  @override
  String get fiveTitle => 'El reto de hoy';

  @override
  String get fiveSame => 'Las mismas cinco para todos hoy. Unos dos minutos.';

  @override
  String get fiveDone => 'El reto de hoy · hecho';

  @override
  String dailyOf(int max) {
    return 'de $max';
  }

  @override
  String dailyPickRight(String answer) {
    return 'Correcta: $answer';
  }

  @override
  String dailyPickWrong(String answer) {
    return 'No exactamente. Correcta: $answer';
  }

  @override
  String dailyYourPick(String answer) {
    return 'La tuya: $answer';
  }

  @override
  String dailyBetter(int pct, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Mejor que el $pct % de los $n jugadores de hoy.',
    );
    return '$_temp0';
  }

  @override
  String dailyPlayers(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Por ahora, $n jugadores hoy.',
      one: 'Por ahora, 1 jugador hoy.',
    );
    return '$_temp0';
  }

  @override
  String dailyFirst(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Entre los primeros $n en jugar hoy: aún son pocos para comparar.',
      one: 'El primero en jugar hoy: aún son pocos para comparar.',
    );
    return '$_temp0';
  }

  @override
  String get dailyCounting => 'Contando a los jugadores de hoy…';

  @override
  String dailyAverage(int right, int total, String avg) {
    return 'Acertaste $right de $total. En estas, los lectores aciertan $avg de media.';
  }

  @override
  String get dailyUncounted =>
      'Ahora no se puede contar a los jugadores de hoy.';

  @override
  String get dailyEach => 'Pregunta a pregunta';

  @override
  String dailyItemRight(int pct) {
    return 'El $pct % de los jugadores de hoy acertó';
  }

  @override
  String dailyItemGuess(String guess) {
    return 'Estimación media de hoy: $guess';
  }

  @override
  String get dailyItemFew => 'Aún hay pocas respuestas para comparar';

  @override
  String fiveYesterday(int score) {
    return 'Las cinco de ayer: $score de 500.';
  }

  @override
  String fiveShareHead(String date) {
    return 'Astute · El reto de hoy · $date';
  }

  @override
  String fiveChallengeLine(int right) {
    return 'He acertado $right de las cinco de hoy en Astute. ¿Me superas?';
  }

  @override
  String get fiveChallengeAll =>
      'He acertado las cinco de hoy en Astute. ¿Me igualas?';

  @override
  String get fiveChallengeInvite =>
      'El reto de hoy en Astute: las mismas cinco preguntas para todos. ¿Cuántas aciertas?';

  @override
  String threeShareHeadIn(String subject, String date) {
    return 'Astute · Las tres de hoy · $subject · $date';
  }

  @override
  String dailyShareScore(int score, int max, int day) {
    return '$score de $max · día $day';
  }

  @override
  String dailyShareScoreAlone(int score, int max) {
    return '$score de $max';
  }

  @override
  String get skillsTitle => 'Qué aprender';

  @override
  String get skillsTitleMark => 'aprender';

  @override
  String get skillsLine =>
      'Cada respuesta mueve tu puntuación. Las que entrenen lo que elijas llevarán su marca.';

  @override
  String get skillsDone => 'Listo';

  @override
  String get skillsFocus => 'EN FOCO';

  @override
  String get skillMarkKicker => 'ESTA TARJETA ENTRENA';

  @override
  String skillMarkLabel(String skill) {
    return 'Entrena $skill';
  }

  @override
  String get skillMarkBody =>
      'Una de las habilidades que pusiste en foco. Cada respuesta en una tarjeta como esta mueve tu puntuación en ella.';

  @override
  String get skillMarkOpen => 'Ver todas tus puntuaciones';

  @override
  String get trainingTitle => 'Tu entrenamiento';

  @override
  String get trainingLine =>
      'Cada respuesta mueve tu puntuación, y una tarjeta difícil acertada es la que más. No hay techo.';

  @override
  String get trainingOthers => 'Las demás';

  @override
  String get trainingEmpty =>
      'Elige en qué quieres mejorar. Cada respuesta en una tarjeta que lo entrena mueve tu puntuación, y la tarjeta lleva su marca.';

  @override
  String get trainingPick => 'Elegir habilidades';

  @override
  String trainingMore(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'y $n más',
      one: 'y 1 más',
    );
    return '$_temp0';
  }

  @override
  String get aimTitle => '¿Dónde quieres ver más claro?';

  @override
  String get aimLine =>
      'Elige uno. Cada día habrá tarjetas para ello, y puedes cambiarlo cuando quieras.';

  @override
  String aimWeek(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n tarjetas para esto esta semana',
      one: '1 tarjeta para esto esta semana',
      zero: 'Ninguna tarjeta para esto esta semana',
    );
    return '$_temp0';
  }

  @override
  String answersRightOf(int right, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      right,
      locale: localeName,
      other: '$right de $n acertadas',
      one: '1 de $n acertada',
    );
    return '$_temp0';
  }

  @override
  String get aimOpen => 'Todo para este objetivo';

  @override
  String get aimPlus =>
      'Con Astute+: todas sus rutas completas, y un coach que trabaja en ello contigo.';

  @override
  String get aimNone =>
      'Elige dónde quieres ver más claro: cada día habrá tarjetas para ello.';

  @override
  String get aimPick => 'Elegir objetivo';

  @override
  String get strengthsTitle => 'Dónde eres fuerte';

  @override
  String get strengthsLine =>
      'Lo dicen tus respuestas, no una elección: dónde aciertas más y dónde fallas.';

  @override
  String strengthsFew(String skills) {
    return 'Aún pocas respuestas: $skills.';
  }

  @override
  String strengthsPractice(String skill) {
    return 'Practica $skill';
  }

  @override
  String get strengthsBest => 'Tu punto fuerte';

  @override
  String get strengthsWeak => 'Dónde fallas más';

  @override
  String get strengthsLocked =>
      'Dónde fallas más, y todo lo demás, con Astute+.';

  @override
  String get strengthsEmpty =>
      'Unas pocas respuestas más y aquí verás dónde eres fuerte.';

  @override
  String get readTitle => 'Dónde ya ves claro';

  @override
  String get readBlind => 'Tu punto ciego';

  @override
  String get readLocked =>
      'Cinco tarjetas sobre tu punto ciego, y tu perfil completo, con Astute+.';

  @override
  String get readEmpty =>
      'Unas pocas respuestas más y aquí verás dónde ves claro y dónde no.';

  @override
  String get readNoAim =>
      'Elige arriba dónde quieres ver más claro: tus respuestas te dirán dónde ya lo haces.';

  @override
  String get readLine =>
      'Las habilidades que pide este objetivo, leídas en tus respuestas: dónde ves claro y tu punto ciego.';

  @override
  String get readOthers => 'El resto de tu perfil';

  @override
  String get focusTitle => 'El foco de la semana';

  @override
  String get focusFromGoal =>
      'Elegido a partir de tu objetivo: cada semana una habilidad distinta.';

  @override
  String get focusFromMisses =>
      'Elegido a partir de tus respuestas: donde más fallas.';

  @override
  String get focusLine =>
      'Las tarjetas que lo entrenan llevan su marca. El domingo, cómo fue la semana.';

  @override
  String focusLast(String skill) {
    return 'La semana pasada: $skill';
  }

  @override
  String focusNext(String skill) {
    return 'Desde el lunes: $skill';
  }

  @override
  String get focusResult => 'Cómo fue la semana';

  @override
  String get focusPlus =>
      'Con Astute+, el foco lo eligen tus respuestas: donde más fallas.';

  @override
  String get focusMarkBody =>
      'Esta semana entrenas esta habilidad: las tarjetas que la entrenan llevan esta marca. El domingo verás cómo fue.';

  @override
  String focusShelf(String skill) {
    return 'Foco de la semana: $skill';
  }

  @override
  String get focusShelfLine => 'Tarjetas para entrenarlo, aún sin leer.';

  @override
  String get focusOpen => 'Tu semana';

  @override
  String get scoreTitle => 'Puntuación Astute';

  @override
  String scoreWeek(String n) {
    return '$n esta semana';
  }

  @override
  String get scoreStart => 'Empieza con tu primera respuesta.';

  @override
  String scoreMoveLabel(String name, String n) {
    return '$name: $n por esta respuesta';
  }

  @override
  String scoreAnswers(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'de $n respuestas',
      one: 'de 1 respuesta',
    );
    return '$_temp0';
  }

  @override
  String get videoKicker => 'Vídeo';

  @override
  String get videoPlay => 'Reproducir';

  @override
  String get videoPause => 'Pausa';

  @override
  String get videoWatchAgain => 'Ver otra vez';

  @override
  String get videoOffline =>
      'El vídeo necesita conexión. Toca para volver a intentarlo.';

  @override
  String get skillsRowTitle => 'Lo que quieres aprender';

  @override
  String skillName(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'critical': 'Pensamiento crítico',
      'decisions': 'Decidir mejor',
      'money': 'Dinero y ahorro',
      'numbers': 'Números y estadística',
      'talk': 'Comunicar',
      'persuade': 'Persuadir',
      'people': 'Entender a la gente',
      'fakes': 'Detectar bulos',
      'science': 'Pensar como científico',
      'focus': 'Concentración',
      'lead': 'Liderazgo',
      'culture': 'Cultura general',
      'other': '$key',
    });
    return '$_temp0';
  }

  @override
  String skillLine(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'critical': 'Distinguir un buen argumento de uno que engaña.',
      'decisions': 'Elegir con riesgos y probabilidades, no por instinto.',
      'money': 'Precios, intereses, ofertas: adónde va tu dinero.',
      'numbers': 'Leer porcentajes y gráficos sin que te engañen.',
      'talk': 'Hacerte entender, de palabra y por escrito.',
      'persuade': 'Convencer, y darte cuenta de cuándo intentan convencerte.',
      'people': 'Por qué la gente hace lo que hace.',
      'fakes': 'Detectar noticias falsas, fotos trucadas y estudios inflados.',
      'science': 'Poner a prueba una idea antes de creerla.',
      'focus': 'Mantener la atención donde importa, durante más tiempo.',
      'lead': 'Dirigir un grupo y decidir por todos.',
      'culture': 'Historia, ciencia, arte: lo que todos citan.',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get perkFiveShort => 'Cada día, a tu nivel.';

  @override
  String get perkShelvesTitle => 'Cada ruta y cada libro';

  @override
  String get perkShelvesLine => 'Enteros, y nuevos cada semana.';

  @override
  String get perkGapShort => 'Cuán seguro estás contra cuánto aciertas.';

  @override
  String get perkReadShort => 'Cada día leído, para volver a abrir.';

  @override
  String get trialToday => 'Hoy · todo Astute+, gratis';

  @override
  String trialReminder(int day) {
    return 'Día $day · te avisamos';
  }

  @override
  String trialCharge(int day, String price, String plan) {
    String _temp0 = intl.Intl.selectLogic(plan, {
      'year': 'al año',
      'other': 'al mes',
    });
    return 'Día $day · $price $_temp0, con renovación automática hasta que canceles';
  }

  @override
  String chargedTodayRenews(String price, String suffix) {
    return '$price$suffix cobrados hoy, con renovación automática hasta que canceles';
  }

  @override
  String cancelHow(String where) {
    return 'Cancela cuando quieras en $where, al menos 24 horas antes de la renovación.';
  }

  @override
  String get cancelWhereIos => 'Ajustes › tu nombre › Suscripciones';

  @override
  String get cancelWhereAndroid =>
      'Google Play › Pagos y suscripciones › Suscripciones';

  @override
  String storeAsking(String store) {
    String _temp0 = intl.Intl.selectLogic(store, {
      'apple': 'Pidiendo los precios al App Store…',
      'other': 'Pidiendo los precios a Google Play…',
    });
    return '$_temp0';
  }

  @override
  String storeUnreachable(String store) {
    String _temp0 = intl.Intl.selectLogic(store, {
      'apple': 'No se pudo conectar con el App Store',
      'other': 'No se pudo conectar con Google Play',
    });
    return '$_temp0';
  }

  @override
  String get storeUnreachableLine =>
      'Los precios y la prueba gratuita vienen de la tienda. Revisa tu conexión y vuelve a intentarlo.';

  @override
  String get tryAgain => 'Reintentar';

  @override
  String get purchasePending =>
      'Esperando aprobación. Astute+ se abrirá en cuanto se complete el pago.';

  @override
  String get oneMoment => 'Un momento…';

  @override
  String get purchaseConfirming => 'Confirmando el pago…';

  @override
  String get purchaseConfirmingSlow =>
      'Está tardando más de lo normal. El pago está a salvo: Astute+ se activará solo.';

  @override
  String get closeLabel => 'Cerrar';

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
  String get verdictRight => 'Correcto.';

  @override
  String get verdictClose => 'Bastante cerca.';

  @override
  String get verdictWrong => 'No exactamente.';

  @override
  String verdictSure(int pct) {
    return 'Estabas seguro al $pct%.';
  }

  @override
  String verdictYouSaid(String given) {
    return 'Dijiste $given';
  }

  @override
  String verdictYouSaidSure(String given, int pct) {
    return 'Dijiste $given, seguro al $pct%';
  }

  @override
  String verdictRightIs(String answer) {
    return 'Correcta: $answer';
  }

  @override
  String verdictRightWithin(String answer, String low, String high) {
    return 'Correcta: $answer (valía de $low a $high)';
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
  String get howSureAreYou => '¿Cómo de seguro estás?';

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
  String get musicSound => 'Sonido en las tarjetas de música';

  @override
  String get musicSoundIsOff =>
      'El sonido de las tarjetas de música está apagado.';

  @override
  String get musicSoundTurnOn => 'Activar';

  @override
  String get thatWasTheOnlyOne => 'Era la única';

  @override
  String get lastOne => 'La última';

  @override
  String deckEndTitle(String word) {
    return 'Esas eran las $word.';
  }

  @override
  String get deckEndAgain => 'Volver a empezar';

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
      other:
          '$n tarjetas que respondiste hace días, de vuelta para ver si se te quedaron',
      one: 'Una tarjeta que respondiste hace días, de vuelta para ver si se te quedó',
    );
    return '$_temp0';
  }

  @override
  String get cameBack => '¿Todavía te acuerdas?';

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
  String get likeThisPill => 'Me gusta esta tarjeta';

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
      'Toca el marcador en cualquier tarjeta y aterriza aquí — las que cambiaron tu forma de pensar, guardadas.';

  @override
  String get nudgeTitle => 'Tus cinco están listas';

  @override
  String get nudgeBookTitle => 'El libro gratis de esta semana';

  @override
  String nudgeBookBody(String title, String author, int minutes) {
    return '$title, de $author: las grandes ideas en $minutes minutos.';
  }

  @override
  String get nudgeFreezeTitle => 'Tu racha sigue a salvo';

  @override
  String nudgeFreezeBody(String question) {
    return 'Ayer te cubrió un comodín. Hoy: $question';
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
  String get yourJourney => 'Tu viaje';

  @override
  String journeySince(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Desde tu última visita, hace $days días',
      one: 'Desde tu última visita, ayer',
      zero: 'Desde tu última visita de hoy',
    );
    return '$_temp0';
  }

  @override
  String journeySinceMark(String n) {
    return '$n desde tu última visita';
  }

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
      'Cómo se usa la app —qué se lee, se guarda y se dice, y qué falla— para que las próximas tarjetas sean mejores. Nunca tu nombre, tu correo ni lo que escribes.';

  @override
  String get usageOn => 'Compartidos, sin tu nombre ni tus palabras.';

  @override
  String get usageOff => 'Ya no se mide nada.';

  @override
  String get consentTitle => '¿Nos ayudas a mejorar Astute?';

  @override
  String get consentLine =>
      'Comparte cómo usas la app: nunca tu nombre, tu correo ni lo que escribes.';

  @override
  String get consentNo => 'No, gracias';

  @override
  String get consentYes => 'Sí, compartir';

  @override
  String consentChangeLater(String profile, String setting) {
    return 'Puedes cambiarlo cuando quieras en $profile, en $setting.';
  }

  @override
  String get yourMix => 'Tu mezcla';

  @override
  String get genresTitle => '¿Qué partes?';

  @override
  String get genresLine =>
      'Toca un género para saltarlo. Mantenlo pulsado y los temas más pequeños de dentro se abren justo debajo.';

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
      'Cinco tarjetas al día elegidas para ti: de tu mezcla, a tu nivel, y las que fallas vuelven. Desde mañana.';

  @override
  String get plusCardHeadline => 'Las cinco, tuyas.';

  @override
  String get plusCardLine =>
      'Cinco tarjetas al día de tu mezcla, a tu nivel. Tu viaje. Todo tu archivo.';

  @override
  String get archiveBeforeThisWeek => 'Antes de esta semana';

  @override
  String get weekKeptThreeOwn =>
      'Siete días seguidos: mañana tres de las cinco son tuyas.';

  @override
  String get weekKeptSundayFourOwn =>
      'Siete días seguidos, y mañana es domingo: cuatro de las cinco son tuyas.';

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
  String get topPicksTitle => 'Merecen tu tiempo';

  @override
  String get topPicksLine =>
      'Elegidas por Astute mientras se llena la lista de los lectores';

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
  String get themePracticalLine =>
      'Algo que probar, o que sacar en una conversación, antes de esta noche';

  @override
  String get themeOrigins => 'De dónde viene';

  @override
  String get themeOriginsLine => 'El origen de cosas que usas cada día';

  @override
  String get themeStories => 'Historias reales';

  @override
  String get themeStoriesLine => 'Cosas que pasaron de verdad';

  @override
  String get storyHint => 'Toca para seguir · mantén pulsado para pausar';

  @override
  String get storyTapOn => 'Toca para seguir';

  @override
  String get storyPrevious => 'Anterior';

  @override
  String get storyClose => 'Cerrar la historia';

  @override
  String get storySave => 'Guardar';

  @override
  String get storySaved => 'Guardada';

  @override
  String get storyShare => 'Compartir';

  @override
  String get storyOpenCard => 'Abrir la tarjeta';

  @override
  String get themeDebates => 'Elige un bando';

  @override
  String get themeDebatesLine =>
      'No hay respuesta correcta, solo un argumento mejor';

  @override
  String get themeWorkItOut => 'Haz la cuenta';

  @override
  String get themeWorkItOutLine =>
      'Adivina el número antes de que te lo diga la tarjeta';

  @override
  String get themeSeen => 'Para ver';

  @override
  String get themeSeenLine => 'Tarjetas que dibujan su idea';

  @override
  String get themeSharpest => 'Para los más agudos';

  @override
  String get themeSharpestLine => 'Las tarjetas más difíciles que hay';

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
  String weekRecapMore(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n más de tu semana con Astute+',
      one: '1 más de tu semana con Astute+',
    );
    return '$_temp0';
  }

  @override
  String get weekReviewTitle => 'Repasa la semana';

  @override
  String get weekReviewLine =>
      'Las preguntas de tus tarjetas de esta semana. Respóndelas otra vez: así se quedan.';

  @override
  String get weekReviewGo => 'Repasar';

  @override
  String get weekReviewNone =>
      'Las tarjetas que leas esta semana vuelven aquí para repasarlas.';

  @override
  String get plusInTheApp =>
      'Astute+ está en la app: descarga Astute en iPhone o Android para empezar tu prueba gratuita.';

  @override
  String get purchaseComplete => 'Compra completada.';

  @override
  String get trialStartedTitle => 'Prueba gratuita activada.';

  @override
  String get successWelcome =>
      'Bienvenido a Astute+. Las cinco tarjetas de hoy están listas.';

  @override
  String successWelcomeNamed(String name) {
    return 'Bienvenido a Astute+, $name. Las cinco tarjetas de hoy están listas.';
  }

  @override
  String get successWelcomeTomorrow =>
      'Bienvenido a Astute+. Las cinco de mañana son todas tuyas.';

  @override
  String successWelcomeTomorrowNamed(String name) {
    return 'Bienvenido a Astute+, $name. Las cinco de mañana son todas tuyas.';
  }

  @override
  String get successFiveCards => '5 tarjetas al día';

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
  String get sceneLockIn => 'Confirmar';

  @override
  String get placeItDrag => 'Desliza por la regla.';

  @override
  String get placeItHappy => '¿Te convence?';

  @override
  String get placeItEstimate => 'Tu estimación';

  @override
  String get placeItNotSet => 'sin fijar';

  @override
  String get placeItLock => 'Confirmar mi estimación';

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
    return '$now min a la semana, al principio $was min';
  }

  @override
  String journeyMinThisWeek(int m) {
    return '$m min esta semana';
  }

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
  String get journeyMovesTitle => 'Trucos que detectas';

  @override
  String get journeySureEmpty => 'Aparece cuando respondas con un 80 % o más.';

  @override
  String get journeyMovesEmpty =>
      'Aparece cuando detectes un truco en dos tarjetas.';

  @override
  String get journeyMissedEmpty =>
      'Seis respuestas en una segunda materia y queda medida.';

  @override
  String get journeyFillsAsYouRead => 'Se llena a medida que lees.';

  @override
  String journeyOfN(int n) {
    return 'de $n';
  }

  @override
  String journeyNewest(String name) {
    return 'Último: $name';
  }

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
  String get betWord => 'Apostar';

  @override
  String get biggerLabel => 'Mayor';

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
  String get fewCards => 'En unas pocas tarjetas';

  @override
  String get fewCardsLine => 'Cuando una sola tarjeta no basta para explicarlo';

  @override
  String get firstLabel => 'Desde';

  @override
  String get forYouNow => 'Para ti, ahora';

  @override
  String get hardBadge => 'Difícil';

  @override
  String hidesIn(String where) {
    return 'Tema: $where';
  }

  @override
  String get howSure => '¿Qué tan seguro estoy, y por qué?';

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
  String get modeCloser => 'Cada vez más cerca';

  @override
  String get modePick => 'Elige una';

  @override
  String get modeRange => 'Apuesta a un rango';

  @override
  String get modeSlide => 'Muévelo';

  @override
  String get modeStake => 'Haz tu apuesta';

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
  String get moveComparedToWhat => '¿Mucho o poco?';

  @override
  String get moveComparedToWhatLine =>
      '«Un 30 % más» no dice nada hasta que sabes: ¿comparado con qué?';

  @override
  String get askingTitle => 'Una pregunta de cada tema';

  @override
  String askingIn(String subject) {
    return 'Preguntas de $subject';
  }

  @override
  String get askingLine =>
      'Igual para todos. Primero responde, luego descubre por qué';

  @override
  String get moveSampling => '¿Quién falta en los datos?';

  @override
  String get moveSamplingLine =>
      'Toda estadística cuenta a unos y deja fuera a otros. Quién falta puede darle la vuelta a la respuesta';

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
  String rangeWidth(int w, int pts) {
    return '±$w · $pts pts';
  }

  @override
  String get rightLastTime => 'Acertada la última vez';

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
  String leanHint(String or) {
    return 'Desliza la «$or» hasta donde estás';
  }

  @override
  String leanHow(String level) {
    String _temp0 = intl.Intl.selectLogic(level, {
      '1': 'un poco',
      '2': 'en general',
      '3': 'con firmeza',
      'other': 'del todo',
    });
    return '$_temp0';
  }

  @override
  String leanSays(String side, String how) {
    return '$side, $how';
  }

  @override
  String leanTook(String side) {
    return 'Elegiste $side';
  }

  @override
  String leanVerdict(String says) {
    return '$says. Ábrela para ver el otro bando.';
  }

  @override
  String get spotTitle => 'Encuentra la falsa';

  @override
  String get spotLine =>
      'Cuatro afirmaciones. Tres son verdaderas, una es falsa.';

  @override
  String get spotPrompt => 'Toca la que creas que es falsa';

  @override
  String get spotConfirm => 'Esa es la falsa';

  @override
  String get spotFound => 'La encontraste. Las otras tres son verdad.';

  @override
  String get spotMissed => 'Esa no: es verdad. La falsa está tachada.';

  @override
  String get spotWhy => 'Toca cualquiera para leer por qué';

  @override
  String get spotYours => 'Tu elección';

  @override
  String get todayLabel => 'Hoy';

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
  String get unmaskMisleadTitle => 'Gráficos que engañan';

  @override
  String get unmaskMisleadLine =>
      'Los números son ciertos. El truco está en el dibujo.';

  @override
  String get unmaskAsk => 'Este gráfico engaña. ¿Ves cómo?';

  @override
  String get unmaskShowTrick => 'Mostrar el truco';

  @override
  String get unmaskHideTrick => 'Ocultar el truco';

  @override
  String get unmaskOriginal => 'Original';

  @override
  String get unmaskCorrected => 'Corregido';

  @override
  String unmaskTrickTruncated(String from) {
    return 'El eje empieza en $from, no en cero.';
  }

  @override
  String unmaskTrickZoomed(String low, String high) {
    return 'El eje solo va de $low a $high, así que un cambio pequeño parece enorme.';
  }

  @override
  String unmaskTrickWide(String low, String high) {
    return 'El eje va de $low a $high, así que un cambio real parece plano.';
  }

  @override
  String unmaskTrickWindow(String shown, String all) {
    return 'Solo muestra $shown, pero los datos abarcan $all.';
  }

  @override
  String get unmaskTrickTotals =>
      'Compara totales brutos, no una medida justa.';

  @override
  String get unmaskTrickFlippedRise =>
      'El eje está al revés, así que una subida parece una bajada.';

  @override
  String get unmaskTrickFlippedFall =>
      'El eje está al revés, así que una bajada parece una subida.';

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

  @override
  String placeNearYou(String place) {
    return 'Cerca de ti · $place';
  }

  @override
  String placeYourRegion(String place) {
    return 'Tu región · $place';
  }

  @override
  String placeYourCountry(String place) {
    return 'Tu país · $place';
  }

  @override
  String get sundayOneMore => 'Domingo: una más elegida para ti';

  @override
  String get whereYouLive => 'Donde vives';

  @override
  String get whereYouLiveLine =>
      'Primero tu ciudad, luego tu región, luego tu país';

  @override
  String get whereYouLiveAsk =>
      'Tarjetas sobre tu ciudad, tu región y tu país: como mucho una al día, y esta estantería. Solo se guarda la ciudad, nunca dónde estás exactamente.';

  @override
  String get whereYouLiveSwitchOn => 'Activar';

  @override
  String get gateUpdateTitle => 'Actualiza Astute';

  @override
  String gateUpdateLine(String store) {
    String _temp0 = intl.Intl.selectLogic(store, {
      'apple': 'La nueva te espera en el App Store',
      'google': 'La nueva te espera en Google Play',
      'other': 'La nueva te espera en tu tienda de apps',
    });
    return 'Esta versión ya no puede seguir. $_temp0, con tus tarjetas y tu racha tal como las dejaste.';
  }

  @override
  String get gateUpdateButton => 'Actualizar';

  @override
  String get gateSoftTitle => 'Hay una nueva versión de Astute';

  @override
  String gateSoftLine(String store) {
    String _temp0 = intl.Intl.selectLogic(store, {
      'apple': 'Te espera en el App Store.',
      'google': 'Te espera en Google Play.',
      'other': 'Te espera en tu tienda de apps.',
    });
    return '$_temp0 Actualizar lleva un momento, y tus tarjetas y tu racha se quedan tal como están.';
  }

  @override
  String get gateSoftLater => 'Más tarde';

  @override
  String get gatePauseTitle => 'Astute se toma un pequeño descanso';

  @override
  String get gatePauseLine =>
      'Estamos arreglando algo entre bastidores. Todo lo que has hecho está a salvo. Vuelve a intentarlo dentro de un rato.';

  @override
  String get gatePauseTrying => 'Reintentando…';

  @override
  String get gatePauseStill =>
      'Seguimos en pausa. Vuelve a intentarlo en unos minutos.';

  @override
  String purposeReadOrDoCount(int toDo, int toRead) {
    return '$toDo para hacer, $toRead para leer';
  }

  @override
  String purposeShelfCount(int toDo, int toRead) {
    return '$toDo para hacer · $toRead para leer';
  }

  @override
  String get purposeFilterToRead => 'Leer';

  @override
  String get purposeFilterToDo => 'Hacer';

  @override
  String purposeVerb(String verb) {
    String _temp0 = intl.Intl.selectLogic(verb, {
      'trueFalse': 'Verdadero o falso',
      'pick': 'Elige una',
      'typeNumber': 'Escribe un número',
      'bet': 'Apuesta el número',
      'side': 'Elige un bando',
      'youFirst': 'Tú primero',
      'moveIt': 'Muévelo y mira',
      'whatNext': '¿Qué pasa después?',
      'spotTrick': 'Encuentra el truco',
      'drawIt': 'Dibújalo',
      'sortThem': 'Clasifícalos',
      'putInOrder': 'Ponlos en orden',
      'holdIt': 'Mantén pulsado',
      'growSample': 'Haz crecer la muestra',
      'askWhy': 'Pregunta por qué',
      'sayPlainly': 'Dilo claro',
      'pairUp': 'Emparéjalos',
      'followClues': 'Sigue las pistas',
      'look': 'Solo mira',
      'listen': 'Escucha',
      'other': '$verb',
    });
    return '$_temp0';
  }

  @override
  String purposeVerbRead(int n) {
    return 'Leer · $n min';
  }

  @override
  String get purposeCommitNote =>
      'Responde aquí y luego abre la carta para ver si acertaste. Una respuesta con la que te comprometes se te queda más tiempo.';

  @override
  String get purposeCommitTitle => 'Primero responde';

  @override
  String get purposeCommitLine => 'Di lo que piensas y luego abre la carta';

  @override
  String get purposeInYourHeadLine => 'Un número al que llegar de cabeza';

  @override
  String get purposeInYourHead => 'De cabeza';

  @override
  String get purposeMoveKicker => 'Una jugada';

  @override
  String purposeMoveNew(int points) {
    return 'Nueva · +$points cuando la domines';
  }

  @override
  String purposeMoveName(String move) {
    String _temp0 = intl.Intl.selectLogic(move, {
      'baseRate': 'Tasas base',
      'survivorship': 'Supervivencia',
      'regression': 'Regresión a la media',
      'confirmation': 'Confirmación',
      'anchoring': 'Anclaje',
      'sampling': 'Muestreo',
      'confounding': 'Factor de confusión',
      'counterfactual': 'Comparado con qué',
      'multipleComparisons': 'Muchas pruebas',
      'availability': 'Disponibilidad',
      'sunkCost': 'Coste hundido',
      'conjunction': 'Conjunción',
      'conditional': 'Probabilidad condicionada',
      'independence': 'Independencia',
      'coincidence': 'Coincidencia',
      'exponential': 'Crecimiento exponencial',
      'reflection': 'La respuesta rápida',
      'simpson': 'Totales',
      'estimation': 'Estimación',
      'computation': 'Hacer la cuenta',
      'other': '$move',
    });
    return '$_temp0';
  }

  @override
  String purposeMoveLine(String move) {
    String _temp0 = intl.Intl.selectLogic(move, {
      'baseRate': 'Que un test sea preciso no dice lo probable que es en ti',
      'survivorship': 'Los datos que tienes son los que sobrevivieron',
      'regression': 'Los extremos vuelven solos hacia la media',
      'confirmation': 'Buscar un sí no es una prueba',
      'anchoring': 'El primer número que se dice mueve todos los siguientes',
      'sampling': 'Quién acabó en la muestra decide lo que puede decir',
      'confounding': 'Puede que otra cosa cause las dos',
      'counterfactual': 'Un cambio no significa nada sin un grupo de control',
      'multipleComparisons': 'Prueba suficientes cosas y una pasará',
      'availability': 'Fácil de imaginar no es lo mismo que frecuente',
      'sunkCost': 'Lo gastado, gastado está; solo se decide sobre lo que queda',
      'conjunction':
          'El detalle hace una historia más creíble y menos probable',
      'conditional': 'Lo que te han dicho cambia las probabilidades',
      'independence': 'El azar no tiene memoria',
      'coincidence': 'Lo raro es frecuente cuando hay muchos intentos',
      'exponential': 'Nadie tiene intuición para lo que se duplica',
      'reflection': 'La respuesta que llega primero es la que hay que revisar',
      'simpson':
          'El total puede inclinarse hacia donde no se inclina ninguna parte',
      'estimation':
          'Divide lo imposible de responder en cosas que puedas estimar',
      'computation': 'Un problema que de verdad puedes terminar',
      'other': '$move',
    });
    return '$_temp0';
  }

  @override
  String purposeMoveAsk(String move) {
    String _temp0 = intl.Intl.selectLogic(move, {
      'baseRate': '¿Cuánto abundaba de entrada?',
      'survivorship': '¿Qué nunca llegó a los datos?',
      'regression': '¿Es solo un extremo que vuelve?',
      'confirmation': '¿Qué me demostraría que me equivoco?',
      'anchoring': '¿Qué número llegó primero?',
      'sampling': '¿A quién se contó?',
      'confounding': '¿Qué otra cosa podría causar las dos?',
      'counterfactual': '¿Comparado con qué?',
      'multipleComparisons': '¿Cuántas cosas se probaron?',
      'availability': '¿Es frecuente o solo fácil de imaginar?',
      'sunkCost': '¿Qué queda por decidir desde aquí?',
      'conjunction': '¿Cada detalle lo hace menos probable?',
      'conditional': '¿Qué cambia saber eso?',
      'independence': '¿El último resultado cambia el siguiente?',
      'coincidence': '¿Cuántas oportunidades hubo?',
      'exponential': '¿Qué pasa cuando vuelve a duplicarse?',
      'reflection': '¿La primera respuesta es la buena?',
      'simpson': '¿Todas las partes se inclinan igual?',
      'estimation': '¿Qué puedo estimar por el camino?',
      'computation': '¿Puedo calcularlo paso a paso?',
      'other': '$move',
    });
    return '$_temp0';
  }

  @override
  String get purposeStepAbove => 'Un escalón más';

  @override
  String get purposeStepAboveLine => 'Más difícil que lo que sueles leer';

  @override
  String purposeThinTitle(String subject) {
    return 'Lo que menos lees: $subject';
  }

  @override
  String purposeThinLine(int percent, String subject) {
    return 'Has leído el $percent % de $subject, lo que menos';
  }

  @override
  String get purposeOtherSide => 'El otro lado';

  @override
  String get purposeOtherSideLine =>
      'Elegiste un bando. Aquí está el mejor argumento en contra';

  @override
  String purposeYouSaid(String side) {
    return 'Dijiste $side';
  }

  @override
  String purposeCaseFor(String side) {
    return 'Las razones del «$side»';
  }

  @override
  String get purposeMechanism => 'El mecanismo';

  @override
  String purposeMovingUpdated(String date) {
    return 'Actualizado el $date';
  }

  @override
  String get purposeMovingYears => 'Puede cambiar en unos años';

  @override
  String get purposeMovingMonths => 'Puede cambiar este año';

  @override
  String get purposeWhy => 'Ah, por eso es';

  @override
  String get purposeWhyLine => 'Un mecanismo, explicado hasta que haga clic';

  @override
  String purposeWhyBand(int n) {
    return 'El porqué · $n min';
  }

  @override
  String get purposeMe => 'Así soy yo';

  @override
  String get purposeMeLine => 'Cosas que haces sin darte cuenta';

  @override
  String get purposeMeFooter => 'Marca las cartas en las que te reconoces.';

  @override
  String purposeMeMarked(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n cartas marcadas con «Así soy yo».',
      one: 'Una carta marcada con «Así soy yo».',
    );
    return '$_temp0';
  }

  @override
  String get purposeAboutYou => 'Nuevo para mí, y sobre mí';

  @override
  String get purposeAboutYouLine => 'Tu cuerpo, tu salud, tus probabilidades';

  @override
  String get purposeHeadline => 'En un titular';

  @override
  String get purposeHeadlineLine =>
      'Estudios y afirmaciones que suenan mejor de lo que son';

  @override
  String get purposeTheClaim => 'La afirmación';

  @override
  String get purposeNumber => 'En una cifra';

  @override
  String get purposeNumberLine =>
      'Probabilidades y porcentajes que piden una segunda mirada';

  @override
  String get purposeOutOfWhat => '¿De cuántos?';

  @override
  String get purposeOffer => 'En una oferta';

  @override
  String get purposeOfferLine => 'Precios, ofertas y quién paga de verdad';

  @override
  String get purposeArgument => 'En una discusión';

  @override
  String get purposeArgumentLine => 'Donde el razonamiento resbala';

  @override
  String purposeKeepHeading(String n) {
    String _temp0 = intl.Intl.selectLogic(n, {
      '1': 'Una pregunta que destapa casi todo esto',
      '2': 'Dos preguntas que destapan casi todo esto',
      '3': 'Tres preguntas que destapan casi todo esto',
      '4': 'Cuatro preguntas que destapan casi todo esto',
      '5': 'Cinco preguntas que destapan casi todo esto',
      'other': '$n preguntas que destapan casi todo esto',
    });
    return '$_temp0';
  }

  @override
  String purposeLifeAbout(String topic) {
    String _temp0 = intl.Intl.selectLogic(topic, {
      'money': 'Dinero',
      'work': 'Trabajo y tiempo',
      'clock': 'Tiempo',
      'body': 'Tu cuerpo',
      'relationships': 'Relaciones',
      'belief': 'Lo que crees',
      'other': '$topic',
    });
    return '$_temp0';
  }

  @override
  String purposeLifeQuestion(String topic) {
    String _temp0 = intl.Intl.selectLogic(topic, {
      'money': '¿Pago por lo que de verdad uso?',
      'work': '¿Qué me haría más fácil empezar mañana?',
      'clock': '¿Adónde se va de verdad mi tiempo?',
      'body': '¿Sigue siendo cierto lo que sé de mi cuerpo?',
      'relationships': '¿Qué necesita de verdad la gente cercana a mí?',
      'belief': '¿Qué tan seguro estoy, y por qué?',
      'other': '$topic',
    });
    return '$_temp0';
  }

  @override
  String purposeLifeChip(String topic) {
    String _temp0 = intl.Intl.selectLogic(topic, {
      'money': 'Dinero',
      'work': 'Trabajo',
      'clock': 'Tiempo',
      'body': 'Cuerpo',
      'relationships': 'Relaciones',
      'belief': 'Lo que creo',
      'other': '$topic',
    });
    return '$_temp0';
  }

  @override
  String get purposeLifeAsk => '¿Sobre qué quieres mejores preguntas?';

  @override
  String get purposeLifeFooter =>
      'Elige los que quieras y aquí aparecen las cartas que preguntan por ello.';

  @override
  String get purposeSpotTrick => 'Encuentra el truco';

  @override
  String get purposeSpotTrickLine => '¿Qué pregunta lo destaparía?';

  @override
  String get purposePlayed => 'Lo que jugaste hoy';

  @override
  String get purposePlayedOff => 'puntos de desvío, de media';

  @override
  String get purposePlayedTricks => 'trucos descubiertos';

  @override
  String get purposePlayedAnswered => 'respondidas en una estantería';

  @override
  String get purposePlayedFooter =>
      'Las respuestas dadas en una estantería cuentan en «Tu viaje», como las de Hoy.';

  @override
  String purposeOf(int n, int of) {
    return '$n de $of';
  }

  @override
  String purposeSetRead(int n, int of) {
    return '$n de $of leídas';
  }

  @override
  String purposeSetDone(int n) {
    return 'Leídas las $n. Llegarán nuevas cuando la estantería vuelva a salir.';
  }

  @override
  String get purposeComplete => 'Completa';

  @override
  String get purposeStampsFooter => 'Cada carta que lees añade su sello.';

  @override
  String get purposeSets => 'Tus colecciones';

  @override
  String get purposeSetsLine =>
      'Leer cuenta. No hace falta responder para completar una colección.';

  @override
  String get purposeTomorrow => 'Mañana en las estanterías';

  @override
  String get purposeTomorrowLine =>
      'Las estanterías cambian cada día. Estas son las siguientes';

  @override
  String get purposeEnd => 'Has llegado al final de Explorar';

  @override
  String get purposeEndLine => 'Hasta mañana';

  @override
  String get betsRangeTitle => 'Apuesta a un rango';

  @override
  String get betsRangeLine => 'Cuanto más estrecho, más paga, si aciertas';

  @override
  String betsRangeWidth(int w, int pts) {
    return '±$w · $pts pts';
  }

  @override
  String get betsBet => 'Apostar';

  @override
  String betsInRange(int pts, String said) {
    return 'Dentro: +$pts puntos. Es $said.';
  }

  @override
  String betsMissedRange(String said) {
    return 'Fallaste: es $said.';
  }

  @override
  String get betsYourGuess => 'Tu estimación';

  @override
  String get betsAnsweredAlready => 'Ya respondida';

  @override
  String get betsOpenCard => 'Abrir la tarjeta';

  @override
  String betsWalletSays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Te quedan $n puntos hoy',
      one: 'Te queda 1 punto hoy',
    );
    return '$_temp0';
  }

  @override
  String get betsSlipTitle => 'Tu boleto';

  @override
  String betsSlipToday(String points) {
    return '$points hoy';
  }

  @override
  String get betsSlipEmpty =>
      'Aún no hay apuestas. Cada una que hagas aparece aquí.';

  @override
  String get betsSlipTipTwice =>
      'Ve estrecho cuando estés seguro: paga el doble.';

  @override
  String get betsSlipTipThrice =>
      'Ve estrecho cuando estés seguro: paga el triple.';

  @override
  String betsSlipTipTimes(int times) {
    String _temp0 = intl.Intl.pluralLogic(
      times,
      locale: localeName,
      other: 'Ve estrecho cuando estés seguro: paga $times veces más.',
    );
    return '$_temp0';
  }

  @override
  String betsSlipNarrow(int right, int n) {
    return 'Apuestas estrechas acertadas: $right de $n.';
  }

  @override
  String betsSlipSure(int right, int n, int pct) {
    return 'Aciertas $right de $n, con un $pct% de seguridad media.';
  }

  @override
  String get betsRight => 'Acierto';

  @override
  String get betsWrong => 'Fallo';

  @override
  String betsOneIn(String n) {
    return '1 de cada $n';
  }

  @override
  String get betsOneInLabel => '1 de cada';

  @override
  String betsScore(int right, int steps) {
    return '$right de $steps';
  }

  @override
  String betsScoreSentence(int right, int steps) {
    return 'Acertaste $right de $steps.';
  }

  @override
  String get betsStakeTitle => 'Haz tu apuesta';

  @override
  String betsStakeLine(int points) {
    return '$points puntos al día. Si ganas, doblas lo apostado';
  }

  @override
  String get betsStakeLabel => 'Apuesta';

  @override
  String betsBetN(int n) {
    return 'Apostar $n';
  }

  @override
  String get betsPickFirst => 'Elige una primero';

  @override
  String get betsNotEnough => 'No tienes puntos suficientes';

  @override
  String betsWin(int n) {
    return 'Ganas $n.';
  }

  @override
  String betsLose(int n) {
    return 'Pierdes $n.';
  }

  @override
  String betsYouWereSure(int pct) {
    return 'Estabas seguro al $pct%.';
  }

  @override
  String get betsFriendTitle => 'Apuesta con un amigo';

  @override
  String get betsFriendLine =>
      'Envía una pregunta y después compara las estimaciones';

  @override
  String get betsFriendNote =>
      'Tu estimación se queda en tu teléfono. La tarjeta llega con su respuesta, así que pide la suya antes.';

  @override
  String betsFriendNoteSaid(String said) {
    return 'Dijiste $said. La tarjeta llega con su respuesta, así que pide su estimación antes.';
  }

  @override
  String get betsFriendSend => 'Enviar a un amigo';

  @override
  String get betsFriendCopy => 'Copiar la pregunta';

  @override
  String get betsFriendCopied => 'Pregunta copiada';

  @override
  String get betsFriendAsk => '¿Tú qué dices?';

  @override
  String get betsNumberTitle => 'Tu número';

  @override
  String get betsNumberLine => 'Ajústalo, fíjalo y mira cuánto te desviaste';

  @override
  String get betsLock => 'Confirmar';

  @override
  String get betsSpotOn => 'Exacto.';

  @override
  String betsCloseEnough(String by) {
    return 'Bastante cerca: te desviaste $by.';
  }

  @override
  String betsOffBy(String by) {
    return 'Te desviaste $by.';
  }

  @override
  String get betsYou => 'tú';

  @override
  String get betsAnswer => 'respuesta';

  @override
  String get betsBiggerTitle => '¿Cuál es mayor?';

  @override
  String get betsBiggerLine => 'Dos cifras que puedes calcular. Toca la mayor';

  @override
  String get betsTapIfBigger => 'Toca si es mayor';

  @override
  String get betsBiggerGotIt => 'Mayor · acertaste';

  @override
  String get betsBigger => 'Mayor';

  @override
  String get betsYourPick => 'Tu elección';

  @override
  String get betsOr => 'o';

  @override
  String get betsBiggerFoot =>
      'Cada cifra es la respuesta de una tarjeta. Cuando elijas, toca una para abrir su tarjeta.';

  @override
  String betsBiggerScore(int right, int n) {
    return 'Acertaste $right de $n.';
  }

  @override
  String get betsCloserTitle => 'Cada vez más cerca';

  @override
  String betsCloserLine(String steps) {
    String _temp0 = intl.Intl.selectLogic(steps, {
      '2': 'Dos pasos de más o menos para acercarte al número',
      '3': 'Tres pasos de más o menos para acercarte al número',
      '4': 'Cuatro pasos de más o menos para acercarte al número',
      '5': 'Cinco pasos de más o menos para acercarte al número',
      'other': '$steps pasos de más o menos para acercarte al número',
    });
    return '$_temp0';
  }

  @override
  String betsCloserStart(String steps) {
    String _temp0 = intl.Intl.selectLogic(steps, {
      '2': 'Dos pasos para acercarte.',
      '3': 'Tres pasos para acercarte.',
      '4': 'Cuatro pasos para acercarte.',
      '5': 'Cinco pasos para acercarte.',
      'other': '$steps pasos para acercarte.',
    });
    return '$_temp0';
  }

  @override
  String betsMoreOrLess(String v) {
    return '¿Más o menos de $v?';
  }

  @override
  String betsStepOf(int at, int of) {
    return 'Paso $at de $of';
  }

  @override
  String get betsMore => 'Más';

  @override
  String get betsLess => 'Menos';

  @override
  String betsCloserYesMore(String v) {
    return 'Correcto: es más de $v.';
  }

  @override
  String betsCloserYesLess(String v) {
    return 'Correcto: es menos de $v.';
  }

  @override
  String betsCloserNoMore(String v) {
    return 'Incorrecto: es más de $v.';
  }

  @override
  String betsCloserNoLess(String v) {
    return 'Incorrecto: es menos de $v.';
  }

  @override
  String betsCloserExact(String said) {
    return 'Es exactamente $said.';
  }

  @override
  String betsCloserDone(String said, int right, int steps) {
    return 'Es $said. Acertaste $right de $steps.';
  }

  @override
  String get betsMagnitudeTitle => 'Órdenes de magnitud';

  @override
  String get betsMagnitudeLine => '¿Diez, mil o un millón? Elige el tamaño';

  @override
  String get betsMagnitudeRight => 'Orden de magnitud correcto.';

  @override
  String betsMagnitudeOff(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Te desviaste $n órdenes de magnitud.',
      one: 'Te desviaste 1 orden de magnitud.',
    );
    return '$_temp0';
  }

  @override
  String get betsDayTitle => 'La apuesta del día';

  @override
  String get betsDayLine => 'Confirma tu estimación y mira cuánto te desviaste';

  @override
  String get betsDayTag => 'Apuesta del día';

  @override
  String get betsDayTagSame => 'Apuesta del día · la misma para todos';

  @override
  String get betsLockIn => 'Confirmar';

  @override
  String betsItIs(String said) {
    return 'Es $said.';
  }

  @override
  String betsPointsOff(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Te desviaste $n puntos porcentuales.',
      one: 'Te desviaste 1 punto porcentual.',
      zero: 'Exacto.',
    );
    return '$_temp0';
  }

  @override
  String screensQuoted(String text) {
    return '«$text»';
  }

  @override
  String get screensExpertTitle => 'Piensa como un experto';

  @override
  String get screensExpertLine =>
      'La pregunta que cada uno de ellos siempre hace, y las tarjetas donde hace falta';

  @override
  String get screensExpertStatistician => 'Estadístico';

  @override
  String get screensExpertStatisticianAs => 'Piensa como un estadístico';

  @override
  String get screensExpertStatisticianAsks =>
      '¿Comparado con qué, y de cuántos?';

  @override
  String get screensExpertEconomist => 'Economista';

  @override
  String get screensExpertEconomistAs => 'Piensa como un economista';

  @override
  String get screensExpertEconomistAsks => '¿Quién paga, y a qué renuncia?';

  @override
  String get screensExpertHistorian => 'Historiador';

  @override
  String get screensExpertHistorianAs => 'Piensa como un historiador';

  @override
  String get screensExpertHistorianAsks => '¿Qué se sabía en aquel momento?';

  @override
  String get screensExpertDoctor => 'Médico';

  @override
  String get screensExpertDoctorAs => 'Piensa como un médico';

  @override
  String get screensExpertDoctorAsks =>
      '¿Cuán frecuente es, y qué más podría ser?';

  @override
  String get screensExpertScientist => 'Científico';

  @override
  String get screensExpertScientistAs => 'Piensa como un científico';

  @override
  String get screensExpertScientistAsks => '¿Cómo sabríamos si fuera falso?';

  @override
  String get screensDotsTitle => 'Une los puntos';

  @override
  String get screensDotsLine =>
      'Elige un tema para ver dónde se cruza con los demás';

  @override
  String screensDotsMeets(int subjects, int cards) {
    String _temp0 = intl.Intl.pluralLogic(
      subjects,
      locale: localeName,
      other: 'Se cruza con $subjects temas',
      one: 'Se cruza con 1 tema',
    );
    String _temp1 = intl.Intl.pluralLogic(
      cards,
      locale: localeName,
      other: 'en $cards tarjetas',
      one: 'en 1 tarjeta',
    );
    return '$_temp0 $_temp1';
  }

  @override
  String get screensDotsWhere => 'Dónde se cruzan';

  @override
  String get screensDotsWhereLine => 'Una pregunta, dos maneras de mirarla';

  @override
  String get screensAskTitle => '¿Qué quieres entender?';

  @override
  String get screensAskHint => 'Pregunta lo que sea, o escribe una palabra';

  @override
  String get screensAskTry => 'Prueba';

  @override
  String get screensAskClear => 'Borrar la pregunta';

  @override
  String screensAskFound(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n tarjetas la responden',
      one: '1 tarjeta la responde',
    );
    return '$_temp0';
  }

  @override
  String get screensAskNone => 'Aún no hay ninguna tarjeta sobre eso';

  @override
  String get screensAskNoneLine =>
      'Guarda la pregunta. Cuando una tarjeta la responda, estará aquí, bajo la pregunta.';

  @override
  String get screensAskKeep => 'Guardar la pregunta';

  @override
  String get screensAskKept => 'Guardada';

  @override
  String get screensAskedTitle => 'Las preguntas que hiciste';

  @override
  String get screensAskedLine => 'Y las tarjetas que las respondieron';

  @override
  String get screensAskedAnswered => 'La respuesta';

  @override
  String get screensAskedWaiting =>
      'Aún no la responde ninguna tarjeta. Cuando alguna lo haga, estará aquí.';

  @override
  String get screensAskedForget => 'Olvidar esta pregunta';

  @override
  String get screensAskedForgotten => 'Pregunta olvidada';

  @override
  String get screensWhyTitle => 'Sigue preguntando por qué';

  @override
  String get screensWhyLine => 'Cada respuesta abre la siguiente pregunta';

  @override
  String get screensWhyAsk => '¿Por qué?';

  @override
  String screensWhyBottom(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n porqués de profundidad.',
      one: '1 porqué de profundidad.',
    );
    return '$_temp0 Más abajo no se puede ir.';
  }

  @override
  String get screensWhyAgain => 'Empezar de nuevo';

  @override
  String get screensWhyHoles => 'Más madrigueras de conejo';

  @override
  String get screensWhyHolesLine => 'Cada una baja unos cuantos porqués';

  @override
  String screensWhyCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n porqués',
      one: '1 porqué',
    );
    return '$_temp0';
  }

  @override
  String get screensWhyDeeper => 'Ve más a fondo';

  @override
  String screensWhySource(String source) {
    return 'Fuente: $source';
  }

  @override
  String screensWhyDepth(int at, int of) {
    String _temp0 = intl.Intl.pluralLogic(
      at,
      locale: localeName,
      other: '$at porqués',
      one: '1 porqué',
    );
    return '$_temp0 de $of';
  }

  @override
  String get screensTimeTitle => 'A través del tiempo';

  @override
  String get screensTimeLine =>
      'Época a época, hasta este año. Arrastra para viajar';

  @override
  String get screensTimeCaption =>
      'Años atrás. Cada marca está diez veces más lejos.';

  @override
  String get screensTimeNow => 'Hoy';

  @override
  String get screensTimeEarlier => 'Más atrás';

  @override
  String get screensTimeLater => 'Más cerca de hoy';

  @override
  String get screensEraAncient => 'El mundo antiguo';

  @override
  String get screensEraAncientWhen => 'Antes del 500';

  @override
  String get screensEraMedieval => 'La Edad Media';

  @override
  String get screensEraMedievalWhen => 'Del 500 al 1500';

  @override
  String get screensEraEarlyModern => 'La Edad Moderna';

  @override
  String get screensEraEarlyModernWhen => 'De 1500 a 1800';

  @override
  String get screensEraNineteenth => 'El siglo XIX';

  @override
  String get screensEraNineteenthWhen => 'De 1800 a 1900';

  @override
  String get screensEraTwentieth => 'El siglo pasado';

  @override
  String get screensEraTwentiethWhen => 'De 1900 a 2000';

  @override
  String get screensEraRecent => 'Este siglo';

  @override
  String get screensEraRecentWhen => 'Desde 2000';

  @override
  String get screensMindTitle => 'Cambia de opinión';

  @override
  String get screensMindLine =>
      'Di qué opinas antes de leer, y otra vez después';

  @override
  String get screensMindClaim => 'Afirmación';

  @override
  String get screensMindBefore => 'Antes de leer';

  @override
  String get screensMindTap => 'Toca dónde te sitúas';

  @override
  String get screensMindKnow => 'Lo que sabemos';

  @override
  String get screensMindNow => '¿Y ahora?';

  @override
  String get screensMindAgain => 'Toca otra vez';

  @override
  String screensMindLevel(String level) {
    String _temp0 = intl.Intl.selectLogic(level, {
      '0': 'Muy en desacuerdo',
      '1': 'En desacuerdo',
      '2': 'No lo sé',
      '3': 'De acuerdo',
      'other': 'Muy de acuerdo',
    });
    return '$_temp0';
  }

  @override
  String screensMindToward(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Diste $n pasos hacia lo que dicen las pruebas.',
      one: 'Diste 1 paso hacia lo que dicen las pruebas.',
    );
    return '$_temp0';
  }

  @override
  String get screensMindSame =>
      'Igual que antes. Una tarjeta es solo una tarjeta.';

  @override
  String get screensMindAlready =>
      'Ya estabas con las pruebas antes de leerlas.';

  @override
  String get screensMindAway =>
      'Te alejaste de las pruebas. Vale la pena releerla.';

  @override
  String get screensMindFirst =>
      'Primero di qué opinas. Un toque, antes de leer.';

  @override
  String screensMindChanged(int changed, int total) {
    return 'Cambiaste de opinión en $changed de $total.';
  }

  @override
  String get screensMindFoot =>
      'Una opinión que cambia es una tarjeta que hizo su trabajo.';

  @override
  String get screensSayTitle => 'Dilo esta noche';

  @override
  String get screensSayLine =>
      'Una frase para llevar a la cena. Toca cuando la hayas dicho';

  @override
  String get screensSayTonight => 'La frase de esta noche';

  @override
  String get screensSaySaid => 'La dije';

  @override
  String get screensSayDone => 'Dicha';

  @override
  String screensSayWeek(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Esta semana dijiste $n frases.',
      one: 'Esta semana dijiste 1 frase.',
      zero: 'Aún no has dicho nada esta semana.',
    );
    return '$_temp0';
  }

  @override
  String get screensSayCounts =>
      'Cada frase que dices también cuenta para el Top de la semana.';

  @override
  String get screensFrontName => 'The Astute';

  @override
  String get screensFrontEdition => 'Edición de hoy';

  @override
  String get screensFrontSame => 'Igual para todos';

  @override
  String get screensFrontLead => 'Apertura';

  @override
  String get screensFrontNumbers => 'En cifras';

  @override
  String get screensFrontCorrections => 'Fe de erratas';

  @override
  String get screensFrontPuzzle => 'El acertijo del día';

  @override
  String get screensFrontEnd => 'Esta es la edición de hoy';

  @override
  String get screensFrontTomorrow => 'La de mañana sale por la mañana';

  @override
  String exploreDayRead(int read, int of) {
    return 'Hoy: $read de $of leídas';
  }

  @override
  String exploreDayLeft(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'quedan $n',
      one: 'queda 1',
    );
    return '$_temp0';
  }

  @override
  String get exploreDayDone => 'todas leídas';

  @override
  String get exploreDayOpen => 'Ir a las cartas de hoy';

  @override
  String get exploreGameNone =>
      'Ahora mismo no hay nada que jugar aquí. Vuelve mañana.';

  @override
  String get challengesTitle => 'Desafíos';

  @override
  String get challengesLine =>
      'Ejercicios breves de juicio y estimación, de unos minutos cada uno.';

  @override
  String challengesPage(int n, int of) {
    return 'Página $n de $of';
  }

  @override
  String get gamePlay => 'Empezar';

  @override
  String get sixtyRules =>
      'Ocho afirmaciones, verdaderas o falsas, en un minuto. Mide lo bien que juzgas con prisa, que es como juzgamos casi todo lo que leemos.';

  @override
  String get sixtyReview => 'Las ocho afirmaciones';

  @override
  String get gameRight => 'Correcto';

  @override
  String get gameWrong => 'Incorrecto';

  @override
  String get gameUnanswered => 'Sin respuesta';

  @override
  String get gameNext => 'Siguiente desafío';

  @override
  String sixtyShareHead(String date) {
    return 'Astute · Sesenta segundos · $date';
  }

  @override
  String sixtyShareScore(int n, int of, int s) {
    return '$n de $of bien · $s s';
  }

  @override
  String sixtySecondsLeftLabel(int s) {
    String _temp0 = intl.Intl.pluralLogic(
      s,
      locale: localeName,
      other: 'Quedan $s segundos',
      one: 'Queda 1 segundo',
    );
    return '$_temp0';
  }

  @override
  String get gameReview => 'Las cartas';

  @override
  String get gameTomorrow => 'Nueva ronda mañana';

  @override
  String get gameContinue => 'Continuar';

  @override
  String gameShareHead(String game, String date) {
    return 'Astute · $game · $date';
  }

  @override
  String gameShareScore(int n, int of) {
    return '$n de $of bien';
  }

  @override
  String gameCardsToday(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n cartas hoy',
      one: '1 carta hoy',
    );
    return '$_temp0';
  }

  @override
  String get gameAllRight => 'Todas bien.';

  @override
  String gamePoints(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n puntos',
      one: '1 punto',
    );
    return '$_temp0';
  }

  @override
  String get gameSeeResult => 'Ver cómo fue';

  @override
  String get gameNextCard => 'Siguiente';

  @override
  String get spotOnce => 'Una elección al día';

  @override
  String get spotGotIt => 'Has encontrado la falsa.';

  @override
  String get spotMissedIt => 'Esa no: es verdadera.';

  @override
  String get tfRules =>
      'Afirmaciones en las que casi todos fallan. Di verdadero o falso y luego lee por qué. Mide el juicio: distinguir lo que es cierto de lo que solo parece obvio.';

  @override
  String get inOrderTitle => 'En orden';

  @override
  String get inOrderRules =>
      'Cuatro momentos de las cartas, sin su año, para ordenar según ocurrieron. Mide tu sentido de la cronología, la primera prueba de cualquier explicación: una causa va antes que su efecto.';

  @override
  String get inOrderFirst => 'Toca el momento que fue primero.';

  @override
  String get inOrderNext => 'Ahora el que vino después.';

  @override
  String get inOrderReady => 'Todos colocados.';

  @override
  String get inOrderCheck => 'Comprobar el orden';

  @override
  String inOrderPlaced(int n) {
    return 'En el puesto $n';
  }

  @override
  String inOrderYours(int n) {
    return 'Tu puesto: $n';
  }

  @override
  String get inOrderPerfect => 'Todos en su sitio.';

  @override
  String get timeGap => 'un año que falta';

  @override
  String get whatYearTitle => '¿Qué año?';

  @override
  String get whatYearRules =>
      'Tres momentos, sin su año. Marca el año de cada uno: cuanto más cerca, más puntos, hasta diez. Mide tu sentido de cuándo ocurrieron las cosas.';

  @override
  String whatYearPoints(int n, int of) {
    return '$n de $of puntos';
  }

  @override
  String get whatYearPerfect => 'Todos los años exactos.';

  @override
  String whatYearOffInAll(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n años de desvío en total.',
      one: '1 año de desvío en total.',
    );
    return '$_temp0';
  }

  @override
  String whatYearSaid(String guess, int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: 'Dijiste $guess · $points puntos',
      one: 'Dijiste $guess · 1 punto',
    );
    return '$_temp0';
  }

  @override
  String whatYearOff(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n años de desvío',
      one: '1 año de desvío',
    );
    return '$_temp0';
  }

  @override
  String whatYearEarlier(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n años antes',
      one: '1 año antes',
    );
    return '$_temp0';
  }

  @override
  String whatYearLater(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n años después',
      one: '1 año después',
    );
    return '$_temp0';
  }

  @override
  String get whatYearDial => 'Año';

  @override
  String get beforeAfterTitle => '¿Antes o después?';

  @override
  String get beforeAfterRules =>
      'Seis momentos, uno tras otro. Di si cada uno ocurrió antes o después del de arriba. Mide tu sentido de la secuencia.';

  @override
  String get beforeAfterBefore => 'Antes';

  @override
  String get beforeAfterAfter => 'Después';

  @override
  String beforeAfterAsk(String year) {
    return '¿Antes o después de $year?';
  }

  @override
  String beforeAfterSaidBefore(String year) {
    return 'Dijiste: antes de $year';
  }

  @override
  String beforeAfterSaidAfter(String year) {
    return 'Dijiste: después de $year';
  }

  @override
  String get beforeAfterStart => 'Aquí empezó la cadena';

  @override
  String get beforeAfterPerfect => 'Ni uno fuera de lugar.';

  @override
  String biggerPairsToday(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n parejas hoy',
      one: '1 pareja hoy',
    );
    return '$_temp0';
  }

  @override
  String get sixtySkill => 'Intuición';

  @override
  String get spotSkill => 'Discernimiento';

  @override
  String get tfSkill => 'Juicio';

  @override
  String get biggerSkill => 'Proporción';

  @override
  String get closerSkill => 'Estimación';

  @override
  String get magnitudeSkill => 'Escala';

  @override
  String get rangeSkill => 'Calibración';

  @override
  String get stakeSkill => 'Convicción';

  @override
  String get numberSkill => 'Precisión';

  @override
  String get inOrderSkill => 'Cronología';

  @override
  String get whatYearSkill => 'Datación';

  @override
  String get beforeAfterSkill => 'Secuencia';

  @override
  String get sixtyAsks => 'Ocho afirmaciones contra el reloj.';

  @override
  String get spotAsks => 'Cuatro afirmaciones, una de ellas falsa.';

  @override
  String get tfAsks => 'Afirmaciones en las que casi todos fallan.';

  @override
  String get biggerAsks => 'Dos cifras. ¿Cuál es mayor?';

  @override
  String get closerAsks => 'Acércate a una cifra, paso a paso.';

  @override
  String get magnitudeAsks => 'Encuentra la potencia de diez correcta.';

  @override
  String get rangeAsks => 'Un rango tan ancho como haga falta.';

  @override
  String get stakeAsks => 'Apuesta puntos según tu seguridad.';

  @override
  String get numberAsks => 'Comprométete con una sola cifra.';

  @override
  String get inOrderAsks => 'Cuatro momentos, del más antiguo.';

  @override
  String get whatYearAsks => 'Sitúa un momento en su año.';

  @override
  String get beforeAfterAsks => 'Cada momento frente al anterior.';

  @override
  String get challengeBest => 'Mejor marca';

  @override
  String get challengeToday => 'Hoy';

  @override
  String get challengeAccuracy => 'Aciertos';

  @override
  String get challengeTime => 'Tiempo';

  @override
  String challengeSeconds(int s) {
    return '$s s';
  }

  @override
  String get challengePersonalBest => 'Mejor marca personal';

  @override
  String challengeAboveChance(int n, int of) {
    return 'Por encima del azar: adivinando se acierta de media $n de $of.';
  }

  @override
  String challengeAtChance(int n, int of) {
    return 'Igual que el azar: adivinando se acierta de media $n de $of.';
  }

  @override
  String challengeBelowChance(int n, int of) {
    return 'Por debajo del azar: adivinando se acierta de media $n de $of.';
  }

  @override
  String sixtyUnanswered(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Se acabó el tiempo con $n afirmaciones sin responder.',
      one: 'Se acabó el tiempo con una afirmación sin responder.',
    );
    return '$_temp0';
  }

  @override
  String get challengeAgain => 'Otra ronda';

  @override
  String get spotRules =>
      'Cuatro afirmaciones: tres son verdaderas y una es falsa. Encuentra la falsa. Mide lo bien que distingues una afirmación fundada de una que solo suena bien.';

  @override
  String get spotAsk => 'Toca la afirmación que creas que es falsa.';

  @override
  String get biggerRules =>
      'Dos cifras, cada una la respuesta a la pregunta de una carta. Toca la que creas que es mayor. Mide tu sentido de la proporción.';

  @override
  String get biggerAsk => 'Toca la carta cuya respuesta es mayor.';

  @override
  String biggerRight(String big, String small) {
    return 'Correcto: $big es más que $small.';
  }

  @override
  String biggerWrong(String big, String small) {
    return 'Incorrecto: $big es más que $small.';
  }

  @override
  String get closerRules =>
      'Acércate a un porcentaje paso a paso: cada vez, di si está por encima o por debajo de la mitad de lo que queda. Mide tu capacidad de estimación.';

  @override
  String closerDoneSteps(String said, int right, int steps) {
    return 'Es $said: acertaste $right de $steps pasos.';
  }

  @override
  String closerExactSteps(String said, int right, int steps) {
    return 'Es exactamente $said: acertaste $right de $steps pasos.';
  }

  @override
  String closerStepsRight(int right, int steps) {
    return 'Acertaste $right de $steps pasos.';
  }

  @override
  String get magnitudeRules =>
      '¿Diez, mil o un millón? Elige la potencia de diez más cercana a la respuesta. Mide tu sentido de la escala, que importa más que las cifras exactas.';

  @override
  String get rangeRules =>
      'Fija tu estimación y luego un rango a su alrededor: cuanto más estrecho, más paga si la respuesta cae dentro. Mide la calibración: saber cuánto sabes.';

  @override
  String rangeOption(int w, int pts) {
    return '±$w · paga $pts';
  }

  @override
  String rangeIn(String said, int pts) {
    String _temp0 = intl.Intl.pluralLogic(
      pts,
      locale: localeName,
      other: 'Es $said: dentro de tu rango, +$pts puntos.',
      one: 'Es $said: dentro de tu rango, +1 punto.',
    );
    return '$_temp0';
  }

  @override
  String rangeOut(String said) {
    return 'Es $said: fuera de tu rango.';
  }

  @override
  String stakeRules(int points) {
    return 'Elige una respuesta y apuesta puntos por ella, de $points al día: si aciertas, tu apuesta se duplica; si no, la pierdes. Mide la convicción: apostar por lo que sabes, y solo por eso.';
  }

  @override
  String stakeWon(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Correcto: ganas $n puntos.',
      one: 'Correcto: ganas 1 punto.',
    );
    return '$_temp0';
  }

  @override
  String stakeLost(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Incorrecto: pierdes $n puntos.',
      one: 'Incorrecto: pierdes 1 punto.',
    );
    return '$_temp0';
  }

  @override
  String get numberRules =>
      'Fija una sola cifra con los botones y bloquéala. Mide la precisión: cuánto te acercas cuando tienes que comprometerte con un número.';

  @override
  String tfRightIs(String side) {
    String _temp0 = intl.Intl.selectLogic(side, {
      'true': 'Correcto: es verdadero.',
      'other': 'Correcto: es falso.',
    });
    return '$_temp0';
  }

  @override
  String tfWrongIs(String side) {
    String _temp0 = intl.Intl.selectLogic(side, {
      'true': 'Incorrecto: es verdadero.',
      'other': 'Incorrecto: es falso.',
    });
    return '$_temp0';
  }

  @override
  String inOrderTold(int n, int of) {
    return '$n de $of en su lugar.';
  }

  @override
  String get whatYearYours => 'Tu año';

  @override
  String get whatYearExactly => 'El año exacto';

  @override
  String beforeAfterRight(String side, String year, String above) {
    String _temp0 = intl.Intl.selectLogic(side, {
      'before': 'Correcto: fue en $year, antes de $above.',
      'other': 'Correcto: fue en $year, después de $above.',
    });
    return '$_temp0';
  }

  @override
  String beforeAfterWrong(String side, String year, String above) {
    String _temp0 = intl.Intl.selectLogic(side, {
      'before': 'Incorrecto: fue en $year, antes de $above.',
      'other': 'Incorrecto: fue en $year, después de $above.',
    });
    return '$_temp0';
  }

  @override
  String get challengeAnswer => 'Respuesta';

  @override
  String get challengeYouSaid => 'Dijiste';

  @override
  String get challengePoints => 'Puntos';

  @override
  String get challengeThisRound => 'Esta ronda';

  @override
  String get challengeLeftToday => 'Quedan hoy';

  @override
  String exploreSubjectLevel(String subject, int n) {
    return '$subject, nivel $n';
  }

  @override
  String exploreBecauseSaved(String question) {
    return 'Porque guardaste «$question»';
  }

  @override
  String get todaySeeAgain => 'Volver a verlas';

  @override
  String get todaySeeAgainHint =>
      'Las cartas de hoy otra vez, a tamaño completo, desde la primera';

  @override
  String get yourFiveFromToday => 'Tus cinco de hoy';

  @override
  String get dayMomentTitle => 'Día completado.';

  @override
  String get dayMomentLater => 'Más tarde';

  @override
  String get yourDayCard => 'Tu día';

  @override
  String get tuneTitle => 'Ajusta tu mezcla';

  @override
  String get tuneEntryLine => 'Cuánto de cada tema, y qué partes';

  @override
  String get tuneLearned =>
      'Ya ajustado por las cartas que te gustaron y las que descartaste. Desliza para cambiarlo.';

  @override
  String get tuneFresh => 'Desliza un tema para ver más o menos de él.';

  @override
  String get tuneHowMuch => 'Cuánto de cada uno';

  @override
  String get tuneInsideLine =>
      'Las partes que más te gustaron van primero. Toca una para saltarla, mantenla pulsada para ver dentro.';

  @override
  String get tuneSave => 'Guardar';

  @override
  String get tuneHoldHint =>
      'Mantén pulsado un género para abrir los temas de dentro';

  @override
  String get shareDayTitle => 'Comparte tu día';

  @override
  String get shareDayRead => 'Cinco cartas, leídas';

  @override
  String get shareDayTurn => 'Cinco cartas al día. Te toca.';

  @override
  String shareDaySure(int n) {
    return '$n% seguro';
  }

  @override
  String get shareDayHeadline => 'Las cinco de hoy';

  @override
  String get shareFormatCover => 'Portada';

  @override
  String get shareFormatList => 'Lista';

  @override
  String get shareFormatStory => 'Historia';

  @override
  String crowdGotRight(int n) {
    return 'El $n% de los lectores acertó';
  }

  @override
  String crowdGotWrong(int n) {
    return 'El $n% de los lectores también falló';
  }

  @override
  String get challengeFriend => 'Reta a un amigo';

  @override
  String get challengeLine => '¿Aciertas esta?';

  @override
  String pathFree(int n) {
    return '$n gratis';
  }

  @override
  String pathMoreTitle(int n) {
    return '$n más en este recorrido.';
  }

  @override
  String get pathMoreLine =>
      'Cada recorrido entero, de la carta más fácil a la más difícil, y una fila nueva cada semana.';

  @override
  String get pathMoreGo => 'Leer el recorrido entero';

  @override
  String get paywallPathsTitle => 'Cada recorrido, las diez.';

  @override
  String get paywallPathsMark => 'las diez.';

  @override
  String get paywallPathsLine =>
      'Diez cartas sobre un tema, de la más fácil a la más difícil. Recorridos nuevos cada semana y tus cinco del día a tu nivel.';

  @override
  String get widgetAskTitle =>
      'La primera carta de mañana, en tu pantalla de inicio.';

  @override
  String get widgetAskLine =>
      'Una carta nueva cada mañana sin abrir la app, y a su lado tu racha.';

  @override
  String get widgetAskStepHold =>
      'Mantén pulsado un espacio vacío de la pantalla de inicio.';

  @override
  String get widgetAskStepAppleAdd => 'Toca Editar y luego Añadir widget.';

  @override
  String get widgetAskStepApplePick =>
      'Busca Astute, elige un tamaño y toca Añadir widget.';

  @override
  String get widgetAskStepAndroidAdd => 'Toca Widgets.';

  @override
  String get widgetAskStepAndroidPick =>
      'Busca Astute, mantén pulsado un widget y arrástralo a su sitio.';

  @override
  String get widgetAskLockScreen =>
      'También en la pantalla de bloqueo: mantenla pulsada y toca Personalizar.';

  @override
  String get widgetAskPin => 'Añadir a la pantalla de inicio';

  @override
  String get widgetAskGotIt => 'Entendido';

  @override
  String get widgetAskNotNow => 'Ahora no';

  @override
  String pathCardOf(int n, int total) {
    return 'Carta $n de $total';
  }

  @override
  String get pathDoorNext => 'Siguiente del recorrido';

  @override
  String get shareSendCard => 'Enviar la carta';

  @override
  String get shareAsImage => 'Como imagen';

  @override
  String get shareCopyLink => 'Copiar enlace';

  @override
  String get shareAnswerNote =>
      'Tu amigo ve primero la pregunta. La respuesta está a un toque, en la página de la carta.';

  @override
  String get shareWhichSide => '¿De qué lado estás?';

  @override
  String get rereadRight => 'La primera vez acertaste.';

  @override
  String get rereadWrong => 'La primera vez fallaste.';

  @override
  String betsDayShareLine(int off) {
    String _temp0 = intl.Intl.pluralLogic(
      off,
      locale: localeName,
      other: 'me desvié $off puntos',
      one: 'me desvié 1 punto',
      zero: 'di en el clavo',
    );
    return 'La apuesta del día en Astute: $_temp0. ¿Lo haces mejor?';
  }

  @override
  String get playTheCard => 'Jugar la carta';

  @override
  String get openTheCard => 'Abrir la carta';

  @override
  String get perkPathsTitle => 'Cada ruta, entera';

  @override
  String get perkPathsLine =>
      'Diez cartas sobre un tema, de la más fácil a la más difícil. Rutas nuevas cada semana.';

  @override
  String get journeyStrongest => 'Tu punto fuerte';

  @override
  String get journeyMostMissed => 'Lo que más fallas';

  @override
  String journeyRightShare(String pct) {
    return '$pct de aciertos';
  }

  @override
  String get journeyChangedMind => 'Cambiaste de idea';

  @override
  String get journeyNewToYou => 'Nuevo para ti';

  @override
  String journeyReactedOf(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'de $n tarjetas que lo preguntaron',
      one: 'de 1 tarjeta que lo preguntó',
    );
    return '$_temp0';
  }

  @override
  String journeyKnewAlready(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n ya las sabías',
      one: '1 ya la sabías',
    );
    return '$_temp0';
  }

  @override
  String get storyLabTitle => 'Tu recorrido, como una historia';

  @override
  String get storyLabNote => 'Versión nueva · a prueba, solo TestFlight';

  @override
  String get storyChapterWeek => 'Esta semana';

  @override
  String get storyChapterWhere => 'Dónde estás';

  @override
  String get storyChapterReason => 'Cómo razonas';

  @override
  String get storyChapterPractice => 'Practica';

  @override
  String get storyChapterStory => 'Tu historia';

  @override
  String get journeyChapterKnow => 'Lo que sabes';

  @override
  String get journeyChapterHabits => 'Tus hábitos';

  @override
  String get journeyChapterCoach => 'Tu coach';

  @override
  String get coachTeaser =>
      'Cada semana, una nota de tu coach sobre cómo razonas: qué salió bien, la trampa que vigilar y qué probar después.';

  @override
  String get coachRead => 'Leer la nota de esta semana';

  @override
  String storyHeadlineSure(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          'En las respuestas dadas con seguridad, acertaste $n veces de cada 10.',
      one: 'En las respuestas dadas con seguridad, acertaste 1 vez de cada 10.',
    );
    return '$_temp0';
  }

  @override
  String get storyBetter => 'Mejor que la semana pasada.';

  @override
  String get storyWorse => 'Un poco menos que la semana pasada.';

  @override
  String storyHeadlineStreak(int n) {
    return '$n días seguidos. No pierdas el hilo.';
  }

  @override
  String storyHeadlineStrong(String subject, String pct) {
    return 'En $subject aciertas el $pct de las veces.';
  }

  @override
  String storyHeadlineRead(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n tarjetas leídas. El recorrido empieza aquí.',
      one: 'Una tarjeta leída. El recorrido empieza aquí.',
      zero: 'Tu primera tarjeta te espera.',
    );
    return '$_temp0';
  }

  @override
  String storyHeadlineReadWeek(int n, int week) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n tarjetas leídas',
      one: 'Una tarjeta leída',
    );
    String _temp1 = intl.Intl.pluralLogic(
      week,
      locale: localeName,
      other: '$week esta semana.',
      one: 'una esta semana.',
      zero: 'ninguna aún esta semana.',
    );
    return '$_temp0, $_temp1';
  }

  @override
  String storyHeadlineReadAllWeek(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n tarjetas leídas, todas esta semana.',
      one: 'Una tarjeta leída hasta ahora.',
    );
    return '$_temp0';
  }

  @override
  String storySaidRight(String sure, String right) {
    return 'Tu seguridad: $sure. Aciertas el $right de las veces.';
  }

  @override
  String storySaidRightToGo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n respuestas más diciendo cuánta seguridad tienes, y se mide.',
      one: 'Una respuesta más diciendo cuánta seguridad tienes, y se mide.',
    );
    return '$_temp0';
  }

  @override
  String storyOverconfident(String subject, int points) {
    return 'Donde te confías demasiado: $subject, por $points puntos.';
  }

  @override
  String get storyUnlock => 'Velo con Astute+';

  @override
  String storyPracticeMisses(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Las $n que fallaste con seguridad',
      one: 'La que fallaste con seguridad',
    );
    return '$_temp0';
  }

  @override
  String storyPracticeChanged(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Las $n que te hicieron cambiar de idea',
      one: 'La tarjeta que te hizo cambiar de idea',
    );
    return '$_temp0';
  }

  @override
  String storyPracticeBlind(String subject) {
    return '5 tarjetas nuevas de $subject';
  }

  @override
  String get storyPracticeNone =>
      'Aún nada que practicar: responde algunas tarjetas y llegará.';

  @override
  String get storyFirstCard => 'Primera tarjeta';

  @override
  String storyReached(String level) {
    return 'Alcanzado: $level';
  }

  @override
  String storyBestStreak(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Mejor racha: $n días',
      one: 'Mejor racha: 1 día',
    );
    return '$_temp0';
  }

  @override
  String storyCardsRead(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n tarjetas leídas',
      one: '1 tarjeta leída',
    );
    return '$_temp0';
  }

  @override
  String get storyToday => 'Hoy';

  @override
  String get storySeePath => 'Ver el camino';

  @override
  String exploreFreshCards(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n tarjetas nuevas arriba',
      one: '1 tarjeta nueva arriba',
    );
    return '$_temp0';
  }

  @override
  String get exploreUpToDate => 'Estás al día: por ahora nada nuevo.';

  @override
  String get deeperTitle => 'Profundiza';

  @override
  String get deeperSimple => 'Explícamelo fácil';

  @override
  String get deeperWhy => 'Por qué importa';

  @override
  String get deeperSides => 'Las dos partes';

  @override
  String get deeperExample => 'Un ejemplo de la vida diaria';

  @override
  String get deeperQuiz => 'Ponme a prueba con un caso nuevo';

  @override
  String get deeperQuizRight => 'Correcto.';

  @override
  String get deeperQuizWrong => 'No del todo.';

  @override
  String get mathsDailySolve => 'Resuélvelo';

  @override
  String get mathsDailySolved => 'Resuelto';

  @override
  String get mathsDailyMissed => 'Esta vez no';

  @override
  String get mathsDailyTomorrow => 'Mañana, uno nuevo';

  @override
  String get mathsDailyAnother => 'Otro como este';

  @override
  String goalShelf(String goal) {
    return 'Te sirve para: $goal';
  }

  @override
  String get goalDecide => 'Decisiones del día a día';

  @override
  String get goalPeople => 'Las personas';

  @override
  String get goalBusiness => 'Trabajo y negocios';

  @override
  String get goalMoney => 'Dinero y compras';

  @override
  String get goalHealth => 'Salud';

  @override
  String get goalDecideLine =>
      'Elecciones, riesgos y probabilidades, sin corazonadas.';

  @override
  String get goalNews => 'Noticias y redes';

  @override
  String get goalNewsLine =>
      'Titulares, estadísticas y posts: qué se sostiene.';

  @override
  String get goalPeopleLine =>
      'Quién quiere convencerte, y cómo hacerte entender.';

  @override
  String get goalBusinessLine =>
      'Negociaciones, incentivos y los números detrás de una idea.';

  @override
  String get goalMoneyLine =>
      'Precios, ofertas, intereses: las trampas de un trato.';

  @override
  String get goalHealthLine =>
      'Dietas, curas y estudios: lo que dicen las pruebas.';

  @override
  String mathsDailyStreak(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n días seguidos',
      one: '1 día seguido',
    );
    return '$_temp0';
  }

  @override
  String get deeperYourTake => 'Tu idea, analizada';

  @override
  String get deeperYourTakeHint => 'Escribe lo que piensas…';

  @override
  String get deeperAnalyse => 'Analizar';

  @override
  String get deeperAsk => 'Pregunta sobre esta tarjeta';

  @override
  String get deeperAskHint => 'Tu pregunta…';

  @override
  String get deeperSend => 'Preguntar';

  @override
  String get deeperSource => 'Fuente';

  @override
  String get deeperOpenSource => 'Abrir el original';

  @override
  String get deeperAiNote => 'Responde una IA: puede equivocarse.';

  @override
  String get deeperBusy => 'Pensando…';

  @override
  String get deeperTomorrow => 'Por hoy basta: mañana más.';

  @override
  String get deeperTryAgain => 'No llegó. Inténtalo de nuevo en un momento.';

  @override
  String get deeperUnavailable =>
      'No está disponible ahora mismo. Inténtalo más tarde.';

  @override
  String newsOutlets(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n medios',
      one: '1 medio',
    );
    return '$_temp0';
  }

  @override
  String newsHoursAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Hace $n h',
      zero: 'Ahora mismo',
    );
    return '$_temp0';
  }

  @override
  String newsDaysAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Hace $n días',
      one: 'Ayer',
    );
    return '$_temp0';
  }

  @override
  String get newsWorld => 'Mundo';

  @override
  String get newsKeyPoints => 'Puntos clave';

  @override
  String get newsBehind => 'Detrás de la noticia';

  @override
  String get newsMeansForYou => 'Qué significa para ti';

  @override
  String get newsMeans => 'Qué significa';

  @override
  String get newsHappenedBefore => 'Ya pasó antes';

  @override
  String get newsSources => 'Fuentes';

  @override
  String get newsMadeFrom =>
      'Escrito por Astute a partir de estas noticias, y contrastado con ellas.';

  @override
  String get newsWhyItMatters => 'Por qué importa';

  @override
  String get deeperDeclined => 'A esta no puede responder.';

  @override
  String get deeperPlusOnly => 'Con Astute+';

  @override
  String get deeperSimpleLead =>
      'La idea de la tarjeta, como se la contarías a un niño curioso de diez años.';

  @override
  String get deeperSidesLead =>
      'Los argumentos más fuertes de cada parte, y qué zanjaría la cuestión.';

  @override
  String get deeperExampleLead =>
      'Un momento de un día cualquiera en el que aparece esta idea.';

  @override
  String get deeperQuizLead =>
      'Un caso que la tarjeta no menciona: una pregunta, tres respuestas.';

  @override
  String get deeperYourTakeLead =>
      'Qué se sostiene en tu razonamiento, dónde falla y una pregunta para ponerlo a prueba.';

  @override
  String get deeperAskLead =>
      'Lo que la tarjeta te dejó con ganas de preguntar.';

  @override
  String get deeperSideA => 'Una parte';

  @override
  String get deeperSideB => 'La otra parte';

  @override
  String get deeperVersus => 'VS';

  @override
  String get deeperRetry => 'Reintentar';

  @override
  String get deeperSimpleGo => 'Explícamelo';

  @override
  String get deeperSidesGo => 'Muéstrame las dos partes';

  @override
  String get deeperExampleGo => 'Dame un ejemplo';

  @override
  String get deeperQuizGo => 'Ponme a prueba';

  @override
  String get bookOfTheWeek => 'Libro de la semana';

  @override
  String bookIdeas(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n ideas',
      one: '1 idea',
    );
    return '$_temp0';
  }

  @override
  String bookMoreTitle(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n ideas más de este libro',
      one: 'Una idea más de este libro',
    );
    return '$_temp0';
  }

  @override
  String get bookMoreLine =>
      'El libro entero con Astute+, y cada semana un libro gratis.';

  @override
  String get bookMoreGo => 'Leer el libro entero';

  @override
  String bookMinutes(int n) {
    return '$n min';
  }

  @override
  String get bookStart => 'Empezar a leer';

  @override
  String get bookContinue => 'Continuar';

  @override
  String get bookAgain => 'Leer de nuevo';

  @override
  String get bookTheIdeas => 'Las ideas';

  @override
  String get bookRecommendedBy => 'Recomendado por';

  @override
  String get bookFreeThisWeek => 'Gratis esta semana';

  @override
  String get booksSeeAll => 'Ver todos';

  @override
  String get booksLibraryTitle => 'Todos los libros';

  @override
  String get bookDoneTitle => 'Libro terminado';

  @override
  String bookDoneLine(int ideas, int minutes) {
    return '$ideas grandes ideas, en $minutes minutos.';
  }

  @override
  String bookDoneCount(int count) {
    return 'Libros terminados: $count';
  }

  @override
  String get bookDoneNext => 'Siguiente libro';

  @override
  String get bookDoneGo => 'Ábrelo';

  @override
  String bookRetold(String title, String author) {
    return 'Las ideas de $title, de $author, contadas con palabras de Astute. Para el libro entero, búscalo en tu librería.';
  }

  @override
  String get foundersTitle => 'Lo que leen los fundadores';

  @override
  String founderBookCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n libros',
      one: '1 libro',
    );
    return '$_temp0';
  }

  @override
  String get founderTheirBooks => 'Los libros que ha recomendado';

  @override
  String founderRole(String id, String role) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'bill_gates': 'Cofundador de Microsoft',
      'warren_buffett': 'El inversor que construyó Berkshire Hathaway',
      'mark_zuckerberg': 'Fundador de Facebook',
      'charlie_munger': 'Socio de Warren Buffett en Berkshire Hathaway',
      'marc_andreessen': 'Cofundador de Netscape y de Andreessen Horowitz',
      'tobi_lutke': 'Fundador de Shopify',
      'naval_ravikant': 'Cofundador de AngelList',
      'other': '$role',
    });
    return '$_temp0';
  }

  @override
  String founderWhere(String id, String where) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'gates_summer': 'GatesNotes, sus libros para el verano',
      'berkshire_meeting': 'la junta anual de Berkshire Hathaway',
      'berkshire_letter': 'su carta a los accionistas de Berkshire Hathaway',
      'year_of_books': 'A Year of Books, en Facebook',
      'publisher_praise': 'su elogio del libro, en la web de la editorial',
      'ferriss_five':
          'The Tim Ferriss Show, entre los cinco mejores libros que ha leído',
      'other': '$where',
    });
    return '$_temp0';
  }

  @override
  String founderAbout(String name) {
    return 'Son libros que $name recomendó en público, con las palabras citadas y dónde las dijo. $name no tiene ninguna relación con Astute.';
  }

  @override
  String founderPhoto(String author, String licence) {
    return 'Foto: $author, $licence, Wikimedia Commons, recortada';
  }

  @override
  String founderAlso(String names) {
    return 'También lo recomendó $names';
  }

  @override
  String get firstCardTitle => 'Tu primera tarjeta';

  @override
  String get firstCardSwipeOn => 'Desliza para seguir';

  @override
  String get trialOfferTitle => 'Prueba todo Astute+.';

  @override
  String get trialOfferMark => 'Astute+.';

  @override
  String get trialOfferLine =>
      'Las cinco tarjetas de hoy te esperan de todos modos.';

  @override
  String get trialStepToday => 'Hoy';

  @override
  String get trialStepTodayLine => 'Se abre todo Astute+. No pagas nada.';

  @override
  String trialStepDay(int day) {
    return 'Día $day';
  }

  @override
  String trialStepReminderLine(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Te enviamos una notificación: faltan $days días.',
      one: 'Te enviamos una notificación: falta 1 día.',
    );
    return '$_temp0';
  }

  @override
  String get trialStepChargeLine =>
      'Se renueva cada año. Cancela al menos 24 horas antes y no pagas nada.';

  @override
  String get trialOfferStart => 'Empezar la prueba';

  @override
  String get trialOfferFree => 'Seguir gratis';

  @override
  String get paywallStepFree => 'Todo gratis';

  @override
  String get paywallStepRemind => 'Te avisamos';

  @override
  String get paywallChargedToday => 'Se cobra hoy · Cancela cuando quieras';

  @override
  String paywallGoalTitle(String goal) {
    String _temp0 = intl.Intl.selectLogic(goal, {
      'decide': 'Para quien quiere decidir mejor.',
      'money': 'Para quien no se deja engañar con el dinero.',
      'people': 'Para quien quiere entender a la gente.',
      'news': 'Para quien no se traga los titulares.',
      'health': 'Para quien quiere pruebas sobre su salud.',
      'business': 'Para quien quiere ver claro en el trabajo.',
      'other': 'Para quien quiere ver claro.',
    });
    return '$_temp0';
  }

  @override
  String paywallGoalMark(String goal) {
    String _temp0 = intl.Intl.selectLogic(goal, {
      'decide': 'mejor.',
      'money': 'dinero.',
      'people': 'gente.',
      'news': 'titulares.',
      'health': 'salud.',
      'business': 'trabajo.',
      'other': 'claro.',
    });
    return '$_temp0';
  }

  @override
  String paywallMadeLine(String subjects) {
    return 'Cinco tarjetas al día de $subjects, a tu nivel. Las que fallas vuelven hasta que se te quedan. Y te ves cambiar, semana a semana.';
  }

  @override
  String subjectsTwo(String a, String b) {
    return '$a y $b';
  }

  @override
  String subjectsThree(String a, String b, String c) {
    return '$a, $b y $c';
  }

  @override
  String get firstWeekTitle => 'Tu primera semana';

  @override
  String get firstMonthTitle => 'Tu primer mes';

  @override
  String firstOfferDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n días de lectura',
      one: 'Un día de lectura',
    );
    return '$_temp0';
  }

  @override
  String get firstWeekBest => 'La mejor tarjeta de la semana';

  @override
  String get firstMonthBest => 'La mejor tarjeta del mes';

  @override
  String firstOfferBestWhy(String why) {
    String _temp0 = intl.Intl.selectLogic(why, {
      'said': 'Se la contaste a alguien.',
      'liked': 'Te gustó.',
      'saved': 'La guardaste.',
      'changed': 'Te hizo cambiar de idea.',
      'other': 'Te la quedaste.',
    });
    return '$_temp0';
  }

  @override
  String firstOfferTrialTitle(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Astute+, gratis durante $days días',
      one: 'Astute+, gratis durante un día',
    );
    return '$_temp0';
  }

  @override
  String get firstOfferPlusLine =>
      'Cinco tarjetas tuyas cada día, cada ruta y cada libro, y tus números semana a semana.';

  @override
  String get firstOfferNotNow => 'Ahora no';

  @override
  String get listenEntry => 'Escucha las cinco de hoy';

  @override
  String get listenEntryShort => 'Escuchar';

  @override
  String get listenTitle => 'Las cinco de hoy';

  @override
  String get listenQuestion => 'Pregunta';

  @override
  String get listenThink => 'Piénsalo…';

  @override
  String get listenAnswer => 'Respuesta';

  @override
  String get listenPreparing => 'Preparando la voz…';

  @override
  String get listenWaiting => 'La siguiente tarjeta está en camino…';

  @override
  String get listenFreeNote =>
      'La primera tarjeta es gratis; las demás, con Astute+.';

  @override
  String get listenOfferTitle =>
      'El resto de las tarjetas de hoy, leídas para ti';

  @override
  String get listenOfferLine =>
      'Con Astute+ escuchas las cinco cada día, incluso con la pantalla bloqueada.';

  @override
  String get listenNothing => 'Esta tarjeta no tiene nada que escuchar';

  @override
  String get listenCardUnavailable => 'No disponible ahora';

  @override
  String get listenUnavailable =>
      'La escucha no está disponible ahora. Vuelve a intentarlo más tarde.';

  @override
  String get listenDone => 'Todas las tarjetas de hoy, escuchadas.';

  @override
  String get listenAgain => 'Escuchar otra vez';

  @override
  String get listenNextCard => 'Siguiente tarjeta';

  @override
  String summaryReadIn(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'Léelo en $minutes minutos',
      one: 'Léelo en 1 minuto',
    );
    return '$_temp0';
  }

  @override
  String get summaryContinue => 'Seguir leyendo';

  @override
  String get summaryAgain => 'Volver a leer';

  @override
  String summaryPartOf(int part, int of) {
    return 'Parte $part de $of';
  }

  @override
  String summaryMinutesLeft(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'quedan $n min',
      one: 'queda 1 min',
    );
    return '$_temp0';
  }

  @override
  String summaryListenFor(int minutes) {
    return 'Escuchar · $minutes min';
  }

  @override
  String get summaryPause => 'Pausa';

  @override
  String get summaryResume => 'Seguir escuchando';

  @override
  String get summaryFreeNote =>
      'La primera parte es gratis; el resto, con Astute+.';

  @override
  String get summaryTitle => 'El resumen';

  @override
  String get summaryNowPlaying => 'Sonando ahora';

  @override
  String get summaryNextPart => 'Siguiente parte';

  @override
  String get summaryFinish => 'Terminar';

  @override
  String get summaryContents => 'Índice';

  @override
  String summaryDoneTitle(String title) {
    return 'Has leído $title';
  }

  @override
  String get summaryDoneLine =>
      'Las cartas del libro sirven para que sus ideas se queden.';

  @override
  String get summaryToCards => 'Las ideas en cartas';

  @override
  String get summaryBackToBook => 'Volver al libro';

  @override
  String get summaryGateTitle => 'El resto del resumen llega con Astute+';

  @override
  String summaryGateLine(int parts) {
    return 'Las $parts partes, para leer y escuchar, de cada libro. El libro de la semana es gratis para todos.';
  }

  @override
  String get summaryNeedsNetwork => 'Este resumen necesita internet una vez.';

  @override
  String get bookAudioBack => 'Retroceder 15 segundos';

  @override
  String get bookAudioWaiting => 'La siguiente parte está en camino…';

  @override
  String get bookAudioDone => 'Escuchado hasta el final.';

  @override
  String get bookAudioOfferTitle => 'Escucha el resto del libro';

  @override
  String get bookAudioOfferLine =>
      'Con Astute+ te leemos cada resumen completo, incluso con la pantalla bloqueada.';

  @override
  String get bookAudioStop => 'Dejar de escuchar';

  @override
  String get bookAudioOpen => 'Abrir el reproductor';

  @override
  String get inviteSection => 'Amigos';

  @override
  String get inviteRow => 'Invita a un amigo';

  @override
  String get inviteRowLine => 'Una semana de Astute+ para los dos';

  @override
  String get inviteCodeRow => '¿Tienes un código?';

  @override
  String get inviteCodeAccepted => 'Código aceptado';

  @override
  String get inviteCodeAcceptedLine =>
      'Tu semana empieza cuando termines tu primer día';

  @override
  String get inviteSheetLine =>
      'Envía tu código a un amigo. Cuando termine su primer día, las cinco tarjetas, cada uno tendrá una semana de Astute+.';

  @override
  String get inviteYourCode => 'Tu código';

  @override
  String get inviteCopy => 'Copiar';

  @override
  String get inviteSend => 'Enviar la invitación';

  @override
  String inviteRules(int cap) {
    return 'Vale para una cuenta nueva que nunca ha tenido Astute+. Recibes hasta $cap semanas al año.';
  }

  @override
  String inviteWeeksSoFar(int n, int cap) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n semanas de $cap este año',
      one: '1 semana de $cap este año',
    );
    return '$_temp0';
  }

  @override
  String inviteCapped(int cap) {
    return 'Ya has tenido las $cap semanas de este año. Tus amigos siguen recibiendo la suya.';
  }

  @override
  String inviteMessage(String code, String link) {
    return 'Te invito a Astute: cinco tarjetas al día para mantener la mente ágil. Con mi código $code, cuando termines tu primer día tendremos una semana de Astute+ cada uno.\n$link';
  }

  @override
  String inviteMessageCapped(String code, String link) {
    return 'Te invito a Astute: cinco tarjetas al día para mantener la mente ágil. Con mi código $code, cuando termines tu primer día tendrás una semana de Astute+ de regalo.\n$link';
  }

  @override
  String get inviteCodeTitle => 'El código de un amigo';

  @override
  String get inviteCodeLine =>
      'Escribe el código que te envió un amigo. Cuando termines tu primer día, cada uno tendrá una semana de Astute+.';

  @override
  String get inviteCodeUse => 'Usar el código';

  @override
  String get inviteCodeWaitingLine =>
      'Termina tu primer día, las cinco tarjetas: entonces empieza la semana de Astute+, para ti y para el amigo que te invitó.';

  @override
  String get inviteRefusedUnknown =>
      'Ese código no existe. Revisa las letras y vuelve a intentarlo.';

  @override
  String get inviteRefusedOwn => 'Es tu propio código: envíaselo a un amigo.';

  @override
  String get inviteRefusedUsed => 'Ya has usado el código de un amigo.';

  @override
  String get inviteRefusedLate =>
      'Los códigos son para cuentas nuevas, en su primera semana.';

  @override
  String get inviteRefusedPlus =>
      'Los códigos son para cuentas que nunca han tenido Astute+.';

  @override
  String get inviteSuccessTitle => 'Una semana de Astute+, de regalo.';

  @override
  String get inviteSuccessPlan => 'Astute+ · una semana';

  @override
  String inviteSuccessUntil(String date) {
    return 'Hasta el $date';
  }

  @override
  String get inviteSuccessFoot =>
      'Nada que pagar y nada que cancelar: después vuelves al plan gratuito.';

  @override
  String inviteEarned(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          '$n amigos terminaron su primer día: $n semanas de Astute+ para ti.',
      one: 'Un amigo terminó su primer día: una semana de Astute+ para ti.',
    );
    return '$_temp0';
  }

  @override
  String get firstDayTitle => 'Has terminado tu primer día';

  @override
  String firstDaySureRight(int sure, int right, int total) {
    return 'Estabas seguro al $sure%, y acertaste $right de $total.';
  }

  @override
  String firstDayRight(int right, int total) {
    return 'Acertaste $right de $total.';
  }

  @override
  String get firstDayRemind => 'Recuérdamelo mañana';

  @override
  String firstDayReminded(String time) {
    return 'Te lo recordaremos mañana a las $time.';
  }

  @override
  String get earlyReadingTag => 'Primera lectura';

  @override
  String earlyReadingAll(int level, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n veces, y acertaste todas',
      two: 'dos veces, y acertaste las dos',
      one: 'una vez, y acertaste',
    );
    return 'Hasta ahora: has dicho $level% $_temp0.';
  }

  @override
  String earlyReadingNone(int level, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n veces, y fallaste todas',
      two: 'dos veces, y fallaste las dos',
      one: 'una vez, y fallaste',
    );
    return 'Hasta ahora: has dicho $level% $_temp0.';
  }

  @override
  String earlyReadingSome(int level, int n, int right) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n veces',
      two: 'dos veces',
    );
    String _temp1 = intl.Intl.pluralLogic(
      right,
      locale: localeName,
      other: '$right veces',
      two: 'dos veces',
      one: 'una vez',
    );
    return 'Hasta ahora: has dicho $level% $_temp0, y acertaste $_temp1.';
  }

  @override
  String get journeyClearEyebrow => 'Esta semana, a la vista';

  @override
  String journeyClearBlind(String subject) {
    return 'Tu punto ciego: $subject';
  }

  @override
  String journeyClearStrong(String subject) {
    return 'Tu punto fuerte: $subject';
  }

  @override
  String journeyClearShare(String pct, int n) {
    return '$pct de aciertos en tus últimas $n respuestas de esta materia.';
  }

  @override
  String journeyClearMemoryDays(int days, int right, int of) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days días',
      two: 'dos días',
      one: 'un día',
    );
    return 'Tras $_temp0, aún recuerdas $right de $of.';
  }

  @override
  String journeyClearMemoryWeeks(int weeks, int right, int of) {
    String _temp0 = intl.Intl.pluralLogic(
      weeks,
      locale: localeName,
      other: '$weeks semanas',
      one: 'una semana',
    );
    return 'Tras $_temp0, aún recuerdas $right de $of.';
  }

  @override
  String get journeyClearBlindNotYet =>
      'Seis respuestas en dos materias y aquí aparece la que más fallas.';

  @override
  String get journeyClearStrongNotYet =>
      'Seis respuestas en una materia y aquí aparece la que mejor se te da.';

  @override
  String journeyClearSureNotYet(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          '$n respuestas más diciendo cuánta seguridad tienes, y aquí aparece una primera lectura.',
      one: 'Una respuesta más diciendo cuánta seguridad tienes, y aquí aparece una primera lectura.',
    );
    return '$_temp0';
  }

  @override
  String get journeyClearMemoryNotYet =>
      'Las tarjetas vuelven a los 2, 7 y 21 días: aquí verás cuántas recuerdas aún.';

  @override
  String get journeyPreviewDoor =>
      'Cada semana, una cifra distinta. Astute+ abre el resto.';

  @override
  String weekSheetOf(String date) {
    return 'La semana del $date';
  }

  @override
  String weekSheetRightValue(int right, int n) {
    return '$right de $n';
  }

  @override
  String get weekSheetRightLabel => 'Respuestas acertadas';

  @override
  String weekSheetAcross(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'en $n respuestas',
      one: 'en 1 respuesta',
    );
    return '$_temp0';
  }

  @override
  String get weekSheetOverLabel => 'Donde te confías demasiado';

  @override
  String get weekSheetMemoryLabel => 'Lo que aún recuerdas';

  @override
  String get weekSheetAccount => 'Conserva tu semana en cualquier móvil';
}

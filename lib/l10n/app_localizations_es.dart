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
      'Ninguna tarjeta coincide aún con ese filtro.';

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
      'Cada tarjeta dice de dónde salen sus datos, para que puedas comprobarlo tú. La mayoría las lee un segundo modelo que hace de crítico, y lo que no puede confirmar va a una lista que revisa una persona. Esa lista aún no está vacía.';

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
  String youSaidItIsCounted(String given, String answer, String band) {
    return 'Dijiste $given · es $answer, y $band cuenta';
  }

  @override
  String youSaidItIs(String given, String answer) {
    return 'Dijiste $given · es $answer';
  }

  @override
  String lineYouSaidSure(String line, int pct) {
    return '$line · dijiste $pct% seguro';
  }

  @override
  String get verdictRight => 'Correcto.';

  @override
  String get verdictClose => 'Bastante cerca.';

  @override
  String get verdictWrong => 'No exactamente.';

  @override
  String verdictSure(int pct) {
    return 'Estabas seguro al $pct%.';
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
  String get topEmpty =>
      'Aún no hay nada en la lista. Cada tarjeta que te gusta, guardas o cuentas suma.';

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
  String get weekRecapCaps => 'ESTA SEMANA TE PREGUNTASTE';

  @override
  String get weekRecapLine => 'Las preguntas que te dejaron tus tarjetas';

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
    return 'En $where';
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
    return 'Has leído el $percent % de $subject, lo que menos';
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
  String get betsLock => 'Fijar';

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
    return 'Bien: es más de $v.';
  }

  @override
  String betsCloserYesLess(String v) {
    return 'Bien: es menos de $v.';
  }

  @override
  String betsCloserNoMore(String v) {
    return 'No: es más de $v.';
  }

  @override
  String betsCloserNoLess(String v) {
    return 'No: es menos de $v.';
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
  String get betsDayLine => 'Fija tu estimación y mira cuánto te desviaste';

  @override
  String get betsDayTag => 'Apuesta del día';

  @override
  String get betsDayTagSame => 'Apuesta del día · la misma para todos';

  @override
  String get betsLockIn => 'Fijar';

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
}

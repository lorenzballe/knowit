// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appName => 'Astut';

  @override
  String get plusName => 'Astut+';

  @override
  String get tabToday => 'Hoje';

  @override
  String get tabExplore => 'Explorar';

  @override
  String get tabProfile => 'Perfil';

  @override
  String signInNotConnected(String provider) {
    return 'O login com $provider ainda não está ligado. Os teus cartões ficam neste aparelho.';
  }

  @override
  String couldNotSignInCarryOn(String label) {
    return 'Não foi possível entrar com $label. Podes continuar sem conta.';
  }

  @override
  String streakDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n dias',
      one: '1 dia',
    );
    return '$_temp0';
  }

  @override
  String get freezeKeptStreak => 'Um freeze salvou a sequência';

  @override
  String get holdACardToKeepIt => 'Mantém um cartão premido para o guardar';

  @override
  String keptToday(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n guardados hoje',
      one: '1 guardado hoje',
    );
    return '$_temp0';
  }

  @override
  String countWord(String n) {
    String _temp0 = intl.Intl.selectLogic(n, {
      '1': 'um',
      '2': 'dois',
      '3': 'três',
      '4': 'quatro',
      '5': 'cinco',
      '6': 'seis',
      '7': 'sete',
      '8': 'oito',
      '9': 'nove',
      '10': 'dez',
      'other': '$n',
    });
    return '$_temp0';
  }

  @override
  String dayRead(int n, String word) {
    return 'Dia $n · $word lidos';
  }

  @override
  String shelfEyebrow(String word) {
    return 'OS $word DE HOJE · DESLIZA PARA REVER';
  }

  @override
  String weekLine(int days) {
    return 'A tua semana · $days de 7 cumpridos';
  }

  @override
  String get tapToFlip => 'TOCA PARA VIRAR';

  @override
  String get shareThisCard => 'Partilhar este cartão';

  @override
  String get removeFromSaved => 'Remover dos guardados';

  @override
  String get saveThisPill => 'Guardar esta pílula';

  @override
  String get shareThisPill => 'Partilhar esta pílula';

  @override
  String cardOf(int k, int n) {
    return 'Cartão $k de $n';
  }

  @override
  String hoursMinutes(int h, int m) {
    return '${h}h ${m}m';
  }

  @override
  String tomorrowsFiveOpenIn(String when) {
    return 'Os cinco de amanhã abrem em $when';
  }

  @override
  String topicOpensTomorrow(String topic, String when) {
    return '$topic abre os cinco de amanhã, em $when';
  }

  @override
  String get exploreTodaysBest => 'Explorar o melhor de hoje';

  @override
  String get fiveMore => 'Mais cinco';

  @override
  String get unlockFiveExtra => 'Desbloquear cinco pílulas extra';

  @override
  String nothingInYet(String subject) {
    return 'Ainda nada em $subject.';
  }

  @override
  String get here => 'esta secção';

  @override
  String get todaysShelf => 'A estante de hoje';

  @override
  String get sameForEveryone => 'Igual para todos, e só hoje';

  @override
  String get onesThatAskTheMost => 'Os que mais perguntam';

  @override
  String get acrossEveryone => 'Entre todos, não só na tua mistura';

  @override
  String becauseSitsAtFull(String name) {
    return 'Porque $name está no máximo';
  }

  @override
  String get olderFromTurnedUp => 'Cartões mais antigos dos temas que subiste';

  @override
  String moreOn(String name) {
    return 'Mais sobre $name';
  }

  @override
  String get subjectReadMost => 'O tema de que mais leste';

  @override
  String monthOf(String name) {
    return 'Um mês de $name';
  }

  @override
  String get somewhereToStart => 'Um ponto de partida que não é hoje';

  @override
  String get searchEveryCard => 'Procurar em todos os cartões';

  @override
  String nothingForYet(String query) {
    return 'Ainda nada para \"$query\".';
  }

  @override
  String matching(int n) {
    return '$n encontrados';
  }

  @override
  String get all => 'Todos';

  @override
  String get theArchive => 'O arquivo';

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
    return '$n cartões. Toca num dia para o abrir.';
  }

  @override
  String get whatYouHaveCovered => 'O que já cobriste';

  @override
  String searchNCards(int n) {
    return 'Procurar em $n cartões';
  }

  @override
  String get cancel => 'Cancelar';

  @override
  String nCards(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n cartões',
      one: '1 cartão',
    );
    return '$_temp0';
  }

  @override
  String get yesterday => 'Ontem';

  @override
  String get noPillsMatchFilter =>
      'Nenhuma pílula corresponde ainda a esse filtro.';

  @override
  String nothingForTryTopic(String query) {
    return 'Nada para \"$query\". Tenta um tema.';
  }

  @override
  String get saved => 'Guardados';

  @override
  String get removedFromSaved => 'Removido dos guardados.';

  @override
  String get undo => 'Anular';

  @override
  String get nothingKeptYet => 'Ainda nada guardado';

  @override
  String nInTopic(int n, String topic) {
    return '$n em $topic';
  }

  @override
  String get keepTheOnesYoullUse => 'Guarda os que vais mesmo usar';

  @override
  String get tapTheHeartLandsHere =>
      'Toca no coração de qualquer pílula e ela aterra aqui — as que mudaram a tua forma de pensar, guardadas.';

  @override
  String get backToTodaysFive => 'VOLTAR AOS CINCO DE HOJE';

  @override
  String get archive => 'Arquivo';

  @override
  String get yourWeek => 'A tua semana';

  @override
  String get nothingThisWeekYet =>
      'Ainda nada esta semana. Cinco cartões começam-na.';

  @override
  String keptDaysOfSeven(int days) {
    return 'Cumprida — $days dias em sete.';
  }

  @override
  String daysOfSevenFiveKeeps(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days dias em sete.',
      one: '1 dia em sete.',
    );
    return '$_temp0 Com cinco, a semana conta.';
  }

  @override
  String get howSureAgainstHowRight => 'Quão seguro, contra quão certo';

  @override
  String get sureAndWrong => 'Seguro, e errado';

  @override
  String get worthGoingBackTo =>
      'Os que vale a pena rever. Errar em algo de que tinhas a certeza é a única forma barata de descobrir o que acreditas de verdade.';

  @override
  String get whereThisIsGoing => 'Para onde isto vai';

  @override
  String ofNRight(int n) {
    return 'de $n certos';
  }

  @override
  String get sayHowSureOnMore =>
      'Diz quão seguro estás em mais alguns e a app diz-te quanto vale essa segurança.';

  @override
  String confidenceOff(int gap) {
    return 'A tua segurança ficou a $gap pontos do que realmente sabias.';
  }

  @override
  String confidenceClosing(int gap, int before) {
    return 'A tua segurança desviou-se $gap pontos, contra $before na semana passada. Está a fechar.';
  }

  @override
  String confidenceOpened(int gap, int before) {
    return 'A tua segurança desviou-se $gap pontos, contra $before na semana passada. Abriu.';
  }

  @override
  String nextRung(String name) {
    return 'A seguir: $name';
  }

  @override
  String youSaidPercentSure(int n) {
    return 'Disseste $n% seguro';
  }

  @override
  String rungName(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'day_one': 'Dia um',
      'reading': 'A ler',
      'answering': 'A responder',
      'saying_how_sure': 'A dizer quão seguro',
      'calibrated': 'Calibrado',
      'holding': 'A reter',
      'sharp': 'Afiado',
      'other': '$id',
    });
    return '$_temp0';
  }

  @override
  String rungClaim(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'day_one': 'Toda a gente começa aqui.',
      'reading': 'O hábito começou.',
      'answering': 'Comprometes-te antes de virar o cartão.',
      'saying_how_sure': 'Pões um número no que achas que sabes.',
      'calibrated': 'O que dizes saber, sabes.',
      'holding': 'Fica contigo semanas depois.',
      'sharp': 'Seguro quando deves, e certo quando estás.',
      'other': '$id',
    });
    return '$_temp0';
  }

  @override
  String stepRead(int n) {
    return 'mais $n cartões para ler';
  }

  @override
  String stepAnswer(int n) {
    return 'mais $n cartões para responder';
  }

  @override
  String stepJudge(int n) {
    return 'mais $n respostas com quão seguro estás';
  }

  @override
  String stepHold(int n) {
    return 'mais $n cartões para reter';
  }

  @override
  String stepGap(int gap, int target) {
    return 'a tua segurança desvia-se $gap pontos — $target chega';
  }

  @override
  String stepBeforeJudged(int n) {
    return 'mais $n respostas antes de a app julgar a tua segurança';
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
  String get signOutQuestion => 'Terminar sessão?';

  @override
  String get signOutBody =>
      'A tua sequência, pílulas guardadas e registo ficam na tua conta. Isto apaga-os deste aparelho.';

  @override
  String get signOut => 'Terminar sessão';

  @override
  String get signedInRecordOnAccount =>
      'Sessão iniciada. A tua sequência e registo estão agora na tua conta.';

  @override
  String couldNotSignInWith(String label) {
    return 'Não foi possível entrar com $label.';
  }

  @override
  String get signInNotAvailableBuild =>
      'Iniciar sessão não está disponível nesta versão.';

  @override
  String get startOverQuestion => 'Começar do zero?';

  @override
  String get startOverBody =>
      'Apaga tudo neste aparelho — sequência, pílulas guardadas, respostas, o teu registo de juízos, temas e plano — e reabre a introdução.';

  @override
  String get wipeIt => 'Apagar';

  @override
  String get yourRecord => 'O teu registo';

  @override
  String get appearance => 'Aspeto';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Escuro';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get yourTopics => 'Os teus temas';

  @override
  String get edit => 'Editar';

  @override
  String get howWellYouKnowYourself => 'Quão bem te conheces';

  @override
  String get isTheGapClosing => 'A diferença está a fechar?';

  @override
  String get movesYouKeepMissing => 'As jogadas que continuas a falhar';

  @override
  String get dailyNudge => 'Lembrete diário';

  @override
  String everyDayAt(String time) {
    return 'Todos os dias às $time';
  }

  @override
  String get yourFivePillsBeforeCoffee =>
      'As tuas 5 pílulas, antes do primeiro café.';

  @override
  String get browserOnlySpeaksOpen =>
      'Um navegador só fala enquanto está aberto, por isso isto precisa da versão para telemóvel.';

  @override
  String get nudgeOff => 'Lembrete desligado.';

  @override
  String nudgeOnEveryDayAt(String time) {
    return 'Lembrete ligado, todos os dias às $time.';
  }

  @override
  String get nudgeOnSystemSaidNo =>
      'Lembrete ligado, mas o sistema recusou. Ativa as notificações do Astut nas definições.';

  @override
  String get nudgeOnNeedsPhone =>
      'Lembrete ligado. A entrega precisa da versão para telemóvel.';

  @override
  String get howMuchYouKnow => 'Quanto sabes';

  @override
  String savedN(int n) {
    return 'Guardados · $n';
  }

  @override
  String get manageSubscription => 'Gerir subscrição';

  @override
  String get howPillsAreWritten => 'Como as pílulas são escritas';

  @override
  String get signingIn => 'A entrar…';

  @override
  String get signInWithApple => 'Entrar com a Apple';

  @override
  String get signInWithGoogle => 'Entrar com o Google';

  @override
  String acrossNAnswersHowSure(int n) {
    return 'Em $n respostas disseste quão seguro estavas. Foi assim que correu.';
  }

  @override
  String get perfectlyCalibratedLine =>
      'Uma pessoa perfeitamente calibrada acerta 70% das vezes quando diz 70%.';

  @override
  String get notEnoughAnswersYet => 'Ainda não há respostas suficientes';

  @override
  String get confidenceMatchesAccuracy =>
      'A tua segurança corresponde à tua precisão';

  @override
  String overconfidentBy(int points) {
    return 'Estás seguro a mais em $points pontos';
  }

  @override
  String underconfidentBy(int points) {
    return 'Estás seguro a menos em $points pontos';
  }

  @override
  String saidPercent(int n) {
    return 'Disseste $n%';
  }

  @override
  String rightPercentOf(int pct, int right, int count) {
    return 'certo $pct% ($right de $count)';
  }

  @override
  String moreOfThisToCome(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'mais $n contextos por vir',
      one: 'mais 1 contexto por vir',
    );
    return '$_temp0';
  }

  @override
  String get seeEveryPrincipleWithPlus =>
      'Vê todos os princípios com o Astut plus';

  @override
  String moreBeingTracked(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'mais $n a ser seguidos',
      one: 'mais 1 a ser seguido',
    );
    return '$_temp0';
  }

  @override
  String get shareMyRecord => 'PARTILHAR O MEU REGISTO';

  @override
  String lastCallsAgainstFirst(int n) {
    return 'As tuas últimas $n respostas, contra as primeiras $n';
  }

  @override
  String closedByPoints(int n) {
    return 'Fechou $n pontos';
  }

  @override
  String openedByPoints(int n) {
    return 'Abriu $n pontos';
  }

  @override
  String get holdingSteady => 'Estável';

  @override
  String get measurementRunningPlus =>
      'A medição está a decorrer. O Astut+ mostra-te para onde vai.';

  @override
  String firstN(int n) {
    return 'Primeiras $n';
  }

  @override
  String lastN(int n) {
    return 'Últimas $n';
  }

  @override
  String get trackingMoreClosely =>
      'A tua segurança acompanha a tua precisão mais de perto do que antes.';

  @override
  String get distanceHasGrown =>
      'A distância cresceu. Vale a pena abrandar antes de te comprometeres.';

  @override
  String get noRealMovementYet =>
      'Ainda sem movimento real. Isto leva semanas, não dias.';

  @override
  String get seeWhichWay => 'VER PARA ONDE';

  @override
  String get spotOn => 'certinho';

  @override
  String pointsOver(int n) {
    return '$n a mais';
  }

  @override
  String pointsUnder(int n) {
    return '$n a menos';
  }

  @override
  String get plusNameCaps => 'ASTUT+';

  @override
  String get sevenDaysFree => '7 dias grátis';

  @override
  String get watchTheGapMove => 'Vê a diferença mexer-se.';

  @override
  String get measurementFreeForever =>
      'A medição é grátis e será sempre. O Astut+ é o que te diz para onde vai.';

  @override
  String get seeThePlans => 'VER OS PLANOS';

  @override
  String get recordStartsToday => 'O teu registo começa hoje.';

  @override
  String dayWord(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'dias',
      one: 'dia',
    );
    return '$_temp0';
  }

  @override
  String pillReadWord(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'pílulas lidas',
      one: 'pílula lida',
    );
    return '$_temp0';
  }

  @override
  String nPillsRead(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n pílulas lidas',
      one: '1 pílula lida',
    );
    return '$_temp0';
  }

  @override
  String nWeeksKept(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n semanas cumpridas',
      one: '1 semana cumprida',
    );
    return '$_temp0';
  }

  @override
  String nComingBack(int n) {
    return '$n a voltar';
  }

  @override
  String nFreezesInHand(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n freezes disponíveis',
      one: '1 freeze disponível',
    );
    return '$_temp0';
  }

  @override
  String get freePlan => 'Plano gratuito';

  @override
  String get streakReset => 'Sequência reiniciada';

  @override
  String youMissedDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Falhaste\n$n dias.',
      one: 'Falhaste\num dia.',
    );
    return '$_temp0';
  }

  @override
  String bestStreakStillRecord(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n dias continuam a ser',
      one: 'Um dia continua a ser',
    );
    return '$_temp0 o teu recorde. Lê os cinco de hoje e o contador recomeça do um.';
  }

  @override
  String get whileYouWereAway => 'Enquanto estiveste fora';

  @override
  String pillsWentUnread(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n pílulas ficaram por ler',
      one: '1 pílula ficou por ler',
    );
    return '$_temp0';
  }

  @override
  String stillMostKeptTopic(String topic) {
    return '$topic continua a ser o tema que mais guardas';
  }

  @override
  String cardsDueBackToday(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n cartões que acertaste voltam hoje',
      one: '1 cartão que acertaste volta hoje',
    );
    return '$_temp0';
  }

  @override
  String get startAgainWithTodaysFive => 'Recomeçar com os cinco de hoje';

  @override
  String moveMyReminderTo(String time) {
    return 'Mudar o meu lembrete para as $time';
  }

  @override
  String dailyNudgeMovedTo(String time) {
    return 'Lembrete diário mudado para as $time.';
  }

  @override
  String get whatYouAlready => 'O que já ';

  @override
  String get know => 'sabes';

  @override
  String get knowIntro =>
      'Os temas que mais subiste. Muda o que um dia te pede em cada um — sólido recebe perguntas, curioso recebe explicações — não quanto recebes dele.';

  @override
  String get startWithMyFirstCards => 'Começar com os meus primeiros cartões';

  @override
  String get skipForNow => 'Saltar por agora';

  @override
  String get levelCurious => 'Curioso';

  @override
  String get levelSome => 'Algum';

  @override
  String get levelSolid => 'Sólido';

  @override
  String get save => 'Guardar';

  @override
  String subjectsInTheMix(int n, int total) {
    return '$n de $total temas na mistura';
  }

  @override
  String get yourSpace => 'A tua ';

  @override
  String get mix => 'mistura';

  @override
  String get everythingIsInDrag =>
      'Está tudo dentro. Arrasta um tema para baixo para ver menos, ou até zero para o tirar.';

  @override
  String get next => 'Seguinte';

  @override
  String get whatShouldWeTalkAbout => 'De que falamos?';

  @override
  String get fivePillsADayPick =>
      'Cinco pílulas por dia, escritas de fresco cada manhã. Escolhe os temas que queres na mistura — podes mudá-los depois.';

  @override
  String nSelected(int n) {
    return '$n selecionados';
  }

  @override
  String startWithNTopics(int n) {
    return 'Começar com $n temas';
  }

  @override
  String saveNTopics(int n) {
    return 'Guardar $n temas';
  }

  @override
  String pickAtLeastN(int n) {
    return 'Escolhe pelo menos $n';
  }

  @override
  String get swipeToSeeMore => 'Desliza para ver mais';

  @override
  String get tagline =>
      'Cinco coisas inteligentes por dia, prontas a usar numa conversa';

  @override
  String get introTopicsTitle => 'Doze temas, cinco pílulas';

  @override
  String get introTopicsLine =>
      'Escritas de fresco cada manhã, e verificadas contra uma fonte.';

  @override
  String get introQuestionTitle => 'Uma pergunta, depois a resposta';

  @override
  String get introQuestionLine =>
      'Cada pílula traz a frase que vale a pena dizer em voz alta.';

  @override
  String get introMixTitle => 'Tu escolhes a mistura';

  @override
  String get introMixLine =>
      'Baixa um tema para ver menos, ou desliga-o de vez.';

  @override
  String get introThirtyTitle => 'Trinta segundos por dia';

  @override
  String get introThirtyLine =>
      'Uma notificação, cinco cartões e uma sequência que não vais querer quebrar.';

  @override
  String get continueWithApple => 'Continuar com a Apple';

  @override
  String get continueWithGoogle => 'Continuar com o Google';

  @override
  String get continueWithEmail => 'Continuar com e-mail';

  @override
  String get termsLine =>
      'Ao registares-te aceitas os nossos Termos de Serviço e a Política de Privacidade';

  @override
  String get skip => 'Saltar';

  @override
  String get tapToRevealLower => 'toca para revelar';

  @override
  String get barMoveCaps => 'A FRASE DE BAR';

  @override
  String get theBarMoveCaps => 'A FRASE DE BAR';

  @override
  String get dayStreakCaps => 'DIAS SEGUIDOS';

  @override
  String sourceLabel(String source) {
    return 'Fonte · $source';
  }

  @override
  String get perkRecordTitle => 'O teu registo ao longo do tempo';

  @override
  String get perkRecordLine =>
      'Se a diferença entre quão seguro estavas e quão certo estavas está mesmo a fechar.';

  @override
  String get perkPrinciplesTitle => 'Todos os princípios que encontraste';

  @override
  String get perkPrinciplesLine =>
      'Não só os três em que és pior — todos, e os contextos que ainda não viste.';

  @override
  String get perkFreezesTitle => 'Três freezes de sequência, não um';

  @override
  String get perkFreezesLine =>
      'O suficiente para um fim de semana fora. Uma sequência que só podes perder é uma sequência que acaba por ir.';

  @override
  String get perkExtraTitle => '5 pílulas extra todos os dias';

  @override
  String get perkExtraLine =>
      'Um segundo conjunto desbloqueia-se assim que acabas o primeiro.';

  @override
  String get perkArchiveTitle => 'O arquivo completo';

  @override
  String get perkArchiveLine =>
      'Todas as pílulas que já leste, pesquisáveis por tema.';

  @override
  String get perkTopicsTitle => 'Escolhe os teus temas';

  @override
  String get perkTopicsLine => 'Inclina a mistura para o que gostas mesmo.';

  @override
  String get plusIsActive => 'ASTUT+ ESTÁ ATIVO';

  @override
  String tryFreeThen(String price, String suffix) {
    return 'Experimenta 7 dias grátis, depois $price$suffix';
  }

  @override
  String get trialStartedNoPayment =>
      'Período de teste iniciado. Nesta versão não há pagamento ligado.';

  @override
  String get thatDidNotGoThrough => 'Isso não passou.';

  @override
  String get plusIsBack => 'O Astut+ está de volta.';

  @override
  String get nothingToRestore => 'Nada para restaurar nesta conta.';

  @override
  String get findOutIfBetter => 'Descobre se estás mesmo a melhorar.';

  @override
  String get perYear => 'por ano';

  @override
  String aMonth(String price) {
    return '$price por mês';
  }

  @override
  String savePercent(int n) {
    return 'POUPA $n%';
  }

  @override
  String get perMonth => 'por mês';

  @override
  String get billedMonthly => 'cobrado mensalmente';

  @override
  String get cancelTheTrial => 'Cancelar o teste';

  @override
  String get cancelAnyTime => 'Cancela quando quiseres';

  @override
  String get cancelAnyTimeNoPayment =>
      'Cancela quando quiseres · Nesta versão não é cobrado nada';

  @override
  String get restorePurchases => 'Restaurar compras';

  @override
  String get everythingOpensNothingCharged => 'Abre tudo. Não é cobrado nada.';

  @override
  String dayN(int n) {
    return 'DIA $n';
  }

  @override
  String get reminderTwoDaysBefore =>
      'Um lembrete, dois dias antes de renovar.';

  @override
  String get itRenewsUnlessCancelled =>
      'Renova, a menos que tenhas cancelado. Podes fazê-lo quando quiseres.';

  @override
  String get howTheFreeWeekWorks => 'COMO FUNCIONA A SEMANA GRÁTIS';

  @override
  String planPrice(String label, String price, String per) {
    return '$label, $price $per';
  }

  @override
  String get pickASideNoRightAnswer =>
      'Escolhe um lado. Não há resposta certa.';

  @override
  String get estimateCloseEnough => 'Estima. Chegar perto conta.';

  @override
  String get tapToReveal => 'Toca para revelar';

  @override
  String closeEnoughItIs(String answer) {
    return 'Perto · é $answer';
  }

  @override
  String youSaidItIsCounted(String given, String answer, String band) {
    return 'Disseste $given · é $answer, e $band conta';
  }

  @override
  String get youGotIt => 'Acertaste';

  @override
  String youSaidItIs(String given, String answer) {
    return 'Disseste $given · é $answer';
  }

  @override
  String get almostEveryoneGetsThisWrong => 'Quase toda a gente erra esta';

  @override
  String lineYouSaidSure(String line, int pct) {
    return '$line · disseste $pct% seguro';
  }

  @override
  String get giveMeANudge => 'Dá-me uma pista';

  @override
  String get beingRightMattersLess =>
      'Acertar importa menos do que saber com que frequência acertas.';

  @override
  String get writeItBeforeTheirs => 'Escreve-o antes de leres o deles.';

  @override
  String get youAnsweredThisOne => 'A esta já respondeste.';

  @override
  String difficultyLabel(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'easy': 'Fácil',
      'medium': 'Média',
      'hard': 'Difícil',
      'other': '$id',
    });
    return '$_temp0';
  }

  @override
  String commitBeforeYouTurn(String difficulty) {
    return '$difficulty · compromete-te antes de o virares.';
  }

  @override
  String get yourAnswer => 'A tua resposta';

  @override
  String get checkMyAnswer => 'Verificar a minha resposta';

  @override
  String get howSureAreYou => 'Quão seguro estás?';

  @override
  String percentSure(int n) {
    return '$n por cento seguro';
  }

  @override
  String get inOneLineWhy => 'Numa linha — porquê?';

  @override
  String get because => 'Porque…';

  @override
  String get nowShowMeTheOtherSide => 'Agora mostra-me o outro lado';

  @override
  String get skipShowMeAnyway => 'Saltar — mostra na mesma';

  @override
  String get youTookCaps => 'ESCOLHESTE';

  @override
  String get putSimplyCaps => 'EM POUCAS PALAVRAS';

  @override
  String get explainLikeImThree => 'Explica-me como a uma criança';

  @override
  String get whatTheOtherSideSaysCaps => 'O QUE DIZ O OUTRO LADO';

  @override
  String get whatTheOtherSideSays => 'O que diz o outro lado';

  @override
  String theTrap(String trap) {
    return 'A armadilha: $trap';
  }

  @override
  String youTookTheSide(String side) {
    return 'Escolheste o lado: $side';
  }

  @override
  String atPercentSure(int n) {
    return ' com $n% de certeza';
  }

  @override
  String youGotThisOne(String sure) {
    return 'Acertaste esta$sure';
  }

  @override
  String youSaidAnswer(String answer, String sure) {
    return 'Disseste $answer$sure';
  }

  @override
  String get swipeForTheNextOne => 'Desliza para o próximo';

  @override
  String get thatWasTheOnlyOne => 'Era o único';

  @override
  String indexOfN(int i, int n) {
    return '$i/$n';
  }

  @override
  String get couldNotRenderCard => 'Não foi possível desenhar o cartão.';

  @override
  String get textCopiedInstead => 'Em vez disso, o texto foi copiado.';

  @override
  String get copiedToClipboard => 'Copiado para a área de transferência.';

  @override
  String get rendering => 'A desenhar…';

  @override
  String get theSourceGoesWithIt => 'A fonte vai com ele';

  @override
  String get fiveADayALittleSharper => 'Cinco por dia. Um pouco mais afiado.';

  @override
  String get shareMyDay => 'Partilhar o meu dia';

  @override
  String climbedTo(String rung) {
    return 'Hoje subiste para $rung';
  }

  @override
  String rightOfAsked(int right, int asked) {
    return '$right de $asked certas';
  }

  @override
  String saidSure(int sure) {
    return '$sure% de certeza';
  }

  @override
  String cardsCameBack(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n cartas voltaram — responde outra vez',
      one: '1 carta voltou — responde outra vez',
    );
    return '$_temp0';
  }

  @override
  String get cameBack => 'Voltaram';
}

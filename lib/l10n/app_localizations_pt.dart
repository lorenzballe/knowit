// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appName => 'Astute';

  @override
  String get plusName => 'Astute+';

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
    return 'OS $word DE HOJE';
  }

  @override
  String get tapToFlip => 'TOCA PARA VIRAR';

  @override
  String get shareThisCard => 'Partilhar este cartão';

  @override
  String get removeFromSaved => 'Remover dos guardados';

  @override
  String get saveThisPill => 'Guardar esta carta';

  @override
  String get shareThisPill => 'Partilhar esta carta';

  @override
  String cardOf(int k, int n) {
    return 'Cartão $k de $n';
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
  String magicUnlock(int days) {
    return 'Experimenta $days dias grátis';
  }

  @override
  String get getPlus => 'Passa para Astute+';

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
      'Nenhuma carta corresponde ainda a esse filtro.';

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
      'A tua sequência, cartas guardadas e registo ficam na tua conta. Isto apaga-os deste aparelho.';

  @override
  String get deleteAccount => 'Apagar conta';

  @override
  String get deletingAccount => 'A apagar a tua conta…';

  @override
  String get deleteAccountQuestion => 'Apagar a tua conta?';

  @override
  String get deleteAccountBody =>
      'A tua conta, a cópia de segurança e o quadro que os teus amigos veem são apagados para sempre, e este aparelho recomeça do início. Isto não cancela o Astute+: a subscrição gere-se nas definições da App Store.';

  @override
  String get deleteAccountConfirm => 'Apagar para sempre';

  @override
  String get accountDeleted => 'A tua conta foi apagada.';

  @override
  String get couldNotDeleteAccount =>
      'Não foi possível apagar a conta. Tenta de novo daqui a pouco.';

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
      'Apaga tudo neste aparelho — sequência, cartas guardadas, respostas, o teu registo de juízos, temas e plano — e reabre a introdução.';

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
  String get journeyButtonLine =>
      'O teu nível, as jogadas que continuas a falhar, a tua semana em perguntas';

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
      'As tuas 5 cartas, antes do primeiro café.';

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
      'Lembrete ligado, mas o sistema recusou. Ativa as notificações do Astute nas definições.';

  @override
  String get nudgeOnNeedsPhone =>
      'Lembrete ligado. A entrega precisa da versão para telemóvel.';

  @override
  String savedN(int n) {
    return 'Guardados · $n';
  }

  @override
  String get manageSubscription => 'Gerir subscrição';

  @override
  String get howPillsAreWritten => 'Como as cartas são escritas';

  @override
  String get howTitle => 'Cada carta aqui é escrita por um modelo de IA.';

  @override
  String get howIntro =>
      'Preferimos dizê-lo logo de início a que o descubras sozinho. É assim que uma carta chega até ti.';

  @override
  String get howStep1Title => 'Escrita antes, por um modelo';

  @override
  String get howStep1Line =>
      'Cada carta segue uma só instrução: uma pergunta que vale a pena, uma resposta que diz porquê e uma jogada que podes voltar a usar.';

  @override
  String get howStep2Title => 'Verificada na sua fonte';

  @override
  String get howStep2Line =>
      'Cada carta diz de onde vem, e um segundo modelo lê-a como crítico antes de sair. O que não se sustenta é cortado.';

  @override
  String get howStep3Title => 'Cinco, distribuídas cada manhã';

  @override
  String get howStep3Line =>
      'Dos temas que escolheste, e nunca uma que já tenhas lido.';

  @override
  String get howStep4Title => 'Mantida honesta pelos leitores';

  @override
  String get howStep4Line =>
      'Quando leitores suficientes dizem que uma carta está errada, deixa de ser distribuída até uma pessoa a verificar.';

  @override
  String get howReportTitle => 'Encontraste um erro?';

  @override
  String get howReportLine =>
      'Toca na bandeirinha ao lado da fonte de uma carta para a denunciar.';

  @override
  String get howFoot => 'As fontes são verificadas de novo todos os meses.';

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
      'Vê todos os princípios com o Astute plus';

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
      'A medição está a decorrer. O Astute+ mostra-te para onde vai.';

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
  String get plusNameCaps => 'ASTUTE+';

  @override
  String trialDaysFree(int days) {
    return '$days dias grátis';
  }

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
      other: 'cartas lidas',
      one: 'carta lida',
    );
    return '$_temp0';
  }

  @override
  String nPillsRead(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n cartas lidas',
      one: '1 carta lida',
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
  String get welcomeBack => 'Bem-vindo de volta';

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
      other: '$n cartas ficaram por ler',
      one: '1 carta ficou por ler',
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
  String subjectsInTheMix(int n, int total) {
    return '$n de $total temas na mistura';
  }

  @override
  String get everythingIsInDrag =>
      'Está tudo dentro. Arrasta um tema para baixo para ver menos, ou até zero para o tirar.';

  @override
  String get next => 'Seguinte';

  @override
  String get whatShouldWeTalkAbout => 'De que falamos?';

  @override
  String get fivePillsADayPick =>
      'Cinco cartas por dia, novas cada manhã. Escolhe os temas que queres na mistura — podes mudá-los depois.';

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
      'Percebe o porquê das coisas e até que ponto podes confiar no que sabes';

  @override
  String get introTopicsTitle => 'Dezanove temas, cinco cartas';

  @override
  String get introTopicsLine =>
      'Escritas antes por um modelo, e cada uma cita a sua fonte.';

  @override
  String get introQuestionTitle =>
      'Uma pergunta, a tua certeza, depois o porquê';

  @override
  String get introQuestionLine =>
      'Diz primeiro a tua certeza. Com o tempo, vês quanto vale o teu «tenho a certeza».';

  @override
  String get introMixTitle => 'Tu escolhes a mistura';

  @override
  String get introMixLine =>
      'Baixa um tema para ver menos, ou desliga-o de vez.';

  @override
  String get introThirtyTitle => 'Dois minutos por dia';

  @override
  String get introThirtyLine =>
      'Uma notificação, cinco cartões e uma sequência que não vais querer quebrar.';

  @override
  String introNotifyWhen(String time) {
    return 'Amanhã, $time';
  }

  @override
  String get introNotifyLine => 'As tuas cinco estão prontas. Dia 1.';

  @override
  String get introOneOfFive => '1 DE 5';

  @override
  String get introDayOne => 'DIA 1';

  @override
  String get introTapTomorrow => 'TOCA AMANHÃ PARA DESCOBRIR';

  @override
  String get introDayOneTomorrow => 'DIA 1 · AMANHÃ';

  @override
  String get introDaySevenStreak => 'DIA 7 · PRIMEIRA SEQUÊNCIA';

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
  String get barMoveCaps => 'PARA LEVAR CONTIGO';

  @override
  String get theBarMoveCaps => 'A FRASE DE BAR';

  @override
  String get widgetFootPlain => 'Cinco cartas, dois minutos.';

  @override
  String widgetFootStreak(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n dias seguidos',
      one: '1 dia seguido',
    );
    return '$_temp0';
  }

  @override
  String get widgetFootDone => 'Feito por hoje';

  @override
  String get widgetStreakStart =>
      'Lê as cinco de hoje para começar uma sequência.';

  @override
  String get widgetFiveTitle => 'AS CINCO DE HOJE';

  @override
  String widgetFiveRead(int n) {
    return '$n de 5 lidas';
  }

  @override
  String get widgetFiveDone => 'As cinco, lidas';

  @override
  String get widgetFiveWaiting => 'Esperam-te cinco cartas novas';

  @override
  String get widgetShelfTitle => 'A ESTANTE DE HOJE';

  @override
  String get widgetShelfFrom => 'Da estante de hoje';

  @override
  String get dayStreakCaps => 'DIAS SEGUIDOS';

  @override
  String sourceLabel(String source) {
    return 'Fonte · $source';
  }

  @override
  String get perkArchiveTitle => 'Todo o teu arquivo';

  @override
  String get perkArchiveLine => 'Cada dia que leste, para sempre.';

  @override
  String get plusIsActive => 'ASTUTE+ ESTÁ ATIVO';

  @override
  String tryFreeThen(int days, String price, String suffix) {
    return '$days dias grátis, depois $price$suffix';
  }

  @override
  String subscribeFor(String price, String suffix) {
    return 'Subscrever por $price$suffix';
  }

  @override
  String get noChargeTodayCancel =>
      'Sem cobrança hoje · cancela quando quiseres';

  @override
  String get chargedTodayCancel => 'Cobrado hoje · cancela quando quiseres';

  @override
  String get everyCardForYouMark => 'ti.';

  @override
  String get trialStartedNoPayment =>
      'Período de teste iniciado. Nesta versão não há pagamento ligado.';

  @override
  String get thatDidNotGoThrough => 'Isso não passou.';

  @override
  String get plusIsBack => 'O Astute+ está de volta.';

  @override
  String get nothingToRestore => 'Nada para restaurar nesta conta.';

  @override
  String get planYearly => 'Anual';

  @override
  String get planMonthly => 'Mensal';

  @override
  String get perYearShort => '/ano';

  @override
  String get perMonthShort => '/mês';

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
  String get termsOfUse => 'Termos de uso';

  @override
  String get privacyPolicy => 'Privacidade';

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
  String get shareMyDay => 'Partilhar';

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
      other:
          '$n cartas a que respondeste há dias, de volta para ver se ficaram',
      one: 'Uma carta a que respondeste há dias, de volta para ver se ficou',
    );
    return '$_temp0';
  }

  @override
  String get cameBack => 'Ainda te lembras?';

  @override
  String get holdACardYouLike => 'Gostas? Mantém premida';

  @override
  String likedToday(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n gostadas hoje',
      one: '1 gostada hoje',
    );
    return '$_temp0';
  }

  @override
  String get liked => 'Gostei';

  @override
  String likedN(int n) {
    return 'Gostei · $n';
  }

  @override
  String get nothingLikedYet => 'Ainda nada de que gostaste';

  @override
  String get likeThisPill => 'Gosto desta carta';

  @override
  String get removeFromLiked => 'Tirar dos gostos';

  @override
  String get removedFromLiked => 'Tirada dos gostos.';

  @override
  String get lessLikeThis => 'Menos como esta';

  @override
  String get whatYouLikedLandsHere => 'As que voltarias a ler';

  @override
  String get holdToLikeLandsHere =>
      'Mantém premida uma carta de que gostes e ela aterra aqui — e a app dá-te mais assim.';

  @override
  String get tapTheBookmarkLandsHere =>
      'Toca no marcador de qualquer carta e ela aterra aqui — as que mudaram a tua forma de pensar, guardadas.';

  @override
  String get nudgeTitle => 'As tuas cinco estão prontas';

  @override
  String get nudgeFreezeTitle => 'O teu congelamento está a aguentar';

  @override
  String nudgeFreezeBody(String question) {
    return 'Ontem está coberto. Hoje: $question';
  }

  @override
  String get nudgeSureTitle => 'Desta tinhas a certeza';

  @override
  String nudgeSureBody(String question, int sure) {
    return '$question — disseste $sure%.';
  }

  @override
  String nudgeTwoWeeksTitle(int read) {
    return 'Há duas semanas tinhas lido $read cartas';
  }

  @override
  String nudgeTwoWeeksBody(int gap, String question) {
    return 'A tua confiança estava $gap pontos ao lado. Hoje: $question';
  }

  @override
  String nudgeTwoWeeksBodyNoGap(int answered, String question) {
    return '$answered respondidas até agora. Hoje: $question';
  }

  @override
  String get friends => 'Amigos';

  @override
  String friendsN(int n) {
    return 'Amigos · $n';
  }

  @override
  String get yourFriendCode => 'O teu código de amigo';

  @override
  String get codeCopied => 'Código copiado.';

  @override
  String get addAFriend => 'Adicionar um amigo';

  @override
  String get theirCode => 'O código dele';

  @override
  String get add => 'Adicionar';

  @override
  String get noFriendsYet =>
      'Ainda ninguém. Troca códigos com um amigo e comparem sequências e calibração — nunca respostas.';

  @override
  String get friendsNeedAnAccount =>
      'Comparar precisa da app no telemóvel e de uma conta. Os teus códigos ficam guardados.';

  @override
  String get noReaderWithCode => 'Nenhum leitor com esse código.';

  @override
  String get thatsYourOwnCode => 'Esse é o teu próprio código.';

  @override
  String pointsOff(int n) {
    return '$n pontos ao lado';
  }

  @override
  String get notMeasuredYet => 'ainda não medida';

  @override
  String get thisWeekByCalibration => 'Esta semana, por calibração';

  @override
  String get notYetToday => 'hoje ainda não';

  @override
  String nOfSeven(int n) {
    return '$n de 7';
  }

  @override
  String get you => 'Tu';

  @override
  String get todaysQuestion => 'A pergunta de hoje';

  @override
  String get right => 'certa';

  @override
  String get wrong => 'errada';

  @override
  String rightAtSure(int sure) {
    return 'certa, $sure% de certeza';
  }

  @override
  String wrongAtSure(int sure) {
    return 'errada, $sure% de certeza';
  }

  @override
  String get yourJourney => 'A tua viagem';

  @override
  String get thePath => 'O caminho';

  @override
  String get youAreHere => 'ESTÁS AQUI';

  @override
  String reachedOn(String date) {
    return 'Alcançado a $date';
  }

  @override
  String readSoFar(int n, int of) {
    return '$n de $of lidas até agora';
  }

  @override
  String nRead(int n) {
    return '$n lidas';
  }

  @override
  String get topLevel => 'Nível máximo';

  @override
  String plusNToday(int n) {
    return '+$n hoje';
  }

  @override
  String get bySubject => 'Por matéria';

  @override
  String get pts => 'pontos';

  @override
  String nStillWithYou(int n) {
    return '$n ainda contigo';
  }

  @override
  String nMoves(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n truques',
      one: '1 truque',
    );
    return '$_temp0';
  }

  @override
  String get scoreStartsToday => 'A tua pontuação começa com as cinco de hoje.';

  @override
  String get anonymousUsage => 'Dados de utilização';

  @override
  String get anonymousUsageLine =>
      'Como a app é usada — o que se lê, guarda e diz, e o que falha — para que as próximas cartas sejam melhores. Nunca o teu nome, o teu email ou o que escreves.';

  @override
  String get usageOn => 'Partilhados, sem o teu nome nem as tuas palavras.';

  @override
  String get usageOff => 'Já não se mede nada.';

  @override
  String get yourMix => 'A tua mistura';

  @override
  String get genresLine =>
      'Toca num género para o saltar. Mantém premido e os três fios lá dentro abrem-se logo abaixo.';

  @override
  String get insideGenre => 'Dentro';

  @override
  String nOfSixOn(int n, int total) {
    return '$n de $total ativos';
  }

  @override
  String get offInYourMix => 'fora da tua mistura';

  @override
  String continueGenresOn(int on, int total) {
    return 'Continuar · $on de $total géneros ativos';
  }

  @override
  String get mixRarely => 'Raramente';

  @override
  String get mixSometimes => 'Às vezes';

  @override
  String get mixOften => 'Muitas vezes';

  @override
  String get mixALot => 'Muito';

  @override
  String get mixFull => 'No máximo';

  @override
  String get forYouChip => 'PARA TI';

  @override
  String get againChip => 'DE NOVO';

  @override
  String get magicLine =>
      'Cinco cartas por dia escolhidas para ti: da tua mistura, ao teu nível, nunca uma já lida. A partir de amanhã.';

  @override
  String get everyCardForYou => 'Cada carta, escolhida para ti.';

  @override
  String get perkOwnTitle => 'Cinco cartas por dia, todas tuas';

  @override
  String get perkOwnLine =>
      'Dos teus fios, ao teu nível, nunca uma já lida. Grátis tens duas por dia.';

  @override
  String get plusCardHeadline => 'As cinco, tuas.';

  @override
  String get plusCardLine =>
      'Cinco cartas por dia da tua mistura, ao teu nível. A tua viagem. Todo o teu arquivo.';

  @override
  String get continueFree => 'Continuar grátis';

  @override
  String get archiveBeforeThisWeek => 'Antes desta semana';

  @override
  String get weekKeptThreeOwn =>
      'Uma semana seguida: amanhã três das cinco são tuas.';

  @override
  String get perkJourneyLine =>
      'O teu nível, cada tema fio a fio, o que ficou, e as jogadas que continuas a falhar.';

  @override
  String get topOfTheWeek => 'Top da semana';

  @override
  String get topOfTheMonth => 'Top do mês';

  @override
  String topIn(String subject) {
    return 'Top em $subject';
  }

  @override
  String get topLineWeek =>
      'As mais gostadas, guardadas e contadas nos últimos 7 dias';

  @override
  String get topLineMonth =>
      'As mais gostadas, guardadas e contadas nos últimos 30 dias';

  @override
  String get topWeek => 'Semana';

  @override
  String get topMonth => 'Mês';

  @override
  String topReaders(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n leitores',
      one: '1 leitor',
    );
    return '$_temp0';
  }

  @override
  String get topEmpty =>
      'Ainda nada na lista. Cada carta de que gostas, que guardas ou que contas entra na conta.';

  @override
  String get readMark => 'Lida';

  @override
  String get lovedSinceTheStart => 'As mais amadas desde o início';

  @override
  String lovedIn(String subject) {
    return 'As mais amadas em $subject';
  }

  @override
  String get lovedLine =>
      'O que os leitores mais guardaram e tu ainda não leste';

  @override
  String get forYouShelf => 'Para ti';

  @override
  String get forYouLine => 'O que a tua leitura põe em primeiro';

  @override
  String get exploreOffline =>
      'Estás sem ligação. Este é o Explorar tal como foi lido da última vez.';

  @override
  String get askYourselfCaps => 'PERGUNTA-TE';

  @override
  String get themeMyths => 'Mitos desfeitos';

  @override
  String get themeMythsLine =>
      'O que quase todos acreditam, e porque está errado';

  @override
  String get themeParadoxes => 'Paradoxos';

  @override
  String get themeParadoxesLine =>
      'Duas coisas verdadeiras que não deviam sê-lo juntas';

  @override
  String get themeNumbers => 'Números que surpreendem';

  @override
  String get themeNumbersLine => 'Onde o número é a reviravolta';

  @override
  String get themePractical => 'Para usar hoje';

  @override
  String get themePracticalLine =>
      'Algo para experimentar, ou para lançar numa conversa, antes da noite';

  @override
  String get themeOrigins => 'De onde vem';

  @override
  String get themeOriginsLine => 'A origem de coisas que usas todos os dias';

  @override
  String get themeStories => 'Histórias verdadeiras';

  @override
  String get themeStoriesLine => 'Coisas que aconteceram mesmo';

  @override
  String get themeDebates => 'Escolhe um lado';

  @override
  String get themeDebatesLine =>
      'Não há resposta certa, só um argumento melhor';

  @override
  String get themeWorkItOut => 'Faz as contas';

  @override
  String get themeWorkItOutLine =>
      'Adivinha o número antes de a carta to dizer';

  @override
  String get themeSeen => 'Para ver';

  @override
  String get themeSeenLine => 'Cartas que desenham a sua ideia';

  @override
  String get themeSharpest => 'Para os mais afiados';

  @override
  String get themeSharpestLine => 'As cartas mais difíceis que há';

  @override
  String get themePast0 => 'O mundo antigo';

  @override
  String get themePast1 => 'Dos séculos XVII ao XIX';

  @override
  String get themePast2 => 'O século passado';

  @override
  String get themePastLine => 'Uma época diferente de cada vez';

  @override
  String get themePlace0 => 'Ásia e Médio Oriente';

  @override
  String get themePlace1 => 'As Américas';

  @override
  String get themePlace2 => 'Europa';

  @override
  String get themePlaceLine => 'Uma parte do mundo diferente de cada vez';

  @override
  String get themeTrueOrFalse => 'Verdadeiro ou falso?';

  @override
  String get themeTrueOrFalseLine => 'Decide antes de virar. Quase todos erram';

  @override
  String get themeReasoning => 'Só raciocínio';

  @override
  String get themeReasoningLine =>
      'Nada para decorar: só uma forma de pensar nisso';

  @override
  String get themeIdeas => 'Grandes ideias';

  @override
  String get themeIdeasLine =>
      'A teoria por trás das coisas, uma ideia de cada vez';

  @override
  String get themeCurious => 'Só curiosidade';

  @override
  String get themeCuriousLine => 'Pelo gosto de saber porquê';

  @override
  String get themeMoving => 'Em movimento';

  @override
  String get themeMovingLine => 'O que está a mudar agora, e porque importa';

  @override
  String get themeHowItWorks => 'Como funciona mesmo';

  @override
  String get themeHowItWorksLine =>
      'O mecanismo por trás de algo que vês todos os dias';

  @override
  String get themePuzzles => 'Enigmas';

  @override
  String get themePuzzlesLine => 'Quebra-cabeças para uma caneta e um minuto';

  @override
  String get weekRecapCaps => 'ESTA SEMANA PERGUNTASTE-TE';

  @override
  String get weekRecapLine => 'As perguntas que as tuas cartas te deixaram';

  @override
  String weekRecapMore(int n) {
    return 'Mais $n da tua semana com Plus';
  }

  @override
  String get plusInTheApp =>
      'O Astute+ está na app: descarrega o Astute no iPhone ou Android para começar o teste gratuito.';

  @override
  String get purchaseComplete => 'Compra concluída.';

  @override
  String get successWelcome =>
      'Boas-vindas ao Astute+. As cinco cartas de hoje estão prontas.';

  @override
  String successWelcomeNamed(String name) {
    return 'Boas-vindas ao Astute+, $name. As cinco cartas de hoje estão prontas.';
  }

  @override
  String get successFiveCards => '5 cartas por dia';

  @override
  String get successArchive => 'Arquivo completo';

  @override
  String successPlanName(String plan) {
    return 'Astute+ $plan';
  }

  @override
  String successFreeUntil(String date, String price, String suffix) {
    return 'Grátis até $date, depois $price$suffix';
  }

  @override
  String successRenewsLine(String date, String price, String suffix) {
    return 'Renova em $date · $price$suffix';
  }

  @override
  String get successReceipt => 'Recibo';

  @override
  String get letsStart => 'Vamos começar';

  @override
  String successFootFirstCharge(String date) {
    return 'Primeira cobrança em $date · cancele quando quiser';
  }

  @override
  String successFootRenews(String date) {
    return 'Renova em $date · cancele quando quiser';
  }

  @override
  String get tryToday => 'EXPERIMENTA HOJE';

  @override
  String minutesShort(int n) {
    return '$n MIN';
  }

  @override
  String get sideOr => 'ou';

  @override
  String get nextStep => 'Passo seguinte';

  @override
  String get showAllSteps => 'Ver tudo';

  @override
  String get revealSeePicture => 'Ver o desenho';

  @override
  String get revealPlayScene => 'Experimente você';

  @override
  String get revealBackToAnswer => 'Voltar à resposta';

  @override
  String get revealShowWorking => 'Ver o raciocínio';

  @override
  String get sceneLockIn => 'CONFIRMAR';

  @override
  String get sceneYou => 'VOCÊ';

  @override
  String get sceneTruth => 'REAL';

  @override
  String get sceneTryAgain => 'De novo';

  @override
  String get sceneDrawHint => 'Desenhe seu palpite com o dedo';

  @override
  String get sceneHoldHint => 'Pressione e segure';

  @override
  String get sceneSwipeHint => 'Deslize ou toque';

  @override
  String get sceneTapToPick => 'Toque na sua escolha';

  @override
  String get sceneShowMe => 'Mostre';

  @override
  String get sceneYourGuess => 'Seu palpite';

  @override
  String sceneNOfM(int n, int m) {
    return '$n de $m';
  }

  @override
  String get reportProblem => 'Reportar um problema';

  @override
  String get reportedThanks => 'Reportado. Obrigado.';

  @override
  String get reportTitle => 'O que está errado neste cartão?';

  @override
  String get reportLead =>
      'Verificamos cada aviso nas fontes e corrigimos o cartão.';

  @override
  String get reportFact => 'Um facto está errado';

  @override
  String get reportAnswer => 'A resposta dada como certa está errada';

  @override
  String get reportSource => 'A fonte não o confirma';

  @override
  String get reportUnclear => 'É confuso';

  @override
  String get reportTypo => 'Uma gralha ou uma linha partida';

  @override
  String get reportOther => 'Outra coisa';

  @override
  String get reportNoteHint => 'Algo que nos ajude a verificar (opcional)';

  @override
  String get reportSend => 'Enviar';

  @override
  String get reportSentToast => 'Obrigado. Vamos verificar.';

  @override
  String get journeyPointsOff => 'pontos ao lado';

  @override
  String journeyOffNotYet(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Mais $n respostas com a tua certeza, e fica medido.',
      one: 'Mais uma resposta com a tua certeza, e fica medido.',
    );
    return '$_temp0';
  }

  @override
  String get journeyYourScore => 'A tua pontuação';

  @override
  String journeyPointsUnit(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'pontos',
      one: 'ponto',
      zero: 'pontos',
    );
    return '$_temp0';
  }

  @override
  String journeyGainedIn(String n) {
    return '+$n em 4 semanas';
  }

  @override
  String journeyWeekSoFar(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Esta semana, até agora, ganhaste $n pontos.',
      one: 'Esta semana, até agora, ganhaste $n ponto.',
      zero: 'Esta semana, até agora, ganhaste $n pontos.',
    );
    return '$_temp0';
  }

  @override
  String journeyWeekOf(int n, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Na semana de $date, ganhaste $n pontos.',
      one: 'Na semana de $date, ganhaste $n ponto.',
      zero: 'Na semana de $date, ganhaste $n pontos.',
    );
    return '$_temp0';
  }

  @override
  String journeyCards(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n cartões',
      one: '$n cartão',
      zero: '$n cartões',
    );
    return '$_temp0';
  }

  @override
  String journeyScoreCaption(String date) {
    return 'A tua pontuação no fim de cada semana desde $date. Toca num ponto para veres essa semana.';
  }

  @override
  String journeyLevelOf(int n, int of) {
    return 'Nível $n de $of';
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
      other: '$n cartões',
      one: '1 cartão',
    );
    return '$_temp0';
  }

  @override
  String journeyToGoAnswers(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n respostas',
      one: '1 resposta',
    );
    return '$_temp0';
  }

  @override
  String journeyToGoSure(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n respostas com a tua certeza',
      one: '1 resposta com a tua certeza',
    );
    return '$_temp0';
  }

  @override
  String journeyToGoHeld(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n cartões retidos',
      one: '1 cartão retido',
    );
    return '$_temp0';
  }

  @override
  String journeyToGoPoints(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n pontos',
      one: '1 ponto',
    );
    return '$_temp0';
  }

  @override
  String get journeyWorth => 'Quanto vale';

  @override
  String journeyBooks(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n livros',
      one: '1 livro',
    );
    return '$_temp0';
  }

  @override
  String journeyOrDocumentaries(int h) {
    return 'ou $h h de documentários';
  }

  @override
  String journeyToFirstBook(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'faltam $n para o primeiro livro',
      one: 'falta 1 para o primeiro livro',
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
      other: '$n dias',
      one: '$n dia',
      zero: '$n dias',
    );
    return '$_temp0';
  }

  @override
  String journeyBestActive(int best, int active, int days) {
    return 'Recorde $best · $active de $days';
  }

  @override
  String journeySubjectsOf(int n, int of) {
    return '$n de $of';
  }

  @override
  String journeySubjectsDashed(String month) {
    return 'temas · tracejado: $month';
  }

  @override
  String get journeySubjects => 'temas';

  @override
  String get journeyHowHard => 'Dificuldade';

  @override
  String get journeyOfThree => 'de 3';

  @override
  String get journeyHardNow => 'Os cartões que abres.';

  @override
  String journeyHardThen(String v, String month) {
    return 'Os cartões que abres. $v em $month';
  }

  @override
  String get journeyReadingTime => 'Tempo de leitura';

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
    return '$now min por semana, antes $was';
  }

  @override
  String journeyMinThisWeek(int m) {
    return '$m min esta semana';
  }

  @override
  String get journeyTimedFromToday => 'Contado a partir de hoje';

  @override
  String journeyPointsOffFrom(int was) {
    return 'pontos ao lado, antes $was';
  }

  @override
  String journeyRungOrLess(String rung, int n) {
    return '$rung · máx. $n';
  }

  @override
  String get journeyRightWhenSure => 'Certo quando seguro';

  @override
  String journeyFromIn(String v, String month) {
    return 'Era $v em $month';
  }

  @override
  String get journeySureNone => 'Ainda não disseste 80% ou mais';

  @override
  String get journeyMovesTitle => 'Truques que apanhas';

  @override
  String journeyOfN(int n) {
    return 'de $n';
  }

  @override
  String journeyNewest(String name) {
    return 'Último: $name';
  }

  @override
  String get journeyNoneYet => 'Ainda nada';

  @override
  String journeyStillWithYou(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'cartões ainda contigo',
      one: 'cartão ainda contigo',
      zero: 'cartões ainda contigo',
    );
    return '$_temp0';
  }

  @override
  String journeyRecallDays(int right, int of, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days dias',
      one: 'um dia',
    );
    return '$right de $of após $_temp0';
  }

  @override
  String journeyRecallWeeks(int right, int of, int weeks) {
    String _temp0 = intl.Intl.pluralLogic(
      weeks,
      locale: localeName,
      other: '$weeks semanas',
      one: 'uma semana',
    );
    return '$right de $of após $_temp0';
  }

  @override
  String journeyActiveDays(int active, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days dias',
      one: '1 dia',
    );
    return '$active de $_temp0';
  }

  @override
  String get journeyMostlyMorning => 'Sobretudo de manhã';

  @override
  String get journeyMostlyAfternoon => 'Sobretudo à tarde';

  @override
  String get journeyMostlyEvening => 'Sobretudo à noite';

  @override
  String get journeyMostlyNight => 'Sobretudo de madrugada';

  @override
  String get journeyInTime => 'No tempo';

  @override
  String journeyYears(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '$nString anos';
  }

  @override
  String journeyFromEra(String era) {
    return 'desde $era até hoje';
  }

  @override
  String get journeyEraAncient => 'a Antiguidade';

  @override
  String get journeyEraMedieval => 'a Idade Média';

  @override
  String get journeyEraEarlyModern => 'o século XVI';

  @override
  String get journeyEraNineteenth => 'o século XIX';

  @override
  String get journeyEraTwentieth => 'o século XX';

  @override
  String get journeyEraRecent => '2000';

  @override
  String get journeyNothingDated => 'ainda nada datado';

  @override
  String get journeyInPlace => 'No mundo';

  @override
  String journeyRegions(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n regiões',
      one: '1 região',
    );
    return '$_temp0';
  }

  @override
  String journeyPlacesAndSpace(String list) {
    return '$list e o espaço';
  }

  @override
  String get journeyRegionAmericas => 'Américas';

  @override
  String get journeyRegionEurope => 'Europa';

  @override
  String get journeyRegionAsia => 'Ásia';

  @override
  String get journeyRegionOceania => 'Oceânia';

  @override
  String get journeyRegionAfrica => 'África';

  @override
  String get journeyRegionMiddleEast => 'Médio Oriente';

  @override
  String get journeyNoPlace => 'ainda nenhum lugar';

  @override
  String get journeyTopics => 'Subtemas';

  @override
  String journeyMet(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n descobertos',
      one: '1 descoberto',
    );
    return '$_temp0';
  }

  @override
  String journeyTopicsMost(int n, String subject) {
    return '$n deles em $subject';
  }

  @override
  String get journeyWords => 'Palavras';

  @override
  String journeyNew(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n novas',
      one: '1 nova',
    );
    return '$_temp0';
  }

  @override
  String get anotherOne => 'Outra';

  @override
  String answerIs(String said) {
    return 'Resposta: $said';
  }

  @override
  String get answeredAlready => 'Já respondida';

  @override
  String get anyCard => 'Qualquer tema, qualquer estante, uma carta';

  @override
  String betN(int n) {
    return 'Apostar $n';
  }

  @override
  String get betWord => 'Apostar';

  @override
  String get biggerLabel => 'Maior';

  @override
  String get biggerYouGotIt => 'Maior · acertaste';

  @override
  String cameBackAfterDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Passados $n dias',
      one: 'Passado um dia',
    );
    return '$_temp0';
  }

  @override
  String get cameBackAfterWeek => 'Passada uma semana';

  @override
  String cameBackAfterWeeks(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Passadas $n semanas',
      one: 'Passada uma semana',
    );
    return '$_temp0';
  }

  @override
  String get check => 'Verificar';

  @override
  String closerDone(String said, int right, int steps) {
    return 'É $said. Acertaste $right de $steps.';
  }

  @override
  String closerNoLess(String v) {
    return 'Não: é menos de $v.';
  }

  @override
  String closerNoMore(String v) {
    return 'Não: é mais de $v.';
  }

  @override
  String get closerStart => 'Três passos para lá chegar.';

  @override
  String closerYesLess(String v) {
    return 'Certo: é menos de $v.';
  }

  @override
  String closerYesMore(String v) {
    return 'Certo: é mais de $v.';
  }

  @override
  String get corrections => 'Correções';

  @override
  String get didYouKnow => 'Sabias?';

  @override
  String get didYouKnowLine => 'Vira-a e depois: novo para ti, ou já sabias?';

  @override
  String get dragToSet => 'Arrasta para escolher';

  @override
  String get dykAgain => 'Outra vez';

  @override
  String dykKnew(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Sabias $n',
      one: 'Sabias 1',
      zero: 'Não sabias nenhuma',
    );
    return '$_temp0';
  }

  @override
  String dykNew(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n novas para ti',
      one: '1 nova para ti',
      zero: 'Nada de novo hoje',
    );
    return '$_temp0';
  }

  @override
  String get editionEnd => 'Esta é a edição de hoje';

  @override
  String get editionTomorrow => 'A de amanhã sai de manhã';

  @override
  String get eraAncient => 'O mundo antigo';

  @override
  String get eraAncientWhen => 'Antes de 500';

  @override
  String get eraEarlyModern => 'A Idade Moderna';

  @override
  String get eraEarlyModernWhen => 'De 1500 a 1800';

  @override
  String get eraMedieval => 'A Idade Média';

  @override
  String get eraMedievalWhen => 'De 500 a 1500';

  @override
  String eraMore(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Mais $n desta época',
      one: 'Mais 1 desta época',
    );
    return '$_temp0';
  }

  @override
  String get eraNineteenth => 'O século XIX';

  @override
  String get eraNineteenthWhen => 'De 1800 a 1900';

  @override
  String get eraRecent => 'Este século';

  @override
  String get eraRecentWhen => 'Desde 2000';

  @override
  String get eraRulerNow => 'Agora';

  @override
  String get eraRulerOld => 'Antiguidade';

  @override
  String get eraShortAncient => 'Antiguidade';

  @override
  String get eraShortEarlyModern => '1500–1800';

  @override
  String get eraShortMedieval => 'Idade Média';

  @override
  String get eraShortNineteenth => 'Século XIX';

  @override
  String get eraShortRecent => 'Século XXI';

  @override
  String get eraShortTwentieth => 'Século XX';

  @override
  String get eraTwentieth => 'O século passado';

  @override
  String get eraTwentiethWhen => 'De 1900 a 2000';

  @override
  String get fewCards => 'Em poucas cartas';

  @override
  String get fewCardsLine => 'Quando uma carta não chega para o explicar';

  @override
  String get firstLabel => 'Desde';

  @override
  String get forYouNow => 'Para ti, agora';

  @override
  String get hardBadge => 'Difícil';

  @override
  String hidesIn(String where) {
    return 'Em $where';
  }

  @override
  String get howSure => 'Até que ponto tenho a certeza, e porquê?';

  @override
  String get inNumbers => 'Em números';

  @override
  String inRange(int pts, String said) {
    return 'Dentro: +$pts pontos. É $said.';
  }

  @override
  String inYourMoves(int n) {
    return 'Nas tuas jogadas · $n×';
  }

  @override
  String itIs(String said) {
    return 'É $said.';
  }

  @override
  String get knewIt => 'Já sabia';

  @override
  String get less => 'Menos';

  @override
  String get lookFirst => 'Olha para o gráfico antes de acreditares no título.';

  @override
  String minutesLabel(int n) {
    return '$n min';
  }

  @override
  String missedRange(String said) {
    return 'Falhaste: é $said.';
  }

  @override
  String get modeBigger => 'Qual é maior?';

  @override
  String get modeCloser => 'Cada vez mais perto';

  @override
  String get modePick => 'Escolhe uma';

  @override
  String get modeRange => 'Aposta num intervalo';

  @override
  String get modeSlide => 'Desliza';

  @override
  String get modeStake => 'Faz a tua aposta';

  @override
  String get monthShelfLine => 'Um tema novo todos os meses, igual para todos';

  @override
  String moodMeta(int cards, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      cards,
      locale: localeName,
      other: '$cards cartas',
      one: '1 carta',
    );
    return '$_temp0 · $minutes min';
  }

  @override
  String get moodTime => 'O tempo que tens';

  @override
  String get moodTitle => 'O teu humor, os teus minutos';

  @override
  String get moodTone => 'Tom';

  @override
  String get more => 'Mais';

  @override
  String moreOrLess(String v) {
    return 'Mais ou menos de $v?';
  }

  @override
  String get moveComparedToWhat => 'Comparado com quê?';

  @override
  String get moveComparedToWhatLine =>
      'Uma mudança não significa nada sem algo com que a comparar';

  @override
  String get askingTitle => 'Uma pergunta de cada tema';

  @override
  String askingIn(String subject) {
    return 'Perguntas de $subject';
  }

  @override
  String get askingLine =>
      'Iguais para todos. Primeiro responde, depois vê porquê';

  @override
  String get moveSampling => 'Quem foi contado?';

  @override
  String get moveSamplingLine =>
      'Quem acaba num estudo decide o que ele te pode dizer';

  @override
  String mythDeckHint(int at, int of) {
    return '$at de $of · desliza para virar';
  }

  @override
  String nOfM(int at, int of) {
    return '$at de $of';
  }

  @override
  String get newMove => 'Nova para ti';

  @override
  String get newToMe => 'Novo para mim';

  @override
  String get notEnoughPoints => 'Pontos insuficientes';

  @override
  String get notSureLine => 'Uma carta de qualquer parte da Astute';

  @override
  String get notSureTitle => 'Não sabes por onde começar?';

  @override
  String get openWord => 'Abrir';

  @override
  String get pickOneFirst => 'Escolhe uma primeiro';

  @override
  String get puzzleOfTheDay => 'O enigma do dia';

  @override
  String rangeWidth(int w, int pts) {
    return '±$w · $pts pts';
  }

  @override
  String get rightLastTime => 'Certa da última vez';

  @override
  String get sameForEveryoneCaps => 'Igual para todos';

  @override
  String get sayFalse => 'Falso';

  @override
  String get sayTrue => 'Verdadeiro';

  @override
  String get seriesAnchors => 'Primeiras impressões';

  @override
  String get seriesGrowth => 'Números que fogem ao controlo';

  @override
  String seriesMeta(int n, int m) {
    return '$n cartas · cerca de $m min';
  }

  @override
  String get seriesOdds => 'Probabilidades que enganam';

  @override
  String get seriesRetold => 'A história, recontada';

  @override
  String seriesStrand(String name) {
    return '$name, em poucas cartas';
  }

  @override
  String get seriesStudies => 'Porque é que os estudos enganam';

  @override
  String showAllN(int n) {
    return 'Mostrar as $n';
  }

  @override
  String get showFewer => 'Mostrar menos';

  @override
  String get sixtyAgain => 'Jogar outra vez';

  @override
  String sixtyIn(int s) {
    return 'em $s segundos';
  }

  @override
  String get sixtyLine => 'Oito verdadeiro ou falso. Segue o instinto';

  @override
  String get sixtyPerfect => 'As oito certas.';

  @override
  String sixtyScore(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n certas até agora',
      one: '1 certa até agora',
      zero: 'Nenhuma certa ainda',
    );
    return '$_temp0';
  }

  @override
  String get sixtySecondsFor => 'segundos para oito\nverdadeiro ou falso';

  @override
  String sixtySecondsLeft(int s) {
    return '$s s';
  }

  @override
  String get sixtyStart => 'Começar';

  @override
  String get sixtyTimeUp => 'antes de o tempo acabar';

  @override
  String get sixtyTitle => 'Sessenta segundos';

  @override
  String slideOff(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Falhaste por $n pontos.',
      one: 'Falhaste por 1 ponto.',
      zero: 'Certeiro.',
    );
    return '$_temp0';
  }

  @override
  String get stakeLabel => 'Aposta';

  @override
  String stepOf(int at, int of) {
    return 'Passo $at de $of';
  }

  @override
  String get surpriseMe => 'Surpreende-me';

  @override
  String get tapIfBigger => 'Toca se for maior';

  @override
  String get tapToTurn => 'Toca para virar';

  @override
  String get tfRight => 'Certo. Abre-a para saberes porquê.';

  @override
  String tfWrong(String side) {
    return 'É $side. Abre-a para saberes porquê.';
  }

  @override
  String theAnswer(String said) {
    return 'A resposta: $said.';
  }

  @override
  String get theAstute => 'The Astute';

  @override
  String get theLead => 'Manchete';

  @override
  String get throughTime => 'Através do tempo';

  @override
  String get throughTimeLine =>
      'Do mundo antigo a este ano. Arrasta, ou escreve um ano';

  @override
  String leanHint(String or) {
    return 'Desliza o «$or» até onde estás';
  }

  @override
  String leanHow(String level) {
    String _temp0 = intl.Intl.selectLogic(level, {
      '1': 'um pouco',
      '2': 'no geral',
      '3': 'com firmeza',
      'other': 'totalmente',
    });
    return '$_temp0';
  }

  @override
  String leanSays(String side, String how) {
    return '$side, $how';
  }

  @override
  String leanTook(String side) {
    return 'Escolheste $side';
  }

  @override
  String leanVerdict(String says) {
    return '$says. Abre-a para veres o outro lado.';
  }

  @override
  String get spotTitle => 'Descobre a falsa';

  @override
  String get spotLine => 'Três são verdadeiras. Uma não.';

  @override
  String get spotPrompt => 'Toca na que achas que é falsa';

  @override
  String get spotConfirm => 'É esta a falsa';

  @override
  String get spotFound => 'Encontraste-a. As outras três são verdadeiras.';

  @override
  String get spotMissed => 'Essa não: é verdadeira. A falsa está riscada.';

  @override
  String get spotWhy => 'Toca em qualquer uma para leres porquê';

  @override
  String get spotYours => 'A tua escolha';

  @override
  String get yearHint => 'Escreve um ano';

  @override
  String get yearAd => 'd.C.';

  @override
  String get yearBc => 'a.C.';

  @override
  String yearNamed(String year) {
    return '$year';
  }

  @override
  String yearAdOf(String year) {
    return '$year d.C.';
  }

  @override
  String yearBcOf(String year) {
    return '$year a.C.';
  }

  @override
  String get yearGo => 'Ir para este ano';

  @override
  String yearNearest(String year) {
    return 'Primeiro o mais perto de $year';
  }

  @override
  String yearNoneNamed(String year) {
    return 'Nenhuma carta aqui fala de um ano perto de $year. Estas são da sua época.';
  }

  @override
  String yearNoAge(String year) {
    return 'Hoje não há nada de perto de $year. Esta é a época mais próxima.';
  }

  @override
  String yearFuture(String year) {
    return '$year ainda está para vir. Aqui está este século.';
  }

  @override
  String get yearZero => 'Não houve ano 0. Experimenta 1 a.C. ou 1 d.C.';

  @override
  String get todayLabel => 'Hoje';

  @override
  String get todaysEdition => 'Edição de hoje';

  @override
  String get toneCurious => 'Curioso';

  @override
  String get toneLight => 'Leve';

  @override
  String get toneSerious => 'Sério';

  @override
  String get toneTough => 'Puxado';

  @override
  String get unmaskBack => 'Mostrar como foi publicado';

  @override
  String get unmaskFlipped => 'Virar para o lado certo';

  @override
  String get unmaskLine => 'Mesmos números, outra imagem';

  @override
  String get unmaskStretched => 'Usar uma escala justa';

  @override
  String get unmaskTitle => 'Desmascara o gráfico';

  @override
  String get unmaskTotals => 'Tornar a comparação justa';

  @override
  String get unmaskTruncated => 'Começar o eixo no zero';

  @override
  String get unmaskWindow => 'Mostrar a série toda';

  @override
  String get whatIfTrue => 'E se for verdade?';

  @override
  String get whatIfTrueLine =>
      'Cartas que continuam a trabalhar depois de as fechares';

  @override
  String get whatYouBelieve => 'Aquilo em que acreditas';

  @override
  String get wrongLastTime => 'Errada da última vez';

  @override
  String youLose(int n) {
    return 'Perdes $n.';
  }

  @override
  String youWin(int n) {
    return 'Ganhas $n.';
  }

  @override
  String get yourPick => 'A tua escolha';
}

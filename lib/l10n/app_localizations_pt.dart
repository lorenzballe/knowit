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
      zero: '$n dias',
    );
    return '$_temp0';
  }

  @override
  String get freezeKeptStreak => 'Uma proteção salvou a sequência';

  @override
  String countWord(String n) {
    String _temp0 = intl.Intl.selectLogic(n, {
      '1': 'uma',
      '2': 'duas',
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
  String dayTitle(int n) {
    return 'Dia $n';
  }

  @override
  String shelfEyebrow(String word) {
    return 'OS $word DE HOJE';
  }

  @override
  String get tapToFlip => 'TOCA PARA VIRAR';

  @override
  String get shareThisCard => 'Partilhar esta carta';

  @override
  String get removeFromSaved => 'Remover dos guardados';

  @override
  String get saveThisPill => 'Guardar esta carta';

  @override
  String get shareThisPill => 'Partilhar esta carta';

  @override
  String get share => 'Partilhar';

  @override
  String cardOf(int k, int n) {
    return 'Carta $k de $n';
  }

  @override
  String tomorrowsFiveOpenIn(String when) {
    return 'As cinco de amanhã · em $when';
  }

  @override
  String topicOpensTomorrow(String topic, String when) {
    return 'Amanhã: $topic · em $when';
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
  String get olderFromTurnedUp => 'Cartas mais antigas dos temas que subiste';

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
  String get searchEveryCard => 'Procurar em todas as cartas';

  @override
  String nothingForYet(String query) {
    return 'Ainda nada para «$query».';
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
      zero: '$n resultados',
    );
    return '$_temp0';
  }

  @override
  String cardsTapADay(int n) {
    return '$n cartas. Toca num dia para o abrir.';
  }

  @override
  String get whatYouHaveCovered => 'O que já cobriste';

  @override
  String searchNCards(int n) {
    return 'Procurar em $n cartas';
  }

  @override
  String get cancel => 'Cancelar';

  @override
  String nCards(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n cartas',
      one: '1 carta',
      zero: '$n cartas',
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
    return 'Nada para «$query». Tenta um tema.';
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
  String get backToTodaysFive => 'Voltar aos cinco de hoje';

  @override
  String get archive => 'Arquivo';

  @override
  String get yourWeek => 'A tua semana';

  @override
  String get nothingThisWeekYet =>
      'Ainda nada esta semana. Cinco cartas começam-na.';

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
      zero: '$days dias em sete.',
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
    return 'Estavas $n% seguro';
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
      'answering': 'Comprometes-te antes de virar a carta.',
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
    return 'mais $n cartas para ler';
  }

  @override
  String stepAnswer(int n) {
    return 'mais $n cartas para responder';
  }

  @override
  String stepJudge(int n) {
    return 'mais $n respostas com quão seguro estás';
  }

  @override
  String stepHold(int n) {
    return 'mais $n cartas para reter';
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
  String scoreLevel(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'curiosity': 'Curiosidade',
      'observation': 'Observação',
      'method': 'Método',
      'judgement': 'Critério',
      'insight': 'Perspicácia',
      'discernment': 'Discernimento',
      'acumen': 'Sagacidade',
      'other': '$id',
    });
    return '$_temp0';
  }

  @override
  String get levelUpTitle => 'Novo nível';

  @override
  String levelUpGain(String skill, String n) {
    return 'O que mais cresceu esta semana: $skill, $n';
  }

  @override
  String levelUpAnswers(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n respostas até agora.',
      one: '$n resposta até agora.',
    );
    return '$_temp0';
  }

  @override
  String get levelLabel => 'Nível';

  @override
  String levelPointsTo(int n, String level) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n pontos para $level',
      one: '$n ponto para $level',
    );
    return '$_temp0';
  }

  @override
  String levelAnswersTo(int n, String level) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n respostas para $level',
      one: '$n resposta para $level',
    );
    return '$_temp0';
  }

  @override
  String get levelTop => 'O nível mais alto';

  @override
  String get levelShareTitle => 'Partilha o teu nível';

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
  String deleteAccountBody(String store) {
    String _temp0 = intl.Intl.selectLogic(store, {
      'apple': 'a subscrição gere-se nas definições da App Store.',
      'google':
          'a subscrição gere-se no Google Play, em Pagamentos e subscrições.',
      'other': 'a subscrição gere-se na loja onde a compraste.',
    });
    return 'A tua conta e a cópia de segurança são apagadas para sempre, e este aparelho recomeça do início. Isto não cancela o Astute+: $_temp0';
  }

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
  String get profileTodayFive => 'As cinco de hoje';

  @override
  String profileTodayOf(int read, int of) {
    return '$read de $of';
  }

  @override
  String profileTodayToRead(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n por ler',
      one: '1 por ler',
      zero: '$n por ler',
    );
    return '$_temp0';
  }

  @override
  String get profileJourneyScores =>
      'Todas as tuas pontuações, semana a semana';

  @override
  String profileInARowLabel(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'dias seguidos',
      one: 'dia seguido',
    );
    return '$_temp0';
  }

  @override
  String get profileWeekTitle => 'Últimos 7 dias';

  @override
  String profileWeekPoints(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'pontos',
      one: 'ponto',
    );
    return '$_temp0';
  }

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
  String get yourCards => 'As tuas cartas';

  @override
  String get emptyLikedHint => 'Mantém premida uma carta de que gostes';

  @override
  String get emptySavedHint => 'Toca no marcador de uma carta';

  @override
  String get lastSevenDays => 'Últimos 7 dias';

  @override
  String get accountSection => 'Conta';

  @override
  String get aboutSection => 'Sobre';

  @override
  String get manageSubscription => 'Gerir subscrição';

  @override
  String get howPillsAreWritten => 'Como escrevemos as cartas';

  @override
  String get howTitle => 'Cada carta aqui é escrita por um modelo de IA.';

  @override
  String get howIntro =>
      'Preferimos dizê-lo logo de início a que o descubras sozinho. É assim que uma carta chega até ti.';

  @override
  String get howStep1Title => 'Escrita com IA';

  @override
  String get howStep1Line =>
      'Cada carta segue uma só instrução: uma pergunta que vale a pena, uma resposta que diz porquê e uma jogada que podes voltar a usar.';

  @override
  String get howStep2Title => 'Com as suas fontes, e lida por um crítico';

  @override
  String get howStep2Line =>
      'Cada carta diz de onde vêm os seus factos, e três em cada quatro levam ao original com um toque, para que possas verificar por ti. A maioria é lida por um segundo modelo que faz de crítico, e o que ele não consegue confirmar vai para uma lista que uma pessoa verifica. Essa lista ainda não está vazia.';

  @override
  String get howStep3Title => 'Cinco, distribuídas cada manhã';

  @override
  String get howStep3Line =>
      'Dos temas que escolheste, cartas que ainda não leste. Uma que acertaste volta mais tarde, para ver se ficou.';

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
  String get howFoot =>
      'Lemos todos os avisos, e preferimos corrigir uma carta a defendê-la.';

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
      zero: 'mais $n contextos por vir',
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
      zero: 'mais $n a ser seguidos',
    );
    return '$_temp0';
  }

  @override
  String get shareMyRecord => 'Partilhar o meu registo';

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
  String get seeThePlans => 'Ver os planos';

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
      zero: '$n cartas lidas',
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
      zero: '$n semanas cumpridas',
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
      other: '$n proteções disponíveis',
      one: '1 proteção disponível',
      zero: '$n proteções disponíveis',
    );
    return '$_temp0';
  }

  @override
  String get freePlan => 'Plano gratuito';

  @override
  String get welcomeBack => 'Bem-vindo de volta';

  @override
  String get comebackTitle => 'Que bom ver-te outra vez.';

  @override
  String get comebackStillYours => 'Continua a ser teu';

  @override
  String bestStreakStillRecord(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n dias continuam a ser',
      one: 'Um dia continua a ser',
    );
    return '$_temp0 o teu recorde. Lê as cinco de hoje e o contador recomeça do um.';
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
      other: '$n cartas que acertaste voltam hoje',
      one: '1 carta que acertaste volta hoje',
      zero: '$n cartas que acertaste voltam hoje',
    );
    return '$_temp0';
  }

  @override
  String get startAgainWithTodaysFive => 'Recomeçar com as cinco de hoje';

  @override
  String moveMyReminderTo(String time) {
    return 'Mudar o meu lembrete para as $time';
  }

  @override
  String dailyNudgeMovedTo(String time) {
    return 'Lembrete diário mudado para as $time.';
  }

  @override
  String get reminderAskTitle => 'A que horas queres o lembrete?';

  @override
  String get reminderAskLine =>
      'Uma notificação por dia, com uma pergunta das tuas cartas.';

  @override
  String get reminderAskTrialLine =>
      'Vamos avisar-te dois dias antes de o período de teste terminar.';

  @override
  String get reminderAskMorning => 'De manhã';

  @override
  String get reminderAskLunch => 'Ao almoço';

  @override
  String get reminderAskEvening => 'Ao fim do dia';

  @override
  String get reminderAskOther => 'Outra hora';

  @override
  String get reminderAskPick => 'Tu escolhes';

  @override
  String get reminderAskUsual => 'Quando costumas ler';

  @override
  String get reminderAskYes => 'Lembra-me';

  @override
  String get reminderAskNotNow => 'Agora não';

  @override
  String get placeAskTitle => 'Cartas sobre o sítio onde vives';

  @override
  String get placeAskLine =>
      'De vez em quando, o Astute vai dar-te uma carta sobre o sítio onde vives — a sua história, a sua ciência, as suas surpresas.';

  @override
  String get placeOnlyCity =>
      'Só guardamos a tua cidade, nunca a tua localização exata.';

  @override
  String get placeAskPreviewLine => 'Perto de ti · Módena';

  @override
  String get placeAskPreviewQuestion => 'A Ghirlandina está inclinada. Quanto?';

  @override
  String get placeAskYes => 'Usar a minha localização';

  @override
  String get placeAskNotNow => 'Agora não';

  @override
  String get placeRowTitle => 'Onde vives';

  @override
  String get placeRowOff => 'Desligado';

  @override
  String get placeRowOffLine =>
      'Liga para receberes cartas sobre o sítio onde vives.';

  @override
  String get placeSwitchOn => 'Ligar';

  @override
  String get placeUseNow => 'Usar a minha localização agora';

  @override
  String get placeRemove => 'Remover';

  @override
  String placeSetTo(String place) {
    return 'Onde vives: $place';
  }

  @override
  String get placeRemoved => 'Removido. O Astute já não guarda onde vives.';

  @override
  String get placeNotFound =>
      'Agora não foi possível saber onde estás. O Astute volta a tentar noutro dia.';

  @override
  String get placeDeniedNote =>
      'Não faz mal. Podes ligar quando quiseres no Perfil.';

  @override
  String get placeServicesOff =>
      'A localização está desligada neste telemóvel. Liga-a nas definições e tenta de novo.';

  @override
  String get placeNotHere => 'Este dispositivo não consegue dizer onde estás.';

  @override
  String get placeSettingsTitle => 'Localização desligada para o Astute';

  @override
  String get placeSettingsBody =>
      'Para receberes cartas sobre o sítio onde vives, permite que o Astute use a localização nas definições. Só guardamos a tua cidade.';

  @override
  String get placeSettingsOpen => 'Abrir definições';

  @override
  String trialWarningTitle(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'O teu período de teste do Astute+ termina daqui a $days dias.',
      one: 'O teu período de teste do Astute+ termina amanhã.',
      zero: 'O teu período de teste do Astute+ termina hoje.',
    );
    return '$_temp0';
  }

  @override
  String trialWarningBody(String date, String price, String path) {
    return 'A $date começa o teu ano de subscrição, por $price. Para continuar, não tens de fazer nada. Para cancelar: $path.';
  }

  @override
  String trialEndsNotice(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'O teu período de teste termina daqui a $days dias',
      one: 'O teu período de teste termina amanhã',
      zero: 'O teu período de teste termina hoje',
    );
    return '$_temp0';
  }

  @override
  String get trialNoticeManage => 'Gerir';

  @override
  String subjectsInTheMix(int n, int total) {
    return '$n de $total temas na mistura';
  }

  @override
  String get everythingIsInDrag =>
      'Está tudo dentro. Toca num tema para o tirar, ou desliza-o para a esquerda para ver menos.';

  @override
  String get mixLeaveOut => 'Tirar';

  @override
  String get mixPutBack => 'Voltar a pôr';

  @override
  String get lovesTitle => 'Escolhe os três de que mais gostas';

  @override
  String get lovesLine =>
      'Até três. Os teus primeiros dias começam por eles e, depois, aparecem mais vezes.';

  @override
  String lovesCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n de 3',
      zero: 'Toca em até três',
    );
    return '$_temp0';
  }

  @override
  String get lovesFull => 'No máximo três: toca num para o tirar.';

  @override
  String get next => 'Seguinte';

  @override
  String get whatShouldWeTalkAbout => 'De que falamos?';

  @override
  String get fivePillsADayPick =>
      'Cinco cartas por dia, novas cada manhã. Escolhe os temas que queres na mistura — podes mudá-los depois.';

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
  String get introPromiseTitle => 'Cinco cartas por dia, dois minutos';

  @override
  String get introPromiseLine =>
      'Diz a tua certeza e descobre até que ponto podes confiar no que sabes.';

  @override
  String get tagline =>
      'Percebe o porquê das coisas e até que ponto podes confiar no que sabes';

  @override
  String get introTopicsTitle => 'Vinte temas, cinco cartas';

  @override
  String get introTopicsLine =>
      'Escritas com IA e depois verificadas, e cada uma cita a sua fonte.';

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
      'Uma notificação, cinco cartas e uma sequência que não vais querer quebrar.';

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
  String get startReading => 'Começar a ler';

  @override
  String get haveAnAccount => 'Já tens conta?';

  @override
  String get signInLink => 'Iniciar sessão';

  @override
  String get signInWelcomeTitle => 'Bem-vindo de volta';

  @override
  String get signInWelcomeLine =>
      'Inicia sessão e a tua sequência, as tuas cartas guardadas e o teu registo voltam contigo.';

  @override
  String get keepStreakOnNewPhone =>
      'Leva a tua sequência para um telemóvel novo';

  @override
  String get keepStreakTitle => 'Não percas a tua sequência';

  @override
  String get keepStreakLine =>
      'Inicia sessão e um telemóvel novo continua onde este fica: a tua sequência, as tuas cartas guardadas, o teu registo.';

  @override
  String get signInNotNow => 'Agora não';

  @override
  String subjectName(String topic) {
    String _temp0 = intl.Intl.selectLogic(topic, {
      'thinking': 'Pensamento',
      'science': 'Ciência',
      'maths': 'Matemática',
      'space': 'Espaço',
      'psychology': 'Psicologia',
      'economics': 'Economia',
      'technology': 'Tecnologia',
      'history': 'História',
      'human_body': 'Corpo humano',
      'philosophy': 'Filosofia',
      'pop_culture': 'Cultura pop',
      'nature': 'Natureza',
      'language': 'Linguagem',
      'weird_facts': 'Curiosidades',
      'sport': 'Desporto',
      'cinema': 'Cinema',
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
      'Por agora, as cartas estão em inglês; a app fala a tua língua.';

  @override
  String termsLine(String terms, String privacy) {
    return 'Ao continuares aceitas os nossos $terms e a $privacy';
  }

  @override
  String get termsLineTerms => 'Termos de Utilização';

  @override
  String get termsLinePrivacy => 'Política de Privacidade';

  @override
  String get skip => 'Saltar';

  @override
  String get tapToRevealLower => 'toca para revelar';

  @override
  String get barMoveCaps => 'PARA LEVAR CONTIGO';

  @override
  String get widgetFootPlain => 'Cinco cartas, dois minutos.';

  @override
  String widgetFootStreak(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n dias seguidos',
      one: '1 dia seguido',
      zero: '$n dias seguidos',
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
  String sourceLabelKind(String kind, String source) {
    return '$kind · $source';
  }

  @override
  String deeperFootLabel(String source) {
    return 'Aprofundar. Fonte: $source';
  }

  @override
  String get sourceKindPaper => 'Estudo';

  @override
  String get sourceKindBook => 'Livro';

  @override
  String get sourceKindInstitution => 'Instituição';

  @override
  String get sourceKindDocument => 'Documento';

  @override
  String get sourceKindData => 'Dados';

  @override
  String get sourceKindReference => 'Obra de referência';

  @override
  String get sourceKindNews => 'Jornal';

  @override
  String get sourceKindCompany => 'Fonte da empresa';

  @override
  String get sourceKindStandard => 'Norma técnica';

  @override
  String get sourceKindArithmetic => 'Cálculo';

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
  String get paywallRecordTitle => 'Vê quanto sabes de verdade.';

  @override
  String get paywallRecordMark => 'de verdade.';

  @override
  String get paywallRecordLine =>
      'Todos os dias dizes quanta certeza tens. O Astute+ mostra-te se a distância entre certeza e acerto está a diminuir, e as jogadas que continuas a falhar.';

  @override
  String paywallRecordOver(int sure, int right) {
    return 'Dizes ter $sure% de certeza e acertas $right% das vezes. O Astute+ mostra-te se essa distância está a diminuir, e as jogadas que continuas a falhar.';
  }

  @override
  String paywallRecordUnder(int sure, int right) {
    return 'Dizes ter $sure% de certeza e acertas $right% das vezes: sabes mais do que pensas. O Astute+ mostra-te se essa distância está a diminuir.';
  }

  @override
  String paywallRecordEven(int sure, int right) {
    return 'Dizes ter $sure% de certeza e acertas $right% das vezes: quase iguais. O Astute+ mostra-te se isso se mantém, e as jogadas que continuas a falhar.';
  }

  @override
  String get paywallOutcomeTitle => 'Que ninguém te engane.';

  @override
  String get paywallOutcomeMark => 'engane.';

  @override
  String get paywallOutcomeLine =>
      'Cinco cartas por dia ao teu nível. As que falhas voltam até ficarem. E vês-te mudar, semana a semana.';

  @override
  String get paywallFiveTitle => 'As cinco, tuas.';

  @override
  String get paywallFiveMark => 'tuas.';

  @override
  String get paywallFiveLine =>
      'Grátis, duas das cinco são para ti, três após uma semana seguida. O Astute+ escolhe as cinco dos teus fios, ao teu nível, e traz de volta as que falhas.';

  @override
  String get paywallReadTitle => 'O que leste, dia a dia.';

  @override
  String get paywallReadMark => 'dia a dia.';

  @override
  String get paywallReadLine =>
      'Os dias que leste ultimamente, do mais recente. Toca num dia para abrir as suas cinco cartas, e numa carta para a releres.';

  @override
  String get perkGapTitle => 'Vê a distância a diminuir';

  @override
  String get perkGapLine =>
      'A tua viagem, semana a semana: certeza contra acerto, e as jogadas que continuas a falhar.';

  @override
  String get perkOwnFiveTitle => 'Cinco cartas tuas';

  @override
  String get perkOwnFiveLine =>
      'Todos os dias, ao teu nível, e as que falhas voltam.';

  @override
  String get perkReadTitle => 'O que leste';

  @override
  String get perkReadLine =>
      'Os teus últimos dias, cada um com as suas cinco cartas, prontos a reabrir.';

  @override
  String get perkAskTitle => 'O teu assistente';

  @override
  String get perkAskLine => 'Explica cada carta e põe-te à prova.';

  @override
  String get perkCoachTitle => 'Um treinador todas as semanas';

  @override
  String get perkCoachLine => 'Onde erras e o que treinar a seguir.';

  @override
  String get perkNew => 'NOVO';

  @override
  String get threeTitle => 'As três de hoje';

  @override
  String threeStep(int n, int total) {
    return '$n de $total';
  }

  @override
  String get threeSame => 'As mesmas três para todos hoje. Cerca de um minuto.';

  @override
  String threeYouSaid(String guess) {
    return 'Disseste $guess.';
  }

  @override
  String threePoints(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '+$n pontos',
      one: '+1 ponto',
      zero: 'Nenhum ponto',
    );
    return '$_temp0';
  }

  @override
  String get threeNext => 'Seguinte';

  @override
  String get threeSeeScore => 'Ver a pontuação';

  @override
  String get threeDone => 'As três de hoje · feito';

  @override
  String get threeYou => 'Você';

  @override
  String whyMissing(String move) {
    return 'Um raciocínio que te escapa: $move';
  }

  @override
  String whyMoveAgain(String move) {
    return '$move, de volta num caso novo';
  }

  @override
  String get whyAgain => 'De volta para um segundo olhar';

  @override
  String whyGoal(String goal) {
    return 'Para o teu objetivo: $goal';
  }

  @override
  String whyLiked(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Como $n cartas de que gostaste',
      one: 'Como uma carta de que gostaste',
    );
    return '$_temp0';
  }

  @override
  String whyHard(String subject) {
    return 'Uma difícil: em $subject és forte';
  }

  @override
  String whyLevel(String subject) {
    return 'Ao teu nível em $subject';
  }

  @override
  String whyGentle(String subject) {
    return 'Uma entrada fácil em $subject';
  }

  @override
  String whyYourSubject(String subject) {
    return 'De $subject, uma das tuas disciplinas';
  }

  @override
  String get whyRandom => 'Tirada ao acaso das tuas disciplinas';

  @override
  String get whyTitle => 'Porquê esta carta';

  @override
  String whyTrains(String move) {
    return 'Treina: $move';
  }

  @override
  String whyMet(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Encontraste-o $n vezes.',
      one: 'Encontraste-o uma vez.',
    );
    return '$_temp0';
  }

  @override
  String whyRight(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Certa $n vezes.',
      one: 'Certa uma vez.',
      zero: 'Ainda nenhuma certa.',
    );
    return '$_temp0';
  }

  @override
  String whyLevelRow(String subject) {
    return 'O teu nível em $subject';
  }

  @override
  String whyLevelWord(String level) {
    String _temp0 = intl.Intl.selectLogic(level, {
      'starting': 'A começar',
      'some': 'A caminho',
      'strong': 'Forte',
      'other': 'A caminho',
    });
    return '$_temp0';
  }

  @override
  String get whyLastMetRow => 'Última vez com este raciocínio';

  @override
  String whyDaysAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Há $n dias',
      one: 'Ontem',
      zero: 'Hoje',
    );
    return '$_temp0';
  }

  @override
  String get whyGoalRow => 'O teu objetivo';

  @override
  String get whyLikedRow => 'Cartas parecidas de que gostaste';

  @override
  String get whyRandomLine =>
      'No plano gratuito, parte de cada dia é tirada ao acaso das disciplinas que escolheste.';

  @override
  String get whyPlusLine =>
      'Com o Astute+, as cinco são escolhidas para ti: ao teu nível, ao teu gosto, e os raciocínios que te escapam voltam.';

  @override
  String get whyMakeMine => 'As cinco para mim';

  @override
  String get whyMore => 'Mais como esta';

  @override
  String get whyMoreDone => 'Anotado: mais como esta';

  @override
  String get whyLess => 'Menos';

  @override
  String get whyTune => 'Ajustar a tua mistura';

  @override
  String get searchTry => 'Experimenta';

  @override
  String get searchByNeed => 'Por necessidade';

  @override
  String get searchByKind => 'Por tipo';

  @override
  String kindName(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'play': 'Para jogar',
      'quiz': 'Quizzes',
      'estimate': 'Estimativas',
      'debate': 'Debates',
      'quick': 'Leituras rápidas',
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
      zero: '$n cartas',
    );
    return '$_temp0';
  }

  @override
  String get areaUsefulFor => 'Serve-te para';

  @override
  String areaPaths(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n percursos · dez cartas cada',
      one: 'Um percurso · dez cartas',
    );
    return '$_temp0';
  }

  @override
  String get areaMoves => 'Os raciocínios que treinas aqui';

  @override
  String get areaMoreCards => 'Mais cartas para isto';

  @override
  String get pathKicker => 'Percurso';

  @override
  String pathMeta(String subject, int n, int minutes) {
    return '$subject · $n cartas · cerca de $minutes min';
  }

  @override
  String pathPartOf(int part, int parts) {
    return 'Parte $part de $parts';
  }

  @override
  String pathTrains(String moves) {
    return 'Treina: $moves';
  }

  @override
  String pathReadOf(int n, int total) {
    return '$n de $total lidas';
  }

  @override
  String get pathFreeTag => 'Grátis';

  @override
  String get pathStart => 'Começar o percurso';

  @override
  String pathContinueAt(int n) {
    return 'Continuar · carta $n';
  }

  @override
  String get pathContinue => 'Continuar';

  @override
  String get notesTitle => 'Notas';

  @override
  String get noteYours => 'A tua nota';

  @override
  String get noteAdd => 'Adicionar uma nota';

  @override
  String get noteEdit => 'Editar';

  @override
  String get noteSave => 'Guardar';

  @override
  String get noteDelete => 'Apagar a nota';

  @override
  String get noteHint => 'O que queres lembrar desta carta?';

  @override
  String get notesEmpty =>
      'Ainda não tens notas. Abre uma carta que guardaste e escreve o que queres lembrar.';

  @override
  String get pathUnlock => 'Desbloquear todos os percursos';

  @override
  String get pathFreeLine =>
      'As duas primeiras cartas de cada percurso são grátis.';

  @override
  String pathNextPart(int n) {
    return 'Parte $n: mais a fundo';
  }

  @override
  String pathDeeperLine(int n) {
    return 'Mais $n cartas do mesmo tema, mais difíceis.';
  }

  @override
  String get pathAgain => 'Ler outra vez';

  @override
  String get subjectKicker => 'Disciplina';

  @override
  String subjectReadOf(int n, int total) {
    return '$n de $total cartas lidas';
  }

  @override
  String subjectRight(int right, int answered) {
    return '$right certas de $answered respondidas';
  }

  @override
  String subjectToNext(int n, int level) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n respostas certas até ao nível $level',
      one: 'Uma resposta certa até ao nível $level',
    );
    return '$_temp0';
  }

  @override
  String get subjectLevel => 'Nível';

  @override
  String get subjectNext => 'A próxima para ti';

  @override
  String get subjectNextLine => 'Um degrau acima do teu nível.';

  @override
  String subjectInside(String subject) {
    return 'Dentro de $subject';
  }

  @override
  String get journeySubjectsTap =>
      'Toca numa disciplina para ver a sua página.';

  @override
  String moveName(String move) {
    String _temp0 = intl.Intl.selectLogic(move, {
      'baseRate': 'Taxas de base',
      'survivorship': 'Sobreviventes',
      'regression': 'Regressão à média',
      'confirmation': 'Confirmação',
      'anchoring': 'Ancoragem',
      'sampling': 'Amostra',
      'confounding': 'Fatores de confusão',
      'counterfactual': 'Comparado com quê',
      'multipleComparisons': 'Muitas tentativas',
      'availability': 'Disponibilidade',
      'sunkCost': 'Custos irrecuperáveis',
      'conjunction': 'Conjunção',
      'conditional': 'Probabilidade condicional',
      'independence': 'Independência',
      'coincidence': 'Coincidências',
      'exponential': 'Crescimento exponencial',
      'reflection': 'A resposta rápida',
      'simpson': 'Agregados',
      'estimation': 'Estimativa',
      'computation': 'Fazer as contas',
      'other': 'Raciocínio',
    });
    return '$_temp0';
  }

  @override
  String moveLine(String move) {
    String _temp0 = intl.Intl.selectLogic(move, {
      'baseRate':
          'A precisão de um teste não é a probabilidade de te dizer respeito',
      'survivorship': 'Os dados que tens são os que sobreviveram',
      'regression': 'Os extremos voltam sozinhos para trás',
      'confirmation': 'Procurar um sim não é um teste',
      'anchoring': 'O primeiro número dito mexe com todos os seguintes',
      'sampling': 'Quem entra na amostra decide o que ela pode dizer',
      'confounding': 'Talvez outra coisa cause as duas',
      'counterfactual': 'Uma mudança não diz nada sem comparação',
      'multipleComparisons': 'Testa coisas suficientes e uma passa',
      'availability': 'Fácil de imaginar não é o mesmo que frequente',
      'sunkCost': 'Gasto está gasto: só se decide sobre o que resta',
      'conjunction':
          'Os detalhes tornam uma história mais credível e menos provável',
      'conditional': 'O que te dizem muda as probabilidades',
      'independence': 'O acaso não tem memória',
      'coincidence': 'As coisas raras são comuns quando há muitas tentativas',
      'exponential': 'Ninguém tem intuição para duplicações',
      'reflection': 'A resposta que chega primeiro é a que se deve verificar',
      'simpson': 'Um todo pode inclinar-se para onde nenhuma parte se inclina',
      'estimation': 'Divide o impossível em coisas que podes estimar',
      'computation': 'Um problema que consegues mesmo acabar',
      'other': 'Raciocínio',
    });
    return '$_temp0';
  }

  @override
  String get threeSend => 'Enviar';

  @override
  String get threeWhy => 'Ver o porquê';

  @override
  String threeYesterday(int score) {
    return 'As três de ontem: $score de 300.';
  }

  @override
  String get fiveTitle => 'O desafio de hoje';

  @override
  String get fiveSame =>
      'As mesmas cinco para todos hoje. Cerca de dois minutos.';

  @override
  String get fiveDone => 'O desafio de hoje · feito';

  @override
  String dailyOf(int max) {
    return 'de $max';
  }

  @override
  String dailyPickRight(String answer) {
    return 'Certa: $answer';
  }

  @override
  String dailyPickWrong(String answer) {
    return 'Não exatamente. Certa: $answer';
  }

  @override
  String dailyYourPick(String answer) {
    return 'A tua: $answer';
  }

  @override
  String dailyBetter(int pct, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Melhor do que $pct% dos $n jogadores de hoje.',
    );
    return '$_temp0';
  }

  @override
  String dailyPlayers(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Até agora, $n jogadores hoje.',
      one: 'Até agora, 1 jogador hoje.',
      zero: 'Até agora, $n jogadores hoje.',
    );
    return '$_temp0';
  }

  @override
  String dailyFirst(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          'Entre os primeiros $n a jogar hoje: ainda são poucos para comparar.',
      one: 'O primeiro a jogar hoje: ainda são poucos para comparar.',
    );
    return '$_temp0';
  }

  @override
  String get dailyCounting => 'A contar os jogadores de hoje…';

  @override
  String dailyAverage(int right, int total, String avg) {
    return 'Acertaste $right de $total. Nestas, os leitores acertam $avg em média.';
  }

  @override
  String get dailyUncounted =>
      'Agora não é possível contar os jogadores de hoje.';

  @override
  String get dailyEach => 'Pergunta a pergunta';

  @override
  String dailyItemRight(int pct) {
    return '$pct% dos jogadores de hoje acertaram';
  }

  @override
  String dailyItemGuess(String guess) {
    return 'Estimativa média de hoje: $guess';
  }

  @override
  String get dailyItemFew => 'Ainda há poucas respostas para comparar';

  @override
  String fiveYesterday(int score) {
    return 'As cinco de ontem: $score de 500.';
  }

  @override
  String fiveShareHead(String date) {
    return 'Astute · O desafio de hoje · $date';
  }

  @override
  String fiveChallengeLine(int right) {
    return 'Acertei $right das cinco de hoje no Astute. Consegues bater-me?';
  }

  @override
  String get fiveChallengeAll =>
      'Acertei as cinco de hoje no Astute. Consegues igualar?';

  @override
  String get fiveChallengeInvite =>
      'O desafio de hoje no Astute: as mesmas cinco perguntas para todos. Quantas acertas?';

  @override
  String threeShareHeadIn(String subject, String date) {
    return 'Astute · As três de hoje · $subject · $date';
  }

  @override
  String dailyShareScore(int score, int max, int day) {
    return '$score de $max · dia $day';
  }

  @override
  String dailyShareScoreAlone(int score, int max) {
    return '$score de $max';
  }

  @override
  String get skillsTitle => 'O que aprender';

  @override
  String get skillsTitleMark => 'aprender';

  @override
  String get skillsLine =>
      'Cada resposta mexe na pontuação. As que treinam o que escolheres têm a sua marca.';

  @override
  String get skillsDone => 'Feito';

  @override
  String get skillsFocus => 'EM FOCO';

  @override
  String get skillMarkKicker => 'ESTA CARTA TREINA';

  @override
  String skillMarkLabel(String skill) {
    return 'Treina $skill';
  }

  @override
  String get skillMarkBody =>
      'Uma das capacidades que puseste em foco. Cada resposta numa carta como esta mexe na tua pontuação.';

  @override
  String get skillMarkOpen => 'Ver todas as tuas pontuações';

  @override
  String get trainingTitle => 'O teu treino';

  @override
  String get trainingLine =>
      'Cada resposta mexe na tua pontuação, e uma carta difícil acertada é a que mais conta. Não há teto.';

  @override
  String get trainingOthers => 'As outras';

  @override
  String get trainingEmpty =>
      'Escolhe em que queres melhorar. Cada resposta numa carta que o treina mexe na tua pontuação, e a carta tem a sua marca.';

  @override
  String get trainingPick => 'Escolher capacidades';

  @override
  String trainingMore(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'e mais $n',
      one: 'e mais 1',
      zero: 'e mais $n',
    );
    return '$_temp0';
  }

  @override
  String get aimTitle => 'Onde queres ver mais claro?';

  @override
  String get aimLine =>
      'Escolhe um. Todos os dias há cartas para isso, e podes mudá-lo quando quiseres.';

  @override
  String aimWeek(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n cartas para isto esta semana',
      one: '1 carta para isto esta semana',
      zero: 'Nenhuma carta para isto esta semana',
    );
    return '$_temp0';
  }

  @override
  String answersRightOf(int right, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      right,
      locale: localeName,
      other: '$right certas em $n',
      one: '1 certa em $n',
    );
    return '$_temp0';
  }

  @override
  String get aimOpen => 'Tudo para este objetivo';

  @override
  String get aimPlus =>
      'Com o Astute+: todos os percursos inteiros, e um treinador que trabalha nisso contigo.';

  @override
  String get aimNone =>
      'Escolhe onde queres ver mais claro: todos os dias haverá cartas para isso.';

  @override
  String get aimPick => 'Escolher objetivo';

  @override
  String get strengthsTitle => 'Onde és forte';

  @override
  String get strengthsLine =>
      'Dizem-no as tuas respostas, não uma escolha: onde acertas mais e onde falhas.';

  @override
  String strengthsFew(String skills) {
    return 'Ainda poucas respostas: $skills.';
  }

  @override
  String strengthsPractice(String skill) {
    return 'Pratica $skill';
  }

  @override
  String get strengthsBest => 'O teu ponto forte';

  @override
  String get strengthsWeak => 'Onde falhas mais';

  @override
  String get strengthsLocked => 'Onde falhas mais, e o resto, com o Astute+.';

  @override
  String get strengthsEmpty =>
      'Mais algumas respostas e verás aqui onde és forte.';

  @override
  String get readTitle => 'Onde já vês claro';

  @override
  String get readBlind => 'O teu ponto cego';

  @override
  String get readLocked =>
      'Cinco cartas sobre o teu ponto cego, e o teu perfil inteiro, com o Astute+.';

  @override
  String get readEmpty =>
      'Mais algumas respostas e verás aqui onde vês claro e onde não.';

  @override
  String get readNoAim =>
      'Escolhe acima onde queres ver mais claro: as tuas respostas vão dizer-te onde já vês.';

  @override
  String get readLine =>
      'As competências que este objetivo pede, lidas nas tuas respostas: onde vês claro, e o teu ponto cego.';

  @override
  String get readOthers => 'O resto do teu perfil';

  @override
  String get focusTitle => 'O foco da semana';

  @override
  String get focusFromGoal =>
      'Escolhido a partir do teu objetivo: cada semana uma competência diferente.';

  @override
  String get focusFromMisses =>
      'Escolhido a partir das tuas respostas: onde falhas mais.';

  @override
  String get focusLine =>
      'As cartas que o treinam têm a sua marca. No domingo, como correu a semana.';

  @override
  String focusLast(String skill) {
    return 'Na semana passada: $skill';
  }

  @override
  String focusNext(String skill) {
    return 'A partir de segunda: $skill';
  }

  @override
  String get focusResult => 'Como correu a semana';

  @override
  String get focusPlus =>
      'Com o Astute+, o foco é escolhido pelas tuas respostas: onde falhas mais.';

  @override
  String get focusMarkBody =>
      'Esta semana treinas esta competência: as cartas que a treinam têm esta marca. No domingo vês como correu.';

  @override
  String focusShelf(String skill) {
    return 'Foco da semana: $skill';
  }

  @override
  String get focusShelfLine => 'Cartas que o treinam, ainda por ler.';

  @override
  String get focusOpen => 'A tua semana';

  @override
  String get scoreTitle => 'Pontuação Astute';

  @override
  String scoreWeek(String n) {
    return '$n esta semana';
  }

  @override
  String get scoreStart => 'Começa com a tua primeira resposta.';

  @override
  String scoreMoveLabel(String name, String n) {
    return '$name: $n por esta resposta';
  }

  @override
  String scoreAnswers(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'de $n respostas',
      one: 'de 1 resposta',
      zero: 'de $n respostas',
    );
    return '$_temp0';
  }

  @override
  String get videoKicker => 'Vídeo';

  @override
  String get videoPlay => 'Reproduzir';

  @override
  String get videoPause => 'Pausar';

  @override
  String get videoWatchAgain => 'Ver de novo';

  @override
  String get videoOffline =>
      'O vídeo precisa de conexão. Toque para tentar de novo.';

  @override
  String get skillsRowTitle => 'O que queres aprender';

  @override
  String skillName(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'critical': 'Pensamento crítico',
      'decisions': 'Decidir melhor',
      'money': 'Dinheiro e poupança',
      'numbers': 'Números e estatística',
      'talk': 'Comunicar',
      'persuade': 'Persuadir',
      'people': 'Compreender pessoas',
      'fakes': 'Detetar falsidades',
      'science': 'Pensar como cientista',
      'focus': 'Concentração',
      'lead': 'Liderança',
      'culture': 'Cultura geral',
      'other': '$key',
    });
    return '$_temp0';
  }

  @override
  String skillLine(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'critical': 'Distinguir um bom argumento de um que engana.',
      'decisions': 'Escolher com riscos e probabilidades, não por instinto.',
      'money': 'Preços, juros, promoções: para onde vai o seu dinheiro.',
      'numbers': 'Ler porcentagens e gráficos sem se deixar enganar.',
      'talk': 'Fazer-se entender, falando e escrevendo.',
      'persuade': 'Convencer, e perceber quando tentam convencer você.',
      'people': 'Por que as pessoas fazem o que fazem.',
      'fakes':
          'Reconhecer notícias falsas, fotos adulteradas e estudos inflados.',
      'science': 'Testar uma ideia antes de acreditar nela.',
      'focus': 'Manter a atenção onde importa, por mais tempo.',
      'lead': 'Liderar um grupo e decidir por todos.',
      'culture': 'História, ciência, arte: o que todos citam.',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get perkFiveShort => 'Todos os dias, ao teu nível.';

  @override
  String get perkShelvesTitle => 'Cada percurso e cada livro';

  @override
  String get perkShelvesLine => 'Inteiros, e novos todas as semanas.';

  @override
  String get perkGapShort => 'Quão certo estás contra quanto acertas.';

  @override
  String get perkReadShort => 'Cada dia lido, para voltar a abrir.';

  @override
  String get trialToday => 'Hoje · todo o Astute+, grátis';

  @override
  String trialReminder(int day) {
    return 'Dia $day · avisamos-te';
  }

  @override
  String trialCharge(int day, String price, String plan) {
    String _temp0 = intl.Intl.selectLogic(plan, {
      'year': 'por ano',
      'other': 'por mês',
    });
    return 'Dia $day · $price $_temp0, com renovação automática até cancelares';
  }

  @override
  String chargedTodayRenews(String price, String suffix) {
    return '$price$suffix cobrados hoje, com renovação automática até cancelares';
  }

  @override
  String cancelHow(String where) {
    return 'Cancela quando quiseres em $where, pelo menos 24 horas antes da renovação.';
  }

  @override
  String get cancelWhereIos => 'Definições › o teu nome › Subscrições';

  @override
  String get cancelWhereAndroid =>
      'Google Play › Pagamentos e subscrições › Subscrições';

  @override
  String storeAsking(String store) {
    String _temp0 = intl.Intl.selectLogic(store, {
      'apple': 'A pedir os preços à App Store…',
      'other': 'A pedir os preços ao Google Play…',
    });
    return '$_temp0';
  }

  @override
  String storeUnreachable(String store) {
    String _temp0 = intl.Intl.selectLogic(store, {
      'apple': 'Não foi possível contactar a App Store',
      'other': 'Não foi possível contactar o Google Play',
    });
    return '$_temp0';
  }

  @override
  String get storeUnreachableLine =>
      'Os preços e o período experimental vêm da loja. Verifica a ligação e tenta outra vez.';

  @override
  String get tryAgain => 'Tentar de novo';

  @override
  String get purchasePending =>
      'À espera de aprovação. O Astute+ abre assim que o pagamento for concluído.';

  @override
  String get oneMoment => 'Um momento…';

  @override
  String get purchaseConfirming => 'A confirmar o pagamento…';

  @override
  String get purchaseConfirmingSlow =>
      'Está a demorar mais do que o habitual. O pagamento está seguro: o Astute+ ativa-se sozinho.';

  @override
  String get closeLabel => 'Fechar';

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
  String get verdictRight => 'Certo.';

  @override
  String get verdictClose => 'Perto o suficiente.';

  @override
  String get verdictWrong => 'Não exatamente.';

  @override
  String verdictSure(int pct) {
    return 'Estavas $pct% seguro.';
  }

  @override
  String verdictYouSaid(String given) {
    return 'Disseste $given';
  }

  @override
  String verdictYouSaidSure(String given, int pct) {
    return 'Disseste $given, com $pct% de certeza';
  }

  @override
  String verdictRightIs(String answer) {
    return 'Certa: $answer';
  }

  @override
  String verdictRightWithin(String answer, String low, String high) {
    return 'Certa: $answer (contava de $low a $high)';
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
  String get swipeForTheNextOne => 'Desliza para a próxima';

  @override
  String get musicSound => 'Som nas cartas de música';

  @override
  String get musicSoundIsOff => 'O som das cartas de música está desligado.';

  @override
  String get musicSoundTurnOn => 'Ligar';

  @override
  String get thatWasTheOnlyOne => 'Era a única';

  @override
  String get lastOne => 'A última';

  @override
  String deckEndTitle(String word) {
    return 'Já viste as $word.';
  }

  @override
  String get deckEndAgain => 'Recomeçar pela primeira';

  @override
  String indexOfN(int i, int n) {
    return '$i/$n';
  }

  @override
  String get couldNotRenderCard => 'Não foi possível desenhar a carta.';

  @override
  String get textCopiedInstead => 'Em vez disso, o texto foi copiado.';

  @override
  String get copiedToClipboard => 'Copiado para a área de transferência.';

  @override
  String get rendering => 'A desenhar…';

  @override
  String get theSourceGoesWithIt => 'A fonte vai com ele';

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
      zero: '$n gostadas hoje',
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
  String get nudgeBookTitle => 'O livro grátis desta semana';

  @override
  String nudgeBookBody(String title, String author, int minutes) {
    return '$title, de $author: as grandes ideias em $minutes minutos.';
  }

  @override
  String get nudgeFreezeTitle => 'A tua sequência está protegida';

  @override
  String nudgeFreezeBody(String question) {
    return 'Ontem ficou protegido. Hoje: $question';
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
  String get yourJourney => 'A tua viagem';

  @override
  String journeySince(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Desde a tua última visita, há $days dias',
      one: 'Desde a tua última visita, ontem',
      zero: 'Desde a tua última visita, hoje',
    );
    return '$_temp0';
  }

  @override
  String journeySinceMark(String n) {
    return '$n desde a tua última visita';
  }

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
      zero: '$n truques',
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
  String get consentTitle => 'Ajudas a melhorar o Astute?';

  @override
  String get consentLine =>
      'Partilha como usas a app — nunca o teu nome, o teu email ou o que escreves.';

  @override
  String get consentCardLine =>
      'Contamos como a app é usada, sem publicidade e nunca com o teu nome.';

  @override
  String get consentNo => 'Não, obrigado';

  @override
  String get consentYes => 'Sim, partilhar';

  @override
  String consentChangeLater(String profile, String setting) {
    return 'Podes mudar isto quando quiseres em $profile, em $setting.';
  }

  @override
  String get yourMix => 'A tua mistura';

  @override
  String get genresTitle => 'Que partes?';

  @override
  String get genresLine =>
      'Toca num género para o saltar. Mantém premido e os temas mais pequenos lá dentro abrem-se logo abaixo.';

  @override
  String get partsOfferLine =>
      'Ao fim de uns dias, já conheces as cartas. Em cada tema, fica com as partes que queres e deixa o resto.';

  @override
  String get partsOfferChoose => 'Escolher as partes';

  @override
  String get partsOfferNotNow => 'Agora não';

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
      'Cinco cartas por dia escolhidas para ti: da tua mistura, ao teu nível, e as que falhas voltam. A partir de amanhã.';

  @override
  String get plusCardHeadline => 'As cinco, tuas.';

  @override
  String get plusCardLine =>
      'Cinco cartas por dia da tua mistura, ao teu nível. A tua viagem. Todo o teu arquivo.';

  @override
  String get archiveBeforeThisWeek => 'Antes desta semana';

  @override
  String get weekKeptThreeOwn =>
      'Sete dias seguidos: amanhã três das cinco são tuas.';

  @override
  String get weekKeptSundayFourOwn =>
      'Sete dias seguidos, e amanhã é domingo: quatro das cinco são tuas.';

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
      zero: '$n leitores',
    );
    return '$_temp0';
  }

  @override
  String get topPicksTitle => 'Valem o teu tempo';

  @override
  String get topPicksLine =>
      'Escolhidas pelo Astute enquanto a lista dos leitores se vai enchendo';

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
  String get storyHint => 'Toca para continuar · mantém premido para pausar';

  @override
  String get storyTapOn => 'Toca para continuar';

  @override
  String get storyPrevious => 'Anterior';

  @override
  String get storyClose => 'Fechar a história';

  @override
  String get storySave => 'Guardar';

  @override
  String get storySaved => 'Guardada';

  @override
  String get storyShare => 'Partilhar';

  @override
  String get storyOpenCard => 'Abrir a carta';

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
  String weekRecapMore(int n) {
    return 'Mais $n da tua semana com Astute+';
  }

  @override
  String get weekReviewTitle => 'Revê a semana';

  @override
  String get weekReviewLine =>
      'As perguntas das tuas cartas desta semana. Responde outra vez: é assim que ficam.';

  @override
  String get weekReviewGo => 'Rever';

  @override
  String get weekReviewNone =>
      'As cartas que leres esta semana voltam aqui, para rever.';

  @override
  String get plusInTheApp =>
      'O Astute+ está na app: descarrega o Astute no iPhone ou Android para começar o teste gratuito.';

  @override
  String get purchaseComplete => 'Compra concluída.';

  @override
  String get trialStartedTitle => 'Período experimental iniciado.';

  @override
  String get successWelcome =>
      'Boas-vindas ao Astute+. As cinco cartas de hoje estão prontas.';

  @override
  String successWelcomeNamed(String name) {
    return 'Boas-vindas ao Astute+, $name. As cinco cartas de hoje estão prontas.';
  }

  @override
  String get successWelcomeTomorrow =>
      'Boas-vindas ao Astute+. As cinco de amanhã são todas tuas.';

  @override
  String successWelcomeTomorrowNamed(String name) {
    return 'Boas-vindas ao Astute+, $name. As cinco de amanhã são todas tuas.';
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
    return 'Primeira cobrança em $date · cancela quando quiseres';
  }

  @override
  String successFootRenews(String date) {
    return 'Renova em $date · cancela quando quiseres';
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
  String get revealPlayScene => 'Experimenta tu';

  @override
  String get revealBackToAnswer => 'Voltar à resposta';

  @override
  String get revealShowWorking => 'Ver o raciocínio';

  @override
  String get sceneLockIn => 'Confirmar';

  @override
  String get placeItDrag => 'Arrasta ao longo da régua.';

  @override
  String get placeItHappy => 'Fica assim?';

  @override
  String get placeItEstimate => 'O teu palpite';

  @override
  String get placeItNotSet => 'ainda por definir';

  @override
  String get placeItLock => 'Confirmar o meu palpite';

  @override
  String get sceneYou => 'TU';

  @override
  String get sceneTruth => 'REAL';

  @override
  String get sceneTryAgain => 'De novo';

  @override
  String get sceneDrawHint => 'Desenha o teu palpite com o dedo';

  @override
  String get sceneHoldHint => 'Pressiona e segura';

  @override
  String get sceneSwipeHint => 'Desliza ou toca';

  @override
  String get sceneTapToPick => 'Toca na tua escolha';

  @override
  String get sceneShowMe => 'Mostra-me';

  @override
  String get sceneYourGuess => 'O teu palpite';

  @override
  String sceneNOfM(int n, int m) {
    return '$n de $m';
  }

  @override
  String get reportProblem => 'Reportar um problema';

  @override
  String get reportedThanks => 'Reportado. Obrigado.';

  @override
  String get reportTitle => 'O que está errado nesta carta?';

  @override
  String get reportLead =>
      'Verificamos cada aviso nas fontes e corrigimos a carta.';

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
      other: '$n cartas',
      one: '$n carta',
      zero: '$n cartas',
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
      other: '$n cartas',
      one: '1 carta',
      zero: '$n cartas',
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
      zero: '$n respostas',
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
      zero: '$n respostas com a tua certeza',
    );
    return '$_temp0';
  }

  @override
  String journeyToGoHeld(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n cartas retidas',
      one: '1 carta retida',
      zero: '$n cartas retidas',
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
      zero: '$n pontos',
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
      zero: '$n livros',
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
      zero: 'faltam $n para o primeiro livro',
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
  String get journeyHardNow => 'As cartas que abres.';

  @override
  String journeyHardThen(String v, String month) {
    return 'As cartas que abres. $v em $month';
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
    return '$now min por semana, no início $was min';
  }

  @override
  String journeyMinThisWeek(int m) {
    return '$m min esta semana';
  }

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
  String get journeyMovesTitle => 'Truques que apanhas';

  @override
  String get journeySureEmpty => 'Aparece quando responderes com 80% ou mais.';

  @override
  String get journeyMovesEmpty =>
      'Aparece quando apanhares um truque em duas cartas.';

  @override
  String get journeyMissedEmpty =>
      'Seis respostas numa segunda área e fica medida.';

  @override
  String get journeyFillsAsYouRead => 'Vai-se preenchendo à medida que lês.';

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
      other: 'cartas ainda contigo',
      one: 'carta ainda contigo',
      zero: 'cartas ainda contigo',
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
      zero: '$days dias',
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
  String get journeyInPlace => 'No mundo';

  @override
  String journeyRegions(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n regiões',
      one: '1 região',
      zero: '$n regiões',
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
  String get journeyTopics => 'Subtemas';

  @override
  String journeyMet(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n descobertos',
      one: '1 descoberto',
      zero: '$n descobertos',
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
      zero: '$n novas',
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
    return 'Tema: $where';
  }

  @override
  String get howSure => 'Até que ponto tenho a certeza, e porquê?';

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
      zero: '$cards cartas',
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
  String get moveComparedToWhat => 'Muito ou pouco?';

  @override
  String get moveComparedToWhatLine =>
      '«Mais 30%» não quer dizer nada enquanto não souberes: comparado com quê?';

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
  String get moveSampling => 'Quem falta nos dados?';

  @override
  String get moveSamplingLine =>
      'Qualquer estatística conta umas pessoas e deixa outras de fora. Quem falta pode virar a resposta ao contrário';

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
  String rangeWidth(int w, int pts) {
    return '±$w · $pts pts';
  }

  @override
  String get rightLastTime => 'Certa da última vez';

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
  String get spotLine =>
      'Quatro afirmações. Três são verdadeiras, uma é falsa.';

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
  String get todayLabel => 'Hoje';

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
  String get unmaskMisleadTitle => 'Gráficos que enganam';

  @override
  String get unmaskMisleadLine =>
      'Os números são verdadeiros. O truque está no desenho.';

  @override
  String get unmaskAsk => 'Este gráfico engana. Consegues ver como?';

  @override
  String get unmaskShowTrick => 'Mostrar o truque';

  @override
  String get unmaskHideTrick => 'Esconder o truque';

  @override
  String get unmaskOriginal => 'Original';

  @override
  String get unmaskCorrected => 'Corrigido';

  @override
  String unmaskTrickTruncated(String from) {
    return 'O eixo começa em $from, não em zero.';
  }

  @override
  String unmaskTrickZoomed(String low, String high) {
    return 'O eixo só vai de $low a $high, por isso uma pequena mudança parece enorme.';
  }

  @override
  String unmaskTrickWide(String low, String high) {
    return 'O eixo vai de $low a $high, por isso uma mudança real parece plana.';
  }

  @override
  String unmaskTrickWindow(String shown, String all) {
    return 'Mostra só $shown, mas os dados cobrem $all.';
  }

  @override
  String get unmaskTrickTotals =>
      'Compara totais brutos, não uma medida justa.';

  @override
  String get unmaskTrickFlippedRise =>
      'O eixo está de pernas para o ar: uma subida parece uma descida.';

  @override
  String get unmaskTrickFlippedFall =>
      'O eixo está de pernas para o ar: uma descida parece uma subida.';

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

  @override
  String placeNearYou(String place) {
    return 'Perto de ti · $place';
  }

  @override
  String placeYourRegion(String place) {
    return 'A tua região · $place';
  }

  @override
  String placeYourCountry(String place) {
    return 'O teu país · $place';
  }

  @override
  String get sundayOneMore => 'Domingo: mais uma escolhida para ti';

  @override
  String get whereYouLive => 'Onde vives';

  @override
  String get whereYouLiveLine =>
      'Primeiro a tua cidade, depois a região, depois o país';

  @override
  String get whereYouLiveAsk =>
      'Cartas sobre a tua cidade, a tua região e o teu país: no máximo uma por dia, e esta estante. Só se guarda a cidade, nunca onde estás exatamente.';

  @override
  String get whereYouLiveSwitchOn => 'Ativar';

  @override
  String get gateUpdateTitle => 'Atualiza o Astute';

  @override
  String gateUpdateLine(String store) {
    String _temp0 = intl.Intl.selectLogic(store, {
      'apple': 'A nova está à tua espera na App Store',
      'google': 'A nova está à tua espera no Google Play',
      'other': 'A nova está à tua espera na tua loja de aplicações',
    });
    return 'Esta versão já não pode continuar. $_temp0, com as tuas cartas e a tua sequência tal como as deixaste.';
  }

  @override
  String get gateUpdateButton => 'Atualizar';

  @override
  String get gateSoftTitle => 'Há uma nova versão do Astute';

  @override
  String gateSoftLine(String store) {
    String _temp0 = intl.Intl.selectLogic(store, {
      'apple': 'Está à tua espera na App Store.',
      'google': 'Está à tua espera no Google Play.',
      'other': 'Está à tua espera na tua loja de aplicações.',
    });
    return '$_temp0 Atualizar demora um instante, e as tuas cartas e a tua sequência ficam como estão.';
  }

  @override
  String get gateSoftLater => 'Mais tarde';

  @override
  String get gatePauseTitle => 'O Astute está a fazer uma pequena pausa';

  @override
  String get gatePauseLine =>
      'Estamos a corrigir uma coisa nos bastidores. Tudo o que fizeste está seguro. Tenta outra vez daqui a pouco.';

  @override
  String get gatePauseTrying => 'A tentar outra vez…';

  @override
  String get gatePauseStill =>
      'Ainda em pausa. Tenta outra vez daqui a uns minutos.';

  @override
  String purposeReadOrDoCount(int toDo, int toRead) {
    return '$toDo para fazer, $toRead para ler';
  }

  @override
  String purposeShelfCount(int toDo, int toRead) {
    return '$toDo para fazer · $toRead para ler';
  }

  @override
  String get purposeFilterToRead => 'Ler';

  @override
  String get purposeFilterToDo => 'Fazer';

  @override
  String purposeVerb(String verb) {
    String _temp0 = intl.Intl.selectLogic(verb, {
      'trueFalse': 'Verdadeiro ou falso',
      'pick': 'Escolhe uma',
      'typeNumber': 'Escreve um número',
      'bet': 'Aposta no número',
      'side': 'Escolhe um lado',
      'youFirst': 'Tu primeiro',
      'moveIt': 'Mexe e vê',
      'whatNext': 'O que acontece a seguir?',
      'spotTrick': 'Descobre o truque',
      'drawIt': 'Desenha',
      'sortThem': 'Separa-os',
      'putInOrder': 'Põe por ordem',
      'holdIt': 'Mantém premido',
      'growSample': 'Aumenta a amostra',
      'askWhy': 'Pergunta porquê',
      'sayPlainly': 'Di-lo de forma simples',
      'pairUp': 'Emparelha',
      'followClues': 'Segue as pistas',
      'look': 'Só olhar',
      'listen': 'Ouve',
      'other': '$verb',
    });
    return '$_temp0';
  }

  @override
  String purposeVerbRead(int n) {
    return 'Ler · $n min';
  }

  @override
  String get purposeCommitNote =>
      'Responde aqui e depois abre a carta para veres se acertaste. Um palpite com que te comprometes fica contigo mais tempo.';

  @override
  String get purposeCommitTitle => 'Primeiro responde';

  @override
  String get purposeCommitLine => 'Diz o que pensas e depois abre a carta';

  @override
  String get purposeInYourHeadLine => 'Um número a que chegar de cabeça';

  @override
  String get purposeInYourHead => 'De cabeça';

  @override
  String get purposeMoveKicker => 'Uma jogada';

  @override
  String purposeMoveNew(int points) {
    return 'Nova · +$points quando a dominares';
  }

  @override
  String purposeMoveName(String move) {
    String _temp0 = intl.Intl.selectLogic(move, {
      'baseRate': 'Taxas de base',
      'survivorship': 'Sobrevivência',
      'regression': 'Regressão à média',
      'confirmation': 'Confirmação',
      'anchoring': 'Ancoragem',
      'sampling': 'Amostragem',
      'confounding': 'Fator de confusão',
      'counterfactual': 'Comparado com quê',
      'multipleComparisons': 'Muitas tentativas',
      'availability': 'Disponibilidade',
      'sunkCost': 'Custo afundado',
      'conjunction': 'Conjunção',
      'conditional': 'Probabilidade condicionada',
      'independence': 'Independência',
      'coincidence': 'Coincidência',
      'exponential': 'Crescimento exponencial',
      'reflection': 'A resposta rápida',
      'simpson': 'Totais',
      'estimation': 'Estimativa',
      'computation': 'Fazer as contas',
      'other': '$move',
    });
    return '$_temp0';
  }

  @override
  String purposeMoveLine(String move) {
    String _temp0 = intl.Intl.selectLogic(move, {
      'baseRate': 'A precisão de um teste não é a probabilidade de seres tu',
      'survivorship': 'Os dados que tens são os que sobreviveram',
      'regression': 'Os extremos voltam sozinhos à média',
      'confirmation': 'Procurar um sim não é um teste',
      'anchoring': 'O primeiro número dito mexe em todos os seguintes',
      'sampling': 'Quem foi parar à amostra decide o que ela pode dizer',
      'confounding': 'Talvez outra coisa cause as duas',
      'counterfactual': 'Uma mudança não diz nada sem um grupo de controlo',
      'multipleComparisons': 'Testa coisas suficientes e uma passa',
      'availability': 'Fácil de imaginar não é o mesmo que frequente',
      'sunkCost': 'O que se gastou está gasto; só se decide sobre o que resta',
      'conjunction':
          'O pormenor torna uma história mais credível e menos provável',
      'conditional': 'O que te disseram muda as probabilidades',
      'independence': 'O acaso não tem memória',
      'coincidence': 'O raro é comum quando há muitas tentativas',
      'exponential': 'Ninguém tem intuição para o que duplica',
      'reflection': 'A resposta que chega primeiro é a que deves verificar',
      'simpson': 'Um todo pode pender para onde nenhuma parte pende',
      'estimation':
          'Parte o impossível de responder em coisas que consegues estimar',
      'computation': 'Um problema que consegues mesmo acabar',
      'other': '$move',
    });
    return '$_temp0';
  }

  @override
  String purposeMoveAsk(String move) {
    String _temp0 = intl.Intl.selectLogic(move, {
      'baseRate': 'Quão comum era à partida?',
      'survivorship': 'O que nunca chegou aos dados?',
      'regression': 'É só um extremo a voltar ao normal?',
      'confirmation': 'O que provaria que me engano?',
      'anchoring': 'Que número veio primeiro?',
      'sampling': 'Quem foi contado?',
      'confounding': 'Que outra coisa poderia causar as duas?',
      'counterfactual': 'Comparado com quê?',
      'multipleComparisons': 'Quantas coisas se experimentaram?',
      'availability': 'É comum, ou só fácil de imaginar?',
      'sunkCost': 'O que falta decidir a partir daqui?',
      'conjunction': 'Cada pormenor torna-o menos provável?',
      'conditional': 'O que muda saber isso?',
      'independence': 'O último resultado muda o próximo?',
      'coincidence': 'Quantas oportunidades houve?',
      'exponential': 'O que acontece quando volta a duplicar?',
      'reflection': 'A primeira resposta é a certa?',
      'simpson': 'Todas as partes pendem para o mesmo lado?',
      'estimation': 'O que posso estimar pelo caminho?',
      'computation': 'Consigo calculá-lo passo a passo?',
      'other': '$move',
    });
    return '$_temp0';
  }

  @override
  String get purposeStepAbove => 'Um degrau acima';

  @override
  String get purposeStepAboveLine => 'Mais difícil do que costumas ler';

  @override
  String purposeThinTitle(String subject) {
    return 'O que menos lês: $subject';
  }

  @override
  String purposeThinLine(int percent, String subject) {
    return 'Leste $percent% de $subject, o que menos leste';
  }

  @override
  String get purposeOtherSide => 'O outro lado';

  @override
  String get purposeOtherSideLine =>
      'Escolheste um lado. Eis o melhor argumento contra';

  @override
  String purposeYouSaid(String side) {
    return 'Disseste $side';
  }

  @override
  String purposeCaseFor(String side) {
    return 'As razões do «$side»';
  }

  @override
  String get purposeMechanism => 'O mecanismo';

  @override
  String purposeMovingUpdated(String date) {
    return 'Atualizado a $date';
  }

  @override
  String get purposeMovingYears => 'Pode mudar daqui a uns anos';

  @override
  String get purposeMovingMonths => 'Pode mudar ainda este ano';

  @override
  String get purposeWhy => 'Ah, então é por isso';

  @override
  String get purposeWhyLine => 'Um mecanismo, explicado até fazer clique';

  @override
  String purposeWhyBand(int n) {
    return 'O porquê · $n min';
  }

  @override
  String get purposeMe => 'Sou eu';

  @override
  String get purposeMeLine => 'Coisas que fazes sem reparar';

  @override
  String get purposeMeFooter => 'Marca as cartas em que te reconheces.';

  @override
  String purposeMeMarked(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n cartas marcadas com «Sou eu».',
      one: 'Uma carta marcada com «Sou eu».',
    );
    return '$_temp0';
  }

  @override
  String get purposeAboutYou => 'Novo para mim, e sobre mim';

  @override
  String get purposeAboutYouLine =>
      'O teu corpo, a tua saúde, as tuas probabilidades';

  @override
  String get purposeHeadline => 'Num título';

  @override
  String get purposeHeadlineLine =>
      'Estudos e afirmações que soam melhor do que são';

  @override
  String get purposeTheClaim => 'A afirmação';

  @override
  String get purposeNumber => 'Num número';

  @override
  String get purposeNumberLine =>
      'Probabilidades e percentagens que pedem um segundo olhar';

  @override
  String get purposeOutOfWhat => 'De quantos?';

  @override
  String get purposeOffer => 'Numa oferta';

  @override
  String get purposeOfferLine => 'Preços, negócios e quem paga mesmo';

  @override
  String get purposeArgument => 'Numa discussão';

  @override
  String get purposeArgumentLine => 'Onde o raciocínio escorrega';

  @override
  String purposeKeepHeading(String n) {
    String _temp0 = intl.Intl.selectLogic(n, {
      '1': 'Uma pergunta que desmascara quase tudo isto',
      '2': 'Duas perguntas que desmascaram quase tudo isto',
      '3': 'Três perguntas que desmascaram quase tudo isto',
      '4': 'Quatro perguntas que desmascaram quase tudo isto',
      '5': 'Cinco perguntas que desmascaram quase tudo isto',
      'other': '$n perguntas que desmascaram quase tudo isto',
    });
    return '$_temp0';
  }

  @override
  String purposeLifeAbout(String topic) {
    String _temp0 = intl.Intl.selectLogic(topic, {
      'money': 'Dinheiro',
      'work': 'Trabalho e tempo',
      'clock': 'Tempo',
      'body': 'O teu corpo',
      'relationships': 'Relações',
      'belief': 'Aquilo em que acreditas',
      'other': '$topic',
    });
    return '$_temp0';
  }

  @override
  String purposeLifeQuestion(String topic) {
    String _temp0 = intl.Intl.selectLogic(topic, {
      'money': 'Estou a pagar pelo que uso mesmo?',
      'work': 'O que tornaria amanhã mais fácil de começar?',
      'clock': 'Para onde vai mesmo o meu tempo?',
      'body': 'O que sei sobre o meu corpo ainda é verdade?',
      'relationships': 'De que precisam mesmo as pessoas próximas de mim?',
      'belief': 'Até que ponto tenho a certeza, e porquê?',
      'other': '$topic',
    });
    return '$_temp0';
  }

  @override
  String purposeLifeChip(String topic) {
    String _temp0 = intl.Intl.selectLogic(topic, {
      'money': 'Dinheiro',
      'work': 'Trabalho',
      'clock': 'Tempo',
      'body': 'Corpo',
      'relationships': 'Relações',
      'belief': 'Aquilo em que acredito',
      'other': '$topic',
    });
    return '$_temp0';
  }

  @override
  String get purposeLifeAsk => 'Sobre o que queres melhores perguntas?';

  @override
  String get purposeLifeFooter =>
      'Escolhe os que quiseres e as cartas sobre isso aparecem aqui.';

  @override
  String get purposeSpotTrick => 'Descobre o truque';

  @override
  String get purposeSpotTrickLine => 'Que pergunta o desmascararia?';

  @override
  String get purposePlayed => 'O que jogaste hoje';

  @override
  String get purposePlayedOff => 'pontos de desvio, em média';

  @override
  String get purposePlayedTricks => 'truques descobertos';

  @override
  String get purposePlayedAnswered => 'respondidas numa estante';

  @override
  String get purposePlayedFooter =>
      'As respostas dadas numa estante contam em «A tua viagem», como as de Hoje.';

  @override
  String purposeOf(int n, int of) {
    return '$n de $of';
  }

  @override
  String purposeSetRead(int n, int of) {
    return '$n de $of lidas';
  }

  @override
  String purposeSetDone(int n) {
    return 'Lidas as $n. Quando a estante voltar, juntam-se novas.';
  }

  @override
  String get purposeComplete => 'Completa';

  @override
  String get purposeStampsFooter => 'Cada carta que lês acrescenta o seu selo.';

  @override
  String get purposeSets => 'As tuas coleções';

  @override
  String get purposeSetsLine =>
      'Ler conta. Não precisas de responder para completar uma coleção.';

  @override
  String get purposeTomorrow => 'Amanhã nas estantes';

  @override
  String get purposeTomorrowLine =>
      'As estantes mudam todos os dias. Estas vêm a seguir';

  @override
  String get purposeEnd => 'Chegaste ao fim de Explorar';

  @override
  String get purposeEndLine => 'Até amanhã';

  @override
  String get betsRangeTitle => 'Aposta num intervalo';

  @override
  String get betsRangeLine => 'Quanto mais estreito, mais paga, se acertares';

  @override
  String betsRangeWidth(int w, int pts) {
    return '±$w · $pts pts';
  }

  @override
  String get betsBet => 'Apostar';

  @override
  String betsInRange(int pts, String said) {
    return 'Dentro: +$pts pontos. É $said.';
  }

  @override
  String betsMissedRange(String said) {
    return 'Falhaste: é $said.';
  }

  @override
  String get betsYourGuess => 'O teu palpite';

  @override
  String get betsAnsweredAlready => 'Já respondida';

  @override
  String get betsOpenCard => 'Abrir a carta';

  @override
  String betsWalletSays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Restam-te $n pontos hoje',
      one: 'Resta-te 1 ponto hoje',
      zero: 'Restam-te $n pontos hoje',
    );
    return '$_temp0';
  }

  @override
  String get betsSlipTitle => 'O teu boletim';

  @override
  String betsSlipToday(String points) {
    return '$points hoje';
  }

  @override
  String get betsSlipEmpty =>
      'Ainda não há apostas. Cada uma que fizeres aparece aqui.';

  @override
  String get betsSlipTipTwice =>
      'Vai estreito quando tens a certeza: paga o dobro.';

  @override
  String get betsSlipTipThrice =>
      'Vai estreito quando tens a certeza: paga o triplo.';

  @override
  String betsSlipTipTimes(int times) {
    String _temp0 = intl.Intl.pluralLogic(
      times,
      locale: localeName,
      other: 'Vai estreito quando tens a certeza: paga $times vezes mais.',
    );
    return '$_temp0';
  }

  @override
  String betsSlipNarrow(int right, int n) {
    return 'Apostas estreitas certas: $right de $n.';
  }

  @override
  String betsSlipSure(int right, int n, int pct) {
    return 'Acertaste $right de $n, com $pct% de certeza em média.';
  }

  @override
  String get betsRight => 'Certo';

  @override
  String get betsWrong => 'Errado';

  @override
  String betsOneIn(String n) {
    return '1 em $n';
  }

  @override
  String get betsOneInLabel => '1 em';

  @override
  String betsScore(int right, int steps) {
    return '$right de $steps';
  }

  @override
  String betsScoreSentence(int right, int steps) {
    return 'Acertaste $right de $steps.';
  }

  @override
  String get betsStakeTitle => 'Faz a tua aposta';

  @override
  String betsStakeLine(int points) {
    return '$points pontos por dia. Se ganhares, duplicas a aposta';
  }

  @override
  String get betsStakeLabel => 'Aposta';

  @override
  String betsBetN(int n) {
    return 'Apostar $n';
  }

  @override
  String get betsPickFirst => 'Escolhe uma primeiro';

  @override
  String get betsNotEnough => 'Pontos insuficientes';

  @override
  String betsWin(int n) {
    return 'Ganhas $n.';
  }

  @override
  String betsLose(int n) {
    return 'Perdes $n.';
  }

  @override
  String betsYouWereSure(int pct) {
    return 'Estavas $pct% seguro.';
  }

  @override
  String get betsFriendTitle => 'Aposta com um amigo';

  @override
  String get betsFriendLine =>
      'Envia uma pergunta e depois comparem os palpites';

  @override
  String get betsFriendNote =>
      'O teu palpite fica no teu telemóvel. A carta vai com a resposta, por isso pede primeiro o palpite do teu amigo.';

  @override
  String betsFriendNoteSaid(String said) {
    return 'Disseste $said. A carta vai com a resposta, por isso pede primeiro o palpite do teu amigo.';
  }

  @override
  String get betsFriendSend => 'Enviar a um amigo';

  @override
  String get betsFriendCopy => 'Copiar a pergunta';

  @override
  String get betsFriendCopied => 'Pergunta copiada';

  @override
  String get betsFriendAsk => 'E tu, o que dizes?';

  @override
  String get betsNumberTitle => 'O teu número';

  @override
  String get betsNumberLine => 'Acerta-o, fixa-o e vê por quanto falhaste';

  @override
  String get betsLock => 'Confirmar';

  @override
  String get betsSpotOn => 'Certeiro.';

  @override
  String betsCloseEnough(String by) {
    return 'Perto o suficiente: falhaste por $by.';
  }

  @override
  String betsOffBy(String by) {
    return 'Falhaste por $by.';
  }

  @override
  String get betsYou => 'tu';

  @override
  String get betsAnswer => 'resposta';

  @override
  String get betsBiggerTitle => 'Qual é maior?';

  @override
  String get betsBiggerLine => 'Dois números que podes calcular. Toca no maior';

  @override
  String get betsTapIfBigger => 'Toca se for maior';

  @override
  String get betsBiggerGotIt => 'Maior · acertaste';

  @override
  String get betsBigger => 'Maior';

  @override
  String get betsYourPick => 'A tua escolha';

  @override
  String get betsOr => 'ou';

  @override
  String get betsBiggerFoot =>
      'Cada número é a resposta de uma carta. Depois de escolheres, toca num para abrir a carta dele.';

  @override
  String betsBiggerScore(int right, int n) {
    return 'Acertaste $right de $n.';
  }

  @override
  String get betsCloserTitle => 'Cada vez mais perto';

  @override
  String betsCloserLine(String steps) {
    String _temp0 = intl.Intl.selectLogic(steps, {
      '2': 'Dois passos de mais ou menos para chegar ao número',
      '3': 'Três passos de mais ou menos para chegar ao número',
      '4': 'Quatro passos de mais ou menos para chegar ao número',
      '5': 'Cinco passos de mais ou menos para chegar ao número',
      'other': '$steps passos de mais ou menos para chegar ao número',
    });
    return '$_temp0';
  }

  @override
  String betsCloserStart(String steps) {
    String _temp0 = intl.Intl.selectLogic(steps, {
      '2': 'Dois passos para lá chegar.',
      '3': 'Três passos para lá chegar.',
      '4': 'Quatro passos para lá chegar.',
      '5': 'Cinco passos para lá chegar.',
      'other': '$steps passos para lá chegar.',
    });
    return '$_temp0';
  }

  @override
  String betsMoreOrLess(String v) {
    return 'Mais ou menos de $v?';
  }

  @override
  String betsStepOf(int at, int of) {
    return 'Passo $at de $of';
  }

  @override
  String get betsMore => 'Mais';

  @override
  String get betsLess => 'Menos';

  @override
  String betsCloserYesMore(String v) {
    return 'Certo: é mais de $v.';
  }

  @override
  String betsCloserYesLess(String v) {
    return 'Certo: é menos de $v.';
  }

  @override
  String betsCloserNoMore(String v) {
    return 'Errado: é mais de $v.';
  }

  @override
  String betsCloserNoLess(String v) {
    return 'Errado: é menos de $v.';
  }

  @override
  String betsCloserExact(String said) {
    return 'É exatamente $said.';
  }

  @override
  String betsCloserDone(String said, int right, int steps) {
    return 'É $said. Acertaste $right de $steps.';
  }

  @override
  String get betsMagnitudeTitle => 'Ordens de grandeza';

  @override
  String get betsMagnitudeLine => 'Dez, mil ou um milhão? Escolhe o tamanho';

  @override
  String get betsMagnitudeRight => 'Ordem de grandeza certa.';

  @override
  String betsMagnitudeOff(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Falhaste por $n ordens de grandeza.',
      one: 'Falhaste por 1 ordem de grandeza.',
      zero: 'Falhaste por $n ordens de grandeza.',
    );
    return '$_temp0';
  }

  @override
  String get betsDayTitle => 'A aposta do dia';

  @override
  String get betsDayLine => 'Confirma o teu palpite e vê por quanto falhaste';

  @override
  String get betsDayTag => 'Aposta do dia';

  @override
  String get betsDayTagSame => 'Aposta do dia · a mesma para todos';

  @override
  String get betsLockIn => 'Confirmar';

  @override
  String betsItIs(String said) {
    return 'É $said.';
  }

  @override
  String betsPointsOff(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Falhaste por $n pontos percentuais.',
      one: 'Falhaste por 1 ponto percentual.',
      zero: 'Certeiro.',
    );
    return '$_temp0';
  }

  @override
  String screensQuoted(String text) {
    return '«$text»';
  }

  @override
  String get screensExpertTitle => 'Pensa como um especialista';

  @override
  String get screensExpertLine =>
      'A pergunta que cada um deles faz sempre, e as cartas que precisam dela';

  @override
  String get screensExpertStatistician => 'Estatístico';

  @override
  String get screensExpertStatisticianAs => 'Pensa como um estatístico';

  @override
  String get screensExpertStatisticianAsks =>
      'Comparado com quê, e em quantos?';

  @override
  String get screensExpertEconomist => 'Economista';

  @override
  String get screensExpertEconomistAs => 'Pensa como um economista';

  @override
  String get screensExpertEconomistAsks => 'Quem paga, e do que abdica?';

  @override
  String get screensExpertHistorian => 'Historiador';

  @override
  String get screensExpertHistorianAs => 'Pensa como um historiador';

  @override
  String get screensExpertHistorianAsks => 'O que se sabia na altura?';

  @override
  String get screensExpertDoctor => 'Médico';

  @override
  String get screensExpertDoctorAs => 'Pensa como um médico';

  @override
  String get screensExpertDoctorAsks => 'Quão comum é, e que mais poderá ser?';

  @override
  String get screensExpertScientist => 'Cientista';

  @override
  String get screensExpertScientistAs => 'Pensa como um cientista';

  @override
  String get screensExpertScientistAsks =>
      'Como saberíamos se estivesse errado?';

  @override
  String get screensDotsTitle => 'Liga os pontos';

  @override
  String get screensDotsLine =>
      'Escolhe um tema para ver onde se cruza com os outros';

  @override
  String screensDotsMeets(int subjects, int cards) {
    String _temp0 = intl.Intl.pluralLogic(
      subjects,
      locale: localeName,
      other: 'Cruza-se com $subjects temas',
      one: 'Cruza-se com 1 tema',
      zero: 'Cruza-se com $subjects temas',
    );
    String _temp1 = intl.Intl.pluralLogic(
      cards,
      locale: localeName,
      other: 'em $cards cartas',
      one: 'em 1 carta',
      zero: 'em $cards cartas',
    );
    return '$_temp0 $_temp1';
  }

  @override
  String get screensDotsWhere => 'Onde se cruzam';

  @override
  String get screensDotsWhereLine => 'Uma pergunta, duas maneiras de a ver';

  @override
  String get screensAskTitle => 'O que queres perceber?';

  @override
  String get screensAskHint =>
      'Pergunta o que quiseres, ou escreve uma palavra';

  @override
  String get screensAskTry => 'Experimenta';

  @override
  String get screensAskClear => 'Apagar a pergunta';

  @override
  String screensAskFound(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n cartas respondem',
      one: '1 carta responde',
      zero: '$n cartas respondem',
    );
    return '$_temp0';
  }

  @override
  String get screensAskNone => 'Ainda não há cartas sobre isso';

  @override
  String get screensAskNoneLine =>
      'Guarda a pergunta. Quando uma carta lhe responder, vai estar aqui, por baixo da pergunta.';

  @override
  String get screensAskKeep => 'Guardar a pergunta';

  @override
  String get screensAskKept => 'Guardada';

  @override
  String get screensAskedTitle => 'As perguntas que fizeste';

  @override
  String get screensAskedLine => 'E as cartas que lhes responderam';

  @override
  String get screensAskedAnswered => 'A resposta';

  @override
  String get screensAskedWaiting =>
      'Ainda nenhuma carta lhe responde. Quando houver uma, vai estar aqui.';

  @override
  String get screensAskedForget => 'Esquecer esta pergunta';

  @override
  String get screensAskedForgotten => 'Pergunta esquecida';

  @override
  String get screensWhyTitle => 'Continua a perguntar porquê';

  @override
  String get screensWhyLine => 'Cada resposta levanta a pergunta seguinte';

  @override
  String get screensWhyAsk => 'Porquê?';

  @override
  String screensWhyBottom(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n porquês de profundidade.',
      one: '1 porquê de profundidade.',
      zero: '$n porquês de profundidade.',
    );
    return '$_temp0 Mais fundo não dá.';
  }

  @override
  String get screensWhyAgain => 'Recomeçar';

  @override
  String get screensWhyHoles => 'Mais tocas de coelho';

  @override
  String get screensWhyHolesLine => 'Cada uma desce uns quantos porquês';

  @override
  String screensWhyCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n porquês',
      one: '1 porquê',
      zero: '$n porquês',
    );
    return '$_temp0';
  }

  @override
  String get screensWhyDeeper => 'Ir mais fundo';

  @override
  String screensWhySource(String source) {
    return 'Fonte: $source';
  }

  @override
  String screensWhyDepth(int at, int of) {
    String _temp0 = intl.Intl.pluralLogic(
      at,
      locale: localeName,
      other: '$at porquês',
      one: '1 porquê',
      zero: '$at porquês',
    );
    return '$_temp0 de $of';
  }

  @override
  String get screensTimeTitle => 'Através do tempo';

  @override
  String get screensTimeLine =>
      'Uma época de cada vez, até este ano. Arrasta para viajar';

  @override
  String get screensTimeCaption =>
      'Anos atrás. Cada traço recua dez vezes mais.';

  @override
  String get screensTimeNow => 'Hoje';

  @override
  String get screensTimeEarlier => 'Mais atrás';

  @override
  String get screensTimeLater => 'Mais perto de hoje';

  @override
  String get screensEraAncient => 'O mundo antigo';

  @override
  String get screensEraAncientWhen => 'Antes de 500';

  @override
  String get screensEraMedieval => 'A Idade Média';

  @override
  String get screensEraMedievalWhen => 'De 500 a 1500';

  @override
  String get screensEraEarlyModern => 'A Idade Moderna';

  @override
  String get screensEraEarlyModernWhen => 'De 1500 a 1800';

  @override
  String get screensEraNineteenth => 'O século XIX';

  @override
  String get screensEraNineteenthWhen => 'De 1800 a 1900';

  @override
  String get screensEraTwentieth => 'O século passado';

  @override
  String get screensEraTwentiethWhen => 'De 1900 a 2000';

  @override
  String get screensEraRecent => 'Este século';

  @override
  String get screensEraRecentWhen => 'Desde 2000';

  @override
  String get screensMindTitle => 'Muda de ideias';

  @override
  String get screensMindLine =>
      'Diz o que pensas antes de ler, e outra vez depois';

  @override
  String get screensMindClaim => 'Afirmação';

  @override
  String get screensMindBefore => 'Antes de ler';

  @override
  String get screensMindTap => 'Toca onde te situas';

  @override
  String get screensMindKnow => 'O que sabemos';

  @override
  String get screensMindNow => 'E agora?';

  @override
  String get screensMindAgain => 'Toca outra vez';

  @override
  String screensMindLevel(String level) {
    String _temp0 = intl.Intl.selectLogic(level, {
      '0': 'Discordo totalmente',
      '1': 'Discordo',
      '2': 'Não sei',
      '3': 'Concordo',
      'other': 'Concordo totalmente',
    });
    return '$_temp0';
  }

  @override
  String screensMindToward(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Deste $n passos em direção às provas.',
      one: 'Deste 1 passo em direção às provas.',
      zero: 'Deste $n passos em direção às provas.',
    );
    return '$_temp0';
  }

  @override
  String get screensMindSame => 'Igual a antes. Uma carta é só uma carta.';

  @override
  String get screensMindAlready =>
      'Já estavas do lado das provas antes de as leres.';

  @override
  String get screensMindAway =>
      'Afastaste-te das provas. Vale uma segunda leitura.';

  @override
  String get screensMindFirst =>
      'Primeiro diz o que pensas. Um toque, antes de ler.';

  @override
  String screensMindChanged(int changed, int total) {
    return 'Mudaste de ideias em $changed de $total.';
  }

  @override
  String get screensMindFoot =>
      'Uma ideia que muda é uma carta que fez o seu trabalho.';

  @override
  String get screensSayTitle => 'Diz isto hoje à noite';

  @override
  String get screensSayLine =>
      'Uma frase para levar ao jantar. Toca quando a disseres';

  @override
  String get screensSayTonight => 'A frase desta noite';

  @override
  String get screensSaySaid => 'Já a disse';

  @override
  String get screensSayDone => 'Dita';

  @override
  String screensSayWeek(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Disseste $n frases esta semana.',
      one: 'Disseste 1 frase esta semana.',
      zero: 'Ainda nada dito esta semana.',
    );
    return '$_temp0';
  }

  @override
  String get screensSayCounts =>
      'Cada frase que dizes também conta para o Top da semana.';

  @override
  String get screensFrontName => 'The Astute';

  @override
  String get screensFrontEdition => 'Edição de hoje';

  @override
  String get screensFrontSame => 'Igual para todos';

  @override
  String get screensFrontLead => 'Manchete';

  @override
  String get screensFrontNumbers => 'Em números';

  @override
  String get screensFrontCorrections => 'Correções';

  @override
  String get screensFrontPuzzle => 'O enigma do dia';

  @override
  String get screensFrontEnd => 'Esta é a edição de hoje';

  @override
  String get screensFrontTomorrow => 'A de amanhã sai de manhã';

  @override
  String exploreDayRead(int read, int of) {
    return 'Hoje: $read de $of lidas';
  }

  @override
  String exploreDayLeft(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'faltam $n',
      one: 'falta 1',
      zero: 'faltam $n',
    );
    return '$_temp0';
  }

  @override
  String get exploreDayDone => 'todas lidas';

  @override
  String get exploreDayOpen => 'Ir para as cartas de hoje';

  @override
  String get exploreGameNone =>
      'Agora não há nada para jogar aqui. Volta amanhã.';

  @override
  String get challengesTitle => 'Desafios';

  @override
  String get challengesLine =>
      'Exercícios breves de juízo e estimativa, de poucos minutos cada.';

  @override
  String challengesPage(int n, int of) {
    return 'Página $n de $of';
  }

  @override
  String get gamePlay => 'Começar';

  @override
  String get sixtyRules =>
      'Oito afirmações, verdadeiras ou falsas, num minuto. Mede o teu juízo sob pressa, que é como julgamos quase tudo o que lemos.';

  @override
  String get sixtyReview => 'As oito afirmações';

  @override
  String get gameRight => 'Certo';

  @override
  String get gameWrong => 'Errado';

  @override
  String get gameUnanswered => 'Sem resposta';

  @override
  String get gameNext => 'Próximo desafio';

  @override
  String sixtyShareHead(String date) {
    return 'Astute · Sessenta segundos · $date';
  }

  @override
  String sixtyShareScore(int n, int of, int s) {
    return '$n de $of certas · $s s';
  }

  @override
  String sixtySecondsLeftLabel(int s) {
    String _temp0 = intl.Intl.pluralLogic(
      s,
      locale: localeName,
      other: 'Faltam $s segundos',
      one: 'Falta 1 segundo',
      zero: 'Faltam $s segundos',
    );
    return '$_temp0';
  }

  @override
  String get gameReview => 'As cartas';

  @override
  String get gameTomorrow => 'Nova ronda amanhã';

  @override
  String get gameContinue => 'Continuar';

  @override
  String gameShareHead(String game, String date) {
    return 'Astute · $game · $date';
  }

  @override
  String gameShareScore(int n, int of) {
    return 'Pontuação: $n de $of';
  }

  @override
  String gameCardsToday(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n cartas hoje',
      one: '1 carta hoje',
      zero: '$n cartas hoje',
    );
    return '$_temp0';
  }

  @override
  String get gameAllRight => 'Todas certas.';

  @override
  String gamePoints(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n pontos',
      one: '1 ponto',
      zero: '$n pontos',
    );
    return '$_temp0';
  }

  @override
  String get gameSeeResult => 'Ver como correu';

  @override
  String get gameNextCard => 'Seguinte';

  @override
  String get spotOnce => 'Uma escolha por dia';

  @override
  String get spotGotIt => 'Encontraste a falsa.';

  @override
  String get spotMissedIt => 'Essa não: é verdadeira.';

  @override
  String get tfRules =>
      'Afirmações em que a maioria erra. Diz verdadeiro ou falso e depois lê porquê. Mede o juízo: distinguir o que é verdade do que só parece óbvio.';

  @override
  String get inOrderTitle => 'Por ordem';

  @override
  String get inOrderRules =>
      'Quatro momentos das cartas, sem o ano, para pôr pela ordem em que aconteceram. Mede o teu sentido de cronologia, a primeira prova de qualquer explicação: uma causa vem antes do seu efeito.';

  @override
  String get inOrderFirst => 'Toca no momento que veio primeiro.';

  @override
  String get inOrderNext => 'Agora no que veio a seguir.';

  @override
  String get inOrderReady => 'Tudo no lugar.';

  @override
  String get inOrderCheck => 'Verificar a ordem';

  @override
  String inOrderPlaced(int n) {
    return 'Na posição $n';
  }

  @override
  String inOrderYours(int n) {
    return 'A tua posição: $n';
  }

  @override
  String get inOrderPerfect => 'Tudo no sítio certo.';

  @override
  String get timeGap => 'um ano em falta';

  @override
  String get whatYearTitle => 'Que ano?';

  @override
  String get whatYearRules =>
      'Três momentos, sem o ano. Marca o ano de cada um: quanto mais perto, mais pontos, até dez. Mede o teu sentido de quando as coisas aconteceram.';

  @override
  String whatYearPoints(int n, int of) {
    return '$n de $of pontos';
  }

  @override
  String get whatYearPerfect => 'Todos os anos certinhos.';

  @override
  String whatYearOffInAll(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n anos de diferença no total.',
      one: '1 ano de diferença no total.',
      zero: '$n anos de diferença no total.',
    );
    return '$_temp0';
  }

  @override
  String whatYearSaid(String guess, int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: 'Disseste $guess · $points pontos',
      one: 'Disseste $guess · 1 ponto',
    );
    return '$_temp0';
  }

  @override
  String whatYearOff(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n anos de diferença',
      one: '1 ano de diferença',
      zero: '$n anos de diferença',
    );
    return '$_temp0';
  }

  @override
  String whatYearEarlier(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n anos antes',
      one: '1 ano antes',
      zero: '$n anos antes',
    );
    return '$_temp0';
  }

  @override
  String whatYearLater(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n anos depois',
      one: '1 ano depois',
      zero: '$n anos depois',
    );
    return '$_temp0';
  }

  @override
  String get whatYearDial => 'Ano';

  @override
  String get beforeAfterTitle => 'Antes ou depois?';

  @override
  String get beforeAfterRules =>
      'Seis momentos, um a seguir ao outro. Diz se cada um aconteceu antes ou depois do de cima. Mede o teu sentido de sequência.';

  @override
  String get beforeAfterBefore => 'Antes';

  @override
  String get beforeAfterAfter => 'Depois';

  @override
  String beforeAfterAsk(String year) {
    return 'Antes ou depois de $year?';
  }

  @override
  String beforeAfterSaidBefore(String year) {
    return 'Disseste: antes de $year';
  }

  @override
  String beforeAfterSaidAfter(String year) {
    return 'Disseste: depois de $year';
  }

  @override
  String get beforeAfterStart => 'Foi aqui que começou';

  @override
  String get beforeAfterPerfect => 'Nem um fora do sítio.';

  @override
  String biggerPairsToday(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n pares hoje',
      one: '1 par hoje',
      zero: '$n pares hoje',
    );
    return '$_temp0';
  }

  @override
  String get sixtySkill => 'Intuição';

  @override
  String get spotSkill => 'Discernimento';

  @override
  String get tfSkill => 'Juízo';

  @override
  String get biggerSkill => 'Proporção';

  @override
  String get closerSkill => 'Estimativa';

  @override
  String get magnitudeSkill => 'Escala';

  @override
  String get rangeSkill => 'Calibração';

  @override
  String get stakeSkill => 'Convicção';

  @override
  String get numberSkill => 'Precisão';

  @override
  String get inOrderSkill => 'Cronologia';

  @override
  String get whatYearSkill => 'Datação';

  @override
  String get beforeAfterSkill => 'Sequência';

  @override
  String get sixtyAsks => 'Oito afirmações contra o relógio.';

  @override
  String get spotAsks => 'Quatro afirmações, uma delas falsa.';

  @override
  String get tfAsks => 'Afirmações em que quase todos erram.';

  @override
  String get biggerAsks => 'Dois números. Qual é maior?';

  @override
  String get closerAsks => 'Aproxima-te de um número, passo a passo.';

  @override
  String get magnitudeAsks => 'Encontra a potência de dez certa.';

  @override
  String get rangeAsks => 'Um intervalo com a largura certa.';

  @override
  String get stakeAsks => 'Aposta pontos conforme a tua certeza.';

  @override
  String get numberAsks => 'Compromete-te com um só número.';

  @override
  String get inOrderAsks => 'Quatro momentos, do mais antigo.';

  @override
  String get whatYearAsks => 'Situa um momento no seu ano.';

  @override
  String get beforeAfterAsks => 'Cada momento face ao anterior.';

  @override
  String get challengeBest => 'Recorde';

  @override
  String get challengeToday => 'Hoje';

  @override
  String get challengeAccuracy => 'Acerto';

  @override
  String get challengeTime => 'Tempo';

  @override
  String challengeSeconds(int s) {
    return '$s s';
  }

  @override
  String get challengePersonalBest => 'Recorde pessoal';

  @override
  String challengeAboveChance(int n, int of) {
    return 'Acima do acaso: só a adivinhar acerta-se em média $n de $of.';
  }

  @override
  String challengeAtChance(int n, int of) {
    return 'Ao nível do acaso: só a adivinhar acerta-se em média $n de $of.';
  }

  @override
  String challengeBelowChance(int n, int of) {
    return 'Abaixo do acaso: só a adivinhar acerta-se em média $n de $of.';
  }

  @override
  String sixtyUnanswered(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'O tempo acabou com $n afirmações sem resposta.',
      one: 'O tempo acabou com uma afirmação sem resposta.',
    );
    return '$_temp0';
  }

  @override
  String get challengeAgain => 'Repetir';

  @override
  String get spotRules =>
      'Quatro afirmações: três são verdadeiras e uma é falsa. Encontra a falsa. Mede o quão bem distingues uma afirmação fundada de uma que só parece certa.';

  @override
  String get spotAsk => 'Toca na afirmação que achas que é falsa.';

  @override
  String get biggerRules =>
      'Dois números, cada um a resposta à pergunta de uma carta. Toca no que achas que é maior. Mede o teu sentido de proporção.';

  @override
  String get biggerAsk => 'Toca na carta cuja resposta é maior.';

  @override
  String biggerRight(String big, String small) {
    return 'Certo: $big é mais do que $small.';
  }

  @override
  String biggerWrong(String big, String small) {
    return 'Errado: $big é mais do que $small.';
  }

  @override
  String get closerRules =>
      'Aproxima-te de uma percentagem passo a passo: de cada vez, diz se está acima ou abaixo do meio do que resta. Mede a tua capacidade de estimativa.';

  @override
  String closerDoneSteps(String said, int right, int steps) {
    return 'É $said: acertaste $right de $steps passos.';
  }

  @override
  String closerExactSteps(String said, int right, int steps) {
    return 'É exatamente $said: acertaste $right de $steps passos.';
  }

  @override
  String closerStepsRight(int right, int steps) {
    return 'Acertaste $right de $steps passos.';
  }

  @override
  String get magnitudeRules =>
      'Dez, mil ou um milhão? Escolhe a potência de dez mais próxima da resposta. Mede o teu sentido de escala, que conta mais do que os algarismos exatos.';

  @override
  String get rangeRules =>
      'Fixa a tua estimativa e depois um intervalo à volta: quanto mais estreito, mais paga se a resposta cair dentro. Mede a calibração: saber quanto sabes.';

  @override
  String rangeOption(int w, int pts) {
    return '±$w · paga $pts';
  }

  @override
  String rangeIn(String said, int pts) {
    String _temp0 = intl.Intl.pluralLogic(
      pts,
      locale: localeName,
      other: 'É $said: dentro do teu intervalo, +$pts pontos.',
      one: 'É $said: dentro do teu intervalo, +1 ponto.',
    );
    return '$_temp0';
  }

  @override
  String rangeOut(String said) {
    return 'É $said: fora do teu intervalo.';
  }

  @override
  String stakeRules(int points) {
    return 'Escolhe uma resposta e aposta pontos nela, de $points por dia: se acertares, a aposta duplica; se não, perde-la. Mede a convicção: apostar no que sabes, e só nisso.';
  }

  @override
  String stakeWon(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Certo: ganhas $n pontos.',
      one: 'Certo: ganhas 1 ponto.',
      zero: 'Certo: ganhas $n pontos.',
    );
    return '$_temp0';
  }

  @override
  String stakeLost(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Errado: perdes $n pontos.',
      one: 'Errado: perdes 1 ponto.',
      zero: 'Errado: perdes $n pontos.',
    );
    return '$_temp0';
  }

  @override
  String get numberRules =>
      'Define um único número com os botões e fixa-o. Mede a precisão: quão perto chegas quando tens de te comprometer com um número.';

  @override
  String tfRightIs(String side) {
    String _temp0 = intl.Intl.selectLogic(side, {
      'true': 'Certo: é verdadeiro.',
      'other': 'Certo: é falso.',
    });
    return '$_temp0';
  }

  @override
  String tfWrongIs(String side) {
    String _temp0 = intl.Intl.selectLogic(side, {
      'true': 'Errado: é verdadeiro.',
      'other': 'Errado: é falso.',
    });
    return '$_temp0';
  }

  @override
  String inOrderTold(int n, int of) {
    return '$n de $of no lugar certo.';
  }

  @override
  String get whatYearYours => 'O teu ano';

  @override
  String get whatYearExactly => 'O ano exato';

  @override
  String beforeAfterRight(String side, String year, String above) {
    String _temp0 = intl.Intl.selectLogic(side, {
      'before': 'Certo: foi em $year, antes de $above.',
      'other': 'Certo: foi em $year, depois de $above.',
    });
    return '$_temp0';
  }

  @override
  String beforeAfterWrong(String side, String year, String above) {
    String _temp0 = intl.Intl.selectLogic(side, {
      'before': 'Errado: foi em $year, antes de $above.',
      'other': 'Errado: foi em $year, depois de $above.',
    });
    return '$_temp0';
  }

  @override
  String get challengeAnswer => 'Resposta';

  @override
  String get challengeYouSaid => 'Disseste';

  @override
  String get challengePoints => 'Pontos';

  @override
  String get challengeThisRound => 'Esta ronda';

  @override
  String get challengeLeftToday => 'Restam hoje';

  @override
  String exploreSubjectLevel(String subject, int n) {
    return '$subject, nível $n';
  }

  @override
  String exploreBecauseSaved(String question) {
    return 'Porque guardaste “$question”';
  }

  @override
  String get todaySeeAgain => 'Ver de novo';

  @override
  String get todaySeeAgainHint =>
      'As cartas de hoje outra vez, em grande, desde a primeira';

  @override
  String get yourFiveFromToday => 'As tuas cinco de hoje';

  @override
  String get dayMomentTitle => 'Dia concluído.';

  @override
  String get dayMomentLater => 'Mais tarde';

  @override
  String get yourDayCard => 'O teu dia';

  @override
  String get tuneTitle => 'Afina a tua mistura';

  @override
  String get tuneEntryLine => 'Quanto de cada tema, e que partes';

  @override
  String get tuneLearned =>
      'Já ajustado pelas cartas de que gostaste e que descartaste. Desliza para mudar.';

  @override
  String get tuneFresh => 'Desliza um tema para ver mais ou menos dele.';

  @override
  String get tuneHowMuch => 'Quanto de cada um';

  @override
  String get tuneInsideLine =>
      'As partes de que mais gostaste vêm primeiro. Toca numa para a saltar, mantém premida para ver o que tem.';

  @override
  String get tuneSave => 'Guardar';

  @override
  String get tuneHoldHint =>
      'Mantém premido um género para abrir os temas lá dentro';

  @override
  String get shareDayTitle => 'Partilha o teu dia';

  @override
  String get shareDayRead => 'Cinco cartas, lidas';

  @override
  String get shareDayTurn => 'Cinco cartas por dia. É a tua vez.';

  @override
  String shareDaySure(int n) {
    return '$n% de certeza';
  }

  @override
  String get shareDayHeadline => 'As cinco de hoje';

  @override
  String get shareFormatCover => 'Capa';

  @override
  String get shareFormatList => 'Lista';

  @override
  String get shareFormatStory => 'Story';

  @override
  String crowdGotRight(int n) {
    return '$n% dos leitores acertaram';
  }

  @override
  String crowdGotWrong(int n) {
    return '$n% dos leitores também erraram';
  }

  @override
  String get challengeFriend => 'Desafia um amigo';

  @override
  String get challengeLine => 'Consegues acertar esta?';

  @override
  String pathFree(int n) {
    return '$n grátis';
  }

  @override
  String pathMoreTitle(int n) {
    return 'Mais $n neste percurso.';
  }

  @override
  String get pathMoreLine =>
      'Cada percurso inteiro, da carta mais fácil à mais difícil, e uma fila nova todas as semanas.';

  @override
  String get pathMoreGo => 'Ler o percurso inteiro';

  @override
  String get paywallPathsTitle => 'Cada percurso, as dez.';

  @override
  String get paywallPathsMark => 'as dez.';

  @override
  String get paywallPathsLine =>
      'Dez cartas sobre um tema, da mais fácil à mais difícil. Percursos novos todas as semanas, e as tuas cinco do dia ao teu nível.';

  @override
  String get widgetAskTitle =>
      'A primeira carta de amanhã, no teu ecrã principal.';

  @override
  String get widgetAskLine =>
      'Uma carta nova todas as manhãs sem abrir a app, e a tua sequência ao lado.';

  @override
  String get widgetAskStepHold =>
      'Toca sem soltar num espaço vazio do ecrã principal.';

  @override
  String get widgetAskStepAppleAdd =>
      'Toca em Editar e depois em Adicionar widget.';

  @override
  String get widgetAskStepApplePick =>
      'Procura a Astute, escolhe um tamanho e toca em Adicionar widget.';

  @override
  String get widgetAskStepAndroidAdd => 'Toca em Widgets.';

  @override
  String get widgetAskStepAndroidPick =>
      'Procura a Astute, toca sem soltar num widget e arrasta-o para o sítio.';

  @override
  String get widgetAskLockScreen =>
      'Também no ecrã bloqueado: toca sem soltar e depois em Personalizar.';

  @override
  String get widgetAskPin => 'Adicionar ao ecrã principal';

  @override
  String get widgetAskGotIt => 'Percebi';

  @override
  String get widgetAskNotNow => 'Agora não';

  @override
  String pathCardOf(int n, int total) {
    return 'Carta $n de $total';
  }

  @override
  String get pathDoorNext => 'Seguinte no percurso';

  @override
  String get shareSendCard => 'Enviar a carta';

  @override
  String get shareAsImage => 'Como imagem';

  @override
  String get shareCopyLink => 'Copiar link';

  @override
  String get shareAnswerNote =>
      'O teu amigo vê primeiro a pergunta. A resposta está a um toque, na página da carta.';

  @override
  String get shareWhichSide => 'De que lado estás?';

  @override
  String get rereadRight => 'Da primeira vez acertaste.';

  @override
  String get rereadWrong => 'Da primeira vez falhaste.';

  @override
  String betsDayShareLine(int off) {
    String _temp0 = intl.Intl.pluralLogic(
      off,
      locale: localeName,
      other: 'falhei por $off pontos',
      one: 'falhei por 1 ponto',
      zero: 'acertei em cheio',
    );
    return 'A aposta do dia no Astute: $_temp0. Fazes melhor?';
  }

  @override
  String get playTheCard => 'Jogar a carta';

  @override
  String get openTheCard => 'Abrir a carta';

  @override
  String get perkPathsTitle => 'Cada percurso, inteiro';

  @override
  String get perkPathsLine =>
      'Dez cartas sobre um tema, da mais fácil à mais difícil. Novos percursos toda semana.';

  @override
  String get journeyStrongest => 'Ponto forte';

  @override
  String get journeyMostMissed => 'O que mais falhas';

  @override
  String journeyRightShare(String pct) {
    return '$pct certas';
  }

  @override
  String get journeyChangedMind => 'Mudaste de ideias';

  @override
  String get journeyNewToYou => 'Novo para ti';

  @override
  String journeyReactedOf(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'de $n cartas que perguntaram',
      one: 'de 1 carta que perguntou',
      zero: 'de $n cartas que perguntaram',
    );
    return '$_temp0';
  }

  @override
  String journeyKnewAlready(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n já sabias',
      one: '1 já sabias',
      zero: '$n já sabias',
    );
    return '$_temp0';
  }

  @override
  String get storyLabTitle => 'O teu percurso, como uma história';

  @override
  String get storyLabNote => 'Versão nova · em teste, só TestFlight';

  @override
  String get storyChapterWeek => 'Esta semana';

  @override
  String get storyChapterWhere => 'Onde estás';

  @override
  String get storyChapterReason => 'Como raciocinas';

  @override
  String get storyChapterPractice => 'Pratica';

  @override
  String get storyChapterStory => 'A tua história';

  @override
  String get journeyChapterKnow => 'O que sabes';

  @override
  String get journeyChapterHabits => 'Os teus hábitos';

  @override
  String get journeyChapterCoach => 'O teu coach';

  @override
  String get coachTeaser =>
      'Todas as semanas, uma nota do teu coach sobre como raciocinas: o que correu bem, a armadilha a evitar, o que experimentar a seguir.';

  @override
  String get coachRead => 'Ler a nota desta semana';

  @override
  String storyHeadlineSure(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Nas respostas dadas com certeza, acertaste $n vezes em 10.',
      one: 'Nas respostas dadas com certeza, acertaste 1 vez em 10.',
      zero: 'Nas respostas dadas com certeza, acertaste $n vezes em 10.',
    );
    return '$_temp0';
  }

  @override
  String get storyBetter => 'Melhor do que na semana passada.';

  @override
  String get storyWorse => 'Um pouco menos do que na semana passada.';

  @override
  String storyHeadlineStreak(int n) {
    return '$n dias seguidos. Não percas o fio.';
  }

  @override
  String storyHeadlineStrong(String subject, String pct) {
    return 'Em $subject acertas $pct das vezes.';
  }

  @override
  String storyHeadlineRead(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n cartas lidas. O percurso começa aqui.',
      one: 'Uma carta lida. O percurso começa aqui.',
      zero: 'A tua primeira carta está à espera.',
    );
    return '$_temp0';
  }

  @override
  String storyHeadlineReadWeek(int n, int week) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n cartas lidas',
      one: 'Uma carta lida',
    );
    String _temp1 = intl.Intl.pluralLogic(
      week,
      locale: localeName,
      other: '$week esta semana.',
      one: 'uma esta semana.',
      zero: 'nenhuma ainda esta semana.',
    );
    return '$_temp0, $_temp1';
  }

  @override
  String storyHeadlineReadAllWeek(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n cartas lidas, todas esta semana.',
      one: 'Uma carta lida até agora.',
    );
    return '$_temp0';
  }

  @override
  String storySaidRight(String sure, String right) {
    return 'A tua certeza: $sure. Acertas $right das vezes.';
  }

  @override
  String storySaidRightToGo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          'Mais $n respostas a dizer quão certo estás, e passa a ser medido.',
      one: 'Mais uma resposta a dizer quão certo estás, e passa a ser medido.',
    );
    return '$_temp0';
  }

  @override
  String storyOverconfident(String subject, int points) {
    return 'Onde confias demais: $subject, por $points pontos.';
  }

  @override
  String get storyUnlock => 'Ver com o Astute+';

  @override
  String storyPracticeMisses(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'As $n que erraste com certeza',
      one: 'A que erraste com certeza',
    );
    return '$_temp0';
  }

  @override
  String storyPracticeChanged(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'As $n que te fizeram mudar de ideias',
      one: 'A carta que te fez mudar de ideias',
    );
    return '$_temp0';
  }

  @override
  String storyPracticeBlind(String subject) {
    return '5 cartas novas de $subject';
  }

  @override
  String get storyPracticeNone =>
      'Ainda nada para praticar: responde a algumas cartas e aparece.';

  @override
  String get storyFirstCard => 'Primeira carta';

  @override
  String storyReached(String level) {
    return 'Alcançado: $level';
  }

  @override
  String storyBestStreak(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Melhor série: $n dias',
      one: 'Melhor série: 1 dia',
      zero: 'Melhor série: $n dias',
    );
    return '$_temp0';
  }

  @override
  String storyCardsRead(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n cartas lidas',
      one: '1 carta lida',
      zero: '$n cartas lidas',
    );
    return '$_temp0';
  }

  @override
  String get storyToday => 'Hoje';

  @override
  String get storySeePath => 'Ver o percurso';

  @override
  String exploreFreshCards(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n cartas novas no topo',
      one: '1 carta nova no topo',
      zero: '$n cartas novas no topo',
    );
    return '$_temp0';
  }

  @override
  String get exploreUpToDate => 'Estás em dia: por agora nada de novo.';

  @override
  String get deeperTitle => 'Aprofundar';

  @override
  String get deeperSimple => 'Explica-me de forma simples';

  @override
  String get deeperWhy => 'Porque importa';

  @override
  String get deeperSides => 'Os dois lados';

  @override
  String get deeperExample => 'Um exemplo do dia a dia';

  @override
  String get deeperQuiz => 'Põe-me à prova com um caso novo';

  @override
  String get deeperQuizRight => 'Certo.';

  @override
  String get deeperQuizWrong => 'Não exatamente.';

  @override
  String get mathsDailySolve => 'Resolve-o';

  @override
  String get mathsDailySolved => 'Resolvido';

  @override
  String get mathsDailyMissed => 'Desta vez não';

  @override
  String get mathsDailyTomorrow => 'Amanhã há outro';

  @override
  String get mathsDailyAnother => 'Outro como este';

  @override
  String goalShelf(String goal) {
    return 'Serve-te para: $goal';
  }

  @override
  String get goalDecide => 'Decisões do dia a dia';

  @override
  String get goalPeople => 'As pessoas';

  @override
  String get goalBusiness => 'Trabalho e negócios';

  @override
  String get goalMoney => 'Dinheiro e compras';

  @override
  String get goalHealth => 'Saúde';

  @override
  String get goalDecideLine =>
      'Escolhas, riscos e probabilidades, sem palpites.';

  @override
  String get goalNews => 'Notícias e redes sociais';

  @override
  String get goalNewsLine => 'Títulos, estatísticas e posts: o que se aguenta.';

  @override
  String get goalPeopleLine =>
      'Quem te quer convencer, e como te fazeres entender.';

  @override
  String get goalBusinessLine =>
      'Negociações, incentivos e os números por trás de uma ideia.';

  @override
  String get goalMoneyLine =>
      'Preços, promoções, juros: as armadilhas de um negócio.';

  @override
  String get goalHealthLine =>
      'Dietas, curas e estudos: o que dizem as provas.';

  @override
  String mathsDailyStreak(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n dias seguidos',
      one: '1 dia seguido',
      zero: '$n dias seguidos',
    );
    return '$_temp0';
  }

  @override
  String get deeperYourTake => 'A tua ideia, analisada';

  @override
  String get deeperYourTakeHint => 'Escreve o que pensas sobre isto…';

  @override
  String get deeperAnalyse => 'Analisar';

  @override
  String get deeperAsk => 'Pergunta sobre esta carta';

  @override
  String get deeperAskHint => 'A tua pergunta…';

  @override
  String get deeperSend => 'Perguntar';

  @override
  String get deeperSource => 'Fonte';

  @override
  String get deeperOpenSource => 'Abrir o original';

  @override
  String get deeperAiNote => 'Responde uma IA: pode errar.';

  @override
  String get deeperBusy => 'A pensar…';

  @override
  String get deeperTomorrow => 'Por hoje chega: amanhã há mais.';

  @override
  String get deeperTryAgain => 'Não chegou. Tenta outra vez daqui a pouco.';

  @override
  String get deeperUnavailable =>
      'Indisponível neste momento. Tenta mais tarde.';

  @override
  String newsOutlets(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n órgãos',
      one: '1 órgão',
      zero: '$n órgãos',
    );
    return '$_temp0';
  }

  @override
  String newsHoursAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Há $n h',
      zero: 'Agora mesmo',
    );
    return '$_temp0';
  }

  @override
  String newsDaysAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Há $n dias',
      one: 'Ontem',
    );
    return '$_temp0';
  }

  @override
  String get newsWorld => 'Mundo';

  @override
  String get newsKeyPoints => 'Pontos-chave';

  @override
  String get newsBehind => 'Por trás da notícia';

  @override
  String get newsMeansForYou => 'O que significa para ti';

  @override
  String get newsMeans => 'O que significa';

  @override
  String get newsHappenedBefore => 'Já aconteceu antes';

  @override
  String get newsSources => 'Fontes';

  @override
  String get newsMadeFrom =>
      'Escrito pelo Astute a partir destas notícias, e verificado com elas.';

  @override
  String get newsWhyItMatters => 'Porque importa';

  @override
  String get deeperDeclined => 'A esta não consegue responder.';

  @override
  String get deeperPlusOnly => 'Com o Astute+';

  @override
  String get deeperSimpleLead =>
      'A ideia da carta, como a contarias a uma criança curiosa de dez anos.';

  @override
  String get deeperSidesLead =>
      'Os argumentos mais fortes de cada lado, e o que resolveria a questão.';

  @override
  String get deeperExampleLead =>
      'Um momento de um dia qualquer em que esta ideia aparece.';

  @override
  String get deeperQuizLead =>
      'Um caso que a carta não menciona: uma pergunta, três respostas.';

  @override
  String get deeperYourTakeLead =>
      'O que se aguenta no teu raciocínio, onde falha, e uma pergunta para o pôr à prova.';

  @override
  String get deeperAskLead =>
      'Tudo o que a carta te deixou com vontade de perguntar.';

  @override
  String get deeperSideA => 'Um lado';

  @override
  String get deeperSideB => 'O outro lado';

  @override
  String get deeperVersus => 'VS';

  @override
  String get deeperRetry => 'Tentar de novo';

  @override
  String get deeperSimpleGo => 'Explica-me';

  @override
  String get deeperSidesGo => 'Mostra-me os dois lados';

  @override
  String get deeperExampleGo => 'Dá-me um exemplo';

  @override
  String get deeperQuizGo => 'Põe-me à prova';

  @override
  String get bookOfTheWeek => 'Livro da semana';

  @override
  String bookIdeas(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n ideias',
      one: '1 ideia',
      zero: '$n ideias',
    );
    return '$_temp0';
  }

  @override
  String bookMoreTitle(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Mais $n ideias deste livro',
      one: 'Mais uma ideia deste livro',
    );
    return '$_temp0';
  }

  @override
  String get bookMoreLine =>
      'O livro inteiro com o Astute+, e todas as semanas um livro grátis.';

  @override
  String get bookMoreGo => 'Ler o livro inteiro';

  @override
  String bookMinutes(int n) {
    return '$n min';
  }

  @override
  String get bookStart => 'Começar a ler';

  @override
  String get bookContinue => 'Continuar';

  @override
  String get bookAgain => 'Ler outra vez';

  @override
  String get bookTheIdeas => 'As ideias';

  @override
  String get bookRecommendedBy => 'Recomendado por';

  @override
  String get bookFreeThisWeek => 'Grátis esta semana';

  @override
  String get booksSeeAll => 'Ver todos';

  @override
  String get booksLibraryTitle => 'Todos os livros';

  @override
  String get bookDoneTitle => 'Livro terminado';

  @override
  String bookDoneLine(int ideas, int minutes) {
    return '$ideas grandes ideias, em $minutes minutos.';
  }

  @override
  String bookDoneCount(int count) {
    return 'Livros terminados: $count';
  }

  @override
  String get bookDoneNext => 'Próximo livro';

  @override
  String get bookDoneGo => 'Abrir';

  @override
  String bookRetold(String title, String author) {
    return 'As ideias de $title, de $author, contadas por palavras do Astute. Para o livro inteiro, procura-o numa livraria.';
  }

  @override
  String get foundersTitle => 'O que leem os fundadores';

  @override
  String founderBookCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n livros',
      one: '1 livro',
      zero: '$n livros',
    );
    return '$_temp0';
  }

  @override
  String get founderTheirBooks => 'Os livros que recomendou';

  @override
  String founderRole(String id, String role) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'bill_gates': 'Cofundador da Microsoft',
      'warren_buffett': 'O investidor que construiu a Berkshire Hathaway',
      'mark_zuckerberg': 'Fundador do Facebook',
      'charlie_munger': 'Sócio de Warren Buffett na Berkshire Hathaway',
      'marc_andreessen': 'Cofundador da Netscape e da Andreessen Horowitz',
      'tobi_lutke': 'Fundador da Shopify',
      'naval_ravikant': 'Cofundador da AngelList',
      'other': '$role',
    });
    return '$_temp0';
  }

  @override
  String founderWhere(String id, String where) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'gates_summer': 'GatesNotes, os seus livros para o verão',
      'berkshire_meeting': 'a assembleia anual da Berkshire Hathaway',
      'berkshire_letter': 'a sua carta aos acionistas da Berkshire Hathaway',
      'year_of_books': 'A Year of Books, no Facebook',
      'publisher_praise': 'o seu elogio ao livro, no site da editora',
      'ferriss_five':
          'The Tim Ferriss Show, entre os cinco melhores livros que já leu',
      'other': '$where',
    });
    return '$_temp0';
  }

  @override
  String founderAbout(String name) {
    return 'São livros que $name recomendou em público, com as palavras citadas e o sítio onde as disse. $name não tem qualquer ligação com o Astute.';
  }

  @override
  String founderPhoto(String author, String licence) {
    return 'Foto: $author, $licence, Wikimedia Commons, recortada';
  }

  @override
  String founderAlso(String names) {
    return 'Também recomendado por $names';
  }

  @override
  String get firstCardTitle => 'A tua primeira carta';

  @override
  String get firstCardSwipeOn => 'Desliza para continuar';

  @override
  String get trialOfferTitle => 'Experimenta todo o Astute+.';

  @override
  String get trialOfferMark => 'Astute+.';

  @override
  String get trialOfferLine =>
      'As cinco cartas de hoje esperam por ti de qualquer forma.';

  @override
  String get trialStepToday => 'Hoje';

  @override
  String get trialStepTodayLine => 'Abre-se todo o Astute+. Não pagas nada.';

  @override
  String trialStepDay(int day) {
    return 'Dia $day';
  }

  @override
  String trialStepReminderLine(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Enviamos-te uma notificação: faltam $days dias.',
      one: 'Enviamos-te uma notificação: falta 1 dia.',
      zero: 'Enviamos-te uma notificação: faltam $days dias.',
    );
    return '$_temp0';
  }

  @override
  String get trialStepChargeLine =>
      'Renova-se todos os anos. Cancela pelo menos 24 horas antes e não pagas nada.';

  @override
  String get trialOfferStart => 'Começar o teste gratuito';

  @override
  String get trialOfferFree => 'Continuar grátis';

  @override
  String get paywallStepFree => 'Tudo grátis';

  @override
  String get paywallStepRemind => 'Avisamos-te';

  @override
  String get paywallChargedToday => 'Cobrado hoje · Cancela quando quiseres';

  @override
  String paywallGoalTitle(String goal) {
    String _temp0 = intl.Intl.selectLogic(goal, {
      'decide': 'Para quem quer decidir melhor.',
      'money': 'Para quem não se deixa enganar com dinheiro.',
      'people': 'Para quem quer perceber as pessoas.',
      'news': 'Para quem não se deixa levar pelos títulos.',
      'health': 'Para quem quer provas sobre saúde.',
      'business': 'Para quem quer ver claro no trabalho.',
      'other': 'Para quem quer ver claro.',
    });
    return '$_temp0';
  }

  @override
  String paywallGoalMark(String goal) {
    String _temp0 = intl.Intl.selectLogic(goal, {
      'decide': 'melhor.',
      'money': 'dinheiro.',
      'people': 'pessoas.',
      'news': 'títulos.',
      'health': 'saúde.',
      'business': 'trabalho.',
      'other': 'claro.',
    });
    return '$_temp0';
  }

  @override
  String paywallMadeLine(String subjects) {
    return 'Cinco cartas por dia de $subjects, ao teu nível. As que falhas voltam até ficarem. E vês-te mudar, semana a semana.';
  }

  @override
  String subjectsTwo(String a, String b) {
    return '$a e $b';
  }

  @override
  String subjectsThree(String a, String b, String c) {
    return '$a, $b e $c';
  }

  @override
  String get firstWeekTitle => 'A tua primeira semana';

  @override
  String get firstMonthTitle => 'O teu primeiro mês';

  @override
  String firstOfferDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n dias de leitura',
      one: 'Um dia de leitura',
    );
    return '$_temp0';
  }

  @override
  String get firstWeekBest => 'A melhor carta da semana';

  @override
  String get firstMonthBest => 'A melhor carta do mês';

  @override
  String firstOfferBestWhy(String why) {
    String _temp0 = intl.Intl.selectLogic(why, {
      'said': 'Contaste-a a alguém.',
      'liked': 'Gostaste dela.',
      'saved': 'Guardaste-a.',
      'changed': 'Fez-te mudar de ideias.',
      'other': 'Ficaste com ela.',
    });
    return '$_temp0';
  }

  @override
  String firstOfferTrialTitle(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Astute+, grátis durante $days dias',
      one: 'Astute+, grátis durante um dia',
    );
    return '$_temp0';
  }

  @override
  String get firstOfferPlusLine =>
      'Cinco cartas tuas todos os dias, cada percurso e cada livro, e os teus números semana a semana.';

  @override
  String get firstOfferNotNow => 'Agora não';

  @override
  String get listenEntry => 'Ouve as cinco de hoje';

  @override
  String get listenEntryShort => 'Ouvir';

  @override
  String get listenTitle => 'As cinco de hoje';

  @override
  String get listenQuestion => 'Pergunta';

  @override
  String get listenThink => 'Pensa nisso…';

  @override
  String get listenAnswer => 'Resposta';

  @override
  String get listenPreparing => 'A preparar a voz…';

  @override
  String get listenWaiting => 'A próxima carta está a chegar…';

  @override
  String get listenFreeNote =>
      'A primeira carta é grátis; as outras, com o Astute+.';

  @override
  String get listenOfferTitle => 'As outras cartas de hoje, lidas para ti';

  @override
  String get listenOfferLine =>
      'Com o Astute+ ouves as cinco todos os dias, mesmo com o ecrã bloqueado.';

  @override
  String get listenNothing => 'Nada para ouvir nesta carta';

  @override
  String get listenCardUnavailable => 'Indisponível de momento';

  @override
  String get listenUnavailable =>
      'Ouvir não está disponível de momento. Tenta mais tarde.';

  @override
  String get listenDone => 'Todas as cartas de hoje, ouvidas.';

  @override
  String get listenAgain => 'Ouvir outra vez';

  @override
  String get listenNextCard => 'Carta seguinte';

  @override
  String summaryReadIn(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'Lê em $minutes minutos',
      one: 'Lê em 1 minuto',
    );
    return '$_temp0';
  }

  @override
  String get summaryContinue => 'Continuar a ler';

  @override
  String get summaryAgain => 'Ler de novo';

  @override
  String summaryPartOf(int part, int of) {
    return 'Parte $part de $of';
  }

  @override
  String summaryMinutesLeft(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'faltam $n min',
      one: 'falta 1 min',
    );
    return '$_temp0';
  }

  @override
  String summaryListenFor(int minutes) {
    return 'Ouvir · $minutes min';
  }

  @override
  String get summaryPause => 'Pausa';

  @override
  String get summaryResume => 'Continuar a ouvir';

  @override
  String get summaryFreeNote =>
      'A primeira parte é grátis; o resto vem com o Astute+.';

  @override
  String get summaryTitle => 'O resumo';

  @override
  String get summaryNowPlaying => 'A tocar';

  @override
  String get summaryNextPart => 'Parte seguinte';

  @override
  String get summaryFinish => 'Terminar';

  @override
  String get summaryContents => 'Índice';

  @override
  String summaryDoneTitle(String title) {
    return 'Leste $title';
  }

  @override
  String get summaryDoneLine => 'As cartas do livro ajudam as ideias a ficar.';

  @override
  String get summaryToCards => 'As ideias em cartas';

  @override
  String get summaryBackToBook => 'Voltar ao livro';

  @override
  String get summaryGateTitle => 'O resto deste resumo vem com o Astute+';

  @override
  String summaryGateLine(int parts) {
    return 'As $parts partes, para ler e ouvir, de cada livro. O livro da semana é grátis para todos.';
  }

  @override
  String get summaryNeedsNetwork => 'Este resumo precisa de internet uma vez.';

  @override
  String get bookAudioBack => 'Recuar 15 segundos';

  @override
  String get bookAudioWaiting => 'A próxima parte está a caminho…';

  @override
  String get bookAudioDone => 'Ouvido até ao fim.';

  @override
  String get bookAudioOfferTitle => 'Ouve o resto do livro';

  @override
  String get bookAudioOfferLine =>
      'Com o Astute+ cada resumo é lido para ti por inteiro, mesmo com o ecrã bloqueado.';

  @override
  String get bookAudioStop => 'Parar de ouvir';

  @override
  String get bookAudioOpen => 'Abrir o leitor';

  @override
  String get inviteSection => 'Amigos';

  @override
  String get inviteRow => 'Convida um amigo';

  @override
  String get inviteRowLine => 'Uma semana de Astute+ para os dois';

  @override
  String get inviteCodeRow => 'Tens um código?';

  @override
  String get inviteCodeAccepted => 'Código aceite';

  @override
  String get inviteCodeAcceptedLine =>
      'A tua semana começa quando terminares o primeiro dia';

  @override
  String get inviteSheetLine =>
      'Envia o teu código a um amigo. Quando ele terminar o primeiro dia, as cinco cartas, cada um recebe uma semana de Astute+.';

  @override
  String get inviteYourCode => 'O teu código';

  @override
  String get inviteCopy => 'Copiar';

  @override
  String get inviteSend => 'Enviar o convite';

  @override
  String inviteRules(int cap) {
    return 'Vale para uma conta nova que nunca teve Astute+. Recebes até $cap semanas por ano.';
  }

  @override
  String inviteWeeksSoFar(int n, int cap) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n semanas de $cap este ano',
      one: '1 semana de $cap este ano',
    );
    return '$_temp0';
  }

  @override
  String inviteCapped(int cap) {
    return 'Já tiveste as $cap semanas deste ano. Os teus amigos continuam a receber a deles.';
  }

  @override
  String inviteMessage(String code, String link) {
    return 'Convido-te para o Astute: cinco cartas por dia para manter a mente afiada. Com o meu código $code, quando terminares o primeiro dia, cada um de nós recebe uma semana de Astute+.\n$link';
  }

  @override
  String inviteMessageCapped(String code, String link) {
    return 'Convido-te para o Astute: cinco cartas por dia para manter a mente afiada. Com o meu código $code, quando terminares o primeiro dia, recebes uma semana de Astute+ de oferta.\n$link';
  }

  @override
  String get inviteCodeTitle => 'O código de um amigo';

  @override
  String get inviteCodeLine =>
      'Escreve o código que um amigo te enviou. Quando terminares o primeiro dia, cada um recebe uma semana de Astute+.';

  @override
  String get inviteCodeUse => 'Usar o código';

  @override
  String get inviteCodeWaitingLine =>
      'Termina o primeiro dia, as cinco cartas: aí começa a semana de Astute+, para ti e para o amigo que te convidou.';

  @override
  String get inviteRefusedUnknown =>
      'Esse código não existe. Confirma os caracteres e tenta outra vez.';

  @override
  String get inviteRefusedOwn =>
      'Esse é o teu próprio código: envia-o a um amigo.';

  @override
  String get inviteRefusedUsed => 'Já usaste o código de um amigo.';

  @override
  String get inviteRefusedLate =>
      'Os códigos são para contas novas, na primeira semana.';

  @override
  String get inviteRefusedPlus =>
      'Os códigos são para contas que nunca tiveram Astute+.';

  @override
  String get inviteSuccessTitle => 'Uma semana de Astute+, oferecida.';

  @override
  String get inviteSuccessPlan => 'Astute+ · uma semana';

  @override
  String inviteSuccessUntil(String date) {
    return 'Até $date';
  }

  @override
  String get inviteSuccessFoot =>
      'Nada a pagar e nada a cancelar: depois voltas ao plano gratuito.';

  @override
  String inviteEarned(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          '$n amigos terminaram o primeiro dia: $n semanas de Astute+ para ti.',
      one: 'Um amigo terminou o primeiro dia: uma semana de Astute+ para ti.',
    );
    return '$_temp0';
  }

  @override
  String get firstDayTitle => 'Terminaste o teu primeiro dia';

  @override
  String firstDaySureRight(int sure, int right, int total) {
    return 'Estavas $sure% seguro e acertaste $right em $total.';
  }

  @override
  String firstDayRight(int right, int total) {
    return 'Acertaste $right em $total.';
  }

  @override
  String get firstDayRemind => 'Lembra-me amanhã';

  @override
  String firstDayReminded(String time) {
    return 'Lembramos-te amanhã às $time.';
  }

  @override
  String get earlyReadingTag => 'Primeira leitura';

  @override
  String earlyReadingAll(int level, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n vezes, e acertaste todas',
      two: 'duas vezes, e acertaste as duas',
      one: 'uma vez, e acertaste',
    );
    return 'Até agora: disseste $level% $_temp0.';
  }

  @override
  String earlyReadingNone(int level, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n vezes, e falhaste todas',
      two: 'duas vezes, e falhaste as duas',
      one: 'uma vez, e falhaste',
    );
    return 'Até agora: disseste $level% $_temp0.';
  }

  @override
  String earlyReadingSome(int level, int n, int right) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n vezes',
      two: 'duas vezes',
    );
    String _temp1 = intl.Intl.pluralLogic(
      right,
      locale: localeName,
      other: '$right vezes',
      two: 'duas vezes',
      one: 'uma vez',
    );
    return 'Até agora: disseste $level% $_temp0, e acertaste $_temp1.';
  }

  @override
  String get journeyClearEyebrow => 'Esta semana, à vista';

  @override
  String journeyClearBlind(String subject) {
    return 'O teu ponto cego: $subject';
  }

  @override
  String journeyClearStrong(String subject) {
    return 'O teu ponto forte: $subject';
  }

  @override
  String journeyClearShare(String pct, int n) {
    return '$pct certas nas tuas últimas $n respostas desta área.';
  }

  @override
  String journeyClearMemoryDays(int days, int right, int of) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days dias',
      two: 'dois dias',
      one: 'um dia',
    );
    return 'Após $_temp0, ainda te lembras de $right de $of.';
  }

  @override
  String journeyClearMemoryWeeks(int weeks, int right, int of) {
    String _temp0 = intl.Intl.pluralLogic(
      weeks,
      locale: localeName,
      other: '$weeks semanas',
      one: 'uma semana',
    );
    return 'Após $_temp0, ainda te lembras de $right de $of.';
  }

  @override
  String get journeyClearBlindNotYet =>
      'Seis respostas em duas áreas e aqui aparece a que mais falhas.';

  @override
  String get journeyClearStrongNotYet =>
      'Seis respostas numa área e aqui aparece aquela em que és melhor.';

  @override
  String journeyClearSureNotYet(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          'Mais $n respostas a dizer quão certo estás, e aqui aparece uma primeira leitura.',
      one: 'Mais uma resposta a dizer quão certo estás, e aqui aparece uma primeira leitura.',
    );
    return '$_temp0';
  }

  @override
  String get journeyClearMemoryNotYet =>
      'As cartas voltam ao fim de 2, 7 e 21 dias: aqui vês quantas ainda recordas.';

  @override
  String get journeyPreviewDoor =>
      'Todas as semanas um número diferente. O Astute+ abre o resto.';

  @override
  String weekSheetOf(String date) {
    return 'A semana de $date';
  }

  @override
  String weekSheetRightValue(int right, int n) {
    return '$right de $n';
  }

  @override
  String get weekSheetRightLabel => 'Respostas certas';

  @override
  String weekSheetAcross(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'em $n respostas',
      one: 'em 1 resposta',
    );
    return '$_temp0';
  }

  @override
  String get weekSheetOverLabel => 'Onde confias demais';

  @override
  String get weekSheetMemoryLabel => 'O que ainda recordas';

  @override
  String get weekSheetAccount => 'Guarda a tua semana em qualquer telemóvel';
}

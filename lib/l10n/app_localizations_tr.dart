// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appName => 'Astute';

  @override
  String get plusName => 'Astute+';

  @override
  String get tabToday => 'Bugün';

  @override
  String get tabExplore => 'Keşfet';

  @override
  String get tabProfile => 'Profil';

  @override
  String signInNotConnected(String provider) {
    return '$provider ile giriş henüz bağlı değil. Kartların bu cihazda kalır.';
  }

  @override
  String couldNotSignInCarryOn(String label) {
    return '$label ile giriş yapılamadı. Hesapsız devam edebilirsin.';
  }

  @override
  String streakDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n gün',
      one: '1 gün',
    );
    return '$_temp0';
  }

  @override
  String get freezeKeptStreak => 'Bir dondurma seriyi kurtardı';

  @override
  String countWord(String n) {
    String _temp0 = intl.Intl.selectLogic(n, {
      '1': 'bir',
      '2': 'iki',
      '3': 'üç',
      '4': 'dört',
      '5': 'beş',
      '6': 'altı',
      '7': 'yedi',
      '8': 'sekiz',
      '9': 'dokuz',
      '10': 'on',
      'other': '$n',
    });
    return '$_temp0';
  }

  @override
  String dayRead(int n, String word) {
    return '$n. gün · $word okundu';
  }

  @override
  String shelfEyebrow(String word) {
    return 'BUGÜNÜN $word KARTI';
  }

  @override
  String get tapToFlip => 'ÇEVİRMEK İÇİN DOKUN';

  @override
  String get shareThisCard => 'Bu kartı paylaş';

  @override
  String get removeFromSaved => 'Saklananlardan çıkar';

  @override
  String get saveThisPill => 'Bu kartı sakla';

  @override
  String get shareThisPill => 'Bu kartı paylaş';

  @override
  String cardOf(int k, int n) {
    return '$n karttan $k.';
  }

  @override
  String tomorrowsFiveOpenIn(String when) {
    return 'Yarının beşlisi $when sonra açılıyor';
  }

  @override
  String topicOpensTomorrow(String topic, String when) {
    return '$topic, yarının beşlisini açıyor, $when sonra';
  }

  @override
  String get exploreTodaysBest => 'Bugünün en iyilerini keşfet';

  @override
  String magicUnlock(int days) {
    return '$days gün ücretsiz dene';
  }

  @override
  String get getPlus => 'Astute+\'a geç';

  @override
  String nothingInYet(String subject) {
    return '$subject içinde henüz bir şey yok.';
  }

  @override
  String get here => 'bu bölüm';

  @override
  String get todaysShelf => 'Bugünün rafı';

  @override
  String get sameForEveryone => 'Herkes için aynı, ve yalnızca bugün';

  @override
  String get onesThatAskTheMost => 'En çok soranlar';

  @override
  String get acrossEveryone => 'Herkeste, yalnızca senin karışımında değil';

  @override
  String becauseSitsAtFull(String name) {
    return 'Çünkü $name en üstte';
  }

  @override
  String get olderFromTurnedUp => 'Yükselttiğin konulardan eski kartlar';

  @override
  String moreOn(String name) {
    return '$name üzerine daha fazlası';
  }

  @override
  String get subjectReadMost => 'En çok okuduğun konu';

  @override
  String monthOf(String name) {
    return 'Bir ay $name';
  }

  @override
  String get somewhereToStart => 'Bugün olmayan bir başlangıç';

  @override
  String get searchEveryCard => 'Tüm kartlarda ara';

  @override
  String nothingForYet(String query) {
    return '\"$query\" için henüz bir şey yok.';
  }

  @override
  String matching(int n) {
    return '$n eşleşme';
  }

  @override
  String get all => 'Tümü';

  @override
  String get theArchive => 'Arşiv';

  @override
  String results(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n sonuç',
      one: '1 sonuç',
    );
    return '$_temp0';
  }

  @override
  String cardsTapADay(int n) {
    return '$n kart. Açmak için bir güne dokun.';
  }

  @override
  String get whatYouHaveCovered => 'Neleri kapsadın';

  @override
  String searchNCards(int n) {
    return '$n kartta ara';
  }

  @override
  String get cancel => 'İptal';

  @override
  String nCards(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n kart',
      one: '1 kart',
    );
    return '$_temp0';
  }

  @override
  String get yesterday => 'Dün';

  @override
  String get noPillsMatchFilter => 'Bu filtreye henüz uyan kart yok.';

  @override
  String nothingForTryTopic(String query) {
    return '\"$query\" için bir şey yok. Bir konu dene.';
  }

  @override
  String get saved => 'Saklananlar';

  @override
  String get removedFromSaved => 'Saklananlardan çıkarıldı.';

  @override
  String get undo => 'Geri al';

  @override
  String get nothingKeptYet => 'Henüz bir şey saklanmadı';

  @override
  String nInTopic(int n, String topic) {
    return '$topic içinde $n';
  }

  @override
  String get keepTheOnesYoullUse => 'Gerçekten kullanacaklarını sakla';

  @override
  String get backToTodaysFive => 'BUGÜNÜN BEŞLİSİNE DÖN';

  @override
  String get archive => 'Arşiv';

  @override
  String get yourWeek => 'Haftan';

  @override
  String get nothingThisWeekYet =>
      'Bu hafta henüz bir şey yok. Beş kart onu başlatır.';

  @override
  String keptDaysOfSeven(int days) {
    return 'Tamam — yedi günden $days.';
  }

  @override
  String daysOfSevenFiveKeeps(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Yedi günden $days.',
      one: 'Yedi günden 1.',
    );
    return '$_temp0 Beş gün haftayı tutar.';
  }

  @override
  String get howSureAgainstHowRight => 'Ne kadar emin, ne kadar doğru';

  @override
  String get sureAndWrong => 'Emin, ve yanlış';

  @override
  String get worthGoingBackTo =>
      'Geri dönmeye değenler. Emin olduğun bir şeyde yanılmak, gerçekten neye inandığını öğrenmenin tek ucuz yoludur.';

  @override
  String get whereThisIsGoing => 'Bu nereye gidiyor';

  @override
  String ofNRight(int n) {
    return '$n sorudan doğru';
  }

  @override
  String get sayHowSureOnMore =>
      'Birkaç soruda daha ne kadar emin olduğunu söyle, uygulama o güvenin ne değer ettiğini söylesin.';

  @override
  String confidenceOff(int gap) {
    return 'Güvenin, gerçekten bildiğinden $gap puan uzaktaydı.';
  }

  @override
  String confidenceClosing(int gap, int before) {
    return 'Güvenin $gap puan saptı, geçen hafta $before idi. Aralık kapanıyor.';
  }

  @override
  String confidenceOpened(int gap, int before) {
    return 'Güvenin $gap puan saptı, geçen hafta $before idi. Aralık açıldı.';
  }

  @override
  String nextRung(String name) {
    return 'Sırada: $name';
  }

  @override
  String youSaidPercentSure(int n) {
    return '%$n emin dedin';
  }

  @override
  String rungName(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'day_one': 'Birinci gün',
      'reading': 'Okuma',
      'answering': 'Yanıtlama',
      'saying_how_sure': 'Güveni söyleme',
      'calibrated': 'Kalibre',
      'holding': 'Tutma',
      'sharp': 'Keskin',
      'other': '$id',
    });
    return '$_temp0';
  }

  @override
  String rungClaim(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'day_one': 'Herkes buradan başlar.',
      'reading': 'Alışkanlık başladı.',
      'answering': 'Kartı çevirmeden önce karar veriyorsun.',
      'saying_how_sure': 'Bildiğini sandığın şeye bir sayı koyuyorsun.',
      'calibrated': 'Bildiğini söylediğini biliyorsun.',
      'holding': 'Haftalar sonra hâlâ seninle.',
      'sharp': 'Gerektiğinde emin, olduğunda doğru.',
      'other': '$id',
    });
    return '$_temp0';
  }

  @override
  String stepRead(int n) {
    return 'okunacak $n kart daha';
  }

  @override
  String stepAnswer(int n) {
    return 'yanıtlanacak $n kart daha';
  }

  @override
  String stepJudge(int n) {
    return 'güvenini söylediğin $n yanıt daha';
  }

  @override
  String stepHold(int n) {
    return 'tutulacak $n kart daha';
  }

  @override
  String stepGap(int gap, int target) {
    return 'güvenin $gap puan sapıyor — $target yeter';
  }

  @override
  String stepBeforeJudged(int n) {
    return 'uygulama güvenini değerlendirmeden önce $n yanıt daha';
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
  String get signOutQuestion => 'Çıkış yapılsın mı?';

  @override
  String get signOutBody =>
      'Serin, sakladığın kartlar ve sicilin hesabında kalır. Bu, onları bu cihazdan siler.';

  @override
  String get deleteAccount => 'Hesabı sil';

  @override
  String get deletingAccount => 'Hesabın siliniyor…';

  @override
  String get deleteAccountQuestion => 'Hesabın silinsin mi?';

  @override
  String get deleteAccountBody =>
      'Hesabın, yedeği ve arkadaşlarının gördüğü pano kalıcı olarak silinir ve bu cihaz en baştan başlar. Bu, Astute+ aboneliğini iptal etmez: abonelik App Store ayarlarından yönetilir.';

  @override
  String get deleteAccountConfirm => 'Kalıcı olarak sil';

  @override
  String get accountDeleted => 'Hesabın silindi.';

  @override
  String get couldNotDeleteAccount => 'Hesap silinemedi. Birazdan tekrar dene.';

  @override
  String get signOut => 'Çıkış yap';

  @override
  String get signedInRecordOnAccount =>
      'Giriş yapıldı. Serin ve sicilin artık hesabında.';

  @override
  String couldNotSignInWith(String label) {
    return '$label ile giriş yapılamadı.';
  }

  @override
  String get signInNotAvailableBuild => 'Bu sürümde giriş kullanılamıyor.';

  @override
  String get startOverQuestion => 'Baştan başlansın mı?';

  @override
  String get startOverBody =>
      'Bu cihazdaki her şeyi siler — seri, saklanan kartlar, yanıtlar, karar sicilin, konular ve plan — ve tanıtımı yeniden açar.';

  @override
  String get wipeIt => 'Sil';

  @override
  String get yourRecord => 'Sicilin';

  @override
  String get appearance => 'Görünüm';

  @override
  String get themeLight => 'Açık';

  @override
  String get themeDark => 'Koyu';

  @override
  String get themeSystem => 'Sistem';

  @override
  String get yourTopics => 'Konuların';

  @override
  String get edit => 'Düzenle';

  @override
  String get howWellYouKnowYourself => 'Kendini ne kadar tanıyorsun';

  @override
  String get journeyButtonLine =>
      'Seviyen, kaçırmaya devam ettiğin hamleler, sorularla haftan';

  @override
  String get isTheGapClosing => 'Aralık kapanıyor mu?';

  @override
  String get movesYouKeepMissing => 'Kaçırmaya devam ettiğin hamleler';

  @override
  String get dailyNudge => 'Günlük hatırlatma';

  @override
  String everyDayAt(String time) {
    return 'Her gün $time';
  }

  @override
  String get yourFivePillsBeforeCoffee => '5 kartın, ilk kahveden önce.';

  @override
  String get browserOnlySpeaksOpen =>
      'Tarayıcı yalnızca açıkken konuşur, bu yüzden telefon sürümü gerekir.';

  @override
  String get nudgeOff => 'Hatırlatma kapalı.';

  @override
  String nudgeOnEveryDayAt(String time) {
    return 'Hatırlatma açık, her gün $time.';
  }

  @override
  String get nudgeOnSystemSaidNo =>
      'Hatırlatma açık ama sistem izin vermedi. Ayarlardan Astute bildirimlerini aç.';

  @override
  String get nudgeOnNeedsPhone =>
      'Hatırlatma açık. Teslimat için telefon sürümü gerekir.';

  @override
  String savedN(int n) {
    return 'Saklananlar · $n';
  }

  @override
  String get manageSubscription => 'Aboneliği yönet';

  @override
  String get howPillsAreWritten => 'Kartlar nasıl yazılıyor';

  @override
  String get howTitle => 'Buradaki her kartı bir yapay zekâ modeli yazıyor.';

  @override
  String get howIntro =>
      'Senin fark etmenden önce baştan söylemeyi tercih ederiz. Bir kart sana şöyle ulaşır.';

  @override
  String get howStep1Title => 'Önceden, bir model tarafından yazılır';

  @override
  String get howStep1Line =>
      'Her kart tek bir talimata göre yazılır: sormaya değer bir soru, nedenini söyleyen bir yanıt ve yeniden kullanabileceğin bir hamle.';

  @override
  String get howStep2Title => 'Kaynağına göre kontrol edilir';

  @override
  String get howStep2Line =>
      'Her kart nereden geldiğini söyler ve yayımlanmadan önce ikinci bir model onu eleştirmen gibi okur. Dayanağı olmayan çıkarılır.';

  @override
  String get howStep3Title => 'Her sabah beş kart';

  @override
  String get howStep3Line =>
      'Seçtiğin konulardan, ve asla daha önce okuduğun bir kart değil.';

  @override
  String get howStep4Title => 'Okurlar dürüst tutar';

  @override
  String get howStep4Line =>
      'Yeterince okur bir kartın yanlış olduğunu söylediğinde, bir insan kontrol edene kadar dağıtılmaz.';

  @override
  String get howReportTitle => 'Bir hata mı buldun?';

  @override
  String get howReportLine =>
      'Bildirmek için bir kartın kaynağının yanındaki bayrağa dokun.';

  @override
  String get howFoot => 'Kaynaklar her ay yeniden kontrol edilir.';

  @override
  String get signingIn => 'Giriş yapılıyor…';

  @override
  String get signInWithApple => 'Apple ile giriş yap';

  @override
  String get signInWithGoogle => 'Google ile giriş yap';

  @override
  String acrossNAnswersHowSure(int n) {
    return '$n yanıtta ne kadar emin olduğunu söyledin. İşte olan.';
  }

  @override
  String get perfectlyCalibratedLine =>
      'Mükemmel kalibre biri %70 dediğinde zamanın %70\'inde haklıdır.';

  @override
  String get notEnoughAnswersYet => 'Henüz yeterli yanıt yok';

  @override
  String get confidenceMatchesAccuracy => 'Güvenin isabetinle örtüşüyor';

  @override
  String overconfidentBy(int points) {
    return '$points puan fazla eminsin';
  }

  @override
  String underconfidentBy(int points) {
    return '$points puan az eminsin';
  }

  @override
  String saidPercent(int n) {
    return '%$n dedin';
  }

  @override
  String rightPercentOf(int pct, int right, int count) {
    return '%$pct doğru ($count içinden $right)';
  }

  @override
  String moreOfThisToCome(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'bunun $n bağlamı daha gelecek',
      one: 'bunun 1 bağlamı daha gelecek',
    );
    return '$_temp0';
  }

  @override
  String get seeEveryPrincipleWithPlus => 'Astute plus ile her ilkeyi gör';

  @override
  String moreBeingTracked(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n tanesi daha izleniyor',
      one: '1 tanesi daha izleniyor',
    );
    return '$_temp0';
  }

  @override
  String get shareMyRecord => 'SİCİLİMİ PAYLAŞ';

  @override
  String lastCallsAgainstFirst(int n) {
    return 'Son $n kararın, ilk $n kararına karşı';
  }

  @override
  String closedByPoints(int n) {
    return '$n puan kapandı';
  }

  @override
  String openedByPoints(int n) {
    return '$n puan açıldı';
  }

  @override
  String get holdingSteady => 'Sabit';

  @override
  String get measurementRunningPlus =>
      'Ölçüm sürüyor. Astute+ hangi yöne gittiğini gösterir.';

  @override
  String firstN(int n) {
    return 'İlk $n';
  }

  @override
  String lastN(int n) {
    return 'Son $n';
  }

  @override
  String get trackingMoreClosely =>
      'Güvenin isabetini eskisinden daha yakından izliyor.';

  @override
  String get distanceHasGrown =>
      'Mesafe büyüdü. Karar vermeden önce yavaşlamaya değer.';

  @override
  String get noRealMovementYet =>
      'Henüz gerçek bir hareket yok. Bu günler değil, haftalar sürer.';

  @override
  String get seeWhichWay => 'HANGİ YÖNE, GÖR';

  @override
  String get spotOn => 'tam isabet';

  @override
  String pointsOver(int n) {
    return '$n fazla';
  }

  @override
  String pointsUnder(int n) {
    return '$n eksik';
  }

  @override
  String get plusNameCaps => 'ASTUTE+';

  @override
  String trialDaysFree(int days) {
    return '$days gün ücretsiz';
  }

  @override
  String get seeThePlans => 'PLANLARI GÖR';

  @override
  String get recordStartsToday => 'Sicilin bugün başlıyor.';

  @override
  String dayWord(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'gün',
      one: 'gün',
    );
    return '$_temp0';
  }

  @override
  String pillReadWord(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'kart okundu',
      one: 'kart okundu',
    );
    return '$_temp0';
  }

  @override
  String nPillsRead(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n kart okundu',
      one: '1 kart okundu',
    );
    return '$_temp0';
  }

  @override
  String nWeeksKept(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n hafta tamam',
      one: '1 hafta tamam',
    );
    return '$_temp0';
  }

  @override
  String nComingBack(int n) {
    return '$n geri geliyor';
  }

  @override
  String nFreezesInHand(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'elde $n dondurma',
      one: 'elde 1 dondurma',
    );
    return '$_temp0';
  }

  @override
  String get freePlan => 'Ücretsiz plan';

  @override
  String get welcomeBack => 'Tekrar hoş geldin';

  @override
  String youMissedDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n gün\nkaçırdın.',
      one: 'Bir gün\nkaçırdın.',
    );
    return '$_temp0';
  }

  @override
  String bestStreakStillRecord(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n gün',
      one: 'Bir gün',
    );
    return '$_temp0 hâlâ rekorun. Bugünün beşlisini oku, sayaç yeniden birden başlar.';
  }

  @override
  String get whileYouWereAway => 'Sen yokken';

  @override
  String pillsWentUnread(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n kart okunmadan kaldı',
      one: '1 kart okunmadan kaldı',
    );
    return '$_temp0';
  }

  @override
  String stillMostKeptTopic(String topic) {
    return '$topic hâlâ en çok sakladığın konu';
  }

  @override
  String cardsDueBackToday(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Doğru bildiğin $n kart bugün geri geliyor',
      one: 'Doğru bildiğin 1 kart bugün geri geliyor',
    );
    return '$_temp0';
  }

  @override
  String get startAgainWithTodaysFive => 'Bugünün beşlisiyle yeniden başla';

  @override
  String moveMyReminderTo(String time) {
    return 'Hatırlatmamı $time saatine al';
  }

  @override
  String dailyNudgeMovedTo(String time) {
    return 'Günlük hatırlatma $time saatine alındı.';
  }

  @override
  String subjectsInTheMix(int n, int total) {
    return 'Karışımda $total konudan $n';
  }

  @override
  String get everythingIsInDrag =>
      'Her şey içeride. Daha az görmek için bir konuyu aşağı sürükle, çıkarmak için sıfıra kadar.';

  @override
  String get next => 'İleri';

  @override
  String get whatShouldWeTalkAbout => 'Ne hakkında konuşalım?';

  @override
  String get fivePillsADayPick =>
      'Günde beş kart, her sabah yenileri. Karışımda istediğin konuları seç — sonra değiştirebilirsin.';

  @override
  String nSelected(int n) {
    return '$n seçildi';
  }

  @override
  String startWithNTopics(int n) {
    return '$n konuyla başla';
  }

  @override
  String saveNTopics(int n) {
    return '$n konuyu kaydet';
  }

  @override
  String pickAtLeastN(int n) {
    return 'En az $n seç';
  }

  @override
  String get swipeToSeeMore => 'Daha fazlası için kaydır';

  @override
  String get tagline => 'Günde beş akıllı şey, sohbette kullanmaya hazır';

  @override
  String get introTopicsTitle => 'On dokuz konu, beş kart';

  @override
  String get introTopicsLine =>
      'Bir model tarafından önceden yazılır, her biri kaynağıyla doğrulanır.';

  @override
  String get introQuestionTitle => 'Bir soru, sonra yanıt';

  @override
  String get introQuestionLine =>
      'Her kart, yüksek sesle söylemeye değer o tek cümleyi taşır.';

  @override
  String get introMixTitle => 'Karışımı sen seçersin';

  @override
  String get introMixLine =>
      'Daha az görmek için bir konuyu kıs, ya da tamamen kapat.';

  @override
  String get introThirtyTitle => 'Günde iki dakika';

  @override
  String get introThirtyLine =>
      'Bir bildirim, beş kart ve bozmak istemeyeceğin bir seri.';

  @override
  String introNotifyWhen(String time) {
    return 'Yarın, $time';
  }

  @override
  String get introNotifyLine => 'Beşin hazır. 1. gün.';

  @override
  String get introOneOfFive => '1 / 5';

  @override
  String get introDayOne => '1. GÜN';

  @override
  String get introTapTomorrow => 'CEVAP İÇİN YARIN DOKUN';

  @override
  String get introDayOneTomorrow => '1. GÜN · YARIN';

  @override
  String get introDaySevenStreak => '7. GÜN · İLK SERİ';

  @override
  String get continueWithApple => 'Apple ile devam et';

  @override
  String get continueWithGoogle => 'Google ile devam et';

  @override
  String get continueWithEmail => 'E-posta ile devam et';

  @override
  String get termsLine =>
      'Kaydolarak Hizmet Şartlarımızı ve Gizlilik Politikamızı kabul etmiş olursun';

  @override
  String get skip => 'Atla';

  @override
  String get tapToRevealLower => 'görmek için dokun';

  @override
  String get barMoveCaps => 'AKILDA KALAN';

  @override
  String get theBarMoveCaps => 'MASADA SÖYLENECEK SÖZ';

  @override
  String get widgetFootPlain => 'Beş kart, iki dakika.';

  @override
  String widgetFootStreak(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n günlük seri',
      one: '1 günlük seri',
    );
    return '$_temp0';
  }

  @override
  String get widgetFootDone => 'Bugünlük tamam';

  @override
  String get widgetStreakStart => 'Seri başlatmak için bugünün beşini oku.';

  @override
  String get widgetFiveTitle => 'BUGÜNÜN BEŞİ';

  @override
  String widgetFiveRead(int n) {
    return '5\'te $n okundu';
  }

  @override
  String get widgetFiveDone => 'Beşi de okundu';

  @override
  String get widgetFiveWaiting => 'Yeni beş kart seni bekliyor';

  @override
  String get dayStreakCaps => 'GÜNLÜK SERİ';

  @override
  String sourceLabel(String source) {
    return 'Kaynak · $source';
  }

  @override
  String get perkArchiveTitle => 'Tüm arşivin';

  @override
  String get perkArchiveLine => 'Okuduğun her gün, kalıcı olarak.';

  @override
  String get plusIsActive => 'ASTUTE+ ETKİN';

  @override
  String tryFreeThen(int days, String price, String suffix) {
    return '$days gün ücretsiz, sonra $price$suffix';
  }

  @override
  String subscribeFor(String price, String suffix) {
    return '$price$suffix ile abone ol';
  }

  @override
  String get noChargeTodayCancel =>
      'Bugün ücret yok · istediğin zaman iptal et';

  @override
  String get chargedTodayCancel =>
      'Bugün ücretlendirilir · istediğin zaman iptal et';

  @override
  String get everyCardForYouMark => 'senin';

  @override
  String get trialStartedNoPayment =>
      'Deneme başladı. Bu sürümde ödeme bağlı değil.';

  @override
  String get thatDidNotGoThrough => 'Bu gerçekleşmedi.';

  @override
  String get plusIsBack => 'Astute+ geri döndü.';

  @override
  String get nothingToRestore => 'Bu hesapta geri yüklenecek bir şey yok.';

  @override
  String get planYearly => 'Yıllık';

  @override
  String get planMonthly => 'Aylık';

  @override
  String get perYearShort => '/yıl';

  @override
  String get perMonthShort => '/ay';

  @override
  String get perYear => 'yıllık';

  @override
  String aMonth(String price) {
    return 'ayda $price';
  }

  @override
  String savePercent(int n) {
    return '%$n TASARRUF';
  }

  @override
  String get perMonth => 'aylık';

  @override
  String get billedMonthly => 'aylık faturalandırılır';

  @override
  String get cancelTheTrial => 'Denemeyi iptal et';

  @override
  String get cancelAnyTime => 'İstediğin zaman iptal et';

  @override
  String get cancelAnyTimeNoPayment =>
      'İstediğin zaman iptal et · Bu sürümde ödeme alınmaz';

  @override
  String get restorePurchases => 'Satın alımları geri yükle';

  @override
  String get termsOfUse => 'Kullanım koşulları';

  @override
  String get privacyPolicy => 'Gizlilik';

  @override
  String planPrice(String label, String price, String per) {
    return '$label, $price $per';
  }

  @override
  String get pickASideNoRightAnswer => 'Bir taraf seç. Doğru yanıt yok.';

  @override
  String get estimateCloseEnough => 'Tahmin et. Yakın olmak sayılır.';

  @override
  String get tapToReveal => 'Görmek için dokun';

  @override
  String closeEnoughItIs(String answer) {
    return 'Yeterince yakın · $answer';
  }

  @override
  String youSaidItIsCounted(String given, String answer, String band) {
    return '$given dedin · $answer, ve $band sayıldı';
  }

  @override
  String get youGotIt => 'Bildin';

  @override
  String youSaidItIs(String given, String answer) {
    return '$given dedin · $answer';
  }

  @override
  String get almostEveryoneGetsThisWrong =>
      'Neredeyse herkes bunu yanlış bilir';

  @override
  String lineYouSaidSure(String line, int pct) {
    return '$line · %$pct emin dedin';
  }

  @override
  String get giveMeANudge => 'Bir ipucu ver';

  @override
  String get beingRightMattersLess =>
      'Haklı olmak, ne sıklıkla haklı olduğunu bilmekten daha az önemlidir.';

  @override
  String get writeItBeforeTheirs => 'Onlarınkini okumadan önce yaz.';

  @override
  String get youAnsweredThisOne => 'Bunu yanıtladın.';

  @override
  String difficultyLabel(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'easy': 'Kolay',
      'medium': 'Orta',
      'hard': 'Zor',
      'other': '$id',
    });
    return '$_temp0';
  }

  @override
  String commitBeforeYouTurn(String difficulty) {
    return '$difficulty · çevirmeden önce karar ver.';
  }

  @override
  String get yourAnswer => 'Yanıtın';

  @override
  String get checkMyAnswer => 'Yanıtımı kontrol et';

  @override
  String get howSureAreYou => 'Ne kadar eminsin?';

  @override
  String percentSure(int n) {
    return 'yüzde $n emin';
  }

  @override
  String get inOneLineWhy => 'Tek satırda — neden?';

  @override
  String get because => 'Çünkü…';

  @override
  String get nowShowMeTheOtherSide => 'Şimdi bana diğer tarafı göster';

  @override
  String get skipShowMeAnyway => 'Atla — yine de göster';

  @override
  String get youTookCaps => 'SEÇTİĞİN';

  @override
  String get putSimplyCaps => 'KISACASI';

  @override
  String get explainLikeImThree => 'Bir çocuğa anlatır gibi anlat';

  @override
  String get whatTheOtherSideSaysCaps => 'DİĞER TARAF NE DİYOR';

  @override
  String get whatTheOtherSideSays => 'Diğer taraf ne diyor';

  @override
  String theTrap(String trap) {
    return 'Tuzak: $trap';
  }

  @override
  String youTookTheSide(String side) {
    return 'Seçtiğin taraf: $side';
  }

  @override
  String atPercentSure(int n) {
    return ' %$n eminlikle';
  }

  @override
  String youGotThisOne(String sure) {
    return 'Bunu bildin$sure';
  }

  @override
  String youSaidAnswer(String answer, String sure) {
    return '$answer dedin$sure';
  }

  @override
  String get swipeForTheNextOne => 'Sonraki için kaydır';

  @override
  String get thatWasTheOnlyOne => 'Tek kart buydu';

  @override
  String indexOfN(int i, int n) {
    return '$i/$n';
  }

  @override
  String get couldNotRenderCard => 'Kart çizilemedi.';

  @override
  String get textCopiedInstead => 'Onun yerine metin kopyalandı.';

  @override
  String get copiedToClipboard => 'Panoya kopyalandı.';

  @override
  String get rendering => 'Çiziliyor…';

  @override
  String get theSourceGoesWithIt => 'Kaynak da onunla gider';

  @override
  String get fiveADayALittleSharper => 'Günde beş. Biraz daha keskin.';

  @override
  String get shareMyDay => 'Paylaş';

  @override
  String climbedTo(String rung) {
    return 'Bugün seni $rung basamağına çıkardı';
  }

  @override
  String rightOfAsked(int right, int asked) {
    return '$asked sorudan $right doğru';
  }

  @override
  String saidSure(int sure) {
    return '%$sure emin';
  }

  @override
  String cardsCameBack(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n kart geri geldi — yeniden cevapla',
      one: '1 kart geri geldi — yeniden cevapla',
    );
    return '$_temp0';
  }

  @override
  String get cameBack => 'Geri gelenler';

  @override
  String get holdACardYouLike => 'Beğendin mi? Basılı tut';

  @override
  String likedToday(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'bugün $n beğeni',
      one: 'bugün 1 beğeni',
    );
    return '$_temp0';
  }

  @override
  String get liked => 'Beğenilenler';

  @override
  String likedN(int n) {
    return 'Beğenilenler · $n';
  }

  @override
  String get nothingLikedYet => 'Henüz beğenilen yok';

  @override
  String get likeThisPill => 'Bu kartı beğen';

  @override
  String get removeFromLiked => 'Beğenilenlerden çıkar';

  @override
  String get removedFromLiked => 'Beğenilenlerden çıkarıldı.';

  @override
  String get lessLikeThis => 'Bunun gibisi daha az';

  @override
  String get whatYouLikedLandsHere => 'Yeniden okuyacakların';

  @override
  String get holdToLikeLandsHere =>
      'Beğendiğin bir karta basılı tut, buraya gelir — uygulama da sana bunun gibilerinden daha çok verir.';

  @override
  String get tapTheBookmarkLandsHere =>
      'Bir kartın yer imine dokun, buraya gelir — düşünme şeklini değiştirenler, saklanır.';

  @override
  String get nudgeTitle => 'Beşin hazır';

  @override
  String get nudgeFreezeTitle => 'Dondurman tutuyor';

  @override
  String nudgeFreezeBody(String question) {
    return 'Dün kapandı. Bugün: $question';
  }

  @override
  String get nudgeSureTitle => 'Bundan emindin';

  @override
  String nudgeSureBody(String question, int sure) {
    return '$question — %$sure demiştin.';
  }

  @override
  String nudgeTwoWeeksTitle(int read) {
    return 'İki hafta önce $read kart okumuştun';
  }

  @override
  String nudgeTwoWeeksBody(int gap, String question) {
    return 'Güvenin $gap puan sapıyordu. Bugün: $question';
  }

  @override
  String nudgeTwoWeeksBodyNoGap(int answered, String question) {
    return 'Şimdiye kadar $answered cevap. Bugün: $question';
  }

  @override
  String get friends => 'Arkadaşlar';

  @override
  String friendsN(int n) {
    return 'Arkadaşlar · $n';
  }

  @override
  String get yourFriendCode => 'Arkadaş kodun';

  @override
  String get codeCopied => 'Kod kopyalandı.';

  @override
  String get addAFriend => 'Arkadaş ekle';

  @override
  String get theirCode => 'Onun kodu';

  @override
  String get add => 'Ekle';

  @override
  String get noFriendsYet =>
      'Henüz kimse yok. Bir arkadaşınla kod değişin; serileri ve kalibrasyonu karşılaştırın — cevapları asla.';

  @override
  String get friendsNeedAnAccount =>
      'Karşılaştırmak için telefon uygulaması ve bir hesap gerekir. Kodların saklanır.';

  @override
  String get noReaderWithCode => 'Bu kodla bir okuyucu yok.';

  @override
  String get thatsYourOwnCode => 'Bu senin kendi kodun.';

  @override
  String pointsOff(int n) {
    return '$n puan sapma';
  }

  @override
  String get notMeasuredYet => 'henüz ölçülmedi';

  @override
  String get thisWeekByCalibration => 'Bu hafta, kalibrasyona göre';

  @override
  String get notYetToday => 'bugün henüz değil';

  @override
  String nOfSeven(int n) {
    return '7\'de $n';
  }

  @override
  String get you => 'Sen';

  @override
  String get todaysQuestion => 'Günün sorusu';

  @override
  String get right => 'doğru';

  @override
  String get wrong => 'yanlış';

  @override
  String rightAtSure(int sure) {
    return 'doğru, %$sure emin';
  }

  @override
  String wrongAtSure(int sure) {
    return 'yanlış, %$sure emin';
  }

  @override
  String get yourJourney => 'Yolculuğun';

  @override
  String get thePath => 'Yol';

  @override
  String get youAreHere => 'BURADASIN';

  @override
  String reachedOn(String date) {
    return '$date tarihinde ulaşıldı';
  }

  @override
  String readSoFar(int n, int of) {
    return 'Şimdiye kadar $of karttan $n okundu';
  }

  @override
  String nRead(int n) {
    return '$n okundu';
  }

  @override
  String get topLevel => 'En üst seviye';

  @override
  String plusNToday(int n) {
    return 'bugün +$n';
  }

  @override
  String get bySubject => 'Konuya göre';

  @override
  String get pts => 'puan';

  @override
  String nStillWithYou(int n) {
    return '$n hâlâ aklında';
  }

  @override
  String nMoves(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n numara',
    );
    return '$_temp0';
  }

  @override
  String get scoreStartsToday => 'Puanın bugünün beş kartıyla başlıyor.';

  @override
  String get anonymousUsage => 'Kullanım verileri';

  @override
  String get anonymousUsageLine =>
      'Uygulamanın nasıl kullanıldığı — neyin okunduğu, saklandığı ve söylendiği, neyin ters gittiği — sonraki kartlar daha iyi olsun diye. Adın, e-postan ya da yazdıkların asla.';

  @override
  String get usageOn => 'Paylaşılıyor; adın ve sözlerin olmadan.';

  @override
  String get usageOff => 'Artık hiçbir şey ölçülmüyor.';

  @override
  String get yourMix => 'Senin karışımın';

  @override
  String get genresLine =>
      'Atlamak için bir türe dokun. Basılı tut, içindeki üç damar hemen altında açılsın.';

  @override
  String get insideGenre => 'İçinde';

  @override
  String nOfSixOn(int n, int total) {
    return '$total türden $n açık';
  }

  @override
  String get offInYourMix => 'karışımında değil';

  @override
  String continueGenresOn(int on, int total) {
    return 'Devam · $total türden $on açık';
  }

  @override
  String get mixRarely => 'Nadiren';

  @override
  String get mixSometimes => 'Bazen';

  @override
  String get mixOften => 'Sık sık';

  @override
  String get mixALot => 'Çok';

  @override
  String get mixFull => 'Tam';

  @override
  String get forYouChip => 'SANA ÖZEL';

  @override
  String get againChip => 'TEKRAR';

  @override
  String get magicLine =>
      'Her gün senin için seçilmiş beş kart: karışımından, seviyende, daha önce okuduğun hiçbiri yok. Yarından itibaren.';

  @override
  String get everyCardForYou => 'Her kart, senin için seçilmiş.';

  @override
  String get perkOwnTitle => 'Günde beş kart, hepsi senin';

  @override
  String get perkOwnLine =>
      'Senin konu dallarından, senin seviyende, daha önce okuduğun hiçbiri yok. Ücretsizde günde iki.';

  @override
  String get plusCardHeadline => 'Beşi de senin olsun.';

  @override
  String get plusCardLine =>
      'Karışımından, seviyende günde beş kart. Yolculuğun. Tüm arşivin.';

  @override
  String get continueFree => 'Ücretsiz devam et';

  @override
  String get archiveBeforeThisWeek => 'Bu haftadan öncesi';

  @override
  String get weekKeptThreeOwn => 'Bir hafta tamam: yarın beşten üçü senin.';

  @override
  String get perkJourneyLine =>
      'Seviyen, dal dal her konu, aklında kalanlar ve kaçırmaya devam ettiğin hamleler.';

  @override
  String get topOfTheWeek => 'Haftanın en iyileri';

  @override
  String get topOfTheMonth => 'Ayın en iyileri';

  @override
  String topIn(String subject) {
    return '$subject: en iyiler';
  }

  @override
  String get topLineWeek =>
      'Son 7 günde en çok beğenilen, saklanan ve anlatılanlar';

  @override
  String get topLineMonth =>
      'Son 30 günde en çok beğenilen, saklanan ve anlatılanlar';

  @override
  String get topWeek => 'Hafta';

  @override
  String get topMonth => 'Ay';

  @override
  String topReaders(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n okur',
      one: '1 okur',
    );
    return '$_temp0';
  }

  @override
  String get topEmpty =>
      'Listede henüz bir şey yok. Beğendiğin, sakladığın ya da anlattığın her kart sayılır.';

  @override
  String get readMark => 'Okundu';

  @override
  String get lovedSinceTheStart => 'Başından beri en sevilenler';

  @override
  String lovedIn(String subject) {
    return '$subject alanında en sevilenler';
  }

  @override
  String get lovedLine =>
      'Okurların en çok sakladığı ve senin henüz okumadığın kartlar';

  @override
  String get forYouShelf => 'Senin için';

  @override
  String get forYouLine => 'Okumanın öne çıkardıkları';

  @override
  String get exploreOffline =>
      'Çevrimdışısın. Bu, Keşfet\'in en son okunduğu hâli.';

  @override
  String get askYourselfCaps => 'KENDİNE SOR';

  @override
  String get themeMyths => 'Çürütülen mitler';

  @override
  String get themeMythsLine =>
      'Neredeyse herkesin inandığı ve neden yanlış olduğu';

  @override
  String get themeParadoxes => 'Paradokslar';

  @override
  String get themeParadoxesLine =>
      'İkisi birden doğru olmaması gereken iki doğru';

  @override
  String get themeNumbers => 'Şaşırtan sayılar';

  @override
  String get themeNumbersLine => 'Sürprizin sayıda olduğu yerler';

  @override
  String get themePractical => 'Bugün kullan';

  @override
  String get themePracticalLine => 'Bu akşamdan önce denenecek bir şey';

  @override
  String get themeOrigins => 'Nereden geldi';

  @override
  String get themeOriginsLine => 'Her gün kullandığın şeylerin başlangıcı';

  @override
  String get themeStories => 'Gerçek hikâyeler';

  @override
  String get themeStoriesLine => 'Gerçekten yaşanmış şeyler';

  @override
  String get themeDebates => 'Taraf seç';

  @override
  String get themeDebatesLine =>
      'Doğru cevap yok, yalnızca daha iyi bir argüman';

  @override
  String get themeWorkItOut => 'Hesapla';

  @override
  String get themeWorkItOutLine => 'Kafandan bulunacak bir sayı';

  @override
  String get themeSeen => 'Görmek için';

  @override
  String get themeSeenLine => 'Fikrini çizen kartlar';

  @override
  String get themeSharpest => 'En keskinler için';

  @override
  String get themeSharpestLine => 'En zor kartlar';

  @override
  String get themePast0 => 'Antik dünya';

  @override
  String get themePast1 => '17. ile 19. yüzyıl';

  @override
  String get themePast2 => 'Geçen yüzyıl';

  @override
  String get themePastLine => 'Her döndüğünde başka bir çağ';

  @override
  String get themePlace0 => 'Asya ve Orta Doğu';

  @override
  String get themePlace1 => 'Amerika kıtası';

  @override
  String get themePlace2 => 'Avrupa';

  @override
  String get themePlaceLine => 'Her döndüğünde dünyanın başka bir yeri';

  @override
  String get themeTrueOrFalse => 'Doğru mu yanlış mı?';

  @override
  String get themeTrueOrFalseLine =>
      'Çevirmeden önce karar ver. Çoğu kişi yanılır';

  @override
  String get themeReasoning => 'Sadece akıl yürütme';

  @override
  String get themeReasoningLine =>
      'Ezberlenecek bir şey yok: sadece düşünme yolu';

  @override
  String get themeIdeas => 'Büyük fikirler';

  @override
  String get themeIdeasLine =>
      'Şeylerin ardındaki teori, her seferinde bir fikir';

  @override
  String get themeCurious => 'Sadece merak';

  @override
  String get themeCuriousLine => 'Nedenini bilmenin keyfi için';

  @override
  String get themeMoving => 'Hareket halinde';

  @override
  String get themeMovingLine => 'Şu an değişenler ve neden önemli oldukları';

  @override
  String get themeHowItWorks => 'Gerçekte nasıl çalışır';

  @override
  String get themeHowItWorksLine =>
      'Her gün gördüğün bir şeyin ardındaki mekanizma';

  @override
  String get themePuzzles => 'Bulmacalar';

  @override
  String get themePuzzlesLine => 'Bir kalem ve bir dakikalık bilmeceler';

  @override
  String get weekRecapCaps => 'BU HAFTA KENDİNE SORDUN';

  @override
  String get weekRecapLine => 'Kartlarının sana bıraktığı sorular';

  @override
  String weekRecapMore(int n) {
    return 'Plus ile haftandan $n tane daha';
  }

  @override
  String get plusInTheApp =>
      'Astute+ uygulamada: ücretsiz denemeni başlatmak için Astute\'u iPhone veya Android\'e indir.';

  @override
  String get purchaseComplete => 'Satın alma tamamlandı.';

  @override
  String get successWelcome => 'Astute+’a hoş geldin. Bugünün beş kartı hazır.';

  @override
  String successWelcomeNamed(String name) {
    return 'Astute+’a hoş geldin, $name. Bugünün beş kartı hazır.';
  }

  @override
  String get successFiveCards => 'Günde 5 kart';

  @override
  String get successArchive => 'Tüm arşiv';

  @override
  String successPlanName(String plan) {
    return 'Astute+ $plan';
  }

  @override
  String successFreeUntil(String date, String price, String suffix) {
    return '$date tarihine kadar ücretsiz, sonra $price$suffix';
  }

  @override
  String successRenewsLine(String date, String price, String suffix) {
    return '$date tarihinde yenilenir · $price$suffix';
  }

  @override
  String get successReceipt => 'Makbuz';

  @override
  String get letsStart => 'Başlayalım';

  @override
  String successFootFirstCharge(String date) {
    return 'İlk ödeme $date · istediğin zaman iptal et';
  }

  @override
  String successFootRenews(String date) {
    return '$date tarihinde yenilenir · istediğin zaman iptal et';
  }

  @override
  String get tryToday => 'BUGÜN DENE';

  @override
  String minutesShort(int n) {
    return '$n DK';
  }

  @override
  String get sideOr => 'ya da';

  @override
  String get nextStep => 'Sonraki adım';

  @override
  String get showAllSteps => 'Tümünü göster';

  @override
  String get revealSeePicture => 'Çizime bak';

  @override
  String get revealPlayScene => 'Kendin dene';

  @override
  String get revealBackToAnswer => 'Cevaba dön';

  @override
  String get revealShowWorking => 'Çözümü göster';

  @override
  String get sceneLockIn => 'ONAYLA';

  @override
  String get sceneYou => 'SEN';

  @override
  String get sceneTruth => 'GERÇEK';

  @override
  String get sceneTryAgain => 'Tekrar';

  @override
  String get sceneDrawHint => 'Tahminini parmağınla çiz';

  @override
  String get sceneHoldHint => 'Basılı tut';

  @override
  String get sceneSwipeHint => 'Kaydır ya da dokun';

  @override
  String get sceneTapToPick => 'Seçimine dokun';

  @override
  String get sceneShowMe => 'Göster';

  @override
  String get sceneYourGuess => 'Tahminin';

  @override
  String sceneNOfM(int n, int m) {
    return '$m içinde $n';
  }

  @override
  String get reportProblem => 'Bir sorun bildir';

  @override
  String get reportedThanks => 'Bildirildi. Teşekkürler.';

  @override
  String get reportTitle => 'Bu kartta ne yanlış?';

  @override
  String get reportLead =>
      'Her bildirimi kaynaklarla karşılaştırıp kartı düzeltiyoruz.';

  @override
  String get reportFact => 'Bir bilgi yanlış';

  @override
  String get reportAnswer => 'Doğru diye işaretlenen cevap yanlış';

  @override
  String get reportSource => 'Kaynak bunu desteklemiyor';

  @override
  String get reportUnclear => 'Kafa karıştırıcı';

  @override
  String get reportTypo => 'Bir yazım hatası ya da bozuk bir satır';

  @override
  String get reportOther => 'Başka bir şey';

  @override
  String get reportNoteHint =>
      'Kontrol etmemize yardımcı olacak bir şey (isteğe bağlı)';

  @override
  String get reportSend => 'Gönder';

  @override
  String get reportSentToast => 'Teşekkürler. Kontrol edeceğiz.';

  @override
  String get journeyPointsOff => 'puan sapma';

  @override
  String journeyOffNotYet(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Eminliğini söyleyerek $n cevap daha ver, ölçülsün.',
    );
    return '$_temp0';
  }

  @override
  String get journeyYourScore => 'Puanın';

  @override
  String journeyPointsUnit(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: 'puan');
    return '$_temp0';
  }

  @override
  String journeyGainedIn(String n) {
    return '4 haftada +$n';
  }

  @override
  String journeyWeekSoFar(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Bu hafta şimdiye kadar $n puan kazandın.',
    );
    return '$_temp0';
  }

  @override
  String journeyWeekOf(int n, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$date haftasında $n puan kazandın.',
    );
    return '$_temp0';
  }

  @override
  String journeyCards(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n kart',
      one: '1 kart',
    );
    return '$_temp0';
  }

  @override
  String journeyScoreCaption(String date) {
    return '$date tarihinden beri her haftanın sonundaki puanın. O haftayı görmek için bir noktaya dokun.';
  }

  @override
  String journeyLevelOf(int n, int of) {
    return 'SEVİYE $n / $of';
  }

  @override
  String journeyStepFrom(String what, String rung) {
    return '$what\n$rung için';
  }

  @override
  String journeyToGoCards(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n kart',
      one: '1 kart',
    );
    return '$_temp0';
  }

  @override
  String journeyToGoAnswers(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n cevap',
    );
    return '$_temp0';
  }

  @override
  String journeyToGoSure(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'eminliğini söylediğin $n cevap',
    );
    return '$_temp0';
  }

  @override
  String journeyToGoHeld(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'tutulacak $n kart',
    );
    return '$_temp0';
  }

  @override
  String journeyToGoPoints(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n puan',
    );
    return '$_temp0';
  }

  @override
  String get journeyWorth => 'Karşılığı';

  @override
  String journeyBooks(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n kitap',
    );
    return '$_temp0';
  }

  @override
  String journeyOrDocumentaries(int h) {
    return 'ya da $h sa belgesel';
  }

  @override
  String journeyToFirstBook(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'ilk kitaba $n kart',
    );
    return '$_temp0';
  }

  @override
  String get journeyInARow => 'Üst üste';

  @override
  String journeyDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n gün',
      one: '1 gün',
    );
    return '$_temp0';
  }

  @override
  String journeyBestActive(int best, int active, int days) {
    return 'Rekor $best · $days günden $active';
  }

  @override
  String journeySubjectsOf(int n, int of) {
    return '$n / $of';
  }

  @override
  String journeySubjectsDashed(String month) {
    return 'konu · kesikli: $month';
  }

  @override
  String get journeySubjects => 'konu';

  @override
  String get journeyHowHard => 'Zorluk';

  @override
  String get journeyOfThree => '/ 3';

  @override
  String get journeyHardNow => 'Açtığın kartlar.';

  @override
  String journeyHardThen(String v, String month) {
    return 'Açtığın kartlar. $month ayında $v';
  }

  @override
  String get journeyReadingTime => 'Okuma süresi';

  @override
  String journeyHoursMinutes(int h, String m) {
    return '$h sa $m';
  }

  @override
  String journeyMinutes(int m) {
    return '$m dk';
  }

  @override
  String journeyMinAWeek(int now, int was) {
    return 'haftada $now dk, başta $was';
  }

  @override
  String journeyMinThisWeek(int m) {
    return 'bu hafta $m dk';
  }

  @override
  String get journeyTimedFromToday => 'Bugünden itibaren sayılıyor';

  @override
  String journeyPointsOffFrom(int was) {
    return 'puan sapma, başta $was';
  }

  @override
  String journeyRungOrLess(String rung, int n) {
    return '$rung · en fazla $n';
  }

  @override
  String get journeyRightWhenSure => 'Emin olunca doğru';

  @override
  String journeyFromIn(String v, String month) {
    return '$month ayında $v idi';
  }

  @override
  String get journeySureNone => 'Henüz %80 ya da üstü demedin';

  @override
  String get journeyMovesTitle => 'Fark ettiğin numaralar';

  @override
  String journeyOfN(int n) {
    return '/ $n';
  }

  @override
  String journeyNewest(String name) {
    return 'En yenisi: $name';
  }

  @override
  String get journeyNoneYet => 'Henüz yok';

  @override
  String journeyStillWithYou(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'kart hâlâ aklında',
    );
    return '$_temp0';
  }

  @override
  String journeyRecallDays(int right, int of, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days gün',
      one: 'bir gün',
    );
    return '$_temp0 sonra $of karttan $right';
  }

  @override
  String journeyRecallWeeks(int right, int of, int weeks) {
    String _temp0 = intl.Intl.pluralLogic(
      weeks,
      locale: localeName,
      other: '$weeks hafta',
      one: 'bir hafta',
    );
    return '$_temp0 sonra $of karttan $right';
  }

  @override
  String journeyActiveDays(int active, int days) {
    return '$days günün $active günü';
  }

  @override
  String get journeyMostlyMorning => 'Genelde sabah';

  @override
  String get journeyMostlyAfternoon => 'Genelde öğleden sonra';

  @override
  String get journeyMostlyEvening => 'Genelde akşam';

  @override
  String get journeyMostlyNight => 'Genelde gece';

  @override
  String get journeyInTime => 'Zamanda';

  @override
  String journeyYears(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '$nString yıl';
  }

  @override
  String journeyFromEra(String era) {
    return '$era ile günümüz arasında';
  }

  @override
  String get journeyEraAncient => 'Antik Çağ';

  @override
  String get journeyEraMedieval => 'Orta Çağ';

  @override
  String get journeyEraEarlyModern => '1500\'ler';

  @override
  String get journeyEraNineteenth => '1800\'ler';

  @override
  String get journeyEraTwentieth => '1900\'ler';

  @override
  String get journeyEraRecent => '2000';

  @override
  String get journeyNothingDated => 'henüz tarihli bir şey yok';

  @override
  String get journeyInPlace => 'Dünyada';

  @override
  String journeyRegions(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n bölge',
    );
    return '$_temp0';
  }

  @override
  String journeyPlacesAndSpace(String list) {
    return '$list ve uzay';
  }

  @override
  String get journeyRegionAmericas => 'Amerika kıtası';

  @override
  String get journeyRegionEurope => 'Avrupa';

  @override
  String get journeyRegionAsia => 'Asya';

  @override
  String get journeyRegionOceania => 'Okyanusya';

  @override
  String get journeyRegionAfrica => 'Afrika';

  @override
  String get journeyRegionMiddleEast => 'Orta Doğu';

  @override
  String get journeyNoPlace => 'henüz bir yer yok';

  @override
  String get journeyTopics => 'Alt konular';

  @override
  String journeyMet(int n) {
    return '$n keşfedildi';
  }

  @override
  String journeyTopicsMost(int n, String subject) {
    return '$n tanesi $subject konusunda';
  }

  @override
  String get journeyWords => 'Kelimeler';

  @override
  String journeyNew(int n) {
    return '$n yeni';
  }

  @override
  String get aMove => 'Bir hamle';

  @override
  String get anotherOne => 'Başka';

  @override
  String answerIs(String said) {
    return 'Cevap: $said';
  }

  @override
  String get answeredAlready => 'Zaten cevaplandı';

  @override
  String get anyCard => 'Her konu, her raf, tek kart';

  @override
  String betN(int n) {
    return '$n yatır';
  }

  @override
  String get betSlip => 'Kuponun';

  @override
  String get betWord => 'Yatır';

  @override
  String get biggerLabel => 'Daha büyük';

  @override
  String get biggerNote => 'Her sayı bir kartın kendi cevabı.';

  @override
  String biggerScore(int right, int asked) {
    return '$asked soruda $right doğru.';
  }

  @override
  String get biggerYouGotIt => 'Daha büyük · bildin';

  @override
  String cameBackAfterDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n gün sonra',
      one: 'Bir gün sonra',
    );
    return '$_temp0';
  }

  @override
  String get cameBackAfterWeek => 'Bir hafta sonra';

  @override
  String cameBackAfterWeeks(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n hafta sonra',
      one: 'Bir hafta sonra',
    );
    return '$_temp0';
  }

  @override
  String get check => 'Kontrol et';

  @override
  String closerDone(String said, int right, int steps) {
    return 'Cevap $said. $steps adımda $right doğru.';
  }

  @override
  String closerNoLess(String v) {
    return 'Hayır: $v değerinden az.';
  }

  @override
  String closerNoMore(String v) {
    return 'Hayır: $v değerinden fazla.';
  }

  @override
  String get closerStart => 'Yaklaşmak için üç adım.';

  @override
  String closerYesLess(String v) {
    return 'Doğru: $v değerinden az.';
  }

  @override
  String closerYesMore(String v) {
    return 'Doğru: $v değerinden fazla.';
  }

  @override
  String get corrections => 'Düzeltmeler';

  @override
  String get didYouKnow => 'Biliyor muydun?';

  @override
  String get didYouKnowLine =>
      'Çevir, sonra: senin için yeni mi, yoksa biliyor muydun?';

  @override
  String get dragToSet => 'Ayarlamak için kaydır';

  @override
  String get dykAgain => 'Tekrar';

  @override
  String dykKnew(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n tanesini biliyordun',
      one: '1 tanesini biliyordun',
      zero: 'Bildiğin yok',
    );
    return '$_temp0';
  }

  @override
  String dykNew(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n tanesi yeni',
      one: '1 tanesi yeni',
      zero: 'Bugün yeni bir şey yok',
    );
    return '$_temp0';
  }

  @override
  String get editionEnd => 'Bugünün baskısı bu kadar';

  @override
  String get editionTomorrow => 'Yarınki sabah çıkıyor';

  @override
  String get eraAncient => 'Antik dünya';

  @override
  String get eraAncientWhen => '500\'den önce';

  @override
  String get eraEarlyModern => 'Erken modern çağ';

  @override
  String get eraEarlyModernWhen => '1500\'den 1800\'e';

  @override
  String get eraMedieval => 'Orta Çağ';

  @override
  String get eraMedievalWhen => '500\'den 1500\'e';

  @override
  String eraMore(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Bu çağdan $n tane daha',
      one: 'Bu çağdan 1 tane daha',
    );
    return '$_temp0';
  }

  @override
  String get eraNineteenth => '19. yüzyıl';

  @override
  String get eraNineteenthWhen => '1800\'den 1900\'e';

  @override
  String get eraRecent => 'Bu yüzyıl';

  @override
  String get eraRecentWhen => '2000\'den beri';

  @override
  String get eraRulerNow => 'Şimdi';

  @override
  String get eraRulerOld => 'Antik çağ';

  @override
  String get eraShortAncient => 'Antik çağ';

  @override
  String get eraShortEarlyModern => '1500–1800';

  @override
  String get eraShortMedieval => 'Orta Çağ';

  @override
  String get eraShortNineteenth => '1800\'ler';

  @override
  String get eraShortRecent => '2000\'ler';

  @override
  String get eraShortTwentieth => '1900\'ler';

  @override
  String get eraTwentieth => 'Geçen yüzyıl';

  @override
  String get eraTwentiethWhen => '1900\'den 2000\'e';

  @override
  String get fewCards => 'Birkaç kartta';

  @override
  String get fewCardsLine => 'Tek kart açıklamaya yetmediğinde';

  @override
  String get firstLabel => 'İlk';

  @override
  String get forYouNow => 'Senin için, şimdi';

  @override
  String get goNarrow => 'Eminsen dar tut: üç kat kazandırır.';

  @override
  String get hardBadge => 'Zor';

  @override
  String hidesIn(String where) {
    return 'Konu: $where';
  }

  @override
  String get howSure => 'Ne kadar eminim, ve neden?';

  @override
  String get inNumbers => 'Rakamlarla';

  @override
  String inRange(int pts, String said) {
    return 'Aralıkta: +$pts puan. Cevap $said.';
  }

  @override
  String inYourMoves(int n) {
    return 'Hamlelerinde · $n×';
  }

  @override
  String itIs(String said) {
    return 'Cevap $said.';
  }

  @override
  String get knewIt => 'Biliyordum';

  @override
  String get less => 'Daha az';

  @override
  String get lookFirst => 'Başlığa inanmadan önce grafiğe bak.';

  @override
  String get markTried => 'Denedim';

  @override
  String minutesLabel(int n) {
    return '$n dk';
  }

  @override
  String missedRange(String said) {
    return 'Kaçtı: cevap $said.';
  }

  @override
  String get modeBigger => 'Hangisi büyük?';

  @override
  String get modeBiggerLine =>
      'Tahmin edebileceğin iki sayı. Büyük olana dokun';

  @override
  String get modeCloser => 'Yaklaş';

  @override
  String get modeCloserLine =>
      'Sayıya yaklaşmak için üç adım: daha fazla mı, az mı';

  @override
  String get modePick => 'Birini seç';

  @override
  String get modePickLine => 'Üç değer. Kartı açmadan önce karar ver';

  @override
  String get modeRange => 'Aralığa oyna';

  @override
  String get modeRangeLine => 'Ne kadar dar, o kadar çok kazandırır, bilirsen';

  @override
  String get modeSlide => 'Kaydır';

  @override
  String get modeSlideLine =>
      'Önce cevabını ayarla, sonra ne kadar yanıldığını gör';

  @override
  String get modeStake => 'Bahsini koy';

  @override
  String modeStakeLine(int n) {
    return 'Günde $n puan. Kazanırsan bahsin ikiye katlanır';
  }

  @override
  String get monthShelfLine => 'Her ay yeni bir konu, herkes için aynı';

  @override
  String moodMeta(int cards, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      cards,
      locale: localeName,
      other: '$cards kart',
    );
    return '$_temp0 · $minutes dk';
  }

  @override
  String get moodTime => 'Ne kadar vaktin var';

  @override
  String get moodTitle => 'Ruh halin, dakikaların';

  @override
  String get moodTone => 'Ton';

  @override
  String get more => 'Daha fazla';

  @override
  String moreOrLess(String v) {
    return '$v değerinden fazla mı, az mı?';
  }

  @override
  String get moveComparedToWhat => 'Neye göre';

  @override
  String get moveComparedToWhatLine =>
      'Kontrol grubu olmadan bir değişim hiçbir şey ifade etmez';

  @override
  String get moveSampling => 'Örneklem';

  @override
  String get moveSamplingLine =>
      'Örnekleme kimin girdiği, ne söyleyebileceğini belirler';

  @override
  String mythDeckHint(int at, int of) {
    return '$at/$of · çevirmek için kaydır';
  }

  @override
  String nOfM(int at, int of) {
    return '$at/$of';
  }

  @override
  String get newMove => 'Senin için yeni';

  @override
  String get newToMe => 'Benim için yeni';

  @override
  String get notEnoughPoints => 'Yeterli puan yok';

  @override
  String get notSureLine => 'Astute\'un herhangi bir yerinden tek kart';

  @override
  String get notSureTitle => 'Nereden başlayacağını bilmiyor musun?';

  @override
  String get openWord => 'Aç';

  @override
  String get pickOneFirst => 'Önce birini seç';

  @override
  String pointsToday(int n) {
    return 'bugün +$n';
  }

  @override
  String get puzzleOfTheDay => 'Günün bulmacası';

  @override
  String rangeWidth(int w, int pts) {
    return '±$w · $pts p';
  }

  @override
  String get rightLastTime => 'Geçen sefer doğru';

  @override
  String get sameForEveryoneCaps => 'Herkes için aynı';

  @override
  String get sayFalse => 'Yanlış';

  @override
  String get sayTrue => 'Doğru';

  @override
  String get seriesAnchors => 'İlk izlenimler';

  @override
  String get seriesGrowth => 'Kontrolden çıkan sayılar';

  @override
  String seriesMeta(int n, int m) {
    return '$n kart · yaklaşık $m dk';
  }

  @override
  String get seriesOdds => 'Yalan söyleyen olasılıklar';

  @override
  String get seriesRetold => 'Yeniden anlatılan tarih';

  @override
  String seriesStrand(String name) {
    return 'Birkaç kartta $name';
  }

  @override
  String get seriesStudies => 'Araştırmalar neden yanıltır';

  @override
  String showAllN(int n) {
    return 'Hepsini göster ($n)';
  }

  @override
  String get showFewer => 'Daha az göster';

  @override
  String get sixtyAgain => 'Tekrar oyna';

  @override
  String sixtyIn(int s) {
    return '$s saniyede';
  }

  @override
  String get sixtyLine => 'Sekiz doğru mu yanlış mı. İçgüdünle git';

  @override
  String get sixtyPerfect => 'Sekizi de doğru.';

  @override
  String sixtyScore(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Şimdiye kadar $n doğru',
      zero: 'Henüz doğru yok',
    );
    return '$_temp0';
  }

  @override
  String get sixtySecondsFor => 'saniyede sekiz\ndoğru mu yanlış mı';

  @override
  String sixtySecondsLeft(int s) {
    return '$s sn';
  }

  @override
  String get sixtyStart => 'Başla';

  @override
  String get sixtyTimeUp => 'süre dolmadan önce';

  @override
  String get sixtyTitle => 'Altmış saniye';

  @override
  String slideAverage(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Ortalamada $n puan sapma.',
      zero: 'Ortalamada tam isabet.',
    );
    return '$_temp0';
  }

  @override
  String get slideNote => 'Ayarla, kontrol et. Önemli olan ne kadar saptığın.';

  @override
  String slideOff(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n puan saptın.',
      zero: 'Tam isabet.',
    );
    return '$_temp0';
  }

  @override
  String get slipEmpty => 'Henüz bahis yok. Her bahsin buraya düşer.';

  @override
  String get stakeLabel => 'Bahis';

  @override
  String stepOf(int at, int of) {
    return 'Adım $at/$of';
  }

  @override
  String get surpriseMe => 'Beni şaşırt';

  @override
  String get tapIfBigger => 'Büyükse dokun';

  @override
  String get tapToTurn => 'Çevirmek için dokun';

  @override
  String get tfRight => 'Doğru. Nedenini görmek için aç.';

  @override
  String tfWrong(String side) {
    return 'Cevap: $side. Nedenini görmek için aç.';
  }

  @override
  String theAnswer(String said) {
    return 'Cevap: $said.';
  }

  @override
  String get theAstute => 'The Astute';

  @override
  String get theLead => 'Manşet';

  @override
  String get throughTime => 'Zamanda yolculuk';

  @override
  String get throughTimeLine => 'Antik dünyadan bu yıla. Gezmek için kaydır';

  @override
  String get todayLabel => 'Bugün';

  @override
  String get todaysEdition => 'Bugünün baskısı';

  @override
  String get toneCurious => 'Meraklı';

  @override
  String get toneLight => 'Hafif';

  @override
  String get toneSerious => 'Ciddi';

  @override
  String get toneTough => 'Zorlu';

  @override
  String get unmaskBack => 'Yayımlandığı gibi göster';

  @override
  String get unmaskFlipped => 'Doğru yöne çevir';

  @override
  String get unmaskLine => 'Aynı sayılar, farklı bir tablo';

  @override
  String get unmaskStretched => 'Adil bir ölçek kullan';

  @override
  String get unmaskTitle => 'Grafiğin maskesini düşür';

  @override
  String get unmaskTotals => 'Karşılaştırmayı adil yap';

  @override
  String get unmaskTruncated => 'Ekseni sıfırdan başlat';

  @override
  String get unmaskWindow => 'Serinin tamamını göster';

  @override
  String get whatIfTrue => 'Ya doğruysa?';

  @override
  String get whatIfTrueLine =>
      'Kapattıktan sonra da işlemeye devam eden kartlar';

  @override
  String get whatYouBelieve => 'İnandıkların';

  @override
  String get wrongLastTime => 'Geçen sefer yanlış';

  @override
  String youLose(int n) {
    return '$n kaybettin.';
  }

  @override
  String youWin(int n) {
    return '$n kazandın.';
  }

  @override
  String get yourPick => 'Senin seçimin';
}

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
  String dayTitle(int n) {
    return '$n. gün';
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
  String get share => 'Paylaş';

  @override
  String cardOf(int k, int n) {
    return '$n karttan $k.';
  }

  @override
  String tomorrowsFiveOpenIn(String when) {
    return 'Yarının beşlisi · $when sonra';
  }

  @override
  String topicOpensTomorrow(String topic, String when) {
    return 'Yarın: $topic · $when sonra';
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
    return '«$query» için henüz bir şey yok.';
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
    return '«$query» için bir şey yok. Bir konu dene.';
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
  String get backToTodaysFive => 'Bugünün beşlisine dön';

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
  String scoreLevel(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'curiosity': 'Merak',
      'observation': 'Gözlem',
      'method': 'Yöntem',
      'judgement': 'Muhakeme',
      'insight': 'Kavrayış',
      'discernment': 'Basiret',
      'acumen': 'Feraset',
      'other': '$id',
    });
    return '$_temp0';
  }

  @override
  String get levelUpTitle => 'Yeni seviye';

  @override
  String levelUpGain(String skill, String n) {
    return 'Bu haftaki en büyük artışın: $skill, $n';
  }

  @override
  String levelUpAnswers(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Şimdiye kadar $n yanıt.',
      one: 'Şimdiye kadar 1 yanıt.',
    );
    return '$_temp0';
  }

  @override
  String get levelLabel => 'Seviye';

  @override
  String levelPointsTo(int n, String level) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$level için $n puan',
      one: '$level için 1 puan',
    );
    return '$_temp0';
  }

  @override
  String levelAnswersTo(int n, String level) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$level için $n yanıt',
      one: '$level için 1 yanıt',
    );
    return '$_temp0';
  }

  @override
  String get levelTop => 'En yüksek seviye';

  @override
  String get levelShareTitle => 'Seviyeni paylaş';

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
  String deleteAccountBody(String store) {
    String _temp0 = intl.Intl.selectLogic(store, {
      'apple': 'abonelik App Store ayarlarından yönetilir.',
      'google': 'abonelik Google Play\'de, Ödemeler ve abonelikler bölümünden yönetilir.',
      'other': 'abonelik, satın aldığın mağazadan yönetilir.',
    });
    return 'Hesabın ve yedeği kalıcı olarak silinir ve bu cihaz en baştan başlar. Bu, Astute+ aboneliğini iptal etmez: $_temp0';
  }

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
  String get profileTodayFive => 'Bugünün beşi';

  @override
  String profileTodayOf(int read, int of) {
    return '$of karttan $read';
  }

  @override
  String profileTodayToRead(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n okunacak',
    );
    return '$_temp0';
  }

  @override
  String get profileJourneyScores => 'Tüm puanların, hafta hafta';

  @override
  String profileInARowLabel(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'gün üst üste',
    );
    return '$_temp0';
  }

  @override
  String get profileWeekTitle => 'Son 7 gün';

  @override
  String profileWeekPoints(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: 'puan');
    return '$_temp0';
  }

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
  String get yourCards => 'Kartların';

  @override
  String get emptyLikedHint => 'Beğendiğin bir karta basılı tut';

  @override
  String get emptySavedHint => 'Bir kartın yer imine dokun';

  @override
  String get lastSevenDays => 'Son 7 gün';

  @override
  String get accountSection => 'Hesap';

  @override
  String get aboutSection => 'Hakkında';

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
  String get howStep2Title => 'Kaynaklı, sonra bir eleştirmen okur';

  @override
  String get howStep2Line =>
      'Her kart bilgilerinin nereden geldiğini söyler ve dörtte üçü tek dokunuşla asıl kaynağa götürür, böylece kendin kontrol edebilirsin. Çoğunu eleştirmen rolündeki ikinci bir model okur; doğrulayamadıkları, bir kişinin kontrol ettiği bir listeye girer. O liste henüz boş değil.';

  @override
  String get howStep3Title => 'Her sabah beş kart';

  @override
  String get howStep3Line =>
      'Seçtiğin konulardan, henüz okumadığın kartlar. Doğru bildiğin bir kart, aklında kalıp kalmadığını görmek için sonra geri gelir.';

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
  String get howFoot =>
      'Her bildirimi okuyoruz; bir kartı savunmaktansa düzeltmeyi tercih ederiz.';

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
  String get shareMyRecord => 'Sicilimi paylaş';

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
  String get seeThePlans => 'Planları gör';

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
  String get comebackTitle => 'Seni yeniden görmek güzel.';

  @override
  String get comebackStillYours => 'Hâlâ senin';

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
  String get reminderAskTitle => 'Sana ne zaman hatırlatalım?';

  @override
  String get reminderAskLine => 'Günde bir bildirim, kartlarından bir soruyla.';

  @override
  String get reminderAskTrialLine =>
      'Ücretsiz denemen bitmeden iki gün önce sana hatırlatacağız.';

  @override
  String get reminderAskMorning => 'Sabah';

  @override
  String get reminderAskLunch => 'Öğle arası';

  @override
  String get reminderAskEvening => 'Akşam';

  @override
  String get reminderAskOther => 'Başka bir saat';

  @override
  String get reminderAskPick => 'Sen seç';

  @override
  String get reminderAskUsual => 'Genelde okuduğun saat';

  @override
  String get reminderAskYes => 'Hatırlat';

  @override
  String get reminderAskNotNow => 'Şimdi değil';

  @override
  String get placeAskTitle => 'Yaşadığın yer hakkında kartlar';

  @override
  String get placeAskLine =>
      'Astute arada bir sana yaşadığın yer hakkında bir kart verecek — tarihi, bilimi, sürprizleri.';

  @override
  String get placeOnlyCity => 'Yalnızca şehrin saklanır, tam konumun asla.';

  @override
  String get placeAskPreviewLine => 'Yakınında · Modena';

  @override
  String get placeAskPreviewQuestion => 'Ghirlandina eğik. Ne kadar?';

  @override
  String get placeAskYes => 'Konumumu kullan';

  @override
  String get placeAskNotNow => 'Şimdi değil';

  @override
  String get placeRowTitle => 'Yaşadığın yer';

  @override
  String get placeRowOff => 'Kapalı';

  @override
  String get placeRowOffLine => 'Yaşadığın yer hakkında kartlar için aç.';

  @override
  String get placeSwitchOn => 'Aç';

  @override
  String get placeUseNow => 'Konumumu şimdi kullan';

  @override
  String get placeRemove => 'Kaldır';

  @override
  String placeSetTo(String place) {
    return 'Yaşadığın yer: $place';
  }

  @override
  String get placeRemoved =>
      'Kaldırıldı. Astute artık nerede yaşadığını saklamıyor.';

  @override
  String get placeNotFound =>
      'Şu anda nerede olduğun bulunamadı. Astute başka bir gün yeniden deneyecek.';

  @override
  String get placeDeniedNote =>
      'Sorun değil. İstediğin zaman Profil\'den açabilirsin.';

  @override
  String get placeServicesOff =>
      'Bu telefonda konum kapalı. Ayarlar\'dan aç ve yeniden dene.';

  @override
  String get placeNotHere => 'Bu cihaz nerede olduğunu söyleyemiyor.';

  @override
  String get placeSettingsTitle => 'Astute için konum kapalı';

  @override
  String get placeSettingsBody =>
      'Yaşadığın yer hakkında kartlar almak için Ayarlar\'da Astute\'un konumunu kullanmasına izin ver. Yalnızca şehrin saklanır.';

  @override
  String get placeSettingsOpen => 'Ayarları aç';

  @override
  String trialWarningTitle(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Astute+ ücretsiz denemen $days gün sonra bitiyor.',
      one: 'Astute+ ücretsiz denemen yarın bitiyor.',
      zero: 'Astute+ ücretsiz denemen bugün bitiyor.',
    );
    return '$_temp0';
  }

  @override
  String trialWarningBody(String date, String price, String path) {
    return '$date tarihinde yıllık aboneliğin $price ile başlıyor. Devam etmek için hiçbir şey yapman gerekmiyor. İptal etmek için: $path.';
  }

  @override
  String trialEndsNotice(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Ücretsiz denemen $days gün sonra bitiyor',
      one: 'Ücretsiz denemen yarın bitiyor',
      zero: 'Ücretsiz denemen bugün bitiyor',
    );
    return '$_temp0';
  }

  @override
  String get trialNoticeManage => 'Yönet';

  @override
  String subjectsInTheMix(int n, int total) {
    return 'Karışımda $total konudan $n';
  }

  @override
  String get everythingIsInDrag =>
      'Her şey içeride. Daha az görmek için bir konuyu sola kaydır, çıkarmak için sonuna kadar.';

  @override
  String get next => 'İleri';

  @override
  String get whatShouldWeTalkAbout => 'Ne hakkında konuşalım?';

  @override
  String get fivePillsADayPick =>
      'Günde beş kart, her sabah yenileri. Karışımda istediğin konuları seç — sonra değiştirebilirsin.';

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
  String get tagline =>
      'Olayların nedenini anla, bildiklerine ne kadar güvenebileceğini gör';

  @override
  String get introTopicsTitle => 'Yirmi konu, beş kart';

  @override
  String get introTopicsLine =>
      'Bir model tarafından önceden yazılır, her biri kaynağını belirtir.';

  @override
  String get introQuestionTitle => 'Bir soru, ne kadar emin, sonra neden';

  @override
  String get introQuestionLine =>
      'Önce ne kadar eminsin, söyle. Zamanla «eminim» sözünün değerini görürsün.';

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
  String get startReading => 'Okumaya başla';

  @override
  String get haveAnAccount => 'Hesabın var mı?';

  @override
  String get signInLink => 'Giriş yap';

  @override
  String get signInWelcomeTitle => 'Tekrar hoş geldin';

  @override
  String get signInWelcomeLine =>
      'Giriş yap; serin, sakladığın kartlar ve sicilin seninle geri gelsin.';

  @override
  String get keepStreakOnNewPhone => 'Serini yeni bir telefona taşı';

  @override
  String get keepStreakTitle => 'Serini kaybetme';

  @override
  String get keepStreakLine =>
      'Giriş yap, yeni bir telefon bu telefonun kaldığı yerden devam etsin: serin, sakladığın kartlar, sicilin.';

  @override
  String get signInNotNow => 'Şimdi değil';

  @override
  String subjectName(String topic) {
    String _temp0 = intl.Intl.selectLogic(topic, {
      'thinking': 'Düşünme',
      'science': 'Bilim',
      'maths': 'Matematik',
      'space': 'Uzay',
      'psychology': 'Psikoloji',
      'economics': 'Ekonomi',
      'technology': 'Teknoloji',
      'history': 'Tarih',
      'human_body': 'İnsan bedeni',
      'philosophy': 'Felsefe',
      'pop_culture': 'Popüler kültür',
      'nature': 'Doğa',
      'language': 'Dil',
      'weird_facts': 'Tuhaf bilgiler',
      'sport': 'Spor',
      'cinema': 'Sinema',
      'music': 'Müzik',
      'art': 'Sanat',
      'medicine': 'Tıp',
      'food': 'Yemek',
      'life': 'Yaşam',
      'other': '$topic',
    });
    return '$_temp0';
  }

  @override
  String get cardsInEnglishNote =>
      'Kartlar şimdilik İngilizce; uygulama senin dilini konuşuyor.';

  @override
  String termsLine(String terms, String privacy) {
    return 'Devam ederek $terms ve $privacy kabul etmiş olursun';
  }

  @override
  String get termsLineTerms => 'Kullanım Koşullarımızı';

  @override
  String get termsLinePrivacy => 'Gizlilik Politikamızı';

  @override
  String get skip => 'Atla';

  @override
  String get tapToRevealLower => 'görmek için dokun';

  @override
  String get barMoveCaps => 'AKILDA KALAN';

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
  String get widgetShelfTitle => 'BUGÜNÜN RAFI';

  @override
  String get widgetShelfFrom => 'Bugünün rafından';

  @override
  String get dayStreakCaps => 'GÜNLÜK SERİ';

  @override
  String sourceLabel(String source) {
    return 'Kaynak · $source';
  }

  @override
  String sourceLabelKind(String kind, String source) {
    return '$kind · $source';
  }

  @override
  String deeperFootLabel(String source) {
    return 'Derinleş. Kaynak: $source';
  }

  @override
  String get sourceKindPaper => 'Araştırma';

  @override
  String get sourceKindBook => 'Kitap';

  @override
  String get sourceKindInstitution => 'Kurum';

  @override
  String get sourceKindDocument => 'Belge';

  @override
  String get sourceKindData => 'Veriler';

  @override
  String get sourceKindReference => 'Başvuru eseri';

  @override
  String get sourceKindNews => 'Gazete';

  @override
  String get sourceKindCompany => 'Şirket kaynağı';

  @override
  String get sourceKindStandard => 'Standart';

  @override
  String get sourceKindArithmetic => 'Hesap';

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
  String get paywallRecordTitle => 'Gerçekten ne kadar bildiğini gör.';

  @override
  String get paywallRecordMark => 'Gerçekten';

  @override
  String get paywallRecordLine =>
      'Her gün ne kadar emin olduğunu söylüyorsun. Astute+, emin olmakla doğru bilmek arasındaki farkın kapanıp kapanmadığını ve kaçırmaya devam ettiğin hamleleri gösterir.';

  @override
  String paywallRecordOver(int sure, int right) {
    return 'Ortalama %$sure emin olduğunu söylüyorsun; doğru cevap oranın %$right. Astute+ bu farkın kapanıp kapanmadığını ve kaçırmaya devam ettiğin hamleleri gösterir.';
  }

  @override
  String paywallRecordUnder(int sure, int right) {
    return 'Ortalama %$sure emin olduğunu söylüyorsun; doğru cevap oranın %$right: sandığından fazlasını biliyorsun. Astute+ bu farkın kapanıp kapanmadığını gösterir.';
  }

  @override
  String paywallRecordEven(int sure, int right) {
    return 'Ortalama %$sure emin olduğunu söylüyorsun; doğru cevap oranın %$right: neredeyse başa baş. Astute+ bunun sürüp sürmediğini ve kaçırmaya devam ettiğin hamleleri gösterir.';
  }

  @override
  String get paywallOutcomeTitle => 'Kimse seni kandıramasın.';

  @override
  String get paywallOutcomeMark => 'kandıramasın.';

  @override
  String get paywallOutcomeLine =>
      'Seviyende günde beş kart. Kaçırdıkların, akılda kalana kadar geri gelir. Ve hafta hafta değiştiğini görürsün.';

  @override
  String get paywallFiveTitle => 'Beşi de senin.';

  @override
  String get paywallFiveMark => 'senin.';

  @override
  String get paywallFiveLine =>
      'Ücretsizde beşten ikisi senin için, bir hafta tamamlayınca üçü. Astute+ beşini de konu dallarından, seviyende seçer ve kaçırdıklarını geri getirir.';

  @override
  String get paywallReadTitle => 'Okudukların, gün gün.';

  @override
  String get paywallReadMark => 'gün gün.';

  @override
  String get paywallReadLine =>
      'Son zamanlarda okuduğun günler, en yenisi önce. Beş kartını açmak için bir güne, yeniden okumak için bir karta dokun.';

  @override
  String get perkGapTitle => 'Farkın kapandığını izle';

  @override
  String get perkGapLine =>
      'Yolculuğun, hafta hafta: ne kadar emin, ne kadar doğru ve kaçırmaya devam ettiğin hamleler.';

  @override
  String get perkOwnFiveTitle => 'Sana ait beş kart';

  @override
  String get perkOwnFiveLine => 'Her gün, seviyende; kaçırdıkların geri gelir.';

  @override
  String get perkReadTitle => 'Okudukların';

  @override
  String get perkReadLine =>
      'Son günlerin, her biri beş kartıyla, yeniden açılmaya hazır.';

  @override
  String get perkAskTitle => 'Asistanın';

  @override
  String get perkAskLine => 'Her kartı anlatır, sonra seni sınar.';

  @override
  String get perkCoachTitle => 'Her hafta bir koç';

  @override
  String get perkCoachLine => 'Nerede yanıldığın, sırada ne çalışacağın.';

  @override
  String get perkNew => 'YENİ';

  @override
  String get threeTitle => 'Bugünün üçlüsü';

  @override
  String threeStep(int n, int total) {
    return '$n / $total';
  }

  @override
  String get threeSame => 'Bugün herkese aynı üç soru. Yaklaşık bir dakika.';

  @override
  String threeYouSaid(String guess) {
    return 'Senin tahminin: $guess.';
  }

  @override
  String threePoints(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '+$n puan',
      zero: 'Puan yok',
    );
    return '$_temp0';
  }

  @override
  String get threeNext => 'Sonraki';

  @override
  String get threeSeeScore => 'Puanını gör';

  @override
  String get threeDone => 'Bugünün üçlüsü · tamam';

  @override
  String get threeYou => 'Sen';

  @override
  String whyMissing(String move) {
    return 'Sık kaçırdığın bir düşünme adımı: $move';
  }

  @override
  String whyMoveAgain(String move) {
    return '$move, yeni bir örnekle yeniden';
  }

  @override
  String get whyAgain => 'İkinci bir bakış için geri geldi';

  @override
  String whyGoal(String goal) {
    return 'Hedefin için: $goal';
  }

  @override
  String whyLiked(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Beğendiğin $n karta benziyor',
    );
    return '$_temp0';
  }

  @override
  String whyHard(String subject) {
    return 'Zor bir kart: $subject konusunda güçlüsün';
  }

  @override
  String whyLevel(String subject) {
    return '$subject konusunda seviyene uygun';
  }

  @override
  String whyGentle(String subject) {
    return '$subject için kolay bir giriş';
  }

  @override
  String whyYourSubject(String subject) {
    return 'Konularından biri: $subject';
  }

  @override
  String get whyRandom => 'Konularından rastgele seçildi';

  @override
  String get whyTitle => 'Neden bu kart';

  @override
  String whyTrains(String move) {
    return 'Çalıştırdığı adım: $move';
  }

  @override
  String whyMet(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n kez karşılaştın.',
    );
    return '$_temp0';
  }

  @override
  String whyRight(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n kez doğru.',
      zero: 'Henüz hiç doğru değil.',
    );
    return '$_temp0';
  }

  @override
  String whyLevelRow(String subject) {
    return '$subject seviyen';
  }

  @override
  String whyLevelWord(String level) {
    String _temp0 = intl.Intl.selectLogic(level, {
      'starting': 'Başlangıç',
      'some': 'Yolda',
      'strong': 'Güçlü',
      'other': 'Yolda',
    });
    return '$_temp0';
  }

  @override
  String get whyLastMetRow => 'Bu adımla son karşılaşman';

  @override
  String whyDaysAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n gün önce',
      one: 'Dün',
      zero: 'Bugün',
    );
    return '$_temp0';
  }

  @override
  String get whyGoalRow => 'Hedefin';

  @override
  String get whyLikedRow => 'Beğendiğin benzer kartlar';

  @override
  String get whyRandomLine =>
      'Ücretsiz planda her günün bir kısmı seçtiğin konulardan rastgele gelir.';

  @override
  String get whyPlusLine =>
      'Astute+ ile beşi de senin için seçilir: seviyene göre, zevkine göre, kaçırdığın adımlar geri döner.';

  @override
  String get whyMakeMine => 'Beşi de benim olsun';

  @override
  String get whyMore => 'Bunun gibi daha çok';

  @override
  String get whyMoreDone => 'Not edildi: bunun gibi daha çok';

  @override
  String get whyLess => 'Daha az';

  @override
  String get whyTune => 'Karışımını ayarla';

  @override
  String get searchTry => 'Dene';

  @override
  String get searchByNeed => 'İhtiyaca göre';

  @override
  String get searchByKind => 'Türe göre';

  @override
  String kindName(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'play': 'Oynanabilir',
      'quiz': 'Testler',
      'estimate': 'Tahminler',
      'debate': 'Tartışmalar',
      'quick': 'Hızlı okumalar',
      'other': 'Kartlar',
    });
    return '$_temp0';
  }

  @override
  String kindCards(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n kart',
    );
    return '$_temp0';
  }

  @override
  String get areaUsefulFor => 'İşine yarar';

  @override
  String areaPaths(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n yol · her biri on kart',
    );
    return '$_temp0';
  }

  @override
  String get areaMoves => 'Burada çalıştığın adımlar';

  @override
  String get areaMoreCards => 'Bunun için daha fazla kart';

  @override
  String get pathKicker => 'Yol';

  @override
  String pathMeta(String subject, int n, int minutes) {
    return '$subject · $n kart · yaklaşık $minutes dk';
  }

  @override
  String pathPartOf(int part, int parts) {
    return 'Bölüm $part / $parts';
  }

  @override
  String pathTrains(String moves) {
    return 'Çalıştırdığı adımlar: $moves';
  }

  @override
  String pathReadOf(int n, int total) {
    return '$total karttan $n tanesi okundu';
  }

  @override
  String get pathFreeTag => 'Ücretsiz';

  @override
  String get pathStart => 'Yola başla';

  @override
  String pathContinueAt(int n) {
    return 'Devam · $n. kart';
  }

  @override
  String get pathContinue => 'Devam';

  @override
  String get notesTitle => 'Notlar';

  @override
  String get noteYours => 'Notun';

  @override
  String get noteAdd => 'Not ekle';

  @override
  String get noteEdit => 'Düzenle';

  @override
  String get noteSave => 'Kaydet';

  @override
  String get noteDelete => 'Notu sil';

  @override
  String get noteHint => 'Bu karttan neyi hatırlamak istiyorsun?';

  @override
  String get notesEmpty =>
      'Henüz not yok. Kaydettiğin bir kartı aç ve hatırlamak istediğini yaz.';

  @override
  String get pathUnlock => 'Tüm yolların kilidini aç';

  @override
  String get pathFreeLine => 'Her yolun ilk iki kartı ücretsizdir.';

  @override
  String pathNextPart(int n) {
    return 'Bölüm $n: daha derine';
  }

  @override
  String pathDeeperLine(int n) {
    return 'Aynı temada $n kart daha, daha zor.';
  }

  @override
  String get pathAgain => 'Yeniden oku';

  @override
  String get subjectKicker => 'Konu';

  @override
  String subjectReadOf(int n, int total) {
    return '$total karttan $n tanesi okundu';
  }

  @override
  String subjectRight(int right, int answered) {
    return '$answered cevaptan $right doğru';
  }

  @override
  String subjectToNext(int n, int level) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Seviye $level için $n doğru cevap kaldı',
    );
    return '$_temp0';
  }

  @override
  String get subjectLevel => 'Seviye';

  @override
  String get subjectNext => 'Sıradaki senin için';

  @override
  String get subjectNextLine => 'Seviyenin bir basamak üstü.';

  @override
  String subjectInside(String subject) {
    return '$subject içinde';
  }

  @override
  String get journeySubjectsTap => 'Bir konuya dokun, kendi sayfası açılsın.';

  @override
  String moveName(String move) {
    String _temp0 = intl.Intl.selectLogic(move, {
      'baseRate': 'Temel oranlar',
      'survivorship': 'Hayatta kalanlar',
      'regression': 'Ortalamaya dönüş',
      'confirmation': 'Doğrulama',
      'anchoring': 'Çapalama',
      'sampling': 'Örneklem',
      'confounding': 'Karıştırıcı etkenler',
      'counterfactual': 'Neye göre',
      'multipleComparisons': 'Çok sayıda deneme',
      'availability': 'Akla gelebilirlik',
      'sunkCost': 'Batık maliyet',
      'conjunction': 'Birleşim',
      'conditional': 'Koşullu olasılık',
      'independence': 'Bağımsızlık',
      'coincidence': 'Tesadüfler',
      'exponential': 'Üstel büyüme',
      'reflection': 'Hızlı cevap',
      'simpson': 'Toplamlar',
      'estimation': 'Tahmin',
      'computation': 'Hesaplamak',
      'other': 'Akıl yürütme',
    });
    return '$_temp0';
  }

  @override
  String moveLine(String move) {
    String _temp0 = intl.Intl.selectLogic(move, {
      'baseRate':
          'Bir testin ne kadar doğru olduğu, senin için olasılığı değildir',
      'survivorship': 'Elindeki veri, hayatta kalan veridir',
      'regression': 'Uç değerler kendiliğinden geri döner',
      'confirmation': 'Bir evet aramak test etmek değildir',
      'anchoring': 'Söylenen ilk sayı sonraki tüm sayıları kaydırır',
      'sampling': 'Örnekleme kimin girdiği, neyi söyleyebileceğini belirler',
      'confounding': 'Belki ikisine de başka bir şey yol açıyordur',
      'counterfactual': 'Karşılaştırma olmadan bir değişim hiçbir şey söylemez',
      'multipleComparisons': 'Yeterince şey dene, biri geçer',
      'availability': 'Kolay hayal edilen, sık olan demek değildir',
      'sunkCost': 'Harcanan harcandı; yalnızca kalana karar verilebilir',
      'conjunction':
          'Ayrıntı bir hikâyeyi daha inandırıcı ve daha az olası yapar',
      'conditional': 'Öğrendiğin şey olasılıkları değiştirir',
      'independence': 'Şansın hafızası yoktur',
      'coincidence': 'Deneme çoksa nadir şeyler sık olur',
      'exponential': 'Kimsenin ikiye katlanmaya sezgisi yoktur',
      'reflection': 'İlk gelen cevap, kontrol edilmesi gereken cevaptır',
      'simpson': 'Bütün, hiçbir parçanın eğilmediği yöne eğilebilir',
      'estimation': 'Cevaplanamayanı tahmin edilebilir parçalara böl',
      'computation': 'Gerçekten bitirebileceğin bir problem',
      'other': 'Akıl yürütme',
    });
    return '$_temp0';
  }

  @override
  String get threeSend => 'Gönder';

  @override
  String get threeWhy => 'Nedenini gör';

  @override
  String threeYesterday(int score) {
    return 'Dünün üçlüsü: $score / 300.';
  }

  @override
  String get fiveTitle => 'Günün meydan okuması';

  @override
  String get fiveSame => 'Bugün herkese aynı beş soru. Yaklaşık iki dakika.';

  @override
  String get fiveDone => 'Günün meydan okuması · tamam';

  @override
  String dailyOf(int max) {
    return '/ $max';
  }

  @override
  String dailyPickRight(String answer) {
    return 'Doğrusu: $answer';
  }

  @override
  String dailyPickWrong(String answer) {
    return 'Tam değil. Doğrusu: $answer';
  }

  @override
  String dailyYourPick(String answer) {
    return 'Senin cevabın: $answer';
  }

  @override
  String dailyBetter(int pct, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Bugünkü $n oyuncunun %$pct kadarından daha iyi.',
    );
    return '$_temp0';
  }

  @override
  String dailyPlayers(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Bugün şimdiye kadar $n oyuncu oynadı.',
    );
    return '$_temp0';
  }

  @override
  String dailyFirst(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          'Bugün ilk oynayan $n kişiden birisin: karşılaştırmak için henüz çok az oyuncu var.',
      one: 'Bugün ilk oynayan sensin: karşılaştırmak için henüz çok az oyuncu var.',
    );
    return '$_temp0';
  }

  @override
  String get dailyCounting => 'Bugünün oyuncuları sayılıyor…';

  @override
  String dailyAverage(int right, int total, String avg) {
    return '$total sorudan $right tanesini bildin. Okurlar bu sorularda ortalama $avg tane biliyor.';
  }

  @override
  String get dailyUncounted => 'Bugünün oyuncuları şu an sayılamıyor.';

  @override
  String get dailyEach => 'Soru soru';

  @override
  String dailyItemRight(int pct) {
    return 'Bugünkü oyuncuların %$pct kadarı doğru bildi';
  }

  @override
  String dailyItemGuess(String guess) {
    return 'Bugünün ortalama tahmini: $guess';
  }

  @override
  String get dailyItemFew => 'Karşılaştırmak için henüz çok az yanıt var';

  @override
  String fiveYesterday(int score) {
    return 'Dünün beşlisi: $score / 500.';
  }

  @override
  String fiveShareHead(String date) {
    return 'Astute · Günün meydan okuması · $date';
  }

  @override
  String fiveChallengeLine(int right) {
    return 'Astute\'ta bugünün beşlisinde 5\'te $right yaptım. Beni geçebilir misin?';
  }

  @override
  String get fiveChallengeAll =>
      'Astute\'ta bugünün beşlisinde 5\'te 5 yaptım. Sen de yapabilir misin?';

  @override
  String get fiveChallengeInvite =>
      'Astute\'ta günün meydan okuması: herkese aynı beş soru. Kaçını bilebilirsin?';

  @override
  String threeShareHeadIn(String subject, String date) {
    return 'Astute · Bugünün üçlüsü · $subject · $date';
  }

  @override
  String dailyShareScore(int score, int max, int day) {
    return '$score / $max · $day. gün';
  }

  @override
  String dailyShareScoreAlone(int score, int max) {
    return '$score / $max';
  }

  @override
  String get skillsTitle => 'Ne öğrenmeli';

  @override
  String get skillsTitleMark => 'öğrenmeli';

  @override
  String get skillsLine =>
      'Her cevap puanını oynatır. Seçtiğini çalıştıran kartlar onun işaretini taşır.';

  @override
  String get skillsDone => 'Tamam';

  @override
  String get skillsFocus => 'ODAKTA';

  @override
  String get skillMarkKicker => 'BU KARTIN ÇALIŞTIRDIĞI';

  @override
  String skillMarkLabel(String skill) {
    return 'Çalıştırdığı: $skill';
  }

  @override
  String get skillMarkBody =>
      'Odağa aldığın becerilerden biri. Bunun gibi bir karttaki her cevap o becerideki puanını oynatır.';

  @override
  String get skillMarkOpen => 'Tüm puanlarını gör';

  @override
  String get trainingTitle => 'Antrenmanın';

  @override
  String get trainingLine =>
      'Her cevap puanını oynatır, en çok da doğru bilinen zor bir kart. Bir tavanı yok.';

  @override
  String get trainingOthers => 'Diğerleri';

  @override
  String get trainingEmpty =>
      'Neyde daha iyi olmak istediğini seç. Onu çalıştıran bir karttaki her cevap puanını oynatır ve kart onun işaretini taşır.';

  @override
  String get trainingPick => 'Becerileri seç';

  @override
  String trainingMore(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 've $n tane daha',
      one: 've 1 tane daha',
    );
    return '$_temp0';
  }

  @override
  String get aimTitle => 'Nerede daha net görmek istersin?';

  @override
  String get aimLine =>
      'Birini seç. Her gün bunun için kartlar olacak; istediğin zaman değiştirebilirsin.';

  @override
  String aimWeek(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Bu hafta bunun için $n kart',
      one: 'Bu hafta bunun için 1 kart',
      zero: 'Bu hafta bunun için kart yok',
    );
    return '$_temp0';
  }

  @override
  String answersRightOf(int right, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      right,
      locale: localeName,
      other: '$n sorudan $right doğru',
      one: '$n sorudan 1 doğru',
    );
    return '$_temp0';
  }

  @override
  String get aimOpen => 'Bu hedef için her şey';

  @override
  String get aimPlus =>
      'Astute+ ile: bunun bütün yolları eksiksiz ve seninle bunun üzerine çalışan bir koç.';

  @override
  String get aimNone =>
      'Nerede daha net görmek istediğini seç: her gün bunun için kartlar olacak.';

  @override
  String get aimPick => 'Hedef seç';

  @override
  String get strengthsTitle => 'Güçlü olduğun yerler';

  @override
  String get strengthsLine =>
      'Bir seçimden değil, cevaplarından: en çok nerede bildiğin ve nerede yanıldığın.';

  @override
  String strengthsFew(String skills) {
    return 'Henüz az cevap var: $skills.';
  }

  @override
  String strengthsPractice(String skill) {
    return '$skill üzerine çalış';
  }

  @override
  String get strengthsBest => 'Güçlü yanın';

  @override
  String get strengthsWeak => 'En çok yanıldığın yer';

  @override
  String get strengthsLocked =>
      'En çok yanıldığın yer ve geri kalanı Astute+ ile.';

  @override
  String get strengthsEmpty =>
      'Birkaç cevap daha, sonra burada güçlü olduğun yerleri göreceksin.';

  @override
  String get readTitle => 'Zaten net gördüğün yerler';

  @override
  String get readBlind => 'Kör noktan';

  @override
  String get readLocked =>
      'Kör noktan için beş kart ve profilinin tamamı Astute+ ile.';

  @override
  String get readEmpty =>
      'Birkaç cevap daha, sonra burada nerede net görüp nerede görmediğini göreceksin.';

  @override
  String get readNoAim =>
      'Yukarıdan nerede daha net görmek istediğini seç: cevapların nerede zaten net gördüğünü gösterecek.';

  @override
  String get readLine =>
      'Bu hedefin gerektirdiği beceriler, cevaplarından okundu: nerede net gördüğün ve kör noktan.';

  @override
  String get readOthers => 'Profilinin geri kalanı';

  @override
  String get focusTitle => 'Haftanın odağı';

  @override
  String get focusFromGoal =>
      'Hedefine göre seçildi: her hafta farklı bir beceri.';

  @override
  String get focusFromMisses =>
      'Cevaplarına göre seçildi: en çok yanıldığın yer.';

  @override
  String get focusLine =>
      'Onu çalıştıran kartlarda işareti olur. Pazar günü haftanın nasıl geçtiğini görürsün.';

  @override
  String focusLast(String skill) {
    return 'Geçen hafta: $skill';
  }

  @override
  String focusNext(String skill) {
    return 'Pazartesiden itibaren: $skill';
  }

  @override
  String get focusResult => 'Hafta nasıl geçti';

  @override
  String get focusPlus =>
      'Astute+ ile odağı cevapların seçer: en çok yanıldığın yer.';

  @override
  String get focusMarkBody =>
      'Bu hafta bu beceriyi çalışıyorsun: onu çalıştıran kartlarda bu işaret olur. Pazar günü nasıl geçtiğini göreceksin.';

  @override
  String focusShelf(String skill) {
    return 'Haftanın odağı: $skill';
  }

  @override
  String get focusShelfLine => 'Onu çalıştıran, henüz okunmamış kartlar.';

  @override
  String get focusOpen => 'Haftan';

  @override
  String get scoreTitle => 'Astute puanı';

  @override
  String scoreWeek(String n) {
    return 'bu hafta $n';
  }

  @override
  String get scoreStart => 'İlk cevabınla başlar.';

  @override
  String scoreMoveLabel(String name, String n) {
    return '$name: bu cevapla $n';
  }

  @override
  String scoreAnswers(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n cevaptan',
      one: '1 cevaptan',
    );
    return '$_temp0';
  }

  @override
  String get videoKicker => 'Video';

  @override
  String get videoPlay => 'Oynat';

  @override
  String get videoPause => 'Duraklat';

  @override
  String get videoWatchAgain => 'Tekrar izle';

  @override
  String get videoOffline =>
      'Video için bağlantı gerekiyor. Tekrar denemek için dokun.';

  @override
  String get skillsRowTitle => 'Öğrenmek istediklerin';

  @override
  String skillName(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'critical': 'Eleştirel düşünme',
      'decisions': 'Daha iyi kararlar',
      'money': 'Para ve birikim',
      'numbers': 'Sayılar ve istatistik',
      'talk': 'İletişim',
      'persuade': 'İkna',
      'people': 'İnsanları anlamak',
      'fakes': 'Sahteyi ayırt etmek',
      'science': 'Bilim insanı gibi düşünmek',
      'focus': 'Odaklanma',
      'lead': 'Liderlik',
      'culture': 'Genel kültür',
      'other': '$key',
    });
    return '$_temp0';
  }

  @override
  String skillLine(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'critical': 'Sağlam bir argümanı yanıltıcı olandan ayırmak.',
      'decisions': 'İçgüdüyle değil, risk ve olasılıkla seçmek.',
      'money': 'Fiyatlar, faiz, kampanyalar: paran nereye gidiyor.',
      'numbers': 'Yüzdeleri ve grafikleri kanmadan okumak.',
      'talk': 'Sözlü de yazılı da anlaşılmak.',
      'persuade': 'İkna etmek ve seni ikna etmeye çalıştıklarını fark etmek.',
      'people': 'İnsanlar yaptıklarını neden yapar.',
      'fakes': 'Sahte haberleri, oynanmış fotoğrafları ve şişirilmiş araştırmaları fark etmek.',
      'science': 'Bir fikre inanmadan önce onu sınamak.',
      'focus': 'Dikkatini önemli yerde daha uzun tutmak.',
      'lead': 'Bir grubu yönetmek ve herkes için karar vermek.',
      'culture': 'Tarih, bilim, sanat: herkesin alıntıladığı şeyler.',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get perkFiveShort => 'Her gün, senin seviyende.';

  @override
  String get perkShelvesTitle => 'Her yol ve her kitap';

  @override
  String get perkShelvesLine => 'Eksiksiz, her hafta yenileriyle.';

  @override
  String get perkGapShort => 'Ne kadar emin, ne kadar haklı: hafta hafta.';

  @override
  String get perkReadShort => 'Okuduğun her gün, yeniden açmak için.';

  @override
  String get trialToday => 'Bugün · Astute+ tamamen ücretsiz';

  @override
  String trialReminder(int day) {
    return '$day. gün · sana hatırlatırız';
  }

  @override
  String trialCharge(int day, String price, String plan) {
    String _temp0 = intl.Intl.selectLogic(plan, {
      'year': 'yıllık',
      'other': 'aylık',
    });
    return '$day. gün · $_temp0 $price, iptal edene kadar otomatik yenilenir';
  }

  @override
  String chargedTodayRenews(String price, String suffix) {
    return '$price$suffix bugün ödenir, iptal edene kadar otomatik yenilenir';
  }

  @override
  String cancelHow(String where) {
    return 'İstediğin zaman $where bölümünden iptal et; yenilemeden en az 24 saat önce.';
  }

  @override
  String get cancelWhereIos => 'Ayarlar › adın › Abonelikler';

  @override
  String get cancelWhereAndroid =>
      'Google Play › Ödemeler ve abonelikler › Abonelikler';

  @override
  String storeAsking(String store) {
    String _temp0 = intl.Intl.selectLogic(store, {
      'apple': 'Fiyatlar App Store’dan alınıyor…',
      'other': 'Fiyatlar Google Play’den alınıyor…',
    });
    return '$_temp0';
  }

  @override
  String storeUnreachable(String store) {
    String _temp0 = intl.Intl.selectLogic(store, {
      'apple': 'App Store’a ulaşılamadı',
      'other': 'Google Play’e ulaşılamadı',
    });
    return '$_temp0';
  }

  @override
  String get storeUnreachableLine =>
      'Fiyatlar ve ücretsiz deneme mağazadan gelir. Bağlantını kontrol edip tekrar dene.';

  @override
  String get tryAgain => 'Tekrar dene';

  @override
  String get purchasePending =>
      'Onay bekleniyor. Ödeme tamamlanır tamamlanmaz Astute+ açılacak.';

  @override
  String get oneMoment => 'Bir saniye…';

  @override
  String get purchaseConfirming => 'Ödeme onaylanıyor…';

  @override
  String get purchaseConfirmingSlow =>
      'Bu, her zamankinden uzun sürüyor. Ödeme güvende: Astute+ kendiliğinden açılacak.';

  @override
  String get closeLabel => 'Kapat';

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
  String get verdictRight => 'Doğru.';

  @override
  String get verdictClose => 'Yeterince yakın.';

  @override
  String get verdictWrong => 'Tam değil.';

  @override
  String verdictSure(int pct) {
    return '%$pct emindin.';
  }

  @override
  String verdictYouSaid(String given) {
    return 'Senin cevabın: $given';
  }

  @override
  String verdictYouSaidSure(String given, int pct) {
    return 'Senin cevabın: $given, %$pct emin';
  }

  @override
  String verdictRightIs(String answer) {
    return 'Doğrusu: $answer';
  }

  @override
  String verdictRightWithin(String answer, String low, String high) {
    return 'Doğrusu: $answer ($low ile $high arası sayılırdı)';
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
  String get musicSound => 'Müzik kartlarında ses';

  @override
  String get musicSoundIsOff => 'Müzik kartlarının sesi kapalı.';

  @override
  String get musicSoundTurnOn => 'Aç';

  @override
  String get thatWasTheOnlyOne => 'Tek kart buydu';

  @override
  String get lastOne => 'Sonuncusu';

  @override
  String deckEndTitle(String word) {
    return 'Hepsi bu kadar: $word.';
  }

  @override
  String get deckEndAgain => 'Baştan başla';

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
      other:
          'Günler önce cevapladığın $n kart, aklında kalmış mı diye geri geldi',
      one: 'Günler önce cevapladığın 1 kart, aklında kalmış mı diye geri geldi',
    );
    return '$_temp0';
  }

  @override
  String get cameBack => 'Hâlâ hatırlıyor musun?';

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
  String get nudgeBookTitle => 'Bu haftanın ücretsiz kitabı';

  @override
  String nudgeBookBody(String title, String author, int minutes) {
    return '$title, $author: büyük fikirler $minutes dakikada.';
  }

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
  String get yourJourney => 'Yolculuğun';

  @override
  String journeySince(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days gün önceki ziyaretinden beri',
      one: 'Dünkü ziyaretinden beri',
      zero: 'Bugünkü son ziyaretinden beri',
    );
    return '$_temp0';
  }

  @override
  String journeySinceMark(String n) {
    return 'son ziyaretinden beri $n';
  }

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
  String get consentTitle => 'Astute\'u daha iyi yapmamıza yardım eder misin?';

  @override
  String get consentLine =>
      'Uygulamayı nasıl kullandığını paylaş — adın, e-postan ve yazdıkların asla gitmez.';

  @override
  String get consentNo => 'Hayır, teşekkürler';

  @override
  String get consentYes => 'Evet, paylaş';

  @override
  String consentChangeLater(String profile, String setting) {
    return 'Bunu istediğin zaman $profile › $setting bölümünden değiştirebilirsin.';
  }

  @override
  String get yourMix => 'Senin karışımın';

  @override
  String get genresTitle => 'Hangi kısımlar?';

  @override
  String get genresLine =>
      'Atlamak için bir türe dokun. Basılı tut, içindeki küçük konular hemen altında açılsın.';

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
      'Her gün senin için seçilmiş beş kart: karışımından, seviyende, ve kaçırdıkların geri gelir. Yarından itibaren.';

  @override
  String get plusCardHeadline => 'Beşi de senin olsun.';

  @override
  String get plusCardLine =>
      'Karışımından, seviyende günde beş kart. Yolculuğun. Tüm arşivin.';

  @override
  String get archiveBeforeThisWeek => 'Bu haftadan öncesi';

  @override
  String get weekKeptThreeOwn => 'Yedi gün üst üste: yarın beşten üçü senin.';

  @override
  String get weekKeptSundayFourOwn =>
      'Yedi gün üst üste, yarın da pazar: beşten dördü senin.';

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
  String get topPicksTitle => 'Vaktine değer';

  @override
  String get topPicksLine =>
      'Okurların listesi dolana kadar Astute\'un seçtikleri';

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
  String get themePracticalLine =>
      'Bu akşamdan önce denenecek ya da bir sohbette söylenecek bir şey';

  @override
  String get themeOrigins => 'Nereden geldi';

  @override
  String get themeOriginsLine => 'Her gün kullandığın şeylerin başlangıcı';

  @override
  String get themeStories => 'Gerçek hikâyeler';

  @override
  String get themeStoriesLine => 'Gerçekten yaşanmış şeyler';

  @override
  String get storyHint => 'İlerlemek için dokun · durdurmak için basılı tut';

  @override
  String get storyTapOn => 'İlerlemek için dokun';

  @override
  String get storyPrevious => 'Önceki';

  @override
  String get storyClose => 'Hikâyeyi kapat';

  @override
  String get storySave => 'Sakla';

  @override
  String get storySaved => 'Saklandı';

  @override
  String get storyShare => 'Paylaş';

  @override
  String get storyOpenCard => 'Kartı aç';

  @override
  String get themeDebates => 'Taraf seç';

  @override
  String get themeDebatesLine =>
      'Doğru cevap yok, yalnızca daha iyi bir argüman';

  @override
  String get themeWorkItOut => 'Hesapla';

  @override
  String get themeWorkItOutLine => 'Kart söylemeden önce sayıyı tahmin et';

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
  String weekRecapMore(int n) {
    return 'Astute+ ile haftandan $n kart daha';
  }

  @override
  String get weekReviewTitle => 'Haftayı tekrarla';

  @override
  String get weekReviewLine =>
      'Bu haftaki kartlarının soruları. Yeniden cevapla: akılda böyle kalırlar.';

  @override
  String get weekReviewGo => 'Tekrarla';

  @override
  String get weekReviewNone =>
      'Bu hafta okuduğun kartlar, tekrar etmen için buraya gelir.';

  @override
  String get plusInTheApp =>
      'Astute+ uygulamada: ücretsiz denemeni başlatmak için Astute\'u iPhone veya Android\'e indir.';

  @override
  String get purchaseComplete => 'Satın alma tamamlandı.';

  @override
  String get trialStartedTitle => 'Ücretsiz deneme başladı.';

  @override
  String get successWelcome => 'Astute+’a hoş geldin. Bugünün beş kartı hazır.';

  @override
  String successWelcomeNamed(String name) {
    return 'Astute+’a hoş geldin, $name. Bugünün beş kartı hazır.';
  }

  @override
  String get successWelcomeTomorrow =>
      'Astute+’a hoş geldin. Yarının beş kartı tamamen senin.';

  @override
  String successWelcomeTomorrowNamed(String name) {
    return 'Astute+’a hoş geldin, $name. Yarının beş kartı tamamen senin.';
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
  String get sceneLockIn => 'Onayla';

  @override
  String get placeItDrag => 'Cetvel boyunca sürükle.';

  @override
  String get placeItHappy => 'Böyle kalsın mı?';

  @override
  String get placeItEstimate => 'Tahminin';

  @override
  String get placeItNotSet => 'henüz yok';

  @override
  String get placeItLock => 'Tahminimi onayla';

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
    return 'haftada $now dk, başta $was dk';
  }

  @override
  String journeyMinThisWeek(int m) {
    return 'bu hafta $m dk';
  }

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
  String get journeyMovesTitle => 'Fark ettiğin numaralar';

  @override
  String get journeySureEmpty => '%80 ya da üstü dediğinde görünür.';

  @override
  String get journeyMovesEmpty =>
      'Bir numarayı iki kartta fark ettiğinde görünür.';

  @override
  String get journeyMissedEmpty => 'İkinci bir konuda altı cevap, ve ölçülür.';

  @override
  String get journeyFillsAsYouRead => 'Okudukça dolar.';

  @override
  String journeyOfN(int n) {
    return '/ $n';
  }

  @override
  String journeyNewest(String name) {
    return 'En yenisi: $name';
  }

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
  String get betWord => 'Yatır';

  @override
  String get biggerLabel => 'Daha büyük';

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
  String get fewCards => 'Birkaç kartta';

  @override
  String get fewCardsLine => 'Tek kart açıklamaya yetmediğinde';

  @override
  String get firstLabel => 'İlk';

  @override
  String get forYouNow => 'Senin için, şimdi';

  @override
  String get hardBadge => 'Zor';

  @override
  String hidesIn(String where) {
    return 'Konu: $where';
  }

  @override
  String get howSure => 'Ne kadar eminim, ve neden?';

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
  String get modeCloser => 'Yaklaş';

  @override
  String get modePick => 'Birini seç';

  @override
  String get modeRange => 'Aralığa oyna';

  @override
  String get modeSlide => 'Kaydır';

  @override
  String get modeStake => 'Bahsini koy';

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
  String get moveComparedToWhat => 'Çok mu, az mı?';

  @override
  String get moveComparedToWhatLine =>
      '«%30 arttı» demek, şunu bilmeden hiçbir şey ifade etmez: neye göre?';

  @override
  String get askingTitle => 'Her konudan bir soru';

  @override
  String askingIn(String subject) {
    return '$subject soruları';
  }

  @override
  String get askingLine => 'Herkes için aynı. Önce cevapla, sonra nedenini gör';

  @override
  String get moveSampling => 'Verilerde kim eksik?';

  @override
  String get moveSamplingLine =>
      'Her istatistik bazılarını sayar, bazılarını atlar. Dışarıda kalanlar cevabı tersine çevirebilir';

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
  String rangeWidth(int w, int pts) {
    return '±$w · $pts p';
  }

  @override
  String get rightLastTime => 'Geçen sefer doğru';

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
  String leanHint(String or) {
    return '«$or» düğmesini durduğun yere kaydır';
  }

  @override
  String leanHow(String level) {
    String _temp0 = intl.Intl.selectLogic(level, {
      '1': 'biraz',
      '2': 'genel olarak',
      '3': 'kesinlikle',
      'other': 'sonuna kadar',
    });
    return '$_temp0';
  }

  @override
  String leanSays(String side, String how) {
    return '$side, $how';
  }

  @override
  String leanTook(String side) {
    return 'Seçtiğin: $side';
  }

  @override
  String leanVerdict(String says) {
    return '$says. Karşı tarafı görmek için aç.';
  }

  @override
  String get spotTitle => 'Yanlış olanı bul';

  @override
  String get spotLine => 'Dört iddia. Üçü doğru, biri yanlış.';

  @override
  String get spotPrompt => 'Yanlış olduğunu düşündüğüne dokun';

  @override
  String get spotConfirm => 'Yanlış olan bu';

  @override
  String get spotFound => 'Buldun. Diğer üçü doğru.';

  @override
  String get spotMissed => 'O değil: o doğru. Yanlış olanın üstü çizili.';

  @override
  String get spotWhy => 'Nedenini okumak için birine dokun';

  @override
  String get spotYours => 'Seçimin';

  @override
  String get todayLabel => 'Bugün';

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
  String get unmaskMisleadTitle => 'Yanıltan grafikler';

  @override
  String get unmaskMisleadLine => 'Sayılar doğru. Hile çizimde.';

  @override
  String get unmaskAsk => 'Bu grafik yanıltıyor. Nasıl, görebiliyor musun?';

  @override
  String get unmaskShowTrick => 'Hileyi göster';

  @override
  String get unmaskHideTrick => 'Hileyi gizle';

  @override
  String get unmaskOriginal => 'Orijinal';

  @override
  String get unmaskCorrected => 'Düzeltilmiş';

  @override
  String unmaskTrickTruncated(String from) {
    return 'Eksen sıfırdan değil, $from değerinden başlıyor.';
  }

  @override
  String unmaskTrickZoomed(String low, String high) {
    return 'Eksen yalnızca $low ile $high arasında; küçük bir değişim dev gibi görünüyor.';
  }

  @override
  String unmaskTrickWide(String low, String high) {
    return 'Eksen $low ile $high arasında; gerçek bir değişim düz görünüyor.';
  }

  @override
  String unmaskTrickWindow(String shown, String all) {
    return 'Yalnızca $shown gösteriliyor, oysa veriler $all dönemini kapsıyor.';
  }

  @override
  String get unmaskTrickTotals =>
      'Adil bir ölçü yerine ham toplamları karşılaştırıyor.';

  @override
  String get unmaskTrickFlippedRise =>
      'Eksen ters çevrilmiş, bu yüzden artış düşüş gibi görünüyor.';

  @override
  String get unmaskTrickFlippedFall =>
      'Eksen ters çevrilmiş, bu yüzden düşüş artış gibi görünüyor.';

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

  @override
  String placeNearYou(String place) {
    return 'Yakınında · $place';
  }

  @override
  String placeYourRegion(String place) {
    return 'Bölgen · $place';
  }

  @override
  String placeYourCountry(String place) {
    return 'Ülken · $place';
  }

  @override
  String get sundayOneMore => 'Pazar: senin için seçilmiş bir tane daha';

  @override
  String get whereYouLive => 'Yaşadığın yer';

  @override
  String get whereYouLiveLine => 'Önce şehrin, sonra bölgen, sonra ülken';

  @override
  String get whereYouLiveAsk =>
      'Şehrin, bölgen ve ülken hakkında kartlar: günde en fazla bir tane, bir de bu raf. Yalnızca şehir saklanır, tam olarak nerede olduğun asla.';

  @override
  String get whereYouLiveSwitchOn => 'Aç';

  @override
  String get gateUpdateTitle => 'Astute’u güncelle';

  @override
  String gateUpdateLine(String store) {
    String _temp0 = intl.Intl.selectLogic(store, {
      'apple': 'Yenisi App Store’da seni bekliyor',
      'google': 'Yenisi Google Play’de seni bekliyor',
      'other': 'Yenisi uygulama mağazanda seni bekliyor',
    });
    return 'Bu sürümle artık devam edilemiyor. $_temp0; kartların ve serin bıraktığın gibi duruyor.';
  }

  @override
  String get gateUpdateButton => 'Güncelle';

  @override
  String get gateSoftTitle => 'Astute’un yeni sürümü hazır';

  @override
  String gateSoftLine(String store) {
    String _temp0 = intl.Intl.selectLogic(store, {
      'apple': 'App Store’da seni bekliyor.',
      'google': 'Google Play’de seni bekliyor.',
      'other': 'Uygulama mağazanda seni bekliyor.',
    });
    return '$_temp0 Güncelleme bir an sürer; kartların ve serin olduğu gibi kalır.';
  }

  @override
  String get gateSoftLater => 'Sonra';

  @override
  String get gatePauseTitle => 'Astute kısa bir mola veriyor';

  @override
  String get gatePauseLine =>
      'Perde arkasında bir şeyi düzeltiyoruz. Yaptığın her şey güvende. Biraz sonra yeniden dene.';

  @override
  String get gatePauseTrying => 'Yeniden deneniyor…';

  @override
  String get gatePauseStill =>
      'Mola sürüyor. Birkaç dakika sonra yeniden dene.';

  @override
  String purposeReadOrDoCount(int toDo, int toRead) {
    return '$toDo yapılacak, $toRead okunacak';
  }

  @override
  String purposeShelfCount(int toDo, int toRead) {
    return '$toDo yapılacak · $toRead okunacak';
  }

  @override
  String get purposeFilterToRead => 'Oku';

  @override
  String get purposeFilterToDo => 'Yap';

  @override
  String purposeVerb(String verb) {
    String _temp0 = intl.Intl.selectLogic(verb, {
      'trueFalse': 'Doğru mu yanlış mı',
      'pick': 'Birini seç',
      'typeNumber': 'Sayı yaz',
      'bet': 'Sayıya bahse gir',
      'side': 'Taraf seç',
      'youFirst': 'Önce sen',
      'moveIt': 'Kaydır ve izle',
      'whatNext': 'Sonra ne olacak?',
      'spotTrick': 'Hileyi bul',
      'drawIt': 'Çiz',
      'sortThem': 'Ayıkla',
      'putInOrder': 'Sıraya diz',
      'holdIt': 'Basılı tut',
      'growSample': 'Örneklemi büyüt',
      'askWhy': 'Neden diye sor',
      'sayPlainly': 'Sade söyle',
      'pairUp': 'Eşleştir',
      'followClues': 'İpuçlarını izle',
      'look': 'Sadece bak',
      'listen': 'Dinle',
      'other': '$verb',
    });
    return '$_temp0';
  }

  @override
  String purposeVerbRead(int n) {
    return 'Oku · $n dk';
  }

  @override
  String get purposeCommitNote =>
      'Burada cevapla, sonra kartı açıp haklı mıymışsın gör. Kendini bağladığın bir tahmin aklında daha uzun kalır.';

  @override
  String get purposeCommitTitle => 'Önce cevapla';

  @override
  String get purposeCommitLine => 'Ne düşündüğünü söyle, sonra kartı aç';

  @override
  String get purposeInYourHeadLine => 'Kafadan bulunacak bir sayı';

  @override
  String get purposeInYourHead => 'Kafadan';

  @override
  String get purposeMoveKicker => 'Bir hamle';

  @override
  String purposeMoveNew(int points) {
    return 'Yeni · ustalaşınca +$points';
  }

  @override
  String purposeMoveName(String move) {
    String _temp0 = intl.Intl.selectLogic(move, {
      'baseRate': 'Taban oranlar',
      'survivorship': 'Hayatta kalan yanılgısı',
      'regression': 'Ortalamaya dönüş',
      'confirmation': 'Doğrulama',
      'anchoring': 'Çapalama',
      'sampling': 'Örneklem',
      'confounding': 'Karıştırıcı etken',
      'counterfactual': 'Neye göre',
      'multipleComparisons': 'Çok deneme',
      'availability': 'Akla gelebilirlik',
      'sunkCost': 'Batık maliyet',
      'conjunction': 'Birleşim',
      'conditional': 'Koşullu olasılık',
      'independence': 'Bağımsızlık',
      'coincidence': 'Tesadüf',
      'exponential': 'Üstel büyüme',
      'reflection': 'Hızlı cevap',
      'simpson': 'Toplamlar',
      'estimation': 'Tahmin',
      'computation': 'Hesaplama',
      'other': '$move',
    });
    return '$_temp0';
  }

  @override
  String purposeMoveLine(String move) {
    String _temp0 = intl.Intl.selectLogic(move, {
      'baseRate':
          'Bir testin isabeti, senin o durumda olma olasılığın değildir',
      'survivorship': 'Elindeki veri, hayatta kalan veridir',
      'regression': 'Uç değerler kendiliğinden ortalamaya döner',
      'confirmation': 'Evet aramak bir sınama değildir',
      'anchoring': 'İlk söylenen sayı, sonraki her sayıyı kaydırır',
      'sampling': 'Örnekleme kimin girdiği, onun ne söyleyebileceğini belirler',
      'confounding': 'İkisine de başka bir şey yol açıyor olabilir',
      'counterfactual':
          'Karşılaştırma grubu olmadan bir değişim hiçbir şey ifade etmez',
      'multipleComparisons': 'Yeterince şey dene, biri geçer',
      'availability': 'Kolay hayal edilen, sık görülen demek değildir',
      'sunkCost': 'Harcanan harcandı; karar ancak kalan için verilir',
      'conjunction':
          'Ayrıntı, hikâyeyi daha inandırıcı ama daha az olası yapar',
      'conditional': 'Sana söylenen şey olasılıkları değiştirir',
      'independence': 'Şansın hafızası yoktur',
      'coincidence': 'Deneme çoksa nadir olan sık görülür',
      'exponential': 'Kimsenin ikiye katlanmaya dair sezgisi yoktur',
      'reflection': 'İlk gelen cevap, kontrol edilmesi gereken cevaptır',
      'simpson': 'Bütün, hiçbir parçanın eğilmediği yöne eğilebilir',
      'estimation': 'Cevaplanamayanı tahmin edebileceğin parçalara böl',
      'computation': 'Gerçekten bitirebileceğin bir problem',
      'other': '$move',
    });
    return '$_temp0';
  }

  @override
  String purposeMoveAsk(String move) {
    String _temp0 = intl.Intl.selectLogic(move, {
      'baseRate': 'Başta ne kadar yaygındı?',
      'survivorship': 'Verilere hiç girmeyen ne?',
      'regression': 'Sadece ortalamaya dönen bir uç değer mi?',
      'confirmation': 'Yanıldığımı ne gösterirdi?',
      'anchoring': 'Hangi sayı önce geldi?',
      'sampling': 'Kimler sayıldı?',
      'confounding': 'İkisine birden ne yol açmış olabilir?',
      'counterfactual': 'Neye göre?',
      'multipleComparisons': 'Kaç şey denendi?',
      'availability': 'Yaygın mı, yoksa sadece kolay mı canlanıyor?',
      'sunkCost': 'Buradan sonra karar verilecek ne kaldı?',
      'conjunction': 'Her ayrıntı onu daha az olası yapıyor mu?',
      'conditional': 'Bunu bilmek neyi değiştirir?',
      'independence': 'Son sonuç bir sonrakini değiştirir mi?',
      'coincidence': 'Kaç fırsat vardı?',
      'exponential': 'Bir kez daha ikiye katlanınca ne olur?',
      'reflection': 'İlk cevap doğru olan mı?',
      'simpson': 'Her parça aynı yöne mi eğiliyor?',
      'estimation': 'Yolda neyi tahmin edebilirim?',
      'computation': 'Adım adım hesaplayabilir miyim?',
      'other': '$move',
    });
    return '$_temp0';
  }

  @override
  String get purposeStepAbove => 'Bir basamak yukarı';

  @override
  String get purposeStepAboveLine => 'Genelde okuduklarından daha zor';

  @override
  String purposeThinTitle(String subject) {
    return 'En az okuduğun: $subject';
  }

  @override
  String purposeThinLine(int percent, String subject) {
    return '$subject rafının %$percent kadarı okundu, en azı bu';
  }

  @override
  String get purposeOtherSide => 'Öbür taraf';

  @override
  String get purposeOtherSideLine =>
      'Bir taraf seçtin. İşte ona karşı en güçlü argüman';

  @override
  String purposeYouSaid(String side) {
    return 'Cevabın: $side';
  }

  @override
  String purposeCaseFor(String side) {
    return '«$side» diyenlerin gerekçeleri';
  }

  @override
  String get purposeMechanism => 'Mekanizma';

  @override
  String purposeMovingUpdated(String date) {
    return '$date tarihinde güncellendi';
  }

  @override
  String get purposeMovingYears => 'Birkaç yıl içinde değişebilir';

  @override
  String get purposeMovingMonths => 'Bu yıl içinde değişebilir';

  @override
  String get purposeWhy => 'Ha, demek bu yüzden';

  @override
  String get purposeWhyLine => 'Tek bir mekanizma, kafana yatana kadar';

  @override
  String purposeWhyBand(int n) {
    return 'Nedeni · $n dk';
  }

  @override
  String get purposeMe => 'Bu benim';

  @override
  String get purposeMeLine => 'Fark etmeden yaptığın şeyler';

  @override
  String get purposeMeFooter => 'Kendini bulduğun kartları işaretle.';

  @override
  String purposeMeMarked(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '«Bu benim» diye işaretlenen kart: $n.',
    );
    return '$_temp0';
  }

  @override
  String get purposeAboutYou => 'Bilmiyordum, üstelik benimle ilgili';

  @override
  String get purposeAboutYouLine => 'Bedenin, sağlığın, olasılıkların';

  @override
  String get purposeHeadline => 'Bir manşette';

  @override
  String get purposeHeadlineLine =>
      'Olduğundan iyi görünen araştırmalar ve iddialar';

  @override
  String get purposeTheClaim => 'İddia';

  @override
  String get purposeNumber => 'Bir sayıda';

  @override
  String get purposeNumberLine =>
      'İkinci kez bakılması gereken olasılıklar ve yüzdeler';

  @override
  String get purposeOutOfWhat => 'Kaçta kaç?';

  @override
  String get purposeOffer => 'Bir teklifte';

  @override
  String get purposeOfferLine =>
      'Fiyatlar, fırsatlar ve gerçekte kimin ödediği';

  @override
  String get purposeArgument => 'Bir tartışmada';

  @override
  String get purposeArgumentLine => 'Akıl yürütmenin kaydığı yer';

  @override
  String purposeKeepHeading(String n) {
    String _temp0 = intl.Intl.selectLogic(n, {
      '1': 'Bunların çoğunu yakalayan bir soru',
      '2': 'Bunların çoğunu yakalayan iki soru',
      '3': 'Bunların çoğunu yakalayan üç soru',
      '4': 'Bunların çoğunu yakalayan dört soru',
      '5': 'Bunların çoğunu yakalayan beş soru',
      'other': 'Bunların çoğunu yakalayan $n soru',
    });
    return '$_temp0';
  }

  @override
  String purposeLifeAbout(String topic) {
    String _temp0 = intl.Intl.selectLogic(topic, {
      'money': 'Para',
      'work': 'İş ve zaman',
      'clock': 'Zaman',
      'body': 'Bedenin',
      'relationships': 'İlişkiler',
      'belief': 'İnandıkların',
      'other': '$topic',
    });
    return '$_temp0';
  }

  @override
  String purposeLifeQuestion(String topic) {
    String _temp0 = intl.Intl.selectLogic(topic, {
      'money': 'Gerçekten kullandığım şeye mi para ödüyorum?',
      'work': 'Yarına başlamayı ne kolaylaştırırdı?',
      'clock': 'Zamanım gerçekte nereye gidiyor?',
      'body': 'Bedenim hakkında bildiklerim hâlâ doğru mu?',
      'relationships': 'Yakınımdaki insanların gerçekten neye ihtiyacı var?',
      'belief': 'Ne kadar eminim, ve neden?',
      'other': '$topic',
    });
    return '$_temp0';
  }

  @override
  String purposeLifeChip(String topic) {
    String _temp0 = intl.Intl.selectLogic(topic, {
      'money': 'Para',
      'work': 'İş',
      'clock': 'Zaman',
      'body': 'Beden',
      'relationships': 'İlişkiler',
      'belief': 'İnandıklarım',
      'other': '$topic',
    });
    return '$_temp0';
  }

  @override
  String get purposeLifeAsk => 'Hangi konuda daha iyi sorular istersin?';

  @override
  String get purposeLifeFooter =>
      'İstediklerini seç, onlarla ilgili kartlar burada çıksın.';

  @override
  String get purposeSpotTrick => 'Hileyi bul';

  @override
  String get purposeSpotTrickLine => 'Hangi soru onu yakalardı?';

  @override
  String get purposePlayed => 'Bugün oynadıkların';

  @override
  String get purposePlayedOff => 'ortalama sapma puanı';

  @override
  String get purposePlayedTricks => 'yakalanan hile';

  @override
  String get purposePlayedAnswered => 'rafta cevaplanan';

  @override
  String get purposePlayedFooter =>
      'Rafta verdiğin cevaplar, Bugün\'dekiler gibi Yolculuğun\'da sayılır.';

  @override
  String purposeOf(int n, int of) {
    return '$of içinde $n';
  }

  @override
  String purposeSetRead(int n, int of) {
    return '$of karttan $n okundu';
  }

  @override
  String purposeSetDone(int n) {
    return '$n kartın hepsi okundu. Raf yeniden gelince yenileri eklenecek.';
  }

  @override
  String get purposeComplete => 'Tamamlandı';

  @override
  String get purposeStampsFooter => 'Okuduğun her kart pulunu ekler.';

  @override
  String get purposeSets => 'Setlerin';

  @override
  String get purposeSetsLine =>
      'Okumak da sayılır. Bir seti doldurmak için cevaplaman gerekmez.';

  @override
  String get purposeTomorrow => 'Yarın raflarda';

  @override
  String get purposeTomorrowLine => 'Raflar her gün değişir. Sırada bunlar var';

  @override
  String get purposeEnd => 'Keşfet\'in sonuna geldin';

  @override
  String get purposeEndLine => 'Yarın görüşürüz';

  @override
  String get betsRangeTitle => 'Aralığa oyna';

  @override
  String get betsRangeLine =>
      'Ne kadar dar olursa, bilirsen o kadar çok kazandırır';

  @override
  String betsRangeWidth(int w, int pts) {
    return '±$w · $pts p';
  }

  @override
  String get betsBet => 'Oyna';

  @override
  String betsInRange(int pts, String said) {
    return 'Aralıkta: +$pts puan. Cevap $said.';
  }

  @override
  String betsMissedRange(String said) {
    return 'Kaçtı: cevap $said.';
  }

  @override
  String get betsYourGuess => 'Tahminin';

  @override
  String get betsAnsweredAlready => 'Zaten cevaplandı';

  @override
  String get betsOpenCard => 'Kartı aç';

  @override
  String betsWalletSays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Bugün $n puanın kaldı',
    );
    return '$_temp0';
  }

  @override
  String get betsSlipTitle => 'Kuponun';

  @override
  String betsSlipToday(String points) {
    return 'Bugün $points';
  }

  @override
  String get betsSlipEmpty =>
      'Henüz bahis yok. Yaptığın her bahis burada görünür.';

  @override
  String get betsSlipTipTwice => 'Eminsen dar seç: iki kat kazandırır.';

  @override
  String get betsSlipTipThrice => 'Eminsen dar seç: üç kat kazandırır.';

  @override
  String betsSlipTipTimes(int times) {
    String _temp0 = intl.Intl.pluralLogic(
      times,
      locale: localeName,
      other: 'Eminsen dar seç: $times kat kazandırır.',
    );
    return '$_temp0';
  }

  @override
  String betsSlipNarrow(int right, int n) {
    return 'Dar bahislerde isabet: $n bahiste $right.';
  }

  @override
  String betsSlipSure(int right, int n, int pct) {
    return '$n bahiste $right doğru, ortalama %$pct eminken.';
  }

  @override
  String get betsRight => 'Doğru';

  @override
  String get betsWrong => 'Yanlış';

  @override
  String betsOneIn(String n) {
    return '1/$n';
  }

  @override
  String get betsOneInLabel => '1/…';

  @override
  String betsScore(int right, int steps) {
    return '$steps adımda $right';
  }

  @override
  String betsScoreSentence(int right, int steps) {
    return '$steps adımda $right doğru.';
  }

  @override
  String get betsStakeTitle => 'Bahsini koy';

  @override
  String betsStakeLine(int points) {
    return 'Günde $points puan. Kazanırsan bahsin ikiye katlanır';
  }

  @override
  String get betsStakeLabel => 'Bahis';

  @override
  String betsBetN(int n) {
    return '$n oyna';
  }

  @override
  String get betsPickFirst => 'Önce birini seç';

  @override
  String get betsNotEnough => 'Yeterli puan yok';

  @override
  String betsWin(int n) {
    return '$n kazandın.';
  }

  @override
  String betsLose(int n) {
    return '$n kaybettin.';
  }

  @override
  String betsYouWereSure(int pct) {
    return '%$pct emindin.';
  }

  @override
  String get betsFriendTitle => 'Bir arkadaşınla iddiaya gir';

  @override
  String get betsFriendLine =>
      'Bir soru gönder, sonra tahminlerinizi karşılaştırın';

  @override
  String get betsFriendNote =>
      'Tahminin telefonunda kalır. Kart cevabıyla birlikte gider, o yüzden önce onun tahminini sor.';

  @override
  String betsFriendNoteSaid(String said) {
    return 'Tahminin: $said. Kart cevabıyla birlikte gider, o yüzden önce onun tahminini sor.';
  }

  @override
  String get betsFriendSend => 'Bir arkadaşa gönder';

  @override
  String get betsFriendCopy => 'Soruyu kopyala';

  @override
  String get betsFriendCopied => 'Soru kopyalandı';

  @override
  String get betsFriendAsk => 'Sen ne dersin?';

  @override
  String get betsNumberTitle => 'Senin sayın';

  @override
  String get betsNumberLine => 'Ayarla, sabitle, ne kadar saptığını gör';

  @override
  String get betsLock => 'Onayla';

  @override
  String get betsSpotOn => 'Tam isabet.';

  @override
  String betsCloseEnough(String by) {
    return 'Yeterince yakın: $by saptın.';
  }

  @override
  String betsOffBy(String by) {
    return '$by saptın.';
  }

  @override
  String get betsYou => 'sen';

  @override
  String get betsAnswer => 'cevap';

  @override
  String get betsBiggerTitle => 'Hangisi büyük?';

  @override
  String get betsBiggerLine => 'Hesaplanabilen iki sayı. Büyük olana dokun';

  @override
  String get betsTapIfBigger => 'Büyükse dokun';

  @override
  String get betsBiggerGotIt => 'Daha büyük · bildin';

  @override
  String get betsBigger => 'Daha büyük';

  @override
  String get betsYourPick => 'Senin seçimin';

  @override
  String get betsOr => 'ya da';

  @override
  String get betsBiggerFoot =>
      'Her sayı bir kartın cevabı. Seçtikten sonra birine dokunarak kartını açabilirsin.';

  @override
  String betsBiggerScore(int right, int n) {
    return '$n denemede $right doğru.';
  }

  @override
  String get betsCloserTitle => 'Yaklaş';

  @override
  String betsCloserLine(String steps) {
    String _temp0 = intl.Intl.selectLogic(steps, {
      'other': 'Sayıya yaklaşmak için $steps adım: daha fazla mı, daha az mı',
    });
    return '$_temp0';
  }

  @override
  String betsCloserStart(String steps) {
    String _temp0 = intl.Intl.selectLogic(steps, {
      '2': 'Yaklaşmak için iki adım.',
      '3': 'Yaklaşmak için üç adım.',
      '4': 'Yaklaşmak için dört adım.',
      '5': 'Yaklaşmak için beş adım.',
      'other': 'Yaklaşmak için $steps adım.',
    });
    return '$_temp0';
  }

  @override
  String betsMoreOrLess(String v) {
    return '$v değerinden fazla mı, az mı?';
  }

  @override
  String betsStepOf(int at, int of) {
    return 'Adım $at/$of';
  }

  @override
  String get betsMore => 'Daha fazla';

  @override
  String get betsLess => 'Daha az';

  @override
  String betsCloserYesMore(String v) {
    return 'Bildin: $v değerinden fazla.';
  }

  @override
  String betsCloserYesLess(String v) {
    return 'Bildin: $v değerinden az.';
  }

  @override
  String betsCloserNoMore(String v) {
    return 'Bilemedin: $v değerinden fazla.';
  }

  @override
  String betsCloserNoLess(String v) {
    return 'Bilemedin: $v değerinden az.';
  }

  @override
  String betsCloserExact(String said) {
    return 'Cevap tam olarak $said.';
  }

  @override
  String betsCloserDone(String said, int right, int steps) {
    return 'Cevap $said. $steps adımda $right doğru.';
  }

  @override
  String get betsMagnitudeTitle => 'Büyüklük mertebesi';

  @override
  String get betsMagnitudeLine => 'On mu, bin mi, bir milyon mu? Büyüklüğü seç';

  @override
  String get betsMagnitudeRight => 'Mertebe doğru.';

  @override
  String betsMagnitudeOff(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n mertebe saptın.',
    );
    return '$_temp0';
  }

  @override
  String get betsDayTitle => 'Günün bahsi';

  @override
  String get betsDayLine => 'Tahminini onayla, sonra ne kadar saptığını gör';

  @override
  String get betsDayTag => 'Günün bahsi';

  @override
  String get betsDayTagSame => 'Günün bahsi · herkes için aynı';

  @override
  String get betsLockIn => 'Onayla';

  @override
  String betsItIs(String said) {
    return 'Cevap $said.';
  }

  @override
  String betsPointsOff(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n yüzde puan saptın.',
      zero: 'Tam isabet.',
    );
    return '$_temp0';
  }

  @override
  String screensQuoted(String text) {
    return '«$text»';
  }

  @override
  String get screensExpertTitle => 'Bir uzman gibi düşün';

  @override
  String get screensExpertLine =>
      'Her birinin hep sorduğu soru ve o soruya ihtiyaç duyan kartlar';

  @override
  String get screensExpertStatistician => 'İstatistikçi';

  @override
  String get screensExpertStatisticianAs => 'Bir istatistikçi gibi düşün';

  @override
  String get screensExpertStatisticianAsks =>
      'Neye kıyasla ve kaç kişi içinden?';

  @override
  String get screensExpertEconomist => 'Ekonomist';

  @override
  String get screensExpertEconomistAs => 'Bir ekonomist gibi düşün';

  @override
  String get screensExpertEconomistAsks =>
      'Kim ödüyor ve karşılığında neyden vazgeçiyor?';

  @override
  String get screensExpertHistorian => 'Tarihçi';

  @override
  String get screensExpertHistorianAs => 'Bir tarihçi gibi düşün';

  @override
  String get screensExpertHistorianAsks => 'O zamanlar insanlar ne biliyordu?';

  @override
  String get screensExpertDoctor => 'Doktor';

  @override
  String get screensExpertDoctorAs => 'Bir doktor gibi düşün';

  @override
  String get screensExpertDoctorAsks => 'Ne kadar yaygın ve başka ne olabilir?';

  @override
  String get screensExpertScientist => 'Bilim insanı';

  @override
  String get screensExpertScientistAs => 'Bir bilim insanı gibi düşün';

  @override
  String get screensExpertScientistAsks =>
      'Yanlış olsaydı bunu nasıl anlardık?';

  @override
  String get screensDotsTitle => 'Noktaları birleştir';

  @override
  String get screensDotsLine =>
      'Diğerleriyle nerede buluştuğunu görmek için bir konu seç';

  @override
  String screensDotsMeets(int subjects, int cards) {
    String _temp0 = intl.Intl.pluralLogic(
      subjects,
      locale: localeName,
      other: '$subjects konuyla',
    );
    String _temp1 = intl.Intl.pluralLogic(
      cards,
      locale: localeName,
      other: '$cards kartta buluşuyor',
    );
    return '$_temp0 $_temp1';
  }

  @override
  String get screensDotsWhere => 'Buluştukları yer';

  @override
  String get screensDotsWhereLine => 'Tek soru, iki bakış';

  @override
  String get screensAskTitle => 'Neyi anlamak istiyorsun?';

  @override
  String get screensAskHint => 'Ne istersen sor ya da bir kelime yaz';

  @override
  String get screensAskTry => 'Dene';

  @override
  String get screensAskClear => 'Soruyu temizle';

  @override
  String screensAskFound(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n kart yanıtlıyor',
    );
    return '$_temp0';
  }

  @override
  String get screensAskNone => 'Bu konuda henüz kart yok';

  @override
  String get screensAskNoneLine =>
      'Soruyu sakla. Bir kart yanıtladığında burada, sorunun altında olacak.';

  @override
  String get screensAskKeep => 'Soruyu sakla';

  @override
  String get screensAskKept => 'Saklandı';

  @override
  String get screensAskedTitle => 'Sorduğun sorular';

  @override
  String get screensAskedLine => 'Ve onları yanıtlayan kartlar';

  @override
  String get screensAskedAnswered => 'Yanıt';

  @override
  String get screensAskedWaiting =>
      'Henüz yanıtlayan kart yok. Olduğunda burada olacak.';

  @override
  String get screensAskedForget => 'Bu soruyu unut';

  @override
  String get screensAskedForgotten => 'Soru unutuldu';

  @override
  String get screensWhyTitle => 'Neden diye sormaya devam et';

  @override
  String get screensWhyLine => 'Her yanıt bir sonraki soruyu doğurur';

  @override
  String get screensWhyAsk => 'Neden?';

  @override
  String screensWhyBottom(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n kat derine indin.',
    );
    return '$_temp0 Bu zincirin dibi burası.';
  }

  @override
  String get screensWhyAgain => 'Baştan başla';

  @override
  String get screensWhyHoles => 'Daha fazla tavşan deliği';

  @override
  String get screensWhyHolesLine => 'Her biri birkaç kat derine iner';

  @override
  String screensWhyCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n kat',
    );
    return '$_temp0';
  }

  @override
  String get screensWhyDeeper => 'Daha derine in';

  @override
  String screensWhySource(String source) {
    return 'Kaynak: $source';
  }

  @override
  String screensWhyDepth(int at, int of) {
    String _temp0 = intl.Intl.pluralLogic(
      at,
      locale: localeName,
      other: '$at. kat, toplam $of',
    );
    return '$_temp0';
  }

  @override
  String get screensTimeTitle => 'Zamanda yolculuk';

  @override
  String get screensTimeLine =>
      'Her seferinde bir çağ, bu yıla kadar. Yolculuk için sürükle';

  @override
  String get screensTimeCaption =>
      'Yıl önce. Her çentik on kat daha geriye gider.';

  @override
  String get screensTimeNow => 'Şimdi';

  @override
  String get screensTimeEarlier => 'Daha geriye';

  @override
  String get screensTimeLater => 'Bugüne daha yakın';

  @override
  String get screensEraAncient => 'Antik dünya';

  @override
  String get screensEraAncientWhen => '500\'den önce';

  @override
  String get screensEraMedieval => 'Orta Çağ';

  @override
  String get screensEraMedievalWhen => '500\'den 1500\'e';

  @override
  String get screensEraEarlyModern => 'Erken modern çağ';

  @override
  String get screensEraEarlyModernWhen => '1500\'den 1800\'e';

  @override
  String get screensEraNineteenth => '19. yüzyıl';

  @override
  String get screensEraNineteenthWhen => '1800\'den 1900\'e';

  @override
  String get screensEraTwentieth => 'Geçen yüzyıl';

  @override
  String get screensEraTwentiethWhen => '1900\'den 2000\'e';

  @override
  String get screensEraRecent => 'Bu yüzyıl';

  @override
  String get screensEraRecentWhen => '2000\'den beri';

  @override
  String get screensMindTitle => 'Fikrini değiştir';

  @override
  String get screensMindLine =>
      'Okumadan önce nerede durduğunu söyle, okuduktan sonra yine';

  @override
  String get screensMindClaim => 'İddia';

  @override
  String get screensMindBefore => 'Okumadan önce';

  @override
  String get screensMindTap => 'Nerede durduğuna dokun';

  @override
  String get screensMindKnow => 'Bildiklerimiz';

  @override
  String get screensMindNow => 'Ya şimdi?';

  @override
  String get screensMindAgain => 'Yine dokun';

  @override
  String screensMindLevel(String level) {
    String _temp0 = intl.Intl.selectLogic(level, {
      '0': 'Kesinlikle katılmıyorum',
      '1': 'Katılmıyorum',
      '2': 'Emin değilim',
      '3': 'Katılıyorum',
      'other': 'Kesinlikle katılıyorum',
    });
    return '$_temp0';
  }

  @override
  String screensMindToward(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Kanıtlara $n adım yaklaştın.',
    );
    return '$_temp0';
  }

  @override
  String get screensMindSame => 'Öncekiyle aynı. Bir kart sadece bir karttır.';

  @override
  String get screensMindAlready =>
      'Okumadan önce de kanıtlarla aynı yerdeydin.';

  @override
  String get screensMindAway =>
      'Kanıtlardan uzaklaştın. Bir kez daha okumaya değer.';

  @override
  String get screensMindFirst =>
      'Önce nerede durduğunu söyle. Okumadan önce tek dokunuş.';

  @override
  String screensMindChanged(int changed, int total) {
    return '$total iddianın $changed tanesinde fikrini değiştirdin.';
  }

  @override
  String get screensMindFoot => 'Değişen bir fikir, işini yapmış bir karttır.';

  @override
  String get screensSayTitle => 'Bu akşam söyle';

  @override
  String get screensSayLine =>
      'Akşam yemeğine götüreceğin tek cümle. Söyleyince dokun';

  @override
  String get screensSayTonight => 'Bu akşamın cümlesi';

  @override
  String get screensSaySaid => 'Söyledim';

  @override
  String get screensSayDone => 'Söylendi';

  @override
  String screensSayWeek(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Bu hafta $n cümle söyledin.',
      zero: 'Bu hafta henüz bir şey söylemedin.',
    );
    return '$_temp0';
  }

  @override
  String get screensSayCounts =>
      'Söylediğin her cümle, Haftanın en iyileri listesine de sayılır.';

  @override
  String get screensFrontName => 'The Astute';

  @override
  String get screensFrontEdition => 'Bugünün baskısı';

  @override
  String get screensFrontSame => 'Herkes için aynı';

  @override
  String get screensFrontLead => 'Manşet';

  @override
  String get screensFrontNumbers => 'Rakamlarla';

  @override
  String get screensFrontCorrections => 'Düzeltmeler';

  @override
  String get screensFrontPuzzle => 'Günün bulmacası';

  @override
  String get screensFrontEnd => 'Bugünün baskısı bu kadar';

  @override
  String get screensFrontTomorrow => 'Yarınki sabah çıkıyor';

  @override
  String exploreDayRead(int read, int of) {
    return 'Bugün: $of karttan $read okundu';
  }

  @override
  String exploreDayLeft(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n kaldı',
    );
    return '$_temp0';
  }

  @override
  String get exploreDayDone => 'hepsi okundu';

  @override
  String get exploreDayOpen => 'Bugünün kartlarına git';

  @override
  String get exploreGameNone =>
      'Şu an burada oynanacak bir şey yok. Yarın tekrar gel.';

  @override
  String get challengesTitle => 'Meydan okumalar';

  @override
  String get challengesLine =>
      'Muhakeme ve tahmin üzerine kısa alıştırmalar, her biri birkaç dakika.';

  @override
  String challengesPage(int n, int of) {
    return 'Sayfa $n/$of';
  }

  @override
  String get gamePlay => 'Başla';

  @override
  String get sixtyRules =>
      'Bir dakikada sekiz iddia: doğru mu, yanlış mı? Acele ederken ne kadar iyi karar verdiğini ölçer; okuduklarımızın çoğunu böyle değerlendiririz.';

  @override
  String get sixtyReview => 'Sekiz iddia';

  @override
  String get gameRight => 'Bildin';

  @override
  String get gameWrong => 'Bilemedin';

  @override
  String get gameUnanswered => 'Cevapsız';

  @override
  String get gameNext => 'Sıradaki meydan okuma';

  @override
  String sixtyShareHead(String date) {
    return 'Astute · Altmış saniye · $date';
  }

  @override
  String sixtyShareScore(int n, int of, int s) {
    return '$of iddiadan $n doğru · $s sn';
  }

  @override
  String sixtySecondsLeftLabel(int s) {
    String _temp0 = intl.Intl.pluralLogic(
      s,
      locale: localeName,
      other: '$s saniye kaldı',
    );
    return '$_temp0';
  }

  @override
  String get gameReview => 'Kartlar';

  @override
  String get gameTomorrow => 'Yeni tur yarın';

  @override
  String get gameContinue => 'Devam et';

  @override
  String gameShareHead(String game, String date) {
    return 'Astute · $game · $date';
  }

  @override
  String gameShareScore(int n, int of) {
    return '$of içinden $n doğru';
  }

  @override
  String gameCardsToday(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Bugün $n kart',
    );
    return '$_temp0';
  }

  @override
  String get gameAllRight => 'Hepsi doğru.';

  @override
  String gamePoints(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n puan',
    );
    return '$_temp0';
  }

  @override
  String get gameSeeResult => 'Sonucu gör';

  @override
  String get gameNextCard => 'Sonraki';

  @override
  String get spotOnce => 'Günde bir seçim';

  @override
  String get spotGotIt => 'Yanlış olanı buldun.';

  @override
  String get spotMissedIt => 'O değil: o doğru.';

  @override
  String get tfRules =>
      'Çoğu kişinin yanıldığı iddialar. Doğru mu yanlış mı söyle, sonra nedenini oku. Muhakemeni ölçer: doğru olanı yalnızca apaçık görünenden ayırmayı.';

  @override
  String get inOrderTitle => 'Sırayla';

  @override
  String get inOrderRules =>
      'Kartlardan dört an, yılları gizli; onları oluş sırasına diz. Kronoloji duygunu ölçer; her açıklamanın ilk sınavı budur: neden, sonucundan önce gelir.';

  @override
  String get inOrderFirst => 'İlk gelen ana dokun.';

  @override
  String get inOrderNext => 'Şimdi ondan sonra geleni.';

  @override
  String get inOrderReady => 'Hepsi yerleşti.';

  @override
  String get inOrderCheck => 'Sırayı kontrol et';

  @override
  String inOrderPlaced(int n) {
    return '$n. sırada';
  }

  @override
  String inOrderYours(int n) {
    return 'Senin sıran: $n';
  }

  @override
  String get inOrderPerfect => 'Hepsi yerli yerinde.';

  @override
  String get timeGap => 'eksik bir yıl';

  @override
  String get whatYearTitle => 'Hangi yıl?';

  @override
  String get whatYearRules =>
      'Üç an, yılları gizli. Her birinin yılını ayarla: ne kadar yakınsan o kadar puan, ona kadar. Olayların ne zaman olduğuna dair sezgini ölçer.';

  @override
  String whatYearPoints(int n, int of) {
    return '$of puandan $n puan';
  }

  @override
  String get whatYearPerfect => 'Her yıl tam isabet.';

  @override
  String whatYearOffInAll(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Toplamda $n yıl saptın.',
    );
    return '$_temp0';
  }

  @override
  String whatYearSaid(String guess, int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: 'Senin cevabın: $guess · $points puan',
    );
    return '$_temp0';
  }

  @override
  String whatYearOff(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n yıl saptın',
    );
    return '$_temp0';
  }

  @override
  String whatYearEarlier(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n yıl önce',
    );
    return '$_temp0';
  }

  @override
  String whatYearLater(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n yıl sonra',
    );
    return '$_temp0';
  }

  @override
  String get whatYearDial => 'Yıl';

  @override
  String get beforeAfterTitle => 'Önce mi sonra mı?';

  @override
  String get beforeAfterRules =>
      'Altı an, art arda. Her birinin üstündekinden önce mi sonra mı olduğunu söyle. Sıralama duygunu ölçer.';

  @override
  String get beforeAfterBefore => 'Önce';

  @override
  String get beforeAfterAfter => 'Sonra';

  @override
  String beforeAfterAsk(String year) {
    return '$year öncesi mi sonrası mı?';
  }

  @override
  String beforeAfterSaidBefore(String year) {
    return 'Senin cevabın: $year öncesi';
  }

  @override
  String beforeAfterSaidAfter(String year) {
    return 'Senin cevabın: $year sonrası';
  }

  @override
  String get beforeAfterStart => 'Zincir burada başladı';

  @override
  String get beforeAfterPerfect => 'Bir tane bile şaşmadı.';

  @override
  String biggerPairsToday(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Bugün $n çift',
    );
    return '$_temp0';
  }

  @override
  String get sixtySkill => 'Sezgi';

  @override
  String get spotSkill => 'Basiret';

  @override
  String get tfSkill => 'Muhakeme';

  @override
  String get biggerSkill => 'Oran';

  @override
  String get closerSkill => 'Tahmin';

  @override
  String get magnitudeSkill => 'Ölçek';

  @override
  String get rangeSkill => 'Kalibrasyon';

  @override
  String get stakeSkill => 'Kanaat';

  @override
  String get numberSkill => 'Kesinlik';

  @override
  String get inOrderSkill => 'Kronoloji';

  @override
  String get whatYearSkill => 'Tarihleme';

  @override
  String get beforeAfterSkill => 'Sıralama';

  @override
  String get sixtyAsks => 'Zamana karşı sekiz iddia.';

  @override
  String get spotAsks => 'Dört iddia, biri yanlış.';

  @override
  String get tfAsks => 'Çoğu kişinin yanıldığı iddialar.';

  @override
  String get biggerAsks => 'İki sayı. Hangisi büyük?';

  @override
  String get closerAsks => 'Adım adım bir sayıya yaklaş.';

  @override
  String get magnitudeAsks => 'Doğru on kuvvetini bul.';

  @override
  String get rangeAsks => 'Tam gerektiği kadar geniş bir aralık.';

  @override
  String get stakeAsks => 'Ne kadar eminsen o kadar puan koy.';

  @override
  String get numberAsks => 'Tek bir sayıda karar kıl.';

  @override
  String get inOrderAsks => 'Dört an, en eskisi önce.';

  @override
  String get whatYearAsks => 'Bir anı yılına yerleştir.';

  @override
  String get beforeAfterAsks => 'Her an, bir öncekine göre.';

  @override
  String get challengeBest => 'Rekor';

  @override
  String get challengeToday => 'Bugün';

  @override
  String get challengeAccuracy => 'İsabet';

  @override
  String get challengeTime => 'Süre';

  @override
  String challengeSeconds(int s) {
    return '$s sn';
  }

  @override
  String get challengePersonalBest => 'Kişisel rekor';

  @override
  String challengeAboveChance(int n, int of) {
    return 'Şansın üzerinde: rastgele tahmin ortalama $of üzerinden $n getirir.';
  }

  @override
  String challengeAtChance(int n, int of) {
    return 'Şansla aynı düzeyde: rastgele tahmin ortalama $of üzerinden $n getirir.';
  }

  @override
  String challengeBelowChance(int n, int of) {
    return 'Şansın altında: rastgele tahmin ortalama $of üzerinden $n getirir.';
  }

  @override
  String sixtyUnanswered(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Süre doldu, $n iddia yanıtsız kaldı.',
    );
    return '$_temp0';
  }

  @override
  String get challengeAgain => 'Bir daha';

  @override
  String get spotRules =>
      'Dört iddia: üçü doğru, biri yanlış. Yanlış olanı bul. Sağlam bir iddiayı yalnızca doğru gibi görünenden ne kadar iyi ayırdığını ölçer.';

  @override
  String get spotAsk => 'Yanlış olduğunu düşündüğün iddiaya dokun.';

  @override
  String get biggerRules =>
      'İki sayı, her biri bir kartın sorusunun cevabı. Daha büyük olduğunu düşündüğüne dokun. Orantı duygunu ölçer.';

  @override
  String get biggerAsk => 'Cevabı daha büyük olan karta dokun.';

  @override
  String biggerRight(String big, String small) {
    return 'Bildin: $big, $small değerinden büyük.';
  }

  @override
  String biggerWrong(String big, String small) {
    return 'Bilemedin: $big, $small değerinden büyük.';
  }

  @override
  String get closerRules =>
      'Bir orana adım adım yaklaş: her seferinde, kalan aralığın ortasından fazla mı az mı olduğunu söyle. Tahmin yeteneğini ölçer.';

  @override
  String closerDoneSteps(String said, int right, int steps) {
    return 'Cevap $said: $steps adımın $right tanesi doğru.';
  }

  @override
  String closerExactSteps(String said, int right, int steps) {
    return 'Cevap tam olarak $said: $steps adımın $right tanesi doğru.';
  }

  @override
  String closerStepsRight(int right, int steps) {
    return '$steps adımın $right tanesi doğru.';
  }

  @override
  String get magnitudeRules =>
      'On mu, bin mi, bir milyon mu? Cevaba en yakın on kuvvetini seç. Ölçek duygunu ölçer; bu, kesin rakamlardan daha önemlidir.';

  @override
  String get rangeRules =>
      'Tahminini belirle, sonra çevresine bir aralık koy: aralık ne kadar darsa, cevap içine düşerse o kadar çok kazandırır. Kalibrasyonunu ölçer: ne kadar bildiğini bilmeyi.';

  @override
  String rangeOption(int w, int pts) {
    return '±$w · $pts kazandırır';
  }

  @override
  String rangeIn(String said, int pts) {
    String _temp0 = intl.Intl.pluralLogic(
      pts,
      locale: localeName,
      other: 'Cevap $said: aralığının içinde, +$pts puan.',
    );
    return '$_temp0';
  }

  @override
  String rangeOut(String said) {
    return 'Cevap $said: aralığının dışında.';
  }

  @override
  String stakeRules(int points) {
    return 'Bir cevap seç ve günlük $points puanından ona puan yatır: doğruysa bahsin ikiye katlanır, yanlışsa kaybolur. Kararlılığını ölçer: bildiğine, yalnızca bildiğine oynamayı.';
  }

  @override
  String stakeWon(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Bildin: $n puan kazandın.',
    );
    return '$_temp0';
  }

  @override
  String stakeLost(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Bilemedin: $n puan kaybettin.',
    );
    return '$_temp0';
  }

  @override
  String get numberRules =>
      'Düğmelerle tek bir sayı ayarla ve kilitle. Kesinliğini ölçer: tek bir sayıya bağlanman gerektiğinde ne kadar yaklaşabildiğini.';

  @override
  String tfRightIs(String side) {
    String _temp0 = intl.Intl.selectLogic(side, {
      'true': 'Bildin: doğru.',
      'other': 'Bildin: yanlış.',
    });
    return '$_temp0';
  }

  @override
  String tfWrongIs(String side) {
    String _temp0 = intl.Intl.selectLogic(side, {
      'true': 'Bilemedin: doğru.',
      'other': 'Bilemedin: yanlış.',
    });
    return '$_temp0';
  }

  @override
  String inOrderTold(int n, int of) {
    return '$of andan $n tanesi doğru yerde.';
  }

  @override
  String get whatYearYours => 'Senin yılın';

  @override
  String get whatYearExactly => 'Tam yılı';

  @override
  String beforeAfterRight(String side, String year, String above) {
    String _temp0 = intl.Intl.selectLogic(side, {
      'before': 'Bildin: $year yılıydı, $above öncesi.',
      'other': 'Bildin: $year yılıydı, $above sonrası.',
    });
    return '$_temp0';
  }

  @override
  String beforeAfterWrong(String side, String year, String above) {
    String _temp0 = intl.Intl.selectLogic(side, {
      'before': 'Bilemedin: $year yılıydı, $above öncesi.',
      'other': 'Bilemedin: $year yılıydı, $above sonrası.',
    });
    return '$_temp0';
  }

  @override
  String get challengeAnswer => 'Cevap';

  @override
  String get challengeYouSaid => 'Senin cevabın';

  @override
  String get challengePoints => 'Puan';

  @override
  String get challengeThisRound => 'Bu tur';

  @override
  String get challengeLeftToday => 'Bugün kalan';

  @override
  String exploreSubjectLevel(String subject, int n) {
    return '$subject, seviye $n';
  }

  @override
  String exploreBecauseSaved(String question) {
    return '“$question” kartını sakladığın için';
  }

  @override
  String get todaySeeAgain => 'Yeniden gör';

  @override
  String get todaySeeAgainHint =>
      'Bugünün kartları yeniden, tam boyutta, ilkinden başlayarak';

  @override
  String get yourFiveFromToday => 'Bugünkü beş kartın';

  @override
  String get dayMomentTitle => 'Gün tamam.';

  @override
  String get dayMomentLater => 'Sonra';

  @override
  String get yourDayCard => 'Senin günün';

  @override
  String get tuneTitle => 'Karışımını ayarla';

  @override
  String get tuneEntryLine => 'Her konudan ne kadar ve hangi kısımları';

  @override
  String get tuneLearned =>
      'Beğendiğin ve attığın kartlarla zaten ayarlandı. Değiştirmek için kaydır.';

  @override
  String get tuneFresh =>
      'Bir konuyu daha çok ya da daha az görmek için kaydır.';

  @override
  String get tuneHowMuch => 'Her birinden ne kadar';

  @override
  String get tuneInsideLine =>
      'En çok beğendiğin kısımlar önce gelir. Atlamak için dokun, içini görmek için basılı tut.';

  @override
  String get tuneSave => 'Kaydet';

  @override
  String get tuneHoldHint =>
      'İçindeki küçük konuları açmak için bir türe basılı tut';

  @override
  String get shareDayTitle => 'Gününü paylaş';

  @override
  String get shareDayRead => 'Beş kart, okundu';

  @override
  String get shareDayTurn => 'Günde beş kart. Sıra sende.';

  @override
  String shareDaySure(int n) {
    return '%$n emin';
  }

  @override
  String get shareDayHeadline => 'Bugünün beşi';

  @override
  String get shareFormatCover => 'Kapak';

  @override
  String get shareFormatList => 'Liste';

  @override
  String get shareFormatStory => 'Hikâye';

  @override
  String crowdGotRight(int n) {
    return 'Okurların %$n kadarı doğru bildi';
  }

  @override
  String crowdGotWrong(int n) {
    return 'Okurların %$n kadarı da yanıldı';
  }

  @override
  String get challengeFriend => 'Bir arkadaşına meydan oku';

  @override
  String get challengeLine => 'Bunu bilebilir misin?';

  @override
  String pathFree(int n) {
    return '$n ücretsiz';
  }

  @override
  String pathMoreTitle(int n) {
    return 'Bu yolda $n kart daha var.';
  }

  @override
  String get pathMoreLine =>
      'Her yol baştan sona, en kolay karttan en zoruna; her hafta da yeni bir sıra.';

  @override
  String get pathMoreGo => 'Yolun tamamını oku';

  @override
  String get paywallPathsTitle => 'Her yol, onu birden.';

  @override
  String get paywallPathsMark => 'onu birden.';

  @override
  String get paywallPathsLine =>
      'Tek konuda on kart, en kolayından en zoruna. Her hafta yeni yollar ve günün beşi senin seviyende.';

  @override
  String get widgetAskTitle => 'Yarının ilk kartı, ana ekranında.';

  @override
  String get widgetAskLine =>
      'Uygulamayı açmadan her sabah yeni bir kart, yanında da serin.';

  @override
  String get widgetAskStepHold => 'Ana ekranda boş bir yere basılı tut.';

  @override
  String get widgetAskStepAppleAdd =>
      'Düzenle\'ye, ardından Widget Ekle\'ye dokun.';

  @override
  String get widgetAskStepApplePick =>
      'Astute\'u bul, bir boyut seç ve Widget Ekle\'ye dokun.';

  @override
  String get widgetAskStepAndroidAdd => 'Widget\'lar\'a dokun.';

  @override
  String get widgetAskStepAndroidPick =>
      'Astute\'u bul, bir widget\'a basılı tutup yerine sürükle.';

  @override
  String get widgetAskLockScreen =>
      'Kilit Ekranı\'nda da olur: basılı tut, sonra Özelleştir\'e dokun.';

  @override
  String get widgetAskPin => 'Ana Ekrana Ekle';

  @override
  String get widgetAskGotIt => 'Anladım';

  @override
  String get widgetAskNotNow => 'Şimdi değil';

  @override
  String pathCardOf(int n, int total) {
    return '$total karttan $n.';
  }

  @override
  String get pathDoorNext => 'Yolda sıradaki';

  @override
  String get shareSendCard => 'Kartı gönder';

  @override
  String get shareAsImage => 'Görsel olarak';

  @override
  String get shareCopyLink => 'Bağlantıyı kopyala';

  @override
  String get shareAnswerNote =>
      'Arkadaşın önce soruyu görür. Cevap, kartın sayfasında tek dokunuş uzakta.';

  @override
  String get shareWhichSide => 'Sen hangi taraftasın?';

  @override
  String get rereadRight => 'İlk seferde doğru bildin.';

  @override
  String get rereadWrong => 'İlk seferde yanıldın.';

  @override
  String betsDayShareLine(int off) {
    String _temp0 = intl.Intl.pluralLogic(
      off,
      locale: localeName,
      other: '$off puan saptım',
      zero: 'tam isabet',
    );
    return 'Astute\'ta günün bahsi: $_temp0. Daha iyisini yapabilir misin?';
  }

  @override
  String get playTheCard => 'Kartı oyna';

  @override
  String get openTheCard => 'Kartı aç';

  @override
  String get perkPathsTitle => 'Her yol, eksiksiz';

  @override
  String get perkPathsLine =>
      'Tek bir konuda on kart, en kolaydan en zora. Her hafta yeni yollar.';

  @override
  String get journeyStrongest => 'En güçlü';

  @override
  String get journeyMostMissed => 'En çok kaçan';

  @override
  String journeyRightShare(String pct) {
    return '$pct doğru';
  }

  @override
  String get journeyChangedMind => 'Fikrin değişti';

  @override
  String get journeyNewToYou => 'Senin için yeni';

  @override
  String journeyReactedOf(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'soran $n karttan',
      one: 'soran 1 karttan',
    );
    return '$_temp0';
  }

  @override
  String journeyKnewAlready(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n tanesini zaten biliyordun',
      one: '1 tanesini zaten biliyordun',
    );
    return '$_temp0';
  }

  @override
  String get storyLabTitle => 'Yolculuğun, bir hikâye olarak';

  @override
  String get storyLabNote => 'Yeni sürüm · denemede, yalnızca TestFlight';

  @override
  String get storyChapterWeek => 'Bu hafta';

  @override
  String get storyChapterWhere => 'Neredesin';

  @override
  String get storyChapterReason => 'Nasıl akıl yürütüyorsun';

  @override
  String get storyChapterPractice => 'Pratik yap';

  @override
  String get storyChapterStory => 'Hikâyen';

  @override
  String get journeyChapterKnow => 'Neler biliyorsun';

  @override
  String get journeyChapterHabits => 'Alışkanlıkların';

  @override
  String get journeyChapterCoach => 'Koçun';

  @override
  String get coachTeaser =>
      'Her hafta koçundan nasıl akıl yürüttüğüne dair bir not: neyin iyi gittiği, dikkat etmen gereken tuzak ve sırada ne deneyeceğin.';

  @override
  String get coachRead => 'Bu haftanın notunu oku';

  @override
  String storyHeadlineSure(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Emin olduğun cevaplarda 10\'da $n kez haklıydın.',
    );
    return '$_temp0';
  }

  @override
  String get storyBetter => 'Geçen haftadan daha iyi.';

  @override
  String get storyWorse => 'Geçen haftadan biraz daha az.';

  @override
  String storyHeadlineStreak(int n) {
    return '$n gün üst üste. İpi bırakma.';
  }

  @override
  String storyHeadlineStrong(String subject, String pct) {
    return '$subject alanında zamanın $pct kadarında haklısın.';
  }

  @override
  String storyHeadlineRead(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n kart okundu. Yolculuk burada başlıyor.',
      zero: 'İlk kartın seni bekliyor.',
    );
    return '$_temp0';
  }

  @override
  String storyHeadlineReadWeek(int n, int week) {
    String _temp0 = intl.Intl.pluralLogic(
      week,
      locale: localeName,
      other: '$n kart okundu, $week tanesi bu hafta.',
      zero: '$n kart okundu, bu hafta henüz yok.',
    );
    return '$_temp0';
  }

  @override
  String storyHeadlineReadAllWeek(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n kart okundu, hepsi bu hafta.',
      one: 'Şimdiye kadar 1 kart okundu.',
    );
    return '$_temp0';
  }

  @override
  String storySaidRight(String sure, String right) {
    return 'Eminliğin: $sure. Zamanın $right kadarında haklısın.';
  }

  @override
  String storySaidRightToGo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Ne kadar emin olduğunu söylediğin $n cevap daha, ve ölçülür.',
    );
    return '$_temp0';
  }

  @override
  String storyOverconfident(String subject, int points) {
    return 'Kendine fazla güvendiğin yer: $subject, $points puan.';
  }

  @override
  String get storyUnlock => 'Astute+ ile gör';

  @override
  String storyPracticeMisses(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Emin olup yanıldığın $n kart',
    );
    return '$_temp0';
  }

  @override
  String storyPracticeChanged(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Fikrini değiştiren $n kart',
    );
    return '$_temp0';
  }

  @override
  String storyPracticeBlind(String subject) {
    return '$subject alanında 5 yeni kart';
  }

  @override
  String get storyPracticeNone =>
      'Henüz çalışacak bir şey yok: birkaç karta cevap ver, gelecek.';

  @override
  String get storyFirstCard => 'İlk kart';

  @override
  String storyReached(String level) {
    return 'Ulaşıldı: $level';
  }

  @override
  String storyBestStreak(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'En iyi seri: $n gün',
    );
    return '$_temp0';
  }

  @override
  String storyCardsRead(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n kart okundu',
    );
    return '$_temp0';
  }

  @override
  String get storyToday => 'Bugün';

  @override
  String get storySeePath => 'Yolu gör';

  @override
  String exploreFreshCards(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Üstte $n yeni kart',
    );
    return '$_temp0';
  }

  @override
  String get exploreUpToDate => 'Her şeyi gördün: şimdilik yeni bir şey yok.';

  @override
  String get deeperTitle => 'Derinleş';

  @override
  String get deeperSimple => 'Basitçe anlat';

  @override
  String get deeperWhy => 'Neden önemli';

  @override
  String get deeperSides => 'İki taraf';

  @override
  String get deeperExample => 'Günlük hayattan bir örnek';

  @override
  String get deeperQuiz => 'Beni yeni bir örnekle sına';

  @override
  String get deeperQuizRight => 'Doğru.';

  @override
  String get deeperQuizWrong => 'Tam değil.';

  @override
  String get mathsDailySolve => 'Çöz';

  @override
  String get mathsDailySolved => 'Çözüldü';

  @override
  String get mathsDailyMissed => 'Bu sefer olmadı';

  @override
  String get mathsDailyTomorrow => 'Yarın yenisi';

  @override
  String get mathsDailyAnother => 'Buna benzer bir tane daha';

  @override
  String goalShelf(String goal) {
    return 'İşine yarar: $goal';
  }

  @override
  String get goalDecide => 'Günlük kararlar';

  @override
  String get goalPeople => 'İnsanlar';

  @override
  String get goalBusiness => 'İş ve girişim';

  @override
  String get goalMoney => 'Para ve alışveriş';

  @override
  String get goalHealth => 'Sağlık';

  @override
  String get goalDecideLine =>
      'Seçimler, riskler ve olasılıklar, sezgiye kapılmadan.';

  @override
  String get goalNews => 'Haberler ve sosyal medya';

  @override
  String get goalNewsLine =>
      'Manşetler, istatistikler ve paylaşımlar: hangisi gerçekten tutarlı.';

  @override
  String get goalPeopleLine =>
      'Seni kim ikna etmeye çalışıyor ve nasıl anlaşılırsın.';

  @override
  String get goalBusinessLine =>
      'Pazarlıklar, teşvikler ve bir fikrin ardındaki rakamlar.';

  @override
  String get goalMoneyLine =>
      'Fiyatlar, indirimler, faiz: bir anlaşmadaki tuzaklar.';

  @override
  String get goalHealthLine =>
      'Diyetler, tedaviler ve araştırmalar: kanıtlar ne diyor.';

  @override
  String mathsDailyStreak(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n gün üst üste',
    );
    return '$_temp0';
  }

  @override
  String get deeperYourTake => 'Fikrin, incelendi';

  @override
  String get deeperYourTakeHint => 'Ne düşündüğünü yaz…';

  @override
  String get deeperAnalyse => 'İncele';

  @override
  String get deeperAsk => 'Bu kart hakkında sor';

  @override
  String get deeperAskHint => 'Sorun…';

  @override
  String get deeperSend => 'Sor';

  @override
  String get deeperSource => 'Kaynak';

  @override
  String get deeperOpenSource => 'Orijinali aç';

  @override
  String get deeperAiNote => 'Bir yapay zekâ yanıtlıyor: yanılabilir.';

  @override
  String get deeperBusy => 'Düşünüyorum…';

  @override
  String get deeperTomorrow => 'Bugünlük bu kadar: yarın devam.';

  @override
  String get deeperTryAgain => 'Ulaşmadı. Birazdan tekrar dene.';

  @override
  String get deeperUnavailable =>
      'Şu anda kullanılamıyor. Daha sonra tekrar dene.';

  @override
  String newsOutlets(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n yayın',
      one: '1 yayın',
    );
    return '$_temp0';
  }

  @override
  String newsHoursAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n sa önce',
      zero: 'Az önce',
    );
    return '$_temp0';
  }

  @override
  String newsDaysAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n gün önce',
      one: 'Dün',
    );
    return '$_temp0';
  }

  @override
  String get newsWorld => 'Dünya';

  @override
  String get newsKeyPoints => 'Öne çıkanlar';

  @override
  String get newsBehind => 'Haberin ardında';

  @override
  String get newsMeansForYou => 'Senin için ne anlama geliyor';

  @override
  String get newsMeans => 'Ne anlama geliyor';

  @override
  String get newsHappenedBefore => 'Daha önce de oldu';

  @override
  String get newsSources => 'Kaynaklar';

  @override
  String get newsMadeFrom =>
      'Astute bu haberlerden yazdı ve onlarla karşılaştırarak doğruladı.';

  @override
  String get newsWhyItMatters => 'Neden önemli';

  @override
  String get deeperDeclined => 'Buna yanıt veremiyor.';

  @override
  String get deeperPlusOnly => 'Astute+ ile';

  @override
  String get deeperSimpleLead =>
      'Kartın fikri, meraklı on yaşında bir çocuğa anlatır gibi.';

  @override
  String get deeperSidesLead =>
      'Her iki tarafın en güçlü gerekçeleri ve meseleyi neyin çözeceği.';

  @override
  String get deeperExampleLead =>
      'Sıradan bir günden, bu fikrin karşına çıktığı bir an.';

  @override
  String get deeperQuizLead =>
      'Kartın söz etmediği bir durum: bir soru, üç cevap.';

  @override
  String get deeperYourTakeLead =>
      'Akıl yürütmende sağlam olan, aksayan yer ve onu sınayacak bir soru.';

  @override
  String get deeperAskLead => 'Kartın sende merak bıraktığı her şey.';

  @override
  String get deeperSideA => 'Bir taraf';

  @override
  String get deeperSideB => 'Öteki taraf';

  @override
  String get deeperVersus => 'VS';

  @override
  String get deeperRetry => 'Tekrar dene';

  @override
  String get deeperSimpleGo => 'Bana anlat';

  @override
  String get deeperSidesGo => 'İki tarafı göster';

  @override
  String get deeperExampleGo => 'Bana bir örnek ver';

  @override
  String get deeperQuizGo => 'Beni sına';

  @override
  String get bookOfTheWeek => 'Haftanın kitabı';

  @override
  String bookIdeas(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n fikir',
    );
    return '$_temp0';
  }

  @override
  String bookMoreTitle(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Bu kitaptan $n fikir daha',
    );
    return '$_temp0';
  }

  @override
  String get bookMoreLine =>
      'Kitabın tamamı Astute+ ile; her hafta bir kitap ücretsiz.';

  @override
  String get bookMoreGo => 'Kitabın tamamını oku';

  @override
  String bookMinutes(int n) {
    return '$n dk';
  }

  @override
  String get bookStart => 'Okumaya başla';

  @override
  String get bookContinue => 'Devam et';

  @override
  String get bookAgain => 'Yeniden oku';

  @override
  String get bookTheIdeas => 'Fikirler';

  @override
  String get bookRecommendedBy => 'Önerenler';

  @override
  String get bookFreeThisWeek => 'Bu hafta ücretsiz';

  @override
  String get booksSeeAll => 'Tümünü gör';

  @override
  String get booksLibraryTitle => 'Tüm kitaplar';

  @override
  String get bookDoneTitle => 'Kitap bitti';

  @override
  String bookDoneLine(int ideas, int minutes) {
    return '$ideas büyük fikir, $minutes dakikada.';
  }

  @override
  String bookDoneCount(int count) {
    return 'Biten kitaplar: $count';
  }

  @override
  String get bookDoneNext => 'Sıradaki kitap';

  @override
  String get bookDoneGo => 'Aç';

  @override
  String bookRetold(String title, String author) {
    return '$author imzalı $title kitabının fikirleri, Astute\'un kendi sözleriyle. Kitabın tamamı için kitapçına bak.';
  }

  @override
  String get foundersTitle => 'Kurucular ne okuyor';

  @override
  String founderBookCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n kitap',
    );
    return '$_temp0';
  }

  @override
  String get founderTheirBooks => 'Önerdiği kitaplar';

  @override
  String founderRole(String id, String role) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'bill_gates': 'Microsoft’un kurucu ortağı',
      'warren_buffett': 'Berkshire Hathaway’i büyüten yatırımcı',
      'mark_zuckerberg': 'Facebook’un kurucusu',
      'charlie_munger': 'Warren Buffett’ın Berkshire Hathaway’deki ortağı',
      'marc_andreessen': 'Netscape ve Andreessen Horowitz’in kurucu ortağı',
      'tobi_lutke': 'Shopify’ın kurucusu',
      'naval_ravikant': 'AngelList’in kurucu ortağı',
      'other': '$role',
    });
    return '$_temp0';
  }

  @override
  String founderWhere(String id, String where) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'gates_summer': 'GatesNotes, yaz için seçtiği kitaplar',
      'berkshire_meeting': 'Berkshire Hathaway’in yıllık genel kurulu',
      'berkshire_letter': 'Berkshire Hathaway hissedarlarına mektubu',
      'year_of_books': 'Facebook’ta A Year of Books',
      'publisher_praise': 'yayınevinin sitesindeki övgüsü',
      'ferriss_five': 'The Tim Ferriss Show, okuduğu en iyi beş kitap arasında',
      'other': '$where',
    });
    return '$_temp0';
  }

  @override
  String founderAbout(String name) {
    return 'Bunlar $name adlı kişinin herkesin önünde önerdiği kitaplar; alıntılanan sözler ve söylendiği yerle birlikte. $name ile Astute arasında hiçbir bağ yok.';
  }

  @override
  String founderPhoto(String author, String licence) {
    return 'Fotoğraf: $author, $licence, Wikimedia Commons, kırpıldı';
  }

  @override
  String founderAlso(String names) {
    return 'Ayrıca önerenler: $names';
  }

  @override
  String get firstCardTitle => 'İlk kartın';

  @override
  String get firstCardSwipeOn => 'Devam etmek için kaydır';

  @override
  String get trialOfferTitle => 'Astute+’ın tamamını dene.';

  @override
  String get trialOfferMark => 'Astute+';

  @override
  String get trialOfferLine => 'Bugünün beş kartı her durumda seni bekliyor.';

  @override
  String get trialStepToday => 'Bugün';

  @override
  String get trialStepTodayLine =>
      'Astute+’ın tamamı açılır. Hiçbir şey ödemezsin.';

  @override
  String trialStepDay(int day) {
    return '$day. gün';
  }

  @override
  String trialStepReminderLine(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Sana bir bildirim göndeririz: $days gün kaldı.',
    );
    return '$_temp0';
  }

  @override
  String get trialStepChargeLine =>
      'Her yıl yenilenir. En az 24 saat önce iptal edersen hiçbir şey ödemezsin.';

  @override
  String get trialOfferStart => 'Ücretsiz denemeyi başlat';

  @override
  String get trialOfferFree => 'Ücretsiz devam et';

  @override
  String get paywallStepFree => 'Her şey ücretsiz';

  @override
  String get paywallStepRemind => 'Sana hatırlatırız';

  @override
  String get paywallChargedToday =>
      'Bugün ücretlendirilir · İstediğin zaman iptal et';

  @override
  String paywallGoalTitle(String goal) {
    String _temp0 = intl.Intl.selectLogic(goal, {
      'decide': 'Daha iyi karar vermek isteyenler için.',
      'money': 'Para konusunda kandırılmayanlar için.',
      'people': 'İnsanları anlamak isteyenler için.',
      'news': 'Manşetlere kanmayanlar için.',
      'health': 'Sağlıkta kanıt isteyenler için.',
      'business': 'İşte net görmek isteyenler için.',
      'other': 'Net görmek isteyenler için.',
    });
    return '$_temp0';
  }

  @override
  String paywallGoalMark(String goal) {
    String _temp0 = intl.Intl.selectLogic(goal, {
      'decide': 'karar',
      'money': 'Para',
      'people': 'İnsanları',
      'news': 'Manşetlere',
      'health': 'kanıt',
      'business': 'net',
      'other': 'Net',
    });
    return '$_temp0';
  }

  @override
  String paywallMadeLine(String subjects) {
    return '$subjects konularından, seviyende günde beş kart. Kaçırdıkların, akılda kalana kadar geri gelir. Ve hafta hafta değiştiğini görürsün.';
  }

  @override
  String subjectsTwo(String a, String b) {
    return '$a ve $b';
  }

  @override
  String subjectsThree(String a, String b, String c) {
    return '$a, $b ve $c';
  }

  @override
  String get firstWeekTitle => 'İlk haftan';

  @override
  String get firstMonthTitle => 'İlk ayın';

  @override
  String firstOfferDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n günlük okuma',
      one: 'Bir günlük okuma',
    );
    return '$_temp0';
  }

  @override
  String get firstWeekBest => 'Haftanın en iyi kartı';

  @override
  String get firstMonthBest => 'Ayın en iyi kartı';

  @override
  String firstOfferBestWhy(String why) {
    String _temp0 = intl.Intl.selectLogic(why, {
      'said': 'Birine anlattın.',
      'liked': 'Beğendin.',
      'saved': 'Kaydettin.',
      'changed': 'Fikrini değiştirdi.',
      'other': 'Sakladın.',
    });
    return '$_temp0';
  }

  @override
  String firstOfferTrialTitle(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Astute+ $days gün ücretsiz',
      one: 'Astute+ bir gün ücretsiz',
    );
    return '$_temp0';
  }

  @override
  String get firstOfferPlusLine =>
      'Her gün sana ait beş kart, her yol ve her kitap, bir de hafta hafta senin sayıların.';

  @override
  String get firstOfferNotNow => 'Şimdi değil';

  @override
  String get listenEntry => 'Bugünkü beşi dinle';

  @override
  String get listenEntryShort => 'Dinle';

  @override
  String get listenTitle => 'Bugünkü beş kart';

  @override
  String get listenQuestion => 'Soru';

  @override
  String get listenThink => 'Bir düşün…';

  @override
  String get listenAnswer => 'Cevap';

  @override
  String get listenPreparing => 'Ses hazırlanıyor…';

  @override
  String get listenWaiting => 'Sonraki kart yolda…';

  @override
  String get listenFreeNote => 'İlk kart ücretsiz; gerisi Astute+ ile.';

  @override
  String get listenOfferTitle => 'Bugünkü diğer kartlar, senin için okunuyor';

  @override
  String get listenOfferLine =>
      'Astute+ ile her gün beşini de dinlersin, ekran kilitliyken bile.';

  @override
  String get listenNothing => 'Bu kartta dinlenecek bir şey yok';

  @override
  String get listenCardUnavailable => 'Şu anda kullanılamıyor';

  @override
  String get listenUnavailable =>
      'Dinleme şu anda kullanılamıyor. Daha sonra tekrar dene.';

  @override
  String get listenDone => 'Bugünkü kartların hepsi dinlendi.';

  @override
  String get listenAgain => 'Yeniden dinle';

  @override
  String get listenNextCard => 'Sonraki kart';

  @override
  String summaryReadIn(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes dakikada oku',
    );
    return '$_temp0';
  }

  @override
  String get summaryContinue => 'Okumaya devam et';

  @override
  String get summaryAgain => 'Yeniden oku';

  @override
  String summaryPartOf(int part, int of) {
    return 'Bölüm $part/$of';
  }

  @override
  String summaryMinutesLeft(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n dk kaldı',
    );
    return '$_temp0';
  }

  @override
  String summaryListenFor(int minutes) {
    return 'Dinle · $minutes dk';
  }

  @override
  String get summaryPause => 'Duraklat';

  @override
  String get summaryResume => 'Dinlemeye devam et';

  @override
  String get summaryFreeNote => 'İlk bölüm ücretsiz; gerisi Astute+ ile.';

  @override
  String get summaryTitle => 'Özet';

  @override
  String get summaryNowPlaying => 'Çalıyor';

  @override
  String get summaryNextPart => 'Sonraki bölüm';

  @override
  String get summaryFinish => 'Bitir';

  @override
  String get summaryContents => 'İçindekiler';

  @override
  String summaryDoneTitle(String title) {
    return '$title kitabını okudun';
  }

  @override
  String get summaryDoneLine =>
      'Kitabın kartları fikirlerin akılda kalmasını sağlar.';

  @override
  String get summaryToCards => 'Kartlarla fikirler';

  @override
  String get summaryBackToBook => 'Kitaba dön';

  @override
  String get summaryGateTitle => 'Özetin devamı Astute+ ile';

  @override
  String summaryGateLine(int parts) {
    return 'Her kitabın $parts bölümünün tamamı, okumak ve dinlemek için. Haftanın kitabı herkese ücretsiz.';
  }

  @override
  String get summaryNeedsNetwork =>
      'Bu özet bir kez internet bağlantısı gerektirir.';

  @override
  String get bookAudioBack => '15 saniye geri';

  @override
  String get bookAudioWaiting => 'Sonraki bölüm geliyor…';

  @override
  String get bookAudioDone => 'Sonuna kadar dinlendi.';

  @override
  String get bookAudioOfferTitle => 'Kitabın devamını dinle';

  @override
  String get bookAudioOfferLine =>
      'Astute+ ile her özet baştan sona okunur, ekran kilitliyken bile.';

  @override
  String get bookAudioStop => 'Dinlemeyi durdur';

  @override
  String get bookAudioOpen => 'Oynatıcıyı aç';

  @override
  String get inviteSection => 'Arkadaşlar';

  @override
  String get inviteRow => 'Bir arkadaşını davet et';

  @override
  String get inviteRowLine => 'İkinize de bir hafta Astute+';

  @override
  String get inviteCodeRow => 'Kodun var mı?';

  @override
  String get inviteCodeAccepted => 'Kod kabul edildi';

  @override
  String get inviteCodeAcceptedLine => 'Haftan, ilk gününü bitirdiğinde başlar';

  @override
  String get inviteSheetLine =>
      'Kodunu bir arkadaşına gönder. İlk gününü, yani beş kartı bitirdiğinde ikiniz de bir hafta Astute+ alırsınız.';

  @override
  String get inviteYourCode => 'Kodun';

  @override
  String get inviteCopy => 'Kopyala';

  @override
  String get inviteSend => 'Daveti gönder';

  @override
  String inviteRules(int cap) {
    return 'Daha önce hiç Astute+ almamış yeni bir hesap için geçerli. Yılda en fazla $cap hafta alırsın.';
  }

  @override
  String inviteWeeksSoFar(int n, int cap) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Bu yıl $cap haftanın $n haftası',
    );
    return '$_temp0';
  }

  @override
  String inviteCapped(int cap) {
    return 'Bu yılın $cap haftasını aldın. Arkadaşların yine de kendi haftasını alır.';
  }

  @override
  String inviteMessage(String code, String link) {
    return 'Seni Astute’a davet ediyorum: zihnini keskin tutmak için günde beş kart. $code kodumla ilk gününü bitirdiğinde ikimiz de bir hafta Astute+ alıyoruz.\n$link';
  }

  @override
  String inviteMessageCapped(String code, String link) {
    return 'Seni Astute’a davet ediyorum: zihnini keskin tutmak için günde beş kart. $code kodumla ilk gününü bitirdiğinde bir hafta Astute+ hediye.\n$link';
  }

  @override
  String get inviteCodeTitle => 'Bir arkadaşının kodu';

  @override
  String get inviteCodeLine =>
      'Bir arkadaşının gönderdiği kodu yaz. İlk gününü bitirdiğinde ikiniz de bir hafta Astute+ alırsınız.';

  @override
  String get inviteCodeUse => 'Kodu kullan';

  @override
  String get inviteCodeWaitingLine =>
      'İlk gününü, yani beş kartı bitir: sonra Astute+ haftası başlar, hem senin hem de seni davet eden arkadaşının.';

  @override
  String get inviteRefusedUnknown =>
      'Böyle bir kod yok. Karakterleri kontrol edip tekrar dene.';

  @override
  String get inviteRefusedOwn => 'Bu senin kendi kodun: bir arkadaşına gönder.';

  @override
  String get inviteRefusedUsed => 'Bir arkadaşının kodunu zaten kullandın.';

  @override
  String get inviteRefusedLate =>
      'Kodlar yeni hesaplar içindir, ilk haftalarında.';

  @override
  String get inviteRefusedPlus =>
      'Kodlar daha önce hiç Astute+ almamış hesaplar içindir.';

  @override
  String get inviteSuccessTitle => 'Bir hafta Astute+, hediye.';

  @override
  String get inviteSuccessPlan => 'Astute+ · bir hafta';

  @override
  String inviteSuccessUntil(String date) {
    return '$date tarihine kadar';
  }

  @override
  String get inviteSuccessFoot =>
      'Ödenecek ya da iptal edilecek bir şey yok: sonra ücretsiz plana dönersin.';

  @override
  String inviteEarned(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n arkadaşın ilk gününü bitirdi: sana $n hafta Astute+.',
    );
    return '$_temp0';
  }

  @override
  String todayLineSure(int right, int asked, int sure) {
    return 'Dün $asked sorudan $right doğru, %$sure emindin.';
  }

  @override
  String todayLineRight(int right, int asked) {
    return 'Dün $asked sorudan $right doğru.';
  }

  @override
  String get todayLineRead => 'Dün beşini de okudun.';

  @override
  String todayLineFirstSubject(String subject) {
    return 'Bugün ilk kez: $subject.';
  }

  @override
  String freezeSavedLine(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days gün ara verdin: serin güvende.',
      one: 'Dün ara verdin: serin güvende.',
    );
    return '$_temp0';
  }

  @override
  String freezeCoversLine(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Bir gün atlarsan serin bozulmaz: $n dondurman var.',
      one: 'Bir gün atlarsan serin bozulmaz: 1 dondurman var.',
    );
    return '$_temp0';
  }

  @override
  String get streakMomentEyebrow => 'Üst üste';

  @override
  String streakMomentUnit(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'gün',
      one: 'gün',
    );
    return '$_temp0';
  }

  @override
  String get streakMomentWeek =>
      'Koca bir hafta. Yarın beş karttan biri daha senin için seçilecek.';

  @override
  String streakMomentNext(int next) {
    return 'Yarın $next olur.';
  }

  @override
  String get deeperWatchMore => 'Videoyu izle';
}

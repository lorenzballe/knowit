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
  String get share => 'Paylaş';

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
      'Her kart bilgilerinin nereden geldiğini söyler, böylece kendin kontrol edebilirsin. Çoğunu eleştirmen rolündeki ikinci bir model okur; doğrulayamadığı şeyler bir insanın kontrol edeceği bir listeye girer. O liste henüz boş değil.';

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
  String youSaidItIsCounted(String given, String answer, String band) {
    return '$given dedin · $answer, ve $band sayıldı';
  }

  @override
  String youSaidItIs(String given, String answer) {
    return '$given dedin · $answer';
  }

  @override
  String lineYouSaidSure(String line, int pct) {
    return '$line · %$pct emin dedin';
  }

  @override
  String get verdictRight => 'Doğru.';

  @override
  String get verdictClose => 'Yeterince yakın.';

  @override
  String get verdictWrong => 'Tam değil.';

  @override
  String verdictSure(int pct) {
    return '%$pct emindin.';
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
  String get betsLock => 'Sabitle';

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
    return 'Doğru: $v değerinden fazla.';
  }

  @override
  String betsCloserYesLess(String v) {
    return 'Doğru: $v değerinden az.';
  }

  @override
  String betsCloserNoMore(String v) {
    return 'Hayır: $v değerinden fazla.';
  }

  @override
  String betsCloserNoLess(String v) {
    return 'Hayır: $v değerinden az.';
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
  String get betsDayLine => 'Tahminini sabitle, sonra ne kadar saptığını gör';

  @override
  String get betsDayTag => 'Günün bahsi';

  @override
  String get betsDayTagSame => 'Günün bahsi · herkes için aynı';

  @override
  String get betsLockIn => 'Sabitle';

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
}

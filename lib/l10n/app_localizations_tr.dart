// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appName => 'Astut';

  @override
  String get plusName => 'Astut+';

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
    return 'BUGÜNÜN $word KARTI · TEKRAR İÇİN KAYDIR';
  }

  @override
  String weekLine(int days) {
    return 'Haftan · 7 günden $days tamam';
  }

  @override
  String get tapToFlip => 'ÇEVİRMEK İÇİN DOKUN';

  @override
  String get shareThisCard => 'Bu kartı paylaş';

  @override
  String get removeFromSaved => 'Saklananlardan çıkar';

  @override
  String get saveThisPill => 'Bu hapı sakla';

  @override
  String get shareThisPill => 'Bu hapı paylaş';

  @override
  String cardOf(int k, int n) {
    return '$n karttan $k.';
  }

  @override
  String hoursMinutes(int h, int m) {
    return '${h}s ${m}dk';
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
  String get fiveMore => 'Beş tane daha';

  @override
  String get unlockFiveExtra => 'Beş ek hapın kilidini aç';

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
  String get noPillsMatchFilter => 'Bu filtreye henüz uyan hap yok.';

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
      'Serin, sakladığın haplar ve sicilin hesabında kalır. Bu, onları bu cihazdan siler.';

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
      'Bu cihazdaki her şeyi siler — seri, saklanan haplar, yanıtlar, karar sicilin, konular ve plan — ve tanıtımı yeniden açar.';

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
  String get yourFivePillsBeforeCoffee => '5 hapın, ilk kahveden önce.';

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
      'Hatırlatma açık ama sistem izin vermedi. Ayarlardan Astut bildirimlerini aç.';

  @override
  String get nudgeOnNeedsPhone =>
      'Hatırlatma açık. Teslimat için telefon sürümü gerekir.';

  @override
  String get howMuchYouKnow => 'Ne kadar biliyorsun';

  @override
  String savedN(int n) {
    return 'Saklananlar · $n';
  }

  @override
  String get manageSubscription => 'Aboneliği yönet';

  @override
  String get howPillsAreWritten => 'Haplar nasıl yazılıyor';

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
  String get seeEveryPrincipleWithPlus => 'Astut plus ile her ilkeyi gör';

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
      'Ölçüm sürüyor. Astut+ hangi yöne gittiğini gösterir.';

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
  String get plusNameCaps => 'ASTUT+';

  @override
  String get sevenDaysFree => '7 gün ücretsiz';

  @override
  String get watchTheGapMove => 'Aralığın hareketini izle.';

  @override
  String get measurementFreeForever =>
      'Ölçüm ücretsiz ve hep öyle kalacak. Astut+ hangi yöne gittiğini söyler.';

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
      other: 'hap okundu',
      one: 'hap okundu',
    );
    return '$_temp0';
  }

  @override
  String nPillsRead(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n hap okundu',
      one: '1 hap okundu',
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
  String get streakReset => 'Seri sıfırlandı';

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
      other: '$n hap okunmadan kaldı',
      one: '1 hap okunmadan kaldı',
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
  String get whatYouAlready => 'Zaten ne ';

  @override
  String get know => 'biliyorsun';

  @override
  String get knowIntro =>
      'En yükseğe çıkardığın konular. Bir günün her birinde senden ne istediğini değiştirir — sağlam olan soru alır, meraklı olan anlatım alır — ne kadar aldığını değil.';

  @override
  String get startWithMyFirstCards => 'İlk kartlarımla başla';

  @override
  String get skipForNow => 'Şimdilik atla';

  @override
  String get levelCurious => 'Meraklı';

  @override
  String get levelSome => 'Biraz';

  @override
  String get levelSolid => 'Sağlam';

  @override
  String get save => 'Kaydet';

  @override
  String subjectsInTheMix(int n, int total) {
    return 'Karışımda $total konudan $n';
  }

  @override
  String get yourSpace => 'Senin ';

  @override
  String get mix => 'karışımın';

  @override
  String get everythingIsInDrag =>
      'Her şey içeride. Daha az görmek için bir konuyu aşağı sürükle, çıkarmak için sıfıra kadar.';

  @override
  String get next => 'İleri';

  @override
  String get whatShouldWeTalkAbout => 'Ne hakkında konuşalım?';

  @override
  String get fivePillsADayPick =>
      'Günde beş hap, her sabah taze yazılır. Karışımda istediğin konuları seç — sonra değiştirebilirsin.';

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
  String get introTopicsTitle => 'On iki konu, beş hap';

  @override
  String get introTopicsLine =>
      'Her sabah taze yazılır ve bir kaynakla doğrulanır.';

  @override
  String get introQuestionTitle => 'Bir soru, sonra yanıt';

  @override
  String get introQuestionLine =>
      'Her hap, yüksek sesle söylemeye değer o tek cümleyi taşır.';

  @override
  String get introMixTitle => 'Karışımı sen seçersin';

  @override
  String get introMixLine =>
      'Daha az görmek için bir konuyu kıs, ya da tamamen kapat.';

  @override
  String get introThirtyTitle => 'Günde otuz saniye';

  @override
  String get introThirtyLine =>
      'Bir bildirim, beş kart ve bozmak istemeyeceğin bir seri.';

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
  String get barMoveCaps => 'MASADA SÖYLENECEK SÖZ';

  @override
  String get theBarMoveCaps => 'MASADA SÖYLENECEK SÖZ';

  @override
  String get dayStreakCaps => 'GÜNLÜK SERİ';

  @override
  String sourceLabel(String source) {
    return 'Kaynak · $source';
  }

  @override
  String get perkRecordTitle => 'Zaman içinde sicilin';

  @override
  String get perkRecordLine =>
      'Ne kadar emin olduğunla ne kadar doğru olduğun arasındaki aralık gerçekten kapanıyor mu.';

  @override
  String get perkPrinciplesTitle => 'Karşılaştığın her ilke';

  @override
  String get perkPrinciplesLine =>
      'Yalnızca en zayıf olduğun üçü değil — hepsi, ve henüz gösterilmeyen bağlamlar.';

  @override
  String get perkFreezesTitle => 'Bir değil, üç seri dondurma';

  @override
  String get perkFreezesLine =>
      'Bir hafta sonu tatiline yeter. Yalnızca kaybedilebilen bir seri, eninde sonunda gider.';

  @override
  String get perkExtraTitle => 'Her gün 5 ek hap';

  @override
  String get perkExtraLine => 'İlkini bitirdiğin anda ikinci set açılır.';

  @override
  String get perkArchiveTitle => 'Tam arşiv';

  @override
  String get perkArchiveLine => 'Okuduğun her hap, konuya göre aranabilir.';

  @override
  String get perkTopicsTitle => 'Kendi konularını seç';

  @override
  String get perkTopicsLine =>
      'Karışımı gerçekten sevdiğin şeye doğru ağırlıklandır.';

  @override
  String get plusIsActive => 'ASTUT+ ETKİN';

  @override
  String tryFreeThen(String price, String suffix) {
    return '7 gün ücretsiz dene, sonra $price$suffix';
  }

  @override
  String get trialStartedNoPayment =>
      'Deneme başladı. Bu sürümde ödeme bağlı değil.';

  @override
  String get thatDidNotGoThrough => 'Bu gerçekleşmedi.';

  @override
  String get plusIsBack => 'Astut+ geri döndü.';

  @override
  String get nothingToRestore => 'Bu hesapta geri yüklenecek bir şey yok.';

  @override
  String get findOutIfBetter => 'Gerçekten gelişip gelişmediğini öğren.';

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
  String get everythingOpensNothingCharged =>
      'Her şey açılır. Hiçbir ücret alınmaz.';

  @override
  String dayN(int n) {
    return '$n. GÜN';
  }

  @override
  String get reminderTwoDaysBefore =>
      'Yenilenmeden iki gün önce bir hatırlatma.';

  @override
  String get itRenewsUnlessCancelled =>
      'İptal etmediysen yenilenir. İstediğin zaman edebilirsin.';

  @override
  String get howTheFreeWeekWorks => 'ÜCRETSİZ HAFTA NASIL İŞLER';

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
  String get shareMyDay => 'Günümü paylaş';

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
  String get holdACardYouLike => 'Beğendiğin bir karta basılı tut';

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
}

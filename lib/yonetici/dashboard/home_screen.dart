import 'dart:convert';
import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import 'package:randevu_sistem/theme/app_tokens.dart';
import 'package:randevu_sistem/theme/theme_provider.dart';
import 'package:randevu_sistem/yonetici/dashboard/ozetsayfasi_sevices.dart';
import 'package:randevu_sistem/yonetici/dashboard/profilbilgileri.dart';
import 'package:randevu_sistem/yonetici/dashboard/satisPerformanslari/kasa.dart';
import 'package:randevu_sistem/yonetici/dashboard/scaffold_layout_builder.dart';
import 'package:randevu_sistem/yonetici/diger/menu/kasa/kasaraporu.dart';
import 'package:sticky_headers/sticky_headers/widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Backend/yetki.dart';
import 'package:randevu_sistem/Frontend/dialpad.dart';
import 'package:randevu_sistem/Frontend/sfdatatable.dart';
import 'package:randevu_sistem/Models/ajanda.dart';
import 'package:randevu_sistem/Models/dashboard.dart';
import 'package:randevu_sistem/Models/e_asistan.dart';
import 'package:randevu_sistem/Models/musteri_danisanlar.dart';
import 'package:randevu_sistem/Models/paketler.dart';
import 'package:randevu_sistem/Models/sms_taslaklari.dart';
import 'package:randevu_sistem/Models/user.dart';
import '../diger/menu/whatsapp/whatsapp_yonetimi.dart';
import '../adisyonlar/adisyonpage.dart';
import '../adisyonlar/yeniadisyon.dart';
import '../diger/menu/ajanda/ajandaekle.dart';
import '../diger/menu/musteriler/yeni_musteri.dart';
import '../santral/santralraporlari.dart';
import 'bildirimler/bildirimler.dart';
import 'deneme.dart';
import 'gunlukRaporlar/gunlukajandanotlari.dart';
import 'gunlukRaporlar/rapor_liste.dart';
import 'package:randevu_sistem/yonetici/diger/menu/randvular/randevularmenu.dart';
import 'package:randevu_sistem/yonetici/diger/menu/musteriler/musteriliste.dart';
import 'package:randevu_sistem/yonetici/diger/menu/ayarlar/personeller/prim_hakedis.dart';
import 'package:randevu_sistem/yonetici/diger/menu/ongorusmeler/ongorusmeler.dart';
import 'package:randevu_sistem/yonetici/adisyonlar/satislar/tahsilat.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'ozetsayfasi.dart';
import 'package:badges/badges.dart' as badges;
import 'package:randevu_sistem/yonetici/hatirlatma/hatirlatma_overlay.dart';
import 'package:randevu_sistem/yonetici/hatirlatma/hatirlatma_model.dart';
import 'package:randevu_sistem/yonetici/cagrimerkezi/cagri_api.dart';

class DashBoard extends StatefulWidget{
  final Kullanici kullanici;
  final dynamic isletmebilgi;
  final int kullanicirolu;
  DashBoard({Key? key,required this.kullanici,required this.isletmebilgi,required this.kullanicirolu}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<DashBoard> with WidgetsBindingObserver {
  List<Map<String, dynamic>> randevuList = [];
  late Kullanici kullanici;
  late int uyelikturu;
  late Future<List<EAsistan>> futureEAsistanData;
  late int kullanicirolu;
  late String? seciliisletme;
  late String isletmeadi;
  late String _isletmeadi;
  bool _showAppBar = false;
  late AjandaDataSource _ajandaDataGridSource;
  late OzetSayfasi ozetsayfabilgi;
  late Map<String,dynamic> ajandalist;
  bool isloading = true;
  bool randevularYukleniyor = true;
  // Ozet verisi (ozetsayfabilgi) basariyla yuklendi mi? late field oldugu icin
  // network/parse hatasinda atanmazsa build erisince LateInitializationError
  // firlatir. Bu bayrak ile build'de guard edip hata ekrani gosteriyoruz.
  bool _ozetYuklendi = false;

  // Performans bölümünde seçilen periyot
  // 'gunluk' | 'haftalik' | 'aylik' | 'yillik'
  String _perfPeriod = 'aylik';

  // Periyot bazlı API yanıt cache'i — anahtar 'gunluk', 'haftalik' vb.
  final Map<String, Map<String, dynamic>> _karsCache = {};

  // Yüklenme durumu: hangi periyotlar için API hâlâ cevap bekliyor
  final Set<String> _loadingPeriods = {};

  // Faturasiz gizle modu (hesap sahibine ozel, salon-wide toggle)
  bool _faturasizGizleAktif = false;

  void _updateNotificationCount() {
    _refreshDashboardData();
  }

  Future<void> _refreshDashboardData() async {
    setState(() {
      isloading = true;
      randevularYukleniyor = true;
    });

    await initialize();
  }

  Future<void> _refreshPage() async {
    // Pull-to-refresh: ONCE yetki cache'ini tazele, SONRA dashboard verisi.
    // Paralel calistirsak yetki cache guncellenmeden randevu fetch oluyor
    // ve eski yetkiye gore filtre uygulaniyor (kullanici "tersine isliyor"
    // hissi aliyor). Siralama kritik.
    if (seciliisletme != null && seciliisletme!.isNotEmpty) {
      await Yetki.tazele(salonid: seciliisletme!);
    }
    await _refreshDashboardData();
  }

  void _onYetkiDegisti() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initialize();
    // Yetki tazelendiginde dashboard bolumleri yeniden cizilsin.
    Yetki.versiyon.addListener(_onYetkiDegisti);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    Yetki.versiyon.removeListener(_onYetkiDegisti);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // App arka plandan dondugunde web tarafindan degistirilmis olabilecek
    // faturasiz_gizle durumunu yenile (sessizce, list reload yapma)
    if (state == AppLifecycleState.resumed
        && seciliisletme != null
        && seciliisletme!.isNotEmpty
        && kullanicirolu == 1) {
      faturasizGizleDurum(seciliisletme!).then((v) {
        if (mounted) setState(() { _faturasizGizleAktif = (v == 1); });
      });
    }
  }

  Future<void> initialize() async {
    bool dataLoaded = false;
    try {
      SharedPreferences localStorage = await SharedPreferences.getInstance();
      isletmeadi = localStorage.getString('isletmeadi') ?? '';
      seciliisletme = await secilisalonid();

      // Tema bilgisini salon-bazlı server senkronu için bağla.
      if (mounted && seciliisletme != null && seciliisletme!.isNotEmpty) {
        // ignore: use_build_context_synchronously
        context.read<ThemeProvider>().bindSalon(seciliisletme!);
        // Karsilastirma (diagramlar) — fire-and-forget, sayfa build'i beklemez
        _loadKarsilastirma(_perfPeriod);
      }

      int bugunYarinTimestamp = DateTime.now().millisecondsSinceEpoch;

      // OPTIMIZE — 4 network cagrisini paralel calistir.
      // Yetki.tazele -> _gunlukRandevulariGetirInternal sirali zincir,
      // ama dashboardGunlukRapor ve easistandashboard yetkiye bagli degil,
      // onlar paralel calisir. Eskiden yetki + sonra Future.wait[3] idi,
      // yani toplam = yetki_suresi + en_yavaş_3. Yeni: max(yetki+randevu, dashboard, easistan)
      final tRandevu = (seciliisletme != null && seciliisletme!.isNotEmpty)
          ? Yetki.tazele(salonid: seciliisletme!)
              .then((_) => _gunlukRandevulariGetirInternal())
          : _gunlukRandevulariGetirInternal();
      // Rol 5 (Personel) icin dashboard'a kendi personel_id'sini gonder ki
      // backend salon toplami yerine sadece bu personelin verisini dondursun.
      final String _dashboardPersonelId = _resolvePersonelIdForRole5();
      final tDashboard =
          dashboardGunlukRapor(seciliisletme!, personelId: _dashboardPersonelId);
      final tAsistan = easistandashboard(seciliisletme!, bugunYarinTimestamp);
      // YENİ: 20s timeout — backend yanıt vermezse sonsuza kadar bekleme.
      final futures = await Future.wait([tDashboard, tAsistan, tRandevu])
          .timeout(const Duration(seconds: 20));
      final OzetSayfasi ozet = futures[0] as OzetSayfasi;
      final asistanVerileri = futures[1] as List<EAsistan>;
      final List<Map<String, dynamic>> randevulariBugun =
          futures[2] as List<Map<String, dynamic>>;

      widget.kullanici.yetkili_olunan_isletmeler.forEach((element) {
        if (element['salon_id'] == seciliisletme.toString()) {
          uyelikturu = int.parse(element['salonlar']['uyelik_turu'].toString());
        }
      });

      if (!mounted) return;
      // Salon-wide faturasiz gizle durumunu (hesap sahibine ozel) sessizce yukle
      if (seciliisletme != null && seciliisletme!.isNotEmpty) {
        faturasizGizleDurum(seciliisletme!).then((v) {
          if (mounted) setState(() { _faturasizGizleAktif = (v == 1); });
        });
      }
      setState(() {
        kullanicirolu = int.parse(widget.kullanici.yetkili_olunan_isletmeler
            .firstWhere((element) => element["salon_id"].toString() == widget.isletmebilgi["id"].toString())["role_id"]
            .toString());
        _isletmeadi = isletmeadi;
        ozetsayfabilgi = ozet;
        _ozetYuklendi = true;
        _ajandaDataGridSource = AjandaDataSource(
            isletmebilgi: widget.isletmebilgi,
            rowsPerPage: 10,
            salonid: seciliisletme!,
            context: context,
            baslik: '');
        futureEAsistanData = Future.value(asistanVerileri);
        randevuList = randevulariBugun;
      });
      dataLoaded = true;
    } catch (e, st) {
      // Network/backend hatası: ekranı preload'ta kilitlemek yerine
      // hatayı logla ve kullanıcıya bilgi ver. Boş state ile devam et.
      debugPrint('home_screen.initialize hata: $e');
      debugPrint('stack: $st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veriler yüklenemedi. Yenilemek için aşağı çekin.'),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } finally {
      // HER DURUMDA loading bayrağını kapat — sonsuz spinner'i önler.
      if (mounted) {
        setState(() {
          randevularYukleniyor = false;
          isloading = false;
        });
      }
      // Hata aldıysak _hasError flag'i için ekstra alan eklenebilir ileride;
      // şu an için snackbar + pull-to-refresh yeterli.
    }
  }

  /// Bugünkü randevuları çeken iç fonksiyon (Future.wait icin paralel).
  Future<List<Map<String, dynamic>>> _gunlukRandevulariGetirInternal() async {
    try {
      // Personel rolundeki kullanici 'randevu.tum_personel_gor' yetkisi
      // YOKSA: sadece kendi personel_id'sine ait randevular listelenir.
      // Salon sahibi / yonetici / yetkili personel ise '' (filtre yok).
      String personelidFiltre = '';
      if (widget.kullanicirolu == 5 &&
          !Yetki.varMi('randevu.tum_personel_gor')) {
        for (final e in widget.kullanici.yetkili_olunan_isletmeler) {
          if (e['salon_id'].toString() ==
              widget.isletmebilgi['id'].toString()) {
            personelidFiltre = e['id'].toString();
            break;
          } 
        }   
      }
      final data = await randevularigetir( 
        '', // musteri_id
        widget.isletmebilgi["id"].toString(),
        'Tümü', 'Tümü', 'Bugün', '1', '', personelidFiltre, '', false,
      );
      if (data.containsKey('data') && data['data'] is List) {
        return List<Map<String, dynamic>>.from(data['data']);
      }
    } catch (e) {
      print('Randevu getirme hatası: $e');
    }
    return <Map<String, dynamic>>[];
  }


  @override
  Widget build(BuildContext context) {
    if (isloading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Ozet verisi yuklenemediyse (network/parse/timeout) ozetsayfabilgi late
    // field atanmamis olur; asagidaki dashboard onu okuyunca patlar. Bu yuzden
    // once bir hata/yeniden-dene ekrani gosteriyoruz.
    if (!_ozetYuklendi) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refreshPage,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                const Icon(Icons.cloud_off_rounded,
                    size: 56, color: Colors.grey),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Panel verileri yüklenemedi.\nİnternet bağlantınızı kontrol edip '
                    'yenilemek için aşağı çekin.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: Colors.black87),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: OutlinedButton.icon(
                    onPressed: _refreshDashboardData,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Yeniden Dene'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: Stack(children: [
      Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Color.alphaBlend(
                  scheme.primary.withValues(alpha: 0.36), Colors.white),
              Color.alphaBlend(
                  scheme.tertiary.withValues(alpha: 0.08), Colors.white),
            ],
          ),
        ),
        child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: scheme.primary,
          backgroundColor: Colors.white,
          strokeWidth: 3,
          onRefresh: _refreshPage,
          child: ListView(
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              _premiumTopBar(context),
              _premiumGreeting(context),
              const SizedBox(height: 16),
              _premiumQuickStrip(context),
              const SizedBox(height: 18),
              // Bugunun Ozeti — Personel (rol 5) icin yetki bakilmadan herkes
              // ayni layout'u gorur; icerideki kutular _premiumDailyGrid
              // icinde ayrica yetki kontrolu yapmiyor.
              if (kullanicirolu == 5 ||
                  Yetki.varMi('randevu.takvim_gor') ||
                  Yetki.varMi('gorusme.liste_gor') ||
                  Yetki.varMi('rapor.satis')) ...[
                _premiumSectionHeader(context, 'Bugünün Özeti', null),
                const SizedBox(height: 10),
                _premiumDailyGrid(context),
              ],
              // Performans / Karsilastirma
              //  - Rol 5 (Personel): personel.kendi_ciro_gor yetkisi açıksa görür.
              //  - Diger roller: rapor.satis yetkisiyle gate.
              if ((kullanicirolu == 5 && Yetki.varMi('personel.kendi_ciro_gor')) ||
                  (kullanicirolu != 5 && Yetki.varMi('rapor.satis'))) ...[
                const SizedBox(height: 18),
                _periodChips(context),
                const SizedBox(height: 10),
                _premiumPerformanceRow(context),
                const SizedBox(height: 12),
                _comparisonCard(context),
                // Zirvedekiler — Personel (rol 5) icin gizli.
                if (kullanicirolu != 5 && Yetki.varMi('rapor.personel_performans')) ...[
                  const SizedBox(height: 12),
                  _topPerformersCard(context),
                ],
                // Saatlik yogunluk — Personel de kendi randevu yogunlugunu gorebilir.
                if (kullanicirolu == 5 || Yetki.varMi('randevu.takvim_gor')) ...[
                  const SizedBox(height: 12),
                  _hourlyDensityCard(context),
                ],
                // Bos Slot Onerisi — Personel (rol 5) icin gizli.
                if (kullanicirolu != 5 && Yetki.varMi('randevu.takvim_gor')) ...[
                  const SizedBox(height: 12),
                  _emptySlotOpportunitiesCard(context),
                ],
                if (widget.kullanici.yetkili_olunan_isletmeler.length > 1) ...[
                  const SizedBox(height: 12),
                  _branchPerformanceCard(context),
                ],
              ],
              // Santral — herkese gorunur.
              const SizedBox(height: 18),
              _premiumSectionHeader(context, 'Santral Aktivitesi', null),
              const SizedBox(height: 10),
              _premiumSantralRow(context),
              // Bugunun Randevulari — rol 5 icin yetki bagimsiz goster.
              if (kullanicirolu == 5 || Yetki.varMi('randevu.takvim_gor')) ...[
                const SizedBox(height: 18),
                _premiumSectionHeader(context, 'Bugünün Randevuları', null),
                const SizedBox(height: 10),
                _premiumTodayAppointments(context),
              ],
              // Asistanim — herkese gorunur (yetki kontrolu icermez)
              const SizedBox(height: 18),
              _premiumSectionHeader(context, 'Asistanım', null),
              const SizedBox(height: 10),
              _premiumEAsistan(context),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      ),
          // Hatirlatma overlay'i tum rollerde mount edilir; ICERIGI BACKEND belirler:
          // genel hatirlatmalar yalnizca rol 1/2/3'e, arama randevusu ilgili personele
          // (rol 5 acente dahil) doner. Yetkisiz rol bos feed alir.
          if (seciliisletme != null && seciliisletme!.isNotEmpty)
            HatirlatmaOverlay(
              sube: seciliisletme!,
              onAc: _hatirlatmaAc,
            ),
        ],
      ),
    );
  }

  /// Hatirlatma kartina tiklandiginda: arama randevusu ise click-to-call baslat,
  /// digerleri simdilik sadece kapanir (ileride tip'e gore navigasyon eklenebilir).
  /// Dashboard "Alacak" karti ve "geciken_alacak" hatirlatmasi AYNI modern
  /// alacak listesini (Vadesi Gelen / Gecmis Alacak) acsin diye ortak builder.
  Widget _alacaklarRaporSayfasi() {
    return RaporListeSayfa(
      baslik: 'Alacaklar',
      ikon: Icons.account_balance_wallet_outlined,
      statLabel: 'Vadesi Gelen / Geçmiş Alacak',
      aramaHint: 'Müşteri adıyla ara',
      bosBaslik: 'Tahsil edilecek alacak yok',
      bosAltyazi:
          'Vadesi gelen ve geçmiş tahsil edilmemiş alacaklar burada listelenir.',
      isletmebilgi: widget.isletmebilgi,
      fetch: alacaklarV2,
      kartMapper: (e) {
        final gecmis = e['vadesi_gecmis'] == true || e['vadesi_gecmis'] == 1;
        return RaporKart(
          musteri: (e['musteri'] ?? '').toString(),
          baslik: (e['kalem'] ?? 'Alacak').toString(),
          tarih: 'Vade: ${(e['planlanan_odeme_tarihi'] ?? '-').toString()}',
          altBilgi: gecmis ? 'Vadesi geçti' : null,
          altBilgiIcon: Icons.warning_amber_rounded,
          sagUst: '${e['tutar'] ?? '0'} ₺',
          sagUstUyari: gecmis,
          data: e,
        );
      },
      onItemTap: (ctx, item) {
        final adId = (item['adisyon_id'] ?? '').toString();
        final musId = (item['user_id'] ?? '').toString();
        final adGecerli = adId.isNotEmpty && adId != 'null' && adId != '0';
        final musGecerli = musId.isNotEmpty && musId != 'null' && musId != '0';
        if (adGecerli) {
          Navigator.push(
            ctx,
            PageTransition(
              type: PageTransitionType.rightToLeft,
              duration: const Duration(milliseconds: 400),
              child: TahsilatEkrani(
                adisyonId: adId,
                isletmebilgi: widget.isletmebilgi,
                musteridanisanid: musId,
                kullanicirolu: widget.kullanicirolu,
              ),
            ),
          );
        } else if (musGecerli) {
          Navigator.push(
            ctx,
            PageTransition(
              type: PageTransitionType.rightToLeft,
              duration: const Duration(milliseconds: 400),
              child: AdisyonlarPage(
                kullanicirolu: widget.kullanicirolu,
                kullanici: widget.kullanici,
                isletmebilgi: widget.isletmebilgi,
                geriGitBtn: true,
                ilkMusteriId: musId,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(ctx).showSnackBar(
            const SnackBar(
              content: Text(
                  'Tahsilat bilgisi alınamadı. Uygulama güncellemesi gerekebilir.'),
            ),
          );
        }
      },
    );
  }

  void _hatirlatmaAc(Hatirlatma h) async {
    // Arama randevusu: click-to-call (ekran degil aksiyon)
    if (h.aksiyon == 'arama_baslat' &&
        h.aranacakMusteriId != null &&
        seciliisletme != null) {
      try {
        final sonuc =
            await CagriApi.aramaBaslat(h.aranacakMusteriId!, seciliisletme!);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(sonuc.message.isNotEmpty ? sonuc.message : 'Arama başlatıldı'),
          duration: const Duration(seconds: 5),
        ));
      } catch (_) {}
      return;
    }

    // Hatirlatma tipine gore ilgili ekrana git.
    Widget? hedef;
    switch (h.tip) {
      case 'geciken_alacak':
        hedef = _alacaklarRaporSayfasi();
        break;
      case 'acik_adisyon':
        hedef = AdisyonlarPage(
          kullanicirolu: widget.kullanicirolu,
          kullanici: widget.kullanici,
          isletmebilgi: widget.isletmebilgi,
          geriGitBtn: true,
        );
        break;
      case 'yeni_musteri':
      case 'dogum_gunu':
        hedef = MusteriListesi(
          kullanicirolu: widget.kullanicirolu,
          isletmebilgi: widget.isletmebilgi,
        );
        break;
      case 'bekleyen_randevu':
      case 'geldi_gelmedi':
        hedef = RandevularMenu(
          kullanicirolu: widget.kullanicirolu,
          isletmebilgi: widget.isletmebilgi,
          personelid: _randevuPersonelIdFiltre(),
          cihazid: "",
          personel_adi: "",
          cihaz_adi: "",
        );
        break;
      case 'personel_odeme':
        hedef = PrimHakedis(isletmebilgi: widget.isletmebilgi);
        break;
    }
    if (hedef != null && mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => hedef!));
    }
  }

  Widget _premiumTopBar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final unread = ozetsayfabilgi.okunmamisbildirimler;
    final hasUnread = unread.isNotEmpty && unread != "0";

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _circleAction(
            context,
            icon: hasUnread
                ? Icons.notifications_active_rounded
                : Icons.notifications_none_rounded,
            badge: hasUnread ? unread : null,
            pulse: hasUnread,
            onTap: () {
              Navigator.push(
                context,
                PageTransition(
                  type: PageTransitionType.rightToLeft,
                  duration: const Duration(milliseconds: 400),
                  child: BildirimlerScreen(
                    kullanicirolu: kullanicirolu,
                    isletmebilgi: widget.isletmebilgi,
                    onNotificationRead: _updateNotificationCount,
                  ),
                ),
              ).then((_) => _refreshDashboardData());
            },
          ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isletmeadi,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: scheme.primary,
                    letterSpacing: 0.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (kullanicirolu != 5) ...[
                _whatsappMiniBadge(context, ozetsayfabilgi.whatsappBagli),
                const SizedBox(width: 8),
              ],
              _circleAction(
                context,
                icon: Icons.person_outline_rounded,
                onTap: () {
                  Navigator.push(
                    context,
                    PageTransition(
                      type: PageTransitionType.rightToLeft,
                      duration: const Duration(milliseconds: 400),
                      child: ProfilBilgileri(kullanici: widget.kullanici),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Profil ikonunun altinda gosterilen kompakt WhatsApp durum gostergesi.
  /// Yesil = bagli, kirmizi = kopuk. Tiklayinca yonetim sayfasi acilir.
  Widget _whatsappMiniBadge(BuildContext context, bool bagli) {
    final scheme = Theme.of(context).colorScheme;
    final tint = bagli ? const Color(0xFF25D366) : const Color(0xFFDC2626);
    return Tooltip(
      message: bagli ? 'WhatsApp Bağlı' : 'WhatsApp Bağlı Değil',
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 0,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WhatsappYonetimiPage(
                isletmebilgi: widget.isletmebilgi,
                kullanicirolu: kullanicirolu,
              ),
            ),
          ),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: tint.withValues(alpha: 0.14),
                  ),
                  child: Icon(
                    FontAwesomeIcons.whatsapp,
                    size: 14,
                    color: tint,
                  ),
                ),
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: tint,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _circleAction(
    BuildContext context, {
    required IconData icon,
    String? badge,
    required VoidCallback onTap,
    bool pulse = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.white,
          shape: const CircleBorder(),
          elevation: 0,
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: pulse
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white,
                          Color.alphaBlend(
                              scheme.primary.withValues(alpha: 0.07),
                              Colors.white),
                        ],
                      )
                    : null,
                color: pulse ? null : Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.12),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: scheme.primary, size: 21),
            ),
          ),
        ),
        if (badge != null)
          Positioned(
            top: -3,
            right: -3,
            child: _AnimatedBadge(badge: badge),
          ),
      ],
    );
  }

  Widget _premiumGreeting(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hoşgeldiniz 👋',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: scheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            isletmeadi,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: scheme.onSurface,
              height: 1.15,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _premiumQuickStrip(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Rol 5 (Personel) icin SMS ve Bugunku Kasa pill'leri gosterilmez.
    if (kullanicirolu == 5) {
      return const SizedBox.shrink();
    }
    // SMS pill: pazarlama.sms_gonder veya pazarlama.toplu_sms yetkisinden
    // biri acikken gosterilir; ikisi de kapaliysa gizlenir.
    final smsGoster = Yetki.varMi('pazarlama.sms_gonder') ||
        Yetki.varMi('pazarlama.toplu_sms');
    final pills = <Widget>[];
    if (smsGoster) {
      pills.add(Expanded(
        child: _quickPill(
          context,
          icon: Icons.sms_outlined,
          value: ozetsayfabilgi.kalansms,
          label: 'SMS',
          tint: scheme.primary,
        ),
      ));
    }
    // WhatsApp durum gostergesi: profil ikonunun altinda (top bar'da) — burada degil.
    if (pills.isNotEmpty) pills.add(const SizedBox(width: 10));
    pills.add(Expanded(
      child: _quickPill(
        context,
        icon: Icons.account_balance_wallet_outlined,
        // rapor.ciro_kar_gor yetkisi yoksa "****" goster.
        value: Yetki.tutarGoster('${ozetsayfabilgi.toplamkasa} ₺', 'rapor.ciro_kar_gor'),
        label: 'Bugünkü Kasa',
        tint: const Color(0xFF10B981),
      ),
    ));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: pills,
      ),
    );
  }

  Widget _quickPill(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color tint,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: tint),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                      height: 1.1,
                    ),
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurface.withValues(alpha: 0.55),
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
    );
  }

  Widget _premiumSectionHeader(
      BuildContext context, String title, VoidCallback? onSeeAll) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: scheme.onSurface,
            ),
          ),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: Row(
                children: [
                  Text(
                    'Tümü',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: scheme.primary,
                    ),
                  ),
                  Icon(Icons.arrow_forward_rounded,
                      size: 16, color: scheme.primary),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Role-5 personel 'randevu.tum_personel_gor' yetkisi yoksa sadece kendi
  /// randevularini gormeli; diger roller icin filtre yok ('').
  String _randevuPersonelIdFiltre() {
    if (kullanicirolu == 5 && !Yetki.varMi('randevu.tum_personel_gor')) {
      for (final e in widget.kullanici.yetkili_olunan_isletmeler) {
        if (e['salon_id'].toString() ==
            widget.isletmebilgi['id'].toString()) {
          return e['id'].toString();
        }
      }
    }
    return '';
  }

  /// Role-5 personel icin salondaki kendi personel_id'sini dondur. Diger
  /// roller icin bos string. Dashboard ozet ve karsilastirma API'lerine
  /// gonderilir; backend rol 5 gelirse tum salon yerine sadece bu
  /// personelin randevu/satis/tahsilat verisiyle filtreler.
  ///
  /// State icindeki `kullanicirolu`'ndan bagimsiz calisir; setState'ten
  /// once (initialize() sirasinda) cagrilabilsin diye role_id direkt
  /// yetkili_olunan_isletmeler'den okunur.
  String _resolvePersonelIdForRole5() {
    if (seciliisletme == null || seciliisletme!.isEmpty) return '';
    for (final e in widget.kullanici.yetkili_olunan_isletmeler) {
      if (e['salon_id'].toString() ==
          widget.isletmebilgi['id'].toString()) {
        final rolStr = e['role_id']?.toString() ?? '';
        if (rolStr == '5') {
          return e['id'].toString();
        }
        return '';
      }
    }
    return '';
  }

  Widget _premiumDailyGrid(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ext = context.appTheme;
    // Her kutu kendi yetkisine bagli:
    //  - Randevular   -> randevu.takvim_gor
    //  - On Gorusme   -> gorusme.liste_gor
    //  - Paket/Urun S -> rapor.satis
    final items = <_DashItem>[];
    if (kullanicirolu == 5 || Yetki.varMi('randevu.takvim_gor')) {
      items.add(_DashItem(
        icon: Icons.calendar_month_rounded,
        title: 'Randevular',
        value: ozetsayfabilgi.randevusayisi.toString(),
        tint: scheme.primary,
        onTap: () => Navigator.push(
          context,
          PageTransition(
            type: PageTransitionType.rightToLeft,
            duration: const Duration(milliseconds: 400),
            child: RandevularMenu(
              kullanicirolu: widget.kullanicirolu,
              isletmebilgi: widget.isletmebilgi,
              personelid: _randevuPersonelIdFiltre(),
              cihazid: "",
              personel_adi: "",
              cihaz_adi: "",
            ),
          ),
        ),
      ));
    }
    if (kullanicirolu == 5 || Yetki.varMi('gorusme.liste_gor')) {
      items.add(_DashItem(
        icon: Icons.chat_bubble_outline_rounded,
        title: 'Ön Görüşme',
        value: ozetsayfabilgi.ongorusmesayisi.toString(),
        tint: scheme.tertiary,
        onTap: () => Navigator.push(
          context,
          PageTransition(
            type: PageTransitionType.rightToLeft,
            duration: const Duration(milliseconds: 400),
            child: OnGorusmeler(
              isletmebilgi: widget.isletmebilgi,
              kullanicirolu: widget.kullanicirolu,
            ),
          ),
        ),
      ));
    }
    if (kullanicirolu == 5 || Yetki.varMi('rapor.satis')) {
      items.add(_DashItem(
        icon: Icons.shopping_bag_outlined,
        title: 'Paket Satışı',
        value: ozetsayfabilgi.paketsatissayisi.toString(),
        tint: ext.successColor,
        onTap: () => Navigator.push(
          context,
          PageTransition(
            type: PageTransitionType.rightToLeft,
            duration: const Duration(milliseconds: 400),
            child: AdisyonlarPage(
              kullanicirolu: widget.kullanicirolu,
              kullanici: widget.kullanici,
              isletmebilgi: widget.isletmebilgi,
              geriGitBtn: true,
              ilkSatisTuruId: "2", // Paket Satışları filtresi
            ),
          ),
        ),
      ));
      items.add(_DashItem(
        icon: Icons.inventory_2_outlined,
        title: 'Ürün Satışı',
        value: ozetsayfabilgi.urunsatissayisi.toString(),
        tint: ext.infoColor,
        onTap: () => Navigator.push(
          context,
          PageTransition(
            type: PageTransitionType.rightToLeft,
            duration: const Duration(milliseconds: 400),
            child: AdisyonlarPage(
              kullanicirolu: widget.kullanicirolu,
              kullanici: widget.kullanici,
              isletmebilgi: widget.isletmebilgi,
              geriGitBtn: true,
              ilkSatisTuruId: "3", // Ürün Satışları filtresi
            ),
          ),
        ),
      ));
    }
    if (items.isEmpty) return const SizedBox.shrink();

    // GridView yerine manuel Row of Rows — shrinkWrap içinde GridView
    // ListView'in scroll perf'ini ciddi şekilde bozuyor. Bu daha akışkan.
    final width = MediaQuery.of(context).size.width;
    final bool isTabletLandscape = width >= 900 &&
        MediaQuery.of(context).orientation == Orientation.landscape;
    final int perRow = isTabletLandscape ? 4 : 2;
    final cardW = (width - 40 - (perRow - 1) * 10) / perRow;
    final cardH = cardW / (isTabletLandscape ? 2.6 : 1.75);
    final cardFullW = width - 40; // tek kalan kutu icin tam genislik
    Widget cardSized(_DashItem it, {bool full = false}) => SizedBox(
          width: full ? cardFullW : cardW,
          height: cardH,
          child: _premiumStatCard(context, it),
        );
    // Items'i perRow'a bol — son satirda eksik varsa olduğu gibi bırak
    final rows = <Widget>[];
    for (int i = 0; i < items.length; i += perRow) {
      final remaining = items.length - i;
      if (remaining == 1 && perRow == 2) {
        rows.add(cardSized(items[i], full: true));
      } else {
        final rowChildren = <Widget>[];
        for (int j = 0; j < perRow && i + j < items.length; j++) {
          if (j > 0) rowChildren.add(const SizedBox(width: 10));
          rowChildren.add(cardSized(items[i + j]));
        }
        rows.add(Row(children: rowChildren));
      }
      if (i + perRow < items.length) rows.add(const SizedBox(height: 10));
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(children: rows),
    );
  }

  Widget _premiumStatCard(BuildContext context, _DashItem item) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Color.alphaBlend(
                item.tint.withValues(alpha: 0.07), Colors.white),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: item.onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // SOL: ikon (üstte) + başlık + "bugün" (altta)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: item.tint.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(item.icon, size: 18, color: item.tint),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface,
                            letterSpacing: -0.1,
                            height: 1.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'bugün',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w500,
                            color: scheme.onSurface.withValues(alpha: 0.50),
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                // SAĞ: büyük rakam + alt sağda yönlendirme oku
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Rakam — kartın yıldızı, sağ üstte büyük
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        item.value,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: item.tint,
                          letterSpacing: -0.8,
                          height: 1.0,
                        ),
                        maxLines: 1,
                      ),
                    ),
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 9,
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Periyot çoğaltıcısı — backend henüz periyot bazlı toplam vermediği için
  // bugünkü değeri ölçekliyoruz; backend hazır olunca buraya gerçek query gelir.
  // Periyot bazlı donut progress — visual demo (backend hazır olunca değişir)
  double _periodProgress(String kind) {
    if (kind == 'kasa') {
      switch (_perfPeriod) {
        case 'gunluk':
          return 0.35;
        case 'haftalik':
          return 0.55;
        case 'aylik':
          return 0.72;
        case 'yillik':
          return 0.88;
      }
    } else {
      switch (_perfPeriod) {
        case 'gunluk':
          return 0.18;
        case 'haftalik':
          return 0.30;
        case 'aylik':
          return 0.48;
        case 'yillik':
          return 0.62;
      }
    }
    return 0.5;
  }

  num _periodMultiplier() {
    switch (_perfPeriod) {
      case 'gunluk':
        return 1;
      case 'haftalik':
        return 7;
      case 'aylik':
        return 30;
      case 'yillik':
        return 365;
    }
    return 1;
  }

  num _parseAmount(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^0-9.,-]'), '').replaceAll(',', '.');
    return num.tryParse(cleaned) ?? 0;
  }

  String _formatAmount(num v) {
    if (v == v.roundToDouble()) return v.round().toString();
    return v.toStringAsFixed(2);
  }

  Widget _periodChips(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const periods = [
      ['gunluk', 'Günlük'],
      ['haftalik', 'Haftalık'],
      ['aylik', 'Aylık'],
      ['yillik', 'Yıllık'],
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: periods.map((p) {
          final selected = _perfPeriod == p[0];
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(999),
                child: InkWell(
                  onTap: () => _onPeriodChange(p[0]),
                  borderRadius: BorderRadius.circular(999),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected
                          ? scheme.primary
                          : scheme.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color:
                                    scheme.primary.withValues(alpha: 0.20),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      p[1],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: selected ? scheme.onPrimary : scheme.primary,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _premiumPerformanceRow(BuildContext context) {
    final ext = context.appTheme;

    // Gerçek backend verisi (cache'te) — yoksa bugünün ozet verisine düş
    // KASA = bu periyot toplam cirosu (tahsil edilmiş)
    // ALACAK = bu periyot bekleyen alacaklar
    final cache = _karsCache[_perfPeriod];
    double kasaReal;
    double alacakReal;
    if (cache != null) {
      // current.value = ciro (kasa - maliyet değil!) → kullanıcının görmek istediği
      kasaReal = (cache['current']?['value'] as num?)?.toDouble() ?? 0;
      alacakReal = (cache['alacak'] as num?)?.toDouble() ?? 0;
    } else {
      // Backend henüz yüklenmediyse: bugünkü ciro & alacak
      kasaReal = _parseAmount(ozetsayfabilgi.toplamkasa.toString()).toDouble();
      alacakReal = _parseAmount(ozetsayfabilgi.kalantutar.toString()).toDouble();
    }

    // Donut: toplam (kasa+alacak) içindeki oran — anlamlı bir yüzde
    // Kasa donut = tahsil edilen / (tahsil + bekleyen)  → tahsil yüzdesi
    // Alacak donut = bekleyen / (tahsil + bekleyen)    → kalan yüzde
    // Sadece alacak varsa ya da hiçbiri yoksa anlamsız → kasa varsa min %100
    final toplam = kasaReal + alacakReal;
    double kasaProgress;
    double alacakProgress;
    if (toplam > 0) {
      kasaProgress = kasaReal / toplam;
      alacakProgress = alacakReal / toplam;
    } else {
      kasaProgress = 0.0;
      alacakProgress = 0.0;
    }
    // Eğer kasa var ama hesaplama %0 verirse (alacak çok yüksek edge case),
    // kullanıcı görsün diye min %15 göster
    if (kasaReal > 0 && kasaProgress < 0.15) kasaProgress = 0.15;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _premiumPerfCard(
              context,
              title: 'Kasa',
              value: '${_formatAmount(kasaReal)} ₺',
              icon: Icons.account_balance_wallet_rounded,
              tint: ext.successColor,
              progress: kasaProgress,
              onTap: () {
                // Yetki yoksa hicbir yonlendirme olmaz — kart pasif.
                if (!Yetki.varMi('rapor.kasa')) return;
                Navigator.push(
                  context,
                  PageTransition(
                    type: PageTransitionType.rightToLeft,
                    duration: const Duration(milliseconds: 400),
                    child: KasaRaporu(isletmebilgi: widget.isletmebilgi),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _premiumPerfCard(
              context,
              title: 'Alacak',
              value: '${_formatAmount(alacakReal)} ₺',
              icon: Icons.payments_outlined,
              tint: ext.warningColor,
              progress: alacakProgress,
              onTap: () {
                // Yetki yoksa hicbir yonlendirme olmaz — kart pasif.
                if (!Yetki.varMi('finans.alacak_yonet')) return;
                Navigator.push(
                  context,
                  PageTransition(
                    type: PageTransitionType.rightToLeft,
                    duration: const Duration(milliseconds: 400),
                    child: RaporListeSayfa(
                            baslik: 'Alacaklar',
                            ikon: Icons.account_balance_wallet_outlined,
                            statLabel: 'Vadesi Gelen / Geçmiş Alacak',
                            aramaHint: 'Müşteri adıyla ara',
                            bosBaslik: 'Tahsil edilecek alacak yok',
                            bosAltyazi:
                                'Vadesi gelen ve geçmiş tahsil edilmemiş alacaklar burada listelenir.',
                            isletmebilgi: widget.isletmebilgi,
                            fetch: alacaklarV2,
                            kartMapper: (e) {
                              final gecmis =
                                  e['vadesi_gecmis'] == true || e['vadesi_gecmis'] == 1;
                              return RaporKart(
                                musteri: (e['musteri'] ?? '').toString(),
                                baslik: (e['kalem'] ?? 'Alacak').toString(),
                                tarih:
                                    'Vade: ${(e['planlanan_odeme_tarihi'] ?? '-').toString()}',
                                altBilgi: gecmis ? 'Vadesi geçti' : null,
                                altBilgiIcon: Icons.warning_amber_rounded,
                                sagUst: '${e['tutar'] ?? '0'} ₺',
                                sagUstUyari: gecmis,
                                data: e,
                              );
                            },
                            onItemTap: (ctx, item) {
                              final adId =
                                  (item['adisyon_id'] ?? '').toString();
                              final musId =
                                  (item['user_id'] ?? '').toString();
                              final adGecerli = adId.isNotEmpty &&
                                  adId != 'null' &&
                                  adId != '0';
                              final musGecerli = musId.isNotEmpty &&
                                  musId != 'null' &&
                                  musId != '0';
                              if (adGecerli) {
                                // Birincil: bu alacağın adisyonunun tahsilat ekranı
                                Navigator.push(
                                  ctx,
                                  PageTransition(
                                    type: PageTransitionType.rightToLeft,
                                    duration:
                                        const Duration(milliseconds: 400),
                                    child: TahsilatEkrani(
                                      adisyonId: adId,
                                      isletmebilgi: widget.isletmebilgi,
                                      musteridanisanid: musId,
                                      kullanicirolu: widget.kullanicirolu,
                                    ),
                                  ),
                                );
                              } else if (musGecerli) {
                                // Yedek: alacak adisyona bağlı değilse müşterinin
                                // Satış Takibi (açık/vadesi geçmiş adisyonları)
                                Navigator.push(
                                  ctx,
                                  PageTransition(
                                    type: PageTransitionType.rightToLeft,
                                    duration:
                                        const Duration(milliseconds: 400),
                                    child: AdisyonlarPage(
                                      kullanicirolu: widget.kullanicirolu,
                                      kullanici: widget.kullanici,
                                      isletmebilgi: widget.isletmebilgi,
                                      geriGitBtn: true,
                                      ilkMusteriId: musId,
                                    ),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Tahsilat bilgisi alınamadı. Uygulama güncellemesi gerekebilir.'),
                                  ),
                                );
                              }
                            },
                          ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _premiumPerfCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color tint,
    required VoidCallback onTap,
    double progress = 0.65,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Color.alphaBlend(tint.withValues(alpha: 0.07), Colors.white),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: tint.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Icon(icon, size: 13, color: tint),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: scheme.onSurface
                                    .withValues(alpha: 0.55),
                                letterSpacing: 0.1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Uzun TL değerleri için FittedBox ile sığdır
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          value,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: scheme.onSurface,
                          ),
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _miniDonut(context, progress: progress, tint: tint),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Backend'den karşılaştırma verisi yükle (cache + loading state)
  Future<void> _loadKarsilastirma(String period) async {
    if (seciliisletme == null || seciliisletme!.isEmpty) return;
    if (_karsCache.containsKey(period)) return;
    if (_loadingPeriods.contains(period)) return; // zaten yükleniyor
    if (mounted) setState(() => _loadingPeriods.add(period));
    final data = await dashboardKarsilastirma(
      seciliisletme!,
      period,
      personelId: _resolvePersonelIdForRole5(),
    );
    if (!mounted) return;
    setState(() {
      _loadingPeriods.remove(period);
      if (data != null) _karsCache[period] = data;
    });
  }

  /// Cache'i temizleyip ilgili periyodu yeniden yukler — kampanya
  /// olusturma gibi state'i degistiren islemlerden sonra cagrilir.
  Future<void> _refreshKarsilastirma(String period) async {
    _karsCache.remove(period);
    await _loadKarsilastirma(period);
  }

  /// Skeleton placeholder — kart içi loading için (CircularProgressIndicator yerine)
  Widget _shimmerLines(BuildContext context, ColorScheme scheme,
      {int lineCount = 3}) {
    Widget bar({double widthFactor = 1.0, double height = 12}) {
      return FractionallySizedBox(
        widthFactor: widthFactor,
        alignment: Alignment.centerLeft,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                scheme.primary.withValues(alpha: 0.06),
                scheme.primary.withValues(alpha: 0.12),
                scheme.primary.withValues(alpha: 0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      );
    }

    final widths = [1.0, 0.75, 0.85, 0.6, 0.9];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(lineCount, (i) {
          return Padding(
            padding: EdgeInsets.only(bottom: i == lineCount - 1 ? 0 : 9),
            child: bar(widthFactor: widths[i % widths.length], height: i == 0 ? 22 : 12),
          );
        }),
      ),
    );
  }

  /// Aktif gap kampanyasi icin tum musterilere SMS bildirim gonderir.
  /// Onay -> backend bulk SMS -> snackbar feedback.
  Future<void> _gonderKampanyaBildirim(
    BuildContext dialogCtx,
    Map active,
    String gapLabel,
    void Function(void Function()) setLocal, {
    required bool Function() loadingGetter,
    required void Function(bool) loadingSetter,
  }) async {
    final salonId = seciliisletme;
    final kampanyaId = (active['id'] as num?)?.toInt();
    if (salonId == null || salonId.isEmpty || kampanyaId == null) return;
    if (loadingGetter()) return;

    final ok = await showDialog<bool>(
      context: dialogCtx,
      builder: (cc) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Müşterilere SMS gönder',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
        content: Text(
          '$gapLabel kampanyanız için salonunuza kayıtlı tüm aktif müşterilere tek seferde SMS gönderilecek. SMS ücretleri salon SMS bakiyenizden düşülecek. Devam edilsin mi?',
          style: const TextStyle(fontSize: 12.5, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(cc, false),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(cc, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6A1B9A),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            icon: const Icon(Icons.sms_rounded, size: 15),
            label: const Text('Gönder'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setLocal(() => loadingSetter(true));
    final res = await saatBosluguKampanyaBildirimGonder(
      salonId: salonId,
      kampanyaId: kampanyaId,
    );
    if (!mounted) return;
    Navigator.of(dialogCtx).pop();

    final status = res?['status'] as String?;
    final gonderildi = (res?['gonderildi'] as num?)?.toInt() ?? 0;
    final apiMsg = res?['message'] as String?;

    if (status == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          content: Text(
            apiMsg ?? '$gonderildi müşteriye SMS gönderildi',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          content: Text(
            apiMsg ?? 'SMS gönderilemedi, lütfen tekrar deneyin',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }

  bool get _isLoadingCurrentPeriod => _loadingPeriods.contains(_perfPeriod);
  bool get _hasRealDataCurrentPeriod => _karsCache.containsKey(_perfPeriod);

  void _onPeriodChange(String period) {
    setState(() => _perfPeriod = period);
    _loadKarsilastirma(period); // background fetch — cache'de yoksa
  }

  // Karşılaştırma verisi — gerçek (backend) varsa onu, yoksa mock döner.
  Map<String, dynamic> _comparisonData() {
    final real = _karsCache[_perfPeriod];
    if (real != null && real['current'] != null && real['previous'] != null) {
      final cur = real['current'] as Map;
      final prev = real['previous'] as Map;
      final seriesRaw = (real['series'] as List?) ?? [];
      final series = seriesRaw
          .map((v) => (v as num).toDouble())
          .toList();
      return {
        'currentLabel': (cur['label'] ?? '').toString(),
        'previousLabel': (prev['label'] ?? '').toString(),
        'current': (cur['value'] as num? ?? 0).toDouble(),
        'previous': (prev['value'] as num? ?? 0).toDouble(),
        'series': series.isEmpty
            ? <double>[0, 0, 0, 0, 0, 0, 0]
            : series,
      };
    }
    // Gerçek veri yoksa boş döndür — UI loading veya empty state gösterir.
    // (Mock fallback kaldırıldı — kullanıcı fake rakam görmesin)
    final periodLabels = {
      'gunluk': ['Bugün', 'Geçen Aynı Gün'],
      'haftalik': ['Bu Hafta', 'Geçen Hafta'],
      'aylik': ['Bu Ay', 'Geçen Ay'],
      'yillik': ['Bu Yıl', 'Geçen Yıl'],
    };
    final labels = periodLabels[_perfPeriod] ?? ['', ''];
    return {
      'currentLabel': labels[0],
      'previousLabel': labels[1],
      'current': 0.0,
      'previous': 0.0,
      'series': <double>[0, 0, 0, 0, 0, 0, 0],
    };
  }

  // Mock karşılaştırma — backend hazır değilse fallback
  Map<String, dynamic> _mockComparisonData() {
    switch (_perfPeriod) {
      case 'gunluk':
        return {
          'currentLabel': 'Bugün',
          'previousLabel': 'Geçen Aynı Gün',
          'current': 1850.0,
          'previous': 1480.0,
          'series': [1100.0, 1300.0, 1450.0, 1280.0, 1400.0, 1620.0, 1850.0],
        };
      case 'haftalik':
        return {
          'currentLabel': 'Bu Hafta',
          'previousLabel': 'Geçen Hafta',
          'current': 9800.0,
          'previous': 8500.0,
          'series': [
            6800.0, 7400.0, 7900.0, 8500.0, 8200.0, 9100.0, 9800.0
          ],
        };
      case 'aylik':
        return {
          'currentLabel': 'Bu Ay',
          'previousLabel': 'Geçen Ay',
          'current': 42500.0,
          'previous': 38900.0,
          'series': [
            32000.0, 35000.0, 31500.0, 36200.0, 38900.0, 41000.0, 42500.0
          ],
        };
      case 'yillik':
        return {
          'currentLabel': 'Bu Yıl',
          'previousLabel': 'Geçen Yıl',
          'current': 510000.0,
          'previous': 470000.0,
          'series': [
            380000.0, 400000.0, 420000.0, 445000.0, 470000.0, 490000.0, 510000.0
          ],
        };
    }
    return {
      'currentLabel': '',
      'previousLabel': '',
      'current': 0.0,
      'previous': 0.0,
      'series': <double>[]
    };
  }

  Widget _comparisonCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ext = context.appTheme;
    final data = _comparisonData();
    final current = data['current'] as double;
    final prev = data['previous'] as double;
    final series = (data['series'] as List).cast<double>();
    // 3 durum: yüklenir / gerçek veri / boş (gerçek 0)
    final isLoading = _isLoadingCurrentPeriod && !_hasRealDataCurrentPeriod;
    final isEmpty = !isLoading && _hasRealDataCurrentPeriod &&
        current == 0 && prev == 0 &&
        !series.any((v) => v > 0);
    final delta = prev > 0 ? ((current - prev) / prev * 100) : 0.0;
    final isUp = delta >= 0;
    final deltaColor = isUp ? ext.successColor : scheme.error;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Color.alphaBlend(
                  scheme.primary.withValues(alpha: 0.05), Colors.white),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Karşılaştırma',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${data['currentLabel']} ↔ ${data['previousLabel']}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: scheme.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isEmpty && !isLoading)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: deltaColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isUp
                                ? Icons.trending_up_rounded
                                : Icons.trending_down_rounded,
                            color: deltaColor,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${isUp ? '+' : ''}${delta.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: deltaColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              if (isLoading)
                _shimmerLines(context, scheme, lineCount: 3)
              else if (isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 32,
                          color: scheme.onSurface.withValues(alpha: 0.30),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Bu ${data['currentLabel']?.toString().toLowerCase() ?? 'period'} için işlem yok',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: scheme.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Şu An',
                            style: TextStyle(
                              fontSize: 10,
                              color: scheme.onSurface.withValues(alpha: 0.55),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_formatAmount(current)} ₺',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: scheme.onSurface,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 36,
                      color: scheme.onSurface.withValues(alpha: 0.08),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Önceki',
                            style: TextStyle(
                              fontSize: 10,
                              color: scheme.onSurface.withValues(alpha: 0.55),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_formatAmount(prev)} ₺',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurface.withValues(alpha: 0.65),
                              letterSpacing: -0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 56,
                  child: _miniBars(series, deltaColor),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniBars(List<double> series, Color color) {
    if (series.isEmpty) return const SizedBox.shrink();
    final max = series.reduce((a, b) => a > b ? a : b);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(series.length, (i) {
        final v = series[i];
        final ratio = max > 0 ? (v / max) : 0.0;
        final isLast = i == series.length - 1;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: FractionallySizedBox(
              heightFactor: ratio.clamp(0.05, 1.0),
              alignment: Alignment.bottomCenter,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isLast
                        ? [color, color.withValues(alpha: 0.65)]
                        : [
                            color.withValues(alpha: 0.55),
                            color.withValues(alpha: 0.30),
                          ],
                  ),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(5)),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  // Top performers — gerçek API verisi, yoksa "veri yok" rows
  Widget _topPerformersCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ext = context.appTheme;
    final real = _karsCache[_perfPeriod];
    final topP = real?['topPersonel'] as Map?;
    final topH = real?['topHizmet'] as Map?;
    final topU = real?['topUrun'] as Map?;
    final isLoading = _isLoadingCurrentPeriod && !_hasRealDataCurrentPeriod;
    final List<Map<String, dynamic>> rows = [
      {
        'icon': Icons.person_rounded,
        'category': 'En İyi Personel',
        'name': topP?['name']?.toString() ?? '—',
        'value': topP != null
            ? '₺ ${_formatAmount((topP['value'] as num? ?? 0).toDouble())}'
            : 'Veri yok',
        'tint': scheme.primary,
        'isEmpty': topP == null,
      },
      {
        'icon': Icons.spa_rounded,
        'category': 'En Çok Satan Hizmet',
        'name': topH?['name']?.toString() ?? '—',
        'value': topH != null ? '${topH['count']} satış' : 'Veri yok',
        'tint': ext.successColor,
        'isEmpty': topH == null,
      },
      {
        'icon': Icons.shopping_bag_rounded,
        'category': 'En Çok Satan Ürün',
        'name': topU?['name']?.toString() ?? '—',
        'value': topU != null ? '${topU['count']} adet' : 'Veri yok',
        'tint': ext.warningColor,
        'isEmpty': topU == null,
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, top: 2, bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.emoji_events_rounded,
                        size: 16, color: scheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Zirvedekiler',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
              if (isLoading)
                _shimmerLines(context, scheme, lineCount: 3)
              else
              for (int i = 0; i < rows.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    color: scheme.onSurface.withValues(alpha: 0.06),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: (rows[i]['tint'] as Color)
                              .withValues(alpha: (rows[i]['isEmpty'] as bool) ? 0.06 : 0.14),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(
                          rows[i]['icon'] as IconData,
                          size: 16,
                          color: (rows[i]['isEmpty'] as bool)
                              ? (rows[i]['tint'] as Color).withValues(alpha: 0.40)
                              : rows[i]['tint'] as Color,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              rows[i]['category'] as String,
                              style: TextStyle(
                                fontSize: 10,
                                color: scheme.onSurface
                                    .withValues(alpha: 0.55),
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              rows[i]['name'] as String,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: (rows[i]['isEmpty'] as bool)
                                    ? scheme.onSurface.withValues(alpha: 0.40)
                                    : scheme.onSurface,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        rows[i]['value'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: (rows[i]['isEmpty'] as bool)
                              ? scheme.onSurface.withValues(alpha: 0.40)
                              : rows[i]['tint'] as Color,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Saat bazlı yoğunluk — salon çalışma saatlerine göre bar grafiği
  // Renkler: prime=kırmızı (yoğun), busy=primary, low=primary açık, empty=yeşil (boşluk fırsatı)
  Widget _hourlyDensityCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final real = _karsCache[_perfPeriod];
    final analysis = real?['hourlyAnalysis'] as Map?;

    // Yeni format varsa onu, yoksa eski 24 saatlik fallback
    final List<Map<String, dynamic>> hourEntries;
    final int workStart;
    final int workEnd;
    final int? peakHour;
    final bool hasData;

    if (analysis != null && analysis['hours'] is List) {
      final hs = (analysis['hours'] as List).cast<Map>();
      hourEntries = hs.map((m) => m.cast<String, dynamic>()).toList();
      workStart = (analysis['workStart'] as num?)?.toInt() ?? 9;
      workEnd = (analysis['workEnd'] as num?)?.toInt() ?? 20;
      peakHour = (analysis['peakHour'] as num?)?.toInt();
      hasData = (analysis['hasData'] as bool?) ?? true;
    } else {
      // Fallback — eski hourlyDensity ya da mock
      final realHourly = (real?['hourlyDensity'] as List?)
          ?.map((n) => (n as num).toDouble())
          .toList();
      final hours = realHourly ??
          <double>[
            0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.05,
            0.45, 0.85, 0.72, 0.55, 0.62, 0.88, 0.70, 0.55, 0.62, 0.78,
            0.95, 1.00, 0.85, 0.50, 0.10,
          ];
      // 9-21 aralığına kırp (varsayılan çalışma)
      workStart = 9;
      workEnd = (hours.length < 22) ? hours.length : 22;
      final maxIdx = hours.indexWhere(
          (v) => v == hours.reduce((a, b) => a > b ? a : b));
      peakHour = maxIdx;
      hasData = realHourly != null;
      hourEntries = [
        for (int h = workStart; h < workEnd; h++)
          {
            'hour': h,
            'count': 0,
            'density': h < hours.length ? hours[h] : 0.0,
            'level': () {
              final v = h < hours.length ? hours[h] : 0.0;
              if (v >= 0.70) return 'prime';
              if (v >= 0.40) return 'busy';
              if (v >= 0.15) return 'low';
              return 'empty';
            }(),
          }
      ];
    }

    final empty = hourEntries.isEmpty;
    final peakLabel = peakHour != null && hasData
        ? '${peakHour.toString().padLeft(2, '0')}:00'
        : '—';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.access_time_rounded,
                      size: 16, color: scheme.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Saat Bazlı Yoğunluk',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Pik: $peakLabel',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: scheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${workStart.toString().padLeft(2, '0')}:00 – ${workEnd.toString().padLeft(2, '0')}:00 çalışma saatleri',
                style: TextStyle(
                  fontSize: 10,
                  color: scheme.onSurface.withValues(alpha: 0.50),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 76,
                child: empty
                    ? Center(
                        child: Text(
                          'Bu dönemde randevu yok',
                          style: TextStyle(
                            fontSize: 11,
                            color: scheme.onSurface.withValues(alpha: 0.45),
                          ),
                        ),
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: List.generate(hourEntries.length, (i) {
                          final e = hourEntries[i];
                          final v = (e['density'] as num).toDouble();
                          final level = e['level'] as String? ?? 'empty';
                          final colors = _hourlyBarColors(scheme, level);
                          return Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 1.5),
                              child: FractionallySizedBox(
                                heightFactor: v.clamp(0.06, 1.0),
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: colors,
                                    ),
                                    borderRadius:
                                        const BorderRadius.vertical(
                                            top: Radius.circular(4)),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
              ),
              const SizedBox(height: 6),
              if (!empty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _hourlyAxisLabels(workStart, workEnd)
                      .map((label) => Text(
                            label,
                            style: TextStyle(
                              fontSize: 9,
                              color: scheme.onSurface.withValues(alpha: 0.45),
                              fontWeight: FontWeight.w600,
                            ),
                          ))
                      .toList(),
                ),
              const SizedBox(height: 10),
              // Legend
              Wrap(
                spacing: 10,
                runSpacing: 4,
                children: [
                  _hourlyLegendDot(scheme, 'prime', 'Yoğun'),
                  _hourlyLegendDot(scheme, 'busy', 'Orta'),
                  _hourlyLegendDot(scheme, 'low', 'Düşük'),
                  _hourlyLegendDot(scheme, 'empty', 'Boş'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Saat bar rengi — yoğunluk seviyesine göre
  List<Color> _hourlyBarColors(ColorScheme scheme, String level) {
    switch (level) {
      case 'prime':
        return const [Color(0xFFEF4444), Color(0xFFF87171)]; // kırmızı
      case 'busy':
        return [
          scheme.primary,
          scheme.primary.withValues(alpha: 0.65),
        ];
      case 'low':
        return [
          scheme.primary.withValues(alpha: 0.45),
          scheme.primary.withValues(alpha: 0.22),
        ];
      case 'empty':
      default:
        return const [Color(0xFF22C55E), Color(0xFF86EFAC)]; // yeşil
    }
  }

  Widget _hourlyLegendDot(ColorScheme scheme, String level, String label) {
    final colors = _hourlyBarColors(scheme, level);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: colors.first,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface.withValues(alpha: 0.65),
          ),
        ),
      ],
    );
  }

  // X-ekseni için 4-5 etiket üret (workStart, ara noktalar, workEnd)
  List<String> _hourlyAxisLabels(int start, int end) {
    final span = end - start;
    if (span <= 1) return ['$start:00'];
    if (span <= 4) {
      return [
        for (int h = start; h <= end; h++) h.toString().padLeft(2, '0')
      ];
    }
    final mid1 = start + (span / 3).round();
    final mid2 = start + (2 * span / 3).round();
    return [
      start.toString().padLeft(2, '0'),
      mid1.toString().padLeft(2, '0'),
      mid2.toString().padLeft(2, '0'),
      end.toString().padLeft(2, '0'),
    ];
  }

  // Boşluk Fırsatları — indirim kampanyası önerisi kartı
  Widget _emptySlotOpportunitiesCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final real = _karsCache[_perfPeriod];
    final analysis = real?['hourlyAnalysis'] as Map?;

    // 3 durum: (a) backend hala yeni alan vermiyor (b) gap yok / hepsi dolu
    // (c) normal liste — her durumda karti gosterelim
    final gapsList = analysis?['gaps'] as List?;
    final gaps = (gapsList ?? [])
        .cast<Map>()
        .map((m) => m.cast<String, dynamic>())
        .toList();

    // Sadece "anlamli" olanlari (onerilen indirim > 0 veya aktif kampanyasi var) gosterelim
    final shownGaps = gaps.where((g) {
      final disc = (g['suggestedDiscount'] as num?)?.toInt() ?? 0;
      final hasActive = g['activeCampaign'] != null;
      return disc > 0 || hasActive;
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.lightbulb_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Boşluk Doldurma Önerisi',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          shownGaps.isEmpty
                              ? 'Boş saat analizi'
                              : 'Boş saatleri indirim kampanyasıyla doldurun',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: scheme.onSurface.withValues(alpha: 0.55),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (analysis == null)
                _gapInfoBanner(
                  context,
                  icon: Icons.refresh_rounded,
                  color: const Color(0xFF6B7280),
                  title: 'Boşluk analizi hazırlanıyor',
                  message:
                      'Birkaç dakika içinde saat analizi tamamlanacak. Dashboard\'ı yenilemeyi deneyin.',
                )
              else if (shownGaps.isEmpty)
                _gapInfoBanner(
                  context,
                  icon: Icons.celebration_rounded,
                  color: const Color(0xFF16A34A),
                  title: 'Saatleriniz oldukça dolu',
                  message:
                      'Şu an için indirim kampanyası önerisi yok. Salonunuzda belirgin bir boşluk saati tespit edilmedi.',
                )
              else
                for (int i = 0; i < shownGaps.length; i++) ...[
                  _gapOpportunityTile(context, shownGaps[i]),
                  if (i < shownGaps.length - 1) const SizedBox(height: 10),
                ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _gapInfoBanner(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String message,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.4,
                    color: scheme.onSurface.withValues(alpha: 0.65),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _gapOpportunityTile(BuildContext context, Map<String, dynamic> gap) {
    final scheme = Theme.of(context).colorScheme;
    final key = gap['key'] as String? ?? 'morning';
    final label = gap['label'] as String? ?? 'Saatler';
    final start = (gap['start'] as num?)?.toInt() ?? 0;
    final end = (gap['end'] as num?)?.toInt() ?? 0;
    final avg = ((gap['avgDensity'] as num?)?.toDouble() ?? 0) * 100;
    final disc = (gap['suggestedDiscount'] as num?)?.toInt() ?? 0;
    final severity = gap['severity'] as String? ?? '';
    final active = gap['activeCampaign'] as Map?;
    final isActive = active != null;
    final activeDisc = isActive ? (active['discount'] as num?)?.toInt() ?? 0 : 0;
    final kalanGun = isActive ? (active['kalanGun'] as num?)?.toInt() ?? 0 : 0;

    IconData icon;
    List<Color> grad;
    switch (key) {
      case 'morning':
        icon = Icons.wb_twilight_rounded;
        grad = const [Color(0xFFFDE68A), Color(0xFFFCD34D)];
        break;
      case 'afternoon':
        icon = Icons.wb_sunny_rounded;
        grad = const [Color(0xFFFED7AA), Color(0xFFFB923C)];
        break;
      case 'evening':
      default:
        icon = Icons.nightlight_round;
        grad = const [Color(0xFFDDD6FE), Color(0xFF8B5CF6)];
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFFF0FDF4) // çok hafif yeşil arka plan
            : scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive
              ? const Color(0xFF22C55E).withValues(alpha: 0.55)
              : scheme.outline.withValues(alpha: 0.12),
          width: isActive ? 1.4 : 1,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: grad),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$label  •  ${start.toString().padLeft(2, '0')}:00-${end.toString().padLeft(2, '0')}:00',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isActive
                          ? 'Doluluk: %${avg.toStringAsFixed(0)}  •  Kampanya aktif'
                          : 'Ortalama doluluk: %${avg.toStringAsFixed(0)}  •  $severity',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: scheme.onSurface.withValues(alpha: 0.55),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isActive
                        ? const [Color(0xFF16A34A), Color(0xFF15803D)]
                        : const [Color(0xFF22C55E), Color(0xFF16A34A)],
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isActive) ...[
                      const Icon(Icons.check_circle_rounded,
                          size: 12, color: Colors.white),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      isActive ? '%$activeDisc Aktif' : '%$disc indirim',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isActive) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined,
                      size: 13, color: Color(0xFF15803D)),
                  const SizedBox(width: 6),
                  Text(
                    kalanGun > 0
                        ? '$kalanGun gün kaldı'
                        : 'Bugün son gün',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF15803D),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          isActive
              ? SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showGapDetailDialog(context, gap),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF15803D),
                      side: const BorderSide(
                        color: Color(0xFF22C55E),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.visibility_rounded, size: 14),
                    label: const Text(
                      'Detayları Gör',
                      style: TextStyle(
                          fontSize: 11.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                )
              : Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showGapDetailDialog(context, gap),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: scheme.primary,
                          side: BorderSide(
                            color: scheme.primary.withValues(alpha: 0.30),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.info_outline_rounded, size: 14),
                        label: const Text(
                          'Detay',
                          style: TextStyle(
                              fontSize: 11.5, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showGapDetailDialog(context, gap),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: scheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.campaign_rounded, size: 14),
                        label: const Text(
                          'Kampanya Hazırla',
                          style: TextStyle(
                              fontSize: 11.5, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  void _showGapDetailDialog(BuildContext context, Map<String, dynamic> gap) {
    final scheme = Theme.of(context).colorScheme;
    final key = gap['key'] as String? ?? 'morning';
    final label = gap['label'] as String? ?? 'Saatler';
    final start = (gap['start'] as num?)?.toInt() ?? 0;
    final end = (gap['end'] as num?)?.toInt() ?? 0;
    final avg = ((gap['avgDensity'] as num?)?.toDouble() ?? 0) * 100;
    final disc = (gap['suggestedDiscount'] as num?)?.toInt() ?? 0;
    final msg = gap['message'] as String? ?? '';
    final active = gap['activeCampaign'] as Map?;
    final isActive = active != null;
    final activeDisc = isActive ? (active['discount'] as num?)?.toInt() ?? 0 : 0;
    final kalanGun = isActive ? (active['kalanGun'] as num?)?.toInt() ?? 0 : 0;
    final activeBaslik = isActive ? active['baslik'] as String? : null;

    bool loading = false;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isActive
                              ? const [Color(0xFF22C55E), Color(0xFF16A34A)]
                              : const [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isActive
                            ? Icons.check_circle_rounded
                            : Icons.lightbulb_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isActive
                            ? '$label Kampanyası Aktif'
                            : '$label Boşluk Önerisi',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (isActive) ...[
                  _dialogInfoRow(
                    context,
                    Icons.campaign_rounded,
                    'Kampanya',
                    activeBaslik ?? '$label - %$activeDisc',
                  ),
                  const SizedBox(height: 10),
                  _dialogInfoRow(
                    context,
                    Icons.schedule_rounded,
                    'Saat aralığı',
                    '${start.toString().padLeft(2, '0')}:00 – ${end.toString().padLeft(2, '0')}:00',
                  ),
                  const SizedBox(height: 10),
                  _dialogInfoRow(
                    context,
                    Icons.local_offer_rounded,
                    'İndirim',
                    '%$activeDisc',
                    valueColor: const Color(0xFF16A34A),
                  ),
                  const SizedBox(height: 10),
                  _dialogInfoRow(
                    context,
                    Icons.timer_outlined,
                    'Kalan süre',
                    kalanGun > 0 ? '$kalanGun gün' : 'Bugün son gün',
                    valueColor: const Color(0xFF15803D),
                  ),
                ] else ...[
                  _dialogInfoRow(
                    context,
                    Icons.schedule_rounded,
                    'Saat aralığı',
                    '${start.toString().padLeft(2, '0')}:00 – ${end.toString().padLeft(2, '0')}:00',
                  ),
                  const SizedBox(height: 10),
                  _dialogInfoRow(
                    context,
                    Icons.show_chart_rounded,
                    'Ortalama doluluk',
                    '%${avg.toStringAsFixed(0)}',
                  ),
                  const SizedBox(height: 10),
                  _dialogInfoRow(
                    context,
                    Icons.local_offer_rounded,
                    'Önerilen indirim',
                    '%$disc',
                    valueColor: const Color(0xFF16A34A),
                  ),
                  const SizedBox(height: 10),
                  _dialogInfoRow(
                    context,
                    Icons.event_rounded,
                    'Geçerlilik',
                    '7 gün',
                  ),
                ],
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF22C55E).withValues(alpha: 0.08)
                        : scheme.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    msg,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: scheme.onSurface.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (isActive)
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: loading
                              ? null
                              : () => _gonderKampanyaBildirim(
                                  ctx, active, label, setLocal,
                                  loadingGetter: () => loading,
                                  loadingSetter: (v) => loading = v),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6A1B9A),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(11)),
                          ),
                          icon: const Icon(Icons.sms_rounded, size: 16),
                          label: const Text(
                            'Müşterilere SMS Gönder',
                            style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: loading
                              ? null
                              : () async {
                                  final salonId = seciliisletme;
                                  final kampanyaId =
                                      (active['id'] as num?)?.toInt();
                                  if (salonId == null ||
                                      salonId.isEmpty ||
                                      kampanyaId == null) {
                                    return;
                                  }
                                  final ok = await showDialog<bool>(
                                    context: ctx,
                                    builder: (cc) => AlertDialog(
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16)),
                                      title: const Text(
                                        'Kampanyayı iptal et',
                                        style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800),
                                      ),
                                      content: Text(
                                        '$label saatleri için aktif kampanyayı durdurmak istediğinize emin misiniz? Bu işlem geri alınamaz.',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(cc, false),
                                          child: const Text('Vazgeç'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () =>
                                              Navigator.pop(cc, true),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFFEF4444),
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                          ),
                                          child: const Text('İptal Et'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (ok != true) return;

                                  setLocal(() => loading = true);
                                  final res =
                                      await saatBosluguKampanyaIptal(
                                    salonId: salonId,
                                    kampanyaId: kampanyaId,
                                  );
                                  if (!mounted) return;
                                  Navigator.of(ctx).pop();

                                  final status = res?['status'] as String?;
                                  if (status == 'success') {
                                    _refreshKarsilastirma(_perfPeriod);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        backgroundColor:
                                            const Color(0xFF16A34A),
                                        behavior: SnackBarBehavior.floating,
                                        content: Text(
                                          '$label kampanyası iptal edildi',
                                          style: const TextStyle(
                                              color: Colors.white),
                                        ),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        backgroundColor:
                                            const Color(0xFFEF4444),
                                        behavior: SnackBarBehavior.floating,
                                        content: Text(
                                          res?['message'] as String? ??
                                              'Kampanya iptal edilemedi',
                                          style: const TextStyle(
                                              color: Colors.white),
                                        ),
                                      ),
                                    );
                                  }
                                },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFEF4444),
                            side: const BorderSide(
                                color: Color(0xFFEF4444), width: 1.2),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: loading
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(
                                        Color(0xFFEF4444)),
                                  ),
                                )
                              : const Icon(Icons.cancel_outlined, size: 16),
                          label: const Text(
                            'Kampanyayı İptal Et',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: loading
                              ? null
                              : () => Navigator.of(ctx).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text(
                            'Tamam',
                            style: TextStyle(
                                fontSize: 12.5, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextButton(
                          onPressed: loading
                              ? null
                              : () => Navigator.of(ctx).pop(),
                          child: const Text('Kapat',
                              style: TextStyle(fontSize: 13)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: ElevatedButton(
                          onPressed: loading
                              ? null
                              : () async {
                                  final salonId = seciliisletme;
                                  if (salonId == null || salonId.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Salon seçili değil')),
                                    );
                                    return;
                                  }
                                  setLocal(() => loading = true);
                                  final res =
                                      await saatBosluguKampanyaOlustur(
                                    salonId: salonId,
                                    gapKey: key,
                                    gapLabel: label,
                                    startHour: start,
                                    endHour: end,
                                    discount: disc,
                                  );
                                  if (!mounted) return;
                                  Navigator.of(ctx).pop();

                                  final status = res?['status'] as String?;
                                  final apiMsg = res?['message'] as String?;
                                  Color bg;
                                  String text;
                                  if (status == 'success') {
                                    bg = const Color(0xFF16A34A);
                                    text = apiMsg ??
                                        '$label için %$disc indirimli kampanya oluşturuldu';
                                    // Dashboard'i refresh et — aktif kampanya kart'ta gozuksun
                                    _refreshKarsilastirma(_perfPeriod);
                                  } else if (status == 'duplicate') {
                                    bg = const Color(0xFFF59E0B);
                                    text = apiMsg ??
                                        '$label için aktif kampanya zaten var';
                                    _refreshKarsilastirma(_perfPeriod);
                                  } else {
                                    bg = const Color(0xFFEF4444);
                                    text = apiMsg ??
                                        'Kampanya oluşturulamadı, lütfen tekrar deneyin';
                                  }
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: bg,
                                      behavior: SnackBarBehavior.floating,
                                      content: Text(
                                        text,
                                        style: const TextStyle(
                                            color: Colors.white),
                                      ),
                                    ),
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: scheme.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: loading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(
                                        Colors.white),
                                  ),
                                )
                              : const FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'Kampanya Hazırla',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dialogInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 15, color: scheme.onSurface.withValues(alpha: 0.55)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: scheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: valueColor ?? scheme.onSurface,
          ),
        ),
      ],
    );
  }

  // Şubeler arası performans — multi-salon için (mock veri)
  Widget _branchPerformanceCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ext = context.appTheme;
    // Mock: salon listesini al, ilk 3'e fake değer at
    final branches = widget.kullanici.yetkili_olunan_isletmeler;
    final mockValues = [42500.0, 28900.0, 18400.0, 14200.0, 9800.0];
    final colors = [
      scheme.primary,
      ext.successColor,
      ext.warningColor,
      ext.infoColor,
      scheme.tertiary,
    ];
    final maxValue = mockValues.first;
    final shown = branches.length > 5 ? 5 : branches.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.storefront_rounded,
                      size: 16, color: scheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Şubeler',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              for (int i = 0; i < shown; i++) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              branches[i]['salonlar']['salon_adi'].toString(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: scheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_formatAmount(mockValues[i])} ₺',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: colors[i],
                              letterSpacing: -0.1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: mockValues[i] / maxValue,
                          minHeight: 6,
                          backgroundColor:
                              colors[i].withValues(alpha: 0.12),
                          valueColor: AlwaysStoppedAnimation(colors[i]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Kâr - Maliyet özet kartı (backend hazırsa gerçek, yoksa mock %40)
  Widget _profitMarginCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ext = context.appTheme;
    final real = _karsCache[_perfPeriod];
    final ciro = _comparisonData()['current'] as double;
    final maliyet = (real?['maliyet'] as num?)?.toDouble() ?? (ciro * 0.40);
    final kar = (real?['kar'] as num?)?.toDouble() ?? (ciro - maliyet);
    final marj = ciro > 0 ? (kar / ciro * 100) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Color.alphaBlend(
                  ext.successColor.withValues(alpha: 0.06), Colors.white),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.trending_up_rounded,
                      size: 16, color: ext.successColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Kâr - Maliyet',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: ext.successColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '%${marj.toStringAsFixed(1)} marj',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: ext.successColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _profitMetric(context,
                        label: 'Ciro',
                        value: ciro,
                        color: scheme.primary),
                  ),
                  Container(
                    width: 1,
                    height: 30,
                    color: scheme.onSurface.withValues(alpha: 0.08),
                  ),
                  Expanded(
                    child: _profitMetric(context,
                        label: 'Maliyet',
                        value: maliyet,
                        color: scheme.error),
                  ),
                  Container(
                    width: 1,
                    height: 30,
                    color: scheme.onSurface.withValues(alpha: 0.08),
                  ),
                  Expanded(
                    child: _profitMetric(context,
                        label: 'Kâr',
                        value: kar,
                        color: ext.successColor),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profitMetric(BuildContext context,
      {required String label, required double value, required Color color}) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: scheme.onSurface.withValues(alpha: 0.55),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${_formatAmount(value)}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: -0.2,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          '₺',
          style: TextStyle(
            fontSize: 9,
            color: scheme.onSurface.withValues(alpha: 0.45),
          ),
        ),
      ],
    );
  }

  Widget _miniDonut(BuildContext context,
      {required double progress, required Color tint}) {
    final scheme = Theme.of(context).colorScheme;
    final clamped = progress.clamp(0.0, 1.0);
    // Key her periyot/değer değişiminde widget'ı yeniden mount eder
    // → animasyon 0'dan başa sarılır, kullanıcı hareketi net görür
    return SizedBox(
      width: 48,
      height: 48,
      child: TweenAnimationBuilder<double>(
        key: ValueKey('${_perfPeriod}_${clamped.toStringAsFixed(3)}'),
        tween: Tween<double>(begin: 0, end: clamped),
        duration: const Duration(milliseconds: 1100),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) {
          final pct = (value * 100).round();
          return Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  value: value,
                  strokeWidth: 5,
                  strokeCap: StrokeCap.round,
                  backgroundColor: tint.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation(tint),
                ),
              ),
              Text(
                '%$pct',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _premiumSantralRow(BuildContext context) {
    final ext = context.appTheme;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _santralPill(
              context,
              icon: Icons.call_made_rounded,
              count: ozetsayfabilgi.gidenarama,
              label: 'Giden',
              tint: ext.successColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _santralPill(
              context,
              icon: Icons.call_received_rounded,
              count: ozetsayfabilgi.gelenarama,
              label: 'Gelen',
              tint: scheme.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _santralPill(
              context,
              icon: Icons.phone_missed_rounded,
              count: ozetsayfabilgi.cevapsizarama,
              label: 'Cevapsız',
              tint: scheme.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _santralPill(
    BuildContext context, {
    required IconData icon,
    required String count,
    required String label,
    required Color tint,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Color.alphaBlend(tint.withValues(alpha: 0.07), Colors.white),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: tint.withValues(alpha: 0.04),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            PageTransition(
              type: PageTransitionType.rightToLeft,
              duration: const Duration(milliseconds: 300),
              child: CDRRaporlari(
                isletmebilgi: widget.isletmebilgi,
                kullanici: widget.kullanici,
                kullanicirolu: widget.kullanicirolu,
                // Bu ekran icin islevsel degil (tus takimi butonu kaldirildi);
                // zorunlu parametreleri karsilamak icin bos ornekler.
                dialPadManager: DialPadManager(),
                scaffoldMessengerKey: GlobalKey<ScaffoldMessengerState>(),
              ),
            ),
          ),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: tint.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 16, color: tint),
                ),
                const SizedBox(height: 10),
                Text(
                  count,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: tint,
                    letterSpacing: -0.4,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _premiumTodayAppointments(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (randevularYukleniyor) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: _glassEmpty(context,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )),
      );
    }
    if (randevuList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: _glassEmpty(context,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'Bugün için randevu bulunmuyor',
                  style: TextStyle(
                    color: scheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ),
            )),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: _glassEmpty(
        context,
        child: ListCardRandevular(randevular: randevuList),
      ),
    );
  }

  Widget _premiumEAsistan(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: _glassEmpty(
        context,
        child: FutureBuilder<List<EAsistan>>(
          future: futureEAsistanData,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              );
            } else if (snapshot.hasError) {
              return const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: Text('Veri alınırken hata oluştu')),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    'Bugün için tablo boş',
                    style: TextStyle(
                      color: scheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ),
              );
            } else {
              return ListCard(tasks: snapshot.data!);
            }
          },
        ),
      ),
    );
  }

  Widget _glassEmpty(BuildContext context, {required Widget child}) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: child,
      ),
    );
  }

  Widget _appBar(BuildContext context, ColorAnimated colorAnimated) {
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    return AppBar(
        automaticallyImplyLeading: false,
        elevation: 100,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isletmeadi,
              style: TextStyle(color: onPrimary, fontSize: 16),
            ),
            SizedBox(width: 28),
            Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ozetsayfabilgi.okunmamisbildirimler != "" &&
                        ozetsayfabilgi.okunmamisbildirimler != "0"
                        ? Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              PageTransition(
                                type: PageTransitionType.rightToLeft,
                                duration: Duration(milliseconds: 500),
                                child: BildirimlerScreen(
                                  kullanicirolu: kullanicirolu,
                                  isletmebilgi: widget.isletmebilgi,
                                  onNotificationRead: _updateNotificationCount,
                                ),
                              ),
                            ).then((_) {
                              _refreshDashboardData();
                            });
                          },
                          icon: Icon(
                            Icons.notifications_active,
                            color: onPrimary,
                          ),
                          iconSize: 20,
                        ),
                        Positioned(
                          right: 10,
                          top: 13,
                          child: badges.Badge(
                            badgeStyle: badges.BadgeStyle(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 3),
                              badgeColor: Colors.red,
                            ),
                            badgeContent: Text(
                              ozetsayfabilgi.okunmamisbildirimler,
                              style: TextStyle(
                                  color: Colors.white, fontSize: 10),
                            ),
                            child: SizedBox.shrink(),
                          ),
                        ),
                      ],
                    )
                        : IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          PageTransition(
                            type: PageTransitionType.rightToLeft,
                            duration: Duration(milliseconds: 500),
                            child: BildirimlerScreen(
                              kullanicirolu: kullanicirolu,
                              isletmebilgi: widget.isletmebilgi,
                              onNotificationRead: _updateNotificationCount,
                            ),
                          ),
                        ).then((_) {
                          _refreshDashboardData();
                        });
                      },
                      icon: Icon(
                        Icons.notifications_active,
                        color: onPrimary,
                      ),
                      iconSize: 20,
                    ),
                    if (kullanicirolu == 1)
                      IconButton(
                        onPressed: () async {
                          if (seciliisletme == null || seciliisletme!.isEmpty) return;
                          // Disclaimer: SADECE aktif ederken (kapalidan acmaya gecerken).
                          // Mod zaten acikken kapatma islemi uyari gerektirmez.
                          if (!_faturasizGizleAktif && mounted) {
                            final onay = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                title: Row(children: [
                                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                                  SizedBox(width: 10),
                                  Text('Bilgilendirme'),
                                ]),
                                content: SingleChildScrollView(
                                  child: Text(
                                    'Bu mod yalnizca yonetim raporu gorunumunuzu etkiler.\n\n'
                                    'Tum satis kayitlariniz sistemde tutulmaya devam eder, hicbiri silinmez.\n\n'
                                    'Vergi yukumluluklerinizi (fatura/fis kesme, beyan) karsiladiginizdan emin olunuz. Bu ozellik bir muhasebe takip aracidir, vergi yukumluluk muafiyeti saglamaz.',
                                    style: TextStyle(fontSize: 14, height: 1.5),
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(false),
                                    child: Text('Vazgec', style: TextStyle(color: Colors.grey.shade600)),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.of(ctx).pop(true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green.shade600,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: Text('Anladim, devam et'),
                                  ),
                                ],
                              ),
                            );
                            if (onay != true) return;
                          }
                          final yeni = await faturasizGizleToggle(seciliisletme!, widget.kullanici.id.toString());
                          if (yeni >= 0 && mounted) setState(() { _faturasizGizleAktif = (yeni == 1); });
                        },
                        icon: Icon(
                          Icons.receipt_long,
                          color: _faturasizGizleAktif ? Colors.amberAccent : onPrimary,
                        ),
                        iconSize: 20,
                      ),
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            PageTransition(
                                type: PageTransitionType.rightToLeft,
                                duration: Duration(milliseconds: 500),
                                child: ProfilBilgileri(kullanici: widget.kullanici)));
                      },
                      icon: Icon(Icons.person, color: onPrimary),
                      iconSize: 20,
                    )
                  ],
                ))
          ],
        ),
        toolbarHeight: 60,
        backgroundColor: colorAnimated.background);
  }
}

class HexColor extends Color {
  static int _getColor(String hex) {
    String formattedHex =  "FF" + hex.toUpperCase().replaceAll("#", "");
    return int.parse(formattedHex, radix: 16);
  }
  HexColor(final String hex) : super(_getColor(hex));
}

class ListCard extends StatelessWidget {
  final List<EAsistan> tasks;
  const ListCard({Key? key, required this.tasks}) : super(key: key);
  void _showTaskDetails(BuildContext context, EAsistan task) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.deepPurple, width: 1),
            ),
            child: Text(
              task.baslik,
              style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold,fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "Görev: ",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple),
                    ),
                    TextSpan(
                      text: task.mesaj,
                      style: TextStyle(color: Colors.blueGrey[700], fontSize: 13),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "Arama Saati: ",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple),
                    ),
                    TextSpan(
                      text: task.arama_saati,
                      style: TextStyle(color: Colors.blueGrey[700], fontSize: 14),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "Durum: ",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple),
                    ),
                    TextSpan(
                      text: task.durum,
                      style: TextStyle(color: Colors.green, fontSize: 14),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "Sonuç: ",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple),
                    ),
                    TextSpan(
                      text: task.sonuc,
                      style: TextStyle(color: Colors.blueGrey[700], fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Kapat"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        return ListTile(
          leading: Icon(Icons.task_alt, color: Colors.green),
          title: Text(tasks[index].baslik),
          subtitle: Text(
            tasks[index].mesaj ?? "",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Icon(Icons.chevron_right),
          onTap: () => _showTaskDetails(context, tasks[index]),
        );
      },
    );
  }
}

class ListCardRandevular extends StatelessWidget {
  final List<Map<String, dynamic>> randevular;
  const ListCardRandevular({Key? key, required this.randevular}) : super(key: key);

  void _showRandevuDetails(BuildContext context, Map<String, dynamic> randevu) {
    // Debug için tüm randevu verisini loglayalım
    print('Randevu Detayları: ${jsonEncode(randevu)}');

    // Verileri güvenli şekilde alalım
    final musteriler = randevu["musteriler"] as Map<String, dynamic>?;
    final users = randevu["users"] as Map<String, dynamic>?;
    final musteriAdi = musteriler?['name']?.toString() ??
        users?['name']?.toString() ??
        randevu["musteri_adi"]?.toString() ??
        "Müşteri Adı Yok";

    final telefonRaw = musteriler?['cep_telefon']?.toString() ??
        users?['cep_telefon']?.toString() ??
        randevu["telefon"]?.toString() ??
        "";
    final telefon = telefonRaw.isEmpty
        ? "Belirtilmemiş"
        : Yetki.telefonGoster(telefonRaw);

    // Hizmetleri güvenli şekilde alalım - düzeltildi
    final hizmetler = randevu["hizmetler"];
    String hizmetAdi = "Hizmet Adı Yok";
    List<String> hizmetListesi = [];

    if (hizmetler != null) {
      if (hizmetler is List) {
        for (var hizmet in hizmetler) {
          if (hizmet is Map) {
            // Hizmet adını farklı yapılardan almayı dene
            String? ad = hizmet['hizmet_adi']?.toString();
            if (ad == null && hizmet['hizmetler'] is Map) {
              ad = hizmet['hizmetler']['hizmet_adi']?.toString();
            }
            if (ad != null) {
              hizmetListesi.add(ad);
            }
          } else if (hizmet is String) {
            hizmetListesi.add(hizmet);
          }
        }
        if (hizmetListesi.isNotEmpty) {
          hizmetAdi = hizmetListesi.join(", ");
        }
      } else if (hizmetler is Map) {
        // Tek bir hizmet objesi
        String? ad = hizmetler['hizmet_adi']?.toString();
        if (ad == null && hizmetler['hizmetler'] is Map) {
          ad = hizmetler['hizmetler']['hizmet_adi']?.toString();
        }
        if (ad != null) {
          hizmetAdi = ad;
        }
      } else if (hizmetler is String) {
        hizmetAdi = hizmetler;
      }
    }

    final not = randevu["not"]?.toString() ??
        randevu["musteri_notu"]?.toString() ??
        randevu["personel_notu"]?.toString() ??
        "Not bulunmuyor";

    final tarih = randevu["tarih"]?.toString() ?? "Belirtilmemiş";
    final saat = randevu["saat"]?.toString() ?? "Belirtilmemiş";
    final durum = randevu["durum"]?.toString();
    final personelAdi = randevu["personel_adi"]?.toString() ?? "";

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.all(20),
          child: Container(
            constraints: BoxConstraints(maxWidth: 500),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 32,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.shade200,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF667EEA).withOpacity(0.3),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.calendar_today_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              musteriAdi,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey.shade900,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4),
                            Text(
                              hizmetAdi,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      _buildRandevuStatusBadge(durum),
                    ],
                  ),
                ),

                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Randevu Bilgileri
                        _buildSection(
                          icon: Icons.work_rounded,
                          title: "Randevu Detayı",
                          child: Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey.shade200,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInfoRow("Hizmet:", hizmetAdi),
                                SizedBox(height: 8),
                                _buildInfoRow("Ad Soyad:", musteriAdi),
                                SizedBox(height: 8),
                                _buildInfoRow("Telefon:", telefon),
                                SizedBox(height: 8),
                                if (personelAdi.isNotEmpty)
                                  _buildInfoRow("Personel:", personelAdi),
                                SizedBox(height: 8),
                                _buildInfoRow("Not:", not),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: 24),

                        // Tarih ve Saat
                        _buildSection(
                          icon: Icons.access_time_filled_rounded,
                          title: "Randevu Zamanı",
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildInfoCard(
                                  icon: Icons.calendar_month_rounded,
                                  title: _formatTarih(tarih),
                                  color: Color(0xFF667EEA),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: _buildInfoCard(
                                  icon: Icons.schedule_rounded,
                                  title: _formatSaat(saat),
                                  color: Color(0xFF4CAF50),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Footer
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                    border: Border(
                      top: BorderSide(
                        color: Colors.grey.shade200,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey.shade700,
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.close_rounded, size: 18),
                            SizedBox(width: 8),
                            Text(
                              "Kapat",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }  Widget _buildSection({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Color(0xFF667EEA).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Color(0xFF667EEA),
                size: 18,
              ),
            ),
            SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        child,
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 18,
                ),
              ),
              SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
              fontSize: 14,
            ),
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: Colors.grey.shade800,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRandevuStatusBadge(dynamic status) {
    String statusText = _getRandevuDurumText(status);
    Color statusColor = _getRandevuDurumColor(status);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 6),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 12,
              color: statusColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTarih(dynamic tarih) {
    if (tarih == null) return "Belirtilmemiş";
    try {
      return DateFormat('dd.MM.yyyy').format(DateTime.parse(tarih.toString()));
    } catch (e) {
      return tarih.toString();
    }
  }

  String _formatSaat(dynamic saat) {
    if (saat == null) return "Belirtilmemiş";
    return saat.toString();
  }

  String _getRandevuDurumText(dynamic status) {
    if (status == null) return "Belirsiz";

    String statusStr = status.toString();
    switch (statusStr) {
      case '0':
        return "Onay Bekliyor";
      case '1':
        return "Onaylı";
      case '2':
        return "Reddedilen/İptal";
      case '3':
        return "Müşteri İptal";
      default:
        return "Belirsiz";
    }
  }

  Color _getRandevuDurumColor(dynamic status) {
    if (status == null) return Colors.grey;

    String statusStr = status.toString();
    switch (statusStr) {
      case '0':
        return Color(0xFFF59E0B); // Turuncu
      case '1':
        return Color(0xFF10B981); // Yeşil
      case '2':
        return Color(0xFFEF4444); // Kırmızı
      case '3':
        return Color(0xFF8B5CF6); // Mor
      default:
        return Colors.grey;
    }
  }


  @override
  Widget build(BuildContext context) {
    if (randevular.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Bugün için randevu bulunmuyor',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: randevular.length,
      itemBuilder: (context, index) {
        final randevu = randevular[index];

        // Müşteri adını güvenli şekilde al
        final musteriler = randevu["musteriler"] as Map<String, dynamic>?;
        final users = randevu["users"] as Map<String, dynamic>?;
        final musteriAdi = musteriler?['name']?.toString() ??
            users?['name']?.toString() ??
            randevu["musteri_adi"]?.toString() ??
            "Müşteri Adı Yok";

        // Hizmet adını güvenli şekilde al
        final hizmetler = randevu["hizmetler"];
        String hizmetAdi = "Hizmet Adı Yok";

        if (hizmetler != null) {
          if (hizmetler is List && hizmetler.isNotEmpty) {
            final ilkHizmet = hizmetler[0];
            if (ilkHizmet is Map) {
              hizmetAdi = ilkHizmet["hizmetler"]["hizmet_adi"]?.toString() ?? "Hizmet Adı Yok";
            } else if (ilkHizmet is String) {
              hizmetAdi = ilkHizmet;
            }
          } else if (hizmetler is Map) {
            hizmetAdi = hizmetler["hizmetler"]["hizmet_adi"]?.toString() ?? "Hizmet Adı Yok";
          } else if (hizmetler is String) {
            hizmetAdi = hizmetler;
          }
        }

        final saat = randevu["saat"]?.toString() ?? "";
        final personelAdi = randevu["personel_adi"]?.toString() ?? "";
        final durum = randevu["durum"]?.toString();

        return Container(
          margin: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            shadowColor: Colors.black.withOpacity(0.1),
            child: ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF667EEA).withOpacity(0.3),
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.calendar_today_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              title: Text(
                musteriAdi,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Colors.grey.shade800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),


              trailing: _buildRandevuStatusBadge(durum),
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              onTap: () => _showRandevuDetails(context, randevu),
            ),
          ),
        );
      },
    );
  }}

class _DashItem {
  final IconData icon;
  final String title;
  final String value;
  final Color tint;
  final VoidCallback onTap;
  _DashItem({
    required this.icon,
    required this.title,
    required this.value,
    required this.tint,
    required this.onTap,
  });
}

/// Çan butonunun üstünde subtle pulse animasyonlu kırmızı badge.
class _AnimatedBadge extends StatefulWidget {
  final String badge;
  const _AnimatedBadge({Key? key, required this.badge}) : super(key: key);

  @override
  State<_AnimatedBadge> createState() => _AnimatedBadgeState();
}

class _AnimatedBadgeState extends State<_AnimatedBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final scale = 1.0 + (_ctrl.value * 0.10);
        return Transform.scale(
          scale: scale,
          child: Container(
            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
            padding: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
              ),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEF4444)
                      .withValues(alpha: 0.30 + (_ctrl.value * 0.25)),
                  blurRadius: 6,
                  spreadRadius: _ctrl.value * 1.5,
                ),
              ],
            ),
            child: Center(
              child: Text(
                widget.badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

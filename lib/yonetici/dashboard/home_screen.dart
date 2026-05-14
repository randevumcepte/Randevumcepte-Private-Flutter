import 'dart:convert';
import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import 'package:randevu_sistem/theme/app_tokens.dart';
import 'package:randevu_sistem/theme/theme_provider.dart';
import 'package:randevu_sistem/yonetici/dashboard/ozetsayfasi_sevices.dart';
import 'package:randevu_sistem/yonetici/dashboard/profilbilgileri.dart';
import 'package:randevu_sistem/yonetici/dashboard/satisPerformanslari/alacaklardashboard.dart';
import 'package:randevu_sistem/yonetici/dashboard/satisPerformanslari/kasa.dart';
import 'package:randevu_sistem/yonetici/dashboard/scaffold_layout_builder.dart';
import 'package:randevu_sistem/yonetici/diger/menu/kasa/kasaraporu.dart';
import 'package:sticky_headers/sticky_headers/widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Frontend/dialpad.dart';
import 'package:randevu_sistem/Frontend/sfdatatable.dart';
import 'package:randevu_sistem/Models/ajanda.dart';
import 'package:randevu_sistem/Models/dashboard.dart';
import 'package:randevu_sistem/Models/e_asistan.dart';
import 'package:randevu_sistem/Models/musteri_danisanlar.dart';
import 'package:randevu_sistem/Models/paketler.dart';
import 'package:randevu_sistem/Models/sms_taslaklari.dart';
import 'package:randevu_sistem/Models/user.dart';
import '../adisyonlar/adisyonpage.dart';
import '../adisyonlar/yeniadisyon.dart';
import '../diger/menu/ajanda/ajandaekle.dart';
import '../diger/menu/musteriler/yeni_musteri.dart';
import '../santral/santralraporlari.dart';
import 'bildirimler/bildirimler.dart';
import 'deneme.dart';
import 'gunlukRaporlar/gunlukajandanotlari.dart';
import 'gunlukRaporlar/ongorusmeraporlari.dart';
import 'gunlukRaporlar/paketsatislaridashboard.dart';
import 'gunlukRaporlar/randevular.dart';
import 'gunlukRaporlar/urunsatislaridashboard.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'ozetsayfasi.dart';
import 'package:badges/badges.dart' as badges;

class DashBoard extends StatefulWidget{
  final Kullanici kullanici;
  final dynamic isletmebilgi;
  final int kullanicirolu;
  DashBoard({Key? key,required this.kullanici,required this.isletmebilgi,required this.kullanicirolu}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<DashBoard> {
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

  // Performans bölümünde seçilen periyot
  // 'gunluk' | 'haftalik' | 'aylik' | 'yillik'
  String _perfPeriod = 'aylik';

  // Periyot bazlı API yanıt cache'i — anahtar 'gunluk', 'haftalik' vb.
  final Map<String, Map<String, dynamic>> _karsCache = {};

  // Yüklenme durumu: hangi periyotlar için API hâlâ cevap bekliyor
  final Set<String> _loadingPeriods = {};

  void _updateNotificationCount() {
    _refreshDashboardData();
  }
  final DialPadManager _dialPadManager = DialPadManager(); // Bu satırı ekleyin

  Future<void> _refreshDashboardData() async {
    setState(() {
      isloading = true;
      randevularYukleniyor = true;
    });

    await initialize();
    await _gunlukRandevulariGetir();
  }

  Future<void> _refreshPage() async {
    await _refreshDashboardData();
  }

  @override
  void initState() {
    super.initState();
    initialize();
    _gunlukRandevulariGetir();
  }

  Future<void> initialize() async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    isletmeadi = localStorage.getString('isletmeadi')!;
    seciliisletme = await secilisalonid();

    // Tema bilgisini salon-bazlı server senkronu için bağla.
    if (mounted && seciliisletme != null && seciliisletme!.isNotEmpty) {
      // ignore: use_build_context_synchronously
      context.read<ThemeProvider>().bindSalon(seciliisletme!);
      // Karşılaştırma verisini de yükle (background, fallback'li)
      _loadKarsilastirma(_perfPeriod);
    }

    int bugunYarinTimestamp = DateTime.now().millisecondsSinceEpoch;

    OzetSayfasi ozet = await dashboardGunlukRapor(seciliisletme!);
    var asistanVerileri = await easistandashboard(seciliisletme!, bugunYarinTimestamp);

    widget.kullanici.yetkili_olunan_isletmeler.forEach((element) {
      if (element['salon_id'] == seciliisletme.toString()) {
        uyelikturu = int.parse(element['salonlar']['uyelik_turu'].toString());
      }
    });

    setState(() {
      kullanicirolu = int.parse(widget.kullanici.yetkili_olunan_isletmeler
          .firstWhere((element) => element["salon_id"].toString() == widget.isletmebilgi["id"].toString())["role_id"]
          .toString());
      _isletmeadi = isletmeadi;
      ozetsayfabilgi = ozet;
      _ajandaDataGridSource = AjandaDataSource(
          isletmebilgi: widget.isletmebilgi,
          rowsPerPage: 10,
          salonid: seciliisletme!,
          context: context,
          baslik: '');
      futureEAsistanData = Future.value(asistanVerileri);
      isloading = false;
    });
  }

  // Günlük randevuları getiren fonksiyon
  Future<void> _gunlukRandevulariGetir() async {
    try {
      SharedPreferences localStorage = await SharedPreferences.getInstance();
      var userData = jsonDecode(localStorage.getString('user')!);
      String userId = userData['id'].toString();

      // Bugünün tarihini al
      final now = DateTime.now();
      String bugunTarih = DateFormat('yyyy-MM-dd').format(now);

      // Randevuları getir
      Map<String, dynamic> randevuData = await randevularigetir(
          '', // musteri_id
          widget.isletmebilgi["id"].toString(), // salonid
          'Tümü', // oluşturma
          'Tümü', // durum
          'Bugün', // tarih
          '1', // currpage
          '', // musteridanisanadi
          '', // personelid
          '', // cihazid
          false // musteriMi
      );

      if (randevuData.containsKey('data') && randevuData['data'] is List) {
        setState(() {
          randevuList = List<Map<String, dynamic>>.from(randevuData['data']);
          randevularYukleniyor = false;
        });
      } else {
        setState(() {
          randevuList = [];
          randevularYukleniyor = false;
        });
      }
    } catch (e) {
      print('Randevu getirme hatası: $e');
      setState(() {
        randevuList = [];
        randevularYukleniyor = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isloading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: Container(
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
              _premiumSectionHeader(context, 'Bugünün Özeti', null),
              const SizedBox(height: 10),
              _premiumDailyGrid(context),
              if (kullanicirolu != 4) ...[
                const SizedBox(height: 18),
                _periodChips(context),
                const SizedBox(height: 10),
                _premiumPerformanceRow(context),
                const SizedBox(height: 12),
                _comparisonCard(context),
                const SizedBox(height: 12),
                _topPerformersCard(context),
                const SizedBox(height: 12),
                _hourlyDensityCard(context),
                const SizedBox(height: 12),
                _emptySlotOpportunitiesCard(context),
                if (widget.kullanici.yetkili_olunan_isletmeler.length > 1) ...[
                  const SizedBox(height: 12),
                  _branchPerformanceCard(context),
                ],
                const SizedBox(height: 12),
                _profitMarginCard(context),
              ],
              if (kullanicirolu < 5) ...[
                const SizedBox(height: 18),
                _premiumSectionHeader(context, 'Santral Aktivitesi', null),
                const SizedBox(height: 10),
                _premiumSantralRow(context),
              ],
              const SizedBox(height: 18),
              _premiumSectionHeader(
                  context,
                  kullanicirolu == 5
                      ? 'Bugünün Randevuları'
                      : 'Asistanım',
                  null),
              const SizedBox(height: 10),
              kullanicirolu == 5
                  ? _premiumTodayAppointments(context)
                  : _premiumEAsistan(context),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _premiumTopBar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final unread = ozetsayfabilgi.okunmamisbildirimler;
    final hasUnread = unread.isNotEmpty && unread != "0";

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _circleAction(
            context,
            icon: Icons.notifications_outlined,
            badge: hasUnread ? unread : null,
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
    );
  }

  Widget _circleAction(
    BuildContext context, {
    required IconData icon,
    String? badge,
    required VoidCallback onTap,
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
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.12),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: scheme.primary, size: 20),
            ),
          ),
        ),
        if (badge != null)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              padding: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ),
            ),
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _quickPill(
            context,
            icon: Icons.sms_outlined,
            value: ozetsayfabilgi.kalansms,
            label: 'SMS',
            tint: scheme.primary,
          ),
          const SizedBox(width: 10),
          _quickPill(
            context,
            icon: Icons.account_balance_wallet_outlined,
            value: '${ozetsayfabilgi.toplamkasa} ₺',
            label: kullanicirolu < 5 ? 'Bugünkü Kasa' : 'Toplam Satış',
            tint: const Color(0xFF10B981),
          ),
          if (kullanicirolu < 5) ...[
            const SizedBox(width: 10),
            _quickActionPill(
              context,
              icon: Icons.phone_in_talk_rounded,
              label: 'Çevir',
              onTap: () {
                _dialPadManager.updateDialPad(
                    context, true, "", widget.kullanici);
              },
            ),
          ],
        ],
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
        mainAxisSize: MainAxisSize.min,
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                  height: 1.1,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: scheme.onSurface.withValues(alpha: 0.55),
                  height: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(width: 6),
        ],
      ),
    );
  }

  Widget _quickActionPill(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [scheme.primary, scheme.tertiary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: scheme.onPrimary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: scheme.onPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
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

  Widget _premiumDailyGrid(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ext = context.appTheme;
    final items = [
      _DashItem(
        icon: Icons.calendar_month_rounded,
        title: 'Randevular',
        value: ozetsayfabilgi.randevusayisi.toString(),
        tint: scheme.primary,
        onTap: () => Navigator.push(
          context,
          PageTransition(
            type: PageTransitionType.rightToLeft,
            duration: const Duration(milliseconds: 400),
            child: RandevularDashboard(
                kullanicirolu: widget.kullanicirolu,
                isletmebilgi: widget.isletmebilgi),
          ),
        ),
      ),
      _DashItem(
        icon: Icons.chat_bubble_outline_rounded,
        title: 'Ön Görüşme',
        value: ozetsayfabilgi.ongorusmesayisi.toString(),
        tint: scheme.tertiary,
        onTap: () => Navigator.push(
          context,
          PageTransition(
            type: PageTransitionType.rightToLeft,
            duration: const Duration(milliseconds: 400),
            child: OnGorusmelerDashboard(isletmebilgi: widget.isletmebilgi),
          ),
        ),
      ),
      _DashItem(
        icon: Icons.shopping_bag_outlined,
        title: 'Paket Satışı',
        value: ozetsayfabilgi.paketsatissayisi.toString(),
        tint: ext.successColor,
        onTap: () => Navigator.push(
          context,
          PageTransition(
            type: PageTransitionType.rightToLeft,
            duration: const Duration(milliseconds: 400),
            child: PaketSatislariDashboard(
              kullanicirolu: widget.kullanicirolu,
              isletmebilgi: widget.isletmebilgi,
            ),
          ),
        ),
      ),
      _DashItem(
        icon: Icons.inventory_2_outlined,
        title: 'Ürün Satışı',
        value: ozetsayfabilgi.urunsatissayisi.toString(),
        tint: ext.infoColor,
        onTap: () => Navigator.push(
          context,
          PageTransition(
            type: PageTransitionType.rightToLeft,
            duration: const Duration(milliseconds: 400),
            child: UrunSatislariDashboard(
              kullanicirolu: widget.kullanicirolu,
              isletmebilgi: widget.isletmebilgi,
            ),
          ),
        ),
      ),
    ];
    // GridView yerine manuel Row of Rows — shrinkWrap içinde GridView
    // ListView'in scroll perf'ini ciddi şekilde bozuyor. Bu daha akışkan.
    final width = MediaQuery.of(context).size.width;
    final cardW = (width - 50) / 2; // 20+20 padding + 10 spacing
    final cardH = cardW / 1.75;
    Widget row(_DashItem a, _DashItem b) => Row(
          children: [
            SizedBox(width: cardW, height: cardH, child: _premiumStatCard(context, a)),
            const SizedBox(width: 10),
            SizedBox(width: cardW, height: cardH, child: _premiumStatCard(context, b)),
          ],
        );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          row(items[0], items[1]),
          const SizedBox(height: 10),
          row(items[2], items[3]),
        ],
      ),
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
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: item.tint.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(item.icon, size: 16, color: item.tint),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                        letterSpacing: -0.2,
                        height: 1.15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '${item.value} bugün',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: scheme.onSurface.withValues(alpha: 0.55),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
    final mult = _periodMultiplier();
    final kasaBase = _parseAmount(ozetsayfabilgi.toplamkasa.toString());
    final alacakBase = _parseAmount(kullanicirolu < 5
        ? ozetsayfabilgi.kalantutar.toString()
        : ozetsayfabilgi.prim.toString());
    final kasaScaled = kasaBase * mult;
    final alacakScaled = alacakBase * mult;
    // Donut progress'i periyot bazlı değişir → her tıklamada animasyonlu hareket
    // (Backend periyot endpoint'i hazır olunca buraya gerçek query gelir.)
    final kasaProgress = _periodProgress('kasa');
    final alacakProgress = _periodProgress('alacak');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _premiumPerfCard(
              context,
              title: kullanicirolu < 5 ? 'Toplam Kasa' : 'Toplam Satış',
              value: '${_formatAmount(kasaScaled)} ₺',
              icon: Icons.account_balance_wallet_rounded,
              tint: ext.successColor,
              progress: kasaProgress,
              onTap: () {
                Navigator.push(
                  context,
                  PageTransition(
                    type: PageTransitionType.rightToLeft,
                    duration: const Duration(milliseconds: 400),
                    child: widget.kullanicirolu != 5
                        ? KasaRaporu(isletmebilgi: widget.isletmebilgi)
                        : AdisyonlarPage(
                            kullanicirolu: widget.kullanicirolu,
                            kullanici: widget.kullanici,
                            isletmebilgi: widget.isletmebilgi,
                            geriGitBtn: true),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _premiumPerfCard(
              context,
              title: kullanicirolu < 5 ? 'Alacak' : 'Prim Hakediş',
              value: '${_formatAmount(alacakScaled)} ₺',
              icon: Icons.payments_outlined,
              tint: ext.warningColor,
              progress: alacakProgress,
              onTap: () {
                Navigator.push(
                  context,
                  PageTransition(
                    type: PageTransitionType.rightToLeft,
                    duration: const Duration(milliseconds: 400),
                    child: widget.kullanicirolu != 5
                        ? AlacaklarDashboard(isletmebilgi: widget.isletmebilgi)
                        : AdisyonlarPage(
                            kullanicirolu: widget.kullanicirolu,
                            kullanici: widget.kullanici,
                            isletmebilgi: widget.isletmebilgi,
                            geriGitBtn: true),
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
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: tint.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(icon, size: 15, color: tint),
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
                          const SizedBox(height: 10),
                          Text(
                            value,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              color: scheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _miniDonut(context, progress: progress, tint: tint),
                  ],
                ),
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
    final data = await dashboardKarsilastirma(seciliisletme!, period);
    if (!mounted) return;
    setState(() {
      _loadingPeriods.remove(period);
      if (data != null) _karsCache[period] = data;
    });
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
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Column(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation(scheme.primary),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Yükleniyor...',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: scheme.onSurface.withValues(alpha: 0.50),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
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
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Column(
                      children: [
                        SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor:
                                AlwaysStoppedAnimation(scheme.primary),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Yükleniyor...',
                          style: TextStyle(
                            fontSize: 11,
                            color: scheme.onSurface.withValues(alpha: 0.50),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
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
    if (analysis == null) return const SizedBox.shrink();
    final gapsList = analysis['gaps'] as List?;
    if (gapsList == null || gapsList.isEmpty) return const SizedBox.shrink();

    final gaps = gapsList.cast<Map>().map((m) => m.cast<String, dynamic>()).toList();

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
                          'Boş saatleri indirim kampanyasıyla doldurun',
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
              for (int i = 0; i < gaps.length; i++) ...[
                _gapOpportunityTile(context, gaps[i]),
                if (i < gaps.length - 1) const SizedBox(height: 10),
              ],
            ],
          ),
        ),
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
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: scheme.outline.withValues(alpha: 0.12),
          width: 1,
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
                      'Ortalama doluluk: %${avg.toStringAsFixed(0)}  •  $severity',
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
                  gradient: const LinearGradient(
                    colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '%$disc indirim',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
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
    final label = gap['label'] as String? ?? 'Saatler';
    final start = (gap['start'] as num?)?.toInt() ?? 0;
    final end = (gap['end'] as num?)?.toInt() ?? 0;
    final avg = ((gap['avgDensity'] as num?)?.toDouble() ?? 0) * 100;
    final disc = (gap['suggestedDiscount'] as num?)?.toInt() ?? 0;
    final msg = gap['message'] as String? ?? '';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
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
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.lightbulb_rounded,
                        size: 20, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '$label Boşluk Önerisi',
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
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.06),
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
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Kapat'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                '$label saatleri için %$disc indirimli kampanya yakında!'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: scheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Kampanya Hazırla'),
                    ),
                  ),
                ],
              ),
            ],
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
    final pct = (clamped * 100).round();
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              value: clamped,
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
              duration: const Duration(milliseconds: 400),
              child: CDRRaporlari(
                kullanicirolu: widget.kullanicirolu,
                isletmebilgi: widget.isletmebilgi,
                dialPadManager: DialPadManager(),
                scaffoldMessengerKey: GlobalKey<ScaffoldMessengerState>(),
                kullanici: widget.kullanici,
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

    final telefon = musteriler?['cep_telefon']?.toString() ??
        users?['cep_telefon']?.toString() ??
        randevu["telefon"]?.toString() ??
        "Belirtilmemiş";

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

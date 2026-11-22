// Diğer > WhatsApp Asistanı
// Web paneldeki /isletmeyonetim/whatsapp-asistan sayfasının mobil karşılığı (9 sekme):
// Genel Bakış, Kazandırdıkları, Sohbetler, Kaçan & Geri Kazanılan, Fotoğraftan Fiyat,
// Öğrenilen Cevaplar, Reklamlarım, Ayarlar.
// Yalnız salon yöneticileri (rol < 5) — backend aynı kapıyı uygular.
// "WhatsApp Asistanı" talep push'una tıklanınca ilgili sohbet doğrudan açılır (acilacakSohbetId).

import 'package:flutter/material.dart';

import 'wa_asistan_api.dart';
import 'wa_widgets.dart';
import 'wa_genel_sekme.dart';
import 'wa_sohbetler_sekme.dart';
import 'wa_gorsel_fiyat_sekme.dart';
import 'wa_diger_sekmeler.dart';
import 'wa_reklam_sekme.dart';

/// Sekmeler arası paylaşılan durum (web sayfasındaki global AYAR/SEKTORLER/... değişkenleri).
class WaDurum extends ChangeNotifier {
  final String sube;
  WaDurum(this.sube);

  String donem = '7g';
  bool baslangicYuklendi = false;
  String? baslangicHata;
  bool acik = true;
  Map<String, dynamic> ayar = {};
  Map<String, dynamic> sektorler = {};
  Map<String, dynamic> kurallar = {};
  List<Map<String, dynamic>> hizmetler = [];
  Map<String, dynamic> otoKurallar = {};

  Map<String, dynamic>? ozetCevap; // /ozet cevabı (ozet, trend, seri, paket, asistan)
  String? ozetHata;
  bool ozetYukleniyor = false;

  Map<String, dynamic> get ozet => harita(ozetCevap?['ozet']);

  /// Sekme değiştirme isteği (Genel Bakış'taki "Tümünü gör" vb.)
  void Function(int sekme)? sekmeAc;

  /// Sohbet detayını açma (her sekmeden)
  void Function(int id)? sohbetAc;

  /// Sohbet listesi yenilensin (devral/geri ver/cevapladım sonrası)
  final sohbetYenile = ValueNotifier<int>(0);

  /// Sohbet detayı önbelleği (id → /sohbet/{id} cevabındaki 'sohbet') + listedeki son mesaj zamanı.
  /// Liste ilk sohbetleri arka planda doldurur; dokununca detay beklemeden açılır, arkadan tazelenir.
  final sohbetOnbellek = <int, Map<String, dynamic>>{};
  final _onbellekZaman = <int, String>{};
  bool _onYukluyor = false;

  Future<void> sohbetleriOnYukle(List<Map<String, dynamic>> liste, {int adet = 10}) async {
    if (_onYukluyor) return;
    _onYukluyor = true;
    try {
      for (final x in liste.take(adet)) {
        final id = sayiDeger(x['id']).toInt();
        final zaman = '${x['tarih'] ?? ''}';
        if (sohbetOnbellek.containsKey(id) && _onbellekZaman[id] == zaman) continue; // değişmemiş
        final r = await WaApi.al(sube, '/sohbet/$id');
        if (okMu(r)) sohbetOnbellegeYaz(id, harita(r['sohbet']), zaman: zaman);
      }
    } finally {
      _onYukluyor = false;
    }
  }

  void sohbetOnbellegeYaz(int id, Map<String, dynamic> s, {String? zaman}) {
    sohbetOnbellek[id] = s;
    if (zaman != null) _onbellekZaman[id] = zaman;
  }

  /// Personel yetkisi (backend /durum): yaz = "WhatsApp sohbetine katılsın" (mesaj kutusu, devral, cevapladım).
  bool yaz = false;
  /// Personel yazınca asistanın sustuğu dakika (cevap vermezse asistan devam eder).
  int esikDk = 5;

  Future<void> yetkiYukle() async {
    final r = await WaApi.al(sube, '/durum');
    if (okMu(r)) {
      yaz = '${r['yaz']}' == '1';
      esikDk = int.tryParse('${r['esik_dk'] ?? ''}') ?? 5;
      notifyListeners();
    }
  }

  Future<void> baslangicYukle() async {
    final r = await WaApi.al(sube, '/baslangic');
    if (!okMu(r)) {
      baslangicHata = '${r['hata'] ?? 'Yüklenemedi.'}';
    } else {
      baslangicHata = null;
      acik = r['acik'] == true || '${r['acik']}' == '1';
      ayar = harita(r['ayar']);
      sektorler = harita(r['sektorler']);
      kurallar = harita(r['kurallar']);
      hizmetler = haritaListe(r['hizmetler']);
      otoKurallar = harita(r['oto_kurallar']);
    }
    baslangicYuklendi = true;
    notifyListeners();
  }

  Future<void> ozetYukle() async {
    ozetYukleniyor = true;
    notifyListeners();
    final r = await WaApi.al(sube, '/ozet', {'donem': donem});
    ozetYukleniyor = false;
    if (okMu(r)) {
      ozetCevap = r;
      ozetHata = null;
    } else {
      ozetHata = '${r['hata'] ?? 'Rapor yüklenemedi.'}';
    }
    notifyListeners();
  }

  void donemDegistir(String d) {
    if (d == donem) return;
    donem = d;
    ozetYukle();
  }

  void ayarGuncelle(Map<String, dynamic> yeni) {
    ayar = yeni;
    notifyListeners();
  }

  void kurallarGuncelle(Map<String, dynamic> yeni, String sektor) {
    kurallar = yeni;
    ayar = {...ayar, 'gorsel_sektor': sektor};
    notifyListeners();
  }
}

const waDonemler = {
  '7g': 'Son 7 Gün',
  '30g': 'Son 30 Gün',
  '90g': 'Son 90 Gün',
  'bu_ay': 'Bu Ay',
  'gecen_ay': 'Geçen Ay',
};

class WaAsistanPage extends StatefulWidget {
  final dynamic isletmebilgi;
  final String? salonId;
  final int? acilacakSohbetId;

  const WaAsistanPage({super.key, required this.isletmebilgi, this.salonId, this.acilacakSohbetId});

  @override
  State<WaAsistanPage> createState() => _WaAsistanPageState();
}

class _WaAsistanPageState extends State<WaAsistanPage> with SingleTickerProviderStateMixin {
  late final WaDurum _d;
  late final TabController _tab;

  /// Reklamlarim sekmesi her zaman gorunur (Genel Bakis.in hemen yaninda, 2026-11-23). Ozellik kapaliysa
  /// sekme icinde "Reklam özelliği bu işletmede kapalı" uyarisi cikar; kampanya hazirlanir, asistan ozellik acilinca gonderir.
  static final _sekmeler = <(IconData, String)>[
    _temelSekmeler[0], // Genel Bakış
    _temelSekmeler[2], // Sohbetler
    (Icons.campaign_rounded, 'Reklamlarım'),
    _temelSekmeler[1], // Kazandırdıkları
    ..._temelSekmeler.skip(3), // Kaçan, Fotoğraftan Fiyat, Öğrenilen, Ayarlar
  ];

  /// Cagiranlarin kullandigi _temelSekmeler sirasi (0 Genel, 1 Kazandirdiklari, 2 Sohbetler, 3 Kacan, 4 Fotograf,
  /// 5 Ogrenilen, 6/7 Ayarlar) -> ekrandaki sekme yeri (Genel, Sohbetler, Reklamlarim, Kazandirdiklari, Kacan, Fotograf, Ogrenilen, Ayarlar)
  static const _sekmeYeri = [0, 3, 1, 4, 5, 6, 7, 7];

  static const _temelSekmeler = <(IconData, String)>[
    (Icons.bar_chart_rounded, 'Genel Bakış'),
    (Icons.trending_up_rounded, 'Kazandırdıkları'),
    (Icons.chat_rounded, 'Sohbetler'),
    (Icons.autorenew_rounded, 'Kaçan & Geri Kazanılan'),
    (Icons.photo_camera_rounded, 'Fotoğraftan Fiyat'),
    (Icons.lightbulb_outline_rounded, 'Öğrenilen Cevaplar'),
    (Icons.settings_rounded, 'Ayarlar'),
  ];

  @override
  void initState() {
    super.initState();
    final sube = (widget.salonId != null && widget.salonId!.isNotEmpty) ? widget.salonId! : '${widget.isletmebilgi['id']}';
    _d = WaDurum(sube);
    _tab = TabController(length: _sekmeler.length, vsync: this);
    // Sekme sirasi: 0 Genel, 1 Kazandirdiklari, 2 Sohbetler, 3 Kacan, 4 Fotograf, 5 Ogrenilen, 6 Reklamlarim, 7 Ayarlar.
    // (Asistan Gelisimi / Gece Denetcisi 2026-11-23 kaldirildi; Ayarlar cagrilari zaten 7.)
    // Cagiranlar _temelSekmeler sirasini kullanir (2 Sohbetler, 3 Kacan, 4 Fotograf, 7/6 Ayarlar); Reklamlarim 1. sirada oldugu icin +1
    _d.sekmeAc = (i) => _tab.animateTo(_sekmeYeri[i.clamp(0, _sekmeYeri.length - 1)]);
    _d.sohbetAc = _sohbetAc;
    _d.baslangicYukle();
    _d.ozetYukle();
    _d.yetkiYukle();
    if (widget.acilacakSohbetId != null) {
      _tab.index = 1; // Sohbetler
      WidgetsBinding.instance.addPostFrameCallback((_) => _sohbetAc(widget.acilacakSohbetId!));
    }
  }

  @override
  void dispose() {
    _tab.dispose();
    _d.dispose();
    super.dispose();
  }

  Future<void> _sohbetAc(int id) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => WaSohbetDetay(d: _d, id: id)));
    _d.sohbetYenile.value++;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: const Row(children: [
          Icon(Icons.smart_toy_rounded, color: waYesil),
          SizedBox(width: 8),
          Flexible(child: Text('WhatsApp Asistanı', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18), overflow: TextOverflow.ellipsis)),
        ]),
        actions: [
          AnimatedBuilder(
            animation: _d,
            builder: (_, __) => PopupMenuButton<String>(
              tooltip: 'Dönem',
              initialValue: _d.donem,
              onSelected: _d.donemDegistir,
              itemBuilder: (_) => waDonemler.entries.map((e) => PopupMenuItem(value: e.key, child: Text(e.value))).toList(),
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(color: scheme.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.calendar_month_rounded, size: 16, color: scheme.primary),
                  const SizedBox(width: 4),
                  Text(waDonemler[_d.donem] ?? '', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: scheme.primary)),
                  Icon(Icons.arrow_drop_down, size: 18, color: scheme.primary),
                ]),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: scheme.primary,
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: scheme.primary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
          tabs: _sekmeler.map((s) => Tab(child: Row(children: [Icon(s.$1, size: 17), const SizedBox(width: 6), Text(s.$2)]))).toList(),
        ),
      ),
      body: AnimatedBuilder(
        animation: _d,
        builder: (context, _) {
          if (!_d.baslangicYuklendi) return const Center(child: CircularProgressIndicator());
          if (_d.baslangicHata != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  WaBos(_d.baslangicHata!),
                  FilledButton(onPressed: () { _d.baslangicYukle(); _d.ozetYukle(); }, child: const Text('Tekrar dene')),
                ]),
              ),
            );
          }
          return Column(children: [
            if (!_d.acik)
              const Padding(
                padding: EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: WaBilgi('WhatsApp asistanı bu işletmede henüz açık değil. Açmak için bizimle iletişime geçin; ayarları şimdiden yapabilirsiniz.',
                    renk: Color(0xFFD97706)),
              ),
            Expanded(
              child: TabBarView(controller: _tab, children: [
                WaGenelSekme(d: _d),
                WaSohbetlerSekme(d: _d),
                WaReklamSekme(d: _d),
                WaKazandirdiklariSekme(d: _d),
                WaGeriKazanimSekme(d: _d),
                WaGorselFiyatSekme(d: _d),
                WaOgrenilenSekme(d: _d),
                WaAyarlarSekme(d: _d),
              ]),
            ),
          ]);
        },
      ),
    );
  }
}

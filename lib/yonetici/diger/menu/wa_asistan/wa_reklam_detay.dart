// Diğer > WhatsApp Asistanı > Reklamlarım > Kampanya detayı
// Bu kampanyanın KPI'ları (Ulaşılan / Açtı / Randevu / Gelen / Kazanç / İndirim), dönemi ve kampanyayı
// alan müşteriler. Backend: GET /api/v1/wa-asistan/reklam-kazanc?reklam_id=<id>&gun=0 (tüm zamanlar).

import 'package:randevu_sistem/dil/material.dart';

import 'wa_asistan_api.dart';
import 'wa_asistan_page.dart';
import 'wa_widgets.dart';

/// "#K-0012"
String waReklamKod(dynamic id) => '#K-${sayiDeger(id).toInt().toString().padLeft(4, '0')}';

/// yayinda | bekliyor | kapali | bitti
String waReklamDurum(Map<String, dynamic> x) {
  final b = isoGun(DateTime.now());
  if (sayiDeger(x['aktif']) == 0) return 'kapali';
  final bit = '${x['bitis'] ?? ''}';
  final bas = '${x['baslangic'] ?? ''}';
  if (bit.length >= 10 && bit.substring(0, 10).compareTo(b) < 0) return 'bitti';
  if (bas.length >= 10 && bas.substring(0, 10).compareTo(b) > 0) return 'bekliyor';
  return 'yayinda';
}

const waReklamDurumAd = {'yayinda': 'Yayında', 'bekliyor': 'Bekliyor', 'kapali': 'Durduruldu', 'bitti': 'Bitti'};
const waReklamDurumRenk = {
  'yayinda': Color(0xFF16A34A),
  'bekliyor': Color(0xFFD97706),
  'kapali': Color(0xFF64748B),
  'bitti': Color(0xFFDC2626),
};

int _gunFark(dynamic s) {
  final t = '${s ?? ''}';
  final d = t.length >= 10 ? DateTime.tryParse(t.substring(0, 10)) : null;
  if (d == null) return 0;
  final b = DateTime.now();
  return DateTime(d.year, d.month, d.day).difference(DateTime(b.year, b.month, b.day)).inDays;
}

/// "1 Ara"
String _gunAy(dynamic s) {
  final t = tarihCoz(s);
  return t == null ? '' : '${t.day} ${aylarKisa[t.month - 1]}';
}

/// "1 Ara – 31 Ara" (bitiş yoksa "1 Ara'dan itibaren")
String waReklamTarihAraligi(Map<String, dynamic> x) {
  final a = _gunAy(x['baslangic']), b = _gunAy(x['bitis']);
  if (a.isEmpty && b.isEmpty) return 'Süresiz';
  if (b.isEmpty) return '$a – süresiz';
  if (a.isEmpty) return '$b tarihine kadar';
  return '$a – $b';
}

/// "8 gün kaldı" | "13 gün sonra başlar" | "Bitti" | "Durduruldu"
String waReklamKalan(Map<String, dynamic> x) {
  final d = waReklamDurum(x);
  if (d == 'bitti') return 'Bitti';
  if (d == 'kapali') return 'Durduruldu';
  if (d == 'bekliyor') {
    final f = _gunFark(x['baslangic']);
    return f <= 1 ? 'Yarın başlar' : '$f gün sonra başlar';
  }
  if ('${x['bitis'] ?? ''}'.length < 10) return 'Süresiz';
  final f = _gunFark(x['bitis']);
  return f == 0 ? 'Son gün bugün' : '$f gün kaldı';
}

String _para(dynamic x) => '₺${sayi(x)}';

/// "2026-11-20 14:30" -> "20 Kas 14:30"
String _gunAySaat(dynamic s) {
  final t = tarihCoz(s);
  if (t == null) return '';
  final g = '${t.day} ${aylarKisa[t.month - 1]}';
  if ('$s'.length < 16) return g;
  return '$g ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

const _katDurumRenk = {
  'gonderildi': Color(0xFF64748B),
  'acti': Color(0xFF2563EB),
  'randevu': Color(0xFF7C3AED),
  'geldi': Color(0xFF0D9488),
  'odedi': Color(0xFF16A34A),
};
const _katDurumAd = {'gonderildi': 'Gönderildi', 'acti': 'Açtı', 'randevu': 'Randevu', 'geldi': 'Geldi', 'odedi': 'Ödedi'};

const _filtreDurumlar = {
  'acti': ['acti', 'randevu', 'geldi', 'odedi'],
  'randevu': ['randevu', 'geldi', 'odedi'],
  'gelen': ['geldi', 'odedi'],
};

class WaReklamDetay extends StatefulWidget {
  final WaDurum d;
  final Map<String, dynamic> reklam;

  /// Düzenle formunu açar; kaydedilirse güncel kampanyayı döner (iptal = null)
  final Future<Map<String, dynamic>?> Function(Map<String, dynamic> reklam)? onDuzenle;

  /// Örnek (demo) veri: verilirse API çağrılmaz, işlemler kapalıdır
  final Map<String, dynamic>? demoVeri;
  const WaReklamDetay({super.key, required this.d, required this.reklam, this.onDuzenle, this.demoVeri});

  @override
  State<WaReklamDetay> createState() => _WaReklamDetayState();
}

class _WaReklamDetayState extends State<WaReklamDetay> {
  late Map<String, dynamic> _x;
  Map<String, dynamic>? _veri;
  String? _hata;
  bool _yukleniyor = true;
  String? _filtre; // null | ulasilan | acti | randevu | gelen

  int get _id => sayiDeger(_x['id']).toInt();

  @override
  void initState() {
    super.initState();
    _x = widget.reklam;
    _yukle();
  }

  Future<void> _yukle() async {
    final demo = widget.demoVeri;
    if (demo != null) {
      setState(() {
        _yukleniyor = false;
        _veri = demo;
        _hata = null;
      });
      return;
    }
    final r = await WaApi.al(widget.d.sube, '/reklam-kazanc', {'reklam_id': '$_id', 'gun': '0'});
    if (!mounted) return;
    setState(() {
      _yukleniyor = false;
      if (okMu(r)) {
        _veri = r;
        _hata = null;
      } else {
        _hata = '${r['hata'] ?? 'Yüklenemedi.'}';
      }
    });
  }

  Future<void> _duzenle() async {
    if (widget.demoVeri != null) {
      waToast(context, 'Örnek veride işlem yapılamaz');
      return;
    }
    final f = widget.onDuzenle;
    if (f == null) return;
    final yeni = await f(_x);
    if (yeni != null && mounted) setState(() => _x = yeni);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F3FC),
      appBar: AppBar(
        backgroundColor: waMorKoyu,
        foregroundColor: Colors.white,
        // Uygulama temasi AppBar ikon/yazi rengini koyu yapiyor: mor zeminde acikca beyaz
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        titleSpacing: 0,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(waReklamKod(_id), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xE6FFFFFF))),
          Text('${_x['baslik'] ?? ''}',
              maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
        ]),
        actions: [
          if (widget.onDuzenle != null || widget.demoVeri != null) IconButton(tooltip: 'Düzenle', onPressed: _duzenle, icon: const Icon(Icons.edit_outlined)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _yukle,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 30),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            _ust(),
            if (_yukleniyor)
              const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
            else if (_hata != null && _veri == null) ...[
              WaBilgi(_hata!, renk: const Color(0xFFDC2626)),
              Center(child: TextButton.icon(onPressed: _yukle, icon: const Icon(Icons.refresh_rounded), label: const Text('Tekrar dene'))),
            ] else ...[
              _kpiler(),
              _baslik('DÖNEMLER'),
              _donemler(),
              _musteriler(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _ust() {
    final d = waReklamDurum(_x);
    final renk = waReklamDurumRenk[d]!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 2),
      child: Wrap(spacing: 10, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
        _durumHap(d, renk),
        Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.calendar_month_outlined, size: 15, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(waReklamTarihAraligi(_x), style: TextStyle(fontSize: 13, color: Colors.grey.shade800, fontWeight: FontWeight.w600)),
        ]),
        Text(waReklamKalan(_x), style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
      ]),
    );
  }

  Widget _durumHap(String d, Color renk) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(color: renk.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
        child: Text('● ${waReklamDurumAd[d]}', style: TextStyle(color: renk, fontSize: 11.5, fontWeight: FontWeight.w700)),
      );

  Widget _kpiler() {
    final o = harita(_veri?['ozet']);
    Widget kart(String anahtar, String ad, dynamic deger, Color renk, Color zemin) {
      final secili = _filtre == anahtar;
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Material(
            color: secili ? renk : zemin,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => setState(() => _filtre = secili ? null : anahtar),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                child: Column(children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(sayi(deger),
                        maxLines: 1, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: secili ? Colors.white : renk)),
                  ),
                  Text(ad,
                      maxLines: 1,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: secili ? Colors.white : renk.withValues(alpha: 0.85))),
                ]),
              ),
            ),
          ),
        ),
      );
    }

    return Column(children: [
      Row(children: [
        kart('ulasilan', 'Ulaşılan', o['ulasilan'], const Color(0xFF6D28D9), const Color(0xFFF1EBFE)),
        kart('acti', 'Açtı', o['acan'], const Color(0xFF2563EB), const Color(0xFFE8F0FE)),
        kart('randevu', 'Randevu', o['randevu'], const Color(0xFFDB2777), const Color(0xFFFDEDF5)),
        kart('gelen', 'Gelen', o['gelen'], const Color(0xFF0D9488), const Color(0xFFE6F7F5)),
      ]),
      const SizedBox(height: 6),
      Row(children: [
        Expanded(
          flex: 2,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF15803D), Color(0xFF22C55E)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              const Icon(Icons.payments_outlined, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Kazanç', style: TextStyle(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.w600)),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(_para(o['kazanc']), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                  ),
                ]),
              ),
            ]),
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            decoration: BoxDecoration(color: const Color(0xFFFFF4E5), borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('İndirim', style: TextStyle(color: Color(0xFFB45309), fontSize: 11.5, fontWeight: FontWeight.w600)),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(_para(o['indirim']), style: const TextStyle(color: Color(0xFFB45309), fontSize: 20, fontWeight: FontWeight.w800)),
              ),
            ]),
          ),
        ),
      ]),
    ]);
  }

  Widget _baslik(String m, {String? sag}) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
        child: Row(children: [
          Expanded(
            child: Text(m, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: Colors.grey.shade700)),
          ),
          if (sag != null) Text(sag, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey.shade600)),
        ]),
      );

  Widget _donemler() {
    final d = waReklamDurum(_x);
    final renk = waReklamDurumRenk[d]!;
    final kz = harita(_veri?['ozet'])['kazanc'];
    return WaKart(
      child: Row(children: [
        Text('${waReklamKod(_id)}/1', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: waMorKoyu)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(waReklamTarihAraligi(_x),
              maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: Colors.grey.shade800)),
        ),
        _durumHap(d, renk),
        const SizedBox(width: 8),
        Text(_para(kz), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF15803D))),
      ]),
    );
  }

  Widget _musteriler() {
    final tum = haritaListe(_veri?['katilimcilar']).where((k) => sayiDeger(k['reklam_id']).toInt() == _id).toList();
    final izin = _filtreDurumlar[_filtre];
    final l = izin == null ? tum : tum.where((k) => izin.contains('${k['durum'] ?? 'gonderildi'}')).toList();

    Widget satir(Map<String, dynamic> k) {
      final ad = '${k['ad'] ?? ''}'.trim();
      final tel = '${k['telefon'] ?? ''}'.trim();
      final isim = ad.isNotEmpty ? ad : tel;
      final durum = '${k['durum'] ?? 'gonderildi'}';
      final renk = _katDurumRenk[durum] ?? const Color(0xFF64748B);
      final odenen = sayiDeger(k['odenen']);
      final rt = _gunAySaat(k['randevu_tarih']);
      final gon = _gunAy(k['gonderim']);
      final alt = [if (ad.isNotEmpty && tel.isNotEmpty) tel, if (gon.isNotEmpty) 'gönderim $gon'].join(' · ');
      final sagAlt = [if (odenen > 0) _para(odenen), if (rt.isNotEmpty) 'randevu $rt'].join(' · ');
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: waAcikMor,
            child: Text(isim.isEmpty ? '?' : isim.characters.first.toUpperCase(),
                style: const TextStyle(color: waMorKoyu, fontWeight: FontWeight.w700, fontSize: 14)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(isim.isEmpty ? 'Müşteri' : isim,
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
              if (alt.isNotEmpty)
                Text(alt, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
            ]),
          ),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: renk.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
              child: Text(_katDurumAd[durum] ?? durum, style: TextStyle(color: renk, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
            if (sagAlt.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(sagAlt,
                    style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600, color: odenen > 0 ? const Color(0xFF15803D) : Colors.grey.shade600)),
              ),
          ]),
        ]),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _baslik('KAMPANYAYI ALAN MÜŞTERİLER (${tum.length})', sag: izin == null ? null : '${l.length} gösteriliyor'),
      WaKart(
        child: l.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(tum.isEmpty ? 'Henüz bu kampanyayı alan müşteri yok.' : 'Bu filtrede müşteri yok.',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              )
            : Column(children: [
                for (var i = 0; i < l.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: Colors.grey.shade200),
                  satir(l[i]),
                ],
              ]),
      ),
    ]);
  }
}

// ================================================================ ÖRNEK (DEMO) VERİ
// Yalnız bellekte: sunucuya hiçbir şey yazılmaz, gönderilmez.

/// {liste: [...3 kampanya], kazanc: reklam-kazanc biçiminde {ok, ozet, reklamlar, katilimcilar}}
Map<String, dynamic> waReklamDemo() {
  final n = DateTime.now();
  final bugun = DateTime(n.year, n.month, n.day);
  String g(int fark) => isoGun(bugun.add(Duration(days: fark)));
  String gs(int fark, String saat) => '${g(fark)} $saat';

  final liste = <Map<String, dynamic>>[
    {
      'id': 12, 'baslik': 'İlk ziyarete %20 indirim', 'metin': 'İlk randevunuzda tüm hizmetlerde %20 indirim.',
      'baslangic': g(-10), 'bitis': g(8), 'aktif': 1, 'indirim_tur': 'yuzde', 'indirim_deger': 20,
      'hizmetler': <int>[], 'gorsel': '', 'gosterim': 0, 'tiklama': 0, 'randevu': 0,
    },
    {
      'id': 15, 'baslik': 'Hafta içi %15', 'metin': 'Pazartesi–Perşembe randevularında %15 indirim.',
      'baslangic': g(13), 'bitis': g(43), 'aktif': 1, 'indirim_tur': 'yuzde', 'indirim_deger': 15,
      'hizmetler': <int>[], 'gorsel': '', 'gosterim': 0, 'tiklama': 0, 'randevu': 0,
    },
    {
      'id': 9, 'baslik': 'Arkadaşını getir', 'metin': 'Arkadaşınızla birlikte gelin, ikinize de %10 indirim.',
      'baslangic': isoGun(DateTime(n.year, n.month - 1, 1)), 'bitis': isoGun(DateTime(n.year, n.month, 0)), 'aktif': 1,
      'indirim_tur': 'yuzde', 'indirim_deger': 10, 'hizmetler': <int>[], 'gorsel': '', 'gosterim': 0, 'tiklama': 0, 'randevu': 0,
    },
  ];

  Map<String, dynamic> k(int rid, String ad, String tel, int gonGun, String durum,
          {int? rGun, String saat = '14:30', num odenen = 0, num indirim = 0}) =>
      {
        'reklam_id': rid,
        'reklam': rid == 12 ? 'İlk ziyarete %20 indirim' : 'Arkadaşını getir',
        'ad': ad,
        'telefon': tel,
        'gonderim': gs(gonGun, '11:20:00'),
        'durum': durum,
        'durum_ad': _katDurumAd[durum],
        'randevu_tarih': rGun == null ? null : gs(rGun, saat),
        'odenen': odenen,
        'indirim': indirim,
      };

  final kat = <Map<String, dynamic>>[
    k(12, 'Ayşe Yılmaz', '0532 *** 45 12', -1, 'randevu', rGun: 2, saat: '15:00', indirim: 170),
    k(12, 'Elif Kaya', '0544 *** 18 07', -2, 'odedi', rGun: -1, saat: '11:30', odenen: 1200, indirim: 300),
    k(12, 'Zeynep Demir', '0505 *** 92 33', -3, 'acti'),
    k(12, 'Merve Şahin', '0533 *** 71 64', -4, 'geldi', rGun: 0, saat: '10:00', indirim: 200),
    k(12, 'Büşra Çelik', '0542 *** 03 58', -5, 'gonderildi'),
    k(12, 'Gizem Arslan', '0555 *** 26 19', -6, 'odedi', rGun: -3, saat: '16:30', odenen: 850, indirim: 212),
    k(12, 'Selin Öztürk', '0536 *** 84 40', -8, 'acti'),
    k(12, 'Derya Aydın', '0507 *** 39 85', -9, 'gonderildi'),
    k(9, 'Fatma Koç', '0532 *** 67 21', -40, 'odedi', rGun: -36, saat: '13:00', odenen: 1450, indirim: 160),
    k(9, 'Gamze Kurt', '0546 *** 52 09', -38, 'odedi', rGun: -35, saat: '17:00', odenen: 950, indirim: 105),
    k(9, 'Tuğba Özdemir', '0538 *** 14 76', -33, 'randevu', rGun: -30, saat: '12:00', indirim: 90),
    k(9, 'Hande Yıldız', '0553 *** 80 37', -31, 'acti'),
  ];

  Map<String, dynamic> bos() => {'ulasilan': 0, 'acan': 0, 'randevu': 0, 'gelen': 0, 'kazanc': 0, 'indirim': 0};
  final ozet = bos();
  final rek = <String, dynamic>{};
  for (final x in kat) {
    final r = rek.putIfAbsent('${x['reklam_id']}', bos) as Map<String, dynamic>;
    final d = '${x['durum']}';
    for (final o in [ozet, r]) {
      o['ulasilan'] = (o['ulasilan'] as num) + 1;
      if (d != 'gonderildi') o['acan'] = (o['acan'] as num) + 1;
      if (x['randevu_tarih'] != null) o['randevu'] = (o['randevu'] as num) + 1;
      if (d == 'geldi' || d == 'odedi') o['gelen'] = (o['gelen'] as num) + 1;
      o['kazanc'] = (o['kazanc'] as num) + (x['odenen'] as num);
      o['indirim'] = (o['indirim'] as num) + (x['indirim'] as num);
    }
  }
  return {
    'liste': liste,
    'kazanc': {'ok': 1, 'ozet': ozet, 'reklamlar': rek, 'katilimcilar': kat},
  };
}

/// Tek kampanyanın demo kazanç verisi (detay sayfası için)
Map<String, dynamic> waReklamDemoTek(Map<String, dynamic> kazanc, int id) {
  final r = harita(harita(kazanc['reklamlar'])['$id']);
  return {
    'ok': 1,
    'ozet': r.isEmpty ? {'ulasilan': 0, 'acan': 0, 'randevu': 0, 'gelen': 0, 'kazanc': 0, 'indirim': 0} : r,
    'reklamlar': {'$id': r},
    'katilimcilar': haritaListe(kazanc['katilimcilar']).where((k) => sayiDeger(k['reklam_id']).toInt() == id).toList(),
  };
}

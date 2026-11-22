// Diğer > WhatsApp Asistanı > Reklamlarım
// Web paneldeki "Reklamlarım" sekmesinin mobil karşılığı: kampanya listesi (durum, indirim, 30 günlük
// gönderim/açılma/randevu), yeni kampanya / düzenle (hizmet seçimi, zorunlu indirim, tarih, afiş, yayın),
// yayına al / durdur, sil. Backend: /api/v1/wa-asistan/reklamlar | reklam | reklam/{id}/sil.
// Sekme yalnız reklam özelliği açık işletmede görünür (ayar['reklam'] == 1), web ile aynı.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import 'wa_asistan_api.dart';
import 'wa_asistan_page.dart';
import 'wa_widgets.dart';

// Web'deki RK_SABLONLAR ile aynı
const _sablonlar = [
  (e: '🎉', i: 20, b: 'İlk ziyarete %20 indirim', m: 'İlk randevunuzda tüm hizmetlerde %20 indirim.\nYalnızca yeni müşterilerimize özel.', k: 'Yeni müşteri kazanın'),
  (e: '📅', i: 15, b: 'Hafta içi indirimi', m: 'Pazartesi–Perşembe randevularında %15 indirim.\nBoş saatlerinizi doldurmanın en kolay yolu.', k: 'Sakin günleri doldurun'),
  (e: '🎁', i: 10, b: 'İki hizmet bir arada', m: 'İki hizmeti birlikte alana özel paket fiyat.\nAyrı ayrı almaktan çok daha avantajlı.', k: 'Sepeti büyütün'),
  (e: '👭', i: 10, b: 'Arkadaşını getir', m: 'Arkadaşınızla birlikte gelin, ikinize de %10 indirim.', k: 'Tavsiye ile büyüyün'),
];

String _bugun() => isoGun(DateTime.now());

/// yayinda | bekliyor | kapali | bitti (web rkDurum)
String _durum(Map<String, dynamic> x) {
  final b = _bugun();
  if (sayiDeger(x['aktif']) == 0) return 'kapali';
  final bit = '${x['bitis'] ?? ''}';
  final bas = '${x['baslangic'] ?? ''}';
  if (bit.length >= 10 && bit.substring(0, 10).compareTo(b) < 0) return 'bitti';
  if (bas.length >= 10 && bas.substring(0, 10).compareTo(b) > 0) return 'bekliyor';
  return 'yayinda';
}

String _trTarih(dynamic s) {
  final t = '${s ?? ''}';
  if (t.length < 10) return t;
  final p = t.substring(0, 10).split('-');
  return '${p[2]}.${p[1]}.${p[0]}';
}

int _gunFark(dynamic s) {
  final d = DateTime.tryParse('${s ?? ''}'.length >= 10 ? '$s'.substring(0, 10) : '');
  if (d == null) return 0;
  final b = DateTime.now();
  return DateTime(d.year, d.month, d.day).difference(DateTime(b.year, b.month, b.day)).inDays;
}

/// WaReklam::tl ile aynı biçim
String _tl(num x) {
  final tam = x == x.roundToDouble();
  final s = tam ? sayi(x) : x.toStringAsFixed(2).replaceAll('.', ',');
  return '$s TL';
}

/// WaReklam::indirimEtiket: "%15" | "250 TL" | ""
String _indirimEtiket(dynamic tur, dynamic deger) {
  final d = sayiDeger(deger);
  if (d <= 0) return '';
  if ('$tur' == 'yuzde') return '%${d == d.roundToDouble() ? d.round() : virgul(d)}';
  if ('$tur' == 'tutar') return _tl(d);
  return '';
}

const _durumAd = {'yayinda': '● Yayında', 'bekliyor': 'Başlamadı', 'kapali': 'Durduruldu', 'bitti': 'Süresi bitti'};
const _durumSinif = {'yayinda': 'y', 'bekliyor': 's', 'kapali': 'g', 'bitti': 'k'};

class WaReklamSekme extends StatefulWidget {
  final WaDurum d;
  const WaReklamSekme({super.key, required this.d});
  @override
  State<WaReklamSekme> createState() => _WaReklamSekmeState();
}

class _WaReklamSekmeState extends State<WaReklamSekme> with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>>? _liste;
  String? _hata;
  bool _ozellikAcik = true;
  List<int> _populer = [];
  String _filtre = 'tumu';
  final _isleniyor = <int>{};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    final r = await WaApi.al(widget.d.sube, '/reklamlar');
    if (!mounted) return;
    setState(() {
      if (okMu(r)) {
        _hata = null;
        _liste = haritaListe(r['liste']);
        _ozellikAcik = r['acik'] == true || '${r['acik']}' == '1';
        _populer = liste(r['populer']).map((e) => sayiDeger(e).toInt()).toList();
      } else {
        _hata = '${r['hata'] ?? 'Yüklenemedi.'}';
        _liste ??= [];
      }
    });
  }

  Future<void> _formAc([Map<String, dynamic>? x]) async {
    final yeni = await Navigator.of(context).push<List<Map<String, dynamic>>>(MaterialPageRoute(
      builder: (_) => WaReklamForm(d: widget.d, reklam: x, populer: _populer),
    ));
    if (yeni != null && mounted) setState(() => _liste = yeni);
  }

  Future<void> _yayinDegistir(Map<String, dynamic> x) async {
    final aktif = sayiDeger(x['aktif']) != 0;
    if (!aktif && '${x['indirim_tur'] ?? ''}'.isEmpty) {
      waToast(context, 'Yayına almadan önce kampanya indirimini girin.');
      _formAc(x);
      return;
    }
    final id = sayiDeger(x['id']).toInt();
    setState(() => _isleniyor.add(id));
    final alan = <String, String>{
      'id': '$id',
      'baslik': '${x['baslik'] ?? ''}',
      'metin': '${x['metin'] ?? ''}',
      'baslangic': _kes10(x['baslangic']),
      'bitis': _kes10(x['bitis']),
      'aktif': aktif ? '0' : '1',
      'indirim_tur': '${x['indirim_tur'] ?? ''}',
      'indirim_deger': x['indirim_deger'] == null ? '' : '${x['indirim_deger']}',
    };
    final hz = liste(x['hizmetler']);
    for (var i = 0; i < hz.length; i++) {
      alan['hizmetler[$i]'] = '${hz[i]}';
    }
    final r = await WaApi.gonderForm(widget.d.sube, '/reklam', alan);
    if (!mounted) return;
    setState(() {
      _isleniyor.remove(id);
      if (okMu(r)) _liste = haritaListe(r['liste']);
    });
    waToast(context, okMu(r) ? (aktif ? 'Kampanya durduruldu.' : 'Kampanya yayında.') : '${r['hata'] ?? 'Kaydedilemedi.'}');
  }

  Future<void> _sil(Map<String, dynamic> x) async {
    if (!await waOnay(context, '"${x['baslik']}" kampanyası silinsin mi?', evet: 'Sil')) return;
    final r = await WaApi.gonder(widget.d.sube, '/reklam/${sayiDeger(x['id']).toInt()}/sil');
    if (!mounted) return;
    if (okMu(r)) setState(() => _liste = haritaListe(r['liste']));
    waToast(context, okMu(r) ? 'Silindi.' : '${r['hata'] ?? 'Silinemedi.'}');
  }

  Future<void> _sayfaAc(Map<String, dynamic> x) async {
    final link = '${x['link'] ?? ''}';
    if (link.isEmpty) return;
    try {
      await launchUrl(Uri.parse(link.startsWith('http') ? link : '${WaApi.host}$link'), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l = _liste;
    return Stack(children: [
      RefreshIndicator(
        onRefresh: _yukle,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            _hero(),
            const WaBilgi(
                'İndirim tanımladığınız kampanyada, asistanın oluşturduğu randevuya indirim otomatik işlenir; tahsilat da indirimli tutardan açılır ve randevuya "🎁 WhatsApp kampanyası" notu düşülür. Kampanyalı müşterinin randevusunu siz açıyorsanız (telefon, elden) indirimi randevu fiyatında kendiniz uygulayın.',
                renk: Color(0xFF16A34A)),
            if (!_ozellikAcik)
              const WaBilgi('Reklam özelliği bu işletmede kapalı. Kampanyalarınızı şimdiden hazırlayabilirsiniz; özellik açılınca asistan göndermeye başlar.',
                  renk: Color(0xFFD97706)),
            if (_hata != null) WaBilgi(_hata!, renk: const Color(0xFFDC2626)),
            if (l == null)
              const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator()))
            else if (l.isEmpty)
              _bos()
            else ...[
              _ozet(l),
              _filtreler(l),
              ...l.where((x) => _filtre == 'tumu' || _durum(x) == _filtre).map(_kart),
            ],
          ],
        ),
      ),
      Positioned(
        right: 16,
        bottom: 16,
        child: FloatingActionButton.extended(
          heroTag: 'wa_reklam_yeni',
          backgroundColor: waMor,
          foregroundColor: Colors.white,
          onPressed: () => _formAc(),
          icon: const Icon(Icons.add),
          label: const Text('Yeni kampanya', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ),
    ]);
  }

  Widget _hero() => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFFDB2777)]),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.campaign_rounded, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text('Kampanyalarınızı asistan anlatsın', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16))),
          ]),
          SizedBox(height: 8),
          Text('1. Kampanyayı bir kez girin  ›  2. Müşteri ilgili hizmeti sorar  ›  3. Asistan afişle birlikte gönderir',
              style: TextStyle(color: Colors.white, fontSize: 12.5, height: 1.4)),
          SizedBox(height: 6),
          Text('Sohbet başına en fazla bir kez gider · ilgisiz hizmette gönderilmez · "kampanya istemiyorum" diyene bir daha gitmez',
              style: TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.4)),
        ]),
      );

  Widget _bos() => WaKart(
        child: Column(children: [
          const Icon(Icons.campaign_outlined, size: 44, color: waMor),
          const SizedBox(height: 6),
          const Text('Henüz kampanyanız yok', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 4),
          const WaAlt('Hazır bir şablonla başlayın ya da "Yeni kampanya" ile kendinizinkini yazın.'),
          const SizedBox(height: 12),
          ..._sablonlar.map((s) => Card(
                elevation: 0,
                color: waAcikMor,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: Text(s.e, style: const TextStyle(fontSize: 24)),
                  title: Text(s.b, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(s.k),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _formAc({'aktif': 1, 'hizmetler': [], 'baslik': s.b, 'metin': s.m, 'indirim_tur': 'yuzde', 'indirim_deger': s.i, '_sablon': 1}),
                ),
              )),
        ]),
      );

  Widget _ozet(List<Map<String, dynamic>> l) {
    var y = 0, g = 0, t = 0, r = 0;
    for (final x in l) {
      if (_durum(x) == 'yayinda') y++;
      g += sayiDeger(x['gosterim']).toInt();
      t += sayiDeger(x['tiklama']).toInt();
      r += sayiDeger(x['randevu']).toInt();
    }
    Widget kpi(IconData i, Color c, String deger, String ad) => Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              Icon(i, size: 18, color: c),
              const SizedBox(height: 4),
              Text(deger, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              Text(ad, textAlign: TextAlign.center, style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600)),
            ]),
          ),
        );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        kpi(Icons.podcasts_rounded, const Color(0xFF16A34A), '$y / ${l.length}', 'Yayında'),
        kpi(Icons.send_rounded, waMor, sayi(g), 'Gönderildi\n30 gün'),
        kpi(Icons.visibility_rounded, const Color(0xFF0284C7), g > 0 ? '${sayi(t)} · %${(t * 100 / g).round()}' : sayi(t), 'Afişi açtı'),
        kpi(Icons.event_available_rounded, const Color(0xFFDB2777), sayi(r), 'Randevuya\ndönüştü'),
      ]),
    );
  }

  Widget _filtreler(List<Map<String, dynamic>> l) {
    final say = <String, int>{'tumu': l.length, 'yayinda': 0, 'bekliyor': 0, 'kapali': 0, 'bitti': 0};
    for (final x in l) {
      say[_durum(x)] = (say[_durum(x)] ?? 0) + 1;
    }
    if (_filtre != 'tumu' && (say[_filtre] ?? 0) == 0) _filtre = 'tumu';
    const adlar = [('tumu', 'Tümü'), ('yayinda', 'Yayında'), ('bekliyor', 'Başlamadı'), ('kapali', 'Durduruldu'), ('bitti', 'Süresi bitti')];
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: adlar
            .where((f) => f.$1 == 'tumu' || (say[f.$1] ?? 0) > 0)
            .map((f) => Padding(
                  padding: const EdgeInsets.only(right: 6, bottom: 6),
                  child: ChoiceChip(
                    label: Text('${f.$2} (${say[f.$1]})'),
                    selected: _filtre == f.$1,
                    selectedColor: waMor.withValues(alpha: 0.15),
                    onSelected: (_) => setState(() => _filtre = f.$1),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _kart(Map<String, dynamic> x) {
    final d = _durum(x);
    final id = sayiDeger(x['id']).toInt();
    final aktif = sayiDeger(x['aktif']) != 0;
    final gorsel = '${x['gorsel'] ?? ''}';
    final ind = _indirimEtiket(x['indirim_tur'], x['indirim_deger']);
    final adlar = {for (final h in widget.d.hizmetler) sayiDeger(h['id']).toInt(): '${h['ad']}'};
    final hz = liste(x['hizmetler']).map((e) => sayiDeger(e).toInt()).toList();
    final g = sayiDeger(x['gosterim']).toInt(), t = sayiDeger(x['tiklama']).toInt(), r = sayiDeger(x['randevu']).toInt();
    String kalan = '';
    if (d == 'yayinda' && '${x['bitis'] ?? ''}'.length >= 10) {
      final f = _gunFark(x['bitis']);
      kalan = f == 0 ? 'Son gün bugün' : '$f gün kaldı';
    }
    if (d == 'bekliyor') kalan = '${_trTarih(x['baslangic'])} başlar';
    final pasif = d == 'kapali' || d == 'bitti';

    return Opacity(
      opacity: pasif ? 0.75 : 1,
      child: WaKart(
        padding: EdgeInsets.zero,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // afis + rozetler
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Stack(children: [
              AspectRatio(
                aspectRatio: 16 / 8,
                child: gorsel.isNotEmpty
                    ? Image.network(gorsel.startsWith('http') ? gorsel : '${WaApi.host}$gorsel',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: waAcikMor, child: const Icon(Icons.image_outlined, size: 40, color: waMor)))
                    : Container(color: waAcikMor, child: const Icon(Icons.image_outlined, size: 40, color: waMor)),
              ),
              Positioned(
                left: 8,
                top: 8,
                right: 8,
                child: Wrap(spacing: 6, runSpacing: 6, children: [
                  _rozet(_durumAd[d]!, _sinifRenk(_durumSinif[d]!)),
                  ind.isNotEmpty ? _rozet('🏷️ $ind indirim', const Color(0xFF16A34A)) : _rozet('⚠️ İndirim girilmedi', const Color(0xFFF59E0B)),
                  if (kalan.isNotEmpty) _rozet(kalan, const Color(0xFF334155)),
                ]),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('${x['baslik']}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
              if ('${x['metin'] ?? ''}'.trim().isNotEmpty)
                Padding(padding: const EdgeInsets.only(top: 4), child: WaAlt('${x['metin']}')),
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 6, children: [
                ...hz.take(3).map((i) => _etiket(adlar[i] ?? '#$i')),
                if (hz.length > 3) _etiket('+${hz.length - 3}'),
                if (hz.isEmpty) _etiket('Hizmet seçilmedi', renk: const Color(0xFF92400E), zemin: const Color(0xFFFEF3C7)),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                _huni(sayi(g), 'gönderildi'),
                _huni(sayi(t), g > 0 ? 'açtı · %${(t * 100 / g).round()}' : 'açtı'),
                _huni(sayi(r), 'randevu', renk: const Color(0xFFDB2777)),
              ]),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('son 30 gün${'${x['bitis'] ?? ''}'.length >= 10 && d != 'bekliyor' && kalan.isEmpty ? ' · son gün ${_trTarih(x['bitis'])}' : ''}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ),
            ]),
          ),
          const Divider(height: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
            child: Row(children: [
              TextButton.icon(onPressed: () => _formAc(x), icon: const Icon(Icons.edit_outlined, size: 18), label: const Text('Düzenle')),
              _isleniyor.contains(id)
                  ? const Padding(padding: EdgeInsets.symmetric(horizontal: 18), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)))
                  : TextButton.icon(
                      onPressed: () => _yayinDegistir(x),
                      icon: Icon(aktif ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 18),
                      label: Text(aktif ? 'Durdur' : 'Yayına al'),
                    ),
              const Spacer(),
              IconButton(tooltip: 'Müşterinin gördüğü sayfa', onPressed: () => _sayfaAc(x), icon: const Icon(Icons.open_in_new_rounded, size: 20)),
              IconButton(tooltip: 'Sil', onPressed: () => _sil(x), icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626))),
            ]),
          ),
        ]),
      ),
    );
  }

  Color _sinifRenk(String s) => switch (s) {
        'y' => const Color(0xFF16A34A),
        's' => const Color(0xFFD97706),
        'k' => const Color(0xFFDC2626),
        _ => const Color(0xFF64748B),
      };

  Widget _rozet(String m, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(20)),
        child: Text(m, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
      );

  Widget _etiket(String m, {Color renk = waMorKoyu, Color zemin = waAcikMor}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: zemin, borderRadius: BorderRadius.circular(8)),
        child: Text(m, style: TextStyle(color: renk, fontSize: 11.5, fontWeight: FontWeight.w600)),
      );

  Widget _huni(String deger, String ad, {Color? renk}) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(deger, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: renk)),
          Text(ad, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        ]),
      );
}

String _kes10(dynamic s) {
  final t = '${s ?? ''}';
  return t.length >= 10 ? t.substring(0, 10) : '';
}

// ================================================================ FORM
class WaReklamForm extends StatefulWidget {
  final WaDurum d;
  final Map<String, dynamic>? reklam;
  final List<int> populer;
  const WaReklamForm({super.key, required this.d, this.reklam, this.populer = const []});
  @override
  State<WaReklamForm> createState() => _WaReklamFormState();
}

class _WaReklamFormState extends State<WaReklamForm> {
  late final int? _id;
  final _baslik = TextEditingController();
  final _metin = TextEditingController();
  final _indDeger = TextEditingController();
  final _ara = TextEditingController();
  String _indTur = 'yuzde';
  String _bas = '';
  String _bit = '';
  bool _aktif = true;
  final _secili = <int>[];
  String? _dosya; // yeni secilen afis
  String? _mevcutGorsel;
  bool _kaydediliyor = false;

  @override
  void initState() {
    super.initState();
    final x = widget.reklam ?? const {};
    _id = x['id'] == null ? null : sayiDeger(x['id']).toInt();
    _baslik.text = '${x['baslik'] ?? ''}';
    _metin.text = '${x['metin'] ?? ''}';
    _indTur = '${x['indirim_tur'] ?? ''}' == 'tutar' ? 'tutar' : 'yuzde';
    final dv = sayiDeger(x['indirim_deger']);
    _indDeger.text = dv > 0 ? (dv == dv.roundToDouble() ? '${dv.round()}' : '$dv') : '';
    _bas = _kes10(x['baslangic']);
    _bit = _kes10(x['bitis']);
    _aktif = x.isEmpty || sayiDeger(x['aktif'] ?? 1) != 0;
    _secili.addAll(liste(x['hizmetler']).map((e) => sayiDeger(e).toInt()));
    final g = '${x['gorsel'] ?? ''}';
    _mevcutGorsel = g.isEmpty ? null : (g.startsWith('http') ? g : '${WaApi.host}$g');
    for (final c in [_baslik, _metin, _indDeger, _ara]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [_baslik, _metin, _indDeger, _ara]) {
      c.dispose();
    }
    super.dispose();
  }

  Map<int, Map<String, dynamic>> get _hizmetMap => {for (final h in widget.d.hizmetler) sayiDeger(h['id']).toInt(): h};

  void _sablonUygula(int i) {
    final s = _sablonlar[i];
    setState(() {
      _baslik.text = s.b;
      _metin.text = s.m;
      _indTur = 'yuzde';
      _indDeger.text = '${s.i}';
    });
  }

  Future<void> _tarihSec(bool baslangic) async {
    final simdi = DateTime.now();
    final mevcut = DateTime.tryParse(baslangic ? _bas : _bit) ?? simdi;
    final t = await showDatePicker(
      context: context,
      initialDate: mevcut,
      firstDate: DateTime(simdi.year - 1),
      lastDate: DateTime(simdi.year + 3),
      locale: const Locale('tr', 'TR'),
    );
    if (t == null) return;
    setState(() => baslangic ? _bas = isoGun(t) : _bit = isoGun(t));
  }

  void _sureSec(String v) {
    final d = DateTime.now();
    setState(() {
      if (_bas.isEmpty && v != '0') _bas = isoGun(d);
      if (v == '0') {
        _bit = '';
      } else if (v == 'ay') {
        _bit = isoGun(DateTime(d.year, d.month + 1, 0));
      } else {
        _bit = isoGun(d.add(Duration(days: int.parse(v))));
      }
    });
  }

  Future<void> _gorselSec() async {
    try {
      final f = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
      if (f == null) return;
      final boyut = await File(f.path).length();
      if (boyut > 4 * 1024 * 1024) {
        if (mounted) waToast(context, 'Görsel 4 MB\'tan büyük olamaz.');
        return;
      }
      setState(() => _dosya = f.path);
    } catch (_) {
      if (mounted) waToast(context, 'Görsel seçilemedi. Galeri izni verildiğinden emin olun.');
    }
  }

  Future<void> _kaydet() async {
    final d = num.tryParse(_indDeger.text.replaceAll(',', '.')) ?? 0;
    if (d <= 0) return waToast(context, 'Kampanya indirimini yazın (zorunlu).');
    if (_indTur == 'yuzde' && d > 100) return waToast(context, 'Yüzde indirim en fazla 100 olabilir.');
    if (_baslik.text.trim().isEmpty) return waToast(context, 'Kampanyaya bir başlık yazın.');
    if (_secili.isEmpty) return waToast(context, 'Kampanyanın ilgili olduğu en az bir hizmet seçin.');
    if (_bas.isNotEmpty && _bit.isNotEmpty && _bit.compareTo(_bas) < 0) return waToast(context, 'Bitiş tarihi başlangıçtan önce olamaz.');
    final alan = <String, String>{
      if (_id != null) 'id': '$_id',
      'baslik': _baslik.text.trim(),
      'metin': _metin.text.trim(),
      'baslangic': _bas,
      'bitis': _bit,
      'aktif': _aktif ? '1' : '0',
      'indirim_tur': _indTur,
      'indirim_deger': '$d',
    };
    for (var i = 0; i < _secili.length; i++) {
      alan['hizmetler[$i]'] = '${_secili[i]}';
    }
    setState(() => _kaydediliyor = true);
    final r = await WaApi.gonderForm(widget.d.sube, '/reklam', alan, dosyaYolu: _dosya);
    if (!mounted) return;
    setState(() => _kaydediliyor = false);
    if (!okMu(r)) return waToast(context, '${r['hata'] ?? 'Kaydedilemedi.'}');
    waToast(context, 'Kampanya kaydedildi.');
    Navigator.of(context).pop(haritaListe(r['liste']));
  }

  // Musteriye giden mesaj (WaReklam::mesaj ile ayni sablon)
  String _mesaj() {
    final b = StringBuffer('🎁 *${_baslik.text.trim().isEmpty ? 'Kampanya başlığı' : _baslik.text.trim()}*\n');
    final ek = <String>[];
    for (final s in _metin.text.split(RegExp(r'\r?\n')).map((s) => s.trim()).where((s) => s.isNotEmpty)) {
      ek.add('✨ $s');
    }
    final ind = _indirimEtiket(_indTur, num.tryParse(_indDeger.text.replaceAll(',', '.')));
    if (ind.isNotEmpty) ek.add('🏷️ Kampanya indirimi: *$ind*');
    final adlar = _secili.map((i) => '${_hizmetMap[i]?['ad'] ?? '#$i'}').toList();
    if (adlar.isNotEmpty) ek.add('💆 ${adlar.take(4).join(', ')}');
    if (_bit.length == 10) {
      final p = _bit.split('-');
      ek.add('📅 Son gün: *${int.parse(p[2])} ${aylarUzun[int.parse(p[1]) - 1]}*');
    }
    if (ek.isNotEmpty) b.write('\n${ek.join('\n')}\n');
    b.write('\n👉 Detaylar ve afiş:\napp.randevumcepte.com.tr/k/…\n\nKampanyadan yararlanmak için *"evet"* yazmanız yeterli, randevunuzu hemen oluşturalım 🙂'
        '\n\n_Kampanya mesajı istemezseniz "kampanya istemiyorum" yazın._');
    return b.toString();
  }

  /// *kalin* ve _italik_ WhatsApp bicimi
  List<TextSpan> _waBicim(String m) {
    final out = <TextSpan>[];
    final re = RegExp(r'\*([^*\n]+)\*|_([^_\n]+)_');
    var i = 0;
    for (final x in re.allMatches(m)) {
      if (x.start > i) out.add(TextSpan(text: m.substring(i, x.start)));
      if (x.group(1) != null) {
        out.add(TextSpan(text: x.group(1), style: const TextStyle(fontWeight: FontWeight.w700)));
      } else {
        out.add(TextSpan(text: x.group(2), style: const TextStyle(fontStyle: FontStyle.italic)));
      }
      i = x.end;
    }
    if (i < m.length) out.add(TextSpan(text: m.substring(i)));
    return out;
  }

  Widget _etiketBaslik(String m, [String? alt]) => Padding(
        padding: const EdgeInsets.only(bottom: 6, top: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(m, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
          if (alt != null) ...[const SizedBox(width: 6), Flexible(child: Text(alt, style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)))],
        ]),
      );

  InputDecoration _dek(String ipucu, {String? sonEk}) => InputDecoration(
        hintText: ipucu,
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        suffixText: sonEk,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      );

  Widget _hizmetSecim() {
    final q = _ara.text.trim().toLowerCase();
    final pop = (widget.populer.isNotEmpty ? widget.populer : widget.d.hizmetler.take(12).map((h) => sayiDeger(h['id']).toInt()).toList());
    final tumu = widget.d.hizmetler;
    List<Map<String, dynamic>> gorunen;
    if (q.isEmpty) {
      final m = _hizmetMap;
      gorunen = pop.where((i) => m.containsKey(i)).map((i) => m[i]!).toList();
    } else {
      gorunen = tumu.where((h) => '${h['ad']}'.toLowerCase().contains(q)).toList();
    }
    gorunen = gorunen.where((h) => !_secili.contains(sayiDeger(h['id']).toInt())).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _etiketBaslik('Hangi hizmet sorulunca gönderilsin?', _secili.isEmpty ? 'en az bir hizmet seçin' : '${_secili.length} seçili'),
      if (_secili.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _secili
                .map((i) => InputChip(
                      label: Text('${_hizmetMap[i]?['ad'] ?? '#$i'}'),
                      selected: true,
                      selectedColor: waMor.withValues(alpha: 0.15),
                      onDeleted: () => setState(() => _secili.remove(i)),
                      showCheckmark: false,
                    ))
                .toList(),
          ),
        ),
      TextField(controller: _ara, decoration: _dek('🔍 Hizmet ara (ör. manikür, protez)')),
      const SizedBox(height: 6),
      Text(q.isEmpty ? '🔥 En çok satanlar · diğerleri için arayın' : (gorunen.isEmpty ? 'Bu adla hizmet bulunamadı.' : 'Arama sonucu · ${gorunen.length} hizmet'),
          style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
      const SizedBox(height: 6),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: gorunen
            .take(40)
            .map((h) => ActionChip(
                  label: Text('${h['ad']}'),
                  avatar: const Icon(Icons.add, size: 16),
                  onPressed: () => setState(() {
                    _secili.add(sayiDeger(h['id']).toInt());
                    _ara.clear();
                  }),
                ))
            .toList(),
      ),
    ]);
  }

  Widget _indirimAlan() {
    final d = num.tryParse(_indDeger.text.replaceAll(',', '.')) ?? 0;
    Widget ornek;
    if (d <= 0) {
      ornek = const Text('İndirim miktarını yazın.', style: TextStyle(color: Color(0xFFDC2626), fontSize: 12.5));
    } else if (_indTur == 'yuzde' && d > 100) {
      ornek = const Text('Yüzde 100\'den büyük olamaz.', style: TextStyle(color: Color(0xFFDC2626), fontSize: 12.5));
    } else {
      final satirlar = <Widget>[];
      for (final i in _secili.take(5)) {
        final h = _hizmetMap[i];
        final lf = sayiDeger(h?['fiyat']);
        if (lf <= 0) {
          satirlar.add(Text('${h?['ad'] ?? '#$i'}: liste fiyatı yok', style: const TextStyle(fontSize: 12.5, fontStyle: FontStyle.italic)));
          continue;
        }
        final yeni = _indTur == 'yuzde' ? lf - (lf * d).round() / 100 : (lf - d < 0 ? 0 : lf - d);
        satirlar.add(Text.rich(TextSpan(style: const TextStyle(fontSize: 12.5), children: [
          TextSpan(text: '${h?['ad']}: '),
          TextSpan(text: _tl(lf), style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey)),
          const TextSpan(text: ' → '),
          TextSpan(text: _tl(yeni), style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF16A34A))),
        ])));
      }
      if (_secili.length > 5) satirlar.add(const Text('…'));
      if (satirlar.isEmpty) satirlar.add(const WaAlt('Hizmet seçince indirimli fiyatı burada görürsünüz.'));
      if (_indTur == 'tutar') satirlar.add(const Padding(padding: EdgeInsets.only(top: 4), child: WaAlt('Tutar indirimi randevu başına bir kez düşülür.')));
      ornek = Column(crossAxisAlignment: CrossAxisAlignment.start, children: satirlar);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _etiketBaslik('Kampanya indirimi *', 'zorunlu · asistanın açtığı randevuya otomatik işlenir'),
      Row(children: [
        SegmentedButton<String>(
          segments: const [ButtonSegment(value: 'yuzde', label: Text('% Yüzde')), ButtonSegment(value: 'tutar', label: Text('₺ Tutar'))],
          selected: {_indTur},
          showSelectedIcon: false,
          onSelectionChanged: (s) => setState(() => _indTur = s.first),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: _indDeger,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _dek(_indTur == 'yuzde' ? 'ör. 15' : 'ör. 250', sonEk: _indTur == 'yuzde' ? '%' : 'TL'),
          ),
        ),
      ]),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(10)),
        child: ornek,
      ),
    ]);
  }

  Widget _tarihler() {
    Widget kutu(String deger, String ipucu, bool baslangic) => Expanded(
          child: InkWell(
            onTap: () => _tarihSec(baslangic),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
              child: Row(children: [
                const Icon(Icons.calendar_today_rounded, size: 16, color: waMor),
                const SizedBox(width: 8),
                Expanded(child: Text(deger.isEmpty ? ipucu : _trTarih(deger), style: TextStyle(color: deger.isEmpty ? Colors.grey : null))),
                if (deger.isNotEmpty)
                  GestureDetector(
                    onTap: () => setState(() => baslangic ? _bas = '' : _bit = ''),
                    child: const Icon(Icons.close, size: 16, color: Colors.grey),
                  ),
              ]),
            ),
          ),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _etiketBaslik('Yayın tarihleri', 'boş bırakılırsa süresiz'),
      Row(children: [kutu(_bas, 'Başlangıç', true), const SizedBox(width: 10), kutu(_bit, 'Bitiş', false)]),
      const SizedBox(height: 6),
      Wrap(spacing: 6, children: [
        for (final s in const [('7', '1 hafta'), ('ay', 'Ay sonuna kadar'), ('30', '30 gün'), ('0', 'Süresiz')])
          ActionChip(label: Text(s.$2), onPressed: () => _sureSec(s.$1)),
      ]),
    ]);
  }

  Widget _gorselAlan() {
    final Widget? onizle = _dosya != null
        ? Image.file(File(_dosya!), fit: BoxFit.cover)
        : (_mevcutGorsel != null ? Image.network(_mevcutGorsel!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox()) : null);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _etiketBaslik('Afiş görseli', 'JPG/PNG, en fazla 4 MB'),
      InkWell(
        onTap: _gorselSec,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 160,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(color: waAcikMor, borderRadius: BorderRadius.circular(12), border: Border.all(color: waMor.withValues(alpha: 0.3))),
          child: onizle != null
              ? Stack(fit: StackFit.expand, children: [
                  onizle,
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                      child: const Text('Değiştir', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                  ),
                ])
              : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.cloud_upload_outlined, size: 34, color: waMor),
                  SizedBox(height: 6),
                  Text('Galeriden görsel seçmek için dokunun'),
                ]),
        ),
      ),
    ]);
  }

  Widget _onizleme() {
    final Widget? img = _dosya != null
        ? Image.file(File(_dosya!), fit: BoxFit.cover)
        : (_mevcutGorsel != null ? Image.network(_mevcutGorsel!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox()) : null);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFE5DDD5), borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Asistan, ilgili hizmet sorulunca gönderir', textAlign: TextAlign.center, style: TextStyle(fontSize: 11.5, color: Colors.black54)),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 320),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: const Color(0xFFDCF8C6), borderRadius: BorderRadius.circular(10)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (img != null) ClipRRect(borderRadius: BorderRadius.circular(8), child: SizedBox(height: 150, child: img)),
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 6, 6, 2),
                child: Text.rich(TextSpan(style: const TextStyle(fontSize: 13.5, color: Colors.black87, height: 1.35), children: _waBicim(_mesaj()))),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 6),
        const Text('Bağlantı her müşteri için ayrı oluşur; kimin açtığı ve randevuya dönüştüğü sayılır.',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.black54)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final yeni = _id == null;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text(yeni ? 'Yeni kampanya' : 'Kampanyayı düzenle', style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: waMor, padding: const EdgeInsets.symmetric(vertical: 14)),
            onPressed: _kaydediliyor ? null : _kaydet,
            icon: _kaydediliyor
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check),
            label: Text(yeni ? 'Kampanyayı kaydet' : 'Değişiklikleri kaydet', style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 30),
        children: [
          if (yeni) ...[
            _etiketBaslik('Hazır şablon', 'dokununca doldurur, sonra düzenlersiniz'),
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (var i = 0; i < _sablonlar.length; i++) ActionChip(label: Text('${_sablonlar[i].e} ${_sablonlar[i].b}'), onPressed: () => _sablonUygula(i)),
            ]),
            const SizedBox(height: 10),
          ],
          _etiketBaslik('Başlık', '${_baslik.text.length}/120'),
          TextField(controller: _baslik, maxLength: 120, decoration: _dek('Örn. Kasım\'a özel protez tırnak + manikür 950 TL').copyWith(counterText: '')),
          const SizedBox(height: 10),
          _etiketBaslik('Açıklama', '${_metin.text.length}/700 · her satır mesajda ayrı madde olur'),
          TextField(
            controller: _metin,
            maxLength: 700,
            minLines: 3,
            maxLines: 6,
            decoration: _dek('Örn. 1.200 TL yerine 950 TL. Ay sonuna kadar geçerli.').copyWith(counterText: ''),
          ),
          const SizedBox(height: 14),
          _hizmetSecim(),
          const SizedBox(height: 14),
          _indirimAlan(),
          const SizedBox(height: 14),
          _tarihler(),
          const SizedBox(height: 14),
          _gorselAlan(),
          const SizedBox(height: 14),
          WaKart(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _aktif,
              activeThumbColor: waMor,
              onChanged: (v) => setState(() => _aktif = v),
              title: const Text('Yayında', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Kapalıyken asistan bu kampanyayı göndermez.'),
            ),
          ),
          _etiketBaslik('Müşteri ne görecek?'),
          _onizleme(),
        ],
      ),
    );
  }
}

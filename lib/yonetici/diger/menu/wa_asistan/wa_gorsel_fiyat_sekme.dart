// WhatsApp Asistanı > Fotoğraftan Fiyat (ayar sayfası: bir kez kurulur).
// Ana işlem: kural yoksa hizmet listesinden OTOMATİK eşleşme (WaGorselDanisman::otomatikKurallar; asistan da aynısını kullanır).
// Fiyat deneme: web'deki hesapla() ile aynı hesap ve müşteriye gidecek metin ("-den başlıyor" + eksik ek notu dahil).

import 'package:randevu_sistem/dil/material.dart';

import 'package:randevu_sistem/Frontend/aramali_dropdown.dart';

import 'wa_asistan_api.dart';
import 'wa_asistan_page.dart';
import 'wa_widgets.dart';

const _sabit = '__sabit';

class WaGorselFiyatSekme extends StatefulWidget {
  final WaDurum d;
  const WaGorselFiyatSekme({super.key, required this.d});
  @override
  State<WaGorselFiyatSekme> createState() => _WaGorselFiyatSekmeState();
}

class _AnaSatir {
  String secim; // '' | hizmet_id | __sabit
  final TextEditingController fiyat;
  bool oto;
  _AnaSatir(this.secim, String f, this.oto) : fiyat = TextEditingController(text: f);
}

class _WaGorselFiyatSekmeState extends State<WaGorselFiyatSekme> with AutomaticKeepAliveClientMixin {
  WaDurum get d => widget.d;
  late String _sektor;
  final Map<String, _AnaSatir> _ana = {};
  final Map<String, TextEditingController> _ek = {};
  final _not = TextEditingController();
  bool _degisti = false;
  bool _kaydediliyor = false;
  String? _kaydedildiYazi;

  // fiyat deneme
  String? _hAna;
  final Map<String, dynamic> _hOz = {}; // secim: String, bool: bool, adet: int

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _sektor = '${d.ayar['gorsel_sektor'] ?? ''}'.isNotEmpty ? '${d.ayar['gorsel_sektor']}' : 'tirnak';
    if (!d.sektorler.containsKey(_sektor) && d.sektorler.isNotEmpty) _sektor = d.sektorler.keys.first;
    _not.text = '${d.ayar['gorsel_not'] ?? ''}';
    _formKur();
  }

  @override
  void dispose() {
    for (final a in _ana.values) {
      a.fiyat.dispose();
    }
    for (final c in _ek.values) {
      c.dispose();
    }
    _not.dispose();
    super.dispose();
  }

  Map<String, dynamic> get _s => harita(d.sektorler[_sektor]);

  void _formKur() {
    for (final a in _ana.values) {
      a.fiyat.dispose();
    }
    for (final c in _ek.values) {
      c.dispose();
    }
    _ana.clear();
    _ek.clear();
    final kayitliSektor = '${d.ayar['gorsel_sektor'] ?? 'tirnak'}';
    final k = _sektor == kayitliSektor ? d.kurallar : <String, dynamic>{};
    final oto = harita(d.otoKurallar[_sektor]);
    for (final a in harita(_s['ana']).keys) {
      final anahtar = 'ana:$a';
      final kayitli = k[anahtar] != null ? harita(k[anahtar]) : null;
      final r = kayitli ?? harita(oto[anahtar]);
      final hid = r['hizmet_id'];
      final fy = r['fiyat'];
      final sabit = (hid == null || '$hid'.isEmpty) && fy != null && '$fy'.isNotEmpty;
      _ana[anahtar] = _AnaSatir(sabit ? _sabit : (hid == null ? '' : '$hid'), sabit ? _fiyatYazi(fy) : '', kayitli == null && oto[anahtar] != null);
    }
    harita(_s['ozellikler']).forEach((o, ozHam) {
      final oz = harita(ozHam);
      if (oz['tip'] == 'secim') {
        harita(oz['secenek']).forEach((v, _) {
          _ek['$o:$v'] = TextEditingController(text: _fiyatYazi(harita(k['$o:$v'])['fiyat']));
        });
      } else if (oz['tip'] == 'bool' || oz['tip'] == 'adet') {
        _ek[o] = TextEditingController(text: _fiyatYazi(harita(k[o])['fiyat']));
      }
    });
    _hAna = harita(_s['ana']).keys.isNotEmpty ? harita(_s['ana']).keys.first : null;
    _hOz.clear();
  }

  String _fiyatYazi(dynamic f) {
    if (f == null || '$f'.isEmpty) return '';
    final n = num.tryParse('$f');
    if (n == null) return '$f';
    return n == n.roundToDouble() ? n.round().toString() : '$n';
  }

  double _hizmetFiyat(String id) {
    final h = d.hizmetler.where((x) => '${x['id']}' == id).toList();
    return h.isEmpty ? 0 : sayiDeger(h.first['fiyat']).toDouble();
  }

  /// Formdaki (kaydedilmemiş dahil) kurallar — web formKurallari()
  Map<String, Map<String, dynamic>> _formKurallari() {
    final kur = <String, Map<String, dynamic>>{};
    _ana.forEach((k, a) {
      final sabit = a.secim == _sabit;
      final hid = !sabit ? a.secim : '';
      final fy = sabit ? a.fiyat.text.trim().replaceAll(',', '.') : '';
      if (hid.isNotEmpty || fy.isNotEmpty) kur[k] = {'hizmet_id': hid.isEmpty ? null : hid, 'fiyat': fy.isEmpty ? null : fy};
    });
    _ek.forEach((k, c) {
      final fy = c.text.trim().replaceAll(',', '.');
      if (fy.isNotEmpty) kur[k] = {'hizmet_id': null, 'fiyat': fy};
    });
    return kur;
  }

  double? _kuralTutar(Map<String, Map<String, dynamic>> kur, String k) {
    final r = kur[k];
    if (r == null) return null;
    final hid = r['hizmet_id'];
    if (hid != null && _hizmetFiyat('$hid') > 0) return _hizmetFiyat('$hid');
    final f = r['fiyat'];
    return f != null && '$f'.isNotEmpty ? double.tryParse('$f') : null;
  }

  void _isaretle() {
    setState(() {
      _degisti = true;
      _kaydedildiYazi = null;
    });
  }

  Future<void> _sektorSec(String s) async {
    if (s == _sektor) return;
    if (_degisti && !await waOnay(context, 'Kaydedilmemiş değişiklikleriniz var. Sektörü değiştirirseniz kaybolur. Devam edilsin mi?', evet: 'Devam')) return;
    setState(() {
      _sektor = s;
      _degisti = false;
      _formKur();
    });
  }

  Future<void> _kaydet() async {
    setState(() => _kaydediliyor = true);
    final kur = _formKurallari();
    final sonuc = await Future.wait([
      WaApi.gonder(d.sube, '/kurallar', {'sektor': _sektor, 'kurallar': kur}),
      WaApi.gonder(d.sube, '/ayar', {'gorsel_not': _not.text}),
    ]);
    if (!mounted) return;
    setState(() => _kaydediliyor = false);
    final r = sonuc[0];
    if (okMu(r)) {
      d.kurallarGuncelle(harita(r['kurallar']), _sektor);
      if (okMu(sonuc[1])) d.ayarGuncelle(harita(sonuc[1]['ayar']));
      setState(() {
        _degisti = false;
        _kaydedildiYazi = 'Kaydedildi. Asistan yeni fiyatları hemen kullanır.';
        _formKur();
      });
      waToast(context, 'Fotoğraf fiyat kuralları kaydedildi.');
    } else {
      waToast(context, '${r['hata'] ?? 'Kaydedilemedi.'}');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (d.sektorler.isEmpty) return const WaBos('Sektör bilgisi yüklenemedi.');
    final s = _s;
    final kur = _formKurallari();
    final anaListe = harita(s['ana']);
    var anaHazir = 0, otoSay = 0, ekDolu = 0;
    _ana.forEach((k, a) {
      if (_kuralTutar(kur, k) != null) {
        anaHazir++;
        if (a.oto) otoSay++;
      }
    });
    _ek.forEach((k, c) {
      if (c.text.trim().isNotEmpty) ekDolu++;
    });
    final gor = harita(d.ozet['gorsel']);

    return Column(children: [
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
          children: [
            WaKart(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [
                  Icon(Icons.photo_camera, color: Color(0xFFDB2777)),
                  SizedBox(width: 8),
                  Expanded(child: Text('Fotoğraftan fiyat ayarları', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
                ]),
                const SizedBox(height: 6),
                const Text(
                  'Müşteri model fotoğrafı gönderdiğinde asistan uygulamaları tanır ve fiyatı buradaki eşleşmelerden hesaplar. Bir kez ayarlanır; ana işlemler hizmet listenizden otomatik bulunur, sizin yalnızca eksikleri tamamlamanız yeterli. Fiyatı bilinmeyen modelde asistan müşteriyi bekletmez, fiyatı size sorar ve randevuya devam eder.',
                  style: TextStyle(fontSize: 13, height: 1.45),
                ),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 6, children: [
                  WaHap('$anaHazir/${_ana.length} ana işlem hazır${otoSay > 0 ? ' ($otoSay\'i otomatik bulundu)' : ''}', sinif: anaHazir == _ana.length ? 'y' : 's'),
                  WaHap('$ekDolu/${_ek.length} ek ücret girildi (isteğe bağlı)', sinif: 'g'),
                  if (gor.isNotEmpty) WaHap('${sayi(gor['toplam'])} fotoğraf · ${sayi(gor['fiyat_verildi'])} fiyat verildi · ${sayi(gor['randevu'])} randevu', sinif: 'm'),
                ]),
                const SizedBox(height: 12),
                const Text('Sektör', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Wrap(spacing: 8, children: [
                  for (final e in d.sektorler.entries)
                    ChoiceChip(
                      avatar: Icon(e.key == 'tirnak' ? Icons.back_hand : (e.key == 'sac' ? Icons.content_cut : Icons.auto_awesome), size: 16),
                      label: Text('${harita(e.value)['ad']}'),
                      selected: e.key == _sektor,
                      onSelected: (_) => _sektorSec(e.key),
                    ),
                ]),
              ]),
            ),

            // 1) Ana işlemler
            WaKart(
              baslik: 'Ana işlemler — fiyat hizmet listenizden gelir',
              ikon: Icons.looks_one,
              ikonRenk: const Color(0xFFBE185D),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const WaAlt('Hizmet listenizden otomatik bulundu. Yanlışsa listeden değiştirin; listenizde yoksa "sabit fiyat" seçin.'),
                const SizedBox(height: 8),
                for (final a in anaListe.entries) _anaSatir('ana:${a.key}', '${a.value}', kur),
              ]),
            ),

            // 2) Ek ücretler
            WaKart(
              baslik: 'Ek ücretler — isteğe bağlı',
              ikon: Icons.looks_two,
              ikonRenk: waMor,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const WaAlt('French, krom, taş gibi ekler çoğu salonda ayrı hizmet olmadığı için burada yazılır. Boş bırakılan ek fotoğrafta varsa asistan "…\'den başlıyor" der ve ek ücreti size sorar.'),
                const SizedBox(height: 6),
                ..._ekBolumler(s),
              ]),
            ),

            // Fiyat deneme
            WaKart(
              baslik: 'Fiyat deneme',
              ikon: Icons.calculate,
              ikonRenk: const Color(0xFFDB2777),
              child: _hesapBolum(s, kur),
            ),

            WaKart(
              baslik: 'Fiyatın altına not',
              ikon: Icons.chat_bubble_outline,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                TextField(
                  controller: _not,
                  maxLines: 3,
                  maxLength: 500,
                  onChanged: (_) => _isaretle(),
                  decoration: InputDecoration(hintText: 'Örn. Mevcut protezin sökümü 150 TL eklenir.', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                ),
                const WaAlt('İsteğe bağlı; her fotoğraf fiyatının altına eklenir.'),
              ]),
            ),
          ],
        ),
      ),
      // Kaydet çubuğu
      Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        decoration: BoxDecoration(
          color: _degisti ? const Color(0xFFFFFBEB) : Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, -2))],
        ),
        child: SafeArea(
          top: false,
          child: Row(children: [
            Icon(_degisti ? Icons.error : (_kaydedildiYazi != null ? Icons.check_circle : Icons.info_outline),
                size: 18, color: _degisti ? const Color(0xFFD97706) : (_kaydedildiYazi != null ? const Color(0xFF16A34A) : Colors.grey)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _degisti ? 'Kaydedilmemiş değişiklikler var' : (_kaydedildiYazi ?? 'Boş bıraktığınız ekler fiyata eklenmez.'),
                style: const TextStyle(fontSize: 12.5),
              ),
            ),
            FilledButton.icon(
              onPressed: _kaydediliyor ? null : _kaydet,
              icon: _kaydediliyor ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.check_circle_outline, size: 18),
              label: const Text('Kuralları kaydet'),
            ),
          ]),
        ),
      ),
    ]);
  }

  Widget _fiyatAlani(TextEditingController c, String ph) => SizedBox(
        width: 110,
        child: TextField(
          controller: c,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => _isaretle(),
          decoration: InputDecoration(
            isDense: true,
            hintText: ph,
            suffixText: 'TL',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      );

  Widget _anaSatir(String anahtar, String ad, Map<String, Map<String, dynamic>> kur) {
    final a = _ana[anahtar]!;
    final sabit = a.secim == _sabit;
    final t = _kuralTutar(kur, anahtar);
    final hazir = t != null;
    final ids = d.hizmetler.map((h) => '${h['id']}').toSet();
    final deger = a.secim.isEmpty || a.secim == _sabit || ids.contains(a.secim) ? a.secim : '';
    final items = <DropdownMenuItem<String>>[
      const DropdownMenuItem(value: '', child: Text('— eşleşme yok —')),
      ...d.hizmetler.map((h) => DropdownMenuItem(
            value: '${h['id']}',
            child: Text('${h['ad']}${sayiDeger(h['fiyat']) > 0 ? ' (${tl(h['fiyat'])})' : ' (fiyatsız)'}', overflow: TextOverflow.ellipsis),
          )),
      const DropdownMenuItem(value: _sabit, child: Text('✎ Listede yok, sabit fiyat yazacağım')),
    ];
    final adlar = {for (final h in d.hizmetler) '${h['id']}': '${h['ad']}', '': 'eşleşme yok', _sabit: 'sabit fiyat'};
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: hazir ? const Color(0xFFBBF7D0) : const Color(0xFFFDE68A)),
        color: hazir ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(ad, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300)),
          child: AramaliDropdown<String>(
            items: items,
            value: deger,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            searchText: (v) => adlar[v] ?? v,
            onChanged: (v) {
              setState(() {
                a.secim = v ?? '';
                a.oto = false;
              });
              _isaretle();
            },
          ),
        ),
        if (sabit) Padding(padding: const EdgeInsets.only(top: 8), child: Align(alignment: Alignment.centerLeft, child: _fiyatAlani(a.fiyat, 'Örn. 800'))),
        const SizedBox(height: 6),
        Text(
          hazir
              ? '✓ ${tl(t)}${a.oto ? ' · otomatik bulundu' : ''}'
              : (a.secim.isNotEmpty && !sabit ? 'Bu hizmetin fiyatı yok' : 'Eşleşme yok → fiyat size sorulur'),
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: hazir ? const Color(0xFF15803D) : const Color(0xFFB45309)),
        ),
      ]),
    );
  }

  List<Widget> _ekBolumler(Map<String, dynamic> s) {
    final w = <Widget>[];
    final efekt = <Widget>[], adet = <Widget>[];
    Widget satir(String anahtar, String ad, {String? alt}) {
      final c = _ek[anahtar];
      if (c == null) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Expanded(
            child: Text.rich(TextSpan(children: [
              TextSpan(text: ad, style: TextStyle(fontWeight: c.text.trim().isNotEmpty ? FontWeight.w700 : FontWeight.w500)),
              if (alt != null) TextSpan(text: '  / $alt', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ])),
          ),
          _fiyatAlani(c, '+ 0'),
        ]),
      );
    }

    Widget grup(IconData i, String baslik, String alt, List<Widget> satirlar) => Container(
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: const Color(0xFFFAF7FF)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Icon(i, size: 17, color: waMor),
              const SizedBox(width: 6),
              Text(baslik, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(width: 6),
              Text(alt, style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
            ]),
            const SizedBox(height: 4),
            ...satirlar,
          ]),
        );

    harita(s['ozellikler']).forEach((o, ozHam) {
      final oz = harita(ozHam);
      if (oz['tip'] == 'secim') {
        w.add(grup(Icons.open_in_full, '${oz['ad']}', 'birini seçer', [
          for (final v in harita(oz['secenek']).entries) satir('$o:${v.key}', '${v.value}'),
        ]));
      } else if (oz['tip'] == 'bool') {
        efekt.add(satir(o, '${oz['ad']}'));
      } else if (oz['tip'] == 'adet') {
        adet.add(satir(o, '${oz['ad']}'.replaceAll(RegExp(r'\s*\([^)]*\)'), ''), alt: '${oz['birim'] ?? ''}'));
      }
    });
    if (efekt.isNotEmpty) w.add(grup(Icons.auto_fix_high, 'Efekt ve uygulamalar', 'varsa eklenir', efekt));
    if (adet.isNotEmpty) w.add(grup(Icons.diamond, 'Parmak başı süslemeler', 'adet × fiyat', adet));
    return w;
  }

  Widget _hesapBolum(Map<String, dynamic> s, Map<String, Map<String, dynamic>> kur) {
    final anaListe = harita(s['ana']);
    final ozellikler = harita(s['ozellikler']);
    final w = <Widget>[
      const WaAlt('Bir model seçin, asistanın müşteriye yazacağı fiyatı görün. (Kaydetmeden de çalışır.)'),
      const SizedBox(height: 8),
      Row(children: [
        const SizedBox(width: 90, child: Text('Model', style: TextStyle(fontWeight: FontWeight.w600))),
        Expanded(
          child: DropdownButton<String>(
            isExpanded: true,
            value: anaListe.containsKey(_hAna) ? _hAna : null,
            items: anaListe.entries.map((e) => DropdownMenuItem(value: e.key, child: Text('${e.value}'))).toList(),
            onChanged: (v) => setState(() => _hAna = v),
          ),
        ),
      ]),
    ];
    ozellikler.forEach((o, ozHam) {
      final oz = harita(ozHam);
      if (oz['tip'] == 'secim') {
        w.add(Row(children: [
          SizedBox(width: 90, child: Text('${oz['ad']}', style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(
            child: DropdownButton<String>(
              isExpanded: true,
              value: (_hOz[o] as String?) ?? '',
              items: [
                const DropdownMenuItem(value: '', child: Text('—')),
                ...harita(oz['secenek']).entries.map((e) => DropdownMenuItem(value: e.key, child: Text('${e.value}'))),
              ],
              onChanged: (v) => setState(() => _hOz[o] = v ?? ''),
            ),
          ),
        ]));
      } else if (oz['tip'] == 'bool') {
        w.add(CheckboxListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: _hOz[o] == true,
          title: Text('${oz['ad']}'),
          onChanged: (v) => setState(() => _hOz[o] = v == true),
        ));
      } else if (oz['tip'] == 'adet') {
        final n = (_hOz[o] as int?) ?? 0;
        w.add(Row(children: [
          Expanded(child: Text('${oz['ad']}', style: const TextStyle(fontSize: 13.5))),
          IconButton(visualDensity: VisualDensity.compact, onPressed: n > 0 ? () => setState(() => _hOz[o] = n - 1) : null, icon: const Icon(Icons.remove_circle_outline)),
          Text('$n', style: const TextStyle(fontWeight: FontWeight.w700)),
          IconButton(visualDensity: VisualDensity.compact, onPressed: n < 10 ? () => setState(() => _hOz[o] = n + 1) : null, icon: const Icon(Icons.add_circle_outline)),
        ]));
      }
    });

    // hesapla()
    if (_hAna == null) return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: w);
    final anaT = _kuralTutar(kur, 'ana:$_hAna');
    if (anaT == null) {
      w.add(_balon('"${anaListe[_hAna]}" için fiyat bulunamadı. Asistan müşteriye "fiyatı işletmemize sordum, bu arada randevunuzu ayarlayalım" der ve fiyatı size sorar.', uyari: true));
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: w);
    }
    final kalem = <(String, double)>[('${anaListe[_hAna]}', anaT)];
    var top = anaT;
    final eksik = <String>[];
    ozellikler.forEach((o, ozHam) {
      final oz = harita(ozHam);
      final ad = '${oz['ad']}';
      if (oz['tip'] == 'secim' && '${_hOz[o] ?? ''}'.isNotEmpty) {
        final t = _kuralTutar(kur, '$o:${_hOz[o]}');
        if (t != null && t != 0) {
          kalem.add(('$ad (${harita(oz['secenek'])[_hOz[o]]})', t));
          top += t;
        }
      } else if (oz['tip'] == 'bool' && _hOz[o] == true) {
        final t = _kuralTutar(kur, o);
        if (t != null && t != 0) {
          kalem.add((ad, t));
          top += t;
        } else {
          eksik.add(ad);
        }
      } else if (oz['tip'] == 'adet' && ((_hOz[o] as int?) ?? 0) > 0) {
        final n = _hOz[o] as int;
        final t = _kuralTutar(kur, o);
        if (t != null && t != 0) {
          kalem.add(('$ad × $n', t * n));
          top += t * n;
        } else {
          eksik.add(ad.replaceAll(RegExp(r'\s*\([^)]*\)'), ''));
        }
      }
    });
    final lst = [for (var i = 0; i < eksik.length; i++) i == 0 ? eksik[i] : eksik[i].toLowerCase()];
    final eksikMetin = lst.isEmpty
        ? ''
        : '${lst.length > 1 ? '${lst.sublist(0, lst.length - 1).join(', ')} ve ${lst.last}' : lst.first} için ek ücret olabilir; işletmemize sordum, netleşince buradan bildireceğiz.';
    final not = _not.text.trim();
    final msj = 'Modelinizi inceledim 😊\n\nBu model için fiyatımız: ${tl(top)}${eksik.isNotEmpty ? '\'den başlıyor' : ''}'
        '${kalem.length > 1 ? '\n(${kalem.map((x) => '${x.$1} ${tl(x.$2)}').join(' + ')})' : ''}'
        '${eksikMetin.isNotEmpty ? '\n$eksikMetin' : ''}${not.isNotEmpty ? '\n$not' : ''}\n\nSize uygun bir gün için randevu oluşturalım mı?';
    w.add(const SizedBox(height: 8));
    w.add(Row(children: [
      const Expanded(child: Text('Müşteriye söylenecek fiyat', style: TextStyle(fontWeight: FontWeight.w600))),
      Text('${tl(top)}${eksik.isNotEmpty ? '+' : ''}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFFDB2777))),
    ]));
    w.add(const SizedBox(height: 6));
    w.add(_balon(msj));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: w);
  }

  Widget _balon(String m, {bool uyari = false}) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: uyari ? const Color(0xFFFFFBEB) : const Color(0xFFDCF8C6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(m, style: const TextStyle(fontSize: 13.5, height: 1.4)),
      );
}

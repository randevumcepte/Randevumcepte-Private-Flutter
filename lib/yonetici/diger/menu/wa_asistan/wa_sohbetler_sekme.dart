// WhatsApp Asistanı > Sohbetler (liste + detay). Web: sohbetListe / sohbetAc / talepSeridi.

import 'dart:async';

import 'package:randevu_sistem/dil/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'wa_asistan_api.dart';
import 'wa_asistan_page.dart';
import 'wa_widgets.dart';

class WaSohbetlerSekme extends StatefulWidget {
  final WaDurum d;
  const WaSohbetlerSekme({super.key, required this.d});
  @override
  State<WaSohbetlerSekme> createState() => _WaSohbetlerSekmeState();
}

class _WaSohbetlerSekmeState extends State<WaSohbetlerSekme> with AutomaticKeepAliveClientMixin {
  WaDurum get d => widget.d;
  late DateTime _bas, _bit; // initState'te üstteki dönemden
  final _ara = TextEditingController();
  bool _yukleniyor = true;
  String? _hata;
  List<Map<String, dynamic>> _liste = [];
  Map<String, dynamic>? _numaraKontrol;
  // Bekleyen = asistan işletmeye sordu ya da müşteri mesajı cevapsız; personel = personel yazdı/devraldı
  String _filtre = 'tumu';
  Timer? _zamanlayici;

  @override
  bool get wantKeepAlive => true;

  late String _sonDonem = d.donem;

  @override
  void initState() {
    super.initState();
    _donemAraligi();
    _yukle();
    d.sohbetYenile.addListener(_sessizYenile);
    d.addListener(_donemKontrol);
    // Yeni mesajlar listeye kendiliğinden düşsün (sessiz yenileme)
    _zamanlayici = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted && _ara.text.trim().isEmpty) _yukle(sessiz: true);
    });
  }

  /// Üstteki dönem seçici (Son 7 Gün / Son 30 Gün / Bu Ay ...) sohbet listesini de belirler
  (DateTime, DateTime) get _donemTarihleri {
    final n = DateTime.now();
    return switch (d.donem) {
      '30g' => (n.subtract(const Duration(days: 29)), n),
      '90g' => (n.subtract(const Duration(days: 89)), n),
      'bu_ay' => (DateTime(n.year, n.month, 1), n),
      'gecen_ay' => (DateTime(n.year, n.month - 1, 1), DateTime(n.year, n.month, 0)),
      _ => (n.subtract(const Duration(days: 6)), n),
    };
  }

  void _donemAraligi() {
    final (b, s) = _donemTarihleri;
    _bas = b;
    _bit = s;
  }

  /// Sohbetten geri dönünce / devral-cevapladım sonrası: liste ekranda kalır, arkadan tazelenir (yükleme göstergesi yok)
  void _sessizYenile() => _yukle(sessiz: true);

  void _donemKontrol() {
    if (d.donem == _sonDonem) return;
    _sonDonem = d.donem;
    setState(_donemAraligi);
    _yukle();
  }

  @override
  void dispose() {
    _zamanlayici?.cancel();
    d.removeListener(_donemKontrol);
    d.sohbetYenile.removeListener(_sessizYenile);
    _ara.dispose();
    super.dispose();
  }

  bool _bekleyen(Map<String, dynamic> x) => '${x['bekleyen']}' == '1';
  bool _personel(Map<String, dynamic> x) => x['devralindi'] == true;
  bool _ai(Map<String, dynamic> x) => !_personel(x) && !_bekleyen(x);
  bool _randevu(Map<String, dynamic> x) =>
      (x['randevu_id'] != null && '${x['randevu_id']}' != '0') || const ['randevu', 'guncelle', 'teyit'].contains('${x['sonuc']}');

  /// Filtre düğmesindeki akıllı filtreler: "kimle ilgilenmeliyim?" (kod, ikon, renk, başlık, açıklama, koşul)
  late final List<(String, IconData, Color, String, String, bool Function(Map<String, dynamic>))> _akilliFiltreler = [
    ('firsat', Icons.local_offer_rounded, const Color(0xFF16A34A), 'Fiyat alıp randevu almayanlar',
        'Satış fırsatı: arayıp ya da yazıp randevuya çevirebilirsiniz', (x) => sayiDeger(x['fiyat']) > 0 && !_randevu(x)),
    ('sustu', Icons.hourglass_bottom_rounded, const Color(0xFFD97706), 'Cevap vermeyi bırakanlar',
        'Asistan son soruyu sordu, müşteri dönmedi', (x) => '${x['son_rol']}' == 'asistan' && !_randevu(x) && '${x['sonuc']}' != 'iptal'),
    ('foto', Icons.photo_camera_rounded, const Color(0xFFDB2777), 'Fotoğraf gönderenler',
        'Model / tasarım fotoğrafı atan müşteriler', (x) => sayiDeger(x['gorsel']) > 0),
    ('iptal', Icons.event_busy_rounded, const Color(0xFFDC2626), 'Randevusunu iptal edenler',
        'Yeni bir gün önermek için', (x) => '${x['sonuc']}' == 'iptal'),
    ('memnuniyetsiz', Icons.thumb_down_alt_rounded, const Color(0xFF7F1D1D), 'Memnun kalmayanlar',
        'Randevu sonrası 👎 verenler', (x) => x['memnuniyet'] != null && sayiDeger(x['memnuniyet']) == 0),
    ('geri', Icons.autorenew_rounded, const Color(0xFF0EA5E9), 'Geri kazanılanlar',
        'Asistanın tekrar yazıp döndürdüğü müşteriler', (x) => '${x['geri_kazanim']}' == '1'),
    ('personel', Icons.person_rounded, _mor, 'Personelin devraldıkları',
        'Şu an bir çalışanınızın yürüttüğü sohbetler', _personel),
  ];

  List<Map<String, dynamic>> get _gorunen {
    for (final f in _akilliFiltreler) {
      if (f.$1 == _filtre) return _liste.where(f.$6).toList();
    }
    return switch (_filtre) {
      'bekleyen' => _liste.where(_bekleyen).toList(),
      'ai' => _liste.where(_ai).toList(),
      'randevu' => _liste.where(_randevu).toList(),
      _ => _liste,
    };
  }

  Future<void> _yukle({bool sessiz = false}) async {
    if (!mounted) return;
    if (!sessiz) {
      setState(() {
        _yukleniyor = true;
        _hata = null;
        _numaraKontrol = null;
      });
    }
    final q = _ara.text.trim();
    final r = await WaApi.al(d.sube, '/sohbetler', {'baslangic': isoGun(_bas), 'bitis': isoGun(_bit), if (q.isNotEmpty) 'q': q});
    if (!mounted) return;
    setState(() {
      _yukleniyor = false;
      if (okMu(r)) {
        _liste = haritaListe(r['liste']);
        // dokununca beklemeden açılsın: bekleyenler + en yeni sohbetler arka planda yüklenir
        d.sohbetleriOnYukle([..._liste.where(_bekleyen), ..._liste.where((x) => !_bekleyen(x))]);
      } else if (!sessiz) {
        _hata = '${r['hata'] ?? 'Sohbetler yüklenemedi.'}';
      }
    });
    if (sessiz) return;
    // Telefonla aranıp bulunamadıysa: neden? (hariç numara / mesaj hiç gelmedi / işlenemedi)
    final rak = q.replaceAll(RegExp(r'\D'), '');
    if (okMu(r) && _liste.isEmpty && rak.length >= 10) {
      final k = await WaApi.al(d.sube, '/numara-kontrol', {'tel': rak});
      if (mounted && okMu(k)) setState(() => _numaraKontrol = k);
    }
  }

  /// Filtre düğmesi: akıllı filtreler (sayılarıyla). Tarih sağ üstteki dönemden gelir.
  void _tarihPenceresi() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Kimle ilgilenmeliyim?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _koyu)),
            const SizedBox(height: 2),
            WaAlt('${waDonemler[d.donem] ?? ''} içindeki sohbetlerden. Dönemi sağ üstten değiştirebilirsiniz.'),
            const SizedBox(height: 8),
            for (final f in _akilliFiltreler) _akilliSatir(c, f),
            if (_akilliFiltreler.any((f) => f.$1 == _filtre))
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.pop(c);
                    setState(() => _filtre = 'tumu');
                  },
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Filtreyi kaldır'),
                ),
              ),
          ]),
        ),
      ),
    );
  }

  Widget _akilliSatir(BuildContext c, (String, IconData, Color, String, String, bool Function(Map<String, dynamic>)) f) {
    final adet = _liste.where(f.$6).length;
    final secili = _filtre == f.$1;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: secili ? f.$3.withValues(alpha: 0.10) : const Color(0xFFF8F7FB),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: adet == 0 && !secili
              ? null
              : () {
                  Navigator.pop(c);
                  setState(() => _filtre = secili ? 'tumu' : f.$1);
                },
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 9, 12, 9),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: secili ? f.$3 : Colors.transparent, width: 1.5)),
            child: Opacity(
              opacity: adet == 0 && !secili ? 0.45 : 1,
              child: Row(children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(color: f.$3.withValues(alpha: 0.13), shape: BoxShape.circle),
                  child: Icon(f.$2, size: 18, color: f.$3),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(f.$4, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _koyu)),
                    Text(f.$5, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
                  ]),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(color: adet > 0 ? f.$3 : Colors.grey.shade300, borderRadius: BorderRadius.circular(12)),
                  child: Text('$adet', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5)),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final bekleyen = _liste.where(_bekleyen).length;
    final gorunen = _gorunen;
    final satirVar = !_yukleniyor && _hata == null && gorunen.isNotEmpty;
    final ust = <Widget>[
      AnimatedBuilder(animation: d, builder: (_, __) => _SohbetHero(acik: d.acik)),
      const SizedBox(height: 8),
      // kartlar = filtre düğmeleri (Bekleyen kartı bekleyen varsa kırmızı)
      _istatistikler(bekleyen),
      const SizedBox(height: 8),
      _aramaSatiri(),
      const SizedBox(height: 8),
      ..._aktifFiltreEtiketi(),
      if (!satirVar) _durumAlani(gorunen),
    ];
    // Telefonda büyük yazı ayarı açıkken üst kartlar ekranı doldurup listeyi itmesin: yazı büyütme en fazla %15
    final mq = MediaQuery.of(context);
    return MediaQuery(
      data: mq.copyWith(textScaler: mq.textScaler.clamp(maxScaleFactor: 1.15)),
      child: RefreshIndicator(
        onRefresh: _yukle,
        // Tembel liste: yalnız ekranda görünen sohbet satırları (ve fotoğrafları) çizilir; 200+ sohbette kasmaz
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 30),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: ust.length + (satirVar ? gorunen.length : 0),
          itemBuilder: (_, i) {
            if (i < ust.length) return ust[i];
            final j = i - ust.length;
            final ilk = j == 0, son = j == gorunen.length - 1;
            final x = gorunen[j];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(ilk ? 18 : 0), bottom: Radius.circular(son ? 18 : 0)),
              ),
              child: Column(children: [
                if (!ilk) const Divider(height: 1, indent: 62, color: Color(0xFFEEEAF5)),
                _SohbetSatiri(key: ValueKey(x['id']), x: x, sube: d.sube, onTap: () => d.sohbetAc?.call(sayiDeger(x['id']).toInt())),
              ]),
            );
          },
        ),
      ),
    );
  }

  /// Akıllı filtre seçiliyse arama altında: "🏷 Fiyat alıp randevu almayanlar · 12  ✕"
  List<Widget> _aktifFiltreEtiketi() {
    for (final f in _akilliFiltreler) {
      if (f.$1 != _filtre) continue;
      return [
        Align(
          alignment: Alignment.centerLeft,
          child: InputChip(
            avatar: Icon(f.$2, size: 16, color: f.$3),
            label: Text('${f.$4} · ${_liste.where(f.$6).length}', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: f.$3)),
            backgroundColor: f.$3.withValues(alpha: 0.10),
            side: BorderSide(color: f.$3.withValues(alpha: 0.35)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            deleteIconColor: f.$3,
            onPressed: _tarihPenceresi,
            onDeleted: () => setState(() => _filtre = 'tumu'),
            visualDensity: VisualDensity.compact,
          ),
        ),
        const SizedBox(height: 6),
      ];
    }
    return const [];
  }

  /// Liste yerine: yükleniyor / hata / boş
  Widget _durumAlani(List<Map<String, dynamic>> gorunen) {
    if (_yukleniyor) return const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator()));
    if (_hata != null) return WaBos(_hata!);
    return WaKart(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        WaBos(_liste.isNotEmpty
            ? switch (_filtre) {
                'bekleyen' => 'Bekleyen müşteri yok. Asistan hepsiyle ilgileniyor.',
                'ai' => 'Şu an asistanın yanıtladığı sohbet yok.',
                'randevu' => 'Bu tarihlerde randevuyla biten sohbet yok.',
                _ => 'Bu filtreye uyan sohbet yok.',
              }
            : (_ara.text.trim().isNotEmpty ? 'Bu aramayla sohbet bulunamadı.' : 'Bu tarihlerde sohbet yok.')),
        if (_numaraKontrol != null) _numaraKontrolKart(_numaraKontrol!),
      ]),
    );
  }

  /// Sayı kartları aynı zamanda filtre: Sohbet (tümü) · Randevu · Bekleyen · Oto. Çözüm (asistanın yürüttükleri).
  /// Seçili kart dolu renkli; bekleyen varsa Bekleyen kartı kırmızı.
  Widget _istatistikler(int bekleyen) {
    final randevu = _liste.where(_randevu).length;
    final oto = _liste.isEmpty ? null : (_liste.where(_ai).length * 100 / _liste.length).round();
    final y = _yukleniyor && _liste.isEmpty;
    Widget kart(String kod, IconData ik, Color renk, String deger, String etiket, {bool uyari = false}) {
      final secili = _filtre == kod;
      // uyarı (bekleyen müşteri var): seçili olmasa da dolu kırmızı + gölge; seçiliyken koyu kırmızı + beyaz çerçeve
      final dolu = secili || uyari;
      final zemin = uyari ? (secili ? const Color(0xFFB91C1C) : const Color(0xFFE11D48)) : (secili ? renk : Colors.white);
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Material(
            color: zemin,
            borderRadius: BorderRadius.circular(14),
            elevation: uyari ? 6 : (secili ? 3 : 0),
            shadowColor: (uyari ? const Color(0xFFE11D48) : renk).withValues(alpha: 0.6),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              // seçili karta tekrar dokununca filtre kalkar
              onTap: () => setState(() => _filtre = secili ? 'tumu' : kod),
              child: Container(
                padding: const EdgeInsets.fromLTRB(4, 6, 4, 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: uyari && secili ? Colors.white : (dolu ? zemin : const Color(0xFFECE8F4)),
                    width: uyari && secili ? 2.5 : 1,
                  ),
                ),
                child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(ik, size: 14, color: dolu ? Colors.white : renk),
                    const SizedBox(width: 4),
                    Flexible(
                      child: FittedBox(
                        child: Text(deger, style: TextStyle(fontSize: uyari ? 16 : 15, fontWeight: FontWeight.w800, color: dolu ? Colors.white : _koyu)),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 1),
                  FittedBox(
                    child: Text(etiket,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: dolu ? Colors.white.withValues(alpha: 0.95) : Colors.grey.shade600)),
                  ),
                ]),
              ),
            ),
          ),
        ),
      );
    }

    return Row(children: [
      kart('tumu', Icons.forum_rounded, _mor, y ? '–' : '${_liste.length}', 'Sohbet'),
      kart('randevu', Icons.event_available_rounded, const Color(0xFF16A34A), y ? '–' : '$randevu', 'Randevu'),
      kart('bekleyen', Icons.schedule_rounded, bekleyen > 0 ? const Color(0xFFE11D48) : const Color(0xFF3B82F6), y ? '–' : '$bekleyen', 'Bekleyen',
          uyari: bekleyen > 0),
      kart('ai', Icons.smart_toy_rounded, const Color(0xFF6D28D9), y || oto == null ? '–' : '%$oto', 'Oto. Çözüm'),
    ]);
  }

  Widget _aramaSatiri() {
    // ince arama çubuğu (40 px): ikonların varsayılan 48 px kutusu daraltıldı
    const ikonKutu = BoxConstraints(minWidth: 38, minHeight: 36);
    return Row(children: [
      Expanded(
        child: SizedBox(
          height: 40,
          child: TextField(
            controller: _ara,
            textInputAction: TextInputAction.search,
            textAlignVertical: TextAlignVertical.center,
            style: const TextStyle(fontSize: 13.5),
            onSubmitted: (_) => _yukle(),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Müşteri adı veya telefon ara...',
              hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded, size: 19, color: _koyu),
              prefixIconConstraints: ikonKutu,
              suffixIcon: _ara.text.isEmpty
                  ? null
                  : IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () { _ara.clear(); _yukle(); }),
              suffixIconConstraints: ikonKutu,
              filled: true,
              fillColor: const Color(0xFFF1EEF8),
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
            ),
          ),
        ),
      ),
      const SizedBox(width: 8),
      Material(
        color: const Color(0xFFF1EEF8),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: _tarihPenceresi,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Stack(alignment: Alignment.center, children: [
              const Icon(Icons.tune_rounded, size: 20, color: _koyu),
              if (_akilliFiltreler.any((f) => f.$1 == _filtre))
                Positioned(top: 8, right: 8, child: Container(width: 9, height: 9, decoration: const BoxDecoration(color: _mor, shape: BoxShape.circle))),
            ]),
          ),
        ),
      ),
    ]);
  }

  Widget _numaraKontrolKart(Map<String, dynamic> k) {
    final gelen = haritaListe(k['gelen']);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFEADFF7)), borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Numara kontrolü', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        ...liste(k['neden']).map((n) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• $n', style: const TextStyle(fontSize: 13, height: 1.45)),
            )),
        if (gelen.isNotEmpty) ...[
          const SizedBox(height: 4),
          const WaAlt('Son gelen mesajlar:'),
          ...gelen.map((g) => Text('${tarihSaat(g['tarih'])} — ${g['metin']} (${g['durum']})', style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700))),
        ],
        if (sayiDeger(k['giden_14g']) > 0) Padding(padding: const EdgeInsets.only(top: 4), child: WaAlt('Son 14 günde bu numaraya sistemden ${k['giden_14g']} mesaj gitti.')),
      ]),
    );
  }
}

// ======================================================================== LİSTE BİLEŞENLERİ
const _mor = Color(0xFF7C3AED);
const _koyu = Color(0xFF2E1065);

class _Rozet extends StatelessWidget {
  final String metin;
  const _Rozet(this.metin);
  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minWidth: 22),
        height: 22,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: _mor, borderRadius: BorderRadius.circular(11), border: Border.all(color: Colors.white, width: 2)),
        child: Text(metin, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700, height: 1)),
      );
}

/// Üstteki mor şerit: asistan açık mı + "müşterilerinizle görüşüyor"
class _SohbetHero extends StatelessWidget {
  final bool acik;
  const _SohbetHero({required this.acik});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [Color(0xFF4C1D95), Color(0xFF6D28D9), Color(0xFF8B5CF6)]),
        boxShadow: [BoxShadow(color: _mor.withValues(alpha: 0.30), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(children: [
        // sağdaki asistan robotu (tasarımdaki görsel; sol/üst kenarı şeride yumuşak geçişli)
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          child: Image.asset('images/wa_asistan_robot.png', fit: BoxFit.fitHeight, filterQuality: FilterQuality.medium),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 104, 8),
          child: Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: waYesil,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: const Center(child: FaIcon(FontAwesomeIcons.whatsapp, color: Colors.white, size: 25)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(6, 3, 10, 3),
                  decoration: BoxDecoration(
                    color: acik ? waYesil.withValues(alpha: 0.30) : Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: acik ? const Color(0xFF4ADE80) : Colors.white70,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 2),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(acik ? 'Aktif' : 'Kapalı', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                  ]),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(acik ? 'Asistanınız müşterilerinizle görüşüyor!' : 'WhatsApp asistanınız şu an kapalı.',
                      style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600)),
                ),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }
}

/// Sohbet satırı: avatar (+ cevapsız mesaj rozeti, WhatsApp rozeti), ad, son mesaj, saat, durum hapı
class _SohbetSatiri extends StatelessWidget {
  final Map<String, dynamic> x;
  final String sube;
  final VoidCallback onTap;
  const _SohbetSatiri({super.key, required this.x, required this.sube, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ad = '${x['ad'] ?? ''}'.trim().isNotEmpty ? '${x['ad']}' : ('${x['telefon'] ?? ''}'.isNotEmpty ? '${x['telefon']}' : 'Müşteri');
    final sonRol = '${x['son_rol'] ?? ''}';
    // eski sunucu: son_metin yok → müşterinin son mesajı
    var mesaj = '${x['son_metin'] ?? x['son_mesaj'] ?? ''}'.replaceFirst(RegExp(r'^\[fotoğraf\]\s*'), '').replaceAll(RegExp(r'[*_~]'), '').replaceAll(RegExp(r'\s+'), ' ').trim();
    if (mesaj.isEmpty) mesaj = sayiDeger(x['gorsel']) > 0 ? 'Fotoğraf' : '…';
    final yanitsiz = sayiDeger(x['yanitsiz']).toInt();
    final talep = '${x['talep'] ?? ''}';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(children: [
          SizedBox(
            width: 52,
            height: 50,
            child: Stack(clipBehavior: Clip.none, children: [
              WaAvatar(ad: ad, id: sayiDeger(x['id']).toInt(), foto: x['foto']?.toString(), sube: sube, boyut: 46),
              if (yanitsiz > 0) Positioned(top: -5, right: -2, child: _Rozet(yanitsiz > 9 ? '9+' : '$yanitsiz')),
              Positioned(
                bottom: -1,
                right: 0,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(color: waYesil, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                  child: const Center(child: FaIcon(FontAwesomeIcons.whatsapp, color: Colors.white, size: 10)),
                ),
              ),
            ]),
          ),
          const SizedBox(width: 10),
          // 1. satır: ad + durum hapı · 2. satır: son mesaj (tam genişlik) + saat
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text(ad, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: _koyu)),
                ),
                const SizedBox(width: 6),
                _durumHap(),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                if (sonRol == 'asistan')
                  const Padding(padding: EdgeInsets.only(right: 4), child: Icon(Icons.smart_toy_outlined, size: 15, color: _mor))
                else if (sonRol == 'personel')
                  const Padding(padding: EdgeInsets.only(right: 4), child: Icon(Icons.person_rounded, size: 15, color: _mor))
                else if (sayiDeger(x['gorsel']) > 0 && mesaj == 'Fotoğraf')
                  Padding(padding: const EdgeInsets.only(right: 4), child: Icon(Icons.photo_camera, size: 14, color: Colors.grey.shade600)),
                Expanded(
                  child: Text(mesaj, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                ),
                const SizedBox(width: 6),
                Text(saatYaDaGun(x['tarih']), style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500)),
              ]),
              if (talep.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text('Asistan size soruyor: $talep',
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFFB45309))),
                ),
            ]),
          ),
          const SizedBox(width: 2),
          Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey.shade400),
        ]),
      ),
    );
  }

  /// Personel Devrede > Beklemede > Randevu Alındı > Müşteri Yanıtı Bekleniyor > AI Yanıtlıyor
  Widget _durumHap() {
    final (Widget ikon, String metin, Color zemin, Color yazi) = x['devralindi'] == true
        ? (const Icon(Icons.person_rounded, size: 14, color: _mor), 'Personel Devrede', const Color(0xFFEDE9FE), _koyu)
        : '${x['bekleyen']}' == '1'
            ? (const Icon(Icons.schedule_rounded, size: 14, color: Color(0xFFF59E0B)), 'Beklemede', const Color(0xFFF1F0F5), _koyu)
            : ((x['randevu_id'] != null && '${x['randevu_id']}' != '0') || const ['randevu', 'guncelle', 'teyit'].contains('${x['sonuc']}'))
                ? (const Icon(Icons.check_circle_rounded, size: 13, color: Color(0xFF16A34A)), 'Randevu Alındı', const Color(0xFFDCFCE7), const Color(0xFF166534))
                : '${x['son_rol']}' == 'asistan'
                    ? (Icon(Icons.schedule_rounded, size: 13, color: Colors.grey.shade700), 'Yanıt Bekleniyor', const Color(0xFFF1F0F5), _koyu)
                    : (Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle)), 'AI Yanıtlıyor',
                        const Color(0xFFDCFCE7), const Color(0xFF14532D));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: zemin, borderRadius: BorderRadius.circular(12)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        ikon,
        const SizedBox(width: 4),
        Text(metin, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: yazi)),
      ]),
    );
  }
}

// ======================================================================== SOHBET DETAY
class WaSohbetDetay extends StatefulWidget {
  final WaDurum d;
  final int id;
  const WaSohbetDetay({super.key, required this.d, required this.id});
  @override
  State<WaSohbetDetay> createState() => _WaSohbetDetayState();
}

class _WaSohbetDetayState extends State<WaSohbetDetay> {
  late int _id = widget.id;
  // önbellekte varsa ekran anında dolu açılır; güncel hâli arkadan gelir
  late Map<String, dynamic>? _s = widget.d.sohbetOnbellek[widget.id];
  String? _hata;
  bool _islem = false;
  final _kaydir = ScrollController();
  final _mesaj = TextEditingController();
  bool _gonderiyor = false;
  int _satirSayisi = -1;
  Timer? _zamanlayici;

  @override
  void initState() {
    super.initState();
    if (_s != null) _enAlta();
    _yukle(sessiz: _s != null);
    // Açık sohbet kendiliğinden yenilenir: müşterinin / asistanın yeni mesajı birkaç saniyede düşer
    _zamanlayici = Timer.periodic(const Duration(seconds: 6), (_) {
      if (mounted && !_islem && !_gonderiyor) _yukle(sessiz: true);
    });
  }

  @override
  void dispose() {
    _zamanlayici?.cancel();
    _kaydir.dispose();
    _mesaj.dispose();
    super.dispose();
  }

  bool get _altta => !_kaydir.hasClients || _kaydir.position.pixels >= _kaydir.position.maxScrollExtent - 120;

  void _enAlta() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _kaydir.hasClients) {
        _kaydir.animateTo(_kaydir.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _yukle({bool sessiz = false}) async {
    final r = await WaApi.al(widget.d.sube, '/sohbet/$_id');
    if (!mounted) return;
    if (!okMu(r) && sessiz) return; // arka plan yenilemesi hata gösterip ekranı bozmasın
    final altta = _altta;
    setState(() {
      if (okMu(r)) {
        _s = harita(r['sohbet']);
        widget.d.sohbetOnbellegeYaz(_id, _s!);
        _hata = null;
      } else {
        _hata = '${r['hata'] ?? 'Sohbet gösterilemedi.'}';
      }
    });
    final n = haritaListe(_s?['satirlar']).length;
    // ilk açılışta ve yeni mesaj geldiğinde (kullanıcı yukarıyı okumuyorsa) en son mesaja kay
    if (n != _satirSayisi && (_satirSayisi < 0 || altta)) _enAlta();
    _satirSayisi = n;
  }

  /// Personel uygulamadan müşteriye yazar (müşteriye salon numarasından, isimsiz gider). Asistan birkaç dakika susar.
  Future<void> _gonder() async {
    final t = _mesaj.text.trim();
    if (t.isEmpty || _gonderiyor) return;
    setState(() => _gonderiyor = true);
    final r = await WaApi.gonder(widget.d.sube, '/sohbet/$_id/yaz', {'metin': t});
    if (!mounted) return;
    setState(() => _gonderiyor = false);
    if (okMu(r)) {
      _mesaj.clear();
      await _yukle();
      _enAlta();
    } else {
      waToast(context, '${r['hata'] ?? 'Mesaj gönderilemedi.'}');
    }
  }

  Future<void> _post(String yol, String basarili, {String? hataVarsayilan}) async {
    setState(() => _islem = true);
    final r = await WaApi.gonder(widget.d.sube, '/sohbet/$_id/$yol');
    if (!mounted) return;
    setState(() => _islem = false);
    waToast(context, okMu(r) ? basarili : '${r['hata'] ?? hataVarsayilan ?? 'İşlem yapılamadı.'}');
    await _yukle();
  }

  @override
  Widget build(BuildContext context) {
    final s = _s;
    final ad = s == null ? 'Sohbet' : ('${s['ad'] ?? ''}'.trim().isNotEmpty ? '${s['ad']}' : 'Müşteri');
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        titleSpacing: 0,
        title: s == null
            ? const Text('Sohbet')
            : Row(children: [
                WaAvatar(ad: ad, id: sayiDeger(s['id']).toInt(), sube: widget.d.sube, boyut: 38),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(ad, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
                    Text('${s['telefon'] ?? ''}'.isEmpty ? 'gizli numara' : '${s['telefon']}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ]),
                ),
              ]),
        actions: [
          IconButton(onPressed: _yukle, icon: const Icon(Icons.refresh)),
          if (s != null && widget.d.yaz)
            PopupMenuButton<String>(
              onSelected: (v) async {
                if (v == 'yol') {
                  if (!await waOnay(context, 'Salonun adresi ve Google Haritalar bağlantısı bu müşteriye WhatsApp\'tan gönderilsin mi?', evet: 'Gönder')) return;
                  await _post('yol-tarifi', 'Yol tarifi gönderildi.', hataVarsayilan: 'Gönderilemedi.');
                } else if (v == 'devral') {
                  await _post('devral', 'Sohbeti uzun süre devraldınız; asistan 24 saat ya da siz geri verene kadar susacak.');
                } else if (v == 'geri') {
                  await _post('geri-ver', 'Sohbet asistana geri verildi.');
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'yol', child: ListTile(dense: true, leading: Icon(Icons.location_on), title: Text('Yol tarifi gönder'))),
                if (s['devralindi'] == true)
                  const PopupMenuItem(value: 'geri', child: ListTile(dense: true, leading: Icon(Icons.smart_toy), title: Text('Asistana geri ver')))
                else
                  const PopupMenuItem(value: 'devral', child: ListTile(dense: true, leading: Icon(Icons.person), title: Text('Uzun süre devral (24 saat)'))),
              ],
            ),
        ],
      ),
      body: s == null
          ? Center(child: _hata != null ? WaBos(_hata!) : const CircularProgressIndicator())
          : Column(children: [
              Expanded(
                child: Stack(children: [
                  RefreshIndicator(
                    onRefresh: _yukle,
                    child: ListView(
                      controller: _kaydir,
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                      children: _icerik(s),
                    ),
                  ),
                  if (_islem) const Positioned.fill(child: ColoredBox(color: Color(0x22000000), child: Center(child: CircularProgressIndicator()))),
                ]),
              ),
              _altCubuk(s),
            ]),
    );
  }

  /// Alt çubuk: asistan durumu ("Yeşim yazdı · cevap vermezseniz asistan 4 dk sonra devam eder") + mesaj kutusu (yazma yetkisi varsa)
  Widget _altCubuk(Map<String, dynamic> s) {
    final ad = harita(s['asistan_durum']);
    final kod = '${ad['kod'] ?? 'asistan'}';
    final (IconData ikon, Color renk) = switch (kod) {
      'personel' => (Icons.person_rounded, const Color(0xFFB45309)),
      'devral' => (Icons.pan_tool_rounded, const Color(0xFFDC2626)),
      'sessiz' || 'kapali' => (Icons.pause_circle_rounded, Colors.grey.shade700),
      _ => (Icons.smart_toy_rounded, const Color(0xFF15803D)),
    };
    return Material(
      color: Colors.white,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if ('${ad['metin'] ?? ''}'.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 6, right: 4),
                child: Row(children: [
                  Icon(ikon, size: 16, color: renk),
                  const SizedBox(width: 6),
                  Expanded(child: Text('${ad['metin']}', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: renk))),
                ]),
              ),
            if (widget.d.yaz)
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Expanded(
                  child: TextField(
                    controller: _mesaj,
                    minLines: 1,
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                    enabled: !_gonderiyor,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Müşteriye yazın…',
                      filled: true,
                      fillColor: const Color(0xFFF3F4F6),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                _gonderiyor
                    ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4)))
                    : IconButton.filled(
                        onPressed: _gonder,
                        style: IconButton.styleFrom(backgroundColor: waYesil),
                        icon: const Icon(Icons.send_rounded, color: Colors.white),
                      ),
              ])
            else
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text('Bu sohbete yazma yetkiniz yok. Salon sahibi Personel > Yetkiler\'den "WhatsApp sohbetine katılsın"ı açabilir.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ),
          ]),
        ),
      ),
    );
  }

  List<Widget> _icerik(Map<String, dynamic> s) {
    final scheme = Theme.of(context).colorScheme;
    final yaz = widget.d.yaz;
    final w = <Widget>[];

    w.add(WaKart(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Durum: ', style: TextStyle(fontWeight: FontWeight.w600)),
          Flexible(child: WaHap('${s['durum'] ?? ''}')),
        ]),
        if (yaz) ...[
          const SizedBox(height: 8),
          WaAlt('Aşağıdan müşteriye yazdığınızda (ya da telefonunuzdan WhatsApp\'a yazdığınızda) asistan otomatik susar. '
              '${widget.d.esikDk} dakika içinde tekrar yazmazsanız ve müşteri devam ederse asistan kaldığı yerden devam eder. '
              'Uzun süre siz ilgilenecekseniz sağ üstten "Uzun süre devral"ı seçin.'),
        ],
      ]),
    ));

    // Yarım kalmış sohbet
    final yarim = s['yarim'];
    if (yarim != null && yarim != false && '$yarim'.isNotEmpty) {
      const yarimMetin = {
        'sozde': 'Asistan "bakayım" deyip sonucu yazmamış.',
        'tekrar': 'Asistan aynı cevabı tekrar etmiş; müşterinin isteği karşılanmamış.',
        'sikayet': 'Müşteri bir şeyin olmadığını / gelmediğini yazmış; istek karşılanmamış.',
      };
      w.add(WaKart(
        renk: const Color(0xFFFEF2F2),
        kenar: const Color(0xFFFECACA),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626)),
            SizedBox(width: 8),
            Text('Bu sohbet yarım kalmış', style: TextStyle(fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 4),
          Text('${yarimMetin['$yarim'] ?? 'Müşterinin son mesajı cevapsız kalmış.'} Asistan birkaç dakika içinde kendiliğinden tamamlar; beklemeden hemen tamamlatabilirsiniz.',
              style: const TextStyle(fontSize: 13, height: 1.4)),
          if (yaz) ...[
            const SizedBox(height: 8),
            FilledButton.icon(
              icon: const Icon(Icons.smart_toy, size: 18),
              label: const Text('Asistan tamamlasın'),
              onPressed: () => _post('devam', 'Asistan sohbeti tamamladı ve müşteriye yazdı.', hataVarsayilan: 'Yapılamadı.'),
            ),
          ],
        ]),
      ));
    }

    // İşletmeye sorulan konular (talep şeridi)
    for (final t in haritaListe(s['talepler'])) {
      w.add(_talepKart(t));
    }

    // Bu numaraya giden mesajlar + önceki sohbetler
    final giden = haritaListe(s['giden']), onceki = haritaListe(s['onceki']);
    final sistemGiden = giden.where((x) => x['asistan'] != true).length;
    if (giden.isNotEmpty || onceki.isNotEmpty) {
      w.add(WaKart(
        padding: EdgeInsets.zero,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: sistemGiden > 0,
            leading: const Icon(Icons.history),
            title: const Text('Bu numaraya giden mesajlar ve önceki sohbetler', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
            subtitle: sistemGiden > 0 ? Align(alignment: Alignment.centerLeft, child: WaHap('$sistemGiden sistem mesajı', sinif: 's')) : null,
            childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            children: [
              ...giden.map((x) => Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: x['asistan'] == true ? const Color(0xFFF5F3FF) : const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text.rich(TextSpan(children: [
                        TextSpan(text: '${x['tip']}  ', style: const TextStyle(fontWeight: FontWeight.w700)),
                        TextSpan(
                            text: '${tarihSaat(x['tarih'])}${sayiDeger(x['durum']) == 2 ? ' · gönderilemedi' : ''}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      ])),
                      const SizedBox(height: 3),
                      Text('${x['mesaj'] ?? ''}', style: const TextStyle(fontSize: 13)),
                    ]),
                  )),
              ...onceki.map((x) => Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text.rich(TextSpan(children: [
                        const TextSpan(text: 'Önceki sohbet  ', style: TextStyle(fontWeight: FontWeight.w700)),
                        TextSpan(text: '${tarihSaat(x['tarih'])} · ${x['mesaj']} mesaj', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      ])),
                      const SizedBox(height: 3),
                      Text('${x['ilk'] ?? ''}', style: const TextStyle(fontSize: 13)),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _id = sayiDeger(x['id']).toInt();
                              _s = null;
                            });
                            _yukle();
                          },
                          child: const Text('Aç →'),
                        ),
                      ),
                    ]),
                  )),
            ],
          ),
        ),
      ));
    }

    // Müşterinin gönderdiği fotoğraflar
    final gorseller = haritaListe(s['gorseller']);
    if (gorseller.isNotEmpty) {
      const durumAd = {'kural_yok': 'fiyat işletmeye soruldu', 'hata': 'incelenemedi', 'belirsiz': 'model soruldu', 'uygun_degil': 'model görünmedi'};
      w.add(SizedBox(
        height: 230,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: gorseller.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, i) {
            final g = gorseller[i];
            final url = WaApi.gorselUrl(widget.d.sube, sayiDeger(g['id']).toInt());
            return Container(
              width: 170,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              clipBehavior: Clip.antiAlias,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Expanded(
                  child: g['dosya'] == true
                      ? GestureDetector(
                          onTap: () => showDialog(
                            context: context,
                            builder: (_) => Dialog(
                              child: InteractiveViewer(child: Image.network(url, headers: WaApi.sonHeaders)),
                            ),
                          ),
                          child: Image.network(url, headers: WaApi.sonHeaders, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, color: Colors.grey))),
                        )
                      : const Center(child: WaAlt('Fotoğraf silindi')),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if ('${g['tarif'] ?? ''}'.isNotEmpty) Text('${g['tarif']}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5)),
                    const SizedBox(height: 3),
                    g['toplam'] != null
                        ? Text(tl(g['toplam']), style: const TextStyle(fontWeight: FontWeight.w800))
                        : WaHap(durumAd['${g['durum']}'] ?? '${g['durum']}', sinif: 'g'),
                  ]),
                ),
              ]),
            );
          },
        ),
      ));
    }

    // Mesajlar
    final satirlar = haritaListe(s['satirlar']);
    w.add(Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        children: satirlar.map((m) {
          final rol = '${m['rol']}';
          final musteri = rol == 'musteri';
          final personel = rol == 'personel';
          final etiket = musteri
              ? 'Müşteri'
              : (personel ? '${m['yazan'] ?? 'Personel'}' : (m['geri_kazanim'] == true ? 'Asistan · geri kazanma' : (m['hatirlatma'] == true ? 'Hatırlatma' : 'Asistan')));
          final renk = musteri ? Colors.white : (personel ? const Color(0xFFFEF3C7) : const Color(0xFFDCF8C6));
          return Align(
            alignment: musteri ? Alignment.centerLeft : Alignment.centerRight,
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.fromLTRB(11, 7, 11, 6),
              decoration: BoxDecoration(
                color: renk,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(musteri ? 3 : 14),
                  bottomRight: Radius.circular(musteri ? 14 : 3),
                ),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 1))],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(etiket, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: musteri ? scheme.primary : const Color(0xFF15803D))),
                const SizedBox(height: 2),
                SelectableText('${m['metin'] ?? ''}', style: const TextStyle(fontSize: 14, height: 1.35)),
                if (m['at'] != null)
                  Align(alignment: Alignment.bottomRight, child: Text(saatKisa(m['at']), style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600))),
              ]),
            ),
          );
        }).toList(),
      ),
    ));
    if (satirlar.isEmpty) w.add(const WaBos('Bu sohbette mesaj yok.'));
    return w;
  }

  // İşletmeye sorulan konunun sonucu: ne zaman soruldu, kime bildirildi, hatırlatma, asistanın dönüşü, kim cevapladı
  Widget _talepKart(Map<String, dynamic> t) {
    Widget adim(IconData ik, Color renk, String baslik, String? alt, dynamic zaman, {Widget? sag}) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CircleAvatar(radius: 14, backgroundColor: renk, child: Icon(ik, size: 15, color: Colors.white)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(baslik, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                if (alt != null && alt.isNotEmpty) Text(alt, style: TextStyle(fontSize: 12.3, color: Colors.grey.shade700, height: 1.4)),
                if (sag != null) Padding(padding: const EdgeInsets.only(top: 6), child: sag),
              ]),
            ),
            if (zaman != null) Text(saatKisa(zaman), style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ]),
        );

    final b = liste(t['bildirilen']);
    final ulasti = b.whereType<Map>().where((x) => x['ulasti'] == true).map((x) => '${x['ad']}').toList();
    final ulasmadi = b.whereType<Map>().where((x) => x['ulasti'] != true).map((x) => '${x['ad']}').toList();
    final eski = b.where((x) => x is! Map).map((x) => '$x').toList();
    final bildirim = [
      if (ulasti.isNotEmpty) 'Telefonuna ulaştı: ${ulasti.join(', ')}',
      'Panelde zil bildirimi olarak görünür.',
      if (ulasmadi.isNotEmpty) 'Ulaşmadı (Randevumcepte uygulamasında oturum yok ya da bildirim izni kapalı): ${ulasmadi.join(', ')}',
      if (eski.isNotEmpty) 'Bildirim gönderilenler: ${eski.join(', ')}',
      if ('${t['ozet'] ?? ''}'.isNotEmpty) 'Müşteri: “${'${t['ozet']}'.length > 160 ? '${t['ozet']}'.substring(0, 160) : t['ozet']}”',
    ].join('\n');

    final durum = '${t['durum']}';
    final kenar = durum == 'bekliyor' ? const Color(0xFFFECACA) : (durum == 'cevaplandi' ? const Color(0xFFBBF7D0) : const Color(0xFFE5E7EB));
    return WaKart(
      kenar: kenar,
      child: Column(children: [
        adim(Icons.send, const Color(0xFFF59E0B), 'İşletmeye soruldu: ${t['konu_ad'] ?? ''}', bildirim, t['acildi']),
        if (t['hatirlatma_at'] != null)
          adim(Icons.notifications, const Color(0xFFFB923C), 'Hatırlatma gönderildi', 'Henüz kimse dönmediği için yöneticilere tekrar bildirildi.', t['hatirlatma_at']),
        if (t['asistan_dondu_at'] != null)
          adim(Icons.smart_toy, waMor, 'Asistan müşteriye döndü', 'Müşteri bekletilmesin diye nazikçe bilgi verdi ve randevuya devam etti.', t['asistan_dondu_at']),
        if (durum == 'cevaplandi')
          adim(Icons.check_circle, const Color(0xFF16A34A), 'İşletme cevapladı', '${t['cevaplayan'] ?? ''} · ${t['sure'] ?? ''} içinde', t['cevaplandi_at'])
        else if (durum == 'cevapsiz')
          adim(Icons.cancel, const Color(0xFFDC2626), 'İşletme dönmedi', '24 saat içinde cevap verilmedi.', null)
        else
          adim(
            Icons.hourglass_bottom,
            const Color(0xFFDC2626),
            '${t['sure'] ?? ''}dır dönüş bekliyor',
            'Aşağıdan ya da telefonunuzdan müşteriye yazın; yazınca burası kendiliğinden "cevaplandı" olur. Asistan bu arada müşteriyle ilgilenmeye devam ediyor.',
            null,
            sag: widget.d.yaz
                ? FilledButton.icon(
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Cevapladım'),
                    onPressed: () => _post('cevaplandi', 'İşaretlendi: işletme cevapladı.'),
                  )
                : null,
          ),
      ]),
    );
  }
}

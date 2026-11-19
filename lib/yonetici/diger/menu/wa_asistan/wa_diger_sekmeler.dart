// WhatsApp Asistanı > Kaçan & Geri Kazanılan, Asistan Gelişimi, Öğrenilen Cevaplar, Ayarlar sekmeleri.

import 'package:flutter/material.dart';

import 'wa_asistan_api.dart';
import 'wa_asistan_page.dart';
import 'wa_widgets.dart';

// ======================================================================== KAÇAN & GERİ KAZANILAN
class WaGeriKazanimSekme extends StatefulWidget {
  final WaDurum d;
  const WaGeriKazanimSekme({super.key, required this.d});
  @override
  State<WaGeriKazanimSekme> createState() => _WaGeriKazanimSekmeState();
}

class _WaGeriKazanimSekmeState extends State<WaGeriKazanimSekme> with AutomaticKeepAliveClientMixin {
  WaDurum get d => widget.d;
  List<Map<String, dynamic>>? _gk;
  String _sonDonem = '';

  static const _durum = {
    'gonderildi': ['Yazıldı', 'm'],
    'cevap': ['Cevap verdi', 'm'],
    'randevu': ['Randevu aldı', 'y'],
    'geldi': ['Salona geldi', 'y'],
    'gelmedi': ['Gelmedi', 'k'],
    'ret': ['İstemedi', 'k'],
    'gonderilemedi': ['Gönderilemedi', 'k'],
  };
  static const _neden = {
    'fiyat': 'Fiyat aldı',
    'pahali': 'Fiyatı yüksek buldu',
    'dusunme': 'Düşünecekti',
    'gorsel': 'Fotoğrafa fiyat aldı',
    'saat': 'Saatlere baktı',
    'bilgi': 'Bilgi aldı',
  };

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    d.addListener(_donemKontrol);
    _yukle();
  }

  @override
  void dispose() {
    d.removeListener(_donemKontrol);
    super.dispose();
  }

  void _donemKontrol() {
    if (d.donem != _sonDonem) _yukle();
  }

  Future<void> _yukle() async {
    _sonDonem = d.donem;
    setState(() => _gk = null);
    final r = await WaApi.al(d.sube, '/geri-kazanim', {'donem': d.donem});
    if (!mounted) return;
    setState(() => _gk = okMu(r) ? haritaListe(r['liste']) : []);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return AnimatedBuilder(
      animation: d,
      builder: (context, _) {
        final kacan = haritaListe(d.ozet['kacan']);
        return RefreshIndicator(
          onRefresh: () async => Future.wait([d.ozetYukle(), _yukle()]),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 30),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              WaKart(
                baslik: 'Kaçan müşteriler',
                ikon: Icons.person_add_alt,
                ikonRenk: const Color(0xFFF97316),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const WaAlt('Asistandan fiyat, bilgi, müsait saat ya da fotoğrafa fiyat alıp randevu oluşturmayan müşteriler. Asistan ayarlardaki süre dolunca bu müşterilere bir kez nazikçe yazar.'),
                  const SizedBox(height: 8),
                  if (d.ozetCevap == null)
                    const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))
                  else if (kacan.isEmpty)
                    const WaBos('Bu dönemde kaçan müşteri yok.')
                  else
                    ...kacan.map((x) => _satir(
                          ad: '${x['ad'] ?? ''}'.isEmpty ? 'Müşteri' : '${x['ad']}',
                          alt: '${x['telefon'] ?? ''}'.isEmpty ? 'gizli numara' : '${x['telefon']}',
                          ust: '${x['hizmet'] ?? ''}'.isEmpty ? '—' : '${x['hizmet']}',
                          hap: WaHap('${x['neden']}${sayiDeger(x['ret']) > 0 ? ' · yazılmaz' : ''}', sinif: sayiDeger(x['ret']) > 0 ? 'k' : 'm'),
                          sag: tarihSaat(x['tarih']),
                          onTap: x['oturum_id'] != null ? () => d.sohbetAc?.call(sayiDeger(x['oturum_id']).toInt()) : null,
                        )),
                ]),
              ),
              WaKart(
                baslik: 'Geri kazanma mesajları',
                ikon: Icons.autorenew,
                child: _gk == null
                    ? const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))
                    : _gk!.isEmpty
                        ? const WaBos('Bu dönemde geri kazanma mesajı gönderilmedi.')
                        : Column(
                            children: _gk!.map((x) {
                              final dr = _durum['${x['durum']}'] ?? ['${x['durum']}', 'g'];
                              return _satir(
                                ad: '${x['ad'] ?? ''}'.isEmpty ? 'Müşteri' : '${x['ad']}',
                                alt: '${x['hizmet_ad'] ?? ''}',
                                ust: _neden['${x['neden']}'] ?? '${x['neden'] ?? ''}',
                                hap: WaHap(dr[0], sinif: dr[1]),
                                sag: tarihSaat(x['gonderildi_at']),
                                ek: [
                                  if (x['randevu_tarih'] != null) 'Randevu: ${x['randevu_tarih']}',
                                  if (sayiDeger(x['tutar']) > 0) tl(x['tutar']),
                                ].join(' · '),
                                onTap: () => _mesajGoster(x),
                              );
                            }).toList(),
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _mesajGoster(Map<String, dynamic> x) {
    final id = sayiDeger(x['yeni_oturum_id']).toInt();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('${x['ad'] ?? 'Müşteri'}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 4),
            WaAlt('Gönderildi: ${tarihSaat(x['gonderildi_at'])}${x['cevap_at'] != null ? ' · Cevap: ${tarihSaat(x['cevap_at'])}' : ''}'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFDCF8C6), borderRadius: BorderRadius.circular(12)),
              child: Text('${x['mesaj'] ?? '—'}', style: const TextStyle(height: 1.4)),
            ),
            if (id > 0) ...[
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(c);
                  d.sohbetAc?.call(id);
                },
                icon: const Icon(Icons.chat),
                label: const Text('Sohbeti aç'),
              ),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _satir({required String ad, required String alt, required String ust, required Widget hap, required String sag, String ek = '', VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(ad, style: const TextStyle(fontWeight: FontWeight.w700)),
              if (alt.isNotEmpty) WaAlt(alt),
              const SizedBox(height: 3),
              Text(ust, style: const TextStyle(fontSize: 12.8)),
              const SizedBox(height: 4),
              hap,
              if (ek.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 3), child: WaAlt(ek)),
            ]),
          ),
          Text(sag, style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
          if (onTap != null) Icon(Icons.chevron_right, color: Colors.grey.shade400),
        ]),
      ),
    );
  }
}

// ======================================================================== ASİSTAN GELİŞİMİ (Gece Denetçisi)
class WaGelisimSekme extends StatefulWidget {
  final WaDurum d;
  const WaGelisimSekme({super.key, required this.d});
  @override
  State<WaGelisimSekme> createState() => _WaGelisimSekmeState();
}

class _WaGelisimSekmeState extends State<WaGelisimSekme> with AutomaticKeepAliveClientMixin {
  WaDurum get d => widget.d;
  Map<String, dynamic>? _r;
  String? _hata;
  bool _baslatiliyor = false;
  final Map<int, TextEditingController> _cevaplar = {};
  final Set<int> _acik = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  @override
  void dispose() {
    for (final c in _cevaplar.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _yukle() async {
    final r = await WaApi.al(d.sube, '/gelisim');
    if (!mounted) return;
    setState(() {
      if (okMu(r)) {
        _r = r;
        _hata = null;
      } else {
        _hata = '${r['hata'] ?? 'Yüklenemedi.'}';
      }
    });
  }

  Future<void> _baslat() async {
    setState(() => _baslatiliyor = true);
    final r = await WaApi.gonder(d.sube, '/denetim-baslat');
    if (!mounted) return;
    setState(() => _baslatiliyor = false);
    waToast(
        context,
        okMu(r)
            ? (sayiDeger(r['adet']) > 0 ? '${r['adet']} sohbet incelemeye gönderildi. Sonuçlar genellikle 1 saat içinde gelir.' : 'İncelenecek yeni sohbet yok.')
            : '${r['hata'] ?? 'Başlatılamadı.'}');
    if (okMu(r)) _yukle();
  }

  Future<void> _dersDurum(int id, String durum) async {
    final r = await WaApi.gonder(d.sube, '/ders/$id/durum', {'durum': durum});
    if (!mounted) return;
    waToast(context, okMu(r) ? (durum == 'aktif' ? 'Ders uygulanıyor.' : 'Ders kapatıldı.') : '${r['hata'] ?? 'Kaydedilemedi.'}');
    _yukle();
  }

  Future<void> _bilgiCevap(int id, String cevap) async {
    final r = await WaApi.gonder(d.sube, '/ders/$id/cevap', {'cevap': cevap});
    if (!mounted) return;
    waToast(context, okMu(r) ? (cevap.isNotEmpty ? 'Kaydedildi. Asistan bu soruyu artık kendisi cevaplar.' : 'Yoksayıldı.') : 'Kaydedilemedi.');
    _yukle();
  }

  Color _puanRenk(num p) => p >= 85 ? const Color(0xFF16A34A) : (p >= 70 ? const Color(0xFFD97706) : const Color(0xFFDC2626));

  Widget _fark(num? simdi, num? once, {bool tersIyi = false}) {
    if (simdi == null || once == null) return const SizedBox.shrink();
    final f = ((simdi - once) * 10).round() / 10;
    if (f == 0) return const SizedBox.shrink();
    final iyi = tersIyi ? f < 0 : f > 0;
    return Text(' ${f > 0 ? '▲' : '▼'} ${virgul(f.abs())}', style: TextStyle(fontSize: 11, color: iyi ? const Color(0xFF5EEAD4) : const Color(0xFFFCA5A5)));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final r = _r;
    return RefreshIndicator(
      onRefresh: _yukle,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 30),
        physics: const AlwaysScrollableScrollPhysics(),
        children: r == null ? [_hata != null ? WaBos(_hata!) : const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))] : _icerik(r),
      ),
    );
  }

  List<Widget> _icerik(Map<String, dynamic> r) {
    final dersler = haritaListe(r['dersler']);
    final aktif = dersler.where((x) => x['tur'] == 'davranis' && x['durum'] == 'aktif').toList();
    final bilgi = dersler.where((x) => x['tur'] == 'bilgi' && x['durum'] == 'oneri').toList();
    final onay = dersler.where((x) => x['tur'] == 'davranis' && x['durum'] == 'oneri').toList();
    final diger = dersler.where((x) => x['tur'] == 'davranis' && (x['durum'] == 'kapali' || x['durum'] == 'reddedildi')).toList();
    final kod = dersler.where((x) => x['tur'] == 'kod' && x['durum'] == 'oneri').toList();
    final acik = r['acik'] == true || '${r['acik']}' == '1';
    final oto = r['oto'] == true || '${r['oto']}' == '1';
    final puan = sayiYaDaNull(r['puan']);
    final w = <Widget>[];

    Widget tile(String b, String e, [Widget? f]) => Expanded(
          child: Container(
            margin: const EdgeInsets.all(3),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Text(b, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17)), if (f != null) f]),
              Text(e, style: const TextStyle(color: Colors.white70, fontSize: 11)),
            ]),
          ),
        );

    // 1) Hero
    w.add(Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF134E4A)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          WaHalka(
            yuzde: puan ?? 0,
            renk: const Color(0xFF5EEAD4),
            ic: puan != null ? '${puan.round()}' : '–',
            alt: 'kalite puanı',
            boyut: 92,
            zemin: Colors.white12,
            yaziRenk: Colors.white,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(12)),
                child: Text('🌙 Gece Denetçisi · ${acik ? (oto ? 'Kendini geliştiriyor' : 'Önerileri onayınıza sunuyor') : 'Kapalı'}',
                    style: const TextStyle(color: Colors.white, fontSize: 11.5)),
              ),
              const SizedBox(height: 6),
              const Text('Asistan her gece sohbetlerini inceleyip kendini geliştiriyor.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
            ]),
          ),
        ]),
        const SizedBox(height: 8),
        const Text(
          'Sorunlu cevapları bulur, "doğrusu buydu" cevabını yazar ve dersi geçmiş sohbetlerde yeniden deneyip daha iyi sonuç verirse uygular. Fiyatlarınız ve kurallarınız kendiliğinden değişmez.',
          style: TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.4),
        ),
        const SizedBox(height: 8),
        Row(children: [
          tile(sayi(r['incelenen']), 'sohbet incelendi (7 gün)'),
          tile(r['randevu_mesaj'] != null ? virgul(r['randevu_mesaj']) : '–', 'mesajda randevu (ortalama)',
              _fark(sayiYaDaNull(r['randevu_mesaj']), sayiYaDaNull(r['randevu_mesaj_once']), tersIyi: true)),
        ]),
        Row(children: [
          tile('${aktif.length}', 'ders uygulanıyor'),
          tile(sayi(r['sorunlu']), 'sorunlu sohbet (puan < 70)'),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF14B8A6)),
            onPressed: _baslatiliyor ? null : _baslat,
            icon: const Icon(Icons.play_circle_fill, size: 18),
            label: const Text('Şimdi incele'),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              sayiDeger(r['bekleyen_is']) > 0 ? '${sayi(r['bekleyen_is'])} sohbet incelemede; sonuç genellikle 1 saat içinde gelir.' : 'Otomatik inceleme her gece 03:00\'te.',
              style: const TextStyle(color: Colors.white70, fontSize: 11.5),
            ),
          ),
        ]),
      ]),
    ));

    if (!acik) {
      w.add(GestureDetector(
        onTap: () => d.sekmeAc?.call(7),
        child: const WaBilgi('Gece denetçisi kapalı. Açmak için Ayarlar sekmesinden "Gece denetçisi sohbetleri incelesin" seçeneğini açın.', renk: Color(0xFFD97706)),
      ));
    }
    if (sayiDeger(r['incelenen']) == 0 && dersler.isEmpty) {
      w.add(const WaKart(
        child: WaBos(
            'Henüz incelenen sohbet yok. Denetçi her gece 03:00\'te, son 3 günde biten sohbetleri inceler. Hemen başlatmak için yukarıdaki "Şimdi incele" düğmesine basın; sonuçlar genellikle 1 saat içinde burada görünür.'),
      ));
      return w;
    }

    // 2) Sizden beklenenler
    if (bilgi.isNotEmpty || onay.isNotEmpty) {
      w.add(WaKart(
        baslik: 'Sizden beklenenler (${bilgi.length + onay.length})',
        ikon: Icons.help,
        ikonRenk: const Color(0xFFD97706),
        kenar: const Color(0xFFFDE68A),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          ...bilgi.map((x) {
            final id = sayiDeger(x['id']).toInt();
            final c = _cevaplar.putIfAbsent(id, () => TextEditingController());
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text('Müşteriler soruyor: "${x['metin']}"', style: const TextStyle(fontWeight: FontWeight.w700)),
                WaAlt('${'${x['gerekce'] ?? ''}'.isNotEmpty ? x['gerekce'] : 'Asistan bu bilgiyi bilmediği için cevaplayamadı.'} Cevabınızı yazarsanız asistan bundan sonra bunu kendisi cevaplar.'),
                const SizedBox(height: 6),
                TextField(
                  controller: c,
                  maxLines: 2,
                  maxLength: 1000,
                  decoration: InputDecoration(isDense: true, hintText: 'Cevabınız (müşteriye aynen gider)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                ),
                Row(children: [
                  FilledButton(
                    onPressed: () {
                      final v = c.text.trim();
                      if (v.isEmpty) {
                        waToast(context, 'Önce cevabınızı yazın.');
                        return;
                      }
                      _bilgiCevap(id, v);
                    },
                    child: const Text('Kaydet'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(onPressed: () => _bilgiCevap(id, ''), child: const Text('Yoksay')),
                ]),
              ]),
            );
          }),
          ...onay.map((x) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text('Önerilen ders: ${x['metin']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                  WaAlt('${harita(x['test'])['not'] ?? x['gerekce'] ?? ''}'),
                  const SizedBox(height: 6),
                  Row(children: [
                    FilledButton(onPressed: () => _dersDurum(sayiDeger(x['id']).toInt(), 'aktif'), child: const Text('Uygula')),
                    const SizedBox(width: 8),
                    OutlinedButton(onPressed: () => _dersDurum(sayiDeger(x['id']).toInt(), 'kapali'), child: const Text('Uygulama')),
                  ]),
                ]),
              )),
        ]),
      ));
    }

    // 3) Kalite puanı grafiği + sorun türleri
    final g = haritaListe(r['gunluk']);
    w.add(WaKart(
      baslik: 'Kalite puanı (son 14 gün)',
      ikon: Icons.monitor_heart,
      ikonRenk: const Color(0xFF14B8A6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (r['puan_once'] != null && r['puan'] != null) WaAlt('önceki hafta ${virgul(r['puan_once'])} → bu hafta ${virgul(r['puan'])}'),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            for (final x in g)
              Expanded(
                child: Tooltip(
                  message: '${x['gun']} · ${x['puan'] == null ? 'inceleme yok' : 'puan ${x['puan']} · ${x['adet']} sohbet'}',
                  child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                    if (x['puan'] != null) Text('${x['puan']}', style: const TextStyle(fontSize: 9)),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      height: x['puan'] == null ? 3 : (sayiDeger(x['puan']).clamp(4, 100) * 0.95).toDouble(),
                      decoration: BoxDecoration(
                        color: x['puan'] == null ? Colors.grey.shade300 : (sayiDeger(x['puan']) < 70 ? const Color(0xFFF87171) : const Color(0xFF2DD4BF)),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ]),
                ),
              ),
          ]),
        ),
        Row(children: [
          for (var i = 0; i < g.length; i++)
            Expanded(
              child: Text(
                i % 3 == 0 && '${g[i]['gun']}'.length >= 10 ? '${int.tryParse('${g[i]['gun']}'.substring(8)) ?? ''} ${aylarKisa[(int.tryParse('${g[i]['gun']}'.substring(5, 7)) ?? 1) - 1]}' : '',
                style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                softWrap: false,
                overflow: TextOverflow.visible,
              ),
            ),
        ]),
      ]),
    ));

    final turlar = haritaListe(r['turlar']);
    final tmx = turlar.isEmpty ? 1 : turlar.map((t) => sayiDeger(t['adet'])).reduce((a, b) => a > b ? a : b).clamp(1, double.infinity);
    w.add(WaKart(
      baslik: 'En sık görülen sorunlar',
      ikon: Icons.bug_report,
      ikonRenk: const Color(0xFFF97316),
      child: turlar.isEmpty
          ? const WaBos('Bu hafta sorun bulunmadı. Asistanın cevapları denetçiden tam not aldı.')
          : Column(
              children: turlar
                  .take(7)
                  .map((t) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(children: [
                          SizedBox(width: 130, child: Text('${t['ad']}', style: const TextStyle(fontSize: 12.5), maxLines: 2)),
                          Expanded(child: WaCubuk(sayiDeger(t['adet']) / tmx, const Color(0xFFF97316))),
                          const SizedBox(width: 8),
                          Text('${t['adet']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                        ]),
                      ))
                  .toList(),
            ),
    ));

    // 4) Asistanın öğrendikleri
    Widget dersSatir(Map<String, dynamic> x) {
      final t = harita(x['test']);
      final k = harita(t['kanit']);
      final toplamK = sayiDeger(k['yeni']) + sayiDeger(k['eski']) + sayiDeger(k['esit']);
      final durum = '${x['durum']}';
      final id = sayiDeger(x['id']).toInt();
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(durum == 'aktif' ? Icons.verified : Icons.lightbulb, color: durum == 'aktif' ? const Color(0xFF0D9488) : Colors.grey, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${x['metin']}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
              if ('${x['gerekce'] ?? ''}'.isNotEmpty) WaAlt('${x['gerekce']}'),
              const SizedBox(height: 4),
              Wrap(spacing: 6, runSpacing: 4, children: [
                if (durum == 'aktif') const WaHap('Uygulanıyor', sinif: 'y'),
                if (durum == 'reddedildi') const WaHap('Testi geçemedi, uygulanmadı', sinif: 'k'),
                if (durum == 'kapali') const WaHap('Kapatıldı', sinif: 'g'),
                if (toplamK > 0) WaHap('Testte ${k['yeni']}/$toplamK sorunlu sohbette daha iyi', sinif: 'm'),
              ]),
              const SizedBox(height: 2),
              WaAlt(tarihSaat(x['created_at'])),
            ]),
          ),
          if (durum == 'aktif') TextButton(onPressed: () => _dersDurum(id, 'kapali'), child: const Text('Geri al')),
          if (durum == 'kapali' || durum == 'reddedildi') TextButton(onPressed: () => _dersDurum(id, 'aktif'), child: const Text('Yine de uygula')),
        ]),
      );
    }

    w.add(WaKart(
      baslik: 'Asistanın öğrendikleri',
      ikon: Icons.school,
      ikonRenk: const Color(0xFF0D9488),
      sag: WaAlt('${aktif.length} ders uygulanıyor'),
      child: aktif.isEmpty && diger.isEmpty
          ? const WaBos('Henüz ders yok. Denetçi tekrarlayan bir sorun gördüğünde ders önerir, test eder ve burada gösterir.')
          : Column(children: [...aktif, ...diger].map(dersSatir).toList()),
    ));

    // 5) Son incelenen sohbetler
    final son = haritaListe(r['son']);
    w.add(WaKart(
      baslik: 'Son incelenen sohbetler',
      ikon: Icons.format_quote,
      child: son.isEmpty
          ? const WaBos('Bu hafta incelenen sohbet yok.')
          : Column(
              children: son.asMap().entries.map((e) {
                final s = e.value;
                final sorunlar = haritaListe(s['sorunlar']);
                final p = sayiDeger(s['puan']);
                final ac = _acik.contains(e.key);
                return Container(
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    InkWell(
                      onTap: () => setState(() => ac ? _acik.remove(e.key) : _acik.add(e.key)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Container(
                            width: 38,
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(color: _puanRenk(p).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                            child: Text('${s['puan']}', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, color: _puanRenk(p))),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text.rich(TextSpan(children: [
                                TextSpan(text: '${s['ad'] ?? 'Müşteri'}  ', style: const TextStyle(fontWeight: FontWeight.w700)),
                                TextSpan(text: tarihSaat(s['tarih']), style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
                              ])),
                              Text('${s['ozet'] ?? ''}', style: const TextStyle(fontSize: 12.5)),
                              const SizedBox(height: 4),
                              sorunlar.isNotEmpty ? WaHap('${sorunlar.length} sorun', sinif: 'm') : const WaHap('Sorunsuz', sinif: 'y'),
                            ]),
                          ),
                          Icon(ac ? Icons.expand_less : Icons.expand_more, color: Colors.grey),
                        ]),
                      ),
                    ),
                    if (ac) ...[
                      ...sorunlar.map((x) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(10)),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                              Text('${x['tur']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                              Text('${x['aciklama'] ?? ''}', style: const TextStyle(fontSize: 12.8)),
                              if ('${x['dogrusu'] ?? ''}'.isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(top: 6),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(8)),
                                  child: Text('${x['dogrusu']}', style: const TextStyle(fontSize: 12.8)),
                                ),
                            ]),
                          )),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: s['oturum_id'] == null ? null : () => d.sohbetAc?.call(sayiDeger(s['oturum_id']).toInt()),
                          child: const Text('Sohbeti aç →'),
                        ),
                      ),
                    ],
                  ]),
                );
              }).toList(),
            ),
    ));

    if (kod.isNotEmpty) {
      w.add(WaKart(
        padding: EdgeInsets.zero,
        child: ExpansionTile(
          leading: const Icon(Icons.bug_report),
          title: Text('Geliştirici notları (${kod.length})', style: const TextStyle(fontSize: 13.5)),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          children: [
            ...kod.map((x) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Text('${x['metin']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text('${x['gerekce'] ?? ''}', style: const TextStyle(fontSize: 12.5)),
                    Align(alignment: Alignment.centerLeft, child: TextButton(onPressed: () => _bilgiCevap(sayiDeger(x['id']).toInt(), ''), child: const Text('Okundu'))),
                  ]),
                )),
            const WaAlt('Bu notlar sistemsel sorunlardır; destek ekibimiz de görür.'),
          ],
        ),
      ));
    }
    return w;
  }
}

// ======================================================================== ÖĞRENİLEN CEVAPLAR
class WaOgrenilenSekme extends StatefulWidget {
  final WaDurum d;
  const WaOgrenilenSekme({super.key, required this.d});
  @override
  State<WaOgrenilenSekme> createState() => _WaOgrenilenSekmeState();
}

class _WaOgrenilenSekmeState extends State<WaOgrenilenSekme> with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>>? _liste;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    final r = await WaApi.al(widget.d.sube, '/ogrenilen');
    if (!mounted) return;
    setState(() => _liste = okMu(r) ? haritaListe(r['liste']) : []);
  }

  Future<void> _sil(int id) async {
    if (!await waOnay(context, 'Bu öğrenilmiş cevap silinsin mi? Asistan bu soruya bir dahaki sefere yeniden cevap üretir.', evet: 'Sil')) return;
    final r = await WaApi.gonder(widget.d.sube, '/ogrenilen/$id/sil');
    if (!mounted) return;
    waToast(context, okMu(r) ? 'Silindi.' : 'Silinemedi.');
    _yukle();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RefreshIndicator(
      onRefresh: _yukle,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 30),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const WaBilgi(
              'Asistan genel bir soruya (ör. "otopark var mı") yapay zekâyla bir kez cevap verince o cevabı öğrenir; aynı soru sonra ücretsiz ve anında cevaplanır. Yanlış ya da eskimiş bir cevabı silebilirsiniz; asistan bir dahaki sefere yeniden düşünür. Öğrenilen cevaplar 30 günde bir yenilenir.'),
          if (_liste == null)
            const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator()))
          else if (_liste!.isEmpty)
            const WaKart(child: WaBos('Henüz öğrenilmiş cevap yok. Asistan genel sorulara cevap verdikçe burası dolacak.'))
          else
            ..._liste!.map((x) => WaKart(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Icon(Icons.help_outline, size: 18, color: waMor),
                      const SizedBox(width: 6),
                      Expanded(child: Text('${x['soru']}', style: const TextStyle(fontWeight: FontWeight.w700))),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Sil',
                        icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626)),
                        onPressed: () => _sil(sayiDeger(x['id']).toInt()),
                      ),
                    ]),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: const Color(0xFFDCF8C6), borderRadius: BorderRadius.circular(10)),
                      child: Text('${x['cevap']}', style: const TextStyle(fontSize: 13.2, height: 1.4)),
                    ),
                    const SizedBox(height: 6),
                    WaAlt('${sayi(x['adet'])} kez ücretsiz kullanıldı'),
                  ]),
                )),
        ],
      ),
    );
  }
}

// ======================================================================== AYARLAR
class WaAyarlarSekme extends StatefulWidget {
  final WaDurum d;
  const WaAyarlarSekme({super.key, required this.d});
  @override
  State<WaAyarlarSekme> createState() => _WaAyarlarSekmeState();
}

class _WaAyarlarSekmeState extends State<WaAyarlarSekme> with AutomaticKeepAliveClientMixin {
  WaDurum get d => widget.d;
  final Map<String, bool> _anahtar = {};
  final _bekle = TextEditingController();
  final _kampanya = TextEditingController();
  bool _kaydediliyor = false;
  bool _testGonderiliyor = false;
  Map<String, dynamic>? _testSonuc;

  static const _ayarlar = <(String, String, String)>[
    ('fiyat_soyle', 'Fiyat sorularını cevaplasın',
        '"Protez tırnak ne kadar?" gibi sorulara hizmet listenizdeki fiyatla cevap verir. Kapalıysa fiyat soran müşteriye fiyatı işletmeye sorduğunu söyler ve size bildirir.'),
    ('gorsel_fiyat', 'Fotoğraftan fiyat versin', 'Müşterinin gönderdiği model fotoğrafına, "Fotoğraftan Fiyat" sekmesindeki eşleşmelerle fiyat verir.'),
    ('memnuniyet_sor', 'Randevudan sonra memnuniyet sorsun', 'Randevu oluşturulunca tek satırlık 👍 / 👎 sorusu eklenir.'),
    ('denetci', 'Gece denetçisi sohbetleri incelesin',
        'Her gece biten sohbetleri inceler, sorunları ve "doğrusu buydu" cevabını "Asistan Gelişimi" sekmesine yazar. (Paketinizden düşmez.)'),
    ('denetci_oto', 'Test edilen dersleri kendisi uygulasın',
        'Denetçinin önerdiği davranış dersi, geçmiş sohbetlerde yeniden denenip daha iyi sonuç verirse asistan hemen uygular. Kapalıysa her ders sizin onayınızı bekler. Fiyat, kampanya ve kurallarınız asla kendiliğinden değişmez.'),
    ('geri_kazanim', 'Kaçan müşteriye tekrar yazsın',
        'Fiyat/bilgi alıp randevu oluşturmayan müşteriye belirlediğiniz süre sonunda, mesai saatinde bir kez yazar ve gerçek boş saatlerinizi önerir. Müşteri "dur" yazarsa bir daha yazılmaz.'),
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _doldur();
  }

  void _doldur() {
    for (final a in _ayarlar) {
      _anahtar[a.$1] = '${d.ayar[a.$1]}' == '1';
    }
    _bekle.text = '${d.ayar['gk_bekle_saat'] ?? 24}';
    _kampanya.text = '${d.ayar['gk_kampanya'] ?? ''}';
  }

  @override
  void dispose() {
    _bekle.dispose();
    _kampanya.dispose();
    super.dispose();
  }

  Future<void> _kaydet() async {
    setState(() => _kaydediliyor = true);
    final v = <String, dynamic>{'gk_bekle_saat': _bekle.text.trim(), 'gk_kampanya': _kampanya.text};
    _anahtar.forEach((k, b) => v[k] = b ? 1 : 0);
    final r = await WaApi.gonder(d.sube, '/ayar', v);
    if (!mounted) return;
    setState(() => _kaydediliyor = false);
    if (okMu(r)) {
      d.ayarGuncelle(harita(r['ayar']));
      _doldur();
      waToast(context, 'Ayarlar kaydedildi.');
      d.ozetYukle();
    } else {
      waToast(context, '${r['hata'] ?? 'Kaydedilemedi.'}');
    }
  }

  Future<void> _testBildirim() async {
    setState(() {
      _testGonderiliyor = true;
      _testSonuc = null;
    });
    final r = await WaApi.gonder(d.sube, '/test-bildirim');
    if (!mounted) return;
    setState(() {
      _testGonderiliyor = false;
      _testSonuc = r;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 30),
      children: [
        WaKart(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (final a in _ayarlar)
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _anahtar[a.$1] ?? false,
                onChanged: (v) => setState(() => _anahtar[a.$1] = v),
                title: Text(a.$2, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                subtitle: Padding(padding: const EdgeInsets.only(top: 2), child: Text(a.$3, style: const TextStyle(fontSize: 12.3, height: 1.4))),
              ),
            const Divider(),
            Row(children: [
              const Expanded(child: Text('Kaç saat sonra yazsın', style: TextStyle(fontWeight: FontWeight.w600))),
              SizedBox(
                width: 100,
                child: TextField(
                  controller: _bekle,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(isDense: true, suffixText: 'saat', helperText: '2 – 168', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            const WaAlt('Fiyatı yüksek bulan müşteriye eklenecek teklif cümleniz (isteğe bağlı — boşsa teklif yapılmaz; asistan kendisi indirim uydurmaz)'),
            const SizedBox(height: 6),
            TextField(
              controller: _kampanya,
              maxLines: 2,
              maxLength: 500,
              decoration: InputDecoration(hintText: 'Örn. Bu haftaya özel protez tırnakta %10 indirimimiz var.', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            ),
            const SizedBox(height: 6),
            FilledButton.icon(
              onPressed: _kaydediliyor ? null : _kaydet,
              icon: _kaydediliyor ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.check),
              label: const Text('Ayarları kaydet'),
            ),
          ]),
        ),
        WaKart(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('Bildirimler telefonunuza geliyor mu?', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 4),
            const Text(
              'Asistan işletmeye bir şey sorduğunda yöneticilerin telefonuna (uygulama) ve paneldeki zile bildirim gider. Deneme bildirimi gönderip kimin telefonuna ulaştığını görün.',
              style: TextStyle(fontSize: 12.3, height: 1.4),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _testGonderiliyor ? null : _testBildirim,
              icon: _testGonderiliyor ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.notifications),
              label: const Text('Test bildirimi gönder'),
            ),
            if (_testSonuc != null) Padding(padding: const EdgeInsets.only(top: 8), child: _testSonucWidget(_testSonuc!)),
          ]),
        ),
      ],
    );
  }

  Widget _testSonucWidget(Map<String, dynamic> d) {
    if (!okMu(d)) return Text('${d['hata'] ?? 'Gönderilemedi.'}', style: const TextStyle(color: Color(0xFFB91C1C)));
    final l = haritaListe(d['liste']);
    final ok = l.where((x) => x['ulasti'] == true).map((x) => '${x['ad']}').toList();
    final yok = l.where((x) => x['ulasti'] != true).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (ok.isNotEmpty) Text('✓ Telefonuna ulaştı: ${ok.join(', ')}', style: const TextStyle(color: Color(0xFF15803D), fontWeight: FontWeight.w600)),
      if (yok.isNotEmpty) ...[
        const SizedBox(height: 4),
        const Text('Ulaşmadı:', style: TextStyle(color: Color(0xFFB45309), fontWeight: FontWeight.w700)),
        ...yok.map((x) => Padding(
              padding: const EdgeInsets.only(left: 8, top: 2),
              child: Text('• ${x['ad']} — ${x['neden'] ?? 'Ulaşmadı.'}', style: const TextStyle(fontSize: 12.5)),
            )),
      ],
      if (ok.isEmpty && yok.isEmpty) const Text('Yönetici yetkisinde personel bulunamadı.'),
      const SizedBox(height: 4),
      const WaAlt('Panelin sağ üstündeki zilde de görünür.'),
    ]);
  }
}

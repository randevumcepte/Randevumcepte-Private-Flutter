// WhatsApp Asistanı > Sohbetler (liste + detay). Web: sohbetListe / sohbetAc / talepSeridi.

import 'package:flutter/material.dart';

import 'wa_asistan_api.dart';
import 'wa_asistan_page.dart';
import 'wa_genel_sekme.dart';
import 'wa_widgets.dart';

class WaSohbetlerSekme extends StatefulWidget {
  final WaDurum d;
  const WaSohbetlerSekme({super.key, required this.d});
  @override
  State<WaSohbetlerSekme> createState() => _WaSohbetlerSekmeState();
}

class _WaSohbetlerSekmeState extends State<WaSohbetlerSekme> with AutomaticKeepAliveClientMixin {
  WaDurum get d => widget.d;
  DateTime _bas = DateTime.now().subtract(const Duration(days: 6));
  DateTime _bit = DateTime.now();
  final _ara = TextEditingController();
  bool _yukleniyor = true;
  String? _hata;
  List<Map<String, dynamic>> _liste = [];
  Map<String, dynamic>? _numaraKontrol;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _yukle();
    d.sohbetYenile.addListener(_yukle);
  }

  @override
  void dispose() {
    d.sohbetYenile.removeListener(_yukle);
    _ara.dispose();
    super.dispose();
  }

  Future<void> _yukle() async {
    if (!mounted) return;
    setState(() {
      _yukleniyor = true;
      _hata = null;
      _numaraKontrol = null;
    });
    final q = _ara.text.trim();
    final r = await WaApi.al(d.sube, '/sohbetler', {'baslangic': isoGun(_bas), 'bitis': isoGun(_bit), if (q.isNotEmpty) 'q': q});
    if (!mounted) return;
    setState(() {
      _yukleniyor = false;
      if (okMu(r)) {
        _liste = haritaListe(r['liste']);
      } else {
        _hata = '${r['hata'] ?? 'Sohbetler yüklenemedi.'}';
      }
    });
    // Telefonla aranıp bulunamadıysa: neden? (hariç numara / mesaj hiç gelmedi / işlenemedi)
    final rak = q.replaceAll(RegExp(r'\D'), '');
    if (okMu(r) && _liste.isEmpty && rak.length >= 10) {
      final k = await WaApi.al(d.sube, '/numara-kontrol', {'tel': rak});
      if (mounted && okMu(k)) setState(() => _numaraKontrol = k);
    }
  }

  Future<void> _tarihSec(bool bas) async {
    final s = await showDatePicker(
      context: context,
      initialDate: bas ? _bas : _bit,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      locale: const Locale('tr', 'TR'),
    );
    if (s == null) return;
    setState(() => bas ? _bas = s : _bit = s);
    _yukle();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    String g(DateTime x) => '${x.day.toString().padLeft(2, '0')}.${x.month.toString().padLeft(2, '0')}.${x.year}';
    return RefreshIndicator(
      onRefresh: _yukle,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 30),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          WaKart(
            child: Column(children: [
              Row(children: [
                Expanded(child: OutlinedButton.icon(onPressed: () => _tarihSec(true), icon: const Icon(Icons.event, size: 16), label: Text(g(_bas)))),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Text('–')),
                Expanded(child: OutlinedButton.icon(onPressed: () => _tarihSec(false), icon: const Icon(Icons.event, size: 16), label: Text(g(_bit)))),
              ]),
              const SizedBox(height: 8),
              TextField(
                controller: _ara,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _yukle(),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Ad veya telefon ara (tüm tarihler)',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _ara.text.isEmpty
                      ? null
                      : IconButton(icon: const Icon(Icons.close), onPressed: () { _ara.clear(); _yukle(); }),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ]),
          ),
          if (_yukleniyor)
            const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator()))
          else if (_hata != null)
            WaBos(_hata!)
          else if (_liste.isEmpty)
            WaKart(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                WaBos(_ara.text.trim().isNotEmpty ? 'Bu aramayla sohbet bulunamadı.' : 'Bu tarihlerde sohbet yok.'),
                if (_numaraKontrol != null) _numaraKontrolKart(_numaraKontrol!),
              ]),
            )
          else
            WaKart(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Column(
                children: [
                  for (var i = 0; i < _liste.length; i++) ...[
                    if (i > 0) Divider(height: 1, color: Colors.grey.shade200),
                    WaKonusmaSatiri(x: _liste[i], sube: d.sube, onTap: () => d.sohbetAc?.call(sayiDeger(_liste[i]['id']).toInt())),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
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
  Map<String, dynamic>? _s;
  String? _hata;
  bool _islem = false;
  final _kaydir = ScrollController();

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  @override
  void dispose() {
    _kaydir.dispose();
    super.dispose();
  }

  Future<void> _yukle() async {
    final r = await WaApi.al(widget.d.sube, '/sohbet/$_id');
    if (!mounted) return;
    setState(() {
      if (okMu(r)) {
        _s = harita(r['sohbet']);
        _hata = null;
      } else {
        _hata = '${r['hata'] ?? 'Sohbet gösterilemedi.'}';
      }
    });
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
        actions: [IconButton(onPressed: _yukle, icon: const Icon(Icons.refresh))],
      ),
      body: s == null
          ? Center(child: _hata != null ? WaBos(_hata!) : const CircularProgressIndicator())
          : Stack(children: [
              RefreshIndicator(
                onRefresh: _yukle,
                child: ListView(
                  controller: _kaydir,
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 30),
                  children: _icerik(s),
                ),
              ),
              if (_islem) const Positioned.fill(child: ColoredBox(color: Color(0x22000000), child: Center(child: CircularProgressIndicator()))),
            ]),
    );
  }

  List<Widget> _icerik(Map<String, dynamic> s) {
    final scheme = Theme.of(context).colorScheme;
    final devralindi = s['devralindi'] == true;
    final w = <Widget>[];

    w.add(WaKart(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Durum: ', style: TextStyle(fontWeight: FontWeight.w600)),
          Flexible(child: WaHap('${s['durum'] ?? ''}')),
        ]),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          OutlinedButton.icon(
            icon: const Icon(Icons.location_on, size: 18),
            label: const Text('Yol tarifi gönder'),
            onPressed: () async {
              if (!await waOnay(context, 'Salonun adresi ve Google Haritalar bağlantısı bu müşteriye WhatsApp\'tan gönderilsin mi?', evet: 'Gönder')) return;
              await _post('yol-tarifi', 'Yol tarifi gönderildi.', hataVarsayilan: 'Gönderilemedi.');
            },
          ),
          devralindi
              ? FilledButton.icon(
                  icon: const Icon(Icons.smart_toy, size: 18),
                  label: const Text('Asistana geri ver'),
                  onPressed: () => _post('geri-ver', 'Sohbet asistana geri verildi.'),
                )
              : OutlinedButton.icon(
                  icon: const Icon(Icons.person, size: 18),
                  label: const Text('Devral (asistan sussun)'),
                  onPressed: () => _post('devral', 'Sohbeti devraldınız; asistan bu sohbette susacak.'),
                ),
        ]),
        const SizedBox(height: 8),
        const WaAlt('Devraldığınızda asistan bu sohbette 24 saat ya da siz geri verene kadar cevap vermez. Telefonunuzdan müşteriye yazdığınızda da asistan otomatik susar.'),
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
          const SizedBox(height: 8),
          FilledButton.icon(
            icon: const Icon(Icons.smart_toy, size: 18),
            label: const Text('Asistan tamamlasın'),
            onPressed: () => _post('devam', 'Asistan sohbeti tamamladı ve müşteriye yazdı.', hataVarsayilan: 'Yapılamadı.'),
          ),
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
              : (personel ? 'Personel' : (m['geri_kazanim'] == true ? 'Asistan · geri kazanma' : (m['hatirlatma'] == true ? 'Hatırlatma' : 'Asistan')));
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
            'Müşteriye WhatsApp\'tan yazın; telefonunuzdan yazınca burası kendiliğinden "cevaplandı" olur. Asistan bu arada müşteriyle ilgilenmeye devam ediyor.',
            null,
            sag: FilledButton.icon(
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Cevapladım'),
              onPressed: () => _post('cevaplandi', 'İşaretlendi: işletme cevapladı.'),
            ),
          ),
      ]),
    );
  }
}

// WhatsApp Asistanı > Genel Bakış + Kazandırdıkları sekmeleri (web: genelYukle / kazandirdiklariHtml).

import 'package:randevu_sistem/dil/material.dart';

import 'wa_asistan_api.dart';
import 'wa_asistan_page.dart';
import 'wa_widgets.dart';

// Kart bilgi penceresi ("i" düğmesi): ne gösterir / nasıl hesaplanır / ne kazandırır — web KART_BILGI ile aynı metinler
const _kartBilgi = <String, List<String>>{
  'kazanc': [
    'Asistanın Getirdiği Kazanç',
    'WhatsApp asistanının sizin yerinize aldığı randevuların toplam hizmet tutarı.',
    'Asistanın oluşturduğu ve iptal edilmeyen randevuların hizmet fiyatları toplanır. Randevu panelde "geldi" işaretlenince tutar gerçekleşen kazanç olarak sayılır; işaretlenene kadar "randevu tutarı" olarak görünür.',
    'Asistanın size ne kadar iş getirdiğini doğrudan gösterir. Pakete ödediğiniz ücretle kıyaslayıp yatırımınızın kaç katını geri aldığınızı görürsünüz.',
  ],
  'mesai': [
    'Mesai Dışı Kazanç',
    'Salonunuz kapalıyken (akşam, gece, kapalı günler) asistanın aldığı randevuların tutarı. Küçük yazı, asistanın bu saatlerde müşterilerinize kaç mesaj yazdığını gösterir.',
    'Randevunun alındığı an, işletme ayarlarınızdaki çalışma saatlerinin dışındaysa tutarı bu karta yazılır. Bu saatlerde gönderilen her cevap da mesaj sayısına eklenir.',
    'Bu müşteriler normalde size ulaşamayıp başka salona gidecekti. Personel yokken kazanılan, tamamen ekstra gelirdir.',
  ],
  'gk': [
    'Geri Kazanılan Müşteri',
    'Fiyat ya da bilgi alıp randevu oluşturmadan giden ("kaçan") müşterilere asistan tekrar yazar; geri dönüp randevu alanların tutarı bu kartta görünür.',
    'Asistan, ayarladığınız süre sonra (varsayılan 24 saat) bu müşterilere mesai saatinde bir kez nazik bir mesaj ve gerçek boş saatlerinizi yollar. Mesajdan sonraki 7 gün içinde alınan randevu "geri kazanılmış" sayılır.',
    'Kaybolacak müşteriyi hiçbir personel emeği olmadan geri getirir. Müşteri "dur" yazarsa bir daha yazılmaz.',
  ],
  'fiyat': [
    'Fiyat Verip Randevu Aldırdığı',
    'Asistanın fiyat söylediği müşterilerden randevu alanların toplam tutarı.',
    'Asistan, sistemde kayıtlı hizmet fiyatlarınızı müşteriye söyler. O sohbette alınan ve iptal edilmeyen randevuların tutarı bu karta yazılır.',
    'Fiyat soran müşteri çoğu zaman cevap gecikince başka salona yazar. Asistan fiyatı anında verip randevuya bağladığı için bu tutar kaçmadan size kalır.',
  ],
  'cozulen': [
    'Asistanın Kendi Bitirdiği Sohbetler',
    'Asistanın baştan sona tek başına ilgilendiği sohbetlerden gelen randevu tutarı. Müşteri ne sorduysa asistan cevapladı; sizin ya da personelinizin araya girmesi gerekmedi. Yüzde, oranı gösterir: %92, 100 müşteriden 92\'siyle hiç uğraşmadınız demektir.',
    'Asistan yalnızca birkaç konuyu size sorar: müşteri "yetkiliyle görüşmek istiyorum" derse, şikâyet / ödeme gibi bir konu açılırsa ya da fiyatı bilinmeyen bir model sorulursa. O zaman size bildirim gelir; asistan bu sırada müşteriyle ilgilenmeye devam eder. Size hiçbir konu sorulmayan sohbetler "kendi bitirdiği" sayılır.',
    'Oran ne kadar yüksekse personeliniz WhatsApp ile o kadar az uğraşır. Oran düşükse fiyatı eksik hizmetleri tamamlayın ve "Öğrenilen Cevaplar" sekmesine bakın.',
  ],
  'gorsel': [
    'Fotoğrafa Fiyat Verildi',
    'Müşterinin WhatsApp\'tan gönderdiği model fotoğrafına asistan fiyat verir; bu sohbetlerden alınan randevuların tutarı bu kartta görünür.',
    'Asistan fotoğraftaki uygulamaları tanır (protez, french, taş sayısı…); fiyatı "Fotoğraftan Fiyat" sekmesindeki kurallarınızdan sistem hesaplar. Asistan fiyat uydurmaz.',
    'Uzmanınızın fotoğrafa bakıp fiyat yazma işini üstlenir; müşteri anında fiyat alır ve randevuya geçer.',
  ],
};

void _bilgiAc(BuildContext context, String anahtar, IconData ikon, Color renk, String deger, String detay, String donem) {
  final k = _kartBilgi[anahtar];
  if (k == null) return;
  Widget bolum(IconData i, String b, String m) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: renk.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(i, size: 17, color: renk),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(b, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(m, style: TextStyle(fontSize: 13.2, height: 1.45, color: Colors.grey.shade800)),
            ]),
          ),
        ]),
      );
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
    builder: (c) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            CircleAvatar(backgroundColor: renk.withValues(alpha: 0.12), child: Icon(ikon, color: renk)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(k[0], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                Text(detay.isEmpty ? deger : '$deger · $detay', style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700)),
              ]),
            ),
          ]),
          const SizedBox(height: 16),
          bolum(Icons.visibility_outlined, 'Ne gösterir?', k[1]),
          bolum(Icons.calculate_outlined, 'Nasıl hesaplanır?', k[2]),
          bolum(Icons.lightbulb_outline, 'Size ne kazandırır?', k[3]),
          Row(children: [
            Expanded(child: WaAlt('Seçili dönem: $donem')),
            FilledButton(onPressed: () => Navigator.pop(c), child: const Text('Anladım')),
          ]),
        ]),
      ),
    ),
  );
}

// ======================================================================== GENEL BAKIŞ
class WaGenelSekme extends StatefulWidget {
  final WaDurum d;
  const WaGenelSekme({super.key, required this.d});
  @override
  State<WaGenelSekme> createState() => _WaGenelSekmeState();
}

class _WaGenelSekmeState extends State<WaGenelSekme> with AutomaticKeepAliveClientMixin {
  WaDurum get d => widget.d;
  String _grafikTur = 'ay';
  Map<String, dynamic>? _grafik;
  List<Map<String, dynamic>>? _son;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _grafikYukle('ay');
    _sonYukle();
    d.sohbetYenile.addListener(_sonYukle);
  }

  @override
  void dispose() {
    d.sohbetYenile.removeListener(_sonYukle);
    super.dispose();
  }

  Future<void> _grafikYukle(String g) async {
    setState(() => _grafikTur = g);
    final r = await WaApi.al(d.sube, '/grafik', {'g': g});
    if (!mounted) return;
    if (okMu(r)) setState(() => _grafik = r);
  }

  Future<void> _sonYukle() async {
    final b = DateTime.now();
    final o = b.subtract(const Duration(days: 6)); // yalnız son 5 konuşma gösteriliyor: 30 günlük liste gereksiz yüktü
    final r = await WaApi.al(d.sube, '/sohbetler', {'baslangic': isoGun(o), 'bitis': isoGun(b)});
    if (!mounted) return;
    setState(() => _son = okMu(r) ? haritaListe(r['liste']).take(5).toList() : []);
  }

  Future<void> _yenile() async {
    await Future.wait([d.ozetYukle(), _grafikYukle(_grafikTur), _sonYukle()]);
  }

  // Tasarımdaki 4 etiket: Randevu Oluşturuldu / Randevu Alındı / Fiyat Verildi / Bilgi Verildi
  String _etiket4(Map<String, dynamic> x) {
    final s = '${x['durum'] ?? ''}';
    if (RegExp(r'Dönüş bekliyor|İşletme').hasMatch(s)) return s;
    if (s == 'Randevu alındı') return 'Randevu Oluşturuldu';
    if (RegExp(r'teyit|değişti').hasMatch(s)) return 'Randevu Alındı';
    return sayiDeger(x['fiyat']) > 0 ? 'Fiyat Verildi' : 'Bilgi Verildi';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return AnimatedBuilder(
      animation: d,
      builder: (context, _) {
        final c = d.ozetCevap;
        return RefreshIndicator(
          onRefresh: _yenile,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 30),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              if (c == null && d.ozetHata == null) const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())),
              if (d.ozetHata != null && c == null) WaBos(d.ozetHata!),
              if (c != null) ..._icerik(context, c),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _icerik(BuildContext context, Map<String, dynamic> c) {
    final scheme = Theme.of(context).colorScheme;
    final o = d.ozet, t = harita(c['trend']), s = harita(c['seri']), p = harita(c['paket']), a = harita(c['asistan']);
    final kz = harita(o['kazanc']), kt = harita(o['kart']), r = harita(o['randevu']), g = harita(o['geri_kazanim']);
    final sh = harita(o['sohbet']), cv = harita(o['cevap']), gr = harita(o['gorsel']);
    final toplamRandevu = sayiDeger(r['adet']) + sayiDeger(g['randevu']);
    final donemAd = waDonemler[d.donem] ?? '';

    Widget heroBolum(IconData i, String e, String deger, Widget trend) => Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(children: [
            Icon(i, color: Colors.white70, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(e, style: const TextStyle(color: Colors.white70, fontSize: 12.5))),
            Text(deger, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
            trend,
          ]),
        );

    final bekleyen = haritaListe(o['aktar_bekleyen']);
    final aiKapali = !(a['acik'] == true) || p['kapali'] == true;

    Widget ozellik(bool acik, String metin, int? sekme) => InkWell(
          onTap: !acik && sekme != null ? () => d.sekmeAc?.call(sekme) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(children: [
              Icon(Icons.check_circle, size: 16, color: acik ? const Color(0xFF16A34A) : Colors.grey.shade400),
              const SizedBox(width: 6),
              Expanded(child: Text(metin, style: TextStyle(fontSize: 13, color: acik ? null : Colors.grey))),
              if (!acik && sekme != null) Text('Aç', style: TextStyle(fontSize: 12, color: scheme.primary, fontWeight: FontWeight.w700)),
            ]),
          ),
        );

    return [
      // Hero
      Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF6D28D9), Color(0xFF9333EA), Color(0xFFC026D3)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.chat, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('WhatsApp üzerinden toplam', style: TextStyle(color: Colors.white70, fontSize: 12.5)),
                Row(children: [
                  Text(sayi(sh['gelen_mesaj']), style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
                  const Text('  mesaj aldınız', style: TextStyle(color: Colors.white, fontSize: 13)),
                  WaTrend(sayiYaDaNull(t['mesaj']), acikZemin: Colors.white.withValues(alpha: 0.2)),
                ]),
              ]),
            ),
          ]),
          const Divider(color: Colors.white24, height: 18),
          heroBolum(Icons.event_available, 'Toplam Randevu', sayi(toplamRandevu), WaTrend(sayiYaDaNull(t['randevu']), acikZemin: Colors.white.withValues(alpha: 0.2))),
          heroBolum(Icons.people_alt, 'Yeni Müşteri', sayi(r['yeni_musteri']), WaTrend(sayiYaDaNull(t['yeni']), acikZemin: Colors.white.withValues(alpha: 0.2))),
          heroBolum(Icons.history, 'Ortalama Yanıt Süresi', sure(cv['medyan_sure_sn']),
              WaTrend(sayiYaDaNull(t['sure']), tersIyi: true, acikZemin: Colors.white.withValues(alpha: 0.2))),
        ]),
      ),

      if (bekleyen.isNotEmpty)
        _UyariSatir(
          renk: const Color(0xFFDC2626),
          ikon: Icons.reply,
          baslik: '${bekleyen.length} müşteri sizden dönüş bekliyor',
          alt: 'Asistan bu konuları size sordu; müşteriyle ilgilenmeye devam ediyor',
          onTap: () => d.sekmeAc?.call(2),
        ),

      _BolumBaslik(Icons.trending_up_rounded, 'Asistanın size kazandırdıkları'),
      _KazancKart(
        renk: const Color(0xFF7C3AED), ikon: Icons.account_balance_wallet, bilgi: 'kazanc', donem: donemAd,
        deger: tl(sayiDeger(kz['gerceklesen']) > 0 ? kz['gerceklesen'] : kz['beklenen']),
        ad: sayiDeger(kz['gerceklesen']) > 0 ? 'Gerçekleşen kazanç' : 'Randevu tutarı',
        detay: kz['kat'] != null ? 'Pakete ödediğinizin ${virgul(kz['kat'])} katı' : (sayiDeger(kz['gerceklesen']) > 0 ? 'salona gelen müşterilerden' : 'gelişler "geldi" işaretlenince kesinleşir'),
        seri: liste(s['tutar']), mesaj: cv['toplam'],
      ),
      _KazancKart(
        renk: const Color(0xFF4F46E5), ikon: Icons.nightlight_round, bilgi: 'mesai', donem: donemAd,
        deger: tl(kz['mesai_disi']), ad: 'Mesai dışı kazanç', detay: '${sayi(r['mesai_disi'])} randevu salon kapalıyken alındı',
        seri: liste(s['mesai_tutar']), mesaj: cv['mesai_disi'],
      ),
      _KazancKart(
        renk: const Color(0xFFF97316), ikon: Icons.autorenew, bilgi: 'gk', donem: donemAd,
        deger: tl(sayiDeger(g['tutar']) > 0 ? g['tutar'] : g['beklenen_tutar']), ad: 'Geri kazanılan müşteri',
        detay: '${sayi(g['randevu'])} kaçan müşteri geri döndü · ${sayi(g['yazildi'])} müşteriye yazıldı',
        seri: liste(s['geri_kazanim']), mesaj: kt['geri_kazanim'] != null ? harita(kt['geri_kazanim'])['mesaj'] : g['yazildi'],
      ),
      _KazancKart(
        renk: const Color(0xFF2563EB), ikon: Icons.sell, bilgi: 'fiyat', donem: donemAd,
        deger: tl(harita(kt['fiyat'])['tutar']), ad: 'Fiyat verip randevu aldırdığı',
        detay: '${sayi(sh['fiyat_aldi'])} müşteriye fiyat verildi, ${sayi(sh['fiyattan_randevu'])} tanesi randevu aldı',
        seri: liste(s['tutar']), mesaj: kt['fiyat'] != null ? harita(kt['fiyat'])['mesaj'] : null,
      ),
      _KazancKart(
        renk: const Color(0xFF16A34A), ikon: Icons.verified_user, bilgi: 'cozulen', donem: donemAd,
        deger: tl(harita(kt['cozulen'])['tutar']), ad: 'Kendi bitirdiği sohbetler',
        detay: sayiDeger(sh['yazisma']) > 0 && sh['cozulen'] != null
            ? '%${sh['cozulen_orani']} · ${sh['yazisma']} sohbetin ${sh['cozulen']} tanesi personele gerek kalmadan bitti'
            : 'personele gerek kalmadan biten sohbetler',
        seri: liste(s['cozulen']), mesaj: kt['cozulen'] != null ? harita(kt['cozulen'])['mesaj'] : null,
      ),
      _KazancKart(
        renk: const Color(0xFFDB2777), ikon: Icons.photo_camera, bilgi: 'gorsel', donem: donemAd,
        deger: tl(harita(kt['gorsel'])['tutar']), ad: 'Fotoğrafa fiyat verildi',
        detay: '${sayi(gr['fiyat_verildi'])} fotoğrafa fiyat verildi, ${sayi(gr['randevu'])} tanesi randevuya döndü',
        seri: liste(s['gorsel']), mesaj: kt['gorsel'] != null ? harita(kt['gorsel'])['mesaj'] : null,
      ),

      const SizedBox(height: 4),
      WaKart(
        baslik: 'Performans Grafiği',
        ikon: Icons.bar_chart_rounded,
        sag: SegmentedButton<String>(
          showSelectedIcon: false,
          style: const ButtonStyle(visualDensity: VisualDensity.compact, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
          segments: const [
            ButtonSegment(value: 'hafta', label: Text('Hafta', style: TextStyle(fontSize: 12))),
            ButtonSegment(value: 'ay', label: Text('Ay', style: TextStyle(fontSize: 12))),
            ButtonSegment(value: 'yil', label: Text('Yıl', style: TextStyle(fontSize: 12))),
          ],
          selected: {_grafikTur},
          onSelectionChanged: (x) => _grafikYukle(x.first),
        ),
        child: _grafik == null
            ? const SizedBox(height: 210, child: Center(child: CircularProgressIndicator()))
            : WaPerformansGrafik(
                etiket: liste(_grafik!['etiket']).map((e) => '$e').toList(),
                randevu: liste(_grafik!['randevu']).map(sayiDeger).toList(),
                mesaj: liste(_grafik!['mesaj']).map(sayiDeger).toList(),
                birim: '${_grafik!['birim'] ?? 'gun'}',
              ),
      ),

      WaKart(
        baslik: 'Son WhatsApp Konuşmaları',
        ikon: Icons.chat,
        ikonRenk: waYesil,
        sag: TextButton(onPressed: () => d.sekmeAc?.call(2), child: const Text('Tümünü Gör')),
        child: _son == null
            ? const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))
            : _son!.isEmpty
                ? const WaBos('Son 30 günde WhatsApp konuşması yok.')
                : Column(
                    children: _son!
                        .map((x) => WaKonusmaSatiri(x: {...x, 'durum': _etiket4(x)}, sube: d.sube, onTap: () => d.sohbetAc?.call(sayiDeger(x['id']).toInt())))
                        .toList()),
      ),

      WaKart(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.smart_toy, color: waMor, size: 30),
            const SizedBox(width: 10),
            const Expanded(child: Text('RandevumCepte AI Asistan', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15))),
            WaHap(a['acik'] == true ? (p['kapali'] == true ? 'Paket doldu' : 'Aktif') : 'Kapalı', sinif: aiKapali ? 'k' : 'y'),
          ]),
          const SizedBox(height: 6),
          const WaAlt('Tüm müşterilerinize akıllı, hızlı ve kişiselleştirilmiş hizmet sunun.'),
          const SizedBox(height: 8),
          ozellik(a['gorsel'] == true, 'Görsel Analiz (Fotoğraf)', 4),
          ozellik(sayiDeger(a['fiyat']) == 1, 'Akıllı Fiyatlandırma', 7),
          ozellik(true, 'Randevu Yönetimi', null),
          ozellik(true, 'Müşteri Desteği', null),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(onPressed: () => d.sekmeAc?.call(7), icon: const Icon(Icons.arrow_forward, size: 18), label: const Text('Ayarları Düzenle')),
          ),
        ]),
      ),
    ];
  }
}

class _BolumBaslik extends StatelessWidget {
  final IconData ikon;
  final String metin;
  const _BolumBaslik(this.ikon, this.metin);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 6, 2, 10),
        child: Row(children: [
          Icon(ikon, size: 18, color: waMor),
          const SizedBox(width: 8),
          Text(metin, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
        ]),
      );
}

class _UyariSatir extends StatelessWidget {
  final Color renk;
  final IconData ikon;
  final String baslik, alt;
  final VoidCallback? onTap;
  const _UyariSatir({required this.renk, required this.ikon, required this.baslik, required this.alt, this.onTap});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: renk.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: renk.withValues(alpha: 0.25))),
              child: Row(children: [
                CircleAvatar(radius: 17, backgroundColor: renk, child: Icon(ikon, color: Colors.white, size: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(baslik, style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(alt, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                  ]),
                ),
                if (onTap != null) Icon(Icons.chevron_right, color: renk),
              ]),
            ),
          ),
        ),
      );
}

class _KazancKart extends StatelessWidget {
  final Color renk;
  final IconData ikon;
  final String bilgi, donem, deger, ad, detay;
  final List<dynamic> seri;
  final dynamic mesaj;
  const _KazancKart({required this.renk, required this.ikon, required this.bilgi, required this.donem, required this.deger, required this.ad, required this.detay, required this.seri, this.mesaj});

  @override
  Widget build(BuildContext context) {
    final mesajYazi = mesaj != null ? '${sayi(mesaj)} mesaj yazıldı' : '';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: renk, width: 4)),
        boxShadow: [BoxShadow(color: renk.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(color: renk.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(ikon, color: renk, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(deger, style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: renk)),
              Text(ad, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
              if (mesajYazi.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(children: [
                    Icon(Icons.chat_bubble_outline, size: 13, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(mesajYazi, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ]),
                ),
              if (detay.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 2), child: WaAlt(detay)),
            ]),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.info_outline, color: Colors.grey.shade500, size: 20),
            onPressed: () => _bilgiAc(context, bilgi, ikon, renk, deger, [mesajYazi, detay].where((e) => e.isNotEmpty).join(' · '), donem),
          ),
        ]),
        Padding(padding: const EdgeInsets.only(right: 8, top: 4), child: WaSpark(seri, renk, yukseklik: 32)),
      ]),
    );
  }
}

/// Sohbet satırı (Genel Bakış son konuşmalar + Sohbetler listesi)
class WaKonusmaSatiri extends StatelessWidget {
  final Map<String, dynamic> x;
  final String sube;
  final VoidCallback onTap;
  const WaKonusmaSatiri({super.key, required this.x, required this.sube, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ad = '${x['ad'] ?? ''}'.trim().isNotEmpty ? '${x['ad']}' : ('${x['telefon'] ?? ''}'.isNotEmpty ? '${x['telefon']}' : 'Müşteri');
    final mesaj = '${x['son_mesaj'] ?? '…'}'.replaceFirst(RegExp(r'^\[fotoğraf\]\s*'), '');
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          WaAvatar(ad: ad, id: sayiDeger(x['id']).toInt(), foto: x['foto']?.toString(), sube: sube),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(ad, style: const TextStyle(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis)),
                Text(saatYaDaGun(x['tarih']), style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
              ]),
              const SizedBox(height: 2),
              Row(children: [
                if (sayiDeger(x['gorsel']) > 0) Padding(padding: const EdgeInsets.only(right: 4), child: Icon(Icons.photo_camera, size: 14, color: Colors.grey.shade600)),
                Expanded(child: Text(mesaj.isEmpty ? '…' : mesaj, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: Colors.grey.shade700))),
              ]),
              const SizedBox(height: 5),
              WaHap('${x['durum'] ?? ''}'),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ======================================================================== KAZANDIRDIKLARI
class WaKazandirdiklariSekme extends StatelessWidget {
  final WaDurum d;
  const WaKazandirdiklariSekme({super.key, required this.d});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: d,
      builder: (context, _) {
        final c = d.ozetCevap;
        return RefreshIndicator(
          onRefresh: d.ozetYukle,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 30),
            physics: const AlwaysScrollableScrollPhysics(),
            children: c == null
                ? [d.ozetHata != null ? WaBos(d.ozetHata!) : const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))]
                : _icerik(context, d.ozet, harita(c['paket'])),
          ),
        );
      },
    );
  }

  List<Widget> _icerik(BuildContext context, Map<String, dynamic> o, Map<String, dynamic> p) {
    final kz = harita(o['kazanc']), r = harita(o['randevu']), g = harita(o['geri_kazanim']), c = harita(o['cevap']), s = harita(o['sohbet']);
    final gercek = sayiDeger(kz['gerceklesen']) > 0;
    final toplam = gercek ? sayiDeger(kz['gerceklesen']) : sayiDeger(kz['beklenen']);
    final paketVar = p['var'] == true;
    final w = <Widget>[];

    // 1) Hero
    Widget cam(IconData i, String d, String e) => Expanded(
          child: Container(
            margin: const EdgeInsets.all(4),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.13), borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(i, color: Colors.white70, size: 18),
              const SizedBox(height: 4),
              Text(d, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
              Text(e, style: const TextStyle(color: Colors.white70, fontSize: 11.2)),
            ]),
          ),
        );
    final paketUcret = sayiDeger(kz['paket_ucret']);
    w.add(Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF4C1D95), Color(0xFF7C3AED), Color(0xFFC026D3)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.emoji_events, color: Color(0xFFFDE68A), size: 18),
          SizedBox(width: 6),
          Text('Bu dönem asistanın size kazandırdığı', style: TextStyle(color: Colors.white70, fontSize: 12.5)),
        ]),
        const SizedBox(height: 6),
        Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, children: [
          Text(tl(toplam), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
          if (kz['kat'] != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: const Color(0xFFFDE68A), borderRadius: BorderRadius.circular(12)),
              child: Text('${virgul(kz['kat'])} kat', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF78350F), fontSize: 12)),
            ),
        ]),
        const SizedBox(height: 4),
        Text(
          toplam > 0
              ? (gercek
                  ? 'Asistanın aldığı randevulardan salona gelen müşterilerin hizmet tutarı.'
                  : 'Asistanın aldığı ${sayi(sayiDeger(r['adet']) + sayiDeger(g['randevu']))} randevunun hizmet tutarı. Müşteri gelip randevu "geldi" işaretlenince kesinleşir.')
              : 'Henüz asistanın aldığı bir randevu yok. Müşteriler WhatsApp\'tan yazıp randevu aldıkça tutar burada birikir.',
          style: const TextStyle(color: Colors.white, fontSize: 12.8, height: 1.4),
        ),
        if (paketUcret > 0) ...[
          const SizedBox(height: 10),
          _roiSatir('Pakete ödediğiniz', paketUcret, [paketUcret, toplam].reduce((a, b) => a > b ? a : b), Colors.white54),
          _roiSatir('Asistanın getirdiği', toplam, [paketUcret, toplam].reduce((a, b) => a > b ? a : b), const Color(0xFFFDE68A)),
        ],
        const SizedBox(height: 10),
        Row(children: [
          cam(Icons.hourglass_bottom, '${virgul(c['personel_saat'] ?? 0)} saat', 'personelinizin telefona harcamadığı zaman'),
          cam(Icons.nightlight_round, '${sayi(c['mesai_disi'])} mesaj', 'salon kapalıyken cevaplandı'),
        ]),
        Row(children: [
          cam(Icons.bolt, sure(c['medyan_sure_sn']), 'müşteriye ortalama cevap süresi'),
          cam(Icons.forum, '${sayi(c['toplam'])} mesaj', 'asistan yazdı · ${sayi(c['ucretsiz'])} tanesi ücretsiz'),
        ]),
      ]),
    ));

    // 2) Sizden beklenenler
    final bekleyen = haritaListe(o['aktar_bekleyen']), kacan = haritaListe(o['kacan']);
    final yap = <Widget>[
      if (bekleyen.isNotEmpty)
        _UyariSatir(renk: const Color(0xFFDC2626), ikon: Icons.reply, baslik: '${bekleyen.length} müşteri sizden dönüş bekliyor',
            alt: 'Asistan bu konuları size sordu; müşteriyle ilgilenmeye devam ediyor', onTap: () => d.sekmeAc?.call(2)),
      if (kacan.isNotEmpty)
        _UyariSatir(renk: const Color(0xFFF97316), ikon: Icons.person_remove, baslik: '${kacan.length} müşteri bilgi alıp randevu almadı',
            alt: 'Asistan bu müşterilere tekrar yazabilir', onTap: () => d.sekmeAc?.call(3)),
      if (paketVar && p['seviye'] != null && p['seviye'] != false && '${p['seviye']}' != '0')
        _UyariSatir(
            renk: p['kapali'] == true ? const Color(0xFFDC2626) : waMor,
            ikon: Icons.inventory_2,
            baslik: p['kapali'] == true ? 'Paket doldu' : 'Paketin %${p['yuzde']}\'i kullanıldı',
            alt: p['kapali'] == true ? 'Asistan ay sonuna kadar cevap vermiyor' : 'Kalan ${sayi(p['kalan'])} yapay zekâ mesajı'),
    ];
    if (yap.isNotEmpty) {
      w.add(const _BolumBaslik(Icons.notifications_active, 'Sizden beklenenler'));
      w.addAll(yap);
    }

    // 3) Kazanç nereden geldi + müşteri yolculuğu
    final parca = <(String, double, Color, String)>[
      ('Mesai içinde alınan randevular', (sayiDeger(r['tutar']) - sayiDeger(r['mesai_disi_tutar'])).clamp(0, double.infinity).toDouble(), const Color(0xFF7C3AED),
          '${sayi(sayiDeger(r['adet']) - sayiDeger(r['mesai_disi']))} randevu'),
      ('Salon kapalıyken alınanlar', sayiDeger(r['mesai_disi_tutar']).toDouble(), const Color(0xFF4F46E5), '${sayi(r['mesai_disi'])} randevu · akşam, gece, tatil'),
      ('Geri kazanılan müşteriler', sayiDeger(g['beklenen_tutar']).toDouble(), const Color(0xFFF97316), '${sayi(g['randevu'])} müşteri geri döndü'),
    ];
    final top = parca.fold<double>(0, (a, x) => a + x.$2);
    w.add(WaKart(
      baslik: 'Kazanç nereden geldi?',
      ikon: Icons.pie_chart,
      child: top > 0
          ? Column(children: [
              WaDonut(parcalar: parca.map((x) => (x.$2, x.$3)).toList(), ortaD: top >= 100000 ? '${sayi(top / 1000)} bin' : sayi(top), ortaE: 'TL toplam'),
              const SizedBox(height: 12),
              ...parca.map((x) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(children: [
                      Container(width: 10, height: 10, decoration: BoxDecoration(color: x.$3, borderRadius: BorderRadius.circular(3))),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(x.$1, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          WaAlt(x.$4),
                        ]),
                      ),
                      Text('${tl(x.$2)}  %${(x.$2 / top * 100).round()}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                    ]),
                  )),
              const SizedBox(height: 6),
              const WaAlt('Tutarlar asistanın aldığı randevuların hizmet fiyatlarından hesaplanır; iptal edilen randevular sayılmaz.'),
            ])
          : const WaBos('Henüz tutar yok. Asistan randevu aldıkça kazancın nereden geldiği burada görünür. Hizmetlerinize fiyat girili değilse tutar 0 görünür; hizmet fiyatlarınızı kontrol edin.'),
    ));

    final hu = harita(o['huni']);
    final yazdi = sayiDeger(hu['yazdi']);
    final adim = <(IconData, String, num, Color)>[
      (Icons.chat, 'Yazdı', yazdi, const Color(0xFF6D28D9)),
      (Icons.info, 'Bilgi / fiyat aldı', sayiDeger(hu['bilgi']), const Color(0xFF9333EA)),
      (Icons.event_available, 'Randevu aldı', sayiDeger(hu['randevu']), const Color(0xFFC026D3)),
      (Icons.storefront, 'Salona geldi', sayiDeger(hu['geldi']), const Color(0xFF16A34A)),
    ];
    w.add(WaKart(
      baslik: 'Müşteri yolculuğu',
      ikon: Icons.filter_alt,
      ikonRenk: const Color(0xFFC026D3),
      child: yazdi > 0
          ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              for (var i = 0; i < adim.length; i++) ...[
                if (i > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Text(
                        '↓ %${adim[i - 1].$3 > 0 ? (adim[i].$3 / adim[i - 1].$3 * 100).round() : 0} devam etti',
                        style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
                  ),
                FractionallySizedBox(
                  widthFactor: (adim[i].$3 / (yazdi == 0 ? 1 : yazdi)).clamp(0.42, 1).toDouble(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(color: adim[i].$4, borderRadius: BorderRadius.circular(10)),
                    child: Row(children: [
                      Icon(adim[i].$1, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Expanded(child: Text(adim[i].$2, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12.5), overflow: TextOverflow.ellipsis)),
                      Text(sayi(adim[i].$3), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                    ]),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              WaAlt('"Salona geldi", panelde randevu "geldi" işaretlendikçe artar.${sayiDeger(hu['randevu']) > 0 && sayiDeger(hu['geldi']) == 0 ? ' Randevuları "geldi" işaretlerseniz gerçekleşen kazancınız da görünür.' : ''}'),
            ])
          : const WaBos('Bu dönemde henüz WhatsApp\'tan yazan müşteri yok.'),
    ));

    // 4) Paket + memnuniyet + asistanın yaptıkları
    Widget satir(String a, String b, {Color? renk}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(children: [Expanded(child: Text(a, style: TextStyle(color: Colors.grey.shade700, fontSize: 13))), Text(b, style: TextStyle(fontWeight: FontWeight.w700, color: renk))]),
        );
    if (paketVar) {
      final pr = p['kapali'] == true ? const Color(0xFFDC2626) : (p['seviye'] != null && '${p['seviye']}' != '0' && p['seviye'] != false ? const Color(0xFFF59E0B) : waMor);
      w.add(WaKart(
        baslik: 'Paket kullanımı',
        ikon: Icons.inventory_2,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            WaHalka(yuzde: sayiDeger(p['yuzde']), renk: pr, ic: '%${p['yuzde']}', alt: 'kullanıldı', boyut: 100),
            const SizedBox(width: 14),
            Expanded(
              child: Column(children: [
                satir('Yapay zekâ mesajı', '${sayi(p['kullanilan'])} / ${sayi(p['dahil'])}'),
                satir('Kalan', sayi(p['kalan'])),
                satir('Ücretsiz cevap', sayi(c['ucretsiz']), renk: const Color(0xFF16A34A)),
              ]),
            ),
          ]),
          const SizedBox(height: 8),
          WaAlt('Hazır cevaplar ve öğrenilen cevaplar paketten düşmez; yalnızca yapay zekânın yazdığı mesajlar sayılır.${p['kapali'] == true ? ' Paket doldu, asistan ay sonuna kadar cevap vermiyor.' : ''}'),
        ]),
      ));
    } else {
      final ct = sayiDeger(c['toplam']);
      final uo = ct > 0 ? (sayiDeger(c['ucretsiz']) / ct * 100).round() : 0;
      w.add(WaKart(
        baslik: 'Cevap dağılımı',
        ikon: Icons.inventory_2,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            WaHalka(yuzde: uo, renk: const Color(0xFF16A34A), ic: '%$uo', alt: 'ücretsiz', boyut: 100),
            const SizedBox(width: 14),
            Expanded(
              child: Column(children: [
                satir('Toplam cevap', sayi(c['toplam'])),
                satir('Ücretsiz cevap', sayi(c['ucretsiz']), renk: const Color(0xFF16A34A)),
                satir('Yapay zekâ', sayi(c['ai'])),
              ]),
            ),
          ]),
          const SizedBox(height: 8),
          const WaAlt('Hazır ve öğrenilen cevaplar ücretsizdir. Bu işletme için mesaj paketi tanımlı değil.'),
        ]),
      ));
    }

    final memnun = sayiDeger(s['memnun']), degil = sayiDeger(s['memnun_degil']), mt = memnun + degil;
    w.add(WaKart(
      baslik: 'Müşteri memnuniyeti',
      ikon: Icons.sentiment_very_satisfied,
      ikonRenk: const Color(0xFF16A34A),
      child: mt > 0
          ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                Text('%${s['memnuniyet_orani']}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF16A34A))),
                const SizedBox(width: 6),
                const Text('memnun kaldı'),
              ]),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Row(children: [
                  Expanded(flex: (memnun * 100).round().clamp(1, 1 << 30), child: Container(height: 10, color: const Color(0xFF22C55E))),
                  if (degil > 0) Expanded(flex: (degil * 100).round(), child: Container(height: 10, color: const Color(0xFFF87171))),
                ]),
              ),
              const SizedBox(height: 6),
              satir('😊 Memnun', '${sayi(memnun)} müşteri'),
              satir('🙁 Memnun değil', '${sayi(degil)} müşteri'),
              const WaAlt('Asistan randevudan sonra müşteriye "memnun kaldınız mı?" diye sorar.'),
            ])
          : const WaBos('Henüz cevap yok. Asistan randevudan sonra müşteriye "memnun kaldınız mı?" diye sorar; gelen cevaplar burada görünür. Ayarlar sekmesinden memnuniyet sorusunun açık olduğunu kontrol edin.'),
    ));

    final isler = <(IconData, Color, num, String)>[
      (Icons.event_available, const Color(0xFF7C3AED), sayiDeger(r['adet']) + sayiDeger(g['randevu']), 'randevu oluşturdu'),
      (Icons.swap_horiz, const Color(0xFF2563EB), sayiDeger(r['guncelle']), 'randevu değiştirdi'),
      (Icons.done_all, const Color(0xFF16A34A), sayiDeger(r['teyit']), 'randevu teyidi aldı'),
      (Icons.cancel, const Color(0xFFDC2626), sayiDeger(r['iptal_islem']), 'iptal isteğini işledi'),
      (Icons.sell, const Color(0xFFF97316), sayiDeger(s['fiyat_aldi']), 'müşteriye fiyat verdi'),
      (Icons.photo_camera, const Color(0xFFDB2777), sayiDeger(harita(o['gorsel'])['toplam']), 'fotoğraf inceledi'),
    ];
    w.add(WaKart(
      baslik: 'Asistan neler yaptı?',
      ikon: Icons.smart_toy,
      ikonRenk: const Color(0xFF2563EB),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 2.6,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        children: isler
            .map((x) => Row(children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(color: x.$2.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                    child: Icon(x.$1, color: x.$2, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(sayi(x.$3), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      Text(x.$4, style: TextStyle(fontSize: 11.2, color: Colors.grey.shade700), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ]),
                  ),
                ]))
            .toList(),
      ),
    ));

    // 5) Ne soruyor + ne zaman yazıyor
    final hz = harita(o['populer_hizmet']);
    final hk = hz.keys.toList();
    final hmax = hk.isEmpty ? 1 : sayiDeger(hz[hk.first]).clamp(1, double.infinity);
    w.add(WaKart(
      baslik: 'Müşteriler en çok neyi soruyor?',
      ikon: Icons.auto_awesome,
      ikonRenk: const Color(0xFFEC4899),
      child: hk.isEmpty
          ? const WaBos('Henüz hizmet sorusu yok. Müşteriler bir hizmet hakkında yazdıkça en çok sorulanlar burada sıralanır.')
          : Column(
              children: [
                for (var i = 0; i < hk.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(children: [
                      SizedBox(
                        width: 24,
                        child: i == 0 ? const Icon(Icons.emoji_events, size: 18, color: Color(0xFFF59E0B)) : Text('${i + 1}', style: const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(hk[i], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          WaCubuk(sayiDeger(hz[hk[i]]) / hmax, const Color(0xFFEC4899)),
                        ]),
                      ),
                      const SizedBox(width: 10),
                      Text('${sayi(hz[hk[i]])} sohbet', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                    ]),
                  ),
              ],
            ),
    ));

    final sd = liste(o['saat_dagilim']).map(sayiDeger).toList();
    final ys = o['yogun_saat'];
    final tepe = ys is Map ? ys.keys.map((k) => int.tryParse('$k') ?? -1).toSet() : (ys is List ? List.generate(ys.length, (i) => i).toSet() : <int>{});
    final smx = sd.isEmpty ? 1 : sd.reduce((a, b) => a > b ? a : b).clamp(1, double.infinity);
    w.add(WaKart(
      baslik: 'Müşteriler ne zaman yazıyor?',
      ikon: Icons.schedule,
      ikonRenk: const Color(0xFF4F46E5),
      child: sd.isNotEmpty && sd.any((x) => x > 0)
          ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(
                height: 110,
                child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  for (var h = 0; h < sd.length; h++)
                    Expanded(
                      child: Tooltip(
                        message: '${h.toString().padLeft(2, '0')}:00 · ${sayi(sd[h])} mesaj',
                        child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                          if (tepe.contains(h) && sd[h] > 0) Text(sayi(sd[h]), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700)),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            height: (sd[h] / smx * 90).clamp(2, 90).toDouble(),
                            decoration: BoxDecoration(
                              color: tepe.contains(h) && sd[h] > 0 ? const Color(0xFFC026D3) : ((h < 9 || h >= 21) ? const Color(0xFF4F46E5) : const Color(0xFFC4B5FD)),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ]),
                      ),
                    ),
                ]),
              ),
              Row(children: [
                for (var h = 0; h < sd.length; h++)
                  Expanded(child: Text(h % 6 == 0 ? h.toString().padLeft(2, '0') : '', style: TextStyle(fontSize: 9.5, color: Colors.grey.shade600), overflow: TextOverflow.visible, softWrap: false)),
              ]),
              const SizedBox(height: 8),
              Wrap(spacing: 12, runSpacing: 4, children: const [
                _Lejant(Color(0xFFC4B5FD), 'Gündüz'),
                _Lejant(Color(0xFF4F46E5), 'Akşam / gece (21:00–09:00)'),
                _Lejant(Color(0xFFC026D3), 'En yoğun 3 saat'),
              ]),
            ])
          : const WaBos('Henüz mesaj yok. Asistan cevap verdikçe müşterilerin günün hangi saatinde yazdığı burada görünür.'),
    ));
    return w;
  }

  Widget _roiSatir(String ad, num deger, num mx, Color renk) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          SizedBox(width: 120, child: Text(ad, style: const TextStyle(color: Colors.white70, fontSize: 12))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Stack(children: [
                Container(height: 8, color: Colors.white12),
                FractionallySizedBox(widthFactor: (mx > 0 ? deger / mx : 0).clamp(0.02, 1).toDouble(), child: Container(height: 8, color: renk)),
              ]),
            ),
          ),
          const SizedBox(width: 8),
          Text(tl(deger), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5)),
        ]),
      );
}

class _Lejant extends StatelessWidget {
  final Color renk;
  final String metin;
  const _Lejant(this.renk, this.metin);
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: renk, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 4),
        Text(metin, style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700)),
      ]);
}

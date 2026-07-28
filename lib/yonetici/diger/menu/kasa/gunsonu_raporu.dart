import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:randevu_sistem/Backend/backend.dart';

/// GÜN SONU RAPORU (mobil) — web'deki ile ayni:
/// odeme yontemine gore gelir/masraf/net, islem/musteri sayisi, ort sepet,
/// personel ciro, en cok satan hizmet/urun, Tam Detay (saglama) ve PDF indirme.
class GunSonuRaporu extends StatefulWidget {
  final dynamic isletmebilgi;
  const GunSonuRaporu({Key? key, required this.isletmebilgi}) : super(key: key);

  @override
  State<GunSonuRaporu> createState() => _GunSonuRaporuState();
}

class _GunSonuRaporuState extends State<GunSonuRaporu> {
  final NumberFormat _nf = NumberFormat('#,##0.00', 'tr_TR');

  String? _salonId;
  String _period = 'Bugün';
  DateTimeRange? _ozelAralik;
  bool _detay = false;
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _r;

  static const List<String> _periodlar = ['Bugün', 'Dün', 'Bu ay', 'Geçen ay', 'Özel'];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _salonId = await secilisalonid();
    await _fetch();
  }

  // Backend'e gonderilecek donem dizesi
  String _periodParam() {
    if (_period == 'Özel' && _ozelAralik != null) {
      final f = DateFormat('yyyy-MM-dd');
      return '${f.format(_ozelAralik!.start)} / ${f.format(_ozelAralik!.end)}';
    }
    return _period;
  }

  Future<void> _fetch() async {
    if (_salonId == null) return;
    setState(() => _loading = true);
    try {
      final data = await gunSonuRaporu(_salonId!, _periodParam());
      setState(() {
        _r = data;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // --- yardimcilar ---
  double _d(dynamic v) => v == null ? 0 : (double.tryParse(v.toString()) ?? 0);
  String _para(dynamic v) => '${_nf.format(_d(v))} ₺';
  String _tarihEtiket() {
    final b = _r?['baslangic']?.toString() ?? '';
    final s = _r?['bitis']?.toString() ?? '';
    String fmt(String iso) {
      final p = iso.split('-');
      return p.length == 3 ? '${p[2]}.${p[1]}.${p[0]}' : iso;
    }
    if (b.isEmpty) return '';
    return b == s ? fmt(b) : '${fmt(b)} → ${fmt(s)}';
  }

  Future<void> _ozelSec() async {
    final now = DateTime.now();
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2015),
      lastDate: now,
      initialDateRange: _ozelAralik ?? DateTimeRange(start: now, end: now),
      locale: const Locale('tr', 'TR'),
    );
    if (r != null) {
      setState(() {
        _ozelAralik = r;
        _period = 'Özel';
      });
      _fetch();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Color.alphaBlend(scheme.primary.withValues(alpha: 0.32), Colors.white),
            Color.alphaBlend(scheme.tertiary.withValues(alpha: 0.06), Colors.white),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: scheme.onSurface),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Gün Sonu Raporu',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: scheme.onSurface),
          ),
          actions: [
            IconButton(
              tooltip: 'PDF indir',
              icon: Icon(Icons.picture_as_pdf_rounded, color: scheme.primary),
              onPressed: (_r == null) ? null : _pdfAc,
            ),
            const SizedBox(width: 6),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _hataKutu()
                : RefreshIndicator(
                    onRefresh: _fetch,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _donemSecici(scheme),
                          const SizedBox(height: 12),
                          _ozetToggle(scheme),
                          const SizedBox(height: 14),
                          if (_detay) ..._detayIcerik(scheme) else ..._ozetIcerik(scheme),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _hataKutu() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Rapor yüklenemedi.\n$_error', textAlign: TextAlign.center),
        ),
      );

  // --- donem secici (chip'ler) ---
  Widget _donemSecici(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: _kutuDeko(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event_note_rounded, size: 16, color: scheme.primary),
              const SizedBox(width: 6),
              Text('Dönem', style: TextStyle(fontWeight: FontWeight.w700, color: scheme.onSurface, fontSize: 13)),
              const Spacer(),
              Text(_tarihEtiket(), style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _periodlar.map((p) {
              final sel = _period == p;
              return ChoiceChip(
                label: Text(p),
                selected: sel,
                onSelected: (_) {
                  if (p == 'Özel') {
                    _ozelSec();
                  } else {
                    setState(() => _period = p);
                    _fetch();
                  }
                },
                selectedColor: scheme.primary,
                labelStyle: TextStyle(
                  color: sel ? Colors.white : Colors.black87,
                  fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12.5,
                ),
                backgroundColor: Colors.grey.shade100,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // --- Özet <-> Tam Detay segmenti ---
  Widget _ozetToggle(ColorScheme scheme) {
    Widget seg(String t, bool aktif, VoidCallback onTap) => Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: aktif ? scheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                t,
                style: TextStyle(
                  color: aktif ? Colors.white : Colors.black54,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        );
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: _kutuDeko(),
      child: Row(
        children: [
          seg('Özet', !_detay, () => setState(() => _detay = false)),
          seg('Tam Detay', _detay, () => setState(() => _detay = true)),
        ],
      ),
    );
  }

  // ============ ÖZET ============
  List<Widget> _ozetIcerik(ColorScheme scheme) {
    final net = _d(_r?['net_toplam']);
    return [
      Row(
        children: [
          Expanded(child: _ozetKart('Gelirler', _para(_r?['gelir_toplam']), const Color(0xFF0EA5B7))),
          const SizedBox(width: 10),
          Expanded(child: _ozetKart('Masraflar', _para(_r?['masraf_toplam']), const Color(0xFFDC2626))),
        ],
      ),
      const SizedBox(height: 10),
      _ozetKart('Net (Gelir − Masraf)', _para(net), net < 0 ? const Color(0xFFDC2626) : const Color(0xFF15803D), buyuk: true),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(child: _miniStat('${_r?['islem_say'] ?? 0}', 'İşlem')),
          const SizedBox(width: 8),
          Expanded(child: _miniStat('${_r?['musteri_say'] ?? 0}', 'Müşteri')),
          const SizedBox(width: 8),
          Expanded(child: _miniStat(_para(_r?['ort_sepet']), 'Ort. Sepet')),
        ],
      ),
      const SizedBox(height: 14),
      _odemeTablosu(scheme),
      const SizedBox(height: 14),
      _personelCiro(scheme),
      const SizedBox(height: 14),
      _topListe(scheme, 'En Çok Satan Hizmet', _r?['top_hizmet'], 'hizmet_adi', Icons.content_cut_rounded),
      const SizedBox(height: 14),
      _topListe(scheme, 'En Çok Satan Ürün', _r?['top_urun'], 'urun_adi', Icons.shopping_bag_rounded),
    ];
  }

  Widget _ozetKart(String baslik, String deger, Color renk, {bool buyuk = false}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _kutuDeko(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(baslik, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.black45)),
          const SizedBox(height: 6),
          Text(deger, style: TextStyle(fontSize: buyuk ? 24 : 18, fontWeight: FontWeight.w800, color: renk)),
        ],
      ),
    );
  }

  Widget _miniStat(String n, String t) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: _kutuDeko(),
      child: Column(
        children: [
          Text(n, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF3B0764))),
          const SizedBox(height: 2),
          Text(t, style: const TextStyle(fontSize: 11.5, color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _odemeTablosu(ColorScheme scheme) {
    final gelir = (_r?['gelir'] ?? {}) as Map;
    final masraf = (_r?['masraf'] ?? {}) as Map;
    final net = (_r?['net'] ?? {}) as Map;
    const yontemler = [
      ['nakit', 'Nakit'],
      ['kredikarti', 'Kredi Kartı'],
      ['havale', 'Havale'],
      ['online', 'Online'],
      ['diger', 'Diğer'],
    ];
    Widget satir(String ad, dynamic g, dynamic m, dynamic n, {bool kalin = false}) {
      final nv = _d(n);
      final st = TextStyle(fontWeight: kalin ? FontWeight.w800 : FontWeight.w500, fontSize: 12.5);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        child: Row(
          children: [
            Expanded(flex: 3, child: Text(ad, style: st)),
            Expanded(flex: 3, child: Text(_nf.format(_d(g)), textAlign: TextAlign.right, style: st)),
            Expanded(flex: 3, child: Text(_nf.format(_d(m)), textAlign: TextAlign.right, style: st)),
            Expanded(
              flex: 3,
              child: Text(_nf.format(nv),
                  textAlign: TextAlign.right,
                  style: st.copyWith(color: nv < 0 ? const Color(0xFFDC2626) : const Color(0xFF15803D), fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: _kutuDeko(),
      child: Column(
        children: [
          _baslik(scheme, Icons.account_balance_wallet_rounded, 'Ödeme Yöntemine Göre'),
          Container(
            color: const Color(0xFFF5EEFE),
            padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 12),
            child: Row(
              children: const [
                Expanded(flex: 3, child: Text('Yöntem', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF5C008E)))),
                Expanded(flex: 3, child: Text('Gelir', textAlign: TextAlign.right, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF5C008E)))),
                Expanded(flex: 3, child: Text('Masraf', textAlign: TextAlign.right, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF5C008E)))),
                Expanded(flex: 3, child: Text('Net', textAlign: TextAlign.right, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF5C008E)))),
              ],
            ),
          ),
          for (final y in yontemler) satir(y[1], gelir[y[0]], masraf[y[0]], net[y[0]]),
          const Divider(height: 1),
          satir('Toplam', _r?['gelir_toplam'], _r?['masraf_toplam'], _r?['net_toplam'], kalin: true),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _personelCiro(ColorScheme scheme) {
    final list = (_r?['personeller'] ?? []) as List;
    return Container(
      decoration: _kutuDeko(),
      child: Column(
        children: [
          _baslik(scheme, Icons.groups_rounded, 'Personel Bazlı Ciro'),
          if (list.isEmpty)
            const Padding(padding: EdgeInsets.all(14), child: Text('Bu dönemde personel işlemi bulunamadı.', style: TextStyle(color: Colors.black45, fontSize: 12.5)))
          else
            for (final p in list)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 12),
                child: Row(
                  children: [
                    Expanded(child: Text(p['personel_adi']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5))),
                    Text('${p['adet'] ?? 0} işlem', style: const TextStyle(fontSize: 11.5, color: Colors.black45)),
                    const SizedBox(width: 12),
                    Text(_para(p['ciro']), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: Color(0xFF5C008E))),
                  ],
                ),
              ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _topListe(ColorScheme scheme, String baslik, dynamic rows, String adKey, IconData icon) {
    final list = (rows ?? []) as List;
    return Container(
      decoration: _kutuDeko(),
      child: Column(
        children: [
          _baslik(scheme, icon, baslik),
          if (list.isEmpty)
            const Padding(padding: EdgeInsets.all(14), child: Text('Kayıt yok.', style: TextStyle(color: Colors.black45, fontSize: 12.5)))
          else
            for (final r in list)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 12),
                child: Row(
                  children: [
                    Expanded(child: Text(r[adKey]?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5))),
                    Text('${r['adet'] ?? 0} adet', style: const TextStyle(fontSize: 11.5, color: Colors.black45)),
                    const SizedBox(width: 12),
                    Text(_para(r['ciro']), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: Color(0xFF5C008E))),
                  ],
                ),
              ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  // ============ TAM DETAY (SAĞLAMA) ============
  List<Widget> _detayIcerik(ColorScheme scheme) {
    final satislar = (_r?['satislar'] ?? []) as List;
    final ims = (_r?['isletme_masraflari'] ?? []) as List;
    final pgs = (_r?['personel_giderleri'] ?? []) as List;
    final net = _d(_r?['net_toplam']);
    return [
      // Satislar
      _detayKart(scheme, Icons.shopping_cart_rounded, 'Satışlar (Gelirler)', 'Satışlar Toplamı', _para(_r?['gelir_toplam']),
          satislar.isEmpty
              ? [_bosSatir('Bu dönemde satış yok.')]
              : satislar
                  .map<Widget>((s) => _kalem(
                        sol: '${s['saat'] ?? ''}  ${s['musteri'] ?? ''}',
                        alt: (s['tahsil_eden']?.toString().isNotEmpty ?? false) ? 'Tahsil: ${s['tahsil_eden']} · ${s['yontem'] ?? ''}' : (s['yontem']?.toString() ?? ''),
                        sag: _para(s['tutar']),
                        etiket: (s['para_girisi'] == true) ? 'Para Girişi' : null,
                        etiketRenk: const Color(0xFF0EA5B7),
                      ))
                  .toList()),
      const SizedBox(height: 14),
      // Isletme masraflari
      _detayKart(scheme, Icons.arrow_downward_rounded, 'İşletme Masrafları', 'İşletme Masrafları Toplamı', _para(_r?['isletme_masraf_toplam']),
          ims.isEmpty
              ? [_bosSatir('İşletme masrafı yok.')]
              : ims
                  .map<Widget>((m) => _kalem(
                        sol: (m['aciklama']?.toString().isNotEmpty ?? false) ? m['aciklama'].toString() : '-',
                        alt: '${m['harcayan'] ?? ''} · ${m['yontem'] ?? ''}',
                        sag: _para(m['tutar']),
                      ))
                  .toList()),
      const SizedBox(height: 14),
      // Personel giderleri
      _detayKart(scheme, Icons.person_rounded, 'Personel Giderleri & Ödemeleri', 'Personel Giderleri Toplamı', _para(_r?['personel_gider_toplam']),
          pgs.isEmpty
              ? [_bosSatir('Personel gideri/ödemesi yok.')]
              : pgs
                  .map<Widget>((m) => _kalem(
                        sol: '${m['harcayan'] ?? ''}',
                        alt: (m['aciklama']?.toString().isNotEmpty ?? false) ? m['aciklama'].toString() : '-',
                        sag: _para(m['tutar']),
                        etiket: m['tip']?.toString(),
                        etiketRenk: (m['tip'] == 'Personel Gideri') ? const Color(0xFFF59E0B) : const Color(0xFF6366F1),
                      ))
                  .toList()),
      const SizedBox(height: 16),
      // Saglama
      Container(
        padding: const EdgeInsets.all(16),
        decoration: _kutuDeko(),
        child: Column(
          children: [
            _saglamaSatir('Satışlar', _para(_r?['gelir_toplam'])),
            _saglamaSatir('− İşletme Masrafları', _para(_r?['isletme_masraf_toplam'])),
            _saglamaSatir('− Personel Giderleri', _para(_r?['personel_gider_toplam'])),
            const Divider(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('= NET (Kasa)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                Text(_para(net), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: net < 0 ? const Color(0xFFDC2626) : const Color(0xFF15803D))),
              ],
            ),
          ],
        ),
      ),
    ];
  }

  Widget _detayKart(ColorScheme scheme, IconData icon, String baslik, String toplamAd, String toplam, List<Widget> satirlar) {
    return Container(
      decoration: _kutuDeko(),
      child: Column(
        children: [
          _baslik(scheme, icon, baslik),
          ...satirlar,
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(toplamAd, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
                Text(toplam, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kalem({required String sol, String? alt, required String sag, String? etiket, Color? etiketRenk}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: Text(sol, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5))),
                    if (etiket != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(color: etiketRenk ?? Colors.grey, borderRadius: BorderRadius.circular(6)),
                        child: Text(etiket, style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ],
                ),
                if (alt != null && alt.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(alt, style: const TextStyle(fontSize: 11, color: Colors.black45)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(sag, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: Color(0xFF5C008E))),
        ],
      ),
    );
  }

  Widget _bosSatir(String t) => Padding(
        padding: const EdgeInsets.all(14),
        child: Text(t, style: const TextStyle(color: Colors.black45, fontSize: 12.5)),
      );

  Widget _saglamaSatir(String ad, String deger) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(ad, style: const TextStyle(fontSize: 13.5, color: Colors.black87)),
            Text(deger, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
          ],
        ),
      );

  // --- ortak stiller ---
  BoxDecoration _kutuDeko() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFECEEF4)),
        boxShadow: [BoxShadow(color: const Color(0xFF5C008E).withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
      );

  Widget _baslik(ColorScheme scheme, IconData icon, String t) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Row(
          children: [
            Icon(icon, size: 16, color: scheme.primary),
            const SizedBox(width: 8),
            Text(t, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF475569))),
          ],
        ),
      );

  // ============ PDF ============
  Future<void> _pdfAc() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _GunSonuPdfPreview(
          r: _r!,
          donem: _tarihEtiket(),
          detay: _detay,
          salonAdi: _salonAdi(),
        ),
      ),
    );
  }

  String _salonAdi() {
    try {
      final b = widget.isletmebilgi;
      if (b is Map && b['salon_adi'] != null) return b['salon_adi'].toString();
    } catch (_) {}
    return '';
  }
}

/// PDF önizleme + indir/paylaş (printing PdfPreview toolbar'i ile).
class _GunSonuPdfPreview extends StatelessWidget {
  final Map<String, dynamic> r;
  final String donem;
  final bool detay;
  final String salonAdi;
  const _GunSonuPdfPreview({required this.r, required this.donem, required this.detay, required this.salonAdi});

  double _d(dynamic v) => v == null ? 0 : (double.tryParse(v.toString()) ?? 0);

  @override
  Widget build(BuildContext context) {
    final nf = NumberFormat('#,##0.00', 'tr_TR');
    String para(dynamic v) => '${nf.format(_d(v))} TL';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gün Sonu PDF'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: PdfPreview(
        canChangePageFormat: false,
        canChangeOrientation: false,
        pdfFileName: 'gun-sonu${detay ? '-detay' : ''}.pdf',
        build: (format) => _makePdf(nf, para),
      ),
    );
  }

  Future<Uint8List> _makePdf(NumberFormat nf, String Function(dynamic) para) async {
    final base = pw.Font.ttf(await rootBundle.load('assets/google_fonts/Poppins-Regular.ttf'));
    final bold = pw.Font.ttf(await rootBundle.load('assets/google_fonts/Poppins-Bold.ttf'));
    final mor = PdfColor.fromHex('5C008E');
    final acikMor = PdfColor.fromHex('F5EEFE');
    final doc = pw.Document();

    pw.Widget sec(String t) => pw.Container(
          width: double.infinity,
          margin: const pw.EdgeInsets.only(top: 10, bottom: 4),
          padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
          color: mor,
          child: pw.Text(t, style: pw.TextStyle(font: bold, color: PdfColors.white, fontSize: 10)),
        );

    pw.Widget tablo(List<String> basliklar, List<List<String>> veri, {List<int> sagaYasli = const []}) {
      final aligns = <int, pw.Alignment>{};
      for (var i = 0; i < basliklar.length; i++) {
        aligns[i] = sagaYasli.contains(i) ? pw.Alignment.centerRight : pw.Alignment.centerLeft;
      }
      return pw.Table.fromTextArray(
        headers: basliklar,
        data: veri,
        border: null,
        headerStyle: pw.TextStyle(font: bold, color: mor, fontSize: 8.5),
        headerDecoration: pw.BoxDecoration(color: acikMor),
        cellStyle: pw.TextStyle(font: base, fontSize: 8.5),
        cellHeight: 16,
        headerAlignments: aligns,
        cellAlignments: aligns,
        oddRowDecoration: pw.BoxDecoration(color: PdfColor.fromHex('FBFAFE')),
      );
    }

    final gelir = (r['gelir'] ?? {}) as Map;
    final masraf = (r['masraf'] ?? {}) as Map;
    final net = (r['net'] ?? {}) as Map;
    const yontemler = [
      ['nakit', 'Nakit'],
      ['kredikarti', 'Kredi Kartı'],
      ['havale', 'Havale'],
      ['online', 'Online'],
      ['diger', 'Diğer'],
    ];

    final content = <pw.Widget>[];
    content.add(pw.Text('Gün Sonu Raporu', style: pw.TextStyle(font: bold, fontSize: 16, color: mor)));
    content.add(pw.Text('${salonAdi.isNotEmpty ? '$salonAdi   -   ' : ''}$donem', style: pw.TextStyle(font: base, fontSize: 9, color: PdfColors.grey700)));

    // Özet
    content.add(sec('ÖZET'));
    content.add(tablo(['Kalem', 'Değer'], [
      ['Gelirler Toplamı', para(r['gelir_toplam'])],
      ['Masraflar Toplamı', para(r['masraf_toplam'])],
      ['Net (Gelir - Masraf)', para(r['net_toplam'])],
      ['İşlem Sayısı', '${r['islem_say'] ?? 0}'],
      ['Müşteri Sayısı', '${r['musteri_say'] ?? 0}'],
      ['Ortalama Sepet', para(r['ort_sepet'])],
    ], sagaYasli: [1]));

    // Ödeme yöntemi
    content.add(sec('ÖDEME YÖNTEMİNE GÖRE'));
    final pmVeri = <List<String>>[];
    for (final y in yontemler) {
      pmVeri.add([y[1], nf.format(_d(gelir[y[0]])), nf.format(_d(masraf[y[0]])), nf.format(_d(net[y[0]]))]);
    }
    pmVeri.add(['Toplam', nf.format(_d(r['gelir_toplam'])), nf.format(_d(r['masraf_toplam'])), nf.format(_d(r['net_toplam']))]);
    content.add(tablo(['Yöntem', 'Gelir', 'Masraf', 'Net'], pmVeri, sagaYasli: [1, 2, 3]));

    if (detay) {
      // Satislar
      content.add(sec('SATIŞLAR (GELİRLER)'));
      final sv = ((r['satislar'] ?? []) as List)
          .map<List<String>>((s) => [
                s['saat']?.toString() ?? '',
                '${s['musteri'] ?? ''}${s['para_girisi'] == true ? ' (Para Girişi)' : ''}',
                s['tahsil_eden']?.toString() ?? '',
                s['yontem']?.toString() ?? '',
                nf.format(_d(s['tutar'])),
              ])
          .toList();
      if (sv.isEmpty) sv.add(['-', 'Satış yok', '', '', '']);
      sv.add(['', '', '', 'Toplam', nf.format(_d(r['gelir_toplam']))]);
      content.add(tablo(['Saat', 'Müşteri', 'Tahsil Eden', 'Yöntem', 'Tutar'], sv, sagaYasli: [4]));

      // İşletme masrafları
      content.add(sec('İŞLETME MASRAFLARI'));
      final iv = ((r['isletme_masraflari'] ?? []) as List)
          .map<List<String>>((m) => [
                m['harcayan']?.toString() ?? '',
                (m['aciklama']?.toString().isNotEmpty ?? false) ? m['aciklama'].toString() : '-',
                m['yontem']?.toString() ?? '',
                nf.format(_d(m['tutar'])),
              ])
          .toList();
      if (iv.isEmpty) iv.add(['', 'İşletme masrafı yok', '', '']);
      iv.add(['', '', 'Toplam', nf.format(_d(r['isletme_masraf_toplam']))]);
      content.add(tablo(['Harcayan', 'Açıklama', 'Yöntem', 'Tutar'], iv, sagaYasli: [3]));

      // Personel giderleri
      content.add(sec('PERSONEL GİDERLERİ & ÖDEMELERİ'));
      final pv = ((r['personel_giderleri'] ?? []) as List)
          .map<List<String>>((m) => [
                m['harcayan']?.toString() ?? '',
                m['tip']?.toString() ?? '',
                (m['aciklama']?.toString().isNotEmpty ?? false) ? m['aciklama'].toString() : '-',
                nf.format(_d(m['tutar'])),
              ])
          .toList();
      if (pv.isEmpty) pv.add(['', 'Yok', '', '']);
      pv.add(['', '', 'Toplam', nf.format(_d(r['personel_gider_toplam']))]);
      content.add(tablo(['Personel', 'Tür', 'Açıklama', 'Tutar'], pv, sagaYasli: [3]));

      // Sağlama
      content.add(sec('SAĞLAMA'));
      content.add(tablo(['Kalem', 'Tutar'], [
        ['Satışlar', para(r['gelir_toplam'])],
        ['(-) İşletme Masrafları', para(r['isletme_masraf_toplam'])],
        ['(-) Personel Giderleri', para(r['personel_gider_toplam'])],
        ['= NET (Kasa)', para(r['net_toplam'])],
      ], sagaYasli: [1]));
    } else {
      // Personel ciro
      content.add(sec('PERSONEL BAZLI CİRO'));
      final pc = ((r['personeller'] ?? []) as List)
          .map<List<String>>((p) => [p['personel_adi']?.toString() ?? '', '${p['adet'] ?? 0}', nf.format(_d(p['ciro']))])
          .toList();
      if (pc.isEmpty) pc.add(['Kayıt yok', '', '']);
      content.add(tablo(['Personel', 'İşlem', 'Ciro'], pc, sagaYasli: [1, 2]));

      // En çok satan hizmet
      content.add(sec('EN ÇOK SATAN HİZMET'));
      final hz = ((r['top_hizmet'] ?? []) as List)
          .map<List<String>>((x) => [x['hizmet_adi']?.toString() ?? '', '${x['adet'] ?? 0}', nf.format(_d(x['ciro']))])
          .toList();
      if (hz.isEmpty) hz.add(['Kayıt yok', '', '']);
      content.add(tablo(['Ad', 'Adet', 'Ciro'], hz, sagaYasli: [1, 2]));

      // En çok satan ürün
      content.add(sec('EN ÇOK SATAN ÜRÜN'));
      final ur = ((r['top_urun'] ?? []) as List)
          .map<List<String>>((x) => [x['urun_adi']?.toString() ?? '', '${x['adet'] ?? 0}', nf.format(_d(x['ciro']))])
          .toList();
      if (ur.isEmpty) ur.add(['Kayıt yok', '', '']);
      content.add(tablo(['Ad', 'Adet', 'Ciro'], ur, sagaYasli: [1, 2]));
    }

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(26),
      theme: pw.ThemeData.withFont(base: base, bold: bold),
      build: (ctx) => content,
      footer: (ctx) => pw.Container(
        alignment: pw.Alignment.center,
        margin: const pw.EdgeInsets.only(top: 8),
        child: pw.Text('${ctx.pageNumber} / ${ctx.pagesCount}', style: pw.TextStyle(font: base, fontSize: 7.5, color: PdfColors.grey)),
      ),
    ));

    return doc.save();
  }
}

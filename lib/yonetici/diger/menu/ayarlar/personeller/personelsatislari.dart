import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Frontend/sfdatatable.dart';
import 'package:randevu_sistem/Models/adisyonlar.dart';
import 'package:randevu_sistem/Models/personel.dart';
import 'package:randevu_sistem/Models/satisturleri.dart';
import 'package:randevu_sistem/yonetici/adisyonlar/satislar/tahsilat.dart';

// Modern soft tasarimli "Personel Satislari" sayfasi. SatisDataSource veri
// kaynagi olarak korunuyor (mevcut fetchData/search/setPage mantigi tamamen ayni),
// sadece UI kart-bazli moderne cevrildi.
class PersonelSatislari extends StatefulWidget {
  final Personel kullanici;
  final dynamic isletmebilgi;
  final int kullanicirolu;
  const PersonelSatislari({
    super.key,
    required this.kullanici,
    required this.isletmebilgi,
    required this.kullanicirolu,
  });

  @override
  State<PersonelSatislari> createState() => _PersonelSatislariState();
}

class _PersonelSatislariState extends State<PersonelSatislari> {
  // === Tema sabitleri (Personeller sayfasi ile birebir) ===
  static const _p1 = Color(0xFF5C008E);
  static const _p2 = Color(0xFF7B2FB8);
  static const _p3 = Color(0xFF9D5DC8);
  static const _purpleBg = Color(0xFFF7F1FB);
  static const _border = Color(0xFFECE6F2);
  static const _text = Color(0xFF2D1B3F);
  static const _muted = Color(0xFF8A8295);
  static const _grad = LinearGradient(
    colors: [_p1, _p2, _p3],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  bool _isLoading = true;
  late String? seciliisletme;
  late SatisDataSource _ds;

  // Filtreler
  final List<SatisTuru> _turler = [
    SatisTuru(id: "", satisturu: "Tümü"),
    SatisTuru(id: "1", satisturu: "Hizmet"),
    SatisTuru(id: "2", satisturu: "Paket"),
    SatisTuru(id: "3", satisturu: "Ürün"),
  ];
  SatisTuru? _seciliTur;

  // Default tarih araligi: cok eski + bugun (mevcut davranisla ayni)
  final TextEditingController _tarih1 = TextEditingController(text: "1970-09-01");
  final TextEditingController _tarih2 =
      TextEditingController(text: DateFormat("yyyy-MM-dd").format(DateTime.now()));
  DateTimeRange? _aralik;

  @override
  void initState() {
    super.initState();
    _seciliTur = _turler[0];
    _initialize();
  }

  Future<void> _initialize() async {
    seciliisletme = await secilisalonid();
    if (!mounted) return;
    _ds = SatisDataSource(
      kullanicirolu: widget.kullanicirolu,
      musteriMi: false,
      personelMi: true,
      isletmebilgi: widget.isletmebilgi,
      rowsPerPage: 10,
      salonid: seciliisletme!,
      context: context,
      tarih1: _tarih1.text,
      tarih2: _tarih2.text,
      musteriid: "",
      personelid: widget.kullanici.id,
      userid: '',
      tur: _seciliTur?.id ?? "",
    );
    _ds.isLoadingNotifier.addListener(_onLoadingChanged);
    setState(() => _isLoading = false);
  }

  void _onLoadingChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ds.isLoadingNotifier.removeListener(_onLoadingChanged);
    _tarih1.dispose();
    _tarih2.dispose();
    super.dispose();
  }

  // === Filtreyi uygula (search) ===
  void _filtreUygula() {
    _ds.search(_tarih1.text, _tarih2.text, "", _seciliTur?.id ?? "", true);
  }

  Future<void> _tarihAraligiSec() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _aralik,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: _p1,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: _text,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      _aralik = picked;
      _tarih1.text = DateFormat("yyyy-MM-dd").format(picked.start);
      _tarih2.text = DateFormat("yyyy-MM-dd").format(picked.end);
      setState(() {});
      _filtreUygula();
    }
  }

  void _tarihiSifirla() {
    _aralik = null;
    _tarih1.text = "1970-09-01";
    _tarih2.text = DateFormat("yyyy-MM-dd").format(DateTime.now());
    setState(() {});
    _filtreUygula();
  }

  // === BUILD ===
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9FD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        iconTheme: const IconThemeData(color: _text),
        title: const Text('Personel Satışları',
            style: TextStyle(color: _text, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            tooltip: 'Yenile',
            icon: const Icon(Icons.refresh, color: _p1),
            onPressed: _isLoading ? null : _filtreUygula,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _p1))
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
                    children: [
                      _hero(),
                      const SizedBox(height: 12),
                      _filtreKart(),
                      const SizedBox(height: 12),
                      if (_ds.isLoadingNotifier.value)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(child: CircularProgressIndicator(color: _p1)),
                        )
                      else if (_ds.adisyon.isEmpty)
                        _bosKart()
                      else
                        ..._ds.adisyon.map(_satisKart),
                    ],
                  ),
                ),
                if (_ds.totalPages > 1) _pagination(),
              ],
            ),
    );
  }

  // === Hero (personel bilgisi) ===
  Widget _hero() {
    final initial = widget.kullanici.personel_adi.trim().isEmpty
        ? '?'
        : widget.kullanici.personel_adi.trim().substring(0, 1).toUpperCase();
    return Container(
      decoration: BoxDecoration(
        gradient: _grad,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: _p1.withValues(alpha: 0.22), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
            ),
            alignment: Alignment.center,
            child: Text(initial,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.kullanici.personel_adi.isEmpty ? 'Personel' : widget.kullanici.personel_adi,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  widget.kullanici.unvan.isNotEmpty && widget.kullanici.unvan != 'null'
                      ? '${widget.kullanici.unvan} · Satış geçmişi'
                      : 'Satış geçmişi',
                  style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // === Filtre kart (chip'ler + tarih) ===
  Widget _filtreKart() {
    final tarihLabel = _aralik == null
        ? 'Tüm zamanlar'
        : '${DateFormat("d MMM").format(_aralik!.start)} - ${DateFormat("d MMM").format(_aralik!.end)}';
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [BoxShadow(color: _p1.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Satis turu chip'leri
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _turler.map(_turChip).toList(),
            ),
          ),
          const SizedBox(height: 10),
          // Tarih aralığı
          Row(
            children: [
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: _tarihAraligiSec,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: _purpleBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.event, color: _p1, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(tarihLabel,
                                style: const TextStyle(
                                    color: _text, fontWeight: FontWeight.w600, fontSize: 13)),
                          ),
                          const Icon(Icons.keyboard_arrow_down_rounded, color: _p1, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (_aralik != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Tarih filtresini temizle',
                  icon: const Icon(Icons.close, color: _muted, size: 18),
                  onPressed: _tarihiSifirla,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _turChip(SatisTuru t) {
    final sel = _seciliTur?.id == t.id;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            setState(() => _seciliTur = t);
            _filtreUygula();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: sel ? _grad : null,
              color: sel ? null : _purpleBg,
              borderRadius: BorderRadius.circular(20),
              boxShadow: sel
                  ? [BoxShadow(color: _p1.withValues(alpha: 0.22), blurRadius: 8, offset: const Offset(0, 3))]
                  : null,
            ),
            child: Text(
              t.satisturu,
              style: TextStyle(
                color: sel ? Colors.white : _p1,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // === Satış kartı ===
  Widget _satisKart(Adisyon a) {
    // 'kalan_tutar' veya 'kalan' alanindan birini parse et
    final kalan = _parseTrNumber(a.kalan_tutar);
    final odenmis = kalan <= 0;
    final turBilgi = _turBilgisi(a);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [BoxShadow(color: _p1.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: kalan > 0 ? () => _tahsilataGit(a) : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Müşteri + Durum
              Row(
                children: [
                  Expanded(
                    child: Text(
                      a.musteri.isEmpty ? '—' : a.musteri,
                      style: const TextStyle(color: _text, fontWeight: FontWeight.w700, fontSize: 14.5),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _durumChip(odenmis),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  if (a.acilis_tarihi.isNotEmpty && a.acilis_tarihi != 'null') ...[
                    const Icon(Icons.event, size: 12, color: _muted),
                    const SizedBox(width: 4),
                    Text(a.acilis_tarihi, style: TextStyle(color: _muted, fontSize: 11.5)),
                  ],
                  if (turBilgi != null) ...[
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: turBilgi.$2.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(turBilgi.$1,
                          style: TextStyle(
                              color: turBilgi.$2, fontSize: 10.5, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ],
              ),
              if (a.icerik.isNotEmpty && a.icerik != 'null') ...[
                const SizedBox(height: 8),
                Text(
                  a.icerik,
                  style: const TextStyle(color: _text, fontSize: 12.5),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 10),
              Container(height: 1, color: _border),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _tutarBlok('Toplam', a.toplam, _text)),
                  Expanded(child: _tutarBlok('Ödenen', a.odenen, const Color(0xFF15803D))),
                  Expanded(
                    child: _tutarBlok(
                      'Kalan',
                      a.kalan_tutar,
                      kalan > 0 ? const Color(0xFF991B1B) : const Color(0xFF15803D),
                    ),
                  ),
                ],
              ),
              if (kalan > 0) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF34D399)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => _tahsilataGit(a),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.attach_money, color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text('Tahsil Et',
                                style: TextStyle(
                                    color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _tutarBlok(String label, String val, Color renk) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: TextStyle(
                color: _muted, fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
        const SizedBox(height: 2),
        Text(
          val.isEmpty ? '—' : '$val ₺',
          style: TextStyle(color: renk, fontSize: 12.5, fontWeight: FontWeight.w800),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _durumChip(bool odenmis) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: odenmis ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            odenmis ? Icons.check_circle : Icons.schedule,
            size: 11,
            color: odenmis ? const Color(0xFF15803D) : const Color(0xFFB45309),
          ),
          const SizedBox(width: 3),
          Text(
            odenmis ? 'Ödendi' : 'Kalan var',
            style: TextStyle(
              color: odenmis ? const Color(0xFF15803D) : const Color(0xFFB45309),
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // === Boş liste ===
  Widget _bosKart() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, color: _muted.withValues(alpha: 0.5), size: 48),
          const SizedBox(height: 10),
          const Text(
            'Satış bulunamadı',
            style: TextStyle(color: _text, fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'Filtreyi değiştirip tekrar dene',
            style: TextStyle(color: _muted, fontSize: 12.5),
          ),
        ],
      ),
    );
  }

  // === Pagination ===
  Widget _pagination() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _pageBtn(
            icon: Icons.chevron_left,
            enabled: _ds.currentPage > 1,
            onTap: () {
              _ds.setPage(_ds.currentPage - 1, _tarih1.text, _tarih2.text, "", _seciliTur?.id ?? "");
            },
          ),
          const SizedBox(width: 14),
          Text('Sayfa ${_ds.currentPage} / ${_ds.totalPages}',
              style: const TextStyle(color: _text, fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(width: 14),
          _pageBtn(
            icon: Icons.chevron_right,
            enabled: _ds.currentPage < _ds.totalPages,
            onTap: () {
              _ds.setPage(_ds.currentPage + 1, _tarih1.text, _tarih2.text, "", _seciliTur?.id ?? "");
            },
          ),
        ],
      ),
    );
  }

  Widget _pageBtn({required IconData icon, required bool enabled, required VoidCallback onTap}) {
    return Material(
      color: enabled ? _purpleBg : const Color(0xFFF3F4F6),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: enabled ? _p1 : _muted, size: 20),
        ),
      ),
    );
  }

  // === Yardimcilar ===
  // Adisyon icerigi/satis_turu'na bakarak tur etiketi + rengi bul.
  (String, Color)? _turBilgisi(Adisyon a) {
    final t = a.satis_turu.toLowerCase();
    if (t.contains('hizmet')) return ('Hizmet', _p1);
    if (t.contains('paket')) return ('Paket', const Color(0xFFEA43F2));
    if (t.contains('ürün') || t.contains('urun')) return ('Ürün', const Color(0xFFF59E0B));
    return null;
  }

  double _parseTrNumber(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    var s = v.toString().trim();
    if (s.isEmpty) return 0.0;
    if (s.contains(',')) {
      // TR formati: "1.234,56" -> binlik '.' kaldir, ondalik ',' -> '.'
      s = s.replaceAll('.', '').replaceAll(',', '.');
    } else if ('.'.allMatches(s).length > 1) {
      // Virgulsuz cok noktali "1.234.567" -> binlik ayraci, kaldir
      s = s.replaceAll('.', '');
    }
    // Virgulsuz tek nokta "1234.5" -> ondalik ayraci; nokta KALMALI
    // (backend float'i string olarak gelirse 10x/100x sismeyi onler)
    return double.tryParse(s) ?? 0.0;
  }

  void _tahsilataGit(Adisyon a) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TahsilatEkrani(
          adisyonId: a.id,
          kullanicirolu: widget.kullanicirolu,
          isletmebilgi: widget.isletmebilgi,
          musteridanisanid: a.user_id,
        ),
      ),
    );
  }
}

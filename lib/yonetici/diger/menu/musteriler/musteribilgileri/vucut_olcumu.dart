// Vucut Olcumu ekrani (Pilates/studyo modu).
// businessMode=true  -> isletme: listeler + ekler + siler (musteriId zorunlu)
// businessMode=false -> danisan: kendi olcumleri (salt-okunur) + gelisim grafigi
import 'package:flutter/material.dart';
import 'package:randevu_sistem/Backend/olcum_api.dart';
import 'package:randevu_sistem/Models/olcum.dart';

class VucutOlcumuEkran extends StatefulWidget {
  final bool businessMode;
  final String? salonId;
  final int? musteriId; // businessMode icin
  final String? musteriAdi;

  const VucutOlcumuEkran({
    Key? key,
    required this.businessMode,
    this.salonId,
    this.musteriId,
    this.musteriAdi,
  }) : super(key: key);

  @override
  State<VucutOlcumuEkran> createState() => _VucutOlcumuEkranState();
}

class _VucutOlcumuEkranState extends State<VucutOlcumuEkran> {
  static const Color _primary = Color(0xFF7C3AED);
  bool _yukleniyor = true;
  String? _hata;
  List<VucutOlcum> _liste = [];

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    setState(() {
      _yukleniyor = true;
      _hata = null;
    });
    try {
      final l = widget.businessMode
          ? await olcumListe(widget.salonId ?? '', widget.musteriId ?? 0)
          : await danisanOlcumlerim(salonId: widget.salonId);
      if (!mounted) return;
      setState(() {
        _liste = l;
        _yukleniyor = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hata = e.toString().replaceFirst('Exception: ', '');
        _yukleniyor = false;
      });
    }
  }

  // Danisan grafigi icin artan tarih ister; isletme listesi azalan gelir.
  List<VucutOlcum> get _artanTarih {
    final l = List<VucutOlcum>.from(_liste);
    l.sort((a, b) => a.tarih.compareTo(b.tarih));
    return l;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A2E)),
        title: Text(
          widget.businessMode ? 'Vücut Ölçümü' : 'Gelişimim',
          style: const TextStyle(color: Color(0xFF1A1A2E), fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF1A1A2E)),
            onPressed: _yukle,
          ),
        ],
      ),
      floatingActionButton: widget.businessMode
          ? FloatingActionButton.extended(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Yeni Ölçüm'),
              onPressed: _ekleFormAc,
            )
          : null,
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : _hata != null
              ? _hataGorunum()
              : _liste.isEmpty
                  ? _bosGorunum()
                  : RefreshIndicator(
                      onRefresh: _yukle,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
                        children: [
                          _grafikKart('Kilo (kg)', _artanTarih.map((o) => o.kilo).toList(),
                              const Color(0xFF1E88E5)),
                          const SizedBox(height: 12),
                          _grafikKart('VKİ', _artanTarih.map((o) => o.vki).toList(),
                              const Color(0xFF7C3AED)),
                          const SizedBox(height: 16),
                          const Padding(
                            padding: EdgeInsets.only(left: 4, bottom: 8),
                            child: Text('Ölçüm Geçmişi',
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                          ),
                          ..._liste.map(_olcumKart),
                        ],
                      ),
                    ),
    );
  }

  Widget _hataGorunum() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
              const SizedBox(height: 12),
              Text(_hata ?? '', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _yukle, child: const Text('Tekrar Dene')),
            ],
          ),
        ),
      );

  Widget _bosGorunum() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.monitor_weight_outlined, color: Colors.black26, size: 56),
              const SizedBox(height: 12),
              Text(
                widget.businessMode
                    ? 'Henüz ölçüm girilmemiş.\nSağ alttaki butondan ekleyebilirsiniz.'
                    : 'Henüz ölçümünüz bulunmuyor.\nStüdyonuz ölçüm girdikçe burada göreceksiniz.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      );

  Widget _grafikKart(String baslik, List<double?> ham, Color renk) {
    final noktalar = ham.where((e) => e != null).map((e) => e!).toList();
    if (noktalar.length < 2) return const SizedBox.shrink();
    final ilk = noktalar.first, son = noktalar.last;
    final fark = son - ilk;
    final farkStr = (fark > 0 ? '+' : '') + fark.toStringAsFixed(1);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(baslik, style: const TextStyle(fontWeight: FontWeight.w700)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (fark <= 0 ? Colors.green : Colors.orange).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$farkStr  (${son.toStringAsFixed(1)})',
                  style: TextStyle(
                    color: fark <= 0 ? Colors.green.shade700 : Colors.orange.shade800,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 70,
            width: double.infinity,
            child: CustomPaint(painter: _Sparkline(noktalar, renk)),
          ),
        ],
      ),
    );
  }

  Widget _olcumKart(VucutOlcum o) {
    final sinif = VucutOlcum.vkiSinif(o.vki);
    Widget metrik(String ad, double? v, String birim) {
      if (v == null) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(right: 16, top: 4),
        child: Text('$ad: ${v.toStringAsFixed(1)}$birim',
            style: const TextStyle(fontSize: 12, color: Colors.black87)),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event, size: 16, color: _primary),
              const SizedBox(width: 6),
              Text(o.tarih, style: const TextStyle(fontWeight: FontWeight.w700)),
              const Spacer(),
              if (o.vki != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('VKİ ${o.vki!.toStringAsFixed(1)}  $sinif',
                      style: const TextStyle(
                          color: _primary, fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              if (widget.businessMode) ...[
                const SizedBox(width: 4),
                InkWell(
                  onTap: () => _sil(o),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                  ),
                ),
              ],
            ],
          ),
          Wrap(
            children: [
              metrik('Kilo', o.kilo, ' kg'),
              metrik('Yağ', o.yagOrani, '%'),
              metrik('Ödem', o.odem, ''),
              metrik('Kas Puanı', o.kasPuani, ''),
              metrik('Kas', o.kasKg, ' kg'),
              metrik('İç Yağ.', o.icYaglanma, ''),
            ],
          ),
          if (o.not != null && o.not!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('📝 ${o.not}',
                  style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ),
        ],
      ),
    );
  }

  Future<void> _sil(VucutOlcum o) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Silinsin mi?'),
        content: Text('${o.tarih} tarihli ölçüm kaydı silinecek.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Vazgeç')),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Sil', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (onay != true) return;
    try {
      await olcumSil(widget.salonId ?? '', o.id);
      await _yukle();
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _ekleFormAc() async {
    final eklendi = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OlcumEkleSheet(
        salonId: widget.salonId ?? '',
        musteriId: widget.musteriId ?? 0,
      ),
    );
    if (eklendi == true) _yukle();
  }
}

// ------- Ekleme formu (bottom sheet) -------
class _OlcumEkleSheet extends StatefulWidget {
  final String salonId;
  final int musteriId;
  const _OlcumEkleSheet({Key? key, required this.salonId, required this.musteriId})
      : super(key: key);

  @override
  State<_OlcumEkleSheet> createState() => _OlcumEkleSheetState();
}

class _OlcumEkleSheetState extends State<_OlcumEkleSheet> {
  static const Color _primary = Color(0xFF7C3AED);
  DateTime _tarih = DateTime.now();
  final _yas = TextEditingController();
  final _boy = TextEditingController();
  final _kilo = TextEditingController();
  final _yag = TextEditingController();
  final _odem = TextEditingController();
  final _kasPuan = TextEditingController();
  final _kasKg = TextEditingController();
  final _icYag = TextEditingController();
  final _not = TextEditingController();
  bool _kaydediyor = false;

  String get _tarihStr =>
      '${_tarih.year.toString().padLeft(4, '0')}-${_tarih.month.toString().padLeft(2, '0')}-${_tarih.day.toString().padLeft(2, '0')}';

  String? get _vkiOnizle {
    final b = double.tryParse(_boy.text.replaceAll(',', '.')) ?? 0;
    final k = double.tryParse(_kilo.text.replaceAll(',', '.')) ?? 0;
    if (b <= 0 || k <= 0) return null;
    final m = b / 100;
    final v = k / (m * m);
    return '${v.toStringAsFixed(1)} (${VucutOlcum.vkiSinif(v)})';
  }

  @override
  void dispose() {
    for (final c in [_yas, _boy, _kilo, _yag, _odem, _kasPuan, _kasKg, _icYag, _not]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _kaydet() async {
    if (_boy.text.trim().isEmpty && _kilo.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('En az boy veya kilo girin.')));
      return;
    }
    setState(() => _kaydediyor = true);
    try {
      String? t(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();
      await olcumEkle(
        salonId: widget.salonId,
        musteriId: widget.musteriId,
        tarih: _tarihStr,
        yas: t(_yas),
        boy: t(_boy),
        kilo: t(_kilo),
        yagOrani: t(_yag),
        odem: t(_odem),
        kasPuani: t(_kasPuan),
        kasKg: t(_kasKg),
        icYaglanma: t(_icYag),
        not: t(_not),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _kaydediyor = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
      }
    }
  }

  Widget _alan(String etiket, TextEditingController c,
      {String? ipucu, bool sayi = true, bool genis = false}) {
    return SizedBox(
      width: genis ? double.infinity : null,
      child: TextField(
        controller: c,
        keyboardType: sayi
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: etiket,
          hintText: ipucu,
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final alt = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: alt),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const Text('Yeni Ölçüm',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),
              InkWell(
                onTap: () async {
                  final s = await showDatePicker(
                    context: context,
                    initialDate: _tarih,
                    firstDate: DateTime(2015),
                    lastDate: DateTime.now(),
                  );
                  if (s != null) setState(() => _tarih = s);
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Ölçüm Tarihi',
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(_tarihStr),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  SizedBox(width: _w(context), child: _alan('Yaş', _yas, ipucu: 'örn. 32')),
                  SizedBox(width: _w(context), child: _alan('Boy (cm)', _boy, ipucu: '170')),
                  SizedBox(width: _w(context), child: _alan('Kilo (kg)', _kilo, ipucu: '68')),
                  SizedBox(width: _w(context), child: _alan('Yağ Oranı (%)', _yag)),
                  SizedBox(width: _w(context), child: _alan('Ödem', _odem)),
                  SizedBox(width: _w(context), child: _alan('Kas Puanı', _kasPuan)),
                  SizedBox(width: _w(context), child: _alan('Kas (kg)', _kasKg)),
                  SizedBox(width: _w(context), child: _alan('İç Yağlanma', _icYag)),
                ],
              ),
              if (_vkiOnizle != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('Hesaplanan VKİ: $_vkiOnizle',
                      style: const TextStyle(
                          color: _primary, fontWeight: FontWeight.w700)),
                ),
              ],
              const SizedBox(height: 12),
              _alan('Not (opsiyonel)', _not, sayi: false, genis: true),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _kaydediyor ? null : _kaydet,
                  child: _kaydediyor
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Kaydet',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _w(BuildContext c) => (MediaQuery.of(c).size.width - 16 * 2 - 10) / 2;
}

// ------- Basit sparkline cizici -------
class _Sparkline extends CustomPainter {
  final List<double> data;
  final Color color;
  _Sparkline(this.data, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final minV = data.reduce((a, b) => a < b ? a : b);
    final maxV = data.reduce((a, b) => a > b ? a : b);
    final aralik = (maxV - minV).abs() < 0.0001 ? 1.0 : (maxV - minV);
    final dx = size.width / (data.length - 1);
    final noktalar = <Offset>[];
    for (var i = 0; i < data.length; i++) {
      final x = dx * i;
      final y = size.height - ((data[i] - minV) / aralik) * (size.height - 10) - 5;
      noktalar.add(Offset(x, y));
    }

    // dolgu
    final dolgu = Path()..moveTo(noktalar.first.dx, size.height);
    for (final p in noktalar) {
      dolgu.lineTo(p.dx, p.dy);
    }
    dolgu.lineTo(noktalar.last.dx, size.height);
    dolgu.close();
    canvas.drawPath(
        dolgu, Paint()..color = color.withOpacity(0.10)..style = PaintingStyle.fill);

    // cizgi
    final cizgi = Path()..moveTo(noktalar.first.dx, noktalar.first.dy);
    for (var i = 1; i < noktalar.length; i++) {
      cizgi.lineTo(noktalar[i].dx, noktalar[i].dy);
    }
    canvas.drawPath(
        cizgi,
        Paint()
          ..color = color
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round);

    // noktalar
    final nokPaint = Paint()..color = color;
    for (final p in noktalar) {
      canvas.drawCircle(p, 3, nokPaint);
      canvas.drawCircle(p, 1.5, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant _Sparkline old) =>
      old.data != data || old.color != color;
}

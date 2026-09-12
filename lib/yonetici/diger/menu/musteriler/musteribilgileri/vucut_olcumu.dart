// Vucut Olcumu ekrani (Pilates/studyo modu).
// businessMode=true  -> isletme: listeler + ekler + siler (musteriId zorunlu)
// businessMode=false -> danisan: kendi olcumleri (salt-okunur)
// Tasarim webdeki "Guncel VKI" ozet karti (renkli gauge) + gecmis listesi gibi.
// Boy ve Yas sabit: ekleme formunda son olcumden/dogum tarihinden on-dolu gelir,
// her seferinde tekrar girilmez. Dogum tarihi varsa yas otomatik hesaplanir (kilitli).
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:randevu_sistem/Backend/olcum_api.dart';
import 'package:randevu_sistem/Models/olcum.dart';

// VKI sinif/renk/skala yardimcilari (web ile birebir ayni esikler).
class _Vki {
  static const zonlar = [
    _Zon('Zayıf', 14, Color(0xFF17A2B8)),
    _Zon('Normal', 26, Color(0xFF28A745)),
    _Zon('Fazla', 20, Color(0xFFFD7E14)),
    _Zon('Obez', 40, Color(0xFFDC3545)),
  ];

  static Color renk(double v) {
    if (v <= 0) return const Color(0xFF9AA0B0);
    if (v < 18.5) return const Color(0xFF17A2B8);
    if (v < 25) return const Color(0xFF28A745);
    if (v < 30) return const Color(0xFFFD7E14);
    return const Color(0xFFDC3545);
  }

  static String sinif(double v) => VucutOlcum.vkiSinif(v);

  // 15..40 araliginda skala uzerinde konum (0..1)
  static double konum(double v) {
    const min = 15.0, max = 40.0;
    final p = (v - min) / (max - min);
    return p.clamp(0.0, 1.0);
  }
}

class _Zon {
  final String ad;
  final int gen;
  final Color renk;
  const _Zon(this.ad, this.gen, this.renk);
}

// ---- Gelisim grafigi icin izlenebilir metrikler ----
// Kullanici bu listeden secer, grafik ve ozet buna gore degisir.
// dusenIyi: degerin AZALMASI olumlu mu? (kilo/yag/vki dususu iyi, kas artisi iyi)
class _Metrik {
  final String key;
  final String etiket;
  final String birim;
  final double? Function(VucutOlcum) al;
  final bool dusenIyi;
  const _Metrik(this.key, this.etiket, this.birim, this.al, this.dusenIyi);
}

const List<_Metrik> _metrikTanim = [
  _Metrik('kilo', 'Kilo', 'kg', _mKilo, true),
  _Metrik('vki', 'VKİ', '', _mVki, true),
  _Metrik('yag', 'Yağ', '%', _mYag, true),
  _Metrik('kasKg', 'Kas', 'kg', _mKasKg, false),
  _Metrik('kasPuan', 'Kas Puanı', '', _mKasPuan, false),
  _Metrik('icYag', 'İç Yağ.', '', _mIcYag, true),
  _Metrik('odem', 'Ödem', '', _mOdem, true),
];

double? _mKilo(VucutOlcum o) => o.kilo;
double? _mVki(VucutOlcum o) => o.vki;
double? _mYag(VucutOlcum o) => o.yagOrani;
double? _mKasKg(VucutOlcum o) => o.kasKg;
double? _mKasPuan(VucutOlcum o) => o.kasPuani;
double? _mIcYag(VucutOlcum o) => o.icYaglanma;
double? _mOdem(VucutOlcum o) => o.odem;

// Dogum tarihinden yas hesapla (gecersizse null).
int? yasHesapla(String? dt) {
  if (dt == null || dt.isEmpty || dt == 'null') return null;
  DateTime? d;
  try {
    d = DateTime.parse(dt);
  } catch (_) {
    return null;
  }
  final now = DateTime.now();
  var y = now.year - d.year;
  if (now.month < d.month || (now.month == d.month && now.day < d.day)) y--;
  if (y < 0 || y > 130) return null;
  return y;
}

class VucutOlcumuEkran extends StatefulWidget {
  final bool businessMode;
  final String? salonId;
  final int? musteriId; // businessMode icin
  final String? musteriAdi;
  final String? dogumTarihi; // varsa yas otomatik hesaplanir

  const VucutOlcumuEkran({
    Key? key,
    required this.businessMode,
    this.salonId,
    this.musteriId,
    this.musteriAdi,
    this.dogumTarihi,
  }) : super(key: key);

  @override
  State<VucutOlcumuEkran> createState() => _VucutOlcumuEkranState();
}

class _VucutOlcumuEkranState extends State<VucutOlcumuEkran> {
  static const Color _primary = Color(0xFF7C3AED);
  bool _yukleniyor = true;
  String? _hata;
  List<VucutOlcum> _liste = [];
  String _metrik = 'kilo'; // gelisim grafiginde secili metrik

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

  // Isletme listesi azalan (yeni ustte) gelir. VKI'si olan en yeni olcum.
  VucutOlcum? get _sonVkili {
    for (final o in _liste) {
      if ((o.vki ?? 0) > 0) return o;
    }
    return _liste.isNotEmpty ? _liste.first : null;
  }

  // Ekleme formuna on-dolu deger: en yeni boy / yas (dogum tarihi yoksa).
  double? get _sonBoy {
    for (final o in _liste) {
      if ((o.boy ?? 0) > 0) return o.boy;
    }
    return null;
  }

  int? get _sonYas {
    for (final o in _liste) {
      if (o.yas != null && o.yas! > 0) return o.yas;
    }
    return null;
  }

  // Grafik icin tarihe gore ARTAN sirali kopya (isletme listesi azalan gelir).
  List<VucutOlcum> get _artan {
    final c = [..._liste];
    c.sort((a, b) {
      final t = a.tarih.compareTo(b.tarih);
      return t != 0 ? t : a.id.compareTo(b.id);
    });
    return c;
  }

  // En az 2 veri noktasi olan metrikler (tek nokta ile trend cizilmez).
  List<_Metrik> get _mevcutMetrikler {
    final v = _artan;
    return _metrikTanim
        .where((m) => v.where((o) => m.al(o) != null).length >= 2)
        .toList();
  }

  String _kisaTarih(String t) {
    final s = t.length >= 10 ? t.substring(0, 10) : t;
    final p = s.split('-');
    return p.length == 3 ? '${p[2]}/${p[1]}' : s;
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
                          if (widget.musteriAdi != null &&
                              widget.musteriAdi!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 4, bottom: 10),
                              child: Text(
                                '${widget.musteriAdi} — Vücut Ölçümleri',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 16),
                              ),
                            ),
                          _ozetKart(),
                          _grafikKart(),
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

  // ---- Gelisim grafigi: secilen metrigin zaman icindeki degisimi ----
  Widget _grafikKart() {
    final metrikler = _mevcutMetrikler;
    if (metrikler.isEmpty) return const SizedBox.shrink();
    final secili = metrikler.firstWhere((m) => m.key == _metrik,
        orElse: () => metrikler.first);

    // Secili metrigin (varsa) noktalarini artan tarihe gore topla.
    final noktalar = <FlSpot>[];
    final tarihler = <String>[];
    double minY = double.infinity, maxY = -double.infinity;
    var i = 0;
    for (final o in _artan) {
      final val = secili.al(o);
      if (val == null) continue;
      noktalar.add(FlSpot(i.toDouble(), val));
      tarihler.add(_kisaTarih(o.tarih));
      if (val < minY) minY = val;
      if (val > maxY) maxY = val;
      i++;
    }
    if (noktalar.length < 2) return const SizedBox.shrink();

    // Y ekseni icin nefes payi.
    final aralik = (maxY - minY).abs();
    final pay = aralik < 0.5 ? 1.0 : aralik * 0.18;
    final altY = minY - pay;
    final ustY = maxY + pay;

    // Ilk -> son degisim ve yorum (metrigin yonune gore olumlu/olumsuz).
    final ilk = noktalar.first.y;
    final son = noktalar.last.y;
    final fark = son - ilk;
    final iyi = secili.dusenIyi ? fark < 0 : fark > 0;
    final degismedi = fark.abs() < (aralik < 0.5 ? 0.05 : 0.1);
    final farkRenk = degismedi
        ? const Color(0xFF888888)
        : (iyi ? const Color(0xFF28A745) : const Color(0xFFDC3545));
    final ok = degismedi ? '●' : (fark > 0 ? '▲' : '▼');
    final cizgiRenk = _primary;

    final bottomAralik =
        (noktalar.length / 4).ceilToDouble().clamp(1.0, double.infinity);

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.show_chart, size: 18, color: _primary),
              const SizedBox(width: 6),
              const Text('Gelişim Grafiği',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              const Spacer(),
              Text('$ok ${fark.abs().toStringAsFixed(aralik < 0.5 ? 2 : 1)}${secili.birim}',
                  style: TextStyle(
                      color: farkRenk,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
            ],
          ),
          const SizedBox(height: 10),
          // Metrik secici cipler
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: metrikler.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, idx) {
                final m = metrikler[idx];
                final aktif = m.key == secili.key;
                return GestureDetector(
                  onTap: () => setState(() => _metrik = m.key),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: aktif ? _primary : const Color(0xFFF0F0F7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      m.etiket,
                      style: TextStyle(
                        color: aktif ? Colors.white : const Color(0xFF555566),
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 190,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (noktalar.length - 1).toDouble(),
                minY: altY,
                maxY: ustY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (ustY - altY) / 4,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: const Color(0xFFEDEDF3), strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      interval: (ustY - altY) / 4,
                      getTitlesWidget: (value, meta) => Text(
                        value.toStringAsFixed(aralik < 5 ? 1 : 0),
                        style: const TextStyle(
                            fontSize: 9.5, color: Color(0xFF999999)),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: bottomAralik,
                      getTitlesWidget: (value, meta) {
                        final idx = value.round();
                        if (idx < 0 || idx >= tarihler.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(tarihler[idx],
                              style: const TextStyle(
                                  fontSize: 9, color: Color(0xFF999999))),
                        );
                      },
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF2A2A3C),
                    getTooltipItems: (spots) => spots.map((s) {
                      final idx = s.x.round();
                      final t = (idx >= 0 && idx < tarihler.length)
                          ? tarihler[idx]
                          : '';
                      return LineTooltipItem(
                        '${s.y.toStringAsFixed(aralik < 5 ? 1 : 0)}${secili.birim}\n$t',
                        const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12),
                      );
                    }).toList(),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: noktalar,
                    isCurved: true,
                    curveSmoothness: 0.25,
                    color: cizgiRenk,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, pct, bar, index) =>
                          FlDotCirclePainter(
                        radius: 3.5,
                        color: Colors.white,
                        strokeWidth: 2,
                        strokeColor: cizgiRenk,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: cizgiRenk.withOpacity(0.10),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---- Web'deki "Guncel VKI" ozet karti (renkli gauge) ----
  Widget _ozetKart() {
    final son = _sonVkili;
    final v = son?.vki ?? 0;
    if (son == null || v <= 0) return const SizedBox.shrink();
    final renk = _Vki.renk(v);
    final sinif = _Vki.sinif(v);
    final pos = _Vki.konum(v);

    // Boy/Yas ozette gosterilecek: dogum tarihinden yas oncelik.
    final yasGoster = yasHesapla(widget.dogumTarihi) ?? son.yas ?? _sonYas;
    final boyGoster = son.boy ?? _sonBoy;

    // Onceki olcume gore kilo degisimi.
    Widget? delta;
    if ((son.kilo ?? 0) > 0) {
      VucutOlcum? onceki;
      var gecti = false;
      for (final o in _liste) {
        if (identical(o, son)) {
          gecti = true;
          continue;
        }
        if (gecti && (o.kilo ?? 0) > 0) {
          onceki = o;
          break;
        }
      }
      if (onceki != null) {
        final d = son.kilo! - onceki.kilo!;
        if (d.abs() >= 0.05) {
          final arti = d > 0;
          final dRenk = arti ? const Color(0xFFDC3545) : const Color(0xFF28A745);
          delta = Padding(
            padding: const EdgeInsets.only(top: 8),
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                    color: dRenk, fontWeight: FontWeight.w700, fontSize: 12.5),
                children: [
                  TextSpan(text: '${arti ? '▲' : '▼'} ${d.abs().toStringAsFixed(1)} kg '),
                  const TextSpan(
                      text: '(önceki ölçüme göre)',
                      style: TextStyle(
                          color: Color(0xFF888888),
                          fontWeight: FontWeight.w400,
                          fontSize: 12.5)),
                ],
              ),
            ),
          );
        } else {
          delta = const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('● Kilo sabit',
                style: TextStyle(color: Color(0xFF888888), fontSize: 12.5)),
          );
        }
      }
    }

    Widget cip(IconData ic, String metin) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F0F7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(ic, size: 13, color: Colors.black45),
              const SizedBox(width: 5),
              Text(metin,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: renk, width: 6)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (son.tarih.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  const Icon(Icons.access_time, size: 14, color: Colors.black38),
                  const SizedBox(width: 5),
                  Text('Son ölçüm: ${son.tarih}',
                      style: const TextStyle(fontSize: 12.5, color: Colors.black54)),
                ],
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Sol: dev VKI rakami
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('GÜNCEL VKİ',
                      style: TextStyle(
                          fontSize: 10.5,
                          letterSpacing: 0.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF8A8FA3))),
                  Text(v.toStringAsFixed(1),
                      style: TextStyle(
                          fontSize: 44,
                          height: 1.05,
                          fontWeight: FontWeight.w800,
                          color: renk)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
                    decoration: BoxDecoration(
                        color: renk, borderRadius: BorderRadius.circular(20)),
                    child: Text(sinif,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(width: 18),
              // Sag: cipler + gauge + scale + delta
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (boyGoster != null)
                          cip(Icons.straighten, 'Boy ${boyGoster.toStringAsFixed(1)} cm'),
                        if (yasGoster != null) cip(Icons.cake_outlined, 'Yaş $yasGoster'),
                        if ((son.kilo ?? 0) > 0)
                          cip(Icons.monitor_weight_outlined,
                              'Kilo ${son.kilo!.toStringAsFixed(1)} kg'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _GaugeBar(pos: pos),
                    const SizedBox(height: 4),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 1),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('15', style: TextStyle(fontSize: 9.5, color: Color(0xFF999999))),
                          Text('18.5', style: TextStyle(fontSize: 9.5, color: Color(0xFF999999))),
                          Text('25', style: TextStyle(fontSize: 9.5, color: Color(0xFF999999))),
                          Text('30', style: TextStyle(fontSize: 9.5, color: Color(0xFF999999))),
                          Text('40+', style: TextStyle(fontSize: 9.5, color: Color(0xFF999999))),
                        ],
                      ),
                    ),
                    if (delta != null) delta,
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _olcumKart(VucutOlcum o) {
    final v = o.vki ?? 0;
    final sinif = _Vki.sinif(v);
    final renk = _Vki.renk(v);
    Widget metrik(String ad, double? val, String birim) {
      if (val == null) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(right: 16, top: 4),
        child: Text('$ad: ${val.toStringAsFixed(1)}$birim',
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
              if (v > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: renk.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('VKİ ${v.toStringAsFixed(1)}  $sinif',
                      style: TextStyle(
                          color: renk, fontWeight: FontWeight.w700, fontSize: 12)),
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
        dogumTarihi: widget.dogumTarihi,
        onBoy: _sonBoy,
        onYas: _sonYas,
      ),
    );
    if (eklendi == true) _yukle();
  }
}

// Renkli 4 zonlu gauge bar + ustunde ok isaretci.
class _GaugeBar extends StatelessWidget {
  final double pos; // 0..1
  const _GaugeBar({Key? key, required this.pos}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      return SizedBox(
        height: 20,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: 6,
              left: 0,
              right: 0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  children: _Vki.zonlar
                      .map((z) => Expanded(
                            flex: z.gen,
                            child: Container(height: 14, color: z.renk),
                          ))
                      .toList(),
                ),
              ),
            ),
            // Ok isaretci
            Positioned(
              left: (pos * w) - 6,
              top: 0,
              child: CustomPaint(size: const Size(12, 9), painter: _OkPainter()),
            ),
          ],
        ),
      );
    });
  }
}

class _OkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(p, Paint()..color = const Color(0xFF222222));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ------- Ekleme formu (bottom sheet) -------
class _OlcumEkleSheet extends StatefulWidget {
  final String salonId;
  final int musteriId;
  final String? dogumTarihi;
  final double? onBoy; // son olcumden gelen boy (on-dolu)
  final int? onYas; // son olcumden gelen yas (dogum tarihi yoksa)
  const _OlcumEkleSheet({
    Key? key,
    required this.salonId,
    required this.musteriId,
    this.dogumTarihi,
    this.onBoy,
    this.onYas,
  }) : super(key: key);

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

  int? _otoYas; // dogum tarihinden hesaplanan yas (varsa yas kilitli)

  @override
  void initState() {
    super.initState();
    // Boy sabit: son olcumden on-dolu.
    if (widget.onBoy != null && widget.onBoy! > 0) {
      _boy.text = _sayiStr(widget.onBoy!);
    }
    // Yas: dogum tarihi varsa otomatik (kilitli), yoksa son yastan on-dolu.
    _otoYas = yasHesapla(widget.dogumTarihi);
    if (_otoYas != null) {
      _yas.text = _otoYas.toString();
    } else if (widget.onYas != null && widget.onYas! > 0) {
      _yas.text = widget.onYas.toString();
    }
  }

  String _sayiStr(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  String get _tarihStr =>
      '${_tarih.year.toString().padLeft(4, '0')}-${_tarih.month.toString().padLeft(2, '0')}-${_tarih.day.toString().padLeft(2, '0')}';

  double get _vkiDeger {
    final b = double.tryParse(_boy.text.replaceAll(',', '.')) ?? 0;
    final k = double.tryParse(_kilo.text.replaceAll(',', '.')) ?? 0;
    if (b <= 0 || k <= 0) return 0;
    final m = b / 100;
    return k / (m * m);
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
      {String? ipucu,
      bool sayi = true,
      bool genis = false,
      bool saltOkunur = false,
      String? yardim}) {
    return SizedBox(
      width: genis ? double.infinity : null,
      child: TextField(
        controller: c,
        readOnly: saltOkunur,
        keyboardType: sayi
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: etiket,
          hintText: ipucu,
          helperText: yardim,
          helperStyle: const TextStyle(fontSize: 10.5, color: _primary),
          suffixIcon: saltOkunur
              ? const Icon(Icons.lock_outline, size: 16, color: Colors.black38)
              : null,
          filled: saltOkunur,
          fillColor: saltOkunur ? const Color(0xFFF4F4FB) : null,
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
    final v = _vkiDeger;
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
                  SizedBox(
                    width: _w(context),
                    child: _alan('Yaş', _yas,
                        ipucu: 'örn. 32',
                        saltOkunur: _otoYas != null,
                        yardim: _otoYas != null ? 'Doğum tarihinden' : null),
                  ),
                  SizedBox(width: _w(context), child: _alan('Boy (cm)', _boy, ipucu: '170')),
                  SizedBox(width: _w(context), child: _alan('Kilo (kg)', _kilo, ipucu: '68')),
                  SizedBox(width: _w(context), child: _alan('Yağ Oranı (%)', _yag)),
                  SizedBox(width: _w(context), child: _alan('Ödem', _odem)),
                  SizedBox(width: _w(context), child: _alan('Kas Puanı', _kasPuan)),
                  SizedBox(width: _w(context), child: _alan('Kas (kg)', _kasKg)),
                  SizedBox(width: _w(context), child: _alan('İç Yağlanma', _icYag)),
                ],
              ),
              if (v > 0) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _Vki.renk(v).withOpacity(0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Text('VKİ (otomatik): ',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      Text(v.toStringAsFixed(1),
                          style: TextStyle(
                              color: _Vki.renk(v),
                              fontWeight: FontWeight.w800,
                              fontSize: 16)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                            color: _Vki.renk(v),
                            borderRadius: BorderRadius.circular(20)),
                        child: Text(_Vki.sinif(v),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
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

import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Models/musteri_danisanlar.dart';
import 'package:randevu_sistem/musteripaneli/anasayfa/odullerim.dart';
import 'package:randevu_sistem/musteripaneli/anasayfa/puan_odullerim.dart';

/// Çarkıfelek (Wheel of Fortune) sayfası — backend'e bağlı.
/// Onaylanmış randevu üzerinden hak kazanılır, günde bir çevirme.
class WheelPage extends StatefulWidget {
  final MusteriDanisan md;
  final dynamic isletmebilgi;

  const WheelPage({
    Key? key,
    required this.md,
    required this.isletmebilgi,
  }) : super(key: key);

  @override
  State<WheelPage> createState() => _WheelPageState();
}

class _WheelPageState extends State<WheelPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  double _angle = 0.0;
  bool _isSpinning = false;
  bool _isLoading = true;
  String? _loadError;

  // Backend state
  bool _aktif = false;
  String _salonAdi = '';
  String _salonId = '';
  int _kalanHak = 0;
  bool _bugunCevirdi = false;
  String _yarinSaat = '';
  List<_Dilim> _dilimler = [];

  // Tick ses akümülatörü — her dilim geçişinde sistem tık sesi + haptik
  double _lastTickAngle = 0.0;
  double _tickAcc = 0.0;

  @override
  void initState() {
    super.initState();
    _salonId = widget.isletmebilgi['id'].toString();
    _salonAdi = (widget.isletmebilgi['salon_adi'] ?? '').toString();

    _controller = AnimationController(
      duration: const Duration(seconds: 9),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.fastOutSlowIn);

    _yukle();
  }

  Future<void> _yukle() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final res = await carkDurum(_salonId, widget.md.id.toString());
      if (res['success'] != true) {
        setState(() {
          _isLoading = false;
          _loadError = res['message']?.toString() ?? 'Veri alınamadı.';
        });
        return;
      }
      final aktif = res['aktif'] == true;
      final salon = res['salon'] ?? {};
      final list = (res['dilimler'] as List? ?? [])
          .map((e) => _Dilim.fromJson(e as Map<String, dynamic>))
          .toList();

      setState(() {
        // TEST MODU: aktif değilse ya da dilim yoksa lokal mock setiyle aç
        _aktif = aktif || list.length < 2 ? true : aktif;
        _salonAdi = (salon['salon_adi'] ?? _salonAdi).toString();
        _kalanHak = (res['kalanHak'] ?? 0) is int
            ? res['kalanHak']
            : int.tryParse(res['kalanHak'].toString()) ?? 0;
        _bugunCevirdi = res['bugunCevirdi'] == true;
        _yarinSaat = (res['yarinSaat'] ?? '').toString();
        _dilimler = list.length < 2 ? _mockDilimler() : list;
        _isLoading = false;
      });
    } catch (e) {
      // TEST MODU: bağlantı yoksa bile çark çalışsın
      setState(() {
        _aktif = true;
        _dilimler = _mockDilimler();
        _isLoading = false;
        _loadError = null;
      });
    }
  }

  // TEST MODU: backend pasif veya yetersiz dilim döndürürse fallback
  List<_Dilim> _mockDilimler() {
    const colors = [
      0xFF6C5CE7, 0xFFFD79A8, 0xFFFDCB6E, 0xFF00B894,
      0xFFE17055, 0xFF74B9FF, 0xFFA29BFE, 0xFFFAB1A0,
    ];
    const tipler = [
      'puan', 'hizmet_indirimi', 'bos', 'tekrar_dene',
      'urun_indirimi', 'puan', 'hizmet_indirimi', 'bos',
    ];
    const isimler = [
      '100 Puan', '%10 Hizmet', 'Boş', 'Tekrar Dene',
      '%5 Ürün', '50 Puan', '%20 Hizmet', 'Boş',
    ];
    return List.generate(8, (i) {
      final tip = tipler[i];
      double? deger;
      if (tip == 'hizmet_indirimi' || tip == 'urun_indirimi') {
        deger = i == 1 ? 10 : (i == 4 ? 5 : 20);
      } else if (tip == 'puan') {
        deger = i == 0 ? 100 : 50;
      }
      return _Dilim(
        id: i + 1,
        ismi: isimler[i],
        renk: Color(colors[i]),
        tip: tip,
        deger: deger,
        sira: i,
      );
    });
  }

  // TEST MODU: backend reddederse lokal random sonuç üret
  Map<String, dynamic> _mockSpinResult() {
    final random = Random();
    final idx = random.nextInt(_dilimler.length);
    final d = _dilimler[idx];
    return {
      'success': true,
      'dilimIndex': idx,
      'dilim': {
        'tip': d.tip,
        'baslik': d.ismi,
        'ismi': d.ismi,
      },
      'odulKodu': (d.tip == 'bos' || d.tip == 'tekrar_dene')
          ? null
          : 'TEST-${random.nextInt(99999).toString().padLeft(5, '0')}',
      'kalanHak': _kalanHak,
    };
  }

  // Çark dönerken her dilim sınırını geçince webteki "tık" hissini ver.
  void _maybeTick() {
    if (!_isSpinning) return;
    final n = _dilimler.length;
    if (n < 2) return;
    final sector = (2 * pi) / n;
    final delta = (_angle - _lastTickAngle).abs();
    _lastTickAngle = _angle;
    _tickAcc += delta;
    while (_tickAcc >= sector) {
      _tickAcc -= sector;
      SystemSound.play(SystemSoundType.click);
      HapticFeedback.selectionClick();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _spinWheel() async {
    if (_isSpinning) return;
    // TEST MODU: _aktif kontrolü kaldırıldı (mock dilimlerle her durumda dönsün)
    if (_dilimler.length < 2) return;
    // TEST MODU: günlük sınır ve hak kontrolü geçici olarak kaldırıldı.
    // if (_kalanHak < 1 || _bugunCevirdi) return;

    setState(() {
      _isSpinning = true;
    });

    Map<String, dynamic> data;
    try {
      data = await carkCevir(_salonId, widget.md.id.toString());
      // TEST MODU: backend reddederse lokal random sonuç ile devam
      if (data['success'] != true) {
        data = _mockSpinResult();
      }
    } catch (e) {
      // TEST MODU: bağlantı hatasında lokal mock
      data = _mockSpinResult();
    }

    final dilimIndex = (data['dilimIndex'] is int)
        ? data['dilimIndex'] as int
        : int.tryParse(data['dilimIndex'].toString()) ?? 0;
    final dilim = data['dilim'] as Map<String, dynamic>? ?? {};
    final odulKodu = data['odulKodu']?.toString();
    final kalanHak = (data['kalanHak'] is int)
        ? data['kalanHak'] as int
        : int.tryParse(data['kalanHak'].toString()) ?? 0;

    // Hedef açı — pointer üstte (top), 0 derece sağda; "yukarıyı" -pi/2 hedefine çek
    final n = _dilimler.length;
    final sectorAngle = 2 * pi / n;
    final random = Random();
    final jitter = (random.nextDouble() - 0.5) * sectorAngle * 0.6;
    // Dilim merkezinin başlangıç açısı (saat 12 referansıyla, saat yönünde):
    final targetSectorMid = (dilimIndex + 0.5) * sectorAngle;
    // Çark saat yönünün tersine dönüyor — final açı, dilim'i pointer'a (üstte) getirmeli.
    // _angle pozitif → counter-clockwise. Yukarıyı -pi/2'ye getiriyoruz.
    final extraSpins = (12 + random.nextInt(5)) * 2 * pi;
    final endAngle = extraSpins + (2 * pi - targetSectorMid) + jitter;

    // Tick akümülatörünü spin başında sıfırla
    _lastTickAngle = _angle;
    _tickAcc = 0.0;

    _controller.reset();
    _animation = Tween<double>(begin: _angle, end: _angle + endAngle).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Cubic(0.17, 0.67, 0.12, 0.99),
      ),
    )
      ..addListener(() {
        setState(() => _angle = _animation.value);
        _maybeTick();
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          // Bitiş: webteki "kutlama" karşılığı — güçlü haptik + sistem alert
          HapticFeedback.heavyImpact();
          SystemSound.play(SystemSoundType.alert);
          Future.delayed(const Duration(milliseconds: 400), () {
            if (!mounted) return;
            setState(() {
              _kalanHak = kalanHak;
              // TEST MODU: bugün çevirdi flag'i set edilmiyor, sürekli çevrilebilsin.
              // _bugunCevirdi = true;
              _isSpinning = false;
            });
            _showWinDialog(dilim, odulKodu);
          });
        }
      });
    _controller.forward();
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFE17055),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showWinDialog(Map<String, dynamic> dilim, String? odulKodu) {
    final tip = (dilim['tip'] ?? '').toString();
    final baslik = (dilim['baslik'] ?? dilim['ismi'] ?? 'Ödül').toString();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: _ResultCard(
            tip: tip,
            baslik: baslik,
            odulKodu: odulKodu,
            onClose: () => Navigator.pop(ctx),
            onMyRewards: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OdullerimPage(md: widget.md),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 520;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FF),
      appBar: AppBar(
        title: const Text('🎡 Çarkıfelek', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF6C5CE7),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Kuponlarım',
            icon: const Icon(Icons.card_giftcard, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OdullerimPage(md: widget.md),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Puan Ödüllerim',
            icon: const Icon(Icons.stars, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PuanOdullerimPage(md: widget.md, salonId: _salonId),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? _buildError()
              : !_aktif
                  ? _buildPasif()
                  : RefreshIndicator(
                      onRefresh: _yukle,
                      color: const Color(0xFF6C5CE7),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmall ? 12 : 20,
                          vertical: 16,
                        ),
                        child: Column(
                          children: [
                            _buildHero(isSmall),
                            const SizedBox(height: 16),
                            _buildWheel(isSmall),
                            const SizedBox(height: 20),
                            _buildSpinButton(),
                            const SizedBox(height: 16),
                            _buildHakInfo(),
                            const SizedBox(height: 16),
                            _buildLinks(),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(_loadError ?? '', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _yukle, child: const Text('Tekrar Dene')),
          ],
        ),
      ),
    );
  }

  Widget _buildPasif() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎡', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 12),
            const Text(
              'Bu salonda çarkıfelek şu an aktif değil.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              _salonAdi,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(bool isSmall) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE), Color(0xFFFD79A8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C5CE7).withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            _salonAdi.isEmpty ? 'Çarkıfelek' : _salonAdi,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Text(
            'Size özel ödüller bekliyor!',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              border: Border.all(color: Colors.white.withOpacity(0.25)),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.casino, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                const Text(
                  'Çevirme hakkınız: ',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
                Text(
                  '$_kalanHak',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWheel(bool isSmall) {
    final size = isSmall
        ? MediaQuery.of(context).size.width * 0.82
        : 360.0;

    return SizedBox(
      width: size,
      height: size + 40,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Pointer
          Positioned(
            top: 0,
            child: Container(
              width: 30,
              height: 44,
              alignment: Alignment.center,
              child: CustomPaint(
                size: const Size(28, 40),
                painter: _PointerPainter(),
              ),
            ),
          ),
          Positioned(
            top: 28,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const SweepGradient(
                  colors: [
                    Color(0xFF6C5CE7),
                    Color(0xFFA29BFE),
                    Color(0xFFFD79A8),
                    Color(0xFFFDCB6E),
                    Color(0xFF00B894),
                    Color(0xFF6C5CE7),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C5CE7).withOpacity(0.35),
                    blurRadius: 30,
                    spreadRadius: 4,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(7),
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF160630),
                  shape: BoxShape.circle,
                ),
                child: Transform.rotate(
                  angle: _angle,
                  child: CustomPaint(
                    painter: _WheelPainter(_dilimler),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpinButton() {
    // TEST MODU: _kalanHak < 1 ve _bugunCevirdi engelleri kaldırıldı, buton hep aktif.
    final disabled = _isSpinning;
    final label = _isSpinning ? 'Çevriliyor...' : '🎲 Çarkı Çevir';

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: disabled ? null : _spinWheel,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE17055),
          disabledBackgroundColor: Colors.grey.shade400,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
          elevation: 6,
          shadowColor: const Color(0xFFE17055).withOpacity(0.5),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }

  Widget _buildHakInfo() {
    String mesaj;
    if (_bugunCevirdi) {
      mesaj = 'Bugün çarkıfeleği çevirdiniz.\n'
          'Bir sonraki çevirme: ${_yarinSaat.isEmpty ? 'yarın' : _yarinSaat} '
          'veya yeni onaylı randevunuzdan sonra.';
    } else if (_kalanHak > 0) {
      mesaj =
          '$_kalanHak çevirme hakkınız var. Günde 1 kez çevirebilirsiniz; yeni onaylı randevularınız yeni hak kazandırır.';
    } else {
      mesaj =
          'Çevirme hakkınız bulunmuyor. Salonumuzda randevu alıp onaylatırsanız hak kazanırsınız.';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(
        mesaj,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 13, color: Color(0xFF636E72), height: 1.45),
      ),
    );
  }

  Widget _buildLinks() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.card_giftcard, size: 18),
            label: const Text('Kuponlarım'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF6C5CE7),
              side: const BorderSide(color: Color(0xFF6C5CE7)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => OdullerimPage(md: widget.md)),
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.stars, size: 18),
            label: const Text('Puan Ödüllerim'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFE17055),
              side: const BorderSide(color: Color(0xFFE17055)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PuanOdullerimPage(md: widget.md, salonId: _salonId),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/* ───────── Backend dilim modeli ───────── */
class _Dilim {
  final int id;
  final String ismi;
  final Color renk;
  final String tip;
  final double? deger;
  final int sira;

  _Dilim({
    required this.id,
    required this.ismi,
    required this.renk,
    required this.tip,
    required this.deger,
    required this.sira,
  });

  factory _Dilim.fromJson(Map<String, dynamic> j) {
    return _Dilim(
      id: (j['id'] is int) ? j['id'] as int : int.tryParse(j['id'].toString()) ?? 0,
      ismi: (j['ismi'] ?? '').toString(),
      renk: _hexToColor((j['renk'] ?? '#6C5CE7').toString()),
      tip: (j['tip'] ?? 'bos').toString(),
      deger: j['deger'] == null ? null : double.tryParse(j['deger'].toString()),
      sira: (j['sira'] is int) ? j['sira'] as int : int.tryParse(j['sira'].toString()) ?? 0,
    );
  }

  String get kisaEtiket {
    switch (tip) {
      case 'puan':            return 'Puan';
      case 'hizmet_indirimi': return 'Hizmet İnd.';
      case 'urun_indirimi':   return 'Ürün İnd.';
      case 'tekrar_dene':     return 'Tekrar Dene';
      case 'bos':             return 'Boş';
      default:                return ismi;
    }
  }

  String? get rakamEtiket {
    if (deger == null) return null;
    if (tip == 'hizmet_indirimi' || tip == 'urun_indirimi') {
      return '%${deger!.toInt()}';
    }
    if (tip == 'puan') return '${deger!.toInt()}';
    return null;
  }
}

Color _hexToColor(String hex) {
  String h = hex.replaceAll('#', '').trim();
  if (h.length == 6) h = 'FF$h';
  return Color(int.tryParse(h, radix: 16) ?? 0xFF6C5CE7);
}

/* ───────── Painters ───────── */

class _WheelPainter extends CustomPainter {
  final List<_Dilim> dilimler;
  _WheelPainter(this.dilimler);

  @override
  void paint(Canvas canvas, Size size) {
    if (dilimler.isEmpty) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final n = dilimler.length;
    final sectorAngle = 2 * pi / n;

    final stroke = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int i = 0; i < n; i++) {
      // Pointer üstte (saat 12). 0 derece referans -pi/2 (üst).
      // Dilim i, üstte başlasın → start = -pi/2 + i*sector
      final startAngle = -pi / 2 + i * sectorAngle;
      final paint = Paint()
        ..color = dilimler[i].renk
        ..style = PaintingStyle.fill;

      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(
          center.dx + radius * cos(startAngle),
          center.dy + radius * sin(startAngle),
        )
        ..arcTo(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          sectorAngle,
          false,
        )
        ..close();

      canvas.drawPath(path, paint);
      canvas.drawPath(path, stroke);

      _drawText(canvas, center, radius, startAngle, sectorAngle, dilimler[i], n);
    }

    // Inner cap
    final cap = Paint()..color = const Color(0xFF160630);
    canvas.drawCircle(center, radius * 0.12, cap);
    canvas.drawCircle(
      center,
      radius * 0.12,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  void _drawText(
    Canvas canvas,
    Offset center,
    double radius,
    double startAngle,
    double sectorAngle,
    _Dilim d,
    int n,
  ) {
    final midAngle = startAngle + sectorAngle / 2;
    final hasDeger = d.rakamEtiket != null;

    if (hasDeger) {
      // Rakam — dış kenara, teğet hizalı, beyaz
      final numFs = n <= 8 ? 17.0 : 14.0;
      final catFs = n <= 8 ? 11.0 : 9.0;
      final numDist = radius - (n <= 8 ? 18 : 15);
      final nx = center.dx + numDist * cos(midAngle);
      final ny = center.dy + numDist * sin(midAngle);

      canvas.save();
      canvas.translate(nx, ny);
      canvas.rotate(midAngle + pi / 2);
      _paintText(
        canvas,
        d.rakamEtiket!,
        Offset.zero,
        TextStyle(
          color: Colors.white,
          fontSize: numFs,
          fontWeight: FontWeight.w900,
          shadows: const [
            Shadow(color: Color(0xCC000000), blurRadius: 3, offset: Offset(1, 1)),
          ],
        ),
      );
      canvas.restore();

      // Kategori
      final catDist = n <= 8 ? radius * 0.45 : radius * 0.4;
      final cx = center.dx + catDist * cos(midAngle);
      final cy = center.dy + catDist * sin(midAngle);
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(midAngle + pi / 2);
      _paintText(
        canvas,
        d.kisaEtiket,
        Offset.zero,
        TextStyle(
          color: Colors.white.withOpacity(0.92),
          fontSize: catFs,
          fontWeight: FontWeight.w700,
          shadows: const [
            Shadow(color: Color(0x99000000), blurRadius: 2, offset: Offset(0.5, 0.5)),
          ],
        ),
      );
      canvas.restore();
    } else {
      final dist = n <= 8 ? radius * 0.55 : radius * 0.48;
      final fs = n <= 8 ? 12.0 : 10.0;
      final tx = center.dx + dist * cos(midAngle);
      final ty = center.dy + dist * sin(midAngle);
      canvas.save();
      canvas.translate(tx, ty);
      canvas.rotate(midAngle + pi / 2);
      _paintText(
        canvas,
        d.kisaEtiket,
        Offset.zero,
        TextStyle(
          color: Colors.white,
          fontSize: fs,
          fontWeight: FontWeight.w700,
          shadows: const [
            Shadow(color: Color(0x99000000), blurRadius: 2, offset: Offset(0.5, 0.5)),
          ],
        ),
      );
      canvas.restore();
    }
  }

  void _paintText(Canvas canvas, String text, Offset offset, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: 2,
      ellipsis: '…',
    )..layout(maxWidth: 100);
    tp.paint(canvas, Offset(offset.dx - tp.width / 2, offset.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _WheelPainter oldDelegate) =>
      oldDelegate.dilimler != dilimler;
}

class _PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF7F1D1D), Color(0xFFEF4444), Color(0xFFFCA5A5), Color(0xFF7F1D1D)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, size.height * 0.18)
      ..lineTo(size.width, size.height * 0.18)
      ..close();
    canvas.drawPath(path, paint);
    final cap = Paint()..color = const Color(0xFFFBBF24);
    canvas.drawCircle(Offset(size.width / 2, size.height), 4, cap);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/* ───────── Result Card ───────── */

class _ResultCard extends StatelessWidget {
  final String tip;
  final String baslik;
  final String? odulKodu;
  final VoidCallback onClose;
  final VoidCallback onMyRewards;

  const _ResultCard({
    required this.tip,
    required this.baslik,
    required this.odulKodu,
    required this.onClose,
    required this.onMyRewards,
  });

  @override
  Widget build(BuildContext context) {
    final isPrize = odulKodu != null && odulKodu!.isNotEmpty;
    final emoji = tip == 'tekrar_dene'
        ? '🍀'
        : tip == 'bos'
            ? '🌟'
            : '🎉';

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 24),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 56)),
          const SizedBox(height: 8),
          Text(
            tip == 'bos'
                ? 'Bu sefer olmadı'
                : tip == 'tekrar_dene'
                    ? 'Tekrar Dene'
                    : 'Tebrikler!',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2D3436),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            tip == 'puan'
                ? 'Puan kazandınız:'
                : tip == 'bos' || tip == 'tekrar_dene'
                    ? ''
                    : 'Kazandığınız ödül:',
            style: const TextStyle(fontSize: 13, color: Color(0xFF636E72)),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEEF2FF), Color(0xFFFEF3C7)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              baslik,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF6C5CE7),
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (isPrize) ...[
            const SizedBox(height: 12),
            Column(
              children: [
                const Text(
                  'Kupon Kodunuz',
                  style: TextStyle(fontSize: 12, color: Color(0xFF636E72)),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFF59E0B),
                      style: BorderStyle.solid,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    odulKodu!,
                    style: const TextStyle(
                      color: Color(0xFF92400E),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Bu kodu 30 gün içinde salonda kullanabilirsiniz.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Color(0xFF636E72)),
                ),
              ],
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              if (isPrize)
                Expanded(
                  child: OutlinedButton(
                    onPressed: onMyRewards,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF6C5CE7),
                      side: const BorderSide(color: Color(0xFF6C5CE7)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                    ),
                    child: const Text('Kuponlarım'),
                  ),
                ),
              if (isPrize) const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: onClose,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C5CE7),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                  ),
                  child: const Text('Tamam'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

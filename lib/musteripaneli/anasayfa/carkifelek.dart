import 'dart:math';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart'; // pubspec.yaml'a eklemeyi unutmayın

class WheelPage extends StatefulWidget {
  const WheelPage({super.key});

  @override
  State<WheelPage> createState() => _WheelPageState();
}

class _WheelPageState extends State<WheelPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _angle = 0.0;
  bool _isSpinning = false;
  String _result = 'Şansını Dene!';
  String _resultDescription = 'Çarkı çevir ve harika ödüller kazan';
  Color _resultColor = const Color(0xFFFF416C);

  // Ses değişkenleri - Sadece çark dönüş sesi için
  final AudioPlayer _spinPlayer = AudioPlayer();
  bool _isSoundLoaded = false;
  bool _isSoundPlaying = false;

  final List<WheelItem> _wheelItems = [
    WheelItem(
        'PREMIUM %30',
        const Color(0xFFFF1744),
        'Premium ürünlerde geçerli\nKupon kodu: PREM30',
        Icons.diamond_outlined,
        1.0),
    WheelItem(
        'HEDIYE ÜRÜN',
        const Color(0xFF00FFA3),
        '50 TL değerinde hediye\nSon kullanım: 30 gün',
        Icons.card_giftcard_outlined,
        1.0),
    WheelItem(
        'BEDAVA KARGO',
        const Color(0xFFFF9800),
        'Sınırsız kullanım\nTüm siparişlerde geçerli',
        Icons.local_shipping_outlined,
        0.95),
    WheelItem(
        'VIP %50 İNDİRİM',
        const Color(0xFF00B0FF),
        'VIP müşteri özel indirimi\nSadece bugün!',
        Icons.star_outline,
        1.0),
    WheelItem(
        'İLK ALIŞVERİŞ %25',
        const Color(0xFF18FFFF),
        'Yeni müşterilere özel\nMin. 100 TL alışveriş',
        Icons.shopping_bag_outlined,
        0.95),
    WheelItem(
        'TEK KULLANIM 100 TL',
        const Color(0xFFFF00FF),
        '200 TL üzeri alışverişte\nHemen kullan',
        Icons.monetization_on_outlined,
        0.9),
    WheelItem(
        '2 AL 1 ÖDE',
        const Color(0xFFD500FF),
        'Seçili ürünlerde\nKampanya ürünleri',
        Icons.tag_faces_outlined,
        1.0),
    WheelItem(
        'ŞANSLI %20',
        const Color(0xFF651FFF),
        'Tüm ürünlerde geçerli\nHerkese açık',
        Icons.celebration_outlined,
        1.0),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSounds();

    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.fastOutSlowIn,
    );
  }

  Future<void> _loadSounds() async {
    try {
      // Çark dönüş sesini yükle
      await _spinPlayer.setSource(AssetSource('sounds/carkifelek.mp3'));
      await _spinPlayer.setReleaseMode(ReleaseMode.loop);
      await _spinPlayer.setVolume(0.7);

      _isSoundLoaded = true;
      debugPrint('Ses başarıyla yüklendi');
    } catch (e) {
      debugPrint('Ses yüklenirken hata: $e');
      _isSoundLoaded = false;
    }
  }

  void _playSpinSound() async {
    if (!_isSoundLoaded || _isSoundPlaying) return;

    try {
      _isSoundPlaying = true;
      await _spinPlayer.resume();
    } catch (e) {
      debugPrint('Spin ses çalınırken hata: $e');
      _isSoundPlaying = false;
    }
  }

  void _stopSpinSound() async {
    if (!_isSoundLoaded || !_isSoundPlaying) return;

    try {
      _isSoundPlaying = false;
      // Timeout hatasını önlemek için pause ve seek işlemlerini ayrı ayrı dene
      await _spinPlayer.pause().timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          debugPrint('Ses durdurma timeout - devam ediliyor');
          // Timeout durumunda sessizce devam et
        },
      );

      // Seek işlemini ayrıca dene
      try {
        await _spinPlayer.seek(Duration.zero).timeout(
          const Duration(seconds: 2),
          onTimeout: () {
            debugPrint('Seek timeout - devam ediliyor');
          },
        );
      } catch (seekError) {
        debugPrint('Seek hatası: $seekError');
      }

    } catch (e) {
      debugPrint('Spin ses durdurulurken hata: $e');
      _isSoundPlaying = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();

    // dispose sırasında sesi durdur
    try {
      _spinPlayer.stop();
      _spinPlayer.dispose();
    } catch (e) {
      debugPrint('Dispose sırasında hata: $e');
    }

    super.dispose();
  }

  @override
  void didChangeMetrics() {
    setState(() {});
  }

  void _spinWheel() {
    if (_isSpinning) return;

    setState(() {
      _isSpinning = true;
      _result = 'Şans Çarkı Dönüyor...';
      _resultDescription = 'Ödülünüz belirleniyor';
      _resultColor = const Color(0xFFFF9800);
    });

    // Çark dönüş sesini başlat
    _playSpinSound();

    final random = Random();
    final extraAngle = random.nextDouble() * 2 * pi;
    final totalAngle = (12 * 2 * pi) + extraAngle + _angle;

    _controller.reset();
    _animation = Tween<double>(
      begin: _angle,
      end: totalAngle,
    ).animate(_controller)
      ..addListener(() => setState(() => _angle = _animation.value))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _stopSpinSound(); // Çark sesini durdur
          Future.delayed(const Duration(milliseconds: 500), () {
            _determineResult(totalAngle);
          });
        }
      });

    _controller.forward();
  }

  void _determineResult(double totalAngle) {
    final sectorAngle = 2 * pi / _wheelItems.length;
    double normalizedAngle = totalAngle % (2 * pi);
    int index = _wheelItems.length -
        ((normalizedAngle ~/ sectorAngle) % _wheelItems.length) -
        1;

    index = index.clamp(0, _wheelItems.length - 1);
    final wonItem = _wheelItems[index];

    setState(() {
      _isSpinning = false;
      _result = '🎉 TEBRİKLER!';
      _resultColor = wonItem.color;
      _resultDescription = '${wonItem.title} kazandınız!';
    });

    _showWinDialog(wonItem);
  }

  void _showWinDialog(WheelItem item) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) {
        return FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: ModalRoute.of(context)!.animation!,
              curve: Curves.easeOutCubic,
            ),
          ),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(
              CurvedAnimation(
                parent: ModalRoute.of(context)!.animation!,
                curve: Curves.elasticOut,
              ),
            ),
            child: Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              insetPadding: const EdgeInsets.all(20),
              child: WinDialogContent(item: item),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    final isLargeScreen = size.width > 900;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              const Color(0xFFF5F5F5),
              const Color(0xFFEEEEEE),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: isSmallScreen ? 100 : 120,
                floating: true,
                pinned: true,
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                leading: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: IconButton(
                    icon: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFF416C),
                            Color(0xFF651FFF),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  titlePadding: EdgeInsets.only(
                    bottom: isSmallScreen ? 12 : 16,
                  ),
                  title: Text(
                    'ŞANS ÇARKI',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 20 : 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.grey[600],
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                actions: [
                  Container(
                    margin: EdgeInsets.only(right: isSmallScreen ? 16 : 24),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFFFF416C),
                          Color(0xFF00B0FF),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.info_outline, color: Colors.white),
                      onPressed: () {
                        _showInfoDialog();
                      },
                    ),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 16 : 24,
                    vertical: 24,
                  ),
                  child: Column(
                    children: [
                      _buildWheelSection(isSmallScreen, isLargeScreen),
                      const SizedBox(height: 32),
                      _buildResultIndicator(isLargeScreen),
                      const SizedBox(height: 32),
                      _buildSpinButton(isSmallScreen),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 40),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWheelSection(bool isSmallScreen, bool isLargeScreen) {
    final wheelSize = isSmallScreen
        ? MediaQuery.of(context).size.width * 0.85
        : isLargeScreen
        ? 400
        : 320;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF416C).withOpacity(0.1),
            blurRadius: 40,
            spreadRadius: 10,
          ),
          BoxShadow(
            color: const Color(0xFF18FFFF).withOpacity(0.1),
            blurRadius: 60,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: wheelSize * 1.1,
            height: wheelSize * 1.1,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
          ),
          Transform.rotate(
            angle: _angle,
            child: Container(
              width: wheelSize * 1,
              height: wheelSize * 1,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: CustomPaint(
                painter: HorizontalTextWheelPainter(_wheelItems, wheelSize * 1),
              ),
            ),
          ),
          Positioned(
            top: -10,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              transform: _isSpinning
                  ? Matrix4.rotationZ(sin(_angle * 0.1) * 0.02)
                  : Matrix4.rotationZ(0),
              child: Container(
                width: 50,
                height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFF1744),
                      Color(0xFFFF9800),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(25),
                    bottomRight: Radius.circular(25),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_drop_down,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: wheelSize * 0.25,
            height: wheelSize * 0.25,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(_isSpinning ? 0.3 : 0.2),
                  blurRadius: _isSpinning ? 30 : 25,
                  spreadRadius: _isSpinning ? 10 : 5,
                ),
              ],
            ),
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: wheelSize * 0.18,
                height: wheelSize * 0.18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFF416C),
                      Color(0xFF651FFF),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF416C).withOpacity(_isSpinning ? 0.6 : 0.4),
                      blurRadius: _isSpinning ? 30 : 20,
                      spreadRadius: _isSpinning ? 10 : 5,
                    ),
                  ],
                ),
                child: AnimatedRotation(
                  duration: const Duration(milliseconds: 200),
                  turns: _isSpinning ? _angle / (2 * pi) : 0,
                  child: const Icon(
                    Icons.star,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultIndicator(bool isLargeScreen) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
        border: Border.all(
          color: _resultColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: Text(
              _result,
              key: ValueKey(_result),
              style: TextStyle(
                fontSize: isLargeScreen ? 28 : 24,
                fontWeight: FontWeight.w800,
                color: _resultColor,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: Text(
              _resultDescription,
              key: ValueKey(_resultDescription),
              style: TextStyle(
                fontSize: isLargeScreen ? 16 : 14,
                color: Colors.black87,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpinButton(bool isSmallScreen) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isSmallScreen ? MediaQuery.of(context).size.width * 0.8 : 300,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: _isSpinning
            ? [
          BoxShadow(
            color: const Color(0xFFFF416C).withOpacity(0.3),
            blurRadius: 30,
            spreadRadius: 3,
          ),
        ]
            : [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        gradient: LinearGradient(
          colors: _isSpinning
              ? [const Color(0xFFFF1744), const Color(0xFFFF9800)]
              : [const Color(0xFFFF416C), const Color(0xFF651FFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(30),
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: _isSpinning ? null : _spinWheel,
          splashColor: Colors.white.withOpacity(0.3),
          highlightColor: Colors.white.withOpacity(0.1),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _isSpinning
                  ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'ÇARK DÖNÜYOR...',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              )
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.autorenew,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'ÇARKI ÇEVİR',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      barrierDismissible: true,
      builder: (context) {
        return FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: ModalRoute.of(context)!.animation!,
              curve: Curves.easeOutCubic,
            ),
          ),
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding: const EdgeInsets.all(20),
            child: InfoDialogContent(),
          ),
        );
      },
    );
  }
}

// WheelItem Model
class WheelItem {
  final String title;
  final Color color;
  final String description;
  final IconData icon;
  final double fontSizeMultiplier;

  WheelItem(this.title, this.color, this.description, this.icon,
      this.fontSizeMultiplier);
}

// HorizontalTextWheelPainter
class HorizontalTextWheelPainter extends CustomPainter {
  final List<WheelItem> items;
  final double wheelSize;

  HorizontalTextWheelPainter(this.items, this.wheelSize);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint();

    final sectorAngle = 2 * pi / items.length;
    final textRadius = radius * 0.65;
    final iconRadius = radius * 0.4;
    final baseFontSize = wheelSize * 0.03;

    for (int i = 0; i < items.length; i++) {
      final startAngle = i * sectorAngle - pi / 2;
      final endAngle = startAngle + sectorAngle;

      final gradient = SweepGradient(
        startAngle: startAngle,
        endAngle: endAngle,
        colors: [
          items[i].color.withOpacity(1.0),
          items[i].color.withOpacity(0.9),
          items[i].color.withOpacity(0.8),
          items[i].color.withOpacity(0.9),
          items[i].color.withOpacity(1.0),
        ],
        stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
      );

      paint.shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      );
      paint.style = PaintingStyle.fill;

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

      paint.shader = null;
      paint.color = Colors.white.withOpacity(0.8);
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 3;
      canvas.drawLine(
        center,
        Offset(
          center.dx + radius * cos(startAngle),
          center.dy + radius * sin(startAngle),
        ),
        paint,
      );

      final textAngle = startAngle + sectorAngle / 2;
      final fontSize = baseFontSize * items[i].fontSizeMultiplier;
      final text = items[i].title;

      final words = text.split(' ');
      final List<String> lines = [];
      String currentLine = '';

      for (final word in words) {
        if ((currentLine.isEmpty ? word : '$currentLine $word').length *
            fontSize <
            radius * 0.6) {
          currentLine = currentLine.isEmpty ? word : '$currentLine $word';
        } else {
          if (currentLine.isNotEmpty) {
            lines.add(currentLine);
          }
          currentLine = word;
        }
      }
      if (currentLine.isNotEmpty) {
        lines.add(currentLine);
      }

      canvas.save();
      final textX = center.dx + textRadius * cos(textAngle);
      final textY = center.dy + textRadius * sin(textAngle);

      canvas.translate(textX, textY);
      canvas.rotate(textAngle + pi / 2);

      final lineHeight = fontSize * 1.2;
      final totalHeight = lines.length * lineHeight;

      for (int lineIndex = 0; lineIndex < lines.length; lineIndex++) {
        final lineText = lines[lineIndex];
        final textPainter = TextPainter(
          text: TextSpan(
            text: lineText,
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.3),
                  offset: const Offset(1, 1),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
          textDirection: TextDirection.ltr,
          maxLines: 1,
          ellipsis: '...',
        );

        textPainter.layout();
        final lineY =
            -totalHeight / 2 + (lineIndex * lineHeight) + lineHeight / 2;

        textPainter.paint(
          canvas,
          Offset(-textPainter.width / 2, lineY - textPainter.height / 2),
        );
      }

      canvas.restore();

      final iconX = center.dx + iconRadius * cos(textAngle);
      final iconY = center.dy + iconRadius * sin(textAngle);

      final iconSize = fontSize * 1.8;
      final iconPainter = TextPainter(
        textDirection: TextDirection.ltr,
        text: TextSpan(
          text: String.fromCharCode(items[i].icon.codePoint),
          style: TextStyle(
            fontFamily: items[i].icon.fontFamily,
            color: Colors.white,
            fontSize: iconSize,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3),
                offset: const Offset(1, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ),
      );

      iconPainter.layout();
      iconPainter.paint(
        canvas,
        Offset(
          iconX - iconPainter.width / 2,
          iconY - iconPainter.height / 2,
        ),
      );
    }

    paint.shader = RadialGradient(
      colors: [
        Colors.white,
        Colors.grey.shade300,
      ],
    ).createShader(Rect.fromCircle(center: center, radius: radius * 0.15));
    paint.style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.15, paint);

    paint.shader = null;
    paint.color = Colors.black.withOpacity(0.3);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 4;
    canvas.drawCircle(center, radius * 0.15, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// InfoDialogContent
class InfoDialogContent extends StatefulWidget {
  @override
  State<InfoDialogContent> createState() => _InfoDialogContentState();
}

class _InfoDialogContentState extends State<InfoDialogContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 1.0, curve: Curves.elasticOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 50,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFFF416C),
                    Color(0xFF00B0FF),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.info_outline,
                      color: Color(0xFFFF416C),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nasıl Çalışır?',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Şans çarkını kullanmak çok kolay',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildInfoStep(
                    '1',
                    'Çarkı Çevir',
                    'Çarkı çevir butonuna bas ve şansını dene',
                    Icons.play_circle_outline,
                    const Color(0xFFFF416C),
                  ),
                  const SizedBox(height: 20),
                  _buildInfoStep(
                    '2',
                    'Ödülünü Kazan',
                    'İşaretçinin gösterdiği ödül senin olacak',
                    Icons.celebration_outlined,
                    const Color(0xFF00B0FF),
                  ),
                  const SizedBox(height: 20),
                  _buildInfoStep(
                    '3',
                    'Kuponunu Kullan',
                    'Kazandığın kuponları alışverişinde kullan',
                    Icons.shopping_cart_outlined,
                    const Color(0xFF00FFA3),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 24),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFF416C),
                          Color(0xFF651FFF),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF416C).withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline,
                            color: Colors.white, size: 22),
                        SizedBox(width: 10),
                        Text(
                          'ANLADIM',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoStep(String number, String title, String subtitle,
      IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: color, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// WinDialogContent
class WinDialogContent extends StatefulWidget {
  final WheelItem item;

  const WinDialogContent({required this.item});

  @override
  State<WinDialogContent> createState() => _WinDialogContentState();
}

class _WinDialogContentState extends State<WinDialogContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
      ),
    );

    _rotateAnimation = Tween<double>(begin: -0.2, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.9, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.rotate(
              angle: _rotateAnimation.value,
              child: child,
            ),
          ),
        );
      },
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 50,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Ana içerik
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          widget.item.color,
                          widget.item.color.withOpacity(0.8),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.celebration,
                            color: widget.item.color,
                            size: 50,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          '🎉 TEBRİKLER 🎉',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1.5,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Harika bir ödül kazandınız!',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Text(
                          widget.item.title,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: widget.item.color,
                            height: 1.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.item.description,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: widget.item.color.withOpacity(0.3),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(
                                'KUPON KODUNUZ',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade600,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'SH${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                  letterSpacing: 3,
                                  fontFamily: 'Courier',
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Son kullanım: ${DateTime.now().add(const Duration(days: 30)).day.toString().padLeft(2, '0')}/${DateTime.now().add(const Duration(days: 30)).month.toString().padLeft(2, '0')}/${DateTime.now().add(const Duration(days: 30)).year}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),

              // Çarpı butonu
              Positioned(
                top: 10,
                right: 10,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Modern barkod tarayıcı — mobile_scanner üzerine ince bir kabuk.
///
/// İki kullanım modu:
///  - **tekSeferlik:** İlk barkod yakalandığında pop eder ve değeri döndürür.
///  - **surekli:** Her okunan kod `onKod` callback'ine düşer, ekran açık kalır
///    (ör. hızlı satışta seri okuma, sayımda).
class BarkodTarayici extends StatefulWidget {
  final String baslik;
  final bool surekli;
  final void Function(String kod)? onKod;

  const BarkodTarayici({
    Key? key,
    this.baslik = 'Barkod Tara',
    this.surekli = false,
    this.onKod,
  }) : super(key: key);

  /// Pratik kısayol: bir barkod yakala ve geri dön (null = iptal).
  static Future<String?> tekSeferTara(BuildContext context, {String baslik = 'Barkod Tara'}) async {
    return Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => BarkodTarayici(baslik: baslik)),
    );
  }

  @override
  State<BarkodTarayici> createState() => _BarkodTarayiciState();
}

class _BarkodTarayiciState extends State<BarkodTarayici> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    formats: const [],
  );
  String? _sonOkunan;
  DateTime _sonZaman = DateTime.fromMillisecondsSinceEpoch(0);
  bool _flash = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onAlgila(BarcodeCapture capture) {
    if (capture.barcodes.isEmpty) return;
    final String? kod = capture.barcodes.first.rawValue;
    if (kod == null || kod.isEmpty) return;

    // Aynı kodu çok hızlı tekrar okumayı engelle (1.5sn debounce)
    final simdi = DateTime.now();
    if (kod == _sonOkunan && simdi.difference(_sonZaman).inMilliseconds < 1500) return;
    _sonOkunan = kod;
    _sonZaman = simdi;

    if (widget.surekli) {
      widget.onKod?.call(kod);
    } else {
      Navigator.of(context).pop(kod);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.baslik),
        actions: [
          IconButton(
            icon: Icon(_flash ? Icons.flash_on : Icons.flash_off),
            onPressed: () {
              setState(() => _flash = !_flash);
              _controller.toggleTorch();
            },
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onAlgila),
          // Hedef çerçevesi
          Center(
            child: Container(
              width: 260,
              height: 160,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF6A1B9A), width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          if (widget.surekli)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                color: Colors.black.withValues(alpha: 0.55),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: const Text(
                  'Sürekli tarama açık — kodları arka arkaya okutabilirsin.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

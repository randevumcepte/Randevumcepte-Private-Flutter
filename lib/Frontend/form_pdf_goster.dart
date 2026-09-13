// form_pdf_goster.dart
//
// Form/sozlesme PDF'ini uygulama icinde acan goruntuleyici.
// `printing` paketinin PdfPreview widget'i PDF'i render eder ve ayrica
// yazdirma (Yazdir) + paylasma/indirme aksiyonlarini hazir sunar.
// Dosya URL'den bytes olarak cekilir (uzanti zaten .pdf olmali).
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:printing/printing.dart';

class FormPdfGoster extends StatefulWidget {
  /// Tam dosya URL'i, orn: https://app.randevumcepte.com.tr/api/v1/formgoster?arsivid=1
  final String url;
  final String baslik;
  const FormPdfGoster({super.key, required this.url, required this.baslik});

  @override
  State<FormPdfGoster> createState() => _FormPdfGosterState();
}

class _FormPdfGosterState extends State<FormPdfGoster> {
  Uint8List? _bytes;
  String? _hata;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    try {
      final resp = await http.get(Uri.parse(widget.url));
      if (resp.statusCode == 200) {
        if (mounted) setState(() => _bytes = resp.bodyBytes);
      } else {
        if (mounted) setState(() => _hata = 'Dosya açılamadı (${resp.statusCode})');
      }
    } catch (e) {
      if (mounted) setState(() => _hata = 'Dosya açılamadı: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.baslik,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 16),
        ),
      ),
      body: _hata != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        size: 56, color: Colors.red),
                    const SizedBox(height: 12),
                    Text(_hata!, textAlign: TextAlign.center),
                  ],
                ),
              ),
            )
          : _bytes == null
              ? const Center(child: CircularProgressIndicator())
              : PdfPreview(
                  build: (format) async => _bytes!,
                  canChangePageFormat: false,
                  canChangeOrientation: false,
                  canDebug: false,
                  pdfFileName: widget.baslik,
                  // Alt aksiyon barini temayla uyumlu yap: koyu zemin + beyaz
                  // ikonlar (varsayilan mor/siyah ikonlar yerine).
                  actionBarTheme: PdfActionBarTheme(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    iconColor: Colors.white,
                    textStyle: const TextStyle(color: Colors.white),
                  ),
                ),
    );
  }
}

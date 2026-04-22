import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class MusteriOcrTara extends StatefulWidget {
  const MusteriOcrTara({Key? key}) : super(key: key);

  @override
  State<MusteriOcrTara> createState() => _MusteriOcrTaraState();
}

class _MusteriOcrTaraState extends State<MusteriOcrTara> {
  static const Color _renk = Color(0xFF6A1B9A);

  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _recognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  final TextEditingController _isimController = TextEditingController();
  final TextEditingController _telefonController = TextEditingController();
  final MaskTextInputFormatter _telefonMask = MaskTextInputFormatter(
    mask: '0### ### ## ##',
    filter: {'#': RegExp(r'[0-9]')},
  );

  File? _secilenGorsel;
  String _tumMetin = '';
  List<String> _isimAdaylari = [];
  List<String> _telefonAdaylari = [];
  String _bulunanEmail = '';
  String _bulunanDogumTarihi = '';
  String _bulunanCinsiyet = '';
  bool _isleniyor = false;

  @override
  void dispose() {
    _recognizer.close();
    _isimController.dispose();
    _telefonController.dispose();
    super.dispose();
  }

  Future<void> _gorselSec(ImageSource kaynak) async {
    try {
      final XFile? secilen = await _picker.pickImage(
        source: kaynak,
        imageQuality: 75,
        maxWidth: 1600,
      );
      if (secilen == null) return;

      CroppedFile? kirpilmis;
      try {
        kirpilmis = await ImageCropper().cropImage(
          sourcePath: secilen.path,
          compressFormat: ImageCompressFormat.jpg,
          compressQuality: 75,
          maxWidth: 1600,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Yazıyı Çerçevele',
              toolbarColor: _renk,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false,
            ),
            IOSUiSettings(
              title: 'Yazıyı Çerçevele',
              aspectRatioLockEnabled: false,
            ),
          ],
        );
      } catch (e) {
        log('cropper hatasi (orijinal kullaniliyor): $e');
      }

      final String yol = kirpilmis?.path ?? secilen.path;
      setState(() {
        _secilenGorsel = File(yol);
        _isleniyor = true;
        _tumMetin = '';
        _isimAdaylari = [];
        _telefonAdaylari = [];
      });

      await _metinTara(File(yol));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Görsel seçilemedi: $e')),
      );
    } finally {
      if (mounted) setState(() => _isleniyor = false);
    }
  }

  Future<void> _metinTara(File dosya) async {
    try {
      final InputImage girdi = InputImage.fromFile(dosya);
      final RecognizedText sonuc = await _recognizer.processImage(girdi);

      final String tumMetin = sonuc.text;

      // Önce yapısal form modu (etiketli alanlar) dene
      final Map<String, String>? form = _formModuOku(sonuc);
      List<String> telefonlar;
      List<String> isimler;
      Map<String, String> ekler;
      if (form != null) {
        isimler = form['isim']?.isNotEmpty == true ? [form['isim']!] : [];
        telefonlar =
            form['telefon']?.isNotEmpty == true ? [form['telefon']!] : [];
        ekler = {
          if ((form['email'] ?? '').isNotEmpty) 'email': form['email']!,
          if ((form['dogum_tarihi'] ?? '').isNotEmpty)
            'dogum_tarihi': form['dogum_tarihi']!,
          if ((form['cinsiyet'] ?? '').isNotEmpty)
            'cinsiyet': form['cinsiyet']!,
        };
      } else {
        telefonlar = _telefonAdaylariniBul(tumMetin);
        isimler = _isimAdaylariniBul(sonuc);
        ekler = _ekAlanlariCikar(tumMetin);
      }

      setState(() {
        _tumMetin = tumMetin;
        _telefonAdaylari = telefonlar;
        _isimAdaylari = isimler;
        _bulunanEmail = ekler['email'] ?? '';
        _bulunanDogumTarihi = ekler['dogum_tarihi'] ?? '';
        _bulunanCinsiyet = ekler['cinsiyet'] ?? '';
        if (isimler.isNotEmpty && _isimController.text.isEmpty) {
          _isimController.text = isimler.first;
        }
        if (telefonlar.isNotEmpty && _telefonController.text.isEmpty) {
          _telefonDoldur(telefonlar.first);
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Metin okunamadı: $e')),
      );
    }
  }

  List<String> _telefonAdaylariniBul(String metin) {
    final RegExp telefonRegex = RegExp(r'(\+?9?0?[\s\-\(\)]*5\d{2}[\s\-\(\)]*\d{3}[\s\-\(\)]*\d{2}[\s\-\(\)]*\d{2})');
    final Set<String> bulunan = {};
    for (final m in telefonRegex.allMatches(metin)) {
      final String sade = m.group(0)!.replaceAll(RegExp(r'\D'), '');
      String normalize = sade;
      if (normalize.startsWith('90') && normalize.length == 12) {
        normalize = '0${normalize.substring(2)}';
      }
      if (normalize.length == 10 && normalize.startsWith('5')) {
        normalize = '0$normalize';
      }
      if (normalize.length == 11 && normalize.startsWith('05')) {
        bulunan.add(normalize);
      }
    }
    return bulunan.toList();
  }

  List<String> _isimAdaylariniBul(RecognizedText sonuc) {
    final RegExp telefonIcerir = RegExp(r'\d{3,}');
    final RegExp sadeceHarf = RegExp(r"^[A-Za-zÇĞİıÖŞÜçğıöşü\s\.\-']+$");
    final List<String> adaylar = [];
    final Set<String> gorulen = {};

    for (final TextBlock blok in sonuc.blocks) {
      for (final TextLine satir in blok.lines) {
        final String temiz = satir.text.trim();
        if (temiz.length < 4 || temiz.length > 60) continue;
        if (telefonIcerir.hasMatch(temiz)) continue;
        if (!sadeceHarf.hasMatch(temiz)) continue;

        final List<String> kelimeler = temiz
            .split(RegExp(r'\s+'))
            .where((k) => k.length >= 2)
            .toList();
        if (kelimeler.length < 2) continue;

        final String formatli = kelimeler
            .map((k) => k.length <= 1
                ? k.toUpperCase()
                : '${k[0].toUpperCase()}${k.substring(1).toLowerCase()}')
            .join(' ');

        if (gorulen.add(formatli.toLowerCase())) {
          adaylar.add(formatli);
        }
      }
    }
    return adaylar;
  }

  void _telefonDoldur(String numara) {
    _telefonMask.clear();
    final String maskelenmis = _telefonMask.maskText(numara);
    _telefonController.text = maskelenmis;
  }

  void _onayla() {
    final String isim = _isimController.text.trim();
    final String telefon = _telefonController.text.trim();
    if (isim.isEmpty && telefon.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İsim veya telefon dolu olmalı')),
      );
      return;
    }
    Navigator.of(context).pop({
      'isim': isim,
      'telefon': telefon,
      'email': _bulunanEmail,
      'dogum_tarihi': _bulunanDogumTarihi,
      'cinsiyet': _bulunanCinsiyet,
    });
  }

  /// Yapısal formu (etiketli alanları) okumaya çalışır. Bulunamazsa null.
  /// Dönüş: { 'isim': ..., 'telefon': ..., 'email': ..., 'dogum_tarihi': ..., 'cinsiyet': ... }
  Map<String, String>? _formModuOku(RecognizedText sonuc) {
    final List<TextLine> tum = [];
    for (final blok in sonuc.blocks) {
      tum.addAll(blok.lines);
    }
    if (tum.length < 3) return null;
    tum.sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));

    final Map<String, RegExp> etiketler = {
      'isim': RegExp(
          r'(m[uü]şter[ıi]\s+ad[ıi]\s+soy[ıa]?d[ıi])|(ad[ıi]\s+soyad[ıi])|(ad\s+soyad)|(ad[ıi]\s+ve\s+soyad[ıi])|([ıi]s[ıi]m\s+soy[ıi]s[ıi]m)',
          caseSensitive: false),
      'telefon': RegExp(
          r'(cep\s*telefon[ıu]?)|(telefon\s*cep)|(telefon)|(gsm)|(cep\s*no)|(\btel\b)',
          caseSensitive: false),
      'email': RegExp(r'(e[\s\-]?mail)|(e[\s\-]?posta)|(\bmail\b)',
          caseSensitive: false),
      'dogum': RegExp(r'do[ğg]um(\s+tarih[ıi])?', caseSensitive: false),
      'cinsiyet': RegExp(r'c[ıi]ns[ıi]yet', caseSensitive: false),
    };

    final Map<String, String> bulunan = {};
    for (final field in etiketler.keys) {
      final reg = etiketler[field]!;
      TextLine? etiketSatiri;
      Match? eslesme;
      for (final l in tum) {
        final m = reg.firstMatch(l.text);
        if (m != null) {
          etiketSatiri = l;
          eslesme = m;
          break;
        }
      }
      if (etiketSatiri == null) continue;

      String value = etiketSatiri.text.substring(eslesme!.end);
      value = value.replaceFirst(RegExp(r'^[\s:.\-]+'), '').trim();

      if (value.isEmpty) {
        final lblBox = etiketSatiri.boundingBox;
        final yMid = lblBox.center.dy;
        final tol = lblBox.height * 0.8;
        final List<TextLine> sag = tum.where((l) {
          if (l == etiketSatiri) return false;
          final c = l.boundingBox.center.dy;
          if ((c - yMid).abs() > tol) return false;
          if (l.boundingBox.left < lblBox.right - 2) return false;
          return true;
        }).toList();
        sag.sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));

        final List<String> kelimeler = [];
        for (final s in sag) {
          bool baskaEtiket = false;
          for (final e in etiketler.entries) {
            if (e.key == field) continue;
            if (e.value.hasMatch(s.text)) {
              baskaEtiket = true;
              break;
            }
          }
          if (baskaEtiket) break;
          kelimeler.add(s.text);
        }
        value = kelimeler.join(' ').trim();
      }

      if (value.isNotEmpty) bulunan[field] = value;
    }

    if (bulunan.isEmpty) return null;
    final isimRaw = bulunan['isim'] ?? '';
    final telRaw = bulunan['telefon'] ?? '';
    if (isimRaw.isEmpty && telRaw.isEmpty) return null;

    String isim = isimRaw
        .replaceAll(RegExp(r'[^A-Za-zÇĞİıÖŞÜçğıöşü\s\.\-]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final kelimeler = isim.split(' ').where((k) => k.length >= 2).toList();
    isim = kelimeler
        .map((k) =>
            '${k[0].toUpperCase()}${k.substring(1).toLowerCase()}')
        .join(' ');

    String telefon = '';
    final telM = RegExp(
            r'(\+?9?0?[\s\-\(\)]*5\d{2}[\s\-\(\)]*\d{3}[\s\-\(\)]*\d{2}[\s\-\(\)]*\d{2})')
        .firstMatch(telRaw);
    if (telM != null) {
      String n = telM.group(0)!.replaceAll(RegExp(r'\D'), '');
      if (n.startsWith('90') && n.length == 12) n = '0${n.substring(2)}';
      if (n.length == 10 && n.startsWith('5')) n = '0$n';
      if (n.length == 11 && n.startsWith('05')) telefon = n;
    }

    String email = '';
    final emRaw = bulunan['email'] ?? '';
    final emM = RegExp(r'[\w.+\-]+@[\w\-]+\.[\w.\-]+').firstMatch(emRaw);
    if (emM != null) email = emM.group(0)!;

    String dogum = '';
    final dRaw = bulunan['dogum'] ?? '';
    final dM = RegExp(r'\b(\d{1,2})[./\-](\d{1,2})[./\-](\d{2,4})\b')
        .firstMatch(dRaw);
    if (dM != null) {
      final d = int.tryParse(dM.group(1)!);
      final mo = int.tryParse(dM.group(2)!);
      int? y = int.tryParse(dM.group(3)!);
      if (d != null &&
          mo != null &&
          y != null &&
          d >= 1 &&
          d <= 31 &&
          mo >= 1 &&
          mo <= 12) {
        if (y < 100) y = y >= 30 ? 1900 + y : 2000 + y;
        if (y >= 1900 && y <= DateTime.now().year) {
          dogum =
              '${y.toString().padLeft(4, '0')}-${mo.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
        }
      }
    }

    String cinsiyet = '';
    final cRaw = bulunan['cinsiyet'] ?? '';
    if (cRaw.isNotEmpty) {
      final upper = cRaw.toUpperCase();
      for (int i = 0; i < upper.length; i++) {
        final ch = upper[i];
        if (ch == 'X' || ch == '✓' || ch == '☒' || ch == '⊠') {
          for (int j = i - 1; j >= 0 && j >= i - 6; j--) {
            if (upper[j] == 'K') {
              cinsiyet = '0';
              break;
            }
            if (upper[j] == 'E') {
              cinsiyet = '1';
              break;
            }
          }
          if (cinsiyet.isNotEmpty) break;
        }
      }
      if (cinsiyet.isEmpty) {
        final norm =
            cRaw.toLowerCase().replaceAll('ı', 'i').replaceAll('İ', 'i');
        if (RegExp(r'\b(kadin|bayan)\b').hasMatch(norm)) {
          cinsiyet = '0';
        } else if (RegExp(r'\b(erkek|bay)\b').hasMatch(norm)) {
          cinsiyet = '1';
        }
      }
    }

    return {
      'isim': isim,
      'telefon': telefon,
      'email': email,
      'dogum_tarihi': dogum,
      'cinsiyet': cinsiyet,
    };
  }

  Map<String, String> _ekAlanlariCikar(String metin) {
    final Map<String, String> sonuc = {};
    final emailM = RegExp(r'[\w.+\-]+@[\w\-]+\.[\w.\-]+').firstMatch(metin);
    if (emailM != null) sonuc['email'] = emailM.group(0)!;

    final dateRe = RegExp(r'\b(\d{1,2})[./\-](\d{1,2})[./\-](\d{2,4})\b');
    for (final m in dateRe.allMatches(metin)) {
      final d = int.tryParse(m.group(1)!);
      final mo = int.tryParse(m.group(2)!);
      int? y = int.tryParse(m.group(3)!);
      if (d == null ||
          mo == null ||
          y == null ||
          d < 1 ||
          d > 31 ||
          mo < 1 ||
          mo > 12) continue;
      if (y < 100) y = y >= 30 ? 1900 + y : 2000 + y;
      if (y < 1900 || y > DateTime.now().year) continue;
      sonuc['dogum_tarihi'] =
          '${y.toString().padLeft(4, '0')}-${mo.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
      break;
    }

    final norm =
        metin.toLowerCase().replaceAll('ı', 'i').replaceAll('İ', 'i');
    final gM = RegExp(r'\b(kadin|bayan|erkek|bay)\b').firstMatch(norm);
    if (gM != null) {
      final w = gM.group(1)!;
      if (w == 'kadin' || w == 'bayan') {
        sonuc['cinsiyet'] = '0';
      } else if (w == 'erkek' || w == 'bay') {
        sonuc['cinsiyet'] = '1';
      }
    }
    return sonuc;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Fotoğraftan Müşteri Tara',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.clear_rounded, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _kaynakSecimi(),
            const SizedBox(height: 15),
            if (_secilenGorsel != null) _gorselOnizleme(),
            if (_isleniyor)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (!_isleniyor && _tumMetin.isNotEmpty) _sonuclar(),
          ],
        ),
      ),
    );
  }

  Widget _kaynakSecimi() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed:
                _isleniyor ? null : () => _gorselSec(ImageSource.camera),
            icon: const Icon(Icons.camera_alt),
            label: const Text('Kamera'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _renk,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(45),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            onPressed:
                _isleniyor ? null : () => _gorselSec(ImageSource.gallery),
            icon: const Icon(Icons.photo_library),
            label: const Text('Galeri'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: _renk,
              side: const BorderSide(color: _renk),
              minimumSize: const Size.fromHeight(45),
            ),
          ),
        ),
      ],
    );
  }

  Widget _gorselOnizleme() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.file(
        _secilenGorsel!,
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
        cacheHeight: 360,
      ),
    );
  }

  Widget _sonuclar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 15),
        const Text(
          'Ad Soyad',
          style: TextStyle(
              fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _isimController,
          decoration: _girdiSusu('Ad Soyad'),
        ),
        if (_isimAdaylari.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('Önerilen isimler:',
              style: TextStyle(fontSize: 12, color: Colors.grey[700])),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _isimAdaylari
                .map(
                  (i) => ActionChip(
                    label: Text(i),
                    onPressed: () => setState(() => _isimController.text = i),
                  ),
                )
                .toList(),
          ),
        ],
        const SizedBox(height: 15),
        const Text(
          'Telefon Numarası',
          style: TextStyle(
              fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _telefonController,
          inputFormatters: [_telefonMask],
          keyboardType: TextInputType.phone,
          decoration: _girdiSusu('0### ### ## ##'),
        ),
        if (_telefonAdaylari.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('Önerilen numaralar:',
              style: TextStyle(fontSize: 12, color: Colors.grey[700])),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _telefonAdaylari
                .map(
                  (t) => ActionChip(
                    label: Text(t),
                    onPressed: () => setState(() => _telefonDoldur(t)),
                  ),
                )
                .toList(),
          ),
        ],
        const SizedBox(height: 15),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: const Text('Algılanan tüm metin'),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                _tumMetin,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _onayla,
            icon: const Icon(Icons.check),
            label: const Text('Forma Aktar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(45),
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _girdiSusu(String hint) {
    return InputDecoration(
      hintText: hint,
      contentPadding: const EdgeInsets.all(15),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: _renk),
        borderRadius: BorderRadius.circular(10),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: _renk),
        borderRadius: BorderRadius.circular(10),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}

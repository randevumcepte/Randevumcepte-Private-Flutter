import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:http/http.dart' as http;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../../../../Backend/backend.dart';

class MusteriTopluOcr extends StatefulWidget {
  final dynamic isletmebilgi;
  final int kullanicirolu;
  const MusteriTopluOcr({
    Key? key,
    required this.isletmebilgi,
    required this.kullanicirolu,
  }) : super(key: key);

  @override
  State<MusteriTopluOcr> createState() => _MusteriTopluOcrState();
}

class _OcrSatir {
  final TextEditingController isim;
  final TextEditingController telefon;
  final TextEditingController email;
  final TextEditingController dogumTarihi;
  String cinsiyet; // '0' kadın, '1' erkek, '' belirtilmemiş
  final MaskTextInputFormatter telefonMask;
  _OcrSatir(
    String isimMetni,
    String telefonMetni, {
    String emailMetni = '',
    String dogumTarihiMetni = '',
    this.cinsiyet = '',
  })  : isim = TextEditingController(text: isimMetni),
        telefon = TextEditingController(),
        email = TextEditingController(text: emailMetni),
        dogumTarihi = TextEditingController(text: dogumTarihiMetni),
        telefonMask = MaskTextInputFormatter(
          mask: '0### ### ## ##',
          filter: {'#': RegExp(r'[0-9]')},
        ) {
    if (telefonMetni.isNotEmpty) {
      telefon.text = telefonMask.maskText(telefonMetni);
    }
  }
  void dispose() {
    isim.dispose();
    telefon.dispose();
    email.dispose();
    dogumTarihi.dispose();
  }
}

class _MusteriTopluOcrState extends State<MusteriTopluOcr> {
  static const Color _renk = Color(0xFF6A1B9A);

  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _recognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  final List<_OcrSatir> _satirlar = [];
  final List<File> _taranmisGorseller = [];
  bool _isleniyor = false;
  String? _seciliSalonId;

  @override
  void initState() {
    super.initState();
    _salonIdYukle();
  }

  Future<void> _salonIdYukle() async {
    _seciliSalonId = await secilisalonid();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _recognizer.close();
    for (final s in _satirlar) {
      s.dispose();
    }
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
              toolbarTitle: 'Listeyi Çerçevele',
              toolbarColor: _renk,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false,
            ),
            IOSUiSettings(
              title: 'Listeyi Çerçevele',
              aspectRatioLockEnabled: false,
            ),
          ],
        );
      } catch (e) {
        log('cropper hatasi (orijinal kullaniliyor): $e');
      }

      final File dosya = File(kirpilmis?.path ?? secilen.path);
      setState(() => _isleniyor = true);

      final List<_OcrSatir> bulunan = await _sayfaTara(dosya);
      setState(() {
        _taranmisGorseller.add(dosya);
        _satirlar.addAll(bulunan);
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${bulunan.length} kayıt bulundu')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tarama hatası: $e')),
      );
    } finally {
      if (mounted) setState(() => _isleniyor = false);
    }
  }

  Future<List<_OcrSatir>> _sayfaTara(File dosya) async {
    final InputImage girdi = InputImage.fromFile(dosya);
    final RecognizedText sonuc = await _recognizer.processImage(girdi);

    // Önce yapısal form modu (etiketli alanlar) dene
    final _OcrSatir? formSonuc = _formModuOku(sonuc);
    if (formSonuc != null) {
      return [formSonuc];
    }

    final RegExp telefonRegex = RegExp(
        r'(\+?9?0?[\s\-\(\)]*5\d{2}[\s\-\(\)]*\d{3}[\s\-\(\)]*\d{2}[\s\-\(\)]*\d{2})');
    final RegExp sadeceHarf =
        RegExp(r"^[A-Za-zÇĞİıÖŞÜçğıöşü\s\.\-']+$");

    final List<_SatirAdayi> adaylar = [];
    for (final TextBlock blok in sonuc.blocks) {
      for (final TextLine satir in blok.lines) {
        final Rect r = satir.boundingBox;
        if (r.height <= 0) continue;
        final String temiz = satir.text.trim();
        if (temiz.isEmpty) continue;
        adaylar.add(_SatirAdayi(
          metin: temiz,
          ymerkez: r.top + r.height / 2,
          yukseklik: r.height,
          xsol: r.left,
        ));
      }
    }
    if (adaylar.isEmpty) return [];

    adaylar.sort((a, b) => a.ymerkez.compareTo(b.ymerkez));

    final double ortalamaYukseklik =
        adaylar.map((a) => a.yukseklik).reduce((a, b) => a + b) /
            adaylar.length;
    final double tolerans = ortalamaYukseklik * 0.7;

    final List<List<_SatirAdayi>> satirGruplari = [];
    for (final aday in adaylar) {
      if (satirGruplari.isEmpty) {
        satirGruplari.add([aday]);
        continue;
      }
      final grup = satirGruplari.last;
      final double grupY =
          grup.map((g) => g.ymerkez).reduce((a, b) => a + b) / grup.length;
      if ((aday.ymerkez - grupY).abs() <= tolerans) {
        grup.add(aday);
      } else {
        satirGruplari.add([aday]);
      }
    }

    final List<_HamSatir> ham = [];
    for (final grup in satirGruplari) {
      grup.sort((a, b) => a.xsol.compareTo(b.xsol));
      final String birlesik = grup.map((g) => g.metin).join(' ');
      final double y =
          grup.map((g) => g.ymerkez).reduce((a, b) => a + b) / grup.length;

      String? telefon;
      final telefonMatch = telefonRegex.firstMatch(birlesik);
      if (telefonMatch != null) {
        final String sade =
            telefonMatch.group(0)!.replaceAll(RegExp(r'\D'), '');
        String n = sade;
        if (n.startsWith('90') && n.length == 12) n = '0${n.substring(2)}';
        if (n.length == 10 && n.startsWith('5')) n = '0$n';
        if (n.length == 11 && n.startsWith('05')) telefon = n;
      }

      String isim = birlesik;
      if (telefonMatch != null) {
        isim = isim.replaceFirst(telefonMatch.group(0)!, ' ');
      }
      isim = isim
          .replaceAll(RegExp(r'^\s*\d+[\.\)\-:]?\s*'), '')
          .replaceAll(RegExp(r'[^A-Za-zÇĞİıÖŞÜçğıöşü\s\.\-]'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      final List<String> kelimeler = isim
          .split(' ')
          .where((k) => k.length >= 2 && sadeceHarf.hasMatch(k))
          .toList();
      isim = kelimeler
          .map((k) =>
              '${k[0].toUpperCase()}${k.substring(1).toLowerCase()}')
          .join(' ');

      if (telefon == null && kelimeler.isEmpty) {
        // satırı yine de extra alan tarama için (yakın satırlardan email/tarih
        // toplamak isteyebiliriz) tutmuyoruz; sadece atlıyoruz.
        continue;
      }
      ham.add(_HamSatir(
        isim: isim,
        telefon: telefon,
        y: y,
        hamMetin: birlesik,
      ));
    }

    // Alt alta ayrı satırlardaki isim-telefon çiftlerini birleştir.
    // Sadece-isim bir satır, hemen ardından gelen sadece-telefon bir satıra
    // (dikey mesafe makulse) eşlenir.
    final double esikMesafe = ortalamaYukseklik * 3.0;
    for (int i = 0; i < ham.length - 1; i++) {
      final a = ham[i];
      final b = ham[i + 1];
      if (a.kullanildi || b.kullanildi) continue;
      final bool aSadeceIsim = a.telefon == null && a.isim.isNotEmpty;
      final bool bSadeceTelefon = b.telefon != null && b.isim.isEmpty;
      if (aSadeceIsim && bSadeceTelefon && (b.y - a.y).abs() <= esikMesafe) {
        b.isim = a.isim;
        b.hamMetin = '${a.hamMetin}\n${b.hamMetin}';
        a.kullanildi = true;
      }
    }
    // Tersi kombinasyon: önce telefon, sonra isim
    for (int i = 0; i < ham.length - 1; i++) {
      final a = ham[i];
      final b = ham[i + 1];
      if (a.kullanildi || b.kullanildi) continue;
      final bool aSadeceTelefon = a.telefon != null && a.isim.isEmpty;
      final bool bSadeceIsim = b.telefon == null && b.isim.isNotEmpty;
      if (aSadeceTelefon && bSadeceIsim && (b.y - a.y).abs() <= esikMesafe) {
        a.isim = b.isim;
        a.hamMetin = '${a.hamMetin}\n${b.hamMetin}';
        b.kullanildi = true;
      }
    }

    // Her geçerli satır için ham metinden ek alanları çıkar
    for (final h in ham) {
      if (h.kullanildi) continue;
      _ekAlanlariCikar(h);
    }

    final Set<String> gorulen = {};
    final List<_OcrSatir> sonucListesi = [];
    for (final h in ham) {
      if (h.kullanildi) continue;
      if (h.telefon == null && h.isim.split(' ').length < 2) continue;
      if (h.telefon != null && gorulen.contains(h.telefon)) continue;
      if (h.telefon != null) gorulen.add(h.telefon!);
      sonucListesi.add(_OcrSatir(
        h.isim,
        h.telefon ?? '',
        emailMetni: h.email ?? '',
        dogumTarihiMetni: h.dogumTarihi ?? '',
        cinsiyet: h.cinsiyet,
      ));
    }
    return sonucListesi;
  }

  /// Yapısal formu okumaya çalışır: "MÜŞTERİ ADI SOYADI: ...", "TELEFON CEP: ..."
  /// gibi etiketleri tespit edip sağındaki/altındaki yazılı değerleri alır.
  /// Etiketler bulunamazsa null döner (freeform parser devreye girer).
  _OcrSatir? _formModuOku(RecognizedText sonuc) {
    final List<TextLine> tum = [];
    for (final blok in sonuc.blocks) {
      tum.addAll(blok.lines);
    }
    if (tum.length < 3) return null;
    tum.sort((a, b) =>
        a.boundingBox.top.compareTo(b.boundingBox.top));

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

      // Aynı satırda etiketten sonra değer var mı?
      String value = etiketSatiri.text.substring(eslesme!.end);
      value = value.replaceFirst(RegExp(r'^[\s:.\-]+'), '').trim();

      if (value.isEmpty) {
        // Aynı yatay satırda, etiketin sağındaki diğer satırları bul
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
        sag.sort((a, b) =>
            a.boundingBox.left.compareTo(b.boundingBox.left));

        final List<String> kelimeler = [];
        for (final s in sag) {
          // başka bir etiketle karşılaştığımızda dur
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

    // Değerleri işle
    final String isim = _formIsimTemizle(isimRaw);

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
      // X / ✓ / ☒ işaretinin hemen öncesindeki K veya E
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
      // Tam kelime fallback
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

    return _OcrSatir(
      isim,
      telefon,
      emailMetni: email,
      dogumTarihiMetni: dogum,
      cinsiyet: cinsiyet,
    );
  }

  String _formIsimTemizle(String raw) {
    String s = raw
        .replaceAll(RegExp(r'[^A-Za-zÇĞİıÖŞÜçğıöşü\s\.\-]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final kelimeler =
        s.split(' ').where((k) => k.length >= 2).toList();
    return kelimeler
        .map((k) =>
            '${k[0].toUpperCase()}${k.substring(1).toLowerCase()}')
        .join(' ');
  }

  String _gecerliTarih(String raw) {
    if (raw.isEmpty) return '';
    // YYYY-MM-DD doğrudan kabul
    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(raw)) return raw;
    // Türkçe formatları çevir
    final m =
        RegExp(r'^(\d{1,2})[./\-](\d{1,2})[./\-](\d{2,4})$').firstMatch(raw);
    if (m != null) {
      final d = int.tryParse(m.group(1)!) ?? 0;
      final mo = int.tryParse(m.group(2)!) ?? 0;
      int y = int.tryParse(m.group(3)!) ?? 0;
      if (d < 1 || d > 31 || mo < 1 || mo > 12) return '';
      if (y < 100) y = y >= 30 ? 1900 + y : 2000 + y;
      if (y < 1900 || y > DateTime.now().year) return '';
      return '${y.toString().padLeft(4, '0')}-${mo.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
    }
    return '';
  }

  void _ekAlanlariCikar(_HamSatir h) {
    // Email
    final emailRe = RegExp(r'[\w.+\-]+@[\w\-]+\.[\w.\-]+');
    final emailM = emailRe.firstMatch(h.hamMetin);
    if (emailM != null) {
      h.email = emailM.group(0);
    }

    // Doğum tarihi: dd.mm.yyyy / dd/mm/yyyy / dd-mm-yyyy / 2 haneli yıl
    final dateRe = RegExp(r'\b(\d{1,2})[./\-](\d{1,2})[./\-](\d{2,4})\b');
    for (final m in dateRe.allMatches(h.hamMetin)) {
      final d = int.tryParse(m.group(1)!);
      final mo = int.tryParse(m.group(2)!);
      int? y = int.tryParse(m.group(3)!);
      if (d == null ||
          mo == null ||
          y == null ||
          d < 1 ||
          d > 31 ||
          mo < 1 ||
          mo > 12) {
        continue;
      }
      if (y < 100) y = y >= 30 ? 1900 + y : 2000 + y;
      if (y < 1900 || y > DateTime.now().year) continue;
      h.dogumTarihi =
          '${y.toString().padLeft(4, '0')}-${mo.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
      break;
    }

    // Cinsiyet: kadın / erkek / bayan / bay (Türkçe I/i normalize)
    final norm = h.hamMetin
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('İ', 'i');
    final genderRe = RegExp(r'\b(kadin|bayan|erkek|bay)\b');
    final gM = genderRe.firstMatch(norm);
    if (gM != null) {
      final w = gM.group(1)!;
      if (w == 'kadin' || w == 'bayan') {
        h.cinsiyet = '0';
      } else if (w == 'erkek' || w == 'bay') {
        h.cinsiyet = '1';
      }
    }
  }

  void _satirEkle() {
    setState(() => _satirlar.add(_OcrSatir('', '')));
  }

  void _satirSil(int i) {
    setState(() {
      _satirlar[i].dispose();
      _satirlar.removeAt(i);
    });
  }

  Future<void> _hepsiniKaydet() async {
    if (_seciliSalonId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Salon bilgisi yüklenemedi')),
      );
      return;
    }
    final List<_OcrSatir> gecerli = _satirlar.where((s) {
      final ad = s.isim.text.trim();
      final tel = s.telefon.text.replaceAll(RegExp(r'\D'), '');
      return ad.isNotEmpty && tel.length == 11 && tel.startsWith('05');
    }).toList();

    if (gecerli.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Geçerli kayıt yok (ad + 11 haneli 05.. telefon)')),
      );
      return;
    }

    final bool? onay = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Toplu Kayıt'),
        content: Text(
            '${gecerli.length} müşteri kaydedilecek. Devam edilsin mi?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    if (onay != true) return;

    await _kayitDongusu(gecerli);
  }

  Future<void> _kayitDongusu(List<_OcrSatir> liste) async {
    int basarili = 0;
    int atlandi = 0;
    int hata = 0;
    final List<String> hataMesajlari = [];

    final ValueNotifier<int> ilerleme = ValueNotifier(0);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Kaydediliyor...'),
        content: ValueListenableBuilder<int>(
          valueListenable: ilerleme,
          builder: (_, deger, __) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(value: deger / liste.length),
              const SizedBox(height: 12),
              Text('$deger / ${liste.length}'),
            ],
          ),
        ),
      ),
    );

    for (int i = 0; i < liste.length; i++) {
      final s = liste[i];
      final String ad = s.isim.text.trim();
      final String tel = s.telefon.text.trim();
      final String emailVal = s.email.text.trim();
      final String dogumVal = s.dogumTarihi.text.trim();
      try {
        final response = await http.post(
          Uri.parse(
              'https://app.randevumcepte.com.tr/api/v1/musteriekleguncelle/$_seciliSalonId'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'ad_soyad': ad,
            'telefon': tel,
            'email': emailVal,
            'dogum_tarihi': _gecerliTarih(dogumVal),
            'cinsiyet': s.cinsiyet,
            'musteri_tipi': '',
            'ozel_notlar': '',
          }),
        );
        if (response.statusCode == 200 || response.statusCode == 201) {
          if (response.body.trim().isNotEmpty) {
            final decoded = json.decode(response.body);
            if (decoded is Map &&
                decoded['status']?.toString() == 'warning') {
              atlandi++;
            } else {
              basarili++;
            }
          } else {
            basarili++;
          }
        } else {
          hata++;
          hataMesajlari.add('$ad: HTTP ${response.statusCode}');
        }
      } catch (e) {
        hata++;
        hataMesajlari.add('$ad: $e');
        log('toplu ocr kayit hata: $e');
      }
      ilerleme.value = i + 1;
    }

    if (mounted) Navigator.of(context, rootNavigator: true).pop();
    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sonuç'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('✅ Kaydedildi: $basarili'),
              Text('⏭ Atlandı (zaten var): $atlandi'),
              Text('❌ Hata: $hata'),
              if (hataMesajlari.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('Hatalar:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                ...hataMesajlari.map((m) => Text('• $m',
                    style: const TextStyle(fontSize: 12))),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );

    if (basarili > 0 && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Toplu Müşteri Tara',
            style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.clear_rounded, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isleniyor
                        ? null
                        : () => _gorselSec(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Kamera'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _renk,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(45),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isleniyor
                        ? null
                        : () => _gorselSec(ImageSource.gallery),
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
            ),
          ),
          if (_isleniyor) const LinearProgressIndicator(),
          if (_taranmisGorseller.isNotEmpty)
            SizedBox(
              height: 70,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _taranmisGorseller.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.file(
                    _taranmisGorseller[i],
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    cacheWidth: 140,
                    cacheHeight: 140,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Text('${_satirlar.length} kayıt',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton.icon(
                  onPressed: _satirEkle,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Satır Ekle'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _satirlar.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Önce kameradan veya galeriden bir fotoğraf seçin.\nAlt alta yazılmış isim ve telefon listesi en iyi sonucu verir.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _satirlar.length,
                    itemBuilder: (_, i) => _satirKarti(i),
                  ),
          ),
          if (_satirlar.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _hepsiniKaydet,
                  icon: const Icon(Icons.save),
                  label: Text('Hepsini Kaydet (${_satirlar.length})'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _satirKarti(int i) {
    final _OcrSatir s = _satirlar[i];
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _renk.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person,
                      size: 16, color: _renk),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: s.isim,
                    keyboardType: TextInputType.name,
                    textCapitalization: TextCapitalization.words,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'Ad Soyad',
                      labelText: 'Ad Soyad',
                      labelStyle: TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500),
                      contentPadding: EdgeInsets.symmetric(vertical: 4),
                    ),
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.red, size: 22),
                  onPressed: () => _satirSil(i),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                      minWidth: 36, minHeight: 36),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 0),
              child: Divider(height: 1),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 36),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.phone,
                        size: 16, color: Colors.green),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: s.telefon,
                      inputFormatters: [s.telefonMask],
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: '0XXX XXX XX XX',
                        labelText: 'Telefon',
                        labelStyle: TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500),
                        contentPadding: EdgeInsets.symmetric(vertical: 4),
                      ),
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
            if (s.email.text.isNotEmpty) ...[
              const Divider(height: 1),
              _ekAlanRow(
                icon: Icons.email_outlined,
                renkAlpha: Colors.blue,
                child: TextField(
                  controller: s.email,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: 'ornek@mail.com',
                    labelText: 'E-posta',
                    labelStyle: TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500),
                    contentPadding: EdgeInsets.symmetric(vertical: 4),
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
            if (s.dogumTarihi.text.isNotEmpty) ...[
              const Divider(height: 1),
              _ekAlanRow(
                icon: Icons.cake_outlined,
                renkAlpha: Colors.orange,
                child: TextField(
                  controller: s.dogumTarihi,
                  keyboardType: TextInputType.datetime,
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: 'YYYY-MM-DD',
                    labelText: 'Doğum Tarihi',
                    labelStyle: TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500),
                    contentPadding: EdgeInsets.symmetric(vertical: 4),
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
            if (s.cinsiyet.isNotEmpty) ...[
              const Divider(height: 1),
              _ekAlanRow(
                icon: Icons.wc_outlined,
                renkAlpha: Colors.pink,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Kadın'),
                        selected: s.cinsiyet == '0',
                        onSelected: (sec) =>
                            setState(() => s.cinsiyet = sec ? '0' : ''),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Erkek'),
                        selected: s.cinsiyet == '1',
                        onSelected: (sec) =>
                            setState(() => s.cinsiyet = sec ? '1' : ''),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _ekAlanRow({
    required IconData icon,
    required Color renkAlpha,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 36, top: 4),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: renkAlpha.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: renkAlpha),
          ),
          const SizedBox(width: 10),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _SatirAdayi {
  final String metin;
  final double ymerkez;
  final double yukseklik;
  final double xsol;
  _SatirAdayi({
    required this.metin,
    required this.ymerkez,
    required this.yukseklik,
    required this.xsol,
  });
}

class _HamSatir {
  String isim;
  String? telefon;
  final double y;
  String hamMetin;
  String? email;
  String? dogumTarihi;
  String cinsiyet;
  bool kullanildi = false;
  _HamSatir({
    required this.isim,
    required this.telefon,
    required this.y,
    required this.hamMetin,
    this.email,
    this.dogumTarihi,
    this.cinsiyet = '',
  });
}

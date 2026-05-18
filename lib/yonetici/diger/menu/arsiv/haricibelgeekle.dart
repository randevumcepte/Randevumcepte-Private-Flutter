import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';
import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Backend/yetki.dart';
import 'package:randevu_sistem/Models/musteri_danisanlar.dart';
import 'package:randevu_sistem/Models/personel.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HariciBelgeEkle extends StatefulWidget {
  final dynamic isletmebilgi;
  const HariciBelgeEkle({super.key, required this.isletmebilgi});

  @override
  State<HariciBelgeEkle> createState() => _HariciBelgeEkleState();
}

class _HariciBelgeEkleState extends State<HariciBelgeEkle> {
  String _seciliSube = '';
  bool _yukleniyor = true;
  bool _gonderiliyor = false;
  String? _hataMesaji;

  List<Personel> _personeller = [];

  MusteriDanisan? _musteri;
  Personel? _personel;
  final List<File> _gorseller = [];
  final _baslik = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _baslat();
  }

  @override
  void dispose() {
    _baslik.dispose();
    super.dispose();
  }

  Future<void> _baslat() async {
    try {
      _seciliSube = (await secilisalonid()) ?? '';
      // Sadece personel listesi preload; musteri arama server-side yapilir
      _personeller = await personellistegetir(_seciliSube);
    } catch (e) {
      _hataMesaji = 'Veriler yüklenemedi: $e';
    }
    if (mounted) setState(() => _yukleniyor = false);
  }

  Future<void> _musteriSec() async {
    final s = await showModalBottomSheet<MusteriDanisan?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _MusteriPicker(
        salonid: _seciliSube,
        seciliId: _musteri?.id,
      ),
    );
    if (s != null) setState(() => _musteri = s);
  }

  Future<void> _personelSec() async {
    final s = await _picker_<Personel>(
      baslik: 'Personel Seç',
      ogeler: _personeller,
      etiket: (p) => p.personel_adi,
      altYazi: (p) => p.cep_telefon,
      seciliId: _personel?.id,
      ogeId: (p) => p.id,
    );
    if (s != null) setState(() => _personel = s);
  }

  Future<T?> _picker_<T>({
    required String baslik,
    required List<T> ogeler,
    required String Function(T) etiket,
    required String Function(T) altYazi,
    required String? seciliId,
    required String Function(T) ogeId,
  }) {
    return showModalBottomSheet<T?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PickerSheet<T>(
        baslik: baslik,
        ogeler: ogeler,
        etiket: etiket,
        altYazi: altYazi,
        seciliId: seciliId,
        ogeId: ogeId,
      ),
    );
  }

  Future<void> _kaynakSec() async {
    final secim = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 12),
                child: Text('Belge Kaynağı',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ),
              _KaynakBtn(
                icon: Icons.camera_alt_rounded,
                baslik: 'Kameradan Çek',
                altYazi: 'Telefon kamerasıyla fotoğraf çek',
                renk: Theme.of(ctx).colorScheme.primary,
                onTap: () => Navigator.pop(ctx, 'camera'),
              ),
              const SizedBox(height: 8),
              _KaynakBtn(
                icon: Icons.photo_library_outlined,
                baslik: 'Galeriden Seç',
                altYazi: 'Cihaz galerisinden resim seç',
                renk: const Color(0xFF0EA5E9),
                onTap: () => Navigator.pop(ctx, 'gallery'),
              ),
            ],
          ),
        ),
      ),
    );
    if (secim == null) return;
    await Future.delayed(const Duration(milliseconds: 80));
    try {
      final XFile? img = await _picker.pickImage(
        source: secim == 'camera' ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 85,
      );
      if (img != null && mounted) {
        setState(() => _gorseller.add(File(img.path)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Resim seçilemedi.')),
        );
      }
    }
  }

  void _gorselSil(int idx) {
    setState(() => _gorseller.removeAt(idx));
  }

  void _gorselGoster(int idx) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: () {
                  _gorselSil(idx);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          body: PhotoView(
            imageProvider: FileImage(_gorseller[idx]),
            minScale: PhotoViewComputedScale.contained * 0.8,
            maxScale: PhotoViewComputedScale.covered * 2,
            backgroundDecoration: const BoxDecoration(color: Colors.black),
          ),
        ),
      ),
    );
  }

  void _uyari(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tamam')),
        ],
      ),
    );
  }

  Future<void> _gonder() async {
    if (_baslik.text.trim().isEmpty) {
      _uyari('Başlık Gerekli', 'Lütfen belge başlığını girin.');
      return;
    }
    if (_musteri == null) {
      _uyari('Müşteri Seçilmedi', 'Lütfen müşteri seçin.');
      return;
    }
    if (_gorseller.isEmpty) {
      _uyari('Belge Yok', 'En az bir resim ekleyin (kamera veya galeri).');
      return;
    }

    setState(() => _gonderiliyor = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user');
      final user = userJson != null ? jsonDecode(userJson) : {};

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(
            'https://apptest.randevumcepte.com.tr/api/v1/haricibelgeekle'),
      );

      request.files
          .add(await http.MultipartFile.fromPath('file', _gorseller[0].path));
      request.fields['id'] = '';
      request.fields['form_baslik'] = _baslik.text.trim();
      request.fields['form_id'] = '0';
      request.fields['personel_id'] = _personel?.id ?? '';
      request.fields['user_id'] = _musteri!.id;
      request.fields['salon_id'] = _seciliSube;
      request.fields['olusturan'] = user['id']?.toString() ?? '';

      final response = await request.send();
      if (response.statusCode == 200) {
        if (mounted) Navigator.pop(context, true);
      } else {
        if (mounted) {
          _uyari('Sunucu Hatası', 'Hata kodu: ${response.statusCode}');
        }
      }
    } catch (_) {
      if (mounted) {
        _uyari('Bağlantı Hatası', 'İnternet bağlantınızı kontrol edin.');
      }
    } finally {
      if (mounted) setState(() => _gonderiliyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F4FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        title: const Text('Harici Belge Ekle',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        actions: [
          TextButton.icon(
            onPressed: _gonderiliyor ? null : _gonder,
            icon: _gonderiliyor
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.check_rounded, color: scheme.primary),
            label: Text(
              'Kaydet',
              style: TextStyle(
                  fontWeight: FontWeight.w800, color: scheme.primary),
            ),
          ),
        ],
      ),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : _hataMesaji != null
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(_hataMesaji!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w600)),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
                  children: [
                    _kart(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _Etiket('Belge Başlığı *'),
                          TextField(
                            controller: _baslik,
                            decoration: _inputDeko(
                                'Örn: Eski Onam Formu - 2024', scheme),
                          ),
                          const SizedBox(height: 14),
                          const _Etiket('Müşteri *'),
                          _SecimAlani(
                            etiket: _musteri?.name ?? 'Müşteri seçin',
                            altYazi: Yetki.telefonGoster(_musteri?.cep_telefon),
                            ikon: Icons.person_outline_rounded,
                            bos: _musteri == null,
                            onTap: _musteriSec,
                          ),
                          const SizedBox(height: 14),
                          const _Etiket('İşlemi Yapan Personel (opsiyonel)'),
                          _SecimAlani(
                            etiket: _personel?.personel_adi ?? 'Personel seçin',
                            altYazi: _personel?.cep_telefon,
                            ikon: Icons.badge_outlined,
                            bos: _personel == null,
                            onTap: _personelSec,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _kart(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.image_outlined,
                                  size: 18, color: scheme.primary),
                              const SizedBox(width: 6),
                              const Text('Belge Resimleri',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800)),
                              const Spacer(),
                              if (_gorseller.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: scheme.primary
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    '${_gorseller.length}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: scheme.primary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (_gorseller.isEmpty)
                            _BosResimAlani(
                              renk: scheme.primary,
                              onTap: _kaynakSec,
                            )
                          else ...[
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                childAspectRatio: 1,
                              ),
                              itemCount: _gorseller.length,
                              itemBuilder: (ctx, i) => _ResimKuc(
                                file: _gorseller[i],
                                onTap: () => _gorselGoster(i),
                                onSil: () => _gorselSil(i),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                          Material(
                            color: scheme.primary.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              onTap: _kaynakSec,
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_a_photo_outlined,
                                        size: 18, color: scheme.primary),
                                    const SizedBox(width: 8),
                                    Text(
                                      _gorseller.isEmpty
                                          ? 'Resim Ekle (Kamera / Galeri)'
                                          : 'Daha Fazla Ekle',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: scheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _kart({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  InputDecoration _inputDeko(String hint, ColorScheme scheme) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12.5, color: Colors.black38),
      filled: true,
      fillColor: const Color(0xFFF4F5F7),
      isDense: true,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }
}

class _Etiket extends StatelessWidget {
  final String text;
  const _Etiket(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _SecimAlani extends StatelessWidget {
  final String etiket;
  final String? altYazi;
  final IconData ikon;
  final bool bos;
  final VoidCallback onTap;
  const _SecimAlani({
    required this.etiket,
    required this.ikon,
    required this.bos,
    required this.onTap,
    this.altYazi,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.primary.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(ikon, color: scheme.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      etiket,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: bos
                            ? Colors.black.withValues(alpha: 0.45)
                            : scheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (altYazi != null && altYazi!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        altYazi!,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: scheme.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.unfold_more_rounded,
                  size: 18, color: scheme.primary.withValues(alpha: 0.6)),
            ],
          ),
        ),
      ),
    );
  }
}

class _BosResimAlani extends StatelessWidget {
  final Color renk;
  final VoidCallback onTap;
  const _BosResimAlani({required this.renk, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: renk.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: renk.withValues(alpha: 0.35),
            style: BorderStyle.solid,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: renk.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.cloud_upload_outlined,
                  size: 28, color: renk),
            ),
            const SizedBox(height: 8),
            Text(
              'Henüz resim eklenmedi',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: renk,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResimKuc extends StatelessWidget {
  final File file;
  final VoidCallback onTap;
  final VoidCallback onSil;
  const _ResimKuc({
    required this.file,
    required this.onTap,
    required this.onSil,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Material(
            child: InkWell(
              onTap: onTap,
              child: Image.file(file, fit: BoxFit.cover),
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: Material(
            color: Colors.black.withValues(alpha: 0.55),
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onSil,
              customBorder: const CircleBorder(),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.close_rounded,
                    size: 16, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _KaynakBtn extends StatelessWidget {
  final IconData icon;
  final String baslik;
  final String altYazi;
  final Color renk;
  final VoidCallback onTap;
  const _KaynakBtn({
    required this.icon,
    required this.baslik,
    required this.altYazi,
    required this.renk,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: renk.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: renk.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: renk, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(baslik,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(altYazi,
                        style: const TextStyle(
                            fontSize: 11.5, color: Colors.black54)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: renk),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickerSheet<T> extends StatefulWidget {
  final String baslik;
  final List<T> ogeler;
  final String Function(T) etiket;
  final String Function(T) altYazi;
  final String? seciliId;
  final String Function(T) ogeId;
  const _PickerSheet({
    required this.baslik,
    required this.ogeler,
    required this.etiket,
    required this.altYazi,
    required this.seciliId,
    required this.ogeId,
  });

  @override
  State<_PickerSheet<T>> createState() => _PickerSheetState<T>();
}

class _PickerSheetState<T> extends State<_PickerSheet<T>> {
  String _arama = '';
  final _aramaController = TextEditingController();

  @override
  void dispose() {
    _aramaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final filtreli = widget.ogeler.where((o) {
      if (_arama.isEmpty) return true;
      final q = _arama.toLowerCase();
      return widget.etiket(o).toLowerCase().contains(q) ||
          widget.altYazi(o).toLowerCase().contains(q);
    }).toList();
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (ctx, scroll) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.baslik,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                child: TextField(
                  controller: _aramaController,
                  onChanged: (v) => setState(() => _arama = v),
                  decoration: InputDecoration(
                    hintText: 'Ara...',
                    isDense: true,
                    prefixIcon: const Icon(Icons.search, size: 18),
                    filled: true,
                    fillColor: scheme.primary.withValues(alpha: 0.05),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: filtreli.isEmpty
                    ? Center(
                        child: Text(
                          'Sonuç yok',
                          style: TextStyle(
                              color: Colors.black.withValues(alpha: 0.5),
                              fontSize: 13),
                        ),
                      )
                    : ListView.builder(
                        controller: scroll,
                        itemCount: filtreli.length,
                        itemBuilder: (ctx, i) {
                          final o = filtreli[i];
                          final aktif = widget.seciliId == widget.ogeId(o);
                          return ListTile(
                            dense: true,
                            tileColor: aktif
                                ? scheme.primary.withValues(alpha: 0.06)
                                : null,
                            title: Text(
                              widget.etiket(o),
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: aktif
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                              ),
                            ),
                            subtitle: widget.altYazi(o).isNotEmpty
                                ? Text(
                                    widget.altYazi(o),
                                    style: const TextStyle(fontSize: 11.5),
                                  )
                                : null,
                            trailing: aktif
                                ? Icon(Icons.check_circle_rounded,
                                    color: scheme.primary, size: 18)
                                : null,
                            onTap: () => Navigator.pop<T?>(context, o),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Server-side aramali musteri picker — `musterilistegetirSayfali` ile
/// tum musteri tabanini gezer (default endpoint limit=50 sorununu giderir).
class _MusteriPicker extends StatefulWidget {
  final String salonid;
  final String? seciliId;
  const _MusteriPicker({required this.salonid, required this.seciliId});

  @override
  State<_MusteriPicker> createState() => _MusteriPickerState();
}

class _MusteriPickerState extends State<_MusteriPicker> {
  final _aramaController = TextEditingController();
  Timer? _debounce;
  bool _yukleniyor = true;
  String _arama = '';
  List<MusteriDanisan> _liste = [];
  String? _hata;

  @override
  void initState() {
    super.initState();
    _yukle('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _aramaController.dispose();
    super.dispose();
  }

  Future<void> _yukle(String q) async {
    if (mounted) setState(() => _yukleniyor = true);
    try {
      final liste = await musterilistegetirSayfali(
          '', widget.salonid, q, '200', '0');
      if (mounted) {
        setState(() {
          _liste = liste;
          _yukleniyor = false;
          _hata = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _yukleniyor = false;
          _hata = e.toString();
        });
      }
    }
  }

  void _aramaDegisti(String v) {
    _arama = v;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _yukle(v));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scroll) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Müşteri Seç',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                child: TextField(
                  controller: _aramaController,
                  onChanged: _aramaDegisti,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'İsim veya telefon ara...',
                    isDense: true,
                    prefixIcon: const Icon(Icons.search, size: 18),
                    suffixIcon: _yukleniyor
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2),
                            ),
                          )
                        : null,
                    filled: true,
                    fillColor: scheme.primary.withValues(alpha: 0.05),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: _hata != null
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: Text(
                            'Hata: $_hata',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.red.shade700),
                          ),
                        ),
                      )
                    : (_liste.isEmpty && !_yukleniyor)
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                _arama.isEmpty
                                    ? 'Müşteri bulunamadı'
                                    : '"$_arama" için sonuç yok',
                                style: TextStyle(
                                    color: Colors.black
                                        .withValues(alpha: 0.5),
                                    fontSize: 13),
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: scroll,
                            itemCount: _liste.length,
                            itemBuilder: (ctx, i) {
                              final m = _liste[i];
                              final aktif = widget.seciliId == m.id;
                              return ListTile(
                                dense: true,
                                tileColor: aktif
                                    ? scheme.primary
                                        .withValues(alpha: 0.06)
                                    : null,
                                leading: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: scheme.primary
                                      .withValues(alpha: 0.15),
                                  child: Text(
                                    m.name.isNotEmpty
                                        ? m.name
                                            .trim()
                                            .substring(0, 1)
                                            .toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: scheme.primary,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  m.name,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: aktif
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                  ),
                                ),
                                subtitle: m.cep_telefon.isNotEmpty &&
                                        m.cep_telefon != 'null'
                                    ? Text(Yetki.telefonGoster(m.cep_telefon),
                                        style: const TextStyle(
                                            fontSize: 11.5))
                                    : null,
                                trailing: aktif
                                    ? Icon(Icons.check_circle_rounded,
                                        color: scheme.primary, size: 18)
                                    : null,
                                onTap: () =>
                                    Navigator.pop<MusteriDanisan>(
                                        context, m),
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:randevu_sistem/Models/islemler.dart';
import 'package:randevu_sistem/Models/musteri_danisanlar.dart';
import 'package:randevu_sistem/theme/app_tokens.dart';

class ImageGallery extends StatefulWidget {
  final MusteriDanisan md;
  final dynamic isletmebilgi;

  const ImageGallery({
    super.key,
    required this.md,
    required this.isletmebilgi,
  });

  @override
  State<ImageGallery> createState() => _ImageGalleryState();
}

class _ImageGalleryState extends State<ImageGallery> {
  static const String _baseUrl = 'https://app.randevumcepte.com.tr/';

  bool isLoading = true;
  bool _uploading = false;

  // group key (tarih string) → list of image paths
  final Map<String, List<String>> _gruplar = {};
  List<String> _siraliGruplar = [];

  // image path → note (caption)
  final Map<String, String> _notlar = {};

  String? get _salonId {
    try {
      final b = widget.isletmebilgi;
      if (b is Map) return b['id']?.toString();
      return b?.id?.toString();
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    fetchImages();
  }

  Future<void> fetchImages() async {
    try {
      setState(() => isLoading = true);
      final Map<String, dynamic> body = {'user_id': widget.md.id};
      final salon = _salonId;
      if (salon != null && salon.isNotEmpty) {
        // Beyaz etiket: sadece bu isletmenin gorselleri gelsin
        body['salon_id'] = salon;
      }
      final response = await http.post(
        Uri.parse('$_baseUrl/api/v1/musteriresimleri'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final folders = data.map((item) => Islemler.fromJson(item)).toList();

        final Map<String, List<String>> grouped = {};
        final Map<String, String> notlar = {};
        for (final e in folders) {
          final raw = (e.islem_fotolari).trim();
          if (raw.isEmpty || raw == 'null' || raw == '[]') continue;
          List<String> images;
          try {
            images = List<String>.from(jsonDecode(raw));
          } catch (_) {
            continue;
          }
          if (images.isEmpty) continue;
          final not = e.resim_notu;
          if (not != null && not.trim().isNotEmpty) {
            for (final p in images) {
              notlar[p] = not;
            }
          }
          final key = _gunKey(e.tarih);
          grouped.putIfAbsent(key, () => <String>[]).addAll(images);
        }

        // sort group keys descending (latest first)
        final keys = grouped.keys.toList()
          ..sort((a, b) => b.compareTo(a));

        if (!mounted) return;
        setState(() {
          _gruplar
            ..clear()
            ..addAll(grouped);
          _notlar
            ..clear()
            ..addAll(notlar);
          _siraliGruplar = keys;
          isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint('musteri resim getir hata: $e');
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  String _gunKey(String raw) {
    if (raw.isEmpty || raw == 'null') return '-';
    // try to normalize to yyyy-MM-dd
    try {
      final dt = DateTime.parse(raw);
      final y = dt.year.toString().padLeft(4, '0');
      final m = dt.month.toString().padLeft(2, '0');
      final d = dt.day.toString().padLeft(2, '0');
      return '$y-$m-$d';
    } catch (_) {
      return raw;
    }
  }

  String _gunBaslik(String key) {
    if (key == '-') return 'Tarihsiz';
    try {
      final dt = DateTime.parse(key);
      const aylar = [
        'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
        'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
      ];
      const gunler = [
        'Pazartesi', 'Salı', 'Çarşamba', 'Perşembe',
        'Cuma', 'Cumartesi', 'Pazar'
      ];
      final bugun = DateTime.now();
      final dun = bugun.subtract(const Duration(days: 1));
      if (dt.year == bugun.year &&
          dt.month == bugun.month &&
          dt.day == bugun.day) {
        return 'Bugün';
      }
      if (dt.year == dun.year &&
          dt.month == dun.month &&
          dt.day == dun.day) {
        return 'Dün';
      }
      final gunAdi = gunler[dt.weekday - 1];
      return '${dt.day} ${aylar[dt.month - 1]} ${dt.year} · $gunAdi';
    } catch (_) {
      return key;
    }
  }

  int get _toplamFoto =>
      _gruplar.values.fold(0, (acc, l) => acc + l.length);

  // ── PHOTO SOURCE PICKER ──────────────────────────────────────────────────
  Future<void> _yeniFotoEkle() async {
    if (_uploading) return;
    final scheme = Theme.of(context).colorScheme;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.onSurface.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Fotoğraf Ekle',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Kaynağı seç',
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _sourceTile(
                      context: ctx,
                      icon: Icons.photo_camera_rounded,
                      label: 'Kamera',
                      onTap: () => Navigator.pop(ctx, ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _sourceTile(
                      context: ctx,
                      icon: Icons.photo_library_rounded,
                      label: 'Galeri',
                      onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return;

    // Permissions
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        _bildirim('Kamera izni gerekli');
        return;
      }
    } else {
      final statuses = await [Permission.photos, Permission.storage].request();
      final ok = (statuses[Permission.photos]?.isGranted ?? false) ||
          (statuses[Permission.storage]?.isGranted ?? false);
      if (!ok) {
        // some Android versions don't require these; proceed and let picker handle
      }
    }

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1600,
    );
    if (picked == null) return;
    // Picker (galeri/kamera) async bir bosluk; iOS'ta uygulama on plana
    // donerken widget dispose olmus olabilir -> context'e dokunmadan once kontrol.
    if (!mounted) return;
    final file = File(picked.path);
    final not = await _notSheet(
      localFile: file,
      mevcut: '',
      actionLabel: 'Ekle',
      baslik: 'Not ekle',
      altMetin: 'İstersen bu fotoğraf için kısa bir not yaz (opsiyonel).',
    );
    if (not == null) return; // iptal edildi
    if (!mounted) return;
    await _uploadImage(file, not.trim());
  }

  // ── NOTE INPUT SHEET (ekleme + düzenleme ortak) ──────────────────────────
  Future<String?> _notSheet({
    File? localFile,
    String? networkUrl,
    required String mevcut,
    required String actionLabel,
    required String baslik,
    required String altMetin,
  }) async {
    if (!mounted) return null; // picker async bosluugundan sonra dispose olduysa context'e dokunma
    final scheme = Theme.of(context).colorScheme;
    final controller = TextEditingController(text: mevcut);
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: scheme.onSurface.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                if (localFile != null || networkUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    child: SizedBox(
                      height: 150,
                      width: double.infinity,
                      child: localFile != null
                          ? Image.file(localFile, fit: BoxFit.cover)
                          : Image.network(networkUrl!, fit: BoxFit.cover),
                    ),
                  ),
                const SizedBox(height: 14),
                Text(
                  baslik,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  altMetin,
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  maxLines: 3,
                  minLines: 1,
                  maxLength: 500,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: 'Not...',
                    filled: true,
                    fillColor: scheme.primary.withValues(alpha: 0.04),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      borderSide: BorderSide(
                          color: scheme.primary.withValues(alpha: 0.12)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      borderSide: BorderSide(
                          color: scheme.primary.withValues(alpha: 0.12)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      borderSide: BorderSide(color: scheme.primary, width: 1.4),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                          side: BorderSide(
                              color: scheme.onSurface.withValues(alpha: 0.15)),
                          foregroundColor: scheme.onSurface,
                        ),
                        child: const Text('İptal',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () =>
                            Navigator.pop(ctx, controller.text),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: scheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: Text(actionLabel,
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    controller.dispose();
    return result;
  }

  Widget _sourceTile({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                scheme.primary.withValues(alpha: 0.10),
                scheme.tertiary.withValues(alpha: 0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: scheme.primary.withValues(alpha: 0.10),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: AppShadows.tinted(scheme.primary),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _uploadImage(File file, [String note = '']) async {
    setState(() => _uploading = true);
    try {
      final req = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/api/v1/musteriresimekle'),
      );
      req.fields['user_id'] = widget.md.id;
      final salon = _salonId;
      if (salon != null && salon.isNotEmpty) {
        req.fields['salon_id'] = salon;
      }
      if (note.trim().isNotEmpty) {
        req.fields['not'] = note.trim();
      }
      req.files.add(
        await http.MultipartFile.fromPath('musteriresim', file.path),
      );

      final streamed = await req.send();
      final body = await streamed.stream.bytesToString();
      debugPrint('upload ${streamed.statusCode}: $body');

      if (streamed.statusCode == 200) {
        _bildirim('Fotoğraf eklendi');
        await fetchImages();
      } else {
        String mesaj = 'Yükleme başarısız';
        try {
          final j = jsonDecode(body) as Map<String, dynamic>;
          if (j['error'] is String) mesaj = j['error'] as String;
        } catch (_) {}
        _bildirim('$mesaj (${streamed.statusCode})');
      }
    } catch (e) {
      debugPrint('upload exception: $e');
      _bildirim('Yükleme sırasında bir hata oluştu');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _bildirim(String mesaj) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mesaj),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── FULL-SCREEN VIEWER ───────────────────────────────────────────────────
  void _acGoruntuleyici(List<String> paths, int index) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.92),
        pageBuilder: (_, __, ___) => _FullScreenGallery(
          paths: paths,
          baseUrl: _baseUrl,
          initialIndex: index,
          notes: Map<String, String>.from(_notlar),
          onDelete: (p) async {
            final ok = await _silmeIste();
            if (!ok) return false;
            return _resimSil(p);
          },
          onEditNote: (p) => _notDuzenle(p),
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  // ── DELETE ───────────────────────────────────────────────────────────────
  Future<bool> _silmeIste() async {
    final scheme = Theme.of(context).colorScheme;
    final res = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.onSurface.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.delete_outline_rounded,
                  color: Colors.red.shade600, size: 26),
            ),
            const SizedBox(height: 12),
            Text(
              'Fotoğrafı sil?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Bu fotoğraf hem senin panelinden hem de\nsalonun panelinden kaldırılır.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: scheme.onSurface.withValues(alpha: 0.6),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      side: BorderSide(
                          color: scheme.onSurface.withValues(alpha: 0.15)),
                      foregroundColor: scheme.onSurface,
                    ),
                    child: const Text(
                      'İptal',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: const Text(
                      'Sil',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    return res == true;
  }

  Future<bool> _resimSil(String path) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/v1/musteriresimsil'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': widget.md.id,
          'path': path,
        }),
      );
      if (res.statusCode == 200) {
        // local'de hızlı kaldır + arka planda yeniden çek
        if (mounted) {
          setState(() {
            for (final entry in _gruplar.entries) {
              entry.value.remove(path);
            }
            _gruplar.removeWhere((_, v) => v.isEmpty);
            _siraliGruplar = _gruplar.keys.toList()
              ..sort((a, b) => b.compareTo(a));
          });
        }
        _bildirim('Fotoğraf silindi');
        fetchImages();
        return true;
      } else {
        debugPrint('sil ${res.statusCode}: ${res.body}');
        String mesaj = 'Silinemedi';
        try {
          final j = jsonDecode(res.body) as Map<String, dynamic>;
          if (j['error'] is String) mesaj = j['error'] as String;
        } catch (_) {}
        _bildirim('$mesaj (${res.statusCode})');
        return false;
      }
    } catch (e) {
      debugPrint('sil exception: $e');
      _bildirim('Silme sırasında bir hata oluştu');
      return false;
    }
  }

  // ── NOTE UPDATE ──────────────────────────────────────────────────────────
  Future<bool> _notGuncelle(String path, String note) async {
    final temiz = note.trim();
    try {
      final Map<String, dynamic> body = {
        'user_id': widget.md.id,
        'path': path,
        'not': temiz,
      };
      final salon = _salonId;
      if (salon != null && salon.isNotEmpty) {
        body['salon_id'] = salon;
      }
      final res = await http.post(
        Uri.parse('$_baseUrl/api/v1/musteriresimnot'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );
      if (res.statusCode == 200) {
        if (mounted) {
          setState(() {
            if (temiz.isEmpty) {
              _notlar.remove(path);
            } else {
              _notlar[path] = temiz;
            }
          });
        }
        _bildirim(temiz.isEmpty ? 'Not silindi' : 'Not kaydedildi');
        return true;
      } else {
        debugPrint('not ${res.statusCode}: ${res.body}');
        String mesaj = 'Not kaydedilemedi';
        try {
          final j = jsonDecode(res.body) as Map<String, dynamic>;
          if (j['error'] is String) mesaj = j['error'] as String;
        } catch (_) {}
        _bildirim('$mesaj (${res.statusCode})');
        return false;
      }
    } catch (e) {
      debugPrint('not exception: $e');
      _bildirim('Not kaydedilirken bir hata oluştu');
      return false;
    }
  }

  /// Not düzenleme akışı. İptal/başarısızlıkta null,
  /// başarıda kaydedilen (kırpılmış) not metnini döndürür ('' = temizlendi).
  Future<String?> _notDuzenle(String path) async {
    final not = await _notSheet(
      networkUrl: '$_baseUrl/$path',
      mevcut: _notlar[path] ?? '',
      actionLabel: 'Kaydet',
      baslik: 'Notu düzenle',
      altMetin: 'Bu fotoğrafa ait notu güncelle veya temizle.',
    );
    if (not == null) return null; // iptal
    final ok = await _notGuncelle(path, not);
    if (!ok) return null;
    return not.trim();
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: scheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Resimlerim',
          style: TextStyle(
            color: scheme.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: -0.2,
          ),
        ),
      ),
      floatingActionButton: _uploading
          ? null
          : FloatingActionButton.extended(
              onPressed: _yeniFotoEkle,
              backgroundColor: scheme.primary,
              foregroundColor: Colors.white,
              elevation: 4,
              icon: const Icon(Icons.add_a_photo_rounded),
              label: const Text(
                'Foto Ekle',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.alphaBlend(
                    scheme.primary.withValues(alpha: 0.10),
                    Colors.white,
                  ),
                  Color.alphaBlend(
                    scheme.tertiary.withValues(alpha: 0.06),
                    Colors.white,
                  ),
                ],
              ),
            ),
            child: SafeArea(
              top: false,
              bottom: false,
              child: isLoading
                  ? Center(
                      child: CircularProgressIndicator(color: scheme.primary))
                  : RefreshIndicator(
                      color: scheme.primary,
                      backgroundColor: Colors.white,
                      strokeWidth: 3,
                      onRefresh: fetchImages,
                      child: _toplamFoto == 0
                          ? _emptyState(context)
                          : _gridList(context),
                    ),
            ),
          ),
          if (_uploading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.35),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: scheme.primary),
                        const SizedBox(height: 12),
                        Text(
                          'Yükleniyor...',
                          style: TextStyle(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w600,
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
    );
  }

  // ── HERO SUMMARY ─────────────────────────────────────────────────────────
  Widget _summaryHero(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary,
            Color.lerp(scheme.primary, scheme.tertiary, 0.6) ?? scheme.primary,
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.tinted(scheme.primary, strength: 1.2),
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(
              Icons.photo_library_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_toplamFoto Fotoğraf',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_siraliGruplar.length} farklı tarihte',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── GROUPED GRID ─────────────────────────────────────────────────────────
  Widget _gridList(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
      children: [
        _summaryHero(context),
        const SizedBox(height: 18),
        ..._siraliGruplar.map((key) {
          final images = _gruplar[key]!;
          return Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: _gunSection(context, key, images),
          );
        }),
      ],
    );
  }

  Widget _gunSection(
      BuildContext context, String key, List<String> images) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: scheme.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _gunBaslik(key),
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.1,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${images.length}',
                style: TextStyle(
                  color: scheme.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: images.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemBuilder: (_, i) {
            final path = images[i];
            final url = '$_baseUrl/$path';
            return _resimKart(
              context,
              url,
              hasNote: _notlar.containsKey(path),
              onTap: () => _acGoruntuleyici(images, i),
              onLongPress: () async {
                final ok = await _silmeIste();
                if (ok) await _resimSil(path);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _resimKart(
    BuildContext context,
    String url, {
    required VoidCallback onTap,
    VoidCallback? onLongPress,
    bool hasNote = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: AppShadows.soft(scheme.primary),
            border: Border.all(
              color: scheme.primary.withValues(alpha: 0.06),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  url,
                  fit: BoxFit.cover,
                  loadingBuilder: (ctx, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      color: scheme.primary.withValues(alpha: 0.05),
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: scheme.primary,
                          value: progress.expectedTotalBytes != null
                              ? progress.cumulativeBytesLoaded /
                                  (progress.expectedTotalBytes ?? 1)
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) => Container(
                    color: scheme.primary.withValues(alpha: 0.05),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.broken_image_rounded,
                      color: scheme.onSurface.withValues(alpha: 0.35),
                    ),
                  ),
                ),
                if (hasNote)
                  Positioned(
                    right: 5,
                    bottom: 5,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.sticky_note_2_rounded,
                        color: Colors.white,
                        size: 13,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── EMPTY ─────────────────────────────────────────────────────────────────
  Widget _emptyState(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        const SizedBox(height: 80),
        Center(
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  scheme.primary.withValues(alpha: 0.14),
                  scheme.tertiary.withValues(alpha: 0.08),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.add_a_photo_rounded,
              color: scheme.primary,
              size: 46,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Henüz fotoğrafın yok',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: scheme.onSurface,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Kameranla çek ya da galeriden seç —\n'
          'eklediğin fotoğraflar salonun panelinde de görünür.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: scheme.onSurface.withValues(alpha: 0.6),
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 22),
        Center(
          child: ElevatedButton.icon(
            onPressed: _yeniFotoEkle,
            icon: const Icon(Icons.add_a_photo_rounded, size: 18),
            label: const Text(
              'Fotoğraf Ekle',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: scheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 22, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── FULL-SCREEN GALLERY VIEWER ───────────────────────────────────────────
class _FullScreenGallery extends StatefulWidget {
  final List<String> paths;
  final String baseUrl;
  final int initialIndex;
  final Map<String, String> notes;
  final Future<bool> Function(String path) onDelete;
  // null = iptal/başarısız; '' = not temizlendi; aksi halde yeni not
  final Future<String?> Function(String path) onEditNote;

  const _FullScreenGallery({
    required this.paths,
    required this.baseUrl,
    required this.initialIndex,
    required this.notes,
    required this.onDelete,
    required this.onEditNote,
  });

  @override
  State<_FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<_FullScreenGallery> {
  late final PageController _controller;
  late int _current;
  late List<String> _paths;
  late Map<String, String> _notes;

  @override
  void initState() {
    super.initState();
    _paths = List<String>.from(widget.paths);
    _notes = Map<String, String>.from(widget.notes);
    _current = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  Future<void> _editNote() async {
    if (_paths.isEmpty) return;
    final path = _paths[_current];
    final result = await widget.onEditNote(path);
    if (result == null) return; // iptal / başarısız
    if (!mounted) return;
    setState(() {
      if (result.isEmpty) {
        _notes.remove(path);
      } else {
        _notes[path] = result;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    if (_paths.isEmpty) return;
    final path = _paths[_current];
    final ok = await widget.onDelete(path);
    if (!ok) return;
    if (!mounted) return;
    setState(() {
      _paths.removeAt(_current);
      if (_paths.isEmpty) {
        Navigator.of(context).pop();
      } else if (_current >= _paths.length) {
        _current = _paths.length - 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: PageView.builder(
              controller: _controller,
              itemCount: _paths.length,
              onPageChanged: (i) => setState(() => _current = i),
              itemBuilder: (_, i) {
                return InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Center(
                    child: Image.network(
                      '${widget.baseUrl}/${_paths[i]}',
                      fit: BoxFit.contain,
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(
                          Icons.broken_image_rounded,
                          color: Colors.white54,
                          size: 60,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            right: 8,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: Colors.white, size: 28),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${_current + 1} / ${_paths.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_note_rounded,
                          color: Colors.white, size: 28),
                      tooltip: 'Not',
                      onPressed: _editNote,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: Colors.white, size: 26),
                      tooltip: 'Sil',
                      onPressed: _delete,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_paths.isNotEmpty && (_notes[_paths[_current]]?.isNotEmpty ?? false))
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: _editNote,
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                    18,
                    14,
                    18,
                    MediaQuery.of(context).padding.bottom + 18,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.72),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.sticky_note_2_rounded,
                          color: Colors.white70, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _notes[_paths[_current]] ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            height: 1.35,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

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
  static const String _baseUrl = 'https://apptest.randevumcepte.com.tr';

  bool isLoading = true;
  bool _uploading = false;

  // group key (tarih string) → list of image paths
  final Map<String, List<String>> _gruplar = {};
  List<String> _siraliGruplar = [];

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
      final response = await http.post(
        Uri.parse('$_baseUrl/api/v1/musteriresimleri'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'user_id': widget.md.id}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final folders = data.map((item) => Islemler.fromJson(item)).toList();

        final Map<String, List<String>> grouped = {};
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
    await _uploadImage(File(picked.path));
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

  Future<void> _uploadImage(File file) async {
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
  void _acGoruntuleyici(List<String> urls, int index) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.92),
        pageBuilder: (_, __, ___) => _FullScreenGallery(
          urls: urls,
          initialIndex: index,
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
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
            final url = '$_baseUrl/${images[i]}';
            return _resimKart(context, url, () {
              final urls = images.map((p) => '$_baseUrl/$p').toList();
              _acGoruntuleyici(urls, i);
            });
          },
        ),
      ],
    );
  }

  Widget _resimKart(
      BuildContext context, String url, VoidCallback onTap) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
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
            child: Image.network(
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
  final List<String> urls;
  final int initialIndex;

  const _FullScreenGallery({
    required this.urls,
    required this.initialIndex,
  });

  @override
  State<_FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<_FullScreenGallery> {
  late final PageController _controller;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
              itemCount: widget.urls.length,
              onPageChanged: (i) => setState(() => _current = i),
              itemBuilder: (_, i) {
                return InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Center(
                    child: Image.network(
                      widget.urls[i],
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
                    '${_current + 1} / ${widget.urls.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:io';
import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:randevu_sistem/yonetici/dashboard/bildirimler/bildirimler_class.dart';
import 'package:randevu_sistem/Frontend/filedownload.dart';
import '../../diger/menu/randvular/randevularmenu.dart';

class BildirimlerScreen extends StatefulWidget {
  final dynamic isletmebilgi;
  final int kullanicirolu;
  final VoidCallback? onNotificationRead;
  const BildirimlerScreen({
    Key? key,
    required this.isletmebilgi,
    required this.kullanicirolu,
    this.onNotificationRead,
  }) : super(key: key);

  @override
  _BildirimlerScreenState createState() => _BildirimlerScreenState();
}

class _BildirimlerScreenState extends State<BildirimlerScreen> {
  late Future<List<SistemBildirimleri>> _items;
  late String _salonId;
  String? _personelId;
  bool _markingAll = false;

  // 0=Tümü, 1=Okunmamış
  int _filter = 0;

  @override
  void initState() {
    super.initState();
    _salonId = widget.isletmebilgi['id'].toString();
    _items = Future.value([]);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _items = _fetchData(_salonId);
    });
  }

  Future<List<SistemBildirimleri>> _fetchData(String salonid) async {
    final localStorage = await SharedPreferences.getInstance();
    final user = jsonDecode(localStorage.getString('user')!);
    final yetkili = jsonDecode(jsonEncode(user['yetkili_olunan_isletmeler']));

    String? personelid;
    for (final item in yetkili) {
      if (item['salon_id'].toString() == salonid.toString()) {
        personelid = item['id'].toString();
      }
    }
    if (personelid == null) {
      throw Exception('Personel ID bulunamadı');
    }
    _personelId = personelid;

    final url = 'https://app.randevumcepte.com.tr/api/v1/bildirimgetir/$salonid/$personelid';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      if (data.isEmpty) return <SistemBildirimleri>[];
      return data.map((e) => SistemBildirimleri.fromJson(e)).toList();
    }
    log('Bildirim getir hata: ${response.statusCode}');
    throw Exception('Bildirimler yüklenemedi');
  }

  Future<void> _markAsRead(String notificationId) async {
    final url = 'https://app.randevumcepte.com.tr/api/v1/bildirimguncelle';
    final res = await http.post(
      Uri.parse(url),
      body: jsonEncode({'bildirim_id': notificationId}),
      headers: {'Content-Type': 'application/json'},
    );
    if (res.statusCode != 200) {
      throw Exception('Bildirim güncellenemedi');
    }
    widget.onNotificationRead?.call();
  }

  Future<void> _markAllAsRead() async {
    if (_personelId == null) return;
    if (_markingAll) return;
    setState(() => _markingAll = true);

    try {
      final url =
          'https://app.randevumcepte.com.tr/api/v1/tumBildirimleriOku/$_salonId/$_personelId';
      final res = await http.post(Uri.parse(url));
      if (res.statusCode == 200) {
        widget.onNotificationRead?.call();
        await _load();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF16A34A),
              behavior: SnackBarBehavior.floating,
              content: const Text('Tüm bildirimler okundu olarak işaretlendi',
                  style: TextStyle(color: Colors.white)),
            ),
          );
        }
      }
    } catch (e) {
      log('Tümünü okundu hatası: $e');
    } finally {
      if (mounted) setState(() => _markingAll = false);
    }
  }

  String _relativeTime(String tarihsaat) {
    try {
      final dt = DateTime.parse(tarihsaat).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 1) return 'Şimdi';
      if (diff.inMinutes < 60) return '${diff.inMinutes} dk önce';
      if (diff.inHours < 24) return '${diff.inHours} sa önce';
      if (diff.inDays == 1) return 'Dün';
      if (diff.inDays < 7) return '${diff.inDays} gün önce';
      return DateFormat('d MMM HH:mm', 'tr_TR').format(dt);
    } catch (_) {
      return tarihsaat;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Color.alphaBlend(scheme.primary.withValues(alpha: 0.18), Colors.white),
            Color.alphaBlend(scheme.tertiary.withValues(alpha: 0.04), Colors.white),
            Colors.white,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          toolbarHeight: 60,
          leading: IconButton(
            icon: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.10),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  size: 16, color: scheme.onSurface),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Bildirimler',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 19,
              letterSpacing: -0.3,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ),
        body: FutureBuilder<List<SistemBildirimleri>>(
          future: _items,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _skeletonList();
            }
            if (snapshot.hasError) {
              return _errorState(snapshot.error.toString());
            }
            final all = snapshot.data ?? <SistemBildirimleri>[];
            final unreadCount = all.where((b) => b.okundu != '1').length;
            final visible = _filter == 0
                ? all
                : all.where((b) => b.okundu != '1').toList();

            return RefreshIndicator(
              color: scheme.primary,
              onRefresh: _load,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _headerBar(all.length, unreadCount),
                  ),
                  if (visible.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _emptyState(),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) => _bildirimCard(visible[i]),
                          childCount: visible.length,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _headerBar(int total, int unread) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      total.toString(),
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                        color: scheme.onSurface,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        unread > 0 ? '$unread yeni' : 'Hepsi okundu',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: unread > 0
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF16A34A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (unread > 0)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _markingAll ? null : _markAllAsRead,
                    borderRadius: BorderRadius.circular(999),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            scheme.primary,
                            scheme.primary.withValues(alpha: 0.78),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: scheme.primary.withValues(alpha: 0.30),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: _markingAll
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.done_all_rounded,
                                    color: Colors.white, size: 14),
                                SizedBox(width: 5),
                                Text(
                                  'Tümünü Oku',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          // Filter pills
          Row(
            children: [
              _filterPill(label: 'Tümü', active: _filter == 0, onTap: () {
                setState(() => _filter = 0);
              }),
              const SizedBox(width: 8),
              _filterPill(
                label: 'Okunmamış',
                active: _filter == 1,
                badge: unread > 0 ? unread.toString() : null,
                onTap: () => setState(() => _filter = 1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterPill({
    required String label,
    required bool active,
    required VoidCallback onTap,
    String? badge,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color:
                active ? scheme.primary : Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(999),
            border: active
                ? null
                : Border.all(
                    color: scheme.primary.withValues(alpha: 0.18), width: 1),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.22),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.white : scheme.primary,
                  letterSpacing: 0.1,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: active
                        ? Colors.white.withValues(alpha: 0.25)
                        : const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _bildirimCard(SistemBildirimleri b) {
    final scheme = Theme.of(context).colorScheme;
    final isRead = b.okundu == '1';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () async {
            if (!isRead) {
              try {
                await _markAsRead(b.id);
                if (mounted) setState(() => b.okundu = '1');
              } catch (_) {}
            }

            if (b.randevuid != 'null') {
              if (!mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RandevularMenu(
                    kullanicirolu: widget.kullanicirolu,
                    isletmebilgi: widget.isletmebilgi,
                    personelid: '',
                    cihazid: '',
                    personel_adi: '',
                    cihaz_adi: '',
                  ),
                ),
              );
            } else if (b.arsiv != null && b.arsiv['uzanti'] != null) {
              await downloadPdf(
                'https://app.randevumcepte.com.tr/${b.arsiv['uzanti']}',
                'appointment_${b.id}',
                context,
              );
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isRead
                    ? Colors.black.withValues(alpha: 0.06)
                    : scheme.primary.withValues(alpha: 0.30),
                width: isRead ? 1 : 1.3,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isRead ? Colors.black : scheme.primary)
                      .withValues(alpha: isRead ? 0.04 : 0.08),
                  blurRadius: isRead ? 6 : 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Sol kenar accent çubuğu
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: isRead
                            ? [
                                Colors.grey.withValues(alpha: 0.15),
                                Colors.grey.withValues(alpha: 0.05),
                              ]
                            : [
                                scheme.primary,
                                scheme.primary.withValues(alpha: 0.55),
                              ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Avatar
                          _avatar(b),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    if (!isRead) ...[
                                      Container(
                                        width: 7,
                                        height: 7,
                                        decoration: BoxDecoration(
                                          color: scheme.primary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                    ],
                                    Expanded(
                                      child: Text(
                                        b.aciklama,
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: isRead
                                              ? FontWeight.w500
                                              : FontWeight.w700,
                                          color: const Color(0xFF1A1A1A),
                                          height: 1.35,
                                          letterSpacing: -0.1,
                                        ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time_rounded,
                                      size: 11,
                                      color: const Color(0xFF1A1A1A)
                                          .withValues(alpha: 0.45),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _relativeTime(b.tarihsaat),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF1A1A1A)
                                            .withValues(alpha: 0.55),
                                      ),
                                    ),
                                    if (b.randevuid != 'null') ...[
                                      const SizedBox(width: 10),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: scheme.primary
                                              .withValues(alpha: 0.10),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          'Randevu',
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w700,
                                            color: scheme.primary,
                                          ),
                                        ),
                                      ),
                                    ] else if (b.arsiv != null &&
                                        b.arsiv['uzanti'] != null) ...[
                                      const SizedBox(width: 10),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEA580C)
                                              .withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: const Text(
                                          'PDF',
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFFC2410C),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 12,
                            color: const Color(0xFF1A1A1A)
                                .withValues(alpha: 0.30),
                          ),
                        ],
                      ),
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

  Widget _avatar(SistemBildirimleri b) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary.withValues(alpha: 0.18),
            scheme.tertiary.withValues(alpha: 0.10),
          ],
        ),
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: Image.network(
          'https://app.randevumcepte.com.tr/${b.avatar}',
          width: 42,
          height: 42,
          fit: BoxFit.cover,
          loadingBuilder: (c, child, progress) {
            if (progress == null) return child;
            return Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: scheme.primary,
                ),
              ),
            );
          },
          errorBuilder: (c, _, __) => Center(
            child: Icon(
              Icons.notifications_rounded,
              size: 22,
              color: scheme.primary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _skeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: 5,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Container(
          height: 78,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    scheme.primary.withValues(alpha: 0.10),
                    scheme.primary.withValues(alpha: 0.04),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_off_outlined,
                size: 40,
                color: scheme.primary.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              _filter == 1
                  ? 'Okunmamış bildirim yok'
                  : 'Bildiriminiz bulunmuyor',
              style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              _filter == 1
                  ? 'Tüm bildirimleriniz okundu olarak işaretli.'
                  : 'Yeni bildirimler burada görünecek.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: const Color(0xFF1A1A1A).withValues(alpha: 0.55),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorState(String msg) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 56, color: Color(0xFFEF4444)),
            const SizedBox(height: 14),
            const Text(
              'Bağlantı sorunu',
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Bildirimler yüklenemedi. Tekrar deneyin.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: const Color(0xFF1A1A1A).withValues(alpha: 0.55),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Tekrar Dene'),
              style: ElevatedButton.styleFrom(
                backgroundColor: scheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// downloadPdf ve indirmedialoggoster — eski mantık korunuyor
Future<void> downloadPdf(String url, String fileName, BuildContext context) async {
  var status = await Permission.storage.request();
  if (!status.isGranted) return;

  ValueNotifier<int> downloadProgressNotifier = ValueNotifier<int>(0);

  Directory downloadsDirectory;
  if (Platform.isAndroid) {
    downloadsDirectory = Directory('/storage/emulated/0/Download');
  } else if (Platform.isIOS) {
    downloadsDirectory = await getApplicationDocumentsDirectory();
  } else {
    throw UnsupportedError('Download not supported');
  }
  final filePath = '${downloadsDirectory.path}/$fileName.pdf';
  Dio dio = Dio();

  indirmedialoggoster(context, 'PDF İndirme', downloadProgressNotifier);

  try {
    await dio.download(
      url,
      filePath,
      onReceiveProgress: (actualBytes, totalBytes) {
        downloadProgressNotifier.value =
            (actualBytes / totalBytes * 100).floor();
      },
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Dosya başarıyla indirildi.')),
    );
  } catch (e) {
    print('Error downloading file: $e');
  }
}

void indirmedialoggoster(BuildContext context, String title,
    ValueNotifier<int> progressNotifier) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ValueListenableBuilder<int>(
            valueListenable: progressNotifier,
            builder: (_, value, __) => Column(
              children: [
                Text('İndiriliyor: %$value'),
                const SizedBox(height: 10),
                LinearProgressIndicator(value: value / 100),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

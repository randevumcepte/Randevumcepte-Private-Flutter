import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;

import 'package:randevu_sistem/Frontend/datetimeformatting.dart';
import 'package:randevu_sistem/Frontend/filedownloader.dart';
import 'package:randevu_sistem/Frontend/sfdatatable.dart';
import 'package:randevu_sistem/Models/colorandtext.dart';
import 'package:randevu_sistem/Models/form.dart';
import 'package:randevu_sistem/Models/musteri_danisanlar.dart';
import 'package:randevu_sistem/theme/app_tokens.dart';

class MusteriPaneliArsivDetay extends StatefulWidget {
  final MusteriDanisan md;
  final dynamic isletmebilgi;

  const MusteriPaneliArsivDetay({
    Key? key,
    required this.md,
    required this.isletmebilgi,
  }) : super(key: key);

  @override
  _MusteriPaneliArsivDetayState createState() => _MusteriPaneliArsivDetayState();
}

class _MusteriPaneliArsivDetayState extends State<MusteriPaneliArsivDetay> {
  late ArsivDataSource2 _arsivDataGridSource;
  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    _initialize();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final text = _searchController.text;
    if (text.isEmpty || text.length >= 3) {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 450), () {
        if (text != _lastQuery) {
          _lastQuery = text;
          _arsivDataGridSource.search(text);
        }
      });
    }
  }

  Future<void> _initialize() async {
    _arsivDataGridSource = ArsivDataSource2(
      cevapladi: '',
      cevapladi2: '',
      rowsPerPage: 10,
      salonid: widget.isletmebilgi['id'].toString(),
      context: context,
      durum: '',
      arama: '',
      musteriDanisanId: widget.md.name,
      musteriid: widget.md.id,
    );
    _arsivDataGridSource.addListener(_onSourceChanged);
    _arsivDataGridSource.isLoadingNotifier.addListener(_onLoadingStateChanged);
    setState(() => _isLoading = false);
  }

  void _onSourceChanged() {
    if (mounted) setState(() {});
  }

  void _onLoadingStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    _arsivDataGridSource.removeListener(_onSourceChanged);
    _arsivDataGridSource.isLoadingNotifier.removeListener(_onLoadingStateChanged);
    super.dispose();
  }

  Future<void> _refresh() async {
    await _arsivDataGridSource.fetchData(
      _arsivDataGridSource.currentPage.toString(),
      _searchController.text,
      false,
    );
  }

  List<Arsiv> get _arsivler => _arsivDataGridSource.rows
      .map((r) => r.getCells()[0].value as Arsiv)
      .toList();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final loading = _arsivDataGridSource.isLoadingNotifier.value;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
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
          bottom: false,
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: scheme.primary))
              : Column(
                  children: [
                    _header(context),
                    _searchField(context),
                    const SizedBox(height: 6),
                    Expanded(
                      child: RefreshIndicator(
                        color: scheme.primary,
                        backgroundColor: Colors.white,
                        strokeWidth: 3,
                        onRefresh: _refresh,
                        child: _arsivler.isEmpty
                            ? _emptyState(context, loading: loading)
                            : ListView.separated(
                                physics: const BouncingScrollPhysics(
                                  parent: AlwaysScrollableScrollPhysics(),
                                ),
                                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                                itemCount: _arsivler.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, i) =>
                                    _arsivCard(context, _arsivler[i]),
                              ),
                      ),
                    ),
                    if (_arsivDataGridSource.totalPages > 1)
                      _paginationBar(context),
                    if (loading && _arsivler.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: scheme.primary,
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  // ── HEADER ────────────────────────────────────────────────────────────────
  Widget _header(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 20, 4),
      child: Row(
        children: [
          Material(
            color: Colors.white,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              customBorder: const CircleBorder(),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.12),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(Icons.arrow_back_rounded, color: scheme.primary, size: 21),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Sözleşmelerim',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: scheme.onSurface,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tüm sözleşme ve belgelerini görüntüle',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurface.withValues(alpha: 0.55),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${_arsivler.length}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: scheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── SEARCH FIELD ──────────────────────────────────────────────────────────
  Widget _searchField(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.soft(scheme.primary),
        ),
        child: TextField(
          controller: _searchController,
          textInputAction: TextInputAction.search,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: scheme.onSurface,
          ),
          decoration: InputDecoration(
            isDense: true,
            hintText: 'Form veya belge adı ara...',
            hintStyle: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: scheme.onSurface.withValues(alpha: 0.45),
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: scheme.primary,
              size: 21,
            ),
            suffixIcon: _searchController.text.isEmpty
                ? null
                : IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: scheme.onSurface.withValues(alpha: 0.55),
                    ),
                    onPressed: () {
                      _searchController.clear();
                    },
                  ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: BorderSide(color: scheme.primary, width: 1.2),
            ),
          ),
        ),
      ),
    );
  }

  // ── EMPTY STATE ───────────────────────────────────────────────────────────
  Widget _emptyState(BuildContext context, {required bool loading}) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      children: [
        const SizedBox(height: 80),
        Center(
          child: Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  scheme.primary.withValues(alpha: 0.16),
                  scheme.tertiary.withValues(alpha: 0.16),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              loading ? Icons.cloud_download_rounded : Icons.description_rounded,
              size: 42,
              color: scheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Center(
          child: Text(
            loading ? 'Belgeler yükleniyor...' : 'Henüz belge yok',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: scheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              loading
                  ? 'Lütfen bekleyin, sözleşme ve belgelerin getiriliyor.'
                  : 'Salon tarafından sana gönderilen sözleşme ve belgeler burada görünür.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: scheme.onSurface.withValues(alpha: 0.55),
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── ARSIV CARD ────────────────────────────────────────────────────────────
  Widget _arsivCard(BuildContext context, Arsiv arsiv) {
    final scheme = Theme.of(context).colorScheme;
    final status = getStatusColorArsiv(arsiv.durum, arsiv.cevapladi, arsiv.cevapladi2);
    final title = (arsiv.form["form_adi"]?.toString() ?? '').toLowerCase() == 'harici'
        ? (arsiv.sozlesme_adi.isNotEmpty ? arsiv.sozlesme_adi : 'Harici Belge')
        : (arsiv.form["form_adi"]?.toString() ?? 'Belge');
    final tarih = formatDateTime(arsiv.tarih_saat);
    final personel = arsiv.personel["personel_adi"]?.toString() ?? '-';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: () => _showDetailSheet(context, arsiv),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: AppShadows.soft(scheme.primary),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      status.color.withValues(alpha: 0.22),
                      status.color.withValues(alpha: 0.10),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _iconForArsiv(arsiv),
                  color: status.color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                              color: scheme.onSurface,
                              height: 1.15,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _statusChip(status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.event_rounded,
                          size: 13,
                          color: scheme.onSurface.withValues(alpha: 0.45),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            tarih,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: scheme.onSurface.withValues(alpha: 0.6),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline_rounded,
                          size: 13,
                          color: scheme.onSurface.withValues(alpha: 0.45),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            personel,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: scheme.onSurface.withValues(alpha: 0.6),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForArsiv(Arsiv a) {
    final formAdi = (a.form["form_adi"]?.toString() ?? '').toLowerCase();
    if (formAdi == 'harici' || a.sozlesme_adi.toLowerCase().contains('belge')) {
      return Icons.attach_file_rounded;
    }
    if (formAdi.contains('sağlık') || formAdi.contains('saglik')) {
      return Icons.health_and_safety_rounded;
    }
    if (formAdi.contains('sözleşme') || formAdi.contains('sozlesme')) {
      return Icons.handshake_rounded;
    }
    if (formAdi.contains('aydınlat') || formAdi.contains('kvkk') || formAdi.contains('onay')) {
      return Icons.verified_user_rounded;
    }
    return Icons.description_rounded;
  }

  Widget _statusChip(ColorAndText status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.text.isEmpty ? '—' : status.text,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: status.color,
          letterSpacing: 0.1,
        ),
      ),
    );
  }

  // ── PAGINATION ────────────────────────────────────────────────────────────
  Widget _paginationBar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final src = _arsivDataGridSource;
    final canPrev = src.currentPage > 1;
    final canNext = src.currentPage < src.totalPages;

    Widget arrow({required IconData icon, required bool enabled, required VoidCallback onTap}) {
      return Material(
        color: enabled ? Colors.white : Colors.white.withValues(alpha: 0.6),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: enabled ? onTap : null,
          customBorder: const CircleBorder(),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: scheme.primary.withValues(alpha: 0.10),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              size: 18,
              color: enabled
                  ? scheme.primary
                  : scheme.onSurface.withValues(alpha: 0.30),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          arrow(
            icon: Icons.chevron_left_rounded,
            enabled: canPrev,
            onTap: () => src.setPage(src.currentPage - 1),
          ),
          const SizedBox(width: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              boxShadow: AppShadows.soft(scheme.primary),
            ),
            child: Text(
              '${src.currentPage} / ${src.totalPages}',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(width: 14),
          arrow(
            icon: Icons.chevron_right_rounded,
            enabled: canNext,
            onTap: () => src.setPage(src.currentPage + 1),
          ),
        ],
      ),
    );
  }

  // ── DETAIL BOTTOM SHEET ───────────────────────────────────────────────────
  void _showDetailSheet(BuildContext context, Arsiv arsiv) {
    final scheme = Theme.of(context).colorScheme;
    final status = getStatusColorArsiv(arsiv.durum, arsiv.cevapladi, arsiv.cevapladi2);
    final title = (arsiv.form["form_adi"]?.toString() ?? '').toLowerCase() == 'harici'
        ? (arsiv.sozlesme_adi.isNotEmpty ? arsiv.sozlesme_adi : 'Harici Belge')
        : (arsiv.form["form_adi"]?.toString() ?? 'Belge');
    final tarih = formatDateTime(arsiv.tarih_saat);
    final personel = arsiv.personel["personel_adi"]?.toString() ?? '-';
    final dogrulamaKodu = arsiv.dogrulama_kodu;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.92,
          expand: false,
          builder: (_, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                controller: controller,
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: scheme.onSurface.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  status.color.withValues(alpha: 0.22),
                                  status.color.withValues(alpha: 0.10),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              _iconForArsiv(arsiv),
                              color: status.color,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                    color: scheme.onSurface,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                _statusChip(status),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _detailRow(context, Icons.person_outline_rounded, 'Müşteri',
                          arsiv.musteridanisan["name"]?.toString() ?? '-'),
                      _detailRow(context, Icons.event_rounded, 'Tarih', tarih),
                      _detailRow(context, Icons.badge_outlined, 'Personel', personel),
                      if (dogrulamaKodu.isNotEmpty && dogrulamaKodu != 'null')
                        _detailRow(
                          context,
                          Icons.verified_user_outlined,
                          'Doğrulama Kodu',
                          dogrulamaKodu,
                          copyable: true,
                        ),
                      if (arsiv.mesaj.isNotEmpty && arsiv.mesaj != 'null')
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: scheme.primary.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.sticky_note_2_outlined,
                                    size: 16, color: scheme.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    arsiv.mesaj,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                      height: 1.4,
                                      color: scheme.onSurface.withValues(alpha: 0.75),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 22),
                      _downloadButton(context, arsiv),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _detailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    bool copyable = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 15, color: scheme.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface.withValues(alpha: 0.5),
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          if (copyable)
            IconButton(
              icon: Icon(Icons.copy_rounded, size: 16, color: scheme.primary),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: value));
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kopyalandı')),
                  );
                }
              },
            ),
        ],
      ),
    );
  }

  Widget _downloadButton(BuildContext context, Arsiv arsiv) {
    final scheme = Theme.of(context).colorScheme;
    final hasFile = arsiv.uzanti.isNotEmpty && arsiv.uzanti != 'null';
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: hasFile ? () => _downloadFile(arsiv) : null,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          decoration: BoxDecoration(
            gradient: hasFile
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      scheme.primary,
                      Color.lerp(scheme.primary, scheme.tertiary, 0.6) ??
                          scheme.primary,
                    ],
                  )
                : null,
            color: hasFile ? null : scheme.onSurface.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: hasFile
                ? [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                hasFile
                    ? Icons.file_download_rounded
                    : Icons.block_rounded,
                color: hasFile
                    ? Colors.white
                    : scheme.onSurface.withValues(alpha: 0.5),
                size: 19,
              ),
              const SizedBox(width: 8),
              Text(
                hasFile ? 'Belgeyi İndir' : 'Bu kayıt için dosya yok',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.1,
                  color: hasFile
                      ? Colors.white
                      : scheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _downloadFile(Arsiv arsiv) async {
    final formAdi = (arsiv.form["form_adi"]?.toString() ?? '').toLowerCase() == 'harici belge'
        ? (arsiv.sozlesme_adi.isNotEmpty ? arsiv.sozlesme_adi : 'belge')
        : (arsiv.form["form_adi"]?.toString() ?? 'belge');
    final safeName = '${arsiv.musteridanisan["name"]}_${arsiv.tarih_saat}_$formAdi${path.extension(arsiv.uzanti)}'
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final downloader = FileDownloader();
    final scheme = Theme.of(context).colorScheme;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('İndirme başlatıldı...'),
        backgroundColor: scheme.primary,
        duration: const Duration(seconds: 2),
      ),
    );

    try {
      final filePath = await downloader.downloadFile(
        'https://apptest.randevumcepte.com.tr/${arsiv.uzanti}',
        safeName,
      );
      log('File downloaded to: $filePath');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('İndirildi: $safeName')),
      );
    } catch (e) {
      log('Failed to download file: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İndirme başarısız oldu.')),
      );
    }
  }
}

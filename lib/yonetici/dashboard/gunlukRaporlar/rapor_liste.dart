import 'dart:async';

import 'package:flutter/material.dart';
import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:randevu_sistem/theme/app_tokens.dart';
import 'package:randevu_sistem/yonetici/dashboard/gunlukRaporlar/rapor_ui.dart';

/// Bir rapor kartinin gosterecegi alanlar (Paket/Urun/Alacak ortak).
class RaporKart {
  final String musteri; // ust satir (kalin)
  final String baslik; // alt satir (paket/urun adi, hizmet vs.)
  final String? tarih; // sol-alt kucuk bilgi
  final String? sagUst; // sag tarafta fiyat/tutar
  final String? altBilgi; // ikinci kucuk bilgi (satan personel / odeme tarihi)
  final IconData altBilgiIcon;
  final bool sagUstUyari; // true ise sag rozet uyari (turuncu) renginde
  final Map<String, dynamic>? data; // tiklamada kullanilacak ham satir

  RaporKart({
    required this.musteri,
    required this.baslik,
    this.tarih,
    this.sagUst,
    this.altBilgi,
    this.altBilgiIcon = Icons.person_outline_rounded,
    this.sagUstUyari = false,
    this.data,
  });
}

/// SfDataGrid yerine kullanilan modern kart-liste rapor sayfasi.
/// Paket Satislari, Urun Satislari ve Alacaklar bu sayfayi paylasir.
class RaporListeSayfa extends StatefulWidget {
  final String baslik;
  final IconData ikon;
  final String statLabel;
  final String aramaHint;
  final String bosBaslik;
  final String bosAltyazi;
  final dynamic isletmebilgi;

  /// (salonid, page, arama) -> Laravel paginate JSON (data, current_page, last_page, total)
  final Future<Map<String, dynamic>> Function(
      String salonid, String page, String arama) fetch;

  /// Tek bir JSON satirini karta donusturur.
  final RaporKart Function(Map<String, dynamic> item) kartMapper;

  /// Bir karta tiklandiginda calisir (orn. tahsilat ekranina git).
  final void Function(BuildContext context, Map<String, dynamic> item)?
      onItemTap;

  const RaporListeSayfa({
    Key? key,
    required this.baslik,
    required this.ikon,
    required this.statLabel,
    required this.aramaHint,
    required this.bosBaslik,
    required this.bosAltyazi,
    required this.isletmebilgi,
    required this.fetch,
    required this.kartMapper,
    this.onItemTap,
  }) : super(key: key);

  @override
  State<RaporListeSayfa> createState() => _RaporListeSayfaState();
}

class _RaporListeSayfaState extends State<RaporListeSayfa> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  String? _salonid;
  bool _isLoading = true;
  bool _sayfaYukleniyor = false;
  String _arama = '';

  List<RaporKart> _kartlar = [];
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalRows = 0;

  @override
  void initState() {
    super.initState();
    _baslat();
    _controller.addListener(_aramaDegisti);
  }

  Future<void> _baslat() async {
    _salonid = await secilisalonid();
    await _veriGetir(1, '');
  }

  void _aramaDegisti() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      final q = _controller.text.trim();
      if (q == _arama) return;
      _arama = q;
      _veriGetir(1, q);
    });
  }

  Future<void> _veriGetir(int page, String arama) async {
    if (_salonid == null) return;
    setState(() => _sayfaYukleniyor = true);
    try {
      final json = await widget.fetch(_salonid!, page.toString(), arama);
      final List<dynamic> data =
          (json['data'] is List) ? json['data'] as List<dynamic> : <dynamic>[];
      _kartlar = data
          .map<RaporKart>(
              (e) => widget.kartMapper(Map<String, dynamic>.from(e as Map)))
          .toList();
      _currentPage = (json['current_page'] ?? 1) as int;
      _totalPages = (json['last_page'] ?? 1) as int;
      _totalRows = (json['total'] ?? _kartlar.length) as int;
    } catch (_) {
      _kartlar = [];
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _sayfaYukleniyor = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    if (_isLoading) {
      return Scaffold(
        appBar: RaporUi.appBar(context, widget.baslik),
        body: Center(
          child: CircularProgressIndicator(color: cs.primary, strokeWidth: 2.5),
        ),
      );
    }

    return Scaffold(
      appBar: RaporUi.appBar(
        context,
        widget.baslik,
        actions: [
          if (widget.isletmebilgi != null &&
              widget.isletmebilgi["demo_hesabi"].toString() == "1")
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              child: SizedBox(
                width: 100,
                child: YukseltButonu(isletme_bilgi: widget.isletmebilgi),
              ),
            ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
              child: RaporUi.statsBanner(
                context,
                label: widget.statLabel,
                value: '$_totalRows',
                icon: widget.ikon,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: RaporUi.searchField(
                context,
                controller: _controller,
                hint: widget.aramaHint,
              ),
            ),
            Expanded(child: _liste()),
            RaporUi.pagination(
              context,
              current: _currentPage,
              total: _totalPages,
              onPage: (p) => _veriGetir(p, _arama),
            ),
          ],
        ),
      ),
    );
  }

  Widget _liste() {
    final cs = context.colors;
    if (_sayfaYukleniyor) {
      return Center(
        child: CircularProgressIndicator(color: cs.primary, strokeWidth: 2.5),
      );
    }
    if (_kartlar.isEmpty) {
      return RaporUi.empty(
        context,
        searching: _arama.isNotEmpty,
        icon: widget.ikon,
        emptyTitle: widget.bosBaslik,
        emptySubtitle: widget.bosAltyazi,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
      itemCount: _kartlar.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _kart(_kartlar[i]),
    );
  }

  Widget _kart(RaporKart k) {
    final cs = context.colors;
    final ext = context.appTheme;
    final tiklanabilir = widget.onItemTap != null && k.data != null;
    final govde = Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.primary.withValues(alpha: 0.10), width: 1),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  cs.primary.withValues(alpha: 0.18),
                  cs.primary.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(widget.ikon, color: cs.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  k.musteri.isEmpty ? '-' : k.musteri,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  k.baslik,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                if (k.tarih != null || k.altBilgi != null) ...[
                  const SizedBox(height: 8),
                  // Tarih + alt bilgi: Row yerine Wrap — dar ekranda taşmak
                  // yerine alt satıra kayar (RenderFlex overflow olmaz).
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      if (k.tarih != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.event_rounded,
                                size: 14,
                                color: cs.onSurfaceVariant
                                    .withValues(alpha: 0.8)),
                            const SizedBox(width: 4),
                            Text(
                              k.tarih!,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      if (k.altBilgi != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(k.altBilgiIcon,
                                size: 14,
                                color: cs.onSurfaceVariant
                                    .withValues(alpha: 0.8)),
                            const SizedBox(width: 4),
                            Text(
                              k.altBilgi!,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (k.sagUst != null) ...[
            const SizedBox(width: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: (k.sagUstUyari ? ext.warningColor : ext.successColor)
                    .withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                k.sagUst!,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: k.sagUstUyari ? ext.warningColor : ext.successColor,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
          if (tiklanabilir) ...[
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded,
                size: 22, color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
          ],
        ],
      ),
    );

    if (!tiklanabilir) return govde;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => widget.onItemTap!(context, k.data!),
        child: govde,
      ),
    );
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Backend/yetki.dart';
import 'package:randevu_sistem/Frontend/sfdatatable.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:randevu_sistem/Models/colorandtext.dart';
import 'package:randevu_sistem/Models/randevular.dart';
import 'package:randevu_sistem/theme/premium_components.dart';

class RandevularMenu extends StatefulWidget {
  final dynamic isletmebilgi;
  final String personelid;
  final String cihazid;
  final String personel_adi;
  final String cihaz_adi;
  final int kullanicirolu;

  const RandevularMenu({
    Key? key,
    required this.kullanicirolu,
    required this.isletmebilgi,
    required this.personelid,
    required this.cihazid,
    required this.cihaz_adi,
    required this.personel_adi,
  }) : super(key: key);

  @override
  _RandevularMenuState createState() => _RandevularMenuState();
}

class _RandevularMenuState extends State<RandevularMenu> {
  Timer? _debounce;
  late RandevuDataSource _randevuDataGridSource;
  late String? seciliisletme;
  bool _isLoading = true;
  bool firsttimetyping = true;
  String? lastQuery;

  final List<String> randevuolusturma = [
    'Tümü',
    'Salon',
    'Web',
    'Uygulama',
  ];
  final List<String> randevudurum = [
    'Tümü',
    'Onay bekleyen',
    'Onaylı',
    'Reddedilen/İptal Edilen',
    'Müşteri tarafından iptal edilen',
  ];
  final List<String> randevutarih = [
    'Tümü',
    'Bugün',
    'Yarın',
    'Bu ay',
    'Önümüzdeki ay',
    'Bu yıl',
    'Önümüzdeki yıl',
  ];

  String selectedrandevuolusturma = 'Tümü';
  String selectedrandevudurum = 'Tümü';
  String selectedrandevutarih = 'Bu yıl';

  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    initialize();
    _controller.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (_controller.text.isEmpty || _controller.text.length >= 3) {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 500), () async {
        if (_controller.text != lastQuery && !firsttimetyping) {
          firsttimetyping = false;
          lastQuery = _controller.text;
          await _applyFilters(page: 1);
        }
      });
    } else {
      if ((_controller.text.isEmpty || _controller.text.length < 3) &&
          firsttimetyping) {
        setState(() => firsttimetyping = false);
      }
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onSearchChanged);
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // Yetki cache'e gore filtre personel_id'sini hesapla.
  // - Personel rolu + 'randevu.tum_personel_gor' KAPALI -> kendi id'si filtre
  // - Aksi durumda -> bos (filtre yok, tum randevular)
  String get _yetkiyeGorePersonelid {
    if (widget.kullanicirolu == 5 &&
        !Yetki.varMi('randevu.tum_personel_gor')) {
      return widget.personelid;
    }
    return '';
  }

  Future<void> initialize() async {
    seciliisletme = await secilisalonid();
    if (!mounted) return;
    // Yetki cache'i hazir degilse tazele; sonra dogru personelid ile fetch.
    if (seciliisletme != null && seciliisletme!.isNotEmpty) {
      await Yetki.tazele(salonid: seciliisletme!);
    }
    if (!mounted) return;
    setState(() {
      _randevuDataGridSource = RandevuDataSource(
        kullanicirolu: widget.kullanicirolu,
        isletmebilgi: widget.isletmebilgi,
        rowsPerPage: 10,
        durum: selectedrandevudurum,
        olusturma: selectedrandevuolusturma,
        salonid: seciliisletme!,
        tarih: selectedrandevutarih,
        context: context,
        musteriid: "",
        personelid: _yetkiyeGorePersonelid,
        cihazid: widget.cihazid,
        musteriMi: false,
      );
      _randevuDataGridSource.isLoadingNotifier.addListener(_onLoadingChanged);
      _randevuDataGridSource.addListener(_onLoadingChanged);
      _isLoading = false;
    });
  }

  void _onLoadingChanged() {
    if (mounted) setState(() {});
  }

  String get _baslik {
    if (widget.personel_adi.isNotEmpty) return '${widget.personel_adi} Randevuları';
    if (widget.cihaz_adi.isNotEmpty) return '${widget.cihaz_adi} Randevuları';
    return 'Randevular';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: PremiumGradientBg(
        child: SafeArea(
          bottom: false,
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: scheme.primary))
              : GestureDetector(
                  onTap: () => FocusScope.of(context).unfocus(),
                  child: Column(
                    children: [
                      _topBar(context),
                      const SizedBox(height: 10),
                      _header(context),
                      const SizedBox(height: 12),
                      _searchBar(context),
                      const SizedBox(height: 10),
                      Expanded(child: _list(context)),
                      _pagination(context),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  // ───────────────────────────── Top Bar
  Widget _topBar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDemo = widget.isletmebilgi["demo_hesabi"].toString() == "1";
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        children: [
          PremiumCircleAction(
            icon: Icons.arrow_back_rounded,
            onTap: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_available_rounded,
                      size: 16, color: scheme.primary),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      _baslik,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: scheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          PremiumCircleAction(
            icon: Icons.refresh_rounded,
            onTap: () async {
              // Yetki cache'ini tazele, sonra listeyi yeniden cek.
              if (seciliisletme != null && seciliisletme!.isNotEmpty) {
                await Yetki.tazele(salonid: seciliisletme!);
              }
              await _applyFilters(page: 1);
            },
          ),
          const SizedBox(width: 8),
          PremiumCircleAction(
            icon: Icons.tune_rounded,
            onTap: _openFilterSheet,
          ),
          if (isDemo) ...[
            const SizedBox(width: 8),
            SizedBox(
              height: 44,
              child: YukseltButonu(isletme_bilgi: widget.isletmebilgi),
            ),
          ],
        ],
      ),
    );
  }

  // ───────────────────────────── Header
  Widget _header(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final toplam = _randevuDataGridSource.randevu.length;
    final sayfa = _randevuDataGridSource.currentPage;
    final son = _randevuDataGridSource.totalPages;
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 4, 22, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Randevular',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: scheme.onSurface,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            son > 0
                ? 'Sayfa $sayfa / $son  •  Bu sayfada $toplam kayıt'
                : 'Henüz kayıt yok',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: scheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────── Search Bar
  Widget _searchBar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.10),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextFormField(
          controller: _controller,
          keyboardType: TextInputType.text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: 'Müşteri adıyla ara…',
            hintStyle: TextStyle(
              color: scheme.onSurface.withValues(alpha: 0.40),
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Icon(Icons.search_rounded,
                color: scheme.primary, size: 20),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.close_rounded,
                        size: 18, color: scheme.onSurface.withValues(alpha: 0.55)),
                    onPressed: () {
                      _controller.clear();
                      setState(() {});
                    },
                  )
                : null,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ),
    );
  }

  // ───────────────────────────── List
  Widget _list(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (_randevuDataGridSource.isLoadingNotifier.value) {
      return Center(child: CircularProgressIndicator(color: scheme.primary));
    }
    final list = _randevuDataGridSource.randevu;
    if (list.isEmpty) {
      return _emptyState(context);
    }
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      itemCount: list.length,
      itemBuilder: (context, i) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _randevuCard(list[i]),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    scheme.primary.withValues(alpha: 0.18),
                    scheme.tertiary.withValues(alpha: 0.10),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(Icons.event_busy_rounded,
                  color: scheme.primary, size: 36),
            ),
            const SizedBox(height: 14),
            Text(
              'Kayıt bulunamadı',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Filtreleri değiştirip tekrar dene.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: scheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _randevuCard(Randevu r) {
    final scheme = Theme.of(context).colorScheme;
    final status = getStatusColorRandevu(r.durum, r.geldimi);
    final tarihParts = r.tarih.split(' ');
    final dateStr = tarihParts.isNotEmpty ? tarihParts[0] : '';
    final timeStr = tarihParts.length > 1 ? tarihParts[1] : '';
    final dateBits = dateStr.split('-');
    final gun = dateBits.length == 3 ? dateBits[2] : '';
    final ay = dateBits.length == 3 ? _ayKisa(dateBits[1]) : '';
    final yil = dateBits.length == 3 ? dateBits[0] : '';

    String hizmetler = '';
    try {
      for (final h in r.hizmetler) {
        final ad = h["hizmetler"]?["hizmet_adi"]?.toString() ?? '';
        if (ad.isNotEmpty) {
          hizmetler += (hizmetler.isEmpty ? '' : ', ') + ad;
        }
      }
    } catch (_) {}

    return PremiumGlassCard(
      padding: const EdgeInsets.all(12),
      onTap: () => _detayDialog(r),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tarih bloğu
          Container(
            width: 58,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  scheme.primary.withValues(alpha: 0.14),
                  scheme.tertiary.withValues(alpha: 0.10),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Text(
                  gun,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: scheme.primary,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  ay,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  yil,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurface.withValues(alpha: 0.50),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Orta blok
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.musteriname,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                if (hizmetler.isNotEmpty)
                  Text(
                    hizmetler,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: scheme.onSurface.withValues(alpha: 0.65),
                      height: 1.3,
                    ),
                  ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded,
                        size: 12, color: scheme.primary.withValues(alpha: 0.75)),
                    const SizedBox(width: 4),
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface.withValues(alpha: 0.70),
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (r.toplam.isNotEmpty && r.toplam != 'null') ...[
                      Icon(Icons.payments_outlined,
                          size: 12,
                          color: scheme.primary.withValues(alpha: 0.75)),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          '${r.toplam} ₺',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface.withValues(alpha: 0.70),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Sağ: status + menü
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _statusBadge(status),
              const SizedBox(height: 6),
              _actionMenu(r),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(ColorAndText s) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: s.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: s.color.withValues(alpha: 0.30),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: s.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            s.text,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: s.color,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionMenu(Randevu r) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: PopupMenuButton<String>(
        tooltip: 'İşlemler',
        padding: EdgeInsets.zero,
        offset: const Offset(0, 32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        icon: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.more_horiz_rounded,
              size: 18, color: scheme.primary),
        ),
        onSelected: (value) => _handleAction(value, r),
        itemBuilder: (ctx) => _menuItems(r),
      ),
    );
  }

  List<PopupMenuEntry<String>> _menuItems(Randevu r) {
    final items = <PopupMenuEntry<String>>[];
    items.add(_menuEntry(
      'detaylibilgi',
      'Detaylı Bilgi',
      Icons.info_outline_rounded,
    ));
    if (r.durum == "0" && widget.kullanicirolu != 5) {
      items.add(_menuEntry(
        'randevuonayla',
        'Onayla',
        Icons.check_circle_outline_rounded,
        tint: const Color(0xFF16A34A),
      ));
    }
    if (r.durum != "2" &&
        r.durum != "3" &&
        r.tahsilat_eklendi != "1" &&
        widget.kullanicirolu != 5) {
      items.add(_menuEntry(
        'randevuiptalet',
        'İptal Et',
        Icons.cancel_outlined,
        tint: const Color(0xFFDC2626),
      ));
    }
    if (r.durum != "0" && widget.kullanicirolu != 5) {
      items.add(_menuEntry(
        'randevuyageldi',
        'Geldi',
        Icons.event_available_rounded,
        tint: const Color(0xFF16A34A),
      ));
      items.add(_menuEntry(
        'randevuyagelmedi',
        'Gelmedi',
        Icons.event_busy_rounded,
        tint: const Color(0xFFDC2626),
      ));
    }
    return items;
  }

  PopupMenuItem<String> _menuEntry(
    String value,
    String label,
    IconData icon, {
    Color? tint,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final c = tint ?? scheme.primary;
    return PopupMenuItem<String>(
      value: value,
      height: 40,
      child: Row(
        children: [
          Icon(icon, size: 16, color: c),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAction(String value, Randevu r) async {
    if (value == 'detaylibilgi') {
      _detayDialog(r);
      return;
    }
    if (value == 'randevuonayla') {
      _optimisticUpdate(r, durum: '1');
      randevuonayla(r.id, context);
      return;
    }
    if (value == 'randevuyageldi') {
      _optimisticUpdate(r, geldimi: '1');
      randevugeldiisaretle(r.id, '', context, '');
      return;
    }
    if (value == 'randevuyagelmedi') {
      _optimisticUpdate(r, geldimi: '0');
      randevugelmediisaretle(r.id, context);
      return;
    }
    if (value == 'randevuiptalet') {
      final onay = await _iptalOnayDialog();
      if (onay != true) return;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final usertype = prefs.getString('user_type') ?? '';
      if (!mounted) return;
      final yeniDurum = usertype == '0' ? '3' : '2';
      _optimisticUpdate(r, durum: yeniDurum);
      _iptalEtSilent(r.id, yeniDurum);
    }
  }

  Future<void> _iptalEtSilent(String randevuid, String durum) async {
    try {
      await http.post(
        Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/randevuiptalet'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'randevuid': randevuid, 'durum': durum}),
      );
    } catch (_) {
      // Optimistic kaldi; hata olsa bile UI tutarli, bir sonraki refresh duzeltir.
    }
  }

  void _optimisticUpdate(Randevu r, {String? durum, String? geldimi}) {
    final idx = _randevuDataGridSource.randevu.indexWhere((x) => x.id == r.id);
    if (idx < 0) return;
    final old = _randevuDataGridSource.randevu[idx];
    setState(() {
      _randevuDataGridSource.randevu[idx] = Randevu(
        id: old.id,
        user_id: old.user_id,
        tarih: old.tarih,
        telefonno: old.telefonno,
        durum: durum ?? old.durum,
        musteriname: old.musteriname,
        geldimi: geldimi ?? old.geldimi,
        hizmetler: old.hizmetler,
        yardimci_personeller: old.yardimci_personeller,
        olusturulma: old.olusturulma,
        olusturan: old.olusturan,
        musteri: old.musteri,
        toplam: old.toplam,
        musterinotu: old.musterinotu,
        personelnotu: old.personelnotu,
        tahsilat_eklendi: old.tahsilat_eklendi,
      );
    });
  }

  void _detayDialog(Randevu r) {
    final scheme = Theme.of(context).colorScheme;
    final status = getStatusColorRandevu(r.durum, r.geldimi);

    String hizmetler = '';
    try {
      for (final h in r.hizmetler) {
        final ad = h["hizmetler"]?["hizmet_adi"]?.toString() ?? '';
        if (ad.isNotEmpty) {
          hizmetler += (hizmetler.isEmpty ? '' : ', ') + ad;
        }
      }
    } catch (_) {}

    String telefon = '';
    try {
      telefon = Yetki.telefonGoster(r.musteri?["cep_telefon"]?.toString());
    } catch (_) {}

    String olusturanAdi = '';
    try {
      olusturanAdi = r.olusturan?["name"]?.toString() ?? '';
    } catch (_) {}

    final musteriNot = (r.musterinotu == 'null' || r.musterinotu.isEmpty)
        ? ''
        : r.musterinotu;
    final personelNot = (r.personelnotu == 'null' || r.personelnotu.isEmpty)
        ? ''
        : r.personelnotu;
    final geldiText = r.geldimi == '1'
        ? 'Geldi'
        : (r.geldimi == '0' ? 'Gelmedi' : '—');

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.40),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.20),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [scheme.primary, scheme.tertiary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.event_available_rounded,
                          color: scheme.onPrimary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.musteriname,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: scheme.onSurface,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Randevu Detayı',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: scheme.onSurface.withValues(alpha: 0.55),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _statusBadge(status),
                  ],
                ),
                const SizedBox(height: 16),
                _detayRow(Icons.calendar_month_outlined, 'Tarih & Saat', r.tarih),
                if (telefon.isNotEmpty)
                  _detayRow(Icons.phone_outlined, 'Telefon', telefon),
                if (hizmetler.isNotEmpty)
                  _detayRow(Icons.spa_outlined, 'Hizmetler', hizmetler),
                if (r.toplam.isNotEmpty && r.toplam != 'null')
                  _detayRow(Icons.payments_outlined, 'Toplam', '${r.toplam} ₺'),
                if (olusturanAdi.isNotEmpty)
                  _detayRow(Icons.person_outline_rounded, 'Oluşturan',
                      olusturanAdi),
                _detayRow(Icons.flag_outlined, 'Geldi mi?', geldiText),
                if (musteriNot.isNotEmpty)
                  _detayRow(Icons.chat_bubble_outline_rounded,
                      'Müşteri Notu', musteriNot),
                if (personelNot.isNotEmpty)
                  _detayRow(Icons.sticky_note_2_outlined, 'Personel Notu',
                      personelNot),
                const SizedBox(height: 14),
                Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () => Navigator.of(ctx).pop(),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [scheme.primary, scheme.tertiary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Kapat',
                          style: TextStyle(
                            color: scheme.onPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
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

  Widget _detayRow(IconData icon, String label, String value) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: scheme.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface.withValues(alpha: 0.55),
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _iptalOnayDialog() {
    final scheme = Theme.of(context).colorScheme;
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.40),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFDC2626).withValues(alpha: 0.20),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFDC2626).withValues(alpha: 0.20),
                      const Color(0xFFDC2626).withValues(alpha: 0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning_amber_rounded,
                    color: Color(0xFFDC2626), size: 30),
              ),
              const SizedBox(height: 14),
              Text(
                'Randevuyu iptal et?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Bu işlem geri alınamaz.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: scheme.onSurface.withValues(alpha: 0.70),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Vazgeç',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface.withValues(alpha: 0.65),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () => Navigator.of(ctx).pop(true),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFDC2626),
                                const Color(0xFFDC2626).withValues(alpha: 0.85),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text(
                              'İptal Et',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _applyFilters({required int page}) async {
    await _randevuDataGridSource.fetchData(
      page.toString(),
      _controller.text,
      selectedrandevuolusturma,
      selectedrandevudurum,
      selectedrandevutarih,
      _yetkiyeGorePersonelid,
      widget.cihazid,
    );
    if (mounted) setState(() {});
  }

  // ───────────────────────────── Pagination
  Widget _pagination(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total = _randevuDataGridSource.totalPages.ceil();
    final cur = _randevuDataGridSource.currentPage;
    final canPrev = cur > 1;
    final canNext = cur < total;
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 6, 16, 12),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            _pageBtn(
              icon: Icons.arrow_back_rounded,
              enabled: canPrev,
              onTap: () => _applyFilters(page: cur - 1),
            ),
            Expanded(
              child: Center(
                child: Text(
                  'Sayfa $cur / $total',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ),
            _pageBtn(
              icon: Icons.arrow_forward_rounded,
              enabled: canNext,
              onTap: () => _applyFilters(page: cur + 1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pageBtn({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 42,
          height: 38,
          decoration: BoxDecoration(
            color: enabled
                ? scheme.primary.withValues(alpha: 0.10)
                : scheme.onSurface.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
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

  // ───────────────────────────── Filter Sheet
  void _openFilterSheet() {
    final scheme = Theme.of(context).colorScheme;
    String tarih = selectedrandevutarih;
    String durum = selectedrandevudurum;
    String olusturma = selectedrandevuolusturma;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: StatefulBuilder(
            builder: (ctx, setSheet) {
              return Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.20),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: scheme.onSurface.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [scheme.primary, scheme.tertiary],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.tune_rounded,
                              color: scheme.onPrimary, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Filtrele',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: scheme.onSurface,
                                ),
                              ),
                              Text(
                                'Sonuçları daralt',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      scheme.onSurface.withValues(alpha: 0.55),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _sheetLabel('Tarih', Icons.calendar_month_outlined),
                    const SizedBox(height: 6),
                    _sheetDropdown(
                      value: tarih,
                      items: randevutarih,
                      onChanged: (v) => setSheet(() => tarih = v ?? 'Tümü'),
                    ),
                    const SizedBox(height: 12),
                    _sheetLabel('Randevu Durumu', Icons.flag_outlined),
                    const SizedBox(height: 6),
                    _sheetDropdown(
                      value: durum,
                      items: randevudurum,
                      onChanged: (v) => setSheet(() => durum = v ?? 'Tümü'),
                    ),
                    const SizedBox(height: 12),
                    _sheetLabel(
                        'Oluşturma Yeri', Icons.devices_other_outlined),
                    const SizedBox(height: 6),
                    _sheetDropdown(
                      value: olusturma,
                      items: randevuolusturma,
                      onChanged: (v) => setSheet(() => olusturma = v ?? 'Tümü'),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Vazgeç',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurface
                                    .withValues(alpha: 0.65),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              onTap: () async {
                                Navigator.of(ctx).pop();
                                setState(() {
                                  selectedrandevutarih = tarih;
                                  selectedrandevudurum = durum;
                                  selectedrandevuolusturma = olusturma;
                                });
                                log("durum $durum");
                                await _applyFilters(page: 1);
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 13),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      scheme.primary,
                                      scheme.tertiary,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_rounded,
                                        size: 16, color: scheme.onPrimary),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Uygula',
                                      style: TextStyle(
                                        color: scheme.onPrimary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.2,
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
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _sheetLabel(String label, IconData icon) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 14, color: scheme.primary.withValues(alpha: 0.85)),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface.withValues(alpha: 0.72),
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }

  Widget _sheetDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: scheme.primary.withValues(alpha: 0.18),
          width: 1.2,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton2<String>(
          isExpanded: true,
          value: value,
          items: items
              .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(
                      e,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
          iconStyleData: IconStyleData(
            icon: Icon(Icons.keyboard_arrow_down_rounded,
                color: scheme.primary, size: 22),
          ),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
          buttonStyleData: const ButtonStyleData(
            padding: EdgeInsets.zero,
            height: 44,
          ),
          dropdownStyleData: DropdownStyleData(
            maxHeight: 280,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.16),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            offset: const Offset(0, -4),
          ),
          menuItemStyleData: const MenuItemStyleData(
            height: 44,
            padding: EdgeInsets.symmetric(horizontal: 14),
          ),
        ),
      ),
    );
  }

  String _ayKisa(String mm) {
    switch (mm) {
      case '01':
        return 'OCA';
      case '02':
        return 'ŞUB';
      case '03':
        return 'MAR';
      case '04':
        return 'NİS';
      case '05':
        return 'MAY';
      case '06':
        return 'HAZ';
      case '07':
        return 'TEM';
      case '08':
        return 'AĞU';
      case '09':
        return 'EYL';
      case '10':
        return 'EKİ';
      case '11':
        return 'KAS';
      case '12':
        return 'ARA';
      default:
        return mm;
    }
  }
}

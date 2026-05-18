import 'package:flutter/material.dart';
import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Frontend/sfdatatable.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:randevu_sistem/Models/odalar.dart';

class OdaEkle extends StatefulWidget {
  final OdaDataSource odadatasource;
  final dynamic isletmebilgi;
  final Oda? oda;
  const OdaEkle({
    super.key,
    required this.odadatasource,
    required this.isletmebilgi,
    this.oda,
  });

  @override
  State<OdaEkle> createState() => _OdaEkleState();
}

class _OdaEkleState extends State<OdaEkle> {
  final TextEditingController _odaAdi = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _seciliisletme;
  bool _saving = false;
  bool _loadingPersonel = true;
  List<Map<String, String>> _personeller = const [];
  final Set<String> _seciliPersonelIds = <String>{};

  bool get _duzenleme => widget.oda != null;

  static const Color _accent = Color(0xFF6366F1);
  static const Color _accentSoft = Color(0xFF818CF8);

  @override
  void initState() {
    super.initState();
    if (_duzenleme) {
      _odaAdi.text = widget.oda!.oda_adi;
    }
    _fetchData();
  }

  Future<void> _fetchData() async {
    _seciliisletme = (await secilisalonid())!;
    try {
      final personeller = await odaPersonelListesi(_seciliisletme!);
      if (_duzenleme) {
        try {
          final detay = await odaDetayGetir(widget.oda!.id);
          final ids = (detay['personel_ids'] as List? ?? const [])
              .map((e) => e.toString())
              .toList();
          _seciliPersonelIds
            ..clear()
            ..addAll(ids);
        } catch (_) {}
      }
      if (mounted) {
        setState(() {
          _personeller = personeller;
          _loadingPersonel = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingPersonel = false);
    }
  }

  @override
  void dispose() {
    _odaAdi.dispose();
    super.dispose();
  }

  Future<void> _kaydet() async {
    if (_seciliisletme == null) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await widget.odadatasource.odaekle(
      _odaAdi.text.trim(),
      _seciliisletme!,
      context,
      personelIds: _seciliPersonelIds.toList(),
      odaId: _duzenleme ? widget.oda!.id : null,
    );
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _personelSecimiAc() async {
    if (_personeller.isEmpty) return;
    final secim = Set<String>.from(_seciliPersonelIds);
    final sonuc = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _PersonelSecimSheet(
          personeller: _personeller,
          baslangicSecim: secim,
          accent: _accent,
          accentSoft: _accentSoft,
        );
      },
    );
    if (sonuc != null && mounted) {
      setState(() {
        _seciliPersonelIds
          ..clear()
          ..addAll(sonuc);
      });
    }
  }

  String? _personelAdi(String id) {
    for (final p in _personeller) {
      if (p['id'] == id) return p['personel_adi'];
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 62,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.black, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _duzenleme ? 'Oda Düzenle' : 'Yeni Oda',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          if (widget.isletmebilgi["demo_hesabi"].toString() == "1")
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              child: SizedBox(
                width: 100,
                child: YukseltButonu(isletme_bilgi: widget.isletmebilgi),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.black12),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
            children: [
              _buildHeroCard(),
              const SizedBox(height: 14),
              _buildFormCard(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _saving ? null : _kaydet,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                disabledBackgroundColor: _accent.withValues(alpha: 0.5),
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: _accent.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ).copyWith(
                elevation: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.disabled) ? 0 : 4),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline_rounded, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Kaydet',
                          style: TextStyle(
                            fontSize: 15,
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
    );
  }

  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_accentSoft, _accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: 0.30),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.meeting_room_rounded,
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _duzenleme ? 'Odayı Düzenle' : 'Yeni Oda Ekle',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Oda adını ve odada çalışacak personelleri belirleyin.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _accent.withValues(alpha: 0.10),
        ),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.label_important_outline_rounded,
                    color: _accent, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'Oda Bilgileri',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14.5,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _label('Oda Adı'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _odaAdi,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(
                fontSize: 14.5, fontWeight: FontWeight.w600),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Lütfen oda adı girin';
              }
              return null;
            },
            decoration: _inputDecoration('Ör. Masaj Odası 1'),
          ),
          const SizedBox(height: 18),
          _label('Personel (opsiyonel)'),
          const SizedBox(height: 8),
          _buildPersonelSecim(),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: Colors.grey[500],
        fontSize: 13.5,
        fontWeight: FontWeight.w500,
      ),
      filled: true,
      fillColor: const Color(0xFFF8FAFB),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _accent.withValues(alpha: 0.15)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _accent.withValues(alpha: 0.15)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _accent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFDC2626)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
      ),
    );
  }

  Widget _buildPersonelSecim() {
    if (_loadingPersonel) {
      return Container(
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _accent.withValues(alpha: 0.15)),
        ),
        alignment: Alignment.center,
        child: const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            color: _accent,
            strokeWidth: 2,
          ),
        ),
      );
    }
    if (_personeller.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _accent.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded,
                size: 18, color: Colors.grey[600]),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Bu işletmede aktif personel bulunmuyor.',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return InkWell(
      onTap: _personelSecimiAc,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _accent.withValues(alpha: 0.15)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: _seciliPersonelIds.isEmpty
                  ? Text(
                      'Personel seçiniz (boş bırakılabilir)',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  : Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _seciliPersonelIds.map((id) {
                        final ad = _personelAdi(id) ?? '#$id';
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _accent.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: _accent.withValues(alpha: 0.30),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                ad,
                                style: const TextStyle(
                                  color: _accent,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () => setState(
                                    () => _seciliPersonelIds.remove(id)),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 14,
                                  color: _accent,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded,
                color: _accent, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        color: Colors.grey[800],
        letterSpacing: 0.1,
      ),
    );
  }
}

class _PersonelSecimSheet extends StatefulWidget {
  final List<Map<String, String>> personeller;
  final Set<String> baslangicSecim;
  final Color accent;
  final Color accentSoft;
  const _PersonelSecimSheet({
    required this.personeller,
    required this.baslangicSecim,
    required this.accent,
    required this.accentSoft,
  });

  @override
  State<_PersonelSecimSheet> createState() => _PersonelSecimSheetState();
}

class _PersonelSecimSheetState extends State<_PersonelSecimSheet> {
  late final Set<String> _secim;
  String _arama = '';

  @override
  void initState() {
    super.initState();
    _secim = Set<String>.from(widget.baslangicSecim);
  }

  @override
  Widget build(BuildContext context) {
    final filtreli = widget.personeller.where((p) {
      if (_arama.isEmpty) return true;
      return (p['personel_adi'] ?? '')
          .toLowerCase()
          .contains(_arama.toLowerCase());
    }).toList();
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [widget.accentSoft, widget.accent],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.people_alt_rounded,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Personel Seç',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                Text(
                  '${_secim.length} seçili',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: widget.accent,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _arama = v),
              style: const TextStyle(
                  fontSize: 13.5, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'Personel adıyla ara',
                hintStyle: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: Icon(Icons.search_rounded,
                    color: widget.accent, size: 20),
                filled: true,
                fillColor: const Color(0xFFF8FAFB),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: widget.accent.withValues(alpha: 0.15)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: widget.accent.withValues(alpha: 0.15)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: widget.accent, width: 1.5),
                ),
              ),
            ),
          ),
          Flexible(
            child: filtreli.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Eşleşme bulunamadı.',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding:
                        const EdgeInsets.fromLTRB(8, 4, 8, 8),
                    itemCount: filtreli.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (context, i) {
                      final p = filtreli[i];
                      final id = p['id']!;
                      final ad = p['personel_adi'] ?? '';
                      final secili = _secim.contains(id);
                      return Material(
                        color: secili
                            ? widget.accent.withValues(alpha: 0.08)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => setState(() {
                            if (secili) {
                              _secim.remove(id);
                            } else {
                              _secim.add(id);
                            }
                          }),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 10),
                            child: Row(
                              children: [
                                AnimatedContainer(
                                  duration:
                                      const Duration(milliseconds: 150),
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: secili
                                        ? widget.accent
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: secili
                                          ? widget.accent
                                          : Colors.black26,
                                      width: 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                  alignment: Alignment.center,
                                  child: secili
                                      ? const Icon(Icons.check_rounded,
                                          size: 16, color: Colors.white)
                                      : const SizedBox.shrink(),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    ad,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: secili
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                      color: secili
                                          ? widget.accent
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 13),
                        side: BorderSide(
                            color: widget.accent.withValues(alpha: 0.3)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Vazgeç',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, _secim),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.accent,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Tamam',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

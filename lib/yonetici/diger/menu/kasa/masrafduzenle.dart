import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:randevu_sistem/Frontend/sfdatatable.dart';
import 'package:randevu_sistem/Frontend/tl_input_formatter.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:randevu_sistem/Models/masrafkategorileri.dart';
import 'package:randevu_sistem/Models/masraflar.dart';
import 'package:randevu_sistem/Models/odemeturu.dart';
import 'package:randevu_sistem/Models/personel.dart';
import 'package:randevu_sistem/theme/premium_components.dart';

class MasrafDuzenle extends StatefulWidget {
  final List<MasrafKategorisi> masrafkategorileri;
  final List<Personel> personeller;
  final GiderDataSource giderDataSource;
  final String seciliisletme;
  final Masraf masraf;
  final dynamic isletmebilgi;

  const MasrafDuzenle({
    super.key,
    required this.personeller,
    required this.masrafkategorileri,
    required this.giderDataSource,
    required this.seciliisletme,
    required this.masraf,
    required this.isletmebilgi,
  });

  @override
  _MasrafDuzenleState createState() => _MasrafDuzenleState();
}

class _MasrafDuzenleState extends State<MasrafDuzenle> {
  final List<OdemeTuru> _odemeYontemleri = [
    OdemeTuru(id: '1', odeme_turu: 'Nakit'),
    OdemeTuru(id: '2', odeme_turu: 'Kredi/Banka Kartı'),
    OdemeTuru(id: '3', odeme_turu: 'Havale/EFT'),
  ];

  Personel? _selectedHarcayan;
  MasrafKategorisi? _selectedKategori;
  OdemeTuru? _selectedOdemeYontemi;

  final TextEditingController _tarihCtrl = TextEditingController();
  final TextEditingController _tutarCtrl = TextEditingController();
  final TextEditingController _aciklamaCtrl = TextEditingController();
  final TextEditingController _kategoriAramaCtrl = TextEditingController();
  final TextEditingController _harcayanAramaCtrl = TextEditingController();

  DateTime? _seciliTarih;
  bool _kaydediliyor = false;

  @override
  void initState() {
    super.initState();

    // Tarih: backend 'yyyy-MM-dd' -> ekranda 'dd.MM.yyyy'
    try {
      _seciliTarih = DateTime.parse('${widget.masraf.tarih}T00:00:00');
    } catch (_) {
      _seciliTarih = DateTime.now();
    }
    _tarihCtrl.text = DateFormat('dd.MM.yyyy').format(_seciliTarih!);

    // Tutar: backend (nokta ondalık) -> TL gösterimi
    _tutarCtrl.text = backendToTl(widget.masraf.tutar);

    // Açıklama
    final aciklama = widget.masraf.aciklama;
    _aciklamaCtrl.text =
        (aciklama != 'null' && aciklama.trim().isNotEmpty) ? aciklama : '';

    // Seçili değerler
    for (final k in widget.masrafkategorileri) {
      if (k.kategori == widget.masraf.masraf_kategorisi["kategori"]) {
        _selectedKategori = k;
        break;
      }
    }
    for (final p in widget.personeller) {
      if (p.personel_adi == widget.masraf.harcayan["personel_adi"]) {
        _selectedHarcayan = p;
        break;
      }
    }
    for (final y in _odemeYontemleri) {
      if (y.id == widget.masraf.odeme_yontemi_id) {
        _selectedOdemeYontemi = y;
        break;
      }
    }
  }

  @override
  void dispose() {
    _tarihCtrl.dispose();
    _tutarCtrl.dispose();
    _aciklamaCtrl.dispose();
    _kategoriAramaCtrl.dispose();
    _harcayanAramaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDemo = widget.isletmebilgi["demo_hesabi"].toString() == "1";

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: scheme.surface,
        body: PremiumGradientBg(
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(scheme, isDemo),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                    children: [
                      _buildTarihTutarCard(scheme),
                      const SizedBox(height: 12),
                      _buildKategoriCard(scheme),
                      const SizedBox(height: 12),
                      _buildOdemeYontemiCard(scheme),
                      const SizedBox(height: 12),
                      _buildHarcayanCard(scheme),
                      const SizedBox(height: 12),
                      _buildAciklamaCard(scheme),
                    ],
                  ),
                ),
                _buildBottomSave(scheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme scheme, bool isDemo) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: [
          PremiumCircleAction(
            icon: Icons.close_rounded,
            onTap: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Masraf Düzenle',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                    letterSpacing: -0.4,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Gider kaydını güncelle',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          if (isDemo)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: SizedBox(
                width: 96,
                child: YukseltButonu(isletme_bilgi: widget.isletmebilgi),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTarihTutarCard(ColorScheme scheme) {
    return _glassCard(
      scheme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel(scheme, 'Masraf Bilgileri', Icons.receipt_long_outlined),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _fieldWithLabel(
                  scheme,
                  label: 'Tarih',
                  child: _tarihAlani(scheme),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _fieldWithLabel(
                  scheme,
                  label: 'Tutar (₺)',
                  child: _modernInput(
                    scheme,
                    controller: _tutarCtrl,
                    hint: '0,00',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [TurkishLiraInputFormatter()],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tarihAlani(ColorScheme scheme) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: _tarihSec,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: scheme.outline.withValues(alpha: 0.25),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 14,
                color: scheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _tarihCtrl.text.isEmpty ? 'Seç' : _tarihCtrl.text,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: _tarihCtrl.text.isEmpty
                        ? scheme.onSurface.withValues(alpha: 0.4)
                        : scheme.onSurface,
                  ),
                ),
              ),
              Icon(
                Icons.expand_more_rounded,
                size: 16,
                color: scheme.onSurface.withValues(alpha: 0.45),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _tarihSec() async {
    FocusScope.of(context).unfocus();
    final picked = await showDatePicker(
      context: context,
      initialDate: _seciliTarih ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _seciliTarih = picked;
        _tarihCtrl.text = DateFormat('dd.MM.yyyy').format(picked);
      });
    }
  }

  Widget _buildKategoriCard(ColorScheme scheme) {
    return _glassCard(
      scheme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel(scheme, 'Masraf Kategorisi', Icons.category_outlined),
          const SizedBox(height: 10),
          _dropdownContainer(
            scheme,
            child: DropdownButtonHideUnderline(
              child: DropdownButton2<MasrafKategorisi>(
                isExpanded: true,
                hint: Text(
                  'Kategori seçiniz',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
                items: widget.masrafkategorileri
                    .map(
                      (item) => DropdownMenuItem(
                        value: item,
                        child: Text(
                          item.kategori,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                value: _selectedKategori,
                onChanged: (value) => setState(() => _selectedKategori = value),
                buttonStyleData: const ButtonStyleData(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  height: 44,
                ),
                iconStyleData: IconStyleData(
                  icon: Icon(
                    Icons.expand_more_rounded,
                    color: scheme.onSurface.withValues(alpha: 0.45),
                  ),
                ),
                dropdownStyleData: DropdownStyleData(
                  maxHeight: 280,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: scheme.primary.withValues(alpha: 0.10),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                ),
                menuItemStyleData: const MenuItemStyleData(height: 40),
                dropdownSearchData: DropdownSearchData(
                  searchController: _kategoriAramaCtrl,
                  searchInnerWidgetHeight: 50,
                  searchInnerWidget: _aramaInputWrapper(
                      scheme, _kategoriAramaCtrl, 'Kategori ara...'),
                  searchMatchFn: (item, searchValue) {
                    return item.value
                        .toString()
                        .toLowerCase()
                        .contains(searchValue.toLowerCase());
                  },
                ),
                onMenuStateChange: (isOpen) {
                  if (!isOpen) _kategoriAramaCtrl.clear();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOdemeYontemiCard(ColorScheme scheme) {
    return _glassCard(
      scheme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel(
              scheme, 'Ödeme Yöntemi', Icons.account_balance_wallet_outlined),
          const SizedBox(height: 10),
          Row(
            children: _odemeYontemleri.map((y) {
              final secili = _selectedOdemeYontemi?.id == y.id;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: y == _odemeYontemleri.last ? 0 : 8,
                  ),
                  child: _odemeChip(scheme, y, secili),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _odemeChip(ColorScheme scheme, OdemeTuru y, bool secili) {
    IconData icon;
    switch (y.id) {
      case '1':
        icon = Icons.payments_rounded;
        break;
      case '2':
        icon = Icons.credit_card_rounded;
        break;
      default:
        icon = Icons.account_balance_rounded;
    }
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => setState(() => _selectedOdemeYontemi = y),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(
            color: secili
                ? scheme.primary.withValues(alpha: 0.10)
                : Colors.white,
            border: Border.all(
              color: secili
                  ? scheme.primary
                  : scheme.outline.withValues(alpha: 0.25),
              width: secili ? 1.4 : 1,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: secili
                    ? scheme.primary
                    : scheme.onSurface.withValues(alpha: 0.55),
              ),
              const SizedBox(height: 6),
              Text(
                y.odeme_turu,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                  color: secili
                      ? scheme.primary
                      : scheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHarcayanCard(ColorScheme scheme) {
    return _glassCard(
      scheme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel(scheme, 'Harcayan', Icons.person_outline_rounded),
          const SizedBox(height: 10),
          _dropdownContainer(
            scheme,
            child: DropdownButtonHideUnderline(
              child: DropdownButton2<Personel>(
                isExpanded: true,
                hint: Text(
                  'Personel seçiniz',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
                items: widget.personeller
                    .map(
                      (item) => DropdownMenuItem(
                        value: item,
                        child: Text(
                          item.personel_adi,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                value: _selectedHarcayan,
                onChanged: (value) => setState(() => _selectedHarcayan = value),
                buttonStyleData: const ButtonStyleData(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  height: 44,
                ),
                iconStyleData: IconStyleData(
                  icon: Icon(
                    Icons.expand_more_rounded,
                    color: scheme.onSurface.withValues(alpha: 0.45),
                  ),
                ),
                dropdownStyleData: DropdownStyleData(
                  maxHeight: 280,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: scheme.primary.withValues(alpha: 0.10),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                ),
                menuItemStyleData: const MenuItemStyleData(height: 40),
                dropdownSearchData: DropdownSearchData(
                  searchController: _harcayanAramaCtrl,
                  searchInnerWidgetHeight: 50,
                  searchInnerWidget: _aramaInputWrapper(
                      scheme, _harcayanAramaCtrl, 'Personel ara...'),
                  searchMatchFn: (item, searchValue) {
                    return item.value
                        .toString()
                        .toLowerCase()
                        .contains(searchValue.toLowerCase());
                  },
                ),
                onMenuStateChange: (isOpen) {
                  if (!isOpen) _harcayanAramaCtrl.clear();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAciklamaCard(ColorScheme scheme) {
    return _glassCard(
      scheme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel(scheme, 'Açıklama', Icons.notes_rounded),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: scheme.outline.withValues(alpha: 0.25),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextFormField(
              controller: _aciklamaCtrl,
              keyboardType: TextInputType.multiline,
              maxLines: 3,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Bu masrafa dair kısa bir not...',
                hintStyle: TextStyle(
                  color: scheme.onSurface.withValues(alpha: 0.35),
                  fontWeight: FontWeight.w500,
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSave(ColorScheme scheme) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [scheme.primary, scheme.tertiary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: _kaydediliyor ? null : _kaydet,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                alignment: Alignment.center,
                child: _kaydediliyor
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: scheme.onPrimary,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_rounded,
                            color: scheme.onPrimary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Değişiklikleri Kaydet',
                            style: TextStyle(
                              color: scheme.onPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _kaydet() async {
    FocusScope.of(context).unfocus();
    if (_seciliTarih == null) {
      _uyari('Lütfen tarih seçiniz.');
      return;
    }
    if (_tutarCtrl.text.trim().isEmpty) {
      _uyari('Lütfen tutar giriniz.');
      return;
    }
    if (_selectedKategori == null) {
      _uyari('Lütfen masraf kategorisi seçiniz.');
      return;
    }
    if (_selectedOdemeYontemi == null) {
      _uyari('Lütfen ödeme yöntemini seçiniz.');
      return;
    }
    if (_selectedHarcayan == null) {
      _uyari('Lütfen harcayan personeli seçiniz.');
      return;
    }

    setState(() => _kaydediliyor = true);
    try {
      final apiTarih = DateFormat('yyyy-MM-dd').format(_seciliTarih!);
      widget.giderDataSource.masrafEkleGuncelle(
        widget.masraf.id,
        _tutarCtrl.text,
        _selectedKategori!,
        _aciklamaCtrl.text,
        _selectedOdemeYontemi!,
        _selectedHarcayan!,
        context,
        widget.seciliisletme,
        apiTarih,
      );
    } finally {
      if (mounted) setState(() => _kaydediliyor = false);
    }
  }

  void _uyari(String mesaj) {
    showPremiumWarning(
      context,
      title: 'Eksik Bilgi',
      message: mesaj,
      tone: 'warning',
    );
  }

  // --- Reusable building blocks (masrafekle ile aynı dil) ---

  Widget _glassCard(ColorScheme scheme, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionLabel(ColorScheme scheme, String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: scheme.primary),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: scheme.onSurface,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  Widget _fieldWithLabel(
    ColorScheme scheme, {
    required String label,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface.withValues(alpha: 0.65),
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }

  Widget _modernInput(
    ColorScheme scheme, {
    required TextEditingController controller,
    required String hint,
    required TextInputType keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: scheme.outline.withValues(alpha: 0.25),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: scheme.onSurface.withValues(alpha: 0.35),
            fontWeight: FontWeight.w500,
          ),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }

  Widget _dropdownContainer(ColorScheme scheme, {required Widget child}) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: scheme.outline.withValues(alpha: 0.25),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }

  Widget _aramaInputWrapper(
    ColorScheme scheme,
    TextEditingController controller,
    String hint,
  ) {
    return Container(
      height: 50,
      padding: const EdgeInsets.only(top: 8, bottom: 4, left: 8, right: 8),
      child: TextFormField(
        controller: controller,
        expands: true,
        maxLines: null,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          hintText: hint,
          hintStyle: TextStyle(
            fontSize: 12,
            color: scheme.onSurface.withValues(alpha: 0.45),
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 16,
            color: scheme.onSurface.withValues(alpha: 0.45),
          ),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 28, minHeight: 28),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: scheme.outline.withValues(alpha: 0.25),
            ),
          ),
        ),
      ),
    );
  }
}

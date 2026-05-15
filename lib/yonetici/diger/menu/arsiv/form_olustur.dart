import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Models/isletmehizmetleri.dart';
import 'package:randevu_sistem/Models/musteri_danisanlar.dart';
import 'package:randevu_sistem/Models/personel.dart';
import 'package:randevu_sistem/Models/sozlesme.dart';
import 'package:randevu_sistem/theme/premium_components.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Web'deki formolusturma.blade.php sayfasının mobil karşılığı.
/// Bir form şablonu seçilir, müşteri/personel/hizmet bilgileri girilir,
/// /api/v1/arsivformekleguncelle ile gönderilir.
class FormOlustur extends StatefulWidget {
  final dynamic isletmebilgi;
  const FormOlustur({super.key, required this.isletmebilgi});

  @override
  State<FormOlustur> createState() => _FormOlusturState();
}

class _FormOlusturState extends State<FormOlustur> {
  String _seciliSube = '';
  bool _yukleniyor = true;
  bool _gonderiliyor = false;
  String? _hataMesaji;

  List<Sozlesme> _formlar = [];
  List<MusteriDanisan> _musteriler = [];
  List<Personel> _personeller = [];
  List<IsletmeHizmet> _hizmetler = [];

  Sozlesme? _form;
  MusteriDanisan? _musteri;
  Personel? _personel;
  IsletmeHizmet? _hizmet;
  String _cinsiyet = 'Kadın';

  final _telefon = TextEditingController();
  final _tc = TextEditingController();
  final _dogum = TextEditingController();
  final _personelTel = TextEditingController();
  final _ucret = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    _baslat();
  }

  @override
  void dispose() {
    _telefon.dispose();
    _tc.dispose();
    _dogum.dispose();
    _personelTel.dispose();
    _ucret.dispose();
    super.dispose();
  }

  Future<void> _baslat() async {
    try {
      _seciliSube = (await secilisalonid()) ?? '';
      final veri = await isletmeVerileriGetir(
          _seciliSube, false, '', '', '', 0, 0);
      _formlar = ((veri['formlar'] ?? []) as List).whereType<Sozlesme>().toList();
      _musteriler = ((veri['musteriler'] ?? []) as List)
          .whereType<MusteriDanisan>()
          .toList();
      _personeller = ((veri['personeller'] ?? []) as List)
          .whereType<Personel>()
          .toList();
      _hizmetler = ((veri['hizmetler'] ?? []) as List)
          .whereType<IsletmeHizmet>()
          .toList();
    } catch (e) {
      _hataMesaji = 'Veriler yüklenemedi: $e';
    }
    if (mounted) setState(() => _yukleniyor = false);
  }

  Future<void> _formSec() async {
    final s = await _picker<Sozlesme>(
      baslik: 'Form / Sözleşme Türü',
      ogeler: _formlar,
      etiket: (f) => f.form_adi,
      altYazi: (_) => '',
      seciliId: _form?.id,
      ogeId: (f) => f.id,
    );
    if (s != null) setState(() => _form = s);
  }

  Future<void> _musteriSec() async {
    final s = await _picker<MusteriDanisan>(
      baslik: 'Müşteri Seç',
      ogeler: _musteriler,
      etiket: (m) => m.name,
      altYazi: (m) => m.cep_telefon,
      seciliId: _musteri?.id,
      ogeId: (m) => m.id,
    );
    if (s != null) {
      setState(() {
        _musteri = s;
        if (s.cep_telefon.isNotEmpty && s.cep_telefon != 'null') {
          _telefon.text = s.cep_telefon;
        }
        if (s.tc_kimlik_no.isNotEmpty && s.tc_kimlik_no != 'null') {
          _tc.text = s.tc_kimlik_no;
        }
        if (s.dogum_tarihi.isNotEmpty && s.dogum_tarihi != 'null') {
          _dogum.text = s.dogum_tarihi;
        }
        if (s.cinsiyet == '1' || s.cinsiyet.toLowerCase() == 'erkek') {
          _cinsiyet = 'Erkek';
        } else {
          _cinsiyet = 'Kadın';
        }
      });
    }
  }

  Future<void> _personelSec() async {
    final s = await _picker<Personel>(
      baslik: 'Personel Seç',
      ogeler: _personeller,
      etiket: (p) => p.personel_adi,
      altYazi: (p) => p.cep_telefon,
      seciliId: _personel?.id,
      ogeId: (p) => p.id,
    );
    if (s != null) {
      setState(() {
        _personel = s;
        if (s.cep_telefon.isNotEmpty && s.cep_telefon != 'null') {
          _personelTel.text = s.cep_telefon;
        }
      });
    }
  }

  Future<void> _hizmetSec() async {
    final s = await _picker<IsletmeHizmet>(
      baslik: 'Hizmet Seç',
      ogeler: _hizmetler,
      etiket: (h) => h.hizmet?['hizmet_adi']?.toString() ?? '-',
      altYazi: (h) => '${h.fiyat} ₺',
      seciliId: _hizmet?.hizmet_id,
      ogeId: (h) => h.hizmet_id,
      temizleVar: true,
    );
    setState(() {
      _hizmet = s;
      if (s != null && s.fiyat.isNotEmpty) _ucret.text = s.fiyat;
    });
  }

  Future<void> _dogumSec() async {
    DateTime baslangic = DateTime(2000, 1, 1);
    if (_dogum.text.isNotEmpty) {
      try {
        baslangic = DateFormat('yyyy-MM-dd').parse(_dogum.text);
      } catch (_) {
        try {
          baslangic = DateFormat('dd.MM.yyyy').parse(_dogum.text);
        } catch (_) {}
      }
    }
    final secilen = await showDatePicker(
      context: context,
      initialDate: baslangic,
      firstDate: DateTime(1925),
      lastDate: DateTime.now(),
      locale: const Locale('tr', 'TR'),
    );
    if (secilen != null) {
      setState(() {
        _dogum.text = DateFormat('yyyy-MM-dd').format(secilen);
      });
    }
  }

  Future<T?> _picker<T>({
    required String baslik,
    required List<T> ogeler,
    required String Function(T) etiket,
    required String Function(T) altYazi,
    required String? seciliId,
    required String Function(T) ogeId,
    bool temizleVar = false,
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
        temizleVar: temizleVar,
      ),
    );
  }

  Future<void> _gonder() async {
    if (_form == null) {
      showPremiumWarning(context,
          title: 'Form Seçilmedi',
          message: 'Lütfen form/sözleşme türü seçin.');
      return;
    }
    if (_musteri == null) {
      showPremiumWarning(context,
          title: 'Müşteri Seçilmedi',
          message: 'Lütfen müşteri seçin.');
      return;
    }
    if (_telefon.text.trim().isEmpty) {
      showPremiumWarning(context,
          title: 'Telefon Boş', message: 'Müşteri cep telefonu zorunlu.');
      return;
    }
    if (_personel == null) {
      showPremiumWarning(context,
          title: 'Personel Seçilmedi',
          message: 'Lütfen işlemi yapan personeli seçin.');
      return;
    }

    setState(() => _gonderiliyor = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user');
      final user = userJson != null ? jsonDecode(userJson) : {};

      final body = {
        'user_id': _musteri!.id,
        'form_id': _form!.id,
        'personel_id': _personel!.id,
        'cinsiyet': _cinsiyet,
        'dogumtarihi': _dogum.text,
        'cep_telefon': _telefon.text.trim(),
        'personel_cep': _personelTel.text.trim(),
        'tc_kimlik_no': _tc.text.trim(),
        'salon_id': _seciliSube,
        'olusturan': user["id"],
        'hizmet': _hizmet?.hizmet_id ?? '',
        'ucret': _ucret.text,
      };

      final resp = await http.post(
        Uri.parse(
            'https://apptest.randevumcepte.com.tr/api/v1/arsivformekleguncelle'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (resp.statusCode == 200) {
        if (mounted) {
          await showPremiumWarning(context,
              title: 'Form Gönderildi',
              message: 'Müşteriye SMS ile form linki gönderildi.',
              tone: 'success');
        }
        if (mounted) Navigator.pop(context, true);
      } else {
        if (mounted) {
          showPremiumWarning(context,
              title: 'Sunucu Hatası',
              message: 'Hata kodu: ${resp.statusCode}',
              tone: 'error');
        }
      }
    } catch (_) {
      if (mounted) {
        showPremiumWarning(context,
            title: 'Bağlantı Hatası',
            message: 'İnternet bağlantınızı kontrol edin.',
            tone: 'error');
      }
    } finally {
      if (mounted) setState(() => _gonderiliyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PremiumGradientBg(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(scheme),
              Expanded(
                child: _yukleniyor
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
                        : _buildBody(scheme),
              ),
              if (!_yukleniyor && _hataMesaji == null) _buildBottom(scheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      child: Row(
        children: [
          PremiumCircleAction(
            icon: Icons.arrow_back_rounded,
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Form Gönder',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                    letterSpacing: -0.4,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Müşteriye onam/anket formu gönder',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ColorScheme scheme) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
      children: [
        PremiumGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Etiket('Form / Sözleşme Türü *'),
              _SecimAlani(
                etiket: _form?.form_adi ?? 'Form seçin',
                ikon: Icons.description_outlined,
                bos: _form == null,
                onTap: _formSec,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        PremiumGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Etiket('Müşteri *'),
              _SecimAlani(
                etiket: _musteri?.name ?? 'Müşteri seçin',
                altYazi: _musteri?.cep_telefon,
                ikon: Icons.person_outline_rounded,
                bos: _musteri == null,
                onTap: _musteriSec,
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _Etiket('Cep Telefon *'),
                        TextField(
                          controller: _telefon,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9 ]')),
                          ],
                          decoration: _inputDeko('05xx xxx xx xx', scheme),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _Etiket('TC Kimlik No'),
                        TextField(
                          controller: _tc,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(11),
                          ],
                          decoration: _inputDeko('11 hane', scheme),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _Etiket('Cinsiyet'),
                        _CinsiyetSec(
                          deger: _cinsiyet,
                          onChanged: (v) => setState(() => _cinsiyet = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _Etiket('Doğum Tarihi'),
                        InkWell(
                          onTap: _dogumSec,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 13),
                            decoration: BoxDecoration(
                              color: scheme.primary.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today_rounded,
                                    size: 16,
                                    color:
                                        scheme.primary.withValues(alpha: 0.7)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _dogum.text.isEmpty
                                        ? 'Tarih seç'
                                        : _dogum.text,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _dogum.text.isEmpty
                                          ? Colors.black38
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        PremiumGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Etiket('İşlemi Yapan Personel *'),
              _SecimAlani(
                etiket: _personel?.personel_adi ?? 'Personel seçin',
                altYazi: _personel?.cep_telefon,
                ikon: Icons.badge_outlined,
                bos: _personel == null,
                onTap: _personelSec,
              ),
              const SizedBox(height: 12),
              const _Etiket('Personel Cep Telefon'),
              TextField(
                controller: _personelTel,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')),
                ],
                decoration:
                    _inputDeko('Personel seçince otomatik dolar', scheme),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        PremiumGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Etiket('Hizmet (opsiyonel)'),
              _SecimAlani(
                etiket: _hizmet?.hizmet?['hizmet_adi']?.toString() ??
                    'Hizmet seçin',
                altYazi: _hizmet != null ? '${_hizmet!.fiyat} ₺' : null,
                ikon: Icons.spa_outlined,
                bos: _hizmet == null,
                onTap: _hizmetSec,
              ),
              const SizedBox(height: 12),
              const _Etiket('Ücret (₺)'),
              TextField(
                controller: _ucret,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: _inputDeko('0,00', scheme),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottom(ColorScheme scheme) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: _gonderiliyor ? null : _gonder,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [scheme.primary, scheme.tertiary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.30),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Center(
                child: _gonderiliyor
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.send_rounded,
                              color: scheme.onPrimary, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Müşteriye Gönder',
                            style: TextStyle(
                              color: scheme.onPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
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

  InputDecoration _inputDeko(String hint, ColorScheme scheme) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12.5, color: Colors.black38),
      filled: true,
      fillColor: scheme.primary.withValues(alpha: 0.05),
      isDense: true,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
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

class _CinsiyetSec extends StatelessWidget {
  final String deger;
  final ValueChanged<String> onChanged;
  const _CinsiyetSec({required this.deger, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (final c in const ['Kadın', 'Erkek'])
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(c),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: deger == c ? scheme.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      c,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: deger == c ? Colors.white : scheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
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
  final bool temizleVar;
  const _PickerSheet({
    required this.baslik,
    required this.ogeler,
    required this.etiket,
    required this.altYazi,
    required this.seciliId,
    required this.ogeId,
    required this.temizleVar,
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
                    if (widget.temizleVar)
                      TextButton.icon(
                        onPressed: () => Navigator.pop<T?>(context, null),
                        icon: const Icon(Icons.clear_rounded, size: 16),
                        label: const Text('Temizle'),
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

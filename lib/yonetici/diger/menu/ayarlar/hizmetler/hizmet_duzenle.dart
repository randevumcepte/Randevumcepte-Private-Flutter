import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Models/cihazlar.dart';
import 'package:randevu_sistem/Models/hizmetler.dart';
import 'package:randevu_sistem/Models/personel.dart';
import 'package:randevu_sistem/theme/app_tokens.dart';

class HizmetDuzenle extends StatefulWidget {
  final dynamic isletmebilgi;
  final Hizmet hizmet;

  /// Kaydetme basarili olunca cagirilir — caller listeyi tazeler.
  final Future<void> Function()? onSaved;

  const HizmetDuzenle({
    super.key,
    required this.isletmebilgi,
    required this.hizmet,
    this.onSaved,
  });

  @override
  State<HizmetDuzenle> createState() => _HizmetDuzenleState();
}

class _HizmetDuzenleState extends State<HizmetDuzenle> {
  bool _yukleniyor = true;
  bool _kaydediliyor = false;

  late TextEditingController _adCtrl;
  late TextEditingController _fiyatCtrl;
  late TextEditingController _sureCtrl;

  List<Personel> _tumPersoneller = [];
  List<Cihaz> _tumCihazlar = [];
  final Set<String> _secilenPersonelIds = {};
  final Set<String> _secilenCihazIds = {};

  String _salonId = '';

  bool get _adDuzenlenebilir =>
      widget.hizmet.ozel_hizmet.toString() == '1';

  @override
  void initState() {
    super.initState();
    _adCtrl = TextEditingController(
      text: widget.hizmet.hizmet_adi == 'null' ? '' : widget.hizmet.hizmet_adi,
    );
    _fiyatCtrl = TextEditingController(
      text: widget.hizmet.fiyat == 'null' ? '' : widget.hizmet.fiyat,
    );
    _sureCtrl = TextEditingController(
      text: widget.hizmet.sure_dk == 'null' ? '' : widget.hizmet.sure_dk,
    );
    _yukle();
  }

  Future<void> _yukle() async {
    _salonId = (await secilisalonid()) ?? '';
    final personeller = await personellistegetir(_salonId);
    final cihazlar = await isletmecihazlari(_salonId);
    if (!mounted) return;

    _tumPersoneller = personeller;
    _tumCihazlar = cihazlar;

    if (widget.hizmet.personel.isNotEmpty &&
        widget.hizmet.personel != 'null') {
      final secilenAdlar = widget.hizmet.personel
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toSet();
      for (final p in _tumPersoneller) {
        if (secilenAdlar.contains(p.personel_adi)) {
          _secilenPersonelIds.add(p.id);
        }
      }
    }
    if (widget.hizmet.cihaz.isNotEmpty && widget.hizmet.cihaz != 'null') {
      final secilenAdlar = widget.hizmet.cihaz
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toSet();
      for (final c in _tumCihazlar) {
        if (secilenAdlar.contains(c.cihaz_adi)) {
          _secilenCihazIds.add(c.id);
        }
      }
    }

    setState(() => _yukleniyor = false);
  }

  @override
  void dispose() {
    _adCtrl.dispose();
    _fiyatCtrl.dispose();
    _sureCtrl.dispose();
    super.dispose();
  }

  Future<void> _kaydet() async {
    if (_kaydediliyor) return;
    final ad = _adCtrl.text.trim();
    final fiyat = _fiyatCtrl.text.trim();
    final sure = _sureCtrl.text.trim();

    if (ad.isEmpty || sure.isEmpty) {
      _uyari('Eksik bilgi', 'Hizmet adı ve süre boş bırakılamaz.');
      return;
    }
    if (_secilenPersonelIds.isEmpty && _secilenCihazIds.isEmpty) {
      _uyari(
        'Personel veya cihaz seç',
        'En az bir personel ya da cihaz seçmelisin.',
      );
      return;
    }

    setState(() => _kaydediliyor = true);

    final formData = {
      'yeniekleme': '0',
      'hizmetler': [widget.hizmet.toJson()],
      'sureler': [sure],
      'fiyatlar': [fiyat],
      'hizmetAdlari': [ad],
      'secilipersoneller': [_secilenPersonelIds.toList()],
      'secilicihazlar': [_secilenCihazIds.toList()],
      'sube': _salonId.isNotEmpty
          ? _salonId
          : widget.isletmebilgi['id'].toString(),
    };

    try {
      final resp = await http
          .post(
            Uri.parse(
                'https://app.randevumcepte.com.tr/api/v1/hizmetekleduzenle'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(formData),
          )
          .timeout(const Duration(seconds: 30));

      if (!mounted) return;
      if (resp.statusCode == 200) {
        if (widget.onSaved != null) {
          await widget.onSaved!();
        }
        if (!mounted) return;
        Navigator.of(context).pop(true);
      } else {
        setState(() => _kaydediliyor = false);
        _uyari(
          'Güncelleme başarısız',
          'Sunucu hatası (${resp.statusCode}). Lütfen tekrar deneyin.',
        );
      }
    } on TimeoutException {
      if (!mounted) return;
      setState(() => _kaydediliyor = false);
      _uyari('Zaman aşımı', 'İstek zaman aşımına uğradı. Tekrar deneyin.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _kaydediliyor = false);
      _uyari('Hata', 'Beklenmedik bir hata oluştu: $e');
    }
  }

  void _uyari(String title, String message) {
    final cs = context.colors;
    final ext = context.appTheme;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(ctx).cardColor,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: ext.warningColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: ext.warningColor.withValues(alpha: 0.20),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: ext.warningColor,
                  size: 28,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 62,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: cs.onSurface, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Hizmet Düzenle',
          style: TextStyle(
            color: cs.onSurface,
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: -0.3,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: context.appTheme.borderSubtle),
        ),
      ),
      body: _yukleniyor
          ? Center(
              child: CircularProgressIndicator(
                color: cs.primary,
                strokeWidth: 2.5,
              ),
            )
          : GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              behavior: HitTestBehavior.translucent,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
                children: [
                  _header(),
                  const SizedBox(height: 14),
                  _formCard(),
                  const SizedBox(height: 14),
                  _secimCard(
                    baslik: 'Personeller',
                    ikon: Icons.person_outline_rounded,
                    secimSayisi: _secilenPersonelIds.length,
                    toplam: _tumPersoneller.length,
                    children: _tumPersoneller.isEmpty
                        ? [const _EmptyMini(text: 'Personel tanımlı değil')]
                        : _tumPersoneller.map(_buildPersonelChip).toList(),
                  ),
                  const SizedBox(height: 12),
                  _secimCard(
                    baslik: 'Cihazlar',
                    ikon: Icons.devices_other_rounded,
                    secimSayisi: _secilenCihazIds.length,
                    toplam: _tumCihazlar.length,
                    children: _tumCihazlar.isEmpty
                        ? [const _EmptyMini(text: 'Cihaz tanımlı değil')]
                        : _tumCihazlar.map(_buildCihazChip).toList(),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: _yukleniyor ? null : _bottomBar(),
    );
  }

  Widget _header() {
    final cs = context.colors;
    final ext = context.appTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: ext.heroGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.30),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: cs.onPrimary.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.spa_rounded,
                color: cs.onPrimary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.hizmet.hizmet_adi == 'null'
                      ? '-'
                      : widget.hizmet.hizmet_adi,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: cs.onPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Hizmet bilgilerini güncelleyin',
                  style: TextStyle(
                    color: cs.onPrimary.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _formCard() {
    final cs = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: cs.primary.withValues(alpha: 0.10),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _labelLine(Icons.label_outline_rounded, 'Hizmet Adı',
              opsiyonel: !_adDuzenlenebilir ? 'sistem hizmeti' : null),
          const SizedBox(height: 6),
          _input(
            controller: _adCtrl,
            enabled: _adDuzenlenebilir,
            hint: 'Hizmet adı',
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _labelLine(Icons.payments_rounded, 'Fiyat (₺)'),
                    const SizedBox(height: 6),
                    _input(
                      controller: _fiyatCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9.,]')),
                      ],
                      hint: '0',
                      prefixText: '₺ ',
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _labelLine(Icons.timer_outlined, 'Süre (dk)'),
                    const SizedBox(height: 6),
                    _input(
                      controller: _sureCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      hint: '0',
                      suffixText: 'dk',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _labelLine(IconData icon, String label, {String? opsiyonel}) {
    final cs = context.colors;
    return Row(
      children: [
        Icon(icon, size: 15, color: cs.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
            letterSpacing: -0.1,
          ),
        ),
        if (opsiyonel != null) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              opsiyonel,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _input({
    required TextEditingController controller,
    bool enabled = true,
    String? hint,
    String? prefixText,
    String? suffixText,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final cs = context.colors;
    final ext = context.appTheme;
    return Container(
      decoration: BoxDecoration(
        color: enabled
            ? ext.surfaceMuted
            : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cs.primary.withValues(alpha: enabled ? 0.18 : 0.06),
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: enabled ? cs.onSurface : cs.onSurfaceVariant,
          letterSpacing: -0.1,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: cs.onSurfaceVariant.withValues(alpha: 0.7),
            fontWeight: FontWeight.w500,
            fontSize: 13.5,
          ),
          prefixText: prefixText,
          prefixStyle: TextStyle(
            color: cs.primary,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
          suffixText: suffixText,
          suffixStyle: TextStyle(
            color: cs.primary,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        ),
      ),
    );
  }

  Widget _secimCard({
    required String baslik,
    required IconData ikon,
    required int secimSayisi,
    required int toplam,
    required List<Widget> children,
  }) {
    final cs = context.colors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: cs.primary.withValues(alpha: 0.10),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.05),
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
                  color: cs.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(ikon, color: cs.primary, size: 17),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  baslik,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: secimSayisi > 0
                      ? cs.primary.withValues(alpha: 0.14)
                      : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$secimSayisi / $toplam',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: secimSayisi > 0
                        ? cs.primary
                        : cs.onSurfaceVariant,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: children),
        ],
      ),
    );
  }

  Widget _buildPersonelChip(Personel p) {
    final selected = _secilenPersonelIds.contains(p.id);
    return _SecimChip(
      label: p.personel_adi,
      icon: Icons.person_rounded,
      selected: selected,
      onTap: () {
        setState(() {
          if (selected) {
            _secilenPersonelIds.remove(p.id);
          } else {
            _secilenPersonelIds.add(p.id);
          }
        });
      },
    );
  }

  Widget _buildCihazChip(Cihaz c) {
    final selected = _secilenCihazIds.contains(c.id);
    return _SecimChip(
      label: c.cihaz_adi,
      icon: Icons.devices_rounded,
      selected: selected,
      onTap: () {
        setState(() {
          if (selected) {
            _secilenCihazIds.remove(c.id);
          } else {
            _secilenCihazIds.add(c.id);
          }
        });
      },
    );
  }

  Widget _bottomBar() {
    final cs = context.colors;
    final ext = context.appTheme;
    return Container(
      padding: EdgeInsets.fromLTRB(
        14,
        10,
        14,
        10 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: ext.shadowBase.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -3),
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
            height: 52,
            decoration: BoxDecoration(
              gradient: _kaydediliyor
                  ? LinearGradient(colors: [
                      cs.surfaceContainerHighest,
                      cs.surfaceContainerHigh,
                    ])
                  : ext.heroGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: _kaydediliyor
                  ? []
                  : [
                      BoxShadow(
                        color: cs.primary.withValues(alpha: 0.40),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
            ),
            alignment: Alignment.center,
            child: _kaydediliyor
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation(cs.onPrimary),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_rounded,
                          color: cs.onPrimary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Güncelle',
                        style: TextStyle(
                          color: cs.onPrimary,
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
    );
  }
}

class _SecimChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _SecimChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? cs.primary : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? cs.primary
                  : cs.primary.withValues(alpha: 0.30),
              width: 1.2,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: cs.primary.withValues(alpha: 0.30),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? Icons.check_rounded : icon,
                size: 14,
                color: selected ? cs.onPrimary : cs.primary,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: selected ? cs.onPrimary : cs.primary,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyMini extends StatelessWidget {
  final String text;
  const _EmptyMini({required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontStyle: FontStyle.italic,
          color: cs.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

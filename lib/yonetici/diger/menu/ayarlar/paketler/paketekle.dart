import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Frontend/tl_input_formatter.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:randevu_sistem/Models/paket_hizmetleri.dart';
import 'package:randevu_sistem/Models/user.dart';
import 'package:randevu_sistem/theme/premium_components.dart';

import 'birhizmetdaha.dart';

class PaketEkle extends StatefulWidget {
  final Kullanici kullanici;
  final dynamic isletmebilgi;
  final int kullanicirolu;
  const PaketEkle({
    Key? key,
    required this.kullanici,
    required this.isletmebilgi,
    required this.kullanicirolu,
  }) : super(key: key);

  @override
  _PaketEkleState createState() => _PaketEkleState();
}

class _PaketEkleState extends State<PaketEkle> {
  late String seciliisletme;
  final TextEditingController paketadi = TextEditingController();
  final TextEditingController paketSeans = TextEditingController();
  final TextEditingController paketFiyat = TextEditingController();
  final TextEditingController paketSure = TextEditingController();
  List<PaketHizmetleri> pakethizmetleri = [];
  bool _isloading = true;
  bool _kaydediliyor = false;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  Future<void> initialize() async {
    seciliisletme = (await secilisalonid())!;
    if (!mounted) return;
    setState(() => _isloading = false);
  }

  @override
  void dispose() {
    paketadi.dispose();
    paketSeans.dispose();
    paketFiyat.dispose();
    paketSure.dispose();
    super.dispose();
  }

  void hizmetekle() async {
    FocusScope.of(context).unfocus();
    final List<PaketHizmetleri>? selectedItems = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BirHizmetDaha(
          secilihizmetler: pakethizmetleri,
          isletmebilgi: widget.isletmebilgi,
        ),
      ),
    );
    if (!mounted) return;
    FocusManager.instance.primaryFocus?.unfocus();
    if (selectedItems != null) {
      setState(() => pakethizmetleri = selectedItems);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isloading) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }
    final scheme = Theme.of(context).colorScheme;
    final isDemo = widget.isletmebilgi["demo_hesabi"].toString() == "1";

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
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
                      _buildPaketAdiCard(scheme),
                      const SizedBox(height: 12),
                      _buildOzelliklerCard(scheme),
                      const SizedBox(height: 12),
                      _buildHizmetlerCard(scheme),
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
                  'Yeni Paket',
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
                  'Hizmetlerden oluşan paket oluştur',
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

  Widget _buildPaketAdiCard(ColorScheme scheme) {
    return _glassCard(
      scheme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel(scheme, 'Paket Adı', Icons.label_outline_rounded),
          const SizedBox(height: 10),
          _modernInput(
            scheme,
            controller: paketadi,
            hint: 'Örn: Lazer Epilasyon 8 Seans',
            keyboardType: TextInputType.text,
          ),
        ],
      ),
    );
  }

  Widget _buildOzelliklerCard(ColorScheme scheme) {
    return _glassCard(
      scheme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel(scheme, 'Paket Özellikleri', Icons.tune_rounded),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _fieldWithLabel(
                  scheme,
                  label: 'Süre (dk)',
                  child: _modernInput(
                    scheme,
                    controller: paketSure,
                    hint: '60',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _fieldWithLabel(
                  scheme,
                  label: 'Seans',
                  child: _modernInput(
                    scheme,
                    controller: paketSeans,
                    hint: '8',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _fieldWithLabel(
                  scheme,
                  label: 'Fiyat (₺)',
                  child: _modernInput(
                    scheme,
                    controller: paketFiyat,
                    hint: '0,00',
                    keyboardType: TextInputType.number,
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

  Widget _buildHizmetlerCard(ColorScheme scheme) {
    return _glassCard(
      scheme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.spa_rounded, size: 16, color: scheme.primary),
              const SizedBox(width: 6),
              Text(
                'Hizmetler',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                  letterSpacing: -0.2,
                ),
              ),
              const Spacer(),
              if (pakethizmetleri.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${pakethizmetleri.length}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: scheme.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (pakethizmetleri.isEmpty)
            _buildHizmetlerBosDurum(scheme)
          else
            ...List.generate(pakethizmetleri.length, (index) {
              final hizmet = pakethizmetleri[index];
              final ad = hizmet.hizmet["hizmet_adi"]?.toString() ?? '';
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Dismissible(
                  dismissThresholds: const {
                    DismissDirection.endToStart: 0.4,
                  },
                  direction: DismissDirection.endToStart,
                  key: Key('${hizmet.hizmet_id}_$index'),
                  background: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 18),
                    child: const Icon(Icons.delete_rounded,
                        color: Colors.white, size: 22),
                  ),
                  onDismissed: (_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$ad kaldırıldı'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    setState(() => pakethizmetleri.removeAt(index));
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: scheme.primary.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: scheme.primary.withValues(alpha: 0.14),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.spa_rounded,
                            size: 15,
                            color: scheme.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            ad,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() => pakethizmetleri.removeAt(index));
                          },
                          icon: Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: scheme.onSurface.withValues(alpha: 0.45),
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 28,
                            minHeight: 28,
                          ),
                          tooltip: 'Kaldır',
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          const SizedBox(height: 4),
          _hizmetEkleBtn(scheme),
        ],
      ),
    );
  }

  Widget _buildHizmetlerBosDurum(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: scheme.outline.withValues(alpha: 0.18),
          style: BorderStyle.solid,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.info_outline_rounded,
              color: scheme.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Henüz hizmet eklenmedi',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Bu pakete dahil olacak hizmetleri ekleyin',
                  style: TextStyle(
                    fontSize: 11,
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

  Widget _hizmetEkleBtn(ColorScheme scheme) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: hizmetekle,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: scheme.primary.withValues(alpha: 0.35),
              width: 1.4,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_rounded, color: scheme.primary, size: 18),
              const SizedBox(width: 6),
              Text(
                'Hizmet Ekle',
                style: TextStyle(
                  color: scheme.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
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
              onTap: _kaydediliyor ? null : _submit,
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
                            'Paketi Kaydet',
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

  Future<void> _submit() async {
    if (paketadi.text.trim().isEmpty) {
      _showUyari('Paket adı boş bırakılamaz.');
      return;
    }
    if (paketadi.text.trim().length < 3) {
      _showUyari('Paket adı en az 3 karakter olmalıdır.');
      return;
    }
    if (pakethizmetleri.isEmpty) {
      _showUyari('En az bir hizmet seçmeniz gerekir.');
      return;
    }

    setState(() => _kaydediliyor = true);

    try {
      final List<Map<String, dynamic>> hizmetler =
          pakethizmetleri.map((h) => h.toJson()).toList();

      final Map<String, dynamic> formData = {
        'adpaket': paketadi.text.trim(),
        'hizmetler': hizmetler,
        'paketsure': paketSure.text,
        'seanslar': paketSeans.text,
        'fiyatlar': tlToBackend(paketFiyat.text),
      };

      log('paketekle formdata: $formData');

      final response = await http.post(
        Uri.parse(
            'https://apptest.randevumcepte.com.tr/api/v1/paket_ekle_guncelle/$seciliisletme'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(formData),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        Navigator.of(context).pop(true);
        return;
      }

      setState(() => _kaydediliyor = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Paket eklenirken bir hata oluştu! Hata kodu: ${response.statusCode}'),
          backgroundColor: Colors.red[700],
        ),
      );
      debugPrint('paketekle error: ${response.body}');
    } catch (e) {
      if (!mounted) return;
      setState(() => _kaydediliyor = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bir hata oluştu: $e'),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }

  void _showUyari(String mesaj) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('UYARI',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text(mesaj),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('TAMAM'),
          ),
        ],
      ),
    );
  }
}

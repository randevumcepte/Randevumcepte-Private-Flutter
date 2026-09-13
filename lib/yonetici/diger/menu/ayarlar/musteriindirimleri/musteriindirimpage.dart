import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';

class MusteriIndirimleri extends StatefulWidget {
  final dynamic isletmebilgi;
  const MusteriIndirimleri({super.key, required this.isletmebilgi});

  @override
  State<MusteriIndirimleri> createState() => _MusteriIndirimleriState();
}

class _MusteriIndirimleriState extends State<MusteriIndirimleri> {
  static const Color _accent = Color(0xFF4CAF93);
  static const Color _accentLight = Color(0xFF6FC8B1);
  static const Color _bg = Color(0xFFF7F9F8);

  String? _seciliisletme;
  bool _isLoading = true;
  bool _isSaving = false;

  bool _sadikAcik = false;
  bool _aktifAcik = false;

  final TextEditingController _sadikCtrl = TextEditingController();
  final TextEditingController _aktifCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _seciliisletme = await secilisalonid();
    final settings = await fetchSalonSettings(_seciliisletme!);
    if (!mounted) return;
    final sadik = settings['sadik_musteri_indirim_yuzde']?.toString() ?? '0';
    final aktif = settings['aktif_musteri_indirim_yuzde']?.toString() ?? '0';
    setState(() {
      _sadikCtrl.text = sadik;
      _aktifCtrl.text = aktif;
      _sadikAcik = sadik != '0' && sadik.isNotEmpty;
      _aktifAcik = aktif != '0' && aktif.isNotEmpty;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _sadikCtrl.dispose();
    _aktifCtrl.dispose();
    super.dispose();
  }

  Future<void> _kaydet() async {
    if (_isSaving) return;

    if (_sadikAcik) {
      final v = int.tryParse(_sadikCtrl.text.trim());
      if (v == null || v <= 0 || v > 100) {
        _toast('Sadık müşteri indirimi için 1-100 arası bir yüzde girin.',
            error: true);
        return;
      }
    }
    if (_aktifAcik) {
      final v = int.tryParse(_aktifCtrl.text.trim());
      if (v == null || v <= 0 || v > 100) {
        _toast('Aktif müşteri indirimi için 1-100 arası bir yüzde girin.',
            error: true);
        return;
      }
    }

    setState(() => _isSaving = true);

    final formData = {
      'sadik_musteri_indirimi':
          _sadikAcik ? _sadikCtrl.text.trim() : '0',
      'aktif_musteri_indirimi':
          _aktifAcik ? _aktifCtrl.text.trim() : '0',
      'sube': _seciliisletme,
      'sadik_acikkapali': _sadikAcik,
      'aktif_acikkapali': _aktifAcik,
    };

    try {
      final response = await http.post(
        Uri.parse(
            'https://app.randevumcepte.com.tr/api/v1/musteriindirim_kaydet'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(formData),
      );
      log('Response status: ${response.statusCode}');
      log('Response body: ${response.body}');

      if (!mounted) return;
      if (response.statusCode == 200) {
        _toast('İndirim ayarları güncellendi.');
        Navigator.of(context).pop();
      } else {
        _toast('Güncelleme başarısız. Kod: ${response.statusCode}',
            error: true);
      }
    } catch (e) {
      if (!mounted) return;
      _toast('Bir hata oluştu: $e', error: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _toast(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              error
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: error ? const Color(0xFFDC2626) : _accent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: _bg,
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
          title: const Text(
            'Müşteri İndirimleri',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w800,
              fontSize: 18,
              letterSpacing: -0.3,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
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
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                    color: _accent, strokeWidth: 2.5),
              )
            : SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildHeaderBanner(),
                            const SizedBox(height: 14),
                            _buildInfoBox(),
                            const SizedBox(height: 14),
                            _buildDiscountCard(
                              title: 'Sadık Müşteri İndirimi',
                              description:
                                  'Düzenli ve uzun süredir gelen müşterilere otomatik uygulanır.',
                              icon: Icons.workspace_premium_rounded,
                              gradient: const [
                                Color(0xFFFFB86B),
                                Color(0xFFFF8A65),
                              ],
                              shadowColor: const Color(0xFFFF8A65),
                              isOn: _sadikAcik,
                              controller: _sadikCtrl,
                              onToggle: (v) {
                                setState(() {
                                  _sadikAcik = v;
                                  if (!v) _sadikCtrl.text = '0';
                                  if (v &&
                                      (_sadikCtrl.text == '0' ||
                                          _sadikCtrl.text.isEmpty)) {
                                    _sadikCtrl.text = '';
                                  }
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            _buildDiscountCard(
                              title: 'Aktif Müşteri İndirimi',
                              description:
                                  'Son dönemde sık ziyaret eden aktif müşterilere uygulanır.',
                              icon: Icons.local_fire_department_rounded,
                              gradient: const [
                                Color(0xFF6FC8B1),
                                Color(0xFF4CAF93),
                              ],
                              shadowColor: _accent,
                              isOn: _aktifAcik,
                              controller: _aktifCtrl,
                              onToggle: (v) {
                                setState(() {
                                  _aktifAcik = v;
                                  if (!v) _aktifCtrl.text = '0';
                                  if (v &&
                                      (_aktifCtrl.text == '0' ||
                                          _aktifCtrl.text.isEmpty)) {
                                    _aktifCtrl.text = '';
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    _buildSaveBar(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeaderBanner() {
    final aktifSayisi = (_sadikAcik ? 1 : 0) + (_aktifAcik ? 1 : 0);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: 0.10),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_accentLight, _accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: _accent.withValues(alpha: 0.30),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.discount_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Müşteri İndirimleri',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  aktifSayisi == 0
                      ? 'Tüm indirimler kapalı'
                      : '$aktifSayisi indirim aktif',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                    height: 1,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: (aktifSayisi == 0 ? Colors.grey : _accent)
                  .withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: aktifSayisi == 0 ? Colors.grey : _accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  aktifSayisi == 0 ? 'Pasif' : 'Aktif',
                  style: TextStyle(
                    color: aktifSayisi == 0 ? Colors.grey[700] : _accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 11.5,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.info_outline_rounded,
                color: Color(0xFF3B82F6), size: 18),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'İndirimler, satış ekranında uygun müşterilere otomatik olarak uygulanır. 0-100 arası bir yüzde girin.',
              style: TextStyle(
                fontSize: 12.5,
                color: Color(0xFF1E40AF),
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountCard({
    required String title,
    required String description,
    required IconData icon,
    required List<Color> gradient,
    required Color shadowColor,
    required bool isOn,
    required TextEditingController controller,
    required ValueChanged<bool> onToggle,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isOn
              ? shadowColor.withValues(alpha: 0.30)
              : Colors.black.withValues(alpha: 0.06),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isOn ? shadowColor : Colors.black)
                .withValues(alpha: isOn ? 0.12 : 0.04),
            blurRadius: isOn ? 16 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(
                      color: shadowColor.withValues(alpha: 0.30),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                        color: Colors.black87,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Transform.scale(
                scale: 0.95,
                child: Switch.adaptive(
                  value: isOn,
                  onChanged: onToggle,
                  activeThumbColor: Colors.white,
                  activeTrackColor: shadowColor,
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: Colors.grey[300],
                ),
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            child: isOn
                ? Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: _buildPercentInput(controller, shadowColor),
                  )
                : const SizedBox(width: double.infinity, height: 0),
          ),
        ],
      ),
    );
  }

  Widget _buildPercentInput(TextEditingController controller, Color accent) {
    return Container(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accent.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        children: [
          Icon(Icons.percent_rounded, color: accent, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: Colors.black87,
                letterSpacing: -0.2,
              ),
              decoration: const InputDecoration(
                hintText: 'İndirim oranı',
                hintStyle: TextStyle(
                  color: Colors.black38,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                ),
                border: InputBorder.none,
                isCollapsed: true,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '%',
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: _isSaving ? null : _kaydet,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_accentLight, _accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _accent.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Container(
              height: 52,
              alignment: Alignment.center,
              child: _isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.4,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline_rounded,
                            color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Kaydet',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15.5,
                            letterSpacing: 0.3,
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
}

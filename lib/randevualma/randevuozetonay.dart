import 'dart:convert';
import 'dart:developer';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Login Sayfası/login_page.dart';
import 'package:randevu_sistem/Models/musteri_danisanlar.dart';
import 'package:randevu_sistem/Models/personel.dart';
import 'package:randevu_sistem/Models/randevuhizmetleri.dart';
import 'package:randevu_sistem/theme/app_tokens.dart';

class RandevuOnay extends StatefulWidget {
  final List<RandevuHizmet> seciliHizmetler;
  final String salonid;
  final String tarih;
  final String saat;
  final dynamic isletmebilgi;

  RandevuOnay({
    Key? key,
    required this.seciliHizmetler,
    required this.tarih,
    required this.saat,
    required this.salonid,
    required this.isletmebilgi,
  }) : super(key: key);

  @override
  RandevuOnayState createState() => RandevuOnayState();
}

class RandevuOnayState extends State<RandevuOnay> {
  final TextEditingController notController = TextEditingController();

  bool kvkkOnay = false;
  bool girisYapilmis = false;
  bool _gonderiliyor = false;
  Map<String, dynamic> user = {};

  @override
  void initState() {
    super.initState();
    _checkGiris();
  }

  void _checkGiris() async {
    bool giris = await girisYapilmismi();
    if (!mounted) return;
    setState(() {
      girisYapilmis = giris;
    });
  }

  Future<bool> girisYapilmismi() async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();

    var userType = localStorage.getString('user_type');
    String? userString = localStorage.getString('musteri');

    log('user type ' + userType.toString());
    log('user str ' + (userString ?? 'null'));

    if (userType == null || userString == null || userType == '0') {
      return false;
    }

    user = jsonDecode(userString);
    return true;
  }

  int _toplamSure() {
    int sum = 0;
    for (final h in widget.seciliHizmetler) {
      final s = int.tryParse(h.sure_dk.toString()) ?? 0;
      sum += s;
    }
    return sum;
  }

  double _toplamFiyat() {
    double sum = 0;
    for (final h in widget.seciliHizmetler) {
      final f = double.tryParse(h.fiyat.toString().replaceAll(',', '.')) ?? 0;
      sum += f;
    }
    return sum;
  }

  String _fiyatBicim(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.alphaBlend(
                  scheme.primary.withValues(alpha: 0.08),
                  Colors.white,
                ),
                Color.alphaBlend(
                  scheme.tertiary.withValues(alpha: 0.04),
                  Colors.white,
                ),
              ],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _topBar(context),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      if (girisYapilmis) _greetingCard(context),
                      if (girisYapilmis) const SizedBox(height: 12),
                      _heroSummaryCard(context),
                      const SizedBox(height: 22),
                      _sectionHeader(
                        context,
                        'Hizmetler',
                        icon: Icons.spa_rounded,
                      ),
                      const SizedBox(height: 10),
                      ...widget.seciliHizmetler
                          .asMap()
                          .entries
                          .map((e) => _hizmetCard(context, e.key, e.value)),
                      const SizedBox(height: 22),
                      _sectionHeader(
                        context,
                        'Notunuz',
                        icon: Icons.sticky_note_2_outlined,
                      ),
                      const SizedBox(height: 10),
                      _notField(context),
                      const SizedBox(height: 22),
                      _kvkkCard(context),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
                _bottomBar(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── TOP BAR ──────────────────────────────────────────────────────────────
  Widget _topBar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: [
          Material(
            color: Colors.white,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: () => Navigator.of(context).maybePop(),
              customBorder: const CircleBorder(),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.12),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: scheme.primary,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Randevu Özeti',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: scheme.onSurface,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Bilgileri kontrol et ve randevuyu oluştur',
                  style: TextStyle(
                    fontSize: 12,
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

  // ── GREETING ─────────────────────────────────────────────────────────────
  Widget _greetingCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final name = (user['name'] ?? '').toString();
    if (name.trim().isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(Icons.waving_hand_rounded,
              color: scheme.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Sayın $name',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: scheme.primary,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── HERO SUMMARY ─────────────────────────────────────────────────────────
  Widget _heroSummaryCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ext = context.appTheme;
    final toplamSure = _toplamSure();
    final toplamFiyat = _toplamFiyat();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary,
            Color.lerp(scheme.primary, scheme.tertiary, 0.6) ??
                scheme.primary,
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.28),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.calendar_today_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.tarih,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.20),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.access_time_rounded,
                                  color: Colors.white,
                                  size: 13,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.saat,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                height: 1,
                color: Colors.white.withValues(alpha: 0.18),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _heroStat(
                      icon: Icons.spa_rounded,
                      label: 'Hizmet',
                      value: '${widget.seciliHizmetler.length}',
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 32,
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                  Expanded(
                    child: _heroStat(
                      icon: Icons.schedule_rounded,
                      label: 'Süre',
                      value:
                          toplamSure > 0 ? '$toplamSure dk' : '—',
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 32,
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                  Expanded(
                    child: _heroStat(
                      icon: Icons.payments_outlined,
                      label: 'Toplam',
                      value: toplamFiyat > 0
                          ? '${_fiyatBicim(toplamFiyat)} ₺'
                          : '—',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroStat({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon,
            color: Colors.white.withValues(alpha: 0.80), size: 16),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  // ── SECTION HEADER ───────────────────────────────────────────────────────
  Widget _sectionHeader(BuildContext context, String title,
      {required IconData icon}) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 17, color: scheme.primary),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: scheme.onSurface,
          ),
        ),
      ],
    );
  }

  // ── HİZMET CARD ──────────────────────────────────────────────────────────
  Widget _hizmetCard(BuildContext context, int index, RandevuHizmet h) {
    final scheme = Theme.of(context).colorScheme;
    final ext = context.appTheme;
    String hizmetAdi = '';
    try {
      hizmetAdi = (h.hizmetler?['hizmet_adi'] ?? '').toString();
    } catch (_) {}
    String personelAdi = '';
    try {
      final p = h.personeller;
      if (p is Personel) personelAdi = p.personel_adi;
    } catch (_) {}

    final sure = h.sure_dk.toString();
    final fiyat = h.fiyat.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.05),
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
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: scheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  hizmetAdi.isEmpty ? 'Hizmet' : hizmetAdi,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    color: scheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (personelAdi.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.person_outline_rounded,
                    size: 15,
                    color: scheme.onSurface.withValues(alpha: 0.55),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      personelAdi,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              if (sure.isNotEmpty && sure != 'null' && sure != '0')
                _chipMini(
                  icon: Icons.schedule_rounded,
                  text: '$sure dk',
                  tint: ext.infoColor,
                ),
              if (sure.isNotEmpty && sure != 'null' && sure != '0' &&
                  fiyat.isNotEmpty && fiyat != 'null' && fiyat != '0')
                const SizedBox(width: 8),
              if (fiyat.isNotEmpty && fiyat != 'null' && fiyat != '0')
                _chipMini(
                  icon: Icons.payments_outlined,
                  text: '$fiyat ₺',
                  tint: ext.successColor,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chipMini({
    required IconData icon,
    required String text,
    required Color tint,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: tint),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: tint,
            ),
          ),
        ],
      ),
    );
  }

  // ── NOT FIELD ────────────────────────────────────────────────────────────
  Widget _notField(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: scheme.primary.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        controller: notController,
        keyboardType: TextInputType.multiline,
        maxLines: null,
        minLines: 2,
        style: TextStyle(
          fontSize: 14,
          color: scheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'İşletmemize iletmek istedikleriniz...',
          hintStyle: TextStyle(
            fontSize: 13,
            color: scheme.onSurface.withValues(alpha: 0.45),
          ),
        ),
      ),
    );
  }

  // ── KVKK CARD ────────────────────────────────────────────────────────────
  Widget _kvkkCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: kvkkOnay
          ? scheme.primary.withValues(alpha: 0.08)
          : Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: () => setState(() => kvkkOnay = !kvkkOnay),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: kvkkOnay
                  ? scheme.primary.withValues(alpha: 0.35)
                  : scheme.primary.withValues(alpha: 0.12),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 22,
                height: 22,
                margin: const EdgeInsets.only(top: 1),
                decoration: BoxDecoration(
                  color: kvkkOnay ? scheme.primary : Colors.transparent,
                  border: Border.all(
                    color: kvkkOnay
                        ? scheme.primary
                        : scheme.onSurface.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: kvkkOnay
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 16)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Kullanım koşullarını ',
                        style: TextStyle(
                          fontSize: 13,
                          color: scheme.primary,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          decorationColor: scheme.primary,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () async {
                            final url = Uri.parse(
                                'https://randevumcepte.com.tr/kullanim-kosullari/');
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url);
                            }
                          },
                      ),
                      TextSpan(
                        text: 've ',
                        style: TextStyle(
                          fontSize: 13,
                          color: scheme.onSurface.withValues(alpha: 0.75),
                        ),
                      ),
                      TextSpan(
                        text: 'Gizlilik & KVKK politikasını ',
                        style: TextStyle(
                          fontSize: 13,
                          color: scheme.primary,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          decorationColor: scheme.primary,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () async {
                            final url = Uri.parse(
                                'https://randevumcepte.com.tr/gizlilik-politikasi-ve-guvenlik/');
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url);
                            }
                          },
                      ),
                      TextSpan(
                        text: 'okudum, kabul ediyorum.',
                        style: TextStyle(
                          fontSize: 13,
                          color: scheme.onSurface.withValues(alpha: 0.75),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── BOTTOM BAR ───────────────────────────────────────────────────────────
  Widget _bottomBar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = kvkkOnay && !_gonderiliyor;
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 18,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            onTap: enabled ? _talepEt : null,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: enabled
                      ? [
                          scheme.primary,
                          Color.lerp(scheme.primary, scheme.tertiary, 0.6) ??
                              scheme.primary,
                        ]
                      : [
                          scheme.onSurface.withValues(alpha: 0.15),
                          scheme.onSurface.withValues(alpha: 0.12),
                        ],
                ),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: enabled
                    ? [
                        BoxShadow(
                          color: scheme.primary.withValues(alpha: 0.30),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_gonderiliyor)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  else
                    const Icon(Icons.check_circle_rounded,
                        color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    _gonderiliyor
                        ? 'Gönderiliyor...'
                        : 'Randevu Talep Et',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.1,
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

  Future<void> _talepEt() async {
    if (!kvkkOnay) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Devam etmek için KVKK onayı vermelisiniz.')),
      );
      return;
    }

    setState(() => _gonderiliyor = true);

    try {
      SharedPreferences localStorage = await SharedPreferences.getInstance();
      var token = localStorage.getString('token');
      var userType = localStorage.getString('user_type');

      if (token != null && userType.toString() == '1') {
        await localStorage.remove('musteri');
        await localStorage.remove('user_type');
        await localStorage.remove('token');
        token = null;
      }

      if (token == null) {
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (builder) => LoginPage(
              randevuSayfasinaYonlendir: true,
              seciliHizmetler: widget.seciliHizmetler,
              tarih: widget.tarih,
              saat: widget.saat,
            ),
          ),
        ).then((_) => _checkGiris());
      } else {
        String? userString = localStorage.getString('musteri');
        if (userString == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Oturum bilgisi bulunamadı, lütfen tekrar giriş yapın.')),
          );
          return;
        }
        Map<String, dynamic> freshUser = jsonDecode(userString);
        user = freshUser;
        MusteriDanisan md = MusteriDanisan.fromJson(freshUser);
        randevuEkleGuncelle(
          '',
          '',
          '',
          md,
          widget.tarih,
          widget.saat,
          widget.seciliHizmetler,
          [],
          false,
          '0',
          '',
          notController.text,
          widget.salonid.toString(),
          context,
          'uygulama',
          '0',
          md.musteri_olunan_salonlar?.firstWhere(
            (element) =>
                element['salon_id'].toString() == widget.salonid.toString(),
            orElse: () => {'salonlar': null},
          )['salonlar'],
        );
      }
    } finally {
      if (mounted) setState(() => _gonderiliyor = false);
    }
  }
}

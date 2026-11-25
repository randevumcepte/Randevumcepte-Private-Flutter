import 'dart:convert';

import 'package:randevu_sistem/dil/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'package:randevu_sistem/Models/musteri_danisanlar.dart';
import 'package:randevu_sistem/musteripaneli/profil/musteri_profil_tema.dart';
import 'package:randevu_sistem/theme/musteri_palet.dart';

class MusteriProfilBilgileri extends StatefulWidget {
  final MusteriDanisan kullanici;
  final VoidCallback? onProfileUpdated;

  /// 'bilgi' (Bilgilerimi Düzenle) | 'sifre' (Şifre Değiştir)
  final String mod;

  const MusteriProfilBilgileri({
    super.key,
    required this.kullanici,
    this.onProfileUpdated,
    this.mod = 'bilgi',
  });

  @override
  State<MusteriProfilBilgileri> createState() => _MusteriProfilBilgileriState();
}

class _MusteriProfilBilgileriState extends State<MusteriProfilBilgileri> {
  late TextEditingController _adsoyad;
  late TextEditingController _email;
  late TextEditingController _telefon;
  late TextEditingController _meslek;
  late TextEditingController _sifre;

  final _formKey = GlobalKey<FormState>();
  final phoneMask = MaskTextInputFormatter(
    mask: '0### ### ## ##',
    filter: {"#": RegExp(r'[0-9]')},
  );

  String _selectedGender = '';
  bool _isObscure = true;
  bool _isSaving = false;

  String _formatPhone(String? raw) {
    if (raw == null || raw == 'null' || raw.isEmpty) return '0';
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '0';
    final onlu = digits.startsWith('0') ? digits : '0' + digits;
    return phoneMask.maskText(onlu);
  }

  @override
  void initState() {
    super.initState();
    _adsoyad = TextEditingController(
      text: widget.kullanici.name != 'null' ? widget.kullanici.name : '',
    );
    _email = TextEditingController(
      text: widget.kullanici.email != 'null' ? widget.kullanici.email : '',
    );
    _telefon =
        TextEditingController(text: _formatPhone(widget.kullanici.cep_telefon));
    _meslek = TextEditingController(
      text: widget.kullanici.meslek != 'null' ? widget.kullanici.meslek : '',
    );
    _sifre = TextEditingController();

    if (widget.kullanici.cinsiyet == '0') {
      _selectedGender = 'kadin';
    } else if (widget.kullanici.cinsiyet == '1') {
      _selectedGender = 'erkek';
    }

    _loadCurrentUserData();
  }

  Future<void> _loadCurrentUserData() async {
    try {
      SharedPreferences localStorage = await SharedPreferences.getInstance();
      var user = jsonDecode(localStorage.getString('musteri')!);

      final response = await http.get(
        Uri.parse(
            'https://app.randevumcepte.com.tr//api/v1/musteri/${user["id"]}'),
      );

      if (response.statusCode != 200) return;
      var data = jsonDecode(response.body);
      localStorage.setString('musteri', jsonEncode(data));

      if (!mounted) return;
      setState(() {
        _adsoyad.text = data['name'] ?? '';
        _email.text = data['email'] ?? '';
        _telefon.text = _formatPhone(data['cep_telefon']?.toString());
        _meslek.text = data['meslek'] ?? '';
        if (data['cinsiyet'].toString() == '0') {
          _selectedGender = 'kadin';
        } else if (data['cinsiyet'].toString() == '1') {
          _selectedGender = 'erkek';
        }
      });
    } catch (e) {
      debugPrint('Error loading current user data: $e');
    }
  }

  Future<void> _refreshUserData() async {
    await _loadCurrentUserData();
    widget.onProfileUpdated?.call();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _formKey.currentState!.save();
    if (widget.mod == 'sifre' && _sifre.text.trim().length < 6) {
      mpMesaj(context, 'Yeni şifre en az 6 karakter olmalı.', hata: true);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);
    await _submitForm(
      _adsoyad.text,
      _email.text,
      _meslek.text,
      _telefon.text.replaceAll(RegExp(r'\D'), ''),
      _sifre.text,
      _selectedGender.isEmpty ? '' : (_selectedGender == 'kadin' ? '0' : '1'),
    );
    if (!mounted) return;
    setState(() => _isSaving = false);
  }

  Future<void> _submitForm(String name, String email, String meslek,
      String cepTelefon, String password, String cinsiyet) async {
    try {
      SharedPreferences localStorage = await SharedPreferences.getInstance();
      var user = jsonDecode(localStorage.getString('musteri')!);

      Map<String, dynamic> formData = {
        'yetkili_id': user["id"],
        'name': name,
        'email': email,
        'meslek': meslek,
        'cep_telefon': cepTelefon,
        'password': password,
        if (cinsiyet.isNotEmpty) 'cinsiyet': int.parse(cinsiyet),
      };

      // GUVENLIK: backend self-update dogrulamasi icin Passport token'i gonder.
      // Token login akisinda json.encode ile 'token' key'ine yazilir.
      String? token;
      final rawToken = localStorage.getString('token');
      if (rawToken != null && rawToken.isNotEmpty) {
        try {
          final d = jsonDecode(rawToken);
          token = d is String ? d : d?.toString();
        } catch (_) {
          token = rawToken;
        }
      }

      final response = await http.post(
        Uri.parse(
            'https://app.randevumcepte.com.tr//api/v1/musteribilgiguncelle'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(formData),
      );

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);
        await localStorage.setString('musteri', jsonEncode(responseData));

        await _refreshUserData();

        if (!mounted) return;
        mpMesaj(context, widget.mod == 'sifre' ? 'Şifreniz güncellendi.' : 'Bilgileriniz güncellendi.');
        if (widget.mod == 'sifre') _sifre.clear();
      } else {
        if (!mounted) return;
        mpMesaj(context, 'Güncellenemedi (hata kodu: ${response.statusCode}).', hata: true);
        debugPrint('Error: ${response.body}');
      }
    } catch (e) {
      if (!mounted) return;
      mpMesaj(context, 'Bir hata oluştu: $e', hata: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sifre = widget.mod == 'sifre';
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: MPAltSayfa(
        baslik: sifre ? 'Şifre Değiştir' : 'Bilgilerimi Düzenle',
        altDugme: _saveBar(context),
        govde: Form(
          key: _formKey,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [sifre ? _securityCard(context) : _personalCard(context)],
          ),
        ),
      ),
    );
  }

  Widget _personalCard(BuildContext context) {
    return _card(
      context,
      child: Column(
        children: [
          _labeledField(
            label: 'Ad Soyad',
            icon: Icons.badge_outlined,
            child: TextFormField(
              controller: _adsoyad,
              keyboardType: TextInputType.text,
              textCapitalization: TextCapitalization.words,
              decoration: _inputDecoration(hint: 'Ad ve soyad'),
              onSaved: (v) => _adsoyad.text = v ?? '',
            ),
          ),
          _divider(),
          _labeledField(
            label: 'E-Posta',
            icon: Icons.mail_outline_rounded,
            child: TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: _inputDecoration(hint: 'ornek@email.com'),
              onSaved: (v) => _email.text = v ?? '',
            ),
          ),
          _divider(),
          _labeledField(
            label: 'Meslek',
            icon: Icons.work_outline_rounded,
            child: TextFormField(
              controller: _meslek,
              keyboardType: TextInputType.text,
              decoration: _inputDecoration(hint: 'Örn. Mühendis'),
              onChanged: (_) => setState(() {}),
              onSaved: (v) => _meslek.text = v ?? '',
            ),
          ),
          _divider(),
          _labeledField(
            label: 'Telefon Numarası',
            icon: Icons.phone_outlined,
            child: TextFormField(
              controller: _telefon,
              inputFormatters: [phoneMask],
              keyboardType: TextInputType.phone,
              decoration: _inputDecoration(hint: '0xxx xxx xx xx'),
              onTap: () {
                if (_telefon.text.length < 2) _telefon.text = '0';
                _telefon.selection = TextSelection.fromPosition(
                  TextPosition(offset: _telefon.text.length),
                );
              },
              onChanged: (value) {
                if (!value.startsWith('0')) {
                  _telefon.text = '0';
                  _telefon.selection = TextSelection.fromPosition(
                    TextPosition(offset: _telefon.text.length),
                  );
                }
                setState(() {});
              },
              onSaved: (v) => _telefon.text = v ?? '',
            ),
          ),
          _divider(),
          _labeledField(
            label: 'Cinsiyet',
            icon: Icons.wc_rounded,
            child: _genderSegment(context),
          ),
        ],
      ),
    );
  }

  Widget _securityCard(BuildContext context) {
    return _card(
      context,
      child: _labeledField(
        label: 'Yeni Şifre',
        icon: Icons.lock_outline_rounded,
        child: TextFormField(
          controller: _sifre,
          obscureText: _isObscure,
          decoration: _inputDecoration(
            hint: 'Değiştirmek için yeni şifre girin',
            suffix: IconButton(
              icon: Icon(
                _isObscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
              onPressed: () => setState(() => _isObscure = !_isObscure),
            ),
          ),
          onSaved: (v) => _sifre.text = v ?? '',
        ),
      ),
    );
  }

  Widget _genderSegment(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget cell(String value, String label, IconData icon) {
      final selected = _selectedGender == value;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _selectedGender = value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              gradient: selected
                  ? LinearGradient(
                      colors: MusteriPalet.of(context).dugme,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: selected ? null : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    size: 16,
                    color: selected
                        ? Colors.white
                        : scheme.onSurface.withValues(alpha: 0.6)),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? Colors.white
                        : scheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          cell('kadin', 'Kadın', Icons.female_rounded),
          cell('erkek', 'Erkek', Icons.male_rounded),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, {required Widget child}) =>
      MPKart(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), child: child);

  Widget _labeledField({
    required String label,
    required IconData icon,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon,
                  size: 14,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.55)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _divider() {
    return Divider(
      height: 1,
      thickness: 1,
      color:
          Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
    );
  }

  InputDecoration _inputDecoration({String? hint, Widget? suffix}) {
    final scheme = Theme.of(context).colorScheme;
    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: scheme.primary.withValues(alpha: 0.04),
      hintText: hint,
      hintStyle: TextStyle(
        color: scheme.onSurface.withValues(alpha: 0.4),
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:
            BorderSide(color: scheme.primary.withValues(alpha: 0.10)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.primary, width: 1.4),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      suffixIcon: suffix,
    );
  }

  Widget _saveBar(BuildContext context) {
    final p = MusteriPalet.of(context);
    return GestureDetector(
      onTap: _isSaving ? null : _submit,
      child: Container(
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: p.dugme, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: p.dugmeAna.withValues(alpha: 0.30), blurRadius: 18, offset: const Offset(0, 8))],
        ),
        child: _isSaving
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4))
            : Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(widget.mod == 'sifre' ? 'Şifreyi Güncelle' : 'Bilgileri Güncelle',
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.2)),
              ]),
      ),
    );
  }

  @override
  void dispose() {
    _adsoyad.dispose();
    _email.dispose();
    _telefon.dispose();
    _meslek.dispose();
    _sifre.dispose();
    super.dispose();
  }
}

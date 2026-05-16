import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'package:randevu_sistem/Frontend/cropimage.dart';
import 'package:randevu_sistem/Models/user.dart';

import 'hesapkaldirmaisletme.dart';

class ProfilBilgileri extends StatefulWidget {
  final Kullanici kullanici;
  const ProfilBilgileri({super.key, required this.kullanici});

  @override
  State<ProfilBilgileri> createState() => _ProfilBilgileriPageState();
}

class _ProfilBilgileriPageState extends State<ProfilBilgileri> {
  late TextEditingController _adsoyad;
  late TextEditingController _email;
  late TextEditingController _telefon;
  late TextEditingController _unvan;
  late TextEditingController _sifre;

  final _formKey = GlobalKey<FormState>();
  final phoneMask = MaskTextInputFormatter(
    mask: '0### ### ## ##',
    filter: {"#": RegExp(r'[0-9]')},
  );

  String _selectedGender = '';
  bool _isObscure = true;
  File? _profileImage;
  Kullanici? _currentUser;
  bool _isLoading = false;
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
    _adsoyad = TextEditingController();
    _email = TextEditingController();
    _telefon = TextEditingController(text: '0');
    _unvan = TextEditingController();
    _sifre = TextEditingController();
    _initializeData();
  }

  Future<void> _initializeData() async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    var userData = jsonDecode(localStorage.getString('user')!);
    setState(() {
      _currentUser = Kullanici.fromJson(userData);
      _updateControllers();
    });
  }

  Future<void> _refreshUserData() async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    var userData = jsonDecode(localStorage.getString('user')!);
    setState(() {
      _currentUser = Kullanici.fromJson(userData);
      _updateControllers();
    });
  }

  void _updateControllers() {
    _adsoyad.text =
        _currentUser?.name != 'null' ? (_currentUser?.name ?? '') : '';
    _email.text =
        _currentUser?.email != 'null' ? (_currentUser?.email ?? '') : '';
    _telefon.text = _formatPhone(_currentUser?.gsm1);
    _unvan.text =
        _currentUser?.unvan != 'null' ? (_currentUser?.unvan ?? '') : '';

    if (_currentUser?.cinsiyet == '0') {
      _selectedGender = 'kadin';
    } else if (_currentUser?.cinsiyet == '1') {
      _selectedGender = 'erkek';
    }
  }

  Future<void> _pickAndCropImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    if (!mounted) return;
    final croppedFile = await Navigator.push<File>(
      context,
      MaterialPageRoute(
          builder: (_) => CropScreen(imageFile: File(pickedFile.path))),
    );

    if (croppedFile != null) {
      setState(() => _isLoading = true);
      await _uploadImage(croppedFile);
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadImage(File image) async {
    try {
      SharedPreferences localStorage = await SharedPreferences.getInstance();
      var user = jsonDecode(localStorage.getString('user')!);

      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
            'https://apptest.randevumcepte.com.tr/api/v1/profilresimyukle'),
      );

      request.fields['yetkili_id'] = user["id"].toString();
      request.files
          .add(await http.MultipartFile.fromPath('folderPath', image.path));

      var response = await request.send();

      if (response.statusCode == 200) {
        var responseData = await http.Response.fromStream(response);
        var responseBody = jsonDecode(responseData.body);

        String newProfileImageUrl = responseBody['profilresmi'] ?? '';
        user['profil_resim'] = newProfileImageUrl;
        await localStorage.setString('user', jsonEncode(user));

        if (!mounted) return;
        setState(() {
          _profileImage = image;
          _currentUser = Kullanici.fromJson(user);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil resmi başarıyla güncellendi!')),
        );
      } else {
        var responseData = await http.Response.fromStream(response);
        debugPrint(
            'Upload error: ${response.statusCode}, Body: ${responseData.body}');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Profil resmi güncellenirken hata oluştu!')),
        );
      }
    } catch (e) {
      debugPrint('Exception: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Profil resmi güncellenirken bir istisna oluştu!')),
      );
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _formKey.currentState!.save();
    setState(() => _isSaving = true);
    await submitForm(
      context,
      _adsoyad.text,
      _email.text,
      _unvan.text,
      _telefon.text.replaceAll(RegExp(r'\D'), ''),
      _sifre.text,
      _selectedGender == 'kadin' ? '0' : '1',
    );
    if (!mounted) return;
    setState(() => _isSaving = false);
  }

  ImageProvider? _getProfileImage() {
    if (_profileImage != null) return FileImage(_profileImage!);
    if (_currentUser?.profil_resim != null &&
        _currentUser!.profil_resim.isNotEmpty) {
      return NetworkImage(
          'https://apptest.randevumcepte.com.tr${_currentUser!.profil_resim}');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_currentUser == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: scheme.primary),
        ),
      );
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          leading: IconButton(
            icon: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(Icons.arrow_back_rounded,
                  color: scheme.onSurface, size: 20),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Profil Bilgileri',
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          centerTitle: true,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                Color.alphaBlend(
                    scheme.primary.withValues(alpha: 0.36), Colors.white),
                Color.alphaBlend(
                    scheme.tertiary.withValues(alpha: 0.08), Colors.white),
              ],
            ),
          ),
          child: SafeArea(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(color: scheme.primary))
                : RefreshIndicator(
                    color: scheme.primary,
                    backgroundColor: Colors.white,
                    strokeWidth: 3,
                    onRefresh: () async {
                      await _refreshUserData();
                      await Future<void>.delayed(
                          const Duration(milliseconds: 600));
                    },
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics()),
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                        children: [
                          _heroHeader(context),
                          const SizedBox(height: 22),
                          _sectionTitle(context, 'Kişisel Bilgiler',
                              Icons.person_outline_rounded),
                          const SizedBox(height: 10),
                          _personalCard(context),
                          const SizedBox(height: 18),
                          _sectionTitle(context, 'Güvenlik',
                              Icons.lock_outline_rounded),
                          const SizedBox(height: 10),
                          _securityCard(context),
                          const SizedBox(height: 18),
                          _dangerZone(context),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
        bottomNavigationBar: _saveBar(context),
      ),
    );
  }

  Widget _heroHeader(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasImage = _getProfileImage() != null;
    return Center(
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 116,
                height: 116,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [scheme.primary, scheme.tertiary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.25),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(4),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  padding: const EdgeInsets.all(3),
                  child: CircleAvatar(
                    backgroundColor:
                        scheme.primary.withValues(alpha: 0.10),
                    backgroundImage: _getProfileImage(),
                    child: !hasImage
                        ? Icon(Icons.person_rounded,
                            size: 48, color: scheme.primary)
                        : null,
                  ),
                ),
              ),
              Positioned(
                bottom: -2,
                right: -2,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _pickAndCropImage,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: scheme.primary.withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(Icons.camera_alt_rounded,
                          color: scheme.primary, size: 18),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _currentUser!.name == 'null' ? '-' : _currentUser!.name,
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          if ((_currentUser?.unvan ?? '').isNotEmpty &&
              _currentUser?.unvan != 'null') ...[
            const SizedBox(height: 4),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                _currentUser!.unvan,
                style: TextStyle(
                  color: scheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.phone_rounded,
                  size: 14,
                  color: scheme.onSurface.withValues(alpha: 0.55)),
              const SizedBox(width: 4),
              Text(
                _formatPhone(_currentUser?.gsm1),
                style: TextStyle(
                  color: scheme.onSurface.withValues(alpha: 0.65),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title, IconData icon) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: scheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ],
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
            label: 'Unvan',
            icon: Icons.work_outline_rounded,
            child: TextFormField(
              controller: _unvan,
              keyboardType: TextInputType.text,
              decoration: _inputDecoration(hint: 'Örn. Yönetici'),
              onSaved: (v) => _unvan.text = v ?? '',
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
                      colors: [scheme.primary, scheme.tertiary],
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
                        ? scheme.onPrimary
                        : scheme.onSurface.withValues(alpha: 0.6)),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? scheme.onPrimary
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

  Widget _card(BuildContext context, {required Widget child}) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: child,
    );
  }

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
      color: Theme.of(context)
          .colorScheme
          .onSurface
          .withValues(alpha: 0.06),
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

  Widget _dangerZone(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const danger = Color(0xFFEF4444);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  HesapKaldirmaIsletme(kullanici: _currentUser!),
            ),
          );
        },
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: danger.withValues(alpha: 0.18)),
            boxShadow: [
              BoxShadow(
                color: danger.withValues(alpha: 0.06),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: danger.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline_rounded,
                    color: danger, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hesabımı Sil',
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Hesabınızı kalıcı olarak kaldırın',
                      style: TextStyle(
                        color: scheme.onSurface.withValues(alpha: 0.55),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: scheme.onSurface.withValues(alpha: 0.4)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _saveBar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _isSaving ? null : _submit,
            child: Container(
              height: 54,
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
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: _isSaving
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: scheme.onPrimary,
                          strokeWidth: 2.4,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_outline_rounded,
                              color: scheme.onPrimary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Bilgileri Güncelle',
                            style: TextStyle(
                              color: scheme.onPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
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

  @override
  void dispose() {
    _adsoyad.dispose();
    _email.dispose();
    _telefon.dispose();
    _unvan.dispose();
    _sifre.dispose();
    super.dispose();
  }
}

Future<void> submitForm(
  context,
  String name,
  String email,
  String unvan,
  String gsm1,
  String password,
  String cinsiyet,
) async {
  SharedPreferences localStorage = await SharedPreferences.getInstance();
  var user = jsonDecode(localStorage.getString('user')!);

  Map<String, dynamic> formData = {
    'yetkili_id': user["id"],
    'name': name,
    'email': email,
    'unvan': unvan,
    'gsm1': gsm1,
    'password': password,
    'cinsiyet': int.parse(cinsiyet),
  };

  final response = await http.post(
    Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/bilgiguncelle'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),
  );

  if (response.statusCode == 200) {
    var responseData = jsonDecode(response.body);
    await localStorage.setString('user', json.encode(responseData));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profil bilgileriniz başarıyla güncellendi!'),
      ),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Profil bilgileriniz kaydedilirken hata oluştu! Hata kodu : ${response.statusCode}'),
      ),
    );
    debugPrint('Error: ${response.body}');
  }
}

import 'dart:convert';
import 'dart:developer';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:randevu_sistem/Frontend/telefon_ulke_alani.dart';
import 'package:randevu_sistem/Frontend/aramali_dropdown.dart';

import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Frontend/progressloading.dart';
import 'package:randevu_sistem/Models/musteri_danisanlar.dart';
import 'package:randevu_sistem/Models/musteridanisanreferans.dart';
import 'package:randevu_sistem/theme/premium_components.dart';

import 'musteriliste.dart';

class Yenimusteri extends StatefulWidget {
  final dynamic isletmebilgi;
  final String telefon;
  final String isim;
  final bool sadeceekranikapat;
  final int kullanicirolu;
  const Yenimusteri({
    Key? key,
    required this.kullanicirolu,
    required this.isletmebilgi,
    required this.telefon,
    required this.sadeceekranikapat,
    required this.isim,
  }) : super(key: key);

  @override
  _YenimusteriState createState() => _YenimusteriState();
}

class _YenimusteriState extends State<Yenimusteri> {
  final List<Referans> musterireferans = [
    Referans(id: "", referans: "Yok"),
    Referans(id: "1", referans: "İnternet"),
    Referans(id: "2", referans: "Reklam"),
    Referans(id: "3", referans: "Instagram"),
    Referans(id: "4", referans: "Facebook"),
    Referans(id: "5", referans: "Tanıdık"),
  ];
  late String seciliisletme;

  Referans? selectedmusterireferans;
  final TextEditingController musterireferanscontroller =
      TextEditingController();
  final TextEditingController adsoyad = TextEditingController();
  final TextEditingController telefon = TextEditingController();
  final TextEditingController dogumtarihi = TextEditingController();
  final TextEditingController eposta = TextEditingController();
  final TextEditingController notlar = TextEditingController();
  String selectedcinsiyet = '';
  bool yukleniyor = true;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    dogumtarihi.text = "";
    super.initState();
    initialize();
  }

  Future<void> initialize() async {
    seciliisletme = (await secilisalonid())!;
    if (!mounted) return;
    setState(() {
      telefon.text = widget.telefon;
      adsoyad.text = widget.isim;
      yukleniyor = false;
      selectedmusterireferans =
          musterireferans.firstWhere((item) => item.id == "");
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final primary = scheme.primary;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Color.alphaBlend(primary.withValues(alpha: 0.36), Colors.white),
            Color.alphaBlend(
                scheme.tertiary.withValues(alpha: 0.08), Colors.white),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          centerTitle: false,
          title: Text(
            'Yeni Müşteri',
            style: TextStyle(
              color: scheme.onSurface,
              fontWeight: FontWeight.w800,
              fontSize: 22,
              letterSpacing: -0.3,
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: primary, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          toolbarHeight: 72,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: yukleniyor
            ? Center(
                child: CircularProgressIndicator(
                  color: primary,
                  strokeWidth: 2.5,
                ),
              )
            : _buildForm(primary),
        bottomNavigationBar: yukleniyor ? null : _buildSaveBar(primary),
      ),
    );
  }

  Widget _buildForm(Color primary) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _avatarBlock(primary),
                const SizedBox(height: 24),
                _sectionTitle(
                    'Kişisel Bilgiler', Icons.person_outline_rounded, primary),
                _buildField(
                  label: 'Ad Soyad',
                  icon: Icons.badge_outlined,
                  controller: adsoyad,
                  primary: primary,
                  onChanged: (_) => setState(() {}),
                  textCapitalization: TextCapitalization.words,
                ),
                _buildField(
                  label: 'Doğum Tarihi',
                  icon: Icons.cake_outlined,
                  controller: dogumtarihi,
                  primary: primary,
                  readOnly: true,
                  hint: 'yyyy-aa-gg',
                  onTap: _pickDate,
                ),
                _genderSelector(),
                const SizedBox(height: 18),
                _sectionTitle(
                    'İletişim', Icons.contact_mail_outlined, primary),
                _buildTelefonField(primary),
                _buildField(
                  label: 'E-posta',
                  icon: Icons.email_outlined,
                  controller: eposta,
                  primary: primary,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 18),
                _sectionTitle('Diğer', Icons.tune_rounded, primary),
                _referansSelector(primary),
                const SizedBox(height: 12),
                _buildField(
                  label: 'Notlar',
                  icon: Icons.notes_rounded,
                  controller: notlar,
                  primary: primary,
                  maxLines: 3,
                  hint: 'Müşteriyle ilgili özel notlar...',
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _avatarBlock(Color primary) {
    final name = adsoyad.text.trim();
    String initials = '?';
    if (name.isNotEmpty) {
      final parts =
          name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
      if (parts.length == 1) {
        initials = parts.first.substring(0, 1).toUpperCase();
      } else {
        initials = (parts.first.substring(0, 1) + parts.last.substring(0, 1))
            .toUpperCase();
      }
    }
    return Center(
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primary.withValues(alpha: 0.22),
                  primary.withValues(alpha: 0.08),
                ],
              ),
              border: Border.all(
                color: primary.withValues(alpha: 0.28),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.10),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Center(
              child: Text(
                initials,
                style: TextStyle(
                  color: primary,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            name.isEmpty ? 'Yeni Müşteri' : name,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: Colors.grey[800],
              letterSpacing: -0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text, IconData icon, Color primary) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 0, 0, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: primary),
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14.5,
              color: Colors.grey[800],
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  // Telefon: ulke kodu secici + numara. Diger alanlarla ayni kutu tasarimi.
  Widget _buildTelefonField(Color primary) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(
              'Telefon Numarası',
              style: TextStyle(
                fontSize: 12.5,
                color: Colors.grey[700],
                fontWeight: FontWeight.w700,
                letterSpacing: -0.1,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey[200]!, width: 1),
            ),
            child: TelefonUlkeAlani(
              controller: telefon,
              cerceveli: false,
              cursorColor: primary,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: Colors.grey[900],
              ),
              decoration: InputDecoration(
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w500,
                  fontSize: 13.5,
                ),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required Color primary,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    VoidCallback? onTap,
    ValueChanged<String>? onChanged,
    bool readOnly = false,
    String? hint,
    int maxLines = 1,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                color: Colors.grey[700],
                fontWeight: FontWeight.w700,
                letterSpacing: -0.1,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey[200]!, width: 1),
            ),
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              readOnly: readOnly,
              onTap: onTap,
              onChanged: onChanged,
              maxLines: maxLines,
              textCapitalization: textCapitalization,
              cursorColor: primary,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: Colors.grey[900],
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w500,
                  fontSize: 13.5,
                ),
                prefixIcon: Icon(icon, color: primary, size: 19),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _genderSelector() {
    Widget pill(String value, String label, IconData icon, Color color) {
      final selected = selectedcinsiyet == value;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => selectedcinsiyet = value),
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              color: selected
                  ? color.withValues(alpha: 0.12)
                  : Colors.grey[50],
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? color.withValues(alpha: 0.5)
                    : Colors.grey[200]!,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    size: 18,
                    color: selected ? color : Colors.grey[500]),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    color: selected ? color : Colors.grey[600],
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(
              'Cinsiyet',
              style: TextStyle(
                fontSize: 12.5,
                color: Colors.grey[700],
                fontWeight: FontWeight.w700,
                letterSpacing: -0.1,
              ),
            ),
          ),
          Row(
            children: [
              pill('0', 'Kadın', Icons.female_rounded,
                  const Color(0xFFE91E63)),
              const SizedBox(width: 10),
              pill('1', 'Erkek', Icons.male_rounded,
                  const Color(0xFF2196F3)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _referansSelector(Color primary) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(
              'Referans',
              style: TextStyle(
                fontSize: 12.5,
                color: Colors.grey[700],
                fontWeight: FontWeight.w700,
                letterSpacing: -0.1,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey[200]!, width: 1),
            ),
            child: DropdownButtonHideUnderline(
              child: AramaliDropdown<Referans>(
                isExpanded: true,
                hint: Row(
                  children: [
                    Icon(Icons.share_outlined, color: primary, size: 19),
                    const SizedBox(width: 12),
                    Text(
                      'Referans Seç',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                items: musterireferans
                    .map((item) => DropdownMenuItem(
                          value: item,
                          child: Text(
                            item.referans,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                        ))
                    .toList(),
                value: selectedmusterireferans,
                onChanged: (value) =>
                    setState(() => selectedmusterireferans = value),
                selectedItemBuilder: (context) => musterireferans
                    .map((item) => Row(
                          children: [
                            Icon(Icons.share_outlined,
                                color: primary, size: 19),
                            const SizedBox(width: 12),
                            Text(
                              item.referans,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[900],
                              ),
                            ),
                          ],
                        ))
                    .toList(),
                buttonStyleData: const ButtonStyleData(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  height: 52,
                ),
                dropdownStyleData: DropdownStyleData(
                  maxHeight: 240,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: Colors.white,
                  ),
                  elevation: 6,
                  offset: const Offset(0, -4),
                ),
                menuItemStyleData: const MenuItemStyleData(height: 42),
                onMenuStateChange: (isOpen) {
                  if (!isOpen) musterireferanscontroller.clear();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveBar(Color primary) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Material(
          color: primary,
          borderRadius: BorderRadius.circular(16),
          elevation: 0,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _onKaydet,
            child: Container(
              height: 52,
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.check_circle_rounded,
                      color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Müşteriyi Kaydet',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
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

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        dogumtarihi.text = DateFormat('yyyy-MM-dd').format(pickedDate);
      });
    }
  }

  Future<void> _onKaydet() async {
    log('🟢 [1] Kaydet butonuna basıldı');
    log('🟢 [2] seciliisletme: $seciliisletme');
    log('🟢 [3] adsoyad: "${adsoyad.text}"');
    log('🟢 [4] telefon: "${telefon.text}"');

    if (_formKey.currentState == null) {
      log('🔴 _formKey.currentState NULL');
      return;
    }
    if (!_formKey.currentState!.validate()) {
      log('🔴 validate() false döndü');
      return;
    }
    _formKey.currentState!.save();

    if (adsoyad.text.trim().isEmpty) {
      log('🔴 Ad soyad boş');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ad Soyad alanı zorunludur')),
      );
      return;
    }
    if (telefon.text.trim().isEmpty || telefon.text.trim() == '0') {
      log('🔴 Telefon boş');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Telefon numarası zorunludur')),
      );
      return;
    }
    log('🟢 [10] Validasyon geçti, submitForm çağrılıyor');

    try {
      MusteriDanisan yenimusteridanisan = await submitForm(
        widget.isletmebilgi,
        seciliisletme,
        adsoyad.text,
        telefon.text,
        eposta.text,
        dogumtarihi.text,
        selectedcinsiyet,
        selectedmusterireferans?.id ?? "",
        notlar.text,
        context,
      );
      log('🟢 [11] submitForm başarılı, id=${yenimusteridanisan.id}');
      if (!mounted) return;
      if (!widget.sadeceekranikapat) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MusteriListesi(
              kullanicirolu: widget.kullanicirolu,
              isletmebilgi: widget.isletmebilgi,
            ),
          ),
        );
      } else {
        Navigator.of(context).pop(yenimusteridanisan);
      }
    } catch (e, st) {
      log('🔴 Müşteri eklenemedi: $e');
      log('🔴 stack: $st');
    }
  }

  Future<MusteriDanisan> submitForm(
      dynamic isletmebilgisi,
      String salonid,
      String musteriad,
      String telefon,
      String e_posta,
      String dogumtarihi,
      String cinsiyet,
      String referans,
      String notlar,
      context) async {
    showProgressLoading(context);

    Map<String, dynamic> formData = {
      'ad_soyad': musteriad,
      'telefon': telefon,
      'email': e_posta,
      'dogum_tarihi': dogumtarihi,
      'cinsiyet': cinsiyet,
      'musteri_tipi': referans,
      'ozel_notlar': notlar
    };

    try {
      final response = await http.post(
        Uri.parse(
            'https://app.randevumcepte.com.tr/api/v1/musteriekleguncelle/' +
                salonid.toString()),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(formData),
      );

      log('musteri ekle response status: ${response.statusCode}');
      log('musteri ekle response body: ${response.body}');

      Navigator.of(context, rootNavigator: true).pop();

      if (response.statusCode != 200 && response.statusCode != 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Müşteri eklenirken bir hata oluştu! Hata kodu : ' +
                    response.statusCode.toString()),
          ),
        );
        throw Exception('Bir hata oluştu: ${response.statusCode}');
      }

      if (response.body.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sunucudan boş yanıt geldi. Müşteri eklenemedi.'),
          ),
        );
        throw Exception('Boş response body');
      }

      final decoded = json.decode(response.body);

      if (decoded is Map &&
          decoded.containsKey('status') &&
          decoded['status'] == 'warning') {
        final mesaj =
            decoded['mesaj']?.toString() ?? 'Bu numara zaten kayıtlı';
        final baslik =
            decoded['title']?.toString() ?? 'Müşteri Zaten Kayıtlı';
        await showPremiumWarning(
          context,
          title: baslik,
          message: mesaj,
          tone: 'warning',
        );
        throw Exception(mesaj);
      }

      return MusteriDanisan.fromJson(decoded as Map<String, dynamic>);
    } catch (e, stackTrace) {
      try {
        Navigator.of(context, rootNavigator: true).pop();
      } catch (_) {}
      log('musteri ekle hata: $e');
      log('stack: $stackTrace');
      if (!e.toString().contains('zaten kayıtlı') &&
          !e.toString().contains('Boş response') &&
          !e.toString().contains('Bir hata oluştu')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Müşteri eklenemedi: ${e.toString()}'),
          ),
        );
      }
      rethrow;
    }
  }
}

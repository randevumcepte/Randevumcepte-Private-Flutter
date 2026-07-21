import 'dart:convert';
import 'dart:developer';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:randevu_sistem/Frontend/telefon_ulke_alani.dart';

import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Backend/yetki.dart';
import 'package:randevu_sistem/Frontend/progressloading.dart';
import 'package:randevu_sistem/Models/musteri_danisanlar.dart';
import 'package:randevu_sistem/Models/musteridanisanreferans.dart';

import 'musteriliste.dart';

class MusteriDuzenle extends StatefulWidget {
  final MusteriDanisan md;
  final dynamic isletmebilgi;
  final int kullanicirolu;
  const MusteriDuzenle({
    Key? key,
    required this.md,
    required this.isletmebilgi,
    required this.kullanicirolu,
  }) : super(key: key);

  @override
  _MusteriDuzenleState createState() => _MusteriDuzenleState();
}

class _MusteriDuzenleState extends State<MusteriDuzenle> {
  final List<Referans> musterireferans = [
    Referans(id: " ", referans: "Yok"),
    Referans(id: "1", referans: "İnternet"),
    Referans(id: "2", referans: "Reklam"),
    Referans(id: "3", referans: "Instagram"),
    Referans(id: "4", referans: "Facebook"),
    Referans(id: "5", referans: "Tanıdık"),
  ];

  late String seciliisletme;
  Referans? selectedmusterireferans;

  late TextEditingController musteriid;
  late TextEditingController adsoyad;
  late TextEditingController telefon;
  late TextEditingController dogumtarihi;
  late TextEditingController eposta;
  late TextEditingController notlar;

  final TextEditingController musterireferanscontroller =
      TextEditingController();

  String selectedcinsiyet = '';
  bool yukleniyor = true;

  // Personel yetkisi yoksa musteri telefonu hic gosterilmez ve duzenlenemez
  bool get _telGor => Yetki.varMi('musteri.telefon_gor');

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    if (widget.md.cinsiyet == '0') {
      selectedcinsiyet = '0';
    } else if (widget.md.cinsiyet == '1') {
      selectedcinsiyet = '1';
    }

    musteriid = TextEditingController(text: widget.md.id);
    adsoyad = TextEditingController(
        text: widget.md.name != 'null' ? widget.md.name : '');
    // _telGor: ham deger verilir, TelefonUlkeAlani ulke kodunu kendi cozer
    // (yabanci numaralarda basa '0' eklemek "0+355..." bozulmasina yol aciyordu)
    telefon = TextEditingController(
        text: widget.md.cep_telefon != 'null'
            ? (_telGor ? widget.md.cep_telefon
                       : Yetki.telefonGoster('0${widget.md.cep_telefon}'))
            : '');
    dogumtarihi = TextEditingController(
        text: widget.md.dogum_tarihi != 'null' ? widget.md.dogum_tarihi : '');
    eposta = TextEditingController(
        text: widget.md.eposta != 'null' ? widget.md.eposta : '');
    notlar = TextEditingController(
        text: widget.md.ozel_notlar != 'null' ? widget.md.ozel_notlar : '');

    selectedmusterireferans = musterireferans.firstWhere(
      (item) => item.id == widget.md.musteri_tipi,
      orElse: () => musterireferans.first,
    );

    initialize();
  }

  Future<void> initialize() async {
    seciliisletme = (await secilisalonid())!;
    if (!mounted) return;
    setState(() {
      yukleniyor = false;
    });
  }

  @override
  void dispose() {
    musteriid.dispose();
    adsoyad.dispose();
    telefon.dispose();
    dogumtarihi.dispose();
    eposta.dispose();
    notlar.dispose();
    musterireferanscontroller.dispose();
    super.dispose();
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
            'Müşteri Düzenle',
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
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Bu alan zorunludur';
                    }
                    return null;
                  },
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
                // Yetki varsa ulke kodu secicili alan, yoksa maskeli salt-okunur
                _telGor
                    ? _buildTelefonField(primary)
                    : _buildField(
                        label: 'Telefon Numarası',
                        icon: Icons.phone_outlined,
                        controller: telefon,
                        primary: primary,
                        keyboardType: TextInputType.phone,
                        readOnly: true,
                      ),
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

    final pr = widget.md.profil_resim;
    final hasImage = pr != null && pr.isNotEmpty && pr != 'null';

    return Center(
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: hasImage
                  ? null
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        primary.withValues(alpha: 0.22),
                        primary.withValues(alpha: 0.08),
                      ],
                    ),
              image: hasImage
                  ? DecorationImage(
                      image: NetworkImage(pr),
                      fit: BoxFit.cover,
                    )
                  : null,
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
            child: hasImage
                ? null
                : Center(
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
            name.isEmpty ? 'Müşteri Düzenle' : name,
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
              validator: (v) =>
                  TelefonUlke.bos(v) ? 'Bu alan zorunludur' : null,
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
    String? Function(String?)? validator,
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
              validator: validator,
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
              color:
                  selected ? color.withValues(alpha: 0.12) : Colors.grey[50],
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
                    size: 18, color: selected ? color : Colors.grey[500]),
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
              child: DropdownButton2<Referans>(
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
                    'Değişiklikleri Kaydet',
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
    DateTime initial = DateTime.now();
    try {
      if (dogumtarihi.text.isNotEmpty) {
        initial = DateTime.parse(dogumtarihi.text);
      }
    } catch (_) {}
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
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
    if (_formKey.currentState == null) return;
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    // Yetki yoksa kullanici telefonu degistirememeli — orijinali geri gonder.
    // Ham deger gonderilir: yabanci numarada basa '0' koymak "0+355..." yapardi.
    final tel = _telGor
        ? telefon.text
        : (widget.md.cep_telefon != 'null' ? widget.md.cep_telefon : '');

    try {
      await submitForm(
        widget.isletmebilgi,
        musteriid.text,
        seciliisletme,
        adsoyad.text,
        tel,
        eposta.text,
        dogumtarihi.text,
        selectedcinsiyet,
        selectedmusterireferans?.id ?? "",
        notlar.text,
        context,
      );
    } catch (e, st) {
      log('musteri guncelle hata: $e');
      log('stack: $st');
    }
  }

  Future<void> submitForm(
      dynamic isletmebilgi,
      String musteri_id,
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
      'ozel_notlar': notlar,
      'musteri_id': musteri_id,
    };

    try {
      final response = await http.post(
        Uri.parse(
            'https://app.randevumcepte.com.tr/api/v1/musteriekleguncelle/' +
                salonid.toString()),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(formData),
      );

      log('musteri guncelle response status: ${response.statusCode}');
      log('musteri guncelle response body: ${response.body}');

      try {
        Navigator.of(context, rootNavigator: true).pop();
      } catch (_) {}

      if (response.statusCode == 200) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MusteriListesi(
              kullanicirolu: widget.kullanicirolu,
              isletmebilgi: isletmebilgi,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Müşteri güncellenirken bir hata oluştu! Hata kodu : ' +
                    response.statusCode.toString()),
          ),
        );
      }
    } catch (e) {
      try {
        Navigator.of(context, rootNavigator: true).pop();
      } catch (_) {}
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Müşteri güncellenemedi: ${e.toString()}'),
        ),
      );
      rethrow;
    }
  }
}

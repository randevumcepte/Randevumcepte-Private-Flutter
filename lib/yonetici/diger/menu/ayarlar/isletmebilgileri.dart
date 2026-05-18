import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';

class IsletmeBilgileri extends StatefulWidget {
  final dynamic isletmebilgi;
  const IsletmeBilgileri({super.key, required this.isletmebilgi});

  @override
  State<IsletmeBilgileri> createState() => _IsletmeBilgileriState();
}

class _IsletmeBilgileriState extends State<IsletmeBilgileri> {
  static const String _baseUrl = 'https://apptest.randevumcepte.com.tr';
  static const Color _accent = Color(0xFF5C008E);
  static const Color _bg = Color(0xFFF7F5FA);

  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  final _isletmeAdi = TextEditingController();
  final _isletmeAdres = TextEditingController();
  final _isletmeTelefon = TextEditingController();
  final _whatsapp = TextEditingController();
  final _aciklama = TextEditingController();
  final _instagram = TextEditingController();
  final _facebook = TextEditingController();
  final _vergiAdi = TextEditingController();
  final _vergiAdresi = TextEditingController();
  final _vergiTcNo = TextEditingController();
  final _vergiDairesi = TextEditingController();
  final _kdvOrani = TextEditingController();

  String? _salonId;
  String? _domain;
  String? _logoPath;
  File? _yeniLogo;

  List<Map<String, dynamic>> _salonTurleri = [];
  String? _salonTuruId;

  bool _isLoading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _isletmeAdi.dispose();
    _isletmeAdres.dispose();
    _isletmeTelefon.dispose();
    _whatsapp.dispose();
    _aciklama.dispose();
    _instagram.dispose();
    _facebook.dispose();
    _vergiAdi.dispose();
    _vergiAdresi.dispose();
    _vergiTcNo.dispose();
    _vergiDairesi.dispose();
    _kdvOrani.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      _salonId = await secilisalonid();
      final results = await Future.wait([
        fetchSalonSettings(_salonId ?? ''),
        _fetchSalonTurleri(),
      ]);
      final salon = results[0] as Map<String, dynamic>;
      final turler = results[1] as List<Map<String, dynamic>>;

      _isletmeAdi.text = (salon['salon_adi'] ?? '').toString();
      _isletmeAdres.text = (salon['adres'] ?? '').toString();
      _isletmeTelefon.text = (salon['telefon_1'] ?? '').toString();
      _whatsapp.text = (salon['whatsapp'] ?? '').toString();
      _aciklama.text = (salon['aciklama'] ?? '').toString();
      _instagram.text = (salon['instagram_sayfa'] ?? '').toString();
      _facebook.text = (salon['facebook_sayfa'] ?? '').toString();
      _vergiAdi.text = (salon['vergi_adi'] ?? '').toString();
      _vergiAdresi.text = (salon['vergi_adresi'] ?? '').toString();
      _vergiTcNo.text = (salon['vergi_no'] ?? '').toString();
      _vergiDairesi.text = (salon['vergi_dairesi'] ?? '').toString();
      _kdvOrani.text = (salon['kdv_orani'] ?? '').toString();
      _domain = (salon['domain'] ?? '').toString();
      _logoPath = (salon['logo'] ?? '').toString();
      _salonTuruId = salon['salon_turu_id']?.toString();

      _salonTurleri = turler;
      if (_salonTurleri.isNotEmpty &&
          !_salonTurleri.any((t) => t['id'].toString() == _salonTuruId)) {
        _salonTuruId = _salonTurleri.first['id'].toString();
      }
    } catch (e) {
      log('İşletme bilgileri yükleme hatası: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchSalonTurleri() async {
    try {
      final r = await http.get(
        Uri.parse('$_baseUrl/api/v1/salonturleri'),
        headers: {'Content-Type': 'application/json'},
      );
      if (r.statusCode == 200) {
        final list = jsonDecode(r.body) as List<dynamic>;
        return list.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (e) {
      log('Salon türleri yüklenemedi: $e');
    }
    return [];
  }

  Future<void> _logoSec() async {
    final src = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galeriden Seç'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Kamera ile Çek'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
    if (src == null) return;
    final picked = await _picker.pickImage(source: src, imageQuality: 85);
    if (picked == null) return;
    setState(() => _yeniLogo = File(picked.path));
  }

  Future<bool> _logoYukle() async {
    if (_yeniLogo == null || _salonId == null) return true;
    try {
      final req = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/api/v1/isletmelogoyukle'),
      );
      req.fields['sube'] = _salonId!;
      req.files.add(
        await http.MultipartFile.fromPath('isletmelogo', _yeniLogo!.path),
      );
      final response = await req.send();
      if (response.statusCode == 200) {
        final body = await http.Response.fromStream(response);
        final data = jsonDecode(body.body);
        _logoPath = data['logo']?.toString();
        _yeniLogo = null;
        return true;
      }
      return false;
    } catch (e) {
      log('Logo yükleme hatası: $e');
      return false;
    }
  }

  Future<void> _kaydet() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_salonId == null) return;
    setState(() => _saving = true);
    HapticFeedback.mediumImpact();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final logoOk = await _logoYukle();
      if (!logoOk) {
        throw Exception('Logo yüklenemedi');
      }
      final response = await http.post(
        Uri.parse('$_baseUrl/api/v1/isletmebilgiguncelle'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sube': _salonId,
          'isletme_adi': _isletmeAdi.text.trim(),
          'isletme_adres': _isletmeAdres.text.trim(),
          'isletme_turu': _salonTuruId,
          'isletme_telefon': _isletmeTelefon.text.trim(),
          'whatsapp': _whatsapp.text.trim(),
          'isletme_aciklama': _aciklama.text.trim(),
          'instagram_url': _instagram.text.trim(),
          'facebook_url': _facebook.text.trim(),
          'vergi_adi': _vergiAdi.text.trim(),
          'vergi_adresi': _vergiAdresi.text.trim(),
          'vergi_tc_no': _vergiTcNo.text.trim(),
          'vergi_dairesi': _vergiDairesi.text.trim(),
          'kdv_orani': _kdvOrani.text.trim(),
        }),
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        setState(() => _saving = false);
        messenger.showSnackBar(
          SnackBar(
            content: const Text('İşletme bilgileri kaydedildi'),
            backgroundColor: _accent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(14),
          ),
        );
      } else {
        setState(() => _saving = false);
        messenger.showSnackBar(
          SnackBar(
            content: Text('Hata: ${response.statusCode}'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Bağlantı hatası: $e'),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          'İşletme Bilgileri',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          if (widget.isletmebilgi["demo_hesabi"].toString() == "1")
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
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
              child: CircularProgressIndicator(color: _accent, strokeWidth: 2.5),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 110),
                children: [
                  _kimlikKarti(),
                  const SizedBox(height: 14),
                  _tanitimKarti(),
                  const SizedBox(height: 14),
                  _iletisimKarti(),
                  const SizedBox(height: 14),
                  _faturaKarti(),
                ],
              ),
            ),
      bottomNavigationBar: _isLoading ? null : _saveBar(),
    );
  }

  // ---------- Kartlar ----------

  Widget _kimlikKarti() {
    return _card(
      icon: Icons.badge_outlined,
      iconColor: const Color(0xFF5C008E),
      title: 'İşletme Kimliği',
      subtitle: 'Logo, isim, tür ve iletişim bilgileri',
      children: [
        _logoBolumu(),
        const SizedBox(height: 18),
        _field(
          controller: _isletmeAdi,
          label: 'İşletme Adı',
          icon: Icons.store_mall_directory_outlined,
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'İşletme adı gerekli' : null,
        ),
        const SizedBox(height: 12),
        _salonTuruDropdown(),
        const SizedBox(height: 12),
        _field(
          controller: _isletmeAdres,
          label: 'Adres',
          icon: Icons.location_on_outlined,
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        _field(
          controller: _isletmeTelefon,
          label: 'Telefon',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 12),
        _field(
          controller: _whatsapp,
          label: 'WhatsApp',
          icon: Icons.chat_bubble_outline_rounded,
          iconColor: const Color(0xFF25D366),
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
      ],
    );
  }

  Widget _tanitimKarti() {
    return _card(
      icon: Icons.campaign_outlined,
      iconColor: const Color(0xFFF59E0B),
      title: 'İşletme Tanıtımı',
      subtitle: 'Tanıtım sayfasında "Hakkımızda" bölümünde görünür',
      children: [
        _field(
          controller: _aciklama,
          label: 'İşletme Açıklaması',
          icon: Icons.description_outlined,
          maxLines: 5,
          maxLength: 1500,
          hint:
              'Örn. 2010\'dan bu yana hizmet veriyoruz. Uzman kadromuz ve hijyenik ortamımızla...',
        ),
      ],
    );
  }

  Widget _iletisimKarti() {
    return _card(
      icon: Icons.link_rounded,
      iconColor: const Color(0xFF06B6D4),
      title: 'İletişim & Sosyal Medya',
      subtitle: 'Online randevu sayfanız ve sosyal medya linkleri',
      children: [
        if ((_domain ?? '').isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F5FA),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.black12),
            ),
            child: Row(
              children: [
                const Icon(Icons.public, size: 18, color: _accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'https://$_domain',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  onPressed: () {
                    Clipboard.setData(
                        ClipboardData(text: 'https://$_domain'));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Link kopyalandı'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        if ((_domain ?? '').isNotEmpty) const SizedBox(height: 12),
        _field(
          controller: _instagram,
          label: 'Instagram URL',
          icon: Icons.camera_alt_outlined,
          iconColor: const Color(0xFFE1306C),
          hint: 'https://instagram.com/...',
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 12),
        _field(
          controller: _facebook,
          label: 'Facebook URL',
          icon: Icons.facebook_rounded,
          iconColor: const Color(0xFF1877F2),
          hint: 'https://facebook.com/...',
          keyboardType: TextInputType.url,
        ),
      ],
    );
  }

  Widget _faturaKarti() {
    return _card(
      icon: Icons.receipt_long_outlined,
      iconColor: const Color(0xFF10B981),
      title: 'Fatura Ayarları',
      subtitle: 'Adisyon ve fatura kesimlerinde kullanılır',
      children: [
        _field(
          controller: _vergiAdi,
          label: 'Firma Adı / Ünvanı',
          icon: Icons.business_outlined,
        ),
        const SizedBox(height: 12),
        _field(
          controller: _vergiAdresi,
          label: 'Vergi Adresi',
          icon: Icons.location_on_outlined,
        ),
        const SizedBox(height: 12),
        _field(
          controller: _vergiTcNo,
          label: 'Vergi / TC No',
          icon: Icons.badge_outlined,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(11),
          ],
        ),
        const SizedBox(height: 12),
        _field(
          controller: _vergiDairesi,
          label: 'Vergi Dairesi',
          icon: Icons.account_balance_outlined,
        ),
        const SizedBox(height: 12),
        _field(
          controller: _kdvOrani,
          label: 'KDV Oranı (%)',
          icon: Icons.percent_rounded,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
      ],
    );
  }

  // ---------- Parçalar ----------

  Widget _logoBolumu() {
    final hasNew = _yeniLogo != null;
    final hasExisting = (_logoPath ?? '').isNotEmpty;
    final imgUrl = hasExisting
        ? (_logoPath!.startsWith('http')
            ? _logoPath!
            : '$_baseUrl/$_logoPath')
        : null;

    return Row(
      children: [
        GestureDetector(
          onTap: _logoSec,
          child: Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: const Color(0xFFF3EEF8),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _accent.withOpacity(0.25)),
              image: hasNew
                  ? DecorationImage(
                      image: FileImage(_yeniLogo!), fit: BoxFit.cover)
                  : (imgUrl != null
                      ? DecorationImage(
                          image: NetworkImage(imgUrl), fit: BoxFit.cover)
                      : null),
            ),
            child: (!hasNew && imgUrl == null)
                ? const Icon(Icons.add_a_photo_outlined,
                    color: _accent, size: 28)
                : null,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Logo',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Kalem simgesine basarak değiştirebilirsiniz. En fazla 240px genişlik önerilir.',
                style: TextStyle(
                  fontSize: 11.5,
                  color: Colors.black54,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _logoSec,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Logo Değiştir'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _accent,
                  side: const BorderSide(color: _accent),
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _salonTuruDropdown() {
    if (_salonTurleri.isEmpty) {
      return const SizedBox.shrink();
    }
    return DropdownButtonFormField<String>(
      value: _salonTuruId,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'İşletme Türü',
        prefixIcon: const Icon(Icons.category_outlined, color: _accent),
        filled: true,
        fillColor: const Color(0xFFFAFAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _accent, width: 1.4),
        ),
      ),
      items: _salonTurleri
          .map((t) => DropdownMenuItem<String>(
                value: t['id'].toString(),
                child: Text(
                  t['salon_turu_adi']?.toString() ?? '',
                  overflow: TextOverflow.ellipsis,
                ),
              ))
          .toList(),
      onChanged: (v) => setState(() => _salonTuruId = v),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    Color iconColor = _accent,
    String? hint,
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: iconColor, size: 20),
        filled: true,
        fillColor: const Color(0xFFFAFAFC),
        counterText: '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _accent, width: 1.4),
        ),
      ),
    );
  }

  Widget _card({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 18, thickness: 0.6),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _saveBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.black12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SizedBox(
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _saving ? null : _kaydet,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_rounded, size: 20),
            label: Text(
              _saving ? 'Kaydediliyor...' : 'Değişiklikleri Kaydet',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

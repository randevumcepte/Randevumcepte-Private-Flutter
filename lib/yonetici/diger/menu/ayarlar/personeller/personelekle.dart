import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Frontend/sfdatatable.dart';
import 'package:randevu_sistem/Models/hesapturu.dart';

// Modern soft tasarimli "Yeni Personel" sayfasi. UI tamamen yenilendi ama state
// alanlari ve PersonelDataSource.personelekleguncelle() cagrisi BOZULMADAN korundu —
// boylece backend tarafi hicbir sekilde etkilenmiyor.
//
// Tasarim referansi: web personelyonetimi.blade.php hero + section kartlari + mor
// gradient (#5C008E -> #9D5DC8).
class PersonelEkle extends StatefulWidget {
  final dynamic isletmebilgi;
  final PersonelDataSource personeldata;
  const PersonelEkle({super.key, required this.isletmebilgi, required this.personeldata});

  @override
  State<PersonelEkle> createState() => _PersonelEkleState();
}

class _PersonelEkleState extends State<PersonelEkle> {
  // === Tema sabitleri (Personeller sayfasi ile birebir) ===
  static const _p1 = Color(0xFF5C008E);
  static const _p2 = Color(0xFF7B2FB8);
  static const _p3 = Color(0xFF9D5DC8);
  static const _border = Color(0xFFECE6F2);
  static const _text = Color(0xFF2D1B3F);
  static const _muted = Color(0xFF8A8295);
  static const _grad = LinearGradient(
    colors: [_p1, _p2, _p3],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // === Form alanlari ===
  final TextEditingController personeladi = TextEditingController();
  final TextEditingController sabitmaas = TextEditingController();
  final TextEditingController hizmetprim = TextEditingController();
  final TextEditingController urunprim = TextEditingController();
  final TextEditingController paketprim = TextEditingController();
  final TextEditingController telefon = TextEditingController();
  final TextEditingController unvan = TextEditingController();
  final TextEditingController hesapturuscontroller = TextEditingController();

  final phoneMask = MaskTextInputFormatter(
    mask: '0### ### ## ##',
    filter: {"#": RegExp(r'[0-9]')},
  );

  String selectedcinsiyet = '';

  final List<HesapTuru> hesapturu = [
    HesapTuru(id: "1", hesapturu: "Hesap Sahibi"),
    HesapTuru(id: "2", hesapturu: "Süpervizör"),
    HesapTuru(id: "3", hesapturu: "Yönetici"),
    HesapTuru(id: "4", hesapturu: "Sekreter"),
    HesapTuru(id: "5", hesapturu: "Personel"),
    HesapTuru(id: "7", hesapturu: "Sanat Yönetmeni"),
    HesapTuru(id: "8", hesapturu: "Sosyal Medya Uzmanı"),
  ];
  HesapTuru? selectedhesapturu;

  late String seciliisletme;

  // Calisma saatleri kontrolleri (1-7: Pzt..Paz)
  final List<TextEditingController> calBas = List.generate(7, (_) => TextEditingController(text: "00:00"));
  final List<TextEditingController> calBit = List.generate(7, (_) => TextEditingController(text: "00:00"));
  final List<bool> calAcik = List.filled(7, false);

  // Mola saatleri kontrolleri (1-7: Pzt..Paz)
  final List<TextEditingController> molaBas = List.generate(7, (_) => TextEditingController(text: "00:00"));
  final List<TextEditingController> molaBit = List.generate(7, (_) => TextEditingController(text: "00:00"));
  final List<bool?> molaAcik = List.filled(7, null);

  TimeOfDay _selectedTime = TimeOfDay.now();
  final formKey = GlobalKey<FormState>();

  static const _gunler = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];

  // === Yasam dongusu ===
  @override
  void initState() {
    super.initState();
    telefon.text = "0";
    _fetchData();
  }

  Future<void> _fetchData() async {
    seciliisletme = (await secilisalonid())!;
    if (!mounted) return;
    setState(() {
      selectedhesapturu = hesapturu.firstWhere((item) => item.id == "", orElse: () => hesapturu[4]);
    });
  }

  @override
  void dispose() {
    for (final c in [personeladi, sabitmaas, hizmetprim, urunprim, paketprim, telefon, unvan, hesapturuscontroller]) {
      c.dispose();
    }
    for (final c in calBas) {
      c.dispose();
    }
    for (final c in calBit) {
      c.dispose();
    }
    for (final c in molaBas) {
      c.dispose();
    }
    for (final c in molaBit) {
      c.dispose();
    }
    super.dispose();
  }

  // === Modern saat secici (mevcut implementasyonun aynisi - mor renkli) ===
  Future<void> _showModernTimePicker(BuildContext context, TextEditingController controller) async {
    TimeOfDay initialTime = _selectedTime;
    if (controller.text.isNotEmpty) {
      try {
        final parts = controller.text.split(':');
        if (parts.length == 2) {
          initialTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
        }
      } catch (_) {}
    }
    final result = await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _buildModernTimePicker(initialTime),
    );
    if (result is TimeOfDay) {
      setState(() {
        _selectedTime = result;
        controller.text = '${result.hour.toString().padLeft(2, '0')}:${result.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Widget _buildModernTimePicker(TimeOfDay initialTime) {
    int selectedHour = initialTime.hour;
    int selectedMinute = _getNearestQuarterMinute(initialTime.minute);
    return StatefulBuilder(
      builder: (ctx, setSt) => Container(
        height: MediaQuery.of(ctx).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[200]!))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text('İptal', style: TextStyle(color: Colors.grey[600], fontSize: 16, fontWeight: FontWeight.w500)),
                  ),
                  const Text('Saat Seç', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _text)),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(TimeOfDay(hour: selectedHour, minute: selectedMinute)),
                    child: const Text('Tamam', style: TextStyle(color: _p1, fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                '${selectedHour.toString().padLeft(2, '0')}:${selectedMinute.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w300, color: _p1),
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: ListWheelScrollView(
                      itemExtent: 50,
                      perspective: 0.005,
                      diameterRatio: 1.5,
                      physics: const FixedExtentScrollPhysics(),
                      controller: FixedExtentScrollController(initialItem: selectedHour),
                      onSelectedItemChanged: (i) => setSt(() => selectedHour = i),
                      children: List.generate(24, (hour) {
                        final sel = hour == selectedHour;
                        return Container(
                          alignment: Alignment.center,
                          child: Text(
                            hour.toString().padLeft(2, '0'),
                            style: TextStyle(
                              fontSize: sel ? 22 : 18,
                              fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                              color: sel ? _p1 : Colors.grey[600],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  Expanded(
                    child: ListWheelScrollView(
                      itemExtent: 50,
                      perspective: 0.005,
                      diameterRatio: 1.5,
                      physics: const FixedExtentScrollPhysics(),
                      controller: FixedExtentScrollController(initialItem: _getIndexFromMinute(selectedMinute)),
                      onSelectedItemChanged: (i) => setSt(() => selectedMinute = _getMinuteFromIndex(i)),
                      children: List.generate(4, (i) {
                        final m = _getMinuteFromIndex(i);
                        final sel = m == selectedMinute;
                        return Container(
                          alignment: Alignment.center,
                          child: Text(
                            m.toString().padLeft(2, '0'),
                            style: TextStyle(
                              fontSize: sel ? 22 : 18,
                              fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                              color: sel ? _p1 : Colors.grey[600],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _getNearestQuarterMinute(int minute) {
    if (minute < 8) return 0;
    if (minute < 23) return 15;
    if (minute < 38) return 30;
    if (minute < 53) return 45;
    return 0;
  }

  int _getMinuteFromIndex(int i) => [0, 15, 30, 45][i % 4];
  int _getIndexFromMinute(int m) => [0, 15, 30, 45].indexOf(m).clamp(0, 3);

  // === Submit ===
  void _kaydet() {
    widget.personeldata.personelekleguncelle(
      "",
      personeladi.text,
      unvan.text,
      telefon.text,
      selectedhesapturu?.id ?? "",
      selectedcinsiyet,
      sabitmaas.text,
      hizmetprim.text,
      urunprim.text,
      paketprim.text,
      seciliisletme,
      calAcik[0], calAcik[1], calAcik[2], calAcik[3], calAcik[4], calAcik[5], calAcik[6],
      calBas[0].text, calBas[1].text, calBas[2].text, calBas[3].text, calBas[4].text, calBas[5].text, calBas[6].text,
      calBit[0].text, calBit[1].text, calBit[2].text, calBit[3].text, calBit[4].text, calBit[5].text, calBit[6].text,
      molaAcik[0], molaAcik[1], molaAcik[2], molaAcik[3], molaAcik[4], molaAcik[5], molaAcik[6],
      molaBas[0].text, molaBas[1].text, molaBas[2].text, molaBas[3].text, molaBas[4].text, molaBas[5].text, molaBas[6].text,
      molaBit[0].text, molaBit[1].text, molaBit[2].text, molaBit[3].text, molaBit[4].text, molaBit[5].text, molaBit[6].text,
      context,
    );
  }

  // === BUILD ===
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFFBF9FD),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0.5,
          iconTheme: const IconThemeData(color: _text),
          title: const Text('Yeni Personel', style: TextStyle(color: _text, fontWeight: FontWeight.w600)),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              child: _kaydetBtn(compact: true),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _hero(),
                  const SizedBox(height: 14),
                  _section(
                    icon: Icons.person_outline,
                    title: 'Temel Bilgiler',
                    children: [
                      _label('Personel Adı'),
                      _modernField(controller: personeladi, hint: 'Adı Soyadı'),
                      const SizedBox(height: 12),
                      _label('Cinsiyet'),
                      _cinsiyetSec(),
                      const SizedBox(height: 12),
                      _label('Cep Telefonu'),
                      _modernField(
                        controller: telefon,
                        hint: '0XXX XXX XX XX',
                        keyboard: TextInputType.phone,
                        formatters: [phoneMask],
                        onTap: () {
                          if (telefon.text.length < 2) telefon.text = "0";
                          telefon.selection = TextSelection.fromPosition(TextPosition(offset: telefon.text.length));
                        },
                        onChanged: (v) {
                          if (!v.startsWith("0")) {
                            telefon.text = "0";
                            telefon.selection = TextSelection.fromPosition(TextPosition(offset: telefon.text.length));
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      _label('Unvan'),
                      _modernField(controller: unvan, hint: 'Berber, Kuaför, Estetisyen...'),
                      const SizedBox(height: 12),
                      _label('Hesap Türü'),
                      _hesapTuruDropdown(),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _section(
                    icon: Icons.attach_money,
                    title: 'Maaş & Prim Hak Edişi',
                    accent: const Color(0xFF10B981),
                    children: [
                      _label('Sabit Maaş (₺)'),
                      _modernField(controller: sabitmaas, hint: '0', keyboard: TextInputType.number),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('Hizmet Primi (%)'),
                                _modernField(controller: hizmetprim, hint: '0', keyboard: TextInputType.number),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('Ürün Primi (%)'),
                                _modernField(controller: urunprim, hint: '0', keyboard: TextInputType.number),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _label('Paket Primi (%)'),
                      _modernField(controller: paketprim, hint: '0', keyboard: TextInputType.number),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _section(
                    icon: Icons.access_time_rounded,
                    title: 'Çalışma Saatleri',
                    accent: const Color(0xFF3B82F6),
                    children: [
                      for (var i = 0; i < 7; i++)
                        _gunSatiri(
                          gun: _gunler[i],
                          acik: calAcik[i],
                          onToggle: (v) => setState(() => calAcik[i] = v ?? false),
                          basCtrl: calBas[i],
                          bitCtrl: calBit[i],
                          accent: const Color(0xFF3B82F6),
                          sonGun: i == 6,
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _section(
                    icon: Icons.free_breakfast_outlined,
                    title: 'Mola Saatleri',
                    accent: const Color(0xFFF59E0B),
                    children: [
                      for (var i = 0; i < 7; i++)
                        _gunSatiri(
                          gun: _gunler[i],
                          acik: molaAcik[i] ?? false,
                          onToggle: (v) => setState(() => molaAcik[i] = v),
                          basCtrl: molaBas[i],
                          bitCtrl: molaBit[i],
                          accent: const Color(0xFFF59E0B),
                          sonGun: i == 6,
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _kaydetBtn(compact: false),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // === Hero ===
  Widget _hero() {
    return Container(
      decoration: BoxDecoration(
        gradient: _grad,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: _p1.withValues(alpha: 0.22), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.person_add_alt_1, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Yeni Personel Ekle',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                SizedBox(height: 3),
                Text('Temel bilgiler, prim oranları ve çalışma saatleri',
                    style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // === Section ===
  Widget _section({
    required IconData icon,
    required String title,
    required List<Widget> children,
    Color accent = _p2,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [BoxShadow(color: _p1.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accent, size: 17),
              ),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(color: _text, fontWeight: FontWeight.w700, fontSize: 14.5)),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _label(String s) => Padding(
        padding: const EdgeInsets.only(bottom: 6, left: 2),
        child: Text(s,
            style: TextStyle(
              color: _muted,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            )),
      );

  // === Modern alan ===
  Widget _modernField({
    required TextEditingController controller,
    String? hint,
    TextInputType keyboard = TextInputType.text,
    List<MaskTextInputFormatter>? formatters,
    VoidCallback? onTap,
    ValueChanged<String>? onChanged,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      inputFormatters: formatters,
      onTap: onTap,
      onChanged: onChanged,
      style: const TextStyle(color: _text, fontSize: 14),
      cursorColor: _p1,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFB8AEC7), fontSize: 13.5),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFFFCFAFE),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: _border),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: _p2, width: 1.6),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // === Cinsiyet seçici (modern segmented) ===
  Widget _cinsiyetSec() {
    return Row(
      children: [
        Expanded(child: _cinsiyetBtn('Kadın', '0', Icons.female_rounded)),
        const SizedBox(width: 8),
        Expanded(child: _cinsiyetBtn('Erkek', '1', Icons.male_rounded)),
      ],
    );
  }

  Widget _cinsiyetBtn(String label, String value, IconData icon) {
    final sel = selectedcinsiyet == value;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => selectedcinsiyet = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: sel ? _grad : null,
          color: sel ? null : const Color(0xFFFCFAFE),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: sel ? Colors.transparent : _border),
          boxShadow: sel
              ? [BoxShadow(color: _p1.withValues(alpha: 0.22), blurRadius: 10, offset: const Offset(0, 4))]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: sel ? Colors.white : _muted, size: 18),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                  color: sel ? Colors.white : _text,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                )),
          ],
        ),
      ),
    );
  }

  // === Hesap Türü dropdown ===
  Widget _hesapTuruDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFCFAFE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton2<HesapTuru>(
          isExpanded: true,
          hint: const Text('Hesap Türü seçiniz', style: TextStyle(color: Color(0xFFB8AEC7), fontSize: 13.5)),
          items: hesapturu
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(item.hesapturu,
                        style: const TextStyle(fontSize: 14, color: _text, fontWeight: FontWeight.w500)),
                  ))
              .toList(),
          value: selectedhesapturu == null || selectedhesapturu!.id == ""
              ? null
              : selectedhesapturu,
          onChanged: (value) => setState(() => selectedhesapturu = value),
          buttonStyleData: const ButtonStyleData(
            padding: EdgeInsets.symmetric(horizontal: 4),
            height: 52,
          ),
          iconStyleData: const IconStyleData(
            icon: Icon(Icons.keyboard_arrow_down_rounded, color: _p1, size: 22),
          ),
          dropdownStyleData: DropdownStyleData(
            maxHeight: 240,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              boxShadow: [BoxShadow(color: _p1.withValues(alpha: 0.12), blurRadius: 14)],
            ),
          ),
          menuItemStyleData: const MenuItemStyleData(height: 44),
          onMenuStateChange: (open) {
            if (!open) hesapturuscontroller.clear();
          },
        ),
      ),
    );
  }

  // === Gün satırı (çalışma + mola için ortak) ===
  Widget _gunSatiri({
    required String gun,
    required bool acik,
    required ValueChanged<bool?> onToggle,
    required TextEditingController basCtrl,
    required TextEditingController bitCtrl,
    required Color accent,
    bool sonGun = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: sonGun ? 0 : 10),
      child: Container(
        decoration: BoxDecoration(
          color: acik ? accent.withValues(alpha: 0.06) : const Color(0xFFFCFAFE),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: acik ? accent.withValues(alpha: 0.3) : _border),
        ),
        padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
        child: Row(
          children: [
            // Toggle switch
            SizedBox(
              width: 44, height: 26,
              child: Transform.scale(
                scale: 0.85,
                child: Switch(
                  value: acik,
                  onChanged: onToggle,
                  activeThumbColor: Colors.white,
                  activeTrackColor: accent,
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: const Color(0xFFD1D5DB),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
            const SizedBox(width: 6),
            // Gun adi
            SizedBox(
              width: 78,
              child: Text(
                gun,
                style: TextStyle(
                  color: acik ? _text : _muted,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            // Saat alanlari
            Expanded(child: _saatAlani(basCtrl, accent, acik)),
            const SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Icon(Icons.arrow_forward, size: 14, color: acik ? accent : _muted),
            ),
            const SizedBox(width: 6),
            Expanded(child: _saatAlani(bitCtrl, accent, acik)),
          ],
        ),
      ),
    );
  }

  Widget _saatAlani(TextEditingController ctrl, Color accent, bool aktif) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: aktif ? () => _showModernTimePicker(context, ctrl) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: aktif ? accent.withValues(alpha: 0.4) : _border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.access_time, color: aktif ? accent : _muted, size: 13),
            const SizedBox(width: 5),
            Text(
              ctrl.text.isEmpty ? '00:00' : ctrl.text,
              style: TextStyle(
                color: aktif ? _text : _muted,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // === Kaydet butonu ===
  Widget _kaydetBtn({required bool compact}) {
    if (compact) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: _kaydet,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: _grad,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check, color: Colors.white, size: 16),
                SizedBox(width: 4),
                Text('Kaydet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13.5)),
              ],
            ),
          ),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        gradient: _grad,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: _p1.withValues(alpha: 0.3), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _kaydet,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white, size: 19),
                SizedBox(width: 8),
                Text('Personeli Kaydet',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

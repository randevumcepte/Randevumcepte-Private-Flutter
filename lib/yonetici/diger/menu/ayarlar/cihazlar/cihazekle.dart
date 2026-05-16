import 'package:flutter/material.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Frontend/sfdatatable.dart';

class CihazEkle extends StatefulWidget {
  final CihazDataSource cihazdatasource;
  final dynamic isletmebilgi;
  const CihazEkle({
    super.key,
    required this.cihazdatasource,
    required this.isletmebilgi,
  });

  @override
  State<CihazEkle> createState() => _CihazEkleState();
}

class _CihazEkleState extends State<CihazEkle> {
  static const Color _accent = Color(0xFF4F46E5);
  static const Color _accentLight = Color(0xFF818CF8);

  final TextEditingController cihazadi = TextEditingController();
  String? seciliisletme;
  bool _kaydediliyor = false;

  static const List<String> _gunler = [
    'Pazartesi',
    'Salı',
    'Çarşamba',
    'Perşembe',
    'Cuma',
    'Cumartesi',
    'Pazar',
  ];

  final List<TextEditingController> _calismaBaslangic =
      List.generate(7, (_) => TextEditingController(text: '09:00'));
  final List<TextEditingController> _calismaBitis =
      List.generate(7, (_) => TextEditingController(text: '18:00'));
  final List<bool> _calismaAcik = List.generate(7, (_) => true);

  final List<TextEditingController> _molaBaslangic =
      List.generate(7, (_) => TextEditingController(text: '13:00'));
  final List<TextEditingController> _molaBitis =
      List.generate(7, (_) => TextEditingController(text: '14:00'));
  final List<bool> _molaAcik = List.generate(7, (_) => false);

  @override
  void initState() {
    super.initState();
    _calismaAcik[5] = false;
    _calismaAcik[6] = false;
    _fetchData();
  }

  Future<void> _fetchData() async {
    seciliisletme = await secilisalonid();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    cihazadi.dispose();
    for (final c in _calismaBaslangic) {
      c.dispose();
    }
    for (final c in _calismaBitis) {
      c.dispose();
    }
    for (final c in _molaBaslangic) {
      c.dispose();
    }
    for (final c in _molaBitis) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _showTimePicker(TextEditingController controller) async {
    TimeOfDay initial = const TimeOfDay(hour: 9, minute: 0);
    if (controller.text.isNotEmpty) {
      try {
        final parts = controller.text.split(':');
        if (parts.length == 2) {
          initial = TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
        }
      } catch (_) {}
    }

    final result = await showModalBottomSheet<TimeOfDay>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _ModernTimePicker(initial: initial),
    );

    if (result != null) {
      setState(() {
        controller.text =
            '${result.hour.toString().padLeft(2, '0')}:${result.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  void _kaydet() {
    final ad = cihazadi.text.trim();
    if (ad.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cihaz adı boş olamaz'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (seciliisletme == null) return;

    setState(() => _kaydediliyor = true);
    widget.cihazdatasource.cihazekle(
      ad,
      seciliisletme!,
      _calismaAcik[0],
      _calismaAcik[1],
      _calismaAcik[2],
      _calismaAcik[3],
      _calismaAcik[4],
      _calismaAcik[5],
      _calismaAcik[6],
      _calismaBaslangic[0].text,
      _calismaBaslangic[1].text,
      _calismaBaslangic[2].text,
      _calismaBaslangic[3].text,
      _calismaBaslangic[4].text,
      _calismaBaslangic[5].text,
      _calismaBaslangic[6].text,
      _calismaBitis[0].text,
      _calismaBitis[1].text,
      _calismaBitis[2].text,
      _calismaBitis[3].text,
      _calismaBitis[4].text,
      _calismaBitis[5].text,
      _calismaBitis[6].text,
      _molaAcik[0],
      _molaAcik[1],
      _molaAcik[2],
      _molaAcik[3],
      _molaAcik[4],
      _molaAcik[5],
      _molaAcik[6],
      _molaBaslangic[0].text,
      _molaBaslangic[1].text,
      _molaBaslangic[2].text,
      _molaBaslangic[3].text,
      _molaBaslangic[4].text,
      _molaBaslangic[5].text,
      _molaBaslangic[6].text,
      _molaBitis[0].text,
      _molaBitis[1].text,
      _molaBitis[2].text,
      _molaBitis[3].text,
      _molaBitis[4].text,
      _molaBitis[5].text,
      _molaBitis[6].text,
      context,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FC),
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
            'Yeni Cihaz',
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
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                child: SizedBox(
                  width: 100,
                  child: YukseltButonu(isletme_bilgi: widget.isletmebilgi),
                ),
              ),
            const SizedBox(width: 6),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: Colors.black12),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderBanner(),
                      const SizedBox(height: 14),
                      _buildCihazAdiCard(),
                      const SizedBox(height: 14),
                      _buildSaatlerCard(
                        title: 'Çalışma Saatleri',
                        icon: Icons.schedule_rounded,
                        baslangic: _calismaBaslangic,
                        bitis: _calismaBitis,
                        acik: _calismaAcik,
                        toggleColor: const Color(0xFF16A34A),
                        hint: 'Cihazın hizmet verdiği saatler',
                      ),
                      const SizedBox(height: 14),
                      _buildSaatlerCard(
                        title: 'Mola Saatleri',
                        icon: Icons.coffee_rounded,
                        baslangic: _molaBaslangic,
                        bitis: _molaBitis,
                        acik: _molaAcik,
                        toggleColor: const Color(0xFFD97706),
                        hint: 'Çalışma saatleri içindeki ara dilimleri',
                      ),
                    ],
                  ),
                ),
              ),
              _buildKaydetBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderBanner() {
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
            child: const Icon(Icons.devices_other_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Yeni Cihaz Tanımla',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Adını yaz, çalışma ve mola saatlerini belirle.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCihazAdiCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _accent.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: 0.05),
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
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.label_outline_rounded,
                    color: _accent, size: 16),
              ),
              const SizedBox(width: 8),
              const Text(
                'Cihaz Adı',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _accent.withValues(alpha: 0.15)),
            ),
            child: TextField(
              controller: cihazadi,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'Örn: 1 Nolu Tırnak Standı',
                hintStyle: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaatlerCard({
    required String title,
    required IconData icon,
    required List<TextEditingController> baslangic,
    required List<TextEditingController> bitis,
    required List<bool> acik,
    required Color toggleColor,
    required String hint,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _accent.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: _accent, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hint,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          for (int i = 0; i < 7; i++)
            _buildGunRow(
              dayName: _gunler[i],
              acik: acik[i],
              onToggle: (v) => setState(() => acik[i] = v),
              baslangic: baslangic[i],
              bitis: bitis[i],
              toggleColor: toggleColor,
              divider: i < 6,
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildGunRow({
    required String dayName,
    required bool acik,
    required ValueChanged<bool> onToggle,
    required TextEditingController baslangic,
    required TextEditingController bitis,
    required Color toggleColor,
    required bool divider,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
          child: Row(
            children: [
              SizedBox(
                width: 90,
                child: Row(
                  children: [
                    _MiniSwitch(
                      value: acik,
                      activeColor: toggleColor,
                      onChanged: onToggle,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        dayName,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: acik ? Colors.black87 : Colors.grey[500],
                          letterSpacing: -0.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildTimePill(
                  controller: baslangic,
                  enabled: acik,
                  label: 'Başlangıç',
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                  color: acik ? Colors.grey[500] : Colors.grey[300],
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildTimePill(
                  controller: bitis,
                  enabled: acik,
                  label: 'Bitiş',
                ),
              ),
            ],
          ),
        ),
        if (divider)
          Divider(height: 1, color: Colors.grey[200]),
      ],
    );
  }

  Widget _buildTimePill({
    required TextEditingController controller,
    required bool enabled,
    required String label,
  }) {
    final color = enabled ? _accent : Colors.grey[400]!;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: enabled ? () => _showTimePicker(controller) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: enabled
                ? _accent.withValues(alpha: 0.06)
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: enabled
                  ? _accent.withValues(alpha: 0.15)
                  : Colors.grey[200]!,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.access_time_rounded, size: 13, color: color),
              const SizedBox(width: 5),
              Text(
                controller.text.isEmpty ? label : controller.text,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: enabled ? Colors.black87 : Colors.grey[500],
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKaydetBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        14,
        12,
        14,
        12 + MediaQuery.of(context).viewPadding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        height: 50,
        width: double.infinity,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: _kaydediliyor ? null : _kaydet,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_accentLight, _accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: _accent.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: _kaydediliyor
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.4,
                      ),
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline_rounded,
                            color: Colors.white, size: 19),
                        SizedBox(width: 8),
                        Text(
                          'Cihazı Kaydet',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
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
}

class _MiniSwitch extends StatelessWidget {
  final bool value;
  final Color activeColor;
  final ValueChanged<bool> onChanged;
  const _MiniSwitch({
    required this.value,
    required this.activeColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 32,
        height: 18,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: value ? activeColor : Colors.grey[300],
          borderRadius: BorderRadius.circular(999),
        ),
        child: Align(
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 14,
            height: 14,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

class _ModernTimePicker extends StatefulWidget {
  final TimeOfDay initial;
  const _ModernTimePicker({required this.initial});

  @override
  State<_ModernTimePicker> createState() => _ModernTimePickerState();
}

class _ModernTimePickerState extends State<_ModernTimePicker> {
  static const Color _accent = Color(0xFF4F46E5);

  late int _hour;
  late int _minute;
  late FixedExtentScrollController _hourCtrl;
  late FixedExtentScrollController _minuteCtrl;

  int _getMinuteFromIndex(int index) {
    switch (index) {
      case 0:
        return 0;
      case 1:
        return 15;
      case 2:
        return 30;
      case 3:
        return 45;
      default:
        return 0;
    }
  }

  int _getQuarterIndex(int minute) {
    if (minute < 8) return 0;
    if (minute < 23) return 1;
    if (minute < 38) return 2;
    if (minute < 53) return 3;
    return 0;
  }

  @override
  void initState() {
    super.initState();
    _hour = widget.initial.hour;
    _minute = _getMinuteFromIndex(_getQuarterIndex(widget.initial.minute));
    _hourCtrl = FixedExtentScrollController(initialItem: _hour);
    _minuteCtrl =
        FixedExtentScrollController(initialItem: _getQuarterIndex(_minute));
  }

  @override
  void dispose() {
    _hourCtrl.dispose();
    _minuteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(26),
          topRight: Radius.circular(26),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 4),
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                  ),
                  child: const Text(
                    'İptal',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const Spacer(),
                const Text(
                  'Saat Seç',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                    letterSpacing: -0.2,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context)
                      .pop(TimeOfDay(hour: _hour, minute: _minute)),
                  style: TextButton.styleFrom(foregroundColor: _accent),
                  child: const Text(
                    'Tamam',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _accent.withValues(alpha: 0.10),
                  _accent.withValues(alpha: 0.04),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Text(
                '${_hour.toString().padLeft(2, '0')} : ${_minute.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: _accent,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 200,
            child: Row(
              children: [
                Expanded(
                  child: ListWheelScrollView.useDelegate(
                    controller: _hourCtrl,
                    itemExtent: 44,
                    perspective: 0.005,
                    diameterRatio: 1.6,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: (i) => setState(() => _hour = i),
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: 24,
                      builder: (context, hour) {
                        final selected = hour == _hour;
                        return Container(
                          alignment: Alignment.center,
                          child: Text(
                            hour.toString().padLeft(2, '0'),
                            style: TextStyle(
                              fontSize: selected ? 22 : 17,
                              fontWeight: selected
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                              color: selected ? _accent : Colors.grey[500],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const Text(
                  ':',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _accent,
                  ),
                ),
                Expanded(
                  child: ListWheelScrollView.useDelegate(
                    controller: _minuteCtrl,
                    itemExtent: 44,
                    perspective: 0.005,
                    diameterRatio: 1.6,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: (i) => setState(
                        () => _minute = _getMinuteFromIndex(i)),
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: 4,
                      builder: (context, i) {
                        final m = _getMinuteFromIndex(i);
                        final selected = m == _minute;
                        return Container(
                          alignment: Alignment.center,
                          child: Text(
                            m.toString().padLeft(2, '0'),
                            style: TextStyle(
                              fontSize: selected ? 22 : 17,
                              fontWeight: selected
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                              color: selected ? _accent : Colors.grey[500],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }
}

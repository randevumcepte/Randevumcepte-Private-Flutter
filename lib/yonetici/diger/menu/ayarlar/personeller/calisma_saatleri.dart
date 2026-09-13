import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Models/isletmecalismasaatleri.dart';
import 'oglen_arasi.dart';

class CalismaSaatleri extends StatefulWidget {
  final dynamic isletmebilgi;
  const CalismaSaatleri({Key? key, required this.isletmebilgi})
      : super(key: key);

  @override
  _CalismaSaatleriState createState() => _CalismaSaatleriState();
}

class _CalismaSaatleriState extends State<CalismaSaatleri> {
  static const Color _accent = Color(0xFF4A6FA5);
  static const Color _accentLight = Color(0xFF6A8BC2);

  String? _seciliisletme;
  bool _isLoading = true;
  bool _isSaving = false;

  // 0..6 → Pazartesi..Pazar
  final List<bool> _active = List.filled(7, false);
  final List<TextEditingController> _startCtrls =
      List.generate(7, (_) => TextEditingController());
  final List<TextEditingController> _endCtrls =
      List.generate(7, (_) => TextEditingController());

  static const List<String> _dayNames = [
    'Pazartesi',
    'Salı',
    'Çarşamba',
    'Perşembe',
    'Cuma',
    'Cumartesi',
    'Pazar',
  ];
  static const List<String> _dayShorts = [
    'Pzt',
    'Sal',
    'Çar',
    'Per',
    'Cum',
    'Cmt',
    'Paz',
  ];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    for (final c in _startCtrls) {
      c.dispose();
    }
    for (final c in _endCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _initialize() async {
    _seciliisletme = await secilisalonid();
    final List<IsletmeCalismaSaatleri> settings =
        await fetchSalonHoursSettings(_seciliisletme!);
    if (!mounted) return;
    setState(() {
      for (final s in settings) {
        final i = s.haftaninGunu - 1;
        if (i < 0 || i > 6) continue;
        _active[i] = s.calisiyor != 0;
        _startCtrls[i].text = s.baslangic;
        _endCtrls[i].text = s.bitis;
      }
      _isLoading = false;
    });
  }

  // ---------- Helpers ----------
  int get _activeCount => _active.where((e) => e).length;

  bool _isWeekend(int i) => i == 5 || i == 6;

  String _dayLabelWithRange(int i) {
    final s = _startCtrls[i].text;
    final e = _endCtrls[i].text;
    if (!_active[i]) return 'Kapalı';
    if (s.isEmpty || e.isEmpty) return 'Saat seçilmedi';
    return '$s – $e';
  }

  // ---------- Quick actions ----------
  void _applyFirstActiveToAll() {
    int src = _active.indexWhere((e) => e);
    if (src < 0) {
      // fallback default
      _setRange(0, '09:00', '18:00');
      src = 0;
      _active[0] = true;
    }
    final s = _startCtrls[src].text;
    final e = _endCtrls[src].text;
    if (s.isEmpty || e.isEmpty) {
      _snack('Önce bir günün saatini ayarlayın.');
      return;
    }
    setState(() {
      for (int i = 0; i < 7; i++) {
        _active[i] = true;
        _startCtrls[i].text = s;
        _endCtrls[i].text = e;
      }
    });
    _snack('Tüm günlere uygulandı.');
  }

  void _toggleWeekendOff() {
    setState(() {
      _active[5] = false;
      _active[6] = false;
    });
  }

  void _setRange(int i, String start, String end) {
    _startCtrls[i].text = start;
    _endCtrls[i].text = end;
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ---------- Time picker (modernized, accent color) ----------
  Future<void> _pickTime(TextEditingController controller) async {
    TimeOfDay initial = TimeOfDay.now();
    if (controller.text.isNotEmpty) {
      try {
        final parts = controller.text.split(':');
        if (parts.length == 2) {
          initial = TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
        }
      } catch (e) {
        log('Saat parse hatası: $e');
      }
    }

    final picked = await showModalBottomSheet<TimeOfDay>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _ModernTimePicker(initial: initial, accent: _accent),
    );

    if (picked != null && mounted) {
      setState(() {
        controller.text =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  // ---------- Save ----------
  Future<void> _save() async {
    if (_isSaving) return;

    // Validation: aktif günlerde saat dolu mu?
    final List<String> missing = [];
    for (int i = 0; i < 7; i++) {
      if (_active[i] &&
          (_startCtrls[i].text.isEmpty || _endCtrls[i].text.isEmpty)) {
        missing.add(_dayNames[i]);
      }
    }
    if (missing.isNotEmpty) {
      _snack('Saat eksik: ${missing.join(", ")}');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await submitform(
        _seciliisletme!,
        _active[0],
        _active[1],
        _active[2],
        _active[3],
        _active[4],
        _active[5],
        _active[6],
        _startCtrls[0].text,
        _startCtrls[1].text,
        _startCtrls[2].text,
        _startCtrls[3].text,
        _startCtrls[4].text,
        _startCtrls[5].text,
        _startCtrls[6].text,
        _endCtrls[0].text,
        _endCtrls[1].text,
        _endCtrls[2].text,
        _endCtrls[3].text,
        _endCtrls[4].text,
        _endCtrls[5].text,
        _endCtrls[6].text,
        context,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ---------- Build ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
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
          'Çalışma Saatleri',
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
          const SizedBox(width: 6),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.black12),
        ),
      ),
      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(color: _accent, strokeWidth: 2.5),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    children: [
                      _buildStatsBanner(),
                      const SizedBox(height: 10),
                      _buildQuickActions(),
                      const SizedBox(height: 14),
                      ...List.generate(7, (i) => _buildDayCard(i)),
                      const SizedBox(height: 12),
                      _buildOglenArasiCard(),
                      const SizedBox(height: 90),
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: _isLoading ? null : _buildSaveBar(),
    );
  }

  // ---------- Components ----------
  Widget _buildStatsBanner() {
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
            child: const Icon(Icons.access_time_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Açık Günler',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$_activeCount',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                        height: 1,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      '/ 7 gün',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.black45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Mini week strip
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(7, (i) {
              final on = _active[i];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 18,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: on
                      ? _accent.withValues(alpha: 0.14)
                      : Colors.grey.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _dayShorts[i].substring(0, 1),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: on ? _accent : Colors.black38,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _quickChip(
            icon: Icons.copy_all_rounded,
            label: 'Tüm günlere uygula',
            onTap: _applyFirstActiveToAll,
          ),
          const SizedBox(width: 8),
          _quickChip(
            icon: Icons.weekend_rounded,
            label: 'Hafta sonu kapalı',
            onTap: _toggleWeekendOff,
          ),
          const SizedBox(width: 8),
          _quickChip(
            icon: Icons.refresh_rounded,
            label: '09:00–18:00',
            onTap: () {
              setState(() {
                for (int i = 0; i < 7; i++) {
                  _setRange(i, '09:00', '18:00');
                  if (!_isWeekend(i)) _active[i] = true;
                }
              });
            },
          ),
          const SizedBox(width: 8),
          _quickChip(
            icon: Icons.power_settings_new_rounded,
            label: 'Hepsini kapat',
            onTap: () => setState(() {
              for (int i = 0; i < 7; i++) {
                _active[i] = false;
              }
            }),
          ),
        ],
      ),
    );
  }

  Widget _quickChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: _accent.withValues(alpha: 0.18),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: _accent),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _accent,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDayCard(int i) {
    final on = _active[i];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: on
              ? _accent.withValues(alpha: 0.20)
              : Colors.black.withValues(alpha: 0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: on ? 0.07 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // Day badge
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: on
                        ? const LinearGradient(
                            colors: [_accentLight, _accent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: on ? null : const Color(0xFFEFF1F5),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Text(
                    _dayShorts[i],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: on ? Colors.white : Colors.black45,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _dayNames[i],
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                          color: Colors.black87,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _dayLabelWithRange(i),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: on ? _accent : Colors.black38,
                        ),
                      ),
                    ],
                  ),
                ),
                // Switch
                Transform.scale(
                  scale: 0.85,
                  child: Switch(
                    value: on,
                    activeThumbColor: Colors.white,
                    activeTrackColor: _accent,
                    inactiveTrackColor: const Color(0xFFE4E7EE),
                    inactiveThumbColor: Colors.white,
                    materialTapTargetSize:
                        MaterialTapTargetSize.shrinkWrap,
                    onChanged: (v) {
                      setState(() {
                        _active[i] = v;
                        // İlk açılıyorsa default saatleri öner
                        if (v &&
                            (_startCtrls[i].text.isEmpty ||
                                _endCtrls[i].text.isEmpty)) {
                          _setRange(i, '09:00', '18:00');
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
            // Time chips (sadece açıkken görünür)
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: on
                  ? Padding(
                      padding: const EdgeInsets.only(top: 10, left: 2, right: 2),
                      child: Row(
                        children: [
                          Expanded(
                            child: _timeChip(
                              label: 'Başlangıç',
                              controller: _startCtrls[i],
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8),
                            child: Container(
                              width: 14,
                              height: 1.5,
                              color: _accent.withValues(alpha: 0.3),
                            ),
                          ),
                          Expanded(
                            child: _timeChip(
                              label: 'Bitiş',
                              controller: _endCtrls[i],
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeChip({
    required String label,
    required TextEditingController controller,
  }) {
    final hasValue = controller.text.isNotEmpty;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _pickTime(controller),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _accent.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _accent.withValues(alpha: 0.18),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.schedule_rounded, size: 16, color: _accent),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.black45,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      hasValue ? controller.text : '— : —',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: hasValue ? Colors.black87 : Colors.black26,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOglenArasiCard() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  OglenArasi(isletmebilgi: widget.isletmebilgi),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFFFB74D).withValues(alpha: 0.30),
              width: 1,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                const Color(0xFFFFF8E1).withValues(alpha: 0.55),
              ],
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFCC80), Color(0xFFFFA726)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(
                      color:
                          const Color(0xFFFFA726).withValues(alpha: 0.30),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.lunch_dining_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'Öğlen Arası Saatleri',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                        color: Colors.black87,
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Mola saatlerinizi buradan yönetin',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFA726).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: Color(0xFFFB8C00),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSaveBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SizedBox(
          height: 50,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _accent.withValues(alpha: 0.5),
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
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
                    children: [
                      Icon(Icons.check_rounded, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Kaydet',
                        style: TextStyle(
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
    );
  }
}

// ---------- Modern Time Picker (themed) ----------
class _ModernTimePicker extends StatefulWidget {
  final TimeOfDay initial;
  final Color accent;
  const _ModernTimePicker({required this.initial, required this.accent});

  @override
  State<_ModernTimePicker> createState() => _ModernTimePickerState();
}

class _ModernTimePickerState extends State<_ModernTimePicker> {
  late int _hour;
  late int _minute;

  static int _nearestQuarter(int m) {
    if (m < 8) return 0;
    if (m < 23) return 15;
    if (m < 38) return 30;
    if (m < 53) return 45;
    return 0;
  }

  static int _minuteFromIndex(int i) {
    switch (i) {
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

  static int _indexFromMinute(int m) {
    switch (m) {
      case 0:
        return 0;
      case 15:
        return 1;
      case 30:
        return 2;
      case 45:
        return 3;
      default:
        return 0;
    }
  }

  late final FixedExtentScrollController _hourCtrl;
  late final FixedExtentScrollController _minuteCtrl;

  @override
  void initState() {
    super.initState();
    _hour = widget.initial.hour;
    _minute = _nearestQuarter(widget.initial.minute);
    _hourCtrl = FixedExtentScrollController(initialItem: _hour);
    _minuteCtrl =
        FixedExtentScrollController(initialItem: _indexFromMinute(_minute));
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
      height: MediaQuery.of(context).size.height * 0.55,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'İptal',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Text(
                  'Saat Seç',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                    letterSpacing: -0.2,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context)
                        .pop(TimeOfDay(hour: _hour, minute: _minute));
                  },
                  child: Text(
                    'Tamam',
                    style: TextStyle(
                      color: widget.accent,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Big preview
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  widget.accent.withValues(alpha: 0.10),
                  widget.accent.withValues(alpha: 0.04),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.accent.withValues(alpha: 0.18),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                '${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  color: widget.accent,
                  letterSpacing: -1,
                ),
              ),
            ),
          ),
          // Wheels
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _wheel(
                    controller: _hourCtrl,
                    itemCount: 24,
                    selectedIndex: _hour,
                    builder: (i) => i.toString().padLeft(2, '0'),
                    onChanged: (i) => setState(() => _hour = i),
                  ),
                ),
                Text(
                  ':',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: widget.accent,
                  ),
                ),
                Expanded(
                  child: _wheel(
                    controller: _minuteCtrl,
                    itemCount: 4,
                    selectedIndex: _indexFromMinute(_minute),
                    builder: (i) => _minuteFromIndex(i).toString().padLeft(2, '0'),
                    onChanged: (i) =>
                        setState(() => _minute = _minuteFromIndex(i)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _wheel({
    required FixedExtentScrollController controller,
    required int itemCount,
    required int selectedIndex,
    required String Function(int) builder,
    required ValueChanged<int> onChanged,
  }) {
    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: 48,
      perspective: 0.005,
      diameterRatio: 1.5,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: onChanged,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: itemCount,
        builder: (context, index) {
          final isSelected = index == selectedIndex;
          return Container(
            alignment: Alignment.center,
            child: Text(
              builder(index),
              style: TextStyle(
                fontSize: isSelected ? 22 : 17,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? widget.accent : Colors.grey[500],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------- API (preserved) ----------
Future<void> submitform(
  String salonId,
  calisiyor1,
  calisiyor2,
  calisiyor3,
  calisiyor4,
  calisiyor5,
  calisiyor6,
  calisiyor7,
  String baslangic1,
  String baslangic2,
  String baslangic3,
  String baslangic4,
  String baslangic5,
  String baslangic6,
  String baslangic7,
  String bitis1,
  String bitis2,
  String bitis3,
  String bitis4,
  String bitis5,
  String bitis6,
  String bitis7,
  BuildContext context,
) async {
  final Map<String, dynamic> formData = {
    'isletme_id': salonId,
    'calisiyor1': calisiyor1 == true ? 1 : 0,
    'calisiyor2': calisiyor2 == true ? 1 : 0,
    'calisiyor3': calisiyor3 == true ? 1 : 0,
    'calisiyor4': calisiyor4 == true ? 1 : 0,
    'calisiyor5': calisiyor5 == true ? 1 : 0,
    'calisiyor6': calisiyor6 == true ? 1 : 0,
    'calisiyor7': calisiyor7 == true ? 1 : 0,
    'calismasaatibaslangic1': baslangic1,
    'calismasaatibaslangic2': baslangic2,
    'calismasaatibaslangic3': baslangic3,
    'calismasaatibaslangic4': baslangic4,
    'calismasaatibaslangic5': baslangic5,
    'calismasaatibaslangic6': baslangic6,
    'calismasaatibaslangic7': baslangic7,
    'calismasaatibisis1': bitis1,
    'calismasaatibisis2': bitis2,
    'calismasaatibisis3': bitis3,
    'calismasaatibisis4': bitis4,
    'calismasaatibisis5': bitis5,
    'calismasaatibisis6': bitis6,
    'calismasaatibisis7': bitis7,
  };

  final queryParameters =
      formData.entries.map((e) => '${e.key}=${e.value}').join('&');

  final response = await http.get(
    Uri.parse(
        'https://app.randevumcepte.com.tr/api/v1/calisma_saati_guncelle_ekle/$salonId?$queryParameters'),
    headers: {'Content-Type': 'application/json'},
  );

  debugPrint('Response status: ${response.statusCode}');
  debugPrint('Response body: ${response.body}');

  if (response.statusCode == 200) {
    log('etkinlik güncelleme : ${response.body}');
    if (!context.mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Çalışma saatleri güncellendi'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  } else {
    debugPrint('Failed to load data. Status code: ${response.statusCode}');
    throw Exception('Failed to load data: ${response.reasonPhrase}');
  }
}

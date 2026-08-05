import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RandevuAyarlari extends StatefulWidget {
  final dynamic isletmebilgi;
  const RandevuAyarlari({super.key, required this.isletmebilgi});

  @override
  State<RandevuAyarlari> createState() => _RandevuAyarlariState();
}

class _RandevuAyarlariState extends State<RandevuAyarlari> {
  static const Color _accent = Color(0xFF4CAF93);
  static const Color _bg = Color(0xFFF7F9F8);

  final List<_AralikOption> _araliklar = const [
    _AralikOption(id: '15', dk: 15, baslik: '15 dk', altyazi: 'Çok kısa randevular'),
    _AralikOption(id: '30', dk: 30, baslik: '30 dk', altyazi: 'Kısa hizmetler'),
    _AralikOption(id: '45', dk: 45, baslik: '45 dk', altyazi: 'Orta süreli'),
    _AralikOption(id: '60', dk: 60, baslik: '60 dk', altyazi: 'Standart'),
    _AralikOption(id: '90', dk: 90, baslik: '90 dk', altyazi: 'Uzun seanslar'),
    _AralikOption(id: '120', dk: 120, baslik: '120 dk', altyazi: 'Çok uzun'),
  ];

  final List<_TakvimOption> _takvimler = const [
    _TakvimOption(
      id: '1',
      baslik: 'Personele Göre',
      altyazi: 'Her personel için ayrı sütun',
      icon: Icons.person_rounded,
      color: Color(0xFF6366F1),
    ),
    _TakvimOption(
      id: '0',
      baslik: 'Hizmet Kategorisine Göre',
      altyazi: 'Kategoriye göre sütun ayrımı',
      icon: Icons.spa_rounded,
      color: Color(0xFFF59E0B),
    ),
    _TakvimOption(
      id: '2',
      baslik: 'Cihaza Göre',
      altyazi: 'Her cihaz için ayrı sütun',
      icon: Icons.devices_other_rounded,
      color: Color(0xFF06B6D4),
    ),
    _TakvimOption(
      id: '3',
      baslik: 'Sınıfa Göre',
      altyazi: 'Sınıf bazlı takvim görünümü',
      icon: Icons.meeting_room_rounded,
      color: Color(0xFFEC4899),
    ),
  ];

  String? _aralikId;
  String? _takvimId;
  bool _onlineRandevuAktif = false;
  bool _gecmisRandevulariGizle = false;
  String? _seciliisletme;
  bool _isLoading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _seciliisletme = await secilisalonid();
    final settings = await fetchSalonSettings(_seciliisletme ?? '');
    if (!mounted) return;
    final ar = settings['randevu_saat_araligi']?.toString();
    final tk = settings['randevu_takvim_turu']?.toString();
    setState(() {
      _aralikId = _araliklar.any((e) => e.id == ar) ? ar : '60';
      _takvimId = _takvimler.any((e) => e.id == tk) ? tk : '1';
      _onlineRandevuAktif =
          settings['musteri_online_randevu_aktif']?.toString() == '1';
      _gecmisRandevulariGizle =
          settings['gecmis_randevulari_gizle']?.toString() == '1';
      _isLoading = false;
    });
  }

  Future<void> _kaydet() async {
    if (_aralikId == null || _takvimId == null || _seciliisletme == null) return;
    setState(() => _saving = true);
    HapticFeedback.mediumImpact();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final response = await http.post(
        Uri.parse('https://app.randevumcepte.com.tr/api/v1/randevuayarguncelle'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'randevu_saat_araligi': _aralikId,
          'randevu_takvim_turu': _takvimId,
          'musteri_online_randevu_aktif': _onlineRandevuAktif ? '1' : '0',
          'gecmis_randevulari_gizle': _gecmisRandevulariGizle ? '1' : '0',
          'salon_id': _seciliisletme,
        }),
      );
      log('Randevu ayar guncelle: ${response.statusCode} ${response.body}');
      if (!mounted) return;
      if (response.statusCode == 200) {
        await SharedPreferences.getInstance();
        if (!mounted) return;
        navigator.pop();
        messenger.showSnackBar(
          SnackBar(
            content: const Text('Online randevu ayarları güncellendi'),
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(14),
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
          'Online Randevu Ayarları',
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
              child: CircularProgressIndicator(
                color: _accent,
                strokeWidth: 2.5,
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 110),
              children: [
                _buildHero(),
                const SizedBox(height: 18),
                _buildSectionHeader(
                  icon: Icons.timer_outlined,
                  title: 'Randevu Aralığı',
                  subtitle:
                      'Takvimde zaman dilimleri kaç dakikalık parçalara bölünsün?',
                ),
                const SizedBox(height: 10),
                _buildAralikGrid(),
                const SizedBox(height: 22),
                _buildSectionHeader(
                  icon: Icons.calendar_month_rounded,
                  title: 'Takvim Görünümü',
                  subtitle:
                      'Randevular hangi başlığa göre sütunlara ayrılsın?',
                ),
                const SizedBox(height: 10),
                _buildTakvimList(),
                const SizedBox(height: 22),
                _buildSectionHeader(
                  icon: Icons.tune_rounded,
                  title: 'Online Randevu',
                  subtitle: 'Müşteri randevu davranışını yönetin.',
                ),
                const SizedBox(height: 10),
                _buildToggleCard(
                  icon: Icons.event_available_rounded,
                  color: const Color(0xFF16A34A),
                  title: 'Müşteri online randevu alabilsin',
                  subtitle:
                      'Bu seçenek açıkken müşteriler mobil/web üzerinden kendileri randevu oluşturabilir.',
                  value: _onlineRandevuAktif,
                  onChanged: (v) {
                    HapticFeedback.selectionClick();
                    setState(() => _onlineRandevuAktif = v);
                  },
                ),
                const SizedBox(height: 8),
                _buildToggleCard(
                  icon: Icons.history_toggle_off_rounded,
                  color: const Color(0xFFD97706),
                  title: 'Saati geçen randevular görünmesin',
                  subtitle:
                      'Açıkken saati geçmiş randevular takvim, liste ve müşteri kartında gizlenir. Yalnızca web sürümündeki (randevu.randevumcepte.com.tr) girişlerde geçerlidir.',
                  value: _gecmisRandevulariGizle,
                  onChanged: (v) {
                    HapticFeedback.selectionClick();
                    setState(() => _gecmisRandevulariGizle = v);
                  },
                ),
              ],
            ),
      bottomNavigationBar: _isLoading ? null : _buildSaveBar(),
    );
  }

  Widget _buildHero() {
    final secili = _araliklar.firstWhere(
      (e) => e.id == _aralikId,
      orElse: () => _araliklar.first,
    );
    final takvim = _takvimler.firstWhere(
      (e) => e.id == _takvimId,
      orElse: () => _takvimler.first,
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6FC8B1), Color(0xFF4CAF93)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _accent.withValues(alpha: 0.30),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(Icons.event_available_rounded,
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Randevu Davranışı',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Colors.black54,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${secili.baslik} • ${takvim.baslik}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    color: Colors.black87,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: _accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAralikGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 10.0;
        final w = (constraints.maxWidth - spacing * 2) / 3;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: _araliklar.map((opt) {
            final selected = opt.id == _aralikId;
            return SizedBox(
              width: w,
              child: _AralikCard(
                option: opt,
                selected: selected,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _aralikId = opt.id);
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildTakvimList() {
    return Column(
      children: [
        for (int i = 0; i < _takvimler.length; i++) ...[
          _TakvimCard(
            option: _takvimler[i],
            selected: _takvimler[i].id == _takvimId,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _takvimId = _takvimler[i].id);
            },
          ),
          if (i != _takvimler.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildToggleCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: value ? color : color.withValues(alpha: 0.10),
              width: value ? 1.6 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: value
                    ? color.withValues(alpha: 0.18)
                    : color.withValues(alpha: 0.04),
                blurRadius: value ? 12 : 6,
                offset: Offset(0, value ? 5 : 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: value
                        ? [color, color.withValues(alpha: 0.75)]
                        : [
                            color.withValues(alpha: 0.18),
                            color.withValues(alpha: 0.10),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: value
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.30),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  icon,
                  color: value ? Colors.white : color,
                  size: 22,
                ),
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
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Switch.adaptive(
                value: value,
                onChanged: onChanged,
                activeThumbColor: color,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSaveBar() {
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
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _saving ? null : _kaydet,
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _saving
                    ? [
                        _accent.withValues(alpha: 0.55),
                        _accent.withValues(alpha: 0.45),
                      ]
                    : const [Color(0xFF6FC8B1), Color(0xFF4CAF93)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: _saving
                  ? []
                  : [
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
              child: _saving
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
                            color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Ayarları Kaydet',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
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

class _AralikOption {
  final String id;
  final int dk;
  final String baslik;
  final String altyazi;
  const _AralikOption({
    required this.id,
    required this.dk,
    required this.baslik,
    required this.altyazi,
  });
}

class _TakvimOption {
  final String id;
  final String baslik;
  final String altyazi;
  final IconData icon;
  final Color color;
  const _TakvimOption({
    required this.id,
    required this.baslik,
    required this.altyazi,
    required this.icon,
    required this.color,
  });
}

class _AralikCard extends StatelessWidget {
  final _AralikOption option;
  final bool selected;
  final VoidCallback onTap;
  const _AralikCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  static const Color _accent = _RandevuAyarlariState._accent;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: selected ? _accent : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? _accent
                  : _accent.withValues(alpha: 0.15),
              width: 1.2,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: _accent.withValues(alpha: 0.30),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: _accent.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${option.dk}',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: selected ? Colors.white : Colors.black87,
                  height: 1,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'dakika',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? Colors.white.withValues(alpha: 0.9)
                      : Colors.black54,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                option.altyazi,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? Colors.white.withValues(alpha: 0.85)
                      : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TakvimCard extends StatelessWidget {
  final _TakvimOption option;
  final bool selected;
  final VoidCallback onTap;
  const _TakvimCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? option.color
                  : option.color.withValues(alpha: 0.10),
              width: selected ? 1.6 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: selected
                    ? option.color.withValues(alpha: 0.18)
                    : option.color.withValues(alpha: 0.04),
                blurRadius: selected ? 12 : 6,
                offset: Offset(0, selected ? 5 : 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: selected
                        ? [
                            option.color,
                            option.color.withValues(alpha: 0.75),
                          ]
                        : [
                            option.color.withValues(alpha: 0.18),
                            option.color.withValues(alpha: 0.10),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: option.color.withValues(alpha: 0.30),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  option.icon,
                  color: selected ? Colors.white : option.color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      option.baslik,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      option.altyazi,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: selected ? option.color : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected
                        ? option.color
                        : Colors.grey.withValues(alpha: 0.35),
                    width: 1.6,
                  ),
                ),
                child: selected
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 16)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

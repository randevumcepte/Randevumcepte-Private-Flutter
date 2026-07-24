import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';

/// Salon sahibinin online randevuya AÇIK saatleri kürasyonu (web ile birebir).
/// - Ana anahtar: kısıtlama açıkken yalnız işaretlenen slotlar müşteriye "boş" gösterilir.
/// - Haftalık: her günün çalışma saatleri slot slot; tıklayarak açık/kapalı.
/// - Günlük limit (seyreltme) + tarihe özel istisna (kapalı / özel aralık).
class OnlineRandevuSaatleri extends StatefulWidget {
  final dynamic isletmebilgi;
  const OnlineRandevuSaatleri({super.key, required this.isletmebilgi});

  @override
  State<OnlineRandevuSaatleri> createState() => _OnlineRandevuSaatleriState();
}

class _OnlineRandevuSaatleriState extends State<OnlineRandevuSaatleri> {
  static const Color _accent = Color(0xFF7B2FB8);
  static const Color _accentDark = Color(0xFF5C008E);
  static const Color _bg = Color(0xFFF7F7FB);
  static const Color _closedBg = Color(0xFFF1F2F6);
  static const Color _closedBorder = Color(0xFFE6E8EE);
  static const Color _closedText = Color(0xFFAEB2BD);

  bool _isLoading = true;
  bool _saving = false;
  bool _hata = false;

  String? _salonId;
  bool _kisitlama = false;
  final TextEditingController _limitCtrl = TextEditingController();

  final List<_GunModel> _gunler = [];
  final List<_Istisna> _istisnalar = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _limitCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      _salonId = await secilisalonid();
      final response = await http.get(
        Uri.parse(
            'https://app.randevumcepte.com.tr/api/v1/online_randevu_saatleri/${_salonId ?? ''}'),
        headers: {'Content-Type': 'application/json'},
      );
      if (!mounted) return;
      if (response.statusCode != 200) {
        setState(() {
          _isLoading = false;
          _hata = true;
        });
        return;
      }
      final data = json.decode(response.body) as Map<String, dynamic>;
      _kisitlama = (data['kisitlama_aktif'] ?? 0).toString() == '1';
      final limit = data['gunluk_limit'];
      _limitCtrl.text = (limit == null || limit.toString() == '0' || limit.toString() == 'null')
          ? ''
          : limit.toString();

      _gunler.clear();
      for (final g in (data['gunler'] as List? ?? [])) {
        final slots = ((g['slots'] as List?) ?? []).map((e) => e.toString()).toList();
        final yapilandirildi = g['yapilandirildi'] == true;
        final Set<String> acik;
        if (yapilandirildi) {
          acik = ((g['acik'] as List?) ?? []).map((e) => e.toString()).toSet();
        } else {
          // Hiç kaydedilmemiş gün: web ile aynı -> varsayılan hepsi açık
          acik = slots.toSet();
        }
        _gunler.add(_GunModel(
          gun: int.tryParse(g['gun'].toString()) ?? 0,
          ad: g['gun_adi']?.toString() ?? '',
          calisiyor: g['calisiyor'] == true,
          slots: slots,
          acik: acik,
        ));
      }

      _istisnalar.clear();
      for (final i in (data['istisnalar'] as List? ?? [])) {
        _istisnalar.add(_Istisna(
          tarih: i['tarih']?.toString() ?? '',
          tip: (i['tip']?.toString() == 'ozel') ? 'ozel' : 'kapali',
          bas: i['bas']?.toString(),
          bit: i['bit']?.toString(),
        ));
      }

      setState(() => _isLoading = false);
    } catch (e) {
      log('Online saat config hata: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hata = true;
      });
    }
  }

  Future<void> _kaydet() async {
    if (_salonId == null) return;
    setState(() => _saving = true);
    HapticFeedback.mediumImpact();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final Map<String, List<String>> gunlerMap = {};
      for (final g in _gunler) {
        final list = g.acik.toList()..sort();
        gunlerMap[g.gun.toString()] = list;
      }
      final istisnaList = _istisnalar.where((e) => e.tarih.isNotEmpty).map((e) {
        final m = <String, dynamic>{'tarih': e.tarih, 'tip': e.tip};
        if (e.tip == 'ozel') {
          m['bas'] = e.bas;
          m['bit'] = e.bit;
        }
        return m;
      }).toList();

      final response = await http.post(
        Uri.parse('https://app.randevumcepte.com.tr/api/v1/online_randevu_saatleri_guncelle'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'salon_id': _salonId,
          'kisitlama_aktif': _kisitlama ? 1 : 0,
          'gunluk_limit': int.tryParse(_limitCtrl.text.trim()) ?? 0,
          'gunler': gunlerMap,
          'istisnalar': istisnaList,
        }),
      );
      log('Online saat kaydet: ${response.statusCode} ${response.body}');
      if (!mounted) return;
      if (response.statusCode == 200) {
        navigator.pop();
        messenger.showSnackBar(_snack('Online randevu saatleri kaydedildi', _accent));
      } else {
        setState(() => _saving = false);
        messenger.showSnackBar(_snack('Hata: ${response.statusCode}', const Color(0xFFDC2626)));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(_snack('Bağlantı hatası: $e', const Color(0xFFDC2626)));
    }
  }

  SnackBar _snack(String msg, Color color) => SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(14),
      );

  String _two(int n) => n < 10 ? '0$n' : '$n';

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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Online Randevu Saatleri',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          if (widget.isletmebilgi is Map &&
              widget.isletmebilgi["demo_hesabi"].toString() == "1")
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
          ? const Center(child: CircularProgressIndicator(color: _accent, strokeWidth: 2.5))
          : _hata
              ? _buildHata()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 110),
                  children: [
                    _buildMasterCard(),
                    const SizedBox(height: 16),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: _kisitlama ? 1 : 0.45,
                      child: IgnorePointer(
                        ignoring: !_kisitlama,
                        child: Column(
                          children: [
                            _buildLimitCard(),
                            const SizedBox(height: 18),
                            _buildLegend(),
                            const SizedBox(height: 10),
                            ..._gunler.map(_buildGunCard),
                            const SizedBox(height: 18),
                            _buildIstisnaSection(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
      bottomNavigationBar: (_isLoading || _hata) ? null : _buildSaveBar(),
    );
  }

  Widget _buildHata() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 48, color: Colors.black26),
              const SizedBox(height: 12),
              const Text('Ayarlar yüklenemedi',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 6),
              Text('Bağlantıyı kontrol edip tekrar deneyin.',
                  style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _hata = false;
                  });
                  _init();
                },
                child: const Text('Tekrar dene'),
              ),
            ],
          ),
        ),
      );

  Widget _buildMasterCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_accentDark, _accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.schedule_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Online açık saatleri ben belirleyeyim',
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(
                  'Kapalıyken tüm boşluklar online görünür. Açtığınızda yalnız işaretlediğiniz saatler müşteriye boş gösterilir; kalanlar dolu görünür. Randevu düşen slotlar zaten otomatik dolu olur.',
                  style: TextStyle(fontSize: 11.5, color: Colors.grey[600], height: 1.35),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _kisitlama,
            activeColor: _accent,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              setState(() => _kisitlama = v);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLimitCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accent.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Günlük en fazla online slot',
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text('Boş = sınırsız. Örn. 3 → günde en çok 3 boşluk gösterilir.',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600], height: 1.3)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 74,
            child: TextField(
              controller: _limitCtrl,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                hintText: '∞',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                filled: true,
                fillColor: _bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _accent.withValues(alpha: 0.15)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _accent.withValues(alpha: 0.15)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _accent, width: 1.4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    Widget dot(Color c, {Gradient? g}) => Container(
          width: 13,
          height: 13,
          decoration: BoxDecoration(
            color: g == null ? c : null,
            gradient: g,
            borderRadius: BorderRadius.circular(4),
          ),
        );
    return Row(
      children: [
        dot(Colors.transparent,
            g: const LinearGradient(colors: [_accentDark, _accent])),
        const SizedBox(width: 6),
        Text('Açık (müşteri seçebilir)',
            style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        const SizedBox(width: 16),
        dot(_closedBg),
        const SizedBox(width: 6),
        Text('Kapalı (dolu görünür)',
            style: TextStyle(fontSize: 12, color: Colors.grey[700])),
      ],
    );
  }

  Widget _buildGunCard(_GunModel g) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEF0F4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(g.ad,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              const Spacer(),
              if (g.calisiyor && g.slots.isNotEmpty) ...[
                Text('${g.acik.length}/${g.slots.length} açık',
                    style: const TextStyle(
                        fontSize: 12, color: _accentDark, fontWeight: FontWeight.w700)),
                const SizedBox(width: 8),
                _miniBtn('Tümü', () {
                  HapticFeedback.selectionClick();
                  setState(() => g.acik = g.slots.toSet());
                }),
                const SizedBox(width: 6),
                _miniBtn('Hiçbiri', () {
                  HapticFeedback.selectionClick();
                  setState(() => g.acik = <String>{});
                }),
              ],
            ],
          ),
          const SizedBox(height: 12),
          if (!g.calisiyor)
            Text('Bu gün salon kapalı — "Çalışma Saatleri"nden ayarlanır.',
                style: TextStyle(
                    fontSize: 12.5, color: Colors.grey[500], fontStyle: FontStyle.italic))
          else if (g.slots.isEmpty)
            Text('Çalışma saati aralığı geçersiz.',
                style: TextStyle(fontSize: 12.5, color: Colors.grey[500]))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: g.slots.map((s) => _slotChip(g, s)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _slotChip(_GunModel g, String s) {
    final acik = g.acik.contains(s);
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          if (acik) {
            g.acik.remove(s);
          } else {
            g.acik.add(s);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          gradient: acik ? const LinearGradient(colors: [_accentDark, _accent]) : null,
          color: acik ? null : _closedBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: acik ? Colors.transparent : _closedBorder),
          boxShadow: acik
              ? [
                  BoxShadow(
                    color: _accent.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          s,
          style: TextStyle(
            color: acik ? Colors.white : _closedText,
            fontWeight: FontWeight.w700,
            fontSize: 12.5,
            decoration: acik ? null : TextDecoration.lineThrough,
          ),
        ),
      ),
    );
  }

  Widget _miniBtn(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _accent.withValues(alpha: 0.25)),
        ),
        child: Text(label,
            style: const TextStyle(
                fontSize: 12, color: _accent, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildIstisnaSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEF0F4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tarihe Özel İstisnalar',
              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text('Belirli bir günü tamamen kapatın ya da o güne özel aralık açın. Haftalık kuralı ezer.',
              style: TextStyle(fontSize: 11.5, color: Colors.grey[600], height: 1.3)),
          const SizedBox(height: 10),
          ..._istisnalar.asMap().entries.map((e) => _buildIstisnaRow(e.key, e.value)),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _istisnalar.add(_Istisna(tarih: '', tip: 'kapali')));
            },
            child: Row(
              children: const [
                Icon(Icons.add_circle_outline_rounded, size: 18, color: _accent),
                SizedBox(width: 6),
                Text('İstisna ekle',
                    style: TextStyle(
                        color: _accent, fontWeight: FontWeight.w700, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIstisnaRow(int index, _Istisna e) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEF0F4)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: now,
                      firstDate: now,
                      lastDate: now.add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() => e.tarih =
                          '${picked.year}-${_two(picked.month)}-${_two(picked.day)}');
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE6E8EE)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 15, color: _accent),
                        const SizedBox(width: 8),
                        Text(e.tarih.isEmpty ? 'Tarih seç' : e.tarih,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: e.tarih.isEmpty ? Colors.grey[500] : Colors.black87)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _istisnalar.removeAt(index));
                },
                child: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.delete_outline_rounded,
                      size: 18, color: Color(0xFFDC2626)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _tipToggle(e),
              ),
            ],
          ),
          if (e.tip == 'ozel') ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _timeField(e, true)),
                const SizedBox(width: 8),
                Expanded(child: _timeField(e, false)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _tipToggle(_Istisna e) {
    Widget seg(String val, String label) {
      final sel = e.tip == val;
      return Expanded(
        child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => e.tip = val);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 9),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: sel ? _accent : Colors.white,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                  color: sel ? _accent : const Color(0xFFE6E8EE), width: 1),
            ),
            child: Text(label,
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: sel ? Colors.white : Colors.black54)),
          ),
        ),
      );
    }

    return Row(
      children: [
        seg('kapali', 'Kapalı'),
        const SizedBox(width: 8),
        seg('ozel', 'Özel aralık'),
      ],
    );
  }

  Widget _timeField(_Istisna e, bool baslangic) {
    final val = baslangic ? e.bas : e.bit;
    return GestureDetector(
      onTap: () async {
        final parts = (val ?? (baslangic ? '09:00' : '18:00')).split(':');
        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(
            hour: int.tryParse(parts[0]) ?? 9,
            minute: parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0,
          ),
        );
        if (picked != null) {
          final s = '${_two(picked.hour)}:${_two(picked.minute)}';
          setState(() {
            if (baslangic) {
              e.bas = s;
            } else {
              e.bit = s;
            }
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE6E8EE)),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time_rounded, size: 15, color: _accent),
            const SizedBox(width: 8),
            Text(val ?? (baslangic ? 'Başlangıç' : 'Bitiş'),
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: val == null ? Colors.grey[500] : Colors.black87)),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          14, 12, 14, 12 + MediaQuery.of(context).viewPadding.bottom),
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
                    ? [_accent.withValues(alpha: 0.55), _accent.withValues(alpha: 0.45)]
                    : const [_accentDark, _accent],
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
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4),
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text('Kaydet',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2)),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GunModel {
  final int gun;
  final String ad;
  final bool calisiyor;
  final List<String> slots;
  Set<String> acik;
  _GunModel({
    required this.gun,
    required this.ad,
    required this.calisiyor,
    required this.slots,
    required this.acik,
  });
}

class _Istisna {
  String tarih;
  String tip; // 'kapali' | 'ozel'
  String? bas;
  String? bit;
  _Istisna({required this.tarih, required this.tip, this.bas, this.bit});
}

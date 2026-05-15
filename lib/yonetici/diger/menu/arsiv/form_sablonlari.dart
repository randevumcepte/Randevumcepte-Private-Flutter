import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:page_transition/page_transition.dart';
import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/theme/premium_components.dart';
import 'form_sablon_duzenle.dart';

class FormSablonlari extends StatefulWidget {
  final dynamic isletmebilgi;
  const FormSablonlari({Key? key, required this.isletmebilgi}) : super(key: key);

  @override
  State<FormSablonlari> createState() => _FormSablonlariState();
}

class _FormSablonlariState extends State<FormSablonlari> {
  bool _yukleniyor = true;
  String _seciliSube = '';
  List<Map<String, dynamic>> _formlar = [];

  @override
  void initState() {
    super.initState();
    _baslat();
  }

  Future<void> _baslat() async {
    _seciliSube = (await secilisalonid()) ?? '';
    await _listeyiYukle();
  }

  Future<void> _listeyiYukle() async {
    if (mounted) setState(() => _yukleniyor = true);
    try {
      final resp = await http.get(
        Uri.parse(
            'https://apptest.randevumcepte.com.tr/api/v1/form-sablonlari-liste?sube=$_seciliSube'),
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final List liste = (data is Map && data['formlar'] != null)
            ? data['formlar'] as List
            : (data is List ? data : []);
        _formlar = liste.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}
    if (mounted) setState(() => _yukleniyor = false);
  }

  Future<void> _siraDegistir(int formId, String yon) async {
    final idx = _formlar.indexWhere((f) => f['id'].toString() == formId.toString());
    if (idx < 0) return;
    if (yon == 'yukari' && idx > 0) {
      final tmp = _formlar[idx - 1];
      _formlar[idx - 1] = _formlar[idx];
      _formlar[idx] = tmp;
    } else if (yon == 'asagi' && idx < _formlar.length - 1) {
      final tmp = _formlar[idx + 1];
      _formlar[idx + 1] = _formlar[idx];
      _formlar[idx] = tmp;
    } else {
      return;
    }
    setState(() {});
    try {
      await http.post(
        Uri.parse(
            'https://apptest.randevumcepte.com.tr/api/v1/form-sablonlari-sira-guncelle'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'sube': _seciliSube, 'form_id': formId, 'yon': yon}),
      );
    } catch (_) {}
  }

  Future<void> _sil(Map<String, dynamic> form) async {
    final accent = Theme.of(context).colorScheme.primary;
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline_rounded,
                    color: Color(0xFFDC2626), size: 28),
              ),
              const SizedBox(height: 14),
              const Text('Form Şablonunu Sil',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(
                '"${form['form_adi'] ?? ''}" şablonunu silmek istediğinize emin misiniz? Bu işlem geri alınamaz.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.black.withValues(alpha: 0.6),
                    height: 1.4),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: BorderSide(color: accent.withValues(alpha: 0.3)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Vazgeç',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Evet, Sil',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (onay != true) return;

    try {
      final resp = await http.post(
        Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/form-sablonlari-sil'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'sube': _seciliSube, 'form_id': form['id']}),
      );
      if (resp.statusCode == 200) {
        await _listeyiYukle();
      }
    } catch (_) {}
  }

  Future<void> _yeniVeyaDuzenle({Map<String, dynamic>? form}) async {
    final sonuc = await Navigator.push(
      context,
      PageTransition(
        type: PageTransitionType.rightToLeft,
        duration: const Duration(milliseconds: 300),
        child: FormSablonDuzenle(
          isletmebilgi: widget.isletmebilgi,
          mevcutForm: form,
        ),
      ),
    );
    if (sonuc == true) {
      await _listeyiYukle();
    }
  }

  int _elemanSayisi(Map<String, dynamic> form) {
    final json = form['sorular_json'];
    if (json == null || json.toString().trim().isEmpty) return 0;
    try {
      final list = jsonDecode(json.toString());
      if (list is List) return list.length;
    } catch (_) {}
    return 0;
  }

  String _olusturmaTarihi(Map<String, dynamic> form) {
    final t = form['created_at']?.toString();
    if (t == null || t.isEmpty) return '-';
    try {
      final d = DateTime.parse(t);
      return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
    } catch (_) {
      return '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (_yukleniyor) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: _listeyiYukle,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
        children: [
          _YeniSablonCTA(onTap: () => _yeniVeyaDuzenle()),
          const SizedBox(height: 14),
          if (_formlar.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(Icons.description_outlined,
                      size: 64,
                      color: scheme.primary.withValues(alpha: 0.4)),
                  const SizedBox(height: 14),
                  Text(
                    'Henüz form şablonu yok',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Yukarıdaki kartla yeni şablon oluştur.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: scheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            )
          else
            ..._formlar.asMap().entries.map((entry) {
              final i = entry.key;
              final form = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _SablonKart(
                  form: form,
                  elemanSayisi: _elemanSayisi(form),
                  tarih: _olusturmaTarihi(form),
                  ilk: i == 0,
                  son: i == _formlar.length - 1,
                  onYukari: () => _siraDegistir(
                      int.parse(form['id'].toString()), 'yukari'),
                  onAsagi: () => _siraDegistir(
                      int.parse(form['id'].toString()), 'asagi'),
                  onDuzenle: () => _yeniVeyaDuzenle(form: form),
                  onSil: () => _sil(form),
                  onPdf: () {},
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _YeniSablonCTA extends StatelessWidget {
  final VoidCallback onTap;
  const _YeniSablonCTA({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [scheme.primary, scheme.tertiary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.30),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.add_rounded,
                    color: scheme.onPrimary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Yeni Form Şablonu',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: scheme.onPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Onam formu veya hizmet sözleşmesi oluştur',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: scheme.onPrimary.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  color: scheme.onPrimary, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}

class _SablonKart extends StatelessWidget {
  final Map<String, dynamic> form;
  final int elemanSayisi;
  final String tarih;
  final bool ilk;
  final bool son;
  final VoidCallback onYukari;
  final VoidCallback onAsagi;
  final VoidCallback onDuzenle;
  final VoidCallback onSil;
  final VoidCallback onPdf;

  const _SablonKart({
    required this.form,
    required this.elemanSayisi,
    required this.tarih,
    required this.ilk,
    required this.son,
    required this.onYukari,
    required this.onAsagi,
    required this.onDuzenle,
    required this.onSil,
    required this.onPdf,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isSozlesme = form['is_sozlesme_tipi']?.toString() == '1';
    return PremiumGlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: (isSozlesme ? const Color(0xFF0EA5E9) : scheme.primary)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isSozlesme
                      ? Icons.handshake_outlined
                      : Icons.description_outlined,
                  color: isSozlesme ? const Color(0xFF0EA5E9) : scheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      form['form_adi']?.toString() ?? '-',
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (isSozlesme)
                          _MetaPill(
                            label: 'Sözleşme',
                            color: const Color(0xFF0EA5E9),
                          ),
                        _MetaPill(
                          label: '$elemanSayisi eleman',
                          color: scheme.primary,
                        ),
                        _MetaPill(
                          label: tarih,
                          color: const Color(0xFF6B7280),
                          icon: Icons.calendar_today_rounded,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  _SiraBtn(
                    icon: Icons.keyboard_arrow_up_rounded,
                    enabled: !ilk,
                    onTap: onYukari,
                  ),
                  const SizedBox(height: 4),
                  _SiraBtn(
                    icon: Icons.keyboard_arrow_down_rounded,
                    enabled: !son,
                    onTap: onAsagi,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _AksiyonBtn(
                  icon: Icons.edit_outlined,
                  label: 'Düzenle',
                  color: scheme.primary,
                  onTap: onDuzenle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _AksiyonBtn(
                  icon: Icons.delete_outline_rounded,
                  label: 'Sil',
                  color: const Color(0xFFDC2626),
                  onTap: onSil,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  const _MetaPill({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _SiraBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _SiraBtn(
      {required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Opacity(
      opacity: enabled ? 1 : 0.3,
      child: Material(
        color: scheme.primary.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 30,
            height: 26,
            child: Icon(icon, size: 18, color: scheme.primary),
          ),
        ),
      ),
    );
  }
}

class _AksiyonBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _AksiyonBtn(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

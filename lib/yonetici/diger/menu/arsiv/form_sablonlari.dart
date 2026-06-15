import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:page_transition/page_transition.dart';
import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/theme/premium_components.dart';
import 'package:url_launcher/url_launcher.dart';
import 'form_sablon_duzenle.dart';

class FormSablonlari extends StatefulWidget {
  final dynamic isletmebilgi;
  const FormSablonlari({super.key, required this.isletmebilgi});

  @override
  State<FormSablonlari> createState() => _FormSablonlariState();
}

class _FormSablonlariState extends State<FormSablonlari> {
  bool _yukleniyor = true;
  String _seciliSube = '';
  List<Map<String, dynamic>> _formlar = [];
  String _arama = '';
  String _filtre = 'tum'; // tum | form | sozlesme

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
            'https://app.randevumcepte.com.tr/api/v1/form-sablonlari-liste?sube=$_seciliSube'),
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final List liste = (data is Map && data['formlar'] != null)
            ? data['formlar'] as List
            : (data is List ? data : []);
        _formlar = liste
            .map<Map<String, dynamic>>(
                (e) => Map<String, dynamic>.from(e))
            .toList();
      }
    } catch (_) {}
    if (mounted) setState(() => _yukleniyor = false);
  }

  Future<void> _siraDegistir(int formId, String yon) async {
    final idx =
        _formlar.indexWhere((f) => f['id'].toString() == formId.toString());
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
            'https://app.randevumcepte.com.tr/api/v1/form-sablonlari-sira-guncelle'),
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
        Uri.parse(
            'https://app.randevumcepte.com.tr/api/v1/form-sablonlari-sil'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'sube': _seciliSube, 'form_id': form['id']}),
      );
      if (resp.statusCode == 200) {
        final j = jsonDecode(resp.body);
        if (j is Map && j['basarili'] != true) {
          if (mounted) {
            showPremiumWarning(context,
                title: 'Silinemedi',
                message: j['mesaj']?.toString() ??
                    'Form silinemedi, tekrar deneyin.',
                tone: 'error');
          }
          return;
        }
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

  Future<void> _pdfAc(Map<String, dynamic> form) async {
    final url =
        'https://app.randevumcepte.com.tr/isletmeyonetim/bosFormIndirDinamik?formId=${form['id']}&sube=$_seciliSube';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      showPremiumWarning(context,
          title: 'Açılamadı',
          message: 'PDF tarayıcıda açılamadı.',
          tone: 'error');
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

  bool _isSozlesme(Map<String, dynamic> f) =>
      f['is_sozlesme_tipi']?.toString() == '1';

  List<Map<String, dynamic>> get _filtreliListe {
    return _formlar.where((f) {
      if (_filtre == 'sozlesme' && !_isSozlesme(f)) return false;
      if (_filtre == 'form' && _isSozlesme(f)) return false;
      if (_arama.isEmpty) return true;
      final adi = (f['form_adi']?.toString() ?? '').toLowerCase();
      return adi.contains(_arama.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (_yukleniyor) {
      return const Center(child: CircularProgressIndicator());
    }

    final toplam = _formlar.length;
    final sozlesmeSayisi = _formlar.where(_isSozlesme).length;
    final formSayisi = toplam - sozlesmeSayisi;
    final liste = _filtreliListe;

    return RefreshIndicator(
      onRefresh: _listeyiYukle,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
        children: [
          _StatsBanner(
            toplam: toplam,
            formSayisi: formSayisi,
            sozlesmeSayisi: sozlesmeSayisi,
          ),
          const SizedBox(height: 12),
          _YeniSablonCTA(onTap: () => _yeniVeyaDuzenle()),
          if (toplam > 0) ...[
            const SizedBox(height: 12),
            _AramaKutusu(
              onChanged: (v) => setState(() => _arama = v),
            ),
            const SizedBox(height: 8),
            _FiltreChipler(
              secili: _filtre,
              tumSayisi: toplam,
              formSayisi: formSayisi,
              sozlesmeSayisi: sozlesmeSayisi,
              onChanged: (v) => setState(() => _filtre = v),
            ),
          ],
          const SizedBox(height: 12),
          if (liste.isEmpty && toplam == 0)
            _BosDurum(
              ikon: Icons.description_outlined,
              baslik: 'Henüz form şablonu yok',
              altYazi: 'Yukarıdaki kartla ilk şablonunu oluştur.',
              renk: scheme.primary,
            )
          else if (liste.isEmpty)
            _BosDurum(
              ikon: Icons.search_off_rounded,
              baslik: 'Eşleşme yok',
              altYazi: 'Filtreyi veya aramayı temizleyebilirsin.',
              renk: scheme.primary,
            )
          else
            ...liste.asMap().entries.map((entry) {
              final i = entry.key;
              final form = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _SablonKart(
                  form: form,
                  isSozlesme: _isSozlesme(form),
                  elemanSayisi: _elemanSayisi(form),
                  tarih: _olusturmaTarihi(form),
                  ilk: i == 0,
                  son: i == liste.length - 1,
                  onYukari: () => _siraDegistir(
                      int.parse(form['id'].toString()), 'yukari'),
                  onAsagi: () => _siraDegistir(
                      int.parse(form['id'].toString()), 'asagi'),
                  onDuzenle: () => _yeniVeyaDuzenle(form: form),
                  onSil: () => _sil(form),
                  onPdf: () => _pdfAc(form),
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ===========================================================================
// STATS BANNER
// ===========================================================================
class _StatsBanner extends StatelessWidget {
  final int toplam;
  final int formSayisi;
  final int sozlesmeSayisi;
  const _StatsBanner({
    required this.toplam,
    required this.formSayisi,
    required this.sozlesmeSayisi,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _MiniStat(
              ikon: Icons.dashboard_customize_rounded,
              etiket: 'Toplam',
              deger: toplam.toString(),
              renk: scheme.primary,
            ),
          ),
          Container(width: 1, height: 32, color: Colors.black12),
          Expanded(
            child: _MiniStat(
              ikon: Icons.description_outlined,
              etiket: 'Onam Formu',
              deger: formSayisi.toString(),
              renk: const Color(0xFF7C3AED),
            ),
          ),
          Container(width: 1, height: 32, color: Colors.black12),
          Expanded(
            child: _MiniStat(
              ikon: Icons.handshake_outlined,
              etiket: 'Sözleşme',
              deger: sozlesmeSayisi.toString(),
              renk: const Color(0xFF0EA5E9),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData ikon;
  final String etiket;
  final String deger;
  final Color renk;
  const _MiniStat({
    required this.ikon,
    required this.etiket,
    required this.deger,
    required this.renk,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(ikon, size: 18, color: renk),
        const SizedBox(height: 4),
        Text(
          deger,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: renk,
            height: 1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          etiket,
          style: const TextStyle(
            fontSize: 10.5,
            color: Colors.black54,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// YENİ ŞABLON CTA
// ===========================================================================
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

// ===========================================================================
// ARAMA + FİLTRE
// ===========================================================================
class _AramaKutusu extends StatelessWidget {
  final ValueChanged<String> onChanged;
  const _AramaKutusu({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Şablon ara...',
          hintStyle: const TextStyle(fontSize: 13, color: Colors.black45),
          prefixIcon: Icon(Icons.search_rounded,
              size: 18, color: scheme.primary.withValues(alpha: 0.7)),
          border: InputBorder.none,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }
}

class _FiltreChipler extends StatelessWidget {
  final String secili;
  final int tumSayisi;
  final int formSayisi;
  final int sozlesmeSayisi;
  final ValueChanged<String> onChanged;
  const _FiltreChipler({
    required this.secili,
    required this.tumSayisi,
    required this.formSayisi,
    required this.sozlesmeSayisi,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _Chip(
            etiket: 'Tümü ($tumSayisi)',
            aktif: secili == 'tum',
            renk: Theme.of(context).colorScheme.primary,
            onTap: () => onChanged('tum'),
          ),
          const SizedBox(width: 6),
          _Chip(
            etiket: 'Onam Formu ($formSayisi)',
            aktif: secili == 'form',
            renk: const Color(0xFF7C3AED),
            onTap: () => onChanged('form'),
          ),
          const SizedBox(width: 6),
          _Chip(
            etiket: 'Sözleşme ($sozlesmeSayisi)',
            aktif: secili == 'sozlesme',
            renk: const Color(0xFF0EA5E9),
            onTap: () => onChanged('sozlesme'),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String etiket;
  final bool aktif;
  final Color renk;
  final VoidCallback onTap;
  const _Chip({
    required this.etiket,
    required this.aktif,
    required this.renk,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: aktif ? renk : Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: aktif ? renk : renk.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Text(
            etiket,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: aktif ? Colors.white : renk,
            ),
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// BOŞ DURUM
// ===========================================================================
class _BosDurum extends StatelessWidget {
  final IconData ikon;
  final String baslik;
  final String altYazi;
  final Color renk;
  const _BosDurum({
    required this.ikon,
    required this.baslik,
    required this.altYazi,
    required this.renk,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: renk.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(ikon, size: 36, color: renk),
          ),
          const SizedBox(height: 14),
          Text(baslik,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
            altYazi,
            textAlign: TextAlign.center,
            style:
                const TextStyle(fontSize: 12.5, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// ŞABLON KARTI
// ===========================================================================
class _SablonKart extends StatelessWidget {
  final Map<String, dynamic> form;
  final bool isSozlesme;
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
    required this.isSozlesme,
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
    final aksanRenk =
        isSozlesme ? const Color(0xFF0EA5E9) : const Color(0xFF7C3AED);
    final aksanIkon =
        isSozlesme ? Icons.handshake_outlined : Icons.description_outlined;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: aksanRenk.withValues(alpha: 0.10),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onDuzenle,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            aksanRenk.withValues(alpha: 0.20),
                            aksanRenk.withValues(alpha: 0.08),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(aksanIkon, color: aksanRenk, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: aksanRenk.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              isSozlesme ? 'SÖZLEŞME' : 'ONAM FORMU',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: aksanRenk,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            form['form_adi']?.toString() ?? '-',
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.layers_outlined,
                                  size: 12,
                                  color: scheme.onSurface
                                      .withValues(alpha: 0.5)),
                              const SizedBox(width: 3),
                              Text(
                                '$elemanSayisi eleman',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: scheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Icon(Icons.calendar_today_rounded,
                                  size: 11,
                                  color: scheme.onSurface
                                      .withValues(alpha: 0.5)),
                              const SizedBox(width: 3),
                              Text(
                                tarih,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: scheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
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
                    const SizedBox(width: 6),
                    Expanded(
                      child: _AksiyonBtn(
                        icon: Icons.picture_as_pdf_outlined,
                        label: 'PDF',
                        color: const Color(0xFF0EA5E9),
                        onTap: onPdf,
                      ),
                    ),
                    const SizedBox(width: 6),
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
          ),
        ),
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
  const _AksiyonBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

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
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
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

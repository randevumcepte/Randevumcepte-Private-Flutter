import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/theme/premium_components.dart';

/// Form şablonu eleman tipleri — web tarafındaki TIP_RENK ve OTOMATIK_TIPLER ile birebir.
class _Tip {
  final String key;
  final String etiket;
  final IconData icon;
  final Color renk;
  const _Tip(this.key, this.etiket, this.icon, this.renk);
}

const _yapiTipleri = <_Tip>[
  _Tip('bolum_basligi', 'Bölüm Başlığı', Icons.title_rounded, Color(0xFF343A40)),
  _Tip('alt_baslik', 'Alt Başlık', Icons.format_size_rounded, Color(0xFF6C757D)),
  _Tip('metin_blogu', 'Metin Bloğu', Icons.notes_rounded, Color(0xFF6C757D)),
  _Tip('madde_listesi', 'Madde Listesi', Icons.format_list_bulleted_rounded, Color(0xFF6C757D)),
  _Tip('not_kutusu', 'Not Kutusu', Icons.info_outline_rounded, Color(0xFF17A2B8)),
];

const _otoTipleri = <_Tip>[
  _Tip('musteri_bilgi_tablosu', 'Müşteri Bilgileri', Icons.person_rounded, Color(0xFF0DCAF0)),
  _Tip('hizmet_paket_bilgisi', 'Hizmet/Paket', Icons.shopping_bag_outlined, Color(0xFF0DCAF0)),
  _Tip('ucret_bilgisi', 'Ücret & Kapora', Icons.payments_outlined, Color(0xFF0DCAF0)),
  _Tip('seans_bilgisi', 'Seans Sayısı', Icons.event_available_rounded, Color(0xFF0DCAF0)),
  _Tip('tarih_yer', 'Tarih & İşletme Adresi', Icons.place_outlined, Color(0xFF0DCAF0)),
];

const _cevapTipleri = <_Tip>[
  _Tip('evet_hayir', 'Evet/Hayır Sorusu', Icons.check_box_outlined, Color(0xFF5C008E)),
  _Tip('metin', 'Kısa Metin Girişi', Icons.short_text_rounded, Color(0xFF28A745)),
  _Tip('uzun_metin', 'Uzun Metin Girişi', Icons.subject_rounded, Color(0xFFFFC107)),
];

_Tip _tipBul(String key) {
  for (final t in [..._yapiTipleri, ..._otoTipleri, ..._cevapTipleri]) {
    if (t.key == key) return t;
  }
  return _yapiTipleri.first;
}

bool _otomatikMi(String key) => _otoTipleri.any((t) => t.key == key);

bool _zorunluKutucukluMu(String key) =>
    key == 'evet_hayir' || key == 'metin' || key == 'uzun_metin';

class _SoruModel {
  String tip;
  String metin;
  bool zorunlu;
  final TextEditingController controller;
  _SoruModel({required this.tip, this.metin = '', this.zorunlu = false})
      : controller = TextEditingController(text: metin);
}

class FormSablonDuzenle extends StatefulWidget {
  final dynamic isletmebilgi;
  final Map<String, dynamic>? mevcutForm;
  const FormSablonDuzenle({
    super.key,
    required this.isletmebilgi,
    this.mevcutForm,
  });

  @override
  State<FormSablonDuzenle> createState() => _FormSablonDuzenleState();
}

class _FormSablonDuzenleState extends State<FormSablonDuzenle> {
  String _seciliSube = '';
  bool _kaydediliyor = false;

  final _formAdi = TextEditingController();
  final _aciklama = TextEditingController();
  bool _isSozlesme = false;
  final List<_SoruModel> _sorular = [];

  bool get _duzenleme => widget.mevcutForm != null;

  @override
  void initState() {
    super.initState();
    _baslat();
  }

  Future<void> _baslat() async {
    _seciliSube = (await secilisalonid()) ?? '';
    if (_duzenleme) {
      final f = widget.mevcutForm!;
      _formAdi.text = f['form_adi']?.toString() ?? '';
      _aciklama.text = f['aciklama']?.toString() ?? '';
      _isSozlesme = f['is_sozlesme_tipi']?.toString() == '1';
      final json = f['sorular_json']?.toString() ?? '';
      if (json.isNotEmpty) {
        try {
          final list = jsonDecode(json);
          if (list is List) {
            for (final item in list) {
              if (item is Map) {
                _sorular.add(_SoruModel(
                  tip: item['tip']?.toString() ?? 'metin_blogu',
                  metin: item['soru']?.toString() ?? '',
                  zorunlu: item['zorunlu'] == true || item['zorunlu']?.toString() == '1',
                ));
              }
            }
          }
        } catch (_) {}
      }
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _formAdi.dispose();
    _aciklama.dispose();
    for (final s in _sorular) {
      s.controller.dispose();
    }
    super.dispose();
  }

  void _soruEkle(String tip) {
    setState(() {
      _sorular.add(_SoruModel(tip: tip));
    });
  }

  void _soruSil(int idx) {
    setState(() {
      _sorular.removeAt(idx).controller.dispose();
    });
  }

  void _soruTasi(int idx, int yon) {
    final yeni = idx + yon;
    if (yeni < 0 || yeni >= _sorular.length) return;
    setState(() {
      final tmp = _sorular[idx];
      _sorular[idx] = _sorular[yeni];
      _sorular[yeni] = tmp;
    });
  }

  Future<void> _kaydet() async {
    final ad = _formAdi.text.trim();
    if (ad.isEmpty) {
      showPremiumWarning(context,
          title: 'Form Adı Gerekli', message: 'Lütfen form adı girin.');
      return;
    }
    if (_sorular.isEmpty) {
      showPremiumWarning(context,
          title: 'Boş Form',
          message: 'En az bir form elemanı eklemelisiniz.');
      return;
    }

    final liste = _sorular
        .map((s) => {
              'tip': s.tip,
              'soru': _otomatikMi(s.tip) ? s.tip : s.controller.text.trim(),
              'zorunlu': _zorunluKutucukluMu(s.tip) ? s.zorunlu : false,
            })
        .toList();

    setState(() => _kaydediliyor = true);
    try {
      final body = {
        'sube': _seciliSube,
        'form_id': _duzenleme ? widget.mevcutForm!['id'] : null,
        'form_adi': ad,
        'aciklama': _aciklama.text,
        'is_sozlesme': _isSozlesme ? 1 : 0,
        'sorular_json': jsonEncode(liste),
      };
      final url = _duzenleme
          ? 'https://apptest.randevumcepte.com.tr/api/v1/form-sablonlari-guncelle'
          : 'https://apptest.randevumcepte.com.tr/api/v1/form-sablonlari-kaydet';
      final resp = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (resp.statusCode == 200) {
        final j = jsonDecode(resp.body);
        if (j is Map && j['basarili'] == true) {
          if (mounted) Navigator.pop(context, true);
          return;
        }
        if (mounted) {
          showPremiumWarning(context,
              title: 'Kaydedilemedi',
              message: (j is Map && j['mesaj'] != null)
                  ? j['mesaj'].toString()
                  : 'Bir hata oluştu, tekrar deneyin.',
              tone: 'error');
        }
      } else {
        if (mounted) {
          showPremiumWarning(context,
              title: 'Sunucu Hatası',
              message: 'Hata kodu: ${resp.statusCode}',
              tone: 'error');
        }
      }
    } catch (e) {
      if (mounted) {
        showPremiumWarning(context,
            title: 'Bağlantı Hatası',
            message: 'İnternet bağlantınızı kontrol edin.',
            tone: 'error');
      }
    } finally {
      if (mounted) setState(() => _kaydediliyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PremiumGradientBg(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          title: Text(
            _duzenleme ? 'Şablonu Düzenle' : 'Yeni Form Şablonu',
            style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w700,
                fontSize: 16),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: _kaydediliyor ? null : _kaydet,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [scheme.primary, scheme.tertiary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: scheme.primary.withValues(alpha: 0.30),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _kaydediliyor
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.save_outlined,
                                  color: scheme.onPrimary, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                _duzenleme ? 'Güncelle' : 'Şablonu Kaydet',
                                style: TextStyle(
                                  color: scheme.onPrimary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
          children: [
            _BilgiKart(
              formAdi: _formAdi,
              aciklama: _aciklama,
              isSozlesme: _isSozlesme,
              onSozlesmeDegisti: (v) => setState(() => _isSozlesme = v),
            ),
            const SizedBox(height: 14),
            PremiumGlassCard(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.add_box_outlined,
                          size: 18, color: scheme.primary),
                      const SizedBox(width: 8),
                      const Text('Eleman Ekle',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _TipBolumu(
                      baslik: 'YAPI ELEMANLARI',
                      tipler: _yapiTipleri,
                      onTip: _soruEkle),
                  if (_isSozlesme) ...[
                    const SizedBox(height: 8),
                    _TipBolumu(
                      baslik: 'OTOMATİK SÖZLEŞME BLOKLARI',
                      altYazi: 'Gönderirken otomatik doldurulur',
                      tipler: _otoTipleri,
                      onTip: _soruEkle,
                    ),
                  ],
                  const SizedBox(height: 8),
                  _TipBolumu(
                      baslik: 'MÜŞTERİ CEVAPLI ALANLAR',
                      tipler: _cevapTipleri,
                      onTip: _soruEkle),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (_sorular.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Icon(Icons.touch_app_outlined,
                        size: 40,
                        color: scheme.primary.withValues(alpha: 0.45)),
                    const SizedBox(height: 8),
                    Text(
                      'Yukarıdan eleman ekleyin',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              )
            else
              ..._sorular.asMap().entries.map((e) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _SoruKart(
                    soru: e.value,
                    ilk: e.key == 0,
                    son: e.key == _sorular.length - 1,
                    onYukari: () => _soruTasi(e.key, -1),
                    onAsagi: () => _soruTasi(e.key, 1),
                    onSil: () => _soruSil(e.key),
                    onZorunluDegisti: (v) =>
                        setState(() => e.value.zorunlu = v),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _BilgiKart extends StatelessWidget {
  final TextEditingController formAdi;
  final TextEditingController aciklama;
  final bool isSozlesme;
  final ValueChanged<bool> onSozlesmeDegisti;

  const _BilgiKart({
    required this.formAdi,
    required this.aciklama,
    required this.isSozlesme,
    required this.onSozlesmeDegisti,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PremiumGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Form Adı',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          TextField(
            controller: formAdi,
            decoration: InputDecoration(
              hintText: 'Örn: Lazer Epilasyon Onam Formu',
              filled: true,
              fillColor: scheme.primary.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
          const SizedBox(height: 14),
          const Text('Açıklama',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
          const Text('Formun üstünde gri kutuda gösterilir.',
              style: TextStyle(fontSize: 11, color: Colors.black54)),
          const SizedBox(height: 6),
          TextField(
            controller: aciklama,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Bu formdaki açıklamaların amacı...',
              filled: true,
              fillColor: scheme.primary.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF0EA5E9).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.3)),
            ),
            child: SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: isSozlesme,
              onChanged: onSozlesmeDegisti,
              activeThumbColor: const Color(0xFF0EA5E9),
              title: const Text('Hizmet Sözleşmesi',
                  style: TextStyle(
                      fontSize: 13.5, fontWeight: FontWeight.w800)),
              subtitle: const Text(
                'Sözleşme bloklarını kullanmak için açın',
                style: TextStyle(fontSize: 11, color: Colors.black54),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TipBolumu extends StatelessWidget {
  final String baslik;
  final String? altYazi;
  final List<_Tip> tipler;
  final void Function(String tip) onTip;
  const _TipBolumu({
    required this.baslik,
    required this.tipler,
    required this.onTip,
    this.altYazi,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(baslik,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: Colors.black.withValues(alpha: 0.55),
              letterSpacing: 0.4,
            )),
        if (altYazi != null) ...[
          const SizedBox(height: 2),
          Text(altYazi!,
              style: const TextStyle(
                  fontSize: 10.5, color: Colors.black54)),
        ],
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: tipler.map((t) {
            return Material(
              color: t.renk.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: () => onTip(t.key),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(t.icon, size: 14, color: t.renk),
                      const SizedBox(width: 6),
                      Text(
                        t.etiket,
                        style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: t.renk),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _SoruKart extends StatelessWidget {
  final _SoruModel soru;
  final bool ilk;
  final bool son;
  final VoidCallback onYukari;
  final VoidCallback onAsagi;
  final VoidCallback onSil;
  final ValueChanged<bool> onZorunluDegisti;

  const _SoruKart({
    required this.soru,
    required this.ilk,
    required this.son,
    required this.onYukari,
    required this.onAsagi,
    required this.onSil,
    required this.onZorunluDegisti,
  });

  @override
  Widget build(BuildContext context) {
    final tip = _tipBul(soru.tip);
    final otomatik = _otomatikMi(soru.tip);
    final zorunluKutucuk = _zorunluKutucukluMu(soru.tip);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: tip.renk, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: tip.renk.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(tip.icon, size: 11, color: tip.renk),
                      const SizedBox(width: 4),
                      Text(tip.etiket,
                          style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: tip.renk)),
                    ],
                  ),
                ),
                const Spacer(),
                _MiniBtn(
                  icon: Icons.keyboard_arrow_up_rounded,
                  enabled: !ilk,
                  onTap: onYukari,
                ),
                const SizedBox(width: 4),
                _MiniBtn(
                  icon: Icons.keyboard_arrow_down_rounded,
                  enabled: !son,
                  onTap: onAsagi,
                ),
                const SizedBox(width: 4),
                _MiniBtn(
                  icon: Icons.delete_outline_rounded,
                  color: const Color(0xFFDC2626),
                  enabled: true,
                  onTap: onSil,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (otomatik)
              _OtomatikAciklama(tip: soru.tip)
            else
              _icerikGiris(),
            if (zorunluKutucuk) ...[
              const SizedBox(height: 6),
              InkWell(
                onTap: () => onZorunluDegisti(!soru.zorunlu),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        height: 18,
                        width: 18,
                        child: Checkbox(
                          value: soru.zorunlu,
                          onChanged: (v) => onZorunluDegisti(v ?? false),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('Zorunlu cevap',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _icerikGiris() {
    final isCokSatir = soru.tip == 'metin_blogu' ||
        soru.tip == 'madde_listesi' ||
        soru.tip == 'not_kutusu';
    final placeholder = switch (soru.tip) {
      'bolum_basligi' => 'BÖLÜM BAŞLIĞI...',
      'alt_baslik' => 'Alt başlık metni...',
      'metin_blogu' => 'Paragraf metni...',
      'madde_listesi' =>
        'Her satıra bir madde:\nKızarıklık (eritem).\nYan etki sadece geçici...',
      'not_kutusu' => 'Not kutusu metni...',
      'evet_hayir' => 'Soru metni (Evet/Hayır)...',
      'metin' => 'Soru metni (kısa cevap)...',
      'uzun_metin' => 'Soru metni (uzun cevap)...',
      _ => 'Metin...',
    };
    return TextField(
      controller: soru.controller,
      maxLines: isCokSatir ? 3 : 1,
      style: TextStyle(
        fontSize: 13,
        fontWeight:
            soru.tip == 'bolum_basligi' ? FontWeight.w800 : FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle: const TextStyle(fontSize: 12, color: Colors.black38),
        filled: true,
        fillColor: const Color(0xFFF4F5F7),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _MiniBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final Color? color;
  final VoidCallback onTap;
  const _MiniBtn({
    required this.icon,
    required this.enabled,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Opacity(
      opacity: enabled ? 1 : 0.3,
      child: Material(
        color: c.withValues(alpha: 0.10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 30,
            height: 28,
            child: Icon(icon, size: 16, color: c),
          ),
        ),
      ),
    );
  }
}

class _OtomatikAciklama extends StatelessWidget {
  final String tip;
  const _OtomatikAciklama({required this.tip});

  @override
  Widget build(BuildContext context) {
    final aciklama = switch (tip) {
      'musteri_bilgi_tablosu' =>
        'Müşteri ad, soyad, telefon ve tarih otomatik gösterilir.',
      'hizmet_paket_bilgisi' =>
        'Seçilen hizmet veya paket adı otomatik gösterilir.',
      'ucret_bilgisi' =>
        'Toplam ücret, kapora ve kalan bakiye otomatik gösterilir.',
      'seans_bilgisi' => 'Seans sayısı otomatik gösterilir.',
      'tarih_yer' => 'Sözleşme tarihi ve işletme adresi otomatik gösterilir.',
      _ => 'Otomatik bilgi.',
    };
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF0DCAF0).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: const Color(0xFF0DCAF0).withValues(alpha: 0.3),
            style: BorderStyle.solid),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome_rounded,
              size: 16, color: Color(0xFF0C5460)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              aciklama,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF0C5460), height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}

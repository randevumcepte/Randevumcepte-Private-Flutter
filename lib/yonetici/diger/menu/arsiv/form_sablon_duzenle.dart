import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:randevu_sistem/Backend/backend.dart';

/// Form şablonu eleman tipleri.
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
  _Tip('evet_hayir', 'Evet/Hayır', Icons.check_box_outlined, Color(0xFF5C008E)),
  _Tip('metin', 'Kısa Metin', Icons.short_text_rounded, Color(0xFF28A745)),
  _Tip('uzun_metin', 'Uzun Metin', Icons.subject_rounded, Color(0xFFFFC107)),
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
  bool zorunlu;
  final TextEditingController controller;
  _SoruModel({required this.tip, String metin = '', bool? zorunlu})
      : zorunlu = zorunlu ?? _zorunluKutucukluMu(tip),
        controller = TextEditingController(text: metin);
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
    try {
      _seciliSube = (await secilisalonid()) ?? '';
    } catch (_) {}
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
                  zorunlu: item['zorunlu'] == true ||
                      item['zorunlu']?.toString() == '1',
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
    setState(() => _sorular.add(_SoruModel(tip: tip)));
  }

  void _soruSil(int idx) {
    setState(() => _sorular.removeAt(idx).controller.dispose());
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

  void _uyari(String baslik, String mesaj) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(baslik),
        content: Text(mesaj),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  Future<void> _kaydet() async {
    final ad = _formAdi.text.trim();
    if (ad.isEmpty) {
      _uyari('Form Adı Gerekli', 'Lütfen form adı girin.');
      return;
    }
    if (_sorular.isEmpty) {
      _uyari('Boş Form', 'En az bir form elemanı ekleyin.');
      return;
    }

    // Cevap tipli alanlar (evet/hayir, metin, uzun_metin) her zaman zorunlu.
    final liste = _sorular
        .map((s) => {
              'tip': s.tip,
              'soru': _otomatikMi(s.tip) ? s.tip : s.controller.text.trim(),
              'zorunlu': _zorunluKutucukluMu(s.tip),
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
          _uyari('Kaydedilemedi',
              (j is Map && j['mesaj'] != null) ? j['mesaj'].toString() : 'Hata oluştu.');
        }
      } else if (mounted) {
        _uyari('Sunucu Hatası', 'Kod: ${resp.statusCode}');
      }
    } catch (_) {
      if (mounted) _uyari('Bağlantı Hatası', 'İnternet bağlantınızı kontrol edin.');
    } finally {
      if (mounted) setState(() => _kaydediliyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F4FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        title: Text(
          _duzenleme ? 'Şablonu Düzenle' : 'Yeni Form Şablonu',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        actions: [
          TextButton.icon(
            onPressed: _kaydediliyor ? null : _kaydet,
            icon: _kaydediliyor
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.check_rounded, color: scheme.primary),
            label: Text(
              _duzenleme ? 'Güncelle' : 'Kaydet',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: scheme.primary,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
        children: [
          _kart(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Etiket('Form Adı *'),
                TextField(
                  controller: _formAdi,
                  maxLength: 200,
                  decoration: _inputDeko(
                      'Örn: Lazer Epilasyon Onam Formu', scheme),
                  buildCounter: (_,
                      {required currentLength,
                      required isFocused,
                      maxLength}) =>
                      null,
                ),
                const SizedBox(height: 12),
                const _Etiket('Açıklama (opsiyonel)'),
                TextField(
                  controller: _aciklama,
                  maxLines: 2,
                  decoration: _inputDeko(
                      'Formun üstünde gri kutuda gösterilir', scheme),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0EA5E9).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFF0EA5E9)
                            .withValues(alpha: 0.30)),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Hizmet Sözleşmesi',
                                style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800)),
                            SizedBox(height: 2),
                            Text(
                                'Açarsan otomatik sözleşme blokları kullanılabilir',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.black54)),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isSozlesme,
                        onChanged: (v) =>
                            setState(() => _isSozlesme = v),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _kart(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.add_box_outlined,
                        size: 18, color: scheme.primary),
                    const SizedBox(width: 6),
                    const Text('Eleman Ekle',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 10),
                _tipBolumu('YAPI ELEMANLARI', _yapiTipleri),
                if (_isSozlesme) ...[
                  const SizedBox(height: 12),
                  _tipBolumu('OTOMATİK SÖZLEŞME BLOKLARI', _otoTipleri),
                ],
                const SizedBox(height: 12),
                _tipBolumu('MÜŞTERİ CEVAPLI ALANLAR', _cevapTipleri),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_sorular.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Column(
                children: [
                  Icon(Icons.touch_app_outlined,
                      size: 44,
                      color: scheme.primary.withValues(alpha: 0.5)),
                  const SizedBox(height: 8),
                  const Text(
                    'Yukarıdan eleman ekleyin',
                    style: TextStyle(
                        fontSize: 13, color: Colors.black54),
                  ),
                ],
              ),
            )
          else
            ..._sorular.asMap().entries.map((e) {
              final i = e.key;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _soruKart(e.value, i, _sorular.length),
              );
            }),
        ],
      ),
    );
  }

  Widget _kart({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  InputDecoration _inputDeko(String hint, ColorScheme scheme) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12.5, color: Colors.black38),
      filled: true,
      fillColor: const Color(0xFFF4F5F7),
      isDense: true,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _tipBolumu(String baslik, List<_Tip> tipler) {
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
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: tipler.map((t) {
            return Material(
              color: t.renk.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: () => _soruEkle(t.key),
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

  Widget _soruKart(_SoruModel soru, int idx, int toplam) {
    final tip = _tipBul(soru.tip);
    final otomatik = _otomatikMi(soru.tip);
    final zorunluKutucuk = _zorunluKutucukluMu(soru.tip);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: tip.renk, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
                _miniBtn(Icons.keyboard_arrow_up_rounded, idx > 0,
                    () => _soruTasi(idx, -1)),
                const SizedBox(width: 4),
                _miniBtn(
                    Icons.keyboard_arrow_down_rounded,
                    idx < toplam - 1,
                    () => _soruTasi(idx, 1)),
                const SizedBox(width: 4),
                _miniBtn(Icons.delete_outline_rounded, true,
                    () => _soruSil(idx),
                    renk: const Color(0xFFDC2626)),
              ],
            ),
            const SizedBox(height: 8),
            if (otomatik)
              _otomatikAciklama(soru.tip)
            else
              _soruIcerik(soru),
            if (zorunluKutucuk) ...[
              const SizedBox(height: 6),
              Row(
                children: const [
                  Icon(Icons.fiber_manual_record,
                      size: 10, color: Color(0xFFDC2626)),
                  SizedBox(width: 6),
                  Text(
                    'Zorunlu cevap',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _miniBtn(IconData icon, bool enabled, VoidCallback onTap,
      {Color? renk}) {
    final c = renk ?? Theme.of(context).colorScheme.primary;
    return Opacity(
      opacity: enabled ? 1 : 0.3,
      child: Material(
        color: c.withValues(alpha: 0.10),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

  Widget _soruIcerik(_SoruModel soru) {
    final isCokSatir = soru.tip == 'metin_blogu' ||
        soru.tip == 'madde_listesi' ||
        soru.tip == 'not_kutusu';
    final placeholder = switch (soru.tip) {
      'bolum_basligi' => 'BÖLÜM BAŞLIĞI...',
      'alt_baslik' => 'Alt başlık metni...',
      'metin_blogu' => 'Paragraf metni...',
      'madde_listesi' =>
        'Her satıra bir madde:\nKızarıklık.\nYan etki geçici...',
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

  Widget _otomatikAciklama(String tip) {
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
            color: const Color(0xFF0DCAF0).withValues(alpha: 0.30)),
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

class _Etiket extends StatelessWidget {
  final String text;
  const _Etiket(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
      ),
    );
  }
}

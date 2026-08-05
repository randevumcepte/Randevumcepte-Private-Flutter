import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Frontend/aramali_dropdown.dart';

class AnketSablonDuzenlePage extends StatefulWidget {
  final dynamic isletmebilgi;
  final Map<String, dynamic>? sablon;
  const AnketSablonDuzenlePage({Key? key, required this.isletmebilgi, this.sablon}) : super(key: key);

  @override
  State<AnketSablonDuzenlePage> createState() => _AnketSablonDuzenlePageState();
}

class _AnketSablonDuzenlePageState extends State<AnketSablonDuzenlePage> {
  late final String _salonId;
  late TextEditingController _adCtrl;
  late TextEditingController _aciklamaCtrl;
  bool _otomatik = true;
  int _saatSonra = 0;
  bool _varsayilan = false;
  bool _aktif = true;
  List<Map<String, dynamic>> _sorular = [];
  bool _kaydediliyor = false;

  // Anket tamamlama odulu (kupon/puan)
  String _odulTipi = 'yok'; // yok | kupon | puan
  String _odulKuponIndirimTipi = 'yuzde'; // yuzde | tutar
  late TextEditingController _odulDegerCtrl;
  late TextEditingController _odulGecerlilikCtrl;
  late TextEditingController _odulPuanCtrl;
  late TextEditingController _odulBaslikCtrl;

  static const _soruTipleri = [
    {'tip': 'nps', 'lbl': 'NPS (0-10)', 'icon': Icons.thumb_up_outlined},
    {'tip': 'csat_yildiz', 'lbl': 'CSAT (1-5 ⭐)', 'icon': Icons.star_outline},
    {'tip': 'evet_hayir', 'lbl': 'Evet/Hayır', 'icon': Icons.help_outline},
    {'tip': 'tek_secim', 'lbl': 'Tek Seçim', 'icon': Icons.radio_button_checked},
    {'tip': 'cok_secim', 'lbl': 'Çok Seçim', 'icon': Icons.check_box_outlined},
    {'tip': 'metin', 'lbl': 'Kısa Metin', 'icon': Icons.short_text},
    {'tip': 'uzun_metin', 'lbl': 'Uzun Metin', 'icon': Icons.notes},
    {'tip': 'bolum_basligi', 'lbl': 'Bölüm Başlığı', 'icon': Icons.title},
  ];

  @override
  void initState() {
    super.initState();
    _salonId = widget.isletmebilgi['id'].toString();
    final s = widget.sablon;
    _adCtrl = TextEditingController(text: s?['ad']?.toString() ?? '');
    _aciklamaCtrl = TextEditingController(text: s?['aciklama']?.toString() ?? '');
    _otomatik = s != null ? ((s['otomatik_gonder'] as num?)?.toInt() == 1 || s['otomatik_gonder'] == true) : true;
    _saatSonra = (s?['gonder_saat_sonra'] as num?)?.toInt() ?? 0;
    _varsayilan = s != null && ((s['varsayilan'] as num?)?.toInt() == 1 || s['varsayilan'] == true);
    _aktif = s == null ? true : ((s['aktif'] as num?)?.toInt() == 1 || s['aktif'] == true);

    // Odul ayarlari
    _odulTipi = s?['odul_tipi']?.toString() ?? 'yok';
    if (!['yok', 'kupon', 'puan'].contains(_odulTipi)) _odulTipi = 'yok';
    _odulKuponIndirimTipi = (s?['odul_kupon_indirim_tipi']?.toString() == 'tutar') ? 'tutar' : 'yuzde';
    _odulDegerCtrl = TextEditingController(text: _numStr(s?['odul_kupon_deger']));
    _odulGecerlilikCtrl = TextEditingController(text: s == null ? '30' : _numStr(s['odul_kupon_gecerlilik_gun']));
    _odulPuanCtrl = TextEditingController(text: _numStr(s?['odul_puan']));
    _odulBaslikCtrl = TextEditingController(text: s?['odul_baslik']?.toString() ?? '');

    final raw = s?['sorular_json'];
    if (raw != null && raw.toString().isNotEmpty) {
      try {
        final list = json.decode(raw.toString());
        if (list is List) {
          _sorular = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      } catch (_) {}
    }
    if (_sorular.isEmpty) {
      _sorular = [
        {'tip': 'nps', 'baslik': 'Bizi bir arkadaşınıza tavsiye eder misiniz? (0-10)', 'zorunlu': true},
        {'tip': 'csat_yildiz', 'baslik': 'Hizmetimizden ne kadar memnun kaldınız?', 'zorunlu': true},
        {'tip': 'uzun_metin', 'baslik': 'Eklemek istediğiniz bir görüş var mı?', 'zorunlu': false},
      ];
    }
  }

  @override
  void dispose() {
    _adCtrl.dispose();
    _aciklamaCtrl.dispose();
    _odulDegerCtrl.dispose();
    _odulGecerlilikCtrl.dispose();
    _odulPuanCtrl.dispose();
    _odulBaslikCtrl.dispose();
    super.dispose();
  }

  // Sayisal degeri temiz string'e cevirir (10.0 -> "10", 10.5 -> "10.5", null -> "")
  String _numStr(dynamic v) {
    if (v == null) return '';
    final d = (v is num) ? v.toDouble() : double.tryParse(v.toString());
    if (d == null) return '';
    if (d == d.roundToDouble()) return d.toInt().toString();
    return d.toString();
  }

  Future<void> _kaydet() async {
    if (_adCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Şablon adı zorunlu'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_sorular.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('En az 1 soru ekleyin'), backgroundColor: Colors.red),
      );
      return;
    }
    // Odul dogrulama: tip secildiyse degeri girilmis olmali
    final odulDeger = double.tryParse(_odulDegerCtrl.text.trim().replaceAll(',', '.')) ?? 0;
    final odulPuan = double.tryParse(_odulPuanCtrl.text.trim().replaceAll(',', '.')) ?? 0;
    if (_odulTipi == 'kupon' && odulDeger <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kupon ödülü için geçerli bir indirim değeri girin'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_odulTipi == 'puan' && odulPuan <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Puan ödülü için geçerli bir puan değeri girin'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _kaydediliyor = true);
    final data = {
      'ad': _adCtrl.text.trim(),
      'aciklama': _aciklamaCtrl.text.trim(),
      'sorular_json': json.encode(_sorular),
      'otomatik_gonder': _otomatik,
      'gonder_saat_sonra': _saatSonra,
      'varsayilan': _varsayilan,
      'odul_tipi': _odulTipi,
      if (_odulTipi == 'kupon') ...{
        'odul_kupon_indirim_tipi': _odulKuponIndirimTipi,
        'odul_kupon_deger': odulDeger,
        'odul_kupon_gecerlilik_gun': int.tryParse(_odulGecerlilikCtrl.text.trim()) ?? 0,
        'odul_baslik': _odulBaslikCtrl.text.trim(),
      },
      if (_odulTipi == 'puan') ...{
        'odul_puan': odulPuan,
        'odul_baslik': _odulBaslikCtrl.text.trim(),
      },
    };

    bool ok = false;
    if (widget.sablon == null) {
      final r = await anketSablonOlustur(_salonId, data);
      ok = r != null && r['basarili'] == true;
    } else {
      data['aktif'] = _aktif;
      ok = await anketSablonGuncelle(_salonId, (widget.sablon!['id'] as num).toInt(), data);
    }

    if (!mounted) return;
    setState(() => _kaydediliyor = false);
    if (ok) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kaydetme hatası'), backgroundColor: Colors.red),
      );
    }
  }

  void _soruEkle(String tip) {
    setState(() {
      _sorular.add({
        'tip': tip,
        'baslik': '',
        'zorunlu': false,
        if (tip == 'tek_secim' || tip == 'cok_secim') 'secenekler': <String>['Seçenek 1', 'Seçenek 2'],
      });
    });
  }

  void _soruSil(int i) {
    setState(() => _sorular.removeAt(i));
  }

  void _soruTasi(int from, int to) {
    if (to < 0 || to >= _sorular.length) return;
    setState(() {
      final item = _sorular.removeAt(from);
      _sorular.insert(to, item);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Color.alphaBlend(scheme.primary.withValues(alpha: 0.32), Colors.white),
            Color.alphaBlend(scheme.tertiary.withValues(alpha: 0.06), Colors.white),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: scheme.onSurface),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            widget.sablon == null ? 'Yeni Şablon' : 'Şablonu Düzenle',
            style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w800, fontSize: 20),
          ),
          actions: [
            IconButton(
              onPressed: _kaydediliyor ? null : _kaydet,
              icon: _kaydediliyor
                  ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(Icons.check, color: scheme.primary),
            ),
          ],
        ),
        body: ListView(
          padding: EdgeInsets.fromLTRB(12, 0, 12, 80),
          children: [
            _kart(scheme, 'Temel Bilgiler', [
              TextField(
                controller: _adCtrl,
                decoration: InputDecoration(labelText: 'Şablon Adı', border: OutlineInputBorder()),
              ),
              SizedBox(height: 12),
              TextField(
                controller: _aciklamaCtrl,
                maxLines: 2,
                decoration: InputDecoration(labelText: 'Açıklama (opsiyonel)', border: OutlineInputBorder()),
              ),
            ]),
            SizedBox(height: 12),
            _kart(scheme, 'Otomatik Gönderim', [
              SwitchListTile(
                value: _otomatik,
                title: Text('Hizmet süresi sonunda SMS gönder'),
                subtitle: Text('Randevu bittiği anda müşteriye anket linki SMS olarak gider', style: TextStyle(fontSize: 11)),
                onChanged: (v) => setState(() => _otomatik = v),
                contentPadding: EdgeInsets.zero,
              ),
              if (_otomatik) ...[
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.bolt, size: 16, color: scheme.primary),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _saatSonra == 0
                              ? 'Hizmet süresi sonunda SMS gider (müşteri salondan çıkmadan)'
                              : 'Hizmet süresi bitiminden $_saatSonra saat sonra SMS gider',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: scheme.primary),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Text('Gecikme: '),
                    SizedBox(
                      width: 70,
                      child: TextField(
                        keyboardType: TextInputType.number,
                        controller: TextEditingController(text: '$_saatSonra'),
                        onChanged: (v) => setState(() => _saatSonra = int.tryParse(v) ?? 0),
                        decoration: InputDecoration(border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                      ),
                    ),
                    Text(' saat (0 = hemen)'),
                  ],
                ),
              ],
              SwitchListTile(
                value: _varsayilan,
                title: Text('Varsayılan şablon yap'),
                subtitle: Text('Otomatik gönderim için bu şablon kullanılır', style: TextStyle(fontSize: 11)),
                onChanged: (v) => setState(() => _varsayilan = v),
                contentPadding: EdgeInsets.zero,
              ),
              if (widget.sablon != null)
                SwitchListTile(
                  value: _aktif,
                  title: Text('Aktif'),
                  onChanged: (v) => setState(() => _aktif = v),
                  contentPadding: EdgeInsets.zero,
                ),
            ]),
            SizedBox(height: 12),
            _kart(scheme, 'Anketi Tamamlayana Ödül', [
              Text(
                'Anketi dolduran müşteriye otomatik kupon veya puan verin. Tamamlama oranını artırır; davet mesajında da otomatik vurgulanır. (Yalnızca kayıtlı müşteriye, herkese; puanına bakılmaz.)',
                style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
              ),
              SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  _odulChip(scheme, 'yok', 'Ödül yok'),
                  _odulChip(scheme, 'kupon', 'İndirim Kuponu'),
                  _odulChip(scheme, 'puan', 'Sadakat Puanı'),
                ],
              ),
              if (_odulTipi == 'kupon') ...[
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AramaliDropdownFormField<String>(
                        value: _odulKuponIndirimTipi,
                        decoration: InputDecoration(labelText: 'İndirim Tipi', border: OutlineInputBorder(), isDense: true),
                        items: [
                          DropdownMenuItem(value: 'yuzde', child: Text('Yüzde (%)')),
                          DropdownMenuItem(value: 'tutar', child: Text('Tutar (₺)')),
                        ],
                        onChanged: (v) => setState(() => _odulKuponIndirimTipi = v ?? 'yuzde'),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _odulDegerCtrl,
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Değer',
                          border: OutlineInputBorder(),
                          isDense: true,
                          suffixText: _odulKuponIndirimTipi == 'tutar' ? '₺' : '%',
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                TextField(
                  controller: _odulGecerlilikCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Geçerlilik (gün)',
                    hintText: 'Boş = süresiz',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ],
              if (_odulTipi == 'puan') ...[
                SizedBox(height: 12),
                TextField(
                  controller: _odulPuanCtrl,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Verilecek Puan',
                    hintText: 'Örn: 50',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ],
              if (_odulTipi != 'yok') ...[
                SizedBox(height: 10),
                TextField(
                  controller: _odulBaslikCtrl,
                  decoration: InputDecoration(
                    labelText: 'Ödül Başlığı (opsiyonel)',
                    hintText: 'Boş = otomatik (örn: %10 İndirim)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ],
            ]),
            SizedBox(height: 16),
            _sectionHeader(scheme, 'Sorular (${_sorular.length})'),
            SizedBox(height: 8),
            ..._sorular.asMap().entries.map((e) => _soruKart(scheme, e.key, e.value)),
            SizedBox(height: 16),
            _sectionHeader(scheme, 'Yeni Soru Ekle'),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _soruTipleri.map((t) {
                return ActionChip(
                  avatar: Icon(t['icon'] as IconData, size: 16, color: scheme.primary),
                  label: Text(t['lbl'] as String, style: TextStyle(fontSize: 12)),
                  onPressed: () => _soruEkle(t['tip'] as String),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: scheme.primary.withValues(alpha: 0.20)),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kart(ColorScheme scheme, String title, List<Widget> children) {
    return Container(
      margin: EdgeInsets.only(top: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: scheme.primary.withValues(alpha: 0.04), blurRadius: 12, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _sectionHeader(ColorScheme scheme, String title) {
    return Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16));
  }

  Widget _odulChip(ColorScheme scheme, String value, String label) {
    final selected = _odulTipi == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12.5, color: selected ? Colors.white : scheme.onSurface)),
      selected: selected,
      selectedColor: scheme.primary,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: scheme.primary.withValues(alpha: 0.25)),
      ),
      onSelected: (_) => setState(() => _odulTipi = value),
    );
  }

  Widget _soruKart(ColorScheme scheme, int i, Map<String, dynamic> soru) {
    final tip = soru['tip']?.toString() ?? 'metin';
    final tipMeta = _soruTipleri.firstWhere((t) => t['tip'] == tip, orElse: () => _soruTipleri.first);
    final secenekler = (soru['secenekler'] as List?)?.cast<String>() ?? [];

    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: scheme.primary.withValues(alpha: 0.04), blurRadius: 10, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(tipMeta['icon'] as IconData, size: 18, color: scheme.primary),
              SizedBox(width: 6),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(tipMeta['lbl'] as String, style: TextStyle(color: scheme.primary, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
              Spacer(),
              IconButton(
                icon: Icon(Icons.arrow_upward, size: 18),
                onPressed: i > 0 ? () => _soruTasi(i, i - 1) : null,
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                icon: Icon(Icons.arrow_downward, size: 18),
                onPressed: i < _sorular.length - 1 ? () => _soruTasi(i, i + 1) : null,
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, size: 18, color: Colors.red),
                onPressed: () => _soruSil(i),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          SizedBox(height: 8),
          TextField(
            controller: TextEditingController(text: soru['baslik']?.toString() ?? ''),
            onChanged: (v) => soru['baslik'] = v,
            decoration: InputDecoration(
              labelText: tip == 'bolum_basligi' ? 'Başlık metni' : 'Soru metni',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          if (tip == 'tek_secim' || tip == 'cok_secim') ...[
            SizedBox(height: 8),
            ...secenekler.asMap().entries.map((e) {
              return Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: TextEditingController(text: e.value),
                        onChanged: (v) => secenekler[e.key] = v,
                        decoration: InputDecoration(
                          labelText: 'Seçenek ${e.key + 1}',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.remove_circle_outline, color: Colors.red, size: 18),
                      onPressed: () {
                        setState(() {
                          secenekler.removeAt(e.key);
                          soru['secenekler'] = secenekler;
                        });
                      },
                    ),
                  ],
                ),
              );
            }),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  secenekler.add('Seçenek ${secenekler.length + 1}');
                  soru['secenekler'] = secenekler;
                });
              },
              icon: Icon(Icons.add, size: 16),
              label: Text('Seçenek Ekle'),
            ),
          ],
          if (tip != 'bolum_basligi' && tip != 'bilgi_metni')
            CheckboxListTile(
              value: soru['zorunlu'] == true,
              title: Text('Zorunlu', style: TextStyle(fontSize: 13)),
              onChanged: (v) => setState(() => soru['zorunlu'] = v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
        ],
      ),
    );
  }
}

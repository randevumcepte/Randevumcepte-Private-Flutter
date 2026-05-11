import 'package:flutter/material.dart';
import 'package:randevu_sistem/Backend/backend.dart';

class CarkYonetimiPage extends StatefulWidget {
  final dynamic isletmebilgi;
  final int kullanicirolu;
  const CarkYonetimiPage({Key? key, required this.isletmebilgi, required this.kullanicirolu}) : super(key: key);

  @override
  State<CarkYonetimiPage> createState() => _CarkYonetimiPageState();
}

class _CarkYonetimiPageState extends State<CarkYonetimiPage> with TickerProviderStateMixin {
  late final TabController _tab;
  late final String _salonId;

  // Çark kurulumu
  bool _sistemLoading = false;
  int _carkAktif = 1;
  List<Map<String, dynamic>> _dilimler = [];

  // Kazananlar
  bool _kazLoading = false;
  Map<String, dynamic>? _kazData;
  String _kazFiltre = 'tumu';

  // Hatırlatma
  bool _hatLoading = false;
  Map<String, dynamic>? _hatData;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _salonId = widget.isletmebilgi['id'].toString();
    _yukleSistem();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _yukleSistem() async {
    setState(() => _sistemLoading = true);
    final r = await carkAdminSistemGetir(_salonId);
    if (!mounted) return;
    if (r != null) {
      _carkAktif = (r['sistem']?['aktifmi'] as num?)?.toInt() ?? 1;
      _dilimler = ((r['dilimler'] as List?) ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      if (_dilimler.isEmpty) {
        _dilimler = _ornekDilimler();
      }
    }
    setState(() => _sistemLoading = false);
  }

  List<Map<String, dynamic>> _ornekDilimler() {
    return [
      {'name': '%10 İndirim', 'probability': 100, 'color': '#6c5ce7', 'tip': 'hizmet_indirimi', 'deger': 10, 'kupon_mu': 1},
      {'name': 'Tekrar Dene', 'probability': 0, 'color': '#a29bfe', 'tip': 'tekrar_dene', 'deger': null, 'kupon_mu': 0},
      {'name': '50 Puan', 'probability': 0, 'color': '#fd79a8', 'tip': 'puan', 'deger': 50, 'kupon_mu': 0},
      {'name': 'Boş', 'probability': 0, 'color': '#fdcb6e', 'tip': 'bos', 'deger': null, 'kupon_mu': 0},
      {'name': '%5 İndirim', 'probability': 0, 'color': '#00b894', 'tip': 'hizmet_indirimi', 'deger': 5, 'kupon_mu': 1},
      {'name': 'Boş', 'probability': 0, 'color': '#e17055', 'tip': 'bos', 'deger': null, 'kupon_mu': 0},
    ];
  }

  Future<void> _yukleKazananlar() async {
    setState(() => _kazLoading = true);
    final r = await carkAdminKazananlar(_salonId, filtre: _kazFiltre);
    if (!mounted) return;
    setState(() {
      _kazData = r;
      _kazLoading = false;
    });
  }

  Future<void> _yukleHatirlatma() async {
    if (_hatData != null) return;
    setState(() => _hatLoading = true);
    final r = await carkAdminHatirlatmaGetir(_salonId);
    if (!mounted) return;
    setState(() {
      _hatData = r;
      _hatLoading = false;
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
            'Çark-ı Felek',
            style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w800, fontSize: 22, letterSpacing: -0.3),
          ),
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(56),
            child: Container(
              margin: EdgeInsets.fromLTRB(12, 0, 12, 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: scheme.primary.withValues(alpha: 0.05), blurRadius: 12, offset: Offset(0, 4)),
                ],
              ),
              child: TabBar(
                controller: _tab,
                indicatorColor: scheme.primary,
                indicatorWeight: 3,
                labelColor: scheme.primary,
                unselectedLabelColor: Colors.grey,
                labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                tabs: [
                  Tab(icon: Icon(Icons.casino, size: 20), text: 'Çark'),
                  Tab(icon: Icon(Icons.card_giftcard, size: 20), text: 'Kazananlar'),
                  Tab(icon: Icon(Icons.notifications_active, size: 20), text: 'SMS'),
                ],
                onTap: (i) {
                  if (i == 1) _yukleKazananlar();
                  if (i == 2) _yukleHatirlatma();
                },
              ),
            ),
          ),
        ),
        body: TabBarView(
          controller: _tab,
          children: [
            _carkTab(scheme),
            _kazananlarTab(scheme),
            _hatirlatmaTab(scheme),
          ],
        ),
      ),
    );
  }

  // ============ CARK TAB ============

  Widget _carkTab(ColorScheme scheme) {
    if (_sistemLoading) return Center(child: CircularProgressIndicator());

    final toplam = _dilimler.fold<int>(0, (s, d) => s + ((d['probability'] as num?)?.toInt() ?? 0));
    final kazanan = _dilimler.where((d) => ((d['probability'] as num?)?.toInt() ?? 0) == 100).length;
    final valid = toplam == 100 && kazanan == 1 && _dilimler.length >= 6;

    return ListView(
      padding: EdgeInsets.fromLTRB(12, 12, 12, 80),
      children: [
        _kart(scheme,
            title: 'Çark Durumu',
            children: [
              SwitchListTile(
                value: _carkAktif == 1,
                title: Text('Çark Aktif'),
                subtitle: Text('Pasifse müşteriler çark çeviremez', style: TextStyle(fontSize: 11)),
                onChanged: (v) async {
                  setState(() => _carkAktif = v ? 1 : 0);
                  await carkAdminAktifToggle(_salonId, v);
                },
                contentPadding: EdgeInsets.zero,
              ),
            ]),
        SizedBox(height: 12),
        _kart(scheme, title: 'Doğrulama', children: [
          Row(
            children: [
              Icon(valid ? Icons.check_circle : Icons.warning, color: valid ? Colors.green : Colors.orange),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  valid
                      ? 'Çark kurulumu geçerli (toplam %100, 1 kazanan, ${_dilimler.length} dilim)'
                      : 'Geçersiz: en az 6 dilim, tam 1 dilim 100, toplam 100 olmalı (şu an toplam $toplam, kazanan $kazanan)',
                  style: TextStyle(fontSize: 12, color: valid ? Colors.green.shade700 : Colors.orange.shade700),
                ),
              ),
            ],
          ),
        ]),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: Text('Dilimler (${_dilimler.length})', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
            TextButton.icon(
              onPressed: () => setState(() => _dilimler.add({
                'name': 'Dilim ${_dilimler.length + 1}',
                'probability': 0,
                'color': '#${(0xFF6c5ce7 + _dilimler.length * 0x1010).toRadixString(16)}',
                'tip': 'bos',
                'deger': null,
                'kupon_mu': 0,
              })),
              icon: Icon(Icons.add),
              label: Text('Ekle'),
            ),
          ],
        ),
        ..._dilimler.asMap().entries.map((e) => _dilimKart(scheme, e.key, e.value)),
        SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: valid ? _kaydet : null,
          icon: Icon(Icons.save),
          label: Text('Çarkı Kaydet'),
          style: ElevatedButton.styleFrom(
            backgroundColor: scheme.primary,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            disabledBackgroundColor: Colors.grey,
          ),
        ),
      ],
    );
  }

  Color _hexToColor(String? hex) {
    if (hex == null || hex.isEmpty) return Colors.purple;
    final h = hex.replaceAll('#', '');
    if (h.length != 6) return Colors.purple;
    return Color(int.parse('FF$h', radix: 16));
  }

  Widget _dilimKart(ColorScheme scheme, int i, Map<String, dynamic> d) {
    final tip = d['tip']?.toString() ?? 'bos';
    final color = _hexToColor(d['color']?.toString());

    return Container(
      margin: EdgeInsets.only(bottom: 8),
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
              Container(width: 18, height: 18, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              SizedBox(width: 8),
              Text('Dilim ${i + 1}', style: TextStyle(fontWeight: FontWeight.w800)),
              Spacer(),
              IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.red, size: 18),
                onPressed: () => setState(() => _dilimler.removeAt(i)),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          SizedBox(height: 8),
          TextField(
            controller: TextEditingController(text: d['name']?.toString() ?? ''),
            onChanged: (v) => d['name'] = v,
            decoration: InputDecoration(labelText: 'Ödül Adı', border: OutlineInputBorder(), isDense: true),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: tip,
                  decoration: InputDecoration(labelText: 'Tip', border: OutlineInputBorder(), isDense: true),
                  items: [
                    DropdownMenuItem(value: 'puan', child: Text('Puan')),
                    DropdownMenuItem(value: 'hizmet_indirimi', child: Text('Hizmet İnd. (%)')),
                    DropdownMenuItem(value: 'urun_indirimi', child: Text('Ürün İnd. (%)')),
                    DropdownMenuItem(value: 'tekrar_dene', child: Text('Tekrar Dene')),
                    DropdownMenuItem(value: 'bos', child: Text('Boş')),
                  ],
                  onChanged: (v) => setState(() {
                    d['tip'] = v;
                    if (v == 'hizmet_indirimi' || v == 'urun_indirimi') {
                      d['kupon_mu'] = 1;
                    } else {
                      d['kupon_mu'] = 0;
                      if (v == 'tekrar_dene' || v == 'bos') d['deger'] = null;
                    }
                  }),
                ),
              ),
              SizedBox(width: 8),
              SizedBox(
                width: 100,
                child: TextField(
                  controller: TextEditingController(text: d['deger']?.toString() ?? ''),
                  keyboardType: TextInputType.number,
                  enabled: tip == 'puan' || tip == 'hizmet_indirimi' || tip == 'urun_indirimi',
                  onChanged: (v) => d['deger'] = double.tryParse(v),
                  decoration: InputDecoration(labelText: 'Değer', border: OutlineInputBorder(), isDense: true),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              SizedBox(
                width: 90,
                child: TextField(
                  controller: TextEditingController(text: '${d['probability'] ?? 0}'),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => d['probability'] = int.tryParse(v) ?? 0,
                  decoration: InputDecoration(labelText: 'Olasılık', border: OutlineInputBorder(), isDense: true, suffixText: '%'),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: ['#6c5ce7', '#a29bfe', '#fd79a8', '#fdcb6e', '#00b894', '#e17055', '#74b9ff', '#55efc4'].map((c) {
                    final selected = (d['color']?.toString() ?? '').toLowerCase() == c.toLowerCase();
                    return GestureDetector(
                      onTap: () => setState(() => d['color'] = c),
                      child: Container(
                        width: 24, height: 24,
                        decoration: BoxDecoration(
                          color: _hexToColor(c),
                          shape: BoxShape.circle,
                          border: Border.all(color: selected ? Colors.black : Colors.transparent, width: 2),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          if ((d['probability'] as num?)?.toInt() == 100)
            Padding(
              padding: EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Icon(Icons.emoji_events, color: Colors.amber.shade700, size: 14),
                  SizedBox(width: 4),
                  Text('KAZANAN DİLİM', style: TextStyle(color: Colors.amber.shade700, fontWeight: FontWeight.w800, fontSize: 11)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _kaydet() async {
    final r = await carkAdminDilimKaydet(_salonId, _dilimler, aktifmi: _carkAktif);
    if (!mounted) return;
    if (r != null && r['basarili'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Çark kaydedildi'), backgroundColor: Colors.green));
      _yukleSistem();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r?['mesaj'] ?? 'Kayıt hatası'), backgroundColor: Colors.red));
    }
  }

  // ============ KAZANANLAR TAB ============

  Widget _kazananlarTab(ColorScheme scheme) {
    if (_kazLoading) return Center(child: CircularProgressIndicator());
    if (_kazData == null) {
      return Center(
        child: TextButton.icon(onPressed: _yukleKazananlar, icon: Icon(Icons.refresh), label: Text('Yükle')),
      );
    }
    final ozet = _kazData!['ozet'] as Map?;
    final odulluler = (_kazData!['odulluler'] as List?) ?? [];
    final users = (_kazData!['users'] as Map?) ?? {};

    return RefreshIndicator(
      onRefresh: _yukleKazananlar,
      child: ListView(
        padding: EdgeInsets.fromLTRB(12, 12, 12, 80),
        children: [
          _ozetCardlar(scheme, ozet),
          SizedBox(height: 12),
          _kuponDogrulaButon(scheme),
          SizedBox(height: 12),
          _kazFiltreChips(scheme),
          SizedBox(height: 12),
          if (odulluler.isEmpty)
            Container(
              padding: EdgeInsets.all(30),
              alignment: Alignment.center,
              child: Column(children: [Icon(Icons.inbox_outlined, size: 48, color: Colors.grey), SizedBox(height: 8), Text('Kupon yok')]),
            )
          else
            ...odulluler.map((o) => _kuponSatiri(scheme, o as Map<String, dynamic>, users)),
        ],
      ),
    );
  }

  Widget _ozetCardlar(ColorScheme scheme, Map? ozet) {
    final t = (ozet?['toplam_cevirme'] as num?)?.toInt() ?? 0;
    final b = (ozet?['bugun_cevirme'] as num?)?.toInt() ?? 0;
    final km = (ozet?['kullanilmamis'] as num?)?.toInt() ?? 0;
    final ku = (ozet?['kullanilmis'] as num?)?.toInt() ?? 0;
    return Row(
      children: [
        Expanded(child: _miniStat('Toplam', '$t', scheme.primary)),
        SizedBox(width: 6),
        Expanded(child: _miniStat('Bugün', '$b', Colors.blue.shade600)),
        SizedBox(width: 6),
        Expanded(child: _miniStat('Bekleyen', '$km', Colors.orange.shade600)),
        SizedBox(width: 6),
        Expanded(child: _miniStat('Kullanılmış', '$ku', Colors.green.shade600)),
      ],
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: color)),
          Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _kuponDogrulaButon(ColorScheme scheme) {
    return ElevatedButton.icon(
      onPressed: _kuponDogrulaDialog,
      icon: Icon(Icons.qr_code_scanner),
      label: Text('Kupon Kodu Doğrula'),
      style: ElevatedButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Future<void> _kuponDogrulaDialog() async {
    final ctrl = TextEditingController();
    final scheme = Theme.of(context).colorScheme;
    await showDialog(
      context: context,
      builder: (c) => StatefulBuilder(builder: (c, setSt) {
        Map<String, dynamic>? sonuc;
        bool yuklu = false;
        return AlertDialog(
          title: Text('Kupon Doğrula'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrl,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(labelText: 'Kupon Kodu', border: OutlineInputBorder()),
              ),
              if (sonuc != null) ...[
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(color: scheme.primary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(sonuc!['odul']?['baslik']?.toString() ?? '-', style: TextStyle(fontWeight: FontWeight.w800)),
                      Text('Müşteri: ${sonuc!['odul']?['musteri_adi'] ?? '-'}'),
                      Text('Durum: ${sonuc!['odul']?['durum']}'),
                      Text('Geçerlilik: ${sonuc!['odul']?['gecerlilik']}'),
                      if (sonuc!['odul']?['durum'] == 'gecerli')
                        ElevatedButton(
                          onPressed: () async {
                            final r = await carkAdminKuponKullan(_salonId, (sonuc!['odul']['id'] as num).toInt());
                            if (mounted && r != null && r['basarili'] == true) {
                              Navigator.pop(c);
                              _yukleKazananlar();
                            }
                          },
                          child: Text('Kullanıldı Olarak İşaretle'),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: Text('Kapat')),
            ElevatedButton(
              onPressed: yuklu ? null : () async {
                setSt(() => yuklu = true);
                final r = await carkAdminKuponDogrula(_salonId, ctrl.text.trim());
                setSt(() {
                  sonuc = r;
                  yuklu = false;
                });
              },
              child: Text('Doğrula'),
            ),
          ],
        );
      }),
    );
  }

  Widget _kazFiltreChips(ColorScheme scheme) {
    final options = [
      {'val': 'tumu', 'lbl': 'Tümü'},
      {'val': 'gecerli', 'lbl': 'Geçerli'},
      {'val': 'kullanildi', 'lbl': 'Kullanıldı'},
      {'val': 'sure_doldu', 'lbl': 'Süresi Doldu'},
    ];
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: options.map((o) {
          final selected = _kazFiltre == o['val'];
          return Padding(
            padding: EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(o['lbl']!),
              selected: selected,
              onSelected: (_) {
                setState(() => _kazFiltre = o['val']!);
                _yukleKazananlar();
              },
              selectedColor: scheme.primary,
              labelStyle: TextStyle(
                color: selected ? Colors.white : scheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: scheme.primary.withValues(alpha: 0.15)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _kuponSatiri(ColorScheme scheme, Map<String, dynamic> o, Map users) {
    final kullanildi = ((o['kullanildi'] as num?)?.toInt() ?? 0) == 1;
    final user = users[o['user_id']?.toString()] ?? users[o['user_id']];
    final musteriAd = (user is Map ? user['name'] : null)?.toString() ?? 'Müşteri';

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: scheme.primary.withValues(alpha: 0.04), blurRadius: 10, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (kullanildi ? Colors.green : scheme.primary).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              kullanildi ? Icons.check_circle : Icons.card_giftcard,
              color: kullanildi ? Colors.green : scheme.primary,
              size: 22,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(o['baslik']?.toString() ?? '-', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                Text(musteriAd, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                Row(
                  children: [
                    Text('Kod: ', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    SelectableText(
                      o['kod']?.toString() ?? '',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: scheme.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!kullanildi)
            IconButton(
              icon: Icon(Icons.check, color: Colors.green),
              onPressed: () async {
                final r = await carkAdminKuponKullan(_salonId, (o['id'] as num).toInt());
                if (mounted && r != null && r['basarili'] == true) _yukleKazananlar();
              },
            )
          else
            IconButton(
              icon: Icon(Icons.undo, color: Colors.orange),
              onPressed: () async {
                final r = await carkAdminKuponKullan(_salonId, (o['id'] as num).toInt(), aksiyon: 'geri_al');
                if (mounted && r != null && r['basarili'] == true) _yukleKazananlar();
              },
            ),
        ],
      ),
    );
  }

  // ============ HATIRLATMA TAB ============

  Widget _hatirlatmaTab(ColorScheme scheme) {
    if (_hatLoading) return Center(child: CircularProgressIndicator());
    if (_hatData == null) {
      return Center(
        child: TextButton.icon(onPressed: _yukleHatirlatma, icon: Icon(Icons.refresh), label: Text('Yükle')),
      );
    }
    return _HatirlatmaFormu(
      salonId: _salonId,
      ayar: Map<String, dynamic>.from(_hatData!['ayar'] as Map),
      bugun: (_hatData!['bugun'] as num?)?.toInt() ?? 0,
      onKaydedildi: (yeni) {
        setState(() => _hatData = {'ayar': yeni, 'bugun': _hatData!['bugun']});
      },
    );
  }

  // ============ COMMON ============

  Widget _kart(ColorScheme scheme, {required String title, required List<Widget> children}) {
    return Container(
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
          SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _HatirlatmaFormu extends StatefulWidget {
  final String salonId;
  final Map<String, dynamic> ayar;
  final int bugun;
  final void Function(Map<String, dynamic>) onKaydedildi;
  const _HatirlatmaFormu({Key? key, required this.salonId, required this.ayar, required this.bugun, required this.onKaydedildi}) : super(key: key);

  @override
  State<_HatirlatmaFormu> createState() => _HatirlatmaFormuState();
}

class _HatirlatmaFormuState extends State<_HatirlatmaFormu> {
  late bool _aktif;
  late TextEditingController _s1, _s2, _s3, _ss;
  late TextEditingController _m1, _m2, _m3, _ms;
  Set<int> _gunler = {1, 2, 3, 4, 5, 6, 7};
  bool _kaydediliyor = false;

  @override
  void initState() {
    super.initState();
    final a = widget.ayar;
    _aktif = ((a['aktif'] as num?)?.toInt() ?? 0) == 1;
    _s1 = TextEditingController(text: a['saat_1']?.toString() ?? '10:00');
    _s2 = TextEditingController(text: a['saat_2']?.toString() ?? '15:00');
    _s3 = TextEditingController(text: a['saat_3']?.toString() ?? '20:00');
    _ss = TextEditingController(text: a['saat_son']?.toString() ?? '22:30');
    _m1 = TextEditingController(text: a['mesaj_1']?.toString() ?? '');
    _m2 = TextEditingController(text: a['mesaj_2']?.toString() ?? '');
    _m3 = TextEditingController(text: a['mesaj_3']?.toString() ?? '');
    _ms = TextEditingController(text: a['mesaj_son']?.toString() ?? '');
    final g = a['gonderim_gunleri'];
    if (g is List) _gunler = g.map((e) => (e as num).toInt()).toSet();
  }

  Future<void> _kaydet() async {
    setState(() => _kaydediliyor = true);
    final ok = await carkAdminHatirlatmaKaydet(widget.salonId, {
      'aktif': _aktif ? 1 : 0,
      'saat_1': _s1.text.trim(),
      'saat_2': _s2.text.trim(),
      'saat_3': _s3.text.trim(),
      'saat_son': _ss.text.trim(),
      'mesaj_1': _m1.text.trim(),
      'mesaj_2': _m2.text.trim(),
      'mesaj_3': _m3.text.trim(),
      'mesaj_son': _ms.text.trim(),
      'gonderim_gunleri': _gunler.toList(),
    });
    if (!mounted) return;
    setState(() => _kaydediliyor = false);
    if (ok) {
      widget.onKaydedildi({
        'aktif': _aktif ? 1 : 0,
        'saat_1': _s1.text.trim(),
        'saat_2': _s2.text.trim(),
        'saat_3': _s3.text.trim(),
        'saat_son': _ss.text.trim(),
        'mesaj_1': _m1.text.trim(),
        'mesaj_2': _m2.text.trim(),
        'mesaj_3': _m3.text.trim(),
        'mesaj_son': _ms.text.trim(),
        'gonderim_gunleri': _gunler.toList(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hatırlatma ayarları kaydedildi'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kaydetme hatası'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const gunIsimleri = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

    return ListView(
      padding: EdgeInsets.fromLTRB(12, 12, 12, 80),
      children: [
        _kartim(scheme, [
          SwitchListTile(
            value: _aktif,
            title: Text('Hatırlatma SMS\'leri Aktif'),
            subtitle: Text('Bugün ${widget.bugun} hatırlatma gönderildi', style: TextStyle(fontSize: 11)),
            onChanged: (v) => setState(() => _aktif = v),
            contentPadding: EdgeInsets.zero,
          ),
        ], title: 'Genel'),
        SizedBox(height: 12),
        _kartim(scheme, [
          Text('Hangi günlerde gönderilsin?', style: TextStyle(fontSize: 12, color: Colors.grey)),
          SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: List.generate(7, (i) {
              final gun = i + 1;
              final selected = _gunler.contains(gun);
              return ChoiceChip(
                label: Text(gunIsimleri[i]),
                selected: selected,
                onSelected: (v) {
                  setState(() {
                    if (v) {
                      _gunler.add(gun);
                    } else {
                      _gunler.remove(gun);
                    }
                  });
                },
                selectedColor: scheme.primary,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : scheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              );
            }),
          ),
        ], title: 'Gönderim Günleri'),
        SizedBox(height: 12),
        _asamaKart(scheme, 1, 'Saat 1', _s1, _m1),
        _asamaKart(scheme, 2, 'Saat 2', _s2, _m2),
        _asamaKart(scheme, 3, 'Saat 3', _s3, _m3),
        _asamaKart(scheme, 4, 'Son Hatırlatma', _ss, _ms),
        SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _kaydediliyor ? null : _kaydet,
          icon: _kaydediliyor
              ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Icon(Icons.save),
          label: Text(_kaydediliyor ? 'Kaydediliyor...' : 'Kaydet'),
          style: ElevatedButton.styleFrom(
            backgroundColor: scheme.primary,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }

  Widget _asamaKart(ColorScheme scheme, int n, String label, TextEditingController saat, TextEditingController mesaj) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(14),
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
              CircleAvatar(radius: 12, backgroundColor: scheme.primary, child: Text('$n', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12))),
              SizedBox(width: 8),
              Text(label, style: TextStyle(fontWeight: FontWeight.w800)),
              Spacer(),
              SizedBox(
                width: 90,
                child: TextField(
                  controller: saat,
                  decoration: InputDecoration(border: OutlineInputBorder(), isDense: true, hintText: 'HH:MM'),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          TextField(
            controller: mesaj,
            maxLines: 3,
            maxLength: 300,
            decoration: InputDecoration(
              labelText: 'Mesaj metni',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kartim(ColorScheme scheme, List<Widget> children, {required String title}) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: scheme.primary.withValues(alpha: 0.04), blurRadius: 12, offset: Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)), SizedBox(height: 8), ...children],
      ),
    );
  }
}

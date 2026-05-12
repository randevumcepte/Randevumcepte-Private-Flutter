import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:randevu_sistem/Backend/backend.dart';

class CarkYonetimiPage extends StatefulWidget {
  final dynamic isletmebilgi;
  final int kullanicirolu;
  const CarkYonetimiPage({Key? key, required this.isletmebilgi, required this.kullanicirolu}) : super(key: key);

  @override
  State<CarkYonetimiPage> createState() => _CarkYonetimiPageState();
}

class _CarkYonetimiPageState extends State<CarkYonetimiPage> with TickerProviderStateMixin, WidgetsBindingObserver {
  late final TabController _tab;
  late final String _salonId;

  // Çark kurulumu
  bool _sistemLoading = false;
  int _carkAktif = 1;
  List<Map<String, dynamic>> _dilimler = [];
  final GlobalKey<_CarkPreviewState> _carkKey = GlobalKey<_CarkPreviewState>();
  bool _ceviriliyor = false;
  Timer? _autoSyncTimer;

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
    WidgetsBinding.instance.addObserver(this);
    _yukleSistem();
    // Sayfa açıkken her 15 saniyede bir hafif senkron (web'de değişiklik olursa anlamak için)
    _autoSyncTimer = Timer.periodic(Duration(seconds: 15), (_) {
      if (_tab.index == 0 && !_ceviriliyor && mounted) {
        _yukleSistemSessiz();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted && !_ceviriliyor) {
      // Uygulama arka plandan döndüğünde çarkı yenile
      _yukleSistemSessiz();
    }
  }

  @override
  void dispose() {
    _autoSyncTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _tab.dispose();
    super.dispose();
  }

  /// Loading spinner göstermeden sessizce yeniden çek (sync için).
  Future<void> _yukleSistemSessiz() async {
    final r = await carkAdminSistemGetir(_salonId);
    if (!mounted || r == null) return;
    final yeniDilimler = ((r['dilimler'] as List?) ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    if (yeniDilimler.isEmpty) return;
    // Sadece gerçekten değişiklik varsa state'i güncelle
    final farkVar = yeniDilimler.length != _dilimler.length ||
        yeniDilimler.asMap().entries.any((e) {
          final eski = e.key < _dilimler.length ? _dilimler[e.key] : null;
          if (eski == null) return true;
          return eski['name'] != e.value['name'] ||
              eski['probability'] != e.value['probability'] ||
              eski['tip'] != e.value['tip'] ||
              eski['deger'] != e.value['deger'] ||
              eski['color'] != e.value['color'];
        });
    if (!farkVar) return;
    setState(() {
      _carkAktif = (r['sistem']?['aktifmi'] as num?)?.toInt() ?? _carkAktif;
      _dilimler = yeniDilimler;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [Icon(Icons.sync, color: Colors.white, size: 16), SizedBox(width: 8), Text('Çark verisi güncellendi (web tarafından)')]),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.blue.shade700,
      ),
    );
  }

  Future<void> _yukleSistem() async {
    setState(() => _sistemLoading = true);
    final r = await carkAdminSistemGetir(_salonId);
    if (!mounted) return;
    setState(() {
      if (r != null) {
        _carkAktif = (r['sistem']?['aktifmi'] as num?)?.toInt() ?? 1;
        _dilimler = ((r['dilimler'] as List?) ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
      if (_dilimler.isEmpty) _dilimler = _ornekDilimler();
      _sistemLoading = false;
    });
  }

  List<Map<String, dynamic>> _ornekDilimler() => [
        {'name': '%10 İndirim', 'probability': 100, 'color': '#6c5ce7', 'tip': 'hizmet_indirimi', 'deger': 10, 'kupon_mu': 1},
        {'name': 'Tekrar Dene', 'probability': 0, 'color': '#a29bfe', 'tip': 'tekrar_dene', 'deger': null, 'kupon_mu': 0},
        {'name': '50 Puan', 'probability': 0, 'color': '#fd79a8', 'tip': 'puan', 'deger': 50, 'kupon_mu': 0},
        {'name': 'Boş', 'probability': 0, 'color': '#fdcb6e', 'tip': 'bos', 'deger': null, 'kupon_mu': 0},
        {'name': '%5 İndirim', 'probability': 0, 'color': '#00b894', 'tip': 'hizmet_indirimi', 'deger': 5, 'kupon_mu': 1},
        {'name': 'Boş', 'probability': 0, 'color': '#e17055', 'tip': 'bos', 'deger': null, 'kupon_mu': 0},
      ];

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
                boxShadow: [BoxShadow(color: scheme.primary.withValues(alpha: 0.05), blurRadius: 12, offset: Offset(0, 4))],
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
                  Tab(icon: Icon(Icons.notifications_active, size: 20), text: 'Hatırlatma'),
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
    final yeterli = _dilimler.length >= 6;
    final valid = toplam == 100 && kazanan == 1 && yeterli;

    return ListView(
      padding: EdgeInsets.fromLTRB(12, 12, 12, 100),
      children: [
        // Görsel çark (animasyonlu)
        Container(
          height: 280,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: scheme.primary.withValues(alpha: 0.06), blurRadius: 14, offset: Offset(0, 4))],
          ),
          child: _CarkPreview(key: _carkKey, dilimler: _dilimler),
        ),
        SizedBox(height: 10),

        // Test Çevir butonu (büyük, çarkın hemen altında)
        ElevatedButton.icon(
          onPressed: (_dilimler.length >= 6 && !_ceviriliyor) ? _testCevir : null,
          icon: _ceviriliyor
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                )
              : Icon(Icons.refresh, size: 22),
          label: Text(
            _ceviriliyor ? 'Çark dönüyor...' : 'Test Çevir',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 0.3),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber.shade700,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            disabledBackgroundColor: Colors.grey.shade400,
            elevation: 3,
            shadowColor: Colors.amber.withValues(alpha: 0.4),
          ),
        ),
        SizedBox(height: 14),

        // Aktif/Pasif + doğrulama
        Container(
          padding: EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: scheme.primary.withValues(alpha: 0.04), blurRadius: 12, offset: Offset(0, 3))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                value: _carkAktif == 1,
                title: Text('Çark Aktif', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('Pasifken müşteriler çark çeviremez', style: TextStyle(fontSize: 11)),
                onChanged: (v) async {
                  setState(() => _carkAktif = v ? 1 : 0);
                  await carkAdminAktifToggle(_salonId, v);
                },
                contentPadding: EdgeInsets.zero,
              ),
              Divider(),
              Row(
                children: [
                  Icon(valid ? Icons.check_circle : Icons.warning_amber, color: valid ? Colors.green : Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      valid
                          ? 'Hazır: ${_dilimler.length} dilim, toplam %100, 1 kazanan'
                          : 'Eksik: ${!yeterli ? "En az 6 dilim olmalı (şu an ${_dilimler.length}). " : ""}'
                              '${kazanan != 1 ? "Tam 1 dilim 100 olmalı (şu an $kazanan). " : ""}'
                              '${toplam != 100 ? "Toplam %100 olmalı (şu an $toplam)." : ""}',
                      style: TextStyle(fontSize: 12, color: valid ? Colors.green.shade700 : Colors.orange.shade700, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 12),

        // Hızlı yardım butonu — otomatik 100% düzelt
        if (!valid)
          Container(
            margin: EdgeInsets.only(bottom: 12),
            child: OutlinedButton.icon(
              onPressed: _otomatikDuzelt,
              icon: Icon(Icons.auto_fix_high),
              label: Text('Olasılıkları Otomatik Düzelt (1 kazanan = %100)'),
              style: OutlinedButton.styleFrom(
                foregroundColor: scheme.primary,
                side: BorderSide(color: scheme.primary),
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

        // Dilim başlığı + Ekle
        Row(
          children: [
            Text('Dilimler (${_dilimler.length})', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            Spacer(),
            TextButton.icon(
              onPressed: _dilimEkle,
              icon: Icon(Icons.add_circle, size: 18),
              label: Text('Ekle'),
            ),
          ],
        ),
        SizedBox(height: 4),

        // Dilim listesi (her biri kendi StatefulWidget'ı, controller bug'ı yok)
        ..._dilimler.asMap().entries.map((e) => _DilimSatiri(
              key: ValueKey('dilim_${e.key}_${_dilimler.length}'),
              index: e.key,
              dilim: e.value,
              onSil: () => setState(() => _dilimler.removeAt(e.key)),
              onDegisti: () => setState(() {}),
            )),

        SizedBox(height: 16),

        // Kaydet
        ElevatedButton.icon(
          onPressed: valid ? _kaydet : null,
          icon: Icon(Icons.save),
          label: Text('Çarkı Kaydet'),
          style: ElevatedButton.styleFrom(
            backgroundColor: scheme.primary,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            disabledBackgroundColor: Colors.grey.shade400,
          ),
        ),
      ],
    );
  }

  void _dilimEkle() {
    setState(() => _dilimler.add({
          'name': 'Dilim ${_dilimler.length + 1}',
          'probability': 0,
          'color': _renkler[_dilimler.length % _renkler.length],
          'tip': 'bos',
          'deger': null,
          'kupon_mu': 0,
        }));
  }

  static const _renkler = ['#6c5ce7', '#a29bfe', '#fd79a8', '#fdcb6e', '#00b894', '#e17055', '#74b9ff', '#55efc4'];

  void _otomatikDuzelt() {
    setState(() {
      if (_dilimler.length < 6) {
        // 6'ya tamamla
        while (_dilimler.length < 6) {
          _dilimler.add({
            'name': 'Dilim ${_dilimler.length + 1}',
            'probability': 0,
            'color': _renkler[_dilimler.length % _renkler.length],
            'tip': 'bos',
            'deger': null,
            'kupon_mu': 0,
          });
        }
      }
      // İlk dilim kazanan, diğerleri 0
      for (var i = 0; i < _dilimler.length; i++) {
        _dilimler[i]['probability'] = i == 0 ? 100 : 0;
      }
    });
  }

  Future<void> _testCevir() async {
    if (_dilimler.length < 6) return;

    // Gerçek olasılıklara göre dilim seç
    final rand = math.Random();
    final toplam = _dilimler.fold<int>(0, (s, d) => s + ((d['probability'] as num?)?.toInt() ?? 0));
    int hedefIndex = 0;
    if (toplam > 0) {
      final r = rand.nextInt(toplam);
      int kumulatif = 0;
      for (var i = 0; i < _dilimler.length; i++) {
        kumulatif += ((_dilimler[i]['probability'] as num?)?.toInt() ?? 0);
        if (r < kumulatif) {
          hedefIndex = i;
          break;
        }
      }
    } else {
      hedefIndex = rand.nextInt(_dilimler.length);
    }

    setState(() => _ceviriliyor = true);
    HapticFeedback.mediumImpact();

    // Çark dönüş animasyonu (~4 saniye)
    await _carkKey.currentState?.cevirSonuc(hedefIndex);

    if (!mounted) return;
    setState(() => _ceviriliyor = false);
    HapticFeedback.heavyImpact();

    final sec = _dilimler[hedefIndex];
    final color = _hexToColor(sec['color']?.toString());

    // Sonuç dialogu
    showDialog(
      context: context,
      builder: (c) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: Icon(Icons.celebration, color: color, size: 36),
              ),
              SizedBox(height: 12),
              Text('Çark Durdu!', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              SizedBox(height: 6),
              Text(
                sec['name']?.toString() ?? '-',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: color),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              if (sec['tip'] != null && sec['tip'] != 'bos')
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    _tipText(sec['tip']?.toString() ?? '', sec['deger']),
                    style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
              SizedBox(height: 16),
              Text(
                'Bu bir simülasyondur. Gerçek dağıtımda olasılıklar geçerlidir.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(c),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('Tamam', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _tipText(String tip, dynamic deger) {
    switch (tip) {
      case 'puan': return '+ ${deger ?? '?'} Puan';
      case 'hizmet_indirimi': return '%${deger ?? '?'} Hizmet İndirimi';
      case 'urun_indirimi': return '%${deger ?? '?'} Ürün İndirimi';
      case 'tekrar_dene': return 'Tekrar Dene';
      default: return tip;
    }
  }

  Color _hexToColor(String? hex) {
    if (hex == null || hex.isEmpty) return Colors.purple;
    final h = hex.replaceAll('#', '');
    if (h.length != 6) return Colors.purple;
    return Color(int.parse('FF$h', radix: 16));
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
          ElevatedButton.icon(
            onPressed: _kuponDogrulaDialog,
            icon: Icon(Icons.qr_code_scanner),
            label: Text('Kupon Kodu Doğrula'),
            style: ElevatedButton.styleFrom(
              backgroundColor: scheme.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
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

  Future<void> _kuponDogrulaDialog() async {
    final ctrl = TextEditingController();
    Map<String, dynamic>? sonuc;
    bool yuklu = false;

    await showDialog(
      context: context,
      builder: (c) => StatefulBuilder(builder: (c, setSt) {
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
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(8)),
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
              onPressed: yuklu
                  ? null
                  : () async {
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
        boxShadow: [BoxShadow(color: scheme.primary.withValues(alpha: 0.04), blurRadius: 10, offset: Offset(0, 2))],
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
}

// ============================================================
// DILIM SATIRI — kendi state'i olan widget (TextController bug yok)
// ============================================================

class _DilimSatiri extends StatefulWidget {
  final int index;
  final Map<String, dynamic> dilim;
  final VoidCallback onSil;
  final VoidCallback onDegisti;
  const _DilimSatiri({Key? key, required this.index, required this.dilim, required this.onSil, required this.onDegisti}) : super(key: key);

  @override
  State<_DilimSatiri> createState() => _DilimSatiriState();
}

class _DilimSatiriState extends State<_DilimSatiri> {
  late TextEditingController _nameCtrl;
  late TextEditingController _degerCtrl;
  late TextEditingController _probCtrl;

  static const _renkler = ['#6c5ce7', '#a29bfe', '#fd79a8', '#fdcb6e', '#00b894', '#e17055', '#74b9ff', '#55efc4'];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.dilim['name']?.toString() ?? '');
    _degerCtrl = TextEditingController(text: widget.dilim['deger']?.toString() ?? '');
    _probCtrl = TextEditingController(text: '${widget.dilim['probability'] ?? 0}');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _degerCtrl.dispose();
    _probCtrl.dispose();
    super.dispose();
  }

  Color _hexToColor(String? hex) {
    if (hex == null || hex.isEmpty) return Colors.purple;
    final h = hex.replaceAll('#', '');
    if (h.length != 6) return Colors.purple;
    return Color(int.parse('FF$h', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tip = widget.dilim['tip']?.toString() ?? 'bos';
    final color = _hexToColor(widget.dilim['color']?.toString());
    final degerEnabled = tip == 'puan' || tip == 'hizmet_indirimi' || tip == 'urun_indirimi';
    final kazanan = (widget.dilim['probability'] as num?)?.toInt() == 100;

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: kazanan ? Border.all(color: Colors.amber.shade400, width: 2) : null,
        boxShadow: [BoxShadow(color: scheme.primary.withValues(alpha: 0.04), blurRadius: 10, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 22, height: 22, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              SizedBox(width: 8),
              Text('Dilim ${widget.index + 1}', style: TextStyle(fontWeight: FontWeight.w800)),
              if (kazanan) ...[
                SizedBox(width: 6),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.emoji_events, color: Colors.amber.shade700, size: 12),
                      SizedBox(width: 2),
                      Text('KAZANAN', style: TextStyle(color: Colors.amber.shade800, fontWeight: FontWeight.w800, fontSize: 10)),
                    ],
                  ),
                ),
              ],
              Spacer(),
              IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.red, size: 20),
                onPressed: widget.onSil,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            onChanged: (v) {
              widget.dilim['name'] = v;
              widget.onDegisti();
            },
            decoration: InputDecoration(labelText: 'Ödül Adı', border: OutlineInputBorder(), isDense: true),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: tip,
                  decoration: InputDecoration(labelText: 'Tip', border: OutlineInputBorder(), isDense: true),
                  items: [
                    DropdownMenuItem(value: 'puan', child: Text('Puan')),
                    DropdownMenuItem(value: 'hizmet_indirimi', child: Text('Hizmet İnd. (%)')),
                    DropdownMenuItem(value: 'urun_indirimi', child: Text('Ürün İnd. (%)')),
                    DropdownMenuItem(value: 'tekrar_dene', child: Text('Tekrar Dene')),
                    DropdownMenuItem(value: 'bos', child: Text('Boş')),
                  ],
                  onChanged: (v) {
                    setState(() {
                      widget.dilim['tip'] = v;
                      if (v == 'hizmet_indirimi' || v == 'urun_indirimi') {
                        widget.dilim['kupon_mu'] = 1;
                      } else {
                        widget.dilim['kupon_mu'] = 0;
                        if (v == 'tekrar_dene' || v == 'bos') {
                          widget.dilim['deger'] = null;
                          _degerCtrl.text = '';
                        }
                      }
                    });
                    widget.onDegisti();
                  },
                ),
              ),
              SizedBox(width: 8),
              SizedBox(
                width: 100,
                child: TextField(
                  controller: _degerCtrl,
                  keyboardType: TextInputType.number,
                  enabled: degerEnabled,
                  onChanged: (v) {
                    widget.dilim['deger'] = double.tryParse(v);
                    widget.onDegisti();
                  },
                  decoration: InputDecoration(labelText: 'Değer', border: OutlineInputBorder(), isDense: true),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              SizedBox(
                width: 100,
                child: TextField(
                  controller: _probCtrl,
                  keyboardType: TextInputType.number,
                  onChanged: (v) {
                    widget.dilim['probability'] = int.tryParse(v) ?? 0;
                    setState(() {});
                    widget.onDegisti();
                  },
                  decoration: InputDecoration(labelText: 'Olasılık', border: OutlineInputBorder(), isDense: true, suffixText: '%'),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: _renkler.map((c) {
                    final selected = (widget.dilim['color']?.toString() ?? '').toLowerCase() == c.toLowerCase();
                    return GestureDetector(
                      onTap: () {
                        setState(() => widget.dilim['color'] = c);
                        widget.onDegisti();
                      },
                      child: Container(
                        width: 26,
                        height: 26,
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
        ],
      ),
    );
  }
}

// ============================================================
// CARK PREVIEW — basit pasta dilim önizlemesi
// ============================================================

class _CarkPreview extends StatefulWidget {
  final List<Map<String, dynamic>> dilimler;
  const _CarkPreview({Key? key, required this.dilimler}) : super(key: key);

  @override
  State<_CarkPreview> createState() => _CarkPreviewState();
}

class _CarkPreviewState extends State<_CarkPreview> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  double _baseRotation = 0;
  Timer? _tickTimer;
  int _lastTickedSlice = -1;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: Duration(milliseconds: 4500));
    _anim = AlwaysStoppedAnimation(0);
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  /// Çarkı verilen dilim üzerinde durdur. ~4 saniye dönüş + yavaşlama.
  Future<void> cevirSonuc(int hedefIndex) async {
    if (widget.dilimler.isEmpty) return;
    final n = widget.dilimler.length;
    final sweep = 2 * math.pi / n;

    // Dilimin merkez açısı (0 = saat 12 yönü, pozitif saat yönünde)
    // Painter dilim 0'ı saat 12'den başlatıyor, dilim merkezi = i * sweep + sweep/2
    // İşaretçi saat 12'de. Çark döndüğünde, hedef dilim saat 12'ye gelsin.
    // Tam tur sayısı + son ayarlama
    final tamTurlar = 4 + math.Random().nextInt(2); // 4-5 tam tur
    // Hedefin saat 12'ye gelmesi için: rotation = (tamTurlar * 2π) - (hedef_merkez_açısı)
    final hedefMerkez = hedefIndex * sweep + sweep / 2;
    final hedefRotation = (tamTurlar * 2 * math.pi) - hedefMerkez;

    final baslangic = _baseRotation;
    final fark = hedefRotation - (baslangic % (2 * math.pi));

    _ctrl.reset();
    _anim = Tween<double>(begin: 0, end: fark).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutQuart),
    );

    // "Tick tick" hissi için her dilim geçişinde haptic
    _lastTickedSlice = -1;
    _ctrl.addListener(_haptickTick);
    await _ctrl.forward();
    _ctrl.removeListener(_haptickTick);
    _baseRotation = baslangic + fark;
  }

  void _haptickTick() {
    final n = widget.dilimler.length;
    if (n == 0) return;
    final sweep = 2 * math.pi / n;
    final donmus = _anim.value;
    final dilimGecis = (donmus / sweep).floor();
    if (dilimGecis != _lastTickedSlice) {
      _lastTickedSlice = dilimGecis;
      HapticFeedback.selectionClick();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (c, _) {
        final rot = (_baseRotation + (_anim.value));
        return CustomPaint(
          size: Size(220, 220),
          painter: _CarkPainter(widget.dilimler, rot),
        );
      },
    );
  }
}

class _CarkPainter extends CustomPainter {
  final List<Map<String, dynamic>> dilimler;
  final double rotation; // radian
  _CarkPainter(this.dilimler, [this.rotation = 0]);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;

    if (dilimler.isEmpty) {
      final paint = Paint()..color = Colors.grey.shade200;
      canvas.drawCircle(center, radius, paint);
      return;
    }

    final n = dilimler.length;
    final sweep = 2 * math.pi / n;

    // Çark gövdesini döndür (işaretçi sabit, çark döner)
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.translate(-center.dx, -center.dy);

    for (var i = 0; i < n; i++) {
      final paint = Paint()..color = _hexToColor(dilimler[i]['color']?.toString());
      final rect = Rect.fromCircle(center: center, radius: radius);
      final start = -math.pi / 2 + i * sweep;
      canvas.drawArc(rect, start, sweep, true, paint);

      // Dilim ayırıcı çizgi
      final sepPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawArc(rect, start, sweep, true, sepPaint);

      // İsim — dilim merkezine sığdır (saat 12 yönüne uzaktan okuyabilmek için döndür)
      final textSpan = TextSpan(
        text: (dilimler[i]['name']?.toString() ?? '').split(' ').first,
        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, shadows: [Shadow(color: Colors.black54, blurRadius: 3)]),
      );
      final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr, maxLines: 1, ellipsis: '…');
      tp.layout(maxWidth: radius * 0.8);
      final angle = start + sweep / 2;
      final tx = center.dx + math.cos(angle) * radius * 0.62;
      final ty = center.dy + math.sin(angle) * radius * 0.62;
      // Yazıyı dilim açısına göre döndür (saat 12'den okunsun)
      canvas.save();
      canvas.translate(tx, ty);
      canvas.rotate(angle + math.pi / 2);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }

    canvas.restore();

    // Dış çerçeve (dönmüyor)
    final framePaint = Paint()
      ..color = Colors.amber.shade400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    canvas.drawCircle(center, radius + 2, framePaint);

    // Merkez nokta
    final centerPaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, radius * 0.16, centerPaint);
    final centerBorder = Paint()
      ..color = Colors.amber.shade700
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius * 0.16, centerBorder);

    // İşaretçi (sabit, saat 12 yönünde)
    final pointer = Path()
      ..moveTo(center.dx, center.dy - radius + 6)
      ..lineTo(center.dx - 11, center.dy - radius - 16)
      ..lineTo(center.dx + 11, center.dy - radius - 16)
      ..close();
    canvas.drawPath(pointer, Paint()..color = Colors.red.shade700);
    canvas.drawPath(
      pointer,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  Color _hexToColor(String? hex) {
    if (hex == null || hex.isEmpty) return Colors.purple;
    final h = hex.replaceAll('#', '');
    if (h.length != 6) return Colors.purple;
    return Color(int.parse('FF$h', radix: 16));
  }

  @override
  bool shouldRepaint(_CarkPainter old) => old.dilimler != dilimler || old.rotation != rotation;
}

// ============================================================
// HATIRLATMA FORMU
// ============================================================

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

  @override
  void dispose() {
    _s1.dispose();
    _s2.dispose();
    _s3.dispose();
    _ss.dispose();
    _m1.dispose();
    _m2.dispose();
    _m3.dispose();
    _ms.dispose();
    super.dispose();
  }

  Future<void> _kaydet() async {
    setState(() => _kaydediliyor = true);
    final data = {
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
    };
    final ok = await carkAdminHatirlatmaKaydet(widget.salonId, data);
    if (!mounted) return;
    setState(() => _kaydediliyor = false);
    if (ok) {
      widget.onKaydedildi(data);
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
        boxShadow: [BoxShadow(color: scheme.primary.withValues(alpha: 0.04), blurRadius: 10, offset: Offset(0, 2))],
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
            decoration: InputDecoration(labelText: 'Mesaj metni', border: OutlineInputBorder()),
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

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:randevu_sistem/Backend/backend.dart';
import 'anket_sablon_duzenle.dart';

class AnketYonetimiPage extends StatefulWidget {
  final dynamic isletmebilgi;
  final int kullanicirolu;
  const AnketYonetimiPage({
    Key? key,
    required this.isletmebilgi,
    required this.kullanicirolu,
  }) : super(key: key);

  @override
  State<AnketYonetimiPage> createState() => _AnketYonetimiPageState();
}

class _AnketYonetimiPageState extends State<AnketYonetimiPage>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  late final String _salonId;

  // Sonuclar tab state
  int _gunFiltre = 30;
  bool _ozetLoading = false;
  Map<String, dynamic>? _ozet;
  bool _listLoading = false;
  List<Map<String, dynamic>> _gonderimler = [];

  // Sablonlar tab state
  bool _sablonLoading = false;
  List<Map<String, dynamic>> _sablonlar = [];

  // Ayarlar
  bool _ayarLoading = false;
  Map<String, dynamic>? _ayarlar;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 2 && _ayarlar == null && !_ayarLoading) {
        _yukleAyarlar();
      }
    });
    _salonId = widget.isletmebilgi['id'].toString();
    _yukleSonuclar();
    _yukleSablonlar();
    _yukleAyarlar();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _yukleSonuclar() async {
    setState(() {
      _ozetLoading = true;
      _listLoading = true;
    });
    final ozet = await anketOzet(_salonId, gun: _gunFiltre);
    final liste = await anketGonderimleri(_salonId, limit: 50, sadeceCevaplilar: true);
    if (!mounted) return;
    setState(() {
      _ozet = ozet;
      _gonderimler = liste ?? [];
      _ozetLoading = false;
      _listLoading = false;
    });
  }

  Future<void> _yukleSablonlar() async {
    setState(() => _sablonLoading = true);
    final liste = await anketSablonListesi(_salonId);
    if (!mounted) return;
    setState(() {
      _sablonlar = liste ?? [];
      _sablonLoading = false;
    });
  }

  Future<void> _yukleAyarlar() async {
    if (_ayarlar != null && !_ayarLoading) return;
    setState(() => _ayarLoading = true);
    final a = await anketAyarlarGetir(_salonId);
    if (!mounted) return;
    setState(() {
      // API null/hata dönse bile default değerlerle formu göster
      _ayarlar = a ??
          {
            'google_url': '',
            'google_review_esik_nps': 9,
            'google_review_esik_csat': 4.5,
            'kotu_puan_uyari_esik_nps': 6,
            'kotu_puan_uyari_esik_csat': 3.0,
          };
      _ayarLoading = false;
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
            'Anket Yönetimi',
            style: TextStyle(
              color: scheme.onSurface,
              fontWeight: FontWeight.w800,
              fontSize: 22,
              letterSpacing: -0.3,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(56),
            child: Container(
              margin: EdgeInsets.fromLTRB(12, 0, 12, 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: scheme.primary,
                indicatorWeight: 3,
                labelColor: scheme.primary,
                unselectedLabelColor: Colors.grey,
                labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                tabs: [
                  Tab(icon: Icon(Icons.bar_chart, size: 20), text: 'Sonuçlar'),
                  Tab(icon: Icon(Icons.description, size: 20), text: 'Şablonlar'),
                  Tab(icon: Icon(Icons.settings, size: 20), text: 'Ayarlar'),
                ],
                onTap: (i) {
                  if (i == 2) _yukleAyarlar();
                },
              ),
            ),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildSonuclarTab(scheme),
            _buildSablonlarTab(scheme),
            _buildAyarlarTab(scheme),
          ],
        ),
      ),
    );
  }

  // ============ SONUCLAR TAB ============

  Widget _buildSonuclarTab(ColorScheme scheme) {
    return RefreshIndicator(
      onRefresh: _yukleSonuclar,
      child: ListView(
        padding: EdgeInsets.fromLTRB(12, 12, 12, 80),
        children: [
          if (_ozet != null) _reputationBadge(scheme, _ozet!),
          _gunFiltreChips(scheme),
          SizedBox(height: 12),
          if (_ozetLoading)
            _loadingCard()
          else if (_ozet != null) ...[
            _ozetKart(scheme, _ozet!),
            SizedBox(height: 12),
            _reputationKartlar(scheme, _ozet!),
          ],
          SizedBox(height: 16),
          _sectionHeader(scheme, 'Son Cevaplar', Icons.list_alt),
          SizedBox(height: 8),
          if (_listLoading)
            _loadingCard()
          else if (_gonderimler.isEmpty)
            _emptyState('Henüz cevaplanmış anket yok.')
          else
            ..._gonderimler.map((g) => _gonderimSatiri(scheme, g)),
        ],
      ),
    );
  }

  Widget _reputationBadge(ColorScheme scheme, Map<String, dynamic> o) {
    final aktif = o['reputationPremiumAktif'] == true;
    final googleVar = o['googleUrlVar'] == true;
    if (!aktif && !googleVar) return SizedBox.shrink();

    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: aktif
              ? [Colors.amber.shade600, Colors.orange.shade700]
              : [Colors.grey.shade400, Colors.grey.shade600],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: (aktif ? Colors.orange : Colors.grey).withValues(alpha: 0.25), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.workspace_premium, color: Colors.white, size: 22),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  aktif ? 'Reputation Booster' : 'Reputation Booster (Pasif)',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                ),
                Text(
                  aktif
                      ? 'PREMIUM AKTİF — Google\'a otomatik yönlendirme + kötü puan uyarısı'
                      : 'Ayarlardan Google linkini girip aktifleştirebilirsiniz',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.92), fontSize: 11),
                ),
              ],
            ),
          ),
          if (aktif)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('AKTİF', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 10)),
            ),
        ],
      ),
    );
  }

  Widget _reputationKartlar(ColorScheme scheme, Map<String, dynamic> o) {
    final googleSay = (o['googleTiklamalar'] as num?)?.toInt() ?? 0;
    final kotuSay = (o['kotuPuanUyarilari'] as num?)?.toInt() ?? 0;

    return Row(
      children: [
        Expanded(
          child: _reputationMiniKart(
            scheme,
            ikon: Icons.thumb_up_alt,
            renk: Colors.green.shade600,
            baslik: 'Google\'a Yönlendirildi',
            sayi: googleSay,
            aciklama: 'Teşekkür edilecekler',
            filtre: 'google_tiklayan',
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _reputationMiniKart(
            scheme,
            ikon: Icons.warning_amber,
            renk: Colors.red.shade600,
            baslik: 'Düşük Puan Veren',
            sayi: kotuSay,
            aciklama: 'Özür dilenecekler',
            filtre: 'kotu_puan',
          ),
        ),
      ],
    );
  }

  Widget _reputationMiniKart(ColorScheme scheme,
      {required IconData ikon, required Color renk, required String baslik, required int sayi, required String aciklama, required String filtre}) {
    return InkWell(
      onTap: () => _reputationListeAc(filtre, baslik),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: EdgeInsets.all(12),
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
                Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(color: renk.withValues(alpha: 0.12), shape: BoxShape.circle),
                  child: Icon(ikon, color: renk, size: 16),
                ),
                Spacer(),
                Icon(Icons.chevron_right, color: Colors.grey, size: 18),
              ],
            ),
            SizedBox(height: 8),
            Text('$sayi', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: renk)),
            Text(baslik, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: scheme.onSurface)),
            Text(aciklama, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Future<void> _reputationListeAc(String filtre, String baslik) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (c, scroll) {
          return FutureBuilder<List<Map<String, dynamic>>?>(
            future: anketGonderimleri(_salonId, limit: 100, sadeceCevaplilar: true, filtre: filtre),
            builder: (c, snap) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  children: [
                    Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                    SizedBox(height: 12),
                    Text(baslik, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                    Text(
                      filtre == 'google_tiklayan'
                          ? 'Bu müşteriler Google\'a yorum bırakmak için tıkladı — teşekkür etmeyi unutmayın'
                          : 'Bu müşteriler düşük puan verdi — özür dileyip durumu telafi edebilirsiniz',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                    ),
                    SizedBox(height: 12),
                    Expanded(
                      child: snap.connectionState != ConnectionState.done
                          ? Center(child: CircularProgressIndicator())
                          : (snap.data == null || snap.data!.isEmpty)
                              ? Center(child: Text('Bu kategoride kayıt yok', style: TextStyle(color: Colors.grey)))
                              : ListView.builder(
                                  controller: scroll,
                                  itemCount: snap.data!.length,
                                  itemBuilder: (c, i) {
                                    final g = snap.data![i];
                                    return Padding(
                                      padding: EdgeInsets.only(bottom: 6),
                                      child: _gonderimSatiri(Theme.of(context).colorScheme, g),
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _gunFiltreChips(ColorScheme scheme) {
    final options = [
      {'val': 7, 'lbl': '7 gün'},
      {'val': 30, 'lbl': '30 gün'},
      {'val': 90, 'lbl': '90 gün'},
      {'val': 365, 'lbl': '1 yıl'},
    ];
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: options.map((o) {
          final selected = _gunFiltre == o['val'];
          return Padding(
            padding: EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(o['lbl'] as String),
              selected: selected,
              onSelected: (_) {
                setState(() => _gunFiltre = o['val'] as int);
                _yukleSonuclar();
              },
              selectedColor: scheme.primary,
              backgroundColor: Colors.white,
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

  Widget _ozetKart(ColorScheme scheme, Map<String, dynamic> o) {
    final cevapOrani = (o['cevapOrani'] is num) ? (o['cevapOrani'] as num).toDouble() : 0.0;
    final nps = o['ortNps'];
    final csat = o['ortCsat'];
    final promoter = (o['promoter'] as num?)?.toInt() ?? 0;
    final passive = (o['passive'] as num?)?.toInt() ?? 0;
    final detractor = (o['detractor'] as num?)?.toInt() ?? 0;
    final toplamCevap = (o['toplamCevap'] as num?)?.toInt() ?? 0;
    final toplamGonderim = (o['toplamGonderim'] as num?)?.toInt() ?? 0;
    final trend = (o['trend'] as List?)?.cast<num>().map((e) => e.toInt()).toList() ?? [];

    final npsToplam = promoter + passive + detractor;
    final promoterOran = npsToplam > 0 ? promoter / npsToplam : 0.0;
    final passiveOran = npsToplam > 0 ? passive / npsToplam : 0.0;
    final detractorOran = npsToplam > 0 ? detractor / npsToplam : 0.0;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: _cardDeco(scheme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _ozetMini('Cevap Oranı', '%${cevapOrani.toStringAsFixed(1)}', scheme.primary)),
              SizedBox(width: 8),
              Expanded(child: _ozetMini('NPS', nps != null ? '$nps' : '-', Colors.green.shade600)),
              SizedBox(width: 8),
              Expanded(child: _ozetMini('CSAT', csat != null ? '$csat' : '-', Colors.orange.shade600)),
            ],
          ),
          SizedBox(height: 6),
          Text(
            '$toplamCevap / $toplamGonderim cevap',
            style: TextStyle(color: Colors.grey, fontSize: 11),
          ),
          if (npsToplam > 0) ...[
            SizedBox(height: 16),
            Text('NPS Dağılımı', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  Expanded(
                    flex: (detractorOran * 1000).round(),
                    child: Container(height: 16, color: Colors.red.shade400),
                  ),
                  Expanded(
                    flex: (passiveOran * 1000).round(),
                    child: Container(height: 16, color: Colors.amber.shade400),
                  ),
                  Expanded(
                    flex: (promoterOran * 1000).round(),
                    child: Container(height: 16, color: Colors.green.shade500),
                  ),
                ],
              ),
            ),
            SizedBox(height: 6),
            Row(
              children: [
                _legend(Colors.red.shade400, 'Detractor $detractor'),
                SizedBox(width: 12),
                _legend(Colors.amber.shade400, 'Passive $passive'),
                SizedBox(width: 12),
                _legend(Colors.green.shade500, 'Promoter $promoter'),
              ],
            ),
          ],
          if (trend.isNotEmpty) ...[
            SizedBox(height: 16),
            Text('Son 7 Gün Trend', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            SizedBox(height: 6),
            _miniBars(trend, scheme),
          ],
        ],
      ),
    );
  }

  Widget _ozetMini(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: color),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _miniBars(List<int> trend, ColorScheme scheme) {
    final maxv = trend.reduce((a, b) => a > b ? a : b);
    return SizedBox(
      height: 50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: trend.map((v) {
          final h = maxv > 0 ? (v / maxv) * 50 : 0.0;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 2),
              child: Container(
                height: h.clamp(2, 50),
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _gonderimSatiri(ColorScheme scheme, Map<String, dynamic> g) {
    final ad = g['ad_soyad']?.toString() ?? '-';
    final nps = g['nps_skoru'];
    final csat = g['csat_skoru'];
    final yorum = g['genel_yorum']?.toString();
    final cevapZ = g['cevap_zamani']?.toString();

    Color npsColor = Colors.grey;
    if (nps != null) {
      final n = nps is num ? nps.toInt() : 0;
      if (n >= 9) npsColor = Colors.green.shade600;
      else if (n >= 7) npsColor = Colors.amber.shade700;
      else npsColor = Colors.red.shade500;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: _cardDeco(scheme),
      child: InkWell(
        onTap: () => _gonderimDetayAc(g['id']),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: scheme.primary.withValues(alpha: 0.12),
                  child: Text(
                    ad.isNotEmpty ? ad[0].toUpperCase() : '?',
                    style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w800),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ad, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      if (cevapZ != null)
                        Text(cevapZ, style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
                if (nps != null)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: npsColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'NPS $nps',
                      style: TextStyle(color: npsColor, fontWeight: FontWeight.w800, fontSize: 12),
                    ),
                  ),
                if (csat != null) ...[
                  SizedBox(width: 6),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, color: Colors.orange.shade700, size: 12),
                        SizedBox(width: 2),
                        Text('$csat', style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.w800, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            if (yorum != null && yorum.isNotEmpty) ...[
              SizedBox(height: 8),
              Text(yorum, style: TextStyle(fontSize: 12, color: Colors.black87)),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _gonderimDetayAc(dynamic id) async {
    if (id == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return FutureBuilder<Map<String, dynamic>?>(
          future: anketGonderimDetay(_salonId, id is int ? id : int.tryParse(id.toString()) ?? 0),
          builder: (c, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snap.data == null) {
              return Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Text('Detay yüklenemedi'),
              );
            }
            return _gonderimDetayContent(snap.data!);
          },
        );
      },
    );
  }

  Widget _gonderimDetayContent(Map<String, dynamic> data) {
    final scheme = Theme.of(context).colorScheme;
    final sorular = (data['sorular'] as List?) ?? [];
    final cevaplar = (data['cevaplar'] as List?) ?? [];
    final musteri = data['musteri_ad']?.toString() ?? '-';
    final sablon = data['sablon_ad']?.toString() ?? '-';

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (ctx, scroll) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              SizedBox(height: 12),
              Text(musteri, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              Text(sablon, style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600, fontSize: 12)),
              SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scroll,
                  itemCount: sorular.length,
                  itemBuilder: (c, i) {
                    final soru = sorular[i] as Map;
                    final cevap = i < cevaplar.length ? cevaplar[i] : null;
                    final cevapVal = cevap is Map ? cevap['cevap'] : cevap;
                    return Container(
                      margin: EdgeInsets.only(bottom: 12),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            soru['baslik']?.toString() ?? soru['soru']?.toString() ?? 'Soru ${i + 1}',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          SizedBox(height: 4),
                          Text(
                            cevapVal != null && cevapVal.toString().isNotEmpty ? cevapVal.toString() : '(Cevap yok)',
                            style: TextStyle(fontSize: 14, color: scheme.onSurface),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============ SABLONLAR TAB ============

  Widget _buildSablonlarTab(ColorScheme scheme) {
    return RefreshIndicator(
      onRefresh: _yukleSablonlar,
      child: ListView(
        padding: EdgeInsets.fromLTRB(12, 12, 12, 80),
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: _cardDeco(scheme),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: scheme.primary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Şablon: anket sorularının tanımı. Varsayılan şablon randevu sonrası otomatik gönderilir.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _yeniSablonAc,
            icon: Icon(Icons.add),
            label: Text('Yeni Şablon'),
            style: ElevatedButton.styleFrom(
              backgroundColor: scheme.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          SizedBox(height: 16),
          if (_sablonLoading)
            _loadingCard()
          else if (_sablonlar.isEmpty)
            _emptyState('Henüz şablon yok. Yukarıdan ekleyin.')
          else
            ..._sablonlar.map((s) => _sablonSatiri(scheme, s)),
        ],
      ),
    );
  }

  Widget _sablonSatiri(ColorScheme scheme, Map<String, dynamic> s) {
    final aktif = (s['aktif'] is num) ? (s['aktif'] as num).toInt() == 1 : (s['aktif'] == true);
    final varsayilan = (s['varsayilan'] is num) ? (s['varsayilan'] as num).toInt() == 1 : (s['varsayilan'] == true);
    final otomatik = (s['otomatik_gonder'] is num) ? (s['otomatik_gonder'] as num).toInt() == 1 : (s['otomatik_gonder'] == true);

    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(14),
      decoration: _cardDeco(scheme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  s['ad']?.toString() ?? '-',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
              if (varsayilan)
                _badge('Varsayılan', Colors.green.shade600),
              SizedBox(width: 4),
              if (!aktif)
                _badge('Pasif', Colors.grey),
              if (aktif)
                _badge('Aktif', scheme.primary),
            ],
          ),
          if ((s['aciklama']?.toString() ?? '').isNotEmpty) ...[
            SizedBox(height: 4),
            Text(s['aciklama'].toString(), style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
          ],
          SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (otomatik)
                Chip(
                  label: Text('Oto. ${s['gonder_saat_sonra']}sa sonra'),
                  backgroundColor: scheme.primary.withValues(alpha: 0.10),
                  labelStyle: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600, fontSize: 11),
                  visualDensity: VisualDensity.compact,
                ),
              _sablonAction(
                Icons.send, 'Test Gönder', Colors.blue.shade600,
                () => _testGonderAc(s),
              ),
              _sablonAction(
                Icons.edit, 'Düzenle', Colors.amber.shade700,
                () => _sablonDuzenleAc(s),
              ),
              _sablonAction(
                Icons.delete_outline, 'Sil', Colors.red.shade600,
                () => _sablonSilOnay(s),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sablonAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            SizedBox(width: 4),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Future<void> _yeniSablonAc() async {
    final sonuc = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AnketSablonDuzenlePage(
        isletmebilgi: widget.isletmebilgi,
        sablon: null,
      )),
    );
    if (sonuc == true) _yukleSablonlar();
  }

  Future<void> _sablonDuzenleAc(Map<String, dynamic> s) async {
    final sonuc = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AnketSablonDuzenlePage(
        isletmebilgi: widget.isletmebilgi,
        sablon: s,
      )),
    );
    if (sonuc == true) _yukleSablonlar();
  }

  Future<void> _sablonSilOnay(Map<String, dynamic> s) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Şablonu Sil'),
        content: Text('${s['ad']} şablonunu silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text('İptal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Sil'),
          ),
        ],
      ),
    );
    if (onay != true) return;
    final sonuc = await anketSablonSil(_salonId, (s['id'] as num).toInt());
    if (!mounted) return;
    if (sonuc != null && sonuc['basarili'] == true) {
      final mesaj = sonuc['pasiflestirildi'] == true
          ? 'Şablon kullanılmış, pasifleştirildi.'
          : 'Şablon silindi.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mesaj)));
      _yukleSablonlar();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(sonuc?['mesaj'] ?? 'Silme hatası'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _testGonderAc(Map<String, dynamic> s) async {
    final adCtrl = TextEditingController();
    final telCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Test Gönderim'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: adCtrl, decoration: InputDecoration(labelText: 'Ad Soyad (opsiyonel)')),
            TextField(controller: telCtrl, decoration: InputDecoration(labelText: 'Telefon'), keyboardType: TextInputType.phone),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text('İptal')),
          ElevatedButton(onPressed: () => Navigator.pop(c, true), child: Text('Gönder')),
        ],
      ),
    );
    if (result != true) return;
    final tel = telCtrl.text.trim();
    if (tel.isEmpty) return;
    final res = await anketManuelGonder(
      _salonId,
      sablonId: (s['id'] as num).toInt(),
      telefon: tel,
      adSoyad: adCtrl.text.trim().isEmpty ? null : adCtrl.text.trim(),
    );
    if (!mounted) return;
    if (res != null && res['basarili'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Anket gönderildi (ID #${res['gonderim_id']})'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res?['mesaj'] ?? 'Gönderim hatası'), backgroundColor: Colors.red),
      );
    }
  }

  // ============ AYARLAR TAB ============

  Widget _buildAyarlarTab(ColorScheme scheme) {
    if (_ayarLoading) return _loadingCard();
    if (_ayarlar == null) {
      // Henuz yuklenmediyse otomatik tetikle (yan tab'a swipe ile gelis)
      WidgetsBinding.instance.addPostFrameCallback((_) => _yukleAyarlar());
      return _loadingCard();
    }
    return _AyarlarFormu(
      salonId: _salonId,
      ayarlar: _ayarlar!,
      onKaydedildi: (yeniAyar) {
        setState(() => _ayarlar = yeniAyar);
      },
    );
  }

  // ============ COMMON ============

  Widget _sectionHeader(ColorScheme scheme, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: scheme.primary),
        SizedBox(width: 6),
        Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
      ],
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 10)),
    );
  }

  Widget _loadingCard() {
    return Container(
      padding: EdgeInsets.all(40),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _emptyState(String msg) {
    return Container(
      padding: EdgeInsets.all(30),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
          SizedBox(height: 8),
          Text(msg, style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  BoxDecoration _cardDeco(ColorScheme scheme) => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      );
}

// ============================================================
// AYARLAR FORMU (Google esik + bilgilendirme)
// ============================================================

class _AyarlarFormu extends StatefulWidget {
  final String salonId;
  final Map<String, dynamic> ayarlar;
  final void Function(Map<String, dynamic>) onKaydedildi;
  const _AyarlarFormu({Key? key, required this.salonId, required this.ayarlar, required this.onKaydedildi}) : super(key: key);

  @override
  State<_AyarlarFormu> createState() => _AyarlarFormuState();
}

class _AyarlarFormuState extends State<_AyarlarFormu> {
  late TextEditingController _googleUrl;
  late int _esikNps;
  late double _esikCsat;
  late int _uyariNps;
  late double _uyariCsat;
  bool _kaydediliyor = false;

  int _toInt(dynamic v, int def) {
    if (v == null) return def;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? double.tryParse(v)?.toInt() ?? def;
    return def;
  }

  double _toDouble(dynamic v, double def) {
    if (v == null) return def;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? def;
    return def;
  }

  @override
  void initState() {
    super.initState();
    _googleUrl = TextEditingController(text: widget.ayarlar['google_url']?.toString() ?? '');
    _esikNps = _toInt(widget.ayarlar['google_review_esik_nps'], 9);
    _esikCsat = _toDouble(widget.ayarlar['google_review_esik_csat'], 4.5);
    _uyariNps = _toInt(widget.ayarlar['kotu_puan_uyari_esik_nps'], 6);
    _uyariCsat = _toDouble(widget.ayarlar['kotu_puan_uyari_esik_csat'], 3.0);
  }

  @override
  void dispose() {
    _googleUrl.dispose();
    super.dispose();
  }

  Future<void> _kaydet() async {
    setState(() => _kaydediliyor = true);
    final ok = await anketAyarlarKaydet(widget.salonId, {
      'google_url': _googleUrl.text.trim(),
      'google_review_esik_nps': _esikNps,
      'google_review_esik_csat': _esikCsat,
      'kotu_puan_uyari_esik_nps': _uyariNps,
      'kotu_puan_uyari_esik_csat': _uyariCsat,
    });
    if (!mounted) return;
    setState(() => _kaydediliyor = false);
    if (ok) {
      widget.onKaydedildi({
        'google_url': _googleUrl.text.trim(),
        'google_review_esik_nps': _esikNps,
        'google_review_esik_csat': _esikCsat,
        'kotu_puan_uyari_esik_nps': _uyariNps,
        'kotu_puan_uyari_esik_csat': _uyariCsat,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ayarlar kaydedildi'), backgroundColor: Colors.green),
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
    return ListView(
      padding: EdgeInsets.fromLTRB(12, 12, 12, 80),
      children: [
        _ayarKart(
          scheme,
          title: 'Google Yorum Yönlendirme',
          subtitle: 'Yüksek puan veren müşteriler Google Maps yorum sayfasına yönlendirilir.',
          children: [
            TextField(
              controller: _googleUrl,
              decoration: InputDecoration(
                labelText: 'Google Maps URL / Place ID',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            _googleYardimKutusu(scheme),
            SizedBox(height: 12),
            _sliderRow('NPS eşiği (≥)', _esikNps.toDouble(), 0, 10, 10,
                (v) => setState(() => _esikNps = v.round())),
            _sliderRow('CSAT eşiği (≥)', _esikCsat, 1, 5, 16,
                (v) => setState(() => _esikCsat = (v * 4).round() / 4)),
          ],
        ),
        SizedBox(height: 12),
        _ayarKart(
          scheme,
          title: 'Kötü Puan Uyarısı',
          subtitle: 'Bu eşiklerin altında puan veren müşteriler için yönetime uyarı gönderilir.',
          children: [
            _sliderRow('NPS eşiği (≤)', _uyariNps.toDouble(), 0, 10, 10,
                (v) => setState(() => _uyariNps = v.round())),
            _sliderRow('CSAT eşiği (≤)', _uyariCsat, 1, 5, 16,
                (v) => setState(() => _uyariCsat = (v * 4).round() / 4)),
          ],
        ),
        SizedBox(height: 20),
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

  Future<void> _openUrl(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Widget _googleYardimKutusu(ColorScheme scheme) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.35), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.star, color: Colors.amber.shade700, size: 18),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'EN DOĞRU YOL — Google Business\'tan yorum bağlantısı:',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: Colors.amber.shade900,
                    height: 1.35,
                  ),
                  softWrap: true,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          _yardimSatiriLink(
            '1.',
            link: 'business.google.com',
            linkUrl: 'https://business.google.com/',
            after: ' → İşletmenize girin',
          ),
          _yardimSatiri('2.', 'Sol menü: Müşteriler → Yorumlar'),
          _yardimSatiri('3.', '"Daha fazla yorum al" butonu → "Bağlantıyı paylaş"'),
          _yardimSatiri('4.', 'Bağlantıyı kopyalayıp yukarıya yapıştırın (g.page/r/... formatında olmalı)'),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 14, color: Colors.grey.shade700),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Alternatif: Google Maps\'ten "Paylaş" da çalışır ama bazı linkler haritayı açar, doğrudan yorum diyaloğunu açmaz.',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade800, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _yardimSatiri(String num, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 18,
            child: Text(num, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Colors.amber.shade900)),
          ),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 12, color: Colors.grey.shade800, height: 1.35)),
          ),
        ],
      ),
    );
  }

  Widget _yardimSatiriLink(String num, {required String link, required String linkUrl, required String after}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 18,
            child: Text(num, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Colors.amber.shade900)),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 12, color: Colors.grey.shade800, height: 1.35),
                children: [
                  TextSpan(
                    text: link,
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.w700,
                    ),
                    recognizer: TapGestureRecognizer()..onTap = () => _openUrl(linkUrl),
                  ),
                  TextSpan(text: after),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ayarKart(ColorScheme scheme, {required String title, required String subtitle, required List<Widget> children}) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          SizedBox(height: 4),
          Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _sliderRow(String label, double value, double min, double max, int divisions, ValueChanged<double> onChange) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          ),
          Expanded(
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              label: value is double && value == value.roundToDouble()
                  ? value.toInt().toString()
                  : value.toStringAsFixed(1),
              onChanged: onChange,
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              value == value.roundToDouble() ? value.toInt().toString() : value.toStringAsFixed(1),
              textAlign: TextAlign.right,
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

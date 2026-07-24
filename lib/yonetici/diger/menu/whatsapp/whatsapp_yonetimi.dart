import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show Factory;
import 'package:flutter/gestures.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Backend/yetki.dart';

class WhatsappYonetimiPage extends StatefulWidget {
  final dynamic isletmebilgi;
  final int kullanicirolu;
  const WhatsappYonetimiPage({Key? key, required this.isletmebilgi, required this.kullanicirolu}) : super(key: key);

  @override
  State<WhatsappYonetimiPage> createState() => _WhatsappYonetimiPageState();
}

class _WhatsappYonetimiPageState extends State<WhatsappYonetimiPage> with TickerProviderStateMixin {
  late final TabController _tab;
  late final String _salonId;

  bool _durumLoading = false;
  Map<String, dynamic>? _durum;
  Map<String, dynamic>? _kanal;
  Map<String, dynamic>? _ozet;
  Timer? _qrPoll;
  String? _qrBase64;
  bool _qrYukleniyor = false;

  // Loglar
  bool _logLoading = false;
  List<Map<String, dynamic>> _loglar = [];
  int _logPage = 1;
  int _logSonSayfa = 1;
  String _logFiltreTel = '';
  int? _logFiltreDurum;

  // Alıcılar
  bool _aliciLoading = false;
  List<Map<String, dynamic>> _aliciler = [];
  String? _aliciHata;

  // Paket
  bool _paketLoading = false;
  Map<String, dynamic>? _paket;
  String _paketPeriyot = 'aylik';

  static const Map<String, Map<String, int>> _paketFiyat = {
    'pro': {'aylik': 499, 'yillik': 4990},
  };

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
    _tab.addListener(_onTabChanged);
    _salonId = widget.isletmebilgi['id'].toString();
    _yukleDurum();
    // Eager load all tabs in parallel - so user never sees empty/gray initial state
    _yukleAliciler();
    _yukleLoglar(page: 1);
    _yuklePaket();
  }

  void _onTabChanged() {
    if (_tab.indexIsChanging) return;
    final i = _tab.index;
    // Reload on tab switch only if previous load failed (kept empty + no loading)
    if (i == 1 && _loglar.isEmpty && !_logLoading) _yukleLoglar(page: 1);
    if (i == 2 && _aliciler.isEmpty && !_aliciLoading) _yukleAliciler();
    if (i == 3 && _paket == null && !_paketLoading) _yuklePaket();
  }

  @override
  void dispose() {
    _qrPoll?.cancel();
    _tab.removeListener(_onTabChanged);
    _tab.dispose();
    super.dispose();
  }

  Future<void> _yukleDurum() async {
    setState(() => _durumLoading = true);
    final d = await whatsappDurum(_salonId);
    final k = await whatsappKanalDurum(_salonId);
    final o = await whatsappOzet(_salonId);
    if (!mounted) return;
    setState(() {
      _durum = d;
      _kanal = k;
      _ozet = o;
      _durumLoading = false;
    });
    final status = _durum?['status']?.toString();
    if (status == 'qr-pending' && _qrPoll == null) {
      _qrYukle();
      _qrPoll = Timer.periodic(Duration(seconds: 4), (_) {
        _statusVeQrPoll();
      });
    } else if (status == 'connected' && _qrPoll != null) {
      _qrPoll!.cancel();
      _qrPoll = null;
    }
  }

  Future<void> _statusVeQrPoll() async {
    final d = await whatsappDurum(_salonId);
    if (!mounted) return;
    setState(() => _durum = d);
    if (d?['status'] == 'qr-pending') _qrYukle();
    if (d?['status'] == 'connected') {
      _qrPoll?.cancel();
      _qrPoll = null;
      _yukleDurum();
    }
  }

  Future<void> _qrYukle() async {
    if (_qrYukleniyor) return;
    setState(() => _qrYukleniyor = true);
    final r = await whatsappQR(_salonId);
    if (!mounted) return;
    setState(() {
      _qrBase64 = r?['qr']?.toString() ?? r?['qrcode']?.toString();
      _qrYukleniyor = false;
    });
  }

  Future<void> _baglat() async {
    final r = await whatsappBaslat(_salonId);
    if (!mounted) return;
    if (r != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Oturum başlatıldı, QR bekleniyor...')),
      );
      _yukleDurum();
    }
  }

  Future<void> _cikis() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('WhatsApp Oturumu Kapat'),
        content: Text('Çıkmak istediğinize emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text('İptal')),
          ElevatedButton(onPressed: () => Navigator.pop(c, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: Text('Çık')),
        ],
      ),
    );
    if (ok != true) return;
    final r = await whatsappCikis(_salonId);
    if (!mounted) return;
    if (r) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Çıkış yapıldı')));
      _yukleDurum();
    }
  }

  Future<void> _kanalToggle(bool aktif) async {
    final r = await whatsappKanalToggle(_salonId, aktif);
    if (!mounted) return;
    if (r) {
      _yukleDurum();
    }
  }

  Future<void> _yukleLoglar({int? page}) async {
    setState(() {
      _logLoading = true;
      if (page != null) _logPage = page;
    });
    final r = await whatsappLoglar(
      _salonId,
      page: _logPage,
      perPage: 30,
      durum: _logFiltreDurum,
      telefon: _logFiltreTel.isEmpty ? null : _logFiltreTel,
    );
    if (!mounted) return;
    setState(() {
      if (r != null) {
        _loglar = ((r['rows'] as List?) ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _logSonSayfa = (r['son_sayfa'] as num?)?.toInt() ?? 1;
      }
      _logLoading = false;
    });
  }

  Future<void> _yukleAliciler() async {
    setState(() {
      _aliciLoading = true;
      _aliciHata = null;
    });
    final r = await whatsappAliciler(_salonId);
    if (!mounted) return;
    setState(() {
      if (r == null) {
        _aliciHata = 'Sunucuya ulaşılamadı. İnternet bağlantınızı kontrol edin.';
        _aliciler = [];
      } else if (r['hata'] != null) {
        _aliciHata = r['hata'].toString();
        _aliciler = [];
      } else {
        _aliciler = ((r['rows'] as List?) ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      _aliciLoading = false;
    });
  }

  Future<void> _yuklePaket() async {
    setState(() => _paketLoading = true);
    final r = await whatsappPaketDurum(_salonId);
    if (!mounted) return;
    setState(() {
      _paket = r ?? {'paket': 'baslangic'};
      _paketLoading = false;
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
            Color.alphaBlend(Colors.green.withValues(alpha: 0.18), Colors.white),
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
          title: Row(
            children: [
              Icon(Icons.chat, color: Color(0xFF25D366)),
              SizedBox(width: 8),
              Text(
                'WhatsApp',
                style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w800, fontSize: 22, letterSpacing: -0.3),
              ),
            ],
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
                indicatorColor: Color(0xFF25D366),
                indicatorWeight: 3,
                labelColor: Color(0xFF25D366),
                unselectedLabelColor: Colors.grey,
                labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
                tabs: [
                  Tab(icon: Icon(Icons.wifi, size: 18), text: 'Bağlantı'),
                  Tab(icon: Icon(Icons.list_alt, size: 18), text: 'Loglar'),
                  Tab(icon: Icon(Icons.people, size: 18), text: 'Alıcılar'),
                  Tab(icon: Icon(Icons.workspace_premium, size: 18), text: 'Paket'),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          controller: _tab,
          children: [
            _baglantiTab(scheme),
            _loglarTab(scheme),
            _alicilarTab(scheme),
            _paketTab(scheme),
          ],
        ),
      ),
    );
  }

  // ============ BAGLANTI TAB ============

  Widget _baglantiTab(ColorScheme scheme) {
    if (_durumLoading) return Center(child: CircularProgressIndicator());

    final status = _durum?['status']?.toString() ?? '-';
    final numara = _durum?['phone']?.toString() ?? _ozet?['numara']?.toString();
    final kanalAktif = (_kanal?['aktif'] == true);

    Color statusColor;
    String statusLabel;
    IconData statusIcon;
    switch (status) {
      case 'connected':
        statusColor = Colors.green;
        statusLabel = 'Bağlı';
        statusIcon = Icons.check_circle;
        break;
      case 'connecting':
        statusColor = Colors.blue;
        statusLabel = 'Bağlanıyor...';
        statusIcon = Icons.sync;
        break;
      case 'qr-pending':
        statusColor = Colors.orange;
        statusLabel = 'QR Bekleniyor';
        statusIcon = Icons.qr_code;
        break;
      case 'banned-or-loggedout':
        statusColor = Colors.red;
        statusLabel = 'Yasaklı / Çıkış Yapıldı';
        statusIcon = Icons.block;
        break;
      case 'rate-limited':
        statusColor = Colors.amber;
        statusLabel = 'Limit Aşıldı';
        statusIcon = Icons.warning;
        break;
      default:
        statusColor = Colors.grey;
        statusLabel = 'Bağlı Değil';
        statusIcon = Icons.power_off;
    }

    return RefreshIndicator(
      onRefresh: _yukleDurum,
      child: ListView(
        padding: EdgeInsets.fromLTRB(12, 12, 12, 80),
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: statusColor.withValues(alpha: 0.10), blurRadius: 16, offset: Offset(0, 4)),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(14),
                  decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), shape: BoxShape.circle),
                  child: Icon(statusIcon, color: statusColor, size: 36),
                ),
                SizedBox(height: 12),
                Text(statusLabel, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: statusColor)),
                if (numara != null && numara.isNotEmpty) ...[
                  SizedBox(height: 4),
                  Text(numara, style: TextStyle(color: Colors.grey.shade700)),
                ],
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (status == 'connected') ...[
                      ElevatedButton.icon(
                        onPressed: _cikis,
                        icon: Icon(Icons.logout),
                        label: Text('Çıkış Yap'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                      ),
                    ] else ...[
                      ElevatedButton.icon(
                        onPressed: _baglat,
                        icon: Icon(Icons.qr_code),
                        label: Text('WhatsApp\'ı Bağla'),
                        style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF25D366), foregroundColor: Colors.white, padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (status == 'qr-pending' && _qrBase64 != null) ...[
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Column(
                children: [
                  Text('WhatsApp\'tan QR\'ı Tarayın', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  SizedBox(height: 4),
                  Text('Telefon > Ayarlar > Bağlı Cihazlar > Cihaz Bağla', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  SizedBox(height: 16),
                  if (_qrBase64!.startsWith('data:image') || _qrBase64!.length > 100)
                    Image.memory(
                      base64Decode(_qrBase64!.replaceAll(RegExp(r'^data:image/[^;]+;base64,'), '')),
                      width: 260,
                      height: 260,
                    )
                  else
                    Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('QR henüz oluşmadı, lütfen bekleyin...', style: TextStyle(color: Colors.grey)),
                    ),
                ],
              ),
            ),
          ],
          SizedBox(height: 16),
          // Kanal toggle
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hatırlatma Kanalı', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                Text('Açıksa randevu hatırlatmaları SMS yerine WhatsApp\'tan gönderilir',
                    style: TextStyle(fontSize: 11, color: Colors.grey)),
                SwitchListTile(
                  value: kanalAktif,
                  title: Text('WhatsApp Hatırlatma Aktif'),
                  onChanged: status == 'connected' ? _kanalToggle : null,
                  contentPadding: EdgeInsets.zero,
                  activeColor: Color(0xFF25D366),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          if (_ozet != null) _ozetCardlar(scheme, _ozet!),
        ],
      ),
    );
  }

  Widget _ozetCardlar(ColorScheme scheme, Map<String, dynamic> o) {
    final bugun = (o['bugun'] as Map?) ?? {};
    final hafta = (o['hafta'] as Map?) ?? {};
    final ay = (o['ay'] as Map?) ?? {};
    final basari = (o['basariOrani'] as num?)?.toDouble() ?? 0;
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('İstatistikler', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _statBox('Bugün Toplam', '${bugun['toplam'] ?? 0}', Colors.blue)),
              SizedBox(width: 8),
              Expanded(child: _statBox('Bugün Başarı', '${bugun['basari'] ?? 0}', Colors.green)),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _statBox('Hafta', '${hafta['toplam'] ?? 0}', Colors.purple)),
              SizedBox(width: 8),
              Expanded(child: _statBox('Ay', '${ay['toplam'] ?? 0}', Colors.orange)),
              SizedBox(width: 8),
              Expanded(child: _statBox('Başarı %', basari.toStringAsFixed(1), Color(0xFF25D366))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statBox(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: color)),
          Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // ============ LOGLAR TAB ============

  Widget _loglarTab(ColorScheme scheme) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Telefon ara...',
                    prefixIcon: Icon(Icons.search, size: 18),
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onSubmitted: (v) {
                    _logFiltreTel = v.trim();
                    _yukleLoglar(page: 1);
                  },
                ),
              ),
              IconButton(
                icon: Icon(Icons.help_outline, color: Colors.grey.shade600),
                tooltip: 'Durumlar hakkında',
                onPressed: _durumBilgisiAc,
              ),
            ],
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 12),
            children: [
              _filtreChip('Tümü', null, Colors.grey),
              _filtreChip('WhatsApp Gönderildi', 1, Colors.green),
              _filtreChip('Başarısız', 2, Colors.red),
              _filtreChip('SMS ile Gönderildi', 3, Colors.orange),
              _filtreChip('Kuyrukta', 0, Colors.blueGrey),
            ],
          ),
        ),
        Expanded(
          child: _logLoading
              ? Center(child: CircularProgressIndicator())
              : _loglar.isEmpty
                  ? RefreshIndicator(
                      onRefresh: () => _yukleLoglar(page: 1),
                      child: ListView(
                        physics: AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(height: 120),
                          Center(child: Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade400)),
                          SizedBox(height: 8),
                          Center(child: Text('Bu filtre için log yok', style: TextStyle(color: Colors.grey))),
                          SizedBox(height: 8),
                          if (_logFiltreDurum != null || _logFiltreTel.isNotEmpty)
                            Center(
                              child: TextButton.icon(
                                onPressed: () {
                                  _logFiltreDurum = null;
                                  _logFiltreTel = '';
                                  _yukleLoglar(page: 1);
                                },
                                icon: Icon(Icons.clear, size: 16),
                                label: Text('Filtreleri Temizle'),
                              ),
                            ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => _yukleLoglar(page: _logPage),
                      child: ListView.separated(
                        padding: EdgeInsets.fromLTRB(12, 4, 12, 80),
                        itemCount: _loglar.length,
                        separatorBuilder: (_, __) => SizedBox(height: 6),
                        itemBuilder: (c, i) => _logSatiri(scheme, _loglar[i]),
                      ),
                    ),
        ),
        if (_logSonSayfa > 1) _paginationBar(scheme),
      ],
    );
  }

  Widget _filtreChip(String label, int? deger, Color color) {
    final aktif = _logFiltreDurum == deger;
    return Padding(
      padding: EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: aktif ? Colors.white : color)),
        selected: aktif,
        showCheckmark: false,
        backgroundColor: Colors.white,
        selectedColor: color,
        side: BorderSide(color: aktif ? color : color.withValues(alpha: 0.4)),
        onSelected: (_) {
          _logFiltreDurum = deger;
          _yukleLoglar(page: 1);
        },
      ),
    );
  }

  Widget _logSatiri(ColorScheme scheme, Map<String, dynamic> l) {
    final d = (l['durum'] as num?)?.toInt() ?? 0;
    final dInfo = _durumInfo(d);
    return InkWell(
      onTap: () => _logDetayAc(l),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: Offset(0, 1))],
        ),
        child: Row(
          children: [
            Icon(dInfo.icon, color: dInfo.color, size: 22),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(Yetki.telefonGoster(l['telefon']?.toString()).isEmpty ? '-' : Yetki.telefonGoster(l['telefon']?.toString()), style: TextStyle(fontWeight: FontWeight.w700))),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: dInfo.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                        child: Text(dInfo.label, style: TextStyle(color: dInfo.color, fontWeight: FontWeight.w700, fontSize: 10)),
                      ),
                    ],
                  ),
                  if ((l['musteri_adi']?.toString() ?? '').isNotEmpty)
                    Text(l['musteri_adi'].toString(), style: TextStyle(fontSize: 11, color: Colors.grey)),
                  Text(
                    l['mesaj']?.toString() ?? '',
                    style: TextStyle(fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(l['created_at']?.toString() ?? '', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  if ((l['hata']?.toString() ?? '').isNotEmpty)
                    Text(l['hata'].toString(),
                        style: TextStyle(fontSize: 11, color: Colors.red),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }

  ({Color color, String label, IconData icon}) _durumInfo(int d) {
    switch (d) {
      case 1: return (color: Colors.green, label: 'WhatsApp Gönderildi', icon: Icons.check_circle);
      case 2: return (color: Colors.red, label: 'Başarısız', icon: Icons.error);
      case 3: return (color: Colors.orange, label: 'SMS ile Gönderildi', icon: Icons.sms);
      default: return (color: Colors.blueGrey, label: 'Kuyrukta', icon: Icons.schedule);
    }
  }

  void _durumBilgisiAc() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (c) => Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            SizedBox(height: 16),
            Text('Durumlar Ne Anlama Geliyor?',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            SizedBox(height: 12),
            _durumAciklamaSatir(
              Icons.check_circle, Colors.green, 'WhatsApp Gönderildi',
              'Mesaj müşterinin WhatsApp\'ına başarıyla iletildi.',
            ),
            _durumAciklamaSatir(
              Icons.sms, Colors.orange, 'SMS ile Gönderildi',
              'WhatsApp\'a ulaşılamadı (numara WhatsApp\'ta yok, internet yok vb.) — sistem otomatik olarak SMS gönderdi. Bu SMS bakiyenizden düşer.',
            ),
            _durumAciklamaSatir(
              Icons.error, Colors.red, 'Başarısız',
              'Mesaj hiçbir kanaldan gönderilemedi. Hata detayını mesaj kartına tıklayarak görebilirsiniz.',
            ),
            _durumAciklamaSatir(
              Icons.schedule, Colors.blueGrey, 'Kuyrukta',
              'Mesaj gönderim sırasında bekliyor, kısa süre içinde işlenecek.',
            ),
            SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(c),
                child: Text('Tamam'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _durumAciklamaSatir(IconData ikon, Color renk, String baslik, String aciklama) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(color: renk.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(ikon, color: renk, size: 18),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(baslik, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: renk)),
                SizedBox(height: 2),
                Text(aciklama, style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _logDetayAc(Map<String, dynamic> l) {
    final d = (l['durum'] as num?)?.toInt() ?? 0;
    final info = _durumInfo(d);
    final mesaj = l['mesaj']?.toString() ?? '';
    final hata = l['hata']?.toString() ?? '';
    final telefonRaw = l['telefon']?.toString() ?? '';
    final telefon = telefonRaw.isEmpty ? '-' : Yetki.telefonGoster(telefonRaw);
    final musteri = l['musteri_adi']?.toString() ?? '';
    final tarih = l['created_at']?.toString() ?? '';
    final randevuId = l['randevu_id'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (c) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.3,
        maxChildSize: 0.92,
        expand: false,
        builder: (c, scroll) => Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          padding: EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(color: info.color.withValues(alpha: 0.12), shape: BoxShape.circle),
                    child: Icon(info.icon, color: info.color, size: 22),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Mesaj Detayı', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        Text(info.label, style: TextStyle(color: info.color, fontWeight: FontWeight.w700, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scroll,
                  children: [
                    _detaySatir('Telefon', telefon),
                    if (musteri.isNotEmpty) _detaySatir('Müşteri', musteri),
                    if (tarih.isNotEmpty) _detaySatir('Tarih', tarih),
                    if (randevuId != null) _detaySatir('Randevu ID', randevuId.toString()),
                    SizedBox(height: 12),
                    Text('Mesaj İçeriği', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.grey.shade700)),
                    SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Color(0xFFF7F9FC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border(left: BorderSide(color: Color(0xFF25D366), width: 3)),
                      ),
                      child: SelectableText(
                        mesaj.isEmpty ? '—' : mesaj,
                        style: TextStyle(fontSize: 14, height: 1.4),
                      ),
                    ),
                    if (hata.isNotEmpty) ...[
                      SizedBox(height: 12),
                      Text('Hata', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.red)),
                      SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                        ),
                        child: SelectableText(hata, style: TextStyle(fontSize: 12, color: Colors.red.shade900)),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detaySatir(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 90, child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600))),
          Expanded(child: Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _paginationBar(ColorScheme scheme) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left),
            onPressed: _logPage > 1 ? () => _yukleLoglar(page: _logPage - 1) : null,
          ),
          Text('$_logPage / $_logSonSayfa'),
          IconButton(
            icon: Icon(Icons.chevron_right),
            onPressed: _logPage < _logSonSayfa ? () => _yukleLoglar(page: _logPage + 1) : null,
          ),
        ],
      ),
    );
  }

  // ============ ALICILAR TAB ============

  Widget _alicilarTab(ColorScheme scheme) {
    // Tab'ın TÜM alanını doldur, beyaz arka plan ile (gradient'i kapat)
    return Material(
      color: Colors.white,
      child: Column(
        children: [
          // ÜST DURUM ŞERİDİ — her zaman görünür
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: _aliciHata != null
                ? Colors.red.shade50
                : (_aliciLoading
                    ? Colors.blue.shade50
                    : (_aliciler.isEmpty ? Colors.amber.shade50 : Colors.green.shade50)),
            child: Row(
              children: [
                Icon(
                  _aliciHata != null
                      ? Icons.error
                      : (_aliciLoading
                          ? Icons.hourglass_top
                          : (_aliciler.isEmpty ? Icons.info_outline : Icons.check_circle)),
                  color: _aliciHata != null
                      ? Colors.red
                      : (_aliciLoading
                          ? Colors.blue
                          : (_aliciler.isEmpty ? Colors.orange : Colors.green)),
                  size: 20,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _aliciHata != null
                        ? 'Hata: ${_aliciHata!}'
                        : (_aliciLoading
                            ? 'Yükleniyor...'
                            : (_aliciler.isEmpty
                                ? 'Henüz hiç alıcı yok. WhatsApp mesajı gönderdikçe burada görünür.'
                                : '${_aliciler.length} alıcı listelendi')),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.refresh, size: 20),
                  tooltip: 'Yenile',
                  onPressed: _aliciLoading ? null : _yukleAliciler,
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
          ),
          // İÇERİK
          Expanded(
            child: _aliciler.isEmpty
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_aliciLoading)
                            CircularProgressIndicator(color: Color(0xFF25D366))
                          else
                            Icon(
                              _aliciHata != null ? Icons.cloud_off : Icons.people_outline,
                              size: 72,
                              color: _aliciHata != null ? Colors.red.shade300 : Colors.grey.shade400,
                            ),
                          SizedBox(height: 16),
                          Text(
                            _aliciLoading
                                ? 'Alıcılar yükleniyor...'
                                : (_aliciHata != null ? 'Bağlantı kurulamadı' : 'Henüz alıcı yok'),
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8),
                          Text(
                            _aliciLoading
                                ? 'Lütfen bekleyin'
                                : (_aliciHata != null
                                    ? _aliciHata!
                                    : 'WhatsApp üzerinden mesaj gönderdiğiniz müşteriler burada listelenecek.'),
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 20),
                          if (!_aliciLoading)
                            ElevatedButton.icon(
                              onPressed: _yukleAliciler,
                              icon: Icon(Icons.refresh, size: 18),
                              label: Text('Tekrar Dene'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF25D366),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              ),
                            ),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _yukleAliciler,
                    child: ListView.separated(
                      padding: EdgeInsets.fromLTRB(12, 12, 12, 80),
                      itemCount: _aliciler.length,
                      separatorBuilder: (_, __) => SizedBox(height: 8),
                      itemBuilder: (c, i) {
                        // Defansif parse: MySQL COUNT/SUM bazen string olarak geliyor
                        int asInt(dynamic v) {
                          if (v == null) return 0;
                          if (v is int) return v;
                          if (v is num) return v.toInt();
                          if (v is String) return int.tryParse(v) ?? 0;
                          return 0;
                        }
                        final a = _aliciler[i];
                        final t = asInt(a['toplam']);
                        final b = asInt(a['basari']);
                        final f = asInt(a['fail']);
                        final fb = asInt(a['fallback']);
                        final sonMesaj = a['son_mesaj']?.toString() ?? '';
                        final musteri = a['musteri_adi']?.toString() ?? '';
                        return InkWell(
                          onTap: () => _aliciGecmisAc(a['telefon']?.toString() ?? '', musteri),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              // NOT: borderRadius ancak UNIFORM renkli border ile
                              // kullanilabilir. Sol yesil aksan artik ayri bir bar
                              // (asagidaki 4px Container) ile ciziliyor.
                              border: Border.all(color: Colors.grey.shade300, width: 1),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Container(width: 4, color: Color(0xFF25D366)),
                                    Expanded(
                                      child: Padding(
                                        padding: EdgeInsets.all(12),
                                        child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Color(0xFF25D366).withValues(alpha: 0.15),
                                  child: Icon(Icons.person, color: Color(0xFF25D366)),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (musteri.isNotEmpty)
                                        Text(musteri, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                      Text(Yetki.telefonGoster(a['telefon']?.toString()).isEmpty ? '-' : Yetki.telefonGoster(a['telefon']?.toString()),
                                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                                      SizedBox(height: 6),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        children: [
                                          _aliciBadge('$t', 'toplam', Colors.blueGrey),
                                          _aliciBadge('✓$b', 'başarılı', Colors.green),
                                          if (f > 0) _aliciBadge('✗$f', 'hata', Colors.red),
                                          if (fb > 0) _aliciBadge('📱$fb', 'SMS', Colors.orange),
                                        ],
                                      ),
                                      if (sonMesaj.isNotEmpty)
                                        Padding(
                                          padding: EdgeInsets.only(top: 4),
                                          child: Text('Son: $sonMesaj',
                                              style: TextStyle(fontSize: 10, color: Colors.grey)),
                                        ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right, color: Colors.grey.shade400),
                              ],
                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _aliciBadge(String sayi, String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
      child: Text('$sayi $label', style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
    );
  }

  Future<void> _aliciGecmisAc(String telefon, [String musteri = '']) async {
    if (telefon.isEmpty) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (c) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (c, scroll) => FutureBuilder<Map<String, dynamic>?>(
          future: whatsappAliciGecmis(_salonId, telefon),
          builder: (c, snap) {
            return Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
              padding: EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: snap.connectionState != ConnectionState.done
                  ? Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                        SizedBox(height: 12),
                        if (musteri.isNotEmpty)
                          Text(musteri, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                        Text(Yetki.telefonGoster(telefon),
                            style: TextStyle(
                              fontWeight: musteri.isNotEmpty ? FontWeight.w500 : FontWeight.w800,
                              fontSize: musteri.isNotEmpty ? 13 : 18,
                              color: musteri.isNotEmpty ? Colors.grey.shade700 : Colors.black,
                            )),
                        SizedBox(height: 4),
                        Text('${((snap.data?['rows'] as List?) ?? []).length} mesaj',
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                        SizedBox(height: 12),
                        Expanded(
                          child: ((snap.data?['rows'] as List?) ?? []).isEmpty
                              ? Center(child: Text('Mesaj geçmişi yok', style: TextStyle(color: Colors.grey)))
                              : ListView.separated(
                                  controller: scroll,
                                  itemCount: ((snap.data?['rows'] as List?) ?? []).length,
                                  separatorBuilder: (_, __) => SizedBox(height: 6),
                                  itemBuilder: (c, i) {
                                    final m = Map<String, dynamic>.from(
                                        ((snap.data?['rows'] as List?) ?? [])[i] as Map);
                                    return _logSatiri(Theme.of(context).colorScheme, m);
                                  },
                                ),
                        ),
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }

  // ============ PAKET TAB ============

  Widget _paketTab(ColorScheme scheme) {
    // Kontor ekrani artik web'den (WebView + otomatik-giris koprusu) geliyor.
    // Salon kendi oturumuyla, kendi bakiyesi/paketleriyle gorur; fiyat/paket
    // degisikligi uygulama guncellemesi gerektirmez (server-side).
    return _KontorWebView(salonId: _salonId);
  }

  // ignore: unused_element
  Widget _paketTabEski(ColorScheme scheme) {
    if (_paketLoading) return Center(child: CircularProgressIndicator());
    if (_paket == null) {
      return Center(child: TextButton.icon(onPressed: _yuklePaket, icon: Icon(Icons.refresh), label: Text('Yükle')));
    }
    final aktifPaket = _paket!['paket']?.toString() ?? 'baslangic';
    final kalanGun = (_paket!['kalan_gun'] as num?)?.toInt();
    final deneme = _paket!['deneme'] == true;
    final bitis = _paket!['bitis']?.toString();
    final baslangic = _paket!['baslangic']?.toString();

    return RefreshIndicator(
      onRefresh: () async {
        setState(() => _paket = null);
        await _yuklePaket();
      },
      child: ListView(
        padding: EdgeInsets.fromLTRB(12, 12, 12, 80),
        children: [
          if (deneme && bitis != null) _denemeBandi(baslangic, bitis, kalanGun),
          _paketBaslik(aktifPaket, kalanGun, deneme),
          SizedBox(height: 16),
          _periyotToggle(),
          SizedBox(height: 16),
          _paketKart(
            scheme,
            paketTip: 'baslangic',
            baslik: 'Başlangıç',
            aciklama: 'Sadece SMS hatırlatma kullanmak isteyen küçük işletmeler için',
            fiyatBuyuk: 'Ücretsiz',
            fiyatAlt: 'Ek ücret yok',
            ozellikler: [
              _Ozellik('SMS ile randevu hatırlatma', true),
              _Ozellik('Mevcut SMS bakiyenizden düşülür', true),
              _Ozellik('Temel raporlama', true),
              _Ozellik('WhatsApp gönderimi', false),
              _Ozellik('Detaylı istatistik', false),
            ],
            aktif: aktifPaket == 'baslangic',
            populer: false,
            deneme: deneme && aktifPaket == 'baslangic',
            kalanGun: kalanGun,
            color: Colors.grey,
          ),
          SizedBox(height: 12),
          _paketKart(
            scheme,
            paketTip: 'pro',
            baslik: 'WhatsApp Randevu Hatırlatma',
            aciklama: 'WhatsApp ile profesyonel hatırlatma — randevuya gelmeyenleri azaltın',
            fiyatBuyuk: _paketPeriyot == 'aylik'
                ? '${_paketFiyat['pro']!['aylik']} TL/ay'
                : '${_paketFiyat['pro']!['yillik']} TL/yıl',
            fiyatAlt: _paketPeriyot == 'aylik'
                ? ''
                : '≈ ${(_paketFiyat['pro']!['yillik']! / 12).round()} TL/ay — 2 ay bedava',
            ozellikler: [
              _Ozellik('Başlangıç paketinin tüm özellikleri', true, bold: true),
              _Ozellik('WhatsApp ile randevu hatırlatma (1 gün önce + yaklaşan)', true),
              _Ozellik('Randevu iptali / güncelleme bildirimi', true),
              _Ozellik('Otomatik SMS yedek', true),
              _Ozellik('Mesaj geçmişi ve alıcı listesi', true),
              _Ozellik('Detaylı istatistik paneli', true),
            ],
            aktif: aktifPaket == 'pro' || aktifPaket == 'premium',
            populer: true,
            deneme: deneme && (aktifPaket == 'pro' || aktifPaket == 'premium'),
            kalanGun: kalanGun,
            color: Color(0xFF25D366),
          ),
        ],
      ),
    );
  }

  Widget _denemeBandi(String? baslangic, String bitis, int? kalanGun) {
    final uyari = (kalanGun != null && kalanGun <= 7);
    final renk = uyari ? Colors.orange : Color(0xFF25D366);
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [renk.withValues(alpha: 0.15), renk.withValues(alpha: 0.05)]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: renk.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Text('🎁', style: TextStyle(fontSize: 28)),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ücretsiz Deneme Aktif',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: renk)),
                SizedBox(height: 2),
                Text(
                  '📅 Başlangıç: ${baslangic ?? "—"}  ·  Bitiş: $bitis',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                ),
                if (kalanGun != null)
                  Text('$kalanGun gün kaldı',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: renk)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _paketBaslik(String aktifPaket, int? kalanGun, bool deneme) {
    final labels = {
      'baslangic': 'Başlangıç (Ücretsiz)',
      'pro': 'WhatsApp Hatırlatma',
      'premium': 'WhatsApp Hatırlatma',
    };
    var mevcut = labels[aktifPaket] ?? aktifPaket;
    if (kalanGun != null && (aktifPaket == 'pro' || aktifPaket == 'premium')) {
      mevcut += ' — $kalanGun gün kaldı';
    }
    if (deneme) mevcut += ' (Deneme)';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'WhatsApp Randevu Hatırlatma Paketi',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        SizedBox(height: 4),
        Text(
          'WhatsApp üzerinden otomatik randevu hatırlatması gönderin, randevuya gelmeyen müşteri sayısını azaltın.',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Color(0xFF25D366).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: 'Mevcut paket: ', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                TextSpan(text: mevcut, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF25D366))),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _periyotToggle() {
    Widget btn(String key, String label, {String? rozet}) {
      final aktif = _paketPeriyot == key;
      return Expanded(
        child: InkWell(
          onTap: () => setState(() => _paketPeriyot = key),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: aktif ? Color(0xFF25D366) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: aktif ? Colors.white : Colors.grey.shade700,
                    )),
                if (rozet != null) ...[
                  SizedBox(width: 6),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: aktif ? Colors.white : Colors.orange,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(rozet,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: aktif ? Color(0xFF25D366) : Colors.white,
                        )),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          btn('aylik', 'Aylık'),
          btn('yillik', 'Yıllık', rozet: '2 AY BEDAVA'),
        ],
      ),
    );
  }

  Widget _paketKart(
    ColorScheme scheme, {
    required String paketTip,
    required String baslik,
    required String aciklama,
    required String fiyatBuyuk,
    required String fiyatAlt,
    required List<_Ozellik> ozellikler,
    required bool aktif,
    required bool populer,
    required bool deneme,
    required int? kalanGun,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: aktif ? Border.all(color: color, width: 2) : null,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (aktif)
            Container(
              padding: EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: Text(
                deneme ? '🎁 DENEME — ${kalanGun ?? 0} GÜN KALDI' : '✓ MEVCUT PAKETİNİZ',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11),
              ),
            )
          else if (populer)
            Container(
              padding: EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: Text(
                '⭐ ÖNERİLEN',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11),
              ),
            ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(baslik, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                SizedBox(height: 4),
                Text(aciklama, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                SizedBox(height: 12),
                Text(fiyatBuyuk, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: color)),
                if (fiyatAlt.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Text(fiyatAlt, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  ),
                SizedBox(height: 12),
                ...ozellikler.map((o) => Padding(
                      padding: EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            o.var_ ? Icons.check_circle : Icons.cancel,
                            color: o.var_ ? Color(0xFF25D366) : Colors.grey.shade400,
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              o.metin,
                              style: TextStyle(
                                fontSize: 12,
                                color: o.var_ ? Colors.black87 : Colors.grey,
                                fontWeight: o.bold ? FontWeight.w700 : FontWeight.normal,
                                decoration: o.var_ ? null : TextDecoration.lineThrough,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: aktif
                      ? OutlinedButton(
                          onPressed: null,
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            disabledForegroundColor: color,
                            side: BorderSide(color: color.withValues(alpha: 0.4)),
                          ),
                          child: Text(deneme ? 'Deneme Aktif' : 'Mevcut Paket',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                        )
                      : paketTip == 'baslangic'
                          ? OutlinedButton(
                              onPressed: null,
                              style: OutlinedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 12)),
                              child: Text('Ücretsiz', style: TextStyle(fontWeight: FontWeight.w700)),
                            )
                          : ElevatedButton(
                              onPressed: () => _paketTalepEt(paketTip),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: color,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Text('Hemen Başla', style: TextStyle(fontWeight: FontWeight.w800)),
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _paketTalepEt(String paket) async {
    final iletisimCtrl = TextEditingController();
    final fiyat = _paketFiyat[paket]?[_paketPeriyot] ?? 0;
    final birim = _paketPeriyot == 'aylik' ? 'TL/ay' : 'TL/yıl';
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'WhatsApp Randevu Hatırlatma\n$fiyat $birim',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Müşteri temsilcimiz sizinle iletişime geçerek ödeme ve aktivasyon süreci hakkında bilgi verecektir.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
            SizedBox(height: 12),
            TextField(
              controller: iletisimCtrl,
              decoration: InputDecoration(
                labelText: 'İletişim Bilgisi',
                hintText: 'örn. 0555 123 45 67',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text('İptal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF25D366), foregroundColor: Colors.white),
            child: Text('Talebi Gönder'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final iletisim = iletisimCtrl.text.trim();
    if (iletisim.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lütfen iletişim bilgisi girin.'), backgroundColor: Colors.red),
      );
      return;
    }
    final r = await whatsappPaketTalep(_salonId, paket: paket, periyot: _paketPeriyot, iletisim: iletisim);
    if (!mounted) return;
    if (r != null && r['ok'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(r['mesaj']?.toString() ?? 'Talebiniz alındı'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Talep gönderilemedi'), backgroundColor: Colors.red),
      );
    }
  }
}

class _Ozellik {
  final String metin;
  final bool var_;
  final bool bold;
  const _Ozellik(this.metin, this.var_, {this.bold = false});
}

/// WhatsApp "Paket" sekmesi: kontor ekranini web'den WebView ile gosterir.
/// Uygulama Bearer token'iyla tek kullanimlik imzali giris linki alir,
/// WebView o linki acar -> salon kendi oturumuyla kendi bakiyesi/paketlerini
/// gorur. Fiyat/paket degisikligi uygulama guncellemesi gerektirmez.
class _KontorWebView extends StatefulWidget {
  final String salonId;
  const _KontorWebView({Key? key, required this.salonId}) : super(key: key);

  @override
  State<_KontorWebView> createState() => _KontorWebViewState();
}

class _KontorWebViewState extends State<_KontorWebView> {
  WebViewController? _controller;
  bool _loading = true;
  String? _hata;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() {
      _hata = null;
      _loading = true;
    });
    try {
      final url = await mobilWebViewUrl(widget.salonId, hedef: 'kontor');
      if (url == null) {
        if (!mounted) return;
        setState(() {
          _hata = 'Kontör ekranı açılamadı. İnternet bağlantınızı kontrol edip tekrar deneyin.';
          _loading = false;
        });
        return;
      }
      final c = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
        ))
        ..loadRequest(Uri.parse(url));
      if (!mounted) return;
      setState(() => _controller = c);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hata = 'Bir hata oluştu, lütfen tekrar deneyin.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hata != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off, size: 42, color: Colors.grey),
              const SizedBox(height: 12),
              Text(_hata!, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[700])),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _init,
                icon: const Icon(Icons.refresh),
                label: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      );
    }
    return Stack(
      children: [
        if (_controller != null)
          WebViewWidget(
            controller: _controller!,
            // WebView dikey kaydirmayi kendi sahiplensin; aksi halde
            // TabBarView/parent scroll araya girip kaydirma kasiyor/takiliyordu.
            gestureRecognizers: {
              Factory<VerticalDragGestureRecognizer>(
                  () => VerticalDragGestureRecognizer()),
            },
          ),
        if (_loading) const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}

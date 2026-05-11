import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:randevu_sistem/Backend/backend.dart';

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

  // Paket
  bool _paketLoading = false;
  Map<String, dynamic>? _paket;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
    _salonId = widget.isletmebilgi['id'].toString();
    _yukleDurum();
  }

  @override
  void dispose() {
    _qrPoll?.cancel();
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
    setState(() => _aliciLoading = true);
    final r = await whatsappAliciler(_salonId);
    if (!mounted) return;
    setState(() {
      _aliciler = ((r?['rows'] as List?) ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      _aliciLoading = false;
    });
  }

  Future<void> _yuklePaket() async {
    if (_paket != null) return;
    setState(() => _paketLoading = true);
    final r = await whatsappPaketDurum(_salonId);
    if (!mounted) return;
    setState(() {
      _paket = r;
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
                onTap: (i) {
                  if (i == 1) _yukleLoglar(page: 1);
                  if (i == 2) _yukleAliciler();
                  if (i == 3) _yuklePaket();
                },
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
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onSubmitted: (v) {
                    _logFiltreTel = v;
                    _yukleLoglar(page: 1);
                  },
                ),
              ),
              SizedBox(width: 6),
              PopupMenuButton<int?>(
                icon: Icon(Icons.filter_list),
                onSelected: (v) {
                  _logFiltreDurum = v;
                  _yukleLoglar(page: 1);
                },
                itemBuilder: (c) => [
                  PopupMenuItem(value: null, child: Text('Tümü')),
                  PopupMenuItem(value: 1, child: Text('Başarılı')),
                  PopupMenuItem(value: 2, child: Text('Başarısız')),
                  PopupMenuItem(value: 3, child: Text('Fallback')),
                  PopupMenuItem(value: 0, child: Text('Beklemede')),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _logLoading
              ? Center(child: CircularProgressIndicator())
              : _loglar.isEmpty
                  ? Center(child: Text('Log yok', style: TextStyle(color: Colors.grey)))
                  : ListView.separated(
                      padding: EdgeInsets.fromLTRB(12, 4, 12, 80),
                      itemCount: _loglar.length,
                      separatorBuilder: (_, __) => SizedBox(height: 6),
                      itemBuilder: (c, i) => _logSatiri(scheme, _loglar[i]),
                    ),
        ),
        if (_logSonSayfa > 1) _paginationBar(scheme),
      ],
    );
  }

  Widget _logSatiri(ColorScheme scheme, Map<String, dynamic> l) {
    final d = (l['durum'] as num?)?.toInt() ?? 0;
    Color dc;
    String dl;
    IconData di;
    switch (d) {
      case 1: dc = Colors.green; dl = 'Başarılı'; di = Icons.check_circle; break;
      case 2: dc = Colors.red; dl = 'Başarısız'; di = Icons.error; break;
      case 3: dc = Colors.orange; dl = 'Fallback'; di = Icons.swap_horiz; break;
      default: dc = Colors.grey; dl = 'Beklemede'; di = Icons.schedule;
    }
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(di, color: dc, size: 22),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(l['telefon']?.toString() ?? '-', style: TextStyle(fontWeight: FontWeight.w700))),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: dc.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                      child: Text(dl, style: TextStyle(color: dc, fontWeight: FontWeight.w700, fontSize: 10)),
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
                  Text(l['hata'].toString(), style: TextStyle(fontSize: 11, color: Colors.red)),
              ],
            ),
          ),
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
    if (_aliciLoading) return Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _yukleAliciler,
      child: _aliciler.isEmpty
          ? ListView(children: [SizedBox(height: 100), Center(child: Text('Alıcı yok', style: TextStyle(color: Colors.grey)))])
          : ListView.separated(
              padding: EdgeInsets.fromLTRB(12, 8, 12, 80),
              itemCount: _aliciler.length,
              separatorBuilder: (_, __) => SizedBox(height: 6),
              itemBuilder: (c, i) {
                final a = _aliciler[i];
                final t = (a['toplam'] as num?)?.toInt() ?? 0;
                final b = (a['basari'] as num?)?.toInt() ?? 0;
                final f = (a['fail'] as num?)?.toInt() ?? 0;
                return InkWell(
                  onTap: () => _aliciGecmisAc(a['telefon']?.toString() ?? ''),
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Color(0xFF25D366).withValues(alpha: 0.12),
                          child: Icon(Icons.phone, color: Color(0xFF25D366)),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(a['telefon']?.toString() ?? '-', style: TextStyle(fontWeight: FontWeight.w700)),
                              if ((a['musteri_adi']?.toString() ?? '').isNotEmpty)
                                Text(a['musteri_adi'].toString(), style: TextStyle(fontSize: 11, color: Colors.grey)),
                              Row(
                                children: [
                                  Text('$t toplam', style: TextStyle(fontSize: 11)),
                                  SizedBox(width: 8),
                                  Text('✓$b', style: TextStyle(fontSize: 11, color: Colors.green)),
                                  SizedBox(width: 8),
                                  Text('✗$f', style: TextStyle(fontSize: 11, color: Colors.red)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _aliciGecmisAc(String telefon) async {
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
              padding: EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: snap.connectionState != ConnectionState.done
                  ? Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                        SizedBox(height: 12),
                        Text(telefon, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                        SizedBox(height: 12),
                        Expanded(
                          child: ListView(
                            controller: scroll,
                            children: ((snap.data?['rows'] as List?) ?? []).map<Widget>((r) {
                              final m = Map<String, dynamic>.from(r as Map);
                              return Padding(
                                padding: EdgeInsets.only(bottom: 6),
                                child: _logSatiri(Theme.of(context).colorScheme, m),
                              );
                            }).toList(),
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
    if (_paketLoading) return Center(child: CircularProgressIndicator());
    if (_paket == null) {
      return Center(child: TextButton.icon(onPressed: _yuklePaket, icon: Icon(Icons.refresh), label: Text('Yükle')));
    }
    final paket = _paket!['paket']?.toString() ?? 'baslangic';
    final periyot = _paket!['periyot']?.toString();
    final kalanGun = (_paket!['kalan_gun'] as num?)?.toInt();
    final deneme = _paket!['deneme'] == true;

    return ListView(
      padding: EdgeInsets.fromLTRB(12, 12, 12, 80),
      children: [
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Mevcut Paket', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _paketRengi(paket).withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(paket.toUpperCase(),
                        style: TextStyle(color: _paketRengi(paket), fontWeight: FontWeight.w800)),
                  ),
                  if (periyot != null) ...[
                    SizedBox(width: 6),
                    Text(periyot, style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                  if (deneme) ...[
                    SizedBox(width: 6),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(6)),
                      child: Text('DENEME', style: TextStyle(color: Colors.amber.shade800, fontWeight: FontWeight.w800, fontSize: 10)),
                    ),
                  ],
                ],
              ),
              if (kalanGun != null) ...[
                SizedBox(height: 8),
                Text('Kalan süre: $kalanGun gün', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ],
          ),
        ),
        SizedBox(height: 16),
        Text('Paket Yükselt', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        SizedBox(height: 8),
        _paketTeklif(scheme, 'pro', 'Pro Paket', 'Aylık 1500 mesaj, öncelikli destek', Colors.blue),
        _paketTeklif(scheme, 'premium', 'Premium Paket', 'Sınırsız mesaj + WA Business API + dedike destek', Colors.purple),
      ],
    );
  }

  Color _paketRengi(String p) {
    switch (p) {
      case 'pro': return Colors.blue;
      case 'premium': return Colors.purple;
      default: return Colors.grey;
    }
  }

  Widget _paketTeklif(ColorScheme scheme, String paketTip, String baslik, String aciklama, Color color) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.workspace_premium, color: color),
              SizedBox(width: 6),
              Text(baslik, style: TextStyle(fontWeight: FontWeight.w800, color: color)),
            ],
          ),
          SizedBox(height: 4),
          Text(aciklama, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
          SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _paketTalepEt(paketTip, 'aylik'),
                  child: Text('Aylık Talep'),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _paketTalepEt(paketTip, 'yillik'),
                  style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white),
                  child: Text('Yıllık Talep'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _paketTalepEt(String paket, String periyot) async {
    final iletisimCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('${paket.toUpperCase()} / ${periyot.toUpperCase()} talep'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Müşteri temsilcimiz sizinle iletişime geçecek.', style: TextStyle(fontSize: 12)),
            SizedBox(height: 8),
            TextField(
              controller: iletisimCtrl,
              decoration: InputDecoration(labelText: 'Tercih ettiğin iletişim (telefon/email)', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text('İptal')),
          ElevatedButton(onPressed: () => Navigator.pop(c, true), child: Text('Talep Et')),
        ],
      ),
    );
    if (ok != true) return;
    final r = await whatsappPaketTalep(_salonId, paket: paket, periyot: periyot, iletisim: iletisimCtrl.text.trim());
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

import 'package:flutter/material.dart';
import 'package:randevu_sistem/Backend/backend.dart';

import '../sms_yonetimi_state.dart';

class SmsRaporlariTab extends StatefulWidget {
  final SmsYonetimiController state;
  const SmsRaporlariTab({Key? key, required this.state}) : super(key: key);

  @override
  State<SmsRaporlariTab> createState() => _SmsRaporlariTabState();
}

class _SmsRaporlariTabState extends State<SmsRaporlariTab>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _altTab;
  bool _yukleniyor = false;
  Map<String, List<dynamic>> _raporlar = {
    'bildirim': [],
    'grup': [],
    'filtre': [],
    'toplu': [],
    'kampanya': [],
  };
  bool _yeniSms = false;

  static const List<_TurMeta> _turler = [
    _TurMeta('Bildirim SMS', 'bildirim'),
    _TurMeta('Grup SMS', 'grup'),
    _TurMeta('Filtreli SMS', 'filtre'),
    _TurMeta('Toplu SMS', 'toplu'),
    _TurMeta('Kampanya SMS', 'kampanya'),
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _altTab = TabController(length: _turler.length, vsync: this);
    _yukle();
  }

  @override
  void dispose() {
    _altTab.dispose();
    super.dispose();
  }

  Future<void> _yukle() async {
    setState(() => _yukleniyor = true);
    try {
      final res = await smsYonetimRaporlar(widget.state.salonId);
      _yeniSms = (res['yeni_sms'] ?? 0) == 1;
      setState(() {
        for (final m in _turler) {
          _raporlar[m.kod] = ((res[m.kod] as List?) ?? []);
        }
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  String _durumText(dynamic durumRaw) {
    final d = durumRaw == null ? 0 : (int.tryParse(durumRaw.toString()) ?? 0);
    switch (d) {
      case 0:
        return 'Bekliyor';
      case 1:
      case 2:
      case 3:
      case 99:
        return 'Gönderildi';
      case 4:
        return 'İleri Tarihli';
      case 10:
        return 'Onay Bekliyor';
      case 91:
        return 'Bakiye Yetersiz';
      case 92:
        return 'Gönderim Durduruldu';
      case 93:
        return 'Teknik Arıza';
      case 94:
        return 'Engellendi';
      case 95:
        return 'İptal Edildi';
      default:
        return 'Bilinmiyor';
    }
  }

  Color _durumRengi(dynamic durumRaw) {
    final d = durumRaw == null ? 0 : (int.tryParse(durumRaw.toString()) ?? 0);
    if (d == 1 || d == 2 || d == 3 || d == 99) return Colors.green;
    if (d == 0 || d == 4 || d == 10) return Colors.orange;
    return Colors.red;
  }

  Future<void> _detayGoster(String pkgId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('Alıcılar getiriliyor...'),
              ],
            ),
          ),
        ),
      ),
    );

    Map<String, dynamic> sonuc;
    try {
      sonuc = await smsYonetimRaporDetay(widget.state.salonId, pkgId);
    } catch (e) {
      sonuc = {'basarili': false, 'mesaj': e.toString()};
    }

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    final basarili = sonuc['basarili'] == true;
    final kayitlar =
        ((sonuc['kayitlar'] as List?) ?? []).cast<dynamic>();
    final mesaj = (sonuc['mesaj'] ?? '').toString();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Expanded(child: Text('SMS Gönderim Detayı')),
            IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: Icon(Icons.close)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: !basarili
              ? Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(mesaj.isEmpty ? 'Detay alınamadı' : mesaj),
                )
              : kayitlar.isEmpty
                  ? Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Kayıt bulunamadı'),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: kayitlar.length,
                      separatorBuilder: (_, __) => Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        final k = kayitlar[i] as Map<String, dynamic>;
                        return ListTile(
                          dense: true,
                          title: Text(
                            (k['ad'] ?? 'Kayıtlı Değil').toString(),
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${k['telefon'] ?? ''} • ${k['operator'] ?? ''}\n'
                            '${k['durum'] ?? ''} • ${k['iletim_tarihi'] ?? ''}',
                            style: TextStyle(fontSize: 12),
                          ),
                          isThreeLine: true,
                        );
                      },
                    ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text('Kapat')),
        ],
      ),
    );
  }

  Widget _raporListesi(List<dynamic> liste) {
    if (liste.isEmpty) {
      return Center(
        child: Text('Bu kategoride kayıt bulunamadı.',
            style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView.separated(
      itemCount: liste.length,
      separatorBuilder: (_, __) => Divider(height: 1),
      itemBuilder: (ctx, index) {
        final r = Map<String, dynamic>.from(liste[index] as Map);
        final tarih = (r['date'] ?? '').toString();
        final adet = (r['count'] ?? 0).toString();
        final fiyat = double.tryParse((r['price'] ?? 0).toString()) ?? 0;
        final adetInt = int.tryParse(adet) ?? 0;
        final toplamKredi = (fiyat * adetInt).toStringAsFixed(2);
        final mesajIcerik = (r['msgdetails'] ?? '').toString();
        final durum = r['status'];
        final pkgId = (r['id'] ?? '').toString();
        return Container(
          padding: EdgeInsets.all(12),
          color: index.isEven ? Colors.white : Colors.grey.shade50,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(tarih,
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Spacer(),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _durumRengi(durum).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _durumText(durum),
                      style: TextStyle(
                          color: _durumRengi(durum),
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6),
              Row(
                children: [
                  _ozelEtiket(Icons.people, '$adet adet'),
                  SizedBox(width: 8),
                  _ozelEtiket(Icons.toll, 'Kredi: $toplamKredi'),
                  if (_yeniSms && pkgId.isNotEmpty) ...[
                    Spacer(),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8)),
                      onPressed: () => _detayGoster(pkgId),
                      icon: Icon(Icons.list_alt, size: 16),
                      label: Text('Detay'),
                    ),
                  ],
                ],
              ),
              SizedBox(height: 6),
              Text(
                mesajIcerik,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _ozelEtiket(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.grey),
        SizedBox(width: 3),
        Text(text, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: TabBar(
                  controller: _altTab,
                  isScrollable: true,
                  labelColor: Colors.deepPurple,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.deepPurple,
                  tabs: _turler.map((t) => Tab(text: t.baslik)).toList(),
                ),
              ),
              IconButton(
                tooltip: 'Yenile',
                onPressed: _yukleniyor ? null : _yukle,
                icon: Icon(Icons.refresh),
              ),
            ],
          ),
        ),
        Expanded(
          child: _yukleniyor
              ? Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _altTab,
                  children: _turler
                      .map((t) => _raporListesi(_raporlar[t.kod] ?? []))
                      .toList(),
                ),
        ),
      ],
    );
  }
}

class _TurMeta {
  final String baslik;
  final String kod;
  const _TurMeta(this.baslik, this.kod);
}

import 'package:flutter/material.dart';
import 'package:randevu_sistem/Backend/backend.dart';

import '../karakter_sayaci.dart';
import '../musteri_secici.dart';
import '../sms_yonetimi_state.dart';

class SablonTopluSmsTab extends StatefulWidget {
  final SmsYonetimiController state;
  const SablonTopluSmsTab({Key? key, required this.state}) : super(key: key);

  @override
  State<SablonTopluSmsTab> createState() => _SablonTopluSmsTabState();
}

class _SablonTopluSmsTabState extends State<SablonTopluSmsTab>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _baslikCtrl = TextEditingController();
  final TextEditingController _mesajCtrl = TextEditingController();
  final GlobalKey<MusteriSeciciState> _seciciKey = GlobalKey();

  Set<int> _seciliIdler = {};
  int _seciliSayi = 0;
  bool _gonderiliyor = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _baslikCtrl.dispose();
    _mesajCtrl.dispose();
    super.dispose();
  }

  Future<void> _gonder() async {
    final mesaj = _mesajCtrl.text.trim();
    if (mesaj.isEmpty || _seciliIdler.isEmpty) {
      _bilgi('Lütfen alıcıları seçip mesajınızı yazınız.');
      return;
    }
    final ok = await _onay('${_seciliSayi} kişiye SMS gönderilecek. Onaylıyor musunuz?');
    if (ok != true) return;

    setState(() => _gonderiliyor = true);
    try {
      final res = await smsYonetimTopluGonder(
        widget.state.salonId,
        musteriIdler: _seciliIdler.toList(),
        mesaj: mesaj,
      );
      _bilgi((res['text'] ?? 'Gönderim tamamlandı').toString(),
          basarili: (res['status'] ?? '') == 'success');
      if ((res['status'] ?? '') == 'success') {
        _mesajCtrl.clear();
        _baslikCtrl.clear();
        _seciciKey.currentState?.tumunuKaldir();
        await widget.state.bakiyeYenile();
      }
    } catch (e) {
      _bilgi('Hata: $e');
    } finally {
      if (mounted) setState(() => _gonderiliyor = false);
    }
  }

  Future<void> _yeniSablon() async {
    final basAd = TextEditingController();
    final mesaj = TextEditingController();
    final kaydetmeSonucu = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Yeni Şablon'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: basAd,
                maxLength: 30,
                decoration: InputDecoration(
                    labelText: 'Şablon Adı',
                    border: OutlineInputBorder(),
                    isDense: true),
              ),
              SizedBox(height: 8),
              StatefulBuilder(
                builder: (ctx2, setStateDialog) => Column(
                  children: [
                    TextField(
                      controller: mesaj,
                      maxLines: 6,
                      decoration: InputDecoration(
                          labelText: 'Mesaj İçeriği',
                          border: OutlineInputBorder()),
                      onChanged: (_) => setStateDialog(() {}),
                    ),
                    SizedBox(height: 6),
                    KarakterSayaci(uzunluk: mesaj.text.length),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Vazgeç')),
          ElevatedButton(
              onPressed: () async {
                if (basAd.text.trim().isEmpty || mesaj.text.trim().isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                      content:
                          Text('Şablon adı ve mesajı boş olamaz')));
                  return;
                }
                try {
                  await smsYonetimTaslakKaydet(widget.state.salonId,
                      baslik: basAd.text.trim(),
                      icerik: mesaj.text.trim());
                  Navigator.pop(ctx, true);
                } catch (e) {
                  ScaffoldMessenger.of(ctx)
                      .showSnackBar(SnackBar(content: Text('Hata: $e')));
                }
              },
              child: Text('Kaydet')),
        ],
      ),
    );
    if (kaydetmeSonucu == true) {
      await widget.state.taslaklariYenile();
      _bilgi('Şablon kaydedildi', basarili: true);
    }
  }

  Future<void> _sablonSil(Map<String, dynamic> taslak) async {
    final id = taslak['id'].toString();
    final baslik = (taslak['baslik'] ?? '').toString();
    final ok = await _onay('"$baslik" şablonunu silmek istediğinize emin misiniz?');
    if (ok != true) return;
    try {
      await smsYonetimTaslakSil(salonId: widget.state.salonId, id: id);
      await widget.state.taslaklariYenile();
      _bilgi('Şablon silindi', basarili: true);
    } catch (e) {
      _bilgi('Hata: $e');
    }
  }

  void _bilgi(String mesaj, {bool basarili = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(mesaj),
      backgroundColor: basarili ? Colors.green : null,
    ));
  }

  Future<bool?> _onay(String mesaj) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Onay'),
        content: Text(mesaj),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Vazgeç')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true), child: Text('Tamam')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return AnimatedBuilder(
      animation: widget.state,
      builder: (_, __) {
        final taslaklar = widget.state.taslaklar;
        return SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                Icon(Icons.message, color: Colors.deepPurple),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Şablon Ayarları ve Toplu SMS',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple)),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white),
                  icon: Icon(Icons.add, size: 18),
                  label: Text('Şablon Oluştur'),
                  onPressed: _yeniSablon,
                ),
              ]),
              Divider(),
              TextField(
                controller: _baslikCtrl,
                decoration: InputDecoration(
                    labelText: 'Şablon Adı (opsiyonel)',
                    border: OutlineInputBorder(),
                    isDense: true),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _mesajCtrl,
                maxLines: 8,
                decoration: InputDecoration(
                    labelText: 'Mesaj İçeriği', border: OutlineInputBorder()),
                onChanged: (_) => setState(() {}),
              ),
              SizedBox(height: 6),
              KarakterSayaci(uzunluk: _mesajCtrl.text.length),
              SizedBox(height: 12),
              Text('Müşterileri Seçiniz',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(height: 6),
              MusteriSecici(
                key: _seciciKey,
                salonId: widget.state.salonId,
                onSelectionChanged: (idler, sayi) {
                  setState(() {
                    _seciliIdler = idler;
                    _seciliSayi = sayi;
                  });
                },
              ),
              SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14)),
                  icon: _gonderiliyor
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Icon(Icons.send),
                  label: Text(_gonderiliyor
                      ? 'Gönderiliyor...'
                      : 'Toplu SMS\'i Gönder'),
                  onPressed: _gonderiliyor ? null : _gonder,
                ),
              ),
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  border: Border(
                      top: BorderSide(color: Colors.grey.shade300),
                      bottom: BorderSide(color: Colors.grey.shade300)),
                ),
                child: Center(
                  child: Text(
                    'Şablonlar (üzerine tıklayarak metni yükleyin)',
                    style: TextStyle(
                        color: Colors.deepPurple,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SizedBox(height: 8),
              if (taslaklar.isEmpty)
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: Text('Henüz şablon oluşturmadınız.',
                        style: TextStyle(color: Colors.grey)),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: taslaklar.length,
                  gridDelegate:
                      SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.4,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemBuilder: (ctx, index) {
                    final t = taslaklar[index];
                    final baslik = (t['baslik'] ?? '').toString();
                    final icerik = (t['taslak_icerik'] ?? '').toString();
                    final salonId = t['salon_id'];
                    final silinebilir = salonId != null &&
                        salonId.toString() == widget.state.salonId;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _baslikCtrl.text = baslik;
                          _mesajCtrl.text = icerik;
                        });
                        _bilgi('Şablon yüklendi', basarili: true);
                      },
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(baslik,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13)),
                                ),
                                if (silinebilir)
                                  InkWell(
                                    onTap: () => _sablonSil(t),
                                    child: Padding(
                                      padding: EdgeInsets.all(4),
                                      child: Icon(Icons.delete_outline,
                                          color: Colors.red, size: 18),
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Expanded(
                              child: Text(
                                icerik,
                                maxLines: 5,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

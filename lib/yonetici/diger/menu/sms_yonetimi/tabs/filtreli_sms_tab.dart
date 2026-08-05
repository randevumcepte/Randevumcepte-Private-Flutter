import 'package:flutter/material.dart';
import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Frontend/aramali_dropdown.dart';

import '../karakter_sayaci.dart';
import '../musteri_secici.dart';
import '../sms_yonetimi_state.dart';

class FiltreliSmsTab extends StatefulWidget {
  final SmsYonetimiController state;
  const FiltreliSmsTab({Key? key, required this.state}) : super(key: key);

  @override
  State<FiltreliSmsTab> createState() => _FiltreliSmsTabState();
}

class _FiltreliSmsTabState extends State<FiltreliSmsTab>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _mesajCtrl = TextEditingController();
  final GlobalKey<MusteriSeciciState> _seciciKey = GlobalKey();

  String? _cinsiyet; // '0' Kadın, '1' Erkek, null Tüm
  String? _seciliTaslakBasligi;
  Set<int> _seciliIdler = {};
  int _seciliSayi = 0;
  bool _gonderiliyor = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _mesajCtrl.dispose();
    super.dispose();
  }

  Future<void> _gonder() async {
    final mesaj = _mesajCtrl.text.trim();
    if (mesaj.isEmpty || _seciliIdler.isEmpty) {
      _bilgi('Lütfen alıcıları seçip mesajınızı yazınız.');
      return;
    }
    final ok = await _onayKutusu(
        '${_seciliSayi} kişiye SMS gönderilecek. Onaylıyor musunuz?');
    if (ok != true) return;

    setState(() => _gonderiliyor = true);
    try {
      final res = await smsYonetimFiltreliGonder(
        widget.state.salonId,
        musteriIdler: _seciliIdler.toList(),
        mesaj: mesaj,
      );
      _bilgi((res['text'] ?? 'Gönderim tamamlandı').toString(),
          basarili: (res['status'] ?? '') == 'success');
      if ((res['status'] ?? '') == 'success') {
        _mesajCtrl.clear();
        _seciciKey.currentState?.tumunuKaldir();
        await widget.state.bakiyeYenile();
      }
    } catch (e) {
      _bilgi('Hata: $e');
    } finally {
      if (mounted) setState(() => _gonderiliyor = false);
    }
  }

  void _bilgi(String mesaj, {bool basarili = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(mesaj),
      backgroundColor: basarili ? Colors.green : null,
    ));
  }

  Future<bool?> _onayKutusu(String mesaj) {
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
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Gönder')),
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
                Icon(Icons.filter_list, color: Colors.deepPurple),
                SizedBox(width: 8),
                Text('Filtreli SMS Gönder',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple)),
              ]),
              Divider(),
              Text('Cinsiyet', style: TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(height: 6),
              AramaliDropdownFormField<String?>(
                value: _cinsiyet,
                isDense: true,
                decoration: InputDecoration(
                    isDense: true, border: OutlineInputBorder()),
                items: [
                  DropdownMenuItem(value: null, child: Text('Tümü')),
                  DropdownMenuItem(value: '0', child: Text('Kadın')),
                  DropdownMenuItem(value: '1', child: Text('Erkek')),
                ],
                onChanged: (v) {
                  setState(() => _cinsiyet = v);
                },
              ),
              SizedBox(height: 12),
              Text('Şablon Seçiniz',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(height: 6),
              AramaliDropdownFormField<String?>(
                value: _seciliTaslakBasligi,
                isDense: true,
                isExpanded: true,
                decoration: InputDecoration(
                    isDense: true, border: OutlineInputBorder()),
                items: [
                  DropdownMenuItem(value: null, child: Text('Seçiniz')),
                  ...taslaklar.map((t) {
                    final baslik = (t['baslik'] ?? '').toString();
                    final icerik = (t['taslak_icerik'] ?? '').toString();
                    return DropdownMenuItem(
                      value: '$baslik|$icerik',
                      child: Text(baslik, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                ],
                onChanged: (v) {
                  setState(() {
                    _seciliTaslakBasligi = v;
                    if (v != null) {
                      final p = v.indexOf('|');
                      if (p > 0) _mesajCtrl.text = v.substring(p + 1);
                    }
                  });
                },
              ),
              SizedBox(height: 12),
              Text('Mesaj İçeriği',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(height: 6),
              TextField(
                controller: _mesajCtrl,
                maxLines: 6,
                decoration: InputDecoration(border: OutlineInputBorder()),
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
                cinsiyet: _cinsiyet,
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
                  label: Text(
                      _gonderiliyor ? 'Gönderiliyor...' : 'SMS Gönder'),
                  onPressed: _gonderiliyor ? null : _gonder,
                ),
              ),
              SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

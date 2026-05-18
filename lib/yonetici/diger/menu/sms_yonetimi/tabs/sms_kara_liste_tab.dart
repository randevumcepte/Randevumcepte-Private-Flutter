import 'dart:async';

import 'package:flutter/material.dart';
import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Backend/yetki.dart';

import '../sms_yonetimi_state.dart';

class SmsKaraListeTab extends StatefulWidget {
  final SmsYonetimiController state;
  const SmsKaraListeTab({Key? key, required this.state}) : super(key: key);

  @override
  State<SmsKaraListeTab> createState() => _SmsKaraListeTabState();
}

class _SmsKaraListeTabState extends State<SmsKaraListeTab>
    with AutomaticKeepAliveClientMixin {
  bool _yukleniyor = false;
  List<Map<String, dynamic>> _liste = [];
  final TextEditingController _aramaCtrl = TextEditingController();
  String _arama = '';
  Timer? _aramaTimer;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  @override
  void dispose() {
    _aramaCtrl.dispose();
    _aramaTimer?.cancel();
    super.dispose();
  }

  Future<void> _yukle() async {
    setState(() => _yukleniyor = true);
    try {
      final res = await smsYonetimKaraListe(widget.state.salonId);
      _liste = ((res['kayitlar'] as List?) ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (_) {
      _liste = [];
    } finally {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  Future<void> _ekleDialog() async {
    Map<String, dynamic>? secilen;
    final aramaCtrl = TextEditingController();
    List<Map<String, dynamic>> sonuclar = [];
    bool araniyor = false;
    Timer? timer;

    Future<void> ara(StateSetter setStateDialog, String q) async {
      timer?.cancel();
      timer = Timer(const Duration(milliseconds: 350), () async {
        setStateDialog(() => araniyor = true);
        try {
          final res = await smsYonetimMusteriListele(
            widget.state.salonId,
            page: 1,
            perPage: 50,
            search: q,
          );
          sonuclar = ((res['customers'] as List?) ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        } catch (_) {}
        setStateDialog(() => araniyor = false);
      });
    }

    final eklendi = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) => AlertDialog(
            title: Text('Kara Listeye Ekle'),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: aramaCtrl,
                    decoration: InputDecoration(
                        labelText: 'Müşteri Ara',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder()),
                    onChanged: (q) => ara(setStateDialog, q),
                  ),
                  SizedBox(height: 8),
                  if (araniyor)
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: CircularProgressIndicator(),
                    )
                  else
                    Container(
                      height: 280,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: sonuclar.isEmpty
                          ? Center(
                              child: Text('Müşteri arayın',
                                  style: TextStyle(color: Colors.grey)))
                          : ListView.separated(
                              itemCount: sonuclar.length,
                              separatorBuilder: (_, __) =>
                                  Divider(height: 1),
                              itemBuilder: (ctx2, i) {
                                final m = sonuclar[i];
                                final id = m['id'].toString();
                                return RadioListTile<String>(
                                  value: id,
                                  groupValue: secilen?['id']?.toString(),
                                  onChanged: (_) =>
                                      setStateDialog(() => secilen = m),
                                  title: Text((m['name'] ?? '').toString()),
                                  subtitle: Text(
                                      Yetki.telefonGoster((m['telefon'] ?? '').toString())),
                                  dense: true,
                                );
                              },
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
                onPressed: secilen == null
                    ? null
                    : () async {
                        try {
                          await smsYonetimKaraListeEkle(
                              widget.state.salonId,
                              secilen!['id'].toString());
                          Navigator.pop(ctx, true);
                        } catch (e) {
                          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                              content: Text('Hata: $e'),
                              backgroundColor: Colors.red));
                        }
                      },
                child: Text('Ekle'),
              ),
            ],
          ),
        );
      },
    );

    if (eklendi == true) {
      await _yukle();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Kara listeye eklendi'),
            backgroundColor: Colors.green));
      }
    }
  }

  Future<void> _kaldir(Map<String, dynamic> kayit) async {
    final ad = (kayit['ad_soyad'] ?? '').toString();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Onay'),
        content: Text('$ad numarasını kara listeden kaldırmak istiyor musunuz?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Vazgeç')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Kaldır')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await smsYonetimKaraListeSil(
          widget.state.salonId, kayit['user_id'].toString());
      await _yukle();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Kara listeden çıkarıldı'),
            backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _aramaDegisti(String yeni) {
    _aramaTimer?.cancel();
    _aramaTimer = Timer(const Duration(milliseconds: 250), () {
      setState(() => _arama = yeni.toLowerCase().trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final filtreli = _arama.isEmpty
        ? _liste
        : _liste
            .where((m) =>
                ((m['ad_soyad'] ?? '')
                            .toString()
                            .toLowerCase()
                            .contains(_arama) ||
                        (m['telefon'] ?? '')
                            .toString()
                            .toLowerCase()
                            .contains(_arama)))
            .toList();
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _aramaCtrl,
                  decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Ara: isim veya telefon',
                      prefixIcon: Icon(Icons.search, size: 20),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8))),
                  onChanged: _aramaDegisti,
                ),
              ),
              SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white),
                icon: Icon(Icons.add, size: 18),
                label: Text('Ekle'),
                onPressed: _ekleDialog,
              ),
              SizedBox(width: 4),
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
              : (filtreli.isEmpty
                  ? Center(
                      child: Text('Kara listede kayıt yok.',
                          style: TextStyle(color: Colors.grey)))
                  : ListView.separated(
                      itemCount: filtreli.length,
                      separatorBuilder: (_, __) => Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        final m = filtreli[i];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.red.shade50,
                            child: Icon(Icons.block, color: Colors.red),
                          ),
                          title: Text((m['ad_soyad'] ?? '').toString()),
                          subtitle: Text(
                              '${Yetki.telefonGoster((m['telefon'] ?? '').toString())}\nEklenme: ${m['eklenme_tarihi'] ?? ''}'),
                          isThreeLine: true,
                          trailing: TextButton.icon(
                            onPressed: () => _kaldir(m),
                            icon:
                                Icon(Icons.remove_circle_outline, size: 18),
                            label: Text('Kaldır'),
                            style: TextButton.styleFrom(
                                foregroundColor: Colors.red),
                          ),
                        );
                      },
                    )),
        ),
      ],
    );
  }
}

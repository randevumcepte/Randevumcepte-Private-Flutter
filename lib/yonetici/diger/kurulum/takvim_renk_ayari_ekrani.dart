import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';

import 'takvim_renk_api.dart';

/// Takvim "Tek Renk" ayar ekrani (mobil).
/// Acikken randevu takviminde tum personel/oda/cihaz kolonlari ve bu kaynaklara
/// ait normal randevular secilen tek renge boyanir. Durum renkleri korunur.
class TakvimRenkAyariEkrani extends StatefulWidget {
  final dynamic isletmebilgi;
  const TakvimRenkAyariEkrani({Key? key, required this.isletmebilgi}) : super(key: key);

  @override
  State<TakvimRenkAyariEkrani> createState() => _TakvimRenkAyariEkraniState();
}

class _TakvimRenkAyariEkraniState extends State<TakvimRenkAyariEkrani> {
  // Varsayilan palet (API'den 10'lu skala gelmezse kullanilir).
  static const List<String> _varsayilanPalet = [
    '#5C008E', '#7E57C2', '#3F51B5', '#2196F3', '#0097A7', '#009688',
    '#2E7D32', '#689F38', '#F9A825', '#EF6C00', '#E64A19', '#C62828',
  ];

  List<String> _palet = _varsayilanPalet;
  bool _aktif = false;
  String _renk = '#5C008E';
  bool _yukleniyor = true;
  bool _kaydediliyor = false;
  final TextEditingController _hexCtrl = TextEditingController();

  String get _salonId => widget.isletmebilgi['id'].toString();

  @override
  void initState() {
    super.initState();
    _getir();
  }

  @override
  void dispose() {
    _hexCtrl.dispose();
    super.dispose();
  }

  String _normHex(String v) {
    v = v.trim();
    if (v.isNotEmpty && !v.startsWith('#')) v = '#$v';
    return v.toUpperCase();
  }

  bool _gecerli(String v) => RegExp(r'^#[0-9A-F]{6}$').hasMatch(v);

  void _renkAyarla(String v) {
    v = _normHex(v);
    if (!_gecerli(v)) return;
    setState(() => _renk = v);
    if (_hexCtrl.text.toUpperCase() != v) _hexCtrl.text = v;
  }

  Future<void> _getir() async {
    final ayar = await TakvimRenkApi.fetch(_salonId);
    if (!mounted) return;
    setState(() {
      if (ayar != null) {
        _aktif = ayar.aktif;
        _renk = ayar.renk.toUpperCase();
        if (ayar.palet.isNotEmpty) _palet = ayar.palet;
      }
      _hexCtrl.text = _renk;
      _yukleniyor = false;
    });
  }

  Future<void> _kaydet() async {
    setState(() => _kaydediliyor = true);
    final ok = await TakvimRenkApi.push(_salonId, _aktif, _renk);
    if (!mounted) return;
    setState(() => _kaydediliyor = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Takvim renk ayarı kaydedildi' : 'Kaydedilemedi, tekrar deneyin'),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );
    if (ok) Navigator.of(context).pop(true);
  }

  Color _c(String hex) {
    try {
      return HexColor(hex);
    } catch (_) {
      return const Color(0xFF5C008E);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        toolbarHeight: 60,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Takvim Renk Ayarı', style: TextStyle(color: Colors.black)),
      ),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeColor: Colors.purple,
                    title: const Text('Tüm kaynaklar için tek renk kullan',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text(
                        'Açıkken takvimde tüm personel, oda ve cihaz kolonları ile normal randevular seçtiğiniz tek renge boyanır. Geldi (yeşil) / gelmedi (kırmızı) / bekliyor (sarı) gibi durum renkleri korunur.'),
                    value: _aktif,
                    onChanged: (v) => setState(() => _aktif = v),
                  ),
                  const Divider(height: 24),
                  Opacity(
                    opacity: _aktif ? 1 : 0.4,
                    child: IgnorePointer(
                      ignoring: !_aktif,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: _c(_renk),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.black12),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _hexCtrl,
                                  maxLength: 7,
                                  textCapitalization: TextCapitalization.characters,
                                  style: const TextStyle(fontFamily: 'monospace', fontSize: 16),
                                  decoration: const InputDecoration(
                                    labelText: 'Renk kodu (hex)',
                                    hintText: '#5C008E',
                                    counterText: '',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                  ),
                                  onChanged: (v) {
                                    final n = _normHex(v);
                                    if (_gecerli(n)) _renkAyarla(n);
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text('10 renk skalanızdan seçin', style: TextStyle(color: Colors.black54)),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: _palet.map((hex) {
                              final secili = hex.toUpperCase() == _renk.toUpperCase();
                              return GestureDetector(
                                onTap: () => _renkAyarla(hex),
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: _c(hex),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: secili ? Colors.black : Colors.black12,
                                      width: secili ? 3 : 1,
                                    ),
                                  ),
                                  child: secili
                                      ? const Icon(Icons.check, color: Colors.white, size: 22)
                                      : null,
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: _kaydediliyor
                          ? const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save, color: Colors.white),
                      label: const Text('Kaydet', style: TextStyle(color: Colors.white, fontSize: 16)),
                      onPressed: _kaydediliyor ? null : _kaydet,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

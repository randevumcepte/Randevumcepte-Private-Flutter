import 'dart:async';

import 'package:flutter/material.dart';
import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Backend/yetki.dart';

/// Sayfalanmış müşteri listesi seçici.
/// SMS Yönetimi sayfasındaki "Müşterileri Seçiniz" alanı ile aynı işi yapar.
class MusteriSecici extends StatefulWidget {
  final String salonId;
  final String? cinsiyet;
  final void Function(Set<int> seciliIdler, int toplam) onSelectionChanged;

  const MusteriSecici({
    Key? key,
    required this.salonId,
    required this.onSelectionChanged,
    this.cinsiyet,
  }) : super(key: key);

  @override
  State<MusteriSecici> createState() => MusteriSeciciState();
}

class MusteriSeciciState extends State<MusteriSecici> {
  final TextEditingController _aramaCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final Set<int> _seciliIdler = {};

  List<Map<String, dynamic>> _musteriler = [];
  int _toplam = 0;
  int _sayfa = 1;
  static const int _perPage = 200;
  bool _yukleniyor = false;
  bool _ilkYukleme = true;
  bool _hepsiSecili = false;
  Timer? _aramaTimer;
  String _arama = '';
  String? _aktifCinsiyet;

  Set<int> get seciliIdler => _seciliIdler;
  int get toplamMusteri => _toplam;
  int get seciliSayi =>
      _hepsiSecili ? _toplam : _seciliIdler.length;

  @override
  void initState() {
    super.initState();
    _aktifCinsiyet = widget.cinsiyet;
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >=
              _scrollCtrl.position.maxScrollExtent - 120 &&
          !_yukleniyor &&
          _musteriler.length < _toplam) {
        _yukle(_sayfa, append: true);
      }
    });
    _yukle(1);
  }

  @override
  void didUpdateWidget(covariant MusteriSecici oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cinsiyet != widget.cinsiyet) {
      _aktifCinsiyet = widget.cinsiyet;
      _sayfa = 1;
      _musteriler.clear();
      _yukle(1);
    }
  }

  @override
  void dispose() {
    _aramaTimer?.cancel();
    _aramaCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _yukle(int sayfa, {bool append = false}) async {
    if (_yukleniyor) return;
    setState(() => _yukleniyor = true);
    try {
      final res = await smsYonetimMusteriListele(
        widget.salonId,
        page: sayfa,
        perPage: _perPage,
        search: _arama,
        cinsiyet: _aktifCinsiyet ?? '',
      );
      final yeniListe = ((res['customers'] as List?) ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      _toplam = int.tryParse((res['total'] ?? 0).toString()) ?? 0;
      _sayfa = sayfa + 1;
      if (!mounted) return;
      setState(() {
        if (append) {
          _musteriler.addAll(yeniListe);
        } else {
          _musteriler = yeniListe;
        }
        _ilkYukleme = false;
      });
      _bildirSecim();
    } catch (_) {
      if (mounted) setState(() => _ilkYukleme = false);
    } finally {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  void _bildirSecim() {
    widget.onSelectionChanged(
      _hepsiSecili ? Set<int>.from(_musteriIdlerHepsiVarsayim()) : _seciliIdler,
      _hepsiSecili ? _toplam : _seciliIdler.length,
    );
  }

  Set<int> _musteriIdlerHepsiVarsayim() {
    // Hepsi secili durumunda tum sayfalardan toplanan ID'leri kullaniyoruz.
    return _seciliIdler;
  }

  Future<void> tumunuSec() async {
    setState(() => _yukleniyor = true);
    try {
      final res = await smsYonetimMusteriListele(
        widget.salonId,
        page: 1,
        perPage: 1000000,
        search: _arama,
        cinsiyet: _aktifCinsiyet ?? '',
      );
      final idList = ((res['musteriIdler'] as List?) ?? [])
          .map((e) => int.tryParse(e.toString()) ?? 0)
          .where((i) => i > 0)
          .toSet();
      if (!mounted) return;
      setState(() {
        _seciliIdler
          ..clear()
          ..addAll(idList);
        _hepsiSecili = true;
      });
      _bildirSecim();
    } finally {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  void tumunuKaldir() {
    setState(() {
      _seciliIdler.clear();
      _hepsiSecili = false;
    });
    _bildirSecim();
  }

  void temizle() => tumunuKaldir();

  void _tekKisiToggle(int id, bool secili) {
    setState(() {
      if (secili) {
        _seciliIdler.add(id);
      } else {
        _seciliIdler.remove(id);
        _hepsiSecili = false;
      }
    });
    _bildirSecim();
  }

  void _aramaDegisti(String yeni) {
    _aramaTimer?.cancel();
    _aramaTimer = Timer(const Duration(milliseconds: 350), () {
      _arama = yeni.trim();
      _sayfa = 1;
      _musteriler.clear();
      _yukle(1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _aramaCtrl,
          decoration: InputDecoration(
            isDense: true,
            hintText: 'Müşteri arayın...',
            prefixIcon: Icon(Icons.search, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onChanged: _aramaDegisti,
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _yukleniyor ? null : tumunuSec,
                icon: Icon(Icons.select_all, size: 18),
                label: Text('Tümünü Seç'),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _yukleniyor ? null : tumunuKaldir,
                icon: Icon(Icons.deselect, size: 18),
                label: Text('Tümünü Kaldır'),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Container(
          height: 240,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _ilkYukleme
              ? Center(child: CircularProgressIndicator())
              : (_musteriler.isEmpty
                  ? Center(
                      child: Text('Müşteri bulunamadı.',
                          style: TextStyle(color: Colors.grey)),
                    )
                  : ListView.separated(
                      controller: _scrollCtrl,
                      itemCount: _musteriler.length + (_yukleniyor ? 1 : 0),
                      separatorBuilder: (_, __) => Divider(height: 1),
                      itemBuilder: (ctx, index) {
                        if (index >= _musteriler.length) {
                          return Padding(
                            padding: const EdgeInsets.all(12),
                            child: Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          );
                        }
                        final m = _musteriler[index];
                        final id = int.tryParse(m['id'].toString()) ?? 0;
                        final ad = (m['name'] ?? '').toString();
                        final tel = Yetki.telefonGoster((m['telefon'] ?? '').toString());
                        final secili = _hepsiSecili || _seciliIdler.contains(id);
                        return CheckboxListTile(
                          dense: true,
                          controlAffinity: ListTileControlAffinity.leading,
                          value: secili,
                          onChanged: (v) => _tekKisiToggle(id, v ?? false),
                          title: Text(
                            ad.isEmpty ? '(İsimsiz)' : ad,
                            style: TextStyle(fontSize: 14),
                          ),
                          subtitle: tel.isEmpty
                              ? null
                              : Text(tel,
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey)),
                        );
                      },
                    )),
        ),
        SizedBox(height: 6),
        Text(
          '${seciliSayi} müşteri seçildi',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';

import '../../../../../Backend/backend.dart';
import '../../../../../Models/isletmehizmetleri.dart';
import '../../../../../Models/paket_hizmetleri.dart';

class BirHizmetDaha extends StatefulWidget {
  final List<PaketHizmetleri> secilihizmetler;
  final PaketHizmetleri? duzenlenecek;
  final dynamic isletmebilgi;

  BirHizmetDaha({
    Key? key,
    required this.secilihizmetler,
    this.duzenlenecek,
    required this.isletmebilgi,
  }) : super(key: key);

  @override
  _BirHizmetDahaState createState() => _BirHizmetDahaState();
}

class _BirHizmetDahaState extends State<BirHizmetDaha> {
  late List<IsletmeHizmet> isletmehizmetliste;
  Set<String> selectedHizmetIds = {};
  Map<String, PaketHizmetleri> existingHizmetler = {};
  bool _isloading = true;

  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    initialize();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  Future<void> initialize() async {
    var seciliisletme = await secilisalonid();
    final liste = await isletmehizmetleri(seciliisletme!);
    setState(() {
      isletmehizmetliste = liste;
      for (var h in widget.secilihizmetler) {
        selectedHizmetIds.add(h.hizmet_id);
        existingHizmetler[h.hizmet_id] = h;
      }
      _isloading = false;
    });
  }

  void _toggleHizmet(String id, bool? checked) {
    setState(() {
      if (checked == true) {
        selectedHizmetIds.add(id);
      } else {
        selectedHizmetIds.remove(id);
      }
    });
  }

  void _kaydet() {
    final List<PaketHizmetleri> result = [];
    for (var item in isletmehizmetliste) {
      final id = item.hizmet["id"].toString();
      if (selectedHizmetIds.contains(id)) {
        final existing = existingHizmetler[id];
        result.add(PaketHizmetleri(
          seans: existing?.seans ?? '0',
          fiyat: existing?.fiyat ?? '0',
          hizmet: item.hizmet,
          hizmet_id: id,
        ));
      }
    }
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pakete Hizmet Seç', style: TextStyle(color: Colors.black)),
        leading: IconButton(
          icon: Icon(Icons.clear_rounded, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (widget.isletmebilgi["demo_hesabi"].toString() == "1")
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: SizedBox(
                width: 100,
                child: YukseltButonu(isletme_bilgi: widget.isletmebilgi),
              ),
            ),
        ],
        toolbarHeight: 60,
        backgroundColor: Colors.white,
      ),
      body: _isloading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: TextFormField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Hizmet Ara...',
                      prefixIcon: Icon(Icons.search, color: Color(0xFF6A1B9A)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF6A1B9A)),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF6A1B9A)),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final filtered = isletmehizmetliste.where((item) {
                        final hizmetAdi = item.hizmet['hizmet_adi']?.toString().toLowerCase() ?? '';
                        return _searchQuery.isEmpty || hizmetAdi.contains(_searchQuery);
                      }).toList();

                      if (filtered.isEmpty) {
                        return Center(child: Text('Hizmet bulunamadı'));
                      }

                      return ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          final id = item.hizmet["id"].toString();
                          final isSelected = selectedHizmetIds.contains(id);
                          return CheckboxListTile(
                            title: Text(item.hizmet['hizmet_adi']?.toString() ?? ''),
                            value: isSelected,
                            onChanged: (val) => _toggleHizmet(id, val),
                            activeColor: Color(0xFF6A1B9A),
                            controlAffinity: ListTileControlAffinity.leading,
                            dense: true,
                          );
                        },
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  child: ElevatedButton(
                    onPressed: _kaydet,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.green,
                      minimumSize: Size(double.infinity, 45),
                    ),
                    child: Text('Kaydet (${selectedHizmetIds.length} seçili)'),
                  ),
                ),
              ],
            ),
    );
  }
}

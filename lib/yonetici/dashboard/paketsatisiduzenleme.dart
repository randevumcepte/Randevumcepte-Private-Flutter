import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';

import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Frontend/tlrakamacevir.dart';
import 'package:randevu_sistem/Models/adisyonpaketler.dart';
import 'package:randevu_sistem/Models/paketler.dart';
import 'package:randevu_sistem/Models/personel.dart';


class PaketSatisiDuzenleme extends StatefulWidget {
  final String musteriid;
  final bool senetlisatis;
  final AdisyonPaket mevcutpaket;
  final dynamic isletmebilgi;
  PaketSatisiDuzenleme({Key? key,required this.musteriid,required this.senetlisatis,required this.mevcutpaket,required this.isletmebilgi}) : super(key: key);
  @override
  _PaketSatisiState createState() => _PaketSatisiState();
}
class _PaketSatisiState extends State<PaketSatisiDuzenleme> {
  var tryformat = NumberFormat.currency(locale: 'tr_TR',symbol: "");
  late List<Personel> paketsatici;
  bool isloading=true;
  String? seciliisletme;
  TimeOfDay _selectedTime = TimeOfDay.now();
  late List<Paket> paket;
  Paket? selectedPaket;
  TextEditingController paketler = TextEditingController();
  Personel? selectedPaketSatici;
  TextEditingController psatici = TextEditingController();
  TextEditingController baslangictarihi = TextEditingController();
  TextEditingController pfiyat = TextEditingController();
  TextEditingController pseans = TextEditingController();
  TextEditingController randevusaati = TextEditingController();
  void initState() {
    super.initState();
    initialize();

  }
  Future<void> initialize() async{
    seciliisletme = (await secilisalonid())!;
    List <Personel> personelliste = await personellistegetir(seciliisletme!);
    List <Paket> paketliste = await paket_liste(seciliisletme!);
    setState(() {
      // id'ye gore tekille (ayni value 2+ -> DropdownButton2 assertion'i onler)
      final gorulenPers = <String>{};
      paketsatici = [for (final p in personelliste) if (gorulenPers.add(p.id)) p];
      final gorulenPaket = <String>{};
      paket = [for (final p in paketliste) if (gorulenPaket.add(p.id)) p];

      // firstWhere orElse'siz StateError firlatabilir (paket/personel silinmis/arsivli/
      // bos id). where().toList ile guvenli -> yoksa null (dropdown bos baslar).
      final eslP = paket.where((e) => e.id == widget.mevcutpaket.paket_id).toList();
      selectedPaket = eslP.isNotEmpty ? eslP.first : null;
      final eslS = paketsatici.where((e) => e.id == widget.mevcutpaket.personel_id).toList();
      selectedPaketSatici = eslS.isNotEmpty ? eslS.first : null;
      pfiyat.text = tryformat.format(double.parse(widget.mevcutpaket.fiyat)).toString();
      pseans.text = widget.mevcutpaket.seans_araligi;


      isloading = false;
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Paket Düzenleme',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.grey.shade700),
          onPressed: () => Navigator.of(context).pop(),
        ),
        toolbarHeight: 70,
        actions: [
          if (widget.isletmebilgi["demo_hesabi"].toString() == "1")
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: YukseltButonu(isletme_bilgi: widget.isletmebilgi),
            ),
        ],
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.05),
      ),
      body: isloading
          ? Center(
              child: CircularProgressIndicator(
                color: Colors.purple.shade700,
              ),
            )
          : GestureDetector(
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Başlık Kartı
                    Container(
                      margin: EdgeInsets.only(bottom: 16),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.purple.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.edit_outlined,
                              color: Colors.purple.shade700,
                              size: 20,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Paket Düzenleme',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                                Text(
                                  'Mevcut paket bilgilerini güncelleyin',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Paket Seçimi
                    _buildInputCard(
                      icon: Icons.inventory_2_outlined,
                      title: 'Paket',
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton2<Paket>(
                          isExpanded: true,
                          hint: Text(
                            'Paket seçin',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          items: paket
                              .map((item) => DropdownMenuItem(
                                    value: item,
                                    child: Text(
                                      item.paket_adi,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade800,
                                      ),
                                    ),
                                  ))
                              .toList(),
                          value: selectedPaket,
                          onChanged: (value) {
                            setState(() {
                              selectedPaket = value;
                              double fiyat = 0;
                              value?.hizmetler.forEach((element) {
                                fiyat += element["fiyat"];
                              });
                              pfiyat.text = tryformat.format(fiyat);
                            });
                          },
                          buttonStyleData: ButtonStyleData(
                            padding: EdgeInsets.symmetric(horizontal: 0),
                            height: 40,
                          ),
                          dropdownStyleData: DropdownStyleData(
                            maxHeight: 200,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.white,
                            ),
                          ),
                          menuItemStyleData: MenuItemStyleData(height: 40),
                          dropdownSearchData: DropdownSearchData(
                            searchController: paketler,
                            searchInnerWidgetHeight: 50,
                            searchInnerWidget: Container(
                              height: 50,
                              padding: EdgeInsets.all(8),
                              child: TextFormField(
                                controller: paketler,
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 8),
                                  hintText: 'Paket ara...',
                                  hintStyle: TextStyle(fontSize: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            searchMatchFn: (item, searchValue) {
                              return (item.value as Paket)
                                  .paket_adi
                                  .toLowerCase()
                                  .contains(searchValue.toLowerCase());
                            },
                          ),
                          onMenuStateChange: (isOpen) {
                            if (!isOpen) {
                              paketler.clear();
                            }
                          },
                        ),
                      ),
                    ),

                    SizedBox(height: 16),

                    // Seans Aralığı ve Fiyat Satırı
                    Row(
                      children: [
                        Expanded(
                          child: _buildInputCard(
                            icon: Icons.date_range_rounded,
                            title: 'Seans Aralığı (gün)',
                            child: TextField(
                              controller: pseans,
                              keyboardType: TextInputType.number,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade800,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Gün',
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildInputCard(
                            icon: Icons.currency_lira,
                            title: 'Fiyat (₺)',
                            child: TextField(
                              controller: pfiyat,
                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade800,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: '0,00',
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 16),

                    // Satıcı Seçimi
                    _buildInputCard(
                      icon: Icons.person_outline,
                      title: 'Satıcı',
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton2<Personel>(
                          isExpanded: true,
                          hint: Text(
                            'Satıcı seçin',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          items: paketsatici
                              .map((item) => DropdownMenuItem(
                                    value: item,
                                    child: Text(
                                      item.personel_adi,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade800,
                                      ),
                                    ),
                                  ))
                              .toList(),
                          value: selectedPaketSatici,
                          onChanged: (value) {
                            setState(() {
                              selectedPaketSatici = value;
                            });
                          },
                          buttonStyleData: ButtonStyleData(
                            padding: EdgeInsets.symmetric(horizontal: 0),
                            height: 40,
                          ),
                          dropdownStyleData: DropdownStyleData(
                            maxHeight: 200,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.white,
                            ),
                          ),
                          menuItemStyleData: MenuItemStyleData(height: 40),
                          dropdownSearchData: DropdownSearchData(
                            searchController: psatici,
                            searchInnerWidgetHeight: 50,
                            searchInnerWidget: Container(
                              height: 50,
                              padding: EdgeInsets.all(8),
                              child: TextFormField(
                                controller: psatici,
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 8),
                                  hintText: 'Satıcı ara...',
                                  hintStyle: TextStyle(fontSize: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            searchMatchFn: (item, searchValue) {
                              return (item.value as Personel)
                                  .personel_adi
                                  .toLowerCase()
                                  .contains(searchValue.toLowerCase());
                            },
                          ),
                          onMenuStateChange: (isOpen) {
                            if (!isOpen) {
                              psatici.clear();
                            }
                          },
                        ),
                      ),
                    ),

                    SizedBox(height: 32),

                    // Kaydet Butonu
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 16),
                      child: ElevatedButton(
                        onPressed: () async {
                          final AdisyonPaket paket = AdisyonPaket(
                            baslangic_tarihi: baslangictarihi.text,
                            seans_araligi: pseans.text,
                            id: widget.mevcutpaket.id,
                            adisyon_id: widget.mevcutpaket.adisyon_id,
                            paket_id: selectedPaket?.id ?? "",
                            fiyat: tlyirakamacevir(pfiyat.text).toString(),
                            personel_id: selectedPaketSatici?.id ?? "",
                            taksitli_tahsilat_id: "",
                            senet_id: "",
                            indirim_tutari: "",
                            hediye: "false",
                            paket: selectedPaket?.toJson() ?? "",
                            personel: selectedPaketSatici?.toJson() ?? "",
                            seans_baslangic_saati: randevusaati.text,
                          );
                          if (widget.senetlisatis) {
                            AdisyonPaket eklenepaket = await adisyonpaketekle(
                                paket,
                                widget.musteriid,
                                context,
                                seciliisletme!,
                                randevusaati.text,
                                true,
                                "");
                            Navigator.pop(context, eklenepaket);
                          } else
                            Navigator.pop(context, paket);
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'KAYDET',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple.shade700,
                          foregroundColor: Colors.white,
                          minimumSize: Size(double.infinity, 54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                          shadowColor: Colors.transparent,
                        ),
                      ),
                    ),

                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInputCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 16, top: 12, right: 16),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: Colors.grey.shade600,
                ),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: child,
          ),
        ],
      ),
    );
  }
}

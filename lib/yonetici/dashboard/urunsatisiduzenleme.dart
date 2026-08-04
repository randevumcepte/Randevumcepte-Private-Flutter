import 'dart:developer';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:randevu_sistem/Frontend/tlrakamacevir.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:randevu_sistem/Models/adisyonurunler.dart';
import 'package:randevu_sistem/Models/personel.dart';

import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Models/urunler.dart';
import 'package:randevu_sistem/yonetici/diger/menu/stok/barkod_tarayici.dart';


class UrunSatisiDuzenleme extends StatefulWidget {
  final String musteriid;
  final AdisyonUrun mevcuturun;
  final bool senetlisatis;
  final dynamic isletmebilgi;
  UrunSatisiDuzenleme({Key? key,required this.musteriid,required this.mevcuturun,required this.senetlisatis,required this.isletmebilgi}) : super(key: key);
  @override
  _HUrunSatisiState createState() => _HUrunSatisiState();
}
class _HUrunSatisiState extends State<UrunSatisiDuzenleme> {
  var tryformat = NumberFormat.currency(locale: 'tr_TR',symbol: "");
  bool isloading = true;
  late List<Personel> satici;
  late List<Urun> urun;
  Urun? selectedUrun;
  Personel? selectedSatici;
  String? seciliisletme;

  TextEditingController saticisec = TextEditingController();
  TextEditingController urunsec = TextEditingController();
  TextEditingController adet = TextEditingController();
  TextEditingController fiyat = TextEditingController();

  void initState() {
    super.initState();
    initialize();

  }
  Future<void> initialize() async{
    seciliisletme = (await secilisalonid())!;
    List <Personel> personelliste = await personellistegetir(seciliisletme!);
    List <Urun> urunliste = await urun_liste(seciliisletme!);
    setState(() {

      satici = personelliste;
      urun  = urunliste;
      adet.text = widget.mevcuturun.adet;
      fiyat.text = widget.mevcuturun.fiyat;
      selectedSatici = satici.firstWhere((element) => element.id.toString() == widget.mevcuturun.personel_id.toString());
      selectedUrun = urun.firstWhere((element) => element.id == widget.mevcuturun.urun_id);
      isloading = false;
    });
  }

  /// Barkod tara → eşleşen ürünü bul → mevcut ürünü değiştir (auto-submit YOK, edit modunda)
  Future<void> _barkodTarayipDegistir() async {
    final String? kod = await BarkodTarayici.tekSeferTara(context, baslik: 'Ürün Barkodu Tara');
    if (kod == null || kod.isEmpty) return;
    if (!mounted) return;

    final String aranan = kod.trim();
    Urun? eslesen;
    for (final u in urun) {
      if (u.barkod.trim() == aranan) {
        eslesen = u;
        break;
      }
    }

    if (eslesen == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"$aranan" barkoduna kayıtlı ürün bulunamadı.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    setState(() {
      selectedUrun = eslesen;
      adet.text = "1";
      double f = double.tryParse(eslesen!.fiyat ?? "0") ?? 0;
      fiyat.text = tryformat.format(f);
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Ürün Satışı Düzenleme',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        leading: IconButton(
          icon:
          Icon(Icons.arrow_back_ios_new_rounded, color: Colors.grey.shade700),
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
              // BARKOD TARA CTA
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.purple.shade600, Colors.purple.shade800],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withValues(alpha: 0.25),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _barkodTarayipDegistir,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 26),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'BARKOD TARA',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Farklı ürünle değiştir',
                                  style: TextStyle(fontSize: 12, color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 22),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // VEYA ayraç
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('veya manuel seç', style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
                ],
              ),

              const SizedBox(height: 16),

              // Ürün Seçimi
              _buildInputCard(
                icon: Icons.shopping_bag_outlined,
                title: 'Ürün',
                child: DropdownButtonHideUnderline(
                  child: DropdownButton2<Urun>(
                    isExpanded: true,
                    hint: Text(
                      'Ürün seçin',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    items: urun
                        .map((item) => DropdownMenuItem(
                      value: item,
                      child: Text(
                        item.urun_adi,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ))
                        .toList(),
                    value: selectedUrun,
                    onChanged: (value) {
                      setState(() {
                        selectedUrun = value;
                        log(selectedUrun?.fiyat ?? "");

                        fiyat.text = tryformat.format(double.parse(
                            (double.parse(adet.text) *
                                double.parse(
                                    selectedUrun?.fiyat ?? "0"))
                                .toString()));

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
                      searchController: urunsec,
                      searchInnerWidgetHeight: 50,
                      searchInnerWidget: Container(
                        height: 50,
                        padding: EdgeInsets.all(8),
                        child: TextFormField(
                          controller: urunsec,
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            hintText: 'Ürün ara...',
                            hintStyle: TextStyle(fontSize: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      searchMatchFn: (item, searchValue) {
                        return (item.value as Urun)
                            .urun_adi
                            .toLowerCase()
                            .contains(searchValue.toLowerCase());
                      },
                    ),
                    onMenuStateChange: (isOpen) {
                      if (!isOpen) {
                        urunsec.clear();
                      }
                    },
                  ),
                ),
              ),

              SizedBox(height: 16),

              // Adet ve Fiyat Satırı
              Row(
                children: [
                  Expanded(
                    child: _buildInputCard(
                      icon: Icons.format_list_numbered_outlined,
                      title: 'Adet',
                      child: TextFormField(
                        controller: adet,
                        keyboardType: TextInputType.phone,
                        enabled: true,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade800,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: '',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade500,
                          ),
                        ),
                        onSaved: (value) {
                          if (value == "")
                            adet.text = "0";
                          else
                            adet.text = value!;
                        },
                        onChanged: (value) {
                          fiyat.text = tryformat.format(double.parse(
                              (double.parse(adet.text) *
                                  double.parse(
                                      selectedUrun?.fiyat ?? "0"))
                                  .toString()));
                        },
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildInputCard(
                      icon: Icons.currency_lira,
                      title: 'Fiyat',
                      child: TextFormField(
                        controller: fiyat,
                        keyboardType: TextInputType.phone,
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
                        onSaved: (value) {
                          fiyat.text = tryformat.format(double.parse(value!));
                        },
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
                    items: satici
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
                    value: selectedSatici,
                    onChanged: (value) {
                      setState(() {
                        selectedSatici = value;
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
                      searchController: saticisec,
                      searchInnerWidgetHeight: 50,
                      searchInnerWidget: Container(
                        height: 50,
                        padding: EdgeInsets.all(8),
                        child: TextFormField(
                          controller: saticisec,
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
                        saticisec.clear();
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
                    final AdisyonUrun urun = AdisyonUrun(islem_tarihi: DateFormat("yyyy-MM-dd").format(DateTime.now()), id:widget.mevcuturun.id,adisyon_id: widget.mevcuturun.adisyon_id, urun_id: selectedUrun?.id ?? "", adet: adet.text, fiyat: tlyirakamacevir(fiyat.text).toString(), personel_id: selectedSatici?.id ?? "", taksitli_tahsilat_id: "", senet_id: "", indirim_tutari: "", hediye: "false", aciklama: "",urun: selectedUrun?.toJson() ?? "", personel: selectedSatici?.toJson() ?? "");
                    if(!widget.senetlisatis)
                    {
                      AdisyonUrun eklenenurun = await adisyonurunekle(urun,widget.musteriid ,context,seciliisletme!,true);
                      Navigator.pop(context, eklenenurun);
                    }
                    else
                      Navigator.pop(context, urun);
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
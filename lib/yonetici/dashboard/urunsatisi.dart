import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:randevu_sistem/Frontend/secilipersonel.dart';
import 'package:randevu_sistem/Frontend/tlrakamacevir.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:randevu_sistem/Models/adisyonurunler.dart';
import 'package:randevu_sistem/Models/personel.dart';

import '../../Backend/backend.dart';
import '../../Models/urunler.dart';

class UrunSatisi extends StatefulWidget {
  final String musteriid;
  final bool senetlisatis;
  final dynamic isletmebilgi;
  final String? mevcutadisyonId;
  final int kullanicirolu;
  UrunSatisi({
    Key? key,
    required this.musteriid,
    required this.senetlisatis,
    required this.isletmebilgi,
    this.mevcutadisyonId,
    required this.kullanicirolu,
  }) : super(key: key);

  @override
  _HUrunSatisiState createState() => _HUrunSatisiState();
}

class _HUrunSatisiState extends State<UrunSatisi> {
  var tryformat = NumberFormat.currency(locale: 'tr_TR', symbol: "");
  bool isloading = true;
  late List<Personel> satici;
  late List<Urun> urun;
  Urun? selectedUrun;
  Personel? selectedSatici;
  String? seciliisletme;

  TextEditingController saticisec = TextEditingController();
  TextEditingController urunsec = TextEditingController();
  TextEditingController adet = TextEditingController(text: "1");
  TextEditingController fiyat = TextEditingController(text: "0,00");

  @override
  void initState() {
    super.initState();
    initialize();
  }

  Future<void> initialize() async {
    seciliisletme = (await secilisalonid())!;
    List<Personel> personelliste = await personellistegetir(seciliisletme!);
    List<Urun> urunliste = await urun_liste(seciliisletme!);
    Personel seciliSatici = await seciliPersonelgetir(widget.isletmebilgi);
    setState(() {
      if(widget.kullanicirolu == 5)
        selectedSatici =seciliSatici;
      satici = personelliste;
      urun = urunliste;
      isloading = false;
    });
  }

  // Fiyat formatlama fonksiyonu
  String formatFiyat(String fiyatStr) {
    if (fiyatStr.isEmpty) return "0,00";

    // Noktayı virgüle çevir
    fiyatStr = fiyatStr.replaceAll('.', ',');

    // Sayısal değeri kontrol et
    double? fiyatDouble = double.tryParse(fiyatStr.replaceAll(',', '.'));
    if (fiyatDouble == null) return "0,00";

    // İki ondalık basamakla formatla
    return NumberFormat("#,##0.00", "tr_TR").format(fiyatDouble);
  }

  // Adet formatlama fonksiyonu
  String formatAdet(String adetStr) {
    if (adetStr.isEmpty) return "1";

    int? adetInt = int.tryParse(adetStr);
    if (adetInt == null || adetInt < 1) return "1";

    return adetInt.toString();
  }

  // Toplam fiyat hesaplama fonksiyonu
  void hesaplaToplamFiyat() {
    if (selectedUrun != null && adet.text.isNotEmpty) {
      double urunFiyati = double.tryParse(selectedUrun!.fiyat ?? "0") ?? 0;
      int adetSayisi = int.tryParse(adet.text) ?? 1;
      double toplam = urunFiyati * adetSayisi;

      setState(() {
        fiyat.text = formatFiyat(toplam.toString());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Ürün Satışı',
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
          :   GestureDetector(
    onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
    child:  SingleChildScrollView(
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
                      Icons.shopping_bag_outlined,
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
                          'Ürün Satışı',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        Text(
                          'Müşteriye yeni ürün ekleyin',
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
                    if (value != null) {
                      setState(() {
                        selectedUrun = value;
                        // Ürün fiyatını göster
                        double urunFiyati =
                            double.tryParse(value.fiyat ?? "0") ?? 0;
                        fiyat.text = formatFiyat(urunFiyati.toString());
                        // Adet'i 1 olarak ayarla
                        adet.text = "1";
                      });
                    }
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
                      keyboardType: TextInputType.number,
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
                      onChanged: (value) {
                        // Tüm metni temizle ve sadece sayıları al
                        String cleanedValue = value.replaceAll(RegExp(r'[^0-9]'), '');

                        if (cleanedValue.isEmpty) {
                          setState(() {
                            adet.text = "";
                          });
                        } else {
                          setState(() {
                            adet.text = cleanedValue;
                            // Kursorü en sona taşı
                            adet.selection = TextSelection.collapsed(offset: cleanedValue.length);
                          });
                        }

                        // Fiyatı hesapla
                        if (cleanedValue.isNotEmpty) {
                          hesaplaToplamFiyat();
                        }
                      },
                    ),
                  ),
                ),
                SizedBox(width: 12),
                // Fiyat alanını değiştirin
                Expanded(
                  child: _buildInputCard(
                    icon: Icons.currency_lira,
                    title: 'Toplam Fiyat',
                    child: TextFormField(
                      controller: fiyat,
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
                      onChanged: (value) {
                        // Önceki karakteri sakla
                        if (value.isNotEmpty) {
                          // Virgülü noktaya çevir ve sayısal kontrol yap
                          String cleanedValue = value.replaceAll(',', '.');

                          // Son karakteri kontrol et
                          String lastChar = value.substring(value.length - 1);

                          // Eğer son karakter sayı değilse ve virgül/nokta değilse, kaldır
                          if (!RegExp(r'[0-9.,]').hasMatch(lastChar)) {
                            // Geçersiz karakteri kaldır
                            value = value.substring(0, value.length - 1);
                            fiyat.text = value;
                            fiyat.selection = TextSelection.collapsed(offset: value.length);
                            return;
                          }

                          // Birden fazla ondalık ayracı kontrol et
                          int decimalCount = value.replaceAll(RegExp(r'[^.,]'), '').length;
                          if (decimalCount > 1) {
                            // Fazla ondalık ayraçları kaldır
                            value = value.substring(0, value.length - 1);
                            fiyat.text = value;
                            fiyat.selection = TextSelection.collapsed(offset: value.length);
                            return;
                          }

                          setState(() {
                            fiyat.text = value;
                            // Kürsörü en sona taşı
                            fiyat.selection = TextSelection.collapsed(offset: value.length);
                          });

                          // Adeti güncelle (eğer ürün fiyatı biliniyorsa)
                          if (selectedUrun != null) {
                            double? urunBirimFiyati = double.tryParse(selectedUrun!.fiyat ?? "0");
                            if (urunBirimFiyati != null && urunBirimFiyati > 0) {
                              double? toplamFiyat = double.tryParse(value.replaceAll(',', '.'));
                              if (toplamFiyat != null && toplamFiyat > 0) {
                                int yeniAdet = (toplamFiyat / urunBirimFiyati).round();
                                if (yeniAdet > 0) {
                                  adet.text = yeniAdet.toString();
                                }
                              }
                            }
                          }
                        }
                      },
                      onTap: () {
                        // Tıkladığında tüm metni seç
                        Future.delayed(Duration.zero, () {
                          fiyat.selection = TextSelection(
                            baseOffset: 0,
                            extentOffset: fiyat.text.length,
                          );
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),

            // Ürün Bilgisi (seçildiğinde göster)


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
                  // Kontroller
                  if (selectedUrun == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Lütfen bir ürün seçin'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  if (selectedSatici == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Lütfen bir satıcı seçin'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  // Stok kontrolü
                  int? stokMiktari = int.tryParse(selectedUrun!.stok_adedi ?? "0");
                  int adetMiktari = int.tryParse(adet.text) ?? 1;
                  if (stokMiktari != null && adetMiktari > stokMiktari) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Yetersiz stok! Mevcut stok: $stokMiktari, İstenen: $adetMiktari'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  // Fiyat null kontrolü
                  String fiyatDegeri = fiyat.text.replaceAll(',', '.');
                  double? fiyatDouble = double.tryParse(fiyatDegeri) ?? 0;

                  final AdisyonUrun urun = AdisyonUrun(
                    islem_tarihi:
                    DateFormat("yyyy-MM-dd").format(DateTime.now()),
                    id: "",
                    adisyon_id: widget.mevcutadisyonId ?? "",
                    urun_id: selectedUrun!.id ?? "",
                    adet: adet.text,
                    fiyat: tlyirakamacevir(fiyat.text).toString(),
                    personel_id: selectedSatici!.id,
                    taksitli_tahsilat_id: "",
                    senet_id: "",
                    indirim_tutari: "",
                    hediye: "false",
                    aciklama: "",
                    urun: selectedUrun!.toJson(),
                    personel: selectedSatici!.toJson(),
                  );

                  if (!widget.senetlisatis) {
                    AdisyonUrun eklenenurun = await adisyonurunekle(
                      urun,
                      widget.musteriid,
                      context,
                      seciliisletme!,
                      true,
                    );
                    Navigator.pop(context, eklenenurun);
                  } else {
                    Navigator.pop(context, urun);
                  }
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
    ));
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
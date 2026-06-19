import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:randevu_sistem/Frontend/secilipersonel.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';

import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Frontend/tlrakamacevir.dart';
import 'package:randevu_sistem/Models/adisyonpaketler.dart';
import 'package:randevu_sistem/Models/paketler.dart';
import 'package:randevu_sistem/Models/personel.dart';

class PaketSatisi extends StatefulWidget {
  final String musteriid;
  final bool senetlisatis;
  final dynamic isletmebilgi;
  final String? mevcutadisyonId;
  final int kullanicirolu;

  PaketSatisi({
    Key? key,
    required this.musteriid,
    required this.senetlisatis,
    required this.isletmebilgi,
    this.mevcutadisyonId,
    required this.kullanicirolu,
  }) : super(key: key);

  @override
  _PaketSatisiState createState() => _PaketSatisiState();
}

class _PaketSatisiState extends State<PaketSatisi> {
  var tryformat = NumberFormat.currency(locale: 'tr_TR', symbol: "");
  late List<Personel> paketsatici;
  bool isloading = true;
  String? seciliisletme;
  late List<Paket> paket;
  Paket? selectedPaket;
  TextEditingController paketler = TextEditingController();
  Personel? selectedPaketSatici;
  TextEditingController psatici = TextEditingController();

  // Otomatik olarak bugünün tarihi ile başlat
  TextEditingController baslangictarihi = TextEditingController(
    text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
  );

  TextEditingController pfiyat = TextEditingController(text: "0,00");
  TextEditingController pseans = TextEditingController(); // Boş bırak

  // Saat controller'ı - şimdi modern saat seçici için değişti
  TextEditingController randevusaati = TextEditingController();

  // Saat seçimi için değişken
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    initialize();
  }

  Future<void> initialize() async {
    seciliisletme = (await secilisalonid())!;
    List<Personel> personelliste = await personellistegetir(seciliisletme!);
    List<Paket> paketliste = await paket_liste(seciliisletme!);
    selectedPaketSatici = await seciliPersonelgetir(widget.isletmebilgi);
    // Şu anki saati başlangıç olarak ayarla
    setState(() {
      // paketsatici'yi id'ye gore tekille (ayni id 2+ -> DropdownButton2 assertion'i onler)
      final gorulenPersId = <String>{};
      paketsatici = [
        for (final p in personelliste) if (gorulenPersId.add(p.id)) p
      ];
      paket = paketliste;
      isloading = false;
      // selectedPaketSatici, items (paketsatici) icindeki GERCEK instance olmali.
      // Personel'de == override yok -> DropdownButton2 identity ile eslestiriyor;
      // seciliPersonelgetir farkli instance dondurdugu icin id ile eslestir, yoksa null.
      if (selectedPaketSatici != null) {
        final esl = paketsatici.where((p) => p.id == selectedPaketSatici!.id).toList();
        selectedPaketSatici = esl.isNotEmpty ? esl.first : null;
      }

      // Başlangıç saati ayarla
      DateTime now = DateTime.now();
      _selectedTime = TimeOfDay(hour: now.hour, minute: now.minute);
      randevusaati.text = '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';
    });
  }

  // MODERN SAAT SEÇİCİ FONKSİYONLARI
  Future<void> _showModernTimePicker(BuildContext context) async {
    TimeOfDay initialTime = _selectedTime;
    bool valid = false;

    while (!valid) {
      final result = await showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) => _buildModernTimePicker(initialTime),
      );

      if (result == null) return;

      if (result is TimeOfDay) {
        setState(() {
          _selectedTime = result;
          randevusaati.text = '${result.hour.toString().padLeft(2, '0')}:${result.minute.toString().padLeft(2, '0')}';
        });
        valid = true;
      }
    }
  }

  Widget _buildModernTimePicker(TimeOfDay initialTime) {
    int selectedHour = initialTime.hour;
    int selectedMinute = _getNearestQuarterMinute(initialTime.minute);

    return StatefulBuilder(
      builder: (context, setState) {
        return GestureDetector(
          onTap: () {},
          child: Container(
            height: MediaQuery.of(context).size.height * 0.6,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                // Başlık ve butonlar
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[200]!),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'İptal',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        'Saat Seç',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          final selectedTime = TimeOfDay(hour: selectedHour, minute: selectedMinute);
                          Navigator.of(context).pop(selectedTime);
                        },
                        child: Text(
                          'Tamam',
                          style: TextStyle(
                            color: Color(0xFF6A1B9A),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Büyük saat gösterimi
                Container(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    '${selectedHour.toString().padLeft(2, '0')}:${selectedMinute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w300,
                      color: Color(0xFF6A1B9A),
                    ),
                  ),
                ),

                // Saat ve dakika seçiciler
                Expanded(
                  child: Row(
                    children: [
                      // Saat seçici
                      Expanded(
                        child: ListWheelScrollView(
                          itemExtent: 50,
                          perspective: 0.005,
                          diameterRatio: 1.5,
                          physics: FixedExtentScrollPhysics(),
                          onSelectedItemChanged: (index) {
                            setState(() {
                              selectedHour = index;
                            });
                          },
                          children: List.generate(24, (hour) {
                            final isSelected = hour == selectedHour;
                            return Container(
                              alignment: Alignment.center,
                              child: Text(
                                hour.toString().padLeft(2, '0'),
                                style: TextStyle(
                                  fontSize: isSelected ? 22 : 18,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                  color: isSelected ? Color(0xFF6A1B9A) : Colors.grey[600],
                                ),
                              ),
                            );
                          }),
                        ),
                      ),

                      // Dakika seçici - SADECE 00-15-30-45
                      Expanded(
                        child: ListWheelScrollView(
                          itemExtent: 50,
                          perspective: 0.005,
                          diameterRatio: 1.5,
                          physics: FixedExtentScrollPhysics(),
                          onSelectedItemChanged: (index) {
                            setState(() {
                              selectedMinute = _getMinuteFromIndex(index);
                            });
                          },
                          children: List.generate(4, (index) {
                            final minute = _getMinuteFromIndex(index);
                            final isSelected = minute == selectedMinute;
                            return Container(
                              alignment: Alignment.center,
                              child: Text(
                                minute.toString().padLeft(2, '0'),
                                style: TextStyle(
                                  fontSize: isSelected ? 22 : 18,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                  color: isSelected ? Color(0xFF6A1B9A) : Colors.grey[600],
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Dakika indeksini gerçek dakika değerine dönüştürme
  int _getMinuteFromIndex(int index) {
    switch (index) {
      case 0: return 0;   // 00
      case 1: return 15;  // 15
      case 2: return 30;  // 30
      case 3: return 45;  // 45
      default: return 0;
    }
  }

  // Mevcut dakikayı en yakın çeyrek saate yuvarlama
  int _getNearestQuarterMinute(int minute) {
    if (minute < 8) return 0;
    if (minute < 23) return 15;
    if (minute < 38) return 30;
    if (minute < 53) return 45;
    return 0; // 53-59 arası için 00 (saat artar)
  }

  // Fiyat formatlama fonksiyonu
  String formatFiyat(String fiyatStr) {
    if (fiyatStr.isEmpty) return "0,00";

    fiyatStr = fiyatStr.replaceAll('.', ',');
    double? fiyatDouble = double.tryParse(fiyatStr.replaceAll(',', '.'));
    if (fiyatDouble == null) return "0,00";

    return NumberFormat("#,##0.00", "tr_TR").format(fiyatDouble);
  }

  // Seans formatlama fonksiyonu
  String formatSeans(String seansStr) {
    if (seansStr.isEmpty) return ""; // Boş bırak

    // Sadece sayısal karakterleri al
    String numericValue = seansStr.replaceAll(RegExp(r'[^0-9]'), '');
    if (numericValue.isEmpty) return "";

    int? seansInt = int.tryParse(numericValue);
    if (seansInt == null || seansInt < 1) return "";

    return seansInt.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Paket Satışı',
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
                      Icons.inventory_2_outlined,
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
                          'Paket Satışı',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        Text(
                          'Müşteriye yeni paket ekleyin',
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
                    if (value != null) {
                      setState(() {
                        selectedPaket = value;
                        // Fiyat + seans sayisi paket hizmetlerinden hesaplanir;
                        // hizmet verisi yoksa paketin KENDI belirlenen degerine duser.
                        double toplamFiyat = 0;
                        double toplamSeans = 0;
                        value.hizmetler.forEach((element) {
                          toplamFiyat +=
                              double.tryParse(element["fiyat"]?.toString() ?? "0") ?? 0;
                          toplamSeans +=
                              double.tryParse(element["seans"]?.toString() ?? "0") ?? 0;
                        });
                        if (toplamFiyat <= 0) {
                          toplamFiyat =
                              double.tryParse(value.fiyat.replaceAll(',', '.')) ?? 0;
                        }
                        pfiyat.text = formatFiyat(toplamFiyat.toString());
                        // Varsayilan seans sayisi (duzenlenebilir): hizmet seans toplami,
                        // yoksa paketin miktari.
                        final int seansVarsayilan = toplamSeans > 0
                            ? toplamSeans.round()
                            : (int.tryParse(value.miktar) ?? 0);
                        pseans.text = seansVarsayilan > 0 ? seansVarsayilan.toString() : '';
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

            // Seans Sayısı ve Fiyat Satırı
            Row(
              children: [
                Expanded(
                  child: _buildInputCard(
                    icon: Icons.format_list_numbered_rounded,
                    title: 'Seans Sayısı',
                    child: TextFormField(
                      controller: pseans,
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade800,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Adet',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 13,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          // Sadece sayısal karakterleri kabul et
                          if (value.isNotEmpty) {
                            String numericValue = value.replaceAll(RegExp(r'[^0-9]'), '');
                            if (numericValue.isNotEmpty) {
                              int? parsed = int.tryParse(numericValue);
                              if (parsed != null) {
                                pseans.text = parsed.toString();
                                pseans.selection = TextSelection.fromPosition(
                                  TextPosition(offset: pseans.text.length),
                                );
                              }
                            } else {
                              pseans.text = '';
                            }
                          }
                        });
                      },
                    ),
                  ),
                ),
                SizedBox(width: 12),
                // Fiyat alanını değiştirin (şu anda 211. satırda)
                Expanded(
                  child: _buildInputCard(
                    icon: Icons.currency_lira,
                    title: 'Fiyat (₺)',
                    child: TextFormField(
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
                            pfiyat.text = value;
                            pfiyat.selection = TextSelection.collapsed(offset: value.length);
                            return;
                          }

                          // Birden fazla ondalık ayracı kontrol et
                          int decimalCount = value.replaceAll(RegExp(r'[^.,]'), '').length;
                          if (decimalCount > 1) {
                            // Fazla ondalık ayraçları kaldır
                            value = value.substring(0, value.length - 1);
                            pfiyat.text = value;
                            pfiyat.selection = TextSelection.collapsed(offset: value.length);
                            return;
                          }

                          setState(() {
                            pfiyat.text = value;
                            // Kürsörü en sona taşı
                            pfiyat.selection = TextSelection.collapsed(offset: value.length);
                          });
                        }
                      },
                      onTap: () {
                        // Tıkladığında tüm metni seç
                        Future.delayed(Duration.zero, () {
                          pfiyat.selection = TextSelection(
                            baseOffset: 0,
                            extentOffset: pfiyat.text.length,
                          );
                        });
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
                  // Kontroller
                  if (selectedPaket == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Lütfen bir paket seçin'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  if (selectedPaketSatici == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Lütfen bir satıcı seçin'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  // pseans artik SEANS SAYISI (adet). Seans araligi (gun) UI'dan
                  // kaldirildi -> backend'e varsayilan 30 gun ile gonderilir.
                  final String seansSayisi = pseans.text.trim();
                  const String seansAraligiGun = '30';

                  // Fiyat null kontrolü
                  String fiyatDegeri = pfiyat.text.replaceAll(',', '.');
                  double? fiyatDouble = double.tryParse(fiyatDegeri) ?? 0;

                  final AdisyonPaket paket = AdisyonPaket(
                    baslangic_tarihi: baslangictarihi.text,
                    seans_araligi: seansAraligiGun,
                    id: "",
                    adisyon_id: widget.mevcutadisyonId ?? "",
                    paket_id: selectedPaket!.id ?? "",
                    fiyat: tlyirakamacevir(pfiyat.text).toString(),
                    personel_id: selectedPaketSatici!.id,
                    taksitli_tahsilat_id: "",
                    senet_id: "",
                    indirim_tutari: "",
                    hediye: "false",
                    paket: selectedPaket!.toJson(),
                    personel: selectedPaketSatici!.toJson(),
                    seans_baslangic_saati: randevusaati.text,
                  );

                  if (!widget.senetlisatis) {
                    AdisyonPaket eklenepaket = await adisyonpaketekle(
                      paket,
                      widget.musteriid,
                      context,
                      seciliisletme!,
                      randevusaati.text,
                      true,
                      "",
                      seansSayisi: seansSayisi,
                    );
                    Navigator.pop(context, eklenepaket);
                  } else {
                    Navigator.pop(context, paket);
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
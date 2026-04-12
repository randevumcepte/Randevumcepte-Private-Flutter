import 'dart:convert';
import 'dart:developer';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:randevu_sistem/Frontend/secilipersonel.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:randevu_sistem/Models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Backend/backend.dart';
import '../../Models/adisyonhizmetler.dart';
import '../../Models/isletmehizmetleri.dart';
import '../../Models/personel.dart';

class HizmetSatisi extends StatefulWidget {
  final String musteriid;
  final bool senetlisatis;
  final dynamic isletmebilgi;
  final String? mevcutadisyonId;
  final int kullanicirolu;

  HizmetSatisi({
    Key? key,
    required this.musteriid,
    required this.senetlisatis,
    required this.isletmebilgi,
    this.mevcutadisyonId,
    required this.kullanicirolu,
  }) : super(key: key);

  @override
  _HizmetSatisiState createState() => _HizmetSatisiState();
}

class _HizmetSatisiState extends State<HizmetSatisi> {
  bool isloading = true;
  late List<Personel> personel;
  late List<IsletmeHizmet> hizmet;

  Personel? selectedpersonel;
  String? seciliisletme;
  TextEditingController secilipersonel = TextEditingController();
  IsletmeHizmet? selectedhizmet;
  TextEditingController secilihizmet = TextEditingController();

  // Otomatik olarak bugünün tarihi ile başlat
  TextEditingController islem_tarihi = TextEditingController(
    text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
  );

  // Saat controller'ı - boş başlat
  TextEditingController islem_saati = TextEditingController();

  // Saat seçimi için değişken
  TimeOfDay _selectedTime = TimeOfDay.now();

  // Fiyat controller - sadece "0,00" ile başlat
  TextEditingController fiyat = TextEditingController(text: "0,00");

  // Hizmetin orijinal fiyatını saklamak için
  String? _orjinalHizmetFiyati;

  // Kullanıcı fiyatı manuel değiştirdi mi?
  bool _fiyatManuelDegistirildi = false;

  TextEditingController sure_dk = TextEditingController(text: "0");

  // Süre için de aynı mantık
  bool _sureManuelDegistirildi = false;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  Future<void> initialize() async {
    seciliisletme = (await secilisalonid())!;
    List<Personel> personelliste = await personellistegetir(seciliisletme!);
    List<IsletmeHizmet> hizmetliste = await isletmehizmetleri(seciliisletme!);
    Personel seciliPersonel  = await seciliPersonelgetir(widget.isletmebilgi);

    // Şu anki saati başlangıç olarak ayarla
    setState(()  {
      personel = personelliste;
      hizmet = hizmetliste;
      isloading = false;
      if(widget.kullanicirolu==5)
       selectedpersonel = seciliPersonel;

      // Başlangıç saati ayarla
      DateTime now = DateTime.now();
      _selectedTime = TimeOfDay(hour: now.hour, minute: now.minute);
      islem_saati.text = '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';
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
          islem_saati.text = '${result.hour.toString().padLeft(2, '0')}:${result.minute.toString().padLeft(2, '0')}';
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

    // Noktayı virgüle çevir
    fiyatStr = fiyatStr.replaceAll('.', ',');

    // Sayısal değeri kontrol et
    double? fiyatDouble = double.tryParse(fiyatStr.replaceAll(',', '.'));
    if (fiyatDouble == null) return "0,00";

    // İki ondalık basamakla formatla
    return NumberFormat("#,##0.00", "tr_TR").format(fiyatDouble);
  }

  // Süre formatlama fonksiyonu
  String formatSure(String sureStr) {
    if (sureStr.isEmpty) return "0";

    int? sureInt = int.tryParse(sureStr);
    if (sureInt == null) return "0";

    return sureInt.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Hizmet Satışı',
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
                        Icons.spa_outlined,
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
                            'Hizmet Satışı',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          Text(
                            'Müşteriye yeni hizmet ekleyin',
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

              // Tarih ve Saat Satırı
              /*Row(
              children: [
                Expanded(
                  child: _buildInputCard(
                    icon: Icons.calendar_today_outlined,
                    title: 'Tarih',
                    child: TextFormField(
                      controller: islem_tarihi,
                      readOnly: true,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade800,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Tarih seç',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade500,
                        ),
                      ),
                      onTap: () async {
                        final DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                          builder: (context, child) {
                            return Theme(
                              data: ThemeData.light().copyWith(
                                colorScheme: ColorScheme.light(
                                  primary: Colors.purple.shade700,
                                  onPrimary: Colors.white,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (pickedDate != null) {
                          setState(() {
                            islem_tarihi.text =
                                DateFormat('yyyy-MM-dd').format(pickedDate);
                          });
                        }
                      },
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildInputCard(
                    icon: Icons.access_time_outlined,
                    title: 'Saat',
                    child: TextFormField(
                      controller: islem_saati,
                      readOnly: true,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade800,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Saat seç',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                        ),
                        suffixIcon: Icon(
                          Icons.access_time,
                          color: Colors.purple.shade700,
                          size: 20,
                        ),
                      ),
                      onTap: () async {
                        await _showModernTimePicker(context);
                      },
                    ),
                  ),
                ),
              ],
            ),*/

              //SizedBox(height: 16),
              //SizedBox(height: 16),

              // Personel Seçimi
              _buildInputCard(
                icon: Icons.person_outline,
                title: 'Personel',
                child: DropdownButtonHideUnderline(
                  child: DropdownButton2<Personel>(
                    isExpanded: true,
                    hint: Text(
                      'Personel seçin',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    items: personel
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
                    value: selectedpersonel,
                    onChanged: (value) {
                      setState(() {
                        selectedpersonel = value;
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
                      searchController: secilipersonel,
                      searchInnerWidgetHeight: 50,
                      searchInnerWidget: Container(
                        height: 50,
                        padding: EdgeInsets.all(8),
                        child: TextFormField(
                          controller: secilipersonel,
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            hintText: 'Personel ara...',
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
                        secilipersonel.clear();
                      }
                    },
                  ),
                ),
              ),

              SizedBox(height: 16),

              // Hizmet Seçimi
              _buildInputCard(
                icon: Icons.spa_outlined,
                title: 'Hizmet',
                child: DropdownButtonHideUnderline(
                  child: DropdownButton2<IsletmeHizmet>(
                    isExpanded: true,
                    hint: Text(
                      'Hizmet seçin',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    items: hizmet
                        .map((item) => DropdownMenuItem(
                      value: item,
                      child: Text(
                        item.hizmet["hizmet_adi"] ?? "",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ))
                        .toList(),
                    value: selectedhizmet,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedhizmet = value;

                          // Orjinal fiyat ve süreyi sakla
                          _orjinalHizmetFiyati = value.fiyat ?? "0";
                          String hizmetSuresi = value.sure ?? "0";

                          // Eğer kullanıcı manuel değiştirmediyse, hizmet değerlerini kullan
                          if (!_fiyatManuelDegistirildi) {
                            fiyat.text = formatFiyat(_orjinalHizmetFiyati!);
                          }

                          if (!_sureManuelDegistirildi) {
                            sure_dk.text = formatSure(hizmetSuresi);
                          }
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
                      searchController: secilihizmet,
                      searchInnerWidgetHeight: 50,
                      searchInnerWidget: Container(
                        height: 50,
                        padding: EdgeInsets.all(8),
                        child: TextFormField(
                          controller: secilihizmet,
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            hintText: 'Hizmet ara...',
                            hintStyle: TextStyle(fontSize: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      searchMatchFn: (item, searchValue) {
                        return (item.value as IsletmeHizmet)
                            .hizmet["hizmet_adi"]
                            .toLowerCase()
                            .contains(searchValue.toLowerCase());
                      },
                    ),
                    onMenuStateChange: (isOpen) {
                      if (!isOpen) {
                        secilihizmet.clear();
                      }
                    },
                  ),
                ),
              ),

              SizedBox(height: 16),

              // Süre ve Fiyat Satırı
              Row(
                children: [
                  Expanded(
                    child: _buildInputCard(
                      icon: Icons.timer_outlined,
                      title: 'Süre (dk)',
                      child: TextFormField(
                        controller: sure_dk,
                        keyboardType: TextInputType.number,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade800,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: '0',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade500,
                          ),
                          suffixIcon: _sureManuelDegistirildi
                              ? IconButton(
                            icon: Icon(Icons.restore, size: 18),
                            color: Colors.orange.shade700,
                            onPressed: () {
                              if (selectedhizmet != null && !_sureManuelDegistirildi) {
                                return;
                              }

                              setState(() {
                                _sureManuelDegistirildi = false;
                                if (selectedhizmet != null) {
                                  String hizmetSuresi = selectedhizmet!.sure ?? "0";
                                  sure_dk.text = formatSure(hizmetSuresi);
                                }
                              });
                            },
                          )
                              : null,
                        ),
                        onTap: () {
                          // Fokus alındığında, kullanıcının manuel değiştireceğini varsay
                          setState(() {
                            _sureManuelDegistirildi = true;
                          });
                        },
                        onChanged: (value) {
                          setState(() {
                            _sureManuelDegistirildi = true;
                            if (value.isEmpty) {
                              sure_dk.text = "0";
                            } else {
                              sure_dk.text = formatSure(value);
                            }
                          });
                        },
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  // Fiyat alanı widget'ını değiştirin:
                  Expanded(
                    child: _buildInputCard(
                      icon: Icons.currency_lira,
                      title: 'Fiyat (₺)',
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

                            // Geçici olarak formatlamayı kaldır, kullanıcı yazarken rahat etsin
                            // Sadece temizleme işlemleri yap

                            setState(() {
                              fiyat.text = value;
                              // Kürsörü en sona taşı
                              fiyat.selection = TextSelection.collapsed(offset: value.length);
                            });
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

              SizedBox(height: 8),

              // Bilgi mesajı
              if (_fiyatManuelDegistirildi || _sureManuelDegistirildi)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 14, color: Colors.orange.shade700),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Hizmet değerleri manuel olarak değiştirildi',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              SizedBox(height: 32),

              // Kaydet Butonu
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16),
                child: ElevatedButton(
                  onPressed: () async {
                    // Kontroller
                    if (selectedhizmet == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Lütfen bir hizmet seçin'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    if (selectedpersonel == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Lütfen bir personel seçin'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    // Fiyat ve süre null kontrolü
                    String fiyatDegeri = fiyat.text.replaceAll(',', '.');
                    double? fiyatDouble = double.tryParse(fiyatDegeri) ?? 0;

                    String sureDegeri = sure_dk.text;
                    int? sureInt = int.tryParse(sureDegeri) ?? 0;

                    final AdisyonHizmet adisyonhizmet = AdisyonHizmet(
                      id: "",
                      adisyon_id: widget.mevcutadisyonId ?? "",
                      hizmet_id: selectedhizmet!.hizmet_id,
                      islem_tarihi: islem_tarihi.text,
                      islem_saati: islem_saati.text,
                      sure: sureInt.toString(),
                      fiyat: fiyatDouble.toStringAsFixed(2).replaceAll('.', ','),
                      geldi: "1",
                      personel_id: selectedpersonel!.id,
                      cihaz_id: "",
                      oda_id: "",
                      dogrulama_kodu: "",
                      taksitli_tahsilat_id: "",
                      senet_id: "",
                      indirim_tutari: "",
                      hediye: "",
                      hizmet: selectedhizmet!.hizmet,
                      personel: selectedpersonel!,
                    );

                    if (!widget.senetlisatis) {
                      AdisyonHizmet eklenenhizmet = await adisyonhizmetekle(
                        adisyonhizmet,
                        widget.musteriid,
                        context,
                        seciliisletme!,
                      );
                      Navigator.pop(context, eklenenhizmet);
                    } else {
                      Navigator.pop(context, adisyonhizmet);
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

      )

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
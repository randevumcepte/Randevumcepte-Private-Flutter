import 'dart:convert';
import 'dart:developer';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:randevu_sistem/Frontend/sfdatatable.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:randevu_sistem/Models/musteri_danisanlar.dart';
import 'package:randevu_sistem/Models/ongorusmenedeni.dart';
import 'package:http/http.dart' as http;

import '../../../../../Backend/backend.dart';
import '../../../../../Models/musteridanisanreferans.dart';
import '../../../../../Models/ongorusmeler.dart';
import '../../../../../Models/personel.dart';
import '../../../../../Models/sehirler.dart';
import '../../../../Frontend/lazyload.dart';

class OnGorusmeDuzenle extends StatefulWidget {
  final OnGorusmeDataSource ongorusmedatasource;
  final OnGorusme ongorusme;
  final dynamic isletmebilgi;
  const OnGorusmeDuzenle({Key? key,required this.ongorusmedatasource, required this.ongorusme,required this.isletmebilgi}) : super(key: key);

  @override
  _OnGorusmeDuzenleState createState() => _OnGorusmeDuzenleState();
}

class _OnGorusmeDuzenleState extends State<OnGorusmeDuzenle> {
  TimeOfDay _selectedTime = TimeOfDay.now();

  late List<MusteriDanisan> musteri;
  MusteriDanisan? selectedMusteri;
  final TextEditingController ongorusmemustericontroller = TextEditingController();
  late List<Sehir> ongorusmesehir;
  Sehir? selectedongorusmesehir;
  final TextEditingController ongorusmesehircontroller = TextEditingController();
  final List<Referans> ongorusmereferans = [
    Referans(id: "", referans: "Yok"),
    Referans(id: "1", referans: "İnternet"),
    Referans(id: "2", referans: "Reklam"),
    Referans(id: "3", referans: "Instagram"),
    Referans(id: "4", referans: "Facebook"),
    Referans(id: "5", referans: "Tanıdık")
  ];

  Referans? selectedongorusmereferans;
  final TextEditingController ongorusmereferanscontroller = TextEditingController();

  OnGorusmeNedeni? selectedongorusmesebep;
  late String seciliisletme;

  final TextEditingController ongorusmesebepcontroller = TextEditingController();
  final TextEditingController adsoyad = TextEditingController();
  final TextEditingController telefon = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController meslek = TextEditingController();
  final TextEditingController ongorusmetarihi = TextEditingController();
  final TextEditingController ongorusmesaati = TextEditingController();
  final TextEditingController ongorusmeaciklama = TextEditingController();

  late List<Personel> ongorusmeyapan;
  late List<OnGorusmeNedeni> ongorusmeneden;
  Personel? selectedongorusmeyapan;
  final TextEditingController ongorusmeyapancontroller = TextEditingController();
  bool yukleniyor = true;
  TextEditingController ongrusmetarih = TextEditingController();

  String _selectedGender = '';

  @override
  void initState() {
    super.initState();
    initialize();
  }

  Future<void> initialize() async {
    try {
      seciliisletme = (await secilisalonid())!;
      final isletmeVerileri = await isletmeVerileriGetir(seciliisletme, false, '', '', '', 0, 0);

      List<MusteriDanisan> musteridanisan = isletmeVerileri['musteriler'] ?? [];
      List<Personel> isletmepersonellerliste = isletmeVerileri['personeller'] ?? [];
      List<OnGorusmeNedeni> ongorusmenedeniliste = isletmeVerileri['onGorusmeNedeni'] ?? [];
      List<Sehir> sehirler = isletmeVerileri['sehirler'] ?? [];

      setState(() {
        musteri = musteridanisan;
        ongorusmeyapan = isletmepersonellerliste;
        ongorusmesehir = sehirler;
        ongorusmeneden = ongorusmenedeniliste;

        // Müşteri seçimi
        if (widget.ongorusme.musteri != null && widget.ongorusme.musteri["id"] != null) {
          try {
            selectedMusteri = musteridanisan.firstWhere(
                    (element) => element.id.toString() == widget.ongorusme.musteri["id"].toString()
            );
          } catch (e) {
            log('Müşteri bulunamadı: $e');
            selectedMusteri = null;
          }
        }

        // Referans seçimi
        try {
          selectedongorusmereferans = ongorusmereferans.firstWhere(
                  (item) => item.id == (widget.ongorusme.musteri_tipi ?? "")
          );
        } catch (e) {
          selectedongorusmereferans = ongorusmereferans.firstWhere((item) => item.id == "");
        }

        // Form alanlarını doldur
        adsoyad.text = widget.ongorusme.ad_soyad != 'null' ? widget.ongorusme.ad_soyad : '';
        telefon.text = widget.ongorusme.cep_telefon != 'null' ? widget.ongorusme.cep_telefon : '';
        email.text = widget.ongorusme.email != 'null' ? widget.ongorusme.email : '';
        meslek.text = widget.ongorusme.meslek != 'null' ? widget.ongorusme.meslek : '';
        ongorusmetarihi.text = widget.ongorusme.tarih!= 'null' ? widget.ongorusme.tarih : '';
        ongorusmesaati.text = widget.ongorusme.saat != 'null' ? widget.ongorusme.saat : '';
        ongorusmeaciklama.text = widget.ongorusme.aciklama != 'null' ? widget.ongorusme.aciklama : '';

        // Personel seçimi
        if (widget.ongorusme.personel != null && widget.ongorusme.personel["id"] != null) {
          try {
            selectedongorusmeyapan = isletmepersonellerliste.firstWhere(
                    (element) => element.id.toString() == widget.ongorusme.personel["id"].toString()
            );
          } catch (e) {
            log('Personel bulunamadı: $e');
            selectedongorusmeyapan = null;
          }
        }

        // Ön görüşme nedeni seçimi
        try {
          String sebepAdi = ongorusmesebebigetir(widget.ongorusme);
          selectedongorusmesebep = ongorusmenedeniliste.firstWhere(
                  (element) => element.getPaketUrunAdi() == sebepAdi
          );
        } catch (e) {
          log('Ön görüşme nedeni bulunamadı: $e');
          selectedongorusmesebep = null;
        }

        // Cinsiyet seçimi
        _selectedGender = musteridanisancinsiyet(widget.ongorusme);

        // Şehir seçimi
        if (widget.ongorusme.il_id != null && widget.ongorusme.il_id.isNotEmpty) {
          try {
            selectedongorusmesehir = sehirler.firstWhere(
                    (element) => element.id.toString() == widget.ongorusme.il_id.toString()
            );
          } catch (e) {
            log('Şehir bulunamadı: $e');
            selectedongorusmesehir = null;
          }
        }

        // Saat değerini TimeOfDay'e çevir
        if (widget.ongorusme.saat != null && widget.ongorusme.saat!.isNotEmpty) {
          try {
            List<String> timeParts = widget.ongorusme.saat!.split(':');
            if (timeParts.length == 2) {
              int hour = int.parse(timeParts[0]);
              int minute = int.parse(timeParts[1]);
              _selectedTime = TimeOfDay(hour: hour, minute: minute);
            }
          } catch (e) {
            log('Saat parse hatası: $e');
          }
        }

        yukleniyor = false;
      });
    } catch (e) {
      log('Initialize hatası: $e');
      setState(() {
        yukleniyor = false;
      });
    }
  }

  String musteridanisancinsiyet(OnGorusme og) {
    if (og.cinsiyet == "0") return "kadin";
    if (og.cinsiyet == "1") return "erkek";
    return "";
  }

  String ongorusmesebebigetir(OnGorusme og) {
    if (og.paket_id != null && og.paket_id.isNotEmpty && og.paket_id != "null") {
      return "${og.paket["paket_adi"] ?? "Paket"} (Paket)";
    }
    if (og.urun_id != null && og.urun_id.isNotEmpty && og.urun_id != "null") {
      return "${og.urun["urun_adi"] ?? "Ürün"} (Ürün)";
    }

    return "";
  }

  // YENİ: Modern saat seçim fonksiyonu - DAKİKALAR 00-15-30-45 OLARAK GÜNCELLENDİ
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
          ongorusmesaati.text = '${result.hour.toString().padLeft(2, '0')}:${result.minute.toString().padLeft(2, '0')}';
        });
        valid = true;
      }
    }
  }

  // YENİ: Modern saat seçim widget'ı - DAKİKALAR 00-15-30-45 OLARAK GÜNCELLENDİ
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

  // YENİ: Dakika indeksini gerçek dakika değerine dönüştürme
  int _getMinuteFromIndex(int index) {
    switch (index) {
      case 0: return 0;   // 00
      case 1: return 15;  // 15
      case 2: return 30;  // 30
      case 3: return 45;  // 45
      default: return 0;
    }
  }

  // YENİ: Mevcut dakikayı en yakın çeyrek saate yuvarlama
  int _getNearestQuarterMinute(int minute) {
    if (minute < 8) return 0;
    if (minute < 23) return 15;
    if (minute < 38) return 30;
    if (minute < 53) return 45;
    return 0; // 53-59 arası için 00 (saat artar)
  }

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  AutovalidateMode _autoValidate = AutovalidateMode.disabled;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: const Text('Ön Görüşme Düzenle', style: TextStyle(color: Colors.black)),
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            if (widget.isletmebilgi["demo_hesabi"].toString() == "1")
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: SizedBox(
                    width: 100,
                    child: YukseltButonu(isletme_bilgi: widget.isletmebilgi)
                ),
              ),
          ],
        ),
        body: yukleniyor
            ? Center(child: CircularProgressIndicator())
            : GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              autovalidateMode: _autoValidate,
              child: formUI(),
            ),
          ),
        ),
      ),
    );
  }

  Widget formUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Müşteri/Danışan Dropdown
        LazyDropdown(
          salonId: seciliisletme??'',
          selectedItem: selectedMusteri,
          onChanged: (value) {
            selectedMusteri = value;
            setState(() {
              selectedMusteri = value;
              adsoyad.text = value?.name ?? '';
              telefon.text = value?.cep_telefon ?? '';
              log('email '+value!.email);
              email.text = value?.email !='null' || !value!.email.isEmpty ? value!.email : '';
              if(value?.cinsiyet == "0")
                _selectedGender = "kadin";
              if(value?.cinsiyet == "1")
                _selectedGender = "erkek";
              if(value?.il_id != "null")
                selectedongorusmesehir = ongorusmesehir.firstWhere((item) => item.id == value?.il_id);
              if(value?.musteri_tipi != "null")
                selectedongorusmereferans = ongorusmereferans.firstWhere((item) => item.id == value?.musteri_tipi);
              if(value?.meslek != "null")
                meslek.text = value?.meslek ?? "";
            });
          },
        ),
        SizedBox(height: 16),

        // Ad Soyad
        _buildTextField(
          title: 'Ad Soyad',
          controller: adsoyad,
          keyboardType: TextInputType.text,
        ),

        SizedBox(height: 16),

        // Telefon
        _buildTextField(
          title: 'Telefon Numarası',
          controller: telefon,
          keyboardType: TextInputType.phone,
        ),

        SizedBox(height: 16),

        // Email
        _buildTextField(
          title: 'E-mail',
          controller: email,
          keyboardType: TextInputType.emailAddress,
        ),

        SizedBox(height: 16),

        // Cinsiyet
        Text('Cinsiyet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ListTile(
                leading: Radio<String>(
                  value: 'kadin',
                  groupValue: _selectedGender,
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value!;
                    });
                  },
                ),
                title: Text('Kadın'),
              ),
            ),
            Expanded(
              child: ListTile(
                leading: Radio<String>(
                  value: 'erkek',
                  groupValue: _selectedGender,
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value!;
                    });
                  },
                ),
                title: Text('Erkek'),
              ),
            ),
          ],
        ),

        SizedBox(height: 16),

        // Şehir
        _buildDropdownField(
          title: 'Şehir',
          value: selectedongorusmesehir,
          items: ongorusmesehir,
          displayText: (item) => item.sehir,
          onChanged: (value) {
            setState(() {
              selectedongorusmesehir = value;
            });
          },
          searchController: ongorusmesehircontroller,
          searchHint: 'Şehir Ara..',
        ),

        SizedBox(height: 16),

        // Referans
        _buildDropdownField(
          title: 'Referans',
          value: selectedongorusmereferans,
          items: ongorusmereferans,
          displayText: (item) => item.referans,
          onChanged: (value) {
            setState(() {
              selectedongorusmereferans = value;
            });
          },
        ),

        SizedBox(height: 16),

        // Meslek
        _buildTextField(
          title: 'Meslek',
          controller: meslek,
          keyboardType: TextInputType.text,
        ),

        SizedBox(height: 16),

        // Ön Görüşme Nedeni
        _buildDropdownField(
          title: 'Ön Görüşme Nedeni',
          value: selectedongorusmesebep,
          items: ongorusmeneden,
          displayText: (item) => item.getPaketUrunAdi(),
          onChanged: (value) {
            setState(() {
              selectedongorusmesebep = value;
            });
          },
          searchController: ongorusmesebepcontroller,
          searchHint: 'Ara..',
        ),

        SizedBox(height: 16),

        // Görüşmeyi Yapan
        _buildDropdownField(
          title: 'Görüşmeyi Yapan',
          value: selectedongorusmeyapan,
          items: ongorusmeyapan,
          displayText: (item) => item.personel_adi,
          onChanged: (value) {
            setState(() {
              selectedongorusmeyapan = value;
            });
          },
          searchController: ongorusmeyapancontroller,
          searchHint: 'Ara..',
        ),

        SizedBox(height: 16),

        // Tarih ve Saat
        Row(
          children: [
            Expanded(
              child: _buildDateField(
                title: 'Randevu Tarihi',
                controller: ongorusmetarihi,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildTimeField(
                title: 'Randevu Saati',
                controller: ongorusmesaati,
              ),
            ),
          ],
        ),

        SizedBox(height: 16),

        // Açıklama
        _buildTextField(
          title: 'Açıklama',
          controller: ongorusmeaciklama,
          keyboardType: TextInputType.multiline,
          maxLines: 3,
        ),

        SizedBox(height: 24),

        // Kaydet Butonu
        Center(
          child: ElevatedButton(
            onPressed: () {
              _saveOnGorusme();
            },
            child: Text('Kaydet', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              minimumSize: Size(120, 50),
            ),
          ),
        ),

        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDropdownField<T>({
    required String title,
    required T? value,
    required List<T> items,
    required String Function(T) displayText,
    required Function(T?) onChanged,
    TextEditingController? searchController,
    String searchHint = 'Ara..',
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Container(
          height: 50,
          decoration: BoxDecoration(
            border: Border.all(color: Color(0xFF6A1B9A)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton2<T>(
              isExpanded: true,
              hint: Text('Seçiniz', style: TextStyle(fontSize: 14)),
              items: items.map((item) => DropdownMenuItem(
                value: item,
                child: Text(displayText(item), style: TextStyle(fontSize: 14)),
              )).toList(),
              value: value,
              onChanged: onChanged,
              buttonStyleData: ButtonStyleData(
                padding: EdgeInsets.symmetric(horizontal: 16),
                height: 50,
              ),
              dropdownStyleData: DropdownStyleData(maxHeight: 200),
              menuItemStyleData: MenuItemStyleData(height: 40),
              dropdownSearchData: searchController != null ? DropdownSearchData(
                searchController: searchController,
                searchInnerWidgetHeight: 50,
                searchInnerWidget: Container(
                  height: 50,
                  padding: EdgeInsets.all(8),
                  child: TextFormField(
                    controller: searchController,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      hintText: searchHint,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                searchMatchFn: (item, searchValue) {
                  return displayText(item.value!).toLowerCase().contains(searchValue.toLowerCase());
                },
              ) : null,
              onMenuStateChange: (isOpen) {
                if (!isOpen && searchController != null) {
                  searchController.clear();
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String title,
    required TextEditingController controller,
    required TextInputType keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Container(
          height: maxLines > 1 ? null : 50,
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            decoration: InputDecoration(
              contentPadding: EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Color(0xFF6A1B9A)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Color(0xFF6A1B9A)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String title,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: true,
          onTap: () async {
            DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(1950),
              lastDate: DateTime(2100),
            );
            if (pickedDate != null) {
              String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
              controller.text = formattedDate;
            }
          },
          decoration: InputDecoration(
            contentPadding: EdgeInsets.all(12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Color(0xFF6A1B9A)),
            ),
          ),
        ),
      ],
    );
  }

  // YENİ: Modern saat alanı - DAKİKALAR 00-15-30-45 OLARAK GÜNCELLENDİ
  Widget _buildTimeField({
    required String title,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: true,
          onTap: () async {
            await _showModernTimePicker(context);
          },
          decoration: InputDecoration(
            contentPadding: EdgeInsets.all(12),
            suffixIcon: Icon(Icons.access_time, color: Color(0xFF6A1B9A)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Color(0xFF6A1B9A)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Color(0xFF6A1B9A)),
            ),
          ),
        ),
      ],
    );
  }

  void _saveOnGorusme() {
    String urunid = "";
    String paketid = "";
    String hizmetid = '';

    String paketurun = selectedongorusmesebep?.getPaketUrunAdi() ?? "";
    if (paketurun.contains("Paket")) {
      paketid = selectedongorusmesebep?.getId() ?? "";
    } else if (paketurun.contains("Ürün")) {
      urunid = selectedongorusmesebep?.getId() ?? "";
    } else if (paketurun.contains('IsletmeHizmet')) {
      hizmetid = selectedongorusmesebep?.getId() ?? '';
    }

    widget.ongorusmedatasource.onGorusmeEkleGuncelle(
        widget.ongorusme.id.toString(),
        selectedMusteri?.id ?? "",
        adsoyad.text,
        telefon.text,
        email.text,
        _selectedGender,
        context,
        seciliisletme,
        selectedongorusmesehir?.id ?? "",
        selectedongorusmereferans?.id ?? "",
        meslek.text,
        urunid,
        paketid,
        ongorusmetarihi.text,
        ongorusmesaati.text,
        ongorusmeaciklama.text,
        selectedongorusmeyapan?.id ?? "",
        "",
        hizmetid
    );
  }
}
import 'dart:convert';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:randevu_sistem/Frontend/sfdatatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../Frontend/yukseltbutonu.dart';
import 'ajanda.dart';

class AjandaEkle extends StatefulWidget {
  final AjandaDataSource ajandaDataSource;
  final dynamic isletmebilgi;
  AjandaEkle({Key? key, required this.ajandaDataSource, required this.isletmebilgi}) : super(key: key);

  @override
  _AjandaEkleState createState() => _AjandaEkleState();
}

class _AjandaEkleState extends State<AjandaEkle> {
  // Controller'lar
  final TextEditingController _baslikController = TextEditingController();
  final TextEditingController _tarihController = TextEditingController();
  final TextEditingController _saatController = TextEditingController();
  final TextEditingController _icerikController = TextEditingController();

  // Dropdown için
  String? _selectedItem = '2';
  final List<String> sablon = ['1', '2', '3', '4', '5'];

  // Diğer state değişkenleri
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _hatirlatmaAktif = true;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Varsayılan tarihi bugün olarak ayarla
    _tarihController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  Future<void> _saveForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (_isLoading) return;

      setState(() {
        _isLoading = true;
      });

      try {
        String baslik = _baslikController.text.trim();
        String tarih = _tarihController.text.trim();
        String saat = _saatController.text.trim();
        String icerik = _icerikController.text.trim();
        String hatirlatmaSaati = _selectedItem ?? "2";

        print('KAYDEDİLEN VERİLER:');
        print('Başlık: "$baslik"');
        print('Tarih: "$tarih"');
        print('Saat: "$saat"');
        print('İçerik: "$icerik"');
        print('Hatırlatma Saati: $hatirlatmaSaati');
        print('Hatırlatma Aktif: $_hatirlatmaAktif');

        if (baslik.isEmpty) throw Exception('Başlık boş olamaz');
        if (tarih.isEmpty) throw Exception('Tarih boş olamaz');
        if (saat.isEmpty) throw Exception('Saat boş olamaz');

        // API çağrısını YAP ama bekleme - callback ile sonucu handle et
        widget.ajandaDataSource.ajandaEkleGuncelle(
            '',
            baslik,
            icerik,
            tarih,
            saat,
            hatirlatmaSaati,
            _hatirlatmaAktif,
            context
        ).then((_) {
          // BAŞARILI - direkt kapat
          if (mounted) {
            Navigator.of(context).pop(true);
          }
        }).catchError((e) {
          // HATA - loading'i durdur ve hatayı göster
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Hata: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        });

      } catch (e) {
        print('Kaydetme hatası: $e');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Hata: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lütfen tüm gerekli alanları doldurunuz!'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  // Modern saat seçici
  Future<void> _showModernTimePicker(BuildContext context) async {
    TimeOfDay initialTime = _selectedTime;

    final result = await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildModernTimePicker(initialTime),
    );

    if (result != null && result is TimeOfDay) {
      setState(() {
        _selectedTime = result;
        _saatController.text = '${result.hour.toString().padLeft(2, '0')}:${result.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Widget _buildModernTimePicker(TimeOfDay initialTime) {
    int selectedHour = initialTime.hour;
    int selectedMinute = _getNearestQuarterMinute(initialTime.minute);

    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
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
                  border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'İptal',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ),
                    Text(
                      'Saat Seç',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(TimeOfDay(hour: selectedHour, minute: selectedMinute));
                      },
                      child: Text(
                        'Tamam',
                        style: TextStyle(color: Color(0xFF6A1B9A), fontSize: 16, fontWeight: FontWeight.w600),
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
                  style: TextStyle(fontSize: 48, fontWeight: FontWeight.w300, color: Color(0xFF6A1B9A)),
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
                          setState(() => selectedHour = index);
                        },
                        children: List.generate(24, (hour) {
                          bool isSelected = hour == selectedHour;
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

                    // Dakika seçici - 00-15-30-45
                    Expanded(
                      child: ListWheelScrollView(
                        itemExtent: 50,
                        perspective: 0.005,
                        diameterRatio: 1.5,
                        physics: FixedExtentScrollPhysics(),
                        onSelectedItemChanged: (index) {
                          setState(() => selectedMinute = _getMinuteFromIndex(index));
                        },
                        children: List.generate(4, (index) {
                          int minute = _getMinuteFromIndex(index);
                          bool isSelected = minute == selectedMinute;
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
        );
      },
    );
  }

  int _getMinuteFromIndex(int index) {
    switch (index) {
      case 0: return 0;
      case 1: return 15;
      case 2: return 30;
      case 3: return 45;
      default: return 0;
    }
  }

  int _getNearestQuarterMinute(int minute) {
    if (minute < 8) return 0;
    if (minute < 23) return 15;
    if (minute < 38) return 30;
    if (minute < 53) return 45;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: Text('Yeni Not Ekle', style: TextStyle(color: Colors.black)),
          leading: IconButton(
            icon: Icon(Icons.clear_rounded, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
          toolbarHeight: 60,
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
          backgroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          reverse: true,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20),

                // BAŞLIK
                _buildLabel('Başlık'),
                SizedBox(height: 10),
                _buildTextFormField(
                  controller: _baslikController,
                  validator: (value) => value == null || value.isEmpty ? 'Lütfen not başlığını yazınız!' : null,
                ),
                SizedBox(height: 10),

                // TARİH ve SAAT
                Row(
                  children: [
                    Expanded(child: _buildTarihField()),
                    SizedBox(width: 10),
                    Expanded(child: _buildSaatField()),
                  ],
                ),
                SizedBox(height: 10),

                // HATIRLATMA AYARLARI
                Row(
                  children: [
                    Expanded(child: _buildHatirlatmaSaatDropdown()),
                    Expanded(child: _buildHatirlatmaSwitch()),
                  ],
                ),
                SizedBox(height: 10),

                // İÇERİK
                _buildLabel('İçerik'),
                SizedBox(height: 10),
                _buildIcerikField(),
                SizedBox(height: 20),

                // KAYDET BUTONU
                _buildSaveButton(),

                Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom))
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 20.0),
      child: Text(text, style: TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String? Function(String?) validator,
    int maxLines = 1,
  }) {
    return Container(
      height: maxLines == 1 ? 40 : null,
      padding: const EdgeInsets.only(left: 20.0, right: 20),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: TextInputType.text,
        maxLines: maxLines,
        decoration: InputDecoration(
          focusColor: Color(0xFF6A1B9A),
          hoverColor: Color(0xFF6A1B9A),
          contentPadding: EdgeInsets.all(15.0),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF6A1B9A)),
            borderRadius: BorderRadius.circular(10.0),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF6A1B9A)),
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
      ),
    );
  }

  Widget _buildTarihField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Tarih'),
        SizedBox(height: 10),
        Container(
          height: 40,
          padding: EdgeInsets.only(left: 20, right: 10),
          child: TextFormField(
            controller: _tarihController,
            validator: (value) => value == null || value.isEmpty ? 'Lütfen tarihi seçiniz!' : null,
            readOnly: true,
            onTap: () async {
              DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(1950),
                lastDate: DateTime(2100),
              );
              if (pickedDate != null) {
                setState(() {
                  _tarihController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
                });
              }
            },
            decoration: InputDecoration(
              suffixIcon: Icon(Icons.calendar_today, color: Color(0xFF6A1B9A),size: 16,), // Tarih ikonu eklendi
              contentPadding: EdgeInsets.all(2.0),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF6A1B9A)),
                borderRadius: BorderRadius.circular(10.0),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF6A1B9A)),
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaatField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Saat'),
        SizedBox(height: 10),
        Container(
          height: 40,
          padding: EdgeInsets.only(left: 10, right: 20),
          child: TextFormField(
            controller: _saatController,
            validator: (value) => value == null || value.isEmpty ? 'Lütfen saati seçiniz!' : null,
            readOnly: true,
            onTap: () => _showModernTimePicker(context),
            decoration: InputDecoration(
              suffixIcon: Icon(Icons.access_time, color: Color(0xFF6A1B9A)),
              contentPadding: EdgeInsets.all(15.0),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF6A1B9A)),
                borderRadius: BorderRadius.circular(10.0),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF6A1B9A)),
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHatirlatmaSaatDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Kaç saat önce hatırlatılsın'),
        SizedBox(height: 10),
        Container(
          margin: EdgeInsets.only(left: 20, right: 10),
          height: 40,
          decoration: BoxDecoration(
            border: Border.all(color: Color(0xFF6A1B9A)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton2<String>(
              isExpanded: true,
              value: _selectedItem,
              onChanged: (value) {
                setState(() => _selectedItem = value);
              },
              items: sablon.map((item) => DropdownMenuItem(
                value: item,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5),
                  child: Text('$item saat', style: TextStyle(fontSize: 14)),
                ),
              )).toList(),
              buttonStyleData: ButtonStyleData(
                padding: EdgeInsets.symmetric(horizontal: 16),
                height: 40,
              ),
              dropdownStyleData: DropdownStyleData(maxHeight: 200),
              menuItemStyleData: MenuItemStyleData(height: 40),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHatirlatmaSwitch() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Hatırlatma'),
        Container(
          padding: EdgeInsets.only(left: 50, top: 8),
          child: Switch(
            value: _hatirlatmaAktif,
            activeColor: Colors.purple[800],
            onChanged: (bool value) {
              setState(() => _hatirlatmaAktif = value);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildIcerikField() {
    return Container(
      padding: const EdgeInsets.only(left: 20.0, right: 20),
      child: TextFormField(
        controller: _icerikController,
        validator: (value) => value == null || value.isEmpty ? 'Lütfen notunuzu yazınız!' : null,
        maxLines: 6,
        decoration: InputDecoration(
          contentPadding: EdgeInsets.all(15.0),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF6A1B9A)),
            borderRadius: BorderRadius.circular(10.0),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF6A1B9A)),
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: _isLoading ? null : _saveForm,
          child: _isLoading
              ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
              : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.save),
              SizedBox(width: 8),
              Text('Kaydet'),
            ],
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _isLoading ? Colors.grey : Colors.green,
            foregroundColor: Colors.white,
            minimumSize: Size(120, 45),
          ),
        ),
      ],
    );
  }
}
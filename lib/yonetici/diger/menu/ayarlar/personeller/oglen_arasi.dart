import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import '../../../../../Backend/backend.dart';
import '../../../../../Models/isletmecalismasaatleri.dart';
import '../../../../../Models/molasaatleri.dart';
import 'oglen_arasi.dart';

class OglenArasi extends StatefulWidget {
  final dynamic isletmebilgi;
  const OglenArasi({Key? key,required this.isletmebilgi}) : super(key: key);

  @override
  _OglenArasiState createState() => _OglenArasiState();
}

class _OglenArasiState extends State<OglenArasi> {
  late String seciliisletme;
  TextEditingController baslangicsaati1 = TextEditingController();
  TextEditingController baslangicsaati2 = TextEditingController();
  TextEditingController baslangicsaati3 = TextEditingController();
  TextEditingController baslangicsaati4 = TextEditingController();
  TextEditingController baslangicsaati5 = TextEditingController();
  TextEditingController baslangicsaati6 = TextEditingController();
  TextEditingController baslangicsaati7 = TextEditingController();
  TextEditingController bitissaati1 = TextEditingController();
  TextEditingController bitissaati2 = TextEditingController();
  TextEditingController bitissaati3 = TextEditingController();
  TextEditingController bitissaati4 = TextEditingController();
  TextEditingController bitissaati5 = TextEditingController();
  TextEditingController bitissaati6 = TextEditingController();
  TextEditingController bitissaati7 = TextEditingController();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool? isChecked1;
  bool? isChecked2;
  bool? isChecked3;
  bool? isChecked4;
  bool? isChecked5;
  bool? isChecked6;
  bool? isChecked7;
  final formKey = GlobalKey<FormState>();
  late Map<String,dynamic> calismasaatleri;

  Future<void> initialize() async {
    seciliisletme = (await secilisalonid())!;
    final List<IsletmeMolaSaatleri> settings = await fetchSalonBreakHoursSettings(seciliisletme);

    setState(() {
      // Map settings to respective days
      for (final setting in settings) {
        final isChecked = setting.mola_var!=0;
        final startTime = setting.baslangic;
        final endTime = setting.bitis;
        debugPrint('Day: ${setting.haftaninGunu}, Start Time: $startTime, End Time: $endTime');

        switch (setting.haftaninGunu) {
          case 1:
            isChecked1 = isChecked;
            baslangicsaati1.text =  setting.baslangic;
            bitissaati1.text = endTime;
            debugPrint('Day: ${setting.haftaninGunu}, Start Time: $baslangicsaati1, End Time: $bitissaati1');
            break;
          case 2:
            isChecked2 = isChecked;
            baslangicsaati2.text = startTime;
            bitissaati2.text = endTime;
            break;
          case 3:
            isChecked3 = isChecked;
            baslangicsaati3.text = startTime;
            bitissaati3.text = endTime;
            break;
          case 4:
            isChecked4 = isChecked;
            baslangicsaati4.text = startTime;
            bitissaati4.text = endTime;
            break;
          case 5:
            isChecked5 = isChecked;
            baslangicsaati5.text = startTime;
            bitissaati5.text = endTime;
            break;
          case 6:
            isChecked6 = isChecked;
            baslangicsaati6.text = startTime;
            bitissaati6.text = endTime;
            break;
          case 7:
            isChecked7 = isChecked;
            baslangicsaati7.text = startTime;
            bitissaati7.text = endTime;
            break;
        }
      }
    });
  }

  @override
  void initState() {
    _selectedTime = TimeOfDay.now();
    super.initState();
    initialize();
  }

  // YENİ: Modern saat seçim fonksiyonu - DAKİKALAR 00-15-30-45 OLARAK GÜNCELLENDİ
  Future<void> _showModernTimePicker(BuildContext context, TextEditingController controller) async {
    TimeOfDay initialTime = _selectedTime;

    // Eğer controller'da değer varsa, onu kullan
    if (controller.text.isNotEmpty) {
      try {
        List<String> timeParts = controller.text.split(':');
        if (timeParts.length == 2) {
          int hour = int.parse(timeParts[0]);
          int minute = int.parse(timeParts[1]);
          initialTime = TimeOfDay(hour: hour, minute: minute);
        }
      } catch (e) {
        log('Saat parse hatası: $e');
      }
    }

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
          controller.text = '${result.hour.toString().padLeft(2, '0')}:${result.minute.toString().padLeft(2, '0')}';
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

  // YENİ: Ortak saat TextField widget'ı
  Widget _buildTimeField(TextEditingController controller, String hintText) {
    return Container(
      height: 40,
      padding: EdgeInsets.only(left:10,right: 10),
      child: TextFormField(
        controller: controller,
        onSaved: (value) {
          controller.text = value!;
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Bu alan zorunludur!';
          }
          return null;
        },
        readOnly: true,
        onTap: () async {
          await _showModernTimePicker(context, controller);
        },
        decoration: InputDecoration(
          suffixIcon: Icon(Icons.access_time, size: 15, color: Color(0xFF6A1B9A)),
          focusColor: Color(0xFF6A1B9A),
          hoverColor: Color(0xFF6A1B9A),
          hintText: hintText,
          hintStyle: TextStyle(color: Color(0xFF6A1B9A)),
          contentPadding: EdgeInsets.all(5.0),
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

  // YENİ: Gün satırı widget'ı
  Widget _buildDayRow({
    required String dayName,
    required bool? isChecked,
    required Function(bool?) onChanged,
    required TextEditingController startController,
    required TextEditingController endController,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              child: Row(
                children: [
                  Checkbox(
                    value: isChecked ?? false,
                    onChanged: onChanged,
                  ),
                  Text(dayName),
                ],
              ),
            ),
            Expanded(
              child: _buildTimeField(startController, 'Başlangıç'),
            ),
            Expanded(
              child: _buildTimeField(endController, 'Bitiş'),
            ),
          ],
        ),
        const Divider(
          height: 2.0,
          thickness: 1,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        toolbarHeight: 60,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: SizedBox(
                width: 100,
                child: YukseltButonu(isletme_bilgi:widget.isletmebilgi)
            ),
          ),
        ],
        title: Text("Mola Saatleri",style: TextStyle(color: Colors.black),),
      ),
      body: Padding(
        padding: EdgeInsets.all(5),
        child: Form(
          key: formKey,
          child: ListView(
            children: [
              // Pazartesi
              _buildDayRow(
                dayName: 'Pazartesi',
                isChecked: isChecked1,
                onChanged: (bool? value) {
                  setState(() {
                    isChecked1 = value;
                  });
                },
                startController: baslangicsaati1,
                endController: bitissaati1,
              ),

              // Salı
              _buildDayRow(
                dayName: 'Salı',
                isChecked: isChecked2,
                onChanged: (bool? value) {
                  setState(() {
                    isChecked2 = value;
                  });
                },
                startController: baslangicsaati2,
                endController: bitissaati2,
              ),

              // Çarşamba
              _buildDayRow(
                dayName: 'Çarşamba',
                isChecked: isChecked3,
                onChanged: (bool? value) {
                  setState(() {
                    isChecked3 = value;
                  });
                },
                startController: baslangicsaati3,
                endController: bitissaati3,
              ),

              // Perşembe
              _buildDayRow(
                dayName: 'Perşembe',
                isChecked: isChecked4,
                onChanged: (bool? value) {
                  setState(() {
                    isChecked4 = value;
                  });
                },
                startController: baslangicsaati4,
                endController: bitissaati4,
              ),

              // Cuma
              _buildDayRow(
                dayName: 'Cuma',
                isChecked: isChecked5,
                onChanged: (bool? value) {
                  setState(() {
                    isChecked5 = value;
                  });
                },
                startController: baslangicsaati5,
                endController: bitissaati5,
              ),

              // Cumartesi
              _buildDayRow(
                dayName: 'Cumartesi',
                isChecked: isChecked6,
                onChanged: (bool? value) {
                  setState(() {
                    isChecked6 = value;
                  });
                },
                startController: baslangicsaati6,
                endController: bitissaati6,
              ),

              // Pazar
              _buildDayRow(
                dayName: 'Pazar',
                isChecked: isChecked7,
                onChanged: (bool? value) {
                  setState(() {
                    isChecked7 = value ?? false;
                  });
                },
                startController: baslangicsaati7,
                endController: bitissaati7,
              ),

              SizedBox(height: 20,),
              ElevatedButton(
                onPressed: () {
                  submitform(
                    seciliisletme,
                    isChecked1,
                    isChecked2,
                    isChecked3,
                    isChecked4,
                    isChecked5,
                    isChecked6,
                    isChecked7,
                    baslangicsaati1.text,
                    baslangicsaati2.text,
                    baslangicsaati3.text,
                    baslangicsaati4.text,
                    baslangicsaati5.text,
                    baslangicsaati6.text,
                    baslangicsaati7.text,
                    bitissaati1.text,
                    bitissaati2.text,
                    bitissaati3.text,
                    bitissaati4.text,
                    bitissaati5.text,
                    bitissaati6.text,
                    bitissaati7.text,
                    context,
                  );
                },
                child: Text('Kaydet'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.green,
                  minimumSize: Size(90, 40),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> submitform(String salonId, calisiyor1,  calisiyor2,  calisiyor3,  calisiyor4,  calisiyor5,  calisiyor6,  calisiyor7,
    String baslangic1, String baslangic2, String baslangic3, String baslangic4, String baslangic5, String baslangic6, String baslangic7,
    String bitis1, String bitis2, String bitis3, String bitis4, String bitis5, String bitis6, String bitis7,
    BuildContext context) async{
  final Map<String, dynamic> formData = {
    'isletme_id': salonId,
    'calisiyor1': calisiyor1 == true ? 1 : 0,
    'calisiyor2': calisiyor2 == true ? 1 : 0,
    'calisiyor3': calisiyor3 == true ? 1 : 0,
    'calisiyor4': calisiyor4 == true ? 1 : 0,
    'calisiyor5': calisiyor5 == true ? 1 : 0,
    'calisiyor6': calisiyor6 == true ? 1 : 0,
    'calisiyor7': calisiyor7 == true ? 1 : 0,
    'calismasaatibaslangic1': baslangic1,
    'calismasaatibaslangic2': baslangic2,
    'calismasaatibaslangic3': baslangic3,
    'calismasaatibaslangic4': baslangic4,
    'calismasaatibaslangic5': baslangic5,
    'calismasaatibaslangic6': baslangic6,
    'calismasaatibaslangic7': baslangic7,
    'calismasaatibisis1': bitis1,
    'calismasaatibisis2': bitis2,
    'calismasaatibisis3': bitis3,
    'calismasaatibisis4': bitis4,
    'calismasaatibisis5': bitis5,
    'calismasaatibisis6': bitis6,
    'calismasaatibisis7': bitis7,
  };

  final queryParameters = formData.entries.map((e) => '${e.key}=${e.value}').join('&');

  final response = await http.get(
    Uri.parse('https://app.randevumcepte.com.tr/api/v1/mola_saati_guncelle_ekle/$salonId?$queryParameters'),
    headers: {'Content-Type': 'application/json'},
  );

  debugPrint('Response status: ${response.statusCode}');
  debugPrint('Response body: ${response.body}');

  if (response.statusCode == 200) {
    log('etkinlik güncelleme : '+response.body);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Güncelleme Başarılı '),
      ),
    );
  } else {
    debugPrint('Failed to load data. Status code: ${response.statusCode}');
    throw Exception('Failed to load data: ${response.reasonPhrase}');
  }
}
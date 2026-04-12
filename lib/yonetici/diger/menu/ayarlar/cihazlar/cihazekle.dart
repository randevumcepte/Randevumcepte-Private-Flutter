import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import '../../../../../Backend/backend.dart';
import '../../../../../Frontend/sfdatatable.dart';
import '../personeller/oglen_arasi.dart';

class CihazEkle extends StatefulWidget {
  final CihazDataSource cihazdatasource;
  final dynamic isletmebilgi;
  const CihazEkle({Key? key, required this.cihazdatasource,required this.isletmebilgi}) : super(key: key);

  @override
  _CihazEkleState createState() => _CihazEkleState();
}

class _CihazEkleState extends State<CihazEkle> {
  TextEditingController cihazadi = TextEditingController();

  late String seciliisletme;

  // Çalışma saatleri kontrolleri
  TextEditingController baslangicsaati1 = TextEditingController(text:"00:00");
  TextEditingController baslangicsaati2 = TextEditingController(text:"00:00");
  TextEditingController baslangicsaati3 = TextEditingController(text:"00:00");
  TextEditingController baslangicsaati4 = TextEditingController(text:"00:00");
  TextEditingController baslangicsaati5 = TextEditingController(text:"00:00");
  TextEditingController baslangicsaati6 = TextEditingController(text:"00:00");
  TextEditingController baslangicsaati7 = TextEditingController(text:"00:00");
  TextEditingController bitissaati1 = TextEditingController(text:"00:00");
  TextEditingController bitissaati2 = TextEditingController(text:"00:00");
  TextEditingController bitissaati3 = TextEditingController(text:"00:00");
  TextEditingController bitissaati4 = TextEditingController(text:"00:00");
  TextEditingController bitissaati5 = TextEditingController(text:"00:00");
  TextEditingController bitissaati6 = TextEditingController(text:"00:00");
  TextEditingController bitissaati7 = TextEditingController(text:"00:00");

  // Mola saatleri kontrolleri
  TextEditingController baslangicsaati8 = TextEditingController(text:"00:00");
  TextEditingController baslangicsaati9 = TextEditingController(text:"00:00");
  TextEditingController baslangicsaati10 = TextEditingController(text:"00:00");
  TextEditingController baslangicsaati11= TextEditingController(text:"00:00");
  TextEditingController baslangicsaati12= TextEditingController(text:"00:00");
  TextEditingController baslangicsaati13= TextEditingController(text:"00:00");
  TextEditingController baslangicsaati14= TextEditingController(text:"00:00");
  TextEditingController bitissaati8 = TextEditingController(text:"00:00");
  TextEditingController bitissaati9 = TextEditingController(text:"00:00");
  TextEditingController bitissaati10 = TextEditingController(text:"00:00");
  TextEditingController bitissaati11= TextEditingController(text:"00:00");
  TextEditingController bitissaati12= TextEditingController(text:"00:00");
  TextEditingController bitissaati13= TextEditingController(text:"00:00");
  TextEditingController bitissaati14= TextEditingController(text:"00:00");

  TimeOfDay _selectedTime = TimeOfDay.now();

  // Çalışma saatleri checkbox'ları
  bool? isChecked1;
  bool? isChecked2;
  bool? isChecked3;
  bool? isChecked4;
  bool? isChecked5;
  bool? isChecked6;
  bool? isChecked7;

  // Mola saatleri checkbox'ları
  bool? isChecked8;
  bool? isChecked9;
  bool? isChecked10;
  bool? isChecked11;
  bool? isChecked12;
  bool? isChecked13;
  bool? isChecked14;

  final formKey = GlobalKey<FormState>();
  late Map<String,dynamic> calismasaatleri;

  void _fetchData() async {
    seciliisletme = (await secilisalonid())!;
  }

  void initState() {
    super.initState();
    _fetchData();
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

  // GÜNCELLENDİ: Modern saat seçim fonksiyonu - DAKİKALAR 00-15-30-45 OLARAK GÜNCELLENDİ
  Future<void> _showModernTimePicker(BuildContext context, TextEditingController controller) async {
    TimeOfDay initialTime = _selectedTime;

    if (controller.text.isNotEmpty) {
      try {
        List<String> timeParts = controller.text.split(':');
        if (timeParts.length == 2) {
          int hour = int.parse(timeParts[0]);
          int minute = int.parse(timeParts[1]);
          initialTime = TimeOfDay(hour: hour, minute: minute);
        }
      } catch (e) {
        // Hata durumunda mevcut zamanı kullan
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

  // GÜNCELLENDİ: Modern saat seçim widget'ı - DAKİKALAR 00-15-30-45 OLARAK GÜNCELLENDİ
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

                      // GÜNCELLENDİ: Dakika seçici - SADECE 00-15-30-45
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

  // Ortak saat TextField widget'ı
  Widget _buildTimeField(TextEditingController controller, String hintText) {
    return Container(
      height: 40,
      padding: EdgeInsets.only(left: 10, right: 10),
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

  // Gün satırı widget'ı - Çalışma Saatleri
  Widget _buildWorkingDayRow({
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

  // Gün satırı widget'ı - Mola Saatleri
  Widget _buildBreakDayRow({
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
    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: Colors.white,
          toolbarHeight: 60,
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
          title: Text("Yeni Cihaz",style: TextStyle(color: Colors.black)),
        ),
        body: SingleChildScrollView(
          reverse: true,
          padding: EdgeInsets.all(8),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 10),

                // Cihaz Adı
                Padding(
                  padding: const EdgeInsets.only(left: 5.0),
                  child: Text('Cihaz Adı',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold)),
                ),
                SizedBox(height: 10),
                Container(
                  height: 40,
                  child: TextFormField(
                    keyboardType: TextInputType.text,
                    controller: cihazadi,
                    onSaved: (value) {
                      cihazadi.text = value!;
                    },
                    enabled:true,
                    decoration: InputDecoration(
                      focusColor:Color(0xFF6A1B9A),
                      hoverColor: Color(0xFF6A1B9A),
                      hintStyle: TextStyle(color:  Color(0xFF6A1B9A)),
                      contentPadding:  EdgeInsets.all(15.0),
                      enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF6A1B9A)),
                          borderRadius: BorderRadius.circular(10.0)
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF6A1B9A)),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 20),

                // ÇALIŞMA SAATLERİ BÖLÜMÜ
                Padding(
                  padding: const EdgeInsets.only(left: 5.0),
                  child: Text('Çalışma Saatleri',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold)),
                ),
                const Divider(),

                // Pazartesi
                _buildWorkingDayRow(
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
                _buildWorkingDayRow(
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
                _buildWorkingDayRow(
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
                _buildWorkingDayRow(
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
                _buildWorkingDayRow(
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
                _buildWorkingDayRow(
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
                _buildWorkingDayRow(
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

                Divider(),
                SizedBox(height: 10),

                // CİHAZ MOLA SAATLERİ BÖLÜMÜ
                Padding(
                  padding: const EdgeInsets.only(left: 5.0),
                  child: Text('Cihaz Mola Saatleri',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold)),
                ),
                const Divider(),

                // Pazartesi Mola
                _buildBreakDayRow(
                  dayName: 'Pazartesi',
                  isChecked: isChecked8,
                  onChanged: (bool? value) {
                    setState(() {
                      isChecked8 = value;
                    });
                  },
                  startController: baslangicsaati8,
                  endController: bitissaati8,
                ),

                // Salı Mola
                _buildBreakDayRow(
                  dayName: 'Salı',
                  isChecked: isChecked9,
                  onChanged: (bool? value) {
                    setState(() {
                      isChecked9 = value;
                    });
                  },
                  startController: baslangicsaati9,
                  endController: bitissaati9,
                ),

                // Çarşamba Mola
                _buildBreakDayRow(
                  dayName: 'Çarşamba',
                  isChecked: isChecked10,
                  onChanged: (bool? value) {
                    setState(() {
                      isChecked10 = value;
                    });
                  },
                  startController: baslangicsaati10,
                  endController: bitissaati10,
                ),

                // Perşembe Mola
                _buildBreakDayRow(
                  dayName: 'Perşembe',
                  isChecked: isChecked11,
                  onChanged: (bool? value) {
                    setState(() {
                      isChecked11 = value;
                    });
                  },
                  startController: baslangicsaati11,
                  endController: bitissaati11,
                ),

                // Cuma Mola
                _buildBreakDayRow(
                  dayName: 'Cuma',
                  isChecked: isChecked12,
                  onChanged: (bool? value) {
                    setState(() {
                      isChecked12 = value;
                    });
                  },
                  startController: baslangicsaati12,
                  endController: bitissaati12,
                ),

                // Cumartesi Mola
                _buildBreakDayRow(
                  dayName: 'Cumartesi',
                  isChecked: isChecked13,
                  onChanged: (bool? value) {
                    setState(() {
                      isChecked13 = value;
                    });
                  },
                  startController: baslangicsaati13,
                  endController: bitissaati13,
                ),

                // Pazar Mola
                _buildBreakDayRow(
                  dayName: 'Pazar',
                  isChecked: isChecked14,
                  onChanged: (bool? value) {
                    setState(() {
                      isChecked14 = value ?? false;
                    });
                  },
                  startController: baslangicsaati14,
                  endController: bitissaati14,
                ),

                const Divider(height: 2.0, thickness: 1),

                SizedBox(height: 20),

                // Kaydet Butonu
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: (){
                        widget.cihazdatasource.cihazekle(
                          cihazadi.text,
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
                          isChecked8,
                          isChecked9,
                          isChecked10,
                          isChecked11,
                          isChecked12,
                          isChecked13,
                          isChecked14,
                          baslangicsaati8.text,
                          baslangicsaati9.text,
                          baslangicsaati10.text,
                          baslangicsaati11.text,
                          baslangicsaati12.text,
                          baslangicsaati13.text,
                          baslangicsaati14.text,
                          bitissaati8.text,
                          bitissaati9.text,
                          bitissaati10.text,
                          bitissaati11.text,
                          bitissaati12.text,
                          bitissaati13.text,
                          bitissaati14.text,
                          context,
                        );
                      },
                      child: Text('Kaydet'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                          backgroundColor: Colors.green,
                          minimumSize: Size(90, 40)
                      ),
                    ),
                  ],
                ),
                Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom))
              ],
            ),
          ),
        ),
      ),
    );
  }
}
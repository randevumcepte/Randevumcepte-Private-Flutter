import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:randevu_sistem/Models/takvimturu.dart';
import 'package:randevu_sistem/yonetici/randevular/randevu_page.dart';
import 'package:randevu_sistem/yonetici/randevular/randevuduzenle.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:randevu_sistem/Models/randevular.dart';
import '../../Backend/backend.dart';
import '../../Frontend/indexedstack.dart';
import '../../Frontend/popupdialogs.dart';
import '../../Frontend/sfdatatable.dart';
import '../../Models/ongorusmeler.dart';
import '../../Models/personel.dart';
import '../../Models/user.dart';
import '../../yukselt.dart';
import '../adisyonlar/satislar/tahsilat.dart';
import '../diger/menu/randvular/randevularmenu.dart';
import 'appointment-editor.dart';

class Takvim extends StatefulWidget {
  final int selectedTab;
  final dynamic isletmebilgi;
  final Kullanici kullanici;
  final int kullanicirolu;

  const Takvim({
    Key? key,
    required this.kullanici,
    required this.selectedTab,
    required this.isletmebilgi,
    required this.kullanicirolu
  }) : super(key: key);

  @override
  TakvimState createState() => TakvimState();
}

class TakvimState extends State<Takvim> {

  double _savedVerticalScrollPosition = 0.0;
  double _savedHorizontalScrollPosition = 0.0;

  DateTime _currentTime = DateTime.now();
  Timer? _timer;
  final GlobalKey _calendarKey = GlobalKey();
  DateTime _selectedDate = DateTime.now();
  DateTime seciliTarih = DateTime.now();
  late PersonelDataSource _personelDataGridSource;
  List<Randevu> randevuliste = [];
  List<Personel> personelliste = [];
  String personelid = "";
  bool isloading = true;
  late String baslangicSaati;
  late String bitisSaati;
  TakvimTuru? selectedTakvimTuru;
  TextEditingController takvimTuruText = TextEditingController();

  final List<TakvimTuru> takvimTuru = [
    TakvimTuru(id: '1', takvim_turu: 'Personele Göre'),
    TakvimTuru(id: '0', takvim_turu: 'Hizmete Göre'),
    TakvimTuru(id: '2', takvim_turu: 'Cihaza Göre'),
    TakvimTuru(id: '3', takvim_turu: 'Odaya Göre'),
  ];

  List<Appointment> updatedAppointments = [];
  List<CalendarResource> resources = [];

  final ScrollController _topHorizontalController = ScrollController();
  final ScrollController _gridHorizontalController = ScrollController();

  final ScrollController _leftVerticalController = ScrollController();
  final ScrollController _gridVerticalController = ScrollController();
  final double _hourHeight = 120.0;
  final double _quarterHeight = 15.0; // 15 dakika = 15px (60/4)
  bool _isSyncingHorizontal = false;
  bool _isSyncingVertical = false;
  @override

  void initState() {
    super.initState();
    _selectedDate = DateTime.now();

    // YATAY SENKRON - grid horizontal -> top horizontal
    _gridHorizontalController.addListener(() {
      if (_isSyncingHorizontal) return;
      _isSyncingHorizontal = true;
      if (_topHorizontalController.hasClients) {
        _topHorizontalController.jumpTo(_gridHorizontalController.offset);
      }
      _isSyncingHorizontal = false;
    });

    // YATAY SENKRON - top horizontal -> grid horizontal
    _topHorizontalController.addListener(() {
      if (_isSyncingHorizontal) return;
      _isSyncingHorizontal = true;
      if (_gridHorizontalController.hasClients) {
        _gridHorizontalController.jumpTo(_topHorizontalController.offset);
      }
      _isSyncingHorizontal = false;
    });

    _timer = Timer.periodic(Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });

    // DİKEY SENKRON - grid vertical -> left vertical
    _gridVerticalController.addListener(() {
      if (_isSyncingVertical) return;
      _isSyncingVertical = true;
      if (_leftVerticalController.hasClients) {
        _leftVerticalController.jumpTo(_gridVerticalController.offset);
      }
      _isSyncingVertical = false;
    });

    // DİKEY SENKRON - left vertical -> grid vertical
    _leftVerticalController.addListener(() {
      if (_isSyncingVertical) return;
      _isSyncingVertical = true;
      if (_gridVerticalController.hasClients) {
        _gridVerticalController.jumpTo(_leftVerticalController.offset);
      }
      _isSyncingVertical = false;
    });

    selectedTakvimTuru = takvimTuru.firstWhere(
            (element) => element.id == widget.isletmebilgi["randevu_takvim_turu"].toString()
    );

    getUpdatedAppointments(
        DateFormat('yyyy-MM-dd').format(seciliTarih),
        DateFormat('yyyy-MM-dd').format(seciliTarih),
        false
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
     _topHorizontalController.dispose();
    _gridHorizontalController.dispose();

     _leftVerticalController.dispose();
     _gridVerticalController.dispose();
    super.dispose();
  }
  // initState'e ekle veya getUpdatedAppointments sonrasında çağır
  void _scrollToCurrentTime() {
    // Eğer bugünün takvimi açıksa
    if (_selectedDate.year == _currentTime.year &&
        _selectedDate.month == _currentTime.month &&
        _selectedDate.day == _currentTime.day) {

      // Şu anki saati al
      final now = DateTime.now();
      final currentHour = now.hour;
      final currentMinute = now.minute;

      // Başlangıç saatini al
      final startParts = baslangicSaati.split(':');
      final startHour = int.parse(startParts[0]);
      final startMinute = int.parse(startParts[1]);
      final startTotalMinutes = startHour * 60 + startMinute;

      // Şu anki toplam dakika
      final currentTotalMinutes = currentHour * 60 + currentMinute;

      // Başlangıçtan itibaren geçen dakika
      int minutesFromStart = currentTotalMinutes - startTotalMinutes;
      if (minutesFromStart < 0) minutesFromStart = 0;

      // 15 dakikalık slot yüksekliği
      final slotHeight = _hourHeight / 4; // 30px
      final minuteHeight = _hourHeight / 60; // 2px

      // Scroll edilecek pozisyon (piksel cinsinden)
      double scrollPosition = minutesFromStart * minuteHeight;

      // Scroll yap (biraz gecikmeyle, widget build olduktan sonra)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_gridVerticalController.hasClients) {
          // Ortalamak için 3 slot yukarıdan başlat (isteğe bağlı)
          scrollPosition = scrollPosition - (slotHeight * 3);
          if (scrollPosition < 0) scrollPosition = 0;

          _gridVerticalController.jumpTo(scrollPosition);

          // Dikey scroll controller'ı da senkronize et
          _leftVerticalController.jumpTo(scrollPosition);
        }
      });
    }
  }
  // getUpdatedAppointments fonksiyonunu güncelleyin:
  Future<void> getUpdatedAppointments(
      String tarih1,
      String tarih2,
      bool yukleniyor
      ) async {
    // Önce scroll pozisyonlarını kaydet
    if (_gridVerticalController.hasClients) {
      _savedVerticalScrollPosition = _gridVerticalController.offset;
    }
    if (_gridHorizontalController.hasClients) {
      _savedHorizontalScrollPosition = _gridHorizontalController.offset;
    }

    if (widget.kullanicirolu == 5) {
      widget.kullanici.yetkili_olunan_isletmeler.forEach((element) {
        if (element["salon_id"].toString() == widget.isletmebilgi["id"].toString()) {
          setState(() {
            personelid = element["id"].toString();
          });
        }
      });
    }

    final randevudata = await fetchRandevular(
        widget.isletmebilgi["id"].toString(),
        personelid,
        tarih1,
        tarih2,
        yukleniyor,
        context,
        selectedTakvimTuru?.id ?? ""
    );

    List<dynamic> randevular = randevudata["randevular"];
    List<dynamic> personeller = randevudata["personeller"];
    List<dynamic> takvimpersoneller = randevudata["resources"];
    List<dynamic> randevulisteleri = randevudata["randevular_liste"];
    setState(() {
      baslangicSaati = randevudata["baslangic"];
      bitisSaati = randevudata["bitis"];
    });

    updatedAppointments = randevular.map<Appointment>((item) {
      return Appointment(
        startTime: DateTime.parse(item['start']),
        endTime: DateTime.parse(item['end']),
        subject: item['title'] ?? "",
        id: item['id'],
        color: Color(int.parse(item['bgcolor'].toString().replaceFirst('0x', ''), radix: 16)),
        resourceIds: [item['resourceId']],
        notes: item["notes"],
        location: item["durum"].toString(),
        recurrenceId: item["ongorusmeid"].toString(),
      );
    }).toList();

    resources = takvimpersoneller.map<CalendarResource>((item) {
      return CalendarResource(
        displayName: item['name'],
        id: item['id'],
        color: Color(int.parse(item['bgcolor'].toString().replaceFirst('0x', ''), radix: 16)),
        image: NetworkImage('https://app.randevumcepte.com.tr' + (item["avatar"] != null ? item['avatar'] : '/public/isletmeyonetim_assets/img/avatar.png')),
      );
    }).toList();

    setState(() {
      personelliste = personeller.map((json) => Personel.fromJson(json)).toList();
      randevuliste = randevulisteleri.map((json) => Randevu.fromJson(json)).toList();

      _personelDataGridSource = PersonelDataSource(
        kullanicirolu: widget.kullanicirolu,
        rowsPerPage: 10,
        salonid: widget.isletmebilgi["id"].toString(),
        context: context,
        baslik: "",
        isletmebilgi: widget.isletmebilgi,
        showYukleniyor: false,
      );
      _selectedDate = seciliTarih;
      isloading = false;
    });

    // Scroll pozisyonlarını geri yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_gridVerticalController.hasClients && _savedVerticalScrollPosition > 0) {
        _gridVerticalController.jumpTo(_savedVerticalScrollPosition);
        _leftVerticalController.jumpTo(_savedVerticalScrollPosition);
      }
      if (_gridHorizontalController.hasClients && _savedHorizontalScrollPosition > 0) {
        _gridHorizontalController.jumpTo(_savedHorizontalScrollPosition);
        _topHorizontalController.jumpTo(_savedHorizontalScrollPosition);
      }
    });

    // Eğer ilk yüklenme ise ve bugünün takvimi ise scroll to current time
    if (!yukleniyor && _savedVerticalScrollPosition == 0) {
      _scrollToCurrentTime();
    }
  }

  double saatiCevir(String saat) {
    List<String> parts = saat.split(":");
    return int.parse(parts[0]) + int.parse(parts[1]) / 60;
  }

  void _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        seciliTarih = picked;
      });
      getUpdatedAppointments(
          DateFormat('yyyy-MM-dd').format(picked),
          DateFormat('yyyy-MM-dd').format(picked),
          true
      );
    }
  }

  void _changeDateByDays(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
      seciliTarih = _selectedDate;
    });
    getUpdatedAppointments(
        DateFormat('yyyy-MM-dd').format(_selectedDate),
        DateFormat('yyyy-MM-dd').format(_selectedDate),
        true
    );
  }

  @override
  Widget build(BuildContext context) {
    double ekranGenisligi = MediaQuery.of(context).size.width;
    final String formattedDate = DateFormat('d MMMM EEEE', 'tr_TR').format(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Takvim', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        actions: [
          if (widget.isletmebilgi["demo_hesabi"].toString() == "1")
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: SizedBox(
                width: 100,
                child: YukseltButonu(isletme_bilgi: widget.isletmebilgi),
              ),
            ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AppointmentEditor(
                    kullanicirolu: widget.kullanicirolu,
                    isletmebilgi: widget.isletmebilgi,
                    tarihsaat: "",
                    personel_id: (widget.kullanicirolu == 5 ? personelid : ""),
                  ),
                ),
              ).then((value) {
                getUpdatedAppointments(
                  DateFormat('yyyy-MM-dd').format(seciliTarih),
                  DateFormat('yyyy-MM-dd').format(seciliTarih),
                  true,
                );
              });
            },
            icon: Icon(Icons.add, color: Colors.black),
            iconSize: 26,
          ),
        ],
        toolbarHeight: 60,
      ),
      body: isloading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          _buildControlBar(ekranGenisligi, formattedDate),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
              ),
              // resources.isEmpty ise mesaj göster, değilse takvimi göster
              child: resources.isEmpty
                  ? const Center(
                child: Text(
                  'Gösterilecek veri bulunmamaktadır.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
                  : _buildCustomCalendar(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlBar(double ekranGenisligi, String formattedDate) {
    return Row(
      children: [
        if (widget.kullanicirolu != 5)
          SizedBox(
            width: ekranGenisligi * 0.35,
            child: DropdownButtonHideUnderline(
              child: DropdownButton2<TakvimTuru>(
                isExpanded: true,
                hint: Text(
                  'Takvim Türü..',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).hintColor,
                  ),
                ),
                items: takvimTuru
                    .map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(
                    item.takvim_turu,
                    style: const TextStyle(fontSize: 14),
                  ),
                ))
                    .toList(),
                value: selectedTakvimTuru,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedTakvimTuru = value;
                    });
                    getUpdatedAppointments(
                      DateFormat('yyyy-MM-dd').format(seciliTarih),
                      DateFormat('yyyy-MM-dd').format(seciliTarih),
                      true,
                    );
                  }
                },
                buttonStyleData: const ButtonStyleData(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  height: 50,
                  width: 400,
                ),
                dropdownStyleData: const DropdownStyleData(maxHeight: 200),
                menuItemStyleData: const MenuItemStyleData(height: 40),
                onMenuStateChange: (isOpen) {
                  if (!isOpen) takvimTuruText.clear();
                },
              ),
            ),
          ),
        SizedBox(
          width: widget.kullanicirolu == 5 ? ekranGenisligi : ekranGenisligi * 0.65,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 0),
            color: Colors.grey.shade200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => _changeDateByDays(-1),
                ),
                GestureDetector(
                  onTap: _pickDate,
                  child: Text(
                    formattedDate,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: () => _changeDateByDays(1),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }


  // _buildCustomCalendar fonksiyonunun düzeltilmiş hali
  Widget _buildCustomCalendar() {
    return LayoutBuilder(
      key: _calendarKey,
      builder: (context, constraints) {
        final baslangicDouble = saatiCevir(baslangicSaati);
        final bitisDouble = saatiCevir(bitisSaati);
        final saatSayisi = (bitisDouble - baslangicDouble).ceil();
        final toplamYukseklik = saatSayisi * _hourHeight;

        final totalSlots = saatSayisi * 4;
        final slotHeight = _hourHeight / 4;
        if (resources.isEmpty) return const SizedBox.shrink();

        final double minPersonelWidth = 150.0;
        final double saatColumnWidth = 60.0;
        final availableWidth = constraints.maxWidth - saatColumnWidth;

        double personelGenisligi = availableWidth / resources.length;
        if (personelGenisligi < minPersonelWidth) {
          personelGenisligi = minPersonelWidth;
        }

        final totalWidth = saatColumnWidth + (personelGenisligi * resources.length);
        final bool needsHorizontalScroll = totalWidth > constraints.maxWidth;

        return Column(
          children: [
            // SABİT ÜST SATIR - Yatay scroll için HorizontalScrollView
            SizedBox(
              height: 70,
              child: Row(
                children: [
                  Container(
                    width: saatColumnWidth,
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: Colors.grey.shade400),
                        bottom: BorderSide(color: Colors.grey.shade400),
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'Saat',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Listener(
                      onPointerSignal: (signal) {
                        if (signal is PointerScrollEvent) {
                          // Yatay scroll'u yakala ve grid controller'ı hareket ettir
                          final deltaX = signal.scrollDelta.dx;
                          if (_gridHorizontalController.hasClients && deltaX != 0) {
                            _gridHorizontalController.jumpTo(
                                _gridHorizontalController.offset + deltaX
                            );
                          }
                        }
                      },
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        controller: _topHorizontalController,
                        physics: needsHorizontalScroll
                            ? const AlwaysScrollableScrollPhysics()
                            : const NeverScrollableScrollPhysics(),
                        child: SizedBox(
                          width: totalWidth - saatColumnWidth,
                          child: Row(
                            children: resources.asMap().entries.map((entry) {
                              final index = entry.key;
                              final resource = entry.value;
                              return Container(
                                width: personelGenisligi,
                                height: 70,
                                decoration: BoxDecoration(
                                  border: Border(
                                    right: BorderSide(color: Colors.grey.shade400),
                                    bottom: BorderSide(color: Colors.grey.shade400),
                                  ),
                                  color: index % 2 == 0 ? Colors.grey[50] : Colors.white,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: resource.color ?? Colors.grey.shade400,
                                          width: 2.0,
                                        ),
                                      ),
                                      child: CircleAvatar(
                                        radius: 16,
                                        backgroundImage: resource.image,
                                        backgroundColor: Colors.grey[200],
                                        child: resource.image == null
                                            ? Text(
                                          resource.displayName.isNotEmpty
                                              ? resource.displayName[0].toUpperCase()
                                              : '?',
                                          style: TextStyle(
                                            color: resource.color ?? Colors.grey[700],
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        )
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      resource.displayName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ANA ALAN
            Expanded(
              child: Row(
                children: [
                  // SAATLER - Dikey scroll için Listener
                  Container(
                    width: saatColumnWidth,
                    color: Colors.grey[50],
                    child: Listener(
                      onPointerSignal: (signal) {
                        if (signal is PointerScrollEvent) {
                          // Dikey scroll'u yakala ve grid controller'ı hareket ettir
                          final deltaY = signal.scrollDelta.dy;
                          if (_gridVerticalController.hasClients && deltaY != 0) {
                            _gridVerticalController.jumpTo(
                                _gridVerticalController.offset + deltaY
                            );
                          }
                        }
                      },
                      child: ListView.builder(
                        controller: _leftVerticalController,
                        itemCount: totalSlots,
                        itemBuilder: (context, index) {
                          final slotIndex = index;
                          final startParts = baslangicSaati.split(':');
                          final startHour = int.parse(startParts[0]);
                          final startMinute = int.parse(startParts[1]);
                          final totalMinutes = (startHour * 60 + startMinute) + (slotIndex * 15);
                          final hour = totalMinutes ~/ 60;
                          final minute = totalMinutes % 60;
                          final timeString = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

                          return Container(
                            height: _hourHeight / 4,
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Colors.grey.shade300),
                                right: BorderSide(color: Colors.grey.shade400),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(top: 2, left: 4),
                              child: Text(
                                timeString,
                                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // PERSONEL SÜTUNLARI - Ana grid
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      controller: _gridVerticalController,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        controller: _gridHorizontalController,
                        physics: needsHorizontalScroll
                            ? const AlwaysScrollableScrollPhysics()
                            : const NeverScrollableScrollPhysics(),
                        child: SizedBox(
                          width: personelGenisligi * resources.length,
                          child: Row(
                            children: resources.map((resource) {
                              return Container(
                                width: personelGenisligi,
                                height: toplamYukseklik,
                                decoration: BoxDecoration(
                                  border: Border(
                                    right: BorderSide(color: Colors.grey.shade300),
                                  ),
                                ),
                                child: Stack(
                                  clipBehavior: Clip.hardEdge,
                                  children: [
                                    ...List.generate(totalSlots + 1, (i) {
                                      return Positioned(
                                        top: i * slotHeight,
                                        left: 0,
                                        right: 0,
                                        child: Container(
                                          height: 1,
                                          color: Colors.grey.shade300,
                                        ),
                                      );
                                    }),
                                    if (_selectedDate.year == _currentTime.year &&
                                        _selectedDate.month == _currentTime.month &&
                                        _selectedDate.day == _currentTime.day)
                                      _buildTimeline(resource, baslangicDouble, saatSayisi, personelGenisligi),
                                    Positioned.fill(
                                      child: GestureDetector(
                                        onTapUp: (details) {
                                          final position = details.localPosition;
                                          final slotIndex = (position.dy / slotHeight).floor();
                                          if (slotIndex >= 0 && slotIndex < totalSlots) {
                                            final startParts = baslangicSaati.split(':');
                                            final startHour = int.parse(startParts[0]);
                                            final startMinute = int.parse(startParts[1]);
                                            final startTotalMinutes = startHour * 60 + startMinute;
                                            final selectedTotalMinutes = startTotalMinutes + (slotIndex * 15);
                                            final selectedHour = selectedTotalMinutes ~/ 60;
                                            final selectedMinute = selectedTotalMinutes % 60;
                                            final secilenTarih = DateTime(
                                              _selectedDate.year,
                                              _selectedDate.month,
                                              _selectedDate.day,
                                              selectedHour,
                                              selectedMinute,
                                            );
                                            _randevuEkle(secilenTarih, resource.id.toString());
                                          }
                                        },
                                        child: Container(color: Colors.transparent),
                                      ),
                                    ),
                                    ..._buildAppointmentsForResource(
                                      resource,
                                      saatSayisi,
                                      baslangicDouble,
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // Timeline (şimdiki saat çizgisi) oluştur
  Widget _buildTimeline(CalendarResource resource, double baslangicDouble, int saatSayisi, double personelGenisligi) {
    final now = DateTime.now();
    final currentHour = now.hour;
    final currentMinute = now.minute;

    // Başlangıç saatini al
    final startParts = baslangicSaati.split(':');
    final startHour = int.parse(startParts[0]);
    final startMinute = int.parse(startParts[1]);
    final startTotalMinutes = startHour * 60 + startMinute;

    // Şu anki toplam dakika
    final currentTotalMinutes = currentHour * 60 + currentMinute;

    // Başlangıçtan itibaren geçen dakika
    final minutesFromStart = currentTotalMinutes - startTotalMinutes;

    // Takvim saat aralığı dışında mı?
    final endParts = bitisSaati.split(':');
    final endHour = int.parse(endParts[0]);
    final endMinute = int.parse(endParts[1]);
    final endTotalMinutes = endHour * 60 + endMinute;

    if (currentTotalMinutes < startTotalMinutes || currentTotalMinutes > endTotalMinutes) {
      return const SizedBox.shrink(); // Takvim saatleri dışında gösterme
    }

    // Yükseklik hesapla (1 dakika = 2px)
    final minuteHeight = _hourHeight / 60;
    final topPosition = minutesFromStart * minuteHeight;

    // Kırmızı nokta (daire)
    final redDot = Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: Colors.red,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.5),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );

    // Çizgi (tüm personel sütunu boyunca)
    final line = Container(
      height: 2,
      color: Colors.red,
      child: Row(
        children: [
          // Sol taraftaki kırmızı nokta (saat sütununda)
          Container(
            width: 60,
            alignment: Alignment.centerRight,
            child: redDot,
          ),
          // Çizgi (personel sütunları boyunca)
          Expanded(
            child: Container(
              height: 2,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );

    return Positioned(
      top: topPosition,
      left: 0,
      right: 0,
      child: line,
    );
  }

  // Belirli bir 15 dk'lık slottaki randevuları getir - BASİT VE DOĞRU
  List<Widget> _getAppointmentsInSlot(
      CalendarResource resource,
      int slotIndex,
      double baslangicDouble, // Bu parametreyi kullanmayacağız!
      ) {
    // Bu slotun GERÇEK saatini hesapla (09:00, 09:15, 09:30 gibi)
    // Başlangıç saati 09:00 ise:
    // slot 0 = 09:00, slot 1 = 09:15, slot 2 = 09:30, slot 3 = 09:45, slot 4 = 10:00, ...

    // Başlangıç saatini parse et
    final baslangicParsed = DateFormat.Hm().parse(baslangicSaati);
    final baslangicDakika = baslangicParsed.hour * 60 + baslangicParsed.minute;

    // Bu slotun başlangıç dakikası
    final slotBaslangicDakika = baslangicDakika + (slotIndex * 15);
    final slotSaat = slotBaslangicDakika ~/ 60;
    final slotDakika = slotBaslangicDakika % 60;

    // Bu slotun bitiş dakikası
    final slotBitisDakika = slotBaslangicDakika + 15;

    print('Slot $slotIndex: ${slotSaat.toString().padLeft(2, '0')}:${slotDakika.toString().padLeft(2, '0')} - ${(slotBitisDakika ~/ 60).toString().padLeft(2, '0')}:${(slotBitisDakika % 60).toString().padLeft(2, '0')}');

    return updatedAppointments.where((app) {
      // Resource kontrolü
      if (app.resourceIds == null || !app.resourceIds!.contains(resource.id)) return false;

      // Tarih kontrolü
      if (app.startTime.year != _selectedDate.year ||
          app.startTime.month != _selectedDate.month ||
          app.startTime.day != _selectedDate.day) return false;

      // Randevunun başlangıç ve bitiş dakikaları
      final appBaslangicDakika = app.startTime.hour * 60 + app.startTime.minute;
      final appBitisDakika = app.endTime.hour * 60 + app.endTime.minute;

      // Randevu bu slotu kesiyor mu?
      return (appBaslangicDakika < slotBitisDakika) && (appBitisDakika > slotBaslangicDakika);
    }).map((appointment) {
      // Randevunun başlangıç ve bitiş dakikaları
      final appBaslangicDakika = appointment.startTime.toLocal().hour * 60 + appointment.startTime.toLocal().minute;
      final appBitisDakika = appointment.endTime.hour * 60 + appointment.endTime.minute;

      // Bu slotun başlangıç dakikası
      final slotBaslangicDakika = baslangicDakika + (slotIndex * 15);

      // Randevunun bu slot içindeki başlangıç pozisyonu (0-15px)
      double topOffset = 0;
      if (appBaslangicDakika > slotBaslangicDakika) {
        topOffset = ((appBaslangicDakika - slotBaslangicDakika) / 15) * _quarterHeight;
      }

      // Randevunun bu slot içindeki yüksekliği
      double height = _quarterHeight - topOffset;

      // Randevu slot bitmeden bitiyorsa
      if (appBitisDakika < slotBaslangicDakika + 15) {
        height = ((appBitisDakika - slotBaslangicDakika) / 15) * _quarterHeight - topOffset;
      }

      // Çok küçük dilimleri gösterme
      if (height <= 2) return const SizedBox.shrink();

      // Aynı slottaki diğer randevular
      final ayniSlotRandevular = updatedAppointments.where((a) {
        if (a.resourceIds == null || !a.resourceIds!.contains(resource.id)) return false;
        if (a.startTime.year != _selectedDate.year ||
            a.startTime.month != _selectedDate.month ||
            a.startTime.day != _selectedDate.day) return false;

        final aBaslangicDakika = a.startTime.hour * 60 + a.startTime.minute;
        final aBitisDakika = a.endTime.hour * 60 + a.endTime.minute;

        return (aBaslangicDakika < slotBaslangicDakika + 15) && (aBitisDakika > slotBaslangicDakika);
      }).toList();

      final int index = ayniSlotRandevular.indexOf(appointment);
      final int toplamSayi = ayniSlotRandevular.length;

      // Genişlik hesapla
      double left = 0;
      double right = 0;

      if (toplamSayi > 1) {
        final double slotGenislik = (196.0 / toplamSayi).floorToDouble();
        left = index * slotGenislik;
        right = 196.0 - (left + slotGenislik);
      }

      return Positioned(
        top: topOffset,
        left: left,
        right: right,
        height: height,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: appointment.color.withOpacity(0.9),
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: appointment.color, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(1.0),
            child: Text(
              appointment.subject,
              style: const TextStyle(color: Colors.white, fontSize: 8),
              maxLines: 1,
              overflow: TextOverflow.visible,
            ),
          ),
        ),
      );
    }).toList();
  }



  // ÇOK BASİT YAKLAŞIM - Randevuları doğrudan saatlerine göre yerleştir

  // SÜRÜKLE-BIRAK ÖZELLİKLİ RANDEVULAR - DÜZELTİLMİŞ

  List<Widget> _buildAppointmentsForResource(
      CalendarResource resource,
      int saatSayisi,
      double baslangicDouble,
      ) {
    List<Widget> appointments = [];

    // 🔥 STRING "08:00" → DATETIME ÇEVİR
    final parts = baslangicSaati.split(':');

    final dayStart = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );

    // 1 dakika = kaç pixel
    final minuteHeight = _hourHeight / 60;

    for (var appointment in updatedAppointments) {
      // Resource kontrolü
      if (appointment.resourceIds == null ||
          !appointment.resourceIds!.contains(resource.id)) continue;

      // Tarih kontrolü
      if (appointment.startTime.toLocal().year != _selectedDate.year ||
          appointment.startTime.toLocal().month != _selectedDate.month ||
          appointment.startTime.toLocal().day != _selectedDate.day) continue;

      // 🔥 DOĞRU ZAMAN HESABI (DateTime farkı)
      final startDiff = appointment.startTime.toLocal().difference(dayStart).inMinutes;
      final endDiff = appointment.endTime.toLocal().difference(dayStart).inMinutes;

      double startOffset = startDiff * minuteHeight;
      double height = (endDiff - startDiff) * minuteHeight;

      // Sınırları kontrol et
      if (startOffset < 0) {
        height += startOffset;
        startOffset = 0;
      }

      if (startOffset + height > saatSayisi * _hourHeight) {
        height = (saatSayisi * _hourHeight) - startOffset;
      }

      if (height <= 0) continue;

      // Minimum yükseklik
      height = height.floorToDouble();
      log('randevu ' + appointment.location.toString());

      // 🔥 OVERLAP HESABI
      final sameHourAppointments = updatedAppointments.where((a) {
        if (a.resourceIds == null ||
            !a.resourceIds!.contains(resource.id)) return false;

        if (a.startTime.year != _selectedDate.year ||
            a.startTime.month != _selectedDate.month ||
            a.startTime.day != _selectedDate.day) return false;

        final aStart = a.startTime.difference(dayStart).inMinutes;
        final aEnd = a.endTime.difference(dayStart).inMinutes;

        return (aStart < endDiff) && (aEnd > startDiff);
      }).toList();

      int index = sameHourAppointments.indexOf(appointment);
      int total = sameHourAppointments.length;

      // 🔥 HARD CODE FIX
      double containerWidth = 150.0; // personelGenisligi ile aynı olmalı
      double left = 2;
      double right = 2;

      if (total > 1) {
        double slotGenislik = (containerWidth - 4) / total;
        left = 2 + (index * slotGenislik);
        right = 2 + ((total - 1 - index) * slotGenislik);
      }

      // Renk
      Color appointmentColor = appointment.color;

      appointments.add(
        Positioned(
          top: startOffset,
          left: left,
          right: right,
          height: height,
          child: Draggable<Appointment>(
            data: appointment,
            feedback: _buildDraggingFeedback(
              appointment,
              appointmentColor,
              height,
              containerWidth - left - right,
            ),
            childWhenDragging: const SizedBox.shrink(),
            onDragEnd: (details) {
              _onDragCompleted(details, appointment, resource.id.toString());
            },
            child: GestureDetector(
              onTap: () => _appointmentDetayGoster(appointment),
              child: Container(
                decoration: BoxDecoration(
                  color: appointmentColor.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: appointmentColor, width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Text(
                    DateFormat.Hm().format(appointment.startTime.toLocal()) +
                        '-' +
                        DateFormat.Hm().format(appointment.endTime.toLocal()) +
                        " " +
                        appointment.subject,
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                    maxLines: height <= 40 ? 2:null,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return appointments;
  }
  // Randevu içeriğini oluşturan yardımcı metod
  Widget _buildAppointmentContent(
      Appointment appointment,
      Color color,
      double height,
      double width,
      ) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              DateFormat.Hm().format(appointment.startTime.toLocal()) +
                  '-' +
                  DateFormat.Hm().format(appointment.endTime.toLocal()) +
                  " " +
                  appointment.subject,
              maxLines: height <= 40 ? 2 : null,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }
// Sürükleme bittiğinde çalışacak fonksiyon
  void _onDragEnd(DraggableDetails details, Appointment appointment, String oldResourceId) {
    if (details.wasAccepted) return; // Zaten kabul edildiyse işlem yapma

    final renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.offset);

    // Hangi personel sütununa bırakıldığını bul
    final double personelGenisligi = 200.0;
    int newResourceIndex = (localPosition.dx / personelGenisligi).floor();

    // Geçerli aralıkta mı kontrol et
    if (newResourceIndex < 0 || newResourceIndex >= resources.length) return;

    final newResource = resources[newResourceIndex];

    // Hangi dakikaya bırakıldığını hesapla
    final parts = baslangicSaati.split(':');
    final dayStart = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );

    final minuteHeight = _hourHeight / 60;
    final minutesFromStart = (localPosition.dy / minuteHeight).round();

    final newStartTime = dayStart.add(Duration(minutes: minutesFromStart));
    final duration = appointment.endTime.difference(appointment.startTime.toLocal());
    final newEndTime = newStartTime.add(duration);

    // Randevuyu güncelle
    _surukleBirakTamamla(appointment, newStartTime, newEndTime, newResource.id.toString());
  }


  // _onDragCompleted metodunu TAMAMEN DEĞİŞTİR
  void _onDragCompleted(DraggableDetails details, Appointment appointment, String oldResourceId) {
    if (details.offset == Offset.zero) return;

    final RenderBox? renderBox = _calendarKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final localPosition = renderBox.globalToLocal(details.offset);

    // Scroll pozisyonunu al
    final scrollX = _gridHorizontalController.hasClients ? _gridHorizontalController.offset : 0.0;

    // Personel sütunu bul (scroll pozisyonunu da hesaba kat)
    const double personelWidth = 150.0;
    const double saatColumnWidth = 60.0;

    // Gerçek X pozisyonu (scroll + local)
    final realX = scrollX + localPosition.dx;

    // Hangi personel sütununa denk geldiğini bul
    int personelIndex = ((realX - saatColumnWidth) / personelWidth).floor();

    if (personelIndex < 0 || personelIndex >= resources.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Geçersiz personel!"), backgroundColor: Colors.red),
      );
      return;
    }

    // Scroll pozisyonunu al (Y ekseni için)
    final scrollY = _gridVerticalController.hasClients ? _gridVerticalController.offset : 0.0;
    final headerHeight = 70.0;

    // Gerçek Y pozisyonu (scroll + local - header)
    final realY = scrollY + localPosition.dy - headerHeight;

    // Başlangıç saati bilgileri
    final startParts = baslangicSaati.split(':');
    final startHour = int.parse(startParts[0]);
    final startMinute = int.parse(startParts[1]);
    final startTotalMinutes = startHour * 60 + startMinute;

    // Bitiş saati bilgileri
    final endParts = bitisSaati.split(':');
    final endHour = int.parse(endParts[0]);
    final endMinute = int.parse(endParts[1]);
    final endTotalMinutes = endHour * 60 + endMinute;

    // 15 dakikalık slot yüksekliği (120px / 4 = 30px)
    final slotHeight = _hourHeight / 4; // 30.0

    // Kaçıncı slot?
    int slotIndex = (realY / slotHeight).floor();

    // Slot sınırlarını kontrol et
    final totalSlots = ((endTotalMinutes - startTotalMinutes) / 15).ceil();
    if (slotIndex < 0) slotIndex = 0;
    if (slotIndex >= totalSlots) slotIndex = totalSlots - 1;

    // Saat hesapla
    int newTotalMinutes = startTotalMinutes + (slotIndex * 15);
    int newHour = newTotalMinutes ~/ 60;
    int newMinute = newTotalMinutes % 60;

    DateTime newStartTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      newHour,
      newMinute,
    );

    final duration = appointment.endTime.difference(appointment.startTime.toLocal());
    DateTime newEndTime = newStartTime.add(duration);

    // Eski saat bilgilerini al
    final oldStartTime = appointment.startTime.toLocal();
    final oldEndTime = appointment.endTime.toLocal();

    // Eski personeli bul
    final oldResourceIdValue = appointment.resourceIds?.first.toString();
    final oldPersonel = resources.firstWhere(
          (r) => r.id.toString() == oldResourceIdValue,
      orElse: () => CalendarResource(
        displayName: 'Bilinmiyor',
        id: '0',
        color: Colors.grey,
        image: const NetworkImage(''),
      ),
    );

    final newPersonel = resources[personelIndex];

    // AYNI SLOT KONTROLÜ
    final isSamePersonel = oldPersonel.id.toString() == newPersonel.id.toString();
    final isSameTime = oldStartTime.hour == newStartTime.hour &&
        oldStartTime.minute == newStartTime.minute;

    // Eğer aynı personel ve aynı saat ise hiçbir işlem yapma
    if (isSamePersonel && isSameTime) {
      return;
    }

    // Onay dialog'u göster
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Randevu Taşıma Onayı',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Randevuyu aşağıdaki bilgilerle güncellemek istediğinize emin misiniz?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📅 Randevu Detayları',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('👤 Müşteri: ${appointment.subject.split('\n')[0]}'),
                  const SizedBox(height: 4),
                  Text('✂️ Hizmet: ${appointment.subject.split('\n')[1]}'),
                  const SizedBox(height: 4),
                  Text('⏰ Eski Tarih/Saat: ${DateFormat('dd MMMM yyyy', 'tr_TR').format(oldStartTime)} ${DateFormat.Hm().format(oldStartTime)} - ${DateFormat.Hm().format(oldEndTime)}'),
                  const SizedBox(height: 4),
                  Text('👨‍💼 Eski Personel: ${oldPersonel.displayName}'),
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text('⏰ Yeni Tarih/Saat: ${DateFormat('dd MMMM yyyy', 'tr_TR').format(newStartTime)} ${DateFormat.Hm().format(newStartTime)} - ${DateFormat.Hm().format(newEndTime)}'),
                  const SizedBox(height: 4),
                  Text('👨‍💼 Yeni Personel: ${newPersonel.displayName}'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _surukleBirakTamamla(appointment, newStartTime, newEndTime, resources[personelIndex].id.toString());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Güncelle'),
          ),
        ],
      ),
    );
  }
// Randevu güncelleme fonksiyonu
  Future<void> _surukleBirakTamamla(
      Appointment oldAppointment,
      DateTime newStartTime,
      DateTime newEndTime,
      String newResourceId,
      ) async {
    // API'ye güncelleme isteği gönder
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Randevu güncelleme API çağrısı
      List<String>? randevudurum = oldAppointment.location?.split('-');
      String randevuHizmetId = '';
      if(randevudurum != null && randevudurum.isNotEmpty)
        randevuHizmetId = randevudurum[4];
      final response = await http.post(
        Uri.parse('https://app.randevumcepte.com.tr/api/v1/surukleBirakRandevuGuncelle'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'randevuHizmetId':randevuHizmetId,
          'randevu_id': oldAppointment.id.toString(),
          'baslangic': newStartTime.toIso8601String(),
          'bitis': newEndTime.toIso8601String(),
          'resourceId': newResourceId,
          'takvimTuru': selectedTakvimTuru?.id.toString()
        }),
      );

      Navigator.pop(context); // Progress dialog'u kapat

      if (response.statusCode == 200) {


        // Takvimi yenile
        getUpdatedAppointments(
          DateFormat('yyyy-MM-dd').format(_selectedDate),
          DateFormat('yyyy-MM-dd').format(_selectedDate),
          true,
        );
      }
      else {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
            content: Text("Randevu güncellenirken bir hata oluştu. Hata kodu : "+response.statusCode.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Güncelleme hatası: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

// Sürükleme sırasında gösterilecek widget
  //   BOYUTU SABİT
  //  İYİLEŞTİRİLMİŞ
  Widget _buildDraggingFeedback(Appointment appointment, Color color, double height, double width) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color.withOpacity(0.8),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(2.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                DateFormat.Hm().format(appointment.startTime.toLocal()) +
                    "-" +
                    DateFormat.Hm().format(appointment.endTime.toLocal()) +
                    " " +
                    appointment.subject,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,

                ),
                maxLines: height<=40 ? 2 : null,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
  void _randevuEkle(DateTime tarih, String resourceId) {
    final now = DateTime.now();
    /*if (tarih.isBefore(now)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Geçmiş tarih / saat için randevu oluşturulamaz!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }*/

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AppointmentEditor(
          kullanicirolu: widget.kullanicirolu,
          isletmebilgi: widget.isletmebilgi,
          tarihsaat: tarih.toString(),
          personel_id: resourceId,
        ),
      ),
    ).then((_) {
      getUpdatedAppointments(
        DateFormat('yyyy-MM-dd').format(seciliTarih),
        DateFormat('yyyy-MM-dd').format(seciliTarih),
        true,
      );
    });
  }

  void _appointmentDetayGoster(Appointment appointment) {
    RandevuDetayGoster(context, appointment);
  }

  void RandevuDetayGoster(BuildContext context, Appointment randevudetay) {
    final _formKey = GlobalKey<FormState>();
    List<String> randevutitle = randevudetay.subject.split('\n');
    List<String>? randevudurum = randevudetay.location?.split('-');
    log('randevu durum '+randevudurum![0]);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          insetPadding: EdgeInsets.zero,

          content: Container(

            width: 280,
            child: SingleChildScrollView(
              child: Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  Positioned(
                    right: -40,
                    top: -40,
                    child: InkResponse(
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                      child: const CircleAvatar(
                        backgroundColor: Colors.red,
                        child: Icon(Icons.close),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        randevudurum![3]=='1' ?
                        Container(
                          padding: EdgeInsets.all(12),
                          margin: EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.orange[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info, color: Colors.orange),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Bu randevunuzun tahsilatını daha önce gerçekleştirdiniz.',
                                  style: TextStyle(color: Colors.orange[800]),
                                ),
                              ),
                            ],
                          ),
                        )
                            : SizedBox(),

                        SizedBox(height: 20,),
                        Text(
                          randevutitle[0] + " Randevu Detayları",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Divider(color: Colors.black, height: 10,),
                        Row(
                          children: [

                            Expanded(child: Text(randevudetay.notes ?? ""))
                          ],
                        ),

                        randevudurum![0] == "0" || randevudurum![0] == "1" ? Divider(color: Colors.black,
                          height: 30,): SizedBox.shrink(),
                        randevudurum![0] == "0" || randevudurum![0] == "1" ? Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(onPressed: () {
                                Navigator.of(context,rootNavigator: true).pop();


                                Navigator.push(context, new MaterialPageRoute(builder: (context) => RandevuDuzenle(isletmebilgi: widget.isletmebilgi, randevu: randevuliste.firstWhere((element) => element.id.toString()==randevudetay.id.toString()),))).then((value) {
                                  getUpdatedAppointments(DateFormat('yyyy-MM-dd').format(seciliTarih), DateFormat('yyyy-MM-dd').format(seciliTarih),true);

                                });

                              }, child:
                              Text('Düzenle'),
                                style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor:  Color(0xFF5E35B1),

                                    elevation: 5,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(5.0)
                                    ),
                                    minimumSize: Size(0, 30)
                                ),
                              ),
                            )
                          ],
                        ) : SizedBox.shrink(),
                        (randevudurum![0] == "0" || randevudurum![0] == "1") && widget.kullanicirolu != 5 ? Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          alignment: WrapAlignment.start,
                          children: [
                            if (randevudurum![0] == "0")
                              ElevatedButton(onPressed: () {
                                randevuonayla(randevudetay.id.toString(), context);
                                Navigator.of(context).pop();
                                getUpdatedAppointments(DateFormat('yyyy-MM-dd').format(seciliTarih), DateFormat('yyyy-MM-dd').format(seciliTarih),false);
                              }, child:
                              Text('Onayla'),
                                style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: Colors.green,
                                    elevation: 5,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(5.0)
                                    ),
                                    minimumSize: Size(130, 30)
                                ),
                              ),
                            if (randevudurum![0] == '0')
                              ElevatedButton(onPressed: () {
                                showDialog<bool>(
                                  context: context,
                                  builder: (dialogContex) {
                                    return AlertDialog(
                                      title: Text('EMİN MİSİNİZ?'),
                                      content: Text("Randevu iptal etme işlemi geri alınamaz?"),
                                      actions: <Widget>[
                                        TextButton(
                                          child: Text('VAZGEÇ'),
                                          onPressed: () {
                                            Navigator.of(dialogContex).pop();
                                          },
                                        ),
                                        TextButton(
                                          child: Text('İPTAL ET'),
                                          onPressed: () async {
                                            SharedPreferences prefs = await SharedPreferences.getInstance();
                                            var usertype = prefs.getString('user_type');
                                            await randevuiptalet(randevudetay.id.toString(), context,usertype.toString());
                                            Navigator.of(dialogContex).pop();
                                            getUpdatedAppointments(DateFormat('yyyy-MM-dd').format(seciliTarih), DateFormat('yyyy-MM-dd').format(seciliTarih),false);
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                                child:
                                Text('İptal Et'),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    foregroundColor: Colors.white,
                                    elevation: 5,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(5.0)
                                    ),
                                    minimumSize: Size(130, 30)
                                ),
                              ),
                            if (randevudurum![0] != "0" && randevudurum[1] != "0")
                              ElevatedButton(onPressed: () async{
                                await randevugelmediisaretle(randevudetay.id.toString(), context);
                                Navigator.of(context).pop();
                                getUpdatedAppointments(DateFormat('yyyy-MM-dd').format(seciliTarih), DateFormat('yyyy-MM-dd').format(seciliTarih),false);
                              }, child:
                              Text('Gelmedi'),
                                style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: Colors.red[600],
                                    elevation: 5,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(5.0)
                                    ),
                                    minimumSize: Size(130, 30)
                                ),
                              ),
                            if (randevudurum![0] != "0" && randevudurum[1] == "0")
                              ElevatedButton(onPressed: () async{
                                await randevuGeldiGelmediIsaretiKaldir(randevudetay.id.toString(), context);
                                Navigator.of(context).pop();
                                getUpdatedAppointments(DateFormat('yyyy-MM-dd').format(seciliTarih), DateFormat('yyyy-MM-dd').format(seciliTarih),false);
                              }, child:
                              Text('Gelmedi İşaretini\nKaldır',style:TextStyle(fontSize: 10)),
                                style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: Colors.red[600],
                                    elevation: 5,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(5.0)
                                    ),
                                    minimumSize: Size(130, 30)
                                ),
                              ),
                            if (randevudurum![0] != "0" && randevudurum[1] != "1")
                              ElevatedButton(onPressed: () async {
                                await randevuGeldiGelmediIsaretiKaldir(randevudetay.id.toString() , context);
                                Navigator.of(context).pop();
                                getUpdatedAppointments(DateFormat('yyyy-MM-dd').format(seciliTarih), DateFormat('yyyy-MM-dd').format(seciliTarih),false);
                              }, child:
                              Text('Geldi'),
                                style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: Colors.green,
                                    elevation: 5,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(5.0)
                                    ),
                                    minimumSize: Size(130, 30)
                                ),
                              ),
                            if (randevudurum![0] != "0" && randevudurum[1] == "1")
                              ElevatedButton(onPressed: () async {
                                await randevuGeldiGelmediIsaretiKaldir(randevudetay.id.toString() , context );
                                Navigator.of(context).pop();
                                getUpdatedAppointments(DateFormat('yyyy-MM-dd').format(seciliTarih), DateFormat('yyyy-MM-dd').format(seciliTarih),false);
                              },
                                child: Text('Geldi İşaretini\nKaldır',style: TextStyle(fontSize: 10),),
                                style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: Colors.green,
                                    elevation: 5,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(5.0)
                                    ),
                                    minimumSize: Size(130, 30)
                                ),
                              ),
                          ],
                        ):SizedBox.shrink(),

                        (randevudurum![0] == "0" || randevudurum![0] == "1" ) && widget.kullanicirolu != 5 && randevudurum![3] != '1' && !randevutitle[0].contains("ÖN GÖRÜŞME")   ? Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          alignment: WrapAlignment.start,
                          children: [
                            if (randevudurum![0] != "0" && !randevutitle[0].contains("PAKET") && widget.kullanicirolu!=5)
                              ElevatedButton(onPressed: () async{
                                if(randevudurum![2]!='1')
                                  await randevudantahsilatagit(context,randevudetay.id.toString());

                                Navigator.of(context).pop();
                                Navigator.push(context, new MaterialPageRoute(builder: (context) => TahsilatEkrani(adisyonId: "", kullanicirolu: widget.kullanicirolu, isletmebilgi: widget.isletmebilgi, musteridanisanid: randevuliste.firstWhere((element) => element.id==randevudetay.id.toString()).user_id.toString()))).then((value) {
                                  log('refresh yapıcak ');
                                  getUpdatedAppointments(DateFormat('yyyy-MM-dd').format(seciliTarih), DateFormat('yyyy-MM-dd').format(seciliTarih),false);
                                });
                              }, child:
                              Text('Tahsilat'),
                                style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: Color(0xFF5E35B1),
                                    elevation: 5,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(5.0)
                                    ),
                                    minimumSize: Size(130, 30)
                                ),
                              ),
                            if (randevudurum![0] != '0')
                              ElevatedButton(onPressed: () {
                                showDialog<bool>(
                                  context: context,
                                  builder: (dialogContex) {
                                    return AlertDialog(
                                      title: Text('EMİN MİSİNİZ?'),
                                      content: Text("Randevu iptal etme işlemi geri alınamaz?"),
                                      actions: <Widget>[
                                        TextButton(
                                          child: Text('VAZGEÇ'),
                                          onPressed: () {
                                            Navigator.of(dialogContex).pop();
                                          },
                                        ),
                                        TextButton(
                                          child: Text('İPTAL ET'),
                                          onPressed: () async {
                                            SharedPreferences prefs = await SharedPreferences.getInstance();
                                            var usertype = prefs.getString('user_type');
                                            await randevuiptalet(randevudetay.id.toString(), context,usertype.toString());
                                            Navigator.of(dialogContex).pop();
                                            getUpdatedAppointments(DateFormat('yyyy-MM-dd').format(seciliTarih), DateFormat('yyyy-MM-dd').format(seciliTarih),false);
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                                child:
                                Text('İptal Et'),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    foregroundColor: Colors.white,
                                    elevation: 5,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(5.0)
                                    ),
                                    minimumSize: Size(130, 30)
                                ),
                              ),
                          ],
                        ) : SizedBox.shrink(),
                        (randevudurum![0] == "0" || randevudurum![0] == "1") && randevutitle[0].contains("ÖN GÖRÜŞME") && (randevudetay.notes ?? "").contains("Beklemede")  ? Row(
                          children: [

                            ElevatedButton(onPressed: () async{
                              OnGorusme selectedItem = await ongorsumebilgi(randevudetay.recurrenceId.toString());
                              if (selectedItem.paket_id != null && selectedItem.paket_id != "null") {
                                paketsatispopup(context, randevudetay.recurrenceId.toString());
                              } else if (selectedItem.urun_id != null && selectedItem.urun_id != "null") {
                                urunsatispopup(context, randevudetay.recurrenceId.toString());
                              }

                            }, child:
                            Text('Satış Yapıldı'),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  elevation: 5,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5.0)
                                  ),
                                  minimumSize: Size(130, 30)
                              ),
                            )
                            ,
                            SizedBox(width: 15,),

                            ElevatedButton(onPressed: () {

                              showSatisYapilmamaNedeniDialog(context, randevudetay.recurrenceId.toString(),"1","",(value)=>getUpdatedAppointments(DateFormat('yyyy-MM-dd').format(seciliTarih), DateFormat('yyyy-MM-dd').format(seciliTarih),false));

                              ;

                              // close the confirmation dialog



                              //satisyapilmadi(context,  "",String aciklama,String currentPage,String aramaterimi,bool showprogress)
                            }, child:
                            Text('Satış Yapılmadı'),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red[600],
                                  elevation: 5,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5.0)
                                  ),
                                  minimumSize: Size(130, 30)
                              ),
                            )

                          ],
                        ) : SizedBox.shrink(),

                      ],
                    ),
                  ),
                ],
              ),
            ),

          ),
        );
      },
    );
  }

  void paketsatispopup(BuildContext context, String ongorusmeid) {
    TextEditingController ongorusmetarihi = TextEditingController();
    TextEditingController seansaralik = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          scrollable: true,
          title: const Text(
            'Paket satışına devam etmek için lütfen aşağıdan başlangıç tarihi seçip seans gün aralığını belirleyin!',
            style: TextStyle(fontSize: 14),
          ),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 0.0),
                child: Text(
                  'Seans Başlangıç Tarihi',
                  style: TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                height: 40,
                padding: const EdgeInsets.only(left: 0, right: 20),
                child: TextFormField(
                  controller: ongorusmetarihi,
                  decoration: InputDecoration(
                    focusColor: const Color(0xFF6A1B9A),
                    hoverColor: const Color(0xFF6A1B9A),
                    hintStyle: const TextStyle(color: Color(0xFF6A1B9A)),
                    contentPadding: const EdgeInsets.all(15.0),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF6A1B9A)),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF6A1B9A)),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
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
                      ongorusmetarihi.text = formattedDate;
                    }
                  },
                ),
              ),
              const SizedBox(height: 10),
              const Padding(
                padding: EdgeInsets.only(left: 0.0),
                child: Text(
                  'Seans Aralığı (Gün)',
                  style: TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                height: 40,
                padding: const EdgeInsets.only(left: 0, right: 20),
                child: TextField(
                  controller: seansaralik,
                  keyboardType: TextInputType.number,
                  maxLines: 1,
                  decoration: InputDecoration(
                    focusColor: const Color(0xFF6A1B9A),
                    hoverColor: const Color(0xFF6A1B9A),
                    hintStyle: const TextStyle(color: Color(0xFF6A1B9A)),
                    contentPadding: const EdgeInsets.all(15.0),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF6A1B9A)),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF6A1B9A)),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Kapat', style: TextStyle(color: Colors.black)),
            ),
            TextButton(
              onPressed: () {
                satisyapildi(context, ongorusmeid, '', ongorusmetarihi.text, seansaralik.text);
                getUpdatedAppointments(
                    DateFormat('yyyy-MM-dd').format(seciliTarih),
                    DateFormat('yyyy-MM-dd').format(seciliTarih),
                    false
                );
              },
              child: const Text('Kaydet', style: TextStyle(color: Colors.purple)),
            ),
          ],
        );
      },
    );
  }

  void urunsatispopup(BuildContext context, String ongorusmeid) {
    TextEditingController quantityController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          scrollable: true,
          title: const Text(
              'Ürün satışına devam etmek için lütfen ürün adedini belirleyiniz!',
              style: TextStyle(fontSize: 16)
          ),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 0.0),
                child: Text(
                  'Adet',
                  style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                height: 50,
                child: TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  maxLines: 1,
                  decoration: InputDecoration(
                    focusColor: const Color(0xFF6A1B9A),
                    hoverColor: const Color(0xFF6A1B9A),
                    hintStyle: const TextStyle(color: Color(0xFF6A1B9A)),
                    contentPadding: const EdgeInsets.all(15.0),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF6A1B9A)),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF6A1B9A)),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Kapat', style: TextStyle(color: Colors.black)),
            ),
            TextButton(
              onPressed: () {
                satisyapildi(context, ongorusmeid, quantityController.text, '', '');
                getUpdatedAppointments(
                    DateFormat('yyyy-MM-dd').format(seciliTarih),
                    DateFormat('yyyy-MM-dd').format(seciliTarih),
                    false
                );
              },
              child: const Text('Kaydet', style: TextStyle(color: Colors.purple)),
            ),
          ],
        );
      },
    );
  }
}
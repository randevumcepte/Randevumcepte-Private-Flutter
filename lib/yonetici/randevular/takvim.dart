import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:ui' as ui;
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
import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Frontend/indexedstack.dart';
import 'package:randevu_sistem/Frontend/popupdialogs.dart';
import 'package:randevu_sistem/Frontend/sfdatatable.dart';
import 'package:randevu_sistem/Models/ongorusmeler.dart';
import 'package:randevu_sistem/Models/personel.dart';
import 'package:randevu_sistem/Models/user.dart';
import 'package:randevu_sistem/yukselt.dart';
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
    TakvimTuru(id: '1', takvim_turu: 'Personele'),
    TakvimTuru(id: '0', takvim_turu: 'Hizmete'),
    TakvimTuru(id: '2', takvim_turu: 'Cihaza'),
    TakvimTuru(id: '3', takvim_turu: 'Odaya'),
  ];

  List<Appointment> updatedAppointments = [];
  List<CalendarResource> resources = [];

  ScrollController _topHorizontalController = ScrollController();
  ScrollController _gridHorizontalController = ScrollController();

  ScrollController _leftVerticalController = ScrollController();
  ScrollController _gridVerticalController = ScrollController();
  final double _hourHeight = 120.0;
  final double _quarterHeight = 15.0; // 15 dakika = 15px (60/4)
  double _personelGenisligi = 150.0; // _buildCustomCalendar içinde güncellenir
  bool _isSyncingHorizontal = false;
  bool _isSyncingVertical = false;
  bool _firstLoad = true; // İlk yüklemede scroll'u doğru offset'ten başlatmak için

  // Aktif gap kampanyalari — takvim ustunde serit olarak gosterilir
  List<Map<String, dynamic>> _gapKampanyaListesi = [];

  @override

  void initState() {
    super.initState();
    _selectedDate = DateTime.now();

    _bindHorizontalSyncListeners();
    _bindVerticalSyncListeners();

    _timer = Timer.periodic(Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });

    selectedTakvimTuru = takvimTuru.firstWhere(
            (element) => element.id == widget.isletmebilgi["randevu_takvim_turu"].toString()
    );

    getUpdatedAppointments(
        DateFormat('yyyy-MM-dd').format(seciliTarih),
        DateFormat('yyyy-MM-dd').format(seciliTarih),
        false
    );

    _loadGapKampanyalari();
  }

  Future<void> _loadGapKampanyalari() async {
    final salonId = widget.isletmebilgi["id"].toString();
    final res = await aktifGapKampanyalari(salonId);
    if (!mounted) return;
    final list = (res?['kampanyalar'] as List?) ?? [];
    setState(() {
      _gapKampanyaListesi = list
          .cast<Map>()
          .map((m) => m.cast<String, dynamic>())
          .toList();
    });
  }

  Widget _buildGapKampanyaSeridi() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        border: Border(
          bottom: BorderSide(
              color: const Color(0xFFFBBF24).withValues(alpha: 0.35), width: 1),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          const Icon(Icons.local_offer_rounded,
              size: 14, color: Color(0xFFB45309)),
          const SizedBox(width: 6),
          const Text(
            'Aktif Kampanya:',
            style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFFB45309)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (int i = 0; i < _gapKampanyaListesi.length; i++) ...[
                    _buildGapChip(_gapKampanyaListesi[i]),
                    if (i < _gapKampanyaListesi.length - 1)
                      const SizedBox(width: 6),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGapChip(Map<String, dynamic> k) {
    final gapKey = k['gapKey'] as String? ?? 'morning';
    final start = (k['startHour'] as num?)?.toInt() ?? 0;
    final end = (k['endHour'] as num?)?.toInt() ?? 0;
    final disc = (k['discount'] as num?)?.toInt() ?? 0;

    final List<Color> grad;
    final IconData icon;
    switch (gapKey) {
      case 'morning':
        grad = const [Color(0xFFFDE68A), Color(0xFFFCD34D)];
        icon = Icons.wb_twilight_rounded;
        break;
      case 'afternoon':
        grad = const [Color(0xFFFED7AA), Color(0xFFFB923C)];
        icon = Icons.wb_sunny_rounded;
        break;
      case 'evening':
      default:
        grad = const [Color(0xFFDDD6FE), Color(0xFF8B5CF6)];
        icon = Icons.nightlight_round;
        break;
    }

    return InkWell(
      onTap: () => _showGapKampanyaDetay(k),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
              color: grad.last.withValues(alpha: 0.55), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: grad),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Icon(icon, size: 11, color: Colors.white),
            ),
            const SizedBox(width: 6),
            Text(
              '${start.toString().padLeft(2, '0')}-${end.toString().padLeft(2, '0')}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                ),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '%$disc',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGapKampanyaDetay(Map<String, dynamic> k) {
    final label = k['gapLabel'] as String? ?? 'Saatler';
    final start = (k['startHour'] as num?)?.toInt() ?? 0;
    final end = (k['endHour'] as num?)?.toInt() ?? 0;
    final disc = (k['discount'] as num?)?.toInt() ?? 0;
    final kalanGun = (k['kalanGun'] as num?)?.toInt() ?? 0;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.local_offer_rounded,
                        size: 18, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '$label Kampanyası',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _detayRow(Icons.schedule_rounded, 'Saat',
                  '${start.toString().padLeft(2, '0')}:00 – ${end.toString().padLeft(2, '0')}:00'),
              const SizedBox(height: 8),
              _detayRow(Icons.local_offer_rounded, 'İndirim', '%$disc',
                  valueColor: const Color(0xFF16A34A)),
              const SizedBox(height: 8),
              _detayRow(
                  Icons.timer_outlined,
                  'Kalan süre',
                  kalanGun > 0 ? '$kalanGun gün' : 'Bugün son gün',
                  valueColor: const Color(0xFF15803D)),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Bu saat aralığındaki müşteriler tahsilat sırasında otomatik %$disc indirim almaya hak kazanır.',
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: Color(0xFF1A1A1A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6A1B9A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11)),
                  ),
                  child: const Text('Tamam',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detayRow(IconData icon, String label, String value,
      {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 15, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: valueColor ?? Colors.black,
          ),
        ),
      ],
    );
  }

  void _bindHorizontalSyncListeners() {
    _gridHorizontalController.addListener(() {
      if (_isSyncingHorizontal) return;
      _isSyncingHorizontal = true;
      if (_topHorizontalController.hasClients) {
        _topHorizontalController.jumpTo(_gridHorizontalController.offset);
      }
      _isSyncingHorizontal = false;
    });
    _topHorizontalController.addListener(() {
      if (_isSyncingHorizontal) return;
      _isSyncingHorizontal = true;
      if (_gridHorizontalController.hasClients) {
        _gridHorizontalController.jumpTo(_topHorizontalController.offset);
      }
      _isSyncingHorizontal = false;
    });
  }

  void _bindVerticalSyncListeners() {
    _gridVerticalController.addListener(() {
      if (_isSyncingVertical) return;
      _isSyncingVertical = true;
      if (_leftVerticalController.hasClients) {
        _leftVerticalController.jumpTo(_gridVerticalController.offset);
      }
      _isSyncingVertical = false;
    });
    _leftVerticalController.addListener(() {
      if (_isSyncingVertical) return;
      _isSyncingVertical = true;
      if (_gridVerticalController.hasClients) {
        _gridVerticalController.jumpTo(_leftVerticalController.offset);
      }
      _isSyncingVertical = false;
    });
  }

  // İlk yüklemede şu anki saate kaymak için başlangıç offset'i hesapla
  double _calculateInitialScrollOffset() {
    if (_selectedDate.year != _currentTime.year ||
        _selectedDate.month != _currentTime.month ||
        _selectedDate.day != _currentTime.day) {
      return 0;
    }
    final now = DateTime.now();
    final startParts = baslangicSaati.split(':');
    final startHour = int.parse(startParts[0]);
    final startMinute = int.parse(startParts[1]);
    final startTotalMinutes = startHour * 60 + startMinute;
    final currentTotalMinutes = now.hour * 60 + now.minute;
    int minutesFromStart = currentTotalMinutes - startTotalMinutes;
    if (minutesFromStart < 0) return 0;
    final slotHeight = _hourHeight / 4;
    final minuteHeight = _hourHeight / 60;
    double pos = minutesFromStart * minuteHeight - (slotHeight * 3);
    if (pos < 0) pos = 0;
    return pos;
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
        image: NetworkImage('https://apptest.randevumcepte.com.tr' + (item["avatar"] != null ? item['avatar'] : '/public/isletmeyonetim_assets/img/avatar.png')),
      );
    }).toList();

    // İlk yüklemede dikey controller'ları initialScrollOffset ile yenile
    // → ilk frame'de zaten doğru pozisyonda olur, "yukarıdan aşağıya inme" animasyonu yaşanmaz.
    if (_firstLoad) {
      final initialOffset = _calculateInitialScrollOffset();
      _gridVerticalController.dispose();
      _leftVerticalController.dispose();
      _gridVerticalController = ScrollController(initialScrollOffset: initialOffset);
      _leftVerticalController = ScrollController(initialScrollOffset: initialOffset);
      _bindVerticalSyncListeners();
      _firstLoad = false;
    }

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

    // Sonraki yüklemelerde scroll pozisyonlarını geri yükle (tarih değişimi vs.)
    if (_savedVerticalScrollPosition > 0 || _savedHorizontalScrollPosition > 0) {
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
          if (_gapKampanyaListesi.isNotEmpty) _buildGapKampanyaSeridi(),
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
        // Class member'ı güncelle (drag/resize hesaplamaları için)
        _personelGenisligi = personelGenisligi;

        final totalWidth = saatColumnWidth + (personelGenisligi * resources.length);
        final bool needsHorizontalScroll = totalWidth > constraints.maxWidth;

        // Başlangıç saati bilgilerini bir kez parse et
        final startParts = baslangicSaati.split(':');
        final startHour = int.parse(startParts[0]);
        final startMinute = int.parse(startParts[1]);
        final startTotalMinutes = startHour * 60 + startMinute;

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
                            children: List.generate(resources.length, (index) {
                              final resource = resources[index];
                              return RepaintBoundary(
                                child: Container(
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
                                ),
                              );
                            }),
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
                  // SAATLER - CustomPaint ile çiz (performans için)
                  Container(
                    width: saatColumnWidth,
                    color: Colors.grey[50],
                    child: Listener(
                      onPointerSignal: (signal) {
                        if (signal is PointerScrollEvent) {
                          final deltaY = signal.scrollDelta.dy;
                          if (_gridVerticalController.hasClients && deltaY != 0) {
                            _gridVerticalController.jumpTo(
                                _gridVerticalController.offset + deltaY
                            );
                          }
                        }
                      },
                      child: SingleChildScrollView(
                        controller: _leftVerticalController,
                        physics: const ClampingScrollPhysics(),
                        child: RepaintBoundary(
                          child: CustomPaint(
                            size: Size(saatColumnWidth, toplamYukseklik),
                            painter: _SaatColumnPainter(
                              totalSlots: totalSlots,
                              slotHeight: slotHeight,
                              startTotalMinutes: startTotalMinutes,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // PERSONEL SÜTUNLARI - Ana grid
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      controller: _gridVerticalController,
                      physics: const ClampingScrollPhysics(),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        controller: _gridHorizontalController,
                        physics: needsHorizontalScroll
                            ? const ClampingScrollPhysics()
                            : const NeverScrollableScrollPhysics(),
                        child: SizedBox(
                          width: personelGenisligi * resources.length,
                          height: toplamYukseklik,
                          child: Row(
                            children: List.generate(resources.length, (resIndex) {
                              final resource = resources[resIndex];
                              return SizedBox(
                                width: personelGenisligi,
                                height: toplamYukseklik,
                                child: Stack(
                                  clipBehavior: Clip.hardEdge,
                                  children: [
                                    // Grid çizgileri
                                    Positioned.fill(
                                      child: RepaintBoundary(
                                        child: CustomPaint(
                                          painter: _GridLinesPainter(
                                            totalSlots: totalSlots,
                                            slotHeight: slotHeight,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Boş slot tap detector
                                    Positioned.fill(
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.translucent,
                                        onTapUp: (details) {
                                          final position = details.localPosition;
                                          final slotIndex = (position.dy / slotHeight).floor();
                                          if (slotIndex >= 0 && slotIndex < totalSlots) {
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
                                      ),
                                    ),
                                    // Şu anki saat çizgisi
                                    if (_selectedDate.year == _currentTime.year &&
                                        _selectedDate.month == _currentTime.month &&
                                        _selectedDate.day == _currentTime.day)
                                      _buildTimeline(resource, baslangicDouble, saatSayisi, personelGenisligi),
                                    // Randevular
                                    ..._buildAppointmentsForResource(
                                      resource,
                                      saatSayisi,
                                      baslangicDouble,
                                      personelGenisligi,
                                    ),
                                  ],
                                ),
                              );
                            }),
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
            color: Colors.red.withValues(alpha: 0.5),
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

List<Widget> _buildAppointmentsForResource(
      CalendarResource resource,
      int saatSayisi,
      double baslangicDouble,
      double personelGenisligi,
      ) {
    List<Widget> appointments = [];

    final parts = baslangicSaati.split(':');
    final dayStart = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );

    final minuteHeight = _hourHeight / 60;
    final slotHeight = _hourHeight / 4; // 15 dk = 30px

    // Bu resource'a ait randevuları önceden filtrele (overlap hesabı için)
    final resourceAppointments = updatedAppointments.where((a) {
      if (a.resourceIds == null || !a.resourceIds!.contains(resource.id)) return false;
      final st = a.startTime.toLocal();
      return st.year == _selectedDate.year &&
          st.month == _selectedDate.month &&
          st.day == _selectedDate.day;
    }).toList();

    for (var appointment in resourceAppointments) {
      final startDiff = appointment.startTime.toLocal().difference(dayStart).inMinutes;
      final endDiff = appointment.endTime.toLocal().difference(dayStart).inMinutes;

      double startOffset = startDiff * minuteHeight;
      double height = (endDiff - startDiff) * minuteHeight;

      if (startOffset < 0) {
        height += startOffset;
        startOffset = 0;
      }

      if (startOffset + height > saatSayisi * _hourHeight) {
        height = (saatSayisi * _hourHeight) - startOffset;
      }

      if (height <= 0) continue;
      height = height.floorToDouble();

      // OVERLAP HESABI - sadece resource'un kendi randevularına bak
      final sameHourAppointments = resourceAppointments.where((a) {
        final aStart = a.startTime.toLocal().difference(dayStart).inMinutes;
        final aEnd = a.endTime.toLocal().difference(dayStart).inMinutes;
        return (aStart < endDiff) && (aEnd > startDiff);
      }).toList();

      int index = sameHourAppointments.indexOf(appointment);
      int total = sameHourAppointments.length;

      double left = 2;
      double right = 2;

      if (total > 1) {
        double slotGenislik = (personelGenisligi - 4) / total;
        left = 2 + (index * slotGenislik);
        right = 2 + ((total - 1 - index) * slotGenislik);
      }

      Color appointmentColor = appointment.color;
      final cardWidth = personelGenisligi - left - right;

      appointments.add(
        Positioned(
          top: startOffset,
          left: left,
          right: right,
          // height intentionally omitted → child intrinsic height kullanır,
          // resize sırasında Container yüksekliği değişince Positioned takip eder
          child: RepaintBoundary(
            child: _AppointmentCard(
              key: ValueKey('appt_${appointment.id}_${appointment.startTime.millisecondsSinceEpoch}'),
              appointment: appointment,
              color: appointmentColor,
              height: height,
              width: cardWidth,
              slotHeight: slotHeight,
              onTap: () => _appointmentDetayGoster(appointment),
              buildFeedback: (h) => _buildDraggingFeedback(appointment, appointmentColor, h, cardWidth),
              onDragEnd: (details) => _onDragCompleted(details, appointment, resource.id.toString()),
              onResizeEnd: (newDurationMinutes) => _onResizeEnd(appointment, newDurationMinutes, resource.id.toString()),
            ),
          ),
        ),
      );
    }

    return appointments;
  }
  // _onDragCompleted metodu
  void _onDragCompleted(DraggableDetails details, Appointment appointment, String oldResourceId) {
    if (details.offset == Offset.zero) return;

    final RenderBox? renderBox = _calendarKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final localPosition = renderBox.globalToLocal(details.offset);

    // Scroll pozisyonunu al
    final scrollX = _gridHorizontalController.hasClients ? _gridHorizontalController.offset : 0.0;

    // Personel sütunu bul (scroll pozisyonunu da hesaba kat)
    final double personelWidth = _personelGenisligi;
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
        Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/surukleBirakRandevuGuncelle'),
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
  Widget _buildDraggingFeedback(Appointment appointment, Color color, double height, double width) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Text(
            DateFormat.Hm().format(appointment.startTime.toLocal()) +
                "-" +
                DateFormat.Hm().format(appointment.endTime.toLocal()) +
                " " +
                appointment.subject,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
            maxLines: height <= 40 ? 2 : null,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  // Resize sonu: yeni süre dakikası API'ye gönderilir
  Future<void> _onResizeEnd(Appointment appointment, int newDurationMinutes, String resourceId) async {
    final oldDuration = appointment.endTime.difference(appointment.startTime).inMinutes;
    if (newDurationMinutes == oldDuration) return;
    if (newDurationMinutes < 15) newDurationMinutes = 15;

    final newEndTime = appointment.startTime.add(Duration(minutes: newDurationMinutes));
    final oldEndTime = appointment.endTime.toLocal();

    // Onay dialog'u
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Randevu Süresi Değişikliği', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Randevu süresini güncellemek istediğinize emin misiniz?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('⏱  Eski Süre: $oldDuration dk (${DateFormat.Hm().format(appointment.startTime.toLocal())} - ${DateFormat.Hm().format(oldEndTime)})'),
                  const SizedBox(height: 6),
                  Text('⏱  Yeni Süre: $newDurationMinutes dk (${DateFormat.Hm().format(appointment.startTime.toLocal())} - ${DateFormat.Hm().format(newEndTime)})'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('İptal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text('Güncelle'),
          ),
        ],
      ),
    );

    if (onay == true) {
      await _surukleBirakTamamla(appointment, appointment.startTime, newEndTime, resourceId);
    } else {
      // Reddedilirse önceki haline geri dön (rebuild)
      if (mounted) setState(() {});
    }
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
                                if (!context.mounted) return;
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
                                await randevugeldiisaretle(randevudetay.id.toString(), '', context, '');
                                if (!context.mounted) return;
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

// ============================================================
// CUSTOM PAINTER: Saat sütunu (sol taraf)
// ============================================================
class _SaatColumnPainter extends CustomPainter {
  final int totalSlots;
  final double slotHeight;
  final int startTotalMinutes;

  _SaatColumnPainter({
    required this.totalSlots,
    required this.slotHeight,
    required this.startTotalMinutes,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;
    final hourLinePaint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1;
    final borderPaint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1;

    final textStyle = TextStyle(fontSize: 12, color: Colors.grey[800], fontWeight: FontWeight.w500);
    final halfStyle = TextStyle(fontSize: 10, color: Colors.grey[500]);

    for (int i = 0; i < totalSlots; i++) {
      final y = i * slotHeight;
      final totalMinutes = startTotalMinutes + (i * 15);
      final hour = totalMinutes ~/ 60;
      final minute = totalMinutes % 60;
      final isHour = minute == 0;
      final isHalf = minute == 30;

      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        isHour ? hourLinePaint : linePaint,
      );

      if (isHour || isHalf) {
        final timeString =
            '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
        final tp = TextPainter(
          text: TextSpan(text: timeString, style: isHour ? textStyle : halfStyle),
          textDirection: ui.TextDirection.ltr,
        )..layout(maxWidth: size.width - 4);
        tp.paint(canvas, Offset(4, y + 2));
      }
    }

    canvas.drawLine(
      Offset(size.width - 0.5, 0),
      Offset(size.width - 0.5, size.height),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SaatColumnPainter oldDelegate) {
    return oldDelegate.totalSlots != totalSlots ||
        oldDelegate.slotHeight != slotHeight ||
        oldDelegate.startTotalMinutes != startTotalMinutes;
  }
}

// ============================================================
// CUSTOM PAINTER: Grid çizgileri (her personel sütununda)
// ============================================================
class _GridLinesPainter extends CustomPainter {
  final int totalSlots;
  final double slotHeight;

  _GridLinesPainter({required this.totalSlots, required this.slotHeight});

  @override
  void paint(Canvas canvas, Size size) {
    final softLine = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1;
    final strongLine = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1;
    final rightBorder = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;

    for (int i = 0; i <= totalSlots; i++) {
      final y = i * slotHeight;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        i % 4 == 0 ? strongLine : softLine,
      );
    }

    canvas.drawLine(
      Offset(size.width - 0.5, 0),
      Offset(size.width - 0.5, size.height),
      rightBorder,
    );
  }

  @override
  bool shouldRepaint(covariant _GridLinesPainter oldDelegate) {
    return oldDelegate.totalSlots != totalSlots ||
        oldDelegate.slotHeight != slotHeight;
  }
}

// ============================================================
// APPOINTMENT CARD: Drag (LongPress 250ms) + Resize handle
// ============================================================
class _AppointmentCard extends StatefulWidget {
  final Appointment appointment;
  final Color color;
  final double height;
  final double width;
  final double slotHeight; // 15 dk
  final VoidCallback onTap;
  final Widget Function(double height) buildFeedback;
  final void Function(DraggableDetails details) onDragEnd;
  final void Function(int newDurationMinutes) onResizeEnd;

  const _AppointmentCard({
    Key? key,
    required this.appointment,
    required this.color,
    required this.height,
    required this.width,
    required this.slotHeight,
    required this.onTap,
    required this.buildFeedback,
    required this.onDragEnd,
    required this.onResizeEnd,
  }) : super(key: key);

  @override
  State<_AppointmentCard> createState() => _AppointmentCardState();
}

class _AppointmentCardState extends State<_AppointmentCard> {
  double? _resizeHeight;
  bool _isResizing = false;

  // FullCalendar tarzı: handle'a basıp doğrudan sürükle → resize
  void _onResizeStart(DragStartDetails _) {
    setState(() {
      _isResizing = true;
      _resizeHeight = widget.height;
    });
  }

  void _onResizeUpdate(DragUpdateDetails details) {
    final newH = (_resizeHeight ?? widget.height) + details.delta.dy;
    final clamped = newH.clamp(widget.slotHeight, widget.slotHeight * 96);
    setState(() {
      _resizeHeight = clamped;
    });
  }

  void _onResizeFinish(DragEndDetails _) {
    if (!_isResizing) return;
    final h = _resizeHeight ?? widget.height;
    final slots = (h / widget.slotHeight).round().clamp(1, 96);
    final newDurationMinutes = slots * 15;

    setState(() {
      _isResizing = false;
      _resizeHeight = null;
    });

    widget.onResizeEnd(newDurationMinutes);
  }

  void _onResizeCancel() {
    setState(() {
      _isResizing = false;
      _resizeHeight = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final displayHeight = _resizeHeight ?? widget.height;
    final color = widget.color;

    final resizeMinutes = _isResizing
        ? ((displayHeight / widget.slotHeight).round() * 15)
        : 0;

    // Yukseklige gore adaptif render:
    // - tiny  (<28px, ~10dk):       handle gizli, ucap padding, fontSize 8.5, tek satir "HH:MM isim"
    // - short (28-44px, 15-20dk):   handle 8px, sik padding, fontSize 9, tek satir
    // - normal(>=44px):             mevcut gorunum (handle 16px, fontSize 10, 2 satira kadar)
    final bool isTiny = displayHeight < 28;
    final bool isShort = !isTiny && displayHeight < 44;
    final double handleHeight = isTiny ? 0 : (isShort ? 8 : 16);
    final EdgeInsets textPadding = isTiny
        ? const EdgeInsets.fromLTRB(3, 1, 3, 2)
        : (isShort
            ? const EdgeInsets.fromLTRB(3, 1, 3, 10)
            : const EdgeInsets.fromLTRB(4, 2, 4, 18));
    final double fontSize = isTiny ? 8.5 : (isShort ? 9 : 10);
    final int maxLines = (isTiny || isShort) ? 1 : 2;

    final String startTimeText = DateFormat.Hm().format(widget.appointment.startTime.toLocal());
    final String endTimeText = DateFormat.Hm().format(widget.appointment.endTime.toLocal());
    final String contentText = _isResizing
        ? '$startTimeText • $resizeMinutes dk'
        // Tiny'de yer az: saat aralik yerine sadece baslangic saati
        : (isTiny
            ? '$startTimeText ${widget.appointment.subject}'
            : '$startTimeText-$endTimeText ${widget.appointment.subject}');

    // Kart dekorasyonu + icerik
    final cardBody = Container(
      width: widget.width,
      height: displayHeight,
      decoration: BoxDecoration(
        color: color.withValues(alpha: _isResizing ? 0.7 : 0.92),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: _isResizing ? Colors.white : color,
          width: _isResizing ? 2 : 1,
        ),
        boxShadow: _isResizing
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: textPadding,
          child: Text(
            contentText,
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              height: 1.1,
            ),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );

    // FullCalendar tarzı resize handle - Stack'te en üstte (drag'i engeller)
    final resizeHandle = MouseRegion(
      cursor: SystemMouseCursors.resizeRow,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragStart: _onResizeStart,
        onVerticalDragUpdate: _onResizeUpdate,
        onVerticalDragEnd: _onResizeFinish,
        onVerticalDragCancel: _onResizeCancel,
        child: Container(
          color: Colors.black.withValues(alpha: _isResizing ? 0.4 : 0.25),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: _isResizing ? 42 : 34,
                height: 2,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              const SizedBox(height: 2),
              Container(
                width: _isResizing ? 42 : 34,
                height: 2,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Resize sırasında drag'i tamamen devre dışı bırak
    final dragLayer = _isResizing
        ? cardBody
        : GestureDetector(
            onTap: widget.onTap,
            child: LongPressDraggable<Appointment>(
              data: widget.appointment,
              delay: const Duration(milliseconds: 250),
              hapticFeedbackOnStart: true,
              feedback: widget.buildFeedback(widget.height),
              childWhenDragging: Opacity(opacity: 0.25, child: cardBody),
              onDragEnd: widget.onDragEnd,
              child: cardBody,
            ),
          );

    // SizedBox + Stack: handle, LongPressDraggable'ın DIŞINDA bağımsız layer
    // Stack'te handle son child → hit-test önce ona gider → drag asla tetiklenmez.
    // Tiny (10dk) blokta handle hic gosterilmez; resize uzun-basip surukleyerek hala mumkun.
    return SizedBox(
      width: widget.width,
      height: displayHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: dragLayer),
          if (handleHeight > 0)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: handleHeight,
              child: resizeHandle,
            ),
        ],
      ),
    );
  }
}
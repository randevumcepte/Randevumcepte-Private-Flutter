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
import 'package:randevu_sistem/Backend/yetki.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:randevu_sistem/Models/takvimturu.dart';
import 'package:randevu_sistem/theme/app_tokens.dart';
import 'package:randevu_sistem/yonetici/randevular/randevu_page.dart';
import 'package:randevu_sistem/yonetici/randevular/randevuduzenle.dart';
import 'package:randevu_sistem/yonetici/diger/menu/musteriler/iletisim_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:randevu_sistem/Models/randevular.dart';
import 'package:randevu_sistem/Backend/backend.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:randevu_sistem/Frontend/indexedstack.dart';
import 'package:randevu_sistem/Frontend/popupdialogs.dart';
import 'package:randevu_sistem/Frontend/route_observer.dart';
import 'package:randevu_sistem/Frontend/sfdatatable.dart';
import 'package:randevu_sistem/Models/ongorusmeler.dart';
import 'package:randevu_sistem/Models/odalar.dart';
import 'package:randevu_sistem/Models/cihazlar.dart';
import 'package:randevu_sistem/Models/personel.dart';
import 'package:randevu_sistem/Models/user.dart';
import 'package:randevu_sistem/yukselt.dart';
import '../adisyonlar/satislar/tahsilat.dart';
import '../diger/menu/randvular/randevularmenu.dart';
import 'appointment-editor.dart';
import 'saat_kapama_form.dart';

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

class TakvimState extends State<Takvim> with RouteAware {

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
  // Web tarafindaki buyutec (zoom) ile ayni mantik: BASE * _zoom olarak olceklendir.
  // Web: BASE_H=32.5 slot -> 1h = 130px. Mobilde 1h base = 130px (slot = 32.5px) — ayni oran.
  static const double _hourHeightBase = 130.0;
  static const double _personelGenisligiBase = 150.0;
  static const double _zoomMin = 0.6;
  static const double _zoomMax = 4.0;
  static const double _zoomStep = 0.4;
  double _zoom = 1.0;
  double get _hourHeight => _hourHeightBase * _zoom;
  double _personelGenisligi = _personelGenisligiBase; // _buildCustomCalendar icinde guncellenir
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

    // ONCE yetki cache'i tazele, SONRA randevu fetch. Yoksa
    // 'randevu.tum_personel_gor' kontrolu eski cache'le yapilir,
    // personel_id filtresi yanlis uygulanir.
    () async {
      await Yetki.tazele(salonid: widget.isletmebilgi['id'].toString());
      if (!mounted) return;
      await getUpdatedAppointments(
        DateFormat('yyyy-MM-dd').format(seciliTarih),
        DateFormat('yyyy-MM-dd').format(seciliTarih),
        false,
      );
    }();

    _loadGapKampanyalari();
    _loadZoom();
  }

  String get _zoomPrefsKey =>
      'takvim_zoom_${widget.isletmebilgi["id"]}';

  Future<void> _loadZoom() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final v = prefs.getDouble(_zoomPrefsKey);
      if (v == null) return;
      if (v < _zoomMin || v > _zoomMax) return;
      if (!mounted) return;
      setState(() => _zoom = v);
    } catch (_) {}
  }

  Future<void> _setZoom(double z) async {
    final clamped = z.clamp(_zoomMin, _zoomMax);
    if (clamped == _zoom) return;
    setState(() => _zoom = clamped);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_zoomPrefsKey, clamped);
    } catch (_) {}
  }

  /// Tab'a her geri donuste cagrilir: o an seçili tarih icin randevulari
  /// ve aktif kampanyalari yeniden cek. Yetki filtresi
  /// getUpdatedAppointments icinde uygulanir.
  Future<void> reloadCurrent() async {
    if (!mounted) return;
    final tarihStr = DateFormat('yyyy-MM-dd').format(seciliTarih);
    await getUpdatedAppointments(tarihStr, tarihStr, false);
    if (!mounted) return;
    await _loadGapKampanyalari();
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
    final ext = context.appTheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: ext.warningColor.withValues(alpha: 0.10),
        border: Border(
          bottom: BorderSide(
              color: ext.warningColor.withValues(alpha: 0.35), width: 1),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          Icon(Icons.local_offer_rounded,
              size: 14, color: ext.warningColor),
          const SizedBox(width: 6),
          Text(
            'Aktif Kampanya:',
            style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: ext.warningColor),
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

    final cs = context.colors;
    final ext = context.appTheme;
    return InkWell(
      onTap: () => _showGapKampanyaDetay(k),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
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
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: ext.successColor,
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

    final cs = context.colors;
    final ext = context.appTheme;
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
                      color: ext.successColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.local_offer_rounded,
                        size: 18, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '$label Kampanyası',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _detayRow(Icons.schedule_rounded, 'Saat',
                  '${start.toString().padLeft(2, '0')}:00 – ${end.toString().padLeft(2, '0')}:00'),
              const SizedBox(height: 8),
              _detayRow(Icons.local_offer_rounded, 'İndirim', '%$disc',
                  valueColor: ext.successColor),
              const SizedBox(height: 8),
              _detayRow(
                  Icons.timer_outlined,
                  'Kalan süre',
                  kalanGun > 0 ? '$kalanGun gün' : 'Bugün son gün',
                  valueColor: ext.successColor),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: ext.successColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Bu saat aralığındaki müşteriler tahsilat sırasında otomatik %$disc indirim almaya hak kazanır.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: cs.onSurface,
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
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
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
    final cs = context.colors;
    return Row(
      children: [
        Icon(icon, size: 15, color: cs.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: cs.onSurfaceVariant),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: valueColor ?? cs.onSurface,
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Route stack'in degisebilecegi her durumda RouteAware aboneligini
    // mevcut PageRoute'a yeniden bagla. didPopNext bir alt sayfadan geri
    // donulduginde tetiklenir ve takvimi tazeler.
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      appRouteObserver.unsubscribe(this);
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void didPopNext() {
    // Alt sayfadan (randevu duzenle, satis vs.) bu route'a donulduginde
    // takvimi guncel veriyle sessizce yeniden yukle.
    reloadCurrent();
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
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

    // Personel rolundeki kullanici 'randevu.tum_personel_gor' yetkisi YOKSA
    // kendi randevulari filtrelenir. Yetki acikken filtre uygulanmaz (tum
    // randevular gelir). Yetkili rollerde de filtre yok.
    if (widget.kullanicirolu == 5 &&
        !Yetki.varMi('randevu.tum_personel_gor')) {
      widget.kullanici.yetkili_olunan_isletmeler.forEach((element) {
        if (element["salon_id"].toString() == widget.isletmebilgi["id"].toString()) {
          setState(() {
            personelid = element["id"].toString();
          });
        }
      });
    } else {
      // Yetki acildiysa eski personelid filtresini temizle.
      if (personelid.isNotEmpty) {
        setState(() {
          personelid = "";
        });
      }
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
        image: NetworkImage('https://app.randevumcepte.com.tr/' + (item["avatar"] != null ? item['avatar'] : '/public/isletmeyonetim_assets/img/avatar.png')),
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

  /// Top bar 'lock_clock' ikonundan cagrilir. Personel/Oda/Cihaz listelerini
  /// yukleyip Saat Kapama bottom sheet'ini acar; kaydedilirse takvimi yeniler.
  Future<void> _saatKapamaAc() async {
    final salonId = widget.isletmebilgi['id'].toString();
    // Personel zaten state'te yuklu. Oda + Cihaz icin verileri cek.
    List<Oda> odalar = const [];
    List<Cihaz> cihazlar = const [];
    try {
      final veri = await isletmeVerileriGetir(salonId, false, '', '', '', 0, 0);
      odalar = (veri['odalar'] as List?)?.cast<Oda>() ?? const [];
      cihazlar = (veri['cihazlar'] as List?)?.cast<Cihaz>() ?? const [];
    } catch (e) {
      log('saat kapama icin oda/cihaz cekilemedi: $e');
    }
    if (!mounted) return;
    final kaydedildi = await showSaatKapamaSheet(
      context: context,
      salonId: salonId,
      takvimTuruId:
          widget.isletmebilgi['randevu_takvim_turu']?.toString() ?? '1',
      personeller: personelliste,
      odalar: odalar,
      cihazlar: cihazlar,
    );
    if (kaydedildi == true && mounted) {
      await getUpdatedAppointments(
        DateFormat('yyyy-MM-dd').format(seciliTarih),
        DateFormat('yyyy-MM-dd').format(seciliTarih),
        true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final ext = context.appTheme;
    double ekranGenisligi = MediaQuery.of(context).size.width;
    final String formattedDate = DateFormat('d MMMM EEEE', 'tr_TR').format(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Takvim'),
        actions: [
          if (widget.isletmebilgi["demo_hesabi"].toString() == "1")
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: SizedBox(
                width: 100,
                child: YukseltButonu(isletme_bilgi: widget.isletmebilgi),
              ),
            ),
          _buildZoomControl(),
          IconButton(
            tooltip: 'Yenile',
            onPressed: () async {
              // Yetki cache'ini tazele + takvimi yeniden cek.
              await Yetki.tazele(salonid: widget.isletmebilgi['id'].toString());
              await getUpdatedAppointments(
                DateFormat('yyyy-MM-dd').format(seciliTarih),
                DateFormat('yyyy-MM-dd').format(seciliTarih),
                true,
              );
            },
            icon: const Icon(Icons.refresh),
            iconSize: 24,
          ),
          if (Yetki.varMi('randevu.olustur'))
            IconButton(
              tooltip: 'Saat Kapama',
              onPressed: _saatKapamaAc,
              icon: const Icon(Icons.lock_clock),
              iconSize: 24,
            ),
          if (Yetki.varMi('randevu.olustur'))
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
              icon: const Icon(Icons.add),
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
                border: Border.all(color: ext.borderSubtle),
              ),
              // resources.isEmpty ise mesaj göster, değilse takvimi göster
              child: resources.isEmpty
                  ? Center(
                child: Text(
                  'Gösterilecek veri bulunmamaktadır.',
                  style: TextStyle(fontSize: 16, color: cs.onSurfaceVariant),
                ),
              )
                  : _buildCustomCalendar(),
            ),
          ),
        ],
      ),
    );
  }

  // Buyutec — web tarafindaki .rc-zoom kontrolunun mobil karsiligi.
  // Salon bazli SharedPreferences ile kalici, MIN/MAX/STEP web ile ayni.
  Widget _buildZoomControl() {
    final cs = context.colors;
    final yuzde = (_zoom * 100).round();
    final canOut = _zoom > _zoomMin + 0.001;
    final canIn = _zoom < _zoomMax - 0.001;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: cs.outlineVariant),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkResponse(
              radius: 18,
              onTap: canOut ? () => _setZoom(_zoom - _zoomStep) : null,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  Icons.zoom_out,
                  size: 20,
                  color: canOut ? cs.primary : cs.onSurface.withValues(alpha: 0.3),
                ),
              ),
            ),
            SizedBox(
              width: 38,
              child: Text(
                '$yuzde%',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: cs.primary,
                ),
              ),
            ),
            InkResponse(
              radius: 18,
              onTap: canIn ? () => _setZoom(_zoom + _zoomStep) : null,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  Icons.zoom_in,
                  size: 20,
                  color: canIn ? cs.primary : cs.onSurface.withValues(alpha: 0.3),
                ),
              ),
            ),
          ],
        ),
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
            color: context.colors.surfaceContainerHighest,
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
    final cs = context.colors;
    final ext = context.appTheme;
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

        final double minPersonelWidth = _personelGenisligiBase * _zoom;
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
                        right: BorderSide(color: ext.borderStrong),
                        bottom: BorderSide(color: ext.borderStrong),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Saat',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: cs.onSurface),
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
                                      right: BorderSide(color: ext.borderStrong),
                                      bottom: BorderSide(color: ext.borderStrong),
                                    ),
                                    color: index % 2 == 0
                                        ? ext.surfaceMuted
                                        : Theme.of(context).cardColor,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: resource.color ?? ext.borderStrong,
                                            width: 2.0,
                                          ),
                                        ),
                                        child: CircleAvatar(
                                          radius: 16,
                                          backgroundImage: resource.image,
                                          backgroundColor: cs.surfaceContainerHighest,
                                          child: resource.image == null
                                              ? Text(
                                            resource.displayName.isNotEmpty
                                                ? resource.displayName[0].toUpperCase()
                                                : '?',
                                            style: TextStyle(
                                              color: resource.color ?? cs.onSurfaceVariant,
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
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                            color: cs.onSurface
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
                    color: ext.surfaceMuted,
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
                              softLineColor: ext.borderSubtle,
                              strongLineColor: ext.borderStrong,
                              hourTextColor: cs.onSurface,
                              halfTextColor: cs.onSurfaceVariant,
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
                                            softLineColor: ext.borderSubtle,
                                            strongLineColor: ext.borderStrong,
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

    final cs = context.colors;
    // Kırmızı nokta (daire) — şu an = error semantic
    final redDot = Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: cs.error,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: cs.error.withValues(alpha: 0.5),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );

    // Çizgi (tüm personel sütunu boyunca)
    final line = Container(
      height: 2,
      color: cs.error,
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
              color: cs.error,
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
        SnackBar(
          content: const Text("Geçersiz personel!"),
          backgroundColor: context.colors.error,
        ),
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
        color: context.colors.outline,
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
    final cs = context.colors;
    final ext = context.appTheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
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
                color: ext.surfaceMuted,
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
            child: Text('İptal', style: TextStyle(color: cs.onSurfaceVariant)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _surukleBirakTamamla(appointment, newStartTime, newEndTime, resources[personelIndex].id.toString());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ext.successColor,
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
            backgroundColor: context.colors.error,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Güncelleme hatası: $e"),
          backgroundColor: context.colors.error,
        ),
      );
    }
  }

// Sürükleme sırasında gösterilecek widget
  Widget _buildDraggingFeedback(Appointment appointment, Color color, double height, double width) {
    final ext = context.appTheme;
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
              color: ext.shadowBase.withValues(alpha: 0.35),
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
    final cs = context.colors;
    final ext = context.appTheme;
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        scrollable: true,
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
                color: ext.surfaceMuted,
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
            child: Text('İptal', style: TextStyle(color: cs.onSurfaceVariant)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: ext.successColor, foregroundColor: Colors.white),
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

    final tt = selectedTakvimTuru?.id ?? '1';
    final String resType = tt == '2'
        ? 'cihaz'
        : tt == '3'
            ? 'oda'
            : tt == '0'
                ? 'hizmet'
                : 'personel';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AppointmentEditor(
          kullanicirolu: widget.kullanicirolu,
          isletmebilgi: widget.isletmebilgi,
          tarihsaat: tarih.toString(),
          personel_id: resType == 'personel' ? resourceId : '',
          resourceId: resourceId,
          resourceType: resType,
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
    // Saat kapama kaydina tiklandiysa: normal randevu detayini gostermek yerine
    // "Bu kapali saat kaydini silmek istediginize emin misiniz?" onay
    // penceresi cikar. Onaylanirsa kapaliSaatSil ile silinir.
    final ilkSatir = appointment.subject.split('\n').first.trim();
    if (ilkSatir == 'Kapalı Saat' || ilkSatir == 'Kapali Saat') {
      _kapaliSaatSilOnayi(appointment);
      return;
    }
    RandevuDetayGoster(context, appointment);
  }

  Future<void> _kapaliSaatSilOnayi(Appointment appointment) async {
    final cs = Theme.of(context).colorScheme;
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Onayla', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Bu kapalı saat kaydını silmek istediğinize emin misiniz?'),
        actionsAlignment: MainAxisAlignment.end,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: cs.error, foregroundColor: cs.onError),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sil'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Vazgeç'),
          ),
        ],
      ),
    );
    if (onay != true) return;

    try {
      final sonuc = await kapaliSaatSil(appointment.id.toString());
      if (!mounted) return;
      if (sonuc['ok'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(sonuc['message']?.toString() ?? 'Saat kapama kaldırıldı')),
        );
        await getUpdatedAppointments(
          DateFormat('yyyy-MM-dd').format(seciliTarih),
          DateFormat('yyyy-MM-dd').format(seciliTarih),
          true,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(sonuc['error']?.toString() ?? sonuc['message']?.toString() ?? 'Silme başarısız')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Silme başarısız: $e')),
      );
    }
  }

  void RandevuDetayGoster(BuildContext context, Appointment randevudetay) {
    final cs = context.colors;
    final ext = context.appTheme;
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
                      child: CircleAvatar(
                        backgroundColor: cs.error,
                        foregroundColor: Colors.white,
                        child: const Icon(Icons.close),
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
                            color: ext.warningColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: ext.warningColor),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info, color: ext.warningColor),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Bu randevunuzun tahsilatını daha önce gerçekleştirdiniz.',
                                  style: TextStyle(color: ext.warningColor),
                                ),
                              ),
                            ],
                          ),
                        )
                            : SizedBox(),

                        SizedBox(height: 20,),
                        Text(
                          randevutitle[0] + " Randevu Detayları",
                          style: TextStyle(fontWeight: FontWeight.bold, color: cs.onSurface),
                        ),
                        Divider(color: cs.outlineVariant, height: 10,),
                        Row(
                          children: [

                            Expanded(child: Text(randevudetay.notes ?? ""))
                          ],
                        ),

                        (randevudurum![0] == "0" || randevudurum![0] == "1") && Yetki.varMi('randevu.duzenle_iptal') ? Divider(color: cs.outlineVariant,
                          height: 30,): SizedBox.shrink(),
                        (randevudurum![0] == "0" || randevudurum![0] == "1") && Yetki.varMi('randevu.duzenle_iptal') && !(randevutitle[0].contains("ÖN GÖRÜŞME") && (randevudetay.notes ?? "").contains("Satış Yapılmadı")) ? _detayBtn(
                          label: 'Düzenle',
                          icon: Icons.edit_outlined,
                          color: cs.primary,
                          fullWidth: true,
                          onTap: () {
                            Navigator.of(context, rootNavigator: true).pop();
                            Navigator.push(context, new MaterialPageRoute(builder: (context) => RandevuDuzenle(isletmebilgi: widget.isletmebilgi, randevu: randevuliste.firstWhere((element) => element.id.toString()==randevudetay.id.toString()),))).then((value) {
                              getUpdatedAppointments(DateFormat('yyyy-MM-dd').format(seciliTarih), DateFormat('yyyy-MM-dd').format(seciliTarih),true);
                            });
                          },
                        ) : SizedBox.shrink(),
                        // WhatsApp + Anket butonlari (web randevu detay kartindaki
                        // .whatsapp-mesaj-ac ve .anket-hizli-gonder-btn karsiligi).
                        // On gorusme haric randevularda gosterilir; telefon varsa WA,
                        // pazarlama.anket_yonet yetkisi varsa Anket butonu.
                        _iletisimButonlariRow(context, randevudetay, randevutitle, randevudurum!),
                        (randevudurum![0] == "0" || randevudurum![0] == "1") && Yetki.varMi('randevu.duzenle_iptal') ? Padding(padding: const EdgeInsets.only(top: 10), child: _detayGrid([
                            if (randevudurum![0] == "0")
                              _detayBtn(
                                label: 'Onayla',
                                icon: Icons.check_circle_outline,
                                color: ext.successColor,
                                onTap: () {
                                  randevuonayla(randevudetay.id.toString(), context);
                                  Navigator.of(context).pop();
                                  getUpdatedAppointments(DateFormat('yyyy-MM-dd').format(seciliTarih), DateFormat('yyyy-MM-dd').format(seciliTarih),false);
                                },
                              ),
                            if (randevudurum![0] == '0')
                              _detayBtn(
                                label: 'İptal Et',
                                icon: Icons.cancel_outlined,
                                color: cs.error,
                                onTap: () {
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
                              ),
                            if (randevudurum![0] != "0" && randevudurum[1] != "0")
                              _detayBtn(
                                label: 'Gelmedi',
                                icon: Icons.close_rounded,
                                color: cs.error,
                                onTap: () async {
                                  await randevugelmediisaretle(randevudetay.id.toString(), context);
                                  if (!context.mounted) return;
                                  Navigator.of(context).pop();
                                  getUpdatedAppointments(DateFormat('yyyy-MM-dd').format(seciliTarih), DateFormat('yyyy-MM-dd').format(seciliTarih),false);
                                },
                              ),
                            if (randevudurum![0] != "0" && randevudurum[1] == "0")
                              _detayBtn(
                                label: 'Gelmedi İşaretini Kaldır',
                                icon: Icons.undo_rounded,
                                color: cs.error,
                                onTap: () async {
                                  await randevuGeldiGelmediIsaretiKaldir(randevudetay.id.toString(), context);
                                  Navigator.of(context).pop();
                                  getUpdatedAppointments(DateFormat('yyyy-MM-dd').format(seciliTarih), DateFormat('yyyy-MM-dd').format(seciliTarih),false);
                                },
                              ),
                            if (randevudurum![0] != "0" && randevudurum[1] != "1")
                              _detayBtn(
                                label: 'Geldi',
                                icon: Icons.check_rounded,
                                color: ext.successColor,
                                onTap: () async {
                                  await randevugeldiisaretle(randevudetay.id.toString(), '', context, '');
                                  if (!context.mounted) return;
                                  Navigator.of(context).pop();
                                  getUpdatedAppointments(DateFormat('yyyy-MM-dd').format(seciliTarih), DateFormat('yyyy-MM-dd').format(seciliTarih),false);
                                },
                              ),
                            if (randevudurum![0] != "0" && randevudurum[1] == "1")
                              _detayBtn(
                                label: 'Geldi İşaretini Kaldır',
                                icon: Icons.undo_rounded,
                                color: ext.successColor,
                                onTap: () async {
                                  await randevuGeldiGelmediIsaretiKaldir(randevudetay.id.toString() , context );
                                  Navigator.of(context).pop();
                                  getUpdatedAppointments(DateFormat('yyyy-MM-dd').format(seciliTarih), DateFormat('yyyy-MM-dd').format(seciliTarih),false);
                                },
                              ),
                        ])):SizedBox.shrink(),

                        (randevudurum![0] == "0" || randevudurum![0] == "1" ) && randevudurum![3] != '1' && !randevutitle[0].contains("ÖN GÖRÜŞME") && (Yetki.varMi('satis.tahsilat_al') || Yetki.varMi('randevu.duzenle_iptal'))  ? Padding(padding: const EdgeInsets.only(top: 10), child: _detayGrid([
                            if (randevudurum![0] != "0" && !randevutitle[0].contains("PAKET") && Yetki.varMi('satis.tahsilat_al'))
                              _detayBtn(
                                label: 'Tahsilat',
                                icon: Icons.payments_outlined,
                                color: cs.primary,
                                onTap: () async{
                                  if(randevudurum![2]!='1')
                                    await randevudantahsilatagit(context,randevudetay.id.toString());

                                  Navigator.of(context).pop();
                                  Navigator.push(context, new MaterialPageRoute(builder: (context) => TahsilatEkrani(adisyonId: "", kullanicirolu: widget.kullanicirolu, isletmebilgi: widget.isletmebilgi, musteridanisanid: randevuliste.firstWhere((element) => element.id==randevudetay.id.toString()).user_id.toString()))).then((value) {
                                    log('refresh yapıcak ');
                                    getUpdatedAppointments(DateFormat('yyyy-MM-dd').format(seciliTarih), DateFormat('yyyy-MM-dd').format(seciliTarih),false);
                                  });
                                },
                              ),
                            if (randevudurum![0] != '0' && Yetki.varMi('randevu.duzenle_iptal'))
                              _detayBtn(
                                label: 'İptal Et',
                                icon: Icons.cancel_outlined,
                                color: cs.error,
                                onTap: () {
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
                              ),
                        ])) : SizedBox.shrink(),
                        (randevudurum![0] == "0" || randevudurum![0] == "1") && randevutitle[0].contains("ÖN GÖRÜŞME") && (randevudetay.notes ?? "").contains("Beklemede")  ? Padding(padding: const EdgeInsets.only(top: 10), child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _detayBtn(
                                    label: 'Satış Yapıldı',
                                    icon: Icons.point_of_sale_outlined,
                                    color: ext.successColor,
                                    onTap: () async{
                                      OnGorusme selectedItem = await ongorsumebilgi(randevudetay.recurrenceId.toString());
                                      bool _dolu(String? v) => v != null && v.isNotEmpty && v != "null" && v != "0";
                                      final String _musteriId = randevuliste
                                          .firstWhere((element) => element.id == randevudetay.id.toString())
                                          .user_id
                                          .toString();
                                      if (_dolu(selectedItem.paket_id)) {
                                        paketsatispopup(context, randevudetay.recurrenceId.toString(), musteriId: _musteriId);
                                      } else if (_dolu(selectedItem.urun_id)) {
                                        urunsatispopup(context, randevudetay.recurrenceId.toString());
                                      } else if (_dolu(selectedItem.hizmet_id)) {
                                        hizmetsatispopup(context, randevudetay.recurrenceId.toString());
                                      }
                                    },
                                  ),
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: _detayBtn(
                                    label: 'Satış Yapılmadı',
                                    icon: Icons.remove_shopping_cart_outlined,
                                    color: cs.error,
                                    onTap: () {
                                      showSatisYapilmamaNedeniDialog(context, randevudetay.recurrenceId.toString(),"1","",(value)=>getUpdatedAppointments(DateFormat('yyyy-MM-dd').format(seciliTarih), DateFormat('yyyy-MM-dd').format(seciliTarih),false));
                                    },
                                  ),
                                ),
                              ],
                            ),
                            if (Yetki.varMi('randevu.duzenle_iptal')) ...[
                              SizedBox(height: 10),
                              _detayBtn(
                                label: 'Randevuyu İptal Et',
                                icon: Icons.event_busy_outlined,
                                color: cs.error,
                                fullWidth: true,
                                onTap: () {
                                  showDialog<bool>(
                                    context: context,
                                    builder: (dialogContex) {
                                      return AlertDialog(
                                        title: Text('EMİN MİSİNİZ?'),
                                        content: Text("Ön görüşme randevusu iptal edilecek ve otomatik olarak satış yapılmadı (Randevu iptali) işaretlenecektir."),
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
                                              await satisyapilmadi(context, randevudetay.recurrenceId.toString(), "Randevu iptali", "1", "", false);
                                              await randevuiptalet(randevudetay.id.toString(), context, usertype.toString());
                                              Navigator.of(dialogContex).pop();
                                              getUpdatedAppointments(DateFormat('yyyy-MM-dd').format(seciliTarih), DateFormat('yyyy-MM-dd').format(seciliTarih), false);
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ],
                        )) : SizedBox.shrink(),

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

  // Randevu detay popup'ı için kompakt dolu aksiyon butonu (küçük)
  Widget _detayBtn({
    required String label,
    IconData? icon,
    required Color color,
    required VoidCallback onTap,
    bool fullWidth = false,
    double fontSize = 12.5,
  }) {
    final btn = ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        minimumSize: const Size(0, 34),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600),
      ),
    );
    if (fullWidth) return SizedBox(width: double.infinity, child: btn);
    return btn;
  }

  // Aksiyon butonlarını 2 kolonlu grid olarak dizer (yan yana 2'şer)
  Widget _detayGrid(List<Widget> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    // Tek eleman -> full-width (aksi halde solda yarim durur, orphan gorunur)
    if (items.length == 1) {
      return SizedBox(width: double.infinity, child: items.first);
    }
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i += 2) {
      final hasSecond = i + 1 < items.length;
      rows.add(Padding(
        padding: EdgeInsets.only(bottom: (i + 2 < items.length) ? 10 : 0),
        child: Row(
          children: [
            Expanded(child: items[i]),
            const SizedBox(width: 10),
            Expanded(child: hasSecond ? items[i + 1] : const SizedBox()),
          ],
        ),
      ));
    }
    return Column(mainAxisSize: MainAxisSize.min, children: rows);
  }

  // Randevu detay popup'inda WhatsApp + Anket Gonder butonlarini gosterir.
  // Web'deki randevu event kartinin (.whatsapp-mesaj-ac / .anket-hizli-gonder-btn)
  // birebir mobil karsiligi. On gorusme randevularinda gizlenir.
  Widget _iletisimButonlariRow(BuildContext context, dynamic randevudetay, List<String> randevutitle, List<String> randevudurum) {
    final cs = context.colors;
    final isOnGorusme = randevutitle.isNotEmpty && randevutitle[0].contains("ÖN GÖRÜŞME");
    if (isOnGorusme) return const SizedBox.shrink();

    // Randevu'ya bagli Randevu objesini bul (telefonno/user_id icin)
    Randevu? rnd;
    try {
      rnd = randevuliste.firstWhere((e) => e.id.toString() == randevudetay.id.toString());
    } catch (_) {
      rnd = null;
    }
    if (rnd == null) return const SizedBox.shrink();

    final tel = _sadeTelefon(rnd.telefonno);
    final userId = rnd.user_id;
    final hasWa = tel.isNotEmpty;
    // Anket yetkisi backend: pazarlama.anket_yonet
    final hasAnket = Yetki.varMi('pazarlama.anket_yonet') && userId.isNotEmpty;

    if (!hasWa && !hasAnket) return const SizedBox.shrink();

    // Salon id (isletmebilgi'den)
    final String salonIdStr = widget.isletmebilgi["id"]?.toString() ?? '';

    final buttons = <Widget>[];
    if (hasWa) {
      buttons.add(_detayBtn(
        label: 'WhatsApp',
        icon: Icons.chat_outlined,
        color: const Color(0xFF25D366),
        onTap: () => IletisimHelper.gonderWhatsapp(
          context,
          salonId: salonIdStr,
          userId: userId,
          musteriAdi: rnd!.musteriname,
          telefon: tel,
        ),
      ));
    }
    if (hasAnket) {
      buttons.add(_detayBtn(
        label: 'Anket Gönder',
        icon: Icons.mark_email_read_outlined,
        color: const Color(0xFF17A589),
        onTap: () => IletisimHelper.gonderAnket(
          context,
          salonId: salonIdStr,
          userId: userId,
          musteriAdi: rnd!.musteriname,
        ),
      ));
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: _detayGrid(buttons),
    );
  }

  // Telefon numarasini 5xxxxxxxxx / 90xxxxxxxxxx formatinda temizler.
  String _sadeTelefon(String? raw) {
    if (raw == null) return '';
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty || digits == 'null') return '';
    return digits;
  }

  // WhatsApp sohbetini acar (wa.me).
  Future<void> _waAc(BuildContext context, String tel) async {
    // wa.me uluslararasi kod bekliyor; Turkiye numarasi ise 90 on ekle
    var num = tel;
    if (num.startsWith('0')) num = num.substring(1);
    if (!num.startsWith('90')) num = '90' + num;
    final url = 'https://wa.me/$num';
    try {
      final uri = Uri.parse(url);
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('WhatsApp açılamadı')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('WhatsApp acilirken hata: $e')),
        );
      }
    }
  }

  // Musteri kartindaki anket gonder akisinin birebir karsiligi.
  // Backend: /api/v1/anket-hizli-gonder (musteridetaylar.dart ile ayni endpoint).
  Future<void> _anketGonder(BuildContext context, String userId, String musteriAdi) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Memnuniyet Anketi Gönder'),
        content: Text('$musteriAdi adlı müşteriye memnuniyet anketi WhatsApp veya SMS ile gönderilsin mi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              foregroundColor: Colors.white,
            ),
            child: const Text('Evet, Gönder'),
          ),
        ],
      ),
    );
    if (onay != true) return;
    if (!context.mounted) return;

    final salonId = widget.isletmebilgi["id"].toString();

    // Preloader
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(children: [
          CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF25D366)),
          SizedBox(width: 16),
          Expanded(child: Text('Anket gönderiliyor…')),
        ]),
      ),
    );

    String? mesaj;
    bool basarili = false;
    String? kanal;
    try {
      final res = await http.post(
        Uri.parse('https://app.randevumcepte.com.tr/api/v1/anket-hizli-gonder'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'salon_id': salonId, 'user_id': userId}),
      ).timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        final j = jsonDecode(res.body);
        basarili = (j['basarili'] ?? false) as bool;
        mesaj = j['mesaj']?.toString();
        kanal = j['kanal']?.toString();
      } else {
        mesaj = 'İstek başarısız (HTTP ${res.statusCode})';
      }
    } catch (e) {
      mesaj = 'Ağ hatası: $e';
    }

    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // preloader kapat

    if (basarili) {
      final kText = kanal == 'whatsapp' ? 'WhatsApp' : 'SMS';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: const Color(0xFF25D366),
        content: Text('Anket $kText ile gönderildi'),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: const Color(0xFFD32F2F),
        content: Text(mesaj ?? 'Gönderilemedi'),
      ));
    }
  }

  // Ön görüşme satış popup'ları için ortak alan başlığı
  Widget _satisAlanLabel(String label, dynamic cs) {
    return Padding(
      padding: const EdgeInsets.only(left: 0.0),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, color: cs.onSurface, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Ön görüşme satış popup'ları için ortak sayısal giriş alanı
  Widget _satisNumField(TextEditingController controller, dynamic cs) {
    return Container(
      height: 40,
      padding: const EdgeInsets.only(left: 0, right: 20),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        maxLines: 1,
        decoration: InputDecoration(
          focusColor: cs.primary,
          hoverColor: cs.primary,
          hintStyle: TextStyle(color: cs.primary),
          contentPadding: const EdgeInsets.all(15.0),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: cs.primary),
            borderRadius: BorderRadius.circular(10.0),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: cs.primary),
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
      ),
    );
  }

  void paketsatispopup(BuildContext context, String ongorusmeid, {String musteriId = ''}) {
    final cs = context.colors;
    TextEditingController seansSayisi = TextEditingController();
    TextEditingController fiyat = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          scrollable: true,
          title: const Text(
            'Paket satışını tamamlamak için paket süresi, seans sayısı ve fiyatı giriniz.',
            style: TextStyle(fontSize: 14),
          ),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _satisAlanLabel('Seans Sayısı', cs),
              const SizedBox(height: 10),
              _satisNumField(seansSayisi, cs),
              const SizedBox(height: 10),
              _satisAlanLabel('Fiyat (₺)', cs),
              const SizedBox(height: 10),
              _satisNumField(fiyat, cs),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Kapat', style: TextStyle(color: cs.onSurface)),
            ),
            TextButton(
              onPressed: () {
                satisyapildi(context, ongorusmeid, '', '', '',
                    fiyat: fiyat.text, seansSayisi: seansSayisi.text,
                    onBasarili: () {
                      // Paket satışı kaydedildikten sonra tahsilat ekranına yönlendir
                      Navigator.push(
                        this.context,
                        MaterialPageRoute(
                          builder: (_) => TahsilatEkrani(
                            adisyonId: "",
                            kullanicirolu: widget.kullanicirolu,
                            isletmebilgi: widget.isletmebilgi,
                            musteridanisanid: musteriId,
                          ),
                        ),
                      ).then((_) => getUpdatedAppointments(
                            DateFormat('yyyy-MM-dd').format(seciliTarih),
                            DateFormat('yyyy-MM-dd').format(seciliTarih),
                            false,
                          ));
                    });
              },
              child: Text('Kaydet', style: TextStyle(color: cs.primary)),
            ),
          ],
        );
      },
    );
  }

  void urunsatispopup(BuildContext context, String ongorusmeid) {
    final cs = context.colors;
    TextEditingController quantityController = TextEditingController();
    TextEditingController fiyat = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          scrollable: true,
          title: const Text(
              'Ürün satışını tamamlamak için adet ve fiyatı giriniz.',
              style: TextStyle(fontSize: 16)
          ),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _satisAlanLabel('Adet', cs),
              const SizedBox(height: 10),
              _satisNumField(quantityController, cs),
              const SizedBox(height: 10),
              _satisAlanLabel('Fiyat (₺)', cs),
              const SizedBox(height: 10),
              _satisNumField(fiyat, cs),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Kapat', style: TextStyle(color: cs.onSurface)),
            ),
            TextButton(
              onPressed: () {
                satisyapildi(context, ongorusmeid, quantityController.text, '', '',
                    fiyat: fiyat.text);
                getUpdatedAppointments(
                    DateFormat('yyyy-MM-dd').format(seciliTarih),
                    DateFormat('yyyy-MM-dd').format(seciliTarih),
                    false
                );
              },
              child: Text('Kaydet', style: TextStyle(color: cs.primary)),
            ),
          ],
        );
      },
    );
  }

  void hizmetsatispopup(BuildContext context, String ongorusmeid) {
    final cs = context.colors;
    TextEditingController fiyat = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          scrollable: true,
          title: const Text(
              'Hizmet satışını tamamlamak için fiyatı giriniz.',
              style: TextStyle(fontSize: 16)
          ),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _satisAlanLabel('Fiyat (₺)', cs),
              const SizedBox(height: 10),
              _satisNumField(fiyat, cs),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Kapat', style: TextStyle(color: cs.onSurface)),
            ),
            TextButton(
              onPressed: () {
                satisyapildi(context, ongorusmeid, '', '', '', fiyat: fiyat.text);
                getUpdatedAppointments(
                    DateFormat('yyyy-MM-dd').format(seciliTarih),
                    DateFormat('yyyy-MM-dd').format(seciliTarih),
                    false
                );
              },
              child: Text('Kaydet', style: TextStyle(color: cs.primary)),
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
  final Color softLineColor;
  final Color strongLineColor;
  final Color hourTextColor;
  final Color halfTextColor;

  _SaatColumnPainter({
    required this.totalSlots,
    required this.slotHeight,
    required this.startTotalMinutes,
    required this.softLineColor,
    required this.strongLineColor,
    required this.hourTextColor,
    required this.halfTextColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = softLineColor
      ..strokeWidth = 1;
    final hourLinePaint = Paint()
      ..color = strongLineColor
      ..strokeWidth = 1;
    final borderPaint = Paint()
      ..color = strongLineColor
      ..strokeWidth = 1;

    final textStyle = TextStyle(fontSize: 12, color: hourTextColor, fontWeight: FontWeight.w500);
    final halfStyle = TextStyle(fontSize: 10, color: halfTextColor);

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
        oldDelegate.startTotalMinutes != startTotalMinutes ||
        oldDelegate.softLineColor != softLineColor ||
        oldDelegate.strongLineColor != strongLineColor ||
        oldDelegate.hourTextColor != hourTextColor ||
        oldDelegate.halfTextColor != halfTextColor;
  }
}

// ============================================================
// CUSTOM PAINTER: Grid çizgileri (her personel sütununda)
// ============================================================
class _GridLinesPainter extends CustomPainter {
  final int totalSlots;
  final double slotHeight;
  final Color softLineColor;
  final Color strongLineColor;

  _GridLinesPainter({
    required this.totalSlots,
    required this.slotHeight,
    required this.softLineColor,
    required this.strongLineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final softLine = Paint()
      ..color = softLineColor
      ..strokeWidth = 1;
    final strongLine = Paint()
      ..color = strongLineColor
      ..strokeWidth = 1;
    final rightBorder = Paint()
      ..color = softLineColor
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
        oldDelegate.slotHeight != slotHeight ||
        oldDelegate.softLineColor != softLineColor ||
        oldDelegate.strongLineColor != strongLineColor;
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
    final ext = context.appTheme;
    final displayHeight = _resizeHeight ?? widget.height;
    final color = widget.color;

    final resizeMinutes = _isResizing
        ? ((displayHeight / widget.slotHeight).round() * 15)
        : 0;

    // Yukseklige gore adaptif render. Backend 'subject'i \n ile coklu satir gonderir:
    //   [musteri (PAKET/ON GORUSME)]
    //   [hizmet/paket adi veya On Gorusme Nedeni:...]
    //   Olusturan:[Musteri (Web/Uygulama/Asistan) veya personel adi]
    //   [RANDEVUYA GELECEK]  (opsiyonel)
    // Tier'lar:
    // - tiny  (<28px, ~10dk):      handle gizli, fontSize 8.5, sadece "HH:MM musteri"
    // - short (28-44px, 15-20dk):  handle 8px, fontSize 9, "HH:MM-HH:MM musteri"
    // - normal (>=44px):           handle 16px, fontSize 10, tum bilgi gosterilir
    //                              (maxLines yukseklige gore hesaplanir)
    final bool isTiny = displayHeight < 28;
    final bool isShort = !isTiny && displayHeight < 44;
    final double handleHeight = isTiny ? 0 : (isShort ? 8 : 16);
    final EdgeInsets textPadding = isTiny
        ? const EdgeInsets.fromLTRB(3, 1, 3, 2)
        : (isShort
            ? const EdgeInsets.fromLTRB(3, 1, 3, 10)
            : const EdgeInsets.fromLTRB(4, 2, 4, 18));
    final double fontSize = isTiny ? 8.5 : (isShort ? 9 : 10);

    // Dinamik maxLines: padding harici alana kac satir sigarsa o kadar goster.
    final double approxLineHeight = fontSize * 1.15;
    final double availableTextHeight =
        displayHeight - textPadding.top - textPadding.bottom;
    final int dynamicMaxLines = isTiny
        ? 1
        : (isShort
            ? 1
            : (availableTextHeight / approxLineHeight).floor().clamp(2, 12));

    final String startTimeText = DateFormat.Hm().format(widget.appointment.startTime.toLocal());
    final String endTimeText = DateFormat.Hm().format(widget.appointment.endTime.toLocal());

    // Backend'in coklu satirini ayir. "Oluşturan:X" → "Oluşturan: X" (bosluk eksikti)
    final List<String> subjectLines = widget.appointment.subject.split('\n');
    final String musteriSatiri = subjectLines.isNotEmpty ? subjectLines[0] : '';
    final String detayBlogu = subjectLines.length > 1
        ? subjectLines
            .skip(1)
            .where((l) => l.trim().isNotEmpty)
            .map((l) => l.startsWith('Oluşturan:')
                ? 'Oluşturan: ${l.substring('Oluşturan:'.length).trim()}'
                : l)
            .join('\n')
        : '';

    final String contentText = _isResizing
        ? '$startTimeText • $resizeMinutes dk'
        : (isTiny
            // Tiny: sadece baslangic saati + musteri (paket etiketi dahil)
            ? '$startTimeText $musteriSatiri'
            : (isShort
                // Short: saat araligi + musteri tek satir
                ? '$startTimeText-$endTimeText $musteriSatiri'
                // Normal+: ilk satir saat+musteri, alt satirlarda hizmet/olusturan
                : (detayBlogu.isEmpty
                    ? '$startTimeText-$endTimeText $musteriSatiri'
                    : '$startTimeText-$endTimeText $musteriSatiri\n$detayBlogu')));

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
                  color: ext.shadowBase.withValues(alpha: 0.25),
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
            maxLines: dynamicMaxLines,
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


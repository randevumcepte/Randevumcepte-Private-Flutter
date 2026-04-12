import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../Backend/backend.dart';
import '../../../../Models/musteri_danisanlar.dart';
import '../../../../Models/user.dart';
import '../musteriler/musteridetaylar.dart';

class SalesReportsPersonelPage extends StatefulWidget {
  final dynamic isletmebilgi;
  final int kullanicirolu;
  final Kullanici kullanici; // Personel bilgisi için eklendi

  SalesReportsPersonelPage({
    Key? key,
    required this.isletmebilgi,
    required this.kullanicirolu,
    required this.kullanici, // Personel bilgisi eklendi
  }) : super(key: key);

  @override
  _SalesReportsPersonelPageState createState() => _SalesReportsPersonelPageState();
}

class _SalesReportsPersonelPageState extends State<SalesReportsPersonelPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['Hizmet', 'Ürün', 'Paket'];

  double toplamSatisTutari = 0;
  double toplamKazanc = 0;
  double toplamAlacak = 0;
  double toplamSatisTutariUrun = 0;
  double toplamKazancUrun = 0;
  double toplamAlacakUrun = 0;
  double toplamSatisTutariPaket = 0;
  double toplamKazancPaket = 0;
  double toplamAlacakPaket = 0;

  // Varsayılan tarih aralığı
  final DateTimeRange _defaultDateRange = DateTimeRange(
    start: DateTime(DateTime.now().year, DateTime.now().month, 1),
    end: DateTime.now(),
  );

  final Map<String, DateTimeRange?> _selectedDateRanges = {
    'Hizmet': DateTimeRange(
      start: DateTime(DateTime.now().year, DateTime.now().month, 1),
      end: DateTime.now(),
    ),
    'Ürün': DateTimeRange(
      start: DateTime(DateTime.now().year, DateTime.now().month, 1),
      end: DateTime.now(),
    ),
    'Paket': DateTimeRange(
      start: DateTime(DateTime.now().year, DateTime.now().month, 1),
      end: DateTime.now(),
    ),
  };

  bool isLoading = true;
  bool _showFilters = false;
  bool _isFilterActive = false;
  final DateFormat _dateFormat = DateFormat('dd.MM.yyyy');
  final tlFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '');
  final Map<String, bool> _expandedCards = {};

  late List<dynamic> hizmetRaporu;
  late List<dynamic> urunRaporu;
  late List<dynamic> paketRaporu;

  // Personel ID'sini al
  String _getPersonelId() {
    String personelId = "";

    // Personel ID'sini yetkili olunan işletmelerden bul
    widget.kullanici.yetkili_olunan_isletmeler.forEach((element) {
      if (element["salon_id"].toString() == widget.isletmebilgi["id"].toString()) {
        personelId = element["id"].toString();
      }
    });

    return personelId;
  }

  @override
  void initState() {
    super.initState();
    initialize();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      _checkFilterStatus();
    });
  }

  void _checkFilterStatus() {
    final currentTab = _tabs[_tabController.index];
    final isDateDefault = _selectedDateRanges[currentTab]?.start == _defaultDateRange.start &&
        _selectedDateRanges[currentTab]?.end == _defaultDateRange.end;

    setState(() {
      _isFilterActive = !isDateDefault;
    });
  }

  void initialize() async {
    setState(() {
      isLoading = true;
    });

    // Personel ID'sini al
    final personelId = _getPersonelId();

    // Sıfırla
    toplamSatisTutari = 0;
    toplamKazanc = 0;
    toplamAlacak = 0;
    toplamSatisTutariUrun = 0;
    toplamKazancUrun = 0;
    toplamAlacakUrun = 0;
    toplamSatisTutariPaket = 0;
    toplamKazancPaket = 0;
    toplamAlacakPaket = 0;

    // Hizmet raporlarını personel ID'si ile al
    hizmetRaporu = await hizmetRaporlari(
      widget.isletmebilgi['id'].toString(),
      DateFormat('yyyy-MM-dd').format(_selectedDateRanges['Hizmet']!.start),
      DateFormat('yyyy-MM-dd').format(_selectedDateRanges['Hizmet']!.end),
      personelId, // Personel ID'sini ekledik
    );

    // Ürün raporlarını personel ID'si ile al
    urunRaporu = await urunRaporlari(
      widget.isletmebilgi['id'].toString(),
      DateFormat('yyyy-MM-dd').format(_selectedDateRanges['Ürün']!.start),
      DateFormat('yyyy-MM-dd').format(_selectedDateRanges['Ürün']!.end),
      personelId, // Personel ID'sini ekledik
    );

    // Paket raporlarını personel ID'si ile al
    paketRaporu = await paketRaporlari(
      widget.isletmebilgi['id'].toString(),
      DateFormat('yyyy-MM-dd').format(_selectedDateRanges['Paket']!.start),
      DateFormat('yyyy-MM-dd').format(_selectedDateRanges['Paket']!.end),
      personelId, // Personel ID'sini ekledik
    );

    // Toplamları hesapla
    hizmetRaporu.forEach((element) {
      setState(() {
        toplamSatisTutari += element['toplamTutarNumeric'];
        toplamKazanc += element['toplamKazancNumeric'];
        toplamAlacak += element['borcNumeric'];
      });
    });

    urunRaporu.forEach((element) {
      setState(() {
        toplamSatisTutariUrun += element['toplamTutarNumeric'];
        toplamKazancUrun += element['toplamKazancNumeric'];
        toplamAlacakUrun += element['borcNumeric'];
      });
    });

    paketRaporu.forEach((element) {
      setState(() {
        toplamSatisTutariPaket += element['toplamTutarNumeric'];
        toplamKazancPaket += element['toplamKazancNumeric'];
        toplamAlacakPaket += element['borcNumeric'];
      });
    });

    setState(() {
      isLoading = false;
      _checkFilterStatus();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _toggleFilters() {
    setState(() {
      _showFilters = !_showFilters;
    });
  }

  void _resetFilters() {
    final currentTab = _tabs[_tabController.index];

    setState(() {
      _selectedDateRanges[currentTab] = DateTimeRange(
        start: _defaultDateRange.start,
        end: _defaultDateRange.end,
      );
      _isFilterActive = false;
    });

    initialize();
  }

  void _resetAllFilters() {
    setState(() {
      _selectedDateRanges.forEach((key, value) {
        _selectedDateRanges[key] = DateTimeRange(
          start: _defaultDateRange.start,
          end: _defaultDateRange.end,
        );
      });
      _isFilterActive = false;
    });

    initialize();
  }

  void _showDateFilter(BuildContext context, String tab) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Zaman Aralığı Seç',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        if (_selectedDateRanges[tab] != null &&
                            (_selectedDateRanges[tab]!.start != _defaultDateRange.start ||
                                _selectedDateRanges[tab]!.end != _defaultDateRange.end))
                          IconButton(
                            icon: Icon(Icons.refresh, color: Colors.orange),
                            onPressed: () {
                              Navigator.pop(context);
                              setState(() {
                                _selectedDateRanges[tab] = DateTimeRange(
                                  start: _defaultDateRange.start,
                                  end: _defaultDateRange.end,
                                );
                              });
                              initialize();
                            },
                            tooltip: 'Tarihi Sıfırla',
                          ),
                        IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              ..._getQuickDateOptions(tab).map((option) => ListTile(
                leading: Icon(_getDateOptionIcon(option['label'] as String),
                    size: 22),
                title: Text(option['label'] as String),
                trailing: option['range'] == _selectedDateRanges[tab]
                    ? Icon(Icons.check_circle, color: Colors.blue, size: 22)
                    : null,
                onTap: () {
                  setState(() {
                    _selectedDateRanges[tab] = option['range'] as DateTimeRange?;
                  });
                  initialize();
                  Navigator.pop(context);
                },
              )).toList(),
              Divider(height: 20),
              ListTile(
                leading: Icon(Icons.date_range, size: 22),
                title: Text('Özel Tarih Aralığı'),
                trailing: Icon(Icons.chevron_right, size: 22),
                onTap: () => _showCustomDatePicker(context, tab),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showCustomDatePicker(BuildContext context, String tab) async {
    Navigator.pop(context);

    DateTime? startDate = _selectedDateRanges[tab]?.start;
    DateTime? endDate = _selectedDateRanges[tab]?.end;

    await showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              contentPadding: EdgeInsets.zero,
              content: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade400,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        gradient: LinearGradient(
                          colors: [Colors.purple.shade400, Colors.purple.shade400],
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_month, color: Colors.white, size: 28),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'TARİH ARALIĞI SEÇİN',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          if (startDate != null || endDate != null)
                            IconButton(
                              icon: Icon(Icons.refresh, color: Colors.white),
                              onPressed: () {
                                Navigator.pop(context);
                                setState(() {
                                  _selectedDateRanges[tab] = DateTimeRange(
                                    start: _defaultDateRange.start,
                                    end: _defaultDateRange.end,
                                  );
                                });
                                initialize();
                              },
                              tooltip: 'Tarihi Sıfırla',
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        children: [
                          InkWell(
                            onTap: () async {
                              final DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: startDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                                builder: (context, child) {
                                  return Theme(
                                    data: ThemeData.light().copyWith(
                                      colorScheme: ColorScheme.light(
                                        primary: Colors.purple.shade400,
                                        onPrimary: Colors.white,
                                      ),
                                      dialogBackgroundColor: Colors.white,
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                setState(() => startDate = picked);
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: startDate != null ? Colors.purple : Colors.grey,
                                  width: startDate != null ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_outlined,
                                    color: startDate != null ? Colors.purple : Colors.grey[500],
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'BAŞLANGIÇ TARİHİ',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          startDate != null
                                              ? _dateFormat.format(startDate!)
                                              : 'Tarih Seçin',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: startDate != null ? Colors.black87 : Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (startDate != null)
                                    IconButton(
                                      icon: Icon(Icons.clear, size: 20),
                                      onPressed: () => setState(() => startDate = null),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          InkWell(
                            onTap: () async {
                              final DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: endDate ?? DateTime.now(),
                                firstDate: startDate ?? DateTime(2020),
                                lastDate: DateTime(2030),
                                builder: (context, child) {
                                  return Theme(
                                    data: ThemeData.light().copyWith(
                                      colorScheme: ColorScheme.light(
                                        primary: Colors.purple.shade200,
                                        onPrimary: Colors.white,
                                      ),
                                      dialogBackgroundColor: Colors.white,
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                setState(() => endDate = picked);
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: endDate != null ? Colors.purple : Colors.grey,
                                  width: endDate != null ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_outlined,
                                    color: endDate != null ? Colors.purple : Colors.grey[500],
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'BİTİŞ TARİHİ',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          endDate != null
                                              ? _dateFormat.format(endDate!)
                                              : 'Tarih Seçin',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: endDate != null ? Colors.black87 : Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (endDate != null)
                                    IconButton(
                                      icon: Icon(Icons.clear, size: 20),
                                      onPressed: () => setState(() => endDate = null),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 24),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                        border: Border(top: BorderSide(color: Colors.grey)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.grey[600],
                                padding: EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text('İPTAL'),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: startDate != null && endDate != null
                                  ? () {
                                if (endDate!.isBefore(startDate!)) {
                                  final temp = startDate;
                                  startDate = endDate;
                                  endDate = temp;
                                }
                                Navigator.pop(context);
                                setState(() {
                                  _selectedDateRanges[tab] = DateTimeRange(
                                    start: startDate!,
                                    end: endDate!,
                                  );
                                });
                                initialize();
                              }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple.shade400,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                disabledBackgroundColor: Colors.grey[300],
                              ),
                              child: Text('UYGULA'),
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
      },
    );
  }

  List<Map<String, dynamic>> _getQuickDateOptions(String tab) {
    final now = DateTime.now();
    return [
      {
        'label': 'Bugün',
        'range': DateTimeRange(
          start: DateTime(now.year, now.month, now.day),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        ),
      },
      {
        'label': 'Dün',
        'range': DateTimeRange(
          start: DateTime(now.year, now.month, now.day - 1),
          end: DateTime(now.year, now.month, now.day - 1, 23, 59, 59),
        ),
      },
      {
        'label': 'Bu Ay',
        'range': DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
        ),
      },
      {
        'label': 'Geçen Ay',
        'range': DateTimeRange(
          start: DateTime(now.year, now.month - 1, 1),
          end: DateTime(now.year, now.month, 0, 23, 59, 59),
        ),
      },
      {
        'label': 'Bu Yıl',
        'range': DateTimeRange(
          start: DateTime(now.year, 1, 1),
          end: DateTime(now.year, 12, 31, 23, 59, 59),
        ),
      },
      {
        'label': 'Geçen Yıl',
        'range': DateTimeRange(
          start: DateTime(now.year - 1, 1, 1),
          end: DateTime(now.year - 1, 12, 31, 23, 59, 59),
        ),
      },
    ];
  }

  IconData _getDateOptionIcon(String label) {
    switch (label) {
      case 'Bugün':
        return Icons.today_outlined;
      case 'Dün':
        return Icons.history_outlined;
      case 'Bu Ay':
        return Icons.calendar_month_outlined;
      case 'Geçen Ay':
        return Icons.calendar_today_outlined;
      case 'Bu Yıl':
        return Icons.event_note_outlined;
      case 'Geçen Yıl':
        return Icons.history_toggle_off_outlined;
      default:
        return Icons.date_range_outlined;
    }
  }

  void _toggleCardExpansion(String cardId) {
    setState(() {
      _expandedCards[cardId] = !(_expandedCards[cardId] ?? false);
    });
  }

  void _showMusteriListesiPopup(BuildContext context, String type, dynamic item) async {
    List<dynamic> musteriler = [];
    String salonId = widget.isletmebilgi['id'].toString();
    String tarih1 = DateFormat('yyyy-MM-dd').format(_selectedDateRanges[type]!.start);
    String tarih2 = DateFormat('yyyy-MM-dd').format(_selectedDateRanges[type]!.end);
    String personelId = _getPersonelId(); // Personel ID'sini al

    try {
      switch (type) {
        case 'Hizmet':
          musteriler = await hizmetMusteriListesiGetir(
              salonId,
              item['hizmet_id'].toString(),
              tarih1,
              tarih2,
               personelId // Personel ID'sini ekle
          );
          break;
        case 'Ürün':
          musteriler = await urunMusteriListesiGetir(
              salonId,
              item['urun_id'].toString(),
              tarih1,
              tarih2,
              personelId // Personel ID'sini ekle
          );
          break;
        case 'Paket':
          musteriler = await paketMusteriListesiGetir(
              salonId,
              item['paket_id'].toString(),
              tarih1,
              tarih2,
              personelId // Personel ID'sini ekle
          );
          break;
      }
    } catch (e) {
      print('Müşteri listesi getirme hatası: $e');
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Müşteri Listesi',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${item['${type.toLowerCase()}_adi']}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue[700],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${musteriler.length} müşteri bulundu',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[600],
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 24, color: Colors.blue[700]),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: musteriler.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Müşteri bulunamadı',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Bu ${type.toLowerCase()} için müşteri kaydı yok',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: musteriler.length,
                itemBuilder: (context, index) {
                  final musteri = musteriler[index];
                  return _buildMusteriCard(context, musteri, index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMusteriCard(BuildContext context, dynamic musteri, int index) {
    MusteriDanisan md = MusteriDanisan.fromJson(musteri);
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MusteriDetaylari(
              md: md,
              isletmebilgi: widget.isletmebilgi,
              kullanicirolu: widget.kullanicirolu,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
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
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.blue[100],
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  musteri['name']?.substring(0, 1).toUpperCase() ?? 'M',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    musteri['name'] ?? 'Müşteri',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  if (musteri['cep_telefon'] != null)
                    Row(
                      children: [
                        Icon(
                          Icons.phone_outlined,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: 6),
                        Text(
                          musteri['cep_telefon'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      'Telefon kaydı yok',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  SizedBox(height: 4),
                  if (musteri['email'] != null)
                    Row(
                      children: [
                        Icon(
                          Icons.email_outlined,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            musteri['email'],
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.blue[700],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Personel Satış Raporları', // Başlığı değiştirdik
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_isFilterActive && _showFilters)
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.orange),
              onPressed: _resetAllFilters,
              tooltip: 'Tüm Filtreleri Sıfırla',
            ),
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_alt : Icons.filter_alt_outlined,
              size: 24,
              color: _isFilterActive ? Colors.blue : null,
            ),
            onPressed: _toggleFilters,
            tooltip: 'Filtrele',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs.map((tab) => Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  tab,
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                if (_selectedDateRanges[tab] != null &&
                    (_selectedDateRanges[tab]!.start != _defaultDateRange.start ||
                        _selectedDateRanges[tab]!.end != _defaultDateRange.end))
                  Container(
                    margin: EdgeInsets.only(left: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          )).toList(),
          labelColor: Colors.purple,
          unselectedLabelColor: Colors.grey[600],
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorWeight: 3,
          indicatorColor: Colors.purple,
        ),
      ),
      body: Column(
        children: [
          // Personel bilgisi banner'ı
          Container(
            padding: EdgeInsets.all(12),
            color: Colors.blue[50],
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person, color: Colors.blue[800]),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.kullanici.name ?? 'Personel',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                      ),
                      Text(
                        'Kendi Satış Raporları',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (_showFilters) _buildFilterSection(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildServiceReports(),
                _buildProductReports(),
                _buildPackageReports(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    final currentTab = _tabs[_tabController.index];
    final dateRange = _selectedDateRanges[currentTab];
    final isDateActive = dateRange != null &&
        (dateRange.start != _defaultDateRange.start ||
            dateRange.end != _defaultDateRange.end);

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filtreler',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              if (isDateActive)
                InkWell(
                  onTap: _resetFilters,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.refresh, size: 16, color: Colors.orange),
                        SizedBox(width: 4),
                        Text(
                          'Sıfırla',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 12),
          _buildFilterCard(
            icon: Icons.calendar_today_outlined,
            title: 'Zaman Aralığı',
            subtitle: dateRange != null
                ? '${_dateFormat.format(dateRange.start)} - ${_dateFormat.format(dateRange.end)}'
                : 'Tüm Zamanlar',
            onTap: () => _showDateFilter(context, currentTab),
            color: Colors.blue,
            isActive: isDateActive,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
    bool isActive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? color : color.withOpacity(0.3),
            width: isActive ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isActive ? color : color.withOpacity(0.7), size: 20),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isActive ? color : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            if (isActive)
              Container(
                margin: EdgeInsets.only(right: 8),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            Icon(Icons.arrow_drop_down, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceReports() {
    return isLoading
        ? Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(
            title: 'Hizmet Özeti',
            icon: Icons.medical_services_outlined,
            color: Colors.blue,
            totalAmount: tlFormat.format(toplamSatisTutari) + ' ₺',
            stats: [
              _StatInfo(
                  label: 'Toplam Kazanç',
                  value: tlFormat.format(toplamKazanc) + ' ₺',
                  change: '+12%'),
              _StatInfo(
                  label: 'Kalan Alacak',
                  value: tlFormat.format(toplamAlacak) + ' ₺',
                  change: '-8%'),
            ],
          ),
          SizedBox(height: 20),
          Text('Hizmet Detayları',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              )),
          SizedBox(height: 12),
          ...hizmetRaporu.asMap().entries.map((entry) {
            int index = entry.key;
            var item = entry.value;
            return _buildExpandableServiceCard(item, index);
          }).toList(),
          if (hizmetRaporu.isEmpty) _buildEmptyState('hizmet'),
        ],
      ),
    );
  }

  Widget _buildProductReports() {
    return isLoading
        ? Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(
            title: 'Ürün Özeti',
            icon: Icons.shopping_bag_outlined,
            color: Colors.green,
            totalAmount: tlFormat.format(toplamSatisTutariUrun) + ' ₺',
            stats: [
              _StatInfo(
                  label: 'Toplam Kazanç',
                  value: tlFormat.format(toplamKazancUrun) + ' ₺',
                  change: '+8%'),
              _StatInfo(
                  label: 'Kalan Alacak',
                  value: tlFormat.format(toplamAlacakUrun) + ' ₺',
                  change: '-12%'),
            ],
          ),
          SizedBox(height: 20),
          Text('Ürün Detayları',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              )),
          SizedBox(height: 12),
          ...urunRaporu.asMap().entries.map((entry) {
            int index = entry.key;
            var item = entry.value;
            return _buildExpandableProductCard(item, index);
          }).toList(),
          if (urunRaporu.isEmpty) _buildEmptyState('ürün'),
        ],
      ),
    );
  }

  Widget _buildPackageReports() {
    return isLoading
        ? Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(
            title: 'Paket Özeti',
            icon: Icons.card_giftcard_outlined,
            color: Colors.purple,
            totalAmount: tlFormat.format(toplamSatisTutariPaket) + ' ₺',
            stats: [
              _StatInfo(
                  label: 'Toplam Kazanç',
                  value: tlFormat.format(toplamKazancPaket) + ' ₺',
                  change: '+15%'),
              _StatInfo(
                  label: 'Kalan Alacak',
                  value: tlFormat.format(toplamAlacakPaket) + ' ₺',
                  change: '-5%'),
            ],
          ),
          SizedBox(height: 20),
          Text('Paket Detayları',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              )),
          SizedBox(height: 12),
          ...paketRaporu.asMap().entries.map((entry) {
            int index = entry.key;
            var item = entry.value;
            return _buildExpandablePackageCard(item, index);
          }).toList(),
          if (paketRaporu.isEmpty) _buildEmptyState('paket'),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String type) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'Satış Raporu Yok',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Bu tarih aralığında $type satışı bulunmuyor',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required IconData icon,
    required Color color,
    required String totalAmount,
    required List<_StatInfo> stats,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          )),
                      SizedBox(height: 4),
                      Text('Toplam Gelir',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          )),
                    ],
                  ),
                ),
                Text(totalAmount,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    )),
              ],
            ),
            SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
              ),
              itemCount: stats.length,
              itemBuilder: (context, index) {
                final stat = stats[index];
                return Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(stat.label,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          )),
                      SizedBox(height: 4),
                      Text(stat.value,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          )),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableServiceCard(Map<String, dynamic> item, int index) {
    final cardId = 'service_$index';
    final isExpanded = _expandedCards[cardId] ?? false;

    final List<Map<String, dynamic>> details = [
      {
        'label': 'Satış Adeti',
        'value': '${item['adet']}',
        'icon': Icons.format_list_numbered_outlined
      },
      {
        'label': 'Hizmet Geliri',
        'value': '${item['toplam_tutar']} ₺',
        'icon': Icons.attach_money_outlined
      },
      {
        'label': 'Toplam Kazanç',
        'value': '${item['toplamKazanc']} ₺',
        'icon': Icons.trending_up_outlined
      },
      {
        'label': 'Kalan Alacak',
        'value': '${item['borc']} ₺',
        'icon': Icons.pending_actions_outlined
      },
    ];

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.spa_outlined, color: Colors.blue, size: 24),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['hizmet_adi'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => _showMusteriListesiPopup(context, 'Hizmet', item),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.people_outline,
                      size: 20,
                      color: Colors.blue,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                InkWell(
                  onTap: () => _toggleCardExpansion(cardId),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 20,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            if (isExpanded) ...[
              SizedBox(height: 16),
              Divider(height: 1),
              SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.8,
                ),
                itemCount: details.length,
                itemBuilder: (context, subIndex) {
                  final detail = details[subIndex];
                  final iconData = detail['icon'] as IconData;
                  return Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Icon(iconData, color: Colors.blue, size: 16),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                detail['label']! as String,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          detail['value']! as String,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableProductCard(Map<String, dynamic> item, int index) {
    final cardId = 'product_$index';
    final isExpanded = _expandedCards[cardId] ?? false;

    final List<Map<String, dynamic>> details = [
      {
        'label': 'Satış Adeti',
        'value': '${item['adet']}',
        'icon': Icons.format_list_numbered_outlined
      },
      {
        'label': 'Ürün Geliri',
        'value': '${item['toplam_tutar']} ₺',
        'icon': Icons.monetization_on_outlined
      },
      {
        'label': 'Toplam Kazanç',
        'value': '${item['toplamKazanc']} ₺',
        'icon': Icons.trending_up_outlined
      },
      {
        'label': 'Kalan Alacak',
        'value': '${item['borc']} ₺',
        'icon': Icons.pending_outlined
      },
    ];

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.shopping_basket_outlined, color: Colors.green, size: 24),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['urun_adi'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => _showMusteriListesiPopup(context, 'Ürün', item),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.people_outline,
                      size: 20,
                      color: Colors.green,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                InkWell(
                  onTap: () => _toggleCardExpansion(cardId),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 20,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            if (isExpanded) ...[
              SizedBox(height: 16),
              Divider(height: 1),
              SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.8,
                ),
                itemCount: details.length,
                itemBuilder: (context, subIndex) {
                  final detail = details[subIndex];
                  final iconData = detail['icon'] as IconData;
                  return Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Icon(iconData, color: Colors.green, size: 16),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                detail['label']! as String,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          detail['value']! as String,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExpandablePackageCard(Map<String, dynamic> item, int index) {
    final cardId = 'package_$index';
    final isExpanded = _expandedCards[cardId] ?? false;

    final List<Map<String, dynamic>> details = [
      {
        'label': 'Satış Adeti',
        'value': '${item['adet']}',
        'icon': Icons.format_list_numbered_outlined
      },
      {
        'label': 'Paket Geliri',
        'value': '${item['toplam_tutar']} ₺',
        'icon': Icons.account_balance_wallet_outlined
      },
      {
        'label': 'Toplam Kazanç',
        'value': '${item['toplamKazanc']} ₺',
        'icon': Icons.bar_chart_outlined
      },
      {
        'label': 'Kalan Alacak',
        'value': '${item['borc']} ₺',
        'icon': Icons.schedule_outlined
      },
    ];

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.all_inclusive_outlined,
                      color: Colors.purple, size: 24),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['paket_adi'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => _showMusteriListesiPopup(context, 'Paket', item),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.people_outline,
                      size: 20,
                      color: Colors.purple,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                InkWell(
                  onTap: () => _toggleCardExpansion(cardId),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 20,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            if (isExpanded) ...[
              SizedBox(height: 16),
              Divider(height: 1),
              SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.8,
                ),
                itemCount: details.length,
                itemBuilder: (context, subIndex) {
                  final detail = details[subIndex];
                  final iconData = detail['icon'] as IconData;
                  return Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.purple.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Icon(iconData, color: Colors.purple, size: 16),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                detail['label']! as String,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          detail['value']! as String,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatInfo {
  final String label;
  final String value;
  final String change;

  _StatInfo({
    required this.label,
    required this.value,
    required this.change,
  });
}
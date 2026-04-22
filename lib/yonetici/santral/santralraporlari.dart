import 'dart:convert';
import 'dart:developer';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:randevu_sistem/Frontend/datetimeformatting.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:randevu_sistem/yonetici/santral/callkit/main.dart';
import 'package:randevu_sistem/yonetici/santral/sipsrc/callscreen.dart';
import 'package:randevu_sistem/yonetici/santral/sipsrc/dialpad.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import '../../../../Frontend/popupdialogs.dart';
import '../../../../Models/randevular.dart';

import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Frontend/altyuvarlakmenu.dart';
import 'package:randevu_sistem/Models/form.dart';
import 'package:randevu_sistem/Frontend/sfdatatable.dart';

import '../../Frontend/dialpad.dart';
import '../../Frontend/filedownload.dart';
import '../../Frontend/indexedstack.dart';
import '../../Models/cdr.dart';
import '../../Models/personel.dart';
import '../../Models/sipclient.dart';
import '../../Models/user.dart';
import '../../main.dart';
import '../diger/menu/musteriler/yeni_musteri.dart';
import 'arama.dart';
import 'arama.dart';
//import 'package:sip_ua/sip_ua.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:share_plus/share_plus.dart';

class CDRRaporlari extends StatefulWidget {
  final dynamic isletmebilgi;
  final DialPadManager dialPadManager;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;
  final Kullanici kullanici;
  final int kullanicirolu;

  const CDRRaporlari({
    Key? key,
    required this.isletmebilgi,
    required this.dialPadManager,
    required this.scaffoldMessengerKey,
    required this.kullanici,
    required this.kullanicirolu
  }) : super(key: key);

  @override
  _CDRState createState() => _CDRState();
}

class _CDRState extends State<CDRRaporlari> {
  ScrollController _scrollController = ScrollController();
  DateTime _sonYuklenenTarih = DateTime.now();
  ValueNotifier<int> downloadProgressNotifier = ValueNotifier(0);
  SnackBar? currentSnackbar;
  bool isSnackbarVisible = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  late OverlayEntry _dialPadOverlayEntry;
  List<bool> _menuVisibility = [];
  List<Cdr> items = [];
  List<Cdr> filteredItems = [];
  late RandevuDataSource _randevuDataGridSource;
  List<Randevu> _randevu = [];
  late List<Randevu> _filteredRandevu = [];
  late String? seciliisletme;
  bool _isLoading = true;
  bool verigetiriliyor = false;
  int totalPages = 1;
  DateTime? startDate;
  DateTime? endDate;
  List<String> dahililer = [];
  String _searchQuery = '';

  TextEditingController baslangictarihi = TextEditingController();
  TextEditingController bitistarihi = TextEditingController();
  TextEditingController _searchController = TextEditingController();

  int _currentOffset = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();

    // Başlangıç ve bitiş tarihlerini ayarla
    DateTime now = DateTime.now();
    DateTime lastWeekStart = now.subtract(Duration(days: 7));
    DateTime lastWeekEnd = now;

    // YENİ EKLENECEK değişkenler
    int _currentOffset = 0;
    bool _hasMore = true;
    bool _isLoadingMore = false;

    initialize();

    _scrollController.addListener(() {
      _kontrolListeBoyutu();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _kontrolListeBoyutu();
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> initialize() async {
    setState(() {
      _isLoading = true;
      _currentOffset = 0;      // YENİ
      _hasMore = true;          // YENİ
      items.clear();            // YENİ
      filteredItems.clear();    // YENİ
    });

    List<Personel> personelListesi = [];
    seciliisletme = widget.isletmebilgi['id']?.toString();

    if (seciliisletme == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    var personellerRaw = widget.isletmebilgi['personeller'];

    if (personellerRaw != null && personellerRaw is List) {
      personelListesi = personellerRaw.map((e) => Personel.fromJson(e)).toList();
    } else {
      personelListesi = [];
    }

    dahililer.clear();
    for (var element in personelListesi) {
      if (element.dahili_no != 'null') dahililer.add(element.dahili_no);
    }

    // YENİ: İlk verileri sayfalı olarak yükle
    await _loadMoreData();

    setState(() {
      _isLoading = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(Duration(milliseconds: 100), () {
        if (mounted) {
          _kontrolListeBoyutu();
        }
      });
    });
  }

  void _kontrolListeBoyutu() {
    if (!_scrollController.hasClients) return;

    final double maxScrollExtent = _scrollController.position.maxScrollExtent;
    final double viewportHeight = _scrollController.position.viewportDimension;

    if ((maxScrollExtent < viewportHeight || _scrollController.position.pixels >= maxScrollExtent) && !verigetiriliyor) {
      _loadMoreData();
    }
  }
  Future<void> _loadMoreData() async {
    if (_isLoadingMore || !_hasMore) return;

    String baslangic = baslangictarihi.text.isEmpty
        ? DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(Duration(days: 7)))
        : baslangictarihi.text;
    String bitis = bitistarihi.text.isEmpty
        ? DateFormat('yyyy-MM-dd').format(DateTime.now())
        : bitistarihi.text;

    log('Yükleniyor - offset: $_currentOffset, baslangic: $baslangic, bitis: $bitis');

    setState(() {
      _isLoadingMore = true;
      verigetiriliyor = true;
    });

    try {
      List<Cdr> yeniVeriler = await santralraporlari(
        seciliisletme!,
        baslangic,
        bitis,
        _currentOffset,
        _searchController.text ?? ""
      );

      log('Gelen veri sayısı: ${yeniVeriler.length}');

      setState(() {
        if (yeniVeriler.length < 50) {
          // Sayfa boyutundan az geldiyse daha fazla veri yoktur
          _hasMore = false;
          log('_hasMore = false (gelen: ${yeniVeriler.length}, pageSize: 50)');
        }

        items.addAll(yeniVeriler);
        _currentOffset += yeniVeriler.length;

        // Arama filtresi aktifse filtreyi koru
        if (_searchQuery.isNotEmpty) {
          filteredItems = items.where((item) {
            return item.musteri.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                item.telefon.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();
        } else {
          filteredItems = List.from(items);
        }

        _menuVisibility = List.generate(filteredItems.length, (_) => false);
      });
    } catch (e) {
      log('Veri yükleme hatası: $e');
    } finally {
      setState(() {
        _isLoadingMore = false;
        verigetiriliyor = false;
      });
    }
  }
  void filterSearchResults(String query) {
    setState(() {
      _searchQuery = query;
    });

    DateTime? start = startDate;
    DateTime? end = endDate;

    if (query.isNotEmpty || (start != null && end != null)) {
      setState(() {
        filteredItems = items.where((item) {
          bool matchesQuery = item.musteri.toLowerCase().contains(query.toLowerCase()) ||
              item.telefon.toLowerCase().contains(query.toLowerCase());

          DateTime itemDate;
          try {
            itemDate = DateTime.parse(item.tarih);
          } catch (e) {
            return false;
          }

          bool matchesDate = (start == null || itemDate.isAfter(start)) &&
              (end == null || itemDate.isBefore(end));

          return matchesQuery && matchesDate;
        }).toList();
      });
    } else {
      setState(() {
        filteredItems = items;
      });
    }
  }

  void _resetFilters() {
    setState(() {
      baslangictarihi.text = '';
      bitistarihi.text = '';
      startDate = null;
      endDate = null;
      _searchController.clear();
      _searchQuery = '';
      // YENİ: Sayfalama değişkenlerini sıfırla
      _currentOffset = 0;
      _hasMore = true;
      items.clear();
      filteredItems.clear();
    });
    initialize(); // Yeniden yükle
  }
  @override
  Widget build(BuildContext context) {
    final double height = MediaQuery.of(context).size.height;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Santral Raporları',
          style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.w600
          ),
        ),
        toolbarHeight: 70,
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        elevation: 1,
        shadowColor: Colors.black12,
        actions: <Widget>[
          if (widget.isletmebilgi["demo_hesabi"].toString() == "1")
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: SizedBox(
                  width: 100,
                  child: YukseltButonu(isletme_bilgi: widget.isletmebilgi)
              ),
            ),
          _buildActionButton(
              icon: Icons.filter_list_alt,
              onPressed: _showFilterBottomSheet,
              tooltip: 'Filtrele'
          ),
          /*_buildActionButton(
              icon: Icons.phone,
              onPressed: () {
                /*widget.dialPadManager.updateDialPad(
                    context, true, "", widget.kullanici
                );*/
              },
              tooltip: 'Tuş Takımı'
          ),*/
        ],
      ),
      body: Container(
        color: isDark ? Colors.grey[850] : Colors.grey[50],
        child: Column(
          children: [
            // Arama ve Filtre Bilgisi
            //_buildSearchAndFilterSection(isDark),

            // İçerik
            Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : filteredItems.isEmpty
                    ? _buildEmptyState()
                    : _buildCallList(isDark)
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Tooltip(
        message: tooltip,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).primaryColor.withOpacity(0.1),
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(
              icon,
              color: Theme.of(context).primaryColor,
              size: 22,
            ),
            padding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilterSection(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Arama Bar
          /*Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: filterSearchResults,
              decoration: InputDecoration(
                hintText: 'Müşteri adı veya telefon numarası ara...',
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                suffixIcon: _searchQuery.isNotEmpty ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    filterSearchResults('');
                  },
                ) : null,
              ),
            ),
          ),*/

          SizedBox(height: 12),

          // Filtre Bilgisi
          if (startDate != null || endDate != null || _searchQuery.isNotEmpty)
            _buildActiveFilters(isDark),
        ],
      ),
    );
  }

  Widget _buildActiveFilters(bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.filter_alt, size: 16, color: Theme.of(context).primaryColor),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              _getFilterSummary(),
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: _resetFilters,
            child: Text(
              'Temizle',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getFilterSummary() {
    List<String> filters = [];

    if (_searchQuery.isNotEmpty) {
      filters.add('Arama: "$_searchQuery"');
    }

    if (startDate != null) {
      filters.add('Başlangıç: ${DateFormat('dd.MM.yyyy').format(startDate!)}');
    }

    if (endDate != null) {
      filters.add('Bitiş: ${DateFormat('dd.MM.yyyy').format(endDate!)}');
    }

    return filters.join(' • ');
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
          ),
          SizedBox(height: 16),
          Text(
            'Santral raporları yükleniyor...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.phone_in_talk_outlined,
            size: 80,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'Arama kaydı bulunamadı',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Yaptığınız aramalar burada görünecektir',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[500] : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: initialize,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'Yenile',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallList(bool isDark) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.only(top: 8, bottom: 16),
        itemCount: filteredItems.length + (_hasMore ? 1 : 0),
        itemBuilder: (BuildContext context, int index) {
          // Son index → loading spinner
          if (index == filteredItems.length) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(
                        Theme.of(context).primaryColor,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Daha fazla yükleniyor...',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          final cdr = filteredItems[index];
          return _buildCallItem(cdr, index, isDark);
        },
      ),
    );
  }

  Widget _buildCallItem(Cdr cdr, int index, bool isDark) {
    final bool isExpanded = _menuVisibility[index];

    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Ana içerik
          ListTile(
            onTap: () {
              setState(() {
                for (int i = 0; i < _menuVisibility.length; i++) {
                  _menuVisibility[i] = i == index ? !_menuVisibility[i] : false;
                }
              });
            },
            leading: _buildCallTypeIcon(cdr.durum),
            title: Text(
              cdr.musteri.isNotEmpty ? cdr.musteri : cdr.telefon,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey),
                    SizedBox(width: 2),
                    Text(
                      '${cdr.tarih} ${cdr.saat}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.person, size: 14, color: Colors.grey),
                    SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        cdr.gorusmeyiyapan == "null" ? "Santral" : cdr.gorusmeyiyapan,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCallStatus(cdr.durum),
                SizedBox(width: 8),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.grey,
                ),
              ],
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),

          // Genişletilmiş içerik
          if (isExpanded)
            _buildExpandedContent(cdr, isDark),
        ],
      ),
    );
  }

  Widget _buildCallTypeIcon(String durum) {
    final Color backgroundColor;
    final IconData icon;
    final Color iconColor = Colors.white;

    switch (durum) {
      case "1": // Ulaşılamadı
        backgroundColor = Colors.blueAccent;
        icon = Icons.call_missed_outgoing;
        break;
      case "2": // Giden arama
        backgroundColor = Colors.purple;
        icon = Icons.call_made;
        break;
      case "3": // Gelen arama
        backgroundColor = Colors.green;
        icon = Icons.call_received;
        break;
      case "0": // Cevapsız arama
        backgroundColor = Colors.red;
        icon = Icons.call_missed;
        break;
      case "4": // Cevapsız arama
        backgroundColor = Colors.black;
        icon = Icons.call_received;
        break;
      case "5": // Cevapsız arama
        backgroundColor = Colors.blue;
        icon = Icons.call_received;
        break;
      case "6": // Cevapsız arama
        backgroundColor = Colors.teal;
        icon = Icons.call_received;
        break;
      default:
        backgroundColor = Colors.grey;
        icon = Icons.phone;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.3),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, size: 24, color: iconColor),
    );
  }

  Widget _buildCallStatus(String durum) {
    final String statusText;
    final Color color;

    switch (durum) {
      case "1":
        statusText = 'Ulaşılamadı';
        color = Colors.blueAccent;
        break;
      case "2":
        statusText = 'Giden';
        color = Colors.purple;
        break;
      case "3":
        statusText = 'Gelen';
        color = Colors.green;
        break;
      case "0":
        statusText = 'Cevapsız';
        color = Colors.red;
        break;
      case "4":
        statusText = 'Sonuçsuz';
        color = Colors.black;
        break;
      case "5":
        statusText = 'Yol Tarifi';
        color = Colors.blue;
        break;
      case "6":
        statusText = 'Kampanya';
        color = Colors.teal;
        break;
      default:
        statusText = 'Bilinmeyen';
        color = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildExpandedContent(Cdr cdr, bool isDark) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Divider(color: Colors.grey[300]),
          SizedBox(height: 12),

          // Telefon numarası
          _buildDetailRow(
            icon: Icons.phone,
            title: 'Telefon',
            value: cdr.telefon,
          ),

          SizedBox(height: 8),

          // Çağrı işlemleri
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Ses kaydı oynatma (sadece giden/gelen aramalar için)
              if (cdr.durum == "2" || cdr.durum == "3")
                _buildActionButtonSmall(
                  icon: Icons.play_circle_fill,
                  label: 'Dinle',
                  color: Colors.green,
                  onPressed: () => seskaydinical(cdr.seskaydi),
                ),

              // Ses kaydı indirme (sadece giden/gelen aramalar için)
              if (cdr.durum == "2" || cdr.durum == "3")
                _buildActionButtonSmall(
                  icon: Icons.file_download,
                  label: 'İndir',
                  color: Colors.deepPurple,
                  onPressed: () => seskaydiniindir(
                    cdr.seskaydi,
                    '${cdr.musteri.isNotEmpty ? cdr.musteri : cdr.telefon}_${cdr.tarih}.wav',
                    context,

                  ),
                ),

              // Tekrar ara
              _buildActionButtonSmall(
                icon: Icons.phone,
                label: 'Ara',
                color: Colors.blue,
                onPressed: () {
                  /*widget.dialPadManager.updateDialPad(
                    context, true, "", widget.kullanici
                );*/
                },
              ),

              // Müşteri ekle (sadece müşteri adı yoksa)
              if (cdr.musteri.isEmpty)
                _buildActionButtonSmall(
                  icon: Icons.person_add,
                  label: 'Müşteri Ekle',
                  color: Colors.orange,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Yenimusteri(
                          kullanicirolu: widget.kullanicirolu,
                            isletmebilgi: widget.isletmebilgi,
                            isim: "",
                            telefon: cdr.telefon,
                            sadeceekranikapat: true
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        SizedBox(width: 8),
        Text(
          '$title: ',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtonSmall({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.1),
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(icon, size: 20, color: color),
            padding: EdgeInsets.zero,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSB) {
            final bool isDark = Theme.of(context).brightness == Brightness.dark;

            return Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Başlık ve kapatma
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filtrele',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),

                  Divider(height: 1),

                  // Filtre içeriği
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildDateField(
                          controller: baslangictarihi,
                          label: 'Başlangıç Tarihi',
                          isDark: isDark,
                          onTap: () async {
                            DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(1950),
                              lastDate: DateTime(2100),
                            );
                            if (pickedDate != null) {
                              setStateSB(() {
                                baslangictarihi.text = DateFormat('yyyy-MM-dd').format(pickedDate);
                                startDate = DateTime.parse(baslangictarihi.text);
                              });
                            }
                          },
                        ),

                        SizedBox(height: 16),

                        _buildDateField(
                          controller: bitistarihi,
                          label: 'Bitiş Tarihi',
                          isDark: isDark,
                          onTap: () async {
                            DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(1950),
                              lastDate: DateTime(2100),
                            );
                            if (pickedDate != null) {
                              setStateSB(() {
                                bitistarihi.text = DateFormat('yyyy-MM-dd').format(pickedDate);
                                endDate = DateTime.parse(bitistarihi.text);
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  // Butonlar
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[50],
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _resetFilters,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: isDark ? Colors.white : Colors.black,
                              side: BorderSide(color: Colors.grey),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text('Sıfırla'),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              filterSearchResults(_searchController.text);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              'Uygula',
                              style: TextStyle(color: Colors.white),
                            ),
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
      },
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800] : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
          ),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'GG-AA-YYYY',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              suffixIcon: Icon(Icons.calendar_today, color: Colors.grey),
            ),
            readOnly: true,
            onTap: onTap,
          ),
        ),
      ],
    );
  }
  Future<void> seskaydinical(String url) async {
    log("ses kaydı url " + url);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Container(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Başlık
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Ses Kaydı",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.grey[600]),
                      onPressed: () {
                        _audioPlayer.stop();
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),

                SizedBox(height: 20),

                // Hareketli ses dalgası simülasyonu
                _AnimatedWaveform(),

                SizedBox(height: 30),

                // Kontrol butonları
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Geri sarma butonu
                    _buildControlButton(
                      icon: Icons.replay_10,
                      onPressed: () async {
                        final position = await _audioPlayer.getCurrentPosition();
                        if (position != null) {
                          await _audioPlayer.seek(Duration(
                            milliseconds: position.inMilliseconds - 10000,
                          ));
                        }
                      },
                    ),

                    // Oynat/Duraklat butonu
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.green[400],
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(Icons.play_arrow, color: Colors.white),
                        iconSize: 32,
                        onPressed: () async {
                          await _audioPlayer.setSourceUrl(url);
                          await _audioPlayer.resume();
                        },
                      ),
                    ),

                    // İleri sarma butonu
                    _buildControlButton(
                      icon: Icons.forward_10,
                      onPressed: () async {
                        final position = await _audioPlayer.getCurrentPosition();
                        if (position != null) {
                          await _audioPlayer.seek(Duration(
                            milliseconds: position.inMilliseconds + 10000,
                          ));
                        }
                      },
                    ),
                  ],
                ),

                SizedBox(height: 20),

                // İkincil kontrol butonları
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSecondaryButton(
                      icon: Icons.pause,
                      text: "Duraklat",
                      onPressed: () async {
                        await _audioPlayer.pause();
                      },
                    ),



                  ],
                ),

                SizedBox(height: 10),

                // İlerleme çubuğu
                StreamBuilder<Duration>(
                  stream: _audioPlayer.onPositionChanged,
                  builder: (context, snapshot) {
                    final position = snapshot.data ?? Duration.zero;
                    return StreamBuilder<Duration>(
                      stream: _audioPlayer.onDurationChanged,
                      builder: (context, snapshot) {
                        final duration = snapshot.data ?? Duration.zero;
                        return Column(
                          children: [
                            SliderTheme(
                              data: SliderThemeData(
                                trackHeight: 4,
                                thumbShape: RoundSliderThumbShape(
                                  enabledThumbRadius: 8,
                                ),
                                overlayShape: RoundSliderOverlayShape(
                                  overlayRadius: 14,
                                ),
                                activeTrackColor: Colors.green[400],
                                inactiveTrackColor: Colors.grey[300],
                                thumbColor: Colors.green[400],
                              ),
                              child: Slider(
                                value: position.inMilliseconds.toDouble(),
                                max: duration.inMilliseconds.toDouble() == 0
                                    ? 1.0
                                    : duration.inMilliseconds.toDouble(),
                                onChanged: (value) async {
                                  await _audioPlayer.seek(
                                    Duration(milliseconds: value.toInt()),
                                  );
                                },
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(position),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  _formatDuration(duration),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }



// Süre formatlama fonksiyonu
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));

    if (duration.inHours > 0) {
      return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    } else {
      return "$twoDigitMinutes:$twoDigitSeconds";
    }
  }

  Future<void> seskaydiniindir(String url, String fileName, BuildContext context) async {
    Directory directory;
    if (Platform.isIOS) {
      directory = await getApplicationDocumentsDirectory();
    } else if (Platform.isAndroid) {
      directory = (await getExternalStorageDirectory())!;
    } else {
      throw UnsupportedError("İndirme desteklenmemektedir");
    }

    String filePath = '${directory.path}/$fileName';

    Dio dio = Dio();
    try {
      await dio.download(url, filePath,
          onReceiveProgress: (received, total) {
            if (total != -1) {
              // istersen progress gösterebilirsin
              print((received / total * 100).toStringAsFixed(0) + "%");
            }
          });

      // iOS ve Android için dosyayı paylaş
      await Share.shareXFiles([XFile(filePath)], text: "Ses kaydınız indirildi");

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Dosya indirilemedi: $e")),
      );
    }
  }
/*Widget _buildPaginationControls() {
    final totalPages = (_randevuDataGridSource.totalPages).ceil();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: _randevuDataGridSource.currentPage > 1
              ? () {
            setState(() {
              _randevuDataGridSource
                  .setPage(_randevuDataGridSource.currentPage - 1);
            });
          }
              : null,
        ),
        Text('Sayfa ${_randevuDataGridSource.currentPage} / $totalPages'),
        IconButton(
          icon: Icon(Icons.arrow_forward),
          onPressed: _randevuDataGridSource.currentPage < totalPages
              ? () {
            setState(() {
              _randevuDataGridSource
                  .setPage(_randevuDataGridSource.currentPage + 1);
            });
          }
              : null,
        ),
      ],
    );
  }*/

}
// Hareketli ses dalgası widget'ı
class _AnimatedWaveform extends StatefulWidget {
  @override
  __AnimatedWaveformState createState() => __AnimatedWaveformState();
}

class __AnimatedWaveformState extends State<_AnimatedWaveform> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(20, (index) {
              // Dalga boylarını rastgele ama animasyonlu hale getir
              double baseHeight = 8 + (index % 7) * 6.0;
              double animatedHeight = baseHeight * _animation.value;

              return Container(
                width: 3,
                height: animatedHeight,
                decoration: BoxDecoration(
                  color: Colors.green[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

// Kontrol butonu widget'ı
Widget _buildControlButton({
  required IconData icon,
  required VoidCallback onPressed,
}) {
  return IconButton(
    icon: Icon(icon, color: Colors.green[400], size: 28),
    onPressed: onPressed,
  );
}

// İkincil buton widget'ı
Widget _buildSecondaryButton({
  required IconData icon,
  required String text,
  required VoidCallback onPressed,
}) {
  return TextButton.icon(
    icon: Icon(icon, color: Colors.grey[700], size: 20),
    label: Text(
      text,
      style: TextStyle(
        color: Colors.grey[700],
        fontSize: 14,
      ),
    ),
    onPressed: onPressed,
    style: TextButton.styleFrom(
      backgroundColor: Colors.grey[100],
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey[300]!),
      ),
    ),
  );
}
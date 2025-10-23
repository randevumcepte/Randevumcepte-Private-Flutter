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




class CDRRaporlari extends StatefulWidget {

  final dynamic isletmebilgi;
  final DialPadManager dialPadManager;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;
  final Kullanici kullanici;
  const CDRRaporlari({Key? key,required this.isletmebilgi,required this.dialPadManager,required this.scaffoldMessengerKey,required this.kullanici}) : super(key: key);
  @override
  _CDRState createState() => _CDRState();
}

class _CDRState extends State<CDRRaporlari> {

  ScrollController _scrollController = ScrollController();
  DateTime _sonYuklenenTarih = DateTime.now(); // initState içinde bunu tanımla
  ValueNotifier<int> downloadProgressNotifier = ValueNotifier(0);
  SnackBar? currentSnackbar;
  bool isSnackbarVisible = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  late OverlayEntry _dialPadOverlayEntry;
  List<bool> _menuVisibility = [];
  late List<Cdr> items;
  late List<Cdr> filteredItems;
  late RandevuDataSource _randevuDataGridSource;
  List<Randevu> _randevu = [];
  late List<Randevu> _filteredRandevu = [];
  late String? seciliisletme;
  bool _isLoading = true;
  bool verigetiriliyor = false;
  int totalPages = 1;
  DateTime? startDate;
  DateTime? endDate;
  List<String> dahililer =[];

  TextEditingController baslangictarihi = TextEditingController();
  TextEditingController bitistarihi = TextEditingController();
  TextEditingController _controller = TextEditingController();
  //final SIPUAHelper _helper = SIPUAHelper();
  @override
  void initState() {
    super.initState();

    // Başlangıç ve bitiş tarihlerini ayarla
    DateTime now = DateTime.now();
    DateTime lastWeekStart = now.subtract(Duration(days: 7));
    DateTime lastWeekEnd = now;

    baslangictarihi.text = '';
    bitistarihi.text = '';
    log('Santral rapor');
    // İlk veriyi yükle
    initialize();

    // Scroll listener ekle
    _scrollController.addListener(() {
      _kontrolListeBoyutu();
    });

    // İlk kontrolü widget ağacı oluşturulduktan sonra başlat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      log("WidgetsBinding çalıştı. ScrollController bağlandı mı kontrol ediliyor...");
      _kontrolListeBoyutu();
    });
  }
  @override
  void dispose() {
    _audioPlayer.dispose(); // Release resources when not needed
    super.dispose();
  }
  Future<void> initialize() async {
    setState(() {
      _isLoading = true;
    });

    List<Personel> personelListesi = [];
    seciliisletme = widget.isletmebilgi['id']?.toString();
    print('initialize: seciliisletme = $seciliisletme');

    if (seciliisletme == null) {
      print('initialize: seciliisletme null, veri yükleme iptal ediliyor');
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
    print('initialize: dahililer = ${jsonEncode(dahililer)}');

    try {
      print('initialize: santralraporlari çağrısı başlıyor...');
      items = await santralraporlari(seciliisletme!, baslangictarihi.text, bitistarihi.text);
      print('initialize: santralraporlari çağrısı bitti, items.length = ${items.length}');
    } catch (e, st) {
      print('initialize: santralraporlari hata: $e');
      print(st);
      items = [];
    }

    filteredItems = items;
    _menuVisibility = List.generate(filteredItems.length, (index) => false);

    try {
      _sonYuklenenTarih = DateTime.parse(baslangictarihi.text);
    } catch (e) {
      print('initialize: tarih parse hatası: $e');
      _sonYuklenenTarih = DateTime.now();
    }

    setState(() {
      _isLoading = false;
    });

    if (items.isEmpty) {
      print("initialize: İlk sorguda hiç veri gelmedi, geçmiş haftalardan yükleniyor...");

    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(Duration(milliseconds: 100), () {
        if (mounted) {
          print("initialize: scroll kontrol ediliyor...");
          _kontrolListeBoyutu();
        }
      });
    });
  }


  void _kontrolListeBoyutu() {
    if (!_scrollController.hasClients) {
      log("ScrollController henüz bağlı değil.");
      return;
    }

    final double maxScrollExtent = _scrollController.position.maxScrollExtent;
    final double viewportHeight = _scrollController.position.viewportDimension;

    log("maxScrollExtent: $maxScrollExtent, viewportHeight: $viewportHeight");

    // Eğer liste ekranı doldurmuyorsa yeni veri yükle
    if ((maxScrollExtent < viewportHeight || _scrollController.position.pixels >= maxScrollExtent) && !verigetiriliyor) {
      log("Liste ekranı doldurmuyor veya sonuna gelindi, yeni veri yükleniyor...");

    }
  }
  /* Future<void> dahaFazlaKayitGetir() async {
    if (verigetiriliyor) return;

    setState(() {
      verigetiriliyor = true;
    });

    bool veriEklendi = false;

    for (int i = 0; i < 2; i++) {
      DateTime oncekiHaftaBitis = _sonYuklenenTarih.subtract(Duration(days: 7 * i + 1));
      DateTime oncekiHaftaBaslangic = _sonYuklenenTarih.subtract(Duration(days: 7 * (i + 1)));

      String yeniBaslangic = oncekiHaftaBaslangic.toIso8601String();
      String yeniBitis = oncekiHaftaBitis.toIso8601String();

      log("Denenen tarih aralığı: $yeniBaslangic - $yeniBitis");

      List<Cdr> newItems = await santralraporlari(seciliisletme!, yeniBaslangic, yeniBitis);

      log("Veri sayısı: ${newItems.length}");

      if (newItems.isNotEmpty) {
        setState(() {
          items.addAll(newItems);
          filteredItems = items;
          _menuVisibility.addAll(List.generate(newItems.length, (_) => false));
          _sonYuklenenTarih = oncekiHaftaBaslangic; // sonraki yükleme için güncelle
        });

        veriEklendi = true;
        break;
      }
    }

    if (!veriEklendi) {
      log("Son 6 haftada yeni kayıt bulunamadı.");
    }

    setState(() {
      verigetiriliyor = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _kontrolListeBoyutu();
    });
  }*/

  void filterSearchResults(String query) {
    DateTime? start = startDate;
    DateTime? end = endDate;

    if (query.isNotEmpty || (start != null && end != null)) {
      setState(() {
        filteredItems = items.where((item) {
          // Debugging: Print the item being filtered
          print("Filtering item: ${item.musteri}");

          bool matchesQuery = item.musteri.toLowerCase().contains(query.toLowerCase()) ||
              item.telefon.toLowerCase().contains(query.toLowerCase());

          // Ensure that date parsing is correct
          DateTime itemDate;
          try {
            itemDate = DateTime.parse(item.tarih); // Adjust 'dateField' to your actual field
          } catch (e) {
            print("Error parsing date: ${item.tarih}");
            return false; // Skip this item if the date can't be parsed
          }
          log("is after start "+itemDate.isAfter(start!).toString());
          log("is before end "+itemDate.isBefore(end!).toString());
          bool matchesDate = (start == null || itemDate.isAfter(start)) &&
              (end == null || itemDate.isBefore(end));

          // Debugging: Print the result of the matches
          print("Matches Query: $matchesQuery, Matches Date: $matchesDate");
          return matchesQuery && matchesDate;
        }).toList();
      });
    }
    else {
      setState(() {
        filteredItems = items;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double height = MediaQuery.of(context).size.height;

    return Scaffold(

      appBar: AppBar(
        title: Text(
          'Santral',
          style: TextStyle(color: Colors.black, fontSize: 18),
        ),
        /*leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Provider.of<IndexedStackState>(context, listen: false).setSelectedIndex(0);
          },
        ),*/
        toolbarHeight: 60,
        actions: <Widget>[
          if (widget.isletmebilgi["demo_hesabi"].toString() == "1")
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: SizedBox(
              width: 100,
              child: YukseltButonu(isletme_bilgi: widget.isletmebilgi,)
            ),
          ),
          IconButton(
            onPressed: () {
              showModalBottomSheet(
                  context: context,
                  builder: (context) {
                    return StatefulBuilder(builder: (context, setStateSB) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          SizedBox(
                            height: 20,
                          ),
                          Container(
                            padding: const EdgeInsets.only(left: 20.0),
                            child: Text(
                              'Başlangıç Tarihi',
                              style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Container(
                            alignment: Alignment.center,
                            margin: EdgeInsets.only(left: 20, right: 20),
                            height: 40,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Color(0xFF6A1B9A)),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: TextField(
                              controller: baslangictarihi,
                              enabled: true,
                              decoration: InputDecoration(
                                focusColor: Color(0xFF6A1B9A),
                                hoverColor: Color(0xFF6A1B9A),
                                hintStyle:
                                TextStyle(color: Color(0xFF6A1B9A)),
                                contentPadding: EdgeInsets.all(15.0),
                                enabledBorder: OutlineInputBorder(
                                  borderSide:
                                  BorderSide(color: Color(0xFF6A1B9A)),
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide:
                                  BorderSide(color: Color(0xFF6A1B9A)),
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                              ),
                              readOnly: true,
                              onTap: () async {
                                DateTime? pickedDate = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime(1950),
                                    lastDate: DateTime(2100));

                                if (pickedDate != null) {
                                  String formattedDate =
                                  DateFormat('yyyy-MM-dd')
                                      .format(pickedDate);
                                  setStateSB(() {
                                    baslangictarihi.text = formattedDate;
                                    startDate =  DateTime.parse(baslangictarihi.text);
                                  });
                                }
                              },
                            ),
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          Container(
                            padding: const EdgeInsets.only(left: 20.0),
                            child: Text(
                              'Bitiş Tarihi',
                              style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Container(
                            alignment: Alignment.center,
                            margin: EdgeInsets.only(left: 20, right: 20),
                            height: 40,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Color(0xFF6A1B9A)),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: TextField(
                              controller: bitistarihi,
                              enabled: true,
                              decoration: InputDecoration(
                                focusColor: Color(0xFF6A1B9A),
                                hoverColor: Color(0xFF6A1B9A),
                                hintStyle:
                                TextStyle(color: Color(0xFF6A1B9A)),
                                contentPadding: EdgeInsets.all(15.0),
                                enabledBorder: OutlineInputBorder(
                                  borderSide:
                                  BorderSide(color: Color(0xFF6A1B9A)),
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide:
                                  BorderSide(color: Color(0xFF6A1B9A)),
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                              ),
                              readOnly: true,
                              onTap: () async {
                                DateTime? pickedDate = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime(1950),
                                    lastDate: DateTime(2100));

                                if (pickedDate != null) {
                                  String formattedDate =
                                  DateFormat('yyyy-MM-dd')
                                      .format(pickedDate);
                                  setStateSB(() {
                                    bitistarihi.text = formattedDate;
                                    endDate =  DateTime.parse(bitistarihi.text);
                                  });
                                }
                              },
                            ),
                          ),
                          SizedBox(
                            height: 20,
                          ),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    Navigator.of(context).pop();
                                    filterSearchResults(_controller.text);
                                  });
                                },
                                child: Text('Arama Kayıtlarını Göster'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple[800],
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    Navigator.of(context).pop();
                                    filterSearchResults(_controller.text);
                                  });
                                },
                                child: Text('Filtreyi Sıfırla'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: 50,
                          ),
                        ],
                      );
                    });
                  });
            },
            icon: Icon(
              Icons.filter_list_outlined,
              color: Colors.black,
            ),
            iconSize: 26,
          ),
          IconButton(
            onPressed: () {
              widget.dialPadManager.updateDialPad(context, true, "",widget.kullanici);

            },
            icon: Icon(
              Icons.phone,
              color: Colors.black,
            ),
            iconSize: 26,
          ),
          /*IconButton(
            onPressed: () {
              Navigator.push(context, new MaterialPageRoute(builder: (context) =>  CallKit()));

            },
            icon: Icon(
              Icons.add,
              color: Colors.black,
            ),
            iconSize: 26,
          ),*/
        ],
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextFormField(
                controller: _controller,
                onChanged:filterSearchResults,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  hintText: 'Müşteri/Danışan Adı...',
                  enabled: true,
                  focusColor: Color(0xFF6A1B9A),
                  hoverColor: Color(0xFF6A1B9A),
                  hintStyle: TextStyle(color: Color(0xFF6A1B9A)),
                  contentPadding: EdgeInsets.all(5.0),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF6A1B9A)),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF6A1B9A)),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
              ),
            ),
            Container(
              height: height - 225,
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : filteredItems.isEmpty
                  ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'images/pbx.png', // Replace with your image path
                    width: 150,
                    height: 150,
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Yaptığınız aramalar burada gösterilecektir.",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              )
                  : ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: filteredItems.length,
                itemBuilder: (BuildContext context, int index) {
                  final bildirimData = filteredItems[index];
                  return Column(
                      children: [
                    Card(
                    color: Colors.white /*bildirimData.durum == "0"
                        ? Colors.red[600] : bildirimData.durum == "2" ? Colors.deepPurple : bildirimData.durum=="3" ? Colors.green : bildirimData.durum == "1" ? Colors.blueAccent :  Colors.white*/ ,
                    elevation: 3.0,
                    margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    child: ListTile(
                      onTap: () {
                        setState(() {

                          for (int i = 0; i < _menuVisibility.length; i++) {
                            if (i == index) {
                              _menuVisibility[i] = !_menuVisibility[i]; // Toggle the tapped one
                            } else {
                              _menuVisibility[i] = false; // Hide others
                            }
                          }
                        });
                      },
                      leading: getCdrStatIcon(bildirimData.durum),
                      title: Text(bildirimData.musteri != ''
                          ? bildirimData.musteri
                          : bildirimData.telefon, style: TextStyle(color:Colors.black),),
                      subtitle: Row(
                        children: [
                          Text(
                            bildirimData.tarih + ' ' + bildirimData.saat,
                            style: TextStyle(color: Colors.black),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.person, color: Colors.black),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              (bildirimData.gorusmeyiyapan == "null"
                                  ? "Santral"
                                  : bildirimData.gorusmeyiyapan),
                              style: TextStyle(color: Colors.black),
                              overflow: TextOverflow.ellipsis, // taşarsa "..." koy
                            ),
                          ),
                        ],
                      ),
                      trailing:  TextButton(
                          onPressed: () {
                            widget.dialPadManager.updateDialPad(context,true,"0"+bildirimData.telefon,widget.kullanici);

                          },
                          child: Icon(Icons.phone,color: Colors.deepPurple)
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 1.0, vertical: 0),
                    ),
                  ),
                        if (_menuVisibility[index]&& (bildirimData.durum=="2" || bildirimData.durum == "3" || bildirimData.musteri =="")  )


                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              bildirimData.durum=="2" || bildirimData.durum == "3" ?
                              TextButton(
                                onPressed: () {
                                  seskaydinical(bildirimData.seskaydi);
                                },
                                  child:
                                  Icon(Icons.play_circle_fill,color: Colors.green,)
                              ) : Text(""),
                              bildirimData.durum=="2" || bildirimData.durum == "3" ? TextButton(
                                  onPressed: () {

                                    seskaydiniindir(bildirimData.seskaydi,'denemeseskaydi.wav',context,bildirimData);

                                  },
                                  child: Icon(Icons.file_download,color: Colors.deepPurple,)
                              ): Text(""),
                              /*TextButton(
                                onPressed: () {
                                  widget.dialPadManager.updateDialPad(context,true,"0"+bildirimData.telefon,);

                                },
                                  child: Icon(Icons.phone,color: Colors.deepPurple)
                              ),*/
                              bildirimData.musteri == '' ?
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => Yenimusteri(isletmebilgi: widget.isletmebilgi,isim:"",telefon:  bildirimData.telefon,sadeceekranikapat: true)),
                                    );

                                    },
                                    child: Icon(Icons.person_add,color: Colors.green)
                                  )
                              : Text('')
                            ],
                          ),
                      ]
                  );


                },
              ),
            )
          ],
        ),
      ),
    );
  }

  String getCdrStat(String durum) {
    switch (durum) {
      case "1":
        return 'Ulaşılamadı';
      case "2":
        return 'Giden arama';
      case "3":
        return "Gelen arama";
      case "0":
        return "Cevapsız arama";
      default:
        return "Bilinmeyen";
    }
  }
  Widget getCdrStatIcon(String durum) {
    switch (durum) {
      case "1":
        return  Container(
          width: 50, // Set the width of the circle
          height: 50, // Set the height of the circle
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blueAccent, // Background color of the circle
          ),
          child: Icon(
            Icons.call_missed_outgoing,
            size: 25,
            color: Colors.white,
          ),
        ); 'Ulaşılamadı';
      case "2":
        return Container(
          width: 50, // Set the width of the circle
          height: 50, // Set the height of the circle
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.purple, // Background color of the circle
          ),
          child: Icon(
            Icons.call_made,
            size: 25,
            color: Colors.white,
          ),
        );'Giden arama';
      case "3":
        return Container(
          width: 50, // Set the width of the circle
          height: 50, // Set the height of the circle
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.green, // Background color of the circle
          ),
          child: Icon(
            Icons.call_received,
            size: 25,
            color: Colors.white,
          ),
        );"Gelen arama";
      case "0":
        return Container(
          width: 50, // Set the width of the circle
          height: 50, // Set the height of the circle
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.red[600], // Background color of the circle
          ),
          child: Icon(
            Icons.call_missed,
            size: 25,
            color: Colors.white,
          ),
        );" Cevapsız arama";
      default:
        return Icon(Icons.phone, size: 25,color: Colors.black);"Bilinmeyen";
    }
  }
  Widget getCagriDurumu(String durum) {
    switch (durum) {
      case "1":
        return Text('Ulaşılamadı',style: TextStyle(color:Colors.black)); 'Ulaşılamadı';
      case "2":
        return Text('Giden',style: TextStyle(color:Colors.black));
      case "3":
        return Text("Gelen",style: TextStyle(color:Colors.black));
      case "0":
        return Text("Cevapsız",style: TextStyle(color:Colors.black));
      default:
        return Text("Bilinmeyen",style: TextStyle(color:Colors.black));
    }
  }
  Future<void> seskaydinical(String url) async {
    log("ses kaydı url "+url);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Ses Kaydı"),
          content: Padding(
            padding: const EdgeInsets.all(0.0), // Set the desired padding here
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  icon: Icon(Icons.play_arrow),
                  label: Text("Çal"),
                  onPressed: () async {
                    await _audioPlayer.setSourceUrl(url);
                    await _audioPlayer.resume();
                  },
                ),

                TextButton.icon(
                  icon: Icon(Icons.pause),
                  label: Text("Duraklat"),
                  onPressed: () async {
                    await _audioPlayer.pause();
                  },
                ),

                TextButton.icon(
                  icon: Icon(Icons.stop),
                  label: Text("Durdur"),
                  onPressed: () async {
                    await _audioPlayer.stop();
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text("Kapat"),
              onPressed: () {
                _audioPlayer.stop();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
  Future<void> seskaydiniindir(String url, String fileName, BuildContext context, Cdr cdr) async {

    var status = await Permission.storage.request();
    if (!status.isGranted) {
      print('Permission denied');
      return;
    }

    downloadProgressNotifier.value = 0;
    Directory directory = Directory("");
    if (Platform.isAndroid) {
      directory = (await getExternalStorageDirectory())!;
    } else {
      directory = (await getApplicationDocumentsDirectory());
    }


    try {
      Directory downloadsDirectory;
      try {
        if (Platform.isAndroid) {
          downloadsDirectory = Directory('/storage/emulated/0/Download');
        } else if (Platform.isIOS) {
          downloadsDirectory = await getApplicationDocumentsDirectory();
        } else {
          throw UnsupportedError("İndirme desteklenmemektedir");
        }
      } catch (e) {
        widget.scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text(e.toString()), duration: Duration(seconds: 2)),
        );
        return;
      }
      String filePath = '${downloadsDirectory.path}/$fileName';
      Dio dio = Dio();
      indirmedialoggoster(context,"Ses kaydı indirme",downloadProgressNotifier);
      await dio.download(url, filePath, onReceiveProgress: (actualBytes, int totalBytes) {
        downloadProgressNotifier.value = (actualBytes / totalBytes * 100).floor();
      });


    } catch (e) {

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

import 'dart:convert';
import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:page_transition/page_transition.dart';
import 'package:randevu_sistem/yonetici/dashboard/ozetsayfasi_sevices.dart';
import 'package:randevu_sistem/yonetici/dashboard/profilbilgileri.dart';
import 'package:randevu_sistem/yonetici/dashboard/satisPerformanslari/alacaklardashboard.dart';
import 'package:randevu_sistem/yonetici/dashboard/satisPerformanslari/kasa.dart';
import 'package:randevu_sistem/yonetici/dashboard/scaffold_layout_builder.dart';
import 'package:randevu_sistem/yonetici/diger/menu/kasa/kasaraporu.dart';
import 'package:sticky_headers/sticky_headers/widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:randevu_sistem/Backend/backend.dart';
import '../../Frontend/dialpad.dart';
import '../../Frontend/sfdatatable.dart';
import '../../Models/ajanda.dart';
import '../../Models/dashboard.dart';
import '../../Models/e_asistan.dart';
import '../../Models/musteri_danisanlar.dart';
import '../../Models/paketler.dart';
import '../../Models/sms_taslaklari.dart';
import '../../Models/user.dart';
import '../adisyonlar/adisyonpage.dart';
import '../adisyonlar/yeniadisyon.dart';
import '../diger/menu/ajanda/ajandaekle.dart';
import '../diger/menu/musteriler/yeni_musteri.dart';
import '../santral/santralraporlari.dart';
import 'bildirimler/bildirimler.dart';
import 'deneme.dart';
import 'gunlukRaporlar/gunlukajandanotlari.dart';
import 'gunlukRaporlar/ongorusmeraporlari.dart';
import 'gunlukRaporlar/paketsatislaridashboard.dart';
import 'gunlukRaporlar/randevular.dart';
import 'gunlukRaporlar/urunsatislaridashboard.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'ozetsayfasi.dart';
import 'package:badges/badges.dart' as badges;

class DashBoard extends StatefulWidget{
  final Kullanici kullanici;
  final dynamic isletmebilgi;
  final int kullanicirolu;
  DashBoard({Key? key,required this.kullanici,required this.isletmebilgi,required this.kullanicirolu}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<DashBoard> {
  List<Map<String, dynamic>> randevuList = [];
  late Kullanici kullanici;
  late int uyelikturu;
  late Future<List<EAsistan>> futureEAsistanData;
  late int kullanicirolu;
  late String? seciliisletme;
  late String isletmeadi;
  late String _isletmeadi;
  bool _showAppBar = false;
  late AjandaDataSource _ajandaDataGridSource;
  late OzetSayfasi ozetsayfabilgi;
  late Map<String,dynamic> ajandalist;
  bool isloading = true;
  bool randevularYukleniyor = true;

  void _updateNotificationCount() {
    _refreshDashboardData();
  }
  final DialPadManager _dialPadManager = DialPadManager(); // Bu satırı ekleyin

  Future<void> _refreshDashboardData() async {
    setState(() {
      isloading = true;
      randevularYukleniyor = true;
    });

    await initialize();
    await _gunlukRandevulariGetir();
  }

  Future<void> _refreshPage() async {
    await _refreshDashboardData();
  }

  @override
  void initState() {
    super.initState();
    initialize();
    _gunlukRandevulariGetir();
  }

  Future<void> initialize() async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    isletmeadi = localStorage.getString('isletmeadi')!;
    seciliisletme = await secilisalonid();

    int bugunYarinTimestamp = DateTime.now().millisecondsSinceEpoch;

    OzetSayfasi ozet = await dashboardGunlukRapor(seciliisletme!);
    var asistanVerileri = await easistandashboard(seciliisletme!, bugunYarinTimestamp);

    widget.kullanici.yetkili_olunan_isletmeler.forEach((element) {
      if (element['salon_id'] == seciliisletme.toString()) {
        uyelikturu = int.parse(element['salonlar']['uyelik_turu'].toString());
      }
    });

    setState(() {
      kullanicirolu = int.parse(widget.kullanici.yetkili_olunan_isletmeler
          .firstWhere((element) => element["salon_id"].toString() == widget.isletmebilgi["id"].toString())["role_id"]
          .toString());
      _isletmeadi = isletmeadi;
      ozetsayfabilgi = ozet;
      _ajandaDataGridSource = AjandaDataSource(
          isletmebilgi: widget.isletmebilgi,
          rowsPerPage: 10,
          salonid: seciliisletme!,
          context: context,
          baslik: '');
      futureEAsistanData = Future.value(asistanVerileri);
      isloading = false;
    });
  }

  // Günlük randevuları getiren fonksiyon
  Future<void> _gunlukRandevulariGetir() async {
    try {
      SharedPreferences localStorage = await SharedPreferences.getInstance();
      var userData = jsonDecode(localStorage.getString('user')!);
      String userId = userData['id'].toString();

      // Bugünün tarihini al
      final now = DateTime.now();
      String bugunTarih = DateFormat('yyyy-MM-dd').format(now);

      // Randevuları getir
      Map<String, dynamic> randevuData = await randevularigetir(
          '', // musteri_id
          widget.isletmebilgi["id"].toString(), // salonid
          'Tümü', // oluşturma
          'Tümü', // durum
          'Bugün', // tarih
          '1', // currpage
          '', // musteridanisanadi
          '', // personelid
          '', // cihazid
          false // musteriMi
      );

      if (randevuData.containsKey('data') && randevuData['data'] is List) {
        setState(() {
          randevuList = List<Map<String, dynamic>>.from(randevuData['data']);
          randevularYukleniyor = false;
        });
      } else {
        setState(() {
          randevuList = [];
          randevularYukleniyor = false;
        });
      }
    } catch (e) {
      print('Randevu getirme hatası: $e');
      setState(() {
        randevuList = [];
        randevularYukleniyor = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double _ratingValue = 0;
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Color(0xFFF5F5F5),
      body: isloading
          ? Center(child: CircularProgressIndicator())
          : ScaffoldLayoutBuilder(
        backgroundColorAppBar:
        const ColorBuilder(Colors.transparent, Color(0xFF6A1B9A)),
        textColorAppBar: const ColorBuilder(Colors.white),
        appBarBuilder: _appBar,
        child: SafeArea(
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: Center(
              child: RefreshIndicator(
                color: Colors.purple[800],
                backgroundColor: Colors.white,
                strokeWidth: 3.0,
                onRefresh: () => _refreshPage(),
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  physics: BouncingScrollPhysics(
                      parent: ClampingScrollPhysics()),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            height: 260,
                            width: double.infinity,
                            decoration: const BoxDecoration(
                                image: DecorationImage(
                                    image: AssetImage(
                                        'images/randevumcepte.jpg'),
                                    fit: BoxFit.fill),
                                borderRadius: BorderRadius.only(
                                    bottomLeft: Radius.circular(20),
                                    bottomRight: Radius.circular(20))),
                          ),
                          Container(
                            child: Column(children: [
                              kullanicirolu < 5
                                  ? SizedBox(height: 50)
                                  : SizedBox(height: 100),
                              if (kullanicirolu < 5)
                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    // SMS bilgisini sola taşıdık
                                    Container(
                                      padding: EdgeInsets.only(
                                          left: 30, top: 40),
                                      child: Text(
                                        ozetsayfabilgi.kalansms + " SMS",
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18),
                                      ),
                                    ),
                                    // Telefon ikonunu sağa ekledik
                                    Container(
                                      padding:
                                      EdgeInsets.only(right: 30, top: 40),
                                      child: IconButton(
                                        onPressed: () {
                                          _dialPadManager.updateDialPad(context, true, "", widget.kullanici);
                                        },
                                        icon: Icon(
                                          Icons.phone,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                              Container(
                                decoration: const BoxDecoration(
                                    borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(15),
                                        topRight: Radius.circular(15),
                                        bottomLeft: Radius.circular(15),
                                        bottomRight: Radius.circular(15)),
                                    color: Colors.white),
                                width: width * 0.9,
                                height: 180,
                                padding: EdgeInsets.only(top: 15),
                                child: Column(
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.only(
                                          bottom: 10, right: 10),
                                      child: Text(
                                        'Günlük Raporlar',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Wrap(
                                      spacing: 5.0,
                                      runSpacing: 5.0,
                                      alignment: WrapAlignment.center,
                                      children: [
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              PageTransition(
                                                type: PageTransitionType
                                                    .rightToLeft,
                                                duration: Duration(
                                                    milliseconds: 500),
                                                child: RandevularDashboard(
                                                    kullanicirolu: widget
                                                        .kullanicirolu,
                                                    isletmebilgi: widget
                                                        .isletmebilgi),
                                              ),
                                            );
                                          },
                                          child: Column(
                                            children: [
                                              Text('Randevular'),
                                              Text(ozetsayfabilgi
                                                  .randevusayisi
                                                  .toString()),
                                            ],
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                            Color(0xFF5E35B1),
                                            foregroundColor: Colors.white,
                                            elevation: 5,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                              BorderRadius.circular(
                                                  5.0),
                                            ),
                                            minimumSize: Size(150, 50),
                                          ),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              PageTransition(
                                                type: PageTransitionType
                                                    .rightToLeft,
                                                duration: Duration(
                                                    milliseconds: 500),
                                                child: OnGorusmelerDashboard(
                                                    isletmebilgi: widget
                                                        .isletmebilgi),
                                              ),
                                            );
                                          },
                                          child: Column(
                                            children: [
                                              Text('Ön Görüşme'),
                                              Text(ozetsayfabilgi
                                                  .ongorusmesayisi
                                                  .toString()),
                                            ],
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            foregroundColor: Colors.white,
                                            backgroundColor:
                                            Color(0xFF9C27B0),
                                            elevation: 5,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                              BorderRadius.circular(
                                                  5.0),
                                            ),
                                            minimumSize: Size(150, 50),
                                          ),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.push(
                                                context,
                                                PageTransition(
                                                    type:
                                                    PageTransitionType
                                                        .rightToLeft,
                                                    duration: Duration(
                                                        milliseconds:
                                                        500),
                                                    child:
                                                    PaketSatislariDashboard(
                                                      kullanicirolu: widget
                                                          .kullanicirolu,
                                                      isletmebilgi: widget
                                                          .isletmebilgi,
                                                    )));
                                          },
                                          child: Column(
                                            children: [
                                              Text('Paket Satışı'),
                                              Text(ozetsayfabilgi
                                                  .paketsatissayisi
                                                  .toString())
                                            ],
                                          ),
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                              Color(0xFFEA80FC),
                                              foregroundColor:
                                              Colors.white,
                                              elevation: 5,
                                              shape:
                                              RoundedRectangleBorder(
                                                  borderRadius:
                                                  BorderRadius
                                                      .circular(
                                                      5.0)),
                                              minimumSize:
                                              Size(150, 50)),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.push(
                                                context,
                                                PageTransition(
                                                    type:
                                                    PageTransitionType
                                                        .rightToLeft,
                                                    duration: Duration(
                                                        milliseconds:
                                                        500),
                                                    child:
                                                    UrunSatislariDashboard(
                                                      kullanicirolu: widget
                                                          .kullanicirolu,
                                                      isletmebilgi: widget
                                                          .isletmebilgi,
                                                    )));
                                          },
                                          child: Column(
                                            children: [
                                              Text('Ürün Satışı'),
                                              Text(ozetsayfabilgi
                                                  .urunsatissayisi
                                                  .toString())
                                            ],
                                          ),
                                          style: ElevatedButton.styleFrom(
                                              foregroundColor:
                                              Colors.white,
                                              backgroundColor:
                                              Color(0xFF1976D2),
                                              elevation: 5,
                                              shape:
                                              RoundedRectangleBorder(
                                                  borderRadius:
                                                  BorderRadius
                                                      .circular(
                                                      5.0)),
                                              minimumSize:
                                              Size(150, 50)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                  width: MediaQuery.of(context).size.width,
                                  height: MediaQuery.of(context)
                                      .size
                                      .height *
                                      0.62,
                                  child: Column(
                                    children: [
                                      if (kullanicirolu != 4)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              right: 115, top: 5),
                                          child: Text(
                                            'Aylık Satış Performansı',
                                            style: TextStyle(
                                                fontWeight:
                                                FontWeight.bold,
                                                fontSize: 16),
                                          ),
                                        ),
                                      if (kullanicirolu != 4)
                                        SizedBox(height: 5),
                                      if (kullanicirolu != 4)
                                        Container(
                                          width: width * 0.95,
                                          child: Row(
                                            mainAxisAlignment:
                                            MainAxisAlignment.center,
                                            children: [
                                              ElevatedButton(
                                                  onPressed: () {
                                                    if (widget.kullanicirolu !=
                                                        5)
                                                      Navigator.push(
                                                          context,
                                                          PageTransition(
                                                              type:
                                                              PageTransitionType
                                                                  .rightToLeft,
                                                              duration:
                                                              Duration(
                                                                  milliseconds:
                                                                  500),
                                                              child: KasaRaporu(
                                                                  isletmebilgi:
                                                                  widget
                                                                      .isletmebilgi)));
                                                    else
                                                      Navigator.push(
                                                          context,
                                                          PageTransition(
                                                              type:
                                                              PageTransitionType
                                                                  .rightToLeft,
                                                              duration:
                                                              Duration(
                                                                  milliseconds:
                                                                  500),
                                                              child: AdisyonlarPage(
                                                                  kullanicirolu: widget
                                                                      .kullanicirolu,
                                                                  kullanici:
                                                                  widget
                                                                      .kullanici,
                                                                  isletmebilgi: widget
                                                                      .isletmebilgi,
                                                                  geriGitBtn:
                                                                  true)));
                                                  },
                                                  style: ElevatedButton
                                                      .styleFrom(
                                                      backgroundColor:
                                                      Color(
                                                          0xFFB39DDB),
                                                      foregroundColor:
                                                      Colors.white,
                                                      elevation: 8,
                                                      textStyle:
                                                      const TextStyle(
                                                        color:
                                                        Colors.white,
                                                        fontSize: 13,
                                                      ),
                                                      minimumSize: Size(
                                                          150, 65),
                                                      shape:
                                                      const RoundedRectangleBorder(
                                                          borderRadius:
                                                          BorderRadius.all(
                                                              Radius.circular(5)))),
                                                  child: Column(
                                                    children: [
                                                      Text(
                                                        (kullanicirolu < 5
                                                            ? 'Kasa'
                                                            : 'Toplam Satış'),
                                                        style: TextStyle(
                                                            fontWeight:
                                                            FontWeight
                                                                .bold,
                                                            fontSize: 15),
                                                      ),
                                                      Text(
                                                          ozetsayfabilgi
                                                              .toplamkasa
                                                              .toString() +
                                                              " ₺",
                                                          style: TextStyle(
                                                              fontSize: 17,
                                                              fontWeight:
                                                              FontWeight
                                                                  .bold))
                                                    ],
                                                  )),
                                              SizedBox(width: 5),
                                              ElevatedButton(
                                                onPressed: () {
                                                  if (widget.kullanicirolu !=
                                                      5)
                                                    Navigator.push(
                                                        context,
                                                        PageTransition(
                                                            type:
                                                            PageTransitionType
                                                                .rightToLeft,
                                                            duration:
                                                            Duration(
                                                                milliseconds:
                                                                500),
                                                            child:
                                                            AlacaklarDashboard(
                                                                isletmebilgi:
                                                                widget.isletmebilgi)));
                                                  else
                                                    Navigator.push(
                                                        context,
                                                        PageTransition(
                                                            type:
                                                            PageTransitionType
                                                                .rightToLeft,
                                                            duration:
                                                            Duration(
                                                                milliseconds:
                                                                500),
                                                            child: AdisyonlarPage(
                                                                kullanicirolu: widget
                                                                    .kullanicirolu,
                                                                kullanici:
                                                                widget
                                                                    .kullanici,
                                                                isletmebilgi: widget
                                                                    .isletmebilgi,
                                                                geriGitBtn:
                                                                true)));
                                                },
                                                style: ElevatedButton
                                                    .styleFrom(
                                                    backgroundColor:
                                                    Colors
                                                        .purple[
                                                    800],
                                                    foregroundColor:
                                                    Colors.white,
                                                    elevation: 8,
                                                    textStyle:
                                                    const TextStyle(
                                                      color:
                                                      Colors.white,
                                                      fontSize: 13,
                                                    ),
                                                    minimumSize: Size(
                                                        150, 65),
                                                    shape:
                                                    const RoundedRectangleBorder(
                                                        borderRadius:
                                                        BorderRadius.all(
                                                            Radius.circular(5)))),
                                                child: Column(
                                                  children: [
                                                    Text(
                                                      (kullanicirolu < 5
                                                          ? 'Alacak'
                                                          : 'Prim Hakediş'),
                                                      style: TextStyle(
                                                          fontWeight:
                                                          FontWeight
                                                              .bold,
                                                          fontSize: 15),
                                                    ),
                                                    Text(
                                                        (kullanicirolu < 5
                                                            ? ozetsayfabilgi
                                                            .kalantutar
                                                            .toString()
                                                            : ozetsayfabilgi
                                                            .prim
                                                            .toString()) +
                                                            " ₺",
                                                        style: TextStyle(
                                                            fontSize: 17,
                                                            fontWeight:
                                                            FontWeight
                                                                .bold))
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      if (kullanicirolu < 5)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              right: 108, top: 10),
                                          child: Text(
                                            'Günlük Santral Raporları',
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight:
                                                FontWeight.bold),
                                          ),
                                        ),
                                      if (kullanicirolu < 5)
                                        SingleChildScrollView(
                                          child: Container(
                                            height: 60,
                                            margin: EdgeInsets.symmetric(
                                                vertical: 8.0),
                                            child: ListView(
                                              scrollDirection:
                                              Axis.horizontal,
                                              shrinkWrap: true,
                                              padding: EdgeInsets.only(
                                                  left: 10, right: 10),
                                              children: [
                                                // Giden arama butonu
                                                Container(
                                                  child: ElevatedButton(
                                                    onPressed: () {
                                                      Navigator.push(
                                                        context,
                                                        PageTransition(
                                                          type:
                                                          PageTransitionType
                                                              .rightToLeft,
                                                          duration:
                                                          Duration(
                                                              milliseconds:
                                                              500),
                                                          child:
                                                          CDRRaporlari(
                                                            kullanicirolu:
                                                            widget
                                                                .kullanicirolu,
                                                            isletmebilgi:
                                                            widget
                                                                .isletmebilgi,
                                                            dialPadManager:
                                                            DialPadManager(),
                                                            scaffoldMessengerKey:
                                                            GlobalKey<
                                                                ScaffoldMessengerState>(),
                                                            kullanici: widget
                                                                .kullanici,
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                      Colors.white,
                                                      side:
                                                      const BorderSide(
                                                        width: 2,
                                                        color: Colors.green,
                                                      ),
                                                      minimumSize: Size(
                                                          90, 200),
                                                      shape:
                                                      const RoundedRectangleBorder(
                                                        borderRadius:
                                                        BorderRadius
                                                            .all(Radius
                                                            .circular(
                                                            5)),
                                                      ),
                                                    ),
                                                    child: Column(
                                                      children: [
                                                        SizedBox(
                                                          height: 10,
                                                        ),
                                                        Text(
                                                          'Giden',
                                                          style: TextStyle(
                                                              fontSize: 14,
                                                              color: Colors
                                                                  .green),
                                                        ),
                                                        SizedBox(
                                                          height: 5,
                                                        ),
                                                        Text(
                                                          ozetsayfabilgi
                                                              .gidenarama,
                                                          style: TextStyle(
                                                              color: Colors
                                                                  .green,
                                                              fontSize:
                                                              17),
                                                        )
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(width: 10),
                                                // Gelen arama butonu
                                                Container(
                                                  child: ElevatedButton(
                                                    onPressed: () {
                                                      Navigator.push(
                                                        context,
                                                        PageTransition(
                                                          type:
                                                          PageTransitionType
                                                              .rightToLeft,
                                                          duration:
                                                          Duration(
                                                              milliseconds:
                                                              500),
                                                          child:
                                                          CDRRaporlari(
                                                            kullanicirolu:
                                                            widget
                                                                .kullanicirolu,
                                                            isletmebilgi:
                                                            widget
                                                                .isletmebilgi,
                                                            dialPadManager:
                                                            DialPadManager(),
                                                            scaffoldMessengerKey:
                                                            GlobalKey<
                                                                ScaffoldMessengerState>(),
                                                            kullanici: widget
                                                                .kullanici,
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                      Colors.white,
                                                      side:
                                                      const BorderSide(
                                                        width: 2,
                                                        color: Color(
                                                            0xFF6A1B9A),
                                                      ),
                                                      minimumSize: Size(
                                                          90, 200),
                                                      shape:
                                                      const RoundedRectangleBorder(
                                                        borderRadius:
                                                        BorderRadius
                                                            .all(Radius
                                                            .circular(
                                                            5)),
                                                      ),
                                                    ),
                                                    child: Column(
                                                      children: [
                                                        SizedBox(
                                                          height: 10,
                                                        ),
                                                        Text(
                                                          'Gelen',
                                                          style: TextStyle(
                                                              fontSize: 14,
                                                              color: Colors
                                                                  .purple[
                                                              800]),
                                                        ),
                                                        SizedBox(
                                                          height: 5,
                                                        ),
                                                        Text(
                                                          ozetsayfabilgi
                                                              .gelenarama,
                                                          style: TextStyle(
                                                              color: Colors
                                                                  .purple[
                                                              800],
                                                              fontSize:
                                                              17),
                                                        )
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(width: 10),
                                                // Cevapsız arama butonu
                                                Container(
                                                  child: ElevatedButton(
                                                    onPressed: () {
                                                      Navigator.push(
                                                        context,
                                                        PageTransition(
                                                          type:
                                                          PageTransitionType
                                                              .rightToLeft,
                                                          duration:
                                                          Duration(
                                                              milliseconds:
                                                              500),
                                                          child:
                                                          CDRRaporlari(
                                                            kullanicirolu:
                                                            widget
                                                                .kullanicirolu,
                                                            isletmebilgi:
                                                            widget
                                                                .isletmebilgi,
                                                            dialPadManager:
                                                            DialPadManager(),
                                                            scaffoldMessengerKey:
                                                            GlobalKey<
                                                                ScaffoldMessengerState>(),
                                                            kullanici: widget
                                                                .kullanici,
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                      Colors.white,
                                                      foregroundColor:
                                                      Colors.white,
                                                      minimumSize: Size(
                                                          70, 200),
                                                      side:
                                                      const BorderSide(
                                                        width: 2,
                                                        color: Color(
                                                            0xFFFF1744),
                                                      ),
                                                      shape:
                                                      const RoundedRectangleBorder(
                                                        borderRadius:
                                                        BorderRadius
                                                            .all(Radius
                                                            .circular(
                                                            5)),
                                                      ),
                                                    ),
                                                    child: Column(
                                                      children: [
                                                        SizedBox(
                                                          height: 10,
                                                        ),
                                                        Text(
                                                          'Cevapsız',
                                                          style: TextStyle(
                                                              fontSize: 14,
                                                              color: Color(
                                                                  0xFFFF1744)),
                                                        ),
                                                        SizedBox(
                                                          height: 5,
                                                        ),
                                                        Text(
                                                          ozetsayfabilgi
                                                              .cevapsizarama,
                                                          style: TextStyle(
                                                              color: Color(
                                                                  0xFFFF1744),
                                                              fontSize:
                                                              17),
                                                        )
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      if (kullanicirolu == 5)
                                        Container(
                                          padding: EdgeInsets.all(8),
                                          alignment: Alignment.center,
                                          child: Text(
                                            '',
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight:
                                                FontWeight.bold),
                                          ),
                                        ),
                                      kullanicirolu == 5
                                          ? Container(
                                          decoration:
                                          const BoxDecoration(
                                              borderRadius:
                                              BorderRadius.only(
                                                  topLeft: Radius
                                                      .circular(
                                                      15),
                                                  topRight: Radius
                                                      .circular(
                                                      15),
                                                  bottomLeft:
                                                  Radius.circular(
                                                      15),
                                                  bottomRight:
                                                  Radius.circular(
                                                      15)),
                                              color: Colors.white),
                                          width: width * 0.9,
                                          height: height * 0.35,
                                          padding:
                                          EdgeInsets.only(top: 5),
                                          child: randevularYukleniyor
                                              ? Center(
                                              child:
                                              CircularProgressIndicator())
                                              : ListView(
                                            children: [
                                              StickyHeader(
                                                header:
                                                Container(
                                                  color: Colors
                                                      .white,
                                                  child: Row(
                                                    mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .center,
                                                    children: [
                                                      Text(
                                                        'Bugünün Randevuları',
                                                        style: TextStyle(
                                                            fontSize:
                                                            16,
                                                            fontWeight:
                                                            FontWeight.bold),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                content:
                                                ListCardRandevular(
                                                    randevular:
                                                    randevuList),
                                              ),
                                            ],
                                          ))
                                          : Expanded(
                                        child: Container(
                                          decoration:
                                          const BoxDecoration(
                                            borderRadius:
                                            BorderRadius.all(
                                                Radius.circular(
                                                    15)),
                                            color: Colors.white,
                                          ),
                                          width: width * 0.9,
                                          height: height * 0.35,
                                          padding: EdgeInsets.only(
                                              top: 5),
                                          child: Column(
                                            children: [
                                              Expanded(
                                                child: FutureBuilder<
                                                    List<EAsistan>>(
                                                  future:
                                                  futureEAsistanData,
                                                  builder: (context,
                                                      snapshot) {
                                                    if (snapshot
                                                        .connectionState ==
                                                        ConnectionState
                                                            .waiting) {
                                                      return Center(
                                                          child:
                                                          CircularProgressIndicator());
                                                    } else if (snapshot
                                                        .hasError) {
                                                      return Center(
                                                          child: Text(
                                                              "Veri alınırken hata oluştu"));
                                                    } else if (!snapshot
                                                        .hasData ||
                                                        snapshot.data!
                                                            .isEmpty) {
                                                      return Center(
                                                        child:
                                                        Padding(
                                                          padding: const EdgeInsets
                                                              .all(
                                                              16.0),
                                                          child: Text(
                                                              'Tabloda herhangi bir veri mevcut değil',
                                                              style: TextStyle(
                                                                  fontSize: 16,
                                                                  fontWeight: FontWeight.w500)),
                                                        ),
                                                      );
                                                    } else {
                                                      return ListView(
                                                        children: [
                                                          ListCard(
                                                              tasks:
                                                              snapshot.data!),
                                                        ],
                                                      );
                                                    }
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    ],
                                  ))
                            ]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _appBar(BuildContext context, ColorAnimated colorAnimated) {
    return AppBar(
        automaticallyImplyLeading: false,
        elevation: 100,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isletmeadi,
              style: (TextStyle(color: Colors.white, fontSize: 16)),
            ),
            SizedBox(width: 28),
            Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ozetsayfabilgi.okunmamisbildirimler != "" &&
                        ozetsayfabilgi.okunmamisbildirimler != "0"
                        ? Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              PageTransition(
                                type: PageTransitionType.rightToLeft,
                                duration: Duration(milliseconds: 500),
                                child: BildirimlerScreen(
                                  kullanicirolu: kullanicirolu,
                                  isletmebilgi: widget.isletmebilgi,
                                  onNotificationRead: _updateNotificationCount,
                                ),
                              ),
                            ).then((_) {
                              _refreshDashboardData();
                            });
                          },
                          icon: Icon(
                            Icons.notifications_active,
                            color: Colors.white,
                          ),
                          iconSize: 20,
                        ),
                        Positioned(
                          right: 10,
                          top: 13,
                          child: badges.Badge(
                            badgeStyle: badges.BadgeStyle(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 3),
                              badgeColor: Colors.red,
                            ),
                            badgeContent: Text(
                              ozetsayfabilgi.okunmamisbildirimler,
                              style: TextStyle(
                                  color: Colors.white, fontSize: 10),
                            ),
                            child: SizedBox.shrink(),
                          ),
                        ),
                      ],
                    )
                        : IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          PageTransition(
                            type: PageTransitionType.rightToLeft,
                            duration: Duration(milliseconds: 500),
                            child: BildirimlerScreen(
                              kullanicirolu: kullanicirolu,
                              isletmebilgi: widget.isletmebilgi,
                              onNotificationRead: _updateNotificationCount,
                            ),
                          ),
                        ).then((_) {
                          _refreshDashboardData();
                        });
                      },
                      icon: Icon(
                        Icons.notifications_active,
                        color: Colors.white,
                      ),
                      iconSize: 20,
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            PageTransition(
                                type: PageTransitionType.rightToLeft,
                                duration: Duration(milliseconds: 500),
                                child: ProfilBilgileri(kullanici: widget.kullanici)));
                      },
                      icon: Icon(Icons.person, color: Colors.white),
                      iconSize: 20,
                    )
                  ],
                ))
          ],
        ),
        toolbarHeight: 60,
        backgroundColor: colorAnimated.background);
  }
}

class HexColor extends Color {
  static int _getColor(String hex) {
    String formattedHex =  "FF" + hex.toUpperCase().replaceAll("#", "");
    return int.parse(formattedHex, radix: 16);
  }
  HexColor(final String hex) : super(_getColor(hex));
}

class ListCard extends StatelessWidget {
  final List<EAsistan> tasks;
  const ListCard({Key? key, required this.tasks}) : super(key: key);
  void _showTaskDetails(BuildContext context, EAsistan task) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.deepPurple, width: 1),
            ),
            child: Text(
              task.baslik,
              style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold,fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "Görev: ",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple),
                    ),
                    TextSpan(
                      text: task.mesaj,
                      style: TextStyle(color: Colors.blueGrey[700], fontSize: 13),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "Arama Saati: ",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple),
                    ),
                    TextSpan(
                      text: task.arama_saati,
                      style: TextStyle(color: Colors.blueGrey[700], fontSize: 14),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "Durum: ",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple),
                    ),
                    TextSpan(
                      text: task.durum,
                      style: TextStyle(color: Colors.green, fontSize: 14),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "Sonuç: ",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple),
                    ),
                    TextSpan(
                      text: task.sonuc,
                      style: TextStyle(color: Colors.blueGrey[700], fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Kapat"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        return ListTile(
          leading: Icon(Icons.task_alt, color: Colors.green),
          title: Text(tasks[index].baslik),
          subtitle: Text(
            tasks[index].mesaj ?? "",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Icon(Icons.chevron_right),
          onTap: () => _showTaskDetails(context, tasks[index]),
        );
      },
    );
  }
}

class ListCardRandevular extends StatelessWidget {
  final List<Map<String, dynamic>> randevular;
  const ListCardRandevular({Key? key, required this.randevular}) : super(key: key);

  void _showRandevuDetails(BuildContext context, Map<String, dynamic> randevu) {
    // Debug için tüm randevu verisini loglayalım
    print('Randevu Detayları: ${jsonEncode(randevu)}');

    // Verileri güvenli şekilde alalım
    final musteriler = randevu["musteriler"] as Map<String, dynamic>?;
    final users = randevu["users"] as Map<String, dynamic>?;
    final musteriAdi = musteriler?['name']?.toString() ??
        users?['name']?.toString() ??
        randevu["musteri_adi"]?.toString() ??
        "Müşteri Adı Yok";

    final telefon = musteriler?['cep_telefon']?.toString() ??
        users?['cep_telefon']?.toString() ??
        randevu["telefon"]?.toString() ??
        "Belirtilmemiş";

    // Hizmetleri güvenli şekilde alalım - düzeltildi
    final hizmetler = randevu["hizmetler"];
    String hizmetAdi = "Hizmet Adı Yok";
    List<String> hizmetListesi = [];

    if (hizmetler != null) {
      if (hizmetler is List) {
        for (var hizmet in hizmetler) {
          if (hizmet is Map) {
            // Hizmet adını farklı yapılardan almayı dene
            String? ad = hizmet['hizmet_adi']?.toString();
            if (ad == null && hizmet['hizmetler'] is Map) {
              ad = hizmet['hizmetler']['hizmet_adi']?.toString();
            }
            if (ad != null) {
              hizmetListesi.add(ad);
            }
          } else if (hizmet is String) {
            hizmetListesi.add(hizmet);
          }
        }
        if (hizmetListesi.isNotEmpty) {
          hizmetAdi = hizmetListesi.join(", ");
        }
      } else if (hizmetler is Map) {
        // Tek bir hizmet objesi
        String? ad = hizmetler['hizmet_adi']?.toString();
        if (ad == null && hizmetler['hizmetler'] is Map) {
          ad = hizmetler['hizmetler']['hizmet_adi']?.toString();
        }
        if (ad != null) {
          hizmetAdi = ad;
        }
      } else if (hizmetler is String) {
        hizmetAdi = hizmetler;
      }
    }

    final not = randevu["not"]?.toString() ??
        randevu["musteri_notu"]?.toString() ??
        randevu["personel_notu"]?.toString() ??
        "Not bulunmuyor";

    final tarih = randevu["tarih"]?.toString() ?? "Belirtilmemiş";
    final saat = randevu["saat"]?.toString() ?? "Belirtilmemiş";
    final durum = randevu["durum"]?.toString();
    final personelAdi = randevu["personel_adi"]?.toString() ?? "";

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.all(20),
          child: Container(
            constraints: BoxConstraints(maxWidth: 500),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 32,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.shade200,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF667EEA).withOpacity(0.3),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.calendar_today_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              musteriAdi,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey.shade900,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4),
                            Text(
                              hizmetAdi,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      _buildRandevuStatusBadge(durum),
                    ],
                  ),
                ),

                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Randevu Bilgileri
                        _buildSection(
                          icon: Icons.work_rounded,
                          title: "Randevu Detayı",
                          child: Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey.shade200,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInfoRow("Hizmet:", hizmetAdi),
                                SizedBox(height: 8),
                                _buildInfoRow("Ad Soyad:", musteriAdi),
                                SizedBox(height: 8),
                                _buildInfoRow("Telefon:", telefon),
                                SizedBox(height: 8),
                                if (personelAdi.isNotEmpty)
                                  _buildInfoRow("Personel:", personelAdi),
                                SizedBox(height: 8),
                                _buildInfoRow("Not:", not),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: 24),

                        // Tarih ve Saat
                        _buildSection(
                          icon: Icons.access_time_filled_rounded,
                          title: "Randevu Zamanı",
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildInfoCard(
                                  icon: Icons.calendar_month_rounded,
                                  title: _formatTarih(tarih),
                                  color: Color(0xFF667EEA),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: _buildInfoCard(
                                  icon: Icons.schedule_rounded,
                                  title: _formatSaat(saat),
                                  color: Color(0xFF4CAF50),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Footer
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                    border: Border(
                      top: BorderSide(
                        color: Colors.grey.shade200,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey.shade700,
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.close_rounded, size: 18),
                            SizedBox(width: 8),
                            Text(
                              "Kapat",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
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
  }  Widget _buildSection({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Color(0xFF667EEA).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Color(0xFF667EEA),
                size: 18,
              ),
            ),
            SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        child,
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 18,
                ),
              ),
              SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
              fontSize: 14,
            ),
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: Colors.grey.shade800,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRandevuStatusBadge(dynamic status) {
    String statusText = _getRandevuDurumText(status);
    Color statusColor = _getRandevuDurumColor(status);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 6),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 12,
              color: statusColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTarih(dynamic tarih) {
    if (tarih == null) return "Belirtilmemiş";
    try {
      return DateFormat('dd.MM.yyyy').format(DateTime.parse(tarih.toString()));
    } catch (e) {
      return tarih.toString();
    }
  }

  String _formatSaat(dynamic saat) {
    if (saat == null) return "Belirtilmemiş";
    return saat.toString();
  }

  String _getRandevuDurumText(dynamic status) {
    if (status == null) return "Belirsiz";

    String statusStr = status.toString();
    switch (statusStr) {
      case '0':
        return "Onay Bekliyor";
      case '1':
        return "Onaylı";
      case '2':
        return "Reddedilen/İptal";
      case '3':
        return "Müşteri İptal";
      default:
        return "Belirsiz";
    }
  }

  Color _getRandevuDurumColor(dynamic status) {
    if (status == null) return Colors.grey;

    String statusStr = status.toString();
    switch (statusStr) {
      case '0':
        return Color(0xFFF59E0B); // Turuncu
      case '1':
        return Color(0xFF10B981); // Yeşil
      case '2':
        return Color(0xFFEF4444); // Kırmızı
      case '3':
        return Color(0xFF8B5CF6); // Mor
      default:
        return Colors.grey;
    }
  }


  @override
  Widget build(BuildContext context) {
    if (randevular.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Bugün için randevu bulunmuyor',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: randevular.length,
      itemBuilder: (context, index) {
        final randevu = randevular[index];

        // Müşteri adını güvenli şekilde al
        final musteriler = randevu["musteriler"] as Map<String, dynamic>?;
        final users = randevu["users"] as Map<String, dynamic>?;
        final musteriAdi = musteriler?['name']?.toString() ??
            users?['name']?.toString() ??
            randevu["musteri_adi"]?.toString() ??
            "Müşteri Adı Yok";

        // Hizmet adını güvenli şekilde al
        final hizmetler = randevu["hizmetler"];
        String hizmetAdi = "Hizmet Adı Yok";

        if (hizmetler != null) {
          if (hizmetler is List && hizmetler.isNotEmpty) {
            final ilkHizmet = hizmetler[0];
            if (ilkHizmet is Map) {
              hizmetAdi = ilkHizmet["hizmetler"]["hizmet_adi"]?.toString() ?? "Hizmet Adı Yok";
            } else if (ilkHizmet is String) {
              hizmetAdi = ilkHizmet;
            }
          } else if (hizmetler is Map) {
            hizmetAdi = hizmetler["hizmetler"]["hizmet_adi"]?.toString() ?? "Hizmet Adı Yok";
          } else if (hizmetler is String) {
            hizmetAdi = hizmetler;
          }
        }

        final saat = randevu["saat"]?.toString() ?? "";
        final personelAdi = randevu["personel_adi"]?.toString() ?? "";
        final durum = randevu["durum"]?.toString();

        return Container(
          margin: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            shadowColor: Colors.black.withOpacity(0.1),
            child: ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF667EEA).withOpacity(0.3),
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.calendar_today_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              title: Text(
                musteriAdi,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Colors.grey.shade800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),


              trailing: _buildRandevuStatusBadge(durum),
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              onTap: () => _showRandevuDetails(context, randevu),
            ),
          ),
        );
      },
    );
  }}
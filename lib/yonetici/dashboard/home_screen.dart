
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
import '../../Frontend/sfdatatable.dart';
import '../../Models/ajanda.dart';
import '../../Models/dashboard.dart';
import '../../Models/e_asistan.dart';
import '../../Models/musteri_danisanlar.dart';
import '../../Models/paketler.dart';
import '../../Models/sms_taslaklari.dart';
import '../../Models/user.dart';
import '../adisyonlar/yeniadisyon.dart';
import '../diger/menu/musteriler/yeni_musteri.dart';
import 'bildirimler/bildirimler.dart';
import 'deneme.dart';
import 'gunlukRaporlar/gunlukajandanotlari.dart';
import 'gunlukRaporlar/ongorusmeraporlari.dart';
import 'gunlukRaporlar/paketsatislaridashboard.dart';
import 'gunlukRaporlar/randevular.dart';
import 'gunlukRaporlar/urunsatislaridashboard.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'ozetsayfasi.dart';

import 'package:badges/badges.dart' as badges; //added on 8.7.2024

class DashBoard extends StatefulWidget{
  final Kullanici kullanici;
  final dynamic isletmebilgi;
  DashBoard({Key? key,required this.kullanici,required this.isletmebilgi}) : super(key: key);


  @override
  _HomeState createState() => _HomeState();


}


class _HomeState extends State<DashBoard> {
  List<Map<String, dynamic>> notesList = [];

  void _updateAgendaList(Map<String, dynamic> newNote) {
    setState(() {
      ozetsayfabilgi.ajanda.add(newNote);
    });
  }
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
  bool isloading=true;
  Future<void> _refreshPage() async {
    // Simulate a network request for new data

    setState(() {
      @override
      Widget build(BuildContext context) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: DashBoard(kullanici: widget.kullanici,isletmebilgi: widget.isletmebilgi,),
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    initialize();

  }

  Future<void> initialize() async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    isletmeadi = localStorage.getString('isletmeadi')!;
    log('Giriş yapan kullanıcı '+localStorage.getString('user')!);
    seciliisletme = await secilisalonid();

    int bugunYarinTimestamp = DateTime.now().millisecondsSinceEpoch;


    OzetSayfasi ozet = await dashboardGunlukRapor(seciliisletme!);

    // Günlük asistan verilerini al

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

  @override
  Widget build(BuildContext context) {
    double _ratingValue = 0;
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;


    return Scaffold(
      resizeToAvoidBottomInset: false,


      backgroundColor: Color(0xFFF5F5F5),

      body: isloading ? Center(child:CircularProgressIndicator()): ScaffoldLayoutBuilder(
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
                      parent: ClampingScrollPhysics()
                  ),

                  child:
                  Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            height: 260,
                            width: double.infinity,
                            decoration: const BoxDecoration(
                                image: DecorationImage(image: AssetImage('images/randevumcepte.jpg'),fit: BoxFit.fill),
                                borderRadius: BorderRadius.only(

                                    bottomLeft: Radius.circular(20),
                                    bottomRight: Radius.circular(20)
                                )),
                          ),

                          Container(

                            child: Column(

                                children: [
                                  kullanicirolu<5 ?
                                  SizedBox(height: 50,)
                                      :
                                  SizedBox(height: 100,),
                                  if(kullanicirolu<5)
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,

                                      children:[
                                        Container( padding: EdgeInsets.only(left: 20),
                                          child: ElevatedButton(
                                            onPressed: (){},
                                            child:
                                            Row(

                                              children: [
                                                Text(ozetsayfabilgi.isletmepuani+" / 5" as String,style:TextStyle(fontSize: 15,color: Colors.white),)


                                              ],),
                                            style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,

                                                shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(5.0)
                                                ),
                                                minimumSize: Size(1, 35)
                                            ),
                                          ),),

                                        Container(padding:EdgeInsets.only(right: 30),
                                            child: Text(ozetsayfabilgi.kalansms+" SMS" as String,style:TextStyle(color: Colors.white,fontSize: 18),)
                                        ),

                                      ],

                                    ),
                                  if(kullanicirolu<5)
                                    Container(
                                        width : width* 0.9,padding: EdgeInsets.only(right: 200,),
                                        child:  RatingBar(
                                            initialRating: double.parse(ozetsayfabilgi.isletmepuani),
                                            direction: Axis.horizontal,
                                            allowHalfRating: true,
                                            itemSize: 18,
                                            itemCount: 5,
                                            itemPadding: EdgeInsets.symmetric(horizontal: 3.0),
                                            ratingWidget: RatingWidget(
                                                full: const Icon(Icons.star, color: Colors.yellow),
                                                half: const Icon(
                                                  Icons.star_half,
                                                  color: Colors.yellow,
                                                ),
                                                empty: const Icon(
                                                  Icons.star_outline,
                                                  color: Colors.yellow,
                                                )
                                            ),
                                            onRatingUpdate: (value) {
                                              setState(() {
                                                _ratingValue = value;
                                              });
                                            }
                                        )


                                    ),
                                  Container(decoration: const BoxDecoration(
                                      borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(15),
                                          topRight: Radius.circular(15),
                                          bottomLeft: Radius.circular(15),
                                          bottomRight: Radius.circular(15)
                                      ),
                                      color: Colors.white),
                                    width : width* 0.9,
                                    height: 180,

                                    padding: EdgeInsets.only(top: 15),


                                    child: Column(

                                      children: [
                                        Padding(padding: EdgeInsets.only(bottom: 10,right: 10),child:  Text('Günlük Raporlar',style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold),),),


                                        Wrap(
                                          spacing: 5.0, // Horizontal spacing between buttons
                                          runSpacing: 5.0, // Vertical spacing between lines of buttons
                                          alignment: WrapAlignment.center, // Center-align buttons
                                          children: [
                                            ElevatedButton(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  PageTransition(
                                                    type: PageTransitionType.rightToLeft,
                                                    duration: Duration(milliseconds: 500),
                                                    child: RandevularDashboard(isletmebilgi: widget.isletmebilgi),
                                                  ),
                                                );
                                              },
                                              child: Column(
                                                children: [
                                                  Text('Randevular'),
                                                  Text(ozetsayfabilgi.randevusayisi.toString()),
                                                ],
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Color(0xFF5E35B1),
                                                foregroundColor: Colors.white,
                                                elevation: 5,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(5.0),
                                                ),
                                                minimumSize: Size(150, 50),
                                              ),
                                            ),
                                            ElevatedButton(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  PageTransition(
                                                    type: PageTransitionType.rightToLeft,
                                                    duration: Duration(milliseconds: 500),
                                                    child: OnGorusmelerDashboard(isletmebilgi: widget.isletmebilgi),
                                                  ),
                                                );
                                              },
                                              child: Column(
                                                children: [
                                                  Text('Ön Görüşme'),
                                                  Text(ozetsayfabilgi.ongorusmesayisi.toString()),
                                                ],
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                foregroundColor: Colors.white,
                                                backgroundColor: Color(0xFF9C27B0),
                                                elevation: 5,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(5.0),
                                                ),
                                                minimumSize: Size(150, 50),
                                              ),
                                            ),
                                            ElevatedButton(onPressed: (){
                                              Navigator.push(context, PageTransition(type: PageTransitionType.rightToLeft,duration: Duration(milliseconds:500), child: PaketSatislariDashboard(isletmebilgi: widget.isletmebilgi,)));
                                            }, child: Column(
                                              children: [
                                                Text('Paket Satışı'),
                                                Text(ozetsayfabilgi.paketsatissayisi.toString())
                                              ],
                                            ),
                                              style: ElevatedButton.styleFrom(
                                                  backgroundColor: Color(0xFFEA80FC),
                                                  foregroundColor: Colors.white,
                                                  elevation: 5,
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(5.0)
                                                  ),
                                                  minimumSize: Size(150,50)
                                              ),
                                            ),
                                            ElevatedButton(onPressed: (){
                                              Navigator.push(context, PageTransition(type: PageTransitionType.rightToLeft,duration: Duration(milliseconds:500), child: UrunSatislariDashboard(isletmebilgi: widget.isletmebilgi,)));
                                            },

                                              child: Column(
                                                children: [
                                                  Text('Ürün Satışı'),
                                                  Text(ozetsayfabilgi.urunsatissayisi.toString())
                                                ],
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                  foregroundColor: Colors.white,
                                                  backgroundColor: Color(0xFF1976D2),
                                                  elevation: 5,
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(5.0)
                                                  ),
                                                  minimumSize: Size(150,50)
                                              ),
                                            ),

                                            // Add more buttons as needed
                                          ],
                                        ),


                                      ],
                                    ),


                                  ),
                                  Container(
                                      width: MediaQuery.of(context).size.width,
                                      height: MediaQuery.of(context).size.height*0.62,
                                      child: Column(
                                        children: [
                                          if(kullanicirolu != 4)
                                            Padding(
                                              padding: const EdgeInsets.only(right: 115,top: 5),
                                              child: Text('Aylık Satış Performansı',style: TextStyle(fontWeight:FontWeight.bold,fontSize: 16),),
                                            ),
                                          if(kullanicirolu != 4)
                                            SizedBox(height: 5,),
                                          if(kullanicirolu != 4)
                                            Container(
                                              width: width*0.95,
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [

                                                  ElevatedButton(onPressed: (){
                                                    Navigator.push(context, PageTransition(type: PageTransitionType.rightToLeft,duration: Duration(milliseconds:500), child: KasaRaporu(isletmebilgi: widget.isletmebilgi,)));
                                                  }, style: ElevatedButton.styleFrom(
                                                      backgroundColor: Color(0xFFB39DDB),

                                                      foregroundColor: Colors.white,
                                                      elevation: 8,
                                                      textStyle: const TextStyle(
                                                        color: Colors.white, fontSize: 13,
                                                      ),
                                                      minimumSize:Size(150,65),
                                                      shape: const RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.all(Radius.circular(5)))
                                                  ),

                                                      child: Column(
                                                        children: [
                                                          Text((kullanicirolu<5 ?'Kasa':'Toplam Satış') ,style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15),),
                                                          Text(ozetsayfabilgi.toplamkasa.toString() +" ₺",style: TextStyle(fontSize: 17,fontWeight: FontWeight.bold))
                                                        ],
                                                      )

                                                  ),

                                                  SizedBox(width: 5,),
                                                  ElevatedButton(onPressed: (){
                                                    Navigator.push(context, PageTransition(type: PageTransitionType.rightToLeft,duration: Duration(milliseconds:500), child: AlacaklarDashboard(isletmebilgi: widget.isletmebilgi,)));
                                                  }, style: ElevatedButton.styleFrom(
                                                      backgroundColor: Colors.purple[800],
                                                      // background (button) color
                                                      foregroundColor: Colors.white,
                                                      elevation: 8,
                                                      textStyle: const TextStyle(
                                                        color: Colors.white, fontSize: 13,
                                                      ),
                                                      minimumSize:Size(150,65),
                                                      shape: const RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.all(Radius.circular(5)))
                                                  ), child:  Column(
                                                    children: [
                                                      Text((kullanicirolu<5 ?'Alacak':'Prim Hakediş') ,style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15),),
                                                      Text((kullanicirolu<5 ?ozetsayfabilgi.kalantutar.toString() : ozetsayfabilgi.prim.toString()) + " ₺",style: TextStyle(fontSize: 17,fontWeight: FontWeight.bold))
                                                    ],
                                                  ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          if(kullanicirolu < 5 )
                                            Padding(
                                              padding: const EdgeInsets.only(right:108,top: 10),
                                              child: Text('Günlük Santral Raporları',style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold),),
                                            ),
                                          if(kullanicirolu<5)
                                            SingleChildScrollView(
                                              child: Container(
                                                height: 60,margin: EdgeInsets.symmetric(vertical: 8.0),
                                                child: ListView(
                                                  scrollDirection: Axis.horizontal,
                                                  shrinkWrap: true,
                                                  padding: EdgeInsets.only(left: 10,right: 10),
                                                  children: [
                                                    Container(

                                                      child: ElevatedButton(onPressed:(){},
                                                          style: ElevatedButton.styleFrom(
                                                              backgroundColor: Colors.white,
                                                              side: const BorderSide(
                                                                  width: 2,
                                                                  color: Colors.green
                                                              ),
                                                              minimumSize:Size(90,200),
                                                              shape: const RoundedRectangleBorder(
                                                                  borderRadius: BorderRadius.all(Radius.circular(5)))

                                                          ),
                                                          child: Column(children: [
                                                            SizedBox(height: 10,),
                                                            Text('Giden ', style: TextStyle(fontSize: 14,color: Colors.green ),),
                                                            SizedBox(height: 5,),
                                                            Text(ozetsayfabilgi.gidenarama,style: TextStyle(color: Colors.green,fontSize: 17))



                                                          ])),
                                                    ),
                                                    SizedBox(width: 10,),
                                                    Container(


                                                      child: ElevatedButton(onPressed:(){},
                                                          style: ElevatedButton.styleFrom(
                                                              backgroundColor: Colors.white,
                                                              side: const BorderSide(
                                                                  width: 2,
                                                                  color: Color(0xFF6A1B9A)
                                                              ),
                                                              minimumSize:Size(90,200),
                                                              shape: const RoundedRectangleBorder(
                                                                  borderRadius: BorderRadius.all(Radius.circular(5)))

                                                          ),
                                                          child: Column(children: [
                                                            SizedBox(height: 10,),
                                                            Text('Gelen ', style: TextStyle(fontSize: 14,color: Colors.purple[800]),),
                                                            SizedBox(height: 5,),


                                                            Text(ozetsayfabilgi.gelenarama,style: TextStyle(color: Colors.purple[800],fontSize: 17))

                                                          ])
                                                      ),
                                                    ),
                                                    SizedBox(width: 10,),
                                                    Container(


                                                      child: ElevatedButton(onPressed:(){},
                                                          style: ElevatedButton.styleFrom(
                                                              backgroundColor: Colors.white,
                                                              foregroundColor: Colors.white,
                                                              minimumSize:Size(70,200),
                                                              side: const BorderSide(
                                                                  width: 2,
                                                                  color: Color(0xFFFF1744)
                                                              ),
                                                              shape: const RoundedRectangleBorder(
                                                                  borderRadius: BorderRadius.all(Radius.circular(5)))

                                                          ),
                                                          child: Column(children: [
                                                            SizedBox(height: 10,),
                                                            Text('Cevapsız ', style: TextStyle(fontSize: 14,color: Color(0xFFFF1744) ),),
                                                            SizedBox(height: 5,),
                                                            Text(ozetsayfabilgi.cevapsizarama,style: TextStyle(color: Color(0xFFFF1744),fontSize: 17))

                                                          ])),
                                                    ),

                                                  ],
                                                ),
                                              ),
                                            ),
                                          if(kullanicirolu==5)
                                            SizedBox(height: 50,),
                                          // Başlık her zaman görünür olacak
                                          if(kullanicirolu!=5)
                                            Container(
                                              padding: EdgeInsets.all(8),
                                              alignment: Alignment.center,
                                              child: Text(
                                                'Asistanım',
                                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                              ),
                                            ),

                                          if(kullanicirolu!=5)
                                          Expanded(
                                            child: Container(
                                              decoration: const BoxDecoration(
                                                borderRadius: BorderRadius.all(Radius.circular(15)),
                                                color: Colors.white,
                                              ),
                                              width: width * 0.9,
                                              height: height * 0.35,
                                              padding: EdgeInsets.only(top: 5),
                                              child: Column(
                                                children: [

                                                  // İçerik
                                                  Expanded(
                                                    child: FutureBuilder<List<EAsistan>>(
                                                      future: futureEAsistanData,
                                                      builder: (context, snapshot) {
                                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                                          return Center(child: CircularProgressIndicator()); // Yükleniyor animasyonu
                                                        } else if (snapshot.hasError) {
                                                          return Center(child: Text("Veri alınırken hata oluştu"));
                                                        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                                          return Center(
                                                            child: Padding(
                                                              padding: const EdgeInsets.all(16.0),
                                                              child: Text(
                                                                'Tabloda herhangi bir veri mevcut değil',
                                                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                                              ),
                                                            ),
                                                          );
                                                        } else {
                                                          return ListView(
                                                            children: [
                                                              // ListCard burada çağırılıyor
                                                              ListCard(tasks: snapshot.data!),
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
                                      )
                                  )


                                ]
                            ),
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
    return  AppBar(
        elevation: 100,
        title:
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(isletmeadi,style: (TextStyle(color: Colors.white,fontSize:18)),),
            SizedBox(width: 28,),
            Expanded(child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                /*IconButton(onPressed: (){

                },

                  icon: Icon(Icons.question_answer_outlined,color: Colors.white),iconSize: 20,),*/
                ozetsayfabilgi.okunmamisbildirimler != "" || ozetsayfabilgi.okunmamisbildirimler != null
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
                            child: BildirimlerScreen(kullanicirolu: kullanicirolu, isletmebilgi: widget.isletmebilgi,),
                          ),
                        );
                      },
                      icon: Icon(
                        Icons.notifications_active,
                        color: Colors.white,
                      ),
                      iconSize: 20,
                    ),
                    Positioned(
                      right: 10,
                      top: 13, // Adjust this value to pull the badge down
                      child: badges.Badge(
                        badgeStyle: badges.BadgeStyle(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3), // Adjust this to change the badge size
                          badgeColor: Colors.red, // Badge color
                        ),
                        badgeContent: Text(
                          ozetsayfabilgi.okunmamisbildirimler,
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        ),
                        child: SizedBox.shrink(), // We use SizedBox.shrink to make sure Badge itself does not occupy space
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
                        child: BildirimlerScreen(kullanicirolu: kullanicirolu, isletmebilgi: widget.isletmebilgi,),
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.notifications_active,
                    color: Colors.white,
                  ),
                  iconSize: 20,
                ),


                IconButton(onPressed: (){

                  Navigator.push(context, PageTransition(type: PageTransitionType.rightToLeft,duration: Duration(milliseconds:500), child: ProfilBilgileri(kullanici: widget.kullanici,)));
                }, icon:  Icon(Icons.person,color:Colors.white,),iconSize: 20,)
              ],
            )
            )


          ],

        ),
        toolbarHeight: 60,



        backgroundColor:colorAnimated.background


    );
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
        print("Task $index: ${tasks[index]}");
        return ListTile(
          leading: Icon(Icons.task_alt, color: Colors.green),
          title: Text(tasks[index].baslik),
          subtitle: Text(
            tasks[index].mesaj ?? "",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Icon(Icons.chevron_right),
          onTap: () => _showTaskDetails(context, tasks[index]), // Open popup
        );
      },
    );
  }
}


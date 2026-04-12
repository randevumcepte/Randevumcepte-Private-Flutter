import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:randevu_sistem/Frontend/altyuvarlakmenu.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:randevu_sistem/yonetici/dashboard/gunlukRaporlar/randevus/salontarafindanrandevular.dart';
import 'package:randevu_sistem/yonetici/dashboard/gunlukRaporlar/randevus/tumrandevular.dart';
import 'package:randevu_sistem/yonetici/dashboard/gunlukRaporlar/randevus/uygulamauzerindenrandevular.dart';
import 'package:randevu_sistem/yonetici/dashboard/gunlukRaporlar/randevus/webuzerindenrandevular.dart';





class RandevularDashboard extends StatefulWidget {
  final dynamic isletmebilgi;
  final int kullanicirolu;
  const RandevularDashboard({Key? key,required this.isletmebilgi,required this.kullanicirolu}) : super(key: key);

  @override
  _RandevularDashboardState createState() =>
      _RandevularDashboardState();
}


class _RandevularDashboardState extends State<RandevularDashboard> {
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DefaultTabController(
        length: 4,
        child: Scaffold(
          // floatingActionButton: AltYuvarlakYeniEkleMenu(isletme_bilgi: widget.isletmebilgi,),

          appBar: AppBar(
            centerTitle: false,
            title: const Text('Randevular',style: TextStyle(color: Colors.black),),
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: <Widget>[
              if (widget.isletmebilgi["demo_hesabi"].toString() == "1")
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: SizedBox(
                  width: 100, // <-- Your width
                  child: YukseltButonu(isletme_bilgi: widget.isletmebilgi,)
                ),
              ),




            ],

            backgroundColor: Colors.white,


            bottom: TabBar(   isScrollable: true,
                indicatorSize: TabBarIndicatorSize.label,
                labelColor: Colors.purple,
                unselectedLabelColor: Colors.purple[800],
                labelPadding: EdgeInsets.only(left: 10, right: 10),
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  color: Colors.transparent, // This will be transparent so that we can apply a custom decoration
                  border: Border.all(
                    color: Colors.purple[800]!,
                    width: 1.5,
                  ),
                ),

                tabs: [

                  Tab(
                    child: Container(
                      width: 130,
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Center(
                          child: Text("Tümü",style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
                        ),
                      ),
                    ),
                  ),
                  Tab(
                    child: Container(
                      width: 150,
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Center(
                          child: Text("İşletme",style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
                        ),
                      ),
                    ),
                  ),
                  Tab(
                    child: Container(

                      width: 130,
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Center(
                          child: Text("Web",style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
                        ),
                      ),
                    ),
                  ),
                  Tab(
                    child: Container(
                      width: 150,
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Center(
                          child: Text("Uygulama",style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
                        ),
                      ),
                    ),
                  ),

                ]),


          ),


          body: TabBarView(
            children: <Widget>[
              TumRandevular(isletmebilgi: widget.isletmebilgi, kullanicirolu: widget.kullanicirolu,),
              SalonTarafindan(isletmebilgi: widget.isletmebilgi, kullanicirolu: widget.kullanicirolu),
              WebUzerinden(isletmebilgi: widget.isletmebilgi, kullanicirolu: widget.kullanicirolu),
              UygulamaUzerinden(isletmebilgi: widget.isletmebilgi, kullanicirolu: widget.kullanicirolu)

            ],
          ),
        ),
      ),
    );
  }
}
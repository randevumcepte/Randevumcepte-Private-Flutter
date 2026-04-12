import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';

import '../../../Frontend/altyuvarlakmenu.dart';
import 'gelirler.dart';
import 'giderler.dart';
import 'toplamkasa.dart';


class KasaDashboard extends StatefulWidget {
  final dynamic isletmebilgi;
  const KasaDashboard({Key? key,required this.isletmebilgi}) : super(key: key);

  @override
  _KasaDashboardState createState() =>
      _KasaDashboardState();
}


class _KasaDashboardState extends State<KasaDashboard> {
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DefaultTabController(
        length: 3,
        child: Scaffold(
          //  floatingActionButton: AltYuvarlakYeniEkleMenu(isletme_bilgi: widget.isletmebilgi,),
          appBar: AppBar(
            title:Text('Kasa',style: TextStyle(color:Colors.black),),
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
            toolbarHeight: 60,
            actions: [
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


            bottom: TabBar(indicatorSize: TabBarIndicatorSize.label,
                unselectedLabelColor: Colors.purple[800],
labelPadding: EdgeInsets.only(left: 2,right: 2),
                indicator: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [Color(0xFF6A1B9A), Colors.purpleAccent]),

                    borderRadius: BorderRadius.circular(5),
                    color: Colors.purple[800]),
                tabs: [

              Tab(
                child: Align(
                  alignment: Alignment.center,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 8,),
                      Text("22.160.000.00",style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold),),
                      Text("Gelir"),

                    ],
                  ),
                ),
              ),
              Tab(
                child: Align(
                  alignment: Alignment.center,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 8,),
                      Text("22.60.000.00",style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold),),
                      Text("Gider"),

                    ],
                  ),
                ),
              ),
              Tab(
                child: Align(
                  alignment: Alignment.center,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 8,),
                      Text("11.100.000.00",style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold),),
                      Text("Toplam"),

                    ],
                  ),
                ),
              ),
            ]),

          ),


          body: TabBarView(
            children: <Widget>[
              GelirlerDashboard(),
              GiderlerDashboard(),
              ToplamKasaDashboard()
            ],
          ),
        ),
      ),
    );
  }
}
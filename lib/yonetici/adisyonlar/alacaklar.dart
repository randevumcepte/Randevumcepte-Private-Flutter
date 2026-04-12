import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:randevu_sistem/yeni/yeni_%C3%BCr%C3%BCn_satis_stok.dart';
import 'package:randevu_sistem/yeni/yeni_masraf.dart';
import 'package:randevu_sistem/yonetici/adisyonlar/alacaktaksitler.dart';

import 'alacaksenetler.dart';



class AlacaklarScreen extends StatefulWidget {
  const AlacaklarScreen({Key? key}) : super(key: key);

  @override
  _AlacaklarScreenState createState() =>
      _AlacaklarScreenState();
}


class _AlacaklarScreenState extends State<AlacaklarScreen> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title:Text('Alacaklar',style: TextStyle(color:Colors.black),),
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
            toolbarHeight: 60,
            actions: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: SizedBox(
                  width: 100, // <-- Your width
                  child:YukseltButonu(isletme_bilgi: null,)
                ),
              ),


            ],
            backgroundColor: Colors.white,


            bottom: TabBar(indicatorSize: TabBarIndicatorSize.label,
                unselectedLabelColor: Colors.purple[800],
                labelPadding: EdgeInsets.only(left: 40,right: 40),
                indicator: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [Color(0xFF6A1B9A), Colors.purpleAccent]),

                    borderRadius: BorderRadius.circular(10),
                    color: Colors.purple[800]),
                tabs: [

                  Tab(
                    child: Align(
                      alignment: Alignment.center,
                      child:
                      Text("Taksitler",style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
                    ),
                  ),

                  Tab(
                    child: Align(
                      alignment: Alignment.center,
                      child:

                      Text("Senetler",style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),


                    ),
                  ),
                ]),

          ),
          body: TabBarView(
            children: <Widget> [
              AlacakTaksitler(),
              AlacakSenetler(),
            ],
          ),
        ),
      ),
    );
  }
}
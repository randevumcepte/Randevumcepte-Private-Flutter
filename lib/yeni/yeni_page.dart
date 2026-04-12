import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:randevu_sistem/yeni/yeni_%C3%BCr%C3%BCn_satis_stok.dart';
import 'package:randevu_sistem/yeni/yeni_masraf.dart';

import 'calisan_secim.dart';

/*class YeniScreen extends StatefulWidget {
  final dynamic isletmebilgi;
  const YeniScreen({Key? key,required this.isletmebilgi}) : super(key: key);

  @override
  _YeniScreenState createState() =>
      _YeniScreenState();
}*/

/*
class _YeniScreenState extends State<YeniScreen> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Image.asset(
                'images/randevu-sistemim.png',
                fit: BoxFit.contain,
                height: 80,
                width: 150,),
            ),
            toolbarHeight: 60,
            actions: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: SizedBox(
                  width: 100, // <-- Your width
                  child: YukseltButonu()
                ),
              ),


            ],
            backgroundColor: Colors.white,


            bottom: TabBar(

              tabs: [
                Tab( text: "Yeni Randevu",),
                Tab( text: "Yeni Masraf"),
                Tab( text: "Yeni Ürün Satışı"),
              ],
              indicator: UnderlineTabIndicator(
                  borderSide: BorderSide(width: 3.0),
                  insets: EdgeInsets.symmetric(horizontal:18.0)
              ),
              labelColor: Colors.black,
              unselectedLabelColor: Colors.deepPurple,
              labelPadding: EdgeInsets.zero,

            ),

          ),
          body: TabBarView(
            children: <Widget> [
              CalisanSecimi(isletmebilgi:widget.isletmebilgi),
              YeniMasraf(),
              YeniUrunSatis(),
            ],
          ),
        ),
      ),
    );
  }
}*/
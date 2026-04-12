import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';

import 'package:randevu_sistem/yeni/yeni_%C3%BCr%C3%BCn_satis_stok.dart';
import 'package:randevu_sistem/yonetici/adisyonlar/odeme.dart';
import 'detay.dart';


class MusteriAdisyon extends StatefulWidget {
  const MusteriAdisyon({Key? key}) : super(key: key);

  @override
  _MusteriAdisyonState createState() =>
      _MusteriAdisyonState();
}


class _MusteriAdisyonState extends State<MusteriAdisyon> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),

          ),
          actions: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: SizedBox(
                width: 100, // <-- Your width
                child: YukseltButonu(isletme_bilgi: null,)
              ),
            ),
          ],

          bottom: TabBar(
            tabs: [
              Tab(text: "Detay",),
              Tab( text: "Ödeme"),

            ],
            labelPadding: EdgeInsets.zero,
            indicator: UnderlineTabIndicator(
                borderSide: BorderSide(width: 3.0),
                insets: EdgeInsets.symmetric(horizontal:18.0)
            ),
            labelColor: Colors.black,
            unselectedLabelColor: Colors.deepPurple,
          ),

          title: Text('Adisyon Detayı',style: TextStyle(color: Colors.black),),
          backgroundColor: Colors.white,
          toolbarHeight: 60,
        ),
        body: TabBarView(
          children: <Widget> [
            MusteriDetay(),
            Odeme(),
          ],
        ),
      ),
    );
  }
}
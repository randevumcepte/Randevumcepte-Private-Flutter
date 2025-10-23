import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:randevu_sistem/yonetici/diger/kurulum/unisex.dart';
import 'package:randevu_sistem/yonetici/diger/kurulum/yeni_hizmet.dart';
import 'erkekler.dart';
import 'kadinlar.dart';




class Hizmetler extends StatefulWidget {
  const Hizmetler({Key? key}) : super(key: key);

  @override
  _HizmetlerState createState() =>
      _HizmetlerState();
}


class _HizmetlerState extends State<Hizmetler> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          toolbarHeight: 60,

          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              tooltip: 'Hizmet Ekle',
              icon: Icon(
                Icons.add,
                color: Colors.black,
                size: 25.0,),

              onPressed: (){
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => YeniHizmet(isletmebilgi: null,)),
                );
              },

            ),
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
              Tab( text: "Kadınlar",),
              Tab( text: "Erkekler"),
              Tab( text: "Unisex"),
            ],
            labelPadding: EdgeInsets.zero,
            indicator: UnderlineTabIndicator(
                borderSide: BorderSide(width: 3.0),
                insets: EdgeInsets.symmetric(horizontal:18.0)
            ),
            labelColor: Colors.black,
            unselectedLabelColor: Colors.deepPurple,

          ),

          title: Text('Hizmetler',style: TextStyle(color: Colors.black),),
        ),
        body: TabBarView(
          children: <Widget> [
            Kadinlar(),
            Erkekler(),
            Unisex(),
          ],
        ),
      ),
    );
  }
}
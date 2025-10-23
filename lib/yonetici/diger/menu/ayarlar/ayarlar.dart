import 'package:flutter/material.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:randevu_sistem/yonetici/diger/menu/ayarlar/odalar/odalar.dart';

import 'package:randevu_sistem/yonetici/diger/menu/ayarlar/personeller/calisma_saatleri.dart';
import 'package:randevu_sistem/yonetici/diger/menu/ayarlar/personeller/personeller.dart';
import 'package:randevu_sistem/yonetici/diger/menu/ayarlar/randevuayarlari.dart';
import 'package:randevu_sistem/yonetici/diger/menu/ayarlar/urunler/urunler.dart';



import 'cihazlar/cihazlar.dart';
import 'hizmetler/hizmetler.dart';
import 'musteriindirimleri/musteriindirimpage.dart';

class Ayarlar extends StatefulWidget {
  final dynamic isletmebilgi;
  const Ayarlar({Key? key,required this.isletmebilgi}) : super(key: key);

  @override
  _AyarlarState createState() =>
      _AyarlarState();
}

class _AyarlarState extends State<Ayarlar> {
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(

      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text("Ayarlar",style: TextStyle(color: Colors.black,fontSize: 18),),
        toolbarHeight: 60,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
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
      ),
      body: _buildListView(),
    );
  }

  ListView _buildListView(){
    return ListView(
      children: <Widget>[
        ListTile(
          title: Text('Çalışma Saatleri'),
          trailing: Icon(Icons.keyboard_arrow_right,color:Colors.purple),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => CalismaSaatleri(isletmebilgi: widget.isletmebilgi,)),
            );
          },
        ),
        Divider(),
        ListTile(
          title: Text('Personeller'),
          trailing: Icon(Icons.keyboard_arrow_right,color:Colors.purple),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => Personeller(isletmebilgi: widget.isletmebilgi,)),
            );
          },
        ),
        Divider(),
        ListTile(
          title: Text('Hizmetler'),
          trailing: Icon(Icons.keyboard_arrow_right,color:Colors.purple),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => Hizmetler(isletmebilgi: widget.isletmebilgi,)),
            );
          },
        ),
        Divider(),
        ListTile(
          title: Text('Cihazlar'),
          trailing: Icon(Icons.keyboard_arrow_right,color:Colors.purple),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => Cihazlar(isletmebilgi: widget.isletmebilgi)),
            );
          },
        ),
        Divider(),
        ListTile(
          title: Text('Odalar'),
          trailing: Icon(Icons.keyboard_arrow_right,color:Colors.purple),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => Odalar(isletmebilgi: widget.isletmebilgi,)),
            );
          },
        ),

        Divider(),
        ListTile(
          title: Text('Randevu Ayarları'),
          trailing: Icon(Icons.keyboard_arrow_right,color:Colors.purple),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => RandevuAyarlari(isletmebilgi: widget.isletmebilgi,)),
            );
          },
        ),
        Divider(),
        ListTile(
          title: Text('Müşteri İndirimleri'),
          trailing: Icon(Icons.keyboard_arrow_right,color:Colors.purple),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => MusteriIndirimleri(isletmebilgi:widget.isletmebilgi)),
            );
          },
        ),


        Divider(),
      ],
    );


  }
}
import 'package:flutter/material.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:randevu_sistem/yeni/tarih_secimi.dart';

import '../yonetici/diger/menu/musteriler/yeni_musteri.dart';


class MusteriSecim extends StatefulWidget {
  final dynamic isletmebilgi;
  final int kullanicirolu;
  const MusteriSecim({Key? key,required this.isletmebilgi,required this.kullanicirolu}) : super(key: key);

  @override
  _MusteriSecimState createState() =>
      _MusteriSecimState();
}

class _MusteriSecimState extends State<MusteriSecim> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text("Müşteri Seç",style: TextStyle(color: Colors.black,),),
        backgroundColor: Colors.white,
        toolbarHeight: 60,
        actions: [
          IconButton(
              icon: Icon(
                  Icons.add,
                  color: Colors.black,
                  size: 25.0),
              onPressed: (){Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => Yenimusteri(kullanicirolu: widget.kullanicirolu, isletmebilgi:widget.isletmebilgi,isim:"",telefon: "",sadeceekranikapat: false,)),
              );}

          ),
          if (widget.isletmebilgi["demo_hesabi"].toString() == "1")
            Padding(

              padding: const EdgeInsets.all(12.0),
              child: SizedBox(
                width: 90, // <-- Your width
                child: YukseltButonu(isletme_bilgi: widget.isletmebilgi,)
              ),
            ),

        ],

      ),

      body: _buildListView(),
    );
  }ListView _buildListView() {
    return ListView(
      children: <Widget>[
        ListTile(
          title: Text('Ferdi Korkmaz'),
          trailing: Icon(Icons.keyboard_arrow_right),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => TakvimSecimi()),
            );
          },
        ),
        ListTile(
          title: Text('Gülşah Korkmaz'),
          trailing: Icon(Icons.keyboard_arrow_right),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => TakvimSecimi()),
            );
          },
        ),

      ],
    );
  }
}
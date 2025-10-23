 import 'package:flutter/material.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import '../yonetici/diger/menu/musteriler/yeni_musteri.dart';
import 'musteri_bilgi.dart';


class MusteriList extends StatefulWidget {
  final dynamic isletmebilgi;
  const MusteriList({Key? key,required this.isletmebilgi}) : super(key: key);

  @override
  _MusteriListState createState() =>
      _MusteriListState();
}

class _MusteriListState extends State<MusteriList> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
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
            if (widget.isletmebilgi["demo_hesabi"].toString() == "1")
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: SizedBox(
                width: 100, // <-- Your width
                child: YukseltButonu(isletme_bilgi: widget.isletmebilgi,),
              ),
            ),


          ],
          backgroundColor: Colors.white,


        ),

        body: _buildListView(),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.deepPurple,
          child: Icon(Icons.add_circle),
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) =>  Yenimusteri(isletmebilgi:widget.isletmebilgi,isim:"",telefon: "",sadeceekranikapat: false,)),);
          },
        ),
      ),
    );
  }ListView _buildListView() {
    return ListView(
      children: <Widget>[
        ListTile(
          title: Text('İlayda Kızak'),
          trailing: Icon(Icons.keyboard_arrow_right),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => MusteriBilgi()),
            );
          },
        ),

        ListTile(
          title: Text('Esra Demirbaş'),
          trailing: Icon(Icons.keyboard_arrow_right),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => MusteriBilgi()),
            );
          },
        ),
        ListTile(
          title: Text('Sibel Çakmak'),
          trailing: Icon(Icons.keyboard_arrow_right),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => MusteriBilgi()),
            );
          },
        ),
        ListTile(
          title: Text('Burak Güleç'),
          trailing: Icon(Icons.keyboard_arrow_right),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => MusteriBilgi()),
            );
          },
        ),
        ListTile(
          title: Text('Zerrin Demirci'),
          trailing: Icon(Icons.keyboard_arrow_right),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => MusteriBilgi()),
            );
          },
        ),
        ListTile(
          title: Text('Ahmet Topal'),
          trailing: Icon(Icons.keyboard_arrow_right),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => MusteriBilgi()),
            );
          },
        ),
        ListTile(
          title: Text('Aysel Açıkalın'),
          trailing: Icon(Icons.keyboard_arrow_right),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => MusteriBilgi()),
            );
          },
        ),
        ListTile(
          title: Text('Mehmet Türkan'),
          trailing: Icon(Icons.keyboard_arrow_right),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => MusteriBilgi()),
            );
          },
        ), ListTile(
          title: Text('Hakan Demir'),
          trailing: Icon(Icons.keyboard_arrow_right),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => MusteriBilgi()),
            );
          },
        ),
        ListTile(
          title: Text('Ahmet Servet'),
          trailing: Icon(Icons.keyboard_arrow_right),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => MusteriBilgi()),
            );
          },
        ), ListTile(
          title: Text('Recep Şentürk'),
          trailing: Icon(Icons.keyboard_arrow_right),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => MusteriBilgi()),
            );
          },
        ),




      ],
    );
  }
}
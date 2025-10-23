import 'package:flutter/material.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:randevu_sistem/yonetici/diger/kurulum/yeni_calisan.dart';


import 'calisan_duzenle.dart';



class Calisanlar extends StatefulWidget {
  final dynamic isletmebilgi;
  const Calisanlar({Key? key,required this.isletmebilgi}) : super(key: key);

  @override
  _CalisanlarState createState() =>
      _CalisanlarState();
}

class _CalisanlarState extends State<Calisanlar> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Çalışanlar",style: TextStyle(color: Colors.black),),
        backgroundColor: Colors.white,
        toolbarHeight: 60,

        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            tooltip: 'Yeni Çalışan Ekle',
            icon: Icon(
              Icons.add,
              color: Colors.black,
              size: 25.0,),

            onPressed: (){
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => YeniCalisan(isletmebilgi: null,)),
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
      ),
      body: _buildListView(),
    );
  }

  ListView _buildListView(){
    return ListView(
      children: <Widget>[
        ListTile(
          title: Text('Cevriye EFE'),
          trailing: Icon(Icons.keyboard_arrow_right),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => CalisanEdit(isletmebilgi: widget.isletmebilgi,)),
            );
          },
        ),
        ListTile(
          title: Text('Anıl Orbey'),
          trailing: Icon(Icons.keyboard_arrow_right),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => CalisanEdit(isletmebilgi: widget.isletmebilgi)),
            );
          },
        ),
        ListTile(
          title: Text('Çağlar Filiz'),
          trailing: Icon(Icons.keyboard_arrow_right),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => CalisanEdit(isletmebilgi: widget.isletmebilgi)),
            );
          },
        ),
      ],
    );


  }
}

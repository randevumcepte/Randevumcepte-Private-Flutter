import 'package:flutter/material.dart';

import '../../yeni/hizmet.dart';



/*class CalisanSecimi1 extends StatefulWidget {
  final dynamic isletmebilgi;
  const CalisanSecimi1({Key? key,required this.isletmebilgi}) : super(key: key);

  @override
  _CalisanSecimi1State createState() =>
      _CalisanSecimi1State();
}

class _CalisanSecimi1State extends State<CalisanSecimi1> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Personel Seçimi",style: TextStyle(color: Colors.black)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.white,
        toolbarHeight: 70,
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
                  builder: (context) => HizmetSecimi(isletmebilgi: widget.isletmebilgi,)),
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
                  builder: (context) => HizmetSecimi(isletmebilgi: widget.isletmebilgi,)),
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
                  builder: (context) => HizmetSecimi(isletmebilgi: widget.isletmebilgi,)),
            );
          },
        ),
      ],
    );


  }
}*/

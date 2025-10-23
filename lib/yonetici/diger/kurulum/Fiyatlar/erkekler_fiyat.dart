import 'package:flutter/material.dart';


import 'fiyat.dart';







class ErkeklerFiyat extends StatefulWidget {
  const ErkeklerFiyat({Key? key}) : super(key: key);

  @override
  _ErkeklerFiyatState createState() =>
      _ErkeklerFiyatState();
}

class _ErkeklerFiyatState extends State<ErkeklerFiyat> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildListView(),
    );
  }

  ListView _buildListView(){
    return ListView(
      children: <Widget>[
        ListTile(
          title: Text('Saç Kesimi'),
          trailing: Icon(Icons.keyboard_arrow_right),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => Fiyat()),
            );
          },
        ),

      ],
    );


  }
}

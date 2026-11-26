

import 'package:flutter/cupertino.dart' hide Text, TextSpan;
import 'package:randevu_sistem/dil/material.dart';

import 'fiyat.dart';







class UnisexFiyat extends StatefulWidget {
  const UnisexFiyat({Key? key}) : super(key: key);

  @override
  _UnisexFiyatState createState() =>
      _UnisexFiyatState();
}

class _UnisexFiyatState extends State<UnisexFiyat> {
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
          title: Text('Cilt Bakımı'),
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

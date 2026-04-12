import 'package:flutter/material.dart';


import 'fiyat.dart';


class KadinlarFiyat extends StatefulWidget {
  const KadinlarFiyat({Key? key}) : super(key: key);

  @override
  _KadinlarFiyatState createState() =>
      _KadinlarFiyatState();
}

class _KadinlarFiyatState extends State<KadinlarFiyat> {
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
          title: Text('Ağda'),
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

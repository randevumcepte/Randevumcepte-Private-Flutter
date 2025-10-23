import 'package:flutter/material.dart';
import 'package:randevu_sistem/yonetici/diger/kurulum/S%C3%BCre/sure.dart';

class KadinlarSure extends StatefulWidget {
  const KadinlarSure({Key? key}) : super(key: key);

  @override
  _KadinlarSureState createState() =>
      _KadinlarSureState();
}

class _KadinlarSureState extends State<KadinlarSure> {
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
                  builder: (context) => Sure()),
            );
          },
        ),

      ],
    );


  }
}

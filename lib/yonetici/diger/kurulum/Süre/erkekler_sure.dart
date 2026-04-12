import 'package:flutter/material.dart';
import 'package:randevu_sistem/yonetici/diger/kurulum/S%C3%BCre/sure.dart';

class ErkeklerSure extends StatefulWidget {
  const ErkeklerSure({Key? key}) : super(key: key);

  @override
  _ErkeklerSureState createState() =>
      _ErkeklerSureState();
}

class _ErkeklerSureState extends State<ErkeklerSure> {
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
                  builder: (context) => Sure()),
            );
          },
        ),

      ],
    );


  }
}

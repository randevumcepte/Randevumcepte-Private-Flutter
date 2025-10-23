import 'package:flutter/material.dart';

import 'hizmet_calisan.dart';





class Erkekler extends StatefulWidget {
  const Erkekler({Key? key}) : super(key: key);

  @override
  _ErkeklerState createState() =>
      _ErkeklerState();
}

class _ErkeklerState extends State<Erkekler> {
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
          leading: Icon(Icons.filter_list_outlined),
          title: Text('Saç Kesimi'),
          trailing: Icon(Icons.keyboard_arrow_right),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => HizmetCalisan()),
            );
          },
        ),

      ],
    );


  }
}

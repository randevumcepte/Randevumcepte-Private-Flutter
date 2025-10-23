import 'package:flutter/material.dart';

import 'hizmet_calisan.dart';





class Kadinlar extends StatefulWidget {
  const Kadinlar({Key? key}) : super(key: key);

  @override
  _KadinlarState createState() =>
      _KadinlarState();
}

class _KadinlarState extends State<Kadinlar> {
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
          title: Text('Ağda'),
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

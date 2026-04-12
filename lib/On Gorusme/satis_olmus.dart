import 'package:flutter/material.dart';




class SatisOlmus extends StatefulWidget {
  const SatisOlmus({Key? key}) : super(key: key);

  @override
  _SatisOlmusState createState() =>
      _SatisOlmusState();
}

class _SatisOlmusState extends State<SatisOlmus> {
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
          title: Text('Cevriye EFE'),
          trailing: Icon(Icons.keyboard_arrow_right),
          onTap: () {

          },
        ),
        ListTile(
          title: Text('Anıl Orbey'),
          trailing: Icon(Icons.keyboard_arrow_right),
          onTap: () {

          },
        ),
        ListTile(
          title: Text('Çağlar Filiz'),
          trailing: Icon(Icons.keyboard_arrow_right),
          onTap: () {

          },
        ),
      ],
    );


  }
}

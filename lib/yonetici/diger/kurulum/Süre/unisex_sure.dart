import 'package:flutter/material.dart';
import 'package:randevu_sistem/yonetici/diger/kurulum/S%C3%BCre/sure.dart';








class UnisexSure extends StatefulWidget {
  const UnisexSure({Key? key}) : super(key: key);

  @override
  _UnisexSureState createState() =>
      _UnisexSureState();
}

class _UnisexSureState extends State<UnisexSure> {
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
                  builder: (context) => Sure()),
            );
          },
        ),

      ],
    );


  }
}

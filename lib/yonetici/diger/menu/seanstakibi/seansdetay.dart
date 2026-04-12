import 'package:flutter/material.dart';
import 'package:randevu_sistem/yonetici/diger/menu/seanstakibi/seansduzenle.dart';

class SeansDetay extends StatefulWidget {
  const SeansDetay({Key? key}) : super(key: key);

  @override
  _SeansDetayState createState() =>
      _SeansDetayState();
}

class _SeansDetayState extends State<SeansDetay> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text("Seanslar",style: TextStyle(color: Colors.black,fontSize: 18),),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        toolbarHeight: 60,
      ),
      body: _buildListView(),
    );
  }

  ListView _buildListView(){
    return ListView(
      children: <Widget>[
        ListTile(
          title: Text('2023-10-12'),
          subtitle: Text('Cevriye EFE'),
          trailing: Icon(Icons.keyboard_arrow_right),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => SeansDuzenle()),
            );
          },
        ),
        Divider(),
        ListTile(
          title: Text('2023-11-12'),
          subtitle: Text('Cevriye EFE'),
          trailing: Icon(Icons.keyboard_arrow_right),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => SeansDuzenle()),
            );
          },
        ),
        Divider(),
        ListTile(
          title: Text('2023-12-12'),
          subtitle: Text('Cevriye EFE'),
          trailing: Icon(Icons.keyboard_arrow_right),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => SeansDuzenle()),
            );
          },
        ),
        Divider(),
      ],
    );



  }
}

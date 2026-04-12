import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:randevu_sistem/musteriler/duzenle.dart';

import 'Randevular.dart';



class MusteriBilgi extends StatefulWidget {
  const MusteriBilgi({Key? key}) : super(key: key);

  @override
  _MusteriBilgiState createState() =>
      _MusteriBilgiState();
}


class _MusteriBilgiState extends State<MusteriBilgi> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
          bottom: TabBar(
            tabs: [
              Tab( text: "Bilgiler",),
              Tab( text: "Randevular"),
            ],
            labelPadding: EdgeInsets.zero,
            indicator: UnderlineTabIndicator(
                borderSide: BorderSide(width: 3.0),
                insets: EdgeInsets.symmetric(horizontal:18.0)
            ),
            labelColor: Colors.black,
            unselectedLabelColor: Colors.deepPurple,


          ),
          toolbarHeight: 50,

          title: Text('Müşteri Detayları',style: TextStyle(color: Colors.black),),
          backgroundColor: Colors.white,
          actions: [
            IconButton(
                icon: Icon(
                    Icons.add,
                    color: Colors.black,
                    size: 25.0),
                onPressed: (){Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => EditPage()),
                );}

            ),
          ],
        ),
        body: TabBarView(
          children: <Widget> [
            Center(child: Text("Bilgiler "),),
            MusteriRandevu(),
          ],
        ),
      ),
    );
  }
}
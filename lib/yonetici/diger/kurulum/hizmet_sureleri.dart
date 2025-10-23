import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'Süre/erkekler_sure.dart';
import 'Süre/kadınlar_sure.dart';
import 'Süre/unisex_sure.dart';


class HizmetSureleri extends StatefulWidget {
 const HizmetSureleri({Key? key}) : super(key: key);

 @override
 _HizmetSureleriState createState() =>
     _HizmetSureleriState();
}


class _HizmetSureleriState extends State<HizmetSureleri> {
 @override
 Widget build(BuildContext context) {
  return DefaultTabController(
   length: 3,
   child: Scaffold(
    appBar: AppBar(
     backgroundColor: Colors.white,
     toolbarHeight: 60,
     leading: IconButton(
      icon: Icon(Icons.arrow_back, color: Colors.black),
      onPressed: () => Navigator.of(context).pop(),
     ),
     bottom: TabBar(
      tabs: [
       Tab( text: "Kadınlar",),
       Tab( text: "Erkekler"),
       Tab( text: "Unisex"),
      ],
      indicator: UnderlineTabIndicator(
          borderSide: BorderSide(width: 3.0),
          insets: EdgeInsets.symmetric(horizontal:18.0)
      ),
      labelColor: Colors.black,
      unselectedLabelColor: Colors.deepPurple,
      labelPadding: EdgeInsets.zero,
     ),
     actions: [
      Padding(
       padding: const EdgeInsets.all(12.0),
       child: SizedBox(
        width: 100, // <-- Your width
        child: YukseltButonu(isletme_bilgi: null,)
       ),
      ),

     ],
     title: Text('Hizmet Süreleri',style: TextStyle(color: Colors.black),),
    ),
    body: TabBarView(
     children: <Widget> [
      KadinlarSure(),
      ErkeklerSure(),
      UnisexSure(),
     ],
    ),
   ),
  );
 }
}
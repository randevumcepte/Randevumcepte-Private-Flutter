import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:randevu_sistem/On%20Gorusme/satis_olmus.dart';
import 'package:randevu_sistem/On%20Gorusme/tumu.dart';

/*class OnGorusme extends StatefulWidget {
  const OnGorusme({Key? key}) : super(key: key);

  @override
  _OnGorusmeState createState() =>
      _OnGorusmeState();
}


class _OnGorusmeState extends State<OnGorusme> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Image.asset(
                'images/randevu-sistemim.png',
                fit: BoxFit.contain,
                height: 80,
                width: 150,),
            ),
            toolbarHeight: 60,
            actions: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: SizedBox(
                  width: 100, // <-- Your width
                  child: YukseltButonu()
                ),
              ),


            ],
            backgroundColor: Colors.white,


            bottom: TabBar(

              tabs: [
                Tab(text: "Tümü",),
                Tab(text: "Satış Yapılanlar"),
                Tab(text: "Satış Yapılmayanlar"),
              ],
              indicator: UnderlineTabIndicator(
                  borderSide: BorderSide(width: 3.0),
                  insets: EdgeInsets.symmetric(horizontal:18.0)
              ),
              labelColor: Colors.black,
              unselectedLabelColor: Colors.deepPurple,
              unselectedLabelStyle: TextStyle(fontSize: 13),
              labelStyle: TextStyle(fontSize: 13),
              labelPadding: EdgeInsets.zero,

            ),

          ),
          body: TabBarView(
            children: <Widget> [
              TumuList(),
              SatisOlmus(),
              Center(child: Text("Satış yapılmamış")),
            ],
          ),
        ),
      ),
    );
  }
}
*/
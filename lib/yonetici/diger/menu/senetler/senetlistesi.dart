import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../raporlar/yeni_senet.dart';
import 'açıksenetler.dart';
import 'kapalısenetler.dart';
import 'odenmemeissenet.dart';
import 'tumsenetler.dart';


class SenetListesi extends StatefulWidget {

  final dynamic isletmebilgi;
  const SenetListesi({Key? key,required this.isletmebilgi}) : super(key: key);

  @override
  _SenetListesiState createState() =>
      _SenetListesiState();
}


class _SenetListesiState extends State<SenetListesi> {
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus(); // Hide the keyboard
      },
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: DefaultTabController(
          length: 4,
          child: Scaffold(


            appBar: AppBar(
              centerTitle: false,
              title: const Text('Senetler',style: TextStyle(color: Colors.black),),
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: <Widget>[
                IconButton(onPressed: (){
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => YeniSenet(isletmebilgi: widget.isletmebilgi,musteridanisanid: "",)),
                  );
                }, icon:  Icon(Icons.add,color:Colors.black,),iconSize: 26,),


              ],

              backgroundColor: Colors.white,


              bottom: PreferredSize(
                preferredSize: Size.fromHeight(60),
                child: Container(

                  padding: EdgeInsets.only(bottom: 10),
                  child: TabBar(   isScrollable: true,
                      indicatorSize: TabBarIndicatorSize.label,
                      labelColor: Colors.purple,
                      unselectedLabelColor: Colors.purple[800],
                      labelPadding: EdgeInsets.symmetric(horizontal: 8),
                      indicator: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        color: Colors.transparent, // This will be transparent so that we can apply a custom decoration
                        border: Border.all(
                          color: Colors.purple[800]!,
                          width: 1.5,
                        ),
                      ),
                      tabs: [

                        Tab(
                          child: Container(
                            width: 60,
                            child: Align(
                              alignment: Alignment.center,
                              child: Text("Tümü",style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
                            ),
                          ),
                        ),
                        Tab(
                          child: Container(
                            width: 110,
                            child: Align(
                              alignment: Alignment.center,
                              child: Text("Açık Senetler",style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
                            ),
                          ),
                        ),
                        Tab(
                          child: Container(
                            width: 120,
                            child: Align(
                              alignment: Alignment.center,
                              child: Text("Kapalı Senetler",style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
                            ),
                          ),
                        ),
                        Tab(
                          child: Container(
                            width: 150,
                            child: Align(
                              alignment: Alignment.center,
                              child: Text("Ödenmemiş Senetler",style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
                            ),
                          ),
                        ),
                      ]),
                ),
              ),

            ),


            body: TabBarView(
              children: <Widget>[
                TumSenetler(),
                AcikSenetler(),
                KapaliSenetler(),
                OdenmemisSenetler()
              ],
            ),
          ),
        ),
      ),
    );
  }
}
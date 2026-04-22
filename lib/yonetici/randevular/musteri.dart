import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:randevu_sistem/Models/musteri_danisanlar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Backend/backend.dart';
import '../diger/menu/musteriler/yeni_musteri.dart';

class Musteri extends StatefulWidget {
  final dynamic isletmebilgi;
  final int kullanicirolu;
  const Musteri({Key? key,required this.isletmebilgi,required this.kullanicirolu}) : super(key: key);

  @override
  _MusteriState createState() =>
      _MusteriState();

}

class _MusteriState extends State<Musteri> {
  late List<MusteriDanisan> musteridanisanliste;
  late List<MusteriDanisan> filtered;
  bool isloading = true;
  String arama ='';
  TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    initialize();
    _controller.addListener(() {

      musteridanisanara(_controller.text);

      log(_controller.text);
    });

  }
  void musteridanisanara(String query) {
    log('Müşteri arama '+query);
    setState(() {
      arama = query;
      filtered = musteridanisanliste.where((item) => item.name.toLowerCase().contains(query.toLowerCase())).toList();
    });
  }

  Future<void> initialize() async
  {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    late String? seciliisletme;
    seciliisletme = await secilisalonid();
    List<MusteriDanisan> musteridanisanlistesi = await musterilistegetir(seciliisletme!);
    setState(() {
      musteridanisanliste = musteridanisanlistesi;
      filtered = musteridanisanliste;
      isloading=false;
    });

  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text("Müşteri Seçimi",style: TextStyle(color: Colors.black,fontSize: 20),),
        toolbarHeight: 70,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
              icon: Icon(
                  Icons.add,
                  color: Colors.black,
                  size: 25.0),
              onPressed: (){Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => Yenimusteri(kullanicirolu: widget.kullanicirolu, isletmebilgi: widget.isletmebilgi,isim:"",telefon: "",sadeceekranikapat: true,)),
              );}

          ),
        ],

      ),

      body: _buildListView(),
    );
  }
  Widget _buildListView() {
    final double width = MediaQuery.of(context).size.width;
    final double height = MediaQuery.of(context).size.height;
    return isloading ? Center(child: CircularProgressIndicator(),) :
        SingleChildScrollView(
          padding: EdgeInsets.all(8),
          child:  Column(

            children: [

              TextFormField(

                controller: _controller,
                keyboardType: TextInputType.text,

                decoration: InputDecoration(
                  hintText: 'Ara...',
                  prefixIcon: Icon(Icons.search),
                  fillColor: Colors.white,
                  filled: true,
                  enabled:true,
                  focusColor:Color(0xFF6A1B9A) ,
                  hoverColor: Color(0xFF6A1B9A) ,
                  hintStyle: TextStyle(color:  Color(0xFF6A1B9A)),
                  contentPadding:  EdgeInsets.all(5.0),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(
                      color: Color(0xFF6A1B9A)),borderRadius: BorderRadius.circular(10.0),),
                  border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10.0),),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF6A1B9A),), borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
              ),
              Container(
                height: height-160,

                child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return Column(
                          children: [
                            ListTile(
                              title: Text(filtered[index].name),

                              trailing: Icon(Icons.keyboard_arrow_right),
                              onTap: () {
                                setState(() {
                                  Navigator.pop(context, filtered[index]);
                                });


                              },
                            ),
                            const Divider(
                              height: 1.0,
                              thickness: 1,
                            ),


                          ]
                      );


                      ;
                    }

                ),


              ),
            ],
          )
        );
   ;


    ;
  }
}
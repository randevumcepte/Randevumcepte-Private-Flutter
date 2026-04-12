
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import '../../../../../Backend/backend.dart';
import '../../../../../Frontend/sfdatatable.dart';
import '../personeller/oglen_arasi.dart';

class OdaEkle extends StatefulWidget {
  final OdaDataSource odadatasource;
  final dynamic isletmebilgi;
  const OdaEkle({Key? key, required this.odadatasource,required this.isletmebilgi}) : super(key: key);

  @override
  _OdaEkleState createState() => _OdaEkleState();
}

class _OdaEkleState extends State<OdaEkle> {
  TextEditingController odaadi = TextEditingController();

  late String seciliisletme;

  final formKey = GlobalKey<FormState>();
  late Map<String,dynamic> calismasaatleri;
  void _fetchData() async {

    seciliisletme = (await secilisalonid())!;





  }


  void initState() {
    super.initState();

    _fetchData();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        toolbarHeight: 60,

        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (widget.isletmebilgi["demo_hesabi"].toString() == "1")
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: SizedBox(
              width: 100, // <-- Your width
              child: YukseltButonu(isletme_bilgi: widget.isletmebilgi,)
            ),
          ),
        ],
        title: Text("Yeni Oda",style: TextStyle(color: Colors.black),),

      ),
      body: Padding( padding: EdgeInsets.all(8),
        child: Form(
          key: formKey,
          child: ListView(

            children: [
              SizedBox(height: 10,),
              Padding(
                padding: const EdgeInsets.only(left: 5.0),
                child: Text('Oda Adı',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
              ),
              SizedBox(height: 10,),
              Container(

                height: 40,
                child: TextFormField(

                  keyboardType: TextInputType.text,

                  controller: odaadi,
                  onSaved: (value) {
                    odaadi.text = value!;
                  },


                  enabled:true,
                  decoration: InputDecoration(

                    focusColor:Color(0xFF6A1B9A) ,
                    hoverColor: Color(0xFF6A1B9A) ,
                    hintStyle: TextStyle(color:  Color(0xFF6A1B9A)),
                    contentPadding:  EdgeInsets.all(15.0),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(
                        color: Color(0xFF6A1B9A)),borderRadius: BorderRadius.circular(10.0),),
                    border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10.0),),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF6A1B9A),), borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                ),
              ),





              const Divider(
                height: 2.0,
                thickness: 1,
              ),

              SizedBox(height: 20,),
              ElevatedButton(onPressed: (){
                widget.odadatasource.odaekle(   odaadi.text,
                  seciliisletme, // You need to pass the correct salonId

                  context,);

              },
                child: Text('Kaydet'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    minimumSize: Size(90, 40)
                ),
              ),
            ],
          ),

        ),

      )
    );
  }





}

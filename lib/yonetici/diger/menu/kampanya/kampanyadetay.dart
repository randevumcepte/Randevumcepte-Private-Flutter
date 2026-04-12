import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:http/http.dart' as http;
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:randevu_sistem/Models/kampanyalar.dart';
import '../../../../Models/kampanyalar.dart';

import 'kampanyabeklenenkatilimcilar.dart';
import 'kampanyakatilankatilimcilar.dart';
import 'kampanyakatilmayankatilimcilar.dart';
import 'kampanyatumkatilimcilar.dart';
import 'package:randevu_sistem/Frontend/progressloading.dart';

class KampanyaDetay extends StatefulWidget {
  final Kampanya kampanyadetayi;
  final dynamic isletmebilgi;
  const KampanyaDetay({Key? key,required this.kampanyadetayi,required this.isletmebilgi}) : super(key: key);

  @override
  _KampanyaDetayState createState() =>
      _KampanyaDetayState();
}


class _KampanyaDetayState extends State<KampanyaDetay>{
  bool isloading = false;

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      floatingActionButton: (widget.kampanyadetayi.katilimcilar.where((element) => element['durum']==null).length > 0) ?_bottomButtons():null,
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      body:
      DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: AppBar(
            centerTitle: false,
            title: const Text(' Reklam Detayı',style: TextStyle(color: Colors.black),),
            leading: IconButton(
              icon: Icon(Icons.clear_rounded, color: Colors.black),
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
            toolbarHeight: 60,

            backgroundColor: Colors.white,




          ),



          body: SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListTile(
                      title: Row(
                        children: [
                          Text('Paket\n${widget.kampanyadetayi.paket_isim}',style: TextStyle(fontWeight: FontWeight.bold),),
                          SizedBox(width: 50,),
                          Expanded(child: Text('Hizmet(-ler)\n${widget.kampanyadetayi.hizmet_adi}',style: TextStyle(fontWeight: FontWeight.bold)))

                        ],
                      )

                  ),
                ),
                Divider(),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListTile(
                      title: Row(
                        children: [
                          Column(
                            children: [
                              Text('Katılımcı'),
                              Text(widget.kampanyadetayi.katilimcilar.length.toString()),
                            ],
                          ),
                          Spacer(),
                          Column(
                            children: [
                              Text('Toplam Seans'),
                              Text(widget.kampanyadetayi.seans.toString())

                            ],
                          ),
                          Spacer(),
                          Column(
                            children: [

                              Text('Kampanya Fiyatı'),

                              Text(widget.kampanyadetayi.fiyat)
                            ],
                          )

                        ],
                      )

                  ),
                ),
                Divider(),
                TabBar(indicatorSize: TabBarIndicatorSize.label,
                    onTap: (index) {

                    },
                    unselectedLabelColor: Colors.purple[800],
                    labelPadding: EdgeInsets.only(left: 2,right: 2),
                    indicator: BoxDecoration(
                        gradient: LinearGradient(
                            colors: [Color(0xFF6A1B9A), Colors.purpleAccent]),

                        borderRadius: BorderRadius.circular(10),
                        color: Colors.purple[800]),
                    tabs: [

                      Tab(
                        child: Align(
                          alignment: Alignment.center,
                          child: Text("Tümü",style: TextStyle(fontSize: 13,fontWeight: FontWeight.bold),),
                        ),
                      ),
                      Tab(
                        child: Align(
                          alignment: Alignment.center,
                          child: Text("Katılanlar",style: TextStyle(fontSize: 13,fontWeight: FontWeight.bold),),
                        ),
                      ),
                      Tab(
                        child: Align(
                          alignment: Alignment.center,
                          child: Text("Katılmayanlar",style: TextStyle(fontSize: 13,fontWeight: FontWeight.bold),),
                        ),
                      ),
                      Tab(
                        child: Align(
                          alignment: Alignment.center,
                          child: Text("Beklenenler",style: TextStyle(fontSize: 13,fontWeight: FontWeight.bold),),
                        ),
                      ),
                    ]),
                SizedBox(
                  height: height*0.55,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height*2.0),
                      child: Column(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: double.infinity,
                              child: TabBarView(
                                children: <Widget>[
                                  TumKampanyaKatilimci(kampanyadetayi: widget.kampanyadetayi,),
                                  KatilanKampanyaKatilimci(kampanyadetayi: widget.kampanyadetayi,),
                                  KatilmayanKampanyaKatilimci(kampanyadetayi: widget.kampanyadetayi,),
                                  BeklenenKampanyaKatilimci(kampanyadetayi: widget.kampanyadetayi,)
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget _bottomButtons() {
    return FloatingActionButton(
      shape: StadiumBorder(),
      onPressed: () {
        // Show the confirmation dialog when the button is pressed
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('SMS Gönder',style: TextStyle(color:Colors.deepPurple),),
              content: const Text('Beklenen katılımcılara SMS gönder !'),
              actions: <Widget>[
                TextButton(
                  child: const Text('İptal',style: TextStyle(color:Colors.red),),
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                ),
                TextButton(
                  child: const Text('Gönder',style: TextStyle(color:Colors.purple),),
                  onPressed: () {
                    // Close the dialog and send the SMS
                    Navigator.of(context).pop();
                    smsgonder(context);



                  },
                ),
              ],
            );
          },
        );
      },
      backgroundColor: Colors.redAccent,
      child: const Icon(
        Icons.message,
        size: 20.0,
      ),
    );
  }
  Future<void> smsgonder(BuildContext context) async {



    Map<String, dynamic> formData = {
      'kampanyaid':widget.kampanyadetayi.id.toString()
    };

    final response = await http.post(
      Uri.parse('https://app.randevumcepte.com.tr/api/v1/kampanyatekrarsmsgonder'),

      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(formData),
    );

    if (response.statusCode == 200) {

      setState(() {
        isloading = false;
      });
      Fluttertoast.showToast(
        msg: "Mesajınız gönderildi!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0,
      );

    }else {
      setState(() {
        isloading = false;
        debugPrint('Error: ${response.body}');
      });


    }




  }
}
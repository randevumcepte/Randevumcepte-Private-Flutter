
import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';

import '../../../../../Backend/backend.dart';
import '../../../../../Models/isletmehizmetleri.dart';
import '../../../../../Models/paket_hizmetleri.dart';
import '../../../../../Models/paketler.dart';
import '../../../../../Models/user.dart';
import '../../satislar/paketsatislariyeni.dart';
import 'birhizmetdaha.dart';




class PaketDuzenle extends StatefulWidget {


  final Paket paket;
  final dynamic isletmebilgi;
  const PaketDuzenle({Key? key, required this.paket,required this.isletmebilgi}) : super(key: key);

  @override
  _PaketDuzenleState createState() => _PaketDuzenleState();
}


class _PaketDuzenleState extends State<PaketDuzenle> {

  late String seciliisletme;
  TextEditingController paketadi = TextEditingController();
  List<PaketHizmetleri>pakethizmetleri = [];
  PaketHizmetleri? secilihizmet;

  void hizmetekle(PaketHizmetleri? editlenecek) async {
    final List<PaketHizmetleri> selectedItems = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BirHizmetDaha(secilihizmetler: pakethizmetleri,duzenlenecek:editlenecek,isletmebilgi: widget.isletmebilgi,)),
    );
    if(selectedItems != null)
    {
      setState(() {

        selectedItems.forEach((element) {
          pakethizmetleri.add(element);
          if(editlenecek != null)
            pakethizmetleri.removeAt(pakethizmetleri.indexOf(editlenecek));



        });


      });
    }

  }



  bool _isloading=true;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  AutovalidateMode _autoValidate = AutovalidateMode.disabled;
  void initState() {

    super.initState();
    initialize();

  }

  Future<void> initialize() async
  {

    seciliisletme = (await secilisalonid())!;
    setState(() {
      paketadi=TextEditingController(text:widget.paket.paket_adi);
      final List<dynamic> hizmetdata = widget.paket.hizmetler;
      pakethizmetleri = hizmetdata.map((e) => PaketHizmetleri.fromJson(e)).toList();
      _isloading=false;
    });
  }
  @override
  Widget build(BuildContext context) {

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus(); // Hide the keyboard
      },
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: new AppBar(
            title: const Text('Paket Düzenle',style: TextStyle(color: Colors.black),),
            backgroundColor: Colors.white,
            leading: IconButton(
              icon: Icon(Icons.clear_rounded, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: SizedBox(
                    width: 100, // <-- Your width
                    child: YukseltButonu(isletme_bilgi: widget.isletmebilgi)
                ),
              ),
            ],

          ),

          body:  _isloading
              ? Center(child: CircularProgressIndicator())
              :Padding(
            padding: const EdgeInsets.fromLTRB(15, 5, 15, 15),
            child: Stack(

              children: <Widget>[formUI(context)],
            ),
          ),
        ),
      ),
    );
  }

  Widget formUI(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return GestureDetector(onTap: () {
      // Unfocus the current text field, dismissing the keyboard
      FocusScope.of(context).unfocus();
    },
      child: Container(
        height: screenHeight,

        child: ListView(
          padding: const EdgeInsets.all(0),
          children: <Widget>[
            SizedBox(height: 20,),
            Padding(
              padding: const EdgeInsets.only(left: 5.0),
              child: Text('Paket Adı',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
            ),
            SizedBox(height: 10,),
            Container(
              height: 40,
              child: TextFormField(

                keyboardType: TextInputType.text,
                controller: paketadi,
                onSaved: (value){
                  paketadi.text=value!;
                },


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
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Text(
                'Hizmetler',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 5),
            pakethizmetleri.length == 0
                ? Padding(
              padding: const EdgeInsets.only(left: 20.0, bottom: 10),
              child: Text(
                'Hizmet seçilmedi',
                style: TextStyle(
                  color: Colors.red[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
                : ListView.builder(
              scrollDirection: Axis.vertical,
              shrinkWrap: true,
              itemCount: pakethizmetleri.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    hizmetekle(pakethizmetleri[index]);
                  },
                  child: Dismissible(
                    dismissThresholds: {
                      DismissDirection.startToEnd: 0.5,
                      DismissDirection.endToStart: 0.5
                    },
                    direction: DismissDirection.endToStart,
                    key: Key(pakethizmetleri[index].hizmet["hizmet_adi"]),
                    background: Container(
                      color: Colors.green,
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.only(left: 20),
                      child: Icon(Icons.edit, color: Colors.white),
                    ),
                    secondaryBackground: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: EdgeInsets.only(right: 20),
                      child: Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (direction) {
                      setState(() {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                '${pakethizmetleri[index].hizmet["hizmet_adi"]} kaldırıldı'),
                          ),
                        );
                        pakethizmetleri.removeAt(index);
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey, width: 1.0),
                        ),
                      ),
                      child: ListTile(
                        title: Text(pakethizmetleri[index].hizmet["hizmet_adi"]),
                        trailing: Text(
                          'Seans : ' +
                              pakethizmetleri[index].seans.toString() +
                              "\nFiyat : " +
                              pakethizmetleri[index].fiyat.toString() +
                              " ₺",
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const Divider(
              height: 1.0,
              thickness: 1,
            ),
            ListTile(
              contentPadding: const EdgeInsets.fromLTRB(10, 0, 5, 5),
              title: Text('Hizmet Ekle'),
              trailing: Icon(Icons.add,color: Colors.purple,),
              onTap: () => hizmetekle(secilihizmet),
            ),
            const Divider(
              height: 1.0,
              thickness: 1,
            ),
            SizedBox(height: 20,),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Check if isletmebilgi is null


                    // Now you can safely call submitForm
                    submitForm(widget.paket.id.toString(), seciliisletme, paketadi.text, pakethizmetleri, context);
                  },
                  child: Text('Kaydet'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: Size(90, 40),
                  ),
                ),
              ],
            ),

          ],
        ),
      ),
    );
  }
  String? validateName(String? value) {
    if (value!.isEmpty) {
      return 'İsmi boş bırakmayınız';
    }
    if (value.length < 3) {
      return '2 karakterden fazla olmalıdır';
    } else {
      return null;
    }
  }


}
Future<void> submitForm(String paket_id, String salonid, String paket_adi, List<PaketHizmetleri> pakethizmetleri, BuildContext context) async {
  // Convert services to JSON format
  List<Map<String, dynamic>> hizmetler = pakethizmetleri.map((hizmet) => hizmet.toJson()).toList();

  // Create form data
  Map<String, dynamic> formData = {
    'paket_id': paket_id,
    'adpaket': paket_adi,
    'hizmetler': hizmetler,
    // Add other form fields as necessary
  };

  log('formdata ' + formData.toString());

  // Make HTTP request
  final response = await http.post(
    Uri.parse('https://app.randevumcepte.com.tr/api/v1/paket_ekle_guncelle/' + salonid.toString()),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),
  );

  if (response.statusCode == 200) {
    log('etkinlik ekleme : ' + response.body);

    Navigator.of(context).pop(true);
  } else {
    // Show error message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Etkinlik eklenirken bir hata oluştu! Hata kodu : ' + response.statusCode.toString()),
      ),
    );
    debugPrint('Error: ${response.body}');
  }
}

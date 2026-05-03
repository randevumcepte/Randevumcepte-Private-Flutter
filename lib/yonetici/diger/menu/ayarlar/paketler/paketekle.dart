
import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:randevu_sistem/Frontend/tl_input_formatter.dart';

import '../../../../../Backend/backend.dart';
import '../../../../../Models/isletmehizmetleri.dart';
import '../../../../../Models/paket_hizmetleri.dart';
import '../../../../../Models/user.dart';
import '../../satislar/paketsatislariyeni.dart';
import 'birhizmetdaha.dart';




class PaketEkle extends StatefulWidget {
  final Kullanici kullanici;
  final dynamic isletmebilgi;
  final int kullanicirolu;
  const PaketEkle({Key? key, required this.kullanici,required this.isletmebilgi,required this.kullanicirolu}) : super(key: key);

  @override
  _PaketEkleState createState() => _PaketEkleState();
}


class _PaketEkleState extends State<PaketEkle> {

  late String seciliisletme;
  TextEditingController paketadi = TextEditingController();
  TextEditingController paketSeans = TextEditingController();
  TextEditingController paketFiyat = TextEditingController();
  TextEditingController paketSure = TextEditingController();
  List<PaketHizmetleri>pakethizmetleri = [];
  PaketHizmetleri? secilihizmet;

  void hizmetekle() async {
    FocusScope.of(context).unfocus();
    final List<PaketHizmetleri>? selectedItems = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BirHizmetDaha(secilihizmetler: pakethizmetleri, isletmebilgi: widget.isletmebilgi)),
    );
    if (!mounted) return;
    FocusManager.instance.primaryFocus?.unfocus();
    if (selectedItems != null) {
      setState(() {
        pakethizmetleri = selectedItems;
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

      _isloading=false;
    });
  }
  @override
  Widget build(BuildContext context) {

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus(); // Hide the keyboard
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: new AppBar(
          title: const Text('Yeni Paket',style: TextStyle(color: Colors.black),),
          backgroundColor: Colors.white,
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
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 5.0),
                        child: Text('Süre (dk)', style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold)),
                      ),
                      SizedBox(height: 8),
                      SizedBox(
                        height: 40,
                        child: TextFormField(
                          controller: paketSure,
                          keyboardType: TextInputType.number,
                          decoration: _paketInputDecoration(),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 5.0),
                        child: Text('Seans', style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold)),
                      ),
                      SizedBox(height: 8),
                      SizedBox(
                        height: 40,
                        child: TextFormField(
                          controller: paketSeans,
                          keyboardType: TextInputType.number,
                          decoration: _paketInputDecoration(),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 5.0),
                        child: Text('Fiyat (₺)', style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold)),
                      ),
                      SizedBox(height: 8),
                      SizedBox(
                        height: 40,
                        child: TextFormField(
                          controller: paketFiyat,
                          keyboardType: TextInputType.number,
                          inputFormatters: [TurkishLiraInputFormatter()],
                          decoration: _paketInputDecoration(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
                return Dismissible(
                  dismissThresholds: {
                    DismissDirection.endToStart: 0.5,
                  },
                  direction: DismissDirection.endToStart,
                  key: Key('${pakethizmetleri[index].hizmet_id}_$index'),
                  secondaryBackground: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.only(right: 20),
                    child: Icon(Icons.delete, color: Colors.white),
                  ),
                  background: Container(),
                  onDismissed: (direction) {
                    setState(() {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${pakethizmetleri[index].hizmet["hizmet_adi"]} kaldırıldı'),
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
                      title: Text(pakethizmetleri[index].hizmet["hizmet_adi"]?.toString() ?? ''),
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
              onTap: () => hizmetekle(),
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
                    submitForm(
                      widget.kullanici,
                      seciliisletme,
                      paketadi.text,
                      pakethizmetleri,
                      paketSure.text,
                      paketSeans.text,
                      tlToBackend(paketFiyat.text),
                      context,
                    );
                  },
                  child: Text('Kaydet'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor:Colors.white,
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

  InputDecoration _paketInputDecoration() {
    return InputDecoration(
      isDense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF6A1B9A)),
        borderRadius: BorderRadius.circular(10.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF6A1B9A)),
        borderRadius: BorderRadius.circular(10.0),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
    );
  }

  Future<void> submitForm(dynamic isletmebilgisi, String salonid, String paket_adi, List<PaketHizmetleri> pakethizmetleri, String paketsure, String seanslar, String fiyatlar, BuildContext context) async {
    List<Map<String, dynamic>> hizmetler = pakethizmetleri.map((hizmet) => hizmet.toJson()).toList();

    Map<String, dynamic> formData = {
      'adpaket': paket_adi,
      'hizmetler': hizmetler,
      'paketsure': paketsure,
      'seanslar': seanslar,
      'fiyatlar': fiyatlar,
    };

    log('formdata ' + formData.toString());

    final response = await http.post(
      Uri.parse('https://app.randevumcepte.com.tr/api/v1/paket_ekle_guncelle/' + salonid.toString()),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(formData),
    );

    if (response.statusCode == 200) {
      log('paket ekleme : ' + response.body);
      if (context.mounted) Navigator.of(context).pop(true);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Paket eklenirken bir hata oluştu! Hata kodu : ' + response.statusCode.toString()),
          ),
        );
      }
      debugPrint('Error: ${response.body}');
    }
  }

}


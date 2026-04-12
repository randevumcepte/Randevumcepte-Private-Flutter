
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:intl/intl.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';

import '../../../../../Frontend/popupdialogs.dart';
import '../../../../../Frontend/progressloading.dart';
import '../../../../../Frontend/sfdatatable.dart';



class YeniUrun extends StatefulWidget {
  final String salonid;
  final UrunDataSource urunDataSource;
  final dynamic isletmebilgi;
  const YeniUrun({Key? key,required this.salonid, required this.urunDataSource,required this.isletmebilgi}) : super(key: key);

  @override
  _YeniUrunState createState() => _YeniUrunState();
}


class _YeniUrunState extends State<YeniUrun> {

  late TextEditingController urunadi = TextEditingController();
  late TextEditingController fiyat = TextEditingController();
  late TextEditingController stok_adedi = TextEditingController();
  late TextEditingController dusuk_stok_siniri = TextEditingController();
  late TextEditingController barkod = TextEditingController();
  @override
  void initState() {
    super.initState();
  }



  Future<void> scanQR() async {
    String barcodeScanRes;
    // Platform mesajları başarısız olabilir, bu yüzden try/catch kullanıyoruz.
    try {
      var result = await BarcodeScanner.scan(); // Barkod tarama başlatılır
      barcodeScanRes = result.rawContent; // Tarama sonucunu al
      print(barcodeScanRes);
    } on PlatformException {
      barcodeScanRes = 'Platform sürümü alınamadı.';
    }

    // Widget ağacından kaldırılmışsa, yanıtı yok saymak istiyoruz.
    if (!mounted) return;

    setState(() {
      barkod.text = barcodeScanRes;
    });
  }

  Future<void> scanBarcodeNormal() async {
    String barcodeScanRes;
    // Platform mesajları başarısız olabilir, bu yüzden try/catch kullanıyoruz.
    try {
      var result = await BarcodeScanner.scan(); // Barkod tarama başlatılır
      barcodeScanRes = result.rawContent; // Tarama sonucunu al
      print(barcodeScanRes);
    } on PlatformException {
      barcodeScanRes = 'Platform sürümü alınamadı.';
    }

    // Widget ağacından kaldırılmışsa, yanıtı yok saymak istiyoruz.
    if (!mounted) return;

    setState(() {
      barkod.text = barcodeScanRes;
    });
  }

  TextEditingController controller = TextEditingController();



  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  AutovalidateMode _autoValidate = AutovalidateMode.disabled;

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: new AppBar(
          title: const Text('Yeni ürün',style: TextStyle(color: Colors.black),),
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
          toolbarHeight: 60,

        ),

        body: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.all(15.0),
            child: Form(
              key: _formKey,
              autovalidateMode: _autoValidate,
              child: formUI(),
            ),
          ),
        ),
      ),
    );
  }

  Widget formUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 5.0),
          child: Text('Ürün Adı',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
        ),
        SizedBox(height: 10,),
        Container(
          height: 40,
          child: TextFormField(

            keyboardType: TextInputType.text,
            controller: urunadi,
            onSaved: (value){
              if(value!=null)
                urunadi.text = value;
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
        SizedBox(height: 10,),
        Padding(
          padding: const EdgeInsets.only(left: 5.0),
          child: Text('Fiyat',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
        ),
        SizedBox(height: 10,),
        Container(
          height: 40,
          child: TextFormField(

            keyboardType: TextInputType.phone,
            controller: fiyat,
            onSaved: (value){
              if(value!=null)
                fiyat.text = value;
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
        SizedBox(height: 10,),
        Padding(
          padding: const EdgeInsets.only(left: 5.0),
          child: Text('Stok Adedi',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
        ),
        SizedBox(height: 10,),
        Container(
          height: 40,
          child: TextFormField(

            keyboardType: TextInputType.phone,
            controller: stok_adedi,
            onSaved: (value){
              if(value!=null)
                stok_adedi.text = value;
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

        SizedBox(height: 10,),
        Padding(
          padding: const EdgeInsets.only(left: 5.0),
          child: Text('Düşük Stok Sınırı',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
        ),
        SizedBox(height: 10,),
        Container(
          height: 40,
          child: TextFormField(

            keyboardType: TextInputType.phone,

            controller: dusuk_stok_siniri,
            onSaved: (value){
              if(value!=null)
                dusuk_stok_siniri.text = value;
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
        SizedBox(height: 10,),
        Padding(
          padding: const EdgeInsets.only(left: 5.0),
          child: Text('Barkod',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
        ),

        SizedBox(height: 10,),
        Container(
          height: 40,
          child: TextFormField(

            keyboardType: TextInputType.phone,
            controller: barkod,
            onSaved: (value){
              if(value!=null)
                barkod.text = value;
            },

            decoration: InputDecoration(

              focusColor:Color(0xFF6A1B9A) ,
              hoverColor: Color(0xFF6A1B9A) ,
              hintStyle: TextStyle(color:  Color(0xFF6A1B9A)),
              contentPadding:  EdgeInsets.all(10.0),
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
        SizedBox(height: 10,),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => scanBarcodeNormal(),
              child: Text('Barkod Tara'),style: ElevatedButton.styleFrom(

              textStyle:
              TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              backgroundColor: Colors.purple[800], // background (button) color
              foregroundColor: Colors.white,

            ),),
          ],
        ),

        const SizedBox(
          height: 10.0,
        ),

        const SizedBox(
          height: 20.0,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(onPressed: (){

              bool valid = true;
              String uyari = 'Formu kaydetmeden önce gerekli alanları eksiksiz doldurunuz.';
              if(urunadi.text=='') {
                  uyari += '\n\nÜrün adı gereklidir';
                  valid = false;
              }
              if(fiyat.text==''){
                  uyari += '\nÜrün fiyatı gereklidir';
                  valid = false;
              }
              if(stok_adedi.text == ''){
                  uyari += '\nÜrün stok adedi gereklidir';
                  valid = false;
              }
              if(dusuk_stok_siniri.text == ''){
                  uyari += '\nÜrün düşük stok sınırı gereklidir';
                  valid = false;
              }
              if(valid = false)
                formWarningDialogs(context,'UYARI',uyari);
              else
                {
                  showProgressLoading(context);
                  widget.urunDataSource.urunEkleGuncelle('', urunadi.text, fiyat.text, stok_adedi.text, dusuk_stok_siniri.text, barkod.text, context, widget.salonid.toString());
                }
            },
              child: Text('Kaydet'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: Size(90, 40)
              ),
            ),
          ],
        )
      ],
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
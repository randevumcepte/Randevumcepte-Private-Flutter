
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:intl/intl.dart';
import 'package:randevu_sistem/Frontend/sfdatatable.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import '../../../../../Frontend/popupdialogs.dart';
import '../../../../../Frontend/progressloading.dart';
import '../../../../../Models/urunler.dart';



class UrunDuzenle extends StatefulWidget {
  final Urun urundetayi;
  final String salonid;
  final UrunDataSource urunDataSource;
  final dynamic isletmebilgi;
  const UrunDuzenle({Key? key,required this.urundetayi,required this.salonid, required this.urunDataSource,required this.isletmebilgi}) : super(key: key);

  @override
  _UrunDuzenleState createState() => _UrunDuzenleState();
}


class _UrunDuzenleState extends State<UrunDuzenle> {


  late TextEditingController urunid = TextEditingController(text: widget.urundetayi.id);
  late TextEditingController urunadi = TextEditingController(text: widget.urundetayi.urun_adi=='null' ? '':widget.urundetayi.urun_adi );
  late TextEditingController fiyat = TextEditingController(text: widget.urundetayi.fiyat=='null' ? '':widget.urundetayi.fiyat );
  late TextEditingController stok_adedi = TextEditingController(text: widget.urundetayi.stok_adedi=='null' ? '':widget.urundetayi.stok_adedi );
  late TextEditingController dusuk_stok_siniri = TextEditingController(text: widget.urundetayi.dusuk_stok_siniri=='null' ? '':widget.urundetayi.dusuk_stok_siniri );
  late TextEditingController barkod = TextEditingController(text: widget.urundetayi.barkod=='null' ? '':widget.urundetayi.barkod );
  bool formisvalid = true;
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





  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  AutovalidateMode _autoValidate = AutovalidateMode.disabled;

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
            title: const Text('Ürün Düzenle',style: TextStyle(color: Colors.black),),
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
            controller: fiyat,
            onSaved: (value){
              if(value!=null)
                fiyat.text = value;
            },
            keyboardType: TextInputType.phone,



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

              String uyari = 'Formu kaydetmeden önce gerekli alanları eksiksiz doldurunuz.';
              if(urunadi.text=='') {
                uyari += '\n\nÜrün adı gereklidir';
                formisvalid = false;
              }
              if(fiyat.text==''){
                uyari += '\nÜrün fiyatı gereklidir';
                formisvalid = false;
              }
              if(stok_adedi.text == ''){
                uyari += '\nÜrün stok adedi gereklidir';
                formisvalid = false;
              }
              if(dusuk_stok_siniri.text == ''){
                uyari += '\nÜrün düşük stok sınırı gereklidir';
                formisvalid = false;
              }
              if(formisvalid == false)
                formWarningDialogs(context,'UYARI',uyari);
              else
              {

                widget.urunDataSource.urunEkleGuncelle(urunid.text, urunadi.text, fiyat.text, stok_adedi.text, dusuk_stok_siniri.text, barkod.text, context, widget.salonid.toString());
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

}
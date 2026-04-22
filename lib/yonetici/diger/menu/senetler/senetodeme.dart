import 'dart:convert';
import 'dart:developer';

import 'package:dropdown_model_list/drop_down/model.dart';
import 'package:dropdown_model_list/drop_down/search_drop_list.dart';
import 'package:dropdown_model_list/drop_down/select_drop_list.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:randevu_sistem/yonetici/diger/menu/senetler/senetlistesi.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../Frontend/popupdialogs.dart';
import '../../../../Frontend/progressloading.dart';
import '../../../../Frontend/sfdatatable.dart';
import '../../../../Models/odemeturu.dart';



class SenetOdeme extends StatefulWidget {
  final dynamic vade;
  final SenetDataSource senetdatasource;
  final String page;
  final String arama;

  const SenetOdeme({Key? key,required this.vade,required this.senetdatasource,required this.page, required this.arama }) : super(key: key);

  @override
  _SenetOdemeState createState() => _SenetOdemeState();
}

class _SenetOdemeState extends State<SenetOdeme> {

  List<OdemeTuru> odeme_turu = [OdemeTuru( id: '1',odeme_turu: 'Nakit'),OdemeTuru( id: '2',odeme_turu: 'Kredi Kartı'),OdemeTuru( id: '3',odeme_turu: 'Banka Havalesi/EFT')];
  String description = '';

  bool formvalid = true;
  OdemeTuru? secilenodemeturu;
  late TextEditingController vadetarihi = TextEditingController(text : widget.vade['vade_tarih']);
  late TextEditingController vadenot = TextEditingController(text: widget.vade['notlar']);
  TextEditingController dogrulamakodu = TextEditingController();
  TextEditingController secilenodemeturutext = TextEditingController();
  @override
  void initState() {
      //set the initial value of text field
    super.initState();
  }
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  AutovalidateMode _autoValidate = AutovalidateMode.disabled;

  @override
  Widget build(BuildContext context) {

    return   GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus(); // Hide the keyboard
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
          appBar: new AppBar(
            title: const Text('Senet Ödeme & Vade Güncelleme',style: TextStyle(color: Colors.black),),
            backgroundColor: Colors.white,
            leading: IconButton(
              icon: Icon(Icons.clear_rounded, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),

          ),

          body: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.all(15.0),
              child: Form(
                key: _formKey,
                autovalidateMode: _autoValidate,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[

                    Padding(
                      padding: const EdgeInsets.only(left: 5.0),
                      child: Text('Ödeme Tarihi',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                    ),
                    SizedBox(height: 10,),
                    TextFormField(
                      controller: vadetarihi,
                      //editing controller of this TextField
                      decoration: InputDecoration(

                        focusColor:Color(0xFF6A1B9A) ,
                        hoverColor: Color(0xFF6A1B9A) ,
                        hintStyle: TextStyle(color:  Color(0xFF6A1B9A)),
                        contentPadding:  EdgeInsets.all(15.0),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(
                            color: Color(0xFF6A1B9A)),borderRadius: BorderRadius.circular(50.0),),
                        border:
                        OutlineInputBorder(borderRadius: BorderRadius.circular(50.0),),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF6A1B9A),), borderRadius: BorderRadius.circular(50.0),
                        ),
                      ),
                      readOnly: true,
                      //set it true, so that user will not able to edit text

                      onTap: () async {
                        DateTime? pickedDate = await showDatePicker(
                            locale: Locale('tr'),
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(1950),
                            //DateTime.now() - not to allow to choose before today.
                            lastDate: DateTime(2100));

                        if (pickedDate != null) {
                          print(
                              pickedDate); //pickedDate output format => 2021-03-10 00:00:00.000
                          String formattedDate =
                          DateFormat('yyyy-MM-dd').format(pickedDate);
                          print(
                              formattedDate); //formatted date output using intl package =>  2021-03-16
                          setState(() {
                            vadetarihi.text = formattedDate; //set output date to TextField value.
                          });
                        } else {}
                      },
                    ),
                    const SizedBox(
                      height: 10.0,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 5.0),
                      child: Text('Notlar',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                    ),
                    SizedBox(height: 10,),
                    TextFormField(
                      controller: vadenot,
                      keyboardType: TextInputType.text,
                      onSaved: (value){
                        if(value!=null)
                          vadenot.text = value;
                      },


                      decoration: InputDecoration(

                        focusColor:Color(0xFF6A1B9A) ,
                        hoverColor: Color(0xFF6A1B9A) ,
                        hintStyle: TextStyle(color:  Color(0xFF6A1B9A)),
                        contentPadding:  EdgeInsets.all(15.0),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(
                            color: Color(0xFF6A1B9A)),borderRadius: BorderRadius.circular(50.0),),
                        border:
                        OutlineInputBorder(borderRadius: BorderRadius.circular(50.0),),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF6A1B9A),), borderRadius: BorderRadius.circular(50.0),
                        ),
                      ),
                    ),
                    SizedBox(height: 10,),
                    Padding(
                      padding: const EdgeInsets.only(left: 5.0),
                      child: Text('Ödeme Şekli',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                    ),
                    SizedBox(height: 10,),

                    Container(

                      alignment: Alignment.center,

                      height: 50,
                      width:double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Color(0xFF6A1B9A)),
                        borderRadius: BorderRadius.circular(50.0), //border corner radius

                        //you can set more BoxShadow() here

                      ),
                      child: DropdownButtonHideUnderline(

                          child: DropdownButton<OdemeTuru>( // DropdownButton<String?>

                            onChanged: (newValue) {
                              setState(() {

                                secilenodemeturu = newValue;

                              });
                            },
                            hint: Text('Ödeme şekli seçiniz...'),
                            value: secilenodemeturu,
                            items: odeme_turu.map((OdemeTuru o) {
                              return DropdownMenuItem<OdemeTuru>(
                                value: o,
                                child: Text(o.odeme_turu),
                              );
                            }).toList(),
                          )),
                    ),
                    SizedBox(height: 10,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(onPressed: (){
                          if(vadetarihi.text == '')
                            formWarningDialogs(context,'UYARI','Ödeme tarihi alanı boş olamaz');
                          else
                            vadeguncelle(widget.vade['id'],vadenot.text,vadetarihi.text );
                        },
                          child: Text('Vadeyi Güncelle'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple[800],
                              foregroundColor: Colors.white,
                              minimumSize: Size(150, 40)
                          ),
                        ),
                        ElevatedButton(onPressed: (){

                            description = 'Lütfen ödemeyi tamamlamadan önce formu eksiksiz doldurunuz';

                            if(vadetarihi.text == ''){
                              formvalid = false;
                              description += '\n-Lütfen ödeme tarihini giriniz.';
                            }
                            if(secilenodemeturu==null){
                              formvalid = false;
                              description += '\n\n-Lütfen ödeme türünü seçiniz.';
                            }
                            if(!formvalid)
                              formWarningDialogs(context, 'UYARI', description);
                            else
                              senetode(widget.vade['id'], secilenodemeturu!, vadetarihi.text,dogrulamakodu.text);


                        },
                          child: Text('Ödemeyi Tamamla'),
                          style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.green,
                              minimumSize: Size(90, 40)
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),

      ),
    );
  }
  Future<void> vadeguncelle(int vadeid,String not,String tarih) async {
    showProgressLoading(context);
    Map<String, dynamic> formData = {
      'vade_id':vadeid,
      'not':not,
      'tarih':tarih

    };
    final response = await http.post(
      Uri.parse('https://app.randevumcepte.com.tr/api/v1/senetvadeguncelle'),

      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(formData),
    );

    if (response.statusCode == 200) {
      Navigator.of(context, rootNavigator: true).pop();
      Navigator.of(context, rootNavigator: true).pop();
      Navigator.of(context, rootNavigator: true).pop();
      Navigator.of(context, rootNavigator: true).pop();
      widget.senetdatasource.fetchData(widget.page, widget.arama, true);



    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vade güncellenirken bir hata oluştu! Hata kodu : '+response.statusCode.toString()),
        ),
      );
      debugPrint('Error: ${response.body}');
    }
  }
  Future<void> senetode (int vadeid,OdemeTuru odemeturu,String tarih,String dogrulama) async {

    SharedPreferences localStorage = await SharedPreferences.getInstance();
    var user = jsonDecode(localStorage.getString('user')!);
    showProgressLoading(context);
   Map<String, dynamic> formData = {
      'vade_id':vadeid,
      'tarih': tarih,
      'dogrulama_kodu':dogrulama,
      'odeme_yontemi':odemeturu.id,
      'user_id':user['id']
    };

    final response = await http.post(
      Uri.parse('https://app.randevumcepte.com.tr/api/v1/senetode'),

      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(formData),
    );

    if (response.statusCode == 200) {

      final jsonresponse = json.decode(response.body);
      log('senet odeme response body '+response.body);
      if(jsonresponse['dogrulamavar'])
        dogrulamaKoduDialogGoster('');
      else if(jsonresponse['dogrulamayanlis'])
      {
          Navigator.of(context, rootNavigator: true).pop();
          dogrulamaKoduDialogGoster('Girilen doğrulama kodu yanlış! \n\n');
      }


      else
        {
          Navigator.of(context, rootNavigator: true).pop();
          Navigator.of(context, rootNavigator: true).pop();
          Navigator.of(context, rootNavigator: true).pop();
          Navigator.of(context, rootNavigator: true).pop();
          Navigator.of(context, rootNavigator: true).pop();
          Navigator.of(context, rootNavigator: true).pop();
          widget.senetdatasource.fetchData(widget.page, widget.arama, true);
        }



    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Senet ödeme kaydı oluşturulurken bir hata oluştu! Hata kodu : '+response.statusCode.toString()),
        ),
      );
      debugPrint('Error: ${response.body}');
    }

  }
  void dogrulamaKoduDialogGoster(String yanlis) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(yanlis+'Lütfen müşterinin telefonuna gönderilen doğrulama kodunu giriniz'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  controller: dogrulamakodu,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(labelText: 'Doğrulama Kodu'),

                  onSaved: (value) {
                    if(value!=null)
                      dogrulamakodu.text = value!;

                  },
                ),

              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Vazgeç'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('GÖNDER'),
              onPressed: () {
                 if(dogrulamakodu.text=='')
                   formWarningDialogs(context, 'UYARI', 'Lütfen doğrulama kodunu giriniz!');
                 else{
                   log('doğrulama kodu '+dogrulamakodu.text);
                   senetode(widget.vade['id'],secilenodemeturu!,vadetarihi.text,dogrulamakodu.text);
                 }



              },
            ),
          ],
        );
      },
    );
  }



}
import 'dart:convert';
import 'dart:developer';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:dropdown_model_list/drop_down/model.dart';
import 'package:dropdown_model_list/drop_down/search_drop_list.dart';
import 'package:dropdown_model_list/drop_down/select_drop_list.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../Backend/backend.dart';
import '../../../../Frontend/progressloading.dart';
import '../../../../Models/musteri_danisanlar.dart';
import '../../../../Models/musteridanisanreferans.dart';
import 'package:http/http.dart' as http;

import '../../../../Models/user.dart';
import 'musteri_ocr_tara.dart';
import 'musteriliste.dart';



class Yenimusteri extends StatefulWidget {
    final dynamic isletmebilgi;
    final String telefon;
    final String isim;
    final bool sadeceekranikapat;
    final int kullanicirolu;
    const Yenimusteri({Key? key,required this.kullanicirolu, required this.isletmebilgi,required this.telefon,required this.sadeceekranikapat, required this.isim}) : super(key: key);

    @override
    _YenimusteriState createState() => _YenimusteriState();
}


class _YenimusteriState extends State<Yenimusteri> {
    final phoneMask = MaskTextInputFormatter(
        mask: '0### ### ## ##',
        filter: { "#": RegExp(r'[0-9]') },
    );
    final List<Referans> musterireferans = [
        Referans(id: "", referans: "Yok"),
        Referans(id: "1", referans: "İnternet"),
        Referans(id: "2", referans: "Reklam"),
        Referans(id: "3", referans: "Instagram"),
        Referans(id: "4", referans: "Facebook"),
        Referans(id: "5", referans: "Tanıdık")


    ];
    late String seciliisletme;

    Referans? selectedmusterireferans;
    final TextEditingController musterireferanscontroller = TextEditingController();
    TextEditingController adsoyad = TextEditingController();
    TextEditingController telefon = TextEditingController();
    TextEditingController dogumtarihi = TextEditingController();
    TextEditingController eposta = TextEditingController();
    TextEditingController notlar = TextEditingController();
    String selectedcinsiyet = '';
    bool yukleniyor=true;
    @override
    void initState() {
        dogumtarihi.text = ""; //set the initial value of text field
        telefon.text = "0";
        super.initState();
        initialize();
    }
    final _formKey = GlobalKey<FormState>();

    Future<void> initialize() async
    {
        seciliisletme = (await secilisalonid())!;

        setState(() {

            telefon.text = widget.telefon ?? "";
            adsoyad.text = widget.isim ?? "";
            yukleniyor = false;
            selectedmusterireferans = musterireferans.firstWhere((item) => item.id == "");
        });

    }

    @override
    Widget build(BuildContext context) {

        return
           Scaffold(
            resizeToAvoidBottomInset: false,
                appBar: new AppBar(
                    title: const Text('Yeni Müşteri',style: TextStyle(color: Colors.black),),
                    backgroundColor: Colors.white,
                    leading: IconButton(
                        icon: Icon(Icons.clear_rounded, color: Colors.black),
                        onPressed: () => Navigator.of(context).pop(),
                    ),


                ),
                
                body: yukleniyor ? Center(child: CircularProgressIndicator(),) : GestureDetector(
                    onTap: () {
                        FocusScope.of(context).unfocus(); // Hide the keyboard
                    },
                    child: SingleChildScrollView(

                        child: Container(
                            margin: const EdgeInsets.all(15.0),
                            child: Form(
                                key: _formKey,
                                child:    Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                        SizedBox(
                                            width: double.infinity,
                                            child: OutlinedButton.icon(
                                                onPressed: () async {
                                                    final result = await Navigator.of(context).push(
                                                        MaterialPageRoute(
                                                            builder: (_) => const MusteriOcrTara(),
                                                        ),
                                                    );
                                                    if (result is Map) {
                                                        final String okunanIsim = (result['isim'] ?? '').toString().trim();
                                                        final String okunanTelefon = (result['telefon'] ?? '').toString().trim();
                                                        final String okunanEmail = (result['email'] ?? '').toString().trim();
                                                        final String okunanDogum = (result['dogum_tarihi'] ?? '').toString().trim();
                                                        final String okunanCinsiyet = (result['cinsiyet'] ?? '').toString().trim();
                                                        setState(() {
                                                            if (okunanIsim.isNotEmpty) adsoyad.text = okunanIsim;
                                                            if (okunanTelefon.isNotEmpty) {
                                                                telefon.text = okunanTelefon.startsWith('0') ? okunanTelefon : '0$okunanTelefon';
                                                            }
                                                            if (okunanEmail.isNotEmpty) eposta.text = okunanEmail;
                                                            if (okunanDogum.isNotEmpty) dogumtarihi.text = okunanDogum;
                                                            if (okunanCinsiyet.isNotEmpty) selectedcinsiyet = okunanCinsiyet;
                                                        });
                                                    }
                                                },
                                                icon: const Icon(Icons.document_scanner_outlined, color: Color(0xFF6A1B9A)),
                                                label: const Text(
                                                    'Fotoğraftan Tara (Ad / Telefon)',
                                                    style: TextStyle(color: Color(0xFF6A1B9A), fontWeight: FontWeight.bold),
                                                ),
                                                style: OutlinedButton.styleFrom(
                                                    minimumSize: const Size.fromHeight(45),
                                                    side: const BorderSide(color: Color(0xFF6A1B9A)),
                                                    shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(10),
                                                    ),
                                                ),
                                            ),
                                        ),
                                        const SizedBox(height: 15),
                                        Padding(
                                            padding: const EdgeInsets.only(left: 5.0),
                                            child: Text('Ad Soyad',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                                        ),
                                        SizedBox(height: 10,),
                                        Container(
                                            height: 40,
                                            child: TextFormField(

                                                keyboardType: TextInputType.text,
                                                controller: adsoyad,
                                                onSaved: (value){
                                                    adsoyad.text=value!;
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
                                            child: Text('Telefon Numarası',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                                        ),
                                        SizedBox(height: 10,),
                                        Container(
                                            height: 40,
                                            child: TextFormField(
                                                inputFormatters: [phoneMask],
                                                keyboardType: TextInputType.phone,

                                                controller: telefon,
                                                onSaved: (value){
                                                    telefon.text=value!;
                                                },
                                                onTap: () {
                                                    // Cursor daima +90'ın sonuna gelsin
                                                    if (telefon.text.length < 2) {
                                                        telefon.text = "0";
                                                    }
                                                    telefon.selection = TextSelection.fromPosition(
                                                        TextPosition(offset: telefon.text.length),
                                                    );
                                                },

                                                onChanged: (value) {
                                                    // Kullanıcı +90 kısmını silmeye çalışırsa düzelt
                                                    if (!value.startsWith("0")) {
                                                        telefon.text = "0";
                                                        telefon.selection = TextSelection.fromPosition(
                                                            TextPosition(offset: telefon.text.length),
                                                        );
                                                    }
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
                                            child: Text('E-posta',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                                        ),
                                        SizedBox(height: 10,),
                                        Container(
                                            height: 40,
                                            child: TextFormField(

                                                keyboardType: TextInputType.emailAddress,

                                                controller: eposta,
                                                onSaved: (value){

                                                    eposta.text = value!;
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
                                            child: Text('Doğum Tarihi',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                                        ),
                                        SizedBox(height: 10,),
                                        Container(height: 40,
                                            child: TextFormField(
                                                controller: dogumtarihi,
                                                enabled:true,
                                                onSaved: (value){

                                                    dogumtarihi.text = value!;
                                                },
                                                //editing controller of this TextField
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
                                                readOnly: true,
                                                //set it true, so that user will not able to edit text

                                                onTap: () async {
                                                    DateTime? pickedDate = await showDatePicker(
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
                                                            dogumtarihi.text =
                                                                formattedDate; //set output date to TextField value.
                                                        });
                                                    } else {}
                                                },
                                            ),
                                        ),
                                        SizedBox(height: 10,),
                                        Padding(
                                            padding: const EdgeInsets.only(left: 5.0),
                                            child: Text('Cinsiyet',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                                        ),
                                        Row(
                                            children: [
                                                Expanded(
                                                    child: ListTile(
                                                        leading: Radio<String>(
                                                            value: '0',
                                                            groupValue: selectedcinsiyet,
                                                            activeColor: Colors.purple[800],
                                                            onChanged: (value) {
                                                                setState(() {
                                                                    selectedcinsiyet = value!;
                                                                });
                                                            },
                                                        ),
                                                        title: const Text('Kadın'),
                                                    ),
                                                ),
                                                Expanded(
                                                    child: ListTile(
                                                        leading: Radio<String>(
                                                            value: '1',
                                                            groupValue: selectedcinsiyet,
                                                            activeColor: Colors.purple[800],
                                                            onChanged: (value) {
                                                                setState(() {
                                                                    selectedcinsiyet = value!;
                                                                });
                                                            },
                                                        ),
                                                        title: const Text('Erkek'),
                                                    ),
                                                ),

                                            ],
                                        ),
                                        Padding(
                                            padding: const EdgeInsets.only(left: 5.0),
                                            child: Text('Referans',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                                        ),
                                        const SizedBox(
                                            height: 10.0,
                                        ),
                                        Container(
                                            alignment: Alignment.center,

                                            height: 40,
                                            width:double.infinity,
                                            decoration: BoxDecoration(
                                                color: Colors.white,
                                                border: Border.all(color: Color(0xFF6A1B9A)),
                                                borderRadius: BorderRadius.circular(10), //border corner radius

                                                //you can set more BoxShadow() here

                                            ),
                                            child: DropdownButtonHideUnderline(

                                                child: DropdownButton2<Referans>(

                                                    isExpanded: true,
                                                    hint: Text(
                                                        'Referans Seç',
                                                        style: TextStyle(
                                                            fontSize: 14,
                                                            color: Theme.of(context).hintColor,
                                                        ),
                                                    ),
                                                    items: musterireferans
                                                        .map((item) => DropdownMenuItem(
                                                        value: item,
                                                        child: Text(
                                                            item.referans,
                                                            style: const TextStyle(
                                                                fontSize: 14,
                                                            ),
                                                        ),
                                                    ))
                                                        .toList(),
                                                    value: selectedmusterireferans,
                                                    onChanged: (value) {
                                                        setState(() {
                                                            selectedmusterireferans = value;
                                                        });
                                                    },
                                                    buttonStyleData: const ButtonStyleData(
                                                        padding: EdgeInsets.symmetric(horizontal: 16),
                                                        height: 50,
                                                        width: 400,
                                                    ),

                                                    dropdownStyleData: const DropdownStyleData(
                                                        maxHeight: 200,

                                                    ),
                                                    menuItemStyleData: const MenuItemStyleData(
                                                        height: 40,
                                                    ),

                                                    //This to clear the search value when you close the menu
                                                    onMenuStateChange: (isOpen) {
                                                        if (!isOpen) {
                                                            musterireferanscontroller.clear();
                                                        }
                                                    },

                                                )),
                                        ),
                                        const SizedBox(
                                            height: 10.0,
                                        ),
                                        Padding(
                                            padding: const EdgeInsets.only(left: 5.0),
                                            child: Text('Notlar',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                                        ),
                                        SizedBox(height: 10,),
                                        Container(
                                            height: 40,
                                            child: TextFormField(

                                                keyboardType: TextInputType.text,
                                                controller: notlar,

                                                onSaved: (value){

                                                    notlar.text = value!;
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

                                        const SizedBox(
                                            height: 20.0,
                                        ),
                                        Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                                ElevatedButton(onPressed: () async{
                                                    log('🟢 [1] Kaydet butonuna basıldı');
                                                    log('🟢 [2] seciliisletme: $seciliisletme');
                                                    log('🟢 [3] adsoyad: "${adsoyad.text}"');
                                                    log('🟢 [4] telefon: "${telefon.text}"');
                                                    log('🟢 [5] eposta: "${eposta.text}"');
                                                    log('🟢 [6] dogumtarihi: "${dogumtarihi.text}"');
                                                    log('🟢 [7] cinsiyet: "$selectedcinsiyet"');
                                                    log('🟢 [8] referans: "${selectedmusterireferans?.id}"');

                                                    if (_formKey.currentState == null) {
                                                        log('🔴 _formKey.currentState NULL');
                                                        return;
                                                    }
                                                    if (!_formKey.currentState!.validate()) {
                                                        log('🔴 validate() false döndü');
                                                        return;
                                                    }
                                                    _formKey.currentState!.save();
                                                    log('🟢 [9] Form validate + save OK');

                                                    if (adsoyad.text.trim().isEmpty) {
                                                        log('🔴 Ad soyad boş');
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                            const SnackBar(content: Text('Ad Soyad alanı zorunludur')),
                                                        );
                                                        return;
                                                    }
                                                    if (telefon.text.trim().isEmpty || telefon.text.trim() == '0') {
                                                        log('🔴 Telefon boş');
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                            const SnackBar(content: Text('Telefon numarası zorunludur')),
                                                        );
                                                        return;
                                                    }
                                                    log('🟢 [10] Validasyon geçti, submitForm çağrılıyor');

                                                    try {
                                                        MusteriDanisan yenimusteridanisan = await submitForm(widget.isletmebilgi,seciliisletme,adsoyad.text,telefon.text,eposta.text,dogumtarihi.text,selectedcinsiyet,selectedmusterireferans?.id ?? "",notlar.text,context);
                                                        log('🟢 [11] submitForm başarılı, id=${yenimusteridanisan.id}');
                                                        if (!widget.sadeceekranikapat) {
                                                            log('🟢 [12a] MusteriListesi\'ne yönleniyor');
                                                            Navigator.pushReplacement(
                                                                context,
                                                                MaterialPageRoute(builder: (context) => MusteriListesi(kullanicirolu: widget.kullanicirolu, isletmebilgi:widget.isletmebilgi)),
                                                            );
                                                        } else {
                                                            log('🟢 [12b] pop ile geri dönülüyor');
                                                            Navigator.of(context).pop(yenimusteridanisan);
                                                        }
                                                    } catch (e, st) {
                                                        log('🔴 Müşteri eklenemedi: $e');
                                                        log('🔴 stack: $st');
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
                                )
                    ),
                        ),
                    ),
                ),
            );

    }
    Future<MusteriDanisan> submitForm(dynamic isletmebilgisi,String salonid,String musteriad,String telefon,String e_posta,String dogumtarihi,String cinsiyet,String referans,String notlar,context)async {

        showProgressLoading(context);


        Map<String,dynamic> formData={
            'ad_soyad':musteriad,
            'telefon':telefon,
            'email':e_posta,
            'dogum_tarihi':dogumtarihi,
            'cinsiyet':cinsiyet,
            'musteri_tipi':referans,
            'ozel_notlar':notlar


        };

        try {
            final response = await http.post(
                Uri.parse('https://app.randevumcepte.com.tr/api/v1/musteriekleguncelle/'+salonid.toString()),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode(formData),
            );

            log('musteri ekle response status: ${response.statusCode}');
            log('musteri ekle response body: ${response.body}');

            // Loading dialog'u her durumda kapat
            Navigator.of(context,rootNavigator: true).pop();

            if (response.statusCode != 200 && response.statusCode != 201) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Müşteri eklenirken bir hata oluştu! Hata kodu : '+response.statusCode.toString()),
                    ),
                );
                throw Exception('Bir hata oluştu: ${response.statusCode}');
            }

            // Boş body kontrolü
            if (response.body.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Sunucudan boş yanıt geldi. Müşteri eklenemedi.'),
                    ),
                );
                throw Exception('Boş response body');
            }

            final decoded = json.decode(response.body);

            // Warning response'u kontrol et
            if (decoded is Map && decoded.containsKey('status') && decoded['status'] == 'warning') {
                final mesaj = decoded['mesaj']?.toString() ?? 'Bu müşteri zaten kayıtlı';
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(mesaj),
                        backgroundColor: Colors.orange,
                        duration: Duration(seconds: 4),
                    ),
                );
                throw Exception(mesaj);
            }

            // Normal müşteri objesi
            return MusteriDanisan.fromJson(decoded as Map<String, dynamic>);
        } catch (e, stackTrace) {
            // Herhangi bir exception durumunda loading'i kapat ve kullanıcıya bildir
            try {
                Navigator.of(context,rootNavigator: true).pop();
            } catch (_) {}
            log('musteri ekle hata: $e');
            log('stack: $stackTrace');
            // Eğer daha önce bir SnackBar gösterilmediyse göster
            if (!e.toString().contains('zaten kayıtlı') && !e.toString().contains('Boş response') && !e.toString().contains('Bir hata oluştu')) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Müşteri eklenemedi: ${e.toString()}'),
                    ),
                );
            }
            rethrow;
        }
    }


}

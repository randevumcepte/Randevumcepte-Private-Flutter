
import 'dart:convert';
import 'dart:core';
import 'dart:developer';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:http/http.dart' as http;
import '../../../../../Backend/backend.dart';
import '../../../../../Models/hizmetkategorisi.dart';
import '../../../../../Models/cihazlar.dart';
import '../../../../../Models/odalar.dart';
import '../../../../../Models/personel.dart';
import '../../../../../Models/personelcihaz.dart';
import 'hizmetler.dart';




class ListedeOlmayanHizmet extends StatefulWidget {
  final dynamic isletmebilgi;
  const ListedeOlmayanHizmet({Key? key,required this.isletmebilgi}) : super(key: key);

  @override
  _ListedeOlmayanHizmetState createState() => _ListedeOlmayanHizmetState();
}
enum SingingCharacter { kadin, erkek,unisex }

class _ListedeOlmayanHizmetState extends State<ListedeOlmayanHizmet> {
  late List<Cihaz>cihazliste;
  late List<HizmetKategorisi> hizmetkategorisi;
  List<PersonelCihaz> personelcihazliste = [];
  HizmetKategorisi? selectedhizmetkategorisi;
  TextEditingController hizmetkategorisicontroller = TextEditingController();
  List<PersonelCihaz> seciliYardimci = [];
  Personel ?secilipersonel;
  Cihaz ?secilicihaz;
  String _selectedGender = '';
  String dropdownValue = 'Seçiniz';
  bool isloading=true;
  TextEditingController hizmet_adi=TextEditingController();
  TextEditingController hizmet_sure=TextEditingController();
  TextEditingController hizmet_fiyat=TextEditingController();


  void initState() {

    super.initState();
    initialize();


  }
  Future<void> initialize() async
  {
    var seciliisletme = await secilisalonid();
    List<HizmetKategorisi> isletmehizmetkategorileriliste = await hizmetkategorileri();
    List<Personel> isletmepersonellerliste = await personellistegetir(seciliisletme!);
    List<Cihaz>isletmecihazliste = await isletmecihazlari(seciliisletme!);
    setState(() {
      hizmetkategorisi = isletmehizmetkategorileriliste;
      cihazliste = isletmecihazliste;
      isletmepersonellerliste.forEach((element) {
         personelcihazliste.add(element);
      });
      isletmecihazliste.forEach((element) {
         personelcihazliste.add(element);
      });

      isloading=false;

    });
  }
  void _showDetailsDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          insetPadding: EdgeInsets.zero,
          content: Container(

            height: 200,
            width: 280,
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[

                Positioned(
                  right: -40,
                  top: -40,
                  child: InkResponse(
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                    child: const CircleAvatar(
                      backgroundColor: Colors.red,
                      child: Icon(Icons.close),
                    ),
                  ),
                ),

                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,

                    children: <Widget>[

                    Text('Özel Hizmet Kategorisi',style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),),
                      Divider(height: 30,color: Colors.black,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 5.0),
                            child: Text('Kategori Adı',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                          ),
                        ],
                      ),
                      SizedBox(height: 10,),
                      Container(
                        height: 40,
                        child: TextField(

                          keyboardType: TextInputType.text,



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
                      SizedBox(height: 30,),
                      ElevatedButton(onPressed: (){



                      },
                        child: Text('Kaydet'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            minimumSize: Size(90, 40)
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  AutovalidateMode _autoValidate = AutovalidateMode.disabled;

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: new AppBar(
          title: const Text('Yeni Hizmet',style: TextStyle(color: Colors.black),),
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

        body: isloading?Center(child:CircularProgressIndicator()):SingleChildScrollView(
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
          child: Text('Hizmet Adı',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
        ),
        SizedBox(height: 10,),
        Container(
          height: 40,
          child: TextFormField(

            keyboardType: TextInputType.text,


            controller: hizmet_adi,


            onSaved: (value) {


              hizmet_adi.text = value!;
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Bu alan zorunludur!';
              }
              return null;
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
          child: Text('Hizmet Süresi (dk)',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
        ),
        SizedBox(height: 10,),
        Container(
          height: 40,
          child: TextFormField(

            keyboardType: TextInputType.phone,
            controller: hizmet_sure,


            onSaved: (value) {


              hizmet_sure.text = value!;
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Bu alan zorunludur!';
              }
              return null;
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
          child: Text('Hizmet Fiyatı (₺)',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
        ),
        SizedBox(height: 10,),
        Container(
          height: 40,
          child: TextFormField(

            keyboardType: TextInputType.phone,
            controller: hizmet_fiyat,


            onSaved: (value) {


              hizmet_fiyat.text = value!;
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Bu alan zorunludur!';
              }
              return null;
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

        SizedBox(height: 20,),
        Container(
          padding: const EdgeInsets.only(left: 5.0),
          child: Text('Hizmeti Sunan Personeller & Cihazlar',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
        ),
        SizedBox(height: 10,),
        Container(
          alignment: Alignment.center,
          height: 40,
          width: MediaQuery.of(context).size.width * 0.9, // Adjusted width
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Color(0xFF6A1B9A)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton2(
              isExpanded: true, // Ensure the dropdown expands to full width
              hint: Text(
                seciliYardimci.isEmpty
                    ? 'Personel ve Cihaz Seç'
                    : seciliYardimci.map((e) {
                  if (e is Personel) {
                    return e.personel_adi;
                  } else if (e is Cihaz) {
                    return e.cihaz_adi;
                  }
                  return 'Unknown';
                }).join(', '), // Display selected items in the hint
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).hintColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              items: personelcihazliste.map((item) {
                bool isSelected = seciliYardimci.contains(item);

                return DropdownMenuItem<PersonelCihaz>(
                  value: item,
                  child: StatefulBuilder(
                    builder: (context, menuSetState) {
                      return InkWell(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              seciliYardimci.remove(item); // Deselect if already selected
                            } else {
                              seciliYardimci.add(item); // Select if not selected
                            }
                            isSelected = !isSelected;
                          });

                          menuSetState(() {}); // Update the checkbox state
                        },
                        child: Container(
                          height: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            children: [
                              Icon(
                                isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                                color: isSelected ? Colors.blue : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  (item is Personel)
                                      ? item.personel_adi
                                      : (item is Cihaz ? item.cihaz_adi : 'Unknown'),
                                  style: const TextStyle(fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              }).toList(),
              onChanged: (_) {
                // No action needed here since we are using InkWell for handling selection
              },

              // Button styling
              buttonStyleData: const ButtonStyleData(
                padding: EdgeInsets.symmetric(horizontal: 16),
                height: 50,
                width: double.infinity,
              ),

              // Dropdown styling
              dropdownStyleData: const DropdownStyleData(maxHeight: 400),
              menuItemStyleData: const MenuItemStyleData(height: 40),
            ),
          ),
        ),


        SizedBox(height: 20,),
        Container(
          padding: const EdgeInsets.only(left: 5.0),
          child: Text('Hizmet Kategorisi',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
        ),
        SizedBox(height: 10,),
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

              child: DropdownButton2<HizmetKategorisi>(

                isExpanded: true,
                hint: Text(
                  'Seçiniz..',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).hintColor,
                  ),
                ),
                items: hizmetkategorisi
                    .map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(
                    item.hizmet_kategori_adi,
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                  ),
                ))
                    .toList(),
                value: selectedhizmetkategorisi,


                onChanged: (value) {
                  setState(() {
                    selectedhizmetkategorisi = value;
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
                dropdownSearchData: DropdownSearchData(
                  searchController: hizmetkategorisicontroller,
                  searchInnerWidgetHeight: 50,
                  searchInnerWidget: Container(
                    height: 50,
                    padding: const EdgeInsets.only(
                      top: 8,
                      bottom: 4,
                      right: 8,
                      left: 8,
                    ),
                    child: TextFormField(
                      expands: true,
                      maxLines: null,
                      controller: hizmetkategorisicontroller,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        hintText: 'Ara...',
                        hintStyle: const TextStyle(fontSize: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  searchMatchFn: (item, searchValue) {
                    return item.value.toString().contains(searchValue);
                  },
                ),
                //This to clear the search value when you close the menu
                onMenuStateChange: (isOpen) {
                  if (!isOpen) {
                    hizmetkategorisicontroller.clear();
                  }
                },

              )),
        ),
        SizedBox(height: 20,),
        Padding(
          padding: const EdgeInsets.only(left: 5.0),
          child: Text('Hizmetin Sunulduğu Müşteri Cinsiyeti',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Radio<String>(
              value: '0',
              groupValue: _selectedGender,
              activeColor: Colors.purple[800],
              onChanged: (value) {
                setState(() {
                  _selectedGender = value!;
                });
              },
            ),
            Text('Kadın',style: TextStyle(fontSize: 16),),
            SizedBox(width: 30,),
            Radio<String>(
              value: '1',
              groupValue: _selectedGender,
              activeColor: Colors.purple[800],
              onChanged: (value) {
                setState(() {
                  _selectedGender = value!;
                });
              },
            ),
            Text('Erkek',style: TextStyle(fontSize: 16),),
            SizedBox(width: 25,),
            Radio<String>(
              value: '2',
              groupValue: _selectedGender,
              activeColor: Colors.purple[800],
              onChanged: (value) {
                setState(() {
                  _selectedGender = value!;
                });
              },
            ),
            Text('Unisex',style: TextStyle(fontSize: 16),)

          ],
        ),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                _showDetailsDialog(context);
              },
              child: Row(
                children: [
                  Icon(Icons.add),
                  Text('Yeni Hizmet Kategorisi Ekle'),
                ],
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple[800],
                minimumSize: Size(150, 40),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0)
                ),
                elevation: 5,
              ),

            ),
          ],
        ),
        const SizedBox(
          height: 20.0,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(onPressed: (){
              submitForm();
            },
              child: Text('Kaydet'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
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
  Future<void> submitForm() async {
    log(seciliYardimci.length.toString());
    List <String> personelidler = [];
    List <String> cihazidler = [];
    seciliYardimci.forEach((element) {
      if(element is Personel)
        personelidler.add(element.id);
      else if(element is Cihaz)
        cihazidler.add(element.id);
    });


    personelidler.forEach((element) {

      log("personel id : "+element);
    });
    cihazidler.forEach((element) {

      log("cihaz id : "+element);
    });

    final Map<String, dynamic> formData = {
        'hizmet_kategorisi': selectedhizmetkategorisi?.id ?? "",
        'hizmet_adi':hizmet_adi.text,


      'hizmet_sure': hizmet_sure.text,
      'hizmet_fiyati':hizmet_fiyat.text,
      'cinsiyet':_selectedGender,

      'personel_id':personelidler,
      'cihaz_id':cihazidler,
      'sube':widget.isletmebilgi["id"],



      // Add other form fields
    };
    log(formData.toString());
    /*final response = await http.post(
      Uri.parse('https://webapp.randevumcepte.com.tr/api/v1/sistemeyenihizmetekle'),

      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(formData),
    );

    if (response.statusCode == 200) {

      Navigator.of(context).pop();

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => Hizmetler(isletmebilgi:widget.isletmebilgi)),
      );

    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hizmet eklenirken bir hata oluştu! Hata kodu : '+response.statusCode.toString()),
        ),
      );
      debugPrint('Error: ${response.body}');
    }*/
  }

}

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';

import '../../Backend/backend.dart';
import '../../Frontend/tlrakamacevir.dart';
import '../../Models/adisyonpaketler.dart';
import '../../Models/paketler.dart';
import '../../Models/personel.dart';


class PaketSatisi extends StatefulWidget {
  final String musteriid;
  final bool senetlisatis;
  final dynamic isletmebilgi;
  PaketSatisi({Key? key,required this.musteriid,required this.senetlisatis,required this.isletmebilgi}) : super(key: key);
  @override
  _PaketSatisiState createState() => _PaketSatisiState();
}
class _PaketSatisiState extends State<PaketSatisi> {
  var tryformat = NumberFormat.currency(locale: 'tr_TR',symbol: "");
  late List<Personel> paketsatici;
  bool isloading=true;
  String? seciliisletme;
  TimeOfDay _selectedTime = TimeOfDay.now();
  late List<Paket> paket;
  Paket? selectedPaket;
  TextEditingController paketler = TextEditingController();
  Personel? selectedPaketSatici;
  TextEditingController psatici = TextEditingController();
  TextEditingController baslangictarihi = TextEditingController();
  TextEditingController pfiyat = TextEditingController();
  TextEditingController pseans = TextEditingController();
  TextEditingController randevusaati = TextEditingController();
  void initState() {
    super.initState();
    initialize();

  }
  Future<void> initialize() async{
    seciliisletme = (await secilisalonid())!;
    List <Personel> personelliste = await personellistegetir(seciliisletme!);
    List <Paket> paketliste = await paket_liste(seciliisletme!);
    setState(() {
      paketsatici = personelliste;
      paket  = paketliste;
      isloading = false;
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  const Text('Yeni Paket Satışı',style: TextStyle(color: Colors.black),),

        leading: IconButton(
          icon: Icon(Icons.clear_rounded, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        toolbarHeight: 60,
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
        backgroundColor: Colors.white,
      ),
      body: isloading? Center(child:CircularProgressIndicator()): SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20,),
            Padding(
              padding: const EdgeInsets.only(left: 20.0),
              child: Text('Paket Adı',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
            ),
            SizedBox(height: 10,),
            Container(
              alignment: Alignment.center,
              margin: EdgeInsets.only(left:20,right: 20),
              height: 50,
              width:double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Color(0xFF6A1B9A)),
                borderRadius: BorderRadius.circular(30), //border corner radius

                //you can set more BoxShadow() here

              ),
              child: DropdownButtonHideUnderline(

                  child: DropdownButton2<Paket>(
                    isExpanded: true,
                    hint: Text(
                      'Paket Seç',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                    items: paket
                        .map((item) => DropdownMenuItem(

                      value: item,
                      child: Text(
                        item.paket_adi,
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ))
                        .toList(),
                    value: selectedPaket,
                    onChanged: (value) {
                      setState(() {
                        selectedPaket = value;
                        double fiyat = 0;
                        value?.hizmetler.forEach((element) {
                          fiyat += double.parse(element["fiyat"]);
                        });
                        pfiyat.text = tryformat.format(fiyat);
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
                      searchController: paketler,
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
                          controller: paketler,
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            hintText: 'Paket Ara..',
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
                        paketler.clear();
                      }
                    },

                  )),
            ),

            SizedBox(height: 10,),
            Padding(
              padding: const EdgeInsets.only(left: 20.0),
              child: Text('Satıcı',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
            ),
            SizedBox(height: 10,),
            Container(
              alignment: Alignment.center,
              margin: EdgeInsets.only(left:20,right: 20),
              height: 50,
              width:double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Color(0xFF6A1B9A)),
                borderRadius: BorderRadius.circular(30), //border corner radius

                //you can set more BoxShadow() here

              ),
              child: DropdownButtonHideUnderline(

                  child: DropdownButton2<Personel>(

                    isExpanded: true,
                    hint: Text(
                      'Satıcı Seç',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                    items: paketsatici
                        .map((item) => DropdownMenuItem(
                      value: item,
                      child: Text(
                        item.personel_adi,
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ))
                        .toList(),
                    value: selectedPaketSatici,

                    onChanged: (value) {
                      setState(() {
                        selectedPaketSatici = value;
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
                      searchController: psatici,
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
                          controller: psatici,
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            hintText: 'Personel Ara..',
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
                        psatici.clear();
                      }
                    },

                  )),
            ),
            SizedBox(height: 10,),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 20.0),
                        child: Text('Randevu Tarihi',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                      ),
                      SizedBox(height: 10,),
                      Container(
                        padding: const EdgeInsets.only(left: 20.0,right: 20),
                        child:  TextFormField(

                          controller: baslangictarihi,
                          enabled:true,
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
                                baslangictarihi.text =
                                    formattedDate; //set output date to TextField value.
                              });
                            } else {}
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 20.0),
                        child: Text('Randevu Saati',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                      ),
                      SizedBox(height: 10,),
                      Container(
                        padding: const EdgeInsets.only(left: 20.0,right: 20),
                        child: TextFormField(
                          controller: randevusaati,
                          onTap: () async {
                            TimeOfDay? pickedTime = await showTimePicker(
                              context: context, initialTime: TimeOfDay.now(),
                              builder: (BuildContext context, Widget? child) {
                                return MediaQuery(
                                  data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                                  child: child!,
                                );
                              },

                            );

                            if (pickedTime != null && pickedTime != _selectedTime) {
                              setState(() {
                                _selectedTime = pickedTime;
                                randevusaati.text = DateFormat.Hm().format(
                                  DateTime(
                                    2023, // You can use any year, month, and day here.
                                    1,    // You can use any month and day here.
                                    1,    // You can use any month and day here.
                                    pickedTime.hour,
                                    pickedTime.minute,
                                  ),
                                );
                              });
                            }
                          },

                          decoration: InputDecoration(
                            enabled:true,
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
                      ),
                    ],
                  ),
                )
              ],
            ),




            SizedBox(height: 10,),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 20.0),
                        child: Text('Seans Aralığı (gün)',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                      ),
                      SizedBox(height: 10,),
                      Container(
                        padding: const EdgeInsets.only(left: 20.0,right: 20),
                        child: TextField(
                          controller: pseans,
                          onSubmitted: (text)=>print(pseans.text),
                          keyboardType: TextInputType.phone,

                          enabled:true,

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
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 20.0),
                        child: Text('Fiyat',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                      ),
                      SizedBox(height: 10,),
                      Container(
                        padding: const EdgeInsets.only(left: 20.0,right: 20),
                        child: TextField(
                          controller: pfiyat,
                          keyboardType: TextInputType.phone,
                          onSubmitted: (text)=>print(pfiyat.text),
                          decoration: InputDecoration(
                            enabled:true,
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
                      ),
                    ],
                  ),
                )
              ],
            ),
            SizedBox(height: 20,),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(onPressed: () async {
                  final AdisyonPaket paket = AdisyonPaket(  baslangic_tarihi: baslangictarihi.text,seans_araligi: pseans.text, id:"",adisyon_id: "", paket_id: selectedPaket?.id ?? "",  fiyat: tlyirakamacevir(pfiyat.text).toString(), personel_id: selectedPaketSatici?.id ?? "", taksitli_tahsilat_id: "", senet_id: "", indirim_tutari: "", hediye: "false",paket: selectedPaket?.toJson() ?? "", personel: selectedPaketSatici?.toJson() ?? "",seans_baslangic_saati: randevusaati.text);
                  if(!widget.senetlisatis)
                  {
                    AdisyonPaket eklenepaket = await adisyonpaketekle(paket,widget.musteriid ,context,seciliisletme!,randevusaati.text,true,"");
                    Navigator.pop(context, eklenepaket);
                  }
                  else
                    Navigator.pop(context, paket);

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
        ),
      ),
    );
  }

}
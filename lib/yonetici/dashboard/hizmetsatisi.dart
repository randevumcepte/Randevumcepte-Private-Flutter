import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';

import '../../Backend/backend.dart';
import '../../Models/adisyonhizmetler.dart';
import '../../Models/isletmehizmetleri.dart';
import '../../Models/personel.dart';


class HizmetSatisi extends StatefulWidget {
  final String musteriid;
  final bool senetlisatis;
  final dynamic isletmebilgi;
  HizmetSatisi({Key? key, required this.musteriid,required this.senetlisatis,required this.isletmebilgi}) : super(key: key);
  @override
  _HizmetSatisiState createState() => _HizmetSatisiState();
}
class _HizmetSatisiState extends State<HizmetSatisi> {
  bool isloading = true;
  late List<Personel> personel;
  late List<IsletmeHizmet> hizmet;


  Personel? selectedpersonel;
  String? seciliisletme;
  TextEditingController secilipersonel = TextEditingController();
  IsletmeHizmet? selectedhizmet;

  TextEditingController secilihizmet = TextEditingController();
  TextEditingController islem_tarihi = TextEditingController();

  TimeOfDay _selectedTime = TimeOfDay.now();
  TextEditingController islem_saati = TextEditingController();


  TextEditingController fiyat = TextEditingController();
  TextEditingController sure_dk = TextEditingController();

  void initState() {
    super.initState();
    initialize();

  }
  Future<void> initialize() async{
    seciliisletme = (await secilisalonid())!;
    List <Personel> personelliste = await personellistegetir(seciliisletme!);
    List <IsletmeHizmet> hizmetliste = await isletmehizmetleri(seciliisletme!);
    setState(() {
      personel = personelliste;
      hizmet  = hizmetliste;
      isloading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  const Text('Yeni Hizmet Satışı',style: TextStyle(color: Colors.black),),

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
      body: isloading ? Center(child: CircularProgressIndicator(),) : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20,),
            Padding(
              padding: const EdgeInsets.only(left: 20.0),
              child: Text('İşlem Tarihi',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
            ),
            SizedBox(height: 10,),
            Container(

              padding: EdgeInsets.only(left:20,right: 20),
              child: TextField(

                controller: islem_tarihi,
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
                      islem_tarihi.text =
                          formattedDate; //set output date to TextField value.
                    });
                  } else {}
                },
              ),

            ),
            SizedBox(height: 10,),
            Padding(
              padding: const EdgeInsets.only(left: 20.0),
              child: Text('İşlem Saati',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
            ),
            SizedBox(height: 10,),
            Container(
              padding: EdgeInsets.only(left:20,right: 20),
              child: TextField(
                controller: islem_saati,
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
                      islem_saati.text = DateFormat.Hm().format(
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

                  suffixIcon: Icon(Icons.access_time),
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
            SizedBox(height: 10,),
            Padding(
              padding: const EdgeInsets.only(left: 20.0),
              child: Text('Personel',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
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
                      'Personel Seç',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                    items: personel
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
                    value: selectedpersonel,

                    onChanged: (value) {
                      setState(() {
                        selectedpersonel = value;
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
                      searchController: secilipersonel,
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
                          controller: secilipersonel,
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
                        secilipersonel.clear();
                      }
                    },

                  )),
            ),
            SizedBox(height: 10,),
            Padding(
              padding: const EdgeInsets.only(left: 20.0),
              child: Text('Hizmet',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
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

                  child: DropdownButton2<IsletmeHizmet>(
                    isExpanded: true,
                    hint: Text(
                      'Hizmet Seç',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                    items: hizmet
                        .map((item) => DropdownMenuItem(

                      value: item,
                      child: Text(
                        item.hizmet["hizmet_adi"],
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ))
                        .toList(),
                    value: selectedhizmet,
                    onChanged: (value) {
                      setState(() {
                        selectedhizmet = value;
                        sure_dk.text = selectedhizmet?.sure ?? "";
                        fiyat.text = selectedhizmet?.fiyat ?? "";
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
                      searchController: secilihizmet,
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
                          controller: secilihizmet,
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            hintText: 'Hizmet Ara..',
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
                        secilihizmet.clear();
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
                        child: Text('Süre (dk)',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                      ),
                      SizedBox(height: 10,),
                      Container(
                        padding: const EdgeInsets.only(left: 20.0,right: 20),
                        child: TextField(
                          controller: sure_dk,
                          onSubmitted: (text)=>print(sure_dk.text),
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
                        child: Text('Fiyat ₺',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                      ),
                      SizedBox(height: 10,),
                      Container(
                        padding: const EdgeInsets.only(left: 20.0,right: 20),
                        child: TextField(
                          controller: fiyat,
                          keyboardType: TextInputType.phone,
                          onSubmitted: (text)=>print(fiyat.text),
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
                ElevatedButton(onPressed: () async{
                  final AdisyonHizmet adisyonhizmet = AdisyonHizmet(id:"", adisyon_id: "", hizmet_id: selectedhizmet?.hizmet_id??"", islem_tarihi: islem_tarihi.text, islem_saati: islem_saati.text, sure: sure_dk.text, fiyat: fiyat.text, geldi: "1", personel_id: selectedpersonel?.id ?? "", cihaz_id: "", oda_id: "", dogrulama_kodu: "", taksitli_tahsilat_id: "", senet_id: "", indirim_tutari: "", hediye: "",hizmet: selectedhizmet?.hizmet??"",personel: selectedpersonel?? "");
                  if(!widget.senetlisatis)
                  {

                    AdisyonHizmet eklenenhizmet = await adisyonhizmetekle(adisyonhizmet,widget.musteriid ,context,seciliisletme!);
                    Navigator.pop(context, eklenenhizmet);
                  }
                  else
                    Navigator.pop(context, adisyonhizmet);
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
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';


class PaketSatisiAdisyon extends StatefulWidget {
  PaketSatisiAdisyon({Key? key}) : super(key: key);
  @override
  _PaketSatisiAdisyonState createState() => _PaketSatisiAdisyonState();
}
class _PaketSatisiAdisyonState extends State<PaketSatisiAdisyon> {
  final List<String> paketsatici = [
    'Cevriye',
    'Beyzanur Sarılı',
    'Anıl Orbey',
    'Çağlar Filiz',
    'Ferdi Korkmaz',
    'Elif Çetin',

  ];
  final List<String> paket = [
    'ekim paketi',
    'bayram paketi',
    'kasım paketi',
    'eylül paketi',
    'kampanya paketi',
    'mayıs paketi',

  ];
  String? selectedPaket;
  TextEditingController paketler = TextEditingController();
  String? selectedPaketSatici;
  TextEditingController psatici = TextEditingController();
  TextEditingController baslangictarihi = TextEditingController();
  TextEditingController pfiyat = TextEditingController();
  TextEditingController pseans = TextEditingController();
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
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: SizedBox(
              width: 100, // <-- Your width
              child: YukseltButonu(isletme_bilgi: null,)
            ),
          ),


        ],
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
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

                  child: DropdownButton2<String>(
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
                        item,
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
              child: Text('Başlangıç Tarihi',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
            ),
            SizedBox(height: 10,),
            Container(

              padding: EdgeInsets.only(left:20,right: 20),
              child: TextField(

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

                  child: DropdownButton2<String>(

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
                        item,
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
            SizedBox(height: 10,),
            Padding(
              padding: const EdgeInsets.only(left: 20.0),
              child: Text('Notlar',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
            ),
            SizedBox(height: 10,),
            Container(
              padding: EdgeInsets.only(left:20,right: 20),
              child: TextField(

                keyboardType: TextInputType.text,



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

            SizedBox(height: 20,),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(onPressed: (){
                  final Map<String, dynamic> data = {
                    'text': baslangictarihi.text,
                    'text2': pfiyat.text,
                    'text3': pseans.text,
                    'dropdownValue': selectedPaketSatici,
                    'dropdownValue2': selectedPaket,
                  };
                  Navigator.pop(context, data);
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
        ),
      ),
    );
  }

}
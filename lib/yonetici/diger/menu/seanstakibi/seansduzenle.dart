import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


class SeansDuzenle extends StatefulWidget {
  SeansDuzenle({Key? key}) : super(key: key);
  @override
  _SeansDuzenleState createState() => _SeansDuzenleState();
}
class _SeansDuzenleState extends State<SeansDuzenle> {



  final List<String> odalar = [
    'Lazer Odası',


  ];
  final List<String> seanspersonel = [
    'Cevriye Güleç',
    'Çağlar Filiz',
    'Elif Çetin',


  ];
  final List<String> seansdurum = [

    'Bekliyor',
    'Geldi',
    'Gelmedi',

  ];
  final List<String> islemadi = [
    'Saç Kesimi',
    'Saç Bakımı',
    'Fön',
    'Ağda',
    'Hareketli Kesim',
    'Sakal Tıraşı',

  ];
  String? selectedoda;
  TextEditingController odaController = TextEditingController();
  String? selectedislemadi;
  TextEditingController islemadiController = TextEditingController();
  String? selectedseansdurum='Bekliyor';
  TextEditingController seansdurumController = TextEditingController();
  String? selectedseanspersonel;
  TextEditingController seanspersonelController = TextEditingController();
  TextEditingController dateInput = TextEditingController();

  Map<String, Color> itemColors = {
    'Bekliyor': Colors.yellow,
    'Gelmedi': Colors.red,
    'Geldi': Colors.green,
  };
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  const Text('Seans Detayı',style: TextStyle(color: Colors.black),),

        leading: IconButton(
          icon: Icon(Icons.clear_rounded, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        toolbarHeight: 60,

        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20,),

            Row(
              children: [
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 20.0),
                      child: Text('Seans Tarihi',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                    ),
                    SizedBox(height: 10,),
                    Container(
                      height: 40,
                      padding: EdgeInsets.only(left:20,right: 20),
                      child: TextField(

                        controller: dateInput,
                        enabled:true,
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
                              dateInput.text =
                                  formattedDate; //set output date to TextField value.
                            });
                          } else {}
                        },
                      ),

                    ),
                  ],
                )
                ),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 20.0),
                      child: Text('İşlem Adı',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                    ),
                    SizedBox(height: 10,),
                    Container(

                      alignment: Alignment.center,
                      margin: EdgeInsets.only(left:20,right: 20),
                      height: 40,
                      width:double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Color(0xFF6A1B9A)),
                        borderRadius: BorderRadius.circular(10), //border corner radius

                        //you can set more BoxShadow() here

                      ),
                      child: DropdownButtonHideUnderline(

                          child: DropdownButton2<String>(

                            isExpanded: true,
                            hint: Text(
                              'Seç',
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).hintColor,
                              ),
                            ),
                            items: islemadi
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
                            value: selectedislemadi,

                            onChanged: (value) {
                              setState(() {
                                selectedislemadi = value;
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
                              searchController: islemadiController,
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
                                  controller: islemadiController,
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    hintText: 'Ara..',
                                    hintStyle: const TextStyle(fontSize: 12),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(5),
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
                                islemadiController.clear();
                              }
                            },

                          )),
                    ),
                  ],
                ))
              ],
            ),
            SizedBox(height: 20,),
            Row(
              children: [
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 20.0),
                      child: Text('Oda (Opsiyonel)',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                    ),
                    SizedBox(height: 10,),
                    Container(

                      alignment: Alignment.center,
                      margin: EdgeInsets.only(left:20,right: 20),
                      height: 40,
                      width:double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Color(0xFF6A1B9A)),
                        borderRadius: BorderRadius.circular(10), //border corner radius

                        //you can set more BoxShadow() here

                      ),
                      child: DropdownButtonHideUnderline(

                          child: DropdownButton2<String>(

                            isExpanded: true,
                            hint: Text(
                              'Seç',
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).hintColor,
                              ),
                            ),
                            items: odalar
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
                            value: selectedoda,

                            onChanged: (value) {
                              setState(() {
                                selectedoda = value;
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
                              searchController: odaController,
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
                                  controller: odaController,
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    hintText: 'Ara..',
                                    hintStyle: const TextStyle(fontSize: 12),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(5),
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
                                odaController.clear();
                              }
                            },

                          )),
                    ),
                  ],
                )
                ),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 20.0),
                      child: Text('Durum',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                    ),
                    SizedBox(height: 10,),
                    DropdownButtonHideUnderline(

                        child: DropdownButton2<String>(

                          isExpanded: true,
                          hint: Text(
                            'Seç',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                          items: seansdurum
                              .map((item) => DropdownMenuItem(
                            value: item,
                            child: Container(
                              height: double.infinity,
                              width: double.infinity,
                              color: itemColors[item] ?? Colors.white,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    item,
                                    style: const TextStyle(
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ))
                              .toList(),
                          value: selectedseansdurum,

                          onChanged: (value) {
                            setState(() {
                              selectedseansdurum = value;
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
                            searchController: seansdurumController,
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
                                controller: seansdurumController,
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  hintText: 'Ara..',
                                  hintStyle: const TextStyle(fontSize: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(5),
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
                              seansdurumController.clear();
                            }
                          },

                        )),
                  ],
                ))
              ],
            ),
            SizedBox(height: 20,),
            Padding(
              padding: const EdgeInsets.only(left: 20.0),
              child: Text('Personel & Cihaz',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
            ),
            SizedBox(height: 10,),
            Container(

              alignment: Alignment.center,
              margin: EdgeInsets.only(left:20,right: 20),
              height: 40,
              width:double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Color(0xFF6A1B9A)),
                borderRadius: BorderRadius.circular(10), //border corner radius

                //you can set more BoxShadow() here

              ),
              child: DropdownButtonHideUnderline(

                  child: DropdownButton2<String>(

                    isExpanded: true,
                    hint: Text(
                      'Seç',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                    items: seanspersonel
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
                    value: selectedseanspersonel,

                    onChanged: (value) {
                      setState(() {
                        selectedseanspersonel = value;
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
                      searchController: seanspersonelController,
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
                          controller: seanspersonelController,
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            hintText: 'Ara..',
                            hintStyle: const TextStyle(fontSize: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5),
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
                        seanspersonelController.clear();
                      }
                    },

                  )),
            ),







            SizedBox(height: 20,),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                ElevatedButton(onPressed: (){
                  final Map<String, dynamic> data = {
                    'text': dateInput.text,
                           };
                  Navigator.pop(context, data);
                },
                  child: Row(
                    children: [

                      Text(' Kaydet'),
                    ],
                  ),
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
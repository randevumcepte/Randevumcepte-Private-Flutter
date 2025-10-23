import 'dart:developer';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:page_transition/page_transition.dart';
import 'package:randevu_sistem/Frontend/progressloading.dart';
import '../../../../Backend/backend.dart';
import '../../../../Frontend/popupdialogs.dart';
import '../../../dashboard/deneme.dart';
import '../../../adisyonlar/yeniadisyon.dart';
import '../musteriler/yeni_musteri.dart';
import 'kasagelirler.dart';
import 'kasagiderler.dart';
import 'kasatumu.dart';

class KasaRaporu extends StatefulWidget {
  final dynamic isletmebilgi;
  const KasaRaporu({Key? key,required this.isletmebilgi}) : super(key: key);

  @override
  _KasaRaporuState createState() =>
      _KasaRaporuState();
}


class _KasaRaporuState extends State<KasaRaporu> {
  var tryformat = NumberFormat.currency(locale: 'tr_TR',symbol: "");
  final List<String> odemeyontemi = [
    'Tümü',
    'Nakit',
    'Kredi Kartı',
    'Havale/EFT',

  ];
  final List<String> kasazaman= [
    'Bugün',
    'Dün',
    'Bu ay',
    'Geçen ay',
    'Bu yıl',


  ];
  late String? seciliisletme;
  bool filtervalid = true;
  String? selectedodemeyontemi;
  TextEditingController odemeyontemicontroller = TextEditingController(text: '');
  late double gelir;
  late double gider;
  double toplam = 0;
  String? selectedkasazaman;
  TextEditingController kasazamancontroller = TextEditingController(text: '');
  bool _isloading = true;
  void initState() {

    super.initState();
    initialize();



  }
  Future<void> _refreshPage() async {

    setState(() {

     _isloading=true;
      initialize();
    });

  }
  Future<void> initialize() async
  {
    seciliisletme = (await secilisalonid())!;
    kasaraporu(seciliisletme!,kasazamancontroller.text,odemeyontemicontroller.text).then((data) {
      setState(() {
        gelir = double.parse(data['toplamgelir'].toString());
        gider = double.parse(data['toplamgider'].toString());
        toplam = gelir-gider;
        _isloading = false;

      });
    });
  }
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _isloading ? Center(child: CircularProgressIndicator(),) : DefaultTabController(
        length: 3,
        child: Scaffold(

          appBar: AppBar(
            title: Text('Kasa Raporu',style: TextStyle(color: Colors.black,fontSize: 18),),
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),

            toolbarHeight: 60,
            actions: <Widget>[

              IconButton(onPressed: (){
                showModalBottomSheet(
                    context: context,
                    builder: (context) {
                      return StatefulBuilder(
                          builder: (context, setStateSB){
                            return Column(

                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                SizedBox(height: 20,),
                                Container(
                                  padding: const EdgeInsets.only(left: 20.0),
                                  child: Text('Ödeme Yöntemi',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
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
                                          'Seçiniz..',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Theme.of(context).hintColor,
                                          ),
                                        ),
                                        items: odemeyontemi
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
                                        value: selectedodemeyontemi,

                                        onChanged: (value) {
                                          setStateSB(() {
                                            selectedodemeyontemi = value;
                                            odemeyontemicontroller.text=value!;
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
                                          searchController: odemeyontemicontroller,
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
                                              controller: odemeyontemicontroller,
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
                                            odemeyontemicontroller.clear();
                                          }
                                        },

                                      )),
                                ),
                                SizedBox(height: 20,),
                                Container(
                                  padding: const EdgeInsets.only(left: 20.0),
                                  child: Text('Zaman',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
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
                                          'Seçiniz..',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Theme.of(context).hintColor,
                                          ),
                                        ),
                                        items: kasazaman
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
                                        value: selectedkasazaman,

                                        onChanged: (value) {
                                          setStateSB(() {
                                            selectedkasazaman = value;
                                            kasazamancontroller.text = value!;
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
                                          searchController: kasazamancontroller,
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
                                              controller: kasazamancontroller,
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
                                            kasazamancontroller.clear();
                                          }
                                        },

                                      )),
                                ),
                                SizedBox(height: 30,),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ElevatedButton(onPressed: (){
                                      if(selectedkasazaman == '')
                                        filtervalid = false;
                                      if(selectedodemeyontemi=='')
                                        filtervalid = false;
                                      if(!filtervalid)
                                        formWarningDialogs(context,'UYARI','Lütfen ödeme yönetmini ve terihi seçiniz!');
                                      else{
                                        Navigator.of(context).pop();
                                        _refreshPage();
                                      }



                                    }, child: Text('Sonuçları Göster'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.purple[800],
                                        foregroundColor: Colors.white,

                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 50,),
                              ],
                            );
                          }
                      );
                    }
                );
              }, icon:  Icon(Icons.filter_list_outlined,color:Colors.black,),iconSize: 26,),



            ],
            backgroundColor: Colors.white,


            bottom:   PreferredSize(
              preferredSize: Size.fromHeight(60),
              child: Container(
                padding: EdgeInsets.only(bottom: 10),
                child: TabBar(
                    onTap: (index) {
                      // Disabling the second tab (index 1)
                      if (index == 2) {
                        DefaultTabController.of(context)?.animateTo(--index);

                      }

                      // Change the tab if it is not the disabled one

                    },
                    isScrollable: false,
                    indicatorSize: TabBarIndicatorSize.label,
                    labelColor: Colors.purple,
                    unselectedLabelColor: Colors.purple[800],
                    labelPadding: EdgeInsets.only(left: 5, right: 5),
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      color: Colors.transparent, // This will be transparent so that we can apply a custom decoration
                      border: Border.all(
                        color: Colors.purple[800]!,
                        width: 1.5,
                      ),
                    ),
                    tabs: [

                      Tab(
                        child: Container(

                          child: Align(
                            alignment: Alignment.center,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 1,),
                                Text( tryformat.format(gelir).toString()+' ₺',style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold),),
                                Text("Gelir"),

                              ],
                            ),
                          ),
                        ),
                      ),
                      Tab(
                        child: Container(
                          width: 180,
                          child: Align(
                            alignment: Alignment.center,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 1,),
                                Text(tryformat.format(gider).toString()+' ₺',style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold),),
                                Text("Gider"),

                              ],
                            ),
                          ),
                        ),
                      ),
                      /*Tab(
                        child: Align(
                          alignment: Alignment.center,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 8,),
                              Text(toplam.toString() +' ₺',style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold),),
                              Text("Toplam"),

                            ],
                          ),
                        ),
                      ),*/
                    ]),
              ),
            ),

          ),


          body: TabBarView(
            children: <Widget>[
              Gelirler(tarih: kasazamancontroller.text,odeme_yontemi: odemeyontemicontroller.text,),
              Giderler(tarih:kasazamancontroller.text,odeme_yontemi: odemeyontemicontroller.text,isletmebilgi: widget.isletmebilgi,),

            ],
          ),
        ),
      ),
    );
  }
}
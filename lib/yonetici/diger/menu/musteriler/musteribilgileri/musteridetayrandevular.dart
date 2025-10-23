import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import '../../../../../Frontend/altyuvarlakmenu.dart';



class MusteriRandevulariMenu extends StatefulWidget {
  final dynamic isletmebilgi;
  MusteriRandevulariMenu({Key? key,required this.isletmebilgi}) : super(key: key);
  @override
  _MusteriRandevulariMenuState createState() => _MusteriRandevulariMenuState();
}

class _MusteriRandevulariMenuState extends State<MusteriRandevulariMenu> {
  final List<String> randevuolusturma = [
    'Tümü',
    'Salon',
    'Web',
    'Uygulama',
  ];
  final List<String> randevudurum= [
    'Tümü',
    'Onay Bekleyen',
    'Onaylı',
    'Reddedilen',
    'müşteri tarafından iptal edilen',


  ];
  final List<String> randevutarih= [
    'Bugün',
    'Yarın',
    'Bu ay',
    'Önümüzdeki ay',
    'Bu yıl',
    'Önümüzdeki yıl',


  ];

  List<Map<String, dynamic>> data = [
    {'Tarih': DateTime(2023,09,15), 'Telefon No': '5383792106', 'Durum': 'Onaylı','icon': Icons.chevron_right},
    {'Tarih': DateTime(2023,10,10), 'Telefon No': '5386237563', 'Durum': 'İptal','icon': Icons.chevron_right},
    {'Tarih': DateTime(2023,10,15), 'Telefon No': '5383965761', 'Durum': 'Beklemede','icon': Icons.chevron_right},
    {'Tarih': DateTime(2023,10,14), 'Telefon No': '5383965761', 'Durum': 'Gelmedi','icon': Icons.chevron_right},
    {'Tarih': DateTime(2023,11,15), 'Telefon No': '5383965761', 'Durum': 'Geldi','icon': Icons.chevron_right},



  ];
  Color? getStatusColor(String Durum) {
    switch (Durum) {
      case 'Onaylı':
        return Colors.purple[800];
      case 'İptal':
        return Colors.black;
      case 'Beklemede':
        return Colors.yellow[700];
      case 'Geldi':
        return Colors.green;
      case 'Gelmedi':
        return Colors.red[600];
      default:
        return Colors.blue; // Default color
    }
  }

  String? selectedrandevuolusturma;
  TextEditingController randevuolusturmacontroller = TextEditingController();

  String? selectedrandevudurum;
  TextEditingController randevudurumcontroller = TextEditingController();

  String? selectedrandevutarih;
  TextEditingController randevutarihcontroller = TextEditingController();
  @override
  Widget build(BuildContext context) {
    data.sort((a,b)=>b['Tarih'].compareTo(a['Tarih']));
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      //floatingActionButton: AltYuvarlakYeniEkleMenu(isletme_bilgi: widget.isletmebilgi,),

      appBar: AppBar(
        title: Text('Randevular',style: TextStyle(color: Colors.black,fontSize: 18),),
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
                              child: Text('Randevu Oluşturma Yeri',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
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
                                    items: randevuolusturma
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
                                    value: selectedrandevuolusturma,

                                    onChanged: (value) {
                                      setStateSB(() {
                                        selectedrandevuolusturma = value;
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
                                      searchController: randevuolusturmacontroller,
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
                                          controller: randevuolusturmacontroller,
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
                                        randevuolusturmacontroller.clear();
                                      }
                                    },

                                  )),
                            ),
                            SizedBox(height: 20,),
                            Container(
                              padding: const EdgeInsets.only(left: 20.0),
                              child: Text('Randevu Durumu',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
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
                                    items: randevudurum
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
                                    value: selectedrandevudurum,

                                    onChanged: (value) {
                                      setStateSB(() {
                                        selectedrandevudurum = value;
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
                                      searchController: randevudurumcontroller,
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
                                          controller: randevudurumcontroller,
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
                                        randevudurumcontroller.clear();
                                      }
                                    },

                                  )),
                            ),
                            SizedBox(height: 20,),
                            Container(
                              padding: const EdgeInsets.only(left: 20.0),
                              child: Text('Tarih',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
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
                                    items: randevutarih
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
                                    value: selectedrandevutarih,

                                    onChanged: (value) {
                                      setStateSB(() {
                                        selectedrandevutarih = value;
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
                                      searchController: randevutarihcontroller,
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
                                          controller: randevutarihcontroller,
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
                                        randevutarihcontroller.clear();
                                      }
                                    },

                                  )),
                            ),
                            SizedBox(height: 30,),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton(onPressed: (){}, child: Text('Sonuçları Göster'),
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




      ),
      body:
      SingleChildScrollView(
        child: Container(

          width: 500,
          child: InteractiveViewer(
            scaleEnabled: false,
            child: DataTable(
              columnSpacing: 20,
              showCheckboxColumn: false,
              columns: [
                DataColumn(label: Expanded(child: Text('Tarih'))),
                DataColumn(label: Expanded(child: Text('Telefon No'))),
                DataColumn(label: Expanded(child: Text('Durum'))),
              ],
              rows: data.map((item) {
                final status = item['Durum'] ?? '';
                final cellColor = getStatusColor(status);
                final formattedDate =
                    "${item['Tarih'].day}.${item['Tarih'].month}.${item['Tarih'].year}";
                // Determine whether to show the icon
                return  DataRow(
                  cells: [
                    DataCell(
                      Container(width:95,child: Text(formattedDate)),
                    ),
                    DataCell(
                      Text(item['Telefon No'].toString()),
                    ),

                    DataCell(
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [

                          ElevatedButton(onPressed: (){},style: ElevatedButton.styleFrom(backgroundColor:cellColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
                              minimumSize: Size(100, 20)

                          )

                              ,child: Text(item['Durum'],style: TextStyle(color: Colors.white),)),

                          Icon(item['icon']),



                        ],
                      ),
                    ),
                  ],
                  onSelectChanged: (_) {
                    _showDetailsDialog(context, item,status);
                  },
                );
              }


              )
                  .toList(),



            ),
          ),
        ),
      ),


    );
  }

  void _showDetailsDialog(BuildContext context, Map<String, dynamic> item,String status) {
    final _formKey = GlobalKey<FormState>();

    if(status=='Onaylı') {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            insetPadding: EdgeInsets.zero,
            content: Container(

              height: 280,
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

                        Text(
                          'Anıl Orbey', style: TextStyle(fontWeight: FontWeight
                            .bold),),
                        Divider(color: Colors.black,
                          height: 10,),
                        Row(
                          children: [
                            Text('Telefon'), SizedBox(width: 22,),
                            Text(':'),
                            Text(' 5316237563')
                          ],
                        ),
                        Row(
                          children: [
                            Text('Hizmet'),
                            SizedBox(width: 25,),
                            Text(': '),
                            Expanded(
                                child: Text('Ağda (tüm vücut)(Cevriye Güleç)'))
                          ],

                        ),
                        Row(
                          children: [
                            Text('Zaman'), SizedBox(width: 26,),
                            Text(':'),
                            Text(' 07.09.2023 17:45')
                          ],

                        ),
                        Row(
                          children: [
                            Text('Oluşturan'), SizedBox(width: 7.5,),
                            Text(':'),
                            Text(' Elif Çetin')
                          ],
                        ),
                        Row(
                          children: [
                            Text('Durum'), SizedBox(width: 10,),
                            SizedBox(width: 18,),
                            Text(':'),
                            Text(' Onaylı')
                          ],

                        ),
                        Divider(color: Colors.black,
                          height: 10,),
                        Row(

                          children: [
                            ElevatedButton(onPressed: () {}, child:
                            Text('Düzenle'),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple[800],
                                  elevation: 5,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5.0)
                                  ),
                                  minimumSize: Size(130, 30)
                              ),
                            ),
                            SizedBox(width: 15,),
                            ElevatedButton(onPressed: () {}, child:
                            Text('İptal Et'),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  elevation: 5,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5.0)
                                  ),
                                  minimumSize: Size(130, 30)
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            ElevatedButton(onPressed: () {}, child:
                            Text('Gelmedi'),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  elevation: 5,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5.0)
                                  ),
                                  minimumSize: Size(130, 30)
                              ),
                            ),
                            SizedBox(width: 15,),
                            ElevatedButton(onPressed: () {}, child:
                            Text('Geldi & Tahsilat'),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  elevation: 5,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5.0)
                                  ),
                                  minimumSize: Size(20, 30)
                              ),
                            ),


                          ],
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
    if(status=='İptal' || status=='Geldi' || status=='Gelmedi') {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            insetPadding: EdgeInsets.zero,
            content: Container(

              height: 250,
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

                        Text(
                          'Anıl Orbey', style: TextStyle(fontWeight: FontWeight
                            .bold),),
                        Divider(color: Colors.black,
                          height: 10,),
                        Row(
                          children: [
                            Text('Telefon'), SizedBox(width: 22,),
                            Text(':'),
                            Text(' 5316237563')
                          ],
                        ),
                        Row(
                          children: [
                            Text('Hizmet'),
                            SizedBox(width: 25,),
                            Text(': '),
                            Expanded(
                                child: Text('Ağda (tüm vücut)(Cevriye Güleç)'))
                          ],

                        ),
                        Row(
                          children: [
                            Text('Zaman'), SizedBox(width: 26,),
                            Text(':'),
                            Text(' 07.09.2023 17:45')
                          ],

                        ),
                        Row(
                          children: [
                            Text('Oluşturan'), SizedBox(width: 7.5,),
                            Text(':'),
                            Text(' Elif Çetin')
                          ],
                        ),
                        Row(
                          children: [
                            Text('Durum'), SizedBox(width: 10,),
                            SizedBox(width: 18,),
                            Text(':'),
                            Text(' Onaylı')
                          ],

                        ),
                        Divider(color: Colors.black,
                          height: 30,),
                        ElevatedButton(onPressed: () {}, child:
                        Text('Düzenle'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple[800],
                              elevation: 5,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5.0)
                              ),
                              minimumSize: Size(130, 30)
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
    if(status=='Beklemede') {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            insetPadding: EdgeInsets.zero,
            content: Container(

              height: 250,
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

                        Text(
                          'Anıl Orbey', style: TextStyle(fontWeight: FontWeight
                            .bold),),
                        Divider(color: Colors.black,
                          height: 10,),
                        Row(
                          children: [
                            Text('Telefon'), SizedBox(width: 22,),
                            Text(':'),
                            Text(' 5316237563')
                          ],
                        ),
                        Row(
                          children: [
                            Text('Hizmet'),
                            SizedBox(width: 25,),
                            Text(': '),
                            Expanded(
                                child: Text('Ağda (tüm vücut)(Cevriye Güleç)'))
                          ],

                        ),
                        Row(
                          children: [
                            Text('Zaman'), SizedBox(width: 26,),
                            Text(':'),
                            Text(' 07.09.2023 17:45')
                          ],

                        ),
                        Row(
                          children: [
                            Text('Oluşturan'), SizedBox(width: 7.5,),
                            Text(':'),
                            Text(' Elif Çetin')
                          ],
                        ),
                        Row(
                          children: [
                            Text('Durum'), SizedBox(width: 10,),
                            SizedBox(width: 18,),
                            Text(':'),
                            Text(' Onaylı')
                          ],

                        ),
                        Divider(color: Colors.black,
                          height: 30,),
                        Row(

                          children: [
                            ElevatedButton(onPressed: () {}, child:
                            Text('Onayla'),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  elevation: 5,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5.0)
                                  ),
                                  minimumSize: Size(130, 30)
                              ),
                            ),
                            SizedBox(width: 15,),
                            ElevatedButton(onPressed: () {}, child:
                            Text('İptal Et'),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  elevation: 5,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5.0)
                                  ),
                                  minimumSize: Size(130, 30)
                              ),
                            ),
                          ],
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
  }


}

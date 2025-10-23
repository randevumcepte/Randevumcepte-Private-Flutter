import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';

import 'satislar/hizmetSatislaridetay.dart';
import 'satislar/paketSatislaridetay.dart';
import 'satislar/urunSatislariadisyon.dart';


class MusteriDetay extends StatefulWidget {
  const MusteriDetay({Key? key}) : super(key: key);

  @override
  _MusteriDetayState createState() =>
      _MusteriDetayState();
}

class _MusteriDetayState extends State<MusteriDetay> {
  String? selectedPersonel;
  TextEditingController personelcontroller = TextEditingController();
  final List<String> personel = [
    'Cevriye',
    'Beyzanur Sarılı',
    'Anıl Orbey',
    'Çağlar Filiz',
    'Ferdi Korkmaz',
    'Elif Çetin',

  ];
  TextStyle headingStyle = const TextStyle(
      fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white);
  TextEditingController textController = TextEditingController();
  RegExp digitValidator  = RegExp("[0-9]+");
  bool isANumber = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildListView(),

    );
  }ListView _buildListView() {
    return ListView(
      children: <Widget>[
        ListTile(
          title: Row(
            children: [Text('Anıl Orbey'),
              Spacer(),
              Text('Durum : '),
              ElevatedButton(onPressed: (){}, child: Text('Geldi',style: TextStyle(color: Colors.white),),
                style: ElevatedButton.styleFrom(
                    backgroundColor:Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
                    minimumSize: Size(65, 20)
                ),
              )

            ],
          )
          
        ),
        const Divider(),
        ListTile(
          title: Row(
            children: [
              Column(
                children: [
                  Text('Oluşturulma Tarihi'),
                  Text('05.10.2023'),
                ],
              ),
              Spacer(),
              Column(
                children: [
                  Text('İşlem Tarihi'),
                  Text('18.10.2023')
                ],
              )

            ],
          )

        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.only(left: 10.0),
          child: Text('Personel',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
        ),
        SizedBox(height: 10,),
        Container(
          alignment: Alignment.center,
          margin: EdgeInsets.only(left:10,right: 10),
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
                    item,
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                  ),
                ))
                    .toList(),
                value: selectedPersonel,

                onChanged: (value) {
                  setState(() {
                    selectedPersonel = value;
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
                  searchController: personelcontroller,
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
                      controller: personelcontroller,
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
                    personelcontroller.clear();
                  }
                },

              )),
        ),
        SizedBox(height: 10,),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextFormField(
            decoration: const InputDecoration(labelText: 'Notlar'),
            keyboardType: TextInputType.text,

          ),
        ),
        const Divider(),
        Column(
          children: [

                Container(width:350,
                    height: 35,
                    color: Colors.purple[800],
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [

                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Text("Hizmet Satışları", style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold)),
                        ),
                        ElevatedButton(onPressed: (){
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => HizmetSatisiAdisyon()),
                          );
                        }, child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(Icons.add,color: Colors.white,),
                            Text('Ekle')
                          ],
                        ),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent, shadowColor: Colors.transparent
                          ),
                        )
                      ],
                    )),


            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Dismissible(key: UniqueKey(),
                direction: DismissDirection.endToStart,
                confirmDismiss: (DismissDirection direction) async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Silmek istediğinizden emin misiniz?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Hayır'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Evet'),
                          )
                        ],
                      );
                    },
                  );

                  return confirmed;
                },
                background: const ColoredBox(
                  color: Colors.red,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Icon(Icons.delete, color: Colors.white),
                    ),
                  ),
                ),
                child:Column(
                  children: [
                    ListTile(
                      title: Text('Muayene'),
                      subtitle: Text('Süre: 60 dk'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Fiyat: ',style: TextStyle(fontWeight: FontWeight.bold,fontSize: 16),),
                          Text('1800₺',style: TextStyle(fontWeight: FontWeight.bold,fontSize: 16),),
                        ],
                      ),
                      tileColor: Colors.grey[200],
                    ),

                  ],
                )
                
              ), 
            ),
          ],
        ),



        Column(
          children: [
            Container(width:350,
                height: 35,
                color: Colors.purple[800],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [

                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text("Ürün Satışları", style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold)),
                    ),
                    ElevatedButton(onPressed: (){
                        Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => UrunSatisiAdisyon()),
                      );
                    }, child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(Icons.add,color: Colors.white,),
                        Text('Ekle')
                      ],
                    ),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent, shadowColor: Colors.transparent
                      ),
                    )
                  ],
                )),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Dismissible(key: UniqueKey(),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (DismissDirection direction) async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('Silmek istediğinizden emin misiniz?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Hayır'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Evet'),
                            )
                          ],
                        );
                      },
                    );

                    return confirmed;
                  },
                  background: const ColoredBox(
                    color: Colors.red,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Icon(Icons.delete, color: Colors.white),
                      ),
                    ),
                  ),
                  child:Column(
                    children: [
                      ListTile(
                        title: Text('Diş Macunu'),
                        subtitle: Text('Adet : 1'),
                        trailing:  Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Fiyat: ',style: TextStyle(fontWeight: FontWeight.bold,fontSize: 16),),
                            Text('180₺',style: TextStyle(fontWeight: FontWeight.bold,fontSize: 16),),
                          ],
                        ),
                        tileColor: Colors.grey[200],
                      ),
                    ],
                  )

              ),
            ),

          ],
        ),
        Column(
          children: [
            Container(width:350,
                height: 35,
                color: Colors.purple[800],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [

                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text("Paket Satışları", style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold)),
                    ),
                    ElevatedButton(onPressed: (){
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => PaketSatisiAdisyon()),
                      );
                    }, child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(Icons.add,color: Colors.white,),
                        Text('Ekle')
                      ],
                    ),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent, shadowColor: Colors.transparent
                      ),
                    )
                  ],
                )),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Dismissible(key: UniqueKey(),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (DismissDirection direction) async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('Silmek istediğinizden emin misiniz?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Hayır'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Evet'),
                            )
                          ],
                        );
                      },
                    );

                    return confirmed;
                  },
                  background: const ColoredBox(
                    color: Colors.red,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Icon(Icons.delete, color: Colors.white),
                      ),
                    ),
                  ),
                  child:Column(
                    children: [
                      ListTile(
                        title: Column(

                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 10,),
                            Text('Muayenede indirim'),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton(onPressed: (){}, child: Row(
                                  children: [
                                    Text('5',style: TextStyle(color: Colors.black),),
                                    Icon(Icons.calendar_month,size: 15,color: Colors.black,)
                                  ],
                                ),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor:Colors.yellow[600],
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
                                      minimumSize: Size(55, 25)
                                  ),
                                ),
                                ElevatedButton(onPressed: (){}, child: Row(
                                  children: [
                                    Text('0',style: TextStyle(color: Colors.white),),
                                    Icon(Icons.check_sharp,size: 15,color: Colors.white,)
                                  ],
                                ),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor:Colors.green,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
                                      minimumSize: Size(55, 25)
                                  ),
                                ),
                                ElevatedButton(onPressed: (){}, child: Row(
                                  children: [
                                    Text('0',style: TextStyle(color: Colors.white),),
                                    Icon(Icons.clear,size: 15,color: Colors.white,)
                                  ],
                                ),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor:Colors.red[600],
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
                                      minimumSize: Size(55, 25)
                                  ),
                                )
                              ],
                            )
                          ],
                        ),
                        trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Fiyat: ',style: TextStyle(fontWeight: FontWeight.bold,fontSize: 16),),
                            Text('1800₺',style: TextStyle(fontWeight: FontWeight.bold,fontSize: 16),),
                          ],
                        ),
                        tileColor: Colors.grey[200],
                      ),
                    ],
                  )

              ),
            ),

          ],
        )




      ],
    );
  }
  void setValidator(valid){
    setState(() {
      isANumber = valid;
    });
  }
}
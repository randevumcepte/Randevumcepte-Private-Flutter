import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:page_transition/page_transition.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';

import '../dashboard/hizmetsatisi.dart';
import '../dashboard/paketsatisi.dart';
import '../dashboard/urunsatisi.dart';

class YeniAdisyon extends StatefulWidget {
  YeniAdisyon({Key? key}) : super(key: key);
  @override
  _YeniAdisyonState createState() => _YeniAdisyonState();
}

class _YeniAdisyonState extends State<YeniAdisyon> {
  TextEditingController dateInput = TextEditingController();
  final List<String> items = [
    'Cevriye',
    'Beyzanur Sarılı',
    'Anıl Orbey',
    'Çağlar Filiz',
    'Ferdi Korkmaz',
    'Elif Çetin',

  ];
  String? selectedValue;
  final TextEditingController textEditingController = TextEditingController();
  void _showAlert() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Bildiri'),
          content: Text('Silmek istediğiniz hizmeti sola kaydırabilirsiniz'),
          actions: <Widget>[
            TextButton(
              child: Text('Kapat'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
  void _deleteData() {
    // Implement the logic to delete data here
    setState(() {

      _dataAdded = false; // Set dataAdded to false
      // Reset the container height
    });
  }
  void _deleteDataurun() {
    // Implement the logic to delete data here
    setState(() {

      _dataAddedurun = false; // Set dataAdded to false
      // Reset the container height
    });
  }
  void _deleteDatapaket() {
    // Implement the logic to delete data here
    setState(() {

      _dataAddedpaket = false; // Set dataAdded to false
      // Reset the container height
    });
  }
  //hizmet icin

  String selectedDropdownValue = ''; // Store the selected dropdown value
  String selectedDropdownValue2 = ''; // Store the selected dropdown value
  TextEditingController tarih = TextEditingController();
  TextEditingController saat = TextEditingController();
  TextEditingController sure = TextEditingController();
  TextEditingController fiyat = TextEditingController();
  bool _dataAdded = false;
  double _containerHeight = 0.0;

  //urun icin
  String selectedDropdownUrun = ''; // Store the selected dropdown value
  String selectedDropdownSatici = ''; // Store the selected dropdown value
  TextEditingController urunAdet = TextEditingController();
  TextEditingController urunFiyat = TextEditingController();
  bool _dataAddedurun = false;
  double _containerHeighturun = 0.0;

//paket icin
  String selectedDropdownPaket = ''; // Store the selected dropdown value
  String selectedDropdownPaketSatici = ''; // Store the selected dropdown value
  TextEditingController baslangictarih = TextEditingController();
  TextEditingController seans = TextEditingController();
  TextEditingController paketfiyat = TextEditingController();
  bool _dataAddedpaket = false;
  double _containerHeightpaket = 0.0;


  //hizmetsatisi
  void hizmetsatisi() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HizmetSatisi(musteriid: "",senetlisatis: false,isletmebilgi: null,)),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        tarih.text=result['text']; // Add entered text to the list
        saat.text=result['text2']; // Add entered text to the list
        sure.text=result['text3']; // Add entered text to the list
        fiyat.text=result['text4']; // Add entered text to the list
        selectedDropdownValue = result['dropdownValue']; // Update dropdown value
        selectedDropdownValue2 = result['dropdownValue2'];
        _dataAdded = true;// Update dropdown value
        _containerHeight = 30.0; // Increase the container height

      });
    }
  }

  //urunsatisi
  void urunsatisi() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UrunSatisi(musteriid: "",senetlisatis: false,isletmebilgi: null)),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        urunAdet.text=result['text']; // Add entered text to the list
        urunFiyat.text=result['text2']; // Add entered text to the list
        selectedDropdownUrun = result['dropdownValue']; // Update dropdown value
        selectedDropdownSatici = result['dropdownValue2'];
        _dataAddedurun = true;// Update dropdown value
        _containerHeighturun = 30.0; // Increase the container height

      });
    }
  }

  //paketsatisi
  void paketsatisi() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PaketSatisi(musteriid: "",senetlisatis: false,isletmebilgi: null)),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        baslangictarih.text=result['text']; // Add entered text to the list
        paketfiyat.text=result['text2']; // Add entered text to the list
        seans.text=result['text3']; // Add entered text to the list
        selectedDropdownPaketSatici = result['dropdownValue']; // Update dropdown value
        selectedDropdownPaket = result['dropdownValue2'];
        _dataAddedpaket = true;// Update dropdown value
        _containerHeightpaket = 30.0; // Increase the container height

      });
    }
  }
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title:  const Text('Yeni Adisyon',style: TextStyle(color: Colors.black),),

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
              child: Text('Adisyon Tarihi',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
            ),
            SizedBox(height: 10,),
            Container(
              height: 40,
              padding: EdgeInsets.only(left:20,right: 20),
              child: TextField(
                controller: dateInput,
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
            SizedBox(height: 10,),
            Padding(
              padding: const EdgeInsets.only(left: 20.0),
              child: Text('Müşteri',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
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
                      'Müşteri Seç',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                    items: items
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
                    value: selectedValue,
                    onChanged: (value) {
                      setState(() {
                        selectedValue = value;
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
                      searchController: textEditingController,
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
                          controller: textEditingController,
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            hintText: 'Müşteri Ara..',
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
                        textEditingController.clear();
                      }
                    },

                  )),
            ),
            SizedBox(height: 10,),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(onPressed: hizmetsatisi,
                  child: Text('Hizmet Satışı'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,

                  ),
                ), ElevatedButton(onPressed: urunsatisi,
                  child: Text('Ürün Satışı'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: Size(110, 36)

                  ),
                ), ElevatedButton(onPressed: paketsatisi,
                  child: Text('Paket Satışı'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,

                  ),
                )
              ],
            ),
            SizedBox(height: 10,),
            Container(
              margin: EdgeInsets.only(left: 10,right: 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Container(

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Eklenen Hizmetler',style: TextStyle(fontWeight: FontWeight.bold,fontSize: 16),),

                          Visibility(
                            visible: _dataAdded,
                            child: IconButton(
                              icon: Icon(Icons.delete,size: 23,color: Colors.red[600],),
                              onPressed: () {
                                _deleteData();
                                _showAlert(); // Show alert when pressed
                              },
                            ),)
                        ],
                      ),
                      Padding(
                        padding:   EdgeInsets.only(top: 0.0),
                        child: Dismissible(
                          key: UniqueKey(),
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
                                padding: EdgeInsets.all(0.0),
                                child: Icon(Icons.delete, color: Colors.white,size: 20,),
                              ),
                            ),
                          ),
                          child: Container(
                            height: _containerHeight,
                            width: double.infinity,
                            color: _dataAdded ? Colors.grey[200] : null,
                            child: Row(
                              children: [
                                Text('${tarih.text}',style: TextStyle(fontSize: 12),),
                                Text(' ${saat.text}',style: TextStyle(fontSize: 12),),
                                Text(
                                  ' $selectedDropdownValue',
                                  style: TextStyle(fontSize: 12.0),
                                ),Text(
                                  ' $selectedDropdownValue2',
                                  style: TextStyle(fontSize: 12.0),
                                ),
                                Row(
                                  children: [
                                    Text(' ${sure.text}',style: TextStyle(fontSize: 12),),
                                    if(_dataAdded)
                                      Text('dk',style: TextStyle(fontSize: 12),)
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text(' ${fiyat.text}',style: TextStyle(fontSize: 12),),
                                    if(_dataAdded)
                                      Text('₺',style: TextStyle(fontSize: 12),)
                                  ],
                                ),

                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 5,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Eklenen Ürünler',style: TextStyle(fontWeight: FontWeight.bold,fontSize: 16),),

                          Visibility(
                            visible: _dataAddedurun,
                            child: IconButton(
                              icon: Icon(Icons.delete,size: 23,color: Colors.red[600],),
                              onPressed: () {
                                _deleteDataurun();
                                _showAlert(); // Show alert when pressed
                              },
                            ),)
                        ],
                      ),
                      Padding(
                        padding:   EdgeInsets.only(top: 0.0),
                        child: Dismissible(
                          key: UniqueKey(),
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
                                padding: EdgeInsets.all(0.0),
                                child: Icon(Icons.delete, color: Colors.white,size: 20,),
                              ),
                            ),
                          ),
                          child: Container(
                            height: _containerHeighturun,
                            width: double.infinity,
                            color: _dataAddedurun ? Colors.grey[200] : null,
                            child: Row(
                              children: [

                                Text(
                                  ' $selectedDropdownUrun',
                                  style: TextStyle(fontSize: 12.0),
                                ),Text(
                                  ' $selectedDropdownSatici',
                                  style: TextStyle(fontSize: 12.0),
                                ),
                                Row(
                                  children: [
                                    Text(' ${urunAdet.text}',style: TextStyle(fontSize: 12),),
                                    if(_dataAddedurun)
                                      Text(' adet',style: TextStyle(fontSize: 12),)
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text(' ${urunFiyat.text}',style: TextStyle(fontSize: 12),),
                                    if(_dataAddedurun)
                                      Text('₺',style: TextStyle(fontSize: 12),)
                                  ],
                                ),

                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 5,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Eklenen Paketler',style: TextStyle(fontWeight: FontWeight.bold,fontSize: 16),),Visibility(
                            visible: _dataAddedpaket,
                            child: IconButton(
                              icon: Icon(Icons.delete,size: 23,color: Colors.red[600],),
                              onPressed: () {
                                _deleteDatapaket();
                                _showAlert(); // Show alert when pressed
                              },
                            ),)
                        ],
                      ),
                      Padding(
                        padding:   EdgeInsets.only(top: 4.0),
                        child: Dismissible(
                          key: UniqueKey(),
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
                                padding: EdgeInsets.all(0.0),
                                child: Icon(Icons.delete, color: Colors.white,size: 20,),
                              ),
                            ),
                          ),
                          child: Container(
                            height: _containerHeightpaket,
                            width: double.infinity,
                            color: _dataAddedpaket ? Colors.grey[200] : null,
                            child: Row(
                              children: [

                                Text(
                                  '$selectedDropdownPaket',
                                  style: TextStyle(fontSize: 12.0),
                                ),Text(
                                  ' $selectedDropdownPaketSatici',
                                  style: TextStyle(fontSize: 12.0),
                                ),
                                Text(' ${baslangictarih.text}',style: TextStyle(fontSize: 12),),
                                Row(
                                  children: [
                                    Text(' ${seans.text}',style: TextStyle(fontSize: 12),),
                                    if(_dataAddedpaket)
                                      Text(' günde bir',style: TextStyle(fontSize: 12),)
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text(' ${paketfiyat.text}',style: TextStyle(fontSize: 12),),
                                    if(_dataAddedpaket)
                                      Text('₺',style: TextStyle(fontSize: 12),)
                                  ],
                                ),

                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 10,),
            Padding(
              padding: const EdgeInsets.only(left: 20.0),
              child: Text('Notlar',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
            ),
            SizedBox(height: 10,),
            Container(
              height: 40,
              padding: EdgeInsets.only(left:20,right: 20),
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
            SizedBox(height: 20,),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(onPressed: (){},
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
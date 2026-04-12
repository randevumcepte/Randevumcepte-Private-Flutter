import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:page_transition/page_transition.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';

import '../../../Frontend/altyuvarlakmenu.dart';
import '../../dashboard/hizmetsatisi.dart';
import '../../dashboard/paketsatisi.dart';
import '../../dashboard/urunsatisi.dart';
import '../alacaklar.dart';

class VarolanTahsilat extends StatefulWidget {
  final dynamic isletmebilgi;
  VarolanTahsilat({Key? key,required this.isletmebilgi}) : super(key: key);
  @override
  _VarolanTahsilatState createState() => _VarolanTahsilatState();
}

class _VarolanTahsilatState extends State<VarolanTahsilat> {

  final List<String> odemeyontem = [
    'Nakit',
    'Kredi KArtı',
    'Havale / EFT',
    'Online Ödeme',
    'Senet',

  ];

  String? selectedodemeyontemi;
  TextEditingController odemeyontemcontroller = TextEditingController();


  TextEditingController dateInput = TextEditingController();
  TextEditingController dateInput2 = TextEditingController();
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
      _containerHeight = 10.0; // Reset the container height
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
      MaterialPageRoute(builder: (context) => HizmetSatisi( kullanicirolu: 0, musteriid: "",senetlisatis: false,isletmebilgi: null,)),
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
      MaterialPageRoute(builder: (context) => UrunSatisi(kullanicirolu: 0, musteriid: "",senetlisatis: false,isletmebilgi: null)),
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
      MaterialPageRoute(builder: (context) => PaketSatisi(kullanicirolu: 0, musteriid: "",senetlisatis: false,isletmebilgi: null)),
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
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      // floatingActionButton: AltYuvarlakYeniEkleMenu(isletme_bilgi: widget.isletmebilgi,),

      appBar: AppBar(
        title:  const Text('Tahsilatlar',style: TextStyle(color: Colors.black),),

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

            Container(

              padding: EdgeInsets.all(10.0),
              margin: EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.white, // Set container background color
                border: Border.all(
                  color: Color(0XFFE0E0E0),
                  width: 1.2,
                ),
                borderRadius: BorderRadius.circular(20.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.15),
                    spreadRadius: 5,
                    blurRadius: 7,
                    offset: Offset(0,3), // changes position of shadow
                  ),
                ],

              ),

              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,

                children:[

                  Text('Cevriye Güleç', style: TextStyle(color: Colors.black,fontSize: 18,fontWeight: FontWeight.bold),),
                  Container( padding: EdgeInsets.only(left: 20),
                    child: ElevatedButton(
                      onPressed: (){},
                      child:
                      Text('Aktif',style: TextStyle(fontSize: 15),),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,

                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0)
                          ),
                          minimumSize: Size(80, 30)
                      ),
                    ),),






                ],

              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                SizedBox(width: 10,),
                ElevatedButton(onPressed: hizmetsatisi,
                  child: Text('Hizmet Ekle',style: TextStyle(fontSize: 12),),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF9C27B0),
                    minimumSize: Size(90, 30),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),

                  ),
                ),
                SizedBox(width: 5,),
                ElevatedButton(onPressed: urunsatisi,
                  child: Text('Ürün Ekle',style:TextStyle(fontSize:12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFEA80FC),
                    minimumSize: Size(95, 30),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),

                  ),
                ),
                SizedBox(width: 5,),
                ElevatedButton(onPressed: paketsatisi,
                  child: Text('Paket Ekle',style:TextStyle(fontSize:12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:  Color(0xFF1976D2),
                    minimumSize: Size(95, 30),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),


                  ),
                ),
                SizedBox(width: 15,),


              ],
            ),
            SizedBox(height: 5,),
            Container(
              margin: EdgeInsets.only(left: 10,right: 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Container(

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

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
                            color: _dataAdded ? Colors.blue[50] : null,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [

                                Text(
                                  ' $selectedDropdownValue2',
                                  style: TextStyle(fontSize: 12.0),
                                ),
                                Text(
                                  ' $selectedDropdownValue',
                                  style: TextStyle(fontSize: 12.0),
                                ),

                                Text(' 1 adet',style: TextStyle(fontSize: 12),),

                                Row(
                                  children: [
                                    Text(' ${fiyat.text}',style: TextStyle(fontSize: 12),),
                                    if(_dataAdded)
                                      Text('₺',style: TextStyle(fontSize: 12),)
                                  ],
                                ),
                                if(_dataAdded)
                                  Icon(Icons.close_outlined,color: Colors.red[600],size: 18,)


                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 5,),

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
                            height: _containerHeighturun,
                            width: double.infinity,
                            color: _dataAddedurun ? Colors.blue[50] : null,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [

                                Text(
                                  ' $selectedDropdownUrun',
                                  style: TextStyle(fontSize: 12.0),
                                ),Text(
                                  ' $selectedDropdownSatici',
                                  style: TextStyle(fontSize: 12.0),
                                ),

                                Text(' 1 adet',style: TextStyle(fontSize: 12),),

                                Row(
                                  children: [
                                    Text(' ${urunFiyat.text}',style: TextStyle(fontSize: 12),),
                                    if(_dataAddedurun)
                                      Text('₺',style: TextStyle(fontSize: 12),)
                                  ],
                                ),
                                if(_dataAddedurun)
                                  Icon(Icons.close_outlined,color: Colors.red[600],size: 18,)


                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 5,),

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
                            color: _dataAddedpaket ? Colors.blue[50] : null,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [

                                Text(
                                  '$selectedDropdownPaket',
                                  style: TextStyle(fontSize: 12.0),
                                ),Text(
                                  ' $selectedDropdownPaketSatici',
                                  style: TextStyle(fontSize: 12.0),
                                ),

                                Text(' 1 adet',style: TextStyle(fontSize: 12),),

                                Row(
                                  children: [
                                    Text(' ${paketfiyat.text}',style: TextStyle(fontSize: 12),),
                                    if(_dataAddedpaket)
                                      Text('₺',style: TextStyle(fontSize: 12),)
                                  ],
                                ),
                                if(_dataAddedpaket)
                                  Icon(Icons.close_outlined,color: Colors.red[600],size: 18,)


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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Container(
                        padding: const EdgeInsets.only(left: 20.0),
                        child: Text('Tarih',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
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
                            contentPadding:  EdgeInsets.all(0.0),
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
                      Container(
                        padding: const EdgeInsets.only(left: 20.0),
                        child: Text('Birim Tutar(₺)',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                      ),
                      SizedBox(height: 10,),
                      Container(
                        height: 40,

                        padding: EdgeInsets.only(left:20,right: 20),
                        child: TextField(

                          keyboardType: TextInputType.phone,



                          decoration: InputDecoration(

                            focusColor:Color(0xFF6A1B9A) ,

                            hoverColor: Color(0xFF6A1B9A) ,
                            filled: true,
                            fillColor: Colors.white,
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
                      Container(

                        padding: const EdgeInsets.only(left: 20.0),
                        child: Text('İndirim (₺)',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                      ),
                      SizedBox(height: 10,),
                      Container(
                        height:40,
                        padding: EdgeInsets.only(left:20,right: 20),
                        child: TextField(

                          keyboardType: TextInputType.phone,



                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
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
                      Container(

                        padding: const EdgeInsets.only(left: 20.0),
                        child: Text('Müşteri İndirimi (₺)',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                      ),
                      SizedBox(height: 10,),
                      Container(
                        height:40,
                        padding: EdgeInsets.only(left:20,right: 20),
                        child: TextField(

                          keyboardType: TextInputType.phone,



                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
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




                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                              items: odemeyontem
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
                                setState(() {
                                  selectedodemeyontemi = value;
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
                                searchController: odemeyontemcontroller,
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
                                    controller: odemeyontemcontroller,
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
                                  odemeyontemcontroller.clear();
                                }
                              },

                            )),
                      ),

                      SizedBox(height: 10,),
                      Container(
                        padding: const EdgeInsets.only(left: 20.0),
                        child: Text('Ödenecek Tutar(₺)',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                      ),
                      SizedBox(height: 10,),
                      Container(
                        height: 40,
                        padding: EdgeInsets.only(left:20,right: 20),
                        child: TextField(

                          keyboardType: TextInputType.phone,



                          decoration: InputDecoration(
                            filled: true,
                            focusColor:Color(0xFF6A1B9A) ,
                            fillColor: Colors.white,
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
                      Container(
                        padding: const EdgeInsets.only(left: 20.0),
                        child: Text('Alacak Tutarı(₺)',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                      ),
                      SizedBox(height: 10,),
                      Container(
                        height: 40,
                        padding: EdgeInsets.only(left:20,right: 20),
                        child: TextField(

                          keyboardType: TextInputType.phone,



                          decoration: InputDecoration(
                            filled: true,

                            focusColor:Color(0xFF6A1B9A) ,
                            fillColor: Colors.white,
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
                      Container(
                        padding: const EdgeInsets.only(left: 20.0),
                        child: Text('Ödenecek Tutar(₺)',style: TextStyle(fontSize: 16,color: Colors.white,fontWeight: FontWeight.bold),),
                      ),
                      SizedBox(height: 15,),
                      Container(
                        width: 150,
                        child: ElevatedButton(onPressed: (){},
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cases_outlined
                              ),
                              Text(' Tahsil Et'),
                            ],
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            minimumSize: Size(0, 30),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
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
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(onPressed: (){
                  Navigator.push(context, PageTransition(type: PageTransitionType.rightToLeft,duration: Duration(milliseconds:500), child: AlacaklarScreen()));
                },
                  child: Text('Alacaklar',style: TextStyle(color:Colors.white),),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow[800],
                    minimumSize: Size(100, 30),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                  ),
                ),
                ElevatedButton(onPressed: (){},
                  child: Text('Taksit Yap'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple[800],
                    minimumSize: Size(90, 30),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                  ),
                ),

              ],
            ),




          ],
        ),
      ),
    );
  }

}


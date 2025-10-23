import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class YeniSenet extends StatefulWidget {
  const YeniSenet({Key? key}) : super(key: key);

  @override
  _YeniSenetState createState() => _YeniSenetState();
}

class _YeniSenetState extends State<YeniSenet> {


  TextEditingController dateInput = TextEditingController();
  final List<String> senetmusteri = [
    'Cevriye',
    'Beyzanur Sarılı',
    'Anıl Orbey',
    'Çağlar Filiz',
    'Ferdi Korkmaz',
    'Elif Çetin',

  ];
  String? selectedsenetmusteri;
  final TextEditingController senetmustericontroller = TextEditingController();
  final List<String> senetturu = [
    'Nakit',
    'Kredi Kartı',
    'Havale / EFT',
    'Online Ödeme',
    'Senet',


  ];
  String? selectedsenetturu;
  final TextEditingController senetturucontroller = TextEditingController();
  TextEditingController vadetarih = TextEditingController();


  @override
  void initState() {
    vadetarih.text = ""; //set the initial value of text field
    super.initState();
  }
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  AutovalidateMode _autoValidate = AutovalidateMode.disabled;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: Icon(Icons.close_outlined, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text('Yeni Senets',style: TextStyle(color: Colors.black,fontSize: 20),),
          toolbarHeight: 60,

          centerTitle: true,
        ),
        body: SingleChildScrollView(
          reverse: true,
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
          child: Text('Müşteri',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
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

              child: DropdownButton2<String>(

                isExpanded: true,
                hint: Text(
                  'Seç',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).hintColor,
                  ),
                ),
                items: senetmusteri
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
                value: selectedsenetmusteri,
                onChanged: (value) {
                  setState(() {
                    selectedsenetmusteri = value;
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
                  searchController: senetmustericontroller,
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
                      controller: senetmustericontroller,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        hintText: 'Ara..',
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
                    senetmustericontroller.clear();
                  }
                },

              )),
        ),
        SizedBox(height: 10,),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 5.0),
                    child: Text('Vade Başlangıç Tarihi',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                  ),
                  SizedBox(height: 10,),
                  Container(
                    height: 40,

                    child: TextField(

                      controller: vadetarih,
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
                            vadetarih.text =
                                formattedDate; //set output date to TextField value.
                          });
                        } else {}
                      },
                    ),

                  ),
                ],
              ),
            ),
            SizedBox(width: 5,),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 5.0),
                    child: Text('Vade (Ay)',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
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
                ],
              ),
            ),

          ],
        ),
        SizedBox(height: 10,),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Padding(
                    padding: const EdgeInsets.only(left: 5.0),
                    child: Text('Tutar (₺)',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
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
                ],
              ),
            ),
            SizedBox(width: 5,),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 5.0),
                    child: Text('Senet Türü',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                  ),
                  SizedBox(height: 10,),
                  Container(
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
                          items: senetturu
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
                          value: selectedsenetturu,
                          onChanged: (value) {
                            setState(() {
                              selectedsenetturu = value;
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
                            searchController: senetturucontroller,
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
                                controller: senetturucontroller,
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  hintText: 'Ara..',
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
                              senetturucontroller.clear();
                            }
                          },

                        )),
                  ),
                ],
              ),
            )
          ],
        ),
        SizedBox(height: 10,),
        Padding(
          padding: const EdgeInsets.only(left: 5.0),
          child: Text('T.C NO',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
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
        SizedBox(height: 10,),
        Padding(
          padding: const EdgeInsets.only(left: 5.0),
          child: Text('Adres',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
        ),
        SizedBox(height: 10,),
        Container(


          child: TextField(

            keyboardType: TextInputType.text,

            maxLines: 2,
            decoration: InputDecoration(
              enabled:true,
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
          child: Text('Kefil Adı ve Soyadı',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
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
        SizedBox(height: 10,),
        Padding(
          padding: const EdgeInsets.only(left: 5.0),
          child: Text('Kefil T.C NO',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
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
        SizedBox(height: 10,),
        Padding(
          padding: const EdgeInsets.only(left: 5.0),
          child: Text('Kefil Adres',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
        ),
        SizedBox(height: 10,),
        Container(


          child: TextField(

            keyboardType: TextInputType.text,

            maxLines: 2,
            decoration: InputDecoration(
              enabled:true,
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
        const SizedBox(
          height: 20.0,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(onPressed: (){},
              child: Text('Kaydet'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: Size(90, 40)
              ),
            ),
          ],
        ),
        Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom))

      ],
    );
  }



}
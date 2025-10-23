import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:randevu_sistem/yeni/urun.dart';



class YeniUrunSatis2 extends StatefulWidget {
  const YeniUrunSatis2({Key? key}) : super(key: key);

  @override
  _YeniUrunSatis2State createState() => _YeniUrunSatis2State();
}

class _YeniUrunSatis2State extends State<YeniUrunSatis2> {
  final List<String> _numbers = ["1","2","3","4","5","6","7","8","9","10","15","20","25","50","75","100","150","200",
    "300","400","500","750","1000","1500","2000","2500","5000"];
  String? _selectedNumber;

  final List<String> _odeme=["Nakit","Kredi Kartı","Havale","Diğer"];
  String? _selectedOdeme;

  final List<String> _satici=["Anıl Orbey","Cevriye Efe","Çağlar Filiz"];
  String? _selectedSatici;


  TextEditingController dateInput = TextEditingController();

  @override
  void initState() {
    dateInput.text = ""; //set the initial value of text field
    super.initState();
  }
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  AutovalidateMode _autoValidate = AutovalidateMode.disabled;
  String? _name;
  String? _mobile;
  String? _email;
  String? _tutar;
  String? _cins;
  String? _not;
  void _validateInputs() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
    } else {
      setState(() {
        _autoValidate = AutovalidateMode.always;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Text("Yeni Ürün Satışı",style: TextStyle(color: Colors.black)),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
          backgroundColor: Colors.white,
          toolbarHeight: 70,

        ),


        body: SingleChildScrollView(
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
      children: <Widget>[

        ListTile(
          contentPadding: const EdgeInsets.fromLTRB(5, 0, 5, 5),
          leading: const Icon(Icons.production_quantity_limits),

          title: Text('Ürün Seçiniz'),
          trailing: Icon(Icons.keyboard_arrow_right),
          onTap: () {

            showDialog<Widget>(
              context: context,
              barrierDismissible: true,
              builder: (BuildContext context) {
                return UrunList();
              },
            ).then((dynamic value) => setState(() {}));
          },
        ),

        const Divider(
          height: 2.0,
          thickness: 1,
        ),
        DropdownButton<String>(
          value: _selectedNumber,
          onChanged: (value) {
            setState(() {
              _selectedNumber = value;
            });
          },
          hint: const Center(
              child: Text(
                'Adet Giriniz',
                style: TextStyle(color: Colors.deepPurple),
              )),
          // Hide the default underline
          underline: Container(),
          // set the color of the dropdown menu
          isExpanded: true,

          // The list of options
          items: _numbers
              .map((e) => DropdownMenuItem(
            value: e,
            child: Container(
              alignment: Alignment.centerLeft,
              child: Text(
                e,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ))
              .toList(),

          // Customize the selected item
          selectedItemBuilder: (BuildContext context) => _numbers
              .map((e) => Center(
            child: Text(
              e,
              style: const TextStyle(
                fontSize: 18,
              ),
            ),
          ))
              .toList(),
        ),

        DropdownButton<String>(
          value: _selectedOdeme,
          onChanged: (value) {
            setState(() {
              _selectedOdeme = value;
            });
          },
          hint: const Center(
              child: Text(
                'Ödeme Şeklini Giriniz',
                style: TextStyle(color: Colors.deepPurple),
              )),
          // Hide the default underline
          underline: Container(),
          // set the color of the dropdown menu
          isExpanded: true,

          // The list of options
          items: _odeme
              .map((e) => DropdownMenuItem(
            value: e,
            child: Container(
              alignment: Alignment.centerLeft,
              child: Text(
                e,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ))
              .toList(),

          // Customize the selected item
          selectedItemBuilder: (BuildContext context) => _odeme
              .map((e) => Center(
            child: Text(
              e,
              style: const TextStyle(
                fontSize: 18,),
            ),
          ))
              .toList(),
        ),
        DropdownButton<String>(
          value: _selectedSatici,
          onChanged: (value) {
            setState(() {
              _selectedSatici = value;
            });
          },
          hint: const Center(
              child: Text(
                'Satıcıyı Giriniz',
                style: TextStyle(color: Colors.deepPurple),
              )),
          // Hide the default underline
          underline: Container(),
          // set the color of the dropdown menu

          isExpanded: true,

          // The list of options
          items: _satici
              .map((e) => DropdownMenuItem(
            value: e,
            child: Container(
              alignment: Alignment.centerLeft,
              child: Text(
                e,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ))
              .toList(),

          // Customize the selected item
          selectedItemBuilder: (BuildContext context) =>_satici
              .map((e) => Center(
            child: Text(
              e,
              style: const TextStyle(
                fontSize: 18,
              ),
            ),
          ))
              .toList(),
        ),
        const Divider(
          height: 2.0,
          thickness: 1,
        ),
        TextFormField(
          decoration: const InputDecoration(icon: Icon(Icons.attach_money),labelText: 'Toplam Fiyat Giriniz'),
          keyboardType: TextInputType.text,
          validator: validateName,
          onSaved: (String? val) {
            _tutar = val;
          },
        ),
        Container(
          height: MediaQuery.of(context).size.width / 3,
          child: Center(
            child: TextField(
              controller: dateInput,
              //editing controller of this TextField
              decoration: InputDecoration(
                  icon: Icon(Icons.calendar_today), //icon of text field
                  labelText: "Tarih Giriniz" //label text of field
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
          ),),
        TextFormField(
          decoration: const InputDecoration(labelText: 'Notlar'),
          keyboardType: TextInputType.text,
          onSaved: (String? val) {
            _not = val;
          },
        ),

        const SizedBox(
          height: 10.0,
        ),
        OutlinedButton(
          onPressed: _validateInputs,
          child: const Text('Kaydet'),
        )
      ],
    );
  }
  String? validateName(String? value) {
    if (value!.isEmpty) {
      return 'Tutar Girilmedi';
    }
    else {
      return null;
    }
  }


}
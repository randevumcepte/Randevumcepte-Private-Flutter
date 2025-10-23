import 'package:flutter/material.dart';
import 'package:intl/intl.dart';




class YeniMasraf extends StatefulWidget {
  const YeniMasraf({Key? key}) : super(key: key);

  @override
  _YeniMasrafState createState() => _YeniMasrafState();
}

class _YeniMasrafState extends State<YeniMasraf> {
  final List<String> _kategori = ["Kategori Seçiniz","Aidat","Demirbaş","Diğer","Doğalgaz","Elektrik","Firma Ödemeleri","İnternet","Kargo","Kira",
  "Malzeme Ödemeleri","Muhasebe","Mutfak","Personel Ödemeleri","Su","Telefon","Temizlik"];
  String? _selectedKategori;

  final List<String> _odeme=["Ödeme Şekli","Nakit","Kredi Kartı","Havale","Diğer"];
  String? _selectedOdeme;

  final List<String> _satici=["Harcayan","Anıl Orbey","Cevriye Efe","Çağlar Filiz"];
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
  String? _aciklama;
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

        DropdownButton<String>(
          value: _selectedKategori,
          onChanged: (value) {
            setState(() {
              _selectedKategori = value;
            });
          },
          hint: const Center(
              child: Text(
                'Kategori Seçiniz',
                style: TextStyle(color: Colors.deepPurple),
              )),
          // Hide the default underline
          underline: Container(),
          // set the color of the dropdown menu
          isExpanded: true,

          // The list of options
          items: _kategori
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
          selectedItemBuilder: (BuildContext context) => _kategori
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
          decoration: const InputDecoration(labelText: 'Açıklama Giriniz'),
          keyboardType: TextInputType.text,
          onSaved: (String? val) {
            _aciklama = val;
          },
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
                'Harcayan Seçiniz',
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
          decoration: const InputDecoration(icon: Icon(Icons.attach_money),labelText: 'Tutarı Giriniz'),
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
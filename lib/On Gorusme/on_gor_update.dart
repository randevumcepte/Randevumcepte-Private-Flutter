
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';

import '../yonetici/randevular/musteri.dart';
/*
class GorusmeGuncelle extends StatefulWidget {
  const GorusmeGuncelle({Key? key}) : super(key: key);

  @override
  _GorusmeGuncelleState createState() => _GorusmeGuncelleState();
}

class _GorusmeGuncelleState extends State<GorusmeGuncelle> {
  TextEditingController dateInput = TextEditingController();


  final List<String> _tip = ["Müşteri Tipi","İnternet","Referans"];
  String? _selectedTip;



  final List<String> _hatirlatma = ["Kaç Gün Sonra Hatılratılsın","(1) gün sonra hatırlatırsın","(5) gün sonra hatırlatırsın","(10) gün sonra hatırlatırsın","(20) gün sonra hatırlatırsın"
      "(40) gün sonra hatırlatırsın","(80) gün sonra hatırlatırsın","(120) gün sonra hatırlatırsın"];
  String? _selectedHatirlatma;

  final List<String> _meslek = ["Meslek Seç","Akademisyen","Doktor",",öğretmen","Mühendis","Tercüman"];
  String? _selectedMeslek;

  final List<String> _gorusme = ["Görüşmeyi Yapan","Anıl Orbey","Cevriye Efe"];
  String? _selectedGorusme;

  final List<String> _paket = ["Paket","60 dakika medikal masaj"];
  String? _selectedPaket;


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
  String? _b_day;
  String? _cins;
  String? _not;
  String? _adres;
  String? _yonlendiren;
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

          title: const Text('Ön Görüşme Düzenle',style: TextStyle(color: Colors.black),),
          backgroundColor: Colors.white,
          toolbarHeight: 60,

          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.all(9.0),
              child: SizedBox(
                width: 100, // <-- Your width
                child: YukseltButonu()
              ),
            ),

          ],

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
          title: Text('Müşteri Seçiniz'),
          trailing: Icon(Icons.keyboard_arrow_right),
          onTap: () {

            /*showDialog<Widget>(
              context: context,
              barrierDismissible: true,
              builder: (BuildContext context) {
                return Musteri();
              },
            ).then((dynamic value) => setState(() {}));*/
          },
        ),
        TextFormField(
          decoration: const InputDecoration(labelText: 'Email'),
          keyboardType: TextInputType.emailAddress,
          onSaved: (String? val) {
            _email = val;
          },
        ),Container(
          height: MediaQuery.of(context).size.width / 3,
          child: Center(
            child: TextField(
              controller: dateInput,
              //editing controller of this TextField
              decoration: InputDecoration(
                  labelText: "Tarihi" //label text of field
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
          decoration: const InputDecoration(labelText: 'Cinsiyet'),
          keyboardType: TextInputType.text,
          onSaved: (String? val) {
            _cins = val;
          },
        ),
        TextFormField(
          decoration: const InputDecoration(labelText: 'Yönlendiren'),
          keyboardType: TextInputType.text,
          onSaved: (String? val) {
            _yonlendiren = val;
          },
        ),
        const SizedBox(
          height: 15.00,
        ),
        CSCPicker(
          layout: Layout.vertical,
          //flagState: CountryFlag.DISABLE,
          onCountryChanged: (country) {},
          onStateChanged: (state) {},
          onCityChanged: (city) {},
          countryDropdownLabel: "Ülke Seçiniz",
          stateDropdownLabel: "İl Seçiniz",
          cityDropdownLabel: "İlçe Seçiniz",
          dropdownDialogRadius: 30,
          searchBarRadius: 30,
        ),
        DropdownButton<String>(
          value: _selectedTip,
          onChanged: (value) {
            setState(() {
              _selectedTip = value;
            });
          },
          hint: const Center(
              child: Text(
                'Müşteri Tipi',
                style: TextStyle(color: Colors.deepPurple),
              )),
          // Hide the default underline
          underline: Container(),
          // set the color of the dropdown menu
          isExpanded: true,

          // The list of options
          items: _tip
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
          selectedItemBuilder: (BuildContext context) => _tip
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
          value: _selectedPaket,
          onChanged: (value) {
            setState(() {
              _selectedPaket = value;
            });
          },
          hint: const Center(
              child: Text(
                'Paket Seçiniz',
                style: TextStyle(color: Colors.deepPurple),
              )),
          // Hide the default underline
          underline: Container(),
          // set the color of the dropdown menu
          isExpanded: true,

          // The list of options
          items: _paket
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
          selectedItemBuilder: (BuildContext context) => _paket
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
          value: _selectedHatirlatma,
          onChanged: (value) {
            setState(() {
              _selectedHatirlatma = value;
            });
          },
          hint: const Center(
              child: Text(
                'Kaç Gün Sonra Hatırlatılsın',
                style: TextStyle(color: Colors.deepPurple),
              )),
          // Hide the default underline
          underline: Container(),
          // set the color of the dropdown menu
          isExpanded: true,

          // The list of options
          items: _hatirlatma
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
          selectedItemBuilder: (BuildContext context) => _hatirlatma
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
          value: _selectedMeslek,
          onChanged: (value) {
            setState(() {
              _selectedMeslek = value;
            });
          },
          hint: const Center(
              child: Text(
                'Meslek Seç',
                style: TextStyle(color: Colors.deepPurple),
              )),
          // Hide the default underline
          underline: Container(),
          // set the color of the dropdown menu
          isExpanded: true,

          // The list of options
          items: _meslek
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
          selectedItemBuilder: (BuildContext context) => _meslek
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
          value: _selectedGorusme,
          onChanged: (value) {
            setState(() {
              _selectedGorusme = value;
            });
          },
          hint: const Center(
              child: Text(
                'Görüşmeyi Yapan',
                style: TextStyle(color: Colors.deepPurple),
              )),
          // Hide the default underline
          underline: Container(),
          // set the color of the dropdown menu
          isExpanded: true,

          // The list of options
          items: _gorusme
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
          selectedItemBuilder: (BuildContext context) => _gorusme
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
        TextFormField(
          decoration: const InputDecoration(labelText: 'Adres'),
          keyboardType: TextInputType.text,
          onSaved: (String? val) {
            _adres = val;
          },
        ),
        TextFormField(
          decoration: const InputDecoration(labelText: 'Notlar'),
          keyboardType: TextInputType.text,
          onSaved: (String? val) {
            _not = val;
          },
        ),
        const Divider(
          height: 10.0,
        ),
        OutlinedButton(
          onPressed: _validateInputs,
          child: const Text('FKaydet'),
        )
      ],
    );
  }
  String? validateName(String? value) {
    if (value!.isEmpty) {
      return 'Boş bırakmayınız';
    }
    else {
      return null;
    }
  }


}
*/

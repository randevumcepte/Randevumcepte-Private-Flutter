import 'package:flutter/material.dart';
import 'package:csc_picker/csc_picker.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';



class SalonBilgileri extends StatefulWidget {
  final dynamic isletmebilgi;
  const SalonBilgileri({Key? key,required this.isletmebilgi}) : super(key: key);

  @override
  _SalonBilgileriState createState() => _SalonBilgileriState();
}


class _SalonBilgileriState extends State<SalonBilgileri> {
  TextEditingController dateInput = TextEditingController();
  final List<String> _cins = ["Kadınlar","Erkekler","Unisex"];
  String? _selectedCins;

  final List<String> _kategori = ["Kuaförler","Berberler","Güzellik ve Estetik Merkezleri","Spalar","Solaryum Merkezleri",
    "Sağlıklı Yaşam Merkezleri","Tırnak ve Makyaj Stüdyoları","Diyetisyenler","Dövme ve Tattoo Merkezleri","Tesettür Kuaförleri"];
  String? _selectedKategori;




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

          title: const Text('Salon Bilgileri',style: TextStyle(color: Colors.black),),
          backgroundColor: Colors.white,
          toolbarHeight: 60,

          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            if (widget.isletmebilgi["demo_hesabi"].toString() == "1")
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: SizedBox(
                width: 100, // <-- Your width
                child: YukseltButonu(isletme_bilgi: widget.isletmebilgi,)
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
        TextFormField(
          decoration: const InputDecoration(labelText: 'Salon Adresi'),
          keyboardType: TextInputType.text,
          validator: validateName,
          onSaved: (String? val) {
            _name = val;
          },
        ),
        TextFormField(
          decoration: const InputDecoration(labelText: 'Salon Numarası'),
          keyboardType: TextInputType.phone,
          onSaved: (String? val) {
            _mobile = val;
          },
        ),
        TextFormField(
          decoration: const InputDecoration(labelText: 'Salon e-posta adresi'),
          keyboardType: TextInputType.emailAddress,
          onSaved: (String? val) {
            _email = val;
          },
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

        DropdownButton<String>(
          value: _selectedCins,
          onChanged: (value) {
            setState(() {
              _selectedCins = value;
            });
          },
          hint: const Center(
              child: Text(
                'Müşteri Cinsiyeti',
                style: TextStyle(color: Colors.deepPurple),
              )),
          // Hide the default underline
          underline: Container(),
          // set the color of the dropdown menu
          isExpanded: true,

          // The list of options
          items: _cins
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
          selectedItemBuilder: (BuildContext context) => _cins
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
      return 'Boş bırakmayınız';
    }
    if (value.length < 3) {
      return '2 karakterden fazla olmalıdır';
    } else {
      return null;
    }
  }


}
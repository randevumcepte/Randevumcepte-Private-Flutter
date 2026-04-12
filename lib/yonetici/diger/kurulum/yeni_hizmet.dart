import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';



class YeniHizmet extends StatefulWidget {
  final dynamic isletmebilgi;
  const YeniHizmet({Key? key,required this.isletmebilgi}) : super(key: key);

  @override
  _YeniHizmetState createState() => _YeniHizmetState();
}

class _YeniHizmetState extends State<YeniHizmet> {
  TextEditingController dateInput = TextEditingController();

  final List<String> _kategori = ["Saç","Tırnak","Makyaj","Estetik ve Güzellik","Solaryum","Ağda","Cilt Bakımı",
    "Lazer Epilasyon","Masaj","Dövme & Tatto","Spor,Yoga,Plates","Beslenme Danışmanlığı"];
  String? _selectedKategori;

  final List<String> _cins=["Kadınlar","Erkekler","Unisex"];
  String? _selectedCins;

  final List<String> _fiyatlandirma=["Herkes için ayrı","Müşteri cinsiyetine göre farklı"];
  String? _selectedFiyatlandirma;

  @override
  void initState() {
    dateInput.text = ""; //set the initial value of text field
    super.initState();
  }
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  AutovalidateMode _autoValidate = AutovalidateMode.disabled;
  String? _name;
  String? _mobile;


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
          backgroundColor: Colors.white,
          toolbarHeight: 60,
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
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text('Yeni Hizmet',style: TextStyle(color: Colors.black),),
          centerTitle: true,
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
          decoration: const InputDecoration(labelText: 'Hizmet Adı'),
          keyboardType: TextInputType.text,
          validator: validateName,
          onSaved: (String? val) {
            _name = val;
          },
        ),
        TextFormField(
          decoration: const InputDecoration(labelText: "Süre (dakika)"),
          keyboardType: TextInputType.datetime,
          onSaved: (String? val) {
            _mobile = val;
          },
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
                ' Hizmet Kategorisi',
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
                fontSize: 18,),
            ),
          ))
              .toList(),
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
                'Hizmet Cinsiyeti',
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
          selectedItemBuilder: (BuildContext context) =>_cins
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
          value: _selectedFiyatlandirma,
          onChanged: (value) {
            setState(() {
              _selectedFiyatlandirma = value;
            });
          },
          hint: const Center(
              child: Text(
                'Hizmet Fiyatladırması',
                style: TextStyle(color: Colors.deepPurple),
              )),
          // Hide the default underline
          underline: Container(),
          // set the color of the dropdown menu

          isExpanded: true,

          // The list of options
          items: _fiyatlandirma
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
          selectedItemBuilder: (BuildContext context) =>_fiyatlandirma
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
      return 'Hizmet adını boş bırakmayınız';
    }
    if (value.length < 3) {
      return '2 karakterden fazla olmalıdır';
    } else {
      return null;
    }
  }


}
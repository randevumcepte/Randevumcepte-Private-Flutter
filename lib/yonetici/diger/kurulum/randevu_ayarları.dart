import 'package:flutter/material.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';

import '../diger_page.dart';

class RandevuAyarlari extends StatefulWidget {
  final dynamic isletmebilgi;
  const RandevuAyarlari({Key? key,required this.isletmebilgi}) : super(key: key);

  @override
  _RandevuAyarlariState createState() => _RandevuAyarlariState();
}

class _RandevuAyarlariState extends State<RandevuAyarlari> {
  final List<String> _aralik = ["5 dakika","10 dakika","15 dakika","20 dakika","25 dakika","30 dakika","45 dakika","60 dakika",
    "90 dakika","120 dakika"];
  String? _selectedAralik;

  final List<String> _kategori=["Hizmete göre","Personele göre"];
  String? _selectedKategori;

  bool light = false;

  TextEditingController dateInput = TextEditingController();

  @override
  void initState() {
    dateInput.text = ""; //set the initial value of text field
    super.initState();
  }
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  AutovalidateMode _autoValidate = AutovalidateMode.disabled;

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
          ),          title: Text("Randevu Ayarları",style: TextStyle(color: Colors.black),),

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
        DropdownButton<String>(
          value: _selectedAralik,
          onChanged: (value) {
            setState(() {
              _selectedAralik = value;
            });
          },
          hint: const Center(
              child: Text(
                'Randevu Aralığı',
                style: TextStyle(color: Colors.deepPurple),
              )),
          // Hide the default underline
          underline: Container(),
          // set the color of the dropdown menu
          isExpanded: true,

          // The list of options
          items: _aralik
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
          selectedItemBuilder: (BuildContext context) => _aralik
              .map((e) => Center(
            child: Text(
              e,
              style: const TextStyle(
                fontSize: 18,),
            ),
          ))
              .toList(),
        ),
        ListTile(
            contentPadding: const EdgeInsets.fromLTRB(5, 2, 5, 2),
            title: Row(children: <Widget>[
              const Expanded(
                child: Text('Randevu Hatırlatma'),
              ),
              Expanded(
                  child: Align(
                      alignment: Alignment.centerRight,
                      child: Switch(
                        value: light,
                        activeColor: Colors.purple,
                        onChanged: (bool value) {
                          setState(() {
                            light = value;
                          });
                        },
                      ))),
            ])),
        const Divider(
          height: 2.0,
          thickness: 1,
        ),

        const SizedBox(
          height: 10.0,
        ),
        OutlinedButton(
          onPressed: () {
            /*Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => DigerPage()),
            );*/
          },
          child: const Text('Kaydet'),
        )
      ],
    );
  }




}
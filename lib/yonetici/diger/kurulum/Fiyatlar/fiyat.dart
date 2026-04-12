import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';

import '../hizmet_sureleri.dart';



class Fiyat extends StatefulWidget {
  const Fiyat({Key? key}) : super(key: key);

  @override
  _FiyatState createState() => _FiyatState();
}

class _FiyatState extends State<Fiyat> {
  TextEditingController dateInput = TextEditingController();

  @override
  void initState() {
    dateInput.text = ""; //set the initial value of text field
    super.initState();
  }
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  AutovalidateMode _autoValidate = AutovalidateMode.disabled;
  String? _mobile;
  String? _mobile2;
  String? _mobile3;



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

          title: const Text('Fiyatlandırma',style: TextStyle(color: Colors.black),),
          backgroundColor: Colors.white,
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
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text("Tek Fiyat",style: TextStyle(height: 2, fontSize: 18)),

          ],
        ),
        TextFormField(
          decoration: const InputDecoration(labelText: "Giriniz"),
          keyboardType: TextInputType.datetime,
          onSaved: (String? val) {
            _mobile = val;
          },
        ),
        const Divider(
          height: 3.0,
          thickness: 1,
        ),

        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text("Fiyat Aralığı",style: TextStyle(height: 2, fontSize: 18)),

          ],
        ),
        TextFormField(
          decoration: const InputDecoration(labelText: "En Düşük Fiyat"),
          keyboardType: TextInputType.datetime,
          onSaved: (String? val) {
            _mobile2= val;
          },
        ),
        TextFormField(
          decoration: const InputDecoration(labelText: "En Yüksek Fiyat"),
          keyboardType: TextInputType.datetime,
          onSaved: (String? val) {
            _mobile3 = val;
          },
        ),



        const SizedBox(
          height: 10.0,
        ),
        OutlinedButton(
          onPressed: () {Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => HizmetSureleri()),
          );},
          child: const Text('Kaydet'),
        )
      ],
    );
  }


}
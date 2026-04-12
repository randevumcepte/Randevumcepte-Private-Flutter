import 'package:flutter/material.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';




class SifreDegisitir extends StatefulWidget {
  final dynamic isletmebilgi;
  const SifreDegisitir({Key? key,required this.isletmebilgi}) : super(key: key);

  @override
  _SifreDegisitirState createState() => _SifreDegisitirState();
}

class _SifreDegisitirState extends State<SifreDegisitir> {
  TextEditingController dateInput = TextEditingController();

  @override
  void initState() {
    dateInput.text = ""; //set the initial value of text field
    super.initState();
  }
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  AutovalidateMode _autoValidate = AutovalidateMode.disabled;
  String? _mevcutSifre;
  String? _yeniSifre;
  String? _yeniSifreTekrar;

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

          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text('Şifre Değiştir',style: TextStyle(color: Colors.black),),
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
          decoration: const InputDecoration(labelText: 'Mevcut Şifre'),
          keyboardType: TextInputType.text,
          validator: validateName,
          onSaved: (String? val) {
            _mevcutSifre = val;
          },
        ),
        TextFormField(
          decoration: const InputDecoration(labelText: 'Yeni Şifre'),
          keyboardType: TextInputType.text,
          validator: validateName,
          onSaved: (String? val) {
            _yeniSifre = val;
          },
        ),
        TextFormField(
          decoration: const InputDecoration(labelText: 'Yeni Şifre (Tekrar)'),
          keyboardType: TextInputType.text,
          validator: validateName,
          onSaved: (String? val) {
            _yeniSifreTekrar = val;
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
      return 'Boş alan bırakmayınız';
    }
    if (value.length < 3) {
      return '2 karakterden fazla olmalıdır';
    } else {
      return null;
    }
  }


}
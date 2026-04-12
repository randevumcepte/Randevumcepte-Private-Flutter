import 'package:flutter/material.dart';



class EditPage extends StatefulWidget {
  const EditPage({Key? key}) : super(key: key);

  @override
  _EditPageState createState() => _EditPageState();
}

class _EditPageState extends State<EditPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  AutovalidateMode _autoValidate = AutovalidateMode.disabled;
  String? _name;
  String? _mobile;
  String? _email;
  String? _b_day;
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
          leading: BackButton(
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text('Düzenle'),
          backgroundColor: Colors.purple,
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
          decoration: const InputDecoration(labelText: 'Ad Soyad (Zorunlu)'),
          keyboardType: TextInputType.text,
          validator: validateName,
          onSaved: (String? val) {
            _name = val;
          },
        ),
        TextFormField(
          decoration: const InputDecoration(labelText: 'Telefon Numarası (Opsiyonel)'),
          keyboardType: TextInputType.phone,
          onSaved: (String? val) {
            _mobile = val;
          },
        ),
        TextFormField(
          decoration: const InputDecoration(labelText: 'Email (Opsiyonel)'),
          keyboardType: TextInputType.emailAddress,
          onSaved: (String? val) {
            _email = val;
          },
        ),
        TextFormField(
          decoration: const InputDecoration(labelText: 'Doğum Tarihi (Opsiyonel)'),
          keyboardType: TextInputType.text,
          onSaved: (String? val) {
            _name = val;
          },
        ),
        TextFormField(
          decoration: const InputDecoration(labelText: 'Cinsiyet (Opsiyonel)'),
          keyboardType: TextInputType.text,
          onSaved: (String? val) {
            _name = val;
          },
        ),
        TextFormField(
          decoration: const InputDecoration(labelText: 'Notlar (Opsiyonel)'),
          keyboardType: TextInputType.text,
          onSaved: (String? val) {
            _name = val;
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
      return 'İsmi boş bırakmayınız';
    }
    if (value.length < 3) {
      return '2 karakterden fazla olmalıdır';
    } else {
      return null;
    }
  }


}
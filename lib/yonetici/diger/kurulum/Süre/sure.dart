import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';



class Sure extends StatefulWidget {
    const Sure({Key? key}) : super(key: key);

    @override
    _SureState createState() => _SureState();
}

class _SureState extends State<Sure> {
    TextEditingController dateInput = TextEditingController();

    @override
    void initState() {
        dateInput.text = ""; //set the initial value of text field
        super.initState();
    }
    final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
    AutovalidateMode _autoValidate = AutovalidateMode.disabled;
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
                    title: const Text('Süre',style: TextStyle(color: Colors.black),),

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
                    decoration: const InputDecoration(labelText: "Süre (dakika)"),
                    keyboardType: TextInputType.datetime,
                    onSaved: (String? val) {
                        _mobile = val;
                    },
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
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';



class UrunEdit extends StatefulWidget {

    const UrunEdit({Key? key }) : super(key: key);

    @override
    _UrunEditState createState() => _UrunEditState();
}

class _UrunEditState extends State<UrunEdit> {
    String _scanBarcode = 'Bilinmiyor';

    @override
    void initState() {
        super.initState();
    }


    Future<void> scanQR() async {
        String barcodeScanRes;
        // Platform mesajları başarısız olabilir, bu yüzden try/catch kullanıyoruz.
        try {
            var result = await BarcodeScanner.scan(); // Barkod tarama başlatılır
            barcodeScanRes = result.rawContent; // Tarama sonucunu al
            print(barcodeScanRes);
        } on PlatformException {
            barcodeScanRes = 'Platform sürümü alınamadı.';
        }

        // Widget ağacından kaldırılmışsa, yanıtı yok saymak istiyoruz.
        if (!mounted) return;

        setState(() {
            _scanBarcode = barcodeScanRes;
        });
    }

    Future<void> scanBarcodeNormal() async {
        String barcodeScanRes;
        // Platform mesajları başarısız olabilir, bu yüzden try/catch kullanıyoruz.
        try {
            var result = await BarcodeScanner.scan(); // Barkod tarama başlatılır
            barcodeScanRes = result.rawContent; // Tarama sonucunu al
            print(barcodeScanRes);
        } on PlatformException {
            barcodeScanRes = 'Platform sürümü alınamadı.';
        }

        // Widget ağacından kaldırılmışsa, yanıtı yok saymak istiyoruz.
        if (!mounted) return;

        setState(() {
            _scanBarcode = barcodeScanRes;
        });
    }
    final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
    AutovalidateMode _autoValidate = AutovalidateMode.disabled;
    String? _name;
    String? _fiyat;
    String? _adet;

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
                    title: const Text('Güncelle',style: TextStyle(color: Colors.black),),

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
                    decoration: const InputDecoration(labelText: 'Ürün Adı'),
                    keyboardType: TextInputType.text,

                    onSaved: (String? val) {
                        _name = val;
                    },
                ),
                TextFormField(
                    decoration: const InputDecoration(labelText: 'Fiyat'),
                    keyboardType: TextInputType.phone,
                    validator: validateName,
                    onSaved: (String? val) {
                        _fiyat = val;
                    },
                ),
                TextFormField(
                    decoration: const InputDecoration(labelText: 'Stok Adedi'),
                    keyboardType: TextInputType.emailAddress,
                    onSaved: (String? val) {
                        _adet = val;
                    },
                ),
                ElevatedButton(
                    onPressed: () => scanBarcodeNormal(),
                    child: Text('Barkod Tara'),style: ElevatedButton.styleFrom(
                    textStyle:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    backgroundColor: Colors.purple[800], // background (button) color
                    foregroundColor: Colors.white,),),
                const Divider(
                    height: 1.0,
                    thickness: 1,
                ),
                Text('Barkod : $_scanBarcode\n',
                    style: TextStyle(fontSize: 18,),
                    textAlign: TextAlign.center,),



                const SizedBox(
                    height: 10.0,
                ),
                OutlinedButton(
                    onPressed: _validateInputs,
                    child: const Text('Güncelle'),
                )
            ],
        );
    }
    String? validateName(String? value) {
        if (value!.isEmpty) {
            return 'Fiyatı Girmediniz';
        }
        else {
            return null;
        }
    }


}
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:randevu_sistem/Models/randevuhizmetleri.dart';
import 'package:randevu_sistem/yeni/urun.dart';

import '../../randevular/hizmet_add.dart';
import '../../randevular/musteri.dart';
import '../menu/senetler/yazdir.dart';



class SenetGuncelle extends StatefulWidget {
  const SenetGuncelle({Key? key}) : super(key: key);

  @override
  _SenetGuncelleState createState() => _SenetGuncelleState();
}

class _SenetGuncelleState extends State<SenetGuncelle> {


  TextEditingController dateInput = TextEditingController();

  @override
  void initState() {
    dateInput.text = ""; //set the initial value of text field
    super.initState();
  }
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  AutovalidateMode _autoValidate = AutovalidateMode.disabled;
  String? _tutar;
  String? _vade;


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
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text('Senet Güncelle',style: TextStyle(color: Colors.black,fontSize: 20),),
          toolbarHeight: 60,

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
          leading: const Icon(Icons.supervised_user_circle_sharp),
          title: Text('Müşteri Seçiniz'),
          trailing: Icon(Icons.keyboard_arrow_right),
          onTap: () {

            /*showDialog<Widget>(
              context: context,
              barrierDismissible: true,
              builder: (BuildContext context) {
                //return Musteri();
              },
            ).then((dynamic value) => setState(() {}));*/
          },
        ),
        ListTile(
          contentPadding: const EdgeInsets.fromLTRB(5, 0, 5, 5),
          leading: const Icon(Icons.production_quantity_limits),

          title: Text('Ürün Seçiniz'),
          trailing: Icon(Icons.keyboard_arrow_right),
          onTap: () {

            showDialog<Widget>(
              context: context,
              barrierDismissible: true,
              builder: (BuildContext context) {
                return UrunList();
              },
            ).then((dynamic value) => setState(() {}));
          },
        ),
        ListTile(
          contentPadding: const EdgeInsets.fromLTRB(5, 0, 5, 5),
          leading: const Icon(Icons.local_laundry_service_outlined),

          title: Text('Hizmet Seçiniz'),
          trailing: Icon(Icons.keyboard_arrow_right),
          onTap: () {

            showDialog<Widget>(
              context: context,
              barrierDismissible: true,
              builder: (BuildContext context) {
                return HizmetAdd(secilihizmetler: [],personel_id: "",);
              },
            ).then((dynamic value) => setState(() {}));
          },
        ),

        const Divider(
          height: 2.0,
          thickness: 1,
        ),

        const Divider(
          height: 2.0,
          thickness: 1,
        ),
        TextFormField(
          decoration: const InputDecoration(icon: Icon(Icons.av_timer),labelText: 'Tutar Giriniz'),
          keyboardType: TextInputType.phone,
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
                  labelText: "Ödeme Tarihini Giriniz" //label text of field
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
          decoration: const InputDecoration(icon: Icon(Icons.attach_money),labelText: 'Vade (Ay)'),
          keyboardType: TextInputType.phone,
          validator: validateName,
          onSaved: (String? val) {
            _vade = val;
          },
        ),

        const SizedBox(
          height: 10.0,
        ),
        OutlinedButton(
          onPressed: (){ /*Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => PdfPreviewPage()),
          );*/},
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
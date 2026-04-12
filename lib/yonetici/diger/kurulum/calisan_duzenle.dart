import 'package:flutter/material.dart';


import '../menu/ayarlar/personeller/oglen_arasi.dart';



class CalisanEdit extends StatefulWidget {
  final dynamic isletmebilgi;
  const CalisanEdit({Key? key,required this.isletmebilgi}) : super(key: key);

  @override
  _CalisanEditState createState() => _CalisanEditState();
}

class _CalisanEditState extends State<CalisanEdit> {
  bool checkBoxValue = false;
  List<String> _durumPzt = ["Açık","Kapalı"];
  String _selectedDurumPzt="Açık";

  List<String> _Saat1Pzt = ["06:00","06:30","07:00","07:30","08:00","08:30","09:00","09:30","10:00","10:30","11:00","11:30","12:00","12:30",
    "13:00","13:30","14:00","14:30","15:00","15:30","16:00","16:30","17:00","17:30","18:00","18:30","19:00","19:30","20:00"];
  String? _selectedSaat1Pzt= "09:00";

  List<String> _Saat2Pzt = ["10:00","10:30","11:00","11:30","12:00","12:30", "13:00","13:30","14:00","14:30","15:00","15:30","16:00","16:30","17:00","17:30",
    "18:00","18:30","19:00","19:30","20:00","20:30","21:00","21:30","22:00","22:30","23:00","23:30","24:00"];
  String? _selectedSaat2Pzt="21:00";

  List<String> _durumSal = ["Açık","Kapalı"];
  String _selectedDurumSal="Açık";

  List<String> _Saat1Sal = ["06:00","06:30","07:00","07:30","08:00","08:30","09:00","09:30","10:00","10:30","11:00","11:30","12:00","12:30",
    "13:00","13:30","14:00","14:30","15:00","15:30","16:00","16:30","17:00","17:30","18:00","18:30","19:00","19:30","20:00"];
  String? _selectedSaat1Sal= "09:00";

  List<String> _Saat2Sal = ["10:00","10:30","11:00","11:30","12:00","12:30", "13:00","13:30","14:00","14:30","15:00","15:30","16:00","16:30","17:00","17:30",
    "18:00","18:30","19:00","19:30","20:00","20:30","21:00","21:30","22:00","22:30","23:00","23:30","24:00"];
  String? _selectedSaat2Sal="21:00";


  List<String> _durumCar = ["Açık","Kapalı"];
  String _selectedDurumCar="Açık";

  List<String> _Saat1Car = ["06:00","06:30","07:00","07:30","08:00","08:30","09:00","09:30","10:00","10:30","11:00","11:30","12:00","12:30",
    "13:00","13:30","14:00","14:30","15:00","15:30","16:00","16:30","17:00","17:30","18:00","18:30","19:00","19:30","20:00"];
  String? _selectedSaat1Car= "09:00";

  List<String> _Saat2Car = ["10:00","10:30","11:00","11:30","12:00","12:30", "13:00","13:30","14:00","14:30","15:00","15:30","16:00","16:30","17:00","17:30",
    "18:00","18:30","19:00","19:30","20:00","20:30","21:00","21:30","22:00","22:30","23:00","23:30","24:00"];
  String? _selectedSaat2Car="21:00";

  List<String> _durumPer = ["Açık","Kapalı"];
  String _selectedDurumPer="Açık";

  List<String> _Saat1Per = ["06:00","06:30","07:00","07:30","08:00","08:30","09:00","09:30","10:00","10:30","11:00","11:30","12:00","12:30",
    "13:00","13:30","14:00","14:30","15:00","15:30","16:00","16:30","17:00","17:30","18:00","18:30","19:00","19:30","20:00"];
  String? _selectedSaat1Per= "09:00";

  List<String> _Saat2Per = ["10:00","10:30","11:00","11:30","12:00","12:30", "13:00","13:30","14:00","14:30","15:00","15:30","16:00","16:30","17:00","17:30",
    "18:00","18:30","19:00","19:30","20:00","20:30","21:00","21:30","22:00","22:30","23:00","23:30","24:00"];
  String? _selectedSaat2Per="21:00";

  List<String> _durumCum = ["Açık","Kapalı"];
  String _selectedDurumCum="Açık";

  List<String> _Saat1Cum = ["06:00","06:30","07:00","07:30","08:00","08:30","09:00","09:30","10:00","10:30","11:00","11:30","12:00","12:30",
    "13:00","13:30","14:00","14:30","15:00","15:30","16:00","16:30","17:00","17:30","18:00","18:30","19:00","19:30","20:00"];
  String? _selectedSaat1Cum= "09:00";

  List<String> _Saat2Cum = ["10:00","10:30","11:00","11:30","12:00","12:30", "13:00","13:30","14:00","14:30","15:00","15:30","16:00","16:30","17:00","17:30",
    "18:00","18:30","19:00","19:30","20:00","20:30","21:00","21:30","22:00","22:30","23:00","23:30","24:00"];
  String? _selectedSaat2Cum="21:00";

  List<String> _durumCts = ["Açık","Kapalı"];
  String _selectedDurumCts="Açık";

  List<String> _Saat1Cts = ["06:00","06:30","07:00","07:30","08:00","08:30","09:00","09:30","10:00","10:30","11:00","11:30","12:00","12:30",
    "13:00","13:30","14:00","14:30","15:00","15:30","16:00","16:30","17:00","17:30","18:00","18:30","19:00","19:30","20:00"];
  String? _selectedSaat1Cts= "09:00";

  List<String> _Saat2Cts = ["10:00","10:30","11:00","11:30","12:00","12:30", "13:00","13:30","14:00","14:30","15:00","15:30","16:00","16:30","17:00","17:30",
    "18:00","18:30","19:00","19:30","20:00","20:30","21:00","21:30","22:00","22:30","23:00","23:30","24:00"];
  String? _selectedSaat2Cts="21:00";

  List<String> _durumPzr = ["Açık","Kapalı"];
  String _selectedDurumPzr="Açık";

  List<String> _Saat1Pzr = ["06:00","06:30","07:00","07:30","08:00","08:30","09:00","09:30","10:00","10:30","11:00","11:30","12:00","12:30",
    "13:00","13:30","14:00","14:30","15:00","15:30","16:00","16:30","17:00","17:30","18:00","18:30","19:00","19:30","20:00"];
  String? _selectedSaat1Pzr= "09:00";

  List<String> _Saat2Pzr = ["10:00","10:30","11:00","11:30","12:00","12:30", "13:00","13:30","14:00","14:30","15:00","15:30","16:00","16:30","17:00","17:30",
    "18:00","18:30","19:00","19:30","20:00","20:30","21:00","21:30","22:00","22:30","23:00","23:30","24:00"];
  String? _selectedSaat2Pzr="21:00";


  TextEditingController dateInput = TextEditingController();
  final List<String> _tipi=["Yönetici","Sekreter","Çalışan"];
  String? _selectedTipi;

  final List<String> _musteriler=["Kadınlar","Erkekler","Unisex"];
  String? _selectedMusteriler;


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
          toolbarHeight: 70,

          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),

          title: const Text('Çalışan Düzenle',style: TextStyle(color: Colors.black),),

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
        DropdownButton<String>(
          value: _selectedTipi,
          onChanged: (value) {
            setState(() {
              _selectedTipi = value;
            });
          },
          hint: const Center(
              child: Text(
                'Tipi Seçiniz',
                style: TextStyle(color: Colors.deepPurple),
              )),
          // Hide the default underline
          underline: Container(),
          // set the color of the dropdown menu
          isExpanded: true,

          // The list of options
          items: _tipi
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
          selectedItemBuilder: (BuildContext context) => _tipi
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
          value: _selectedMusteriler,
          onChanged: (value) {
            setState(() {
              _selectedMusteriler = value;
            });
          },
          hint: const Center(
              child: Text(
                'Müşteriler Seçiniz',
                style: TextStyle(color: Colors.deepPurple),
              )),
          // Hide the default underline
          underline: Container(),
          // set the color of the dropdown menu

          isExpanded: true,

          // The list of options
          items: _musteriler
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
          selectedItemBuilder: (BuildContext context) =>_musteriler
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
        CheckboxListTile(
          title: const Text('Takvimde Görünür'),
          secondary: const Icon(
            Icons.calendar_today,
            color: Colors.purple,
          ),
          value: checkBoxValue,
          onChanged: (bool? newValue) {
            setState(() {
              checkBoxValue = newValue!;
            });
          },
        ),
        const Divider(
          height: 2.0,
          thickness: 1,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text("Çalışma Saatleri",style: TextStyle(height: 2, fontSize: 18)),

          ],
        ),
        const Divider(
          height: 2.0,
          thickness: 1,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,

          children: [
            Text("Pts"),
            DropdownButton<String>(
              hint: Text("Durum"),
              items: _durumPzt.map((durum) {
                return DropdownMenuItem<String>(
                  child: Text(durum),
                  value: durum,
                );
              }).toList(),
              onChanged: (data) {
                setState(() {
                  _selectedDurumPzt = data!;
                });
              },
              value: _selectedDurumPzt,
            ),
            DropdownButton<String>(
              hint: Text("Saat Seçin"),
              items: _Saat1Pzt.map((saat1) {
                return DropdownMenuItem<String>(
                  child: Text(saat1),
                  value: saat1,
                );
              }).toList(),
              onChanged: (data) {
                setState(() {
                  _selectedSaat1Pzt = data!;
                });
              },
              value: _selectedSaat1Pzt,
            ),
            DropdownButton<String>(
              hint: Text("Saat Seçin"),
              items: _Saat2Pzt.map((saat2) {
                return DropdownMenuItem<String>(
                  child: Text(saat2),
                  value: saat2,
                );
              }).toList(),
              onChanged: (data) {
                setState(() {
                  _selectedSaat2Pzt = data!;
                });
              },
              value: _selectedSaat2Pzt,
            ),

          ],

        ),
        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,

          children: [
            Text("Sal"),
            DropdownButton<String>(
              hint: Text("Durum"),
              items: _durumSal.map((durum) {
                return DropdownMenuItem<String>(
                  child: Text(durum),
                  value: durum,
                );
              }).toList(),
              onChanged: (data) {
                setState(() {
                  _selectedDurumSal = data!;
                });
              },
              value: _selectedDurumSal,
            ),
            DropdownButton<String>(
              hint: Text("Saat Seçin"),
              items: _Saat1Sal.map((saat1) {
                return DropdownMenuItem<String>(
                  child: Text(saat1),
                  value: saat1,
                );
              }).toList(),
              onChanged: (data) {
                setState(() {
                  _selectedSaat1Sal = data!;
                });
              },
              value: _selectedSaat1Sal,
            ),
            DropdownButton<String>(
              hint: Text("Saat Seçin"),
              items: _Saat2Sal.map((saat2) {
                return DropdownMenuItem<String>(
                  child: Text(saat2),
                  value: saat2,
                );
              }).toList(),
              onChanged: (data) {
                setState(() {
                  _selectedSaat2Sal = data!;
                });
              },
              value: _selectedSaat2Sal,
            ),

          ],

        ),
        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,

          children: [
            Text("Çar"),
            DropdownButton<String>(
              hint: Text("Durum"),
              items: _durumCar.map((durum) {
                return DropdownMenuItem<String>(
                  child: Text(durum),
                  value: durum,
                );
              }).toList(),
              onChanged: (data) {
                setState(() {
                  _selectedDurumCar = data!;
                });
              },
              value: _selectedDurumCar,
            ),
            DropdownButton<String>(
              hint: Text("Saat Seçin"),
              items: _Saat1Car.map((saat1) {
                return DropdownMenuItem<String>(
                  child: Text(saat1),
                  value: saat1,
                );
              }).toList(),
              onChanged: (data) {
                setState(() {
                  _selectedSaat1Car = data!;
                });
              },
              value: _selectedSaat1Car,
            ),
            DropdownButton<String>(
              hint: Text("Saat Seçin"),
              items: _Saat2Car.map((saat2) {
                return DropdownMenuItem<String>(
                  child: Text(saat2),
                  value: saat2,
                );
              }).toList(),
              onChanged: (data) {
                setState(() {
                  _selectedSaat2Car = data!;
                });
              },
              value: _selectedSaat2Car,
            ),

          ],

        ),
        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,

          children: [
            Text("Per"),
            DropdownButton<String>(
              hint: Text("Durum"),
              items: _durumPer.map((durum) {
                return DropdownMenuItem<String>(
                  child: Text(durum),
                  value: durum,
                );
              }).toList(),
              onChanged: (data) {
                setState(() {
                  _selectedDurumPer = data!;
                });
              },
              value: _selectedDurumPer,
            ),
            DropdownButton<String>(
              hint: Text("Saat Seçin"),
              items: _Saat1Per.map((saat1) {
                return DropdownMenuItem<String>(
                  child: Text(saat1),
                  value: saat1,
                );
              }).toList(),
              onChanged: (data) {
                setState(() {
                  _selectedSaat1Per = data!;
                });
              },
              value: _selectedSaat1Per,
            ),
            DropdownButton<String>(
              hint: Text("Saat Seçin"),
              items: _Saat2Per.map((saat2) {
                return DropdownMenuItem<String>(
                  child: Text(saat2),
                  value: saat2,
                );
              }).toList(),
              onChanged: (data) {
                setState(() {
                  _selectedSaat2Per = data!;
                });
              },
              value: _selectedSaat2Per,
            ),

          ],

        ),
        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,

          children: [
            Text("Cum"),
            DropdownButton<String>(
              hint: Text("Durum"),
              items: _durumCum.map((durum) {
                return DropdownMenuItem<String>(
                  child: Text(durum),
                  value: durum,
                );
              }).toList(),
              onChanged: (data) {
                setState(() {
                  _selectedDurumCum = data!;
                });
              },
              value: _selectedDurumCum,
            ),
            DropdownButton<String>(
              hint: Text("Saat Seçin"),
              items: _Saat1Cum.map((saat1) {
                return DropdownMenuItem<String>(
                  child: Text(saat1),
                  value: saat1,
                );
              }).toList(),
              onChanged: (data) {
                setState(() {
                  _selectedSaat1Cum = data!;
                });
              },
              value: _selectedSaat1Cum,
            ),
            DropdownButton<String>(
              hint: Text("Saat Seçin"),
              items: _Saat2Cum.map((saat2) {
                return DropdownMenuItem<String>(
                  child: Text(saat2),
                  value: saat2,
                );
              }).toList(),
              onChanged: (saat2) {
                setState(() {
                  _selectedSaat2Cum = saat2!;
                });
              },
              value: _selectedSaat2Cum,
            ),

          ],

        ),
        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,

          children: [
            Text("Cts"),
            DropdownButton<String>(
              hint: Text("Durum"),
              items: _durumCts.map((durum) {
                return DropdownMenuItem<String>(
                  child: Text(durum),
                  value: durum,
                );
              }).toList(),
              onChanged: (durum) {
                setState(() {
                  _selectedDurumCts = durum!;
                });
              },
              value: _selectedDurumCts,
            ),
            DropdownButton<String>(
              hint: Text("Saat Seçin"),
              items: _Saat1Cts.map((saat1) {
                return DropdownMenuItem<String>(
                  child: Text(saat1),
                  value: saat1,
                );
              }).toList(),
              onChanged: (saat1) {
                setState(() {
                  _selectedSaat1Cts = saat1!;
                });
              },
              value: _selectedSaat1Cts,
            ),
            DropdownButton<String>(
              hint: Text("Saat Seçin"),
              items: _Saat2Cts.map((saat2) {
                return DropdownMenuItem<String>(
                  child: Text(saat2),
                  value: saat2,
                );
              }).toList(),
              onChanged: (saat2) {
                setState(() {
                  _selectedSaat2Cts = saat2!;
                });
              },
              value: _selectedSaat2Cts,
            ),

          ],

        ),
        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,

          children: [
            Text("Pzr"),
            DropdownButton<String>(
              hint: Text("Durum"),
              items: _durumPzr.map((durum) {
                return DropdownMenuItem<String>(
                  child: Text(durum),
                  value: durum,
                );
              }).toList(),
              onChanged: (durum) {
                setState(() {
                  _selectedDurumPzr = durum!;
                });
              },
              value: _selectedDurumPzr,
            ),
            DropdownButton<String>(
              hint: Text("Saat Seçin"),
              items: _Saat1Pzr.map((saat1) {
                return DropdownMenuItem<String>(
                  child: Text(saat1),
                  value: saat1,
                );
              }).toList(),
              onChanged: (saat1) {
                setState(() {
                  _selectedSaat1Pzr = saat1!;
                });
              },
              value: _selectedSaat1Pzr,
            ),
            DropdownButton<String>(
              hint: Text("Saat Seçin"),
              items: _Saat2Pzr.map((saat2) {
                return DropdownMenuItem<String>(
                  child: Text(saat2),
                  value: saat2,
                );
              }).toList(),
              onChanged: (saat2) {
                setState(() {
                  _selectedSaat2Pzr = saat2!;
                });
              },
              value: _selectedSaat2Pzr,
            ),

          ],

        ),
        const Divider(
          height: 2.0,
          thickness: 1,
        ),
        ListTile(
          title: Text('Öğlen Arası Saatleri (varsa ekleyiniz)'),
          trailing: Icon(Icons.keyboard_arrow_right),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => OglenArasi(isletmebilgi: widget.isletmebilgi,)),
            );
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
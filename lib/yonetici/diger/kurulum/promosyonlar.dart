import 'package:flutter/material.dart';
import 'package:intl/intl.dart';



class Promosyonlar extends StatefulWidget {
  const Promosyonlar({Key? key}) : super(key: key);

  @override
  _PromosyonlarState createState() => _PromosyonlarState();
}

class _PromosyonlarState extends State<Promosyonlar> {
  TextEditingController dateInput = TextEditingController();

  final List<String> _kazanimNakit = ["%0","%1","%2","%3","%4","%5","%6","%7","%8","%9","%10","%15","%20","%25","%30","%35","%40",
    "%45","%50","%75","%100"];
  String? _selectedKazanimNakit;

  final List<String> _kazanimKredi = ["%0","%1","%2","%3","%4","%5","%6","%7","%8","%9","%10","%15","%20","%25","%30","%35","%40",
    "%45","%50","%75","%100"];
  String? _selectedKazanimKredi;

  final List<String> _kullanimLimit = ["0 TL","1 TL","2 TL","3 TL","4 TL","5 TL","6 TL","7 TL","8 TL","9 TL","10 TL","15 TL","20 TL",
    "25 TL","30 TL","35 TL","40 TL","45 TL","50 TL","75 TL","100 TL"];
  String? _selectedKullanimLimit;

  final List<String> _dgIndirimi = ["%0","%1","%2","%3","%4","%5","%6","%7","%8","%9","%10","%15","%20","%25","%30","%35","%40",
    "%45","%50","%75","%100"];
  String? _selectedDgIndirimi;

  final List<String> _onlinerandevuIndirim = ["%0","%1","%2","%3","%4","%5","%6","%7","%8","%9","%10","%15","%20","%25","%30","%35","%40",
    "%45","%50","%75","%100"];
  String? _selectedOnlineRandevuIndirim;



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
          backgroundColor: Colors.purple,
          leading: BackButton(
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text('Promosyonlar'),
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

        DropdownButton<String>(
          value: _selectedKazanimNakit,
          onChanged: (value) {
            setState(() {
              _selectedKazanimNakit = value;
            });
          },
          hint: const Center(
              child: Text(
                'Parapuan Kazanımı(nakit)',
                style: TextStyle(color: Colors.deepPurple),
              )),
          // Hide the default underline
          underline: Container(),
          // set the color of the dropdown menu
          isExpanded: true,

          // The list of options
          items: _kazanimNakit
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
          selectedItemBuilder: (BuildContext context) => _kazanimNakit
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
          value: _selectedKazanimKredi,
          onChanged: (value) {
            setState(() {
              _selectedKazanimKredi = value;
            });
          },
          hint: const Center(
              child: Text(
                'Parapuan Kazanımı (kredi)',
                style: TextStyle(color: Colors.deepPurple),
              )),
          // Hide the default underline
          underline: Container(),
          // set the color of the dropdown menu
          isExpanded: true,

          // The list of options
          items: _kazanimKredi
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
          selectedItemBuilder: (BuildContext context) => _kazanimKredi
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
          value: _selectedKullanimLimit,
          onChanged: (value) {
            setState(() {
              _selectedKullanimLimit = value;
            });
          },
          hint: const Center(
              child: Text(
                'Parapuan Kullanım Limiti',
                style: TextStyle(color: Colors.deepPurple),
              )),
          // Hide the default underline
          underline: Container(),
          // set the color of the dropdown menu
          isExpanded: true,

          // The list of options
          items: _kullanimLimit
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
          selectedItemBuilder: (BuildContext context) => _kullanimLimit
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
          value: _selectedDgIndirimi,
          onChanged: (value) {
            setState(() {
              _selectedDgIndirimi = value;
            });
          },
          hint: const Center(
              child: Text(
                'Doğumgünü İndirimi',
                style: TextStyle(color: Colors.deepPurple),
              )),
          // Hide the default underline
          underline: Container(),
          // set the color of the dropdown menu
          isExpanded: true,

          // The list of options
          items: _dgIndirimi
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
          selectedItemBuilder: (BuildContext context) => _dgIndirimi
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
          value: _selectedOnlineRandevuIndirim,
          onChanged: (value) {
            setState(() {
              _selectedOnlineRandevuIndirim = value;
            });
          },
          hint: const Center(
              child: Text(
                'Online Randevu İndirimi',
                style: TextStyle(color: Colors.deepPurple),
              )),
          // Hide the default underline
          underline: Container(),
          // set the color of the dropdown menu
          isExpanded: true,

          // The list of options
          items: _onlinerandevuIndirim
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
          selectedItemBuilder: (BuildContext context) => _onlinerandevuIndirim
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
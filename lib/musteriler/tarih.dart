import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../yonetici/adisyonlar/musteri_detay.dart';

class Tarih extends StatefulWidget {
  Tarih({Key? key}) : super(key: key);

  @override
  _TarihState createState() => _TarihState();
}

class _TarihState extends State<Tarih> {
  GlobalKey<FormState> _oFormKey = GlobalKey<FormState>();
  late TextEditingController _controller1;
  DateTime? selectedDateTime1;

  String _valueChanged1 = '';
  String _valueToValidate1 = '';
  String _valueSaved1 = '';

  @override
  void initState() {
    super.initState();
    _controller1 = TextEditingController();
    _getValue();
  }

  Future<void> _getValue() async {
    await Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        selectedDateTime1 = DateTime(2000, 9, 20, 14, 30);
        _controller1.text = DateFormat('dd.MM.yyyy HH:mm').format(selectedDateTime1!);
      });
    });
  }

  Future<void> _selectDateTime(BuildContext context) async {
    DateTime now = DateTime.now();
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      selectableDayPredicate: (date) {
        if (date.weekday == 6 || date.weekday == 7) return false;
        return true;
      },
    );

    if (date != null) {
      TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        DateTime fullDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );

        setState(() {
          selectedDateTime1 = fullDateTime;
          _controller1.text = DateFormat('dd.MM.yyyy HH:mm').format(fullDateTime);
          _valueChanged1 = _controller1.text;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tarih Seçimi', style: TextStyle(color: Colors.black)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.white,
        toolbarHeight: 70,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Form(
          key: _oFormKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                controller: _controller1,
                readOnly: true,
                decoration: InputDecoration(
                  icon: Icon(Icons.event),
                  labelText: 'Tarih ve Saat',
                  border: OutlineInputBorder(),
                ),
                onTap: () => _selectDateTime(context),
                validator: (val) {
                  if (selectedDateTime1 == null) {
                    setState(() => _valueToValidate1 = '');
                    return 'Lütfen tarih ve saat seçin';
                  }
                  setState(() => _valueToValidate1 = val ?? '');
                  return null;
                },
                onSaved: (val) {
                  setState(() => _valueSaved1 = val ?? '');
                },
              ),
              SizedBox(height: 50),
              Text(
                'Tarih şu şekilde değiştirildi',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              SelectableText(_valueChanged1),
              SizedBox(height: 10),
              Text(
                'Kaydedilen tarih',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              SelectableText(_valueSaved1),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  final form = _oFormKey.currentState;
                  if (form?.validate() == true) {
                    form?.save();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MusteriAdisyon()),
                    );
                  }
                },
                child: Text('Kaydet'),
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  final form = _oFormKey.currentState;
                  form?.reset();

                  setState(() {
                    _controller1.clear();
                    selectedDateTime1 = null;
                    _valueChanged1 = '';
                    _valueToValidate1 = '';
                    _valueSaved1 = '';
                  });
                },
                child: Text('Sıfırla'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

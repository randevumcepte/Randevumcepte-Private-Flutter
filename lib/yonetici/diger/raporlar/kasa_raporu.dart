import 'package:flutter/material.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';



class KasaRaporu extends StatefulWidget {
  final dynamic isletmebilgi;
  const KasaRaporu({Key? key,required this.isletmebilgi}) : super(key: key);
  @override
  _KasaRaporuState createState() => _KasaRaporuState();
}

GlobalKey<FormState> myFormKey = new GlobalKey();

class _KasaRaporuState extends State<KasaRaporu> {
  DateTimeRange? myDateRange;

  void _submitForm() {
    final FormState? form = myFormKey.currentState;
    form!.save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Kasa Raporu",style: TextStyle(color: Colors.black),),
        backgroundColor: Colors.white,
        toolbarHeight: 60,
        actions: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: SizedBox(
              width: 100, // <-- Your width
              child: YukseltButonu(isletme_bilgi:widget.isletmebilgi)
            ),
          ),

        ],
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: myFormKey,
          child: Column(
            children: [
              Column(
                children: [
                  TextFormField(
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Tarih Aralığı',
                      prefixIcon: Icon(Icons.date_range),
                      hintText: 'Başlangıç ve bitiş tarihi seçin',
                      border: OutlineInputBorder(),
                    ),
                    controller: TextEditingController(
                      text: myDateRange == null
                          ? ''
                          : '${myDateRange!.start.toString().split(" ")[0]} - ${myDateRange!.end.toString().split(" ")[0]}',
                    ),
                    onTap: () async {
                      DateTimeRange? picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(1990),
                        lastDate: DateTime(2100),
                        initialDateRange: myDateRange,
                      );
                      if (picked != null) {
                        setState(() {
                          myDateRange = picked;
                        });
                      }
                    },
                    validator: (value) {
                      if (myDateRange == null) {
                        return 'Lütfen tarih aralığı seçin';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _submitForm,
                    child: Text("Raporu Göster"),
                  ),
                ],

              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text("Kapanış Bakiyesi", style: TextStyle(fontWeight: FontWeight.bold,fontSize: 20),),
                        Spacer(),
                        Text("0.00TL", style: TextStyle(fontSize: 15),),
                      ],
                    ),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text("Toplam Gelir", style: TextStyle(fontWeight: FontWeight.bold,fontSize: 18,color: Colors.black54),),
                              Spacer(),
                              Text("0.00TL", style: TextStyle(fontSize: 15),),
                            ],
                          ),
                          const Divider(),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Text("Nakit", style: TextStyle(fontSize: 15),),
                                      Spacer(),
                                      Text("0.00TL", style: TextStyle(fontSize: 15),),
                                    ],
                                  ),
                                  const Divider(),
                                  Row(
                                    children: [
                                      Text("Kredi Kartı", style: TextStyle(fontSize: 15),),
                                      Spacer(),
                                      Text("0.00TL", style: TextStyle(fontSize: 15),),
                                    ],
                                  ),
                                  const Divider(),
                                  Row(
                                    children: [
                                      Text("Havale", style: TextStyle(fontSize: 15),),
                                      Spacer(),
                                      Text("0.00TL", style: TextStyle(fontSize: 15),),
                                    ],
                                  ),
                                  const Divider(),
                                  Row(
                                    children: [
                                      Text("Diğer", style: TextStyle(fontSize: 15),),
                                      Spacer(),
                                      Text("0.00TL", style: TextStyle(fontSize: 15),),
                                    ],
                                  )
                                ],
                            ),
                          ),
                          const Divider(),
                          Row(
                            children: [
                              Text("Toplam Gider", style: TextStyle(fontWeight: FontWeight.bold,fontSize: 18,color: Colors.black54),),
                              Spacer(),
                              Text("0.00TL", style: TextStyle(fontSize: 15),),
                            ],
                          ),
                          const Divider(),

                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Text("Nakit", style: TextStyle(fontSize: 15),),
                                    Spacer(),
                                    Text("0.00TL", style: TextStyle(fontSize: 15),),
                                  ],
                                ),
                                const Divider(),
                                Row(
                                  children: [
                                    Text("Kredi Kartı", style: TextStyle(fontSize: 15),),
                                    Spacer(),
                                    Text("0.00TL", style: TextStyle(fontSize: 15),),
                                  ],
                                ),
                                const Divider(),
                                Row(
                                  children: [
                                    Text("Havale", style: TextStyle(fontSize: 15),),
                                    Spacer(),
                                    Text("0.00TL", style: TextStyle(fontSize: 15),),
                                  ],
                                ),
                                const Divider(),
                                Row(
                                  children: [
                                    Text("Diğer", style: TextStyle(fontSize: 15),),
                                    Spacer(),
                                    Text("0.00TL", style: TextStyle(fontSize: 15),),
                                  ],
                                ),
                                const Divider(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )



            ],
          ),
        ),
      ),
    );
  }
}
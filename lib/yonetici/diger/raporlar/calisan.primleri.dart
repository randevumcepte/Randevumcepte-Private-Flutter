 import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';



class CalisanPrimleri extends StatefulWidget {
  final dynamic isletmebilgi;
  const CalisanPrimleri({Key? key,required this.isletmebilgi}) : super(key: key);
  @override
  _CalisanPrimleriState createState() => _CalisanPrimleriState();
}

GlobalKey<FormState> myFormKey = new GlobalKey();

class _CalisanPrimleriState extends State<CalisanPrimleri> {
  DateTimeRange? myDateRange;

  void _submitForm() {
    final FormState? form = myFormKey.currentState;
    form!.save();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('tr', 'TR'),
      ],
      home: Scaffold(
        appBar: AppBar(
          title: Text("Prim Takibi",style: TextStyle(color: Colors.black),),
          backgroundColor: Colors.white,

          toolbarHeight: 60,

          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
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

                          Text("KASA", style: TextStyle(fontSize: 20),),

                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Text("Toplam", style: TextStyle(fontWeight: FontWeight.bold,fontSize: 18,color: Colors.black54),),
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
                                      Text("Hizmet gelirleri", style: TextStyle(fontSize: 15),),
                                      Spacer(),
                                      Text("0.00TL", style: TextStyle(fontSize: 15),),
                                    ],
                                  ),
                                  const Divider(),
                                  Row(
                                    children: [
                                      Text("Ürün satış gelirleri", style: TextStyle(fontSize: 15),),
                                      Spacer(),
                                      Text("0.00TL", style: TextStyle(fontSize: 15),),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    ],
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(

                    children: [
                      Text("Anıl Orbey", style: TextStyle(fontSize: 20),),

                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Text("Toplam", style: TextStyle(fontWeight: FontWeight.bold,fontSize: 18,color: Colors.black54),),
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
                                      Text("Hizmet gelirleri", style: TextStyle(fontSize: 15),),
                                      Spacer(),
                                      Text("0.00TL", style: TextStyle(fontSize: 15),),
                                    ],
                                  ),
                                  const Divider(),
                                  Row(
                                    children: [
                                      Text("Ürün satış gelirleri", style: TextStyle(fontSize: 15),),
                                      Spacer(),
                                      Text("0.00TL", style: TextStyle(fontSize: 15),),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    ],
                  ),
                ),



              ],
            ),
          ),
        ),
      ),
    );
  }
}
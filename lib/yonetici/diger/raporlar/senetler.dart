import 'package:flutter/material.dart';
import 'package:randevu_sistem/yonetici/diger/raporlar/senet_guncelle.dart';

import '../menu/senetler/senetekle.dart';
import '../menu/senetler/yazdir.dart';

class Senetler extends StatefulWidget {
  const Senetler({Key? key}) : super(key: key);

  @override
  _SenetlerState createState() =>
      _SenetlerState();
}

class _SenetlerState extends State<Senetler> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text("Senetler",style: TextStyle(color: Colors.black,fontSize: 20),),
          toolbarHeight: 60,
          backgroundColor: Colors.white,
          actions: [
            IconButton(
                icon: Icon(
                    Icons.add,
                    color: Colors.black,
                    size: 25.0),
                onPressed: (){Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => YeniSenet()),
                );}

            ),
          ],
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          )
      ),
      body: _buildListView(),
    );
  }ListView _buildListView() {
    return ListView(
      children: <Widget>[

        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  children: [
                    ListTile(
                      title: Text('Anıl Orbey',style: TextStyle( fontSize: 18),),
                      tileColor: Colors.black12,
                      onTap: () {
                        showModalBottomSheet(
                            context: context,
                            builder: (context) {
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Padding(
                                    padding: const EdgeInsets.all(15.0),
                                    child: Column(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(15.0),
                                          child: Row(
                                            children: [
                                              Text("Hizmet", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),),
                                              Spacer(),
                                              Text("Saç Kesimi")
                                            ],
                                          ),
                                        ),
                                        const Divider(height: 1.0,),
                                        Padding(
                                          padding: const EdgeInsets.all(15.0),
                                          child: Row(

                                            children: [
                                              Text("Ürün", style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15),),
                                              Spacer(),
                                              Text("Yok")
                                            ],
                                          ),
                                        ),
                                        const Divider(height: 1.0,),
                                        Padding(
                                          padding: const EdgeInsets.all(15.0),
                                          child: Row(

                                            children: [
                                              Text("Tutar", style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15),),
                                              Spacer(),
                                              Text("500 TL"),

                                            ],
                                          ),
                                        ),
                                        const Divider(height: 1.0,),

                                        Padding(
                                          padding: const EdgeInsets.all(15.0),
                                          child: Row(

                                            children: [
                                              Text("Ödeme Tarihi", style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15),),
                                              Spacer(),
                                              Text("12.05.2023")
                                            ],
                                          ),
                                        ),
                                        const Divider(
                                          height: 1.0,
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(15.0),
                                          child: Row(

                                            children: [
                                              Text("Vade", style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15),),
                                              Spacer(),
                                              Text("2 Ay")
                                            ],
                                          ),
                                        ),
                                        const Divider(
                                          height: 1.0,
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(15.0),
                                          child: Row(

                                            children: [
                                              Text("Senet 1", style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15),),
                                              Spacer(),
                                              Text("Ödendi")
                                            ],
                                          ),
                                        ),
                                        const Divider(
                                          height: 1.0,
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(15.0),
                                          child: Row(

                                            children: [
                                              Text("Senet 2", style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15),),
                                              Spacer(),
                                              Text("Ödenmedi")
                                            ],
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            const SizedBox(
                                              width: 50.00,
                                            ),
                                            ElevatedButton(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (context) => SenetGuncelle()),
                                                );
                                              },
                                              style: ElevatedButton.styleFrom(
                                                foregroundColor: Colors.white, backgroundColor: Colors.deepPurple,
                                                elevation: 10,  // Elevation
                                                shadowColor: Colors.purpleAccent, // Shadow Color
                                              ),
                                              child: const Text(
                                                'Düzenle',
                                                style: TextStyle(fontSize: 15),
                                              ),
                                            ),
                                            const SizedBox(
                                              width: 50.00,
                                            ),
                                            ElevatedButton(
                                              onPressed: () {
                                                /*Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (context) => PdfPreviewPage()),
                                                );*/
                                              },
                                              style: ElevatedButton.styleFrom(
                                                foregroundColor: Colors.white, backgroundColor: Colors.purple,
                                                elevation: 10,  // Elevation
                                                shadowColor: Colors.purpleAccent, // Shadow Color
                                              ),
                                              child: const Text(
                                                'Yazdır',
                                                style: TextStyle(fontSize: 15),
                                              ),
                                            ),
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            });
                      },
                    ),const Divider(height: 1.0,),

                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


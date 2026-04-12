import 'package:flutter/material.dart';

import '../yonetici/adisyonlar/musteri_detay.dart';

class MusteriRandevu extends StatefulWidget {
  const MusteriRandevu({Key? key}) : super(key: key);

  @override
  _MusteriRandevuState createState() =>
      _MusteriRandevuState();
}

class _MusteriRandevuState extends State<MusteriRandevu> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildListView(),
    );
  }ListView _buildListView() {
    return ListView(
      children: <Widget>[

        Column(
          children: [
            const Divider(),
              Column(
                children: [
                      ListTile(
                        title: Text('05.05.2023',style: TextStyle( fontSize: 20),),
                        tileColor: Colors.black12,
                        trailing: Icon(Icons.keyboard_arrow_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => MusteriAdisyon()),
                          );
                        },
                      ),
                      const Divider(),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(

                            children: [
                              Text("Durum", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),),
                              Spacer(),
                              Text("Onaylı")
                            ],
                          ),
                        ),
                        const Divider(),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(

                            children: [
                              Text("Hizmet", style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15),),
                              Spacer(),
                              Text("Manikür")
                            ],
                          ),
                        ),
                        const Divider(),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(

                            children: [
                              Text("Çalışan", style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15),),
                              Spacer(),
                              Text("Cevocey,"),
                              Text("Anıl Orbey"),
                            ],
                          ),
                        ),
                        const Divider(),

                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(

                            children: [
                              Text("Ödeme", style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15),),
                              Spacer(),
                              Text("0 TL")
                            ],
                          ),
                        ),
                      ],
                    ),
                  )




                ],
              ),

            const Divider(),

          ],
              ),


      ],
    );
  }
}


import 'package:flutter/material.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:randevu_sistem/yonetici/diger/raporlar/urun_edit.dart';
class UrunSatislari extends StatefulWidget {
  const UrunSatislari({Key? key}) : super(key: key);

  @override
  _UrunSatislariState createState() =>
      _UrunSatislariState();
}

class _UrunSatislariState extends State<UrunSatislari> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Ürün Satışları",style: TextStyle(color: Colors.black),),
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
      ),
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
                  title: Text('Ürünüm',style: TextStyle( fontSize: 20),),
                  trailing: Icon(Icons.keyboard_arrow_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => Urunedit()),
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(

                          children: [
                            Text("Adet", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),),
                            Spacer(),
                            Text("1")
                          ],
                        ),
                      ),
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(

                          children: [
                            Text("Tutar", style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15),),
                            Spacer(),
                            Text("44 TL")
                          ],
                        ),
                      ),
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(

                          children: [
                            Text("Ödeme Şekli", style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15),),
                            Spacer(),
                            Text("Kredi Kartı"),

                          ],
                        ),
                      ),
                      const Divider(),

                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(

                          children: [
                            Text("Müşteri", style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15),),
                            Spacer(),
                            Text("Ferdi Korkmaz")
                          ],
                        ),

                      ),
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(

                            children: [
                              Text("Satıcı", style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15),),
                              Spacer(),
                              Text("Çağlar Filiz")
                            ]
                        ),

                      ),
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(

                          children: [
                            Text("Tarih", style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15),),
                            Spacer(),
                            Text("05.05.2023")
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

        const Divider(),


      ],
    );
  }
}


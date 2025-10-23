import 'package:flutter/material.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';

import 'masraf_edit.dart';



class Masraflar extends StatefulWidget {
  final dynamic isletmebilgi;
  const Masraflar({Key? key,required this.isletmebilgi}) : super(key: key);

  @override
  _MasraflarState createState() =>
      _MasraflarState();
}

class _MasraflarState extends State<Masraflar> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Masraflar",style: TextStyle(color: Colors.black),),
        backgroundColor: Colors.white,
        toolbarHeight: 60,
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
                Dismissible(key: UniqueKey(),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (DismissDirection direction) async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('Silmek istediğinizden emin misiniz?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Hayır'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Evet'),
                            )
                          ],
                        );
                      },
                    );

                    return confirmed;
                  },
                  background: const ColoredBox(
                    color: Colors.red,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Icon(Icons.delete, color: Colors.white),
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        title: Text('05.05.2023',style: TextStyle( fontSize: 20),),
                        trailing: Icon(Icons.keyboard_arrow_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => Masrafedit(isletmebilgi: widget.isletmebilgi,)),
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
                                  Text("Kategori", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),),
                                  Spacer(),
                                  Text("Diğer")
                                ],
                              ),
                            ),
                            const Divider(),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(

                                children: [
                                  Text("Açıklama", style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15),),
                                  Spacer(),
                                  Text("Deneme")
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
                                  Text("50.00TL"),

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
                                  Text("Kredi Kartı")
                                ],
                              ),
                            ),
                            const Divider(),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(

                                children: [
                                  Text("Harcayan", style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15),),
                                  Spacer(),
                                  Text("Cevocey")
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

            const Divider(),

          ],
        ),

        const Divider(),


      ],
    );
  }
}


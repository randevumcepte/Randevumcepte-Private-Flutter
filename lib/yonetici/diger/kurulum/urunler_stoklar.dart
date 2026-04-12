import 'package:flutter/material.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';

import 'Urunler/urun_edit.dart';
import 'Urunler/yeni_urun.dart';





class UrunlerStoklar extends StatefulWidget {
  final dynamic isletmebilgi;
  const UrunlerStoklar({Key? key,required this.isletmebilgi}) : super(key: key);

  @override
  _UrunlerStoklarState createState() =>
      _UrunlerStoklarState();
}

class _UrunlerStoklarState extends State<UrunlerStoklar> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Ürünler ve Stoklar",style: TextStyle(color: Colors.black),),
        backgroundColor: Colors.white,
        toolbarHeight: 60,

        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.add,
              color: Colors.black,
              size: 25.0,),

            onPressed: (){
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => YeniUrunEkle(isletmebilgi: widget.isletmebilgi,)),
              );
            },

          ),
          if (widget.isletmebilgi["demo_hesabi"].toString() == "1")
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: SizedBox(
              width: 90, // <-- Your width
              child: YukseltButonu(isletme_bilgi: widget.isletmebilgi,)
            ),
          ),
        ],),
      body: _buildListView(),
    );
  }

  ListView _buildListView(){
    return ListView(
      children: <Widget>[
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
                    leading: Icon(Icons.filter_list_outlined),
                    title: Text('Ürünüm'),
                    trailing: Icon(Icons.keyboard_arrow_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => UrunEdit()),
                      );
                    },
                  ),                ],
              ),


            ),
          ],
        ),

      ],
    );


  }
}

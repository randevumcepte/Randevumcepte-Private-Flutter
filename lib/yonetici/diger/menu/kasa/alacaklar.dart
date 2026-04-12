import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';

import '../../../../Frontend/altyuvarlakmenu.dart';
import '../../../adisyonlar/adisyonpage.dart';
import '../../../adisyonlar/musteri_detay.dart';
import '../../../dashboard/deneme.dart';
import '../../../adisyonlar/yeniadisyon.dart';
import '../musteriler/yeni_musteri.dart';


class Alacaklar extends StatefulWidget {
  final dynamic isletmebilgi;
  Alacaklar({Key? key,required this.isletmebilgi}) : super(key: key);
  @override
  _AlacaklarState createState() => _AlacaklarState();
}

class _AlacaklarState extends State<Alacaklar> {
  List<Map<String, dynamic>> data = [
    {'Müşteri': 'Cevriye Güleç', 'icerik': 'İmplant İmplant tedavisi Ağız bakım suyu', 'ptarih': '14.10.22023','icon': Icons.chevron_right},
    {'Müşteri': 'Anıl Orbey', 'icerik': 'İmplant İmplant tedavisi Ağız bakım suyu', 'ptarih': '14.10.22023','icon': Icons.chevron_right},
    {'Müşteri': 'Çağlar Filiz', 'icerik': 'İmplant İmplant tedavisi Ağız bakım suyu', 'ptarih': '14.10.22023','icon': Icons.chevron_right},


  ];


  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      //floatingActionButton: AltYuvarlakYeniEkleMenu(isletme_bilgi:widget.isletmebilgi),
      appBar: AppBar(
        title: Text('Alacaklar',style: TextStyle(color: Colors.black,fontSize: 18),),
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

        toolbarHeight: 60,

        backgroundColor: Colors.white,




      ),

      body:
      SingleChildScrollView(
        child: Container(

          width: 500,
          child: InteractiveViewer(
            scaleEnabled: false,
            child: DataTable(
              columnSpacing: 10,
              showCheckboxColumn: false,
              columns: [
                DataColumn(label: Expanded(child: Text('Müşteri'))),
                DataColumn(label: Expanded(child: Text('Hizmet&Ürün&Paket'))),
                DataColumn(label: Expanded(child: Text('Ödeme Tarihi'))),
              ],
              rows: data.map((item) {

                // Determine whether to show the icon
                return  DataRow(
                  cells: [
                    DataCell(
                      Container(child: Text(item['Müşteri'])),
                    ),
                    DataCell(
                      Container(child: Text(item['icerik'])),
                    ),

                    DataCell(
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [

                          ElevatedButton(onPressed: (){},style: ElevatedButton.styleFrom(backgroundColor:Colors.purple[800],
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
                              minimumSize: Size(80, 20)

                          )

                              ,child: Text(item['ptarih'],style: TextStyle(color: Colors.white),)),

                          Icon(item['icon']),



                        ],
                      ),
                    ),
                  ],
                  onSelectChanged: (_) {
                    _showDetailsDialog(context, item);
                  },
                );
              }


              )
                  .toList(),



            ),
          ),
        ),
      ),


    );
  }

  void _showDetailsDialog(BuildContext context, Map<String, dynamic> item) {
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          insetPadding: EdgeInsets.zero,
          content: Container(

            height: 250,
            width: 280,
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[

                Positioned(
                  right: -40,
                  top: -40,
                  child: InkResponse(
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                    child: const CircleAvatar(
                      backgroundColor: Colors.red,
                      child: Icon(Icons.close),
                    ),
                  ),
                ),

                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: <Widget>[
                      SizedBox(height: 20,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Anıl Orbey',style: TextStyle(fontWeight: FontWeight.bold),),
                        ],
                      ),
                      Divider(color: Colors.black,
                        height: 10,),
                      Row(
                        children: [
                          Text('Oluşturulma Tarih'),SizedBox(width: 20,),
                          Text(':'),
                          Text(' 02.09.2023')
                        ],
                      ),
                      Row(
                        children: [
                          Text('Hizmet&Ürün&Paket'),
                          SizedBox(width: 2,),
                          Text(': '),
                          Expanded(child: Text('İmplant İmplant tedavisi Ağız bakım suyu'))
                        ],

                      ),
                      Row(
                        children: [
                          Text('Tutar (₺)'),SizedBox(width: 86,),
                          Text(':'),
                          Text(' 1000')
                        ],

                      ),
                      Row(
                        children: [
                          Text('Ödeme Tarih'),SizedBox(width: 56,),
                          Text(':'),
                          Text(' 02.10.2023')
                        ],
                      ),

                      Divider(color: Colors.black,
                        height: 10,),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(onPressed: (){
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => MusteriAdisyon()),
                            );
                          }, child:
                          Text('Tahsil Et'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple[800],
                                elevation: 5,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5.0)
                                ),
                                minimumSize: Size(130,30)
                            ),
                          ),
                        ],
                      ),

                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );


  }
}

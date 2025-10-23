import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:randevu_sistem/yonetici/diger/menu/seanstakibi/seansdetay.dart';

import '../../anasayfa/anasayfa.dart';



class MusteriSeanslari extends StatefulWidget {
  MusteriSeanslari({Key? key}) : super(key: key);
  @override
  _MusteriSeanslariState createState() => _MusteriSeanslariState();
}

class _MusteriSeanslariState extends State<MusteriSeanslari> {
  List<Map<String, dynamic>> data = [
    {'paketadi': 'Dermapen Tedavisi','toplam':'5', 'beklenen': '4', 'gelen': '1','Kalan':'0','icon': Icons.chevron_right},
    {'paketadi': 'İmplant Tedavisi', 'toplam':'5', 'beklenen': '3', 'gelen': '2','Kalan':'1','icon': Icons.chevron_right},
    {'paketadi': 'Dermapen Tedvisi','toplam':'5',  'beklenen': '5', 'gelen': '0','Kalan':'5','icon': Icons.chevron_right},


  ];

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(

      floatingActionButton: WhatsAppFAB(),
      appBar:AppBar(
        title:Text('Seanslarım',style: TextStyle(color: Colors.black),),

        toolbarHeight: 60,

        backgroundColor: Colors.white,




      ),
      body:
      SingleChildScrollView(
        child: Container(

          width: 600,
          child: InteractiveViewer(
            scaleEnabled: false,
            child: DataTable(
              columnSpacing: 1,

              showCheckboxColumn: false,
              columns: [
                DataColumn(label: Expanded(child: Text('Paket Adı'))),

                DataColumn(label: Expanded(child: Padding(
                  padding: const EdgeInsets.only(left: 50),
                  child: Text('Seans Detayları'),
                ))),

              ],
              rows: data.map((item) {

                // Determine whether to show the icon
                return  DataRow(
                  cells: [
                    DataCell(
                      Container(width:80,child: Text(item['paketadi'])),

                    ),

                    DataCell(
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          ElevatedButton(onPressed: (){},style: ElevatedButton.styleFrom(backgroundColor:Colors.purple[800],
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
                              minimumSize: Size(55, 20)

                          )

                              ,child: Row(
                                children: [
                                  Text(item['toplam'],style: TextStyle(color: Colors.white),),

                                  Icon(Icons.add,color: Colors.white,size: 15,)
                                ],
                              )),
                          SizedBox(width: 3,),
                          ElevatedButton(onPressed: (){},style: ElevatedButton.styleFrom(backgroundColor:Colors.yellow[600],
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
                              minimumSize: Size(50, 20)

                          )

                              ,child: Row(
                                children: [
                                  Text(item['beklenen'],style: TextStyle(color: Colors.black),),

                                  Icon(Icons.calendar_month,color: Colors.black,size: 15,)
                                ],
                              )),
                          SizedBox(width: 3,),
                          ElevatedButton(onPressed: (){},style: ElevatedButton.styleFrom(backgroundColor:Colors.green,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
                              minimumSize: Size(55, 20)

                          )

                              ,child: Row(
                                children: [
                                  Text(item['gelen'],style: TextStyle(color: Colors.white),),

                                  Icon(Icons.check,size: 15,)
                                ],
                              )),
                          SizedBox(width: 3,),
                          ElevatedButton(onPressed: (){},style: ElevatedButton.styleFrom(backgroundColor:Colors.red[600],
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
                              minimumSize: Size(55, 20)

                          )

                              ,child: Row(
                                children: [
                                  Text(item['Kalan'],style: TextStyle(color: Colors.white),),

                                  Icon(Icons.close_outlined,size: 15,)
                                ],
                              )),

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

            height: 180,
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
                    crossAxisAlignment: CrossAxisAlignment.center,

                    children: <Widget>[
                      SizedBox(height: 20,),
                      Text('Anıl Orbey',style: TextStyle(fontWeight: FontWeight.bold),),
                      Divider(color: Colors.black,
                        height: 10,),
                      Row(
                        children: [
                          Text('Seans Başlangıcı'),SizedBox(width: 2,),
                          Text(':'),
                          Text(' 12.10.2023')
                        ],
                      ),
                      Row(
                        children: [
                          Text('Paket Adı'),
                          SizedBox(width: 56,),
                          Text(': '),
                          Expanded(child: Text('İmplant tedavisi'))
                        ],

                      ),
                      Row(
                        children: [
                          Text('Toplam Ücret(₺)'),SizedBox(width: 8,),
                          Text(':'),
                          Text(' 1.000,00')
                        ],

                      ),
                      Row(
                        children: [
                          Text('Ödenen(₺)'),SizedBox(width: 49,),
                          Text(':'),
                          Text(' 0,00')
                        ],
                      ),
                      Row(
                        children: [
                          Text('Kalan(₺)'),SizedBox(width: 45,),
                          SizedBox(width: 18,),
                          Text(':'),
                          Text(' 1.000,00')
                        ],

                      ),
                      Divider(color: Colors.black,
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
class WhatsAppFAB extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 65.0,
      height: 65.0,
      child: FloatingActionButton(
        onPressed: () {
          // Handle the FAB press
          WhatsAppOpener.openWhatsApp('+902323130028', '');
        },
        backgroundColor: Color(0xFF25D366), // WhatsApp green color
        child: SvgPicture.asset(
          'images/wp5.svg', // Replace with the actual path to your WhatsApp SVG icon
          width: 30,
          height: 40,
          color: Colors.white,
        ),
      ),
    );
  }
}

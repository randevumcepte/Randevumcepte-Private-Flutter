import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../anasayfa/anasayfa.dart';






class MusteriHarcamalarDashboard extends StatefulWidget {
  MusteriHarcamalarDashboard({Key? key}) : super(key: key);
  @override
  _MusteriHarcamalarDashboardState createState() => _MusteriHarcamalarDashboardState();
}

class _MusteriHarcamalarDashboardState extends State<MusteriHarcamalarDashboard> {
  List<Map<String, dynamic>> data = [
    { 'harcamaturu': 'Şampuan', 'Fiyat': '1000','odenen': '500','Kalan':'500','icon': Icons.chevron_right},
    {'harcamaturu': 'Bayram Paketi', 'Fiyat': '1500','odenen': '1000','Kalan':'500','icon': Icons.chevron_right},
    {'harcamaturu': 'Duş Jeli', 'Fiyat': '105000','odenen': '100000','Kalan':'5000','icon': Icons.chevron_right},


  ];


  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      floatingActionButton: WhatsAppFAB(),

      appBar: AppBar(
        title: Text('Harcamalarım',style: TextStyle(color:Colors.black),),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
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
                DataColumn(label: Expanded(child: Text('Harcama İçeriği'))),
                DataColumn(label: Expanded(child: Text('Fiyat'))),
                DataColumn(label: Expanded(child: Text('Ödenen'))),
                DataColumn(label: Expanded(child: Text('Kalan'))),
              ],
              rows: data.map((item) {

                // Determine whether to show the icon
                return  DataRow(
                  cells: [

                    DataCell(
                      Container(width:60,child: Text(item['harcamaturu'].toString())),
                    ),

                    DataCell(
                      ElevatedButton(onPressed: (){},style: ElevatedButton.styleFrom(backgroundColor:Colors.purple[800],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
                          minimumSize: Size(80, 20)

                      )

                          ,child: Text(item['Fiyat'],style: TextStyle(color: Colors.white),)),
                    ),
                    DataCell(
                      ElevatedButton(onPressed: (){ },style: ElevatedButton.styleFrom(backgroundColor:Colors.green,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
                          minimumSize: Size(80, 20)

                      )

                          ,child: Text(item['odenen'],style: TextStyle(color: Colors.white),)),
                    ),
                    DataCell(
                      Row(
                        children: [
                          ElevatedButton(onPressed: (){ },style: ElevatedButton.styleFrom(backgroundColor:Colors.red[600],
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
                              minimumSize: Size(80, 20)

                          )

                              ,child: Text(item['Kalan'],style: TextStyle(color: Colors.white),)),


                        ],
                      ),
                    ),
                  ],


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

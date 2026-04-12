import 'package:flutter/material.dart';


class GiderlerDashboard extends StatefulWidget {
  GiderlerDashboard({Key? key}) : super(key: key);
  @override
  _GiderlerDashboardState createState() => _GiderlerDashboardState();
}

class _GiderlerDashboardState extends State<GiderlerDashboard> {
  List<Map<String, dynamic>> data = [
    {'Harcayan': 'Cevriye Güleç', 'Tarih': '02.09.2023', 'Fiyat': '1000','icon': Icons.chevron_right},
    {'Harcayan': 'Anıl Orbey', 'Tarih': '02.09.2023', 'Fiyat': '1500','icon': Icons.chevron_right},
    {'Harcayan': 'Çağlar Filiz', 'Tarih': '02.11.2023', 'Fiyat': '510000','icon': Icons.chevron_right},


  ];


  @override
  Widget build(BuildContext context) {

    return Scaffold(



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
                DataColumn(label: Expanded(child: Text('Harcayan'))),
                DataColumn(label: Expanded(child: Text('Tarih'))),
                DataColumn(label: Expanded(child: Text('Fiyat'))),
              ],
              rows: data.map((item) {

                // Determine whether to show the icon
                return  DataRow(
                  cells: [
                    DataCell(
                      Container(width:95,child: Text(item['Harcayan'])),
                    ),
                    DataCell(
                      Container(width:115,child: Text(item['Tarih'])),
                    ),

                    DataCell(
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [

                          ElevatedButton(onPressed: (){},style: ElevatedButton.styleFrom(backgroundColor:Colors.red[600],
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
                              minimumSize: Size(80, 20)

                          )

                              ,child: Text(item['Fiyat'],style: TextStyle(color: Colors.white),)),

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

            height: 190,
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
                          Text('Tarih'),SizedBox(width: 83,),
                          Text(':'),
                          Text(' 02.09.2023')
                        ],
                      ),
                      Row(
                        children: [
                          Text('Ödeme Yöntemi'),
                          SizedBox(width: 5,),
                          Text(': '),
                          Expanded(child: Text('Nakit'))
                        ],

                      ),
                      Row(
                        children: [
                          Text('Fiyat'),SizedBox(width: 85,),
                          Text(':'),
                          Text(' 1000')
                        ],

                      ),

                      Divider(color: Colors.black,
                        height: 10,),


                      Text('Açıklama',style: TextStyle(fontWeight: FontWeight.bold),),
                      Text('Kİra Ödemesi')



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

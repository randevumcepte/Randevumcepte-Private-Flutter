import 'package:flutter/material.dart';


class ToplamKasaDashboard extends StatefulWidget {
  ToplamKasaDashboard({Key? key}) : super(key: key);
  @override
  _ToplamKasaDashboardState createState() => _ToplamKasaDashboardState();
}

class _ToplamKasaDashboardState extends State<ToplamKasaDashboard> {
  List<Map<String, dynamic>> gelirler = [
    {'Müşteri/Harcayan': 'Cevriye Güleç', 'Tarih': DateTime(2023,10,15), 'Fiyat': '1000','tur':'gelirler','icon': Icons.chevron_right},
    {'Müşteri/Harcayan': 'Anıl Orbey', 'Tarih': DateTime(2023,09,15), 'Fiyat': '1500','tur':'gelirler','icon': Icons.chevron_right},
    {'Müşteri/Harcayan': 'Çağlar Filiz', 'Tarih': DateTime(2023,11,15), 'Fiyat': '510000','tur':'gelirler','icon': Icons.chevron_right},


  ];
  List<Map<String, dynamic>> giderler = [
    {'Müşteri/Harcayan': 'Cevriye Güleç', 'Tarih': DateTime(2023,08,15), 'Fiyat': '1000','tur':'giderler','icon': Icons.chevron_right},
    {'Müşteri/Harcayan': 'Anıl Orbey', 'Tarih': DateTime(2023,10,10), 'Fiyat': '1500','tur':'giderler','icon': Icons.chevron_right},
    {'Müşteri/Harcayan': 'Çağlar Filiz', 'Tarih': DateTime(2023,09,09), 'Fiyat': '510000','tur':'giderler','icon': Icons.chevron_right},


  ];


  List<Map<String, dynamic>> toplam = [];
  @override
  Widget build(BuildContext context) {

toplam.addAll(gelirler);
toplam.addAll(giderler);
toplam.sort((a,b)=>b['Tarih'].compareTo(a['Tarih']));

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
                DataColumn(label: Expanded(child: Text('Müşteri/Harcayan'))),
                DataColumn(label: Expanded(child: Text('Tarih'),),numeric: true,),
                DataColumn(label: Expanded(child: Text('Fiyat'))),
              ],
              rows:toplam.map((item) {
                final status = item['tur'] ?? '';
                final ageColor = (item['tur'] == 'gelirler')
                    ? Colors.green
                    : Colors.red[600];
                final formattedDate =
                    "${item['Tarih'].day}.${item['Tarih'].month}.${item['Tarih'].year}";


                return  DataRow(
                  cells: [
                    DataCell(
                      Container(width:120,child: Text(item['Müşteri/Harcayan'])),
                    ),
                    DataCell(
                      Container(width:90,child: Text(formattedDate)),
                    ),

                    DataCell(
                      GestureDetector(
                        onTap: () {
                          _showDetailsDialog(context, item['gelirler'], status);
                        },
                        child: Row(

                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [

                            ElevatedButton(onPressed: (){
                            },style: ElevatedButton.styleFrom(backgroundColor:ageColor,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
                                minimumSize: Size(80, 20)

                            )

                                ,child: Text(item['Fiyat'],style: TextStyle(color: Colors.white),)),

                            Icon(item['icon']),



                          ],
                        ),
                      ),
                    ),
                  ],
                  onSelectChanged: (_) {
                    _showDetailsDialog(context, item,status);
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

  void _showDetailsDialog(BuildContext context, Map<String, dynamic> item,String status) {
    final _formKey = GlobalKey<FormState>();
if(status=='giderler') {
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
                    SizedBox(height: 5,),
                    Text('Gider', style: TextStyle(fontWeight: FontWeight.bold,
                        fontSize: 18),),
                    SizedBox(height: 5,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Anıl Orbey',
                          style: TextStyle(fontWeight: FontWeight.bold),),
                      ],
                    ),
                    Divider(color: Colors.black,
                      height: 10,),
                    Row(
                      children: [
                        Text('Tarih'), SizedBox(width: 83,),
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
                        Text('Fiyat'), SizedBox(width: 85,),
                        Text(':'),
                        Text(' 1000')
                      ],

                    ),

                    Divider(color: Colors.black,
                      height: 10,),


                    Text('Açıklama', style: TextStyle(fontWeight: FontWeight
                        .bold),),
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
    if(status=='gelirler') {
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
                        SizedBox(height: 5,),
                        Text('Gelir', style: TextStyle(fontWeight: FontWeight.bold,
                            fontSize: 18),),
                        SizedBox(height: 5,),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Anıl Orbey',
                              style: TextStyle(fontWeight: FontWeight.bold),),
                          ],
                        ),
                        Divider(color: Colors.black,
                          height: 10,),
                        Row(
                          children: [
                            Text('Tarih'), SizedBox(width: 83,),
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
                            Text('Fiyat'), SizedBox(width: 85,),
                            Text(':'),
                            Text(' 1000')
                          ],

                        ),

                        Divider(color: Colors.black,
                          height: 10,),


                        Text('Notlar', style: TextStyle(fontWeight: FontWeight
                            .bold),),
                        Text('tek sefer tahsilat')


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
}

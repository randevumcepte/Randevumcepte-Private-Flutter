import 'package:flutter/material.dart';

import '../../../../../Frontend/altyuvarlakmenu.dart';
import '../../seanstakibi/seansdetay.dart';
class IslemlerveSeanslar extends StatefulWidget {
  final dynamic isletmebilgi;
  IslemlerveSeanslar({Key? key,required this.isletmebilgi}) : super(key: key);
  @override
  _IslemlerveSeanslarState createState() => _IslemlerveSeanslarState();
}

class _IslemlerveSeanslarState extends State<IslemlerveSeanslar> {
  List<Map<String, dynamic>> data = [
    {'Tarih': DateTime(2023,09,15), 'beklenen': '4', 'gelen': '1','Kalan':'3','icon': Icons.chevron_right},
    {'Tarih': DateTime(2023,10,15), 'beklenen': '3', 'gelen': '2','Kalan':'1','icon': Icons.chevron_right},
    {'Tarih': DateTime(2023,11,15), 'beklenen': '5', 'gelen': '0','Kalan':'5','icon': Icons.chevron_right},


  ];

  @override
  Widget build(BuildContext context) {
    data.sort((a,b)=>b['Tarih'].compareTo(a['Tarih']));
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      // floatingActionButton: AltYuvarlakYeniEkleMenu(isletme_bilgi: widget.isletmebilgi,),

      appBar:AppBar(
        title:Text('Seans Takibi',style: TextStyle(color: Colors.black),),
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

          width: 600,
          child: InteractiveViewer(
            scaleEnabled: false,
            child: DataTable(
              columnSpacing: 0.0,

              showCheckboxColumn: false,
              columns: [
                DataColumn(label: Expanded(child: Text('Seans Başlangıcı clmdjlbcjlzcbzjck'))),
                DataColumn(label: Expanded(child: Text('',style: TextStyle(color: Colors.white),))),
                DataColumn(label: Expanded(child: Text('Seans Detayılarınkk'))),
                DataColumn(label: Expanded(child: Text(''))),
              ],
              rows: data.map((item) {
                final formattedDate =
                    "${item['Tarih'].day}.${item['Tarih'].month}.${item['Tarih'].year}";
                // Determine whether to show the icon
                return  DataRow(
                  cells: [
                    DataCell(
                      Text(formattedDate),

                    ),
                    DataCell(
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Container(
                            width: 60,
                            child: ElevatedButton(onPressed: (){},style: ElevatedButton.styleFrom(backgroundColor:Colors.yellow[600],
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
                                minimumSize: Size(50, 20)

                            )

                                ,child: Row(
                                  children: [
                                    Text(item['beklenen'],style: TextStyle(color: Colors.black),),
                                    SizedBox(width: 5,),
                                    Icon(Icons.calendar_month,color: Colors.black,size: 15,)
                                  ],
                                )),
                          ),
                        ],
                      ),

                    ),
                    DataCell(
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 60,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                ElevatedButton(onPressed: (){},style: ElevatedButton.styleFrom(backgroundColor:Colors.green,  foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
                                    minimumSize: Size(50, 20)

                                )

                                    ,child: Row(
                                      children: [
                                        Text(item['gelen'],style: TextStyle(color: Colors.white),),
                                        SizedBox(width: 5,),
                                        Icon(Icons.check,size: 15,)
                                      ],
                                    )),
                              ],
                            ),
                          ),
                        ],
                      ),

                    ),
                    DataCell(
                      Container(

                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [

                            ElevatedButton(onPressed: (){},style: ElevatedButton.styleFrom(backgroundColor:Colors.red[600],  foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
                                minimumSize: Size(60, 20)

                            )

                                ,child: Row(
                                  children: [
                                    Text(item['Kalan'],style: TextStyle(color: Colors.white),),
                                    SizedBox(width: 5,),
                                    Icon(Icons.close_outlined,size: 15,)
                                  ],
                                )),

                            Icon(item['icon']),


                          ],
                        ),
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
                    crossAxisAlignment: CrossAxisAlignment.center,

                    children: <Widget>[

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
                        height: 30,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(onPressed: (){
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => SeansDetay()),
                            );
                          }, child:
                          Text('Seans Detayları'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple[800],
                                foregroundColor: Colors.white,
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

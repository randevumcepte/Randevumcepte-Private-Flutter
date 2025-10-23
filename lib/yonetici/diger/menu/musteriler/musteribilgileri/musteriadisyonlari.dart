import 'package:flutter/material.dart';

import '../../../../../Frontend/altyuvarlakmenu.dart';
import '../../../../adisyonlar/musteri_detay.dart';



class MusteriAdiayonlari extends StatefulWidget {
  final dynamic isletmebilgi;
  MusteriAdiayonlari({Key? key,required this.isletmebilgi}) : super(key: key);
  @override
  _MusteriAdiayonlariState createState() => _MusteriAdiayonlariState();
}

class _MusteriAdiayonlariState extends State<MusteriAdiayonlari> {
  List<Map<String, dynamic>> data = [
    {'Tarih': DateTime(2023,10,15),  'Toplam': '400', 'Ödenen': '200','Kalan':'200','icon': Icons.chevron_right},
    {'Tarih': DateTime(2023,09,15),  'Toplam': '1000', 'Ödenen': '500','Kalan':'500','icon': Icons.chevron_right},
    {'Tarih': DateTime(2023,11,15),  'Toplam': '600', 'Ödenen': '0','Kalan':'600','icon': Icons.chevron_right},


  ];

  @override
  Widget build(BuildContext context) {
    data.sort((a,b)=>b['Tarih'].compareTo(a['Tarih']));
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      //floatingActionButton: AltYuvarlakYeniEkleMenu(isletme_bilgi: widget.isletmebilgi,),

      appBar: AppBar(
        title: Text('Adisyonlar',style: TextStyle(color: Colors.black),),
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
                DataColumn(label: Expanded(child: Text('Müşteri'))),
                DataColumn(label: Expanded(child: Text('Toplam ₺'))),
                DataColumn(label: Expanded(child: Text('Ödenen ₺'))),
                DataColumn(label: Expanded(child: Text('Kalan ₺'))),
              ],
              rows: data.map((item) {
                final formattedDate =
                    "${item['Tarih'].day}.${item['Tarih'].month}.${item['Tarih'].year}";
                // Determine whether to show the icon
                return  DataRow(
                  cells: [
                    DataCell(
                      Container(width:85,child: Text(formattedDate)),
                      onTap:(){
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => MusteriAdisyon(),
                          ),
                        );
                      },
                    ),
                    DataCell(
                      ElevatedButton(onPressed: (){},style: ElevatedButton.styleFrom(backgroundColor:Colors.purple[800],  foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
                          minimumSize: Size(65, 20)

                      )

                          ,child: Text(item['Toplam'],style: TextStyle(color: Colors.white),)),
                      onTap:(){
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => MusteriAdisyon(),
                          ),
                        );
                      },
                    ),
                    DataCell(
                      ElevatedButton(onPressed: (){},style: ElevatedButton.styleFrom(backgroundColor:Colors.green,  foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
                          minimumSize: Size(65, 20)

                      )

                          ,child: Text(item['Ödenen'],style: TextStyle(color: Colors.white),)),
                      onTap:(){
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => MusteriAdisyon(),
                          ),
                        );
                      },
                    ),
                    DataCell(
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [

                          ElevatedButton(onPressed: (){},style: ElevatedButton.styleFrom(backgroundColor:Colors.red[600],  foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
                              minimumSize: Size(65, 20)

                          )

                              ,child: Text(item['Kalan'],style: TextStyle(color: Colors.white),)),

                          Icon(item['icon']),


                        ],
                      ),
                      onTap:(){
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => MusteriAdisyon(),
                          ),
                        );
                      },
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

  void _showDetailsDialog(BuildContext context, Map<String, dynamic> item) {
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          insetPadding: EdgeInsets.zero,
          content: Container(

            height: 280,
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
                          Text('Telefon'),SizedBox(width: 22,),
                          Text(':'),
                          Text(' 5316237563')
                        ],
                      ),
                      Row(
                        children: [
                          Text('Hizmet'),
                          SizedBox(width: 25,),
                          Text(': '),
                          Expanded(child: Text('Ağda (tüm vücut)(Cevriye Güleç)'))
                        ],

                      ),
                      Row(
                        children: [
                          Text('Zaman'),SizedBox(width: 26,),
                          Text(':'),
                          Text(' 07.09.2023 17:45')
                        ],

                      ),
                      Row(
                        children: [
                          Text('Oluşturan'),SizedBox(width: 7.5,),
                          Text(':'),
                          Text(' Elif Çetin')
                        ],
                      ),
                      Row(
                        children: [
                          Text('Durum'),SizedBox(width: 10,),
                          SizedBox(width: 18,),
                          Text(':'),
                          Text(' Onaylı')
                        ],

                      ),
                      Divider(color: Colors.black,
                        height: 10,),
                      Row(

                        children: [
                          ElevatedButton(onPressed: (){}, child:
                          Text('Düzenle'),
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
                          SizedBox(width: 15,),
                          ElevatedButton(onPressed: (){}, child:
                          Text('İptal Et'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
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
                      Row(
                        children: [
                          ElevatedButton(onPressed: (){}, child:
                          Text('Gelmedi'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                elevation: 5,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5.0)
                                ),
                                minimumSize: Size(130,30)
                            ),
                          ),
                          SizedBox(width: 15,),
                          ElevatedButton(onPressed: (){}, child:
                          Text('Geldi & Tahsilat'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                elevation: 5,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5.0)
                                ),
                                minimumSize: Size(20,30)
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

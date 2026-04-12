import 'package:flutter/material.dart';
import 'package:randevu_sistem/Frontend/sfdatatable.dart';
import 'package:randevu_sistem/yonetici/diger/menu/senetler/senetodeme.dart';

import '../../../../Models/senetler.dart';

class SenetVadeleri extends StatefulWidget {
  final Senet senet;
  final SenetDataSource senetdatasource;
  final String page;
  final String arama;
  const SenetVadeleri({Key? key,required this.senet,required this.senetdatasource, required this.page, required this.arama}) : super(key: key);

  @override
  _SenetVadeleriState createState() =>
      _SenetVadeleriState();
}

class _SenetVadeleriState extends State<SenetVadeleri> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text("Senet Vadeleri",style: TextStyle(color: Colors.black,fontSize: 18),),
        toolbarHeight: 60,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),

      ),
      body: _buildListView(),
    );
  }

  ListView _buildListView(){
    return ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: widget.senet.vadeler.length,
        itemBuilder: (BuildContext context, int index) {
          final vadeData =  widget.senet.vadeler[index];
          int vadeno = ++index;
          return Column(
            children: [
              SizedBox(height: 10,),
              ListTile(
                title: Row(
                  children: [
                    Text('Vade #'+ vadeno.toString() +' : '),
                    Text(vadeData['tutar'].toString()+' ₺',style: TextStyle(fontWeight: FontWeight.bold),),
                    Spacer(),
                    ElevatedButton(onPressed: (){


                    },style: vadeData['odendi'] == 1 ? ElevatedButton.styleFrom(backgroundColor:Colors.green,  foregroundColor: Colors.white,) : ElevatedButton.styleFrom(backgroundColor:Colors.red[600] ,  foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),

                        minimumSize: Size(105, 35)
                    )

                      ,child: Text(vadeData['odendi'] == 1 ? 'Ödendi': 'Ödenmedi',style: TextStyle(color: Colors.white),), ),
                  ],
                ),
                trailing: Icon(Icons.keyboard_arrow_right),
                onTap: () {
                  if(vadeData['odendi'] != 1)
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => SenetOdeme(vade: vadeData,senetdatasource: widget.senetdatasource,page: widget.page,arama: widget.arama,)),
                    );
                },
              ),
            ],
          );
        }

    );


  }
}

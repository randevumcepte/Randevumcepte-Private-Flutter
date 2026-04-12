import 'package:flutter/material.dart';

import '../diger/menu/senetler/yazdir.dart';
import 'satislar/tahsilat.dart';

class Odeme extends StatefulWidget {
  const Odeme({Key? key}) : super(key: key);

  @override
  _OdemeState createState() =>
      _OdemeState();
}

class _OdemeState extends State<Odeme> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildListView(),

    );
  }ListView _buildListView() {
    return ListView(
      children: <Widget>[

        Container(
          padding: EdgeInsets.only(top:15,left: 15,right: 15),
          child: Row(

            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [

              Text('Alacak Tutarı (₺)',style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),),
              Text('3.100,00',style: TextStyle(color: Colors.red[600],fontSize: 22,fontWeight: FontWeight.bold),)

            ],

          ),
        ),


        const Divider(),
        Container(
          padding: EdgeInsets.only(left: 15,right: 15,top: 10),
          child: Text('Adisyon Özeti',style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),),
        ),
        Divider(),
        Container(
          padding: EdgeInsets.only(left: 20,right: 20),
          child: Column(
            children: [
              Row(
                children: [
                  Text('Birim Fiyat (₺)',style: TextStyle(fontSize: 16),),
                  Spacer(),
                  Text('2.200,00',style: TextStyle(fontSize: 16),)
                ],
              ),
              Divider(),
              Row(
                children: [
                  Text('İndirim Tutarı (₺)',style: TextStyle(fontSize: 16),),
                  Spacer(),
                  Text('0,00',style: TextStyle(fontSize: 16),)
                ],
              ),
              Divider(),
              Row(
                children: [
                  Text('Tahsil Edilen Tutar (₺)',style: TextStyle(color: Colors.green,fontSize: 16),),
                  Spacer(),
                  Text('100,00',style: TextStyle(color: Colors.green,fontSize: 16),)
                ],
              ),
              Divider(),
              Row(
                children: [
                  Text('Tahsil Edilecek Kalan Tutar (₺)',style: TextStyle(color: Colors.red[600],fontSize: 16),),
                  Spacer(),
                  Text('3.000,00',style: TextStyle(color: Colors.red[600],fontSize: 16),)
                ],
              )
            ],
          ),

        ),
        Divider(),
        Container(
          padding: EdgeInsets.only(left: 15,right: 15,top: 15),
          child: Text('Ödeme Akışı',style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),),
        ),
        Divider(),
        Container(
          padding: EdgeInsets.only(left: 20,right: 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('1.Ödeme',style: TextStyle(fontSize: 16),),
                  Text('01.10.2023',style: TextStyle(fontSize: 16),),
                  Text('100,00',style: TextStyle(fontSize: 16),),
                  Text('Kredi Kartı',style: TextStyle(fontSize: 16),)
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 50,),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(onPressed: (){
              /*Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PdfPreviewPage(senet: Se,)),
              );*/
            }, child: Text('Senet Oluştur'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple[800],
                  minimumSize: Size(150, 40)
              ),
            ),
            ElevatedButton(onPressed: (){
              /*Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Tahsilat()),
              );*/
            }, child: Text('Tahsil Et'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: Size(150, 40)
              ),
            ),

          ],
        ),


      ],
    );
  }

}
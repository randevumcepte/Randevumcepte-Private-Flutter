import 'dart:convert';
import 'dart:developer';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:randevu_sistem/Models/kampanyalar.dart';
import 'package:randevu_sistem/Backend/backend.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:randevu_sistem/Frontend/altyuvarlakmenu.dart';
import '../../../../Backend/backend.dart';
import '../../../../Models/katilimcilar.dart';
import 'kampanyadetay.dart';
import 'kampanyaekle.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';


class Kampanyalar extends StatefulWidget {
  final dynamic isletmebilgi;
  Kampanyalar({Key? key,required this.isletmebilgi}) : super(key: key);
  @override
  _KampanyalarState createState() => _KampanyalarState();
}

class _KampanyalarState extends State<Kampanyalar> {
  bool  _isLoading= true;
  final List<String> randevuolusturma = [
    'Tümü',
    'Salon',
    'Web',
    'Uygulama',
  ];
  final List<String> randevudurum= [
    'Tümü',
    'Onay Bekleyen',
    'Onaylı',
    'Reddedilen',
    'müşteri tarafından iptal edilen',


  ];
  final List<String> randevutarih= [

    'Bugün',
    'Yarın',
    'Bu ay',
    'Önümüzdeki ay',
    'Bu yıl',
    'Önümüzdeki yıl',


  ];



  String? selectedrandevuolusturma = 'Tümü';
  TextEditingController randevuolusturmacontroller = TextEditingController();

  String? selectedrandevudurum = 'Tümü';
  TextEditingController randevudurumcontroller = TextEditingController();

  String? selectedrandevutarih = 'Bu yıl';
  TextEditingController randevutarihcontroller = TextEditingController();
  List<Kampanya> kampanyalar = [];


  @override
  void initState() {
    super.initState();

    _fetchData();
  }

  void _fetchData() async {

    try {

      setState(() {


        _isLoading= false;

      });
    } catch (e) {
      print('Error fetching data: $e');
    }
  }



  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(


      appBar: AppBar(
        title: Text('Reklam Yönetimi',style: TextStyle(color: Colors.black,fontSize: 18),),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),

        toolbarHeight: 60,
        actions: <Widget>[
          if (widget.isletmebilgi["demo_hesabi"].toString() == "1")
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: SizedBox(
              width: 100, // <-- Your width
              child: YukseltButonu(isletme_bilgi: widget.isletmebilgi,)
            ),
          ),



        ],
        backgroundColor: Colors.white,




      ),




      body: _isLoading
          ? Center(child: CircularProgressIndicator()) // Show loading indicator while data is loading
          :SingleChildScrollView(

        child: Container(
          child: InteractiveViewer(
            scaleEnabled: false,
            child: kampanyalar.isEmpty ? _buildEmptyTableMessage() : _buildDataTable(),
          ),
        ),
      ),
    );
  }

  Widget _buildDataTable() {
    final double width = MediaQuery.of(context).size.width-70;

    return DataTable(
      columnSpacing: 20,

      showCheckboxColumn: false,
      columns: [

        DataColumn(label: Container(width:width * .25,child: Text('Paket Adı',softWrap: true,))),
        DataColumn(label: Container(width:width * .25, child: Text('Katılımcı Sayısı',softWrap: true,))),
        DataColumn(label: Container(width:width * .25,child: Text('Fiyat'))),
        DataColumn(label: Container(width:width * .25,child: Text('İşlemler'))),
      ],
      rows: kampanyalar.map((item) {
        //final colorAndText = getStatusColorAndText(item.durum, item.geldimi);


        //final status = "${item.durum}";

        //List katilimcilarjson = json.decode('');
        /* List<Katilimcilar> katilimciListte =  katilimcilarjson.map((e) => Katilimcilar.fromJson(e)).toList();*/
        return DataRow(
          cells: [

            DataCell(
              Text(item.paket_isim,softWrap: true,),
            ),
            DataCell(
              Text(item.katilimcilar.length.toString()),
            ),
            DataCell(
              Text(item.fiyat+ " ₺",softWrap: true,),
            ),
            DataCell(
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {

                  } else if (value == 'delete') {

                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'edit',
                    child: Text('Düzenle'),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Text('Sil'),
                  ),
                ],
              ),
            ),
          ],
          onSelectChanged: (_) {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => KampanyaDetay(kampanyadetayi: item,isletmebilgi: widget.isletmebilgi,)),
            );
            //_showDetailsDialog(context, item, colorAndText.text, status);
          },
        );
      }).toList(),
    );
  }

  Widget _buildEmptyTableMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 50.0,left: 8,right: 8),
        child: Text(
          'Tabloda herhangi bir veri mevcut değil',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }



}class ColorAndText {
  final Color color;
  final String text;

  ColorAndText(this.color, this.text);
}




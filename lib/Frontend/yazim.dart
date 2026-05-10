import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:randevu_sistem/Frontend/popupdialogs.dart';
import 'package:randevu_sistem/Frontend/progressloading.dart';
import 'package:randevu_sistem/Models/kampanyalar.dart';

import 'package:randevu_sistem/yonetici/dashboard/gunlukRaporlar/ajandaduzenle.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Models/ajanda.dart';
import 'package:randevu_sistem/Models/form.dart';
import 'package:randevu_sistem/Models/masrafkategorileri.dart';
import 'package:randevu_sistem/Models/masraflar.dart';
import 'package:randevu_sistem/Models/musteri_danisanlar.dart';
import 'package:randevu_sistem/Models/odemeturu.dart';
import 'package:randevu_sistem/Models/paketler.dart';
import 'package:randevu_sistem/Models/personel.dart';
import 'package:randevu_sistem/Models/randevular.dart';
import 'package:randevu_sistem/Models/satislar.dart';
import 'package:randevu_sistem/Models/senetler.dart';
import 'package:randevu_sistem/Models/sms_taslaklari.dart';
import 'package:randevu_sistem/Models/tahsilatlar.dart';
import 'package:randevu_sistem/Models/urunler.dart';

import 'package:randevu_sistem/yonetici/diger/menu/ayarlar/urunler/urunduzenle.dart';
import 'package:randevu_sistem/yonetici/diger/menu/kampanya/kampanyalar.dart';
import 'package:randevu_sistem/yonetici/diger/menu/kampanya/kampanyaduzenle.dart';
import 'package:http/http.dart' as http;
import 'package:randevu_sistem/Models/colorandtext.dart';
import 'package:intl/intl.dart';
import 'package:randevu_sistem/yonetici/diger/menu/kasa/masrafduzenle.dart';
import 'package:randevu_sistem/yonetici/diger/menu/musteriler/musteriduzenle.dart';
import 'package:randevu_sistem/yonetici/diger/menu/senetler/senetvadeleri.dart';
import 'package:randevu_sistem/yonetici/diger/menu/senetler/yazdir.dart';
import 'datetimeformatting.dart';
import 'package:randevu_sistem/yonetici/diger/menu/musteriler/musteridetaylar.dart';



class KampanyaDataSource extends DataGridSource  {
  List<DataGridRow> _paginatedRows = [];
  int rowsPerPage;
  int currentPage;

  int totalPages = 1;
  int totalRows;
  String salonid;

  String arama;

  BuildContext context;
  List<Kampanya> kampanya = [];


  ValueNotifier<bool> isLoadingNotifier = ValueNotifier(false);
  KampanyaDataSource({
    required this.rowsPerPage,
    required this.context,
    required this.salonid,

    required this.arama,




  }) : currentPage = 1, totalRows = 0 {
    fetchData(currentPage.toString(),arama,true);
  }
  void search(String baslik)
  {
    currentPage = 1;
    fetchData("1",baslik,false);
  }
  Future<void> fetchData(String page,String baslik,bool showprogress) async {

    isLoadingNotifier.value = true;
    if(showprogress)
      showProgressLoading(context);
    notifyListeners();
    final jsonResponse = await kampanyagetir(salonid, page.toString(),baslik);

    List<dynamic> data = jsonResponse['data'];
    kampanya = data.map<Kampanya>((json) => Kampanya.fromJson(json)).toList();
    if(_paginatedRows.length>0)
      _paginatedRows = [];

    kampanya.forEach((e) {

      ++totalRows;
      _paginatedRows.add(
          DataGridRow(cells: [
            DataGridCell<Kampanya>(columnName: 'campaign',value: e),
            DataGridCell<String>(columnName: 'id', value: e.id),
            DataGridCell<String>(columnName: 'paket', value: e.paket_isim),
            DataGridCell<String>(columnName: 'hizmet', value: e.hizmet_adi),
            DataGridCell<String>(columnName: 'katilimci', value: e.katilimcilar.length.toString()),
            DataGridCell<String>(columnName: 'fiyat', value: e.fiyat),


          ])
      );
    });
    totalPages = jsonResponse['last_page'];
    currentPage = jsonResponse['current_page'];
    isLoadingNotifier.value = false;
    if(showprogress)
      Navigator.of(context, rootNavigator: true).pop();// Notify listeners that loading has finished
    notifyListeners();
  }

  void setPage(int page) {
    if (page > 0 && page <= totalPages) {
      currentPage = page;

      fetchData(currentPage.toString(),"",true);
    }
  }


  @override
  List<DataGridRow> get rows => _paginatedRows;


  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    final colorAndText = getStatusColorAndText(row.getCells()[4].value.toString());
    return DataGridRowAdapter(cells: [

      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[0].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[1].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[2].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[3].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[4].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[5].value.toString()),
      ),

      Container(
          alignment: Alignment.center,
          child:PopupMenuButton<String>(
            onSelected: (String value) async {
              if(value=='duzenle')
              {


              }
              if(value=='sil')
              {
                showKampanyaSilmeConfirmationDialog(context,row.getCells()[1].value.toString());
              }


            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'duzenle',
                child: Text('Düzenle'),
              ),
              PopupMenuItem<String>(
                value: 'sil',
                child: Text('Sil'),
              ),

            ],
          )
      )


    ]);


  }
  Future<bool?> showKampanyaSilmeConfirmationDialog(BuildContext context, String id)  {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Emin misiniz?'),
          content: Text('Veri silme işlemi geri alınamaz!'),
          actions: <Widget>[
            TextButton(
              child: Text('VAZGEÇ'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('SİL'),
              onPressed: () {
               kampanyasil(context,int.parse(id));
              },
            ),
          ],
        );
      },
    );
  }

}



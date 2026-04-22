import 'dart:developer';


import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:randevu_sistem/Frontend/progressloading.dart';
import 'package:randevu_sistem/Models/musteri_danisanlar.dart';
import 'package:randevu_sistem/yonetici/diger/menu/senetler/kapal%C4%B1senetler.dart';
import 'package:randevu_sistem/yonetici/diger/menu/senetler/senetvadeleri.dart';
import 'package:randevu_sistem/yonetici/diger/menu/senetler/yazdir.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import '../../../../Frontend/popupdialogs.dart';
import '../../../../Models/randevular.dart';
import '../../../../Models/senetler.dart';
import '../../../../Models/urunler.dart';
import '../../../../yeni/urun_ekle.dart';
import '../../../adisyonlar/adisyonpage.dart';
import '../../../adisyonlar/musteri_detay.dart';
import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Frontend/altyuvarlakmenu.dart';
import 'package:randevu_sistem/Models/form.dart';
import 'package:randevu_sistem/Frontend/sfdatatable.dart';

import '../ayarlar/urunler/urunduzenle.dart';


class Gelirler extends StatefulWidget {
    final String tarih;
    final String odeme_yontemi;
    Gelirler({Key? key, required this.tarih, required this.odeme_yontemi }) : super(key: key);
    @override

    _KasaState createState() => _KasaState();
}

class _KasaState extends State<Gelirler> {

    late GelirDataSource _gelirDataGridSource;
    late List<bool> selectedRows;

    late String? seciliisletme;
    bool  _isLoading= true;
    TextEditingController musteriController = TextEditingController();
    int totalPages = 1;
    bool anyChecked = false;
    bool selectAll = false;
    @override
    void initState() {
        super.initState();
        initialize();
    }

    Future<void> initialize() async
    {
        seciliisletme = await secilisalonid();

            setState(() {


                _gelirDataGridSource = GelirDataSource(rowsPerPage:10,salonid: seciliisletme!,context: context,odemeyontemi: widget.odeme_yontemi,tarih: widget.tarih,);
                _gelirDataGridSource.isLoadingNotifier.addListener(_onLoadingStateChanged);
                _isLoading = false;

            });

    }

    void _onLoadingStateChanged() {
        setState(() {
            // This empty setState function just triggers a rebuild of the widget when the loading state changes
        });
    }

    Future<void> _refreshPage() async {
        // Simulate a network request for new data

        setState(() {
            @override
            Widget build(BuildContext context) {
                return MaterialApp(
                    debugShowCheckedModeBanner: false,
                    home: KapaliSenetler(),
                );
            }
        });
    }

    @override
    Widget build(BuildContext context) {
        final double width = MediaQuery.of(context).size.width;
        final double height = MediaQuery.of(context).size.height;
        return   _isLoading
            ? Center(child: CircularProgressIndicator())
            : Scaffold(



            body:GestureDetector(
                child: Column(

                    children: [

                        Expanded(

                            // Adjust the height based on your requirements
                            child: SfDataGrid(
                                source: _gelirDataGridSource,
                                shrinkWrapRows: true,
                                columnWidthMode: ColumnWidthMode.fill,
                                defaultColumnWidth: 120,








                                onCellTap: (DataGridCellTapDetails details) {

                                    final tappedRow = _gelirDataGridSource.rows[details.rowColumnIndex.rowIndex - 1];
                                    _gelirDataGridSource.showDetailsDialog(context, tappedRow);
                                    /*ArsivDetayGosterDialog(context );
                 Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => KampanyaDetay(kampanyadetayi: tappedRow.getCells()[0].value,)),
                  );*/

                                },
                                columns: <GridColumn>[

                                    GridColumn(

                                        width: width*0,
                                        columnName: 'gelirpar',
                                        label: Container(

                                            padding: EdgeInsets.all(5.0),
                                            alignment: Alignment.centerLeft,
                                            child: Text('gelirpar'),
                                        ),
                                    ),

                                    GridColumn(

                                        width: width*0,
                                        columnName: 'odemetutar',
                                        label: Container(

                                            padding: EdgeInsets.all(5.0),
                                            alignment: Alignment.centerLeft,
                                            child: Text('odemetutar'),
                                        ),
                                    ),
                                    GridColumn(

                                        width: width*0,
                                        columnName: 'odemeyontemi',
                                        label: Container(

                                            padding: EdgeInsets.all(5.0),
                                            alignment: Alignment.centerLeft,
                                            child: Text('odemeyontemi'),
                                        ),
                                    ),
                                    GridColumn(

                                        width: width*0,
                                        columnName: 'aciklama',
                                        label: Container(

                                            padding: EdgeInsets.all(5.0),
                                            alignment: Alignment.centerLeft,
                                            child: Text('aciklama'),
                                        ),
                                    ),
                                    GridColumn(

                                        width: width*0.40,
                                        columnName: 'musteridanisanparakoyan',
                                        label: Container(

                                            padding: EdgeInsets.all(5.0),
                                            alignment: Alignment.centerLeft,
                                            child: Text('Müşteri/Para Koyan'),
                                        ),
                                    ),

                                    GridColumn(
                                        width: width*0.25,
                                        columnName: 'tarih',
                                        label: Container(
                                            padding: EdgeInsets.all(5.0),
                                            alignment: Alignment.centerLeft,
                                            child: Text('Tarih'),
                                        ),
                                    ),

                                    GridColumn(
                                        width: width*0.34,
                                        columnName: 'fiyat',
                                        label: Container(
                                            padding: EdgeInsets.all(5.0),
                                            alignment: Alignment.centerRight,
                                            child: Text('Tutar ₺'),
                                        ),
                                    ),


                                ],
                            ),
                        ),


                        _buildPaginationControls()
                    ],
                ),

            )


        );



    }


    Widget _buildPaginationControls() {

        final totalPages = (_gelirDataGridSource.totalPages).ceil();

        return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
                IconButton(
                    icon: Icon(Icons.arrow_back),
                    onPressed: _gelirDataGridSource.currentPage > 1
                        ? () {
                        setState(() {

                            _gelirDataGridSource.setPage(_gelirDataGridSource.currentPage - 1);
                        });
                    }
                        : null,
                ),
                Text('Sayfa ${_gelirDataGridSource.currentPage} / $totalPages'),
                IconButton(
                    icon: Icon(Icons.arrow_forward),
                    onPressed: _gelirDataGridSource.currentPage < totalPages
                        ? () {
                        setState(() {
                            _gelirDataGridSource.setPage(_gelirDataGridSource.currentPage + 1);
                        });
                    }
                        : null,
                ),
            ],
        );
    }





}

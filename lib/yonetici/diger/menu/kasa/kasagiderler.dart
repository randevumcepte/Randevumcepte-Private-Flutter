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
import '../../../../Models/masrafkategorileri.dart';
import '../../../../Models/personel.dart';
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


class Giderler extends StatefulWidget {
    final String tarih;
    final String odeme_yontemi;
    final dynamic isletmebilgi;
    Giderler({Key? key, required this.tarih, required this.odeme_yontemi,required this.isletmebilgi }) : super(key: key);
    @override

    _KasaState createState() => _KasaState();
}

class _KasaState extends State<Giderler> {

    late GiderDataSource _giderDataGridSource;
    late List<bool> selectedRows;
    late List<Personel>personelliste;
    late List<MasrafKategorisi>masrafkategoriliste;
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
        personelliste = await personellistegetir(seciliisletme!);
        masrafkategoriliste = await masrafkategorileri();
        setState(() {


            _giderDataGridSource = GiderDataSource(isletmebilgi: widget.isletmebilgi, rowsPerPage:10,salonid: seciliisletme!,context: context,odemeyontemi: widget.odeme_yontemi,tarih: widget.tarih,harcayan: '', personelliste: personelliste,masrafkategoriliste: masrafkategoriliste);
            _giderDataGridSource.isLoadingNotifier.addListener(_onLoadingStateChanged);
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
                                source: _giderDataGridSource,
                                shrinkWrapRows: true,
                                columnWidthMode: ColumnWidthMode.fill,
                                defaultColumnWidth: 120,








                                onCellTap: (DataGridCellTapDetails details) {

                                    final tappedRow = _giderDataGridSource.rows[details.rowColumnIndex.rowIndex - 1];
                                    _giderDataGridSource.showDetailsDialog(context,  tappedRow.getCells()[0].value);
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
                                        columnName: 'tutar',
                                        label: Container(

                                            padding: EdgeInsets.all(5.0),
                                            alignment: Alignment.centerLeft,
                                            child: Text('tutar'),
                                        ),
                                    ),

                                    GridColumn(

                                        width: width*0.40,
                                        columnName: 'harcayan',
                                        label: Container(

                                            padding: EdgeInsets.all(5.0),
                                            alignment: Alignment.centerLeft,
                                            child: Text('Harcayan'),
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
                                        columnName: 'tutartext',
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

        final totalPages = (_giderDataGridSource.totalPages).ceil();

        return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
                IconButton(
                    icon: Icon(Icons.arrow_back),
                    onPressed: _giderDataGridSource.currentPage > 1
                        ? () {
                        setState(() {

                            _giderDataGridSource.setPage(_giderDataGridSource.currentPage - 1);
                        });
                    }
                        : null,
                ),
                Text('Sayfa ${_giderDataGridSource.currentPage} / $totalPages'),
                IconButton(
                    icon: Icon(Icons.arrow_forward),
                    onPressed: _giderDataGridSource.currentPage < totalPages
                        ? () {
                        setState(() {
                            _giderDataGridSource.setPage(_giderDataGridSource.currentPage + 1);
                        });
                    }
                        : null,
                ),
            ],
        );
    }





}

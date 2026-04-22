import 'dart:developer';

import 'package:dropdown_button2/dropdown_button2.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';

import 'package:randevu_sistem/yonetici/adisyonlar/satislar/tahsilat.dart';
import 'package:randevu_sistem/yonetici/adisyonlar/satislar/varolantahsilat.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';


import 'package:provider/provider.dart';

import '../../../../../Backend/backend.dart';
import '../../../../../Frontend/indexedstack.dart';
import '../../../../../Frontend/sfdatatable.dart';
import '../../../../../Models/musteri_danisanlar.dart';
import '../../../../../Models/personel.dart';
import '../../../../../Models/satisturleri.dart';




class PersonelSatislari extends StatefulWidget {
  final Personel kullanici;
  final dynamic isletmebilgi;
  final int kullanicirolu;
  PersonelSatislari({Key? key, required this.kullanici,required this.isletmebilgi,required this.kullanicirolu}) : super(key: key);
  @override
  _PersonelSatislariState createState() => _PersonelSatislariState();
}

class _PersonelSatislariState extends State<PersonelSatislari> {
  bool _isLoading = true;
  final List<SatisTuru> adisyonicerigi = [
    SatisTuru(id: "", satisturu: "Tümü"),
    SatisTuru(id: "1", satisturu: "Hizmet Satışları"),
    SatisTuru(id: "2", satisturu: "Paket Satışları"),
    SatisTuru(id: "3", satisturu: "Ürün Satışları"),
  ];
  late String? seciliisletme;
  SatisTuru? selectedadisyonicerigi;
  TextEditingController adisyonicerigicontroller = TextEditingController();
  late SatisDataSource _satisDataGridSource;
  String? selectedadisyondurum;
  MusteriDanisan? selectedMusteri;
  TextEditingController adisyondurumcontroller = TextEditingController();
  late List<MusteriDanisan> musteridanisanliste;
  
  TextEditingController tarih1 = TextEditingController(text: "1970-09-01");
  TextEditingController tarih2 = TextEditingController(
      text: DateFormat("yyyy-MM-dd").format(DateTime.now()));
  TextEditingController musteridanisanadi = TextEditingController();
  DateTime? startDate;
  DateTime? endDate;
  late dynamic isletme_bilgi;

  DateTimeRange? _selectedDateRange;

  void initState() {
    super.initState();
    initialize();
  }

  Future<void> initialize() async {



    seciliisletme = await secilisalonid();

    List<MusteriDanisan> musteridanisanlar = await musterilistegetir(seciliisletme!);


    setState(() {

      musteridanisanliste = musteridanisanlar;
      selectedadisyonicerigi = adisyonicerigi[0];
      _satisDataGridSource = SatisDataSource(
        kullanicirolu: widget.kullanicirolu,
        musteriMi: false,
        personelMi: true,
        isletmebilgi: widget.isletmebilgi,
        rowsPerPage: 10,
        salonid: seciliisletme!,
        context: context,
        tarih1: tarih1.text,
        tarih2: tarih2.text,
        musteriid: "",
        personelid: widget.kullanici.id,
        userid: '',
        tur: selectedadisyonicerigi?.id ?? "", );
      _satisDataGridSource.isLoadingNotifier
          .addListener(_onLoadingStateChanged);
      _isLoading = false;

    });
  }

  void _onLoadingStateChanged() {
    setState(() {
      // This empty setState function just triggers a rebuild of the widget when the loading state changes
    });
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Satışlar',
          style: TextStyle(color: Colors.black),
        ),
        leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              Navigator.of(context).pop();
            }),
        toolbarHeight: 60,
        actions: [
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
          ? Center(
        child: CircularProgressIndicator(),
      )
          : SingleChildScrollView(
          child: Column(children: [
            Container(
              height: height - 205,
              // Adjust the height based on your requirements
              child: SfDataGrid(
                source: _satisDataGridSource,
                shrinkWrapRows: true,
                columnWidthMode: ColumnWidthMode.fill,
                defaultColumnWidth: 120,
                allowSwiping: true,
                rowHeight: 55,
                onSwipeStart: (details) {
                  if (details.swipeDirection ==
                      DataGridRowSwipeDirection.startToEnd) {
                    details.setSwipeMaxOffset(50);
                  } else if (details.swipeDirection ==
                      DataGridRowSwipeDirection.endToStart) {
                    details.setSwipeMaxOffset(50);
                  }
                  return true;
                },
                startSwipeActionsBuilder:
                    (BuildContext context, DataGridRow row, int rowIndex) {
                  return GestureDetector(
                      onTap: () {
                        Navigator.push(
                            context,
                            new MaterialPageRoute(
                                builder: (context) => VarolanTahsilat(isletmebilgi: widget.isletmebilgi,)));
                      },
                      child: Container(
                          color: Colors.purple,
                          child: Center(
                            child: Icon(Icons.money, color: Colors.white),
                          )));
                },
                endSwipeActionsBuilder:
                    (BuildContext context, DataGridRow row, int rowIndex) {
                  return GestureDetector(
                      onTap: () async {
                        //_ongorusmeDataGridSource.showAjandaSilmeConfirmationDialog(context, row.getCells()[1].value);
                      },
                      child: Container(
                          color: Colors.red,
                          child: Center(
                            child: Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          )));
                },
                onCellTap: (DataGridCellTapDetails details) {
                  final tappedRow = _satisDataGridSource
                      .rows[details.rowColumnIndex.rowIndex - 1];


                },
                columns: <GridColumn>[
                  GridColumn(
                    width: width * 0,
                    columnName: 'satis',
                    label: Container(
                      padding: EdgeInsets.all(2.0),
                      alignment: Alignment.centerLeft,
                      child: Text('a'),
                    ),
                  ),
                  GridColumn(
                    width: width * 0,
                    columnName: 'id',
                    label: Container(
                      padding: EdgeInsets.all(2.0),
                      alignment: Alignment.centerLeft,
                      child: Text('#'),
                    ),
                  ),
                  GridColumn(
                    width: width * 0.25,
                    columnName: 'musteridanisantarih',
                    label: Container(
                      padding: EdgeInsets.all(2.0),
                      alignment: Alignment.centerLeft,
                      child: Text('Müşteri/Tarih'),
                    ),
                  ),
                  GridColumn(
                    width: width * 0.25,
                    columnName: 'toplam',
                    label: Container(
                      padding: EdgeInsets.all(2.0),
                      alignment: Alignment.center,
                      child: Text('Toplam ₺'),
                    ),
                  ),
                  GridColumn(
                    width: width * 0.25,
                    columnName: 'odenen',
                    label: Container(
                      padding: EdgeInsets.all(2.0),
                      alignment: Alignment.center,
                      child: Text('Ödenen ₺'),
                    ),
                  ),
                  GridColumn(
                    width: width * 0.25,
                    columnName: 'kalan',
                    label: Container(
                      padding: EdgeInsets.all(2.0),
                      alignment: Alignment.center,
                      child: Text('Kalan ₺'),
                    ),
                  ),
                ],
              ),
            ),
            _buildPaginationControls()
          ])),
    );
  }

  Widget _buildPaginationControls() {
    final totalPages = (_satisDataGridSource.totalPages).ceil();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: _satisDataGridSource.currentPage > 1
              ? () {
            setState(() {
              _satisDataGridSource.setPage(
                  _satisDataGridSource.currentPage - 1,
                  tarih1.text,
                  tarih2.text,
                  "",
                  selectedadisyonicerigi?.id ?? "");
            });
          }
              : null,
        ),
        Text('Sayfa ${_satisDataGridSource.currentPage} / $totalPages'),
        IconButton(
          icon: Icon(Icons.arrow_forward),
          onPressed: _satisDataGridSource.currentPage < totalPages
              ? () {
            setState(() {
              _satisDataGridSource.setPage(
                  _satisDataGridSource.currentPage + 1,
                  tarih1.text,
                  tarih2.text,
                  "",
                  selectedadisyonicerigi?.id ?? "");
            });
          }
              : null,
        ),
      ],
    );
  }

  void printWidgetInfo(Widget widget) {
    debugPrint('Widget info : $widget');
  }
}
import 'dart:async';
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


class SadikMusteriler extends StatefulWidget {
  final dynamic isletmebilgi;
  final int kullanicirolu;
  const SadikMusteriler({Key? key,required this.isletmebilgi,required this.kullanicirolu}) : super(key: key);
  @override
  _MusterilerState createState() => _MusterilerState();
}

class _MusterilerState extends State<SadikMusteriler> {
  MusteriDanisan? selectedmusteri;
  late List<MusteriDanisan> musteris;
  List<TextEditingController> urunadet = [];
  late MusteriDanisanDataSource _musteriDanisanDataSource;
  late List<bool> selectedRows;
  List<Urun> _urun = [];
  late List<Urun> _filteredUrun = [];
  late String? seciliisletme;
  bool  _isLoading= true;
  TextEditingController musteriController = TextEditingController();
  int totalPages = 1;
  bool anyChecked = false;
  bool selectAll = false;
  Timer? _debounce;
  bool firsttimetyping=true;
  String? lastQuery;
  TextEditingController _controller = TextEditingController();
  @override
  void initState() {

    super.initState();
    initialize();


    _controller.addListener(() {

      _onSearchChanged();


    });
  }
  void _onSearchChanged() {

    if (_controller.text.length == 0 || _controller.text.length >= 3) {

      if (_debounce?.isActive ?? false) _debounce!.cancel();

      _debounce = Timer(const Duration(milliseconds: 500), () {
        if (_controller.text != lastQuery && !firsttimetyping) {  // Check if the query is different
          setState(() {

            firsttimetyping=false;
            lastQuery = _controller.text; // Update the last search query
            _musteriDanisanDataSource.search(_controller.text);
            //FocusScope.of(context).unfocus();
          });
        }
      });
    }
    else
    {
      if((_controller.text == '' || _controller.text.length<3) && firsttimetyping)
      {

        setState(() {
          firsttimetyping = false;
        });
      }
    }
  }


  Future<void> initialize() async
  {
    seciliisletme = await secilisalonid();


    setState(() {


      _musteriDanisanDataSource = MusteriDanisanDataSource(kullanicirolu: widget.kullanicirolu, isletmebilgi: widget.isletmebilgi,rowsPerPage:10,salonid: seciliisletme!,context: context,durum: '2',arama: _controller.text);
      _musteriDanisanDataSource.isLoadingNotifier.addListener(_onLoadingStateChanged);
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

        resizeToAvoidBottomInset: false,

        body:GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus(); // Hide the keyboard
          },
          child: Column(

            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextFormField(

                  controller: _controller,
                  keyboardType: TextInputType.text,

                  decoration: InputDecoration(
                    hintText: 'Müşteri...',
                    enabled:true,
                    focusColor:Color(0xFF6A1B9A) ,
                    hoverColor: Color(0xFF6A1B9A) ,
                    hintStyle: TextStyle(color:  Color(0xFF6A1B9A)),
                    contentPadding:  EdgeInsets.all(5.0),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(
                        color: Color(0xFF6A1B9A)),borderRadius: BorderRadius.circular(10.0),),
                    border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10.0),),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF6A1B9A),), borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                ),

              ),
              Expanded(


                child: SfDataGrid(
                  source: _musteriDanisanDataSource,
                  shrinkWrapRows: true,
                  columnWidthMode: ColumnWidthMode.fill,
                  defaultColumnWidth: 120,








                  onCellTap: (DataGridCellTapDetails details) {

                    final tappedRow = _musteriDanisanDataSource.rows[details.rowColumnIndex.rowIndex - 1];
                    _musteriDanisanDataSource.showDetailsDialog(context, tappedRow.getCells()[0].value);
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
                      columnName: 'musteripar',
                      label: Container(

                        padding: EdgeInsets.all(5.0),
                        alignment: Alignment.centerLeft,
                        child: Text('musteripar'),
                      ),
                    ),

                    GridColumn(

                      width: width*0,
                      columnName: 'id',
                      label: Container(

                        padding: EdgeInsets.only(left:10.0),
                        alignment: Alignment.centerLeft,
                        child: Text('#'),
                      ),
                    ),
                    GridColumn(

                      width: width*0.30,
                      columnName: 'musteridanisanadi',
                      label: Container(

                        padding: EdgeInsets.all(5.0),
                        alignment: Alignment.centerLeft,
                        child: Text('Müşteri'),
                      ),
                    ),



                    GridColumn(

                      width: width*0.30,
                      columnName: 'ceptelefon',
                      label: Container(

                        padding: EdgeInsets.all(5.0),
                        alignment: Alignment.centerLeft,
                        child: Text('Telefon'),
                      ),
                    ),


                    GridColumn(
                      width: width*0.30,
                      columnName: 'randevusayisi',
                      label: Container(
                        padding: EdgeInsets.all(5.0),
                        alignment: Alignment.centerLeft,
                        child: Text('Randevu Sayısı'),
                      ),
                    ),

                    GridColumn(
                      width: width*0.10,
                      columnName: 'islemler',
                      label: Container(
                        padding: EdgeInsets.all(5.0),
                        alignment: Alignment.centerLeft,
                        child: Text(''),
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

    final totalPages = (_musteriDanisanDataSource.totalPages).ceil();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: _musteriDanisanDataSource.currentPage > 1
              ? () {
            setState(() {

              _musteriDanisanDataSource.setPage(_musteriDanisanDataSource.currentPage - 1);
            });
          }
              : null,
        ),
        Text('Sayfa ${_musteriDanisanDataSource.currentPage} / $totalPages'),
        IconButton(
          icon: Icon(Icons.arrow_forward),
          onPressed: _musteriDanisanDataSource.currentPage < totalPages
              ? () {
            setState(() {
              _musteriDanisanDataSource.setPage(_musteriDanisanDataSource.currentPage + 1);
            });
          }
              : null,
        ),
      ],
    );
  }





}

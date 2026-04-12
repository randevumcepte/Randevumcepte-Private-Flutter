import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:randevu_sistem/Models/etkinlikler.dart';
import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/yukselt.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:randevu_sistem/Frontend/altyuvarlakmenu.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../../../../Frontend/popupdialogs.dart';
import '../../../../Frontend/sfdatatable.dart';
import '../../../../Models/katilimcilar.dart';
import '../../../../Models/musteri_danisanlar.dart';
import '../../../../Models/sms_taslaklari.dart';
import 'etkinlikdetay.dart';
import 'etkinlikduzenle.dart';
import 'etkinlikekle.dart';

class Etkinlikler extends StatefulWidget {
  final dynamic isletmebilgi;
  Etkinlikler({Key? key,required this.isletmebilgi}) : super(key: key);
  @override
  _EtkinliklerState createState() => _EtkinliklerState();
}

class _EtkinliklerState extends State<Etkinlikler> {

  bool  _isLoading= true;

  late EtkinlikDataSource _etkinlikDataGridSource;

  late String seciliisletme;
  late List<MusteriDanisan> fullmusteridanisanlistesi = [];

  late List<SmsTaslak>fullsmstaslaklistesi =[];

  TextEditingController _controller = TextEditingController();
  List<Etkinlik> etkinlikler = [];
  Timer? _debounce;
  bool firsttimetyping = true;
  String? lastQuery;
  @override
  void initState() {
    super.initState();
    initialize();
    _controller.addListener(() {
      _onSearchChanged();
    });
  }

  void _onSearchChanged() {
    // Check if the search query has changed or is reset to empty
    if (_controller.text.length == 0 || _controller.text.length >= 3) {
      // Cancel any active debounce timer
      if (_debounce?.isActive ?? false) _debounce!.cancel();

      // Debounce the search to delay the API call until the user stops typing
      _debounce = Timer(const Duration(milliseconds: 500), () {
        if (_controller.text != lastQuery && !firsttimetyping) {  // Check if the query is different
          setState(() {

            firsttimetyping=false;
            lastQuery = _controller.text; // Update the last search query
            _etkinlikDataGridSource.search(_controller.text);
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
  Future<void> initialize() async{

    seciliisletme=(await secilisalonid())!;

    setState(() {
      _etkinlikDataGridSource=EtkinlikDataSource(context: context, rowsPerPage: 10, salonid: seciliisletme, arama: _controller.text);
      _etkinlikDataGridSource.isLoadingNotifier.addListener(_onLoadingStateChanged);
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
    return GestureDetector(
      onTap: () {
        // Unfocus the current text field, dismissing the keyboard
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        //floatingActionButton: AltYuvarlakYeniEkleMenu(isletme_bilgi: widget.isletmebilgi,),
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            title: Text('Etkinlikler',style: TextStyle(color: Colors.black,fontSize: 18),),
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
              IconButton(onPressed: (){
                Navigator.of(context).pop();

                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => EtkinlikEkle(isletmebilgi: widget.isletmebilgi, etkinlidatasource: _etkinlikDataGridSource,)),
                );
              }, icon:  Icon(Icons.add,color:Colors.black,),iconSize: 26,),
            ],
            backgroundColor: Colors.white,
          ),
          body: _isLoading
              ? Center(child: CircularProgressIndicator()) // Show loading indicator while data is loading
              :LayoutBuilder(
              builder: (context, constraints) {
                return Column(

                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextFormField(

                        controller: _controller,
                        keyboardType: TextInputType.text,

                        decoration: InputDecoration(
                          hintText: 'Başlık...',
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
                        source: _etkinlikDataGridSource,
                        shrinkWrapRows: true,
                        columnWidthMode: ColumnWidthMode.fill,
                        defaultColumnWidth: 120,
                        allowSwiping: true,
                        onSwipeStart: (details) {
                          if (details.swipeDirection == DataGridRowSwipeDirection.startToEnd) {
                            details.setSwipeMaxOffset(50);
                          } else if (details.swipeDirection == DataGridRowSwipeDirection.endToStart) {
                            details.setSwipeMaxOffset(50);
                          }
                          return true;
                        },

                        startSwipeActionsBuilder:
                            (BuildContext context, DataGridRow row, int rowIndex) {
                          return GestureDetector(
                              onTap: () {
                                Navigator.of(context).pop();
                                Navigator.push(context, new MaterialPageRoute(builder: (context) => new EtkinlikDuzenle(etkinlikdetayi: row.getCells()[0].value as Etkinlik, etkinlidatasource: _etkinlikDataGridSource,)));
                              },
                              child: Container(
                                  color: Colors.purple,
                                  child: Center(
                                    child: Icon(Icons.edit,color: Colors.white),
                                  )));
                        },
                        endSwipeActionsBuilder:
                            (BuildContext context, DataGridRow row, int rowIndex) {
                          return GestureDetector(
                              onTap: () async {
                                _etkinlikDataGridSource.showEtkinlikSilmeConfirmationDialog(context, row.getCells()[1].value);

                              },
                              child: Container(
                                  color: Colors.red,
                                  child: Center(
                                    child: Icon(Icons.delete,color: Colors.white,),
                                  )));
                        },
                        onCellTap: (DataGridCellTapDetails details) {

                          final tappedRow = _etkinlikDataGridSource.rows[details.rowColumnIndex.rowIndex - 1];

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => EtkinlikDetay(etkinlikdetayi: tappedRow.getCells()[0].value,isletmebilgi: widget.isletmebilgi,)),
                          );


                        },
                        columns: <GridColumn>[
                          GridColumn(

                            width: width*0,
                            columnName: 'etkinlik',
                            label: Container(

                              padding: EdgeInsets.only(left:10.0),
                              alignment: Alignment.centerLeft,
                              child: Text('e'),
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

                            width: width*0.275,
                            columnName: 'tarih_saat',
                            label: Container(

                              padding: EdgeInsets.only(left:10.0),
                              alignment: Alignment.centerLeft,
                              child: Text('Tarih-Saat'),
                            ),
                          ),
                          GridColumn(
                            width: width*0.25,
                            columnName: 'etkinlik_adi',
                            label: Container(
                              //padding: EdgeInsets.all(5.0),
                              alignment: Alignment.centerLeft,
                              child: Text('Etkinlik Adı'),
                            ),
                          ),
                          GridColumn(
                            width: width*0.17,
                            columnName: 'katilimci',
                            label: Container(
                              //padding: EdgeInsets.all(5.0),
                              alignment: Alignment.centerRight,
                              child: Text('Katılımcı'),
                            ),
                          ),
                          GridColumn(
                            width: width*0.20,
                            columnName: 'fiyat',
                            label: Container(
                              //padding: EdgeInsets.all(5.0),
                              alignment: Alignment.centerRight,
                              child: Text('Fiyat(₺)'),
                            ),
                          ),
                          GridColumn(
                            width: width*0.15,
                            columnName: 'islem',
                            label: Container(
                              //padding: EdgeInsets.all(5.0),
                                alignment: Alignment.center,
                                child: Text("")
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildPaginationControls()
                  ],
                );}
          )
      ),
    );
  }




  Widget _buildPaginationControls() {

    final totalPages = (_etkinlikDataGridSource.totalPages).ceil();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: _etkinlikDataGridSource.currentPage > 1
              ? () {
            setState(() {

              _etkinlikDataGridSource.setPage(_etkinlikDataGridSource.currentPage - 1);
            });
          }
              : null,
        ),
        Text('Sayfa ${_etkinlikDataGridSource.currentPage} / $totalPages'),
        IconButton(
          icon: Icon(Icons.arrow_forward),
          onPressed: _etkinlikDataGridSource.currentPage < totalPages
              ? () {
            setState(() {
              _etkinlikDataGridSource.setPage(_etkinlikDataGridSource.currentPage + 1);
            });
          }
              : null,
        ),
      ],
    );
  }
}


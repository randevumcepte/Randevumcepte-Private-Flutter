import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:randevu_sistem/Models/randevular.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../../../../Backend/backend.dart';
import '../../../../Frontend/sfdatatable.dart';
import '../../../randevualma/randevual.dart';
import '../../randevularim/randevual.dart';

class MusteriRandevularDashboard extends StatefulWidget {
  final dynamic isletmebilgi;
  final String musteriId;
  MusteriRandevularDashboard({Key? key,required this.isletmebilgi,required this.musteriId}) : super(key: key);
  @override
  _TumRandevularState createState() => _TumRandevularState();
}

class _TumRandevularState extends State<MusteriRandevularDashboard> {
  late RandevuDataSource _randevuDataGridSource;
  List<Randevu> _randevu = [];
  late String? seciliisletme;
  bool  _isLoading= true;
  bool firsttimetyping = true;
  Timer? _debounce;
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
            _randevuDataGridSource.search(_controller.text,"Tümü","Tümü","Bugün");
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


    setState(() {


      _randevuDataGridSource = RandevuDataSource(isletmebilgi:widget.isletmebilgi,rowsPerPage:10,durum: "Tümü", olusturma: "Tümü",salonid: '',tarih:"Bugün",context: context,musteriid: widget.musteriId,personelid: "",cihazid: "",musteriMi: true);
      _randevuDataGridSource.isLoadingNotifier.addListener(_onLoadingStateChanged);
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
    final double width = MediaQuery.of(context).size.width;
    final double height = MediaQuery.of(context).size.height;
    return  _isLoading
        ? Center(child: CircularProgressIndicator())
        :Scaffold(

      appBar: AppBar(
        title: Text('Randevular',style: TextStyle(color: Colors.black,fontSize: 18),),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),


        toolbarHeight: 60,
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: SizedBox(
              width: 150, // <-- Your width
              child: ElevatedButton(onPressed: (){
                Navigator.of(context).pop();

                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => RandevuAl()),
                );
              }, child: Text("RANDEVU AL"), style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple[800], // background (button) color
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                      color: Colors.white, fontSize: 15,fontWeight: FontWeight.bold
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0))
              ),
              ),
            ),
          ),

        ],
        backgroundColor: Colors.white,




      ),

      body: SingleChildScrollView(
        child: Column(
          children: [

            _randevuDataGridSource.rows.isEmpty
                ?  Center(child: Text("Bugün için oluşturulmuş randevunuz bulunmamaktadır",textAlign: TextAlign.center,))
                : Container(
              height: height - 275,
              // Adjust the height based on your requirements
              child: _randevuDataGridSource != null
                  ? SfDataGrid(
                source: _randevuDataGridSource,
                shrinkWrapRows: true,
                columnWidthMode: ColumnWidthMode.fill,
                defaultColumnWidth: 120,
                allowSwiping: true,
                onSwipeStart: (details) {
                  if (details.swipeDirection ==
                      DataGridRowSwipeDirection.startToEnd) {
                    details.setSwipeMaxOffset(0);
                  } else if (details.swipeDirection ==
                      DataGridRowSwipeDirection.endToStart) {
                    details.setSwipeMaxOffset(0);
                  }
                  return true;
                },
                startSwipeActionsBuilder: (BuildContext context,
                    DataGridRow row, int rowIndex) {
                  return GestureDetector(
                      onTap: () {
                        //Navigator.of(context).pop();
                        //Navigator.push(context, new MaterialPageRoute(builder: (context) => new KampanyaDuzenle(kampanyadetayi: row.getCells()[0].value as Kampanya,)));
                      },
                      child: Container(
                          color: Colors.purple,
                          child: Center(
                            child: Icon(Icons.edit, color: Colors.white),
                          )));
                },
                endSwipeActionsBuilder: (BuildContext context,
                    DataGridRow row, int rowIndex) {
                  return GestureDetector(
                      onTap: () async {
                        /*final confirmed = await showKampanyaDeleteConfirmationDialog(context,int.parse(row.getCells()[1].value), () {
                              // Perform deletion

                              setState(() {
                                kampanyasil(context,int.parse(row.getCells()[1].value));
                                Navigator.of(context).pop();
                                Navigator.push(context, new MaterialPageRoute(builder: (context) => new TumArsiv()));


                              });
                            });*/
                      },
                      child: Container(
                          color: Colors.red,
                          child: Center(
                            child: Icon(Icons.delete, color: Colors.white),
                          )));
                },
                onCellTap: (DataGridCellTapDetails details) {
                  final tappedRow = _randevuDataGridSource
                      .rows[details.rowColumnIndex.rowIndex - 1];
                  /*ArsivDetayGosterDialog(context );
                     Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => KampanyaDetay(kampanyadetayi: tappedRow.getCells()[0].value,)),
                      );*/
                },
                columns: <GridColumn>[
                  GridColumn(
                    width: width * 0,
                    columnName: 'randevu',
                    label: Container(
                      padding: EdgeInsets.all(5.0),
                      alignment: Alignment.centerLeft,
                      child: Text('a'),
                    ),
                  ),
                  GridColumn(
                    width: width * 0,
                    columnName: 'id',
                    label: Container(
                      padding: EdgeInsets.all(5.0),
                      alignment: Alignment.centerLeft,
                      child: Text('#'),
                    ),
                  ),
                  GridColumn(
                    width: width * 0.3,
                    columnName: 'tarih',
                    label: Container(
                      padding: EdgeInsets.all(5.0),
                      alignment: Alignment.centerLeft,
                      child: Text('Tarih'),
                    ),
                  ),
                  GridColumn(
                    width: width * 0.3,
                    columnName: 'musteridanisan',
                    label: Container(
                      padding: EdgeInsets.all(5.0),
                      alignment: Alignment.centerLeft,
                      child: Text('Hizmet(-ler)'),
                    ),
                  ),
                  GridColumn(
                    width: width * 0,
                    columnName: 'durum',
                    label: Container(
                      padding: EdgeInsets.all(5.0),
                      alignment: Alignment.centerLeft,
                      child: Text('Durum'),
                    ),
                  ),
                  GridColumn(
                    width: width * 0,
                    columnName: 'geldi',
                    label: Container(
                      padding: EdgeInsets.all(5.0),
                      alignment: Alignment.centerLeft,
                      child: Text('Durum'),
                    ),
                  ),
                  GridColumn(
                    width: width * 0.3,
                    columnName: 'durum_text',
                    label: Container(
                      padding: EdgeInsets.all(5.0),
                      alignment: Alignment.centerLeft,
                      child: Text('Durum'),
                    ),
                  ),
                  GridColumn(
                    width: width * 0.1,
                    columnName: 'islem',
                    label: Container(
                        padding: EdgeInsets.all(5.0),
                        alignment: Alignment.center,
                        child: Text("")
                    ),
                  ),
                ],
              )
                  : Center(child: CircularProgressIndicator()),
            ),
            _buildPaginationControls()
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationControls() {
    final totalPages = (_randevuDataGridSource.totalPages).ceil();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: _randevuDataGridSource.currentPage > 1
              ? () {
            setState(() {
              _randevuDataGridSource.setPage(
                  _randevuDataGridSource.currentPage - 1,"Tümü","Tümü","Bugün");
            });
          }
              : null,
        ),
        Text('Sayfa ${_randevuDataGridSource.currentPage} / $totalPages'),
        IconButton(
          icon: Icon(Icons.arrow_forward),
          onPressed: _randevuDataGridSource.currentPage < totalPages
              ? () {
            setState(() {
              _randevuDataGridSource.setPage(
                  _randevuDataGridSource.currentPage + 1,"Tümü","Tümü","Bugün");
            });
          }
              : null,
        ),
      ],
    );
  }
}

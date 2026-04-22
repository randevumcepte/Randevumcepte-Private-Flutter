import 'dart:async';


import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import '../../../../Frontend/popupdialogs.dart';
import '../../../adisyonlar/adisyonpage.dart';
import '../../../adisyonlar/musteri_detay.dart';
import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Frontend/altyuvarlakmenu.dart';
import 'package:randevu_sistem/Models/form.dart';
import 'package:randevu_sistem/Frontend/sfdatatable.dart';
import 'package:randevu_sistem/Frontend/arsivdetay.dart';

class IptalEdilenArsiv extends StatefulWidget {
  @override

  _ArsivState createState() => _ArsivState();
}

class _ArsivState extends State<IptalEdilenArsiv> {
  late ArsivDataSource _arsivDataGridSource;
  List<Arsiv> _arsiv = [];
  late List<Arsiv> _filteredArsiv = [];
  late String? seciliisletme;
  bool _isLoading = true;
  TextEditingController _controller = TextEditingController();
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
            _arsivDataGridSource.search(_controller.text);
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
    _arsivDataGridSource = ArsivDataSource(cevapladi: '',cevapladi2: '', rowsPerPage:10,salonid: seciliisletme!,context: context,durum: '0',arama: _controller.text, musteriid: '');
    _arsivDataGridSource.isLoadingNotifier.addListener(_onLoadingStateChanged);
    _isLoading = false;
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
          home: IptalEdilenArsiv(),
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
        : GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus(); // Hide the keyboard
      },
      child: Column(

        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(

              controller: _controller,
              keyboardType: TextInputType.text,

              decoration: InputDecoration(
                hintText: 'Müşteri Adı veya Form Adı...',
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
              source: _arsivDataGridSource,
              shrinkWrapRows: true,
              columnWidthMode: ColumnWidthMode.fill,
              defaultColumnWidth: 120,
              allowSwiping: true,



              onSwipeStart: (details) {
                if (details.swipeDirection == DataGridRowSwipeDirection.startToEnd) {
                  details.setSwipeMaxOffset(0);
                } else if (details.swipeDirection == DataGridRowSwipeDirection.endToStart) {
                  details.setSwipeMaxOffset(0);
                }
                return true;
              },

              startSwipeActionsBuilder:
                  (BuildContext context, DataGridRow row, int rowIndex) {
                return GestureDetector(
                    onTap: () {
                      //Navigator.of(context).pop();
                      //Navigator.push(context, new MaterialPageRoute(builder: (context) => new KampanyaDuzenle(kampanyadetayi: row.getCells()[0].value as Kampanya,)));
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
                          child: Icon(Icons.delete,color: Colors.white,),
                        )));
              },
              onCellTap: (DataGridCellTapDetails details) {
                FocusScope.of(context).unfocus();
                final tappedRow = _arsivDataGridSource.rows[details.rowColumnIndex.rowIndex - 1];
                ArsivDetayGosterDialog(context,tappedRow.getCells()[0].value );
                /*Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => KampanyaDetay(kampanyadetayi: tappedRow.getCells()[0].value,)),
                  );*/

              },
              columns: <GridColumn>[
                GridColumn(

                  width: width*0,
                  columnName: 'arsiv',
                  label: Container(

                    padding: EdgeInsets.all(5.0),
                    alignment: Alignment.centerLeft,
                    child: Text('a'),
                  ),
                ),
                GridColumn(

                  width: width*0,
                  columnName: 'id',
                  label: Container(

                    padding: EdgeInsets.all(5.0),
                    alignment: Alignment.centerLeft,
                    child: Text('#'),
                  ),
                ),
                GridColumn(

                  width: width*0.2,
                  columnName: 'tarih',
                  label: Container(

                    padding: EdgeInsets.all(5.0),
                    alignment: Alignment.centerLeft,
                    child: Text('Tarih'),
                  ),
                ),
                GridColumn(

                  width: width*0.2,
                  columnName: 'musteridanisan',
                  label: Container(

                    padding: EdgeInsets.all(5.0),
                    alignment: Alignment.centerLeft,
                    child: Text('Müşteri'),
                  ),
                ),
                GridColumn(
                  width: width*0.2,
                  columnName: 'formadi',
                  label: Container(
                    padding: EdgeInsets.all(5.0),
                    alignment: Alignment.centerLeft,
                    child: Text('Form Adı'),
                  ),
                ),
                GridColumn(
                  width: width*0,
                  columnName: 'durum',
                  label: Container(
                    padding: EdgeInsets.all(5.0),
                    alignment: Alignment.centerLeft,
                    child: Text('Durum'),
                  ),
                ),
                GridColumn(
                  width: width*0,
                  columnName: 'cevaplandi',
                  label: Container(
                    padding: EdgeInsets.all(5.0),
                    alignment: Alignment.centerLeft,
                    child: Text('cvp'),
                  ),
                ),
                GridColumn(
                  width: width*0,
                  columnName: 'cevaplandi2',
                  label: Container(
                    padding: EdgeInsets.all(5.0),
                    alignment: Alignment.centerLeft,
                    child: Text('cvp2'),
                  ),
                ),
                GridColumn(
                  width: width*0.3,
                  columnName: 'durum_text',
                  label: Container(
                    padding: EdgeInsets.all(5.0),
                    alignment: Alignment.centerLeft,
                    child: Text('Durum'),
                  ),
                ),

                GridColumn(
                  width: width*0.1,
                  columnName: 'islem',
                  label: Container(
                    padding: EdgeInsets.all(5.0),
                    alignment: Alignment.center,
                    child: Text("")
                  ),
                ),
              ],
            ),
          ),
          _buildPaginationControls()
        ],
      ),
    );



  }
  Widget _buildPaginationControls() {

    final totalPages = (_arsivDataGridSource.totalPages).ceil();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: _arsivDataGridSource.currentPage > 1
              ? () {
            setState(() {

              _arsivDataGridSource.setPage(_arsivDataGridSource.currentPage - 1);
            });
          }
              : null,
        ),
        Text('Sayfa ${_arsivDataGridSource.currentPage} / $totalPages'),
        IconButton(
          icon: Icon(Icons.arrow_forward),
          onPressed: _arsivDataGridSource.currentPage < totalPages
              ? () {
            setState(() {
              _arsivDataGridSource.setPage(_arsivDataGridSource.currentPage + 1);
            });
          }
              : null,
        ),
      ],
    );
  }
}

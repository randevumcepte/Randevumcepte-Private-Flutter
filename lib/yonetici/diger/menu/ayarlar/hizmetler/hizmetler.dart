import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../../../../../Backend/backend.dart';
import '../../../../../Frontend/altyuvarlakmenu.dart';
import '../../../../../Frontend/sfdatatable.dart';
import '../../../../../yeni/hizmet.dart';



class Hizmetler extends StatefulWidget {
  final dynamic isletmebilgi;
  Hizmetler({Key? key,required this.isletmebilgi}) : super(key: key);

  @override
  _HizmetlerState createState  () => _HizmetlerState();


}

class _HizmetlerState extends State<Hizmetler> {
  late List<bool> selectedRows;
  late String? seciliisletme;
  bool _isLoading = true;
  late HizmetlerDataSource _hizmetDataGridSource;
  TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    initialize();
    _controller.addListener(() {
      _hizmetDataGridSource.search(_controller.text);
    });
  }

  Future<void> initialize() async {
    seciliisletme = await secilisalonid();
    setState(() {
      _hizmetDataGridSource = HizmetlerDataSource(
          rowsPerPage: 10,
          salonid: seciliisletme!,
          context: context,
          baslik: _controller.text,
          isletmebilgi: widget.isletmebilgi
      );
      _hizmetDataGridSource.isLoadingNotifier.addListener(_onLoadingStateChanged);
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
    double width = MediaQuery
        .of(context)
        .size
        .width;
    double height = MediaQuery
        .of(context)
        .size
        .height;
    return   _isLoading
        ? Center(child: CircularProgressIndicator())
        : GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus(); // Hide the keyboard
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,

        appBar: AppBar(
          backgroundColor: Colors.white,
          toolbarHeight: 60,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            "Hizmetler",
            style: TextStyle(color: Colors.black),
          ),
          actions: <Widget>[
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: SizedBox(
                  width: 100, // <-- Your width
                  child: YukseltButonu(isletme_bilgi:widget.isletmebilgi)
              ),
            ),
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HizmetSecimi(isletmebilgi: widget.isletmebilgi,hizmetDataGridSource: _hizmetDataGridSource,)),
                );
              },
              icon: Icon(Icons.add, color: Colors.black),
              iconSize: 26,
            ),
          ],
        ),
        body:_isLoading
            ? Center(child: CircularProgressIndicator())
            : GestureDetector(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  controller: _controller,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    hintText: 'Hizmet Ara...',
                    enabled: true,
                    focusColor: Color(0xFF6A1B9A),
                    hoverColor: Color(0xFF6A1B9A),
                    hintStyle: TextStyle(color: Color(0xFF6A1B9A)),
                    contentPadding: EdgeInsets.all(5.0),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF6A1B9A)),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF6A1B9A)),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                ),
              ),
              Expanded(

                child: SfDataGrid(
                  source: _hizmetDataGridSource,
                  shrinkWrapRows: true,
                  columnWidthMode: ColumnWidthMode.fill,
                  defaultColumnWidth: 120,
                  allowSwiping: true,
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

                  onCellTap: (DataGridCellTapDetails details) {
                    final tappedRow = _hizmetDataGridSource
                        .rows[details.rowColumnIndex.rowIndex - 1];
                    _hizmetDataGridSource.showDetailsDialog(
                        context, tappedRow.getCells()[0].value);
                  },
                  columns: <GridColumn>[
                    GridColumn(
                      width: width * 0,
                      columnName: 'hizmet',
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
                      columnName: 'hizmetadi',
                      label: Container(
                        padding: EdgeInsets.all(5.0),
                        alignment: Alignment.centerLeft,
                        child: Text('Hizmet Adı'),
                      ),
                    ),
                    GridColumn(
                      width: width * 0.75,
                      columnName: 'personel',
                      label: Container(
                        padding: EdgeInsets.all(5.0),
                        alignment: Alignment.centerLeft,
                        child: Text('Personeller | Cihazlar'),
                      ),

                    ),


                  ],
                ),
              ),
               _buildPaginationControls()
            ],
          ),
        ),
      ),
    );

  }

  Widget _buildPaginationControls() {

    final totalPages = (_hizmetDataGridSource.totalPages).ceil();
    log("total pages ilk "+ totalPages.toString());
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: _hizmetDataGridSource.currentPage > 1
              ? () {
            setState(() {
              _hizmetDataGridSource
                  .setPage(_hizmetDataGridSource.currentPage - 1);
            });
          }
              : null,
        ),
        Text('Sayfa ${_hizmetDataGridSource.currentPage} / $totalPages'),
        IconButton(
          icon: Icon(Icons.arrow_forward),
          onPressed: _hizmetDataGridSource.currentPage < totalPages
              ? () {
            setState(() {
              _hizmetDataGridSource
                  .setPage(_hizmetDataGridSource.currentPage + 1);
            });
          }
              : null,
        ),
      ],
    );
  }
}

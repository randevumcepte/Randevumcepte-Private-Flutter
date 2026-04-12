import 'dart:async';
import 'package:flutter/material.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../../../../Models/ajanda.dart';
import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Frontend/altyuvarlakmenu.dart';
import 'package:randevu_sistem/Frontend/sfdatatable.dart';
import '../../../dashboard/gunlukRaporlar/gunlukajandanotlari.dart';
import 'ajandaduzenle.dart';
import 'ajandaekle.dart';

class AjandaNotlar extends StatefulWidget {
  final dynamic isletmebilgi;
  AjandaNotlar({Key? key, required this.isletmebilgi}) : super(key: key);

  @override
  _AjandaNotlarState createState() => _AjandaNotlarState();
}

class _AjandaNotlarState extends State<AjandaNotlar> {
  TextEditingController _controller = TextEditingController();
  late AjandaDataSource _ajandaDataGridSource;
  late List<bool> selectedRows;
  late String? seciliisletme;
  bool _isLoading = true;
  Timer? _debounce;
  Timer? _throttle;// Timer for debouncing
  int totalPages = 1;
  bool firsttimetyping = true;
  String? lastQuery;
  bool _isDisposed = false; // Yeni: dispose kontrolü

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
            _ajandaDataGridSource.search(_controller.text);
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
  // Debounce method to delay the API call


  Future<void> initialize() async {
    seciliisletme = await secilisalonid();
    setState(() {
      _ajandaDataGridSource = AjandaDataSource(
        isletmebilgi: widget.isletmebilgi,
        rowsPerPage: 10,
        salonid: seciliisletme!,
        context: context,
        baslik: _controller.text,
      );
      _ajandaDataGridSource.isLoadingNotifier.addListener(_onLoadingStateChanged);
      _isLoading = false;
    });
  }

  void _onLoadingStateChanged() {
    if (!_isDisposed && mounted) {
      setState(() {
        // Sadece mounted ve disposed değilse setState çağır
      });
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _debounce?.cancel();
    _controller.dispose();
    // DataSource'i dispose et
    if (_ajandaDataGridSource.isLoadingNotifier.hasListeners) {
      _ajandaDataGridSource.isLoadingNotifier.removeListener(_onLoadingStateChanged);
    }
    _ajandaDataGridSource.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double height = MediaQuery.of(context).size.height;

    // Determine if the keyboard is visible by checking the view insets (keyboard height)
    final bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return _isLoading
        ? Center(child: CircularProgressIndicator())
        : GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus(); // Hide the keyboard
      },
      child: Scaffold(

        appBar: AppBar(
          title: Text('Ajanda', style: TextStyle(color: Colors.black, fontSize: 18)),
          /*leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),*/
          toolbarHeight: 60,
          actions: <Widget>[
            if (widget.isletmebilgi["demo_hesabi"].toString() == "1")
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: SizedBox(
                width: 100,
                child: YukseltButonu(isletme_bilgi: widget.isletmebilgi,),
              ),
            ),
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AjandaEkle(
                      isletmebilgi: widget.isletmebilgi,
                      ajandaDataSource: _ajandaDataGridSource,
                    ),
                  ),
                );
              },
              icon: Icon(Icons.add, color: Colors.black),
              iconSize: 26,
            ),
          ],
          backgroundColor: Colors.white,
        ),
        body: LayoutBuilder(
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
                    source: _ajandaDataGridSource,
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
                    startSwipeActionsBuilder: (BuildContext context, DataGridRow row, int rowIndex) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => AjandaDuzenle(
                                    isletmebilgi: widget.isletmebilgi,
                                    notdetayi: row.getCells()[0].value as Ajanda,
                                    ajandaDataSource: _ajandaDataGridSource,
                                  )));
                        },
                        child: Container(
                            color: Colors.purple,
                            child: Center(
                              child: Icon(Icons.edit, color: Colors.white),
                            )),
                      );
                    },
                    endSwipeActionsBuilder: (BuildContext context, DataGridRow row, int rowIndex) {
                      return GestureDetector(
                        onTap: () async {
                          _ajandaDataGridSource.showAjandaSilmeConfirmationDialog(context, row.getCells()[1].value);
                        },
                        child: Container(
                            color: Colors.red,
                            child: Center(
                              child: Icon(Icons.delete, color: Colors.white),
                            )),
                      );
                    },
                
                    columns: <GridColumn>[
                      GridColumn(
                        width: width * 0,
                        columnName: 'ajanda',
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
                        columnName: 'tarihsaat',
                        label: Container(
                          padding: EdgeInsets.all(5.0),
                          alignment: Alignment.centerLeft,
                          child: Text('Tarih & Saat'),
                        ),
                      ),
                      GridColumn(
                        width: width * 0.3,
                        columnName: 'baslik',
                        label: Container(
                          padding: EdgeInsets.all(5.0),
                          alignment: Alignment.centerLeft,
                          child: Text('Başlık'),
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
                            child: Text("")),
                      ),
                    ],
                  ),
                ),
                 _buildPaginationControls(),
              ],
            );
          },
        ),
      ),
    );
  }


  Widget _buildPaginationControls() {
    final totalPages = (_ajandaDataGridSource.totalPages).ceil();
    return  Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: _ajandaDataGridSource.currentPage > 1
                ? () {
              setState(() {
                _ajandaDataGridSource.setPage(_ajandaDataGridSource.currentPage - 1);
              });
            }
                : null,
          ),
          Text('Sayfa ${_ajandaDataGridSource.currentPage} / $totalPages'),
          IconButton(
            icon: Icon(Icons.arrow_forward),
            onPressed: _ajandaDataGridSource.currentPage < totalPages
                ? () {
              setState(() {
                _ajandaDataGridSource.setPage(_ajandaDataGridSource.currentPage + 1);
              });
            }
                : null,
          ),
        ],

    );

  }
}
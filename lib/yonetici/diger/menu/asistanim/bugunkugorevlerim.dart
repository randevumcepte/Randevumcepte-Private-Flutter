import 'dart:async';
import 'package:flutter/material.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../../../../Models/ajanda.dart';
import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Frontend/altyuvarlakmenu.dart';
import 'package:randevu_sistem/Frontend/sfdatatable.dart';
import '../../../../Models/e_asistan.dart';
import '../../../dashboard/gunlukRaporlar/gunlukajandanotlari.dart';


 class BugunlukGorevler extends StatefulWidget {
  final dynamic isletmebilgi;
BugunlukGorevler({Key? key, required this.isletmebilgi}) : super(key: key);

  @override
  _BugunlukGorevlerState createState() => _BugunlukGorevlerState();
}

class _BugunlukGorevlerState extends State<BugunlukGorevler> {
  TextEditingController _controller = TextEditingController();
  late EAsistanDataSource _easistanDataGridSource;
  late List<bool> selectedRows;
  late String? seciliisletme;
  bool _isLoading = true;
  Timer? _debounce;
  Timer? _throttle;// Timer for debouncing
  int totalPages = 1;
  bool firsttimetyping = true;
  String? lastQuery;
  DateTime today = DateTime.now();
  @override
  void initState() {
    super.initState();
    initialize();


  }

  Future<void> initialize() async {
    seciliisletme = await secilisalonid();
    setState(() {
      _easistanDataGridSource = EAsistanDataSource(
        isletmebilgi: widget.isletmebilgi,
        rowsPerPage: 10,
        salonid: seciliisletme!,
        context: context,
        bugunyarin: today.toString(), // Bugün tarihini filtre olarak gönderiyoruz
      );
      _easistanDataGridSource.isLoadingNotifier.addListener(_onLoadingStateChanged);
      _isLoading = false;
    });
  }


  void _onLoadingStateChanged() {
    setState(() {
      // This empty setState function triggers a rebuild when the loading state changes
    });
  }

  @override
  void dispose() {
    _debounce?.cancel(); // Cancel the debounce timer when the widget is disposed
    _controller.dispose();
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
        resizeToAvoidBottomInset: false,

        body: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [

                // build metodu içinde Expanded yerine şu yapıyı kullan:
                Expanded(
                  child: _easistanDataGridSource.rows.isEmpty
                      ? Center(
                    child: Text(
                      "Tabloda herhangi bir veri bulunmamaktadır",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  )
                      : SfDataGrid(
                    source: _easistanDataGridSource,
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
                    onCellTap: (DataGridCellTapDetails details) {
                      if (details.rowColumnIndex.rowIndex > 0) { // Başlık satırını atlamak için
                        final int rowIndex = details.rowColumnIndex.rowIndex - 1;
                        final task = _easistanDataGridSource.rows[details.rowColumnIndex.rowIndex - 1];

                        _easistanDataGridSource.showTaskDetails(context, task.getCells()[0].value);
                      }
                    },
                    columns: <GridColumn>[
                      GridColumn(
                        width: width * 0,
                        columnName: 'asistan',
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
                        width: width * 0.30,
                        columnName: 'baslik',
                        label: Container(
                          padding: EdgeInsets.all(5.0),
                          alignment: Alignment.centerLeft,
                          child: Text('Başlık'),
                        ),
                      ),
                      GridColumn(
                        width: width * 0.30,
                        columnName: 'aramasaati',
                        label: Container(
                          padding: EdgeInsets.all(5.0),
                          alignment: Alignment.centerLeft,
                          child: Text('Arama Saati'),
                        ),
                      ),
                      GridColumn(
                        width: width * 0.40,
                        columnName: 'sonuc',
                        label: Container(
                          padding: EdgeInsets.all(5.0),
                          alignment: Alignment.centerLeft,
                          child: Text('Sonuç'),
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
    final totalPages = (_easistanDataGridSource.totalPages).ceil();
    return  Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: _easistanDataGridSource.currentPage > 1
              ? () {
            setState(() {
              _easistanDataGridSource.setPage(_easistanDataGridSource.currentPage - 1);
            });
          }
              : null,
        ),
        Text('Sayfa ${_easistanDataGridSource.currentPage} / $totalPages'),
        IconButton(
          icon: Icon(Icons.arrow_forward),
          onPressed: _easistanDataGridSource.currentPage < totalPages
              ? () {
            setState(() {
              _easistanDataGridSource.setPage(_easistanDataGridSource.currentPage + 1);
            });
          }
              : null,
        ),
      ],

    );

  }
}
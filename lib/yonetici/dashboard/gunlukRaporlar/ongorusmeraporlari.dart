import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:randevu_sistem/yonetici/dashboard/gunlukRaporlar/ongorduzenle.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import '../../../Backend/backend.dart';
import '../../../Frontend/altyuvarlakmenu.dart';
import '../../../Frontend/sfdatatable.dart';
import '../../diger/menu/ongorusmeler/ongorusmeduzenle.dart';

class OnGorusmelerDashboard extends StatefulWidget {
  final dynamic isletmebilgi;
  OnGorusmelerDashboard({Key? key,required this.isletmebilgi}) : super(key: key);
  @override
  _OnGorusmelerDashboardState createState() => _OnGorusmelerDashboardState();
}

class _OnGorusmelerDashboardState extends State<OnGorusmelerDashboard> {
  TextEditingController _controller = TextEditingController();
  OnGorusmeDataSource2? _ongorusmeDataGridSource;
  late String? seciliisletme;

  bool _isLoading = true;
  TextEditingController musteriController = TextEditingController();
  int totalPages = 1;
  bool anyChecked = false;
  bool selectAll = false;
  Timer? _debounce;
  bool firsttimetyping=true;
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
    if (_controller.text.length == 0 || _controller.text.length >= 3) {
      if (_debounce?.isActive ?? false) _debounce!.cancel();

      _debounce = Timer(const Duration(milliseconds: 500), () {
        if (_controller.text != lastQuery && !firsttimetyping) {
          setState(() {
            firsttimetyping=false;
            lastQuery = _controller.text;
            _ongorusmeDataGridSource?.search(_controller.text.isEmpty ? '' : _controller.text); // Boşsa null gönder
          });
        }
      });
    } else {
      if((_controller.text == '' || _controller.text.length<3) && firsttimetyping) {
        setState(() {
          firsttimetyping = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    musteriController.dispose();
    super.dispose();
  }

  Future<void> initialize() async {
    try {
      seciliisletme = await secilisalonid();

      // DataSource'i oluştur - başlangıçta arama parametresi null olacak
      final dataSource = OnGorusmeDataSource2(
        isletmebilgi: widget.isletmebilgi,
        rowsPerPage: 10,
        salonid: seciliisletme!,
        context: context,
        arama: '', // Başlangıçta null gönder
      );

      setState(() {
        _ongorusmeDataGridSource = dataSource;
        _ongorusmeDataGridSource?.isLoadingNotifier.addListener(_onLoadingStateChanged);
        _isLoading = false;
      });
    } catch (e) {
      log("Initialize error: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onLoadingStateChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Ön Görüşmeler', style: TextStyle(color: Colors.black)),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
          backgroundColor: Colors.white,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_ongorusmeDataGridSource == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Ön Görüşmeler', style: TextStyle(color: Colors.black)),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
          backgroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Veriler yüklenirken bir hata oluştu'),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: initialize,
                child: Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Ön Görüşmeler', style: TextStyle(color: Colors.black)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        toolbarHeight: 60,
        actions: [
          if (widget.isletmebilgi["demo_hesabi"].toString() == "1")
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: SizedBox(
                width: 100,
                child: YukseltButonu(isletme_bilgi: widget.isletmebilgi),
              ),
            ),
        ],
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextFormField(
                controller: _controller,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  hintText: 'Müşteri/danışan adı...',
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
            Container(
              height: height - 275,
              child: SfDataGrid(
                source: _ongorusmeDataGridSource!,
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OnGorusmeDuzenleOzet(
                            isletmebilgi: widget.isletmebilgi,
                            ongorusme: row.getCells()[0].value,
                            ongorusmedatasource: _ongorusmeDataGridSource!,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      color: Colors.purple,
                      child: Center(
                        child: Icon(Icons.edit, color: Colors.white),
                      ),
                    ),
                  );
                },
                endSwipeActionsBuilder: (BuildContext context, DataGridRow row, int rowIndex) {
                  return GestureDetector(
                    onTap: () async {
                      // Add your delete logic here
                    },
                    child: Container(
                      color: Colors.red,
                      child: Center(
                        child: Icon(Icons.delete, color: Colors.white),
                      ),
                    ),
                  );
                },
                onCellTap: (DataGridCellTapDetails details) {
                  final tappedRow = _ongorusmeDataGridSource!.rows[details.rowColumnIndex.rowIndex - 1];
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OnGorusmeDuzenleOzet(
                        isletmebilgi: widget.isletmebilgi,
                        ongorusmedatasource: _ongorusmeDataGridSource!,
                        ongorusme: tappedRow.getCells()[0].value,
                      ),
                    ),
                  );
                },
                columns: <GridColumn>[
                  GridColumn(
                    width: width * 0,
                    columnName: 'ongorusme',
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
                    columnName: 'musteridanisan',
                    label: Container(
                      padding: EdgeInsets.all(5.0),
                      alignment: Alignment.centerLeft,
                      child: Text('Müşteri/Danışan'),
                    ),
                  ),
                  GridColumn(
                    width: width * 0.3,
                    columnName: 'paketurun',
                    label: Container(
                      padding: EdgeInsets.all(5.0),
                      alignment: Alignment.centerLeft,
                      child: Text('Paket/Ürün'),
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
                        child: Text("")
                    ),
                  ),
                ],
              ),
            ),
            _buildPaginationControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationControls() {
    if (_ongorusmeDataGridSource == null) {
      return SizedBox();
    }

    final totalPages = (_ongorusmeDataGridSource!.totalPages).ceil();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: _ongorusmeDataGridSource!.currentPage > 1
              ? () {
            setState(() {
              _ongorusmeDataGridSource!.setPage(_ongorusmeDataGridSource!.currentPage - 1);
            });
          }
              : null,
        ),
        Text('Sayfa ${_ongorusmeDataGridSource!.currentPage} / $totalPages'),
        IconButton(
          icon: Icon(Icons.arrow_forward),
          onPressed: _ongorusmeDataGridSource!.currentPage < totalPages
              ? () {
            setState(() {
              _ongorusmeDataGridSource!.setPage(_ongorusmeDataGridSource!.currentPage + 1);
            });
          }
              : null,
        ),
      ],
    );
  }
}
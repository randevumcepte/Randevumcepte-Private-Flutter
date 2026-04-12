import 'dart:async';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../../../../Frontend/sfdatatable.dart';
import '../../../../Models/e_asistan.dart';
import 'package:randevu_sistem/Backend/backend.dart';

class BugunlukGorevler extends StatefulWidget {
  final dynamic isletmebilgi;
  BugunlukGorevler({Key? key, required this.isletmebilgi}) : super(key: key);

  @override
  _BugunlukGorevlerState createState() => _BugunlukGorevlerState();
}

class _BugunlukGorevlerState extends State<BugunlukGorevler> {
  TextEditingController _controller = TextEditingController();
  late EAsistanDataSource _easistanDataGridSource;
  late String? seciliisletme;
  bool _isLoading = true;
  DateTime today = DateTime.now();

  @override
  void initState() {
    super.initState();
    initialize();
  }

  Future<void> initialize() async {
    seciliisletme = await secilisalonid();
    _easistanDataGridSource = EAsistanDataSource(
      isletmebilgi: widget.isletmebilgi,
      rowsPerPage: 10,
      salonid: seciliisletme!,
      context: context,
      bugunyarin: today.toString(),
    );
    _easistanDataGridSource.isLoadingNotifier.addListener(() {
      setState(() {}); // Loading state değişirse rebuild
    });
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Text yüksekliğini hesaplayan fonksiyon
  double calculateTextHeight(String text, double maxWidth, TextStyle style, {int maxLines = 3}) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: maxLines,
    );
    textPainter.layout(maxWidth: maxWidth);
    return textPainter.height + 10; // padding
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;

    return _isLoading
        ? Center(child: CircularProgressIndicator())
        : GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Column(
          children: [
            Expanded(
              child: _easistanDataGridSource.rows.isEmpty
                  ? Center(
                child: Text(
                  "Tabloda herhangi bir veri bulunmamaktadır",
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              )
                  : SfDataGrid(
                source: _easistanDataGridSource,
                shrinkWrapRows: true,
                columnWidthMode: ColumnWidthMode.fill,
                defaultColumnWidth: 120,
                allowSwiping: true,
                onQueryRowHeight: (details) {
                  if (details.rowIndex == 0) {
                    return details.rowHeight; // header
                  }

                  final row = _easistanDataGridSource
                      .effectiveRows[details.rowIndex - 1];

                  // Tüm kolonlar için genişlikler
                  final columnWidths = {
                    'asistan': width * 0.0,
                    'id': width * 0.0,
                    'baslik': width * 0.35 - 10,
                    'aramasaati': width * 0.25 - 10,
                    'sonuc': width * 0.40 - 10,
                    'islem': width * 0.1 - 10,
                  };

                  double maxHeight = 0;
                  row.getCells().forEach((cell) {
                    if (columnWidths.containsKey(cell.columnName)) {
                      final cellText = cell.value.toString();
                      final cellHeight = calculateTextHeight(
                        cellText,
                        columnWidths[cell.columnName]!,
                        const TextStyle(fontSize: 14),
                      );
                      if (cellHeight > maxHeight) {
                        maxHeight = cellHeight;
                      }
                    }
                  });

                  return maxHeight;
                },
                onCellTap: (DataGridCellTapDetails details) {
                  if (details.rowColumnIndex.rowIndex > 0) {
                    final task = _easistanDataGridSource.rows[
                    details.rowColumnIndex.rowIndex - 1];
                    _easistanDataGridSource.showTaskDetails(
                        context, task.getCells()[0].value);
                  }
                },
                columns: [
                  GridColumn(
                    columnName: 'asistan',
                    width: width * 0.0,
                    label: Container(),
                  ),
                  GridColumn(
                    columnName: 'id',
                    width: width * 0.0,
                    label: Container(),
                  ),
                  GridColumn(
                    columnName: 'baslik',
                    width: width * 0.30,
                    label: Container(
                      padding: EdgeInsets.all(5),
                      alignment: Alignment.centerLeft,
                      child: Text('Müşteri/Danışan'),
                    ),
                  ),
                  GridColumn(
                    columnName: 'aramasaati',
                    width: width * 0.20,
                    label: Container(
                      padding: EdgeInsets.all(5),
                      alignment: Alignment.centerLeft,
                      child: Text('Arama Saati'),
                    ),
                  ),
                  GridColumn(
                    columnName: 'sonuc',
                    width: width * 0.50,
                    label: Container(
                      padding: EdgeInsets.all(5),
                      alignment: Alignment.centerLeft,
                      child: Text('Sonuç'),
                    ),
                  ),
                  GridColumn(
                    columnName: 'islem',
                    width: width * 0.0,
                    label: Container(
                      padding: EdgeInsets.all(5),
                      alignment: Alignment.center,
                      child: Text(''),
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
    final totalPages = (_easistanDataGridSource.totalPages).ceil();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: _easistanDataGridSource.currentPage > 1
              ? () {
            setState(() {
              _easistanDataGridSource
                  .setPage(_easistanDataGridSource.currentPage - 1);
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
              _easistanDataGridSource
                  .setPage(_easistanDataGridSource.currentPage + 1);
            });
          }
              : null,
        ),
      ],
    );
  }
}

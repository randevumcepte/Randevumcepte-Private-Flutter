import 'package:flutter/material.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../../../../../Backend/backend.dart';
import '../../../../../Frontend/altyuvarlakmenu.dart';
import '../../../../../Frontend/sfdatatable.dart';
import 'odaekle.dart';


class Odalar extends StatefulWidget {
  final dynamic isletmebilgi;
  Odalar({Key? key,required this.isletmebilgi}) : super(key: key);

  @override
  _OdalarState createState() => _OdalarState();
}

class _OdalarState extends State<Odalar> {
  late List<bool> selectedRows;
  late String? seciliisletme;
  bool _isLoading = true;
  late OdaDataSource _odaDataGridSource;
  TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    initialize();
    _controller.addListener(() {
      _odaDataGridSource.search(_controller.text);
    });
  }

  Future<void> initialize() async {
    seciliisletme = await secilisalonid();
    setState(() {
      _odaDataGridSource = OdaDataSource(
        rowsPerPage: 10,
        salonid: seciliisletme!,
        context: context,
        baslik: _controller.text,
      );
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return _isLoading
        ? Center(child: CircularProgressIndicator())
        : GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus(); // Hide the keyboard
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
            "Odalar",
            style: TextStyle(color: Colors.black),
          ),
          actions: <Widget>[
            if (widget.isletmebilgi["demo_hesabi"].toString() == "1")
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: SizedBox(
                width: 100, // <-- Your width
                child: YukseltButonu(isletme_bilgi: widget.isletmebilgi,)
              ),
            ),
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => OdaEkle(odadatasource: _odaDataGridSource,isletmebilgi: widget.isletmebilgi,)),
                );
              },
              icon: Icon(Icons.add, color: Colors.black),
              iconSize: 26,
            ),
          ],
      ),
      body: GestureDetector(

          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  controller: _controller,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    hintText: 'Oda...',
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
                  source: _odaDataGridSource,
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
                  startSwipeActionsBuilder:
                      (BuildContext context, DataGridRow row, int rowIndex) {
                    return GestureDetector(
                      onTap: () {
                        // Handle edit action
                      },
                      child: Container(
                        color: Colors.purple,
                        child: Center(
                          child: Icon(Icons.edit, color: Colors.white),
                        ),
                      ),
                    );
                  },
                  endSwipeActionsBuilder:
                      (BuildContext context, DataGridRow row, int rowIndex) {
                    return GestureDetector(
                      onTap: () async {
                        // Handle delete action
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
                    final tappedRow = _odaDataGridSource
                        .rows[details.rowColumnIndex.rowIndex - 1];
                    _odaDataGridSource.showDetailsDialog(
                        context, tappedRow.getCells()[0].value);
                  },
                  columns: <GridColumn>[
                    GridColumn(
                      width: width * 0,
                      columnName: 'oda',
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
                      columnName: 'odaadi',
                      label: Container(
                        padding: EdgeInsets.all(5.0),
                        alignment: Alignment.centerLeft,
                        child: Text('Oda Adı'),
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
                        alignment: Alignment.centerLeft,
                        child: Text('Durum',),

                      ),

                    ),
                    GridColumn(
                      width: width * 0.3,
                      columnName: 'aciklama',
                      label: Container(
                        padding: EdgeInsets.all(5.0),
                        alignment: Alignment.centerLeft,
                        child: Text('Açıklama'),
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
    ),
        );
  }

  Widget _buildPaginationControls() {
    final totalPages = (_odaDataGridSource.totalPages).ceil();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: _odaDataGridSource.currentPage > 1
              ? () {
            setState(() {
              _odaDataGridSource
                  .setPage(_odaDataGridSource.currentPage - 1);
            });
          }
              : null,
        ),
        Text('Sayfa ${_odaDataGridSource.currentPage} / $totalPages'),
        IconButton(
          icon: Icon(Icons.arrow_forward),
          onPressed: _odaDataGridSource.currentPage < totalPages
              ? () {
            setState(() {
              _odaDataGridSource
                  .setPage(_odaDataGridSource.currentPage + 1);
            });
          }
              : null,
        ),
      ],
    );
  }
}
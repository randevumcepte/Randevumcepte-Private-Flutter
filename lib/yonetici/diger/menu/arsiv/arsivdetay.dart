import 'dart:async';

import 'package:flutter/material.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Models/form.dart';
import '../../../../../Frontend/altyuvarlakmenu.dart';
import '../../../../../Frontend/arsivdetay.dart';
import '../../../../../Frontend/sfdatatable.dart';
import '../../../../../Models/musteri_danisanlar.dart';

class ArsivDetay extends StatefulWidget {
  final MusteriDanisan md;
  final dynamic isletmebilgi;
  const ArsivDetay({Key? key, required this.md,required this.isletmebilgi}) : super(key: key);

  @override
  _ArsivDetayState createState() => _ArsivDetayState();
}

class _ArsivDetayState extends State<ArsivDetay> {
  late ArsivDataSource _arsivDataGridSource;
  bool _isLoading = true;
  late String? seciliisletme;
  final TextEditingController _controller = TextEditingController();
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
  Future<void> initialize() async {
    seciliisletme = await secilisalonid();
    _arsivDataGridSource = ArsivDataSource(
      cevapladi: '',
      cevapladi2: '',
      rowsPerPage: 10,
      salonid: seciliisletme!,
      context: context,
      durum: '',
      arama: _controller.text,
     musteriid: widget.md.id,

    );
    _arsivDataGridSource.isLoadingNotifier.addListener(_onLoadingStateChanged);
    setState(() {
      _isLoading = false;
    });
  }

  void _onLoadingStateChanged() {
    setState(() {
      // Trigger a rebuild when the loading state changes
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _arsivDataGridSource.isLoadingNotifier.removeListener(_onLoadingStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double height = MediaQuery.of(context).size.height;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      // floatingActionButton: AltYuvarlakYeniEkleMenu(isletme_bilgi: widget.isletmebilgi,),
      appBar: AppBar(
        title: Text(
          '${widget.md.name} Sözleşme/Belgeleri',
          style: TextStyle(color: Colors.black, fontSize: 18),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        toolbarHeight: 60,
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: SizedBox(
              width: 100, // <-- Your width
              child: YukseltButonu(isletme_bilgi: widget.isletmebilgi,)
            ),
          ),
        ],
        backgroundColor: Colors.white,
      ),
      body: GestureDetector(


        onTap: () {
        FocusScope.of(context).unfocus(); // Hide the keyboard
        },
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  controller: _controller,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    hintText: 'Müşteri/Danışan Adı veya Form Adı...',
                    enabled: true,
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
              // Conditional rendering
              _arsivDataGridSource.rows.isEmpty
                  ? Padding(
                padding: const EdgeInsets.all(14.0),
                child: Center(
                  child: Text(
                    'Tabloda herhangi bir veri mevcut değil',
                    style: TextStyle(fontSize: 18, color: Colors.black),
                  ),
                ),
              )
                  : Container(
                height: height - 325,
                child: SfDataGrid(
                  source: _arsivDataGridSource,
                  columnWidthMode: ColumnWidthMode.fill,
                  defaultColumnWidth: 120,
                  allowSwiping: true,
                  onSwipeStart: (details) {
                    if (details.swipeDirection ==
                        DataGridRowSwipeDirection.startToEnd ||
                        details.swipeDirection ==
                            DataGridRowSwipeDirection.endToStart) {
                      details.setSwipeMaxOffset(0);
                    }
                    return true;
                  },
                  startSwipeActionsBuilder: (BuildContext context,
                      DataGridRow row, int rowIndex) {
                    return GestureDetector(
                      onTap: () {
                        // Handle edit action here
                      },
                      child: Container(
                        color: Colors.purple,
                        child: Center(
                            child: Icon(Icons.edit, color: Colors.white)),
                      ),
                    );
                  },
                  endSwipeActionsBuilder: (BuildContext context,
                      DataGridRow row, int rowIndex) {
                    return GestureDetector(
                      onTap: () async {
                        // Handle delete action here
                      },
                      child: Container(
                        color: Colors.red,
                        child: Center(
                            child: Icon(Icons.delete, color: Colors.white)),
                      ),
                    );
                  },
                  onCellTap: (DataGridCellTapDetails details) {
                    final tappedRow = _arsivDataGridSource
                        .rows[details.rowColumnIndex.rowIndex - 1];
                    ArsivDetayGosterDialog(
                        context, tappedRow.getCells()[0].value);
                  },
                  columns: _buildGridColumns(width),
                ),
              ),
              _buildPaginationControls(),
            ],
          ),
        ),
      ),
    );
  }

  List<GridColumn> _buildGridColumns(double width) {
    return [
      GridColumn(
        width: width * 0,
        columnName: 'arsiv',
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
        width: width * 0.2,
        columnName: 'tarih',
        label: Container(
          padding: EdgeInsets.all(5.0),
          alignment: Alignment.centerLeft,
          child: Text('Tarih'),
        ),
      ),
      GridColumn(
        width: width * 0.2,
        columnName: 'musteridanisan',
        label: Container(
          padding: EdgeInsets.all(5.0),
          alignment: Alignment.centerLeft,
          child: Text('Müşteri & Danışan'),
        ),
      ),
      GridColumn(
        width: width * 0.2,
        columnName: 'formadi',
        label: Container(
          padding: EdgeInsets.all(5.0),
          alignment: Alignment.centerLeft,
          child: Text('Form Adı'),
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
        columnName: 'cevaplandi',
        label: Container(
          padding: EdgeInsets.all(5.0),
          alignment: Alignment.centerLeft,
          child: Text('cvp'),
        ),
      ),
      GridColumn(
        width: width * 0,
        columnName: 'cevaplandi2',
        label: Container(
          padding: EdgeInsets.all(5.0),
          alignment: Alignment.centerLeft,
          child: Text('cvp2'),
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
    ];
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

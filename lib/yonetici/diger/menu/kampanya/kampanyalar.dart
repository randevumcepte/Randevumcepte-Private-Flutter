import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:randevu_sistem/Models/musteri_danisanlar.dart';
import 'package:randevu_sistem/Models/sms_taslaklari.dart';
import 'package:randevu_sistem/yonetici/diger/menu/kampanya/kampanyaduzenle.dart';
import 'package:randevu_sistem/yonetici/diger/menu/kampanya/kampanyaekle.dart';

import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:randevu_sistem/Frontend/backroutes.dart';
import 'package:randevu_sistem/yonetici/dashboard/home_screen.dart';
import 'package:randevu_sistem/Login%20Sayfas%C4%B1/checklogin.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:http/http.dart' as http;
import '../../../../Backend/backend.dart';
import '../../../../Frontend/sfdatatable.dart';
import '../../../../Models/kampanyalar.dart';
import '../../../../Models/paketler.dart';
import 'kampanyadetay.dart';
import 'package:randevu_sistem/Frontend/popupdialogs.dart';
import 'package:shared_preferences/shared_preferences.dart';


class Kampanyalar extends StatefulWidget {
  final dynamic isletmebilgi;
  Kampanyalar({Key? key, required this.isletmebilgi}) : super(key: key);
  @override
  _KampanyaPageState createState() => _KampanyaPageState();
}

class _KampanyaPageState extends State<Kampanyalar> {
  late KampanyaDataSource _kampanyaDataGridSource;

  List<Kampanya> _kampanyalar = [];
  late List<Kampanya> _filteredKampanyas = [];

  late String seciliisletme;
  late List<MusteriDanisan> fullmusteridanisanlistesi = [];
  late List<Paket>fullpaketlerlistesi = [];
  late List<SmsTaslak>fullsmstaslaklistesi =[];

  bool _isLoading = true;
  TextEditingController _controller = TextEditingController();
  bool firsttimetyping = true;
  String? lastQuery;

  Timer? _debounce;

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
            _kampanyaDataGridSource.search(_controller.text);
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
    seciliisletme = (await secilisalonid())!;

      setState(() {


        _kampanyaDataGridSource = KampanyaDataSource(  salonid: seciliisletme!,arama: _controller.text,context: context,rowsPerPage: 10,isletmebilgi: widget.isletmebilgi);
        _kampanyaDataGridSource.isLoadingNotifier.addListener(_onLoadingStateChanged);
        _isLoading = false;
      });


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
          home: Kampanyalar(isletmebilgi: widget.isletmebilgi,),
        );
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double height = MediaQuery.of(context).size.height;
    return  GestureDetector(
      onTap: () {
        // Unfocus the current text field, dismissing the keyboard
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(

          title: Text('Reklam Yönetimi',style: TextStyle(color: Colors.black,fontSize: 18),),
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
                    builder: (context) => KampanyaEkle(kampanyadatasource: _kampanyaDataGridSource,isletmebilgi: widget.isletmebilgi,)),
              );
            }, icon:  Icon(Icons.add,color:Colors.black,),iconSize: 26,),


          ],
          backgroundColor: Colors.white,




        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : LayoutBuilder(
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
                  source: _kampanyaDataGridSource,
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
                          Navigator.push(context, new MaterialPageRoute(builder: (context) => new KampanyaDuzenle(kampanyadetayi: row.getCells()[0].value as Kampanya, kampanyadatasource: _kampanyaDataGridSource,isletmebilgi: widget.isletmebilgi,)));
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
                          _kampanyaDataGridSource.showKampanyaSilmeConfirmationDialog(context, row.getCells()[1].value);


                        },
                        child: Container(
                            color: Colors.red,
                            child: Center(
                              child: Icon(Icons.delete,color: Colors.white,),
                            )));
                  },
                  onCellTap: (DataGridCellTapDetails details) {

                    final tappedRow = _kampanyaDataGridSource.rows[details.rowColumnIndex.rowIndex - 1];

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => KampanyaDetay(kampanyadetayi: tappedRow.getCells()[0].value,isletmebilgi: widget.isletmebilgi,)),
                    );

                  },
                  columns: <GridColumn>[
                    GridColumn(

                      width: width*0,
                      columnName: 'campaign',
                      label: Container(

                        padding: EdgeInsets.only(left:10.0),
                        alignment: Alignment.centerLeft,
                        child: Text('c'),
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
                      columnName: 'paket',
                      label: Container(

                        padding: EdgeInsets.only(left:10.0),
                        alignment: Alignment.centerLeft,
                        child: Text('Paket'),
                      ),
                    ),
                    GridColumn(
                      width: width*0.275,
                      columnName: 'hizmet',
                      label: Container(
                        //padding: EdgeInsets.all(5.0),
                        alignment: Alignment.centerLeft,
                        child: Text('Hizmet(-ler)'),
                      ),
                    ),
                    GridColumn(
                      width: width*0.15,
                      columnName: 'katilimci',
                      label: Container(
                        //padding: EdgeInsets.all(5.0),
                        alignment: Alignment.centerRight,
                        child: Text('Katılımcı'),
                      ),
                    ),
                    GridColumn(
                      width: width*0.15,
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
        ),


      ),
    );
  }
  Widget _buildPaginationControls() {

    final totalPages = (_kampanyaDataGridSource.totalPages).ceil();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: _kampanyaDataGridSource.currentPage > 1
              ? () {
            setState(() {

              _kampanyaDataGridSource.setPage(_kampanyaDataGridSource.currentPage - 1);
            });
          }
              : null,
        ),
        Text('Sayfa ${_kampanyaDataGridSource.currentPage} / $totalPages'),
        IconButton(
          icon: Icon(Icons.arrow_forward),
          onPressed: _kampanyaDataGridSource.currentPage < totalPages
              ? () {
            setState(() {
              _kampanyaDataGridSource.setPage(_kampanyaDataGridSource.currentPage + 1);
            });
          }
              : null,
        ),
      ],
    );
  }
}

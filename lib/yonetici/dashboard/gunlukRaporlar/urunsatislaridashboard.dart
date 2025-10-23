import 'dart:developer';

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import '../../../Backend/backend.dart';
import '../../../Frontend/altyuvarlakmenu.dart';
import '../../../Frontend/sfdatatable.dart';
import '../../../Models/urunsatislari.dart';
import '../../adisyonlar/musteri_detay.dart';

class UrunSatislariDashboard   extends StatefulWidget {
  final dynamic isletmebilgi;
  UrunSatislariDashboard  ({Key? key,required this.isletmebilgi}) : super(key: key);
  @override
  _UrunSatislariDashboardState createState() => _UrunSatislariDashboardState();
}


class _UrunSatislariDashboardState extends State<UrunSatislariDashboard  > {
  late UrunSatisDataSource _urunSatisDataSource;
  late String? seciliisletme;
  bool  _isLoading= true;

  TextEditingController _controller = TextEditingController();
  @override
  void initState() {
    super.initState();
    initialize();
    _controller.addListener(() {
      _urunSatisDataSource.search(_controller.text);
      log(_controller.text);
    });
  }
  Future<void> initialize() async {
    seciliisletme = await secilisalonid();
    urunsatislarigetir(seciliisletme!,'1','').then((data) {
      setState(() {


        _urunSatisDataSource = UrunSatisDataSource(rowsPerPage:10,salonid: seciliisletme!,context: context);
        _urunSatisDataSource.isLoadingNotifier.addListener(_onLoadingStateChanged);
        _isLoading = false;



      });
    });
  }

  void _onLoadingStateChanged() {
    setState(() {
      // This empty setState function just triggers a rebuild of the widget when the loading state changes
    });
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return _isLoading
        ? Center(child: CircularProgressIndicator())
        :Scaffold(
      //floatingActionButton: AltYuvarlakYeniEkleMenu(isletme_bilgi:widget.isletmebilgi),

      appBar: AppBar(
        title: Text('Ürün Satışları',style: TextStyle(color:Colors.black),),
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
              width: 100, // <-- Your width
              child: YukseltButonu(isletme_bilgi: widget.isletmebilgi,)
            ),
          ),


        ],
        backgroundColor: Colors.white,




      ),
      body: SingleChildScrollView(
        child:Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextFormField(

                controller: _controller,
                keyboardType: TextInputType.text,

                decoration: InputDecoration(
                  hintText: 'Müsteri Adı',
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

            _urunSatisDataSource.rows.isEmpty
                ? Center(child: Text("Tabloda herhangi bir veri mevcut değil"))
                : Container(
              height: height - 275,
              // Adjust the height based on your requirements
              child: _urunSatisDataSource != null
                  ? SfDataGrid(
                source: _urunSatisDataSource,
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
                onCellTap: (DataGridCellTapDetails details) {
                  final tappedRow = _urunSatisDataSource
                      .rows[details.rowColumnIndex.rowIndex - 1];
                  /*ArsivDetayGosterDialog(context );
                     Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => KampanyaDetay(kampanyadetayi: tappedRow.getCells()[0].value,)),
                      );*/
                },
                columns:<GridColumn> [
                  GridColumn(
                    width: width * 0,
                    columnName: 'paket',
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

                    width: width*0.4,
                    columnName: 'paketadi',
                    label: Container(

                      padding: EdgeInsets.all(5.0),
                      alignment: Alignment.centerLeft,
                      child: Text('Ürün Adı'),
                    ),
                  ),

                  GridColumn(
                    width: width*0.3,
                    columnName: 'musteridanisan',
                    label: Container(
                      padding: EdgeInsets.all(5.0),
                      alignment: Alignment.centerLeft,
                      child: Text('Müşteri'),
                    ),
                  ),


                  GridColumn(
                    width: width*0.2,
                    columnName: 'fiyat',
                    label: Container(
                      padding: EdgeInsets.all(5.0),
                      alignment: Alignment.centerRight,
                      child: Text('Fiyat ₺'),
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

              ) : Center(child: CircularProgressIndicator()),

            ),
            _buildPaginationControls()
          ],
        )
      ),
    );
  }
  Widget _buildPaginationControls() {

    final totalPages = (_urunSatisDataSource.totalPages).ceil();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: _urunSatisDataSource.currentPage > 1
              ? () {
            setState(() {

              _urunSatisDataSource.setPage(_urunSatisDataSource.currentPage - 1);
            });
          }
              : null,
        ),
        Text('Sayfa ${_urunSatisDataSource.currentPage} / $totalPages'),
        IconButton(
          icon: Icon(Icons.arrow_forward),
          onPressed: _urunSatisDataSource.currentPage < totalPages
              ? () {
            setState(() {
              _urunSatisDataSource.setPage(_urunSatisDataSource.currentPage + 1);
            });
          }
              : null,
        ),
      ],
    );
  }


  void _showDetailsDialog(BuildContext context, UrunSatisi urun) {
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          insetPadding: EdgeInsets.zero,
          content: Container(

            height: 190,
            width: 280,
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[

                Positioned(
                  right: -40,
                  top: -40,
                  child: InkResponse(
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                    child: const CircleAvatar(
                      backgroundColor: Colors.red,
                      child: Icon(Icons.close),
                    ),
                  ),
                ),

                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,

                    children: <Widget>[
                      SizedBox(height: 20,),
                      Text(urun.musteri,style: TextStyle(fontWeight: FontWeight.bold),),
                      Divider(color: Colors.black,
                        height: 10,),
                      Row(
                        children: [
                          Text('Ürün'),SizedBox(width: 27,),
                          Text(': '),
                          Text(urun.urun)
                        ],
                      ),
                      Row(
                        children: [
                          Text('Satan'),
                          SizedBox(width: 20,),
                          Text(': '),
                          Expanded(child: Text(urun.satan))
                        ],

                      ),
                      Row(
                        children: [
                          Text('Fiyat'),SizedBox(width: 26,),
                          Text(': '),
                          Text(urun.fiyat)
                        ],

                      ),

                      Divider(color: Colors.black,
                        height: 10,),

                      ElevatedButton(onPressed: (){
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => MusteriAdisyon()),
                        );
                      }, child:
                      Text('Tahsil Et'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple[800],
                            foregroundColor: Colors.white,
                            elevation: 5,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5.0)
                            ),
                            minimumSize: Size(130,30)
                        ),
                      ),




                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );


  }
}


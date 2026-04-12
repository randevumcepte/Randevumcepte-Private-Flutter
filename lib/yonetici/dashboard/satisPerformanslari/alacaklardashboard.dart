import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import '../../../Backend/backend.dart';
import '../../../Frontend/altyuvarlakmenu.dart';
import '../../../Frontend/sfdatatable.dart';
import '../../adisyonlar/musteri_detay.dart';


class AlacaklarDashboard extends StatefulWidget {
  final dynamic isletmebilgi;
  AlacaklarDashboard({Key? key,required this.isletmebilgi}) : super(key: key);
  @override
  _AlacaklarDashboardState createState() => _AlacaklarDashboardState();
}

class _AlacaklarDashboardState extends State<AlacaklarDashboard> {
  late AlacaklarDataSource _alacaklarDataSource;
  late String? seciliisletme;

  bool  _isLoading= true;
  TextEditingController _controller = TextEditingController();
  @override
  void initState() {
    super.initState();
    initialize();
    _controller.addListener(() {
      _alacaklarDataSource.search(_controller.text);
      log(_controller.text);
    });
  }
  Future<void> initialize() async {
    seciliisletme = await secilisalonid();
    alacaklargetir(seciliisletme!,'1','').then((data) {
      setState(() {


        _alacaklarDataSource = AlacaklarDataSource(rowsPerPage:10,salonid: seciliisletme!,context: context);
        _alacaklarDataSource.isLoadingNotifier.addListener(_onLoadingStateChanged);
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
    return  _isLoading
        ? Center(child: CircularProgressIndicator())
        :Scaffold(
      // floatingActionButton: AltYuvarlakYeniEkleMenu(isletme_bilgi: widget.isletmebilgi,),

      appBar: AppBar(
        title: Text('Alacaklar',style: TextStyle(color: Colors.black),),
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
      body:
      SingleChildScrollView(
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
            _alacaklarDataSource.rows.isEmpty
                ? Center(child: Text("Tabloda herhangi bir veri mevcut değil"))
                :Container(
                height: height - 275,

              child: _alacaklarDataSource != null
                  ? SfDataGrid(
                source: _alacaklarDataSource,
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
                  final tappedRow = _alacaklarDataSource
                      .rows[details.rowColumnIndex.rowIndex - 1];
                  /*ArsivDetayGosterDialog(context );
                     Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => KampanyaDetay(kampanyadetayi: tappedRow.getCells()[0].value,)),
                      );*/
                },
                columns:<GridColumn>[
                  GridColumn(
                    width: width * 0,
                    columnName: 'alacak',
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
                    columnName: 'musteridanisan',
                    label: Container(

                      padding: EdgeInsets.all(5.0),
                      alignment: Alignment.centerLeft,
                      child: Text('Müşteri'),
                    ),
                  ),

                  GridColumn(
                    width: width*0.2,
                    columnName: 'tutar',
                    label: Container(
                      padding: EdgeInsets.all(5.0),
                      alignment: Alignment.centerRight,
                      child: Text('Tutar ₺'),
                    ),
                  ),

                  GridColumn(
                    width: width*0.3,
                    columnName: 'odemetarih',
                    label: Container(
                      padding: EdgeInsets.all(5.0),
                      alignment: Alignment.centerLeft,
                      child: Text('Planlanan Ödeme Tarihi'),
                    ),
                  ),



                  GridColumn(
                    width: width*0.1,
                    columnName: 'islem',
                    label: Container(
                      padding: EdgeInsets.all(5.0),
                      alignment: Alignment.center,
                      child:Text("")
                    ),
                  ),
                ]
              ):Center(child: CircularProgressIndicator()),

            ),
            _buildPaginationControls()
          ],
        )
      ),


    );
  }

  Widget _buildPaginationControls() {

    final totalPages = (_alacaklarDataSource.totalPages).ceil();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: _alacaklarDataSource.currentPage > 1
              ? () {
            setState(  () {

              _alacaklarDataSource.setPage(_alacaklarDataSource.currentPage - 1);
            });
          }
              : null,
        ),
        Text('Sayfa ${_alacaklarDataSource.currentPage} / $totalPages'),
        IconButton(
          icon: Icon(Icons.arrow_forward),
          onPressed: _alacaklarDataSource.currentPage < totalPages
              ? () {
            setState(() {
              _alacaklarDataSource.setPage(_alacaklarDataSource.currentPage + 1);
            });
          }
              : null,
        ),
      ],
    );
  }

  void _showDetailsDialog(BuildContext context, Map<String, dynamic> item) {
    final _formKey = GlobalKey<FormState>();

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            insetPadding: EdgeInsets.zero,
            content: Container(

              height: 220,
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
                        Text('Anıl Orbey',style: TextStyle(fontWeight: FontWeight.bold),),
                        Divider(color: Colors.black,
                          height: 10,),
                        Row(
                          children: [
                            Text('Oluşturulma',style: TextStyle(fontSize: 15),),SizedBox(width: 10,),
                            Text(':'),
                            Text(' 21.09.2023',style: TextStyle(fontSize: 15),)
                          ],
                        ),
                        Row(
                          children: [
                            Text('Hizmet',style: TextStyle(fontSize: 15),),
                            SizedBox(width: 44,),
                            Text(': '),
                            Container(width: 180,child: SingleChildScrollView(scrollDirection: Axis.horizontal,child: Text('Bayram Paketi Deneme Ürünü 2222',style: TextStyle(fontSize: 15),)))
                          ],

                        ),
                        Row(
                          children: [
                            Text('Tutar',style: TextStyle(fontSize: 15),),SizedBox(width: 57,),
                            Text(':'),
                            Text(' 1000',style: TextStyle(fontSize: 15),)
                          ],

                        ),
                        Row(
                          children: [
                            Text('Ödeme Tarihi',style: TextStyle(fontSize: 15),),SizedBox(width: 3,),
                            Text(':'),
                            Text(' 20.10.2023',style: TextStyle(fontSize: 15),)
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

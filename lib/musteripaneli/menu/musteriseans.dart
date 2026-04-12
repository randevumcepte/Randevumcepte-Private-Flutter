import 'dart:async';
import 'dart:developer';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:randevu_sistem/Frontend/progressloading.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:randevu_sistem/Models/musteri_danisanlar.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';


import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Frontend/altyuvarlakmenu.dart';
import 'package:randevu_sistem/Models/form.dart';
import 'package:randevu_sistem/Frontend/sfdatatable.dart';

import '../../../../../Frontend/datetimeformatting.dart';
import '../../../../../Models/seanstakibi.dart';
import '../../../../../Models/urunler.dart';


class IslemlerveSeanslarMusteriPaneli extends StatefulWidget {
  final MusteriDanisan kullanici;
  final dynamic isletmebilgi;
  IslemlerveSeanslarMusteriPaneli({Key? key, required this.kullanici,required this.isletmebilgi}) : super(key: key);
  @override

  _IslemlerveSeanslarMusteriPaneliState createState() => _IslemlerveSeanslarMusteriPaneliState();
}

class _IslemlerveSeanslarMusteriPaneliState extends State<IslemlerveSeanslarMusteriPaneli> {
  MusteriDanisan? selectedmusteri;
  late List<MusteriDanisan> musteris;
  List<TextEditingController> urunadet = [];
  late SeansDataSource _seansDataGridSource;
  late List<bool> selectedRows;
  List<Urun> _urun = [];
  late List<Urun> _filteredUrun = [];
  late String? seciliisletme;
  bool  _isLoading= true;
  TextEditingController musteriController = TextEditingController();
  int totalPages = 1;
  bool anyChecked = false;
  bool selectAll = false;
  Timer? _debounce;
  bool firsttimetyping = true;
  String? lastQuery;
  TextEditingController _controller = TextEditingController();
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
        if (_controller.text != lastQuery && !firsttimetyping) {  // Check if the query is different
          setState(() {

            firsttimetyping=false;
            lastQuery = _controller.text; // Update the last search query
            _seansDataGridSource.search(_controller.text);
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
  Future<void> initialize() async
  {
    seciliisletme = await secilisalonid();
    musteris = await musterilistegetir(seciliisletme!);
    urunlerigetir(seciliisletme!,'1','').then((data) {
      setState(() {


        _seansDataGridSource = SeansDataSource(rowsPerPage:10,salonid: seciliisletme!,context: context, musteriid: widget.kullanici.id  ,musteriMi: true);
        _seansDataGridSource.isLoadingNotifier.addListener(_onLoadingStateChanged);
        _isLoading = false;

      });
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
          home: IslemlerveSeanslarMusteriPaneli(kullanici: widget.kullanici, isletmebilgi: widget.isletmebilgi,),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double height = MediaQuery.of(context).size.height;
    return   _isLoading
        ? Center(child: CircularProgressIndicator())
        : GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus(); // Hide the keyboard
      },
          child: Scaffold(

              resizeToAvoidBottomInset: false,

          appBar:AppBar(
            title:Text('Seanslarım',style: TextStyle(color: Colors.black),),
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
            toolbarHeight: 60,
            actions: [



            ],
            backgroundColor: Colors.white,




          ),
          body:SingleChildScrollView(
            child: Column(

              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(

                    controller: _controller,
                    keyboardType: TextInputType.text,

                    decoration: InputDecoration(
                      hintText: 'Paket Adı...',
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
                Container(
                  height: height-275,
                  // Adjust the height based on your requirements
                  child: SfDataGrid(
                    source: _seansDataGridSource,
                    shrinkWrapRows: true,
                    columnWidthMode: ColumnWidthMode.fill,
                    defaultColumnWidth: 120,




                    onSwipeStart: (details) {
                      if (details.swipeDirection == DataGridRowSwipeDirection.startToEnd) {
                        details.setSwipeMaxOffset(50);
                      } else if (details.swipeDirection == DataGridRowSwipeDirection.endToStart) {
                        details.setSwipeMaxOffset(50);
                      }
                      return true;
                    },



                    onCellTap: (DataGridCellTapDetails details) {

                      final tappedRow = _seansDataGridSource.rows[details.rowColumnIndex.rowIndex - 1];
                      seansdetaylari(context, tappedRow.getCells()[0].value);
                      /*ArsivDetayGosterDialog(context );
                   Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => KampanyaDetay(kampanyadetayi: tappedRow.getCells()[0].value,)),
                    );*/

                    },
                    columns: <GridColumn>[

                      GridColumn(

                        width: width*0,
                        columnName: 'paket',
                        label: Container(

                          padding: EdgeInsets.all(5.0),
                          alignment: Alignment.centerLeft,
                          child: Text('Müşteri/Danışan ve Paket'),
                        ),
                      ),

                      GridColumn(

                        width: width*0.30,
                        columnName: 'musteridanisanpaket',
                        label: Container(

                          padding: EdgeInsets.all(5.0),
                          alignment: Alignment.centerLeft,
                          child: Text('Paket Adı'),
                        ),
                      ),



                      GridColumn(

                        width: width*0,
                        columnName: 'beklenen',
                        label: Container(

                          padding: EdgeInsets.all(5.0),
                          alignment: Alignment.centerLeft,
                          child: Text('beklenen'),
                        ),
                      ),
                      GridColumn(

                        width: width*0,
                        columnName: 'gelinen',
                        label: Container(

                          padding: EdgeInsets.all(5.0),
                          alignment: Alignment.centerLeft,
                          child: Text('gelinen'),
                        ),
                      ),
                      GridColumn(

                        width: width*0,
                        columnName: 'gelinmeyen',
                        label: Container(

                          padding: EdgeInsets.all(5.0),
                          alignment: Alignment.centerLeft,
                          child: Text('gelinmeyen'),
                        ),
                      ),
                      GridColumn(
                        width: width*0.70,
                        columnName: 'seansdetay',
                        label: Container(
                          padding: EdgeInsets.all(5.0),
                          alignment: Alignment.center,
                          child: Text('Seans Detayları'),
                        ),
                      ),


                    ],
                  ),
                ),


                _buildPaginationControls()
              ],
            ),

          )


    ),
        );



  }


  Widget _buildPaginationControls() {

    final totalPages = (_seansDataGridSource.totalPages).ceil();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: _seansDataGridSource.currentPage > 1
              ? () {
            setState(() {

              _seansDataGridSource.setPage(_seansDataGridSource.currentPage - 1);
            });
          }
              : null,
        ),
        Text('Sayfa ${_seansDataGridSource.currentPage} / $totalPages'),
        IconButton(
          icon: Icon(Icons.arrow_forward),
          onPressed: _seansDataGridSource.currentPage < totalPages
              ? () {
            setState(() {
              _seansDataGridSource.setPage(_seansDataGridSource.currentPage + 1);
            });
          }
              : null,
        ),
      ],
    );
  }
  void seansdetaylari(BuildContext context, SeansTakip seanstakip)
  {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              contentPadding:EdgeInsets.all(5.0),
              title: Text(
                seanstakip.musteri["name"] +" "+ seanstakip.paket +" Seans Detayları",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Column(
                        children: List.generate(seanstakip.seanslar.length, (index) {
                          var item = seanstakip.seanslar[index];

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                item["seans_no"] == 1 ? Text(item["hizmet"]["hizmet_adi"]+ " Seansları",
                                  style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold
                                  ),
                                ) : Text(""),
                                SizedBox(height: 10),
                                Padding(
                                  padding: const EdgeInsets.only(left: 0.0),
                                  child: Text(item["seans_no"].toString()+ " Seans",
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold
                                    ),
                                  ),
                                ),
                                //1. satır
                                Container(
                                  color:Color(0xFFE2E2E2),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,

                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            SizedBox(height: 10),
                                            Padding(
                                              padding: const EdgeInsets.only(left: 0.0),
                                              child: Text("Tarih & Saat",
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.black,
                                                    fontWeight: FontWeight.bold
                                                ),
                                              ),
                                            ),

                                            SizedBox(height: 10),
                                            Padding(
                                              padding: const EdgeInsets.only(left: 0.0),
                                              child: Text(tarihsaatdonustur(item["seans_tarih"],item["seans_saat"])
                                                ,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ),

                                          ],
                                        ),
                                      ),

                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            SizedBox(height: 10),
                                            Padding(
                                              padding: const EdgeInsets.only(left: 0.0),
                                              child: Text("Personel",
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.black,
                                                    fontWeight: FontWeight.bold
                                                ),
                                              ),
                                            ),

                                            SizedBox(height: 10),
                                            Padding(
                                              padding: const EdgeInsets.only(left: 0.0),
                                              child: Text(item["personel"] != null ? item["personel"]["personel_adi"] : "Belirtilmemiş"
                                                ,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ),

                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            SizedBox(height: 10),
                                            Padding(
                                              padding: const EdgeInsets.only(left: 0.0),
                                              child: Text("Oda",
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.black, fontWeight: FontWeight.bold
                                                ),
                                              ),
                                            ),

                                            SizedBox(height: 10),
                                            Padding(
                                              padding: const EdgeInsets.only(left: 0.0),
                                              child: Text(item["oda"] != null ? item["oda"]["oda_adi"] : "Belirtilmemiş"
                                                ,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ),

                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  color:Color(0xFFE2E2E2),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,

                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            SizedBox(height: 10),
                                            Padding(
                                              padding: const EdgeInsets.only(left: 0.0),
                                              child: Text("Cihaz",
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.black, fontWeight: FontWeight.bold
                                                ),
                                              ),
                                            ),

                                            SizedBox(height: 10),
                                            Padding(
                                              padding: const EdgeInsets.only(left: 0.0),
                                              child: Text(item["cihaz"] != null ? item["cihaz"]["cihaz_adi"] : "Belirtilmemiş",
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ),

                                          ],
                                        ),
                                      ),

                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            SizedBox(height: 20),



                                            Padding(
                                              padding: const EdgeInsets.only(left: 0.0),
                                              child: item["geldi"] == null ?
                                              ElevatedButton(
                                                onPressed: () {},
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.yellow,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
                                                  minimumSize: Size(70, 20),
                                                ),
                                                child: Text("Beklemede",
                                                  style: TextStyle(color: Colors.black,fontSize: 10),
                                                ),
                                              )
                                                  : item["geldi"]== 0 ?
                                              ElevatedButton(
                                                onPressed: () {},
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red[600],
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
                                                  minimumSize: Size(70, 20),
                                                ),
                                                child: Text("Gelmedi",
                                                  style: TextStyle(color: Colors.white,fontSize: 10),
                                                ),
                                              )
                                                  :
                                              ElevatedButton(
                                                onPressed: () {},
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.green,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
                                                  minimumSize: Size(70, 20),
                                                ),
                                                child: Text("Geldi",
                                                  style: TextStyle(color: Colors.black,fontSize: 10),
                                                ),
                                              ),
                                            ),

                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            SizedBox(height: 10),
                                            ElevatedButton(
                                                onPressed: () {},
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.green,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
                                                  minimumSize: Size(40, 40),
                                                ),
                                                child: Icon(Icons.calendar_today_rounded,color: Colors.white,)
                                            ),

                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                //2. satır


                              ],
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text("KAPAT"),
                ),

              ],
            );
          },
        );
      },
    );
  }






}

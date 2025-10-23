import 'dart:async';
import 'dart:developer';


import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:randevu_sistem/Frontend/progressloading.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:randevu_sistem/Models/masrafkategorileri.dart';
import 'package:randevu_sistem/Models/musteri_danisanlar.dart';
import 'package:randevu_sistem/Models/personel.dart';
import 'package:randevu_sistem/yonetici/diger/menu/senetler/kapal%C4%B1senetler.dart';
import 'package:randevu_sistem/yonetici/diger/menu/senetler/senetvadeleri.dart';
import 'package:randevu_sistem/yonetici/diger/menu/senetler/yazdir.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import '../../../../Frontend/popupdialogs.dart';
import '../../../../Models/randevular.dart';
import '../../../../Models/senetler.dart';
import '../../../../Models/sms_taslaklari.dart';
import '../../../../Models/urunler.dart';
import '../../../../yeni/urun_ekle.dart';
import '../../../adisyonlar/adisyonpage.dart';
import '../../../adisyonlar/musteri_detay.dart';
import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Frontend/altyuvarlakmenu.dart';
import 'package:randevu_sistem/Models/form.dart';
import 'package:randevu_sistem/Frontend/sfdatatable.dart';

import '../ayarlar/urunler/urunduzenle.dart';
import 'masrafekle.dart';


class Masraflar extends StatefulWidget {
    final String tarih;
    final String odeme_yontemi;
    final dynamic isletmebilgi;
    Masraflar({Key? key, required this.tarih, required this.odeme_yontemi, required this.isletmebilgi }) : super(key: key);
    @override

    _KasaState createState() => _KasaState();
}

class _KasaState extends State<Masraflar> {
    TextEditingController _controller = TextEditingController();
    late GiderDataSource _giderDataGridSource;
    late List<bool> selectedRows;

    late String? seciliisletme;
    bool  _isLoading= true;
    TextEditingController musteriController = TextEditingController();
    int totalPages = 1;
    bool anyChecked = false;
    bool selectAll = false;
    List<Personel> harcayan = [];
    List<MasrafKategorisi> masrafturu = [];
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
                        _giderDataGridSource.search(_controller.text);
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
        List<Personel> personeller = await personellistegetir(seciliisletme!);
        List<MasrafKategorisi> masrafkategorisi = await masrafkategorileri();
        setState(() {

            harcayan = personeller;
            masrafturu = masrafkategorisi;
            _giderDataGridSource = GiderDataSource(isletmebilgi: widget.isletmebilgi, rowsPerPage:10,salonid: seciliisletme!,context: context,odemeyontemi: widget.odeme_yontemi,tarih: widget.tarih,harcayan: '', personelliste: personeller,masrafkategoriliste: masrafkategorisi );
            _giderDataGridSource.isLoadingNotifier.addListener(_onLoadingStateChanged);
            _isLoading = false;

        });

    }

    void _onLoadingStateChanged() {
        setState(() {
            // This empty setState function just triggers a rebuild of the widget when the loading state changes
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
                // Unfocus the current text field, dismissing the keyboard
                FocusScope.of(context).unfocus();
            },
              child: Scaffold(
                  resizeToAvoidBottomInset: false,
              appBar: AppBar(
                  title: Text('Masraflar',style: TextStyle(color: Colors.black,fontSize: 18),),
                  leading: IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () => Navigator.of(context).pop(),
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
                      IconButton(onPressed: (){
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => MasrafEkle(personeller: harcayan,masrafkategorileri: masrafturu,seciliisletme: seciliisletme!,giderDataSource: _giderDataGridSource,isletmebilgi: widget.isletmebilgi,)),
                          );
                      }, icon:  Icon(Icons.add,color:Colors.black,),iconSize: 26,),


                  ],
                  toolbarHeight: 60,

                  backgroundColor: Colors.white,




              ),


              body:LayoutBuilder(
                builder: (context, constraints) {
                    return Column(

                        children: [
                            Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: TextFormField(

                                    controller: _controller,
                                    keyboardType: TextInputType.text,

                                    decoration: InputDecoration(
                                        hintText: 'Harcayan...',
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

                                // Adjust the height based on your requirements
                                child: SfDataGrid(
                                    source: _giderDataGridSource,
                                    shrinkWrapRows: true,
                                    columnWidthMode: ColumnWidthMode.fill,
                                    defaultColumnWidth: 120,

                                    onCellTap: (DataGridCellTapDetails details) {

                                        final tappedRow = _giderDataGridSource.rows[details.rowColumnIndex.rowIndex - 1];
                                        _giderDataGridSource.showDetailsDialog(context,  tappedRow.getCells()[0].value);
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
                                            columnName: 'gelirpar',
                                            label: Container(

                                                padding: EdgeInsets.all(5.0),
                                                alignment: Alignment.centerLeft,
                                                child: Text('gelirpar'),
                                            ),
                                        ),
                                        GridColumn(

                                            width: width*0,
                                            columnName: 'tutar',
                                            label: Container(

                                                padding: EdgeInsets.all(5.0),
                                                alignment: Alignment.centerLeft,
                                                child: Text('tutar'),
                                            ),
                                        ),

                                        GridColumn(

                                            width: width*0.35,
                                            columnName: 'harcayan',
                                            label: Container(

                                                padding: EdgeInsets.all(5.0),
                                                alignment: Alignment.centerLeft,
                                                child: Text('Harcayan'),
                                            ),
                                        ),

                                        GridColumn(
                                            width: width*0.30,
                                            columnName: 'tarih',
                                            label: Container(
                                                padding: EdgeInsets.all(5.0),
                                                alignment: Alignment.centerLeft,
                                                child: Text('Tarih'),
                                            ),
                                        ),

                                        GridColumn(
                                            width: width*0.30,
                                            columnName: 'tutartext',
                                            label: Container(
                                                padding: EdgeInsets.all(5.0),
                                                alignment: Alignment.centerRight,
                                                child: Text('Tutar ₺'),
                                            ),
                                        ),


                                    ],
                                ),
                            ),


                            _buildPaginationControls()
                        ],
                    );
                }


              )


        ),
            );



    }


    Widget _buildPaginationControls() {

        final totalPages = (_giderDataGridSource.totalPages).ceil();

        return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
                IconButton(
                    icon: Icon(Icons.arrow_back),
                    onPressed: _giderDataGridSource.currentPage > 1
                        ? () {
                        setState(() {

                            _giderDataGridSource.setPage(_giderDataGridSource.currentPage - 1);
                        });
                    }
                        : null,
                ),
                Text('Sayfa ${_giderDataGridSource.currentPage} / $totalPages'),
                IconButton(
                    icon: Icon(Icons.arrow_forward),
                    onPressed: _giderDataGridSource.currentPage < totalPages
                        ? () {
                        setState(() {
                            _giderDataGridSource.setPage(_giderDataGridSource.currentPage + 1);
                        });
                    }
                        : null,
                ),
            ],
        );
    }





}

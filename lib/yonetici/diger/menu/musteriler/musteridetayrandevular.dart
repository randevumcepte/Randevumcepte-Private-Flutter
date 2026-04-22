import 'dart:developer';


import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';


import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Frontend/altyuvarlakmenu.dart';
import 'package:randevu_sistem/Models/form.dart';
import 'package:randevu_sistem/Frontend/sfdatatable.dart';
import 'dart:async';

import '../../../../../Models/musteri_danisanlar.dart';
import '../../../../../Models/randevular.dart';


class MusteriRandevulariMenu extends StatefulWidget {
  final dynamic isletmebilgi;
  final MusteriDanisan md;
  final int kullanicirolu;
  const MusteriRandevulariMenu({Key? key,required this.isletmebilgi, required this.md,required this.kullanicirolu}) : super(key: key);
  @override
  _MusteriRandevulariMenuState createState() => _MusteriRandevulariMenuState();
}

class _MusteriRandevulariMenuState extends State<MusteriRandevulariMenu> {
  Timer? _debounce;
  bool _isFetching = false;
  late RandevuDataSource _randevuDataGridSource;
  List<Randevu> _randevu = [];
  late List<Randevu> _filteredRandevu = [];
  late String? seciliisletme;
  bool  _isLoading= true;
  final List<String> randevuolusturma = [
    'Tümü',
    'Salon',
    'Web',
    'Uygulama',
  ];
  final List<String> randevudurum= [
    'Tümü',
    'Onay bekleyen',
    'Onaylı',
    'Reddedilen/İptal Edilen',
    'Müşteri tarafından iptal edilen',


  ];
  final List<String> randevutarih= [

    'Tümü',
    'Bugün',
    'Yarın',
    'Bu ay',
    'Önümüzdeki ay',
    'Bu yıl',
    'Önümüzdeki yıl',


  ];
  int totalPages = 1;
  String? selectedrandevuolusturma = 'Tümü';
  TextEditingController randevuolusturmacontroller = TextEditingController();
  String? lastQuery;
  String? selectedrandevudurum = 'Tümü';
  TextEditingController randevudurumcontroller = TextEditingController();

  String? selectedrandevutarih = 'Bu yıl';
  TextEditingController randevutarihcontroller = TextEditingController();
  bool firsttimetyping = true;
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
            _randevuDataGridSource.search(
                _controller.text,
                selectedrandevudurum!,
                selectedrandevuolusturma!,
                selectedrandevutarih!
            );
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
  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }
  Future<void> initialize() async
  {
    seciliisletme = await secilisalonid();

    setState(() {


      _randevuDataGridSource = RandevuDataSource(kullanicirolu: widget.kullanicirolu, isletmebilgi:widget.isletmebilgi,rowsPerPage:10,durum: selectedrandevudurum!, olusturma: selectedrandevuolusturma!,salonid: seciliisletme!,tarih:selectedrandevutarih!,context: context, musteriid: widget.md.id,personelid: "",cihazid: "",musteriMi: false);
      _randevuDataGridSource.isLoadingNotifier.addListener(_onLoadingStateChanged);
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
    final bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    return   _isLoading
        ? Center(child: CircularProgressIndicator())
        : GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus(); // Hide the keyboard
      },
      child: Scaffold(
        resizeToAvoidBottomInset:false,
        appBar: AppBar(
          title: Text('Randevular',style: TextStyle(color: Colors.black,fontSize: 18),),
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
              showModalBottomSheet(
                  context: context,
                  builder: (context) {
                    return StatefulBuilder(
                        builder: (context, setStateSB){
                          return Column(

                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              SizedBox(height: 20,),
                              Container(
                                padding: const EdgeInsets.only(left: 20.0),
                                child: Text('Randevu Oluşturma Yeri',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                              ),
                              SizedBox(height: 10,),
                              Container(

                                alignment: Alignment.center,
                                margin: EdgeInsets.only(left:20,right: 20),
                                height: 40,
                                width:double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: Color(0xFF6A1B9A)),
                                  borderRadius: BorderRadius.circular(10), //border corner radius

                                  //you can set more BoxShadow() here

                                ),
                                child: DropdownButtonHideUnderline(

                                    child: DropdownButton2<String>(

                                      isExpanded: true,
                                      hint: Text(
                                        'Seçiniz..',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Theme.of(context).hintColor,
                                        ),
                                      ),
                                      items: randevuolusturma
                                          .map((item) => DropdownMenuItem(
                                        value: item,
                                        child: Text(
                                          item,
                                          style: const TextStyle(
                                            fontSize: 14,
                                          ),
                                        ),
                                      ))
                                          .toList(),
                                      value: selectedrandevuolusturma,

                                      onChanged: (value) {
                                        setStateSB(() {
                                          selectedrandevuolusturma = value;
                                          randevuolusturmacontroller.text = value!;
                                        });
                                      },
                                      buttonStyleData: const ButtonStyleData(
                                        padding: EdgeInsets.symmetric(horizontal: 16),
                                        height: 50,
                                        width: 400,
                                      ),

                                      dropdownStyleData: const DropdownStyleData(
                                        maxHeight: 200,
                                      ),
                                      menuItemStyleData: const MenuItemStyleData(
                                        height: 40,
                                      ),

                                      //This to clear the search value when you close the menu
                                      onMenuStateChange: (isOpen) {
                                        if (!isOpen) {
                                          randevuolusturmacontroller.clear();
                                        }
                                      },

                                    )),
                              ),
                              SizedBox(height: 20,),
                              Container(
                                padding: const EdgeInsets.only(left: 20.0),
                                child: Text('Randevu Durumu',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                              ),
                              SizedBox(height: 10,),
                              Container(

                                alignment: Alignment.center,
                                margin: EdgeInsets.only(left:20,right: 20),
                                height: 40,
                                width:double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: Color(0xFF6A1B9A)),
                                  borderRadius: BorderRadius.circular(10), //border corner radius

                                  //you can set more BoxShadow() here

                                ),
                                child: DropdownButtonHideUnderline(

                                    child: DropdownButton2<String>(

                                      isExpanded: true,
                                      hint: Text(
                                        'Seçiniz..',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Theme.of(context).hintColor,
                                        ),
                                      ),
                                      items: randevudurum
                                          .map((item) => DropdownMenuItem(
                                        value: item,
                                        child: Text(
                                          item,
                                          style: const TextStyle(
                                            fontSize: 14,
                                          ),
                                        ),
                                      ))
                                          .toList(),
                                      value: selectedrandevudurum,

                                      onChanged: (value) {
                                        setStateSB(() {
                                          selectedrandevudurum = value;
                                          randevudurumcontroller.text = value!;
                                        });
                                      },
                                      buttonStyleData: const ButtonStyleData(
                                        padding: EdgeInsets.symmetric(horizontal: 16),
                                        height: 50,
                                        width: 400,
                                      ),

                                      dropdownStyleData: const DropdownStyleData(
                                        maxHeight: 200,
                                      ),
                                      menuItemStyleData: const MenuItemStyleData(
                                        height: 40,
                                      ),

                                      //This to clear the search value when you close the menu
                                      onMenuStateChange: (isOpen) {
                                        if (!isOpen) {
                                          randevudurumcontroller.clear();
                                        }
                                      },

                                    )),
                              ),
                              SizedBox(height: 20,),
                              Container(
                                padding: const EdgeInsets.only(left: 20.0),
                                child: Text('Tarih',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                              ),
                              SizedBox(height: 10,),
                              Container(

                                alignment: Alignment.center,
                                margin: EdgeInsets.only(left:20,right: 20),
                                height: 40,
                                width:double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: Color(0xFF6A1B9A)),
                                  borderRadius: BorderRadius.circular(10), //border corner radius

                                  //you can set more BoxShadow() here

                                ),
                                child: DropdownButtonHideUnderline(

                                    child: DropdownButton2<String>(

                                      isExpanded: true,
                                      hint: Text(
                                        'Seçiniz..',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Theme.of(context).hintColor,
                                        ),
                                      ),
                                      items: randevutarih
                                          .map((item) => DropdownMenuItem(
                                        value: item,
                                        child: Text(
                                          item,
                                          style: const TextStyle(
                                            fontSize: 14,
                                          ),
                                        ),
                                      ))
                                          .toList(),
                                      value: selectedrandevutarih,

                                      onChanged: (value) {
                                        setStateSB(() {
                                          selectedrandevutarih = value;
                                          randevutarihcontroller.text = value!;
                                        });
                                      },
                                      buttonStyleData: const ButtonStyleData(
                                        padding: EdgeInsets.symmetric(horizontal: 16),
                                        height: 50,
                                        width: 400,
                                      ),

                                      dropdownStyleData: const DropdownStyleData(
                                        maxHeight: 200,
                                      ),
                                      menuItemStyleData: const MenuItemStyleData(
                                        height: 40,
                                      ),

                                      //This to clear the search value when you close the menu
                                      onMenuStateChange: (isOpen) {
                                        if (!isOpen) {
                                          randevutarihcontroller.clear();
                                        }
                                      },

                                    )),
                              ),
                              SizedBox(height: 30,),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton(onPressed: (){
                                    Navigator.of(context).pop();
                                    log("durum "+selectedrandevudurum!);
                                    _randevuDataGridSource.search(_controller.text,selectedrandevudurum!,selectedrandevuolusturma!,selectedrandevutarih!);
                                  }, child: Text('Sonuçları Göster'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.purple[800],
                                      foregroundColor: Colors.white,

                                    ),

                                  ),
                                ],
                              ),
                              SizedBox(height: 50,),
                            ],
                          );
                        }
                    );
                  }
              );
            }, icon:  Icon(Icons.filter_list_outlined,color:Colors.black,),iconSize: 26,),


          ],
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
                      hintText: 'Müşteri Adı...',
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
                    source: _randevuDataGridSource,
                    shrinkWrapRows: true,
                    columnWidthMode: ColumnWidthMode.fill,
                    defaultColumnWidth: 120,
                    allowSwiping: true,



                    onSwipeStart: (details) {
                      if (details.swipeDirection == DataGridRowSwipeDirection.startToEnd) {
                        details.setSwipeMaxOffset(0);
                      } else if (details.swipeDirection == DataGridRowSwipeDirection.endToStart) {
                        details.setSwipeMaxOffset(0);
                      }
                      return true;
                    },

                    startSwipeActionsBuilder:
                        (BuildContext context, DataGridRow row, int rowIndex) {
                      return GestureDetector(
                          onTap: () {
                            //Navigator.of(context).pop();
                            //Navigator.push(context, new MaterialPageRoute(builder: (context) => new KampanyaDuzenle(kampanyadetayi: row.getCells()[0].value as Kampanya,)));
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
                            /*final confirmed = await showKampanyaDeleteConfirmationDialog(context,int.parse(row.getCells()[1].value), () {
                          // Perform deletion

                          setState(() {
                            kampanyasil(context,int.parse(row.getCells()[1].value));
                            Navigator.of(context).pop();
                            Navigator.push(context, new MaterialPageRoute(builder: (context) => new TumArsiv()));


                          });
                        });*/

                          },
                          child: Container(
                              color: Colors.red,
                              child: Center(
                                child: Icon(Icons.delete,color: Colors.white,),
                              )));
                    },
                    onCellTap: (DataGridCellTapDetails details) {

                      final tappedRow = _randevuDataGridSource.rows[details.rowColumnIndex.rowIndex - 1];
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
                        columnName: 'randevu',
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

                        width: width*0.3,
                        columnName: 'tarih',
                        label: Container(

                          padding: EdgeInsets.all(5.0),
                          alignment: Alignment.centerLeft,
                          child: Text('Tarih'),
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
                        width: width*0,
                        columnName: 'durum',
                        label: Container(
                          padding: EdgeInsets.all(5.0),
                          alignment: Alignment.centerLeft,
                          child: Text('Durum'),
                        ),
                      ),


                      GridColumn(
                        width: width*0,
                        columnName: 'geldi',
                        label: Container(
                          padding: EdgeInsets.all(5.0),
                          alignment: Alignment.centerLeft,
                          child: Text('Durum'),
                        ),
                      ),
                      GridColumn(
                        width: width*0.3,
                        columnName: 'durum_text',
                        label: Container(
                          padding: EdgeInsets.all(5.0),
                          alignment: Alignment.centerLeft,
                          child: Text('Durum'),
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
                  ),
                ),
                if (!isKeyboardVisible) _buildPaginationControls()
              ],
            );
          },
        ),


      ),
    );



  }


  Widget _buildPaginationControls() {

    final totalPages = (_randevuDataGridSource.totalPages).ceil();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: _randevuDataGridSource.currentPage > 1
              ? () {
            setState(() {

              _randevuDataGridSource.setPage(_randevuDataGridSource.currentPage - 1,selectedrandevudurum!,selectedrandevuolusturma!,selectedrandevutarih!);
            });
          }
              : null,
        ),
        Text('Sayfa ${_randevuDataGridSource.currentPage} / $totalPages'),
        IconButton(
          icon: Icon(Icons.arrow_forward),
          onPressed: _randevuDataGridSource.currentPage < totalPages
              ? () {
            setState(() {
              _randevuDataGridSource.setPage(_randevuDataGridSource.currentPage + 1,selectedrandevudurum!,selectedrandevuolusturma!,selectedrandevutarih!);
            });
          }
              : null,
        ),
      ],
    );
  }
}

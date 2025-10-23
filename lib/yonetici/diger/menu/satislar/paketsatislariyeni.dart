import 'dart:async';
import 'dart:developer';


import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:randevu_sistem/Frontend/progressloading.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:randevu_sistem/Models/adisyonlar.dart';
import 'package:randevu_sistem/Models/musteri_danisanlar.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import '../../../../Frontend/popupdialogs.dart';
import '../../../../Models/adisyonpaketler.dart';
import '../../../../Models/paketler.dart';
import '../../../../Models/personel.dart';
import '../../../../Models/randevular.dart';

import '../../../../Models/urunler.dart';
import '../../../../Models/user.dart';
import '../../../../yeni/urun_ekle.dart';
import '../../../adisyonlar/adisyonpage.dart';
import '../../../adisyonlar/musteri_detay.dart';
import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Frontend/altyuvarlakmenu.dart';
import 'package:randevu_sistem/Models/form.dart';
import 'package:randevu_sistem/Frontend/sfdatatable.dart';

import '../ayarlar/paketler/paketduzenle.dart';
import '../ayarlar/paketler/paketekle.dart';
import '../ayarlar/urunler/urunduzenle.dart';

import 'package:randevu_sistem/yonetici/adisyonlar/satislar/tahsilat.dart';
class PaketSatislari extends StatefulWidget {
  final Kullanici kullanici;
  final dynamic isletmebilgi;
  PaketSatislari ({Key? key, required this.kullanici,required this.isletmebilgi}) : super(key: key);
  @override
  _PaketSatislariState createState() => _PaketSatislariState();
}

class _PaketSatislariState extends State<PaketSatislari> {
  MusteriDanisan? selectedmusteri;
  late List<MusteriDanisan> musteris;
  List<TextEditingController> paketbaslangictarihi = [];
  List<TextEditingController> paketbaslangicsaati = [];
  List<TextEditingController> paketseansaraligi = [];
  List<TextEditingController> psatici = [];
  List<TimeOfDay> _selectedTime = [];
  //List<Personel>selectedpaketsatici = [];
  Personel? selectedpaketsatici;
  late List<Personel>paketsatici;
  late PaketDataSource _paketDataGridSource;
  late List<bool> selectedRows;
  late String? seciliisletme;
  bool  _isLoading= true;
  TextEditingController musteriController = TextEditingController();
  TextEditingController saticiController = TextEditingController();
  int totalPages = 1;
  bool anyChecked = false;
  bool selectAll = false;
  late dynamic isletme_bilgi;
  Timer? _debounce;
  bool firsttimetyping=true;
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
            _paketDataGridSource.search(_controller.text);
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
  void onCheckboxChanged(int rowIndex, bool isChecked) {

    setState(() {
      _paketDataGridSource.anyChecked.value = isChecked;
    });
  }
  Future<void> initialize() async
  {
    seciliisletme = await secilisalonid();
    musteris = await musterilistegetir(seciliisletme!);

    List <Personel> personelliste = await personellistegetir(seciliisletme!);
    widget.kullanici.yetkili_olunan_isletmeler.forEach((element) {
      log(element['salon_id'].toString());
      if(element['salon_id'].toString()==seciliisletme.toString())
      {

        isletme_bilgi = element;

      }

    });
    urunlerigetir(seciliisletme!,'1','').then((data) {
      setState(() {

        paketsatici = personelliste;
        _paketDataGridSource = PaketDataSource(rowsPerPage:10,salonid: seciliisletme!,context: context,checkBoxChecked: onCheckboxChanged);
        _paketDataGridSource.isLoadingNotifier.addListener(_onLoadingStateChanged);
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
          home: PaketSatislari(kullanici: widget.kullanici,isletmebilgi: widget.isletmebilgi,),
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
          floatingActionButton: _paketDataGridSource.anyChecked.value  ? Stack(
            fit: StackFit.expand,
            children: [

              Positioned(
                bottom: 15,
                left: 30,

                child: ElevatedButton(

                  onPressed: () {
                    _showPopup(context);
                  },
                  style: ElevatedButton.styleFrom(padding: EdgeInsets.all(15), backgroundColor: Colors.purple[800],  foregroundColor: Colors.white, shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(55)))),
                  child: Text('Satış\n Yap',style: TextStyle(fontSize: 12),),
                ),
              ),
            ],
          ) : null,


          appBar: AppBar(
            title: Text('Paketler',style: TextStyle(color: Colors.black,fontSize: 18),),
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => PaketEkle(kullanici: widget.kullanici, isletmebilgi: widget.isletmebilgi, )),
                );
              }, icon:  Icon(Icons.add,color:Colors.black,),iconSize: 26,),


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
                          hintText: 'Paket Adı...',
                          enabled: true,
                          focusColor: Color(0xFF6A1B9A),
                          hoverColor: Color(0xFF6A1B9A),
                          hintStyle: TextStyle(color: Color(0xFF6A1B9A)),
                          contentPadding: EdgeInsets.all(5.0),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Color(0xFF6A1B9A)),
                            borderRadius: BorderRadius.circular(10.0),),
                          border:
                          OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF6A1B9A),),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                      ),

                    ),
                    Expanded(

                      // Adjust the height based on your requirements
                      child: SfDataGrid(
                        source: _paketDataGridSource,
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
                            (BuildContext context, DataGridRow row,
                            int rowIndex) {
                          return GestureDetector(
                              onTap: () {
                                //Navigator.of(context).pop();
                                //Navigator.push(context, new MaterialPageRoute(builder: (context) => new KampanyaDuzenle(kampanyadetayi: row.getCells()[0].value as Kampanya,)));
                                /*Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => UrunDuzenle(urundetayi: row.getCells()[0].value as Urun,salonid: seciliisletme!,urunDataSource: _urunDataGridSource,)),
                            );*/

                              },
                              child: Container(
                                  color: Colors.purple,
                                  child: Center(
                                    child: Icon(
                                        Icons.edit, color: Colors.white),
                                  )));
                        },
                        endSwipeActionsBuilder:
                            (BuildContext context, DataGridRow row,
                            int rowIndex) {
                          return GestureDetector(
                              onTap: () async {
                                final confirmed = await _paketDataGridSource
                                    .showDeleteConfirmationDialog(context,
                                    int.parse(row.getCells()[1].value), () {
                                      // Perform deletion

                                      setState(() {
                                        showProgressLoading(context);
                                        _paketDataGridSource.sil(context,
                                            int.parse(row.getCells()[1].value));
                                      });
                                    });
                              },
                              child: Container(
                                  color: Colors.red,
                                  child: Center(
                                    child: Icon(
                                      Icons.delete, color: Colors.white,),
                                  )));
                        },
                        onCellTap: (DataGridCellTapDetails details) {
                          final tappedRow = _paketDataGridSource.rows[details
                              .rowColumnIndex.rowIndex - 1];
                          _showDetailsDialog(context, tappedRow.getCells()[0]
                              .value);
                          /*ArsivDetayGosterDialog(context );
                   Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => KampanyaDetay(kampanyadetayi: tappedRow.getCells()[0].value,)),
                    );*/

                        },
                        columns: <GridColumn>[
                          GridColumn(

                            width: width * 0.1,
                            columnName: 'checkbox',
                            label: Container(

                                padding: EdgeInsets.all(5.0),
                                alignment: Alignment.centerLeft,
                                child: Checkbox(
                                  value: _paketDataGridSource.selectAll.value,
                                  onChanged: (value) {
                                    setState(() {
                                      _paketDataGridSource.hepsiniSec(value!);
                                    });
                                  },
                                  activeColor: Colors.purple[800],
                                )
                            ),
                          ),
                          GridColumn(

                            width: width * 0,
                            columnName: 'paket',
                            label: Container(

                              padding: EdgeInsets.all(5.0),
                              alignment: Alignment.centerLeft,
                              child: Text('Paketpar'),
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

                            width: width * 0.30,
                            columnName: 'paketadi',
                            label: Container(

                              padding: EdgeInsets.all(5.0),
                              alignment: Alignment.centerLeft,
                              child: Text('Paket Adı'),
                            ),
                          ),

                          GridColumn(
                            width: width * 0.25,
                            columnName: 'hizmetler',
                            label: Container(
                              padding: EdgeInsets.all(5.0),
                              alignment: Alignment.centerLeft,
                              child: Text('Hizmet(-ler)'),
                            ),
                          ),


                          GridColumn(
                            width: width * 0.25,
                            columnName: 'fiyat',
                            label: Container(
                              padding: EdgeInsets.all(5.0),
                              alignment: Alignment.centerRight,
                              child: Text('Fiyat ₺'),
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


                    _buildPaginationControls()
                  ],
                );
              }

          )


    ),
        );



  }


  Widget _buildPaginationControls() {

    final totalPages = (_paketDataGridSource.totalPages).ceil();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: _paketDataGridSource.currentPage > 1
              ? () {
            setState(() {

              _paketDataGridSource.setPage(_paketDataGridSource.currentPage - 1);
            });
          }
              : null,
        ),
        Text('Sayfa ${_paketDataGridSource.currentPage} / $totalPages'),
        IconButton(
          icon: Icon(Icons.arrow_forward),
          onPressed: _paketDataGridSource.currentPage < totalPages
              ? () {
            setState(() {
              _paketDataGridSource.setPage(_paketDataGridSource.currentPage + 1);
            });
          }
              : null,
        ),
      ],
    );
  }
  void _showDetailsDialog(BuildContext context, Paket paket) {
    final _formKey = GlobalKey<FormState>();

    String hizmetadi='';
    String seans='';
    double fiyat=0;
    paket.hizmetler.forEach((element) {
      hizmetadi+=element['hizmet']['hizmet_adi']+' ';
      seans+=element['seans']+' ';
      fiyat+=double.parse(element['fiyat']);
    });


    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          insetPadding: EdgeInsets.zero,
          content: Container(

            height: 180,
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
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: <Widget>[

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(paket.paket_adi,style: TextStyle(fontWeight: FontWeight.bold),),
                        ],
                      ),
                      Divider(color: Colors.black,
                        height: 10,),
                      Row(
                        children: [
                          Text('Hizmetler'), SizedBox(width: 2,),
                          Text(': '),
                          Expanded(child: Text(hizmetadi))
                        ],
                      ),
                      Row(
                        children: [
                          Text('Fiyat'), SizedBox(width: 35,),
                          Text(': '),
                          Text(fiyat.toString())
                        ],
                      ),
                      Row(
                        children: [
                          Text('Seans'), SizedBox(width: 26,),
                          Text(': '),
                          Text(seans)
                        ],
                      ),

                      SizedBox(height: 10,),
                      Divider(color: Colors.black,),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => PaketDuzenle( paket: paket,isletmebilgi: widget.isletmebilgi,)),
                            );
                          }, child:
                          Text('Düzenle'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple[800],
                                foregroundColor: Colors.white,
                                elevation: 5,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5.0)
                                ),
                                minimumSize: Size(130, 30)
                            ),
                          ),

                        ],
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
  void _showPopup(BuildContext context ) {
    // Variables to store the selected values from the dropdowns
    List<Paket> selectedData = [];
    for (int i = 0; i < _paketDataGridSource.selectedRows.value.length; i++) {
      log("Seçili : "+_paketDataGridSource.selectedRows.value[i].toString());
      if (_paketDataGridSource.selectedRows.value[i]) {
        selectedData.add(_paketDataGridSource.paket[i]);
        paketbaslangictarihi = List.generate(_paketDataGridSource.selectedRows.value.length, (index) => TextEditingController());
        paketbaslangicsaati = List.generate(_paketDataGridSource.selectedRows.value.length, (index) => TextEditingController());
        paketseansaraligi = List.generate(_paketDataGridSource.selectedRows.value.length, (index) => TextEditingController());
        psatici = List.generate(_paketDataGridSource.selectedRows.value.length, (index) => TextEditingController());
        //selectedpaketsatici = List.generate(_paketDataGridSource.selectedRows.value.length, (index) => paketsatici[0]);
        _selectedTime = List.generate(_paketDataGridSource.selectedRows.value.length, (index) => TimeOfDay.now());
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text(
                "Satış Yap",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 0.0),
                        child: Text(
                          'Müşteri & Danışan',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      Container(
                        height: 40,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Color(0xFF6A1B9A)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton2<MusteriDanisan>(
                            isExpanded: true,
                            hint: Text(
                              'Seç',
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).hintColor,
                              ),
                            ),
                            items: musteris.map((item) => DropdownMenuItem(
                              value: item,
                              child: Text(
                                item.name,
                                style: const TextStyle(fontSize: 14),
                              ),
                            )).toList(),
                            value: selectedmusteri,
                            onChanged: (value) {
                              setState(() {
                                selectedmusteri = value;
                              });
                            },
                            buttonStyleData: const ButtonStyleData(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              height: 50,
                              width: 100,
                            ),
                            dropdownStyleData: const DropdownStyleData(
                              maxHeight: 200,
                            ),
                            menuItemStyleData: const MenuItemStyleData(
                              height: 40,
                            ),
                            dropdownSearchData: DropdownSearchData(
                              searchController: musteriController,
                              searchInnerWidgetHeight: 50,
                              searchInnerWidget: Container(
                                height: 50,
                                padding: const EdgeInsets.all(8),
                                child: TextFormField(
                                  expands: true,
                                  maxLines: null,
                                  controller: musteriController,
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    hintText: 'Ara..',
                                    hintStyle: const TextStyle(fontSize: 12),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                  ),
                                ),
                              ),
                              searchMatchFn: (item, searchValue) {
                                final musteriAdi = item.value?.name?.toLowerCase();
                                return musteriAdi != null && musteriAdi.contains(searchValue.toLowerCase());
                              },
                            ),
                            onMenuStateChange: (isOpen) {
                              if (!isOpen) {
                                musteriController.clear();
                              }
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: 10,),
                      Padding(
                        padding: const EdgeInsets.only(right: 0.0),
                        child: Text(
                          'Satıcı Personel',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      Container(
                        height: 40,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Color(0xFF6A1B9A)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton2<Personel>(
                            isExpanded: true,
                            hint: Text(
                              'Seç',
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).hintColor,
                              ),
                            ),
                            items: paketsatici.map((item) => DropdownMenuItem(
                              value: item,
                              child: Text(
                                item.personel_adi,
                                style: const TextStyle(fontSize: 14),
                              ),
                            )).toList(),
                            value: selectedpaketsatici,
                            onChanged: (value) {
                              setState(() {
                                selectedpaketsatici = value;
                              });
                            },
                            buttonStyleData: const ButtonStyleData(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              height: 50,
                              width: 100,
                            ),
                            dropdownStyleData: const DropdownStyleData(
                              maxHeight: 200,
                            ),
                            menuItemStyleData: const MenuItemStyleData(
                              height: 40,
                            ),
                            dropdownSearchData: DropdownSearchData(
                              searchController: saticiController,
                              searchInnerWidgetHeight: 50,
                              searchInnerWidget: Container(
                                height: 50,
                                padding: const EdgeInsets.all(8),
                                child: TextFormField(
                                  expands: true,
                                  maxLines: null,
                                  controller: saticiController,
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    hintText: 'Ara..',
                                    hintStyle: const TextStyle(fontSize: 12),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                  ),
                                ),
                              ),
                              searchMatchFn: (item, searchValue) {
                                final personelAdi = item.value?.personel_adi?.toLowerCase();
                                return personelAdi != null && personelAdi.contains(searchValue.toLowerCase());
                              },
                            ),
                            onMenuStateChange: (isOpen) {
                              if (!isOpen) {
                                saticiController.clear();
                              }
                            },
                          ),
                        ),
                      ),
                      /*SizedBox(height: 10),
                      Column(
                        children: List.generate(selectedData.length, (index) {
                          var item = selectedData[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 0.0),
                                  child: Text(
                                    '${item.paket_adi}',
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(left: 0.0),
                                            child: Text(
                                              'Randevu Tarihi',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 10),
                                          Container(
                                            height: 40,
                                            padding: const EdgeInsets.only(left: 0.0, right: 0),
                                            child: TextFormField(
                                              controller: paketbaslangictarihi[index],
                                              enabled: true,
                                              onSaved: (value) {
                                                paketbaslangictarihi[index].text = value!;
                                              },
                                              decoration: InputDecoration(
                                                focusColor: Color(0xFF6A1B9A),
                                                hoverColor: Color(0xFF6A1B9A),
                                                hintStyle: TextStyle(color: Color(0xFF6A1B9A)),
                                                contentPadding: EdgeInsets.all(15.0),
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
                                              readOnly: true,
                                              onTap: () async {
                                                DateTime? pickedDate = await showDatePicker(
                                                  context: context,
                                                  initialDate: DateTime.now(),
                                                  firstDate: DateTime(1950),
                                                  lastDate: DateTime(2100),
                                                );

                                                if (pickedDate != null) {
                                                  String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
                                                  setState(() {
                                                    paketbaslangictarihi[index].text = formattedDate;
                                                  });
                                                }
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(left: 10.0),
                                            child: Text(
                                              'Randevu Saati',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 10),
                                          Container(
                                            height: 40,
                                            padding: const EdgeInsets.only(left: 10.0, right: 0),
                                            child: TextFormField(
                                              controller: paketbaslangicsaati[index],
                                              onTap: () async {
                                                TimeOfDay? pickedTime = await showTimePicker(
                                                  context: context,
                                                  initialTime: TimeOfDay.now(),
                                                  builder: (BuildContext context, Widget? child) {
                                                    return MediaQuery(
                                                      data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                                                      child: child!,
                                                    );
                                                  },
                                                );

                                                if (pickedTime != null && pickedTime != _selectedTime) {
                                                  setState(() {
                                                    _selectedTime[index] = pickedTime;
                                                    paketbaslangicsaati[index].text = DateFormat.Hm().format(
                                                      DateTime(
                                                        2023,
                                                        1,
                                                        1,
                                                        pickedTime.hour,
                                                        pickedTime.minute,
                                                      ),
                                                    );
                                                  });
                                                }
                                              },
                                              decoration: InputDecoration(
                                                focusColor: Color(0xFF6A1B9A),
                                                hoverColor: Color(0xFF6A1B9A),
                                                hintStyle: TextStyle(color: Color(0xFF6A1B9A)),
                                                contentPadding: EdgeInsets.all(15.0),
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
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(left: 0.0),
                                            child: Text(
                                              'Seans Aralığı (Gün)',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 10),
                                          Container(
                                            height: 40,
                                            padding: const EdgeInsets.only(left: 0.0, right: 0),
                                            child: TextFormField(
                                              controller: paketseansaraligi[index],
                                              onSaved: (value) {
                                                paketseansaraligi[index].text = value!;
                                              },
                                              keyboardType: TextInputType.phone,
                                              enabled: true,
                                              decoration: InputDecoration(
                                                focusColor: Color(0xFF6A1B9A),
                                                hoverColor: Color(0xFF6A1B9A),
                                                hintStyle: TextStyle(color: Color(0xFF6A1B9A)),
                                                contentPadding: EdgeInsets.all(15.0),
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
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(left: 10.0),
                                            child: Text(
                                              'Paketi Satan',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 10),
                                          Container(
                                            alignment: Alignment.center,
                                            margin: EdgeInsets.only(left: 10),
                                            height: 40,
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              border: Border.all(color: Color(0xFF6A1B9A)),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: DropdownButtonHideUnderline(
                                              child: DropdownButton2<Personel>(
                                                isExpanded: true,
                                                hint: Text(
                                                  'Satıcı Seç',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Theme.of(context).hintColor,
                                                  ),
                                                ),
                                                items: paketsatici.map((item) => DropdownMenuItem(
                                                  value: item,
                                                  child: Text(
                                                    item.personel_adi,
                                                    style: const TextStyle(fontSize: 14),
                                                  ),
                                                )).toList(),
                                                value: selectedpaketsatici[index],
                                                onChanged: (value) {
                                                  setState(() {
                                                    selectedpaketsatici[index] = value!;
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
                                                dropdownSearchData: DropdownSearchData(
                                                  searchController: psatici[index],
                                                  searchInnerWidgetHeight: 50,
                                                  searchInnerWidget: Container(
                                                    height: 50,
                                                    padding: const EdgeInsets.all(8),
                                                    child: TextFormField(
                                                      expands: true,
                                                      maxLines: null,
                                                      controller: psatici[index],
                                                      decoration: InputDecoration(
                                                        isDense: true,
                                                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                        hintText: ' Ara..',
                                                        hintStyle: const TextStyle(fontSize: 12),
                                                        border: OutlineInputBorder(
                                                          borderRadius: BorderRadius.circular(5),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  searchMatchFn: (item, searchValue) {
                                                    return item.value.toString().contains(searchValue);
                                                  },
                                                ),
                                                onMenuStateChange: (isOpen) {
                                                  if (!isOpen) {
                                                    psatici[index].clear();
                                                  }
                                                },
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),
                      ),*/
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text("Vazgeç"),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    bool isvalid = true;
                    if(selectedmusteri == null)
                      isvalid =false;
                    if(selectedpaketsatici == null)
                      isvalid =false;
                    /*paketbaslangictarihi.forEach((element) {
                      int ind1 = 0;
                      if(element == "")
                        isvalid =false;
                      if(selectedpaketsatici[ind1]==null)
                        isvalid =false;
                      ind1 = ind1 +1;
                    });
                    paketbaslangicsaati.forEach((element) {
                      if(element == "")
                        isvalid =false;
                    });
                    paketseansaraligi.forEach((element) {

                      if(element == "")
                        isvalid =false;
                    });*/
                    if(!isvalid)
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('UYARI'),
                            content: Text('Satış için müşteri ve satıcı seçimini yapmanız gerekmektedir!'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop(); // Dismiss the dialog
                                },
                                child: Text('TAMAM'),
                              ),

                            ],
                          );
                        },
                      );
                    else
                    {
                      int i = 0;
                      bool valid = true;
                      selectedData.forEach((element) async {
                        double toplamfiyat = 0;
                        element.hizmetler.forEach((element2) {
                          toplamfiyat += element2["fiyat"] ;
                        });

                        final AdisyonPaket paket = AdisyonPaket(id: "", adisyon_id: "", paket_id: element?.id ?? "", baslangic_tarihi: paketbaslangictarihi[i].text, seans_araligi: paketseansaraligi[i].text, fiyat: toplamfiyat.toString(), personel_id: selectedpaketsatici!.id, taksitli_tahsilat_id: "", senet_id: "", indirim_tutari: "", hediye: "",seans_baslangic_saati: paketbaslangicsaati[i].text);
                        AdisyonPaket eklenenpaket = await adisyonpaketekle(paket,selectedmusteri?.id ?? "" ,context,  seciliisletme!, paketbaslangicsaati[i].text,false,"");
                        if(eklenenpaket != AdisyonPaket)
                          valid = false;
                        i = i+1;

                      });
                      if(valid)
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (builder) => TahsilatEkrani(isletmebilgi: isletme_bilgi, musteridanisanid: selectedmusteri?.id ?? "",),
                          ),
                        );

                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green[400],  foregroundColor: Colors.white,),
                  child: Text("Tahsilata Git"),
                ),
              ],
            );
          },
        );
      },
    );
  }
  void paketahsilet()
  {
    //List<String> adetdegerleri = paketadet.map((controller) => controller.text).toList();

  }




}

import 'dart:async';
import 'dart:developer';


import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:randevu_sistem/Frontend/progressloading.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:randevu_sistem/Models/musteri_danisanlar.dart';
import 'package:randevu_sistem/yonetici/adisyonlar/satislar/tahsilat.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import '../../../../Frontend/lazyload.dart';
import '../../../../Frontend/popupdialogs.dart';
import '../../../../Models/adisyonurunler.dart';
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

import '../ayarlar/urunler/urunduzenle.dart';


class Urunler extends StatefulWidget {
  final Kullanici kullanici;
  final dynamic isletmebilgi;
  final int kullanicirolu;
  final String adisyonId;
  Urunler ({Key? key, required this.adisyonId, required this.kullanici,required this.isletmebilgi,required this.kullanicirolu}) : super(key: key);
  @override

  _UrunlerState createState() => _UrunlerState();
}

class _UrunlerState extends State<Urunler> {
  MusteriDanisan? selectedmusteri;
  late List<MusteriDanisan> musteris;
  List<TextEditingController> urunadet = [];
  List<TextEditingController> usatici = [];
  late UrunDataSource _urunDataGridSource;
  late List<bool> selectedRows;
  late List <Personel> urunsatici;
  List <Personel> selectedUrunSatici = [];
  late String? seciliisletme;
  bool  _isLoading= true;
  TextEditingController musteriController = TextEditingController();
  int totalPages = 1;
  bool anyChecked = false;
  bool selectAll = false;

  Timer? _debounce;
  TextEditingController _controller = TextEditingController();
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

    if (_controller.text.length == 0 || _controller.text.length >= 3) {

      if (_debounce?.isActive ?? false) _debounce!.cancel();

      _debounce = Timer(const Duration(milliseconds: 500), () {
        if (_controller.text != lastQuery && !firsttimetyping) {  // Check if the query is different
          setState(() {

            firsttimetyping=false;
            lastQuery = _controller.text; // Update the last search query
            _urunDataGridSource.search(_controller.text);
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
      _urunDataGridSource.anyChecked.value = isChecked;
    });
  }
  Future<void> initialize() async
  {

    seciliisletme = await secilisalonid();

    List <Personel> personelliste = await personellistegetir(seciliisletme!);


      setState(() {

        urunsatici = personelliste;
        _urunDataGridSource = UrunDataSource(rowsPerPage:10,salonid: seciliisletme!,context: context,checkBoxChecked: onCheckboxChanged,isletmebilgi: widget.isletmebilgi);
        _urunDataGridSource.isLoadingNotifier.addListener(_onLoadingStateChanged);
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
    return    GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus(); // Hide the keyboard
      },
          child: _isLoading
              ? Center(child: CircularProgressIndicator())
              :Scaffold(
          floatingActionButton: _urunDataGridSource.anyChecked.value  ? Stack(
            fit: StackFit.expand,
            children: [

              Positioned(
                bottom: 15,
                left: 30,

                child: ElevatedButton(

                  onPressed: () {
                    _showPopup(context);
                  },
                  style: ElevatedButton.styleFrom(padding: EdgeInsets.all(15), backgroundColor: Colors.purple[800],   foregroundColor: Colors.white,shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(55)))),
                  child: Text('Satış\n Yap',style: TextStyle(fontSize: 12),),
                ),
              ),
            ],
          ) : null,


          appBar: AppBar(
            title: Text('Stok Yönetimi',style: TextStyle(color: Colors.black,fontSize: 18),),
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),

            toolbarHeight: 60,
            actions: <Widget>[
              if(widget.isletmebilgi["demo_hesabi"].toString() == "1")
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: SizedBox(
                  width: 100, // <-- Your width
                  child: YukseltButonu(isletme_bilgi: widget.isletmebilgi)
                ),
              ),
              IconButton(onPressed: (){
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => YeniUrun(salonid: seciliisletme!,urunDataSource: _urunDataGridSource,isletmebilgi: widget.isletmebilgi,)),
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
                      hintText: 'Ürün Adı...',
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
                    source: _urunDataGridSource,
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
                            //Navigator.of(context).pop();
                            //Navigator.push(context, new MaterialPageRoute(builder: (context) => new KampanyaDuzenle(kampanyadetayi: row.getCells()[0].value as Kampanya,)));
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => UrunDuzenle(urundetayi: row.getCells()[0].value as Urun,salonid: seciliisletme!,urunDataSource: _urunDataGridSource,isletmebilgi: widget.isletmebilgi)),
                            );

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
                            final confirmed = await _urunDataGridSource.showDeleteConfirmationDialog(context,int.parse(row.getCells()[1].value), () {
                              // Perform deletion

                              setState(() {
                                showProgressLoading(context);
                                _urunDataGridSource.sil(context,int.parse(row.getCells()[1].value));



                              });
                            });

                          },
                          child: Container(
                              color: Colors.red,
                              child: Center(
                                child: Icon(Icons.delete,color: Colors.white,),
                              )));
                    },
                    onCellTap: (DataGridCellTapDetails details) {

                      final tappedRow = _urunDataGridSource.rows[details.rowColumnIndex.rowIndex - 1];
                      _showDetailsDialog(context,tappedRow.getCells()[0].value);
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
                          child: Text(''), // Sadece başlık olarak "Seç" yazısı
                        ),
                      ),
                      GridColumn(

                        width: width*0,
                        columnName: 'urun',
                        label: Container(

                          padding: EdgeInsets.all(5.0),
                          alignment: Alignment.centerLeft,
                          child: Text('Ürünpar'),
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

                        width: width*0.40,
                        columnName: 'urunadi',
                        label: Container(

                          padding: EdgeInsets.all(5.0),
                          alignment: Alignment.centerLeft,
                          child: Text('Ürün Adı'),
                        ),
                      ),

                      GridColumn(
                        width: width*0.25,
                        columnName: 'stok',
                        label: Container(
                          padding: EdgeInsets.all(5.0),
                          alignment: Alignment.centerLeft,
                          child: Text('Stok (Adet)'),
                        ),
                      ),


                      GridColumn(
                        width: width*0.25,
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
                  ),
                ),


                _buildPaginationControls()
              ],
            );}

          )


    ),
        );



  }


  Widget _buildPaginationControls() {

    final totalPages = (_urunDataGridSource.totalPages).ceil();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: _urunDataGridSource.currentPage > 1
              ? () {
            setState(() {

              _urunDataGridSource.setPage(_urunDataGridSource.currentPage - 1);
            });
          }
              : null,
        ),
        Text('Sayfa ${_urunDataGridSource.currentPage} / $totalPages'),
        IconButton(
          icon: Icon(Icons.arrow_forward),
          onPressed: _urunDataGridSource.currentPage < totalPages
              ? () {
            setState(() {
              _urunDataGridSource.setPage(_urunDataGridSource.currentPage + 1);
            });
          }
              : null,
        ),
      ],
    );
  }
  void _showPopup(BuildContext context) {
    // Variables to store the selected values from the dropdowns

    List<Urun> selectedData = [];
    for (int i = 0; i < _urunDataGridSource.selectedRows.value.length; i++) {
      if (_urunDataGridSource.selectedRows.value[i]) {
        selectedData.add(_urunDataGridSource.urun[i]);
        urunadet = List.generate(_urunDataGridSource.selectedRows.value.length, (index) => TextEditingController());
        usatici = List.generate(_urunDataGridSource.selectedRows.value.length, (index) => TextEditingController());
        selectedUrunSatici = List.generate(_urunDataGridSource.selectedRows.value.length, (index) => urunsatici[0]);
      }
    }

    showDialog(

      context: context,
      builder: (BuildContext context,) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return AlertDialog(

                title: Text("Satış Yap",style: TextStyle(fontWeight: FontWeight.bold),),
                content: SingleChildScrollView(
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 0.0),
                          child: Text('Müşteri',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                        ),
                        SizedBox(height: 10,),
                        Container(



                          height: 60,
                          width:double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Color(0xFF6A1B9A)),
                            borderRadius: BorderRadius.circular(10), //border corner radius

                            //you can set more BoxShadow() here

                          ),
                          child: DropdownButtonHideUnderline(

                              child:  LazyDropdown(
                                salonId: widget.isletmebilgi['id'].toString(),
                                selectedItem: selectedmusteri,
                                onChanged: (value) {

                                  setState(() {
                                    selectedmusteri = value;
                                  });


                                },
                              ), ),
                        ),

                        SizedBox(height: 10,),
                        ListView.builder(
                          shrinkWrap: true,
                          itemCount: selectedData.length,
                          itemBuilder: (context, index) {
                            var item = selectedData[index];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(left: 0.0),
                                            child: Text('${item.urun_adi} için adet',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                                          ),
                                          SizedBox(height: 10,),
                                          Container(
                                            height: 40,
                                            padding: const EdgeInsets.only(left: 0.0,right: 0),
                                            child: TextFormField(
                                              controller: urunadet[index],

                                              onSaved: (value){
                                                if(value!=null)
                                                  urunadet[index].text = value;
                                              },
                                              keyboardType: TextInputType.number,

                                              enabled:true,

                                              decoration: InputDecoration(

                                                focusColor:Color(0xFF6A1B9A) ,
                                                hoverColor: Color(0xFF6A1B9A) ,
                                                hintStyle: TextStyle(color:  Color(0xFF6A1B9A)),
                                                contentPadding:  EdgeInsets.all(15.0),
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
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(left: 20.0),
                                            child: Text('Satıcı',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                                          ),
                                          SizedBox(height: 10,),
                                          Container(

                                            alignment: Alignment.center,
                                            margin: EdgeInsets.only(left:20,),
                                            height: 40,
                                            width:double.infinity,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              border: Border.all(color: Color(0xFF6A1B9A)),
                                              borderRadius: BorderRadius.circular(10), //border corner radius

                                              //you can set more BoxShadow() here

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
                                                  items: urunsatici
                                                      .map((item) => DropdownMenuItem(
                                                    value: item,
                                                    child: Text(
                                                      item.personel_adi,
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ))
                                                      .toList(),
                                                  value: selectedUrunSatici[index],

                                                  onChanged: (value) {
                                                    setState(() {
                                                      selectedUrunSatici[index] = value!;
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
                                                    searchController: usatici[index],
                                                    searchInnerWidgetHeight: 50,
                                                    searchInnerWidget: Container(
                                                      height: 50,
                                                      padding: const EdgeInsets.only(
                                                        top: 8,
                                                        bottom: 4,
                                                        right: 8,
                                                        left: 8,
                                                      ),
                                                      child: TextFormField(
                                                        expands: true,
                                                        maxLines: null,
                                                        controller: usatici[index],
                                                        decoration: InputDecoration(
                                                          isDense: true,
                                                          contentPadding: const EdgeInsets.symmetric(
                                                            horizontal: 10,
                                                            vertical: 8,
                                                          ),
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
                                                  //This to clear the search value when you close the menu
                                                  onMenuStateChange: (isOpen) {
                                                    if (!isOpen) {
                                                      usatici[index].clear();
                                                    }
                                                  },

                                                )),
                                          ),
                                        ],
                                      ),
                                    )
                                  ],
                                ),



                                SizedBox(height: 10,),
                              ],
                            );
                          },
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
                    child: Text("İptal Et"),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      bool isvalid = true;
                      if(selectedmusteri == null)
                        isvalid =false;
                      urunadet.forEach((element) {

                        if(element == "0" || element == "")
                          isvalid =false;
                      });

                      if(!isvalid)
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('UYARI'),
                              content: Text('Lütfen formu eksiksiz doldurunuz.'),
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
                          double toplamfiyat = double.parse(element.fiyat) * double.parse(urunadet[i].text);
                          final AdisyonUrun urun = AdisyonUrun(islem_tarihi: DateFormat("yyyy-MM-dd").format(DateTime.now()), id:"",adisyon_id: "", urun_id: element?.id ?? "", adet: urunadet[i].text, fiyat:toplamfiyat.toString()  , personel_id:  selectedUrunSatici[i].id, taksitli_tahsilat_id: "", senet_id: "", indirim_tutari: "", hediye: "false", aciklama: "",urun: element?.toJson() ?? "", personel:  selectedUrunSatici[i]);
                          AdisyonUrun eklenenurun = await adisyonurunekle(urun,selectedmusteri?.id ?? "" ,context,seciliisletme!,false);
                          if(eklenenurun != AdisyonUrun)
                            valid = false;
                          i = i+1;

                        });
                        if(valid)
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (builder) => TahsilatEkrani(adisyonId: widget.adisyonId, kullanicirolu: widget.kullanicirolu, isletmebilgi: widget.isletmebilgi, musteridanisanid: selectedmusteri?.id ?? "",),
                            ),
                          );

                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green[400],  foregroundColor: Colors.white,),
                    child: Text("Tahsilata Git"),
                  ),
                ],
              );
            }
        );
      },
    );
  }
  void uruntahsilet()
  {
    List<String> adetdegerleri = urunadet.map((controller) => controller.text).toList();

  }
  void _showDetailsDialog(BuildContext context ,Urun urun ) {
    final _formKey = GlobalKey<FormState>();


    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          insetPadding: EdgeInsets.zero,
          content: Container(

            height: 200,
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
                      foregroundColor: Colors.white,
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
                          Text(urun.urun_adi,style: TextStyle(fontWeight: FontWeight.bold),),
                        ],
                      ),
                      Divider(color: Colors.black,
                        height: 10,),
                      Row(
                        children: [
                          Text('Stok'), SizedBox(width: 5,),
                          Text(':'),
                          Text(urun.stok_adedi)
                        ],
                      ),
                      Row(
                        children: [
                          Text('Fiyat'), SizedBox(width: 5,),
                          Text(':'),
                          Text(urun.fiyat+' ₺')
                        ],
                      ),
                      Row(
                        children: [
                          Text('Barkod'), SizedBox(width: 5,),
                          Text(':'),
                          Text(urun.barkod)
                        ],
                      ),
                      Row(
                        children: [
                          Text('Düşük Stok Sınırı'), SizedBox(width: 2,),
                          Text(':'),
                          Text(urun.dusuk_stok_siniri)
                        ],
                      ),

                      SizedBox(height: 10,),
                      Divider(color: Colors.black,),

                      Row(

                        children: [
                          ElevatedButton(onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => UrunDuzenle(urundetayi: urun,salonid: seciliisletme!,urunDataSource: _urunDataGridSource,isletmebilgi: widget.isletmebilgi)),
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
                          SizedBox(width: 15,),
                          ElevatedButton(onPressed: () {
                            _urunDataGridSource.sil(context,int.parse(urun.id));
                          }, child:
                          Text('Sil'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red[600],
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

}

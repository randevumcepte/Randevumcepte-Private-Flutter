  import 'dart:developer';

  import 'package:dropdown_button2/dropdown_button2.dart';

  import 'package:flutter/material.dart';
  import 'package:intl/intl.dart';
  import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';

  import 'package:randevu_sistem/yonetici/adisyonlar/satislar/tahsilat.dart';
import 'package:randevu_sistem/yonetici/diger/diger_page.dart';

  import 'package:syncfusion_flutter_datagrid/datagrid.dart';

  import '../../Backend/backend.dart';
  import '../../Frontend/indexedstack.dart';
  import '../../Frontend/lazyload.dart';
import '../../Frontend/sfdatatable.dart';
  import '../../Models/adisyonlar.dart';
  import '../../Models/musteri_danisanlar.dart';
  import '../../Models/satislar.dart';
  import '../../Models/satisturleri.dart';

  import 'package:provider/provider.dart';

  import '../../Models/user.dart';

  class AdisyonlarPage extends StatefulWidget {
    final Kullanici kullanici;
    final int kullanicirolu;
    final dynamic isletmebilgi;
    AdisyonlarPage({Key? key, required this.kullanici,required this.isletmebilgi,required this.kullanicirolu}) : super(key: key);
    @override
    _AdisyonlarPageState createState() => _AdisyonlarPageState();
  }

  class _AdisyonlarPageState extends State<AdisyonlarPage> {
    bool _isLoading = true;
    final List<SatisTuru> adisyonicerigi = [
      SatisTuru(id: "", satisturu: "Tümü"),
      SatisTuru(id: "1", satisturu: "Hizmet Satışları"),
      SatisTuru(id: "2", satisturu: "Paket Satışları"),
      SatisTuru(id: "3", satisturu: "Ürün Satışları"),
    ];
    late String? seciliisletme;
    SatisTuru? selectedadisyonicerigi;
    TextEditingController adisyonicerigicontroller = TextEditingController();
    late SatisDataSource _satisDataGridSource;
    String? selectedadisyondurum;
    MusteriDanisan? selectedMusteri;
    TextEditingController adisyondurumcontroller = TextEditingController();

    TextEditingController tarih1 = TextEditingController(text: "1970-01-01");
    TextEditingController tarih2 = TextEditingController(
        text: DateFormat("yyyy-MM-dd").format(DateTime.now()));
    TextEditingController musteridanisanadi = TextEditingController();
    DateTime? startDate;
    DateTime? endDate;


    DateTimeRange? _selectedDateRange;

    void initState() {
      super.initState();
      initialize();
    }

    Future<void> initialize() async {
      seciliisletme = await secilisalonid();

      setState(() {

        selectedadisyonicerigi = adisyonicerigi[0];
        _satisDataGridSource = SatisDataSource(
          musteriMi: false,
            isletmebilgi:widget.isletmebilgi,
            rowsPerPage: 10,
            salonid: seciliisletme!,
            context: context,
            tarih1: tarih1.text,
            tarih2: tarih2.text,
            musteriid: "",
            tur: selectedadisyonicerigi?.id ?? "",
            personelid: "",
            userid: widget.kullanicirolu==5?widget.kullanici.id:''
        );
        _satisDataGridSource.isLoadingNotifier
            .addListener(_onLoadingStateChanged);
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
      double width = MediaQuery.of(context).size.width;
      double height = MediaQuery.of(context).size.height;
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Satışlar',
            style: TextStyle(color: Colors.black),
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
            IconButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) {
                    return StatefulBuilder(
                      builder: (context, setStateSB) {
                        return Column(

                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            SizedBox(height: 20),
                            Container(
                              padding:
                              const EdgeInsets.only(left: 20.0, right: 20),
                              child: Text(
                                'Müşteri/danışan',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(height: 10),
                            Container(
                              margin:
                              const EdgeInsets.only(left: 20.0, right: 20),
                              alignment: Alignment.center,
                              height: 40,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Color(0xFF6A1B9A)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child:  LazyDropdown(
                                salonId: seciliisletme??'',
                                selectedItem: selectedMusteri,
                                onChanged: (value) {
                                  selectedMusteri = value;

                                },
                              ),
                            ),
                            SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.only(left: 20.0),
                              child: Text(
                                'Satış İçeriği',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(height: 10),
                            Container(
                              alignment: Alignment.center,
                              margin: EdgeInsets.only(left: 20, right: 20),
                              height: 40,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Color(0xFF6A1B9A)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton2<SatisTuru>(
                                  isExpanded: true,
                                  hint: Text(
                                    'Seçiniz..',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Theme.of(context).hintColor,
                                    ),
                                  ),
                                  items: adisyonicerigi
                                      .map((item) => DropdownMenuItem(
                                    value: item,
                                    child: Text(
                                      item.satisturu,
                                      style: const TextStyle(
                                        fontSize: 14,
                                      ),
                                    ),
                                  ))
                                      .toList(),
                                  value: selectedadisyonicerigi,
                                  onChanged: (value) {
                                    setStateSB(() {
                                      selectedadisyonicerigi = value;
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
                                    searchController: adisyonicerigicontroller,
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
                                        controller: adisyonicerigicontroller,
                                        decoration: InputDecoration(
                                          isDense: true,
                                          contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 8,
                                          ),
                                          hintText: 'Ara...',
                                          hintStyle:
                                          const TextStyle(fontSize: 12),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                            BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ),
                                    searchMatchFn: (item, searchValue) {
                                      return item.value
                                          .toString()
                                          .contains(searchValue);
                                    },
                                  ),
                                  onMenuStateChange: (isOpen) {
                                    if (!isOpen) {
                                      adisyonicerigicontroller.clear();
                                    }
                                  },
                                ),
                              ),
                            ),
                            SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.only(left: 20.0),
                              child: Text(
                                'Tarihe Göre',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(height: 10),
                            Container(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton(
                                    onPressed: () async {
                                      final DateTimeRange? picked =
                                      await showDateRangePicker(
                                        context: context,
                                        firstDate: DateTime(1970),
                                        lastDate: DateTime(2050),
                                        initialDateRange: _selectedDateRange,
                                      );

                                      if (picked != null &&
                                          picked != _selectedDateRange) {
                                        setStateSB(() {
                                          _selectedDateRange = picked;
                                        });
                                      }
                                    },
                                    child: Text('Tarih Aralığını Giriniz'),
                                    style: ElevatedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                        backgroundColor: Colors.black),
                                  ),

                                ],
                              ),
                            ),
                            SizedBox(height: 10),
                            Container(
                              height: 40,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _selectedDateRange != null
                                        ? DateFormat("dd.MM.yyyy").format(
                                        _selectedDateRange!.start
                                            .toLocal()) +
                                        " - " +
                                        DateFormat("dd.MM.yyyy").format(
                                            _selectedDateRange!.end.toLocal())
                                        : "Tarih Seçilmedi.",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 18,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    String tarih1 = _selectedDateRange != null
                                        ? DateFormat("yyyy-MM-dd").format(
                                        _selectedDateRange!.start.toLocal())
                                        : "1970-01-01";
                                    String tarih2 = _selectedDateRange != null
                                        ? DateFormat("yyyy-MM-dd").format(
                                        _selectedDateRange!.end.toLocal())
                                        : DateFormat("yyyy-MM-dd")
                                        .format(DateTime.now());
                                    _satisDataGridSource.search(
                                        tarih1,
                                        tarih2,
                                        selectedMusteri?.id ?? "",
                                        selectedadisyonicerigi?.id ?? "",
                                        true);
                                  },
                                  child: Text('Ara'),
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor:Colors.white,
                                      backgroundColor: Color(0xFF6A1B9A)),
                                ),
                                SizedBox(width: 10),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    tarih1.text = "1970-01-01";
                                    tarih2.text = DateFormat("yyyy-MM-dd").format(DateTime.now());

                                    setStateSB(() {

                                      _selectedDateRange = null;
                                      selectedMusteri = null;
                                      selectedadisyonicerigi = null;// Resetting the date range
                                    });
                                    _satisDataGridSource.search(
                                        tarih1.text,
                                        tarih2.text ,
                                        selectedMusteri?.id ?? "",
                                        selectedadisyonicerigi?.id ?? "",
                                        true);
                                  },
                                  child: Text('Formu Sıfırla'),
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                      backgroundColor: Colors.grey),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
              icon: Icon(
                Icons.search,
                size: 30,
                color: Color(0xFF6A1B9A),
              ),
            ),
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TahsilatEkrani(isletmebilgi: widget.isletmebilgi,musteridanisanid: "")),
                );
              },
              icon: Icon(
                Icons.add,
                color: Colors.black,
              ),
              iconSize: 26,
            ),
          ],
          backgroundColor: Colors.white,
        ),
        body: _isLoading
            ? Center(
          child: CircularProgressIndicator(),
        )
            : GestureDetector(
            child: Column(children: [
              Expanded(

                // Adjust the height based on your requirements
                child: SfDataGrid(
                  source: _satisDataGridSource,
                  shrinkWrapRows: true,
                  columnWidthMode: ColumnWidthMode.fill,
                  defaultColumnWidth: 120,
                  allowSwiping: true,
                  onQueryRowHeight: (details) {
                    if (details.rowIndex == 0) {
                      return details.rowHeight; // header satırı
                    }

                    final row = _satisDataGridSource.effectiveRows[details.rowIndex - 1];
                    final description = row
                        .getCells()
                        .firstWhere((cell) => cell.columnName == 'musteridanisantarih')
                        .value
                        .toString();

                    // burada aynı oranı tekrar kullanabilirsin
                    final columnWidth = MediaQuery.of(context).size.width * 0.5;

                    return calculateTextHeight(
                      description,
                      columnWidth,
                      const TextStyle(fontSize: 14),
                    );
                  },
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
                          log('tahsilat için dokunuldu');
                          final Adisyon satis = row.getCells()[0].value;
                          Navigator.push(
                              context,
                              new MaterialPageRoute(
                                  builder: (context) => TahsilatEkrani(isletmebilgi: widget.isletmebilgi,musteridanisanid: satis.user_id)));
                        },
                        child: Container(
                            color: Colors.purple,
                            child: Center(
                              child: Icon(Icons.money, color: Colors.white),
                            )));
                  },
                  endSwipeActionsBuilder:
                      (BuildContext context, DataGridRow row, int rowIndex) {
                    return GestureDetector(
                        onTap: () async {
                          //_ongorusmeDataGridSource.showAjandaSilmeConfirmationDialog(context, row.getCells()[1].value);
                        },
                        child: Container(
                            color: Colors.red,
                            child: Center(
                              child: Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            )));
                  },
                  onCellTap: (DataGridCellTapDetails details) {
                    final tappedRow = _satisDataGridSource.rows[details.rowColumnIndex.rowIndex - 1];
                    final Adisyon satis = tappedRow.getCells()[0].value;

                    // Eğer kalan tutar sıfır ise hiçbir işlem yapma
                    if (satis.kalan_tutar == "0" || satis.kalan_tutar == "0,00") {
                      return;
                    }

                    // Eğer kalan tutar sıfır değilse, sayfaya yönlendir
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TahsilatEkrani(
                          isletmebilgi: widget.isletmebilgi,
                          musteridanisanid: satis.user_id,
                        ),
                      ),
                    );
                  },
                  columns: <GridColumn>[
                    GridColumn(
                      width: width * 0,
                      columnName: 'satis',
                      label: Container(
                        padding: EdgeInsets.all(2.0),
                        alignment: Alignment.centerLeft,
                        child: Text('a'),
                      ),
                    ),
                    GridColumn(
                      width: width * 0,
                      columnName: 'id',
                      label: Container(
                        padding: EdgeInsets.all(2.0),
                        alignment: Alignment.centerLeft,
                        child: Text('#'),
                      ),
                    ),
                    GridColumn(
                      width: width * 0.25,
                      columnName: 'musteridanisantarih',
                      label: Container(
                        padding: EdgeInsets.all(2.0),
                        alignment: Alignment.centerLeft,
                        child: Text('Satış Bilgisi'),
                      ),
                    ),
                    GridColumn(
                      width: width * 0.25,
                      columnName: 'toplam',
                      label: Container(
                        padding: EdgeInsets.all(2.0),
                        alignment: Alignment.center,
                        child: Text('Toplam ₺'),
                      ),
                    ),
                    GridColumn(
                      width: width * 0.25,
                      columnName: 'odenen',
                      label: Container(
                        padding: EdgeInsets.all(2.0),
                        alignment: Alignment.center,
                        child: Text('Ödenen ₺'),
                      ),
                    ),
                    GridColumn(
                      width: width * 0.25,
                      columnName: 'kalan',
                      label: Container(
                        padding: EdgeInsets.all(2.0),
                        alignment: Alignment.center,
                        child: Text('Kalan ₺'),
                      ),
                    ),
                  ],
                ),
              ),
              _buildPaginationControls()
            ])),
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
              height: 280,
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
                        Text(
                          'Anıl Orbey',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Divider(
                          color: Colors.black,
                          height: 10,
                        ),
                        Row(
                          children: [
                            Text('Telefon'),
                            SizedBox(
                              width: 22,
                            ),
                            Text(':'),
                            Text(' 5316237563')
                          ],
                        ),
                        Row(
                          children: [
                            Text('Hizmet'),
                            SizedBox(
                              width: 25,
                            ),
                            Text(': '),
                            Expanded(
                                child: Text('Ağda (tüm vücut)(Cevriye Güleç)'))
                          ],
                        ),
                        Row(
                          children: [
                            Text('Zaman'),
                            SizedBox(
                              width: 26,
                            ),
                            Text(':'),
                            Text(' 07.09.2023 17:45')
                          ],
                        ),
                        Row(
                          children: [
                            Text('Oluşturan'),
                            SizedBox(
                              width: 7.5,
                            ),
                            Text(':'),
                            Text(' Elif Çetin')
                          ],
                        ),
                        Row(
                          children: [
                            Text('Durum'),
                            SizedBox(
                              width: 10,
                            ),
                            SizedBox(
                              width: 18,
                            ),
                            Text(':'),
                            Text(' Onaylı')
                          ],
                        ),
                        Divider(
                          color: Colors.black,
                          height: 10,
                        ),
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () {},
                              child: Text('Düzenle'),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple[800],
                                  elevation: 5,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5.0)),
                                  minimumSize: Size(130, 30)),
                            ),
                            SizedBox(
                              width: 15,
                            ),
                            ElevatedButton(
                              onPressed: () {},
                              child: Text('İptal Et'),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  elevation: 5,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5.0)),
                                  minimumSize: Size(130, 30)),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () {},
                              child: Text('Gelmedi'),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  elevation: 5,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5.0)),
                                  minimumSize: Size(130, 30)),
                            ),
                            SizedBox(
                              width: 15,
                            ),
                            ElevatedButton(
                              onPressed: () {},
                              child: Text('Geldi & Tahsilat'),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  elevation: 5,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5.0)),
                                  minimumSize: Size(20, 30)),
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

    Widget _buildPaginationControls() {
      final totalPages = (_satisDataGridSource.totalPages).ceil();

      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: _satisDataGridSource.currentPage > 1
                ? () {
              setState(() {
                _satisDataGridSource.setPage(
                    _satisDataGridSource.currentPage - 1,
                    tarih1.text,
                    tarih2.text,
                    "",
                    selectedadisyonicerigi?.id ?? "");
              });
            }
                : null,
          ),
          Text('Sayfa ${_satisDataGridSource.currentPage} / $totalPages'),
          IconButton(
            icon: Icon(Icons.arrow_forward),
            onPressed: _satisDataGridSource.currentPage < totalPages
                ? () {
              setState(() {
                _satisDataGridSource.setPage(
                    _satisDataGridSource.currentPage + 1,
                    tarih1.text,
                    tarih2.text,
                    "",
                    selectedadisyonicerigi?.id ?? "");
              });
            }
                : null,
          ),
        ],
      );
    }

    void printWidgetInfo(Widget widget) {
      debugPrint('Widget info : $widget');
    }
  }



import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';


import 'package:syncfusion_flutter_datagrid/datagrid.dart';


import '../../../../../Frontend/sfdatatable.dart';
import '../../../../../Models/musteri_danisanlar.dart';

import '../../../../../Models/satisturleri.dart';




class MusteriALinanUrunlerDashboard extends StatefulWidget {
  final MusteriDanisan kullanici;
  final dynamic isletmebilgi;
  MusteriALinanUrunlerDashboard({Key? key, required this.kullanici,required this.isletmebilgi}) : super(key: key);
  @override
  _MusteriAdiayonlariState createState() => _MusteriAdiayonlariState();
}

class _MusteriAdiayonlariState extends State<MusteriALinanUrunlerDashboard> {
  bool _isLoading = true;
  final List<SatisTuru> adisyonicerigi = [
    SatisTuru(id: "", satisturu: "Tümü"),
    SatisTuru(id: "1", satisturu: "Hizmet Satışları"),
    SatisTuru(id: "2", satisturu: "Paket Satışları"),
    SatisTuru(id: "3", satisturu: "Ürün Satışları"),
  ];

  SatisTuru? selectedadisyonicerigi;
  TextEditingController adisyonicerigicontroller = TextEditingController();
  late SatisDataSource _satisDataGridSource;
  String? selectedadisyondurum;
  MusteriDanisan? selectedMusteri;
  TextEditingController adisyondurumcontroller = TextEditingController();
  late List<MusteriDanisan> musteridanisanliste;

  TextEditingController tarih1 = TextEditingController(text: "1970-09-01");
  TextEditingController tarih2 = TextEditingController(
      text: DateFormat("yyyy-MM-dd").format(DateTime.now()));
  TextEditingController musteridanisanadi = TextEditingController();
  DateTime? startDate;
  DateTime? endDate;
  late dynamic isletme_bilgi;

  DateTimeRange? _selectedDateRange;

  void initState() {
    super.initState();
    initialize();
  }

  Future<void> initialize() async {





    setState(() {


      selectedadisyonicerigi = adisyonicerigi[0];
      _satisDataGridSource = SatisDataSource(
        musteriMi: true,
        isletmebilgi: widget.isletmebilgi,
        rowsPerPage: 10,
        salonid: widget.isletmebilgi['id'].toString(),
        context: context,
        tarih1: tarih1.text,
        tarih2: tarih2.text,
        musteriid:  widget.kullanici.id,
        personelid:"",
        userid: '',
        tur:  "3", );
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
          'Satın Aldığım Ürünler',
          style: TextStyle(color: Colors.black),
        ),
        leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              Navigator.of(context).pop();
            }),
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
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(),
      )
          : SingleChildScrollView(
          child: Column(children: [
            _satisDataGridSource.rows.length == 0 ? Center(child: Text('Satın almış olduğunuz ürün bulunmamaktadır'),) :
            Container(
              height: height - 145,
              // Adjust the height based on your requirements
              child:  SfDataGrid(
                source: _satisDataGridSource,
                shrinkWrapRows: true,
                columnWidthMode: ColumnWidthMode.fill,
                defaultColumnWidth: 120,

                rowHeight: 75,
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
                  final tappedRow = _satisDataGridSource
                      .rows[details.rowColumnIndex.rowIndex - 1];


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
                      child: Text('Ürün Adı'),
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

/*import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../anasayfa.dart';






class MusteriALinanPaketlerDashboard extends StatefulWidget {
  MusteriALinanPaketlerDashboard({Key? key}) : super(key: key);
  @override
  _MusteriALinanPaketlerDashboardState createState() => _MusteriALinanPaketlerDashboardState();
}

class _MusteriALinanPaketlerDashboardState extends State<MusteriALinanPaketlerDashboard> {
  List<Map<String, dynamic>> data = [
    { 'Paket': 'Bayram Paketi', 'Fiyat': '1000','odenen': '500','Kalan':'500','icon': Icons.chevron_right},
    {'Paket': 'Ekim Paketi', 'Fiyat': '1500','odenen': '1000','Kalan':'500','icon': Icons.chevron_right},
    {'Paket': 'Kasım Paketi', 'Fiyat': '105000','odenen': '100000','Kalan':'5000','icon': Icons.chevron_right},


  ];


  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(

      floatingActionButton: WhatsAppFAB(),
      appBar: AppBar(
        title: Text('Aldığım Paketler',style: TextStyle(color:Colors.black),),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        toolbarHeight: 60,

        backgroundColor: Colors.white,




      ),
      body:
      SingleChildScrollView(
        child: Container(

          width: 500,
          child: InteractiveViewer(
            scaleEnabled: false,
            child: DataTable(
              columnSpacing: 10,
              showCheckboxColumn: false,
              columns: [
                DataColumn(label: Expanded(child: Text('Paket Adı'))),
                DataColumn(label: Expanded(child: Text('Fiyat'))),
                DataColumn(label: Expanded(child: Text('Ödenen'))),
                DataColumn(label: Expanded(child: Text('Kalan'))),
              ],
              rows: data.map((item) {

                // Determine whether to show the icon
                return  DataRow(
                  cells: [

                    DataCell(
                      Container(width:60,child: Text(item['Paket'].toString())),
                    ),

                    DataCell(
                      ElevatedButton(onPressed: (){},style: ElevatedButton.styleFrom(backgroundColor:Colors.purple[800],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
                          minimumSize: Size(80, 20)

                      )

                          ,child: Text(item['Fiyat'],style: TextStyle(color: Colors.white),)),
                    ),
                    DataCell(
                      ElevatedButton(onPressed: (){ },style: ElevatedButton.styleFrom(backgroundColor:Colors.green,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
                          minimumSize: Size(80, 20)

                      )

                          ,child: Text(item['odenen'],style: TextStyle(color: Colors.white),)),
                    ),
                    DataCell(
                      Row(
                        children: [
                          ElevatedButton(onPressed: (){ },style: ElevatedButton.styleFrom(backgroundColor:Colors.red[600],
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
                              minimumSize: Size(80, 20)

                          )

                              ,child: Text(item['Kalan'],style: TextStyle(color: Colors.white),)),


                        ],
                      ),
                    ),
                  ],


                );
              }


              )
                  .toList(),



            ),
          ),
        ),
      ),


    );
  }


}
class WhatsAppFAB extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 65.0,
      height: 65.0,
      child: FloatingActionButton(
        onPressed: () {
          // Handle the FAB press
          WhatsAppOpener.openWhatsApp('+902323130028', '');
        },
        backgroundColor: Color(0xFF25D366), // WhatsApp green color
        child: SvgPicture.asset(
          'images/wp5.svg', // Replace with the actual path to your WhatsApp SVG icon
          width: 30,
          height: 40,
          color: Colors.white,
        ),
      ),
    );
  }
}
*/
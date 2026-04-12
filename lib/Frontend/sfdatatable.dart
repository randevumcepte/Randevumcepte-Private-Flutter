import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:randevu_sistem/Frontend/popupdialogs.dart';
import 'package:randevu_sistem/Frontend/progressloading.dart';
import 'package:randevu_sistem/Frontend/telefonnumralarinigizle.dart';
import 'package:randevu_sistem/Models/kampanyalar.dart';


import 'package:path/path.dart' as path;
import 'package:randevu_sistem/yonetici/diger/diger_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:randevu_sistem/Backend/backend.dart';
import '../Models/adisyonkalemleri.dart';
import '../Models/adisyonlar.dart';
import '../Models/ajanda.dart';
import '../Models/alacaklarmodel.dart';
import '../Models/cihazlar.dart';
import '../Models/etkinlikler.dart';
import '../Models/form.dart';
import '../Models/hizmetler.dart';
import '../Models/masrafkategorileri.dart';
import '../Models/masraflar.dart';
import '../Models/musteri_danisanlar.dart';
import '../Models/odalar.dart';
import '../Models/odemeturu.dart';
import '../Models/ongorusmeler.dart';
import '../Models/paketler.dart';
import '../Models/paketsatislari.dart';
import '../Models/personel.dart';
import '../Models/personelcihaz.dart';
import '../Models/randevuhizmetleri.dart';
import '../Models/randevular.dart';

import '../Models/seanstakibi.dart';
import '../Models/senetler.dart';
import '../Models/e_asistan.dart';
import '../Models/sms_taslaklari.dart';
import '../Models/tahsilatlar.dart';
import '../Models/urunler.dart';

import '../Models/urunsatislari.dart';
import '../yeni/calisan_secim.dart';
import '../yonetici/adisyonlar/satislar/varolantahsilat.dart';
import '../yonetici/dashboard/gunlukRaporlar/ongorduzenle.dart';
import '../yonetici/diger/menu/ajanda/ajanda.dart';
import '../yonetici/diger/menu/ajanda/ajandaduzenle.dart';
import '../yonetici/diger/menu/ayarlar/personeller/personelduzenle.dart';
import '../yonetici/diger/menu/ayarlar/personeller/personelsatislari.dart';
import '../yonetici/diger/menu/ayarlar/urunler/urunduzenle.dart';
import '../yonetici/diger/menu/etkinlik/etkinikler.dart';
import '../yonetici/diger/menu/etkinlik/etkinlikduzenle.dart';
import '../yonetici/diger/menu/kampanya/kampanyalar.dart';
import '../yonetici/diger/menu/kampanya/kampanyaduzenle.dart';
import 'package:http/http.dart' as http;
import 'package:randevu_sistem/Models/colorandtext.dart';
import 'package:intl/intl.dart';
import '../yonetici/diger/menu/kasa/masrafduzenle.dart';
import '../yonetici/diger/menu/musteriler/musteriduzenle.dart';
import '../yonetici/diger/menu/ongorusmeler/ongorusmeduzenle.dart';
import '../yonetici/diger/menu/senetler/senetvadeleri.dart';
import '../yonetici/diger/menu/senetler/yazdir.dart';
import '../yonetici/randevular/randevuduzenle.dart';
import 'arsivdetay.dart';
import 'datetimeformatting.dart';
import 'package:randevu_sistem/yonetici/diger/menu/musteriler/musteridetaylar.dart';
import 'package:randevu_sistem/yonetici/adisyonlar/satislar/tahsilat.dart';

import 'dosyaindir.dart';
import 'filedownloader.dart';
import 'dart:ui' as ui;

/*class KampanyaDataSource extends DataGridSource {


  late BuildContext context2;


  List<Kampanya> _kampanyalar = [];
  List<DataGridRow> _kampanyaRows = [];
  KampanyaDataSource(List<Kampanya> kampanyalar, BuildContext context) {

    context2 = context;

    _kampanyalar = kampanyalar;
    buildKampanyaDataGridRows();

  }
  void buildKampanyaDataGridRows() {
    _kampanyaRows = _kampanyalar
        .map<DataGridRow>((e) => DataGridRow(cells: [
      DataGridCell<Kampanya>(columnName: 'campaign',value: e),
      DataGridCell<String>(columnName: 'id', value: e.id),
      DataGridCell<String>(columnName: 'paket', value: e.paket_isim),
      DataGridCell<String>(columnName: 'hizmet', value: e.hizmet_adi),
      DataGridCell<String>(columnName: 'katilimci', value: e.katilimcilar.length.toString()),
      DataGridCell<String>(columnName: 'fiyat', value: e.fiyat),
    ]))
        .toList();
  }

  @override
  List<DataGridRow> get rows => _kampanyaRows;


  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    List<Widget> cellwidget = row.getCells().map<Widget>((cell) {
      return Container(
        alignment: (cell.columnName=='katilimci' || cell.columnName=='fiyat') ? Alignment.centerRight :Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(cell.value.toString()),
      );
    }).toList();
    cellwidget.add(Container(
        alignment: Alignment.center,
        child:PopupMenuButton<String>(
          onSelected: (String value) {
            
            if(value=='kampanyaduzenle')
            {
              Navigator.of(context2).pop();
              Navigator.push(context2, new MaterialPageRoute(builder: (context2) => new KampanyaDuzenle(kampanyadetayi: row.getCells()[0].value as Kampanya,)));
            }
            if(value=='kampanyasil')
            {

              //showKampanyaDeleteConfirmationDialog(context2,int.parse(row.getCells()[1].value));

            }
            print(value);
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: 'kampanyaduzenle',
              child: Text('Düzenle'),
            ),
            PopupMenuItem<String>(
              value: 'kampanyasil',
              child: Text('Sil'),
            ),
          ],
        )
    ));
    return DataGridRowAdapter(cells: cellwidget);
  }
  void deleteKampanya(int id) {


    _kampanyaRows.removeWhere((row) => row.getCells()[1].value == id);


    notifyListeners();

  }

  void updateKampanyaDataSource(List<Kampanya> newKampanyalar) {

    _kampanyaRows = newKampanyalar
        .map<DataGridRow>((e) => DataGridRow(cells: [

      DataGridCell<Kampanya>(columnName: 'campaign',value: e),
      DataGridCell<String>(columnName: 'id', value: e.id),
      DataGridCell<String>(columnName: 'paket', value: e.paket_isim),
      DataGridCell<String>(columnName: 'hizmet', value: e.hizmet_adi),
      DataGridCell<String>(columnName: 'katilimci', value: e.katilimcilar.length.toString()),
      DataGridCell<String>(columnName: 'fiyat', value: e.fiyat),
    ]))
        .toList();

    notifyListeners();
  }


} */
class OnGorusmeDataSource2 extends DataGridSource {
  int rowsPerPage;
  int currentPage;
  int totalPages = 1;
  int totalRows;
  String arama;
  BuildContext context;
  dynamic isletmebilgi;

  List<OnGorusme> ongorusme = [];
  List<DataGridRow> _paginatedRows = [];
  ValueNotifier<bool> isLoadingNotifier = ValueNotifier(false);
  String salonid;

  OnGorusmeDataSource2({
    required this.context,
    required this.rowsPerPage,
    required this.salonid,
    required this.arama,
    required this.isletmebilgi,
  }) : currentPage = 1, totalRows = 0 {
    fetchData2(currentPage.toString(), arama, false);
  }

  Future<void> fetchData2(String page, String arama, bool showprogress) async {
    isLoadingNotifier.value = true;
    if (showprogress) {
      showProgressLoading(context);
    }
    notifyListeners();

    try {
      final jsonResponse = await ongorusmelergunluk(salonid, page.toString(), arama);

      // DEBUG: Gelen veriyi logla
      log('Gelen veri: ${jsonResponse.toString()}');

      List<dynamic> data = jsonResponse['data'];

      // DEBUG: Data listesini logla
      log('Data listesi uzunluğu: ${data.length}');

      ongorusme = data.map<OnGorusme>((json) => OnGorusme.fromJson(json)).toList();

      // DEBUG: Map edilmiş ön görüşmeleri logla
      log('Map edilmiş ön görüşmeler: ${ongorusme.length}');

      // _paginatedRows'ı temizle
      _paginatedRows.clear();
      totalRows = 0;

      for (var e in ongorusme) {
        totalRows++;

        // Paket/Ürün bilgisini doğru şekilde oluştur
        String paketUrunBilgisi = '';
        if (e.urun_id != null && e.urun_id != "null" && e.urun != null) {
          paketUrunBilgisi = e.urun["urun_adi"] ?? "";
        } else if (e.paket_id != null && e.paket_id != "null" && e.paket != null) {
          paketUrunBilgisi = e.paket["paket_adi"] ?? "";
        }

        _paginatedRows.add(
            DataGridRow(cells: [
              DataGridCell<OnGorusme>(columnName: 'ongorusme', value: e),
              DataGridCell<String>(columnName: 'id', value: e.id),
              DataGridCell<String>(columnName: 'musteridanisan', value: e.ad_soyad),
              DataGridCell<String>(columnName: 'paketurun', value: paketUrunBilgisi),
              DataGridCell<String>(columnName: 'durum', value: e.durum.toString()),
            ])
        );
      }

      // DEBUG: Oluşturulan satırları logla
      log('Oluşturulan DataGrid satırları: ${_paginatedRows.length}');

      totalPages = jsonResponse['last_page'] ?? 1;
      currentPage = jsonResponse['current_page'] ?? 1;

    } catch (e) {
      log('fetchData2 hatası: $e');
    } finally {
      isLoadingNotifier.value = false;
      if (showprogress) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      notifyListeners();
    }
  }

  void search(String musteridanisanadi) {
    currentPage = 1;
    arama = musteridanisanadi;
    fetchData2("1", musteridanisanadi, false);
  }

  void setPage(int page) {
    if (page > 0 && page <= totalPages) {
      currentPage = page;
      fetchData2(currentPage.toString(), "", true);
    }
  }

  @override
  List<DataGridRow> get rows => _paginatedRows;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    return DataGridRowAdapter(cells: [
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[0].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[1].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[2].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[3].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[4].value.toString()),
      ),
      Container(
        padding: EdgeInsets.only(top: 10.0, bottom: 10.0),
        height: 20,
        child: ElevatedButton(
          onPressed: () {
            String status = row.getCells()[4].value.toString();
            if (status == '0') {
              showReasonDialog(context, row.getCells()[0].value);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: getOngorusmeStatusColor(row.getCells()[4].value.toString())?.color,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
            minimumSize: Size(100, 20),
          ),
          child: Text(
            getOngorusmeStatusColor(row.getCells()[4].value.toString()).text,
            style: TextStyle(color: Colors.white, fontSize: 10),
          ),
        ),
      ),
      Container(
        alignment: Alignment.center,
        child: (row.getCells()[4].value.toString() != '1' && row.getCells()[4].value.toString() != '0')
            ? PopupMenuButton<String>(
          onSelected: (String value) {
            if (value == 'duzenle') {
              // Düzenleme işlemi
            }
            if (value == 'satisyapildi') {
              OnGorusme selectedItem = row.getCells()[0].value;
              if (selectedItem.paket_id != null && selectedItem.paket_id != "null") {
                showPackagePopup(context, row.getCells()[1].value);
              } else if (selectedItem.urun_id != null && selectedItem.urun_id != "null") {
                showProductPopup(context, row.getCells()[1].value);
              }
            }
            if (value == 'satisyapilmadi') {
              showSatisYapilmamaNedeniDialog(
                  context,
                  row.getCells()[1].value,
                  currentPage.toString(),
                  arama,
                      (value) => fetchData2(value["currentPage"] = "1", value["arama"] = "", value["showprogress"] = true)
              );
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: 'duzenle',
              child: Text('Düzenle'),
            ),
            PopupMenuItem<String>(
              value: 'satisyapildi',
              child: Text('Satış Yapıldı'),
            ),
            PopupMenuItem<String>(
              value: 'satisyapilmadi',
              child: Text('Satış Yapılmadı'),
            ),
          ],
        )
            : Container(),
      ),
    ]);
  }

  void showReasonDialog(BuildContext context, OnGorusme ongorusme) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Satış Yapılmama Sebebi"),
          content: Text(ongorusme.satisyapilmadi_not ?? "Sebep belirtilmemiş"),
          actions: <Widget>[
            TextButton(
              child: Text("Kapat"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
  void showPackagePopup(BuildContext context, String ongorusmeid) {
    TextEditingController ongorusmetarihi = TextEditingController();
    TextEditingController seansaralik = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          scrollable: true,
          title: Text(
            'Paket satışına devam etmek için lütfen aşağıdan başlangıç tarihi seçip seans gün aralığını belirleyin!',
            style: TextStyle(fontSize: 14),
          ),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Session date input
              Padding(
                padding: const EdgeInsets.only(left: 0.0),
                child: Text(
                  'Seans Başlangıç Tarihi',
                  style: TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 10),
              Container(
                height: 40,
                padding: EdgeInsets.only(left: 0, right: 20),
                child: TextFormField(
                  controller: ongorusmetarihi,
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
                  readOnly: true, // User cannot directly enter text
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1950),
                      lastDate: DateTime(2100),
                    );

                    // Update the TextFormField with the selected date
                    if (pickedDate != null) {
                      // Format the date as needed (e.g., yyyy-MM-dd)
                      String formattedDate =  DateFormat('yyyy-MM-dd').format(pickedDate);
                      ongorusmetarihi.text = formattedDate;
                    }
                  },
                ),
              ),
              SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 0.0),
                child: Text(
                  'Seans Aralığı (Gün)',
                  style: TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 10),
              Container(
                height: 40,
                padding: EdgeInsets.only(left: 0, right: 20),
                child: TextField(
                  controller: seansaralik,
                  keyboardType: TextInputType.number,
                  maxLines: 1,
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
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Kapat', style: TextStyle(color: Colors.black)),
            ),
            TextButton(
              onPressed: () {
                satisyapildi(context, ongorusmeid, '', ongorusmetarihi.text, seansaralik.text);
              },
              child: Text('Kaydet', style: TextStyle(color: Colors.purple[800])),
            ),
          ],
        );
      },
    );
  }

  void showProductPopup(BuildContext context, String  ongorusmeid) {
    TextEditingController quantityController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          scrollable: true,
          title: Text('Ürün satışına devam etmek için lütfen ürün adedini belirleyiniz!',style:TextStyle(fontSize:16)),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 0.0),
                child: Text('Adet', style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),),
              ),
              SizedBox(height: 10,),
              Container(
                height: 50,
                child: TextField(
                  controller: quantityController,  // Set the controller
                  keyboardType: TextInputType.number,
                  maxLines: 1,
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
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Kapat', style: TextStyle(color: Colors.black)),
            ),
            TextButton(
              onPressed: () {
                satisyapildi(context, ongorusmeid, quantityController.text,'','');
              },
              child: Text('Kaydet', style: TextStyle(color: Colors.purple[800])),
            ),
          ],
        );
      },
    );
  }



  void satisyapildi(BuildContext context, String ongorusmeid,String adet,String baslangictarih,String seansaralik) async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();

    var user = jsonDecode(localStorage.getString('user')!);

    showProgressLoading(context);
    Map<String, dynamic> formData = {
      'ongorusmeid': ongorusmeid,
      'baslangic_tarihi': baslangictarih,
      'urun_adedi': adet,
      'seans_araligi': seansaralik,
      'olusturan':user['id']
    };

    final response = await http.post(
      Uri.parse('https://app.randevumcepte.com.tr/api/v1/ongorusmesatisyapildi'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(formData),
    );
    Navigator.of(context).pop();
    if (response.statusCode == 200) {
      Navigator.of(context).pop();
      fetchData2(currentPage.toString(), arama, false);
    } else {

      debugPrint(response.body);
    }
  }
  Future<void> onGorusmeEkleGuncelle2(String ongorusmeid,String musteri_id,String ad_soyad,String telefon,String email, String cinsiyet,context,String salonid,String sehir,String referans,String meslek,String urun_id, String paket_id, String randevu_tarihi, String randevu_saati, String aciklama,String personelid,String cakisanrandevuekle) async {

    SharedPreferences localStorage = await SharedPreferences.getInstance();
    List<RandevuHizmet>randevuhizmetleri = [
      RandevuHizmet(cihaz: "",cihaz_id: "",fiyat: "",personel_id: personelid,hizmet_id: "1",hizmetler: "",oda: "",oda_id: "",personeller: "",saat: randevu_saati,saat_bitis: "",sure_dk: "60",yardimci_personel: "",birusttekiileaynisaat: "0")
    ];
    var user = jsonDecode(localStorage.getString('user')!);

    showProgressLoading(context);
    Map<String, dynamic> formData = {
      'on_gorusme_id':ongorusmeid,
      'musteri_id': musteri_id,
      'ad_soyad': ad_soyad,
      'telefon':telefon,
      'email': email,
      'cinsiyet': cinsiyet,
      'salonid':salonid,
      'il_id' : sehir,
      'musteri_tipi': referans,
      'meslek':meslek,
      'urun_id':urun_id,
      'paket_id':paket_id,
      'randevu_tarihi':randevu_tarihi,
      'randevu_saati':randevu_saati,
      'aciklama':aciklama,
      'olusturan': user["id"],
      'gorusmeyi_yapan':personelid,
      'cakisanrandevuekle':cakisanrandevuekle,
      'hizmetler':randevuhizmetleri,




      // Add other form fields
    };

    final response = await http.post(
      Uri.parse('https://app.randevumcepte.com.tr/api/v1/ongorusmeekleguncelle'),

      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(formData),
    );

    if (response.statusCode == 200) {
      log(response.body);
      dynamic result = json.decode(response.body);

      if(result["cakismavar"]=="1")
      {
        Navigator.of(context,rootNavigator: true).pop();
        showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('UYARI'),
              content: Text('Oluşturduğunuz öngörüşme randevusu aşağıdakilerle çakışmaktadır!\n\n'+result["cakisanunsurlar"].replaceAll(r'\n', '\n')),
              actions: <Widget>[
                TextButton(
                  child: Text('VAZGEÇ'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('YİNE DE RANDEVUYU OLUŞTUR'),
                  onPressed: () {
                    onGorusmeEkleGuncelle2(ongorusmeid,musteri_id, ad_soyad, telefon, email,  cinsiyet,context, salonid, sehir, referans, meslek, urun_id,  paket_id,  randevu_tarihi,  randevu_saati,  aciklama, personelid, "1");


                  },
                ),
              ],
            );
          },
        );

      }
      else{
        Navigator.of(context,rootNavigator: true).pop();
        Navigator.of(context).pop();
      }

      fetchData2("1", arama, false);

    } else {
      Navigator.of(context,rootNavigator: true).pop();
      logyaz(response.statusCode,response.reasonPhrase);
      debugPrint('Error: ${response.body}');

    }

  }



}
class OnGorusmeDataSource extends DataGridSource {

  int rowsPerPage;
  int currentPage;
  int totalPages = 1;
  int totalRows;
  String arama;
  BuildContext context;
  dynamic isletmebilgi;

  List<OnGorusme> ongorusme = [];

  List<DataGridRow> _paginatedRows = [];
  ValueNotifier<bool> isLoadingNotifier = ValueNotifier(false);

  String salonid;


  OnGorusmeDataSource({

    required this.context,
    required this.isletmebilgi,
    required this.rowsPerPage,
    required this.salonid,
    required this.arama,



  }): currentPage = 1, totalRows = 0 {
    fetchData(currentPage.toString(),'',false);
  }

  Future<void> fetchData(String page,String arama,bool showprogress) async {
    log("ön görüşme data fetch :"+page+" - "+arama+" - "+showprogress.toString() );
    isLoadingNotifier.value = true;
    notifyListeners();
    final jsonResponse = await ongorusmeler(salonid, page.toString(),arama);

    List<dynamic> data = jsonResponse['data'];
    ongorusme = data.map<OnGorusme>((json) => OnGorusme.fromJson(json)).toList();
    if(_paginatedRows.length>0)
      _paginatedRows = [];

    ongorusme.forEach((e) {
      ++totalRows;

      // Paket/Ürün adını doğru şekilde al
      String paketUrunAdi = _getPaketUrunAdi(e);

      _paginatedRows.add(
          DataGridRow(cells: [
            DataGridCell<OnGorusme>(columnName: 'ongorusme',value: e),
            DataGridCell<String>(columnName: 'id', value: e.id),
            DataGridCell<String>(columnName: 'musteridanisan', value: e.ad_soyad),
            DataGridCell<String>(columnName: 'paketurun', value: paketUrunAdi),
            DataGridCell<String>(columnName: 'durum', value: e.durum.toString()),
          ])
      );
    });
    totalPages = jsonResponse['last_page'];
    currentPage = jsonResponse['current_page'];
    isLoadingNotifier.value = false;
    notifyListeners();
  }

// Paket/Ürün adını güvenli şekilde almak için yardımcı metod
  String _getPaketUrunAdi(OnGorusme ongorusme) {
    String paketUrunAdi = "";

    // Önce ürün kontrolü
    if (ongorusme.urun_id != null && ongorusme.urun_id != "null" && ongorusme.urun_id.isNotEmpty) {
      if (ongorusme.urun is Map && ongorusme.urun.containsKey("urun_adi")) {
        paketUrunAdi = ongorusme.urun["urun_adi"]?.toString() ?? "";
      }
    }

    // Eğer ürün yoksa paket kontrolü
    if (paketUrunAdi.isEmpty && ongorusme.paket_id != null && ongorusme.paket_id != "null" && ongorusme.paket_id.isNotEmpty) {
      if (ongorusme.paket is Map && ongorusme.paket.containsKey("paket_adi")) {
        paketUrunAdi = ongorusme.paket["paket_adi"]?.toString() ?? "";
      }
    }



    // Hiçbiri yoksa
    if (paketUrunAdi.isEmpty) {
      paketUrunAdi = "Ön Görüşme";
    }

    return paketUrunAdi;
  }
  void search(String musteridanisanadi)
  {
    currentPage = 1;
    arama = musteridanisanadi;
    fetchData("1",musteridanisanadi,false);
  }
  void setPage(int page) {
    if (page > 0 && page <= totalPages) {
      currentPage = page;

      fetchData(currentPage.toString(),"",true);
    }
  }



  @override
  List<DataGridRow> get rows => _paginatedRows;


  @override
  DataGridRowAdapter buildRow(DataGridRow row) {

    return DataGridRowAdapter(cells: [


      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[0].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[1].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[2].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[3].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[4].value.toString()),
      ),
      Container(
        padding: EdgeInsets.only(top:10.0,bottom: 10.0),
        height: 20,
        child:  ElevatedButton(
          onPressed: () {
            String status = row.getCells()[4].value.toString();
            if (status == '0') {
              // Show a popup with the reason for not making a sale when status is 0
              showReasonDialog(context, row.getCells()[0].value);  // Pass the ID to get the reason
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: getOngorusmeStatusColor(row.getCells()[4].value.toString())?.color,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
            minimumSize: Size(100, 20),
          ),
          child: Text(
            getOngorusmeStatusColor(row.getCells()[4].value.toString()).text,
            style: TextStyle(color: Colors.white,fontSize: 10),
          ),
        ),
      ),
      // Seventh column (PopupMenuButton or empty container)
      Container(
        alignment: Alignment.center,
        child: (row.getCells()[4].value.toString() != '1' && row.getCells()[4].value.toString() != '0')
            ? PopupMenuButton<String>(
          onSelected: (String value) {
            if (value == 'duzenle') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OnGorusmeDuzenle(
                    isletmebilgi: isletmebilgi,
                    ongorusme: row.getCells()[0].value,
                    ongorusmedatasource: this,
                  ),
                ),
              );
            }
            if (value == 'satisyapildi') {
              OnGorusme selectedItem = row.getCells()[0].value;
              if (selectedItem.paket_id != null && selectedItem.paket_id != "null") {
                showPackagePopup(context, row.getCells()[1].value);
              } else if (selectedItem.urun_id != null && selectedItem.urun_id != "null") {
                showProductPopup(context, row.getCells()[1].value);
              }
            }
            if (value == 'satisyapilmadi') {
              showSatisYapilmamaNedeniDialog(context, row.getCells()[1].value,currentPage.toString(),arama,(value) => fetchData(value["currentPage"]="1", value["arama"]="", value["showprogress"]=true));
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: 'duzenle',
              child: Text('Düzenle'),
            ),
            PopupMenuItem<String>(
              value: 'satisyapildi',
              child: Text('Satış Yapıldı'),
            ),
            PopupMenuItem<String>(
              value: 'satisyapilmadi',
              child: Text('Satış Yapılmadı'),
            ),
          ],
        )
            : Container(), // Empty container when status is 1 or 0
      ),


    ]);
  }
  void showReasonDialog(BuildContext context, OnGorusme ongorusme) {


    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Satış Yapılmama Sebebi"),
          content: Text(ongorusme.satisyapilmadi_not),
          actions: <Widget>[
            TextButton(
              child: Text("Kapat"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
  void showPackagePopup(BuildContext context, String ongorusmeid) {
    TextEditingController ongorusmetarihi = TextEditingController();
    TextEditingController seansaralik = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          scrollable: true,
          title: Text(
            'Paket satışına devam etmek için lütfen aşağıdan başlangıç tarihi seçip seans gün aralığını belirleyin!',
            style: TextStyle(fontSize: 14),
          ),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Session date input
              Padding(
                padding: const EdgeInsets.only(left: 0.0),
                child: Text(
                  'Seans Başlangıç Tarihi',
                  style: TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 10),
              Container(
                height: 40,
                padding: EdgeInsets.only(left: 0, right: 20),
                child: TextFormField(
                  controller: ongorusmetarihi,
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
                  readOnly: true, // User cannot directly enter text
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1950),
                      lastDate: DateTime(2100),
                    );

                    // Update the TextFormField with the selected date
                    if (pickedDate != null) {
                      // Format the date as needed (e.g., yyyy-MM-dd)
                      String formattedDate =  DateFormat('yyyy-MM-dd').format(pickedDate);
                      ongorusmetarihi.text = formattedDate;
                    }
                  },
                ),
              ),
              SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 0.0),
                child: Text(
                  'Seans Aralığı (Gün)',
                  style: TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 10),
              Container(
                height: 40,
                padding: EdgeInsets.only(left: 0, right: 20),
                child: TextField(
                  controller: seansaralik,
                  keyboardType: TextInputType.number,
                  maxLines: 1,
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
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Kapat', style: TextStyle(color: Colors.black)),
            ),
            TextButton(
              onPressed: () {
                satisyapildi(context, ongorusmeid, '', ongorusmetarihi.text, seansaralik.text);
              },
              child: Text('Kaydet', style: TextStyle(color: Colors.purple[800])),
            ),
          ],
        );
      },
    );
  }

  void showProductPopup(BuildContext context, String  ongorusmeid) {
    TextEditingController quantityController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          scrollable: true,
          title: Text('Ürün satışına devam etmek için lütfen ürün adedini belirleyiniz!',style:TextStyle(fontSize:16)),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 0.0),
                child: Text('Adet', style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),),
              ),
              SizedBox(height: 10,),
              Container(
                height: 50,
                child: TextField(
                  controller: quantityController,  // Set the controller
                  keyboardType: TextInputType.number,
                  maxLines: 1,
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
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Kapat', style: TextStyle(color: Colors.black)),
            ),
            TextButton(
              onPressed: () {
                satisyapildi(context, ongorusmeid, quantityController.text,'','');
              },
              child: Text('Kaydet', style: TextStyle(color: Colors.purple[800])),
            ),
          ],
        );
      },
    );
  }


  void satisyapildi(BuildContext context, String ongorusmeid,String adet,String baslangictarih,String seansaralik) async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();

    var user = jsonDecode(localStorage.getString('user')!);

    showProgressLoading(context);
    Map<String, dynamic> formData = {
      'ongorusmeid': ongorusmeid,
      'baslangic_tarihi': baslangictarih,
      'urun_adedi': adet,
      'seans_araligi': seansaralik,
      'olusturan':user['id']
    };

    final response = await http.post(
      Uri.parse('https://app.randevumcepte.com.tr/api/v1/ongorusmesatisyapildi'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(formData),
    );
    Navigator.of(context).pop();
    if (response.statusCode == 200) {
      Navigator.of(context).pop();
      fetchData(currentPage.toString(), arama, false);
    } else {

      debugPrint(response.body);
    }
  }
  Future<void> onGorusmeEkleGuncelle(
      String ongorusmeid,
      String musteri_id,
      String ad_soyad,
      String telefon,
      String email,
      String cinsiyet,
      BuildContext context,
      String salonid,
      String sehir,
      String referans,
      String meslek,
      String urun_id,
      String paket_id,
      String randevu_tarihi,
      String randevu_saati,
      String aciklama,
      String personelid,
      String cakisanrandevuekle,
      String hizmet_id) async {

    SharedPreferences localStorage = await SharedPreferences.getInstance();
    var user = jsonDecode(localStorage.getString('user')!);

    showProgressLoading(context);

    List<Map<String, dynamic>> randevuhizmetleri = [
      {
        'cihaz': "",
        'cihaz_id': "",
        'fiyat': "",
        'personel_id': personelid,
        'hizmet_id': "1",
        'hizmetler': {},
        'oda': "",
        'oda_id': "",
        'personeller': {},
        'saat': randevu_saati,
        'saat_bitis': "",
        'sure_dk': "60",
        'yardimci_personel': "",
        'birusttekiileaynisaat': ""
      }
    ];

    Map<String, dynamic> formData = {
      'on_gorusme_id': ongorusmeid.isEmpty ? "" : ongorusmeid,
      'musteri_id': musteri_id.isEmpty ? "0" : musteri_id,
      'ad_soyad': ad_soyad,
      'telefon': telefon,
      'email': email.isEmpty ? "" : email,
      'cinsiyet': cinsiyet.isEmpty ? "" : cinsiyet,
      'salonid': salonid,
      'il_id': sehir.isEmpty ? "" : sehir,
      'musteri_tipi': referans.isEmpty ? "" : referans,
      'meslek': meslek.isEmpty ? "" : meslek,
      'urun_id': urun_id.isEmpty ? "" : urun_id,
      'paket_id': paket_id.isEmpty ? "" : paket_id,
      'hizmet_id': hizmet_id.isEmpty ? "" : hizmet_id,
      'randevu_tarihi': randevu_tarihi,
      'randevu_saati': randevu_saati,
      'aciklama': aciklama.isEmpty ? "" : aciklama,
      'olusturan': user["id"].toString(),
      'gorusmeyi_yapan': personelid.isEmpty ? "" : personelid,
      'cakisanrandevuekle': cakisanrandevuekle.isEmpty ? "" : cakisanrandevuekle,
      'hizmetler': randevuhizmetleri, 
    };

    try {
      final response = await http.post(
        Uri.parse('https://app.randevumcepte.com.tr/api/v1/ongorusmeekleguncelle'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(formData),
      );

      if (response.statusCode == 200) {
        dynamic result = json.decode(response.body);

        if (result["cakismavar"] == "1") {
          Navigator.of(context, rootNavigator: true).pop(); // Loading kapat

          // Çakışma varsa dialog göster
          await showDialog<bool>(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('UYARI'),
                content: Text('Oluşturduğunuz öngörüşme randevusu aşağıdakilerle çakışmaktadır!\n\n' +
                    result["cakisanunsurlar"].replaceAll(r'\n', '\n')),
                actions: <Widget>[
                  TextButton(
                    child: Text('VAZGEÇ'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  TextButton(
                    child: Text('YİNE DE RANDEVUYU OLUŞTUR'),
                    onPressed: () {
                      // Dialog'u kapat ve "1" (evet) değeri ile geri dön
                      Navigator.of(context).pop(true);
                    },
                  ),
                ],
              );
            },
          ).then((value) {
            // Eğer kullanıcı "YİNE DE RANDEVUYU OLUŞTUR" dediyse
            if (value == true) {
              // Ön görüşmeyi tekrar dene, bu sefer çakışmayı ignore et
              onGorusmeEkleGuncelle(
                  ongorusmeid, musteri_id, ad_soyad, telefon, email, cinsiyet,
                  context, salonid, sehir, referans, meslek, urun_id, paket_id,
                  randevu_tarihi, randevu_saati, aciklama, personelid, "1", hizmet_id
              );
            }
          });
        } else {
          // Başarılı kayıt
          Navigator.of(context, rootNavigator: true).pop(); // Loading kapat

          // Başarı mesajı göster
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ön görüşme başarıyla kaydedildi.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );

          // Sayfayı kapat ve öngörüşmeler listesine dön
          Navigator.of(context).pop();

          // Verileri güncelle
          fetchData("1", arama, false);
        }
      } else {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sunucu hatası: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bir hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

}
class KampanyaDataSource extends DataGridSource {
  List<DataGridRow> _paginatedRows = [];
  int rowsPerPage;
  int currentPage;

  int totalPages = 1;
  int totalRows;
  String salonid;

  String arama;
  dynamic isletmebilgi;
  BuildContext context;
  List<Kampanya> kampanya = [];


  ValueNotifier<bool> isLoadingNotifier = ValueNotifier(false);
  KampanyaDataSource({
    required this.rowsPerPage,
    required this.context,
    required this.salonid,
    required this.isletmebilgi,
    required this.arama,




  }) : currentPage = 1, totalRows = 0 {
    fetchData(currentPage.toString(),arama,true);
  }
  void search(String baslik)
  {
    currentPage = 1;
    fetchData("1",baslik,false);
  }
  Future<void> fetchData(String page,String baslik,bool showprogress) async {

    isLoadingNotifier.value = true;
    if(showprogress)
      showProgressLoading(context);
    notifyListeners();
    final jsonResponse = await kampanyagetir(salonid, page.toString(),baslik);

    List<dynamic> data = jsonResponse['data'];
    kampanya = data.map<Kampanya>((json) => Kampanya.fromJson(json)).toList();
    if(_paginatedRows.length>0)
      _paginatedRows = [];

    kampanya.forEach((e) {

      ++totalRows;
      _paginatedRows.add(
          DataGridRow(cells: [
            DataGridCell<Kampanya>(columnName: 'campaign',value: e),
            DataGridCell<String>(columnName: 'id', value: e.id),
            DataGridCell<String>(columnName: 'paket', value: e.paket_isim),
            DataGridCell<String>(columnName: 'hizmet', value: e.hizmet_adi),
            DataGridCell<String>(columnName: 'katilimci', value: e.katilimcilar.length.toString()),
            DataGridCell<String>(columnName: 'fiyat', value: e.fiyat),


          ])
      );
    });
    totalPages = jsonResponse['last_page'];
    currentPage = jsonResponse['current_page'];
    isLoadingNotifier.value = false;
    if(showprogress)
      Navigator.of(context, rootNavigator: true).pop();// Notify listeners that loading has finished
    notifyListeners();
  }

  void setPage(int page) {
    if (page > 0 && page <= totalPages) {
      currentPage = page;

      fetchData(currentPage.toString(),"",true);
    }
  }


  @override
  List<DataGridRow> get rows => _paginatedRows;


  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    final colorAndText = getStatusColorAndText(row.getCells()[4].value.toString());
    return DataGridRowAdapter(cells: [

      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[0].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[1].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[2].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[3].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[4].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[5].value.toString()),
      ),

      Container(
          alignment: Alignment.center,
          child:PopupMenuButton<String>(
            onSelected: (String value) async {
              if(value=='duzenle')
              {

                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => KampanyaDuzenle(kampanyadetayi: row.getCells()[0].value, kampanyadatasource: this,isletmebilgi:isletmebilgi)),
                );
              }
              if(value=='sil')
              {
                showKampanyaSilmeConfirmationDialog(context,row.getCells()[1].value.toString());
              }


            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'duzenle',
                child: Text('Düzenle'),
              ),
              PopupMenuItem<String>(
                value: 'sil',
                child: Text('Sil'),
              ),

            ],
          )
      )


    ]);


  }
  Future<bool?> showKampanyaSilmeConfirmationDialog(BuildContext context, String id)  {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Emin misiniz?'),
          content: Text('Veri silme işlemi geri alınamaz!'),
          actions: <Widget>[
            TextButton(
              child: Text('VAZGEÇ'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('SİL'),
              onPressed: () {
                kampanyasil(context,id);
              },
            ),
          ],
        );
      },
    );
  }
  Future<void> kampanyasil(BuildContext context, String id) async {
    Map<String, dynamic> formData = {
      'kampanyaid':id,
    };

    final response = await http.post(
      Uri.parse('https://app.randevumcepte.com.tr/api/v1/kampanyapasifet'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(formData),
    );

    if (response.statusCode == 200) {
      Navigator.of(context).pop();
      fetchData(currentPage.toString(), arama, true);
    }
    else {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kampanya silinirken bir hata oluştu! Hata kodu : '+response.statusCode.toString()),
        ),
      );
      debugPrint('Error: ${response.body}');
    }
  }
  Future<void> kampanyaekleguncelle(String kampanyaid,String salonid,Paket secilenpaket,String kampanya_mesaj,String seans,String hizmetler, String fiyat,List<MusteriDanisan> secilen_katilimcilar, context) async {

    SharedPreferences localStorage = await SharedPreferences.getInstance();

    var user = jsonDecode(localStorage.getString('user')!);
    Map<String, dynamic> formData = {
      'paket':secilenpaket.id.toString(),
      'kampanya_id': kampanyaid,
      'kampanya_sms': kampanya_mesaj,
      'kampanyapakethizmet': hizmetler,
      'kampanyapaketseans':seans,
      'kampanyapaketfiyat': fiyat,
      'olusturan': user['id'],
      'secilen_katilimcilar':jsonEncode(secilen_katilimcilar.map((itemler) => itemler.toJson()).toList()),


      // Add other form fields
    };

    final response = await http.post(
      Uri.parse('https://app.randevumcepte.com.tr/api/v1/kampanyaekleduzenle/'+salonid.toString()),

      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(formData),
    );

    if (response.statusCode == 200) {
      log('etkinlik ekleme : '+response.body);

      Navigator.of(context,rootNavigator: true).pop();
      Navigator.of(context).pop(response.body);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Kampanyalar(isletmebilgi:isletmebilgi), // Replace with your actual form screen widget
        ),
      );



    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kampanya eklenirken bir hata oluştu! Hata kodu : '+response.statusCode.toString()),
        ),
      );
      debugPrint('Error: ${response.body}');
    }




  }
}

class KatilimciDataSource extends DataGridSource {




  late BuildContext context2;


  List<dynamic> _katilimcilar = [];
  List<DataGridRow> _katilimciRows = [];
  KatilimciDataSource(List<dynamic> katilimcilar, BuildContext context,String durum) {

    context2 = context;

    _katilimcilar = katilimcilar;
    buildKatilimciDataGridRows(durum);

  }
  void buildKatilimciDataGridRows(String durum) {

    if(durum == '')
    {

      _katilimciRows = _katilimcilar
          .map<DataGridRow>((e) =>  DataGridRow(cells: [
        DataGridCell<String>(columnName: 'musteri',value: e['musteri']['name']),
        DataGridCell<String>(columnName: 'telefon', value: e['musteri']['cep_telefon']),
        DataGridCell<String>(columnName: 'durum', value: e['durum'].toString()),

      ]))
          .toList();
    }

    if(durum == '1'){

      _katilimciRows = _katilimcilar.where((element) => element['durum']=='1')
          .map<DataGridRow>((e) =>  DataGridRow(cells: [
        DataGridCell<String>(columnName: 'musteri',value: e['musteri']['name']),
        DataGridCell<String>(columnName: 'telefon', value: e['musteri']['cep_telefon']),
        DataGridCell<String>(columnName: 'durum', value: e['durum'].toString()),


      ]))
          .toList();
    }

    if(durum == '0')
      _katilimciRows = _katilimcilar.where((element) => element['durum']=='0').map<DataGridRow>((e) =>  DataGridRow(cells: [
        DataGridCell<String>(columnName: 'musteri',value: e['musteri']['name']),
        DataGridCell<String>(columnName: 'telefon', value: e['musteri']['cep_telefon']),
        DataGridCell<String>(columnName: 'durum', value: e['durum'].toString()),


      ]))
          .toList();
    if(durum == 'null')
      _katilimciRows = _katilimcilar.where((element) => element['durum']==null).map<DataGridRow>((e) =>  DataGridRow(cells: [
        DataGridCell<String>(columnName: 'musteri',value: e['musteri']['name']),
        DataGridCell<String>(columnName: 'telefon', value: e['musteri']['cep_telefon']),
        DataGridCell<String>(columnName: 'durum', value: e['durum'].toString()),

      ]))
          .toList();
  }
  @override
  List<DataGridRow> get rows => _katilimciRows;
  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    List<Widget> cellwidget = row.getCells().map<Widget>((cell) {

      return Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(cell.value.toString()),
      );

    }).toList();
    cellwidget.add(
      Container(
        padding: EdgeInsets.only(top:10.0,bottom: 10.0),
        height: 20,
        child:  ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: getStatusColorAndText(row.getCells()[2].value.toString()).color,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
            minimumSize: Size(100, 20),
          ),
          child: Text(
            getStatusColorAndText(row.getCells()[2].value.toString()).text,
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),

    );

    return DataGridRowAdapter(cells: cellwidget);
  }
  void updateKatilimciDataSource(List<dynamic> newKatilimcilar,String durum) {

    if(durum == '')
    {

      _katilimciRows = newKatilimcilar
          .map<DataGridRow>((e) =>  DataGridRow(cells: [
        DataGridCell<String>(columnName: 'musteri',value: e['musteri']['name']),
        DataGridCell<String>(columnName: 'telefon', value: e['musteri']['cep_telefon']),
        DataGridCell<String>(columnName: 'durum', value: e['durum'].toString()),

      ]))
          .toList();
    }

    if(durum == '1'){

      _katilimciRows = newKatilimcilar.where((element) => element['durum']==1)
          .map<DataGridRow>((e) =>  DataGridRow(cells: [
        DataGridCell<String>(columnName: 'musteri',value: e['musteri']['name']),
        DataGridCell<String>(columnName: 'telefon', value: e['musteri']['cep_telefon']),
        DataGridCell<String>(columnName: 'durum', value: e['durum'].toString()),


      ]))
          .toList();
    }

    if(durum == '0')
      _katilimciRows = newKatilimcilar.where((element) => element['durum']==0).map<DataGridRow>((e) =>  DataGridRow(cells: [
        DataGridCell<String>(columnName: 'musteri',value: e['musteri']['name']),
        DataGridCell<String>(columnName: 'telefon', value: e['musteri']['cep_telefon']),
        DataGridCell<String>(columnName: 'durum', value: e['durum'].toString()),


      ]))
          .toList();
    if(durum == 'null')
      _katilimciRows = newKatilimcilar.where((element) => element['durum']==null).map<DataGridRow>((e) =>  DataGridRow(cells: [
        DataGridCell<String>(columnName: 'musteri',value: e['musteri']['name']),
        DataGridCell<String>(columnName: 'telefon', value: e['musteri']['cep_telefon']),
        DataGridCell<String>(columnName: 'durum', value: e['durum'].toString()),

      ]))
          .toList();

    notifyListeners();
  }



}

class ArsivDataSource extends DataGridSource {

  int rowsPerPage;
  int currentPage;
  int totalPages = 1;
  int totalRows;
  String arama;
  BuildContext context;


  List<Arsiv> arsiv = [];

  List<DataGridRow> _paginatedRows = [];
  ValueNotifier<bool> isLoadingNotifier = ValueNotifier(false);

  String salonid;
  String musteriid;
  String durum = '';
  String cevapladi = '';
  String cevapladi2 = '';
  ArsivDataSource({

    required this.context,
    required this.durum,
    required this.cevapladi,
    required this.cevapladi2,
    required this.rowsPerPage,
    required this.salonid,
    required this.arama,
    required this.musteriid,

  }): currentPage = 1, totalRows = 0 {
    fetchData(currentPage.toString(),'',false);
  }

  Future<void> fetchData(String page,String arama,bool showprogress) async {

    isLoadingNotifier.value = true;
    if(showprogress)
      showProgressLoading(context);
    notifyListeners();
    final jsonResponse = await arsivgetir(salonid,musteriid, page.toString(),arama,durum,cevapladi,cevapladi2 );

    List<dynamic> data = jsonResponse['data'];
    arsiv = data.map<Arsiv>((json) => Arsiv.fromJson(json)).toList();
    if(_paginatedRows.length>0)
      _paginatedRows = [];

    arsiv.forEach((e) {


      ++totalRows;

      _paginatedRows.add(
          DataGridRow(cells: [
            DataGridCell<Arsiv>(columnName: 'arsiv',value: e),
            DataGridCell<String>(columnName: 'id', value: e.id),
            DataGridCell<String>(columnName: 'tarih', value: formatDateTime(e.tarih_saat) ),
            DataGridCell<String>(columnName: 'musteridanisan', value: e.musteridanisan["name"]),
            DataGridCell<String>(columnName: 'formadi', value: e.form["form_adi"]== 'Harici' ? e.sozlesme_adi : e.form["form_adi"]),
            DataGridCell<String>(columnName: 'durum', value: e.durum.toString()),
            DataGridCell<String>(columnName: 'cevaplandi', value: e.cevapladi.toString()),
            DataGridCell<String>(columnName: 'cevaplandi2', value: e.cevapladi2.toString()),


          ])
      );

    });


    totalPages = jsonResponse['last_page'];
    currentPage = jsonResponse['current_page'];
    isLoadingNotifier.value = false;
    if(showprogress)
      Navigator.of(context, rootNavigator: true).pop();// Notify listeners that loading has finished
    notifyListeners();



  }

  void search(String musteridanisanadi)
  {
    currentPage = 1;
    arama = musteridanisanadi;
    fetchData("1",musteridanisanadi,false);
  }
  void setPage(int page) {
    if (page > 0 && page <= totalPages) {
      currentPage = page;

      fetchData(currentPage.toString(),"",true);
    }
  }



  @override
  List<DataGridRow> get rows => _paginatedRows;


  @override
  DataGridRowAdapter buildRow(DataGridRow row) {

    return DataGridRowAdapter(cells: [


      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[0].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[1].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[2].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[3].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[4].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[5].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[6].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[7].value.toString()),
      ),
      Container(
        padding: EdgeInsets.only(top:10.0,bottom: 10.0),
        height: 20,
        child:  ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: getStatusColorArsiv(row.getCells()[5].value.toString(),row.getCells()[6].value.toString(),row.getCells()[7].value.toString())?.color,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
            minimumSize: Size(100, 20),
          ),
          child: Text(
            getStatusColorArsiv(row.getCells()[5].value.toString(),row.getCells()[6].value.toString(),row.getCells()[7].value.toString()).text,
            style: TextStyle(color: Colors.white,fontSize: 10),
          ),
        ),
      ),
      Container(
          alignment: Alignment.center,
          child:PopupMenuButton<String>(
            onSelected: (String value) {

              if(value=='formbilgi')
              {
                ArsivDetayGosterDialog(context,row.getCells()[0].value );

              }
              if(value=='formiptal')
              {

                formiptal(row.getCells()[1].value);

              }
              if(value=='formgonder')
              {
                formgonder(context,row.getCells()[1].value);

              }
              if(value=='formonayla')
              {
                formonayla(context,row.getCells()[1].value);

              }
              if(value=='formindir')
              {
                String dosya = row.getCells()[0].value.uzanti;
                String dosyaReplaced = dosya.replaceAll('public/formlar/', '');
                dosyaIndir( 'https://app.randevumcepte.com.tr/'+dosya,dosyaReplaced ,context);


              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'formbilgi',
                child: Text('Bilgi'),
              ),

              PopupMenuItem<String>(
                value: 'formindir',
                child: Text('İndir'),
              ),

              if(row.getCells()[5].value.toString() != "1" && getStatusColorArsiv(row.getCells()[5].value.toString(),row.getCells()[6].value.toString(),row.getCells()[7].value.toString()).text!= "Harici Belge")
                PopupMenuItem<String>(
                  value: 'formgonder',
                  child: Text('Formu Gönder'),
                ),
              if(row.getCells()[5].value.toString() != "1" && getStatusColorArsiv(row.getCells()[5].value.toString(),row.getCells()[6].value.toString(),row.getCells()[7].value.toString()).text!= "Harici Belge")
                PopupMenuItem<String>(
                  value: 'formonayla',
                  child: Text('Onayla'),
                ),
              if(row.getCells()[5].value.toString() != "0")
                PopupMenuItem<String>(
                  value: 'formiptal',
                  child: Text('İptal Et'),
                ),
            ],
          )
      )


    ]);
  }
  void formiptal(String arsivid) async{
    showProgressLoading(context);
    Map<String, dynamic> formData = {

      'id':arsivid,

    };
    final response = await http.post(
      Uri.parse('https://app.randevumcepte.com.tr/api/v1/arsiviptal'),

      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(formData),
    );


    if (response.statusCode == 200) {
      Navigator.of(context,rootNavigator: true).pop();
      fetchData(currentPage.toString(), arama, false);


    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Form iptal edilirken bir hata oluştu! Hata kodu : '+response.statusCode.toString()),
        ),
      );
      debugPrint(response.body);


    }
  }
  void formgonder(BuildContext context ,String arsivid) async{
    showProgressLoading(context);
    Map<String, dynamic> formData = {

      'id':arsivid,

    };
    final response = await http.post(
      Uri.parse('https://app.randevumcepte.com.tr/api/v1/formgonder'),

      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(formData),
    );


    if (response.statusCode == 200) {
      Navigator.of(context,rootNavigator: true).pop();
      fetchData(currentPage.toString(), arama, false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Form tekrar gönderildi. '),
        ),
      );



    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Form gönderirken edilirken bir hata oluştu! Hata kodu : '+response.statusCode.toString()),
        ),
      );
      debugPrint(response.body);


    }
  }
  void formonayla(BuildContext context ,String arsivid) async{
    showProgressLoading(context);
    Map<String, dynamic> formData = {

      'id':arsivid,

    };
    final response = await http.post(
      Uri.parse('https://app.randevumcepte.com.tr/api/v1/arsivonayla'),

      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(formData),
    );


    if (response.statusCode == 200) {
      Navigator.of(context,rootNavigator: true).pop();
      fetchData(currentPage.toString(), arama, false);


    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Form gönderirken edilirken bir hata oluştu! Hata kodu : '+response.statusCode.toString()),
        ),
      );
      debugPrint(response.body);


    }
  }
  void showDetailsDialog(BuildContext context, Arsiv arsiv){
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
                        Text('Anıl Orbey',
                          style: TextStyle(fontWeight: FontWeight.bold),),
                        Divider(color: Colors.black,
                          height: 10,),
                        Row(
                          children: [
                            Text('Tarih'),
                            SizedBox(width: 14,),
                            Text(': '),
                            Expanded(child: Text('11.10.2023'))
                          ],

                        ),
                        Row(
                          children: [
                            Text('Başlık'), SizedBox(width: 7,),
                            Text(':'),
                            Text(' Beyazlatıcı Krem')
                          ],
                        ),
                        Row(
                          children: [
                            Text('Durum'),
                            SizedBox(width: 2,),
                            Text(': '),
                            Expanded(child: Text('Onaylandı'))
                          ],

                        ),


                        Divider(color: Colors.black,
                          height: 20,),
                        SizedBox(height: 10,),
                        Row(
                          children: [
                            SizedBox(width: 5,),
                            ElevatedButton(onPressed: () {

                            }, child:
                            Text('Formu Tekrar Gönder'),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple[800],
                                  foregroundColor: Colors.white,
                                  elevation: 5,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5.0)
                                  ),
                                  minimumSize: Size(110, 30)
                              ),
                            ),
                            SizedBox(width: 10,),
                            ElevatedButton(onPressed: () {

                            }, child:
                            Text('İndir', style: TextStyle(color: Colors.black)),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.yellow[600],
                                  elevation: 5,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5.0)
                                  ),
                                  minimumSize: Size(90, 30)
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
        }
    );
  }




}

class RandevuDataSource extends DataGridSource {
  List<DataGridRow> _paginatedRows = [];
  var tryformat = NumberFormat.currency(locale: 'tr_TR',symbol: "");
  int rowsPerPage;
  int currentPage;

  int totalPages = 1;
  int totalRows;
  String salonid;
  String tarih;
  String durum;
  String cihazid;
  String personelid;
  String musteriid;
  bool musteriMi;
  int kullanicirolu;
  dynamic isletmebilgi;
  BuildContext context;
  List<Randevu> randevu = [];
  List<DataGridRow> randevuRows = [];
  ValueNotifier<bool> isLoadingNotifier = ValueNotifier(false);
  String olusturma;
  RandevuDataSource({
    required this.rowsPerPage,
    required this.kullanicirolu,
    required this.context,
    required this.salonid,
    required this.musteriid,
    required this.tarih,
    required this.durum,
    required this.olusturma,
    required this.isletmebilgi,
    required this.personelid,
    required this.cihazid,
    required this.musteriMi,

  }) : currentPage = 1, totalRows = 0 {
    fetchData(currentPage.toString(),'',olusturma,durum,tarih,personelid,cihazid);

  }

  Future<void> fetchData(String page,String musteridanisanadi,String olusturma_filter, String durum_filter, String tarih_filter,String personelid, String cihazid) async {

    if(musteridanisanadi.length>=3 || musteridanisanadi.length==0)
      showProgressLoading(context);
    isLoadingNotifier.value = true;

    notifyListeners();
    log(' id '+salonid);
    final jsonResponse = await randevularigetir(musteriid,salonid, olusturma_filter, durum_filter, tarih_filter, page.toString(),musteridanisanadi,personelid, cihazid,musteriMi);

    List<dynamic> data = jsonResponse['data'];
    randevu = data.map<Randevu>((json) => Randevu.fromJson(json)).toList();
    _paginatedRows = randevu.map<DataGridRow>((e) {
      String randevuHizmetler = '';

      e.hizmetler.forEach((element){
        randevuHizmetler += element["hizmetler"]["hizmet_adi"].toString()+ ", ";
      });
      return DataGridRow(cells: [
        DataGridCell<Randevu>(columnName: 'randevu',value: e),
        DataGridCell<String>(columnName: 'id', value: e.id),
        DataGridCell<String>(columnName: 'tarih', value: e.tarih),

        musteriMi ? DataGridCell<String>(columnName: 'hizmetler', value: randevuHizmetler) : DataGridCell<String>(columnName: 'musteridanisan', value: e.musteriname) ,

        DataGridCell<String>(columnName: 'durum', value: e.durum.toString()),
        DataGridCell<String>(columnName: 'geldi', value: e.geldimi.toString()),
      ]);
    }).toList();

    totalPages = jsonResponse['last_page'];
    log("total pages 2 : "+totalPages.toString());
    currentPage = jsonResponse['current_page'];
    totalRows = randevu.length;
    isLoadingNotifier.value = false;
    if(musteridanisanadi.length>=3 || musteridanisanadi.length==0)
      Navigator.of(context,rootNavigator: true).pop();
    notifyListeners();



  }

  void search(String musteridanisanadi,String durumfilter, String olusturmafilter, String tarihfilter)
  {
    currentPage = 1;
    fetchData("1",musteridanisanadi,olusturmafilter,durumfilter,tarihfilter,personelid,cihazid);
  }
  void setPage(int page,String durumfilter, String olusturmafilter,String tarihfilter) {
    if (page > 0 && page <= totalPages) {
      currentPage = page;
      fetchData(currentPage.toString(),"",olusturmafilter,durumfilter,tarihfilter,personelid,cihazid);
    }
  }

  @override
  List<DataGridRow> get rows => _paginatedRows;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    List<Widget> cellwidget = row.getCells().map<Widget>((cell) {
      return Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(5.0),
        child: Text(cell.value.toString(),style: TextStyle(fontSize: 12),),
      );
    }).toList();

    cellwidget.add(
      Container(
        padding: EdgeInsets.only(top:10.0,bottom: 10.0),
        height: 20,
        child:  ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: getStatusColorRandevu(row.getCells()[4].value.toString(),row.getCells()[5].value.toString())?.color,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
            minimumSize: Size(100, 20),
          ),
          child: Text(
            getStatusColorRandevu(row.getCells()[4].value.toString(),row.getCells()[5].value.toString()).text,
            style: TextStyle(color: Colors.white,fontSize: 10),
          ),
        ),
      ),

    );
    cellwidget.add(Container(
        alignment: Alignment.center,
        child:PopupMenuButton<String> (
            onSelected: (String value) async{
              Randevu secilirandevu = row.getCells()[0].value;
              if(value=='detaylibilgi')
              {
                randevudetayi(context,row.getCells()[0].value,musteriMi);
              }
              if(value=="randevuduzenle")
                Navigator.push(context, new MaterialPageRoute(builder: (context) => RandevuDuzenle(isletmebilgi: isletmebilgi, randevu: row.getCells()[0].value,)));

              if(value=="randevuiptalet")
                showDialog<bool>(
                  context: context,
                  builder: (dialogcontext) {
                    return AlertDialog(
                      title: Text('EMİN MİSİNİZ?'),
                      content: Text("Randevu iptal etme işlemi geri alınamaz?"),
                      actions: <Widget>[
                        TextButton(
                          child: Text('VAZGEÇ'),
                          onPressed: () {
                            Navigator.of(dialogcontext).pop();
                          },
                        ),
                        TextButton(
                          child: Text('İPTAL ET'),
                          onPressed: () async {
                            SharedPreferences prefs = await SharedPreferences.getInstance();
                            var usertype = prefs.getString('user_type');
                            randevuiptalet(row.getCells()[1].value.toString(), dialogcontext,usertype!);
                            Navigator.of(dialogcontext).pop();

                            await fetchData(currentPage.toString(),'',olusturma,durum,tarih,personelid,cihazid);
                            //getUpdatedAppointments();
                          },
                        ),
                      ],
                    );
                  },
                );
              if(value=="randevuyageldi") {
                await randevugeldiisaretle(row.getCells()[1].value, '', context,'');
                await fetchData(currentPage.toString(),'',olusturma,durum,tarih,personelid,cihazid);
              }
              if(value=="randevuyagelmedi"){
                randevugelmediisaretle(row.getCells()[1].value, context);
                await fetchData(currentPage.toString(),'',olusturma,durum,tarih,personelid,cihazid);
              }
              if(value=="randevuonayla"){

                randevuonayla(row.getCells()[1].value, context);
                await fetchData(currentPage.toString(),'',olusturma,durum,tarih,personelid,cihazid);
              }

            },

            itemBuilder: (BuildContext context) {
              log('Müşteri mi ? '+musteriMi.toString());
              List<PopupMenuEntry<String>> menuItems = [];
              Randevu rndv = row.getCells()[0].value;
              menuItems.add(
                PopupMenuItem<String>(
                  value: 'detaylibilgi',
                  child: Text('Detaylı Bilgi'),
                ),
              );
              if(row.getCells()[4].value.toString() == "0" && !musteriMi && kullanicirolu != 5)
                menuItems.add(
                  PopupMenuItem<String>(
                    value: 'randevuonayla',
                    child: Text('Onayla'),
                  ),
                );
              if(row.getCells()[4].value.toString() != "2" && row.getCells()[4].value.toString() != "3" )
              {
                if(rndv.tahsilat_eklendi != "1" && kullanicirolu != 5)
                  menuItems.add(
                    PopupMenuItem<String>(
                      value: 'randevuiptalet',
                      child: Text('İptal Et'),
                    ),
                  );
                /*if(!musteriMi)
                  menuItems.add(
                    PopupMenuItem<String>(
                      value: 'randevuduzenle',
                      child: Text('Düzenle'),
                    ),
                  );*/
                if(row.getCells()[4].value.toString() != "0" && !musteriMi && kullanicirolu !=5)
                {
                  menuItems.add(
                    PopupMenuItem<String>(
                      value: 'randevuyageldi',
                      child: Text('Geldi'),
                    ),
                  );
                  menuItems.add(
                    PopupMenuItem<String>(
                      value: 'randevuyagelmedi',
                      child: Text('Gelmedi'),
                    ),
                  );

                }

              }




              return menuItems;
            }
        )
    ));
    return DataGridRowAdapter(cells: cellwidget);

  }
  void updateRandevuDataSource(List<Randevu> newRandevu) {
    randevuRows = newRandevu
        .map<DataGridRow>((e) =>
        DataGridRow(cells: [
          DataGridCell<Randevu>(columnName: 'randevu', value: e),
          DataGridCell<String>(columnName: 'id', value: e.id),
          DataGridCell<String>(columnName: 'tarih', value: e.tarih),
          DataGridCell<String>(
              columnName: 'musteridanisan', value: e.musteriname),

          DataGridCell<String>(columnName: 'durum', value: e.durum.toString()),
          DataGridCell<String>(
              columnName: 'geldi', value: e.geldimi.toString()),

        ]))
        .toList();

    notifyListeners();
  }
  void randevudetayi(BuildContext context, Randevu randevudetay,bool musteri) {
    String geldigelmedi = "";
    String personelnot = "";
    String musterinot = "";
    String durumstr = "";
    if(randevudetay.geldimi=="1")
      geldigelmedi = "Geldi";
    else
      geldigelmedi = "Gelmedi";
    if(randevudetay.musterinotu=="null")
      musterinot = "";
    if(randevudetay.personelnotu=="null")
      personelnot = "";

    if(randevudetay.durum == "0")
      durumstr = "Onay bekliyor";

    if(randevudetay.durum == "1")
      durumstr = "Onaylı ";
    if(randevudetay.durum == "2")
      durumstr = "İptal edildi/reddedildi ";
    if(randevudetay.durum == "3")
      durumstr = "Müşteri/danışan iptal etti ";
    String hizmetlerStr = "";
    randevudetay.hizmetler.forEach((element){

      hizmetlerStr += element["hizmetler"]["hizmet_adi"].toString()+ ", ";
    });

    String icerik = "Durum : "+durumstr +
        (!musteri  ? "\n" +"Telefon : "+  randevudetay.musteri["cep_telefon"] : '') +
        "\n" +"Hizmet(-ler) : "+hizmetlerStr+
        "\n" +"Tarih & Saat : "+randevudetay.tarih+
        "\n" +"Oluşturan : "+randevudetay.olusturan["name"]+
        "\n" +"Geldi mi? : "+geldigelmedi+
        "\n" +"Müşteri Notu : "+musterinot+
        "\n" +"Personel Notu : "+personelnot;

    final _formKey = GlobalKey<FormState>();
    List<String> randevutitle = randevudetay.musteriname.split('\n');
    List<String>? randevudurum = randevudetay.durum.split('-');


    showDialog(
      context: context,

      builder: (BuildContext context) {
        return AlertDialog(
            insetPadding: EdgeInsets.zero,
            content: Container(
              width: MediaQuery.of(context).size.width * 0.75,
              child:SingleChildScrollView(

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
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          SizedBox(height: 20,),
                          Text(
                            randevutitle[0] + " Randevu Detayları",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Divider(color: Colors.black, height: 10,),
                          Row(
                            children: [

                              Expanded(child: Text(icerik
                              )),
                              /*Expanded(child: Text("Hizmet(-ler) : "+randevudetay.hizmetler ?? ""+ "\n")),
                          Expanded(child: Text("Zaman : "+randevudetay.tarih ?? ""+ "\n")),
                          Expanded(child: Text("Oluşturan : "+randevudetay.olusturan ?? ""+ "\n")),
                          Expanded(child: Text("Geldi mi? : "+randevudetay.geldimi == "1" ?+ "\n")),*/
                            ],
                          ),

                          randevudurum![0] == "0" || randevudurum![0] == "1" ? Divider(color: Colors.black,
                            height: 30,): SizedBox.shrink(),
                          (randevudurum![0] == "0" || randevudurum![0] == "1") && !musteri ? Row(
                            children: [
                              ElevatedButton(onPressed: () {

                                Navigator.push(context, new MaterialPageRoute(builder: (context) => RandevuDuzenle(isletmebilgi: isletmebilgi, randevu: randevudetay,)));

                              }, child:
                              Text('Düzenle'),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor:  Color(0xFF5E35B1),
                                    foregroundColor: Colors.white,
                                    elevation: 5,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(5.0)
                                    ),
                                    minimumSize: Size(275, 30)
                                ),
                              )
                            ],
                          ) : SizedBox.shrink(),
                          (randevudurum![0] == "0" || randevudurum![0] == "1")&& !musteri && kullanicirolu!=5 ? Row(

                            children: [
                              randevudurum![0] == "0" ?
                              ElevatedButton(onPressed: () {}, child:
                              Text('Onayla'),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    elevation: 5,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(5.0)
                                    ),
                                    minimumSize: Size(130, 30)
                                ),
                              ):SizedBox.shrink(),
                              randevudurum![0] == "0" ?
                              SizedBox(width: 15,):SizedBox.shrink(),
                              randevudurum![0] == "0"  ?
                              ElevatedButton(onPressed: () {
                                showDialog<bool>(
                                  context: context,
                                  builder: (dialogContex) {
                                    return AlertDialog(
                                      title: Text('EMİN MİSİNİZ?'),
                                      content: Text("Randevu iptal etme işlemi geri alınamaz?"),
                                      actions: <Widget>[
                                        TextButton(
                                          child: Text('VAZGEÇ'),
                                          onPressed: () {
                                            Navigator.of(dialogContex).pop();
                                          },
                                        ),
                                        TextButton(
                                          child: Text('GÖNDER'),
                                          onPressed: () async {
                                            Navigator.of(context, rootNavigator: true).pop();
                                            SharedPreferences prefs = await SharedPreferences.getInstance();
                                            var usertype = prefs.getString('user_type');
                                            randevuiptalet(randevudetay.id.toString(), context,usertype!);
                                            Navigator.of(context, rootNavigator: true).pop();
                                            await fetchData(currentPage.toString(),'',olusturma,durum,tarih,personelid,cihazid);
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                );




                              }, child:
                              Text('İptal Et'),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    foregroundColor: Colors.white,
                                    elevation: 5,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(5.0)
                                    ),
                                    minimumSize: Size(130, 30)
                                ),
                              ) : SizedBox.shrink(),
                              randevudurum![0] != "0" ?
                              ElevatedButton(onPressed: () async {
                                randevugelmediisaretle(randevudetay.id.toString(), context);
                                Navigator.of(context, rootNavigator: true).pop();
                                await fetchData(currentPage.toString(),'',olusturma,durum,tarih,personelid,cihazid);


                              }, child:
                              Text('Gelmedi'),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red[600],
                                    foregroundColor: Colors.white,
                                    elevation: 5,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(5.0)
                                    ),
                                    minimumSize: Size(130, 30)
                                ),
                              ):SizedBox.shrink(),
                              SizedBox(width: 15,),
                              randevudurum![0] != "0" ?
                              ElevatedButton(onPressed: ()  async {
                                randevugeldiisaretle(randevudetay.id.toString(),'', context,'');
                                //getUpdatedAppointments();
                                Navigator.of(context, rootNavigator: true).pop();
                                await fetchData(currentPage.toString(),'',olusturma,durum,tarih,personelid,cihazid);


                              }, child:
                              Text('Geldi'),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    elevation: 5,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(5.0)
                                    ),
                                    minimumSize: Size(130, 30)
                                ),
                              ):SizedBox.shrink(),

                            ],
                          ):SizedBox.shrink(),
                          randevudurum![0] != "0" && !musteri && kullanicirolu != 5   ? Row(
                            children: [
                              if(randevudetay.tahsilat_eklendi != "1")
                                ElevatedButton(onPressed: () async {
                                  log(isletmebilgi.toString());
                                  log(randevudetay.user_id.toString());
                                  dynamic randevutahsilatsonuc = await randevudantahsilatagit(context,randevudetay.id.toString());

                                  if(randevutahsilatsonuc==true){

                                    Navigator.of(context).pop();
                                    Navigator.push(context, new MaterialPageRoute(builder: (context) => TahsilatEkrani(adisyonId: "", kullanicirolu: kullanicirolu, isletmebilgi: isletmebilgi, musteridanisanid:randevudetay.user_id)));
                                  }


                                }, child:
                                Text('Tahsilat'),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFF5E35B1),
                                      foregroundColor: Colors.white,
                                      elevation: 5,
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(5.0)
                                      ),
                                      minimumSize: Size(130, 30)
                                  ),
                                )
                              ,
                              SizedBox(width: 15,),
                              if(randevudetay.tahsilat_eklendi != "1")
                                ElevatedButton(onPressed: () {
                                  showDialog<bool>(
                                    context: context,
                                    builder: (dialogContex) {
                                      return AlertDialog(
                                        title: Text('EMİN MİSİNİZ?'),
                                        content: Text("Randevu iptal etme işlemi geri alınamaz?"),
                                        actions: <Widget>[
                                          TextButton(
                                            child: Text('VAZGEÇ'),
                                            onPressed: () {
                                              Navigator.of(dialogContex).pop();
                                            },
                                          ),
                                          TextButton(
                                            child: Text('GÖNDER'),
                                            onPressed: () async {
                                              Navigator.of(context, rootNavigator: true).pop();
                                              SharedPreferences prefs = await SharedPreferences.getInstance();
                                              var usertype = prefs.getString('user_type');
                                              randevuiptalet(randevudetay.id.toString(), context,usertype!);
                                              Navigator.of(context, rootNavigator: true).pop();
                                              await fetchData(currentPage.toString(),'',olusturma,durum,tarih,personelid,cihazid);
                                              //getUpdatedAppointments();
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  );




                                }, child:
                                Text('İptal Et'),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black,
                                      foregroundColor: Colors.white,
                                      elevation: 5,
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(5.0)
                                      ),
                                      minimumSize: Size(130, 30)
                                  ),
                                )

                            ],
                          ) : SizedBox.shrink(),

                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )

        );
      },
    );
  }
}
class RandevuDataSource2 extends DataGridSource {
  List<DataGridRow> _paginatedRows = [];

  int rowsPerPage;
  int currentPage;

  int totalPages = 1;
  int totalRows;
  String salonid;


  BuildContext context;
  List<Randevu> randevu = [];
  List<DataGridRow> randevuRows = [];
  ValueNotifier<bool> isLoadingNotifier = ValueNotifier(false);

  RandevuDataSource2({
    required this.rowsPerPage,

    required this.context,
    required this.salonid,


  }) : currentPage = 1, totalRows = 0 {
    randevutum(currentPage.toString(),'');

  }

  Future<void> randevutum(String page,String musteridanisanadi) async {
    isLoadingNotifier.value = true;
    musteridanisanadi == '' ? showProgressLoading(context) : null;
    notifyListeners();
    final jsonResponse = await randevucek(salonid,page.toString(),musteridanisanadi);
    List<dynamic> data = jsonResponse['data'];
    randevu = data.map<Randevu>((json) => Randevu.fromJson(json)).toList();
    _paginatedRows = randevu.map<DataGridRow>((e) {
      return DataGridRow(cells: [
        DataGridCell<Randevu>(columnName: 'randevu',value: e),
        DataGridCell<String>(columnName: 'id', value: e.id),
        DataGridCell<String>(columnName: 'tarih', value: e.tarih),
        DataGridCell<String>(columnName: 'musteridanisan', value: e.musteriname),

        DataGridCell<String>(columnName: 'durum', value: e.durum.toString()),
        DataGridCell<String>(columnName: 'geldi', value: e.geldimi.toString()),
      ]);
    }).toList();

    totalPages = jsonResponse['last_page'];

    currentPage = jsonResponse['current_page'];
    totalRows = randevu.length;
    isLoadingNotifier.value = false;
    musteridanisanadi == '' ? Navigator.of(context, rootNavigator: true).pop() : null;// Notify listeners that loading has finished
    notifyListeners();



  }

  void search(String musteridanisanadi)
  {
    currentPage = 1;
    randevutum("1",musteridanisanadi);
  }
  void setPage(int page) {
    if (page > 0 && page <= totalPages) {
      currentPage = page;
      randevutum(currentPage.toString(),"");
    }
  }

  @override
  List<DataGridRow> get rows => _paginatedRows;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    List<Widget> cellwidget = row.getCells().map<Widget>((cell) {
      return Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(5.0),
        child: Text(cell.value.toString(),style: TextStyle(fontSize: 12),),
      );
    }).toList();

    cellwidget.add(
      Container(
        padding: EdgeInsets.only(top:10.0,bottom: 10.0),
        height: 20,
        child:  ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: getStatusColorRandevu(row.getCells()[4].value.toString(),row.getCells()[5].value.toString())?.color,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
            minimumSize: Size(100, 20),
          ),
          child: Text(
            getStatusColorRandevu(row.getCells()[4].value.toString(),row.getCells()[5].value.toString()).text,
            style: TextStyle(color: Colors.white,fontSize: 10),
          ),
        ),
      ),

    );
    cellwidget.add(Container(
        alignment: Alignment.center,
        child:PopupMenuButton<String>(
          onSelected: (String value) {


          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: 'formindir',
              child: Text('İndir'),
            ),
            PopupMenuItem<String>(
              value: 'formyazdir',
              child: Text('Yazdır'),
            ),
            PopupMenuItem<String>(
              value: 'formgonder',
              child: Text('Formu Gönder'),
            ),
            PopupMenuItem<String>(
              value: 'formonayla',
              child: Text('Onayla'),
            ),
            PopupMenuItem<String>(
              value: 'formiptal',
              child: Text('İptal Et'),
            ),
          ],
        )
    ));
    return DataGridRowAdapter(cells: cellwidget);

  }
  void updateRandevuDataSource(List<Randevu> newRandevu) {
    randevuRows = newRandevu
        .map<DataGridRow>((e) =>
        DataGridRow(cells: [
          DataGridCell<Randevu>(columnName: 'randevu', value: e),
          DataGridCell<String>(columnName: 'id', value: e.id),
          DataGridCell<String>(columnName: 'tarih', value: e.tarih),
          DataGridCell<String>(
              columnName: 'musteridanisan', value: e.musteriname),

          DataGridCell<String>(columnName: 'durum', value: e.durum.toString()),
          DataGridCell<String>(
              columnName: 'geldi', value: e.geldimi.toString()),

        ]))
        .toList();

    notifyListeners();
  }
}

class RandevuDataSource3 extends DataGridSource {
  List<DataGridRow> _paginatedRows = [];

  int rowsPerPage;
  int currentPage;

  int totalPages = 1;
  int totalRows;
  String salonid;


  BuildContext context;
  List<Randevu> randevu = [];
  List<DataGridRow> randevuRows = [];
  ValueNotifier<bool> isLoadingNotifier = ValueNotifier(false);

  RandevuDataSource3({
    required this.rowsPerPage,

    required this.context,
    required this.salonid,


  }) : currentPage = 1, totalRows = 0 {
    randevusalon(currentPage.toString(),'');

  }

  Future<void> randevusalon(String page,String musteridanisanadi) async {
    isLoadingNotifier.value = true;
    musteridanisanadi == '' ? showProgressLoading(context) : null;
    notifyListeners();
    final jsonResponse = await randevucek(salonid,page.toString(),musteridanisanadi);
    List<dynamic> data = jsonResponse['data'];
    randevu = data.map<Randevu>((json) => Randevu.fromJson(json)).toList();
    _paginatedRows = randevu.map<DataGridRow>((e) {
      return DataGridRow(cells: [
        DataGridCell<Randevu>(columnName: 'randevu',value: e),
        DataGridCell<String>(columnName: 'id', value: e.id),
        DataGridCell<String>(columnName: 'tarih', value: e.tarih),
        DataGridCell<String>(columnName: 'musteridanisan', value: e.musteriname),

        DataGridCell<String>(columnName: 'durum', value: e.durum.toString()),
        DataGridCell<String>(columnName: 'geldi', value: e.geldimi.toString()),
      ]);
    }).toList();

    totalPages = jsonResponse['last_page'];

    currentPage = jsonResponse['current_page'];
    totalRows = randevu.length;
    isLoadingNotifier.value = false;
    musteridanisanadi == '' ? Navigator.of(context, rootNavigator: true).pop() : null;// Notify listeners that loading has finished
    notifyListeners();



  }

  void search(String musteridanisanadi)
  {
    currentPage = 1;
    randevusalon("1",musteridanisanadi);
  }
  void setPage(int page) {
    if (page > 0 && page <= totalPages) {
      currentPage = page;
      randevusalon(currentPage.toString(),"");
    }
  }

  @override
  List<DataGridRow> get rows => _paginatedRows;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    List<Widget> cellwidget = row.getCells().map<Widget>((cell) {
      return Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(5.0),
        child: Text(cell.value.toString(),style: TextStyle(fontSize: 12),),
      );
    }).toList();

    cellwidget.add(
      Container(
        padding: EdgeInsets.only(top:10.0,bottom: 10.0),
        height: 20,
        child:  ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: getStatusColorRandevu(row.getCells()[4].value.toString(),row.getCells()[5].value.toString())?.color,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
            minimumSize: Size(100, 20),
          ),
          child: Text(
            getStatusColorRandevu(row.getCells()[4].value.toString(),row.getCells()[5].value.toString()).text,
            style: TextStyle(color: Colors.white,fontSize: 10),
          ),
        ),
      ),

    );
    cellwidget.add(Container(
        alignment: Alignment.center,
        child:PopupMenuButton<String>(
            onSelected: (String value) {


            },
            itemBuilder: (BuildContext context) {
              List<PopupMenuEntry<String>> menuItems = [];
              if(row.getCells()[4].value.toString() == "0")
                menuItems.add(
                  PopupMenuItem<String>(
                    value: 'randevuonayla',
                    child: Text('Onayla'),
                  ),
                );
              if(row.getCells()[4].value.toString() != "2" || row.getCells()[4].value.toString() != "3")
              {
                menuItems.add(
                  PopupMenuItem<String>(
                    value: 'randevuiptalet',
                    child: Text('İptal Et'),
                  ),
                );
                menuItems.add(
                  PopupMenuItem<String>(
                    value: 'randevuduzenle',
                    child: Text('Düzenle'),
                  ),
                );
                menuItems.add(
                  PopupMenuItem<String>(
                    value: 'randevuyageldi',
                    child: Text('Geldi'),
                  ),
                );
                menuItems.add(
                  PopupMenuItem<String>(
                    value: 'randevuyageldi',
                    child: Text('Gelmedi'),
                  ),
                );
              }




              return menuItems;
            }



        )
    ));
    return DataGridRowAdapter(cells: cellwidget);

  }
  void updateRandevuDataSource(List<Randevu> newRandevu) {
    randevuRows = newRandevu
        .map<DataGridRow>((e) =>
        DataGridRow(cells: [
          DataGridCell<Randevu>(columnName: 'randevu', value: e),
          DataGridCell<String>(columnName: 'id', value: e.id),
          DataGridCell<String>(columnName: 'tarih', value: e.tarih),
          DataGridCell<String>(
              columnName: 'musteridanisan', value: e.musteriname),

          DataGridCell<String>(columnName: 'durum', value: e.durum.toString()),
          DataGridCell<String>(
              columnName: 'geldi', value: e.geldimi.toString()),

        ]))
        .toList();

    notifyListeners();
  }
}
class RandevuDataSource4 extends DataGridSource {
  List<DataGridRow> _paginatedRows = [];

  int rowsPerPage;
  int currentPage;

  int totalPages = 1;
  int totalRows;
  String salonid;


  BuildContext context;
  List<Randevu> randevu = [];
  List<DataGridRow> randevuRows = [];
  ValueNotifier<bool> isLoadingNotifier = ValueNotifier(false);

  RandevuDataSource4({
    required this.rowsPerPage,

    required this.context,
    required this.salonid,


  }) : currentPage = 1, totalRows = 0 {
    randevuapp(currentPage.toString(),'');

  }

  Future<void> randevuapp(String page,String musteridanisanadi) async {
    isLoadingNotifier.value = true;
    musteridanisanadi == '' ? showProgressLoading(context) : null;
    notifyListeners();
    final jsonResponse = await randevucekuygulama(salonid,page.toString(),musteridanisanadi);
    List<dynamic> data = jsonResponse['data'];
    randevu = data.map<Randevu>((json) => Randevu.fromJson(json)).toList();
    _paginatedRows = randevu.map<DataGridRow>((e) {
      return DataGridRow(cells: [
        DataGridCell<Randevu>(columnName: 'randevu',value: e),
        DataGridCell<String>(columnName: 'id', value: e.id),
        DataGridCell<String>(columnName: 'tarih', value: e.tarih),
        DataGridCell<String>(columnName: 'musteridanisan', value: e.musteriname),

        DataGridCell<String>(columnName: 'durum', value: e.durum.toString()),
        DataGridCell<String>(columnName: 'geldi', value: e.geldimi.toString()),
      ]);
    }).toList();

    totalPages = jsonResponse['last_page'];

    currentPage = jsonResponse['current_page'];
    totalRows = randevu.length;
    isLoadingNotifier.value = false;
    musteridanisanadi == '' ? Navigator.of(context, rootNavigator: true).pop() : null;// Notify listeners that loading has finished
    notifyListeners();



  }

  void search(String musteridanisanadi)
  {
    currentPage = 1;
    randevuapp("1",musteridanisanadi);
  }
  void setPage(int page) {
    if (page > 0 && page <= totalPages) {
      currentPage = page;
      randevuapp(currentPage.toString(),"");
    }
  }

  @override
  List<DataGridRow> get rows => _paginatedRows;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    List<Widget> cellwidget = row.getCells().map<Widget>((cell) {
      return Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(5.0),
        child: Text(cell.value.toString(),style: TextStyle(fontSize: 12),),
      );
    }).toList();

    cellwidget.add(
      Container(
        padding: EdgeInsets.only(top:10.0,bottom: 10.0),
        height: 20,
        child:  ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: getStatusColorRandevu(row.getCells()[4].value.toString(),row.getCells()[5].value.toString())?.color,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
            minimumSize: Size(100, 20),
          ),
          child: Text(
            getStatusColorRandevu(row.getCells()[4].value.toString(),row.getCells()[5].value.toString()).text,
            style: TextStyle(color: Colors.white,fontSize: 10),
          ),
        ),
      ),

    );
    cellwidget.add(Container(
        alignment: Alignment.center,
        child:PopupMenuButton<String>(
          onSelected: (String value) {


          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: 'formindir',
              child: Text('İndir'),
            ),
            PopupMenuItem<String>(
              value: 'formyazdir',
              child: Text('Yazdır'),
            ),
            PopupMenuItem<String>(
              value: 'formgonder',
              child: Text('Formu Gönder'),
            ),
            PopupMenuItem<String>(
              value: 'formonayla',
              child: Text('Onayla'),
            ),
            PopupMenuItem<String>(
              value: 'formiptal',
              child: Text('İptal Et'),
            ),
          ],
        )
    ));
    return DataGridRowAdapter(cells: cellwidget);

  }
  void updateRandevuDataSource(List<Randevu> newRandevu) {
    randevuRows = newRandevu
        .map<DataGridRow>((e) =>
        DataGridRow(cells: [
          DataGridCell<Randevu>(columnName: 'randevu', value: e),
          DataGridCell<String>(columnName: 'id', value: e.id),
          DataGridCell<String>(columnName: 'tarih', value: e.tarih),
          DataGridCell<String>(
              columnName: 'musteridanisan', value: e.musteriname),

          DataGridCell<String>(columnName: 'durum', value: e.durum.toString()),
          DataGridCell<String>(
              columnName: 'geldi', value: e.geldimi.toString()),

        ]))
        .toList();

    notifyListeners();
  }
}
class RandevuDataSource5 extends DataGridSource {
  List<DataGridRow> _paginatedRows = [];

  int rowsPerPage;
  int currentPage;

  int totalPages = 1;
  int totalRows;
  String salonid;


  BuildContext context;
  List<Randevu> randevu = [];
  List<DataGridRow> randevuRows = [];
  ValueNotifier<bool> isLoadingNotifier = ValueNotifier(false);

  RandevuDataSource5({
    required this.rowsPerPage,

    required this.context,
    required this.salonid,


  }) : currentPage = 1, totalRows = 0 {
    randevuweb(currentPage.toString(),'');

  }

  Future<void> randevuweb(String page,String musteridanisanadi) async {
    isLoadingNotifier.value = true;
    musteridanisanadi == '' ? showProgressLoading(context) : null;
    notifyListeners();
    final jsonResponse = await randevucekweb(salonid,page.toString(),musteridanisanadi);
    List<dynamic> data = jsonResponse['data'];
    randevu = data.map<Randevu>((json) => Randevu.fromJson(json)).toList();
    _paginatedRows = randevu.map<DataGridRow>((e) {
      return DataGridRow(cells: [
        DataGridCell<Randevu>(columnName: 'randevu',value: e),
        DataGridCell<String>(columnName: 'id', value: e.id),
        DataGridCell<String>(columnName: 'tarih', value: e.tarih),
        DataGridCell<String>(columnName: 'musteridanisan', value: e.musteriname),

        DataGridCell<String>(columnName: 'durum', value: e.durum.toString()),
        DataGridCell<String>(columnName: 'geldi', value: e.geldimi.toString()),
      ]);
    }).toList();

    totalPages = jsonResponse['last_page'];

    currentPage = jsonResponse['current_page'];
    totalRows = randevu.length;
    isLoadingNotifier.value = false;
    musteridanisanadi == '' ? Navigator.of(context, rootNavigator: true).pop() : null;// Notify listeners that loading has finished
    notifyListeners();



  }

  void search(String musteridanisanadi)
  {
    currentPage = 1;
    randevuweb("1",musteridanisanadi);
  }
  void setPage(int page) {
    if (page > 0 && page <= totalPages) {
      currentPage = page;
      randevuweb(currentPage.toString(),"");
    }
  }

  @override
  List<DataGridRow> get rows => _paginatedRows;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    List<Widget> cellwidget = row.getCells().map<Widget>((cell) {
      return Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(5.0),
        child: Text(cell.value.toString(),style: TextStyle(fontSize: 12),),
      );
    }).toList();

    cellwidget.add(
      Container(
        padding: EdgeInsets.only(top:10.0,bottom: 10.0),
        height: 20,
        child:  ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: getStatusColorRandevu(row.getCells()[4].value.toString(),row.getCells()[5].value.toString())?.color,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
            minimumSize: Size(100, 20),
          ),
          child: Text(
            getStatusColorRandevu(row.getCells()[4].value.toString(),row.getCells()[5].value.toString()).text,
            style: TextStyle(color: Colors.white,fontSize: 10),
          ),
        ),
      ),

    );
    cellwidget.add(Container(
        alignment: Alignment.center,
        child:PopupMenuButton<String>(
          onSelected: (String value) {


          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: 'formindir',
              child: Text('İndir'),
            ),
            PopupMenuItem<String>(
              value: 'formyazdir',
              child: Text('Yazdır'),
            ),
            PopupMenuItem<String>(
              value: 'formgonder',
              child: Text('Formu Gönder'),
            ),
            PopupMenuItem<String>(
              value: 'formonayla',
              child: Text('Onayla'),
            ),
            PopupMenuItem<String>(
              value: 'formiptal',
              child: Text('İptal Et'),
            ),
          ],
        )
    ));
    return DataGridRowAdapter(cells: cellwidget);

  }
  void updateRandevuDataSource(List<Randevu> newRandevu) {
    randevuRows = newRandevu
        .map<DataGridRow>((e) =>
        DataGridRow(cells: [
          DataGridCell<Randevu>(columnName: 'randevu', value: e),
          DataGridCell<String>(columnName: 'id', value: e.id),
          DataGridCell<String>(columnName: 'tarih', value: e.tarih),
          DataGridCell<String>(
              columnName: 'musteridanisan', value: e.musteriname),

          DataGridCell<String>(columnName: 'durum', value: e.durum.toString()),
          DataGridCell<String>(
              columnName: 'geldi', value: e.geldimi.toString()),

        ]))
        .toList();

    notifyListeners();
  }
}
class AjandaDataSource extends DataGridSource {
  List<DataGridRow> _paginatedRows = [];
  int rowsPerPage;
  int currentPage;
  int totalPages = 1;
  int totalRows;
  String salonid;
  String baslik;
  BuildContext context;
  List<Ajanda> ajanda = [];
  dynamic isletmebilgi;
  bool _isDisposed = false;
  ValueNotifier<bool> isLoadingNotifier = ValueNotifier(false);

  AjandaDataSource({
    required this.rowsPerPage,
    required this.context,
    required this.salonid,
    required this.isletmebilgi,
    required this.baslik,
  }) : currentPage = 1, totalRows = 0 {
    fetchData(currentPage.toString(), baslik, true);
  }

  void search(String baslik) {
    this.baslik = baslik;
    currentPage = 1;
    fetchData("1", baslik, false);
  }

  Future<void> fetchData(String page, String baslik, bool showprogress) async {
    if (_isDisposed) return;

    if (!_isDisposed) {
      isLoadingNotifier.value = true;
    }

    if (showprogress && !_isDisposed && context.mounted) {
      showProgressLoading(context);
    }

    try {
      final jsonResponse = await ajandagetir(salonid, page.toString(), baslik);

      if (_isDisposed) return;

      List<dynamic> data = jsonResponse['data'];
      ajanda = data.map<Ajanda>((json) => Ajanda.fromJson(json)).toList();

      _paginatedRows.clear();
      totalRows = 0;

      ajanda.forEach((e) {
        ++totalRows;
        _paginatedRows.add(
            DataGridRow(cells: [
              DataGridCell<Ajanda>(columnName: 'ajanda', value: e),
              DataGridCell<String>(columnName: 'id', value: e.id.toString()),
              DataGridCell<String>(columnName: 'tarihsaat', value: formattedDate(e.ajandatarih.toString()) + ' ' + e.ajandasaat.toString()),
              DataGridCell<String>(columnName: 'baslik', value: e.title.toString()),
              DataGridCell<String>(columnName: 'durum', value: e.durum.toString()),
            ])
        );
      });

      totalPages = jsonResponse['last_page'];
      currentPage = jsonResponse['current_page'];

      if (!_isDisposed) {
        isLoadingNotifier.value = false;
        if (showprogress && context.mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }
        notifyListeners();
      }

    } catch (e) {
      if (!_isDisposed) {
        isLoadingNotifier.value = false;
        if (showprogress && context.mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Veriler yüklenirken hata oluştu: $e')),
          );
        }
      }
    }
  }

  void setPage(int page) {
    if (page > 0 && page <= totalPages) {
      currentPage = page;
      fetchData(currentPage.toString(), baslik, true);
    }
  }

  void refreshData() {
    fetchData(currentPage.toString(), baslik, false);
  }

  Future<void> ajandaEkleGuncelle(String id, String baslik, String icerik, String tarih,
      String saat, String hatirlatma_saati, bool hatirlatma,
      BuildContext context) async {

    SharedPreferences localStorage = await SharedPreferences.getInstance();
    var user = jsonDecode(localStorage.getString('user')!);

    Map<String, dynamic> formData = {
      'ajandaid': id,
      'baslik': baslik,
      'icerik': icerik,
      'tarih': tarih,
      'saat': saat,
      'hatirlatma_saati': hatirlatma_saati,
      'hatirlatma': hatirlatma
    };

    print('API Gönderilen Veriler: $formData');

    try {
      final response = await http.post(
        Uri.parse('https://app.randevumcepte.com.tr/api/v1/notekleduzenle/' + salonid.toString() + '/' + user['id'].toString()),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(formData),
      ).timeout(Duration(seconds: 10));

      print('API Yanıt Kodu: ${response.statusCode}');
      print('API Yanıt Body: ${response.body}');

      if (response.statusCode == 200) {
        // API plain text döndürüyor, JSON değil - bu yüzden jsonDecode kullanma
        String responseBody = response.body;

        // Başarılı mesajları kontrol et
        if (responseBody.contains('başarıyla') || responseBody.contains('kaydedildi') || responseBody.contains('success')) {
          // VERİLERİ YENİLE - progress gösterme
          await fetchData(currentPage.toString(), this.baslik, false);

          if (context.mounted) {
            // Başarı mesajını göster
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(id.isEmpty ? 'Notunuz Eklendi' : 'Notunuz Güncellendi'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else {
          // API hata mesajı döndürdü
          throw Exception('API Error: $responseBody');
        }
      } else {
        throw Exception('HTTP Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('API Call Error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bağlantı hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      rethrow;
    }
  }
  ColorAndText getStatusColorAndText(String durum) {
    if (durum != '1' ) {
      return ColorAndText(Colors.red[600]!, 'Okunmadı');

    } else {
      return ColorAndText(Colors.green, 'Okundu');
    }
  }

  @override
  List<DataGridRow> get rows => _paginatedRows;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    final colorAndText = getStatusColorAndText(row.getCells()[4].value.toString());

    return DataGridRowAdapter(cells: [
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[0].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[1].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[2].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[3].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[4].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(3.0),
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AjandaDuzenle(
                  isletmebilgi: isletmebilgi,
                  notdetayi: row.getCells()[0].value,
                  ajandaDataSource: this,
                ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: colorAndText.color,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
            minimumSize: Size(100, 20),
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
          child: Text(
            colorAndText.text,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.normal,
            ),
          ),
        ),
      ),
      Container(
          alignment: Alignment.center,
          child: PopupMenuButton<String>(
            onSelected: (String value) async {
              if (value == 'duzenle') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AjandaDuzenle(
                      isletmebilgi: isletmebilgi,
                      notdetayi: row.getCells()[0].value,
                      ajandaDataSource: this,
                    ),
                  ),
                );
              } else if (value == 'okundu') {
                okunduajanda(context, row.getCells()[1].value);
              } else if (value == 'sil') {
                showAjandaSilmeConfirmationDialog(context, row.getCells()[1].value.toString());
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(value: 'duzenle', child: Text('Düzenle')),
              PopupMenuItem<String>(value: 'okundu', child: Text('Okundu')),
              PopupMenuItem<String>(value: 'sil', child: Text('Sil')),
            ],
          )
      )
    ]);
  }

  Future<bool?> showAjandaSilmeConfirmationDialog(BuildContext context, String id)  {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Emin misiniz?'),
          content: Text('Veri silme işlemi geri alınamaz!'),
          actions: <Widget>[
            TextButton(
              child: Text('VAZGEÇ'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('SİL'),
              onPressed: () {
                ajandasil(context, id);
              },
            ),
          ],
        );
      },
    );
  }

  void okunduajanda(BuildContext context, String ajandaid) async {
    showProgressLoading(context);
    Map<String, dynamic> formData = {
      'ajanda_id': ajandaid,
    };

    final response = await http.post(
      Uri.parse('https://app.randevumcepte.com.tr/api/v1/ajanda_okunduisaretle'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(formData),
    );

    if (response.statusCode == 200) {
      Navigator.of(context, rootNavigator: true).pop();
      fetchData(currentPage.toString(), baslik, false); // progress gösterme
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Okundu işaretlenirken hata oluştu! Hata kodu: ${response.statusCode}'),
        ),
      );
      debugPrint(response.body);
    }
  }

  Future<void> ajandasil(BuildContext context, String id) async {
    Map<String, dynamic> formData = {
      'id': id,
    };

    final response = await http.post(
      Uri.parse('https://app.randevumcepte.com.tr/api/v1/ajandasil'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(formData),
    );

    if (response.statusCode == 200) {
      Navigator.of(context).pop();
      fetchData(currentPage.toString(), baslik, false); // progress gösterme
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Notunuz silinirken bir hata oluştu! Hata kodu: ${response.statusCode}'),
        ),
      );
      debugPrint('Error: ${response.body}');
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    isLoadingNotifier.dispose();
    super.dispose();
  }
}


class UrunDataSource extends DataGridSource {
  List<DataGridRow> _paginatedRows = [];

  int rowsPerPage;
  int currentPage;

  int totalPages = 1;
  int totalRows;
  String salonid;
  final dynamic isletmebilgi;
  BuildContext context;
  List<Urun> urun = [];
  List<DataGridRow> urunRows = [];
  ValueNotifier<bool> isLoadingNotifier = ValueNotifier(false);
  ValueNotifier<bool> selectAll = ValueNotifier(false);
  ValueNotifier<bool> anyChecked = ValueNotifier(false);
  late ValueNotifier<List<bool>> selectedRows;
  final Function(int, bool) checkBoxChecked;

  UrunDataSource({
    required this.rowsPerPage,
    required this.isletmebilgi,
    required this.context,
    required this.salonid,
    required this.checkBoxChecked,


  }) : currentPage = 1, totalRows = 0 {
    fetchData(currentPage.toString(),'');
  }

  Future<void> fetchData(String page,String urunadi) async {

    isLoadingNotifier.value = true;
    urunadi == '' ? showProgressLoading(context) : null;
    notifyListeners();
    final jsonResponse = await urunlerigetir(salonid, page.toString(),urunadi);
    List<dynamic> data = jsonResponse['data'];
    urun = data.map<Urun>((json) => Urun.fromJson(json)).toList();
    selectedRows = ValueNotifier(List.generate(urun.length, (index) => false));
    _paginatedRows = urun.map<DataGridRow>((e) {
      return DataGridRow(cells: [

        DataGridCell<Urun>(columnName: 'urun', value: e),
        DataGridCell<String>(columnName: 'id', value: e.id.toString()),
        DataGridCell<String>(columnName: 'urunadi', value: e.urun_adi.toString()),

        DataGridCell<String>(columnName: 'stok', value: e.stok_adedi.toString()),
        DataGridCell<String>(columnName: 'fiyat', value: e.fiyat.toString()),
      ]);
    }).toList();

    totalPages = jsonResponse['last_page'];

    currentPage = jsonResponse['current_page'];
    totalRows = urun.length;
    isLoadingNotifier.value = false;
    urunadi == '' ? Navigator.of(context, rootNavigator: true).pop() : null;// Notify listeners that loading has finished
    notifyListeners();



  }
  void search(String musteridanisanadi)
  {
    currentPage = 1;
    fetchData("1",musteridanisanadi);
  }
  void setPage(int page) {
    if (page > 0 && page <= totalPages) {
      currentPage = page;
      fetchData(currentPage.toString(),"");
    }
  }
  Future<void> urunEkleGuncelle(String urunid,String urunadi,String fiyat,String stokadedi,String dusukstoksiniri, String barkod,context,String salonid) async {



    showProgressLoading(context);
    Map<String, dynamic> formData = {
      'urun_id':urunid,
      'urun_adi': urunadi,
      'stok_adedi': stokadedi,
      'dusuk_stok_siniri':dusukstoksiniri,
      'barkod': barkod,
      'fiyat': fiyat,



      // Add other form fields
    };

    final response = await http.post(
      Uri.parse('https://app.randevumcepte.com.tr/api/v1/urunekleduzenle/'+salonid),

      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(formData),
    );

    if (response.statusCode == 200) {


      Navigator.of(context,rootNavigator: true).pop();
      Navigator.of(context).pop();
      fetchData("1",'');

    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ürün '+urunid!='' ? 'güncellenirken' : 'eklenirken'+' bir hata oluştu! Hata kodu : '+response.statusCode.toString()),
        ),
      );
      debugPrint('Error: ${response.body}');
    }

  }

  void hepsiniSec(bool value)
  {
    notifyListeners();
    selectAll.value = value!;
    selectedRows.value = List.generate(urun.length, (_) => selectAll.value);

    anyChecked.value= selectedRows.value.any((element) => element);

    notifyListeners();
  }
  @override
  List<DataGridRow> get rows => _paginatedRows;
  Future<bool?> showDeleteConfirmationDialog(BuildContext context, int id, Function onDeleteConfirmed)  {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Emin misiniz?'),
          content: Text('Veri silme işlemi geri alınamaz!'),
          actions: <Widget>[
            TextButton(
              child: Text('VAZGEÇ'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('SİL'),
              onPressed: () {

                onDeleteConfirmed();

              },
            ),
          ],
        );
      },
    );
  }
  Future<void> sil(BuildContext context, int id) async {
    Map<String, dynamic> formData = {
      'urunid':id,
    };

    final response = await http.post(
      Uri.parse('https://app.randevumcepte.com.tr/api/v1/urunpasifet'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(formData),
    );

    if (response.statusCode == 200) {
      fetchData('1', '');

    }
    else {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ürün silinirken bir hata oluştu! Hata kodu : '+response.statusCode.toString()),
        ),
      );
      debugPrint('Error: ${response.body}');
    }
  }
  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    final int rowIndex = rows.indexOf(row);
    return DataGridRowAdapter(cells: [
      /*
      Checkbox(
      value: selectAll.value,
        onChanged: (value) {

          selectAll.value = value!;
          selectedRows.value = List.generate(urun.length, (_) => selectAll.value);
          anyChecked.value = selectedRows.value.any((element) => element);

        },
        activeColor: Colors.purple[800],
      ),*/
      Checkbox(
        value: selectedRows.value[_paginatedRows.indexOf(row)],
        onChanged: (bool? value) {
          notifyListeners();
          selectedRows.value[_paginatedRows.indexOf(row)] = value ?? false;
          checkBoxChecked(rowIndex,value!);

          notifyListeners();

        },
        activeColor: Colors.purple[800],
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[0].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[1].value),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[2].value),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[3].value),
      ),
      Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[4].value),
      ),
      Container(
          alignment: Alignment.center,
          child:PopupMenuButton<String>(
            onSelected: (String value) async {
              if(value=='duzenle')
              {

                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => UrunDuzenle(urundetayi: row.getCells()[0].value,salonid: this.salonid,urunDataSource: this,isletmebilgi:isletmebilgi)),
                );
              }
              if(value=='sil')
              {
                final confirmed = await showDeleteConfirmationDialog(context,int.parse(row.getCells()[1].value), () {
                  // Perform deletion

                  Navigator.of(context, rootNavigator: true).pop();

                  sil(context, int.parse(row.getCells()[1].value));

                  fetchData('1', '');




                });


              }


            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'duzenle',
                child: Text('Düzenle'),
              ),
              PopupMenuItem<String>(
                value: 'sil',
                child: Text('Sil'),
              ),

            ],
          )
      )

    ]);
    List<Widget> cellwidget = [];
    cellwidget.add(Checkbox(
      value: selectAll.value,
      onChanged: (value) {

        selectAll.value = value!;
        selectedRows.value = List.generate(urun.length, (_) => selectAll.value);
        anyChecked.value = selectedRows.value.any((element) => element);

      },
      activeColor: Colors.purple[800],
    ));


    row.getCells().map<Widget>((cell) {
      cellwidget.add(Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(5.0),
        child: Text(cell.value.toString(),style: TextStyle(fontSize: 12),),
      ));

    }).toList();


    cellwidget.add(Container(
        alignment: Alignment.center,
        child:PopupMenuButton<String>(
          onSelected: (String value) {


          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: 'formindir',
              child: Text('İndir'),
            ),
            PopupMenuItem<String>(
              value: 'formyazdir',
              child: Text('Yazdır'),
            ),
            PopupMenuItem<String>(
              value: 'formgonder',
              child: Text('Formu Gönder'),
            ),
            PopupMenuItem<String>(
              value: 'formonayla',
              child: Text('Onayla'),
            ),
            PopupMenuItem<String>(
              value: 'formiptal',
              child: Text('İptal Et'),
            ),
          ],
        )
    ));
    return DataGridRowAdapter(cells: cellwidget);

  }

}
class PaketSatisDataSource extends DataGridSource {
  List<DataGridRow> _paginatedRows = [];

  int rowsPerPage;
  int currentPage;

  int totalPages = 1;
  int totalRows;
  String salonid;

  BuildContext context;
  List<PaketSatisi> paket = [];
  List<DataGridRow> paketRows = [];
  ValueNotifier<bool> isLoadingNotifier = ValueNotifier(false);
  ValueNotifier<bool> selectAll = ValueNotifier(false);
  ValueNotifier<bool> anyChecked = ValueNotifier(false);
  late ValueNotifier<List<bool>> selectedRows;
  int kullanicirolu;

  PaketSatisDataSource({
    required this.rowsPerPage,

    required this.context,
    required this.salonid,
    required this.kullanicirolu,

  }) : currentPage = 1, totalRows = 0 {
    fetchData(currentPage.toString(),"");
  }

  Future<void> fetchData(String page,String musteridanisanadi) async {
    isLoadingNotifier.value = true;
    musteridanisanadi == '' ? showProgressLoading(context) : null;
    notifyListeners();

    final jsonResponse = await paketsatislarigetir(salonid,page.toString(),musteridanisanadi);
    print('JSON Response: $jsonResponse');
    List<dynamic> data = jsonResponse['data'];
    print('data: $data');

    paket = data.map<PaketSatisi>((json) => PaketSatisi.fromJson(json)).toList();
    print('Parsed PaketSatisi List: $paket');
    _paginatedRows = paket.map<DataGridRow>((e) {
      return DataGridRow(cells: [
        DataGridCell<PaketSatisi>(columnName: 'paket',value: e),
        DataGridCell<String>(columnName: 'id', value: e.id.toString()),
        DataGridCell<String>(columnName: 'paketadi', value: e.paket.toString()),
        DataGridCell<String>(columnName: 'musteridanisan', value: e.musteri.toString()),
        DataGridCell<String>(columnName: 'fiyat', value: e.fiyat.toString()),
        DataGridCell<String>(columnName: 'tarih', value: e.tarih.toString()),
        DataGridCell<String>(columnName: 'satan', value: e.satan.toString()),

      ]);
    }).toList();


    totalPages = jsonResponse['last_page'];

    currentPage = jsonResponse['current_page'];
    totalRows = paket.length;
    isLoadingNotifier.value = false;
    musteridanisanadi == '' ? Navigator.of(context, rootNavigator: true).pop() : null;// Notify listeners that loading has finished
    notifyListeners();



  }
  @override
  List<DataGridRow> get rows => _paginatedRows;
  void search(String musteridanisanadi)
  {
    currentPage = 1;
    fetchData("1",musteridanisanadi);
  }
  void setPage(int page) {
    if (page > 0 && page <= totalPages) {
      currentPage = page;
      fetchData(currentPage.toString(),"");
    }
  }



  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    final int rowIndex = rows.indexOf(row);
    print('Building row for index: $rowIndex');

    // Debug print to check row cells
    row.getCells().forEach((cell) {
      print('Cell: ${cell.columnName}, Value: ${cell.value}');
    });

    return DataGridRowAdapter(cells: [
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[0].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[1].value),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[2].value),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[3].value),
      ),
      Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[4].value),
      ),
      SizedBox()

    ]);
  }
}
class UrunSatisDataSource extends DataGridSource {

  List<DataGridRow> _paginatedRows = [];

  int rowsPerPage;
  int currentPage;

  int totalPages = 1;
  int totalRows;
  String salonid;

  BuildContext context;
  List<UrunSatisi> urun = [];
  List<DataGridRow> urunsatisRows = [];
  ValueNotifier<bool> isLoadingNotifier = ValueNotifier(false);
  ValueNotifier<bool> selectAll = ValueNotifier(false);
  ValueNotifier<bool> anyChecked = ValueNotifier(false);
  late ValueNotifier<List<bool>> selectedRows;
  int kullanicirolu;


  UrunSatisDataSource({
    required this.rowsPerPage,
    required this.kullanicirolu,
    required this.context,
    required this.salonid,

  }) : currentPage = 1, totalRows = 0 {
    fetchData(currentPage.toString(),"");
  }

  Future<void> fetchData(String page,String musteridanisanadi) async {
    isLoadingNotifier.value = true;
    musteridanisanadi == '' ? showProgressLoading(context) : null;
    notifyListeners();

    final jsonResponse = await urunsatislarigetir(salonid,page.toString(),musteridanisanadi);
    print('JSON Response: $jsonResponse');
    List<dynamic> data = jsonResponse['data'];
    print('data: $data');

    urun = data.map<UrunSatisi>((json) => UrunSatisi.fromJson(json)).toList();
    print('Parsed PaketSatisi List: $urun');
    _paginatedRows = urun.map<DataGridRow>((e) {
      return DataGridRow(cells: [
        DataGridCell<UrunSatisi>(columnName: 'urun',value: e),
        DataGridCell<String>(columnName: 'id', value: e.id.toString()),
        DataGridCell<String>(columnName: 'urunadi', value: e.urun.toString()),
        DataGridCell<String>(columnName: 'musteridanisan', value: e.musteri.toString()),
        DataGridCell<String>(columnName: 'fiyat', value: e.fiyat.toString()),
        DataGridCell<String>(columnName: 'tarih', value: e.tarih.toString()),
        DataGridCell<String>(columnName: 'satan', value: e.satan.toString()),

      ]);
    }).toList();


    totalPages = jsonResponse['last_page'];

    currentPage = jsonResponse['current_page'];
    totalRows = urun.length;
    isLoadingNotifier.value = false;
    musteridanisanadi == '' ? Navigator.of(context, rootNavigator: true).pop() : null;// Notify listeners that loading has finished
    notifyListeners();



  }
  @override
  List<DataGridRow> get rows => _paginatedRows;
  void search(String musteridanisanadi)
  {
    currentPage = 1;
    fetchData("1",musteridanisanadi);
  }
  void setPage(int page) {
    if (page > 0 && page <= totalPages) {
      currentPage = page;
      fetchData(currentPage.toString(),"");
    }
  }



  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    final int rowIndex = rows.indexOf(row);
    print('Building row for index: $rowIndex');

    // Debug print to check row cells
    row.getCells().forEach((cell) {
      print('Cell: ${cell.columnName}, Value: ${cell.value}');
    });

    return DataGridRowAdapter(cells: [
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[0].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[1].value),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[2].value),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[3].value),
      ),
      Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[4].value),
      ),
        SizedBox()

    ]);
  }
}
class AlacaklarDataSource extends DataGridSource {

  List<DataGridRow> _paginatedRows = [];

  int rowsPerPage;
  int currentPage;

  int totalPages = 1;
  int totalRows;
  String salonid;

  BuildContext context;
  List<Alacaklar> alacak = [];
  List<DataGridRow> alacakRows = [];
  ValueNotifier<bool> isLoadingNotifier = ValueNotifier(false);
  ValueNotifier<bool> selectAll = ValueNotifier(false);
  ValueNotifier<bool> anyChecked = ValueNotifier(false);
  late ValueNotifier<List<bool>> selectedRows;


  AlacaklarDataSource({
    required this.rowsPerPage,

    required this.context,
    required this.salonid,

  }) : currentPage = 1, totalRows = 0 {
    fetchData(currentPage.toString(),"");
  }

  Future<void> fetchData(String page,String musteridanisanadi) async {
    isLoadingNotifier.value = true;
    musteridanisanadi == '' ? showProgressLoading(context) : null;
    notifyListeners();

    final jsonResponse = await alacaklargetir(salonid,page.toString(),musteridanisanadi);
    print('JSON Response: $jsonResponse');
    List<dynamic> data = jsonResponse['data'];
    print('data: $data');

    alacak = data.map<Alacaklar>((json) => Alacaklar.fromJson(json)).toList();
    print('Parsed PaketSatisi List: $alacak');
    _paginatedRows = alacak.map<DataGridRow>((e) {
      return DataGridRow(cells: [
        DataGridCell<Alacaklar>(columnName: 'alacak',value: e),
        DataGridCell<String>(columnName: 'id', value: e.id.toString()),
        DataGridCell<String>(columnName: 'musteridanisan', value: e.musteri.toString()),
        DataGridCell<String>(columnName: 'tutar', value: e.tutar.toString()),
        DataGridCell<String>(columnName: 'odemetarih', value: e.odemetarih.toString()),


      ]);
    }).toList();


    totalPages = jsonResponse['last_page'];

    currentPage = jsonResponse['current_page'];
    totalRows = alacak.length;
    isLoadingNotifier.value = false;
    musteridanisanadi == '' ? Navigator.of(context, rootNavigator: true).pop() : null;// Notify listeners that loading has finished
    notifyListeners();



  }
  @override
  List<DataGridRow> get rows => _paginatedRows;
  void search(String musteridanisanadi)
  {
    currentPage = 1;
    fetchData("1",musteridanisanadi);
  }
  void setPage(int page) {
    if (page > 0 && page <= totalPages) {
      currentPage = page;
      fetchData(currentPage.toString(),"");
    }
  }



  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    final int rowIndex = rows.indexOf(row);
    print('Building row for index: $rowIndex');

    // Debug print to check row cells
    row.getCells().forEach((cell) {
      print('Cell: ${cell.columnName}, Value: ${cell.value}');
    });

    return DataGridRowAdapter(cells: [
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[0].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[1].value),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[2].value),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[3].value),
      ),
      Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[4].value),
      ),
      Container(
        alignment: Alignment.center,
        child: PopupMenuButton<String>(
          onSelected: (String value) async {
            if (value == 'tahsilet') {
              // Navigate to another screen or perform an action
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: 'tahsilet',
              child: Text('Tahsil Et'),
            ),
          ],
        ),
      ),
    ]);
  }
}
class PaketDataSource extends DataGridSource {
  List<DataGridRow> _paginatedRows = [];

  int rowsPerPage;
  int currentPage;

  int totalPages = 1;
  int totalRows;
  String salonid;

  BuildContext context;
  List<Paket> paket = [];
  List<DataGridRow> paketRows = [];
  ValueNotifier<bool> isLoadingNotifier = ValueNotifier(false);
  ValueNotifier<bool> selectAll = ValueNotifier(false);
  ValueNotifier<bool> anyChecked = ValueNotifier(false);
  late ValueNotifier<List<bool>> selectedRows;
  final Function(int, bool) checkBoxChecked;

  PaketDataSource({
    required this.rowsPerPage,

    required this.context,
    required this.salonid,
    required this.checkBoxChecked,


  }) : currentPage = 1, totalRows = 0 {
    fetchData(currentPage.toString(),'');
  }

  Future<void> fetchData(String page,String pakethimzet) async {

    isLoadingNotifier.value = true;
    pakethimzet == ''  ? showProgressLoading(context) : null;
    notifyListeners();
    final jsonResponse = await paketlerigetir(salonid, page.toString(),pakethimzet,);
    List<dynamic> data = jsonResponse['data'];
    paket = data.map<Paket>((json) => Paket.fromJson(json)).toList();
    selectedRows = ValueNotifier(List.generate(paket.length, (index) => false));

    _paginatedRows = paket.map<DataGridRow>((e) {
      String hizmetler = '';
      double totalfiyat = 0;
      e.hizmetler.forEach((element) {
        hizmetler += element['hizmet']['hizmet_adi'] + ' ('+element['seans'].toString()+') ';
        totalfiyat += double.parse(element['fiyat'].toString());
      });

      return DataGridRow(cells: [

        DataGridCell<Paket>(columnName: 'paket', value: e),
        DataGridCell<String>(columnName: 'id', value: e.id.toString()),
        DataGridCell<String>(columnName: 'paketadi', value: e.paket_adi.toString()),
        DataGridCell<String>(columnName: 'hizmetler', value: hizmetler),
        DataGridCell<String>(columnName: 'fiyat', value: totalfiyat.toString()),
      ]);
    }).toList();

    totalPages = jsonResponse['last_page'];

    currentPage = jsonResponse['current_page'];
    totalRows = paket.length;
    isLoadingNotifier.value = false;
    pakethimzet == '' ? Navigator.of(context, rootNavigator: true).pop() : null;// Notify listeners that loading has finished
    notifyListeners();



  }
  void search(String musteridanisanadi)
  {
    currentPage = 1;
    fetchData("1",musteridanisanadi);
  }
  void setPage(int page) {
    if (page > 0 && page <= totalPages) {
      currentPage = page;
      fetchData(currentPage.toString(),"");
    }
  }


  void hepsiniSec(bool value)
  {
    notifyListeners();
    selectAll.value = value!;
    selectedRows.value = List.generate(paket.length, (_) => selectAll.value);

    anyChecked.value= selectedRows.value.any((element) => element);

    notifyListeners();
  }
  @override
  List<DataGridRow> get rows => _paginatedRows;
  Future<bool?> showDeleteConfirmationDialog(BuildContext context, int id, Function onDeleteConfirmed)  {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Emin misiniz?'),
          content: Text('Veri silme işlemi geri alınamaz!'),
          actions: <Widget>[
            TextButton(
              child: Text('VAZGEÇ'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('SİL'),
              onPressed: () {

                onDeleteConfirmed();

              },
            ),
          ],
        );
      },
    );
  }
  Future<void> sil(BuildContext context, int id) async {
    Map<String, dynamic> formData = {
      'urunid':id,
    };

    final response = await http.post(
      Uri.parse('https://app.randevumcepte.com.tr/api/v1/urunpasifet'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(formData),
    );

    if (response.statusCode == 200) {
      fetchData('1', '');

    }
    else {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ürün silinirken bir hata oluştu! Hata kodu : '+response.statusCode.toString()),
        ),
      );
      debugPrint('Error: ${response.body}');
    }
  }
  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    final int rowIndex = rows.indexOf(row);
    return DataGridRowAdapter(cells: [

      Checkbox(
        value: selectedRows.value[_paginatedRows.indexOf(row)],
        onChanged: (bool? value) {
          notifyListeners();
          selectedRows.value[_paginatedRows.indexOf(row)] = value ?? false;
          checkBoxChecked(rowIndex,value!);

          notifyListeners();

        },
        activeColor: Colors.purple[800],
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[0].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[1].value),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[2].value),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[3].value),
      ),
      Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[4].value),
      ),
      Container(
          alignment: Alignment.center,
          child:PopupMenuButton<String>(
            onSelected: (String value) async {
              if(value=='duzenle')
              {

                /*Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => UrunDuzenle(urundetayi: row.getCells()[0].value,salonid: this.salonid,urunDataSource: this,)),
                );*/
              }
              if(value=='sil')
              {
                final confirmed = await showDeleteConfirmationDialog(context,int.parse(row.getCells()[1].value), () {
                  // Perform deletion

                  Navigator.of(context, rootNavigator: true).pop();

                  sil(context, int.parse(row.getCells()[1].value));

                  fetchData('1', '');




                });


              }


            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'duzenle',
                child: Text('Düzenle'),
              ),
              PopupMenuItem<String>(
                value: 'sil',
                child: Text('Sil'),
              ),

            ],
          )
      )

    ]);
    List<Widget> cellwidget = [];
    cellwidget.add(Checkbox(
      value: selectAll.value,
      onChanged: (value) {

        selectAll.value = value!;
        selectedRows.value = List.generate(paket.length, (_) => selectAll.value);
        anyChecked.value = selectedRows.value.any((element) => element);

      },
      activeColor: Colors.purple[800],
    ));


    row.getCells().map<Widget>((cell) {
      cellwidget.add(Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(5.0),
        child: Text(cell.value.toString(),style: TextStyle(fontSize: 12),),
      ));

    }).toList();


    cellwidget.add(Container(
        alignment: Alignment.center,
        child:PopupMenuButton<String>(
          onSelected: (String value) {


          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: 'formindir',
              child: Text('İndir'),
            ),
            PopupMenuItem<String>(
              value: 'formyazdir',
              child: Text('Yazdır'),
            ),
            PopupMenuItem<String>(
              value: 'formgonder',
              child: Text('Formu Gönder'),
            ),
            PopupMenuItem<String>(
              value: 'formonayla',
              child: Text('Onayla'),
            ),
            PopupMenuItem<String>(
              value: 'formiptal',
              child: Text('İptal Et'),
            ),
          ],
        )
    ));
    return DataGridRowAdapter(cells: cellwidget);

  }

}
class SeansDataSource extends DataGridSource {
  List<DataGridRow> _paginatedRows = [];

  int rowsPerPage;
  int currentPage;

  int totalPages = 1;
  int totalRows;
  String salonid;
  String musteriid;
  BuildContext context;
  List<SeansTakip> seanstakibi = [];
  bool musteriMi;
  List<DataGridRow> paketRows = [];
  ValueNotifier<bool> isLoadingNotifier = ValueNotifier(false);




  SeansDataSource({
    required this.rowsPerPage,
    required this.context,
    required this.salonid,
    required this.musteriid,
    required this.musteriMi,

  }) : currentPage = 1, totalRows = 0 {
    fetchData(currentPage.toString(),'');
  }
  Row seansdetaylari(item)
  {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        ElevatedButton(onPressed: (){},style: ElevatedButton.styleFrom(backgroundColor:Colors.purple[800],foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
            minimumSize: Size(55, 20)

        )

            ,child: Row(
              children: [
                Text(item['toplam'],style: TextStyle(color: Colors.white),),

                Icon(Icons.add,color: Colors.white,size: 15,)
              ],
            )),
        SizedBox(width: 3,),
        ElevatedButton(onPressed: (){},style: ElevatedButton.styleFrom(backgroundColor:Colors.yellow[600],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
            minimumSize: Size(50, 20)

        )

            ,child: Row(
              children: [
                Text(item['beklenen'],style: TextStyle(color: Colors.black),),

                Icon(Icons.calendar_month,color: Colors.black,size: 15,)
              ],
            )),
        SizedBox(width: 3,),
        ElevatedButton(onPressed: (){},style: ElevatedButton.styleFrom(backgroundColor:Colors.green,foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
            minimumSize: Size(55, 20)

        )

            ,child: Row(
              children: [
                Text(item['gelen'],style: TextStyle(color: Colors.white),),

                Icon(Icons.check,size: 15,)
              ],
            )),
        SizedBox(width: 3,),
        ElevatedButton(onPressed: (){},style: ElevatedButton.styleFrom(backgroundColor:Colors.red[600],foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
            minimumSize: Size(55, 20)

        )

            ,child: Row(
              children: [
                Text(item['Kalan'],style: TextStyle(color: Colors.white),),

                Icon(Icons.close_outlined,size: 15,)
              ],
            )),

        Icon(item['icon']),
      ],
    );
  }
  Future<void> fetchData(String page,String musteripaket) async {

    isLoadingNotifier.value = true;

    notifyListeners();
    final jsonResponse = await seanslarigetir(salonid, page.toString(),musteripaket,musteriid,context,musteriMi);

    List<dynamic> data = jsonResponse['data'];
    log('Seans json data '+jsonEncode(jsonResponse['data']));

    seanstakibi = data.map<SeansTakip>((json) => SeansTakip.fromJson(json)).toList();
    if(_paginatedRows.length>0)
      _paginatedRows = [];

    seanstakibi.forEach((e) {
      String icerikStr = (!musteriMi ? e.musteri["name"]+'\n' : '')+ e.paket.toString();



      e.seanslar.forEach((f) {





        if(!musteriMi)
          icerikStr += e.musteri['name']+'\n';
        icerikStr += e.paket.toString();


      });
      ++totalRows;

      _paginatedRows.add(
          DataGridRow(cells: [
            DataGridCell<SeansTakip>(columnName: 'paket', value: e),
            DataGridCell<String>(columnName: 'musteridanisanpaket', value:icerikStr),

            DataGridCell<int>(columnName: 'beklenen', value: e.bekleyenSeansSayisi),
            DataGridCell<int>(columnName: 'gelinen', value: e.gelinenSeansSayisi),
            DataGridCell<int>(columnName: 'gelinmeyen', value: e.gelinmeyenSeansSayisi),

          ])
      );



    });


    totalPages = jsonResponse['last_page'];

    currentPage = jsonResponse['current_page'];

    isLoadingNotifier.value = false;
    // Notify listeners that loading has finished
    notifyListeners();



  }
  void search(String musteridanisanadi)
  {
    currentPage = 1;
    fetchData("1",musteridanisanadi);
  }
  void setPage(int page) {
    if (page > 0 && page <= totalPages) {
      currentPage = page;

      fetchData(currentPage.toString(),"");
    }
  }



  @override
  List<DataGridRow> get rows => _paginatedRows;


  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    final int rowIndex = rows.indexOf(row);
    return DataGridRowAdapter(cells: [
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[0].value.toString()),
      ),

      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[1].value.toString()),
      ),

      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[2].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[3].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[4].value.toString()),
      ),
      Container(
        height: 20,
        child:Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height:5),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap, // <--- BU
                    backgroundColor: Colors.purple[800],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                    minimumSize: Size(30, 20),
                  ),
                  child: Row(
                    children: [
                      Text(
                        (row.getCells()[2].value +
                            row.getCells()[3].value +
                            row.getCells()[4].value)
                            .toString(),
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                      Icon(Icons.add, color: Colors.white, size: 15),
                    ],
                  ),
                ),
                SizedBox(width: 3),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap, // <--- BU
                    backgroundColor: Colors.yellow[600],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                    minimumSize: Size(30, 20),
                  ),
                  child: Row(
                    children: [
                      Text(
                        (row.getCells()[2].value).toString(),
                        style: TextStyle(color: Colors.black, fontSize: 10),
                      ),
                      Icon(Icons.calendar_month, color: Colors.black, size: 15),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height:5),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap, // <--- BU
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                    minimumSize: Size(30, 20),
                  ),
                  child: Row(
                    children: [
                      Text(
                        row.getCells()[3].value.toString(),
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                      Icon(Icons.check, size: 15),
                    ],
                  ),
                ),
                SizedBox(width: 3),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap, // <--- BU
                    backgroundColor: Colors.red[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                    minimumSize: Size(30, 20),
                  ),
                  child: Row(
                    children: [
                      Text(
                        row.getCells()[4].value.toString(),
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                      Icon(Icons.close_outlined, size: 15),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height:5),
          ],
        ),
      )



    ]);


  }

}
class ArsivDataSource2 extends DataGridSource {
  int rowsPerPage;
  int currentPage;
  int totalPages = 1;
  int totalRows;
  String arama;
  final String musteriDanisanId;
  BuildContext context;

  List<Arsiv> arsiv = [];
  List<DataGridRow> _paginatedRows = [];
  ValueNotifier<bool> isLoadingNotifier = ValueNotifier(false);

  String salonid;
  String musteriid;
  String durum = '';
  String cevapladi = '';
  String cevapladi2 = '';

  ArsivDataSource2({
    required this.context,
    required this.durum,
    required this.cevapladi,
    required this.cevapladi2,
    required this.rowsPerPage,
    required this.salonid,
    required this.musteriid,
    required this.arama,
    required this.musteriDanisanId,
  }) : currentPage = 1, totalRows = 0 {
    fetchData(currentPage.toString(), '', false);
  }

  Future<void> fetchData(String page, String arama, bool showprogress) async {
    isLoadingNotifier.value = true;
    if (showprogress) showProgressLoading(context);
    notifyListeners();

    final jsonResponse = await arsivgetir(salonid,musteriid, page.toString(), arama, durum, cevapladi, cevapladi2);

    List<dynamic> data = jsonResponse['data'];
    arsiv = data.map<Arsiv>((json) => Arsiv.fromJson(json)).toList();
    totalPages = jsonResponse['last_page'];
    currentPage = jsonResponse['current_page'];

    _filterData();

    isLoadingNotifier.value = false;
    if (showprogress) Navigator.of(context, rootNavigator: true).pop();
    notifyListeners();
  }

  void _filterData() {
    // Apply filter based on search query and musteriDanisanId
    final filteredData = arsiv.where((item) {
      return item.musteridanisan['name'] == musteriDanisanId &&
          (item.musteridanisan['name'].toLowerCase().contains(arama.toLowerCase()) ||
              item.form['form_adi'].toLowerCase().contains(arama.toLowerCase()));
    }).toList();

    _paginatedRows = filteredData.map<DataGridRow>((e) {
      return DataGridRow(cells: [
        DataGridCell<Arsiv>(columnName: 'arsiv', value: e),
        DataGridCell<String>(columnName: 'id', value: e.id),
        DataGridCell<String>(columnName: 'tarih', value: formatDateTime(e.tarih_saat)),

        DataGridCell<String>(columnName: 'formadi', value: e.form["form_adi"] == 'Harici' ? e.sozlesme_adi : e.form["form_adi"]),
        DataGridCell<String>(columnName: 'durum', value: e.durum.toString()),
        DataGridCell<String>(columnName: 'cevaplandi', value: e.cevapladi.toString()),
        DataGridCell<String>(columnName: 'cevaplandi2', value: e.cevapladi2.toString()),
      ]);
    }).toList();
  }

  void search(String musteridanisanadi) {
    currentPage = 1;
    arama = musteridanisanadi;
    fetchData("1", musteridanisanadi, false);
  }

  void setPage(int page) {
    if (page > 0 && page <= totalPages) {
      currentPage = page;
      fetchData(currentPage.toString(), arama, true);
    }
  }

  @override
  List<DataGridRow> get rows => _paginatedRows;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    return DataGridRowAdapter(cells: [
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[0].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[1].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[2].value.toString()),
      ),

      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[3].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[4].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[5].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[6].value.toString()),
      ),
      Container(
        padding: EdgeInsets.only(top: 10.0, bottom: 10.0),
        height: 20,
        child: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: getStatusColorArsiv(row.getCells()[4].value.toString(), row.getCells()[5].value.toString(), row.getCells()[6].value.toString())?.color,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
            minimumSize: Size(100, 20),
          ),
          child: Text(
            getStatusColorArsiv(row.getCells()[4].value.toString(), row.getCells()[5].value.toString(), row.getCells()[6].value.toString()).text,
            style: TextStyle(color: Colors.white, fontSize: 10),
          ),
        ),
      ),
      Container(
        alignment: Alignment.center,
        child: PopupMenuButton<String>(
          onSelected: (String value) {

            if (value == 'formindir') {

              String dosya = row.getCells()[0].value.uzanti;
              String dosyaReplaced = dosya.replaceAll('public/formlar/', '');
              dosyaIndir( 'https://app.randevumcepte.com.tr/'+dosya,dosyaReplaced ,context);
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[

            PopupMenuItem<String>(
              value: 'formindir',
              child: Text('İndir'),
            ),

          ],
        ),
      ),
    ]);
  }

  void showDetailsDialog(BuildContext context, Arsiv arsiv) {
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          insetPadding: EdgeInsets.zero,
          content: Container(
            height: 250,
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
                      Text(
                        arsiv.musteridanisan["name"],
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Divider(color: Colors.black, height: 10,),
                      Row(
                        children: [
                          Text('Tarih'),
                          SizedBox(width: 14,),
                          Text(': '),
                          Expanded(child: Text(formatDateTime(arsiv.tarih_saat)))
                        ],
                      ),
                      Row(
                        children: [
                          Text('Başlık'), SizedBox(width: 7,),
                          Text(':'),
                          Expanded(

                              child: Text(
                                  arsiv.form["form_adi"] != 'harici' ? arsiv.form["form_adi"] : arsiv.sozlesme_adi))
                        ],
                      ),
                      Row(
                        children: [
                          Text('Durum'),
                          SizedBox(width: 2,),
                          Text(': '),
                          Expanded(child: Text(getStatusColorArsiv(arsiv.durum, arsiv.cevapladi, arsiv.cevapladi2).text))
                        ],
                      ),
                      Row(
                        children: [
                          Text('İşlem Yapan Personel'),
                          SizedBox(width: 2,),
                          Text(': '),
                          Expanded(child: Text(arsiv.personel["personel_adi"]))
                        ],
                      ),
                      Divider(color: Colors.black, height: 20,),
                      SizedBox(height: 10,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [

                          ElevatedButton(
                            onPressed: () async {
                              String formadi = arsiv.form["form_adi"] == "Harici Belge" ? arsiv.sozlesme_adi : arsiv.form["form_adi"];
                              String fileName = '${arsiv.musteridanisan["name"]}${arsiv.tarih_saat}$formadi.${path.extension(arsiv.uzanti)}';
                              final fileDownloader = FileDownloader();

                              try {
                                final filePath = await fileDownloader.downloadFile(
                                  'https://app.randevumcepte.com.tr/${arsiv.uzanti}',
                                  fileName,
                                );
                                log('File downloaded to: $filePath');
                              } catch (e) {
                                log('Failed to download file: $e');
                              }
                            },
                            child: Text('İndir', style: TextStyle(color: Colors.black)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.yellow[600],
                              elevation: 5,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5.0),
                              ),
                              minimumSize: Size(90, 30),
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


class SenetDataSource extends DataGridSource {
  List<DataGridRow> _paginatedRows = [];

  int rowsPerPage;
  int currentPage;
  String arama;
  int totalPages = 1;
  int totalRows;
  String salonid;
  String durum;
  BuildContext context;
  List<Senet> senet = [];

  List<DataGridRow> paketRows = [];
  ValueNotifier<bool> isLoadingNotifier = ValueNotifier(false);




  SenetDataSource({
    required this.rowsPerPage,
    required this.context,
    required this.salonid,
    required this.durum,
    required this.arama,

  }) : currentPage = 1, totalRows = 0 {
    fetchData(currentPage.toString(),'',true);
  }

  Future<void> fetchData(String page,String musteripaket,bool showprogress) async {

    isLoadingNotifier.value = true;
    if(showprogress)
      showProgressLoading(context);
    notifyListeners();
    final jsonResponse = await senetlerigetir(salonid, page.toString(),musteripaket,durum);

    List<dynamic> data = jsonResponse['data'];
    senet = data.map<Senet>((json) => Senet.fromJson(json)).toList();
    if(_paginatedRows.length>0)
      _paginatedRows = [];

    senet.forEach((e) {
      String yaklasanvadetarih = '';
      int odenenvade = 0;
      int kalanvade = 0;
      String durum = '';
      e.vadeler.forEach((f) {
        if (f["odendi"] == 1)
          ++odenenvade;
        else {
          ++kalanvade;
          if(yaklasanvadetarih=='')
            yaklasanvadetarih=formattedDate(f["vade_tarih"]);
        }
        if(kalanvade>0 ){

          if(yaklasanvadetarih != '')
          {
            if(DateTime.parse(f["vade_tarih"]+'T00:00:00').isBefore(DateTime.now()))
              durum = 'Ödenmemiş';
            else{
              if(durum != 'Ödenmemiş')
                durum = 'Açık';
            }
          }

        }
        else
          durum = 'Kapalı';



      });




      ++totalRows;

      _paginatedRows.add(
          DataGridRow(cells: [
            DataGridCell<Senet>(columnName: 'senetpar', value: e),
            DataGridCell<String>(columnName: 'durum', value: durum),
            DataGridCell<String>(columnName: 'musteridanisan', value: e.musteri["name"]),

            DataGridCell<int>(columnName: 'odenen', value: odenenvade),
            DataGridCell<int>(columnName: 'kalan', value: kalanvade),
            DataGridCell<String>(columnName: 'yaklasanvade', value: yaklasanvadetarih),

          ])
      );



    });


    totalPages = jsonResponse['last_page'];

    currentPage = jsonResponse['current_page'];

    isLoadingNotifier.value = false;
    if(showprogress)
      Navigator.of(context, rootNavigator: true).pop();// Notify listeners that loading has finished
    notifyListeners();



  }
  void search(String musteridanisanadi)
  {
    currentPage = 1;
    arama = musteridanisanadi;
    fetchData("1",musteridanisanadi,false);
  }
  void setPage(int page) {
    if (page > 0 && page <= totalPages) {
      currentPage = page;

      fetchData(currentPage.toString(),"",true);
    }
  }



  @override
  List<DataGridRow> get rows => _paginatedRows;


  @override
  DataGridRowAdapter buildRow(DataGridRow row) {

    return DataGridRowAdapter(cells: [


      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(""),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[1].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[2].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[3].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[4].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[5].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(3.0),
        child:     ElevatedButton(onPressed: (){
          showDetailsDialog(context, row);
        },style: ElevatedButton.styleFrom(backgroundColor:Colors.green,foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
            minimumSize: Size(40, 20)

        )

            ,child: Text(row.getCells()[3].value.toString(),style: TextStyle(color: Colors.white),)),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(3.0),
        child:     ElevatedButton(onPressed: (){
          showDetailsDialog(context, row);
        },style: ElevatedButton.styleFrom(backgroundColor:Colors.red[600],foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
            minimumSize: Size(40, 20)

        )

            ,child: Text(row.getCells()[4].value.toString(),style: TextStyle(color: Colors.white),)),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(3.0),
        child: row.getCells()[5].value.toString()==''  ? null :  ElevatedButton(onPressed: (){
          showDetailsDialog(context, row);
        },style: ElevatedButton.styleFrom(backgroundColor:Colors.red[600],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
            minimumSize: Size(40, 20)

        )

            ,child: Text(row.getCells()[5].value.toString(),style: TextStyle(color: Colors.white),)),
      ),


    ]);


  }
  void showDetailsDialog(BuildContext context, DataGridRow row) {
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

                      Text(row.getCells()[2].value.toString(),style: TextStyle(fontWeight: FontWeight.bold),),
                      Divider(color: Colors.black,
                        height: 10,),
                      Row(
                        children: [
                          Text('Durum'),SizedBox(width: 59,),
                          Text(': '),
                          Text(row.getCells()[1].value.toString())
                        ],
                      ),
                      Row(
                        children: [
                          Text('Vade Sayısı'),
                          SizedBox(width: 25,),
                          Text(': '),
                          Expanded(child: Text((row.getCells()[3].value + row.getCells()[4].value).toString()))
                        ],

                      ),
                      Row(
                        children: [
                          Text('Ödenmiş'),SizedBox(width: 43,),
                          Text(': '),
                          Text(row.getCells()[3].value.toString())
                        ],

                      ),
                      Row(
                        children: [
                          Text('Kalan'),SizedBox(width: 67,),
                          Text(': '),
                          Text(row.getCells()[4].value.toString())
                        ],
                      ),
                      Row(
                        children: [
                          Text('Yaklaşan Vade'),

                          Text(' : '),
                          Text(row.getCells()[5].value.toString())
                        ],

                      ),
                      Divider(color: Colors.black,
                        height: 40,),
                      Row(

                        children: [
                          ElevatedButton(onPressed: (){
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => SenetVadeleri(senet: row.getCells()[0].value,senetdatasource: this,page:currentPage.toString(),arama: arama, )),
                            );
                          }, child:
                          Text('Vadeler'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple[800],
                                elevation: 5,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5.0)
                                ),
                                minimumSize: Size(130,30)
                            ),
                          ),
                          SizedBox(width: 15,),
                          ElevatedButton(onPressed: (){
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => PdfPreviewPage(senet:row.getCells()[0].value)),
                            );
                          }, child:
                          Text('Yazdır'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                elevation: 5,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5.0)
                                ),
                                minimumSize: Size(130,30)
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

class GelirDataSource extends DataGridSource {
  var tryformat = NumberFormat.currency(locale: 'tr_TR',symbol: "");
  List<DataGridRow> _paginatedRows = [];
  int rowsPerPage;
  int currentPage;

  int totalPages = 1;
  int totalRows;
  String salonid;
  String tarih;
  String odemeyontemi;
  BuildContext context;
  List<Tahsilat> tahsilat = [];
  List<DataGridRow> paketRows = [];
  ValueNotifier<bool> isLoadingNotifier = ValueNotifier(false);
  GelirDataSource({
    required this.rowsPerPage,
    required this.context,
    required this.salonid,
    required this.odemeyontemi,
    required this.tarih,


  }) : currentPage = 1, totalRows = 0 {
    fetchData(currentPage.toString(),'',true);
  }

  Future<void> fetchData(String page,String musteripaket,bool showprogress) async {

    isLoadingNotifier.value = true;
    if(showprogress)
      showProgressLoading(context);
    notifyListeners();
    final jsonResponse = await tahsilatraporu(salonid, page.toString(),tarih,odemeyontemi);

    List<dynamic> data = jsonResponse['data'];
    tahsilat = data.map<Tahsilat>((json) => Tahsilat.fromJson(json)).toList();
    if(_paginatedRows.length>0)
      _paginatedRows = [];

    tahsilat.forEach((e) {

      ++totalRows;
      _paginatedRows.add(
          DataGridRow(cells: [
            DataGridCell<Tahsilat>(columnName: 'gelirpar', value: e),
            DataGridCell<String>(columnName: 'odemetutar', value: e.tutar.toString()),
            DataGridCell<String>(columnName: 'odemeyontemi', value: e.odeme_yontemi_id.toString()),
            DataGridCell<String>(columnName: 'aciklama', value: e.notlar.toString()),
            DataGridCell<String>(columnName: 'musteridanisanparakoyan', value: e.musteri!=null ? e.musteri["name"] : e.olusturan["personel_adi"]),

            DataGridCell<String>(columnName: 'tarih', value: formattedDate(e.tarih.toString())),



          ])
      );
    });
    totalPages = jsonResponse['last_page'];
    currentPage = jsonResponse['current_page'];
    isLoadingNotifier.value = false;
    if(showprogress)
      Navigator.of(context, rootNavigator: true).pop();// Notify listeners that loading has finished
    notifyListeners();
  }

  void setPage(int page) {
    if (page > 0 && page <= totalPages) {
      currentPage = page;

      fetchData(currentPage.toString(),"",true);
    }
  }



  @override
  List<DataGridRow> get rows => _paginatedRows;


  @override
  DataGridRowAdapter buildRow(DataGridRow row) {

    return DataGridRowAdapter(cells: [

      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[0].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[1].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[2].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[3].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[4].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[5].value.toString()),
      ),
      Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.all(3.0),
        child:     ElevatedButton(onPressed: (){
          showDetailsDialog(context, row);
        },style: ElevatedButton.styleFrom(backgroundColor:Colors.green,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
            minimumSize: Size(100, 20)

        )

            ,child: Text(row.getCells()[1].value.toString(),style: TextStyle(color: Colors.white),)),
      ),


    ]);


  }
  void showDetailsDialog(BuildContext context, DataGridRow row) {
    final _formKey = GlobalKey<FormState>();
    String odemeyontemi = '';
    if (row.getCells()[2].value.toString() == "1")
      odemeyontemi = 'Nakit';
    if (row.getCells()[2].value.toString() == "2")
      odemeyontemi = "Kredi Kartı";
    if (row.getCells()[2].value.toString() == "3")
      odemeyontemi = "Havale / EFT";
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
                      foregroundColor: Colors.white,
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
                      SizedBox(height: 20,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(row.getCells()[4].value.toString(),
                            style: TextStyle(fontWeight: FontWeight.bold),),
                        ],
                      ),
                      Divider(color: Colors.black,
                        height: 10,),
                      Row(
                        children: [
                          Text('Tarih'), SizedBox(width: 83,),
                          Text(':'),
                          Text(row.getCells()[5].value.toString())
                        ],
                      ),
                      Row(
                        children: [
                          Text('Ödeme Yöntemi'),
                          SizedBox(width: 5,),
                          Text(': '),
                          Expanded(child: Text(odemeyontemi))
                        ],

                      ),
                      Row(
                        children: [
                          Text('Fiyat'), SizedBox(width: 85,),
                          Text(':'),
                          Text(row.getCells()[1].value.toString())
                        ],

                      ),

                      Divider(color: Colors.black,
                        height: 10,),


                      Text('Açıklama',
                        style: TextStyle(fontWeight: FontWeight.bold),),
                      Text(row.getCells()[3].value.toString()!="null"?row.getCells()[3].value.toString():"")


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
class GiderDataSource extends DataGridSource {
  var tryformat = NumberFormat.currency(locale: 'tr_TR',symbol: "");
  List<DataGridRow> _paginatedRows = [];
  int rowsPerPage;
  int currentPage;
  dynamic isletmebilgi;
  int totalPages = 1;
  int totalRows;
  String salonid;
  String tarih;
  String harcayan;
  String odemeyontemi;
  BuildContext context;
  List<Masraf> masraf = [];
  List<Personel>personelliste;
  List<MasrafKategorisi>masrafkategoriliste;
  List<DataGridRow> paketRows = [];
  ValueNotifier<bool> isLoadingNotifier = ValueNotifier(false);
  GiderDataSource({
    required this.rowsPerPage,
    required this.context,
    required this.salonid,
    required this.odemeyontemi,
    required this.tarih,
    required this.harcayan,
    required this.personelliste,
    required this.masrafkategoriliste,
    required this.isletmebilgi,

  }) : currentPage = 1, totalRows = 0 {
    fetchData(currentPage.toString(),harcayan,true);
  }
  void search(String harcayan)
  {
    currentPage = 1;
    fetchData("1",harcayan,false);
  }
  Future<void> fetchData(String page,String harcayan,bool showprogress) async {

    isLoadingNotifier.value = true;
    if(showprogress)
      showProgressLoading(context);
    notifyListeners();
    final jsonResponse = await masrafraporu(salonid, page.toString(),tarih,odemeyontemi,harcayan);

    List<dynamic> data = jsonResponse['data'];
    masraf = data.map<Masraf>((json) => Masraf.fromJson(json)).toList();
    if(_paginatedRows.length>0)
      _paginatedRows = [];

    masraf.forEach((e) {

      ++totalRows;
      _paginatedRows.add(
          DataGridRow(cells: [
            DataGridCell<Masraf>(columnName: 'giderpar', value: e),
            DataGridCell<String>(columnName: 'tutar', value: tryformat.format(double.parse(e.tutar.toString())).toString()),
            DataGridCell<String>(columnName: 'harcayan', value: e.harcayan["personel_adi"]),
            DataGridCell<String>(columnName: 'tarih', value: formattedDate(e.tarih.toString())),



          ])
      );
    });
    totalPages = jsonResponse['last_page'];
    currentPage = jsonResponse['current_page'];
    isLoadingNotifier.value = false;
    if(showprogress)
      Navigator.of(context, rootNavigator: true).pop();// Notify listeners that loading has finished
    notifyListeners();
  }

  void setPage(int page) {
    if (page > 0 && page <= totalPages) {
      currentPage = page;

      fetchData(currentPage.toString(),"",true);
    }
  }



  @override
  List<DataGridRow> get rows => _paginatedRows;


  @override
  DataGridRowAdapter buildRow(DataGridRow row) {

    return DataGridRowAdapter(cells: [

      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[0].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[1].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[2].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[3].value.toString()),
      ),

      Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.all(3.0),
        child:     ElevatedButton(onPressed: (){
          showDetailsDialog(context, row.getCells()[0].value);
        },style: ElevatedButton.styleFrom(backgroundColor:Colors.red[600],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
            minimumSize: Size(100, 20)

        )

            ,child: Text(row.getCells()[1].value.toString(),style: TextStyle(color: Colors.white),)),
      ),


    ]);


  }
  Future<void> masrafEkleGuncelle(String masrafid,String masraf_tutari,MasrafKategorisi masraf_kategorisi,String masraf_notlari,OdemeTuru masraf_odeme_yontemi, Personel harcayan,context,String salonid,String tarih) async {


    showProgressLoading(context);
    Map<String, dynamic> formData = {
      'id':masrafid,
      'masraf_tutari': masraf_tutari,
      'masraf_kategorisi':masraf_kategorisi.id,
      'masraf_notlari':masraf_notlari,
      'masraf_aciklama':masraf_notlari,
      'masraf_odeme_yontemi': masraf_odeme_yontemi.id,
      'harcayan': harcayan.id,
      'tarih':tarih,



      // Add other form fields
    };

    final response = await http.post(
      Uri.parse('https://app.randevumcepte.com.tr/api/v1/masrafekleduzenle/'+salonid),

      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(formData),
    );

    if (response.statusCode == 200) {


      Navigator.of(context,rootNavigator: true).pop();
      Navigator.of(context).pop();
      fetchData("1",'',true);

    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Masraf kaydı '+masrafid!='' ? 'güncellenirken' : 'eklenirken'+' bir hata oluştu! Hata kodu : '+response.statusCode.toString()),
        ),
      );
      debugPrint('Error: ${response.body}');
    }

  }
  Future<void> profilBilgiGuncelle(String profilid,String ad_soyad,String e_posta,String unvan,context,String salonid,String telefon_no,int cinsiyet,String sifre) async {


    showProgressLoading(context);
    Map<String, dynamic> formData = {
      'id':profilid,
      'adsoyad': ad_soyad,
      'e_posta':e_posta,
      'unvan':unvan,
      'telefon_no':telefon_no,
      'cinsiyet': cinsiyet,
      'sifre':sifre,


      // Add other form fields
    };

    final response = await http.post(
      Uri.parse('https://app.randevumcepte.com.tr/api/v1/bilgiguncelle/'+salonid),

      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(formData),
    );

    if (response.statusCode == 200) {


      Navigator.of(context,rootNavigator: true).pop();
      Navigator.of(context).pop();
      fetchData("1",'',true);

    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profil '+profilid!='' ? 'güncellenirken' : 'eklenirken'+' bir hata oluştu! Hata kodu : '+response.statusCode.toString()),
        ),
      );
      debugPrint('Error: ${response.body}');
    }

  }
  void showDetailsDialog(BuildContext context, Masraf masraf) {
    final _formKey = GlobalKey<FormState>();
    String odemeyontemi = '';
    if (masraf.odeme_yontemi_id == "1")
      odemeyontemi = 'Nakit';
    if (masraf.odeme_yontemi_id == "2")
      odemeyontemi = "Kredi Kartı";
    if (masraf.odeme_yontemi_id == "3")
      odemeyontemi = "Havale / EFT";
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
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: <Widget>[
                      SizedBox(height: 0,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(masraf.harcayan["personel_adi"],
                            style: TextStyle(fontWeight: FontWeight.bold),),
                        ],
                      ),
                      Divider(color: Colors.black,
                        height: 10,),
                      Row(
                        children: [
                          Text('Tarih'), SizedBox(width: 93,),
                          Text(' : '),
                          Text(formattedDate(masraf.tarih))
                        ],
                      ),
                      Row(
                        children: [
                          Text('Ödeme Yöntemi'),
                          SizedBox(width: 15,),
                          Text(' : '),
                          Expanded(child: Text(odemeyontemi))
                        ],

                      ),
                      Row(
                        children: [
                          Text('Tutar'), SizedBox(width: 90,),
                          Text(' : '),
                          Text(masraf.tutar.toString())
                        ],

                      ),
                      Row(
                        children: [
                          Text('Masfar Kategorisi'),
                          Text(' : '),
                          Text(masraf.masraf_kategorisi["kategori"].toString())
                        ],

                      ),
                      Divider(color: Colors.black,
                        height: 10,),


                      Text('Açıklama',
                        style: TextStyle(fontWeight: FontWeight.bold),),
                      Text(masraf.notlar != 'null' ? masraf.notlar : ''),
                      SizedBox(height: 10,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(onPressed: (){
                            Navigator.of(context, rootNavigator: true).pop();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => MasrafDuzenle(personeller: personelliste, masrafkategorileri: masrafkategoriliste, giderDataSource: this, seciliisletme: salonid, masraf: masraf, isletmebilgi:  isletmebilgi,)),
                            );
                          }, child:
                          Text('Düzenle'),
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
class MusteriDanisanDataSource extends DataGridSource {
  List<DataGridRow> _paginatedRows = [];

  int rowsPerPage;
  int currentPage;
  String arama;
  int totalPages = 1;
  int totalRows;
  String salonid;
  String durum;
  BuildContext context;
  int kullanicirolu;
  List<MusteriDanisan> musteridanisan = [];
  dynamic isletmebilgi;
  List<DataGridRow> paketRows = [];
  ValueNotifier<bool> isLoadingNotifier = ValueNotifier(false);




  MusteriDanisanDataSource({
    required this.rowsPerPage,
    required this.context,
    required this.salonid,
    required this.durum,
    required this.arama,
    required this.isletmebilgi,
    required this.kullanicirolu
  }) : currentPage = 1, totalRows = 0 {
    fetchData(page:currentPage.toString(),musteripaket: '',showProgress: true);
  }

  Future<void> fetchData({required String page, String musteripaket = '', bool showProgress = true}) async {
    print(page+' - '+ musteripaket);
    if(showProgress) showProgressLoading(context);
    isLoadingNotifier.value = true;

    // Backend’den veri çek
    final jsonResponse = await musteridanisanlistesi(salonid, page, musteripaket, durum);

    List<dynamic> data = jsonResponse['data'];
    musteridanisan = data.map((json) => MusteriDanisan.fromJson(json)).toList();

    // Önceki sayfa verilerini temizle
    _paginatedRows.clear();

    // Yeni sayfanın verilerini ekle
    _paginatedRows.addAll(musteridanisan.map((e) => DataGridRow(cells: [
      DataGridCell(columnName: 'musteripar', value: e),
      DataGridCell(columnName:'id', value:e.id.toString()),
      DataGridCell(columnName: 'musteridanisanadi', value: e.name),
      DataGridCell(columnName: 'ceptelefon', value: e.cep_telefon),
      DataGridCell(columnName: 'randevusayisi', value: e.randevu_sayisi),
    ])));

    totalPages = jsonResponse['last_page'] ?? 1;
    currentPage = jsonResponse['current_page'] ?? 1;

    isLoadingNotifier.value = false;
    if(showProgress) Navigator.of(context, rootNavigator: true).pop();

    notifyListeners(); // DataGrid’e yenilemesini söyle
  }

  void search(String musteridanisanadi){
    arama = musteridanisanadi;
    fetchData(page: '1', musteripaket: musteridanisanadi, showProgress: false);
  }

  void setPage(int page) {
    if(page > 0 && page <= totalPages) {
      fetchData(page: page.toString(), musteripaket: arama, showProgress: true);
    }
  }



  @override
  List<DataGridRow> get rows => _paginatedRows;


  @override
  DataGridRowAdapter buildRow(DataGridRow row) {

    return DataGridRowAdapter(cells: [


      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[0].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[1].value.toString()),
      ),  Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[2].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[3].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[4].value.toString()),
      ),
      Container(
          alignment: Alignment.center,
          child:PopupMenuButton<String>(
            onSelected: (String value) {
              if(value=='bilgi')
              {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => MusteriDetaylari(kullanicirolu: kullanicirolu, isletmebilgi:isletmebilgi,md: row.getCells()[0].value )),
                );
              }
              if(value=='duzenle')
              {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => MusteriDuzenle(kullanicirolu: kullanicirolu, isletmebilgi:isletmebilgi,md: row.getCells()[0].value )),
                );
              }
              if(value=='sil')
              {

                showMusteriSilmeConfirmationDialog(context,row.getCells()[1].value.toString(),this.salonid);
              }

            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'bilgi',
                child: Text('Detaylı Bilgi'),
              ),
              PopupMenuItem<String>(
                value: 'duzenle',
                child: Text('Düzenle'),
              ),
              PopupMenuItem<String>(
                value: 'sil',
                child: Text('Sil'),
              ),
            ],
          )
      )


    ]);


  }
  Future<bool?> showMusteriSilmeConfirmationDialog(BuildContext context, String id,String salonid)  {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Emin misiniz?'),
          content: Text('Veri silme işlemi geri alınamaz!'),
          actions: <Widget>[
            TextButton(
              child: Text('VAZGEÇ'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('SİL'),
              onPressed: () {
                musterisil(context,id,salonid);
              },
            ),
          ],
        );
      },
    );
  }
  Future<void> musterisil(BuildContext context, String id,String salonid) async {
    Map<String, dynamic> formData = {
      'salonid':salonid,
      'portfoy_id':id,
    };

    final response = await http.post(
      Uri.parse('https://app.randevumcepte.com.tr/api/v1/musterisil'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(formData),
    );

    if (response.statusCode == 200) {
      Navigator.of(context).pop();
      fetchData(page:currentPage.toString(),musteripaket: arama, showProgress: true);
    }
    else {

      debugPrint('Error: ${response.body}');
    }
  }

  void showDetailsDialog(BuildContext context, MusteriDanisan md) {
    final _formKey = GlobalKey<FormState>();

    String cinsiyet = "";
    String referans = "";
    if(md.cinsiyet=="0")
      cinsiyet = "Kadın";
    else if(md.cinsiyet=="1")
      cinsiyet = "Erkek";
    else
      cinsiyet = "Belirtilmemiş";
    if(md.musteri_tipi == "1")
      referans="İnternet";
    else if(md.musteri_tipi == "2")
      referans="Reklam";
    else if(md.musteri_tipi == "3")
      referans="Instagram";
    else if(md.musteri_tipi == "4")
      referans="Facebook";
    else if(md.musteri_tipi == "5")
      referans="Tanıdık";
    else
      referans="Belirtilmemiş";


    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          insetPadding: EdgeInsets.zero,
          content: Container(

            height: 350,
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
                          Text(md.name,style: TextStyle(fontWeight: FontWeight.bold),),
                        ],
                      ),
                      Divider(color: Colors.black,
                        height: 10,),


                      Row(
                        children: [
                          Text('Telefon'), SizedBox(width: 58,),
                          Text(':'),
                          Text(md.cep_telefon.toString())
                        ],
                      ),
                      Row(
                        children: [
                          Text('Kayıt Tarihi'), SizedBox(width: 33,),
                          Text(':'),
                          Text(md.kayit_tarihi)
                        ],
                      ),

                      Row(
                        children: [
                          Text('Son Randevusu'), SizedBox(width: 2,),
                          Text(':'),
                          Text(md.son_randevu_tarihi!= "null" ? md.son_randevu_tarihi:"")
                        ],
                      ),
                      Row(
                        children: [
                          Text('Randevu Sayısı'), SizedBox(width: 4,),

                          Text(':'),
                          Text(md.randevu_sayisi.toString())
                        ],

                      ),
                      Row(
                        children: [
                          Text('E-posta '), SizedBox(width: 54,),
                          Text(':'),
                          Expanded(
                              child:Text(md.eposta!="null"?md.eposta:"")
                          )
                        ],
                      ),
                      Row(
                        children: [
                          Text('Referans'), SizedBox(width: 48,),
                          Text(':'),
                          Text(referans)
                        ],
                      ),
                      Row(
                        children: [
                          Text('Doğum Tarihi'), SizedBox(width: 17,),
                          Text(':'),
                          Text(md.dogum_tarihi != "null" ? md.dogum_tarihi : "")
                        ],
                      ),
                      Row(
                        children: [
                          Text('Cinsiyet '), SizedBox(width: 51,),
                          Text(':'),
                          Text(cinsiyet)
                        ],
                      ),

                      Divider(color: Colors.black,
                        height: 5,),
                      Text('Notlar',style: TextStyle(fontWeight: FontWeight.bold),),
                      Text(md.ozel_notlar!="null"?md.ozel_notlar:""),
                      SizedBox(height: 40,),
                      Divider(color: Colors.black,),

                      Row(

                        children: [
                          ElevatedButton(onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => MusteriDuzenle(kullanicirolu: kullanicirolu, isletmebilgi:isletmebilgi,md: md,)),
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
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => MusteriDetaylari(kullanicirolu: kullanicirolu, isletmebilgi:isletmebilgi,md: md )),
                            );}, child:
                          Text('Detaylı Bilgi'),
                            style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.purple[800],
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
class EtkinlikDataSource extends DataGridSource{
  List<DataGridRow> _paginatedRows=[];
  int rowsPerPage;
  int currentPage;

  int totalPages=1;
  int totalRows;
  String salonid;
  String arama;

  BuildContext context;

  List<Etkinlik> etkinlik=[];

  ValueNotifier<bool> isLoadingNotifier=ValueNotifier(false);

  EtkinlikDataSource({
    required this.context,
    required this.rowsPerPage,
    required this.salonid,
    required this.arama,

  }):currentPage=1,totalRows=0{
    fetchData(currentPage.toString(), arama, true);
  }
  void search(String baslik)
  {
    currentPage = 1;
    fetchData("1",baslik,false);
  }
  Future<void> fetchData(String page,String baslik,bool showprogress) async{
    isLoadingNotifier.value=true;
    if(showprogress)
      showProgressLoading(context);
    notifyListeners();
    final jsonResponse =await etkinlikgetir(salonid, page.toString(),baslik);

    List<dynamic> data = jsonResponse['data'];
    etkinlik=data.map<Etkinlik>((json)=>Etkinlik.fromJson(json)).toList();
    if(_paginatedRows.length>0)
      _paginatedRows=[];

    etkinlik.forEach((e) {
      ++totalRows;
      _paginatedRows.add(
          DataGridRow(cells: [
            DataGridCell<Etkinlik>(columnName:'etkinlik',value:e),
            DataGridCell<String>(columnName:'id',value:e.id.toString()),
            DataGridCell<String>(columnName:'tarih_saat',value:e.tarih_saat.toString()),
            DataGridCell<String>(columnName:'etkinlik_adi',value:e.etkinlik_adi.toString()),
            DataGridCell<String>(columnName:'katilimcilar',value:e.katilimcilar.length.toString()),
            DataGridCell<String>(columnName: 'fiyat', value: e.fiyat != "null" ? e.fiyat.toString() : ''),
          ])
      );
    });

    totalPages=jsonResponse['last_page'];
    currentPage=jsonResponse['current_page'];
    isLoadingNotifier.value=false;
    if(showprogress)
      Navigator.of(context,rootNavigator: true).pop();
    notifyListeners();
  }

  void setPage(int page){
    if(page>0 && page<=totalPages){
      currentPage=page;
      fetchData(currentPage.toString(),"",true);
    }
  }

  @override
  List<DataGridRow> get rows=>_paginatedRows;





  @override
  DataGridRowAdapter? buildRow(DataGridRow row) {
    final colorAndText = getStatusColorAndText(row.getCells()[4].value.toString());
    return DataGridRowAdapter(cells: [

      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[0].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[1].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[2].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[3].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[4].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[5].value.toString()),
      ),

      Container(
          alignment: Alignment.center,
          child:PopupMenuButton<String>(
            onSelected: (String value) async {
              if(value=='duzenle')
              {

                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => EtkinlikDuzenle(etkinlikdetayi: row.getCells()[0].value, etkinlidatasource: this,)),
                );

              }
              if(value=='sil')
              {
                showEtkinlikSilmeConfirmationDialog(context,row.getCells()[1].value.toString());
              }


            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'duzenle',
                child: Text('Düzenle'),
              ),
              PopupMenuItem<String>(
                value: 'sil',
                child: Text('Sil'),
              ),

            ],
          )
      )


    ]);
  }

  Future<bool?> showEtkinlikSilmeConfirmationDialog(BuildContext context, String id)  {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Emin misiniz?'),
          content: Text('Veri silme işlemi geri alınamaz!'),
          actions: <Widget>[
            TextButton(
              child: Text('VAZGEÇ'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('SİL'),
              onPressed: () {
                etkinliksil(context,id);
              },
            ),
          ],
        );
      },
    );
  }
  Future<void> etkinliksil(BuildContext context, String id) async {
    Map<String, dynamic> formData = {
      'etkinlikid':id,
    };

    final response = await http.post(
      Uri.parse('https://app.randevumcepte.com.tr/api/v1/etkinlikpasifet'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(formData),
    );

    if (response.statusCode == 200) {
      Navigator.of(context).pop();
      fetchData(currentPage.toString(), arama, true);
    }
    else {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Etkinlik silinirken bir hata oluştu! Hata kodu : '+response.statusCode.toString()),
        ),
      );
      debugPrint('Error: ${response.body}');
    }
  }

  Future<void> etkinlikekleguncelle(String etkinlik_id,dynamic isletmebilgisi, String salonid,String etkinlik_adi,String etkinlik_tarih,String etkinlik_saat,String etkinlik_mesaj, String etkinlik_fiyat,List<MusteriDanisan> secilen_katilimcilar,context) async {

    SharedPreferences localStorage = await SharedPreferences.getInstance();
    log('Etkinlik adı : '+etkinlik_adi);
    var user = jsonDecode(localStorage.getString('user')!);
    Map<String, dynamic> formData = {
      'etkinlik_id':etkinlik_id,
      'etkinlik_adi':etkinlik_adi,
      'etkinlik_tarih': etkinlik_tarih,
      'etkinlik_saat': etkinlik_saat,
      'etkinlik_mesaj': etkinlik_mesaj,
      'etkinlik_fiyat':etkinlik_fiyat,
      'secilen_katilimcilar':jsonEncode(secilen_katilimcilar.map((itemler) => itemler.toJson()).toList()),


      // Add other form fields
    };
    log('formdata '+formData.toString());
    final response = await http.post(
      Uri.parse('https://app.randevumcepte.com.tr/api/v1/etkinlikekleduzenle/'+salonid.toString()),

      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(formData),
    );

    if (response.statusCode == 200) {
      log('etkinlik ekleme : '+response.body);

      Navigator.of(context).pop();
      fetchData("1", arama, false);

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => Etkinlikler(isletmebilgi: isletmebilgisi,)),
      );

    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Etkinlik eklenirken bir hata oluştu! Hata kodu : '+response.statusCode.toString()),
        ),
      );
      debugPrint('Error: ${response.body}');
    }
  }




}

class CihazDataSource extends DataGridSource {
  List<DataGridRow> _paginatedRows = [];
  int rowsPerPage;
  int currentPage;

  int totalPages = 1;
  int totalRows;
  String salonid;

  String baslik;

  BuildContext context;
  List<Cihaz> cihaz = [];


  ValueNotifier<bool> isLoadingNotifier = ValueNotifier(false);
  CihazDataSource({
    required this.rowsPerPage,
    required this.context,
    required this.salonid,

    required this.baslik,




  }) : currentPage = 1, totalRows = 0 {
    fetchData(currentPage.toString(),baslik,true);
  }
  void search(String baslik)
  {
    currentPage = 1;
    fetchData("1",baslik,false);
  }
  Future<void> fetchData(String page,String baslik,bool showprogress) async {

    isLoadingNotifier.value = true;
    if(showprogress)
      showProgressLoading(context);
    notifyListeners();
    final jsonResponse = await cihazgetir(salonid, page.toString(),baslik);

    List<dynamic> data = jsonResponse['data'];
    cihaz = data.map<Cihaz>((json) => Cihaz.fromJson(json)).toList();
    if(_paginatedRows.length>0)
      _paginatedRows = [];

    cihaz.forEach((e) {

      ++totalRows;
      _paginatedRows.add(
          DataGridRow(cells: [
            DataGridCell<Cihaz>(columnName: 'cihaz', value: e),
            DataGridCell<String>(columnName: 'id', value: e.id.toString()),
            DataGridCell<String>(columnName: 'cihazadi', value:e.cihaz_adi.toString() ),
            DataGridCell<String>(columnName: 'durum', value: e.durum.toString()),
            DataGridCell<String>(columnName: 'aciklama', value: e.aciklama != "null" ? e.aciklama.toString() : ''),


          ])
      );
    });
    totalPages = jsonResponse['last_page'];
    currentPage = jsonResponse['current_page'];
    isLoadingNotifier.value = false;
    if(showprogress)
      Navigator.of(context, rootNavigator: true).pop();// Notify listeners that loading has finished
    notifyListeners();
  }

  void setPage(int page) {
    if (page > 0 && page <= totalPages) {
      currentPage = page;

      fetchData(currentPage.toString(),"",true);
    }
  }


  ColorAndText getStatusColorAndText(String durum) {
    print('Durum: $durum');


    if (durum == '0') {
      return ColorAndText(Colors.red[600]!, 'Müsait Değil',);
    }
    else {
      return ColorAndText(Colors.green, 'Müsait');
    }



  }
  @override
  List<DataGridRow> get rows => _paginatedRows;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    final colorAndText = getStatusColorAndText(row.getCells()[3].value.toString());
    return DataGridRowAdapter(cells: [

      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[0].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[1].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[2].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[3].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(3.0),
        child:  ElevatedButton(
          onPressed: () {


          },
          style: ElevatedButton.styleFrom(
            backgroundColor: colorAndText.color,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
            minimumSize: Size(100, 20),
          ),
          child: Text(
            colorAndText.text,
            style: TextStyle(color: Colors.white,fontSize: 12),
          ),
        ),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[4].value.toString()),
      ),


      Container(
          alignment: Alignment.center,
          child:PopupMenuButton<String>(
            onSelected: (String value) async {
              if(value=='musait')
              {
                log("cihazid"+row.getCells()[1].value);
                cihazmusait(context, row.getCells()[1].value);

              }
              if(value=='musaitdegil')
              {
                showCheckboxPopup(context, row.getCells()[1].value);

              }
              if(value=='sil')
              {
                showCihazSilmeConfirmationDialog(context,row.getCells()[1].value.toString());
              }


            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'musait',
                child: Text('Musait'),
              ),
              PopupMenuItem<String>(
                value: 'musaitdegil',
                child: Text('Müsait Değil'),
              ),
              PopupMenuItem<String>(
                value: 'sil',
                child: Text('Sil'),
              ),

            ],
          )
      )


    ]);


  }
  Future<bool?> showCihazSilmeConfirmationDialog(BuildContext context, String id)  {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Emin misiniz?'),
          content: Text('Veri silme işlemi geri alınamaz!'),
          actions: <Widget>[
            TextButton(
              child: Text('VAZGEÇ'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('SİL'),
              onPressed: () {
                cihazsil
                  (context, id);
              },
            ),
          ],
        );
      },
    );
  }
  Future<void> cihazsil(BuildContext context, String id) async {


    Map<String, dynamic> formData = {
      'cihaz_id':id,
    };

    final response = await http.post(
      Uri.parse('https://app.randevumcepte.com.tr/api/v1/cihaz_sil'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(formData),
    );

    if (response.statusCode == 200) {
      Navigator.of(context).pop();
      fetchData(currentPage.toString(), baslik, false);
    }
    else {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Notunuz silinirken bir hata oluştu! Hata kodu : '+response.statusCode.toString()),
        ),
      );
      debugPrint('Error: ${response.body}');
    }
  }
  void cihazmusait(BuildContext context, String cihazid) async {

    showProgressLoading(context);
    Map<String, dynamic> formData = {
      'cihaz_id': cihazid,
    };

    final response = await http.post(
      Uri.parse('https://app.randevumcepte.com.tr/api/v1/cihazmusaitisaretle'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(formData),
    );

    if (response.statusCode == 200) {
      Navigator.of(context, rootNavigator: true).pop();
      fetchData(currentPage.toString(), baslik, false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cihaz müsait edlirken bir hata oluştu! Hata kodu : ' + response.statusCode.toString()),
        ),
      );
      debugPrint(response.body);
    }
  }
  void cihazmusaitdegil(BuildContext context, String cihazid,String aciklama) async {

    showProgressLoading(context);
    Map<String, dynamic> formData = {
      'cihaz_id': cihazid,
      'aciklama': aciklama,
    };

    final response = await http.post(
      Uri.parse('https://app.randevumcepte.com.tr/api/v1/cihazmusaitdegilisaretle'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(formData),
    );

    if (response.statusCode == 200) {
      Navigator.of(context).pop();
      fetchData(currentPage.toString(), baslik, false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cihaz müsait edlirken bir hata oluştu! Hata kodu : ' + response.statusCode.toString()),
        ),
      );
      debugPrint(response.body);
    }
  }
  Future<void> cihazekle(String cihazadi,String salonId, calisiyor1,  calisiyor2,  calisiyor3,  calisiyor4,  calisiyor5,  calisiyor6,  calisiyor7,
      String baslangic1, String baslangic2, String baslangic3, String baslangic4, String baslangic5, String baslangic6, String baslangic7,
      String bitis1, String bitis2, String bitis3, String bitis4, String bitis5, String bitis6, String bitis7,
      calisiyor8,  calisiyor9,  calisiyor10,  calisiyor11,  calisiyor12,  calisiyor13,  calisiyor14,
      String baslangic8, String baslangic9, String baslangic10, String baslangic11, String baslangic12, String baslangic13, String baslangic14,
      String bitis8, String bitis9, String bitis10, String bitis11, String bitis12, String bitis13, String bitis14,
      BuildContext context) async {
    final Map<String, dynamic> formData = {
      'isletme_id': salonId,
      'cihaz_adi':cihazadi,
      'calisiyor1': calisiyor1 == true ? 1 : 0,
      'calisiyor2': calisiyor2 == true ? 1 : 0,
      'calisiyor3': calisiyor3 == true ? 1 : 0,
      'calisiyor4': calisiyor4 == true ? 1 : 0,
      'calisiyor5': calisiyor5 == true ? 1 : 0,
      'calisiyor6': calisiyor6 == true ? 1 : 0,
      'calisiyor7': calisiyor7 == true ? 1 : 0,
      'cihaz_baslangicsaati1': baslangic1,
      'cihaz_baslangicsaati2': baslangic2,
      'cihaz_baslangicsaati3': baslangic3,
      'cihaz_baslangicsaati4': baslangic4,
      'cihaz_baslangicsaati5': baslangic5,
      'cihaz_baslangicsaati6': baslangic6,
      'cihaz_baslangicsaati7': baslangic7,
      'cihaz_bitissaati1': bitis1,
      'cihaz_bitissaati2': bitis2,
      'cihaz_bitissaati3': bitis3,
      'cihaz_bitissaati4': bitis4,
      'cihaz_bitissaati5': bitis5,
      'cihaz_bitissaati6': bitis6,
      'cihaz_bitissaati7': bitis7,
      'mola1': calisiyor1 == true ? 1 : 0,
      'mola2': calisiyor2 == true ? 1 : 0,
      'mola3': calisiyor3 == true ? 1 : 0,
      'mola4': calisiyor4 == true ? 1 : 0,
      'mola5': calisiyor5 == true ? 1 : 0,
      'mola6': calisiyor6 == true ? 1 : 0,
      'mola7': calisiyor7 == true ? 1 : 0,
      'cihaz_molabaslangicsaati1': baslangic8,
      'cihaz_molabaslangicsaati2': baslangic9,
      'cihaz_molabaslangicsaati3': baslangic10,
      'cihaz_molabaslangicsaati4': baslangic11,
      'cihaz_molabaslangicsaati5': baslangic12,
      'cihaz_molabaslangicsaati6': baslangic13,
      'cihaz_molabaslangicsaati7': baslangic14,
      'cihaz_molabitissaati1': bitis8,
      'cihaz_molabitissaati2': bitis9,
      'cihaz_molabitissaati3': bitis10,
      'cihaz_molabitissaati4': bitis11,
      'cihaz_molabitissaati5': bitis12,
      'cihaz_molabitissaati6': bitis13,
      'cihaz_molabitissaati7': bitis14,



    };
    final queryParameters = formData.entries.map((e) => '${e.key}=${e.value}')
        .join('&');

    final response = await http.get(
      Uri.parse(
          'https://app.randevumcepte.com.tr/api/v1/cihazekle/$salonId?$queryParameters'),

      headers: {'Content-Type': 'application/json'},


    );
    debugPrint('Response status: ${response.statusCode}');
    debugPrint('Response body: ${response.body}');

    if (response.statusCode == 200) {
      log('etkinlik güncelleme : ' + response.body);
      Navigator.of(context).pop();
      fetchData("1", baslik, false);

    } else {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(' ${response.statusCode} '),
        ),
      );

    }
  }
  void showDetailsDialog(BuildContext context, Cihaz cihaz) {
    final _formKey = GlobalKey<FormState>();
    String durum="";
    if(cihaz.durum=="0")
      durum="Müsait Değil";
    else if(cihaz.durum=="1")
      durum="Müsait";

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
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: <Widget>[
                      SizedBox(height: 20,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(cihaz.cihaz_adi,
                            style: TextStyle(fontWeight: FontWeight.bold,fontSize: 20),),
                        ],
                      ),
                      Divider(color: Colors.black,
                        height: 10,),
                      Row(
                        children: [
                          Text('Durum'), SizedBox(width: 27,),
                          Text(':'),
                          Text(durum)
                        ],
                      ),
                      Row(
                        children: [
                          Text('Açıklama'),
                          SizedBox(width: 5,),
                          Text(': '),
                          Expanded(child: Text(cihaz.aciklama!="null"?cihaz.aciklama:""
                          ))
                        ],

                      ),
                      SizedBox(height: 60,),

                      Divider(color: Colors.black,
                        height: 20,),

                      Row(
                        children: [

                          ElevatedButton(onPressed: () {}, child:
                          Text('Müsait'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                elevation: 5,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5.0)
                                ),
                                minimumSize: Size(130, 30)
                            ),
                          ),
                          SizedBox(width: 15,),
                          ElevatedButton(onPressed: () {

                          }, child:
                          Text('Müsait Değil'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple[800],
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
  void showCheckboxPopup(BuildContext context, String cihazId) {
    TextEditingController aciklamaController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              scrollable: true,
              title: Text('Müsait Değil'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 10,),
                    Padding(
                      padding: const EdgeInsets.only(left: 0.0),
                      child: Text('Açıklama', style: TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold),),
                    ),
                    SizedBox(height: 10,),
                    Container(
                      height: 110,
                      child: TextField(
                        controller: aciklamaController,  // Set the controller
                        keyboardType: TextInputType.text,
                        maxLines: 6,
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
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Kapat', style: TextStyle(color: Colors.black)),
                ),
                TextButton(
                  onPressed: () {
                    cihazmusaitdegil(context, cihazId, aciklamaController.text);
                  },
                  child: Text('Kaydet', style: TextStyle(color: Colors.purple[800])),
                ),
              ],
            );
          },
        );
      },
    );
  }

}

class OdaDataSource extends DataGridSource {
  List<DataGridRow> _paginatedRows = [];
  int rowsPerPage;
  int currentPage;

  int totalPages = 1;
  int totalRows;
  String salonid;

  String baslik;

  BuildContext context;
  List<Oda> oda = [];


  ValueNotifier<bool> isLoadingNotifier = ValueNotifier(false);
  OdaDataSource({
    required this.rowsPerPage,
    required this.context,
    required this.salonid,

    required this.baslik,




  }) : currentPage = 1, totalRows = 0 {
    fetchData(currentPage.toString(),baslik,true);
  }
  void search(String baslik)
  {
    currentPage = 1;
    fetchData("1",baslik,false);
  }
  Future<void> fetchData(String page,String baslik,bool showprogress) async {

    isLoadingNotifier.value = true;
    if(showprogress)
      showProgressLoading(context);
    notifyListeners();
    final jsonResponse = await odagetir(salonid, page.toString(),baslik);

    List<dynamic> data = jsonResponse['data'];
    oda = data.map<Oda>((json) => Oda.fromJson(json)).toList();
    if(_paginatedRows.length>0)
      _paginatedRows = [];

    oda.forEach((e) {

      ++totalRows;
      _paginatedRows.add(
          DataGridRow(cells: [
            DataGridCell<Oda>(columnName: 'oda', value: e),
            DataGridCell<String>(columnName: 'id', value: e.id.toString()),
            DataGridCell<String>(columnName: 'odaadi', value:e.oda_adi.toString() ),
            DataGridCell<String>(columnName: 'durum', value: e.durum.toString()),
            DataGridCell<String>(columnName: 'aciklama', value: e.aciklama != "null" ? e.aciklama.toString() : ''),


          ])
      );
    });
    totalPages = jsonResponse['last_page'];
    currentPage = jsonResponse['current_page'];
    isLoadingNotifier.value = false;
    if(showprogress)
      Navigator.of(context, rootNavigator: true).pop();// Notify listeners that loading has finished
    notifyListeners();
  }

  void setPage(int page) {
    if (page > 0 && page <= totalPages) {
      currentPage = page;

      fetchData(currentPage.toString(),"",true);
    }
  }


  ColorAndText getStatusColorAndText(String durum) {
    print('Durum: $durum');


    if (durum == '0') {
      return ColorAndText(Colors.red[600]!, 'Müsait Değil',);
    }
    else {
      return ColorAndText(Colors.green, 'Müsait');
    }



  }
  @override
  List<DataGridRow> get rows => _paginatedRows;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    final colorAndText = getStatusColorAndText(row.getCells()[3].value.toString());
    return DataGridRowAdapter(cells: [

      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[0].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[1].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[2].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[3].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(3.0),
        child:  ElevatedButton(
          onPressed: () {


          },
          style: ElevatedButton.styleFrom(
            backgroundColor: colorAndText.color,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
            minimumSize: Size(100, 20),
          ),
          child: Text(
            colorAndText.text,
            style: TextStyle(color: Colors.white,fontSize: 12),
          ),
        ),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[4].value.toString()),
      ),


      Container(
          alignment: Alignment.center,
          child:PopupMenuButton<String>(
            onSelected: (String value) async {
              if(value=='musait')
              {
                log("odaid"+row.getCells()[1].value);
                odamusait(context, row.getCells()[1].value);

              }
              if(value=='musaitdegil')
              {
                showCheckboxPopup(context, row.getCells()[1].value);

              }
              if(value=='sil')

              {
                log(row.getCells()[1].value);
                showOdaSilmeConfirmationDialog(context,row.getCells()[1].value.toString());
              }


            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'musait',
                child: Text('Musait'),
              ),
              PopupMenuItem<String>(
                value: 'musaitdegil',
                child: Text('Müsait Değil'),
              ),
              PopupMenuItem<String>(
                value: 'sil',
                child: Text('Sil'),
              ),

            ],
          )
      )


    ]);


  }
  Future<bool?> showOdaSilmeConfirmationDialog(BuildContext context, String id)  {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Emin misiniz?'),
          content: Text('Veri silme işlemi geri alınamaz!'),
          actions: <Widget>[
            TextButton(
              child: Text('VAZGEÇ'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('SİL'),
              onPressed: () {
                odasil
                  (context, id);
              },
            ),
          ],
        );
      },
    );
  }
  Future<void> odaekle(String odaadi,String salonId,
      BuildContext context) async {
    final Map<String, dynamic> formData = {
      'isletme_id': salonId,
      'oda_adi':odaadi,




    };
    final queryParameters = formData.entries.map((e) => '${e.key}=${e.value}')
        .join('&');

    final response = await http.get(
      Uri.parse(
          'https://app.randevumcepte.com.tr/api/v1/odaekleduzenle/$salonId?$queryParameters'),

      headers: {'Content-Type': 'application/json'},


    );
    debugPrint('Response status: ${response.statusCode}');
    debugPrint('Response body: ${response.body}');

    if (response.statusCode == 200) {
      log('etkinlik güncelleme : ' + response.body);
      Navigator.of(context).pop();
      fetchData("1", baslik, false);

    } else {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${response.statusCode} '),
        ),
      );
      debugPrint('Failed to load data. Status code: ${response.statusCode}');
      throw Exception('Failed to load data: ${response.reasonPhrase}');
    }
  }
  Future<void> odasil(BuildContext context, String id) async {


    Map<String, dynamic> formData = {
      'oda_id':id,
    };

    final response = await http.post(
      Uri.parse('https://app.randevumcepte.com.tr/api/v1/oda_sil'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(formData),
    );

    if (response.statusCode == 200) {
      Navigator.of(context).pop();
      fetchData(currentPage.toString(), baslik, false);
    }
    else {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Notunuz silinirken bir hata oluştu! Hata kodu : '+response.statusCode.toString()),
        ),
      );
      debugPrint('Error: ${response.body}');
    }
  }
  void odamusait(BuildContext context, String odaid) async {

    showProgressLoading(context);
    Map<String, dynamic> formData = {
      'oda_id': odaid,
    };

    final response = await http.post(
      Uri.parse('https://app.randevumcepte.com.tr/api/v1/odamusaitisaretle'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(formData),
    );

    if (response.statusCode == 200) {
      Navigator.of(context, rootNavigator: true).pop();
      fetchData(currentPage.toString(), baslik, false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cihaz müsait edlirken bir hata oluştu! Hata kodu : ' + response.statusCode.toString()),
        ),
      );
      debugPrint(response.body);
    }
  }
  void odamusaitdegil(BuildContext context, String odaid,String aciklama) async {

    showProgressLoading(context);
    Map<String, dynamic> formData = {
      'oda_id': odaid,
      'aciklama': aciklama,
    };

    final response = await http.post(
      Uri.parse('https://app.randevumcepte.com.tr/api/v1/odamusaitdegilisaretle'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(formData),
    );

    if (response.statusCode == 200) {
      Navigator.of(context).pop();
      fetchData(currentPage.toString(), baslik, false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cihaz müsait edlirken bir hata oluştu! Hata kodu : ' + response.statusCode.toString()),
        ),
      );
      debugPrint(response.body);
    }
  }

  void showDetailsDialog(BuildContext context, Oda oda) {
    final _formKey = GlobalKey<FormState>();
    String durum="";
    if(oda.durum=="0")
      durum="Müsait Değil";
    else if(oda.durum=="1")
      durum="Müsait";

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
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: <Widget>[
                      SizedBox(height: 20,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(oda.oda_adi,
                            style: TextStyle(fontWeight: FontWeight.bold,fontSize: 20),),
                        ],
                      ),
                      Divider(color: Colors.black,
                        height: 10,),
                      Row(
                        children: [
                          Text('Durum'), SizedBox(width: 27,),
                          Text(':'),
                          Text(durum)
                        ],
                      ),
                      Row(
                        children: [
                          Text('Açıklama'),
                          SizedBox(width: 5,),
                          Text(': '),
                          Expanded(child: Text(oda.aciklama!="null"?oda.aciklama:""
                          ))
                        ],

                      ),
                      SizedBox(height: 60,),

                      Divider(color: Colors.black,
                        height: 20,),

                      Row(
                        children: [

                          ElevatedButton(onPressed: () {}, child:
                          Text('Müsait'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                elevation: 5,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5.0)
                                ),
                                minimumSize: Size(130, 30)
                            ),
                          ),
                          SizedBox(width: 15,),
                          ElevatedButton(onPressed: () {

                          }, child:
                          Text('Müsait Değil'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple[800],
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
  void showCheckboxPopup(BuildContext context, String cihazId) {
    TextEditingController aciklamaController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              scrollable: true,
              title: Text('Müsait Değil'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 10,),
                    Padding(
                      padding: const EdgeInsets.only(left: 0.0),
                      child: Text('Açıklama', style: TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold),),
                    ),
                    SizedBox(height: 10,),
                    Container(
                      height: 110,
                      child: TextField(
                        controller: aciklamaController,  // Set the controller
                        keyboardType: TextInputType.text,
                        maxLines: 6,
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
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Kapat', style: TextStyle(color: Colors.black)),
                ),
                TextButton(
                  onPressed: () {
                    odamusaitdegil(context, cihazId, aciklamaController.text);
                  },
                  child: Text('Kaydet', style: TextStyle(color: Colors.purple[800])),
                ),
              ],
            );
          },
        );
      },
    );
  }

}
class SatisDataSource extends DataGridSource {
  bool musteriMi;
  bool personelMi;
  int kullanicirolu;
  int rowsPerPage;
  int currentPage;
  int totalPages = 1;
  int totalRows;
  String tarih1;
  String tarih2;
  String tur;
  String musteriid;
  String userid;
  BuildContext context;
  String personelid;
  dynamic isletmebilgi;
  List<Adisyon> adisyon = [];

  List<DataGridRow> _paginatedRows = [];
  ValueNotifier<bool> isLoadingNotifier = ValueNotifier(false);

  String salonid;

  SatisDataSource({
    required this.musteriMi,
    required this.context,
    required this.isletmebilgi,
    required this.rowsPerPage,
    required this.salonid,
    required this.tarih1,
    required this.tarih2,
    required this.musteriid,
    required this.tur,
    required this.personelid,
    required this.userid,
    required this.personelMi,
    required this.kullanicirolu,


  }): currentPage = 1, totalRows = 0 {
    fetchData(currentPage.toString(),tarih1,tarih2,musteriid,tur,false,personelid);
  }

  Future<void> fetchData(String page,String tarih1,String tarih2,String musteriid,String tur,bool showprogress,String personelid) async {

    isLoadingNotifier.value = true;
    if(showprogress)
      showProgressLoading(context);
    notifyListeners();
    final jsonResponse = await satislar(salonid, page.toString(),tarih1, tarih2, musteriid,tur,personelid,musteriMi,userid,0);

    List<dynamic> data = jsonResponse['data'];
    adisyon = data.map<Adisyon>((json) => Adisyon.fromJson(json)).toList();
    if(_paginatedRows.length>0)
      _paginatedRows = [];

    adisyon.forEach((e) {

      String icerik = e.icerik;
      ++totalRows;

      _paginatedRows.add(
          DataGridRow(cells: [
            DataGridCell<Adisyon>(columnName: 'satis',value: e),
            DataGridCell<String>(columnName: 'id', value: e.id),
            DataGridCell<String>(
              columnName: 'musteridanisantarih',
              value: musteriMi ?  e.icerik + '\n'+e.acilis_tarihi :
                  e.musteri + '\n'+ e.icerik + '\n'+e.acilis_tarihi
            ),


            DataGridCell<String>(columnName: 'toplam', value: e.toplam),
            DataGridCell<String>(columnName: 'odenen', value: e.odenen),
            DataGridCell<String>(columnName: 'kalan', value: e.kalan_tutar),

          ])
      );

    });


    totalPages = jsonResponse['last_page'];
    currentPage = jsonResponse['current_page'];
    isLoadingNotifier.value = false;
    if(showprogress)
      Navigator.of(context, rootNavigator: true).pop();// Notify listeners that loading has finished
    notifyListeners();



  }
  void showDetailsDialog(BuildContext context, Adisyon adisyon) {
    List<AdisyonKalemleri> adisyonkalemleri = []; // Populate this list as needed
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
                      child: Icon(Icons.close),
                    ),
                  ),
                ),
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      SizedBox(height: 20),
                      Text(
                        adisyon.musteri,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Divider(
                        color: Colors.black,
                        height: 10,
                      ),


                    ],
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  void search(String tarih1,String tarih2,String musteriid,String tur,bool progressshow)
  {
    currentPage = 1;

    fetchData("1",tarih1,tarih2,musteriid,tur,progressshow,personelid);
  }
  void setPage(int page,String tarih1, String tarih2, String musteriid,String tur) {
    if (page > 0 && page <= totalPages) {
      currentPage = page;

      fetchData(currentPage.toString(),tarih1,tarih2,musteriid,tur,true,personelid);
    }
  }
  @override
  List<DataGridRow> get rows => _paginatedRows;


  @override
  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    final Adisyon adisyon = row.getCells()[0].value; // Adisyon nesnesini al

    return DataGridRowAdapter(cells: [
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(2.0),
        child: Text(adisyon.toString()), // Adisyon'ın toString metodunu kullan
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(2.0),
        child: Text(row.getCells()[1].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(2.0),
        child: Text(row.getCells()[2].value.toString(), style: TextStyle(fontSize: 12)),
      ),
      Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.all(2.0),
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            if (!musteriMi && !personelMi )
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => TahsilatEkrani(
                    adisyonId: adisyon.id,
                    kullanicirolu: kullanicirolu,
                    isletmebilgi: isletmebilgi,
                    musteridanisanid: adisyon.user_id, // Doğrudan property'yi kullan
                  ),
                ),
              );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple[800],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
            minimumSize: Size(double.infinity, 20),
          ),
          child: Text(
            row.getCells()[3].value.toString(),
            style: TextStyle(color: Colors.white, fontSize: 11),
            maxLines: 1,
          ),
        ),
      ),
      Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.all(2.0),
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            if (!musteriMi && !personelMi)
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => TahsilatEkrani(
                    adisyonId: adisyon.id,
                    kullanicirolu: kullanicirolu,
                    isletmebilgi: isletmebilgi,
                    musteridanisanid: adisyon.user_id, // Doğrudan property'yi kullan
                  ),
                ),
              );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
            minimumSize: Size(double.infinity, 20),
          ),
          child: Text(
            row.getCells()[4].value.toString(),
            style: TextStyle(color: Colors.white, fontSize: 11),
            maxLines: 1,
          ),
        ),
      ),
      Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.all(2.0),
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            if (!musteriMi && !personelMi)
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>  TahsilatEkrani(
                    adisyonId: adisyon.id,
                    kullanicirolu: kullanicirolu,
                    isletmebilgi: isletmebilgi,
                    musteridanisanid: adisyon.user_id, // Doğrudan property'yi kullan
                  ),
                ),
              );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[600],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
            minimumSize: Size(double.infinity, 20),
          ),
          child: Text(
            row.getCells()[5].value.toString(),
            style: TextStyle(color: Colors.white, fontSize: 11),
            maxLines: 1,
          ),
        ),
      ),
    ]);
  }

}
class PersonelDataSource extends DataGridSource{

  List<DataGridRow> _paginatedRows = [];
  int rowsPerPage;
  int currentPage;

  int totalPages = 1;
  int totalRows;
  String salonid;

  String baslik;
  dynamic isletmebilgi;
  bool showYukleniyor;
  int kullanicirolu;
  BuildContext context;
  List<Personel> personel = [];

  ValueNotifier<bool> isLoadingNotifier = ValueNotifier(false);
  PersonelDataSource({
    required this.rowsPerPage,
    required this.context,
    required this.salonid,
    required this.isletmebilgi,
    required this.baslik,
    required this.showYukleniyor,
    required this.kullanicirolu,




  }) : currentPage = 1, totalRows = 0 {
    fetchData(currentPage.toString(),baslik,showYukleniyor);
  }
  void search(String baslik)
  {
    currentPage = 1;
    fetchData("1",baslik,false);
  }
  Future<void> fetchData(String page,String baslik,bool showprogress) async {

    isLoadingNotifier.value = true;
    if(showprogress)
      showProgressLoading(context);
    notifyListeners();
    final jsonResponse = await personelgetir(salonid, page.toString(),baslik);

    List<dynamic> data = jsonResponse['data'];
    personel = data
        .map<Personel>((json) => Personel.fromJson(json))
        .toSet()
        .toList();
    if(_paginatedRows.length>0)
      _paginatedRows = [];

    personel.forEach((e) {

      ++totalRows;
      _paginatedRows.add(
          DataGridRow(cells: [
            DataGridCell<Personel>(columnName: 'personel', value: e),
            DataGridCell<String>(columnName: 'id', value: e.id.toString()),
            DataGridCell<String>(columnName: 'personeladi', value:e.personel_adi.toString() ),
            DataGridCell<String>(columnName: 'telefon', value:e.cep_telefon.toString() ),
            DataGridCell<String>(columnName: 'durum', value: e.durum.toString()),



          ])
      );
    });
    totalPages = jsonResponse['last_page'];
    currentPage = jsonResponse['current_page'];
    isLoadingNotifier.value = false;
    if(showprogress)
      Navigator.of(context, rootNavigator: true).pop();// Notify listeners that loading has finished
    notifyListeners();
  }

  void setPage(int page, [String? searchText]) {
    if (page > 0 && page <= totalPages) {
      currentPage = page;
      // Eğer searchText verilmişse onu kullan, yoksa mevcut arama terimini kullan
      String search = searchText ?? '';
      fetchData(currentPage.toString(), search, true);
    }
  }

  ColorAndText getStatusColorAndText(String durum) {
    print('Durum: $durum');


    if (durum == '0') {
      return ColorAndText(Colors.red[600]!, 'Pasif',);
    }
    else {
      return ColorAndText(Colors.green, 'Aktif');
    }



  }
  @override
  List<DataGridRow> get rows => _paginatedRows;

  @override
  DataGridRowAdapter? buildRow(DataGridRow row) {
    final colorAndText = getStatusColorAndText(row.getCells()[4].value.toString());
    final currentStatus = row.getCells()[4].value.toString(); // Assuming status is stored in cell[4]
    return DataGridRowAdapter(cells: [

      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[0].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[1].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[2].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[3].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[4].value.toString()),
      ),

      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(3.0),
        child:  ElevatedButton(
          onPressed: () {


          },
          style: ElevatedButton.styleFrom(
            backgroundColor: colorAndText.color,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
            minimumSize: Size(100, 20),
          ),
          child: Text(
            colorAndText.text,
            style: TextStyle(color: Colors.white,fontSize: 12),
          ),
        ),
      ),


      Container(
          alignment: Alignment.center,
          child:PopupMenuButton<String>(
            onSelected: (String value) async {

              if(value=='duzenle')
              {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => PersonelDuzenle(per: row.getCells()[0].value,isletmebilgi:isletmebilgi, personeldata: this,)),
                );

              }
              if(value=='satislar')
              {
                if(value=='satislar')
                {

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => PersonelSatislari(kullanicirolu: kullanicirolu, kullanici: row.getCells()[0].value,isletmebilgi:isletmebilgi)),
                  );
                }

              }
              if(value=='sifre')
              {
                personelsifre(context, row.getCells()[1].value);

              }
              if(value=='aktif')
              {
                personelaktif(context, row.getCells()[1].value);
              }
              if(value=='pasif')
              {
                personelpasif(context, row.getCells()[1].value);
              }



            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[

              PopupMenuItem<String>(
                value: 'duzenle',
                child: Text('Düzenle'),
              ),
              PopupMenuItem<String>(
                value: 'satislar',
                child: Text('Personel Satışları'),
              ),
              PopupMenuItem<String>(
                value: 'sifre',
                child: Text('Şifre Değiştir'),
              ),
              PopupMenuItem<String>(
                value: currentStatus == '1' ? 'pasif' : 'aktif', // Show appropriate action
                child: Text(currentStatus == '1' ? 'Pasif Yap' : 'Aktif Yap'),
              ),

            ],
          )
      )


    ]);
  }
  void personelsifre(BuildContext context, String personelid) async {

    showProgressLoading(context);
    Map<String, dynamic> formData = {
      'personelid': personelid,
    };

    final response = await http.post(
      Uri.parse('https://app.randevumcepte.com.tr/api/v1/personelsifregonder'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(formData),
    );

    if (response.statusCode == 200) {
      Navigator.of(context, rootNavigator: true).pop();
      fetchData(currentPage.toString(), baslik, false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Şifre SMS olarak gönderildi.'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Personel aktif edlirken bir hata oluştu! Hata kodu : ' + response.statusCode.toString()),
        ),
      );
      debugPrint(response.body);
    }
  }
  void personelaktif(BuildContext context, String personelid) async {

    showProgressLoading(context);
    Map<String, dynamic> formData = {
      'personelid': personelid,
    };

    final response = await http.post(
      Uri.parse('https://app.randevumcepte.com.tr/api/v1/personelaktifyap'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(formData),
    );

    if (response.statusCode == 200) {
      Navigator.of(context, rootNavigator: true).pop();
      fetchData(currentPage.toString(), baslik, false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Personel aktif edlirken bir hata oluştu! Hata kodu : ' + response.statusCode.toString()),
        ),
      );
      debugPrint(response.body);
    }
  }
  void personelpasif(BuildContext context, String personelid) async {

    showProgressLoading(context);
    Map<String, dynamic> formData = {
      'personelid': personelid,
    };

    final response = await http.post(
      Uri.parse('https://app.randevumcepte.com.tr/api/v1/personelpasifyap'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(formData),
    );

    if (response.statusCode == 200) {
      Navigator.of(context, rootNavigator: true).pop();
      fetchData(currentPage.toString(), baslik, false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Personel aktif edlirken bir hata oluştu! Hata kodu : ' + response.statusCode.toString()),
        ),
      );
      debugPrint(response.body);
    }
  }


  void showDetailsDialog(BuildContext context, Personel personel) async{
    dynamic primler = await personelprimhesapla(context,personel.id,salonid);
    log(primler["hizmet_hakedis"]);
    final _formKey = GlobalKey<FormState>();
    String hesapturu="";
    String durum="";
    if(personel.durum=="0")
      durum="Pasif";
    else if(personel.durum=="1")
      durum="Aktif";

    if(personel.hesap_turu=='1')
      hesapturu="Hesap Sahibi";
    else if(personel.hesap_turu=='2')
      hesapturu="Süpervizör";
    else if(personel.hesap_turu=='3')
      hesapturu="Yönetici";
    else if(personel.hesap_turu=='4')
      hesapturu="Sekreter";
    else if(personel.hesap_turu=='5')
      hesapturu="Personel";
    else if(personel.hesap_turu=='7')
      hesapturu="Sanat Yönetmeni";
    else if(personel.hesap_turu=='8')
      hesapturu="Sosyal Medya Uzmanı";

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          insetPadding: EdgeInsets.zero,
          content: Container(

            height: 500,
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
                      SizedBox(height: 20,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(personel.personel_adi,
                            style: TextStyle(fontWeight: FontWeight.bold,fontSize: 20),),
                        ],
                      ),
                      Divider(color: Colors.black,
                        height: 10,),
                      Row(
                        children: [
                          Text('Telefon'), SizedBox(width: 27,),
                          Text(': '),
                          Text(personel.cep_telefon)
                        ],
                      ),
                      Row(
                        children: [
                          Text('Hesap Tipi'),
                          SizedBox(width: 5,),
                          Text(': '),
                          Expanded(child: Text(hesapturu))
                        ],

                      ),
                      Row(
                        children: [
                          Text('Unvan'),
                          SizedBox(width: 36,),
                          Text(': '),
                          Expanded(child: Text(personel.unvan))
                        ],

                      ),
                      Row(
                        children: [
                          Text('Durum'), SizedBox(width: 33,),
                          Text(': '),
                          Text(durum)
                        ],

                      ),

                      Divider(color: Colors.black,
                        height: 20,),
                      Container(
                        width: 500,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(8),),color: Colors.purple[50],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('%'+personel.hizmet_prim_yuzde,style: TextStyle(color: Colors.black,fontSize: 20,fontWeight: FontWeight.bold),),
                                Text('Hizmet Satışları',style: TextStyle(color: Colors.grey,fontSize: 14),)
                              ],
                            ),
                            SizedBox(width: 110,),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(primler["hizmet_hakedis"]+" ₺",style: TextStyle(color: Colors.black,fontSize: 20,fontWeight: FontWeight.bold),),
                                Text('Prim',style: TextStyle(color: Colors.grey,fontSize: 14),)
                              ],
                            )
                          ],
                        ),
                      ),
                      SizedBox(height: 10,),
                      Container(
                        width: 500,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(8),),color: Colors.blue[50],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('%'+personel.paket_prim_yuzde,style: TextStyle(color: Colors.black,fontSize: 20,fontWeight: FontWeight.bold),),
                                Text('Paket Satışları',style: TextStyle(color: Colors.grey,fontSize: 14),)
                              ],
                            ),
                            SizedBox(width: 110,),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(primler["paket_hakedis"] + " ₺",style: TextStyle(color: Colors.black,fontSize: 20,fontWeight: FontWeight.bold),),
                                Text('Prim',style: TextStyle(color: Colors.grey,fontSize: 14),)
                              ],
                            )
                          ],
                        ),
                      ),
                      SizedBox(height: 10,),
                      Container(
                        width: 500,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(8),),color: Colors.amber[50],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("%"+personel.urun_prim_yuzde,style: TextStyle(color: Colors.black,fontSize: 20,fontWeight: FontWeight.bold),),
                                Text('Ürün Satışları',style: TextStyle(color: Colors.grey,fontSize: 14),)
                              ],
                            ),
                            SizedBox(width: 110,),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(primler["urun_hakedis"]+" ₺",style: TextStyle(color: Colors.black,fontSize: 20,fontWeight: FontWeight.bold),),
                                Text('Prim',style: TextStyle(color: Colors.grey,fontSize: 14),)
                              ],
                            )
                          ],
                        ),
                      ),
                      SizedBox(height: 10,),
                      Container(
                        width: 500,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(8),),color: Colors.green[50],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('12.000,00',style: TextStyle(color: Colors.black,fontSize: 20,fontWeight: FontWeight.bold),),
                                Text('Prim Hakediş',style: TextStyle(color: Colors.black,fontSize: 14,fontWeight: FontWeight.bold),)
                              ],
                            ),
                            SizedBox(width: 110,),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(personel.maas,style: TextStyle(color: Colors.black,fontSize: 20,fontWeight: FontWeight.bold),),
                                Text('Maaş',style: TextStyle(color: Colors.black,fontSize: 14,fontWeight: FontWeight.bold),)
                              ],
                            )
                          ],
                        ),
                      ),
                      SizedBox(height: 10,),
                      Divider(color: Colors.black,
                        height: 10,),

                      Row(

                        children: [
                          if(personel.durum=="1")
                            ElevatedButton(onPressed: () {
                              personelpasif(context, personel.id);
                            }, child:
                            Text('Pasif Yap'),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red[600],
                                  elevation: 5,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5.0)
                                  ),
                                  minimumSize: Size(130, 30)
                              ),
                            ),
                          if(personel.durum=="0")
                            ElevatedButton(onPressed: () {
                              personelaktif(context, personel.id);
                            }, child:
                            Text('Aktif Yap'),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  elevation: 5,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5.0)
                                  ),
                                  minimumSize: Size(130, 30)
                              ),
                            ),
                          SizedBox(width: 15,),
                          ElevatedButton(onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => PersonelSatislari(kullanicirolu: kullanicirolu, kullanici: personel,isletmebilgi:isletmebilgi)),
                            );
                          }, child:
                          Text('Satışlar'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple[800],
                                elevation: 5,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5.0)
                                ),
                                minimumSize: Size(130, 30)
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [

                          ElevatedButton(onPressed: () {
                            personelsifre(context, personel.id);
                          }, child:
                          Text('Şifre Değiştir'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                elevation: 5,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5.0)
                                ),
                                minimumSize: Size(130, 30)
                            ),
                          ),
                          SizedBox(width: 15,),
                          ElevatedButton(onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => PersonelDuzenle(per: personel,isletmebilgi:isletmebilgi, personeldata: this,)),
                            );
                          }, child:
                          Text('Düzenle'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple[800],
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
  Future<void> personelekleguncelle(String personelid,String personeladi,String unvan,String telefon,String hesapturu,String cinsiyet,String sabitmaas,String hizmetprim,
      String urunprim,String paketprim,
      String salonId, calisiyor1,  calisiyor2,  calisiyor3,  calisiyor4,  calisiyor5,  calisiyor6,  calisiyor7,
      String baslangic1, String baslangic2, String baslangic3, String baslangic4, String baslangic5, String baslangic6, String baslangic7,
      String bitis1, String bitis2, String bitis3, String bitis4, String bitis5, String bitis6, String bitis7,
      calisiyor8,  calisiyor9,  calisiyor10,  calisiyor11,  calisiyor12,  calisiyor13,  calisiyor14,
      String baslangic8, String baslangic9, String baslangic10, String baslangic11, String baslangic12, String baslangic13, String baslangic14,
      String bitis8, String bitis9, String bitis10, String bitis11, String bitis12, String bitis13, String bitis14,
      BuildContext context) async {
    final Map<String, dynamic> formData = {
      'personel_id': salonId,
      'personel_adi':personeladi,
      'unvan':unvan,
      'personel_maas':sabitmaas,
      'cinsiyet':cinsiyet,
      'cep_telefon':telefon,
      'personel_id': personelid,
      'sistem_yetki':hesapturu,
      'hizmet_prim_yuzde':hizmetprim,
      'urun_prim_yuzde':urunprim,
      'paket_prim_yuzde':paketprim,
      'calisiyor1': calisiyor1 == true ? 1 : 0,
      'calisiyor2': calisiyor2 == true ? 1 : 0,
      'calisiyor3': calisiyor3 == true ? 1 : 0,
      'calisiyor4': calisiyor4 == true ? 1 : 0,
      'calisiyor5': calisiyor5 == true ? 1 : 0,
      'calisiyor6': calisiyor6 == true ? 1 : 0,
      'calisiyor7': calisiyor7 == true ? 1 : 0,
      'baslangicsaati1': baslangic1,
      'baslangicsaati2': baslangic2,
      'baslangicsaati3': baslangic3,
      'baslangicsaati4': baslangic4,
      'baslangicsaati5': baslangic5,
      'baslangicsaati6': baslangic6,
      'baslangicsaati7': baslangic7,
      'bitissaati1': bitis1,
      'bitissaati2': bitis2,
      'bitissaati3': bitis3,
      'bitissaati4': bitis4,
      'bitissaati5': bitis5,
      'bitissaati6': bitis6,
      'bitissaati7': bitis7,
      'mola1': calisiyor1 == true ? 1 : 0,
      'mola2': calisiyor2 == true ? 1 : 0,
      'mola3': calisiyor3 == true ? 1 : 0,
      'mola4': calisiyor4 == true ? 1 : 0,
      'mola5': calisiyor5 == true ? 1 : 0,
      'mola6': calisiyor6 == true ? 1 : 0,
      'mola7': calisiyor7 == true ? 1 : 0,
      'molabaslangicsaati1': baslangic8,
      'molabaslangicsaati2': baslangic9,
      'molabaslangicsaati3': baslangic10,
      'molabaslangicsaati4': baslangic11,
      'molabaslangicsaati5': baslangic12,
      'molabaslangicsaati6': baslangic13,
      'molabaslangicsaati7': baslangic14,
      'molabitissaati1': bitis8,
      'molabitissaati2': bitis9,
      'molabitissaati3': bitis10,
      'molabitissaati4': bitis11,
      'molabitissaati5': bitis12,
      'molabitissaati6': bitis13,
      'molabitissaati7': bitis14,




    };


    final response = await http.post(
      Uri.parse(
          'https://app.randevumcepte.com.tr/api/v1/personelekleduzenle'),

      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(formData),


    );
    debugPrint('Response status: ${response.statusCode}');
    debugPrint('Response body: ${response.body}');

    if (response.statusCode == 200) {
      log('etkinlik güncelleme : ' + response.body);
      Navigator.of(context).pop();
      fetchData("1",baslik,false);


    } else {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('error'),
        ),
      );
      debugPrint('Failed to load data. Status code: ${response.statusCode}');
      throw Exception('Failed to load data: ${response.reasonPhrase}');
    }
  }






}
class HizmetlerDataSource extends DataGridSource{
  List<DataGridRow> _paginatedRows = [];
  int rowsPerPage;
  int currentPage;

  int totalPages = 1;
  int totalRows;
  String salonid;

  String baslik;
  dynamic isletmebilgi;
  BuildContext context;
  List<Hizmet> hizmet = [];

  ValueNotifier<bool> isLoadingNotifier = ValueNotifier(false);
  HizmetlerDataSource({
    required this.rowsPerPage,
    required this.context,
    required this.salonid,
    required this.isletmebilgi,
    required this.baslik,




  }) : currentPage = 1, totalRows = 0 {
    fetchData(currentPage.toString(),baslik,true);
  }
  void search(String baslik)
  {
    currentPage = 1;
    fetchData("1",baslik,false);
  }
  Future<void> fetchData(String page, String baslik, bool showprogress) async {

    if (showprogress)
      showProgressLoading(context);
    isLoadingNotifier.value = true;
    notifyListeners();

    final jsonResponse = await hizmetgetir(salonid, page.toString(), baslik);
    log('hizmet json '+jsonEncode(jsonResponse));
    List<dynamic> data = jsonResponse['data'];
    hizmet = data.map<Hizmet>((json) => Hizmet.fromJson(json)).toList();
    _paginatedRows.clear();

    // Recalculate rows only if needed based on data
    hizmet.forEach((e) {
      _paginatedRows.add(
        DataGridRow(cells: [
          DataGridCell<Hizmet>(columnName: 'hizmet', value: e),
          DataGridCell<String>(columnName: 'id', value: e.id.toString()),
          DataGridCell<String>(columnName: 'hizmetadi', value: e.hizmet_adi.toString()),
          DataGridCell<String>(
            columnName: 'personel',
            value: (e.personel.toString() != "null" ? e.personel.toString() : "") +
                (e.cihaz.toString() != "null" ? ", " + e.cihaz.toString() : ""),
          ),
        ]),
      );
    });

    // Update totalPages and currentPage directly from API response
    totalPages = jsonResponse['last_page'] ?? 1;
    currentPage = jsonResponse['current_page'] ?? 1;
    totalRows = jsonResponse['total'] ?? totalRows; // If total rows are returned by the API
    log("total pages 2 : "+ jsonResponse['last_page'].toString());

    if (showprogress)
      Navigator.of(context, rootNavigator: true).pop(); // Close loading dialog
    isLoadingNotifier.value = false;
    notifyListeners();
  }
  Future<void> hizmetekleduzenle(bool yeniekleme,List<String>hizmetAdlari,  List<Hizmet> secilihizmetler,List<String> sureler, List<String> fiyatlar,List<List<PersonelCihaz>>secilipersonelcihazlar,String seciliisletme) async {

    showProgressLoading(context);
    List<List<String>> personeller = [];
    List<List<String>> cihazlar = [];
    secilipersonelcihazlar.asMap().forEach((index,element) {
      personeller.add([]);
      cihazlar.add([]);
      element.forEach((element2) {
        if (element2 is Personel)
          personeller[index].add(element2.id);
        else if(element2 is Cihaz)
          cihazlar[index].add(element2.id);
      });
    });
    Map<String, dynamic> formData = {
      'yeniekleme': yeniekleme ? '1':'0',
      'hizmetler' : secilihizmetler,
      'sureler': sureler,
      'fiyatlar': fiyatlar,
      'hizmetAdlari': hizmetAdlari,
      'secilipersoneller': personeller,
      'secilicihazlar': cihazlar,

      'sube':seciliisletme,

    };

    final response = await http.post(
        Uri.parse('https://app.randevumcepte.com.tr/api/v1/hizmetekleduzenle'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(formData),
    );
    Navigator.of(context,rootNavigator:true).pop();
    if (response.statusCode == 200) {
      Navigator.of(context).pop();
      if(yeniekleme)
        Navigator.of(context).pop();
      fetchData("1","",false);

    } else {

      debugPrint(response.body);
    }
  }
  Future<void> hizmetSil(String seciliHizmetId) async {

    showProgressLoading(context);

    Map<String, dynamic> formData = {
      'hizmetId': seciliHizmetId,
    };

    final response = await http.post(
      Uri.parse('https://app.randevumcepte.com.tr/api/v1/hizmetsil'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(formData),
    );
    Navigator.of(context,rootNavigator:true).pop();
    if (response.statusCode == 200) {
      Navigator.of(context).pop();

      fetchData("1","",false);

    } else {

      debugPrint(response.body);
    }
  }

  void setPage(int page) {
    if (page > 0 && page <= totalPages) {
      currentPage = page;

      fetchData(currentPage.toString(),"",true);
    }
  }
  @override
  List<DataGridRow> get rows => _paginatedRows;
  @override
  DataGridRowAdapter? buildRow(DataGridRow row) {

    return DataGridRowAdapter(cells: [

      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[0].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[1].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[2].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[3].value.toString()),
      ),




    ]);
  }
  void showDetailsDialog(BuildContext context, Hizmet hizmet) {
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          contentPadding: EdgeInsets.zero,
          content: SingleChildScrollView(
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Positioned(
                  right: -20,
                  top: -20,
                  child: InkResponse(
                    onTap: () => Navigator.of(context).pop(),
                    child: const CircleAvatar(
                      backgroundColor: Colors.red,
                      child: Icon(Icons.close, color: Colors.white),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const SizedBox(height: 20),

                        Center(
                          child: Text(
                            hizmet.hizmet_adi,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),

                        const Divider(),

                        _row('Süre (dk)', hizmet.sure_dk),
                        _row('Fiyat (₺)', hizmet.fiyat),
                        _row('Personel(-ler)', hizmet.personel),
                        _row('Cihaz(-lar)', hizmet.cihaz),

                        const SizedBox(height: 20),
                        const Divider(),

                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  List<Hizmet> secilihizmet = [hizmet];
                                  Navigator.of(context).pop();

                                  Navigator.of(context, rootNavigator: true).push(
                                    MaterialPageRoute(
                                      builder: (_) => CalisanSecimi(
                                        isletmebilgi: isletmebilgi,
                                        secilihizmetler: secilihizmet,
                                        hizmetDataGridSource: this,
                                        yeniEkleme: false,
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: Colors.green,
                                ),
                                child: const Text('Düzenle'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  bool? sonuc = await showDialog<bool>(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: const Text('Uyarı'),
                                        content: const Text('Bu kaydı silmek istediğinize emin misiniz?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context, false);
                                            },
                                            child: const Text('İptal'),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                              foregroundColor: Colors.white
                                            ),
                                            onPressed: () {
                                              Navigator.pop(context, true);
                                            },
                                            child: const Text('Sil'),
                                          ),
                                        ],
                                      );
                                    },
                                  );

                                  if (sonuc == true) {
                                    hizmetSil(hizmet.id);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: Colors.red
                                ),
                                child: const Text('Sil'),
                              ),
                            ),

                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

      },
    );





  }
  Widget _row(String label, String? value) {
    log(label+"-"+value!);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label)),
          const Text(': '),
          Expanded(
            child: Text(
              value != null && value != "null" ? value : "Belirtilmemiş",
            ),
          ),
        ],
      ),
    );
  }


}
class EAsistanDataSource extends DataGridSource {
  List<DataGridRow> _paginatedRows = [];
  int rowsPerPage;
  int currentPage;
  int totalPages = 1;
  int totalRows;
  String salonid;
  String bugunyarin;
  BuildContext context;
  List<EAsistan> asistan = [];
  dynamic isletmebilgi;
  ValueNotifier<bool> isLoadingNotifier = ValueNotifier(false);

  EAsistanDataSource({
    required this.rowsPerPage,
    required this.context,
    required this.salonid,
    required this.isletmebilgi,
    required this.bugunyarin,
  })  : currentPage = 1,
        totalRows = 0 {
    fetchData(currentPage.toString(), bugunyarin, true);
  }

  Future<void> fetchData(String page, String bugunyarin, bool showprogress) async {
    isLoadingNotifier.value = true;
    if (showprogress) showProgressLoading(context);
    notifyListeners();

    // Convert bugunyarin to DateTime
    DateTime? parsedDate;
    try {
      parsedDate = DateTime.parse(bugunyarin);
    } catch (e) {
      print('Invalid date format for bugunyarin: $bugunyarin');
      isLoadingNotifier.value = false;
      if (showprogress) Navigator.of(context, rootNavigator: true).pop();
      return; // Exit if the date is invalid
    }

    // Use the timestamp in milliseconds or seconds
    int bugunYarinTimestamp = parsedDate.millisecondsSinceEpoch;

    final jsonResponse = await easistan(salonid, page, bugunYarinTimestamp);

    List<dynamic> data = jsonResponse['data'];
    asistan = data.map<EAsistan>((json) => EAsistan.fromJson(json)).toList();

    if (_paginatedRows.isNotEmpty) _paginatedRows.clear();

    asistan.forEach((e) {
      ++totalRows;
      _paginatedRows.add(DataGridRow(cells: [
        DataGridCell<EAsistan>(columnName: 'asistan', value: e),
        DataGridCell<String>(columnName: 'id', value: e.id.toString()),  // Ortak ID'yi burada kullan
        DataGridCell<String>(columnName: 'baslik', value: e.baslik.toString()),
        DataGridCell<String>(columnName: 'aramasaati', value: e.arama_saati.toString()),
        DataGridCell<String>(columnName: 'sonuc', value: e.sonuc.toString()),
      ]));
    });

    totalPages = jsonResponse['last_page'];
    currentPage = jsonResponse['current_page'];

    isLoadingNotifier.value = false;

    if (showprogress) Navigator.of(context, rootNavigator: true).pop();
    notifyListeners();
  }

  void setPage(int page) {
    if (page > 0 && page <= totalPages) {
      currentPage = page;
      fetchData(currentPage.toString(), bugunyarin, true);
    }
  }

  ColorAndText getStatusColorAndText(String durum) {
    print('Durum: $durum');
    if (durum == '0') {
      return ColorAndText(Colors.red[600]!, 'Okunmadı');
    } else {
      return ColorAndText(Colors.green, 'Okundu');
    }
  }

  @override
  List<DataGridRow> get rows => _paginatedRows;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    final colorAndText = getStatusColorAndText(row.getCells()[4].value.toString());
    // Assuming ID is stored in row[1].
    // arama_saati değerini DateTime olarak parse et
    DateTime? aramaSaati;
    try {
      aramaSaati = DateTime.parse(row.getCells()[3].value.toString());
    } catch (e) {
      print('Invalid date format for arama_saati: ${row.getCells()[3].value}');
    }

    bool showPopup = aramaSaati != null && aramaSaati.isAfter(DateTime.now());
    return DataGridRowAdapter(cells: [
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[0].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[1].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[2].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[3].value.toString()),
      ),
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(row.getCells()[4].value.toString()),
      ),

      Container(
        alignment: Alignment.center,
        child: showPopup
            ? PopupMenuButton<String>(
          onSelected: (String value) async {
            if (value == 'goreviptali') {
              goreviptali(context, row.getCells()[1].value.toString());
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: 'goreviptali',
              child: Text('Görevi İptal Et'),
            ),
          ],
        )
            : SizedBox(), // Eğer arama_saati geçmişse buton yerine boş bir widget koyuyoruz
      ),
    ]);
  }
  void goreviptali(BuildContext context, String asistanid) async {

    showProgressLoading(context);
    Map<String, dynamic> formData = {
      'alacak_id': asistanid,
      'randevu_id':asistanid,
      'kampanya_id':asistanid
    };

    final response = await http.post(
      Uri.parse('https://demoapptest.randevumcepte.com.tr/api/v1/gorev-iptal-et'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(formData),
    );

    print('API Yanıtı: ${response.body}'); // Yanıtı görmek için

    if (response.statusCode == 200) {
      try {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          Navigator.of(context, rootNavigator: true).pop();
          fetchData(currentPage.toString(), bugunyarin, false);

          // Görev iptal edildi, kullanıcıya bildirim yapılabilir
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Görev başarıyla iptal edildi!')),
          );
        } else {
          throw Exception(jsonResponse['message']);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Yanıt hatalı: ${response.body}')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Görev iptal edilirken bir hata oluştu! Hata kodu: ${response.statusCode}'),
        ),
      );
    }

  }
  void showTaskDetails(BuildContext context, EAsistan task) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.deepPurple, width: 1),
            ),
            child: Text(
              task.baslik,
              style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold, fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "Görev: ",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple),
                    ),
                    TextSpan(
                      text: task.mesaj,
                      style: TextStyle(color: Colors.blueGrey[700], fontSize: 13),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "Arama Saati: ",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple),
                    ),
                    TextSpan(
                      text: task.arama_saati,
                      style: TextStyle(color: Colors.blueGrey[700], fontSize: 14),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "Durum: ",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple),
                    ),
                    TextSpan(
                      text: task.durum,
                      style: TextStyle(
                        color: task.durum == "Ulaşıldı" ? Colors.green : Colors.red,  // Durum kontrolü
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "Sonuç: ",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple),
                    ),
                    TextSpan(
                      text: task.sonuc,
                      style: TextStyle(color: Colors.blueGrey[700], fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Kapat"),
            ),
          ],
        );
      },
    );
  }

}

double calculateTextHeight(String text, double columnWidth, TextStyle style) {
  final textPainter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: ui.TextDirection.ltr,
    maxLines: null,
  )..layout(maxWidth: columnWidth);

  return textPainter.size.height + 16; // padding ekle
}


import 'dart:developer';
import 'dart:ui';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:dropdown_search/dropdown_search.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:randevu_sistem/randevualma/randevuozetonay.dart';

import '../../Backend/backend.dart';
import '../../Frontend/datetimeformatting.dart';
import '../../Frontend/popupdialogs.dart';

import '../../Models/cihazlar.dart';
import '../../Models/isletmehizmetleri.dart';
import '../../Models/musteri_danisanlar.dart';
import '../../Models/odalar.dart';
import '../../Models/personel.dart';
import '../../Models/randevuhizmetleri.dart';
import '../../Models/randevuhizmetyardimcipersonelleri.dart';

import '../../Models/randevutekrarsikligi.dart';
import '../../yeni/app_colors.dart';

import 'package:randevu_sistem/yonetici/randevular/musteri.dart';

import '../Models/BosDoluSaatler.dart';
import '../Models/salonlar.dart';


class RandevuAl extends StatefulWidget {



  @override
  AppointmentEditorState createState() => AppointmentEditorState();
}

class AppointmentEditorState extends State<RandevuAl> {
  bool isloading = true;
  List<IsletmeHizmet> isletmehizmetliste =[];
  List<Personel> personelliste = [];

  List<Personel?> secilipersonel = [];
  List<IsletmeHizmet?>  secilihizmet= [];

  List<Salonlar>subeler=[];
  List<List<Personel>> filtreliPersonelListesi = [[]];

  DateTime secilitarih = DateTime.now();
  DateTime secilisaat = DateTime.now();

  TextEditingController randevutarihi = TextEditingController(text: "");
  TextEditingController randevusaati = TextEditingController(text: '');


  List<TextEditingController> hizmet = [];
  List<TextEditingController> personel = [];
  TextEditingController sube = TextEditingController();
  Salonlar? seciliSube;



  final TextEditingController textEditingController = TextEditingController();

  bool formisvalid = true;
  late String seciliisletme;
  List<RandevuHizmet> randevuhizmetleri = [RandevuHizmet(hizmetler: null, hizmet_id: '', personel_id: '', personeller: null, oda_id: '', oda: null, cihaz_id: '', cihaz: null, fiyat: '', sure_dk: '', saat: '', saat_bitis: '', yardimci_personel: '', birusttekiileaynisaat: '')];

  late List<String> tarihListesi;
  String? secilenTarih;
  String? secilenSaat;
  List<BosDoluSaatler> saatler =[] ;
  List<String> hizmetSecimHintText = [];
  List<String> personelSecimHintText = [];
  void initState() {
    super.initState();

    initialize();
    tarihListesi = tarihleriOlustur();
    secilenTarih = tarihListesi.first;
  }

  List<String> tarihleriOlustur() {
    final bugun = DateTime.now();
    final toplamGun = 180; // 2 ay ~ 60 gün
    final List<String> tarihListesi = [];

    for (int i = 0; i < toplamGun; i++) {
      final gun = bugun.add(Duration(days: i));
      if (i == 0) {
        tarihListesi.add("Bugün");
      } else if (i == 1) {
        tarihListesi.add("Yarın");
      } else {
        // Gün adını kısa almak için DateFormat
        String gunAdi = DateFormat.E("tr").format(gun); // tr için Paz, Pzt, Sal, ...
        String tarih = DateFormat("dd.MM").format(gun); // 24.09
        tarihListesi.add("$tarih $gunAdi");
      }
    }

    return tarihListesi;
  }
  Future<void> hizmetleriGetir() async{

    final isletmeVerileri = await isletmeVerileriGetir(seciliSube!.id.toString(),true,await appBundleAl(),'','',0,0);
    List<IsletmeHizmet> isletmehizmetleriliste =  isletmeVerileri['hizmetler'];
    setState(() {
      hizmetSecimHintText.clear;
      hizmetSecimHintText = hizmetSecimHintText.map((e) => 'Hizmet seç...').toList();
      isletmehizmetliste = isletmehizmetleriliste;
    });
  }
  Future<void> initialize() async {

    String salonId = '';

    final isletmeVerileri = await isletmeVerileriGetir(salonId,true,await appBundleAl(),'','',0,0);
    List<Salonlar> isletmesubeler = isletmeVerileri['subeler'];
    List<IsletmeHizmet> isletmehizmetleriliste = isletmesubeler.length==1 ? isletmeVerileri['hizmetler'] : [];


    setState(() {
      hizmet.add(TextEditingController());
      personel.add(TextEditingController());
      secilipersonel.add(null);
      secilihizmet.add(null);
      isletmehizmetliste = isletmehizmetleriliste;
      personelliste = [];
      subeler = isletmesubeler;
      if(isletmesubeler.length == 1)
        seciliSube = isletmesubeler[0];
      String hizmetsecimtext = '';
      if(isletmehizmetliste.length==0)
        hizmetsecimtext= 'Önce şube seçmeniz gerekir!';
      else
        hizmetsecimtext = 'Hizmet seç...';
      hizmetSecimHintText.add(hizmetsecimtext);
      personelSecimHintText.add('Önce hizmet seçmeniz gerekir!');
      isloading = false;
    });

  }

  DateTime stringiDateTimeYap(String tarihString) {
    final bugun = DateTime.now();

    // Bugün ve Yarın için özel durum
    if (tarihString == "Bugün") {
      return DateTime(bugun.year, bugun.month, bugun.day);
    }
    if (tarihString == "Yarın") {
      final yarin = bugun.add(const Duration(days: 1));
      return DateTime(yarin.year, yarin.month, yarin.day);
    }

    // Diğer tarih formatı: "24.09 Çar" → sadece "24.09" kısmını al
    String tarihPart = tarihString.split(' ')[0]; // "24.09"
    List<String> parts = tarihPart.split('.');

    if (parts.length != 2) {
      throw FormatException("Tarih string formatı yanlış: $tarihString");
    }

    int gun = int.parse(parts[0]);
    int ay = int.parse(parts[1]);
    int yil = bugun.year; // başlangıç olarak bu yıl

    DateTime dt = DateTime(yil, ay, gun);

    // Eğer bu tarih, bugünden daha küçük görünüyorsa → gelecek yıl olmalı
    if (dt.isBefore(DateTime(bugun.year, bugun.month, bugun.day))) {
      dt = DateTime(yil + 1, ay, gun);
    }

    return dt;
  }
  void personelSecAdiminaGec (int index,String hizmetId) async{
    String sube = '';
    if(seciliSube != null)
      sube  = seciliSube!.id;
    var personelData = await personelAdiminaGec(sube,await appBundleAl(),hizmetId);
    List<Personel> hizmetPersonelleriListe = personelData['personeller'];
    setState(() {
      filtreliPersonelListesi[index] = hizmetPersonelleriListe;
      personelSecimHintText[index] = 'Personel seç...';
      });
  }
  void tarihSaatAdiminaGec () async
  {
      bool secimTamam = randevuhizmetleri.every((element) {
        return element.hizmet_id != '' && element.personel_id != '';
      });
      if(secimTamam)
        {

          List<String>seciliHizmetler=[];
          List<String>seciliPersoneller=[];
          randevuhizmetleri.forEach((element){
              seciliHizmetler.add(element.hizmet_id);
              seciliPersoneller.add(element.personel_id);

          });
          String sube = '';
          if(seciliSube!=null)
            sube = seciliSube!.id;
          dynamic randevuSaatleri = await bosVeDoluSaatleriGetir(sube,seciliPersoneller,seciliHizmetler,DateFormat("yyyy-MM-dd").format(stringiDateTimeYap(secilenTarih!)),await appBundleAl());
          // 🔹 JSON’dan listeyi parse et
          if (randevuSaatleri["saatler"] != null &&
              randevuSaatleri["saatler"] is List) {
            saatler = (randevuSaatleri["saatler"] as List)
                .map((e) => BosDoluSaatler.fromJson(e))
                .toList();
          } else {
            saatler = []; // Boş liste döndür
          }

          setState(() {}); // UI’yı güncelle


        }

  }
  Future<void> tarihsec(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(1950),
        //DateTime.now() - not to allow to choose before today.
        lastDate: DateTime(2100));

    if (pickedDate != null) {
      print(pickedDate); //pickedDate output format => 2021-03-10 00:00:00.000
      String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
      print(
          formattedDate); //formatted date output using intl package =>  2021-03-16
      setState(() {
        randevutarihi.text =
            formattedDate; //set output date to TextField value.
      });
    } else {}
  }
  String tarihGosterimi(DateTime tarih) {
    final bugun = DateTime.now();
    final fark = DateTime(tarih.year, tarih.month, tarih.day)
        .difference(DateTime(bugun.year, bugun.month, bugun.day))
        .inDays;

    if (fark == 0) return "Bugün";
    if (fark == 1) return "Yarın";
    String gunAdi = DateFormat.E("tr").format(tarih); // Çar, Per...
    String tarihStr = DateFormat("dd.MM").format(tarih);
    return "$tarihStr $gunAdi";
  }
  Future<void> saatsec(BuildContext context) async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(secilisaat ?? DateTime.now()),
    );

    if (pickedTime != null) {
      print(
          formattedDate); //formatted date output using intl package =>  2021-03-16
      setState(() {
        String dakika = '0';
        if (pickedTime.minute < 10)
          dakika = '0' + pickedTime.minute.toString();
        else
          dakika = pickedTime.minute.toString();
        randevusaati.text = pickedTime.hour.toString() + ':' + dakika;
      });
    } else {}
  }



  Widget _getAppointmentEditor(BuildContext context) {
    final double columnWidth = MediaQuery.of(context).size.width / 2 - 20;
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return
      isloading ?  Center(child: CircularProgressIndicator(),) :  GestureDetector(
          onTap: () {
            // Unfocus the current text field, dismissing the keyboard
            FocusScope.of(context).unfocus();
          },
          child: Container(
              height: screenHeight,
              color: Colors.white,
              child: ListView(
                padding: const EdgeInsets.all(0),
                children: <Widget>[
                  subeler.length>1 ?
                    Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 0.0), // dikey padding azaltıldı
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center, // dikey ortala
                        children: [
                          Text(
                            'Şube Seçimi',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),


                        ],
                      ),
                    ): SizedBox(),
                  subeler.length>1 ? SizedBox(height: 10,) : SizedBox(),
                  subeler.length>1?  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 0.0),
                    child: Container(
                      alignment: Alignment.center,
                      height: 40,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Color(0xFF6A1B9A)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton2<Salonlar>(
                          isExpanded: true,
                          hint: Text('Şube Seç', style: TextStyle(fontSize: 14, color: Theme.of(context).hintColor)),
                          items: subeler.map((item) => DropdownMenuItem(
                            value: item,
                            child: Text(item.salon_adi, style: TextStyle(fontSize: 14)),
                          )).toList(),
                          value: seciliSube,
                          onChanged: (value) {
                            setState(() {
                              seciliSube = value;
                              hizmetleriGetir();



                            });
                          },
                          buttonStyleData: ButtonStyleData(padding: EdgeInsets.symmetric(horizontal: 10), height: 50, width: 400),
                          dropdownStyleData: DropdownStyleData(maxHeight: 400),
                          menuItemStyleData: MenuItemStyleData(height: 40),
                          dropdownSearchData: DropdownSearchData(
                            searchController: sube,
                            searchInnerWidgetHeight: 50,
                            searchInnerWidget: Container(
                              height: 50,
                              padding: EdgeInsets.all(8),
                              child: TextFormField(
                                expands: true,
                                maxLines: null,
                                controller: sube,
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  hintText: 'Şube Ara..',
                                  hintStyle: TextStyle(fontSize: 12),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                            searchMatchFn: (item, searchValue) => item.value!.salon_adi.toString().toLowerCase().contains(searchValue.toLowerCase()),
                          ),
                        ),
                      ),
                    )
                  ) :
                   SizedBox(),
                  subeler.length>1? SizedBox(height: 10,) : SizedBox(),


                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 0.0), // dikey padding azaltıldı
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center, // dikey ortala
                      children: [
                        Text(
                          'Hizmet/Personel Seçimi',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        TextButton(
                          onPressed: () {

                            setState(() {


                              hizmet.add(TextEditingController());
                              personel.add(TextEditingController());
                              secilipersonel.add(null);

                              secilihizmet.add(null);
                              filtreliPersonelListesi.add([]);

                              randevuhizmetleri.add(RandevuHizmet(
                                hizmetler: null,
                                hizmet_id: '',
                                personel_id: '',
                                personeller: null,
                                oda_id: '',
                                oda: null,
                                cihaz_id: '',
                                cihaz: null,
                                fiyat: '',
                                sure_dk: '',
                                saat: '',
                                saat_bitis: '',
                                yardimci_personel: '',
                                birusttekiileaynisaat: '',
                              ));


                              hizmetSecimHintText.add( (isletmehizmetliste.length==0 ? 'Önce şube seçmeniz gerekir' :  'Hizmet seç...'));
                              personelSecimHintText.add('Önce hizmet seçmeniz gerekir!');

                            });
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size(0, 30),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Hizmet Ekle",
                                style: TextStyle(fontSize: 12, color: Colors.green),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.add, size: 30, color: Colors.green),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  SizedBox(height: 5),
                  ...List.generate(randevuhizmetleri.length, (index) {
                    final set = randevuhizmetleri[index];
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 3),
                      child: Padding(
                        padding: const EdgeInsets.all(5),
                        child: Column(
                          children: [

                            Row(
                              children: [
                                SizedBox(
                                  width: columnWidth  -20,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Hizmet', style: TextStyle(fontSize: 11)),
                                      SizedBox(height: 5),
                                      Container(
                                        alignment: Alignment.center,
                                        height: 40,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          border: Border.all(color: Color(0xFF6A1B9A)),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton2<IsletmeHizmet>(
                                            isExpanded: true,
                                            hint: Text(hizmetSecimHintText[index], style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
                                            items: isletmehizmetliste.map((item) => DropdownMenuItem(
                                              value: item,
                                              child: Text(item.hizmet['hizmet_adi'], style: TextStyle(fontSize: 14)),
                                            )).toList(),
                                            value: secilihizmet[index],
                                            onChanged: (value) {
                                              setState(() {
                                                secilihizmet[index] = value!;
                                                randevuhizmetleri[index].hizmet_id = value.hizmet_id;

                                                randevuhizmetleri[index].sure_dk = value.sure;
                                                randevuhizmetleri[index].fiyat = value.fiyat;
                                                randevuhizmetleri[index].hizmetler = value.hizmet;
                                                personelSecAdiminaGec(index,value.hizmet_id);
                                                tarihSaatAdiminaGec();

                                              });
                                            },
                                            buttonStyleData: ButtonStyleData(padding: EdgeInsets.symmetric(horizontal: 10), height: 50, width: 400),
                                            dropdownStyleData: DropdownStyleData(maxHeight: 400),
                                            menuItemStyleData: MenuItemStyleData(height: 40),
                                            dropdownSearchData: DropdownSearchData(
                                              searchController: hizmet[index],
                                              searchInnerWidgetHeight: 50,
                                              searchInnerWidget: Container(
                                                height: 50,
                                                padding: EdgeInsets.all(8),
                                                child: TextFormField(
                                                  expands: true,
                                                  maxLines: null,
                                                  controller: hizmet[index],
                                                  decoration: InputDecoration(
                                                    isDense: true,
                                                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                    hintText: 'Hizmet Ara..',
                                                    hintStyle: TextStyle(fontSize: 12),
                                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                                  ),
                                                ),
                                              ),
                                              searchMatchFn: (item, searchValue) => item.value!.hizmet["hizmet_adi"].toString().toLowerCase().contains(searchValue.toLowerCase()),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 10), // İki alan arası boşluk
                                SizedBox(
                                    width: columnWidth -20 ,
                                    child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children:[
                                          Text(
                                            'Personel',
                                            style: TextStyle( fontSize: 11),
                                          ),
                                          SizedBox(height:5),
                                          Container(
                                            alignment: Alignment.center,

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
                                                    personelSecimHintText[index],
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Theme.of(context).hintColor,
                                                    ),
                                                  ),
                                                  value: secilipersonel[index],
                                                  items: filtreliPersonelListesi[index]
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

                                                  onChanged: (value) {
                                                    setState(() {
                                                      secilipersonel[index] = value!;
                                                      randevuhizmetleri[index].personel_id = value.id;
                                                      randevuhizmetleri[index].personeller = value;
                                                      tarihSaatAdiminaGec();
                                                    });
                                                  },
                                                  buttonStyleData: const ButtonStyleData(
                                                    padding: EdgeInsets.symmetric(horizontal: 16),
                                                    height: 50,
                                                    width: 400,
                                                  ),

                                                  dropdownStyleData: const DropdownStyleData(
                                                    maxHeight: 400,

                                                  ),
                                                  menuItemStyleData: const MenuItemStyleData(
                                                    height: 40,
                                                  ),
                                                  dropdownSearchData: DropdownSearchData(
                                                    searchController: personel[index],
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
                                                        controller: personel[index],

                                                        decoration: InputDecoration(
                                                          isDense: true,
                                                          contentPadding: const EdgeInsets.symmetric(
                                                            horizontal: 10,
                                                            vertical: 8,
                                                          ),
                                                          hintText: 'Personel Ara..',
                                                          hintStyle: const TextStyle(fontSize: 12),
                                                          border: OutlineInputBorder(
                                                            borderRadius: BorderRadius.circular(8),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    searchMatchFn: (item, searchValue) {

                                                      return item.value!.personel_adi.toString().toLowerCase().contains(searchValue.toLowerCase());
                                                    },
                                                  ),
                                                  //This to clear the search value when you close the menu
                                                  onMenuStateChange: (isOpen) {
                                                    if (!isOpen) {

                                                    }
                                                  },

                                                )),
                                          ),

                                        ]
                                    )


                                ),
                                SizedBox(width: 10),
                                if (randevuhizmetleri.length > 1)
                                  SizedBox(
                                    width: 20,
                                    child: IconButton(
                                      icon: Icon(Icons.remove_circle, color: Colors.red),
                                      onPressed: () {
                                        tarihSaatAdiminaGec();
                                        setState(() => randevuhizmetleri.removeAt(index));
                                      },
                                    ),
                                  ),

                              ],
                            ),

                          ],
                        ),
                      ),
                    );
                  }),

                  const Divider(
                    height: 1.0,
                    thickness: 1,
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 📌 Başlık
                        Text(
                          'Tarih/Saat Seçimi',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: 10), // Başlık ile container arası boşluk

                        // 📌 Tarih/Saat Seçimi Container'ı
                        Container(
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(15)),
                            color: Colors.white,
                          ),
                          height: subeler.length > 1 ? height*0.54 : height * 0.65,
                          width: double.infinity, // tam genişlik
                          padding: EdgeInsets.only(top: 5, left: 5, right: 5),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 📌 Tarih Listesi
                              SizedBox(
                                height: 50,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: tarihListesi.length,
                                  itemBuilder: (context, index) {
                                    final tarih = tarihListesi[index];
                                    final seciliMi = secilenTarih == tarih;

                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          secilenTarih = tarih;
                                          secilenSaat = null;
                                          tarihSaatAdiminaGec();
                                        });
                                      },
                                      child: Container(
                                        width: 90,
                                        margin: EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: seciliMi ? Colors.purple[800] : Colors.grey.shade200,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          tarih,
                                          style: TextStyle(
                                            color: seciliMi ? Colors.white : Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),

                              SizedBox(height: 10),

                              // 📌 Saat Listesi
                              Expanded(
                                child: SingleChildScrollView(
                                  child: saatler == null || saatler.isEmpty
                                      ? Center(
                                    child: Text(
                                      "Uygun saat bulunamadı",
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  )
                                      : Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: saatler.map((saat) {
                                      final seciliMi = secilenSaat == saat.saat;

                                      return RawChip(
                                        labelPadding: EdgeInsets.symmetric(horizontal: 28),
                                        label: Text(
                                          saat.saat,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        selected: seciliMi,
                                        onSelected: (selected) {
                                          if (saat.dolu=='1') return; // Dolu saat seçilemez
                                          setState(() {
                                            if (secilenSaat == saat.saat) {
                                              secilenSaat = null; // Aynı kutuya basınca seçim kaldır
                                            } else {
                                              secilenSaat = saat.saat;



                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(builder: (context) => RandevuOnay(seciliHizmetler: randevuhizmetleri, tarih: DateFormat("dd.MM.yyyy").format(stringiDateTimeYap(secilenTarih!)), saat: secilenSaat!,salonid: seciliSube?.id ?? '',)),
                                              );

                                            }
                                          });
                                        },
                                        selectedColor: Colors.purple[800], // Seçilen boş saat mavi
                                        backgroundColor: saat.dolu=='1' ? Colors.red : Colors.green,
                                        disabledColor: Colors.red, // Dolu saatler kırmızı
                                        showCheckmark: false, // ✅ Check ikonunu kaldır
                                      );
                                    }).toList(),

                                  ),
                                ),
                              ),


                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                ],
              )));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(

          appBar: new AppBar(
            title: const Text(
              'Randevu Al',
              style: TextStyle(color: Colors.black),
            ),
            backgroundColor: Colors.white,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
            elevation: 4, // gölge ekler, değeri artırarak gölgeyi güçlendirebilirsin
            shadowColor: Colors.grey.withOpacity(0.5), // gölge rengi
            toolbarHeight: 60,
          ),
          body: Padding(
            padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
            child: Stack(
              children: <Widget>[_getAppointmentEditor(context)],
            ),
          ),
        ));
  }



}

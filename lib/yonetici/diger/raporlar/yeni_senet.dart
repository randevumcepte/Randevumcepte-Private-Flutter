import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:randevu_sistem/Frontend/altyuvarlakmenu.dart';
import 'package:randevu_sistem/Frontend/progressloading.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:randevu_sistem/Models/adisyonhizmetler.dart';
import 'package:randevu_sistem/Models/adisyonpaketler.dart';
import 'package:randevu_sistem/Models/adisyonurunler.dart';
import 'package:randevu_sistem/Models/isletmehizmetleri.dart';
import 'package:randevu_sistem/Models/musteri_danisanlar.dart';
import 'package:randevu_sistem/Models/senetturleri.dart';
import 'package:randevu_sistem/Models/senetvadeleri.dart';
import 'package:randevu_sistem/Models/taksitlitahsilatlar.dart';
import 'package:randevu_sistem/yonetici/dashboard/urunsatisiduzenleme.dart';

import '../../../Backend/backend.dart';
import '../../../Frontend/paraformati.dart';
import '../../../Frontend/tlrakamacevir.dart';
import '../../../Models/adisyonkalemleri.dart';
import '../../../Models/odemeturu.dart';
import '../../../Models/paketler.dart';
import '../../../Models/personel.dart';
import '../../../Models/senetler.dart';
import '../../../Models/taksitvadeleri.dart';
import '../../../Models/urunler.dart';
import '../../dashboard/hizmetsatisi.dart';
import '../../dashboard/hizmetsatisiduzenleme.dart';
import '../../dashboard/paketsatisi.dart';
import '../../dashboard/paketsatisiduzenleme.dart';
import '../../dashboard/urunsatisi.dart';
import '../../diger/menu/musteriler/yeni_musteri.dart';

class YeniSenet extends StatefulWidget {
  final dynamic isletmebilgi;
  final String musteridanisanid;
  YeniSenet({Key? key,required this.isletmebilgi,required this.musteridanisanid}) : super(key: key);
  @override
  _YeniSenetState createState() => _YeniSenetState();
}

class _YeniSenetState extends State<YeniSenet> {

  bool isloading = true;
  bool kalemleryukleniyor = false;
  final List<OdemeTuru> odemeyontem = [
    OdemeTuru(id: '1', odeme_turu: 'Nakit'),
    OdemeTuru(id: '2', odeme_turu: 'Kredi Kartı'),
    OdemeTuru(id: '3', odeme_turu: 'Havale/EFT'),


  ];
  final List<SenetTuru> senetturu=[
      SenetTuru(id:"1",senet_turu: "Nakden"),
    SenetTuru(id:"2",senet_turu: "Malen"),
    SenetTuru(id:"3",senet_turu: "Hizmet"),
  ];
  var tryformat = NumberFormat.currency(locale: 'tr_TR',symbol: "");
  OdemeTuru? selectedodemeyontemi;
  TextEditingController odemeyontemcontroller = TextEditingController();



  TextEditingController vade_baslangic_tarihi = TextEditingController(text: DateFormat("yyyy-MM-dd").format(DateTime.now()));
  TextEditingController ilk_taksit_vade_tarihi = TextEditingController(text: DateFormat("yyyy-MM-dd").format(DateTime.now()));
  TextEditingController taksit_sayisi = TextEditingController(text:"1");
  TextEditingController taksit_toplam_tutar = TextEditingController();
  TextEditingController dateInput2 = TextEditingController(text: DateFormat("yyyy-MM-dd").format(DateTime.now()));
  TextEditingController toplamindirimtutari = TextEditingController();
  late List<MusteriDanisan> musteridanisanlar;
  MusteriDanisan? secilimusteridanisan;
  final TextEditingController textEditingController = TextEditingController();

  List<bool> isCheckedList = [];
  List<bool> isCheckedList2 = [];
  void _showAlert() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Bildiri'),
          content: Text('Silmek istediğiniz hizmeti sola kaydırabilirsiniz'),
          actions: <Widget>[
            TextButton(
              child: Text('Kapat'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteData() {
    // Implement the logic to delete data here
    setState(() {

      _dataAdded = false; // Set dataAdded to false
      _containerHeight = 10.0; // Reset the container height
    });
  }
  //hizmet icin

  String selectedDropdownValue = ''; // Store the selected dropdown value
  String selectedDropdownValue2 = ''; // Store the selected dropdown value
  SenetTuru? secilisenetturu;
  TextEditingController musteri_sabit_indirim = TextEditingController(text: "0");
  TextEditingController tarih = TextEditingController();
  TextEditingController saat = TextEditingController();
  TextEditingController sure = TextEditingController();
  TextEditingController fiyat = TextEditingController();

  TextEditingController tckimlikno = TextEditingController();
  TextEditingController musteridanisanadres = TextEditingController();
  TextEditingController kefiladres = TextEditingController();
  TextEditingController kefiladsoyad = TextEditingController();
  TextEditingController kefiltcno = TextEditingController();


  TextEditingController vade_sayisi_ay = TextEditingController();


  TextEditingController odenecek_tutar = TextEditingController(text: "0,00");
  TextEditingController tahsilat_tutari = TextEditingController();
  TextEditingController senet_tutari = TextEditingController();


  bool _dataAdded = false;
  double _containerHeight = 0.0;

  //urun icin
  String selectedDropdownUrun = ''; // Store the selected dropdown value
  String selectedDropdownSatici = ''; // Store the selected dropdown value
  TextEditingController urunAdet = TextEditingController();
  TextEditingController urunFiyat = TextEditingController();
  bool _dataAddedurun = false;
  double _containerHeighturun = 0.0;

//paket icin
  String selectedDropdownPaket = ''; // Store the selected dropdown value
  String selectedDropdownPaketSatici = ''; // Store the selected dropdown value
  TextEditingController baslangictarih = TextEditingController();
  TextEditingController seans = TextEditingController();
  TextEditingController paketfiyat = TextEditingController();
  TextEditingController musteridanisanadi = TextEditingController();
  TextEditingController aktifsadikpasif = TextEditingController();
  bool _dataAddedpaket = false;
  double _containerHeightpaket = 0.0;
  late String seciliisletme;
  late List<Urun> urunliste;
  late List<Paket> paketliste;
  late List<IsletmeHizmet> hizmetliste;

  List<AdisyonKalemleri> adisyonkalemleri = [];
  List<AdisyonKalemleri> senetvadeleri = [];
  List<AdisyonKalemleri> taksitvadeleri = [];
  List<AdisyonKalemleri> senetvadeleri_alacak = [];
  List<AdisyonKalemleri> taksitvadeleri_alacak = [];

  int secilialacaksenet = 0;
  int secilialacaktaksit = 0;


  @override
  void initState() {
    super.initState();
    initialize();

  }
  @override
  void dispose() {
    super.dispose();
  }

  void loadbar(MusteriDanisan value) async
  {
    String musterituru = await musteriDanisanTuru(seciliisletme,value?.id.toString() ?? "");
    String indirimtext = "0";
    String aktifpasif = "";

    if(musterituru == "1"){

      aktifpasif= "Aktif";
      indirimtext = widget.isletmebilgi["aktif_musteri_indirim_yuzde"].toString();
    }
    else if(musterituru == "2")
    {
      aktifpasif="Sadık";
      indirimtext = widget.isletmebilgi["sadik_musteri_indirim_yuzde"].toString();
    }
    else{
      aktifpasif="Pasif";
    }



    setState(() {
      kalemleryukleniyor = true;
      adisyonkalemleri.clear();
      taksitvadeleri.clear();
      senetvadeleri.clear();
      secilimusteridanisan = value;
      musteri_sabit_indirim.text = indirimtext;
      aktifsadikpasif.text = aktifpasif;
      musteridanisanadi.text = (secilimusteridanisan?.name)!;
      alacaklarigetir();

    });
  }
  Future<void> initialize() async{
    seciliisletme = (await secilisalonid())!;
    List <MusteriDanisan> musteridanisanliste = await musterilistegetir(seciliisletme);
    setState(() {

      musteridanisanlar = musteridanisanliste;


      if(widget.musteridanisanid != ""){




        loadbar(musteridanisanlar.firstWhere((element) => element.id == widget.musteridanisanid));

      }

      isloading = false;

    });
  }

  //hizmetsatisi
  void alacaklarigetir () async{

    if(secilimusteridanisan != null){
      String danisan = secilimusteridanisan?.id ?? "";

      dynamic senettaksitdata = await senetvetaksitler(seciliisletme!, secilimusteridanisan?.id ?? "");

      List<Senet> senetler = senettaksitdata['senet'].map<Senet>((json) => Senet.fromJson(json)).toList();

      List<TaksitliTahsilat> taksitler = senettaksitdata['taksit'].map<TaksitliTahsilat>((json) => TaksitliTahsilat.fromJson(json)).toList();
      List<AdisyonHizmet> adisyonhizmetler = senettaksitdata["adisyon_hizmet"].map<AdisyonHizmet>((json) => AdisyonHizmet.fromJson(json)).toList();
      List<AdisyonUrun> adisyonurunler = senettaksitdata["adisyon_urun"].map<AdisyonUrun>((json) => AdisyonUrun.fromJson(json)).toList();
      List<AdisyonPaket> adisyonpaketler = senettaksitdata["adisyon_paket"].map<AdisyonPaket>((json) => AdisyonPaket.fromJson(json)).toList();


      senetler.forEach((element) {
        element.vadeler.forEach((element2) {

          if(element2["odendi"]=="0") {
            setState(() {

              senetvadeleri.add(SenetVade(id: element2["id"].toString(),
                  senet_id: element2["senet_id"].toString(),
                  vade_tarih: element2["vade_tarih"],
                  tutar: element2["tutar"].toString(),
                  odendi: element2["odendi"].toString(),
                  notlar: element2["notlar"],
                  odeme_yontemi_id: element2["odeme_yonetemi_id"].toString(),
                  dogrulama_kodu: element2["dogrulama_kodu"]));


            });
          }
          if(element2["odendi"]==0 && DateTime.parse(element2["vade_tarih"]+'T00:00:00').isBefore(DateTime.now())){
            setState(() {

              adisyonkalemleri.add(SenetVade(id: element2["id"].toString(), senet_id: element2["senet_id"].toSctring(), vade_tarih: element2["vade_tarih"], tutar: element2["tutar"].toString(), odendi: element2["odendi"].toString(), notlar: element2["notlar"], odeme_yontemi_id: element2["odeme_yonetemi_id"].toString(), dogrulama_kodu: element2["dogrulama_kodu"]));

            });
          }
        });
      });
      taksitler.forEach((element) {

        element.vadeler.forEach((element2) {

          if(element2["odendi"]=="0") {
            log("ekleniyor ");
            setState(() {

              taksitvadeleri.add(TaksitVade(
                  id: element2["id"].toString(),
                  taksitli_tahsilat_id: element2["taksitli_tahsilat_id"]
                      .toString(),
                  vade_tarih: element2["vade_tarih"],
                  tutar: element2["tutar"].toString(),
                  odendi: element2["odendi"].toString(),
                  notlar: element2["notlar"],
                  odeme_yontemi_id: element2["odeme_yonetemi_id"].toString(),
                  dogrulama_kodu: element2["dogrulama_kodu"]));

            });


          }
          if(element2["odendi"]==0 && DateTime.parse(element2["vade_tarih"]+'T00:00:00').isBefore(DateTime.now())){
            setState(() {
              adisyonkalemleri.add(TaksitVade(id: element2["id"].toString(), taksitli_tahsilat_id: element2["taksitli_tahsilat_id"].toString(), vade_tarih: element2["vade_tarih"], tutar: element2["tutar"].toString(), odendi: element2["odendi"].toString(), notlar: element2["notlar"], odeme_yontemi_id: element2["odeme_yonetemi_id"].toString(), dogrulama_kodu: element2["dogrulama_kodu"]));

            });
          }
        });
      });


      adisyonhizmetler.forEach((element) {
        setState(() {
          adisyonkalemleri.add(element);

        });
      });
      adisyonurunler.forEach((element) {

        setState(() {
          adisyonkalemleri.add(element);

        });
      });
      adisyonpaketler.forEach((element) {
        setState(() {
          adisyonkalemleri.add(element);

        });
      });
    }
    setState(() {
      isCheckedList = List.generate(taksitvadeleri.length, (index) => false);
      isCheckedList2 = List.generate(senetvadeleri.length, (index) => false);
      kalemleryukleniyor = false;
      tutar_hesapla(false);
    });
  }
  void hizmetsatisi(AdisyonHizmet? mevcutadisyonhizmet) async {
    if(secilimusteridanisan == null)
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('UYARI'),
            content: Text('Devam etmek için önce müşteri/danışan seçiniz veya ekleyiniz.'),
            actions: <Widget>[
              TextButton(
                child: Text('Kapat'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    else{
      final AdisyonHizmet result = mevcutadisyonhizmet != null ? await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => HizmetSatisiDuzenleme(musteriid: secilimusteridanisan?.id ??"", mevcuthizmet:mevcutadisyonhizmet ,senetlisatis: true,isletmebilgi: widget.isletmebilgi,)),
      ) : await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => HizmetSatisi(musteriid: secilimusteridanisan?.id ??"",senetlisatis: true,isletmebilgi: widget.isletmebilgi)),
      );

      if (result != null ) {

        setState(() {
          if(mevcutadisyonhizmet != null)
          {
            adisyonkalemleri.removeWhere((element) => element is AdisyonHizmet ? element.id == mevcutadisyonhizmet.id : false );

          }

          adisyonkalemleri.add(result);
          tutar_hesapla(false);



        });
      }
    }

  }
  void tutar_hesapla(bool onodemegirildi)
  {

    double fiyattoplam = 0;
    double indirimtutari = 0;



    adisyonkalemleri.forEach((element) {
      if(element is AdisyonHizmet){
        String tutar = element.fiyat;

        tutar = tutar.replaceAll(",", ".");
        fiyattoplam += double.parse(tutar);
        indirimtutari += (double.parse(tutar) * (double.parse(musteri_sabit_indirim.text)/100));

      }

      if(element is AdisyonUrun){
        String tutar = element.fiyat;

        tutar = tutar.replaceAll(",", ".");
        fiyattoplam += double.parse(tutar);
        indirimtutari += (double.parse(tutar) * (double.parse(musteri_sabit_indirim.text)/100));


      }

      if(element is AdisyonPaket)
      {
        String tutar = element.fiyat;

        tutar = tutar.replaceAll(",", ".");
        fiyattoplam += double.parse(tutar);
        indirimtutari += (double.parse(tutar) * (double.parse(musteri_sabit_indirim.text)/100));

      }





    });

    setState(() {

      toplamindirimtutari.text = tryformat.format(indirimtutari).toString();
      tahsilat_tutari.text = tryformat.format(fiyattoplam-indirimtutari).toString();
      if(!onodemegirildi || tahsilat_tutari.text == odenecek_tutar.text)
        senet_tutari.text = tryformat.format(fiyattoplam-indirimtutari).toString();
      else{

        senet_tutari.text = tryformat.format(fiyattoplam- indirimtutari  - tlyirakamacevir(odenecek_tutar.text));
        taksit_toplam_tutar.text = senet_tutari.text;
      }

    });
  }

  //urunsatisi
  void urunsatisi(AdisyonUrun? mevcutadisyonurun) async {
    if(secilimusteridanisan == null)
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('UYARI'),
            content: Text('Devam etmek için önce müşteri/danışan seçiniz veya ekleyiniz.'),
            actions: <Widget>[
              TextButton(
                child: Text('Kapat'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    else{
      final AdisyonUrun result = mevcutadisyonurun != null ? await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => UrunSatisiDuzenleme(musteriid: secilimusteridanisan?.id ??"", mevcuturun:mevcutadisyonurun ,senetlisatis: true,isletmebilgi: widget.isletmebilgi)),
      ) : await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => UrunSatisi(musteriid: secilimusteridanisan?.id ??"",senetlisatis: true,isletmebilgi: widget.isletmebilgi)),
      );

      if (result != null ) {

        setState(() {
          if(mevcutadisyonurun != null)
          {
            adisyonkalemleri.removeWhere((element) => element is AdisyonUrun ? element.id == mevcutadisyonurun.id : false );

          }

          adisyonkalemleri.add(result);
          tutar_hesapla(false);



        });
      }
    }
  }

  //paketsatisi
  void paketsatisi(AdisyonPaket? mevcutadisyonpaket) async {
    if(secilimusteridanisan == null)
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('UYARI'),
            content: Text('Devam etmek için önce müşteri/danışan seçiniz veya ekleyiniz.'),
            actions: <Widget>[
              TextButton(
                child: Text('Kapat'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    else{
      final AdisyonPaket result = mevcutadisyonpaket != null ?  await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PaketSatisiDuzenleme(musteriid: secilimusteridanisan?.id ??"", mevcutpaket:mevcutadisyonpaket ,senetlisatis: true,isletmebilgi: widget.isletmebilgi)),
      ) : await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PaketSatisi(musteriid: secilimusteridanisan?.id ?? "",senetlisatis: true,isletmebilgi: widget.isletmebilgi)),
      );

      if (result != null ) {

        setState(() {
          if(mevcutadisyonpaket != null)
          {
            adisyonkalemleri.removeWhere((element) => element is AdisyonPaket ? element.id == mevcutadisyonpaket.id : false );

          }
          adisyonkalemleri.add(result);
          tutar_hesapla(false);

        });
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus(); // Hide the keyboard
      },
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(



          appBar: AppBar(
            title:  const Text('Yeni Senet',style: TextStyle(color: Colors.black),),

            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
            toolbarHeight: 60,
            actions: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: SizedBox(
                    width: 100, // <-- Your width
                    child: YukseltButonu(isletme_bilgi: widget.isletmebilgi)
                ),
              ),


            ],
            backgroundColor: Colors.white,
          ),
          body: isloading ? Center(child: CircularProgressIndicator(),):
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 20.0),
                          child: Text('Müşteri/Danışan',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                        ),
                        SizedBox(height: 10,),
                        Container(
                            alignment: Alignment.center,
                            margin: EdgeInsets.only(left:20,right: 20),
                            height: 40,

                            width:150,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Color(0xFF6A1B9A)),
                              borderRadius: BorderRadius.circular(10), //border corner radius

                              //you can set more BoxShadow() here

                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton2<MusteriDanisan>(
                                isExpanded: true,
                                hint: Text(
                                  'Seçiniz...',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context).hintColor,
                                  ),
                                ),
                                items: musteridanisanlar
                                    .map((item) => DropdownMenuItem(
                                  value: item,
                                  child: Text(
                                    item.name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                    ),
                                  ),
                                ))
                                    .toList(),
                                value: secilimusteridanisan,
                                onChanged: (value) {
                                  setState(() {
                                    secilimusteridanisan = value;
                                    tckimlikno.text = value?.tc_kimlik_no ?? "";
                                    musteridanisanadres.text = (value?.adres != "null" ? value?.adres :  "")! ;
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
                                  searchController: textEditingController,
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
                                      controller: textEditingController,
                                      decoration: InputDecoration(
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 8,
                                        ),
                                        hintText: 'Müşteri Ara..',
                                        hintStyle: const TextStyle(fontSize: 12),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ),
                                  searchMatchFn: (item, searchValue) {
                                    return item.value!.name.toString().toLowerCase().contains(searchValue.toLowerCase());

                                  },
                                ),
                                // Clear the search value when you close the menu
                                onMenuStateChange: (isOpen) {
                                  if (!isOpen) {
                                    textEditingController.clear();
                                  }
                                },
                              ),
                            )
                        ),

                      ],
                    )),
                    Expanded(child:   Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [

                        SizedBox(height: 30,),
                        ElevatedButton(onPressed: () async{

                          final MusteriDanisan yenimusteridanisan =  await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => Yenimusteri(isletmebilgi: widget.isletmebilgi,isim:"",telefon:"",sadeceekranikapat: true,)),
                          );
                          if(yenimusteridanisan != null)
                            setState(() {
                              musteridanisanlar.add(yenimusteridanisan);
                              secilimusteridanisan = yenimusteridanisan;
                            });
                        },
                          child: Text('Yeni Müşteri/Danışan Ekle',style:TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple[800],
                            foregroundColor: Colors.white,
                            minimumSize: Size(60, 30),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),



                          ),
                        ),
                      ],
                    ),)
                  ],
                ),
                SizedBox(height: 10),
                Container(
                  padding: EdgeInsets.only(left:20,right:20),
                  child:Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [

                                Text('TC Kimlik No',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                                SizedBox(height: 10,),
                                TextFormField(
                                  maxLength: 11,

                                  controller: tckimlikno,
                                  keyboardType: TextInputType.phone,

                                  onSaved: (value) {
                                    tckimlikno.text = value!;

                                  },

                                  decoration: InputDecoration(
                                    filled: true,
                                    focusColor:Color(0xFF6A1B9A) ,
                                    fillColor: Colors.white,
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
                                SizedBox(height: 10,),
                                Text('Adres',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                                SizedBox(height: 10,),
                                TextFormField(
                                  maxLines: 3,
                                  controller: musteridanisanadres,

                                  onSaved: (value) {
                                    musteridanisanadres.text = value!;

                                  },

                                  decoration: InputDecoration(
                                    filled: true,
                                    focusColor:Color(0xFF6A1B9A) ,
                                    fillColor: Colors.white,
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
                              ],
                            )
                        )
                      ]
                  ),
                ),

                SizedBox(height: 10,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    SizedBox(width: 10,),
                    ElevatedButton(onPressed: (){
                      hizmetsatisi(null);
                    },
                      child: Text('Hizmet Ekle',style: TextStyle(fontSize: 12),),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF9C27B0),
                        foregroundColor: Colors.white,
                        minimumSize: Size(90, 30),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),

                      ),
                    ),
                    SizedBox(width: 5,),
                    ElevatedButton(onPressed: (){urunsatisi(null);},
                      child: Text('Ürün Ekle',style:TextStyle(fontSize:12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFEA80FC),
                        foregroundColor: Colors.white,
                        minimumSize: Size(95, 30),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),

                      ),
                    ),
                    SizedBox(width: 5,),
                    ElevatedButton(onPressed: (){paketsatisi(null);},
                      child: Text('Paket Ekle',style:TextStyle(fontSize:12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:  Color(0xFF1976D2),
                        foregroundColor: Colors.white,
                        minimumSize: Size(95, 30),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),


                      ),
                    ),
                    SizedBox(width: 15,),


                  ],
                ),
                SizedBox(height: 5,),
                Container(
                  margin: EdgeInsets.only(left: 10,right: 10),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Container(

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          kalemleryukleniyor ? Center(child: CircularProgressIndicator(),) : ListView.builder(
                              scrollDirection: Axis.vertical,
                              shrinkWrap: true,

                              itemCount: adisyonkalemleri.length,
                              itemBuilder: (context,index){
                                final item = adisyonkalemleri[index];
                                String key = "";
                                String kalem = "";
                                String adet = "";
                                String satan = "";
                                String tutar = "";
                                if(item is AdisyonHizmet){

                                  key=item.hizmet_id.toString();
                                  kalem = item.hizmet["hizmet_adi"];
                                  adet = "1";
                                  if(item.personel is Personel){
                                    Personel pers = item.personel;
                                    satan = pers.personel_adi;
                                  }

                                  else
                                    satan = item.personel["personel_adi"];
                                  tutar = tryformat.format(double.parse(item.fiyat));

                                }

                                if(item is AdisyonUrun)
                                {
                                  key=item.urun_id.toString();
                                  kalem = item.urun["urun_adi"];
                                  adet = item.adet;
                                  satan = item.personel["personel_adi"];

                                  tutar=tryformat.format(double.parse(item.fiyat));


                                }

                                if(item is AdisyonPaket)
                                {
                                  key=item.paket_id.toString();
                                  kalem = item.paket["paket_adi"];
                                  adet="1";
                                  log("Paket satan Personel "+item.personel.toString());
                                  satan = item.personel["personel_adi"];
                                  tutar =tryformat.format(double.parse(item.fiyat));


                                }
                                if(item is SenetVade){
                                  key=item.id.toString();
                                  kalem= item.id.toString() +" nolu Senet vadesi";
                                  adet = "1";
                                  satan = DateFormat('dd.MM.yyyy').format(DateTime.parse(item.vade_tarih));
                                  tutar = tryformat.format(double.parse(item.tutar));
                                }
                                if(item is TaksitVade){
                                  key=item.id.toString();
                                  kalem= item.id.toString() +" nolu Taksit vadesi";
                                  adet = "1";
                                  satan = DateFormat('dd.MM.yyyy').format(DateTime.parse(item.vade_tarih));
                                  tutar = tryformat.format(double.parse(item.tutar));
                                }

                                return
                                  GestureDetector(
                                    onTap: (){
                                      if(item is AdisyonHizmet)
                                        hizmetsatisi(item);
                                      if(item is AdisyonUrun){

                                        urunsatisi(item);
                                      }
                                      if(item is AdisyonPaket){
                                        paketsatisi(item);
                                      }

                                    },

                                    child: Dismissible(
                                        dismissThresholds: {
                                          DismissDirection.startToEnd: 0.5,
                                          DismissDirection.endToStart: 0.5
                                        },
                                        direction: DismissDirection.horizontal,
                                        key: Key(key ),
                                        background: Container(
                                          color: Colors.green,
                                          alignment: Alignment.centerLeft,
                                          padding: EdgeInsets.only(left: 20),
                                          child: Icon(Icons.edit, color: Colors.white),
                                        ),
                                        secondaryBackground: Container(
                                          color: Colors.red,
                                          alignment: Alignment.centerRight,
                                          padding: EdgeInsets.only(right: 20),
                                          child: Icon(Icons.delete, color: Colors.white),
                                        ),
                                        confirmDismiss: ( direction) async {
                                          return await showDialog(
                                            context: context,
                                            builder: (BuildContext context2) {
                                              return AlertDialog(
                                                title: const Text("UYARI"),
                                                content: const Text("Satış kalemini silmek istediğinize emin misiniz? Bu işlem geri alınamaz"),
                                                actions: <Widget>[
                                                  TextButton(
                                                      onPressed: () => Navigator.of(context2).pop(false),
                                                      child: const Text("VAZGEÇ")
                                                  ),
                                                  TextButton(
                                                    onPressed: () async{
                                                      Navigator.of(context2).pop(true);



                                                        setState(() {
                                                          if(adisyonkalemleri[index] is SenetVade)
                                                          {
                                                            senetvadeleri.add(adisyonkalemleri[index]);
                                                            senetvadeleri.sort((a, b) => a.getSortValue().compareTo(b.getSortValue()));
                                                          }

                                                          if(adisyonkalemleri[index] is TaksitVade)
                                                          {
                                                            taksitvadeleri.add(adisyonkalemleri[index]);
                                                            taksitvadeleri.sort((a, b) => a.getSortValue().compareTo(b.getSortValue()));
                                                          }

                                                          adisyonkalemleri.removeAt(index);

                                                          tutar_hesapla(false);
                                                        });



                                                    } ,
                                                    child: const Text("SİL"),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },

                                        child : Container(
                                          decoration: BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(color: Colors.grey, width: 1.0),
                                            ),
                                          ),
                                          child:  ListTile(
                                            title: Text(kalem),
                                            subtitle: Text(satan),
                                            trailing: Text(adet + ' Adet\n'+tutar+" ₺", textAlign: TextAlign.right),
                                          ),
                                        )
                                    ),
                                  );



                              }),

                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10,),
                Container(
                  padding: const EdgeInsets.all( 20.0),
                  color: Color(0xFFE2E2E2), // Set your desired background color here
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(

                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              child: Text('Ön Ödeme Tutarı ₺',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                            ),
                            SizedBox(height: 10,),
                            Container(
                              height: 40,
                              padding: const EdgeInsets.only( right:20.0),
                              child: TextFormField(

                                controller: odenecek_tutar,
                                keyboardType: TextInputType.phone,
                                onChanged: (value){
                                  tutar_hesapla(true);
                                },
                                onSaved: (value) {
                                  odenecek_tutar.text = value!;

                                },

                                decoration: InputDecoration(
                                  filled: true,
                                  focusColor:Color(0xFF6A1B9A) ,
                                  fillColor: Colors.white,
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


                          ]
                        )
                      ),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  child: Text('Ön Ödeme Türü',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                                ),
                                SizedBox(height: 10,),
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

                                      child: DropdownButton2<OdemeTuru>(

                                        isExpanded: true,
                                        hint: Text(
                                          'Seçiniz..',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Theme.of(context).hintColor,
                                          ),
                                        ),
                                        items: odemeyontem
                                            .map((item) => DropdownMenuItem(
                                          value: item,
                                          child: Text(
                                            item.odeme_turu,
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                        ))
                                            .toList(),
                                        value: selectedodemeyontemi,

                                        onChanged: (value) {
                                          setState(() {
                                            selectedodemeyontemi = value;
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
                                            odemeyontemcontroller.clear();
                                          }
                                        },

                                      )),
                                ),


                              ]
                          )
                      )
                    ]
                  ),
                ),
                SizedBox(height: 10,),
                Container(
                  padding: const EdgeInsets.only(left: 20.0,right:20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            Container(


                              child: Text('Vade Başlangıç Tarihi',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                            ),
                            SizedBox(height: 10,),
                            Container(
                              height: 40,
                              padding: EdgeInsets.only(right: 20),
                              child: TextFormField(
                                controller: vade_baslangic_tarihi,
                                //editing controller of this TextField
                                decoration: InputDecoration(

                                  focusColor:Color(0xFF6A1B9A) ,
                                  hoverColor: Color(0xFF6A1B9A) ,
                                  hintStyle: TextStyle(color:  Color(0xFF6A1B9A)),
                                  contentPadding:  EdgeInsets.all(0.0),
                                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(
                                      color: Color(0xFF6A1B9A)),borderRadius: BorderRadius.circular(10.0),),
                                  border:
                                  OutlineInputBorder(borderRadius: BorderRadius.circular(10.0),),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Color(0xFF6A1B9A),), borderRadius: BorderRadius.circular(10.0),
                                  ),
                                ),
                                readOnly: true,
                                //set it true, so that user will not able to edit text

                                onTap: () async {
                                  DateTime? pickedDate = await showDatePicker(
                                      context: context,
                                      initialDate: DateTime.now(),
                                      firstDate: DateTime(1950),
                                      //DateTime.now() - not to allow to choose before today.
                                      lastDate: DateTime(2100));

                                  if (pickedDate != null) {
                                    print(
                                        pickedDate); //pickedDate output format => 2021-03-10 00:00:00.000
                                    String formattedDate =
                                    DateFormat('yyyy-MM-dd').format(pickedDate);
                                    print(
                                        formattedDate); //formatted date output using intl package =>  2021-03-16
                                    setState(() {
                                      vade_baslangic_tarihi.text =
                                          formattedDate; //set output date to TextField value.
                                    });
                                  } else {}
                                },
                              ),
                            ),
                            SizedBox(height: 10,),
                            Text('Senet Tutarı (₺)',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),


                            SizedBox(height: 10,),
                            Container(
                              height:40,
                              padding: EdgeInsets.only( right: 20),
                              child: TextFormField(

                                controller: senet_tutari,
                                keyboardType: TextInputType.phone,
                                onChanged: (value) {
                                  tutar_hesapla(false);

                                },
                                onSaved: (value) {
                                  senet_tutari.text = value!;
                                },

                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white,
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
                            SizedBox(height: 10,),

                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding:  EdgeInsets.only(right: 20.0),
                              child: Text('Vade Sayısı (Ay)',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                            ),
                            SizedBox(height: 10,),
                            Container(
                              height: 40,

                              child: TextFormField(

                                keyboardType: TextInputType.phone,
                                controller: vade_sayisi_ay,
                                onSaved: (value) {
                                  vade_sayisi_ay.text = value!;
                                },



                                decoration: InputDecoration(
                                  filled: true,

                                  focusColor:Color(0xFF6A1B9A) ,
                                  fillColor: Colors.white,
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

                            SizedBox(height: 10,),
                            Container(
                              padding:  EdgeInsets.only(right: 20.0),
                              child: Text('Senet Türü',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                            ),
                            SizedBox(height: 10,),
                            Container(
                              padding: EdgeInsets.only(right: 20.0),
                              alignment: Alignment.center,
                              height: 40,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Color(0xFF6A1B9A)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton2<SenetTuru>(
                                  isExpanded: true,
                                  hint: Text(
                                    'Seçiniz...',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Theme.of(context).hintColor,
                                    ),
                                  ),
                                  items: senetturu.map((item) => DropdownMenuItem(
                                    value: item,
                                    child: Text(
                                      item.senet_turu,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  )).toList(),
                                  value: secilisenetturu,
                                  onChanged: (value) {
                                    setState(() {
                                      secilisenetturu = value;
                                    });
                                  },
                                  buttonStyleData: const ButtonStyleData(
                                    padding: EdgeInsets.only(left: 16,  ),
                                    height: 50,
                                    width: double.infinity,
                                  ),
                                  dropdownStyleData: const DropdownStyleData(
                                    maxHeight: 200,
                                  ),
                                  menuItemStyleData: const MenuItemStyleData(
                                    height: 40,
                                  ),

                                  onMenuStateChange: (isOpen) {
                                    if (!isOpen) {
                                      odemeyontemcontroller.clear();
                                    }
                                  },
                                ),
                              ),
                            ),

                            SizedBox(height: 10,),

                          ],
                        ),
                      )
                    ]
                  ),

                ),

                SizedBox(height: 10,),
                Container(
                  padding: EdgeInsets.only(left:20,right:20),
                  child:Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [

                                Text('Kefil Adı ve Soyadı',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                                SizedBox(height: 10,),
                                TextFormField(

                                  controller: kefiladsoyad,


                                  onSaved: (value) {
                                    kefiladsoyad.text = value!;

                                  },

                                  decoration: InputDecoration(
                                    filled: true,
                                    focusColor:Color(0xFF6A1B9A) ,
                                    fillColor: Colors.white,
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
                                SizedBox(height: 10,),
                                Text('Kefil TC Kimlik No',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                                SizedBox(height: 10,),
                                TextFormField(

                                  controller: kefiltcno,
                                  keyboardType: TextInputType.phone,

                                  onSaved: (value) {
                                    kefiltcno.text = value!;

                                  },

                                  decoration: InputDecoration(
                                    filled: true,
                                    focusColor:Color(0xFF6A1B9A) ,
                                    fillColor: Colors.white,
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
                                SizedBox(height: 10,),
                                Text('Kefil Adres',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                                SizedBox(height: 10,),
                                TextFormField(
                                  maxLines: 3,
                                  controller: kefiladres,

                                  onChanged: (value){
                                    tutar_hesapla(true);
                                  },
                                  onSaved: (value) {
                                    kefiladres.text = value!;

                                  },

                                  decoration: InputDecoration(
                                    filled: true,
                                    focusColor:Color(0xFF6A1B9A) ,
                                    fillColor: Colors.white,
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
                              ],
                            )
                        )
                      ]
                  ),
                ),
                SizedBox(height: 10,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: (){
                        bool formisvalid = true;
                        String warningtext = "Senedi kaydetmeden önce aşağıdaki hataları düzeltmeniz gerekmektedir!";
                        if(tckimlikno.text =="")
                          formisvalid = false;
                        if(musteridanisanadres.text == "")
                          formisvalid = false;
                        if(senet_tutari.text=="" || senet_tutari.text=="0,00")
                        {

                          formisvalid = false;

                        }
                        if(vade_baslangic_tarihi.text == "")
                          {
                            formisvalid = false;

                          }
                        if(vade_sayisi_ay.text == ""){
                          formisvalid = false;

                        }
                        if(secilisenetturu == null)
                          {
                            formisvalid =false;

                          }
                        if(kefiladsoyad.text == "")
                        {
                          formisvalid =false;

                        }
                        if(kefiltcno.text == "")
                        {
                          formisvalid =false;

                        }
                        if(kefiladres.text == "")
                        {
                          formisvalid =false;

                        }
                        if(!formisvalid)
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text('UYARI'),
                                content: Text("Senet oluşturmadan önce ön ödeme haricindeki tüm alanları eksiksiz doldurmanız gerekmektedir! Lütfen formu kontrol ediniz."),
                                actions: <Widget>[
                                  TextButton(
                                    child: Text('Kapat'),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ],
                              );
                            },
                          );

                        else{
                          //tahsilet(context, seciliisletme,adisyonkalemleri,taksit_sayisi.text,ilk_taksit_vade_tarihi.text,taksit_toplam_tutar.text,secilimusteridanisan?.id ??"",toplamindirimtutari.text,selectedodemeyontemi?.id??"",odenecek_tutar.text,tahsilat_tarihi.text,"",harici_indirim.text);
                          senetolustur(context, seciliisletme, adisyonkalemleri, vade_sayisi_ay.text,vade_baslangic_tarihi.text,senet_tutari.text,secilimusteridanisan?.id ??"",odenecek_tutar.text,selectedodemeyontemi?.id??"", tckimlikno.text
                              ,musteridanisanadres.text,kefiladsoyad.text,kefiltcno.text, kefiladres.text,secilisenetturu?.id ?? "");
                        }
                      },
                      child: Row(
                        children: [
                          Icon(Icons.money_sharp),
                          Text('Yeni Senet Oluştur'),
                        ],
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        minimumSize: Size(90, 30),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),

        ),
      ),
    );
  }

  void alacaklarigoster(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              insetPadding: EdgeInsets.zero,
              content: Container(
                width: MediaQuery.of(context).size.width * 0.75,
                child: SingleChildScrollView(
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
                      DefaultTabController(
                        length: 2,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * 0.7, // Set a maximum height
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min, // Allow the dialog to adjust height based on content
                            children: [
                              // TabBar container
                              Container(
                                color: Colors.white,
                                child: TabBar(
                                  isScrollable: true,
                                  indicatorSize: TabBarIndicatorSize.label,
                                  labelColor: Colors.purple,
                                  unselectedLabelColor: Colors.purple[800],
                                  labelPadding: EdgeInsets.only(left: 10, right: 10),
                                  indicator: BoxDecoration(
                                    borderRadius: BorderRadius.circular(25),
                                    color: Colors.transparent,
                                    border: Border.all(
                                      color: Colors.purple[800]!,
                                      width: 1.5,
                                    ),
                                  ),
                                  tabs: [
                                    Tab(
                                      child: Container(
                                        width: 130,
                                        child: Padding(
                                          padding: const EdgeInsets.all(4.0),
                                          child: Center(
                                            child: Text(
                                              "Taksitler",
                                              style: TextStyle(
                                                  fontSize: 15, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Tab(
                                      child: Container(
                                        width: 150,
                                        child: Padding(
                                          padding: const EdgeInsets.all(4.0),
                                          child: Center(
                                            child: Text(
                                              "Senetler",
                                              style: TextStyle(
                                                  fontSize: 15, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // TabBarView content
                              Flexible(
                                child: TabBarView(
                                  children: [
                                    // Content for "Taksitler"
                                    SingleChildScrollView(
                                      child: Column(
                                        children: [
                                          kalemleryukleniyor
                                              ? Center(child: CircularProgressIndicator())
                                              : ListView.builder(
                                            scrollDirection: Axis.vertical,
                                            shrinkWrap: true,
                                            physics: NeverScrollableScrollPhysics(),
                                            itemCount: taksitvadeleri.length,
                                            itemBuilder: (context, index) {
                                              final item2 = taksitvadeleri[index];
                                              String key2 = "";
                                              String kalem2 = "";
                                              String adet2 = "";
                                              String satan2 = "";
                                              String tutar2 = "";

                                              if (item2 is TaksitVade) {
                                                key2 = item2.id.toString();
                                                kalem2 = item2.id.toString() + " nolu Taksit vadesi";
                                                adet2 = "1";
                                                satan2 = DateFormat('dd.MM.yyyy').format(
                                                    DateTime.parse(item2.vade_tarih));
                                                tutar2 = tryformat.format(
                                                    double.parse(item2.tutar));
                                              }

                                              return GestureDetector(
                                                onTap: () {

                                                },

                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    border: Border(
                                                      bottom: BorderSide(
                                                          color: Colors.grey, width: 1.0),
                                                    ),
                                                  ),
                                                  child: ListTile(
                                                    leading: Checkbox(
                                                      value: isCheckedList[index],
                                                      onChanged: (bool? value) {
                                                        setState(() {
                                                          isCheckedList[index] = value!;
                                                          if(value)
                                                            ++secilialacaktaksit;
                                                          else
                                                            --secilialacaktaksit;
                                                        });
                                                      },
                                                    ),
                                                    title: Text(kalem2),
                                                    subtitle: Text(satan2),
                                                    trailing: Text(
                                                      adet2 + ' Adet\n' + tutar2 + " ₺",
                                                      textAlign: TextAlign.right,
                                                    ),
                                                  ),
                                                ),

                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Content for "Senetler"
                                    SingleChildScrollView(
                                      child: Column(
                                        children: [
                                          kalemleryukleniyor
                                              ? Center(child: CircularProgressIndicator())
                                              : ListView.builder(
                                            scrollDirection: Axis.vertical,
                                            shrinkWrap: true,
                                            physics: NeverScrollableScrollPhysics(),
                                            itemCount: senetvadeleri.length,
                                            itemBuilder: (context, index) {
                                              final item2 = senetvadeleri[index];
                                              String key2 = "";
                                              String kalem2 = "";
                                              String adet2 = "";
                                              String satan2 = "";
                                              String tutar2 = "";

                                              if (item2 is SenetVade) {
                                                key2 = item2.id.toString();
                                                kalem2 = item2.id.toString() + " nolu Senet vadesi";
                                                adet2 = "1";
                                                satan2 = DateFormat('dd.MM.yyyy').format(
                                                    DateTime.parse(item2.vade_tarih));
                                                tutar2 = tryformat.format(
                                                    double.parse(item2.tutar));
                                              }

                                              return GestureDetector(
                                                onTap: () {},

                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    border: Border(
                                                      bottom: BorderSide(
                                                          color: Colors.grey, width: 1.0),
                                                    ),
                                                  ),
                                                  child: ListTile(
                                                    leading: Checkbox(
                                                      value: isCheckedList2[index],
                                                      onChanged: (bool? value) {
                                                        setState(() {
                                                          isCheckedList2[index] = value!;
                                                          if(value)
                                                            ++secilialacaksenet;
                                                          else
                                                            --secilialacaksenet;
                                                        });
                                                      },
                                                    ),
                                                    title: Text(kalem2),
                                                    subtitle: Text(satan2),
                                                    trailing: Text(
                                                      adet2 + ' Adet\n' + tutar2 + " ₺",
                                                      textAlign: TextAlign.right,
                                                    ),
                                                  ),
                                                ),

                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Spacer to push the button to the bottom
                              SizedBox(height: 10), // Add some space above the button
                              ElevatedButton(
                                style: ElevatedButton.styleFrom( backgroundColor: Colors.green,  foregroundColor: Colors.white,),
                                //
                                onPressed: () {

                                  if(secilialacaksenet + secilialacaktaksit != 0){
                                    isCheckedList.asMap().forEach((girdi,element) {
                                      if(element){
                                        adisyonkalemleri.add(taksitvadeleri[girdi]);
                                        taksitvadeleri.removeAt(girdi);
                                      }

                                    });
                                    isCheckedList2.asMap().forEach((girdi,element) {
                                      if(element){
                                        adisyonkalemleri.add(senetvadeleri[girdi]);
                                        senetvadeleri.removeAt(girdi);
                                      }

                                    });
                                    tutar_hesapla(false);
                                    Navigator.of(context).pop();

                                  }

                                },
                                child: Text("Seçilileri Tahsilata Aktar"),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<bool> satiskalemikaldir(int index, List<AdisyonKalemleri> items) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Dismissal'),
          content: Text('Are you sure you want to dismiss this item?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text('Confirm'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );


  }
}
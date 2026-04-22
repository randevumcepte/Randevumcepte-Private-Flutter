import 'dart:async';

import 'dart:developer';
import 'dart:io';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:randevu_sistem/Models/adisyonhizmetler.dart';
import 'package:randevu_sistem/Models/adisyonpaketler.dart';
import 'package:randevu_sistem/Models/adisyonurunler.dart';
import 'package:randevu_sistem/Models/isletmehizmetleri.dart';
import 'package:randevu_sistem/Models/musteri_danisanlar.dart';
import 'package:randevu_sistem/Models/senetvadeleri.dart';
import 'package:randevu_sistem/Models/taksitlitahsilatlar.dart';
import 'package:randevu_sistem/yonetici/dashboard/urunsatisiduzenleme.dart';

import '../../../Backend/backend.dart';

import '../../../Frontend/lazyload.dart';
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

class TahsilatEkrani extends StatefulWidget {
  final dynamic isletmebilgi;
  final String musteridanisanid;
  final int kullanicirolu;
  final String adisyonId;
  TahsilatEkrani({Key? key,required this.adisyonId, required this.isletmebilgi,required this.musteridanisanid,required this.kullanicirolu}) : super(key: key);
  @override
  _TahsilatState createState() => _TahsilatState();
}

class _TahsilatState extends State<TahsilatEkrani> {

  bool isloading = true;
  Color? aktifPasifRenk;
  bool kalemleryukleniyor = false;
  final List<OdemeTuru> odemeyontem = [
    OdemeTuru(id: '1', odeme_turu: 'Nakit'),
    OdemeTuru(id: '2', odeme_turu: 'Kredi Kartı'),

    OdemeTuru(id: '3', odeme_turu: 'Havale/EFT'),


  ];
  var tryformat = NumberFormat.currency(locale: 'tr_TR',symbol: "");
  OdemeTuru? selectedodemeyontemi;
  TextEditingController odemeyontemcontroller = TextEditingController();



  TextEditingController tahsilat_tarihi = TextEditingController(text: DateFormat("yyyy-MM-dd").format(DateTime.now()));
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

  TextEditingController musteri_sabit_indirim = TextEditingController(text: "0");
  TextEditingController tarih = TextEditingController();
  TextEditingController saat = TextEditingController();
  TextEditingController sure = TextEditingController();
  TextEditingController fiyat = TextEditingController();

  TextEditingController birim_tutar = TextEditingController();
  TextEditingController odenecek_tutar = TextEditingController();
  TextEditingController tahsilat_tutari = TextEditingController();
  TextEditingController kalan_alacak_tutar = TextEditingController();
  TextEditingController harici_indirim = TextEditingController();

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
  final GlobalKey<LazyDropdownState> dropdownKey = GlobalKey<LazyDropdownState>();

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
    log('müşteri türü '+musterituru.toString());
    final settings = await fetchSalonSettings(seciliisletme);
    String indirimtext = "0";
    String aktifpasif = "";

    if(musterituru == "1"){

      aktifpasif= "Aktif";
      aktifPasifRenk = Color(0xFF9C27B0);
      indirimtext = settings['aktif_musteri_indirim_yuzde']?.toString() ?? '0';
      print("Aktif Müşteri İndirim Yüzdesi: ${widget.isletmebilgi["aktif_musteri_indirim_yuzde"]}");

    }
    else if(musterituru == "2")
    {
      aktifPasifRenk = Color(0xFF28A745);
      aktifpasif="Sadık";
      indirimtext =settings['sadik_musteri_indirim_yuzde']?.toString() ?? '0';
      print("Sadik Müşteri İndirim Yüzdesi: ${widget.isletmebilgi["sadik_musteri_indirim_yuzde"]}");

    }
    else{
      aktifPasifRenk = Color(0xFF000000);
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
  Future<void> initialize() async {
    seciliisletme = (await secilisalonid())!;

    // Async işlemleri önce yap
    String hariciIndirimText = tryformat.format(0).toString();
    String kalanAlacakText = tryformat.format(0).toString();

    MusteriDanisan? musteridanisanliste;
    if (widget.musteridanisanid != "") {

        musteridanisanliste = await musterilistegetirTahsilat(widget.musteridanisanid);

    }

    // Sadece senkron olarak state güncelle
    setState(() {
      harici_indirim.text = hariciIndirimText;
      kalan_alacak_tutar.text = kalanAlacakText;

      if (musteridanisanliste != null) {
        secilimusteridanisan = musteridanisanliste;
        loadbar(musteridanisanliste); // Burada da setState var, onun için dikkat
      }

      isloading = false;
    });
  }

  //hizmetsatisi
  void alacaklarigetir () async{

    if(secilimusteridanisan != null){
      String danisan = secilimusteridanisan?.id ?? "";

      dynamic senettaksitdata = await senetvetaksitler(seciliisletme!, secilimusteridanisan?.id ?? "",widget.adisyonId);
      String fullData = senettaksitdata["adisyon_paket"].toString();
      int chunkSize = 800;

      for (int i = 0; i < fullData.length; i += chunkSize) {
        int end = (i + chunkSize < fullData.length) ? i + chunkSize : fullData.length;
        debugPrint(fullData.substring(i, end));
      }
      List<Senet> senetler =  senettaksitdata['senet'].map<Senet>((json) => Senet.fromJson(json)).toList();
      log('taksit data '+senettaksitdata["taksit"].toString());
      print(senettaksitdata['taksit'].runtimeType);
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
                  notlar: element2["notlar"].toString(),
                  odeme_yontemi_id: element2["odeme_yontemi_id"]??"",
                  dogrulama_kodu: element2["dogrulama_kodu"]??""));


            });
          }
          if(element2["odendi"]==0 && DateTime.parse(element2["vade_tarih"]+'T00:00:00').isBefore(DateTime.now())){
            setState(() {

              adisyonkalemleri.add(SenetVade(id: element2["id"].toString(), senet_id: element2["senet_id"].toSctring(), vade_tarih: element2["vade_tarih"], tutar: element2["tutar"].toString(), odendi: element2["odendi"].toString(), notlar: element2["notlar"], odeme_yontemi_id: element2["odeme_yontemi_id"].toString(), dogrulama_kodu: element2["dogrulama_kodu"]));

            });
          }
        });
      });
      taksitler.forEach((element) {
        log('vade saysı '+element.vadeler.length.toString());
        element.vadeler.forEach((element2) {

          if(element2["odendi"].toString()=='0') {

            log("ekleniyor ");
            setState(() {

              taksitvadeleri.add(TaksitVade(
                  id: element2["id"].toString(),
                  taksitli_tahsilat_id: element2["taksitli_tahsilat_id"]
                      .toString(),
                  vade_tarih: element2["vade_tarih"].toString(),
                  tutar: element2["tutar"].toString(),
                  odendi: element2["odendi"].toString(),
                  notlar: element2["notlar"].toString(),
                  odeme_yontemi_id: element2["odeme_yontemi_id"].toString(),
                  dogrulama_kodu: element2["dogrulama_kodu"].toString())


              );

            });


          }
          if(element2["odendi"].toString()=='0' && DateTime.parse(element2["vade_tarih"]+'T00:00:00').isBefore(DateTime.now())){
            setState(() {

              adisyonkalemleri.add(TaksitVade(id: element2["id"].toString(), taksitli_tahsilat_id: element2["taksitli_tahsilat_id"].toString(), vade_tarih: element2["vade_tarih"], tutar: element2["tutar"].toString(), odendi: element2["odendi"].toString(), notlar: element2["notlar"].toString(), odeme_yontemi_id: element2["odeme_yontemi_id"]??"", dogrulama_kodu: element2["dogrulama_kodu"]??""));

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
        debugPrint('ürün var');
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
            content: Text('Devam etmek için önce müşteri seçiniz veya ekleyiniz.'),
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
        MaterialPageRoute(builder: (context) => HizmetSatisiDuzenleme( adisyonId: widget.adisyonId, musteriid: secilimusteridanisan?.id ??"", mevcuthizmet:mevcutadisyonhizmet ,senetlisatis: false,isletmebilgi: widget.isletmebilgi,)),
      ) : await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => HizmetSatisi(kullanicirolu: widget.kullanicirolu, mevcutadisyonId: widget.adisyonId,  musteriid: secilimusteridanisan?.id ??"",senetlisatis: false,isletmebilgi: widget.isletmebilgi)),
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
    double hariciindirim = tlyirakamacevir(harici_indirim.text);


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
      if(element is SenetVade)
      {
        String tutar = element.tutar;


        tutar = tutar.replaceAll(",", ".");
        fiyattoplam += double.parse(tutar);


      }
      if(element is TaksitVade)
      {
        String tutar = element.tutar;

        tutar = tutar.replaceAll(",", ".");
        fiyattoplam += double.parse(tutar);

      }




    });
    log("toplam : "+fiyattoplam.toString());
    log("indirim : "+indirimtutari.toString());
    log("harici : "+hariciindirim.toString());
    setState(() {
      birim_tutar.text = tryformat.format(fiyattoplam).toString();
      toplamindirimtutari.text = tryformat.format(indirimtutari+hariciindirim).toString();
      tahsilat_tutari.text = tryformat.format(fiyattoplam-indirimtutari-hariciindirim).toString();
      if(!onodemegirildi || tahsilat_tutari.text == odenecek_tutar.text)
        odenecek_tutar.text = tryformat.format(fiyattoplam-indirimtutari-hariciindirim).toString();
      else{

        kalan_alacak_tutar.text = tryformat.format(fiyattoplam- indirimtutari - hariciindirim - tlyirakamacevir(odenecek_tutar.text));
        taksit_toplam_tutar.text = kalan_alacak_tutar.text;
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
            content: Text('Devam etmek için önce müşteri seçiniz veya ekleyiniz.'),
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
        MaterialPageRoute(builder: (context) => UrunSatisiDuzenleme(musteriid: secilimusteridanisan?.id ??"", mevcuturun:mevcutadisyonurun ,senetlisatis: false,isletmebilgi: widget.isletmebilgi)),
      ) : await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => UrunSatisi(kullanicirolu: widget.kullanicirolu, mevcutadisyonId: widget.adisyonId, musteriid: secilimusteridanisan?.id ??"",senetlisatis: false,isletmebilgi: widget.isletmebilgi)),
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
            content: Text('Devam etmek için önce müşteri seçiniz veya ekleyiniz.'),
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
        MaterialPageRoute(builder: (context) => PaketSatisiDuzenleme(musteriid: secilimusteridanisan?.id ??"", mevcutpaket:mevcutadisyonpaket ,senetlisatis: false,isletmebilgi: widget.isletmebilgi)),
      ) : await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PaketSatisi(kullanicirolu: widget.kullanicirolu, mevcutadisyonId: widget.adisyonId, musteriid: secilimusteridanisan?.id ?? "",senetlisatis: false,isletmebilgi: widget.isletmebilgi)),
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
    return Scaffold(
      resizeToAvoidBottomInset: true,
      //floatingActionButton:  AltYuvarlakYeniEkleMenu(isletme_bilgi: widget.isletmebilgi,),

      appBar: AppBar(
        title:  const Text('Tahsilatlar',style: TextStyle(color: Colors.black),),

        leading: IconButton(
          icon: Icon(Icons.clear_rounded, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
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
            icon: Icon(Icons.add, color: Colors.black),
            iconSize: 26,
            onPressed: ()  async{
              final MusteriDanisan yenimusteridanisan =  await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => Yenimusteri(kullanicirolu: widget.kullanicirolu, isletmebilgi: widget.isletmebilgi,isim:"",telefon:"",sadeceekranikapat: true,)),
              );
              if(yenimusteridanisan != null)
                setState(() {
                  musteridanisanlar.add(yenimusteridanisan);
                  secilimusteridanisan = yenimusteridanisan;
                  dropdownKey.currentState?.addItemAndSelect(yenimusteridanisan);

                });

            },
          ),
          /*Platform.isIOS ? SizedBox():
          IconButton(
            icon: Icon(Icons.group_add, color: Colors.black),
            iconSize: 26,
            onPressed: (){
              rehberdenSecAlternatif(context,widget.isletmebilgi,widget.kullanicirolu);
            }, // New button to select multiple contacts
          ),*/


        ],
        backgroundColor: Colors.white,
      ),
      body: isloading ? Center(child: CircularProgressIndicator(),):
      GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
    child:  SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20,),
            widget.adisyonId == '' ?
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                    width: width*0.6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 20.0),
                          child: Text('Müşteri',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                        ),
                        SizedBox(height: 10,),
                        Container(
                          alignment: Alignment.center,
                          margin: EdgeInsets.only(left: 20, right: 20),
                          height: 50,
                          width: width*0.6,
                          child: LazyDropdown(
                            key: dropdownKey,
                            salonId: seciliisletme??'',
                            selectedItem: secilimusteridanisan,
                            onChanged: (value) {
                              secilimusteridanisan = value;
                              loadbar(value!);
                            },
                          ),
                        )


                      ],
                    )),
                Container(
                  width: width*0.2,
                  child:   Column(

                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [

                      SizedBox(height: 30,),

                      ElevatedButton(onPressed: () async{

                        final MusteriDanisan yenimusteridanisan =  await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => Yenimusteri(kullanicirolu: widget.kullanicirolu, isletmebilgi: widget.isletmebilgi,isim:"",telefon:"",sadeceekranikapat: true,)),
                        );
                        if(yenimusteridanisan != null)
                          setState(() {
                            musteridanisanlar.add(yenimusteridanisan);
                          });
                      },
                        child: Text('Yeni Ekle',style:TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple[800],
                          foregroundColor: Colors.white,
                          minimumSize: Size(100, 30),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),



                        ),
                      ),
                    ],
                  ),)
              ],
            ) : SizedBox(),
            SizedBox(height: 10),
            secilimusteridanisan != null ? Container(


              margin: EdgeInsets.only(left:20.0,right:20),
              decoration: BoxDecoration(
                color: Colors.white, // Set container background color
                border: Border.all(
                  color: Color(0XFFE0E0E0),
                  width: 1.2,
                ),
                borderRadius: BorderRadius.circular(20.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.15),
                    spreadRadius: 5,
                    blurRadius: 7,
                    offset: Offset(0,3), // changes position of shadow
                  ),
                ],

              ),

              child:  Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,

                children:[

                  Text(musteridanisanadi.text, style: TextStyle(color: Colors.black,fontSize: 18,fontWeight: FontWeight.bold),),
                  Container( padding: EdgeInsets.only(left: 20),
                    child: ElevatedButton(
                      onPressed: (){},
                      child:
                      Text(aktifsadikpasif.text ,style: TextStyle(fontSize: 15),),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: aktifPasifRenk,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0)
                          ),
                          minimumSize: Size(80, 30)
                      ),
                    ),),

                ],
              ) ,
            ) : SizedBox.shrink(),
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

                              // Null check ekleyin
                              if(item.personel != null) {
                                if(item.personel is Personel){
                                  Personel pers = item.personel;
                                  satan = pers.personel_adi;
                                }
                                else {
                                  satan = item.personel["personel_adi"] ?? "Personel Yok";
                                }
                              } else {
                                satan = "Personel Yok";
                              }

                              tutar = tryformat.format(double.parse(item.fiyat));
                            }

                            if(item is AdisyonUrun)
                            {
                              key=item.urun_id.toString();
                              kalem = item.urun["urun_adi"];
                              adet = item.adet;

                              // Null check ekleyin
                              if(item.personel != null) {
                                satan = item.personel["personel_adi"] ?? "Personel Yok";
                              } else {
                                satan = "Personel Yok";
                              }

                              tutar=tryformat.format(double.parse(item.fiyat));
                            }

                            if(item is AdisyonPaket)
                            {
                              key=item.paket_id.toString();
                              kalem = item.paket["paket_adi"];
                              adet="1";

                              // Null check ekleyin
                              if(item.personel != null) {
                                satan = item.personel["personel_adi"] ?? "Personel Yok";
                              } else {
                                satan = "Personel Yok";
                              }

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
                                                  dynamic kalemsilme = {};
                                                  bool senetveyataksitkalemi = false;
                                                  if(adisyonkalemleri[index] is AdisyonHizmet){
                                                    kalemsilme = await adisyonhizmetsil(adisyonkalemleri[index] as AdisyonHizmet, context);

                                                  }
                                                  else if(adisyonkalemleri[index] is AdisyonUrun){
                                                    kalemsilme = await adisyonurunsil(adisyonkalemleri[index] as AdisyonUrun, context);

                                                  }
                                                  else if(adisyonkalemleri[index] is AdisyonPaket){
                                                    kalemsilme = await adisyonpaketsil(adisyonkalemleri[index] as AdisyonPaket, context);

                                                  }
                                                  else {
                                                    senetveyataksitkalemi = true;
                                                    kalemsilme = {"basarili": "1"};
                                                  }
                                                  if(kalemsilme["basarili"]=="1" || senetveyataksitkalemi == true){

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
                                                  }
                                                  else
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text(kalemsilme["mesaj"]),
                                                      ),
                                                    );

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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [





                      Container(
                        padding: const EdgeInsets.only(left: 20.0),
                        child: Text('Tarih',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                      ),
                      SizedBox(height: 10,),
                      Container(
                        height: 40,
                        padding: EdgeInsets.only(left:20,right: 20),
                        child: TextFormField(
                          controller: tahsilat_tarihi,
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
                                tahsilat_tarihi.text =
                                    formattedDate; //set output date to TextField value.
                              });
                            } else {}
                          },
                        ),
                      ),
                      SizedBox(height: 10,),
                      Container(
                        padding: const EdgeInsets.only(left: 20.0),
                        child: Text('Birim Tutar(₺)',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                      ),
                      SizedBox(height: 10,),
                      Container(
                        height: 40,

                        padding: EdgeInsets.only(left:20,right: 20),
                        child: TextFormField(

                          keyboardType: TextInputType.phone,
                          enabled: false,
                          controller: birim_tutar,
                          onSaved: (value) {
                            birim_tutar.text = value!;
                          },

                          decoration: InputDecoration(

                            focusColor:Color(0xFF6A1B9A) ,

                            hoverColor: Color(0xFF6A1B9A) ,
                            filled: true,
                            fillColor: Colors.white,
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

                        padding: const EdgeInsets.only(left: 20.0),
                        child: Text('Müşteri İndirimi (%)',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                      ),
                      SizedBox(height: 10,),
                      Container(
                        height:40,
                        padding: EdgeInsets.only(left:20,right: 20),
                        child: TextFormField(
                          enabled: false,
                          keyboardType: TextInputType.phone,
                          controller:musteri_sabit_indirim,


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
                      Container(

                        padding: const EdgeInsets.only(left: 20.0),
                        child: Text('İndirim (₺)',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                      ),

                      SizedBox(height: 10,),
                      Container(
                        height:40,
                        padding: EdgeInsets.only(left:20,right: 20),
                        child: TextFormField(

                          controller: harici_indirim,
                          keyboardType: TextInputType.phone,
                          onChanged: (value) {
                            tutar_hesapla(false);

                          },
                          onSaved: (value) {
                            harici_indirim.text = value!;
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





                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.only(left: 20.0),
                        child: Text('Ödeme Yöntemi',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
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
                              dropdownSearchData: DropdownSearchData(
                                searchController: odemeyontemcontroller,
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
                                    controller: odemeyontemcontroller,
                                    decoration: InputDecoration(
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 8,
                                      ),
                                      hintText: 'Ara...',
                                      hintStyle: const TextStyle(fontSize: 12),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
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
                                  odemeyontemcontroller.clear();
                                }
                              },

                            )),
                      ),

                      SizedBox(height: 10,),
                      Container(
                        padding: const EdgeInsets.only(left: 20.0),
                        child: Text('Ödenecek Tutar(₺)',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                      ),
                      SizedBox(height: 10,),
                      Container(
                        height: 40,
                        padding: EdgeInsets.only(left:20,right: 20),
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
                      SizedBox(height: 10,),
                      Container(
                        padding: const EdgeInsets.only(left: 20.0),
                        child: Text('Kalan Alacak Tutarı(₺)',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                      ),
                      SizedBox(height: 10,),
                      Container(
                        height: 40,
                        padding: EdgeInsets.only(left:20,right: 20),
                        child: TextFormField(
                          enabled: false,
                          keyboardType: TextInputType.phone,
                          controller: kalan_alacak_tutar,
                          onSaved: (value) {
                            kalan_alacak_tutar.text = value!;
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
                    ],
                  ),
                )



              ],
            ),
            SizedBox(height: 10,),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(onPressed: (){
                  alacaklarigoster(context);

                },
                  child: Text('Alacaklar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    minimumSize: Size(110, 30),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                  ),
                ),
                ElevatedButton(

                  onPressed: (){
                    if(kalan_alacak_tutar.text=="" || kalan_alacak_tutar.text=="0,00")
                    {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('UYARI'),
                            content: Text('Taksit yapmadan önce lütfen kalan alacak tutarının belirli olması ve ödenecek tutarın indirimler dahil toplam tahsilat tutarından daha az olması gereklidir. Eğer kısmi ödeme yapılmadan tüm tutar üzerinden taksit yapılacaksa ödenecek tutarı 0 giriniz.'),
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
                    else
                    {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('Yeni Taksitli Tahsilat'),
                            content:
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Container(

                                  child: Text('Ödeme Başlangıç Tarihi',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                                ),
                                SizedBox(height: 10,),
                                Container(
                                  height: 40,
                                  padding: EdgeInsets.only(left:20,right: 20),
                                  child: TextFormField(
                                    controller: ilk_taksit_vade_tarihi,
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
                                          ilk_taksit_vade_tarihi.text =
                                              formattedDate; //set output date to TextField value.
                                        });
                                      } else {}
                                    },
                                  ),
                                ),
                                SizedBox(height: 10,),
                                Container(

                                  child: Text('Taksit Sayısı',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                                ),
                                SizedBox(height: 10,),
                                Container(
                                  height: 40,
                                  padding: EdgeInsets.only(left:20,right: 20),
                                  child: TextFormField(

                                    keyboardType: TextInputType.phone,
                                    controller: taksit_sayisi,
                                    onSaved: (value) {
                                      taksit_sayisi.text = value!;
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

                                  child: Text('Toplam Tutar (₺)',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                                ),
                                SizedBox(height: 10,),
                                Container(
                                  height: 40,
                                  padding: EdgeInsets.only(left:20,right: 20),
                                  child: TextFormField(
                                    enabled: false,
                                    keyboardType: TextInputType.phone,
                                    controller: taksit_toplam_tutar,
                                    onSaved: (value) {
                                      taksit_toplam_tutar.text = value!;
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
                              ],
                            ),

                            actions: <Widget>[
                              TextButton(
                                child: Text('KAYDET'),
                                onPressed: () async {


                                  int taksitResult = await taksitekleguncelle(context, seciliisletme,adisyonkalemleri,taksit_sayisi.text,ilk_taksit_vade_tarihi.text,taksit_toplam_tutar.text,secilimusteridanisan?.id ??"",toplamindirimtutari.text,selectedodemeyontemi?.id??"",odenecek_tutar.text,tahsilat_tarihi.text,"",harici_indirim.text);
                                  if (taksitResult == 200) {


                                    Navigator.of(context).pop();
                                    Navigator.of(context).pop();
                                    Navigator.of(context).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Taksitlendirme başarıyla kaydedildi'),
                                      ),
                                    );
                                    initialize();


                                  } else {


                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Taksitlendirme işlenirken bir hata oluştu. Hata kodu : '+taksitResult.toString()),
                                      ),
                                    );

                                  }
                                  setState(() {
                                    adisyonkalemleri.clear();
                                    taksitvadeleri.clear();
                                    senetvadeleri.clear();
                                    alacaklarigetir();
                                  });



                                },
                              ),
                              TextButton(
                                child: Text('KAPAT'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          );
                        },
                      );
                    }

                  },
                  child: Text('Taksit Yap'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple[800],
                    foregroundColor: Colors.white,
                    minimumSize: Size(110, 30),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                  ),
                ),
              ],
            ),



            SizedBox(height: 10,),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: (){
                    bool formisvalid = true;
                    String warningtext = "Tahsilatı kaydetmeden önce aşağıdaki hataları düzeltmeniz gerekmektedir!";
                    if(odenecek_tutar.text=="" || odenecek_tutar.text=="0,00")
                    {

                      formisvalid = false;
                      warningtext += "\n\nÖdenecek tutar 0'dan büyük olmalıdır.";
                    }
                    if(selectedodemeyontemi == null){
                      formisvalid = false;
                      warningtext += "\n\nÖdeme yöntemi seçilmelidir.";
                    }
                    if(!formisvalid)
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('UYARI'),
                            content: Text(warningtext),
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
                      tahsilet(context, seciliisletme,adisyonkalemleri,taksit_sayisi.text,ilk_taksit_vade_tarihi.text,taksit_toplam_tutar.text,secilimusteridanisan?.id ??"",toplamindirimtutari.text,selectedodemeyontemi?.id??"",odenecek_tutar.text,tahsilat_tarihi.text,"",harici_indirim.text);

                      setState(() {
                        adisyonkalemleri.clear();
                        taksitvadeleri.clear();
                        senetvadeleri.clear();
                        selectedodemeyontemi = null;
                        odenecek_tutar.text='0,00';
                        kalan_alacak_tutar.text = '0,00';

                      });
                      initialize();
                      Navigator.of(context).pop(); //tahsilat yaptıktan sonra kapanması için eklendi bu satır.
                    }




                  },
                  child: Row(
                    children: [
                      Icon(Icons.money_sharp),
                      Text(' Tahsil Et'),
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
    ));
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
                            foregroundColor: Colors.white,
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

                                child: TabBar(
                                  isScrollable: false,
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
                                    // Sondan başa doğru iterasyon — index kayması olmaz
                                    for (int i = isCheckedList.length - 1; i >= 0; i--) {
                                      if (isCheckedList[i]) {
                                        adisyonkalemleri.add(taksitvadeleri[i]);
                                        taksitvadeleri.removeAt(i);
                                      }
                                    }
                                    for (int i = isCheckedList2.length - 1; i >= 0; i--) {
                                      if (isCheckedList2[i]) {
                                        adisyonkalemleri.add(senetvadeleri[i]);
                                        senetvadeleri.removeAt(i);
                                      }
                                    }
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
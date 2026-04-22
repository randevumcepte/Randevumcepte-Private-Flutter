import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:randevu_sistem/Models/adisyonhizmetler.dart';
import 'package:randevu_sistem/Models/adisyonpaketler.dart';
import 'package:randevu_sistem/Models/adisyonurunler.dart';
import 'package:randevu_sistem/Models/isletmehizmetleri.dart';
import 'package:randevu_sistem/Models/musteri_danisanlar.dart';
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
import '../../../Models/senetvadeleri.dart';
import '../../../Models/taksitvadeleri.dart';
import '../../../Models/urunler.dart';
import '../../../Models/user.dart';
import '../../dashboard/hizmetsatisi.dart';
import '../../dashboard/hizmetsatisiduzenleme.dart';
import '../../dashboard/paketsatisi.dart';
import '../../dashboard/paketsatisiduzenleme.dart';
import '../../dashboard/urunsatisi.dart';
import '../../diger/menu/musteriler/yeni_musteri.dart';
import '../adisyonpage.dart';

class SatisEkrani extends StatefulWidget {
  final dynamic isletmebilgi;
  final String musteridanisanid;
  final int kullanicirolu;
  final Kullanici kullanici; // Yeni parametre


  SatisEkrani({
    Key? key,
    required this.isletmebilgi,
    required this.musteridanisanid,
    required this.kullanicirolu,
    required this.kullanici, // Yeni parametre

  }) : super(key: key);

  @override
  _SatisEkraniState createState() => _SatisEkraniState();
}

class _SatisEkraniState extends State<SatisEkrani> {
  bool isloading = true;
  Color? aktifPasifRenk;
  bool kalemleryukleniyor = false;
  String yeniSatisAdisyonId = '';

  final List<OdemeTuru> odemeyontem = [
    OdemeTuru(id: '1', odeme_turu: 'Nakit'),
    OdemeTuru(id: '2', odeme_turu: 'Kredi Kartı'),
    OdemeTuru(id: '3', odeme_turu: 'Havale/EFT'),
  ];

  var tryformat = NumberFormat.currency(locale: 'tr_TR', symbol: "");
  OdemeTuru? selectedodemeyontemi;
  TextEditingController odemeyontemcontroller = TextEditingController();

  TextEditingController tahsilat_tarihi = TextEditingController(
      text: DateFormat("yyyy-MM-dd").format(DateTime.now())
  );
  TextEditingController ilk_taksit_vade_tarihi = TextEditingController(
      text: DateFormat("yyyy-MM-dd").format(DateTime.now())
  );
  TextEditingController taksit_sayisi = TextEditingController(text: "1");
  TextEditingController taksit_toplam_tutar = TextEditingController();

  late List<MusteriDanisan> musteridanisanlar;
  MusteriDanisan? secilimusteridanisan;
  final TextEditingController textEditingController = TextEditingController();

  List<bool> isCheckedList = [];
  List<bool> isCheckedList2 = [];

  // Kontroller
  TextEditingController musteri_sabit_indirim = TextEditingController(text: "0");
  TextEditingController birim_tutar = TextEditingController();
  TextEditingController odenecek_tutar = TextEditingController();
  TextEditingController tahsilat_tutari = TextEditingController();
  TextEditingController kalan_alacak_tutar = TextEditingController();
  TextEditingController harici_indirim = TextEditingController();
  TextEditingController toplamindirimtutari = TextEditingController();
  TextEditingController musteridanisanadi = TextEditingController();
  TextEditingController aktifsadikpasif = TextEditingController();

  bool _dataAdded = false;
  double _containerHeight = 0.0;

  // Diğer değişkenler
  late String seciliisletme;
  List<AdisyonKalemleri> adisyonkalemleri = [];
  List<AdisyonKalemleri> senetvadeleri = [];
  List<AdisyonKalemleri> taksitvadeleri = [];

  int secilialacaksenet = 0;
  int secilialacaktaksit = 0;

  // Modern Renk Palette
  final Color _primaryColor = Color(0xFF7C4DFF);
  final Color _secondaryColor = Color(0xFFB388FF);
  final Color _accentColor = Color(0xFFEA80FC);
  final Color _successColor = Color(0xFF00E676);
  final Color _warningColor = Color(0xFFFF9100);
  final Color _errorColor = Color(0xFFFF5252);
  final Color _backgroundColor = Color(0xFFF8F9FF);
  final Color _surfaceColor = Colors.white;
  final Color _textColor = Color(0xFF1A1A2E);
  final Color _textLightColor = Color(0xFF6B7280);
  final Color _borderColor = Color(0xFFE5E7EB);
  final Color _shadowColor = Color(0x0A1A1A2E);

  // Gradient Colors
  final Gradient _primaryGradient = LinearGradient(
    colors: [Color(0xFF7C4DFF), Color(0xFFB388FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  final Gradient _successGradient = LinearGradient(
    colors: [Color(0xFF00E676), Color(0xFF69F0AE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  final Gradient _warningGradient = LinearGradient(
    colors: [Color(0xFFFF9100), Color(0xFFFFAB40)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void initState() {
    super.initState();
    initialize();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void loadbar(MusteriDanisan value) async {
    String musterituru = await musteriDanisanTuru(seciliisletme, value?.id.toString() ?? "");
    log('müşteri türü ' + musterituru.toString());
    final settings = await fetchSalonSettings(seciliisletme);
    String indirimtext = "0";
    String aktifpasif = "";

    if (musterituru == "1") {
      aktifpasif = "Aktif";
      aktifPasifRenk = Color(0xFF7C4DFF);
      indirimtext = settings['aktif_musteri_indirim_yuzde']?.toString() ?? '0';
    } else if (musterituru == "2") {
      aktifPasifRenk = Color(0xFF00E676);
      aktifpasif = "Sadık";
      indirimtext = settings['sadik_musteri_indirim_yuzde']?.toString() ?? '0';
    } else {
      aktifPasifRenk = Color(0xFF9E9E9E);
      aktifpasif = "Pasif";
    }

    setState(() {
      kalemleryukleniyor = true;

      // Sadece mevcut kalemleri temizle, alacakları getirme
      adisyonkalemleri.clear();

      // Taksit ve senet vadelerini temizle (alacakları getirmemek için)
      taksitvadeleri.clear();
      senetvadeleri.clear();

      secilimusteridanisan = value;
      musteri_sabit_indirim.text = indirimtext;
      aktifsadikpasif.text = aktifpasif;
      musteridanisanadi.text = (secilimusteridanisan?.name)!;

      // Alacakları getirme kısmını kaldır
      // alacaklarigetir(); // BU SATIRI KALDIRIN

      setState(() {
        kalemleryukleniyor = false;
        tutar_hesapla(false);
      });
    });
  }
  Future<void> initialize() async {
    seciliisletme = (await secilisalonid())!;

    String hariciIndirimText = tryformat.format(0).toString();
    String kalanAlacakText = tryformat.format(0).toString();

    MusteriDanisan? musteridanisanliste;
    if (widget.musteridanisanid != "") {
      musteridanisanliste = await musterilistegetirTahsilat(widget.musteridanisanid);
    }

    setState(() {
      harici_indirim.text = hariciIndirimText;
      kalan_alacak_tutar.text = kalanAlacakText;

      if (musteridanisanliste != null) {
        secilimusteridanisan = musteridanisanliste;
        loadbar(musteridanisanliste);
      }

      isloading = false;
    });
  }

  void alacaklarigetir() async {
    if (secilimusteridanisan != null) {
      dynamic senettaksitdata = await senetvetaksitler(seciliisletme!, secilimusteridanisan?.id ?? "","");

      List<Senet> senetler = senettaksitdata['senet'].map<Senet>((json) => Senet.fromJson(json)).toList();
      List<TaksitliTahsilat> taksitler = senettaksitdata['taksit'].map<TaksitliTahsilat>((json) => TaksitliTahsilat.fromJson(json)).toList();
      List<AdisyonHizmet> adisyonhizmetler = senettaksitdata["adisyon_hizmet"].map<AdisyonHizmet>((json) => AdisyonHizmet.fromJson(json)).toList();
      List<AdisyonUrun> adisyonurunler = senettaksitdata["adisyon_urun"].map<AdisyonUrun>((json) => AdisyonUrun.fromJson(json)).toList();
      List<AdisyonPaket> adisyonpaketler = senettaksitdata["adisyon_paket"].map<AdisyonPaket>((json) => AdisyonPaket.fromJson(json)).toList();

      senetler.forEach((element) {
        element.vadeler.forEach((element2) {
          if (element2["odendi"] == "0") {
            setState(() {
              senetvadeleri.add(SenetVade(
                  id: element2["id"].toString(),
                  senet_id: element2["senet_id"].toString(),
                  vade_tarih: element2["vade_tarih"],
                  tutar: element2["tutar"].toString(),
                  odendi: element2["odendi"].toString(),
                  notlar: element2["notlar"],
                  odeme_yontemi_id: element2["odeme_yontemi_id"].toString(),
                  dogrulama_kodu: element2["dogrulama_kodu"]
              ));
            });
          }
        });
      });

      taksitler.forEach((element) {
        element.vadeler.forEach((element2) {
          if (element2["odendi"].toString() == '0') {
            setState(() {
              taksitvadeleri.add(TaksitVade(
                  id: element2["id"].toString(),
                  taksitli_tahsilat_id: element2["taksitli_tahsilat_id"].toString(),
                  vade_tarih: element2["vade_tarih"].toString(),
                  tutar: element2["tutar"].toString(),
                  odendi: element2["odendi"].toString(),
                  notlar: element2["notlar"].toString(),
                  odeme_yontemi_id: element2["odeme_yontemi_id"].toString(),
                  dogrulama_kodu: element2["dogrulama_kodu"].toString()
              ));
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
    if (secilimusteridanisan == null) {
      _showUyariDialog('Devam etmek için önce müşteri seçiniz veya ekleyiniz.');
      return;
    }

    final AdisyonHizmet result = mevcutadisyonhizmet != null
        ? await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HizmetSatisiDuzenleme(
          musteriid: secilimusteridanisan?.id ?? "",
          mevcuthizmet: mevcutadisyonhizmet,
          senetlisatis: false,
          isletmebilgi: widget.isletmebilgi,
          adisyonId: "",
        ),
      ),
    )
        : await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HizmetSatisi(
          musteriid: secilimusteridanisan?.id ?? "",
          senetlisatis: false,
          isletmebilgi: widget.isletmebilgi,
          kullanicirolu: widget.kullanicirolu,
          mevcutadisyonId : yeniSatisAdisyonId,

        ),
      ),
    );

    if (result != null) {
      setState(() {
        if (mevcutadisyonhizmet != null) {
          adisyonkalemleri.removeWhere((element) => element is AdisyonHizmet ? element.id == mevcutadisyonhizmet.id : false);
        }
        adisyonkalemleri.add(result);

        tutar_hesapla(false);
        yeniSatisAdisyonId = result.adisyon_id;
      });
    }
  }

  void urunsatisi(AdisyonUrun? mevcutadisyonurun) async {
    if (secilimusteridanisan == null) {
      _showUyariDialog('Devam etmek için önce müşteri seçiniz veya ekleyiniz.');
      return;
    }

    final AdisyonUrun result = mevcutadisyonurun != null
        ? await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UrunSatisiDuzenleme(
          musteriid: secilimusteridanisan?.id ?? "",
          mevcuturun: mevcutadisyonurun,
          senetlisatis: false,
          isletmebilgi: widget.isletmebilgi,
        ),
      ),
    )
        : await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UrunSatisi(
          musteriid: secilimusteridanisan?.id ?? "",
          senetlisatis: false,
          isletmebilgi: widget.isletmebilgi,
          kullanicirolu: widget.kullanicirolu,
          mevcutadisyonId : yeniSatisAdisyonId,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        if (mevcutadisyonurun != null) {
          adisyonkalemleri.removeWhere((element) => element is AdisyonUrun ? element.id == mevcutadisyonurun.id : false);
        }
        adisyonkalemleri.add(result);
        yeniSatisAdisyonId = result.adisyon_id;
        tutar_hesapla(false);

      });
    }
  }

  void paketsatisi(AdisyonPaket? mevcutadisyonpaket) async {
    if (secilimusteridanisan == null) {
      _showUyariDialog('Devam etmek için önce müşteri seçiniz veya ekleyiniz.');
      return;
    }

    final AdisyonPaket result = mevcutadisyonpaket != null
        ? await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaketSatisiDuzenleme(
          musteriid: secilimusteridanisan?.id ?? "",
          mevcutpaket: mevcutadisyonpaket,
          senetlisatis: false,
          isletmebilgi: widget.isletmebilgi,
        ),
      ),
    )
        : await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaketSatisi(
          musteriid: secilimusteridanisan?.id ?? "",
          senetlisatis: false,
          isletmebilgi: widget.isletmebilgi,
          kullanicirolu: widget.kullanicirolu,
          mevcutadisyonId : yeniSatisAdisyonId,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        if (mevcutadisyonpaket != null) {
          adisyonkalemleri.removeWhere((element) => element is AdisyonPaket ? element.id == mevcutadisyonpaket.id : false);
        }
        adisyonkalemleri.add(result);
        yeniSatisAdisyonId = result.adisyon_id;
        tutar_hesapla(false);
      });
    }
  }

  void tutar_hesapla(bool onodemegirildi) {
    double fiyattoplam = 0;
    double indirimtutari = 0;
    double hariciindirim = tlyirakamacevir(harici_indirim.text);

    adisyonkalemleri.forEach((element) {
      if (element is AdisyonHizmet) {
        String tutar = element.fiyat;
        tutar = tutar.replaceAll(",", ".");
        fiyattoplam += double.parse(tutar);
        indirimtutari += (double.parse(tutar) * (double.parse(musteri_sabit_indirim.text) / 100));
      }

      if (element is AdisyonUrun) {
        String tutar = element.fiyat;
        tutar = tutar.replaceAll(",", ".");
        fiyattoplam += double.parse(tutar);
        indirimtutari += (double.parse(tutar) * (double.parse(musteri_sabit_indirim.text) / 100));
      }

      if (element is AdisyonPaket) {
        String tutar = element.fiyat;
        tutar = tutar.replaceAll(",", ".");
        fiyattoplam += double.parse(tutar);
        indirimtutari += (double.parse(tutar) * (double.parse(musteri_sabit_indirim.text) / 100));
      }

      if (element is SenetVade) {
        String tutar = element.tutar;
        tutar = tutar.replaceAll(",", ".");
        fiyattoplam += double.parse(tutar);
      }

      if (element is TaksitVade) {
        String tutar = element.tutar;
        tutar = tutar.replaceAll(",", ".");
        fiyattoplam += double.parse(tutar);
      }
    });

    setState(() {
      birim_tutar.text = tryformat.format(fiyattoplam).toString();
      toplamindirimtutari.text = tryformat.format(indirimtutari + hariciindirim).toString();
      tahsilat_tutari.text = tryformat.format(fiyattoplam - indirimtutari - hariciindirim).toString();

      if (!onodemegirildi || tahsilat_tutari.text == odenecek_tutar.text) {
        odenecek_tutar.text = tryformat.format(fiyattoplam - indirimtutari - hariciindirim).toString();
      } else {
        kalan_alacak_tutar.text = tryformat.format(fiyattoplam - indirimtutari - hariciindirim - tlyirakamacevir(odenecek_tutar.text));
        taksit_toplam_tutar.text = kalan_alacak_tutar.text;
      }
    });
  }

  void _showUyariDialog(String mesaj) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: _surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 24,
          title: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: _warningGradient,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.white, size: 24),
                SizedBox(width: 12),
                Text(
                  'UYARI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              mesaj,
              style: TextStyle(
                fontSize: 15,
                color: _textLightColor,
                height: 1.5,
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Kapat',
                style: TextStyle(
                  color: _primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildTarihPicker(TextEditingController controller, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _textLightColor,
            ),
          ),
        ),
        Container(
          height: 50,
          decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: _shadowColor,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: InputBorder.none,
              suffixIcon: Container(
                margin: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.calendar_today_rounded, color: _primaryColor, size: 20),
              ),
              hintText: 'Tarih seçin',
              hintStyle: TextStyle(color: _textLightColor.withOpacity(0.7)),
            ),
            readOnly: true,
            style: TextStyle(fontSize: 15, color: _textColor, fontWeight: FontWeight.w500),
            onTap: () async {
              DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(1950),
                lastDate: DateTime(2100),
                builder: (context, child) {
                  return Theme(
                    data: ThemeData.light().copyWith(
                      primaryColor: _primaryColor,
                      colorScheme: ColorScheme.light(primary: _primaryColor),
                      buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
                    ),
                    child: child!,
                  );
                },
              );

              if (pickedDate != null) {
                String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
                setState(() {
                  controller.text = formattedDate;
                });
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    bool enabled = true,
    bool isCurrency = false,
    bool isPercentage = false,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _textLightColor,
            ),
          ),
        ),
        Container(
          height: 50,
          decoration: BoxDecoration(
            color: enabled ? _surfaceColor : _backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: enabled ? _borderColor : _borderColor.withOpacity(0.5),
              width: 1,
            ),
            boxShadow: enabled
                ? [
              BoxShadow(
                color: _shadowColor,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ]
                : null,
          ),
          child: TextFormField(
            controller: controller,
            enabled: enabled,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: InputBorder.none,
              suffixText: isCurrency ? '₺' : (isPercentage ? '%' : ''),
              suffixStyle: TextStyle(
                color: _primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
              hintText: '0${isCurrency ? ',00' : ''}',
              hintStyle: TextStyle(color: _textLightColor.withOpacity(0.5)),
            ),
            style: TextStyle(
              fontSize: 15,
              color: _textColor,
              fontWeight: FontWeight.w500,
            ),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildOdemeYontemi() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 8),
          child: Text(
            'Ödeme Yöntemi',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _textLightColor,
            ),
          ),
        ),
        Container(
          height: 50,
          decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: _shadowColor,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton2<OdemeTuru>(
              isExpanded: true,
              hint: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Ödeme yöntemi seçin',
                  style: TextStyle(
                    fontSize: 15,
                    color: _textLightColor.withOpacity(0.7),
                  ),
                ),
              ),
              items: odemeyontem
                  .map((item) => DropdownMenuItem(
                value: item,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    item.odeme_turu,
                    style: TextStyle(
                      fontSize: 15,
                      color: _textColor,
                      fontWeight: FontWeight.w500,
                    ),
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
              buttonStyleData: ButtonStyleData(
                padding: EdgeInsets.symmetric(horizontal: 16),
                height: 50,
              ),
              dropdownStyleData: DropdownStyleData(
                maxHeight: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: _surfaceColor,
                  boxShadow: [
                    BoxShadow(
                      color: _shadowColor,
                      blurRadius: 16,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
              ),
              menuItemStyleData: MenuItemStyleData(
                height: 45,
                padding: EdgeInsets.symmetric(horizontal: 12),
              ),
              iconStyleData: IconStyleData(
                icon: Icon(Icons.keyboard_arrow_down_rounded, color: _primaryColor, size: 24),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKalemListesi() {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: _shadowColor,
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          if (adisyonkalemleri.isNotEmpty)
            ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: adisyonkalemleri.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: _borderColor,
                indent: 16,
                endIndent: 16,
              ),
              itemBuilder: (context, index) {
                final item = adisyonkalemleri[index];
                String key = "";
                String kalem = "";
                String adet = "";
                String satan = "";
                String tutar = "";
                IconData icon = Icons.receipt_rounded;
                Color iconColor = _primaryColor;
                Color backgroundColor = _primaryColor.withOpacity(0.1);

                if (item is AdisyonHizmet) {
                  key = item.hizmet_id.toString();
                  kalem = item.hizmet["hizmet_adi"];
                  adet = "1";
                  if (item.personel != null) {
                    if (item.personel is Personel) {
                      Personel pers = item.personel;
                      satan = pers.personel_adi;
                    } else {
                      satan = item.personel["personel_adi"] ?? "Personel Yok";
                    }
                  } else {
                    satan = "Personel Yok";
                  }
                  tutar = tryformat.format(double.parse(item.fiyat));
                  icon = Icons.spa_rounded;
                  iconColor = Color(0xFF7C4DFF);
                  backgroundColor = Color(0xFF7C4DFF).withOpacity(0.1);
                }

                if (item is AdisyonUrun) {
                  key = item.urun_id.toString();
                  kalem = item.urun["urun_adi"];
                  adet = item.adet;
                  satan = item.personel?["personel_adi"] ?? "Personel Yok";
                  tutar = tryformat.format(double.parse(item.fiyat));
                  icon = Icons.shopping_bag_rounded;
                  iconColor = Color(0xFFEA80FC);
                  backgroundColor = Color(0xFFEA80FC).withOpacity(0.1);
                }

                if (item is AdisyonPaket) {
                  key = item.paket_id.toString();
                  kalem = item.paket["paket_adi"];
                  adet = "1";
                  satan = item.personel?["personel_adi"] ?? "Personel Yok";
                  tutar = tryformat.format(double.parse(item.fiyat));
                  icon = Icons.card_membership_rounded;
                  iconColor = Color(0xFF00E5FF);
                  backgroundColor = Color(0xFF00E5FF).withOpacity(0.1);
                }

                if (item is SenetVade) {
                  key = item.id.toString();
                  kalem = "${item.id} nolu Senet vadesi";
                  adet = "1";
                  satan = DateFormat('dd.MM.yyyy').format(DateTime.parse(item.vade_tarih));
                  tutar = tryformat.format(double.parse(item.tutar));
                  icon = Icons.description_rounded;
                  iconColor = Color(0xFFFF9100);
                  backgroundColor = Color(0xFFFF9100).withOpacity(0.1);
                }

                if (item is TaksitVade) {
                  key = item.id.toString();
                  kalem = "${item.id} nolu Taksit vadesi";
                  adet = "1";
                  satan = DateFormat('dd.MM.yyyy').format(DateTime.parse(item.vade_tarih));
                  tutar = tryformat.format(double.parse(item.tutar));
                  icon = Icons.payment_rounded;
                  iconColor = Color(0xFF00E676);
                  backgroundColor = Color(0xFF00E676).withOpacity(0.1);
                }

                return Dismissible(
                  key: Key(key),
                  direction: DismissDirection.horizontal,
                  background: Container(
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        SizedBox(width: 20),
                        Icon(Icons.edit_rounded, color: Colors.green),
                        SizedBox(width: 10),
                        Text('Düzenle', style: TextStyle(color: Colors.green)),
                      ],
                    ),
                  ),
                  secondaryBackground: Container(
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('Sil', style: TextStyle(color: Colors.red)),
                        SizedBox(width: 10),
                        Icon(Icons.delete_rounded, color: Colors.red),
                        SizedBox(width: 20),
                      ],
                    ),
                  ),
                  confirmDismiss: (direction) async {
                    if (direction == DismissDirection.startToEnd) {
                      if (item is AdisyonHizmet) hizmetsatisi(item);
                      if (item is AdisyonUrun) urunsatisi(item);
                      if (item is AdisyonPaket) paketsatisi(item);
                      return false;
                    } else {
                      return await showDialog(
                        context: context,
                        builder: (BuildContext context2) {
                          return AlertDialog(
                            backgroundColor: _surfaceColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            title: Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFFFF5252), Color(0xFFFF8A80)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.delete_forever_rounded, color: Colors.white, size: 24),
                                  SizedBox(width: 12),
                                  Text(
                                    "Satış Kalemini Sil",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            content: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Text(
                                "Bu satış kalemini silmek istediğinize emin misiniz? Bu işlem geri alınamaz.",
                                style: TextStyle(
                                  fontSize: 15,
                                  color: _textLightColor,
                                  height: 1.5,
                                ),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context2).pop(false),
                                child: Text(
                                  "VAZGEÇ",
                                  style: TextStyle(
                                    color: _textLightColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  Navigator.of(context2).pop(true);
                                  dynamic kalemsilme = {};
                                  bool senetveyataksitkalemi = false;

                                  if (item is AdisyonHizmet) {
                                    kalemsilme = await adisyonhizmetsil(item, context);
                                  } else if (item is AdisyonUrun) {
                                    kalemsilme = await adisyonurunsil(item, context);
                                  } else if (item is AdisyonPaket) {
                                    kalemsilme = await adisyonpaketsil(item, context);
                                  } else {
                                    senetveyataksitkalemi = true;
                                    kalemsilme = {"basarili": "1"};
                                  }

                                  if (kalemsilme["basarili"] == "1" || senetveyataksitkalemi) {
                                    setState(() {
                                      if (item is SenetVade) {
                                        senetvadeleri.add(item);
                                        senetvadeleri.sort((a, b) => a.getSortValue().compareTo(b.getSortValue()));
                                      }
                                      if (item is TaksitVade) {
                                        taksitvadeleri.add(item);
                                        taksitvadeleri.sort((a, b) => a.getSortValue().compareTo(b.getSortValue()));
                                      }
                                      adisyonkalemleri.removeAt(index);
                                      tutar_hesapla(false);
                                    });
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(kalemsilme["mesaj"]),
                                        backgroundColor: Colors.red,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFFFF5252),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                ),
                                child: Text(
                                  "SİL",
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: iconColor.withOpacity(0.2), width: 1),
                        ),
                        child: Icon(icon, color: iconColor, size: 22),
                      ),
                      title: Text(
                        kalem,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        satan,
                        style: TextStyle(
                          fontSize: 13,
                          color: _textLightColor,
                        ),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _backgroundColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$adet Adet',
                              style: TextStyle(
                                fontSize: 12,
                                color: _textLightColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '$tutar ₺',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _primaryColor,
                            ),
                          ),
                        ],
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                );
              },
            )
          else
            Container(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _backgroundColor,
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(color: _borderColor, width: 1),
                    ),
                    child: Icon(
                      Icons.shopping_cart_outlined,
                      size: 40,
                      color: _textLightColor.withOpacity(0.3),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Henüz satış  eklenmemiş',
                    style: TextStyle(
                      fontSize: 16,
                      color: _textLightColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Yukardaki butonlardan satış ekleyebilirsiniz',
                      style: TextStyle(
                        fontSize: 14,
                        color: _textLightColor.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMusteriBilgi() {
    if (secilimusteridanisan == null) return SizedBox.shrink();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _surfaceColor,
            _surfaceColor,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: _shadowColor,
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.person_rounded, color: _primaryColor, size: 22),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            musteridanisanadi.text,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: _textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Müşteri',
                            style: TextStyle(
                              fontSize: 13,
                              color: _textLightColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  aktifPasifRenk?.withOpacity(0.9) ?? _primaryColor.withOpacity(0.9),
                  aktifPasifRenk?.withOpacity(0.7) ?? _primaryColor.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: (aktifPasifRenk ?? _primaryColor).withOpacity(0.2),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              aktifsadikpasif.text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String text,
    required Color color,
    required VoidCallback onPressed,
    IconData? icon,
    bool isOutlined = false,
    bool isSmall = false,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isOutlined ? Colors.transparent : color,
        foregroundColor: isOutlined ? color : Colors.white,
        minimumSize: isSmall ? Size(0, 42) : Size(120, 68),
        padding: EdgeInsets.symmetric(horizontal: isSmall ? 8 : 15, vertical: isSmall ? 8 : 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isOutlined ? BorderSide(color: color, width: 1.5) : BorderSide.none,
        ),
        elevation: isOutlined ? 0 : 4,
        shadowColor: isOutlined ? Colors.transparent : color.withOpacity(0.3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: isSmall ? 13 : 14),
            SizedBox(width: isSmall ? 1 : 2),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: isSmall ? 11 : 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButtons() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: _shadowColor,
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: _buildActionButton(
              text: 'Hizmet Ekle',
              color: Color(0xFF7C4DFF),
              onPressed: () => hizmetsatisi(null),
              icon: Icons.spa_outlined,
              isSmall: true,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: _buildActionButton(
              text: 'Ürün Ekle',
              color: Color(0xFFEA80FC),
              onPressed: () => urunsatisi(null),
              icon: Icons.shopping_bag_rounded,
              isSmall: true,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: _buildActionButton(
              text: 'Paket Ekle',
              color: Color(0xFF64A3FF),
              onPressed: () => paketsatisi(null),
              icon: Icons.card_membership_rounded,
              isSmall: true,
            ),
          ),
        ],
      ),
    );
  }

  void _showTaksitDialog() {
    if (kalan_alacak_tutar.text == "" || kalan_alacak_tutar.text == "0,00") {
      _showUyariDialog(
        'Taksit yapmadan önce lütfen kalan alacak tutarının belirli olması ve ödenecek tutarın indirimler dahil toplam tahsilat tutarından daha az olması gereklidir. Eğer kısmi ödeme yapılmadan tüm tutar üzerinden taksit yapılacaksa ödenecek tutarı 0 giriniz.',
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: _surfaceColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 24,
              child: Container(
                padding: EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: _primaryGradient,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.payment_rounded, color: Colors.white, size: 24),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'Yeni Taksitli Tahsilat',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: _textColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24),
                      _buildTarihPicker(ilk_taksit_vade_tarihi, 'İlk Taksit Tarihi'),
                      SizedBox(height: 20),
                      _buildInputField(
                        controller: taksit_sayisi,
                        label: 'Taksit Sayısı',
                      ),
                      SizedBox(height: 20),
                      _buildInputField(
                        controller: taksit_toplam_tutar,
                        label: 'Toplam Taksit Tutarı',
                        enabled: false,
                        isCurrency: true,
                      ),
                      SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            child: Text(
                              'İPTAL',
                              style: TextStyle(
                                color: _textLightColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () async {
                              int taksitResult = await taksitekleguncelle(
                                context,
                                seciliisletme,
                                adisyonkalemleri,
                                taksit_sayisi.text,
                                ilk_taksit_vade_tarihi.text,
                                taksit_toplam_tutar.text,
                                secilimusteridanisan?.id ?? "",
                                toplamindirimtutari.text,
                                selectedodemeyontemi?.id ?? "",
                                odenecek_tutar.text,
                                tahsilat_tarihi.text,
                                "",
                                harici_indirim.text,
                              );

                              if (taksitResult == 200) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Taksitlendirme başarıyla kaydedildi'),
                                    backgroundColor: _successColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                initialize();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Taksitlendirme işlenirken bir hata oluştu. Hata kodu: $taksitResult'),
                                    backgroundColor: Colors.red,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    behavior: SnackBarBehavior.floating,
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
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryColor,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                            ),
                            child: Text(
                              'KAYDET',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
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

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    bool isTablet = width > 600;
    String currentDateTime = DateFormat('dd MMMM yyyy EEEE HH:mm', 'tr_TR').format(DateTime.now());

    return Scaffold(
      backgroundColor: _backgroundColor,
      // Kaydet Butonu - Scaffold'ın bottomNavigationBar'ına ekleyin
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _surfaceColor,
          border: Border(
            top: BorderSide(color: _borderColor, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: _shadowColor,
              blurRadius: 20,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: adisyonkalemleri.isEmpty
              ? null
              : () {
            // AdisyonlarPage'ye git
            Navigator.pop(context, {'refresh': true});          },
          style: ElevatedButton.styleFrom(
            backgroundColor: adisyonkalemleri.isEmpty
                ? _textLightColor.withOpacity(0.3)
                : _primaryColor,
            foregroundColor: Colors.white,
            minimumSize: Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
            shadowColor: _primaryColor.withOpacity(0.3),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.save_rounded, size: 22),
              SizedBox(width: 10),
              Text(
                'KAYDET',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        title: Text(
          'Yeni Satış',
          style: TextStyle(
            color: _textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: -0.3,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.close_outlined, color: _primaryColor, size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
        toolbarHeight: 64,
        backgroundColor: _surfaceColor,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: _surfaceColor,
        actions: [
          if (widget.isletmebilgi["demo_hesabi"].toString() == "1")
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: SizedBox(
                width: 100,
                child: YukseltButonu(isletme_bilgi: widget.isletmebilgi),
              ),
            ),
          Container(
            margin: EdgeInsets.only(right: 16),
            child: IconButton(
              icon: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.person_add_alt_1_rounded, color: _primaryColor, size: 22),
              ),
              onPressed: () async {
                final MusteriDanisan yenimusteridanisan = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Yenimusteri(
                      kullanicirolu: widget.kullanicirolu,
                      isletmebilgi: widget.isletmebilgi,
                      isim: "",
                      telefon: "",
                      sadeceekranikapat: true,
                    ),
                  ),
                );
                if (yenimusteridanisan != null) {
                  setState(() {
                    secilimusteridanisan = yenimusteridanisan;
                    loadbar(yenimusteridanisan);
                  });
                }
              },
            ),
          ),
        ],
      ),
      body: isloading
          ? Center(
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: _primaryGradient,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: Colors.white,
            ),
          ),
        ),
      )
          : SingleChildScrollView(
        padding: EdgeInsets.only(bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),

            // Müşteri Seçim Bölümü
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tarih ve Saat Kartı (Vurgulu)
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 20),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          _primaryColor.withOpacity(0.08),
                          _secondaryColor.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _primaryColor.withOpacity(0.2), width: 1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _primaryColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.calendar_today_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tarih ve Saat',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _textLightColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  currentDateTime,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: _textColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                      ],
                    ),
                  ),

                  SizedBox(height: 24),
                  Text(
                    'Müşteri Seçimi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _textColor,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: _surfaceColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _borderColor, width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: _shadowColor,
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: LazyDropdown(
                            salonId: seciliisletme,
                            selectedItem: secilimusteridanisan,
                            onChanged: (value) {
                              secilimusteridanisan = value;
                              loadbar(value!);
                            },
                          ),
                        ),
                      ),


                    ],
                  ),
                ],
              ),
            ),


            SizedBox(height: 12),
            // Müşteri Bilgi Kartı
            if (secilimusteridanisan != null) _buildMusteriBilgi(),

            SizedBox(height: 12),

            // Satış Kalemleri Ekleme Butonları
            _buildFloatingActionButtons(),

            SizedBox(height: 24),

            // Satış Kalemleri Listesi Başlık
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Satış Detayları',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _textColor,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (adisyonkalemleri.isNotEmpty)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${adisyonkalemleri.length} kalem',
                        style: TextStyle(
                          fontSize: 13,
                          color: _primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            SizedBox(height: 12),

            // Satış Kalemleri Listesi
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: _buildKalemListesi(),
            ),



            SizedBox(height: 32),
          ],
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
            return Dialog(
              backgroundColor: _surfaceColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              insetPadding: EdgeInsets.all(20),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: _borderColor, width: 1),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Alacaklar',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _textColor,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close_rounded, color: _textLightColor),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: DefaultTabController(
                        length: 2,
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: _backgroundColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              margin: EdgeInsets.all(16),
                              child: TabBar(
                                indicatorSize: TabBarIndicatorSize.tab,
                                labelColor: Colors.white,
                                unselectedLabelColor: _textLightColor,
                                indicator: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  gradient: _primaryGradient,
                                ),
                                tabs: [
                                  Tab(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                      child: Text(
                                        "Taksitler",
                                        style: TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ),
                                  Tab(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                      child: Text(
                                        "Senetler",
                                        style: TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: TabBarView(
                                children: [
                                  SingleChildScrollView(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Column(
                                        children: [
                                          kalemleryukleniyor
                                              ? Padding(
                                            padding: const EdgeInsets.all(32.0),
                                            child: CircularProgressIndicator(color: _primaryColor),
                                          )
                                              : taksitvadeleri.isEmpty
                                              ? Padding(
                                            padding: const EdgeInsets.all(32.0),
                                            child: Column(
                                              children: [
                                                Icon(Icons.payments_rounded, size: 60, color: _textLightColor.withOpacity(0.3)),
                                                SizedBox(height: 16),
                                                Text(
                                                  'Taksit bulunamadı',
                                                  style: TextStyle(color: _textLightColor),
                                                ),
                                              ],
                                            ),
                                          )
                                              : ListView.separated(
                                            shrinkWrap: true,
                                            physics: NeverScrollableScrollPhysics(),
                                            itemCount: taksitvadeleri.length,
                                            separatorBuilder: (context, index) => Divider(color: _borderColor),
                                            itemBuilder: (context, index) {
                                              final item2 = taksitvadeleri[index];
                                              String kalem2 = "";
                                              String satan2 = "";
                                              String tutar2 = "";

                                              if (item2 is TaksitVade) {
                                                kalem2 = "${item2.id} nolu Taksit vadesi";
                                                satan2 = DateFormat('dd.MM.yyyy').format(
                                                    DateTime.parse(item2.vade_tarih));
                                                tutar2 = tryformat.format(
                                                    double.parse(item2.tutar));
                                              }

                                              return Container(
                                                decoration: BoxDecoration(
                                                  color: _surfaceColor,
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(color: _borderColor, width: 1),
                                                ),
                                                margin: EdgeInsets.only(bottom: 8),
                                                child: ListTile(
                                                  leading: Checkbox(
                                                    value: isCheckedList[index],
                                                    onChanged: (bool? value) {
                                                      setState(() {
                                                        isCheckedList[index] = value!;
                                                        if (value)
                                                          ++secilialacaktaksit;
                                                        else
                                                          --secilialacaktaksit;
                                                      });
                                                    },
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                  ),
                                                  title: Text(
                                                    kalem2,
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.w600,
                                                      color: _textColor,
                                                    ),
                                                  ),
                                                  subtitle: Text(
                                                    satan2,
                                                    style: TextStyle(color: _textLightColor),
                                                  ),
                                                  trailing: Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    crossAxisAlignment: CrossAxisAlignment.end,
                                                    children: [
                                                      Text(
                                                        '$tutar2 ₺',
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.bold,
                                                          color: _primaryColor,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                          SizedBox(height: 16),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SingleChildScrollView(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Column(
                                        children: [
                                          kalemleryukleniyor
                                              ? Padding(
                                            padding: const EdgeInsets.all(32.0),
                                            child: CircularProgressIndicator(color: _primaryColor),
                                          )
                                              : senetvadeleri.isEmpty
                                              ? Padding(
                                            padding: const EdgeInsets.all(32.0),
                                            child: Column(
                                              children: [
                                                Icon(Icons.description_rounded, size: 60, color: _textLightColor.withOpacity(0.3)),
                                                SizedBox(height: 16),
                                                Text(
                                                  'Senet bulunamadı',
                                                  style: TextStyle(color: _textLightColor),
                                                ),
                                              ],
                                            ),
                                          )
                                              : ListView.separated(
                                            shrinkWrap: true,
                                            physics: NeverScrollableScrollPhysics(),
                                            itemCount: senetvadeleri.length,
                                            separatorBuilder: (context, index) => Divider(color: _borderColor),
                                            itemBuilder: (context, index) {
                                              final item2 = senetvadeleri[index];
                                              String kalem2 = "";
                                              String satan2 = "";
                                              String tutar2 = "";

                                              if (item2 is SenetVade) {
                                                kalem2 = "${item2.id} nolu Senet vadesi";
                                                satan2 = DateFormat('dd.MM.yyyy').format(
                                                    DateTime.parse(item2.vade_tarih));
                                                tutar2 = tryformat.format(
                                                    double.parse(item2.tutar));
                                              }

                                              return Container(
                                                decoration: BoxDecoration(
                                                  color: _surfaceColor,
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(color: _borderColor, width: 1),
                                                ),
                                                margin: EdgeInsets.only(bottom: 8),
                                                child: ListTile(
                                                  leading: Checkbox(
                                                    value: isCheckedList2[index],
                                                    onChanged: (bool? value) {
                                                      setState(() {
                                                        isCheckedList2[index] = value!;
                                                        if (value)
                                                          ++secilialacaksenet;
                                                        else
                                                          --secilialacaksenet;
                                                      });
                                                    },
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                  ),
                                                  title: Text(
                                                    kalem2,
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.w600,
                                                      color: _textColor,
                                                    ),
                                                  ),
                                                  subtitle: Text(
                                                    satan2,
                                                    style: TextStyle(color: _textLightColor),
                                                  ),
                                                  trailing: Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    crossAxisAlignment: CrossAxisAlignment.end,
                                                    children: [
                                                      Text(
                                                        '$tutar2 ₺',
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.bold,
                                                          color: _primaryColor,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                          SizedBox(height: 16),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: _borderColor, width: 1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                if (secilialacaksenet + secilialacaktaksit != 0) {
                                  isCheckedList.asMap().forEach((girdi, element) {
                                    if (element) {
                                      adisyonkalemleri.add(taksitvadeleri[girdi]);
                                      taksitvadeleri.removeAt(girdi);
                                    }
                                  });
                                  isCheckedList2.asMap().forEach((girdi, element) {
                                    if (element) {
                                      adisyonkalemleri.add(senetvadeleri[girdi]);
                                      senetvadeleri.removeAt(girdi);
                                    }
                                  });
                                  tutar_hesapla(false);
                                  Navigator.of(context).pop();
                                  setState(() {
                                    isCheckedList = List.generate(taksitvadeleri.length, (index) => false);
                                    isCheckedList2 = List.generate(senetvadeleri.length, (index) => false);
                                    secilialacaksenet = 0;
                                    secilialacaktaksit = 0;
                                  });
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primaryColor,
                                foregroundColor: Colors.white,
                                minimumSize: Size(0, 52),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                              ),
                              child: Text(
                                'Seçilileri Tahsilata Aktar',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
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
      },
    );
  }
}
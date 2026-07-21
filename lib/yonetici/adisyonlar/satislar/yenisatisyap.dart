import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:randevu_sistem/Backend/yetki.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:randevu_sistem/Models/adisyonhizmetler.dart';
import 'package:randevu_sistem/Models/adisyonpaketler.dart';
import 'package:randevu_sistem/Models/adisyonurunler.dart';
import 'package:randevu_sistem/Models/adisyonlar.dart';
import 'package:randevu_sistem/Models/isletmehizmetleri.dart';
import 'package:randevu_sistem/Models/musteri_danisanlar.dart';
import 'package:randevu_sistem/Models/taksitlitahsilatlar.dart';
import 'package:randevu_sistem/yonetici/dashboard/urunsatisiduzenleme.dart';

import 'package:randevu_sistem/Backend/backend.dart';

import 'package:randevu_sistem/Frontend/lazyload.dart';
import 'package:randevu_sistem/theme/app_tokens.dart';
import 'package:randevu_sistem/Frontend/tlrakamacevir.dart';
import 'package:randevu_sistem/Models/adisyonkalemleri.dart';
import 'package:randevu_sistem/Models/odemeturu.dart';
import 'package:randevu_sistem/Models/paketler.dart';
import 'package:randevu_sistem/Models/personel.dart';
import 'package:randevu_sistem/Models/senetler.dart';
import 'package:randevu_sistem/Models/senetvadeleri.dart';
import 'package:randevu_sistem/Models/taksitvadeleri.dart';
import 'package:randevu_sistem/Models/urunler.dart';
import 'package:randevu_sistem/Models/user.dart';
import '../../dashboard/hizmetsatisi.dart';
import '../../dashboard/hizmetsatisiduzenleme.dart';
import 'coklu_hizmet_secim.dart';
import 'coklu_urun_secim.dart';
import 'coklu_paket_secim.dart';
import 'coklu_urun_secim.dart';
import 'coklu_paket_secim.dart';
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
  // Dolu geldiğinde düzenleme modu: mevcut adisyonun kalemleri yüklenir, yeni
  // eklenen/düzenlenen kalemler bu adisyona işlenir (satış takibinden 'Düzenle').
  final String mevcutAdisyonId;


  SatisEkrani({
    Key? key,
    required this.isletmebilgi,
    required this.musteridanisanid,
    required this.kullanicirolu,
    required this.kullanici, // Yeni parametre
    this.mevcutAdisyonId = '',

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

  // Cark indirim kuponu
  final TextEditingController _carkKuponKodCtrl = TextEditingController();
  Map<String, dynamic>? _carkKuponInfo;
  bool _carkKuponApplied = false;
  bool _carkKuponLoading = false;

  // Modern Renk Palette — tema'dan
  Color get _primaryColor => context.colors.primary;
  Color get _secondaryColor => context.colors.primaryContainer;
  Color get _accentColor => context.colors.primaryContainer;
  Color get _successColor => context.appTheme.successColor;
  Color get _warningColor => context.appTheme.warningColor;
  Color get _errorColor => context.colors.error;
  Color get _backgroundColor => context.appTheme.surfaceMuted;
  Color get _surfaceColor => Theme.of(context).cardColor;
  Color get _textColor => context.colors.onSurface;
  Color get _textLightColor => context.colors.onSurfaceVariant;
  Color get _borderColor => context.appTheme.borderSubtle;
  Color get _shadowColor => context.appTheme.shadowBase.withValues(alpha: 0.04);

  // Gradient Colors — tema heroGradient
  Gradient get _primaryGradient => context.appTheme.heroGradient;

  Gradient get _successGradient => LinearGradient(
    colors: [context.appTheme.successColor, context.appTheme.successColor.withValues(alpha: 0.7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  Gradient get _warningGradient => LinearGradient(
    colors: [context.appTheme.warningColor, context.appTheme.warningColor.withValues(alpha: 0.7)],
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
    if (!mounted) return;

    // Müşterinin bugün açılmış, HİÇ ödemesi yapılmamış (açık) adisyonu varsa
    // yeni kalemler o adisyona eklensin; yoksa boş bırak → ilk kalemde yeni adisyon açılır.
    // NOT: Satış takibiyle aynı KANITLI geniş aralıkla çekip "bugün + ödemesiz"
    // süzmeyi burada yapıyoruz (dar tarih aralığı / datetime saat riskini elemek için).
    final String acikAdisyonId = await _acikAdisyonBul(value.id.toString());
    if (!mounted) return;

    String indirimtext = "0";
    String aktifpasif = "";

    if (musterituru == "1") {
      aktifpasif = "Aktif";
      aktifPasifRenk = context.colors.primary;
      indirimtext = settings['aktif_musteri_indirim_yuzde']?.toString() ?? '0';
    } else if (musterituru == "2") {
      aktifPasifRenk = context.appTheme.successColor;
      aktifpasif = "Sadık";
      indirimtext = settings['sadik_musteri_indirim_yuzde']?.toString() ?? '0';
    } else {
      aktifPasifRenk = context.colors.onSurfaceVariant;
      aktifpasif = "Pasif";
    }

    setState(() {
      kalemleryukleniyor = true;

      // Sadece mevcut kalemleri temizle, alacakları getirme
      adisyonkalemleri.clear();

      // Bugün ödemesiz açık adisyon varsa ona ekle; yoksa yeni adisyon açılır
      yeniSatisAdisyonId = acikAdisyonId;

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
        if (widget.mevcutAdisyonId.isNotEmpty) {
          // Düzenleme modu: mevcut adisyonu ve kalemlerini yükle
          _duzenlemeModuYukle(musteridanisanliste);
        } else {
          loadbar(musteridanisanliste);
        }
      }

      isloading = false;
    });
  }

  // Satış takibinden 'Düzenle' ile açıldığında: müşteri bilgisini yükler ve
  // mevcut adisyonun hizmet/ürün/paket kalemlerini listeye getirir. Yeni
  // eklenen/düzenlenen kalemler yeniSatisAdisyonId üzerinden aynı adisyona işlenir.
  void _duzenlemeModuYukle(MusteriDanisan value) async {
    String musterituru = await musteriDanisanTuru(seciliisletme, value.id.toString());
    final settings = await fetchSalonSettings(seciliisletme);
    if (!mounted) return;

    String indirimtext = "0";
    String aktifpasif = "";
    if (musterituru == "1") {
      aktifpasif = "Aktif";
      aktifPasifRenk = context.colors.primary;
      indirimtext = settings['aktif_musteri_indirim_yuzde']?.toString() ?? '0';
    } else if (musterituru == "2") {
      aktifPasifRenk = context.appTheme.successColor;
      aktifpasif = "Sadık";
      indirimtext = settings['sadik_musteri_indirim_yuzde']?.toString() ?? '0';
    } else {
      aktifPasifRenk = context.colors.onSurfaceVariant;
      aktifpasif = "Pasif";
    }

    // Mevcut adisyonun kalemlerini getir (yalnızca hizmet/ürün/paket)
    final List<AdisyonKalemleri> yuklenen = [];
    try {
      final data = await senetvetaksitler(
          seciliisletme!, value.id.toString(), widget.mevcutAdisyonId);
      for (final j in (data["adisyon_hizmet"] as List? ?? [])) {
        yuklenen.add(AdisyonHizmet.fromJson(j));
      }
      for (final j in (data["adisyon_urun"] as List? ?? [])) {
        yuklenen.add(AdisyonUrun.fromJson(j));
      }
      for (final j in (data["adisyon_paket"] as List? ?? [])) {
        yuklenen.add(AdisyonPaket.fromJson(j));
      }
    } catch (e) {
      log('[duzenleme] kalem yükleme hatası: $e');
    }
    if (!mounted) return;

    setState(() {
      secilimusteridanisan = value;
      musteri_sabit_indirim.text = indirimtext;
      aktifsadikpasif.text = aktifpasif;
      musteridanisanadi.text = value.name ?? '';
      yeniSatisAdisyonId = widget.mevcutAdisyonId;
      adisyonkalemleri.clear();
      adisyonkalemleri.addAll(yuklenen);
      tutar_hesapla(false);
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

  /// Müşterinin BUGÜN açılmış, hiç ödemesi yapılmamış (açık) adisyonunu bulur.
  /// Bulursa id'sini döner; yoksa '' (→ ilk kalemde yeni adisyon açılır).
  /// Satış takibiyle aynı geniş aralıkla çekip "bugün + ödemesiz" süzülür
  /// (dar tarih aralığı / datetime saat riskini elemek için).
  Future<String> _acikAdisyonBul(String musteriId) async {
    if (musteriId.isEmpty) return '';
    try {
      final String bugunListe = DateFormat("yyyy-MM-dd").format(DateTime.now());
      final String bugunGosterim = DateFormat("dd.MM.yyyy").format(DateTime.now());
      final resp = await satislar(seciliisletme ?? "", "1", "1970-01-01", bugunListe,
          musteriId, "", "", false, "", 1);
      final List<dynamic> data = (resp['data'] as List?) ?? [];
      for (final j in data) {
        final Adisyon a = Adisyon.fromJson(j);
        final double odenen =
            double.tryParse(a.odenen_numeric.replaceAll(',', '.')) ?? 0;
        final double kalan =
            double.tryParse(a.kalan_tutar_numeric.replaceAll(',', '.')) ?? 0;
        // BIRLESTIRME KURALI (kati): yalnizca AYNI GUN acilmis ve HIC odeme
        // alinmamis adisyon. Kismi odeme de kapsam disi. Kapanmis adisyona
        // kalem yazmak muhasebeyi bozdugu icin uc ayri guvence birlikte aranir:
        //  1) odenen_numeric <= 0  → kalem bazli hic tahsilat yok
        //  2) son_tahsilat_tarihi bos → adisyon bazli hic tahsilat kaydi yok
        //     (kalemlere baglanmamis tahsilati da yakalar; odenen 0 gorunse bile eler)
        //  3) kalan_tutar_numeric > 0 → hala odenecek bakiye var
        //     (indirim/hediye ile sifirlanip fiilen kapanmis adisyonu eler)
        final bool hicOdemeYok =
            odenen <= 0 && a.son_tahsilat_tarihi.trim().isEmpty && kalan > 0;
        if (hicOdemeYok && a.acilis_tarihi == bugunGosterim) {
          log('[acik-adisyon] musteri=$musteriId secilen=${a.id} (odenen=$odenen kalan=$kalan)');
          return a.id;
        }
      }
      log('[acik-adisyon] musteri=$musteriId donen=${data.length} secilen=YOK');
    } catch (e) {
      log('[acik-adisyon] hata: $e');
    }
    return '';
  }

  /// Kalem eklemeden HEMEN ÖNCE açık adisyonu tazeler. Müşteri seçildikten sonra
  /// (ayni ya da baska hesaptan) acilmis odemesiz adisyon varsa kalemler ona gider.
  Future<void> _acikAdisyonTazele() async {
    if (yeniSatisAdisyonId.isNotEmpty) return; // zaten bir adisyona bagliyiz
    final id = await _acikAdisyonBul(secilimusteridanisan?.id.toString() ?? '');
    if (id.isNotEmpty && mounted) {
      setState(() => yeniSatisAdisyonId = id);
    }
  }

  void hizmetsatisi(AdisyonHizmet? mevcutadisyonhizmet) async {
    if (secilimusteridanisan == null) {
      _showUyariDialog('Devam etmek için önce müşteri seçiniz veya ekleyiniz.');
      return;
    }

    // Yeni ekleme: kuaför-dostu çoklu hizmet seçim ekranı (birden fazla hizmet)
    if (mevcutadisyonhizmet == null) {
      await _acikAdisyonTazele(); // ayni gun odemesiz adisyon varsa ona ekle
      if (!mounted) return;
      final List<AdisyonHizmet>? eklenenler = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CokluHizmetSecim(
            musteriid: secilimusteridanisan?.id ?? "",
            isletmebilgi: widget.isletmebilgi,
            kullanicirolu: widget.kullanicirolu,
            mevcutadisyonId: yeniSatisAdisyonId,
          ),
        ),
      );
      if (eklenenler != null && eklenenler.isNotEmpty) {
        setState(() {
          adisyonkalemleri.addAll(eklenenler);
          yeniSatisAdisyonId = eklenenler.last.adisyon_id;
          tutar_hesapla(false);
        });
      }
      return;
    }

    // Düzenleme: tek hizmet düzenleme ekranı (mevcut akış)
    final AdisyonHizmet? result = await Navigator.push(
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

    // Yeni ekleme: çoklu ürün seçim ekranı (birden fazla ürün)
    if (mevcutadisyonurun == null) {
      await _acikAdisyonTazele(); // ayni gun odemesiz adisyon varsa ona ekle
      if (!mounted) return;
      final List<AdisyonUrun>? eklenenler = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CokluUrunSecim(
            musteriid: secilimusteridanisan?.id ?? "",
            isletmebilgi: widget.isletmebilgi,
            kullanicirolu: widget.kullanicirolu,
            mevcutadisyonId: yeniSatisAdisyonId,
          ),
        ),
      );
      if (eklenenler != null && eklenenler.isNotEmpty) {
        setState(() {
          adisyonkalemleri.addAll(eklenenler);
          yeniSatisAdisyonId = eklenenler.last.adisyon_id;
          tutar_hesapla(false);
        });
      }
      return;
    }

    // Düzenleme: tek ürün düzenleme ekranı (mevcut akış)
    final AdisyonUrun? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UrunSatisiDuzenleme(
          musteriid: secilimusteridanisan?.id ?? "",
          mevcuturun: mevcutadisyonurun,
          senetlisatis: false,
          isletmebilgi: widget.isletmebilgi,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        adisyonkalemleri.removeWhere((element) => element is AdisyonUrun ? element.id == mevcutadisyonurun.id : false);
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

    // Yeni ekleme: çoklu paket seçim ekranı (birden fazla paket)
    if (mevcutadisyonpaket == null) {
      await _acikAdisyonTazele(); // ayni gun odemesiz adisyon varsa ona ekle
      if (!mounted) return;
      final List<AdisyonPaket>? eklenenler = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CokluPaketSecim(
            musteriid: secilimusteridanisan?.id ?? "",
            isletmebilgi: widget.isletmebilgi,
            kullanicirolu: widget.kullanicirolu,
            mevcutadisyonId: yeniSatisAdisyonId,
          ),
        ),
      );
      if (eklenenler != null && eklenenler.isNotEmpty) {
        setState(() {
          adisyonkalemleri.addAll(eklenenler);
          yeniSatisAdisyonId = eklenenler.last.adisyon_id;
          tutar_hesapla(false);
        });
      }
      return;
    }

    // Düzenleme: tek paket düzenleme ekranı (mevcut akış)
    final AdisyonPaket? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaketSatisiDuzenleme(
          musteriid: secilimusteridanisan?.id ?? "",
          mevcutpaket: mevcutadisyonpaket,
          senetlisatis: false,
          isletmebilgi: widget.isletmebilgi,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        adisyonkalemleri.removeWhere((element) => element is AdisyonPaket ? element.id == mevcutadisyonpaket.id : false);
        adisyonkalemleri.add(result);
        yeniSatisAdisyonId = result.adisyon_id;
        tutar_hesapla(false);
      });
    }
  }

  // ────────── Cark indirim kuponu ──────────
  double _matchingTutarForKuponTip(String tip) {
    double t = 0;
    for (final el in adisyonkalemleri) {
      if (el is AdisyonHizmet && tip == 'hizmet_indirimi') {
        t += double.tryParse(el.fiyat.replaceAll(',', '.')) ?? 0;
      } else if (el is AdisyonUrun && tip == 'urun_indirimi') {
        t += double.tryParse(el.fiyat.replaceAll(',', '.')) ?? 0;
      } else if (el is AdisyonPaket && tip == 'paket_indirimi') {
        t += double.tryParse(el.fiyat.replaceAll(',', '.')) ?? 0;
      }
    }
    return t;
  }

  String _kuponTipAdi(String tip) {
    switch (tip) {
      case 'hizmet_indirimi': return 'Hizmet';
      case 'urun_indirimi':   return 'Ürün';
      case 'paket_indirimi':  return 'Paket';
      default: return 'İndirim';
    }
  }

  Future<void> _applyCarkKupon() async {
    final kod = _carkKuponKodCtrl.text.trim().toUpperCase();
    if (kod.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kupon kodu giriniz'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    if (secilimusteridanisan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Önce müşteri seçiniz'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    setState(() => _carkKuponLoading = true);
    try {
      final res = await carkAdminKuponDogrula(seciliisletme, kod);
      if (res == null || res['basarili'] != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: _errorColor,
            behavior: SnackBarBehavior.floating,
            content: Text((res?['mesaj'] ?? 'Kupon doğrulanamadı').toString(),
                style: const TextStyle(color: Colors.white)),
          ),
        );
        return;
      }
      final odul = Map<String, dynamic>.from(res['odul'] as Map);
      final tip = (odul['tip'] ?? '').toString();
      final durum = (odul['durum'] ?? '').toString();
      if (durum == 'kullanildi') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: _errorColor,
            behavior: SnackBarBehavior.floating,
            content: const Text('Bu kupon daha önce kullanılmış',
                style: TextStyle(color: Colors.white)),
          ),
        );
        return;
      }
      if (durum == 'sure_doldu') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: _errorColor,
            behavior: SnackBarBehavior.floating,
            content: const Text('Bu kuponun süresi dolmuş',
                style: TextStyle(color: Colors.white)),
          ),
        );
        return;
      }
      if (tip != 'hizmet_indirimi' && tip != 'urun_indirimi' && tip != 'paket_indirimi') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bu kupon indirim kuponu değil'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      final matchTutar = _matchingTutarForKuponTip(tip);
      if (matchTutar <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: _errorColor,
            behavior: SnackBarBehavior.floating,
            content: Text('Sepette ${_kuponTipAdi(tip).toLowerCase()} bulunmadığı için kupon uygulanamadı',
                style: const TextStyle(color: Colors.white)),
          ),
        );
        return;
      }
      final deger = (odul['deger'] as num?)?.toDouble() ?? 0;
      final indirimTutar = matchTutar * (deger / 100.0);
      final mevcut = tlyirakamacevir(harici_indirim.text);
      final yeni = mevcut + indirimTutar;
      final odulId = (odul['id'] as num?)?.toInt() ?? 0;
      if (odulId > 0) {
        await carkAdminKuponKullan(seciliisletme, odulId, aksiyon: 'kullan');
      }
      setState(() {
        harici_indirim.text = tryformat.format(yeni).toString();
        _carkKuponInfo = odul;
        _carkKuponApplied = true;
      });
      tutar_hesapla(false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _successColor,
          behavior: SnackBarBehavior.floating,
          content: Text(
            '🎁 Kupon uygulandı: %${deger.toInt()} ${_kuponTipAdi(tip)} indirimi (${tryformat.format(indirimTutar)} ₺)',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _carkKuponLoading = false);
    }
  }

  Widget _buildCarkKuponBanner() {
    if (_carkKuponApplied && _carkKuponInfo != null) {
      final tip = (_carkKuponInfo!['tip'] ?? '').toString();
      final deger = (_carkKuponInfo!['deger'] as num?)?.toInt() ?? 0;
      final kod = (_carkKuponInfo!['kod'] ?? '').toString();
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFCD34D), width: 1),
        ),
        child: Row(
          children: [
            const Icon(Icons.card_giftcard_rounded, size: 20, color: Color(0xFF92400E)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Çark kuponu uygulandı: $kod — %$deger ${_kuponTipAdi(tip)} İndirimi',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF78350F),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.card_giftcard_rounded, size: 18, color: Color(0xFF92400E)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _carkKuponKodCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Çark kupon kodu',
                hintStyle: TextStyle(
                    fontSize: 12.5, color: _textColor.withValues(alpha: 0.45)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFFDE68A)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFFDE68A)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: Color(0xFFF59E0B), width: 1.5),
                ),
              ),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _carkKuponLoading ? null : _applyCarkKupon,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: _carkKuponLoading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Uygula',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
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
                  kalem = item.hizmet?["hizmet_adi"] ?? "";
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
                  tutar = tryformat.format(double.parse(item.fiyat.replaceAll(",", ".")));
                  icon = Icons.spa_rounded;
                  iconColor = _primaryColor;
                  backgroundColor = _primaryColor.withValues(alpha: 0.1);
                }

                if (item is AdisyonUrun) {
                  key = item.urun_id.toString();
                  kalem = item.urun?["urun_adi"] ?? "";
                  adet = item.adet;
                  satan = item.personel?["personel_adi"] ?? "Personel Yok";
                  tutar = tryformat.format(double.parse(item.fiyat.replaceAll(",", ".")));
                  icon = Icons.shopping_bag_rounded;
                  iconColor = context.appTheme.infoColor;
                  backgroundColor = context.appTheme.infoColor.withValues(alpha: 0.1);
                }

                if (item is AdisyonPaket) {
                  key = item.paket_id.toString();
                  kalem = item.paket?["paket_adi"] ?? "";
                  adet = "1";
                  satan = item.personel?["personel_adi"] ?? "Personel Yok";
                  tutar = tryformat.format(double.parse(item.fiyat.replaceAll(",", ".")));
                  icon = Icons.card_membership_rounded;
                  iconColor = _successColor;
                  backgroundColor = _successColor.withValues(alpha: 0.1);
                }

                if (item is SenetVade) {
                  key = item.id.toString();
                  kalem = "${item.id} nolu Senet vadesi";
                  adet = "1";
                  satan = DateFormat('dd.MM.yyyy').format(DateTime.parse(item.vade_tarih));
                  tutar = tryformat.format(double.parse(item.tutar.replaceAll(",", ".")));
                  icon = Icons.description_rounded;
                  iconColor = _warningColor;
                  backgroundColor = _warningColor.withValues(alpha: 0.1);
                }

                if (item is TaksitVade) {
                  key = item.id.toString();
                  kalem = "${item.id} nolu Taksit vadesi";
                  adet = "1";
                  satan = DateFormat('dd.MM.yyyy').format(DateTime.parse(item.vade_tarih));
                  tutar = tryformat.format(double.parse(item.tutar.replaceAll(",", ".")));
                  icon = Icons.payment_rounded;
                  iconColor = _successColor;
                  backgroundColor = _successColor.withValues(alpha: 0.1);
                }

                return Dismissible(
                  key: Key(key),
                  direction: DismissDirection.horizontal,
                  background: Container(
                    decoration: BoxDecoration(
                      color: _successColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        SizedBox(width: 20),
                        Icon(Icons.edit_rounded, color: _successColor),
                        SizedBox(width: 10),
                        Text('Düzenle', style: TextStyle(color: _successColor)),
                      ],
                    ),
                  ),
                  secondaryBackground: Container(
                    decoration: BoxDecoration(
                      color: _errorColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('Sil', style: TextStyle(color: _errorColor)),
                        SizedBox(width: 10),
                        Icon(Icons.delete_rounded, color: _errorColor),
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
                                  colors: [_errorColor, _errorColor.withValues(alpha: 0.7)],
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
                                  Icon(Icons.delete_forever_rounded, color: context.colors.onError, size: 24),
                                  SizedBox(width: 12),
                                  Text(
                                    "Satış Kalemini Sil",
                                    style: TextStyle(
                                      color: context.colors.onError,
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
                                        backgroundColor: _errorColor,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _errorColor,
                                  foregroundColor: context.colors.onError,
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
      child: Builder(
        builder: (_) {
          final hizmetYet = Yetki.varMi('satis.adisyon_olustur');
          final urunYet = Yetki.varMi('urun.sat');
          final paketYet = Yetki.varMi('paket.sat');
          final btns = <Widget>[];
          if (hizmetYet) {
            btns.add(Expanded(
              child: _buildActionButton(
                text: 'Hizmet Ekle',
                color: _primaryColor,
                onPressed: () => hizmetsatisi(null),
                icon: Icons.spa_outlined,
                isSmall: true,
              ),
            ));
          }
          if (urunYet) {
            if (btns.isNotEmpty) btns.add(SizedBox(width: 8));
            btns.add(Expanded(
              child: _buildActionButton(
                text: 'Ürün Ekle',
                color: context.appTheme.infoColor,
                onPressed: () => urunsatisi(null),
                icon: Icons.shopping_bag_rounded,
                isSmall: true,
              ),
            ));
          }
          if (paketYet) {
            if (btns.isNotEmpty) btns.add(SizedBox(width: 8));
            btns.add(Expanded(
              child: _buildActionButton(
                text: 'Paket Ekle',
                color: _successColor,
                onPressed: () => paketsatisi(null),
                icon: Icons.card_membership_rounded,
                isSmall: true,
              ),
            ));
          }
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: btns,
          );
        },
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
                                satisTarihi: tahsilat_tarihi.text,
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
                                    backgroundColor: _errorColor,
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

  // Hızlı Tahsilat Bottom Sheet — yeni satıştan direkt tahsilat
  Future<void> _acHizliTahsilatBottomSheet() async {
    if (secilimusteridanisan == null) {
      _showUyariDialog('Devam etmek için önce müşteri seçiniz.');
      return;
    }
    if (adisyonkalemleri.isEmpty) {
      _showUyariDialog('Tahsilat için önce hizmet, ürün veya paket ekleyiniz.');
      return;
    }

    final double toplamTahsilat = tlyirakamacevir(tahsilat_tutari.text);
    final TextEditingController tutarCtrl = TextEditingController(text: tryformat.format(toplamTahsilat));
    OdemeTuru secilenYontem = odemeyontem.first; // Default Nakit
    bool taksitMode = false;
    final TextEditingController taksitSayisiCtrl = TextEditingController(text: '2');
    final TextEditingController taksitTarihCtrl = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
    final TextEditingController tahsilatTarihCtrl = TextEditingController(
        text: tahsilat_tarihi.text.isNotEmpty ? tahsilat_tarihi.text : DateFormat('yyyy-MM-dd').format(DateTime.now()));

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetCtx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
          child: StatefulBuilder(
            builder: (BuildContext sbCtx, StateSetter setSheet) {
              final double tahsilEdilen = tlyirakamacevir(tutarCtrl.text);
              final double kalan = (toplamTahsilat - tahsilEdilen).clamp(0, double.infinity);
              final bool tamTahsilat = kalan <= 0.005;

              Widget yontemChip(OdemeTuru y, IconData ico) {
                final bool sel = secilenYontem.id == y.id;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setSheet(() => secilenYontem = y),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: sel ? _primaryColor : _surfaceColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: sel ? _primaryColor : _borderColor, width: 1.4),
                        boxShadow: sel ? [
                          BoxShadow(color: _primaryColor.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3)),
                        ] : null,
                      ),
                      child: Column(
                        children: [
                          Icon(ico, color: sel ? Colors.white : _textLightColor, size: 22),
                          const SizedBox(height: 6),
                          Text(y.odeme_turu, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: sel ? Colors.white : _textColor)),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return Container(
                decoration: BoxDecoration(
                  color: _backgroundColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Drag handle
                        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: _borderColor, borderRadius: BorderRadius.circular(2)))),
                        const SizedBox(height: 14),
                        // Header
                        Row(
                          children: [
                            Container(
                              width: 42, height: 42,
                              decoration: BoxDecoration(gradient: _primaryGradient, borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Icons.payments_rounded, color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Hızlı Tahsilat', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _textColor)),
                                Text(musteridanisanadi.text, style: TextStyle(fontSize: 12, color: _textLightColor)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Toplam tutar kartı
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: _primaryGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: _primaryColor.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Toplam Tutar', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text('${tryformat.format(toplamTahsilat)} ₺', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 4),
                              Text('${adisyonkalemleri.length} kalem', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        // Ödeme yöntemi
                        Text('Ödeme Yöntemi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _textLightColor, letterSpacing: 0.3)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            yontemChip(odemeyontem[0], Icons.payments_outlined),
                            yontemChip(odemeyontem[1], Icons.credit_card_rounded),
                            yontemChip(odemeyontem[2], Icons.account_balance_rounded),
                          ],
                        ),
                        const SizedBox(height: 18),
                        // Tahsil edilen tutar
                        Text('Tahsil Edilen Tutar (₺)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _textLightColor, letterSpacing: 0.3)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: tutarCtrl,
                          keyboardType: TextInputType.phone,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _textColor),
                          onChanged: (_) => setSheet(() {}),
                          decoration: InputDecoration(
                            isDense: true,
                            filled: true,
                            fillColor: _surfaceColor,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: _borderColor, width: 1.2), borderRadius: BorderRadius.circular(14)),
                            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: _primaryColor, width: 1.6), borderRadius: BorderRadius.circular(14)),
                            suffixIcon: TextButton(
                              onPressed: () => setSheet(() => tutarCtrl.text = tryformat.format(toplamTahsilat)),
                              child: Text('TAMAMI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _primaryColor)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        // Tahsilat tarihi
                        Text('Tahsilat Tarihi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _textLightColor, letterSpacing: 0.3)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: tahsilatTarihCtrl,
                          readOnly: true,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _textColor),
                          onTap: () async {
                            DateTime? p = await showDatePicker(
                              context: sbCtx,
                              initialDate: DateTime.tryParse(tahsilatTarihCtrl.text) ?? DateTime.now(),
                              firstDate: DateTime(1950),
                              lastDate: DateTime(2100),
                              locale: const Locale('tr', 'TR'),
                            );
                            if (p != null) {
                              setSheet(() => tahsilatTarihCtrl.text = DateFormat('yyyy-MM-dd').format(p));
                            }
                          },
                          decoration: InputDecoration(
                            isDense: true,
                            filled: true,
                            fillColor: _surfaceColor,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            suffixIcon: Icon(Icons.calendar_today_rounded, size: 18, color: _primaryColor),
                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: _borderColor, width: 1.2), borderRadius: BorderRadius.circular(14)),
                            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: _primaryColor, width: 1.6), borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                        // Kalan + Taksit toggle (sadece kısmi ödeme varsa görünür)
                        if (!tamTahsilat) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _warningColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _warningColor.withValues(alpha: 0.3), width: 1),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline_rounded, color: _warningColor, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Kalan: ${tryformat.format(kalan)} ₺', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _textColor)),
                                      Text('Kalan tutar için taksit oluşturulması gerekiyor', style: TextStyle(fontSize: 11, color: _textLightColor)),
                                    ],
                                  ),
                                ),
                                Switch.adaptive(
                                  value: taksitMode,
                                  activeColor: _primaryColor,
                                  onChanged: (v) => setSheet(() => taksitMode = v),
                                ),
                              ],
                            ),
                          ),
                          if (taksitMode) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Taksit Sayısı', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _textLightColor)),
                                      const SizedBox(height: 6),
                                      TextFormField(
                                        controller: taksitSayisiCtrl,
                                        keyboardType: TextInputType.number,
                                        style: TextStyle(fontSize: 14, color: _textColor),
                                        decoration: InputDecoration(
                                          isDense: true,
                                          filled: true,
                                          fillColor: _surfaceColor,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: _borderColor, width: 1.2), borderRadius: BorderRadius.circular(12)),
                                          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: _primaryColor, width: 1.6), borderRadius: BorderRadius.circular(12)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('İlk Vade Tarihi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _textLightColor)),
                                      const SizedBox(height: 6),
                                      TextFormField(
                                        controller: taksitTarihCtrl,
                                        readOnly: true,
                                        style: TextStyle(fontSize: 13, color: _textColor),
                                        onTap: () async {
                                          DateTime? p = await showDatePicker(
                                            context: sbCtx,
                                            initialDate: DateTime.now().add(const Duration(days: 30)),
                                            firstDate: DateTime.now(),
                                            lastDate: DateTime(2100),
                                          );
                                          if (p != null) {
                                            setSheet(() => taksitTarihCtrl.text = DateFormat('yyyy-MM-dd').format(p));
                                          }
                                        },
                                        decoration: InputDecoration(
                                          isDense: true,
                                          filled: true,
                                          fillColor: _surfaceColor,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                          suffixIcon: Icon(Icons.calendar_today_rounded, size: 16, color: _primaryColor),
                                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: _borderColor, width: 1.2), borderRadius: BorderRadius.circular(12)),
                                          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: _primaryColor, width: 1.6), borderRadius: BorderRadius.circular(12)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                        const SizedBox(height: 22),
                        // Submit button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              if (tahsilEdilen <= 0 && !taksitMode) {
                                ScaffoldMessenger.of(sheetCtx).showSnackBar(
                                  SnackBar(content: const Text('Tahsil edilen tutar 0\'dan büyük olmalıdır.'), backgroundColor: _errorColor),
                                );
                                return;
                              }
                              if (!tamTahsilat && !taksitMode) {
                                ScaffoldMessenger.of(sheetCtx).showSnackBar(
                                  SnackBar(content: const Text('Kalan tutar için taksit oluşturmanız veya tamamını tahsil etmeniz gerekir.'), backgroundColor: _errorColor),
                                );
                                return;
                              }

                              // Update main screen controllers to match what we're sending
                              selectedodemeyontemi = secilenYontem;
                              odenecek_tutar.text = tutarCtrl.text;

                              if (tamTahsilat) {
                                // Full payment → tahsilet (kapalı satış)
                                try {
                                  await tahsilet(
                                    context,
                                    seciliisletme,
                                    adisyonkalemleri,
                                    "1",
                                    taksitTarihCtrl.text,
                                    "0,00",
                                    secilimusteridanisan?.id ?? "",
                                    toplamindirimtutari.text,
                                    secilenYontem.id,
                                    tutarCtrl.text,
                                    tahsilatTarihCtrl.text,
                                    "",
                                    harici_indirim.text,
                                    satisTarihi: tahsilat_tarihi.text,
                                  );
                                  if (!mounted) return;
                                  Navigator.of(sheetCtx).pop();
                                  Navigator.of(context).pop({'refresh': true});
                                } catch (e) {
                                  // tahsilet already shows snackbar on error
                                }
                              } else {
                                // Partial + taksit → taksitekleguncelle (açık satış)
                                final int? tn = int.tryParse(taksitSayisiCtrl.text.trim());
                                if (tn == null || tn < 1) {
                                  ScaffoldMessenger.of(sheetCtx).showSnackBar(
                                    SnackBar(content: const Text('Taksit sayısı en az 1 olmalıdır.'), backgroundColor: _errorColor),
                                  );
                                  return;
                                }
                                final int result = await taksitekleguncelle(
                                  context,
                                  seciliisletme,
                                  adisyonkalemleri,
                                  taksitSayisiCtrl.text,
                                  taksitTarihCtrl.text,
                                  tryformat.format(kalan),
                                  secilimusteridanisan?.id ?? "",
                                  toplamindirimtutari.text,
                                  secilenYontem.id,
                                  tutarCtrl.text,
                                  tahsilatTarihCtrl.text,
                                  "",
                                  harici_indirim.text,
                                  satisTarihi: tahsilat_tarihi.text,
                                );
                                if (!mounted) return;
                                if (result == 200) {
                                  Navigator.of(sheetCtx).pop();
                                  Navigator.of(context).pop({'refresh': true});
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: const Text('Satış kaydedildi ve taksitlendirildi.'), backgroundColor: _successColor),
                                  );
                                } else {
                                  ScaffoldMessenger.of(sheetCtx).showSnackBar(
                                    SnackBar(content: Text('Hata: $result'), backgroundColor: _errorColor),
                                  );
                                }
                              }
                            },
                            icon: Icon(tamTahsilat ? Icons.check_circle_rounded : Icons.timeline_rounded, size: 22),
                            label: Text(
                              tamTahsilat ? 'TAM TAHSİL ET' : (taksitMode ? 'TAKSİTLİ TAHSİL ET' : 'TAHSİL ET'),
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: tamTahsilat ? const Color(0xFF2E7D32) : _primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // Alt bar: "Satış Takibi" butonu ekranı kapatıp satış takibi sekmesini açar
  // (kalemler eklenince zaten adisyona yazıldığı için ekstra kayıt yapmaz).
  // "TAHSİL ET" yalnızca tahsilat yetkisi (satis.tahsilat_al) olanlara gösterilir.
  Widget _buildAltButonlar() {
    final bool tahsilatYetkisi = Yetki.varMi('satis.tahsilat_al');
    final bool aktif = adisyonkalemleri.isNotEmpty;

    final Widget satisTakibiBtn = tahsilatYetkisi
        ? OutlinedButton(
            onPressed: aktif ? () => Navigator.of(context).pop({'refresh': true}) : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2E7D32),
              side: BorderSide(
                  color: aktif ? const Color(0xFF2E7D32) : _borderColor, width: 1.4),
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_rounded, size: 20),
                SizedBox(width: 8),
                Flexible(
                  child: Text('Kaydet',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          )
        : ElevatedButton(
            onPressed: aktif ? () => Navigator.of(context).pop({'refresh': true}) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  aktif ? const Color(0xFF2E7D32) : _textLightColor.withValues(alpha: 0.3),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_rounded, size: 22),
                SizedBox(width: 10),
                Text('Kaydet',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
              ],
            ),
          );

    final Widget tahsilEtBtn = ElevatedButton(
      onPressed: aktif ? () => _acHizliTahsilatBottomSheet() : null,
      style: ElevatedButton.styleFrom(
        backgroundColor:
            aktif ? const Color(0xFF2E7D32) : _textLightColor.withValues(alpha: 0.3),
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        shadowColor: const Color(0xFF2E7D32).withValues(alpha: 0.3),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.payments_rounded, size: 22),
          SizedBox(width: 10),
          Flexible(
            child: Text('TAHSİL ET',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          ),
        ],
      ),
    );

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceColor,
        border: Border(top: BorderSide(color: _borderColor, width: 1)),
        boxShadow: [
          BoxShadow(color: _shadowColor, blurRadius: 20, offset: Offset(0, -5)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(child: satisTakibiBtn),
            if (tahsilatYetkisi) ...[
              const SizedBox(width: 12),
              Expanded(child: tahsilEtBtn),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    bool isTablet = width > 600;

    return Scaffold(
      backgroundColor: _backgroundColor,
      // Alt butonlar: "Kaydet ve Çık" her zaman; "TAHSİL ET" sadece tahsilat yetkisi varsa
      bottomNavigationBar: _buildAltButonlar(),
      appBar: AppBar(
        title: Text(
          widget.mevcutAdisyonId.isNotEmpty ? 'Adisyon Düzenle' : 'Yeni Satış',
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
          // Yeni müşteri ekleme: düzenleme modunda gizli (müşteri sabit)
          if (widget.mevcutAdisyonId.isEmpty)
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
                  // Tarih ve Müşteri Seçimi — yan yana iki kolon
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sol kolon: Satış Tarihi (sadece tarih seçimi)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Satış Tarihi',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _textColor,
                                letterSpacing: -0.3,
                              ),
                            ),
                            SizedBox(height: 12),
                            GestureDetector(
                              onTap: () async {
                                DateTime initial =
                                    DateTime.tryParse(tahsilat_tarihi.text) ?? DateTime.now();
                                DateTime? pickedDate = await showDatePicker(
                                  context: context,
                                  initialDate: initial,
                                  firstDate: DateTime(1950),
                                  lastDate: DateTime(2100),
                                  locale: const Locale('tr', 'TR'),
                                  builder: (context, child) {
                                    return Theme(
                                      data: ThemeData.light().copyWith(
                                        primaryColor: _primaryColor,
                                        colorScheme: ColorScheme.light(primary: _primaryColor),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (pickedDate != null) {
                                  setState(() {
                                    tahsilat_tarihi.text =
                                        DateFormat('yyyy-MM-dd').format(pickedDate);
                                    ilk_taksit_vade_tarihi.text =
                                        DateFormat('yyyy-MM-dd').format(pickedDate);
                                  });
                                }
                              },
                              child: Container(
                                height: 52,
                                padding: EdgeInsets.symmetric(horizontal: 12),
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
                                child: Row(
                                  children: [
                                    Icon(Icons.calendar_today_rounded,
                                        color: _primaryColor, size: 18),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        DateFormat('dd MMM yyyy', 'tr_TR').format(
                                            DateTime.tryParse(tahsilat_tarihi.text) ??
                                                DateTime.now()),
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: _textColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 12),
                      // Sağ kolon: Müşteri Seçimi
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                            Container(
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
                              // Düzenleme modunda müşteri değiştirilemez (adisyon o müşteriye ait)
                              child: AbsorbPointer(
                                absorbing: widget.mevcutAdisyonId.isNotEmpty,
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

            if (secilimusteridanisan != null &&
                adisyonkalemleri.any((e) => e is AdisyonHizmet || e is AdisyonUrun || e is AdisyonPaket))
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _buildCarkKuponBanner(),
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
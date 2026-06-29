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

import 'package:randevu_sistem/Backend/backend.dart';

import 'package:randevu_sistem/Frontend/lazyload.dart';
import 'package:randevu_sistem/theme/app_tokens.dart';
import 'package:randevu_sistem/Frontend/tlrakamacevir.dart';
import 'package:randevu_sistem/Models/adisyonkalemleri.dart';
import 'package:randevu_sistem/Models/odemeturu.dart';
import 'package:randevu_sistem/Models/paketler.dart';
import 'package:randevu_sistem/Models/personel.dart';
import 'package:randevu_sistem/Models/senetler.dart';
import 'package:randevu_sistem/Models/taksitvadeleri.dart';
import 'package:randevu_sistem/Models/urunler.dart';
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

  // Gap kampanyasi (Sabah/Ogleden sonra/Aksam indirim) — su an aktif mi?
  Map<String, dynamic>? _gapKampanya;
  bool _gapBannerVisible = true;
  bool _gapApplied = false;

  // Cark indirim kuponu
  final TextEditingController _carkKuponKodCtrl = TextEditingController();
  Map<String, dynamic>? _carkKuponInfo;
  bool _carkKuponApplied = false;
  bool _carkKuponLoading = false;

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
    final cs = context.colors;
    final ext = context.appTheme;
    String musterituru = await musteriDanisanTuru(seciliisletme,value?.id.toString() ?? "");
    log('müşteri türü '+musterituru.toString());
    final settings = await fetchSalonSettings(seciliisletme);
    String indirimtext = "0";
    String aktifpasif = "";

    if(musterituru == "1"){

      aktifpasif= "Aktif";
      aktifPasifRenk = cs.primary;
      indirimtext = settings['aktif_musteri_indirim_yuzde']?.toString() ?? '0';
      print("Aktif Müşteri İndirim Yüzdesi: ${widget.isletmebilgi["aktif_musteri_indirim_yuzde"]}");

    }
    else if(musterituru == "2")
    {
      aktifPasifRenk = ext.successColor;
      aktifpasif="Sadık";
      indirimtext =settings['sadik_musteri_indirim_yuzde']?.toString() ?? '0';
      print("Sadik Müşteri İndirim Yüzdesi: ${widget.isletmebilgi["sadik_musteri_indirim_yuzde"]}");

    }
    else{
      aktifPasifRenk = cs.onSurface;
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

    // Aktif gap kampanyasi var mi? — su anki saat ile kontrol et
    _loadGapKampanya();
  }

  Future<void> _loadGapKampanya() async {
    final res = await randevuKampanyaKontrol(salonId: seciliisletme);
    if (!mounted) return;
    if (res != null && res['hasCampaign'] == true) {
      setState(() {
        _gapKampanya = res;
        _gapBannerVisible = true;
        _gapApplied = false;
      });
    }
  }

  Widget _buildGapKampanyaBanner() {
    final cs = context.colors;
    final ext = context.appTheme;
    final k = _gapKampanya!;
    final gapLabel = k['gapLabel'] as String? ?? 'Saatler';
    final disc = (k['discount'] as num?)?.toInt() ?? 0;
    final hour = (k['hour'] as num?)?.toInt() ?? 0;

    // Renk paleti — gap'e göre
    final gapKey = k['gapKey'] as String? ?? 'morning';
    final List<Color> grad;
    final IconData icon;
    switch (gapKey) {
      case 'morning':
        grad = const [Color(0xFFFDE68A), Color(0xFFFCD34D)];
        icon = Icons.wb_twilight_rounded;
        break;
      case 'afternoon':
        grad = const [Color(0xFFFED7AA), Color(0xFFFB923C)];
        icon = Icons.wb_sunny_rounded;
        break;
      case 'evening':
      default:
        grad = const [Color(0xFFDDD6FE), Color(0xFF8B5CF6)];
        icon = Icons.nightlight_round;
        break;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: _gapApplied
            ? ext.successColor.withValues(alpha: 0.10)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _gapApplied
              ? ext.successColor
              : ext.warningColor,
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: (_gapApplied
                    ? ext.successColor
                    : ext.warningColor)
                .withValues(alpha: 0.10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: grad),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '$gapLabel Kampanyası',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                ext.successColor,
                                ext.successColor,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '%$disc',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _gapApplied
                          ? '✓ İndirim müşteri indirim yüzdesi olarak uygulandı'
                          : 'Şu an (${hour.toString().padLeft(2, '0')}:00) indirim aralığında. Müşteri indirimini %$disc olarak uygula?',
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.4,
                        color: cs.onSurface.withValues(alpha: 0.65),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: cs.onSurface.withValues(alpha: 0.45),
                ),
                onPressed: () =>
                    setState(() => _gapBannerVisible = false),
              ),
            ],
          ),
          if (!_gapApplied) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _applyGapDiscount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11)),
                ),
                icon: const Icon(Icons.local_offer_rounded, size: 16),
                label: Text(
                  '%$disc İndirimi Uygula',
                  style: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _applyGapDiscount() {
    final ext = context.appTheme;
    final disc = (_gapKampanya?['discount'] as num?)?.toInt() ?? 0;
    if (disc <= 0) return;
    setState(() {
      musteri_sabit_indirim.text = disc.toString();
      _gapApplied = true;
    });
    // Indirim hesaplamasini yeniden tetikle
    tutar_hesapla(false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: ext.successColor,
        behavior: SnackBarBehavior.floating,
        content: Text(
          '${_gapKampanya?['gapLabel'] ?? ''} kampanyası: %$disc indirim uygulandı',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
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

  String _tipAdi(String tip) {
    switch (tip) {
      case 'hizmet_indirimi': return 'Hizmet';
      case 'urun_indirimi':   return 'Ürün';
      case 'paket_indirimi':  return 'Paket';
      default: return 'İndirim';
    }
  }

  Future<void> _applyCarkKupon() async {
    final ext = context.appTheme;
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
            backgroundColor: ext.errorColor,
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
      // Backend response doesn't include user_id; tip + durum + sepet kontrolu ile yetinilir
      if (durum == 'kullanildi') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: ext.errorColor,
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
            backgroundColor: ext.errorColor,
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
            backgroundColor: ext.errorColor,
            behavior: SnackBarBehavior.floating,
            content: Text('Sepette ${_tipAdi(tip).toLowerCase()} bulunmadığı için kupon uygulanamadı',
                style: const TextStyle(color: Colors.white)),
          ),
        );
        return;
      }
      final deger = (odul['deger'] as num?)?.toDouble() ?? 0;
      final indirimTutar = matchTutar * (deger / 100.0);
      // Mevcut harici indirimin uzerine ekle
      final mevcut = tlyirakamacevir(harici_indirim.text);
      final yeni = mevcut + indirimTutar;
      // Kuponu kullanildi olarak isaretle
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
          backgroundColor: ext.successColor,
          behavior: SnackBarBehavior.floating,
          content: Text(
            '🎁 Kupon uygulandı: %${deger.toInt()} ${_tipAdi(tip)} indirimi (${tryformat.format(indirimTutar)} ₺)',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _carkKuponLoading = false);
    }
  }

  Widget _buildCarkKuponBanner() {
    final cs = context.colors;
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
                'Çark kuponu uygulandı: $kod — %$deger ${_tipAdi(tip)} İndirimi',
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
                    fontSize: 12.5, color: cs.onSurface.withValues(alpha: 0.45)),
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
                  vade_tarih: element2["vade_tarih"].toString(),
                  tutar: element2["tutar"].toString(),
                  odendi: element2["odendi"].toString(),
                  notlar: element2["notlar"].toString(),
                  odeme_yontemi_id: (element2["odeme_yontemi_id"]??"").toString(),
                  dogrulama_kodu: (element2["dogrulama_kodu"]??"").toString()));


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

              adisyonkalemleri.add(TaksitVade(id: element2["id"].toString(), taksitli_tahsilat_id: element2["taksitli_tahsilat_id"].toString(), vade_tarih: element2["vade_tarih"].toString(), tutar: element2["tutar"].toString(), odendi: element2["odendi"].toString(), notlar: element2["notlar"].toString(), odeme_yontemi_id: (element2["odeme_yontemi_id"]??"").toString(), dogrulama_kodu: (element2["dogrulama_kodu"]??"").toString()));

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
    final cs = context.colors;
    final ext = context.appTheme;
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      //floatingActionButton:  AltYuvarlakYeniEkleMenu(isletme_bilgi: widget.isletmebilgi,),

      appBar: AppBar(
        title:  Text('Tahsilatlar',style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w700, fontSize: 19),),
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.clear_rounded, color: cs.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        toolbarHeight: 60,
        shape: Border(bottom: BorderSide(color: ext.borderSubtle, width: 1)),
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
            icon: Icon(Icons.person_add_alt_1_rounded, color: cs.primary),
            iconSize: 24,
            tooltip: 'Yeni müşteri',
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
      ),
      body: isloading ? Center(child: CircularProgressIndicator(),):
      GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
    child:  SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16,),
            if (_gapKampanya != null && _gapKampanya!['hasCampaign'] == true && _gapBannerVisible)
              _buildGapKampanyaBanner(),
            if (secilimusteridanisan != null && adisyonkalemleri.any((e) => e is AdisyonHizmet || e is AdisyonUrun || e is AdisyonPaket))
              _buildCarkKuponBanner(),
            widget.adisyonId == '' ?
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: ext.borderSubtle, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.05),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 7,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.person_outline_rounded, size: 18, color: cs.primary),
                              SizedBox(width: 6),
                              Text('Müşteri',style: TextStyle(fontSize: 14,color: cs.onSurface,fontWeight: FontWeight.w700),),
                            ],
                          ),
                          const SizedBox(height: 10,),
                          Container(
                            alignment: Alignment.center,
                            height: 48,
                            child: LazyDropdown(
                              key: dropdownKey,
                              salonId: seciliisletme,
                              selectedItem: secilimusteridanisan,
                              onChanged: (value) {
                                secilimusteridanisan = value;
                                loadbar(value!);
                              },
                            ),
                          )
                        ],
                      )),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 28,),
                        ElevatedButton.icon(
                          onPressed: () async{
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
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: const Text('Yeni',style:TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cs.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                            minimumSize: const Size(0, 48),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)),
                          ),
                        ),
                      ],
                    ),)
                ],
              ),
            ) : const SizedBox(),
            const SizedBox(height: 12),
            secilimusteridanisan != null ? Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border.all(color: ext.borderSubtle, width: 1),
                borderRadius: BorderRadius.circular(18.0),
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.05),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children:[
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: (aktifPasifRenk ?? cs.primary).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Icon(Icons.person_rounded, color: aktifPasifRenk ?? cs.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            musteridanisanadi.text,
                            style: TextStyle(color: cs.onSurface,fontSize: 16,fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: (aktifPasifRenk ?? cs.primary).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: (aktifPasifRenk ?? cs.primary).withValues(alpha: 0.25), width: 1),
                    ),
                    child: Text(
                      aktifsadikpasif.text,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: aktifPasifRenk ?? cs.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ) : const SizedBox.shrink(),
            const SizedBox(height: 14,),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: (){ hizmetsatisi(null); },
                      icon: const Icon(Icons.spa_rounded, size: 16),
                      label: const Text('Hizmet', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 4),
                        minimumSize: const Size(0, 42),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: (){ urunsatisi(null); },
                      icon: const Icon(Icons.shopping_bag_rounded, size: 16),
                      label: const Text('Ürün', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primaryContainer,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 4),
                        minimumSize: const Size(0, 42),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: (){ paketsatisi(null); },
                      icon: const Icon(Icons.inventory_2_rounded, size: 16),
                      label: const Text('Paket', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ext.infoColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 4),
                        minimumSize: const Size(0, 42),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12,),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: ext.borderSubtle, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Container(

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      kalemleryukleniyor ? const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator(),)) : (adisyonkalemleri.isEmpty ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.receipt_long_rounded, size: 40, color: cs.primary.withValues(alpha: 0.35)),
                              const SizedBox(height: 10),
                              Text('Henüz kalem eklenmedi', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 4),
                              Text('Yukarıdan hizmet, ürün veya paket ekleyin', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11)),
                            ],
                          ),
                        ),
                      ) : ListView.builder(
                          scrollDirection: Axis.vertical,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
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

                            IconData typeIcon = Icons.receipt_long_rounded;
                            Color typeColor = cs.primary;
                            if (item is AdisyonHizmet) { typeIcon = Icons.spa_rounded; typeColor = cs.primary; }
                            else if (item is AdisyonUrun) { typeIcon = Icons.shopping_bag_rounded; typeColor = cs.primaryContainer; }
                            else if (item is AdisyonPaket) { typeIcon = Icons.inventory_2_rounded; typeColor = ext.infoColor; }
                            else if (item is SenetVade) { typeIcon = Icons.description_rounded; typeColor = ext.warningColor; }
                            else if (item is TaksitVade) { typeIcon = Icons.event_note_rounded; typeColor = ext.infoColor; }

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
                                    dismissThresholds: const {
                                      DismissDirection.startToEnd: 0.5,
                                      DismissDirection.endToStart: 0.5
                                    },
                                    direction: DismissDirection.horizontal,
                                    key: Key(key ),
                                    background: Container(
                                      color: ext.successColor,
                                      alignment: Alignment.centerLeft,
                                      padding: const EdgeInsets.only(left: 20),
                                      child: const Icon(Icons.edit_rounded, color: Colors.white),
                                    ),
                                    secondaryBackground: Container(
                                      color: cs.error,
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.only(right: 20),
                                      child: const Icon(Icons.delete_rounded, color: Colors.white),
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
                                        color: Theme.of(context).cardColor,
                                        border: Border(
                                          bottom: BorderSide(color: ext.borderSubtle, width: 1.0),
                                        ),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 38,
                                            height: 38,
                                            decoration: BoxDecoration(
                                              color: typeColor.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(11),
                                            ),
                                            alignment: Alignment.center,
                                            child: Icon(typeIcon, color: typeColor, size: 19),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(kalem, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis,),
                                                const SizedBox(height: 2),
                                                Text(satan, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant, fontWeight: FontWeight.w500)),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text('$tutar ₺', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.onSurface)),
                                              const SizedBox(height: 2),
                                              Text('$adet adet', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    )
                                ),
                              );



                          })),

                    ],
                  ),
                ),
              ),
              ),
            ),
            const SizedBox(height: 12,),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: ext.borderSubtle, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child:
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Container(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text('Tarih',style: TextStyle(fontSize: 13,color: cs.onSurfaceVariant,fontWeight: FontWeight.w600,letterSpacing: 0.2),),
                      ),
                      const SizedBox(height: 8,),
                      Container(
                        height: 48,
                        padding: const EdgeInsets.only(left:8,right: 8),
                        child: TextFormField(
                          style: TextStyle(fontSize: 15, color: cs.onSurface, fontWeight: FontWeight.w500),
                          controller: tahsilat_tarihi,
                          //editing controller of this TextField
                          decoration: InputDecoration(

                            focusColor:cs.primary ,
                            hoverColor: cs.primary ,
                            hintStyle: TextStyle(color:  cs.primary),
                            isDense: true,
                            contentPadding:  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(
                                color: ext.borderSubtle, width: 1.2),borderRadius: BorderRadius.circular(12.0),),
                            border:
                            OutlineInputBorder(borderRadius: BorderRadius.circular(12.0),),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: cs.primary, width: 1.6), borderRadius: BorderRadius.circular(12.0),
                            ),
                            disabledBorder: OutlineInputBorder(borderSide: BorderSide(
                                color: ext.borderSubtle, width: 1.2),borderRadius: BorderRadius.circular(12.0),),
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
                      const SizedBox(height: 8,),
                      Container(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text('Birim Tutar(₺)',style: TextStyle(fontSize: 13,color: cs.onSurfaceVariant,fontWeight: FontWeight.w600,letterSpacing: 0.2),),
                      ),
                      const SizedBox(height: 8,),
                      Container(
                        height: 48,
                        padding: const EdgeInsets.only(left:8,right: 8),
                        child: TextFormField(
                          style: TextStyle(fontSize: 15, color: cs.onSurface, fontWeight: FontWeight.w500),
                          keyboardType: TextInputType.phone,
                          enabled: false,
                          controller: birim_tutar,
                          onSaved: (value) {
                            birim_tutar.text = value!;
                          },

                          decoration: InputDecoration(

                            focusColor:cs.primary ,

                            hoverColor: cs.primary ,
                            filled: true,
                            fillColor: Theme.of(context).cardColor,
                            hintStyle: TextStyle(color:  cs.primary),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(
                                color: ext.borderSubtle, width: 1.2),borderRadius: BorderRadius.circular(12.0),),
                            border:
                            OutlineInputBorder(borderRadius: BorderRadius.circular(12.0),),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: cs.primary, width: 1.6), borderRadius: BorderRadius.circular(12.0),
                            ),
                            disabledBorder: OutlineInputBorder(borderSide: BorderSide(
                                color: ext.borderSubtle, width: 1.2),borderRadius: BorderRadius.circular(12.0),),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8,),
                      Container(

                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text('Müşteri İndirimi (%)',style: TextStyle(fontSize: 13,color: cs.onSurfaceVariant,fontWeight: FontWeight.w600,letterSpacing: 0.2),),
                      ),
                      const SizedBox(height: 8,),
                      Container(
                        height:48,
                        padding: const EdgeInsets.only(left:8,right: 8),
                        child: TextFormField(
                          style: TextStyle(fontSize: 15, color: cs.onSurface, fontWeight: FontWeight.w500),
                          enabled: false,
                          keyboardType: TextInputType.phone,
                          controller:musteri_sabit_indirim,


                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Theme.of(context).cardColor,
                            focusColor:cs.primary ,
                            hoverColor: cs.primary ,
                            hintStyle: TextStyle(color:  cs.primary),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(
                                color: ext.borderSubtle, width: 1.2),borderRadius: BorderRadius.circular(12.0),),
                            border:
                            OutlineInputBorder(borderRadius: BorderRadius.circular(12.0),),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: cs.primary, width: 1.6), borderRadius: BorderRadius.circular(12.0),
                            ),
                            disabledBorder: OutlineInputBorder(borderSide: BorderSide(
                                color: ext.borderSubtle, width: 1.2),borderRadius: BorderRadius.circular(12.0),),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8,),
                      Container(

                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text('İndirim (₺)',style: TextStyle(fontSize: 13,color: cs.onSurfaceVariant,fontWeight: FontWeight.w600,letterSpacing: 0.2),),
                      ),

                      const SizedBox(height: 8,),
                      Container(
                        height:48,
                        padding: const EdgeInsets.only(left:8,right: 8),
                        child: TextFormField(
                          style: TextStyle(fontSize: 15, color: cs.onSurface, fontWeight: FontWeight.w500),

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
                            fillColor: Theme.of(context).cardColor,
                            focusColor:cs.primary ,
                            hoverColor: cs.primary ,
                            hintStyle: TextStyle(color:  cs.primary),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(
                                color: ext.borderSubtle, width: 1.2),borderRadius: BorderRadius.circular(12.0),),
                            border:
                            OutlineInputBorder(borderRadius: BorderRadius.circular(12.0),),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: cs.primary, width: 1.6), borderRadius: BorderRadius.circular(12.0),
                            ),
                            disabledBorder: OutlineInputBorder(borderSide: BorderSide(
                                color: ext.borderSubtle, width: 1.2),borderRadius: BorderRadius.circular(12.0),),
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
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text('Ödeme Yöntemi',style: TextStyle(fontSize: 13,color: cs.onSurfaceVariant,fontWeight: FontWeight.w600,letterSpacing: 0.2),),
                      ),
                      const SizedBox(height: 8,),
                      Container(
                        alignment: Alignment.center,
                        margin: const EdgeInsets.only(left:8,right: 8),
                        height: 48,
                        width:double.infinity,
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          border: Border.all(color: ext.borderSubtle, width: 1.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(

                            child: DropdownButton2<OdemeTuru>(

                              isExpanded: true,
                              hint: Text(
                                'Seçiniz..',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Theme.of(context).hintColor,
                                ),
                              ),
                              items: odemeyontem
                                  .map((item) => DropdownMenuItem(
                                value: item,
                                child: Text(
                                  item.odeme_turu,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
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

                      const SizedBox(height: 8,),
                      Container(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text('Ödenecek Tutar(₺)',style: TextStyle(fontSize: 13,color: cs.onSurfaceVariant,fontWeight: FontWeight.w600,letterSpacing: 0.2),),
                      ),
                      const SizedBox(height: 8,),
                      Container(
                        height: 48,
                        padding: const EdgeInsets.only(left:8,right: 8),
                        child: TextFormField(
                          style: TextStyle(fontSize: 15, color: cs.onSurface, fontWeight: FontWeight.w500),

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
                            focusColor:cs.primary ,
                            fillColor: Theme.of(context).cardColor,
                            hoverColor: cs.primary ,
                            hintStyle: TextStyle(color:  cs.primary),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(
                                color: ext.borderSubtle, width: 1.2),borderRadius: BorderRadius.circular(12.0),),
                            border:
                            OutlineInputBorder(borderRadius: BorderRadius.circular(12.0),),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: cs.primary, width: 1.6), borderRadius: BorderRadius.circular(12.0),
                            ),
                            disabledBorder: OutlineInputBorder(borderSide: BorderSide(
                                color: ext.borderSubtle, width: 1.2),borderRadius: BorderRadius.circular(12.0),),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8,),
                      Container(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text('Kalan Alacak Tutarı(₺)',style: TextStyle(fontSize: 13,color: cs.onSurfaceVariant,fontWeight: FontWeight.w600,letterSpacing: 0.2),),
                      ),
                      const SizedBox(height: 8,),
                      Container(
                        height: 48,
                        padding: const EdgeInsets.only(left:8,right: 8),
                        child: TextFormField(
                          style: TextStyle(fontSize: 15, color: cs.onSurface, fontWeight: FontWeight.w500),
                          enabled: false,
                          keyboardType: TextInputType.phone,
                          controller: kalan_alacak_tutar,
                          onSaved: (value) {
                            kalan_alacak_tutar.text = value!;
                          },



                          decoration: InputDecoration(
                            filled: true,

                            focusColor:cs.primary ,
                            fillColor: Theme.of(context).cardColor,
                            hoverColor: cs.primary ,
                            hintStyle: TextStyle(color:  cs.primary),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(
                                color: ext.borderSubtle, width: 1.2),borderRadius: BorderRadius.circular(12.0),),
                            border:
                            OutlineInputBorder(borderRadius: BorderRadius.circular(12.0),),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: cs.primary, width: 1.6), borderRadius: BorderRadius.circular(12.0),
                            ),
                            disabledBorder: OutlineInputBorder(borderSide: BorderSide(
                                color: ext.borderSubtle, width: 1.2),borderRadius: BorderRadius.circular(12.0),),
                          ),
                        ),
                      ),
                    ],
                  ),
                )



              ],
            ),
            ),
            const SizedBox(height: 14,),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (){
                      alacaklarigoster(context);
                    },
                    icon: const Icon(Icons.account_balance_wallet_rounded, size: 16),
                    label: const Text('Alacaklar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ext.successColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                      minimumSize: const Size(0, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                  icon: const Icon(Icons.timeline_rounded, size: 16),
                  label: const Text('Taksit Yap', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  onPressed: (){
                    if(secilimusteridanisan == null){
                      showDialog(
                        context: context,
                        builder: (BuildContext context) => AlertDialog(
                          title: const Text('UYARI'),
                          content: const Text('Devam etmek için önce müşteri seçiniz veya ekleyiniz.'),
                          actions: [TextButton(child: const Text('Kapat'), onPressed: () => Navigator.of(context).pop())],
                        ),
                      );
                      return;
                    }
                    if(adisyonkalemleri.isEmpty){
                      showDialog(
                        context: context,
                        builder: (BuildContext context) => AlertDialog(
                          title: const Text('UYARI'),
                          content: const Text('Taksit yapmak için önce hizmet, ürün veya paket eklemelisiniz.'),
                          actions: [TextButton(child: const Text('Kapat'), onPressed: () => Navigator.of(context).pop())],
                        ),
                      );
                      return;
                    }

                    // Modal açılırken kalan ödeme tutarı = tahsilat tutarı (indirimler düşüldükten sonra)
                    final double toplamTahsilat = tlyirakamacevir(tahsilat_tutari.text);
                    taksit_toplam_tutar.text = tryformat.format(toplamTahsilat);
                    final TextEditingController onOdemeTutariCtrl = TextEditingController(text: '0,00');
                    OdemeTuru? secilenOnOdemeTuru;
                    {
                      showDialog(
                        context: context,
                        builder: (BuildContext dialogContext) {
                          return StatefulBuilder(
                            builder: (BuildContext sbContext, StateSetter setStateDialog) {
                              return AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                                contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                                title: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: cs.primary.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      alignment: Alignment.center,
                                      child: Icon(Icons.timeline_rounded, size: 18, color: cs.primary),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text('Yeni Taksitli Tahsilat', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface)),
                                    ),
                                  ],
                                ),
                                content: SizedBox(
                                  width: MediaQuery.of(dialogContext).size.width * 0.92,
                                  child: SingleChildScrollView(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        // Ön Ödeme Tutarı
                                        Padding(
                                          padding: const EdgeInsets.only(left: 4, bottom: 6),
                                          child: Text('Ön Ödeme Tutarı (₺)',style: TextStyle(fontSize: 13,color: cs.onSurfaceVariant,fontWeight: FontWeight.w600,letterSpacing: 0.2),),
                                        ),
                                        SizedBox(
                                          height: 42,
                                          child: TextFormField(
                                            style: TextStyle(fontSize: 14, color: cs.onSurface),
                                            controller: onOdemeTutariCtrl,
                                            keyboardType: TextInputType.phone,
                                            onChanged: (value) {
                                              final double on = tlyirakamacevir(value);
                                              final double kalan = (toplamTahsilat - on).clamp(0, double.infinity);
                                              setStateDialog(() {
                                                taksit_toplam_tutar.text = tryformat.format(kalan);
                                              });
                                            },
                                            decoration: InputDecoration(
                                              filled: true,
                                              fillColor: Theme.of(context).cardColor,
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                                              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: ext.borderSubtle, width: 1.2),borderRadius: BorderRadius.circular(12.0),),
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                                              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: cs.primary, width: 1.6), borderRadius: BorderRadius.circular(12.0)),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        // Ön Ödeme Türü
                                        Padding(
                                          padding: const EdgeInsets.only(left: 4, bottom: 6),
                                          child: Text('Ön Ödeme Türü',style: TextStyle(fontSize: 13,color: cs.onSurfaceVariant,fontWeight: FontWeight.w600,letterSpacing: 0.2),),
                                        ),
                                        Container(
                                          height: 44,
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).cardColor,
                                            border: Border.all(color: ext.borderSubtle, width: 1.2),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: DropdownButtonHideUnderline(
                                            child: DropdownButton<OdemeTuru>(
                                              isExpanded: true,
                                              hint: const Text('Seçiniz..', style: TextStyle(fontSize: 14)),
                                              value: secilenOnOdemeTuru,
                                              items: odemeyontem.map((item) => DropdownMenuItem(
                                                value: item,
                                                child: Text(item.odeme_turu, style: const TextStyle(fontSize: 14)),
                                              )).toList(),
                                              onChanged: (value) {
                                                setStateDialog(() {
                                                  secilenOnOdemeTuru = value;
                                                });
                                              },
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        // Kalan Ödeme Tutarı (auto)
                                        Padding(
                                          padding: const EdgeInsets.only(left: 4, bottom: 6),
                                          child: Text('Kalan Ödeme Tutarı (₺)',style: TextStyle(fontSize: 13,color: cs.onSurfaceVariant,fontWeight: FontWeight.w600,letterSpacing: 0.2),),
                                        ),
                                        SizedBox(
                                          height: 42,
                                          child: TextFormField(
                                            style: TextStyle(fontSize: 14, color: cs.onSurface),
                                            enabled: false,
                                            controller: taksit_toplam_tutar,
                                            decoration: InputDecoration(
                                              filled: true,
                                              fillColor: ext.surfaceMuted,
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                                              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: ext.borderSubtle, width: 1.2),borderRadius: BorderRadius.circular(12.0),),
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                                              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: cs.primary, width: 1.6), borderRadius: BorderRadius.circular(12.0)),
                                              disabledBorder: OutlineInputBorder(borderSide: BorderSide(color: ext.borderSubtle, width: 1.2),borderRadius: BorderRadius.circular(12.0),),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        // Tarih
                                        Padding(
                                          padding: const EdgeInsets.only(left: 4, bottom: 6),
                                          child: Text('Ödeme Başlangıç Tarihi',style: TextStyle(fontSize: 13,color: cs.onSurfaceVariant,fontWeight: FontWeight.w600,letterSpacing: 0.2),),
                                        ),
                                        SizedBox(
                                          height: 42,
                                          child: TextFormField(
                                            style: TextStyle(fontSize: 14, color: cs.onSurface),
                                            controller: ilk_taksit_vade_tarihi,
                                            readOnly: true,
                                            decoration: InputDecoration(
                                              filled: true,
                                              fillColor: Theme.of(context).cardColor,
                                              suffixIcon: Icon(Icons.calendar_today_rounded, size: 18, color: cs.primary),
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                                              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: ext.borderSubtle, width: 1.2),borderRadius: BorderRadius.circular(12.0),),
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                                              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: cs.primary, width: 1.6), borderRadius: BorderRadius.circular(12.0)),
                                            ),
                                            onTap: () async {
                                              DateTime? pickedDate = await showDatePicker(
                                                  context: sbContext,
                                                  initialDate: DateTime.now(),
                                                  firstDate: DateTime(1950),
                                                  lastDate: DateTime(2100));
                                              if (pickedDate != null) {
                                                String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
                                                setStateDialog(() {
                                                  ilk_taksit_vade_tarihi.text = formattedDate;
                                                });
                                              }
                                            },
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        // Taksit Sayısı
                                        Padding(
                                          padding: const EdgeInsets.only(left: 4, bottom: 6),
                                          child: Text('Taksit Sayısı (Ay)',style: TextStyle(fontSize: 13,color: cs.onSurfaceVariant,fontWeight: FontWeight.w600,letterSpacing: 0.2),),
                                        ),
                                        SizedBox(
                                          height: 42,
                                          child: TextFormField(
                                            style: TextStyle(fontSize: 14, color: cs.onSurface),
                                            keyboardType: TextInputType.phone,
                                            controller: taksit_sayisi,
                                            decoration: InputDecoration(
                                              filled: true,
                                              fillColor: Theme.of(context).cardColor,
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                                              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: ext.borderSubtle, width: 1.2),borderRadius: BorderRadius.circular(12.0),),
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                                              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: cs.primary, width: 1.6), borderRadius: BorderRadius.circular(12.0)),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                      ],
                                    ),
                                  ),
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    child: Text('KAPAT', style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
                                    onPressed: () {
                                      Navigator.of(dialogContext).pop();
                                    },
                                  ),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.check_rounded, size: 18),
                                    label: const Text('KAYDET', style: TextStyle(fontWeight: FontWeight.w700)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: cs.primary,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onPressed: () async {
                                      // Validasyon: taksit sayısı > 0, kalan > 0, tarih var
                                      String hata = "";
                                      final int? taksitN = int.tryParse(taksit_sayisi.text.trim());
                                      if (taksitN == null || taksitN < 1) {
                                        hata = "Taksit sayısı en az 1 olmalıdır.";
                                      }
                                      final double kalanT = tlyirakamacevir(taksit_toplam_tutar.text);
                                      final double onOdeme = tlyirakamacevir(onOdemeTutariCtrl.text);
                                      if (kalanT <= 0) {
                                        hata = "Kalan ödeme tutarı sıfırdan büyük olmalıdır.";
                                      }
                                      if (ilk_taksit_vade_tarihi.text.isEmpty) {
                                        hata = "Ödeme başlangıç tarihi seçiniz.";
                                      }
                                      if (onOdeme > 0 && secilenOnOdemeTuru == null) {
                                        hata = "Ön ödeme girdiyseniz ödeme türü seçmelisiniz.";
                                      }
                                      if (hata.isNotEmpty) {
                                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                                          SnackBar(content: Text(hata), backgroundColor: cs.error),
                                        );
                                        return;
                                      }

                                      // Ön ödeme türü: girilmemişse seçili main screen ödeme yöntemi, o da yoksa Nakit (id:1)
                                      String odemeYontemiId = secilenOnOdemeTuru?.id ?? (selectedodemeyontemi?.id ?? "1");
                                      String onOdemeText = tryformat.format(onOdeme);

                                      int taksitResult = await taksitekleguncelle(
                                        context,
                                        seciliisletme,
                                        adisyonkalemleri,
                                        taksit_sayisi.text,
                                        ilk_taksit_vade_tarihi.text,
                                        taksit_toplam_tutar.text,
                                        secilimusteridanisan?.id ?? "",
                                        toplamindirimtutari.text,
                                        odemeYontemiId,
                                        onOdemeText,
                                        tahsilat_tarihi.text,
                                        "",
                                        harici_indirim.text,
                                      );
                                      if (taksitResult == 200) {
                                        Navigator.of(dialogContext).pop();
                                        Navigator.of(context).pop();
                                        Navigator.of(context).pop();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Taksitlendirme başarıyla kaydedildi'), backgroundColor: ext.successColor),
                                        );
                                        initialize();
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Taksitlendirme işlenirken bir hata oluştu. Hata kodu : $taksitResult'), backgroundColor: cs.error),
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
                                ],
                              );
                            },
                          );
                        },
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)),
                  ),
                ),
                ),
              ],
              ),
            ),



            const SizedBox(height: 14,),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: ElevatedButton(
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.payments_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('TAHSİL ET', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                    ],
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ext.successColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                    minimumSize: const Size(0, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
                  ),
                ),
                ),
              ],
              ),
            ),
            const SizedBox(height: 20,),
          ],
        ),
      ),
    ));
  }

  void alacaklarigoster(BuildContext context) {
    final cs = context.colors;
    final ext = context.appTheme;
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
                          child: CircleAvatar(
                            foregroundColor: cs.onError,
                            backgroundColor: cs.error,
                            child: const Icon(Icons.close),
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
                                margin: const EdgeInsets.fromLTRB(4, 4, 4, 8),
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: ext.surfaceMuted,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: TabBar(
                                  isScrollable: false,
                                  indicatorSize: TabBarIndicatorSize.tab,
                                  labelColor: Colors.white,
                                  unselectedLabelColor: cs.primary,
                                  labelPadding: EdgeInsets.zero,
                                  dividerColor: Colors.transparent,
                                  indicator: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: cs.primary,
                                    boxShadow: [
                                      BoxShadow(
                                        color: cs.primary.withValues(alpha: 0.25),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  tabs: const [
                                    Tab(
                                      height: 38,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.event_note_rounded, size: 16),
                                          SizedBox(width: 6),
                                          Text("Taksitler", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                                        ],
                                      ),
                                    ),
                                    Tab(
                                      height: 38,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.description_rounded, size: 16),
                                          SizedBox(width: 6),
                                          Text("Senetler", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                                        ],
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

                                              return Container(
                                                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: isCheckedList[index] ? cs.primary.withValues(alpha: 0.06) : Theme.of(context).cardColor,
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: isCheckedList[index] ? cs.primary.withValues(alpha: 0.4) : ext.borderSubtle,
                                                    width: 1.2,
                                                  ),
                                                ),
                                                child: ListTile(
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                  leading: Checkbox(
                                                    activeColor: cs.primary,
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                                    value: isCheckedList[index],
                                                    onChanged: (bool? value) {
                                                      setState(() {
                                                        isCheckedList[index] = value!;
                                                        if(value) {
                                                          ++secilialacaktaksit;
                                                        } else {
                                                          --secilialacaktaksit;
                                                        }
                                                      });
                                                    },
                                                  ),
                                                  title: Text(kalem2, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface)),
                                                  subtitle: Text(satan2, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                                                  trailing: Text(
                                                    '$tutar2 ₺\n$adet2 adet',
                                                    textAlign: TextAlign.right,
                                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.onSurface),
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

                                              return Container(
                                                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: isCheckedList2[index] ? cs.primary.withValues(alpha: 0.06) : Theme.of(context).cardColor,
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: isCheckedList2[index] ? cs.primary.withValues(alpha: 0.4) : ext.borderSubtle,
                                                    width: 1.2,
                                                  ),
                                                ),
                                                child: ListTile(
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                  leading: Checkbox(
                                                    activeColor: cs.primary,
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                                    value: isCheckedList2[index],
                                                    onChanged: (bool? value) {
                                                      setState(() {
                                                        isCheckedList2[index] = value!;
                                                        if(value) {
                                                          ++secilialacaksenet;
                                                        } else {
                                                          --secilialacaksenet;
                                                        }
                                                      });
                                                    },
                                                  ),
                                                  title: Text(kalem2, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface)),
                                                  subtitle: Text(satan2, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                                                  trailing: Text(
                                                    '$tutar2 ₺\n$adet2 adet',
                                                    textAlign: TextAlign.right,
                                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.onSurface),
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
                              const SizedBox(height: 12),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: ext.successColor,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    ),
                                    icon: const Icon(Icons.arrow_circle_right_rounded, size: 18),
                                    label: const Text("Seçilileri Tahsilata Aktar", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
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
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
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
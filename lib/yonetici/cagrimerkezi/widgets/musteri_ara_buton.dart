// Uygulama geneli musteri "Ara" butonu — Cagri Merkezi arama butonlarinin
// (arama_liste_detay_ekrani._AraButon) ayni akisi, her musteri ekraninda.
//
// - Gorunurluk tek yerden: CagriApi.aramaAcik (BottomNavigationExample kurar).
//   Kapali ise widget hic yer kaplamaz (SizedBox.shrink).
// - user_id verilirse numara sunucudan alinir (maskeli personel de arayabilir,
//   numara cihaza/ekrana gelmez). Yoksa ham telefon kullanilir.
// - Softphone acik+kayitliysa uygulama icinden, degilse Bria dahilisi calar.
import 'package:randevu_sistem/dil/material.dart';
import 'package:randevu_sistem/theme/app_tokens.dart';

import '../cagri_api.dart';

enum MusteriAraStil {
  /// Yesil dolu daire (Cagri Merkezi listesindeki buton gibi).
  daire,

  /// Kucuk yesil telefon ikonu (liste satirlari / kart kenarlari).
  ikon,

  /// Ikon + "Ara" yazili kucuk dolu buton (detay sayfalari / alt sayfalar).
  etiketli,
}

class MusteriAraButon extends StatefulWidget {
  final String? userId;
  final String? telefon;
  final String? sube;
  final String? gorunenAd;
  final MusteriAraStil stil;
  final double boyut;

  const MusteriAraButon({
    super.key,
    this.userId,
    this.telefon,
    this.sube,
    this.gorunenAd,
    this.stil = MusteriAraStil.ikon,
    this.boyut = 20,
  });

  /// Bu musteri icin buton gosterilebilir mi? (Satir duzenini buna gore
  /// kurmak isteyen cagiranlar icin.)
  static bool gosterilir({String? userId, String? telefon}) {
    if (!CagriApi.aramaAcik) return false;
    final uid = (userId ?? '').trim();
    final uidVar = uid.isNotEmpty && uid != 'null' && uid != '0';
    final ham = telefon ?? '';
    final tel = ham.contains('*') ? '' : ham.replaceAll(RegExp(r'\D'), ''); // maskeli = yok
    return uidVar || tel.isNotEmpty;
  }

  /// Butonsuz kullanim (popup menu / ozel aksiyon icin).
  static Future<void> ara(
    BuildContext context, {
    String? userId,
    String? telefon,
    String? sube,
    String? gorunenAd,
  }) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(const SnackBar(
        content: Text('Arama başlatılıyor...'), duration: Duration(seconds: 2)));
    try {
      final sonuc = await CagriApi.musteriAra(
          userId: userId, telefon: telefon, sube: sube, gorunenAd: gorunenAd);
      messenger?.hideCurrentSnackBar();
      messenger?.showSnackBar(SnackBar(
        content: Text(sonuc.message.isNotEmpty
            ? sonuc.message
            : (sonuc.success ? 'Arama başlatıldı' : 'Arama başlatılamadı')),
        backgroundColor: sonuc.kirmiziBant ? Colors.redAccent : null,
        duration: const Duration(seconds: 5),
      ));
    } on CagriApiException catch (e) {
      messenger?.hideCurrentSnackBar();
      messenger?.showSnackBar(SnackBar(
          content: Text(e.message), backgroundColor: Colors.redAccent));
    } catch (e) {
      messenger?.hideCurrentSnackBar();
      messenger?.showSnackBar(SnackBar(
          content: Text('Arama hatası: $e'), backgroundColor: Colors.redAccent));
    }
  }

  @override
  State<MusteriAraButon> createState() => _MusteriAraButonState();
}

class _MusteriAraButonState extends State<MusteriAraButon> {
  bool _araniyor = false;

  Future<void> _ara() async {
    if (_araniyor) return;
    setState(() => _araniyor = true);
    try {
      await MusteriAraButon.ara(context,
          userId: widget.userId,
          telefon: widget.telefon,
          sube: widget.sube,
          gorunenAd: widget.gorunenAd);
    } finally {
      if (mounted) setState(() => _araniyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!MusteriAraButon.gosterilir(userId: widget.userId, telefon: widget.telefon)) {
      return const SizedBox.shrink();
    }
    final renk = context.appTheme.successColor;
    final yukleniyor = SizedBox(
      width: widget.boyut * 0.9,
      height: widget.boyut * 0.9,
      child: CircularProgressIndicator(
          strokeWidth: 2,
          color: widget.stil == MusteriAraStil.ikon ? renk : Colors.white),
    );

    switch (widget.stil) {
      case MusteriAraStil.daire:
        return Material(
          color: renk,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _araniyor ? null : _ara,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: _araniyor
                  ? yukleniyor
                  : Icon(Icons.call, color: Colors.white, size: widget.boyut),
            ),
          ),
        );
      case MusteriAraStil.etiketli:
        return FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: renk,
            foregroundColor: Colors.white,
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          ),
          onPressed: _araniyor ? null : _ara,
          icon: _araniyor ? yukleniyor : Icon(Icons.call, size: widget.boyut * 0.9),
          label: Text(CagriApi.araEtiketi),
        );
      case MusteriAraStil.ikon:
        return IconButton(
          tooltip: CagriApi.araEtiketi,
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          padding: EdgeInsets.zero,
          onPressed: _araniyor ? null : _ara,
          icon: _araniyor
              ? yukleniyor
              : Icon(Icons.call, color: renk, size: widget.boyut),
        );
    }
  }
}

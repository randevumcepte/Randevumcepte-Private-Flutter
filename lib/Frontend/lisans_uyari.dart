import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:randevu_sistem/Login%20Sayfas%C4%B1/tanitim.dart';

/// Lisans (uyelik_bitis_tarihi) ile ilgili uyari/blok ekranlari.
///
/// Mantik Laravel projesindeki `lisans_sure_kontrol` ile ayni:
///  - uyelik_bitis_tarihi NULL / bos  -> lisans henuz aktif degil (blok)
///  - kalan gun < 0                   -> lisans suresi bitti (blok)
///  - 0 <= kalan gun <= 30            -> yaklasan bitis uyarisi (gunde 3 kez)
///
/// Platform iletisim numarasi (isletmeye lisans satisi icin) Laravel view'i
/// ile ayni: 0541 294 81 44.
const String kLisansIletisimTel = '05412948144';
const String kLisansIletisimGosterim = '0541 294 81 44';

/// Isletme tarafi lisans-bitti ekraninda "ayrintili bilgi" yonlendirmesi.
const String kLisansWebUrl = 'https://randevumcepte.com.tr';
const String kLisansWebGosterim = 'randevumcepte.com.tr';

/// Yaklasan bitis uyarisinin gosterilecegi gun esigi.
const int kLisansUyariEsikGun = 30;

/// Gunde gosterilebilecek maksimum uyari sayisi.
const int kLisansGunlukMaxUyari = 3;

/// Gosterimler arasi minimum dakika. Web ile ayni (~3.5 saat); boylece
/// gunluk 3 gosterim 09:00-20:00 mesaisine yayilir.
const int kLisansAralikDk = 210;

/// `uyelik_bitis_tarihi` degerinden kalan gun sayisini hesaplar.
/// Tarih yok/bos/gecersiz ise `null` doner.
int? lisansKalanGun(dynamic tarih) {
  final s = tarih?.toString().trim() ?? '';
  if (s.isEmpty || s.toLowerCase() == 'null') return null;

  // "2026-07-15" / "2026-07-15 00:00:00" / "2026-07-15T00:00:00" formatlari
  final datePart = s.split(' ').first.split('T').first;
  final parts = datePart.split('-');
  if (parts.length < 3) return null;
  final y = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  final d = int.tryParse(parts[2]);
  if (y == null || m == null || d == null) return null;

  // Laravel ile ayni: bitis gununun 23:59:59'una kadar gecerli.
  final bitis = DateTime(y, m, d, 23, 59, 59);
  final now = DateTime.now();
  return (bitis.difference(now).inHours / 24).round();
}

/// Lisans bitmis (ya da henuz aktif olmamis) mi? Blok ekrani bu durumda acilir.
bool lisansBittiMi(dynamic tarih) {
  final s = tarih?.toString().trim() ?? '';
  if (s.isEmpty || s.toLowerCase() == 'null') return true; // henuz aktif degil
  final gun = lisansKalanGun(tarih);
  if (gun == null) return true;
  return gun < 0;
}

/// Tarih NULL/bos mu? (Laravel: "Lisans Kullaniminiz Henuz Aktif Olmadi!")
bool _lisansAktifDegilMi(dynamic tarih) {
  final s = tarih?.toString().trim() ?? '';
  return s.isEmpty || s.toLowerCase() == 'null';
}

/// isletmebilgi Map'inden ilk dolu alani okur.
String? _alanOku(dynamic isletmebilgi, List<String> keys) {
  if (isletmebilgi is! Map) return null;
  for (final k in keys) {
    final v = isletmebilgi[k];
    if (v != null && v.toString().trim().isNotEmpty &&
        v.toString().trim().toLowerCase() != 'null') {
      return v.toString().trim();
    }
  }
  return null;
}

/// Telefonu gosterim/arama icin formatlar: 10 haneli (5xx...) numaranin basina
/// 0 ekler. Zaten 0 veya + ile basliyorsa dokunmaz.
String? _telGoster(String? t) {
  if (t == null) return null;
  final s = t.trim();
  if (s.isEmpty) return null;
  if (s.startsWith('+') || s.startsWith('0')) return s;
  final rakam = s.replaceAll(RegExp(r'[^0-9]'), '');
  if (rakam.length == 10 && rakam.startsWith('5')) return '0$rakam';
  return s;
}

Future<void> _ara(String numara) async {
  final temiz = numara.replaceAll(RegExp(r'[^0-9+]'), '');
  if (temiz.isEmpty) return;
  final uri = Uri.parse('tel:$temiz');
  // canLaunchUrl bazi cihazlarda yanlis false donebiliyor; once dogrudan
  // telefon ceviriciyi acmayi dene, olmazsa canLaunchUrl ile tekrar dene.
  try {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (ok) return;
  } catch (_) {}
  try {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  } catch (e) {
    log('Lisans arama baslatilamadi: $e');
  }
}

/// Web sitesini haricî tarayicida acar (ayrintili bilgi yonlendirmesi).
Future<void> _webAc(String url) async {
  try {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (e) {
    log('Web acilamadi: $e');
  }
}

/// Oturumu kapatip giris/onboarding ekranina doner.
Future<void> lisansCikisYap(BuildContext context) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
    await prefs.remove('musteri');
    await prefs.remove('user_type');
  } catch (_) {}
  if (!context.mounted) return;
  Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => OnBoardingPage()),
    (route) => false,
  );
}

// ─────────────────────────────────────────────────────────────────────────
//  YAKLASAN BITIS UYARISI (gunde 3 kez, sadece isletme tarafi)
// ─────────────────────────────────────────────────────────────────────────

class LisansUyari {
  static bool _aktifDialog = false;

  /// Lisans durumunu kontrol eder; 30 gun veya az kalmissa (henuz bitmemisse)
  /// gunde [kLisansGunlukMaxUyari] kez uyari dialogu gosterir. Dialog disariya
  /// tiklayinca KAPANMAZ; sadece butonla kapanir.
  static Future<void> kontrolEt(
    BuildContext context,
    dynamic isletmebilgi,
  ) async {
    if (isletmebilgi is! Map) return;
    final tarih = isletmebilgi['uyelik_bitis_tarihi'];

    // Bitmis/aktif degil -> blok ekrani devrede, dialog gosterme.
    if (lisansBittiMi(tarih)) return;

    final gun = lisansKalanGun(tarih);
    if (gun == null || gun < 0 || gun > kLisansUyariEsikGun) return;

    if (!await _gunlukKotaVar()) return;
    if (_aktifDialog || !context.mounted) return;

    await _kotayiArttir();
    await _goster(context, gun);
  }

  static Future<bool> _gunlukKotaVar() async {
    final prefs = await SharedPreferences.getInstance();
    final bugun = _bugunStr();
    final ayniGun = prefs.getString('lisans_uyari_tarih') == bugun;
    final sayac = ayniGun ? (prefs.getInt('lisans_uyari_sayac') ?? 0) : 0;
    final son = ayniGun ? (prefs.getInt('lisans_uyari_son') ?? 0) : 0;
    final simdi = DateTime.now().millisecondsSinceEpoch;
    // Web ile ayni kosul: gunluk max + son gosterimden bu yana min aralik.
    return sayac < kLisansGunlukMaxUyari &&
        (simdi - son) >= kLisansAralikDk * 60 * 1000;
  }

  static Future<void> _kotayiArttir() async {
    final prefs = await SharedPreferences.getInstance();
    final bugun = _bugunStr();
    final ayniGun = prefs.getString('lisans_uyari_tarih') == bugun;
    final sayac = ayniGun ? (prefs.getInt('lisans_uyari_sayac') ?? 0) : 0;
    await prefs.setString('lisans_uyari_tarih', bugun);
    await prefs.setInt('lisans_uyari_sayac', sayac + 1);
    await prefs.setInt('lisans_uyari_son', DateTime.now().millisecondsSinceEpoch);
  }

  static String _bugunStr() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  static Future<void> _goster(BuildContext context, int gun) async {
    _aktifDialog = true;
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false, // disariya tiklayinca kapanmaz
        barrierColor: const Color(0x8C0F172A), // rgba(15,23,42,.55)
        builder: (ctx) => WillPopScope(
          onWillPop: () async => false, // geri tusu de kapatmaz
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: _LisansUyariKart(
              gun: gun,
              onKapat: () => Navigator.of(ctx).pop(),
              onAra: () => _ara(kLisansIletisimTel),
            ),
          ),
        ),
      );
    } finally {
      _aktifDialog = false;
    }
  }
}

/// Laravel `layout_isletmeadmin.blade.php` icindeki `.wa-promo-card` uyari
/// popup tasariminin Flutter karsiligi.
class _LisansUyariKart extends StatelessWidget {
  final int gun;
  final VoidCallback onKapat;
  final VoidCallback onAra;

  const _LisansUyariKart({
    Key? key,
    required this.gun,
    required this.onKapat,
    required this.onAra,
  }) : super(key: key);

  // Uyari temasi: amber/turuncu gradient
  static const Color _c1 = Color(0xFFF59E0B);
  static const Color _c2 = Color(0xFFF97316);
  static const Color _kirmizi = Color(0xFFDC2626);

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 430),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x4D0F172A), // rgba(15,23,42,.30)
              blurRadius: 60,
              offset: Offset(0, 24),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 30, 26, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Yuvarlak gradient ikon
                  Container(
                    width: 66,
                    height: 66,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [_c1, _c2],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _c2.withValues(alpha: 0.40),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.warning_amber_rounded,
                        color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 14),
                  // Baslik
                  const Text(
                    'Lisans Süresi Uyarısı',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Metin (kalan gun kirmizi vurgulu)
                  Text.rich(
                    TextSpan(
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: Color(0xFF475569),
                      ),
                      children: [
                        const TextSpan(
                            text: 'Lisans kullanım sürenizin dolmasına '),
                        TextSpan(
                          text: gun <= 0 ? 'bugün' : '$gun gün',
                          style: const TextStyle(
                              color: _kirmizi, fontWeight: FontWeight.w800),
                        ),
                        TextSpan(
                            text: gun <= 0 ? ' doluyor. ' : ' kaldı. '),
                        const TextSpan(
                          text:
                              'Hizmetin kesintisiz devam etmesi için lisansınızı '
                              'yenilemek üzere lütfen bizimle iletişime geçin.',
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  // Iletisim numarasi
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.phone, size: 17, color: _c2),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: onAra,
                        child: const Text(
                          '0 541 294 81 44',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: _c2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // Aksiyon butonlari
                  Row(
                    children: [
                      Expanded(
                        child: _AraButon(onTap: onAra),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: onKapat,
                          child: Container(
                            height: 46,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Kapat',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Kapat (X)
            Positioned(
              top: 8,
              right: 10,
              child: GestureDetector(
                onTap: onKapat,
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.close, size: 22, color: Color(0xFF94A3B8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AraButon extends StatelessWidget {
  final VoidCallback onTap;
  const _AraButon({Key? key, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_LisansUyariKart._c1, _LisansUyariKart._c2],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: _LisansUyariKart._c2.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.phone, size: 16, color: Colors.white),
            SizedBox(width: 7),
            Text(
              'Hemen Ara',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
//  LISANS BITTI BLOK EKRANI
// ─────────────────────────────────────────────────────────────────────────

class LisansBittiEkrani extends StatelessWidget {
  final dynamic isletmebilgi;

  /// Musteri tarafi mi? (true: iletisim/adres + arama, false: Laravel view'i)
  final bool isMusteri;

  const LisansBittiEkrani({
    Key? key,
    required this.isletmebilgi,
    required this.isMusteri,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1220),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: isMusteri ? _musteriIcerik(context) : _isletmeIcerik(context),
            ),
          ),
        ),
      ),
    );
  }

  // ── ISLETME TARAFI (Laravel lisanssurebitti.blade.php benzeri) ──────────
  Widget _isletmeIcerik(BuildContext context) {
    final aktifDegil = _lisansAktifDegilMi(
      isletmebilgi is Map ? isletmebilgi['uyelik_bitis_tarihi'] : null,
    );
    final salonAdi = _alanOku(isletmebilgi, const ['salon_adi']) ?? '';
    final salonId = _alanOku(isletmebilgi, const ['id']) ?? '';

    final baslik = aktifDegil
        ? 'Lisans Kullanımınız Henüz Aktif Olmadı!'
        : 'Lisans Kullanım Süreniz Bitti!';
    final aciklama = StringBuffer()
      ..write(salonAdi.isNotEmpty ? 'Sayın $salonAdi. ' : 'Sayın Yetkili. ')
      ..write(aktifDegil
          ? 'Panel kullanımı için lisansınız henüz aktif olmamıştır. '
          : 'Panel kullanım süreniz sona ermiştir. ')
      ..write(
          'Ayrıntılı bilgi için bizimle iletişime geçebilir veya web sitemizi ziyaret edebilirsiniz.');

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.lock_clock_rounded, color: Color(0xFF5076DB), size: 72),
        const SizedBox(height: 24),
        Text(
          baslik,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
            height: 1.25,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          aciklama.toString(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 15,
            height: 1.5,
            fontFamily: 'Montserrat',
          ),
        ),
        if (salonId.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            'İşletme ID: $salonId',
            style: const TextStyle(color: Colors.white38, fontSize: 13),
          ),
        ],
        const SizedBox(height: 32),
        _cerceveliButon(
          icon: Icons.phone,
          label: 'İLETİŞİME GEÇMEK İÇİN : $kLisansIletisimGosterim',
          onTap: () => _ara(kLisansIletisimTel),
        ),
        const SizedBox(height: 14),
        _cerceveliButon(
          icon: Icons.language,
          label: 'AYRINTILI BİLGİ : $kLisansWebGosterim',
          onTap: () => _webAc(kLisansWebUrl),
        ),
        const SizedBox(height: 14),
        _cerceveliButon(
          icon: Icons.logout,
          label: 'ÇIKIŞ YAPIN',
          onTap: () => lisansCikisYap(context),
        ),
      ],
    );
  }

  // ── MUSTERI TARAFI (iletisim bilgisi + adres + arama) ──────────────────
  Widget _musteriIcerik(BuildContext context) {
    final salonAdi = _alanOku(isletmebilgi, const ['salon_adi']) ?? 'İşletme';
    final telefon = _telGoster(_alanOku(isletmebilgi, const ['telefon_1', 'telefon', 'telefon_2']));
    final adres = _alanOku(isletmebilgi, const ['adres']);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.info_outline_rounded, color: Color(0xFF5076DB), size: 72),
        const SizedBox(height: 24),
        const Text(
          'Hizmet Geçici Olarak Kullanılamıyor',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
            height: 1.25,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '$salonAdi şu anda uygulama üzerinden hizmet veremiyor. '
          'Randevu ve bilgi için işletme ile doğrudan iletişime geçebilirsiniz.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 15,
            height: 1.5,
            fontFamily: 'Montserrat',
          ),
        ),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Column(
            children: [
              _bilgiSatiri(Icons.store_mall_directory_outlined, salonAdi),
              if (adres != null) ...[
                const SizedBox(height: 12),
                _bilgiSatiri(Icons.location_on_outlined, adres),
              ],
              if (telefon != null) ...[
                const SizedBox(height: 12),
                _bilgiSatiri(Icons.phone_outlined, telefon),
              ],
            ],
          ),
        ),
        const SizedBox(height: 26),
        if (telefon != null)
          _cerceveliButon(
            icon: Icons.phone,
            label: 'İŞLETMEYİ ARA',
            onTap: () => _ara(telefon),
          ),
        const SizedBox(height: 14),
        _cerceveliButon(
          icon: Icons.logout,
          label: 'ÇIKIŞ YAP',
          onTap: () => lisansCikisYap(context),
        ),
      ],
    );
  }

  Widget _bilgiSatiri(IconData icon, String metin) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF5076DB), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            metin,
            style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
          ),
        ),
      ],
    );
  }

  Widget _cerceveliButon({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18, color: Colors.white),
        label: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: const BorderSide(color: Colors.white),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
//  LISANS BITTI UYARI BANNER'I (Hesabim ekrani icinde gosterilir)
// ─────────────────────────────────────────────────────────────────────────

/// Lisans bitmis isletme Hesabim ekranina yonlendirildiginde, sayfanin
/// ustunde kalici olarak gosterilen kirmizi uyari karti. Iletisim numarasini
/// arama butonu icerir.
class LisansBittiBanner extends StatelessWidget {
  final dynamic isletmebilgi;
  const LisansBittiBanner({Key? key, required this.isletmebilgi}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final aktifDegil = _lisansAktifDegilMi(
      isletmebilgi is Map ? isletmebilgi['uyelik_bitis_tarihi'] : null,
    );
    final salonId = _alanOku(isletmebilgi, const ['id']);
    final baslik = aktifDegil
        ? 'Lisans Kullanımınız Henüz Aktif Olmadı'
        : 'Lisans Kullanım Süreniz Bitti';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: Color(0xFFDC2626), size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      baslik,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF991B1B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      aktifDegil
                          ? 'Paneli kullanmaya devam edebilmek için lisansınızın aktif edilmesi gerekiyor. Uygun paketi almak için bizimle iletişime geçin.'
                          : 'Panel kullanım süreniz sona erdi. Yalnızca hesap ve fatura bilgilerinize erişebilirsiniz. Kullanıma devam için lisansınızı yenileyin.',
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: Color(0xFF7F1D1D),
                      ),
                    ),
                    if (salonId != null) ...[
                      const SizedBox(height: 4),
                      Text('İşletme ID: $salonId',
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFFB91C1C))),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _ara(kLisansIletisimTel),
              icon: const Icon(Icons.phone, size: 18),
              label: const Text('İletişime Geç : $kLisansIletisimGosterim'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

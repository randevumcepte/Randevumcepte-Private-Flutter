import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:randevu_sistem/Frontend/cropimage.dart';
import 'package:randevu_sistem/Models/user.dart';
import 'package:randevu_sistem/yonetici/dashboard/bildirimler/bildirimler.dart';
import 'package:randevu_sistem/yonetici/dashboard/profilbilgileri.dart';
import 'package:randevu_sistem/yonetici/diger/menu/bildirim_ayarlari/bildirim_ayarlari_page.dart';
import 'package:randevu_sistem/yonetici/diger/menu/bildirim_ayarlari/bildirimlerim_page.dart';

import 'profil_api.dart';
import 'profil_sayfalar.dart';
import 'profil_tema.dart';

/// Menü > Profil Bilgileri: kişi kartı + istatistikler + sıradaki müşteri + ayar satırları.
/// Herkes (her rol) aynı tasarımı görür; içerik role göre değişir. Alt menüye dokunulmaz.
class ProfilSayfasi extends StatefulWidget {
  final dynamic isletmebilgi;
  final int kullanicirolu;
  final VoidCallback onCikis;
  const ProfilSayfasi({super.key, required this.isletmebilgi, required this.kullanicirolu, required this.onCikis});

  @override
  State<ProfilSayfasi> createState() => _ProfilSayfasiState();
}

class _ProfilSayfasiState extends State<ProfilSayfasi> {
  Kullanici? _k;
  Map<String, dynamic> _o = {};
  bool _yukleniyor = true;
  bool _resimYukleniyor = false;

  String get _sube => widget.isletmebilgi['id'].toString();
  bool get _yonetici => _o['yonetici'] == true || widget.kullanicirolu < 5;
  bool get _kazancGorunur => widget.kullanicirolu == 5 && widget.isletmebilgi['studyo_modu'].toString() != '1';

  @override
  void initState() {
    super.initState();
    _kullaniciOku();
    _yukle();
    HakkindaSayfasi.surumAl().then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _kullaniciOku() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString('user');
    if (s == null || !mounted) return;
    setState(() => _k = Kullanici.fromJson(jsonDecode(s)));
  }

  /// Önce hızlı özet (kazanç hesabı hariç), ardından kazanç dahil tam özet.
  Future<void> _yukle() async {
    final hizli = await ProfilApi.get('ozet', _sube, {'hizli': '1'});
    if (!mounted) return;
    setState(() {
      _yukleniyor = false;
      if (ProfilApi.ok(hizli)) _o = {..._o, ...hizli, if (_o['bu_ay'] != null) 'bu_ay': _o['bu_ay'], if (_o['hedef'] != null) 'hedef': _o['hedef']};
    });
    final tam = await ProfilApi.get('ozet', _sube);
    if (!mounted || !ProfilApi.ok(tam)) return;
    setState(() => _o = tam);
  }

  Future<void> _ac(Widget sayfa) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => sayfa));
    if (!mounted) return;
    await _kullaniciOku();
    _yukle();
  }

  // ─────────────────────────────── foto

  Future<void> _resimSec() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (x == null || !mounted) return;
    final kirpik = await Navigator.push<File>(context, MaterialPageRoute(builder: (_) => CropScreen(imageFile: File(x.path))));
    if (kirpik == null) return;
    setState(() => _resimYukleniyor = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = jsonDecode(prefs.getString('user')!);
      final req = http.MultipartRequest('POST', Uri.parse('https://app.randevumcepte.com.tr/api/v1/profilresimyukle'));
      req.fields['yetkili_id'] = user['id'].toString();
      req.fields['sube'] = _sube;
      final raw = prefs.getString('token');
      if (raw != null && raw.isNotEmpty) {
        String t;
        try {
          final d = jsonDecode(raw);
          t = d is String ? d : d.toString();
        } catch (_) {
          t = raw;
        }
        req.headers['Authorization'] = 'Bearer $t';
      }
      req.files.add(await http.MultipartFile.fromPath('folderPath', kirpik.path));
      final res = await http.Response.fromStream(await req.send());
      if (res.statusCode == 200) {
        user['profil_resim'] = jsonDecode(res.body)['profilresmi'] ?? '';
        await prefs.setString('user', jsonEncode(user));
        await _kullaniciOku();
        _bildir('Profil fotoğrafınız güncellendi.');
      } else {
        _bildir('Fotoğraf yüklenemedi.', hata: true);
      }
    } catch (_) {
      _bildir('Fotoğraf yüklenemedi.', hata: true);
    }
    if (mounted) setState(() => _resimYukleniyor = false);
  }

  void _bildir(String m, {bool hata = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: hata ? Colors.red.shade700 : PT.koyu,
          content: Text(m)));
  }

  // ─────────────────────────────── durum

  void _durumSec() {
    final durumlar = Map<String, dynamic>.from(_o['durumlar'] ?? {'musait': 'Müsait', 'molada': 'Molada', 'izinli': 'İzinli'});
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Durumum', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: PT.koyu)),
            const SizedBox(height: 4),
            const Text('Yöneticiniz durumunuzu Ekibim ekranında görür.', style: TextStyle(fontSize: 13, color: PT.gri)),
            const SizedBox(height: 12),
            ...durumlar.entries.map((e) {
              final secili = (_o['durum'] ?? 'musait') == e.key;
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                leading: Container(width: 14, height: 14, decoration: BoxDecoration(color: PT.durumRenk(e.key), shape: BoxShape.circle)),
                title: Text(e.value.toString(), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5, color: PT.koyu)),
                trailing: secili ? const Icon(Icons.check_circle_rounded, color: PT.mor) : null,
                onTap: () async {
                  Navigator.pop(c);
                  final eski = _o['durum'];
                  setState(() => _o['durum'] = e.key);
                  final r = await ProfilApi.post('durum', _sube, {'durum': e.key});
                  if (!ProfilApi.ok(r)) {
                    setState(() => _o['durum'] = eski);
                    _bildir((r['hata'] ?? 'Kaydedilemedi.').toString(), hata: true);
                  }
                },
              );
            }),
          ]),
        ),
      ),
    );
  }

  // ─────────────────────────────── çizim

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: PT.zemin,
        body: Stack(children: [
          const PTZemin(),
          SafeArea(
            child: RefreshIndicator(
              color: PT.mor,
              onRefresh: () async {
                await _kullaniciOku();
                await _yukle();
              },
              child: ListView(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
                children: [
                  _ustBar(),
                  const SizedBox(height: 10),
                  _baslik(),
                  const SizedBox(height: 18),
                  _istatistik(),
                  const SizedBox(height: 12),
                  _siradaki(),
                  const SizedBox(height: 12),
                  ..._satirlar(),
                  const SizedBox(height: 14),
                  _cikis(),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _ustBar() => Row(children: [
        PTDaireDugme(ikon: Icons.arrow_back_rounded, onTap: () => Navigator.pop(context)),
        const Spacer(),
        Stack(clipBehavior: Clip.none, children: [
          PTDaireDugme(
            ikon: Icons.notifications_none_rounded,
            onTap: () => _ac(BildirimlerScreen(isletmebilgi: widget.isletmebilgi, kullanicirolu: widget.kullanicirolu)),
          ),
          if ((_o['okunmamis_bildirim'] ?? 0) is int && (_o['okunmamis_bildirim'] ?? 0) > 0)
            Positioned(
              right: -2,
              top: -4,
              child: Container(
                constraints: const BoxConstraints(minWidth: 20),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white, width: 2)),
                child: Text('${(_o['okunmamis_bildirim'] as int) > 99 ? '99+' : _o['okunmamis_bildirim']}',
                    textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ),
        ]),
      ]);

  ImageProvider? _resim() {
    final r = _k?.profil_resim ?? '';
    if (r.isEmpty || r == 'null') return null;
    return NetworkImage('https://app.randevumcepte.com.tr/$r');
  }

  String _tel(String? raw) {
    final d = (raw ?? '').replaceAll(RegExp(r'\D'), '');
    if (d.isEmpty) return '';
    final o = d.startsWith('0') ? d : '0$d';
    if (o.length != 11) return o;
    return '${o.substring(0, 4)} ${o.substring(4, 7)} ${o.substring(7, 9)} ${o.substring(9)}';
  }

  Widget _baslik() {
    final ad = (_k?.name ?? '') == 'null' ? '' : (_k?.name ?? '');
    final unvan = (_k?.unvan ?? '') == 'null' ? '' : (_k?.unvan ?? '');
    final durum = (_o['durum'] ?? 'musait').toString();
    final durumAd = (_o['durumlar'] is Map ? _o['durumlar'][durum] : null) ?? {'musait': 'Müsait', 'molada': 'Molada', 'izinli': 'İzinli'}[durum] ?? 'Müsait';
    final resim = _resim();
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Stack(clipBehavior: Clip.none, children: [
        Container(
          width: 124,
          height: 124,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [
            BoxShadow(color: PT.mor.withValues(alpha: 0.16), blurRadius: 22, offset: const Offset(0, 10)),
          ]),
          child: CircleAvatar(
            backgroundColor: PT.lila,
            backgroundImage: resim,
            child: _resimYukleniyor
                ? const CircularProgressIndicator(color: PT.mor, strokeWidth: 2.5)
                : resim == null
                    ? Text(ad.isNotEmpty ? ad.trim()[0].toUpperCase() : '?',
                        style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w800, color: PT.mor))
                    : null,
          ),
        ),
        Positioned(
          right: 2,
          bottom: 4,
          child: GestureDetector(
            onTap: _resimYukleniyor ? null : _resimSec,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [
                BoxShadow(color: PT.mor.withValues(alpha: 0.22), blurRadius: 10, offset: const Offset(0, 4)),
              ]),
              child: const Icon(Icons.photo_camera_rounded, color: PT.mor, size: 20),
            ),
          ),
        ),
      ]),
      const SizedBox(width: 16),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: _durumSec,
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 6, 6, 6),
                decoration: BoxDecoration(
                  color: PT.durumRenk(durum).withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: PT.durumRenk(durum).withValues(alpha: 0.28)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 9, height: 9, decoration: BoxDecoration(color: PT.durumRenk(durum), shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text(durumAd.toString(), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: PT.durumKoyu(durum))),
                  Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: PT.durumKoyu(durum)),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(ad.isEmpty ? '—' : ad,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: PT.koyu, letterSpacing: -0.4, height: 1.15)),
          if (unvan.isNotEmpty) ...[
            const SizedBox(height: 7),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: PT.lila, borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.person_rounded, size: 15, color: PT.mor),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(unvan,
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: PT.mor)),
                ),
              ]),
            ),
          ],
          if (_tel(_k?.gsm1).isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.phone_rounded, size: 16, color: PT.koyu),
              const SizedBox(width: 6),
              Text(_tel(_k?.gsm1), style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: PT.koyu)),
            ]),
          ],
        ]),
      ),
    ]);
  }

  Widget _istatistik() {
    Widget kutu(IconData ikon, String deger, String etiket, VoidCallback? onTap) => Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(ikon, color: PT.mor, size: 24),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(deger, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: PT.koyu)),
                    ),
                    Text(etiket, maxLines: 2, style: const TextStyle(fontSize: 11.5, height: 1.2, color: PT.gri)),
                  ]),
                ),
              ]),
            ),
          ),
        );
    Widget ayrac() => Container(width: 1, height: 40, color: PT.cizgi);
    final puan = _o['ortalama_puan'];
    return PTKart(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
      child: Row(children: [
        kutu(Icons.calendar_month_rounded, _yukleniyor ? '…' : '${_o['bugun_randevu'] ?? 0}', 'Bugünkü\nRandevu', null),
        ayrac(),
        kutu(Icons.groups_rounded, _yukleniyor ? '…' : binlik((_o['toplam_musteri'] ?? 0) as num),
            _yonetici ? 'Toplam\nMüşteri' : 'Müşterim', null),
        ayrac(),
        kutu(Icons.star_rounded, _yukleniyor ? '…' : (puan == null ? '—' : puan.toString().replaceAll('.', ',')), 'Ortalama\nPuan',
            () => _ac(YorumlarSayfasi(sube: _sube, yonetici: _yonetici))),
      ]),
    );
  }

  Widget _siradaki() {
    final s = _o['siradaki'];
    if (_yukleniyor) return const SizedBox.shrink();
    if (s is! Map) {
      return PTKart(
        child: Row(children: [
          PTIkon(Icons.event_available_rounded),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Önümüzdeki 7 günde bekleyen randevu yok.',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: PT.gri)),
          ),
        ]),
      );
    }
    final dk = (s['dakika'] ?? 0) as int;
    String kalan;
    if (s['bugun'] != true) {
      kalan = trTarih(s['tarih']?.toString());
    } else if (dk < 1) {
      kalan = 'Şimdi';
    } else if (dk < 60) {
      kalan = '$dk dk sonra';
    } else if (dk < 180) {
      kalan = '${dk ~/ 60} sa ${dk % 60} dk';
    } else {
      kalan = 'Bugün';
    }
    final alt = [s['hizmet'], if (_yonetici && (s['personel'] ?? '').toString().isNotEmpty) s['personel']]
        .where((e) => e != null && e.toString().isNotEmpty)
        .join(' · ');
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF6A1FD0), Color(0xFF8E4DEB)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: PT.mor.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
      child: Row(children: [
        Column(children: [
          Text(s['saat']?.toString() ?? '', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)),
          const Text('Sıradaki', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xD9FFFFFF))),
        ]),
        Container(width: 1, height: 42, margin: const EdgeInsets.symmetric(horizontal: 14), color: Colors.white24),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s['musteri']?.toString() ?? '',
                maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            if (alt.isNotEmpty)
              Text(alt, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: Color(0xE6FFFFFF))),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
          child: Text(kalan, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white)),
        ),
      ]),
    );
  }

  List<Widget> _satirlar() {
    final rol = widget.kullanicirolu;
    final buAy = _o['bu_ay'] is Map ? _o['bu_ay'] as Map : const {};
    final hedef = _o['hedef'] is Map ? _o['hedef'] as Map : null;
    String? performansRozet;
    if (_kazancGorunur && buAy['kazanc'] != null) {
      performansRozet = tl(buAy['kazanc'] as num);
    } else if (_yonetici && buAy['ciro'] != null) {
      performansRozet = tl(buAy['ciro'] as num);
    } else if (hedef != null) {
      performansRozet = '%${hedef['yuzde']}';
    }
    final izinBekleyen = (_o['izin_bekleyen'] ?? 0) as int;
    final onayBekleyen = (_o['izin_onay_bekleyen'] ?? 0) as int;
    final personelAdi = (_k?.name ?? '') == 'null' ? '' : (_k?.name ?? '');
    final pid = (_o['personel_id'] ?? '').toString();
    return [
      PTSatir(
          ikon: Icons.badge_rounded,
          baslik: 'Bilgilerimi Düzenle',
          alt: 'Ad, unvan, telefon ve e-posta bilgileriniz',
          onTap: () async {
            if (_k == null) return;
            await _ac(ProfilBilgileri(kullanici: _k!, mod: 'bilgi'));
          }),
      if (rol == 1)
        PTSatir(
            ikon: Icons.notifications_rounded,
            baslik: 'Bildirim Ayarları',
            alt: 'SMS, WhatsApp ve uygulama bildirim tercihlerini yönetin',
            onTap: () => _ac(BildirimAyarlariPage(salonId: _sube)))
      else
        PTSatir(
            ikon: Icons.notifications_rounded,
            baslik: 'Bildirimlerim',
            alt: 'Hangi bildirimlerin sesli geleceğini seçin',
            onTap: () => _ac(BildirimlerimPage(salonId: _sube))),
      PTSatir(
          ikon: Icons.lock_rounded,
          baslik: 'Şifre Değiştir',
          alt: 'Hesap güvenliğiniz için şifrenizi güncelleyin',
          onTap: () async {
            if (_k == null) return;
            await _ac(ProfilBilgileri(kullanici: _k!, mod: 'sifre'));
          }),
      PTSatir(
          ikon: Icons.edit_calendar_rounded,
          baslik: 'Çalışma Saatlerim',
          alt: 'Haftalık mesai planınız ve yaklaşan izinleriniz',
          onTap: () => _ac(CalismaSaatleriSayfasi(sube: _sube))),
      PTSatir(
          ikon: Icons.beach_access_rounded,
          baslik: 'İzinlerim',
          alt: 'İzin isteyin, taleplerinizin durumunu görün',
          rozet: izinBekleyen > 0 ? '$izinBekleyen bekliyor' : null,
          onTap: () => _ac(IzinlerSayfasi(sube: _sube))),
      PTSatir(
          ikon: Icons.star_rounded,
          baslik: 'Performansım',
          alt: _kazancGorunur ? 'Bu ayki kazancınız, satışlarınız ve hedefiniz' : 'Bu ayki satışlar ve hedef',
          rozet: performansRozet,
          onTap: () => _ac(PerformansSayfasi(
                sube: _sube,
                ozet: _o,
                kazancGorunur: _kazancGorunur,
                isletmebilgi: widget.isletmebilgi,
                personelId: pid,
                personelAdi: personelAdi,
              ))),
      PTSatir(
          ikon: Icons.reviews_rounded,
          baslik: 'Müşteri Yorumlarım',
          alt: 'Size yapılan değerlendirmeler',
          rozet: (_o['puan_sayisi'] ?? 0) > 0 ? '${_o['puan_sayisi']}' : null,
          onTap: () => _ac(YorumlarSayfasi(sube: _sube, yonetici: _yonetici))),
      PTSatir(
          ikon: Icons.content_cut_rounded,
          baslik: 'Hizmetlerim',
          alt: 'Verdiğiniz hizmetler ve fiyatları',
          rozet: (_o['hizmet_sayisi'] ?? 0) > 0 ? '${_o['hizmet_sayisi']}' : null,
          onTap: () => _ac(HizmetlerSayfasi(sube: _sube))),
      PTSatir(
          ikon: Icons.photo_library_rounded,
          baslik: 'Çalışmalarım',
          alt: 'Yaptığınız işlerin fotoğrafları',
          rozet: (_o['calisma_sayisi'] ?? 0) > 0 ? '${_o['calisma_sayisi']}' : null,
          onTap: () => _ac(CalismalarSayfasi(sube: _sube))),
      if (_yonetici)
        PTSatir(
            ikon: Icons.groups_2_rounded,
            baslik: 'Ekibim',
            alt: 'Durumlar, aylık hedefler ve izin onayları',
            rozet: onayBekleyen > 0 ? '$onayBekleyen onay' : null,
            rozetRenk: onayBekleyen > 0 ? const Color(0xFFEA580C) : null,
            onTap: () => _ac(EkipSayfasi(sube: _sube))),
      if (rol != 1)
        PTSatir(
            ikon: Icons.manage_accounts_rounded,
            baslik: 'Yetkilerim',
            alt: 'Erişim yetkileriniz ve modüller',
            onTap: () => _ac(YetkilerSayfasi(sube: _sube))),
      PTSatir(
          ikon: Icons.devices_rounded,
          baslik: 'Cihazlarım',
          alt: 'Hesabınızın açık olduğu cihazlar',
          rozet: (_o['cihaz_sayisi'] ?? 0) > 0 ? '${_o['cihaz_sayisi']}' : null,
          onTap: () => _ac(CihazlarSayfasi(sube: _sube))),
      PTSatir(
          ikon: Icons.headset_mic_rounded,
          baslik: 'Yardım & Destek',
          alt: 'Sorularınız için bize ulaşın',
          onTap: () => _ac(const DestekSayfasi())),
      PTSatir(
          ikon: Icons.info_rounded,
          baslik: 'Uygulama Hakkında',
          alt: 'Sürüm bilgisi ve kullanım koşulları',
          rozet: HakkindaSayfasi.surum.isEmpty ? null : 'v${HakkindaSayfasi.surum}',
          onTap: () => _ac(const HakkindaSayfasi())),
    ];
  }

  Widget _cikis() => Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
          color: PT.lila.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white),
        ),
        child: Row(children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.7), shape: BoxShape.circle),
            child: const Icon(Icons.logout_rounded, color: PT.mor, size: 25),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('Oturumu Kapat', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: PT.koyu)),
              ),
              SizedBox(height: 2),
              Text('Güvenli çıkış', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: PT.gri)),
            ]),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: PT.mor,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: widget.onCikis,
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('Çıkış Yap', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
          ),
        ]),
      );
}

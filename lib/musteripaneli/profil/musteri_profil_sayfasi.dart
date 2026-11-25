import 'dart:convert';
import 'dart:io';

import 'package:randevu_sistem/dil/material.dart';
import 'package:randevu_sistem/dil/dil.dart';
import 'package:randevu_sistem/dil/dil_secici.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:randevu_sistem/Backend/backend.dart' show dashboardGunlukRaporMusteri;
import 'package:randevu_sistem/Backend/yetki.dart';
import 'package:randevu_sistem/Frontend/cropimage.dart';
import 'package:randevu_sistem/Frontend/indexedstack.dart';
import 'package:randevu_sistem/Login Sayfası/tanitim.dart';
import 'package:randevu_sistem/Models/musteri_danisanlar.dart';
import 'package:randevu_sistem/Models/musteridashboard.dart';
import 'package:randevu_sistem/musteripaneli/anasayfa/hesapkaldirma.dart';
import 'package:randevu_sistem/musteripaneli/anasayfa/musteribildirimleri/musteribildirimleri.dart';
import 'package:randevu_sistem/musteripaneli/anasayfa/musteriprofilbilgileri.dart';
import 'package:randevu_sistem/musteripaneli/anasayfa/puan_odullerim.dart';
import 'package:randevu_sistem/musteripaneli/musteri_alt_menu.dart';
import 'package:randevu_sistem/musteripaneli/randevularim/randevularim.dart';
import 'package:randevu_sistem/services/notification_service.dart';
import 'package:randevu_sistem/theme/musteri_palet.dart';
import 'package:randevu_sistem/yonetici/profil/profil_api.dart';

import 'musteri_profil_sayfalar.dart';
import 'musteri_profil_tema.dart';

/// Müşteri profili: işletme/personel profiliyle (ProfilSayfasi) aynı tasarım, müşteriye göre içerik.
class MusteriProfilSayfasi extends StatefulWidget {
  final MusteriDanisan md;
  final dynamic isletmebilgi;
  const MusteriProfilSayfasi({super.key, required this.md, required this.isletmebilgi});

  @override
  State<MusteriProfilSayfasi> createState() => _MusteriProfilSayfasiState();
}

class _MusteriProfilSayfasiState extends State<MusteriProfilSayfasi> {
  late String _ad = _temiz(widget.md.name);
  late String _telefon = _temiz(widget.md.cep_telefon);
  late String _resim = _temiz(widget.md.profil_resim);
  Map<String, dynamic> _o = {};
  MusteriOzet? _ozet;
  bool _yukleniyor = true;
  bool _resimYukleniyor = false;
  String _surum = '';

  String get _sube => widget.isletmebilgi is Map ? widget.isletmebilgi['id'].toString() : '';
  bool get _studyo => widget.isletmebilgi is Map && widget.isletmebilgi['studyo_modu']?.toString() == '1';

  static String _temiz(dynamic v) {
    final s = (v ?? '').toString().trim();
    return s == 'null' ? '' : s;
  }

  @override
  void initState() {
    super.initState();
    _musteriOku();
    _yukle();
    PackageInfo.fromPlatform().then((p) {
      if (mounted) setState(() => _surum = p.version);
    }).catchError((_) {});
  }

  /// Bilgilerini düzenleyince cihazdaki kayıt güncellenir; ekran oradan okur
  Future<void> _musteriOku() async {
    final s = (await SharedPreferences.getInstance()).getString('musteri');
    if (s == null || !mounted) return;
    final m = jsonDecode(s);
    if (m is! Map || m['id'].toString() != widget.md.id.toString()) return;
    setState(() {
      if (_temiz(m['name']).isNotEmpty) _ad = _temiz(m['name']);
      if (_temiz(m['cep_telefon']).isNotEmpty) _telefon = _temiz(m['cep_telefon']);
      if (m.containsKey('profil_resim')) _resim = _temiz(m['profil_resim']);
    });
  }

  Future<void> _yukle() async {
    final sonuc = await Future.wait<dynamic>([
      ProfilApi.get('/musteri-profil/ozet', _sube),
      dashboardGunlukRaporMusteri().then<MusteriOzet?>((v) => v).catchError((_) => null),
    ]);
    if (!mounted) return;
    setState(() {
      _yukleniyor = false;
      final r = sonuc[0] as Map<String, dynamic>;
      if (ProfilApi.ok(r)) _o = r;
      if (sonuc[1] != null) _ozet = sonuc[1] as MusteriOzet;
    });
    if (_ozet != null) musteriOkunmamisBildirim.value = int.tryParse(_ozet!.okunmamisbildirimler) ?? 0;
  }

  Future<void> _ac(Widget sayfa) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => sayfa));
    if (!mounted) return;
    await _musteriOku();
    _yukle();
  }

  // ─────────────────────────────── foto

  Future<void> _resimSec() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (x == null || !mounted) return;
    final kirpik = await Navigator.push<File>(context, MaterialPageRoute(builder: (_) => CropScreen(imageFile: File(x.path))));
    if (kirpik == null || !mounted) return;
    setState(() => _resimYukleniyor = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final m = jsonDecode(prefs.getString('musteri')!);
      final req = http.MultipartRequest('POST', Uri.parse('https://app.randevumcepte.com.tr/api/v1/musteriprofilresimyukle'));
      req.fields['yetkili_id'] = m['id'].toString();
      req.fields['sube'] = _sube;
      final t = await ProfilApi.token();
      if (t != null) req.headers['Authorization'] = 'Bearer $t';
      req.files.add(await http.MultipartFile.fromPath('folderPath', kirpik.path));
      final res = await http.Response.fromStream(await req.send());
      if (res.statusCode != 200) throw Exception('${res.statusCode}');
      m['profil_resim'] = jsonDecode(res.body)['profilresmi'] ?? '';
      await prefs.setString('musteri', jsonEncode(m));
      await _musteriOku();
      if (mounted) mpMesaj(context, 'Profil fotoğrafınız güncellendi.');
    } catch (_) {
      if (mounted) mpMesaj(context, 'Fotoğraf yüklenemedi.', hata: true);
    }
    if (mounted) setState(() => _resimYukleniyor = false);
  }

  // ─────────────────────────────── çizim

  @override
  Widget build(BuildContext context) {
    final p = MusteriPalet.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: p.koyuMod ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: p.zemin,
        body: Stack(children: [
          const MPZemin(),
          SafeArea(
            child: RefreshIndicator(
              color: p.ana,
              onRefresh: () async {
                await _musteriOku();
                await _yukle();
              },
              child: ListView(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
                children: [
                  _ustBar(),
                  const SizedBox(height: 10),
                  _baslik(p),
                  const SizedBox(height: 18),
                  _istatistik(p),
                  const SizedBox(height: 12),
                  _siradaki(p),
                  const SizedBox(height: 12),
                  ..._satirlar(),
                  const SizedBox(height: 14),
                  _cikis(p),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }

  int get _okunmamis => int.tryParse(_ozet?.okunmamisbildirimler ?? '') ?? 0;

  void _bildirimler() => _ac(MusteriBildirimlerScreen(md: widget.md, isletmebilgi: widget.isletmebilgi));

  void _randevularim() => _ac(MusteriRandevulari(md: widget.md, isletmebilgi: widget.isletmebilgi, geriButonu: true));

  Widget _ustBar() => Row(children: [
        MPDaireDugme(ikon: Icons.arrow_back_rounded, etiket: 'Geri', onTap: () => Navigator.pop(context)),
        const Spacer(),
        Stack(clipBehavior: Clip.none, children: [
          MPDaireDugme(ikon: Icons.notifications_none_rounded, etiket: 'Bildirimler', onTap: _bildirimler),
          if (_okunmamis > 0)
            Positioned(
              right: -2,
              top: -4,
              child: Container(
                constraints: const BoxConstraints(minWidth: 20),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                    color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white, width: 2)),
                child: Text(_okunmamis > 99 ? '99+' : '$_okunmamis',
                    textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ),
        ]),
      ]);

  String _telYaz(String raw) {
    final d = raw.replaceAll(RegExp(r'\D'), '');
    if (d.isEmpty) return '';
    final o = d.startsWith('0') ? d : '0$d';
    if (o.length != 11) return o;
    return '${o.substring(0, 4)} ${o.substring(4, 7)} ${o.substring(7, 9)} ${o.substring(9)}';
  }

  /// Yeni müşteriye "Pasif" yazılmaz
  String get _uyelik {
    final o = _ozet;
    if (o == null) return '';
    return o.kategori == 'pasif' ? 'Müşteri' : o.kategoriLabel;
  }

  Widget _baslik(MusteriPalet p) {
    final tel = _telYaz(_telefon);
    return Row(children: [
      Stack(clipBehavior: Clip.none, children: [
        Container(
          width: 124,
          height: 124,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(color: p.koyuMod ? p.kart : Colors.white, shape: BoxShape.circle, boxShadow: [
            BoxShadow(color: p.ana.withValues(alpha: 0.16), blurRadius: 22, offset: const Offset(0, 10)),
          ]),
          child: CircleAvatar(
            backgroundColor: p.yumusak,
            backgroundImage: _resim.isEmpty ? null : NetworkImage('https://app.randevumcepte.com.tr/${_resim.replaceFirst(RegExp(r'^/+'), '')}'),
            child: _resimYukleniyor
                ? CircularProgressIndicator(color: p.ana, strokeWidth: 2.5)
                : _resim.isEmpty
                    ? Text(_ad.isNotEmpty ? _ad[0].toUpperCase() : '?',
                        style: TextStyle(fontSize: 44, fontWeight: FontWeight.w800, color: p.ana))
                    : null,
          ),
        ),
        Positioned(
          right: 2,
          bottom: 4,
          child: Semantics(
            button: true,
            label: 'Fotoğrafı değiştir',
            child: GestureDetector(
              onTap: _resimYukleniyor ? null : _resimSec,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(color: p.kart, shape: BoxShape.circle, boxShadow: [
                  BoxShadow(color: p.ana.withValues(alpha: 0.22), blurRadius: 10, offset: const Offset(0, 4)),
                ]),
                child: Icon(Icons.photo_camera_rounded, color: p.ana, size: 20),
              ),
            ),
          ),
        ),
      ]),
      const SizedBox(width: 16),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_ad.isEmpty ? '—' : _ad,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: p.baslik, letterSpacing: -0.4, height: 1.15)),
          if (_uyelik.isNotEmpty) ...[
            const SizedBox(height: 7),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: p.yumusak, borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(_ozet?.kategori == 'sadik' ? Icons.workspace_premium_rounded : Icons.person_rounded, size: 15, color: p.ana),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(_uyelik,
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: p.ana)),
                ),
              ]),
            ),
          ],
          if (tel.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.phone_rounded, size: 16, color: p.baslik),
              const SizedBox(width: 6),
              Text(tel, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: p.baslik)),
            ]),
          ],
        ]),
      ),
    ]);
  }

  Widget _istatistik(MusteriPalet p) {
    Widget kutu(IconData ikon, num? deger, String etiket, VoidCallback onTap) => Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(ikon, color: p.ana, size: 24),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(_yukleniyor ? '…' : (deger == null ? '—' : binlik(deger)),
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: p.baslik)),
                    ),
                    Text(etiket, maxLines: 2, style: TextStyle(fontSize: 11.5, height: 1.2, color: p.metin)),
                  ]),
                ),
              ]),
            ),
          ),
        );
    Widget ayrac() => Container(width: 1, height: 40, color: p.kartKenar);
    return MPKart(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
      child: Row(children: [
        kutu(Icons.calendar_month_rounded, _o['yaklasan'] as num?, 'Yaklaşan\nRandevu', _randevularim),
        ayrac(),
        kutu(Icons.check_circle_rounded, _o['ziyaret'] as num?, 'Toplam\nZiyaret', _randevularim),
        ayrac(),
        if (_studyo)
          kutu(Icons.notifications_rounded, _ozet == null ? null : _okunmamis, 'Yeni\nBildirim', _bildirimler)
        else
          kutu(Icons.star_rounded, _ozet?.sadakatPuani, 'Sadakat\nPuanı', () => _ac(PuanOdullerimPage(md: widget.md, salonId: _sube))),
      ]),
    );
  }

  Widget _siradaki(MusteriPalet p) {
    final s = _o['siradaki'];
    if (_yukleniyor || _o.isEmpty) return const SizedBox.shrink();
    if (s is! Map) {
      return MPKart(
        onTap: _randevularim,
        child: Row(children: [
          const MPIkon(Icons.event_available_rounded),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Yaklaşan randevunuz yok.', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: p.metin)),
          ),
        ]),
      );
    }
    final dk = (s['dakika'] as num? ?? 0).toInt();
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
    final hizmet = (s['hizmet'] ?? '').toString();
    final alt = [(s['sube'] ?? '').toString(), s['onayli'] == true ? 'Onaylandı' : 'Onay bekliyor'].where((e) => e.isNotEmpty).join(' · ');
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: p.dugme, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: p.dugmeAna.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: _randevularim,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
            child: Row(children: [
              Column(children: [
                Text(s['saat']?.toString() ?? '',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)),
                const Text('Randevunuz', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xD9FFFFFF))),
              ]),
              Container(width: 1, height: 42, margin: const EdgeInsets.symmetric(horizontal: 14), color: Colors.white24),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(hizmet.isEmpty ? 'Randevu' : hizmet,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15.5, height: 1.2, fontWeight: FontWeight.w700, color: Colors.white)),
                  Text(alt, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: Color(0xE6FFFFFF))),
                ]),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                child: Text(kalan, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  /// Yalnız hesap işlemleri; Menü ve alt menüdeki sayfalar burada tekrarlanmaz
  List<Widget> _satirlar() {
    final md = widget.md;
    String? sayi(dynamic v) => v is num && v > 0 ? binlik(v) : null;
    return [
      MPSatir(
          ikon: Icons.badge_rounded,
          baslik: 'Bilgilerimi Düzenle',
          alt: 'Ad, telefon, e-posta ve meslek bilgileriniz',
          onTap: () => _ac(MusteriProfilBilgileri(kullanici: md, mod: 'bilgi'))),
      MPSatir(
          ikon: Icons.lock_rounded,
          baslik: 'Şifre Değiştir',
          alt: 'Hesap güvenliğiniz için şifrenizi güncelleyin',
          onTap: () => _ac(MusteriProfilBilgileri(kullanici: md, mod: 'sifre'))),
      if (Dil.acik)
        MPSatir(
            ikon: Icons.language_rounded,
            baslik: Dil.kod == 'tr' ? 'Dil / Language' : '${Dil.cevir('Dil')} / Language',
            alt: 'Uygulama ve mesajlarınızın dili',
            rozet: Dil.secili == null ? null : '${Dil.secili!.bayrak} ${Dil.secili!.ad}',
            onTap: () async {
              await dilSeciciAc(context, renk: MusteriPalet.of(context).ana);
              if (mounted) setState(() {});
            }),
      MPSatir(
          ikon: Icons.devices_rounded,
          baslik: 'Cihazlarım',
          alt: 'Hesabınızın açık olduğu cihazlar',
          rozet: sayi(_o['cihaz']),
          onTap: () => _ac(MusteriCihazlarSayfasi(sube: _sube))),
      MPSatir(
          ikon: Icons.info_rounded,
          baslik: 'Uygulama Hakkında',
          alt: 'Kullanım koşulları ve KVKK',
          rozet: _surum.isEmpty ? null : 'v$_surum',
          onTap: () => _ac(MusteriHakkindaSayfasi(sube: _sube))),
      MPSatir(
          ikon: Icons.delete_outline_rounded,
          renk: musteriProfilKirmizi,
          baslik: 'Hesabımı Sil',
          alt: 'Hesabınızı kalıcı olarak kaldırın',
          onTap: () => _ac(HesapKaldirma(kullanici: md))),
    ];
  }

  /// Tek eylem: kartın tamamına dokununca çıkış
  Widget _cikis(MusteriPalet p) => Material(
        color: p.yumusak.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => musteriGuvenliCikis(context),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: p.koyuMod ? p.kartKenar : Colors.white)),
            child: Row(children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(color: p.kart.withValues(alpha: p.koyuMod ? 1 : 0.75), shape: BoxShape.circle),
                child: Icon(Icons.logout_rounded, color: p.ana, size: 25),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Güvenli Çıkış', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: p.baslik)),
                  const SizedBox(height: 2),
                  Text('Oturumunuzu kapatır', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: p.metin)),
                ]),
              ),
              Icon(Icons.chevron_right_rounded, color: p.ana, size: 28),
            ]),
          ),
        ),
      );
}

/// Onay sorar, cihaz kaydını ve oturumu kapatıp giriş ekranına döner (Menü ve Profil ortak)
Future<void> musteriGuvenliCikis(BuildContext context) async {
  final renk = Theme.of(context).colorScheme.primary;
  final evet = await showDialog<bool>(
    context: context,
    builder: (d) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Çıkış Yap', style: TextStyle(fontWeight: FontWeight.w600)),
      content: const Text('Çıkış yapmak istediğinize emin misiniz?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(d, false), child: Text('Hayır', style: TextStyle(color: renk))),
        FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('Evet')),
      ],
    ),
  );
  if (evet != true || !context.mounted) return;
  final sekme = Provider.of<IndexedStackState>(context, listen: false);
  final nav = Navigator.of(context);
  try {
    await NotificationService.instance.unregister();
  } catch (_) {
    // cihaz kaydı silinemese de çıkış yapılır
  }
  sekme.setSelectedIndex(0);
  sekme.resetSelectedIndex();
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('musteri');
  await prefs.remove('user_type');
  await prefs.remove('token');
  await Yetki.temizle();
  nav.pushAndRemoveUntil(
    PageTransition(type: PageTransitionType.fade, duration: const Duration(milliseconds: 300), child: OnBoardingPage()),
    (route) => false,
  );
}

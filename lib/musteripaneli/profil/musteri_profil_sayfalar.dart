import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:randevu_sistem/services/notification_service.dart';
import 'package:randevu_sistem/theme/musteri_palet.dart';
import 'package:randevu_sistem/yonetici/profil/profil_api.dart';

import 'musteri_profil_tema.dart';

/// Ortak: yükle → liste çiz → aşağı çekince yenile
abstract class _ListeDurum<T extends StatefulWidget> extends State<T> {
  bool yukleniyor = true;
  String? hata;
  Map<String, dynamic> veri = {};

  Future<Map<String, dynamic>> getir();

  @override
  void initState() {
    super.initState();
    yukle();
  }

  Future<void> yukle() async {
    final r = await getir();
    if (!mounted) return;
    setState(() {
      yukleniyor = false;
      if (ProfilApi.ok(r)) {
        veri = r;
        hata = null;
      } else {
        hata = (r['hata'] ?? 'Yüklenemedi.').toString();
      }
    });
  }

  Widget kaydirma(List<Widget> cocuklar) {
    final p = MusteriPalet.of(context);
    if (yukleniyor) return Center(child: CircularProgressIndicator(color: p.ana));
    return RefreshIndicator(
      color: p.ana,
      onRefresh: yukle,
      child: ListView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
        children: hata != null ? [MPBos(Icons.cloud_off_rounded, hata!)] : cocuklar,
      ),
    );
  }
}

// ═══════════════════════════════════════════════ Cihazlarım

class MusteriCihazlarSayfasi extends StatefulWidget {
  final String sube;
  const MusteriCihazlarSayfasi({super.key, required this.sube});
  @override
  State<MusteriCihazlarSayfasi> createState() => _MusteriCihazlarSayfasiState();
}

class _MusteriCihazlarSayfasiState extends _ListeDurum<MusteriCihazlarSayfasi> {
  @override
  Future<Map<String, dynamic>> getir() async {
    final t = await NotificationService.instance.mevcutToken();
    return ProfilApi.get('/musteri-profil/cihazlar', widget.sube, {'token': t ?? ''});
  }

  Future<void> _kapat(Map c) async {
    final evet = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Bu cihazdan çıkış yap'),
        content: const Text('Bu cihazdaki oturum kapatılır ve cihaz bildirim almayı bırakır.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Vazgeç')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: musteriProfilKirmizi, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(d, true),
              child: const Text('Çıkış yap')),
        ],
      ),
    );
    if (evet != true) return;
    final r = await ProfilApi.post('/musteri-profil/cihaz-kapat', widget.sube, {'id': c['id']});
    if (!mounted) return;
    mpMesaj(context, ProfilApi.ok(r) ? 'Cihazdaki oturum kapatıldı.' : (r['hata'] ?? 'Yapılamadı.').toString(), hata: !ProfilApi.ok(r));
    yukle();
  }

  /// Platforma göre okunur ad; cihaz alanı model adıysa yanına eklenir (kimlik kodları gösterilmez).
  (IconData, String) _tur(Map c) {
    final p = '${c['platform'] ?? ''} ${c['cihaz'] ?? ''}'.toLowerCase();
    final (ikon, tur) = p.contains('web')
        ? (Icons.laptop_mac_rounded, 'Web tarayıcı')
        : (p.contains('ios') || p.contains('iphone') || p.contains('ipad'))
            ? (Icons.phone_iphone_rounded, 'iPhone')
            : (Icons.phone_android_rounded, p.contains('android') ? 'Android telefon' : 'Telefon');
    final cihaz = (c['cihaz'] ?? '').toString().trim();
    final gizle = cihaz.isEmpty || cihaz == 'null' || RegExp(r'^[0-9a-fA-F-]{12,}$').hasMatch(cihaz);
    return (ikon, gizle ? tur : '$tur · $cihaz');
  }

  @override
  Widget build(BuildContext context) {
    final p = MusteriPalet.of(context);
    final l = (veri['cihazlar'] as List? ?? []).cast<Map>();
    return MPAltSayfa(
      baslik: 'Cihazlarım',
      govde: kaydirma([
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text('Hesabınızın açık olduğu ve bildirim alan cihazlar. Tanımadığınız bir cihaz varsa çıkış yaptırın ve şifrenizi değiştirin.',
              style: TextStyle(fontSize: 13, height: 1.35, color: p.metin)),
        ),
        if (l.isEmpty) const MPBos(Icons.devices_rounded, 'Kayıtlı cihaz bulunamadı.'),
        ...l.map((c) {
          final bu = c['bu_cihaz'] == true;
          final son = (c['updated_at'] ?? c['created_at'] ?? '').toString();
          final (ikon, ad) = _tur(c);
          return Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: MPKart(
              child: Row(children: [
                MPIkon(ikon, boyut: 46),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Flexible(
                        child: Text(ad,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: p.baslik)),
                      ),
                      if (bu) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFF16A34A).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                          child: const Text('Bu cihaz', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF16A34A))),
                        ),
                      ],
                    ]),
                    if (son.length >= 10) Text('Son kullanım: ${trTarih(son.substring(0, 10))}', style: TextStyle(fontSize: 12.5, color: p.metin)),
                  ]),
                ),
                if (!bu)
                  TextButton(
                    onPressed: () => _kapat(c),
                    child: const Text('Çıkış yap', style: TextStyle(color: musteriProfilKirmizi, fontWeight: FontWeight.w700)),
                  ),
              ]),
            ),
          );
        }),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════ Uygulama Hakkında + yasal metinler

/// İşletmenin kendi bilgileri + sürüm + uygulama içi yasal metinler
class MusteriHakkindaSayfasi extends StatefulWidget {
  final String sube;
  const MusteriHakkindaSayfasi({super.key, required this.sube});

  @override
  State<MusteriHakkindaSayfasi> createState() => _MusteriHakkindaSayfasiState();
}

class _MusteriHakkindaSayfasiState extends _ListeDurum<MusteriHakkindaSayfasi> {
  String _yapi = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((p) {
      if (mounted) setState(() => _yapi = '${p.version} (${p.buildNumber})');
    }).catchError((_) {});
  }

  @override
  Future<Map<String, dynamic>> getir() => ProfilApi.get('/musteri-profil/hakkinda', widget.sube);

  static const Map<String, IconData> _ikon = {
    'kullanim': Icons.description_rounded,
    'gizlilik': Icons.privacy_tip_rounded,
    'kvkk': Icons.verified_user_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final p = MusteriPalet.of(context);
    final i = veri['isletme'] is Map ? veri['isletme'] as Map : const {};
    final metinler = (veri['metinler'] as List? ?? []).cast<Map>();
    final ad = (i['ad'] ?? '').toString();
    final logo = (i['logo'] ?? '').toString();
    final adres = (i['adres'] ?? '').toString();
    final tel = (i['telefon'] ?? '').toString();
    final yedek = Icon(Icons.storefront_rounded, color: p.ana, size: 40);
    Widget bilgi(IconData ikon, String yazi) => Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(ikon, size: 18, color: p.ana),
            const SizedBox(width: 8),
            Expanded(child: Text(yazi, style: TextStyle(fontSize: 13.5, height: 1.35, color: p.baslik))),
          ]),
        );
    return MPAltSayfa(
      baslik: 'Uygulama Hakkında',
      govde: kaydirma([
        MPKart(
          padding: const EdgeInsets.all(18),
          child: Column(children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(color: p.yumusak, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4), boxShadow: [
                BoxShadow(color: p.ana.withValues(alpha: 0.14), blurRadius: 16, offset: const Offset(0, 6)),
              ]),
              clipBehavior: Clip.antiAlias,
              child: logo.isEmpty ? yedek : Image.network(logo, fit: BoxFit.cover, errorBuilder: (_, __, ___) => yedek),
            ),
            const SizedBox(height: 12),
            Text(ad, textAlign: TextAlign.center, style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: p.baslik, letterSpacing: -0.3)),
            const SizedBox(height: 4),
            Text(_yapi.isEmpty ? '' : 'Sürüm $_yapi', style: TextStyle(fontSize: 13, color: p.metin)),
            if (adres.isNotEmpty || tel.isNotEmpty) ...[
              const SizedBox(height: 12),
              Divider(height: 1, color: p.kartKenar),
              const SizedBox(height: 4),
              if (adres.isNotEmpty) bilgi(Icons.location_on_rounded, adres),
              if (tel.isNotEmpty) bilgi(Icons.call_rounded, tel),
            ],
          ]),
        ),
        const SizedBox(height: 14),
        ...metinler.map((m) => MPSatir(
              ikon: _ikon[m['kod']] ?? Icons.article_rounded,
              baslik: m['baslik'].toString(),
              alt: 'Son güncelleme: ${m['guncelleme'] ?? ''}',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _YasalMetin(metin: m, isletme: ad))),
            )),
      ]),
    );
  }
}

/// Uygulama içi yasal metin okuma sayfası
class _YasalMetin extends StatelessWidget {
  final Map metin;
  final String isletme;
  const _YasalMetin({required this.metin, required this.isletme});

  @override
  Widget build(BuildContext context) {
    final p = MusteriPalet.of(context);
    final bolumler = (metin['bolumler'] as List? ?? []).cast<Map>();
    return MPAltSayfa(
      baslik: metin['baslik'].toString(),
      govde: ListView(padding: const EdgeInsets.fromLTRB(16, 6, 16, 28), children: [
        MPKart(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(isletme, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: p.ana)),
            Text('Son güncelleme: ${metin['guncelleme'] ?? ''}', style: TextStyle(fontSize: 12.5, color: p.metin)),
            for (var n = 0; n < bolumler.length; n++) ...[
              const SizedBox(height: 16),
              Text('${n + 1}. ${bolumler[n]['baslik']}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: p.baslik)),
              const SizedBox(height: 5),
              Text(bolumler[n]['metin'].toString(), style: TextStyle(fontSize: 14, height: 1.55, color: p.metin)),
            ],
          ]),
        ),
      ]),
    );
  }
}

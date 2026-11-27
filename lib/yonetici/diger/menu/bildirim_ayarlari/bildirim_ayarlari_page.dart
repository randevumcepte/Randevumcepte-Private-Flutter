import 'dart:async';
import 'dart:convert';

import 'package:randevu_sistem/dil/material.dart';
import 'package:randevu_sistem/Backend/backend.dart';

/// Ayarlar > Bildirim Yönetim Merkezi (web paneli "Bildirim Yönetim Merkezi" ile aynı).
/// Her bildirim x alıcı (Müşteri / Personel / Yönetici) x kanal (SMS / WhatsApp / Uygulama).
/// Değişiklikler yerelde biriktirilir, "Değişiklikleri Kaydet" ile toplu gönderilir.
/// Uçlar: /api/v1/bildirim-ayarlari/veri + /kaydet (yalnız Hesap Sahibi).
class BildirimAyarlariPage extends StatefulWidget {
  final String salonId;
  const BildirimAyarlariPage({super.key, required this.salonId});

  @override
  State<BildirimAyarlariPage> createState() => _BildirimAyarlariPageState();
}

class _BildirimAyarlariPageState extends State<BildirimAyarlariPage>
    with WidgetsBindingObserver {
  static const Color _mor = Color(0xFF5C008E);
  static const Color _mor2 = Color(0xFF7B2FB8);
  static const Color _yesil = Color(0xFF16A34A);
  static const Color _menekse = Color(0xFF6D28D9);
  static const Color _turuncu = Color(0xFFEA580C);
  static const Color _zemin = Color(0xFFF7F5FB);

  static const List<String> _kanallar = ['sms', 'whatsapp', 'push'];
  static const Map<String, String> _kanalAd = {
    'sms': 'SMS',
    'whatsapp': 'WhatsApp',
    'push': 'Uygulama',
  };
  static const Map<String, Color> _kanalRenk = {
    'sms': _mor,
    'whatsapp': _yesil,
    'push': _menekse,
  };
  static const Map<String, String> _aliciAd = {
    'musteri': 'Müşteri',
    'personel': 'Personel',
    'yonetici': 'Yönetici',
  };

  static const Map<String, (IconData, Color)> _ikon = {
    'randevu_olusturuldu': (Icons.event_available_outlined, Color(0xFF7C3AED)),
    'randevu_guncellendi': (Icons.swap_horiz_rounded, Color(0xFF2563EB)),
    'randevu_onaylandi': (Icons.check_circle_outline, Color(0xFF16A34A)),
    'randevu_reddedildi': (Icons.cancel_outlined, Color(0xFFDC2626)),
    'randevu_iptal': (Icons.block_rounded, Color(0xFFDC2626)),
    'online_randevu_talebi': (Icons.laptop_mac_rounded, Color(0xFF2563EB)),
    'musteri_geldi': (Icons.login_rounded, Color(0xFF0891B2)),
    'hatirlatma_yaklasan': (
      Icons.notifications_active_outlined,
      Color(0xFF7C3AED)
    ),
    'hatirlatma_bir_gun_once': (Icons.schedule_rounded, Color(0xFFF59E0B)),
    'seans_hatirlatma': (Icons.hourglass_bottom_rounded, Color(0xFF7C3AED)),
    'ders_hatirlatma': (Icons.groups_outlined, Color(0xFF0D9488)),
    'ders_katilim_sor': (Icons.help_outline_rounded, Color(0xFF0D9488)),
    'alacak_hatirlatma': (Icons.payments_outlined, Color(0xFF16A34A)),
    'senet_vade': (Icons.description_outlined, Color(0xFFB45309)),
    'tekrar_arama': (Icons.phone_outlined, Color(0xFF2563EB)),
    'musteri_eklendi': (Icons.person_add_alt_1_outlined, Color(0xFF16A34A)),
    'dogum_gunu': (Icons.cake_outlined, Color(0xFFDB2777)),
    'kara_liste': (Icons.person_off_outlined, Color(0xFF475569)),
    'degerlendirme_anketi': (Icons.star_border_rounded, Color(0xFFF59E0B)),
    'kotu_degerlendirme': (Icons.thumb_down_alt_outlined, Color(0xFFDC2626)),
    'musteri_foto': (Icons.image_outlined, Color(0xFF0891B2)),
    'damga_karti': (Icons.confirmation_number_outlined, Color(0xFF7C3AED)),
    'cark_hatirlatma': (Icons.casino_outlined, Color(0xFFDB2777)),
    'seans_kullanim': (Icons.fact_check_outlined, Color(0xFF7C3AED)),
    'para_islemleri': (
      Icons.account_balance_wallet_outlined,
      Color(0xFF16A34A)
    ),
    'dogrulama_kodu': (Icons.key_outlined, Color(0xFF475569)),
    'kvkk_onay': (Icons.shield_outlined, Color(0xFF475569)),
    'silme_onay_kodu': (Icons.lock_outline_rounded, Color(0xFFDC2626)),
    'kampanya_link': (Icons.campaign_outlined, Color(0xFFF59E0B)),
    'wa_asistan_talep': (Icons.chat_outlined, Color(0xFF16A34A)),
    'telefon_asistani': (Icons.headset_mic_outlined, Color(0xFF2563EB)),
  };

  bool _yukleniyor = true;
  bool _kaydediliyor = false;
  String? _hata;

  /// Ekranda düzenlenen veri ve sunucudaki (kayıtlı) hali.
  Map<String, dynamic>? _veri;
  Map<String, dynamic>? _orj;

  /// Web ile anlik esitleme: ekran acikken 15 sn'de bir ve uygulama one gelince sunucudan tazelenir
  /// (yalniz kaydedilmemis degisiklik yokken — kullanicinin yarim isi ezilmesin).
  Timer? _esitleZamanlayici;
  bool _esitleniyor = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _yukle(ilk: true);
    _esitleZamanlayici =
        Timer.periodic(const Duration(seconds: 15), (_) => _sessizEsitle());
  }

  @override
  void dispose() {
    _esitleZamanlayici?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _sessizEsitle();
  }

  Future<void> _sessizEsitle() async {
    if (!mounted ||
        _veri == null ||
        _yukleniyor ||
        _kaydediliyor ||
        _esitleniyor) {
      return;
    }
    if (_bekleyenSayisi > 0) return;
    _esitleniyor = true;
    try {
      final res = await bildirimAyarlariVeri(widget.salonId);
      if (!mounted || !_okMu(res) || res['gruplar'] is! List) return;
      // Bu arada kullanici bir sey degistirdiyse dokunma
      if (_bekleyenSayisi > 0 || _kaydediliyor) return;
      setState(() {
        _veri = _kopya(res);
        _orj = _kopya(res);
      });
    } catch (_) {
      // sessiz: bir sonraki turda tekrar denenir
    } finally {
      _esitleniyor = false;
    }
  }

  // ---------------------------------------------------------------- yardımcılar

  bool _okMu(Map<String, dynamic> res) =>
      res['ok'] == 1 || res['ok'] == true || res['ok'].toString() == '1';

  int _i(dynamic v) {
    if (v == true) return 1;
    if (v == false || v == null) return 0;
    if (v is num) return v != 0 ? 1 : 0;
    final s = v.toString();
    return (s == '1' || s == 'true') ? 1 : 0;
  }

  int _sayi(dynamic v, [int vars = 0]) {
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? vars;
  }

  Map<String, dynamic> _kopya(Map<String, dynamic> m) =>
      Map<String, dynamic>.from(jsonDecode(jsonEncode(m)) as Map);

  List<Map> _gruplar(Map<String, dynamic>? v) => (v?['gruplar'] is List)
      ? (v!['gruplar'] as List).whereType<Map>().toList()
      : <Map>[];

  List<Map> _bildirimler(Map g) => (g['bildirimler'] is List)
      ? (g['bildirimler'] as List).whereType<Map>().toList()
      : <Map>[];

  Map<String, dynamic> get _durum => (_veri?['durum'] is Map)
      ? Map<String, dynamic>.from(_veri!['durum'] as Map)
      : <String, dynamic>{};

  // _orj aramasi her satirda tum listeyi taramasin: kod -> bildirim sozlugu (veri degisince yenilenir)
  Map<String, dynamic>? _orjIndeksKaynak;
  final Map<String, Map> _orjIndeks = {};

  Map? _bildirimBul(Map<String, dynamic>? v, String kod) {
    if (v != null && identical(v, _orj)) {
      if (!identical(_orjIndeksKaynak, v)) {
        _orjIndeks.clear();
        for (final g in _gruplar(v)) {
          for (final b in _bildirimler(g)) {
            _orjIndeks[b["kod"].toString()] = b;
          }
        }
        _orjIndeksKaynak = v;
      }
      return _orjIndeks[kod];
    }
    for (final g in _gruplar(v)) {
      for (final b in _bildirimler(g)) {
        if (b['kod'].toString() == kod) return b;
      }
    }
    return null;
  }

  Map? _alici(Map? b, String alici) {
    final a = b?['alicilar'];
    if (a is! Map) return null;
    final r = a[alici];
    return r is Map ? r : null;
  }

  int _hatirlatmaSaat(Map<String, dynamic>? v) {
    final s = _sayi(v?['hatirlatma_saat'], 2);
    return s.clamp(1, 23);
  }

  /// Kaydedilmemiş anahtar farkları.
  List<Map<String, dynamic>> _farklar() {
    final l = <Map<String, dynamic>>[];
    if (_veri == null) return l;
    for (final g in _gruplar(_veri)) {
      for (final b in _bildirimler(g)) {
        final kod = b['kod'].toString();
        final o = _bildirimBul(_orj, kod);
        for (final a in _aliciAd.keys) {
          final r = _alici(b, a);
          if (r == null) continue;
          final ro = _alici(o, a);
          for (final k in _kanallar) {
            if (_i(r[k]) != _i(ro?[k])) {
              l.add({'kod': kod, 'alici': a, 'kanal': k, 'deger': _i(r[k])});
            }
          }
        }
      }
    }
    return l;
  }

  Map<String, dynamic> _digerFark() {
    final d = <String, dynamic>{};
    if (_veri == null) return d;
    if (_hatirlatmaSaat(_veri) != _hatirlatmaSaat(_orj)) {
      d['hatirlatma_saat'] = _hatirlatmaSaat(_veri);
    }
    if (_i(_veri!['push_once_sms']) != _i(_orj?['push_once_sms'])) {
      d['push_once_sms'] = _i(_veri!['push_once_sms']);
    }
    return d;
  }

  int get _bekleyenSayisi => _farklar().length + _digerFark().length;

  String _binlik(int n) {
    final s = n.abs().toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
      b.write(s[i]);
    }
    return n < 0 ? '-$b' : b.toString();
  }

  void _mesaj(String metin, {bool hata = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(metin),
      backgroundColor: hata ? Colors.red.shade700 : null,
    ));
  }

  // ---------------------------------------------------------------- veri

  Future<void> _yukle({bool ilk = false}) async {
    if (ilk || _veri == null) {
      setState(() {
        _yukleniyor = true;
        _hata = null;
      });
    } else if (_bekleyenSayisi > 0) {
      final tamam = await _onayIste(
        'Kaydedilmemiş değişiklikler var',
        'Yenilerseniz kaydedilmemiş değişiklikleriniz kaybolacak. Devam edilsin mi?',
        'Yenile',
      );
      if (!tamam) return;
    }
    final res = await bildirimAyarlariVeri(widget.salonId);
    if (!mounted) return;
    setState(() {
      _yukleniyor = false;
      if (_okMu(res) && res['gruplar'] is List) {
        _veri = _kopya(res);
        _orj = _kopya(res);
        _hata = null;
      } else if (_veri == null) {
        _hata = (res['hata'] ?? 'Bildirim ayarları yüklenemedi.').toString();
      }
    });
    if (!_okMu(res) && _veri != null) {
      _mesaj((res['hata'] ?? 'Bildirim ayarları yenilenemedi.').toString(),
          hata: true);
    }
  }

  void _cipDegistir(Map b, String alici, String kanal) {
    final r = _alici(b, alici);
    if (r == null || _kaydediliyor) return;
    setState(() => r[kanal] = _i(r[kanal]) == 1 ? 0 : 1);
  }

  void _anaDegistir(Map b, String alici, bool acik) {
    final r = _alici(b, alici);
    if (r == null || _kaydediliyor) return;
    setState(() {
      if (acik) {
        // Önce kaydedilmiş halindeki açık kanalları geri getir; yoksa varsayılan kanal.
        final o = _alici(_bildirimBul(_orj, b['kod'].toString()), alici);
        final geri =
            o != null && (_i(o['sms']) + _i(o['whatsapp']) + _i(o['push'])) > 0;
        if (geri) {
          for (final k in _kanallar) {
            r[k] = _i(o[k]);
          }
        } else if (alici != 'musteri') {
          r['push'] = 1; // personel / yönetici: ücretsiz uygulama bildirimi
        } else if (_i(_durum['wa_bagli']) == 1) {
          r['whatsapp'] = 1;
        } else {
          r['sms'] = 1;
        }
      } else {
        for (final k in _kanallar) {
          r[k] = 0;
        }
      }
    });
  }

  Future<void> _kaydet() async {
    if (_veri == null || _kaydediliyor) return;
    final l = _farklar();
    final d = _digerFark();
    if (l.isEmpty && d.isEmpty) {
      await _basariPenceresi('Ayarlarınız kayıtlı ve güncel.');
      return;
    }
    setState(() => _kaydediliyor = true);
    final res = await bildirimAyarKaydet(widget.salonId, {
      'degisiklikler': jsonEncode(l),
      ...d,
    });
    if (!mounted) return;
    final ok = _okMu(res);
    setState(() {
      _kaydediliyor = false;
      if (ok && res['gruplar'] is List) {
        _veri = _kopya(res);
        _orj = _kopya(res);
      } else if (ok) {
        // Yanıtta tam veri yoksa ekrandaki hali kayıtlı kabul et.
        _orj = _kopya(_veri!);
      }
    });
    if (ok) {
      await _basariPenceresi(
          '${l.length + d.length} değişiklik kaydedildi. Değişiklikler Log Hareketleri\'ne yazıldı.');
    } else {
      _mesaj((res['hata'] ?? 'Ayarlar kaydedilemedi.').toString(), hata: true);
    }
  }

  Future<void> _basariPenceresi(String alt) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFBBF7D0), width: 4),
                ),
                child: const Icon(Icons.check_rounded, color: _yesil, size: 36),
              ),
              const SizedBox(height: 16),
              const Text(
                'Değişiklikleriniz başarıyla kaydedilmiştir',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F1633)),
              ),
              const SizedBox(height: 8),
              Text(alt,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13.5,
                      color: Colors.grey.shade700,
                      height: 1.4)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: _mor,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Tamam',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _onayIste(String baslik, String metin, String evet) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(baslik,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        content: Text(metin),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: _turuncu),
            child: Text(evet),
          ),
        ],
      ),
    );
    return r == true;
  }

  // ---------------------------------------------------------------- arayüz

  @override
  Widget build(BuildContext context) {
    final bekleyen = _veri == null ? 0 : _bekleyenSayisi;
    return PopScope(
      canPop: bekleyen == 0,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final cik = await _onayIste(
          'Kaydedilmemiş değişiklikler var',
          '$bekleyen değişiklik henüz kaydedilmedi. Kaydetmeden çıkılsın mı?',
          'Kaydetmeden Çık',
        );
        if (cik && mounted) Navigator.of(this.context).pop();
      },
      child: Scaffold(
        backgroundColor: _zemin,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          foregroundColor: const Color(0xFF1F1633),
          title: const Text('Bildirim Yönetim Merkezi',
              style: TextStyle(
                  color: Color(0xFF1F1633),
                  fontWeight: FontWeight.w800,
                  fontSize: 18)),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: const Color(0xFFEDE7F6)),
          ),
        ),
        floatingActionButton: _veri == null ? null : _kaydetButonu(bekleyen),
        body: _yukleniyor
            ? const Center(child: CircularProgressIndicator(color: _mor))
            : (_hata != null && _veri == null
                ? _hataKutusu(_hata!)
                : _icerik()),
      ),
    );
  }

  Widget _kaydetButonu(int bekleyen) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: _mor.withValues(alpha: bekleyen > 0 ? 0.40 : 0.22),
            blurRadius: bekleyen > 0 ? 18 : 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: _kaydediliyor ? null : _kaydet,
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: const LinearGradient(colors: [_mor, _mor2]),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_kaydediliyor)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.2, color: Colors.white),
                  )
                else
                  const Icon(Icons.save_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text(_kaydediliyor ? 'Kaydediliyor…' : 'Değişiklikleri Kaydet',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5)),
                if (bekleyen > 0 && !_kaydediliyor) ...[
                  const SizedBox(width: 10),
                  Container(
                    constraints: const BoxConstraints(minWidth: 22),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF97316),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Text('$bekleyen',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _icerik() {
    final cocuklar = <Widget>[
      ..._durumKartlari(),
      const SizedBox(height: 12),
      _kurallarKarti(),
      if (_veri?['gelmeme'] is Map) ...[
        const SizedBox(height: 12),
        _gelmemeKarti(_veri!['gelmeme'] as Map),
      ],
    ];
    for (final g in _gruplar(_veri)) {
      final liste = _bildirimler(g);
      if (liste.isEmpty) continue;
      final ek = g['kod'] == 'guvenlik'
          ? ' · üç kanalda da kapalıysa kod hiç istenmez'
          : '';
      cocuklar.add(Padding(
        padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                  color: _mor, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${(g['ad'] ?? '').toString()}$ek',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF3B2A5C)),
              ),
            ),
          ],
        ),
      ));
      for (final b in liste) {
        cocuklar.add(_bildirimKarti(b));
      }
    }
    cocuklar.add(Padding(
      padding: const EdgeInsets.fromLTRB(4, 14, 4, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline_rounded,
              size: 15, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Bu ayarları yalnızca işletme sahibi değiştirebilir. Kaydedilen her değişiklik, '
              'kimin yaptığıyla birlikte Log Hareketleri\'ne yazılır.',
              style: TextStyle(
                  fontSize: 12, color: Colors.grey.shade600, height: 1.35),
            ),
          ),
        ],
      ),
    ));

    return RefreshIndicator(
      color: _mor,
      onRefresh: _yukle,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 110),
        children: cocuklar,
      ),
    );
  }

  // Golge yok: onlarca kartta bulanik golge kaydirmayi kasar; ince kenarlik yeterli.
  BoxDecoration _kartSusu({Color? kenar}) => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kenar ?? const Color(0xFFE9E2F3)),
      );

  List<Widget> _durumKartlari() {
    final d = _durum;
    final smsHesap = _i(d['sms_hesabi']) == 1;
    final bakiye = d['sms_bakiye'];
    final bakiyeSifir = bakiye != null && _sayi(bakiye) == 0;
    final smsIyi = smsHesap && !bakiyeSifir;
    final smsAlt = !smsHesap
        ? 'SMS hesabı tanımlı değil; SMS gönderilemez.'
        : (bakiyeSifir
            ? 'SMS paketiniz bitti; SMS gönderilemez.'
            : 'SMS bildirimleri gönderilir.');
    final smsKalan =
        !smsHesap ? '0' : (bakiye == null ? '—' : _binlik(_sayi(bakiye)));
    final waBagli = _i(d['wa_bagli']) == 1;

    var toplam = 0;
    for (final g in _gruplar(_veri)) {
      toplam += _bildirimler(g).length;
    }

    final kartlar = [
      _durumKarti(
        ikon: Icons.sms_outlined,
        renk: _mor,
        zemin: const Color(0xFFEFE1FB),
        baslik: smsIyi ? 'SMS Aktif' : 'SMS Kullanılamıyor',
        alt: smsAlt,
        iyi: smsIyi,
        onEk: 'Kalan',
        kalan: smsKalan,
        birim: 'SMS',
      ),
      _durumKarti(
        ikon: Icons.chat_rounded,
        renk: _yesil,
        zemin: const Color(0xFFDCF6E6),
        baslik: waBagli ? 'WhatsApp Bağlı' : 'WhatsApp Bağlı Değil',
        alt: waBagli
            ? 'WhatsApp bildirimleri gönderilir.'
            : 'Bağlayana kadar WhatsApp\'tan mesaj gitmez.',
        iyi: waBagli,
        onEk: 'Kalan',
        kalan: _binlik(_sayi(d['wa_kontor'])),
        birim: 'kontör',
      ),
      _durumKarti(
        ikon: Icons.notifications_none_rounded,
        renk: _menekse,
        zemin: const Color(0xFFE7E0FD),
        baslik: 'Uygulama Bildirimi Aktif',
        alt: 'Uygulama bildirimleri ücretsiz gönderilir.',
        iyi: true,
        onEk: 'Kullanan',
        kalan: _binlik(_sayi(d['uygulama_musteri'])),
        birim: 'müşteri',
      ),
    ];

    return [
      LayoutBuilder(builder: (context, c) {
        final genislik = (c.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (var i = 0; i < kartlar.length; i++)
              SizedBox(
                // Üçüncü kart tam genişlik: 2 sütunlu ızgarada boşluk kalmasın.
                width: i == 2 ? c.maxWidth : genislik,
                child: kartlar[i],
              ),
          ],
        );
      }),
      const SizedBox(height: 10),
      Row(
        children: [
          _miniSayi('$toplam', 'Bildirim türü', const Color(0xFFEFE1FB), _mor),
          const SizedBox(width: 8),
          _miniSayi(
              '3', 'Kanal', const Color(0xFFDBEAFE), const Color(0xFF1D4ED8)),
          const SizedBox(width: 8),
          _miniSayi('${_sayi(d['personel_sayisi'])}', 'Personel',
              const Color(0xFFFFEDD5), const Color(0xFFC2410C)),
        ],
      ),
    ];
  }

  Widget _durumKarti({
    required IconData ikon,
    required Color renk,
    required Color zemin,
    required String baslik,
    required String alt,
    required bool iyi,
    required String onEk,
    required String kalan,
    required String birim,
  }) {
    final vurgu = iyi ? renk : _turuncu;
    final acik = iyi ? zemin : const Color(0xFFFFEDD5);
    // Not: renkleri farkli kenarlar + borderRadius Flutter'da cizilemez (assert -> icerik cizilmez).
    // Sol renk seridi bu yuzden kenarlik degil, kirpilmis kart icinde ayri bir parca.
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [acik, acik, Colors.white],
            stops: const [0, 0.45, 1],
          ),
          border: Border.all(color: acik),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: vurgu),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                    color: const Color(0xFF1F1633)
                                        .withValues(alpha: 0.06),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2)),
                              ],
                            ),
                            child: Icon(ikon, color: renk, size: 19),
                          ),
                          const Spacer(),
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: iyi
                                  ? const Color(0xFFDCFCE7)
                                  : const Color(0xFFFED7AA),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                                iyi
                                    ? Icons.check_rounded
                                    : Icons.priority_high_rounded,
                                size: 13,
                                color: iyi ? _yesil : _turuncu),
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      Text(baslik,
                          style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: vurgu)),
                      const SizedBox(height: 2),
                      Text(alt,
                          style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.grey.shade700,
                              height: 1.3)),
                      const SizedBox(height: 7),
                      Text.rich(
                        TextSpan(
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade700),
                          children: [
                            TextSpan(text: '$onEk '),
                            TextSpan(
                              text: kalan,
                              style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  color: renk),
                            ),
                            TextSpan(text: ' $birim'),
                          ],
                        ),
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
  }

  Widget _miniSayi(String sayi, String etiket, Color zemin, Color renk) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
            color: zemin, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Text(sayi,
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800, color: renk)),
            const SizedBox(height: 1),
            Text(etiket,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 11.5, fontWeight: FontWeight.w700, color: renk)),
          ],
        ),
      ),
    );
  }

  // WhatsApp -> SMS yedegi sistemde kalici acik: isletme degistiremez, yalniz bilgi olarak gosterilir.
  Widget _kurallarKarti() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: _kartSusu(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: _mor, size: 18),
              SizedBox(width: 8),
              Text('Akıllı Bildirim Kuralları',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1F1633))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 1, right: 10),
                child:
                    Icon(Icons.check_circle_rounded, color: _yesil, size: 22),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('WhatsApp başarısız olursa SMS gönder',
                        style: TextStyle(
                            fontSize: 13.5, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                          color: const Color(0xFFDCF6E6),
                          borderRadius: BorderRadius.circular(20)),
                      child: const Text('Sistem kuralı · her zaman açık',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF15803D))),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'WhatsApp bağlı değilse veya mesaj iletilemezse aynı mesaj SMS ile gider. '
                      'SMS paketiniz yoksa SMS de gitmez.',
                      style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.grey.shade600,
                          height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 1, right: 10),
                child: Icon(Icons.phone_iphone_rounded, color: _mor, size: 22),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Expanded(
                        child: Text('Önce uygulama bildirimi, açılmazsa SMS',
                            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                      ),
                      if (_i(_veri?['push_once_sms']) != _i(_orj?['push_once_sms'])) _degistiNoktasi(),
                      Switch(
                        value: _i(_veri?['push_once_sms']) == 1,
                        activeColor: _mor,
                        onChanged: (v) => setState(() => _veri!['push_once_sms'] = v ? 1 : 0),
                      ),
                    ]),
                    Text(
                      'Randevu hatırlatmasında: müşterinin telefonunda uygulamanın yeni sürümü varsa önce '
                      'bildirim gider. Müşteri 30 dakika içinde bildirimi açmaz ya da "Geliyorum" demezse '
                      'SMS gönderilir. Açarsa SMS gitmez, kontörünüz harcanmaz.',
                      style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.layers_outlined, color: _mor, size: 17),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Birden fazla kanal açıksa hepsinden gider. Örneğin SMS ve WhatsApp ikisi de '
                  'açıksa müşteri iki mesaj alır.',
                  style: TextStyle(
                      fontSize: 11.5, color: Colors.grey.shade700, height: 1.3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// "2026-11" -> "Kas 2026"
  String _ayAdi(dynamic ay) {
    const adlar = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
    final p = ay.toString().split('-');
    final m = p.length == 2 ? int.tryParse(p[1]) : null;
    return (m == null || m < 1 || m > 12) ? ay.toString() : '${adlar[m - 1]} ${p[0]}';
  }

  /// Son 90 gün: randevuya gelmeme oranı ve "Geliyorum" diyenlerde oran.
  Widget _gelmemeKarti(Map g) {
    String yuzde(dynamic v) => v == null ? '—' : '%' + v.toString().replaceAll('.', ',');
    final isaretli = _sayi(g['geldi']) + _sayi(g['gelmedi']);
    final aylik = (g['aylik'] is List) ? (g['aylik'] as List).whereType<Map>().toList() : <Map>[];
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: _kartSusu(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.insights_rounded, color: _mor, size: 18),
          SizedBox(width: 8),
          Text('Randevuya Gelmeme (son 90 gün)',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1F1633))),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          _miniSayi(yuzde(g['oran']), 'Gelmeme oranı', const Color(0xFFFDECEC), const Color(0xFFB91C1C)),
          const SizedBox(width: 8),
          _miniSayi(_binlik(_sayi(g['gelmedi'])), 'Gelmedi', const Color(0xFFF4F1FA), const Color(0xFF3B2A5C)),
          const SizedBox(width: 8),
          _miniSayi(_binlik(_sayi(g['geldi'])), 'Geldi', const Color(0xFFDCF6E6), const Color(0xFF15803D)),
        ]),
        const SizedBox(height: 8),
        Text(
          isaretli == 0
              ? 'Henüz "Geldi / Gelmedi" işaretlenmiş randevu yok. Oran, randevular işaretlendikçe oluşur.'
              : 'Oran, "Geldi" ya da "Gelmedi" işaretlenmiş onaylı randevulardan hesaplanır. '
                  '${_binlik(_sayi(g['isaretsiz']))} randevu işaretlenmemiş.',
          style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600, height: 1.3),
        ),
        if (_sayi(g['yanitli']) > 0) ...[
          const SizedBox(height: 6),
          Text(
            'Hatırlatmaya "Geliyorum" diyen ${_binlik(_sayi(g['yanitli']))} müşteride gelmeme oranı: ${yuzde(g['yanitli_oran'])}',
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF3B2A5C)),
          ),
        ],
        if (aylik.length > 1) ...[
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 6, children: [
            for (final a in aylik)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFF4F1FA), borderRadius: BorderRadius.circular(10)),
                child: Text('${_ayAdi(a['ay'])}: ${yuzde(a['oran'])}',
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
              ),
          ]),
        ],
      ]),
    );
  }

  Widget _degistiNoktasi() => Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
            color: Color(0xFFF97316), shape: BoxShape.circle),
      );

  Widget _bildirimKarti(Map b) {
    final kod = b['kod'].toString();
    final (ikon, renk) = _ikon[kod] ??
        (Icons.notifications_none_rounded, const Color(0xFF7C3AED));
    final aciklama = (b['aciklama'] ?? '').toString();
    final saatDegisti = _hatirlatmaSaat(_veri) != _hatirlatmaSaat(_orj);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      decoration: _kartSusu(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: renk.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(ikon, color: renk, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text((b['ad'] ?? '').toString(),
                        style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F1633))),
                    if (aciklama.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(aciklama,
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                height: 1.3)),
                      ),
                    if (kod == 'hatirlatma_yaklasan')
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            _saatSecici(),
                            if (saatDegisti) ...[
                              const SizedBox(width: 6),
                              _degistiNoktasi()
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (final a in _aliciAd.keys) _aliciSatiri(b, a),
        ],
      ),
    );
  }

  Widget _saatSecici() {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F0FC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDCC9F2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _hatirlatmaSaat(_veri),
          isDense: true,
          borderRadius: BorderRadius.circular(10),
          icon: const Icon(Icons.expand_more_rounded, color: _mor, size: 18),
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700, color: _mor),
          items: [
            for (var i = 1; i <= 23; i++)
              DropdownMenuItem(value: i, child: Text('$i saat önce')),
          ],
          onChanged: _kaydediliyor
              ? null
              : (v) {
                  if (v != null) setState(() => _veri!['hatirlatma_saat'] = v);
                },
        ),
      ),
    );
  }

  Widget _aliciSatiri(Map b, String alici) {
    final r = _alici(b, alici);
    final etiket = _aliciAd[alici]!;
    final ustCizgi = BoxDecoration(
      border: Border(top: BorderSide(color: Colors.grey.shade100)),
    );
    if (r == null) {
      return Container(
        decoration: ustCizgi,
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          SizedBox(
              width: 72,
              child: Text(etiket,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade500))),
          Text('—', style: TextStyle(color: Colors.grey.shade400)),
        ]),
      );
    }
    final o = _alici(_bildirimBul(_orj, b['kod'].toString()), alici);
    final acik = (_i(r['sms']) + _i(r['whatsapp']) + _i(r['push'])) > 0;

    // Tek satir: etiket + ana anahtar + 3 kanal cipi. Cipte ikon yok, yazi sigmazsa kesilmez kuculur.
    return Container(
      decoration: ustCizgi,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 58,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(etiket,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: acik
                          ? const Color(0xFF3B2A5C)
                          : Colors.grey.shade500)),
            ),
          ),
          SizedBox(
            width: 42,
            height: 28,
            child: FittedBox(
              fit: BoxFit.contain,
              child: Switch(
                value: acik,
                activeTrackColor: _mor,
                activeThumbColor: Colors.white,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onChanged:
                    _kaydediliyor ? null : (v) => _anaDegistir(b, alici, v),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Row(
              children: [
                for (final k in _kanallar) ...[
                  Expanded(
                    child: _kanalCipi(
                      acik: _i(r[k]) == 1,
                      degisti: _i(r[k]) != _i(o?[k]),
                      kanal: k,
                      onTap: () => _cipDegistir(b, alici, k),
                    ),
                  ),
                  if (k != _kanallar.last) const SizedBox(width: 4),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kanalCipi({
    required bool acik,
    required bool degisti,
    required String kanal,
    required VoidCallback onTap,
  }) {
    final renk = _kanalRenk[kanal]!;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: acik ? renk.withValues(alpha: 0.12) : Colors.white,
          borderRadius: BorderRadius.circular(9),
          child: InkWell(
            borderRadius: BorderRadius.circular(9),
            onTap: _kaydediliyor ? null : onTap,
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: acik
                      ? renk.withValues(alpha: 0.55)
                      : Colors.grey.shade300,
                  width: acik ? 1.3 : 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _kanalAd[kanal]!,
                        maxLines: 1,
                        softWrap: false,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: acik ? renk : Colors.grey.shade500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (degisti)
          Positioned(
            top: -3,
            right: -3,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: const Color(0xFFF97316),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }

  Widget _hataKutusu(String mesaj) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                  color: Color(0xFFFEE2E2), shape: BoxShape.circle),
              child: const Icon(Icons.error_outline_rounded,
                  color: Color(0xFFDC2626), size: 32),
            ),
            const SizedBox(height: 14),
            const Text('Bildirim ayarları yüklenemedi',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 6),
            Text(mesaj,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () => _yukle(ilk: true),
              style: FilledButton.styleFrom(backgroundColor: _mor),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }
}

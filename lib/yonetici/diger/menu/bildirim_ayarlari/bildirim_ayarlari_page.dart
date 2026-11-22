import 'package:flutter/material.dart';
import 'package:randevu_sistem/Backend/backend.dart';

/// Ayarlar > Bildirim Ayarları (web paneliyle aynı ekran).
/// SMS / WhatsApp / Uygulama (push) için her bildirim x alıcı ayrı anahtar.
/// Uçlar: /api/v1/bildirim-ayarlari/veri + /kaydet (yalnız Hesap Sahibi).
class BildirimAyarlariPage extends StatefulWidget {
  final String salonId;
  const BildirimAyarlariPage({super.key, required this.salonId});

  @override
  State<BildirimAyarlariPage> createState() => _BildirimAyarlariPageState();
}

class _BildirimAyarlariPageState extends State<BildirimAyarlariPage> {
  static const Color _yesil = Color(0xFF22C55E);
  static const Color _mor = Colors.deepPurple;

  static const List<String> _kanallar = ['sms', 'whatsapp', 'push'];
  static const Map<String, String> _aliciAd = {
    'musteri': 'Müşteriye',
    'personel': 'Personele',
    'yonetici': 'Yöneticiye',
  };

  bool _yukleniyor = true;
  bool _topluCalisiyor = false;
  String? _hata;
  List<dynamic> _gruplar = [];
  bool _waYedekSms = false;
  Map<String, dynamic> _durum = {};
  final Set<String> _bekleyen = {};

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    setState(() {
      _yukleniyor = true;
      _hata = null;
    });
    final res = await bildirimAyarlariVeri(widget.salonId);
    if (!mounted) return;
    setState(() {
      _yukleniyor = false;
      if (_okMu(res)) {
        _veriyiAl(res);
      } else {
        _hata = (res['hata'] ?? 'Bildirim ayarları yüklenemedi.').toString();
      }
    });
  }

  bool _okMu(Map<String, dynamic> res) =>
      res['ok'] == 1 || res['ok'] == true || res['ok'].toString() == '1';

  bool _acikMi(dynamic v) => v == 1 || v == true || v.toString() == '1';

  void _veriyiAl(Map<String, dynamic> res) {
    _gruplar = (res['gruplar'] is List) ? res['gruplar'] as List : [];
    _waYedekSms = _acikMi(res['wa_yedek_sms']);
    _durum = (res['durum'] is Map)
        ? Map<String, dynamic>.from(res['durum'] as Map)
        : <String, dynamic>{};
  }

  void _mesaj(String metin, {bool hata = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(metin),
      backgroundColor: hata ? Colors.red.shade700 : null,
    ));
  }

  // ---------------------------------------------------------------- kayıt

  Future<void> _anahtarDegistir(
      Map bildirim, String alici, String kanal, bool yeni) async {
    final kod = bildirim['kod'].toString();
    final anahtar = '$kod|$alici|$kanal';
    if (_bekleyen.contains(anahtar)) return;
    final kanallarMap = (bildirim['alicilar'] as Map)[alici] as Map;
    final eski = kanallarMap[kanal];
    setState(() {
      kanallarMap[kanal] = yeni ? 1 : 0;
      _bekleyen.add(anahtar);
    });
    final res = await bildirimAyarKaydet(widget.salonId, {
      'kod': kod,
      'alici': alici,
      'kanal': kanal,
      'deger': yeni ? 1 : 0,
    });
    if (!mounted) return;
    setState(() {
      _bekleyen.remove(anahtar);
      if (_okMu(res)) {
        if (res['kanallar'] is Map) {
          (res['kanallar'] as Map).forEach((k, v) => kanallarMap[k] = v);
        }
      } else {
        kanallarMap[kanal] = eski;
      }
    });
    if (!_okMu(res)) {
      _mesaj((res['hata'] ?? 'Ayar kaydedilemedi.').toString(), hata: true);
    }
  }

  Future<void> _waYedekDegistir(bool yeni) async {
    if (_bekleyen.contains('wa_yedek')) return;
    final eski = _waYedekSms;
    setState(() {
      _waYedekSms = yeni;
      _bekleyen.add('wa_yedek');
    });
    final res =
        await bildirimAyarKaydet(widget.salonId, {'wa_yedek_sms': yeni ? 1 : 0});
    if (!mounted) return;
    setState(() {
      _bekleyen.remove('wa_yedek');
      _waYedekSms = _okMu(res) ? _acikMi(res['wa_yedek_sms']) : eski;
    });
    if (!_okMu(res)) {
      _mesaj((res['hata'] ?? 'Ayar kaydedilemedi.').toString(), hata: true);
    }
  }

  Future<void> _toplu(String kanal, bool deger) async {
    if (_topluCalisiyor) return;
    setState(() => _topluCalisiyor = true);
    final res = await bildirimAyarKaydet(widget.salonId, {
      'toplu': 1,
      'kanal': kanal,
      'deger': deger ? 1 : 0,
    });
    if (!mounted) return;
    setState(() {
      _topluCalisiyor = false;
      if (_okMu(res) && res['gruplar'] is List) _veriyiAl(res);
    });
    if (_okMu(res)) {
      _mesaj(deger ? 'Tüm bildirimler açıldı.' : 'Tüm bildirimler kapatıldı.');
    } else {
      _mesaj((res['hata'] ?? 'Ayar kaydedilemedi.').toString(), hata: true);
    }
  }

  // ---------------------------------------------------------------- arayüz

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F7FB),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          foregroundColor: Colors.black,
          title: const Text('Bildirim Ayarları',
              style:
                  TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              color: Colors.white,
              child: TabBar(
                labelColor: _mor,
                unselectedLabelColor: Colors.grey.shade700,
                indicatorColor: _mor,
                tabs: const [
                  Tab(text: 'SMS'),
                  Tab(text: 'WhatsApp'),
                  Tab(text: 'Uygulama'),
                ],
              ),
            ),
          ),
        ),
        body: _yukleniyor
            ? const Center(child: CircularProgressIndicator())
            : (_hata != null
                ? _hataKutusu(_hata!)
                : Stack(children: [
                    TabBarView(
                        children: _kanallar.map(_kanalSekmesi).toList()),
                    if (_topluCalisiyor)
                      Positioned.fill(
                        child: Container(
                          color: Colors.white.withValues(alpha: 0.5),
                          child:
                              const Center(child: CircularProgressIndicator()),
                        ),
                      ),
                  ])),
      ),
    );
  }

  Widget _kanalSekmesi(String kanal) {
    final kartlar = <Widget>[];
    for (final g in _gruplar) {
      if (g is! Map) continue;
      final bildirimler = (g['bildirimler'] is List)
          ? (g['bildirimler'] as List).whereType<Map>().toList()
          : <Map>[];
      final grupKartlari = <Widget>[];
      for (final b in bildirimler) {
        final kart = _bildirimKarti(b, kanal);
        if (kart != null) grupKartlari.add(kart);
      }
      if (grupKartlari.isEmpty) continue;
      kartlar.add(Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
        child: Text(
          (g['ad'] ?? '').toString(),
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade800,
              letterSpacing: 0.3),
        ),
      ));
      kartlar.addAll(grupKartlari);
    }

    return RefreshIndicator(
      onRefresh: _yukle,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
        children: [
          _durumKarti(kanal),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: _topluCalisiyor ? null : () => _toplu(kanal, true),
                icon: const Icon(Icons.toggle_on_outlined, size: 18),
                label: const Text('Tümünü aç'),
                style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF16A34A),
                    visualDensity: VisualDensity.compact),
              ),
              TextButton.icon(
                onPressed: _topluCalisiyor ? null : () => _toplu(kanal, false),
                icon: const Icon(Icons.toggle_off_outlined, size: 18),
                label: const Text('Tümünü kapat'),
                style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    visualDensity: VisualDensity.compact),
              ),
            ],
          ),
          if (kartlar.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Bu kanal için ayarlanabilir bildirim yok.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600)),
            ),
          ...kartlar,
        ],
      ),
    );
  }

  BoxDecoration get _kartSusu => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      );

  Widget _durumKarti(String kanal) {
    IconData ikon;
    Color renk;
    String baslik;
    String alt;
    Widget? ek;

    if (kanal == 'sms') {
      final hesap = _acikMi(_durum['sms_hesabi']);
      final bakiye = _durum['sms_bakiye'];
      ikon = Icons.sms_outlined;
      renk = hesap ? _yesil : Colors.orange.shade700;
      baslik = hesap ? 'SMS hesabı tanımlı' : 'SMS paketi yok';
      alt = hesap
          ? (bakiye != null
              ? 'Kalan SMS: $bakiye'
              : 'Kalan SMS bilgisi alınamadı')
          : 'SMS paketi olmadan SMS bildirimleri gönderilmez.';
    } else if (kanal == 'whatsapp') {
      final bagli = _acikMi(_durum['wa_bagli']);
      ikon = Icons.chat_outlined;
      renk = bagli ? _yesil : Colors.red.shade600;
      baslik = bagli ? 'WhatsApp bağlı' : 'WhatsApp bağlı değil';
      alt = bagli
          ? 'Bildirimler işletmenizin WhatsApp hattından gönderilir.'
          : 'WhatsApp bağlanmadan WhatsApp bildirimleri gönderilmez.';
      ek = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 20),
          Row(
            children: [
              const Expanded(
                child: Text('WhatsApp ulaşmazsa SMS gönder',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
              Switch(
                value: _waYedekSms,
                activeTrackColor: _yesil,
                activeThumbColor: Colors.white,
                onChanged: _bekleyen.contains('wa_yedek')
                    ? null
                    : (v) => _waYedekDegistir(v),
              ),
            ],
          ),
          Text('SMS paketi yoksa SMS de gitmez.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ],
      );
    } else {
      final n = _durum['uygulama_musteri'] ?? 0;
      ikon = Icons.phone_iphone_rounded;
      renk = _mor;
      baslik = 'Uygulamayı kullanan müşteri: $n';
      alt = 'Uygulama bildirimi yalnızca uygulamayı kullanan müşterilere gider.';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _kartSusu,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: renk.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(ikon, color: renk, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(baslik,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(alt,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ],
          ),
          if (ek != null) ek,
        ],
      ),
    );
  }

  /// Bu kanalda gösterilecek alıcı satırı yoksa null döner.
  Widget? _bildirimKarti(Map b, String kanal) {
    final alicilar = b['alicilar'];
    if (alicilar is! Map) return null;
    final satirlar = <Widget>[];
    for (final alici in _aliciAd.keys) {
      final k = alicilar[alici];
      if (k is! Map || !k.containsKey(kanal)) continue;
      final anahtar = '${b['kod']}|$alici|$kanal';
      satirlar.add(Row(
        children: [
          Icon(
              alici == 'musteri'
                  ? Icons.person_outline
                  : alici == 'yonetici'
                      ? Icons.admin_panel_settings_outlined
                      : Icons.badge_outlined,
              size: 18,
              color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
              child: Text(_aliciAd[alici]!,
                  style: const TextStyle(fontSize: 14))),
          Switch(
            value: _acikMi(k[kanal]),
            activeTrackColor: _yesil,
                activeThumbColor: Colors.white,
            onChanged: _bekleyen.contains(anahtar) || _topluCalisiyor
                ? null
                : (v) => _anahtarDegistir(b, alici, kanal, v),
          ),
        ],
      ));
    }
    if (satirlar.isEmpty) return null;
    final aciklama = (b['aciklama'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 4),
      decoration: _kartSusu,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text((b['ad'] ?? '').toString(),
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ),
          if (aciklama.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 3, right: 8),
              child: Text(aciklama,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ),
          const SizedBox(height: 4),
          ...satirlar,
        ],
      ),
    );
  }

  Widget _hataKutusu(String mesaj) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 36),
            const SizedBox(height: 12),
            const Text('Bildirim ayarları yüklenemedi',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(mesaj,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _yukle,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Backend/yetki.dart';
import 'package:randevu_sistem/Models/personel.dart';

// Personel granular yetki yonetimi sayfasi.
//
// Tasarim:
//  - Mor gradient hero (personel avatar+ad)
//  - 4 sablon kart (Sekreter / Personel Tam / Personel Sade / Demo)
//      Birine tiklayinca o sablonun ayarlari toplu uygulanir, "Özel" badge'i kalkar.
//  - Kategori bazli accordion'lar (Randevu, Müşteri, Satış, ...)
//      Her kategorinin basliginda "X / Y aktif" sayaci
//      Her yetki bir Switch satiri (label + aciklama + toggle)
//  - Floating kaydet butonu
//
// Kullanici elle ayar degistirdiginde sablon otomatik "ozel" olarak isaretlenir.
// Backend'de kaydedildiginde "Personel" rolunde olmayan personeller icin sayfa
// uyari gosterir (defansif).
class PersonelYetki extends StatefulWidget {
  final Personel personel;
  final String salonid;
  const PersonelYetki({super.key, required this.personel, required this.salonid});

  @override
  State<PersonelYetki> createState() => _PersonelYetkiState();
}

class _PersonelYetkiState extends State<PersonelYetki> {
  // Tema (Personeller sayfasi ile birebir)
  static const _p1 = Color(0xFF5C008E);
  static const _p2 = Color(0xFF7B2FB8);
  static const _p3 = Color(0xFF9D5DC8);
  static const _purpleBg = Color(0xFFF7F1FB);
  static const _border = Color(0xFFECE6F2);
  static const _text = Color(0xFF2D1B3F);
  static const _muted = Color(0xFF8A8295);
  static const _grad = LinearGradient(
    colors: [_p1, _p2, _p3],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  bool _loading = true;
  bool _kaydediliyor = false;
  String? _hata;
  bool _personelRolunde = true;

  // Server'dan gelenler
  List<Map<String, dynamic>> _tanimlar = [];
  Map<String, Map<String, dynamic>> _kategoriler = {};
  List<Map<String, dynamic>> _sablonlar = [];

  // Sayfa state'i
  String _seciliSablon = 'personel_sade';
  Map<String, bool> _ayarlar = {};
  // Hangi kategori acik (collapse durumu)
  final Set<String> _acikKategoriler = {'randevu', 'musteri'};
  // Sayfa yuklendigindeki orijinal (degisti mi karsilastirmasi icin)
  Map<String, bool> _orijinalAyarlar = {};
  String _orijinalSablon = 'personel_sade';

  bool get _degisti =>
      _orijinalSablon != _seciliSablon ||
      !_haritalarEsit(_orijinalAyarlar, _ayarlar);

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    setState(() {
      _loading = true;
      _hata = null;
    });
    try {
      // Paralel: sema + personel ayarlar
      final results = await Future.wait([
        personelYetkiSema(),
        personelYetkiGetir(salonid: widget.salonid, personelid: widget.personel.id),
      ]);
      final sema = results[0];
      final ayar = results[1];

      if (sema == null) {
        setState(() {
          _loading = false;
          _hata = 'Yetki şeması yüklenemedi.';
        });
        return;
      }

      _tanimlar = ((sema['tanimlar'] as List?) ?? const [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      _kategoriler = {};
      ((sema['kategoriler'] as Map?) ?? const {}).forEach((k, v) {
        _kategoriler[k.toString()] = Map<String, dynamic>.from(v as Map);
      });
      _sablonlar = ((sema['sablonlar'] as List?) ?? const [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      if (ayar != null && ayar['basarili'] == true) {
        _personelRolunde = ayar['personel_rolunde'] == true;
        _seciliSablon = (ayar['sablon'] ?? 'personel_sade').toString();
        final ayarMap = (ayar['ayarlar'] as Map?) ?? const {};
        _ayarlar = {};
        ayarMap.forEach((k, v) {
          _ayarlar[k.toString()] = v == true || v == 1 || v == '1';
        });
      } else {
        _seciliSablon = 'personel_sade';
        _ayarlar = {};
      }

      // Eksik anahtarlari false ile tamamla
      for (final t in _tanimlar) {
        final key = t['key'].toString();
        _ayarlar.putIfAbsent(key, () => false);
      }

      _orijinalSablon = _seciliSablon;
      _orijinalAyarlar = Map.of(_ayarlar);

      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _loading = false;
        _hata = 'Hata: $e';
      });
    }
  }

  Future<void> _kaydet() async {
    setState(() => _kaydediliyor = true);
    final result = await personelYetkiKaydet(
      salonid: widget.salonid,
      personelid: widget.personel.id,
      sablon: _seciliSablon,
      ayarlar: _ayarlar,
    );
    setState(() => _kaydediliyor = false);
    if (!mounted) return;
    final ok = result['basarili'] == true;
    if (ok) {
      _orijinalSablon = _seciliSablon;
      _orijinalAyarlar = Map.of(_ayarlar);
      // Eger duzenlenen personel = giris yapan kullanici ise, giris yapanin
      // yetki cache'i de tazelensin ki UI hemen yansisin. Farkli personel
      // ise cagri zarar vermez (kendi yetkilerini cekiyor).
      Yetki.tazele(salonid: widget.salonid);
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Yetkiler kaydedildi'),
          backgroundColor: const Color(0xFF15803D),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      final mesaj = (result['mesaj'] ?? 'Kaydedilemedi').toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mesaj, maxLines: 4),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          action: SnackBarAction(
            label: 'Kapat',
            textColor: Colors.white,
            onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
          ),
        ),
      );
    }
  }

  // Belli bir sablonu uygula (tum ayarlar bir cirpida bu sablonun degerlerine doner).
  // Backend sema cevabinda her sablonun 'ayarlar' map'i geliyor — onu kullaniyoruz.
  // Boylece backend ile mobile arasinda uyumsuzluk olmaz, yeni yetki/sablon
  // eklemek icin tek yer (PersonelYetkiSabitleri.php) yeterli olur.
  void _sablonUygula(String sablonKey) {
    // _sablonlar listesinden bu key'e sahip olani bul
    final secilen = _sablonlar.firstWhere(
      (s) => s['key'].toString() == sablonKey,
      orElse: () => const <String, dynamic>{},
    );
    final ayarRaw = secilen['ayarlar'];
    if (ayarRaw is! Map) {
      debugPrint('Sablon ayarlari bulunamadi: $sablonKey');
      return;
    }
    setState(() {
      _seciliSablon = sablonKey;
      _ayarlar = {};
      // Once tum anahtarlari false yap (sema'da var olan ama sablonda olmayanlar)
      for (final t in _tanimlar) {
        _ayarlar[t['key'].toString()] = false;
      }
      // Sablon degerlerini uygula
      ayarRaw.forEach((k, v) {
        _ayarlar[k.toString()] = v == true || v == 1 || v == '1';
      });
    });
  }

  void _yetkiToggle(String key) {
    setState(() {
      _ayarlar[key] = !(_ayarlar[key] ?? false);
      // Elle degisiklik yapildiginda sablon 'ozel' olur
      _seciliSablon = 'ozel';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9FD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        iconTheme: const IconThemeData(color: _text),
        title: const Text('Yetki Yönetimi',
            style: TextStyle(color: _text, fontWeight: FontWeight.w600)),
        actions: [
          if (_degisti && !_loading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              child: _kaydetBtn(compact: true),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _p1))
          : _hata != null
              ? _hataKarti(_hata!)
              : ListView(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 80),
                  children: [
                    _hero(),
                    const SizedBox(height: 14),
                    if (!_personelRolunde) _personelRolDegilUyari(),
                    if (!_personelRolunde) const SizedBox(height: 12),
                    _sablonBolumu(),
                    const SizedBox(height: 14),
                    _yetkilerBolumu(),
                    const SizedBox(height: 14),
                    if (_degisti) _kaydetBtn(compact: false),
                  ],
                ),
    );
  }

  // === Hero ===
  Widget _hero() {
    final initial = widget.personel.personel_adi.trim().isEmpty
        ? '?'
        : widget.personel.personel_adi.trim().substring(0, 1).toUpperCase();
    return Container(
      decoration: BoxDecoration(
        gradient: _grad,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: _p1.withValues(alpha: 0.22), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
            ),
            alignment: Alignment.center,
            child: Text(initial,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.personel.personel_adi,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                const Text('Erişim ayarları ve yetkiler',
                    style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _personelRolDegilUyari() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Color(0xFFB45309), size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Bu personel "Personel" rolünde değil — Hesap Sahibi/Yönetici/Süpervizör/Sekreter rolleri otomatik tam yetkilidir. Buradaki ayarlar SADECE rol "Personel" yapıldığında uygulanır.',
              style: TextStyle(color: Color(0xFF92400E), fontSize: 12.5, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  // === Sablon bolumu ===
  Widget _sablonBolumu() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [BoxShadow(color: _p1.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune, color: _p2, size: 18),
              const SizedBox(width: 8),
              const Text('Hazır Şablon',
                  style: TextStyle(color: _text, fontWeight: FontWeight.w700, fontSize: 14)),
              const Spacer(),
              if (_seciliSablon == 'ozel')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Özel',
                      style: TextStyle(
                          color: Color(0xFFB45309), fontSize: 11, fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.1,
            children: _sablonlar.map((s) {
              final key = s['key'].toString();
              final sel = _seciliSablon == key;
              return _sablonKart(
                key: key,
                ad: s['ad'].toString(),
                aciklama: s['aciklama'].toString(),
                ikonAdi: s['ikon']?.toString() ?? 'person',
                secili: sel,
              );
            }).toList(),
          ),
          if (_seciliSablon == 'ozel') ...[
            const SizedBox(height: 8),
            Text(
              'Üzerinde değişiklik yaptın. Aşağıdaki ayarlar sadece bu personele özel uygulanacak.',
              style: TextStyle(color: _muted, fontSize: 11.5, fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sablonKart({
    required String key,
    required String ad,
    required String aciklama,
    required String ikonAdi,
    required bool secili,
  }) {
    return InkWell(
      onTap: () => _sablonUygula(key),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        decoration: BoxDecoration(
          gradient: secili ? _grad : null,
          color: secili ? null : const Color(0xFFFCFAFE),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: secili ? Colors.transparent : _border),
          boxShadow: secili
              ? [BoxShadow(color: _p1.withValues(alpha: 0.22), blurRadius: 10, offset: const Offset(0, 4))]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                color: secili
                    ? Colors.white.withValues(alpha: 0.22)
                    : _purpleBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _ikonAd(ikonAdi),
                color: secili ? Colors.white : _p1,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ad,
                      style: TextStyle(
                        color: secili ? Colors.white : _text,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text(
                    aciklama,
                    style: TextStyle(
                      color: secili
                          ? Colors.white.withValues(alpha: 0.82)
                          : _muted,
                      fontSize: 10,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _ikonAd(String ad) {
    switch (ad) {
      case 'support_agent': return Icons.support_agent;
      case 'verified_user': return Icons.verified_user;
      case 'person': return Icons.person;
      case 'visibility': return Icons.visibility;
      case 'event': return Icons.event;
      case 'people': return Icons.people;
      case 'payments': return Icons.payments;
      case 'inventory_2': return Icons.inventory_2;
      case 'badge': return Icons.badge;
      case 'bar_chart': return Icons.bar_chart;
      case 'account_balance_wallet': return Icons.account_balance_wallet;
      case 'campaign': return Icons.campaign;
      case 'phone_in_talk': return Icons.phone_in_talk;
      case 'settings': return Icons.settings;
      default: return Icons.tune;
    }
  }

  // === Yetkiler bolumu (kategorili accordion) ===
  Widget _yetkilerBolumu() {
    // Tanimlari kategorilere grupla (sira backend'den geldigi gibi)
    final Map<String, List<Map<String, dynamic>>> grupla = {};
    for (final t in _tanimlar) {
      final k = t['kategori'].toString();
      grupla.putIfAbsent(k, () => []).add(t);
    }
    final kategoriSirasi = _kategoriler.keys.toList();
    final kategorilerListesi = <Widget>[];
    for (final kat in kategoriSirasi) {
      if (!grupla.containsKey(kat)) continue;
      final yetkiler = grupla[kat]!;
      final aktif = yetkiler.where((y) => _ayarlar[y['key'].toString()] == true).length;
      final etiket = _kategoriler[kat]!;
      kategorilerListesi.add(_kategoriAccordion(
        kat: kat,
        ad: etiket['ad'].toString(),
        ikon: _ikonAd(etiket['ikon']?.toString() ?? 'tune'),
        aktif: aktif,
        toplam: yetkiler.length,
        yetkiler: yetkiler,
      ));
      kategorilerListesi.add(const SizedBox(height: 8));
    }
    return Column(children: kategorilerListesi);
  }

  Widget _kategoriAccordion({
    required String kat,
    required String ad,
    required IconData ikon,
    required int aktif,
    required int toplam,
    required List<Map<String, dynamic>> yetkiler,
  }) {
    final acik = _acikKategoriler.contains(kat);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                if (acik) {
                  _acikKategoriler.remove(kat);
                } else {
                  _acikKategoriler.add(kat);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
              child: Row(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: _p2.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(ikon, color: _p2, size: 17),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(ad,
                        style: const TextStyle(
                            color: _text, fontWeight: FontWeight.w700, fontSize: 14)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: aktif > 0 ? _purpleBg : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$aktif / $toplam',
                      style: TextStyle(
                        color: aktif > 0 ? _p1 : _muted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(acik ? Icons.expand_less : Icons.expand_more, color: _muted),
                ],
              ),
            ),
          ),
          if (acik) ...[
            const Divider(height: 1, color: _border),
            ...yetkiler.map(_yetkiSatiri),
          ],
        ],
      ),
    );
  }

  Widget _yetkiSatiri(Map<String, dynamic> y) {
    final key = y['key'].toString();
    final label = y['label'].toString();
    final aciklama = (y['aciklama'] ?? '').toString();
    final acik = _ayarlar[key] ?? false;
    // Telefon vurgu: musteri.telefon_gor altinda kirmizi uyari
    final telefonOzel = key == 'musteri.telefon_gor';
    return InkWell(
      onTap: () => _yetkiToggle(key),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: _text, fontSize: 13.5, fontWeight: FontWeight.w600)),
                  if (aciklama.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        aciklama,
                        style: TextStyle(
                          color: telefonOzel
                              ? const Color(0xFFB45309)
                              : _muted,
                          fontSize: 11.5,
                          fontWeight: telefonOzel ? FontWeight.w600 : FontWeight.w400,
                          height: 1.3,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Switch(
              value: acik,
              onChanged: (_) => _yetkiToggle(key),
              activeThumbColor: Colors.white,
              activeTrackColor: _p2,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: const Color(0xFFD1D5DB),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }

  // === Kaydet butonu ===
  Widget _kaydetBtn({required bool compact}) {
    if (compact) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: _kaydediliyor ? null : _kaydet,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: _grad,
              borderRadius: BorderRadius.circular(10),
            ),
            child: _kaydediliyor
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text('Kaydet',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13.5)),
                    ],
                  ),
          ),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        gradient: _grad,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: _p1.withValues(alpha: 0.3), blurRadius: 14, offset: const Offset(0, 6)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _kaydediliyor ? null : _kaydet,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _kaydediliyor
                  ? const [
                      SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      ),
                    ]
                  : const [
                      Icon(Icons.check_circle_outline, color: Colors.white, size: 19),
                      SizedBox(width: 8),
                      Text('Yetkileri Kaydet',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15.5)),
                    ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _hataKarti(String mesaj) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Color(0xFF991B1B)),
            const SizedBox(width: 10),
            Expanded(child: Text(mesaj, style: const TextStyle(color: Color(0xFF991B1B)))),
          ],
        ),
      ),
    );
  }

  bool _haritalarEsit(Map<String, bool> a, Map<String, bool> b) {
    if (a.length != b.length) return false;
    for (final k in a.keys) {
      if (a[k] != b[k]) return false;
    }
    return true;
  }
}

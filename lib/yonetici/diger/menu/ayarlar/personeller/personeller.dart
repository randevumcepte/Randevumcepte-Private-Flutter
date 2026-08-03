import 'package:flutter/material.dart';
import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Backend/yetki.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:randevu_sistem/Models/personel.dart';
import 'package:randevu_sistem/Frontend/sfdatatable.dart';
import 'package:randevu_sistem/yonetici/diger/menu/ayarlar/personeller/personeldetay.dart';
import 'package:randevu_sistem/yonetici/diger/menu/ayarlar/personeller/personelduzenle.dart';
import 'package:randevu_sistem/yonetici/diger/menu/ayarlar/personeller/personelekle.dart';
import 'package:randevu_sistem/yonetici/diger/menu/ayarlar/personeller/personelsatislari.dart';
import 'package:randevu_sistem/yonetici/diger/menu/ayarlar/personeller/personel_yetki.dart';
import 'package:randevu_sistem/yonetici/diger/menu/ayarlar/personeller/prim_hakedis.dart';

// Personeller listesi sayfasi. Web'deki personelyonetimi.blade.php'in mobil karsiligi.
// - Mor gradient hero
// - 4 istatistik karti: Takvimde / Aktif / Pasif / Toplam
// - Arama kutusu + Yeni Personel butonu
// - Personel kart listesi (avatar + ad + telefon + durum + takvim badge + dropdown)
// - Pagination
//
// PersonelDataSource'u UI gostergesi olarak DEĞIL, PersonelEkle/PersonelDuzenle'ye
// geçirmek icin tutuyoruz (onlar zorunlu olarak istiyor). Veri cekme isini
// kendi state'imizde yapiyoruz; navigasyon donusunde fetchData ile tazeliyoruz.
class Personeller extends StatefulWidget {
  final dynamic isletmebilgi;
  final int kullanicirolu;
  const Personeller({super.key, required this.isletmebilgi, required this.kullanicirolu});

  @override
  State<Personeller> createState() => _PersonellerState();
}

class _PersonellerState extends State<Personeller> {
  // Tasarim sabitleri (web ile birebir):
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

  String? _salonid;
  bool _initLoading = true;
  bool _listLoading = false;

  // Sayfa listesi (UI'da gosterilen, sayfalanmis liste)
  List<Personel> _liste = [];
  int _currentPage = 1;
  int _totalPages = 1;

  // Stat kartlari icin tum personel listesi (sayfalama yok)
  List<Personel> _tumListe = [];

  // PersonelDataSource: PersonelEkle/PersonelDuzenle constructor'lari zorunlu istiyor.
  // Sadece onlara parametre olarak gecmek icin tutuyoruz; UI'da kullanmiyoruz.
  PersonelDataSource? _dataSource;

  final TextEditingController _aramaCtrl = TextEditingController();
  String _aramaQ = '';

  @override
  void initState() {
    super.initState();
    _init();
    _aramaCtrl.addListener(() {
      if (_aramaCtrl.text == _aramaQ) return;
      _aramaQ = _aramaCtrl.text;
      _currentPage = 1;
      _listeYukle();
    });
  }

  @override
  void dispose() {
    _aramaCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    _salonid = await secilisalonid();
    if (!mounted) return;
    if (_salonid == null) {
      setState(() => _initLoading = false);
      return;
    }
    // Yetki cache'ini tazele (giris yapan kisinin guncel yetkileri)
    await Yetki.tazele(salonid: _salonid!);
    await Future.wait([_listeYukle(), _tumListeYukle()]);
    if (!mounted) return;
    setState(() => _initLoading = false);
  }

  // PersonelEkle/PersonelDuzenle'nin constructor'i zorunlu olarak PersonelDataSource istiyor.
  // UI'da kullanmadigimiz icin sadece bu navigasyonlarda lazy olarak olustur.
  PersonelDataSource _ekleDuzenleDataSource() {
    return _dataSource ??= PersonelDataSource(
      kullanicirolu: widget.kullanicirolu,
      rowsPerPage: 10,
      salonid: _salonid!,
      context: context,
      baslik: '',
      isletmebilgi: widget.isletmebilgi,
      showYukleniyor: false,
    );
  }

  Future<void> _listeYukle() async {
    if (_salonid == null) return;
    setState(() => _listLoading = true);
    try {
      final json = await personelgetir(_salonid!, _currentPage.toString(), _aramaQ);
      final List<dynamic> data = json['data'] ?? [];
      _liste = data.map<Personel>((e) => Personel.fromJson(e)).toList();
      _currentPage = (json['current_page'] as num?)?.toInt() ?? 1;
      _totalPages = (json['last_page'] as num?)?.toInt() ?? 1;
    } catch (e) {
      debugPrint('personeller _listeYukle: $e');
    } finally {
      if (mounted) setState(() => _listLoading = false);
    }
  }

  Future<void> _tumListeYukle() async {
    if (_salonid == null) return;
    try {
      _tumListe = await personellistegetir(_salonid!);
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('personeller _tumListeYukle: $e');
    }
  }

  Future<void> _refreshAll() async {
    await Future.wait([_listeYukle(), _tumListeYukle()]);
  }

  // === istatistikler (tum liste uzerinden) ===
  int get _statTakvimde => _tumListe.where((p) => p.takvimde_gorunsun == '1' || p.takvimde_gorunsun == 'true').length;
  int get _statAktif => _tumListe.where((p) => p.durum == '1' || p.durum == 'true').length;
  int get _statPasif => _tumListe.where((p) => p.durum == '0' || p.durum == 'false').length;
  int get _statToplam => _tumListe.length;

  // === aksiyonlar ===
  void _ekleAc() {
    if (_salonid == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PersonelEkle(isletmebilgi: widget.isletmebilgi, personeldata: _ekleDuzenleDataSource()),
      ),
    ).then((_) => _refreshAll());
  }

  void _duzenleAc(Personel p) {
    if (_salonid == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PersonelDuzenle(per: p, isletmebilgi: widget.isletmebilgi, personeldata: _ekleDuzenleDataSource()),
      ),
    ).then((_) => _refreshAll());
  }

  void _detayAc(Personel p) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PersonelDetay(personel: p, isletmebilgi: widget.isletmebilgi),
      ),
    );
  }

  void _satislarAc(Personel p) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PersonelSatislari(
          kullanicirolu: widget.kullanicirolu,
          kullanici: p,
          isletmebilgi: widget.isletmebilgi,
        ),
      ),
    );
  }

  void _yetkiAc(Personel p) {
    if (_salonid == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PersonelYetki(personel: p, salonid: _salonid!),
      ),
    );
  }

  Future<void> _sifreGonder(Personel p) async {
    final onay = await _onaylat(
      baslik: 'Yeni şifre gönder?',
      icerik: '${p.personel_adi} için yeni şifre üretilecek ve SMS olarak gönderilecek.',
      onayText: 'Evet, gönder',
    );
    if (onay != true) return;
    final ok = await personelSifreGonder(p.id);
    if (!mounted) return;
    _snack(ok ? 'Şifre SMS olarak gönderildi' : 'Şifre gönderilemedi', basari: ok);
  }

  Future<void> _aktifPasifToggle(Personel p) async {
    final aktif = p.durum == '1' || p.durum == 'true';
    // Optimistic update: backend cevap beklemeden UI'i hemen guncelle
    final eskiDurum = p.durum;
    setState(() {
      p.durum = aktif ? '0' : '1';
    });
    final ok = aktif ? await personelPasifYap(p.id) : await personelAktifYap(p.id);
    if (!mounted) return;
    if (ok) {
      _snack(aktif ? 'Personel pasif yapıldı' : 'Personel aktif yapıldı', basari: true);
      // Tum liste icin stat kartlarini tazele
      await _tumListeYukle();
    } else {
      // Hata: optimistic update'i geri al
      setState(() {
        p.durum = eskiDurum;
      });
      _snack('İşlem başarısız', basari: false);
    }
  }

  Future<void> _takvimToggle(Personel p) async {
    // Optimistic update
    final eski = p.takvimde_gorunsun;
    final acik = p.takvimde_gorunsun == '1' || p.takvimde_gorunsun == 'true';
    setState(() {
      p.takvimde_gorunsun = acik ? '0' : '1';
    });
    final yeni = await personelTakvimdeGorunsunToggle(p.id, _salonid!);
    if (!mounted) return;
    if (yeni != null) {
      // Backend yeni durumu dondu, kesin sonucu ata
      setState(() {
        p.takvimde_gorunsun = yeni.toString();
      });
      _snack(yeni == 1 ? 'Takvimde gözükecek' : 'Takvimden kaldırıldı', basari: true);
      await _tumListeYukle(); // stat kartlarini tazele
    } else {
      setState(() => p.takvimde_gorunsun = eski);
      _snack('Takvim durumu güncellenemedi', basari: false);
    }
  }

  Future<void> _siraKaydir(Personel p, int delta) async {
    // Optimistic: listedeki sirayi hemen kaydir
    final idx = _liste.indexWhere((x) => x.id == p.id);
    final hedef = idx + delta;
    if (idx >= 0 && hedef >= 0 && hedef < _liste.length) {
      setState(() {
        final item = _liste.removeAt(idx);
        _liste.insert(hedef, item);
      });
    }
    final ok = await personelSiralamaKaydir(p.id, _salonid!, delta);
    if (!mounted) return;
    if (!ok) {
      // Hata: geri al
      if (idx >= 0 && hedef >= 0 && hedef < _liste.length) {
        setState(() {
          final item = _liste.removeAt(hedef);
          _liste.insert(idx, item);
        });
      }
      _snack('Sıra değiştirilemedi', basari: false);
    }
  }

  Future<void> _arsivle(Personel p) async {
    // Once silme tarihinden itibaren gelecek randevulardaki bu personele ait hizmetleri kontrol et
    final veri = await personelGelecekHizmetler(p.id, _salonid!);
    if (!mounted) return;
    if (veri['sonuc'] != 'ok') {
      _snack('Personel bilgisi alınamadı', basari: false);
      return;
    }
    final int count = (veri['count'] is int) ? veri['count'] as int : int.tryParse('${veri['count']}') ?? 0;
    final List hizmetler = (veri['hizmetler'] is List) ? veri['hizmetler'] as List : const [];
    final List personeller = (veri['personeller'] is List) ? veri['personeller'] as List : const [];

    Map<String, String>? transferler;

    if (count > 0) {
      // Gelecek hizmet var: aktarim ZORUNLU
      if (personeller.isEmpty) {
        await _onaylat(
          baslik: 'Aktarım yapılamıyor',
          icerik: 'Bu personelin $count gelecek randevu hizmeti var ancak devredilebilecek '
              'başka aktif personel bulunmuyor. Önce yeni bir personel ekleyin.',
          onayText: 'Tamam',
        );
        return;
      }
      transferler = await _aktarimDialog(p, count, hizmetler, personeller);
      if (transferler == null) return; // vazgecildi
    } else {
      final onay = await _onaylat(
        baslik: '${p.personel_adi} silinsin mi?',
        icerik: 'Personel kalıcı olarak listeden gizlenecek.\n\n'
            '• Geçmiş randevu, satış, prim ve hak ediş kayıtları korunur\n'
            '• Raporlar ve istatistikler etkilenmez\n'
            '• Listeden, takvimden ve online randevudan kalkacak',
        onayText: 'Evet, sil',
        tehlikeli: true,
      );
      if (onay != true) return;
    }

    // Optimistic: personeli listeden hemen kaldir
    final idx = _liste.indexWhere((x) => x.id == p.id);
    setState(() {
      if (idx >= 0) _liste.removeAt(idx);
    });
    final sonuc = await personelArsivle(p.id, _salonid!, transferler: transferler);
    if (!mounted) return;
    if (sonuc['sonuc'] == 'ok') {
      final int akt = (sonuc['aktarilan'] is int) ? sonuc['aktarilan'] as int : int.tryParse('${sonuc['aktarilan']}') ?? 0;
      _snack(akt > 0 ? '$akt hizmet aktarıldı, personel silindi' : 'Personel silindi', basari: true);
      await _tumListeYukle(); // stat kartlarini tazele
    } else {
      // Hata: personeli geri ekle
      if (idx >= 0) {
        setState(() => _liste.insert(idx, p));
      }
      _snack(sonuc['mesaj']?.toString() ?? 'Silinemedi', basari: false);
    }
  }

  // Gelecek randevu hizmetlerinin her birini baska bir personele zorunlu devir ekrani.
  // Donen: rh_id -> yeni personelid eslemesi; vazgecilirse null.
  Future<Map<String, String>?> _aktarimDialog(
    Personel p,
    int count,
    List hizmetler,
    List personeller,
  ) {
    final Map<String, String> secim = {}; // rh_id -> personelid
    String? tumu;
    return showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            final tumSecili = hizmetler.every((h) => secim['${h['rh_id']}'] != null);
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Hizmetleri Aktar ve Sil',
                  style: TextStyle(color: _text, fontWeight: FontWeight.w700, fontSize: 18)),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${p.personel_adi} adlı personelin $count gelecek randevu hizmeti var. '
                      'Silmeden önce her hizmetin devredileceği personeli seçin.',
                      style: const TextStyle(color: _muted, height: 1.4, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      decoration: BoxDecoration(color: _purpleBg, borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text('Tümünü şu personele aktar',
                                style: TextStyle(color: _text, fontSize: 13, fontWeight: FontWeight.w600)),
                          ),
                          _personelDropdown(personeller, tumu, (v) {
                            setLocal(() {
                              tumu = v;
                              if (v != null) {
                                for (final h in hizmetler) {
                                  secim['${h['rh_id']}'] = v;
                                }
                              }
                            });
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: hizmetler.length,
                        separatorBuilder: (_, __) => const Divider(height: 16, color: _border),
                        itemBuilder: (_, i) {
                          final h = hizmetler[i];
                          final rh = '${h['rh_id']}';
                          final tarih = _tarihFmt('${h['tarih'] ?? ''}');
                          final saat = '${h['saat'] ?? ''}';
                          final saatKisa = saat.length >= 5 ? saat.substring(0, 5) : saat;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('$tarih $saatKisa',
                                  style: const TextStyle(color: _text, fontWeight: FontWeight.w600, fontSize: 13)),
                              Text('${h['musteri'] ?? '-'} • ${h['hizmet'] ?? '-'}',
                                  style: const TextStyle(color: _muted, fontSize: 12)),
                              const SizedBox(height: 4),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: _personelDropdown(personeller, secim[rh], (v) {
                                  setLocal(() => secim[rh] = v!);
                                }),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Vazgeç', style: TextStyle(color: _muted)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tumSecili ? const Color(0xFFDC2626) : _muted,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: tumSecili ? () => Navigator.pop(ctx, secim) : null,
                  child: const Text('Aktar ve Sil'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _personelDropdown(List personeller, String? value, ValueChanged<String?> onChanged) {
    return DropdownButton<String>(
      value: value,
      hint: const Text('Seçiniz', style: TextStyle(fontSize: 13, color: _muted)),
      underline: const SizedBox.shrink(),
      isDense: true,
      items: personeller.map<DropdownMenuItem<String>>((p) {
        return DropdownMenuItem<String>(
          value: '${p['id']}',
          child: Text('${p['personel_adi']}', style: const TextStyle(fontSize: 13, color: _text)),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  String _tarihFmt(String ymd) {
    final parts = ymd.split(' ').first.split('-');
    if (parts.length == 3) return '${parts[2]}.${parts[1]}.${parts[0]}';
    return ymd;
  }

  // === UI yardimcilari ===
  Future<bool?> _onaylat({
    required String baslik,
    required String icerik,
    String onayText = 'Onayla',
    bool tehlikeli = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(baslik, style: const TextStyle(color: _text, fontWeight: FontWeight.w700)),
        content: Text(icerik, style: const TextStyle(color: _text, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç', style: TextStyle(color: _muted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: tehlikeli ? const Color(0xFFDC2626) : _p1,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(onayText),
          ),
        ],
      ),
    );
  }

  void _snack(String mesaj, {required bool basari}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mesaj),
        backgroundColor: basari ? const Color(0xFF15803D) : const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
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
        title: const Text('Personeller', style: TextStyle(color: _text, fontWeight: FontWeight.w600)),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            child: SizedBox(width: 110, child: YukseltButonu(isletme_bilgi: widget.isletmebilgi)),
          ),
          if (Yetki.varMi('personel.prim_hakedis_gor'))
            IconButton(
              tooltip: 'Prim & Hak Ediş',
              icon: const Icon(Icons.payments_outlined, color: _p1),
              onPressed: _initLoading
                  ? null
                  : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PrimHakedis(isletmebilgi: widget.isletmebilgi),
                        ),
                      ),
            ),
          if (Yetki.varMi('personel.ekle_duzenle'))
            IconButton(
              tooltip: 'Yeni Personel',
              icon: const Icon(Icons.person_add_alt_1, color: _p1),
              onPressed: _initLoading ? null : _ekleAc,
            ),
        ],
      ),
      body: _initLoading
          ? const Center(child: CircularProgressIndicator(color: _p1))
          : RefreshIndicator(
              color: _p1,
              onRefresh: _refreshAll,
              child: Builder(builder: (context) {
                final bool isTabletLandscape =
                    MediaQuery.of(context).size.width >= 900 &&
                        MediaQuery.of(context).orientation ==
                            Orientation.landscape;
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
                  children: [
                    _hero(),
                    const SizedBox(height: 10),
                    _tabNavi(),
                    const SizedBox(height: 12),
                    _statlar(),
                    const SizedBox(height: 14),
                    _aramaVeYeniBtn(),
                    const SizedBox(height: 10),
                    if (_listLoading && _liste.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child:
                            Center(child: CircularProgressIndicator(color: _p1)),
                      )
                    else if (_liste.isEmpty)
                      _bosKart()
                    else if (isTabletLandscape)
                      _personelListesi2Col()
                    else
                      ..._liste.map(_personelKarti),
                    if (_totalPages > 1) _pagination(),
                  ],
                );
              }),
            ),
    );
  }

  // === Hero ===
  Widget _hero() {
    return Container(
      decoration: BoxDecoration(
        gradient: _grad,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: _p1.withValues(alpha: 0.22), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.groups_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Personel Yönetimi',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3),
                ),
                SizedBox(height: 3),
                Text(
                  'Çalışma saatleri, prim ve hak edişler',
                  style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 12.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // === Tab benzeri 2'li segment navigasyonu (web tasarimi: Personeller | Prim & Hak Edis) ===
  Widget _tabNavi() {
    // Prim & Hak Ediş yetkisi yoksa tab gozukmesin
    if (!Yetki.varMi('personel.prim_hakedis_gor')) {
      return const SizedBox.shrink();
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
        boxShadow: [BoxShadow(color: _p1.withValues(alpha: 0.04), blurRadius: 6)],
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          // Personeller — aktif
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: _grad,
                borderRadius: BorderRadius.circular(9),
                boxShadow: [BoxShadow(color: _p1.withValues(alpha: 0.18), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, color: Colors.white, size: 15),
                  SizedBox(width: 6),
                  Text('Personeller',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5)),
                ],
              ),
            ),
          ),
          // Prim & Hak Edis — buton (yeni sayfaya gider)
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(9),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PrimHakedis(isletmebilgi: widget.isletmebilgi),
                    ),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 9),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.payments_outlined, color: _muted, size: 15),
                      SizedBox(width: 6),
                      Text('Prim & Hak Ediş',
                          style: TextStyle(color: _muted, fontWeight: FontWeight.w700, fontSize: 12.5)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // === Stat kartlari (4'lu yatay sira, kompakt) ===
  Widget _statlar() {
    return Row(
      children: [
        Expanded(child: _statKart(
          icon: Icons.calendar_today_rounded,
          renk: const Color(0xFF3B82F6),
          label: 'TAKVİMDE',
          value: _statTakvimde,
          valueColor: const Color(0xFF2563EB),
        )),
        const SizedBox(width: 6),
        Expanded(child: _statKart(
          icon: Icons.check_circle_outline,
          renk: const Color(0xFF10B981),
          label: 'AKTİF',
          value: _statAktif,
          valueColor: const Color(0xFF059669),
        )),
        const SizedBox(width: 6),
        Expanded(child: _statKart(
          icon: Icons.pause_circle_outline,
          renk: const Color(0xFF94A3B8),
          label: 'PASİF',
          value: _statPasif,
          valueColor: const Color(0xFF64748B),
        )),
        const SizedBox(width: 6),
        Expanded(child: _statKart(
          icon: Icons.groups_2_outlined,
          renk: _p2,
          label: 'TOPLAM',
          value: _statToplam,
          valueColor: _text,
        )),
      ],
    );
  }

  Widget _statKart({
    required IconData icon,
    required Color renk,
    required String label,
    required int value,
    required Color valueColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
        boxShadow: [BoxShadow(color: _p1.withValues(alpha: 0.04), blurRadius: 6)],
      ),
      padding: const EdgeInsets.fromLTRB(8, 9, 8, 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: renk, size: 14),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(color: _muted, fontSize: 8.5, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
          const SizedBox(height: 2),
          Text(value.toString(),
              style: TextStyle(color: valueColor, fontSize: 16, fontWeight: FontWeight.w800, height: 1)),
        ],
      ),
    );
  }

  // === Arama (Yeni Personel butonu kaldirildi — AppBar'da + ikonu var) ===
  Widget _aramaVeYeniBtn() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: TextField(
        controller: _aramaCtrl,
        style: const TextStyle(color: _text, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Personel ara...',
          hintStyle: TextStyle(color: _muted, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: _p2, size: 20),
          suffixIcon: _aramaCtrl.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close, size: 18, color: _muted),
                  onPressed: () => _aramaCtrl.clear(),
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  // Tablet yatay: personel kartlarini 2 sutuna boler
  Widget _personelListesi2Col() {
    final rows = <Widget>[];
    for (int i = 0; i < _liste.length; i += 2) {
      final left = _personelKarti(_liste[i]);
      final right = i + 1 < _liste.length
          ? _personelKarti(_liste[i + 1])
          : const SizedBox.shrink();
      rows.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: left),
          const SizedBox(width: 10),
          Expanded(child: right),
        ],
      ));
    }
    return Column(children: rows);
  }

  // === Personel karti ===
  Widget _personelKarti(Personel p) {
    final aktif = p.durum == '1' || p.durum == 'true';
    final takvimde = p.takvimde_gorunsun == '1' || p.takvimde_gorunsun == 'true';
    final initial = p.personel_adi.trim().isEmpty
        ? '?'
        : p.personel_adi.trim().substring(0, 1).toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [BoxShadow(color: _p1.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        // Personel detay sayfasi prim/hakedis bilgisi gosteriyor — bu yetki
        // yoksa kart tikina kapali.
        onTap: Yetki.varMi('personel.prim_hakedis_gor')
            ? () => _detayAc(p)
            : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  color: _purpleBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [BoxShadow(color: _p1.withValues(alpha: 0.08), blurRadius: 4)],
                ),
                alignment: Alignment.center,
                child: Text(initial,
                    style: const TextStyle(color: _p1, fontWeight: FontWeight.w700, fontSize: 17)),
              ),
              const SizedBox(width: 12),
              // Ad + telefon + badge'ler
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            p.personel_adi,
                            style: const TextStyle(color: _text, fontWeight: FontWeight.w700, fontSize: 14.5),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (p.unvan.isNotEmpty && p.unvan != 'null') ...[
                          const SizedBox(width: 6),
                          Text('· ${p.unvan}', style: TextStyle(color: _muted, fontSize: 12)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (p.cep_telefon.isNotEmpty && p.cep_telefon != 'null')
                      Row(
                        children: [
                          Icon(Icons.phone, size: 12, color: _muted),
                          const SizedBox(width: 4),
                          Text(p.cep_telefon, style: const TextStyle(color: _text, fontSize: 12.5)),
                        ],
                      ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _badge(
                          icon: aktif ? Icons.check_circle : Icons.pause_circle_filled,
                          text: aktif ? 'Aktif' : 'Pasif',
                          bg: aktif ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                          fg: aktif ? const Color(0xFF15803D) : const Color(0xFF991B1B),
                        ),
                        _badge(
                          icon: takvimde ? Icons.event_available : Icons.event_busy,
                          text: takvimde ? 'Takvimde' : 'Gizli',
                          bg: takvimde ? const Color(0xFFDBEAFE) : const Color(0xFFF3F4F6),
                          fg: takvimde ? const Color(0xFF2563EB) : const Color(0xFF6B7280),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Menu
              _menu(p),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge({required IconData icon, required String text, required Color bg, required Color fg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: fg, size: 11),
          const SizedBox(width: 3),
          Text(text, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _menu(Personel p) {
    final aktif = p.durum == '1' || p.durum == 'true';
    final takvimde = p.takvimde_gorunsun == '1' || p.takvimde_gorunsun == 'true';
    return PopupMenuButton<String>(
      tooltip: 'İşlemler',
      icon: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: _purpleBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.more_vert, color: _p1, size: 18),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      offset: const Offset(0, 36),
      onSelected: (v) {
        switch (v) {
          case 'detay': _detayAc(p); break;
          case 'duzenle': _duzenleAc(p); break;
          case 'satislar': _satislarAc(p); break;
          case 'yetki': _yetkiAc(p); break;
          case 'sifre': _sifreGonder(p); break;
          case 'aktif_pasif': _aktifPasifToggle(p); break;
          case 'takvim': _takvimToggle(p); break;
          case 'yukari': _siraKaydir(p, -1); break;
          case 'asagi': _siraKaydir(p, 1); break;
          case 'sil': _arsivle(p); break;
        }
      },
      itemBuilder: (_) {
        // Yetki bazli menü items
        final duzenleVar = Yetki.varMi('personel.ekle_duzenle');
        final yetkiYonet = Yetki.varMi('personel.yetki_yonet');
        final silVar = Yetki.varMi('personel.sil');
        final detayVar = Yetki.varMi('personel.prim_hakedis_gor');
        return [
          if (detayVar) _menuItem('detay', Icons.visibility_outlined, 'Detaylar'),
          if (duzenleVar) _menuItem('duzenle', Icons.edit_outlined, 'Düzenle'),
          _menuItem('satislar', Icons.shopping_bag_outlined, 'Satışlar'),
          if (yetkiYonet) _menuItem('yetki', Icons.shield_outlined, 'Yetkileri Düzenle'),
          if (duzenleVar) _menuItem('sifre', Icons.password_outlined, 'Şifre Gönder'),
          if (duzenleVar) const PopupMenuDivider(),
          if (duzenleVar) _menuItem(
            'aktif_pasif',
            aktif ? Icons.pause_circle_outline : Icons.play_circle_outline,
            aktif ? 'Pasif Yap' : 'Aktif Yap',
          ),
          if (duzenleVar) _menuItem(
            'takvim',
            takvimde ? Icons.event_busy : Icons.event_available,
            takvimde ? 'Takvimden Gizle' : 'Takvimde Göster',
          ),
          if (duzenleVar) _menuItem('yukari', Icons.arrow_upward, 'Yukarı Taşı'),
          if (duzenleVar) _menuItem('asagi', Icons.arrow_downward, 'Aşağı Taşı'),
          if (silVar) const PopupMenuDivider(),
          if (silVar) _menuItem('sil', Icons.delete_outline, 'Sil', renk: const Color(0xFFDC2626)),
        ];
      },
    );
  }

  PopupMenuItem<String> _menuItem(String v, IconData icon, String label, {Color renk = _text}) {
    return PopupMenuItem<String>(
      value: v,
      child: Row(
        children: [
          Icon(icon, size: 18, color: renk == _text ? _p2 : renk),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: renk, fontSize: 13.5, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // === Bos liste ===
  Widget _bosKart() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Icon(Icons.people_outline, color: _muted.withValues(alpha: 0.5), size: 48),
          const SizedBox(height: 10),
          Text(
            _aramaQ.isEmpty ? 'Henüz personel yok' : 'Sonuç bulunamadı',
            style: const TextStyle(color: _text, fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            _aramaQ.isEmpty ? 'İlk personeli eklemek için + butonuna dokunun' : '"$_aramaQ" için sonuç yok',
            style: TextStyle(color: _muted, fontSize: 12.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // === Pagination ===
  Widget _pagination() {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _pageBtn(
            icon: Icons.chevron_left,
            enabled: _currentPage > 1,
            onTap: () {
              _currentPage--;
              _listeYukle();
            },
          ),
          const SizedBox(width: 14),
          Text('Sayfa $_currentPage / $_totalPages',
              style: const TextStyle(color: _text, fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(width: 14),
          _pageBtn(
            icon: Icons.chevron_right,
            enabled: _currentPage < _totalPages,
            onTap: () {
              _currentPage++;
              _listeYukle();
            },
          ),
        ],
      ),
    );
  }

  Widget _pageBtn({required IconData icon, required bool enabled, required VoidCallback onTap}) {
    return Material(
      color: enabled ? _purpleBg : const Color(0xFFF3F4F6),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: enabled ? _p1 : _muted, size: 20),
        ),
      ),
    );
  }
}

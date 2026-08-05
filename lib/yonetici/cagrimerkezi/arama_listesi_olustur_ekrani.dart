// Cagri Merkezi — Arama Listesi Olustur (yonetici).
// Web paneldeki /isletmeyonetim/arama-dashboard "Arama Listesi Oluştur" modalinin
// (modaldialogs/arama_listesi_ekle.blade.php) mobil karsiligi. Ayni backend uclari:
//   POST /filtre-onizleme  -> canli "X musteri eslesti" + secilebilir liste
//   GET  /personeller      -> atanacak personel dropdown'u
//   POST /liste-ekle       -> listeyi olustur

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:randevu_sistem/theme/app_tokens.dart';
import 'cagri_api.dart';
import 'cagri_models.dart';

class AramaListesiOlusturEkrani extends StatefulWidget {
  final String sube;

  const AramaListesiOlusturEkrani({super.key, required this.sube});

  @override
  State<AramaListesiOlusturEkrani> createState() =>
      _AramaListesiOlusturEkraniState();
}

class _AramaListesiOlusturEkraniState extends State<AramaListesiOlusturEkrani> {
  // ── Ust alanlar ──
  final _baslikCtrl = TextEditingController();
  List<CagriPersonel> _personeller = [];
  int? _secilenPersonel;
  bool _personelYukleniyor = true;
  DateTime _tarih = DateTime.now();

  // ── Filtreler (web modaliyla ayni anahtarlar) ──
  String _kayit = '';
  DateTime? _kayitT1;
  DateTime? _kayitT2;
  String _durum = '';
  String _gelmeyen = '';
  String _satis = '';
  String _cinsiyet = '';
  final _dogumgunuCtrl = TextEditingController();
  bool _karaListeHaric = true;
  bool _whatsappOnay = false;
  bool _hicRandevuYok = false;
  bool _iptalEden = false;

  // ── Musteri arama / secim ──
  final _aramaCtrl = TextEditingController();
  final _basCtrl = TextEditingController();
  final _bitCtrl = TextEditingController();
  String _search = '';
  final _customerScroll = ScrollController();

  // ── Onizleme durumu ──
  int _total = 0;
  int _toplamFiltresiz = 0;
  List<int> _tumIdler = [];
  List<FiltreMusteri> _customers = [];
  final Set<int> _secili = {};
  bool _filtreYukleniyor = false;
  bool _listeYukleniyor = false; // sayfalama / arama sirasinda
  int _page = 1;
  bool _aralikModu = false;
  int _sonrakiBaslangic = 0;
  String? _topluBilgi;

  bool _kaydediyor = false;

  Timer? _debounce;
  static const int _perPage = 100;

  @override
  void initState() {
    super.initState();
    _personelleriYukle();
    _filtreUygula();
    _customerScroll.addListener(_scrollDinle);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _baslikCtrl.dispose();
    _dogumgunuCtrl.dispose();
    _aramaCtrl.dispose();
    _basCtrl.dispose();
    _bitCtrl.dispose();
    _customerScroll.dispose();
    super.dispose();
  }

  // ───────── Yardimcilar ─────────

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _fmtTr(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  Map<String, dynamic> _filtreMap() => {
        'kayit': _kayit,
        'kayit_t1': _kayitT1 != null ? _fmt(_kayitT1!) : '',
        'kayit_t2': _kayitT2 != null ? _fmt(_kayitT2!) : '',
        'durum': _durum,
        'gelmeyen': _gelmeyen,
        'satis': _satis,
        'cinsiyet': _cinsiyet,
        'dogumgunu_yaklasan': _dogumgunuCtrl.text.trim(),
        'kara_liste_haric': _karaListeHaric ? 1 : 0,
        'whatsapp_onay': _whatsappOnay ? 1 : 0,
        'hic_randevu_yok': _hicRandevuYok ? 1 : 0,
        'iptal_eden': _iptalEden ? 1 : 0,
        'search': _search,
      };

  void _filtreDegisti() {
    _bagimliliklariUygula();
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _filtreUygula);
  }

  // Celiskili filtre kombinasyonlarini engelle (web filtreBagimliliklari ozeti).
  void _bagimliliklariUygula() {
    // Pasif = satis yok -> "Satis Yapilmis" ile celisir.
    if (_durum == 'pasif' && _satis == 'var') _satis = '';
    // "Hic randevu almamis" -> gelmeyen / iptal eden imkansiz.
    if (_hicRandevuYok) {
      _gelmeyen = '';
      _iptalEden = false;
    }
  }

  // ───────── API cagrilari ─────────

  Future<void> _personelleriYukle() async {
    try {
      final list = await CagriApi.personeller(widget.sube);
      if (!mounted) return;
      setState(() {
        _personeller = list;
        _personelYukleniyor = false;
      });
    } catch (_) {
      if (mounted) setState(() => _personelYukleniyor = false);
    }
  }

  // Filtre degisti: secim SIFIRLANIR, ilk sayfa taze yuklenir.
  Future<void> _filtreUygula() async {
    setState(() {
      _filtreYukleniyor = true;
      _page = 1;
      _aralikModu = false;
      _topluBilgi = null;
    });
    try {
      final r = await CagriApi.filtreOnizleme(
        sube: widget.sube,
        filtre: _filtreMap(),
        page: 1,
        perPage: _perPage,
      );
      if (!mounted) return;
      setState(() {
        _total = r.total;
        _toplamFiltresiz = r.toplamFiltresiz;
        _tumIdler = r.musteriIdler;
        _customers = r.customers;
        _secili.clear(); // varsayilan: hicbiri secili degil
        _sonrakiBaslangic = 0;
        _filtreYukleniyor = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _filtreYukleniyor = false);
      _snack('Filtre uygulanamadı: $e');
    }
  }

  // Sadece arama: eslesenleri listeler, SECIMI DEGISTIRMEZ (birikerek secim).
  Future<void> _aramaYap() async {
    setState(() {
      _listeYukleniyor = true;
      _page = 1;
      _aralikModu = false;
    });
    try {
      final r = await CagriApi.filtreOnizleme(
        sube: widget.sube,
        filtre: _filtreMap(),
        page: 1,
        perPage: _perPage,
      );
      if (!mounted) return;
      setState(() {
        _total = r.total;
        _customers = r.customers;
        _listeYukleniyor = false;
      });
    } catch (_) {
      if (mounted) setState(() => _listeYukleniyor = false);
    }
  }

  Future<void> _dahaFazla() async {
    if (_listeYukleniyor || _aralikModu) return;
    if (_customers.length >= _total) return;
    setState(() => _listeYukleniyor = true);
    final next = _page + 1;
    try {
      final r = await CagriApi.filtreOnizleme(
        sube: widget.sube,
        filtre: _filtreMap(),
        page: next,
        perPage: _perPage,
      );
      if (!mounted) return;
      setState(() {
        _page = next;
        _customers = [..._customers, ...r.customers];
        _listeYukleniyor = false;
      });
    } catch (_) {
      if (mounted) setState(() => _listeYukleniyor = false);
    }
  }

  void _scrollDinle() {
    if (_aralikModu) return;
    if (_customerScroll.position.pixels >=
        _customerScroll.position.maxScrollExtent - 60) {
      _dahaFazla();
    }
  }

  // Tumunu sec: filtreye uyan TUM id'ler (tek istekte gelir).
  Future<void> _tumunuSec() async {
    setState(() => _listeYukleniyor = true);
    try {
      final r = await CagriApi.filtreOnizleme(
        sube: widget.sube,
        filtre: _filtreMap(),
        page: 1,
        perPage: 1,
      );
      if (!mounted) return;
      setState(() {
        _tumIdler = r.musteriIdler;
        _secili
          ..clear()
          ..addAll(_tumIdler);
        _sonrakiBaslangic = _tumIdler.length;
        _aralikModu = false;
        _topluBilgi = 'Tümü seçildi (${_tumIdler.length})';
        _listeYukleniyor = false;
      });
    } catch (_) {
      if (mounted) setState(() => _listeYukleniyor = false);
    }
  }

  void _tumunuKaldir() {
    setState(() {
      _secili.clear();
      _sonrakiBaslangic = 0;
      _topluBilgi = null;
    });
  }

  // [bas..bit] (1-tabanli) araligini sec ve o dilimi listede goster.
  Future<void> _araligiSec(int bas, int bit) async {
    if (_tumIdler.isEmpty) return;
    if (bas < 1) bas = 1;
    if (bit < bas) bit = bas;
    if (bit > _tumIdler.length) bit = _tumIdler.length;
    final dilim = _tumIdler.sublist(bas - 1, bit);
    setState(() {
      _secili
        ..clear()
        ..addAll(dilim);
      _sonrakiBaslangic = bit;
      _aralikModu = true;
      _listeYukleniyor = true;
      _topluBilgi = '$bas–$bit. sıradaki ${dilim.length} müşteri seçildi ✓';
    });
    try {
      final r = await CagriApi.filtreOnizleme(
        sube: widget.sube,
        filtre: _filtreMap(),
        offset: bas - 1,
        limit: dilim.length,
      );
      if (!mounted) return;
      setState(() {
        _customers = r.customers;
        _listeYukleniyor = false;
      });
      if (_customerScroll.hasClients) _customerScroll.jumpTo(0);
    } catch (_) {
      if (mounted) setState(() => _listeYukleniyor = false);
    }
  }

  Future<void> _kaydet() async {
    if (_secilenPersonel == null) {
      _snack('Listeyi oluşturmadan önce aramayı yapacak personeli seçin.');
      return;
    }
    if (_baslikCtrl.text.trim().isEmpty) {
      _snack('Lütfen liste için bir başlık yazın (örn. 1. Gün).');
      return;
    }
    if (_secili.isEmpty) {
      _snack('Lütfen en az bir müşteri seçin.');
      return;
    }
    setState(() => _kaydediyor = true);
    try {
      final mesaj = await CagriApi.listeEkle(
        sube: widget.sube,
        aramaBasligi: _baslikCtrl.text.trim(),
        aramapersoneli: _secilenPersonel!,
        aranacakTarih: _fmt(_tarih),
        secilenMusteriler: _secili.toList(),
        filtre: _filtreMap(),
      );
      if (!mounted) return;
      setState(() => _kaydediyor = false);
      _snack(mesaj);
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _kaydediyor = false);
      _snack('Liste oluşturulamadı: $e');
    }
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(m)));
  }

  // ───────── UI ─────────

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        foregroundColor: cs.onSurface,
        title: const Text('Arama Listesi Oluştur',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
        children: [
          _ustAlanlar(),
          const SizedBox(height: 18),
          _filtreKarti(),
          const SizedBox(height: 18),
          _musteriSecimKarti(),
        ],
      ),
      bottomNavigationBar: _altBar(),
    );
  }

  Widget _ustAlanlar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _etiket('Liste Başlığı'),
        TextField(
          controller: _baslikCtrl,
          decoration: _inputDecoration('Örn: 1. Gün Aramaları'),
        ),
        const SizedBox(height: 14),
        _etiket('Atanacak Personel'),
        _personelDropdown(),
        const SizedBox(height: 14),
        _etiket('Aranacak Tarih'),
        InkWell(
          onTap: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: _tarih,
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
            );
            if (d != null) setState(() => _tarih = d);
          },
          child: InputDecorator(
            decoration: _inputDecoration(''),
            child: Row(
              children: [
                Icon(Icons.calendar_today,
                    size: 16, color: context.colors.onSurfaceVariant),
                const SizedBox(width: 10),
                Text(_fmtTr(_tarih)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _personelDropdown() {
    final cs = context.colors;
    if (_personelYukleniyor) {
      return InputDecorator(
        decoration: _inputDecoration(''),
        child: Row(
          children: [
            const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: 10),
            Text('Yükleniyor…',
                style: TextStyle(color: cs.onSurfaceVariant)),
          ],
        ),
      );
    }
    return DropdownButtonFormField<int>(
      value: _secilenPersonel,
      isExpanded: true,
      decoration: _inputDecoration('Personel seçin…'),
      hint: const Text('Personel seçin…'),
      items: _personeller
          .map((p) => DropdownMenuItem(value: p.id, child: Text(p.ad)))
          .toList(),
      onChanged: (v) => setState(() => _secilenPersonel = v),
    );
  }

  Widget _filtreKarti() {
    final cs = context.colors;
    final ext = context.appTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: ext.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_alt, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Text('Müşteri Filtreleri',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: cs.primary)),
            ],
          ),
          const SizedBox(height: 14),
          _etiket('Kayıt Durumu'),
          _drop(_kayit, const {
            '': 'Tümü',
            'son1yil': 'Son 1 Yılda Eklenen',
            'ozel': 'Özel Tarih Aralığı',
          }, (v) => setState(() {
                _kayit = v;
                if (v != 'ozel') {
                  _kayitT1 = null;
                  _kayitT2 = null;
                }
                _filtreDegisti();
              })),
          if (_kayit == 'ozel') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _tarihAlan('Başlangıç', _kayitT1,
                        (d) => setState(() {
                              _kayitT1 = d;
                              _filtreDegisti();
                            }))),
                const SizedBox(width: 10),
                Expanded(
                    child: _tarihAlan('Bitiş', _kayitT2, (d) => setState(() {
                          _kayitT2 = d;
                          _filtreDegisti();
                        }))),
              ],
            ),
          ],
          const SizedBox(height: 12),
          _etiket('Müşteri Durumu'),
          _drop(_durum, const {
            '': 'Tümü',
            'sadik': 'Sadık (3+ işlem)',
            'aktif': 'Aktif (1-2 işlem)',
            'pasif': 'Pasif (hiç işlem yok)',
          }, (v) => setState(() {
                _durum = v;
                _filtreDegisti();
              })),
          const SizedBox(height: 12),
          _etiket('Gelmeyen Müşteriler'),
          _drop(_gelmeyen, {
            '': 'Tümü',
            '15': 'Son 15 gündür gelmeyen',
            '30': 'Son 30 gündür gelmeyen',
            '60': 'Son 60 gündür gelmeyen',
            '90': 'Son 90 gündür gelmeyen',
          }, (v) => setState(() {
                _gelmeyen = v;
                _filtreDegisti();
              }), kilitli: _hicRandevuYok),
          const SizedBox(height: 12),
          _etiket('Satış Durumu'),
          _drop(_satis, const {
            '': 'Tümü',
            'var': 'Satış Yapılmış',
            'yok': 'Satış Yapılmamış',
          }, (v) => setState(() {
                _satis = v;
                _filtreDegisti();
              })),
          const SizedBox(height: 12),
          _etiket('Cinsiyet'),
          _drop(_cinsiyet, const {
            '': 'Tümü',
            '0': 'Kadın',
            '1': 'Erkek',
          }, (v) => setState(() {
                _cinsiyet = v;
                _filtreDegisti();
              })),
          const SizedBox(height: 12),
          _etiket('Doğum Günü Yaklaşan (gün)'),
          TextField(
            controller: _dogumgunuCtrl,
            keyboardType: TextInputType.number,
            decoration: _inputDecoration('örn: 7'),
            onChanged: (_) => _filtreDegisti(),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _cip('Kara liste hariç', _karaListeHaric,
                  (v) => setState(() {
                        _karaListeHaric = v;
                        _filtreDegisti();
                      })),
              _cip('WhatsApp onaylı', _whatsappOnay, (v) => setState(() {
                    _whatsappOnay = v;
                    _filtreDegisti();
                  })),
              _cip('Hiç randevu almamış', _hicRandevuYok,
                  (v) => setState(() {
                        _hicRandevuYok = v;
                        _filtreDegisti();
                      })),
              _cip('Randevu iptal eden', _iptalEden,
                  kilitli: _hicRandevuYok, (v) => setState(() {
                        _iptalEden = v;
                        _filtreDegisti();
                      })),
            ],
          ),
          const SizedBox(height: 16),
          _sayac(),
        ],
      ),
    );
  }

  Widget _sayac() {
    final cs = context.colors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: cs.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 54,
            child: _filtreYukleniyor
                ? const Center(
                    child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5)))
                : Text('$_total',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: cs.primary)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('müşteri seçtiğin filtrelere uyuyor',
                    style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface)),
                if (_toplamFiltresiz > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                      'Salonda toplam $_toplamFiltresiz aranabilir müşteri var (filtresiz).',
                      style: TextStyle(
                          fontSize: 12, color: cs.onSurfaceVariant)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _musteriSecimKarti() {
    final cs = context.colors;
    final ext = context.appTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: ext.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _etiket('Müşterileri Seçiniz'),
          Text(
              'Başlangıçta hiçbiri seçili değil — Tümünü Seç / İlk 100 ile toplu seçebilir ya da arayıp tek tek seçebilirsiniz.',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          const SizedBox(height: 12),
          TextField(
            controller: _aramaCtrl,
            decoration: _inputDecoration('🔍 Müşteri arayın...'),
            onChanged: (v) {
              _search = v.trim();
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 400), _aramaYap);
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: OutlinedButton(
                      onPressed: _tumunuSec, child: const Text('Tümünü Seç'))),
              const SizedBox(width: 8),
              Expanded(
                  child: OutlinedButton(
                      onPressed: _tumunuKaldir,
                      child: const Text('Tümünü Kaldır'))),
            ],
          ),
          const SizedBox(height: 8),
          _topluSecBar(),
          if (_topluBilgi != null) ...[
            const SizedBox(height: 6),
            Text(_topluBilgi!,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: cs.primary)),
          ],
          const SizedBox(height: 12),
          _musteriListesi(),
          const SizedBox(height: 8),
          Text('${_secili.length} müşteri seçildi',
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: cs.primary)),
        ],
      ),
    );
  }

  Widget _topluSecBar() {
    final cs = context.colors;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: cs.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text('⚡ Toplu seç:',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                      color: cs.primary)),
              const SizedBox(width: 8),
              _miniBtn('İlk 100', () => _araligiSec(1, 100)),
              const SizedBox(width: 6),
              _miniBtn(
                  'Sonraki 100',
                  _sonrakiBaslangic >= _tumIdler.length
                      ? null
                      : () => _araligiSec(
                          _sonrakiBaslangic + 1, _sonrakiBaslangic + 100)),
            ],
          ),
          const SizedBox(height: 8),
          _aralikGiris(),
        ],
      ),
    );
  }

  Widget _aralikGiris() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _basCtrl,
            keyboardType: TextInputType.number,
            decoration: _inputDecoration('baş.'),
          ),
        ),
        const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8), child: Text('–')),
        Expanded(
          child: TextField(
            controller: _bitCtrl,
            keyboardType: TextInputType.number,
            decoration: _inputDecoration('bit.'),
          ),
        ),
        const SizedBox(width: 8),
        _miniBtn('Seç', () {
          final bas = int.tryParse(_basCtrl.text.trim());
          final bit = int.tryParse(_bitCtrl.text.trim());
          if (bas == null && bit == null) {
            _snack('Başlangıç/bitiş sıra girin.');
            return;
          }
          _araligiSec(bas ?? 1, bit ?? _tumIdler.length);
        }),
      ],
    );
  }

  Widget _musteriListesi() {
    final cs = context.colors;
    final ext = context.appTheme;
    return Container(
      height: 260,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: ext.borderSubtle),
      ),
      child: _filtreYukleniyor && _customers.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _customers.isEmpty
              ? Center(
                  child: Text('Filtreye uyan müşteri yok',
                      style: TextStyle(color: cs.onSurfaceVariant)))
              : Stack(
                  children: [
                    ListView.separated(
                      controller: _customerScroll,
                      itemCount: _customers.length + (_listeYukleniyor ? 1 : 0),
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: ext.borderSubtle),
                      itemBuilder: (context, i) {
                        if (i >= _customers.length) {
                          return const Padding(
                            padding: EdgeInsets.all(12),
                            child: Center(
                                child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))),
                          );
                        }
                        final c = _customers[i];
                        final secili = _secili.contains(c.id);
                        return CheckboxListTile(
                          dense: true,
                          controlAffinity: ListTileControlAffinity.leading,
                          value: secili,
                          onChanged: (v) => setState(() {
                            if (v == true) {
                              _secili.add(c.id);
                            } else {
                              _secili.remove(c.id);
                            }
                          }),
                          title: Text(c.name.isEmpty ? '(İsimsiz)' : c.name,
                              style: const TextStyle(fontSize: 14)),
                        );
                      },
                    ),
                  ],
                ),
    );
  }

  Widget _altBar() {
    final cs = context.colors;
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      child: SizedBox(
        height: 50,
        child: ElevatedButton.icon(
          onPressed: _kaydediyor ? null : _kaydet,
          style: ElevatedButton.styleFrom(
            backgroundColor: cs.primary,
            foregroundColor: cs.onPrimary,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md)),
          ),
          icon: _kaydediyor
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.check_circle),
          label: Text(_kaydediyor ? 'Oluşturuluyor…' : 'Listeyi Oluştur',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }

  // ───────── Kucuk yardimci widget'lar ─────────

  Widget _etiket(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t,
            style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: context.colors.onSurfaceVariant)),
      );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: context.appTheme.borderSubtle),
        ),
      );

  Widget _drop(String value, Map<String, String> secenekler,
      ValueChanged<String> onChanged,
      {bool kilitli = false}) {
    return Opacity(
      opacity: kilitli ? 0.4 : 1,
      child: IgnorePointer(
        ignoring: kilitli,
        child: DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          decoration: _inputDecoration(''),
          items: secenekler.entries
              .map((e) =>
                  DropdownMenuItem(value: e.key, child: Text(e.value)))
              .toList(),
          onChanged: (v) => onChanged(v ?? ''),
        ),
      ),
    );
  }

  Widget _tarihAlan(String etiket, DateTime? deger, ValueChanged<DateTime> onSec) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _etiket(etiket),
        InkWell(
          onTap: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: deger ?? DateTime.now(),
              firstDate: DateTime(2015),
              lastDate: DateTime(2100),
            );
            if (d != null) onSec(d);
          },
          child: InputDecorator(
            decoration: _inputDecoration(''),
            child: Text(deger != null ? _fmtTr(deger) : 'Seç',
                style: TextStyle(
                    color: deger != null
                        ? context.colors.onSurface
                        : context.colors.onSurfaceVariant)),
          ),
        ),
      ],
    );
  }

  Widget _cip(String etiket, bool secili, ValueChanged<bool> onChanged,
      {bool kilitli = false}) {
    final cs = context.colors;
    final ext = context.appTheme;
    return Opacity(
      opacity: kilitli ? 0.4 : 1,
      child: InkWell(
        onTap: kilitli ? null : () => onChanged(!secili),
        borderRadius: BorderRadius.circular(99),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: secili ? cs.primary : cs.surface,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
                color: secili ? cs.primary : ext.borderStrong),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(secili ? Icons.check_circle : Icons.circle_outlined,
                  size: 16,
                  color: secili ? cs.onPrimary : cs.onSurfaceVariant),
              const SizedBox(width: 7),
              Text(etiket,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: secili ? cs.onPrimary : cs.onSurface)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniBtn(String t, VoidCallback? onTap) {
    final cs = context.colors;
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: cs.primary,
        side: BorderSide(color: cs.primary.withValues(alpha: 0.4)),
      ),
      child: Text(t, style: const TextStyle(fontSize: 12.5)),
    );
  }
}

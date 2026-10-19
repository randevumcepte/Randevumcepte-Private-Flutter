// Arama Randevu Takvimi (mobil sekme).
// Web paneldeki "Arama Randevu Takvimi" cockpit'inin mobil karsiligi:
//   - Tarih secici (gun bazli)
//   - Musteri arama (ad'a gore, gelen gun olaylari icinde)
//   - Durum filtreleri (renk/segment)
//   - Personele gore gruplanmis, saate gore sirali arama randevusu kartlari
//   - Karta dokun -> islem sayfasi (Ara-Bria / Randevu Olusturuldu / Iptal / Randevu Gecmisi)
//   - "Arama Randevusu Ekle" (musteri + personel + tarih/saat)
//
// Arama: WebRTC YOK. CagriApi.aramaBaslat -> santral AMI originate -> personelin
// Bria dahilisi calar -> acinca musteriye baglanir (numara cihaza gitmez, KVKK).

import 'package:flutter/material.dart';
import 'package:randevu_sistem/Frontend/aramali_dropdown.dart';
import 'package:randevu_sistem/yonetici/randevular/appointment-editor.dart';
import 'package:randevu_sistem/yonetici/randevular/saat_secici.dart';
import 'package:randevu_sistem/yonetici/diger/menu/ongorusmeler/ongorusmeekle.dart';
import 'package:randevu_sistem/Frontend/sfdatatable.dart';
import 'cagri_api.dart';
import 'widgets/hizli_satis_sheet.dart';
import 'cagri_models.dart';
import 'widgets/sonuc_formu.dart';
import 'widgets/randevu_gecmisi.dart';

class AramaRandevuTakvimi extends StatefulWidget {
  final dynamic isletmebilgi;
  final int kullanicirolu;
  const AramaRandevuTakvimi({
    Key? key,
    required this.isletmebilgi,
    required this.kullanicirolu,
  }) : super(key: key);

  @override
  State<AramaRandevuTakvimi> createState() => _AramaRandevuTakvimiState();
}

class _AramaRandevuTakvimiState extends State<AramaRandevuTakvimi> {
  late final String _sube;
  DateTime _tarih = DateTime.now();
  bool _yukleniyor = true;
  String? _hata;
  List<TakvimEvent> _olaylar = [];
  String _ara = '';
  String? _filtreRenk; // null = tumu

  @override
  void initState() {
    super.initState();
    _sube = widget.isletmebilgi['id'].toString();
    _yukle();
  }

  String _iki(int n) => n < 10 ? '0$n' : '$n';
  String _ymd(DateTime d) => '${d.year}-${_iki(d.month)}-${_iki(d.day)}';
  String _gunBaslik(DateTime d) {
    const aylar = ['', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
    const gunler = ['', 'Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma',
      'Cumartesi', 'Pazar'];
    return '${d.day} ${aylar[d.month]} ${d.year}, ${gunler[d.weekday]}';
  }

  Color _renk(String hex) {
    var h = hex.replaceAll('#', '').trim();
    if (h.length == 6) h = 'FF$h';
    return Color(int.tryParse(h, radix: 16) ?? 0xFF2563EB);
  }

  Future<void> _yukle() async {
    if (mounted) setState(() { _yukleniyor = true; _hata = null; });
    try {
      final gun = _ymd(_tarih);
      final list = await CagriApi.takvimVerileri(_sube, start: gun, end: gun);
      if (mounted) setState(() { _olaylar = list; _yukleniyor = false; });
    } catch (e) {
      if (mounted) setState(() {
        _hata = e is CagriApiException
            ? '(${e.statusCode}) ${e.message}'
            : 'Yüklenirken hata oluştu: $e';
        _yukleniyor = false;
      });
    }
  }

  void _tarihDegistir(int gunFark) {
    setState(() => _tarih = _tarih.add(Duration(days: gunFark)));
    _yukle();
  }

  Future<void> _tarihSec() async {
    final secilen = await showDatePicker(
      context: context,
      initialDate: _tarih,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('tr', 'TR'),
    );
    if (secilen != null) {
      setState(() => _tarih = secilen);
      _yukle();
    }
  }

  // Filtre + arama uygulanmis liste
  List<TakvimEvent> get _filtreli {
    final q = _ara.trim().toLowerCase();
    return _olaylar.where((e) {
      if (_filtreRenk != null && e.color != _filtreRenk) return false;
      if (q.isNotEmpty && !e.musteri.toLowerCase().contains(q)) return false;
      return true;
    }).toList();
  }

  // Durum renk sayaclari (segment chip'leri)
  List<_Segment> get _segmentler {
    final Map<String, _Segment> m = {};
    for (final e in _olaylar) {
      final s = m.putIfAbsent(
          e.color, () => _Segment(e.color, e.durumMetin, 0));
      s.adet++;
    }
    final list = m.values.toList();
    list.sort((a, b) => b.adet.compareTo(a.adet));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final filtreli = _filtreli;
    // Personele gore grupla
    final Map<int, List<TakvimEvent>> grup = {};
    for (final e in filtreli) {
      grup.putIfAbsent(e.personelId, () => []).add(e);
    }
    final pidler = grup.keys.toList()
      ..sort((a, b) => (grup[a]!.first.personel)
          .toLowerCase()
          .compareTo(grup[b]!.first.personel.toLowerCase()));

    return Column(
      children: [
        // Tarih seridi
        Container(
          color: const Color(0xFFF7F3FC),
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _tarihDegistir(-1),
              ),
              Expanded(
                child: InkWell(
                  onTap: _tarihSec,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE7E9F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 16, color: Color(0xFF6D28D9)),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            _gunBaslik(_tarih),
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => _tarihDegistir(1),
              ),
              IconButton(
                icon: const Icon(Icons.today, color: Color(0xFF6D28D9)),
                tooltip: 'Bugün',
                onPressed: () {
                  setState(() => _tarih = DateTime.now());
                  _yukle();
                },
              ),
            ],
          ),
        ),
        // Musteri arama + Ekle
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 2, 10, 6),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Müşteri ara...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onChanged: (v) => setState(() => _ara = v),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6D28D9),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Randevu'),
                onPressed: _aramaRandevusuEkle,
              ),
            ],
          ),
        ),
        // Segment filtreleri
        if (_segmentler.isNotEmpty)
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: [
                _segChip('Tümü', null, _olaylar.length, const Color(0xFF6D28D9)),
                for (final s in _segmentler)
                  _segChip(s.ad, s.renk, s.adet, _renk(s.renk)),
              ],
            ),
          ),
        const SizedBox(height: 4),
        // Govde
        Expanded(
          child: _yukleniyor
              ? const Center(child: CircularProgressIndicator())
              : _hata != null
                  ? ListView(children: [
                      const SizedBox(height: 50),
                      _mesajView(_hata!, Icons.error_outline, Colors.red),
                      const SizedBox(height: 10),
                      Center(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('Tekrar Dene'),
                          onPressed: _yukle,
                        ),
                      ),
                    ])
                  : filtreli.isEmpty
                      ? RefreshIndicator(
                          onRefresh: _yukle,
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              const SizedBox(height: 60),
                              _mesajView('Bu güne ait arama randevusu yok.',
                                  Icons.event_busy, Colors.grey),
                            ],
                          ),
                        )
                      : LayoutBuilder(builder: (ctx, c) {
                          // Personel sutunlari web'deki gibi YAN YANA.
                          // Tek sutun -> tam ekran; coklu -> yatay kaydirmali (~1.6 sutun gorunur).
                          List<TakvimEvent> items0(int pid) =>
                              grup[pid]!..sort((a, b) => a.start.compareTo(b.start));
                          if (pidler.length <= 1) {
                            final items = items0(pidler.first);
                            return RefreshIndicator(
                              onRefresh: _yukle,
                              child: ListView(
                                padding:
                                    const EdgeInsets.fromLTRB(10, 2, 10, 20),
                                children: [
                                  _personelGrubu(items.first.personel, items),
                                ],
                              ),
                            );
                          }
                          final genislik = c.maxWidth * 0.62; // ~1.6 sutun
                          return RefreshIndicator(
                            onRefresh: _yukle,
                            child: ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                SizedBox(
                                  height: c.maxHeight,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.fromLTRB(
                                        10, 2, 4, 20),
                                    itemCount: pidler.length,
                                    itemBuilder: (_, i) {
                                      final items = items0(pidler[i]);
                                      return _personelSutun(
                                          items.first.personel, items, genislik);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
        ),
      ],
    );
  }

  Widget _segChip(String ad, String? renk, int adet, Color c) {
    final aktif = _filtreRenk == renk;
    return Padding(
      padding: const EdgeInsets.only(right: 7),
      child: ChoiceChip(
        label: Text('$ad ($adet)', style: const TextStyle(fontSize: 12)),
        selected: aktif,
        selectedColor: c.withOpacity(.18),
        side: BorderSide(color: aktif ? c : const Color(0xFFE2E2EA)),
        labelStyle: TextStyle(
            color: aktif ? c : Colors.black87,
            fontWeight: aktif ? FontWeight.w700 : FontWeight.w500),
        onSelected: (_) => setState(() => _filtreRenk = aktif ? null : renk),
      ),
    );
  }

  Widget _mesajView(String t, IconData ic, Color c) => Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(ic, size: 44, color: c.withOpacity(.6)),
              const SizedBox(height: 10),
              Text(t,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: c, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );

  // Sutun basligi (mor seritte personel adi + adet).
  Widget _sutunBaslik(String personel, int adet) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: const BoxDecoration(
          color: Color(0xFF6D28D9),
          borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(personel,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
              decoration: BoxDecoration(
                  color: Colors.white24, borderRadius: BorderRadius.circular(20)),
              child: Text('$adet',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );

  // Tek sutun (tam ekran) — dikey kartlar icerige gore uzar.
  Widget _personelGrubu(String personel, List<TakvimEvent> items) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDE7F6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sutunBaslik(personel, items.length),
          for (final e in items) _olayKart(e),
        ],
      ),
    );
  }

  // Coklu sutun (yan yana) — sabit genislik, kendi icinde dikey kaydirmali.
  Widget _personelSutun(
      String personel, List<TakvimEvent> items, double genislik) {
    return Container(
      width: genislik,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDE7F6)),
      ),
      child: Column(
        children: [
          _sutunBaslik(personel, items.length),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [for (final e in items) _olayKart(e)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _olayKart(TakvimEvent e) {
    final c = _renk(e.color);
    return InkWell(
      onTap: () => _olayIslem(e),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFF1F1F5))),
        ),
        child: Row(
          children: [
            Container(width: 4, height: 38,
                decoration: BoxDecoration(
                    color: c, borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.access_time, size: 13, color: c),
                    const SizedBox(width: 4),
                    Text(e.saat,
                        style: TextStyle(
                            color: c,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                  ]),
                  const SizedBox(height: 2),
                  Text(e.musteri.isEmpty ? 'Müşteri' : e.musteri,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: c.withOpacity(.12),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(e.durumMetin,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: c, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  // ───────── Islem sayfasi (bottom sheet) ─────────
  void _olayIslem(TakvimEvent e) {
    if (e.islenmis) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Bu arama "${e.durumMetin}" olarak işlendi.'),
        duration: const Duration(seconds: 2),
      ));
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (_) => _IslemSheet(
        event: e,
        sube: _sube,
        isletmebilgi: widget.isletmebilgi,
        kullanicirolu: widget.kullanicirolu,
        onDegisti: () {
          Navigator.pop(context);
          _yukle();
        },
      ),
    );
  }

  // ───────── Arama randevusu ekle ─────────
  Future<void> _aramaRandevusuEkle() async {
    final eklendi = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (_) => _RandevuEkleSheet(
          sube: _sube, kullanicirolu: widget.kullanicirolu),
    );
    if (eklendi == true) _yukle();
  }
}

class _Segment {
  final String renk;
  final String ad;
  int adet;
  _Segment(this.renk, this.ad, this.adet);
}

// ══════════════ Islem bottom sheet ══════════════
class _IslemSheet extends StatefulWidget {
  final TakvimEvent event;
  final String sube;
  final dynamic isletmebilgi;
  final int kullanicirolu;
  final VoidCallback onDegisti;
  const _IslemSheet(
      {required this.event,
      required this.sube,
      required this.isletmebilgi,
      required this.kullanicirolu,
      required this.onDegisti});
  @override
  State<_IslemSheet> createState() => _IslemSheetState();
}

class _IslemSheetState extends State<_IslemSheet> {
  bool _islemde = false;

  Future<void> _ara() async {
    setState(() => _islemde = true);
    try {
      final r = await CagriApi.aramaBaslat(widget.event.id, widget.sube);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(r.message.isEmpty
            ? 'Telefonunuz (Bria) çalacak, açın.'
            : r.message),
      ));
    } catch (e) {
      _hataGoster(e);
    } finally {
      if (mounted) setState(() => _islemde = false);
    }
  }

  Future<void> _randevuOlusturuldu() async {
    setState(() => _islemde = true);
    try {
      await CagriApi.randevuOlusturulduIsaretle(widget.event.id, widget.sube);
      if (!mounted) return;
      _basari('Randevu oluşturuldu olarak işaretlendi.');
      widget.onDegisti();
    } catch (e) {
      _hataGoster(e);
      if (mounted) setState(() => _islemde = false);
    }
  }

  Future<void> _iptal() async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Arama randevusu iptal'),
        content: const Text('Bu arama randevusu iptal edilsin mi?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Vazgeç')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('İptal Et')),
        ],
      ),
    );
    if (onay != true) return;
    setState(() => _islemde = true);
    try {
      await CagriApi.aramaRandevuIptal(widget.event.id, widget.sube);
      if (!mounted) return;
      _basari('Arama randevusu iptal edildi.');
      widget.onDegisti();
    } catch (e) {
      _hataGoster(e);
      if (mounted) setState(() => _islemde = false);
    }
  }

  Future<void> _randevuGecmisi() async {
    await randevuGecmisiGoster(context,
        sube: widget.sube,
        userId: widget.event.userId,
        ad: widget.event.musteri);
  }

  // Normal salon randevusu olustur (web "Yeni Randevu Olustur" ile ayni amac):
  // AppointmentEditor'u musteri prefill'li acar; donunce isteyene durum=8 isaretler.
  Future<void> _yeniRandevu() async {
    bool kaydedildi = false;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AppointmentEditor(
          isletmebilgi: widget.isletmebilgi,
          tarihsaat: '',
          personel_id: '',
          kullanicirolu: widget.kullanicirolu,
          prefillMusteriId:
              widget.event.userId > 0 ? widget.event.userId.toString() : null,
          prefillMusteriAdi: widget.event.musteri,
          onRandevuKaydedildi: () => kaydedildi = true,
        ),
      ),
    );
    if (!mounted || !kaydedildi) return;
    // NORMAL randevu -> "Randevu Verildi" bayragi (durum=8 DEGIL, listeden cikarmaz).
    // Takvimdeki "Randevu Olusturuldu" butonu callback'i durum=8 ile tamamlamaya devam eder.
    try {
      await CagriApi.randevuVerildiIsaretle(widget.event.id, widget.sube);
      _basari('Randevu oluşturuldu.');
      widget.onDegisti();
    } catch (e) {
      _hataGoster(e);
    }
  }

  // Ön Görüşme Randevusu (web gibi GERCEK olusturma): YeniOnGorusme ekranini musteri
  // prefill'li acar; kayitta aranacak durum=6 isaretlenir + sheet kapanir/tazelenir.
  Future<void> _onGorusmeAc() async {
    final ds = OnGorusmeDataSource(
      isletmebilgi: widget.isletmebilgi,
      rowsPerPage: 10,
      salonid: widget.sube,
      context: context,
      arama: '',
    );
    bool kaydedildi = false;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => YeniOnGorusme(
          ongorusmedatasource: ds,
          isletmebilgi: widget.isletmebilgi,
          kullanicirolu: widget.kullanicirolu,
          prefillMusteriId:
              widget.event.userId > 0 ? widget.event.userId.toString() : null,
          prefillMusteriAdi: widget.event.musteri,
          onKaydedildi: () => kaydedildi = true,
        ),
      ),
    );
    if (!mounted || !kaydedildi) return;
    try {
      await CagriApi.notEkle(
        aramaDetayId: widget.event.aramaId,
        aranacakMusteriId: widget.event.id,
        sonuc: CagriDurum.onGorusme, // 6
        sube: widget.sube,
      );
      widget.onDegisti(); // sheet kapat + takvim tazele
    } catch (e) {
      _hataGoster(e);
    }
  }

  // Telefonda Satis (web gibi GERCEK satis): Hizli Satis sheet -> adisyon/tahsilat;
  // basarili ise aranacak durum=7 isaretlenir + sheet kapanir/tazelenir.
  Future<void> _telefondaSatisAc() async {
    if (widget.event.userId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Bu kayıtta müşteri bağlantısı yok, satış yapılamıyor.')));
      return;
    }
    final tutar = await hizliSatisGoster(context,
        sube: widget.sube,
        musteriId: widget.event.userId,
        musteriAd: widget.event.musteri);
    if (!mounted || tutar == null) return;
    try {
      await CagriApi.notEkle(
        aramaDetayId: widget.event.aramaId,
        aranacakMusteriId: widget.event.id,
        sonuc: CagriDurum.telefondaSatis, // 7
        satisTutari: tutar.toStringAsFixed(2),
        sube: widget.sube,
      );
      widget.onDegisti();
    } catch (e) {
      _hataGoster(e);
    }
  }

  void _basari(String m) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), backgroundColor: const Color(0xFF16A34A)));

  void _hataGoster(Object e) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(e is CagriApiException ? e.message : 'İşlem başarısız.'),
          backgroundColor: Colors.red));

  @override
  Widget build(BuildContext context) {
    final e = widget.event;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scroll) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Center(
                child: Container(width: 40, height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(3))),
              ),
              Expanded(
                child: ListView(
                  controller: scroll,
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  children: [
                    Text(e.musteri.isEmpty ? 'Müşteri' : e.musteri,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text('${e.personel} · ${e.saat}'
                        '${e.telefon.isNotEmpty ? ' · ${e.telefon}' : ''}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    const SizedBox(height: 12),
                    // Ust aksiyonlar: Ara (Bria) + Randevu Gecmisi (web header gibi)
                    Row(children: [
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF16A34A),
                                foregroundColor: Colors.white),
                            icon: const Icon(Icons.phone, size: 18),
                            label: const Text('Ara (Bria)',
                                style: TextStyle(fontWeight: FontWeight.w700)),
                            onPressed: _islemde ? null : _ara,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.history, size: 18),
                            label: const Text('Randevu Geçmişi'),
                            onPressed: e.userId > 0 ? _randevuGecmisi : null,
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    // Normal salon randevusu olustur (web "Yeni Randevu Olustur")
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1D4ED8),
                          backgroundColor: const Color(0xFFEFF6FF),
                          side: const BorderSide(color: Color(0xFFBFDBFE)),
                        ),
                        icon: const Icon(Icons.calendar_month, size: 18),
                        label: const Text('Yeni Randevu Oluştur',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                        onPressed: _islemde ? null : _yeniRandevu,
                      ),
                    ),
                    const Divider(height: 24),
                    // TAM gorusme sonucu formu GOMULU (web gibi tek sheet) —
                    // Gorusuldu/Cevapsiz/Mesgul/Ulasilamadi + On Gorusme + Satis +
                    // Arama Randevusu Ver + not + Sonucu Kaydet.
                    SonucFormuGovde(
                      aramaDetayId: e.aramaId,
                      aranacakMusteriId: e.id,
                      sube: widget.sube,
                      mevcutNot: e.not,
                      onKaydedildi: widget.onDegisti, // sheet'i kapat + takvimi tazele
                      onOnGorusmeTap: _onGorusmeAc,
                      onTelefondaSatisTap: _telefondaSatisAc,
                    ),
                    const SizedBox(height: 10),
                    // Takvim'e ozel randevu durum aksiyonlari (web: İptal Et / Randevu Olusturuldu)
                    Row(children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.event_available, size: 18),
                          label: const Text('Randevu Oluşturuldu'),
                          onPressed: _islemde ? null : _randevuOlusturuldu,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                          icon: const Icon(Icons.cancel, size: 18),
                          label: const Text('İptal Et'),
                          onPressed: _islemde ? null : _iptal,
                        ),
                      ),
                    ]),
                    if (_islemde) ...[
                      const SizedBox(height: 12),
                      const Center(child: CircularProgressIndicator()),
                    ],
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════ Arama randevusu ekle sheet ══════════════
class _RandevuEkleSheet extends StatefulWidget {
  final String sube;
  final int kullanicirolu;
  const _RandevuEkleSheet(
      {required this.sube, required this.kullanicirolu});
  @override
  State<_RandevuEkleSheet> createState() => _RandevuEkleSheetState();
}

class _RandevuEkleSheetState extends State<_RandevuEkleSheet> {
  final _notCtrl = TextEditingController();
  final _araCtrl = TextEditingController();
  List<MusteriSecenek> _musteriSonuc = [];
  MusteriSecenek? _musteri;
  List<CagriPersonel> _personeller = [];
  CagriPersonel? _personel;
  DateTime? _tarih;
  TimeOfDay? _saat;
  bool _araniyor = false;
  bool _kaydediyor = false;

  @override
  void initState() {
    super.initState();
    _personelleriYukle();
  }

  @override
  void dispose() {
    _notCtrl.dispose();
    _araCtrl.dispose();
    super.dispose();
  }

  Future<void> _personelleriYukle() async {
    try {
      final p = await CagriApi.personeller(widget.sube);
      if (mounted) setState(() => _personeller = p);
    } catch (_) {}
  }

  Future<void> _musteriAra(String q) async {
    if (q.trim().length < 2) {
      setState(() => _musteriSonuc = []);
      return;
    }
    setState(() => _araniyor = true);
    try {
      final r = await CagriApi.musteriSelect(widget.sube, q.trim());
      if (mounted) setState(() { _musteriSonuc = r; _araniyor = false; });
    } catch (_) {
      if (mounted) setState(() => _araniyor = false);
    }
  }

  String _iki(int n) => n < 10 ? '0$n' : '$n';

  Future<void> _kaydet() async {
    if (_musteri == null || _personel == null || _tarih == null || _saat == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Müşteri, personel, tarih ve saat seçin.')));
      return;
    }
    setState(() => _kaydediyor = true);
    try {
      final r = await CagriApi.aramaRandevuEkle(
        sube: widget.sube,
        musteriId: _musteri!.id,
        personelId: _personel!.id,
        tarih: '${_tarih!.year}-${_iki(_tarih!.month)}-${_iki(_tarih!.day)}',
        saat: '${_iki(_saat!.hour)}:${_iki(_saat!.minute)}',
        not: _notCtrl.text.trim().isEmpty ? null : _notCtrl.text.trim(),
      );
      if (!mounted) return;
      if (r.success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(r.message.isEmpty ? 'Arama randevusu eklendi.' : r.message),
            backgroundColor: const Color(0xFF16A34A)));
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(r.message.isEmpty ? 'Eklenemedi.' : r.message),
            backgroundColor: Colors.red));
        setState(() => _kaydediyor = false);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e is CagriApiException ? e.message : 'Eklenemedi.'),
          backgroundColor: Colors.red));
      setState(() => _kaydediyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16, right: 16, top: 14),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(3))),
            ),
            const SizedBox(height: 12),
            const Text('Arama Randevusu Ekle',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            // Musteri secimi
            if (_musteri != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.person, color: Color(0xFF6D28D9)),
                title: Text(_musteri!.text),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _musteri = null),
                ),
              )
            else ...[
              TextField(
                controller: _araCtrl,
                decoration: InputDecoration(
                  labelText: 'Müşteri ara (ad / telefon)',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _araniyor
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2)))
                      : null,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onChanged: _musteriAra,
              ),
              if (_musteriSonuc.isNotEmpty)
                Container(
                  constraints: const BoxConstraints(maxHeight: 180),
                  margin: const EdgeInsets.only(top: 6),
                  decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE2E2EA)),
                      borderRadius: BorderRadius.circular(10)),
                  child: ListView(
                    shrinkWrap: true,
                    children: _musteriSonuc
                        .map((m) => ListTile(
                              dense: true,
                              title: Text(m.text),
                              onTap: () => setState(() {
                                _musteri = m;
                                _musteriSonuc = [];
                              }),
                            ))
                        .toList(),
                  ),
                ),
            ],
            const SizedBox(height: 12),
            // Personel
            AramaliDropdownFormField<CagriPersonel>(
              value: _personel,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Personel',
                prefixIcon: const Icon(Icons.badge),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: _personeller
                  .map((p) => DropdownMenuItem(value: p, child: Text(p.ad)))
                  .toList(),
              onChanged: (v) => setState(() => _personel = v),
              searchText: (p) => p.ad, // arama personel adi uzerinden
            ),
            const SizedBox(height: 12),
            // Tarih + saat
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(_tarih == null
                      ? 'Tarih'
                      : '${_tarih!.day}.${_iki(_tarih!.month)}.${_tarih!.year}'),
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now().subtract(const Duration(days: 1)),
                      lastDate: DateTime(2100),
                      locale: const Locale('tr', 'TR'),
                    );
                    if (d != null) setState(() => _tarih = d);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.access_time, size: 18),
                  label: Text(_saat == null
                      ? 'Saat'
                      : '${_iki(_saat!.hour)}:${_iki(_saat!.minute)}'),
                  onPressed: () async {
                    final t = await saatSecici(
                        context, _saat ?? const TimeOfDay(hour: 10, minute: 0),
                        minuteInterval: 1);
                    if (t != null) setState(() => _saat = t);
                  },
                ),
              ),
            ]),
            const SizedBox(height: 12),
            TextField(
              controller: _notCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Not (opsiyonel)',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6D28D9),
                    foregroundColor: Colors.white),
                onPressed: _kaydediyor ? null : _kaydet,
                child: _kaydediyor
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Kaydet',
                        style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

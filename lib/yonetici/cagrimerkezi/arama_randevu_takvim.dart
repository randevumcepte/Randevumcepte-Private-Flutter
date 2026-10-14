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
import 'cagri_api.dart';
import 'cagri_models.dart';

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
          child: RefreshIndicator(
            onRefresh: _yukle,
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
                        ? ListView(children: [
                            const SizedBox(height: 60),
                            _mesajView('Bu güne ait arama randevusu yok.',
                                Icons.event_busy, Colors.grey),
                          ])
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(10, 2, 10, 20),
                            itemCount: pidler.length,
                            itemBuilder: (_, i) {
                              final pid = pidler[i];
                              final items = grup[pid]!
                                ..sort((a, b) => a.start.compareTo(b.start));
                              return _personelGrubu(
                                  items.first.personel, items);
                            },
                          ),
          ),
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
          Container(
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                  decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(20)),
                  child: Text('${items.length}',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          for (final e in items) _olayKart(e),
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.access_time, size: 13, color: c),
                  const SizedBox(width: 4),
                  Text(e.saat,
                      style: TextStyle(
                          color: c, fontWeight: FontWeight.w700, fontSize: 13)),
                ]),
                const SizedBox(height: 2),
                Text(e.musteri.isEmpty ? 'Müşteri' : e.musteri,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: c.withOpacity(.12),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(e.durumMetin,
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
  final VoidCallback onDegisti;
  const _IslemSheet(
      {required this.event, required this.sube, required this.onDegisti});
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (_) =>
          _GecmisSheet(sube: widget.sube, userId: widget.event.userId,
              ad: widget.event.musteri),
    );
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
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16, right: 16, top: 14),
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
          Text(e.musteri.isEmpty ? 'Müşteri' : e.musteri,
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text('${e.personel} · ${e.saat}'
              '${e.telefon.isNotEmpty ? ' · ${e.telefon}' : ''}',
              style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          if (e.not.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: const Color(0xFFF7F3FC),
                  borderRadius: BorderRadius.circular(10)),
              child: Text(e.not, style: const TextStyle(fontSize: 13)),
            ),
          ],
          const SizedBox(height: 16),
          if (_islemde)
            const Padding(
              padding: EdgeInsets.all(14),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white),
                icon: const Icon(Icons.phone),
                label: const Text('Ara (Bria)',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                onPressed: _ara,
              ),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.event_available, size: 18),
                  label: const Text('Randevu Oluşturuldu'),
                  onPressed: _randevuOlusturuldu,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red),
                  icon: const Icon(Icons.cancel, size: 18),
                  label: const Text('İptal Et'),
                  onPressed: _iptal,
                ),
              ),
            ]),
            const SizedBox(height: 8),
            TextButton.icon(
              icon: const Icon(Icons.history, size: 18),
              label: const Text('Randevu Geçmişi'),
              onPressed: widget.event.userId > 0 ? _randevuGecmisi : null,
            ),
          ],
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

// ══════════════ Randevu gecmisi sheet ══════════════
class _GecmisSheet extends StatefulWidget {
  final String sube;
  final int userId;
  final String ad;
  const _GecmisSheet(
      {required this.sube, required this.userId, required this.ad});
  @override
  State<_GecmisSheet> createState() => _GecmisSheetState();
}

class _GecmisSheetState extends State<_GecmisSheet> {
  bool _yukleniyor = true;
  String? _hata;
  MusteriRandevuGecmisi? _veri;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    try {
      final v =
          await CagriApi.musteriRandevuGecmisi(widget.sube, widget.userId);
      if (mounted) setState(() { _veri = v; _yukleniyor = false; });
    } catch (e) {
      if (mounted) setState(() {
        _hata = e is CagriApiException ? e.message : 'Geçmiş alınamadı.';
        _yukleniyor = false;
      });
    }
  }

  Color _renk(String hex) {
    var h = hex.replaceAll('#', '').trim();
    if (h.length == 6) h = 'FF$h';
    return Color(int.tryParse(h, radix: 16) ?? 0xFF6D28D9);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.92,
      builder: (_, controller) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: _yukleniyor
            ? const Center(child: CircularProgressIndicator())
            : _hata != null
                ? Center(child: Text(_hata!,
                    style: const TextStyle(color: Colors.red)))
                : ListView(
                    controller: controller,
                    children: [
                      Center(
                        child: Container(width: 40, height: 4,
                            decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(3))),
                      ),
                      const SizedBox(height: 12),
                      Text('Randevu Geçmişi — ${widget.ad}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      Row(children: [
                        _ozetKutu('Geldi', _veri!.geldi, const Color(0xFF16A34A)),
                        const SizedBox(width: 8),
                        _ozetKutu('Gelmedi', _veri!.gelmedi, Colors.red),
                        const SizedBox(width: 8),
                        _ozetKutu('Onaylı', _veri!.onayli, const Color(0xFF2563EB)),
                      ]),
                      const SizedBox(height: 14),
                      if (_veri!.randevular.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(child: Text('Randevu geçmişi yok.')),
                        )
                      else
                        for (final r in _veri!.randevular) _gecmisKart(r),
                    ],
                  ),
      ),
    );
  }

  Widget _ozetKutu(String l, int n, Color c) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
              color: c.withOpacity(.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.withOpacity(.25))),
          child: Column(children: [
            Text('$n',
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800, color: c)),
            Text(l,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[700])),
          ]),
        ),
      );

  Widget _gecmisKart(RandevuGecmisKayit r) {
    final c = _renk(r.renk);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border(left: BorderSide(color: c, width: 4),
              top: const BorderSide(color: Color(0xFFEEEEEE)),
              right: const BorderSide(color: Color(0xFFEEEEEE)),
              bottom: const BorderSide(color: Color(0xFFEEEEEE)))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('${r.tarih} ${r.saat}',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                  color: c.withOpacity(.12),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(r.durumMetin,
                  style: TextStyle(
                      color: c, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ]),
          if (r.hizmet.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(r.hizmet, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
          ],
          if (r.personel.isNotEmpty)
            Text(r.personel,
                style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          if (r.not.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(r.not, style: const TextStyle(fontSize: 12.5)),
          ],
        ],
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
            DropdownButtonFormField<CagriPersonel>(
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
                    final t = await showTimePicker(
                        context: context,
                        initialTime: const TimeOfDay(hour: 10, minute: 0));
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

// Cagri Merkezi — Liste Yonetimi (web Performans paneli "Liste Yonetimi" sekmesi paritesi).
// Islevler: liste sec (+arsiv filtresi), atanan personel (Ata/Degistir, Atamayi Geri Al),
// liste durumu (Pasife Al / Arsivle / Aktif Yap), sonuc segmentleri (sayim), segment Indir (CSV paylas),
// Secili Segmenti Tasi (yeni listeye baska personele), Sonuc Alinamayanlari Aktar (toplu).
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:randevu_sistem/theme/app_tokens.dart';
import 'package:randevu_sistem/Frontend/aramali_dropdown.dart';
import '../cagri_api.dart';
import '../cagri_models.dart';

class ListeYonetimi extends StatefulWidget {
  final String sube;
  const ListeYonetimi({super.key, required this.sube});

  @override
  State<ListeYonetimi> createState() => _ListeYonetimiState();
}

class _ListeYonetimiState extends State<ListeYonetimi> {
  bool _arsivGoster = false;
  bool _listelerYukleniyor = true;
  List<AramaKart> _listeler = [];
  List<CagriPersonel> _personeller = [];

  int? _seciliAramaId;
  bool _segYukleniyor = false;
  SegmentSonuc? _seg;

  int? _hedefPersonelId; // ata / tasi / aktar hedefi
  String? _seciliSegmentKod; // indir / tasi
  bool _islemde = false;

  @override
  void initState() {
    super.initState();
    _listeleriYukle();
    _personelleriYukle();
  }

  Future<void> _listeleriYukle() async {
    setState(() => _listelerYukleniyor = true);
    try {
      final l = await CagriApi.kartlar(widget.sube, arsiv: _arsivGoster);
      if (!mounted) return;
      setState(() {
        _listeler = l;
        _listelerYukleniyor = false;
        if (_seciliAramaId != null &&
            !l.any((k) => k.id == _seciliAramaId)) {
          _seciliAramaId = null;
          _seg = null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _listelerYukleniyor = false);
      _uyar('Listeler yüklenemedi: $e');
    }
  }

  Future<void> _personelleriYukle() async {
    try {
      final p = await CagriApi.personeller(widget.sube);
      if (mounted) setState(() => _personeller = p);
    } catch (_) {}
  }

  Future<void> _segYukle(int aramaId) async {
    setState(() {
      _seciliAramaId = aramaId;
      _segYukleniyor = true;
      _seg = null;
      _seciliSegmentKod = null;
    });
    try {
      final s = await CagriApi.listeSegmentler(aramaId, widget.sube);
      if (!mounted) return;
      setState(() {
        _seg = s;
        _hedefPersonelId = s.personelId;
        _segYukleniyor = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _segYukleniyor = false);
      _uyar('Segmentler yüklenemedi: $e');
    }
  }

  Future<void> _calistir(Future<Map<String, dynamic>> Function() islem,
      {bool listeleriTazele = false}) async {
    if (_islemde) return;
    setState(() => _islemde = true);
    try {
      final r = await islem();
      if (!mounted) return;
      final ok = r['success'] == true || r['basarili'] == true;
      _uyar((r['message'] ?? (ok ? 'İşlem tamam.' : 'İşlem başarısız.')).toString(),
          hata: !ok);
      if (ok) {
        if (listeleriTazele) await _listeleriYukle();
        if (_seciliAramaId != null) await _segYukle(_seciliAramaId!);
      }
    } catch (e) {
      _uyar('Hata: $e', hata: true);
    } finally {
      if (mounted) setState(() => _islemde = false);
    }
  }

  // ───────── Aksiyonlar ─────────
  void _ata() {
    if (_hedefPersonelId == null) { _uyar('Personel seçin.'); return; }
    _calistir(() => CagriApi.listePersonelDegistir(
        aramaId: _seciliAramaId!, personelId: _hedefPersonelId, sube: widget.sube),
        listeleriTazele: true);
  }

  void _atamaGeriAl() {
    _calistir(() => CagriApi.listePersonelDegistir(
        aramaId: _seciliAramaId!, personelId: null, sube: widget.sube),
        listeleriTazele: true);
  }

  void _durum(int durum) {
    _calistir(() => CagriApi.listeDurum(_seciliAramaId!, durum, widget.sube),
        listeleriTazele: true);
  }

  void _segmentTasi() {
    if (_seciliSegmentKod == null) { _uyar('Taşınacak segmenti seçin.'); return; }
    if (_hedefPersonelId == null) { _uyar('Hedef personel seçin.'); return; }
    _calistir(() => CagriApi.segmentAta(
        aramaId: _seciliAramaId!,
        kod: _seciliSegmentKod!,
        personelId: _hedefPersonelId!,
        sube: widget.sube),
        listeleriTazele: true);
  }

  void _topluAktar() {
    if (_hedefPersonelId == null) { _uyar('Hedef personel seçin.'); return; }
    _calistir(() => CagriApi.topluAktar(
        aramaId: _seciliAramaId!,
        personelId: _hedefPersonelId!,
        kodlar: 'bekleyen,0,2,5', // sonuc alinamayanlar
        sube: widget.sube),
        listeleriTazele: true);
  }

  Future<void> _indir() async {
    if (_seciliSegmentKod == null) { _uyar('İndirilecek segmenti seçin.'); return; }
    if (_islemde) return;
    setState(() => _islemde = true);
    try {
      final csv = await CagriApi.segmentIndirCsv(
          aramaId: _seciliAramaId!, kod: _seciliSegmentKod!, sube: widget.sube);
      final dir = await getApplicationDocumentsDirectory();
      final seg = _seg?.segmentler
          .firstWhere((s) => s.kod == _seciliSegmentKod,
              orElse: () => CagriSegment(kod: '', ad: 'segment', adet: 0));
      final ad = (seg?.ad ?? 'segment').replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
      final dosya = 'liste-${_seciliAramaId}-$ad.csv';
      final f = File('${dir.path}/$dosya');
      await f.writeAsString(csv);
      await SharePlus.instance
          .share(ShareParams(files: [XFile(f.path)], text: dosya));
    } catch (e) {
      _uyar('İndirilemedi: $e', hata: true);
    } finally {
      if (mounted) setState(() => _islemde = false);
    }
  }

  void _uyar(String m, {bool hata = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(m),
      behavior: SnackBarBehavior.floating,
      backgroundColor: hata ? Colors.red : null,
    ));
  }

  String _listeEtiket(AramaKart k) {
    final p = (k.personel ?? '').trim();
    return '${k.baslik} (${k.toplam})${p.isNotEmpty ? ' — $p' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final ext = context.appTheme;
    return RefreshIndicator(
      onRefresh: _listeleriYukle,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 28),
        children: [
          // Baslik + aciklama
          Row(
            children: [
              Icon(Icons.filter_alt_outlined, color: cs.primary, size: 20),
              const SizedBox(width: 6),
              Text('Liste Segmentasyonu',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
              'Listeyi sonuca göre ayır (Görüşüldü / Cevapsız / … / Bekleyen); '
              'segmenti indir ya da başka personele taşı.',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          const SizedBox(height: 12),

          // Arsiv filtresi + Yenile
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() => _arsivGoster = !_arsivGoster);
                    _listeleriYukle();
                  },
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _arsivGoster,
                        onChanged: (v) {
                          setState(() => _arsivGoster = v ?? false);
                          _listeleriYukle();
                        },
                      ),
                      const Text('Arşivdekiler'),
                    ],
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _listelerYukleniyor ? null : _listeleriYukle,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Yenile'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Liste secici
          _listelerYukleniyor
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()))
              : AramaliDropdownFormField<int>(
                  value: _seciliAramaId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Liste ara / seç',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                  items: _listeler
                      .map((k) => DropdownMenuItem<int>(
                          value: k.id, child: Text(_listeEtiket(k))))
                      .toList(),
                  onChanged: (v) { if (v != null) _segYukle(v); },
                  searchText: (id) => _listeler
                      .firstWhere((k) => k.id == id,
                          orElse: () => AramaKart(
                              id: 0, baslik: '', toplam: 0, arandi: 0,
                              kalan: 0, ilerleme: 0))
                      .baslik,
                ),
          const SizedBox(height: 12),

          if (_seciliAramaId == null)
            Padding(
              padding: const EdgeInsets.only(top: 32),
              child: Center(
                child: Text('Yukarıdan bir arama listesi seçin.',
                    style: TextStyle(color: cs.onSurfaceVariant)),
              ),
            )
          else if (_segYukleniyor)
            const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()))
          else if (_seg != null) ...[
            _atananPersonelKarti(cs, ext),
            const SizedBox(height: 14),
            _segmentIzgara(cs, ext),
            const SizedBox(height: 14),
            _altAksiyonlar(cs),
          ],
        ],
      ),
    );
  }

  Widget _durumRozet(int d) {
    late Color c; late String t;
    if (d == 2) { c = Colors.orange; t = 'Arşiv'; }
    else if (d == 1) { c = const Color(0xFF16A34A); t = 'Aktif'; }
    else { c = Colors.grey; t = 'Pasif'; }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
          color: c.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(99)),
      child: Text(t,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c)),
    );
  }

  Widget _atananPersonelKarti(ColorScheme cs, dynamic ext) {
    final s = _seg!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border.all(color: ext.borderSubtle),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_outline, size: 18, color: cs.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                    'Atanan personel: ${s.personelAd.isEmpty ? "—" : s.personelAd}',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              _durumRozet(s.durum),
            ],
          ),
          const SizedBox(height: 10),
          // Hedef personel secici (ata / tasi / aktar ortak)
          AramaliDropdownFormField<int>(
            value: _hedefPersonelId,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Personel',
              isDense: true,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md)),
            ),
            items: _personeller
                .map((p) =>
                    DropdownMenuItem<int>(value: p.id, child: Text(p.ad)))
                .toList(),
            onChanged: (v) => setState(() => _hedefPersonelId = v),
            searchText: (id) => _personeller
                .firstWhere((p) => p.id == id,
                    orElse: () => CagriPersonel(id: 0, ad: ''))
                .ad,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: _islemde ? null : _ata,
                style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary, foregroundColor: cs.onPrimary),
                icon: const Icon(Icons.swap_horiz, size: 18),
                label: const Text('Ata / Değiştir'),
              ),
              if (s.personelId != null)
                OutlinedButton.icon(
                  onPressed: _islemde ? null : _atamaGeriAl,
                  icon: const Icon(Icons.person_off_outlined, size: 18),
                  label: const Text('Atamayı Geri Al'),
                ),
              if (s.durum == 1)
                OutlinedButton.icon(
                  onPressed: _islemde ? null : () => _durum(3),
                  icon: const Icon(Icons.pause_circle_outline, size: 18),
                  label: const Text('Pasife Al'),
                )
              else
                OutlinedButton.icon(
                  onPressed: _islemde ? null : () => _durum(1),
                  icon: const Icon(Icons.play_circle_outline, size: 18),
                  label: const Text('Aktif Yap'),
                ),
              if (s.durum != 2)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.orange),
                  onPressed: _islemde ? null : () => _durum(2),
                  icon: const Icon(Icons.archive_outlined, size: 18),
                  label: const Text('Arşivle'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _segmentIzgara(ColorScheme cs, dynamic ext) {
    final segs = _seg!.segmentler;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: segs.map((s) {
        final secili = _seciliSegmentKod == s.kod;
        final bos = s.adet == 0;
        return InkWell(
          onTap: bos ? null : () => setState(() => _seciliSegmentKod = s.kod),
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Opacity(
            opacity: bos ? 0.45 : 1,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: secili ? cs.primary.withValues(alpha: 0.12) : cs.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                    color: secili ? cs.primary : ext.borderSubtle,
                    width: secili ? 1.5 : 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(s.ad,
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: secili ? FontWeight.w700 : FontWeight.w500,
                          color: secili ? cs.primary : cs.onSurface)),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(99)),
                    child: Text('${s.adet}',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: cs.primary)),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _altAksiyonlar(ColorScheme cs) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: _islemde ? null : _indir,
          icon: const Icon(Icons.download_outlined, size: 18),
          label: const Text('İndir (paylaş)'),
        ),
        ElevatedButton.icon(
          onPressed: _islemde ? null : _segmentTasi,
          style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary, foregroundColor: cs.onPrimary),
          icon: const Icon(Icons.group_add_outlined, size: 18),
          label: const Text('Seçili Segmenti Taşı'),
        ),
        ElevatedButton.icon(
          onPressed: _islemde ? null : _topluAktar,
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6D28D9),
              foregroundColor: Colors.white),
          icon: const Icon(Icons.groups_outlined, size: 18),
          label: const Text('Sonuç Alınamayanları Aktar'),
        ),
      ],
    );
  }
}

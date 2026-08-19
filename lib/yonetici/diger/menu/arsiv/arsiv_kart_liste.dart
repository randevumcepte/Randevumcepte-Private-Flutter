import 'dart:async';
import 'package:flutter/material.dart';
import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Frontend/arsivdetay.dart';
import 'package:randevu_sistem/Models/colorandtext.dart';
import 'package:randevu_sistem/Models/form.dart';

/// Form Yönetimi sekmelerinin (Tümü/Onaylanan/Beklenen/İptal/Harici)
/// kullandığı modern card listesi. Premium tasarım + arama + infinite scroll.
class ArsivKartListe extends StatefulWidget {
  final String durum;
  final String cevapladi;
  final String cevapladi2;
  final String bosMesaj;
  final IconData bosIkon;
  // Disaridan (orn. yeni form eklenince) listeyi yeniden yuklemek icin token.
  // Deger degisince didUpdateWidget tetiklenir ve liste resetlenir.
  final int refreshToken;
  // Musteri detayindan acilinca sadece o musteriye ait kayitlar gelsin (opsiyonel).
  final String? musteriId;

  const ArsivKartListe({
    super.key,
    required this.durum,
    required this.cevapladi,
    required this.cevapladi2,
    this.bosMesaj = 'Kayıt bulunamadı',
    this.bosIkon = Icons.inbox_outlined,
    this.refreshToken = 0,
    this.musteriId,
  });

  @override
  State<ArsivKartListe> createState() => _ArsivKartListeState();
}

class _ArsivKartListeState extends State<ArsivKartListe> {
  String? _seciliSube;
  final List<Arsiv> _liste = [];
  int _sayfa = 1;
  int _toplamSayfa = 1;
  int _toplamKayit = 0;
  bool _yukleniyor = true;
  bool _dahaYukleniyor = false;
  String _arama = '';
  String? _hataMesaji;
  Timer? _debounce;
  final _aramaController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _baslat();
    _scrollController.addListener(_scrollDinle);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _aramaController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _baslat() async {
    _seciliSube = await secilisalonid();
    await _yukle(reset: true);
  }

  @override
  void didUpdateWidget(covariant ArsivKartListe oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken && _seciliSube != null) {
      _yukle(reset: true);
    }
  }

  void _scrollDinle() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_dahaYukleniyor &&
        _sayfa < _toplamSayfa) {
      _dahaYukle();
    }
  }

  void _aramaDegisti(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (v != _arama) {
        _arama = v;
        _yukle(reset: true);
      }
    });
  }

  Future<void> _yukle({bool reset = false}) async {
    if (_seciliSube == null) return;
    if (reset) {
      _sayfa = 1;
      _liste.clear();
      _hataMesaji = null;
      if (mounted) setState(() => _yukleniyor = true);
    }
    try {
      final resp = await arsivgetir(
        _seciliSube!,
        widget.musteriId ?? '',
        _sayfa.toString(),
        _arama,
        widget.durum,
        widget.cevapladi,
        widget.cevapladi2,
      );
      final data = (resp['data'] ?? []) as List;
      final yeniler = <Arsiv>[];
      int parseHata = 0;
      for (final j in data) {
        try {
          // Arsiv.fromJson 'form' ve 'musteri' alanlarini Map bekler;
          // bazi eski kayitlarda null/eksik olabilir — minimal default ile parse et.
          final map = Map<String, dynamic>.from(j as Map);
          map['form'] ??= {'form_adi': '-'};
          map['musteri'] ??= {'name': '-'};
          map['personel'] ??= <String, dynamic>{};
          yeniler.add(Arsiv.fromJson(map));
        } catch (_) {
          parseHata++;
        }
      }
      if (mounted) {
        setState(() {
          _liste.addAll(yeniler);
          _toplamSayfa = (resp['last_page'] ?? 1) as int;
          _toplamKayit = (resp['total'] ?? 0) as int;
          _yukleniyor = false;
          if (yeniler.isEmpty && parseHata > 0) {
            _hataMesaji =
                '$parseHata kayit parse edilemedi (eski format kayit olabilir).';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _yukleniyor = false;
          _hataMesaji = e.toString();
        });
      }
    }
  }

  Future<void> _dahaYukle() async {
    if (_dahaYukleniyor || _sayfa >= _toplamSayfa) return;
    setState(() => _dahaYukleniyor = true);
    _sayfa++;
    await _yukle(reset: false);
    if (mounted) setState(() => _dahaYukleniyor = false);
  }

  String _formatTarih(String t) {
    if (t.isEmpty || t == 'null') return '-';
    try {
      final d = DateTime.parse(t).toLocal();
      const aylar = [
        'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
        'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'
      ];
      final saat = '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
      return '${d.day.toString().padLeft(2, '0')} ${aylar[d.month - 1]} ${d.year}  $saat';
    } catch (_) {
      return t;
    }
  }

  String _formAdi(Arsiv a) {
    final adi = a.form['form_adi']?.toString() ?? '';
    if (adi == 'Harici') return a.sozlesme_adi.isNotEmpty ? a.sozlesme_adi : 'Harici Belge';
    return adi.isNotEmpty ? adi : '-';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: TextField(
              controller: _aramaController,
              onChanged: _aramaDegisti,
              decoration: InputDecoration(
                hintText: 'Müşteri veya form adı ara...',
                hintStyle: const TextStyle(fontSize: 13, color: Colors.black45),
                prefixIcon: Icon(Icons.search_rounded,
                    size: 18, color: scheme.primary.withValues(alpha: 0.7)),
                suffixIcon: _aramaController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          _aramaController.clear();
                          _aramaDegisti('');
                          setState(() {});
                        },
                      )
                    : null,
                border: InputBorder.none,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ),
        ),
        Expanded(
          child: _yukleniyor
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () => _yukle(reset: true),
                  child: _liste.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          children: [
                            const SizedBox(height: 60),
                            Icon(
                                _hataMesaji != null
                                    ? Icons.error_outline_rounded
                                    : widget.bosIkon,
                                size: 64,
                                color: (_hataMesaji != null
                                        ? Colors.red
                                        : scheme.primary)
                                    .withValues(alpha: 0.5)),
                            const SizedBox(height: 14),
                            Text(
                              _hataMesaji != null
                                  ? 'Veri çekilemedi'
                                  : widget.bosMesaj,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurface
                                    .withValues(alpha: 0.65),
                              ),
                            ),
                            // Teshis kutusu yalnizca gercek hata durumunda
                            // gozukur; normal "kayit yok" ekraninda gizli.
                            if (_hataMesaji != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    _DbgRow('Şube ID', _seciliSube ?? '-'),
                                    _DbgRow('Filtre',
                                        'durum=${widget.durum} | cvp=${widget.cevapladi} | cvp2=${widget.cevapladi2}'),
                                    _DbgRow('Sayfa',
                                        '$_sayfa / $_toplamSayfa (toplam $_toplamKayit)'),
                                    if (_arama.isNotEmpty)
                                      _DbgRow('Arama', _arama),
                                    _DbgRow('Hata', _hataMesaji!),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                          itemCount: _liste.length + (_dahaYukleniyor ? 1 : 0),
                          itemBuilder: (ctx, i) {
                            if (i >= _liste.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2.5),
                                  ),
                                ),
                              );
                            }
                            final a = _liste[i];
                            final durum = getStatusColorArsiv(
                              a.durum,
                              a.cevapladi.toString(),
                              a.cevapladi2.toString(),
                            );
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _ArsivKart(
                                arsiv: a,
                                musteriAdi:
                                    a.musteridanisan['name']?.toString() ?? '-',
                                formAdi: _formAdi(a),
                                tarih: _formatTarih(a.tarih_saat),
                                durumRenk: durum.color,
                                durumYazi: durum.text,
                                onTap: () =>
                                    ArsivDetayGosterDialog(
                                  context,
                                  a,
                                  onDegisti: () => _yukle(reset: true),
                                ),
                              ),
                            );
                          },
                        ),
                ),
        ),
      ],
    );
  }
}

class _ArsivKart extends StatelessWidget {
  final Arsiv arsiv;
  final String musteriAdi;
  final String formAdi;
  final String tarih;
  final Color durumRenk;
  final String durumYazi;
  final VoidCallback onTap;

  const _ArsivKart({
    required this.arsiv,
    required this.musteriAdi,
    required this.formAdi,
    required this.tarih,
    required this.durumRenk,
    required this.durumYazi,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initial = musteriAdi.isNotEmpty
        ? musteriAdi.trim().substring(0, 1).toUpperCase()
        : '?';
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.07),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      scheme.primary.withValues(alpha: 0.18),
                      scheme.tertiary.withValues(alpha: 0.18),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: scheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            musteriAdi,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        _DurumRozet(renk: durumRenk, yazi: durumYazi),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formAdi,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface.withValues(alpha: 0.75),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_rounded,
                            size: 11,
                            color:
                                scheme.onSurface.withValues(alpha: 0.55)),
                        const SizedBox(width: 4),
                        Text(
                          tarih,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color:
                                scheme.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
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

class _DurumRozet extends StatelessWidget {
  final Color renk;
  final String yazi;
  const _DurumRozet({required this.renk, required this.yazi});

  @override
  Widget build(BuildContext context) {
    if (yazi.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: renk.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        yazi,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: renk,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _DbgRow extends StatelessWidget {
  final String etiket;
  final String deger;
  const _DbgRow(this.etiket, this.deger);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 56,
            child: Text(
              etiket,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              deger,
              style: const TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

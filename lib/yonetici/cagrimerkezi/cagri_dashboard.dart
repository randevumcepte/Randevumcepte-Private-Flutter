// Cagri Merkezi Dashboard (yonetici) — personel performans kartlari.
// Personel kartina tiklayinca o personelin gorusme notlari/ses kayitlari.

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import 'package:randevu_sistem/theme/app_tokens.dart';
import 'cagri_api.dart';
import 'cagri_models.dart';

class CagriDashboard extends StatefulWidget {
  final dynamic isletmebilgi;
  final int kullanicirolu;

  const CagriDashboard({
    super.key,
    required this.isletmebilgi,
    required this.kullanicirolu,
  });

  @override
  State<CagriDashboard> createState() => _CagriDashboardState();
}

class _CagriDashboardState extends State<CagriDashboard> {
  late final String _sube;
  List<PersonelKart> _kartlar = [];
  bool _yukleniyor = true;
  String? _hata;

  @override
  void initState() {
    super.initState();
    _sube = widget.isletmebilgi['id'].toString();
    _yukle();
  }

  Future<void> _yukle() async {
    setState(() {
      _yukleniyor = true;
      _hata = null;
    });
    try {
      final k = await CagriApi.dashboardVerileri(_sube);
      if (mounted) {
        setState(() {
          _kartlar = k;
          _yukleniyor = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hata = '$e';
          _yukleniyor = false;
        });
      }
    }
  }

  void _personelDetay(PersonelKart p) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _PersonelDetayEkrani(
          personelId: p.personelId,
          ad: p.ad,
          sube: _sube,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final ext = context.appTheme;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        foregroundColor: cs.onSurface,
        title: const Text('Çağrı Merkezi',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(onPressed: _yukle, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : _hata != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: ext.warningColor),
                      const SizedBox(height: 12),
                      Text('Yüklenemedi', style: TextStyle(color: cs.onSurfaceVariant)),
                      const SizedBox(height: 8),
                      ElevatedButton(onPressed: _yukle, child: const Text('Tekrar dene')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _yukle,
                  child: _kartlar.isEmpty
                      ? ListView(
                          children: [
                            const SizedBox(height: 120),
                            Icon(Icons.bar_chart, size: 56, color: ext.borderStrong),
                            const SizedBox(height: 12),
                            Center(
                              child: Text('Henüz arama verisi yok',
                                  style: TextStyle(color: cs.onSurfaceVariant)),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
                          itemCount: _kartlar.length,
                          itemBuilder: (context, i) => _personelKarti(_kartlar[i]),
                        ),
                ),
    );
  }

  Widget _personelKarti(PersonelKart p) {
    final cs = context.colors;
    final ext = context.appTheme;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: ext.borderSubtle),
      ),
      child: InkWell(
        onTap: () => _personelDetay(p),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: cs.primary.withValues(alpha: 0.12),
                    child: Text(
                      p.ad.isNotEmpty ? p.ad[0].toUpperCase() : '?',
                      style: TextStyle(
                          color: cs.primary, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(p.ad,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                  if (p.satisCirosu > 0)
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: ext.successColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text('${p.satisCirosu.toStringAsFixed(0)} ₺',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: ext.successColor)),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _rozet('Atanan', p.atanan, cs.onSurface, ext.surfaceMuted),
                  _rozet('Aranan', p.aranan, cs.primary,
                      cs.primary.withValues(alpha: 0.10)),
                  _rozet('Kalan', p.kalan, ext.warningColor,
                      ext.warningColor.withValues(alpha: 0.10)),
                  _rozet('Konuşulan', p.konusulan, ext.successColor,
                      ext.successColor.withValues(alpha: 0.10)),
                  _rozet('Cevapsız', p.cevapsiz, ext.warningColor,
                      ext.warningColor.withValues(alpha: 0.10)),
                  _rozet('Randevu', p.randevu, ext.infoColor,
                      ext.infoColor.withValues(alpha: 0.10)),
                  _rozet('Ön Görüşme', p.ongorusme, ext.infoColor,
                      ext.infoColor.withValues(alpha: 0.10)),
                  _rozet('Satış', p.satis, ext.successColor,
                      ext.successColor.withValues(alpha: 0.10)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: cs.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text('${p.toplamDk} dk',
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                  const SizedBox(width: 14),
                  Icon(Icons.phone, size: 14, color: cs.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text('${p.gorusmeSayisi} görüşme',
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                  const Spacer(),
                  Text('Detay',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: cs.primary)),
                  Icon(Icons.chevron_right, size: 18, color: cs.primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rozet(String etiket, int deger, Color renk, Color arka) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: arka,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$deger',
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w800, color: renk)),
          const SizedBox(width: 5),
          Text(etiket,
              style: TextStyle(fontSize: 11.5, color: renk.withValues(alpha: 0.9))),
        ],
      ),
    );
  }
}

class _PersonelDetayEkrani extends StatefulWidget {
  final int personelId;
  final String ad;
  final String sube;

  const _PersonelDetayEkrani({
    required this.personelId,
    required this.ad,
    required this.sube,
  });

  @override
  State<_PersonelDetayEkrani> createState() => _PersonelDetayEkraniState();
}

class _PersonelDetayEkraniState extends State<_PersonelDetayEkrani> {
  final AudioPlayer _player = AudioPlayer();
  String? _calanUrl;
  List<DashboardNot> _notlar = [];
  bool _yukleniyor = true;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    setState(() => _yukleniyor = true);
    try {
      final n = await CagriApi.dashboardPersonelDetay(widget.personelId, widget.sube);
      if (mounted) {
        setState(() {
          _notlar = n;
          _yukleniyor = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _yukleniyor = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Yüklenemedi: $e')),
        );
      }
    }
  }

  Future<void> _oynatDurdur(String url) async {
    try {
      if (_calanUrl == url) {
        await _player.stop();
        if (mounted) setState(() => _calanUrl = null);
        return;
      }
      await _player.stop();
      await _player.play(UrlSource(Uri.encodeFull(url)));
      if (mounted) setState(() => _calanUrl = url);
      _player.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _calanUrl = null);
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ses kaydı oynatılamadı')),
        );
      }
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final ext = context.appTheme;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        foregroundColor: cs.onSurface,
        title: Text(widget.ad,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : _notlar.isEmpty
              ? Center(
                  child: Text('Görüşme kaydı yok',
                      style: TextStyle(color: cs.onSurfaceVariant)))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
                  itemCount: _notlar.length,
                  itemBuilder: (context, i) {
                    final n = _notlar[i];
                    final caliyor = n.ses.isNotEmpty && _calanUrl == n.ses;
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(12),
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
                              Expanded(
                                child: Text(n.musteri,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700, fontSize: 14)),
                              ),
                              Text(n.tarih,
                                  style: TextStyle(
                                      fontSize: 11.5, color: cs.onSurfaceVariant)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: cs.primary.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: Text(n.sonuc,
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: cs.primary)),
                              ),
                              if (n.sureDk > 0) ...[
                                const SizedBox(width: 8),
                                Text('${n.sureDk} dk',
                                    style: TextStyle(
                                        fontSize: 11.5,
                                        color: cs.onSurfaceVariant)),
                              ],
                              if (n.satisTutari != null) ...[
                                const SizedBox(width: 8),
                                Text('${n.satisTutari!.toStringAsFixed(0)} ₺',
                                    style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: ext.successColor)),
                              ],
                            ],
                          ),
                          if (n.kategori.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              [n.kategori, if (n.altKategori.isNotEmpty) n.altKategori]
                                  .join(' › '),
                              style: TextStyle(
                                  fontSize: 12, color: cs.onSurfaceVariant),
                            ),
                          ],
                          if (n.not.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(n.not, style: const TextStyle(fontSize: 13)),
                          ],
                          if (n.ses.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () => _oynatDurdur(n.ses),
                              borderRadius: BorderRadius.circular(99),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 7),
                                decoration: BoxDecoration(
                                  color: cs.primary.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                        caliyor
                                            ? Icons.stop_circle
                                            : Icons.play_circle_fill,
                                        size: 20,
                                        color: cs.primary),
                                    const SizedBox(width: 6),
                                    Text(caliyor ? 'Durdur' : 'Dinle',
                                        style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                            color: cs.primary)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

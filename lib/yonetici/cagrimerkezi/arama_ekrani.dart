// Arama Ekrani (dialer ana ekran) — acentenin atanan listeleri.
// Liste kartlari (ilerleme) + zamani gelen geri-arama hatirlatmalari.

import 'dart:async';
import 'package:flutter/material.dart';

import 'package:randevu_sistem/theme/app_tokens.dart';
import 'cagri_api.dart';
import 'cagri_models.dart';
import 'arama_liste_detay_ekrani.dart';

class AramaEkrani extends StatefulWidget {
  final dynamic isletmebilgi;
  final int kullanicirolu;

  const AramaEkrani({
    super.key,
    required this.isletmebilgi,
    required this.kullanicirolu,
  });

  @override
  State<AramaEkrani> createState() => _AramaEkraniState();
}

class _AramaEkraniState extends State<AramaEkrani> {
  late final String _sube;
  List<AramaKart> _kartlar = [];
  bool _yukleniyor = true;
  String? _hata;

  Timer? _hatirlatmaTimer;
  List<YaklasanRandevu> _yaklasan = [];

  @override
  void initState() {
    super.initState();
    _sube = widget.isletmebilgi['id'].toString();
    _yukle();
    _hatirlatmalariKontrol();
    _hatirlatmaTimer = Timer.periodic(
        const Duration(seconds: 45), (_) => _hatirlatmalariKontrol());
  }

  @override
  void dispose() {
    _hatirlatmaTimer?.cancel();
    super.dispose();
  }

  Future<void> _yukle() async {
    setState(() {
      _yukleniyor = true;
      _hata = null;
    });
    try {
      final k = await CagriApi.kartlar(_sube);
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

  Future<void> _hatirlatmalariKontrol() async {
    try {
      final r = await CagriApi.yaklasanRandevular(_sube);
      if (mounted) setState(() => _yaklasan = r);
    } catch (_) {}
  }

  void _listeyiAc(AramaKart kart) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AramaListeDetayEkrani(
          aramaId: kart.id,
          baslik: kart.baslik,
          sube: _sube,
          kullanicirolu: widget.kullanicirolu,
        ),
      ),
    ).then((_) => _yukle());
  }

  void _hatirlatmalariGoster() {
    final cs = context.colors;
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text('Zamanı Gelen Geri Aramalar',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface)),
                ],
              ),
            ),
            ..._yaklasan.map((y) => ListTile(
                  leading: const Icon(Icons.phone_callback),
                  title: Text(y.ad),
                  subtitle: Text('${y.tarih} ${y.saat}'),
                  onTap: () {
                    Navigator.pop(context);
                    final kart = _kartlar.firstWhere(
                      (k) => k.id == y.aramaId,
                      orElse: () => AramaKart(
                        id: y.aramaId,
                        baslik: 'Liste',
                        toplam: 0,
                        arandi: 0,
                        kalan: 0,
                        ilerleme: 0,
                      ),
                    );
                    _listeyiAc(kart);
                  },
                )),
          ],
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
        title: const Text('Arama Ekranı',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(onPressed: _yukle, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          // Geri arama hatirlatma bandi
          if (_yaklasan.isNotEmpty)
            Material(
              color: Colors.orange.withValues(alpha: 0.14),
              child: InkWell(
                onTap: _hatirlatmalariGoster,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.notifications_active, color: Colors.orange),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${_yaklasan.length} geri arama zamanı geldi',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, color: Colors.deepOrange),
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.deepOrange),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(
            child: _yukleniyor
                ? const Center(child: CircularProgressIndicator())
                : _hata != null
                    ? _hataGoster()
                    : RefreshIndicator(
                        onRefresh: _yukle,
                        child: _kartlar.isEmpty
                            ? ListView(
                                children: [
                                  const SizedBox(height: 120),
                                  Icon(Icons.list_alt_outlined,
                                      size: 56, color: ext.borderStrong),
                                  const SizedBox(height: 12),
                                  Center(
                                    child: Text('Atanmış arama listeniz yok',
                                        style:
                                            TextStyle(color: cs.onSurfaceVariant)),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
                                itemCount: _kartlar.length,
                                itemBuilder: (context, i) =>
                                    _kart(_kartlar[i]),
                              ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _hataGoster() {
    final cs = context.colors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: context.appTheme.warningColor),
          const SizedBox(height: 12),
          Text('Yüklenemedi', style: TextStyle(color: cs.onSurfaceVariant)),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: _yukle, child: const Text('Tekrar dene')),
        ],
      ),
    );
  }

  Widget _kart(AramaKart kart) {
    final cs = context.colors;
    final ext = context.appTheme;
    final oran = (kart.ilerleme.clamp(0, 100)) / 100.0;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: ext.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: ext.shadowBase.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _listeyiAc(kart),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(Icons.phone_in_talk_outlined, color: cs.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(kart.baslik,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700)),
                        if (kart.personel != null || kart.aranacakTarih != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              [
                                if (kart.personel != null) kart.personel,
                                if (kart.aranacakTarih != null)
                                  '⏰ ${kart.aranacakTarih}',
                              ].join('  •  '),
                              style: TextStyle(
                                  fontSize: 12, color: cs.onSurfaceVariant),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: ext.borderStrong),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: oran,
                  minHeight: 7,
                  backgroundColor: ext.surfaceMuted,
                  valueColor: AlwaysStoppedAnimation(cs.primary),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _istatistik('Toplam', kart.toplam, cs.onSurface),
                  _istatistik('Arandı', kart.arandi, ext.successColor),
                  _istatistik('Kalan', kart.kalan, ext.warningColor),
                  _istatistik('%', kart.ilerleme, cs.primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _istatistik(String etiket, int deger, Color renk) {
    final cs = context.colors;
    return Column(
      children: [
        Text('$deger',
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w800, color: renk)),
        Text(etiket, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
      ],
    );
  }
}

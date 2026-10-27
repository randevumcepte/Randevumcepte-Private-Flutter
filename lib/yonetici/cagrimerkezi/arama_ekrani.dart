// Arama Ekrani (dialer ana ekran) — acentenin atanan listeleri.
// Liste kartlari (ilerleme) + zamani gelen geri-arama hatirlatmalari.

import 'dart:async';
import 'package:flutter/material.dart';

import 'package:randevu_sistem/theme/app_tokens.dart';
import 'cagri_api.dart';
import 'cagri_models.dart';
import 'arama_liste_detay_ekrani.dart';
import 'arama_listesi_olustur_ekrani.dart';

class AramaEkrani extends StatefulWidget {
  final dynamic isletmebilgi;
  final int kullanicirolu;
  // gomulu=true ise sekmeli Cagri Merkezi sayfasi icinde -> kendi AppBar'ini gizler.
  final bool gomulu;

  const AramaEkrani({
    super.key,
    required this.isletmebilgi,
    required this.kullanicirolu,
    this.gomulu = false,
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
          isletmebilgi: widget.isletmebilgi,
        ),
      ),
    ).then((_) => _yukle());
  }

  // faz -> (emoji, etiket, renk) — web ile ayni (Geciken / Yaklasan 5dk / Zamani Geldi).
  (String, String, Color) _fazStil(String faz) {
    switch (faz) {
      case 'gecikti':
        return ('⚠️', 'Geciken Arama', const Color(0xFFD32F2F));
      case 'on5':
        return ('⏰', 'Yaklaşan Arama (5 dk)', const Color(0xFFEA580C));
      default:
        return ('📞', 'Arama Zamanı Geldi', const Color(0xFF6D28D9));
    }
  }

  // Ust banner: en acil faz'a gore renk/emoji; tiklayinca hatirlatma kartlari acilir.
  Widget _hatirlatmaBanner() {
    final gecikti = _yaklasan.any((y) => y.faz == 'gecikti');
    final zaman = _yaklasan.any((y) => y.faz == 'zaman');
    final renk = gecikti
        ? const Color(0xFFD32F2F)
        : (zaman ? const Color(0xFF6D28D9) : const Color(0xFFEA580C));
    final emoji = gecikti ? '⚠️' : (zaman ? '📞' : '⏰');
    final metin = gecikti
        ? 'geciken arama'
        : (zaman ? 'arama zamanı geldi' : 'yaklaşan arama');
    return Material(
      color: renk.withValues(alpha: 0.10),
      child: InkWell(
        onTap: _hatirlatmalariGoster,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Text('${_yaklasan.length} $metin — görüntüle',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: renk,
                        fontSize: 13.5)),
              ),
              Icon(Icons.chevron_right, color: renk, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _hatirlatmalariGoster() {
    final cs = context.colors;
    // Tab controller'i sheet ACILMADAN yakala: modal sheet DefaultTabController altinda DEGIL.
    final tabController = DefaultTabController.maybeOf(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text('Arama Hatırlatmaları (${_yaklasan.length})',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface)),
                ],
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 12),
                children: _yaklasan.map((y) {
                  final f = _fazStil(y.faz);
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(sheetCtx);
                        tabController?.animateTo(1); // Arama Randevuları (takvim)
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: f.$3.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: f.$3.withValues(alpha: 0.35)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(f.$1, style: const TextStyle(fontSize: 14)),
                                const SizedBox(width: 6),
                                Text(f.$2,
                                    style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w800,
                                        color: f.$3)),
                                const Spacer(),
                                Text('${y.tarih} ${y.saat}',
                                    style: TextStyle(
                                        fontSize: 12, color: cs.onSurfaceVariant)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(y.ad,
                                style: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w700)),
                            if (y.not.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(y.not,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 12.5, color: cs.onSurfaceVariant)),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.event, size: 14, color: f.$3),
                                const SizedBox(width: 4),
                                Text('Arama Randevularına git',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: f.$3)),
                                Icon(Icons.chevron_right, size: 16, color: f.$3),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Yeni arama listesi olustur ekranini ac; eklenirse kartlari tazele.
  Future<void> _aramaListesiOlustur() async {
    final sonuc = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AramaListesiOlusturEkrani(sube: _sube),
      ),
    );
    if (sonuc == true) _yukle();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final ext = context.appTheme;
    return Scaffold(
      backgroundColor: cs.surface,
      // Arama Listesi Olustur (Performans'tan buraya tasindi).
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _aramaListesiOlustur,
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        icon: const Icon(Icons.add),
        label: const Text('Arama Listesi Oluştur',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      appBar: widget.gomulu
          ? null
          : AppBar(
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
          // Arama hatirlatma banner'i (web popup paritesi): yaklasan/zamani gelen/geciken
          // arama randevusu varsa gorunur; tiklayinca kartlar + Arama Randevulari takvimine gider.
          if (_yaklasan.isNotEmpty) _hatirlatmaBanner(),
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

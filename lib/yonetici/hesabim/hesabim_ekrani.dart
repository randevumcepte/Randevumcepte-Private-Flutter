// Hesabim (My Account) ekrani — web Hesabim sayfasinin mobil karsiligi.
// Hero + Uyelik / Aldigim Hizmetler / Fatura Bilgileri / Faturalarim sekmeleri.
// Satin alma/yukseltme YOK (Netflix modeli) — sadece bilgilendirme + fatura duzenleme.

import 'package:flutter/material.dart';
import 'package:randevu_sistem/theme/app_tokens.dart';
import 'hesabim_api.dart';

class HesabimEkrani extends StatefulWidget {
  final dynamic isletmebilgi;
  const HesabimEkrani({super.key, required this.isletmebilgi});

  @override
  State<HesabimEkrani> createState() => _HesabimEkraniState();
}

class _HesabimEkraniState extends State<HesabimEkrani> {
  late final String _sube;
  HesabimVeri? _veri;
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
      final v = await HesabimApi.getir(_sube);
      if (mounted) setState(() { _veri = v; _yukleniyor = false; });
    } catch (e) {
      if (mounted) setState(() { _hata = '$e'; _yukleniyor = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: context.appTheme.surfaceMuted,
        appBar: AppBar(
          backgroundColor: cs.surface,
          elevation: 0,
          foregroundColor: cs.onSurface,
          title: const Text('Hesabım',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          actions: [IconButton(onPressed: _yukle, icon: const Icon(Icons.refresh))],
          bottom: _yukleniyor || _veri == null
              ? null
              : TabBar(
                  isScrollable: true,
                  labelColor: cs.primary,
                  unselectedLabelColor: cs.onSurfaceVariant,
                  indicatorColor: cs.primary,
                  labelStyle:
                      const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                  tabs: const [
                    Tab(text: 'Üyelik'),
                    Tab(text: 'Hizmetler'),
                    Tab(text: 'Fatura Bilgileri'),
                    Tab(text: 'Faturalarım'),
                  ],
                ),
        ),
        body: _yukleniyor
            ? const Center(child: CircularProgressIndicator())
            : _hata != null
                ? _hataGoster()
                : Column(
                    children: [
                      _hero(),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _uyelikTab(),
                            _hizmetlerTab(),
                            _faturaBilgiTab(),
                            _faturalarTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _hataGoster() {
    final cs = context.colors;
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.error_outline, size: 48, color: context.appTheme.warningColor),
        const SizedBox(height: 12),
        Text('Yüklenemedi', style: TextStyle(color: cs.onSurfaceVariant)),
        const SizedBox(height: 8),
        ElevatedButton(onPressed: _yukle, child: const Text('Tekrar dene')),
      ]),
    );
  }

  // ───────── Hero ─────────
  Widget _hero() {
    final cs = context.colors;
    final ext = context.appTheme;
    final i = _veri!.isletme;
    final k = _veri!.kullanici;
    final kg = i.kalanGun;
    final Color kgRenk = kg == null
        ? cs.onSurfaceVariant
        : (kg <= 7 ? Colors.redAccent : (kg <= 30 ? ext.warningColor : ext.successColor));
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: ext.heroGradient,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
              color: cs.primary.withValues(alpha: 0.30),
              blurRadius: 16,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white.withValues(alpha: 0.22),
                backgroundImage:
                    k.profilResim.startsWith('http') ? NetworkImage(k.profilResim) : null,
                child: k.profilResim.startsWith('http')
                    ? null
                    : Text(
                        i.salonAdi.isNotEmpty ? i.salonAdi[0].toUpperCase() : '?',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(i.salonAdi,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800)),
                    if (k.name.isNotEmpty)
                      Text(k.name,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9), fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _heroPill(Icons.workspace_premium_outlined,
                  '${i.uyelikTuruAdi} • ${i.uyelikPeriyoduAdi}'),
              if (kg != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.timer_outlined, size: 14, color: kgRenk),
                    const SizedBox(width: 4),
                    Text('$kg gün kaldı',
                        style: TextStyle(
                            color: kgRenk, fontSize: 12, fontWeight: FontWeight.w800)),
                  ]),
                ),
            ],
          ),
          if (k.email.isNotEmpty || k.gsm1.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(children: [
              if (k.gsm1.isNotEmpty) ...[
                const Icon(Icons.phone, size: 13, color: Colors.white70),
                const SizedBox(width: 4),
                Text(k.gsm1,
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(width: 12),
              ],
              if (k.email.isNotEmpty)
                Expanded(
                  child: Row(children: [
                    const Icon(Icons.email_outlined, size: 13, color: Colors.white70),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(k.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ),
                  ]),
                ),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _heroPill(IconData icon, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 5),
          Text(text,
              style: const TextStyle(
                  color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
        ]),
      );

  // ───────── Tab 1: Uyelik ─────────
  Widget _uyelikTab() {
    final i = _veri!.isletme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
      children: [
        _kart('Aktif Üyelik', Icons.workspace_premium_outlined, [
          _satir('Paket', i.uyelikTuruAdi),
          _satir('Ödeme Periyodu', i.uyelikPeriyoduAdi),
          _satir('Bitiş Tarihi', i.uyelikBitisTarihi.isEmpty ? '-' : i.uyelikBitisTarihi),
          _satir('Kalan Gün', i.kalanGun == null ? '-' : '${i.kalanGun} gün'),
          _satir('Kayıt Tarihi', i.kayitTarihi.isEmpty ? '-' : i.kayitTarihi),
        ]),
        const SizedBox(height: 12),
        _bilgiNotu(
            'Paket yükseltme ve satın alma işlemleri web panelden (app.randevumcepte.com.tr) yapılır.'),
      ],
    );
  }

  // ───────── Tab 2: Hizmetler ─────────
  Widget _hizmetlerTab() {
    final cs = context.colors;
    if (_veri!.hizmetler.isEmpty) {
      return Center(
          child: Text('Hizmet bulunamadı',
              style: TextStyle(color: cs.onSurfaceVariant)));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
      children: _veri!.hizmetler.map(_hizmetKart).toList(),
    );
  }

  Widget _hizmetKart(HesabimHizmet h) {
    final cs = context.colors;
    final ext = context.appTheme;
    final renk = _renkCevir(h.renk);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: ext.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: renk.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(_ikonCevir(h.icon), color: renk, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(h.ad,
                          style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface)),
                    ),
                    _durumPill(h, renk),
                  ],
                ),
                if (h.aciklama.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(h.aciklama,
                      style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant)),
                ],
                const SizedBox(height: 6),
                Wrap(spacing: 8, runSpacing: 4, children: [
                  if (h.periyot.isNotEmpty)
                    _miniEtiket(Icons.autorenew, h.periyot),
                  if (h.bitis.isNotEmpty)
                    _miniEtiket(Icons.event, 'Bitiş: ${h.bitis}'),
                  if (h.kalanGun != null)
                    _miniEtiket(Icons.timer_outlined, '${h.kalanGun} gün'),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _durumPill(HesabimHizmet h, Color renk) {
    final ext = context.appTheme;
    String label;
    Color c;
    if (h.deneme) {
      label = h.denemeLabel.isNotEmpty ? h.denemeLabel : 'Deneme';
      c = ext.warningColor;
    } else if (h.aktif) {
      label = 'Aktif';
      c = ext.successColor;
    } else {
      label = 'Pasif';
      c = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: c.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(99)),
      child: Text(label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: c)),
    );
  }

  Widget _miniEtiket(IconData icon, String text) {
    final cs = context.colors;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: cs.onSurfaceVariant),
      const SizedBox(width: 3),
      Text(text, style: TextStyle(fontSize: 11.5, color: cs.onSurfaceVariant)),
    ]);
  }

  // ───────── Tab 3: Fatura Bilgileri ─────────
  Widget _faturaBilgiTab() => _FaturaBilgiForm(sube: _sube, isletme: _veri!.isletme);

  // ───────── Tab 4: Faturalarim ─────────
  Widget _faturalarTab() {
    final cs = context.colors;
    final fat = _veri!.faturalar;
    final sms = _veri!.smsSiparisleri;
    if (fat.isEmpty && sms.isEmpty) {
      return Center(
          child: Text('Henüz fatura kaydı yok',
              style: TextStyle(color: cs.onSurfaceVariant)));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
      children: [
        if (sms.isNotEmpty) ...[
          _bolumBaslik('Duyuru (SMS) Siparişleri'),
          ...sms.map((s) => _faturaSatir(
                tarih: _str(s['created_at']),
                baslik: '${_str(s['sms_adet'])} SMS',
                tutar: _str(s['tutar']),
                durum: _str(s['yukleme_durumu']) == '1' ? 'Yüklendi' : 'Bekliyor',
                url: _str(s['fatura_url']),
              )),
          const SizedBox(height: 12),
        ],
        if (fat.isNotEmpty) ...[
          _bolumBaslik('Üyelik Ödemeleri'),
          ...fat.map((f) => _faturaSatir(
                tarih: _str(f['odeme_tarihi']),
                baslik: _str(f['aciklama']).isEmpty ? 'Ödeme' : _str(f['aciklama']),
                tutar: _str(f['tutar']),
                durum: _str(f['durum']),
                url: _str(f['dosya_url']),
              )),
        ],
      ],
    );
  }

  Widget _faturaSatir({
    required String tarih,
    required String baslik,
    required String tutar,
    required String durum,
    required String url,
  }) {
    final cs = context.colors;
    final ext = context.appTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: ext.borderSubtle),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(baslik,
                    style:
                        const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Row(children: [
                  if (tarih.isNotEmpty)
                    Text(tarih,
                        style: TextStyle(fontSize: 11.5, color: cs.onSurfaceVariant)),
                  if (durum.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text('• $durum',
                        style: TextStyle(fontSize: 11.5, color: cs.onSurfaceVariant)),
                  ],
                ]),
              ],
            ),
          ),
          if (tutar.isNotEmpty)
            Text('$tutar ₺',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w800, color: cs.primary)),
        ],
      ),
    );
  }

  // ───────── Ortak ─────────
  Widget _kart(String baslik, IconData ikon, List<Widget> cocuklar) {
    final cs = context.colors;
    final ext = context.appTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: ext.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(ikon, size: 18, color: cs.primary),
            const SizedBox(width: 8),
            Text(baslik,
                style: TextStyle(
                    fontSize: 14.5, fontWeight: FontWeight.w800, color: cs.onSurface)),
          ]),
          const SizedBox(height: 12),
          ...cocuklar,
        ],
      ),
    );
  }

  Widget _satir(String etiket, String deger) {
    final cs = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(etiket,
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
          ),
          Expanded(
            child: Text(deger,
                style: TextStyle(
                    fontSize: 13.5, fontWeight: FontWeight.w600, color: cs.onSurface)),
          ),
        ],
      ),
    );
  }

  Widget _bolumBaslik(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 2),
        child: Text(t,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: context.colors.onSurfaceVariant,
                letterSpacing: 0.3)),
      );

  Widget _bilgiNotu(String t) {
    final cs = context.colors;
    final ext = context.appTheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ext.infoColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: ext.infoColor.withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        Icon(Icons.info_outline, size: 18, color: ext.infoColor),
        const SizedBox(width: 8),
        Expanded(
            child: Text(t, style: TextStyle(fontSize: 12.5, color: cs.onSurface))),
      ]),
    );
  }

  String _str(dynamic v) => v == null ? '' : v.toString();

  Color _renkCevir(String renk) {
    switch (renk) {
      case 'yesil':
        return const Color(0xFF16A34A);
      case 'turuncu':
        return const Color(0xFFF97316);
      case 'mavi':
        return const Color(0xFF3B82F6);
      case 'lacivert':
        return const Color(0xFF1E3A8A);
      case 'pembe':
        return const Color(0xFFEC4899);
      case 'teal':
        return const Color(0xFF14B8A6);
      case 'mor':
      default:
        return context.colors.primary;
    }
  }

  IconData _ikonCevir(String fa) {
    switch (fa) {
      case 'fa-whatsapp':
        return Icons.chat;
      case 'fa-headphones':
        return Icons.headset_mic_outlined;
      case 'fa-magic':
        return Icons.auto_awesome;
      case 'fa-mobile':
        return Icons.smartphone;
      case 'fa-star':
        return Icons.star_outline;
      case 'fa-trophy':
        return Icons.emoji_events_outlined;
      case 'fa-file-text-o':
        return Icons.description_outlined;
      case 'fa-calendar-check-o':
      default:
        return Icons.event_available_outlined;
    }
  }
}

// ───────── Fatura Bilgileri formu ─────────
class _FaturaBilgiForm extends StatefulWidget {
  final String sube;
  final HesabimIsletme isletme;
  const _FaturaBilgiForm({required this.sube, required this.isletme});

  @override
  State<_FaturaBilgiForm> createState() => _FaturaBilgiFormState();
}

class _FaturaBilgiFormState extends State<_FaturaBilgiForm> {
  late final TextEditingController _vergiAdi;
  late final TextEditingController _vergiNo;
  late final TextEditingController _kdv;
  late final TextEditingController _adres;
  bool _kaydediliyor = false;

  @override
  void initState() {
    super.initState();
    _vergiAdi = TextEditingController(text: widget.isletme.vergiAdi);
    _vergiNo = TextEditingController(text: widget.isletme.vergiNo);
    _kdv = TextEditingController(text: widget.isletme.kdvOrani);
    _adres = TextEditingController(text: widget.isletme.vergiAdresi);
  }

  @override
  void dispose() {
    _vergiAdi.dispose();
    _vergiNo.dispose();
    _kdv.dispose();
    _adres.dispose();
    super.dispose();
  }

  Future<void> _kaydet() async {
    setState(() => _kaydediliyor = true);
    try {
      final ok = await HesabimApi.faturaBilgiGuncelle(
        sube: widget.sube,
        vergiAdi: _vergiAdi.text.trim(),
        vergiNo: _vergiNo.text.trim(),
        vergiAdresi: _adres.text.trim(),
        kdvOrani: _kdv.text.trim(),
      );
      if (!mounted) return;
      setState(() => _kaydediliyor = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'Fatura bilgileri güncellendi' : 'Kaydedilemedi'),
        backgroundColor: ok ? null : Colors.redAccent,
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _kaydediliyor = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Hata: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      children: [
        _alan('Vergi / Ünvan Adı', _vergiAdi),
        _alan('Vergi / TC No', _vergiNo, keyboard: TextInputType.number),
        _alan('KDV Oranı (%)', _kdv,
            keyboard: const TextInputType.numberWithOptions(decimal: true)),
        _alan('Vergi Adresi', _adres, satir: 3),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _kaydediliyor ? null : _kaydet,
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.primary,
              foregroundColor: context.colors.onPrimary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md)),
            ),
            icon: _kaydediliyor
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save_outlined),
            label: Text(_kaydediliyor ? 'Kaydediliyor...' : 'Bilgileri Kaydet',
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  Widget _alan(String etiket, TextEditingController c,
      {TextInputType? keyboard, int satir = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        keyboardType: keyboard,
        maxLines: satir,
        decoration: InputDecoration(
          labelText: etiket,
          alignLabelWithHint: true,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md)),
        ),
      ),
    );
  }
}

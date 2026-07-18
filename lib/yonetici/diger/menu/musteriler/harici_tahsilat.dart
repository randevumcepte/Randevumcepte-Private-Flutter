import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Models/musteri_danisanlar.dart';
import 'package:randevu_sistem/theme/app_tokens.dart';

/// Gecmise donuk (harici) satis + tahsilat ekranı. Müsteri sabit (md).
/// Yan etkisiz: recete/stok/seans olusturulmaz (web hariciTahsilatEkle ile birebir).
class HariciTahsilat extends StatefulWidget {
  final MusteriDanisan md;
  final dynamic isletmebilgi;
  const HariciTahsilat({Key? key, required this.md, required this.isletmebilgi})
      : super(key: key);

  @override
  State<HariciTahsilat> createState() => _HariciTahsilatState();
}

class _KalemSatir {
  String tip; // 'hizmet' | 'urun' | 'paket'
  String? id;
  String ad;
  final TextEditingController fiyat;
  final TextEditingController adet;
  _KalemSatir({this.tip = 'hizmet', this.id, this.ad = '', String fiyat = '', String adet = '1'})
      : fiyat = TextEditingController(text: fiyat),
        adet = TextEditingController(text: adet);
}

class _HariciTahsilatState extends State<HariciTahsilat> {
  String? _salonId;
  String? _olusturanId;
  bool _yukleniyor = true;
  bool _kaydediyor = false;

  // {id, ad, fiyat}
  List<Map<String, dynamic>> _hizmetler = [];
  List<Map<String, dynamic>> _urunler = [];
  List<Map<String, dynamic>> _paketler = [];

  DateTime _satisTarihi = DateTime.now();
  final List<_KalemSatir> _kalemler = [_KalemSatir()];
  final TextEditingController _tahsilatTutari = TextEditingController(text: '0');
  String _odemeYontemi = '1'; // 1 Nakit, 2 Kredi Kartı, 3 Havale/EFT
  final TextEditingController _not = TextEditingController();

  static const _odemeler = [
    {'id': '1', 'ad': 'Nakit', 'icon': Icons.payments_outlined},
    {'id': '2', 'ad': 'Kredi Kartı', 'icon': Icons.credit_card_rounded},
    {'id': '3', 'ad': 'Havale/EFT', 'icon': Icons.account_balance_outlined},
  ];

  @override
  void initState() {
    super.initState();
    _baslat();
  }

  Future<void> _baslat() async {
    try {
      _salonId = await secilisalonid();
      final prefs = await SharedPreferences.getInstance();
      final us = prefs.getString('user');
      if (us != null) {
        _olusturanId = (jsonDecode(us)['id']).toString();
      }
      final data = await hariciTahsilatKalemler(_salonId ?? '');
      _hizmetler = _mapList(data['hizmetler']);
      _urunler = _mapList(data['urunler']);
      _paketler = _mapList(data['paketler']);
    } catch (_) {}
    if (mounted) setState(() => _yukleniyor = false);
  }

  List<Map<String, dynamic>> _mapList(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .map<Map<String, dynamic>>((e) => {
              'id': (e['id']).toString(),
              'ad': (e['ad'] ?? '').toString(),
              'fiyat': (e['fiyat'] ?? '0').toString(),
            })
        .toList();
  }

  List<Map<String, dynamic>> _secenekler(String tip) {
    if (tip == 'urun') return _urunler;
    if (tip == 'paket') return _paketler;
    return _hizmetler;
  }

  double get _toplam {
    double t = 0;
    for (final k in _kalemler) {
      t += double.tryParse(k.fiyat.text.replaceAll(',', '.')) ?? 0;
    }
    return t;
  }

  @override
  void dispose() {
    _tahsilatTutari.dispose();
    _not.dispose();
    for (final k in _kalemler) {
      k.fiyat.dispose();
      k.adet.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 62,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: cs.onSurface, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Harici Tahsilat',
          style: TextStyle(
            color: cs.onSurface,
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: -0.3,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: context.appTheme.borderSubtle),
        ),
      ),
      body: _yukleniyor
          ? Center(
              child: CircularProgressIndicator(
                  color: cs.primary, strokeWidth: 2.5))
          : GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
                children: [
                  _musteriBanner(),
                  const SizedBox(height: 12),
                  _tarihAlani(),
                  const SizedBox(height: 16),
                  _baslikSatiri('Satış Kalemleri', Icons.shopping_bag_outlined),
                  const SizedBox(height: 8),
                  ..._kalemler.asMap().entries.map((e) => _kalemKart(e.key)),
                  const SizedBox(height: 4),
                  _kalemEkleButon(),
                  const SizedBox(height: 16),
                  _baslikSatiri('Tahsilat', Icons.account_balance_wallet_outlined),
                  const SizedBox(height: 8),
                  _tahsilatKart(),
                ],
              ),
            ),
      bottomNavigationBar: _yukleniyor ? null : _altBar(),
    );
  }

  Widget _musteriBanner() {
    final cs = context.colors;
    final ext = context.appTheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        gradient: ext.heroGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.person_rounded, color: cs.onPrimary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Müşteri',
                    style: TextStyle(
                        color: cs.onPrimary.withValues(alpha: 0.85),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600)),
                Text(widget.md.name,
                    style: TextStyle(
                        color: cs.onPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _baslikSatiri(String s, IconData ikon) {
    final cs = context.colors;
    return Row(
      children: [
        Icon(ikon, size: 18, color: cs.primary),
        const SizedBox(width: 8),
        Text(s,
            style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: cs.onSurface)),
      ],
    );
  }

  Widget _kart({required Widget child, EdgeInsets? padding}) {
    final cs = context.colors;
    return Container(
      padding: padding ?? const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.primary.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(
              color: cs.primary.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: child,
    );
  }

  Widget _tarihAlani() {
    final cs = context.colors;
    return _kart(
      child: Row(
        children: [
          Icon(Icons.event_rounded, color: cs.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Satış Tarihi',
                    style: TextStyle(
                        fontSize: 11.5,
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600)),
                Text(DateFormat('dd.MM.yyyy').format(_satisTarihi),
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface)),
              ],
            ),
          ),
          TextButton(
            onPressed: _tarihSec,
            child: const Text('Değiştir',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _tarihSec() async {
    final secilen = await showDatePicker(
      context: context,
      initialDate: _satisTarihi,
      firstDate: DateTime(2015),
      lastDate: DateTime.now(),
    );
    if (secilen != null) setState(() => _satisTarihi = secilen);
  }

  Widget _kalemKart(int i) {
    final cs = context.colors;
    final k = _kalemler[i];
    final urunMu = k.tip == 'urun';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _kart(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: _tipSecici(k)),
                if (_kalemler.length > 1)
                  IconButton(
                    icon: Icon(Icons.delete_outline_rounded,
                        color: cs.error, size: 22),
                    onPressed: () => setState(() {
                      _kalemler[i].fiyat.dispose();
                      _kalemler[i].adet.dispose();
                      _kalemler.removeAt(i);
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _kalemSec(i),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: cs.primary.withValues(alpha: 0.18)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        k.ad.isEmpty ? 'Seç...' : k.ad,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: k.ad.isEmpty
                              ? cs.onSurfaceVariant.withValues(alpha: 0.7)
                              : cs.onSurface,
                        ),
                      ),
                    ),
                    Icon(Icons.expand_more_rounded,
                        color: cs.onSurfaceVariant),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: urunMu ? 2 : 1,
                  child: _miniAlan(
                    label: 'Fiyat (₺)',
                    controller: k.fiyat,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                if (urunMu) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: _miniAlan(label: 'Adet', controller: k.adet),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tipSecici(_KalemSatir k) {
    final tipler = const [
      {'v': 'hizmet', 'ad': 'Hizmet'},
      {'v': 'urun', 'ad': 'Ürün'},
      {'v': 'paket', 'ad': 'Paket'},
    ];
    final cs = context.colors;
    return Wrap(
      spacing: 6,
      children: tipler.map((t) {
        final secili = k.tip == t['v'];
        return GestureDetector(
          onTap: () => setState(() {
            k.tip = t['v']!;
            k.id = null;
            k.ad = '';
            k.fiyat.text = '';
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: secili
                  ? cs.primary
                  : cs.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              t['ad']!,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: secili ? cs.onPrimary : cs.primary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _miniAlan(
      {required String label,
      required TextEditingController controller,
      ValueChanged<String>? onChanged}) {
    final cs = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 11.5,
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          onChanged: onChanged,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderSide:
                  BorderSide(color: cs.primary.withValues(alpha: 0.18)),
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: cs.primary, width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Future<void> _kalemSec(int i) async {
    final k = _kalemler[i];
    final secenekler = _secenekler(k.tip);
    final secilen = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SecimSheet(secenekler: secenekler),
    );
    if (secilen != null) {
      setState(() {
        k.id = secilen['id'].toString();
        k.ad = secilen['ad'].toString();
        final f = (secilen['fiyat'] ?? '0').toString().replaceAll(',', '.');
        k.fiyat.text = (double.tryParse(f) ?? 0).toStringAsFixed(0);
      });
    }
  }

  Widget _kalemEkleButon() {
    final cs = context.colors;
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () => setState(() => _kalemler.add(_KalemSatir())),
        icon: Icon(Icons.add_circle_outline_rounded, color: cs.primary),
        label: Text('Kalem Ekle',
            style: TextStyle(color: cs.primary, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _tahsilatKart() {
    final cs = context.colors;
    return _kart(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _miniAlan(label: 'Tahsil Edilen Tutar (₺)', controller: _tahsilatTutari),
          const SizedBox(height: 12),
          Text('Ödeme Yöntemi',
              style: TextStyle(
                  fontSize: 11.5,
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Row(
            children: _odemeler.map((o) {
              final secili = _odemeYontemi == o['id'];
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _odemeYontemi = o['id'] as String),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: secili
                            ? cs.primary
                            : cs.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(o['icon'] as IconData,
                              size: 20,
                              color: secili ? cs.onPrimary : cs.primary),
                          const SizedBox(height: 4),
                          Text(o['ad'] as String,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      secili ? cs.onPrimary : cs.primary)),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _not,
            maxLines: 2,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: 'Not (opsiyonel)',
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              enabledBorder: OutlineInputBorder(
                borderSide:
                    BorderSide(color: cs.primary.withValues(alpha: 0.18)),
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: cs.primary, width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _altBar() {
    final cs = context.colors;
    final tryf = NumberFormat('#,##0.00', 'tr_TR');
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border:
              Border(top: BorderSide(color: context.appTheme.borderSubtle)),
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Toplam',
                    style: TextStyle(
                        fontSize: 11.5,
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600)),
                Text('${tryf.format(_toplam)} ₺',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface)),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _kaydediyor ? null : _kaydet,
                  icon: _kaydediyor
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_rounded, size: 20),
                  label: Text(_kaydediyor ? 'Kaydediliyor...' : 'Tahsilatı Kaydet',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _kaydet() async {
    // Gecerli kalemler
    final kalemler = <Map<String, dynamic>>[];
    for (final k in _kalemler) {
      if (k.id == null || k.id!.isEmpty) continue;
      kalemler.add({
        'tip': k.tip,
        'id': k.id,
        'fiyat': k.fiyat.text.replaceAll(',', '.'),
        'adet': k.adet.text.replaceAll(',', '.'),
      });
    }
    if (kalemler.isEmpty) {
      _uyari('En az bir geçerli satış kalemi seçin.');
      return;
    }
    if (_olusturanId == null) {
      _uyari('Oturum bilgisi alınamadı.');
      return;
    }

    setState(() => _kaydediyor = true);
    try {
      final res = await hariciTahsilatEkle(
        salonid: _salonId ?? '',
        musteriId: widget.md.id.toString(),
        olusturanId: _olusturanId!,
        satisTarihi: DateFormat('yyyy-MM-dd').format(_satisTarihi),
        kalemler: kalemler,
        tahsilatTutari: _tahsilatTutari.text.replaceAll(',', '.'),
        odemeYontemi: _odemeYontemi,
        not: _not.text,
      );
      if (!mounted) return;
      if (res['durum'] == 'basarili') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['mesaj']?.toString() ?? 'Kaydedildi.')),
        );
        Navigator.pop(context, true);
      } else {
        _uyari(res['mesaj']?.toString() ?? 'Kayıt başarısız.');
      }
    } catch (_) {
      _uyari('Kayıt sırasında bir hata oluştu.');
    } finally {
      if (mounted) setState(() => _kaydediyor = false);
    }
  }

  void _uyari(String s) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(s)));
  }
}

/// Hizmet/Ürün/Paket seçimi için aramalı bottom sheet.
class _SecimSheet extends StatefulWidget {
  final List<Map<String, dynamic>> secenekler;
  const _SecimSheet({required this.secenekler});

  @override
  State<_SecimSheet> createState() => _SecimSheetState();
}

class _SecimSheetState extends State<_SecimSheet> {
  final _ctrl = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final filtre = _q.isEmpty
        ? widget.secenekler
        : widget.secenekler
            .where((e) =>
                e['ad'].toString().toLowerCase().contains(_q.toLowerCase()))
            .toList();
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (ctx, scroll) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
        child: Column(
          children: [
            Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(999)),
            ),
            TextField(
              controller: _ctrl,
              autofocus: true,
              onChanged: (v) => setState(() => _q = v),
              decoration: InputDecoration(
                hintText: 'Ara...',
                prefixIcon: Icon(Icons.search_rounded, color: cs.primary),
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
                enabledBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: cs.primary.withValues(alpha: 0.18)),
                  borderRadius: BorderRadius.circular(14),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: cs.primary, width: 1.5),
                  borderRadius: BorderRadius.circular(14),
                ),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: filtre.isEmpty
                  ? Center(
                      child: Text('Sonuç yok',
                          style: TextStyle(color: cs.onSurfaceVariant)))
                  : ListView.separated(
                      controller: scroll,
                      itemCount: filtre.length,
                      separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.12)),
                      itemBuilder: (_, i) {
                        final e = filtre[i];
                        return ListTile(
                          title: Text(e['ad'].toString(),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                          trailing: Text('${e['fiyat']} ₺',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: cs.primary)),
                          onTap: () => Navigator.pop(context, e),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

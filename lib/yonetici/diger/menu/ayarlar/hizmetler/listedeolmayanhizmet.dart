import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Models/cihazlar.dart';
import 'package:randevu_sistem/Models/hizmetkategorisi.dart';
import 'package:randevu_sistem/Models/personel.dart';
import 'package:randevu_sistem/theme/app_tokens.dart';
import 'hizmetler.dart';

class ListedeOlmayanHizmet extends StatefulWidget {
  final dynamic isletmebilgi;
  const ListedeOlmayanHizmet({super.key, required this.isletmebilgi});

  @override
  State<ListedeOlmayanHizmet> createState() => _ListedeOlmayanHizmetState();
}

class _ListedeOlmayanHizmetState extends State<ListedeOlmayanHizmet> {
  bool _yukleniyor = true;
  bool _kaydediliyor = false;

  final TextEditingController _adCtrl = TextEditingController();
  final TextEditingController _fiyatCtrl = TextEditingController();
  final TextEditingController _sureCtrl = TextEditingController();

  List<HizmetKategorisi> _kategoriler = [];
  List<Personel> _tumPersoneller = [];
  List<Cihaz> _tumCihazlar = [];

  HizmetKategorisi? _seciliKategori;
  String _cinsiyet = ''; // '0' Kadin, '1' Erkek, '2' Unisex
  final Set<String> _secilenPersonelIds = {};
  final Set<String> _secilenCihazIds = {};

  String _salonId = '';

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  @override
  void dispose() {
    _adCtrl.dispose();
    _fiyatCtrl.dispose();
    _sureCtrl.dispose();
    super.dispose();
  }

  Future<void> _yukle() async {
    _salonId = (await secilisalonid()) ?? '';
    final kategoriler = await hizmetkategorileri();
    final personeller = await personellistegetir(_salonId);
    final cihazlar = await isletmecihazlari(_salonId);
    if (!mounted) return;
    setState(() {
      _kategoriler = kategoriler;
      _tumPersoneller = personeller;
      _tumCihazlar = cihazlar;
      _yukleniyor = false;
    });
  }

  Future<void> _kaydet() async {
    if (_kaydediliyor) return;

    final ad = _adCtrl.text.trim();
    final fiyat = _fiyatCtrl.text.trim();
    final sure = _sureCtrl.text.trim();

    final eksik = <String>[];
    if (ad.isEmpty) eksik.add('Hizmet Adı');
    if (sure.isEmpty) eksik.add('Süre');
    if (fiyat.isEmpty) eksik.add('Fiyat');
    if (_seciliKategori == null) eksik.add('Kategori');
    if (_cinsiyet.isEmpty) eksik.add('Müşteri Cinsiyeti');
    if (_secilenPersonelIds.isEmpty && _secilenCihazIds.isEmpty) {
      eksik.add('Personel / Cihaz');
    }

    if (eksik.isNotEmpty) {
      _uyari('Eksik bilgi', 'Lütfen şu alanları doldurun:\n${eksik.join(', ')}');
      return;
    }

    final sureNum = double.tryParse(sure.replaceAll(',', '.'));
    final fiyatNum = double.tryParse(fiyat.replaceAll(',', '.'));
    if (sureNum == null || sureNum <= 0) {
      _uyari('Geçersiz süre', 'Süreyi dakika olarak (örn: 30) girin.');
      return;
    }
    if (fiyatNum == null || fiyatNum < 0) {
      _uyari('Geçersiz fiyat', 'Fiyat negatif olamaz.');
      return;
    }

    setState(() => _kaydediliyor = true);

    final formData = {
      'hizmet_kategorisi': _seciliKategori?.id ?? '',
      'hizmet_adi': ad,
      'hizmet_sure': sure,
      'hizmet_fiyati': fiyat,
      'cinsiyet': _cinsiyet,
      'personel_id': _secilenPersonelIds.toList(),
      'cihaz_id': _secilenCihazIds.toList(),
      'sube': widget.isletmebilgi['id'],
    };

    try {
      final response = await http
          .post(
            Uri.parse(
                'https://apptest.randevumcepte.com.tr/api/v1/sistemeyenihizmetekle'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(formData),
          )
          .timeout(const Duration(seconds: 30));

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Hizmet başarıyla eklendi'),
            backgroundColor: context.colors.primary,
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => Hizmetler(isletmebilgi: widget.isletmebilgi),
          ),
        );
      } else {
        setState(() => _kaydediliyor = false);
        _uyari(
          'Kayıt başarısız',
          'Sunucu hatası (${response.statusCode}). Tekrar deneyin.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _kaydediliyor = false);
      _uyari('Bağlantı hatası', 'Sunucuya ulaşılamadı.\n$e');
    }
  }

  Future<void> _yeniKategoriEkle() async {
    final ctrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final cs = context.colors;
    final ext = context.appTheme;
    final sonuc = await showDialog<String>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(ctx).cardColor,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: ext.heroGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: cs.primary.withValues(alpha: 0.30),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(Icons.add_rounded,
                        color: cs.onPrimary, size: 28),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Yeni Kategori',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  decoration: BoxDecoration(
                    color: ext.surfaceMuted,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: cs.primary.withValues(alpha: 0.18),
                      width: 1,
                    ),
                  ),
                  child: TextFormField(
                    controller: ctrl,
                    autofocus: true,
                    textInputAction: TextInputAction.done,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Örn: Cilt Bakımı',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 13),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Kategori adı gerekli';
                      }
                      if (v.trim().length < 2) return 'En az 2 karakter';
                      return null;
                    },
                    onFieldSubmitted: (_) {
                      if (formKey.currentState!.validate()) {
                        Navigator.pop(ctx, ctrl.text.trim());
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          side: BorderSide(
                              color: cs.primary.withValues(alpha: 0.30)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Vazgeç',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            Navigator.pop(ctx, ctrl.text.trim());
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cs.primary,
                          foregroundColor: cs.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Kaydet',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (sonuc != null && sonuc.isNotEmpty) {
      setState(() {
        final yeni = HizmetKategorisi(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          hizmet_kategori_adi: sonuc,
        );
        _kategoriler.add(yeni);
        _seciliKategori = yeni;
      });
    }
  }

  Future<void> _kategoriSec() async {
    final aramaCtrl = TextEditingController();
    String arama = '';
    final cs = context.colors;
    final ext = context.appTheme;
    final secim = await showModalBottomSheet<HizmetKategorisi>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, sheetSetState) {
            final filtreli = _kategoriler.where((k) {
              if (arama.isEmpty) return true;
              return k.hizmet_kategori_adi
                  .toLowerCase()
                  .contains(arama.toLowerCase());
            }).toList();
            return Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: Theme.of(ctx).cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Kategori Seç',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: ext.surfaceMuted,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: cs.primary.withValues(alpha: 0.18),
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: aramaCtrl,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface),
                      onChanged: (v) {
                        sheetSetState(() => arama = v);
                      },
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.search_rounded,
                            color: cs.primary, size: 20),
                        hintText: 'Kategori ara',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: filtreli.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Text(
                              'Eşleşme bulunamadı',
                              style: TextStyle(
                                  color: cs.onSurfaceVariant,
                                  fontWeight: FontWeight.w600),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            itemCount: filtreli.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 4),
                            itemBuilder: (_, i) {
                              final k = filtreli[i];
                              final secili = _seciliKategori?.id == k.id;
                              return Material(
                                color: secili
                                    ? cs.primary.withValues(alpha: 0.10)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () => Navigator.pop(ctx, k),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 12),
                                    child: Row(
                                      children: [
                                        Icon(
                                          secili
                                              ? Icons.check_circle_rounded
                                              : Icons.circle_outlined,
                                          size: 20,
                                          color: secili
                                              ? cs.primary
                                              : cs.onSurfaceVariant
                                                  .withValues(alpha: 0.5),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            k.hizmet_kategori_adi,
                                            style: TextStyle(
                                              fontWeight: secili
                                                  ? FontWeight.w800
                                                  : FontWeight.w600,
                                              color: secili
                                                  ? cs.primary
                                                  : cs.onSurface,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (secim != null) {
      setState(() => _seciliKategori = secim);
    }
  }

  void _uyari(String title, String message) {
    final cs = context.colors;
    final ext = context.appTheme;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(ctx).cardColor,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: ext.warningColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: ext.warningColor.withValues(alpha: 0.20),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: ext.warningColor,
                  size: 28,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Tamam',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final ext = context.appTheme;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 62,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Yeni Hizmet',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: -0.3,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: ext.borderSubtle),
        ),
      ),
      body: _yukleniyor
          ? Center(
              child: CircularProgressIndicator(
                color: cs.primary,
                strokeWidth: 2.5,
              ),
            )
          : GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              behavior: HitTestBehavior.translucent,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
                children: [
                  _header(),
                  const SizedBox(height: 14),
                  _formCard(),
                  const SizedBox(height: 12),
                  _kategoriCard(),
                  const SizedBox(height: 12),
                  _cinsiyetCard(),
                  const SizedBox(height: 12),
                  _secimCard(
                    baslik: 'Personeller',
                    ikon: Icons.person_outline_rounded,
                    secimSayisi: _secilenPersonelIds.length,
                    toplam: _tumPersoneller.length,
                    children: _tumPersoneller.isEmpty
                        ? [const _EmptyMini(text: 'Personel tanımlı değil')]
                        : _tumPersoneller.map(_buildPersonelChip).toList(),
                  ),
                  const SizedBox(height: 12),
                  _secimCard(
                    baslik: 'Cihazlar',
                    ikon: Icons.devices_other_rounded,
                    secimSayisi: _secilenCihazIds.length,
                    toplam: _tumCihazlar.length,
                    children: _tumCihazlar.isEmpty
                        ? [const _EmptyMini(text: 'Cihaz tanımlı değil')]
                        : _tumCihazlar.map(_buildCihazChip).toList(),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: _yukleniyor ? null : _bottomBar(),
    );
  }

  Widget _header() {
    final cs = context.colors;
    final ext = context.appTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: ext.heroGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.30),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: cs.onPrimary.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.add_business_rounded,
                color: cs.onPrimary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Yeni Hizmet Oluştur',
                  style: TextStyle(
                    color: cs.onPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Sistemde olmayan bir hizmeti kendin ekle',
                  style: TextStyle(
                    color: cs.onPrimary.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _formCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _kartDekorasyon(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _labelLine(Icons.label_outline_rounded, 'Hizmet Adı'),
          const SizedBox(height: 6),
          _input(
            controller: _adCtrl,
            hint: 'Örn: Saç Kesim, Manikür',
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _labelLine(Icons.payments_rounded, 'Fiyat (₺)'),
                    const SizedBox(height: 6),
                    _input(
                      controller: _fiyatCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9.,]')),
                      ],
                      hint: '0',
                      prefixText: '₺ ',
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _labelLine(Icons.timer_outlined, 'Süre (dk)'),
                    const SizedBox(height: 6),
                    _input(
                      controller: _sureCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      hint: '0',
                      suffixText: 'dk',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kategoriCard() {
    final cs = context.colors;
    final ext = context.appTheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _kartDekorasyon(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.category_outlined,
                    color: cs.primary, size: 17),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Hizmet Kategorisi',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: _yeniKategoriEkle,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: ext.heroGradient,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: cs.primary.withValues(alpha: 0.30),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded,
                            size: 14, color: cs.onPrimary),
                        const SizedBox(width: 3),
                        Text(
                          'Yeni',
                          style: TextStyle(
                            color: cs.onPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 11.5,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _kategoriSec,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 13),
                decoration: BoxDecoration(
                  color: ext.surfaceMuted,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: cs.primary.withValues(alpha: 0.18),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _seciliKategori?.hizmet_kategori_adi ??
                            'Kategori seç',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _seciliKategori == null
                              ? cs.onSurfaceVariant
                              : cs.onSurface,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ),
                    Icon(Icons.unfold_more_rounded,
                        color: cs.primary.withValues(alpha: 0.7), size: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cinsiyetCard() {
    final cs = context.colors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _kartDekorasyon(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.people_alt_outlined,
                    color: cs.primary, size: 17),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Müşteri Cinsiyeti',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _cinsiyetPill(
                  label: 'Kadın',
                  value: '0',
                  icon: Icons.woman_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _cinsiyetPill(
                  label: 'Erkek',
                  value: '1',
                  icon: Icons.man_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _cinsiyetPill(
                  label: 'Unisex',
                  value: '2',
                  icon: Icons.wc_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cinsiyetPill({
    required String label,
    required String value,
    required IconData icon,
  }) {
    final cs = context.colors;
    final selected = _cinsiyet == value;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _cinsiyet = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? cs.primary : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? cs.primary : cs.primary.withValues(alpha: 0.20),
              width: 1.2,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: cs.primary.withValues(alpha: 0.30),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? cs.onPrimary : cs.primary,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: selected ? cs.onPrimary : cs.primary,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _secimCard({
    required String baslik,
    required IconData ikon,
    required int secimSayisi,
    required int toplam,
    required List<Widget> children,
  }) {
    final cs = context.colors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _kartDekorasyon(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(ikon, color: cs.primary, size: 17),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  baslik,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: secimSayisi > 0
                      ? cs.primary.withValues(alpha: 0.14)
                      : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$secimSayisi / $toplam',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: secimSayisi > 0 ? cs.primary : cs.onSurfaceVariant,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: children),
        ],
      ),
    );
  }

  Widget _buildPersonelChip(Personel p) {
    final selected = _secilenPersonelIds.contains(p.id);
    return _SecimChip(
      label: p.personel_adi,
      icon: Icons.person_rounded,
      selected: selected,
      onTap: () {
        setState(() {
          if (selected) {
            _secilenPersonelIds.remove(p.id);
          } else {
            _secilenPersonelIds.add(p.id);
          }
        });
      },
    );
  }

  Widget _buildCihazChip(Cihaz c) {
    final selected = _secilenCihazIds.contains(c.id);
    return _SecimChip(
      label: c.cihaz_adi,
      icon: Icons.devices_rounded,
      selected: selected,
      onTap: () {
        setState(() {
          if (selected) {
            _secilenCihazIds.remove(c.id);
          } else {
            _secilenCihazIds.add(c.id);
          }
        });
      },
    );
  }

  Widget _bottomBar() {
    final cs = context.colors;
    final ext = context.appTheme;
    return Container(
      padding: EdgeInsets.fromLTRB(
        14,
        10,
        14,
        10 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: ext.shadowBase,
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: _kaydediliyor ? null : _kaydet,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              gradient: _kaydediliyor
                  ? LinearGradient(
                      colors: [
                        cs.onSurfaceVariant.withValues(alpha: 0.5),
                        cs.onSurfaceVariant.withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : ext.heroGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: _kaydediliyor
                  ? []
                  : [
                      BoxShadow(
                        color: cs.primary.withValues(alpha: 0.40),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
            ),
            alignment: Alignment.center,
            child: _kaydediliyor
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation(cs.onPrimary),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_rounded,
                          color: cs.onPrimary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Hizmeti Kaydet',
                        style: TextStyle(
                          color: cs.onPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _kartDekorasyon() {
    final cs = context.colors;
    return BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: cs.primary.withValues(alpha: 0.10),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: cs.primary.withValues(alpha: 0.05),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _labelLine(IconData icon, String label) {
    final cs = context.colors;
    return Row(
      children: [
        Icon(icon, size: 15, color: cs.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
            letterSpacing: -0.1,
          ),
        ),
      ],
    );
  }

  Widget _input({
    required TextEditingController controller,
    String? hint,
    String? prefixText,
    String? suffixText,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final cs = context.colors;
    final ext = context.appTheme;
    return Container(
      decoration: BoxDecoration(
        color: ext.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cs.primary.withValues(alpha: 0.18),
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: cs.onSurface,
          letterSpacing: -0.1,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w500,
            fontSize: 13.5,
          ),
          prefixText: prefixText,
          prefixStyle: TextStyle(
            color: cs.primary,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
          suffixText: suffixText,
          suffixStyle: TextStyle(
            color: cs.primary,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        ),
      ),
    );
  }
}

class _SecimChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _SecimChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? cs.primary : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? cs.primary : cs.primary.withValues(alpha: 0.30),
              width: 1.2,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: cs.primary.withValues(alpha: 0.30),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? Icons.check_rounded : icon,
                size: 14,
                color: selected ? cs.onPrimary : cs.primary,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: selected ? cs.onPrimary : cs.primary,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyMini extends StatelessWidget {
  final String text;
  const _EmptyMini({required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontStyle: FontStyle.italic,
          color: cs.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Frontend/sfdatatable.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:randevu_sistem/Models/hizmetler.dart';
import 'package:randevu_sistem/theme/app_tokens.dart';
import 'package:randevu_sistem/yonetici/diger/menu/ayarlar/hizmetler/listedeolmayanhizmet.dart';
import 'calisan_secim.dart';

class HizmetSecimi extends StatefulWidget {
  final dynamic isletmebilgi;
  final HizmetlerDataSource hizmetDataGridSource;

  const HizmetSecimi({
    Key? key,
    required this.isletmebilgi,
    required this.hizmetDataGridSource,
  }) : super(key: key);

  @override
  _HizmetSecimiState createState() => _HizmetSecimiState();
}

class _HizmetSecimiState extends State<HizmetSecimi> {
  List<Hizmet> hizmet = [];
  List<Hizmet> filteredhizmet = [];
  List<Hizmet> secilihizmetler = [];
  bool isloading = true;
  late String seciliisletme;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    initialize();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void initialize() async {
    seciliisletme = (await secilisalonid())!;
    final List<Hizmet> hizmetlist =
        await seciliolmayanhizmetgetir(seciliisletme);
    if (!mounted) return;
    setState(() {
      hizmet = hizmetlist;
      filteredhizmet = hizmetlist;
      isloading = false;
    });
  }

  void _onSearchChanged(String value) {
    final q = value.toLowerCase();
    setState(() {
      if (q.isEmpty) {
        filteredhizmet = List.from(hizmet);
      } else {
        filteredhizmet = hizmet.where((h) {
          final ad = h.hizmet_adi.toLowerCase();
          final kat = (h.hizmet_kategori['hizmet_kategorisi_adi'] ?? '')
              .toString()
              .toLowerCase();
          return ad.contains(q) || kat.contains(q);
        }).toList();
      }
    });
  }

  void _toggleSecim(Hizmet h) {
    setState(() {
      if (secilihizmetler.contains(h)) {
        secilihizmetler.remove(h);
      } else {
        secilihizmetler.add(h);
      }
    });
  }

  String _temizleVeBirlestir(String? hizmetAdi, String? kategoriAdi) {
    String hAdi = hizmetAdi?.trim() ?? '';
    String kAdi = kategoriAdi?.trim() ?? '';
    final RegExp temizleyici = RegExp('[​﻿]');
    hAdi = hAdi.replaceAll(temizleyici, '');
    kAdi = kAdi.replaceAll(temizleyici, '');
    return kAdi.isEmpty ? hAdi : '$hAdi  ·  $kAdi';
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final int sayi = secilihizmetler.length;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 62,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: cs.onSurface, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Hizmet Seçimi',
          style: TextStyle(
            color: cs.onSurface,
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          if (widget.isletmebilgi != null &&
              widget.isletmebilgi["demo_hesabi"].toString() == "1")
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              child: SizedBox(
                width: 100,
                child: YukseltButonu(isletme_bilgi: widget.isletmebilgi),
              ),
            ),
          const SizedBox(width: 6),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: context.appTheme.borderSubtle),
        ),
      ),
      body: isloading
          ? Center(
              child: CircularProgressIndicator(
                  color: cs.primary, strokeWidth: 2.5),
            )
          : GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(child: _buildList()),
                ],
              ),
            ),
      bottomNavigationBar: isloading ? null : _buildBottomBar(sayi),
    );
  }

  Widget _buildHeader() {
    final cs = context.colors;
    final ext = context.appTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      child: Column(
        children: [
          // Arama
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: cs.primary.withValues(alpha: 0.10),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: TextField(
              controller: _searchCtrl,
              textInputAction: TextInputAction.search,
              onChanged: _onSearchChanged,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
              decoration: InputDecoration(
                hintText: 'Hizmet veya kategori ara',
                hintStyle: TextStyle(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon:
                    Icon(Icons.search_rounded, color: cs.primary, size: 22),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close_rounded,
                            size: 18, color: cs.onSurfaceVariant),
                        onPressed: () {
                          _searchCtrl.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Listede olmayan hizmet kartı
          Material(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ListedeOlmayanHizmet(
                      isletmebilgi: widget.isletmebilgi,
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: cs.primary.withValues(alpha: 0.10),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: cs.primary.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: ext.heroGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: cs.primary.withValues(alpha: 0.30),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(Icons.add_rounded,
                          color: cs.onPrimary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Listede olmayan hizmet',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: cs.onSurface,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Kendi hizmetini oluştur',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        color: cs.onSurfaceVariant, size: 22),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (filteredhizmet.isEmpty) {
      return _buildEmpty();
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      itemCount: filteredhizmet.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) => _buildHizmetItem(filteredhizmet[i]),
    );
  }

  Widget _buildHizmetItem(Hizmet h) {
    final cs = context.colors;
    final bool secili = secilihizmetler.contains(h);
    final String adi = _temizleVeBirlestir(
      h.hizmet_adi,
      h.hizmet_kategori['hizmet_kategorisi_adi']?.toString(),
    );
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _toggleSecim(h),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: secili
                  ? cs.primary.withValues(alpha: 0.45)
                  : cs.primary.withValues(alpha: 0.08),
              width: secili ? 1.4 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: cs.primary.withValues(alpha: secili ? 0.10 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: secili ? cs.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: secili
                        ? cs.primary
                        : cs.outline.withValues(alpha: 0.45),
                    width: 1.6,
                  ),
                ),
                child: secili
                    ? Icon(Icons.check_rounded,
                        color: cs.onPrimary, size: 16)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  adi,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: secili ? FontWeight.w800 : FontWeight.w600,
                    color: cs.onSurface,
                    letterSpacing: -0.15,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    final cs = context.colors;
    final aramada = _searchCtrl.text.isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                aramada ? Icons.search_off_rounded : Icons.spa_rounded,
                size: 44,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              aramada ? 'Eşleşme bulunamadı' : 'Hizmet listesi boş',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              aramada
                  ? 'Aramanı temizleyip tekrar deneyebilirsin.'
                  : 'Yukarıdan "Listede olmayan hizmet" ile kendi hizmetini oluşturabilirsin.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(int sayi) {
    final cs = context.colors;
    final ext = context.appTheme;
    final bool active = sayi > 0;
    return Container(
      padding: EdgeInsets.fromLTRB(
        14,
        10,
        14,
        10 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(color: ext.borderSubtle, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded,
                    size: 16, color: cs.primary),
                const SizedBox(width: 6),
                Text(
                  '$sayi seçili',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                    color: cs.primary,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: active
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CalisanSecimi(
                            isletmebilgi: widget.isletmebilgi,
                            secilihizmetler: secilihizmetler,
                            hizmetDataGridSource:
                                widget.hizmetDataGridSource,
                            yeniEkleme: true,
                          ),
                        ),
                      );
                    }
                  : null,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  gradient: active ? ext.heroGradient : null,
                  color: active
                      ? null
                      : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: cs.primary.withValues(alpha: 0.30),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Sonraki',
                      style: TextStyle(
                        color: active
                            ? cs.onPrimary
                            : cs.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: active
                          ? cs.onPrimary
                          : cs.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Gorusme sonucu kaydetme formu (bottom sheet).
// Sonuc + kategori + not + (geri arama tarih/saat) + (satis tutari) toplar ve
// CagriApi.notEkle ile kaydeder. Web paneldeki sonuc formuyla ayni semantik.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:randevu_sistem/theme/app_tokens.dart';
import '../cagri_api.dart';
import '../cagri_models.dart';

/// Sonuc formunu acar. Kaydedilirse true doner (cagiran listeyi yeniler).
Future<bool?> sonucFormuGoster(
  BuildContext context, {
  required int aramaDetayId,
  required int aranacakMusteriId,
  required String musteriAd,
  required String sube,
  String? mevcutNot,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SonucFormu(
      aramaDetayId: aramaDetayId,
      aranacakMusteriId: aranacakMusteriId,
      musteriAd: musteriAd,
      sube: sube,
      mevcutNot: mevcutNot,
    ),
  );
}

class _SonucSecenek {
  final int kod;
  final String ad;
  final IconData icon;
  const _SonucSecenek(this.kod, this.ad, this.icon);
}

const List<_SonucSecenek> _secenekler = [
  _SonucSecenek(CagriDurum.gorusuldu, 'Görüşüldü', Icons.check_circle_outline),
  _SonucSecenek(CagriDurum.cevapsiz, 'Cevapsız', Icons.phone_missed_outlined),
  _SonucSecenek(CagriDurum.mesgul, 'Meşgul', Icons.phone_disabled_outlined),
  _SonucSecenek(CagriDurum.ulasilamadi, 'Ulaşılamadı', Icons.signal_cellular_off_outlined),
  _SonucSecenek(CagriDurum.onGorusme, 'Ön Görüşme', Icons.event_available_outlined),
  _SonucSecenek(CagriDurum.telefondaSatis, 'Telefonda Satış', Icons.shopping_bag_outlined),
];

class _SonucFormu extends StatefulWidget {
  final int aramaDetayId;
  final int aranacakMusteriId;
  final String musteriAd;
  final String sube;
  final String? mevcutNot;

  const _SonucFormu({
    required this.aramaDetayId,
    required this.aranacakMusteriId,
    required this.musteriAd,
    required this.sube,
    this.mevcutNot,
  });

  @override
  State<_SonucFormu> createState() => _SonucFormuState();
}

class _SonucFormuState extends State<_SonucFormu> {
  int? _sonuc;
  bool _tekrarAra = false; // durum 3
  DateTime? _tekrarTarih;
  TimeOfDay? _tekrarSaat;
  final TextEditingController _not = TextEditingController();
  final TextEditingController _satis = TextEditingController();

  List<CagriKategori> _kategoriler = [];
  int? _kategoriId;
  int? _altKategoriId;

  bool _kaydediyor = false;

  @override
  void initState() {
    super.initState();
    if ((widget.mevcutNot ?? '').isNotEmpty) _not.text = widget.mevcutNot!;
    _kategorileriYukle();
  }

  Future<void> _kategorileriYukle() async {
    try {
      final k = await CagriApi.kategoriler(widget.sube);
      if (mounted) setState(() => _kategoriler = k);
    } catch (_) {}
  }

  @override
  void dispose() {
    _not.dispose();
    _satis.dispose();
    super.dispose();
  }

  bool get _satisMi => _sonuc == CagriDurum.telefondaSatis;
  // Geri arama gereken durumlar: On Gorusme (6) veya Tekrar Aranacak (3 - checkbox).
  bool get _geriAramaGerekli => _sonuc == CagriDurum.onGorusme || _tekrarAra;

  Future<void> _tarihSec() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _tekrarTarih ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (d != null) setState(() => _tekrarTarih = d);
  }

  Future<void> _saatSec() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _tekrarSaat ?? TimeOfDay.now(),
    );
    if (t != null) setState(() => _tekrarSaat = t);
  }

  Future<void> _kaydet() async {
    // Dogrulama
    if (_geriAramaGerekli && (_tekrarTarih == null || _tekrarSaat == null)) {
      _uyar('Geri arama için tarih ve saat seçin.');
      return;
    }
    if (_satisMi && (double.tryParse(_satis.text.replaceAll(',', '.')) ?? 0) <= 0) {
      _uyar('Satış tutarı girin.');
      return;
    }

    setState(() => _kaydediyor = true);
    String? tarihStr;
    String? saatStr;
    if (_geriAramaGerekli && _tekrarTarih != null && _tekrarSaat != null) {
      tarihStr = DateFormat('yyyy-MM-dd').format(_tekrarTarih!);
      saatStr =
          '${_tekrarSaat!.hour.toString().padLeft(2, '0')}:${_tekrarSaat!.minute.toString().padLeft(2, '0')}';
    }

    try {
      final ok = await CagriApi.notEkle(
        aramaDetayId: widget.aramaDetayId,
        aranacakMusteriId: widget.aranacakMusteriId,
        noticerik: _not.text.trim(),
        sonuc: _sonuc,
        kategoriId: _kategoriId,
        altKategoriId: _altKategoriId,
        satisTutari: _satisMi ? _satis.text.trim() : null,
        santralnottarih: tarihStr,
        santralnotsaat: saatStr,
        sube: widget.sube,
      );
      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pop(true);
      } else {
        setState(() => _kaydediyor = false);
        _uyar('Kaydedilemedi, tekrar deneyin.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _kaydediyor = false);
      _uyar('Hata: $e');
    }
  }

  void _uyar(String m) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(m), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final ext = context.appTheme;
    final altlar = _kategoriId == null
        ? <AltKategori>[]
        : (_kategoriler.firstWhere(
            (k) => k.id == _kategoriId,
            orElse: () => CagriKategori(id: -1, ad: '', altlar: []),
          )).altlar;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.78,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scroll) => Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: ext.borderStrong,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                child: Row(
                  children: [
                    Icon(Icons.assignment_turned_in_outlined, color: cs.primary, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Görüşme Sonucu',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w700, color: cs.onSurface),
                      ),
                    ),
                    Text(widget.musteriAd,
                        style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scroll,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  children: [
                    // Sonuc secenekleri
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _secenekler.map((s) {
                        final secili = _sonuc == s.kod;
                        return InkWell(
                          onTap: () => setState(() {
                            _sonuc = s.kod;
                            if (s.kod != CagriDurum.onGorusme) {
                              // on gorusme disindaki sonuclar geri aramayi otomatik tetiklemez
                            }
                          }),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: secili ? cs.primary.withValues(alpha: 0.12) : cs.surface,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(
                                color: secili ? cs.primary : ext.borderSubtle,
                                width: secili ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(s.icon,
                                    size: 18,
                                    color: secili ? cs.primary : cs.onSurfaceVariant),
                                const SizedBox(width: 6),
                                Text(s.ad,
                                    style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: secili ? FontWeight.w700 : FontWeight.w500,
                                        color: secili ? cs.primary : cs.onSurface)),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    // Tekrar aranacak (durum 3)
                    if (!_satisMi)
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: _tekrarAra,
                        onChanged: (v) => setState(() => _tekrarAra = v ?? false),
                        title: const Text('Daha sonra tekrar aranacak'),
                        subtitle: const Text('Belirtilen tarih/saatte hatırlatma çıkar'),
                      ),

                    // Geri arama tarih/saat
                    if (_geriAramaGerekli) ...[
                      Row(
                        children: [
                          Expanded(
                            child: _seciciButon(
                              context,
                              icon: Icons.calendar_today_outlined,
                              label: _tekrarTarih == null
                                  ? 'Tarih seç'
                                  : DateFormat('dd.MM.yyyy').format(_tekrarTarih!),
                              onTap: _tarihSec,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _seciciButon(
                              context,
                              icon: Icons.access_time,
                              label: _tekrarSaat == null
                                  ? 'Saat seç'
                                  : _tekrarSaat!.format(context),
                              onTap: _saatSec,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Satis tutari
                    if (_satisMi) ...[
                      TextField(
                        controller: _satis,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Satış Tutarı (₺)',
                          prefixIcon: const Icon(Icons.payments_outlined),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md)),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Kategori
                    if (_kategoriler.isNotEmpty) ...[
                      DropdownButtonFormField<int?>(
                        value: _kategoriId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Kategori (opsiyonel)',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md)),
                        ),
                        items: [
                          const DropdownMenuItem<int?>(value: null, child: Text('—')),
                          ..._kategoriler.map((k) =>
                              DropdownMenuItem<int?>(value: k.id, child: Text(k.ad))),
                        ],
                        onChanged: (v) => setState(() {
                          _kategoriId = v;
                          _altKategoriId = null;
                        }),
                      ),
                      const SizedBox(height: 12),
                      if (altlar.isNotEmpty)
                        DropdownButtonFormField<int?>(
                          value: _altKategoriId,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Alt Kategori (opsiyonel)',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppRadius.md)),
                          ),
                          items: [
                            const DropdownMenuItem<int?>(value: null, child: Text('—')),
                            ...altlar.map((a) =>
                                DropdownMenuItem<int?>(value: a.id, child: Text(a.ad))),
                          ],
                          onChanged: (v) => setState(() => _altKategoriId = v),
                        ),
                      if (altlar.isNotEmpty) const SizedBox(height: 12),
                    ],

                    // Not
                    TextField(
                      controller: _not,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Görüşme Notu',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md)),
                      ),
                    ),
                  ],
                ),
              ),
              // Kaydet
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _kaydediyor ? null : _kaydet,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md)),
                      ),
                      icon: _kaydediyor
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save_outlined),
                      label: Text(_kaydediyor ? 'Kaydediliyor...' : 'Sonucu Kaydet',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _seciciButon(BuildContext context,
      {required IconData icon, required String label, required VoidCallback onTap}) {
    final cs = context.colors;
    final ext = context.appTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: ext.borderSubtle),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: cs.primary),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 13.5))),
          ],
        ),
      ),
    );
  }
}

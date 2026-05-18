import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Backend/yetki.dart';
import 'package:randevu_sistem/Models/isletmehizmetleri.dart';
import 'package:randevu_sistem/Models/musteri_danisanlar.dart';
import 'package:randevu_sistem/Models/paketler.dart';
import 'package:randevu_sistem/theme/premium_components.dart';

class SozlesmeOlustur extends StatefulWidget {
  final dynamic isletmebilgi;
  const SozlesmeOlustur({super.key, required this.isletmebilgi});

  @override
  State<SozlesmeOlustur> createState() => _SozlesmeOlusturState();
}

class _SozlesmeOlusturState extends State<SozlesmeOlustur> {
  String _seciliSube = '';
  bool _yukleniyor = true;
  bool _gonderiliyor = false;
  String? _hataMesaji;

  List<MusteriDanisan> _musteriler = [];
  List<IsletmeHizmet> _hizmetler = [];
  List<Paket> _paketler = [];

  MusteriDanisan? _musteri;
  IsletmeHizmet? _hizmet;
  Paket? _paket;

  final _telefon = TextEditingController();
  String _telOrijinal = '';
  bool get _telGor => Yetki.varMi('musteri.telefon_gor');
  final _seans = TextEditingController(text: '1');
  final _toplam = TextEditingController();
  final _kapora = TextEditingController(text: '0');
  final _metin = TextEditingController();
  final _not = TextEditingController();

  @override
  void initState() {
    super.initState();
    _baslat();
  }

  @override
  void dispose() {
    _telefon.dispose();
    _seans.dispose();
    _toplam.dispose();
    _kapora.dispose();
    _metin.dispose();
    _not.dispose();
    super.dispose();
  }

  Future<void> _baslat() async {
    try {
      _seciliSube = (await secilisalonid()) ?? '';
      final veri = await isletmeVerileriGetir(
          _seciliSube, false, '', '', '', 0, 0);
      _musteriler = ((veri['musteriler'] ?? []) as List)
          .whereType<MusteriDanisan>()
          .toList();
      _hizmetler = ((veri['hizmetler'] ?? []) as List)
          .whereType<IsletmeHizmet>()
          .toList();
      _paketler = ((veri['paketler'] ?? []) as List)
          .whereType<Paket>()
          .toList();
      _metin.text = _varsayilanMetin();
    } catch (e) {
      _hataMesaji = 'Veriler yüklenemedi: $e';
    }
    if (mounted) setState(() => _yukleniyor = false);
  }

  String _isletmeAdi() {
    final v = widget.isletmebilgi;
    if (v is Map) {
      for (final k in const ['salon_adi', 'isletme_adi', 'ad', 'name']) {
        final val = v[k];
        if (val != null && val.toString().trim().isNotEmpty) {
          return val.toString();
        }
      }
    }
    return 'İşletmemiz';
  }

  String _varsayilanMetin() {
    final ad = _isletmeAdi();
    return '1. Bu sözleşme $ad ile yukarıda bilgileri yazılı müşteri arasında akdedilmiştir.\n'
        '2. Müşteri, alacağı hizmet/paket karşılığında belirtilen toplam ücreti ödemeyi kabul ve taahhüt eder.\n'
        '3. Kapora/ön ödeme alındığı durumda kalan bakiye, hizmet süresi içerisinde tahsil edilecektir.\n'
        '4. Müşteri belirlenen randevu saatlerinde hazır bulunmakla yükümlüdür. Mazeretsiz iptaller veya gelmemeler için ücret iadesi yapılmaz.\n'
        '5. İşletme, hizmeti taahhüt edilen kalitede sunmakla yükümlüdür.\n'
        '6. Taraflar bu sözleşmeyi okuyup, anladığını ve kabul ettiğini beyan eder.';
  }

  Future<void> _musteriSec() async {
    final secilen = await _genelPicker<MusteriDanisan>(
      baslik: 'Müşteri Seç',
      ogeler: _musteriler,
      etiket: (m) => m.name,
      altYazi: (m) => Yetki.telefonGoster(m.cep_telefon),
      seciliId: _musteri?.id,
      ogeId: (m) => m.id,
    );
    if (secilen != null) {
      setState(() {
        _musteri = secilen;
        _telOrijinal = secilen.cep_telefon;
        _telefon.text = _telGor ? _telOrijinal : Yetki.telefonGoster(_telOrijinal);
      });
    }
  }

  Future<void> _hizmetSec() async {
    final secilen = await _genelPicker<IsletmeHizmet>(
      baslik: 'Hizmet Seç',
      ogeler: _hizmetler,
      etiket: (h) => h.hizmet?['hizmet_adi']?.toString() ?? '-',
      altYazi: (h) => '${h.fiyat} ₺',
      seciliId: _hizmet?.hizmet_id,
      ogeId: (h) => h.hizmet_id,
      temizleVar: true,
    );
    setState(() {
      _hizmet = secilen;
      if (secilen != null && _toplam.text.trim().isEmpty) {
        _toplam.text = secilen.fiyat;
      }
    });
  }

  Future<void> _paketSec() async {
    final secilen = await _genelPicker<Paket>(
      baslik: 'Paket Seç',
      ogeler: _paketler,
      etiket: (p) => p.paket_adi,
      altYazi: (p) => p.fiyat.isNotEmpty ? '${p.fiyat} ₺' : '',
      seciliId: _paket?.id,
      ogeId: (p) => p.id,
      temizleVar: true,
    );
    setState(() {
      _paket = secilen;
      if (secilen != null && secilen.fiyat.isNotEmpty && secilen.fiyat != '0') {
        _toplam.text = secilen.fiyat;
      }
    });
  }

  Future<T?> _genelPicker<T>({
    required String baslik,
    required List<T> ogeler,
    required String Function(T) etiket,
    required String Function(T) altYazi,
    required String? seciliId,
    required String Function(T) ogeId,
    bool temizleVar = false,
  }) {
    return showModalBottomSheet<T?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _PickerSheet<T>(
          baslik: baslik,
          ogeler: ogeler,
          etiket: etiket,
          altYazi: altYazi,
          seciliId: seciliId,
          ogeId: ogeId,
          temizleVar: temizleVar,
        );
      },
    );
  }

  Future<void> _gonder() async {
    if (_musteri == null) {
      showPremiumWarning(context,
          title: 'Müşteri Seçilmedi',
          message: 'Lütfen bir müşteri seçin.');
      return;
    }
    if (_telefon.text.trim().isEmpty) {
      showPremiumWarning(context,
          title: 'Telefon Boş',
          message: 'Müşteri cep telefonu zorunlu.');
      return;
    }
    final toplam = double.tryParse(_toplam.text.replaceAll(',', '.')) ?? 0;
    if (toplam <= 0) {
      showPremiumWarning(context,
          title: 'Toplam Ücret',
          message: 'Geçerli bir toplam ücret girin.');
      return;
    }
    if (_metin.text.trim().isEmpty) {
      showPremiumWarning(context,
          title: 'Sözleşme Şartları',
          message: 'Sözleşme metni boş olamaz.');
      return;
    }

    setState(() => _gonderiliyor = true);
    try {
      // form.gonder yetkisi yoksa: sozlesmeyi olustur ve arsive kaydet,
      // ama musteriye SMS atma.
      final sadeceKaydet = !Yetki.varMi('form.gonder');
      final body = {
        'sube': _seciliSube,
        'user_id': _musteri!.id,
        'cep_telefon': _telGor ? _telefon.text.trim() : _telOrijinal,
        'hizmet_id': _hizmet?.hizmet_id ?? '',
        'paket_id': _paket?.id ?? '',
        'seans_sayisi': int.tryParse(_seans.text) ?? 1,
        'toplam_ucret': toplam,
        'kapora': double.tryParse(_kapora.text.replaceAll(',', '.')) ?? 0,
        'sozlesme_metni': _metin.text,
        'sozlesme_notu': _not.text,
        'sadece_kaydet': sadeceKaydet,
      };
      final resp = await http.post(
        Uri.parse(
            'https://apptest.randevumcepte.com.tr/api/v1/sozlesme-olustur'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (resp.statusCode == 200) {
        final j = jsonDecode(resp.body);
        if (j is Map && j['basarili'] == true) {
          if (mounted) {
            await showPremiumWarning(context,
                title: sadeceKaydet ? 'Sözleşme Kaydedildi' : 'Sözleşme Gönderildi',
                message: sadeceKaydet
                    ? 'Sözleşme arşive eklendi. Gönderme yetkiniz olmadığı için müşteriye SMS atılmadı.'
                    : 'Müşteriye SMS ile sözleşme gönderildi.',
                tone: 'success');
          }
          if (mounted) Navigator.pop(context, true);
          return;
        }
        if (mounted) {
          showPremiumWarning(context,
              title: 'Gönderilemedi',
              message: (j is Map && j['mesaj'] != null)
                  ? j['mesaj'].toString()
                  : 'Bir hata oluştu, tekrar deneyin.',
              tone: 'error');
        }
      } else {
        if (mounted) {
          showPremiumWarning(context,
              title: 'Sunucu Hatası',
              message: 'Hata kodu: ${resp.statusCode}',
              tone: 'error');
        }
      }
    } catch (_) {
      if (mounted) {
        showPremiumWarning(context,
            title: 'Bağlantı Hatası',
            message: 'İnternet bağlantınızı kontrol edin.',
            tone: 'error');
      }
    } finally {
      if (mounted) setState(() => _gonderiliyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PremiumGradientBg(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(scheme),
              Expanded(
                child: _yukleniyor
                    ? const Center(child: CircularProgressIndicator())
                    : _hataMesaji != null
                        ? Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(_hataMesaji!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontWeight: FontWeight.w600)),
                          )
                        : _buildBody(scheme),
              ),
              if (!_yukleniyor && _hataMesaji == null) _buildBottom(scheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      child: Row(
        children: [
          PremiumCircleAction(
            icon: Icons.arrow_back_rounded,
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sözleşme Oluştur',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                    letterSpacing: -0.4,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Hizmet sözleşmesi hazırla ve müşteriye gönder',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ColorScheme scheme) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
      children: [
        PremiumGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Etiket('Müşteri *'),
              _SecimAlani(
                etiket: _musteri?.name ?? 'Müşteri seçin',
                altYazi: Yetki.telefonGoster(_musteri?.cep_telefon),
                ikon: Icons.person_outline_rounded,
                bos: _musteri == null,
                onTap: _musteriSec,
              ),
              const SizedBox(height: 14),
              const _Etiket('Cep Telefon *'),
              TextField(
                controller: _telefon,
                keyboardType: TextInputType.phone,
                readOnly: !_telGor,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9 *]')),
                ],
                decoration: _inputDeko('Müşteri seçince otomatik dolar', scheme),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        PremiumGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Etiket('Hizmet (opsiyonel)'),
              _SecimAlani(
                etiket: _hizmet?.hizmet?['hizmet_adi']?.toString() ??
                    'Hizmet seçin',
                altYazi: _hizmet != null ? '${_hizmet!.fiyat} ₺' : null,
                ikon: Icons.spa_outlined,
                bos: _hizmet == null,
                onTap: _hizmetSec,
              ),
              const SizedBox(height: 14),
              const _Etiket('Paket (opsiyonel)'),
              _SecimAlani(
                etiket: _paket?.paket_adi ?? 'Paket seçin',
                altYazi: (_paket != null && _paket!.fiyat.isNotEmpty)
                    ? '${_paket!.fiyat} ₺'
                    : null,
                ikon: Icons.inventory_2_outlined,
                bos: _paket == null,
                onTap: _paketSec,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        PremiumGlassCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Etiket('Seans'),
                    TextField(
                      controller: _seans,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      decoration: _inputDeko('1', scheme),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Etiket('Toplam Ücret *'),
                    TextField(
                      controller: _toplam,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: _inputDeko('0,00 ₺', scheme),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Etiket('Kapora'),
                    TextField(
                      controller: _kapora,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: _inputDeko('0,00 ₺', scheme),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        PremiumGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Etiket('Sözleşme Şartları *'),
              const Text(
                'Müşteriye gösterilecek metin — düzenleyebilirsiniz.',
                style: TextStyle(fontSize: 11, color: Colors.black54),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _metin,
                maxLines: 10,
                minLines: 6,
                style:
                    const TextStyle(fontFamily: 'monospace', fontSize: 12.5),
                decoration: _inputDeko('Sözleşme metni...', scheme),
              ),
              const SizedBox(height: 14),
              const _Etiket('Ek Not (opsiyonel)'),
              TextField(
                controller: _not,
                maxLines: 2,
                decoration: _inputDeko(
                    'Örn: Seans aralığı 15 günü geçemez.', scheme),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottom(ColorScheme scheme) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: _gonderiliyor ? null : _gonder,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [scheme.primary, scheme.tertiary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.30),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Center(
                child: _gonderiliyor
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Yetki.varMi('form.gonder')
                                ? Icons.send_rounded
                                : Icons.save_outlined,
                            color: scheme.onPrimary,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            Yetki.varMi('form.gonder')
                                ? 'Oluştur ve Müşteriye Gönder'
                                : 'Sadece Oluştur',
                            style: TextStyle(
                              color: scheme.onPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeko(String hint, ColorScheme scheme) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12.5, color: Colors.black38),
      filled: true,
      fillColor: scheme.primary.withValues(alpha: 0.05),
      isDense: true,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}

class _Etiket extends StatelessWidget {
  final String text;
  const _Etiket(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _SecimAlani extends StatelessWidget {
  final String etiket;
  final String? altYazi;
  final IconData ikon;
  final bool bos;
  final VoidCallback onTap;
  const _SecimAlani({
    required this.etiket,
    required this.ikon,
    required this.bos,
    required this.onTap,
    this.altYazi,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.primary.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(ikon, color: scheme.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      etiket,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: bos
                            ? Colors.black.withValues(alpha: 0.45)
                            : scheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (altYazi != null && altYazi!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        altYazi!,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: scheme.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.unfold_more_rounded,
                  size: 18, color: scheme.primary.withValues(alpha: 0.6)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickerSheet<T> extends StatefulWidget {
  final String baslik;
  final List<T> ogeler;
  final String Function(T) etiket;
  final String Function(T) altYazi;
  final String? seciliId;
  final String Function(T) ogeId;
  final bool temizleVar;
  const _PickerSheet({
    required this.baslik,
    required this.ogeler,
    required this.etiket,
    required this.altYazi,
    required this.seciliId,
    required this.ogeId,
    required this.temizleVar,
  });

  @override
  State<_PickerSheet<T>> createState() => _PickerSheetState<T>();
}

class _PickerSheetState<T> extends State<_PickerSheet<T>> {
  String _arama = '';
  final _aramaController = TextEditingController();

  @override
  void dispose() {
    _aramaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final filtreli = widget.ogeler.where((o) {
      if (_arama.isEmpty) return true;
      final q = _arama.toLowerCase();
      return widget.etiket(o).toLowerCase().contains(q) ||
          widget.altYazi(o).toLowerCase().contains(q);
    }).toList();
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (ctx, scroll) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.baslik,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                    ),
                    if (widget.temizleVar)
                      TextButton.icon(
                        onPressed: () => Navigator.pop<T?>(context, null),
                        icon: const Icon(Icons.clear_rounded, size: 16),
                        label: const Text('Temizle'),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                child: TextField(
                  controller: _aramaController,
                  onChanged: (v) => setState(() => _arama = v),
                  decoration: InputDecoration(
                    hintText: 'Ara...',
                    isDense: true,
                    prefixIcon: const Icon(Icons.search, size: 18),
                    filled: true,
                    fillColor: scheme.primary.withValues(alpha: 0.05),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: filtreli.isEmpty
                    ? Center(
                        child: Text(
                          'Sonuç yok',
                          style: TextStyle(
                              color: Colors.black.withValues(alpha: 0.5),
                              fontSize: 13),
                        ),
                      )
                    : ListView.builder(
                        controller: scroll,
                        itemCount: filtreli.length,
                        itemBuilder: (ctx, i) {
                          final o = filtreli[i];
                          final aktif =
                              widget.seciliId == widget.ogeId(o);
                          return ListTile(
                            dense: true,
                            tileColor: aktif
                                ? scheme.primary.withValues(alpha: 0.06)
                                : null,
                            title: Text(
                              widget.etiket(o),
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: aktif
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                              ),
                            ),
                            subtitle: widget.altYazi(o).isNotEmpty
                                ? Text(
                                    widget.altYazi(o),
                                    style: const TextStyle(fontSize: 11.5),
                                  )
                                : null,
                            trailing: aktif
                                ? Icon(Icons.check_circle_rounded,
                                    color: scheme.primary, size: 18)
                                : null,
                            onTap: () => Navigator.pop<T?>(context, o),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

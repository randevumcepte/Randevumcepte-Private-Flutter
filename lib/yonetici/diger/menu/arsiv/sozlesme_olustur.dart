import 'dart:convert';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:randevu_sistem/Backend/backend.dart';
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

  List<MusteriDanisan> _musteriler = [];
  List<IsletmeHizmet> _hizmetler = [];
  List<Paket> _paketler = [];

  MusteriDanisan? _musteri;
  IsletmeHizmet? _hizmet;
  Paket? _paket;

  final _telefon = TextEditingController();
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
    _seciliSube = (await secilisalonid()) ?? '';
    final veri = await isletmeVerileriGetir(_seciliSube, false, '', '', '', 0, 0);
    _musteriler = (veri['musteriler'] ?? []).cast<MusteriDanisan>();
    _hizmetler = (veri['hizmetler'] ?? []).cast<IsletmeHizmet>();
    _paketler = (veri['paketler'] ?? []).cast<Paket>();
    _metin.text = _varsayilanMetin();
    if (mounted) setState(() => _yukleniyor = false);
  }

  String _isletmeAdi() {
    final v = widget.isletmebilgi;
    final adaylar = ['salon_adi', 'isletme_adi', 'ad', 'name'];
    for (final k in adaylar) {
      if (v is Map && v[k] != null && v[k].toString().trim().isNotEmpty) {
        return v[k].toString();
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

  void _musteriSecildi(MusteriDanisan? m) {
    setState(() {
      _musteri = m;
      _telefon.text = m?.cep_telefon ?? '';
    });
  }

  void _hizmetSecildi(IsletmeHizmet? h) {
    setState(() {
      _hizmet = h;
      if (h != null && _toplam.text.trim().isEmpty) {
        _toplam.text = h.fiyat;
      }
    });
  }

  void _paketSecildi(Paket? p) {
    setState(() {
      _paket = p;
      if (p != null) {
        if (p.fiyat.isNotEmpty && p.fiyat != '0') _toplam.text = p.fiyat;
      }
    });
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
      final body = {
        'sube': _seciliSube,
        'user_id': _musteri!.id,
        'cep_telefon': _telefon.text.trim(),
        'hizmet_id': _hizmet?.hizmet_id ?? '',
        'paket_id': _paket?.id ?? '',
        'seans_sayisi': int.tryParse(_seans.text) ?? 1,
        'toplam_ucret': toplam,
        'kapora': double.tryParse(_kapora.text.replaceAll(',', '.')) ?? 0,
        'sozlesme_metni': _metin.text,
        'sozlesme_notu': _not.text,
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
                title: 'Sözleşme Gönderildi',
                message: 'Müşteriye SMS ile sözleşme gönderildi.',
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
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          title: const Text(
            'Hizmet Sözleşmesi Oluştur',
            style: TextStyle(
                color: Colors.black, fontWeight: FontWeight.w700, fontSize: 16),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
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
                              Icon(Icons.send_rounded,
                                  color: scheme.onPrimary, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Oluştur ve Müşteriye Gönder',
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
        ),
        body: _yukleniyor
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
                children: [
                  PremiumGlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _Etiket('Müşteri *'),
                        _MusteriSecici(
                          musteriler: _musteriler,
                          secili: _musteri,
                          onChanged: _musteriSecildi,
                        ),
                        const SizedBox(height: 14),
                        const _Etiket('Cep Telefon *'),
                        TextField(
                          controller: _telefon,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')),
                          ],
                          decoration: _inputDeko(
                              'Müşteri seçince otomatik dolar', scheme),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  PremiumGlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _Etiket('Hizmet (opsiyonel)'),
                        _HizmetSecici(
                          hizmetler: _hizmetler,
                          secili: _hizmet,
                          onChanged: _hizmetSecildi,
                        ),
                        const SizedBox(height: 14),
                        const _Etiket('Paket (opsiyonel)'),
                        _PaketSecici(
                          paketler: _paketler,
                          secili: _paket,
                          onChanged: _paketSecildi,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
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
                                keyboardType: const TextInputType
                                    .numberWithOptions(decimal: true),
                                decoration: _inputDeko('0.00 ₺', scheme),
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
                                keyboardType: const TextInputType
                                    .numberWithOptions(decimal: true),
                                decoration: _inputDeko('0.00 ₺', scheme),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
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
                          style: const TextStyle(
                              fontFamily: 'monospace', fontSize: 12.5),
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

class _MusteriSecici extends StatelessWidget {
  final List<MusteriDanisan> musteriler;
  final MusteriDanisan? secili;
  final ValueChanged<MusteriDanisan?> onChanged;
  const _MusteriSecici({
    required this.musteriler,
    required this.secili,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DropdownButtonHideUnderline(
      child: DropdownButton2<MusteriDanisan>(
        isExpanded: true,
        value: secili,
        hint: const Text('Müşteri seçin', style: TextStyle(fontSize: 13)),
        items: musteriler
            .map((m) => DropdownMenuItem(
                  value: m,
                  child: Text(
                    m.name,
                    style: const TextStyle(fontSize: 13.5),
                    overflow: TextOverflow.ellipsis,
                  ),
                ))
            .toList(),
        onChanged: onChanged,
        buttonStyleData: ButtonStyleData(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        dropdownStyleData: DropdownStyleData(
          maxHeight: 320,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
        ),
        dropdownSearchData: DropdownSearchData(
          searchController: TextEditingController(),
          searchInnerWidgetHeight: 50,
          searchInnerWidget: Padding(
            padding: const EdgeInsets.all(8),
            child: TextFormField(
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Müşteri ara...',
                prefixIcon: const Icon(Icons.search, size: 18),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          searchMatchFn: (item, q) =>
              (item.value as MusteriDanisan).name.toLowerCase().contains(q.toLowerCase()),
        ),
      ),
    );
  }
}

class _HizmetSecici extends StatelessWidget {
  final List<IsletmeHizmet> hizmetler;
  final IsletmeHizmet? secili;
  final ValueChanged<IsletmeHizmet?> onChanged;
  const _HizmetSecici(
      {required this.hizmetler,
      required this.secili,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DropdownButtonHideUnderline(
      child: DropdownButton2<IsletmeHizmet>(
        isExpanded: true,
        value: secili,
        hint: const Text('— Hizmet seçin —', style: TextStyle(fontSize: 13)),
        items: [
          const DropdownMenuItem<IsletmeHizmet>(
            value: null,
            child: Text('— Seçim yok —', style: TextStyle(fontSize: 13)),
          ),
          ...hizmetler.map((h) => DropdownMenuItem(
                value: h,
                child: Text(
                  h.hizmet?['hizmet_adi']?.toString() ?? '-',
                  style: const TextStyle(fontSize: 13.5),
                  overflow: TextOverflow.ellipsis,
                ),
              )),
        ],
        onChanged: onChanged,
        buttonStyleData: ButtonStyleData(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        dropdownStyleData: DropdownStyleData(
          maxHeight: 320,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

class _PaketSecici extends StatelessWidget {
  final List<Paket> paketler;
  final Paket? secili;
  final ValueChanged<Paket?> onChanged;
  const _PaketSecici(
      {required this.paketler,
      required this.secili,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DropdownButtonHideUnderline(
      child: DropdownButton2<Paket>(
        isExpanded: true,
        value: secili,
        hint: const Text('— Paket seçin —', style: TextStyle(fontSize: 13)),
        items: [
          const DropdownMenuItem<Paket>(
            value: null,
            child: Text('— Seçim yok —', style: TextStyle(fontSize: 13)),
          ),
          ...paketler.map((p) => DropdownMenuItem(
                value: p,
                child: Text(
                  p.paket_adi,
                  style: const TextStyle(fontSize: 13.5),
                  overflow: TextOverflow.ellipsis,
                ),
              )),
        ],
        onChanged: onChanged,
        buttonStyleData: ButtonStyleData(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        dropdownStyleData: DropdownStyleData(
          maxHeight: 320,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

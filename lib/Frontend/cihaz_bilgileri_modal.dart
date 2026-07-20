import 'package:flutter/material.dart';
import 'package:randevu_sistem/Backend/backend.dart';

/// Lazer epilasyon seansinda cihaz parametrelerini (Enerji/Jul, Hiz, MS,
/// Atis sayisi, Uygulamayi Yapan personel, Not) girmek/duzenlemek icin modal.
/// Bolge adi otomatik gelir (kartin/hizmetin adi). Ust kisimda seans secici
/// ile ayni bolgenin baska seanslarina gecilebilir.
///
/// [seansId]  : acilista yuklenecek seansin id'si (genelde en son seans).
/// [seanslar] : o bolgenin seanslari — secici icin [{id, no, tarih, geldi}].
/// Donus: kaydedildiyse true.
Future<bool?> cihazBilgileriModalGoster(
  BuildContext context, {
  required String seansId,
  required List<Map<String, dynamic>> seanslar,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => _CihazBilgileriSheet(
      seansId: seansId,
      seanslar: seanslar,
    ),
  );
}

const Color _indigo = Color(0xFF4F46E5);

class _CihazBilgileriSheet extends StatefulWidget {
  final String seansId;
  final List<Map<String, dynamic>> seanslar;

  const _CihazBilgileriSheet({
    required this.seansId,
    required this.seanslar,
  });

  @override
  State<_CihazBilgileriSheet> createState() => _CihazBilgileriSheetState();
}

class _CihazBilgileriSheetState extends State<_CihazBilgileriSheet> {
  final _enerjiCtrl = TextEditingController();
  final _hizCtrl = TextEditingController();
  final _msCtrl = TextEditingController();
  final _atisCtrl = TextEditingController();
  final _notCtrl = TextEditingController();

  late String _seansId;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  String _bolgeAdi = '';
  String _seansBilgi = '';
  List<Map<String, dynamic>> _personeller = [];
  String? _seciliPersonelId;

  @override
  void initState() {
    super.initState();
    _seansId = widget.seansId;
    _yukle();
  }

  @override
  void dispose() {
    _enerjiCtrl.dispose();
    _hizCtrl.dispose();
    _msCtrl.dispose();
    _atisCtrl.dispose();
    _notCtrl.dispose();
    super.dispose();
  }

  String _s(dynamic v) => v == null ? '' : v.toString();

  Future<void> _yukle() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await seansCihazVeriGetir(_seansId);
      if (!mounted) return;
      if (_s(res['hatali']) != '0') {
        setState(() {
          _loading = false;
          _error = _s(res['mesaj']).isEmpty
              ? 'Kayıt bulunamadı.'
              : _s(res['mesaj']);
        });
        return;
      }
      final seans = (res['seans'] is Map) ? res['seans'] as Map : {};
      final personeller = (res['personeller'] is List)
          ? (res['personeller'] as List)
              .whereType<Map>()
              .map<Map<String, dynamic>>((e) => {
                    'id': _s(e['id']),
                    'personel_adi': _s(e['personel_adi']),
                  })
              .toList()
          : <Map<String, dynamic>>[];
      final bolgeler = (res['bolgeler'] is List) ? res['bolgeler'] as List : [];
      final Map ilk =
          bolgeler.isNotEmpty && bolgeler.first is Map ? bolgeler.first : {};

      final varsayilan = _s(seans['varsayilan_personel_id']);
      final mevcutPersonel = _s(ilk['personel_id']);

      setState(() {
        _bolgeAdi = _s(seans['hizmet_adi']);
        final musteri = _s(seans['musteri_adi']);
        final seansNo = _s(seans['seans_no']);
        final tarih = _s(seans['seans_tarih']);
        _seansBilgi = [
          if (musteri.isNotEmpty) musteri,
          if (seansNo.isNotEmpty) '$seansNo. Seans',
          if (tarih.isNotEmpty) _formatTarih(tarih),
        ].join('  ·  ');
        _personeller = personeller;
        _enerjiCtrl.text = _s(ilk['enerji']);
        _hizCtrl.text = _s(ilk['hiz']);
        _msCtrl.text = _s(ilk['ms']);
        _atisCtrl.text = _s(ilk['atis_sayisi']);
        _notCtrl.text = _s(ilk['notlar']);
        // Secili personel: mevcut kayit -> varsayilan (randevu personeli)
        final aday = mevcutPersonel.isNotEmpty ? mevcutPersonel : varsayilan;
        _seciliPersonelId =
            personeller.any((p) => p['id'] == aday) ? aday : null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Veri alınamadı.';
      });
    }
  }

  Future<void> _seansDegistir(String? yeniId) async {
    if (yeniId == null || yeniId == _seansId) return;
    setState(() => _seansId = yeniId);
    await _yukle();
  }

  Future<void> _kaydet() async {
    setState(() => _saving = true);
    try {
      final bolge = <String, dynamic>{
        'uygulama_bolgesi': _bolgeAdi,
        'enerji': _enerjiCtrl.text.trim(),
        'hiz': _hizCtrl.text.trim(),
        'ms': _msCtrl.text.trim(),
        'atis_sayisi': _atisCtrl.text.trim(),
        'personel_id': _seciliPersonelId ?? '',
        'notlar': _notCtrl.text.trim(),
      };
      final res = await seansCihazVeriKaydet(_seansId, [bolge]);
      if (!mounted) return;
      final ok = _s(res['hatali']) == '0';
      Navigator.of(context).pop(ok);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_s(res['mesaj']).isEmpty
              ? (ok ? 'Cihaz bilgileri kaydedildi' : 'Kaydedilemedi')
              : _s(res['mesaj'])),
          backgroundColor: ok ? const Color(0xFF16A34A) : Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cihaz bilgileri kaydedilemedi.')),
      );
    }
  }

  String _formatTarih(String raw) {
    final parts = raw.split('-');
    if (parts.length == 3) {
      return '${parts[2].substring(0, parts[2].length >= 2 ? 2 : parts[2].length)}.${parts[1]}.${parts[0]}';
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (ctx, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? _buildError()
                        : ListView(
                            controller: controller,
                            padding: const EdgeInsets.fromLTRB(18, 6, 18, 16),
                            children: _buildForm(),
                          ),
              ),
              _buildBottomActions(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
      decoration: const BoxDecoration(
        color: _indigo,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt_rounded, color: Colors.white, size: 22),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Cihaz / Seans Bilgileri',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          InkWell(
            onTap: () => Navigator.of(context).pop(false),
            borderRadius: BorderRadius.circular(999),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close_rounded, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          _error ?? 'Hata',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }

  List<Widget> _buildForm() {
    return [
      if (_seansBilgi.isNotEmpty) ...[
        const SizedBox(height: 8),
        Text(
          _seansBilgi,
          style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
        ),
      ],
      // Seans secici (birden fazla seans varsa)
      if (widget.seanslar.length > 1) ...[
        const SizedBox(height: 14),
        _label('Seans Seç'),
        const SizedBox(height: 5),
        _seansSecici(),
      ],
      // Bolge adi (otomatik)
      const SizedBox(height: 14),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF2FF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFC7D2FE)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'UYGULAMA BÖLGESİ',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: _indigo,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _bolgeAdi.isEmpty ? '-' : _bolgeAdi,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF312E81),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(child: _numField('Enerji (Jül)', _enerjiCtrl)),
          const SizedBox(width: 10),
          Expanded(child: _numField('Hız', _hizCtrl)),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(child: _numField('MS', _msCtrl)),
          const SizedBox(width: 10),
          Expanded(child: _numField('Atış Sayısı', _atisCtrl)),
        ],
      ),
      const SizedBox(height: 12),
      _label('Uygulamayı Yapan'),
      const SizedBox(height: 5),
      _personelDropdown(),
      const SizedBox(height: 12),
      _label('Not (opsiyonel)'),
      const SizedBox(height: 5),
      TextField(
        controller: _notCtrl,
        decoration: _inputDecoration(),
      ),
      const SizedBox(height: 8),
    ];
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: Color(0xFF64748B),
          letterSpacing: 0.3,
        ),
      );

  InputDecoration _inputDecoration() => InputDecoration(
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
          borderRadius: BorderRadius.circular(9),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: _indigo, width: 1.4),
          borderRadius: BorderRadius.circular(9),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(9)),
      );

  Widget _numField(String label, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 5),
        TextField(
          controller: ctrl,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: _inputDecoration(),
        ),
      ],
    );
  }

  Widget _seansSecici() {
    final ids = widget.seanslar.map((e) => e['id'].toString()).toList();
    final value = ids.contains(_seansId) ? _seansId : null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFCBD5E1)),
        borderRadius: BorderRadius.circular(9),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          items: widget.seanslar.map((s) {
            final id = s['id'].toString();
            final no = s['no']?.toString() ?? '';
            final tarih = (s['tarih'] ?? '').toString();
            final geldi = s['geldi'];
            final durum = geldi == 1 ? '✓' : (geldi == 0 ? '✗' : '•');
            final tStr = tarih.isEmpty ? '' : ' — ${_formatTarih(tarih)}';
            return DropdownMenuItem(
              value: id,
              child: Text('$no. Seans$tStr  $durum',
                  style: const TextStyle(fontSize: 14)),
            );
          }).toList(),
          onChanged: _saving ? null : _seansDegistir,
        ),
      ),
    );
  }

  Widget _personelDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFCBD5E1)),
        borderRadius: BorderRadius.circular(9),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: _seciliPersonelId,
          hint: const Text('— Seçiniz —', style: TextStyle(fontSize: 14)),
          items: _personeller.map((p) {
            return DropdownMenuItem(
              value: p['id'].toString(),
              child: Text(p['personel_adi'].toString(),
                  style: const TextStyle(fontSize: 14)),
            );
          }).toList(),
          onChanged: (v) => setState(() => _seciliPersonelId = v),
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _saving ? null : () => Navigator.of(context).pop(false),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text('İptal',
                        style: TextStyle(
                            color: Color(0xFF334155),
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: (_saving || _loading || _error != null) ? null : _kaydet,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color: (_saving || _loading || _error != null)
                        ? _indigo.withValues(alpha: 0.5)
                        : _indigo,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_rounded,
                                  color: Colors.white, size: 18),
                              SizedBox(width: 6),
                              Text('Kaydet',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14)),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

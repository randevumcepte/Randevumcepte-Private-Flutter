import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:randevu_sistem/Frontend/aramali_dropdown.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/yonetici/diger/sube_secici.dart';

/// Bildirim Reklamı oluştur / düzenle formu (yönetici tarafı).
/// Web panelindeki modal ile birebir aynı alanlar.
class BildirimReklamiForm extends StatefulWidget {
  final dynamic isletmebilgi;
  final Map<String, dynamic>? reklam; // düzenleme için
  const BildirimReklamiForm({Key? key, this.isletmebilgi, this.reklam}) : super(key: key);

  @override
  State<BildirimReklamiForm> createState() => _BildirimReklamiFormState();
}

class _BildirimReklamiFormState extends State<BildirimReklamiForm> {
  Color get _mor => Theme.of(context).colorScheme.primary; // uygulama tema rengi
  String get _salonId => '${widget.isletmebilgi?['id'] ?? ''}';

  final _baslik = TextEditingController();
  final _mesaj = TextEditingController();
  final _kuponDeger = TextEditingController();
  final _kuponGun = TextEditingController();
  final _kuponAdet = TextEditingController();
  final _kuponLimit = TextEditingController(text: '1');
  final _segGun = TextEditingController(text: '60');

  // Çoklu şube: reklam hangi şubelere gönderilecek (yeni reklamda, tek şubede gizli)
  List<String> _seciliReklamSubeler = const [];

  String _tur = 'kampanya';
  String _aksiyon = 'kupon';
  String _kuponTip = 'yuzde';
  // Kupon 'hangi urun/hizmet icin gecerli' toggle: 'hizmet' | 'urun' | 'tumu'
  String _kuponGecerliTip = 'tumu';
  String? _kuponHizmetId;
  String? _kuponUrunId;
  String _hedefKitle = 'tumu';
  String _segTip = 'kisi';
  String _segCinsiyet = '0';
  String? _segHizmetId;
  String? _segUrunId;
  int? _segUserId;
  String _segUserAd = '';
  String _durum = 'taslak';

  bool _kanalPush = true, _kanalInapp = true, _tamEkran = false;
  String? _gorsel; // /public/... yolu
  String? _gorselUrl; // tam url (önizleme)
  String? _rndTarih, _rndTarihBit, _rndSaatBas, _rndSaatBit;

  List<Map<String, dynamic>> _hizmetler = [];
  List<Map<String, dynamic>> _urunler = [];
  List<Map<String, dynamic>> _musteriler = [];
  bool _kaydediliyor = false;
  bool _gorselYukleniyor = false;

  final _turler = const {
    'kampanya': 'Kampanya / İndirim',
    'bos_slot': 'Boş Slot Doldurma',
    'yeni_hizmet': 'Yeni Hizmet Tanıtımı',
    'geri_kazanim': 'Yeniden Kazanım',
    'ozel_gun': 'Özel Gün',
    'sadakat': 'Sadakat / Puan',
    'etkinlik': 'Etkinlik / Duyuru',
  };

  @override
  void initState() {
    super.initState();
    _dropdownlariYukle();
    final r = widget.reklam;
    if (r != null) {
      _baslik.text = r['baslik']?.toString() ?? '';
      _mesaj.text = r['mesaj']?.toString() ?? '';
      _tur = r['tur']?.toString() ?? 'kampanya';
      _kanalPush = r['kanal_push'] == true;
      _kanalInapp = r['kanal_inapp'] == true;
      _tamEkran = r['tam_ekran'] == true;
      _aksiyon = r['aksiyon_tipi']?.toString() ?? 'kupon';
      _gorsel = r['gorsel']?.toString();
      _gorselUrl = r['gorsel_url']?.toString();
      _kuponTip = r['kupon_indirim_tipi']?.toString() ?? 'yuzde';
      if (r['kupon_deger'] != null && (r['kupon_deger'] is num) && r['kupon_deger'] > 0) {
        _kuponDeger.text = '${(r['kupon_deger'] as num) % 1 == 0 ? (r['kupon_deger'] as num).toInt() : r['kupon_deger']}';
      }
      _kuponHizmetId = r['kupon_hizmet_id']?.toString();
      _kuponUrunId = r['kupon_urun_id']?.toString();
      if ((_kuponUrunId ?? '').isNotEmpty && _kuponUrunId != 'null') {
        _kuponGecerliTip = 'urun';
      } else if ((_kuponHizmetId ?? '').isNotEmpty && _kuponHizmetId != 'null') {
        _kuponGecerliTip = 'hizmet';
      } else {
        _kuponGecerliTip = 'tumu';
      }
      if (r['kupon_gecerlilik_gun'] != null) _kuponGun.text = '${r['kupon_gecerlilik_gun']}';
      if (r['kupon_toplam_adet'] != null) _kuponAdet.text = '${r['kupon_toplam_adet']}';
      if (r['kupon_kisi_limit'] != null) _kuponLimit.text = '${r['kupon_kisi_limit']}';
      _rndTarih = r['randevu_tarih']?.toString();
      _rndTarihBit = r['randevu_tarih_bit']?.toString();
      _rndSaatBas = r['randevu_saat_bas']?.toString();
      _rndSaatBit = r['randevu_saat_bit']?.toString();
      _durum = r['durum']?.toString() ?? 'taslak';
      _hedefKitle = r['hedef_kitle']?.toString() ?? 'tumu';
      final kosulRaw = r['hedef_kosul'];
      if (kosulRaw != null && '$kosulRaw'.isNotEmpty) {
        try {
          final k = kosulRaw is String ? jsonDecode(kosulRaw) : kosulRaw;
          if (k is Map && k['tip'] != null) {
            _segTip = k['tip'].toString();
            if (k['gun'] != null) _segGun.text = '${k['gun']}';
            if (k['hizmet_id'] != null) _segHizmetId = k['hizmet_id'].toString();
            if (k['urun_id'] != null) _segUrunId = k['urun_id'].toString();
            if (k['cinsiyet'] != null) _segCinsiyet = k['cinsiyet'].toString();
            if (k['user_id'] != null) _segUserId = int.tryParse('${k['user_id']}');
          }
        } catch (_) {}
      }
    }
  }

  Future<void> _dropdownlariYukle() async {
    try {
      final h = await reklamAdminHizmetler(_salonId);
      final m = await reklamAdminMusteriler(_salonId);
      Map<String, dynamic> u = const {'data': <dynamic>[]};
      try { u = await reklamAdminUrunler(_salonId); } catch (_) {}
      if (!mounted) return;
      setState(() {
        _hizmetler = ((h['data'] as List?) ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _urunler = ((u['data'] as List?) ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _musteriler = ((m['data'] as List?) ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        if (_segUserId != null) {
          final bul = _musteriler.firstWhere((x) => '${x['id']}' == '$_segUserId', orElse: () => {});
          if (bul.isNotEmpty) _segUserAd = '${bul['name']} — ${bul['cep_telefon']}';
        }
      });
    } catch (_) {}
  }

  Future<void> _gorselSec() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (x == null) return;
    setState(() => _gorselYukleniyor = true);
    try {
      final bytes = await File(x.path).readAsBytes();
      final b64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      final res = await reklamAdminGorsel(_salonId, b64);
      if (!mounted) return;
      if (res['success'] == true) {
        setState(() {
          _gorsel = res['yol']?.toString();
          _gorselUrl = res['url']?.toString();
        });
      } else {
        _snack(res['message']?.toString() ?? 'Görsel yüklenemedi');
      }
    } catch (_) {
      _snack('Görsel yüklenemedi');
    } finally {
      if (mounted) setState(() => _gorselYukleniyor = false);
    }
  }

  Future<void> _tarihSec(bool bitis) async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d == null) return;
    final s = DateFormat('yyyy-MM-dd').format(d);
    setState(() => bitis ? _rndTarihBit = s : _rndTarih = s);
  }

  Future<void> _saatSec(bool bitis) async {
    final t = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 10, minute: 0));
    if (t == null) return;
    final s = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    setState(() => bitis ? _rndSaatBit = s : _rndSaatBas = s);
  }

  Future<void> _kisiSec() async {
    final secili = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (ctx) => _KisiSecici(musteriler: _musteriler),
    );
    if (secili != null) {
      setState(() {
        _segUserId = int.tryParse('${secili['id']}');
        _segUserAd = '${secili['name']} — ${secili['cep_telefon']}';
      });
    }
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _kaydet() async {
    if (_baslik.text.trim().isEmpty) {
      _snack('Başlık zorunlu');
      return;
    }
    if (!_kanalPush && !_kanalInapp && !_tamEkran) {
      _snack('En az bir kanal seçili olmalı');
      return;
    }
    setState(() => _kaydediliyor = true);
    final veri = <String, dynamic>{
      if (widget.reklam != null) 'id': widget.reklam!['id'],
      'baslik': _baslik.text.trim(),
      'mesaj': _mesaj.text.trim(),
      'tur': _tur,
      'gorsel': _gorsel ?? '',
      'kanal_push': _kanalPush ? 1 : 0,
      'kanal_inapp': _kanalInapp ? 1 : 0,
      'tam_ekran': _tamEkran ? 1 : 0,
      'aksiyon_tipi': _aksiyon,
      'kupon_indirim_tipi': _kuponTip,
      'kupon_deger': _kuponDeger.text.trim(),
      'kupon_hizmet_id': _kuponHizmetId ?? '',
      'kupon_urun_id': _kuponUrunId ?? '',
      'kupon_gecerli_tip': _kuponGecerliTip,
      'kupon_gecerlilik_gun': _kuponGun.text.trim(),
      'kupon_toplam_adet': _kuponAdet.text.trim(),
      'kupon_kisi_limit': _kuponLimit.text.trim(),
      'randevu_tarih': _rndTarih ?? '',
      'randevu_tarih_bit': _rndTarihBit ?? '',
      'randevu_saat_bas': _rndSaatBas ?? '',
      'randevu_saat_bit': _rndSaatBit ?? '',
      'hedef_kitle': _hedefKitle,
      'segment_tip': _segTip,
      'segment_gun': _segGun.text.trim(),
      'segment_hizmet_id': _segHizmetId ?? '',
      'segment_urun_id': _segUrunId ?? '',
      'segment_cinsiyet': _segCinsiyet,
      'segment_user_id': _segUserId ?? '',
      'durum': _durum,
      if (widget.reklam == null && _seciliReklamSubeler.isNotEmpty)
        'salon_ids': _seciliReklamSubeler,
    };
    try {
      final res = await reklamAdminKaydet(_salonId, veri);
      if (!mounted) return;
      if (res['success'] == true) {
        Navigator.pop(context, true);
      } else {
        setState(() => _kaydediliyor = false);
        _snack(res['message']?.toString() ?? 'Kaydedilemedi');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _kaydediliyor = false);
        _snack('Kaydedilemedi');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final kuponVar = _aksiyon == 'kupon' || _aksiyon == 'randevu';
    final randevuVar = _aksiyon == 'randevu';
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6FB),
      appBar: AppBar(
        backgroundColor: _mor,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        title: Text(widget.reklam == null ? 'Yeni Reklam' : 'Reklamı Düzenle', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
        children: [
          _bolum('İçerik'),
          _lbl('Reklam Türü'),
          _drop(_tur, _turler, (v) => setState(() => _tur = v)),
          const SizedBox(height: 12),
          _lbl('Başlık *'),
          _tf(_baslik, 'Örn: Bu haftaya özel %20 indirim!'),
          const SizedBox(height: 12),
          _lbl('Mesaj'),
          _tf(_mesaj, 'Kısa açıklama (bildirim gövdesi)', satir: 3),
          const SizedBox(height: 12),
          _lbl('Görsel'),
          _gorselAlan(),

          _bolum('Kanallar'),
          _switch('Push (anlık bildirim)', Icons.notifications, _kanalPush, (v) => setState(() => _kanalPush = v)),
          _switch('Uygulama içi kart', Icons.smartphone, _kanalInapp, (v) => setState(() => _kanalInapp = v)),
          _switch('Açılışta tam ekran (popup)', Icons.fullscreen, _tamEkran, (v) => setState(() => _tamEkran = v)),

          _bolum('Görsele dokununca'),
          _drop(_aksiyon, const {
            'kupon': '🎟️ İndirim kuponu tanımlansın',
            'randevu': '📅 Boş slot: indirimli saatte randevu',
            'yok': 'ℹ️ Sadece görsel',
          }, (v) => setState(() => _aksiyon = v)),

          if (kuponVar) ...[
            const SizedBox(height: 12),
            _kutu(const Color(0xFFFAF5FF), const Color(0xFFEDE9FE), 'Kupon Ayarları', _mor, [
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_lbl('İndirim Tipi'), _drop(_kuponTip, const {'yuzde': 'Yüzde (%)', 'tutar': 'Tutar (₺)'}, (v) => setState(() => _kuponTip = v))])),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_lbl('Değer'), _tf(_kuponDeger, '20', sayi: true)])),
              ]),
              const SizedBox(height: 10),
              _lbl('Kupon Ne İçin?'),
              _drop(_kuponGecerliTip, const {
                'hizmet': 'Belirli hizmet',
                'urun': 'Belirli ürün',
                'tumu': 'Kısıtlama yok (tümü)',
              }, (v) => setState(() {
                _kuponGecerliTip = v;
                if (v == 'urun') _kuponHizmetId = null;
                if (v == 'hizmet') _kuponUrunId = null;
              })),
              const SizedBox(height: 10),
              if (_kuponGecerliTip == 'hizmet') ...[
                _lbl('Geçerli Hizmet'),
                _hizmetDrop(_kuponHizmetId, true, (v) => setState(() => _kuponHizmetId = v)),
              ] else if (_kuponGecerliTip == 'urun') ...[
                _lbl('Geçerli Ürün'),
                _urunDrop(_kuponUrunId, true, (v) => setState(() => _kuponUrunId = v)),
              ],
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_lbl('Geçerlilik (gün)'), _tf(_kuponGun, 'süresiz', sayi: true)])),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_lbl('Toplam Adet'), _tf(_kuponAdet, 'sınırsız', sayi: true)])),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_lbl('Kişi Limiti'), _tf(_kuponLimit, '1', sayi: true)])),
              ]),
              if (randevuVar) const Padding(padding: EdgeInsets.only(top: 10), child: Text('Boş slot reklamında kupon opsiyoneldir. Değer girmezsen sadece randevuya yönlendirir.', style: TextStyle(fontSize: 11.5, color: Color(0xFF0284C7)))),
            ]),
          ],

          if (randevuVar) ...[
            const SizedBox(height: 12),
            _kutu(const Color(0xFFF0F9FF), const Color(0xFFBAE6FD), 'Randevu Tarih & Saat Aralığı', const Color(0xFF0284C7), [
              Row(children: [
                Expanded(child: _pickAlan('Başlangıç Tarihi', _rndTarih, Icons.event, () => _tarihSec(false))),
                const SizedBox(width: 10),
                Expanded(child: _pickAlan('Bitiş Tarihi', _rndTarihBit, Icons.event, () => _tarihSec(true))),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _pickAlan('Başlangıç Saati', _rndSaatBas, Icons.schedule, () => _saatSec(false))),
                const SizedBox(width: 10),
                Expanded(child: _pickAlan('Bitiş Saati', _rndSaatBit, Icons.schedule, () => _saatSec(true))),
              ]),
              const Padding(padding: EdgeInsets.only(top: 10), child: Text('Müşteri dokununca randevu ekranı bu tarih ve saat aralığına kısıtlı açılır.', style: TextStyle(fontSize: 11.5, color: Color(0xFF0284C7)))),
            ]),
          ],

          _bolum('Kimlere gitsin?'),
          _drop(_hedefKitle, const {'tumu': 'Tüm müşteriler', 'segment': 'Belirli segment'}, (v) => setState(() => _hedefKitle = v)),
          if (_hedefKitle == 'segment') ...[
            const SizedBox(height: 12),
            _kutu(const Color(0xFFF8FAFC), const Color(0xFFE2E8F0), 'Segment', const Color(0xFF334155), [
              _drop(_segTip, const {
                'kisi': '👤 Belirli kişi',
                'gelmeyen': 'Uzun süredir gelmeyenler',
                'dogum_gunu': 'Doğum günü bu ay',
                'hizmet': 'Belirli hizmeti alanlar',
                'urun': 'Belirli ürünü alanlar',
                'cinsiyet': 'Cinsiyete göre',
              }, (v) => setState(() => _segTip = v)),
              const SizedBox(height: 10),
              if (_segTip == 'kisi')
                InkWell(
                  onTap: _kisiSec,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(11), border: Border.all(color: const Color(0xFFE5E7EB))),
                    child: Row(children: [
                      Icon(Icons.search, size: 18, color: _mor),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_segUserAd.isEmpty ? 'Kişi seç (isim/telefon ara)' : _segUserAd, style: TextStyle(color: _segUserAd.isEmpty ? const Color(0xFF94A3B8) : const Color(0xFF1E293B)))),
                    ]),
                  ),
                ),
              if (_segTip == 'gelmeyen') ...[_lbl('Kaç gündür gelmeyenler?'), _tf(_segGun, '60', sayi: true)],
              if (_segTip == 'hizmet') ...[_lbl('Hangi hizmeti alanlar?'), _hizmetDrop(_segHizmetId, false, (v) => setState(() => _segHizmetId = v))],
              if (_segTip == 'urun') ...[_lbl('Hangi ürünü alanlar?'), _urunDrop(_segUrunId, false, (v) => setState(() => _segUrunId = v))],
              if (_segTip == 'cinsiyet') ...[_lbl('Cinsiyet'), _drop(_segCinsiyet, const {'0': 'Kadın', '1': 'Erkek'}, (v) => setState(() => _segCinsiyet = v))],
            ]),
          ],

          _bolum('Yayın durumu'),
          _drop(_durum, const {'taslak': 'Taslak (yayında değil)', 'aktif': 'Aktif (yayında)', 'pasif': 'Pasif'}, (v) => setState(() => _durum = v)),

          // Çoklu şube: yeni reklam hangi şubelere gönderilsin (tek şubede gizli)
          if (widget.reklam == null)
            SubeCokluSecici(
              aktifSalonId: _salonId,
              baslik: 'Hangi şubelere gönderilsin?',
              onChanged: (ids) => _seciliReklamSubeler = ids,
            ),

          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: _mor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13))),
              onPressed: _kaydediliyor ? null : _kaydet,
              icon: _kaydediliyor ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.check, color: Colors.white),
              label: const Text('Kaydet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  // ---- küçük widget yardımcıları ----
  Widget _bolum(String t) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 10),
        child: Text(t, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
      );

  Widget _lbl(String t) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(t, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF475569))));

  Widget _tf(TextEditingController c, String hint, {int satir = 1, bool sayi = false}) => TextField(
        controller: c,
        maxLines: satir,
        keyboardType: sayi ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          hintText: hint,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: BorderSide(color: _mor, width: 1.5)),
        ),
      );

  Widget _drop(String deger, Map<String, String> secenekler, ValueChanged<String> onDegis) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 13),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(11), border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5)),
        child: DropdownButtonHideUnderline(
          child: AramaliDropdown<String>(
            value: secenekler.containsKey(deger) ? deger : secenekler.keys.first,
            isExpanded: true,
            items: secenekler.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis))).toList(),
            onChanged: (v) { if (v != null) onDegis(v); },
          ),
        ),
      );

  Widget _hizmetDrop(String? deger, bool tumuSecenegi, ValueChanged<String?> onDegis) {
    final items = <DropdownMenuItem<String?>>[
      if (tumuSecenegi) const DropdownMenuItem(value: null, child: Text('Tüm hizmetler')),
      ..._hizmetler.map((h) => DropdownMenuItem<String?>(value: '${h['id']}', child: Text('${h['ad']}', overflow: TextOverflow.ellipsis))),
    ];
    final gecerli = items.any((it) => it.value == deger) ? deger : (tumuSecenegi ? null : (_hizmetler.isNotEmpty ? '${_hizmetler.first['id']}' : null));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(11), border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5)),
      child: DropdownButtonHideUnderline(
        child: AramaliDropdown<String?>(value: gecerli, isExpanded: true, items: items, onChanged: onDegis),
      ),
    );
  }

  /// Urun dropdown (kupon 'gecerli urun' + segment 'urun' icin).
  /// _hizmetDrop ile ayni desen; urun listesi bos ise "urun tanimli degil" mesaji.
  Widget _urunDrop(String? deger, bool tumuSecenegi, ValueChanged<String?> onDegis) {
    if (_urunler.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
        decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(11), border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5)),
        child: const Text('Bu şubede tanımlı ürün yok.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5)),
      );
    }
    final items = <DropdownMenuItem<String?>>[
      if (tumuSecenegi) const DropdownMenuItem(value: null, child: Text('Tüm ürünler')),
      ..._urunler.map((u) => DropdownMenuItem<String?>(value: '${u['id']}', child: Text('${u['ad']}', overflow: TextOverflow.ellipsis))),
    ];
    final gecerli = items.any((it) => it.value == deger) ? deger : (tumuSecenegi ? null : '${_urunler.first['id']}');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(11), border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5)),
      child: DropdownButtonHideUnderline(
        child: AramaliDropdown<String?>(value: gecerli, isExpanded: true, items: items, onChanged: onDegis),
      ),
    );
  }

  Widget _switch(String t, IconData ic, bool deger, ValueChanged<bool> onDegis) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(11), border: Border.all(color: deger ? _mor : const Color(0xFFE5E7EB), width: 1.5)),
        child: SwitchListTile(
          value: deger,
          activeThumbColor: Colors.white,
          activeTrackColor: _mor,
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: const Color(0xFFCBD5E1),
          onChanged: onDegis,
          secondary: Icon(ic, color: deger ? _mor : const Color(0xFF94A3B8), size: 22),
          title: Text(t, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
          dense: true,
        ),
      );

  Widget _kutu(Color bg, Color border, String baslik, Color renk, List<Widget> cocuklar) => Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: border, width: 1.5)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(baslik, style: TextStyle(fontWeight: FontWeight.w800, color: renk, fontSize: 13.5)),
          const SizedBox(height: 12),
          ...cocuklar,
        ]),
      );

  Widget _gorselAlan() => Column(children: [
        InkWell(
          onTap: _gorselYukleniyor ? null : _gorselSec,
          child: Container(
            height: 150,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFCBD5E1), width: 2, style: BorderStyle.solid)),
            clipBehavior: Clip.antiAlias,
            child: _gorselYukleniyor
                ? Center(child: CircularProgressIndicator(color: _mor))
                : (_gorselUrl != null && _gorselUrl!.isNotEmpty
                    ? Image.network(_gorselUrl!, fit: BoxFit.cover, width: double.infinity, errorBuilder: (c, e, s) => const Center(child: Icon(Icons.broken_image, color: Color(0xFF94A3B8))))
                    : const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.cloud_upload_outlined, size: 32, color: Color(0xFF94A3B8)), SizedBox(height: 6), Text('Görsel yükle', style: TextStyle(color: Color(0xFF94A3B8)))]))),
          ),
        ),
        const Padding(padding: EdgeInsets.only(top: 6), child: Align(alignment: Alignment.centerLeft, child: Text('Açılış popup için dikey 9:16 (Instagram Story) görseli önerilir.', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))))),
      ]);

  Widget _pickAlan(String etiket, String? deger, IconData ic, VoidCallback onTap) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _lbl(etiket),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(11), border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5)),
            child: Row(children: [
              Icon(ic, size: 17, color: const Color(0xFF0284C7)),
              const SizedBox(width: 7),
              Text(deger ?? 'Seç', style: TextStyle(color: deger == null ? const Color(0xFF94A3B8) : const Color(0xFF1E293B), fontSize: 13)),
            ]),
          ),
        ),
      ]);
}

/// Kişi seçmek için aranabilir bottom sheet.
class _KisiSecici extends StatefulWidget {
  final List<Map<String, dynamic>> musteriler;
  const _KisiSecici({required this.musteriler});
  @override
  State<_KisiSecici> createState() => _KisiSeciciState();
}

class _KisiSeciciState extends State<_KisiSecici> {
  String _q = '';
  @override
  Widget build(BuildContext context) {
    final filtre = widget.musteriler.where((m) {
      if (_q.isEmpty) return true;
      final t = '${m['name']} ${m['cep_telefon']}'.toLowerCase();
      return t.contains(_q.toLowerCase());
    }).toList();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(children: [
          const SizedBox(height: 10),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.all(14),
            child: TextField(
              autofocus: true,
              onChanged: (v) => setState(() => _q = v),
              decoration: InputDecoration(
                hintText: 'İsim veya telefon ara…',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          Expanded(
            child: filtre.isEmpty
                ? const Center(child: Text('Kişi bulunamadı', style: TextStyle(color: Color(0xFF94A3B8))))
                : ListView.separated(
                    itemCount: filtre.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) => ListTile(
                      title: Text('${filtre[i]['name']}'),
                      subtitle: Text('${filtre[i]['cep_telefon']}'),
                      onTap: () => Navigator.pop(context, filtre[i]),
                    ),
                  ),
          ),
        ]),
      ),
    );
  }
}

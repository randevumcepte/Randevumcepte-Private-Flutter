// Asistanım > Asistan Görüşmeleri
// AI telefon asistanının (santral) yaptığı görüşmeler: liste, yazılı döküm, ses kaydı,
// "geri aranacak" müşteriler (yetkili açmadı / mesai dışı) + "Aradım" işaretleme.
// Backend: /api/v1/santral-asistan/* (Bearer). Web paneldeki Santral > Asistan Görüşmeleri ile aynı veri.
// "Geri aranacak müşteri" push'una tıklanınca bu sekme "Geri aranacak" filtresiyle açılır.

import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:randevu_sistem/dil/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:randevu_sistem/theme/premium_components.dart';
import 'package:randevu_sistem/yonetici/cagrimerkezi/cagri_api.dart';
import 'package:randevu_sistem/yonetici/cagrimerkezi/widgets/musteri_ara_buton.dart';

class AsistanGorusmeApi {
  static const String _host = 'https://app.randevumcepte.com.tr';
  static const String _base = '$_host/api/v1/santral-asistan';

  static Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('token');
    if (raw == null || raw.isEmpty) {
      final userRaw = prefs.getString('user');
      if (userRaw != null) {
        try {
          final user = jsonDecode(userRaw);
          if (user is Map && user['token'] != null) return user['token'].toString();
        } catch (_) {}
      }
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      return decoded is String ? decoded : decoded?.toString();
    } catch (_) {
      return raw;
    }
  }

  static Future<Map<String, String>> _headers() async {
    final token = await _token();
    return {
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static String _hata(http.Response r) {
    if (r.statusCode == 403) return 'Asistan görüşmelerini yalnızca işletme yöneticileri görebilir.';
    try {
      final j = jsonDecode(r.body);
      if (j is Map && j['hata'] != null) return j['hata'].toString();
    } catch (_) {}
    return 'Bağlantı hatası (${r.statusCode}).';
  }

  static Future<Map<String, dynamic>> liste(String sube, {required bool geriAra, required int gun}) async {
    final bit = DateTime.now();
    final bas = bit.subtract(Duration(days: gun - 1));
    String f(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final uri = Uri.parse('$_base/gorusmeler').replace(queryParameters: {
      'sube': sube,
      'baslangic': f(bas),
      'bitis': f(bit),
      if (geriAra) 'geri_ara': '1',
    });
    final r = await http.get(uri, headers: await _headers()).timeout(const Duration(seconds: 30));
    if (r.statusCode != 200) throw Exception(_hata(r));
    return Map<String, dynamic>.from(jsonDecode(r.body));
  }

  static Future<Map<String, dynamic>> detay(String sube, int id) async {
    final uri = Uri.parse('$_base/gorusme/$id').replace(queryParameters: {'sube': sube});
    final r = await http.get(uri, headers: await _headers()).timeout(const Duration(seconds: 30));
    if (r.statusCode != 200) throw Exception(_hata(r));
    final j = jsonDecode(r.body);
    return Map<String, dynamic>.from(j['kayit'] ?? {});
  }

  static Future<String?> geriArandi(String sube, int id) async {
    final uri = Uri.parse('$_base/geri-arandi/$id').replace(queryParameters: {'sube': sube});
    final r = await http.post(uri, headers: await _headers()).timeout(const Duration(seconds: 30));
    if (r.statusCode != 200) return _hata(r);
    final j = jsonDecode(r.body);
    return (j['ok'] == 1 || j['ok'] == true) ? null : (j['hata']?.toString() ?? 'İşaretlenemedi.');
  }

  /// Ses kaydını (Bearer gerektirir) geçici dosyaya indirir; oynatıcı dosyadan çalar.
  static Future<String> sesIndir(String apiUrl, int id) async {
    final r = await http
        .get(Uri.parse('$_host$apiUrl'), headers: await _headers())
        .timeout(const Duration(seconds: 60));
    if (r.statusCode != 200) throw Exception('Ses kaydı alınamadı (${r.statusCode}).');
    final dir = await getTemporaryDirectory();
    final f = File('${dir.path}/asistan_ses_$id.wav');
    await f.writeAsBytes(r.bodyBytes, flush: true);
    return f.path;
  }
}

class AsistanGorusmeleri extends StatefulWidget {
  final dynamic isletmebilgi;
  /// Push'tan gelindiyse bildirimin salonu (yetkilinin birden fazla salonu olabilir).
  final String? salonId;
  final bool baslangictaGeriAra;
  /// Push'taki görüşme: liste yüklenince detayı otomatik açılır.
  final int? acilacakOturumId;

  const AsistanGorusmeleri({
    super.key,
    required this.isletmebilgi,
    this.salonId,
    this.baslangictaGeriAra = false,
    this.acilacakOturumId,
  });

  @override
  State<AsistanGorusmeleri> createState() => _AsistanGorusmeleriState();
}

class _AsistanGorusmeleriState extends State<AsistanGorusmeleri>
    with AutomaticKeepAliveClientMixin {
  late bool _geriAra = widget.baslangictaGeriAra;
  int _gun = 7;
  bool _yukleniyor = true;
  String? _hata;
  List<Map<String, dynamic>> _liste = [];
  int _bekleyen = 0;
  bool _otomatikAcildi = false;
  String _aranan = '';

  /// Arama kutusu: musteri adi, telefon (rakamlar) ve konusma ozetinde arar.
  List<Map<String, dynamic>> get _gorunen {
    final q = _aranan.trim().toLowerCase();
    if (q.isEmpty) return _liste;
    final qRakam = q.replaceAll(RegExp(r'\D'), '');
    return _liste.where((o) {
      final ad = (o['musteri'] ?? '').toString().toLowerCase();
      final tel = (o['telefon'] ?? '').toString().replaceAll(RegExp(r'\D'), '');
      final metin = '${o['son_musteri'] ?? ''} ${o['sonuc'] ?? ''}'.toLowerCase();
      return ad.contains(q) ||
          metin.contains(q) ||
          (qRakam.length >= 3 && tel.contains(qRakam));
    }).toList();
  }

  String get _sube =>
      (widget.salonId != null && widget.salonId!.isNotEmpty)
          ? widget.salonId!
          : widget.isletmebilgi['id'].toString();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    setState(() {
      _yukleniyor = true;
      _hata = null;
    });
    try {
      final j = await AsistanGorusmeApi.liste(_sube, geriAra: _geriAra, gun: _gun);
      if (!mounted) return;
      setState(() {
        _liste = List<Map<String, dynamic>>.from(
            (j['liste'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)));
        _bekleyen = int.tryParse('${j['bekleyen_geri_ara'] ?? 0}') ?? 0;
        _yukleniyor = false;
      });
      if (!_otomatikAcildi && widget.acilacakOturumId != null) {
        _otomatikAcildi = true;
        _detayAc(widget.acilacakOturumId!);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hata = e.toString().replaceFirst('Exception: ', '');
        _yukleniyor = false;
      });
    }
  }

  Future<void> _detayAc(int id) async {
    final degisti = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GorusmeDetay(sube: _sube, id: id),
    );
    if (degisti == true) _yukle();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final scheme = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: _yukle,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _filtreler(scheme),
          const SizedBox(height: 10),
          TextField(
            onChanged: (v) => setState(() => _aranan = v),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Müşteri adı, telefon ya da konuşmada ara',
              prefixIcon: const Icon(Icons.search_rounded),
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: scheme.primary.withValues(alpha: 0.15)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: scheme.primary.withValues(alpha: 0.15)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (_bekleyen > 0 && !_geriAra) _bekleyenBandi(scheme),
          if (_yukleniyor)
            const Padding(
              padding: EdgeInsets.only(top: 60),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_hata != null)
            _bosDurum(Icons.error_outline_rounded, _hata!, scheme)
          else if (_liste.isEmpty)
            _bosDurum(
              _geriAra ? Icons.check_circle_outline_rounded : Icons.support_agent_rounded,
              _geriAra
                  ? 'Geri aranmayı bekleyen müşteri yok.'
                  : 'Bu tarih aralığında asistan görüşmesi yok.',
              scheme,
            )
          else if (_gorunen.isEmpty)
            _bosDurum(Icons.search_off_rounded, 'Aramanızla eşleşen görüşme yok.', scheme)
          else
            ..._gorunen.map((o) => _satir(o, scheme)),
        ],
      ),
    );
  }

  Widget _filtreler(ColorScheme scheme) {
    Widget chip(String label, bool secili, VoidCallback onTap, {int? rozet}) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(rozet != null && rozet > 0 ? '$label ($rozet)' : label),
            selected: secili,
            onSelected: (_) => onTap(),
            selectedColor: scheme.primary.withValues(alpha: 0.16),
            labelStyle: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: secili ? scheme.primary : scheme.onSurface.withValues(alpha: 0.75),
            ),
            backgroundColor: Colors.white,
            side: BorderSide(color: scheme.primary.withValues(alpha: secili ? 0.4 : 0.12)),
          ),
        );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        chip('Geri aranacak', _geriAra, () {
          setState(() => _geriAra = true);
          _yukle();
        }, rozet: _bekleyen),
        chip('Son 7 gün', !_geriAra && _gun == 7, () {
          setState(() {
            _geriAra = false;
            _gun = 7;
          });
          _yukle();
        }),
        chip('Son 30 gün', !_geriAra && _gun == 30, () {
          setState(() {
            _geriAra = false;
            _gun = 30;
          });
          _yukle();
        }),
      ]),
    );
  }

  Widget _bekleyenBandi(ColorScheme scheme) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: PremiumGlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          shadowTint: Colors.orange,
          onTap: () {
            setState(() => _geriAra = true);
            _yukle();
          },
          child: Row(children: [
            const Icon(Icons.phone_callback_rounded, color: Colors.orange),
            const SizedBox(width: 10),
            Expanded(
              child: Text('$_bekleyen müşteri geri aranmayı bekliyor',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
            const Icon(Icons.chevron_right_rounded),
          ]),
        ),
      );

  Widget _bosDurum(IconData ikon, String metin, ColorScheme scheme) => Padding(
        padding: const EdgeInsets.only(top: 60, left: 24, right: 24),
        child: Column(children: [
          Icon(ikon, size: 44, color: scheme.onSurface.withValues(alpha: 0.35)),
          const SizedBox(height: 10),
          Text(metin,
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.65))),
        ]),
      );

  Widget _satir(Map<String, dynamic> o, ColorScheme scheme) {
    final geriAra = '${o['geri_ara']}' == '1';
    final musteri = (o['musteri'] ?? '').toString();
    final tel = (o['telefon'] ?? '').toString();
    final renk = _rozetRengi((o['renk'] ?? '').toString());
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: PremiumGlassCard(
        padding: const EdgeInsets.all(14),
        shadowTint: geriAra ? Colors.orange : null,
        onTap: () => _detayAc(int.parse('${o['id']}')),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(musteri.isNotEmpty ? musteri : tel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
            Text((o['tarih'] ?? '').toString(),
                style: TextStyle(fontSize: 12, color: scheme.onSurface.withValues(alpha: 0.55))),
          ]),
          if (musteri.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(tel,
                  style: TextStyle(fontSize: 12.5, color: scheme.onSurface.withValues(alpha: 0.6))),
            ),
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
            _rozet((o['sonuc'] ?? '').toString(), renk),
            _rozet((o['tip'] ?? '').toString(), scheme.onSurface.withValues(alpha: 0.55)),
            if ((o['sure'] ?? '').toString().isNotEmpty)
              _rozet('⏱ ${o['sure']}', scheme.onSurface.withValues(alpha: 0.55)),
            if ('${o['ses'] ?? 0}' != '0') _rozet('🎧 Ses kaydı', scheme.primary),
          ]),
          if ((o['son_musteri'] ?? '').toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('“${o['son_musteri']}”',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 12.5,
                      fontStyle: FontStyle.italic,
                      color: scheme.onSurface.withValues(alpha: 0.7))),
            ),
        ]),
      ),
    );
  }
}

Color _rozetRengi(String renk) {
  switch (renk) {
    case 'randevu':
      return Colors.green.shade700;
    case 'teyit':
      return Colors.teal.shade700;
    case 'iptal':
      return Colors.red.shade700;
    case 'aktar':
      return Colors.indigo.shade600;
    case 'guncelle':
      return Colors.blue.shade700;
    case 'geriara':
      return Colors.orange.shade800;
    default:
      return Colors.grey.shade700;
  }
}

Widget _rozet(String metin, Color renk) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: renk.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(metin, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: renk)),
    );

// ---------------------------------------------------------------- detay
class _GorusmeDetay extends StatefulWidget {
  final String sube;
  final int id;
  const _GorusmeDetay({required this.sube, required this.id});

  @override
  State<_GorusmeDetay> createState() => _GorusmeDetayState();
}

class _GorusmeDetayState extends State<_GorusmeDetay> {
  Map<String, dynamic>? _k;
  String? _hata;
  bool _isaretleniyor = false;
  final AudioPlayer _oynatici = AudioPlayer();
  int? _calanSes;
  int? _yuklenenSes;

  @override
  void initState() {
    super.initState();
    _oynatici.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _calanSes = null);
    });
    AsistanGorusmeApi.detay(widget.sube, widget.id).then((k) {
      if (mounted) setState(() => _k = k);
    }).catchError((e) {
      if (mounted) setState(() => _hata = e.toString().replaceFirst('Exception: ', ''));
    });
  }

  @override
  void dispose() {
    _oynatici.dispose();
    super.dispose();
  }

  String? get _aranabilirTel {
    final t = (_k?['telefon'] ?? '').toString().replaceAll(RegExp(r'\D'), '');
    return t.length >= 10 ? t : null;
  }

  /// Uygulama geneli arama mantigi (CagriApi.AramaModu): mobil softphone
  /// dahilisi varsa uygulama icinden, dahili_no varsa Bria (santral), hicbiri
  /// yoksa cihazin telefon uygulamasi. Bu ekran zaten yalniz yoneticiye acik ve
  /// numara ekranda gorundugu icin telefon modunda dogrudan cevrilir.
  Future<void> _ara() async {
    final t = _aranabilirTel;
    if (t == null) return;
    if (CagriApi.aramaModu == AramaModu.telefon) {
      await launchUrl(Uri(scheme: 'tel', path: t), mode: LaunchMode.externalApplication);
      return;
    }
    final musteri = (_k?['musteri'] ?? '').toString();
    await MusteriAraButon.ara(context,
        telefon: t, sube: widget.sube, gorunenAd: musteri.isNotEmpty ? musteri : null);
  }

  Future<void> _aradim() async {
    setState(() => _isaretleniyor = true);
    final hata = await AsistanGorusmeApi.geriArandi(widget.sube, widget.id);
    if (!mounted) return;
    setState(() => _isaretleniyor = false);
    if (hata != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(hata)));
      return;
    }
    Navigator.of(context).pop(true);
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geri arandı olarak işaretlendi.')));
  }

  Future<void> _sesCal(Map<String, dynamic> s) async {
    final id = int.parse('${s['id']}');
    if (_calanSes == id) {
      await _oynatici.stop();
      setState(() => _calanSes = null);
      return;
    }
    final apiUrl = (s['api_url'] ?? '').toString();
    if (apiUrl.isEmpty) return;
    setState(() => _yuklenenSes = id);
    try {
      final yol = await AsistanGorusmeApi.sesIndir(apiUrl, id);
      await _oynatici.stop();
      await _oynatici.play(DeviceFileSource(yol));
      if (mounted) setState(() => _calanSes = id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
      }
    } finally {
      if (mounted) setState(() => _yuklenenSes = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // expand: false -> sayfa yalniz kendi boyu kadar yer kaplar; ustteki karartiya dokununca kapanir
    // (varsayilan expand: true tum ekrani kapliyor, bosluga dokunus engele ulasmiyordu).
    return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.88,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scroll) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF7F7FA),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: _k == null
              ? Center(
                  child: _hata != null
                      ? Padding(padding: const EdgeInsets.all(24), child: Text(_hata!))
                      : const CircularProgressIndicator())
              : ListView(
                  controller: scroll,
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                            color: Colors.black26, borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _baslik(scheme),
                    if ('${_k!['geri_ara']}' == '1') ...[
                      const SizedBox(height: 12),
                      _geriAraKarti(scheme),
                    ] else if ((_k!['geri_arandi'] ?? '').toString().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _rozet('✓ Geri arandı: ${_k!['geri_arandi']}', Colors.teal.shade700),
                    ],
                    if ((_k!['sesler'] as List? ?? []).isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text('Ses kaydı', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      ...(_k!['sesler'] as List).map((s) => _sesSatiri(Map<String, dynamic>.from(s), scheme)),
                    ],
                    const SizedBox(height: 16),
                    const Text('Konuşma', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    ...(_k!['konusma'] as List? ?? [])
                        .map((m) => _balon(Map<String, dynamic>.from(m), scheme)),
                  ],
                ),
        ),
    );
  }

  Widget _baslik(ColorScheme scheme) {
    final musteri = (_k!['musteri'] ?? '').toString();
    final tel = (_k!['telefon'] ?? '').toString();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(musteri.isNotEmpty ? musteri : tel,
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
            if (musteri.isNotEmpty)
              Text(tel, style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.6))),
          ]),
        ),
        if (_aranabilirTel != null)
          IconButton.filled(
            onPressed: _ara,
            icon: const Icon(Icons.call_rounded),
            tooltip: 'Ara',
          ),
      ]),
      const SizedBox(height: 8),
      Wrap(spacing: 6, runSpacing: 6, children: [
        _rozet((_k!['sonuc'] ?? '').toString(), _rozetRengi((_k!['renk'] ?? '').toString())),
        _rozet((_k!['tip'] ?? '').toString(), Colors.grey.shade700),
        _rozet((_k!['tarih'] ?? '').toString(), Colors.grey.shade700),
        if ((_k!['sure'] ?? '').toString().isNotEmpty) _rozet('⏱ ${_k!['sure']}', Colors.grey.shade700),
        if ((_k!['randevu'] ?? '').toString().isNotEmpty)
          _rozet('📅 Randevu: ${_k!['randevu']}', Colors.green.shade700),
      ]),
    ]);
  }

  Widget _geriAraKarti(ColorScheme scheme) {
    final neden = (_k!['geri_ara_neden'] ?? '').toString();
    final not = (_k!['geri_ara_not'] ?? '').toString();
    return PremiumGlassCard(
      padding: const EdgeInsets.all(14),
      shadowTint: Colors.orange,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.phone_callback_rounded, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Geri aranacak${neden.isNotEmpty ? ' · $neden' : ''}',
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ]),
        if (not.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('Müşterinin notu: $not'),
        ],
        const SizedBox(height: 12),
        Row(children: [
          if (_aranabilirTel != null)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _ara,
                icon: const Icon(Icons.call_rounded, size: 18),
                label: const Text('Ara'),
              ),
            ),
          if (_aranabilirTel != null) const SizedBox(width: 10),
          Expanded(
            child: FilledButton.icon(
              onPressed: _isaretleniyor ? null : _aradim,
              icon: _isaretleniyor
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.check_rounded, size: 18),
              label: const Text('Aradım, tamamlandı'),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _sesSatiri(Map<String, dynamic> s, ColorScheme scheme) {
    final id = int.parse('${s['id']}');
    final caliyor = _calanSes == id;
    final yukleniyor = _yuklenenSes == id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: PremiumGlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        onTap: yukleniyor ? null : () => _sesCal(s),
        child: Row(children: [
          yukleniyor
              ? const SizedBox(width: 28, height: 28, child: Padding(
                  padding: EdgeInsets.all(4), child: CircularProgressIndicator(strokeWidth: 2)))
              : Icon(caliyor ? Icons.stop_circle_rounded : Icons.play_circle_fill_rounded,
                  size: 28, color: scheme.primary),
          const SizedBox(width: 10),
          Expanded(child: Text((s['tur'] ?? 'Ses kaydı').toString())),
        ]),
      ),
    );
  }

  Widget _balon(Map<String, dynamic> m, ColorScheme scheme) {
    final musteri = m['rol'] == 'musteri';
    return Align(
      alignment: musteri ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: musteri ? Colors.white : scheme.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(musteri ? 'Müşteri' : 'Asistan',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: musteri ? Colors.grey.shade700 : scheme.primary)),
          const SizedBox(height: 2),
          Text((m['metin'] ?? '').toString(), style: const TextStyle(fontSize: 14)),
        ]),
      ),
    );
  }
}

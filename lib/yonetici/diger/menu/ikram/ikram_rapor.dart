import 'package:randevu_sistem/dil/material.dart';
import 'package:randevu_sistem/Backend/backend.dart';
import 'ikram_hizmet.dart' show ikramTl, ikramTarih;

/// İkram Hizmet > Detaylı Rapor: dönem özeti, kampanya bazında kazanç ve
/// ikram kazanan müşteriler (hak / kullanım / son kullanma).
class IkramRaporSayfasi extends StatefulWidget {
  final String salonId;
  final int ilkDonem;
  final List<Map<String, dynamic>> kurallar;
  final List<Map<String, dynamic>> musteriler;

  const IkramRaporSayfasi({
    super.key,
    required this.salonId,
    required this.ilkDonem,
    required this.kurallar,
    required this.musteriler,
  });

  @override
  State<IkramRaporSayfasi> createState() => _IkramRaporSayfasiState();
}

class _IkramRaporSayfasiState extends State<IkramRaporSayfasi> {
  static const _koyu = Color(0xFF2E1065);
  static const _mor = Color(0xFF7C3AED);
  static const _morKoyu = Color(0xFF5B21B6);
  static const _soluk = Color(0xFF6B5A8E);

  late int _donem;
  bool _yukleniyor = true;
  late List<Map<String, dynamic>> _kurallar;
  late List<Map<String, dynamic>> _musteriler;
  Map<String, dynamic> _ozet = {};
  String _arama = '';

  @override
  void initState() {
    super.initState();
    _donem = widget.ilkDonem;
    _kurallar = widget.kurallar;
    _musteriler = widget.musteriler;
    _yukle();
  }

  List<Map<String, dynamic>> _liste(dynamic v) =>
      ((v as List?) ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList();

  Future<void> _yukle() async {
    setState(() => _yukleniyor = true);
    final r = await ikramHizmetYonetimGetir(widget.salonId, donem: _donem);
    if (!mounted) return;
    setState(() {
      _yukleniyor = false;
      if (r != null) {
        _kurallar = _liste(r['kurallar']);
        _musteriler = _liste(r['musteriler']);
        _ozet = r['ozet'] is Map ? Map<String, dynamic>.from(r['ozet'] as Map) : {};
      }
    });
  }

  Map<String, dynamic> _kampanyaOzet(Map<String, dynamic> k) {
    final m = _ozet['kampanyalar'];
    if (m is Map && m[k['id'].toString()] is Map) return Map<String, dynamic>.from(m[k['id'].toString()] as Map);
    return {};
  }

  @override
  Widget build(BuildContext context) {
    const donemler = {7: '7 Gün', 30: '30 Gün', 90: '90 Gün', 365: '1 Yıl'};
    final q = _arama.trim().toLowerCase();
    final musteriler = _musteriler
        .where((m) => q.isEmpty ||
            (m['ad'] ?? '').toString().toLowerCase().contains(q) ||
            (m['telefon'] ?? '').toString().contains(q) ||
            (m['hizmet_adi'] ?? '').toString().toLowerCase().contains(q))
        .toList();
    final hakli = _musteriler.where((m) => ((m['hak'] as num?)?.toInt() ?? 0) > 0).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5EDFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5EDFC),
        elevation: 0,
        foregroundColor: _koyu,
        title: const Text('Detaylı Rapor', style: TextStyle(fontWeight: FontWeight.w800, color: _koyu)),
      ),
      body: RefreshIndicator(
        color: _mor,
        onRefresh: _yukle,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            // Dönem seçimi
            Row(
              children: donemler.entries.map((e) {
                final secili = _donem == e.key;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _donem = e.key);
                      _yukle();
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: secili ? _mor : Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: secili ? _mor : const Color(0xFFE2D4F8)),
                      ),
                      child: Text(e.value,
                          style: TextStyle(color: secili ? Colors.white : _koyu, fontSize: 13, fontWeight: FontWeight.w700)),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            if (_yukleniyor)
              const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator(color: _mor)))
            else ...[
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.55,
                children: [
                  _kutu('Toplam Kazanç', '${ikramTl(_ozet['toplam'] as num?)} TL', Icons.payments_rounded,
                      alt: _artisYazi()),
                  _kutu('Önceki Dönem', '${ikramTl(_ozet['onceki'] as num?)} TL', Icons.history_rounded),
                  _kutu('Ek Kazanç', '${ikramTl(_ozet['ek_kazanc'] as num?)} TL', Icons.savings_rounded,
                      alt: 'Tekrar gelen müşteriler'),
                  _kutu('Bu Ay', '${ikramTl(_ozet['bu_ay'] as num?)} TL', Icons.calendar_month_rounded),
                  _kutu('Kampanya Kullanımı', '${(_ozet['kullanim'] as num?)?.toInt() ?? 0}', Icons.card_giftcard_rounded,
                      alt: 'Dönemde kullanılan ikram'),
                  _kutu(
                      'Kullanım Oranı',
                      _ozet['kullanim_orani'] == null ? '—' : '%${_ozet['kullanim_orani']}',
                      Icons.star_rounded,
                      alt: '${(_ozet['kullanilan_ikram'] as num?)?.toInt() ?? 0} / ${(_ozet['kazanilan_ikram'] as num?)?.toInt() ?? 0} ikram'),
                ],
              ),
              const SizedBox(height: 18),
              _baslik(Icons.campaign_rounded, 'Kampanyalar'),
              if (_kurallar.isEmpty) _bos('Henüz kampanya yok.') else ..._kurallar.map(_kampanyaSatir),
              const SizedBox(height: 14),
              _baslik(Icons.people_alt_rounded, 'İkram Kazanan Müşteriler',
                  sag: hakli > 0 ? '$hakli kişinin bekleyen ikramı var' : null),
              if (_musteriler.length > 6)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextField(
                    onChanged: (v) => setState(() => _arama = v),
                    decoration: InputDecoration(
                      hintText: 'Müşteri, telefon veya hizmet ara',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                    ),
                  ),
                ),
              if (musteriler.isEmpty)
                _bos(_musteriler.isEmpty ? 'Henüz ikram kazanan müşteri yok.' : 'Aramaya uyan müşteri yok.')
              else
                ...musteriler.map(_musteriKart),
            ],
          ],
        ),
      ),
    );
  }

  String? _artisYazi() {
    final a = (_ozet['artis_yuzde'] as num?)?.toDouble();
    if (a == null) return 'Önceki dönemle kıyas yok';
    return '${a >= 0 ? '↑' : '↓'} %${a.abs().toStringAsFixed(a.abs() < 10 && a % 1 != 0 ? 1 : 0)} ${a >= 0 ? 'artış' : 'azalış'}';
  }

  Widget _kutu(String baslik, String deger, IconData ikon, {String? alt}) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: _mor.withValues(alpha: 0.07), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Row(children: [
            Icon(ikon, size: 16, color: _mor),
            const SizedBox(width: 5),
            Expanded(child: Text(baslik, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, color: _soluk))),
          ]),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(deger, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: _koyu)),
          ),
          if (alt != null)
            Text(alt, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: _soluk)),
        ]),
      );

  Widget _baslik(IconData ikon, String yazi, {String? sag}) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          Icon(ikon, color: _morKoyu, size: 22),
          const SizedBox(width: 6),
          Text(yazi, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: _koyu)),
          const Spacer(),
          if (sag != null) Text(sag, style: const TextStyle(fontSize: 11, color: _mor, fontWeight: FontWeight.w700)),
        ]),
      );

  Widget _bos(String yazi) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Center(child: Text(yazi, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12.5, color: _soluk))),
      );

  Widget _kampanyaSatir(Map<String, dynamic> k) {
    final o = _kampanyaOzet(k);
    final aktif = ((k['aktif'] as num?)?.toInt() ?? 0) == 1;
    final bas = ikramTarih(k['baslangic']?.toString());
    final bit = ikramTarih(k['bitis_tarihi']?.toString());
    final adet = (k['gereken_adet'] as num?)?.toInt() ?? 0;
    final hediye = (k['ucretsiz_adet'] as num?)?.toInt() ?? 1;
    final kazanan = _musteriler.where((m) => m['hizmet_adi'] == k['hizmet_adi']).length;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)]),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('$adet+$hediye', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text((k['hizmet_adi'] ?? '').toString(), style: const TextStyle(fontWeight: FontWeight.w800, color: _koyu)),
            Text(
              '${bas.isEmpty ? 'Başlamadı' : '$bas – ${bit.isEmpty ? 'Süresiz' : bit}'} · ${aktif ? 'Aktif' : 'Pasif'} · $kazanan müşteri',
              style: const TextStyle(fontSize: 11, color: _soluk),
            ),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${ikramTl(o['kazanc'] as num?)} TL', style: const TextStyle(fontWeight: FontWeight.w900, color: _koyu)),
          Text('dönem: ${ikramTl(o['donem_kazanc'] as num?)} TL', style: const TextStyle(fontSize: 10.5, color: _soluk)),
        ]),
      ]),
    );
  }

  Widget _musteriKart(Map<String, dynamic> m) {
    int n(String a) => (m[a] as num?)?.toInt() ?? 0;
    final hak = n('hak');
    final tel = (m['telefon'] ?? '').toString();
    final son = (m['son_kullanma'] ?? '').toString();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text((m['ad'] ?? '').toString(), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _koyu)),
            if (tel.isNotEmpty) Text(tel, style: const TextStyle(fontSize: 11.5, color: _soluk)),
            const SizedBox(height: 3),
            Text('${m['hizmet_adi']} · ${m['kural']}', style: const TextStyle(fontSize: 12, color: _koyu)),
            Text('Ücretli alım ${n('ucretli')} · kazanılan ${n('kazanilan')} · kullanılan ${n('kullanilan')}',
                style: const TextStyle(fontSize: 11.5, color: _soluk)),
            if (hak > 0 && son.isNotEmpty)
              Text('En yakın son kullanma: ${ikramTarih(son)}', style: TextStyle(fontSize: 11.5, color: Colors.amber.shade900)),
            if (n('suresi_dolan') > 0)
              Text('${n('suresi_dolan')} ikramın süresi doldu', style: const TextStyle(fontSize: 11.5, color: Colors.red)),
          ]),
        ),
        hak > 0
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFEDE9FE), borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.card_giftcard_rounded, size: 16, color: _morKoyu),
                  const SizedBox(width: 4),
                  Text('$hak', style: const TextStyle(fontWeight: FontWeight.w800, color: _morKoyu)),
                ]),
              )
            : const Text('—', style: TextStyle(color: Color(0xFFB9A5DD))),
      ]),
    );
  }
}

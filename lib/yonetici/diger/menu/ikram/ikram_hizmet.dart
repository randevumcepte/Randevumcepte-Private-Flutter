import 'package:flutter/material.dart';
import 'package:randevu_sistem/Backend/backend.dart';
import 'kampanya_ayarlari.dart';

/// İkram Hizmet ("bir hizmeti N kez alana M ikram") — Çarkıfelek'ten bağımsız
/// yönetim sayfası. Web /isletmeyonetim/ikramhizmet ile aynı API ve kurallar
/// (backend iç adı "damga kartı": /carkAdmin/damga-karti*).
/// Müşteri ikramını ne zaman kullanacağına kendisi karar verir; kullanım
/// tahsilat ekranında personel tarafından müşteri isteyince işlenir.
class IkramHizmetPage extends StatefulWidget {
  final dynamic isletmebilgi;
  final int kullanicirolu;
  const IkramHizmetPage({Key? key, required this.isletmebilgi, required this.kullanicirolu}) : super(key: key);

  @override
  State<IkramHizmetPage> createState() => _IkramHizmetPageState();
}

class _IkramHizmetPageState extends State<IkramHizmetPage> {
  static const _mor = Color(0xFF7C3AED);
  late final String _salonId;
  bool _yukleniyor = true;
  List<Map<String, dynamic>> _kurallar = [];
  List<Map<String, dynamic>> _hizmetler = [];
  List<Map<String, dynamic>> _musteriler = [];

  @override
  void initState() {
    super.initState();
    _salonId = widget.isletmebilgi['id'].toString();
    _yukle();
  }

  List<Map<String, dynamic>> _liste(dynamic v) =>
      ((v as List?) ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList();

  Future<void> _yukle() async {
    final r = await ikramHizmetYonetimGetir(_salonId);
    if (!mounted) return;
    setState(() {
      _yukleniyor = false;
      if (r != null) {
        _kurallar = _liste(r['kurallar']);
        _hizmetler = _liste(r['hizmetler']);
        _musteriler = _liste(r['musteriler']);
      }
    });
  }

  void _bilgi(String mesaj, {bool hata = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(mesaj),
      backgroundColor: hata ? Colors.red : null,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5FF),
      appBar: AppBar(
        title: const Text('İkram Hizmet', style: TextStyle(fontWeight: FontWeight.w700)),
        elevation: 0,
      ),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _yukle,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
                children: [
                  _bilgiKutusu(),
                  const SizedBox(height: 14),
                  _baslik(Icons.rule_rounded, 'İkram Kuralları'),
                  OutlinedButton.icon(
                    onPressed: () => _kuralDuzenle(null),
                    icon: const Icon(Icons.add),
                    label: const Text('Yeni Kampanya'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _mor,
                      side: BorderSide(color: _mor.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_kurallar.isEmpty)
                    _bos('Henüz ikram kuralı yok. Örn. "Cilt Bakımı 4 kez alana 1 ikram".')
                  else
                    ..._kurallar.map(_kuralKart),
                  const SizedBox(height: 8),
                  _baslik(Icons.people_alt_rounded, 'İkram Kazanan Müşteriler'),
                  if (_musteriler.isEmpty)
                    _bos('Henüz ikram kazanan müşteri yok.')
                  else
                    ..._musteriler.map(_musteriKart),
                ],
              ),
            ),
    );
  }

  Widget _bilgiKutusu() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFFA855F7), Color(0xFF10B981)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Text(
        'Bir hizmeti belirlediğiniz sayıda ücretli alan müşteri o hizmetten ikram kazanır. '
        'Sayım "Geldi" işaretli randevulara göre yapılır; paket seansları sayılmaz. '
        'Müşteri ikramlarını uygulamasında görür ve ne zaman kullanacağına kendisi karar verir; '
        'kullanmak istediğinde tahsilat ekranından işlenir.',
        style: TextStyle(color: Colors.white, fontSize: 12.5, height: 1.4, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _baslik(IconData ikon, String yazi) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 8),
      child: Row(children: [
        Icon(ikon, color: _mor, size: 20),
        const SizedBox(width: 6),
        Text(yazi, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
      ]),
    );
  }

  String _tarih(String t) {
    final d = DateTime.tryParse(t);
    if (d == null) return t;
    String iki(int x) => x.toString().padLeft(2, '0');
    return '${iki(d.day)}.${iki(d.month)}.${d.year}';
  }

  Widget _bos(String yazi) => Container(
        padding: const EdgeInsets.all(18),
        alignment: Alignment.center,
        child: Text(yazi, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      );

  Widget _kart({required Widget child, bool soluk = false}) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: _mor.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Opacity(opacity: soluk ? 0.55 : 1, child: child),
      );

  Widget _rozet(String yazi, Color zemin, Color renk) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: zemin, borderRadius: BorderRadius.circular(20)),
        child: Text(yazi, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: renk)),
      );

  Widget _kuralKart(Map<String, dynamic> k) {
    final aktif = ((k['aktif'] as num?)?.toInt() ?? 0) == 1;
    final gereken = (k['gereken_adet'] as num?)?.toInt() ?? 0;
    final ikram = (k['ucretsiz_adet'] as num?)?.toInt() ?? 0;
    final gDeger = (k['gecerlilik_deger'] as num?)?.toInt() ?? 0;
    final gecerlilik = gDeger > 0 ? '$gDeger ${k['gecerlilik_birim'] == 'gun' ? 'gün' : 'ay'} geçerli' : 'Süresiz';
    final indirim = k['tur'] == 'indirim';
    final tarihler = (k['tarih_araligi'] ?? '').toString();
    return _kart(
      soluk: !aktif,
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFDDD6FE), Color(0xFFA855F7)]),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(children: [
            Text(indirim ? '%${k['indirim_orani']}' : '$gereken+$ikram',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF3B0764), height: 1)),
            const SizedBox(height: 1),
            Text(indirim ? 'İNDİRİM' : 'İKRAM',
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF3B0764), letterSpacing: 0.4)),
          ]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text((k['hizmet_adi'] ?? '-').toString(), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            const SizedBox(height: 2),
            Text('${k['kural_yazi'] ?? '$gereken kez alana $ikram ikram'} · kullanım: $gecerlilik', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
            if (tarihler.isNotEmpty)
              Text('Kampanya: $tarihler', style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
            const SizedBox(height: 6),
            aktif
                ? _rozet('AÇIK', const Color(0xFFDCFCE7), const Color(0xFF166534))
                : _rozet('KAPALI', Colors.grey.shade200, Colors.grey.shade700),
          ]),
        ),
        IconButton(icon: const Icon(Icons.edit, color: _mor), tooltip: 'Düzenle', onPressed: () => _kuralDuzenle(k)),
        IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), tooltip: 'Sil', onPressed: () => _kuralSil(k)),
      ]),
    );
  }

  Widget _musteriKart(Map<String, dynamic> m) {
    int n(String a) => (m[a] as num?)?.toInt() ?? 0;
    final hak = n('hak');
    final tel = (m['telefon'] ?? '').toString();
    final son = (m['son_kullanma'] ?? '').toString();
    return _kart(
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text((m['ad'] ?? '').toString(), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            if (tel.isNotEmpty) Text(tel, style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
            const SizedBox(height: 4),
            Text('${m['hizmet_adi']} · ${m['kural']}', style: TextStyle(fontSize: 12, color: Colors.grey.shade800)),
            const SizedBox(height: 2),
            Text('Ücretli alım ${n('ucretli')} · kazanılan ${n('kazanilan')} · kullanılan ${n('kullanilan')}',
                style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
            if (hak > 0 && son.isNotEmpty)
              Text('En yakın son kullanma: ${_tarih(son)}', style: TextStyle(fontSize: 11.5, color: Colors.amber.shade900)),
            if (n('suresi_dolan') > 0)
              Text('${n('suresi_dolan')} ikramın süresi doldu', style: const TextStyle(fontSize: 11.5, color: Colors.red)),
          ]),
        ),
        hak > 0
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFEDE9FE), borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.card_giftcard_rounded, size: 16, color: Color(0xFF5B21B6)),
                const SizedBox(width: 4),
                Text('$hak', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF5B21B6))),
              ]),
              )
            : Text('—', style: TextStyle(color: Colors.grey.shade400)),
      ]),
    );
  }

  Future<void> _kuralDuzenle(Map<String, dynamic>? mevcut) async {
    final kaydedildi = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => KampanyaAyarlariSayfasi(salonId: _salonId, mevcut: mevcut, hizmetler: _hizmetler),
      ),
    );
    if (kaydedildi == true && mounted) {
      _yukle();
      _bilgi('Kampanya kaydedildi');
    }
  }

  Future<void> _kuralSil(Map<String, dynamic> k) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('İkram Kuralını Sil'),
        content: Text('"${k['hizmet_adi']}" ikram kuralı silinsin mi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final r = await carkAdminDamgaKartiSil(_salonId, (k['id'] as num).toInt());
    if (!mounted) return;
    if (r != null && r['basarili'] == true) {
      _yukle();
      _bilgi('İkram kuralı silindi');
    } else {
      _bilgi(r?['mesaj']?.toString() ?? 'Silinemedi', hata: true);
    }
  }
}

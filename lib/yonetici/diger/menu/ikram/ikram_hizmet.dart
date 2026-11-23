import 'package:flutter/material.dart';
import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Frontend/aramali_dropdown.dart';

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
                    label: const Text('Yeni İkram Kuralı'),
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
            Text('$gereken+$ikram',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF3B0764), height: 1)),
            const SizedBox(height: 1),
            const Text('İKRAM',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF3B0764), letterSpacing: 0.4)),
          ]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text((k['hizmet_adi'] ?? '-').toString(), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            const SizedBox(height: 2),
            Text('$gereken kez alana $ikram ikram · $gecerlilik', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
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
    int? hizmetId = (mevcut?['hizmet_id'] as num?)?.toInt();
    final gerekenCtrl = TextEditingController(text: ((mevcut?['gereken_adet'] as num?)?.toInt() ?? 4).toString());
    final ikramCtrl = TextEditingController(text: ((mevcut?['ucretsiz_adet'] as num?)?.toInt() ?? 1).toString());
    final mevcutSure = (mevcut?['gecerlilik_deger'] as num?)?.toInt() ?? 0;
    final sureCtrl = TextEditingController(text: mevcutSure > 0 ? '$mevcutSure' : '');
    String sureBirim = mevcut?['gecerlilik_birim'] == 'gun' ? 'gun' : 'ay';
    bool aktif = ((mevcut?['aktif'] as num?)?.toInt() ?? 1) == 1;
    bool kaydediyor = false;

    // Kuraldaki hizmet artik aktif listede degilse de secili gorunsun
    final hizmetler = List<Map<String, dynamic>>.from(_hizmetler);
    if (hizmetId != null && !hizmetler.any((h) => (h['id'] as num).toInt() == hizmetId)) {
      hizmetler.insert(0, {'id': hizmetId, 'hizmet_adi': mevcut?['hizmet_adi'] ?? 'Hizmet #$hizmetId'});
    }

    await showDialog(
      context: context,
      builder: (c) => StatefulBuilder(builder: (c, setSt) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(mevcut == null ? 'Yeni İkram Kuralı' : 'İkram Kuralını Düzenle'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              AramaliDropdownFormField<int>(
                value: hizmetId,
                isExpanded: true,
                hint: const Text('Hizmet ara veya seçin'),
                decoration: const InputDecoration(labelText: 'Hizmet', border: OutlineInputBorder()),
                items: hizmetler
                    .map((h) => DropdownMenuItem<int>(
                          value: (h['id'] as num).toInt(),
                          child: Text((h['hizmet_adi'] ?? '').toString(), overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (v) => setSt(() => hizmetId = v),
              ),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: gerekenCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Kaç kez alana', suffixText: 'kez', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: ikramCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'İkram', suffixText: 'seans', border: OutlineInputBorder()),
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: sureCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Kullanım süresi',
                      hintText: 'Boş = süresiz',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 96,
                  child: DropdownButtonFormField<String>(
                    value: sureBirim,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'ay', child: Text('ay')),
                      DropdownMenuItem(value: 'gun', child: Text('gün')),
                    ],
                    onChanged: (v) => setSt(() => sureBirim = v ?? 'ay'),
                  ),
                ),
              ]),
              const SizedBox(height: 4),
              Text('İkram, kazanıldığı günden itibaren bu süre içinde kullanılmazsa düşer.',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              const SizedBox(height: 8),
              Text(
                '"Geldi" işaretli ücretli randevular sayılır; paket/seanslı satış seansları sayılmaz. '
                'Müşteri ikramını istediği zaman kullanır.',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600, height: 1.35),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Aktif'),
                subtitle: const Text('Sayım açıldığı andan itibaren başlar', style: TextStyle(fontSize: 11)),
                value: aktif,
                activeColor: _mor,
                onChanged: (v) => setSt(() => aktif = v),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: kaydediyor ? null : () => Navigator.pop(c), child: const Text('İptal')),
            ElevatedButton(
              onPressed: kaydediyor
                  ? null
                  : () async {
                      if (hizmetId == null) {
                        _bilgi('Lütfen bir hizmet seçin', hata: true);
                        return;
                      }
                      setSt(() => kaydediyor = true);
                      final veri = <String, dynamic>{
                        if (mevcut != null) 'id': mevcut['id'],
                        'hizmet_id': hizmetId,
                        'gereken_adet': int.tryParse(gerekenCtrl.text.trim()) ?? 0,
                        'ucretsiz_adet': int.tryParse(ikramCtrl.text.trim()) ?? 0,
                        'aktif': aktif ? 1 : 0,
                        'gecerlilik_deger': int.tryParse(sureCtrl.text.trim()) ?? 0,
                        'gecerlilik_birim': sureBirim,
                      };
                      var r = await carkAdminDamgaKartiKaydet(_salonId, veri);
                      if (!mounted) return;
                      // Sayilmis ziyareti olan kuralda adet/hizmet degisiyor: etkisini gosterip onay al
                      if (r != null && r['onay_gerekli'] == true) {
                        final evet = await showDialog<bool>(
                          context: c,
                          builder: (d) => AlertDialog(
                            title: const Text('Müşteriler etkilenecek'),
                            content: Text(r!['mesaj']?.toString() ?? ''),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Vazgeç')),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(d, true),
                                style: ElevatedButton.styleFrom(backgroundColor: _mor, foregroundColor: Colors.white),
                                child: const Text('Evet, kaydet'),
                              ),
                            ],
                          ),
                        );
                        if (!mounted) return;
                        if (evet != true) {
                          setSt(() => kaydediyor = false);
                          return;
                        }
                        r = await carkAdminDamgaKartiKaydet(_salonId, {...veri, 'onay': 1});
                        if (!mounted) return;
                      }
                      setSt(() => kaydediyor = false);
                      if (r != null && r['basarili'] == true) {
                        Navigator.pop(c);
                        _yukle();
                        _bilgi('İkram kuralı kaydedildi');
                      } else {
                        _bilgi(r?['mesaj']?.toString() ?? 'Kaydedilemedi', hata: true);
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: _mor, foregroundColor: Colors.white),
              child: kaydediyor
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(mevcut == null ? 'Ekle' : 'Güncelle'),
            ),
          ],
        );
      }),
    );
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

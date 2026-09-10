// Grup dersi katilimci yonetim ekrani — takvimde ders bloguna tiklayinca acilir.
// Katilimci ekle/cikar/geldi-gelmedi + dersi duzenle/iptal. Web panel modalinin mobil karsiligi.
import 'package:flutter/material.dart';
import 'package:randevu_sistem/Backend/backend.dart' show musterilistegetirSayfali;
import 'package:randevu_sistem/Backend/grup_dersi_api.dart';
import 'package:randevu_sistem/Models/grup_dersi.dart';
import 'package:randevu_sistem/Models/musteri_danisanlar.dart';
import 'package:randevu_sistem/yonetici/randevular/grup_dersi_ekle_ekran.dart';

const Color _mor = Color(0xFF5C008E);

class GrupDersiKatilimciEkran extends StatefulWidget {
  final String salonId;
  final int oturumId;
  final Map isletmebilgi;
  const GrupDersiKatilimciEkran({
    Key? key,
    required this.salonId,
    required this.oturumId,
    required this.isletmebilgi,
  }) : super(key: key);

  @override
  State<GrupDersiKatilimciEkran> createState() => _GrupDersiKatilimciEkranState();
}

class _GrupDersiKatilimciEkranState extends State<GrupDersiKatilimciEkran> {
  bool _yukleniyor = true;
  String? _hata;
  GrupDersOturum? _oturum;
  List<GrupDersKatilimci> _katilimcilar = [];

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    setState(() { _yukleniyor = true; _hata = null; });
    try {
      final r = await dersOturumGetir(widget.salonId, widget.oturumId);
      setState(() {
        _oturum = r['oturum'] as GrupDersOturum;
        _katilimcilar = (r['katilimcilar'] as List).cast<GrupDersKatilimci>();
        _yukleniyor = false;
      });
    } catch (e) {
      setState(() { _hata = e.toString(); _yukleniyor = false; });
    }
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  int get _aktifSayi =>
      _katilimcilar.where((k) => k.durum != 'iptal' && k.durum != 'bekleme').length;

  Future<void> _durumDegistir(GrupDersKatilimci k, String yeni) async {
    try {
      final dusum = await dersKatilimciDurum(widget.salonId, k.id, yeni);
      if (dusum == 'dusuldu') _snack('Geldi işaretlendi, paketten 1 seans düşüldü.');
      else if (dusum == 'hak_yok') _snack('Geldi işaretlendi (paket/seans hakkı bulunamadı).');
      else if (dusum == 'iade') _snack('Seans iade edildi.');
      await _yukle();
    } catch (e) {
      _snack('Hata: $e');
    }
  }

  Future<void> _cikar(GrupDersKatilimci k) async {
    try {
      await dersKatilimciCikar(widget.salonId, k.id);
      await _yukle();
    } catch (e) {
      _snack('Hata: $e');
    }
  }

  Future<void> _dersiIptalEt() async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Dersi İptal Et'),
        content: const Text('Bu ders takvimden kaldırılacak ve katılımcılara bildirilecek. Emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Vazgeç')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('İptal Et', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (onay != true) return;
    try {
      await dersOturumSil(widget.salonId, widget.oturumId);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _snack('Hata: $e');
    }
  }

  Future<void> _dersiDuzenle() async {
    final o = _oturum;
    if (o == null) return;
    final sonuc = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => GrupDersiEkleEkran(
          salonId: widget.salonId,
          isletmebilgi: widget.isletmebilgi,
          duzenlenecek: o,
        ),
      ),
    );
    if (sonuc == true) await _yukle();
  }

  Future<void> _katilimciEkleAra() async {
    final secili = await showModalBottomSheet<MusteriDanisan>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MusteriAraSheet(salonId: widget.salonId),
    );
    if (secili == null) return;
    try {
      final r = await dersKatilimciEkle(widget.salonId, widget.oturumId, int.parse(secili.id.toString()));
      if (r['katilimci_durum'] == 'bekleme') _snack('Kapasite dolu — bekleme listesine eklendi.');
      await _yukle();
    } catch (e) {
      _snack('Hata: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = _oturum;
    final dolu = o != null && _aktifSayi >= o.kapasite;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _mor,
        foregroundColor: Colors.white,
        title: const Text('Ders Katılımcıları'),
        actions: [
          if (o != null)
            IconButton(icon: const Icon(Icons.edit), tooltip: 'Dersi Düzenle', onPressed: _dersiDuzenle),
          if (o != null)
            IconButton(icon: const Icon(Icons.delete_outline), tooltip: 'Dersi İptal Et', onPressed: _dersiIptalEt),
        ],
      ),
      floatingActionButton: (o == null)
          ? null
          : FloatingActionButton.extended(
              backgroundColor: _mor,
              icon: const Icon(Icons.person_add),
              label: const Text('Katılımcı Ekle'),
              onPressed: _katilimciEkleAra,
            ),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : _hata != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('Yüklenemedi:\n$_hata', textAlign: TextAlign.center)))
              : RefreshIndicator(
                  onRefresh: _yukle,
                  child: ListView(
                    padding: const EdgeInsets.all(14),
                    children: [
                      _ozetKart(o!, dolu),
                      const SizedBox(height: 12),
                      if (_katilimcilar.where((k) => k.durum != 'iptal').isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 30),
                          child: Center(child: Text('Henüz katılımcı yok.', style: TextStyle(color: Colors.grey))),
                        ),
                      ..._katilimcilar
                          .where((k) => k.durum != 'iptal')
                          .map((k) => _katilimciKart(k))
                          .toList(),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
    );
  }

  Widget _ozetKart(GrupDersOturum o, bool dolu) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFECE8F4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(o.dersTipi, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _mor)),
                const SizedBox(height: 4),
                Text('${o.tarih}  ${o.saat} - ${o.saatBitis}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                if (o.personel.isNotEmpty) Text('👤 ${o.personel}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                if (o.hizmetId == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text('Hizmet bağlı değil — paket düşmez / online kapalı',
                        style: TextStyle(color: Colors.orange, fontSize: 11)),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: dolu ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text('$_aktifSayi / ${o.kapasite}',
                style: TextStyle(fontWeight: FontWeight.bold, color: dolu ? const Color(0xFFEF4444) : const Color(0xFF059669))),
          ),
        ],
      ),
    );
  }

  Widget _katilimciKart(GrupDersKatilimci k) {
    final bekleme = k.durum == 'bekleme';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0xFFEEF1F4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(k.ad, style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (k.tel.isNotEmpty) Text(k.tel, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red, size: 20),
                tooltip: 'Çıkar',
                onPressed: () => _cikar(k),
              ),
            ],
          ),
          if (bekleme)
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('BEKLEMEDE', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
            )
          else
            Wrap(
              spacing: 6,
              children: [
                _durumBtn(k, 'rezerve', 'Rezerve', Colors.blue),
                _durumBtn(k, 'geldi', 'Geldi', const Color(0xFF059669)),
                _durumBtn(k, 'gelmedi', 'Gelmedi', const Color(0xFFEF4444)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _durumBtn(GrupDersKatilimci k, String d, String lbl, Color renk) {
    final aktif = k.durum == d;
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: aktif ? renk : Colors.transparent,
        foregroundColor: aktif ? Colors.white : Colors.black54,
        side: BorderSide(color: aktif ? renk : const Color(0xFFD7DDE3)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        minimumSize: const Size(0, 32),
      ),
      onPressed: aktif ? null : () => _durumDegistir(k, d),
      child: Text(lbl, style: const TextStyle(fontSize: 12)),
    );
  }
}

// Müşteri arama bottom sheet (mevcut /musteriler arama endpointini kullanir)
class _MusteriAraSheet extends StatefulWidget {
  final String salonId;
  const _MusteriAraSheet({Key? key, required this.salonId}) : super(key: key);
  @override
  State<_MusteriAraSheet> createState() => _MusteriAraSheetState();
}

class _MusteriAraSheetState extends State<_MusteriAraSheet> {
  final _c = TextEditingController();
  bool _ara = false;
  List<MusteriDanisan> _sonuc = [];

  Future<void> _search() async {
    final q = _c.text.trim();
    if (q.length < 2) return;
    setState(() => _ara = true);
    try {
      final r = await musterilistegetirSayfali('', widget.salonId, q, '20', '0');
      setState(() { _sonuc = r; _ara = false; });
    } catch (_) {
      setState(() { _sonuc = []; _ara = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
        padding: const EdgeInsets.all(16),
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            const Text('Katılımcı Ekle', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _mor)),
            const SizedBox(height: 10),
            TextField(
              controller: _c,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: 'İsim veya telefon (en az 2 harf)',
                suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: _search),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _ara
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.separated(
                      itemCount: _sonuc.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final m = _sonuc[i];
                        return ListTile(
                          title: Text(m.name),
                          subtitle: Text(m.cep_telefon),
                          onTap: () => Navigator.pop(context, m),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

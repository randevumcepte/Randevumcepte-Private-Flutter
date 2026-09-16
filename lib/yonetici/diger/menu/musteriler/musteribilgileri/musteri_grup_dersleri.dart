// Isletme musteri detayinda: musterinin dahil oldugu GRUP DERSLERI bolumu.
// Isletme buradan katildi/katilmadi isaretleyebilir veya kaydi silebilir.
import 'package:flutter/material.dart';
import 'package:randevu_sistem/Backend/grup_dersi_api.dart';
import 'package:randevu_sistem/Models/grup_dersi.dart';
import 'package:randevu_sistem/yonetici/adisyonlar/satislar/ders_slot_secici.dart';

const Color _mor = Color(0xFF5C008E);

class MusteriGrupDersleri extends StatefulWidget {
  final String userId; // musteri (danisan) id
  final String salonId;
  final bool tekrarliAktif; // studyo modu: tekrarli otomatik katilim bolumu
  const MusteriGrupDersleri(
      {Key? key, required this.userId, required this.salonId, this.tekrarliAktif = false})
      : super(key: key);

  @override
  State<MusteriGrupDersleri> createState() => _MusteriGrupDersleriState();
}

class _MusteriGrupDersleriState extends State<MusteriGrupDersleri> {
  bool _yukleniyor = true;
  String? _hata;
  List<Map<String, dynamic>> _dersler = [];
  List<Map<String, dynamic>> _tekrarli = [];
  final Set<int> _islemde = {};

  static const List<String> _gunAdi = ['', 'Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

  @override
  void initState() {
    super.initState();
    _yukle();
    if (widget.tekrarliAktif) _yukleTekrarli();
  }

  Future<void> _yukleTekrarli() async {
    try {
      final r = await dersTekrarliListe(widget.salonId, widget.userId);
      if (!mounted) return;
      setState(() => _tekrarli = r);
    } catch (_) {/* sessiz */}
  }

  Future<void> _yukle() async {
    setState(() {
      _yukleniyor = true;
      _hata = null;
    });
    try {
      final r = await danisanGrupDerslerim(widget.userId, salonId: widget.salonId);
      if (!mounted) return;
      setState(() {
        _dersler = r;
        _yukleniyor = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hata = 'Grup dersleri yüklenemedi.';
        _yukleniyor = false;
      });
    }
  }

  void _snack(String m, {bool hata = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(m),
      backgroundColor: hata ? Colors.redAccent : const Color(0xFF059669),
    ));
  }

  Future<void> _durum(Map<String, dynamic> d, String durum) async {
    final kid = int.tryParse(d['katilimci_id'].toString()) ?? 0;
    if (kid == 0) return;
    setState(() => _islemde.add(kid));
    try {
      await dersKatilimciDurum(widget.salonId, kid, durum);
      _snack(durum == 'geldi' ? 'Katıldı olarak işaretlendi.' : 'Katılmadı olarak işaretlendi.');
      await _yukle();
    } catch (_) {
      _snack('İşlem başarısız.', hata: true);
    } finally {
      if (mounted) setState(() => _islemde.remove(kid));
    }
  }

  Future<void> _sil(Map<String, dynamic> d) async {
    final kid = int.tryParse(d['katilimci_id'].toString()) ?? 0;
    if (kid == 0) return;
    final onay = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Kaydı Sil'),
        content: Text('${d['ders_tipi']} • ${d['tarih']} ${d['saat']}\n\n'
            'Bu dersten kaydı silinsin mi? (Düşülen seans varsa iade edilir.)'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Vazgeç')),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Sil', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (onay != true) return;
    setState(() => _islemde.add(kid));
    try {
      await dersKatilimciCikar(widget.salonId, kid);
      _snack('Kayıt silindi.');
      await _yukle();
    } catch (_) {
      _snack('Silinemedi.', hata: true);
    } finally {
      if (mounted) setState(() => _islemde.remove(kid));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_yukleniyor) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: _mor))),
      );
    }
    if (_hata != null) {
      return _kart(child: Row(children: [
        const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(_hata!, style: TextStyle(color: Colors.grey.shade600))),
        TextButton(onPressed: _yukle, child: const Text('Tekrar')),
      ]));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.tekrarliAktif) _tekrarliBolum(),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
          child: Row(
            children: [
              const Icon(Icons.groups_rounded, size: 18, color: _mor),
              const SizedBox(width: 6),
              const Text('Grup Dersleri',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF2C3E50))),
              const SizedBox(width: 6),
              Text('(${_dersler.length})', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
            ],
          ),
        ),
        if (_dersler.isEmpty)
          _kart(child: Text('Bu müşteri henüz bir grup dersine kayıtlı değil.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13.5)))
        else
          for (final d in _dersler) _dersKart(d),
      ],
    );
  }

  // ── Tekrarli otomatik katilim bolumu (studyo modu) ──
  Widget _tekrarliBolum() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
          child: Row(
            children: [
              const Icon(Icons.event_repeat_rounded, size: 18, color: _mor),
              const SizedBox(width: 6),
              const Expanded(
                child: Text('Otomatik Ders Planı',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF2C3E50))),
              ),
              TextButton.icon(
                onPressed: _yeniTekrarli,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Plan Oluştur'),
                style: TextButton.styleFrom(foregroundColor: _mor, visualDensity: VisualDensity.compact),
              ),
            ],
          ),
        ),
        if (_tekrarli.isEmpty)
          _kart(child: Text('Paket seanslarını seçtiğiniz gün/saat/eğitmene göre takvime otomatik dağıtın.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13)))
        else
          for (final t in _tekrarli) _tekrarliKart(t),
        const SizedBox(height: 6),
        const Divider(height: 20),
      ],
    );
  }

  Widget _tekrarliKart(Map<String, dynamic> t) {
    final gunler = (t['gunler'] as List?)?.map((e) => _gunAdi[(int.tryParse(e.toString()) ?? 0).clamp(0, 7)]).join(', ') ?? '';
    final yerlesen = int.tryParse(t['yerlesen'].toString()) ?? 0;
    final toplam = int.tryParse(t['toplam_seans'].toString()) ?? 0;
    final kalan = int.tryParse(t['kalan'].toString()) ?? 0;
    final id = int.tryParse(t['id'].toString()) ?? 0;
    final islemde = _islemde.contains(-id); // negatif: tekrarli id cakismasin
    return _kart(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${t['hizmet_adi']}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 3),
                Text('$gunler • $yerlesen/$toplam seans yerleşti${kalan > 0 ? ' • $kalan bekliyor' : ''}',
                    style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600)),
              ],
            ),
          ),
          IconButton(
            onPressed: islemde ? null : () => _tekrarliSil(t),
            icon: islemde
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            tooltip: 'Planı sil (gelecek dersler temizlenir)',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Future<void> _yeniTekrarli() async {
    final degisti = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TekrarliKatilimForm(userId: widget.userId, salonId: widget.salonId),
    );
    if (degisti == true) {
      await _yukleTekrarli();
      await _yukle();
    }
  }

  Future<void> _tekrarliSil(Map<String, dynamic> t) async {
    final id = int.tryParse(t['id'].toString()) ?? 0;
    if (id == 0) return;
    final onay = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Planı Sil'),
        content: Text('${t['hizmet_adi']} otomatik ders planı silinsin mi?\n\n'
            'Gelecekteki otomatik kayıtlar temizlenir; geçmiş dersler korunur.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Vazgeç')),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Sil', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (onay != true) return;
    setState(() => _islemde.add(-id));
    try {
      final n = await dersTekrarliSil(widget.salonId, id);
      _snack('Plan silindi. $n gelecek ders temizlendi.');
      await _yukleTekrarli();
      await _yukle();
    } catch (_) {
      _snack('Silinemedi.', hata: true);
    } finally {
      if (mounted) setState(() => _islemde.remove(-id));
    }
  }

  Widget _kart({required Widget child}) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEDE7F4)),
        ),
        child: child,
      );

  Widget _durumRozet(String durum) {
    late Color c;
    late String t;
    switch (durum) {
      case 'geldi': c = const Color(0xFF059669); t = 'Katıldı'; break;
      case 'gelmedi': c = const Color(0xFFEF4444); t = 'Katılmadı'; break;
      case 'bekleme': c = const Color(0xFFF59E0B); t = 'Beklemede'; break;
      default: c = _mor; t = 'Rezerve';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(t, style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }

  Widget _dersKart(Map<String, dynamic> d) {
    final durum = (d['durum'] ?? 'rezerve').toString();
    final kid = int.tryParse(d['katilimci_id'].toString()) ?? 0;
    final islemde = _islemde.contains(kid);
    final egitmen = (d['personel'] ?? d['egitmen'] ?? '').toString();

    return _kart(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('${d['ders_tipi']}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
              ),
              _durumRozet(durum),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.event_outlined, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text('${d['tarih']} ${d['saat']}',
                  style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600)),
              if (egitmen.isNotEmpty && egitmen != 'null') ...[
                const SizedBox(width: 8),
                Icon(Icons.person_outline, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 3),
                Flexible(child: Text(egitmen, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600))),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: islemde ? null : () => _durum(d, 'gelmedi'),
                  icon: const Icon(Icons.close_rounded, size: 15),
                  label: const Text('Katılmadı'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                    side: const BorderSide(color: Color(0xFFF0B4AC)),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    minimumSize: const Size(0, 34),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: islemde ? null : () => _durum(d, 'geldi'),
                  icon: const Icon(Icons.check_rounded, size: 15),
                  label: const Text('Katıldı'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    minimumSize: const Size(0, 34),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: islemde ? null : () => _sil(d),
                icon: islemde
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                tooltip: 'Kaydı sil',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Tekrarli otomatik katilim olusturma formu (bottom sheet) ──
class TekrarliKatilimForm extends StatefulWidget {
  final String userId;
  final String salonId;
  const TekrarliKatilimForm({Key? key, required this.userId, required this.salonId}) : super(key: key);

  @override
  State<TekrarliKatilimForm> createState() => _TekrarliKatilimFormState();
}

class _TekrarliKatilimFormState extends State<TekrarliKatilimForm> {
  static const Color _mor = Color(0xFF5C008E);
  static const List<String> _gunAdi = ['', 'Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

  bool _yukleniyor = true;
  bool _kaydediyor = false;
  String? _hata;

  List<Map<String, dynamic>> _kaynaklar = [];
  List<GrupDersSablon> _sablonlar = [];
  int? _kaynakIndex;

  final Set<int> _seciliSablon = {}; // secili sabit ders slotlari (sablon id) — her slot gun+saat+egitmen tasir
  int _toplamSeans = 0;
  DateTime _baslangic = DateTime.now();

  String _hhmm(String s) => s.length >= 5 ? s.substring(0, 5) : s;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    try {
      final k = await dersTekrarliKaynaklar(widget.salonId, widget.userId);
      final p = await dersProgramiListe(widget.salonId);
      if (!mounted) return;
      setState(() {
        _kaynaklar = k;
        _sablonlar = (p['sablon'] as List).cast<GrupDersSablon>();
        _yukleniyor = false;
        if (_kaynaklar.isNotEmpty) _kaynakSec(0);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hata = 'Bilgiler yüklenemedi.';
        _yukleniyor = false;
      });
    }
  }

  Map<String, dynamic>? get _kaynak =>
      (_kaynakIndex != null && _kaynakIndex! < _kaynaklar.length) ? _kaynaklar[_kaynakIndex!] : null;

  // Secili kaynagin hizmetine ait sablonlar (hoca filtresi UI'da ayrica uygulanir)
  List<GrupDersSablon> get _uygunSablon {
    final k = _kaynak;
    if (k == null) return [];
    final hid = k['hizmet_id'].toString();
    return _sablonlar.where((s) => (s.hizmetId ?? '').toString() == hid).toList();
  }

  // Secili slotlar (gun + saat sirali) — ozet gosterim icin
  List<GrupDersSablon> get _seciliSlotlar {
    final l = _uygunSablon.where((s) => _seciliSablon.contains(s.id)).toList();
    l.sort((a, b) {
      final g = a.haftaGunu.compareTo(b.haftaGunu);
      return g != 0 ? g : _hhmm(a.saat).compareTo(_hhmm(b.saat));
    });
    return l;
  }

  void _kaynakSec(int i) {
    setState(() {
      _kaynakIndex = i;
      _seciliSablon.clear();
      _toplamSeans = int.tryParse(_kaynaklar[i]['kalan_seans'].toString()) ?? 0;
    });
  }

  void _snack(String m, {bool hata = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(m),
      backgroundColor: hata ? Colors.redAccent : const Color(0xFF059669),
    ));
  }

  Future<void> _tarihSec() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _baslangic,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 366)),
      locale: const Locale('tr', 'TR'),
    );
    if (d != null) setState(() => _baslangic = d);
  }

  // Satis ekranindaki ile ayni slot secici (gun+saat+egitmen) — her slot kendi saatini tasir
  Future<void> _slotSeciciAc() async {
    final r = await showModalBottomSheet<Set<int>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DersSlotSecici(slotlar: _uygunSablon, secili: Set<int>.from(_seciliSablon)),
    );
    if (r != null && mounted) setState(() => _seciliSablon..clear()..addAll(r));
  }

  Future<void> _kaydet() async {
    final k = _kaynak;
    if (k == null) return;
    if (_seciliSablon.isEmpty) {
      _snack('En az bir ders slotu seçin.', hata: true);
      return;
    }
    if (_toplamSeans <= 0) {
      _snack('Seans sayısı geçersiz.', hata: true);
      return;
    }
    setState(() => _kaydediyor = true);
    try {
      final r = await dersTekrarliKaydet(
        salonId: widget.salonId,
        userId: widget.userId,
        hizmetId: int.tryParse(k['hizmet_id'].toString()) ?? 0,
        toplamSeans: _toplamSeans,
        sablonlar: _seciliSablon.toList(),
        baslangic:
            '${_baslangic.year}-${_baslangic.month.toString().padLeft(2, '0')}-${_baslangic.day.toString().padLeft(2, '0')}',
        adisyonPaketId: k['adisyon_paket_id'] == null ? null : int.tryParse(k['adisyon_paket_id'].toString()),
        adisyonHizmetId: k['adisyon_hizmet_id'] == null ? null : int.tryParse(k['adisyon_hizmet_id'].toString()),
      );
      final s = Map<String, dynamic>.from(r['sonuc'] ?? {});
      final olusan = int.tryParse(s['olusan'].toString()) ?? 0;
      final yeniOturum = int.tryParse(s['oturum_olusturulan'].toString()) ?? 0;
      final yerlesmeyen = int.tryParse(s['yerlesmeyen'].toString()) ?? 0;
      _snack('$olusan ders planlandı${yeniOturum > 0 ? ' ($yeniOturum yeni oturum açıldı)' : ''}'
          '${yerlesmeyen > 0 ? ' • $yerlesmeyen seans yerleştirilemedi' : ''}.');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _snack('Kaydedilemedi: ${e.toString().replaceAll('Exception: ', '')}', hata: true);
    } finally {
      if (mounted) setState(() => _kaydediyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final alt = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(18, 12, 18, 18 + alt),
      child: _yukleniyor
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 50),
              child: Center(child: CircularProgressIndicator(color: _mor)))
          : _hata != null
              ? Padding(padding: const EdgeInsets.symmetric(vertical: 40), child: Center(child: Text(_hata!)))
              : _kaynaklar.isEmpty
                  ? _bosDurum()
                  : _form(),
    );
  }

  Widget _bosDurum() {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      _tutamac(),
      const SizedBox(height: 20),
      Icon(Icons.inventory_2_outlined, size: 40, color: Colors.grey.shade400),
      const SizedBox(height: 10),
      Text('Bu müşterinin uygun (kalan seanslı) paket/hizmet satışı yok.',
          textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
      const SizedBox(height: 16),
      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Kapat')),
    ]);
  }

  Widget _tutamac() => Center(
        child: Container(
          width: 42,
          height: 4,
          decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(3)),
        ),
      );

  Widget _form() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _tutamac(),
          const SizedBox(height: 12),
          const Text('Otomatik Ders Planı',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF2C3E50))),
          const SizedBox(height: 4),
          Text('Seçtiğiniz ders slotlarına (gün + saat + eğitmen) paket seanslarını haftalık olarak otomatik dağıtır. Her slot kendi saatini taşır — farklı günlere farklı saat verebilirsiniz.',
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600)),
          const SizedBox(height: 16),

          _etiket('Paket / Hizmet'),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE0D6EC)),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                isExpanded: true,
                value: _kaynakIndex,
                items: [
                  for (int i = 0; i < _kaynaklar.length; i++)
                    DropdownMenuItem(
                      value: i,
                      child: Text('${_kaynaklar[i]['etiket']} • ${_kaynaklar[i]['kalan_seans']} seans',
                          overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5)),
                    ),
                ],
                onChanged: (v) => v != null ? _kaynakSec(v) : null,
              ),
            ),
          ),
          const SizedBox(height: 16),

          _etiket('Seans Sayısı'),
          Row(children: [
            _sayacBtn(Icons.remove, () => setState(() => _toplamSeans = (_toplamSeans - 1).clamp(1, 999))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Text('$_toplamSeans', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            ),
            _sayacBtn(Icons.add, () => setState(() => _toplamSeans = (_toplamSeans + 1).clamp(1, 999))),
            const Spacer(),
            Text('kalan: ${_kaynak?['kalan_seans'] ?? 0}', style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500)),
          ]),
          const SizedBox(height: 16),

          _etiket('Ders Slotları'),
          if (_uygunSablon.isEmpty)
            _uyari('Bu hizmet için haftalık programda ders yok. Önce Ders Programı ekranından ekleyin.')
          else ...[
            InkWell(
              onTap: _slotSeciciAc,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE0D6EC)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  const Icon(Icons.event_repeat_rounded, size: 17, color: _mor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _seciliSablon.isEmpty
                          ? 'Gün + saat + eğitmen slotu seçin'
                          : '${_seciliSablon.length} slot seçildi',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _seciliSablon.isEmpty ? Colors.grey.shade500 : const Color(0xFF2C3E50)),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
                ]),
              ),
            ),
            if (_seciliSablon.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final s in _seciliSlotlar) _slotOzetCip(s),
              ]),
            ],
          ],
          const SizedBox(height: 16),

          _etiket('Başlangıç'),
          InkWell(
            onTap: _tarihSec,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE0D6EC)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                const Icon(Icons.calendar_today_rounded, size: 17, color: _mor),
                const SizedBox(width: 10),
                Text(
                    '${_baslangic.day.toString().padLeft(2, '0')}.${_baslangic.month.toString().padLeft(2, '0')}.${_baslangic.year}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
          const SizedBox(height: 22),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (_kaydediyor || _uygunSablon.isEmpty) ? null : _kaydet,
              icon: _kaydediyor
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.auto_awesome_rounded, size: 18),
              label: Text(_kaydediyor ? 'Dağıtılıyor…' : 'Planla ve Dağıt'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _mor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _etiket(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Text(t, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF6B7280))),
      );

  Widget _uyari(String t) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(10)),
        child: Text(t, style: const TextStyle(fontSize: 12.5, color: Color(0xFF9A3412))),
      );

  Widget _sayacBtn(IconData ic, VoidCallback onTap) => Material(
        color: const Color(0xFFF3EEF9),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(padding: const EdgeInsets.all(8), child: Icon(ic, size: 20, color: _mor)),
        ),
      );

  Widget _slotOzetCip(GrupDersSablon s) {
    final gun = _gunAdi[s.haftaGunu.clamp(0, 7)];
    final saat = _hhmm(s.saat);
    final hoca = (s.personel.isNotEmpty && s.personel != 'null') ? s.personel : '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EEF9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text('$gun $saat${hoca.isNotEmpty ? ' • $hoca' : ''}',
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: _mor)),
    );
  }
}

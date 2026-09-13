// Isletme musteri detayinda: musterinin dahil oldugu GRUP DERSLERI bolumu.
// Isletme buradan katildi/katilmadi isaretleyebilir veya kaydi silebilir.
import 'package:flutter/material.dart';
import 'package:randevu_sistem/Backend/grup_dersi_api.dart';

const Color _mor = Color(0xFF5C008E);

class MusteriGrupDersleri extends StatefulWidget {
  final String userId; // musteri (danisan) id
  final String salonId;
  const MusteriGrupDersleri(
      {Key? key, required this.userId, required this.salonId})
      : super(key: key);

  @override
  State<MusteriGrupDersleri> createState() => _MusteriGrupDersleriState();
}

class _MusteriGrupDersleriState extends State<MusteriGrupDersleri> {
  bool _yukleniyor = true;
  String? _hata;
  List<Map<String, dynamic>> _dersler = [];
  final Set<int> _islemde = {};

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
    final gecmis = d['gecmis'] == true;
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

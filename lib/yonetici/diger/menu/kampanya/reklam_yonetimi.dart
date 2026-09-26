import 'package:flutter/material.dart';
import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/yonetici/diger/menu/kampanya/reklam_ekle_sihirbaz.dart';
import 'package:randevu_sistem/yonetici/diger/menu/kampanya/reklam_raporu.dart';

/// Reklam Yönetimi (Kampanya) liste ekranı — web paritesi giriş noktası.
class ReklamYonetimi extends StatefulWidget {
  final dynamic isletmebilgi;
  const ReklamYonetimi({Key? key, required this.isletmebilgi}) : super(key: key);

  @override
  State<ReklamYonetimi> createState() => _ReklamYonetimiState();
}

class _ReklamYonetimiState extends State<ReklamYonetimi> {
  static const Color _mor = Color(0xFF7B2FB8);

  String? _salonId;
  bool _yukleniyor = true;
  List<Map<String, dynamic>> _kampanyalar = [];

  static const Map<String, String> _kanalAdi = {
    '1': 'Arama',
    '2': 'SMS',
    '3': 'Bildirim',
    '4': 'Bilgilendirme',
  };

  @override
  void initState() {
    super.initState();
    _baslat();
  }

  Future<void> _baslat() async {
    _salonId ??= await secilisalonid();
    await _yukle();
  }

  Future<void> _yukle() async {
    if (mounted) setState(() => _yukleniyor = true);
    if (_salonId != null) {
      final res = await kampanyaListesi(_salonId!);
      if (res != null && res['data'] is List) {
        _kampanyalar = (res['data'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    }
    if (mounted) setState(() => _yukleniyor = false);
  }

  int _katilimciSayisi(Map<String, dynamic> k) {
    final v = k['kampanya_katilimcilari'];
    if (v is List) return v.length;
    return 0;
  }

  Future<void> _sihirbazAc({dynamic kampanyaId, String? ad}) async {
    final sonuc = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReklamEkleSihirbaz(
          isletmebilgi: widget.isletmebilgi,
          kampanyaId: kampanyaId,
          kampanyaAdi: ad,
        ),
      ),
    );
    if (sonuc == true) _yukle();
  }

  Future<void> _sil(Map<String, dynamic> k) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reklamı Sil'),
        content: Text('"${k['paket_isim'] ?? 'Kampanya'}" reklamını silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sil', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (onay == true) {
      final ok = await kampanyaPasifYap(k['id']);
      if (ok) {
        _yukle();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Silinemedi'), backgroundColor: Colors.red));
      }
    }
  }

  void _raporAc(Map<String, dynamic> k) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReklamRaporu(
          isletmebilgi: widget.isletmebilgi,
          kampanyaId: k['id'],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(backgroundColor: _mor, title: const Text('Reklam Yönetimi')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _mor,
        onPressed: () => _sihirbazAc(),
        icon: const Icon(Icons.add),
        label: const Text('Yeni Reklam'),
      ),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _yukle,
              child: _kampanyalar.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 120),
                        Icon(Icons.campaign_outlined, size: 64, color: Colors.black26),
                        SizedBox(height: 12),
                        Center(child: Text('Henüz reklam oluşturulmadı', style: TextStyle(color: Colors.black45))),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _kampanyalar.length,
                      itemBuilder: (_, i) => _kart(_kampanyalar[i]),
                    ),
            ),
    );
  }

  Widget _kart(Map<String, dynamic> k) {
    final kanal = _kanalAdi['${k['gorev_turu']}'] ?? '';
    final ad = (k['paket_isim'] ?? k['hizmet_adi'] ?? 'Kampanya').toString();
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _raporAc(k),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: _mor.withOpacity(0.12),
                child: const Icon(Icons.campaign, color: _mor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ad, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _rozet(kanal, Colors.indigo),
                        const SizedBox(width: 6),
                        _rozet('${_katilimciSayisi(k)} katılımcı', Colors.teal),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.orange),
                tooltip: 'Düzenle',
                onPressed: () => _sihirbazAc(kampanyaId: k['id'], ad: ad),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                tooltip: 'Sil',
                onPressed: () => _sil(k),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rozet(String metin, Color renk) {
    if (metin.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: renk.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(metin, style: TextStyle(color: renk, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

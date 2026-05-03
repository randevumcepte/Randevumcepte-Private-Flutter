import 'package:flutter/material.dart';
import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Models/musteri_danisanlar.dart';
import 'package:randevu_sistem/musteripaneli/anasayfa/odullerim.dart';

/// Müşterinin salon bazlı puan merdiveni — kazanılabilecek puan ödülleri.
class PuanOdullerimPage extends StatefulWidget {
  final MusteriDanisan md;
  final String? salonId;

  const PuanOdullerimPage({Key? key, required this.md, this.salonId})
      : super(key: key);

  @override
  State<PuanOdullerimPage> createState() => _PuanOdullerimPageState();
}

class _PuanOdullerimPageState extends State<PuanOdullerimPage> {
  bool _isLoading = true;
  String? _error;

  bool _bos = false;
  Map<String, dynamic>? _salon;
  double _puanBakiyesi = 0;
  List<Map<String, dynamic>> _odulSeviyeleri = [];
  List<Map<String, dynamic>> _puanKayitlari = [];
  String? _aktifSalonId;

  @override
  void initState() {
    super.initState();
    _aktifSalonId = widget.salonId;
    _yukle();
  }

  Future<void> _yukle({String? salonIdOverride}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final res = await carkPuanOdullerim(
        widget.md.id.toString(),
        salonId: salonIdOverride ?? _aktifSalonId,
      );
      if (res['success'] != true) {
        setState(() {
          _isLoading = false;
          _error = res['message']?.toString() ?? 'Veri alınamadı.';
        });
        return;
      }
      final bos = res['bos'] == true;
      setState(() {
        _bos = bos;
        if (!bos) {
          _salon = Map<String, dynamic>.from(res['salon'] as Map? ?? {});
          _puanBakiyesi = double.tryParse((res['puanBakiyesi'] ?? 0).toString()) ?? 0;
          _odulSeviyeleri = (res['odulSeviyeleri'] as List? ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          _puanKayitlari = (res['puanKayitlari'] as List? ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          _aktifSalonId = (_salon?['id'] ?? _aktifSalonId).toString();
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Bağlantı hatası: $e';
      });
    }
  }

  Future<void> _talepEt(Map<String, dynamic> odul) async {
    final puanEsigi = (odul['puan_esigi'] ?? 0).toString();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ödülü Talep Et'),
        content: Text(
          'Bu ödülü talep etmek istediğinize emin misiniz?\n'
          '$puanEsigi puan düşecek ve kupon kodunuz oluşacak.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
            child: const Text('Talep Et'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      final res = await carkPuanOdulTalep(
        widget.md.id.toString(),
        _aktifSalonId ?? '',
        (odul['id'] is int) ? odul['id'] as int : int.tryParse(odul['id'].toString()) ?? 0,
      );
      if (res['success'] == true) {
        if (!mounted) return;
        await showDialog(
          context: context,
          builder: (ctx) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(20),
            child: _PuanTalepKart(
              kod: (res['kod'] ?? '').toString(),
              baslik: (res['baslik'] ?? '').toString(),
              onClose: () => Navigator.pop(ctx),
              onMyRewards: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => OdullerimPage(md: widget.md)),
                );
              },
            ),
          ),
        );
        await _yukle();
      } else {
        _snack(res['message']?.toString() ?? 'İşlem başarısız');
      }
    } catch (e) {
      _snack('Bağlantı hatası');
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FF),
      appBar: AppBar(
        title: const Text('⭐ Puan Ödüllerim', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF3B82F6),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _bos
                  ? _buildEmpty()
                  : RefreshIndicator(
                      color: const Color(0xFF3B82F6),
                      onRefresh: _yukle,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildHero(),
                          if (_puanKayitlari.length > 1) ...[
                            const SizedBox(height: 12),
                            _buildSalonSecici(),
                          ],
                          const SizedBox(height: 16),
                          if (_odulSeviyeleri.isEmpty)
                            _buildSeviyeBos()
                          else
                            ..._odulSeviyeleri.map(_buildOdulKart).toList(),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(_error ?? '', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: () => _yukle(), child: const Text('Tekrar Dene')),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎖️', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            const Text(
              'Henüz puanınız bulunmuyor.\nÇarkıfelekten "Puan" kazanarak biriktirebilir,\nbiriktiren puanlarla özel ödüller alabilirsiniz.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF636E72), height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero() {
    final salonAdi = (_salon?['salon_adi'] ?? '').toString();
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF3B82F6), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '⭐ Puan Ödüllerim',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(salonAdi, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_puanBakiyesi.toInt()}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 56,
                  fontWeight: FontWeight.w900,
                  height: 1,
                  letterSpacing: -2,
                ),
              ),
              const SizedBox(width: 12),
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'Toplam Puan',
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSalonSecici() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (ctx, i) {
          final pk = _puanKayitlari[i];
          final id = pk['salon_id'].toString();
          final aktif = id == _aktifSalonId;
          return InkWell(
            borderRadius: BorderRadius.circular(50),
            onTap: aktif ? null : () => _yukle(salonIdOverride: id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: aktif ? const Color(0xFF6C5CE7) : Colors.white,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: aktif ? const Color(0xFF6C5CE7) : const Color(0xFFE5E7EB)),
              ),
              child: Text(
                '${pk['salon_adi']} (${(pk['puan'] ?? 0).toString().split('.').first})',
                style: TextStyle(
                  color: aktif ? Colors.white : const Color(0xFF6B7280),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: _puanKayitlari.length,
      ),
    );
  }

  Widget _buildSeviyeBos() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Text('🎖️', style: TextStyle(fontSize: 56)),
          SizedBox(height: 8),
          Text(
            'Bu salonda henüz tanımlı puan ödülü yok.\nSalon yakında ödülleri tanıtacak.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Color(0xFF636E72), height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildOdulKart(Map<String, dynamic> o) {
    final esik = (o['puan_esigi'] is int)
        ? o['puan_esigi'] as int
        : int.tryParse(o['puan_esigi'].toString()) ?? 0;
    final talepEdilebilir = _puanBakiyesi >= esik;
    final yuzde = ((_puanBakiyesi / (esik <= 0 ? 1 : esik)) * 100).clamp(0, 100).toDouble();
    final eksik = (esik - _puanBakiyesi).clamp(0, double.infinity);
    final tip = (o['tip'] ?? '').toString();
    final tipLabel = {
      'hizmet_indirimi': 'Hizmet İndirimi',
      'urun_indirimi':   'Ürün İndirimi',
      'hediye':          'Hediye',
    }[tip] ?? 'Ödül';
    final tipBg = {
      'hizmet_indirimi': const Color(0xFFDBEAFE),
      'urun_indirimi':   const Color(0xFFFCE7F3),
      'hediye':          const Color(0xFFFEF3C7),
    }[tip] ?? const Color(0xFFE5E7EB);
    final tipFg = {
      'hizmet_indirimi': const Color(0xFF1E40AF),
      'urun_indirimi':   const Color(0xFF9F1239),
      'hediye':          const Color(0xFF92400E),
    }[tip] ?? const Color(0xFF374151);
    final degerLbl = (o['deger'] != null && (tip == 'hizmet_indirimi' || tip == 'urun_indirimi'))
        ? '%${double.tryParse(o['deger'].toString())?.toInt() ?? 0}'
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: talepEdilebilir
            ? const Color(0xFFECFDF5).withOpacity(0.6)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: talepEdilebilir ? const Color(0xFF10B981) : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (o['baslik'] ?? '').toString(),
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ((o['aciklama'] ?? '').toString().isEmpty ? '—' : o['aciklama'].toString()),
                      style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), height: 1.4),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: tipBg,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            tipLabel,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: tipFg),
                          ),
                        ),
                        if (degerLbl.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text(
                            degerLbl,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFDE047), Color(0xFFF59E0B)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      '$esik',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF78350F), height: 1),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'PUAN',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF78350F), letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: yuzde / 100,
              minHeight: 8,
              backgroundColor: const Color(0xFFF3F4F6),
              valueColor: AlwaysStoppedAnimation<Color>(
                talepEdilebilir ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_puanBakiyesi.toInt()} / $esik',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
              Text(
                '${yuzde.toInt()}%',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (talepEdilebilir)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.card_giftcard, size: 18),
                label: const Text('Ödülü Talep Et'),
                onPressed: () => _talepEt(o),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            )
          else
            Text(
              '🔒 ${eksik.toInt()} puan daha gerekiyor',
              style: const TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w700, fontSize: 13),
            ),
        ],
      ),
    );
  }
}

class _PuanTalepKart extends StatelessWidget {
  final String kod;
  final String baslik;
  final VoidCallback onClose;
  final VoidCallback onMyRewards;

  const _PuanTalepKart({
    required this.kod,
    required this.baslik,
    required this.onClose,
    required this.onMyRewards,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🎉', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 6),
          const Text(
            'Ödülünüz Hazır!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 6),
          Text(
            baslik,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 16),
          const Text(
            'Kupon Kodunuz',
            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
            ),
            child: Text(
              kod,
              style: const TextStyle(
                color: Color(0xFF92400E),
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Bu kodu 60 gün içinde salonda ibraz edin.',
            style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onMyRewards,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF6C5CE7),
                    side: const BorderSide(color: Color(0xFF6C5CE7)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                  ),
                  child: const Text('Kuponlarım'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: onClose,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C5CE7),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                  ),
                  child: const Text('Tamam'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

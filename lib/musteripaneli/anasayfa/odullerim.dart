import 'package:flutter/material.dart';
import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Models/musteri_danisanlar.dart';
import 'package:randevu_sistem/musteripaneli/anasayfa/gecerli_sube_rozeti.dart';

/// Müşterinin kazandığı kuponları listeler (çark + puan ödülü).
class OdullerimPage extends StatefulWidget {
  final MusteriDanisan md;

  const OdullerimPage({Key? key, required this.md}) : super(key: key);

  @override
  State<OdullerimPage> createState() => _OdullerimPageState();
}

class _OdullerimPageState extends State<OdullerimPage> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _odullerim = [];

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final res = await carkOdullerim(widget.md.id.toString());
      if (res['success'] == true) {
        final list = (res['data'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        setState(() {
          _odullerim = list;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _error = res['message']?.toString() ?? 'Veri alınamadı.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Bağlantı hatası: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FF),
      appBar: AppBar(
        title: const Text('🎁 Kuponlarım', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF6C5CE7),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _yukle,
                  color: const Color(0xFF6C5CE7),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildHero(),
                      const SizedBox(height: 14),
                      if (_odullerim.isEmpty)
                        _buildEmpty()
                      else
                        ..._odullerim.map(_buildKart).toList(),
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
            ElevatedButton(onPressed: _yukle, child: const Text('Tekrar Dene')),
          ],
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFDCB6E), Color(0xFFFD79A8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFD79A8).withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🎁 Kazandığım Ödüller',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 6),
          Text(
            'Çarkıfelekten ve puan ödüllerinden kazandığınız kuponlar burada listelenir. Salonda randevu aldığınızda kupon kodunuzu personele söyleyin.',
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Text('🎡', style: TextStyle(fontSize: 56)),
          SizedBox(height: 8),
          Text(
            'Henüz kazanılmış bir ödülünüz yok.\nOnaylanmış randevularınız üzerinden çarkı çevirebilirsiniz.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Color(0xFF636E72), height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildKart(Map<String, dynamic> o) {
    final kullanildi = (o['kullanildi'] ?? 0) == 1;
    final kod = (o['kod'] ?? '').toString();
    final baslik = (o['baslik'] ?? 'Ödül').toString();
    final salonAdi = (o['salon_adi'] ?? 'Salon').toString();
    final gecerlilik = (o['gecerlilik_tarihi'] ?? '').toString();
    final kullanimTarihi = (o['kullanim_tarihi'] ?? '').toString();
    final gecmis = !kullanildi && _gecmisMi(gecerlilik);
    final pasif = kullanildi || gecmis;

    String etiket;
    Color etiketBg;
    Color etiketFg;
    if (kullanildi) {
      etiket = 'Kullanıldı';
      etiketBg = const Color(0xFFFEE2E2);
      etiketFg = const Color(0xFF991B1B);
    } else if (gecmis) {
      etiket = 'Süresi Doldu';
      etiketBg = const Color(0xFFFEE2E2);
      etiketFg = const Color(0xFF991B1B);
    } else {
      etiket = 'Geçerli';
      etiketBg = const Color(0xFFD1FAE5);
      etiketFg = const Color(0xFF065F46);
    }

    return Opacity(
      opacity: pasif ? 0.6 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: pasif ? Colors.grey.shade300 : const Color(0xFFE5E7EB),
            width: 2,
            style: BorderStyle.solid,
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    baslik,
                    style: const TextStyle(
                      color: Color(0xFF6C5CE7),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: etiketBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    etiket,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: etiketFg,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(salonAdi, style: const TextStyle(color: Color(0xFF636E72), fontSize: 13)),
            GecerliSubeRozeti.fromJson(o, renk: const Color(0xFF6C5CE7)),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
              ),
              child: Center(
                child: Text(
                  kod,
                  style: const TextStyle(
                    color: Color(0xFF92400E),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                _altYazi(kullanildi, gecmis, gecerlilik, kullanimTarihi),
                style: const TextStyle(fontSize: 12, color: Color(0xFF636E72)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _gecmisMi(String tarihStr) {
    if (tarihStr.isEmpty) return false;
    final t = DateTime.tryParse(tarihStr);
    if (t == null) return false;
    final today = DateTime.now();
    return t.isBefore(DateTime(today.year, today.month, today.day));
  }

  String _altYazi(bool kullanildi, bool gecmis, String gecerlilik, String kullanim) {
    if (kullanildi && kullanim.isNotEmpty) {
      final d = DateTime.tryParse(kullanim);
      if (d != null) return '${_format(d)} tarihinde kullanıldı';
    }
    if (gecerlilik.isNotEmpty) {
      final d = DateTime.tryParse(gecerlilik);
      if (d != null) {
        return gecmis ? 'Süresi doldu (${_format(d)})' : 'Son kullanım: ${_format(d)}';
      }
    }
    return 'Süresiz';
  }

  String _format(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd.$mm.${d.year}';
  }
}

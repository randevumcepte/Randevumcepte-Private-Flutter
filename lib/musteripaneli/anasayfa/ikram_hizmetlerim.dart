import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Models/musteri_danisanlar.dart';

/// Müşteri: İkram Hizmetlerim (Starbucks "ikram içecek" mantığı).
/// Üstte toplam kalan ikram; altta hizmet hizmet ücretli alım / kazanılan /
/// kullanılan / kalan ve sonraki ikrama ilerleme. İkramı ne zaman kullanacağına
/// müşteri karar verir (ödeme sırasında salona söyler).
/// Veri: /api/v1/musteri/ikram-hizmetleri (tahsilat ekranıyla aynı sayım).
class IkramHizmetlerimPage extends StatefulWidget {
  final MusteriDanisan md;
  final String? salonId;
  const IkramHizmetlerimPage({Key? key, required this.md, this.salonId}) : super(key: key);

  @override
  State<IkramHizmetlerimPage> createState() => _IkramHizmetlerimPageState();
}

class _IkramHizmetlerimPageState extends State<IkramHizmetlerimPage> {
  static const _mor = Color(0xFF7C3AED);
  bool _yukleniyor = true;
  int _toplamHak = 0;
  List<Map<String, dynamic>> _kartlar = [];

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    final sid = widget.salonId ?? '';
    final r = sid.isEmpty ? null : await musteriIkramHizmetleri(sid, widget.md.id.toString());
    if (!mounted) return;
    setState(() {
      _yukleniyor = false;
      if (r != null && r['basarili'] == true) {
        _toplamHak = (r['toplam_hak'] as num?)?.toInt() ?? 0;
        _kartlar = ((r['kartlar'] as List?) ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    });
  }

  String _tarih(dynamic t) {
    final d = DateTime.tryParse((t ?? '').toString());
    if (d == null) return '';
    String iki(int x) => x.toString().padLeft(2, '0');
    return '${iki(d.day)}.${iki(d.month)}.${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5FF),
      appBar: AppBar(
        title: const Text('İkram Hizmetlerim', style: TextStyle(color: Colors.white)),
        backgroundColor: _mor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              color: _mor,
              onRefresh: _yukle,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  _hero(),
                  const SizedBox(height: 14),
                  _bilgi(),
                  const SizedBox(height: 4),
                  if (_kartlar.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(30),
                      child: Text('Bu salonda şu an ikram hizmet kampanyası yok.',
                          textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
                    )
                  else
                    ..._kartlar.map(_hizmetKart),
                ],
              ),
            ),
    );
  }

  Widget _hero() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4C1D95), Color(0xFF7C3AED), Color(0xFF10B981)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: _mor.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('İkram bakiyesi', style: TextStyle(color: Color(0xFFFDE68A), fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.card_giftcard_rounded, size: 38, color: Color(0xFFFDE68A)),
              const SizedBox(width: 8),
              Text('$_toplamHak',
                  style: const TextStyle(color: Colors.white, fontSize: 52, fontWeight: FontWeight.w800, height: 1)),
            ]),
            const SizedBox(height: 6),
            Text(_toplamHak > 0 ? '$_toplamHak ikram hizmetiniz var' : 'Henüz kullanılabilir ikramınız yok',
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          ]),
        ),
      ]),
    );
  }

  Widget _bilgi() {
    Widget satir(IconData ikon, String yazi) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: _mor.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(ikon, size: 18, color: _mor),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(yazi, style: const TextStyle(fontSize: 13, color: Color(0xFF374151), height: 1.4))),
          ]),
        );
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        satir(Icons.event_available_rounded, 'Kampanyalı hizmetleri ücretli aldıkça ikram kazanırsınız; gelinen her randevu sayılır.'),
        satir(Icons.card_giftcard_rounded, 'Kazandığınız ikramı dilediğiniz bir seansınızda kullanırsınız; ödeme sırasında salona söylemeniz yeterli.'),
        satir(Icons.savings_rounded, 'İstemezseniz ikramınız saklı kalır; kullanım süresi varsa o tarihe kadar dilediğiniz seansta kullanabilirsiniz.'),
      ]),
    );
  }

  Widget _ikramSatir(Map<String, dynamic> ik) {
    final durum = (ik['durum'] ?? '').toString();
    final tutar = double.tryParse((ik['tutar'] ?? 0).toString()) ?? 0;
    final bitis = (ik['bitis'] ?? '').toString();
    late final String aciklama;
    late final String rozet;
    late final Color renk;
    late final IconData ikon;
    if (durum == 'kullanildi') {
      aciklama = '${_tarih(ik['kullanim_tarihi'])} tarihinde kullanıldı'
          '${tutar > 0 ? ' · ${tutar.toStringAsFixed(tutar == tutar.roundToDouble() ? 0 : 2)} ₺ kazanç' : ''}';
      rozet = 'Kullanıldı';
      renk = const Color(0xFF059669);
      ikon = Icons.check_circle_rounded;
    } else if (durum == 'gecerli') {
      aciklama = bitis.isNotEmpty ? '${_tarih(bitis)} tarihine kadar kullanılabilir' : 'Süresiz, dilediğiniz zaman kullanılabilir';
      rozet = 'Kullanılabilir';
      renk = _mor;
      ikon = Icons.card_giftcard_rounded;
    } else {
      aciklama = '${_tarih(bitis)} tarihinde süresi doldu';
      rozet = 'Süresi doldu';
      renk = const Color(0xFFDC2626);
      ikon = Icons.timer_off_rounded;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Icon(ikon, size: 18, color: renk),
        const SizedBox(width: 8),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${_tarih(ik['kazanma'])} tarihinde kazanıldı',
                style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
            Text(aciklama, style: const TextStyle(fontSize: 12.5, color: Color(0xFF374151))),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: renk.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Text(rozet, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: renk)),
        ),
      ]),
    );
  }

  Widget _hizmetKart(Map<String, dynamic> k) {
    int n(String a) => int.tryParse((k[a] ?? 0).toString()) ?? 0;
    final gereken = math.max(1, n('gereken_adet'));
    final ilerleme = n('ilerleme');
    final hak = n('hak');
    final aktif = n('aktif') == 1;
    // Ikram gecmisi: kazanilan her ikram (en yeni ustte) — kullanildi / kullanilabilir / suresi doldu.
    // Eski backend 'ikramlar' gondermezse bolum gizli kalir.
    final ikramlar = ((k['ikramlar'] as List?) ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    final gecerlilik = (k['gecerlilik'] ?? '').toString();
    final gecerliler = ((k['gecerli_ikramlar'] as List?) ?? const []).map((e) => e.toString()).toList();
    final dolan = n('suresi_dolan');

    Widget istat(String sayi, String etiket, {bool vurgu = false}) => Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: vurgu ? const Color(0xFFF5F3FF) : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(children: [
              Text(sayi,
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: vurgu ? _mor : const Color(0xFF111827))),
              const SizedBox(height: 2),
              Text(etiket, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10.5, color: Color(0xFF6B7280))),
            ]),
          ),
        );

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          // Sonraki ikrama ilerleme halkasi (Starbucks 0/15 gibi)
          SizedBox(
            width: 54,
            height: 54,
            child: Stack(alignment: Alignment.center, children: [
              SizedBox(
                width: 54,
                height: 54,
                child: CircularProgressIndicator(
                  value: aktif ? ilerleme / gereken : 0,
                  strokeWidth: 5,
                  backgroundColor: _mor.withOpacity(0.12),
                  valueColor: const AlwaysStoppedAnimation(_mor),
                ),
              ),
              Text('$ilerleme/$gereken', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
            ]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text((k['hizmet_adi'] ?? '').toString(),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
              const SizedBox(height: 2),
              Text('$gereken alana ${n('ucretsiz_adet')} ikram${gecerlilik.isNotEmpty ? ' · $gecerlilik geçerli' : ''}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _mor)),
            ]),
          ),
          if (hak > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.card_giftcard_rounded, size: 16, color: Color(0xFF047857)),
                const SizedBox(width: 4),
                Text('$hak', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF047857))),
              ]),
            ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          istat('${n('ucretli')}', 'Ücretli\nalım'),
          istat('${n('kazanilan')}', 'Kazanılan\nikram'),
          istat('${n('kullanilan')}', 'Kullanılan\nikram'),
          istat('$hak', 'Kalan\nikram', vurgu: true),
        ]),
        // Gecerliligini kaybedecek ikramlar (Starbucks "Gecerliligini Kaybedecek Yildizlar")
        if (gecerliler.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(10)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Icon(Icons.hourglass_bottom_rounded, size: 15, color: Color(0xFF92400E)),
                SizedBox(width: 4),
                Text('Son kullanma tarihleri',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF92400E))),
              ]),
              const SizedBox(height: 3),
              ...gecerliler.map((t) => Text('• 1 ikram · ${_tarih(t)} tarihine kadar',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF92400E)))),
            ]),
          ),
        ],
        if (dolan > 0) ...[
          const SizedBox(height: 6),
          Text('$dolan ikramın kullanım süresi doldu.', style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626))),
        ],
        const SizedBox(height: 10),
        Text(
          aktif
              ? 'Sonraki ikrama ${gereken - ilerleme} ücretli alım kaldı.'
              : 'Bu ikram kampanyası sona erdi${hak > 0 ? '; kalan ikramınızı kullanabilirsiniz.' : '.'}',
          style: const TextStyle(fontSize: 12.5, color: Color(0xFF6B7280)),
        ),
        if (ikramlar.isNotEmpty) ...[
          const Divider(height: 22),
          const Text('İkram geçmişi',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF374151))),
          const SizedBox(height: 4),
          ...ikramlar.map(_ikramSatir),
        ],
      ]),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:randevu_sistem/services/notification_service.dart';
import 'package:randevu_sistem/yonetici/diger/menu/ayarlar/personeller/hakedislerim.dart';

import 'profil_api.dart';
import 'profil_durum.dart';
import 'profil_tema.dart';

int _i(dynamic v) => v is int ? v : (v is num ? v.toInt() : int.tryParse('${v ?? ''}') ?? 0);
double _d(dynamic v) => v is num ? v.toDouble() : double.tryParse('${v ?? ''}') ?? 0;

/// Ortak: yükle → liste çiz → aşağı çekince yenile
abstract class _ListeDurum<T extends StatefulWidget> extends State<T> {
  bool yukleniyor = true;
  String? hata;
  Map<String, dynamic> veri = {};

  Future<Map<String, dynamic>> getir();

  @override
  void initState() {
    super.initState();
    yukle();
  }

  Future<void> yukle() async {
    final r = await getir();
    if (!mounted) return;
    setState(() {
      yukleniyor = false;
      if (ProfilApi.ok(r)) {
        veri = r;
        hata = null;
      } else {
        hata = (r['hata'] ?? 'Yüklenemedi.').toString();
      }
    });
  }

  Widget kaydirma(List<Widget> cocuklar) {
    if (yukleniyor) return const Center(child: CircularProgressIndicator(color: PT.mor));
    if (hata != null) {
      return ListView(children: [PTBos(Icons.cloud_off_rounded, hata!)]);
    }
    return RefreshIndicator(
      color: PT.mor,
      onRefresh: yukle,
      child: ListView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
        children: cocuklar,
      ),
    );
  }
}

Widget _yildizlar(double puan, {double boyut = 16}) => Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final dolu = puan >= i + 0.75;
        final yarim = !dolu && puan >= i + 0.25;
        return Icon(dolu ? Icons.star_rounded : yarim ? Icons.star_half_rounded : Icons.star_outline_rounded,
            size: boyut, color: const Color(0xFFF59E0B));
      }),
    );

// ═══════════════════════════════════════════════ Yorumlar

class YorumlarSayfasi extends StatefulWidget {
  final String sube;
  final bool yonetici;
  const YorumlarSayfasi({super.key, required this.sube, required this.yonetici});
  @override
  State<YorumlarSayfasi> createState() => _YorumlarSayfasiState();
}

class _YorumlarSayfasiState extends _ListeDurum<YorumlarSayfasi> {
  @override
  Future<Map<String, dynamic>> getir() => ProfilApi.get('yorumlar', widget.sube, {'tum': widget.yonetici ? '1' : '0'});

  @override
  Widget build(BuildContext context) {
    final l = (veri['yorumlar'] as List? ?? []).cast<Map>();
    final ort = l.isEmpty ? 0.0 : l.map((e) => _d(e['puan'])).reduce((a, b) => a + b) / l.length;
    return PTAltSayfa(
      baslik: widget.yonetici ? 'Müşteri Yorumları' : 'Müşteri Yorumlarım',
      govde: kaydirma([
        if (l.isEmpty)
          const PTBos(Icons.reviews_rounded,
              'Henüz değerlendirme yok.\nRandevudan sonra gönderilen memnuniyet anketleri cevaplandıkça burada görünür.')
        else ...[
          PTKart(
            child: Row(children: [
              Text(ort.toStringAsFixed(1).replaceAll('.', ','),
                  style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: PT.koyu, letterSpacing: -1)),
              const SizedBox(width: 14),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _yildizlar(ort, boyut: 22),
                const SizedBox(height: 4),
                Text('Son ${l.length} değerlendirme', style: const TextStyle(fontSize: 13, color: PT.gri)),
              ]),
            ]),
          ),
          const SizedBox(height: 12),
          ...l.map((y) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: PTKart(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(
                        child: Text(y['musteri'].toString(),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: PT.koyu)),
                      ),
                      _yildizlar(_d(y['puan'])),
                    ]),
                    const SizedBox(height: 2),
                    Text(
                        [trTarih(y['tarih']?.toString()), if ((y['personel'] ?? '').toString().isNotEmpty) y['personel']]
                            .join(' · '),
                        style: const TextStyle(fontSize: 12, color: PT.gri)),
                    if ((y['yorum'] ?? '').toString().trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('“${y['yorum'].toString().trim()}”',
                          style: const TextStyle(fontSize: 14, height: 1.4, color: PT.koyu, fontStyle: FontStyle.italic)),
                    ],
                  ]),
                ),
              )),
        ],
      ]),
    );
  }
}

// ═══════════════════════════════════════════════ Çalışma saatleri

class CalismaSaatleriSayfasi extends StatefulWidget {
  final String sube;
  const CalismaSaatleriSayfasi({super.key, required this.sube});
  @override
  State<CalismaSaatleriSayfasi> createState() => _CalismaSaatleriSayfasiState();
}

class _CalismaSaatleriSayfasiState extends _ListeDurum<CalismaSaatleriSayfasi> {
  @override
  Future<Map<String, dynamic>> getir() => ProfilApi.get('calisma-saatleri', widget.sube);

  @override
  Widget build(BuildContext context) {
    final gunler = (veri['gunler'] as List? ?? []).cast<Map>();
    final izinler = (veri['yaklasan_izinler'] as List? ?? []).cast<Map>();
    return PTAltSayfa(
      baslik: 'Çalışma Saatlerim',
      govde: kaydirma([
        if (veri['kayitli'] == false)
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text('Çalışma saatleriniz henüz girilmemiş. Yöneticiniz Personeller ekranından ekleyebilir.',
                style: TextStyle(fontSize: 13, color: PT.gri)),
          ),
        PTKart(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Column(
            children: [
              for (var i = 0; i < gunler.length; i++) ...[
                if (i > 0) const Divider(height: 1, color: PT.cizgi),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  child: Row(children: [
                    if (gunler[i]['bugun'] == true)
                      Container(width: 6, height: 6, margin: const EdgeInsets.only(right: 8), decoration: const BoxDecoration(color: PT.mor, shape: BoxShape.circle)),
                    Expanded(
                      child: Text(gunler[i]['gun'].toString(),
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: gunler[i]['bugun'] == true ? FontWeight.w800 : FontWeight.w600,
                              color: gunler[i]['bugun'] == true ? PT.mor : PT.koyu)),
                    ),
                    gunler[i]['calisiyor'] == true
                        ? Text('${gunler[i]['baslangic']} – ${gunler[i]['bitis']}',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: PT.koyu))
                        : Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
                            child: const Text('İzinli gün', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: PT.gri)),
                          ),
                  ]),
                ),
              ],
            ],
          ),
        ),
        if (izinler.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text('Yaklaşan izinlerim', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: PT.gri)),
          ),
          ...izinler.map((z) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: PTKart(
                  child: Row(children: [
                    PTIkon(Icons.beach_access_rounded, boyut: 42),
                    const SizedBox(width: 12),
                    Text(
                        z['baslangic'] == z['bitis']
                            ? trTarih(z['baslangic']?.toString())
                            : '${trTarih(z['baslangic']?.toString())} – ${trTarih(z['bitis']?.toString())}',
                        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: PT.koyu)),
                  ]),
                ),
              )),
        ],
      ]),
    );
  }
}

// ═══════════════════════════════════════════════ İzinler

const Map<String, String> _izinTurleri = {'yillik': 'Yıllık izin', 'mazeret': 'Mazeret izni', 'rapor': 'Sağlık raporu', 'ucretsiz': 'Ücretsiz izin'};

Widget _izinDurumRozet(String d) {
  final m = {
    'bekliyor': ['Onay bekliyor', const Color(0xFFEA580C)],
    'onaylandi': ['Onaylandı', PT.yesil],
    'reddedildi': ['Reddedildi', const Color(0xFFDC2626)],
    'iptal': ['İptal edildi', const Color(0xFF64748B)],
  }[d] ?? [d, PT.gri];
  final renk = m[1] as Color;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(color: renk.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
    child: Text(m[0] as String, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: renk)),
  );
}

String _izinAralik(Map z) => z['baslangic'] == z['bitis']
    ? trTarih(z['baslangic']?.toString())
    : '${trTarih(z['baslangic']?.toString())} – ${trTarih(z['bitis']?.toString())}';

class IzinlerSayfasi extends StatefulWidget {
  final String sube;
  const IzinlerSayfasi({super.key, required this.sube});
  @override
  State<IzinlerSayfasi> createState() => _IzinlerSayfasiState();
}

class _IzinlerSayfasiState extends _ListeDurum<IzinlerSayfasi> {
  @override
  Future<Map<String, dynamic>> getir() => ProfilApi.get('izinler', widget.sube);

  Future<void> _talepAc() async {
    final sonuc = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _IzinFormu(sube: widget.sube),
    );
    if (sonuc == true) {
      if (mounted) ptMesaj(context, 'İzin talebiniz yöneticinize gönderildi.');
      yukle();
    }
  }

  Future<void> _iptal(Map z) async {
    final evet = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('İzni iptal et'),
        content: Text('${_izinAralik(z)} izni iptal edilsin mi?'
            '${z['durum'] == 'onaylandi' ? '\nTakvimde kapatılan saatler yeniden açılır.' : ''}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Vazgeç')),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600), onPressed: () => Navigator.pop(c, true), child: const Text('İptal et')),
        ],
      ),
    );
    if (evet != true) return;
    final r = await ProfilApi.post('izin-iptal', widget.sube, {'id': z['id']});
    if (!mounted) return;
    ptMesaj(context, ProfilApi.ok(r) ? 'İzin iptal edildi.' : (r['hata'] ?? 'İptal edilemedi.').toString(), hata: !ProfilApi.ok(r));
    yukle();
  }

  @override
  Widget build(BuildContext context) {
    final l = (veri['izinler'] as List? ?? []).cast<Map>();
    final bugun = DateTime.now().toIso8601String().substring(0, 10);
    return PTAltSayfa(
      baslik: 'İzinlerim',
      altDugme: ptAnaDugme('İzin İste', Icons.add_rounded, _talepAc),
      govde: kaydirma([
        if (l.isEmpty)
          const PTBos(Icons.beach_access_rounded, 'Henüz izin talebiniz yok.\nAşağıdaki “İzin İste” ile gün seçip yöneticinize gönderebilirsiniz.')
        else
          ...l.map((z) {
            final iptalEdilebilir = z['durum'] == 'bekliyor' || (z['durum'] == 'onaylandi' && (z['bitis'] ?? '').toString().compareTo(bugun) >= 0);
            return Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: PTKart(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(
                      child: Text(_izinAralik(z), style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: PT.koyu)),
                    ),
                    _izinDurumRozet(z['durum'].toString()),
                  ]),
                  const SizedBox(height: 3),
                  Text('${_izinTurleri[z['tur']] ?? z['tur']} · ${_i(z['gun'])} gün',
                      style: const TextStyle(fontSize: 13, color: PT.gri)),
                  if ((z['aciklama'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(z['aciklama'].toString(), style: const TextStyle(fontSize: 13.5, color: PT.koyu)),
                  ],
                  if ((z['karar_notu'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text('Yönetici notu: ${z['karar_notu']}', style: const TextStyle(fontSize: 13, color: PT.gri, fontStyle: FontStyle.italic)),
                  ],
                  if (iptalEdilebilir)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => _iptal(z),
                        child: const Text('İptal et', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w700)),
                      ),
                    ),
                ]),
              ),
            );
          }),
      ]),
    );
  }
}

class _IzinFormu extends StatefulWidget {
  final String sube;
  const _IzinFormu({required this.sube});
  @override
  State<_IzinFormu> createState() => _IzinFormuState();
}

class _IzinFormuState extends State<_IzinFormu> {
  DateTimeRange? _aralik;
  String _tur = 'yillik';
  final _aciklama = TextEditingController();
  bool _gonderiliyor = false;

  String _ymd(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _tarihSec() async {
    final simdi = DateTime.now();
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(simdi.year, simdi.month, simdi.day),
      lastDate: simdi.add(const Duration(days: 365)),
      initialDateRange: _aralik,
      locale: const Locale('tr', 'TR'),
      helpText: 'İzin günlerini seçin',
      saveText: 'Tamam',
      builder: (c, w) => Theme(data: Theme.of(c).copyWith(colorScheme: Theme.of(c).colorScheme.copyWith(primary: PT.mor)), child: w!),
    );
    if (r != null) setState(() => _aralik = r);
  }

  Future<void> _gonder() async {
    if (_aralik == null) {
      ptMesaj(context, 'Önce izin günlerini seçin.', hata: true);
      return;
    }
    setState(() => _gonderiliyor = true);
    final r = await ProfilApi.post('izin-talep', widget.sube, {
      'baslangic': _ymd(_aralik!.start),
      'bitis': _ymd(_aralik!.end),
      'tur': _tur,
      'aciklama': _aciklama.text.trim(),
    });
    if (!mounted) return;
    setState(() => _gonderiliyor = false);
    if (ProfilApi.ok(r)) {
      Navigator.pop(context, true);
    } else {
      ptMesaj(context, (r['hata'] ?? 'Gönderilemedi.').toString(), hata: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gun = _aralik == null ? 0 : _aralik!.end.difference(_aralik!.start).inDays + 1;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('İzin İste', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: PT.koyu)),
            const SizedBox(height: 14),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _tarihSec,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: PT.lila.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(14)),
                child: Row(children: [
                  const Icon(Icons.date_range_rounded, color: PT.mor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _aralik == null
                          ? 'Gün seçin'
                          : '${trTarih(_ymd(_aralik!.start))} – ${trTarih(_ymd(_aralik!.end))}  ($gun gün)',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _aralik == null ? PT.gri : PT.koyu),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: PT.mor),
                ]),
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _izinTurleri.entries
                  .map((e) => ChoiceChip(
                        label: Text(e.value),
                        selected: _tur == e.key,
                        selectedColor: PT.mor,
                        labelStyle: TextStyle(fontWeight: FontWeight.w700, color: _tur == e.key ? Colors.white : PT.koyu),
                        onSelected: (_) => setState(() => _tur = e.key),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _aciklama,
              maxLines: 2,
              maxLength: 300,
              decoration: InputDecoration(
                hintText: 'Açıklama (isteğe bağlı)',
                filled: true,
                fillColor: PT.lila.withValues(alpha: 0.35),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 6),
            ptAnaDugme('Yöneticime Gönder', Icons.send_rounded, _gonder, yukleniyor: _gonderiliyor),
          ]),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════ Performans

class PerformansSayfasi extends StatelessWidget {
  final String sube;
  final Map<String, dynamic> ozet;
  final bool kazancGorunur;
  final dynamic isletmebilgi;
  final String personelId;
  final String personelAdi;
  const PerformansSayfasi(
      {super.key,
      required this.sube,
      required this.ozet,
      required this.kazancGorunur,
      required this.isletmebilgi,
      required this.personelId,
      required this.personelAdi});

  @override
  Widget build(BuildContext context) {
    final buAy = ozet['bu_ay'] is Map ? ozet['bu_ay'] as Map : const {};
    final hedef = ozet['hedef'] is Map ? ozet['hedef'] as Map : null;
    final yonetici = ozet['yonetici'] == true;
    const aylar = ['', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
    final ay = aylar[DateTime.now().month];
    Widget buyukKart(String etiket, String deger, IconData ikon, String alt) => PTKart(
          child: Row(children: [
            PTIkon(ikon),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(etiket, style: const TextStyle(fontSize: 13, color: PT.gri)),
                Text(deger, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: PT.koyu, letterSpacing: -0.5)),
                Text(alt, style: const TextStyle(fontSize: 12, color: PT.gri)),
              ]),
            ),
          ]),
        );
    return PTAltSayfa(
      baslik: 'Performansım',
      govde: ListView(padding: const EdgeInsets.fromLTRB(16, 6, 16, 28), children: [
        if (kazancGorunur) ...[
          buyukKart('$ay kazancım', tl(buAy['kazanc'] as num?), Icons.account_balance_wallet_rounded, 'Maaş + prim + bonus − kesinti (bugüne kadar)'),
          const SizedBox(height: 10),
        ],
        buyukKart(yonetici ? '$ay salon cirosu' : '$ay satışlarım', tl(buAy['ciro'] as num?), Icons.trending_up_rounded,
            'Hizmet + ürün + paket satışları'),
        const SizedBox(height: 10),
        PTKart(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              PTIkon(Icons.flag_rounded, boyut: 44),
              const SizedBox(width: 12),
              const Expanded(child: Text('Aylık hedefim', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: PT.koyu))),
              if (hedef != null)
                Text('%${hedef['yuzde']}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: PT.mor)),
            ]),
            const SizedBox(height: 12),
            if (hedef == null)
              Text(yonetici ? 'Hedefleri Profil > Ekibim ekranından belirleyebilirsiniz.' : 'Bu ay için yöneticiniz henüz hedef belirlemedi.',
                  style: const TextStyle(fontSize: 13.5, color: PT.gri))
            else ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (_d(hedef['yuzde']) / 100).clamp(0, 1).toDouble(),
                  minHeight: 12,
                  backgroundColor: PT.lila,
                  color: _d(hedef['yuzde']) >= 100 ? PT.yesil : PT.mor,
                ),
              ),
              const SizedBox(height: 8),
              Text('${tl(hedef['gerceklesen'] as num?)} / ${tl(hedef['tutar'] as num?)}',
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: PT.koyu)),
            ],
          ]),
        ),
        const SizedBox(height: 10),
        PTKart(
          child: Row(children: [
            Expanded(child: _mini('Bugünkü randevu', '${ozet['bugun_randevu'] ?? 0}')),
            Expanded(child: _mini(yonetici ? 'Müşteri' : 'Müşterim', binlik(_i(ozet['toplam_musteri'])))),
            Expanded(child: _mini('Ortalama puan', ozet['ortalama_puan'] == null ? '—' : ozet['ortalama_puan'].toString().replaceAll('.', ','))),
          ]),
        ),
        if (kazancGorunur) ...[
          const SizedBox(height: 14),
          PTSatir(
            ikon: Icons.receipt_long_rounded,
            baslik: 'Hakedişlerim',
            alt: 'Maaş, prim ve ödeme geçmişinin ayrıntısı',
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => Hakedislerim(isletmebilgi: isletmebilgi, personelId: personelId, personelAdi: personelAdi))),
          ),
        ],
      ]),
    );
  }

  Widget _mini(String e, String d) => Column(children: [
        Text(d, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: PT.koyu)),
        const SizedBox(height: 2),
        Text(e, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11.5, color: PT.gri)),
      ]);
}

// ═══════════════════════════════════════════════ Hizmetler

class HizmetlerSayfasi extends StatefulWidget {
  final String sube;
  const HizmetlerSayfasi({super.key, required this.sube});
  @override
  State<HizmetlerSayfasi> createState() => _HizmetlerSayfasiState();
}

class _HizmetlerSayfasiState extends _ListeDurum<HizmetlerSayfasi> {
  @override
  Future<Map<String, dynamic>> getir() => ProfilApi.get('hizmetler', widget.sube);

  @override
  Widget build(BuildContext context) {
    final l = (veri['hizmetler'] as List? ?? []).cast<Map>();
    return PTAltSayfa(
      baslik: 'Hizmetlerim',
      govde: kaydirma([
        if (l.isEmpty)
          const PTBos(Icons.content_cut_rounded, 'Size atanmış hizmet yok.\nYöneticiniz Personeller ekranından hizmet atayabilir.')
        else
          PTKart(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Column(children: [
              for (var i = 0; i < l.length; i++) ...[
                if (i > 0) const Divider(height: 1, color: PT.cizgi),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  child: Row(children: [
                    const Icon(Icons.check_circle_rounded, size: 18, color: PT.mor),
                    const SizedBox(width: 10),
                    Expanded(child: Text(l[i]['ad'].toString(), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: PT.koyu))),
                    if (l[i]['fiyat'] != null) Text(tl(l[i]['fiyat'] as num), style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: PT.gri)),
                  ]),
                ),
              ],
            ]),
          ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════ Çalışmalarım (portfolyo)

class CalismalarSayfasi extends StatefulWidget {
  final String sube;
  const CalismalarSayfasi({super.key, required this.sube});
  @override
  State<CalismalarSayfasi> createState() => _CalismalarSayfasiState();
}

class _CalismalarSayfasiState extends _ListeDurum<CalismalarSayfasi> {
  bool _yukleniyorFoto = false;

  @override
  Future<Map<String, dynamic>> getir() => ProfilApi.get('calismalar', widget.sube);

  Future<void> _ekle() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 2000);
    if (x == null) return;
    setState(() => _yukleniyorFoto = true);
    final r = await ProfilApi.dosya('calisma-ekle', widget.sube, 'resim', x.path);
    if (!mounted) return;
    setState(() => _yukleniyorFoto = false);
    ptMesaj(context, ProfilApi.ok(r) ? 'Fotoğraf eklendi.' : (r['hata'] ?? 'Yüklenemedi.').toString(), hata: !ProfilApi.ok(r));
    yukle();
  }

  void _goster(Map c) {
    showDialog(
      context: context,
      builder: (d) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(14),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: InteractiveViewer(child: Image.network('https://app.randevumcepte.com.tr${c['resim']}')),
          ),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
              onPressed: () async {
                Navigator.pop(d);
                final r = await ProfilApi.post('calisma-sil', widget.sube, {'id': c['id']});
                if (!mounted) return;
                ptMesaj(context, ProfilApi.ok(r) ? 'Fotoğraf silindi.' : (r['hata'] ?? 'Silinemedi.').toString(), hata: !ProfilApi.ok(r));
                yukle();
              },
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Sil'),
            ),
            const SizedBox(width: 10),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: PT.koyu),
              onPressed: () => Navigator.pop(d),
              child: const Text('Kapat'),
            ),
          ]),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = (veri['calismalar'] as List? ?? []).cast<Map>();
    return PTAltSayfa(
      baslik: 'Çalışmalarım',
      altDugme: ptAnaDugme('Fotoğraf Ekle', Icons.add_photo_alternate_rounded, _ekle, yukleniyor: _yukleniyorFoto),
      govde: kaydirma([
        if (l.isEmpty)
          const PTBos(Icons.photo_library_rounded, 'Yaptığınız işlerin fotoğraflarını burada biriktirin.\nMüşterilere örnek göstermek için kullanabilirsiniz.')
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 8, crossAxisSpacing: 8),
            itemCount: l.length,
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => _goster(l[i]),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network('https://app.randevumcepte.com.tr${l[i]['resim']}',
                    fit: BoxFit.cover,
                    cacheWidth: 360,
                    errorBuilder: (_, __, ___) => Container(color: PT.lila, child: const Icon(Icons.broken_image_rounded, color: PT.mor))),
              ),
            ),
          ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════ Ekibim (yönetici)

class EkipSayfasi extends StatefulWidget {
  final String sube;
  const EkipSayfasi({super.key, required this.sube});
  @override
  State<EkipSayfasi> createState() => _EkipSayfasiState();
}

class _EkipSayfasiState extends _ListeDurum<EkipSayfasi> {
  List<Map> _izinler = [];

  @override
  Future<Map<String, dynamic>> getir() async {
    final r = await ProfilApi.get('ekip', widget.sube);
    final iz = await ProfilApi.get('izinler', widget.sube, {'tum': '1'});
    if (ProfilApi.ok(iz)) _izinler = (iz['izinler'] as List? ?? []).cast<Map>();
    return r;
  }

  Future<void> _karar(Map z, bool onay) async {
    final notC = TextEditingController();
    final evet = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(onay ? 'İzni onayla' : 'İzni reddet'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${z['personel_adi']} · ${_izinAralik(z)}'),
          if (onay)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text('Onaylanınca bu günler takvimde kapatılır.', style: TextStyle(fontSize: 13, color: PT.gri)),
            ),
          if (onay) _cakisanUyari(z['cakisan']),
          const SizedBox(height: 10),
          TextField(controller: notC, decoration: const InputDecoration(hintText: 'Not (isteğe bağlı)')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Vazgeç')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: onay ? PT.yesil : Colors.red.shade600),
            onPressed: () => Navigator.pop(c, true),
            child: Text(onay ? 'Onayla' : 'Reddet'),
          ),
        ],
      ),
    );
    if (evet != true) return;
    final r = await ProfilApi.post('izin-karar', widget.sube, {'id': z['id'], 'onay': onay ? 1 : 0, 'not': notC.text.trim()});
    if (!mounted) return;
    ptMesaj(context, ProfilApi.ok(r) ? (onay ? 'İzin onaylandı, takvim kapatıldı.' : 'İzin reddedildi.') : (r['hata'] ?? 'Kaydedilemedi.').toString(),
        hata: !ProfilApi.ok(r));
    yukle();
  }

  /// Bu sürede zaten alınmış randevular (onay öncesi uyarı)
  Widget _cakisanUyari(dynamic liste) {
    final l = (liste is List ? liste : const []).cast<Map>();
    if (l.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Bu sürede ${l.length} randevusu var:', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFC2410C), fontSize: 13)),
        const SizedBox(height: 4),
        ...l.take(5).map((x) => Text('• ${trTarih(x['tarih']?.toString())} ${x['saat']} · ${x['musteri']}', style: const TextStyle(fontSize: 12.5))),
        if (l.length > 5) Text('… ve ${l.length - 5} randevu daha', style: const TextStyle(fontSize: 12.5)),
        const SizedBox(height: 4),
        const Text('Randevular kendiliğinden iptal edilmez; başka personele aktarın ya da müşteriyi arayın.',
            style: TextStyle(fontSize: 12, color: PT.gri)),
      ]),
    );
  }

  Future<void> _molaKarar(Map m, bool onay) async {
    final evet = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(onay ? 'Molayı onayla' : 'Molayı reddet'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${m['personel_adi']} · ${m['sure']}'),
          if (onay)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text('Onaylanınca şu andan itibaren takvim bu süre için kapatılır.', style: TextStyle(fontSize: 13, color: PT.gri)),
            ),
          if (onay) _cakisanUyari(m['cakisan']),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Vazgeç')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: onay ? PT.yesil : Colors.red.shade600),
            onPressed: () => Navigator.pop(c, true),
            child: Text(onay ? 'Onayla' : 'Reddet'),
          ),
        ],
      ),
    );
    if (evet != true) return;
    final r = await ProfilApi.post('mola-karar', widget.sube, {'id': m['id'], 'onay': onay ? 1 : 0});
    if (!mounted) return;
    ptMesaj(context, ProfilApi.ok(r) ? (onay ? 'Mola onaylandı, takvim kapatıldı.' : 'Mola reddedildi.') : (r['hata'] ?? 'Kaydedilemedi.').toString(),
        hata: !ProfilApi.ok(r));
    yukle();
  }

  Future<void> _kisiMenu(Map p) async {
    final secim = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (c) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const PTIkon(Icons.toggle_on_rounded, boyut: 42),
            title: const Text('Durumunu değiştir', style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text((p['durum_metni'] ?? 'Müsait').toString()),
            onTap: () => Navigator.pop(c, 'durum'),
          ),
          ListTile(
            leading: const PTIkon(Icons.flag_rounded, boyut: 42),
            title: const Text('Aylık hedef', style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(_d(p['hedef']) > 0 ? tl(_d(p['hedef'])) : 'Hedef yok'),
            onTap: () => Navigator.pop(c, 'hedef'),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (!mounted || secim == null) return;
    if (secim == 'hedef') return _hedef(p);
    final degisti = await durumSec(context,
        sube: widget.sube,
        yonetici: true,
        detay: {'durum': p['durum'] ?? 'musait', 'metin': p['durum_metni'] ?? ''},
        personelId: _i(p['id']),
        personelAdi: p['ad'].toString());
    if (degisti) yukle();
  }

  Future<void> _hedef(Map p) async {
    final c = TextEditingController(text: _d(p['hedef']) > 0 ? _d(p['hedef']).round().toString() : '');
    final tutar = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('${p['ad']} · aylık hedef'),
        content: TextField(
          controller: c,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(suffixText: '₺', hintText: 'Örn. 50000', helperText: 'Bu ayki satış hedefi (0 = hedef yok)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('Vazgeç')),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: PT.mor), onPressed: () => Navigator.pop(d, c.text), child: const Text('Kaydet')),
        ],
      ),
    );
    if (tutar == null) return;
    final r = await ProfilApi.post('hedef', widget.sube, {'personel_id': p['id'], 'tutar': tutar.replaceAll(RegExp(r'[^0-9]'), '')});
    if (!mounted) return;
    ptMesaj(context, ProfilApi.ok(r) ? 'Hedef kaydedildi.' : (r['hata'] ?? 'Kaydedilemedi.').toString(), hata: !ProfilApi.ok(r));
    yukle();
  }

  @override
  Widget build(BuildContext context) {
    final ekip = (veri['ekip'] as List? ?? []).cast<Map>();
    final durumlar = Map<String, dynamic>.from(veri['durumlar'] ?? {});
    final bekleyen = _izinler.where((z) => z['durum'] == 'bekliyor').toList();
    final molalar = (veri['mola_bekleyen'] as List? ?? []).cast<Map>();
    return PTAltSayfa(
      baslik: 'Ekibim',
      govde: kaydirma([
        if (molalar.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text('Onay bekleyen molalar', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFEA580C))),
          ),
          ...molalar.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: PTKart(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      const PTIkon(Icons.coffee_rounded, boyut: 40),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(m['personel_adi'].toString(), style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: PT.koyu)),
                          Text('${m['sure']} mola · ${m['saat']}\'de istedi', style: const TextStyle(fontSize: 13, color: PT.gri)),
                        ]),
                      ),
                    ]),
                    if ((m['cakisan'] as List? ?? []).isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text('⚠ Bu sürede ${(m['cakisan'] as List).length} randevusu var',
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFFC2410C))),
                      ),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red.shade600, side: BorderSide(color: Colors.red.shade200)),
                          onPressed: () => _molaKarar(m, false),
                          child: const Text('Reddet'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: PT.yesil),
                          onPressed: () => _molaKarar(m, true),
                          child: const Text('Onayla'),
                        ),
                      ),
                    ]),
                  ]),
                ),
              )),
          const SizedBox(height: 8),
        ],
        if (bekleyen.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text('Onay bekleyen izinler', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFEA580C))),
          ),
          ...bekleyen.map((z) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: PTKart(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(z['personel_adi'].toString(), style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: PT.koyu)),
                    Text('${_izinAralik(z)} · ${_i(z['gun'])} gün · ${_izinTurleri[z['tur']] ?? z['tur']}',
                        style: const TextStyle(fontSize: 13, color: PT.gri)),
                    if ((z['aciklama'] ?? '').toString().isNotEmpty)
                      Padding(padding: const EdgeInsets.only(top: 5), child: Text(z['aciklama'].toString(), style: const TextStyle(fontSize: 13.5))),
                    if ((z['cakisan'] as List? ?? []).isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text('⚠ Bu sürede ${(z['cakisan'] as List).length} randevusu var',
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFFC2410C))),
                      ),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red.shade600, side: BorderSide(color: Colors.red.shade200)),
                          onPressed: () => _karar(z, false),
                          child: const Text('Reddet'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: PT.yesil),
                          onPressed: () => _karar(z, true),
                          child: const Text('Onayla'),
                        ),
                      ),
                    ]),
                  ]),
                ),
              )),
          const SizedBox(height: 8),
        ],
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text('Ekip · bu ay', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: PT.gri)),
        ),
        ...ekip.map((p) {
          final durum = (p['durum'] ?? 'musait').toString();
          final yuzde = p['yuzde'];
          final resim = (p['resim'] ?? '').toString();
          return Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: PTKart(
              onTap: () => _kisiMenu(p),
              child: Column(children: [
                Row(children: [
                  Stack(children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: PT.lila,
                      backgroundImage: resim.isNotEmpty && resim != 'null' ? NetworkImage('https://app.randevumcepte.com.tr/$resim') : null,
                      child: resim.isEmpty || resim == 'null'
                          ? Text(p['ad'].toString().isNotEmpty ? p['ad'].toString()[0] : '?',
                              style: const TextStyle(fontWeight: FontWeight.w800, color: PT.mor))
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                          width: 13,
                          height: 13,
                          decoration: BoxDecoration(color: PT.durumRenk(durum), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2))),
                    ),
                  ]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(p['ad'].toString(), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: PT.koyu)),
                      Text('${p['durum_metni'] ?? durumlar[durum] ?? durum} · Satış ${tl(_d(p['ciro']))}', style: const TextStyle(fontSize: 12.5, color: PT.gri)),
                    ]),
                  ),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(_d(p['hedef']) > 0 ? '%$yuzde' : 'Hedef yok',
                        style: TextStyle(fontSize: _d(p['hedef']) > 0 ? 17 : 12.5, fontWeight: FontWeight.w800, color: _d(p['hedef']) > 0 ? PT.mor : PT.gri)),
                    const Text('Düzenle', style: TextStyle(fontSize: 11.5, color: PT.mor, fontWeight: FontWeight.w600)),
                  ]),
                ]),
                if (_d(p['hedef']) > 0) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: (_d(yuzde) / 100).clamp(0, 1).toDouble(),
                      minHeight: 7,
                      backgroundColor: PT.lila,
                      color: _d(yuzde) >= 100 ? PT.yesil : PT.mor,
                    ),
                  ),
                ],
              ]),
            ),
          );
        }),
        if (_izinler.any((z) => z['durum'] != 'bekliyor')) ...[
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text('İzin geçmişi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: PT.gri)),
          ),
          ..._izinler.where((z) => z['durum'] != 'bekliyor').take(20).map((z) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: PTKart(
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(z['personel_adi'].toString(), style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: PT.koyu)),
                        Text(_izinAralik(z), style: const TextStyle(fontSize: 12.5, color: PT.gri)),
                      ]),
                    ),
                    _izinDurumRozet(z['durum'].toString()),
                  ]),
                ),
              )),
        ],
      ]),
    );
  }
}

// ═══════════════════════════════════════════════ Yetkilerim

class YetkilerSayfasi extends StatefulWidget {
  final String sube;
  const YetkilerSayfasi({super.key, required this.sube});
  @override
  State<YetkilerSayfasi> createState() => _YetkilerSayfasiState();
}

class _YetkilerSayfasiState extends _ListeDurum<YetkilerSayfasi> {
  @override
  Future<Map<String, dynamic>> getir() => ProfilApi.get('yetkiler', widget.sube);

  @override
  Widget build(BuildContext context) {
    final gruplar = (veri['gruplar'] as List? ?? []).cast<Map>();
    return PTAltSayfa(
      baslik: 'Yetkilerim',
      govde: kaydirma([
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 10),
          child: Text('Yetkilerinizi işletme yöneticiniz belirler. Değişiklik için yöneticinize başvurun.',
              style: TextStyle(fontSize: 13, color: PT.gri)),
        ),
        ...gruplar.map((g) {
          final l = (g['yetkiler'] as List? ?? []).cast<Map>();
          final acik = l.where((y) => y['acik'] == true).length;
          return Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: PTKart(
              padding: EdgeInsets.zero,
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.fromLTRB(14, 4, 12, 4),
                  shape: const Border(),
                  title: Text(g['ad'].toString(), style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: PT.koyu)),
                  subtitle: Text('$acik / ${l.length} açık', style: const TextStyle(fontSize: 12.5, color: PT.gri)),
                  children: l
                      .map((y) => ListTile(
                            dense: true,
                            leading: Icon(y['acik'] == true ? Icons.check_circle_rounded : Icons.remove_circle_outline_rounded,
                                color: y['acik'] == true ? PT.yesil : const Color(0xFFCBD5E1)),
                            title: Text(y['ad'].toString(),
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: y['acik'] == true ? PT.koyu : PT.gri)),
                            subtitle: (y['aciklama'] ?? '').toString().isEmpty ? null : Text(y['aciklama'].toString(), style: const TextStyle(fontSize: 12)),
                          ))
                      .toList(),
                ),
              ),
            ),
          );
        }),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════ Cihazlarım

class CihazlarSayfasi extends StatefulWidget {
  final String sube;
  const CihazlarSayfasi({super.key, required this.sube});
  @override
  State<CihazlarSayfasi> createState() => _CihazlarSayfasiState();
}

class _CihazlarSayfasiState extends _ListeDurum<CihazlarSayfasi> {
  @override
  Future<Map<String, dynamic>> getir() async {
    final t = await NotificationService.instance.mevcutToken();
    return ProfilApi.get('cihazlar', widget.sube, {'token': t ?? ''});
  }

  Future<void> _kapat(Map c) async {
    final evet = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Bu cihazdan çıkış yap'),
        content: const Text('Bu cihazdaki oturum kapatılır ve cihaz bildirim almayı bırakır.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Vazgeç')),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600), onPressed: () => Navigator.pop(d, true), child: const Text('Çıkış yap')),
        ],
      ),
    );
    if (evet != true) return;
    final r = await ProfilApi.post('cihaz-kapat', widget.sube, {'id': c['id']});
    if (!mounted) return;
    ptMesaj(context, ProfilApi.ok(r) ? 'Cihazdaki oturum kapatıldı.' : (r['hata'] ?? 'Yapılamadı.').toString(), hata: !ProfilApi.ok(r));
    yukle();
  }

  IconData _ikon(Map c) {
    final p = '${c['platform'] ?? ''} ${c['cihaz'] ?? ''}'.toLowerCase();
    if (p.contains('web')) return Icons.laptop_mac_rounded;
    if (p.contains('ios') || p.contains('iphone') || p.contains('ipad')) return Icons.phone_iphone_rounded;
    return Icons.phone_android_rounded;
  }

  /// Platforma göre okunur ad; cihaz alanı model adıysa yanına eklenir (kimlik kodları gösterilmez).
  String _ad(Map c) {
    final p = (c['platform'] ?? '').toString().toLowerCase();
    final tur = p.contains('web')
        ? 'Web tarayıcı'
        : (p.contains('ios') || p.contains('iphone'))
            ? 'iPhone'
            : p.contains('android')
                ? 'Android telefon'
                : 'Telefon';
    final cihaz = (c['cihaz'] ?? '').toString().trim();
    final kimlik = RegExp(r'^[0-9a-fA-F-]{12,}$').hasMatch(cihaz);
    if (cihaz.isEmpty || cihaz == 'null' || kimlik) return tur;
    return '$tur · $cihaz';
  }

  @override
  Widget build(BuildContext context) {
    final l = (veri['cihazlar'] as List? ?? []).cast<Map>();
    return PTAltSayfa(
      baslik: 'Cihazlarım',
      govde: kaydirma([
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 10),
          child: Text('Hesabınızın açık olduğu ve bildirim alan cihazlar. Tanımadığınız bir cihaz varsa çıkış yaptırın ve şifrenizi değiştirin.',
              style: TextStyle(fontSize: 13, height: 1.35, color: PT.gri)),
        ),
        if (l.isEmpty) const PTBos(Icons.devices_rounded, 'Kayıtlı cihaz bulunamadı.'),
        ...l.map((c) {
          final bu = c['bu_cihaz'] == true;
          final son = (c['son_kullanim_tarihi'] ?? c['updated_at'] ?? c['created_at'] ?? '').toString();
          return Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: PTKart(
              child: Row(children: [
                PTIkon(_ikon(c), boyut: 46),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Flexible(
                        child: Text(_ad(c), maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: PT.koyu)),
                      ),
                      if (bu) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(color: PT.yesil.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                          child: const Text('Bu cihaz', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: PT.yesil)),
                        ),
                      ],
                    ]),
                    if (son.length >= 10) Text('Son kullanım: ${trTarih(son.substring(0, 10))}', style: const TextStyle(fontSize: 12.5, color: PT.gri)),
                  ]),
                ),
                if (!bu)
                  TextButton(
                    onPressed: () => _kapat(c),
                    child: const Text('Çıkış yap', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w700)),
                  ),
              ]),
            ),
          );
        }),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════ Uygulama Hakkında + yasal metinler

/// İşletmenin kendi bilgileri (ad, logo, adres, telefon) + sürüm + uygulama içi yasal metinler.
/// Metinler sunucuda her işletme için kendi bilgileriyle otomatik üretilir (/api/v1/profil/hakkinda).
class HakkindaSayfasi extends StatefulWidget {
  final String sube;
  const HakkindaSayfasi({super.key, required this.sube});
  static String surum = '';
  static Future<String> surumAl() async {
    if (surum.isNotEmpty) return surum;
    try {
      surum = (await PackageInfo.fromPlatform()).version;
    } catch (_) {}
    return surum;
  }

  @override
  State<HakkindaSayfasi> createState() => _HakkindaSayfasiState();
}

class _HakkindaSayfasiState extends _ListeDurum<HakkindaSayfasi> {
  String _yapi = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((p) {
      if (mounted) setState(() => _yapi = '${p.version} (${p.buildNumber})');
    }).catchError((_) {});
  }

  @override
  Future<Map<String, dynamic>> getir() => ProfilApi.get('hakkinda', widget.sube);

  static const Map<String, IconData> _ikon = {
    'kullanim': Icons.description_rounded,
    'gizlilik': Icons.privacy_tip_rounded,
    'kvkk': Icons.verified_user_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final i = veri['isletme'] is Map ? veri['isletme'] as Map : const {};
    final metinler = (veri['metinler'] as List? ?? []).cast<Map>();
    final ad = (i['ad'] ?? '').toString();
    final logo = (i['logo'] ?? '').toString();
    return PTAltSayfa(
      baslik: 'Uygulama Hakkında',
      govde: kaydirma([
        PTKart(
          padding: const EdgeInsets.all(18),
          child: Column(children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(color: PT.lila, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4), boxShadow: [
                BoxShadow(color: PT.mor.withValues(alpha: 0.14), blurRadius: 16, offset: const Offset(0, 6)),
              ]),
              clipBehavior: Clip.antiAlias,
              child: logo.isNotEmpty
                  ? Image.network(logo, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.storefront_rounded, color: PT.mor, size: 40))
                  : const Icon(Icons.storefront_rounded, color: PT.mor, size: 40),
            ),
            const SizedBox(height: 12),
            Text(ad, textAlign: TextAlign.center, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: PT.koyu, letterSpacing: -0.3)),
            const SizedBox(height: 4),
            Text(_yapi.isEmpty ? '' : 'Sürüm $_yapi', style: const TextStyle(fontSize: 13, color: PT.gri)),
            if ((i['adres'] ?? '').toString().isNotEmpty || (i['telefon'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1, color: PT.cizgi),
              const SizedBox(height: 12),
              if ((i['adres'] ?? '').toString().isNotEmpty)
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.location_on_rounded, size: 18, color: PT.mor),
                  const SizedBox(width: 8),
                  Expanded(child: Text(i['adres'].toString(), style: const TextStyle(fontSize: 13.5, height: 1.35, color: PT.koyu))),
                ]),
              if ((i['telefon'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.call_rounded, size: 18, color: PT.mor),
                  const SizedBox(width: 8),
                  Text(i['telefon'].toString(), style: const TextStyle(fontSize: 13.5, color: PT.koyu)),
                ]),
              ],
            ],
          ]),
        ),
        const SizedBox(height: 14),
        ...metinler.map((m) => PTSatir(
              ikon: _ikon[m['kod']] ?? Icons.article_rounded,
              baslik: m['baslik'].toString(),
              alt: 'Son güncelleme: ${m['guncelleme'] ?? ''}',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => YasalMetinSayfasi(metin: m, isletme: ad))),
            )),
      ]),
    );
  }
}

/// Uygulama içi yasal metin okuma sayfası
class YasalMetinSayfasi extends StatelessWidget {
  final Map metin;
  final String isletme;
  const YasalMetinSayfasi({super.key, required this.metin, required this.isletme});

  @override
  Widget build(BuildContext context) {
    final bolumler = (metin['bolumler'] as List? ?? []).cast<Map>();
    return PTAltSayfa(
      baslik: metin['baslik'].toString(),
      govde: ListView(padding: const EdgeInsets.fromLTRB(16, 6, 16, 28), children: [
        PTKart(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(isletme, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: PT.mor)),
            Text('Son güncelleme: ${metin['guncelleme'] ?? ''}', style: const TextStyle(fontSize: 12.5, color: PT.gri)),
            for (var n = 0; n < bolumler.length; n++) ...[
              const SizedBox(height: 16),
              Text('${n + 1}. ${bolumler[n]['baslik']}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: PT.koyu)),
              const SizedBox(height: 5),
              Text(bolumler[n]['metin'].toString(), style: const TextStyle(fontSize: 14, height: 1.55, color: Color(0xFF3B3561))),
            ],
          ]),
        ),
      ]),
    );
  }
}

import 'package:randevu_sistem/dil/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:randevu_sistem/Models/musteri_danisanlar.dart';
import 'package:randevu_sistem/musteripaneli/anasayfa/salon_yorumlari.dart';
import 'package:randevu_sistem/musteripaneli/marka_subeleri.dart';
import 'package:randevu_sistem/musteripaneli/randevularim/randevularim.dart';
import 'package:randevu_sistem/randevualma/randevual.dart';
import 'package:randevu_sistem/theme/musteri_palet.dart';

/// Alt menüdeki + düğmesi: alttan açılan "Hızlı İşlemler" (Randevu Al, Yol Tarifi, WhatsApp, Değerlendir).
/// Adres yoksa Yol Tarifi yerine Salonu Ara; online randevu kapalıysa Randevu Al yerine Randevularım çıkar.
Future<void> musteriHizliIslemAc(
  BuildContext context, {
  required MusteriDanisan md,
  required dynamic isletmebilgi,
  required bool randevuAcik,
}) async {
  final subeler = _subeler(md, isletmebilgi);
  final adresVar = subeler.any((s) => s.adres.isNotEmpty);

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    builder: (c) {
      final p = MusteriPalet.of(c);
      void sec(VoidCallback is_) {
        Navigator.pop(c);
        is_();
      }

      void git(Widget sayfa) => sec(() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => sayfa)));

      return _Panel(p: p, baslik: 'Hızlı İşlemler', children: [
        _buyukKart(
          p,
          randevuAcik ? Icons.event_available_rounded : Icons.calendar_month_rounded,
          randevuAcik ? 'Randevu Al' : 'Randevularım',
          randevuAcik ? 'Hizmet ve saatini hemen seç' : 'Yaklaşan ve geçmiş randevuların',
          () => git(randevuAcik ? RandevuAl() : MusteriRandevulari(md: md, isletmebilgi: isletmebilgi, geriButonu: true)),
        ),
        const SizedBox(height: 14),
        Row(children: [
          if (adresVar)
            _kutu(p, Icons.near_me_rounded, p.ana, 'Yol Tarifi', () => sec(() => _subeSec(context, subeler, _yolTarifi)))
          else
            _kutu(p, Icons.phone_rounded, p.ana, 'Salonu Ara', () => sec(() => _subeSec(context, subeler, _ara))),
          const SizedBox(width: 12),
          _kutu(p, FontAwesomeIcons.whatsapp, const Color(0xFF1FAF57), 'WhatsApp',
              () => sec(() => _subeSec(context, subeler, _whatsapp))),
          const SizedBox(width: 12),
          _kutu(p, Icons.star_rounded, const Color(0xFFE8A317), 'Değerlendir', () => git(const SalonYorumlariSayfasi())),
        ]),
      ]);
    },
  );
}

TextStyle _yazi(double boyut, FontWeight kalinlik, Color renk) =>
    GoogleFonts.figtree(fontSize: boyut, fontWeight: kalinlik, color: renk, letterSpacing: 0, height: 1.2);

Widget _buyukKart(MusteriPalet p, IconData ikon, String baslik, String alt, VoidCallback onTap) => Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: p.dugme),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: p.dugmeAna.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 7))],
          ),
          child: Row(children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(17)),
              child: Icon(ikon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(baslik, style: _yazi(18, FontWeight.w800, Colors.white)),
                const SizedBox(height: 3),
                Text(alt, style: _yazi(13, FontWeight.w500, Colors.white.withValues(alpha: 0.9))),
              ]),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 28),
          ]),
        ),
      ),
    );

Widget _kutu(MusteriPalet p, IconData ikon, Color renk, String yazi, VoidCallback onTap) => Expanded(
      child: Semantics(
        button: true,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: 112,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: p.kart,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: p.kartKenar),
              boxShadow: [BoxShadow(color: p.ana.withValues(alpha: p.koyuMod ? 0 : 0.07), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(shape: BoxShape.circle, color: renk.withValues(alpha: 0.14)),
                child: Icon(ikon, color: renk, size: 25),
              ),
              const SizedBox(height: 10),
              FittedBox(fit: BoxFit.scaleDown, child: Text(yazi, style: _yazi(13, FontWeight.w700, p.baslik))),
            ]),
          ),
        ),
      ),
    );

class _Panel extends StatelessWidget {
  final MusteriPalet p;
  final String baslik;
  final List<Widget> children;
  const _Panel({required this.p, required this.baslik, required this.children});

  @override
  Widget build(BuildContext context) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        decoration: BoxDecoration(
          color: p.zemin,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(color: p.ana.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(3)),
                ),
              ),
              const SizedBox(height: 16),
              Text(baslik, style: _yazi(19, FontWeight.w800, p.baslik)),
              const SizedBox(height: 14),
              ...children,
            ]),
          ),
        ),
      );
}

// ---------------------------------------------------------------- şube + dış bağlantılar

class _Sube {
  final String ad, adres, telefon, whatsapp;
  const _Sube(this.ad, this.adres, this.telefon, this.whatsapp);
}

/// Markanın şubeleri (başka işletmeler hariç)
List<_Sube> _subeler(MusteriDanisan md, dynamic isletmebilgi) {
  String oku(Map m, List<String> anahtarlar) {
    for (final k in anahtarlar) {
      final v = m[k]?.toString().trim() ?? '';
      if (v.isNotEmpty && v != 'null') return v;
    }
    return '';
  }

  _Sube yap(Map m) => _Sube(
        oku(m, const ['salon_adi', 'isletme_adi', 'adi', 'name']),
        oku(m, const ['adres']),
        oku(m, const ['telefon_1', 'telefon', 'telefonno', 'telefon_2']),
        oku(m, const ['whatsapp', 'whatsapp_numara', 'whatsappPhone', 'telefon_1', 'telefon']),
      );

  return [for (final e in markaSubeleri(md, isletmebilgi)) yap(e['salonlar'] as Map)];
}

/// Tek şubede doğrudan çalışır, birden fazlaysa şube seçtirir
void _subeSec(BuildContext context, List<_Sube> subeler, Future<void> Function(BuildContext, _Sube) islem) {
  if (subeler.isEmpty) return _uyar(context, 'Salon bilgisi bulunamadı.');
  if (subeler.length == 1) {
    islem(context, subeler.first);
    return;
  }
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    builder: (c) {
      final p = MusteriPalet.of(c);
      return _Panel(p: p, baslik: 'Şube seçin', children: [
        for (final s in subeler)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: p.kart,
              borderRadius: BorderRadius.circular(18),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: p.kartKenar)),
                leading: Icon(Icons.storefront_rounded, color: p.ana),
                title: Text(s.ad.isEmpty ? 'Şube' : s.ad, style: _yazi(15, FontWeight.w700, p.baslik)),
                subtitle: s.adres.isEmpty ? null : Text(s.adres, maxLines: 2, overflow: TextOverflow.ellipsis),
                trailing: Icon(Icons.chevron_right_rounded, color: p.ana),
                onTap: () {
                  Navigator.pop(c);
                  islem(context, s);
                },
              ),
            ),
          ),
      ]);
    },
  );
}

Future<void> _yolTarifi(BuildContext context, _Sube s) => s.adres.isEmpty
    ? Future.sync(() => _uyar(context, 'Salonun adresi tanımlı değil.'))
    : _ac(context, Uri.https('www.google.com', '/maps/dir/', {'api': '1', 'destination': '${s.ad}, ${s.adres}'}), 'Harita açılamadı.');

Future<void> _ara(BuildContext context, _Sube s) => s.telefon.isEmpty
    ? Future.sync(() => _uyar(context, 'Salonun arama numarası tanımlı değil.'))
    : _ac(context, Uri.parse('tel:${s.telefon.replaceAll(RegExp(r'[^0-9+]'), '')}'), 'Arama başlatılamadı.');

Future<void> _whatsapp(BuildContext context, _Sube s) {
  var no = s.whatsapp.replaceAll(RegExp(r'[^0-9]'), '');
  if (no.startsWith('00')) no = no.substring(2);
  if (no.startsWith('0')) no = '90${no.substring(1)}';
  if (!no.startsWith('90') && no.length == 10) no = '90$no';
  if (no.isEmpty) return Future.sync(() => _uyar(context, 'Salonun WhatsApp numarası tanımlı değil.'));
  return _ac(context, Uri.https('wa.me', '/$no', {'text': 'Merhaba, bilgi / randevu almak istiyorum.'}), 'WhatsApp açılamadı.');
}

Future<void> _ac(BuildContext context, Uri url, String hata) async {
  try {
    if (await launchUrl(url, mode: LaunchMode.externalApplication)) return;
  } catch (_) {
    // aşağıda uyarı gösterilir
  }
  if (context.mounted) _uyar(context, hata);
}

void _uyar(BuildContext context, String mesaj) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mesaj), behavior: SnackBarBehavior.floating));

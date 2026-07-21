// telefon_ulke_alani.dart — Ulke kodu secici + telefon numarasi alani (mobil)
//
// Web'deki public/js/telefon-ulke.js ile BIREBIR ayni sozlesme:
//   - Turkiye (+90): backend'e DUZ ulusal numara gider, bastaki 0 atilmis -> "5321234567"
//   - Yabanci:      backend'e "+KOD" + ulusal numara gider          -> "+355691234567"
// Backend telefon_no_format_duzenle yalniz +90/90/0 soyar, +355..'a dokunmaz.
//
// Kullanim: mevcut TextEditingController'i ver; widget onun .text'ini her zaman
// backend'e gidecek degerde tutar (eski dogrulama/gonderim kodu aynen calisir).
//
//   TelefonUlkeAlani(controller: telefon, label: 'Telefon Numarası')

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UlkeKodu {
  final String ad;
  final String kod;
  final String bayrak;
  final bool one; // true -> listenin basindaki "Sik kullanilan" grubunda

  const UlkeKodu(this.ad, this.kod, this.bayrak, {this.one = false});
}

const List<UlkeKodu> ulkeKodlari = [
  UlkeKodu('Türkiye', '+90', '🇹🇷', one: true),
  UlkeKodu('Almanya', '+49', '🇩🇪', one: true),
  UlkeKodu('Hollanda', '+31', '🇳🇱', one: true),
  UlkeKodu('Avusturya', '+43', '🇦🇹', one: true),
  UlkeKodu('Belçika', '+32', '🇧🇪', one: true),
  UlkeKodu('Fransa', '+33', '🇫🇷', one: true),
  UlkeKodu('İngiltere', '+44', '🇬🇧', one: true),
  UlkeKodu('İsviçre', '+41', '🇨🇭', one: true),
  UlkeKodu('İtalya', '+39', '🇮🇹', one: true),
  UlkeKodu('İspanya', '+34', '🇪🇸', one: true),
  UlkeKodu('İsveç', '+46', '🇸🇪', one: true),
  UlkeKodu('Norveç', '+47', '🇳🇴', one: true),
  UlkeKodu('Danimarka', '+45', '🇩🇰', one: true),
  UlkeKodu('ABD / Kanada', '+1', '🇺🇸', one: true),
  UlkeKodu('Azerbaycan', '+994', '🇦🇿', one: true),
  UlkeKodu('Arnavutluk', '+355', '🇦🇱', one: true),
  UlkeKodu('Kosova', '+383', '🇽🇰', one: true),
  UlkeKodu('K. Makedonya', '+389', '🇲🇰', one: true),
  UlkeKodu('Bulgaristan', '+359', '🇧🇬', one: true),
  UlkeKodu('K.K.T.C / G.Kıbrıs', '+357', '🇨🇾', one: true),
  UlkeKodu('Afganistan', '+93', '🇦🇫'),
  UlkeKodu('Almanya', '+49', '🇩🇪'),
  UlkeKodu('ABD / Kanada', '+1', '🇺🇸'),
  UlkeKodu('Andorra', '+376', '🇦🇩'),
  UlkeKodu('Angola', '+244', '🇦🇴'),
  UlkeKodu('Anguilla', '+1264', '🇦🇮'),
  UlkeKodu('Antigua ve Barbuda', '+1268', '🇦🇬'),
  UlkeKodu('Arjantin', '+54', '🇦🇷'),
  UlkeKodu('Arnavutluk', '+355', '🇦🇱'),
  UlkeKodu('Aruba', '+297', '🇦🇼'),
  UlkeKodu('Avustralya', '+61', '🇦🇺'),
  UlkeKodu('Avusturya', '+43', '🇦🇹'),
  UlkeKodu('Azerbaycan', '+994', '🇦🇿'),
  UlkeKodu('Bahamalar', '+1242', '🇧🇸'),
  UlkeKodu('Bahreyn', '+973', '🇧🇭'),
  UlkeKodu('Bangladeş', '+880', '🇧🇩'),
  UlkeKodu('Barbados', '+1246', '🇧🇧'),
  UlkeKodu('Belarus', '+375', '🇧🇾'),
  UlkeKodu('Belçika', '+32', '🇧🇪'),
  UlkeKodu('Belize', '+501', '🇧🇿'),
  UlkeKodu('Benin', '+229', '🇧🇯'),
  UlkeKodu('Bermuda', '+1441', '🇧🇲'),
  UlkeKodu('Beyaz Rusya (Belarus)', '+375', '🇧🇾'),
  UlkeKodu('Bhutan', '+975', '🇧🇹'),
  UlkeKodu('Birleşik Arap Emirlikleri', '+971', '🇦🇪'),
  UlkeKodu('Bolivya', '+591', '🇧🇴'),
  UlkeKodu('Bosna-Hersek', '+387', '🇧🇦'),
  UlkeKodu('Botsvana', '+267', '🇧🇼'),
  UlkeKodu('Brezilya', '+55', '🇧🇷'),
  UlkeKodu('Brunei', '+673', '🇧🇳'),
  UlkeKodu('Bulgaristan', '+359', '🇧🇬'),
  UlkeKodu('Burkina Faso', '+226', '🇧🇫'),
  UlkeKodu('Burundi', '+257', '🇧🇮'),
  UlkeKodu('Cebelitarık', '+350', '🇬🇮'),
  UlkeKodu('Cezayir', '+213', '🇩🇿'),
  UlkeKodu('Cibuti', '+253', '🇩🇯'),
  UlkeKodu('Çad', '+235', '🇹🇩'),
  UlkeKodu('Çekya', '+420', '🇨🇿'),
  UlkeKodu('Çin', '+86', '🇨🇳'),
  UlkeKodu('Danimarka', '+45', '🇩🇰'),
  UlkeKodu('Doğu Timor', '+670', '🇹🇱'),
  UlkeKodu('Dominik Cumhuriyeti', '+1809', '🇩🇴'),
  UlkeKodu('Dominika', '+1767', '🇩🇲'),
  UlkeKodu('Ekvador', '+593', '🇪🇨'),
  UlkeKodu('Ekvator Ginesi', '+240', '🇬🇶'),
  UlkeKodu('El Salvador', '+503', '🇸🇻'),
  UlkeKodu('Endonezya', '+62', '🇮🇩'),
  UlkeKodu('Eritre', '+291', '🇪🇷'),
  UlkeKodu('Ermenistan', '+374', '🇦🇲'),
  UlkeKodu('Estonya', '+372', '🇪🇪'),
  UlkeKodu('Esvatini', '+268', '🇸🇿'),
  UlkeKodu('Etiyopya', '+251', '🇪🇹'),
  UlkeKodu('Fas', '+212', '🇲🇦'),
  UlkeKodu('Fiji', '+679', '🇫🇯'),
  UlkeKodu('Fildişi Sahili', '+225', '🇨🇮'),
  UlkeKodu('Filipinler', '+63', '🇵🇭'),
  UlkeKodu('Filistin', '+970', '🇵🇸'),
  UlkeKodu('Finlandiya', '+358', '🇫🇮'),
  UlkeKodu('Fransa', '+33', '🇫🇷'),
  UlkeKodu('Fransız Guyanası', '+594', '🇬🇫'),
  UlkeKodu('Fransız Polinezyası', '+689', '🇵🇫'),
  UlkeKodu('Gabon', '+241', '🇬🇦'),
  UlkeKodu('Gambiya', '+220', '🇬🇲'),
  UlkeKodu('Gana', '+233', '🇬🇭'),
  UlkeKodu('Gine', '+224', '🇬🇳'),
  UlkeKodu('Gine-Bissau', '+245', '🇬🇼'),
  UlkeKodu('Grenada', '+1473', '🇬🇩'),
  UlkeKodu('Grönland', '+299', '🇬🇱'),
  UlkeKodu('Guadeloupe', '+590', '🇬🇵'),
  UlkeKodu('Guam', '+1671', '🇬🇺'),
  UlkeKodu('Guatemala', '+502', '🇬🇹'),
  UlkeKodu('Guyana', '+592', '🇬🇾'),
  UlkeKodu('Güney Afrika', '+27', '🇿🇦'),
  UlkeKodu('Güney Kore', '+82', '🇰🇷'),
  UlkeKodu('Güney Sudan', '+211', '🇸🇸'),
  UlkeKodu('Gürcistan', '+995', '🇬🇪'),
  UlkeKodu('Haiti', '+509', '🇭🇹'),
  UlkeKodu('Hindistan', '+91', '🇮🇳'),
  UlkeKodu('Hollanda', '+31', '🇳🇱'),
  UlkeKodu('Honduras', '+504', '🇭🇳'),
  UlkeKodu('Hong Kong', '+852', '🇭🇰'),
  UlkeKodu('Hırvatistan', '+385', '🇭🇷'),
  UlkeKodu('Irak', '+964', '🇮🇶'),
  UlkeKodu('İngiltere', '+44', '🇬🇧'),
  UlkeKodu('İran', '+98', '🇮🇷'),
  UlkeKodu('İrlanda', '+353', '🇮🇪'),
  UlkeKodu('İspanya', '+34', '🇪🇸'),
  UlkeKodu('İsrail', '+972', '🇮🇱'),
  UlkeKodu('İsveç', '+46', '🇸🇪'),
  UlkeKodu('İsviçre', '+41', '🇨🇭'),
  UlkeKodu('İtalya', '+39', '🇮🇹'),
  UlkeKodu('İzlanda', '+354', '🇮🇸'),
  UlkeKodu('Jamaika', '+1876', '🇯🇲'),
  UlkeKodu('Japonya', '+81', '🇯🇵'),
  UlkeKodu('Kamboçya', '+855', '🇰🇭'),
  UlkeKodu('Kamerun', '+237', '🇨🇲'),
  UlkeKodu('Karadağ', '+382', '🇲🇪'),
  UlkeKodu('Katar', '+974', '🇶🇦'),
  UlkeKodu('Kayman Adaları', '+1345', '🇰🇾'),
  UlkeKodu('Kazakistan', '+7', '🇰🇿'),
  UlkeKodu('Kenya', '+254', '🇰🇪'),
  UlkeKodu('Kırgızistan', '+996', '🇰🇬'),
  UlkeKodu('Kiribati', '+686', '🇰🇮'),
  UlkeKodu('K.K.T.C / G.Kıbrıs', '+357', '🇨🇾'),
  UlkeKodu('Kolombiya', '+57', '🇨🇴'),
  UlkeKodu('Komorlar', '+269', '🇰🇲'),
  UlkeKodu('Kongo Cumhuriyeti', '+242', '🇨🇬'),
  UlkeKodu('Kongo Dem. Cum.', '+243', '🇨🇩'),
  UlkeKodu('Kosova', '+383', '🇽🇰'),
  UlkeKodu('Kosta Rika', '+506', '🇨🇷'),
  UlkeKodu('Kuveyt', '+965', '🇰🇼'),
  UlkeKodu('Kuzey Kore', '+850', '🇰🇵'),
  UlkeKodu('K. Makedonya', '+389', '🇲🇰'),
  UlkeKodu('Küba', '+53', '🇨🇺'),
  UlkeKodu('Laos', '+856', '🇱🇦'),
  UlkeKodu('Lesotho', '+266', '🇱🇸'),
  UlkeKodu('Letonya', '+371', '🇱🇻'),
  UlkeKodu('Liberya', '+231', '🇱🇷'),
  UlkeKodu('Libya', '+218', '🇱🇾'),
  UlkeKodu('Liechtenstein', '+423', '🇱🇮'),
  UlkeKodu('Litvanya', '+370', '🇱🇹'),
  UlkeKodu('Lübnan', '+961', '🇱🇧'),
  UlkeKodu('Lüksemburg', '+352', '🇱🇺'),
  UlkeKodu('Macaristan', '+36', '🇭🇺'),
  UlkeKodu('Madagaskar', '+261', '🇲🇬'),
  UlkeKodu('Makao', '+853', '🇲🇴'),
  UlkeKodu('Malavi', '+265', '🇲🇼'),
  UlkeKodu('Maldivler', '+960', '🇲🇻'),
  UlkeKodu('Malezya', '+60', '🇲🇾'),
  UlkeKodu('Mali', '+223', '🇲🇱'),
  UlkeKodu('Malta', '+356', '🇲🇹'),
  UlkeKodu('Marshall Adaları', '+692', '🇲🇭'),
  UlkeKodu('Martinik', '+596', '🇲🇶'),
  UlkeKodu('Mauritius', '+230', '🇲🇺'),
  UlkeKodu('Meksika', '+52', '🇲🇽'),
  UlkeKodu('Mikronezya', '+691', '🇫🇲'),
  UlkeKodu('Moğolistan', '+976', '🇲🇳'),
  UlkeKodu('Moldova', '+373', '🇲🇩'),
  UlkeKodu('Monako', '+377', '🇲🇨'),
  UlkeKodu('Moritanya', '+222', '🇲🇷'),
  UlkeKodu('Mozambik', '+258', '🇲🇿'),
  UlkeKodu('Myanmar', '+95', '🇲🇲'),
  UlkeKodu('Mısır', '+20', '🇪🇬'),
  UlkeKodu('Namibya', '+264', '🇳🇦'),
  UlkeKodu('Nauru', '+674', '🇳🇷'),
  UlkeKodu('Nepal', '+977', '🇳🇵'),
  UlkeKodu('Nijer', '+227', '🇳🇪'),
  UlkeKodu('Nijerya', '+234', '🇳🇬'),
  UlkeKodu('Nikaragua', '+505', '🇳🇮'),
  UlkeKodu('Norveç', '+47', '🇳🇴'),
  UlkeKodu('Orta Afrika Cum.', '+236', '🇨🇫'),
  UlkeKodu('Özbekistan', '+998', '🇺🇿'),
  UlkeKodu('Pakistan', '+92', '🇵🇰'),
  UlkeKodu('Palau', '+680', '🇵🇼'),
  UlkeKodu('Panama', '+507', '🇵🇦'),
  UlkeKodu('Papua Yeni Gine', '+675', '🇵🇬'),
  UlkeKodu('Paraguay', '+595', '🇵🇾'),
  UlkeKodu('Peru', '+51', '🇵🇪'),
  UlkeKodu('Polonya', '+48', '🇵🇱'),
  UlkeKodu('Portekiz', '+351', '🇵🇹'),
  UlkeKodu('Porto Riko', '+1787', '🇵🇷'),
  UlkeKodu('Réunion', '+262', '🇷🇪'),
  UlkeKodu('Romanya', '+40', '🇷🇴'),
  UlkeKodu('Ruanda', '+250', '🇷🇼'),
  UlkeKodu('Rusya', '+7', '🇷🇺'),
  UlkeKodu('Samoa', '+685', '🇼🇸'),
  UlkeKodu('San Marino', '+378', '🇸🇲'),
  UlkeKodu('Sao Tome ve Principe', '+239', '🇸🇹'),
  UlkeKodu('Senegal', '+221', '🇸🇳'),
  UlkeKodu('Seyşeller', '+248', '🇸🇨'),
  UlkeKodu('Sırbistan', '+381', '🇷🇸'),
  UlkeKodu('Sierra Leone', '+232', '🇸🇱'),
  UlkeKodu('Singapur', '+65', '🇸🇬'),
  UlkeKodu('Slovakya', '+421', '🇸🇰'),
  UlkeKodu('Slovenya', '+386', '🇸🇮'),
  UlkeKodu('Solomon Adaları', '+677', '🇸🇧'),
  UlkeKodu('Somali', '+252', '🇸🇴'),
  UlkeKodu('Sri Lanka', '+94', '🇱🇰'),
  UlkeKodu('Sudan', '+249', '🇸🇩'),
  UlkeKodu('Suriname', '+597', '🇸🇷'),
  UlkeKodu('Suriye', '+963', '🇸🇾'),
  UlkeKodu('Suudi Arabistan', '+966', '🇸🇦'),
  UlkeKodu('Şili', '+56', '🇨🇱'),
  UlkeKodu('Tacikistan', '+992', '🇹🇯'),
  UlkeKodu('Tanzanya', '+255', '🇹🇿'),
  UlkeKodu('Tayland', '+66', '🇹🇭'),
  UlkeKodu('Tayvan', '+886', '🇹🇼'),
  UlkeKodu('Togo', '+228', '🇹🇬'),
  UlkeKodu('Tonga', '+676', '🇹🇴'),
  UlkeKodu('Trinidad ve Tobago', '+1868', '🇹🇹'),
  UlkeKodu('Tunus', '+216', '🇹🇳'),
  UlkeKodu('Türkiye', '+90', '🇹🇷'),
  UlkeKodu('Türkmenistan', '+993', '🇹🇲'),
  UlkeKodu('Uganda', '+256', '🇺🇬'),
  UlkeKodu('Ukrayna', '+380', '🇺🇦'),
  UlkeKodu('Umman', '+968', '🇴🇲'),
  UlkeKodu('Uruguay', '+598', '🇺🇾'),
  UlkeKodu('Ürdün', '+962', '🇯🇴'),
  UlkeKodu('Vanuatu', '+678', '🇻🇺'),
  UlkeKodu('Vatikan', '+379', '🇻🇦'),
  UlkeKodu('Venezuela', '+58', '🇻🇪'),
  UlkeKodu('Vietnam', '+84', '🇻🇳'),
  UlkeKodu('Yemen', '+967', '🇾🇪'),
  UlkeKodu('Yeni Kaledonya', '+687', '🇳🇨'),
  UlkeKodu('Yeni Zelanda', '+64', '🇳🇿'),
  UlkeKodu('Yeşil Burun (Cabo Verde)', '+238', '🇨🇻'),
  UlkeKodu('Yunanistan', '+30', '🇬🇷'),
  UlkeKodu('Zambiya', '+260', '🇿🇲'),
  UlkeKodu('Zimbabve', '+263', '🇿🇼'),];

/// Web'deki telefon-ulke.js mantiginin Dart karsiligi.
class TelefonUlke {
  static const String varsayilanKod = '+90';

  static String rakam(String? s) => (s ?? '').replaceAll(RegExp(r'[^0-9]'), '');

  /// Bastaki 0(lar) atilmis ulusal numara
  static String ulusal(String? s) =>
      rakam(s).replaceFirst(RegExp(r'^0+'), '');

  /// Turkce duyarli arama normalizasyonu ("Arnavut" -> "arnavut")
  static String norm(String? s) {
    var t = (s ?? '').replaceAll('İ', 'i').replaceAll('I', 'ı').toLowerCase();
    return t
        .replaceAll('ı', 'i')
        .replaceAll('ş', 's')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll('â', 'a')
        .replaceAll('é', 'e');
  }

  /// TR gosterim bicimi: "532 123 45 67"
  /// Ulke kodu zaten "+90" gosterdigi icin basta 0 YOK (web ile ayni).
  /// Bastaki 0(lar) ve rakam disi karakterler atilir, 10 hane ile sinirlanir.
  static String trBicim(String? s) {
    var d = ulusal(s);
    if (d.length > 10) d = d.substring(0, 10);
    if (d.isEmpty) return '';
    final sb = StringBuffer();
    for (var i = 0; i < d.length; i++) {
      if (i == 3 || i == 6 || i == 8) sb.write(' ');
      sb.write(d[i]);
    }
    return sb.toString();
  }

  static UlkeKodu? kayitBul(String kod) {
    for (final u in ulkeKodlari) {
      if (u.kod == kod) return u;
    }
    return null;
  }

  /// Saklanan degeri (kod, gosterilecek numara) olarak coz.
  /// Gelen deger "+355691234567", "05321234567", "5321234567" olabilir.
  static MapEntry<String, String> coz(String? stored) {
    final s = (stored ?? '').trim();
    if (s.isEmpty || s == 'null' || s == '0') {
      return const MapEntry(varsayilanKod, '');
    }
    if (s.startsWith('+')) {
      var best = '';
      for (final u in ulkeKodlari) {
        // en uzun eslesen kod kazanir (+1 ile +1246 karismasin)
        if (s.startsWith(u.kod) && u.kod.length > best.length) best = u.kod;
      }
      if (best.isNotEmpty) {
        final kalan = rakam(s.substring(best.length));
        return MapEntry(best, best == varsayilanKod ? trBicim(kalan) : kalan);
      }
      return MapEntry(varsayilanKod, trBicim(rakam(s)));
    }
    return MapEntry(varsayilanKod, trBicim(rakam(s)));
  }

  /// Backend'e gidecek deger
  static String birlestir(String kod, String? numText) {
    final d = ulusal(numText);
    if (d.isEmpty) return '';
    if (kod == varsayilanKod) return d; // TR: duz 10 hane
    return '$kod$d'; // yabanci: +KOD + numara
  }

  static bool bos(String? numText) => ulusal(numText).isEmpty;
}

/// Ulke secme sayfasi (aramali). Secilen ulkeyi dondurur, iptalde null.
Future<UlkeKodu?> ulkeSecTara(BuildContext context, String seciliKod) {
  return showModalBottomSheet<UlkeKodu>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _UlkeSecSheet(seciliKod: seciliKod),
  );
}

class _UlkeSecSheet extends StatefulWidget {
  final String seciliKod;
  const _UlkeSecSheet({required this.seciliKod});

  @override
  State<_UlkeSecSheet> createState() => _UlkeSecSheetState();
}

class _UlkeSecSheetState extends State<_UlkeSecSheet> {
  final TextEditingController _ara = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _ara.dispose();
    super.dispose();
  }

  List<UlkeKodu> get _one =>
      ulkeKodlari.where((u) => u.one).toList(growable: false);

  List<UlkeKodu> get _tumu =>
      ulkeKodlari.where((u) => !u.one).toList(growable: false);

  bool _uyar(UlkeKodu u) {
    if (_q.isEmpty) return true;
    return TelefonUlke.norm(u.ad).contains(_q) ||
        u.kod.replaceAll('+', '').startsWith(_q);
  }

  @override
  Widget build(BuildContext context) {
    final aramaVar = _q.isNotEmpty;
    final one = aramaVar ? const <UlkeKodu>[] : _one;
    final tumu = (aramaVar ? ulkeKodlari : _tumu).where(_uyar).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _ara,
                  autofocus: false,
                  decoration: const InputDecoration(
                    hintText: 'Ülke veya kod ara...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(
                      () => _q = TelefonUlke.norm(v.replaceAll('+', '')).trim()),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: (one.isEmpty ? 0 : one.length + 1) +
                      (tumu.isEmpty ? 0 : tumu.length + 1),
                  itemBuilder: (context, i) {
                    if (one.isNotEmpty) {
                      if (i == 0) return _baslik('Sık kullanılan');
                      if (i <= one.length) return _satir(one[i - 1]);
                      i -= one.length + 1;
                    }
                    if (tumu.isEmpty) return const SizedBox.shrink();
                    if (i == 0) {
                      return _baslik(aramaVar ? 'Sonuçlar' : 'Tüm ülkeler');
                    }
                    return _satir(tumu[i - 1]);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _baslik(String s) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
        child: Text(
          s.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: .5,
            color: Colors.grey.shade600,
          ),
        ),
      );

  Widget _satir(UlkeKodu u) {
    final secili = u.kod == widget.seciliKod;
    return ListTile(
      leading: Text(u.bayrak, style: const TextStyle(fontSize: 24)),
      title: Text(u.ad,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      trailing: Text(
        u.kod,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: secili ? Theme.of(context).colorScheme.primary : Colors.grey[600],
        ),
      ),
      selected: secili,
      onTap: () => Navigator.of(context).pop(u),
    );
  }
}

/// Ulke kodu butonu + numara alani.
/// [controller].text her zaman BACKEND'E GIDECEK degeri tutar.
class TelefonUlkeAlani extends StatefulWidget {
  final TextEditingController controller;
  final String? label;
  final String? hint;
  final bool enabled;
  final InputDecoration? decoration;
  final String? Function(String?)? validator;
  final void Function(String deger)? onChanged;

  /// false ise ulke butonu kendi cercevesini cizmez — ekran kendi kutusunun
  /// icine koyabilsin diye (yeni_musteri gibi ozel tasarimli formlar).
  final bool cerceveli;
  final TextStyle? style;
  final Color? cursorColor;

  /// Vurgu rengi (acilir ok + imlec). Verilmezse temanin primary rengi.
  final Color? renk;

  const TelefonUlkeAlani({
    Key? key,
    required this.controller,
    this.label,
    this.hint,
    this.enabled = true,
    this.decoration,
    this.validator,
    this.onChanged,
    this.cerceveli = true,
    this.style,
    this.cursorColor,
    this.renk,
  }) : super(key: key);

  @override
  State<TelefonUlkeAlani> createState() => _TelefonUlkeAlaniState();
}

/// TR numarasi icin bicimlendirici: rakam disini atar, bastaki 0(lar)i siler,
/// 10 hane ile sinirlar ve "### ### ## ##" bicimine sokar.
/// (Sabit maske yerine bunu kullaniyoruz ki yapistirilan "0532..." veya
///  "+90 532..." degerleri de dogru bicimlensin.)
class _TrTelefonFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = TelefonUlke.trBicim(newValue.text);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _TelefonUlkeAlaniState extends State<TelefonUlkeAlani> {
  late String _kod;
  late TextEditingController _num;
  final _trFmt = _TrTelefonFormatter();
  String _sonYazilan = ''; // disaridan gelen degisikligi ayirt etmek icin

  @override
  void initState() {
    super.initState();
    final p = TelefonUlke.coz(widget.controller.text);
    _kod = p.key;
    _num = TextEditingController(text: p.value);
    _sonYazilan = TelefonUlke.birlestir(_kod, _num.text);
    widget.controller.text = _sonYazilan;
    widget.controller.addListener(_disaridanGeldi);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_disaridanGeldi);
    _num.dispose();
    super.dispose();
  }

  // Ekran kodu controller.text'i dogrudan degistirdiyse (ornegin AJAX sonrasi)
  void _disaridanGeldi() {
    if (widget.controller.text == _sonYazilan) return;
    final p = TelefonUlke.coz(widget.controller.text);
    _sonYazilan = TelefonUlke.birlestir(p.key, p.value);
    if (!mounted) return;
    setState(() {
      _kod = p.key;
      _num.text = p.value;
    });
  }

  void _yaz() {
    _sonYazilan = TelefonUlke.birlestir(_kod, _num.text);
    widget.controller.text = _sonYazilan;
    if (widget.onChanged != null) widget.onChanged!(_sonYazilan);
  }

  Future<void> _ulkeSec() async {
    final u = await ulkeSecTara(context, _kod);
    if (u == null || !mounted) return;
    final d = TelefonUlke.ulusal(_num.text);
    setState(() {
      _kod = u.kod;
      _num.text = u.kod == TelefonUlke.varsayilanKod
          ? TelefonUlke.trBicim(d)
          : d;
    });
    _yaz();
  }

  @override
  Widget build(BuildContext context) {
    final tr = _kod == TelefonUlke.varsayilanKod;
    final u = TelefonUlke.kayitBul(_kod);
    final taban = widget.decoration ??
        InputDecoration(
          labelText: widget.label ?? 'Telefon',
          prefixIcon: const Icon(Icons.phone_outlined),
        );

    final renk = widget.renk ?? Theme.of(context).colorScheme.primary;

    return Row(
      crossAxisAlignment:
          widget.cerceveli ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Padding(
          padding: EdgeInsets.only(top: widget.cerceveli ? 4 : 0),
          child: InkWell(
            onTap: widget.enabled ? _ulkeSec : null,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: widget.cerceveli ? 10 : 4,
                  vertical: widget.cerceveli ? 14 : 6),
              decoration: widget.cerceveli
                  ? BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    )
                  : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(u?.bayrak ?? '🌐',
                      style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 4),
                  Text(
                    _kod,
                    style: (widget.style ?? const TextStyle())
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                  if (widget.enabled)
                    Icon(Icons.arrow_drop_down, color: renk, size: 20),
                ],
              ),
            ),
          ),
        ),
        // Cerceve yoksa (mevcut kutunun icine gomuluyorsa) ince ayirac cizgisi
        if (!widget.cerceveli) ...[
          const SizedBox(width: 6),
          Container(width: 1, height: 22, color: Colors.grey.shade300),
          const SizedBox(width: 8),
        ],
        SizedBox(width: widget.cerceveli ? 8 : 0),
        Expanded(
          child: TextFormField(
            controller: _num,
            enabled: widget.enabled,
            keyboardType: TextInputType.phone,
            maxLines: 1,
            style: widget.style,
            cursorColor: widget.cursorColor ?? renk,
            decoration: taban.copyWith(
              hintText: widget.hint ?? (tr ? '### ### ## ##' : 'Numara'),
            ),
            inputFormatters: tr
                ? [_trFmt]
                : [FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))],
            validator: widget.validator ??
                (v) => TelefonUlke.bos(v) ? 'Telefon alanı gereklidir' : null,
            onChanged: (v) => _yaz(),
          ),
        ),
      ],
    );
  }
}

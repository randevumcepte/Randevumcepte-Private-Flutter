import 'dart:convert';

class _Kalip {
  final RegExp desen;
  final String ceviri;
  final String sabit; // hızlı ön eleme: kalıptaki en uzun sabit parça
  const _Kalip(this.desen, this.ceviri, this.sabit);
}

/// Türkçe metin -> seçili dil. Kurallar sunucu (App\Services\MusteriDili) ve web (musteri-dil.js) ile AYNI:
/// birebir, boşluk/büyük harf farkı, {} kalıpları, tarih adları, baş/son simge, parçalar (· • , satır, cümle).
/// Bulunamayan metin Türkçe kalır.
class Ceviri {
  static String dil = 'tr';
  static String surum = '';
  static Map<String, String> _s = {};
  static Map<String, String> _kucuk = {};
  static List<_Kalip> _kaliplar = [];
  static final Map<String, String> _onbellek = {};

  static const _aylar = ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
  static const _ayKisa = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
  static const _gunler = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
  static const _gunKisa = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
  static const Map<String, List<String>> _ayUzunD = {
    'en': ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'],
    'ru': ['января', 'февраля', 'марта', 'апреля', 'мая', 'июня', 'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'],
    'de': ['Januar', 'Februar', 'März', 'April', 'Mai', 'Juni', 'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember'],
  };
  static const Map<String, List<String>> _ayYalinD = {
    'ru': ['Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь', 'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'],
  };
  static const Map<String, List<String>> _ayKisaD = {
    'en': ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
    'ru': ['янв', 'фев', 'мар', 'апр', 'мая', 'июн', 'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'],
    'de': ['Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun', 'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'],
  };

  static void yukle(String yeniDil, String ham) {
    final j = jsonDecode(ham) as Map;
    final s = <String, String>{};
    final kucuk = <String, String>{};
    final kaliplar = <_Kalip>[];
    (j['sozluk'] as Map).forEach((k, v) {
      final tr = k.toString(), c = v.toString();
      if (tr.contains('{}') || tr.contains('{#}')) {
        kaliplar.add(_kalip(tr, c));
        return;
      }
      s[tr] = c;
      s.putIfAbsent(_bosluk(tr), () => c);
      kucuk.putIfAbsent(_kucult(_bosluk(tr)), () => c);
    });
    // Önce en çok sabit harf içeren kalıp denenir (özel kalıp genel kalıptan önce)
    kaliplar.sort((a, b) => b.desen.pattern.length.compareTo(a.desen.pattern.length));
    dil = yeniDil;
    surum = (j['surum'] ?? '').toString();
    _s = s;
    _kucuk = kucuk;
    _kaliplar = kaliplar;
    _onbellek.clear();
  }

  static _Kalip _kalip(String tr, String c) {
    final b = StringBuffer('^');
    var enUzun = '';
    for (final p in tr.split(RegExp(r'(?=\{[#]?\})|(?<=\{\})|(?<=\{#\})'))) {
      if (p == '{}') {
        b.write(r'([^\n]+?)');
      } else if (p == '{#}') {
        b.write(r'([\d.,:%+\-/]+)');
      } else {
        final duz = p.trim();
        if (duz.length > enUzun.length) enUzun = duz;
        b.write(p.splitMapJoin(RegExp(r'\s+'),
            onMatch: (m) => m.group(0)!.contains('\n') ? r'\s*\n\s*' : r'[^\S\n]+', onNonMatch: RegExp.escape));
      }
    }
    b.write(r'$');
    // Ön eleme parçası tek kelimelik boşluksuz olsun (metindeki satır sonu farkı elemesin)
    final kelimeler = enUzun.split(RegExp(r'\s+'))..sort((x, y) => y.length.compareTo(x.length));
    return _Kalip(RegExp(b.toString()), c, kelimeler.isEmpty ? '' : kelimeler.first);
  }

  static String _bosluk(String s) => s.replaceAll(RegExp(r'\s+'), ' ').trim();
  static String _kucult(String s) => s.replaceAll('I', 'ı').replaceAll('İ', 'i').toLowerCase();
  static bool _harf(String s) => RegExp(r'[A-Za-zÇĞİÖŞÜçğıöşü]').hasMatch(s);

  static String cevir(String metin) {
    if (dil == 'tr' || metin.isEmpty || !_harf(metin)) return metin;
    final hazir = _onbellek[metin];
    if (hazir != null) return hazir;
    final bas = metin.length - metin.trimLeft().length;
    final son = metin.trimRight().length;
    final oz = bas >= son ? '' : metin.substring(bas, son);
    final c = oz.isEmpty ? null : _bul(oz, 0);
    final sonuc = c == null ? metin : metin.substring(0, bas) + c + metin.substring(son);
    if (_onbellek.length > 3000) _onbellek.clear();
    _onbellek[metin] = sonuc;
    return sonuc;
  }

  static String? _tam(String s) {
    final v = _s[s] ?? _s[_bosluk(s)];
    if (v != null) return v;
    if (s.trim().length < 3) return null; // "AD" baş harfleri "Ad" sanılmasın
    final k = _kucuk[_kucult(_bosluk(s))];
    if (k == null) return null;
    final hepBuyuk = s.length > 2 && s == s.toUpperCase() && s != s.toLowerCase();
    return hepBuyuk ? k.toUpperCase() : k;
  }

  static String? _bul(String s, int derin) {
    final t = _tam(s);
    if (t != null) return t;
    if (derin > 3) return null;

    for (final k in _kaliplar) {
      if (k.sabit.isNotEmpty && !s.contains(k.sabit)) continue;
      final m = k.desen.firstMatch(s);
      if (m == null) continue;
      var sira = 0;
      return k.ceviri.replaceAllMapped(RegExp(r'\{(\d?)#?\}'), (x) {
        final no = x.group(1)!.isEmpty ? ++sira : int.parse(x.group(1)!);
        final parca = (no <= m.groupCount ? m.group(no) : null) ?? '';
        if (!_harf(parca) || _aylar.contains(parca.trim())) return parca; // "Sayın Eylül" kişi adı
        return _bul(parca.trim(), derin + 1) ?? parca;
      });
    }

    // Çok satırlı metin satır satır (baş/son simge ayıklamadan ÖNCE: satırlar bozulmasın)
    if (s.contains('\n')) return _parcala(s, '\n', derin);

    final saatli = RegExp(r'^(\d{1,2}[:.]\d{2}) +(.+)$').firstMatch(s); // "14:00 Manikür"
    if (saatli != null) {
      final c = _bul(saatli.group(2)!, derin + 1);
      if (c != null) return '${saatli.group(1)} $c';
    }

    final tarihli = _tarih(s);
    if (tarihli != null && !_turkceKaldi(tarihli, s)) return tarihli;

    // Baş/son simge, emoji, iki nokta...
    final ic = RegExp(r'^([^A-Za-zÇĞİÖŞÜçğıöşü0-9%]*)([\s\S]*?)([^A-Za-zÇĞİÖŞÜçğıöşü0-9%)]*)$').firstMatch(s);
    if (ic != null && (ic.group(1)!.isNotEmpty || ic.group(3)!.isNotEmpty) && ic.group(2)!.isNotEmpty) {
      final c = _bul(ic.group(2)!, derin + 1);
      if (c != null) return ic.group(1)! + c + ic.group(3)!;
    }

    final cumleler = s.split(RegExp(r'(?<=[.!?])\s+'));
    if (cumleler.length > 1) {
      var degisti = false;
      final c = cumleler.map((x) {
        final y = _bul(x.trim(), derin + 1);
        if (y != null) degisti = true;
        return y ?? x;
      }).toList();
      if (degisti) return c.join(' ');
    }

    for (final ayrac in const [' • ', ' · ', '  ·  ', ' | ', ' — ', ' – ', ' / ', ' + ', ', ', ': ']) {
      if (!s.contains(ayrac)) continue;
      final p = _parcala(s, ayrac, derin);
      if (p != null) return p;
    }
    return tarihli;
  }

  static String? _parcala(String s, String ayrac, int derin) {
    var degisti = false, hepsi = true;
    final c = s.split(ayrac).map((x) {
      if (x.trim().isEmpty || !_harf(x)) return x;
      final y = _bul(x.trim(), derin + 1);
      y != null ? degisti = true : hepsi = false;
      return y ?? x;
    }).toList();
    // Virgüllü cümle yarım çevrilmesin: virgülde parçaların hepsi bilinmeli
    if (ayrac == ', ' && !hepsi) return null;
    return degisti ? c.join(ayrac) : null;
  }

  static bool _turkceKaldi(String yeni, String eski) {
    // Tarih dışında harf kaldıysa tam çevrilmiş sayılmaz (parçalara bakılsın)
    final kalan = eski.replaceAll(RegExp(_aylar.join('|')), '').replaceAll(RegExp(_gunler.join('|')), '')
        .replaceAll(RegExp('\\b(${_ayKisa.join('|')}|${_gunKisa.join('|')})\\b'), '');
    return _harf(kalan);
  }

  /// "25 Kasım 2026, Salı" / "Kasım 2026" / "25 Kas" / "Sal 25" -> seçili dil; tarih yoksa null.
  static String? _tarih(String s) {
    if (!_ayUzunD.containsKey(dil)) return null;
    var r = s;
    r = r.replaceAllMapped(RegExp('(\\d{1,2}) (${_aylar.join('|')})(?![A-Za-zçğıöşü])'), (m) {
      final ay = _ayUzunD[dil]![_aylar.indexOf(m.group(2)!)];
      return dil == 'de' ? '${m.group(1)}. $ay' : '${m.group(1)} $ay';
    });
    r = r.replaceAllMapped(RegExp('(\\d{1,2}) (${_ayKisa.join('|')})(?![A-Za-zçğıöşü])'), (m) {
      final ay = _ayKisaD[dil]![_ayKisa.indexOf(m.group(2)!)];
      return dil == 'de' ? '${m.group(1)}. $ay' : '${m.group(1)} $ay';
    });
    r = r.replaceAllMapped(RegExp('(?<![A-Za-zçğıöşü])(${_aylar.join('|')}) (\\d{4})'), (m) {
      final i = _aylar.indexOf(m.group(1)!);
      return '${(_ayYalinD[dil] ?? _ayUzunD[dil]!)[i]} ${m.group(2)}';
    });
    r = r.replaceAllMapped(RegExp('(?<![A-Za-zçğıöşüÇĞİÖŞÜ])(${([..._gunler]..sort((a, b) => b.length - a.length)).join('|')})(?![A-Za-zçğıöşü])'),
        (m) => _s[m.group(1)!] ?? m.group(1)!);
    if (RegExp(r'\d').hasMatch(s)) {
      r = r.replaceAllMapped(RegExp('(?<![A-Za-zçğıöşüÇĞİÖŞÜ])(${_gunKisa.join('|')})(?![A-Za-zçğıöşü])'), (m) => _s[m.group(1)!] ?? m.group(1)!);
    }
    return r == s ? null : r;
  }
}

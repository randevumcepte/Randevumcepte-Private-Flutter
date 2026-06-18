// Salon hatirlatma (reminder/toast) modeli.
// Backend: GET /api/v1/hatirlatma-feed?sube=... (HatirlatmaApiController@feed)
// Alan adlari web JSON cevabiyla birebir.

class Hatirlatma {
  final String id;
  final String tip;
  final int oncelik;
  final String tema;
  final String emoji;
  final String baslik;
  final String mesaj;
  final String altMesaj;
  final String ctaText;
  final String link;
  final int sayac;
  // Cagri merkezi arama randevusu icin:
  final String? aksiyon; // 'arama_baslat'
  final int? aranacakMusteriId;
  final String? sonSes;

  Hatirlatma({
    required this.id,
    required this.tip,
    required this.oncelik,
    required this.tema,
    required this.emoji,
    required this.baslik,
    required this.mesaj,
    required this.altMesaj,
    required this.ctaText,
    required this.link,
    required this.sayac,
    this.aksiyon,
    this.aranacakMusteriId,
    this.sonSes,
  });

  /// Dismiss anahtari: sayac degisince yeni kart sayilir (web ile ayni mantik).
  String get anahtar => '$id:$sayac';

  factory Hatirlatma.fromJson(Map<String, dynamic> j) {
    int toInt(dynamic v) {
      if (v is int) return v;
      if (v is double) return v.toInt();
      return int.tryParse('${v ?? ''}') ?? 0;
    }

    int? toIntN(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is double) return v.toInt();
      return int.tryParse('$v');
    }

    String s(dynamic v) => v == null ? '' : v.toString();

    return Hatirlatma(
      id: s(j['id']),
      tip: s(j['tip']),
      oncelik: toInt(j['oncelik']),
      tema: s(j['tema']),
      emoji: s(j['emoji']),
      baslik: s(j['baslik']),
      mesaj: s(j['mesaj']),
      altMesaj: s(j['altMesaj']),
      ctaText: s(j['cta_text']),
      link: s(j['link']),
      sayac: toInt(j['sayac']),
      aksiyon: j['aksiyon'] == null ? null : s(j['aksiyon']),
      aranacakMusteriId: toIntN(j['aranacak_musteri_id']),
      sonSes: j['son_ses'] == null ? null : s(j['son_ses']),
    );
  }
}

// Cagri Merkezi (Call Center) veri modelleri.
// Backend: /api/v1/cagri-merkezi/* (CagriMerkeziApiController).
// Alan adlari web panelindeki JSON cevaplarla BIRE BIR ayni tutulmustur.

int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is double) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

int? _toIntN(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  return int.tryParse(v.toString());
}

double _toDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString().replaceAll(',', '.')) ?? 0;
}

double? _toDoubleN(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString().replaceAll(',', '.'));
}

String _toStr(dynamic v) => v == null ? '' : v.toString();
String? _toStrN(dynamic v) => v == null ? null : v.toString();

/// Arama listesi karti (dialer ana ekran).
class AramaKart {
  final int id;
  final String baslik;
  final String? personel;
  final String? aranacakTarih;
  final int toplam;
  final int arandi;
  final int kalan;
  final int ilerleme;

  AramaKart({
    required this.id,
    required this.baslik,
    this.personel,
    this.aranacakTarih,
    required this.toplam,
    required this.arandi,
    required this.kalan,
    required this.ilerleme,
  });

  factory AramaKart.fromJson(Map<String, dynamic> j) => AramaKart(
        id: _toInt(j['id']),
        baslik: _toStr(j['baslik']),
        personel: _toStrN(j['personel']),
        aranacakTarih: _toStrN(j['aranacak_tarih']),
        toplam: _toInt(j['toplam']),
        arandi: _toInt(j['arandi']),
        kalan: _toInt(j['kalan']),
        ilerleme: _toInt(j['ilerleme']),
      );
}

/// Kuyruktaki aranacak musteri (KVKK: personel icin maskeli gelir).
class AranacakMusteri {
  final int aranacakMusteriId;
  final String ad;
  final String? telefon; // sadece yoneticiye gelir, personele null
  final String telefonGizlenmis;
  final String durum;
  final int? durumKod;
  final String not;
  final String notTarih;
  final String notSaat;
  final String ses;

  AranacakMusteri({
    required this.aranacakMusteriId,
    required this.ad,
    this.telefon,
    required this.telefonGizlenmis,
    required this.durum,
    this.durumKod,
    required this.not,
    required this.notTarih,
    required this.notSaat,
    required this.ses,
  });

  factory AranacakMusteri.fromJson(Map<String, dynamic> j) => AranacakMusteri(
        aranacakMusteriId: _toInt(j['aranacak_musteri_id']),
        ad: _toStr(j['ad']),
        telefon: _toStrN(j['telefon']),
        telefonGizlenmis: _toStr(j['telefonGizlenmis']),
        durum: _toStr(j['durum']),
        durumKod: _toIntN(j['durum_kod']),
        not: _toStr(j['not']),
        notTarih: _toStr(j['not_tarih']),
        notSaat: _toStr(j['not_saat']),
        ses: _toStr(j['ses']),
      );
}

class ListeDetay {
  final List<AranacakMusteri> data;
  final int total;
  final int page;
  final int perPage;

  ListeDetay({
    required this.data,
    required this.total,
    required this.page,
    required this.perPage,
  });

  factory ListeDetay.fromJson(Map<String, dynamic> j) => ListeDetay(
        data: ((j['data'] as List?) ?? [])
            .map((e) => AranacakMusteri.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        total: _toInt(j['total']),
        page: _toInt(j['page']),
        perPage: _toInt(j['perPage']),
      );
}

/// Bir musterinin gecmis gorusmesi (cogul). Ses kaydiyla birlikte.
class CagriGecmis {
  final String tarih;
  final int? sonucKod;
  final String sonuc;
  final String not;
  final String ses;
  final String randevuTarih;
  final String randevuSaat;
  final double? satisTutari;

  CagriGecmis({
    required this.tarih,
    this.sonucKod,
    required this.sonuc,
    required this.not,
    required this.ses,
    required this.randevuTarih,
    required this.randevuSaat,
    this.satisTutari,
  });

  factory CagriGecmis.fromJson(Map<String, dynamic> j) => CagriGecmis(
        tarih: _toStr(j['tarih']),
        sonucKod: _toIntN(j['sonuc_kod']),
        sonuc: _toStr(j['sonuc']),
        not: _toStr(j['not']),
        ses: _toStr(j['ses']),
        randevuTarih: _toStr(j['randevu_tarih']),
        randevuSaat: _toStr(j['randevu_saat']),
        satisTutari: _toDoubleN(j['satis_tutari']),
      );
}

/// Dashboard personel performans karti.
class PersonelKart {
  final int personelId;
  final String ad;
  final int atanan;
  final int aranan;
  final int kalan;
  final int cevapsiz;
  final int konusulan;
  final int ulasilamadi;
  final int randevu;
  final int ongorusme;
  final int satis;
  final int toplamDk;
  final int gorusmeSayisi;
  final double satisCirosu;

  PersonelKart({
    required this.personelId,
    required this.ad,
    required this.atanan,
    required this.aranan,
    required this.kalan,
    required this.cevapsiz,
    required this.konusulan,
    required this.ulasilamadi,
    required this.randevu,
    required this.ongorusme,
    required this.satis,
    required this.toplamDk,
    required this.gorusmeSayisi,
    required this.satisCirosu,
  });

  factory PersonelKart.fromJson(Map<String, dynamic> j) => PersonelKart(
        personelId: _toInt(j['personel_id']),
        ad: _toStr(j['ad']),
        atanan: _toInt(j['atanan']),
        aranan: _toInt(j['aranan']),
        kalan: _toInt(j['kalan']),
        cevapsiz: _toInt(j['cevapsiz']),
        konusulan: _toInt(j['konusulan']),
        ulasilamadi: _toInt(j['ulasilamadi']),
        randevu: _toInt(j['randevu']),
        ongorusme: _toInt(j['ongorusme']),
        satis: _toInt(j['satis']),
        toplamDk: _toInt(j['toplam_dk']),
        gorusmeSayisi: _toInt(j['gorusme_sayisi']),
        satisCirosu: _toDouble(j['satis_cirosu']),
      );
}

/// Dashboard personel detayindaki tek gorusme notu.
class DashboardNot {
  final String musteri;
  final String not;
  final String sonuc;
  final int? sonucKod;
  final int sureDk;
  final String kategori;
  final String altKategori;
  final double? satisTutari;
  final String ses;
  final String tarih;

  DashboardNot({
    required this.musteri,
    required this.not,
    required this.sonuc,
    this.sonucKod,
    required this.sureDk,
    required this.kategori,
    required this.altKategori,
    this.satisTutari,
    required this.ses,
    required this.tarih,
  });

  factory DashboardNot.fromJson(Map<String, dynamic> j) => DashboardNot(
        musteri: _toStr(j['musteri']),
        not: _toStr(j['not']),
        sonuc: _toStr(j['sonuc']),
        sonucKod: _toIntN(j['sonuc_kod']),
        sureDk: _toInt(j['sure_dk']),
        kategori: _toStr(j['kategori']),
        altKategori: _toStr(j['alt_kategori']),
        satisTutari: _toDoubleN(j['satis_tutari']),
        ses: _toStr(j['ses']),
        tarih: _toStr(j['tarih']),
      );
}

/// Zamani gelen geri-arama hatirlatmasi.
class YaklasanRandevu {
  final int id;
  final int aramaId;
  final String ad;
  final String tarih;
  final String saat;

  YaklasanRandevu({
    required this.id,
    required this.aramaId,
    required this.ad,
    required this.tarih,
    required this.saat,
  });

  factory YaklasanRandevu.fromJson(Map<String, dynamic> j) => YaklasanRandevu(
        id: _toInt(j['id']),
        aramaId: _toInt(j['arama_id']),
        ad: _toStr(j['ad']),
        tarih: _toStr(j['tarih']),
        saat: _toStr(j['saat']),
      );
}

/// On gorusme icin gercek musteri bilgisi.
class OngorusmeBilgi {
  final int userId;
  final String ad;
  final String telefon;

  OngorusmeBilgi({required this.userId, required this.ad, required this.telefon});

  factory OngorusmeBilgi.fromJson(Map<String, dynamic> j) => OngorusmeBilgi(
        userId: _toInt(j['user_id']),
        ad: _toStr(j['ad']),
        telefon: _toStr(j['telefon']),
      );
}

/// Liste sonuc segmenti (yonetici).
class CagriSegment {
  final String kod;
  final String ad;
  final int adet;

  CagriSegment({required this.kod, required this.ad, required this.adet});

  factory CagriSegment.fromJson(Map<String, dynamic> j) => CagriSegment(
        kod: _toStr(j['kod']),
        ad: _toStr(j['ad']),
        adet: _toInt(j['adet']),
      );
}

class SegmentSonuc {
  final String baslik;
  final int? personelId;
  final String personelAd;
  final List<CagriSegment> segmentler;

  SegmentSonuc({
    required this.baslik,
    this.personelId,
    required this.personelAd,
    required this.segmentler,
  });

  factory SegmentSonuc.fromJson(Map<String, dynamic> j) => SegmentSonuc(
        baslik: _toStr(j['baslik']),
        personelId: _toIntN(j['personel_id']),
        personelAd: _toStr(j['personel_ad']),
        segmentler: ((j['segmentler'] as List?) ?? [])
            .map((e) => CagriSegment.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

/// Basit personel (atama dropdown'lari icin). Endpoint: {id, personel_adi}
class CagriPersonel {
  final int id;
  final String ad;

  CagriPersonel({required this.id, required this.ad});

  factory CagriPersonel.fromJson(Map<String, dynamic> j) => CagriPersonel(
        id: _toInt(j['id']),
        ad: _toStr(j['personel_adi'] ?? j['ad']),
      );
}

/// Arama Listesi Olustur ekraninda filtreye uyan tek musteri satiri.
class FiltreMusteri {
  final int id;
  final String name;
  final String telefon;

  FiltreMusteri({required this.id, required this.name, required this.telefon});

  factory FiltreMusteri.fromJson(Map<String, dynamic> j) => FiltreMusteri(
        id: _toInt(j['id']),
        name: _toStr(j['name']),
        telefon: _toStr(j['cep_telefon']),
      );
}

/// Filtre onizleme cevabi: eslesen sayi + isme gore sirali TUM id'ler + sayfali liste.
class FiltreOnizleme {
  final int total;
  final int toplamFiltresiz;
  final List<int> musteriIdler;
  final List<FiltreMusteri> customers;

  FiltreOnizleme({
    required this.total,
    required this.toplamFiltresiz,
    required this.musteriIdler,
    required this.customers,
  });

  factory FiltreOnizleme.fromJson(Map<String, dynamic> j) => FiltreOnizleme(
        total: _toInt(j['total']),
        toplamFiltresiz: _toInt(j['toplam_filtresiz']),
        musteriIdler:
            ((j['musteriIdler'] as List?) ?? []).map(_toInt).toList(),
        customers: ((j['customers'] as List?) ?? [])
            .map((e) => FiltreMusteri.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

class CagriScript {
  final int id;
  final String baslik;
  final String icerik;

  CagriScript({required this.id, required this.baslik, required this.icerik});

  factory CagriScript.fromJson(Map<String, dynamic> j) => CagriScript(
        id: _toInt(j['id']),
        baslik: _toStr(j['baslik']),
        icerik: _toStr(j['icerik']),
      );
}

class AltKategori {
  final int id;
  final String ad;
  AltKategori({required this.id, required this.ad});
  factory AltKategori.fromJson(Map<String, dynamic> j) =>
      AltKategori(id: _toInt(j['id']), ad: _toStr(j['ad']));
}

class CagriKategori {
  final int id;
  final String ad;
  final List<AltKategori> altlar;
  CagriKategori({required this.id, required this.ad, required this.altlar});
  factory CagriKategori.fromJson(Map<String, dynamic> j) => CagriKategori(
        id: _toInt(j['id']),
        ad: _toStr(j['ad']),
        altlar: ((j['altlar'] as List?) ?? [])
            .map((e) => AltKategori.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

/// Arama baslatma sonucu.
class AramaBaslatSonuc {
  final bool success;
  final String message;
  final int? aramaListeId;
  AramaBaslatSonuc({required this.success, required this.message, this.aramaListeId});
  factory AramaBaslatSonuc.fromJson(Map<String, dynamic> j) => AramaBaslatSonuc(
        success: j['success'] == true,
        message: _toStr(j['message']),
        aramaListeId: _toIntN(j['aramaListeId']),
      );
}

/// Aranacak musteri durum kodu -> renk/etiket yardimcilari (web ile ayni semantik).
class CagriDurum {
  static const int ulasilamadi = 0;
  static const int arandi = 1;
  static const int cevapsiz = 2;
  static const int tekrarAranacak = 3;
  static const int gorusuldu = 4;
  static const int mesgul = 5;
  static const int onGorusme = 6;
  static const int telefondaSatis = 7;

  static String etiket(int? kod) {
    switch (kod) {
      case 1:
        return 'Arandı';
      case 0:
        return 'Ulaşılamadı';
      case 2:
        return 'Cevapsız';
      case 3:
        return 'Tekrar Aranacak';
      case 4:
        return 'Görüşüldü';
      case 5:
        return 'Meşgul';
      case 6:
        return 'Ön Görüşme Randevusu';
      case 7:
        return 'Telefonda Satış';
      default:
        return 'Bekliyor';
    }
  }
}

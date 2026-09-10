// Grup dersi (Pilates/kurs) modelleri — backend /api/v1 ders_* endpointleri.
// fromJson kalibi projedeki diger modellerle ayni (guvenli .toString() cevrimi).

class GrupDersOturum {
  final int id;
  final String dersTipi;
  final String? hizmetId;
  final String tarih;
  final String saat;
  final String saatBitis;
  final int kapasite;
  final String? personelId;
  final String personel;
  final int doluluk;

  GrupDersOturum({
    required this.id,
    required this.dersTipi,
    required this.hizmetId,
    required this.tarih,
    required this.saat,
    required this.saatBitis,
    required this.kapasite,
    required this.personelId,
    required this.personel,
    required this.doluluk,
  });

  factory GrupDersOturum.fromJson(Map<String, dynamic> j) => GrupDersOturum(
        id: int.tryParse(j['id'].toString()) ?? 0,
        dersTipi: (j['ders_tipi'] ?? 'Grup Dersi').toString(),
        hizmetId: j['hizmet_id']?.toString(),
        tarih: (j['tarih'] ?? '').toString(),
        saat: (j['saat'] ?? '').toString(),
        saatBitis: (j['saat_bitis'] ?? '').toString(),
        kapasite: int.tryParse(j['kapasite'].toString()) ?? 1,
        personelId: j['personel_id']?.toString(),
        personel: (j['personel'] ?? '').toString(),
        doluluk: int.tryParse(j['doluluk'].toString()) ?? 0,
      );
}

class GrupDersKatilimci {
  final int id;
  final String userId;
  final String ad;
  final String tel;
  final String durum; // rezerve | geldi | gelmedi | bekleme | iptal

  GrupDersKatilimci({
    required this.id,
    required this.userId,
    required this.ad,
    required this.tel,
    required this.durum,
  });

  factory GrupDersKatilimci.fromJson(Map<String, dynamic> j) => GrupDersKatilimci(
        id: int.tryParse(j['id'].toString()) ?? 0,
        userId: j['user_id'].toString(),
        ad: (j['ad'] ?? '').toString(),
        tel: (j['tel'] ?? '').toString(),
        durum: (j['durum'] ?? 'rezerve').toString(),
      );
}

class GrupDersSablon {
  final int id;
  final int haftaGunu; // 1=Pzt..7=Paz
  final String dersTipi;
  final String? hizmetId;
  final String? personelId;
  final String personel;
  final String saat;
  final String saatBitis;
  final int kapasite;

  GrupDersSablon({
    required this.id,
    required this.haftaGunu,
    required this.dersTipi,
    required this.hizmetId,
    required this.personelId,
    required this.personel,
    required this.saat,
    required this.saatBitis,
    required this.kapasite,
  });

  factory GrupDersSablon.fromJson(Map<String, dynamic> j) => GrupDersSablon(
        id: int.tryParse(j['id'].toString()) ?? 0,
        haftaGunu: int.tryParse(j['hafta_gunu'].toString()) ?? 1,
        dersTipi: (j['ders_tipi'] ?? 'Grup Dersi').toString(),
        hizmetId: j['hizmet_id']?.toString(),
        personelId: j['personel_id']?.toString(),
        personel: (j['personel'] ?? '').toString(),
        saat: (j['saat'] ?? '').toString(),
        saatBitis: (j['saat_bitis'] ?? '').toString(),
        kapasite: int.tryParse(j['kapasite'].toString()) ?? 1,
      );
}

// Basit ad/id cifti (personel + hizmet dropdownlari icin)
class GrupDersSecenek {
  final String id;
  final String ad;
  GrupDersSecenek({required this.id, required this.ad});
  factory GrupDersSecenek.fromJson(Map<String, dynamic> j, String adKey) =>
      GrupDersSecenek(id: j['id'].toString(), ad: (j[adKey] ?? '').toString());
}

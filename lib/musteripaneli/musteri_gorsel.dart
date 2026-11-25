import 'package:randevu_sistem/yonetici/diger/menu/ikram/kampanya_ayarlari.dart' show ikramHazirGorsel;

/// Giriş yapan müşteri erkek mi (users.cinsiyet = 1). Ana sayfa açılışta ve profilden dönünce günceller;
/// cinsiyeti boş olan müşteride false kalır.
bool musteriErkek = false;

const _erkekGorsel = {
  'images/ikram_k_sac.jpg': 'images/ikram_e_sac.jpg',
  'images/ikram_k_lazer.jpg': 'images/ikram_e_lazer.jpg',
  'images/ikram_k_tirnak.jpg': 'images/ikram_e_el.jpg',
  'images/ikram_k_pedikur.jpg': 'images/ikram_e_ayak.jpg',
  'images/ikram_foto_ayak.png': 'images/ikram_e_ayak.jpg',
};

/// Müşteri ekranlarında hizmetin hazır görseli: erkek hesapta erkek görseli,
/// hizmetin erkek görseli yoksa kişisiz genel görsel.
String musteriHizmetGorseli(String hizmet) {
  final g = ikramHazirGorsel(hizmet);
  return musteriErkek ? (_erkekGorsel[g] ?? 'images/ikram_e_genel.jpg') : g;
}

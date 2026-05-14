/// Ürün birimi (adet/gr/kg/ml/lt/paket) ile ilgili
/// hızlı seçim, stepper artışı, biçimlendirme ve dönüşüm yardımcıları.
///
/// Tasarım kararı: Stokta her zaman **ana birim** tutulur (örn: 1000 gr boya).
/// Alış/satış/sarf/sayım hareketleri de ana birimde yazılır.
/// Kullanıcının kolayı için akıllı stepper + hızlı seçim chip'leri sağlanır.
///
/// Profesyonel POS yaklaşımı (Mindbody, Vagaro, Salonbridge benzeri):
/// - Sürekli/bölünebilir birimler (gr, ml, kg, lt) için ondalıklı stepper + büyük adımlar
/// - Sayılı birimler (adet, paket) için tam sayı stepper
/// - Hızlı seçim chip'leri birimin tipik kullanım değerlerine göre
class BirimHelper {
  /// Birim tipini sınıflandırır.
  /// Dönüş: 'kucuk' (gr/ml), 'buyuk' (kg/lt), 'sayili' (adet/paket)
  static String tip(String birim) {
    final b = birim.toLowerCase().trim();
    if (b == 'gr' || b == 'ml') return 'kucuk';
    if (b == 'kg' || b == 'lt') return 'buyuk';
    return 'sayili'; // adet, paket, default
  }

  /// Birime göre hızlı seçim chip değerleri.
  /// Örn: gr için [5, 10, 25, 50, 100, 250, 500]
  static List<num> hizliSecim(String birim) {
    switch (tip(birim)) {
      case 'kucuk': return const [5, 10, 25, 50, 100, 250, 500];
      case 'buyuk': return const [0.1, 0.25, 0.5, 1, 2, 5];
      default:      return const [1, 2, 3, 5, 10, 25];
    }
  }

  /// Stepper +/- butonunun artış miktarı.
  /// gr/ml: 5, kg/lt: 0.5, adet/paket: 1
  static double stepperArtis(String birim) {
    switch (tip(birim)) {
      case 'kucuk': return 5;
      case 'buyuk': return 0.5;
      default:      return 1;
    }
  }

  /// İlk açılışta önerilen başlangıç değeri.
  static double varsayilanBaslangic(String birim) {
    switch (tip(birim)) {
      case 'kucuk': return 10;   // 10 gr / 10 ml
      case 'buyuk': return 0.5;  // 0.5 kg / 0.5 lt
      default:      return 1;    // 1 adet
    }
  }

  /// Birim için kullanıcı dostu uzun ad.
  static String uzunAd(String birim) {
    switch (birim.toLowerCase().trim()) {
      case 'gr':    return 'Gram';
      case 'kg':    return 'Kilogram';
      case 'ml':    return 'Mililitre';
      case 'lt':    return 'Litre';
      case 'paket': return 'Paket';
      case 'adet':  return 'Adet';
      default:      return birim;
    }
  }

  /// Birime göre uygun ondalık hane sayısı.
  /// gr/ml: tam sayı tercih (50 gr); kg/lt: 2-3 ondalık (0.5 kg); adet: tam.
  static int ondalikHane(String birim) {
    switch (tip(birim)) {
      case 'kucuk': return 0;    // 30 gr (50.0 değil)
      case 'buyuk': return 3;    // 0.5 kg, 1.25 lt
      default:      return 0;    // 1 adet
    }
  }

  /// Miktar + birim olarak biçimlendir: "30 gr", "0,5 kg", "2 adet".
  static String formatla(double miktar, String birim) {
    return '${_sayiFmt(miktar, ondalikHane(birim))} $birim';
  }

  /// Sadece sayıyı biçimlendir.
  static String sayi(double miktar, String birim) {
    return _sayiFmt(miktar, ondalikHane(birim));
  }

  static String _sayiFmt(double n, int ondalik) {
    if (ondalik == 0 || n == n.roundToDouble()) return n.toStringAsFixed(0);
    var s = n.toStringAsFixed(ondalik);
    // Trailing zero ve trailing nokta sil
    s = s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    return s.replaceAll('.', ',');
  }

  /// Birim için emoji/ikon önerisi (gösterim için).
  static String ikon(String birim) {
    switch (birim.toLowerCase().trim()) {
      case 'gr':
      case 'kg':    return '⚖️';
      case 'ml':
      case 'lt':    return '💧';
      case 'paket': return '📦';
      default:      return '🔢';
    }
  }

  /// Tüm desteklenen birimler (dropdown vb. için).
  static const List<String> tumBirimler = ['adet', 'gr', 'kg', 'ml', 'lt', 'paket'];
}

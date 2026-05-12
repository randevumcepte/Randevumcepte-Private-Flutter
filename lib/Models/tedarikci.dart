class Tedarikci {
  Tedarikci({
    required this.id,
    required this.ad,
    this.telefon = '',
    this.vergi_no = '',
    this.email = '',
    this.adres = '',
    this.aciklama = '',
    this.aktif = true,
  });

  final String id;
  final String ad;
  final String telefon;
  final String vergi_no;
  final String email;
  final String adres;
  final String aciklama;
  final bool aktif;

  factory Tedarikci.fromJson(Map<String, dynamic> j) {
    return Tedarikci(
      id: j['id'].toString(),
      ad: (j['ad'] ?? '').toString(),
      telefon: (j['telefon'] ?? '').toString(),
      vergi_no: (j['vergi_no'] ?? '').toString(),
      email: (j['email'] ?? '').toString(),
      adres: (j['adres'] ?? '').toString(),
      aciklama: (j['aciklama'] ?? '').toString(),
      aktif: (j['aktif']?.toString() ?? '1') == '1' || j['aktif'] == true,
    );
  }
}

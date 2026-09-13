import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Backend/yetki.dart';
import 'package:randevu_sistem/Frontend/MusteriDanisanSecimLazyLoad.dart';
import 'package:randevu_sistem/Models/isletmehizmetleri.dart';
import 'package:randevu_sistem/Models/musteri_danisanlar.dart';
import 'package:randevu_sistem/Models/paketler.dart';
import 'package:randevu_sistem/theme/premium_components.dart';
import 'package:signature/signature.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SozlesmeOlustur extends StatefulWidget {
  final dynamic isletmebilgi;
  const SozlesmeOlustur({super.key, required this.isletmebilgi});

  @override
  State<SozlesmeOlustur> createState() => _SozlesmeOlusturState();
}

class _SozlesmeOlusturState extends State<SozlesmeOlustur> {
  String _seciliSube = '';
  bool _yukleniyor = true;
  bool _gonderiliyor = false;
  String? _hataMesaji;

  List<MusteriDanisan> _musteriler = [];
  List<IsletmeHizmet> _hizmetler = [];
  List<Paket> _paketler = [];

  MusteriDanisan? _musteri;
  IsletmeHizmet? _hizmet;
  Paket? _paket;

  final _telefon = TextEditingController();
  String _telOrijinal = '';
  bool get _telGor => Yetki.varMi('musteri.telefon_gor');
  final _seans = TextEditingController(text: '1');
  final _toplam = TextEditingController();
  final _kapora = TextEditingController(text: '0');
  final _metin = TextEditingController();
  final _not = TextEditingController();

  // Odeme sekli / taksit (opsiyonel)
  String _odemeSekli = 'nakit'; // nakit | havale | kredi_karti | taksit
  final _taksitSayisi = TextEditingController();
  final _taksitTutari = TextEditingController();
  DateTime? _ilkTaksit;
  DateTime? _gecerlilik;

  // Isletme sahibi (salon yetkilisi) imzasi — cift tarafli imza (web ile ayni).
  final _yetkiliAd = TextEditingController();
  final _yetkiliTel = TextEditingController();
  final SignatureController _imzaController = SignatureController(
    penStrokeWidth: 2.5,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  @override
  void initState() {
    super.initState();
    _baslat();
  }

  @override
  void dispose() {
    _telefon.dispose();
    _seans.dispose();
    _toplam.dispose();
    _kapora.dispose();
    _metin.dispose();
    _not.dispose();
    _taksitSayisi.dispose();
    _taksitTutari.dispose();
    _yetkiliAd.dispose();
    _yetkiliTel.dispose();
    _imzaController.dispose();
    super.dispose();
  }

  Future<void> _baslat() async {
    try {
      _seciliSube = (await secilisalonid()) ?? '';
      final veri = await isletmeVerileriGetir(
          _seciliSube, false, '', '', '', 0, 0);
      _musteriler = ((veri['musteriler'] ?? []) as List)
          .whereType<MusteriDanisan>()
          .toList();
      _hizmetler = ((veri['hizmetler'] ?? []) as List)
          .whereType<IsletmeHizmet>()
          .toList();
      _paketler = ((veri['paketler'] ?? []) as List)
          .whereType<Paket>()
          .toList();
      // Daha once "Varsayilan Yap" ile kaydedilmis salon-ozel metin varsa onu
      // kullan; yoksa fabrika varsayilanina dus.
      final prefs = await SharedPreferences.getInstance();
      final kayitliMetin = prefs.getString('sozlesme_sartlari_$_seciliSube');
      _metin.text = (kayitliMetin != null && kayitliMetin.trim().isNotEmpty)
          ? kayitliMetin
          : _varsayilanMetin();
    } catch (e) {
      _hataMesaji = 'Veriler yüklenemedi: $e';
    }
    if (mounted) setState(() => _yukleniyor = false);
  }

  String _varsayilanMetin() {
    // Web ile ayni 8 maddelik genel sozlesme metni (MERKEZ = isletme).
    return '''1- SÖZLEŞMENİN KONUSU VE KAPSAMI
İşbu sözleşmenin konusu, MÜŞTERİ tarafından MERKEZ'den satın aldığı aşağıda detayları belirtilen lazer, bakım ve güzellik hizmetlerinin (bundan böyle "HİZMET" olarak anılacaktır) şartlarının, hizmetlerin sunulmasının, ödeme koşullarının ve tarafların hak ve yükümlülüklerinin belirlenmesidir.
2- ÖDEME ŞEKLİ VE KOŞULLARI
2.1- ÖDEME YÖNTEMİ
Nakit, Kredi Kart (tek çekim, taksit), elden taksit (vade tarihleri ekli ödeme planında belirtilir)
2.2- Müşteri taksitli işlemlerde ödemeleri belirtilen vadelerde yapmakla yükümlüdür. Ödemelerin gecikmesi durumunda MERKEZ, yasal faiz talep etme ve kalan borcunun tamamını muaccel kılma hakkını saklı tutar.
2.3- Hizmet bedeli ödenmeden veya ödeme planına uygulamadan hizmetin ifasına devam edilip edilmeyeceği MERKEZ'in inisiyatifindedir.
3- TARAFLARIN HAK VE YÜKÜMLÜLÜKLERİ
3.1- MERKEZ'İN YÜKÜMLÜLÜKLERİ
Merkez, hizmeti mesleki standartlara uygun, hijyen kurallarına bağlı, konusunda uzman personel tarafından ve taahhüt edilen standartlarda sunmak, kullanılan cihaz ve ürünlerin standartlara uygunluğunu sağlamak ve müşteriye sözleşme şartlarına uygun olarak hizmet vermekle yükümlüdür.
3.2- MÜŞTERİ'NİN YÜKÜMLÜLÜKLERİ VE SAĞLIK BEYANI
Sağlık Beyanı: Müşteri, hamilelik, epilepsi, kalp pili, açık yara, cilt hastalıkları, kanser tedavisi, hormon bozuklukları veya düzenli kullandığı ilaçlar gibi hizmetin uygulanmasında engel olabilecek veya risk oluşturabilecek tüm sağlık durumlarını MERKEZ'e yazılı olarak bildirmek zorundadır.
Müşteri, yanlış veya eksik sağlık beyanından kaynaklanabilecek komplikasyonlardan, yan etkilerden veya hizmetin sonuç vermemesinden MERKEZ'in sorumlu tutulmayacağını kabul ve beyan eder.
İşlem Sonrası Bakım: Müşteri, işlem sonrasında kendisine iletilen (güneşten korunma, su teması vb.) bakım talimatlarına uymak zorundadır. Talimatlara uyulmaması sonucu oluşacak leke, tahriş veya sonuç almama durumlarında MERKEZ sorumlu değildir. Müşteri, işbu sorumluluğun kendisinde olduğunu kabul ve beyan edip, tüm talimatlara eksiksiz uyacağını taahhüt eder.
3.3- TIBBİ İŞLEM UYARISI
Müşteri, MERKEZ'de uygulanan işlemlerin birer "tıbbi tedavi" veya "hastalık teşhis, tedavi yöntemi" olmadığını ve bakım amaçlı uygulamalar olduğunu, %100 sonuç garantisi verilmeyeceğini (kıl yapısı, hormon dengesi, cilt tipi gibi biyolojik faktörlere bağlı olarak) bildiğini kabul eder. Ve hizmetin etkilerinin kişisel özelliklere göre değişebileceğini, garanti sonuç talep etmeyeceğini, kendisinden kaynaklı bir durum ortaya çıktığında bunun MERKEZ'den kaynaklı olmadığını kabul ve beyan eder.
4- RANDEVU, İPTAL VE ERTELEME POLİTİKASI
4.1- MERKEZ, planlanmış randevulara ilişkin hatırlatma mesajını müşterinin bildirdiği telefon numarasına SMS, WhatsApp yolu ile bilgilendirme yapmakla yükümlüdür.
4.2- Müşteri de randevu saatine tam zamanında gelmekle yükümlüdür. 15 dakikayı aşan gecikmelerde MERKEZ, seansı iptal etme ve süreyi kısaltma hakkına sahiptir.
4.3- Randevu iptali veya erteleme talepleri, randevu saatinden en az 24 saat önce MERKEZ'e bildirilmelidir.
4.4- Mazeretsiz Gelmeme (No-Show): 24 saat önceden haber verilmeksizin randevuya gelinmemesi durumunda, ilgili seans "kullanılmış, yapılmış" sayılır ve paket hakkından düşülür. Müşteri bu durumda herhangi bir hak iddia edemez. Müşteri bu durumu eksiksiz kabul ve beyan eder.
4.5- Alınan hizmet paketleri, sözleşmede belirtilen süre içerisinde kullanılmalıdır. MÜŞTERİ'nin kendi kusurlarından kaynaklanan gecikmelerde süre uzatımı talep edemez. Ancak MERKEZ mücbir bir sebep varlığında ya da işletmeden kaynaklı zorunluluklar halinde süre uzatımı yapabilir.
5- CAYMA HAKKI, FESİH VE İADE KOŞULLARI
5.1- Cayma Hakkı: Müşteri sözleşmenin imzalandığı tarihten itibaren 14 (on dört) gün içinde, hizmet alımına başlanmamış olması kaydıyla, herhangi bir gerekçe göstermeksizin ve cezai şart ödemeksizin sözleşmeden cayma hakkına sahiptir.
5.2- Hizmet Başladıktan Sonra Fesih: Hizmetin ifasına başlandıktan (ilk seans yapıldıktan) sonra mücbir nedenlerle sözleşmenin feshedilmesi durumunda; kullanılan seanslar liste fiyatı (indirimli paket fiyatı değil, tek seans birim fiyatı) üzerinden hesaplanır. Toplam ödenen tutardan, kullanılan seansların liste fiyatı bedeli düşülerek kalan tutar iade edilir. Ancak MÜŞTERİ tarafından keyfi nedenlerle sözleşmenin feshedilmesi durumunda işbu sözleşme muaccel hale gelir ve ödenen bedeller geri iade edilmez. Müşteri bunu kabul ettiğini beyan eder.
5.3- MERKEZ'den kaynaklanan kusurlu hizmet (ayıplı hizmet) durumunda, MÜŞTERİ'nin 6502 sayılı kanundan doğan bedel iadesi veya hizmetin yeniden görülmesi hakları saklıdır.
6- HİZMETİN DEVİR VE İADESİ
6.1- İşbu yapılan hizmet sözleşmesi sadece sözleşmeyi imzalayan MÜŞTERİ'yi bağlar. Alınan hizmet herhangi başka birine devredilemez.
6.2- MÜŞTERİ tarafından alınan hizmet bir başkasına satılamaz ve ücret yerine kullanılamaz.
6.3- Müşteri getireceği Resmi Sağlık Kurumu Raporu ile hizmetin kesin olarak alınamayacağını belgelemesi halinde kullanılmayan seansların bedeli iade edilir.
6.4- Peşin ödemelerde yasal zorunluluklar dışında iade yapılmaz.
6.5- MÜŞTERİ, kendisi adına uygulanmış olan kampanya, indirim veya özel fiyatla alınan hizmetleri farklı biri üzerinde kullanamaz.
7- KİŞİSEL VERİLERİN KORUNMASI (KVKK)
7.1- MÜŞTERİ, bu sözleşme kapsamında verdiği kişisel verilerin (kimlik, iletişim, sağlık bilgileri, işlem öncesi ve sonrası fotoğraflar, rıza dahilinde çekilen videolar ve fotoğraflar vb.) 6698 sayılı KVKK kapsamında hizmetin ifası, randevu takibi ve yasal yükümlülükler nedeniyle MERKEZ tarafından işlenmesine, saklanmasına ve mevzuatın izin verdiği kurumlarla, MERKEZ'in yönettiği sosyal medya hesaplarında (Instagram, Facebook, TikTok vb.) paylaşılmasına açık rıza gösterdiğini beyan eder.
7.2- Müşteri yukarıda belirtilen ve MERKEZ'in sosyal medya hesaplarında paylaşılması için video, fotoğraf, görüntü vb. gibi alınan içeriklerin paylaşılmasına açık rıza göstermiyorsa işbu sözleşme ile birlikte imzalanan KVKK aydınlatma metni ve açık rıza formu imzalatılmıştır.
8- YETKİLİ MAHKEMELER VE YÜRÜRLÜK
İşbu sözleşmeden doğacak uyuşmazlıklarda, Tüketici Hakem Heyetleri ve ......................................... Mahkemeleri ve İcra daireleri yetkilidir. İşbu sözleşme 8 (sekiz) maddeden ibaret olup taraflarca iki nüsha olarak tanzim ve imza edilmiştir.''';
  }

  String _ikiHane(int n) => n < 10 ? '0$n' : '$n';
  String _isoTarih(DateTime d) => '${d.year}-${_ikiHane(d.month)}-${_ikiHane(d.day)}';
  String _gosterTarih(DateTime? d) =>
      d == null ? 'Seçin' : '${_ikiHane(d.day)}.${_ikiHane(d.month)}.${d.year}';

  // Canli taksit plani (sunucudaki mantigin aynisi — onizleme icin).
  List<Map<String, dynamic>> _taksitPlani() {
    final toplam = double.tryParse(_toplam.text.replaceAll(',', '.')) ?? 0;
    final kapora = double.tryParse(_kapora.text.replaceAll(',', '.')) ?? 0;
    double kalan = toplam - kapora;
    if (kalan < 0) kalan = 0;
    final sayi = int.tryParse(_taksitSayisi.text) ?? 0;
    if (sayi < 1) return [];
    final elle = double.tryParse(_taksitTutari.text.replaceAll(',', '.')) ?? 0;
    final birim = elle > 0
        ? elle
        : double.parse((kalan / sayi).toStringAsFixed(2));
    final plan = <Map<String, dynamic>>[];
    double toplandi = 0;
    for (int i = 1; i <= sayi; i++) {
      double tutar = (i == sayi)
          ? double.parse((kalan - toplandi).toStringAsFixed(2))
          : birim;
      if (tutar < 0) tutar = 0;
      toplandi = double.parse((toplandi + tutar).toStringAsFixed(2));
      DateTime? tarih;
      if (_ilkTaksit != null) {
        tarih = DateTime(_ilkTaksit!.year, _ilkTaksit!.month + (i - 1),
            _ilkTaksit!.day);
      }
      plan.add({'sira': i, 'tarih': tarih, 'tutar': tutar});
    }
    return plan;
  }

  String _paraFormat(num v) {
    // Basit 1.234,56 formati
    final s = v.toStringAsFixed(2);
    final parcalar = s.split('.');
    final tam = parcalar[0];
    final ondalik = parcalar[1];
    final sb = StringBuffer();
    for (int i = 0; i < tam.length; i++) {
      if (i > 0 && (tam.length - i) % 3 == 0) sb.write('.');
      sb.write(tam[i]);
    }
    return '$sb,$ondalik';
  }

  Future<void> _musteriSec() async {
    final secilen = await _genelPicker<MusteriDanisan>(
      baslik: 'Müşteri Seç',
      ogeler: _musteriler,
      etiket: (m) => m.name,
      altYazi: (m) => Yetki.telefonGoster(m.cep_telefon),
      seciliId: _musteri?.id,
      ogeId: (m) => m.id,
      // Musteri sayisi cok olabilir: on-yuklenen liste yerine SUNUCUDAN
      // arama + sayfali yukleme (lazy load) — Form Gonder ekraniyla ayni.
      sunucudanGetir: (arama, offset) => MusteriDanisanSecimLazyLoad.fetch(
        seciliMusteri: _musteri?.id ?? '',
        salonId: _seciliSube,
        search: arama,
        offset: offset,
        limit: _sayfaBoyutu,
      ),
      sayfaBoyutu: _sayfaBoyutu,
    );
    if (secilen != null) {
      setState(() {
        _musteri = secilen;
        _telOrijinal = secilen.cep_telefon;
        _telefon.text = _telGor ? _telOrijinal : Yetki.telefonGoster(_telOrijinal);
      });
    }
  }

  Future<void> _hizmetSec() async {
    final secilen = await _genelPicker<IsletmeHizmet>(
      baslik: 'Hizmet Seç',
      ogeler: _hizmetler,
      etiket: (h) => h.hizmet?['hizmet_adi']?.toString() ?? '-',
      altYazi: (h) => '${h.fiyat} ₺',
      seciliId: _hizmet?.hizmet_id,
      ogeId: (h) => h.hizmet_id,
      temizleVar: true,
    );
    setState(() {
      _hizmet = secilen;
      if (secilen != null && _toplam.text.trim().isEmpty) {
        _toplam.text = secilen.fiyat;
      }
    });
  }

  Future<void> _paketSec() async {
    final secilen = await _genelPicker<Paket>(
      baslik: 'Paket Seç',
      ogeler: _paketler,
      etiket: (p) => p.paket_adi,
      altYazi: (p) => p.fiyat.isNotEmpty ? '${p.fiyat} ₺' : '',
      seciliId: _paket?.id,
      ogeId: (p) => p.id,
      temizleVar: true,
    );
    setState(() {
      _paket = secilen;
      if (secilen != null && secilen.fiyat.isNotEmpty && secilen.fiyat != '0') {
        _toplam.text = secilen.fiyat;
      }
    });
  }

  static const int _sayfaBoyutu = 50;

  Future<T?> _genelPicker<T>({
    required String baslik,
    required List<T> ogeler,
    required String Function(T) etiket,
    required String Function(T) altYazi,
    required String? seciliId,
    required String Function(T) ogeId,
    bool temizleVar = false,
    Future<List<T>> Function(String arama, int offset)? sunucudanGetir,
    int sayfaBoyutu = 50,
  }) {
    return showModalBottomSheet<T?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _PickerSheet<T>(
          baslik: baslik,
          ogeler: ogeler,
          etiket: etiket,
          altYazi: altYazi,
          seciliId: seciliId,
          ogeId: ogeId,
          temizleVar: temizleVar,
          sunucudanGetir: sunucudanGetir,
          sayfaBoyutu: sayfaBoyutu,
        );
      },
    );
  }

  Future<void> _gonder() async {
    if (_musteri == null) {
      showPremiumWarning(context,
          title: 'Müşteri Seçilmedi',
          message: 'Lütfen bir müşteri seçin.');
      return;
    }
    if (_telefon.text.trim().isEmpty) {
      showPremiumWarning(context,
          title: 'Telefon Boş',
          message: 'Müşteri cep telefonu zorunlu.');
      return;
    }
    final toplam = double.tryParse(_toplam.text.replaceAll(',', '.')) ?? 0;
    if (toplam <= 0) {
      showPremiumWarning(context,
          title: 'Toplam Ücret',
          message: 'Geçerli bir toplam ücret girin.');
      return;
    }
    if (_metin.text.trim().isEmpty) {
      showPremiumWarning(context,
          title: 'Sözleşme Şartları',
          message: 'Sözleşme metni boş olamaz.');
      return;
    }

    setState(() => _gonderiliyor = true);
    try {
      // form.gonder yetkisi yoksa: sozlesmeyi olustur ve arsive kaydet,
      // ama musteriye SMS atma.
      final sadeceKaydet = !Yetki.varMi('form.gonder');

      // Isletme yetkilisi imzasini base64 PNG data-uri olarak hazirla.
      String salonImza = '';
      if (_imzaController.isNotEmpty) {
        final imzaBytes = await _imzaController.toPngBytes();
        if (imzaBytes != null) {
          salonImza = 'data:image/png;base64,${base64Encode(imzaBytes)}';
        }
      }

      final body = {
        'sube': _seciliSube,
        'user_id': _musteri!.id,
        'cep_telefon': _telGor ? _telefon.text.trim() : _telOrijinal,
        'hizmet_id': _hizmet?.hizmet_id ?? '',
        'paket_id': _paket?.id ?? '',
        'seans_sayisi': int.tryParse(_seans.text) ?? 1,
        'toplam_ucret': toplam,
        'kapora': double.tryParse(_kapora.text.replaceAll(',', '.')) ?? 0,
        'sozlesme_metni': _metin.text,
        'sozlesme_notu': _not.text,
        'odeme_sekli': _odemeSekli,
        if (_odemeSekli == 'taksit')
          'taksit_sayisi': int.tryParse(_taksitSayisi.text) ?? 0,
        if (_odemeSekli == 'taksit')
          'taksit_tutari':
              double.tryParse(_taksitTutari.text.replaceAll(',', '.')) ?? 0,
        if (_odemeSekli == 'taksit' && _ilkTaksit != null)
          'ilk_taksit_tarihi': _isoTarih(_ilkTaksit!),
        if (_gecerlilik != null) 'gecerlilik_tarihi': _isoTarih(_gecerlilik!),
        // Isletme sahibi (salon yetkilisi) imzasi
        'salon_imza': salonImza,
        'salon_yetkili_ad': _yetkiliAd.text.trim(),
        'salon_yetkili_telefon': _yetkiliTel.text.trim(),
        'sadece_kaydet': sadeceKaydet,
      };
      final resp = await http.post(
        Uri.parse(
            'https://app.randevumcepte.com.tr/api/v1/sozlesme-olustur'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (resp.statusCode == 200) {
        final j = jsonDecode(resp.body);
        if (j is Map && j['basarili'] == true) {
          if (mounted) {
            await showPremiumWarning(context,
                title: sadeceKaydet ? 'Sözleşme Kaydedildi' : 'Sözleşme Gönderildi',
                message: sadeceKaydet
                    ? 'Sözleşme arşive eklendi. Gönderme yetkiniz olmadığı için müşteriye SMS atılmadı.'
                    : 'Müşteriye SMS ile sözleşme gönderildi.',
                tone: 'success');
          }
          if (mounted) Navigator.pop(context, true);
          return;
        }
        if (mounted) {
          showPremiumWarning(context,
              title: 'Gönderilemedi',
              message: (j is Map && j['mesaj'] != null)
                  ? j['mesaj'].toString()
                  : 'Bir hata oluştu, tekrar deneyin.',
              tone: 'error');
        }
      } else {
        if (mounted) {
          showPremiumWarning(context,
              title: 'Sunucu Hatası',
              message: 'Hata kodu: ${resp.statusCode}',
              tone: 'error');
        }
      }
    } catch (_) {
      if (mounted) {
        showPremiumWarning(context,
            title: 'Bağlantı Hatası',
            message: 'İnternet bağlantınızı kontrol edin.',
            tone: 'error');
      }
    } finally {
      if (mounted) setState(() => _gonderiliyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PremiumGradientBg(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(scheme),
              Expanded(
                child: _yukleniyor
                    ? const Center(child: CircularProgressIndicator())
                    : _hataMesaji != null
                        ? Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(_hataMesaji!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontWeight: FontWeight.w600)),
                          )
                        : _buildBody(scheme),
              ),
              if (!_yukleniyor && _hataMesaji == null) _buildBottom(scheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      child: Row(
        children: [
          PremiumCircleAction(
            icon: Icons.arrow_back_rounded,
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sözleşme Oluştur',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                    letterSpacing: -0.4,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Hizmet sözleşmesi hazırla ve müşteriye gönder',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ColorScheme scheme) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
      children: [
        PremiumGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Etiket('Müşteri *'),
              _SecimAlani(
                etiket: _musteri?.name ?? 'Müşteri seçin',
                altYazi: Yetki.telefonGoster(_musteri?.cep_telefon),
                ikon: Icons.person_outline_rounded,
                bos: _musteri == null,
                onTap: _musteriSec,
              ),
              const SizedBox(height: 14),
              const _Etiket('Cep Telefon *'),
              TextField(
                controller: _telefon,
                keyboardType: TextInputType.phone,
                readOnly: !_telGor,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9 *]')),
                ],
                decoration: _inputDeko('Müşteri seçince otomatik dolar', scheme),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        PremiumGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Etiket('Hizmet (opsiyonel)'),
              _SecimAlani(
                etiket: _hizmet?.hizmet?['hizmet_adi']?.toString() ??
                    'Hizmet seçin',
                altYazi: _hizmet != null ? '${_hizmet!.fiyat} ₺' : null,
                ikon: Icons.spa_outlined,
                bos: _hizmet == null,
                onTap: _hizmetSec,
              ),
              const SizedBox(height: 14),
              const _Etiket('Paket (opsiyonel)'),
              _SecimAlani(
                etiket: _paket?.paket_adi ?? 'Paket seçin',
                altYazi: (_paket != null && _paket!.fiyat.isNotEmpty)
                    ? '${_paket!.fiyat} ₺'
                    : null,
                ikon: Icons.inventory_2_outlined,
                bos: _paket == null,
                onTap: _paketSec,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        PremiumGlassCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Etiket('Seans'),
                    TextField(
                      controller: _seans,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      decoration: _inputDeko('1', scheme),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Etiket('Toplam Ücret *'),
                    TextField(
                      controller: _toplam,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: _inputDeko('0,00 ₺', scheme),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Etiket('Kapora'),
                    TextField(
                      controller: _kapora,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: _inputDeko('0,00 ₺', scheme),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildOdemeKart(scheme),
        const SizedBox(height: 12),
        PremiumGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Etiket('Sözleşme Şartları *'),
              const Text(
                'Müşteriye gösterilecek metin — düzenleyebilirsiniz.',
                style: TextStyle(fontSize: 11, color: Colors.black54),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _metin,
                maxLines: 10,
                minLines: 6,
                style:
                    const TextStyle(fontFamily: 'monospace', fontSize: 12.5),
                decoration: _inputDeko('Sözleşme metni...', scheme),
              ),
              const SizedBox(height: 8),
              // Metindeki degisiklikleri salon-ozel varsayilan olarak kaydet.
              // Kayitli metin sonraki sozlesmelerde otomatik gelir
              // (SharedPreferences, salon bazli).
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _varsayilanOlarakKaydet,
                  icon: const Icon(Icons.push_pin_outlined, size: 16),
                  label: const Text('Varsayılan Yap',
                      style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: scheme.primary,
                    side: BorderSide(color: scheme.primary.withOpacity(0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const _Etiket('Ek Not (opsiyonel)'),
              TextField(
                controller: _not,
                maxLines: 2,
                decoration: _inputDeko(
                    'Örn: Seans aralığı 15 günü geçemez.', scheme),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildImzaKart(scheme),
      ],
    );
  }

  // "Varsayılan Yap": mevcut sözleşme metnini bu salon için varsayılan olarak
  // kaydeder; sonraki sözleşmeler bu metinle açılır.
  Future<void> _varsayilanOlarakKaydet() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sozlesme_sartlari_$_seciliSube', _metin.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Bu metin varsayılan olarak kaydedildi. Sonraki sözleşmelerde otomatik gelecek.'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _tarihSec(bool ilkTaksit) async {
    final now = DateTime.now();
    final secili = await showDatePicker(
      context: context,
      initialDate: (ilkTaksit ? _ilkTaksit : _gecerlilik) ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 6),
      locale: const Locale('tr', 'TR'),
    );
    if (secili != null) {
      setState(() {
        if (ilkTaksit) {
          _ilkTaksit = secili;
        } else {
          _gecerlilik = secili;
        }
      });
    }
  }

  Widget _tarihAlani({
    required String etiket,
    required DateTime? deger,
    required VoidCallback onTap,
    ColorScheme? scheme,
  }) {
    final s = scheme ?? Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Etiket(etiket),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            decoration: BoxDecoration(
              color: s.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.event_outlined,
                    size: 18, color: s.primary.withValues(alpha: 0.7)),
                const SizedBox(width: 8),
                Text(
                  _gosterTarih(deger),
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: deger == null
                        ? Colors.black.withValues(alpha: 0.45)
                        : s.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Isletme sahibi (salon yetkilisi) imza karti — parmakla imza + ad/telefon.
  Widget _buildImzaKart(ColorScheme scheme) {
    return PremiumGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Etiket('İşletme Sahibi / Yetkili İmzası'),
          const Text(
            'Sözleşmeyi işletme adına imzalayın. Müşteri kendi imzasını link üzerinden atacaktır.',
            style: TextStyle(fontSize: 11, color: Colors.black54),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _yetkiliAd,
            textCapitalization: TextCapitalization.words,
            decoration: _inputDeko('Yetkili Ad Soyad', scheme),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _yetkiliTel,
            keyboardType: TextInputType.phone,
            decoration: _inputDeko('Yetkili Telefon', scheme),
          ),
          const SizedBox(height: 12),
          const _Etiket('İmza'),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                  color: scheme.primary.withValues(alpha: 0.35), width: 1.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Signature(
                controller: _imzaController,
                height: 160,
                backgroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _imzaController.clear(),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Temizle'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOdemeKart(ColorScheme scheme) {
    final taksitli = _odemeSekli == 'taksit';
    final plan = taksitli ? _taksitPlani() : <Map<String, dynamic>>[];
    final secenekler = const [
      ['nakit', 'Nakit'],
      ['havale', 'Havale'],
      ['kredi_karti', 'Kredi Kartı'],
      ['taksit', 'Taksitli'],
    ];
    return PremiumGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Etiket('Ödeme Şekli'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: secenekler.map((o) {
              final aktif = _odemeSekli == o[0];
              return ChoiceChip(
                label: Text(o[1]),
                selected: aktif,
                onSelected: (_) => setState(() => _odemeSekli = o[0]),
                labelStyle: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: aktif ? scheme.onPrimary : scheme.onSurface,
                ),
                selectedColor: scheme.primary,
                backgroundColor: scheme.primary.withValues(alpha: 0.06),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          _tarihAlani(
            etiket: 'Hizmet/Paket Geçerlilik Tarihi (opsiyonel)',
            deger: _gecerlilik,
            onTap: () => _tarihSec(false),
            scheme: scheme,
          ),
          if (taksitli) ...[
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _Etiket('Taksit Sayısı'),
                      TextField(
                        controller: _taksitSayisi,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        onChanged: (_) => setState(() {}),
                        decoration: _inputDeko('Örn: 6', scheme),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _Etiket('Taksit Tutarı (oto)'),
                      TextField(
                        controller: _taksitTutari,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        onChanged: (_) => setState(() {}),
                        decoration: _inputDeko('Boş = eşit böl', scheme),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _tarihAlani(
              etiket: 'İlk Taksit Tarihi',
              deger: _ilkTaksit,
              onTap: () => _tarihSec(true),
              scheme: scheme,
            ),
            const SizedBox(height: 12),
            if (plan.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: scheme.primary.withValues(alpha: 0.15)),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                      child: Row(
                        children: [
                          Icon(Icons.credit_card_rounded,
                              size: 16, color: scheme.primary),
                          const SizedBox(width: 6),
                          Text(
                            '${plan.length} Taksitlik Plan',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: scheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...plan.map((t) {
                      final DateTime? tarih = t['tarih'] as DateTime?;
                      return Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 26,
                              child: Text('${t['sira']}.',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700)),
                            ),
                            Expanded(
                              child: Text(
                                tarih != null ? _gosterTarih(tarih) : '—',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            Text(
                              '${_paraFormat(t['tutar'] as num)} ₺',
                              style: const TextStyle(
                                  fontSize: 12.5, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottom(ColorScheme scheme) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: _gonderiliyor ? null : _gonder,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [scheme.primary, scheme.tertiary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.30),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Center(
                child: _gonderiliyor
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Yetki.varMi('form.gonder')
                                ? Icons.send_rounded
                                : Icons.save_outlined,
                            color: scheme.onPrimary,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            Yetki.varMi('form.gonder')
                                ? 'Oluştur ve Müşteriye Gönder'
                                : 'Sadece Oluştur',
                            style: TextStyle(
                              color: scheme.onPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeko(String hint, ColorScheme scheme) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12.5, color: Colors.black38),
      filled: true,
      fillColor: scheme.primary.withValues(alpha: 0.05),
      isDense: true,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}

class _Etiket extends StatelessWidget {
  final String text;
  const _Etiket(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _SecimAlani extends StatelessWidget {
  final String etiket;
  final String? altYazi;
  final IconData ikon;
  final bool bos;
  final VoidCallback onTap;
  const _SecimAlani({
    required this.etiket,
    required this.ikon,
    required this.bos,
    required this.onTap,
    this.altYazi,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.primary.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(ikon, color: scheme.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      etiket,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: bos
                            ? Colors.black.withValues(alpha: 0.45)
                            : scheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (altYazi != null && altYazi!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        altYazi!,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: scheme.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.unfold_more_rounded,
                  size: 18, color: scheme.primary.withValues(alpha: 0.6)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickerSheet<T> extends StatefulWidget {
  final String baslik;
  final List<T> ogeler;
  final String Function(T) etiket;
  final String Function(T) altYazi;
  final String? seciliId;
  final String Function(T) ogeId;
  final bool temizleVar;

  /// Verilirse arama/sayfalama SUNUCUDAN yapilir (lazy load); verilmezse
  /// [ogeler] listesi bellek icinde filtrelenir (kucuk listeler icin).
  final Future<List<T>> Function(String arama, int offset)? sunucudanGetir;
  final int sayfaBoyutu;

  const _PickerSheet({
    required this.baslik,
    required this.ogeler,
    required this.etiket,
    required this.altYazi,
    required this.seciliId,
    required this.ogeId,
    required this.temizleVar,
    this.sunucudanGetir,
    this.sayfaBoyutu = 50,
  });

  @override
  State<_PickerSheet<T>> createState() => _PickerSheetState<T>();
}

class _PickerSheetState<T> extends State<_PickerSheet<T>> {
  String _arama = '';
  final _aramaController = TextEditingController();

  // Sunucu taraflı (lazy load) mod durumu
  bool get _uzaktan => widget.sunucudanGetir != null;
  final List<T> _uzakOgeler = [];
  final ScrollController _kaydirma = ScrollController();
  Timer? _aramaGecikmesi;
  int _offset = 0;
  bool _yukleniyor = false;
  bool _dahaVar = true;
  int _istekNo = 0; // yarış durumunu önlemek için

  @override
  void initState() {
    super.initState();
    if (_uzaktan) {
      _dahaGetir(sifirla: true);
      _kaydirma.addListener(() {
        if (_kaydirma.position.pixels >=
                _kaydirma.position.maxScrollExtent - 200 &&
            !_yukleniyor &&
            _dahaVar) {
          _dahaGetir();
        }
      });
    }
  }

  @override
  void dispose() {
    _aramaGecikmesi?.cancel();
    _kaydirma.dispose();
    _aramaController.dispose();
    super.dispose();
  }

  Future<void> _dahaGetir({bool sifirla = false}) async {
    if (_yukleniyor || (!sifirla && !_dahaVar)) return;
    if (sifirla) {
      _offset = 0;
      _dahaVar = true;
    }
    final istek = ++_istekNo;
    setState(() => _yukleniyor = true);
    try {
      final sonuc = await widget.sunucudanGetir!(_arama, _offset);
      // Daha yeni bir arama başladıysa bu cevabı yok say.
      if (!mounted || istek != _istekNo) return;
      setState(() {
        if (sifirla) _uzakOgeler.clear();
        _uzakOgeler.addAll(sonuc);
        _offset += widget.sayfaBoyutu;
        if (sonuc.length < widget.sayfaBoyutu) _dahaVar = false;
      });
    } catch (_) {
      if (mounted && istek == _istekNo) setState(() => _dahaVar = false);
    } finally {
      if (mounted && istek == _istekNo) setState(() => _yukleniyor = false);
    }
  }

  void _aramaDegisti(String v) {
    setState(() => _arama = v);
    if (!_uzaktan) return;
    // Her tuşta istek atmamak için kısa gecikme.
    _aramaGecikmesi?.cancel();
    _aramaGecikmesi = Timer(const Duration(milliseconds: 350), () {
      _dahaGetir(sifirla: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Uzaktan modda filtreleme sunucuda yapılır; yerel modda bellekte.
    final filtreli = _uzaktan
        ? List<T>.from(_uzakOgeler)
        : widget.ogeler.where((o) {
            if (_arama.isEmpty) return true;
            final q = _arama.toLowerCase();
            return widget.etiket(o).toLowerCase().contains(q) ||
                widget.altYazi(o).toLowerCase().contains(q);
          }).toList();
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (ctx, scroll) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.baslik,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                    ),
                    if (widget.temizleVar)
                      TextButton.icon(
                        onPressed: () => Navigator.pop<T?>(context, null),
                        icon: const Icon(Icons.clear_rounded, size: 16),
                        label: const Text('Temizle'),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                child: TextField(
                  controller: _aramaController,
                  onChanged: _aramaDegisti,
                  decoration: InputDecoration(
                    hintText: 'Ara...',
                    isDense: true,
                    prefixIcon: const Icon(Icons.search, size: 18),
                    filled: true,
                    fillColor: scheme.primary.withValues(alpha: 0.05),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: filtreli.isEmpty
                    ? Center(
                        child: _uzaktan && _yukleniyor
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(
                                'Sonuç yok',
                                style: TextStyle(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    fontSize: 13),
                              ),
                      )
                    : ListView.builder(
                        // Uzaktan modda kendi kaydırma denetleyicimiz gerekiyor
                        // (sayfa sonuna gelince yeni sayfa çekiliyor).
                        controller: _uzaktan ? _kaydirma : scroll,
                        itemCount:
                            filtreli.length + (_uzaktan && _dahaVar ? 1 : 0),
                        itemBuilder: (ctx, i) {
                          if (i >= filtreli.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 14),
                              child: Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                ),
                              ),
                            );
                          }
                          final o = filtreli[i];
                          final aktif =
                              widget.seciliId == widget.ogeId(o);
                          return ListTile(
                            dense: true,
                            tileColor: aktif
                                ? scheme.primary.withValues(alpha: 0.06)
                                : null,
                            title: Text(
                              widget.etiket(o),
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: aktif
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                              ),
                            ),
                            subtitle: widget.altYazi(o).isNotEmpty
                                ? Text(
                                    widget.altYazi(o),
                                    style: const TextStyle(fontSize: 11.5),
                                  )
                                : null,
                            trailing: aktif
                                ? Icon(Icons.check_circle_rounded,
                                    color: scheme.primary, size: 18)
                                : null,
                            onTap: () => Navigator.pop<T?>(context, o),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

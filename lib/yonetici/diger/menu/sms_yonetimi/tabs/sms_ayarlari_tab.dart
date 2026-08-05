import 'package:flutter/material.dart';
import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Frontend/aramali_dropdown.dart';

import '../sms_yonetimi_state.dart';

class SmsAyarlariTab extends StatefulWidget {
  final SmsYonetimiController state;
  const SmsAyarlariTab({Key? key, required this.state}) : super(key: key);

  @override
  State<SmsAyarlariTab> createState() => _SmsAyarlariTabState();
}

class _SmsAyarlariTabState extends State<SmsAyarlariTab>
    with AutomaticKeepAliveClientMixin {
  bool _kaydediliyor = false;

  @override
  bool get wantKeepAlive => true;

  // Web sayfasındaki ayar listesi (ayar_id -> kart bilgileri)
  static const List<_AyarKart> _kartlar = [
    _AyarKart(
        ayarId: 16,
        baslik: 'Doğrulama Kodu',
        aciklama:
            'Randevu ve senet işlemlerinde müşterinin cep telefonuna doğrulama kodu gitsin/gitmesin ayarı.',
        sadeceMusteri: true),
    _AyarKart(
        ayarId: 1,
        baslik: 'Yaklaşan Randevu Hatırlatma',
        aciklama:
            'Randevu hatırlatmalarına dair SMS gönderimlerinin gitsin/gitmesin ayarı. (Saat ayarı aşağıdadır.)'),
    _AyarKart(
        ayarId: 2,
        baslik: 'Randevu Talebi Onaylandığında',
        aciklama: 'Online randevu talebi onaylandığında SMS gönderim ayarı.'),
    _AyarKart(
        ayarId: 3,
        baslik: 'Aktif Randevu İptalinde',
        aciklama: 'Oluşturulan randevu iptal edildiğinde SMS gönderim ayarı.'),
    _AyarKart(
        ayarId: 4,
        baslik: 'Müşteri Eklendiğinde',
        aciklama:
            'Müşteri kaydedildiğinde bilgilendirme SMS\'i gönderim ayarı.',
        sadeceMusteri: true),
    _AyarKart(
        ayarId: 5,
        baslik: '60 Gün Ziyaret Etmemiş Müşteri Hatırlatma',
        aciklama:
            '60 gün boyunca işletmenizi ziyaret etmemiş müşterilerinize otomatik hatırlatma SMS\'i.',
        sadeceMusteri: true),
    _AyarKart(
        ayarId: 6,
        baslik: 'Bir Gün Önce Randevu Hatırlatma',
        aciklama: 'Bir gün önce hatırlatma SMS gönderim ayarı.'),
    _AyarKart(
        ayarId: 7,
        baslik: 'Randevu Talebi Reddedildiğinde',
        aciklama: 'Online randevu talebi reddedildiğinde SMS gönderim ayarı.'),
    _AyarKart(
        ayarId: 8,
        baslik: 'Doğum Günü Gönderimi',
        aciklama:
            'Doğum günü olan müşterilere kutlama SMS\'i gönderim ayarı.',
        sadeceMusteri: true),
    _AyarKart(
        ayarId: 9,
        baslik: 'Randevu Sürükle ve Bırak',
        aciklama: 'Randevu sürükle/bırak işleminde SMS gönderim ayarı.',
        sadeceMusteri: true),
    _AyarKart(
        ayarId: 10,
        baslik: 'Etkinlik & Kampanya Katılım Linki',
        aciklama:
            'Etkinlik veya kampanya katılım linki için SMS gönderim ayarı.',
        sadeceMusteri: true),
    _AyarKart(
        ayarId: 11,
        baslik: 'Online Randevu Talebi Bilgilendirme',
        aciklama: 'Yeni online randevu talebi geldiğinde SMS gönderim ayarı.'),
    _AyarKart(
        ayarId: 12,
        baslik: 'Randevu Oluşturulduğunda',
        aciklama: 'Randevu oluşturulduğu esnada SMS gönderim ayarı.'),
    _AyarKart(
        ayarId: 13,
        baslik: 'Randevu Sonrası Değerlendirme',
        aciklama: 'Randevu sonrası değerlendirme SMS\'i gönderim ayarı.',
        sadeceMusteri: true),
    _AyarKart(
        ayarId: 14,
        baslik: 'Randevu Güncelleme',
        aciklama:
            'Güncellenen randevu saati ve tarihini SMS olarak gönderme ayarı.'),
    _AyarKart(
        ayarId: 15,
        baslik: 'Kara Liste',
        aciklama: 'Kara listeye eklenen numaraya SMS gönderim ayarı.',
        sadeceMusteri: true),
    _AyarKart(
        ayarId: 17,
        baslik: 'Yaklaşan Notu Hatırlatma',
        aciklama: 'Notlara dair SMS gönderim ayarı.',
        sadecePersonel: true),
    _AyarKart(
        ayarId: 18,
        baslik: 'Form SMS Olarak Gönderme',
        aciklama: 'Form linki müşteriye SMS olarak gönderilsin ayarı.'),
    _AyarKart(
        ayarId: 19,
        baslik: 'Para İşlemleri Bilgilendirme',
        aciklama:
            'Kasa para ekleme/alma işlemlerinde hesap sahibine SMS gönderim ayarı.',
        sadecePersonel: true),
    _AyarKart(
        ayarId: 20,
        baslik: 'Seans Bilgisi Bildirimi',
        aciklama: 'Müşterinin seans bilgilerinin SMS olarak gönderim ayarı.',
        sadeceMusteri: true),
    _AyarKart(
        ayarId: 21,
        baslik: 'Müşteri Geldi Bildirimi',
        aciklama: 'Personele müşterinin geldiğini SMS ile bildirim ayarı.',
        sadecePersonel: true),
    _AyarKart(
        ayarId: 22,
        baslik: 'KVKK Bildirimi',
        aciklama: 'KVKK bildirimi SMS gönderim ayarı.',
        sadeceMusteri: true),
    _AyarKart(
        ayarId: 23,
        baslik: 'Satış ve Tahsilat Silme Bildirimi',
        aciklama:
            'Tahsilat/satış silme işlemlerinde hesap sahibine SMS gönderim ayarı.',
        sadecePersonel: true),
  ];

  Future<void> _kaydet() async {
    setState(() => _kaydediliyor = true);
    try {
      final liste = widget.state.ayarlar.entries
          .map((e) => {
                'ayar_id': e.key,
                'musteri': e.value['musteri'] == true,
                'personel': e.value['personel'] == true,
              })
          .toList();
      final res = await smsYonetimAyarKaydet(
        widget.state.salonId,
        ayarlar: liste,
        randevuSmsHatirlatma: widget.state.randevuSmsHatirlatma,
      );
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor:
            res['basarili'] == true ? Colors.green : Colors.red,
        content: Text((res['mesaj'] ?? 'Kaydedildi').toString()),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.red,
        content: Text('Hata: $e'),
      ));
    } finally {
      if (mounted) setState(() => _kaydediliyor = false);
    }
  }

  Widget _ayarKarti(_AyarKart kart) {
    final state = widget.state;
    return Container(
      margin: EdgeInsets.symmetric(vertical: 6),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(kart.baslik,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600)),
          if (kart.aciklama.isNotEmpty) ...[
            SizedBox(height: 4),
            Text(kart.aciklama,
                style: TextStyle(
                    fontSize: 12, color: Colors.grey.shade700)),
          ],
          SizedBox(height: 8),
          Row(
            children: [
              if (!kart.sadecePersonel)
                Expanded(
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(
                        kart.sadeceMusteri ? 'Açık / Kapalı' : 'Müşteri',
                        style: TextStyle(fontSize: 13)),
                    value: state.ayarMusteri(kart.ayarId),
                    onChanged: (v) => state.ayarMusteriDegistir(kart.ayarId, v),
                  ),
                ),
              if (!kart.sadeceMusteri)
                Expanded(
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(
                        kart.sadecePersonel ? 'Açık / Kapalı' : 'Personel',
                        style: TextStyle(fontSize: 13)),
                    value: state.ayarPersonel(kart.ayarId),
                    onChanged: (v) =>
                        state.ayarPersonelDegistir(kart.ayarId, v),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _hatirlatmaSaatiKarti() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 6),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Yaklaşan Randevu Hatırlatma Saati',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          SizedBox(height: 4),
          Text('Randevudan kaç saat önce SMS gönderilsin?',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
          SizedBox(height: 8),
          AramaliDropdownFormField<int>(
            value: widget.state.randevuSmsHatirlatma,
            decoration: InputDecoration(
                isDense: true, border: OutlineInputBorder()),
            items: List.generate(23, (i) => i + 1)
                .map((s) => DropdownMenuItem(
                      value: s,
                      child: Text('$s saat'),
                    ))
                .toList(),
            onChanged: (v) {
              if (v == null) return;
              setState(() {
                widget.state.randevuSmsHatirlatma = v;
              });
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return AnimatedBuilder(
      animation: widget.state,
      builder: (_, __) {
        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _hatirlatmaSaatiKarti(),
                    ..._kartlar.map(_ayarKarti).toList(),
                    SizedBox(height: 80),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                      top: BorderSide(color: Colors.grey.shade300)),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _kaydediliyor ? null : _kaydet,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: _kaydediliyor
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Icon(Icons.save),
                    label: Text(_kaydediliyor
                        ? 'Kaydediliyor...'
                        : 'Ayarları Güncelle'),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AyarKart {
  final int ayarId;
  final String baslik;
  final String aciklama;
  final bool sadeceMusteri;
  final bool sadecePersonel;

  const _AyarKart({
    required this.ayarId,
    required this.baslik,
    required this.aciklama,
    this.sadeceMusteri = false,
    this.sadecePersonel = false,
  });
}

import 'dart:convert';

import 'package:randevu_sistem/Models/katilimcilar.dart';
class Arsiv {
  Arsiv({
    required this.id,
    required this.form,
    required this.tarih_saat,
    required this.musteridanisan,
    required this.durum,
    required this.uzanti,
    required this.harici_belge,
    required this.musteridanisan_imza,
    required this.personel_imza,
    required this.cevapladi,
    required this.cevapladi2,
    required this.enfeksiyon,
    required this.seker,
    required this.alerji_bagisiklik_romatizma,
    required this.operasyon,
    required this.deri_hastaligi,
    required this.kanama,
    required this.hepatit_aids,
    required this.gebelik,
    required this.son_bir_hafta,
    required this.son_uc_gun,
    required this.son_bir_ay,
    required this.son_birkac_hafta,
    required this.mesaj,
    required this.form_olusturan,
    required this.dogrulama_kodu,
    required this.personel,
    required this.sozlesme_adi,


  });

  final String id;
  final String tarih_saat;
  final Map<String, dynamic>  form;

  final Map<String, dynamic> musteridanisan;
  final String durum;
  final String uzanti;
  final String harici_belge;
  final String musteridanisan_imza;
  final String personel_imza;
  final String cevapladi;
  final String cevapladi2;
  final String sozlesme_adi;
  final String enfeksiyon;
  final String seker;
  final String alerji_bagisiklik_romatizma;
  final String operasyon;
  final String deri_hastaligi;
  final String kanama;
  final String hepatit_aids;
  final String gebelik;
  final String son_bir_hafta;
  final String son_uc_gun;
  final String son_bir_ay;
  final String son_birkac_hafta;
  final String mesaj;
  final String form_olusturan;
  final String dogrulama_kodu;
  final Map<String, dynamic> personel;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': tarih_saat,
      'form' :form,
      'mesaj':mesaj,
      'sozlesme_adi':sozlesme_adi,
      'name,' : musteridanisan,
      'durum,' : durum,
      'uzanti,' : uzanti,
      'harici_belge,' : harici_belge,
      'musteridanisan_imza,' : musteridanisan_imza,
      'personel_imza,' : personel_imza,
      'cevapladi,' : cevapladi,
      'cevapladi2,' : cevapladi2,
      'enfeksiyon,' : enfeksiyon,
      'seker,' : seker,
      'alerji_bagisiklik_romatizma,' : alerji_bagisiklik_romatizma,
      'operasyon,' : operasyon,
      'deri_hastaligi,' : deri_hastaligi,
      'kanama,' : kanama,
      'hepatit_aids,' : hepatit_aids,
      'gebelik,' : gebelik,
      'son_bir_hafta,' : son_bir_hafta,
      'son_uc_gun,' : son_uc_gun,
      'son_bir_ay,' : son_bir_ay,
      'son_birkac_hafta,' : son_birkac_hafta,
      'mesaj,' : mesaj,
      'form_olusturan,' : form_olusturan,
      'dogrulama_kodu,' : dogrulama_kodu,
      'personel' : personel,

    };
  }

  factory Arsiv.fromJson(Map<String, dynamic> jsonvar) {

    return Arsiv(
      id:jsonvar["id"].toString(),
      tarih_saat: jsonvar["created_at"].toString(),
      form: jsonvar["form"],

      musteridanisan:jsonvar['musteri'],
      durum:jsonvar['durum'].toString(),
      uzanti:jsonvar['uzanti'].toString(),
      harici_belge:jsonvar['harici_belge'].toString(),
      musteridanisan_imza:jsonvar['musteridanisan_imza'].toString(),
      personel_imza:jsonvar['personel_imza'].toString(),
      cevapladi:jsonvar['cevapladi'].toString(),
      cevapladi2:jsonvar['cevapladi2'].toString(),
      enfeksiyon:jsonvar['enfeksiyon'].toString(),
      seker:jsonvar['seker'].toString(),
      alerji_bagisiklik_romatizma:jsonvar['alerji_bagisiklik_romatizma'].toString(),
      operasyon:jsonvar['operasyon'].toString(),
      deri_hastaligi:jsonvar['deri_hastaligi'].toString(),
      kanama:jsonvar['kanama'].toString(),
      hepatit_aids:jsonvar['hepatit_aids'].toString(),
      gebelik:jsonvar['gebelik'].toString(),
      son_bir_hafta:jsonvar['son_bir_hafta'].toString(),
      son_uc_gun:jsonvar['son_uc_gun'].toString(),
      son_bir_ay:jsonvar['son_bir_ay'].toString(),
      son_birkac_hafta:jsonvar['son_birkac_hafta'].toString(),
      mesaj:jsonvar['mesaj'].toString(),
      form_olusturan:jsonvar['form_olusturan'].toString(),
      dogrulama_kodu:jsonvar['dogrulama_kodu'].toString(),
      personel:jsonvar['personel'],
      sozlesme_adi: jsonvar['sozlesme_adi'].toString(),




    );
  }
}
import 'package:flutter/material.dart';

import 'musteri_kart_listesi.dart';

class AktifMusteriler extends StatelessWidget {
  final dynamic isletmebilgi;
  final int kullanicirolu;

  const AktifMusteriler({
    Key? key,
    required this.isletmebilgi,
    required this.kullanicirolu,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      body: MusteriKartListesi(
        isletmebilgi: isletmebilgi,
        kullanicirolu: kullanicirolu,
        durum: '1',
        accent: const Color(0xFF2196F3),
        bosBaslik: 'Aktif müşteri yok',
        bosAciklama:
            'Yakın zamanda randevu almış müşterilerin burada görünür.',
      ),
    );
  }
}

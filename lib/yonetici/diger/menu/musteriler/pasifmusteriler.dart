import 'package:flutter/material.dart';

import 'musteri_kart_listesi.dart';

class PasifMusteriler extends StatelessWidget {
  final dynamic isletmebilgi;
  final int kullanicirolu;

  const PasifMusteriler({
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
        durum: '0',
        accent: const Color(0xFFFF9800),
        bosBaslik: 'Pasif müşteri yok',
        bosAciklama:
            'Uzun süredir randevu almamış müşteriler burada listelenir. Onlara mesaj atmak için iyi bir liste.',
      ),
    );
  }
}

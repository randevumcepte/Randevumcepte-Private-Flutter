import 'package:flutter/material.dart';

import 'musteri_kart_listesi.dart';

class SadikMusteriler extends StatelessWidget {
  final dynamic isletmebilgi;
  final int kullanicirolu;

  const SadikMusteriler({
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
        durum: '2',
        accent: const Color(0xFF4CAF50),
        bosBaslik: 'Sadık müşteri görünmüyor',
        bosAciklama:
            'Düzenli randevu alan müşterilerin burada listelenir. Birkaç ziyaret sonrası listelenmeye başlar.',
      ),
    );
  }
}

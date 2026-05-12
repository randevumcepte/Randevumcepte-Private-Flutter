import 'package:flutter/material.dart';

import 'musteri_kart_listesi.dart';

class TumMusteriler extends StatelessWidget {
  final dynamic isletmebilgi;
  final int kullanicirolu;

  const TumMusteriler({
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
        durum: '3',
        accent: Theme.of(context).colorScheme.primary,
        bosBaslik: 'Henüz müşteri yok',
        bosAciklama:
            'Sağ üstteki + butonu ile müşteri ekleyebilir ya da rehberden hızlıca aktarabilirsin.',
      ),
    );
  }
}

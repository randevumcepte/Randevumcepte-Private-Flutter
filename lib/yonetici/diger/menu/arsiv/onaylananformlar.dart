import 'package:flutter/material.dart';
import 'arsiv_kart_liste.dart';

class OnaylananArsiv extends StatelessWidget {
  const OnaylananArsiv({super.key});

  @override
  Widget build(BuildContext context) {
    return const ArsivKartListe(
      durum: '1',
      cevapladi: '1',
      cevapladi2: '1',
      bosMesaj: 'Onaylanmış form yok',
      bosIkon: Icons.check_circle_outline,
    );
  }
}

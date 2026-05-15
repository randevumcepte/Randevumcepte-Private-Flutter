import 'package:flutter/material.dart';
import 'arsiv_kart_liste.dart';

class BeklenenArsiv extends StatelessWidget {
  const BeklenenArsiv({super.key});

  @override
  Widget build(BuildContext context) {
    return const ArsivKartListe(
      durum: 'null',
      cevapladi: 'b',
      cevapladi2: 'b',
      bosMesaj: 'Bekleyen form yok',
      bosIkon: Icons.hourglass_empty_rounded,
    );
  }
}

import 'package:flutter/material.dart';
import 'arsiv_kart_liste.dart';

class HariciArsiv extends StatelessWidget {
  const HariciArsiv({super.key});

  @override
  Widget build(BuildContext context) {
    return const ArsivKartListe(
      durum: 'null',
      cevapladi: 'null',
      cevapladi2: 'null',
      bosMesaj: 'Harici belge yok',
      bosIkon: Icons.upload_file_rounded,
    );
  }
}

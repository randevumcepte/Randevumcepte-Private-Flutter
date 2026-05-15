import 'package:flutter/material.dart';
import 'arsiv_kart_liste.dart';

class IptalEdilenArsiv extends StatelessWidget {
  const IptalEdilenArsiv({super.key});

  @override
  Widget build(BuildContext context) {
    return const ArsivKartListe(
      durum: '0',
      cevapladi: '',
      cevapladi2: '',
      bosMesaj: 'İptal edilmiş form yok',
      bosIkon: Icons.cancel_outlined,
    );
  }
}

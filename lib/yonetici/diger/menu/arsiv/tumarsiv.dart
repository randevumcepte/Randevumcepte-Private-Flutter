import 'package:flutter/material.dart';
import 'package:randevu_sistem/theme/premium_components.dart';
import 'arsiv_kart_liste.dart';

class TumArsiv extends StatelessWidget {
  const TumArsiv({super.key});

  @override
  Widget build(BuildContext context) {
    return PremiumGradientBg(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Tüm Formlar',
            style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w700,
                fontSize: 16),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const SafeArea(
          child: ArsivKartListe(
            durum: '',
            cevapladi: '',
            cevapladi2: '',
            bosMesaj: 'Henüz form yok',
            bosIkon: Icons.inbox_outlined,
          ),
        ),
      ),
    );
  }
}

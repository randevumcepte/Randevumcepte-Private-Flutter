// Cagri Merkezi — sekmeli tek sayfa.
// 4 ekran tek menude toplanir:
//   - Performans (Dashboard)      : SADECE hesap sahibi (rol == 1)
//   - Arama Randevu Takvimi        : herkes
//   - Arama Ekrani (calisma)       : herkes
//   - Kayitlar (Santral/CDR)       : herkes (personel sadece kendi dahilisi -> sadeceDahili)
//
// Menu gate'i (diger_page.dart): uyelik_turu == 3.
// Arama: WebRTC YOK — Bria (santral originate) uzerinden (alt ekranlarda).

import 'package:flutter/material.dart';
import 'package:randevu_sistem/Frontend/dialpad.dart';
import 'package:randevu_sistem/Models/user.dart';
import 'package:randevu_sistem/yonetici/santral/santralraporlari.dart';

import 'arama_ekrani.dart';
import 'arama_randevu_takvim.dart';
import 'cagri_dashboard.dart';

class CagriMerkeziSayfa extends StatelessWidget {
  final dynamic isletmebilgi;
  final int kullanicirolu;
  final Kullanici kullanici;
  final DialPadManager dialPadManager;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;
  final String sadeceDahili; // personel (rol 5) ise sadece kendi dahilisinin kayitlari

  const CagriMerkeziSayfa({
    Key? key,
    required this.isletmebilgi,
    required this.kullanicirolu,
    required this.kullanici,
    required this.dialPadManager,
    required this.scaffoldMessengerKey,
    this.sadeceDahili = '',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool sahip = kullanicirolu == 1; // Performans sekmesi sadece hesap sahibinde

    final tabs = <Tab>[
      if (sahip) const Tab(icon: Icon(Icons.bar_chart_rounded), text: 'Performans'),
      const Tab(icon: Icon(Icons.event_note_rounded), text: 'Randevu Takvimi'),
      const Tab(icon: Icon(Icons.dialpad_rounded), text: 'Arama Ekranı'),
      const Tab(icon: Icon(Icons.phone_in_talk_rounded), text: 'Kayıtlar'),
    ];

    final views = <Widget>[
      if (sahip)
        CagriDashboard(
          isletmebilgi: isletmebilgi,
          kullanicirolu: kullanicirolu,
          gomulu: true,
        ),
      AramaRandevuTakvimi(
        isletmebilgi: isletmebilgi,
        kullanicirolu: kullanicirolu,
      ),
      AramaEkrani(
        isletmebilgi: isletmebilgi,
        kullanicirolu: kullanicirolu,
        gomulu: true,
      ),
      CDRRaporlari(
        isletmebilgi: isletmebilgi,
        kullanicirolu: kullanicirolu,
        kullanici: kullanici,
        dialPadManager: dialPadManager,
        scaffoldMessengerKey: scaffoldMessengerKey,
        // Personel rolunde ise SADECE kendi dahilisine ait CDR gorunur.
        sadeceDahili: sadeceDahili,
      ),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Çağrı Merkezi',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          bottom: TabBar(
            isScrollable: true,
            labelColor: const Color(0xFF6D28D9),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF6D28D9),
            indicatorWeight: 3,
            tabs: tabs,
          ),
        ),
        body: TabBarView(children: views),
      ),
    );
  }
}

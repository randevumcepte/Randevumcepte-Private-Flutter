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
      if (sahip) const Tab(text: 'Performans'),
      const Tab(text: 'Takvim'),
      const Tab(text: 'Atanan\nAramalar'),
      const Tab(text: 'Kayıtlar'),
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
      // Cagri Kayitlari = Santral CDR icerigi, kendi basligi OLMADAN (gomulu)
      // dogrudan bu sekmenin icinde. Filtre butonu gomulu modda FAB olarak gelir.
      CDRRaporlari(
        isletmebilgi: isletmebilgi,
        kullanicirolu: kullanicirolu,
        kullanici: kullanici,
        dialPadManager: dialPadManager,
        scaffoldMessengerKey: scaffoldMessengerKey,
        // Personel rolunde ise SADECE kendi dahilisine ait CDR gorunur.
        sadeceDahili: sadeceDahili,
        gomulu: true,
      ),
    ];

    const mor = Color(0xFF6D28D9);
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Çağrı Merkezi',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1ECFA),
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(4),
                child: TabBar(
                  isScrollable: false, // tam genislik — sekmeler ekrani kaplar
                  labelColor: Colors.white,
                  unselectedLabelColor: mor,
                  labelStyle: const TextStyle(
                      fontSize: 11.5, fontWeight: FontWeight.w800, height: 1.1),
                  unselectedLabelStyle: const TextStyle(
                      fontSize: 11.5, fontWeight: FontWeight.w600, height: 1.1),
                  indicator: BoxDecoration(
                    color: mor,
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [
                      BoxShadow(
                          color: mor.withOpacity(.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3)),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  padding: EdgeInsets.zero,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 2),
                  tabs: tabs,
                ),
              ),
            ),
          ),
        ),
        body: TabBarView(children: views),
      ),
    );
  }
}

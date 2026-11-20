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
import 'package:url_launcher/url_launcher.dart';
import 'package:randevu_sistem/Frontend/dialpad.dart';
import 'package:randevu_sistem/Models/user.dart';
import 'package:randevu_sistem/telefon/softphone.dart';
import 'package:randevu_sistem/yonetici/santral/santralraporlari.dart';

import 'arama_ekrani.dart';
import 'cagri_api.dart';
import 'arama_randevu_takvim.dart';
import 'cagri_dashboard.dart';
import 'widgets/santral_dakika_karti.dart';

/// Tus takimi softphone'dan dogrudan arar (sunucudan gecmez); santral
/// dakikasi yoksa (tanimli 0 / bitti) softphone tus takimi yerine telefonun
/// kendi tus takimi acilir, alt kirmizi bantta uyarilir.
Future<void> _tusTakimiAc(BuildContext context) async {
  final sube = CagriApi.aktifSube ?? '';
  final uyari = await CagriApi.dakikaEngeli(sube);
  if (!context.mounted) return;
  if (uyari != null) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('⚠️ $uyari Santral araması yapılamaz; '
          'telefonunuzun kendi arama uygulamasını kullanın.'),
      backgroundColor: Colors.redAccent,
      duration: const Duration(seconds: 6),
    ));
    try {
      await launchUrl(Uri(scheme: 'tel', path: ''),
          mode: LaunchMode.externalApplication);
    } catch (_) {}
    return;
  }
  await Softphone.instance.tusTakimiAc(context);
}

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

    // Sira: Atanan Aramalar -> Arama Randevulari -> (Performans: sadece sahip) -> Cagri Kayitlari
    final tabs = <Tab>[
      const Tab(text: 'Atanan\nAramalar'),
      const Tab(text: 'Arama\nRandevuları'),
      if (sahip) const Tab(text: 'Performans'),
      const Tab(text: 'Çağrı\nKayıtları'),
    ];

    final views = <Widget>[
      // Atanan Aramalar (calisma ekrani) — 'Arama Listesi Olustur' FAB burada.
      AramaEkrani(
        isletmebilgi: isletmebilgi,
        kullanicirolu: kullanicirolu,
        gomulu: true,
      ),
      // Arama Randevulari (takvim)
      AramaRandevuTakvimi(
        isletmebilgi: isletmebilgi,
        kullanicirolu: kullanicirolu,
      ),
      // Performans (dashboard) — sadece hesap sahibi
      if (sahip)
        CagriDashboard(
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
          // Softphone modulu acik build'lerde tus takimi (kapaliyken gorunmez).
          actions: [
            if (Softphone.instance.aktif)
              ValueListenableBuilder<bool>(
                valueListenable: Softphone.instance.kayitli,
                builder: (context, kayitli, _) => IconButton(
                  tooltip: kayitli ? 'Tuş takımı' : 'Tuş takımı (santrale bağlı değil)',
                  icon: Icon(Icons.dialpad,
                      color: kayitli ? Colors.green : Colors.grey),
                  onPressed: () => _tusTakimiAc(context),
                ),
              ),
          ],
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
        body: Column(children: [
          // Santral dakikasi (yalniz santral_aktif = 1 isletmede; sunucu da kontrol eder)
          if (CagriApi.santralAktif(isletmebilgi))
            SantralDakikaKarti(
              sube: '${isletmebilgi['id']}',
              kompakt: true,
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 6),
            ),
          Expanded(child: TabBarView(children: views)),
        ]),
      ),
    );
  }
}

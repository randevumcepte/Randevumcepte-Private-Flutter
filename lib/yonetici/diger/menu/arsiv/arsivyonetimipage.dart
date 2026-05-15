import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';

import 'beklenenformlar.dart';
import 'formekle.dart';
import 'form_sablonlari.dart';
import 'haricibelge.dart';
import 'haricibelgeekle.dart';
import 'iptaledilenformlar.dart';
import 'onaylananformlar.dart';
import 'sozlesme_olustur.dart';
import 'tumarsiv.dart';

class ArsivYonetimiPage extends StatefulWidget {
  final dynamic isletmebilgi;
  const ArsivYonetimiPage({Key? key, required this.isletmebilgi})
      : super(key: key);

  @override
  _ArsivYonetimiPageState createState() => _ArsivYonetimiPageState();
}

class _ArsivYonetimiPageState extends State<ArsivYonetimiPage> {
  void _yeniSec(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.18),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 10),
                  child: Text(
                    'Yeni Oluştur',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ),
                _SecimSatiri(
                  icon: Icons.send_rounded,
                  baslik: 'Form Gönder',
                  altYazi: 'Müşteriye onam/anket formu gönder',
                  renk: const Color(0xFF16A34A),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      PageTransition(
                        type: PageTransitionType.rightToLeft,
                        duration: const Duration(milliseconds: 300),
                        child: FormEkle(isletmebilgi: widget.isletmebilgi),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                _SecimSatiri(
                  icon: Icons.handshake_outlined,
                  baslik: 'Sözleşme Oluştur',
                  altYazi: 'Hizmet sözleşmesi hazırla ve gönder',
                  renk: const Color(0xFF0EA5E9),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      PageTransition(
                        type: PageTransitionType.rightToLeft,
                        duration: const Duration(milliseconds: 300),
                        child: SozlesmeOlustur(
                            isletmebilgi: widget.isletmebilgi),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                _SecimSatiri(
                  icon: Icons.upload_file_rounded,
                  baslik: 'Belge Ekle',
                  altYazi: 'Harici bir belgeyi sisteme yükle',
                  renk: const Color(0xFF7C3AED),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      PageTransition(
                        type: PageTransitionType.rightToLeft,
                        duration: const Duration(milliseconds: 300),
                        child: HariciBelgeEkle(
                            isletmebilgi: widget.isletmebilgi),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: DefaultTabController(
        length: 6,
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            centerTitle: false,
            title: const Text(
              'Form Yönetimi',
              style: TextStyle(color: Colors.black),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: <Widget>[
              if (widget.isletmebilgi["demo_hesabi"].toString() == "1")
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: SizedBox(
                    width: 100,
                    child: YukseltButonu(isletme_bilgi: widget.isletmebilgi),
                  ),
                ),
              IconButton(
                onPressed: () => _yeniSec(context),
                icon: const Icon(Icons.add, color: Colors.black),
                iconSize: 26,
              ),
            ],
            backgroundColor: Colors.white,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Container(
                padding: const EdgeInsets.only(bottom: 10),
                child: TabBar(
                  isScrollable: true,
                  indicatorSize: TabBarIndicatorSize.tab,
                  tabAlignment: TabAlignment.start,
                  labelColor: scheme.primary,
                  unselectedLabelColor: scheme.primary.withValues(alpha: 0.7),
                  labelPadding: const EdgeInsets.only(left: 10, right: 10),
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    color: Colors.transparent,
                    border: Border.all(color: scheme.primary, width: 1.5),
                  ),
                  tabs: const [
                    _SekmeEt(text: 'Tümü', genislik: 60),
                    _SekmeEt(text: 'Onaylananlar', genislik: 120),
                    _SekmeEt(text: 'Beklenenler', genislik: 120),
                    _SekmeEt(text: 'İptal Edilenler', genislik: 120),
                    _SekmeEt(text: 'Harici Belgeler', genislik: 130),
                    _SekmeEt(text: 'Form Şablonları', genislik: 140),
                  ],
                ),
              ),
            ),
          ),
          body: TabBarView(
            children: <Widget>[
              TumArsiv(),
              OnaylananArsiv(),
              BeklenenArsiv(),
              IptalEdilenArsiv(),
              HariciArsiv(),
              FormSablonlari(isletmebilgi: widget.isletmebilgi),
            ],
          ),
        ),
      ),
    );
  }
}

class _SekmeEt extends StatelessWidget {
  final String text;
  final double genislik;
  const _SekmeEt({required this.text, required this.genislik});

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: SizedBox(
        width: genislik,
        child: Align(
          alignment: Alignment.center,
          child: Text(
            text,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

class _SecimSatiri extends StatelessWidget {
  final IconData icon;
  final String baslik;
  final String altYazi;
  final Color renk;
  final VoidCallback onTap;
  const _SecimSatiri({
    required this.icon,
    required this.baslik,
    required this.altYazi,
    required this.renk,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: renk.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: renk.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: renk, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      baslik,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      altYazi,
                      style: const TextStyle(
                          fontSize: 11.5, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: renk),
            ],
          ),
        ),
      ),
    );
  }
}

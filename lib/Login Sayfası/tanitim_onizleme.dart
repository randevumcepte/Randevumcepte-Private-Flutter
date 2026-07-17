// Sadece açılış (tanıtım) ekranını TELEFON BOYUTUNDA izole önizlemek için
// geçici giriş noktası. Çalıştırmak için:
//   flutter run -d chrome -t "lib/Login Sayfası/tanitim_onizleme.dart"
// Not: Bu dosya üretimde kullanılmaz; sadece animasyonu hızlı görmek içindir.
import 'package:flutter/material.dart';
import 'tanitim.dart';

void main() {
  runApp(const _OnizlemeApp());
}

class _OnizlemeApp extends StatelessWidget {
  const _OnizlemeApp();

  @override
  Widget build(BuildContext context) {
    // Tipik bir telefon dikey ölçüsü (mantıksal piksel)
    const Size telefonBoyut = Size(390, 844);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tanıtım Önizleme',
      home: Scaffold(
        backgroundColor: const Color(0xFF201033),
        body: Center(
          child: Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: const Color(0xFF0B0B12),
              borderRadius: BorderRadius.circular(46),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 50,
                  spreadRadius: 6,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(36),
              child: SizedBox(
                width: telefonBoyut.width,
                height: telefonBoyut.height,
                // Alt widget'lar (SafeArea vb.) telefondaymış gibi davransın diye
                // MediaQuery'yi telefon ölçüsü + çentik/alt bar boşluklarıyla override et.
                child: MediaQuery(
                  data: const MediaQueryData(
                    size: telefonBoyut,
                    devicePixelRatio: 3.0,
                    padding: EdgeInsets.only(top: 47, bottom: 24),
                  ),
                  child: OnBoardingPage(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

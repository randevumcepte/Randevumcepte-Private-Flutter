
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:randevu_sistem/Frontend/telefon_ulke_alani.dart';
import 'package:randevu_sistem/Frontend/popupdialogs.dart';

// ! import here file animate
import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Frontend/progressloading.dart';
import 'package:randevu_sistem/Models/randevuhizmetleri.dart';
import 'package:randevu_sistem/theme/premium_components.dart';
import 'fade_animation.dart';
import 'login_page.dart';
import 'package:http/http.dart' as http;

class SifremiUnuttum extends StatefulWidget {
  final bool randevuSayfasinaYonlendir;
  final List<RandevuHizmet> seciliHizmetler;
  final String tarih;
  final String saat;

  SifremiUnuttum({Key? key,required this.randevuSayfasinaYonlendir, required this.seciliHizmetler,required this.tarih,required this.saat}) : super(key: key);
  @override
  _SifremiUnuttumState createState() => _SifremiUnuttumState();
}

class _SifremiUnuttumState extends State<SifremiUnuttum> {
TextEditingController ceptelefon = TextEditingController();
  @override
  void initState() {
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return _sayfaIskeleti(scheme, [
      Text(
        'Şifrenizi mi unuttunuz?',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: scheme.onSurface.withValues(alpha: 0.55),
        ),
      ),
      const SizedBox(height: 4),
      Text(
        'Şifremi Unuttum',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.6,
          color: scheme.onSurface,
        ),
      ),
      const SizedBox(height: 24),
      PremiumGlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline,
                      color: Colors.amber.shade800, size: 22),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      "Şifre sıfırlama, sisteme kayıtlı telefon numaranıza SMS olarak gönderilir. SMS ulaşmazsa lütfen işletmenize ulaşınız.",
                      style: TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _telefonAlani(scheme),
          ],
        ),
      ),
      const SizedBox(height: 20),
      _anaButon(scheme, 'Şifremi Gönder', () {
        if (ceptelefon.text == '' || ceptelefon.text == '0') {
          formWarningDialogs(
            context,
            "UYARI",
            "Lütfen sisteme kayıtlı olan telefon numaranızı giriniz",
          );
        } else {
          sifregonder(
            ceptelefon.text,
            context,
            widget.randevuSayfasinaYonlendir,
          );
        }
      }),
      const SizedBox(height: 20),
      _ayirac(scheme),
      const SizedBox(height: 16),
      OutlinedButton(
        onPressed: () => Navigator.pop(context),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          side: BorderSide(
              color: scheme.primary.withValues(alpha: 0.5), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          foregroundColor: scheme.primary,
        ),
        child: const Text(
          'Giriş ekranına dön',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    ]);
  }

  // Giris Yap ekraniyla ayni dekoratif arka plan lekesi
  Widget _decorBlob(Color color, double size) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
            stops: const [0, 1],
          ),
        ),
      ),
    );
  }

  // Giris Yap ekranindaki logo blogu
  Widget _logoBlok(ColorScheme scheme) {
    return Center(
      child: FadeAnimation(
        1,
        Column(
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.28),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.85),
                  width: 4,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Image.asset(
                  'images/aleyna.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Image.asset(
              'images/aleyna.png',
              height: 28,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 6),
            Text(
              'Zaman Şimdi Kontrolünüzde',
              style: TextStyle(
                fontSize: 11.5,
                fontStyle: FontStyle.italic,
                letterSpacing: 0.2,
                color: scheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Giris Yap ekranindaki gradyanli ana aksiyon butonu
  Widget _anaButon(ColorScheme scheme, String yazi, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [scheme.primary, scheme.tertiary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.36),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                yazi,
                style: TextStyle(
                  color: scheme.onPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded, size: 18, color: scheme.onPrimary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ayirac(ColorScheme scheme) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: scheme.onSurface.withValues(alpha: 0.10),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'VEYA',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface.withValues(alpha: 0.45),
              letterSpacing: 0.5,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: scheme.onSurface.withValues(alpha: 0.10),
          ),
        ),
      ],
    );
  }

  Widget _telefonAlani(ColorScheme scheme) {
    return InputDecorator(
      isEmpty: false,
      decoration: const InputDecoration(
        labelText: 'Telefon',
        prefixIcon: Icon(Icons.phone_in_talk_rounded),
      ),
      child: TelefonUlkeAlani(
        controller: ceptelefon,
        renk: scheme.primary,
        cerceveli: false,
        decoration: const InputDecoration(
          border: InputBorder.none,
          isCollapsed: true,
        ),
      ),
    );
  }

  // Giris Yap ekraniyla ayni sayfa iskeleti
  Widget _sayfaIskeleti(ColorScheme scheme, List<Widget> icerik) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    Color.alphaBlend(
                        scheme.primary.withValues(alpha: 0.38), Colors.white),
                    Color.alphaBlend(
                        scheme.tertiary.withValues(alpha: 0.08), Colors.white),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -80,
            right: -60,
            child: _decorBlob(scheme.primary.withValues(alpha: 0.28), 220),
          ),
          Positioned(
            top: size.height * 0.28,
            left: -90,
            child: _decorBlob(scheme.tertiary.withValues(alpha: 0.22), 180),
          ),
          Positioned(
            bottom: -70,
            right: -40,
            child: _decorBlob(scheme.primary.withValues(alpha: 0.18), 200),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom -
                      32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: Icon(Icons.arrow_back_rounded,
                            color: scheme.primary, size: 26),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    _logoBlok(scheme),
                    const SizedBox(height: 32),
                    ...icerik,
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> sifregonder(String tel,context,bool randevuSayfasinaYonlendir) async {
    showProgressLoading(context);
    String appBundle = await appBundleAl();


    Map<String, dynamic> formData = {
      'cep_telefon':tel,
      'sms_baslik' : '',
      'sms_apikey' : '',
      'salonidler' : '415',
      'sms_username':'',
      'sms_secret':'',
      'isletmeadi': 'Aleyna Güzellik Salonu',
      'appBundle': appBundle
      // Add other form fields
    };

    final response = await http.post(
      Uri.parse('https://app.randevumcepte.com.tr/api/v1/sifregonder'),

      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(formData),
    );

    if (response.statusCode == 200) {
      log("cevap body "+response.body);
      Navigator.of(context,rootNavigator: true).pop();
      if(response.body=="error")
        formWarningDialogs(context, "HATA", "Sistemde kayıtlı telefon numarası bulunamadı!");
      else {
        final String maskeli = _maskelePhone(tel);
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.sms_outlined, color: Colors.purple),
                const SizedBox(width: 8),
                const Text("Şifreniz Gönderildi"),
              ],
            ),
            content: Text(
              "Yeni şifreniz $maskeli numaralı telefonunuza SMS olarak gönderildi. "
              "SMS birkaç dakika içinde ulaşmazsa lütfen işletmenize ulaşınız.",
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text("Tamam", style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (builder) => LoginPage(randevuSayfasinaYonlendir: randevuSayfasinaYonlendir,seciliHizmetler:widget.seciliHizmetler,tarih: widget.tarih,saat: widget.saat,),
          ),
        );
      }




    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Şifreniz gönderilirken bir hata oluştu : '+response.statusCode.toString()),
        ),
      );
      debugPrint('Error: ${response.body}');
    }
  }

  String _maskelePhone(String tel) {
    final digits = tel.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 4) return tel;
    final son = digits.substring(digits.length - 2);
    final bas = digits.substring(0, digits.length >= 4 ? 4 : 1);
    return '$bas *** ** $son';
  }

}
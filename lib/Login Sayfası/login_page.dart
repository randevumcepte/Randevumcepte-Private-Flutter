import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:provider/provider.dart';
import 'package:randevu_sistem/Frontend/popupdialogs.dart';
import 'package:randevu_sistem/Frontend/progressloading.dart';
import 'package:randevu_sistem/Login%20Sayfas%C4%B1/kayit_ol.dart';
import 'package:randevu_sistem/Login%20Sayfas%C4%B1/sifremi_unuttum.dart';
import 'package:randevu_sistem/Models/user.dart';
import 'package:randevu_sistem/randevualma/randevuozetonay.dart';
import 'package:randevu_sistem/services/notification_service.dart';
import 'package:randevu_sistem/yonetici/subesecimi.dart';
// ! import here file animate 
import 'package:randevu_sistem/Frontend/indexedstack.dart';
import 'package:randevu_sistem/Models/musteri_danisanlar.dart';
import 'package:randevu_sistem/Models/randevuhizmetleri.dart';
import 'package:randevu_sistem/basic_bottom_nav_bar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:randevu_sistem/musteripaneli/musterialtbar.dart';

import 'package:randevu_sistem/yonetici/dashboard/home_screen.dart';
import 'fade_animation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:randevu_sistem/network_utils/api.dart';
import 'dart:convert';
import 'dart:developer';
import 'package:randevu_sistem/musteripaneli/anasayfa/anasayfa.dart';
import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/theme/premium_components.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();


class LoginPage extends StatefulWidget {
  final bool randevuSayfasinaYonlendir;
  final List<RandevuHizmet> seciliHizmetler;
  final String tarih;
  final String saat;


  LoginPage({Key? key, required this.randevuSayfasinaYonlendir, required this.seciliHizmetler,required this.tarih,required this.saat}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<LoginPage> {
  bool _isSelected = false;

  bool _isLoading = false;
  var cep_telefon;
  var password;
  final _formKey = GlobalKey<FormState>();
  TextEditingController ceptelefon = TextEditingController();
  AutovalidateMode _autoValidate = AutovalidateMode.disabled;
  void _validateInputs() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
    } else {
      setState(() {
        _autoValidate = AutovalidateMode.always;
      });
    }
  } final phoneMask = MaskTextInputFormatter(
    mask: '0### ### ## ##',
    filter: { "#": RegExp(r'[0-9]') },
  );
  @override
  void initState() {
    super.initState();
    cep_telefon = "0";  // Format en başta görünsün
    ceptelefon.text = '0';
  }


  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Soft gradient background
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
          // Decorative blurred blobs for premium depth
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
                child: Form(
                  key: _formKey,
                  autovalidateMode: _autoValidate,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 32),
                      // Logo — icon badge + wordmark, no boxy card
                      Center(
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
                                      color: scheme.primary
                                          .withValues(alpha: 0.28),
                                      blurRadius: 28,
                                      offset: const Offset(0, 12),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: Colors.white
                                        .withValues(alpha: 0.85),
                                    width: 4,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Image.asset(
                                    'images/randevumcepteicon.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Image.asset(
                                'images/randevumcepte.png',
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
                                  color: scheme.onSurface
                                      .withValues(alpha: 0.55),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Tekrar Hoşgeldiniz 👋',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: scheme.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Giriş Yap',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 24),
                    // Form glass card
                    PremiumGlassCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          TextFormField(
                            keyboardType: TextInputType.number,
                            maxLines: 1,
                            controller: ceptelefon,
                            decoration: InputDecoration(
                              labelText: 'Telefon',
                              hintText: '0### ### ## ##',
                              prefixIcon: const Icon(Icons.phone_in_talk_rounded),
                            ),
                            inputFormatters: [phoneMask],
                            validator: (telefonNo) {
                              if (telefonNo!.isEmpty) {
                                return 'Telefon alanı gereklidir';
                              }
                              cep_telefon = telefonNo;
                              ceptelefon.text = telefonNo;
                              return null;
                            },
                            onSaved: (String? val) {
                              cep_telefon = val;
                              ceptelefon.text = val!;
                            },
                            onTap: () {
                              if (ceptelefon.text.length < 2) {
                                ceptelefon.text = "0";
                              }
                              ceptelefon.selection =
                                  TextSelection.fromPosition(
                                TextPosition(offset: ceptelefon.text.length),
                              );
                            },
                            onChanged: (value) {
                              if (!value.startsWith("0")) {
                                ceptelefon.text = "0";
                                ceptelefon.selection =
                                    TextSelection.fromPosition(
                                  TextPosition(
                                      offset: ceptelefon.text.length),
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            obscureText: true,
                            maxLines: 1,
                            decoration: const InputDecoration(
                              labelText: 'Şifre',
                              hintText: '••••••••',
                              prefixIcon: Icon(Icons.lock_outline_rounded),
                            ),
                            validator: (passwordValue) {
                              if (passwordValue!.isEmpty) {
                                return 'Şifre gereklidir';
                              }
                              password = passwordValue;
                              return null;
                            },
                          ),
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (builder) => SifremiUnuttum(
                                      randevuSayfasinaYonlendir:
                                          widget.randevuSayfasinaYonlendir,
                                      seciliHizmetler:
                                          widget.seciliHizmetler,
                                      tarih: widget.tarih,
                                      saat: widget.saat,
                                    ),
                                  ),
                                );
                              },
                              child: Text(
                                'Şifremi Unuttum',
                                style: TextStyle(
                                  color: scheme.primary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Giriş Yap — gradient action button (full width)
                    Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        onTap: () {
                          if (_formKey.currentState!.validate()) {
                            _login();
                          }
                        },
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
                                'Giriş Yap',
                                style: TextStyle(
                                  color: scheme.onPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded,
                                  size: 18, color: scheme.onPrimary),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Divider with text
                    Row(
                      children: [
                        Expanded(
                            child: Container(
                                height: 1,
                                color: scheme.onSurface
                                    .withValues(alpha: 0.10))),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 12),
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
                                color: scheme.onSurface
                                    .withValues(alpha: 0.10))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Müşteri Ol — outlined
                    OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (builder) => KayitOl(
                              randevuSayfasinaYonlendir:
                                  widget.randevuSayfasinaYonlendir,
                              seciliHizmetler: widget.seciliHizmetler,
                              tarih: widget.tarih,
                              saat: widget.saat,
                            ),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                        side: BorderSide(
                            color: scheme.primary.withValues(alpha: 0.5),
                            width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        foregroundColor: scheme.primary,
                      ),
                      child: const Text(
                        'Müşteri Ol',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

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

  void dispose() {
    super.dispose();
  }

  void _login() async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    var oneSignalId = localStorage.getString('onesignal_player_id');
    showProgressLoading(context);
    setState(() {
      _isLoading = true;
    });
    var data = {
      'cep_telefon' : cep_telefon,
      'password' : password,
      'appBundle': await appBundleAl(),
      'cihazBilgi': await cihazBilgisi(),
      'bildirimId':oneSignalId.toString(),
    };


    var res = await Network().authData(data, '/login');
    var body = json.decode(res.body);

    _showMsg(msg) {
      final snackBar = SnackBar(
        content: Text(msg),
        action: SnackBarAction(
          label: 'Close',
          onPressed: () {},
        ),
      );
    }
    log('login body' + body.toString());
    if(body['message']['success']) {
      Navigator.of(context,rootNavigator: true).pop();
      SharedPreferences localStorage = await SharedPreferences.getInstance();
      localStorage.setString('token', json.encode(body['message']['token']));

      localStorage.setString('user', json.encode(body['message']['user']));
      log('giriş yapan kullanıcı giriş bölümü '+json.encode(body['message']['user']));

      localStorage.setString('musteri', json.encode(body['message']['musteri']));
      localStorage.setString('user_type', json.encode(body['message']['user_type']));

      Map<String, dynamic> userMap  = body['message']['user_type'].toString() == '1'? json.decode(json.encode(body['message']['user'])) :json.decode(json.encode(body['message']['musteri'])) ;




      if(body['message']['user_type'].toString() == "1") {



        Kullanici kullanici = Kullanici.fromJson(userMap);
        log("Kullanıcı id : "+kullanici.id.toString());
        //saveVoipTokenToBackend(localStorage.getString('ios_voip_token')??'',kullanici.id.toString(),localStorage.getString('fcm_token')??"");
          if(kullanici.yetkili_olunan_isletmeler.length == 1)
          {
            // FCM cihaz kaydı (yetkili = salon sahibi)
            NotificationService.instance.registerForUser(
              kullaniciTipi: 'yetkili',
              yetkiliId: kullanici.id.toString(),
              salonId: kullanici.yetkili_olunan_isletmeler[0]['salon_id'].toString(),
            );

            localStorage.setString('sube',kullanici.yetkili_olunan_isletmeler[0]['salon_id'].toString());
            localStorage.setString('isletmeadi', kullanici.yetkili_olunan_isletmeler[0]['salonlar']['salon_adi']);


          }
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (context) => (kullanici.yetkili_olunan_isletmeler.length > 1) ? SubeSecimi(kullanici: kullanici, scaffoldMessengerKey: scaffoldMessengerKey,) : BottomNavigationExample(scaffoldMessengerKey: scaffoldMessengerKey, isletmebilgi: kullanici.yetkili_olunan_isletmeler[0]['salonlar'], kullanici: kullanici, uyelikturu: int.parse(kullanici.yetkili_olunan_isletmeler[0]['salonlar']['uyelik_turu'].toString()),),

          ),
              (route) => false,
        ).then((_) {
          // Reset IndexedStackState to 0 after logging in
          Provider.of<IndexedStackState>(context, listen: false).setSelectedIndex(0);
        });
      } else {
        MusteriDanisan musteri = MusteriDanisan.fromJson(userMap);

        var isletmebilgi = musteri.musteri_olunan_salonlar?.firstWhere((element)=>element['salon_id'].toString() == '20')['salonlar'];

        // FCM cihaz kaydı (müşteri)
        NotificationService.instance.registerForUser(
          kullaniciTipi: 'musteri',
          userId: musteri.id.toString(),
        );
        if(widget.randevuSayfasinaYonlendir)
          Navigator.of(context).pop();
        else
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => MusteriAltBar(musteriId: musteri,isletmebilgi :isletmebilgi,scaffoldMessengerKey: scaffoldMessengerKey)
            ),
          );
      }
    } else {
      Navigator.of(context, rootNavigator: true).pop();
      formWarningDialogs(context,'HATA',body['message']['message']);
    }

    setState(() {
      _isLoading = false;
    });
  }


}
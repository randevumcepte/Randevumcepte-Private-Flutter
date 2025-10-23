import 'package:circular_menu/circular_menu.dart';
import 'package:flutter/material.dart';

import '../yonetici/adisyonlar/satislar/tahsilat.dart';
import '../yonetici/diger/menu/musteriler/yeni_musteri.dart';
import '../yonetici/randevular/appointment-editor.dart';
import '../yonetici/randevular/randevu_page.dart';

class AltYuvarlakYeniEkleMenu extends StatelessWidget {
  final dynamic isletme_bilgi;
  AltYuvarlakYeniEkleMenu({Key? key, required this.isletme_bilgi});
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return Stack(
      children: [
        // Ana içerik burada olabilir (body)
        Positioned.fill(
          child: CircularMenu(
            alignment: Alignment.bottomRight,
            backgroundWidget: Container(), // opsiyonel: tıklanınca arka plan
            toggleButtonColor: Colors.purple[800]!,
            toggleButtonIconColor: Colors.white,
            toggleButtonBoxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8.0,
              )
            ],
            toggleButtonMargin: 20.0, // tüm kenarlar için aynı boşluk
            toggleButtonSize: 55.0,
            items: [
              CircularMenuItem(
                icon: Icons.calendar_month,
                color: Color(0xFF9C27B0),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AppointmentEditor(
                        isletmebilgi: isletme_bilgi,
                        tarihsaat: "",
                        personel_id: "",
                      ),
                    ),
                  );
                },
                iconSize: 24,
                iconColor: Colors.white,
                margin: 10,
              ),
              CircularMenuItem(
                icon: Icons.shopping_cart,
                color: Color(0xFF64B5F6),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TahsilatEkrani(
                        isletmebilgi: isletme_bilgi,
                        musteridanisanid: "",
                      ),
                    ),
                  );
                },
                iconSize: 24,
                iconColor: Colors.white,
                margin: 10,
              ),
              CircularMenuItem(
                icon: Icons.person_add_alt_1,
                color: Color(0xFFEA80FC),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Yenimusteri(
                        isletmebilgi: isletme_bilgi,
                        isim: "",
                        telefon: "",
                        sadeceekranikapat: false,
                      ),
                    ),
                  );
                },
                iconSize: 24,
                iconColor: Colors.white,
                margin: 10,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
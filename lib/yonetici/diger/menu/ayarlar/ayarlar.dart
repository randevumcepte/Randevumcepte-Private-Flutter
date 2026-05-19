import 'package:flutter/material.dart';
import 'package:randevu_sistem/Backend/yetki.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:randevu_sistem/theme/theme_picker_screen.dart';
import 'package:randevu_sistem/yonetici/diger/menu/ayarlar/isletmebilgileri.dart';
import 'package:randevu_sistem/yonetici/diger/menu/ayarlar/odalar/odalar.dart';
import 'package:randevu_sistem/yonetici/diger/menu/ayarlar/personeller/calisma_saatleri.dart';
import 'package:randevu_sistem/yonetici/diger/menu/ayarlar/personeller/personeller.dart';
import 'package:randevu_sistem/yonetici/diger/menu/ayarlar/randevuayarlari.dart';
import 'package:randevu_sistem/yonetici/diger/menu/ayarlar/urunler/urunler.dart';
import 'cihazlar/cihazlar.dart';
import 'hizmetler/hizmetler.dart';
import 'musteriindirimleri/musteriindirimpage.dart';

class Ayarlar extends StatefulWidget {
  final dynamic isletmebilgi;
  final int kullanicirolu;
  const Ayarlar({Key? key, required this.isletmebilgi, required this.kullanicirolu}) : super(key: key);

  @override
  _AyarlarState createState() => _AyarlarState();
}

class _AyarlarState extends State<Ayarlar> {
  // Ayarlar öğeleri için veri listesi
  final List<AyarlarItem> _ayarlarListesi = [];

  @override
  void initState() {
    super.initState();
    // Her ayar kutusu kendi yetkisine bagli:
    //  - Isletme Bilgileri / Calisma Saatleri -> ayar.salon_bilgi
    //  - Cihazlar / Odalar                    -> ayar.cihaz_oda_yonet
    //  - Online Randevu                       -> randevu.online_ayar
    //  - Hizmetler / Musteri Indirimleri / Gorunum -> herkese acik
    if (Yetki.varMi('ayar.salon_bilgi')) {
      _ayarlarListesi.add(AyarlarItem(
        title: 'İşletme Bilgileri',
        icon: Icons.business_rounded,
        iconColor: const Color(0xFF5C008E),
        gradientColors: [const Color(0xFF8B5CF6), const Color(0xFF5C008E)],
        route: IsletmeBilgileri(isletmebilgi: widget.isletmebilgi),
      ));
      _ayarlarListesi.add(AyarlarItem(
        title: 'Çalışma Saatleri',
        icon: Icons.access_time_rounded,
        iconColor: const Color(0xFF4A6FA5),
        gradientColors: [const Color(0xFF6A8BC2), const Color(0xFF4A6FA5)],
        route: CalismaSaatleri(isletmebilgi: widget.isletmebilgi),
      ));
    }
    if (Yetki.varMi('hizmet.tanim_olustur') || Yetki.varMi('hizmet.kategori_yonet')) {
      _ayarlarListesi.add(AyarlarItem(
        title: 'Hizmetler',
        icon: Icons.spa_rounded,
        iconColor: const Color(0xFF4CAF93),
        gradientColors: [const Color(0xFF6FC8B1), const Color(0xFF4CAF93)],
        route: Hizmetler(isletmebilgi: widget.isletmebilgi),
      ));
    }
    if (Yetki.varMi('ayar.cihaz_oda_yonet')) {
      _ayarlarListesi.add(AyarlarItem(
        title: 'Cihazlar',
        icon: Icons.devices_rounded,
        iconColor: const Color(0xFFF57C51),
        gradientColors: [const Color(0xFFF79A77), const Color(0xFFF57C51)],
        route: Cihazlar(isletmebilgi: widget.isletmebilgi),
      ));
      _ayarlarListesi.add(AyarlarItem(
        title: 'Odalar',
        icon: Icons.meeting_room_rounded,
        iconColor: const Color(0xFF9B6CA7),
        gradientColors: [const Color(0xFFB38BC1), const Color(0xFF9B6CA7)],
        route: Odalar(isletmebilgi: widget.isletmebilgi),
      ));
    }
    if (Yetki.varMi('randevu.online_ayar')) {
      _ayarlarListesi.add(AyarlarItem(
        title: 'Online Randevu',
        icon: Icons.calendar_today_rounded,
        iconColor: const Color(0xFF42A5F5),
        gradientColors: [const Color(0xFF64B5F6), const Color(0xFF42A5F5)],
        route: RandevuAyarlari(isletmebilgi: widget.isletmebilgi),
      ));
    }
    if (Yetki.varMi('satis.indirim_uygula')) {
      _ayarlarListesi.add(AyarlarItem(
        title: 'Müşteri İndirimleri',
        icon: Icons.discount_rounded,
        iconColor: const Color(0xFFF44336),
        gradientColors: [const Color(0xFFEF5350), const Color(0xFFF44336)],
        route: MusteriIndirimleri(isletmebilgi: widget.isletmebilgi),
      ));
    }
    _ayarlarListesi.add(AyarlarItem(
      title: 'Görünüm',
      icon: Icons.palette_rounded,
      iconColor: const Color(0xFF7C3AED),
      gradientColors: [const Color(0xFFA78BFA), const Color(0xFF7C3AED)],
      route: ThemePickerScreen(
        canEditServer: widget.kullanicirolu < 4,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final bool isTablet = MediaQuery.of(context).size.width >= 600;
    final bool isDesktop = MediaQuery.of(context).size.width >= 1024;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Color.alphaBlend(
                  scheme.primary.withValues(alpha: 0.36), Colors.white),
              Color.alphaBlend(
                  scheme.tertiary.withValues(alpha: 0.08), Colors.white),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(child: _buildBody(isTablet, isDesktop)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: scheme.onSurface),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(
              'Ayarlar',
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
          ),
          if (widget.isletmebilgi["demo_hesabi"].toString() == "1")
            SizedBox(
              width: 110,
              child: YukseltButonu(isletme_bilgi: widget.isletmebilgi),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(bool isTablet, bool isDesktop) {
    final scheme = Theme.of(context).colorScheme;
    final bool isTabletLandscape =
        isTablet && MediaQuery.of(context).orientation == Orientation.landscape;
    return Padding(
      padding: EdgeInsets.all(isDesktop ? 24 : isTablet ? 20 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık ve açıklama
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "İşletme Ayarları",
                  style: TextStyle(
                    fontSize: isDesktop ? 26 : isTablet ? 22 : 19,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "İşletmenizin ayarlarını buradan yönetebilirsiniz",
                  style: TextStyle(
                    fontSize: isDesktop ? 14 : 12,
                    color: scheme.onSurface.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // GridView ile ayar kartları
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount:
                    isDesktop ? 4 : isTabletLandscape ? 4 : isTablet ? 3 : 2,
                crossAxisSpacing: isDesktop ? 20 : isTablet ? 16 : 12,
                mainAxisSpacing: isDesktop ? 20 : isTablet ? 16 : 12,
                childAspectRatio: isDesktop
                    ? 1.1
                    : isTabletLandscape
                        ? 1.4
                        : isTablet
                            ? 1.05
                            : 1.0,
              ),
              itemCount: _ayarlarListesi.length,
              itemBuilder: (context, index) {
                return _buildSettingCard(_ayarlarListesi[index]);
              },
            ),
          ),

          // Alt bilgilendirme
        ],
      ),
    );
  }

  Widget _buildSettingCard(AyarlarItem item) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Color.alphaBlend(
                item.gradientColors[0].withValues(alpha: 0.06), Colors.white),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => item.route),
            );
          },
          splashColor: item.gradientColors[0].withValues(alpha: 0.10),
          highlightColor: item.gradientColors[0].withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: item.gradientColors,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: item.gradientColors[0]
                                .withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(item.icon, color: Colors.white, size: 20),
                    ),
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: item.gradientColors[0].withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: item.iconColor,
                        size: 11,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _getDescription(item.title),
                  style: TextStyle(
                    fontSize: 11,
                    color: scheme.onSurface.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getDescription(String title) {
    switch (title) {
      case 'İşletme Bilgileri':
        return 'İşletme kimliği, iletişim ve fatura bilgileri';
      case 'Çalışma Saatleri':
        return 'Çalışma saatlerinizi düzenleyin';
      case 'Personeller':
        return 'Personel bilgilerini yönetin';
      case 'Hizmetler':
        return 'Hizmetlerinizi düzenleyin';
      case 'Cihazlar':
        return 'Cihazlarınızı yönetin';
      case 'Odalar':
        return 'Oda bilgilerini düzenleyin';
      case 'Online Randevu':
        return 'Online randevu sistemini yapılandırın';
      case 'Müşteri İndirimleri':
        return 'İndirim politikalarınızı belirleyin';
      case 'Ürünler':
        return 'Ürünlerinizi yönetin';
      default:
        return 'Ayarları yönetin';
    }
  }

  Widget _buildFooterInfo() {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F7FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: Color(0xFF4299E1),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Ayarlarınız güvende",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Tüm ayarlarınız güvenli bir şekilde saklanır",
                  style: TextStyle(
                    color: const Color(0xFF718096).withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Ayarlar öğeleri için model sınıfı
class AyarlarItem {
  final String title;
  final IconData icon;
  final Color iconColor;
  final List<Color> gradientColors;
  final Widget route;

  AyarlarItem({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.gradientColors,
    required this.route,
  });
}
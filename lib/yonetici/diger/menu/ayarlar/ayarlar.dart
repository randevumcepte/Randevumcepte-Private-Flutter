import 'package:flutter/material.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
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
    _ayarlarListesi.addAll([
      AyarlarItem(
        title: 'Çalışma Saatleri',
        icon: Icons.access_time_rounded,
        iconColor: const Color(0xFF4A6FA5),
        gradientColors: [const Color(0xFF6A8BC2), const Color(0xFF4A6FA5)],
        route: CalismaSaatleri(isletmebilgi: widget.isletmebilgi),
      ),

      AyarlarItem(
        title: 'Hizmetler',
        icon: Icons.spa_rounded,
        iconColor: const Color(0xFF4CAF93),
        gradientColors: [const Color(0xFF6FC8B1), const Color(0xFF4CAF93)],
        route: Hizmetler(isletmebilgi: widget.isletmebilgi),
      ),
      AyarlarItem(
        title: 'Cihazlar',
        icon: Icons.devices_rounded,
        iconColor: const Color(0xFFF57C51),
        gradientColors: [const Color(0xFFF79A77), const Color(0xFFF57C51)],
        route: Cihazlar(isletmebilgi: widget.isletmebilgi),
      ),
      AyarlarItem(
        title: 'Odalar',
        icon: Icons.meeting_room_rounded,
        iconColor: const Color(0xFF9B6CA7),
        gradientColors: [const Color(0xFFB38BC1), const Color(0xFF9B6CA7)],
        route: Odalar(isletmebilgi: widget.isletmebilgi),
      ),
      AyarlarItem(
        title: 'Randevu Ayarları',
        icon: Icons.calendar_today_rounded,
        iconColor: const Color(0xFF42A5F5),
        gradientColors: [const Color(0xFF64B5F6), const Color(0xFF42A5F5)],
        route: RandevuAyarlari(isletmebilgi: widget.isletmebilgi),
      ),
      AyarlarItem(
        title: 'Müşteri İndirimleri',
        icon: Icons.discount_rounded,
        iconColor: const Color(0xFFF44336),
        gradientColors: [const Color(0xFFEF5350), const Color(0xFFF44336)],
        route: MusteriIndirimleri(isletmebilgi: widget.isletmebilgi),
      ),

    ]);
  }

  @override
  Widget build(BuildContext context) {
    final bool isTablet = MediaQuery.of(context).size.width >= 600;
    final bool isDesktop = MediaQuery.of(context).size.width >= 1024;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _buildAppBar(),
      body: _buildBody(isTablet, isDesktop),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      title: const Text(
        "Ayarlar",
        style: TextStyle(
          color: Color(0xFF333333),
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      centerTitle: false,
      toolbarHeight: 70,
      leading: Container(
        margin: const EdgeInsets.only(left: 8),
        child: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F3F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF4A5568), size: 20),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      actions: [
        if (widget.isletmebilgi["demo_hesabi"].toString() == "1")
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: SizedBox(
              width: 110,
              child: YukseltButonu(isletme_bilgi: widget.isletmebilgi),
            ),
          ),
      ],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(20),
        ),
      ),
    );
  }

  Widget _buildBody(bool isTablet, bool isDesktop) {
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
                    fontSize: isDesktop ? 28 : isTablet ? 24 : 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "İşletmenizin ayarlarını buradan yönetebilirsiniz",
                  style: TextStyle(
                    fontSize: isDesktop ? 16 : 14,
                    color: const Color(0xFF718096),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          // GridView ile ayar kartları
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isDesktop ? 4 : isTablet ? 3 : 2,
                crossAxisSpacing: isDesktop ? 20 : isTablet ? 16 : 12,
                mainAxisSpacing: isDesktop ? 20 : isTablet ? 16 : 12,
                childAspectRatio: isDesktop ? 1.1 : isTablet ? 1.05 : 1.0,
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
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => item.route),
          );
        },
        splashColor: item.gradientColors[0].withOpacity(0.1),
        highlightColor: item.gradientColors[0].withOpacity(0.05),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                item.gradientColors[0].withOpacity(0.08),
                item.gradientColors[1].withOpacity(0.03),
              ],
            ),
            border: Border.all(
              color: Colors.grey.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // İkon konteyneri
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: item.gradientColors,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: item.gradientColors[0].withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    item.icon,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),

              const SizedBox(height: 5),

              // Başlık
              Text(
                item.title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3748),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 4),

              // Açıklama (isteğe bağlı)
              Text(
                _getDescription(item.title),
                style: TextStyle(
                  fontSize: 12,
                  color: const Color(0xFF718096).withOpacity(0.8),
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 4),

              // Ok işareti
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: item.gradientColors[0].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: item.iconColor,
                    size: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getDescription(String title) {
    switch (title) {
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
      case 'Randevu Ayarları':
        return 'Randevu sistemini yapılandırın';
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
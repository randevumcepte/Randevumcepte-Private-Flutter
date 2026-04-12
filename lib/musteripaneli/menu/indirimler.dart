import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../Models/musteri_danisanlar.dart';

class KazanilanIndirimlerPage extends StatefulWidget {
  final MusteriDanisan md;
  final dynamic isletmebilgi;

  const KazanilanIndirimlerPage({
    Key? key,
    required this.md,
    this.isletmebilgi,
  }) : super(key: key);

  @override
  State<KazanilanIndirimlerPage> createState() => _KazanilanIndirimlerPageState();
}

class _KazanilanIndirimlerPageState extends State<KazanilanIndirimlerPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Örnek indirim verileri (gerçek uygulamada API'den gelecek)
  final List<Map<String, dynamic>> _kazanilanIndirimler = [
    {
      'id': '1',
      'indirim_turu': 'Yüzde İndirimi',
      'indirim_miktari': 20,
      'indirim_tipi': 'yuzde',
      'urun_adi': 'Kişisel Antrenman Paketi',
      'kazanilma_tarihi': DateTime.now().subtract(const Duration(days: 2)),
      'son_kullanim_tarihi': DateTime.now().add(const Duration(days: 30)),
      'kod': 'CARK20ABC',
      'durum': 'aktif',
      'aciklama': 'Kişisel antrenman paketlerinde %20 indirim',
      'min_sepet_tutari': 500,
      'renk_kodu': 0xFF9C27B0, // Mor
    },
    {
      'id': '2',
      'indirim_turu': 'Sabit İndirim',
      'indirim_miktari': 100,
      'indirim_tipi': 'sabit',
      'urun_adi': 'Beslenme Danışmanlığı',
      'kazanilma_tarihi': DateTime.now().subtract(const Duration(days: 5)),
      'son_kullanim_tarihi': DateTime.now().add(const Duration(days: 15)),
      'kod': 'CARK100XYZ',
      'durum': 'aktif',
      'aciklama': 'Beslenme danışmanlığı paketlerinde 100 TL indirim',
      'min_sepet_tutari': 300,
      'renk_kodu': 0xFFFF9800, // Turuncu
    },
    {
      'id': '3',
      'indirim_turu': 'Ücretsiz Hizmet',
      'indirim_miktari': 0,
      'indirim_tipi': 'ucretsiz',
      'urun_adi': '1 Seans Masaj',
      'kazanilma_tarihi': DateTime.now().subtract(const Duration(days: 10)),
      'son_kullanim_tarihi': DateTime.now().add(const Duration(days: 45)),
      'kod': 'CARKFREE123',
      'durum': 'aktif',
      'aciklama': '1 saat ücretsiz masaj seansı',
      'renk_kodu': 0xFF4CAF50, // Yeşil
    },
    {
      'id': '4',
      'indirim_turu': 'Yüzde İndirimi',
      'indirim_miktari': 15,
      'indirim_tipi': 'yuzde',
      'urun_adi': 'Grup Dersleri',
      'kazanilma_tarihi': DateTime.now().subtract(const Duration(days: 15)),
      'son_kullanim_tarihi': DateTime.now().subtract(const Duration(days: 1)), // Süresi dolmuş
      'kod': 'CARK15DEF',
      'durum': 'suresi_doldu',
      'aciklama': 'Tüm grup derslerinde %15 indirim',
      'min_sepet_tutari': 200,
      'renk_kodu': 0xFFF44336, // Kırmızı
    },
    {
      'id': '5',
      'indirim_turu': 'Sabit İndirim',
      'indirim_miktari': 50,
      'indirim_tipi': 'sabit',
      'urun_adi': 'Supplement Ürünleri',
      'kazanilma_tarihi': DateTime.now().subtract(const Duration(days: 20)),
      'son_kullanim_tarihi': DateTime.now().add(const Duration(days: 60)),
      'kod': 'CARK50GHI',
      'durum': 'aktif',
      'aciklama': 'Tüm supplement ürünlerinde 50 TL indirim',
      'min_sepet_tutari': 250,
      'renk_kodu': 0xFF2196F3, // Mavi
    },
    {
      'id': '6',
      'indirim_turu': 'Sabit İndirim',
      'indirim_miktari': 25,
      'indirim_tipi': 'sabit',
      'urun_adi': 'Yoga Dersleri',
      'kazanilma_tarihi': DateTime.now().subtract(const Duration(days: 25)),
      'son_kullanim_tarihi': DateTime.now().add(const Duration(days: 10)),
      'kod': 'CARK25JKL',
      'durum': 'aktif',
      'aciklama': 'Yoga derslerinde 25 TL indirim',
      'min_sepet_tutari': 150,
      'renk_kodu': 0xFFE91E63, // Pembe
    },
  ];

  String _selectedFilter = 'tumu'; // tumu, aktif, suresi_dolan, kullanilan

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _formatTarih(DateTime tarih) {
    return DateFormat('dd MMM yyyy', 'tr_TR').format(tarih);
  }

  String _formatKisaTarih(DateTime tarih) {
    return DateFormat('dd MMM', 'tr_TR').format(tarih);
  }

  IconData _getIndirimIcon(String tip) {
    switch (tip) {
      case 'yuzde':
        return Icons.percent;
      case 'sabit':
        return Icons.attach_money;
      case 'ucretsiz':
        return Icons.card_giftcard;
      default:
        return Icons.discount;
    }
  }

  Color _getDurumRengi(String durum) {
    switch (durum) {
      case 'aktif':
        return Colors.green;
      case 'suresi_doldu':
        return Colors.red;
      case 'kullanildi':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  String _getDurumText(String durum) {
    switch (durum) {
      case 'aktif':
        return 'Aktif';
      case 'suresi_doldu':
        return 'Süresi Doldu';
      case 'kullanildi':
        return 'Kullanıldı';
      default:
        return durum;
    }
  }

  String _getIndirimText(Map<String, dynamic> indirim) {
    if (indirim['indirim_tipi'] == 'yuzde') {
      return '%${indirim['indirim_miktari']} İndirim';
    } else if (indirim['indirim_tipi'] == 'sabit') {
      return '${indirim['indirim_miktari']} TL İndirim';
    } else if (indirim['indirim_tipi'] == 'ucretsiz') {
      return 'Ücretsiz Hizmet';
    }
    return 'İndirim';
  }

  List<Map<String, dynamic>> _getFiltrelenmisIndirimler() {
    if (_selectedFilter == 'tumu') {
      return _kazanilanIndirimler;
    }
    return _kazanilanIndirimler.where((indirim) => indirim['durum'] == _selectedFilter).toList();
  }

  int _getFilterCount(String filter) {
    if (filter == 'tumu') {
      return _kazanilanIndirimler.length;
    }
    return _kazanilanIndirimler.where((indirim) => indirim['durum'] == filter).length;
  }

  Widget _buildFiltreButonlari() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      height: 45,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildFiltreButonu('tumu', 'Tümü', Icons.all_inbox, _getFilterCount('tumu')),
          _buildFiltreButonu('aktif', 'Aktif', Icons.check_circle, _getFilterCount('aktif')),
          _buildFiltreButonu('suresi_doldu', 'Süresi Dolan', Icons.timer_off, _getFilterCount('suresi_doldu')),
          _buildFiltreButonu('kullanildi', 'Kullanılan', Icons.done_all, _getFilterCount('kullanildi')),
        ],
      ),
    );
  }

  Widget _buildFiltreButonu(String filtre, String label, IconData icon, int count) {
    bool isSelected = _selectedFilter == filtre;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filtre;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.purple : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? Colors.purple : Colors.grey.shade300,
            width: 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.purple.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey.shade600,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade600,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIndirimKarti(Map<String, dynamic> indirim) {
    bool isActive = indirim['durum'] == 'aktif';
    bool isExpired = indirim['durum'] == 'suresi_doldu';
    Color renk = Color(indirim['renk_kodu'] ?? 0xFF9C27B0);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Süresi doldu etiketi
          if (isExpired)
            Positioned(
              top: 16,
              right: -8,
              child: Transform.rotate(
                angle: 0.1,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.red.shade400,
                        Colors.red.shade600,
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                  child: const Text(
                    'SÜRESİ DOLDU',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),

          // Kullanıldı etiketi
          if (indirim['durum'] == 'kullanildi')
            Positioned(
              top: 16,
              right: -8,
              child: Transform.rotate(
                angle: 0.1,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.grey.shade500,
                        Colors.grey.shade700,
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                  child: const Text(
                    'KULLANILDI',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),

          // Ana kart içeriği
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üst kısım - İndirim bilgisi ve durum
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // İkon
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            renk.withOpacity(0.2),
                            renk.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Icon(
                          _getIndirimIcon(indirim['indirim_tipi']),
                          color: renk,
                          size: 28,
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // İndirim bilgisi
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getIndirimText(indirim),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: renk,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            indirim['urun_adi'],
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Durum göstergesi (sadece aktif için)
                    if (isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Aktif',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // Orta kısım - İndirim kodu
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: renk.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.qr_code,
                          color: renk,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'İndirim Kodu',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              indirim['kod'],
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: renk,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isActive)
                        GestureDetector(
                          onTap: () {
                            // Kodu kopyala
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(Icons.check_circle, color: Colors.white, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Kod kopyalandı: ${indirim['kod']}',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor: renk,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: renk.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.copy,
                              color: renk,
                              size: 18,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Açıklama ve detaylar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Açıklama
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.grey.shade400,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            indirim['aciklama'],
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Minimum sepet tutarı
                    if (indirim['min_sepet_tutari'] != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.shopping_basket_outlined,
                            color: Colors.grey.shade400,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Minimum sepet tutarı: ${indirim['min_sepet_tutari']} TL',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Alt kısım - Tarih bilgileri
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    // Kazanılma tarihi
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.card_giftcard,
                            color: Colors.grey.shade400,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Kazanma',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                _formatKisaTarih(indirim['kazanilma_tarihi']),
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Son kullanma tarihi
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(
                            Icons.event,
                            color: isExpired ? Colors.red.shade300 : Colors.green.shade300,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Son Kullanım',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isExpired ? Colors.red.shade300 : Colors.grey,
                                ),
                              ),
                              Text(
                                _formatKisaTarih(indirim['son_kullanim_tarihi']),
                                style: TextStyle(
                                  color: isExpired ? Colors.red.shade400 : Colors.green.shade600,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBosDurum() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.discount_outlined,
                  size: 80,
                  color: Colors.purple.withOpacity(0.3),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Henüz indirim bulunmuyor',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D2D2D),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Çarkıfelek\'i çevirerek harika indirimler kazanabilirsin!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/carkifelek');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.auto_awesome, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Çarkıfelek\'e Git',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    final filtrelenmisIndirimler = _getFiltrelenmisIndirimler();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text(
          'İndirimlerim',
          style: TextStyle(
            color: Color(0xFF2D2D2D),
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        toolbarHeight: 60,
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_back,
              color: Colors.purple,
              size: 20,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.help_outline,
                color: Colors.purple,
                size: 20,
              ),
            ),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (context) => Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text(
                          'İndirimler Hakkında',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.discount, color: Colors.purple, size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Çarkıfelek\'ten kazandığınız tüm indirimler burada listelenir.',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_circle, color: Colors.green, size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Aktif indirimlerinizi sepet sayfasında kullanabilirsiniz.',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.copy, color: Colors.blue, size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'İndirim kodunu kopyalayıp sipariş sırasında kullanabilirsiniz.',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.purple,
                          ),
                          child: const Text('Kapat'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [

            _buildFiltreButonlari(),

            Expanded(
              child: filtrelenmisIndirimler.isEmpty
                  ? _buildBosDurum()
                  : ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: filtrelenmisIndirimler.length,
                itemBuilder: (context, index) {
                  return _buildIndirimKarti(filtrelenmisIndirimler[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
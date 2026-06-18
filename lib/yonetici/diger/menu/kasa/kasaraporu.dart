import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Backend/yetki.dart';

class KasaRaporu extends StatefulWidget {
  final dynamic isletmebilgi;
  const KasaRaporu({Key? key, required this.isletmebilgi}) : super(key: key);

  @override
  _KasaRaporuState createState() => _KasaRaporuState();
}

class _KasaRaporuState extends State<KasaRaporu> with SingleTickerProviderStateMixin {
  final NumberFormat tryformat = NumberFormat.currency(locale: 'tr_TR', symbol: "₺");
  final DateFormat dateFormat = DateFormat('dd.MM.yyyy');

  late TabController _tabController;
  late String? seciliisletme;
  String selectedPeriod = 'Bu ay';
  String selectedPaymentMethod = 'Tümü';
  String selectedHarcayan = '';

  late double gelir;
  late double gider;
  double toplam = 0;
  double ciro = 0;
  bool _isloading = true;

  List<Map<String, dynamic>> gelirListesi = [];
  List<Map<String, dynamic>> giderListesi = [];

  int _gelirCurrentPage = 1;
  int _gelirTotalPages = 1;
  int _giderCurrentPage = 1;
  int _giderTotalPages = 1;

  bool _gelirLoading = false;
  bool _giderLoading = false;

  final List<String> periodOptions = ['Bugün', 'Dün', 'Bu ay', 'Geçen ay', 'Bu yıl', 'Tümü'];
  final List<String> paymentOptions = ['Tümü', 'Nakit', 'Kredi Kartı', 'Havale/EFT'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    initialize();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> initialize() async {
    seciliisletme = await secilisalonid();
    await fetchAllData();
  }

  Future<void> fetchAllData() async {
    setState(() => _isloading = true);

    await fetchSummary();
    await Future.wait([
      fetchGelirler(resetPage: true),
      fetchGiderler(resetPage: true),
    ]);

    setState(() => _isloading = false);
  }

  Future<void> fetchSummary() async {
    try {
      var data = await kasaraporu(seciliisletme!, selectedPeriod, selectedPaymentMethod);
      setState(() {
        gelir = double.parse(data['toplamgelir'].toString());
        gider = double.parse(data['toplamgider'].toString());
        toplam = gelir - gider;
        ciro = double.parse(data['toplamCiro'].toString());
      });
    } catch (e) {
      print('Özet veri hatası: $e');
      setState(() {
        gelir = 0;
        gider = 0;
        toplam = 0;
      });
    }
  }

  Future<void> fetchGelirler({bool resetPage = false}) async {
    if (resetPage) {
      setState(() {
        _gelirCurrentPage = 1;
        _gelirLoading = true;
      });
    } else {
      setState(() => _gelirLoading = true);
    }

    try {
      var response = await tahsilatraporu(
          seciliisletme!,
          _gelirCurrentPage.toString(),
          selectedPeriod,
          selectedPaymentMethod
      );

      setState(() {
        if (response.containsKey('data')) {
          log('gelir listesi '+response['data'].toString());
          gelirListesi = List<Map<String, dynamic>>.from(response['data']);
        } else {
          gelirListesi = [];
        }

        _gelirTotalPages = response['last_page'] ?? 1;
        _gelirLoading = false;
      });
    } catch (e) {
      print('Gelirler hatası: $e');
      setState(() {
        gelirListesi = [];
        _gelirLoading = false;
      });
    }
  }

  Future<void> fetchGiderler({bool resetPage = false}) async {
    if (resetPage) {
      setState(() {
        _giderCurrentPage = 1;
        _giderLoading = true;
      });
    } else {
      setState(() => _giderLoading = true);
    }

    try {
      var response = await masrafraporu(
          seciliisletme!,
          _giderCurrentPage.toString(),
          selectedPeriod,
          selectedPaymentMethod,
          selectedHarcayan
      );

      setState(() {
        if (response.containsKey('data')) {
          giderListesi = List<Map<String, dynamic>>.from(response['data']);
        } else {
          giderListesi = [];
        }

        _giderTotalPages = response['last_page'] ?? 1;
        _giderLoading = false;
      });
    } catch (e) {
      print('Giderler hatası: $e');
      setState(() {
        giderListesi = [];
        _giderLoading = false;
      });
    }
  }

  void _showDevredenAylarModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.transparent,
      builder: (context) => _DevredenAylarSheet(
        salonId: seciliisletme!,
        formatCurrency: tryformat,
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: _FilterDialog(
          periodOptions: periodOptions,
          paymentOptions: paymentOptions,
          selectedPeriod: selectedPeriod,
          selectedPayment: selectedPaymentMethod,
          onApply: (period, payment) {
            setState(() {
              selectedPeriod = period;
              selectedPaymentMethod = payment;
              selectedHarcayan = '';
            });
            fetchAllData();
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Color.alphaBlend(scheme.primary.withValues(alpha: 0.32), Colors.white),
            Color.alphaBlend(scheme.tertiary.withValues(alpha: 0.06), Colors.white),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _buildAppBar(),
        body: _isloading
            ? _buildLoadingState()
            : RefreshIndicator(
          onRefresh: fetchAllData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 16),
                _buildStatsCards(),
                const SizedBox(height: 24),
                _buildChart(),
                const SizedBox(height: 24),
                _buildTransactionTabs(),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionTabs() {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TabBar(
            controller: _tabController,
            indicatorColor: scheme.primary,
            indicatorWeight: 3,
            labelColor: scheme.primary,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: 'Gelirler', icon: Icon(Icons.arrow_upward)),
              Tab(text: 'Giderler', icon: Icon(Icons.arrow_downward)),
            ],
          ),
          SizedBox(
            height: 410, // Sabit yükseklik
            child: TabBarView(
              controller: _tabController,
              children: [
                  _TransactionList(
                    transactions: gelirListesi,
                    type: 'gelir',
                    isLoading: _gelirLoading,
                    formatCurrency: tryformat,
                    formatDate: dateFormat,
                    currentPage: _gelirCurrentPage,
                    totalPages: _gelirTotalPages,
                    onPageChanged: (page) {
                      setState(() {
                        _gelirCurrentPage = page;
                      });
                      fetchGelirler();
                    },
                  ),

                   _TransactionList(
                    transactions: giderListesi,
                    type: 'gider',
                    isLoading: _giderLoading,
                    formatCurrency: tryformat,
                    formatDate: dateFormat,
                    currentPage: _giderCurrentPage,
                    totalPages: _giderTotalPages,
                    onPageChanged: (page) {
                      setState(() {
                        _giderCurrentPage = page;
                      });
                      fetchGiderler();
                    },
                    onSearch: (text) {
                      setState(() {
                        selectedHarcayan = text;
                      });
                      fetchGiderler(resetPage: true);
                    },

                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final scheme = Theme.of(context).colorScheme;
    return AppBar(
      title: Text(
        'Kasa Raporu',
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 22,
          color: scheme.onSurface,
          letterSpacing: -0.3,
        ),
      ),
      centerTitle: false,
      elevation: 0,
      backgroundColor: Colors.transparent,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios, color: scheme.onSurface),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          child: Row(
            children: [
              _buildFilterChip(),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _showFilterDialog,
                icon: Icon(Icons.tune, color: scheme.primary),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: scheme.primary.withValues(alpha: 0.06),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _showDevredenAylarModal,
                icon: Icon(Icons.calendar_month, color: scheme.secondary),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: scheme.primary.withValues(alpha: 0.06),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip() {
    String filterText = selectedPeriod;
    if (selectedPaymentMethod != 'Tümü') {
      filterText += ' • ${selectedPaymentMethod}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_alt, size: 16, color: Colors.purple),
          const SizedBox(width: 4),
          Text(
            filterText,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
        ],
      ),
    );
  }
  //üst kartlar bölümü
  Widget _buildStatsCards() {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final crossAxisCount = isLandscape ? 4 : 2;

    // Yatay ve dikey için farklı aspect ratio
    final aspectRatio = isLandscape ? 2.3 : 1.9;

    return GridView.custom(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 8,
        crossAxisSpacing: 12,
        mainAxisExtent: 100, // SABİT YÜKSEKLİK! 100px
      ),
        childrenDelegate: SliverChildListDelegate([

        _StatCard(
          title: 'Toplam Gelir',
          amount: gelir,
          icon: Icons.trending_up,
          color: Colors.green,
          gradient: [Colors.green.shade50, Colors.white],
          onTap: () => _tabController.animateTo(0),
        ),
        _StatCard(
          title: 'Toplam Gider',
          amount: gider,
          icon: Icons.trending_down,
          color: Colors.red,
          gradient: [Colors.red.shade50, Colors.white],
          onTap: () => _tabController.animateTo(1),
        ),
        _StatCard(
          title: 'Aylık Kasa',
          amount: toplam,
          icon: Icons.account_balance_wallet,
          color: Colors.blue,
          gradient: [Colors.blue.shade50, Colors.white],
          subtitle: 'Dönem İçi Aylık Kasa',
        ),
        _StatCard(
          title: 'Toplam Kazanç',
          amount: ciro,
          icon: Icons.emoji_events,
          color: Colors.orange,
          gradient: [Colors.orange.shade50, Colors.white],
          subtitle: 'Toplam Kazanç',
        ),
      ]),
    );
  }

  Widget _buildChart() {
    final total = gelir + gider;
    final double gelirYuzde = total > 0 ? (gelir / total) * 100 : 0;
    final double giderYuzde = total > 0 ? (gider / total) * 100 : 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Gelir/Gider Dağılımı',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    selectedPeriod,
                    style: const TextStyle(fontSize: 12, color: Colors.purple),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: gelir,
                      title: '${gelirYuzde.toStringAsFixed(0)}%',
                      color: Colors.green,
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      titlePositionPercentageOffset: 0.6, // Yazıyı dilim dışına çıkar
                    ),
                    PieChartSectionData(
                      value: gider,
                      title: '${giderYuzde.toStringAsFixed(0)}%',
                      color: Colors.red,
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      titlePositionPercentageOffset: 0.6,
                    ),
                  ],
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  startDegreeOffset: 0,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Gelir', gelir, gelirYuzde, Colors.green),
                const SizedBox(width: 24),
                _buildLegendItem('Gider', gider, giderYuzde, Colors.red),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Net Bakiye',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    Yetki.tutarGoster(
                      '${toplam >= 0 ? '+' : '-'} ${NumberFormat('#,##0.00', 'tr_TR').format(toplam.abs())} ₺',
                      'rapor.ciro_kar_gor',
                    ),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: toplam >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String title, double amount, double yuzde, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
            Text(
              '${NumberFormat('#,##0.00', 'tr_TR').format(amount)} ₺',
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }


  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.purple),
          SizedBox(height: 16),
          Text('Rapor yükleniyor...', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}


// Transaction List Widget - Scroll'suz, sabit yükseklikli
class _TransactionList extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;
  final String type;
  final bool isLoading;
  final NumberFormat formatCurrency;
  final DateFormat formatDate;
  final int currentPage;
  final int totalPages;
  final Function(int) onPageChanged;
  final Function(String)? onSearch;

  const _TransactionList({
    required this.transactions,
    required this.type,
    required this.isLoading,
    required this.formatCurrency,
    required this.formatDate,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    this.onSearch,
  });

  String _formatDate(dynamic dateValue) {
    if (dateValue == null) return '';
    try {
      if (dateValue is String && dateValue.contains('-') && dateValue.length == 10) {
        DateTime parsedDate = DateTime.parse(dateValue);
        return formatDate.format(parsedDate);
      }
      return dateValue.toString();
    } catch (e) {
      return dateValue.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(color: Colors.purple),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [

        if (transactions.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'Henüz kayıt yok',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          )
        else
          ...transactions.map((item) {
            String hizmetUrunPaket = '';
            /*if(type=='gelir')
              {
                for (var paketOdeme in item['paket_odemeleri'])
                {
                  hizmetUrunPaket = '-'+paketOdeme['adisyon_paket']['paket']['paket_adi']+'\n';
                }
              }*/


            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              child: ListTile(
                onTap: () => _showDetayPopup(context, item),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0), // Dikey padding 0
                visualDensity: const VisualDensity(horizontal: 0, vertical: -3), // Dikey sıkıştırma
                leading: CircleAvatar(
                  backgroundColor: type == 'gelir' ? Colors.green.shade50 : Colors.red.shade50,
                  child: Icon(
                    type == 'gelir' ? Icons.currency_lira_outlined : Icons.remove,
                    color: type == 'gelir' ? Colors.green : Colors.red,
                  ),
                ),
                title: Text(
                  type == 'gelir'
                      ? ((item['musteri']?['name']  ?? 'Kasaya para ekleme')+"\n"+(item['aciklama']??hizmetUrunPaket))
                      : (item['harcayan']?['personel_adi'] ?? item['aciklama'] ?? 'İşlem'),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDate(item['odeme_tarihi'] ?? item['tarih']),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    if (type == 'gider' && item['aciklama'] != null && item['aciklama'].toString().isNotEmpty)
                      Text(
                        item['aciklama'],
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${type == 'gelir' ? '+' : '-'} ${NumberFormat('#,##0.00', 'tr_TR').format(item['tutar'] ?? item['miktar'])} ₺',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: type == 'gelir' ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getOdemeYontemi(item),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        if (totalPages > 1)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Sayfa $currentPage / $totalPages',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: currentPage < totalPages ? () => onPageChanged(currentPage + 1) : null,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }
  String _getOdemeYontemi(Map<String, dynamic> item) {
    // Ödeme yöntemi ID'sini al
    int? odemeYontemiId = item['odeme_yontemi_id'];

    // ID'ye göre ödeme türünü belirle
    switch (odemeYontemiId) {
      case 1:
        return 'Nakit';
      case 2:
        return 'Kredi Kartı';
      case 3:
        return 'Havale/EFT';
      case 4:
        return 'Diğer';

      default:
      // Eğer direkt ödeme yöntemi adı gelmişse
        if (item['odeme_yontemi'] != null) {
          return item['odeme_yontemi'];
        }
        return '';
    }
  }

  String? _safeString(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  String? _kategoriAdi(Map<String, dynamic> item) {
    final candidates = [
      item['masraf_kategori'],
      item['masraf_kategorisi'],
      item['kategori'],
    ];
    for (final c in candidates) {
      if (c is Map) {
        final ad = _safeString(c['kategori']) ?? _safeString(c['kategori_adi']);
        if (ad != null) return ad;
      } else {
        final s = _safeString(c);
        if (s != null) return s;
      }
    }
    return null;
  }

  double? _toDoubleOrNull(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    return double.tryParse(s);
  }

  /// Tahsilatın hangi hizmet/paket/ürünleri kapsadığını çıkarır.
  /// Her satır: {tip, ad, tutar, adet}
  List<Map<String, dynamic>> _satilanKalemler(Map<String, dynamic> item) {
    final List<Map<String, dynamic>> kalemler = [];

    // Hizmet ödemeleri
    final hizmetOdemeleri = item['hizmet_odemeleri'];
    if (hizmetOdemeleri is List) {
      for (final h in hizmetOdemeleri) {
        if (h is! Map) continue;
        final adisyonHizmet = h['adisyon_hizmet'];
        String? ad;
        if (adisyonHizmet is Map) {
          final hizmet = adisyonHizmet['hizmet'];
          if (hizmet is Map) ad = _safeString(hizmet['hizmet_adi']);
        }
        kalemler.add({
          'tip': 'Hizmet',
          'ad': ad ?? 'Hizmet',
          'tutar': _toDoubleOrNull(h['tutar']),
        });
      }
    }

    // Paket ödemeleri
    final paketOdemeleri = item['paket_odemeleri'];
    if (paketOdemeleri is List) {
      for (final p in paketOdemeleri) {
        if (p is! Map) continue;
        final adisyonPaket = p['adisyon_paket'];
        String? ad;
        if (adisyonPaket is Map) {
          final paket = adisyonPaket['paket'];
          if (paket is Map) ad = _safeString(paket['paket_adi']);
        }
        kalemler.add({
          'tip': 'Paket',
          'ad': ad ?? 'Paket',
          'tutar': _toDoubleOrNull(p['tutar']),
        });
      }
    }

    // Adisyon üzerinden ürün ödemeleri
    final urunOdemeleri = item['urun_odemeleri'];
    if (urunOdemeleri is List) {
      for (final u in urunOdemeleri) {
        if (u is! Map) continue;
        final adisyonUrun = u['adisyon_urun'];
        String? ad;
        int? adet;
        if (adisyonUrun is Map) {
          final urun = adisyonUrun['urun'];
          if (urun is Map) ad = _safeString(urun['urun_adi']);
          final a = _toDoubleOrNull(adisyonUrun['adet']);
          if (a != null) adet = a.toInt();
        }
        kalemler.add({
          'tip': 'Ürün',
          'ad': ad ?? 'Ürün',
          'tutar': _toDoubleOrNull(u['tutar']),
          'adet': adet,
        });
      }
    }

    // Direkt ürün satışı (adisyon dışı)
    final urunSatisi = item['urun_satisi'];
    if (urunSatisi is Map) {
      final urun = urunSatisi['urunler'];
      String? ad;
      if (urun is Map) ad = _safeString(urun['urun_adi']);
      final adet = _toDoubleOrNull(urunSatisi['adet'])?.toInt();
      kalemler.add({
        'tip': 'Ürün',
        'ad': ad ?? 'Ürün',
        'tutar': _toDoubleOrNull(urunSatisi['tutar'] ?? urunSatisi['fiyat']),
        'adet': adet,
      });
    }

    return kalemler;
  }

  IconData _kalemIkonu(String tip) {
    switch (tip) {
      case 'Paket':
        return Icons.card_giftcard_rounded;
      case 'Ürün':
        return Icons.shopping_bag_outlined;
      case 'Hizmet':
      default:
        return Icons.content_cut_rounded;
    }
  }

  Widget _satilanlarBlogu(List<Map<String, dynamic>> kalemler, Color accent) {
    final fmt = NumberFormat('#,##0.00', 'tr_TR');
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.receipt_long_rounded, size: 15, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Satılan',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.black.withValues(alpha: 0.45),
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 6),
                ...kalemler.map((k) {
                  final tip = (k['tip'] as String?) ?? 'Hizmet';
                  final ad = (k['ad'] as String?) ?? '-';
                  final tutar = k['tutar'] as double?;
                  final adet = k['adet'] as int?;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(_kalemIkonu(tip), size: 13, color: accent),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                adet != null && adet > 1
                                    ? '$ad  ×$adet'
                                    : ad,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                  height: 1.3,
                                ),
                              ),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: accent.withValues(alpha: 0.10),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      tip,
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        color: accent,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ),
                                  if (tutar != null) ...[
                                    const SizedBox(width: 6),
                                    Text(
                                      '${fmt.format(tutar)} ₺',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black
                                            .withValues(alpha: 0.55),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Geliri tahsil eden personel (olusturan oncelikli, yoksa satici). Backend
  /// bu iliskileri eager-load eder; yoksa null doner ve satir gizlenir.
  String? _tahsilEden(Map<String, dynamic> item) {
    final o = item['olusturan'];
    if (o is Map) {
      final ad = _safeString(o['personel_adi']);
      if (ad != null) return ad;
    }
    final s = item['satici'];
    if (s is Map) {
      final ad = _safeString(s['personel_adi']);
      if (ad != null) return ad;
    }
    return null;
  }

  void _showDetayPopup(BuildContext context, Map<String, dynamic> item) {
    final isGelir = type == 'gelir';
    final tutar = item['tutar'] ?? item['miktar'];
    final tarih = _formatDate(item['odeme_tarihi'] ?? item['tarih']);
    final odemeYontemi = _getOdemeYontemi(item);
    final aciklama = _safeString(item['aciklama']);
    final notlar = _safeString(item['notlar']);
    final musteriAdi = (item['musteri'] is Map)
        ? _safeString(item['musteri']['name'])
        : null;
    final harcayanAdi = (item['harcayan'] is Map)
        ? _safeString(item['harcayan']['personel_adi'])
        : null;
    final kategori = _kategoriAdi(item);
    final kayitNo = _safeString(item['id']);
    final kalemler = isGelir ? _satilanKalemler(item) : <Map<String, dynamic>>[];

    final Color accent = isGelir ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final IconData accentIcon =
        isGelir ? Icons.trending_up_rounded : Icons.trending_down_rounded;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.42),
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.22),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _detayHeader(scheme, accent, accentIcon, isGelir, tutar, ctx),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _detaySatir(
                          icon: Icons.calendar_today_rounded,
                          label: 'Tarih',
                          value: tarih.isEmpty ? '-' : tarih,
                          accent: accent,
                        ),
                        _detaySatir(
                          icon: Icons.account_balance_wallet_rounded,
                          label: 'Ödeme Yöntemi',
                          value: odemeYontemi.isEmpty ? '-' : odemeYontemi,
                          accent: accent,
                        ),
                        if (isGelir)
                          _detaySatir(
                            icon: Icons.person_outline_rounded,
                            label: 'Müşteri',
                            value: musteriAdi ?? 'Kasaya para ekleme',
                            accent: accent,
                          ),
                        if (isGelir && _tahsilEden(item) != null)
                          _detaySatir(
                            icon: Icons.badge_outlined,
                            label: 'Tahsil Eden',
                            value: _tahsilEden(item)!,
                            accent: accent,
                          ),
                        if (isGelir && kalemler.isNotEmpty)
                          _satilanlarBlogu(kalemler, accent),
                        if (!isGelir && harcayanAdi != null)
                          _detaySatir(
                            icon: Icons.person_outline_rounded,
                            label: 'Harcayan',
                            value: harcayanAdi,
                            accent: accent,
                          ),
                        if (!isGelir && kategori != null)
                          _detaySatir(
                            icon: Icons.category_outlined,
                            label: 'Kategori',
                            value: kategori,
                            accent: accent,
                          ),
                        if (aciklama != null)
                          _detaySatir(
                            icon: Icons.notes_rounded,
                            label: 'Açıklama',
                            value: aciklama,
                            accent: accent,
                          ),
                        if (!isGelir && notlar != null)
                          _detaySatir(
                            icon: Icons.sticky_note_2_outlined,
                            label: 'Notlar',
                            value: notlar,
                            accent: accent,
                          ),
                        if (kayitNo != null)
                          _detaySatir(
                            icon: Icons.tag_rounded,
                            label: 'Kayıt No',
                            value: '#$kayitNo',
                            accent: accent,
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 6, 18, 16),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      onTap: () => Navigator.of(ctx).pop(),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [accent, accent.withValues(alpha: 0.82)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.30),
                              blurRadius: 14,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'Kapat',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detayHeader(ColorScheme scheme, Color accent, IconData accentIcon,
      bool isGelir, dynamic tutar, BuildContext ctx) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 14, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.16),
            accent.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(accentIcon, color: accent, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isGelir ? 'Gelir Detayı' : 'Gider Detayı',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: accent,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${isGelir ? '+' : '-'} ${NumberFormat('#,##0.00', 'tr_TR').format(tutar ?? 0)} ₺',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.white,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: () => Navigator.of(ctx).pop(),
              customBorder: const CircleBorder(),
              child: Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                child: Icon(
                  Icons.close_rounded,
                  color: scheme.onSurface.withValues(alpha: 0.55),
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detaySatir({
    required IconData icon,
    required String label,
    required String value,
    required Color accent,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 15, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.black.withValues(alpha: 0.45),
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    height: 1.3,
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




// Stat Card Widget - Responsive
class _StatCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color color;
  final List<Color> gradient;
  final VoidCallback? onTap;
  final String? subtitle;

  const _StatCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
    required this.gradient,
    this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final format = NumberFormat('#,##0.00', 'tr_TR');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // SADECE BURAYI DEĞİŞTİRDİM
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${format.format(amount)} ₺',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[500],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Filter Dialog ve DevredenAylarSheet aynı kalabilir
// ... (Filter Dialog ve DevredenAylarSheet kodları aynı)
// Filter Dialog
class _FilterDialog extends StatefulWidget {
  final List<String> periodOptions;
  final List<String> paymentOptions;
  final String selectedPeriod;
  final String selectedPayment;
  final Function(String, String) onApply;

  const _FilterDialog({
    required this.periodOptions,
    required this.paymentOptions,
    required this.selectedPeriod,
    required this.selectedPayment,
    required this.onApply,
  });

  @override
  State<_FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<_FilterDialog> {
  late String period;
  late String payment;

  @override
  void initState() {
    super.initState();
    period = widget.selectedPeriod;
    payment = widget.selectedPayment;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filtreleme Seçenekleri',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Zaman Aralığı',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: widget.periodOptions.map((option) {
              return FilterChip(
                label: Text(option),
                selected: period == option,
                onSelected: (selected) {
                  setState(() => period = option);
                },
                selectedColor: Colors.purple.shade100,
                checkmarkColor: Colors.purple,
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          const Text(
            'Ödeme Yöntemi',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: widget.paymentOptions.map((option) {
              return FilterChip(
                label: Text(option),
                selected: payment == option,
                onSelected: (selected) {
                  setState(() => payment = option);
                },
                selectedColor: Colors.purple.shade100,
                checkmarkColor: Colors.purple,
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('İptal'),
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => widget.onApply(period, payment),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Filtrele'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Devreden Aylar Bölümü

class _DevredenAylarSheet extends StatefulWidget {
  final String salonId;
  final NumberFormat formatCurrency;

  const _DevredenAylarSheet({
    required this.salonId,
    required this.formatCurrency,
  });

  @override
  State<_DevredenAylarSheet> createState() => _DevredenAylarSheetState();
}

class _DevredenAylarSheetState extends State<_DevredenAylarSheet> {
  int selectedYear = DateTime.now().year;
  List<Map<String, dynamic>> aylar = [];
  bool isLoading = false;
  String? errorMessage;

  final List<int> availableYears = List.generate(
    DateTime.now().year - 2014,
        (i) => DateTime.now().year - i,
  );

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      var response = await devredenAylar(widget.salonId, selectedYear);
      if (response['success'] == true) {
        setState(() {
          aylar = List<Map<String, dynamic>>.from(response['data']);
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = response['message'] ?? 'Veri yüklenirken hata oluştu';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Bağlantı hatası: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Devreden Aylar',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Yıl seçici
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: selectedYear,
                  isExpanded: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  items: availableYears.map((year) {
                    return DropdownMenuItem(
                      value: year,
                      child: Text('$year Yılı'),
                    );
                  }).toList(),
                  onChanged: (year) {
                    if (year != null) {
                      setState(() {
                        selectedYear = year;
                      });
                      _fetchData();
                    }
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Liste
          Expanded(
            child: isLoading
                ? const Center(
              child: CircularProgressIndicator(color: Colors.purple),
            )
                : errorMessage != null
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    errorMessage!,
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _fetchData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                    ),
                    child: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            )
                : aylar.isEmpty
                ? const Center(
              child: Text('Kayıt bulunamadı'),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: aylar.length,
              itemBuilder: (context, index) {
                var ay = aylar[index];
                double netKar = _toDouble(ay['donem_net_kar']);
                double tahsilatlar = _toDouble(ay['tahsilatlar']);
                double masraflar = _toDouble(ay['masraflar']);

                bool isKar = netKar > 0;
                bool isZarar = netKar < 0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // Sol ikon
                        Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            color: isKar
                                ? Colors.green.shade50
                                : isZarar
                                ? Colors.red.shade50
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isKar
                                ? Icons.trending_up
                                : isZarar
                                ? Icons.trending_down
                                : Icons.remove,
                            color: isKar
                                ? Colors.green
                                : isZarar
                                ? Colors.red
                                : Colors.grey,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Orta kısım - Ay ve gelir/gider
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${ay['ay_adi']} ${ay['yil']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              // Gelir ve Gider satırı
                              Wrap(
                                spacing: 12,
                                runSpacing: 4,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'Gelir:',
                                        style: TextStyle(fontSize: 11, color: Colors.grey),
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          widget.formatCurrency.format(tahsilatlar),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.green[700],
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'Gider:',
                                        style: TextStyle(fontSize: 11, color: Colors.grey),
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          widget.formatCurrency.format(masraflar),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.red[700],
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Sağ kısım - Net kar
                        Container(
                          constraints: BoxConstraints(
                            minWidth: isSmallScreen ? 70 : 90,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${isKar ? '+' : isZarar ? '-' : ''} ${widget.formatCurrency.format(netKar.abs())}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: isSmallScreen ? 13 : 14,
                                  color: isKar
                                      ? Colors.green
                                      : isZarar
                                      ? Colors.red
                                      : Colors.grey,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isKar
                                      ? Colors.green.shade100
                                      : isZarar
                                      ? Colors.red.shade100
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  isKar
                                      ? 'KAR'
                                      : isZarar
                                      ? 'ZARAR'
                                      : 'DENGELİ',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 8 : 9,
                                    fontWeight: FontWeight.bold,
                                    color: isKar
                                        ? Colors.green[800]
                                        : isZarar
                                        ? Colors.red[800]
                                        : Colors.grey[800],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
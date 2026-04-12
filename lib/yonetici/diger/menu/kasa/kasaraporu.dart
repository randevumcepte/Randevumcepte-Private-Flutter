import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../Backend/backend.dart';

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
  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
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
    );
  }

  Widget _buildTransactionTabs() {
    return Container(
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
        mainAxisSize: MainAxisSize.min,
        children: [
          TabBar(
            controller: _tabController,
            indicatorColor: Colors.purple,
            labelColor: Colors.purple,
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
    return AppBar(
      title: const Text(
        'Kasa Raporu',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 24,
          color: Colors.black87,
        ),
      ),
      centerTitle: false,
      elevation: 0,
      backgroundColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
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
                icon: const Icon(Icons.tune, color: Colors.purple),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  elevation: 2,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _showDevredenAylarModal,
                icon: const Icon(Icons.calendar_month, color: Colors.orange),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  elevation: 2,
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
          title: 'Toplam Kasa',
          amount: toplam,
          icon: Icons.account_balance_wallet,
          color: Colors.blue,
          gradient: [Colors.blue.shade50, Colors.white],
          subtitle: 'Dönem İçi Toplam Kasa',
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
                    '${toplam >= 0 ? '+' : '-'} ${NumberFormat('#,##0.00', 'tr_TR').format(toplam.abs())} ₺',
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
                      ? ((item['musteri']['name']  ?? 'Kasaya para ekleme')+"\n"+(item['aciklama']??hizmetUrunPaket))
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
  import 'dart:convert';
  import 'dart:developer';

  import 'package:dropdown_button2/dropdown_button2.dart';
  import 'package:flutter/material.dart';
  import 'package:intl/intl.dart';
  import 'package:provider/provider.dart';
  import '../dashboard/paketsatisi.dart';
  import '../dashboard/hizmetsatisi.dart';
  import '../dashboard/urunsatisi.dart';

  import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
  import 'package:randevu_sistem/yonetici/adisyonlar/satislar/tahsilat.dart';
  import 'package:randevu_sistem/Backend/backend.dart';
  import 'package:randevu_sistem/Frontend/lazyload.dart';
  import 'package:randevu_sistem/Models/adisyonlar.dart';
  import 'package:randevu_sistem/Models/musteri_danisanlar.dart';
  import 'package:randevu_sistem/Models/satislar.dart';
  import 'package:randevu_sistem/Models/satisturleri.dart';
  import 'package:randevu_sistem/Models/user.dart';

  class AdisyonlarPage extends StatefulWidget {
    final Kullanici kullanici;
    final int kullanicirolu;
    final dynamic isletmebilgi;
    final bool geriGitBtn;

    AdisyonlarPage({
      Key? key,
      required this.kullanici,
      required this.isletmebilgi,
      required this.kullanicirolu,
      required this.geriGitBtn,
    }) : super(key: key);

    @override
    _AdisyonlarPageState createState() => _AdisyonlarPageState();
  }

  class _AdisyonlarPageState extends State<AdisyonlarPage> with SingleTickerProviderStateMixin {
    bool _isLoading = true;
    late TabController _tabController;

    final List<SatisTuru> adisyonicerigi = [
      SatisTuru(id: "", satisturu: "Tümü"),
      SatisTuru(id: "1", satisturu: "Hizmet Satışları"),
      SatisTuru(id: "2", satisturu: "Paket Satışları"),
      SatisTuru(id: "3", satisturu: "Ürün Satışları"),
    ];

    late String? seciliisletme;
    SatisTuru? selectedadisyonicerigi;
    TextEditingController adisyonicerigicontroller = TextEditingController();
    String? selectedadisyondurum;
    MusteriDanisan? selectedMusteri;
    TextEditingController adisyondurumcontroller = TextEditingController();
    TextEditingController musteridanisanadi = TextEditingController();

    DateTimeRange? _selectedDateRange;

    List<Adisyon> _acikAdisyonlar = [];
    List<Adisyon> _kapaliAdisyonlar = [];
    int _currentPage = 1;
    int _currentPageAcik = 1;

    int _totalPages = 1;
    int _totalPagesAcik = 1;

    bool _isLoadingMore = false;
    bool _isLoadingAcikMore = false;

    Map<String, bool> _expandedItems = {};
    Map<String, bool> _expandedAcikItems = {};

    String? acikSayi;
    String? kapaliSayi;

    String? _currentlyExpandedId; // Sadece bir adisyonun açık olması için


    bool _kapaliFetched = false;

    @override
    void initState() {
      super.initState();
      _tabController = TabController(length: 2, vsync: this);
      _tabController.addListener(_onTabChanged);
      initialize();
    }

    @override
    void dispose() {
      _tabController.removeListener(_onTabChanged);
      _tabController.dispose();
      super.dispose();
    }

    void _onTabChanged() {
      if (_tabController.indexIsChanging) return;
      if (_tabController.index == 1 && !_kapaliFetched && seciliisletme != null) {
        _kapaliFetched = true;
        fetchAdisyonlar();
      }
    }

    Future<void> initialize() async {
      seciliisletme = await secilisalonid();

      await fetchAcikAdisyonlar();

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }

    Future<void> fetchAdisyonlar({bool resetPage = true}) async {
      if (!mounted) return;

      if (resetPage) {
        _currentPage = 1;
        _expandedItems.clear();
        _currentlyExpandedId = null;
        _kapaliAdisyonlar = [];
      }

      setState(() {
        _isLoadingMore = true;
      });

      try {
        final jsonResponse = await satislar(
            seciliisletme!,
            _currentPage.toString(),
            _selectedDateRange != null
                ? DateFormat("yyyy-MM-dd").format(_selectedDateRange!.start.toLocal())
                : "1970-01-01",
            _selectedDateRange != null
                ? DateFormat("yyyy-MM-dd").format(_selectedDateRange!.end.toLocal())
                : DateFormat("yyyy-MM-dd").format(DateTime.now()),
            selectedMusteri?.id ?? "",
            selectedadisyonicerigi?.id ?? "",
            "",
            false,
            widget.kullanicirolu == 5 ? widget.kullanici.id : '',
            0
        );

        if (!mounted) return;

        List<dynamic> data = jsonResponse['data'];
        List<Adisyon> newAdisyonlar = data.map<Adisyon>((json) => Adisyon.fromJson(json)).toList();

        setState(() {
          if (resetPage) {
            _kapaliAdisyonlar = newAdisyonlar;
          } else {
            // Yeni gelenleri ekle, aynı ID varsa güncelle
            for (var newAdisyon in newAdisyonlar) {
              int index = _kapaliAdisyonlar.indexWhere((a) => a.id == newAdisyon.id);
              if (index != -1) {
                _kapaliAdisyonlar[index] = newAdisyon;
              } else {
                _kapaliAdisyonlar.add(newAdisyon);
              }
            }
          }
          // Backend her iki sayi da dondurur; tab degismesine gerek kalmadan ikisi de guncellenir
          if (jsonResponse['acik_sayisi'] != null) {
            acikSayi = jsonResponse['acik_sayisi'].toString();
          }
          if (jsonResponse['kapali_sayisi'] != null) {
            kapaliSayi = jsonResponse['kapali_sayisi'].toString();
          } else {
            kapaliSayi = jsonResponse['satisSayisi']?.toString() ?? '0';
          }
          _totalPages = jsonResponse['last_page'] ?? 1;
          _isLoadingMore = false;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isLoadingMore = false;
        });
      }
    }

    Future<void> fetchAcikAdisyonlar({bool resetPage = true}) async {
      if (!mounted) return;

      if (resetPage) {
        _currentPageAcik = 1;
        _expandedAcikItems.clear();
        _currentlyExpandedId = null;
        _acikAdisyonlar = [];
      }

      setState(() {
        _isLoadingAcikMore = true;
      });

      try {
        final jsonResponse = await satislar(
            seciliisletme!,
            _currentPageAcik.toString(),
            _selectedDateRange != null
                ? DateFormat("yyyy-MM-dd").format(_selectedDateRange!.start.toLocal())
                : "1970-01-01",
            _selectedDateRange != null
                ? DateFormat("yyyy-MM-dd").format(_selectedDateRange!.end.toLocal())
                : DateFormat("yyyy-MM-dd").format(DateTime.now()),
            selectedMusteri?.id ?? "",
            selectedadisyonicerigi?.id ?? "",
            "",
            false,
            widget.kullanicirolu == 5 ? widget.kullanici.id : '',
            1
        );

        if (!mounted) return;

        List<dynamic> data = jsonResponse['data'];
        List<Adisyon> newAdisyonlar = data.map<Adisyon>((json) => Adisyon.fromJson(json)).toList();

        setState(() {
          if (resetPage) {
            _acikAdisyonlar = newAdisyonlar;
          } else {
            // Yeni gelenleri ekle, aynı ID varsa güncelle
            for (var newAdisyon in newAdisyonlar) {
              int index = _acikAdisyonlar.indexWhere((a) => a.id == newAdisyon.id);
              if (index != -1) {
                _acikAdisyonlar[index] = newAdisyon;
              } else {
                _acikAdisyonlar.add(newAdisyon);
              }
            }
          }
          _totalPagesAcik = jsonResponse['last_page'] ?? 1;
          // Backend her iki sayi da dondurur; tab degismesine gerek kalmadan ikisi de guncellenir
          if (jsonResponse['acik_sayisi'] != null) {
            acikSayi = jsonResponse['acik_sayisi'].toString();
          } else {
            acikSayi = jsonResponse['satisSayisi']?.toString() ?? '0';
          }
          if (jsonResponse['kapali_sayisi'] != null) {
            kapaliSayi = jsonResponse['kapali_sayisi'].toString();
          }
          _isLoadingAcikMore = false;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isLoadingAcikMore = false;
        });
      }
    }
    void _loadMoreData() {
      if (_currentPage < _totalPages && !_isLoadingMore) {
        _currentPage++;
        fetchAdisyonlar(resetPage: false);
      }
    }
    void _loadMoreAcikData() {
      if (_currentPageAcik < _totalPagesAcik && !_isLoadingAcikMore) {
        _currentPageAcik++;
        fetchAcikAdisyonlar(resetPage: false);
      }
    }
  // _AdisyonlarPageState sınıfına ekleyeceğimiz yeni fonksiyonlar
    void hizmetsatisiEkle(BuildContext context, Adisyon adisyon) async {
      if (adisyon.kalan_tutar == "0" || adisyon.kalan_tutar == "0,00") {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kapalı adisyona yeni hizmet eklenemez'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HizmetSatisi(
            musteriid: adisyon.user_id,
            senetlisatis: false,
            isletmebilgi: widget.isletmebilgi,
            kullanicirolu: widget.kullanicirolu,
            mevcutadisyonId: adisyon.id,
          ),
        ),
      );

      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hizmet başarıyla eklendi'),
            backgroundColor: Colors.green,
          ),
        );

        // resetPage: false ile yenile - liste sıfırlanmaz, sadece güncellenir
        await fetchAdisyonlar(resetPage: false);
        await fetchAcikAdisyonlar(resetPage: false);
      }
    }

    void urunsatisiEkle(BuildContext context, Adisyon adisyon) async {
      if (adisyon.kalan_tutar == "0" || adisyon.kalan_tutar == "0,00") {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kapalı adisyona yeni ürün eklenemez'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UrunSatisi(
            musteriid: adisyon.user_id,
            senetlisatis: false,
            isletmebilgi: widget.isletmebilgi,
            kullanicirolu: widget.kullanicirolu,
            mevcutadisyonId: adisyon.id,
          ),
        ),
      );

      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ürün başarıyla eklendi'),
            backgroundColor: Colors.green,
          ),
        );

        await fetchAdisyonlar(resetPage: false);
        await fetchAcikAdisyonlar(resetPage: false);
      }
    }

    void paketsatisiEkle(BuildContext context, Adisyon adisyon) async {
      if (adisyon.kalan_tutar == "0" || adisyon.kalan_tutar == "0,00") {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kapalı adisyona yeni paket eklenemez'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaketSatisi(
            musteriid: adisyon.user_id,
            senetlisatis: false,
            isletmebilgi: widget.isletmebilgi,
            kullanicirolu: widget.kullanicirolu,
            mevcutadisyonId: adisyon.id,
          ),
        ),
      );

      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Paket başarıyla eklendi'),
            backgroundColor: Colors.green,
          ),
        );

        await fetchAdisyonlar(resetPage: false);
        await fetchAcikAdisyonlar(resetPage: false);
      }
    }
    void _toggleExpand(String adisyonId) {
      setState(() {
        if (_currentlyExpandedId == adisyonId) {
          // Aynı karta tekrar tıklandıysa kapat
          _currentlyExpandedId = null;
        } else {
          // Yeni karta tıklandıysa sadece onu aç
          _currentlyExpandedId = adisyonId;
        }
      });
    }
    // _AdisyonlarPageState sınıfına ekleyin
    Future<void> _deleteAdisyon(Adisyon adisyon, bool isOpenTab) async {
      // Silme onayı göster
      final confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 28),
                SizedBox(width: 12),
                Text('Adisyonu Sil'),
              ],
            ),
            content: Text(
              '${adisyon.musteri} adlı müşteriye ait adisyonu silmek istediğinize emin misiniz?\n\nBu işlem geri alınamaz!',
              style: TextStyle(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('İptal', style: TextStyle(color: Colors.grey.shade700)),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Silme işlemini burada yap, dialog'u kapatma
                  setState(() {
                    // Butonu disable et
                  });

                  try {
                    final response = await adisyonSil(adisyon.id);

                    if (response['success'] == true) {
                      // Önce dialog'u kapat
                      Navigator.of(context).pop(true);

                      if (mounted) {
                        setState(() {
                          if (isOpenTab) {
                            _acikAdisyonlar.removeWhere((item) => item.id == adisyon.id);
                            if (acikSayi != null && acikSayi!.isNotEmpty) {
                              int currentCount = int.tryParse(acikSayi!) ?? 0;
                              if (currentCount > 0) {
                                acikSayi = (currentCount - 1).toString();
                              }
                            }
                          } else {
                            _kapaliAdisyonlar.removeWhere((item) => item.id == adisyon.id);
                            if (kapaliSayi != null && kapaliSayi!.isNotEmpty) {
                              int currentCount = int.tryParse(kapaliSayi!) ?? 0;
                              if (currentCount > 0) {
                                kapaliSayi = (currentCount - 1).toString();
                              }
                            }
                          }
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Adisyon başarıyla silindi'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(response['message'] ?? 'Silme işlemi başarısız'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Hata: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                ),
                child: Text('Sil'),
              ),
            ],
          );
        },
      );
    }
    Widget _buildAdisyonCard(Adisyon adisyon, bool isOpenTab) {
      final bool isExpanded = _currentlyExpandedId == adisyon.id;
      final double toplam = double.tryParse(adisyon.toplam_numeric) ?? 0;
      final double odenen = double.tryParse(adisyon.odenen_numeric) ?? 0;
      final double kalan = double.tryParse(adisyon.kalan_tutar_numeric) ?? 0;
      final bool isFullPaid = kalan <= 0;
      final double progress = toplam > 0 ? (odenen / toplam).clamp(0.0, 1.0) : 0.0;
      final Color statusColor =
          isFullPaid ? Colors.green.shade600 : Colors.orange.shade600;
      final String personel =
          (adisyon.hizmet_veren.isNotEmpty && adisyon.hizmet_veren != "null")
              ? adisyon.hizmet_veren
              : '';

      return Container(
        margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _toggleExpand(adisyon.id),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(12, 10, 4, 10),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(Icons.person_outline,
                              size: 18, color: Colors.purple.shade400),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              adisyon.musteri,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            '₺${toplam.toStringAsFixed(2).replaceAll('.', ',')}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          _buildKebabMenu(adisyon, isOpenTab),
                        ],
                      ),
                      SizedBox(height: 2),
                      Padding(
                        padding: EdgeInsets.only(left: 24, right: 12),
                        child: Row(
                          children: [
                            Icon(Icons.event_outlined,
                                size: 11, color: Colors.grey.shade500),
                            SizedBox(width: 3),
                            Text(
                              adisyon.acilis_tarihi,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade600),
                            ),
                            if (adisyon.son_tahsilat_tarihi.isNotEmpty &&
                                adisyon.son_tahsilat_tarihi !=
                                    adisyon.acilis_tarihi) ...[
                              Text('  ·  ',
                                  style: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 12)),
                              Icon(Icons.payments_outlined,
                                  size: 11,
                                  color: Colors.green.shade500),
                              SizedBox(width: 3),
                              Text(
                                adisyon.son_tahsilat_tarihi,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                            if (personel.isNotEmpty) ...[
                              Text('  ·  ',
                                  style: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 12)),
                              Flexible(
                                child: Text(
                                  personel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(height: 10),
                      Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 6,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(statusColor),
                                ),
                              ),
                            ),
                            SizedBox(width: 10),
                            Text(
                              isFullPaid
                                  ? 'Tamamlandı'
                                  : 'Kalan ₺${kalan.toStringAsFixed(2).replaceAll('.', ',')}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              isExpanded
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              size: 22,
                              color: Colors.grey.shade400,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isExpanded) ...[
                  Container(height: 1, color: Colors.grey.shade100),
                  Padding(
                    padding: EdgeInsets.fromLTRB(12, 10, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCompactSalesContent(adisyon.icerikKisaltilmis),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildMiniStat(
                                'Toplam', toplam, Colors.grey.shade700),
                            _buildMiniStat(
                                'Ödenen', odenen, Colors.green.shade700),
                            _buildMiniStat(
                                'Kalan',
                                kalan,
                                kalan > 0
                                    ? Colors.orange.shade700
                                    : Colors.green.shade700),
                          ],
                        ),
                        if (!isFullPaid) ...[
                          SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 38,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TahsilatEkrani(
                                      kullanicirolu: widget.kullanicirolu,
                                      isletmebilgi: widget.isletmebilgi,
                                      musteridanisanid: adisyon.user_id,
                                      adisyonId: adisyon.id,
                                    ),
                                  ),
                                ).then((_) async {
                                  await _refreshAdisyonAfterPayment(
                                      adisyon, isOpenTab);
                                });
                              },
                              icon: Icon(Icons.payment_outlined, size: 16),
                              label: Text('Tahsilat Yap',
                                  style: TextStyle(fontSize: 13)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple.shade700,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    Widget _buildKebabMenu(Adisyon adisyon, bool isOpenTab) {
      final bool isKapali = adisyon.kalan_tutar == "0" ||
          adisyon.kalan_tutar == "0,00";
      return SizedBox(
        width: 32,
        height: 32,
        child: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert,
              size: 20, color: Colors.grey.shade500),
          padding: EdgeInsets.zero,
          splashRadius: 18,
          tooltip: '',
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          onSelected: (value) {
            switch (value) {
              case 'hizmet':
                hizmetsatisiEkle(context, adisyon);
                break;
              case 'urun':
                urunsatisiEkle(context, adisyon);
                break;
              case 'paket':
                paketsatisiEkle(context, adisyon);
                break;
              case 'sil':
                _deleteAdisyon(adisyon, isOpenTab);
                break;
            }
          },
          itemBuilder: (context) => [
            if (!isKapali) ...[
              PopupMenuItem(
                value: 'hizmet',
                child: Row(children: [
                  Icon(Icons.spa_outlined,
                      size: 18, color: Colors.purple.shade700),
                  SizedBox(width: 10),
                  Text('Hizmet Ekle'),
                ]),
              ),
              PopupMenuItem(
                value: 'urun',
                child: Row(children: [
                  Icon(Icons.shopping_bag_outlined,
                      size: 18, color: Colors.purple.shade700),
                  SizedBox(width: 10),
                  Text('Ürün Ekle'),
                ]),
              ),
              PopupMenuItem(
                value: 'paket',
                child: Row(children: [
                  Icon(Icons.inventory_2_outlined,
                      size: 18, color: Colors.purple.shade700),
                  SizedBox(width: 10),
                  Text('Paket Ekle'),
                ]),
              ),
              PopupMenuDivider(),
            ],
            PopupMenuItem(
              value: 'sil',
              child: Row(children: [
                Icon(Icons.delete_outline,
                    size: 18, color: Colors.red.shade600),
                SizedBox(width: 10),
                Text('Sil',
                    style: TextStyle(color: Colors.red.shade700)),
              ]),
            ),
          ],
        ),
      );
    }

    Widget _buildMiniStat(String label, double amount, Color color) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500)),
          SizedBox(height: 2),
          Text(
            '₺${amount.toStringAsFixed(2).replaceAll('.', ',')}',
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      );
    }

    Widget _buildCompactSalesContent(String content) {
      if (content.isEmpty) return SizedBox.shrink();
      final lines = content
          .split('\n')
          .where((l) => l.trim().isNotEmpty)
          .toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines.map((line) {
          Color dotColor;
          if (line.contains('(H)'))
            dotColor = Colors.blue.shade400;
          else if (line.contains('(Ü)'))
            dotColor = Colors.green.shade400;
          else if (line.contains('(P)'))
            dotColor = Colors.purple.shade400;
          else
            dotColor = Colors.grey.shade400;

          final parts =
              line.split('  ').where((p) => p.trim().isNotEmpty).toList();
          final name = parts.isNotEmpty
              ? parts[0]
                  .replaceAll('(H)', '')
                  .replaceAll('(Ü)', '')
                  .replaceAll('(P)', '')
                  .trim()
              : '';
          final fiyat = (parts.length > 2 && parts[2].contains('₺'))
              ? parts[2]
              : '';

          return Padding(
            padding: EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                      color: dotColor, shape: BoxShape.circle),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade800)),
                ),
                if (fiyat.isNotEmpty)
                  Text(fiyat,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800)),
              ],
            ),
          );
        }).toList(),
      );
    }
    Future<void> _refreshAdisyonAfterPayment(Adisyon oldAdisyon, bool wasInOpenTab) async {
      try {
        // Sadece bu adisyonu güncellemek için API çağrısı yap
        final jsonResponse = await satislar(
            seciliisletme!,
            "1", // sayfa 1
            _selectedDateRange != null
                ? DateFormat("yyyy-MM-dd").format(_selectedDateRange!.start.toLocal())
                : "1970-01-01",
            _selectedDateRange != null
                ? DateFormat("yyyy-MM-dd").format(_selectedDateRange!.end.toLocal())
                : DateFormat("yyyy-MM-dd").format(DateTime.now()),
            oldAdisyon.user_id, // Sadece bu müşteri için filtrele
            selectedadisyonicerigi?.id ?? "",
            "",
            false,
            widget.kullanicirolu == 5 ? widget.kullanici.id : '',
            -1 // tümü
        );

        List<dynamic> data = jsonResponse['data'];
        List<Adisyon> updatedAdisyonlar = data.map<Adisyon>((json) => Adisyon.fromJson(json)).toList();

        // Güncellenmiş adisyonu bul
        Adisyon? updatedAdisyon = updatedAdisyonlar.firstWhere(
              (a) => a.id == oldAdisyon.id,
          orElse: () => oldAdisyon,
        );

        // Kalan tutarı kontrol et
        double kalan = double.tryParse(updatedAdisyon.kalan_tutar_numeric) ?? 0;
        bool isNowClosed = kalan <= 0;

        setState(() {
          _acikAdisyonlar.removeWhere((item) => item.id == oldAdisyon.id);
          _kapaliAdisyonlar.removeWhere((item) => item.id == oldAdisyon.id);

          if (isNowClosed) {
            // Yeni kapanan adisyon en yeni tarihli oldugu icin liste basina ekle
            _kapaliAdisyonlar.insert(0, updatedAdisyon);
            if (acikSayi != null && acikSayi!.isNotEmpty) {
              int currentAcik = int.tryParse(acikSayi!) ?? 0;
              if (currentAcik > 0) {
                acikSayi = (currentAcik - 1).toString();
              }
            }
            int currentKapali = int.tryParse(kapaliSayi ?? '0') ?? 0;
            kapaliSayi = (currentKapali + 1).toString();
          } else {
            // Hala acik: degisen tutarlarla guncelle, en uste tasi
            _acikAdisyonlar.insert(0, updatedAdisyon);
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Tahsilat islemi tamamlandi'),
              backgroundColor: Colors.green,
            ),
          );
        }

      } catch (e) {
        await fetchAcikAdisyonlar(resetPage: true);
        if (_kapaliFetched) {
          await fetchAdisyonlar(resetPage: true);
        }
      }
    }
    Widget _buildFilterBottomSheet() {
      return StatefulBuilder(
        builder: (context, setStateSB) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.65, // Ekranın %65'i
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Üst başlık bölümü
                Container(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filtrele',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close, color: Colors.grey.shade600, size: 22),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                    ],
                  ),
                ),

                // İçerik bölümü
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(20),
                    physics: AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFilterSection(
                          icon: Icons.person_outline,
                          title: 'Müşteri',
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: LazyDropdown(
                              salonId: seciliisletme ?? '',
                              selectedItem: selectedMusteri,
                              onChanged: (value) {
                                setStateSB(() {
                                  selectedMusteri = value;
                                });
                              },
                            ),
                          ),
                        ),

                        SizedBox(height: 16),

                        _buildFilterSection(
                          icon: Icons.category_outlined,
                          title: 'Satış Türü',
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton2<SatisTuru>(
                                isExpanded: true,
                                hint: Padding(
                                  padding: EdgeInsets.only(left: 12),
                                  child: Text(
                                    'Tümü Seç',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                                items: adisyonicerigi
                                    .map((item) => DropdownMenuItem(
                                  value: item,
                                  child: Padding(
                                    padding: EdgeInsets.only(left: 12),
                                    child: Text(
                                      item.satisturu,
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ))
                                    .toList(),
                                value: selectedadisyonicerigi,
                                onChanged: (value) {
                                  setStateSB(() {
                                    selectedadisyonicerigi = value;
                                  });
                                },
                                buttonStyleData: ButtonStyleData(
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  height: 50,
                                ),
                                dropdownStyleData: DropdownStyleData(
                                  maxHeight: 200,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                menuItemStyleData: MenuItemStyleData(height: 40),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 16),

                        _buildFilterSection(
                          icon: Icons.calendar_today_outlined,
                          title: 'Tarih Aralığı',
                          child: Column(
                            children: [
                              ElevatedButton(
                                onPressed: () async {
                                  final DateTimeRange? picked =
                                  await showDateRangePicker(
                                    context: context,
                                    firstDate: DateTime(1970),
                                    lastDate: DateTime(2050),
                                    initialDateRange: _selectedDateRange,
                                    builder: (context, child) {
                                      return Theme(
                                        data: ThemeData.light().copyWith(
                                          colorScheme: ColorScheme.light(
                                            primary: Colors.purple.shade700,
                                            onPrimary: Colors.white,
                                          ),
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (picked != null && picked != _selectedDateRange) {
                                    setStateSB(() {
                                      _selectedDateRange = picked;
                                    });
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple.shade50,
                                  foregroundColor: Colors.purple.shade700,
                                  minimumSize: Size(double.infinity, 50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(color: Colors.purple.shade100),
                                  ),
                                  elevation: 0,
                                  shadowColor: Colors.transparent,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.date_range_outlined, size: 20),
                                    SizedBox(width: 8),
                                    Text('Tarih Seç'),
                                  ],
                                ),
                              ),

                              if (_selectedDateRange != null) ...[
                                SizedBox(height: 12),
                                Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.green.shade100),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Başlangıç',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.green.shade700,
                                            ),
                                          ),
                                          Text(
                                            DateFormat("dd.MM.yyyy")
                                                .format(_selectedDateRange!.start.toLocal()),
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Colors.green.shade800,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Icon(Icons.arrow_forward,
                                          color: Colors.green.shade600, size: 20),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            'Bitiş',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.green.shade700,
                                            ),
                                          ),
                                          Text(
                                            DateFormat("dd.MM.yyyy")
                                                .format(_selectedDateRange!.end.toLocal()),
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Colors.green.shade800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ] else ...[
                                SizedBox(height: 12),
                                Text(
                                  'Tarih seçilmedi',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Butonlar bölümü
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade200, width: 1),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setStateSB(() {
                              _selectedDateRange = null;
                              selectedMusteri = null;
                              selectedadisyonicerigi = null;
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey.shade700,
                            side: BorderSide(color: Colors.grey.shade300),
                            minimumSize: Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text('Sıfırla'),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            fetchAdisyonlar();
                            fetchAcikAdisyonlar();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple.shade700,
                            foregroundColor: Colors.white,
                            minimumSize: Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                            shadowColor: Colors.transparent,
                          ),
                          child: Text('Uygula'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    }
    Widget _buildFilterSection({
      required IconData icon,
      required String title,
      required Widget child,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Colors.grey.shade700),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          child,
        ],
      );
    }

    Widget _buildEmptyState(bool isOpenTab) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isOpenTab ? Icons.pending_outlined : Icons.check_circle_outline,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
              ),
              SizedBox(height: 24),
              Text(
                isOpenTab ? 'Açık adisyon bulunmuyor' : 'Kapalı adisyon bulunmuyor',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              SizedBox(height: 12),
              Text(
                isOpenTab
                    ? 'Devam eden satış işlemi bulunmamaktadır'
                    : 'Tamamlanan satış işlemi bulunmamaktadır',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.receipt_long, color: Colors.purple.shade700, size: 20),
              ),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Satışlar',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  Text(
                    'Adisyon Yönetimi',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          leading: widget.geriGitBtn
              ? IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.grey.shade700),
            onPressed: () => Navigator.of(context).pop(),
          )
              : null,
          toolbarHeight: 70,
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(80),
            child: Column(
              children: [
                // Mor çerçeve içinde TabBar
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.purple.shade200,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.shade50,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white,
                          Colors.white,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.9),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                    unselectedLabelStyle: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                    unselectedLabelColor: Colors.grey.shade700,
                    labelColor: Colors.grey.shade800,
                    dividerColor: Colors.transparent,
                    tabs: [
                      Tab(
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.pending_outlined,
                                  size: 14,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text('Açık'),
                              SizedBox(width: 4),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  _isLoading ? '' : (acikSayi ?? '0'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),

                            ],
                          ),
                        ),
                      ),
                      Tab(
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.check_circle_outline,
                                  size: 14,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text('Kapalı'),
                              SizedBox(width: 4),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  _isLoading ? '' : (kapaliSayi ?? '0'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),

                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Alt çizgi
                Container(
                  height: 2,
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.purple.shade100,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            if (widget.isletmebilgi["demo_hesabi"].toString() == "1")
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: YukseltButonu(isletme_bilgi: widget.isletmebilgi),
              ),
            Container(
              width: 40,
              height: 40,
              margin: EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => _buildFilterBottomSheet(),
                  );
                },
                icon: Icon(Icons.filter_alt_outlined, size: 20, color: Colors.grey.shade700),
                padding: EdgeInsets.zero,
              ),
            ),
            /*if (widget.kullanicirolu != 5)
              Container(
                width: 40,
                height: 40,
                margin: EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.purple.shade700,
                      Colors.purple.shade500,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TahsilatEkrani(
                          kullanicirolu: widget.kullanicirolu,
                          isletmebilgi: widget.isletmebilgi,
                          musteridanisanid: "",
                          adisyonId: "",
                        ),
                      ),
                    );
                  },
                  icon: Icon(Icons.add, color: Colors.white, size: 20),
                  padding: EdgeInsets.zero,
                ),
              ),*/
          ],
          backgroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.black.withOpacity(0.05),
        ),
        body: _isLoading
            ? Center(
          child: CircularProgressIndicator(
            color: Colors.purple.shade700,
          ),
        )
            : TabBarView(
          controller: _tabController,
          children: [
            _buildAdisyonListView(_acikAdisyonlar, true),
            _buildAdisyonListView(_kapaliAdisyonlar, false),
          ],
        ),
      );
    }

    Widget _buildAdisyonListView(List<Adisyon> adisyonlar, bool isOpenTab) {
      final bool tabLoading = isOpenTab ? _isLoadingAcikMore : _isLoadingMore;
      final bool hasMore = isOpenTab
          ? (_currentPageAcik < _totalPagesAcik)
          : (_currentPage < _totalPages);

      if (adisyonlar.isEmpty && !tabLoading) {
        return _buildEmptyState(isOpenTab);
      }

      return NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200 &&
              !tabLoading &&
              hasMore) {
            if (isOpenTab) {
              _loadMoreAcikData();
            } else {
              _loadMoreData();
            }
            return true;
          }
          return false;
        },
        child: RefreshIndicator(
          color: Colors.purple.shade700,
          backgroundColor: Colors.white,
          onRefresh: () async {
            if (isOpenTab) {
              await fetchAcikAdisyonlar();
            } else {
              await fetchAdisyonlar();
            }
          },
          child: ListView.builder(
            physics: AlwaysScrollableScrollPhysics(),
            itemCount: adisyonlar.length + (tabLoading ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == adisyonlar.length) {
                return Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.purple.shade700,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                );
              }
              return _buildAdisyonCard(adisyonlar[index], isOpenTab);
            },
          ),
        ),
      );
    }
  }
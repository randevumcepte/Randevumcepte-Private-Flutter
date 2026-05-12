import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:randevu_sistem/yonetici/diger/menu/musteriler/sadikmusteriler.dart';
import 'package:randevu_sistem/yonetici/diger/menu/musteriler/yeni_musteri.dart';
// import 'package:randevu_sistem/yonetici/diger/menu/musteriler/musteri_toplu_ocr.dart'; // TODO: Toplu OCR tamamlanınca aç
import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Models/musterisayilari.dart';
import 'rehberdekimusteriler.dart';
import 'aktifmusteriler.dart';
import 'pasifmusteriler.dart';
import 'tummusteriler.dart';
import 'package:permission_handler/permission_handler.dart';

class MusteriListesi extends StatefulWidget {
  final dynamic isletmebilgi;
  final int kullanicirolu;
  const MusteriListesi({Key? key, required this.isletmebilgi,required this.kullanicirolu}) : super(key: key);

  @override
  _MusteriListesiState createState() => _MusteriListesiState();
}

class _MusteriListesiState extends State<MusteriListesi> {
  MusteriSayilari? _musteriSayilari;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMusteriSayilari();
  }

  Future<void> _loadMusteriSayilari() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final sayilar = await musteriSayilariGetir(widget.isletmebilgi['id'].toString());

      setState(() {
        _musteriSayilari = sayilar;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      print('Müşteri sayıları yükleme hatası: $e');
    }
  }

  // İzin durumunu kontrol etmek için
  Future<bool> _checkAndRequestPermission() async {
    var status = await Permission.contacts.status;

    if (status.isGranted) {
      return true;
    } else {
      status = await Permission.contacts.request();

      if (status.isGranted) {
        return true;
      } else if (status.isPermanentlyDenied) {
        _showPermissionSettingsDialog();
        return false;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Rehber erişim izni gereklidir!")),
        );
        return false;
      }
    }
  }

  void _showPermissionSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text("İzin Gerekli"),
        content: Text("Rehber erişimi için izin gereklidir. Lütfen ayarlardan izin verin."),
        actions: <Widget>[
          TextButton(
            child: Text("İptal"),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text("Ayarlar"),
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
          ),
        ],
      ),
    );
  }



  Widget _buildTabWithCount(String title, int? count, Color color) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Tab(
        child: Container(
          constraints: BoxConstraints(minWidth: 120),
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (count != null) ...[
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.orange, size: 16),
          SizedBox(width: 8),
          Flexible(
            child: Text(
              'Sayılar yüklenemedi',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Color primaryColor = scheme.primary;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Color.alphaBlend(
                primaryColor.withValues(alpha: 0.36),
                Colors.white,
              ),
              Color.alphaBlend(
                scheme.tertiary.withValues(alpha: 0.08),
                Colors.white,
              ),
            ],
          ),
        ),
        child: DefaultTabController(
        length: 4,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: false,
          appBar: AppBar(
            centerTitle: false,
            title: Text(
              'Müşteriler',
              style: TextStyle(
                color: scheme.onSurface,
                fontWeight: FontWeight.w800,
                fontSize: 22,
                letterSpacing: -0.3,
              ),
            ),
            leading:
              IconButton(
                icon: Icon(Icons.arrow_back, color: primaryColor, size: 20),
                onPressed: () => Navigator.of(context).pop(),

            ),
            actions: <Widget>[

              Container(
                margin: EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(Icons.person_add_alt_1, color: primaryColor),
                  iconSize: 22,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Yenimusteri(
                          isletmebilgi: widget.isletmebilgi,
                          isim: "",
                          telefon: "",
                          sadeceekranikapat: false,
                          kullanicirolu: widget.kullanicirolu,
                        ),
                      ),
                    );
                  },
                ),
              ),
              // TODO: Belgeden bilgi ekleme (Toplu Tara) — iş bitince aç
              // Container(
              //   margin: EdgeInsets.only(right: 8),
              //   decoration: BoxDecoration(
              //     color: Colors.white,
              //     borderRadius: BorderRadius.circular(12),
              //     boxShadow: [
              //       BoxShadow(
              //         color: Colors.black12,
              //         blurRadius: 4,
              //         offset: Offset(0, 2),
              //       ),
              //     ],
              //   ),
              //   child: IconButton(
              //     icon: Icon(Icons.document_scanner_outlined, color: primaryColor),
              //     iconSize: 22,
              //     tooltip: 'Toplu Tara',
              //     onPressed: () async {
              //       final sonuc = await Navigator.push(
              //         context,
              //         MaterialPageRoute(
              //           builder: (context) => MusteriTopluOcr(
              //             isletmebilgi: widget.isletmebilgi,
              //             kullanicirolu: widget.kullanicirolu,
              //           ),
              //         ),
              //       );
              //       if (sonuc == true) {
              //         _loadMusteriSayilari();
              //       }
              //     },
              //   ),
              // ),
              Platform.isIOS ? SizedBox():
              Container(
                margin: EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(Icons.contacts_rounded, color: primaryColor),
                  iconSize: 22,
                  tooltip: 'Rehberden toplu ekle',
                  onPressed: () async {
                    final hasPermission = await _checkAndRequestPermission();
                    if (!hasPermission) return;
                    if (!mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ContactSelectionPage(
                          isletmebilgi: widget.isletmebilgi,
                          kullanicirolu: widget.kullanicirolu,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            toolbarHeight: 80,
            backgroundColor: Colors.transparent,
            elevation: 0,
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(_isLoading || _errorMessage != null ? 80 : 70),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.05),
                      blurRadius: 14,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    if (_isLoading || _errorMessage != null)
                      Container(
                        height: 30,
                        child: _isLoading
                            ? SizedBox.shrink() // Yükleniyor çizgisi kaldırıldı
                            : _buildErrorWidget(),
                      ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 1, vertical: 10),
                      child: TabBar(
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        indicatorSize: TabBarIndicatorSize.label,
                        labelColor: primaryColor,
                        unselectedLabelColor: Colors.grey[600],
                        dividerColor: Colors.transparent,
                        indicator: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          color: primaryColor.withValues(alpha: 0.10),
                        ),
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        unselectedLabelStyle: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                        tabs: [
                          _buildTabWithCount(
                            "Tüm Müşteriler",
                            _musteriSayilari?.tumMusteriler,
                            primaryColor,
                          ),
                          _buildTabWithCount(
                            "Sadık Müşteriler",
                            _musteriSayilari?.sadikMusteriler,
                            Color(0xFF4CAF50), // Yeşil
                          ),
                          _buildTabWithCount(
                            "Aktif Müşteriler",
                            _musteriSayilari?.aktifMusteriler,
                            Color(0xFF2196F3), // Mavi
                          ),
                          _buildTabWithCount(
                            "Pasif Müşteriler",
                            _musteriSayilari?.pasifMusteriler,
                            Color(0xFFFF9800), // Turuncu
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: TabBarView(
            children: <Widget>[
              TumMusteriler(kullanicirolu: widget.kullanicirolu,isletmebilgi: widget.isletmebilgi),
              SadikMusteriler(kullanicirolu: widget.kullanicirolu, isletmebilgi: widget.isletmebilgi),
              AktifMusteriler(kullanicirolu: widget.kullanicirolu, isletmebilgi: widget.isletmebilgi),
              PasifMusteriler(kullanicirolu: widget.kullanicirolu,isletmebilgi: widget.isletmebilgi),
            ],
          ),
        ),
      ),
    ),
  );
  }
}
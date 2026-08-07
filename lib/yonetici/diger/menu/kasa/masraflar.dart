import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Backend/yetki.dart';
import 'package:randevu_sistem/Frontend/sfdatatable.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:randevu_sistem/Models/masrafkategorileri.dart';
import 'package:randevu_sistem/Models/masraflar.dart';
import 'package:randevu_sistem/Models/personel.dart';

import 'masrafduzenle.dart';
import 'masrafekle.dart';

class Masraflar extends StatefulWidget {
  final String tarih;
  final String odeme_yontemi;
  final dynamic isletmebilgi;
  const Masraflar({
    Key? key,
    required this.tarih,
    required this.odeme_yontemi,
    required this.isletmebilgi,
  }) : super(key: key);

  @override
  _MasraflarState createState() => _MasraflarState();
}

class _MasraflarState extends State<Masraflar> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  late GiderDataSource _giderDataGridSource;
  String? seciliisletme;
  List<Personel> harcayan = [];
  List<MasrafKategorisi> masrafturu = [];

  bool _isLoading = true;
  String? _lastQuery;

  @override
  void initState() {
    super.initState();
    initialize();
    _controller.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> initialize() async {
    seciliisletme = await secilisalonid();
    final List<Personel> personeller = await personellistegetir(seciliisletme!);
    final List<MasrafKategorisi> masrafkategorisi = await masrafkategorileri();
    setState(() {
      harcayan = personeller;
      masrafturu = masrafkategorisi;
      _giderDataGridSource = GiderDataSource(
        isletmebilgi: widget.isletmebilgi,
        rowsPerPage: 10,
        salonid: seciliisletme!,
        context: context,
        odemeyontemi: widget.odeme_yontemi,
        tarih: widget.tarih,
        harcayan: '',
        personelliste: personeller,
        masrafkategoriliste: masrafkategorisi,
      );
      _giderDataGridSource.isLoadingNotifier.addListener(_onDataChanged);
      _isLoading = false;
    });
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  void _onSearchChanged() {
    if (_controller.text.isEmpty || _controller.text.length >= 3) {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 500), () {
        if (_controller.text != _lastQuery) {
          _lastQuery = _controller.text;
          _giderDataGridSource.search(_controller.text);
        }
      });
    }
  }

  String _formatTarih(String date) {
    try {
      final DateTime dt = DateTime.parse('${date}T00:00:00');
      return DateFormat('dd.MM.yyyy').format(dt);
    } catch (_) {
      return date;
    }
  }

  String _odemeYontemi(String id) {
    switch (id) {
      case '1':
        return 'Nakit';
      case '2':
        return 'Kredi Kartı';
      case '3':
        return 'Havale/EFT';
      case '4':
        return 'Diğer';
      default:
        return '';
    }
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
        resizeToAvoidBottomInset: false,
        appBar: _buildAppBar(scheme),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.purple))
            : GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: Column(
                  children: [
                    _buildSearchField(scheme),
                    Expanded(child: _buildList(scheme)),
                    _buildPagination(),
                  ],
                ),
              ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ColorScheme scheme) {
    return AppBar(
      elevation: 0,
      centerTitle: false,
      backgroundColor: Colors.transparent,
      title: Text(
        'Masraflar',
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 22,
          color: scheme.onSurface,
          letterSpacing: -0.3,
        ),
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios, color: scheme.onSurface),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        if (widget.isletmebilgi["demo_hesabi"].toString() == "1")
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: SizedBox(
              width: 100,
              child: YukseltButonu(isletme_bilgi: widget.isletmebilgi),
            ),
          ),
        if (Yetki.varMi('finans.masraf_ekle'))
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MasrafEkle(
                      personeller: harcayan,
                      masrafkategorileri: masrafturu,
                      seciliisletme: seciliisletme!,
                      giderDataSource: _giderDataGridSource,
                      isletmebilgi: widget.isletmebilgi,
                    ),
                  ),
                );
              },
              icon: Icon(Icons.add, color: scheme.primary),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                elevation: 0,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSearchField(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: 'Harcayan ara...',
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixIcon: Icon(Icons.search, color: scheme.primary),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: scheme.primary),
          ),
        ),
      ),
    );
  }

  Widget _buildList(ColorScheme scheme) {
    final List<Masraf> masraflar = _giderDataGridSource.masraf;

    if (masraflar.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.money_off_rounded, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Masraf kaydı bulunamadı',
                style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      itemCount: masraflar.length,
      itemBuilder: (context, index) {
        final Masraf m = masraflar[index];
        final double tutar = double.tryParse(m.tutar.toString()) ?? 0;
        final String? kategori = m.masraf_kategorisi["kategori"]?.toString();
        final String _aciklamaText = m.aciklama.trim();
        final bool _aciklamaVar = _aciklamaText.isNotEmpty && _aciklamaText.toLowerCase() != 'null';
        return Card(
          elevation: 0,
          color: Colors.white,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            onTap: () => _showMasrafDetay(m),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            leading: CircleAvatar(
              backgroundColor: Colors.red.shade50,
              child: const Icon(Icons.money_off_rounded, color: Colors.red),
            ),
            title: Text(
              m.harcayan["personel_adi"]?.toString() ?? 'İşlem',
              style: const TextStyle(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatTarih(m.tarih),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                if (kategori != null && kategori.isNotEmpty && kategori != 'null')
                  Text(
                    kategori,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (_aciklamaVar)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      _aciklamaText,
                      style: TextStyle(fontSize: 11.5, color: Colors.grey[700], fontStyle: FontStyle.italic),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (m.personel_gideri)
                  Container(
                    margin: const EdgeInsets.only(top: 3),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Personel Gideri',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFB45309),
                      ),
                    ),
                  ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '- ${NumberFormat('#,##0.00', 'tr_TR').format(tutar)} ₺',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _odemeYontemi(m.odeme_yontemi_id),
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPagination() {
    final int totalPages = _giderDataGridSource.totalPages.ceil();
    if (totalPages <= 1) return const SizedBox(height: 8);
    final int current = _giderDataGridSource.currentPage;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            style: IconButton.styleFrom(backgroundColor: Colors.white),
            onPressed: current > 1
                ? () => _giderDataGridSource.setPage(current - 1)
                : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Sayfa $current / $totalPages',
                style: const TextStyle(fontSize: 14)),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            style: IconButton.styleFrom(backgroundColor: Colors.white),
            onPressed: current < totalPages
                ? () => _giderDataGridSource.setPage(current + 1)
                : null,
          ),
        ],
      ),
    );
  }

  void _showMasrafDetay(Masraf m) {
    final scheme = Theme.of(context).colorScheme;
    final double tutar = double.tryParse(m.tutar.toString()) ?? 0;
    final String? kategori = m.masraf_kategorisi["kategori"]?.toString();
    final String aciklama =
        (m.notlar != 'null' && m.notlar.trim().isNotEmpty) ? m.notlar : '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.red.shade50,
                  child: const Icon(Icons.money_off_rounded, color: Colors.red),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    m.harcayan["personel_adi"]?.toString() ?? 'İşlem',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  '- ${NumberFormat('#,##0.00', 'tr_TR').format(tutar)} ₺',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red),
                ),
              ],
            ),
            const Divider(height: 24),
            _detayRow('Tarih', _formatTarih(m.tarih)),
            _detayRow('Ödeme Yöntemi', _odemeYontemi(m.odeme_yontemi_id)),
            if (kategori != null && kategori.isNotEmpty && kategori != 'null')
              _detayRow('Kategori', kategori),
            if (aciklama.isNotEmpty) _detayRow('Açıklama', aciklama),
            const SizedBox(height: 20),
            Row(
              children: [
                if (Yetki.varMi('finans.masraf_ekle')) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _masrafSil(m);
                      },
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Sil'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MasrafDuzenle(
                            personeller: harcayan,
                            masrafkategorileri: masrafturu,
                            giderDataSource: _giderDataGridSource,
                            seciliisletme: seciliisletme!,
                            masraf: m,
                            isletmebilgi: widget.isletmebilgi,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Düzenle'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: scheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _masrafSil(Masraf m) async {
    final scheme = Theme.of(context).colorScheme;
    final double tutar = double.tryParse(m.tutar.toString()) ?? 0;

    final bool? onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Masrafı Sil'),
        content: Text(
          '${m.harcayan["personel_adi"] ?? "Bu"} masrafını '
          '(- ${NumberFormat('#,##0.00', 'tr_TR').format(tutar)} ₺) '
          'silmek istediğinize emin misiniz? Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Vazgeç',
                style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.6))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (onay != true) return;

    bool basarili = false;
    try {
      basarili = await masrafsil(seciliisletme!, m.id);
    } catch (_) {
      basarili = false;
    }

    if (!mounted) return;

    if (basarili) {
      _giderDataGridSource.fetchData(
          _giderDataGridSource.currentPage.toString(), '', true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masraf kaydı silindi'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masraf silinemedi, lütfen tekrar deneyin'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _detayRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

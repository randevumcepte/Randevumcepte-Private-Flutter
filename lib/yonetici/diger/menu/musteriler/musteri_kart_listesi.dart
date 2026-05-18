import 'dart:async';

import 'package:flutter/material.dart';
import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Backend/yetki.dart';
import 'package:randevu_sistem/Frontend/sfdatatable.dart';
import 'package:randevu_sistem/Models/musteri_danisanlar.dart';

import 'musteridetaylar.dart';
import 'musteriduzenle.dart';

class MusteriKartListesi extends StatefulWidget {
  final dynamic isletmebilgi;
  final int kullanicirolu;
  // '0' pasif, '1' aktif, '2' sadık, '3' tüm
  final String durum;
  final Color accent;
  final String bosBaslik;
  final String bosAciklama;

  const MusteriKartListesi({
    Key? key,
    required this.isletmebilgi,
    required this.kullanicirolu,
    required this.durum,
    required this.accent,
    this.bosBaslik = 'Müşteri bulunamadı',
    this.bosAciklama = 'Henüz kayıt yok ya da aramaya uyan sonuç yok',
  }) : super(key: key);

  @override
  State<MusteriKartListesi> createState() => _MusteriKartListesiState();
}

class _MusteriKartListesiState extends State<MusteriKartListesi> {
  MusteriDanisanDataSource? _ds;
  String? _seciliisletme;
  bool _isLoading = true;
  bool _firstTime = true;
  String? _lastQuery;
  Timer? _debounce;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _init();
    _searchCtrl.addListener(_onSearchChanged);
  }

  Future<void> _init() async {
    _seciliisletme = await secilisalonid();
    if (!mounted) return;
    setState(() {
      _ds = MusteriDanisanDataSource(
        kullanicirolu: widget.kullanicirolu,
        isletmebilgi: widget.isletmebilgi,
        rowsPerPage: 10,
        salonid: _seciliisletme!,
        context: context,
        durum: widget.durum,
        arama: _searchCtrl.text,
      );
      _ds!.isLoadingNotifier.addListener(_onLoadingChanged);
      _isLoading = false;
    });
  }

  void _onLoadingChanged() {
    if (mounted) setState(() {});
  }

  void _onSearchChanged() {
    final text = _searchCtrl.text;
    if (text.isEmpty || text.length >= 3) {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 500), () {
        if (text != _lastQuery && !_firstTime) {
          if (!mounted) return;
          setState(() {
            _firstTime = false;
            _lastQuery = text;
            _ds?.search(text);
          });
        }
      });
    } else if (_firstTime) {
      _firstTime = false;
    }
    if (mounted) setState(() {}); // temizle ikonunu güncelle
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ds?.isLoadingNotifier.removeListener(_onLoadingChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _ds == null) {
      return Center(
        child: CircularProgressIndicator(
          color: widget.accent,
          strokeWidth: 2.5,
        ),
      );
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Column(
        children: [
          _buildSearch(),
          Expanded(child: _buildList()),
          _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.accent.withValues(alpha: 0.10),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.accent.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchCtrl,
          textInputAction: TextInputAction.search,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: 'Ad veya telefon ile ara',
            hintStyle: TextStyle(
              color: Colors.grey[500],
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Icon(Icons.search_rounded,
                color: widget.accent, size: 22),
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.close_rounded,
                        size: 18, color: Colors.grey[600]),
                    onPressed: () {
                      _searchCtrl.clear();
                      _ds?.search('');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    final musteriler = _ds!.musteridanisan;
    if (musteriler.isEmpty) {
      return _buildEmpty();
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      itemCount: musteriler.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _buildCard(musteriler[i]),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: widget.accent.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.people_outline_rounded,
                  size: 44, color: widget.accent),
            ),
            const SizedBox(height: 16),
            Text(
              widget.bosBaslik,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.bosAciklama,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(MusteriDanisan m) {
    final scheme = Theme.of(context).colorScheme;
    final pr = m.profil_resim;
    final hasImage = pr != null && pr.isNotEmpty && pr != 'null';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _ds!.showDetailsDialog(context, m),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: widget.accent.withValues(alpha: 0.10),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.accent.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.accent.withValues(alpha: 0.12),
                  image: hasImage
                      ? DecorationImage(
                          image: NetworkImage(pr),
                          fit: BoxFit.cover,
                        )
                      : null,
                  border: Border.all(
                    color: widget.accent.withValues(alpha: 0.18),
                    width: 1.5,
                  ),
                ),
                child: hasImage
                    ? null
                    : Center(
                        child: Text(
                          _getInitials(m.name),
                          style: TextStyle(
                            color: widget.accent,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      m.name.isEmpty ? '-' : m.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                        color: scheme.onSurface,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.phone_rounded,
                            size: 13, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            _phoneText(m.cep_telefon),
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        _buildBadge(
                          icon: Icons.event_rounded,
                          text: '${_safeNum(m.randevu_sayisi)} randevu',
                          color: widget.accent,
                        ),
                        if (_validDate(m.son_randevu_tarihi)) ...[
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Son: ${m.son_randevu_tarihi}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              _buildMenu(m),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenu(MusteriDanisan m) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_rounded,
          color: Colors.grey[600], size: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      elevation: 6,
      onSelected: (value) {
        if (value == 'bilgi') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MusteriDetaylari(
                kullanicirolu: widget.kullanicirolu,
                isletmebilgi: widget.isletmebilgi,
                md: m,
              ),
            ),
          );
        } else if (value == 'duzenle') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MusteriDuzenle(
                kullanicirolu: widget.kullanicirolu,
                isletmebilgi: widget.isletmebilgi,
                md: m,
              ),
            ),
          );
        } else if (value == 'sil') {
          _ds!.showMusteriSilmeConfirmationDialog(
              context, m.id, _seciliisletme!);
        }
      },
      itemBuilder: (context) => [
        _menuItem('bilgi', Icons.info_outline_rounded, 'Detaylı Bilgi'),
        if (Yetki.varMi('musteri.ekle_duzenle'))
          _menuItem('duzenle', Icons.edit_outlined, 'Düzenle'),
        if (Yetki.varMi('musteri.sil'))
          _menuItem('sil', Icons.delete_outline_rounded, 'Sil',
              danger: true),
      ],
    );
  }

  PopupMenuItem<String> _menuItem(
    String value,
    IconData icon,
    String label, {
    bool danger = false,
  }) {
    final color = danger ? Colors.red[600] : Colors.grey[800];
    return PopupMenuItem<String>(
      value: value,
      height: 40,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13.5,
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  String _phoneText(String raw) {
    if (raw.isEmpty || raw == 'null') return 'Telefon yok';
    // musteri.telefon_gor yetkisi yoksa maske: "0532 *** ** 47"
    return Yetki.telefonGoster(raw);
  }

  String _safeNum(String s) {
    if (s.isEmpty || s == 'null') return '0';
    return s;
  }

  bool _validDate(String s) {
    return s.isNotEmpty && s != 'null' && s != 'NULL';
  }

  Widget _buildPagination() {
    final total = _ds!.totalPages;
    final current = _ds!.currentPage;
    if (total <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _pageBtn(Icons.chevron_left_rounded, current > 1, () {
            setState(() {
              _ds!.setPage(current - 1);
            });
          }),
          const SizedBox(width: 14),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: widget.accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Sayfa $current / $total',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
                color: widget.accent,
                letterSpacing: -0.1,
              ),
            ),
          ),
          const SizedBox(width: 14),
          _pageBtn(Icons.chevron_right_rounded, current < total, () {
            setState(() {
              _ds!.setPage(current + 1);
            });
          }),
        ],
      ),
    );
  }

  Widget _pageBtn(IconData icon, bool enabled, VoidCallback onTap) {
    return Material(
      color: enabled ? widget.accent : Colors.grey[200],
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 22,
            color: enabled ? Colors.white : Colors.grey[400],
          ),
        ),
      ),
    );
  }
}

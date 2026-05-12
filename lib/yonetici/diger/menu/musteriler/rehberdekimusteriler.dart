import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/theme/premium_components.dart';

import 'musteriliste.dart';

class ContactSelectionPage extends StatefulWidget {
  final dynamic isletmebilgi;
  final int kullanicirolu;
  const ContactSelectionPage({
    Key? key,
    required this.isletmebilgi,
    required this.kullanicirolu,
  }) : super(key: key);

  @override
  _ContactSelectionPageState createState() => _ContactSelectionPageState();
}

class _ContactSelectionPageState extends State<ContactSelectionPage> {
  String? _seciliisletme;
  List<Contact> _contacts = [];
  List<Contact> _filteredContacts = [];
  final Set<String> _selectedIds = {};
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    _seciliisletme = await secilisalonid();
    await _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);

    final status = await Permission.contacts.request();
    if (!status.isGranted) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rehber erişim izni reddedildi!')),
      );
      return;
    }

    final contacts = await FlutterContacts.getContacts(
      withProperties: true,
      withThumbnail: false,
    );
    // sadece telefonu olanlar
    final filtered = contacts
        .where((c) => c.phones.isNotEmpty)
        .toList()
      ..sort((a, b) =>
          (a.displayName).toLowerCase().compareTo((b.displayName).toLowerCase()));

    if (!mounted) return;
    setState(() {
      _contacts = filtered;
      _filteredContacts = filtered;
      _isLoading = false;
    });
  }

  void _toggleSelection(Contact contact) {
    setState(() {
      if (_selectedIds.contains(contact.id)) {
        _selectedIds.remove(contact.id);
      } else {
        _selectedIds.add(contact.id);
      }
    });
  }

  bool get _allFilteredSelected =>
      _filteredContacts.isNotEmpty &&
      _filteredContacts.every((c) => _selectedIds.contains(c.id));

  void _toggleSelectAllFiltered() {
    setState(() {
      if (_allFilteredSelected) {
        for (final c in _filteredContacts) {
          _selectedIds.remove(c.id);
        }
      } else {
        for (final c in _filteredContacts) {
          _selectedIds.add(c.id);
        }
      }
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      final q = query.toLowerCase().trim();
      if (q.isEmpty) {
        _filteredContacts = _contacts;
      } else {
        _filteredContacts = _contacts.where((c) {
          final name = c.displayName.toLowerCase();
          final phone = c.phones.isNotEmpty
              ? c.phones.first.number.replaceAll(RegExp(r'\D'), '')
              : '';
          return name.contains(q) || phone.contains(q);
        }).toList();
      }
    });
  }

  String _normalizePhone(String raw) {
    return raw.replaceAll(RegExp(r'\D'), '');
  }

  String _phoneForSave(String raw) {
    var digits = _normalizePhone(raw);
    if (digits.startsWith('90') && digits.length > 10) {
      digits = digits.substring(2);
    }
    if (!digits.startsWith('0')) {
      digits = '0$digits';
    }
    return digits;
  }

  List<Contact> get _selectedContacts =>
      _contacts.where((c) => _selectedIds.contains(c.id)).toList();

  Future<void> _handleSelection() async {
    final selected = _selectedContacts;
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Önce eklenecek kişileri seçin')),
      );
      return;
    }
    if (_seciliisletme == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İşletme bilgisi yüklenemedi')),
      );
      return;
    }

    final scheme = Theme.of(context).colorScheme;
    final primary = scheme.primary;

    // check_phone: zaten kayıtlı olanları ayır
    final phones =
        selected.map((c) => _normalizePhone(c.phones.first.number)).toList();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _LoadingDialog(primary: primary, text: 'Numaralar kontrol ediliyor...'),
    );

    Set<String> existingPhones = {};
    try {
      final response = await http.post(
        Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/check_phone'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phones': phones}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['phones'] is List) {
          for (final p in data['phones'] as List) {
            if (p['exists'] == true) {
              existingPhones.add(p['phone'].toString());
            }
          }
        }
      }
    } catch (e) {
      log('check_phone hatasi: $e');
    }
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    // zaten kayıtlı olanları ayır
    final toAdd = <Contact>[];
    final existingNames = <String>[];
    for (final c in selected) {
      final p = _normalizePhone(c.phones.first.number);
      if (existingPhones.contains(p)) {
        existingNames.add(c.displayName);
      } else {
        toAdd.add(c);
      }
    }

    if (toAdd.isEmpty) {
      await showPremiumWarning(
        context,
        title: 'Tüm kişiler zaten kayıtlı',
        message:
            'Seçtiğin ${selected.length} kişinin hepsi sistemde mevcut. Yeni ekleme yapılmadı.',
        tone: 'warning',
      );
      setState(() {
        _selectedIds.clear();
      });
      return;
    }

    // toplu kaydetme: ilerleme dialog'u
    final progressNotifier = ValueNotifier<int>(0);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _BulkProgressDialog(
        primary: primary,
        total: toAdd.length,
        progressNotifier: progressNotifier,
      ),
    );

    int success = 0;
    int failed = 0;
    for (final c in toAdd) {
      try {
        final ok = await _kaydet(
          _seciliisletme!,
          c.displayName,
          _phoneForSave(c.phones.first.number),
        );
        if (ok) {
          success++;
        } else {
          failed++;
        }
      } catch (e) {
        failed++;
        log('toplu ekleme hata: $e');
      }
      progressNotifier.value++;
    }

    progressNotifier.dispose();
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    // özet
    await _showSummary(
      success: success,
      failed: failed,
      existingNames: existingNames,
    );

    if (!mounted) return;
    // başarı varsa müşteri listesine dön
    if (success > 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MusteriListesi(
            kullanicirolu: widget.kullanicirolu,
            isletmebilgi: widget.isletmebilgi,
          ),
        ),
      );
    } else {
      setState(() {
        _selectedIds.clear();
      });
    }
  }

  Future<bool> _kaydet(String salonid, String isim, String telefon) async {
    final formData = {
      'ad_soyad': isim,
      'telefon': telefon,
      'musteri_id': '',
    };
    final response = await http.post(
      Uri.parse(
          'https://apptest.randevumcepte.com.tr/api/v1/musteriekleguncelle/$salonid'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(formData),
    );
    if (response.statusCode != 200) return false;
    if (response.body.trim().isEmpty) return false;
    try {
      final data = json.decode(response.body);
      if (data is Map && data['status'] == 'warning') {
        return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _showSummary({
    required int success,
    required int failed,
    required List<String> existingNames,
  }) async {
    final scheme = Theme.of(context).colorScheme;
    final primary = scheme.primary;
    await showDialog(
      context: context,
      builder: (_) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (success > 0 ? primary : Colors.orange)
                      .withValues(alpha: 0.12),
                ),
                child: Icon(
                  success > 0
                      ? Icons.check_circle_rounded
                      : Icons.info_outline_rounded,
                  size: 36,
                  color: success > 0 ? primary : Colors.orange,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                success > 0 ? 'Ekleme tamamlandı' : 'Sonuç',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 16),
              _summaryRow(
                  Icons.check_circle_outline_rounded,
                  '$success yeni müşteri eklendi',
                  const Color(0xFF4CAF50)),
              if (existingNames.isNotEmpty) ...[
                const SizedBox(height: 8),
                _summaryRow(
                    Icons.person_off_outlined,
                    '${existingNames.length} kişi zaten kayıtlı (atlandı)',
                    Colors.orange[700]!),
              ],
              if (failed > 0) ...[
                const SizedBox(height: 8),
                _summaryRow(
                    Icons.error_outline_rounded,
                    '$failed ekleme başarısız',
                    Colors.red[600]!),
              ],
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: Material(
                  color: primary,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      height: 46,
                      alignment: Alignment.center,
                      child: const Text(
                        'Tamam',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final primary = scheme.primary;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Color.alphaBlend(primary.withValues(alpha: 0.36), Colors.white),
            Color.alphaBlend(
                scheme.tertiary.withValues(alpha: 0.08), Colors.white),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          centerTitle: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 72,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: primary, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Rehberden Ekle',
            style: TextStyle(
              color: scheme.onSurface,
              fontWeight: FontWeight.w800,
              fontSize: 22,
              letterSpacing: -0.3,
            ),
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: primary,
                    strokeWidth: 2.5,
                  ),
                )
              : Column(
                  children: [
                    const SizedBox(height: 12),
                    _buildSearch(primary),
                    _buildTopBar(primary),
                    Expanded(child: _buildList(primary)),
                  ],
                ),
        ),
        bottomNavigationBar: _isLoading ? null : _buildBottomBar(primary),
      ),
    );
  }

  Widget _buildSearch(Color primary) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey[200]!, width: 1),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: 'İsim veya telefon ile ara',
            hintStyle: TextStyle(
              color: Colors.grey[500],
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon:
                Icon(Icons.search_rounded, color: primary, size: 22),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.close_rounded,
                        size: 18, color: Colors.grey[600]),
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(Color primary) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.people_rounded, size: 14, color: primary),
                const SizedBox(width: 6),
                Text(
                  '${_selectedIds.length} / ${_contacts.length} seçili',
                  style: TextStyle(
                    color: primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap:
                _filteredContacts.isEmpty ? null : _toggleSelectAllFiltered,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: _allFilteredSelected
                    ? primary
                    : primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _allFilteredSelected
                      ? primary
                      : primary.withValues(alpha: 0.3),
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _allFilteredSelected
                        ? Icons.check_box_rounded
                        : Icons.check_box_outline_blank_rounded,
                    size: 16,
                    color:
                        _allFilteredSelected ? Colors.white : primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _allFilteredSelected ? 'Tümünü kaldır' : 'Tümünü seç',
                    style: TextStyle(
                      color: _allFilteredSelected
                          ? Colors.white
                          : primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                      letterSpacing: -0.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(Color primary) {
    if (_filteredContacts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.contacts_outlined,
                    size: 42, color: primary),
              ),
              const SizedBox(height: 14),
              const Text(
                'Kişi bulunamadı',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _searchQuery.isEmpty
                    ? 'Rehberinde telefon numarası olan kişi yok.'
                    : 'Aramaya uyan sonuç yok.',
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

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      itemCount: _filteredContacts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) => _buildCard(_filteredContacts[i], primary),
    );
  }

  Widget _buildCard(Contact c, Color primary) {
    final selected = _selectedIds.contains(c.id);
    final phone = c.phones.isNotEmpty ? c.phones.first.number : '';
    final name = c.displayName.isEmpty ? '-' : c.displayName;
    final initials = _getInitials(name);

    return Material(
      color: selected ? primary.withValues(alpha: 0.06) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _toggleSelection(c),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? primary.withValues(alpha: 0.4)
                  : Colors.grey[200]!,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primary.withValues(alpha: 0.12),
                  border: Border.all(
                    color: primary.withValues(alpha: 0.18),
                    width: 1.2,
                  ),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (phone.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.phone_rounded,
                              size: 12, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              phone,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: selected ? primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selected ? primary : Colors.grey[400]!,
                    width: 1.6,
                  ),
                ),
                child: selected
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 17)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(Color primary) {
    final count = _selectedIds.length;
    final enabled = count > 0;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Material(
          color: enabled ? primary : Colors.grey[300],
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: enabled ? _handleSelection : null,
            child: Container(
              height: 52,
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.group_add_rounded,
                    color: enabled ? Colors.white : Colors.grey[600],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    enabled
                        ? 'Seçilenleri Ekle ($count)'
                        : 'Kişi seçin',
                    style: TextStyle(
                      color: enabled ? Colors.white : Colors.grey[600],
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _LoadingDialog extends StatelessWidget {
  final Color primary;
  final String text;
  const _LoadingDialog({required this.primary, required this.text});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 26),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                color: primary,
                strokeWidth: 2.5,
              ),
            ),
            const SizedBox(width: 14),
            Text(
              text,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BulkProgressDialog extends StatelessWidget {
  final Color primary;
  final int total;
  final ValueNotifier<int> progressNotifier;
  const _BulkProgressDialog({
    required this.primary,
    required this.total,
    required this.progressNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
        child: ValueListenableBuilder<int>(
          valueListenable: progressNotifier,
          builder: (context, value, _) {
            final percent = total == 0 ? 0.0 : value / total;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primary.withValues(alpha: 0.12),
                  ),
                  child: Icon(Icons.group_add_rounded,
                      size: 30, color: primary),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Müşteriler ekleniyor',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15.5,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$value / $total',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: percent,
                    minHeight: 8,
                    backgroundColor: primary.withValues(alpha: 0.10),
                    valueColor: AlwaysStoppedAnimation<Color>(primary),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../Backend/backend.dart';
import 'musteriliste.dart';
import 'yeni_musteri.dart';

class ContactSelectionPage extends StatefulWidget {
  final dynamic isletmebilgi;
  final int kullanicirolu;
  const ContactSelectionPage({Key? key, required this.isletmebilgi,required this.kullanicirolu}) : super(key: key);

  @override
  _ContactSelectionPageState createState() => _ContactSelectionPageState();
}

class _ContactSelectionPageState extends State<ContactSelectionPage> {
  late String seciliisletme;
  List<Contact> _contacts = [];
  List<Contact> _filteredContacts = [];
  List<Contact> _selectedContacts = [];
  TextEditingController _searchController = TextEditingController();
  bool isLoading = true;
  bool allSelected = false;
  bool isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadContacts();
    initialize();
  }

  Future<void> _loadContacts() async {
    setState(() {
      isLoading = true;
    });

    // Rehber izni isteme
    if (await Permission.contacts.request().isGranted) {
      // flutter_contacts kullanarak rehber verilerini alıyoruz
      final contacts = await FlutterContacts.getContacts(withThumbnail: false);
      setState(() {
        _contacts = contacts;
        _filteredContacts = _contacts;
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Rehber erişim izni reddedildi!"))
      );
    }
  }

  Future<void> initialize() async {
    seciliisletme = (await secilisalonid())!;
  }

  void _toggleSelection(Contact contact) {
    setState(() {
      if (_selectedContacts.contains(contact)) {
        _selectedContacts.remove(contact);
      } else {
        _selectedContacts.add(contact);
      }
      allSelected = _selectedContacts.length == _filteredContacts.length;
    });
  }

  void _toggleSelectAll(bool? value) {
    setState(() {
      allSelected = value ?? false;
      _selectedContacts = allSelected ? List.from(_filteredContacts) : [];
    });
  }

  // Telefon numarasını formatlama fonksiyonu
  String formatPhoneNumber(String phoneNumber) {
    return phoneNumber.replaceAll(RegExp(r'\D'), ''); // Tüm harf ve semboller silinir.
  }

  void _handleSelection() async {
    if (_selectedContacts.isNotEmpty) {
      List<String> phoneNumbers = _selectedContacts.map((contact) {
        String phone = contact.phones.isNotEmpty ? contact.phones.first.number : "";
        return formatPhoneNumber(phone); // Telefon numarasını formatla
      }).toList();

      final response = await http.post(
        Uri.parse('https://app.randevumcepte.com.tr/api/v1/check_phone'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phones': phoneNumbers}),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        print('API Response: $data');

        List<String> existingUsers = [];

        // **Birden fazla telefon için döngü**
        for (var phoneData in data['phones']) {
          if (phoneData['exists']) {
            for (var user in phoneData['users']) {
              existingUsers.add("${user['name']} (${user['system']})"); // Kullanıcıları listele
            }
          }
        }

        if (existingUsers.isNotEmpty) {
          _showExistingUsersDialog(existingUsers); // **Popup çağrıldı**
        } else {
          // **Sistemde kayıtlı kullanıcı yoksa yeni müşterileri ekleyelim**
          for (var selectedContact in _selectedContacts) {
            String isim = selectedContact.displayName ?? "";
            String telefon = selectedContact.phones.isNotEmpty ? selectedContact.phones.first.number : "";

            // Yeni müşteri ekleme fonksiyonunu çağır
            submitForm(widget.isletmebilgi, "", seciliisletme, isim, telefon, context);
          }
        }
      } else {
        print('Error: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Telefon numarası kontrolü sırasında bir hata oluştu.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hiç müşteri seçilmedi!")),
      );
    }
  }

  void _showExistingUsersDialog(List<String> users) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Sistemde Kayıtlı Kullanıcılar"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: users.map((user) => Text(user)).toList(), // Kullanıcıları listele
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Popup'ı kapat
              },
              child: Text("Tamam"),
            ),
          ],
        );
      },
    );
  }

  void _filterContacts(String query) {
    setState(() {
      _filteredContacts = _contacts
          .where((contact) =>
      contact.displayName != null &&
          contact.displayName!.toLowerCase().contains(query.toLowerCase()))
          .toList();
      allSelected = _selectedContacts.length == _filteredContacts.length;
    });
  }

  void _toggleSearch() {
    setState(() {
      isSearching = !isSearching;
      if (!isSearching) {
        _searchController.clear();
        _filteredContacts = _contacts;
      }
    });
  }

  void _selectAll() {
    setState(() {
      if (_selectedContacts.length == _filteredContacts.length) {
        _selectedContacts.clear();
      } else {
        _selectedContacts = List.from(_filteredContacts);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seçilen Kişileri Ekle', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.done, color: Colors.deepPurple),
            onPressed: _handleSelection,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0, top: 8, right: 16, left: 8),
            child: Row(
              children: [
                Expanded(
                  child: isSearching
                      ? TextField(
                    controller: _searchController,
                    onChanged: _filterContacts,
                    decoration: InputDecoration(
                      hintText: 'Kişi Ara...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        borderSide: BorderSide.none,
                      ),
                      fillColor: Colors.grey[200],
                      filled: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                      prefixIcon: Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.close),
                        onPressed: _toggleSearch,
                      ),
                    ),
                  )
                      : Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: Icon(Icons.search, size: 28),
                      onPressed: _toggleSearch,
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    IconButton(
                      icon: Icon(
                        _selectedContacts.length == _filteredContacts.length
                            ? Icons.check_box
                            : Icons.check_box_outline_blank,
                        color: Colors.deepPurple,
                      ),
                      onPressed: _selectAll,
                    ),
                    Text(
                      _selectedContacts.length.toString(),
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
              itemCount: _filteredContacts.length,
              itemBuilder: (context, index) {
                final contact = _filteredContacts[index];
                return ListTile(
                  title: Text(contact.displayName ?? ""),
                  subtitle: contact.phones.isNotEmpty
                      ? Text(contact.phones.first.number)
                      : null,
                  leading: Icon(Icons.person),
                  trailing: Icon(
                    _selectedContacts.contains(contact)
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                    color: Colors.deepPurple,
                  ),
                  onTap: () => _toggleSelection(contact),
                );
              },
            ),
          ),
        ],
      ),
    );
  }



Future<void> submitForm(dynamic isletmebilgi, String musteri_id, String salonid, String musteriad, String telefon, context) async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();

    Map<String, dynamic> formData = {
      'ad_soyad': musteriad,
      'telefon': telefon,
      'musteri_id': musteri_id
    };

    final response = await http.post(
      Uri.parse('https://app.randevumcepte.com.tr/api/v1/musteriekleguncelle/' + salonid.toString()),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(formData),
    );

    log('Response status: ${response.statusCode}');
    log('Response body: ${response.body}');

    if (response.statusCode == 200) {
      if (response.body.isNotEmpty) {
        var responseData = json.decode(response.body);
        if (responseData['status'] == 'warning') {
          // Müşteri zaten var, popup göster
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text(responseData['title']),
                content: Text(responseData['mesaj']),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('Tamam'),
                  ),
                ],
              );
            },
          );
        } else {
          log('müşteri ekleme : ' + response.body);
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => MusteriListesi(kullanicirolu: widget.kullanicirolu, isletmebilgi: isletmebilgi)));
        }
      }
    } else {
      print('Hata: ${response.statusCode}');
    }
  }
}
import 'dart:convert';


import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:randevu_sistem/musteripaneli/anasayfa/hesapkaldirma.dart';
import 'dart:io';

import 'package:randevu_sistem/yonetici/dashboard/scaffold_layout_builder.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Frontend/cropimage.dart';
import '../../Models/musteri_danisanlar.dart';
import '../../Models/user.dart';

import 'package:http/http.dart' as http;

class MusteriProfilBilgileri extends StatefulWidget {
  final MusteriDanisan kullanici;
  final VoidCallback? onProfileUpdated;

  MusteriProfilBilgileri({Key? key, required this.kullanici, this.onProfileUpdated}) : super(key: key);

  @override
  _ProfilBilgileriPageState createState() => _ProfilBilgileriPageState();
}

enum SingingCharacter { kadin, erkek }

class _ProfilBilgileriPageState extends State<MusteriProfilBilgileri> {
  late TextEditingController _adsoyad;
  late TextEditingController _email;
  late TextEditingController _telefon;
  late TextEditingController _cinsiyet;
  late TextEditingController _unvan;
  late TextEditingController _sifre;

  final _formKey = GlobalKey<FormState>();
  String _selectedGender = '';
  bool _isObscure = true;
  File? _profileImage;
  String? _currentProfileImageUrl;
  bool _isLoading = false;
  int _imageVersion = 0; // Cache busting için

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _currentProfileImageUrl = widget.kullanici.profil_resim;
    _loadCurrentUserData(); // Sayfa açıldığında güncel verileri yükle
  }

  void _initializeControllers() {
    _adsoyad = TextEditingController(text: widget.kullanici.name != 'null' ? widget.kullanici.name : '');
    _email = TextEditingController(text: widget.kullanici.email != 'null' ? widget.kullanici.email : '');
    _telefon = TextEditingController(text: widget.kullanici.cep_telefon != 'null' ? widget.kullanici.cep_telefon : '');
    _unvan = TextEditingController(text: widget.kullanici.meslek != 'null' ? widget.kullanici.meslek : '');
    _cinsiyet = TextEditingController(text: widget.kullanici.cinsiyet);
    _sifre = TextEditingController(text: '');

    if (widget.kullanici.cinsiyet == '0') {
      _selectedGender = 'kadin';
    } else if (widget.kullanici.cinsiyet == '1') {
      _selectedGender = 'erkek';
    } else {
      _selectedGender = '';
    }
  }

  // Sayfa açıldığında güncel kullanıcı verilerini yükle
  Future<void> _loadCurrentUserData() async {
    try {
      SharedPreferences localStorage = await SharedPreferences.getInstance();
      var user = jsonDecode(localStorage.getString('musteri')!);

      final response = await http.get(
        Uri.parse('https://app.randevumcepte.com.tr/api/v1/musteri/${user["id"]}'),
      );

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);

        // Local storage'ı güncelle
        localStorage.setString('musteri', jsonEncode(responseData));

        // State'i güncelle
        setState(() {
          _currentProfileImageUrl = responseData['profil_resim'];
          _adsoyad.text = responseData['name'] ?? '';
          _email.text = responseData['email'] ?? '';
          _telefon.text = responseData['cep_telefon'] ?? '';
          _unvan.text = responseData['meslek'] ?? '';

          if (responseData['cinsiyet'] == '0') {
            _selectedGender = 'kadin';
          } else if (responseData['cinsiyet'] == '1') {
            _selectedGender = 'erkek';
          } else {
            _selectedGender = '';
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading current user data: $e');
    }
  }

  Future<void> _refreshUserData() async {
    try {
      SharedPreferences localStorage = await SharedPreferences.getInstance();
      var user = jsonDecode(localStorage.getString('musteri')!);

      final response = await http.get(
        Uri.parse('https://app.randevumcepte.com.tr/api/v1/musteri/${user["id"]}'),
      );

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);

        // Local storage'ı güncelle
        localStorage.setString('musteri', jsonEncode(responseData));

        // State'i güncelle ve cache'i temizle
        setState(() {
          _currentProfileImageUrl = responseData['profil_resim'];
          _imageVersion++; // Cache busting
        });

        // Parent widget'a bildir
        widget.onProfileUpdated?.call();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profil bilgileri güncellendi!')),
        );
      }
    } catch (e) {
      debugPrint('Error refreshing user data: $e');
    }
  }

  Future<void> pickAndCropImage() async {
    // İzin kontrolü
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.photos,
    ].request();

    if (statuses[Permission.photos]!.isGranted || statuses[Permission.camera]!.isGranted) {
      final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);

      if (pickedFile == null) return;

      final croppedFile = await Navigator.push<File>(
        context,
        MaterialPageRoute(builder: (_) => CropScreen(imageFile: File(pickedFile.path))),
      );

      if (croppedFile != null) {
        setState(() {
          _profileImage = croppedFile;
          _isLoading = true;
        });
        await uploadImage(croppedFile);
      }
    }
  }



  Future<void> uploadImage(File image) async {
    try {
      SharedPreferences localStorage = await SharedPreferences.getInstance();
      var user = jsonDecode(localStorage.getString('musteri')!);

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://app.randevumcepte.com.tr/api/v1/musteriprofilresimyukle'),
      );

      request.fields['yetkili_id'] = user["id"].toString();
      request.files.add(await http.MultipartFile.fromPath('folderPath', image.path));

      var response = await request.send();

      if (response.statusCode == 200) {
        var responseData = await http.Response.fromStream(response);
        var responseBody = jsonDecode(responseData.body);

        String newProfileImageUrl = responseBody['profilresmi'] ?? '';

        // Local storage'ı güncelle
        user['profil_resim'] = newProfileImageUrl;
        await localStorage.setString('musteri', jsonEncode(user));

        // UI'ı hemen güncelle ve cache'i temizle
        setState(() {
          _currentProfileImageUrl = newProfileImageUrl;
          _profileImage = null;
          _imageVersion++; // Cache busting için version değiştir
          _isLoading = false;
        });

        // Sunucudan güncel verileri çek
        await _refreshUserData();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profil resmi başarıyla güncellendi!')),
        );
      } else {
        var responseData = await http.Response.fromStream(response);
        debugPrint('Upload error: ${response.statusCode}, Body: ${responseData.body}');
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profil resmi güncellenirken hata oluştu!')),
        );
      }
    } catch (e) {
      debugPrint('Exception: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profil resmi güncellenirken bir hata oluştu!')),
      );
    }
  }

  // Cache busting ile profil resmi URL'si oluştur
  String _getProfileImageUrl() {
    if (_currentProfileImageUrl == null || _currentProfileImageUrl!.isEmpty) {
      return '';
    }

    String baseUrl = 'https://app.randevumcepte.com.tr$_currentProfileImageUrl';

    // Cache busting için timestamp veya version ekle
    if (_imageVersion > 0) {
      return '$baseUrl?v=$_imageVersion';
    }

    return '$baseUrl?t=${DateTime.now().millisecondsSinceEpoch}';
  }

  ImageProvider? _getProfileImage() {
    // Önce local'deki güncellenmiş resmi göster
    if (_profileImage != null) {
      return FileImage(_profileImage!);
    }

    // Sonra cache busting ile network resmi göster
    if (_currentProfileImageUrl != null && _currentProfileImageUrl!.isNotEmpty) {
      String imageUrl = _getProfileImageUrl();
      debugPrint('Loading profile image from: $imageUrl');
      return NetworkImage(imageUrl);
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus(); // Hide the keyboard
      },      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Color(0xFFF5F5F5),
        body: SingleChildScrollView(
          child: ScaffoldLayoutBuilder(
            backgroundColorAppBar: const ColorBuilder(Colors.transparent, Color(0xFF6A1B9A)),
            textColorAppBar: const ColorBuilder(Colors.white),
            appBarBuilder: _appBar,
            child: SafeArea(
              child: Container(
                width: width,
                height: height,
                child: Center(
                  child: RefreshIndicator(
                    color: Colors.purple[800],
                    backgroundColor: Colors.white,
                    strokeWidth: 3.0,
                    onRefresh: _refreshUserData,
                    child: SingleChildScrollView(
                      physics: BouncingScrollPhysics(parent: ClampingScrollPhysics()),
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              Container(
                                height: 300,
                                width: double.infinity,
                                decoration: const BoxDecoration(
                                    image: DecorationImage(
                                        image: AssetImage('images/randevumcepte.jpg'),
                                        fit: BoxFit.fill
                                    ),
                                    borderRadius: BorderRadius.only(
                                        bottomLeft: Radius.circular(20),
                                        bottomRight: Radius.circular(20)
                                    )
                                ),
                              ),
                              Form(
                                key: _formKey,
                                child: Column(
                                    children: [
                                      SizedBox(height: 65),
                                      Stack(
                                        clipBehavior: Clip.none,
                                        children: <Widget>[
                                          Container(
                                            height: 105,
                                            width: 105,
                                            decoration: BoxDecoration(
                                                color: Colors.purple[800],
                                                borderRadius: BorderRadius.circular(52.5),
                                                boxShadow: [BoxShadow(color: Colors.white, spreadRadius: 3)]
                                            ),
                                            child: _isLoading
                                                ? Center(
                                              child: CircularProgressIndicator(
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                              ),
                                            )
                                                : CircleAvatar(
                                              radius: 50,
                                              backgroundImage: _getProfileImage(),
                                              child: _profileImage == null &&
                                                  (_currentProfileImageUrl == null || _currentProfileImageUrl!.isEmpty)
                                                  ? Icon(
                                                Icons.person,
                                                size: 50,
                                                color: Colors.white,
                                              )
                                                  : null,
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 1,
                                            right: -25,
                                            child: ElevatedButton(
                                              onPressed: _isLoading ? null : pickAndCropImage,
                                              child: Icon(Icons.edit, color: Colors.purple[800]),
                                              style: ElevatedButton.styleFrom(
                                                shape: CircleBorder(),
                                                backgroundColor: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 10),
                                      Text(
                                        _adsoyad.text.isNotEmpty ? _adsoyad.text : widget.kullanici.name,
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 23,
                                            fontWeight: FontWeight.bold
                                        ),
                                      ),
                                      Text(
                                        _telefon.text.isNotEmpty ? _telefon.text : widget.kullanici.cep_telefon,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w400,
                                          fontSize: 14,
                                        ),
                                      ),
                                      SizedBox(height:15),
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => HesapKaldirma(kullanici: widget.kullanici),
                                            ),
                                          );
                                        },
                                        icon: Icon(Icons.delete, size: 24, color: Colors.white),
                                        label: Text('Hesabımı Sil', style: TextStyle(fontSize:12)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                      Container(
                                          width: width,
                                          height: height * 0.9,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              SizedBox(height: 25),
                                              Container(
                                                decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.circular(15),
                                                    color: Colors.white
                                                ),
                                                width: width * 0.9,
                                                height: height * 0.8,
                                                padding: EdgeInsets.all(15),
                                                child: _buildFormContent(),
                                              ),
                                            ],
                                          )
                                      )
                                    ]
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('Ayarlar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple[800])),
        ]),
        _buildTextField('Ad Soyad', _adsoyad, TextInputType.text),
        _buildTextField('E-Posta Adresi', _email, TextInputType.emailAddress),
        _buildTextField('Meslek', _unvan, TextInputType.text),
        _buildTextField('Telefon Numarası', _telefon, TextInputType.phone),
        _buildPasswordField(),
        _buildGenderSelection(),
        SizedBox(height: 5),
        _buildUpdateButton(),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, TextInputType keyboardType) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 5.0),
          child: Text(label, style: TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold)),
        ),
        SizedBox(height: 10),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: _inputDecoration(),
        ),
        SizedBox(height: 10),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 5.0),
          child: Text('Şifre Değiştir', style: TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold)),
        ),
        SizedBox(height: 10),
        TextFormField(
          controller: _sifre,
          obscureText: _isObscure,
          decoration: _inputDecoration(
            suffixIcon: IconButton(
              icon: Icon(_isObscure ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _isObscure = !_isObscure),
            ),
          ),
        ),
        SizedBox(height: 10),
      ],
    );
  }

  Widget _buildGenderSelection() {
    return Row(
      children: [
        Expanded(
          child: ListTile(
            leading: Radio<String>(
              value: 'kadin',
              groupValue: _selectedGender,
              activeColor: Colors.purple[800],
              onChanged: (value) => setState(() {
                _selectedGender = value!;
                _cinsiyet.text = value;
              }),
            ),
            title: Text('Kadın'),
          ),
        ),
        Expanded(
          child: ListTile(
            leading: Radio<String>(
              value: 'erkek',
              groupValue: _selectedGender,
              activeColor: Colors.purple[800],
              onChanged: (value) => setState(() {
                _selectedGender = value!;
                _cinsiyet.text = value;
              }),
            ),
            title: Text('Erkek'),
          ),
        ),
      ],
    );
  }

  Widget _buildUpdateButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();
              await _submitForm(
                _adsoyad.text,
                _email.text,
                _unvan.text,
                _telefon.text,
                _sifre.text,
                _selectedGender == 'kadin' ? '0' : '1',
              );
            }
          },
          child: Text('Bilgileri Güncelle'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({Widget? suffixIcon}) {
    return InputDecoration(
      focusColor: Color(0xFF6A1B9A),
      hoverColor: Color(0xFF6A1B9A),
      hintStyle: TextStyle(color: Color(0xFF6A1B9A)),
      contentPadding: EdgeInsets.all(15.0),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF6A1B9A)),
        borderRadius: BorderRadius.circular(50.0),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(50.0)),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF6A1B9A)),
        borderRadius: BorderRadius.circular(50.0),
      ),
      suffixIcon: suffixIcon,
    );
  }

  Widget _appBar(BuildContext context, ColorAnimated colorAnimated) {
    return AppBar(
      elevation: 10,
      title: Text('Profil Bilgileri', style: TextStyle(color: Colors.white, fontSize: 18)),
      iconTheme: IconThemeData(color: Colors.white),
      toolbarHeight: 60,
      centerTitle: true,
      backgroundColor: colorAnimated.background,
    );
  }

  Future<void> _submitForm(String name, String email, String meslek, String cep_telefon, String password, String cinsiyet) async {
    try {
      SharedPreferences localStorage = await SharedPreferences.getInstance();
      var user = jsonDecode(localStorage.getString('musteri')!);

      Map<String, dynamic> formData = {
        'yetkili_id': user["id"],
        'name': name,
        'email': email,
        'meslek': meslek,
        'cep_telefon': cep_telefon,
        'password': password,
        'cinsiyet': int.parse(cinsiyet),
      };

      final response = await http.post(
        Uri.parse('https://app.randevumcepte.com.tr/api/v1/musteribilgiguncelle'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(formData),
      );

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);
        await localStorage.setString('musteri', jsonEncode(responseData));

        // Verileri yenile
        await _refreshUserData();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profil bilgileriniz başarıyla güncellendi!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Güncelleme sırasında hata oluştu! Hata kodu: ${response.statusCode}')),
        );
        debugPrint('Error: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bir hata oluştu: $e')),
      );
    }
  }
}

class HexColor extends Color {
  static int _getColor(String hex) {
    String formattedHex = "FF" + hex.toUpperCase().replaceAll("#", "");
    return int.parse(formattedHex, radix: 16);
  }
  HexColor(final String hex) : super(_getColor(hex));
}

class ListCard extends StatelessWidget {
  const ListCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        itemCount: 6,
        itemBuilder: (BuildContext context, int index) {
          return ListTile(
            leading: Icon(Icons.edit_note_outlined),
            title: Text('Not 1'),
            subtitle: Text(
              'ferdi korkmaz hatırlatma arama yapılacak',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Icon(Icons.chevron_right),
            onTap: () {},
          );
        }
    );
  }
}
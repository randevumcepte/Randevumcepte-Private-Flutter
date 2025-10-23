import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:randevu_sistem/yonetici/dashboard/scaffold_layout_builder.dart';
import 'package:shared_preferences/shared_preferences.dart';


import '../../Frontend/cropimage.dart';
import '../../Models/user.dart';

import 'package:http/http.dart' as http;

import '../../musteripaneli/anasayfa/hesapkaldirma.dart';
import 'hesapkaldirmaisletme.dart';



class ProfilBilgileri extends StatefulWidget {

  final Kullanici kullanici;
  ProfilBilgileri({Key? key,required this.kullanici}) : super(key: key);
  @override
  _ProfilBilgileriPageState createState() => _ProfilBilgileriPageState();
}
enum SingingCharacter { kadin, erkek }
class _ProfilBilgileriPageState extends State<ProfilBilgileri> {

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
  void initState() {
    super.initState();
    _adsoyad = TextEditingController(text:widget.kullanici.name);
    _email = TextEditingController(text:widget.kullanici.email);
    _telefon=  TextEditingController(text:widget.kullanici.gsm1);
    _unvan = TextEditingController(text:widget.kullanici.unvan);


    _cinsiyet = TextEditingController(text:widget.kullanici.cinsiyet);
    _sifre = TextEditingController(text:'');

    if (widget.kullanici.cinsiyet == '0') {
      _selectedGender = 'kadin';
    } else if (widget.kullanici.cinsiyet == '1') {
      _selectedGender = 'erkek';
    }




  }
  Future<void> requestCameraAndGalleryPermission() async {


    // Permission denied, show a message or handle accordingly.
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Kamera ve Galeri İzni'),
        content:
        Text('Profil resmi yüklemek için kamera ve galeri izni gerekmektedir.'),
        actions: <Widget>[
          TextButton(
            child: Text('Vazgeç'),
            onPressed: () {
              Navigator.of(context).pop();

            }
            ,
          ),
          TextButton(
            child: Text('Ayarlar'),
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            }
            ,
          ),
        ],
      ),
    );

  }

  Future<void> pickAndCropImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    final croppedFile = await Navigator.push<File>(
      context,
      MaterialPageRoute(builder: (_) => CropScreen(imageFile: File(pickedFile.path))),
    );

    if (croppedFile != null) {
      setState(() => _profileImage = croppedFile);
      await uploadImage(croppedFile);
    }
  }





  Future<void> uploadImage(File image) async {
    try {
      SharedPreferences localStorage = await SharedPreferences.getInstance();
      var user = jsonDecode(localStorage.getString('user')!);

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://app.randevumcepte.com.tr/api/v1/profilresimyukle'),
      );

      request.fields['yetkili_id'] = user["id"].toString();
      request.files.add(await http.MultipartFile.fromPath('folderPath', image.path));

      var response = await request.send();

      if (response.statusCode == 200) {
        var responseData = await http.Response.fromStream(response);
        var responseBody = jsonDecode(responseData.body);

        String newProfileImageUrl = responseBody['profilresmi'] ?? '';
        user['profil_resim'] = newProfileImageUrl;
        localStorage.setString('user', jsonEncode(user));

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profil resmi başarıyla güncellendi!')),
        );
      } else {
        var responseData = await http.Response.fromStream(response);
        debugPrint('Upload error: ${response.statusCode}, Body: ${responseData.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profil resmi güncellenirken hata oluştu!')),
        );
      }
    } catch (e) {
      debugPrint('Exception: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profil resmi güncellenirken bir istisna oluştu!')),
      );
    }
  }
    @override
  Widget build(BuildContext context) {

    SingingCharacter? _character = SingingCharacter.kadin;

    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;


    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Color(0xFFF5F5F5),

      body:SingleChildScrollView(
        child: ScaffoldLayoutBuilder(
          backgroundColorAppBar:
          const ColorBuilder(Colors.transparent, Color(0xFF6A1B9A)),
          textColorAppBar: const ColorBuilder(Colors.white),
          appBarBuilder: _appBar,
          child: SafeArea(
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: Center(
                child: RefreshIndicator(
                  color: Colors.purple[800],
                  backgroundColor: Colors.white,
                  strokeWidth: 3.0,
                  onRefresh: () async {
                    // Replace this delay with the code to be executed during refresh
                    // and return a Future when code finishes execution.
                    return Future<void>.delayed(const Duration(seconds: 1));
                  },
                  child: SingleChildScrollView(

                    scrollDirection: Axis.vertical,
                    physics: BouncingScrollPhysics(
                        parent: ClampingScrollPhysics()
                    ),

                    child:
                    Column(

                      children: [

                        Stack(
                          children: [
                            Container(
                              height: 300,
                              width: double.infinity,
                              decoration: const BoxDecoration(
                                  image: DecorationImage(image: AssetImage('images/randevumcepte.jpg'),fit: BoxFit.fill),
                                  borderRadius: BorderRadius.only(

                                      bottomLeft: Radius.circular(20),
                                      bottomRight: Radius.circular(20)
                                  )),
                            ),

                            Form(
                              key: _formKey,
                              child: Column(

                                  children: [
                                    SizedBox(height: 65,),


                                    Stack(
                                      clipBehavior: Clip.none,

                                      children: <Widget>[


                                        Container(

                                          height: 105,
                                          width: 105,
                                          decoration: BoxDecoration(
                                              color: Colors.purple[800],

                                              borderRadius: BorderRadius.circular(52.5),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.white,
                                                  spreadRadius:3,
                                                )
                                              ]

                                          ),

                                          child: CircleAvatar(
                                            radius: 50,
                                            backgroundImage: _profileImage != null
                                                ? FileImage(_profileImage!)  // Use FileImage if _profileImage is not null
                                                : widget.kullanici.profil_resim != null
                                                ? NetworkImage('https://app.randevumcepte.com.tr' + widget.kullanici.profil_resim) as ImageProvider
                                                : NetworkImage('https://app.randevumcepte.com.tr' + widget.kullanici.profil_resim),
                                            child: _profileImage == null && widget.kullanici.profil_resim == null
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
                                          child:ElevatedButton(
                                            onPressed: () async {

                                              await pickAndCropImage();
                                            },
                                            child: Icon(Icons.edit,color: Colors.purple[800],),
                                            style: ElevatedButton.styleFrom(
                                              shape: CircleBorder(),
                                              backgroundColor: Colors.white,
                                            ),
                                          ), ),




                                      ],
                                    ),

                                    SizedBox(height: 10,),
                                    Text(widget.kullanici.name, style: TextStyle(color: Colors.white,fontSize: 23, fontWeight: FontWeight.bold  ),),

                                    Text(widget.kullanici.gsm1, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w400,fontSize: 16,),),
                                    SizedBox(height:15),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) => HesapKaldirmaIsletme(kullanici: widget.kullanici)),
                                        );

                                      },
                                      icon: Icon(
                                        Icons.delete,          // Silme ikonu
                                        size: 24,               // İkon boyutu
                                        color: Colors.white,    // İkon rengi
                                      ),
                                      label: Text('Hesabımı Sil', style:TextStyle(fontSize:12)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor:Colors.white,
                                      ),
                                    ),
                                    Container(
                                        width: MediaQuery.of(context).size.width,
                                        height: MediaQuery.of(context).size.height*0.9,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            SizedBox(height: 25,),
                                            Container(
                                                decoration: const BoxDecoration(
                                                    borderRadius: BorderRadius.only(
                                                        topLeft: Radius.circular(15),
                                                        topRight: Radius.circular(15),
                                                        bottomLeft: Radius.circular(15),
                                                        bottomRight: Radius.circular(15)
                                                    ),
                                                    color: Colors.white),
                                                width: width* 0.9,
                                                height: height*0.8,
                                                padding: EdgeInsets.all( 15),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [

                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [

                                                        Text('Ayarlar',style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold,color: Colors.purple[800]),),

                                                      ],
                                                    ),
                                                    Padding(
                                                      padding: const EdgeInsets.only(left: 5.0),
                                                      child: Text('Ad Soyad',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                                                    ),
                                                    SizedBox(height: 10,),
                                                    TextFormField(
                                                      controller: _adsoyad,
                                                      onSaved: (value) {
                                                        _adsoyad.text = value!;
                                                      },
                                                      keyboardType: TextInputType.text,



                                                      decoration: InputDecoration(

                                                        focusColor:Color(0xFF6A1B9A) ,
                                                        hoverColor: Color(0xFF6A1B9A) ,
                                                        hintStyle: TextStyle(color:  Color(0xFF6A1B9A)),
                                                        contentPadding:  EdgeInsets.all(15.0),
                                                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(
                                                            color: Color(0xFF6A1B9A)),borderRadius: BorderRadius.circular(50.0),),
                                                        border:
                                                        OutlineInputBorder(borderRadius: BorderRadius.circular(50.0),),
                                                        focusedBorder: OutlineInputBorder(
                                                          borderSide: BorderSide(color: Color(0xFF6A1B9A),), borderRadius: BorderRadius.circular(50.0),
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(height: 10,),
                                                    Padding(
                                                      padding: const EdgeInsets.only(left: 5.0),
                                                      child: Text('E-Posta Adresi',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                                                    ),
                                                    SizedBox(height: 10,),
                                                    TextFormField(

                                                      keyboardType: TextInputType.text,

                                                      controller: _email,
                                                      onSaved: (value) {
                                                        _email.text = value!;
                                                      },
                                                      decoration: InputDecoration(

                                                        focusColor:Color(0xFF6A1B9A) ,
                                                        hoverColor: Color(0xFF6A1B9A) ,
                                                        hintStyle: TextStyle(color:  Color(0xFF6A1B9A)),
                                                        contentPadding:  EdgeInsets.all(15.0),
                                                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(
                                                            color: Color(0xFF6A1B9A)),borderRadius: BorderRadius.circular(50.0),),
                                                        border:
                                                        OutlineInputBorder(borderRadius: BorderRadius.circular(50.0),),
                                                        focusedBorder: OutlineInputBorder(
                                                          borderSide: BorderSide(color: Color(0xFF6A1B9A),), borderRadius: BorderRadius.circular(50.0),
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(height: 10,),
                                                    Padding(
                                                      padding: const EdgeInsets.only(left: 5.0),
                                                      child: Text('Unvan',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                                                    ),
                                                    SizedBox(height: 10,),
                                                    TextFormField(

                                                      keyboardType: TextInputType.text,

                                                      controller: _unvan,
                                                      onSaved: (value) {
                                                        _unvan.text = value!;
                                                      },
                                                      decoration: InputDecoration(

                                                        focusColor:Color(0xFF6A1B9A) ,
                                                        hoverColor: Color(0xFF6A1B9A) ,
                                                        hintStyle: TextStyle(color:  Color(0xFF6A1B9A)),
                                                        contentPadding:  EdgeInsets.all(15.0),
                                                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(
                                                            color: Color(0xFF6A1B9A)),borderRadius: BorderRadius.circular(50.0),),
                                                        border:
                                                        OutlineInputBorder(borderRadius: BorderRadius.circular(50.0),),
                                                        focusedBorder: OutlineInputBorder(
                                                          borderSide: BorderSide(color: Color(0xFF6A1B9A),), borderRadius: BorderRadius.circular(50.0),
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(height: 10,),
                                                    Padding(
                                                      padding: const EdgeInsets.only(left: 5.0),
                                                      child: Text('Telefon Numarası',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                                                    ),
                                                    SizedBox(height: 10,),
                                                    TextFormField(
                                                      controller: _telefon,
                                                      onSaved: (value) {
                                                        _telefon.text = value!;
                                                      },
                                                      keyboardType: TextInputType.phone,


                                                      decoration: InputDecoration(

                                                        focusColor:Color(0xFF6A1B9A) ,
                                                        hoverColor: Color(0xFF6A1B9A) ,
                                                        hintStyle: TextStyle(color:  Color(0xFF6A1B9A)),
                                                        contentPadding:  EdgeInsets.all(15.0),
                                                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(
                                                            color: Color(0xFF6A1B9A)),borderRadius: BorderRadius.circular(50.0),),
                                                        border:
                                                        OutlineInputBorder(borderRadius: BorderRadius.circular(50.0),),
                                                        focusedBorder: OutlineInputBorder(
                                                          borderSide: BorderSide(color: Color(0xFF6A1B9A),), borderRadius: BorderRadius.circular(50.0),
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(height: 10,),
                                                    Padding(
                                                      padding: const EdgeInsets.only(left: 5.0),
                                                      child: Text('Şifre Değiştir',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                                                    ),
                                                    SizedBox(height: 10,),
                                                    TextFormField(
                                                      controller: _sifre,
                                                      onSaved: (value) {
                                                        _sifre.text = value!;
                                                      },
                                                      keyboardType: TextInputType.text,

                                                      obscureText: _isObscure,
                                                      decoration: InputDecoration(
                                                        suffixIcon: IconButton(
                                                            icon: Icon(
                                                                _isObscure ? Icons.visibility_off : Icons.visibility),
                                                            onPressed: () {
                                                              setState(() {
                                                                _isObscure = !_isObscure;
                                                              });
                                                            }),


                                                        focusColor:Color(0xFF6A1B9A) ,
                                                        hoverColor: Color(0xFF6A1B9A) ,
                                                        hintStyle: TextStyle(color:  Color(0xFF6A1B9A)),
                                                        contentPadding:  EdgeInsets.all(15.0),
                                                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(
                                                            color: Color(0xFF6A1B9A)),borderRadius: BorderRadius.circular(50.0),),
                                                        border:
                                                        OutlineInputBorder(borderRadius: BorderRadius.circular(50.0),),
                                                        focusedBorder: OutlineInputBorder(
                                                          borderSide: BorderSide(color: Color(0xFF6A1B9A),), borderRadius: BorderRadius.circular(50.0),
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(height: 10,),
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: ListTile(
                                                            leading: Radio<String>(
                                                              value: 'kadin',
                                                              groupValue: _selectedGender,
                                                              activeColor: Colors.purple[800],
                                                              onChanged: (value) {
                                                                setState(() {
                                                                  _selectedGender = value!;
                                                                  _cinsiyet.text = value!;
                                                                });
                                                              },
                                                            ),
                                                            title: const Text('Kadın'),
                                                          ),
                                                        ),
                                                        Expanded(
                                                          child: ListTile(
                                                            leading: Radio<String>(
                                                              value: 'erkek',
                                                              groupValue: _selectedGender,
                                                              activeColor: Colors.purple[800],
                                                              onChanged: (value) {
                                                                setState(() {
                                                                  _selectedGender = value!;
                                                                  _cinsiyet.text = value!;
                                                                });
                                                              },
                                                            ),
                                                            title: const Text('Erkek'),
                                                          ),
                                                        ),

                                                      ],
                                                    ),
                                                    SizedBox(height: 5,),
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        ElevatedButton(onPressed: () async {
                                                          if (_formKey.currentState!.validate()) {
                                                            _formKey
                                                                .currentState!
                                                                .save();
                                                            await submitForm(
                                                              context,
                                                              _adsoyad.text,
                                                              _email.text,
                                                              _unvan.text,
                                                              _telefon.text,
                                                              _sifre.text,
                                                              _selectedGender ==
                                                                  'kadin'
                                                                  ? '0'
                                                                  : '1',

                                                            );
                                                          }
                                                        },
                                                          child: Text('Bilgileri Güncelle'),
                                                          style: ElevatedButton.styleFrom(
                                                              backgroundColor: Colors.green
                                                          ),
                                                        ),
                                                      ],
                                                    )







                                                  ],
                                                )
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
    );
  }






  Widget _appBar(BuildContext context, ColorAnimated colorAnimated) {
    return  AppBar(
        elevation: 10,
        title:


        Text('Profil Bilgileri',style: (TextStyle(color: Colors.white,fontSize:18)),),

        iconTheme: IconThemeData(color: Colors.white),
        toolbarHeight: 60,
        centerTitle: true,



        backgroundColor:colorAnimated.background


    );
  }




}

class HexColor extends Color {
  static int _getColor(String hex) {
    String formattedHex =  "FF" + hex.toUpperCase().replaceAll("#", "");
    return int.parse(formattedHex, radix: 16);
  }
  HexColor(final String hex) : super(_getColor(hex));
}
class ListCard extends StatelessWidget{
  const ListCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context){
    return ListView.builder(
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        itemCount: 6,
        itemBuilder: (BuildContext context, int index){
          return  ListTile(
            leading: Icon(Icons.edit_note_outlined),
            title: Text('Not 1'),
            subtitle: Text('ferdi korkmaz hatırlatma arama yapılacak',maxLines: 1,overflow: TextOverflow.ellipsis,    //add this to set (...) at the end of sentence
            ),
            trailing: Icon(Icons.chevron_right),
            onTap: (){},


          );
        }
    );
  }
}
Future<void> submitForm(context, String name, String email, String unvan, String gsm1, String password, String cinsiyet) async {
  SharedPreferences localStorage = await SharedPreferences.getInstance();
  var user = jsonDecode(localStorage.getString('user')!);

  Map<String, dynamic> formData = {
    'yetkili_id' : user["id"],
    'name': name,
    'email': email,
    'unvan': unvan,
    'gsm1': gsm1,
    'password': password,
    'cinsiyet': int.parse(cinsiyet),
  };

  final response = await http.post(
    Uri.parse('https://app.randevumcepte.com.tr/api/v1/bilgiguncelle'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),
  );

  if (response.statusCode == 200) {
    localStorage.remove('user');
    localStorage.setString('user', json.encode(json.decode(response.body)));

    // Trigger a rebuild to show the updated data


    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Profil bilgileriniz başarıyla güncellendi!'),
      ),
    );

    // You can also call setState to refresh the UI if you're not using any state management
    // setState(() {});

    // If you want to navigate after update
    // Navigator.push(context, MaterialPageRoute(builder: (context) => AjandaNotlar()));
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Profil bilgileriniz kaydedilirken hata oluştu! Hata kodu : ' + response.statusCode.toString()),
      ),
    );
    debugPrint('Error: ${response.body}');
  }
}

import 'dart:convert';
import 'package:page_transition/page_transition.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

import 'package:photo_view/photo_view.dart';
import 'package:http/http.dart' as http;
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../Backend/backend.dart';
import '../../../../Frontend/progressloading.dart';
import '../../../../Models/musteri_danisanlar.dart';
import '../../../../Models/personel.dart';
import 'arsivyonetimipage.dart';

class HariciBelgeEkle extends StatefulWidget {
  final dynamic isletmebilgi;
  HariciBelgeEkle({Key? key,required this.isletmebilgi}) : super(key: key);
  @override
  _HariciBelgeEkleState createState() => _HariciBelgeEkleState();
}
class ImageViewer extends StatelessWidget {
  final File image;
  final VoidCallback onDelete;

  ImageViewer({required this.image, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Resim Görüntüle'),
        backgroundColor:Colors.purple[800] ,
        actions: [
          IconButton(
            onPressed: onDelete,
            icon: Icon(Icons.delete),
          ),
        ],
      ),
      body: Center(
        child: PhotoView(
          imageProvider: FileImage(image),
          minScale: PhotoViewComputedScale.contained * 0.8,
          maxScale: PhotoViewComputedScale.covered * 2,
          backgroundDecoration: BoxDecoration(color: Colors.black),
        ),
      ),
    );
  }
}
class _HariciBelgeEkleState extends State<HariciBelgeEkle> {
  bool _isLoading = false;
  List<File> _images = [];
  late File belge;
  String? _documentName;
  String? _documentExtension;
  late String seciliisletme;
  late List<Personel> personelliste;
  late List<MusteriDanisan> musteridanisanliste;
  bool yukleniyor =true;
  void initState() {

    super.initState();
    initialize();

  }
  Future<void> initialize() async
  {
    seciliisletme = (await secilisalonid())!;
    List<MusteriDanisan> musteridanisan = await musterilistegetir(seciliisletme!);
    List<Personel> isletmepersonellerliste = await personellistegetir(seciliisletme!);




    setState(() {
      musteridanisanliste = musteridanisan;
      personelliste = isletmepersonellerliste;
      yukleniyor = false;
    });

  }
  // Function to take a picture from the camera
  Future<void> takePicture() async {
    setState(() {
      _isLoading = true;
    });

    final imagePicker = ImagePicker();
    final XFile? pickedImage =
    await imagePicker.pickImage(source: ImageSource.camera);

    setState(() {
      _isLoading = false;
    });

    if (pickedImage != null) {
      setState(() {
        _images.add(File(pickedImage.path));
      });
    }
  }
  // Function to upload a document
  Future<void> uploadDocument() async {
    setState(() {
      _isLoading = true;
    });

    // Check for permission
    PermissionStatus status = await Permission.storage.request();

    if (status.isGranted) {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );

      setState(() {
        _isLoading = false;
      });

      if (result != null) {
        String? extension = result.files.single.extension;

        // Allowed MIME types mapped by their extensions
        final Map<String, String> mimeTypes = {
          'pdf': 'application/pdf',
          'doc': 'application/msword',
          'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        };

        if (mimeTypes.containsKey(extension)) {
          setState(() {
            _documentName = result.files.single.name;
            _documentExtension = extension;
            belge = File(result.files.single.path!);
          });
        } else {
          // Handle invalid file type here
          print('Invalid file type selected.');
        }
      }
    } else if (status.isDenied) {
      // Handle the case when permission is denied
      print('Storage permission denied');
    } else if (status.isPermanentlyDenied) {
      // Handle the case when permission is permanently denied
      openAppSettings(); // Direct the user to app settings
    }

    setState(() {
      _isLoading = false;
    });
  }


  // Function to delete the uploaded image
  void deleteImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  // Function to delete the uploaded document
  void deleteDocument() {
    setState(() {
      _documentName = null;
      _documentExtension = null;
    });
  }
  // Function to view image in full screen

  final List<String> musteri = [
    'Cevriye Güleç',
    'Anıl Orbey',
    'Çağlar  Filiz',
    'Elif Çetin',
    'Ferdi Korkmaz',


  ];
  MusteriDanisan? selectedmusteri;
  TextEditingController musteriController = TextEditingController();
  final List<String> personel = [
    'Cevriye Efe',
    'Alkın Orbey',
    'Çağrı  Taner',
    'Esra Çetin',
    'Gülşah Korkmaz',


  ];
  Personel? selectedpersonel;
  TextEditingController personelController = TextEditingController();


  TextEditingController formbaslik = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Unfocus the current text field, dismissing the keyboard
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title:  const Text('Harici Belge Ekle',style: TextStyle(color: Colors.black),),

          leading: IconButton(
            icon: Icon(Icons.clear_rounded, color: Colors.black),
            onPressed: () {Navigator.of(context).pop(); Navigator.push(context, PageTransition(type: PageTransitionType.rightToLeft,duration: Duration(milliseconds:500), child: ArsivYonetimiPage(isletmebilgi: widget.isletmebilgi,)));},
          ),
          toolbarHeight: 60,
          actions: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: SizedBox(
                width: 100, // <-- Your width
                child: YukseltButonu(isletme_bilgi: widget.isletmebilgi
                  ,)
              ),
            ),


          ],
          backgroundColor: Colors.white,
        ),
        body: yukleniyor ? Center(child: CircularProgressIndicator(),) : SingleChildScrollView(
          reverse: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20,),
              Padding(
                padding: const EdgeInsets.only(left: 20.0),
                child: Text('Form Başlığı',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
              ),
              SizedBox(height: 10,),
              Container(
                height: 40,
                padding: const EdgeInsets.only(left: 20.0,right: 20),
                child: TextFormField(
                  controller: formbaslik,
                  onSaved: (value){ formbaslik.text = value!;},
                  keyboardType: TextInputType.text,

                  enabled:true,

                  decoration: InputDecoration(

                    focusColor:Color(0xFF6A1B9A) ,
                    hoverColor: Color(0xFF6A1B9A) ,
                    hintStyle: TextStyle(color:  Color(0xFF6A1B9A)),
                    contentPadding:  EdgeInsets.all(15.0),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(
                        color: Color(0xFF6A1B9A)),borderRadius: BorderRadius.circular(10.0),),
                    border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10.0),),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF6A1B9A),), borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10,),
              Padding(
                padding: const EdgeInsets.only(left: 20.0),
                child: Text('Müşteri',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
              ),
              SizedBox(height: 10,),
              Container(

                alignment: Alignment.center,
                margin: EdgeInsets.only(left:20,right: 20),
                height: 40,
                width:double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Color(0xFF6A1B9A)),
                  borderRadius: BorderRadius.circular(10), //border corner radius

                  //you can set more BoxShadow() here

                ),
                child: DropdownButtonHideUnderline(

                    child: DropdownButton2<MusteriDanisan>(

                      isExpanded: true,
                      hint: Text(
                        'Seç',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                      items: musteridanisanliste
                          .map((item) => DropdownMenuItem(
                        value: item,
                        child: Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      ))
                          .toList(),
                      value: selectedmusteri,

                      onChanged: (value) {
                        setState(() {
                          selectedmusteri = value;
                        });
                      },
                      buttonStyleData: const ButtonStyleData(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        height: 50,
                        width: 400,
                      ),

                      dropdownStyleData: const DropdownStyleData(
                        maxHeight: 200,
                      ),
                      menuItemStyleData: const MenuItemStyleData(
                        height: 40,
                      ),
                      dropdownSearchData: DropdownSearchData(
                        searchController: musteriController,
                        searchInnerWidgetHeight: 50,
                        searchInnerWidget: Container(
                          height: 50,
                          padding: const EdgeInsets.only(
                            top: 8,
                            bottom: 4,
                            right: 8,
                            left: 8,
                          ),
                          child: TextFormField(
                            expands: true,
                            maxLines: null,
                            controller: musteriController,
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              hintText: 'Şablon Ara..',
                              hintStyle: const TextStyle(fontSize: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                          ),
                        ),
                        searchMatchFn: (item, searchValue) {
                          return item.value!.name.toString().toLowerCase().contains(searchValue.toLowerCase());
                        },
                      ),
                      //This to clear the search value when you close the menu
                      onMenuStateChange: (isOpen) {
                        if (!isOpen) {
                          musteriController.clear();
                        }
                      },

                    )),
              ),
              SizedBox(height: 10,),
              Padding(
                padding: const EdgeInsets.only(left: 20.0),
                child: Text('İşlemi Yapan Personel',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
              ),
              SizedBox(height: 10,),
              Container(

                alignment: Alignment.center,
                margin: EdgeInsets.only(left:20,right: 20),
                height: 40,
                width:double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Color(0xFF6A1B9A)),
                  borderRadius: BorderRadius.circular(10), //border corner radius

                  //you can set more BoxShadow() here

                ),
                child: DropdownButtonHideUnderline(

                    child: DropdownButton2<Personel>(

                      isExpanded: true,
                      hint: Text(
                        'Seç',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                      items: personelliste
                          .map((item) => DropdownMenuItem(
                        value: item,
                        child: Text(
                          item.personel_adi,
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      ))
                          .toList(),
                      value: selectedpersonel,

                      onChanged: (value) {
                        setState(() {
                          selectedpersonel = value;
                        });
                      },
                      buttonStyleData: const ButtonStyleData(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        height: 50,
                        width: 400,
                      ),

                      dropdownStyleData: const DropdownStyleData(
                        maxHeight: 200,
                      ),
                      menuItemStyleData: const MenuItemStyleData(
                        height: 40,
                      ),
                      dropdownSearchData: DropdownSearchData(
                        searchController: personelController,
                        searchInnerWidgetHeight: 50,
                        searchInnerWidget: Container(
                          height: 50,
                          padding: const EdgeInsets.only(
                            top: 8,
                            bottom: 4,
                            right: 8,
                            left: 8,
                          ),
                          child: TextFormField(
                            expands: true,
                            maxLines: null,
                            controller: personelController,
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              hintText: ' Ara..',
                              hintStyle: const TextStyle(fontSize: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                          ),
                        ),
                        searchMatchFn: (item, searchValue) {
                          return item.value!.personel_adi.toString().toLowerCase().contains(searchValue.toLowerCase());
                        },
                      ),
                      //This to clear the search value when you close the menu
                      onMenuStateChange: (isOpen) {
                        if (!isOpen) {
                          personelController.clear();
                        }
                      },

                    )),
              ),

              SizedBox(height: 20,),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: _isLoading ? null : takePicture,
                    child: Row(

                      children: [
                        Icon(Icons.camera_alt_outlined),
                        SizedBox(width: 5,),
                        Text('Resim Çek'),
                      ],
                    ),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.purple[800],foregroundColor: Colors.white,minimumSize: Size(100, 40)),
                  ),

                  ElevatedButton(
                    onPressed: _isLoading ? null : uploadDocument,
                    child: Row(
                      children: [
                        Icon(Icons.upload_file),
                        SizedBox(width: 5,),
                        Text('Belge Yükle'),
                      ],
                    ),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.purple[800],foregroundColor: Colors.white,minimumSize: Size(100, 40)),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Container(
                padding: EdgeInsets.only(left:20,right: 20),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 4,

                    mainAxisSpacing: 4,
                  ),
                  itemCount: _images.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Stack(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ImageViewer(
                                  image: _images[index],
                                  onDelete: () => deleteImage(index),
                                ),
                              ),
                            );
                          },
                          child:  Image.file(_images[index], fit: BoxFit.cover),


                        ),
                        Positioned(
                          bottom: 70,
                          right: 72,
                          child: IconButton(
                            onPressed: () => deleteImage(index),
                            icon: Icon(Icons.delete, color: Colors.red),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              if (_documentName != null)
                Container(padding: EdgeInsets.only(left:10),child:  Stack(
                  alignment: Alignment.centerRight,
                  children: [
                    Text('Belge: $_documentName ',style: TextStyle(fontSize: 16,color: Colors.blue[900]),),

                    Positioned(

                      child: IconButton(
                        onPressed: deleteDocument,
                        icon: Icon(Icons.delete,color:Colors.red[600]),
                      ),
                    ),
                  ],
                )),
              SizedBox(height: 20,),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  ElevatedButton(onPressed: (){
                    if(_images.length==0)
                      hariciBelgeEkle(belge,'');
                    else
                      hariciBelgeEkle(_images[0],'');

                  },
                    child: Row(
                      children: [

                        Text(' Gönder'),
                      ],
                    ),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        minimumSize: Size(90, 40)
                    ),
                  ),
                ],
              ),
              Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom))
            ],
          ),
        ),
      ),
    );
  }
  Future<void> hariciBelgeEkle(File file,String id) async {
    showProgressLoading(context);
    SharedPreferences localStorage = await SharedPreferences.getInstance();

    var user = jsonDecode(localStorage.getString('user')!);
    Map<String, dynamic> formData = {
      'id': id,
      'form_baslik': formbaslik.text,
      'form_id': '0',
      'personel_id': selectedpersonel?.id,
      'user_id' : selectedmusteri?.id,
      'salon_id' : seciliisletme,
      'olusturan':user["id"]


      // Add other form fields
    };

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('https://app.randevumcepte.com.tr/api/v1/haricibelgeekle'),
    );

    request.files.add(await http.MultipartFile.fromPath('file', file.path));
    formData.forEach((key, value) {
      request.fields[key] = value.toString();
    });
    var response = await request.send();

    if (response.statusCode == 200) {

      Navigator.push(context, PageTransition(type: PageTransitionType.rightToLeft,duration: Duration(milliseconds:500), child: ArsivYonetimiPage(isletmebilgi: widget.isletmebilgi,)));
      print('File uploaded successfully!');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Form oluşturulurken bir hata oluştu! Hata kodu : '+response.statusCode.toString()),
        ),
      );
      var responseBody = await response.stream.bytesToString();
      debugPrint('Error: ${responseBody}');

    }

  }
}
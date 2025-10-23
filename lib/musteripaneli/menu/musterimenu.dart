import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:randevu_sistem/musteripaneli/anasayfa/musteriprofilbilgileri.dart';
import 'package:randevu_sistem/musteripaneli/menu/saglikbilgileri.dart';
import 'package:randevu_sistem/musteripaneli/menu/siparislerim.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Frontend/backroutes.dart';
import '../../Frontend/indexedstack.dart';
import '../../Login Sayfası/checklogin.dart';
import '../../Login Sayfası/tanitim.dart';
import '../../Models/musteri_danisanlar.dart';
import '../anasayfa/anasayfa.dart';
import '../anasayfa/raporlar/seanslar.dart';
import 'musteriresimleri.dart';
import 'musteriseans.dart';
import 'musterisözlesmeleri.dart';
class MenuPage extends StatefulWidget{
  final VoidCallback onLogout;
  final MusteriDanisan md;
  final dynamic isletmebilgi;
  const MenuPage({Key? key, required this.onLogout, required this.md, this.isletmebilgi,}) : super(key: key);

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  void _logout(BuildContext context) async {
    try {
      bool? confirmLogout = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Çıkış Yap'),
          content: Text('Çıkış yapmak istediğinize emin misiniz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Hayır'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Evet'),
            ),
          ],
        ),
      );

      if (confirmLogout == true) {
        // Reset the selectedIndex state before logging out
        Provider.of<IndexedStackState>(context, listen: false).setSelectedIndex(0);
        Provider.of<IndexedStackState>(context, listen: false).resetSelectedIndex();
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.remove('musteri');
        await prefs.remove('user_type');
        await prefs.remove('token');

        // Call the callback to update the login state
        //widget.onLogout();

        // Replace the current route with the login page
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => OnBoardingPage()),
              (Route<dynamic> route) => false, 
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bir hata oluştu: ${e.toString()}')),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return WillPopScope( onWillPop: () => BackRoutes.onWillPop(context,MusteriAnsayfa(md: widget.md, isletmebilgi: widget.isletmebilgi, onLogout: () {  },),true),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
          home:Scaffold(
            resizeToAvoidBottomInset: false,
            appBar: AppBar(
              title: Text('Menü',style: TextStyle(color:Colors.black),),
              toolbarHeight: 60,
              backgroundColor: Colors.white,
            ),
            body:SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(12),
                alignment: Alignment.center,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.date_range,color: Colors.purple,),
                      title: const Text("Seanslarım"),
                      trailing: Icon(Icons.keyboard_arrow_right,color:Colors.purple),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => SeanslarDashboard(isletmebilgi: this.widget.isletmebilgi,md: this.widget.md,))
                        );
                      },
                    ),
                    Divider(),
                    ListTile(
                      leading: const Icon(Icons.shopping_cart,color: Colors.purple,),
                      title: const Text("Satın Aldıklarım"),
                      trailing: Icon(Icons.keyboard_arrow_right,color:Colors.purple),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => MusteriPaneliAdiayonlari( kullanici: widget.md,isletmebilgi: widget.isletmebilgi,)),
                        );
                      },
                    ),
                    Divider(),ListTile(
                      leading: const Icon(Icons.health_and_safety_outlined,color: Colors.purple,),
                      title: const Text("Sağlık Bilgilerim"),
                      trailing: Icon(Icons.keyboard_arrow_right,color:Colors.purple),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => MusteriPaneliSaglikBilgileri(md: this.widget.md,)),
                        );
                      },
                    ),
                    Divider(),ListTile(
                      leading: const Icon(Icons.article_outlined,color: Colors.purple,),
                      title: const Text("Sözleşme/Belgelerim"),
                      trailing: Icon(Icons.keyboard_arrow_right,color:Colors.purple),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => MusteriPaneliArsivDetay( md: widget.md,isletmebilgi: widget.isletmebilgi,)),
                        );
                      },
                    ),

                    Divider(),ListTile(
                      leading: const Icon(Icons.photo_camera_back_outlined,color: Colors.purple,),
                      title: const Text("Resimlerim"),
                      trailing: Icon(Icons.keyboard_arrow_right,color:Colors.purple),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ImageGallery(md: this.widget.md, isletmebilgi:  this.widget.isletmebilgi,)),
                        );
                      },
                    ),
                    Divider(),ListTile(
                      leading: const Icon(Icons.person,color: Colors.purple,),
                      title: const Text("Profil Bilgilerim"),
                      trailing: Icon(Icons.keyboard_arrow_right,color:Colors.purple),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => MusteriProfilBilgileri(kullanici: this.widget.md)),
                        );
                      },
                    ),
                    Divider(),
                    ListTile(
                      leading: Icon(Icons.exit_to_app,color:Colors.purple),
                      title: Text("Çıkış Yap"),
                      trailing: Icon(Icons.keyboard_arrow_right,color:Colors.purple),
                      onTap: () { _logout(context);},

                    ),
                  ],
                ),
              ),
            )

          ),
      ),
    );
  }
}
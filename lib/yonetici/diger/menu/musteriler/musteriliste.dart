import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:randevu_sistem/yonetici/diger/menu/musteriler/sadikmusteriler.dart';
import 'package:randevu_sistem/yonetici/diger/menu/musteriler/yeni_musteri.dart';
import '../../../../Backend/backend.dart';
import 'rehberdekimusteriler.dart';
import 'aktifmusteriler.dart';
import 'pasifmusteriler.dart';
import 'tummusteriler.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import 'package:permission_handler/permission_handler.dart';

class MusteriListesi extends StatefulWidget {
  final dynamic isletmebilgi;
  const MusteriListesi({Key? key, required this.isletmebilgi}) : super(key: key);

  @override
  _MusteriListesiState createState() => _MusteriListesiState();
}

class _MusteriListesiState extends State<MusteriListesi> {
  Future<void> rehberdenSec() async {
    if (await FlutterContacts.requestPermission()) {
      final contact = await FlutterContacts.openExternalPick();

      if (contact != null) {
        // Detaylı bilgileri baştan çek (telefonlar dahil)
        final fullContact = await FlutterContacts.getContact(contact.id, withProperties: true);

        if (fullContact != null) {
          String isim = fullContact.displayName.trim();
          String telefon = fullContact.phones.isNotEmpty ? fullContact.phones.first.number : "";

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Yenimusteri(
                isletmebilgi: widget.isletmebilgi,
                isim: isim,
                telefon: telefon,
                sadeceekranikapat: false,
              ),
            ),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Rehber erişim izni reddedildi!")),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: AppBar(
            centerTitle: false,
            title:  Expanded(
              child: Text(
                'Müşteriler',
                style: TextStyle(color: Colors.black),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: <Widget>[
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: SizedBox(
                  //width: 100,
                  child: YukseltButonu(isletme_bilgi: widget.isletmebilgi),
                ),
              ),
              IconButton(
                icon: Icon(Icons.add, color: Colors.black),
                iconSize: 26,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Yenimusteri(
                        isletmebilgi: widget.isletmebilgi,
                        isim:"",
                        telefon: "",
                        sadeceekranikapat: false,
                      ),
                    ),
                  );
                },
              ),

              IconButton(
                icon: Icon(Icons.group_add, color: Colors.black),
                iconSize: 26,
                onPressed: (){
                  rehberdenTopluSec(context, widget.isletmebilgi);
                }, // New button to select multiple contacts
              ),
            ],
            backgroundColor: Colors.white,
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(60),
              child: Container(
                padding: EdgeInsets.only(bottom: 10),
                child: TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.purple,
                  unselectedLabelColor: Colors.purple[800],
                  labelPadding: EdgeInsets.only(left: 10, right: 10),
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    color: Colors.transparent,
                    border: Border.all(
                      color: Colors.purple[800]!,
                      width: 1.5,
                    ),
                  ),
                  tabs: [
                    Tab(
                      child: Container(
                        width: 110,
                        child: Align(
                          alignment: Alignment.center,
                          child: Text(
                            "Tümü",
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                    Tab(
                      child: Container(
                        width: 220,
                        child: Align(
                          alignment: Alignment.center,
                          child: Text(
                            "Sadık Müşteriler",
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                    Tab(
                      child: Container(
                        width: 220,
                        child: Align(
                          alignment: Alignment.center,
                          child: Text(
                            "Aktif Müşteriler",
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                    Tab(
                      child: Container(
                        width: 220,
                        child: Align(
                          alignment: Alignment.center,
                          child: Text(
                            "Pasif Müşteriler",
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: TabBarView(
            children: <Widget>[
              TumMusteriler(isletmebilgi: widget.isletmebilgi),
              SadikMusteriler(isletmebilgi: widget.isletmebilgi),
              AktifMusteriler(isletmebilgi: widget.isletmebilgi),
              PasifMusteriler(isletmebilgi: widget.isletmebilgi),
            ],
          ),
        ),
      ),
    );
  }
}
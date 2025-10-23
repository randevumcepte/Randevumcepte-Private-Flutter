import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:randevu_sistem/yonetici/diger/menu/arsiv/tumarsiv.dart';
import 'package:randevu_sistem/yonetici/diger/menu/musteriler/sadikmusteriler.dart';
import 'package:randevu_sistem/yonetici/diger/menu/musteriler/yeni_musteri.dart';

import '../../../../Frontend/altyuvarlakmenu.dart';
import 'beklenenformlar.dart';
import 'formekle.dart';
import 'haricibelge.dart';
import 'haricibelgeekle.dart';
import 'iptaledilenformlar.dart';
import 'onaylananformlar.dart';
import 'package:image_picker/image_picker.dart';





class ArsivYonetimiPage extends StatefulWidget {
  final dynamic isletmebilgi;
  const ArsivYonetimiPage({Key? key,required this.isletmebilgi}) : super(key: key);

  @override
  _ArsivYonetimiPageState createState() =>
      _ArsivYonetimiPageState();
}
class _ArsivYonetimiPageState extends State<ArsivYonetimiPage> {
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus(); // Hide the keyboard
        },
      child: DefaultTabController(
        length: 5,
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            centerTitle: false,
            title: const Text(
              'Arşiv Yönetimi',
              style: TextStyle(color: Colors.black),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: <Widget>[
              if (widget.isletmebilgi["demo_hesabi"].toString() == "1")
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: SizedBox(
                    width: 100, // <-- Your width
                    child: YukseltButonu(isletme_bilgi: widget.isletmebilgi,)
                ),
              ),
              IconButton(
                onPressed: () {
                  showModalBottomSheet(
                    isScrollControlled: true,
                    backgroundColor: Colors.grey[200],
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(25.0),
                      ),
                    ),
                    context: context,
                    builder: (context) {
                      return FractionallySizedBox(
                        heightFactor: 0.11,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                Navigator.of(context).pop();
                                Navigator.push(
                                  context,
                                  PageTransition(
                                    type: PageTransitionType.rightToLeft,
                                    duration: Duration(milliseconds: 500),
                                    child: FormEkle(isletmebilgi: widget.isletmebilgi,),
                                  ),
                                );
                              },
                              child: Text('Yeni Form Oluştur'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor:Colors.white,
                                elevation: 5,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5.0),
                                ),
                                minimumSize: Size(110, 30),
                              ),
                            ),
                            SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                Navigator.of(context).pop();
                                Navigator.push(
                                  context,
                                  PageTransition(
                                    type: PageTransitionType.rightToLeft,
                                    duration: Duration(milliseconds: 500),
                                    child: HariciBelgeEkle(isletmebilgi: widget.isletmebilgi,),
                                  ),
                                );
                              },
                              child: Text('Belge Ekle'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple[800],
                                foregroundColor:Colors.white,
                                elevation: 5,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5.0),
                                ),
                                minimumSize: Size(150, 30),
                              ),
                            )
                          ],
                        ),
                      );
                    },
                  );
                },
                icon: Icon(Icons.add, color: Colors.black),
                iconSize: 26,
              ),
            ],
            backgroundColor: Colors.white,
            bottom:  PreferredSize(
              preferredSize: Size.fromHeight(60),
              child: Container(
                padding: EdgeInsets.only(bottom: 10),

                child: TabBar(
                  isScrollable: true,
                  indicatorSize: TabBarIndicatorSize.tab,
                  tabAlignment: TabAlignment.start, // <-- sekmeler soldan yapışık başlar
                  labelColor: Colors.purple,
                  unselectedLabelColor: Colors.purple[800],
                  labelPadding: EdgeInsets.only(left: 10, right: 10),
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    color: Colors.transparent, // This will be transparent so that we can apply a custom decoration
                    border: Border.all(
                      color: Colors.purple[800]!,
                      width: 1.5,
                    ),
                  ),
                  tabs: [
                    Tab(
                      child: Container(
                        width: 60,
                        child: Align(
                          alignment: Alignment.center,
                          child: Text(
                            "Tümü",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Tab(
                      child: Container(
                        width: 120,
                        child: Align(
                          alignment: Alignment.center,
                          child: Text(
                            "Onaylananlar",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Tab(
                      child: Container(
                        width: 120,
                        child: Align(
                          alignment: Alignment.center,
                          child: Text(
                            "Beklenenler",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Tab(
                      child: Container(
                        width: 120,
                        child: Align(
                          alignment: Alignment.center,
                          child: Text(
                            "İptal Edilenler",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Tab(
                      child: Container(
                        width: 120,
                        child: Align(
                          alignment: Alignment.center,
                          child: Text(
                            "Harici Belgeler",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
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
              TumArsiv(),
              OnaylananArsiv(),
              BeklenenArsiv(),
              IptalEdilenArsiv(),
              HariciArsiv()
            ],
          ),
        ),
      )
    );
  }
}

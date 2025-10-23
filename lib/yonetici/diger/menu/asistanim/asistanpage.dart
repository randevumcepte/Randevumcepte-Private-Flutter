
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:randevu_sistem/yonetici/diger/menu/asistanim/yarinkigorevlerim.dart';

import 'bugunkugorevlerim.dart';





class AsistanimPage extends StatefulWidget {
  final dynamic isletmebilgi;
  const AsistanimPage({Key? key,required this.isletmebilgi}) : super(key: key);

  @override
  _AsistanimPageState createState() =>
      _AsistanimPageState();
}
class _AsistanimPageState extends State<AsistanimPage> {
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus(); // Hide the keyboard
        },
        child: DefaultTabController(
          length: 2,
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            appBar: AppBar(
              centerTitle: false,
              title: const Text(
                'Asistanım',
                style: TextStyle(color: Colors.black),
              ),
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.of(context).pop(),
              ),

              backgroundColor: Colors.white,
              bottom:  PreferredSize(
                preferredSize: Size.fromHeight(60),
                child: Container(
                  padding: EdgeInsets.only(bottom: 10),

                  child: TabBar(
                    isScrollable: false,
                    indicatorSize: TabBarIndicatorSize.label,
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
                          width: 160,
                          child: Align(
                            alignment: Alignment.center,
                            child: Text(
                              "Bugünkü Görevlerim",
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
                          width: 160,
                          child: Align(
                            alignment: Alignment.center,
                            child: Text(
                              "Yarınki Görevlerim",
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
                BugunlukGorevler(isletmebilgi: widget.isletmebilgi,),
                YarinkiGorevler(isletmebilgi: widget.isletmebilgi,)

              ],
            ),
          ),
        )
    );
  }
}

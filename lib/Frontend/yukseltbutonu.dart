
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:randevu_sistem/Backend/backend.dart';



class YukseltButonu extends StatelessWidget {
  final dynamic isletme_bilgi;
  YukseltButonu({Key? key, required this.isletme_bilgi});
  @override
  Widget build(BuildContext context) {
    debugPrint("işletme bilgi yükselt butonu "+isletme_bilgi.toString() );
    if(isletme_bilgi["demo_hesabi"].toString() == "1")
    return  ElevatedButton(onPressed: (){

        launchURL("https://randevumcepte.com.tr/paketler");

    }, child: Text("YÜKSELT"), style: ElevatedButton.styleFrom(
        backgroundColor: Colors.purple[800], // background (button) color
        foregroundColor: Colors.white,
        textStyle: const TextStyle(
          color: Colors.white, fontSize: 15,
        ),
        shape: const BeveledRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(5)))
    ),
    );
    else
      return SizedBox.shrink();
  }
}

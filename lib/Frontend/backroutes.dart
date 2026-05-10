import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:randevu_sistem/yonetici/diger/menu/kampanya/kampanyalar.dart';

class BackRoutes{
  static Future<bool> onWillPop(BuildContext context,Widget widget,bool menusayfasi)  async {
    // Perform your custom action here
    // For example, show a confirmation dialog
    Navigator.of(context).pop();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => widget),
    );
    return true;


  }
}

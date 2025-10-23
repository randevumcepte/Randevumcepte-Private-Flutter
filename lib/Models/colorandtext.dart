import 'dart:developer';
import 'dart:ui';

import 'package:flutter/material.dart';

class ColorAndText {
  final Color color;
  final String text;

  ColorAndText(this.color, this.text);
}
ColorAndText getStatusColorAndText(String durum) {

  if (durum == '0') {
    return ColorAndText(Colors.red[600]!, 'Katılmıyor');
  }
  else if(durum=='1')
    return ColorAndText(Colors.green, 'Katılıyor');
  else {
    return ColorAndText(Colors.orange, 'Beklemede');
  }



}
ColorAndText getStatusColorArsiv(String Durum,String Cevapladi,String Cevapladi2) {
  if (Durum == 'null' && Cevapladi2 == 'null' && Cevapladi == 'null')
    return ColorAndText(Colors.purple[800]!, 'Harici Belge');
  else if (Durum == 'null' && (Cevapladi == '1' || Cevapladi2 == '1'))
    return ColorAndText(Colors.yellow[700]!, 'Onay Bekleniyor');

  else if (Durum == 'null' && (Cevapladi == '0' || Cevapladi2 == '0'))
    return ColorAndText(Colors.blue[700]!, 'Form Bekleniyor');

  else if (Durum == '1')
    return ColorAndText(Colors.green!, 'Onaylı');

  else if (Durum == '0')
    return ColorAndText(Colors.red[600]!, 'İptal Edildi');
  else
    return ColorAndText(Colors.white!, '');

}
ColorAndText getStatusColorRandevu(String Durum,String randevuyageldi) {
  if (Durum == '0')
    return ColorAndText(Colors.yellow[700]!, 'Beklemede');
    //return ColorAndText(Colors.purple[800]!, 'Harici Belge');
 /* else if (Durum == 'null' && (Cevapladi == '1' || Cevapladi2 == '1'))
    return ColorAndText(Colors.yellow[700]!, 'Onay Bekleniyor');

  else if (Durum == 'null' && (Cevapladi == '0' || Cevapladi2 == '0'))
    return ColorAndText(Colors.blue[700]!, 'Form Bekleniyor');*/

  else if (Durum == '1'){
    if(randevuyageldi.toString()=="1")
      return ColorAndText(Colors.green!, 'Geldi');
    else if(randevuyageldi.toString()=="0")
      return ColorAndText(Colors.red[600]!, 'Gelmedi');
    else
      return ColorAndText(Colors.green!, 'Onaylı');
  }

  else if (Durum == '2')
    return ColorAndText(Colors.black!, 'İptal Edildi');
  else if (Durum == '3')
    return ColorAndText(Colors.black!, 'Müşteri İptal');
  else
    return ColorAndText(Colors.white!, '');

}

ColorAndText getOngorusmeStatusColor(String Durum) {
  switch (Durum) {
    case '1':
      return ColorAndText(Colors.green!, 'Satış Yapıldı');
    case '0':
      return ColorAndText(Colors.red[600]!, 'Satış Yapılmadı');
    case 'null':
      return ColorAndText(Colors.yellow[700]!, 'Beklemede');
    default:
      return ColorAndText(Colors.yellow[700]!, 'Beklemede');
  }
}
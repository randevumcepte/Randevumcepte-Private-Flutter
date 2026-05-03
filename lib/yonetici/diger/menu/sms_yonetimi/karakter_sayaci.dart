import 'package:flutter/material.dart';

/// Web'deki SMS karakter sayacı ile aynı kuralları uygular.
class KarakterSayaci extends StatelessWidget {
  final int uzunluk;
  const KarakterSayaci({Key? key, required this.uzunluk}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color bg = Colors.white;
    Color fg = Colors.black87;
    int adet = 1;
    if (uzunluk <= 155) {
      adet = 1;
      bg = Colors.grey.shade100;
    } else if (uzunluk <= 292) {
      adet = 2;
      bg = Colors.orange;
      fg = Colors.white;
    } else if (uzunluk <= 439) {
      adet = 3;
      bg = Colors.red;
      fg = Colors.white;
    } else if (uzunluk <= 587) {
      adet = 4;
      bg = Colors.red;
      fg = Colors.white;
    } else if (uzunluk <= 735) {
      adet = 5;
      bg = Colors.red;
      fg = Colors.white;
    } else {
      adet = 6;
      bg = Colors.red;
      fg = Colors.white;
    }
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        '$uzunluk karakter (Gönderim başına $adet sms üzerinden ücretlendirilecektir)',
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }
}

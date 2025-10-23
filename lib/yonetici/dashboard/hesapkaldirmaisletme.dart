import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:randevu_sistem/Models/musteri_danisanlar.dart';
import 'package:randevu_sistem/Models/user.dart';

import '../../Frontend/progressloading.dart';

class HesapKaldirmaIsletme extends StatefulWidget {
  final Kullanici kullanici;

  HesapKaldirmaIsletme({Key? key, required this.kullanici}) : super(key: key);

  @override
  _HesapKaldirmaState createState() => _HesapKaldirmaState();
}

class _HesapKaldirmaState extends State<HesapKaldirmaIsletme> {
  bool accepted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text("Hesap Silme Talebi", style: TextStyle(color: Colors.black)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),

      // İçerik
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Uyarı kutusu
            Container(
              padding: EdgeInsets.all(16),
              margin: EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red.shade700,
                    size: 32,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "UYARI",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Hesabınızı silmek istediğinizde tüm kişisel bilgileriniz, "
                              "randevu geçmişiniz ve kayıtlı verileriniz 30 iş günü içerisinde işletme veritabanından kalıcı olarak "
                              "silinecektir. Bu işlem geri alınamaz.",
                          style: TextStyle(fontSize: 16, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // Onay kutusu
            Row(
              children: [
                Checkbox(
                  value: accepted,
                  onChanged: (val) {
                    setState(() {
                      accepted = val ?? false;
                    });
                  },
                ),
                Expanded(
                  child: Text(
                    "Hesabımı silmek istediğimi ve tüm verilerimin kalıcı olarak "
                        "silineceğini kabul ediyorum.",
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),

            SizedBox(height: 80), // butonlar için boşluk bırak
          ],
        ),
      ),

      // Alt sabit butonlar
      bottomNavigationBar: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min, // sadece içerik kadar yer kaplasın
          children: [
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.grey.shade400),
                ),
                child: Text(
                  "İptal",
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
              ),
            ),
            SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (!accepted) {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text("Uyarı"),
                          content: Text("Lütfen devam etmeden önce şartları kabul ediniz."),
                          actions: [
                            TextButton(
                              child: Text("Tamam"),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        );
                      },
                    );
                  } else {
                    showProgressLoading(context);
                    Map<String, dynamic> formData = {
                      'yetkiliId': widget.kullanici.id,
                      'salonIdler': [182],

                    };

                    final response = await http.post(
                      Uri.parse("https://app.randevumcepte.com.tr/api/v1/hesapSilmeTalebiGonderPersonel"),
                      headers: {'Content-Type': 'application/json'},
                      body: jsonEncode(formData),
                    );
                    Navigator.of(context, rootNavigator: true).pop();
                    if (response.statusCode == 200) {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text("Başarılı"),
                            content: Text("Hesap silme talebiniz işletmemize başarı ile iletilmiş olup süreç ile ilgili işletmemiz tarafından bilgilendirileceksiniz. Dilerseniz 30 iş günü içerisinde hesap silme talebinizi iptal edebilirsiniz."),
                            actions: [
                              TextButton(
                                child: Text("Tamam"),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          );
                        },
                      );

                    } else {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text("HATA"),
                            content: Text("Hesap silme talebiniz işletmemize iletilirken bir hata oluştu. Lütfen daha sonra tekrar  deneyiniz."),
                            actions: [
                              TextButton(
                                child: Text("Tamam"),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          );
                        },
                      );
                    }

                  }
                },

                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  "Hesabımı Sil",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),

    );
  }
}

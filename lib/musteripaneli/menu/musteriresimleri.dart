import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:randevu_sistem/Models/musteri_danisanlar.dart';

import '../../Models/islemler.dart';

class ImageGallery extends StatefulWidget {
  final MusteriDanisan md;
  final dynamic isletmebilgi;

  const ImageGallery({Key? key, required this.md, required this.isletmebilgi}) : super(key: key);

  @override
  _ImageGalleryState createState() => _ImageGalleryState();
}

class _ImageGalleryState extends State<ImageGallery> {
  late List<Islemler> imageFolders = []; // Initialize as an empty list
  late List<List<String>> imageFolder2 = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchImages();
  }

  Future<void> fetchImages() async {
    try {
      final userId = widget.md.id; // Get user_id from md model

      final response = await http.post(
        Uri.parse('https://app.randevumcepte.com.tr/api/v1/musteriresimleri'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'user_id': userId,
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        setState(() {
          imageFolders = data.map((item) => Islemler.fromJson(item)).toList();

          imageFolders.forEach((element) {
            List<String> images = List<String>.from(jsonDecode(element.islem_fotolari));
            imageFolder2.add(images);


          });

          isLoading = false;
        });
      } else {
        // Handle HTTP-level errors
        debugPrint(response.body);
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {

      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Resimlerim',
          style: TextStyle(color: Colors.black),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        toolbarHeight: 60,
        backgroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : imageFolder2.isEmpty
          ? const Center(child: Text('Resim bulunmamaktadır'))
          : ListView(
        children: imageFolders.asMap()
            .entries
            .map((entry) {
          int index = entry.key; // T
          String folderName = entry.value.tarih;
          List<String> images = imageFolder2[entry.key];


          return ExpansionTile(
            title: Text(folderName),
            children: images.map((image) {
              String imageUrl =
                  'https://app.randevumcepte.com.tr/$image';




              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Material( // Wrap with Material to prevent Hero effects
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                              (loadingProgress.expectedTotalBytes ?? 1)
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.broken_image, size: 50);
                    },
                  ),
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }
}

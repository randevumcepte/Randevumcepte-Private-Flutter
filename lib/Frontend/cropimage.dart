import 'dart:io';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CropScreen extends StatefulWidget {
  final File imageFile;
  CropScreen({required this.imageFile});

  @override
  _CropScreenState createState() => _CropScreenState();
}

class _CropScreenState extends State<CropScreen> {
  final _cropController = CropController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Resmi Kırp")),
      body: Column(
        children: [
          Expanded(
            child: Crop(
              image: widget.imageFile.readAsBytesSync(),
              controller: _cropController,
              aspectRatio: 1.0,
              onCropped: (result) async {
                if (result is CropSuccess) {
                  final croppedFile = File(widget.imageFile.path);
                  await croppedFile.writeAsBytes(result.croppedImage);
                  Navigator.of(context).pop(croppedFile); // crop edilmiş resmi geri döndür
                }
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(), // iptal
                child: Text("İptal"),
              ),
              ElevatedButton(
                onPressed: () {
                  _cropController.crop(); // crop işlemini başlat
                },
                child: Text("Tamam"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:percent_indicator/percent_indicator.dart';

/*void indirmedialoggoster(BuildContext context,String title, ValueNotifier downloadProgressNotifier )
{
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: Padding(
          padding: const EdgeInsets.all(16.0), // Optional: add padding to the content
          child: ValueListenableBuilder(
            valueListenable: downloadProgressNotifier,
            builder: (context, value, snapshot) {
              if (value >= 100) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.of(context).pop();
                });
              }
              return Column(
                mainAxisSize: MainAxisSize.min, // Ensures the dialog sizes based on its content
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'İndiriliyor...',
                    style: TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 32),
                  LinearPercentIndicator(
                    barRadius: const Radius.circular(10),
                    lineHeight: 15.0,
                    percent: downloadProgressNotifier.value / 100,
                    backgroundColor: Colors.grey.shade300,
                    progressColor: Colors.blue,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "${downloadProgressNotifier.value}%",
                    style: const TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.w600,
                        color: Colors.black),
                  ),
                ],
              );
            },
          ),
        ),

      );
    },
  );
}*/
void indirmedialoggoster(
    BuildContext context,
    String title,
    ValueNotifier<dynamic> downloadProgressNotifier,
    ) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite, // genişliği sabitliyoruz
          child: ValueListenableBuilder<dynamic>(
            valueListenable: downloadProgressNotifier,
            builder: (context, value, _) {
              if (value >= 100) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                });
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'İndiriliyor...',
                    style: TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 32),
                  LinearPercentIndicator(
                    barRadius: const Radius.circular(10),
                    lineHeight: 15.0,
                    percent: value / 100,
                    backgroundColor: Colors.grey.shade300,
                    progressColor: Colors.blue,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "$value%",
                    style: const TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    },
  );
}
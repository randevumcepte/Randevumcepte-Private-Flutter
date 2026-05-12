import 'package:flutter/material.dart';
import 'gorev_list_view.dart';

class BugunlukGorevler extends StatelessWidget {
  final dynamic isletmebilgi;
  const BugunlukGorevler({super.key, required this.isletmebilgi});

  @override
  Widget build(BuildContext context) {
    return GorevListView(
      isletmebilgi: isletmebilgi,
      tipi: GorevTipi.bugun,
    );
  }
}

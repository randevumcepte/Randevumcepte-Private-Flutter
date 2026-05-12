import 'package:flutter/material.dart';
import 'gorev_list_view.dart';

class YarinkiGorevler extends StatelessWidget {
  final dynamic isletmebilgi;
  const YarinkiGorevler({super.key, required this.isletmebilgi});

  @override
  Widget build(BuildContext context) {
    return GorevListView(
      isletmebilgi: isletmebilgi,
      tipi: GorevTipi.yarin,
    );
  }
}

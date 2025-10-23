
import 'package:flutter/material.dart';

dynamic showProgressLoading(BuildContext context)
{
  return showDialog(
    barrierDismissible: false,
    builder: (ctx) {
      return Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
        ),
      );
    },
    context: context,
  );
}

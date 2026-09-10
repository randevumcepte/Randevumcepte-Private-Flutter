// Kaydirmali (wheel) saat secici — Material showTimePicker (kadran) yerine.
// 5 dk araliklarla, 24 saat. Bottom sheet olarak acilir, TimeOfDay doner.
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

const Color _mor = Color(0xFF5C008E);

Future<TimeOfDay?> saatSecici(BuildContext context, TimeOfDay initial) async {
  // Cupertino minuteInterval assertion: baslangic dakikasi araliga uymali
  final int dk = (initial.minute ~/ 5) * 5;
  DateTime secili = DateTime(2020, 1, 1, initial.hour, dk);

  return showModalBottomSheet<TimeOfDay>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Vazgeç', style: TextStyle(color: Colors.grey)),
                  ),
                  const Text('Saat Seç', style: TextStyle(fontWeight: FontWeight.w700, color: _mor)),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, TimeOfDay(hour: secili.hour, minute: secili.minute)),
                    child: const Text('Tamam', style: TextStyle(color: _mor, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            SizedBox(
              height: 210,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                use24hFormat: true,
                minuteInterval: 5,
                initialDateTime: secili,
                onDateTimeChanged: (d) => secili = d,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

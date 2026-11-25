import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:randevu_sistem/dil/ceviri.dart';

void main() {
  test('müşteri dili çeviri kuralları', () {
    Ceviri.yukle('ru', File('assets/dil/ru.json').readAsStringSync());
    const beklenen = {
      'RANDEVU AL': 'ЗАПИСАТЬСЯ',
      '3 gün kaldı': 'Осталось дней: 3',
      'Manikür, Pedikür': 'Маникюр, Педикюр',
      '25 Kasım 2026': '25 ноября 2026',
      'Kas': 'ноя',
      'Durum: Onaylandı': 'Статус: Подтверждено',
      'Manikür Kampanyası': 'Акция «Маникюр»',
      'Ayşe Yılmaz': 'Ayşe Yılmaz',
    };
    beklenen.forEach((tr, ru) => expect(Ceviri.cevir(tr), ru));
    Ceviri.dil = 'tr';
    expect(Ceviri.cevir('Randevu Al'), 'Randevu Al');
  });
}

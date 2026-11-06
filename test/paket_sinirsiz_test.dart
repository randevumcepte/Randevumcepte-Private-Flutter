import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:randevu_sistem/Models/paket_hizmetleri.dart';
import 'package:randevu_sistem/Models/paketler.dart';
import 'package:randevu_sistem/Models/seanstakibi.dart';
import 'package:randevu_sistem/yonetici/dashboard/paket_satis_hizmetleri.dart';
import 'package:randevu_sistem/yonetici/diger/menu/ayarlar/paketler/paket_gecerlilik_alanlari.dart';
import 'package:randevu_sistem/yonetici/diger/menu/seanstakibi/sinirsiz_seans_karti.dart';

Paket _paket(Map<String, dynamic> ek) => Paket.fromJson({
      'id': 5,
      'paket_adi': 'Lazer',
      'aktif': 1,
      'miktar': 366,
      'fiyat': '1000',
      'hizmetler': [
        {'hizmet_id': 1, 'seans': 8, 'fiyat': 0, 'hizmet': {'hizmet_adi': 'Bacak'}},
        {'hizmet_id': 2, 'seans': 8, 'fiyat': 0, 'hizmet': {'hizmet_adi': 'Kol'}},
      ],
      ...ek,
    });

SeansTakip _takip({String? baslangic, String? bitis}) => SeansTakip.fromJson({
      'id': 1,
      'adisyon': 1,
      'musteri': {'name': 'Deneme'},
      'paket': 'Lazer (P)',
      'seanslar': [],
      'toplamSeansSayisi': 366,
      'bekleyenSeansSayisi': 1,
      'gelinenSeansSayisi': 1,
      'gelinmeyenSeansSayisi': 0,
      'sinirsiz': 1,
      'sure': '1 Yıl',
      'baslangic': baslangic,
      'bitis': bitis,
    });

String _gun(int fark) =>
    DateTime.now().add(Duration(days: fark)).toIso8601String().substring(0, 10);

Widget _sar(Widget w) => MaterialApp(
      home: Scaffold(body: SizedBox(width: 320, child: SingleChildScrollView(child: w))),
    );

void main() {
  test('Paket: sinirsiz alanlari okunur, toJson geri okunabilir', () {
    final p = _paket({'sinirsiz': 1, 'gecerlilik_sayi': 2, 'gecerlilik_birim': 'yil'});
    expect(p.sinirsiz, isTrue);
    expect(p.sinirsizEtiketi, 'Sınırsız · 2 Yıl');
    final geri = Paket.fromJson(p.toJson());
    expect(geri.sinirsiz, isTrue);
    expect(geri.sureMetni, '2 Yıl');
  });

  test('Eski sunucu yaniti (alan yok): seansli paket', () {
    final p = _paket({});
    expect(p.sinirsiz, isFalse);
    expect(p.sureMetni, '');
  });

  test('Varsayilan seans bolge basina haktir: 8,8 = 8', () {
    expect(_paket({}).varsayilanSeans, 8);
  });

  test('Sure: bitis gunu dahil, gecmisse doldu, yoksa ilk gelis bekler', () {
    expect(_takip(bitis: _gun(0)).suresiDoldu, isFalse);
    expect(_takip(bitis: _gun(0)).kalanSureMetni, '0 gün kaldı');
    expect(_takip(bitis: _gun(-1)).suresiDoldu, isTrue);
    expect(_takip().suresiDoldu, isFalse);
    expect(_takip().kalanSureMetni, 'İlk gelişte başlar');
  });

  test('Form verisi: sinirsiz secilince sure bossa 1 yil', () {
    final d = PaketGecerlilikDegeri();
    d.sinirsizYap(true);
    expect(d.formVerisi(), {
      'sinirsiz': 1,
      'gecerlilik_sayi': '1',
      'gecerlilik_birim': 'yil',
      'gunluk_limit': '',
    });
  });

  testWidgets('Kart: 366 gorunmez, sayaclar seanslardan, sure dolunca yeni kullanim yok',
      (t) async {
    final seanslar = [
      {'geldi': 1, 'seans_tarih': '2026-11-05'},
      {'geldi': null, 'seans_tarih': '2026-11-06'},
      {'geldi': 0, 'seans_tarih': '2026-11-07'},
    ];
    Widget kart(SeansTakip p) => _sar(SinirsizSeansKarti(
          paket: p,
          hizmetAdi: 'Çok uzun bir hizmet adı ki dar ekrana sığmayabilir olsun',
          seanslar: seanslar,
          onDokum: () {},
          onYeniKullanim: () {},
        ));
    await t.pumpWidget(kart(_takip(baslangic: '2026-11-05', bitis: _gun(10))));
    expect(find.text('05.11.2026'), findsOneWidget);
    expect(find.textContaining('366'), findsNothing);
    expect(find.text('Yeni Kullanım'), findsOneWidget);
    expect(t.takeException(), isNull);

    await t.pumpWidget(kart(_takip(baslangic: '2025-01-01', bitis: _gun(-1))));
    expect(find.text('Süresi doldu'), findsOneWidget);
    expect(find.text('Yeni Kullanım'), findsNothing);
  });

  testWidgets('Dokum: en yeni ustte, duzenle pencereyi kapatip seansi verir', (t) async {
    Map? duzenlenen;
    await t.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (c) => TextButton(
            child: const Text('ac'),
            onPressed: () => sinirsizSeansDokumuGoster(c,
                baslik: 'Bacak',
                seanslar: [
                  {'id': 1, 'geldi': 1, 'seans_tarih': '2026-01-01', 'personel_adi': 'Ayşe'},
                  {'id': 2, 'geldi': null, 'seans_tarih': '2026-03-01', 'seans_saat': '10:30:00'},
                ],
                onDuzenle: (s) => duzenlenen = s),
          ),
        ),
      ),
    ));
    await t.tap(find.text('ac'));
    await t.pumpAndSettle();
    expect(find.text('01.03.2026  10:30'), findsOneWidget);
    expect(
      t.getTopLeft(find.text('01.03.2026  10:30')).dy,
      lessThan(t.getTopLeft(find.text('01.01.2026')).dy),
    );
    await t.tap(find.byIcon(Icons.edit_outlined).first);
    await t.pumpAndSettle();
    expect(duzenlenen?['id'], 2);
    expect(find.text('Seans Dökümü'), findsNothing);
  });

  testWidgets('Satis hizmetleri: cikarma calisir, son hizmet cikarilamaz', (t) async {
    var liste = paketSatisHizmetleri(_paket({}));
    expect(paketSatisHizmetIdleri(liste), ['1', '2']);
    Widget ekran(List<PaketHizmetleri> l) => _sar(PaketSatisHizmetSecimi(
          hizmetler: l,
          isletmebilgi: const {'demo_hesabi': 0},
          onChanged: (v) => liste = v,
        ));
    await t.pumpWidget(ekran(liste));
    await t.tap(find.byIcon(Icons.close_rounded).first);
    expect(paketSatisHizmetIdleri(liste), ['2']);
    await t.pumpWidget(ekran(liste));
    await t.pumpAndSettle();
    expect(find.byIcon(Icons.close_rounded), findsNothing);
    expect(find.text('Hizmet Ekle'), findsOneWidget);
  });
}

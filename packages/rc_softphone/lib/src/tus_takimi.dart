import 'package:flutter/material.dart';
import 'package:sip_ua/sip_ua.dart';

import 'sip_service.dart';

/// Numara cevirme ekrani: kayit durumu + numara alani + tus takimi + ara.
/// Arama baslayinca SipService arama ekranini kendisi acar.
class TusTakimiEkrani extends StatefulWidget {
  const TusTakimiEkrani({super.key, this.baslangicNumara = ''});

  final String baslangicNumara;

  @override
  State<TusTakimiEkrani> createState() => _TusTakimiEkraniState();
}

class _TusTakimiEkraniState extends State<TusTakimiEkrani> {
  final SipService _sip = SipService.instance;
  late final TextEditingController _numara =
      TextEditingController(text: widget.baslangicNumara);
  bool _araniyor = false;

  @override
  void dispose() {
    _numara.dispose();
    super.dispose();
  }

  void _ekle(String t) {
    _numara.text += t;
    setState(() {});
  }

  void _sil() {
    if (_numara.text.isEmpty) return;
    _numara.text = _numara.text.substring(0, _numara.text.length - 1);
    setState(() {});
  }

  Future<void> _ara() async {
    final String n = _numara.text.trim();
    if (n.isEmpty || _araniyor) return;
    setState(() => _araniyor = true);
    final bool ok = await _sip.cagriBaslat(n);
    if (!mounted) return;
    setState(() => _araniyor = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_sip.registered
            ? 'Arama başlatılamadı (devam eden bir arama olabilir).'
            : 'Santrale bağlı değil. Dahili bilgisi ve internet bağlantısını kontrol edin.'),
        backgroundColor: Colors.redAccent,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tuş Takımı'),
        actions: const <Widget>[KayitDurumuRozeti(), SizedBox(width: 12)],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            children: <Widget>[
              const Spacer(),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _numara,
                      readOnly: true,
                      showCursor: false,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 30, letterSpacing: 1.5),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Numara',
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _numara.text.isEmpty ? null : _sil,
                    icon: const Icon(Icons.backspace_outlined),
                    tooltip: 'Sil',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TusIzgarasi(onTus: _ekle),
              const SizedBox(height: 24),
              ValueListenableBuilder<bool>(
                valueListenable: _sip.kayitli,
                builder: (_, bool kayitli, __) => Material(
                  color: kayitli ? Colors.green : Colors.grey,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: kayitli && !_araniyor ? _ara : null,
                    child: SizedBox(
                      width: 72,
                      height: 72,
                      child: _araniyor
                          ? const Padding(
                              padding: EdgeInsets.all(22),
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5),
                            )
                          : const Icon(Icons.call, color: Colors.white, size: 34),
                    ),
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

/// 3x4 tus izgarasi (tus takimi ve arama ici DTMF ortak).
class TusIzgarasi extends StatelessWidget {
  const TusIzgarasi({super.key, required this.onTus, this.koyu = false});

  final ValueChanged<String> onTus;
  final bool koyu;

  static const List<List<String>> _tuslar = <List<String>>[
    <String>['1', ''],
    <String>['2', 'ABC'],
    <String>['3', 'DEF'],
    <String>['4', 'GHI'],
    <String>['5', 'JKL'],
    <String>['6', 'MNO'],
    <String>['7', 'PQRS'],
    <String>['8', 'TUV'],
    <String>['9', 'WXYZ'],
    <String>['*', ''],
    <String>['0', '+'],
    <String>['#', ''],
  ];

  @override
  Widget build(BuildContext context) {
    final Color yazi = koyu ? Colors.white : Theme.of(context).colorScheme.onSurface;
    final Color zemin = koyu
        ? Colors.white.withValues(alpha: 0.12)
        : Theme.of(context).colorScheme.surfaceContainerHighest;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        mainAxisSpacing: 14,
        crossAxisSpacing: 22,
        childAspectRatio: 1.25,
        children: _tuslar
            .map((List<String> t) => Material(
                  color: zemin,
                  shape: const StadiumBorder(),
                  child: InkWell(
                    customBorder: const StadiumBorder(),
                    onTap: () => onTus(t[0]),
                    onLongPress: t[0] == '0' ? () => onTus('+') : null,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(t[0],
                            style: TextStyle(
                                color: yazi, fontSize: 26, fontWeight: FontWeight.w500)),
                        if (t[1].isNotEmpty)
                          Text(t[1],
                              style: TextStyle(
                                  color: yazi.withValues(alpha: 0.6), fontSize: 10)),
                      ],
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

/// Santral kayit durumu: yesil = kayitli, turuncu = baglaniyor, kirmizi = yok.
class KayitDurumuRozeti extends StatelessWidget {
  const KayitDurumuRozeti({super.key});

  @override
  Widget build(BuildContext context) {
    final SipService sip = SipService.instance;
    return ValueListenableBuilder<RegistrationStateEnum?>(
      valueListenable: sip.registrationState,
      builder: (_, RegistrationStateEnum? s, __) {
        late final Color renk;
        late final String metin;
        switch (s) {
          case RegistrationStateEnum.REGISTERED:
            renk = Colors.green;
            metin = 'Bağlı';
            break;
          case RegistrationStateEnum.REGISTRATION_FAILED:
            renk = Colors.red;
            metin = 'Kayıt hatası';
            break;
          case RegistrationStateEnum.UNREGISTERED:
            renk = Colors.red;
            metin = 'Bağlı değil';
            break;
          default:
            renk = Colors.orange;
            metin = 'Bağlanıyor';
        }
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.circle, size: 10, color: renk),
            const SizedBox(width: 6),
            Text(metin, style: const TextStyle(fontSize: 13)),
          ],
        );
      },
    );
  }
}

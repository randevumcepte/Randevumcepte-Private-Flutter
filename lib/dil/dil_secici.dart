import 'package:flutter/material.dart';

import 'dil.dart';

/// Dil listesi (alttan açılır). Diller kendi adıyla yazılır; seçilince uygulama anında o dile geçer.
Future<void> dilSeciciAc(BuildContext context, {Color? renk}) async {
  if (!Dil.acik) return;
  final ana = renk ?? Theme.of(context).colorScheme.primary;
  final secilen = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (c) => SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.language_rounded, color: ana, size: 22),
              const SizedBox(width: 8),
              Text(Dil.kod == 'tr' ? 'Dil seçin · Language' : '${Dil.cevir('Dil seçin')} · Language',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 12),
            for (final d in Dil.diller)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: d.kod == Dil.kod ? ana.withValues(alpha: 0.10) : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: d.kod == Dil.kod ? ana : Colors.grey.withValues(alpha: 0.25)),
                    ),
                    leading: Text(d.bayrak, style: const TextStyle(fontSize: 26)),
                    title: Text(d.ad, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    trailing: d.kod == Dil.kod ? Icon(Icons.check_circle_rounded, color: ana) : null,
                    onTap: () => Navigator.pop(c, d.kod),
                  ),
                ),
              ),
          ]),
        ),
      ),
    ),
  );
  if (secilen != null) await Dil.sec(secilen);
}

/// Giriş öncesi ekranların sağ üstündeki dil düğmesi (🌐 TR). Salonda dil seçimi kapalıysa görünmez.
class DilDugmesi extends StatelessWidget {
  final Color? renk;
  const DilDugmesi({super.key, this.renk});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: Dil.degisim,
      builder: (context, kod, _) {
        if (!Dil.acik) return const SizedBox.shrink();
        final ana = renk ?? Theme.of(context).colorScheme.primary;
        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Semantics(
            button: true,
            label: 'Language',
            child: Material(
              color: Colors.white,
              elevation: 3,
              shadowColor: Colors.black26,
              borderRadius: BorderRadius.circular(22),
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () => dilSeciciAc(context, renk: ana),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.language_rounded, size: 20, color: ana),
                    const SizedBox(width: 6),
                    Text(Dil.kod.toUpperCase(), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ana)),
                    Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: ana),
                  ]),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Telefonun dili Türkçe değilse ilk açılışta bir kez dil sorulur.
Future<void> ilkAcilistaDilSor(BuildContext context, {Color? renk}) async {
  if (!Dil.acik || Dil.soruldu) return;
  final cihaz = Dil.cihazDili();
  if (cihaz == null || cihaz == 'tr') return;
  await Dil.sec(cihaz, kaydet: false); // ekran telefonun dilinde açılır; kişi listeden değiştirebilir
  if (context.mounted) await dilSeciciAc(context, renk: renk);
}

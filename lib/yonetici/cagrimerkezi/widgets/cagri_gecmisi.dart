// Bir musterinin gecmis gorusmeleri + ses kaydi oynatici.
// santralraporlari.dart'taki audioplayers desenini izler.

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import 'package:randevu_sistem/theme/app_tokens.dart';
import '../cagri_api.dart';
import '../cagri_models.dart';

class CagriGecmisiWidget extends StatefulWidget {
  final int aranacakMusteriId;
  final String sube;

  const CagriGecmisiWidget({
    super.key,
    required this.aranacakMusteriId,
    required this.sube,
  });

  @override
  State<CagriGecmisiWidget> createState() => CagriGecmisiWidgetState();
}

class CagriGecmisiWidgetState extends State<CagriGecmisiWidget> {
  final AudioPlayer _player = AudioPlayer();
  String? _calanUrl;
  List<CagriGecmis> _gecmis = [];
  bool _yukleniyor = true;
  String? _hata;

  @override
  void initState() {
    super.initState();
    yukle();
  }

  @override
  void didUpdateWidget(covariant CagriGecmisiWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.aranacakMusteriId != widget.aranacakMusteriId) {
      _player.stop();
      _calanUrl = null;
      yukle();
    }
  }

  Future<void> yukle() async {
    setState(() {
      _yukleniyor = true;
      _hata = null;
    });
    try {
      final g = await CagriApi.musteriGecmisi(widget.aranacakMusteriId, widget.sube);
      if (mounted) {
        setState(() {
          _gecmis = g;
          _yukleniyor = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hata = '$e';
          _yukleniyor = false;
        });
      }
    }
  }

  Future<void> _oynatDurdur(String url) async {
    try {
      if (_calanUrl == url) {
        await _player.stop();
        if (mounted) setState(() => _calanUrl = null);
        return;
      }
      await _player.stop();
      await _player.play(UrlSource(Uri.encodeFull(url)));
      if (mounted) setState(() => _calanUrl = url);
      _player.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _calanUrl = null);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ses kaydı oynatılamadı')),
        );
      }
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Color _sonucRenk(int? kod) {
    final ext = context.appTheme;
    switch (kod) {
      case CagriDurum.gorusuldu:
      case CagriDurum.arandi:
        return ext.successColor;
      case CagriDurum.telefondaSatis:
        return ext.successColor;
      case CagriDurum.onGorusme:
      case CagriDurum.tekrarAranacak:
        return ext.infoColor;
      case CagriDurum.cevapsiz:
      case CagriDurum.mesgul:
        return ext.warningColor;
      case CagriDurum.ulasilamadi:
        return Colors.redAccent;
      default:
        return context.colors.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final ext = context.appTheme;

    if (_yukleniyor) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_hata != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: ext.warningColor, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text('Geçmiş yüklenemedi', style: TextStyle(color: cs.onSurfaceVariant))),
            TextButton(onPressed: yukle, child: const Text('Tekrar')),
          ],
        ),
      );
    }
    if (_gecmis.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text('Henüz görüşme kaydı yok',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _gecmis.map((g) {
        final renk = _sonucRenk(g.sonucKod);
        final caliyor = g.ses.isNotEmpty && _calanUrl == g.ses;
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: ext.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: renk.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(g.sonuc,
                        style: TextStyle(
                            fontSize: 11.5, fontWeight: FontWeight.w700, color: renk)),
                  ),
                  const Spacer(),
                  Text(g.tarih,
                      style: TextStyle(fontSize: 11.5, color: cs.onSurfaceVariant)),
                ],
              ),
              if (g.not.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(g.not, style: TextStyle(fontSize: 13, color: cs.onSurface)),
              ],
              if (g.randevuTarih.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.event, size: 14, color: ext.infoColor),
                    const SizedBox(width: 4),
                    Text('${g.randevuTarih} ${g.randevuSaat}',
                        style: TextStyle(fontSize: 12, color: ext.infoColor)),
                  ],
                ),
              ],
              if (g.satisTutari != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.payments_outlined, size: 14, color: ext.successColor),
                    const SizedBox(width: 4),
                    Text('${g.satisTutari!.toStringAsFixed(2)} ₺',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: ext.successColor)),
                  ],
                ),
              ],
              if (g.ses.isNotEmpty) ...[
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _oynatDurdur(g.ses),
                  borderRadius: BorderRadius.circular(99),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(caliyor ? Icons.stop_circle : Icons.play_circle_fill,
                            size: 20, color: cs.primary),
                        const SizedBox(width: 6),
                        Text(caliyor ? 'Durdur' : 'Ses Kaydını Dinle',
                            style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: cs.primary)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}

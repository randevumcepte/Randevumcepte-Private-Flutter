// Arama listesi detay — secili listenin musteri kuyrugu.
// Her musteri: durum, not, ARA (click-to-call), Sonuc kaydet, Cagri gecmisi.

import 'package:flutter/material.dart';

import 'package:randevu_sistem/theme/app_tokens.dart';
import 'cagri_api.dart';
import 'cagri_models.dart';
import 'widgets/sonuc_formu.dart';
import 'widgets/cagri_gecmisi.dart';

class AramaListeDetayEkrani extends StatefulWidget {
  final int aramaId;
  final String baslik;
  final String sube;
  final int kullanicirolu;

  const AramaListeDetayEkrani({
    super.key,
    required this.aramaId,
    required this.baslik,
    required this.sube,
    required this.kullanicirolu,
  });

  @override
  State<AramaListeDetayEkrani> createState() => _AramaListeDetayEkraniState();
}

class _AramaListeDetayEkraniState extends State<AramaListeDetayEkrani> {
  final ScrollController _scroll = ScrollController();
  final List<AranacakMusteri> _musteriler = [];
  int _page = 1;
  int _total = 0;
  bool _yukleniyor = false;
  bool _ilkYukleme = true;
  bool get _dahaVar => _musteriler.length < _total;

  @override
  void initState() {
    super.initState();
    _yukle(ilk: true);
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
        if (!_yukleniyor && _dahaVar) _yukle();
      }
    });
  }

  Future<void> _yukle({bool ilk = false}) async {
    if (_yukleniyor) return;
    setState(() => _yukleniyor = true);
    try {
      if (ilk) {
        _page = 1;
        _musteriler.clear();
      }
      final res = await CagriApi.listeDetay(widget.aramaId, widget.sube,
          page: _page, perPage: 50);
      if (!mounted) return;
      setState(() {
        _total = res.total;
        _musteriler.addAll(res.data);
        _page++;
        _yukleniyor = false;
        _ilkYukleme = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _yukleniyor = false;
        _ilkYukleme = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Liste yüklenemedi: $e')),
      );
    }
  }

  Future<void> _yenile() async => _yukle(ilk: true);

  Color _durumRenk(int? kod) {
    final ext = context.appTheme;
    switch (kod) {
      case CagriDurum.gorusuldu:
      case CagriDurum.arandi:
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

  void _detayAc(AranacakMusteri m) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MusteriDetaySheet(
        musteri: m,
        aramaId: widget.aramaId,
        sube: widget.sube,
        onDegisti: _yenile,
      ),
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final ext = context.appTheme;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        foregroundColor: cs.onSurface,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.baslik,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            if (_total > 0)
              Text('${_musteriler.length}/$_total müşteri',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          ],
        ),
        actions: [
          IconButton(onPressed: _yenile, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _ilkYukleme
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _yenile,
              child: _musteriler.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 120),
                        Icon(Icons.inbox_outlined, size: 56, color: ext.borderStrong),
                        const SizedBox(height: 12),
                        Center(
                          child: Text('Bu listede müşteri yok',
                              style: TextStyle(color: cs.onSurfaceVariant)),
                        ),
                      ],
                    )
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                      itemCount: _musteriler.length + (_dahaVar ? 1 : 0),
                      itemBuilder: (context, i) {
                        if (i >= _musteriler.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final m = _musteriler[i];
                        final renk = _durumRenk(m.durumKod);
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: cs.surface,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: ext.borderSubtle),
                          ),
                          child: ListTile(
                            onTap: () => _detayAc(m),
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            title: Text(m.ad,
                                style: const TextStyle(
                                    fontSize: 14.5, fontWeight: FontWeight.w600)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: renk.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(99),
                                      ),
                                      child: Text(m.durum,
                                          style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: renk)),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(m.telefonGizlenmis,
                                        style: TextStyle(
                                            fontSize: 12, color: cs.onSurfaceVariant)),
                                  ],
                                ),
                                if (m.not.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(m.not,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontSize: 12, color: cs.onSurfaceVariant)),
                                ],
                              ],
                            ),
                            trailing: _AraButon(
                              aranacakMusteriId: m.aranacakMusteriId,
                              sube: widget.sube,
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

/// Click-to-call butonu. Bria dahilisini caldirir.
class _AraButon extends StatefulWidget {
  final int aranacakMusteriId;
  final String sube;
  const _AraButon({required this.aranacakMusteriId, required this.sube});

  @override
  State<_AraButon> createState() => _AraButonState();
}

class _AraButonState extends State<_AraButon> {
  bool _araniyor = false;

  Future<void> _ara() async {
    setState(() => _araniyor = true);
    try {
      final sonuc = await CagriApi.aramaBaslat(widget.aranacakMusteriId, widget.sube);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(sonuc.message.isNotEmpty
              ? sonuc.message
              : (sonuc.success ? 'Arama başlatıldı' : 'Arama başlatılamadı')),
          backgroundColor: sonuc.success ? null : Colors.redAccent,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Arama hatası: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _araniyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ext = context.appTheme;
    return Material(
      color: ext.successColor,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: _araniyor ? null : _ara,
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: _araniyor
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.call, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

/// Musteri detay alt sayfasi: ARA, Sonuc kaydet, Cagri gecmisi.
class _MusteriDetaySheet extends StatelessWidget {
  final AranacakMusteri musteri;
  final int aramaId;
  final String sube;
  final Future<void> Function() onDegisti;

  const _MusteriDetaySheet({
    required this.musteri,
    required this.aramaId,
    required this.sube,
    required this.onDegisti,
  });

  /// Memnuniyet anketi (tek tik). Web musteri-detay "Anket Gonder" ile ayni:
  /// onay -> varsayilan sablon WA-first/SMS ile gonderilir, sablon secimi yok.
  Future<void> _anketGonder(BuildContext context) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Memnuniyet anketi gönderilsin mi?'),
        content: const Text(
            'Müşteriye anket linki WhatsApp veya SMS ile gönderilecek.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Vazgeç')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Evet, gönder')),
        ],
      ),
    );
    if (onay != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      final res = await CagriApi.anketGonder(
          aranacakMusteriId: musteri.aranacakMusteriId, sube: sube);
      final basarili = res['basarili'] == true;
      final kanal = res['kanal'] == 'whatsapp' ? 'WhatsApp' : 'SMS';
      messenger.showSnackBar(SnackBar(
        content: Text(basarili
            ? 'Anket $kanal ile gönderildi.'
            : (res['mesaj']?.toString() ?? 'Anket gönderilemedi.')),
        backgroundColor: basarili ? null : Colors.redAccent,
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
          content: Text('Anket gönderilemedi: $e'),
          backgroundColor: Colors.redAccent));
    }
  }

  /// WhatsApp mesaj compose sayfasi (web musteri-detay modaliyla ayni: serbest metin).
  void _whatsappAc(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WhatsAppComposeSheet(
        aranacakMusteriId: musteri.aranacakMusteriId,
        ad: musteri.ad,
        telefonGizlenmis: musteri.telefonGizlenmis,
        sube: sube,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final ext = context.appTheme;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scroll) => Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                  color: ext.borderStrong, borderRadius: BorderRadius.circular(99)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: cs.primary.withValues(alpha: 0.12),
                    child: Icon(Icons.person, color: cs.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(musteri.ad,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                        Text(musteri.telefonGizlenmis,
                            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final kayit = await CagriApi.aramaBaslat(
                            musteri.aranacakMusteriId, sube);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(kayit.message.isNotEmpty
                                ? kayit.message
                                : 'Arama başlatıldı'),
                            duration: const Duration(seconds: 5),
                          ),
                        );
                      },
                      icon: Icon(Icons.call, color: ext.successColor),
                      label: const Text('Ara (Bria)'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                      ),
                      onPressed: () async {
                        final ok = await sonucFormuGoster(
                          context,
                          aramaDetayId: aramaId,
                          aranacakMusteriId: musteri.aranacakMusteriId,
                          musteriAd: musteri.ad,
                          sube: sube,
                          mevcutNot: musteri.not,
                        );
                        if (ok == true) {
                          await onDegisti();
                          if (context.mounted) Navigator.of(context).pop();
                        }
                      },
                      icon: const Icon(Icons.edit_note),
                      label: const Text('Sonuç'),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF128C7E),
                        side: const BorderSide(color: Color(0xFF25D366)),
                      ),
                      onPressed: () => _whatsappAc(context),
                      icon: const Icon(Icons.chat, size: 19),
                      label: const Text('WhatsApp'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: cs.primary,
                        side: BorderSide(color: cs.primary.withValues(alpha: 0.5)),
                      ),
                      onPressed: () => _anketGonder(context),
                      icon: const Icon(Icons.assignment_turned_in_outlined, size: 19),
                      label: const Text('Anket'),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Çağrı Geçmişi',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface)),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: CagriGecmisiWidget(
                  aranacakMusteriId: musteri.aranacakMusteriId,
                  sube: sube,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// WhatsApp mesaj compose alt sayfasi. Web musteri-detay modaliyle ayni:
/// serbest metin (max 1000) + karakter sayaci. Numara KVKK geregi maskeli gosterilir;
/// backend aranacak_musteri_id ile gercek numarayi cozup gonderir.
class _WhatsAppComposeSheet extends StatefulWidget {
  final int aranacakMusteriId;
  final String ad;
  final String telefonGizlenmis;
  final String sube;

  const _WhatsAppComposeSheet({
    required this.aranacakMusteriId,
    required this.ad,
    required this.telefonGizlenmis,
    required this.sube,
  });

  @override
  State<_WhatsAppComposeSheet> createState() => _WhatsAppComposeSheetState();
}

class _WhatsAppComposeSheetState extends State<_WhatsAppComposeSheet> {
  final TextEditingController _ctrl = TextEditingController();
  static const Color _wa = Color(0xFF25D366);
  bool _gonderiliyor = false;
  int _uzunluk = 0;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      if (_ctrl.text.length != _uzunluk) {
        setState(() => _uzunluk = _ctrl.text.length);
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _gonder() async {
    final mesaj = _ctrl.text.trim();
    if (mesaj.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen göndermek istediğiniz mesajı yazın.')),
      );
      return;
    }
    setState(() => _gonderiliyor = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final res = await CagriApi.whatsappGonder(
        aranacakMusteriId: widget.aranacakMusteriId,
        mesaj: mesaj,
        sube: widget.sube,
      );
      final ok = res['ok'] == true;
      if (!mounted) return;
      if (ok) Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(
        content: Text(res['mesaj']?.toString() ??
            (ok ? 'Mesaj gönderildi.' : 'Mesaj gönderilemedi.')),
        backgroundColor: ok ? null : Colors.redAccent,
        duration: const Duration(seconds: 4),
      ));
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
          content: Text('Mesaj gönderilemedi: $e'),
          backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _gonderiliyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final ext = context.appTheme;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                    color: ext.borderStrong,
                    borderRadius: BorderRadius.circular(99)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: _wa,
                    child: Icon(Icons.chat, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('WhatsApp Mesajı',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                        Text('${widget.ad} · ${widget.telefonGizlenmis}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 12.5, color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: TextField(
                controller: _ctrl,
                maxLines: 6,
                minLines: 4,
                maxLength: 1000,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Müşterinize göndermek istediğiniz mesajı yazın...',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md)),
                  counterText: '$_uzunluk / 1000',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _gonderiliyor
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Vazgeç'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _wa,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _gonderiliyor ? null : _gonder,
                      icon: _gonderiliyor
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.send, size: 18),
                      label: Text(
                          _gonderiliyor ? 'Gönderiliyor...' : "WhatsApp'tan Gönder"),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

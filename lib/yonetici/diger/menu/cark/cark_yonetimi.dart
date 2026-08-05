import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/yonetici/diger/sube_secici.dart';
import 'package:randevu_sistem/Frontend/aramali_dropdown.dart';

class CarkYonetimiPage extends StatefulWidget {
  final dynamic isletmebilgi;
  final int kullanicirolu;
  const CarkYonetimiPage({Key? key, required this.isletmebilgi, required this.kullanicirolu}) : super(key: key);

  @override
  State<CarkYonetimiPage> createState() => _CarkYonetimiPageState();
}

class _CarkYonetimiPageState extends State<CarkYonetimiPage> with TickerProviderStateMixin, WidgetsBindingObserver {
  late final TabController _tab;
  late final String _salonId;

  // Çark kurulumu
  bool _sistemLoading = false;
  int _carkAktif = 1;
  List<Map<String, dynamic>> _dilimler = [];
  // Çoklu şube: çarkın uygulanacağı şubeler (varsayılan: bulunulan şube)
  List<String> _seciliCarkSubeler = [];
  final GlobalKey<_CarkPreviewState> _carkKey = GlobalKey<_CarkPreviewState>();
  bool _ceviriliyor = false;
  Timer? _autoSyncTimer;
  late final ConfettiController _konfeti;
  final AudioPlayer _cheerPlayer = AudioPlayer();
  Uint8List? _cheerBytes;
  final ScrollController _carkScroll = ScrollController();

  // Kazananlar
  bool _kazLoading = false;
  Map<String, dynamic>? _kazData;
  String _kazFiltre = 'tumu';

  // Hatırlatma
  bool _hatLoading = false;
  Map<String, dynamic>? _hatData;

  // Puan Ödülleri
  bool _puanOdulLoading = false;
  List<Map<String, dynamic>> _puanOdulleri = [];

  // Kaydedilmemiş değişiklik var mı? (true ise otomatik sync yapılmaz — kullanıcının emeği silinmesin)
  bool _dilimDirty = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
    _salonId = widget.isletmebilgi['id'].toString();
    _seciliCarkSubeler = [_salonId];
    _konfeti = ConfettiController(duration: Duration(seconds: 3));
    // Runtime WAV ses byte'larını hazırla (web Audio API'nin Flutter karşılığı)
    _cheerBytes = _generateCheerWav();
    WidgetsBinding.instance.addObserver(this);
    _yukleSistem();
    // Sayfa açıkken her 15 saniyede bir hafif senkron (web'de değişiklik olursa anlamak için)
    _autoSyncTimer = Timer.periodic(Duration(seconds: 15), (_) {
      if (_tab.index == 0 && !_ceviriliyor && mounted) {
        _yukleSistemSessiz();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted && !_ceviriliyor) {
      // Uygulama arka plandan döndüğünde çarkı yenile
      _yukleSistemSessiz();
    }
  }

  @override
  void dispose() {
    _autoSyncTimer?.cancel();
    _konfeti.dispose();
    _cheerPlayer.dispose();
    _carkScroll.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _tab.dispose();
    super.dispose();
  }

  // ============= Runtime WAV ses üretici (web Audio API portu) =============

  /// Kazanma sesi: "ta-da" arpeggio + 3 konfeti pop + alkış (clap clap clap...) — ~2.4 sn mono.
  /// Hepsi runtime'da WAV byte olarak üretilir (asset gerektirmez).
  Uint8List _generateCheerWav() {
    const sr = 44100;
    const dur = 2.4; // saniye — alkışlara yer açmak için uzatıldı
    final n = (sr * dur).floor();
    final samples = Int16List(n);
    final rand = math.Random(42);

    // 5 nota: do-mi-sol-la-do (C major triad + 6th, yukarı doğru)
    final notalar = [
      {'ms': 0,   'f': 523.25},  // C5
      {'ms': 130, 'f': 659.25},  // E5
      {'ms': 260, 'f': 783.99},  // G5
      {'ms': 390, 'f': 880.00},  // A5
      {'ms': 520, 'f': 1046.50}, // C6 — uzun çalsın
    ];

    // Konfeti pop'ları: 3 adet, kısa yüksek frekans patlamalar
    // (mantıken konfeti atılırken "pop pop pop" sesi)
    final popZamanlari = [0.00, 0.10, 0.20]; // saniye
    // Her pop için rastgele tepe frekansı (1500-3000 Hz)
    final popFrekanslari = popZamanlari.map((_) => 1500.0 + rand.nextDouble() * 1500).toList();

    // Alkış patlamaları: 9 adet, kısa beyaz gürültü patlamaları (clap clap clap...)
    // 0.45 sn'den başlar, gittikçe yoğunlaşır, sonra yavaşlar (gerçek alkış ritmi)
    final clapZamanlari = [
      0.45, 0.62, 0.78, 0.92, 1.06, 1.22, 1.40, 1.62, 1.88,
    ];
    // Her alkış için rastgele güç (0.7-1.0) ve süre (60-110ms) — doğal seda
    final clapGucu = clapZamanlari.map((_) => 0.7 + rand.nextDouble() * 0.3).toList();
    final clapSuresi = clapZamanlari.map((_) => 0.06 + rand.nextDouble() * 0.05).toList();

    for (var i = 0; i < n; i++) {
      final t = i / sr;
      double s = 0;

      // ===== ARPEGGIO (mevcut "ta-da") =====
      for (var k = 0; k < notalar.length; k++) {
        final ms = (notalar[k]['ms'] as num).toDouble();
        final f = (notalar[k]['f'] as num).toDouble();
        final nt = t - ms / 1000;
        if (nt < 0) continue;
        final notaUzun = (k == notalar.length - 1) ? 0.95 : 0.30;
        if (nt > notaUzun) continue;
        double g;
        if (nt < 0.03) {
          g = (nt / 0.03) * 0.40;
        } else {
          final decT = (nt - 0.03) / (notaUzun - 0.03);
          g = 0.40 * math.exp(-decT * 3.5);
        }
        s += math.sin(2 * math.pi * f * nt) * g;
        s += math.sin(2 * math.pi * f * 2 * nt) * g * 0.12;
      }

      // ===== KONFETI POP'LARI =====
      for (var p = 0; p < popZamanlari.length; p++) {
        final dt = t - popZamanlari[p];
        if (dt < 0 || dt > 0.08) continue;
        // Hızlı attack + exp decay, yüksek frekans
        final env = math.exp(-dt * 50);
        final f = popFrekanslari[p];
        // Frekans hızla düşer (pitch-down efekti)
        final freqMod = f * (1 - dt * 8).clamp(0.3, 1.0);
        s += math.sin(2 * math.pi * freqMod * dt) * env * 0.35;
      }

      // ===== ALKIŞ (filtered noise burst'ler) =====
      for (var c = 0; c < clapZamanlari.length; c++) {
        final dt = t - clapZamanlari[c];
        final maxSure = clapSuresi[c];
        if (dt < 0 || dt > maxSure) continue;
        // Çok hızlı attack (3ms), exp decay
        double clapEnv;
        if (dt < 0.003) {
          clapEnv = (dt / 0.003) * clapGucu[c];
        } else {
          clapEnv = clapGucu[c] * math.exp(-(dt - 0.003) / (maxSure * 0.35));
        }
        // Beyaz gürültü (band-limited, yüksek frekanslı)
        final noise = rand.nextDouble() * 2 - 1;
        s += noise * clapEnv * 0.30;
      }

      samples[i] = (s.clamp(-1.0, 1.0) * 32767).round();
    }

    return _wrapWav(samples, sampleRate: sr, channels: 1);
  }

  Uint8List _wrapWav(Int16List samples, {required int sampleRate, required int channels}) {
    final dataLen = samples.length * 2;
    final fileSize = 36 + dataLen;
    final byteRate = sampleRate * channels * 2;
    final blockAlign = channels * 2;

    final bb = BytesBuilder();
    bb.add(ascii.encode('RIFF'));
    bb.add(_le32(fileSize));
    bb.add(ascii.encode('WAVE'));
    bb.add(ascii.encode('fmt '));
    bb.add(_le32(16));
    bb.add(_le16(1));        // PCM
    bb.add(_le16(channels));
    bb.add(_le32(sampleRate));
    bb.add(_le32(byteRate));
    bb.add(_le16(blockAlign));
    bb.add(_le16(16));       // bits per sample
    bb.add(ascii.encode('data'));
    bb.add(_le32(dataLen));
    // PCM data little-endian
    final pcm = Uint8List(dataLen);
    final bd = ByteData.view(pcm.buffer);
    for (var i = 0; i < samples.length; i++) {
      bd.setInt16(i * 2, samples[i], Endian.little);
    }
    bb.add(pcm);
    return bb.takeBytes();
  }

  List<int> _le16(int v) => [v & 0xFF, (v >> 8) & 0xFF];
  List<int> _le32(int v) => [v & 0xFF, (v >> 8) & 0xFF, (v >> 16) & 0xFF, (v >> 24) & 0xFF];

  /// Tick: sistem click sesi (audioplayers çok yavaş, native click anında çalar)
  Future<void> _playTick() async {
    SystemSound.play(SystemSoundType.click);
  }

  Future<void> _playCheer() async {
    if (_cheerBytes == null) return;
    try {
      await _cheerPlayer.stop();
      await _cheerPlayer.play(BytesSource(_cheerBytes!, mimeType: 'audio/wav'));
    } catch (_) {}
  }

  /// Loading spinner göstermeden sessizce yeniden çek (sync için).
  Future<void> _yukleSistemSessiz() async {
    // Kaydedilmemiş değişiklik varsa sync atlanır — kullanıcının emeği silinmesin
    if (_dilimDirty) return;
    final r = await carkAdminSistemGetir(_salonId);
    if (!mounted || r == null) return;
    final yeniDilimler = ((r['dilimler'] as List?) ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    if (yeniDilimler.isEmpty) return;
    // Sadece gerçekten değişiklik varsa state'i güncelle
    // (color field'ı diff'e dahil değil — Flutter otomatik atıyor)
    final farkVar = yeniDilimler.length != _dilimler.length ||
        yeniDilimler.asMap().entries.any((e) {
          final eski = e.key < _dilimler.length ? _dilimler[e.key] : null;
          if (eski == null) return true;
          return eski['name'] != e.value['name'] ||
              eski['probability'] != e.value['probability'] ||
              eski['tip'] != e.value['tip'] ||
              eski['deger'] != e.value['deger'];
        });
    if (!farkVar) return;
    setState(() {
      _carkAktif = (r['sistem']?['aktifmi'] as num?)?.toInt() ?? _carkAktif;
      _dilimler = yeniDilimler;
      // Stabil _uid ve otomatik renk
      for (final d in _dilimler) {
        d['_uid'] = d['_uid'] ?? _yeniUid();
      }
      _renkleriOtomatikAta();
      _kazananGarantile();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [Icon(Icons.sync, color: Colors.white, size: 16), SizedBox(width: 8), Text('Çark verisi güncellendi (web tarafından)')]),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.blue.shade700,
      ),
    );
  }

  int _uidCounter = 0;
  int _yeniUid() => ++_uidCounter;

  Future<void> _yukleSistem() async {
    setState(() => _sistemLoading = true);
    final r = await carkAdminSistemGetir(_salonId);
    if (!mounted) return;
    setState(() {
      if (r != null) {
        _carkAktif = (r['sistem']?['aktifmi'] as num?)?.toInt() ?? 1;
        _dilimler = ((r['dilimler'] as List?) ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
      if (_dilimler.isEmpty) _dilimler = _ornekDilimler();
      // Her dilime stabil bir _uid ata (yoksa) — TextField state korunması için
      for (final d in _dilimler) {
        d['_uid'] = d['_uid'] ?? _yeniUid();
      }
      // Renkleri otomatik ata (index sırasına göre) — web ile aynı davranış
      _renkleriOtomatikAta();
      // Hiç kazanan yoksa ilk dilim kazanan olsun
      _kazananGarantile();
      _sistemLoading = false;
      _dilimDirty = false;
    });
  }

  List<Map<String, dynamic>> _ornekDilimler() => [
        {'name': '100 Puan', 'probability': 100, 'color': _renkler[0], 'tip': 'puan', 'deger': 100, 'kupon_mu': 0},
        {'name': '%20 Hizmet', 'probability': 0, 'color': _renkler[1], 'tip': 'hizmet_indirimi', 'deger': 20, 'indirim_tipi': 'yuzde', 'kupon_mu': 1},
        {'name': '%10 Ürün', 'probability': 0, 'color': _renkler[2], 'tip': 'urun_indirimi', 'deger': 10, 'indirim_tipi': 'yuzde', 'kupon_mu': 1},
        {'name': '50 Puan', 'probability': 0, 'color': _renkler[3], 'tip': 'puan', 'deger': 50, 'kupon_mu': 0},
        {'name': 'Tekrar Dene', 'probability': 0, 'color': _renkler[4], 'tip': 'tekrar_dene', 'deger': null, 'kupon_mu': 0},
        {'name': 'Boş', 'probability': 0, 'color': _renkler[5], 'tip': 'bos', 'deger': null, 'kupon_mu': 0},
      ];

  Future<void> _yukleKazananlar() async {
    setState(() => _kazLoading = true);
    final r = await carkAdminKazananlar(_salonId, filtre: _kazFiltre);
    if (!mounted) return;
    setState(() {
      _kazData = r;
      _kazLoading = false;
    });
  }

  Future<void> _yukleHatirlatma() async {
    if (_hatData != null) return;
    setState(() => _hatLoading = true);
    final r = await carkAdminHatirlatmaGetir(_salonId);
    if (!mounted) return;
    setState(() {
      _hatData = r;
      _hatLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Color.alphaBlend(scheme.primary.withValues(alpha: 0.32), Colors.white),
            Color.alphaBlend(scheme.tertiary.withValues(alpha: 0.06), Colors.white),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: scheme.onSurface),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Çark-ı Felek',
            style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w800, fontSize: 22, letterSpacing: -0.3),
          ),
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(56),
            child: Container(
              margin: EdgeInsets.fromLTRB(12, 0, 12, 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: scheme.primary.withValues(alpha: 0.05), blurRadius: 12, offset: Offset(0, 4))],
              ),
              child: TabBar(
                controller: _tab,
                indicatorColor: scheme.primary,
                indicatorWeight: 3,
                labelColor: scheme.primary,
                unselectedLabelColor: Colors.grey,
                labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                isScrollable: true,
                tabs: [
                  Tab(icon: Icon(Icons.casino, size: 20), text: 'Çark'),
                  Tab(icon: Icon(Icons.card_giftcard, size: 20), text: 'Kazananlar'),
                  Tab(icon: Icon(Icons.stars_rounded, size: 20), text: 'Puan Ödülleri'),
                  Tab(icon: Icon(Icons.notifications_active, size: 20), text: 'Hatırlatma'),
                ],
                onTap: (i) {
                  if (i == 1) _yukleKazananlar();
                  if (i == 2) _yuklePuanOdulleri();
                  if (i == 3) _yukleHatirlatma();
                },
              ),
            ),
          ),
        ),
        body: TabBarView(
          controller: _tab,
          children: [
            _carkTab(scheme),
            _kazananlarTab(scheme),
            _puanOdulleriTab(scheme),
            _hatirlatmaTab(scheme),
          ],
        ),
      ),
    );
  }

  // ============ CARK TAB ============

  Widget _carkTab(ColorScheme scheme) {
    if (_sistemLoading) return Center(child: CircularProgressIndicator());

    final kazanan = _dilimler.where((d) => ((d['probability'] as num?)?.toInt() ?? 0) == 100).length;
    final yeterli = _dilimler.length >= 6;
    final maksOk = _dilimler.length <= 12;
    final valid = kazanan == 1 && yeterli && maksOk;

    return ListView(
      controller: _carkScroll,
      padding: EdgeInsets.fromLTRB(12, 12, 12, 100),
      children: [
        // Görsel çark (web tarzı: koyu zemin + conic-gradient glow ring)
        Stack(
          alignment: Alignment.topCenter,
          children: [
            Container(
              height: 340,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                // Hero gradient — web'deki ck-hero ile aynı (purple → pink)
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF6c5ce7),
                    Color(0xFFa29bfe),
                    Color(0xFFfd79a8),
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Color(0xFF6c5ce7).withValues(alpha: 0.45), blurRadius: 28, offset: Offset(0, 8)),
                ],
              ),
              child: _CarkPreview(key: _carkKey, dilimler: _dilimler, onTick: _playTick),
            ),
            // Konfeti: çarkın üstünden aşağı doğru dökülür
            Positioned(
              top: 0,
              child: ConfettiWidget(
                confettiController: _konfeti,
                blastDirection: math.pi / 2, // aşağı yön
                blastDirectionality: BlastDirectionality.explosive,
                maxBlastForce: 18,
                minBlastForce: 6,
                emissionFrequency: 0.06,
                numberOfParticles: 18,
                gravity: 0.2,
                shouldLoop: false,
                colors: const [
                  Colors.amber,
                  Colors.pinkAccent,
                  Colors.lightBlueAccent,
                  Colors.greenAccent,
                  Colors.deepPurpleAccent,
                  Colors.orangeAccent,
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 10),

        // Test Çevir butonu (büyük, çarkın hemen altında)
        ElevatedButton.icon(
          onPressed: (_dilimler.length >= 6 && !_ceviriliyor) ? _testCevir : null,
          icon: _ceviriliyor
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                )
              : Icon(Icons.refresh, size: 22),
          label: Text(
            _ceviriliyor ? 'Çark dönüyor...' : 'Test Çevir',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 0.3),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber.shade700,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            disabledBackgroundColor: Colors.grey.shade400,
            elevation: 3,
            shadowColor: Colors.amber.withValues(alpha: 0.4),
          ),
        ),
        SizedBox(height: 14),

        // Aktif/Pasif + doğrulama
        Container(
          padding: EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: scheme.primary.withValues(alpha: 0.04), blurRadius: 12, offset: Offset(0, 3))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                value: _carkAktif == 1,
                title: Text('Çark Aktif', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('Pasifken müşteriler çark çeviremez', style: TextStyle(fontSize: 11)),
                onChanged: (v) async {
                  setState(() => _carkAktif = v ? 1 : 0);
                  await carkAdminAktifToggle(_salonId, v);
                },
                contentPadding: EdgeInsets.zero,
              ),
              Divider(),
              Row(
                children: [
                  Icon(valid ? Icons.check_circle : Icons.warning_amber, color: valid ? Colors.green : Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      valid
                          ? 'Hazır: ${_dilimler.length} dilim · 1 kazanan seçildi'
                          : 'Eksik: ${!yeterli ? "En az 6 dilim olmalı (şu an ${_dilimler.length}). " : ""}'
                              '${!maksOk ? "En fazla 12 dilim olabilir (şu an ${_dilimler.length}). " : ""}'
                              '${kazanan != 1 ? "Tam 1 kazanan dilim seçilmeli (şu an $kazanan)." : ""}',
                      style: TextStyle(fontSize: 12, color: valid ? Colors.green.shade700 : Colors.orange.shade700, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 12),

        // Hızlı yardım butonu — eksik dilim doldur + ilk dilimi kazanan yap
        if (!valid && (!yeterli || kazanan != 1))
          Container(
            margin: EdgeInsets.only(bottom: 12),
            child: OutlinedButton.icon(
              onPressed: _otomatikDuzelt,
              icon: Icon(Icons.auto_fix_high),
              label: Text(!yeterli ? 'Eksik Dilimleri Tamamla (6\'ya getir)' : 'İlk Dilimi Kazanan Yap'),
              style: OutlinedButton.styleFrom(
                foregroundColor: scheme.primary,
                side: BorderSide(color: scheme.primary),
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

        // Dilim başlığı + Ekle
        Row(
          children: [
            Text('Dilimler (${_dilimler.length})', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            if (_dilimDirty) ...[
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade400),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit, size: 11, color: Colors.orange.shade800),
                    SizedBox(width: 4),
                    Text('Kaydedilmedi',
                        style: TextStyle(fontSize: 10, color: Colors.orange.shade800, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
            Spacer(),
            TextButton.icon(
              onPressed: _dilimEkle,
              icon: Icon(Icons.add_circle, size: 18),
              label: Text('Ekle'),
            ),
          ],
        ),
        SizedBox(height: 4),

        // Dilim listesi — key olarak stabil _uid (ekleme/silme'de TextField korunur)
        ..._dilimler.asMap().entries.map((e) {
          final uid = e.value['_uid'] ?? e.key;
          return _DilimSatiri(
            key: ValueKey('dilim_$uid'),
            index: e.key,
            dilim: e.value,
            onSil: () => setState(() {
              _dilimler.removeAt(e.key);
              _renkleriOtomatikAta();
              _kazananGarantile();
              _dilimDirty = true;
            }),
            onDegisti: () => setState(() => _dilimDirty = true),
            onKazan: () => _kazananYap(e.key),
          );
        }),

        SizedBox(height: 16),

        // Çoklu şube: çark hangi şubelere uygulanacak (tek şubede gizli)
        SubeCokluSecici(
          aktifSalonId: _salonId,
          baslik: 'Çark hangi şubelere uygulanacak?',
          onChanged: (ids) => _seciliCarkSubeler = ids,
        ),

        // Kaydet
        ElevatedButton.icon(
          onPressed: valid ? _kaydet : null,
          icon: Icon(Icons.save),
          label: Text('Çarkı Kaydet'),
          style: ElevatedButton.styleFrom(
            backgroundColor: scheme.primary,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            disabledBackgroundColor: Colors.grey.shade400,
          ),
        ),
        SizedBox(height: 10),

        // Müşterilere duyuru push'u
        OutlinedButton.icon(
          onPressed: (_carkAktif == 1 && !_dilimDirty) ? _duyuruGonderBottomSheet : null,
          icon: Icon(Icons.campaign_outlined),
          label: Text(
            _dilimDirty
                ? 'Önce çarkı kaydedin'
                : (_carkAktif == 1 ? 'Müşterilere Duyuru Gönder' : 'Çark pasif — duyuru gönderilemez'),
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.teal.shade700,
            side: BorderSide(color: Colors.teal.shade400, width: 1.5),
            padding: EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }

  void _dilimEkle() {
    setState(() {
      // Yeni dilimi en BAŞA ekle ki kullanıcı hemen görsün
      _dilimler.insert(0, {
        '_uid': _yeniUid(),
        'name': 'Ödül ${_dilimler.length + 1}',
        'probability': 0,
        'color': _renkler[0], // _renkleriOtomatikAta() index'e göre yeniden atayacak
        'tip': 'bos',
        'deger': null,
        'kupon_mu': 0,
      });
      // Tüm renkleri index'e göre yeniden ata (insert sonrası kaymalar için)
      _renkleriOtomatikAta();
      // Eğer önceki kazanan yer değiştirdiyse (index 0 oldu), kazanan'ı koru
      _kazananGarantile();
      _dilimDirty = true;
    });
    HapticFeedback.lightImpact();
    // Sayfayı dilim listesine kaydır (yeni dilim ekranda görünsün)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_carkScroll.hasClients) {
        // Dilim listesi yaklaşık 540 px civarında başlıyor (çark + butonlar + validasyon kartı)
        _carkScroll.animateTo(
          540,
          duration: Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  // Web tarafıyla birebir aynı renk paleti (carkifelek.blade.php COLORS)
  static const _renkler = [
    '#FF6B6B', '#FF8E53', '#FFC107', '#51CF66', '#339AF0',
    '#CC5DE8', '#F06595', '#74C0FC', '#63E6BE', '#FFD43B',
    '#FF922B', '#20C997', '#4DABF7', '#DA77F2', '#F783AC',
    '#E64980', '#7950F2', '#4C6EF5', '#228BE6', '#099268',
  ];

  /// Tüm dilim renklerini index'e göre paletten otomatik ata.
  void _renkleriOtomatikAta() {
    for (var i = 0; i < _dilimler.length; i++) {
      _dilimler[i]['color'] = _renkler[i % _renkler.length];
    }
  }

  /// Hiç kazanan yoksa ilk dilimi kazanan yap (web ile aynı davranış).
  void _kazananGarantile() {
    if (_dilimler.isEmpty) return;
    final varMi = _dilimler.any((d) => ((d['probability'] as num?)?.toInt() ?? 0) == 100);
    if (!varMi) {
      for (var i = 0; i < _dilimler.length; i++) {
        _dilimler[i]['probability'] = i == 0 ? 100 : 0;
      }
    }
  }

  /// Verilen index'i tek kazanan yap. Diğerleri 0.
  void _kazananYap(int index) {
    setState(() {
      for (var i = 0; i < _dilimler.length; i++) {
        _dilimler[i]['probability'] = i == index ? 100 : 0;
      }
      _dilimDirty = true;
    });
    HapticFeedback.selectionClick();
  }

  void _otomatikDuzelt() {
    setState(() {
      if (_dilimler.length < 6) {
        // 6'ya tamamla
        while (_dilimler.length < 6) {
          _dilimler.add({
            '_uid': _yeniUid(),
            'name': 'Ödül ${_dilimler.length + 1}',
            'probability': 0,
            'color': _renkler[0], // _renkleriOtomatikAta yeniden atayacak
            'tip': 'bos',
            'deger': null,
            'kupon_mu': 0,
          });
        }
      }
      // Renkleri index'e göre yeniden ata
      _renkleriOtomatikAta();
      // İlk dilim kazanan, diğerleri 0
      for (var i = 0; i < _dilimler.length; i++) {
        _dilimler[i]['probability'] = i == 0 ? 100 : 0;
      }
      _dilimDirty = true;
    });
  }

  Future<void> _testCevir() async {
    if (_dilimler.length < 6) return;

    // Gerçek olasılıklara göre dilim seç
    final rand = math.Random();
    final toplam = _dilimler.fold<int>(0, (s, d) => s + ((d['probability'] as num?)?.toInt() ?? 0));
    int hedefIndex = 0;
    if (toplam > 0) {
      final r = rand.nextInt(toplam);
      int kumulatif = 0;
      for (var i = 0; i < _dilimler.length; i++) {
        kumulatif += ((_dilimler[i]['probability'] as num?)?.toInt() ?? 0);
        if (r < kumulatif) {
          hedefIndex = i;
          break;
        }
      }
    } else {
      hedefIndex = rand.nextInt(_dilimler.length);
    }

    setState(() => _ceviriliyor = true);
    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.click);

    // Çark dönüş animasyonu (~4 saniye)
    await _carkKey.currentState?.cevirSonuc(hedefIndex);

    if (!mounted) return;
    setState(() => _ceviriliyor = false);
    HapticFeedback.heavyImpact();

    // Kazanma efekti: konfeti + alkış+arpeggio (web ile aynı)
    _konfeti.play();
    HapticFeedback.heavyImpact();
    _playCheer();

    final sec = _dilimler[hedefIndex];
    final color = _hexToColor(sec['color']?.toString());

    // Sonuç dialogu
    showDialog(
      context: context,
      builder: (c) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: Icon(Icons.celebration, color: color, size: 36),
              ),
              SizedBox(height: 12),
              Text('Çark Durdu!', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              SizedBox(height: 6),
              Text(
                sec['name']?.toString() ?? '-',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: color),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              if (sec['tip'] != null && sec['tip'] != 'bos')
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    _tipText(sec['tip']?.toString() ?? '', sec['deger'], sec['indirim_tipi']?.toString()),
                    style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
              SizedBox(height: 16),
              Text(
                'Bu bir simülasyondur. Gerçek dağıtımda olasılıklar geçerlidir.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(c),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('Tamam', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _tipText(String tip, dynamic deger, [String? indirimTipi]) {
    // İndirim değeri: tutar ise "50 ₺", değilse "%50"
    final tutar = indirimTipi == 'tutar';
    final ind = tutar ? '${deger ?? '?'} ₺' : '%${deger ?? '?'}';
    switch (tip) {
      case 'puan': return '+ ${deger ?? '?'} Puan';
      case 'hizmet_indirimi': return '$ind Hizmet İndirimi';
      case 'urun_indirimi': return '$ind Ürün İndirimi';
      case 'paket_indirimi': return '$ind Paket İndirimi';
      case 'tekrar_dene': return 'Tekrar Dene';
      default: return tip;
    }
  }

  Color _hexToColor(String? hex) {
    if (hex == null || hex.isEmpty) return Colors.purple;
    final h = hex.replaceAll('#', '');
    if (h.length != 6) return Colors.purple;
    return Color(int.parse('FF$h', radix: 16));
  }

  Future<void> _kaydet() async {
    final r = await carkAdminDilimKaydet(_salonId, _dilimler,
        aktifmi: _carkAktif, salonIds: _seciliCarkSubeler);
    if (!mounted) return;
    if (r != null && r['basarili'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Çark kaydedildi'), backgroundColor: Colors.green));
      _dilimDirty = false;
      _yukleSistem();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r?['mesaj'] ?? 'Kayıt hatası'), backgroundColor: Colors.red));
    }
  }

  // ============ DUYURU BOTTOM SHEET ============

  void _duyuruGonderBottomSheet() {
    final baslikCtrl = TextEditingController();
    final mesajCtrl = TextEditingController(
      text: 'Çark-ı Felek\'i çevir, sürpriz ödülü kap! Bugün şansını dene 🎁',
    );
    bool gonderiliyor = false;
    Map<String, dynamic>? sonuc;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSt) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(10)),
                          child: Icon(Icons.campaign, color: Colors.teal.shade700, size: 22),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Çark Duyurusu', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                              Text(
                                'Uygulaması yüklü tüm müşterilerinize push gönderilir',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),

                    // Sonuç gösterildi mi?
                    if (sonuc != null) ...[
                      _duyuruSonucKart(sonuc!),
                      SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(sheetCtx),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade700,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('Kapat', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ] else ...[
                      TextField(
                        controller: baslikCtrl,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          labelText: 'Başlık (boş bırakırsanız salon adı kullanılır)',
                          hintText: '🎡 Bugün şansını dene!',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          isDense: true,
                        ),
                      ),
                      SizedBox(height: 10),
                      TextField(
                        controller: mesajCtrl,
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: 3,
                        maxLength: 200,
                        decoration: InputDecoration(
                          labelText: 'Mesaj',
                          helperText: '{ad} ve {salon_adi} yerlerine müşteri adı ve salon adı yazılır',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      SizedBox(height: 6),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: gonderiliyor
                              ? null
                              : () async {
                                  setSt(() => gonderiliyor = true);
                                  final r = await carkAdminBildirimGonder(
                                    _salonId,
                                    baslik: baslikCtrl.text,
                                    mesaj: mesajCtrl.text,
                                  );
                                  if (!sheetCtx.mounted) return;
                                  setSt(() {
                                    sonuc = r ?? {'basarili': false, 'mesaj': 'Bağlantı hatası'};
                                    gonderiliyor = false;
                                  });
                                },
                          icon: gonderiliyor
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Icon(Icons.send),
                          label: Text(
                            gonderiliyor ? 'Gönderiliyor...' : 'Bildirimi Gönder',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade700,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            disabledBackgroundColor: Colors.teal.shade200,
                          ),
                        ),
                      ),
                    ],
                    SizedBox(height: 4),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      baslikCtrl.dispose();
      mesajCtrl.dispose();
    });
  }

  Widget _duyuruSonucKart(Map<String, dynamic> r) {
    final basarili = r['basarili'] == true;
    final gonderildi = (r['gonderildi'] as num?)?.toInt() ?? 0;
    final hata = (r['hata'] as num?)?.toInt() ?? 0;
    final hedef = (r['hedef'] as num?)?.toInt() ?? 0;
    final mesaj = r['mesaj']?.toString();

    if (!basarili) {
      return Container(
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade700),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                mesaj ?? 'Gönderim başarısız',
                style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    // 3 farklı durum: tam başarı / kısmi başarı / hiç gitmedi
    final tamBasari = gonderildi > 0 && hata == 0;
    final kismi = gonderildi > 0 && hata > 0;
    final hicGitmedi = gonderildi == 0 && hedef > 0;
    final hedefYok = hedef == 0;

    Color renkBg, renkBorder, renkIkonBg, renkBaslik;
    IconData ikon;
    String baslikText;

    if (tamBasari) {
      renkBg = Colors.green.shade50;
      renkBorder = Colors.green.shade200;
      renkBaslik = Colors.green.shade800;
      renkIkonBg = Colors.green.shade700;
      ikon = Icons.check_circle;
      baslikText = 'Bildirim gönderildi ($gonderildi cihaz)';
    } else if (kismi) {
      renkBg = Colors.amber.shade50;
      renkBorder = Colors.amber.shade300;
      renkBaslik = Colors.amber.shade900;
      renkIkonBg = Colors.amber.shade700;
      ikon = Icons.info_outline;
      baslikText = 'Kısmen gönderildi ($gonderildi/${gonderildi + hata})';
    } else if (hicGitmedi) {
      renkBg = Colors.red.shade50;
      renkBorder = Colors.red.shade200;
      renkBaslik = Colors.red.shade800;
      renkIkonBg = Colors.red.shade700;
      ikon = Icons.error_outline;
      baslikText = 'Hiçbir cihaza ulaşılamadı';
    } else if (hedefYok) {
      renkBg = Colors.grey.shade100;
      renkBorder = Colors.grey.shade300;
      renkBaslik = Colors.grey.shade800;
      renkIkonBg = Colors.grey.shade600;
      ikon = Icons.inbox_outlined;
      baslikText = 'Uygulaması yüklü müşteri yok';
    } else {
      renkBg = Colors.green.shade50;
      renkBorder = Colors.green.shade200;
      renkBaslik = Colors.green.shade800;
      renkIkonBg = Colors.green.shade700;
      ikon = Icons.check_circle;
      baslikText = 'Sonuç';
    }

    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: renkBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: renkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(ikon, color: renkIkonBg),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  baslikText,
                  style: TextStyle(color: renkBaslik, fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
            ],
          ),
          if (hedef > 0) ...[
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _duyuruIstatistik('Müşteri', '$hedef', Colors.blue.shade700)),
                SizedBox(width: 6),
                Expanded(child: _duyuruIstatistik('Gönderildi', '$gonderildi', Colors.green.shade700)),
                SizedBox(width: 6),
                Expanded(child: _duyuruIstatistik('Hata', '$hata', Colors.orange.shade700)),
              ],
            ),
          ],
          if (hicGitmedi) ...[
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Olası sebepler:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.red.shade800)),
                  SizedBox(height: 4),
                  Text('• Müşteriler uygulamayı silmiş ve token\'lar artık geçersiz', style: TextStyle(fontSize: 11, color: Colors.grey.shade800)),
                  Text('• Firebase yapılandırması sunucu tarafında eksik', style: TextStyle(fontSize: 11, color: Colors.grey.shade800)),
                  Text('• Geliştirici Laravel log\'unu kontrol etmeli', style: TextStyle(fontSize: 11, color: Colors.grey.shade800)),
                ],
              ),
            ),
          ],
          if (mesaj != null && mesaj.isNotEmpty) ...[
            SizedBox(height: 8),
            Text(mesaj, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
          ],
        ],
      ),
    );
  }

  Widget _duyuruIstatistik(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: color)),
          Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  // ============ KAZANANLAR TAB ============

  // Kupon siralama anahtari: kullanildiysa kullanim_tarihi, aksi halde created_at.
  // Hem ISO ("...T..Z") hem bosluklu ("Y-m-d H:i:s") formatlari DateTime.tryParse ile okunur.
  DateTime? _kuponSiraTarihi(Map o) {
    final s = (o['kullanim_tarihi'] ?? o['created_at'])?.toString();
    if (s == null || s.isEmpty) return null;
    return DateTime.tryParse(s);
  }

  Widget _kazananlarTab(ColorScheme scheme) {
    if (_kazLoading) return Center(child: CircularProgressIndicator());
    if (_kazData == null) {
      return Center(
        child: TextButton.icon(onPressed: _yukleKazananlar, icon: Icon(Icons.refresh), label: Text('Yükle')),
      );
    }
    final ozet = _kazData!['ozet'] as Map?;
    // Backend ile ayni siralama (COALESCE(kullanim_tarihi, created_at) DESC):
    // en son kullanilan/dogrulanan kupon en ustte. Sunucu sirasindan bagimsiz garanti.
    final odulluler = List<dynamic>.from((_kazData!['odulluler'] as List?) ?? []);
    odulluler.sort((a, b) {
      final ta = _kuponSiraTarihi(a as Map);
      final tb = _kuponSiraTarihi(b as Map);
      if (ta == null && tb == null) return 0;
      if (ta == null) return 1; // tarihsizler en sona
      if (tb == null) return -1;
      return tb.compareTo(ta); // azalan (yeni ustte)
    });
    final users = (_kazData!['users'] as Map?) ?? {};

    return RefreshIndicator(
      onRefresh: _yukleKazananlar,
      child: ListView(
        padding: EdgeInsets.fromLTRB(12, 12, 12, 80),
        children: [
          _ozetCardlar(scheme, ozet),
          SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _kuponDogrulaDialog,
            icon: Icon(Icons.qr_code_scanner),
            label: Text('Kupon Kodu Doğrula'),
            style: ElevatedButton.styleFrom(
              backgroundColor: scheme.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          SizedBox(height: 12),
          _kazFiltreChips(scheme),
          SizedBox(height: 12),
          if (odulluler.isEmpty)
            Container(
              padding: EdgeInsets.all(30),
              alignment: Alignment.center,
              child: Column(children: [Icon(Icons.inbox_outlined, size: 48, color: Colors.grey), SizedBox(height: 8), Text('Kupon yok')]),
            )
          else
            ...odulluler.map((o) => _kuponSatiri(scheme, o as Map<String, dynamic>, users)),
        ],
      ),
    );
  }

  Widget _ozetCardlar(ColorScheme scheme, Map? ozet) {
    final t = (ozet?['toplam_cevirme'] as num?)?.toInt() ?? 0;
    final b = (ozet?['bugun_cevirme'] as num?)?.toInt() ?? 0;
    final km = (ozet?['kullanilmamis'] as num?)?.toInt() ?? 0;
    final ku = (ozet?['kullanilmis'] as num?)?.toInt() ?? 0;
    return Row(
      children: [
        Expanded(child: _miniStat('Toplam', '$t', scheme.primary)),
        SizedBox(width: 6),
        Expanded(child: _miniStat('Bugün', '$b', Colors.blue.shade600)),
        SizedBox(width: 6),
        Expanded(child: _miniStat('Bekleyen', '$km', Colors.orange.shade600)),
        SizedBox(width: 6),
        Expanded(child: _miniStat('Kullanılmış', '$ku', Colors.green.shade600)),
      ],
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: color)),
          Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Future<void> _kuponDogrulaDialog() async {
    final ctrl = TextEditingController();
    Map<String, dynamic>? sonuc; // {basarili:true, odul:{...}} veya {basarili:false, mesaj:...}
    bool islemde = false;

    await showDialog(
      context: context,
      builder: (c) => StatefulBuilder(builder: (c, setSt) {
        final scheme = Theme.of(context).colorScheme;
        final Map? odul = (sonuc != null && sonuc!['basarili'] == true) ? sonuc!['odul'] as Map? : null;
        final String? hataMsj = (sonuc != null && sonuc!['basarili'] != true)
            ? (sonuc!['mesaj']?.toString() ?? 'Kupon bulunamadı')
            : null;
        final String? durum = odul?['durum']?.toString();

        String durumEtiket(String? d) {
          switch (d) {
            case 'gecerli':
              return '● Geçerli';
            case 'kullanildi':
              return '✓ Zaten Kullanıldı';
            case 'sure_doldu':
              return '⊘ Süresi Dolmuş';
            default:
              return d ?? '-';
          }
        }

        // 1. adım: kodu API'ye sorup bilgileri getir
        Future<void> dogrula() async {
          final kod = ctrl.text.trim();
          if (kod.isEmpty) return;
          setSt(() => islemde = true);
          final r = await carkAdminKuponDogrula(_salonId, kod);
          setSt(() {
            sonuc = r;
            islemde = false;
          });
        }

        // 2. adım: kuponu kullanıldı işaretle (veya geri al)
        Future<void> isaretle({String aksiyon = 'kullan'}) async {
          if (odul == null) return;
          setSt(() => islemde = true);
          final r = await carkAdminKuponKullan(_salonId, (odul['id'] as num).toInt(), aksiyon: aksiyon);
          if (r != null && r['basarili'] == true) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(aksiyon == 'kullan' ? '✓ Kupon kullanıldı olarak işaretlendi' : '↺ Kullanım geri alındı'),
                backgroundColor: aksiyon == 'kullan' ? Colors.green : Colors.grey[700],
              ));
            }
            Navigator.pop(c);
            _yukleKazananlar();
          } else {
            setSt(() => islemde = false);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('İşlem başarısız, tekrar deneyin')));
            }
          }
        }

        // Alt ana buton: doğrulama durumuna göre şekil değiştirir
        Widget anaButon() {
          if (islemde) {
            return const ElevatedButton(
              onPressed: null,
              child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }
          if (durum == 'gecerli') {
            return ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              onPressed: () => isaretle(),
              icon: const Icon(Icons.check),
              label: const Text('Kullanıldı İşaretle'),
            );
          }
          if (durum == 'kullanildi') {
            return ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[600], foregroundColor: Colors.white),
              onPressed: () => isaretle(aksiyon: 'geri_al'),
              icon: const Icon(Icons.undo),
              label: const Text('Kullanımı Geri Al'),
            );
          }
          // henüz doğrulanmadı ya da süresi dolmuş → tekrar doğrula
          return ElevatedButton(onPressed: dogrula, child: const Text('Doğrula'));
        }

        return AlertDialog(
          title: const Text('Kupon Doğrula'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrl,
                textCapitalization: TextCapitalization.characters,
                onChanged: (_) {
                  if (sonuc != null) setSt(() => sonuc = null); // kod değişince eski sonucu temizle
                },
                decoration: const InputDecoration(labelText: 'Kupon Kodu', border: OutlineInputBorder()),
              ),
              if (hataMsj != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                  child: Row(children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(hataMsj, style: const TextStyle(color: Colors.red))),
                  ]),
                ),
              ],
              if (odul != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: scheme.primary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(odul['baslik']?.toString() ?? '-', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text('Müşteri: ${odul['musteri_adi'] ?? '-'}'),
                      Text(
                        'Durum: ${durumEtiket(durum)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: durum == 'gecerli'
                              ? Colors.green[700]
                              : durum == 'kullanildi'
                                  ? Colors.red[700]
                                  : Colors.grey[600],
                        ),
                      ),
                      Text('Geçerlilik: ${odul['gecerlilik'] ?? 'Süresiz'}'),
                      if (durum == 'gecerli') ...[
                        const SizedBox(height: 6),
                        Text('Onaylamak için aşağıdaki "Kullanıldı İşaretle" butonuna basın.',
                            style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: const Text('Kapat')),
            anaButon(),
          ],
        );
      }),
    );
  }

  Widget _kazFiltreChips(ColorScheme scheme) {
    final options = [
      {'val': 'tumu', 'lbl': 'Tümü'},
      {'val': 'gecerli', 'lbl': 'Geçerli'},
      {'val': 'kullanildi', 'lbl': 'Kullanıldı'},
      {'val': 'sure_doldu', 'lbl': 'Süresi Doldu'},
    ];
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: options.map((o) {
          final selected = _kazFiltre == o['val'];
          return Padding(
            padding: EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(o['lbl']!),
              selected: selected,
              onSelected: (_) {
                setState(() => _kazFiltre = o['val']!);
                _yukleKazananlar();
              },
              selectedColor: scheme.primary,
              labelStyle: TextStyle(
                color: selected ? Colors.white : scheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: scheme.primary.withValues(alpha: 0.15)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _kuponSatiri(ColorScheme scheme, Map<String, dynamic> o, Map users) {
    final kullanildi = ((o['kullanildi'] as num?)?.toInt() ?? 0) == 1;
    final user = users[o['user_id']?.toString()] ?? users[o['user_id']];
    final musteriAd = (user is Map ? user['name'] : null)?.toString() ?? 'Müşteri';

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: scheme.primary.withValues(alpha: 0.04), blurRadius: 10, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (kullanildi ? Colors.green : scheme.primary).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              kullanildi ? Icons.check_circle : Icons.card_giftcard,
              color: kullanildi ? Colors.green : scheme.primary,
              size: 22,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(o['baslik']?.toString() ?? '-', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                Text(musteriAd, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                Row(
                  children: [
                    Text('Kod: ', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    SelectableText(
                      o['kod']?.toString() ?? '',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: scheme.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!kullanildi)
            IconButton(
              icon: Icon(Icons.check, color: Colors.green),
              onPressed: () async {
                final r = await carkAdminKuponKullan(_salonId, (o['id'] as num).toInt());
                if (mounted && r != null && r['basarili'] == true) _yukleKazananlar();
              },
            )
          else
            IconButton(
              icon: Icon(Icons.undo, color: Colors.orange),
              onPressed: () async {
                final r = await carkAdminKuponKullan(_salonId, (o['id'] as num).toInt(), aksiyon: 'geri_al');
                if (mounted && r != null && r['basarili'] == true) _yukleKazananlar();
              },
            ),
        ],
      ),
    );
  }

  // ============ PUAN ODULLERI TAB ============

  Future<void> _yuklePuanOdulleri() async {
    setState(() => _puanOdulLoading = true);
    final r = await carkAdminPuanOdulleriGetir(_salonId);
    if (!mounted) return;
    setState(() {
      _puanOdulLoading = false;
      if (r != null && r['basarili'] == true) {
        _puanOdulleri = ((r['odulSeviyeleri'] as List?) ?? const [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
    });
  }

  Widget _puanOdulleriTab(ColorScheme scheme) {
    if (_puanOdulLoading) return Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: _yuklePuanOdulleri,
      child: ListView(
        padding: EdgeInsets.fromLTRB(12, 12, 12, 100),
        children: [
          Container(
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [scheme.primary.withValues(alpha: 0.08), scheme.tertiary.withValues(alpha: 0.06)],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: scheme.primary.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: scheme.primary, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Müşteri çarktan puan kazanır. Topladığı puanla buradaki ödüllerden seçim yapar; salonda kupon koduyla doğrularsınız.',
                    style: TextStyle(fontSize: 12, color: scheme.onSurface.withValues(alpha: 0.75), height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _puanOdulDuzenle(null),
            icon: Icon(Icons.add),
            label: Text('Yeni Ödül Ekle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: scheme.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          SizedBox(height: 12),
          if (_puanOdulleri.isEmpty)
            Container(
              padding: EdgeInsets.all(30),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(Icons.stars_outlined, size: 56, color: Colors.grey.shade400),
                  SizedBox(height: 10),
                  Text('Henüz puan ödülü tanımlamadınız', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w700)),
                  SizedBox(height: 4),
                  Text(
                    'Yukarıdaki butondan eşik, başlık ve ödül tipini belirleyip ekleyin.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            )
          else
            ..._puanOdulleri.map((o) => _puanOdulKart(scheme, o)),
        ],
      ),
    );
  }

  Widget _puanOdulKart(ColorScheme scheme, Map<String, dynamic> o) {
    final tip = (o['tip'] ?? '').toString();
    final aktif = ((o['aktif'] as num?)?.toInt() ?? 1) == 1;
    final esik = (o['puan_esigi'] as num?)?.toInt() ?? 0;
    final deger = o['deger'];
    final tipLabel = const {
      'hizmet_indirimi': 'Hizmet İnd.',
      'urun_indirimi': 'Ürün İnd.',
      'hediye': 'Hediye',
    }[tip] ?? tip;
    final tipColor = const {
      'hizmet_indirimi': Color(0xFF1E40AF),
      'urun_indirimi': Color(0xFF9F1239),
      'hediye': Color(0xFF92400E),
    }[tip] ?? Colors.grey;

    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: aktif ? Colors.transparent : Colors.grey.shade300),
        boxShadow: [BoxShadow(color: scheme.primary.withValues(alpha: 0.04), blurRadius: 10, offset: Offset(0, 2))],
      ),
      child: Opacity(
        opacity: aktif ? 1 : 0.55,
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFFFDE047), Color(0xFFF59E0B)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text('$esik', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF78350F), height: 1)),
                  SizedBox(height: 1),
                  Text('PUAN', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF78350F), letterSpacing: 0.4)),
                ],
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (o['baslik'] ?? '-').toString(),
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                  if (((o['aciklama'] ?? '').toString()).isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Text(
                        (o['aciklama']).toString(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade700, height: 1.3),
                      ),
                    ),
                  SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: tipColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(tipLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: tipColor)),
                      ),
                      if (deger != null && (tip == 'hizmet_indirimi' || tip == 'urun_indirimi')) ...[
                        SizedBox(width: 6),
                        Text('%${(deger as num).toInt()}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                      ],
                      if (!aktif) ...[
                        SizedBox(width: 6),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('PASİF', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey.shade700)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.edit, color: scheme.primary),
              tooltip: 'Düzenle',
              onPressed: () => _puanOdulDuzenle(o),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Sil',
              onPressed: () => _puanOdulSil(o),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _puanOdulDuzenle(Map<String, dynamic>? mevcut) async {
    final baslikCtrl = TextEditingController(text: (mevcut?['baslik'] ?? '').toString());
    final aciklamaCtrl = TextEditingController(text: (mevcut?['aciklama'] ?? '').toString());
    final esikCtrl = TextEditingController(text: (mevcut?['puan_esigi'] ?? '').toString());
    final degerCtrl = TextEditingController(
      text: mevcut?['deger'] != null ? (mevcut!['deger'] as num).toInt().toString() : '',
    );
    String tip = (mevcut?['tip'] ?? 'hizmet_indirimi').toString();
    bool aktif = ((mevcut?['aktif'] as num?)?.toInt() ?? 1) == 1;
    bool kaydediyor = false;
    // Çoklu şube: yeni ödül hangi şubelere eklenecek (varsayılan: bulunulan şube)
    List<String> puanSubeler = [_salonId];

    await showDialog(
      context: context,
      builder: (c) => StatefulBuilder(builder: (c, setSt) {
        final scheme = Theme.of(context).colorScheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(mevcut == null ? 'Yeni Puan Ödülü' : 'Ödülü Düzenle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: baslikCtrl,
                  decoration: InputDecoration(
                    labelText: 'Başlık',
                    hintText: 'Örn. %10 Hizmet İndirimi',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: aciklamaCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Açıklama (opsiyonel)',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: esikCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Puan Eşiği',
                    hintText: 'Örn. 250',
                    border: OutlineInputBorder(),
                    suffixText: 'puan',
                  ),
                ),
                SizedBox(height: 10),
                AramaliDropdownFormField<String>(
                  value: tip,
                  decoration: InputDecoration(
                    labelText: 'Ödül Tipi',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(value: 'hizmet_indirimi', child: Text('Hizmet İndirimi')),
                    DropdownMenuItem(value: 'urun_indirimi', child: Text('Ürün İndirimi')),
                    DropdownMenuItem(value: 'hediye', child: Text('Hediye')),
                  ],
                  onChanged: (v) => setSt(() => tip = v ?? 'hizmet_indirimi'),
                ),
                if (tip == 'hizmet_indirimi' || tip == 'urun_indirimi') ...[
                  SizedBox(height: 10),
                  TextField(
                    controller: degerCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'İndirim Yüzdesi',
                      hintText: 'Örn. 15',
                      border: OutlineInputBorder(),
                      suffixText: '%',
                    ),
                  ),
                ],
                SizedBox(height: 10),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Aktif'),
                  subtitle: Text(aktif ? 'Müşteriye görünür' : 'Pasif — müşteri göremez', style: TextStyle(fontSize: 11)),
                  value: aktif,
                  activeColor: scheme.primary,
                  onChanged: (v) => setSt(() => aktif = v),
                ),
                if (mevcut == null)
                  SubeCokluSecici(
                    aktifSalonId: _salonId,
                    baslik: 'Hangi şubelere eklensin?',
                    onChanged: (ids) => puanSubeler = ids,
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: kaydediyor ? null : () => Navigator.pop(c),
              child: Text('İptal'),
            ),
            ElevatedButton(
              onPressed: kaydediyor
                  ? null
                  : () async {
                      setSt(() => kaydediyor = true);
                      final data = <String, dynamic>{
                        if (mevcut != null) 'id': mevcut['id'],
                        'baslik': baslikCtrl.text.trim(),
                        'aciklama': aciklamaCtrl.text.trim(),
                        'puan_esigi': int.tryParse(esikCtrl.text.trim()) ?? 0,
                        'tip': tip,
                        'deger': (tip == 'hizmet_indirimi' || tip == 'urun_indirimi')
                            ? (int.tryParse(degerCtrl.text.trim()) ?? 0)
                            : null,
                        'aktif': aktif ? 1 : 0,
                        if (mevcut == null) 'salon_ids': puanSubeler,
                      };
                      final r = await carkAdminPuanOdulKaydet(_salonId, data);
                      if (!mounted) return;
                      setSt(() => kaydediyor = false);
                      if (r != null && r['basarili'] == true) {
                        Navigator.pop(c);
                        _yuklePuanOdulleri();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Ödül kaydedildi'), behavior: SnackBarBehavior.floating),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(r?['mesaj']?.toString() ?? 'Kaydedilemedi'),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              child: kaydediyor
                  ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(mevcut == null ? 'Ekle' : 'Güncelle'),
            ),
          ],
        );
      }),
    );
  }

  Future<void> _puanOdulSil(Map<String, dynamic> o) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Ödülü Sil'),
        content: Text('"${o['baslik']}" ödülünü silmek istediğinize emin misiniz?\n\nBu işlem geri alınamaz.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text('İptal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text('Sil'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final basarili = await carkAdminPuanOdulSil(_salonId, (o['id'] as num).toInt());
    if (!mounted) return;
    if (basarili) {
      _yuklePuanOdulleri();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ödül silindi'), behavior: SnackBarBehavior.floating),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Silinemedi'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
      );
    }
  }

  // ============ HATIRLATMA TAB ============

  Widget _hatirlatmaTab(ColorScheme scheme) {
    if (_hatLoading) return Center(child: CircularProgressIndicator());
    if (_hatData == null) {
      return Center(
        child: TextButton.icon(onPressed: _yukleHatirlatma, icon: Icon(Icons.refresh), label: Text('Yükle')),
      );
    }
    return _HatirlatmaFormu(
      salonId: _salonId,
      ayar: Map<String, dynamic>.from(_hatData!['ayar'] as Map),
      bugun: (_hatData!['bugun'] as num?)?.toInt() ?? 0,
      onKaydedildi: (yeni) {
        setState(() => _hatData = {'ayar': yeni, 'bugun': _hatData!['bugun']});
      },
    );
  }
}

// ============================================================
// DILIM SATIRI — kendi state'i olan widget (TextController bug yok)
// ============================================================

class _DilimSatiri extends StatefulWidget {
  final int index;
  final Map<String, dynamic> dilim;
  final VoidCallback onSil;
  final VoidCallback onDegisti;
  final VoidCallback onKazan;
  const _DilimSatiri({Key? key, required this.index, required this.dilim, required this.onSil, required this.onDegisti, required this.onKazan}) : super(key: key);

  @override
  State<_DilimSatiri> createState() => _DilimSatiriState();
}

class _DilimSatiriState extends State<_DilimSatiri> {
  late TextEditingController _nameCtrl;
  late TextEditingController _degerCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.dilim['name']?.toString() ?? '');
    _degerCtrl = TextEditingController(text: widget.dilim['deger']?.toString() ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _degerCtrl.dispose();
    super.dispose();
  }

  Color _hexToColor(String? hex) {
    if (hex == null || hex.isEmpty) return Colors.purple;
    final h = hex.replaceAll('#', '');
    if (h.length != 6) return Colors.purple;
    return Color(int.parse('FF$h', radix: 16));
  }

  // % / ₺ birim butonu (seçiliyse tema renginde dolu)
  Widget _birimSecenek(ColorScheme scheme, String sembol, String etiket, bool secili, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: secili ? scheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: secili ? scheme.primary : Colors.grey.shade300, width: 1.5),
        ),
        child: Text(
          '$sembol $etiket',
          style: TextStyle(
            color: secili ? Colors.white : Colors.grey.shade700,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tip = widget.dilim['tip']?.toString() ?? 'bos';
    final color = _hexToColor(widget.dilim['color']?.toString());
    final isIndirim = tip == 'hizmet_indirimi' || tip == 'urun_indirimi' || tip == 'paket_indirimi';
    final indirimTipi = (widget.dilim['indirim_tipi'] ?? 'yuzde').toString();
    final degerEnabled = tip == 'puan' || isIndirim;
    // Değer birimi: puan / % / ₺ (indirim dilimlerinde salon sahibi seçer)
    final birim = tip == 'puan' ? 'puan' : (isIndirim ? (indirimTipi == 'tutar' ? '₺' : '%') : '');
    final kazanan = (widget.dilim['probability'] as num?)?.toInt() == 100;

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: kazanan ? Border.all(color: Colors.amber.shade400, width: 2) : null,
        boxShadow: [BoxShadow(color: scheme.primary.withValues(alpha: 0.04), blurRadius: 10, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 22, height: 22, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              SizedBox(width: 8),
              Text('Dilim ${widget.index + 1}', style: TextStyle(fontWeight: FontWeight.w800)),
              Spacer(),
              // Kazan / ★ Kazanan butonu (web ile aynı)
              GestureDetector(
                onTap: kazanan ? null : widget.onKazan,
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: kazanan
                        ? LinearGradient(
                            colors: [Colors.amber.shade600, Colors.orange.shade700],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: kazanan ? null : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: kazanan
                        ? null
                        : Border.all(color: Colors.green.shade400.withValues(alpha: 0.6), width: 1.5),
                    boxShadow: kazanan
                        ? [BoxShadow(color: Colors.amber.withValues(alpha: 0.35), blurRadius: 8, offset: Offset(0, 2))]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        kazanan ? Icons.emoji_events : Icons.flag_outlined,
                        size: 14,
                        color: kazanan ? Colors.white : Colors.green.shade700,
                      ),
                      SizedBox(width: 4),
                      Text(
                        kazanan ? 'Kazanan' : 'Kazan',
                        style: TextStyle(
                          color: kazanan ? Colors.white : Colors.green.shade700,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 4),
              IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.red, size: 20),
                onPressed: widget.onSil,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            onChanged: (v) {
              widget.dilim['name'] = v;
              widget.onDegisti();
            },
            decoration: InputDecoration(labelText: 'Ödül Adı', border: OutlineInputBorder(), isDense: true),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: AramaliDropdownFormField<String>(
                  value: tip,
                  decoration: InputDecoration(labelText: 'Tip', border: OutlineInputBorder(), isDense: true),
                  items: [
                    DropdownMenuItem(value: 'puan', child: Text('Puan')),
                    DropdownMenuItem(value: 'hizmet_indirimi', child: Text('Hizmet İnd. (%)')),
                    DropdownMenuItem(value: 'urun_indirimi', child: Text('Ürün İnd. (%)')),
                    DropdownMenuItem(value: 'tekrar_dene', child: Text('Tekrar Dene')),
                    DropdownMenuItem(value: 'bos', child: Text('Boş')),
                  ],
                  onChanged: (v) {
                    setState(() {
                      widget.dilim['tip'] = v;
                      if (v == 'hizmet_indirimi' || v == 'urun_indirimi' || v == 'paket_indirimi') {
                        widget.dilim['kupon_mu'] = 1;
                        // İndirim tipine geçince birim varsayılanı % (salon sahibi değiştirebilir)
                        if (widget.dilim['indirim_tipi'] != 'tutar') {
                          widget.dilim['indirim_tipi'] = 'yuzde';
                        }
                      } else {
                        widget.dilim['kupon_mu'] = 0;
                        if (v == 'tekrar_dene' || v == 'bos') {
                          widget.dilim['deger'] = null;
                          _degerCtrl.text = '';
                        }
                      }
                    });
                    widget.onDegisti();
                  },
                ),
              ),
              SizedBox(width: 8),
              SizedBox(
                width: 100,
                child: TextField(
                  controller: _degerCtrl,
                  keyboardType: TextInputType.number,
                  enabled: degerEnabled,
                  onChanged: (v) {
                    widget.dilim['deger'] = double.tryParse(v);
                    widget.onDegisti();
                  },
                  decoration: InputDecoration(
                    labelText: 'Değer',
                    suffixText: birim.isEmpty ? null : birim,
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          // İndirim dilimlerinde birim seçimi: % (yüzde) veya sabit ₺ (tutar)
          if (isIndirim) ...[
            SizedBox(height: 8),
            Row(
              children: [
                Text('İndirim birimi:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey.shade700)),
                SizedBox(width: 10),
                _birimSecenek(scheme, '%', 'Yüzde', indirimTipi != 'tutar', () {
                  setState(() => widget.dilim['indirim_tipi'] = 'yuzde');
                  widget.onDegisti();
                }),
                SizedBox(width: 6),
                _birimSecenek(scheme, '₺', 'Tutar', indirimTipi == 'tutar', () {
                  setState(() => widget.dilim['indirim_tipi'] = 'tutar');
                  widget.onDegisti();
                }),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// CARK PREVIEW — basit pasta dilim önizlemesi
// ============================================================

class _CarkPreview extends StatefulWidget {
  final List<Map<String, dynamic>> dilimler;
  final VoidCallback? onTick;
  const _CarkPreview({Key? key, required this.dilimler, this.onTick}) : super(key: key);

  @override
  State<_CarkPreview> createState() => _CarkPreviewState();
}

class _CarkPreviewState extends State<_CarkPreview> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  double _baseRotation = 0;
  Timer? _tickTimer;
  int _lastTickedSlice = -1;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: Duration(milliseconds: 8000));
    _anim = AlwaysStoppedAnimation(0);
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  /// Çarkı verilen dilim üzerinde durdur. ~4 saniye dönüş + yavaşlama.
  Future<void> cevirSonuc(int hedefIndex) async {
    if (widget.dilimler.isEmpty) return;
    final n = widget.dilimler.length;
    final sweep = 2 * math.pi / n;

    // Dilimin merkez açısı (0 = saat 12 yönü, pozitif saat yönünde)
    // Painter dilim 0'ı saat 12'den başlatıyor, dilim merkezi = i * sweep + sweep/2
    // İşaretçi saat 12'de. Çark döndüğünde, hedef dilim saat 12'ye gelsin.
    // Tam tur sayısı + son ayarlama
    final tamTurlar = 8 + math.Random().nextInt(3); // 8-10 tam tur (daha dramatik dönüş)
    // Hedefin saat 12'ye gelmesi için: rotation = (tamTurlar * 2π) - (hedef_merkez_açısı)
    final hedefMerkez = hedefIndex * sweep + sweep / 2;
    final hedefRotation = (tamTurlar * 2 * math.pi) - hedefMerkez;

    final baslangic = _baseRotation;
    final fark = hedefRotation - (baslangic % (2 * math.pi));

    _ctrl.reset();
    _anim = Tween<double>(begin: 0, end: fark).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutQuart),
    );

    // "Tick tick" hissi için her dilim geçişinde haptic
    _lastTickedSlice = -1;
    _ctrl.addListener(_haptickTick);
    await _ctrl.forward();
    _ctrl.removeListener(_haptickTick);
    _baseRotation = baslangic + fark;
  }

  void _haptickTick() {
    final n = widget.dilimler.length;
    if (n == 0) return;
    final sweep = 2 * math.pi / n;
    final donmus = _anim.value;
    final dilimGecis = (donmus / sweep).floor();
    if (dilimGecis != _lastTickedSlice) {
      _lastTickedSlice = dilimGecis;
      HapticFeedback.selectionClick();
      widget.onTick?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (c, _) {
        final rot = (_baseRotation + (_anim.value));
        return SizedBox(
          width: 300,
          height: 300,
          child: CustomPaint(painter: _CarkPainter(widget.dilimler, rot)),
        );
      },
    );
  }
}

/// Web çark widget'ının birebir Flutter portu.
/// Renkler, rakam/kategori yerleşimi, ayraç çizgileri, işaretçi — hepsi web ile aynı.
class _CarkPainter extends CustomPainter {
  final List<Map<String, dynamic>> dilimler;
  final double rotation;
  _CarkPainter(this.dilimler, [this.rotation = 0]);

  static const double _cx = 150, _cy = 150, _R = 130;

  @override
  void paint(Canvas canvas, Size size) {
    // Web SVG 300x300, scale et
    final scale = size.width / 300;
    canvas.scale(scale);

    final center = Offset(_cx, _cy);

    // Çark zemini — koyu mor (web: #160630)
    canvas.drawCircle(center, _R + 4, Paint()..color = Color(0xFF160630));

    if (dilimler.isEmpty) {
      return;
    }

    final n = dilimler.length;
    final angDeg = 360 / n; // her dilim açısı (derece)

    // Çark gövdesini döndür (işaretçi sabit, çark döner)
    canvas.save();
    canvas.translate(_cx, _cy);
    canvas.rotate(rotation);
    canvas.translate(-_cx, -_cy);

    // Conic-gradient glow ring (dış)
    final ringRect = Rect.fromCircle(center: center, radius: _R + 3);
    final gradPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          Color(0xFF6c5ce7), Color(0xFFa29bfe), Color(0xFFfd79a8),
          Color(0xFFfdcb6e), Color(0xFF00b894), Color(0xFF6c5ce7),
        ],
      ).createShader(ringRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7;
    canvas.drawCircle(center, _R + 3, gradPaint);

    for (var i = 0; i < n; i++) {
      final saDeg = i * angDeg;
      final sweepDeg = angDeg;
      final saRad = (saDeg - 90) * math.pi / 180;
      final sweepRad = sweepDeg * math.pi / 180;

      // Dilim path: M cx,cy L x1,y1 A R R 0 lg 1 x2,y2 Z
      final dilim = Path()
        ..moveTo(_cx, _cy)
        ..lineTo(_cx + _R * math.cos(saRad), _cy + _R * math.sin(saRad))
        ..arcTo(
          Rect.fromCircle(center: center, radius: _R),
          saRad, sweepRad, false,
        )
        ..close();

      // Dilim dolgusu (renk)
      canvas.drawPath(dilim, Paint()..color = _hexToColor(dilimler[i]['color']?.toString()));

      // Beyaz ayraç (stroke .7 alpha)
      canvas.drawPath(dilim, Paint()
        ..color = Colors.white.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2);

      // ===== YAZILAR (web kodu ile bire bir) =====
      final tAngDeg = saDeg + angDeg / 2;
      final tRad = (tAngDeg - 90) * math.pi / 180;
      // SVG'de text-rotate: tAng <= 180 ? tAng - 90 : tAng - 270 (sağ ya da sol okunsun diye flip)
      final textRotDeg = tAngDeg <= 180 ? tAngDeg - 90 : tAngDeg - 270;
      final textRotRad = textRotDeg * math.pi / 180;

      final tip = dilimler[i]['tip']?.toString() ?? '';
      final deger = dilimler[i]['deger'];
      final hasDeger = (tip == 'puan' || tip == 'hizmet_indirimi' || tip == 'urun_indirimi') && deger != null;

      if (hasDeger) {
        final numFs = n <= 8 ? 17.0 : 14.0;
        final catFs = n <= 8 ? 11.0 : 9.0;

        // Rakam — dış kenara teğet (indirim: tutar ise "50₺", değilse "%50")
        final numStr = tip.contains('indirimi')
            ? (dilimler[i]['indirim_tipi'] == 'tutar' ? '${_fmt(deger)}₺' : '%${_fmt(deger)}')
            : _fmt(deger);
        final numDist = _R - (n <= 8 ? 16 : 13);
        final nx = _cx + numDist * math.cos(tRad);
        final ny = _cy + numDist * math.sin(tRad);

        canvas.save();
        canvas.translate(nx, ny);
        canvas.rotate(tAngDeg * math.pi / 180);
        _drawStrokedText(canvas, Offset.zero, numStr, numFs, FontWeight.w900, Colors.white, Color(0xCC000000), 3.5);
        canvas.restore();

        // Kategori — iç bölgede radyal
        final innerLabel = _buildLabel(dilimler[i]);
        final catDist = (n <= 8 ? 68.0 : 60.0);
        final cx2 = _cx + catDist * math.cos(tRad);
        final cy2 = _cy + catDist * math.sin(tRad);
        final catMaxCh = math.max(4, (55 / (catFs * 0.62)).floor());
        final lines = _wrapText(innerLabel, catMaxCh);
        final catLH = catFs + 2;
        final catSY = -((lines.length - 1) * catLH / 2);

        canvas.save();
        canvas.translate(cx2, cy2);
        canvas.rotate(textRotRad);
        for (var li = 0; li < lines.length; li++) {
          _drawStrokedText(canvas, Offset(0, catSY + li * catLH), lines[li], catFs, FontWeight.w700,
              Color(0xEBFFFFFF), Color(0x80000000), 2);
        }
        canvas.restore();
      } else {
        // Metin ödülü (Tekrar Dene, Boş, isim)
        final dist = (n <= 8 ? 76.0 : 68.0);
        final fs = (n <= 8 ? 12.0 : 10.0);
        final maxCh = math.max(6, (80 / (fs * 0.60)).floor());
        final lh = fs + 3;
        final label = _buildLabel(dilimler[i]);
        var lines = _wrapText(label, maxCh);
        if (lines.length > 2) lines = [label.substring(0, math.min(maxCh - 1, label.length)) + '…'];
        final tx = _cx + dist * math.cos(tRad);
        final ty = _cy + dist * math.sin(tRad);
        final sy = -((lines.length - 1) * lh / 2);

        canvas.save();
        canvas.translate(tx, ty);
        canvas.rotate(textRotRad);
        for (var li = 0; li < lines.length; li++) {
          _drawStrokedText(canvas, Offset(0, sy + li * lh), lines[li], fs, FontWeight.w700,
              Colors.white, Color(0x8C000000), 2.5);
        }
        canvas.restore();
      }
    }

    // Merkez beyaz daire (dönmeyle uyumlu)
    canvas.drawCircle(center, 14, Paint()..color = Colors.white);
    canvas.drawCircle(center, 14, Paint()
      ..color = Color(0xFF6c5ce7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3);

    canvas.restore();

    // İşaretçi (sabit, çarkın üstünde — saat 12 yönü)
    _drawPointer(canvas, _cx, _cy - _R);
  }

  void _drawPointer(Canvas canvas, double x, double yTop) {
    // Web SVG pointer: kırmızı gövde + altın taban — saat 12'den aşağı işaret eder
    final body = Path()
      ..moveTo(x, yTop + 6)              // alt uç (çarkın üstüne değiyor)
      ..lineTo(x - 14, yTop - 32)        // sol üst
      ..lineTo(x + 14, yTop - 32)        // sağ üst
      ..close();
    // Kırmızı gradient (web: pg)
    canvas.drawShadow(body, Colors.black.withValues(alpha: 0.5), 6, false);
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        colors: [Color(0xFF7f1d1d), Color(0xFFef4444), Color(0xFFfca5a5), Color(0xFF7f1d1d)],
        stops: [0, 0.4, 0.7, 1],
      ).createShader(Rect.fromLTWH(x - 14, yTop - 32, 28, 38));
    canvas.drawPath(body, bodyPaint);
    canvas.drawPath(body, Paint()
      ..color = Color(0xFF7f1d1d)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1);

    // Üst yuvarlatılmış kutu
    final cap = RRect.fromRectAndRadius(Rect.fromLTWH(x - 14, yTop - 42, 28, 12), Radius.circular(5));
    canvas.drawRRect(cap, bodyPaint);
    canvas.drawRRect(cap, Paint()
      ..color = Color(0xFF7f1d1d)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1);

    // Altın yuvarlak (tip)
    final tipPaint = Paint()
      ..shader = LinearGradient(
        colors: [Color(0xFF92400e), Color(0xFFfbbf24), Color(0xFF92400e)],
      ).createShader(Rect.fromCircle(center: Offset(x, yTop + 6), radius: 4));
    canvas.drawCircle(Offset(x, yTop + 6), 4, tipPaint);
    canvas.drawCircle(Offset(x, yTop + 6), 4, Paint()
      ..color = Color(0xFF78350f)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1);
  }

  // ============= Yardımcılar =============

  String _buildLabel(Map<String, dynamic> d) {
    final tip = d['tip']?.toString() ?? '';
    final ismi = d['name']?.toString() ?? '';
    switch (tip) {
      case 'puan':            return 'Puan';
      case 'hizmet_indirimi': return 'Hizmet İnd.';
      case 'urun_indirimi':   return 'Ürün İnd.';
      case 'tekrar_dene':     return 'Tekrar Dene';
      case 'bos':             return 'Boş';
      default:                return ismi.isEmpty ? 'Ödül' : ismi;
    }
  }

  String _fmt(dynamic v) {
    if (v == null) return '';
    if (v is num) {
      if (v == v.toInt()) return v.toInt().toString();
      return v.toString();
    }
    return v.toString();
  }

  List<String> _wrapText(String text, int maxCh) {
    final words = text.split(RegExp(r'\s+'));
    final lines = <String>[];
    var cur = '';
    for (final w in words) {
      final cand = (cur.isEmpty ? w : '$cur $w');
      if (cand.length <= maxCh) {
        cur = cand;
      } else {
        if (cur.isNotEmpty) lines.add(cur);
        cur = w;
      }
    }
    if (cur.isNotEmpty) lines.add(cur);
    return lines.isEmpty ? [''] : lines;
  }

  void _drawStrokedText(Canvas canvas, Offset center, String text, double fontSize,
      FontWeight weight, Color fill, Color stroke, double strokeWidth) {
    // Stroke (alt katman)
    final strokePainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: weight,
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth
            ..strokeJoin = StrokeJoin.round
            ..color = stroke,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    strokePainter.paint(canvas, Offset(center.dx - strokePainter.width / 2, center.dy - strokePainter.height / 2));

    // Fill (üst katman)
    final fillPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: fontSize, fontWeight: weight, color: fill),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    fillPainter.paint(canvas, Offset(center.dx - fillPainter.width / 2, center.dy - fillPainter.height / 2));
  }

  Color _hexToColor(String? hex) {
    if (hex == null || hex.isEmpty) return Color(0xFF6c5ce7);
    final h = hex.replaceAll('#', '');
    if (h.length != 6) return Color(0xFF6c5ce7);
    return Color(int.parse('FF$h', radix: 16));
  }

  @override
  bool shouldRepaint(_CarkPainter old) => old.dilimler != dilimler || old.rotation != rotation;
}

// ============================================================
// HATIRLATMA FORMU
// ============================================================

class _HatirlatmaFormu extends StatefulWidget {
  final String salonId;
  final Map<String, dynamic> ayar;
  final int bugun;
  final void Function(Map<String, dynamic>) onKaydedildi;
  const _HatirlatmaFormu({Key? key, required this.salonId, required this.ayar, required this.bugun, required this.onKaydedildi}) : super(key: key);

  @override
  State<_HatirlatmaFormu> createState() => _HatirlatmaFormuState();
}

class _HatirlatmaFormuState extends State<_HatirlatmaFormu> {
  late bool _aktif;
  // 3 slot: her birinin aktif + başlık + altyazı + saat + mesaj
  late bool _a1, _a2, _a3;
  late TextEditingController _s1, _s2, _s3;
  late TextEditingController _m1, _m2, _m3;
  late TextEditingController _b1, _b2, _b3;       // başlık
  late TextEditingController _alt1, _alt2, _alt3; // altyazı
  Set<int> _gunler = {1, 2, 3, 4, 5, 6, 7};
  bool _kaydediliyor = false;

  // Slot default'ları — salon ilk açtığında bu standart başlıklarla gelir
  static const _defaults = [
    {'baslik': 'Sabah Hatırlatması', 'altyazi': 'Güne hediyeyle başla', 'saat': '10:00', 'mesaj': '🎡 Bugün çark hakkınız var, hediyeler sizi bekliyor!'},
    {'baslik': 'Öğleden Sonra',      'altyazi': 'Çark hâlâ açık',       'saat': '15:00', 'mesaj': '⏰ Çark hakkınız hâlâ duruyor — son birkaç saat!'},
    {'baslik': 'Akşam Hatırlatması', 'altyazi': 'Bugünün son şansı',    'saat': '20:00', 'mesaj': '🚨 Son saatler! Çarkı çevirmeyi unutmayın'},
  ];

  @override
  void initState() {
    super.initState();
    final a = widget.ayar;
    _aktif = ((a['aktif'] as num?)?.toInt() ?? 0) == 1;
    _a1 = ((a['aktif_1'] as num?)?.toInt() ?? 1) == 1;
    _a2 = ((a['aktif_2'] as num?)?.toInt() ?? 1) == 1;
    _a3 = ((a['aktif_3'] as num?)?.toInt() ?? 1) == 1;
    _s1 = TextEditingController(text: a['saat_1']?.toString() ?? _defaults[0]['saat']!);
    _s2 = TextEditingController(text: a['saat_2']?.toString() ?? _defaults[1]['saat']!);
    _s3 = TextEditingController(text: a['saat_3']?.toString() ?? _defaults[2]['saat']!);
    _m1 = TextEditingController(text: a['mesaj_1']?.toString() ?? _defaults[0]['mesaj']!);
    _m2 = TextEditingController(text: a['mesaj_2']?.toString() ?? _defaults[1]['mesaj']!);
    _m3 = TextEditingController(text: a['mesaj_3']?.toString() ?? _defaults[2]['mesaj']!);
    _b1 = TextEditingController(text: (a['baslik_1']?.toString().isNotEmpty ?? false) ? a['baslik_1'].toString() : _defaults[0]['baslik']!);
    _b2 = TextEditingController(text: (a['baslik_2']?.toString().isNotEmpty ?? false) ? a['baslik_2'].toString() : _defaults[1]['baslik']!);
    _b3 = TextEditingController(text: (a['baslik_3']?.toString().isNotEmpty ?? false) ? a['baslik_3'].toString() : _defaults[2]['baslik']!);
    _alt1 = TextEditingController(text: (a['altyazi_1']?.toString().isNotEmpty ?? false) ? a['altyazi_1'].toString() : _defaults[0]['altyazi']!);
    _alt2 = TextEditingController(text: (a['altyazi_2']?.toString().isNotEmpty ?? false) ? a['altyazi_2'].toString() : _defaults[1]['altyazi']!);
    _alt3 = TextEditingController(text: (a['altyazi_3']?.toString().isNotEmpty ?? false) ? a['altyazi_3'].toString() : _defaults[2]['altyazi']!);
    final g = a['gonderim_gunleri'];
    if (g is List) _gunler = g.map((e) => (e as num).toInt()).toSet();
  }

  @override
  void dispose() {
    _s1.dispose(); _s2.dispose(); _s3.dispose();
    _m1.dispose(); _m2.dispose(); _m3.dispose();
    _b1.dispose(); _b2.dispose(); _b3.dispose();
    _alt1.dispose(); _alt2.dispose(); _alt3.dispose();
    super.dispose();
  }

  void _yeniHatirlatmaEkle() {
    // İlk pasif slot'u aktif et
    setState(() {
      if (!_a1) { _a1 = true; }
      else if (!_a2) { _a2 = true; }
      else if (!_a3) { _a3 = true; }
    });
  }

  int get _aktifSayisi => (_a1 ? 1 : 0) + (_a2 ? 1 : 0) + (_a3 ? 1 : 0);

  Future<void> _kaydet() async {
    setState(() => _kaydediliyor = true);
    final data = {
      'aktif': _aktif ? 1 : 0,
      'saat_1': _s1.text.trim(),
      'saat_2': _s2.text.trim(),
      'saat_3': _s3.text.trim(),
      'mesaj_1': _m1.text.trim(),
      'mesaj_2': _m2.text.trim(),
      'mesaj_3': _m3.text.trim(),
      'baslik_1': _b1.text.trim(),
      'baslik_2': _b2.text.trim(),
      'baslik_3': _b3.text.trim(),
      'altyazi_1': _alt1.text.trim(),
      'altyazi_2': _alt2.text.trim(),
      'altyazi_3': _alt3.text.trim(),
      'aktif_1': _a1 ? 1 : 0,
      'aktif_2': _a2 ? 1 : 0,
      'aktif_3': _a3 ? 1 : 0,
      'gonderim_gunleri': _gunler.toList(),
    };
    final ok = await carkAdminHatirlatmaKaydet(widget.salonId, data);
    if (!mounted) return;
    setState(() => _kaydediliyor = false);
    if (ok) {
      widget.onKaydedildi(data);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hatırlatma ayarları kaydedildi'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kaydetme hatası'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const gunIsimleri = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

    return ListView(
      padding: EdgeInsets.fromLTRB(12, 12, 12, 80),
      children: [
        _kartim(scheme, [
          SwitchListTile(
            value: _aktif,
            title: Text('Hatırlatma SMS\'leri Aktif'),
            subtitle: Text('Bugün ${widget.bugun} hatırlatma gönderildi', style: TextStyle(fontSize: 11)),
            onChanged: (v) => setState(() => _aktif = v),
            contentPadding: EdgeInsets.zero,
          ),
        ], title: 'Genel'),
        SizedBox(height: 12),
        _kartim(scheme, [
          Text('Hangi günlerde gönderilsin?', style: TextStyle(fontSize: 12, color: Colors.grey)),
          SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: List.generate(7, (i) {
              final gun = i + 1;
              final selected = _gunler.contains(gun);
              return ChoiceChip(
                label: Text(gunIsimleri[i]),
                selected: selected,
                onSelected: (v) {
                  setState(() {
                    if (v) {
                      _gunler.add(gun);
                    } else {
                      _gunler.remove(gun);
                    }
                  });
                },
                selectedColor: scheme.primary,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : scheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              );
            }),
          ),
        ], title: 'Gönderim Günleri'),
        SizedBox(height: 12),
        if (_a1)
          _asamaKart(scheme, 1, _b1, _alt1, _s1, _m1,
              onSil: () => setState(() => _a1 = false)),
        if (_a2)
          _asamaKart(scheme, 2, _b2, _alt2, _s2, _m2,
              onSil: () => setState(() => _a2 = false)),
        if (_a3)
          _asamaKart(scheme, 3, _b3, _alt3, _s3, _m3,
              onSil: () => setState(() => _a3 = false)),
        if (_aktifSayisi < 3) ...[
          SizedBox(height: 4),
          _ekleButonu(scheme),
          SizedBox(height: 8),
        ],
        SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _kaydediliyor ? null : _kaydet,
          icon: _kaydediliyor
              ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Icon(Icons.save),
          label: Text(_kaydediliyor ? 'Kaydediliyor...' : 'Kaydet'),
          style: ElevatedButton.styleFrom(
            backgroundColor: scheme.primary,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }

  Widget _asamaKart(
    ColorScheme scheme,
    int n,
    TextEditingController baslik,
    TextEditingController altyazi,
    TextEditingController saat,
    TextEditingController mesaj, {
    required VoidCallback onSil,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: scheme.primary.withValues(alpha: 0.04), blurRadius: 10, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: scheme.primary,
                child: Text('$n', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: baslik,
                      maxLength: 80,
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: scheme.onSurface),
                      decoration: InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                        hintText: 'Başlık (ör. Sabah Hatırlatması)',
                        counterText: '',
                      ),
                    ),
                    TextField(
                      controller: altyazi,
                      maxLength: 120,
                      style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700, fontStyle: FontStyle.italic),
                      decoration: InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                        hintText: 'Altyazı (ör. Öğleden sonra)',
                        counterText: '',
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 6),
              Material(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: onSil,
                  child: Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(Icons.close_rounded, color: Colors.red.shade700, size: 18),
                  ),
                ),
              ),
            ],
          ),
          Divider(height: 18, color: Colors.grey.shade200),
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
              SizedBox(width: 6),
              Expanded(
                child: Text('Bu saatte gönderilir', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
              ),
              SizedBox(
                width: 100,
                child: TextField(
                  controller: saat,
                  decoration: InputDecoration(border: OutlineInputBorder(), isDense: true, hintText: 'HH:MM'),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          TextField(
            controller: mesaj,
            maxLines: 3,
            maxLength: 300,
            decoration: InputDecoration(labelText: 'Mesaj metni', border: OutlineInputBorder()),
          ),
        ],
      ),
    );
  }

  Widget _ekleButonu(ColorScheme scheme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _yeniHatirlatmaEkle,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [scheme.primary.withValues(alpha: 0.08), scheme.tertiary.withValues(alpha: 0.08)]),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: scheme.primary.withValues(alpha: 0.30), width: 1.5, style: BorderStyle.solid),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline, color: scheme.primary, size: 22),
              SizedBox(width: 8),
              Text(
                'Yeni Hatırlatma Ekle  (${3 - _aktifSayisi} yer kaldı)',
                style: TextStyle(fontWeight: FontWeight.w800, color: scheme.primary, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kartim(ColorScheme scheme, List<Widget> children, {required String title}) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: scheme.primary.withValues(alpha: 0.04), blurRadius: 12, offset: Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)), SizedBox(height: 8), ...children],
      ),
    );
  }
}

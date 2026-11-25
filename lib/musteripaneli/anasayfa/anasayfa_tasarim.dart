// ignore_for_file: invalid_use_of_protected_member
part of 'anasayfa.dart';

/// Tasarımın yuvarlak hatlı yazı tipi (Figtree; inmezse tema yazı tipine düşer)
TextStyle _dYazi({double? fontSize, double? height, FontWeight? fontWeight, Color? color, double? letterSpacing}) => GoogleFonts.figtree(
    fontSize: fontSize, height: height, fontWeight: fontWeight, color: color, letterSpacing: letterSpacing ?? 0);

/// Müşteri ana sayfası görünümü ("Mor Işıltılı Güzellik Uygulaması" tasarımı, 852 px genişlik).
/// Ölçüler ekran genişliğine oranlanır (tablette en çok 600 dp). Sabit parçalar (üst görsel, çark
/// kartı, ikonlar) tasarımdan kesilmiştir; yazı ve sayılar canlıdır.
extension _AnasayfaTasarim on _MusteriAnsayfaState {
  MusteriPalet get _p => MusteriPalet.of(context);
  double get _genislik => math.min(MediaQuery.of(context).size.width, 600.0);
  double _x(num px) => _genislik * px / 852;

  void _git(Widget sayfa, {VoidCallback? sonra}) {
    Navigator.push(
      context,
      PageTransition(type: PageTransitionType.rightToLeft, duration: const Duration(milliseconds: 400), child: sayfa),
    ).then((_) => sonra?.call());
  }

  String get _salonId => widget.isletmebilgi is Map ? (widget.isletmebilgi['id']?.toString() ?? '') : '';

  int get _okunmamis => int.tryParse(ozetsayfabilgi?.okunmamisbildirimler ?? '') ?? 0;

  int _kn(Map<String, dynamic> k, String a) => int.tryParse((k[a] ?? 0).toString()) ?? 0;

  /// Hâlâ açık olan kampanyalar + kapanmış ama kullanılmamış hakkı olanlar
  List<Map<String, dynamic>> get _gorunenKampanyalar {
    final s = DateTime.now();
    final bugun = DateTime(s.year, s.month, s.day);
    return _ikramKartlari.where((k) {
      if (_kn(k, 'hak') > 0) return true;
      if (_kn(k, 'aktif') != 1) return false;
      final bas = DateTime.tryParse((k['kampanya_baslangic'] ?? '').toString());
      if (bas != null && bas.isAfter(bugun)) return false;
      final bit = DateTime.tryParse((k['kampanya_bitis'] ?? '').toString());
      return bit == null || !bit.isBefore(bugun);
    }).toList();
  }

  void _kampanyaAc([Map<String, dynamic>? k]) => _git(
        IkramHizmetlerimPage(md: widget.md, salonId: _salonId, kuralId: k == null ? null : _kn(k, 'kural_id')),
        sonra: _ikramYukle,
      );

  void _randevularimAc() => _git(
        MusteriRandevulari(md: widget.md, isletmebilgi: widget.isletmebilgi, geriButonu: true),
        sonra: _yaklasanYukle,
      );

  void _bildirimlerAc() => _git(
        MusteriBildirimlerScreen(isletmebilgi: widget.isletmebilgi, md: widget.md, onNotificationRead: initialize),
        sonra: initialize,
      );

  void _puanOdulAc() => _git(PuanOdullerimPage(md: widget.md, salonId: _salonId.isEmpty ? null : _salonId));

  Widget _sayfa() {
    final kampanyalar = _gorunenKampanyalar;
    return Center(
      child: SizedBox(
        width: _genislik,
        child: ListView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + _x(16)),
          children: [
            _ustBolum(),
            SizedBox(height: _x(14)),
            _carkVeKisayollar(),
            SizedBox(height: _x(28)),
            if (_grupRezervasyonAktif) ...[
              _grupRezervasyonKart(context),
              SizedBox(height: _x(28)),
            ],
            _yaklasanRandevu(),
            SizedBox(height: _x(26)),
            if (kampanyalar.isNotEmpty) ...[
              _kampanyaBolumu(kampanyalar),
              SizedBox(height: _x(20)),
            ],
            if (_reklamlar.isNotEmpty) ...[
              _bolumBasligi('Sana Özel'),
              SizedBox(height: _x(14)),
              _reklamKartlari(context),
              SizedBox(height: _x(16)),
            ],
            _digerOzellikler(),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- üst bölüm

  Widget _ustBolum() {
    final ust = MediaQuery.of(context).padding.top;
    final kay = ust - _x(57); // tasarımdaki saat çubuğu 57 px; görsel telefonun çubuğuna hizalanır
    final ad = widget.md.name.trim().isEmpty ? 'Misafir' : widget.md.name.trim().split(' ').first;
    Widget yer(num sol, num y, Widget c, {num? w, num? h}) => Positioned(
          left: _x(sol),
          top: kay + _x(y),
          width: w == null ? null : _x(w),
          height: h == null ? null : _x(h),
          child: c,
        );

    return SizedBox(
      height: kay + _x(548),
      child: Stack(clipBehavior: Clip.hardEdge, children: [
        Positioned.fill(
          child: MarkaIsikEfekti(merkez: Offset(_x(612), kay + _x(262)), yaricap: _x(146)),
        ),
        yer(
          32,
          78,
          GestureDetector(
            onTap: _bildirimlerAc,
            child: Stack(clipBehavior: Clip.none, children: [
              _daire(Icons.notifications_rounded),
              if (_okunmamis > 0) Positioned(left: _x(62), top: _x(6), child: MusteriRozet(_okunmamis, _x(34))),
            ]),
          ),
          w: 130,
          h: 84,
        ),
        yer(
          738,
          78,
          Semantics(
            button: true,
            label: 'Profilim',
            child: GestureDetector(
              onTap: () => _git(MusteriProfilBilgileri(kullanici: widget.md)),
              child: _daire(Icons.person_outline_rounded),
            ),
          ),
        ),
        yer(43, 190, Text('Merhaba 👋', style: _dYazi(fontSize: _x(28), height: 1.2, fontWeight: FontWeight.w700, color: _p.baslik))),
        yer(
          43,
          226,
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(children: [
              Text(ad,
                  style: _dYazi(fontSize: _x(58), height: 1.1, fontWeight: FontWeight.w800, color: _p.baslik, letterSpacing: -1)),
              SizedBox(width: _x(16)),
              _degrade(Icons.favorite_rounded, _x(44)),
            ]),
          ),
          w: 262,
          h: 66,
        ),
        yer(
          43,
          300,
          Text('Güzelliğin için\nher zaman yanındayız ✨',
              style: _dYazi(fontSize: _x(22), height: 1.3, fontWeight: FontWeight.w500, color: _p.metin)),
        ),
        ..._bakiyeKarti(yer),
      ]),
    );
  }

  Widget _daire(IconData ikon) => Container(
        width: _x(82),
        height: _x(82),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _p.kart.withValues(alpha: 0.9),
          boxShadow: [BoxShadow(color: _p.ana.withValues(alpha: 0.14), blurRadius: 14, offset: const Offset(0, 4))],
        ),
        child: Icon(ikon, color: _p.ana, size: _x(46)),
      );

  /// İkram bakiyesi kartı.
  /// Salonda ikram kampanyası yoksa sadakat puanı ve üyelik gösterilir.
  List<Widget> _bakiyeKarti(Widget Function(num, num, Widget, {num? w, num? h}) yer) {
    final ikramVar = _ikramKartlari.isNotEmpty;
    var oran = 0.0;
    for (final k in _ikramKartlari) {
      final g = math.max(1, _kn(k, 'gereken_adet'));
      if (_kn(k, 'hak') > 0) {
        oran = 1;
      } else if (_kn(k, 'aktif') == 1) {
        oran = math.max(oran, (_kn(k, 'ilerleme') / g).clamp(0.0, 1.0));
      }
    }
    TextStyle etiket = _dYazi(fontSize: _x(20), height: 1.2, fontWeight: FontWeight.w600, color: _p.baslik);
    Widget sigdir(Widget c) => FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: c);

    return [
      yer(30, 394, Container(decoration: _camKutu(50)), w: 792, h: 138),
      yer(
        54,
        418,
        Container(
          padding: EdgeInsets.all(_x(10)),
          decoration: BoxDecoration(color: _p.yumusak.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(_x(28))),
          child: ColorFiltered(colorFilter: _p.gorselFiltre, child: Image.asset('images/musteri_kutu3d.png', fit: BoxFit.contain)),
        ),
        w: 90,
        h: 90,
      ),
      yer(
        656,
        439,
        Container(
          padding: EdgeInsets.only(left: _x(18), right: _x(6)),
          decoration: BoxDecoration(color: _p.yumusak, borderRadius: BorderRadius.circular(_x(29))),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(children: [
              Text('Detaylar', style: _dYazi(fontSize: _x(21), fontWeight: FontWeight.w600, color: _p.ana)),
              Icon(Icons.chevron_right_rounded, color: _p.ana, size: _x(34)),
            ]),
          ),
        ),
        w: 146,
        h: 58,
      ),
      yer(166, 416, sigdir(Text(ikramVar ? 'İkram Bakiyen' : 'Sadakat Puanın', style: etiket)), w: 155, h: 27),
      yer(
        166,
        443,
        sigdir(Text(ikramVar ? '$_ikramHak' : _formatPuan(ozetsayfabilgi?.sadakatPuani ?? 0),
            style: _dYazi(fontSize: _x(44), height: 1.1, fontWeight: FontWeight.w800, color: _p.baslik))),
        w: 155,
        h: 50,
      ),
      yer(166, 492, sigdir(Text(ikramVar ? 'Hediye Hizmet' : 'Puan', style: _dYazi(fontSize: _x(19), height: 1.2, color: _p.metin))),
          w: 155, h: 25),
      yer(331, 424, Container(color: _p.ana.withValues(alpha: 0.35)), w: 1.6, h: 78),
      yer(372, 416, Icon(Icons.star_rounded, color: _p.ana, size: _x(34))),
      yer(414, 418, sigdir(Text(ikramVar ? 'Kampanya Oranın' : 'Üyeliğin', style: etiket)), w: 200, h: 27),
      yer(
        374,
        456,
        sigdir(Text(ikramVar ? '%${(oran * 100).round()}' : (ozetsayfabilgi?.kategoriLabel ?? 'Müşteri'),
            style: _dYazi(fontSize: _x(ikramVar ? 46 : 28), height: 1.1, fontWeight: FontWeight.w800, color: _p.baslik))),
        w: ikramVar ? 140 : 250,
        h: 54,
      ),
      if (ikramVar) yer(530, 444, CustomPaint(painter: _DHalka(oran, _x(11), _p)), w: 76, h: 76),
      yer(
        30,
        394,
        Semantics(
          button: true,
          label: 'Detaylar',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => ikramVar ? _kampanyaAc() : _puanOdulAc(),
          ),
        ),
        w: 796,
        h: 138,
      ),
    ];
  }

  // ---------------------------------------------------------------- çark + kısayollar

  BoxDecoration _camKutu(num r) => BoxDecoration(
        color: _p.kart,
        borderRadius: BorderRadius.circular(_x(r)),
        border: Border.all(color: _p.kartKenar),
        boxShadow: [BoxShadow(color: _p.ana.withValues(alpha: _p.koyuMod ? 0 : 0.08), blurRadius: 16, offset: const Offset(0, 6))],
      );

  LinearGradient get _dugmeDegrade =>
      LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: _p.dugme);

  /// Tek renk ikon/görseli temanın degradesiyle boyar
  Widget _boya(Widget c) => ShaderMask(
        shaderCallback: (r) => LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(_p.ana, Colors.white, 0.18)!, _p.ana],
        ).createShader(r),
        blendMode: BlendMode.srcIn,
        child: c,
      );

  Widget _degrade(IconData ikon, double boyut) => _boya(Icon(ikon, size: boyut, color: Colors.white));

  Widget _gorselIkon(String ad) => _boya(Image.asset('images/musteri_i_$ad.png', fit: BoxFit.contain));

  Widget _carkVeKisayollar() {
    Widget kisayol(Widget ikon, String yazi, VoidCallback onTap) => Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: EdgeInsets.only(left: _x(18), right: _x(8)),
              decoration: _camKutu(30),
              child: Row(children: [
                SizedBox(width: _x(46), height: _x(48), child: Center(child: ikon)),
                SizedBox(width: _x(9)),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(yazi, style: _dYazi(fontSize: _x(20), fontWeight: FontWeight.w600, color: _p.baslik)),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: _p.ana, size: _x(32)),
              ]),
            ),
          ),
        );
    Widget gorsel(String ad) => _gorselIkon(ad);
    final ara = SizedBox(height: _x(9));

    return Padding(
      padding: EdgeInsets.only(left: _x(32), right: _x(27)),
      child: SizedBox(
        height: _x(302),
        child: Row(children: [
          SizedBox(width: _x(517), height: _x(302), child: _studyo ? _studyoKarti() : _carkKarti()),
          SizedBox(width: _x(27)),
          Expanded(
            child: Column(children: [
              if (_onlineRandevuAktif)
                kisayol(gorsel('randevu'), 'Randevu Al', _onRandevuAlPressed)
              else
                kisayol(gorsel('randevu'), 'Randevularım', _randevularimAc),
              ara,
              kisayol(gorsel('kampanya'), 'Kampanyalarım', _kampanyaAc),
              ara,
              kisayol(_degrade(Icons.spa_rounded, _x(42)), 'Seanslarım',
                  () => _git(SeanslarDashboard(isletmebilgi: widget.isletmebilgi, md: widget.md))),
              ara,
              kisayol(gorsel('destek'), 'Destek Al', _destekAc),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _carkKarti() => Semantics(
        button: true,
        label: 'Çarkıfelek, Çevir ve Kazan',
        child: GestureDetector(
          onTap: () => _git(WheelPage(md: widget.md, isletmebilgi: widget.isletmebilgi)),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_x(38)),
              gradient: _dugmeDegrade,
              boxShadow: [BoxShadow(color: _p.ana.withValues(alpha: 0.24), blurRadius: 18, offset: const Offset(0, 8))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_x(38)),
              child: Stack(children: [
                for (final (sol, y, cap) in const [(350, -80, 260), (-60, 190, 220), (190, 20, 150)])
                  Positioned(
                    left: _x(sol),
                    top: _x(y),
                    width: _x(cap),
                    height: _x(cap),
                    child: DecoratedBox(
                        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.07))),
                  ),
                Positioned(
                  left: _x(12),
                  top: _x(30),
                  width: _x(240),
                  height: _x(250),
                  child: DonenCark(filtre: _p.gorselFiltre),
                ),
                Positioned(
                  right: _x(24),
                  top: _x(34),
                  child: Text('🎁', style: TextStyle(fontSize: _x(38), height: 1.1)),
                ),
                Positioned(
                  left: _x(268),
                  right: _x(16),
                  top: _x(86),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Çarkıfelek',
                          style: _dYazi(color: Colors.white, fontSize: _x(38), height: 1.15, fontWeight: FontWeight.w800)),
                    ),
                    SizedBox(height: _x(6)),
                    Text('Şansını dene,\nhediye kazan!',
                        style: _dYazi(color: Colors.white.withValues(alpha: 0.92), fontSize: _x(22), height: 1.25)),
                    SizedBox(height: _x(20)),
                    Container(
                      height: _x(54),
                      padding: EdgeInsets.only(left: _x(22), right: _x(10)),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(_x(27)),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(children: [
                          Text('Çevir & Kazan', style: _dYazi(color: Colors.white, fontSize: _x(21), fontWeight: FontWeight.w700)),
                          Icon(Icons.chevron_right_rounded, color: Colors.white, size: _x(34)),
                        ]),
                      ),
                    ),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      );

  /// Stüdyo modunda çark yok: yerine ders/randevu kartı
  Widget _studyoKarti() {
    final ders = widget.isletmebilgi is Map && widget.isletmebilgi['grup_dersi_aktif']?.toString() == '1';
    return GestureDetector(
      onTap: () => ders
          ? _git(GrupDerslerimEkran(userId: widget.md.id.toString(), salonId: _salonId, rezervasyonAcik: _grupRezervasyonAktif))
          : _randevularimAc(),
      child: Container(
        padding: EdgeInsets.all(_x(40)),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_x(38)),
          gradient: _dugmeDegrade,
          boxShadow: [BoxShadow(color: _p.ana.withValues(alpha: 0.28), blurRadius: 18, offset: const Offset(0, 8))],
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(ders ? Icons.groups_rounded : Icons.event_available_rounded, color: Colors.white, size: _x(72)),
          SizedBox(height: _x(16)),
          Text(ders ? 'Derslerim' : 'Randevularım',
              style: _dYazi(color: Colors.white, fontSize: _x(38), fontWeight: FontWeight.w800)),
          SizedBox(height: _x(6)),
          Text(ders ? 'Grup derslerini görüntüle' : 'Yaklaşan ve geçmiş randevuların',
              style: _dYazi(color: Colors.white.withValues(alpha: 0.9), fontSize: _x(23))),
        ]),
      ),
    );
  }

  void _destekAc() {
    Widget satir(IconData ikon, Color renk, String baslik, String alt, String mode) => ListTile(
          leading: CircleAvatar(backgroundColor: renk.withValues(alpha: 0.12), child: Icon(ikon, color: renk)),
          title: Text(baslik, style: _dYazi(fontWeight: FontWeight.w700, color: _p.baslik)),
          subtitle: Text(alt),
          onTap: () {
            Navigator.pop(context);
            _iletisimAksiyon(context, mode: mode);
          },
        );
    showModalBottomSheet(
      context: context,
      backgroundColor: _p.kart,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            satir(Icons.phone_rounded, _p.ana, 'Salonu Ara', 'Telefonla görüşün', 'ara'),
            satir(FontAwesomeIcons.whatsapp, const Color(0xFF25D366), 'WhatsApp', 'Mesaj gönderin', 'wp'),
          ]),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- yaklaşan randevu

  Future<void> _yaklasanYukle() async {
    try {
      final simdi = DateTime.now();
      String g(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final aralik = 'Özel:${g(simdi)}:${g(simdi.add(const Duration(days: 365)))}';
      Future<Map<String, dynamic>> cek(int sayfa) =>
          randevularigetir(widget.md.id.toString(), '', 'Tümü', 'Tümü', aralik, '$sayfa', '', '', '', true);
      final ilk = await cek(1);
      final satirlar = <dynamic>[...(ilk['data'] as List? ?? const [])];
      // Sıralama yönünden bağımsız: en yakın randevu ilk ya da son sayfadadır
      final son = int.tryParse((ilk['last_page'] ?? 1).toString()) ?? 1;
      if (son > 1) satirlar.addAll((await cek(son))['data'] as List? ?? const []);

      Randevu? enYakin;
      DateTime? enYakinTarih;
      for (final j in satirlar) {
        final r = Randevu.fromJson(Map<String, dynamic>.from(j as Map));
        if (r.durum != '0' && r.durum != '1') continue;
        final t = DateTime.tryParse(r.tarih.trim());
        if (t == null || t.isBefore(simdi)) continue;
        if (enYakinTarih == null || t.isBefore(enYakinTarih)) {
          enYakin = r;
          enYakinTarih = t;
        }
      }
      if (!mounted) return;
      setState(() {
        _yaklasan = enYakin;
        _yaklasanTarih = enYakinTarih;
      });
    } catch (_) {
      // randevu yüklenemezse kart "yok" durumunda kalır
    }
  }

  String _hizmetAdi(Randevu r) {
    final adlar = <String>[];
    if (r.hizmetler is List) {
      for (final h in r.hizmetler as List) {
        final ic = h is Map ? h['hizmetler'] : null;
        final ad = (ic is Map ? ic['hizmet_adi'] : null)?.toString().trim() ?? '';
        if (ad.isNotEmpty && !adlar.contains(ad)) adlar.add(ad);
      }
    }
    return adlar.isEmpty ? 'Randevu' : adlar.join(', ');
  }

  Widget _yaklasanRandevu() {
    const aylar = ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
    final r = _yaklasan;
    final t = _yaklasanTarih;
    final hizmet = r == null ? '' : _hizmetAdi(r);
    final tarih = t == null
        ? ''
        : '${t.day} ${aylar[t.month - 1]} ${t.year}  •  ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    final dugme = r != null || _onlineRandevuAktif;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: _x(28)),
      child: Container(
        decoration: _camKutu(42),
        child: Column(children: [
          SizedBox(
            height: _x(70),
            child: Row(children: [
              SizedBox(width: _x(28)),
              SizedBox(width: _x(50), height: _x(52), child: _gorselIkon('takvim')),
              SizedBox(width: _x(14)),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text('Yaklaşan Randevunuz', style: _dYazi(fontSize: _x(27), fontWeight: FontWeight.w700, color: _p.baslik)),
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _randevularimAc,
                child: Row(children: [
                  Text('Tümünü Gör', style: _dYazi(fontSize: _x(21), color: _p.ana, fontWeight: FontWeight.w500)),
                  Icon(Icons.chevron_right_rounded, color: _p.ana, size: _x(38)),
                  SizedBox(width: _x(12)),
                ]),
              ),
            ]),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(_x(34), _x(12), _x(24), _x(16)),
            decoration: BoxDecoration(
              color: _p.yumusak.withValues(alpha: 0.22),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(_x(42))),
            ),
            child: Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(_x(28)),
                child: SizedBox(
                  width: _x(146),
                  height: _x(94),
                  child: Image.asset(ikramHazirGorsel(hizmet), fit: BoxFit.cover),
                ),
              ),
              SizedBox(width: _x(24)),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(r == null ? 'Yaklaşan randevunuz yok' : hizmet,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _dYazi(fontSize: _x(23), fontWeight: FontWeight.w600, color: _p.baslik)),
                  SizedBox(height: _x(8)),
                  if (r != null)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(children: [
                        Icon(Icons.calendar_month_rounded, color: _p.ana, size: _x(28)),
                        SizedBox(width: _x(8)),
                        Text(tarih, style: _dYazi(fontSize: _x(22), fontWeight: FontWeight.w600, color: _p.baslik)),
                      ]),
                    )
                  else
                    Text('Size uygun saati hemen seçin',
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: _dYazi(fontSize: _x(20), color: _p.metin)),
                  if (r != null && r.durum == '0') ...[
                    SizedBox(height: _x(4)),
                    Text('Onay bekliyor',
                        style: _dYazi(fontSize: _x(18), fontWeight: FontWeight.w600, color: const Color(0xFFB45309))),
                  ],
                ]),
              ),
              if (dugme) ...[
                SizedBox(width: _x(12)),
                GestureDetector(
                  onTap: r != null ? _randevularimAc : _onRandevuAlPressed,
                  child: Container(
                    width: _x(198),
                    height: _x(77),
                    decoration: BoxDecoration(
                      gradient: _dugmeDegrade,
                      borderRadius: BorderRadius.circular(_x(39)),
                      boxShadow: [BoxShadow(color: _p.ana.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 5))],
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(r != null ? 'Randevumu\nGörüntüle' : 'Randevu Al',
                          textAlign: TextAlign.center,
                          style: _dYazi(color: Colors.white, fontSize: _x(19), height: 1.15, fontWeight: FontWeight.w500)),
                      SizedBox(width: _x(6)),
                      Icon(Icons.chevron_right_rounded, color: Colors.white, size: _x(34)),
                    ]),
                  ),
                ),
              ],
            ]),
          ),
        ]),
      ),
    );
  }

  // ---------------------------------------------------------------- kampanyalar

  Widget _bolumBasligi(String yazi, {Widget? ikon}) => Padding(
        padding: EdgeInsets.symmetric(horizontal: _x(32)),
        child: Row(children: [
          if (ikon != null) ...[ikon, SizedBox(width: _x(12))],
          Text(yazi, style: _dYazi(fontSize: _x(27), fontWeight: FontWeight.w700, color: _p.baslik)),
          SizedBox(width: _x(20)),
          Expanded(
            child: Container(
              height: 1.4,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [_p.ana.withValues(alpha: 0), _p.ana.withValues(alpha: 0.3), _p.ana.withValues(alpha: 0)]),
              ),
            ),
          ),
        ]),
      );

  Widget _kampanyaBolumu(List<Map<String, dynamic>> liste) => Column(children: [
        _bolumBasligi('Aktif Kampanyalarım',
            ikon: SizedBox(width: _x(50), height: _x(54), child: _gorselIkon('hediye'))),
        SizedBox(height: _x(8)),
        SizedBox(
          height: _x(228),
          child: PageView.builder(
            controller: _kampanyaPc,
            itemCount: liste.length,
            onPageChanged: (i) => setState(() => _kampanyaSayfa = i),
            itemBuilder: (_, i) => _kampanyaKarti(liste[i]),
          ),
        ),
        if (liste.length > 1) ...[
          SizedBox(height: _x(10)),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var i = 0; i < liste.length; i++)
              Container(
                width: _x(15),
                height: _x(15),
                margin: EdgeInsets.symmetric(horizontal: _x(7)),
                decoration: BoxDecoration(shape: BoxShape.circle, color: i == _kampanyaSayfa ? _p.ana : _p.yumusak),
              ),
          ]),
        ],
      ]);

  Widget _kampanyaKarti(Map<String, dynamic> k) {
    final gereken = math.max(1, _kn(k, 'gereken_adet'));
    final hediye = _kn(k, 'ucretsiz_adet');
    final hak = _kn(k, 'hak');
    final ilerleme = hak > 0 ? gereken : _kn(k, 'ilerleme').clamp(0, gereken);
    final hizmet = (k['hizmet_adi'] ?? '').toString();
    final g = (k['gorsel'] ?? '').toString();
    final hazir = Image.asset(ikramHazirGorsel(hizmet), fit: BoxFit.cover);
    final bit = DateTime.tryParse((k['kampanya_bitis'] ?? '').toString());
    String? kalan;
    if (bit != null) {
      final s = DateTime.now();
      final gun = DateTime(bit.year, bit.month, bit.day).difference(DateTime(s.year, s.month, s.day)).inDays;
      kalan = gun < 0 ? 'Süre doldu' : (gun == 0 ? 'Son gün' : '$gun gün kaldı');
    }
    Widget nokta(bool dolu) => Container(
          width: _x(24),
          height: _x(24),
          margin: EdgeInsets.only(left: _x(12)),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: dolu ? _p.ana : null,
            border: dolu ? null : Border.all(color: _p.ana.withValues(alpha: 0.3), width: 1.6),
          ),
        );

    return GestureDetector(
      onTap: () => _kampanyaAc(k),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: _x(25), vertical: _x(6)),
        padding: EdgeInsets.all(_x(12)),
        decoration: _camKutu(42),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(_x(32)),
            child: SizedBox(
              width: _x(256),
              height: double.infinity,
              child: g.isEmpty
                  ? hazir
                  : Image.network('https://app.randevumcepte.com.tr$g', fit: BoxFit.cover, errorBuilder: (_, __, ___) => hazir),
            ),
          ),
          SizedBox(width: _x(22)),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  height: _x(52),
                  padding: EdgeInsets.symmetric(horizontal: _x(16)),
                  decoration: BoxDecoration(
                    gradient: _dugmeDegrade,
                    borderRadius: BorderRadius.circular(_x(16)),
                  ),
                  alignment: Alignment.center,
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('👑', style: _dYazi(fontSize: _x(26), height: 1.2)),
                    SizedBox(width: _x(8)),
                    Text('$gereken + $hediye',
                        style: _dYazi(color: Colors.white, fontSize: _x(34), height: 1.1, fontWeight: FontWeight.w700)),
                  ]),
                ),
                const Spacer(),
                if (kalan != null)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: _x(14), vertical: _x(8)),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3DC),
                      borderRadius: BorderRadius.circular(_x(24)),
                    ),
                    child: Row(children: [
                      Icon(Icons.timer_outlined, color: const Color(0xFFD97706), size: _x(28)),
                      SizedBox(width: _x(6)),
                      Text(kalan, style: _dYazi(fontSize: _x(19), fontWeight: FontWeight.w600, color: const Color(0xFFD97706))),
                    ]),
                  ),
              ]),
              const Spacer(),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('$hizmet Kampanyası', style: _dYazi(fontSize: _x(23), fontWeight: FontWeight.w700, color: _p.baslik)),
              ),
              SizedBox(height: _x(2)),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(hak > 0 ? '$hak ücretsiz hakkınız var 🎁' : '$gereken hizmet al, $hediye hizmet hediye!',
                    style: _dYazi(
                        fontSize: _x(20),
                        fontWeight: hak > 0 ? FontWeight.w700 : FontWeight.w400,
                        color: hak > 0 ? const Color(0xFF15803D) : _p.metin)),
              ),
              const Spacer(),
              Row(children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: _x(9), vertical: _x(7)),
                        decoration: BoxDecoration(color: _p.yumusak, borderRadius: BorderRadius.circular(_x(20))),
                        child: Text('$ilerleme/$gereken',
                            style: _dYazi(fontSize: _x(21), height: 1.1, fontWeight: FontWeight.w700, color: _p.ana)),
                      ),
                      for (var i = 0; i < gereken; i++) nokta(i < ilerleme),
                    ]),
                  ),
                ),
                SizedBox(width: _x(10)),
                Container(
                  height: _x(56),
                  padding: EdgeInsets.only(left: _x(22), right: _x(10)),
                  decoration: BoxDecoration(
                    color: _p.yumusak,
                    borderRadius: BorderRadius.circular(_x(28)),
                  ),
                  child: Row(children: [
                    Text('Detaylar', style: _dYazi(fontSize: _x(20), fontWeight: FontWeight.w600, color: _p.ana)),
                    Icon(Icons.chevron_right_rounded, color: _p.ana, size: _x(34)),
                  ]),
                ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  // ---------------------------------------------------------------- diğer özellikler

  Widget _digerOzellikler() {
    Widget gorsel(String ad) => _gorselIkon(ad);
    final ogeler = <(Widget, String, VoidCallback)>[
      if (!_studyo) (gorsel('kupa'), 'Puan\nÖdülleri', _puanOdulAc),
      if (!_studyo) (_degrade(Icons.confirmation_number_rounded, _x(48)), 'Kuponlarım', () => _git(OdullerimPage(md: widget.md))),
      (gorsel('yorum'), 'Müşteri\nYorumları', () => _git(const SalonYorumlariSayfasi())),
      (gorsel('duyuru'), 'Kampanya ve\nDuyurular', _duyurularAc),
      (
        _degrade(Icons.inventory_2_rounded, _x(46)),
        'Paketlerim',
        () => _git(MusteriALinanPaketlerDashboard(
            kullanicirolu: widget.kullanicirolu, isletmebilgi: widget.isletmebilgi, kullanici: widget.md))
      ),
      if (!_studyo)
        (
          _degrade(Icons.shopping_bag_rounded, _x(46)),
          'Ürünlerim',
          () => _git(MusteriALinanUrunlerDashboard(
              kullanicirolu: widget.kullanicirolu, isletmebilgi: widget.isletmebilgi, kullanici: widget.md))
        ),
      (gorsel('takvim'), 'Randevularım', _randevularimAc),
      if (!_studyo) (_degrade(Icons.workspace_premium_rounded, _x(50)), _uyelikYazi, _puanOdulAc),
    ];
    Widget kutu((Widget, String, VoidCallback) o) => GestureDetector(
          onTap: o.$3,
          child: Container(
            decoration: _camKutu(36),
            child: Stack(children: [
              Positioned.fill(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  SizedBox(height: _x(52), child: Center(child: o.$1)),
                  SizedBox(height: _x(4)),
                  SizedBox(
                    height: _x(48),
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(o.$2,
                            textAlign: TextAlign.center,
                            style: _dYazi(fontSize: _x(19), height: 1.15, fontWeight: FontWeight.w600, color: _p.baslik)),
                      ),
                    ),
                  ),
                ]),
              ),
              Positioned(
                right: _x(10),
                top: _x(36),
                child: Icon(Icons.chevron_right_rounded, color: _p.ana.withValues(alpha: 0.55), size: _x(30)),
              ),
            ]),
          ),
        );

    return Stack(clipBehavior: Clip.none, children: [
      Column(children: [
        _bolumBasligi('Diğer Özellikler'),
        SizedBox(height: _x(14)),
        for (var i = 0; i < ogeler.length; i += 4)
          Padding(
            padding: EdgeInsets.fromLTRB(_x(29), 0, _x(29), _x(16)),
            child: Row(children: [
              for (var j = i; j < i + 4; j++) ...[
                if (j > i) SizedBox(width: _x(16)),
                Expanded(child: j < ogeler.length ? SizedBox(height: _x(131), child: kutu(ogeler[j])) : const SizedBox()),
              ],
            ]),
          ),
      ]),
    ]);
  }

  String get _uyelikYazi =>
      '${ozetsayfabilgi?.kategoriLabel ?? 'Üyeliğim'}\n${_formatPuan(ozetsayfabilgi?.sadakatPuani ?? 0)} puan';

  void _duyurularAc() => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: _p.zemin,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (c) => SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(c).size.height * 0.8),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: _duyurularCard(context),
            ),
          ),
        ),
      );
}

/// Kampanya oranı halkası (leylak zemin, mor-pembe yay)
class _DHalka extends CustomPainter {
  final double oran;
  final double kalinlik;
  final MusteriPalet p;
  _DHalka(this.oran, this.kalinlik, this.p);

  @override
  void paint(Canvas canvas, Size size) {
    final m = size.center(Offset.zero);
    final r = size.shortestSide / 2 - kalinlik / 2;
    final rect = Rect.fromCircle(center: m, radius: r);
    canvas.drawCircle(
        m,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = kalinlik
          ..color = p.yumusak);
    if (oran <= 0) return;
    canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * oran.clamp(0.0, 1.0),
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = kalinlik
          ..strokeCap = StrokeCap.round
          ..shader = SweepGradient(colors: [p.ana, p.anaKoyu, p.ana]).createShader(rect));
  }

  @override
  bool shouldRepaint(covariant _DHalka e) => e.oran != oran || e.kalinlik != kalinlik || e.p.ana != p.ana;
}

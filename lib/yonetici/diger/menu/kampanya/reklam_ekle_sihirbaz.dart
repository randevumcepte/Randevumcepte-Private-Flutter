import 'package:flutter/material.dart';
import 'package:randevu_sistem/Backend/backend.dart';

/// Reklam (Kampanya) Ekle/Duzenle sihirbazi — web reklam-ekle-modal paritesi.
/// Adimlar: Kanal -> Hedef Kitle -> Hizmet/Urun/Paket -> Sablon & Mesaj -> Indirim -> Planlama.
/// kampanyaId verilirse DUZENLEME modu (kampanyaDuzenleGetir ile dolu acilir).
class ReklamEkleSihirbaz extends StatefulWidget {
  final dynamic isletmebilgi;
  final dynamic kampanyaId; // null = yeni
  final String? kampanyaAdi;

  const ReklamEkleSihirbaz({
    Key? key,
    required this.isletmebilgi,
    this.kampanyaId,
    this.kampanyaAdi,
  }) : super(key: key);

  @override
  State<ReklamEkleSihirbaz> createState() => _ReklamEkleSihirbazState();
}

class _ReklamEkleSihirbazState extends State<ReklamEkleSihirbaz> {
  static const Color _mor = Color(0xFF7B2FB8);

  String? _salonId;
  bool _yukleniyor = true;
  bool _kaydediyor = false;

  // Form verileri (dropdown kaynaklari)
  List<Map<String, dynamic>> _hizmetler = [];
  List<Map<String, dynamic>> _urunler = [];
  List<Map<String, dynamic>> _paketler = [];
  List<Map<String, dynamic>> _sablonlar = [];
  List<Map<String, dynamic>> _gruplar = [];

  // Secimler
  int _gorevTuru = 1; // 1=Arama 2=SMS 3=Bildirim 4=Bilgilendirme
  String _preset = 'all'; // all/sadik/aktif/pasif/son1yil/grup
  String _cinsiyet = ''; // ''=Tumu, erkekler, kadinlar
  String? _grupDeger; // haricigrup-X
  String? _hizmetDeger; // hizmet-X
  String? _urunDeger; // urun-X
  String? _paketDeger; // paket-X
  String _seciliSablonId = '';
  final TextEditingController _mesajCtrl = TextEditingController();

  bool _yuzdeIndirim = true; // true=%, false=X Al Y Ode
  final TextEditingController _yuzdeCtrl = TextEditingController(text: '10');
  final TextEditingController _xalCtrl = TextEditingController(text: '2');
  final TextEditingController _yodeCtrl = TextEditingController(text: '1');
  final TextEditingController _kodCtrl = TextEditingController();

  DateTime _baslangic = DateTime.now();
  DateTime _bitis = DateTime.now().add(const Duration(days: 30));
  TimeOfDay _saat = TimeOfDay.now();

  bool _hedefDegisti = false; // duzenlemede hedef kitle degistiyse true

  int? _kitleSayisi; // secili hedef kitle tahmini kisi sayisi
  bool _kitleSayiliyor = false;

  static const Map<int, String> _kanallar = {
    1: 'Santral Arama',
    2: 'SMS',
    3: 'Uygulama Bildirimi',
    4: 'Bilgilendirme',
  };

  static const Map<String, String> _presetler = {
    'all': 'Tüm Müşterilerim',
    'sadik': 'Sadık Müşterilerim',
    'aktif': 'Aktif Müşteriler',
    'pasif': 'Geri Kazanılmalı',
    'son1yil': 'Son 1 Yılın Müşterileri',
    'grup': 'Özel Grubum',
  };

  @override
  void initState() {
    super.initState();
    _baslat();
  }

  @override
  void dispose() {
    _mesajCtrl.dispose();
    _yuzdeCtrl.dispose();
    _xalCtrl.dispose();
    _yodeCtrl.dispose();
    _kodCtrl.dispose();
    super.dispose();
  }

  Future<void> _baslat() async {
    _salonId = await secilisalonid();
    if (_salonId != null) {
      final form = await kampanyaFormVerileri(_salonId!);
      if (form != null && form['success'] == true) {
        _hizmetler = _liste(form['hizmetler']);
        _urunler = _liste(form['urunler']);
        _paketler = _liste(form['paketler']);
        _sablonlar = _liste(form['sablonlar']);
        _gruplar = _liste(form['gruplar']);
      }
      if (widget.kampanyaId != null) {
        await _duzenlemeDoldur();
      }
    }
    if (mounted) setState(() => _yukleniyor = false);
    _kitleGuncelle();
  }

  List<Map<String, dynamic>> _liste(dynamic v) {
    if (v is List) {
      return v.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  Future<void> _duzenlemeDoldur() async {
    final d = await kampanyaDuzenleGetir(_salonId!, widget.kampanyaId);
    if (d == null || d['success'] != true) return;
    _gorevTuru = int.tryParse('${d['gorev_turu']}') ?? 1;
    final hup = (d['hizmetUrunPaket'] ?? '').toString();
    // Deger ilgili listede yoksa null birak (Dropdown assertion atmasin).
    bool _varMi(List<Map<String, dynamic>> l, String v) => l.any((e) => e['value'].toString() == v);
    if (hup.startsWith('hizmet-') && _varMi(_hizmetler, hup)) _hizmetDeger = hup;
    else if (hup.startsWith('urun-') && _varMi(_urunler, hup)) _urunDeger = hup;
    else if (hup.startsWith('paket-') && _varMi(_paketler, hup)) _paketDeger = hup;
    _mesajCtrl.text = (d['mesaj'] ?? '').toString();
    _kodCtrl.text = (d['indirim_kodu'] ?? '').toString();
    _yuzdeIndirim = d['yuzde_mi'] == true;
    if ('${d['yuzde']}'.isNotEmpty) _yuzdeCtrl.text = '${d['yuzde']}';
    if ('${d['xal']}'.isNotEmpty) _xalCtrl.text = '${d['xal']}';
    if ('${d['yode']}'.isNotEmpty) _yodeCtrl.text = '${d['yode']}';
    final bt = DateTime.tryParse('${d['baslangic_tarihi']}');
    if (bt != null) _baslangic = bt;
    final et = DateTime.tryParse('${d['bitis_tarihi']}');
    if (et != null) _bitis = et;

    // Hedef kitle: kayitli filtre/grup/cinsiyet -> preset + grup + cinsiyet secili gelsin.
    final hf = (d['hedef_filtre'] ?? '').toString();
    final hg = (d['hedef_grup'] ?? '').toString();
    _cinsiyet = (d['hedef_cinsiyet'] ?? '').toString();
    if (hg.isNotEmpty) {
      _preset = 'grup';
      if (_varMi(_gruplar, hg)) _grupDeger = hg;
    } else if (hf == '6') {
      _preset = 'sadik';
    } else if (hf == '7') {
      _preset = 'aktif';
    } else if (hf == '8') {
      _preset = 'pasif';
    } else if (hf == '1') {
      _preset = 'son1yil';
    } else {
      _preset = 'all';
    }

    _hedefDegisti = false; // duzenleme acilisinda kitle degismedi say
  }

  String _tarihStr(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _saatStr(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  // Preset -> gelenGelmeyenMusteri filtresi
  String _presetFiltre() {
    switch (_preset) {
      case 'sadik':
        return '6';
      case 'aktif':
        return '7';
      case 'pasif':
        return '8';
      case 'son1yil':
        return '1';
      default:
        return '';
    }
  }

  String get _hizmetUrunPaket => _hizmetDeger ?? _urunDeger ?? _paketDeger ?? '';

  // Secili hedef kitle degisince tahmini kisi sayisini yenile.
  Future<void> _kitleGuncelle() async {
    if (_salonId == null) return;
    setState(() => _kitleSayiliyor = true);
    final sayi = await kampanyaKitleSayisi(
      _salonId!,
      filtre: _preset == 'grup' ? '' : _presetFiltre(),
      cinsiyet: _cinsiyet,
      grup: _preset == 'grup' ? (_grupDeger ?? '') : '',
    );
    if (mounted) {
      setState(() {
        _kitleSayisi = sayi;
        _kitleSayiliyor = false;
      });
    }
  }

  Future<void> _kaydet() async {
    if (_salonId == null) return;
    // Basit dogrulama
    if (_mesajCtrl.text.trim().isEmpty) {
      _uyari('Kampanya mesajı boş olamaz. Bir şablon seçin veya metin yazın.');
      return;
    }
    if (_kitleSayisi != null && _kitleSayisi == 0) {
      _uyari('Seçili hedef kitlede müşteri yok. Farklı bir kitle seçin.');
      return;
    }
    setState(() => _kaydediyor = true);

    final body = <String, dynamic>{
      'kampanya_id': widget.kampanyaId ?? '',
      'hedefDegisti': _hedefDegisti ? '1' : '0',
      'gorevTuru': '$_gorevTuru',
      'gelenGelmeyenMusteri': _preset == 'grup' ? '' : _presetFiltre(),
      'musteriGruplari': _preset == 'grup' ? (_grupDeger ?? '') : '',
      'katilimciTuru': _cinsiyet,
      'kampanyaKategori': '',
      'hizmetUrunPaket': _hizmetUrunPaket,
      'seciliSablonId': _seciliSablonId,
      'kampanya_sms': _mesajCtrl.text,
      'kampanyaKodu': _kodCtrl.text.trim(),
      'indirimTuru': _yuzdeIndirim,
      'Xal': _xalCtrl.text.trim(),
      'Yode': _yodeCtrl.text.trim(),
      'kampanyaIndirim': _yuzdeCtrl.text.trim(),
      'asistan_tarih': _tarihStr(_baslangic),
      'kampanyaGecerlilikTarihi': _tarihStr(_bitis),
      'asistan_saat': _saatStr(_saat),
    };

    final res = await kampanyaKaydet(_salonId!, body);
    if (mounted) setState(() => _kaydediyor = false);
    if (res != null && res['success'] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kampanya başarıyla kaydedildi'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } else {
      _uyari('Kampanya kaydedilemedi. Lütfen tekrar deneyin.');
    }
  }

  void _uyari(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    final duzenleme = widget.kampanyaId != null;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        title: Text(duzenleme ? 'Reklam Düzenle' : 'Yeni Reklam Oluştur',
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
      ),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(14),
              children: [
                _bolum('1', 'Kanal Seçin', _kanalKartlari()),
                _bolum('2', 'Hedef Kitle', _hedefKitle()),
                _bolum('3', 'Hizmet / Ürün / Paket', _hupSecim()),
                _bolum('4', 'Şablon & Mesaj', _sablonMesaj()),
                if (_gorevTuru != 4) _bolum('5', 'İndirim', _indirim()),
                _bolum('6', 'Planlama', _planlama()),
                const SizedBox(height: 12),
                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _mor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _kaydediyor ? null : _kaydet,
                    icon: _kaydediyor
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check),
                    label: Text(_kaydediyor ? 'Kaydediliyor...' : 'Kaydet & Gönder', style: const TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
    );
  }

  Widget _bolum(String no, String baslik, Widget icerik) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(radius: 13, backgroundColor: _mor, child: Text(no, style: const TextStyle(color: Colors.white, fontSize: 13))),
                const SizedBox(width: 8),
                Text(baslik, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            icerik,
          ],
        ),
      ),
    );
  }

  Widget _kanalKartlari() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _kanallar.entries.map((e) {
        final secili = _gorevTuru == e.key;
        return ChoiceChip(
          label: Text(e.value),
          selected: secili,
          selectedColor: _mor.withOpacity(0.15),
          labelStyle: TextStyle(color: secili ? _mor : Colors.black87, fontWeight: secili ? FontWeight.w600 : FontWeight.normal),
          onSelected: (_) => setState(() => _gorevTuru = e.key),
        );
      }).toList(),
    );
  }

  Widget _hedefKitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: _mor.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.groups, size: 16, color: _mor),
              const SizedBox(width: 6),
              _kitleSayiliyor
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text('Tahmini kitle: ${_kitleSayisi ?? '-'} kişi',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _mor)),
            ],
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _presetler.entries.map((e) {
            final secili = _preset == e.key;
            return ChoiceChip(
              label: Text(e.value),
              selected: secili,
              selectedColor: _mor.withOpacity(0.15),
              labelStyle: TextStyle(color: secili ? _mor : Colors.black87, fontWeight: secili ? FontWeight.w600 : FontWeight.normal),
              onSelected: (_) {
                setState(() {
                  _preset = e.key;
                  _hedefDegisti = true;
                });
                _kitleGuncelle();
              },
            );
          }).toList(),
        ),
        if (_preset == 'grup') ...[
          const SizedBox(height: 12),
          _hupDropdown('Grup seçin', _gruplar, _grupDeger, (v) {
            setState(() {
              _grupDeger = v;
              _hedefDegisti = true;
            });
            _kitleGuncelle();
          }),
        ],
        const SizedBox(height: 12),
        const Text('Cinsiyet', style: TextStyle(fontSize: 13, color: Colors.black54)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          children: [
            _cinsiyetChip('', 'Tümü'),
            _cinsiyetChip('kadinlar', 'Kadınlar'),
            _cinsiyetChip('erkekler', 'Erkekler'),
          ],
        ),
      ],
    );
  }

  Widget _cinsiyetChip(String val, String etiket) {
    final secili = _cinsiyet == val;
    return ChoiceChip(
      label: Text(etiket),
      selected: secili,
      selectedColor: _mor.withOpacity(0.15),
      labelStyle: TextStyle(color: secili ? _mor : Colors.black87),
      onSelected: (_) {
        setState(() {
          _cinsiyet = val;
          _hedefDegisti = true;
        });
        _kitleGuncelle();
      },
    );
  }

  Widget _hupSecim() {
    return Column(
      children: [
        _hupDropdown('Hizmet seçin...', _hizmetler, _hizmetDeger, (v) {
          setState(() {
            _hizmetDeger = v;
            _urunDeger = null;
            _paketDeger = null;
            _hedefDegisti = true;
          });
        }),
        const SizedBox(height: 10),
        _hupDropdown('Ürün seçin...', _urunler, _urunDeger, (v) {
          setState(() {
            _urunDeger = v;
            _hizmetDeger = null;
            _paketDeger = null;
            _hedefDegisti = true;
          });
        }),
        const SizedBox(height: 10),
        _hupDropdown('Paket seçin...', _paketler, _paketDeger, (v) {
          setState(() {
            _paketDeger = v;
            _hizmetDeger = null;
            _urunDeger = null;
            _hedefDegisti = true;
          });
        }),
      ],
    );
  }

  // Aranabilir secim alani: tiklaninca arama kutulu alt sayfa acar (uzun listeler icin).
  Widget _hupDropdown(String etiket, List<Map<String, dynamic>> liste, String? deger, ValueChanged<String?> onChanged) {
    final secili = deger == null
        ? <String, dynamic>{}
        : liste.firstWhere((e) => e['value'].toString() == deger, orElse: () => <String, dynamic>{});
    final seciliLabel = secili.isNotEmpty ? secili['label'].toString() : '';
    return InkWell(
      onTap: () async {
        final secim = await _araliSeciciAc(etiket, liste, deger);
        if (secim != null) onChanged(secim.isEmpty ? null : secim);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: etiket, border: const OutlineInputBorder()),
        child: Row(
          children: [
            Expanded(
              child: Text(
                seciliLabel.isEmpty ? 'Seçin...' : seciliLabel,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: seciliLabel.isEmpty ? Colors.black45 : Colors.black87),
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.black54),
          ],
        ),
      ),
    );
  }

  // Turkce duyarli normalize (arama icin: İ/ı/ş/ğ/ü/ö/ç -> ascii + kucuk harf).
  String _norm(String s) => s
      .replaceAll('İ', 'i').replaceAll('I', 'i').replaceAll('ı', 'i')
      .replaceAll('Ş', 's').replaceAll('ş', 's')
      .replaceAll('Ğ', 'g').replaceAll('ğ', 'g')
      .replaceAll('Ü', 'u').replaceAll('ü', 'u')
      .replaceAll('Ö', 'o').replaceAll('ö', 'o')
      .replaceAll('Ç', 'c').replaceAll('ç', 'c')
      .toLowerCase();

  // Aranabilir alt sayfa: value doner; '' = temizle; null = vazgec.
  Future<String?> _araliSeciciAc(String baslik, List<Map<String, dynamic>> liste, String? mevcut) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        String q = '';
        return StatefulBuilder(builder: (ctx, setModal) {
          final filtreli = q.isEmpty
              ? liste
              : liste.where((e) => _norm(e['label'].toString()).contains(_norm(q))).toList();
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: SizedBox(
              height: MediaQuery.of(ctx).size.height * 0.75,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 8, 4),
                    child: Row(
                      children: [
                        Expanded(child: Text(baslik, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                        TextButton(onPressed: () => Navigator.pop(ctx, ''), child: const Text('Temizle')),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      autofocus: true,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Ara...',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (v) => setModal(() => q = v),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: filtreli.isEmpty
                        ? const Center(child: Text('Sonuç yok', style: TextStyle(color: Colors.black45)))
                        : ListView.builder(
                            itemCount: filtreli.length,
                            itemBuilder: (_, i) {
                              final e = filtreli[i];
                              final val = e['value'].toString();
                              final secili = val == mevcut;
                              return ListTile(
                                title: Text(e['label'].toString()),
                                trailing: secili ? const Icon(Icons.check, color: _mor) : null,
                                onTap: () => Navigator.pop(ctx, val),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  Widget _sablonMesaj() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _hupDropdown('Şablon seçin (opsiyonel)', _sablonlar, _seciliSablonId.isEmpty ? null : _seciliSablonId, (v) {
          setState(() {
            _seciliSablonId = v ?? '';
            final sablon = _sablonlar.firstWhere((s) => s['value'].toString() == v, orElse: () => <String, dynamic>{});
            if (sablon.isNotEmpty) _mesajCtrl.text = (sablon['icerik'] ?? '').toString();
          });
        }),
        const SizedBox(height: 10),
        TextField(
          controller: _mesajCtrl,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Kampanya Mesajı',
            border: OutlineInputBorder(),
            helperText: '{müşteri} ve {gün} yer tutucuları gönderimde kişiye özel çözülür.',
          ),
          // Mesaj elle degistirilince serbest metin moduna gec (sablon override kalksin)
          onChanged: (_) {
            if (_seciliSablonId.isNotEmpty) setState(() => _seciliSablonId = '');
          },
        ),
      ],
    );
  }

  Widget _indirim() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('X Al Y Öde'),
            Switch(
              activeColor: _mor,
              value: _yuzdeIndirim,
              onChanged: (v) => setState(() => _yuzdeIndirim = v),
            ),
            const Text('Yüzde İndirim'),
          ],
        ),
        const SizedBox(height: 6),
        if (_yuzdeIndirim)
          TextField(
            controller: _yuzdeCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'İndirim (%)', border: OutlineInputBorder()),
          )
        else
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _xalCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'X Al', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _yodeCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Y Öde', border: OutlineInputBorder()),
                ),
              ),
            ],
          ),
        const SizedBox(height: 10),
        TextField(
          controller: _kodCtrl,
          decoration: const InputDecoration(
            labelText: 'İndirim Kodu (boş bırakılırsa otomatik üretilir)',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _planlama() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _tarihSecici('Başlangıç', _baslangic, (d) => setState(() => _baslangic = d))),
            const SizedBox(width: 10),
            Expanded(child: _tarihSecici('Bitiş', _bitis, (d) => setState(() => _bitis = d))),
          ],
        ),
        const SizedBox(height: 10),
        _saatSecici(),
      ],
    );
  }

  Widget _tarihSecici(String etiket, DateTime deger, ValueChanged<DateTime> onSec) {
    return InkWell(
      onTap: () async {
        final secilen = await showDatePicker(
          context: context,
          initialDate: deger,
          firstDate: DateTime(2020),
          lastDate: DateTime(2035),
        );
        if (secilen != null) onSec(secilen);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: etiket, border: const OutlineInputBorder()),
        child: Text(_tarihStr(deger)),
      ),
    );
  }

  Widget _saatSecici() {
    return InkWell(
      onTap: () async {
        final secilen = await showTimePicker(context: context, initialTime: _saat);
        if (secilen != null) setState(() => _saat = secilen);
      },
      child: InputDecorator(
        decoration: const InputDecoration(labelText: 'Saat', border: OutlineInputBorder()),
        child: Text(_saatStr(_saat)),
      ),
    );
  }
}

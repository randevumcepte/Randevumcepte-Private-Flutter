import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Models/cilttipi.dart';
import 'package:randevu_sistem/Models/musteri_danisanlar.dart';
import 'package:randevu_sistem/Models/saglikbilgileri.dart';

class MusteriPaneliSaglikBilgileri extends StatefulWidget {
  final MusteriDanisan md;
  const MusteriPaneliSaglikBilgileri({Key? key, required this.md})
      : super(key: key);

  @override
  _MusteriPaneliSaglikBilgileriState createState() =>
      _MusteriPaneliSaglikBilgileriState();
}

class _MusteriPaneliSaglikBilgileriState
    extends State<MusteriPaneliSaglikBilgileri> {
  String? seciliisletme;
  bool _saving = false;

  final List<SaglikBilgileri> evethayir = [
    SaglikBilgileri(id: "0", saglik: "Hayır"),
    SaglikBilgileri(id: "1", saglik: "Evet"),
  ];
  final List<CiltTipi> cilttipi = [
    CiltTipi(id: '0', citl: 'Karma'),
    CiltTipi(id: '1', citl: 'Yağlı'),
    CiltTipi(id: '2', citl: 'Hassas'),
    CiltTipi(id: '3', citl: 'Kuru'),
    CiltTipi(id: '4', citl: 'Nemli'),
    CiltTipi(id: '5', citl: 'Normal'),
  ];

  late TextEditingController eksaglik;
  late TextEditingController musteriid;

  SaglikBilgileri? selectedhemofili;
  SaglikBilgileri? selectedseker;
  SaglikBilgileri? selectedhamile;
  SaglikBilgileri? selectedameliyat;
  SaglikBilgileri? selectedalerji;
  SaglikBilgileri? selectedalkol;
  SaglikBilgileri? selectedregl;
  SaglikBilgileri? selecteddoku;
  SaglikBilgileri? selectedilac;
  SaglikBilgileri? selectedkemoterapi;
  SaglikBilgileri? selecteduygulama;
  CiltTipi? selectedcilttip;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  AutovalidateMode _autoValidate = AutovalidateMode.disabled;

  Color get _primary => Theme.of(context).colorScheme.primary;
  Color get _onSurface => Theme.of(context).colorScheme.onSurface;
  Color get _border => _onSurface.withValues(alpha: 0.10);
  Color get _tint => _primary.withValues(alpha: 0.10);

  SaglikBilgileri? _matchEvetHayir(String value) {
    final hit = evethayir.where((item) => item.id == value);
    return hit.isEmpty ? null : hit.first;
  }

  @override
  void initState() {
    super.initState();
    musteriid = TextEditingController(text: widget.md.id);
    final rawNot = widget.md.ek_saglik_sorunu;
    eksaglik = TextEditingController(
      text: (rawNot.isEmpty || rawNot.toLowerCase() == 'null') ? '' : rawNot,
    );
    selectedhemofili = _matchEvetHayir(widget.md.hemofili_hastaligi_var);
    selectedseker = _matchEvetHayir(widget.md.seker_hastaligi_var);
    selectedhamile = _matchEvetHayir(widget.md.hamile);
    selectedameliyat =
        _matchEvetHayir(widget.md.yakin_zamanda_ameliyat_gecirildi);
    selectedalerji = _matchEvetHayir(widget.md.alerji_var);
    selectedalkol = _matchEvetHayir(widget.md.alkol_alimi_yapildi);
    selectedregl = _matchEvetHayir(widget.md.regl_doneminde);
    selecteddoku = _matchEvetHayir(widget.md.deri_yumusak_doku_hastaligi_var);
    selectedilac = _matchEvetHayir(widget.md.surekli_kullanilan_ilac_Var);
    selectedkemoterapi = _matchEvetHayir(widget.md.kemoterapi_goruyor);
    selecteduygulama =
        _matchEvetHayir(widget.md.daha_once_uygulama_yaptirildi);
    final ct = cilttipi.where((item) => item.id == widget.md.cilt_tipi);
    selectedcilttip = ct.isEmpty ? null : ct.first;

    _loadSalon();
  }

  Future<void> _loadSalon() async {
    seciliisletme = await secilisalonid();
  }

  @override
  void dispose() {
    eksaglik.dispose();
    musteriid.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) {
      setState(() => _autoValidate = AutovalidateMode.onUserInteraction);
      return;
    }
    _formKey.currentState!.save();
    setState(() => _saving = true);
    await submitForm(
      musteriid.text,
      selectedhemofili?.id ?? "",
      selectedseker?.id ?? "",
      selectedhamile?.id ?? "",
      selectedameliyat?.id ?? "",
      selectedalerji?.id ?? "",
      selectedalkol?.id ?? "",
      selectedregl?.id ?? "",
      selecteddoku?.id ?? "",
      selectedilac?.id ?? "",
      selectedkemoterapi?.id ?? "",
      selecteduygulama?.id ?? "",
      eksaglik.text,
      selectedcilttip?.id ?? "",
      context,
    );
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text(
            'Sağlık Bilgilerim',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: _onSurface,
              letterSpacing: -0.5,
            ),
          ),
          toolbarHeight: 64,
          elevation: 0,
          backgroundColor: Colors.transparent,
          centerTitle: false,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_rounded,
                color: _onSurface, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                Color.alphaBlend(
                    scheme.primary.withValues(alpha: 0.36), Colors.white),
                Color.alphaBlend(
                    scheme.tertiary.withValues(alpha: 0.08), Colors.white),
              ],
            ),
          ),
          child: SafeArea(
            child: Form(
              key: _formKey,
              autovalidateMode: _autoValidate,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoBanner(),
                    const SizedBox(height: 16),

                    _buildQuestionGroup(
                      icon: Icons.favorite_rounded,
                      title: 'Genel Sağlık Durumu',
                      questions: [
                        _yesNoRow(
                          'Hemofili hastalığı var mı?',
                          selectedhemofili,
                          (v) => setState(() => selectedhemofili = v),
                        ),
                        _yesNoRow(
                          'Şeker hastalığı var mı?',
                          selectedseker,
                          (v) => setState(() => selectedseker = v),
                        ),
                        _yesNoRow(
                          'Deri veya yumuşak doku hastalığı var mı?',
                          selecteddoku,
                          (v) => setState(() => selecteddoku = v),
                        ),
                        _yesNoRow(
                          'Sürekli kullandığı ilaç var mı?',
                          selectedilac,
                          (v) => setState(() => selectedilac = v),
                        ),
                        _yesNoRow(
                          'Kemoterapi görüyor mu?',
                          selectedkemoterapi,
                          (v) => setState(() => selectedkemoterapi = v),
                        ),
                      ],
                    ),

                    _buildQuestionGroup(
                      icon: Icons.female_rounded,
                      title: 'Kadın Sağlığı',
                      questions: [
                        _yesNoRow(
                          'Hamile mi?',
                          selectedhamile,
                          (v) => setState(() => selectedhamile = v),
                        ),
                        _yesNoRow(
                          'Regl döneminde mi?',
                          selectedregl,
                          (v) => setState(() => selectedregl = v),
                        ),
                      ],
                    ),

                    _buildQuestionGroup(
                      icon: Icons.access_time_rounded,
                      title: 'Son 48 Saat',
                      questions: [
                        _yesNoRow(
                          'Yakın zamanda ameliyat geçirildi mi?',
                          selectedameliyat,
                          (v) => setState(() => selectedameliyat = v),
                        ),
                        _yesNoRow(
                          '48 saat içinde alkol alımı var mı?',
                          selectedalkol,
                          (v) => setState(() => selectedalkol = v),
                        ),
                      ],
                    ),

                    _buildQuestionGroup(
                      icon: Icons.science_outlined,
                      title: 'Alerji & Estetik Geçmişi',
                      questions: [
                        _yesNoRow(
                          'Herhangi bir alerjisi var mı?',
                          selectedalerji,
                          (v) => setState(() => selectedalerji = v),
                        ),
                        _yesNoRow(
                          'Daha önce uygulama yaptırıldı mı?',
                          selecteduygulama,
                          (v) => setState(() => selecteduygulama = v),
                        ),
                      ],
                    ),

                    _buildSkinTypeCard(),

                    _buildNoteCard(),

                    const SizedBox(height: 8),
                    _buildSaveButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _tint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child:
                Icon(Icons.lock_outline_rounded, color: _primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Sağlık bilgileriniz salonunuzla güvenli bir şekilde paylaşılır ve uygulamanızın güvenliği için kullanılır.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.35,
                color: _onSurface.withValues(alpha: 0.75),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionGroup({
    required IconData icon,
    required String title,
    required List<Widget> questions,
  }) {
    final List<Widget> children = [];
    for (var i = 0; i < questions.length; i++) {
      children.add(questions[i]);
      if (i < questions.length - 1) {
        children.add(Divider(
          height: 1,
          color: _border.withValues(alpha: 0.6),
          indent: 16,
          endIndent: 16,
        ));
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: _tint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: _primary, size: 17),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _onSurface,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: _border),
          ...children,
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _yesNoRow(
    String label,
    SaglikBilgileri? value,
    ValueChanged<SaglikBilgileri?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                color: _onSurface.withValues(alpha: 0.85),
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(width: 10),
          _yesNoToggle(value, onChanged),
        ],
      ),
    );
  }

  Widget _yesNoToggle(
    SaglikBilgileri? value,
    ValueChanged<SaglikBilgileri?> onChanged,
  ) {
    Widget pill(String label, String id) {
      final selected = value?.id == id;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(
          evethayir.firstWhere((e) => e.id == id),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? _primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: _primary.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected
                  ? Colors.white
                  : _onSurface.withValues(alpha: 0.55),
              letterSpacing: -0.1,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: _onSurface.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          pill('Evet', '1'),
          const SizedBox(width: 2),
          pill('Hayır', '0'),
        ],
      ),
    );
  }

  Widget _buildSkinTypeCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _tint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.spa_rounded, color: _primary, size: 17),
              ),
              const SizedBox(width: 12),
              Text(
                'Cilt Tipi',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _onSurface,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: cilttipi.map((c) => _skinChip(c)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _skinChip(CiltTipi c) {
    final selected = selectedcilttip?.id == c.id;
    return GestureDetector(
      onTap: () => setState(() => selectedcilttip = c),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? _primary : _tint,
          borderRadius: BorderRadius.circular(20),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          c.citl,
          style: TextStyle(
            color: selected ? Colors.white : _primary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
            letterSpacing: -0.1,
          ),
        ),
      ),
    );
  }

  Widget _buildNoteCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _tint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.edit_note_rounded,
                    color: _primary, size: 19),
              ),
              const SizedBox(width: 12),
              Text(
                'Ek Sağlık Notları',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _onSurface,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: eksaglik,
            maxLines: 4,
            minLines: 3,
            style: TextStyle(
              fontSize: 14,
              color: _onSurface,
              height: 1.4,
            ),
            decoration: InputDecoration(
              hintText: 'Belirtmek istediğiniz başka bir sağlık durumu...',
              hintStyle: TextStyle(
                color: _onSurface.withValues(alpha: 0.4),
                fontSize: 13.5,
              ),
              filled: true,
              fillColor: _onSurface.withValues(alpha: 0.03),
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _primary, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.redAccent),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.redAccent),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Bu alan zorunludur';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _saving ? null : _onSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _primary.withValues(alpha: 0.5),
          elevation: 0,
          shadowColor: _primary.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _saving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.4,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.check_rounded, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Bilgileri Kaydet',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

Future<void> submitForm(
    String musteri_id,
    String hemofili,
    String seker,
    String hamile,
    String ameliyet,
    String alerji,
    String alkol,
    String regl,
    String doku,
    String ilac,
    String kemo,
    String uygulama,
    String eksaglik,
    String cilt,
    context) async {
  Map<String, dynamic> formData = {
    'hemofili_hastaligi_var': hemofili,
    'seker_hastaligi_var': seker,
    'hamile': hamile,
    'alerji_var': alerji,
    'yakin_zamanda_ameliyat_gecirildi': ameliyet,
    'alkol_alimi_yapildi': alkol,
    'regl_doneminde': regl,
    'deri_yumusak_doku_hastaligi_var': doku,
    'surekli_kullanilan_ilac_Var': ilac,
    'kemoterapi_goruyor': kemo,
    'daha_once_uygulama_yaptirildi': uygulama,
    'ek_saglik_sorunu': eksaglik,
    'cilt_tipi': cilt,
    'musteri_id': musteri_id
  };

  final response = await http.post(
    Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/saglikbilgilerigir'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),
  );
  log('Response status: ${response.statusCode}');
  log('Response body: ${response.body}');

  if (response.statusCode == 200) {
    if (response.body.isNotEmpty) {
      log('Response body: ${response.body}');
    } else {
      log('Response body is empty');
    }
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Güncelleme Başarılı')),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Bilgiler değiştirilirken bir hata oluştu! Hata kodu : ${response.statusCode}'),
      ),
    );
    debugPrint('Error: ${response.body}');
  }
}

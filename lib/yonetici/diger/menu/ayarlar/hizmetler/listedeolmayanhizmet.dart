import 'dart:convert';
import 'dart:core';
import 'dart:developer';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:http/http.dart' as http;
import '../../../../../Backend/backend.dart';
import '../../../../../Models/hizmetkategorisi.dart';
import '../../../../../Models/cihazlar.dart';
import '../../../../../Models/odalar.dart';
import '../../../../../Models/personel.dart';
import '../../../../../Models/personelcihaz.dart';
import 'hizmetler.dart';

class ListedeOlmayanHizmet extends StatefulWidget {
  final dynamic isletmebilgi;
  const ListedeOlmayanHizmet({Key? key, required this.isletmebilgi})
      : super(key: key);

  @override
  _ListedeOlmayanHizmetState createState() => _ListedeOlmayanHizmetState();
}

class _ListedeOlmayanHizmetState extends State<ListedeOlmayanHizmet> {
  late List<Cihaz> cihazliste;
  late List<HizmetKategorisi> hizmetkategorisi;
  List<PersonelCihaz> personelcihazliste = [];
  HizmetKategorisi? selectedhizmetkategorisi;
  TextEditingController hizmetkategorisicontroller = TextEditingController();
  List<PersonelCihaz> seciliYardimci = [];
  String _selectedGender = '';
  bool isloading = true;
  TextEditingController hizmet_adi = TextEditingController();
  TextEditingController hizmet_sure = TextEditingController();
  TextEditingController hizmet_fiyat = TextEditingController();

  // Yeni kategori ekleme dialog'u için controller
  TextEditingController yeniKategoriController = TextEditingController();

  // ScrollController ve form key
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();
  AutovalidateMode _autoValidate = AutovalidateMode.disabled;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    hizmet_adi.dispose();
    hizmet_sure.dispose();
    hizmet_fiyat.dispose();
    hizmetkategorisicontroller.dispose();
    yeniKategoriController.dispose();
    super.dispose();
  }

  Future<void> initialize() async {
    var seciliisletme = await secilisalonid();
    List<HizmetKategorisi> isletmehizmetkategorileriliste =
    await hizmetkategorileri();
    List<Personel> isletmepersonellerliste =
    await personellistegetir(seciliisletme!);
    List<Cihaz> isletmecihazliste = await isletmecihazlari(seciliisletme!);
    setState(() {
      hizmetkategorisi = isletmehizmetkategorileriliste;
      cihazliste = isletmecihazliste;
      isletmepersonellerliste.forEach((element) {
        personelcihazliste.add(element);
      });
      isletmecihazliste.forEach((element) {
        personelcihazliste.add(element);
      });
      isloading = false;
    });
  }

  void _showDetailsDialog(BuildContext context) {
    final _kategoriFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Yeni Hizmet Kategorisi',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(  // <-- EKLENDI (scroll ekledi)
            child: Form(
              key: _kategoriFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: yeniKategoriController,
                    autofocus: true,  // <-- EKLENDI (direkt odaklansın)
                    textInputAction: TextInputAction.done,  // <-- EKLENDI (klavyede "bitti" butonu)
                    decoration: InputDecoration(
                      labelText: 'Kategori Adı',
                      hintText: 'Örn: Saç Kesim, Cilt Bakımı...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color(0xFF6A1B9A)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(  // <-- EKLENDI
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Kategori adı giriniz';
                      }
                      if (value.length < 2) {
                        return 'En az 2 karakter giriniz';
                      }
                      return null;
                    },
                    onFieldSubmitted: (value) {  // <-- EKLENDI (enter'a basınca kaydet)
                      if (_kategoriFormKey.currentState!.validate()) {
                        _saveNewCategory(context, _kategoriFormKey);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                yeniKategoriController.clear();
                Navigator.of(context).pop();
              },
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_kategoriFormKey.currentState!.validate()) {
                  _saveNewCategory(context, _kategoriFormKey);
                }
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Kaydet'),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24), // <-- EKLENDI
        );
      },
    );
  }

// Yeni kategori kaydetme işlemini ayrı metoda aldım
  void _saveNewCategory(BuildContext context, GlobalKey<FormState> formKey) {
    if (formKey.currentState!.validate()) {
      setState(() {
        HizmetKategorisi yeniKategori = HizmetKategorisi(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          hizmet_kategori_adi: yeniKategoriController.text,
        );
        hizmetkategorisi.add(yeniKategori);
        selectedhizmetkategorisi = yeniKategori;
      });
      yeniKategoriController.clear();
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Yeni kategori eklendi'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.shortestSide >= 600;
    final isLandscape = screenSize.width > screenSize.height;

    final horizontalPadding = isTablet ? 32.0 : 16.0;
    final verticalPadding = isTablet ? 24.0 : 16.0;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text(
              'Yeni Hizmet',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.white,
            elevation: 1,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              if (widget.isletmebilgi["demo_hesabi"].toString() == "1")
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: SizedBox(
                    width: 100,
                    child: YukseltButonu(isletme_bilgi: widget.isletmebilgi),
                  ),
                ),
            ],
          ),
          body: isloading
              ? const Center(child: CircularProgressIndicator())
              : LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                controller: _scrollController,
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - verticalPadding * 2,
                  ),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: _autoValidate,
                    child: _buildFormUI(isTablet, isLandscape),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFormUI(bool isTablet, bool isLandscape) {
    if (isTablet && !isLandscape) {
      return _buildTwoColumnLayout();
    } else {
      return _buildSingleColumnLayout();
    }
  }

  Widget _buildSingleColumnLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          label: 'Hizmet Adı',
          controller: hizmet_adi,
          hint: 'Örn: Saç Kesim, Manikür...',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          label: 'Hizmet Süresi (dk)',
          controller: hizmet_sure,
          hint: 'Örn: 30',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          label: 'Hizmet Fiyatı (₺)',
          controller: hizmet_fiyat,
          hint: 'Örn: 150',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 24),
        _buildPersonelCihazSelector(),
        const SizedBox(height: 24),
        _buildKategoriSelector(),
        const SizedBox(height: 16),
        _buildCinsiyetSelector(),
        const SizedBox(height: 24),
        _buildKaydetButton(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTwoColumnLayout() {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildTextField(
                label: 'Hizmet Adı',
                controller: hizmet_adi,
                hint: 'Örn: Saç Kesim, Manikür...',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                label: 'Hizmet Süresi (dk)',
                controller: hizmet_sure,
                hint: 'Örn: 30',
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildTextField(
                label: 'Hizmet Fiyatı (₺)',
                controller: hizmet_fiyat,
                hint: 'Örn: 150',
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildPersonelCihazSelector(),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildKategoriSelector(),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildCinsiyetSelector(),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildKaydetButton(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 5, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: TextInputAction.next,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFF6A1B9A), width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            errorBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.red),
              borderRadius: BorderRadius.circular(12),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.red, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Bu alan zorunludur';
            }
            if (keyboardType == TextInputType.number) {
              if (double.tryParse(value) == null) {
                return 'Geçerli bir sayı giriniz';
              }
              if (double.parse(value) <= 0) {
                return '0\'dan büyük bir değer giriniz';
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPersonelCihazSelector() {
    final bool hasError = seciliYardimci.isEmpty && _autoValidate == AutovalidateMode.always;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 5, bottom: 8),
          child: Text(
            'Hizmeti Sunan Personel & Cihazlar ${hasError ? '*' : ''}',
            style: TextStyle(
              fontSize: 14,
              color: hasError ? Colors.red : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: hasError ? Colors.red : Colors.grey[300]!,
              width: hasError ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton2<PersonelCihaz>(
              isExpanded: true,
              hint: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  seciliYardimci.isEmpty
                      ? 'Personel ve Cihaz Seçiniz'
                      : seciliYardimci.map((e) {
                    if (e is Personel) {
                      return e.personel_adi;
                    } else if (e is Cihaz) {
                      return e.cihaz_adi;
                    }
                    return 'Unknown';
                  }).join(', '),
                  style: TextStyle(
                    fontSize: 14,
                    color: seciliYardimci.isEmpty ? Colors.grey[600] : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              items: personelcihazliste.map((item) {
                bool isSelected = seciliYardimci.contains(item);
                return DropdownMenuItem<PersonelCihaz>(
                  value: item,
                  child: StatefulBuilder(
                    builder: (context, menuSetState) {
                      return InkWell(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              seciliYardimci.remove(item);
                            } else {
                              seciliYardimci.add(item);
                            }
                            isSelected = !isSelected;
                          });
                          menuSetState(() {});
                        },
                        child: Container(
                          height: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            children: [
                              Icon(
                                isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                                color: isSelected ? const Color(0xFF6A1B9A) : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  (item is Personel)
                                      ? item.personel_adi
                                      : (item is Cihaz ? item.cihaz_adi : 'Unknown'),
                                  style: const TextStyle(fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              }).toList(),
              onChanged: (_) {},
              buttonStyleData: const ButtonStyleData(
                padding: EdgeInsets.symmetric(horizontal: 16),
                height: 50,
                width: double.infinity,
              ),
              dropdownStyleData: const DropdownStyleData(maxHeight: 400),
              menuItemStyleData: const MenuItemStyleData(height: 40),
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 5),
            child: Text(
              'En az bir personel veya cihaz seçmelisiniz',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red[700],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildKategoriSelector() {
    final bool hasError = selectedhizmetkategorisi == null && _autoValidate == AutovalidateMode.always;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 5, bottom: 8),
          child: Text(
            'Hizmet Kategorisi ${hasError ? '*' : ''}',
            style: TextStyle(
              fontSize: 14,
              color: hasError ? Colors.red : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dropdown - genişlik 8 birim (flex)
            Expanded(
              flex: 8,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: hasError ? Colors.red : Colors.grey[300]!,
                    width: hasError ? 1.5 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton2<HizmetKategorisi>(
                    isExpanded: true,
                    hint: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'Kategori Seçiniz',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    items: hizmetkategorisi.map((item) => DropdownMenuItem<HizmetKategorisi>(
                      value: item,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          item.hizmet_kategori_adi,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    )).toList(),
                    value: selectedhizmetkategorisi,
                    onChanged: (value) {
                      setState(() {
                        selectedhizmetkategorisi = value;
                      });
                    },
                    buttonStyleData: ButtonStyleData(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      height: 50,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    dropdownStyleData: const DropdownStyleData(
                      maxHeight: 300,
                      width: double.infinity,
                    ),
                    menuItemStyleData: const MenuItemStyleData(height: 45),
                    dropdownSearchData: DropdownSearchData(
                      searchController: hizmetkategorisicontroller,
                      searchInnerWidgetHeight: 50,
                      searchInnerWidget: Container(
                        padding: const EdgeInsets.all(8),
                        child: TextFormField(
                          controller: hizmetkategorisicontroller,
                          decoration: InputDecoration(
                            hintText: 'Kategori Ara...',
                            hintStyle: const TextStyle(fontSize: 12),
                            prefixIcon: const Icon(Icons.search, size: 18),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                      searchMatchFn: (item, searchValue) {
                        return item.value
                            .toString()
                            .toLowerCase()
                            .contains(searchValue.toLowerCase());
                      },
                    ),
                    onMenuStateChange: (isOpen) {
                      if (!isOpen) {
                        hizmetkategorisicontroller.clear();
                      }
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Artı butonu - genişlik 1 birim (flex)
            Expanded(
              flex: 1,
              child: InkWell(
                onTap: () => _showDetailsDialog(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                  ),
                  child: Icon(
                    Icons.add,
                    color: Colors.green[600],
                    size: 28,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 5),
            child: Text(
              'Lütfen bir hizmet kategorisi seçiniz',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red[700],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCinsiyetSelector() {
    final bool hasError = _selectedGender.isEmpty && _autoValidate == AutovalidateMode.always;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 5, bottom: 8),
          child: Text(
            'Müşteri Cinsiyeti ${hasError ? '*' : ''}',
            style: TextStyle(
              fontSize: 14,
              color: hasError ? Colors.red : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: hasError ? Colors.red : Colors.grey[300]!,
              width: hasError ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildRadioOption('Kadın', '0'),
              _buildRadioOption('Erkek', '1'),
              _buildRadioOption('Unisex', '2'),
            ],
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 5),
            child: Text(
              'Lütfen müşteri cinsiyetini seçiniz',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red[700],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRadioOption(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio<String>(
          value: value,
          groupValue: _selectedGender,
          activeColor: const Color(0xFF6A1B9A),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          onChanged: (val) {
            setState(() {
              _selectedGender = val!;
            });
          },
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildKaydetButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: const Text(
          'Hizmeti Kaydet',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Future<void> submitForm() async {
    // Tüm alanları kontrol et
    List<String> eksikAlanlar = [];

    if (hizmet_adi.text.trim().isEmpty) {
      eksikAlanlar.add('Hizmet Adı');
    }
    if (hizmet_sure.text.trim().isEmpty) {
      eksikAlanlar.add('Hizmet Süresi');
    }
    if (hizmet_fiyat.text.trim().isEmpty) {
      eksikAlanlar.add('Hizmet Fiyatı');
    }
    if (selectedhizmetkategorisi == null) {
      eksikAlanlar.add('Hizmet Kategorisi');
    }
    if (_selectedGender.isEmpty) {
      eksikAlanlar.add('Müşteri Cinsiyeti');
    }
    if (seciliYardimci.isEmpty) {
      eksikAlanlar.add('Personel/Cihaz');
    }

    // Eksik alan varsa genel uyarı göster
    if (eksikAlanlar.isNotEmpty) {
      setState(() {
        _autoValidate = AutovalidateMode.always;
      });

      _scrollToFirstError();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Lütfen tüm alanları doldurunuz:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(eksikAlanlar.join(', ')),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    // Form validasyonu
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _autoValidate = AutovalidateMode.always;
      });
      return;
    }

    List<String> personelidler = [];
    List<String> cihazidler = [];

    seciliYardimci.forEach((element) {
      if (element is Personel) {
        personelidler.add(element.id);
        log('yeni hizmet için eklenen personel id ' + element.id.toString());
      } else if (element is Cihaz) {
        cihazidler.add(element.id);
      }
    });

    final Map<String, dynamic> formData = {
      'hizmet_kategorisi': selectedhizmetkategorisi?.id ?? "",
      'hizmet_adi': hizmet_adi.text.trim(),
      'hizmet_sure': hizmet_sure.text.trim(),
      'hizmet_fiyati': hizmet_fiyat.text.trim(),
      'cinsiyet': _selectedGender,
      'personel_id': personelidler,
      'cihaz_id': cihazidler,
      'sube': widget.isletmebilgi["id"],
    };

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await http.post(
        Uri.parse('https://app.randevumcepte.com.tr/api/v1/sistemeyenihizmetekle'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(formData),
      );

      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (response.statusCode == 200) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Hizmet başarıyla eklendi'),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.of(context).pop();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => Hizmetler(isletmebilgi: widget.isletmebilgi),
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Hizmet eklenirken hata oluştu! Hata: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
          debugPrint('Error: ${response.body}');
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bağlantı hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _scrollToFirstError() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }
}
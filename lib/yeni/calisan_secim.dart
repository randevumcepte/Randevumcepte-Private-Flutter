import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Frontend/popupdialogs.dart';
import 'package:randevu_sistem/Frontend/sfdatatable.dart';
import 'package:randevu_sistem/Models/cihazlar.dart';
import 'package:randevu_sistem/Models/hizmetler.dart';
import 'package:randevu_sistem/Models/personel.dart';
import 'package:randevu_sistem/Models/personelcihaz.dart';
import 'package:randevu_sistem/theme/app_tokens.dart';

class CalisanSecimi extends StatefulWidget {
  final dynamic isletmebilgi;
  final List<Hizmet> secilihizmetler;
  final bool yeniEkleme;
  final HizmetlerDataSource hizmetDataGridSource;
  const CalisanSecimi({Key? key, required this.yeniEkleme, required this.isletmebilgi, required this.secilihizmetler,required this.hizmetDataGridSource}) : super(key: key);

  @override
  _CalisanSecimiState createState() => _CalisanSecimiState();
}

class _CalisanSecimiState extends State<CalisanSecimi> {
  bool isloading = true;
  String butonyazi = "";
  List<List<PersonelCihaz>> secilipersoneller = [];
  List<List<PersonelCihaz>> personelliste = [];
  List<List<PersonelCihaz>> filteredPersonelliste = [];
  List<TextEditingController> hizmetsuresi = [];
  List<TextEditingController> hizmetAdi = [];
  List<TextEditingController> hizmetfiyat = [];
  List<TextEditingController> filterController = [];

  @override
  void initState() {
    super.initState();
    initialize();
  }

  // Method to filter the list based on search
  void filterPersonelList(int index) {
    String query = filterController[index].text.toLowerCase();
    setState(() {
      filteredPersonelliste[index] = personelliste[index]
          .where((personelCihaz) {
        // Check if the object is of type Personel and filter by personel_adi
        if (personelCihaz is Personel) {
          return personelCihaz.personel_adi.toLowerCase().contains(query.toLowerCase());
        }
        // Check if the object is of type Cihaz and filter by cihaz_adi
        if (personelCihaz is Cihaz) {
          return personelCihaz.cihaz_adi.toLowerCase().contains(query.toLowerCase());
        }
        return false;
      })
          .toList();

    });


  }

  Future<void> initialize() async {

    var seciliisletme = await secilisalonid();
    List<Personel> isletmepersonellerliste = await personellistegetir(seciliisletme!);

    List<Cihaz>isletmecihazliste = await isletmecihazlari(seciliisletme!);
    setState(() {

      widget.secilihizmetler.forEach((element) {
        log('düzenlenebilir kendi hizmetim '+element.toJson().toString());
        if(!widget.yeniEkleme)
          butonyazi = " Güncelle";
        else
          butonyazi = " Ekle";

        var combinedList = <PersonelCihaz>[];
        var secilicombinedlist = <PersonelCihaz>[];

        combinedList.addAll(isletmepersonellerliste);
        combinedList.addAll(isletmecihazliste);
        personelliste.add(combinedList);
        filteredPersonelliste.add(combinedList);
        filterController.add(TextEditingController());
        hizmetsuresi.add(TextEditingController(text: (element.sure_dk!= "null" ? element.sure_dk : '')));
        hizmetfiyat.add(TextEditingController(text: (element.fiyat!= "null" ? element.fiyat : '')));
        hizmetAdi.add(TextEditingController(text: (element.hizmet_adi!= "null" ? element.hizmet_adi : '')));
        if(element.personel != "null"  ){
          List<String>personelsplit = element.personel.split(',');
          personelsplit.forEach((element) {
            secilicombinedlist.addAll(isletmepersonellerliste.where((element2) =>element2.personel_adi == element));
            secilipersoneller.add(secilicombinedlist);

          });
        }
        else if(element.cihaz != "null" ) {
          List<String>cihazsplit = element.cihaz.split(',');
          cihazsplit.forEach((element) {
            secilicombinedlist.addAll(
                isletmecihazliste.where((element2) => element2.cihaz_adi ==
                    element));
            secilipersoneller.add(secilicombinedlist);
          });
        }
        else
          secilipersoneller.add([]);



      });



      isloading = false;
    });
  }

  // ───────────────────────── Modern UI yardimcilari ─────────────────────────

  Widget _labelLine(IconData icon, String label) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 15, color: cs.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
            letterSpacing: -0.1,
          ),
        ),
      ],
    );
  }

  InputDecoration _modernInput({String? hint, bool enabled = true}) {
    final cs = Theme.of(context).colorScheme;
    final ext = context.appTheme;
    OutlineInputBorder border(Color c, double w) => OutlineInputBorder(
          borderSide: BorderSide(color: c, width: w),
          borderRadius: BorderRadius.circular(AppRadius.md),
        );
    return InputDecoration(
      filled: true,
      fillColor: ext.surfaceMuted,
      hintText: hint,
      hintStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 13.5, fontWeight: FontWeight.w500),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      enabledBorder: border(cs.primary.withValues(alpha: 0.18), 1),
      disabledBorder: border(cs.primary.withValues(alpha: 0.10), 1),
      border: border(cs.primary.withValues(alpha: 0.18), 1),
      focusedBorder: border(cs.primary, 1.5),
    );
  }

  TextStyle get _inputTextStyle => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurface,
        letterSpacing: -0.1,
      );

  BoxDecoration _kartDekorasyon() {
    final cs = Theme.of(context).colorScheme;
    return BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: cs.primary.withValues(alpha: 0.10), width: 1),
      boxShadow: [
        BoxShadow(
          color: cs.primary.withValues(alpha: 0.05),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _hizmetKarti(int index) {
    final cs = Theme.of(context).colorScheme;
    final ext = context.appTheme;
    final data = widget.secilihizmetler[index];
    final ozelMi = data.ozel_hizmet.toString() == "1";

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      padding: const EdgeInsets.all(16),
      decoration: _kartDekorasyon(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baslik
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(Icons.design_services_outlined, size: 20, color: cs.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  data.hizmet_adi != "null" ? data.hizmet_adi : 'Hizmet',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Hizmet Adi
          _labelLine(Icons.label_outline_rounded, 'Hizmet Adı'),
          const SizedBox(height: 6),
          TextFormField(
            enabled: ozelMi,
            controller: hizmetAdi[index],
            style: _inputTextStyle,
            decoration: _modernInput(hint: 'Hizmet adı', enabled: ozelMi),
          ),
          const SizedBox(height: 14),

          // Personel & Cihaz
          _labelLine(Icons.groups_outlined, 'Personel(-ler) & Cihaz(-lar)'),
          const SizedBox(height: 6),
          _personelCihazDropdown(index),
          const SizedBox(height: 14),

          // Sure | Fiyat
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _labelLine(Icons.timer_outlined, 'Süre (dk)'),
                    const SizedBox(height: 6),
                    TextFormField(
                      keyboardType: TextInputType.number,
                      controller: hizmetsuresi[index],
                      style: _inputTextStyle,
                      decoration: _modernInput(hint: 'örn: 30'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _labelLine(Icons.payments_outlined, 'Fiyat (₺)'),
                    const SizedBox(height: 6),
                    TextFormField(
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      controller: hizmetfiyat[index],
                      style: _inputTextStyle,
                      decoration: _modernInput(hint: 'örn: 250'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Secili personel/cihaz ozeti
          if (secilipersoneller[index].isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: secilipersoneller[index].map((e) {
                final ad = e is Personel
                    ? e.personel_adi
                    : (e is Cihaz ? e.cihaz_adi : 'Bilinmiyor');
                final cihazMi = e is Cihaz;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: ext.surfaceMuted,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: cs.primary.withValues(alpha: 0.18)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(cihazMi ? Icons.devices_other : Icons.person,
                          size: 12, color: cs.primary),
                      const SizedBox(width: 4),
                      Text(ad,
                          style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _personelCihazDropdown(int index) {
    final cs = Theme.of(context).colorScheme;
    final ext = context.appTheme;
    return Container(
      alignment: Alignment.center,
      height: 48,
      width: double.infinity,
      decoration: BoxDecoration(
        color: ext.surfaceMuted,
        border: Border.all(color: cs.primary.withValues(alpha: 0.18)),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton2<PersonelCihaz>(
          isExpanded: true,
          hint: Text(
            'Personel veya cihazları seçin...',
            style: TextStyle(fontSize: 13.5, color: cs.onSurfaceVariant, fontWeight: FontWeight.w500),
          ),
          items: filteredPersonelliste[index].map((item) {
            return DropdownMenuItem(
              value: item,
              enabled: false,
              child: StatefulBuilder(
                builder: (context, menuSetState) {
                  bool isSelected = secilipersoneller[index].any((selectedItem) {
                    return (selectedItem is Personel && item is Personel && selectedItem.personel_adi == item.personel_adi) ||
                        (selectedItem is Cihaz && item is Cihaz && selectedItem.cihaz_adi == item.cihaz_adi);
                  });
                  return InkWell(
                    onTap: () {
                      if (isSelected) {
                        setState(() {
                          secilipersoneller[index].removeWhere((selectedItem) {
                            return (selectedItem is Personel && item is Personel && selectedItem.personel_adi == item.personel_adi) ||
                                (selectedItem is Cihaz && item is Cihaz && selectedItem.cihaz_adi == item.cihaz_adi);
                          });
                        });
                      } else {
                        setState(() {
                          secilipersoneller[index].add(item);
                        });
                      }
                      menuSetState(() {});
                    },
                    child: Container(
                      height: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                            color: isSelected ? cs.primary : cs.onSurfaceVariant,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              (item is Personel)
                                  ? item.personel_adi
                                  : (item is Cihaz ? item.cihaz_adi : 'Bilinmiyor'),
                              style: const TextStyle(fontSize: 14),
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
          value: secilipersoneller[index].isEmpty ? null : secilipersoneller[index].last,
          onChanged: (value) {},
          selectedItemBuilder: (context) {
            return List.generate(filteredPersonelliste[index].length, (i) {
              return Container(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  secilipersoneller[index].isNotEmpty
                      ? secilipersoneller[index].map((e) {
                          return e is Personel ? e.personel_adi : (e is Cihaz ? e.cihaz_adi : "Bilinmiyor");
                        }).join(', ')
                      : 'Personel veya cihazları seçin...',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                    overflow: TextOverflow.ellipsis,
                  ),
                  maxLines: 1,
                ),
              );
            });
          },
          buttonStyleData: const ButtonStyleData(
            padding: EdgeInsets.only(left: 14, right: 8),
            height: 48,
            width: double.infinity,
          ),
          iconStyleData: IconStyleData(
            icon: Icon(Icons.keyboard_arrow_down_rounded, color: cs.primary),
          ),
          menuItemStyleData: const MenuItemStyleData(height: 44, padding: EdgeInsets.zero),
          dropdownStyleData: DropdownStyleData(
            maxHeight: 320,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
          dropdownSearchData: DropdownSearchData(
            searchController: filterController[index],
            searchInnerWidgetHeight: 50,
            searchInnerWidget: Container(
              height: 50,
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: TextFormField(
                expands: true,
                maxLines: null,
                controller: filterController[index],
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  hintText: 'Personel & cihaz ara...',
                  hintStyle: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  filled: true,
                  fillColor: ext.surfaceMuted,
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: cs.primary.withValues(alpha: 0.18)),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: cs.primary, width: 1.4),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
              ),
            ),
            searchMatchFn: (item, searchValue) {
              if (item.value is Personel) {
                return (item.value as Personel).personel_adi.toString().toLowerCase().contains(searchValue.toLowerCase());
              } else if (item.value is Cihaz) {
                return (item.value as Cihaz).cihaz_adi.toString().toLowerCase().contains(searchValue.toLowerCase());
              }
              return false;
            },
          ),
        ),
      ),
    );
  }

  void _kaydet() {
    List<String> hizmetsureleri = [];
    List<String> hizmetfiyatlari = [];
    List<String> hizmetAdlari = [];
    bool formvalid = true;
    if (secilipersoneller.length == 0) formvalid = false;
    hizmetsuresi.forEach((element) {
      if (element.text == "")
        formvalid = false;
      else
        hizmetsureleri.add(element.text);
    });
    hizmetAdi.forEach((element) {
      if (element.text == "")
        formvalid = false;
      else
        hizmetAdlari.add(element.text);
    });
    secilipersoneller.forEach((element) {
      if (element.length == 0) formvalid = false;
    });
    hizmetfiyat.forEach((element) {
      hizmetfiyatlari.add(element.text);
    });
    if (!formvalid)
      formWarningDialogs(context, 'UYARI',
          "Hizmet eklemeden önce tüm bilgilerin eksiksiz girilmesi gerekmektedir. Lütfen formu tekrar kontrol ediniz.");
    else
      widget.hizmetDataGridSource.hizmetekleduzenle(widget.yeniEkleme, hizmetAdlari,
          widget.secilihizmetler, hizmetsureleri, hizmetfiyatlari, secilipersoneller,
          widget.isletmebilgi["id"].toString());
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = context.appTheme;
    return Scaffold(
      backgroundColor: ext.surfaceMuted,
      appBar: AppBar(
        toolbarHeight: 60,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: cs.onSurface,
        title: Text(
          "Hizmet Bilgileri",
          style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w700, fontSize: 17),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: cs.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: isloading
          ? Center(child: CircularProgressIndicator(color: cs.primary))
          : GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: widget.secilihizmetler.length,
                itemBuilder: (BuildContext context, int index) => _hizmetKarti(index),
              ),
            ),
      bottomNavigationBar: isloading
          ? const SizedBox.shrink()
          : Container(
              padding: EdgeInsets.fromLTRB(14, 10, 14, 10 + MediaQuery.of(context).padding.bottom),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: ext.shadowBase,
                    blurRadius: 12,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: _kaydet,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: ext.heroGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: cs.primary.withValues(alpha: 0.40),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(widget.yeniEkleme ? Icons.add_rounded : Icons.check_rounded,
                            color: cs.onPrimary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Hizmet$butonyazi',
                          style: TextStyle(
                            color: cs.onPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

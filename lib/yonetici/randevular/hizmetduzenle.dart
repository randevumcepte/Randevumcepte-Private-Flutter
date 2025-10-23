
import 'dart:developer';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'dart:collection';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:randevu_sistem/Models/isletmehizmetleri.dart';
import 'package:randevu_sistem/Models/randevuhizmetleri.dart';

import '../../Backend/backend.dart';
import '../../Models/cihazlar.dart';
import '../../Models/odalar.dart';
import '../../Models/personel.dart';
import '../../yeni/app_colors.dart';

class HizmetAdd extends StatefulWidget {
  final List<RandevuHizmet> secilihizmetler;
  final RandevuHizmet? duzenlenecek;
  final String personel_id;
  const HizmetAdd({Key? key,required this.secilihizmetler, this.duzenlenecek,required this.personel_id}) : super(key: key);

  @override

  _HizmetState createState() => new _HizmetState();
}
class CropList {
  final String cropName;


  CropList(
      this.cropName,

      );
}

class _HizmetState extends State<HizmetAdd> {
  bool isloading = true;


  HashSet<CropList> selectedItem = HashSet();
  late List<IsletmeHizmet> isletmehizmetliste;
  late List<Personel> personelliste;
  late List<Cihaz>cihazliste;
  late List<Oda>odaliste;
  bool usttekiilebirlestir = false;
  bool isMultiSelectionEnabled = true;


  List<Personel> seciliyardimcipersonel = [];


  TextEditingController suredk = TextEditingController();
  TextEditingController fiyat = TextEditingController();
  TextEditingController personel = TextEditingController();
  TextEditingController musteridanisan = TextEditingController();
  TextEditingController oda = TextEditingController();
  TextEditingController cihaz = TextEditingController();
  TextEditingController hizmet = TextEditingController();

  Personel ?secilipersonel;
  Oda ?secilioda;
  Cihaz ?secilicihaz;
  IsletmeHizmet ?secilihizmet;

  void initState() {

    super.initState();
    initialize();

  }

  Future<void> initialize() async
  {
    var seciliisletme = await secilisalonid();
    List<IsletmeHizmet> isletmehizmetleriliste = await isletmehizmetleri(seciliisletme!);
    List<Personel> isletmepersonellerliste = await personellistegetir(seciliisletme!);
    List<Cihaz>isletmecihazliste = await isletmecihazlari(seciliisletme!);
    List<Oda>isletmeodaliste = await isletmeodalari(seciliisletme!);


    setState(() {

      isletmehizmetliste = isletmehizmetleriliste;
      personelliste = isletmepersonellerliste;
      odaliste= isletmeodaliste;
      cihazliste = isletmecihazliste;


      if(widget.personel_id != "")
        secilipersonel = personelliste.firstWhere((element) => element.id.toString() == widget.personel_id.toString() );
      isloading = false;
      if(widget.duzenlenecek != null) {
        suredk.text = widget.duzenlenecek?.sure_dk ?? "";
        fiyat.text = widget.duzenlenecek?.fiyat ?? "";

        if(widget.duzenlenecek?.personeller!=null)
          secilipersonel = Personel.fromJson(widget.duzenlenecek?.personeller);
        if(widget.duzenlenecek?.oda!=null)
          secilioda = Oda.fromJson(widget.duzenlenecek?.oda);
        if(widget.duzenlenecek?.cihaz!=null)
          secilicihaz = Cihaz.fromJson(widget.duzenlenecek?.cihaz);
        if(widget.duzenlenecek?.hizmetler!=null){

          secilihizmet = IsletmeHizmet(hizmet_id: widget.duzenlenecek?.hizmet_id ?? "",fiyat: widget.duzenlenecek?.fiyat ?? "",bolum: widget.duzenlenecek?.hizmetler["bolum"], hizmet: widget.duzenlenecek?.hizmetler,hizmet_kategorisi: widget.duzenlenecek?.hizmetler["hizmet_kategori_id"],sure: "");
        }

      }
    });

  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        backgroundColor: Colors.white,
        title: Text("Hizmet Seçimi",style: TextStyle(color: Colors.black),),
        // centerTitle: isMultiSelectionEnabled ? false : true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),

      ),
      body: isloading ? Center(child: CircularProgressIndicator(),) :SingleChildScrollView(

        child:   Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 15.0),
              child: Text('Personel',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
            ),
            SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: Container(
                alignment: Alignment.center,

                height: 40,
                width:double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Color(0xFF6A1B9A)),
                  borderRadius: BorderRadius.circular(10), //border corner radius

                  //you can set more BoxShadow() here

                ),
                child: DropdownButtonHideUnderline(

                    child: DropdownButton2<Personel>(

                      isExpanded: true,
                      hint: Text(
                        'Personel Seç',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                      value: secilipersonel,
                      items: personelliste
                          .map((item) => DropdownMenuItem(
                        value: item,
                        child: Text(
                          item.personel_adi,
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      ))
                          .toList(),

                      onChanged: (value) {
                        setState(() {
                          secilipersonel = value;

                        });
                      },
                      buttonStyleData: const ButtonStyleData(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        height: 50,
                        width: 400,
                      ),

                      dropdownStyleData: const DropdownStyleData(
                        maxHeight: 400,

                      ),
                      menuItemStyleData: const MenuItemStyleData(
                        height: 40,
                      ),
                      dropdownSearchData: DropdownSearchData(
                        searchController: personel,
                        searchInnerWidgetHeight: 50,
                        searchInnerWidget: Container(
                          height: 50,
                          padding: const EdgeInsets.only(
                            top: 8,
                            bottom: 4,
                            right: 8,
                            left: 8,
                          ),
                          child: TextFormField(
                            expands: true,
                            maxLines: null,
                            controller: personel,

                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              hintText: 'Personel Ara..',
                              hintStyle: const TextStyle(fontSize: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        searchMatchFn: (item, searchValue) {

                          return item.value!.personel_adi.toString().toLowerCase().contains(searchValue.toLowerCase());
                        },
                      ),
                      //This to clear the search value when you close the menu
                      onMenuStateChange: (isOpen) {
                        if (!isOpen) {

                        }
                      },

                    )),
              ),
            ),
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 15.0),
              child: Text('Yardımcı Personel(-ler) (Opsiyonel)',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
            ),
            SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: Container(
                alignment: Alignment.center,

                height: 40,
                width:double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Color(0xFF6A1B9A)),
                  borderRadius: BorderRadius.circular(10), //border corner radius

                  //you can set more BoxShadow() here

                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton2(
                    isExpanded: true,
                    hint: Text(
                      'Yardımcı Personel(-ler)i Seç',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                    items: personelliste.map((item) {
                      return DropdownMenuItem<Personel>(
                        value: item,
                        child: StatefulBuilder(
                          builder: (context, menuSetState) {
                            final isSelected = seciliyardimcipersonel.contains(item);
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    seciliyardimcipersonel.remove(item);
                                  } else {
                                    seciliyardimcipersonel.add(item);
                                  }
                                });
                                menuSetState(() {}); // for updating the checkbox
                              },
                              child: Container(
                                height: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                child: Row(
                                  children: [
                                    Icon(
                                      isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                                      color: isSelected ? Colors.blue : null,
                                    ),
                                    const SizedBox(width: 16),
                                    Text(
                                      item.personel_adi,
                                      style: const TextStyle(
                                        fontSize: 14,
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
                    value: seciliyardimcipersonel.isEmpty ? null : seciliyardimcipersonel.last,
                    onChanged: (_) {},
                    buttonStyleData: const ButtonStyleData(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      height: 50,
                      width: 400,
                    ),

                    dropdownStyleData: const DropdownStyleData(
                      maxHeight: 400,

                    ),
                    menuItemStyleData: const MenuItemStyleData(
                      height: 40,
                    ),
                    selectedItemBuilder: (context) {
                      return personelliste.map((item) {
                        return Container(
                          alignment: AlignmentDirectional.centerStart,
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            seciliyardimcipersonel.map((e) => e.personel_adi).join(', '),
                            style: const TextStyle(
                              fontSize: 14,
                              overflow: TextOverflow.ellipsis,
                            ),
                            maxLines: 1,
                          ),
                        );
                      }).toList();
                    },

                  ),
                ),
              ),
            ),
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 15.0),
              child: Text('Hizmet',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
            ),
            SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: Container(
                alignment: Alignment.center,

                height: 40,
                width:double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Color(0xFF6A1B9A)),
                  borderRadius: BorderRadius.circular(10), //border corner radius

                  //you can set more BoxShadow() here

                ),
                child: DropdownButtonHideUnderline(

                    child: DropdownButton2<IsletmeHizmet>(

                      isExpanded: true,
                      hint: Text(
                        'Hizmet Seç',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                      items: isletmehizmetliste
                          .map((item) => DropdownMenuItem(
                        value: item,
                        child: Text(
                          item.hizmet['hizmet_adi'],
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      ))
                          .toList(),
                      value: secilihizmet,
                      onChanged: (value) {
                        setState(() {
                          secilihizmet = value;
                          suredk.text = value!.sure;
                          fiyat.text = value!.fiyat;
                        });
                      },
                      buttonStyleData: const ButtonStyleData(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        height: 50,
                        width: 400,
                      ),

                      dropdownStyleData: const DropdownStyleData(
                        maxHeight: 400,

                      ),
                      menuItemStyleData: const MenuItemStyleData(
                        height: 40,
                      ),
                      dropdownSearchData: DropdownSearchData(
                        searchController: hizmet,
                        searchInnerWidgetHeight: 50,
                        searchInnerWidget: Container(
                          height: 50,
                          padding: const EdgeInsets.only(
                            top: 8,
                            bottom: 4,
                            right: 8,
                            left: 8,
                          ),
                          child: TextFormField(
                            expands: true,
                            maxLines: null,
                            controller: hizmet,
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              hintText: 'Hizmet Ara..',
                              hintStyle: const TextStyle(fontSize: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        searchMatchFn: (item, searchValue) {


                          return item.value!.hizmet["hizmet_adi"].toString().toLowerCase().contains(searchValue.toLowerCase());
                        },
                      ),
                      //This to clear the search value when you close the menu
                      onMenuStateChange: (isOpen) {
                        if (!isOpen) {

                        }
                      },

                    )),
              ),
            ),


            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 15.0),
              child: Text('Oda (Opsiyonel)',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
            ),
            SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: Container(
                alignment: Alignment.center,

                height: 40,
                width:double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Color(0xFF6A1B9A)),
                  borderRadius: BorderRadius.circular(10), //border corner radius

                  //you can set more BoxShadow() here

                ),
                child: DropdownButtonHideUnderline(

                    child: DropdownButton2<Oda>(

                      isExpanded: true,
                      hint: Text(
                        'Oda Seç',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                      value: secilioda,
                      items: odaliste
                          .map((item) => DropdownMenuItem(
                        value: item,
                        child: Text(
                          item.oda_adi,
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      ))
                          .toList(),

                      onChanged: (value) {
                        setState(() {
                          secilioda = value;
                        });
                      },
                      buttonStyleData: const ButtonStyleData(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        height: 50,
                        width: 400,
                      ),

                      dropdownStyleData: const DropdownStyleData(
                        maxHeight: 400,

                      ),
                      menuItemStyleData: const MenuItemStyleData(
                        height: 40,
                      ),
                      dropdownSearchData: DropdownSearchData(
                        searchController: oda,
                        searchInnerWidgetHeight: 50,
                        searchInnerWidget: Container(
                          height: 50,
                          padding: const EdgeInsets.only(
                            top: 8,
                            bottom: 4,
                            right: 8,
                            left: 8,
                          ),
                          child: TextFormField(
                            expands: true,
                            maxLines: null,
                            controller: oda,
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              hintText: 'Oda Ara..',
                              hintStyle: const TextStyle(fontSize: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        searchMatchFn: (item, searchValue) {

                          return item.value!.oda_adi.toString().toLowerCase().contains(searchValue.toLowerCase());
                        },
                      ),
                      //This to clear the search value when you close the menu
                      onMenuStateChange: (isOpen) {
                        if (!isOpen) {

                        }
                      },

                    )),
              ),
            ),
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 15.0),
              child: Text('Cihaz (Opsiyonel)',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
            ),
            SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: Container(
                alignment: Alignment.center,

                height: 40,
                width:double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Color(0xFF6A1B9A)),
                  borderRadius: BorderRadius.circular(10), //border corner radius

                  //you can set more BoxShadow() here

                ),
                child: DropdownButtonHideUnderline(

                    child: DropdownButton2<Cihaz>(

                      isExpanded: true,
                      hint: Text(
                        'Cihaz Seç',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                      items: cihazliste
                          .map((item) => DropdownMenuItem(
                        value: item,
                        child: Text(
                          item.cihaz_adi,
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      ))
                          .toList(),
                      value: secilicihaz,
                      onChanged: (value) {
                        setState(() {
                          secilicihaz = value;
                        });
                      },
                      buttonStyleData: const ButtonStyleData(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        height: 50,
                        width: 400,
                      ),

                      dropdownStyleData: const DropdownStyleData(
                        maxHeight: 400,

                      ),
                      menuItemStyleData: const MenuItemStyleData(
                        height: 40,
                      ),
                      dropdownSearchData: DropdownSearchData(
                        searchController: cihaz,
                        searchInnerWidgetHeight: 50,
                        searchInnerWidget: Container(
                          height: 50,
                          padding: const EdgeInsets.only(
                            top: 8,
                            bottom: 4,
                            right: 8,
                            left: 8,
                          ),
                          child: TextFormField(
                            expands: true,
                            maxLines: null,controller: cihaz,
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              hintText: 'Cihaz Ara..',
                              hintStyle: const TextStyle(fontSize: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        searchMatchFn: (item, searchValue) {

                          return item.value!.cihaz_adi.toString().toLowerCase().contains(searchValue.toLowerCase());
                        },
                      ),
                      //This to clear the search value when you close the menu
                      onMenuStateChange: (isOpen) {
                        if (!isOpen) {

                        }
                      },

                    )),
              ),
            ),
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 15.0),
              child: Text('Süre (dk)',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
            ),
            SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: TextFormField(

                onSaved: (value){
                  suredk.text=value!;
                },
                keyboardType: TextInputType.phone,
                controller: suredk,
                decoration: InputDecoration(


                  contentPadding:  EdgeInsets.all(15.0),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(
                      color: Color(0xFF6A1B9A)),borderRadius: BorderRadius.circular(10.0),),
                  border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10.0),),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF6A1B9A),), borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
              ),
            ),
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 15.0),
              child: Text('Fiyat (₺)',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
            ),
            SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),

              child: TextFormField(
                controller: fiyat,

                keyboardType: TextInputType.phone,
                onSaved: (value){
                  fiyat.text=value!;
                },
                decoration: InputDecoration(

                  focusColor:Color(0xFF6A1B9A) ,
                  contentPadding: EdgeInsets.symmetric(vertical: 3, horizontal: 10.0),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(
                      color: Color(0xFF6A1B9A)),borderRadius: BorderRadius.circular(10.0),),
                  border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10.0),),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF6A1B9A),), borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
              ),
            ),
            SizedBox(height: 10),
            widget.secilihizmetler.length > 0 ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Checkbox(
                  value: usttekiilebirlestir,
                  onChanged: (bool? value) {
                    setState(() {
                      usttekiilebirlestir = value!;
                    });
                  },
                ),
                Expanded(
                  child: Text('Bir üstteki hizmet ile aynı anda başlaması için işaretleyiniz',
                    style: TextStyle(fontSize: 14),
                  ),
                )

              ],
            ) : Text(''),

            SizedBox(height: 5),

          ],
        ),
      ),
      bottomNavigationBar: Container(
        height: 65,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: const BoxDecoration(
          color: AppColors.mainBg,
        ),
        child:   ElevatedButton(onPressed: (){
          setState(() {
            final List<RandevuHizmet> randevuhizmetleri = [];
            seciliyardimcipersonel.forEach((element) {
              randevuhizmetleri.add(RandevuHizmet(hizmetler: secilihizmet?.hizmet, hizmet_id: secilihizmet!.hizmet["id"].toString(), personel_id: element.id.toString(), personeller: element.toMap(), oda_id: secilioda!=null?secilioda!.id.toString():'', oda: secilioda?.toMap(), cihaz_id: secilicihaz!=null?secilicihaz!.id.toString():'', cihaz: secilicihaz?.toMap(), fiyat: fiyat.text, sure_dk: suredk.text, saat: '', saat_bitis: '', yardimci_personel: '1',birusttekiileaynisaat: usttekiilebirlestir ? "1" : "0"));
            });
            randevuhizmetleri.add(RandevuHizmet(hizmetler: secilihizmet?.hizmet, hizmet_id: secilihizmet!.hizmet["id"].toString(), personel_id: secilipersonel!=null?secilipersonel!.id.toString():'', personeller: secilipersonel?.toMap(), oda_id: secilioda!=null?secilioda!.id.toString():'', oda: secilioda?.toMap(), cihaz_id: secilicihaz!=null?secilicihaz!.id.toString():'', cihaz: secilicihaz?.toMap(), fiyat: fiyat.text, sure_dk: suredk.text, saat: '', saat_bitis: '', yardimci_personel: '0' ,birusttekiileaynisaat: usttekiilebirlestir ? "1" : "0"));

            Navigator.pop(context,randevuhizmetleri);
          });
        },

          child: Text('Kaydet'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            minimumSize: Size(90, 40),

          ),
        ),
      ),
    );
  }

  String getSelectedItemCount() {
    return selectedItem.isNotEmpty
        ? selectedItem.length.toString() + " tane hizmet seçildi"
        : "Hizmet Seçilmedi";
  }

  void doMultiSelection(CropList croplist) {
    if (isMultiSelectionEnabled) {
      if (selectedItem.contains(croplist)) {
        selectedItem.remove(croplist);
      } else {
        selectedItem.add(croplist);
      }
      setState(() {});
    } else {
      //Other logic create hear
    }
  }

  InkWell getCropListItem(CropList croplist) {
    return InkWell(
        onTap: () {
          isMultiSelectionEnabled = true;
          doMultiSelection(croplist);
        },
        onLongPress: () {

          doMultiSelection(croplist);
        },
        child: Stack(alignment: Alignment.centerLeft, children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const SizedBox(
                      height: 10,
                    ),
                    SizedBox(
                      width: double.infinity,
                      height: 18.0,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 40.0),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 1.0),
                          child: Text(
                            croplist.cropName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontFamily: 'Poppins',
                              fontStyle: FontStyle.normal,
                              color: AppColors.textRegColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
          Visibility(
              visible: isMultiSelectionEnabled,
              child: Icon(
                selectedItem.contains(croplist)
                    ? Icons.check_box
                    : Icons.check_box_outline_blank,
                size: 30,
                color: Colors.deepPurple,
              ))
        ]));
  }
}
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

import '../Backend/backend.dart';
import '../Frontend/popupdialogs.dart';
import '../Frontend/sfdatatable.dart';
import '../Models/cihazlar.dart';
import '../Models/hizmetler.dart';
import '../Models/personel.dart';
import '../Models/personelcihaz.dart';
import 'app_colors.dart';

class CalisanSecimi extends StatefulWidget {
  final dynamic isletmebilgi;
  final List<Hizmet> secilihizmetler;

  final HizmetlerDataSource hizmetDataGridSource;
  const CalisanSecimi({Key? key, required this.isletmebilgi, required this.secilihizmetler,required this.hizmetDataGridSource}) : super(key: key);

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
        if(element.hizmet_id != "null")
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        toolbarHeight: 60,
        backgroundColor: Colors.white,
        title: Text("Hizmet Bilgileri", style: TextStyle(color: Colors.black)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: isloading
          ? Center(child: CircularProgressIndicator())
          : GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();  // Hide keyboard when tapping outside
        },
        child: ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: widget.secilihizmetler.length,
          itemBuilder: (BuildContext context, int index) {
            final data = widget.secilihizmetler[index];



            return Container(
              padding: EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.hizmet_adi + " için bilgiler",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Personel(-ler) & Cihaz(-lar)',
                    style: TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 5),
                  Container(
                    alignment: Alignment.center,
                    height: 40,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Color(0xFF6A1B9A)),
                      borderRadius: BorderRadius.circular(10), // Border corner radius
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton2<PersonelCihaz>(

                        isExpanded: true,
                        hint: Text(
                          'Personel veya cihazları seçin...',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).hintColor,
                          ),
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

                                    menuSetState(() {}); // Updates the dropdown menu
                                  },
                                  child: Container(
                                    height: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                    child: Row(
                                      children: [
                                        if (isSelected)
                                          const Icon(Icons.check_box_outlined)
                                        else
                                          const Icon(Icons.check_box_outline_blank),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Text(
                                            (item is Personel)
                                                ? item.personel_adi
                                                : (item is Cihaz ? item.cihaz_adi : 'Bilinmiyor'),
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
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
                              alignment: AlignmentDirectional.center,
                              child: Text(
                                secilipersoneller[index].isNotEmpty
                                    ? secilipersoneller[index].map((e) {
                                  return e is Personel ? e.personel_adi : (e is Cihaz ? e.cihaz_adi : "Bilinmiyor");
                                }).join(', ')
                                    : 'No selection',
                                style: const TextStyle(
                                  fontSize: 14,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                maxLines: 1,
                              ),
                            );
                          });
                        },
                        buttonStyleData: const ButtonStyleData(
                          padding: EdgeInsets.only(left: 16, right: 8),
                          height: 40,
                          width: double.infinity,
                        ),
                        menuItemStyleData: const MenuItemStyleData(
                          height: 40,
                          padding: EdgeInsets.zero,
                        ),
                        dropdownStyleData: const DropdownStyleData(maxHeight: 300),
                        dropdownSearchData: DropdownSearchData(
                          searchController: filterController[index],
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
                              controller: filterController[index],
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                hintText: 'Personel & cihaz ara...',
                                hintStyle: const TextStyle(fontSize: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),

                          searchMatchFn: (item, searchValue) {
                            if (item.value is Personel) {
                              return (item.value as Personel).personel_adi.toString().toLowerCase().contains(searchValue.toLowerCase());
                            }
                            else if (item.value is Cihaz)
                              return (item.value as Cihaz).cihaz_adi.toString().toLowerCase().contains(searchValue.toLowerCase());
                            return false;
                          },
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 15),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              child: Text('Süre (dk)', style: TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold)),
                            ),
                            SizedBox(height: 10),
                            Container(
                              padding: EdgeInsets.only(right: 10),
                              height: 40,
                              child: TextFormField(
                                keyboardType: TextInputType.phone,
                                controller: hizmetsuresi[index],
                                onSaved: (value) {
                                  setState(() {
                                    hizmetsuresi[index].text = value!;
                                  });

                                },
                                decoration: InputDecoration(
                                  filled: true,
                                  focusColor: Color(0xFF6A1B9A),
                                  fillColor: Colors.white,
                                  hoverColor: Color(0xFF6A1B9A),
                                  hintStyle: TextStyle(color: Color(0xFF6A1B9A)),
                                  contentPadding: EdgeInsets.all(15.0),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Color(0xFF6A1B9A)),
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Color(0xFF6A1B9A)),
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.only(left: 10),
                              child: Text('Fiyat (₺)', style: TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold)),
                            ),
                            SizedBox(height: 10),
                            Container(
                              padding: EdgeInsets.only(left: 10),
                              height: 40,
                              child: TextFormField(
                                keyboardType: TextInputType.phone,
                                controller: hizmetfiyat[index],
                                onSaved: (value) {
                                  setState(() {
                                    hizmetfiyat[index].text = value!;
                                  });

                                },
                                decoration: InputDecoration(
                                  filled: true,
                                  focusColor: Color(0xFF6A1B9A),
                                  fillColor: Colors.white,
                                  hoverColor: Color(0xFF6A1B9A),
                                  hintStyle: TextStyle(color: Color(0xFF6A1B9A)),
                                  contentPadding: EdgeInsets.all(15.0),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Color(0xFF6A1B9A)),
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Color(0xFF6A1B9A)),
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: isloading ? SizedBox.shrink() : Container(
        height: 65,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: const BoxDecoration(
          color: AppColors.mainBg,
        ),
        child: ElevatedButton(
          onPressed: () {
            List<String>hizmetsureleri=[];
            List<String>hizmetfiyatlari=[];
            bool formvalid = true;
             if(secilipersoneller.length==0)
                formvalid = false;
            hizmetsuresi.forEach((element) {
              {
                if(element.text == "")
                  formvalid = false;
                else
                  hizmetsureleri.add(element.text);
              }
            });
            hizmetfiyat.forEach((element) {
              hizmetfiyatlari.add(element.text);
            });
            if(!formvalid)
              formWarningDialogs(context, 'UYARI', "Hizmet eklemeden önce bilgilerin hizmete ait personel/cihaz ve süre bilgisinin eksiksiz girilmesi gerekmektedir. Lütfen formu tekrar kontrol ediniz.");
            else
            {
              widget.secilihizmetler.forEach((element) {
                log(element.id +" - "+element.hizmet_id);
              });

                widget.hizmetDataGridSource.hizmetekleduzenle(widget.secilihizmetler, hizmetsureleri, hizmetfiyatlari, secilipersoneller,widget.isletmebilgi["id"].toString());

            }
          },
          child: Text('Hizmet '+butonyazi),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            minimumSize: Size(90, 40),
          ),
        ),
      ),
    );
  }
}

import 'dart:developer';

import 'package:flutter/material.dart';
import 'dart:collection';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:line_icons/line_icon.dart';
import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';


import '../Frontend/sfdatatable.dart';
import '../Models/hizmetler.dart';
import '../yonetici/diger/menu/ayarlar/hizmetler/listedeolmayanhizmet.dart';
import 'app_colors.dart';
import 'calisan_secim.dart';
import 'musteri_secimi.dart';

class HizmetSecimi extends StatefulWidget {
  final dynamic isletmebilgi;
  final HizmetlerDataSource hizmetDataGridSource;
  const HizmetSecimi({Key? key,required this.isletmebilgi,required this.hizmetDataGridSource}) : super(key: key);

  @override

  _HizmetSecimiState createState() => new _HizmetSecimiState();
}
class _HizmetSecimiState extends State<HizmetSecimi> {
  List<Hizmet> hizmet = [];
  List<Hizmet> filteredhizmet = [];
  List<Hizmet> notSelectedHizmet = []; // List for services not selected
  bool isloading = true;
  List<Hizmet> secilihizmetler = [];
  bool isMultiSelectionEnabled = true;
  late String seciliisletme;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void initialize() async {
    seciliisletme = (await secilisalonid())!;


    // Fetch the services
    List<Hizmet> hizmetlist = await seciliolmayanhizmetgetir(seciliisletme);

    setState(() {
      // Assuming you fetch both selected and non-selected services from the same method or two different ones.
      hizmet = hizmetlist;
      filteredhizmet = hizmetlist;
      notSelectedHizmet = hizmetlist.where((hizmet) => !secilihizmetler.contains(hizmet)).toList();
      isloading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 60,
        backgroundColor: Colors.white,
        title: Text("Hizmet Seçimi", style: TextStyle(color: Colors.black)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (widget.isletmebilgi["demo_hesabi"].toString() == "1")
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: SizedBox(
              width: 100,
              child: YukseltButonu(isletme_bilgi: widget.isletmebilgi,),
            ),
          ),
        ],
      ),
      body: isloading
          ? Center(child: CircularProgressIndicator())
          : Container(
        color: AppColors.mainBg,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [


            SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: TextFormField(
                onChanged: (value) {
                  setState(() {
                    if (value.isEmpty) {
                    filteredhizmet = List.from(hizmet); // Reset to full list when search is empty
                  } else {
                    filteredhizmet = hizmet.where((element) {
                      return element.hizmet_adi.toLowerCase().contains(value.toLowerCase()) ||
                          element.hizmet_kategori['hizmet_kategorisi_adi'].toLowerCase().contains(value.toLowerCase());
                    }).toList();
                  }
                    List<Hizmet> filteredData = hizmet.where((element) {
                      return element.hizmet_adi.toLowerCase().contains(value.toLowerCase()) ||
                          element.hizmet_kategori['hizmet_kategorisi_adi'].toLowerCase().contains(value.toLowerCase());
                    }).toList();

                    setState(() {
                      filteredhizmet = filteredData;


                    });
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Ara',
                  prefixIcon: Icon(Icons.search),
                  contentPadding: EdgeInsets.fromLTRB(8, 5, 10, 5),
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
              ),
            ),
            SizedBox(height: 10),

            // Unselected Services List Box
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ListedeOlmayanHizmet(isletmebilgi: widget.isletmebilgi,)),
                  );
                },
                child: Container(
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Listede olmayan hizmet',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(Icons.arrow_forward, color: Colors.purple),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 10),
            Expanded(
              child: ListView(
                children: filteredhizmet.map((Hizmet croplist) {
                  return Card(
                    elevation: 10,
                    margin: const EdgeInsets.only(left: 10, right: 10, top: 5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(
                          left: 10, right: 10, top: 2, bottom: 5),
                      height: 40.0,
                      child: getCropListItem(croplist),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        height: 65,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: const BoxDecoration(
          color: AppColors.mainBg,
        ),
        child: Center(
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 5.0),
                    child: Text(isMultiSelectionEnabled
                        ? getSelectedItemCount()
                        : "tane hizmets seçildi"),
                  ),
                  const SizedBox(height: 5),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: 150,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    textStyle: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold,
                    ),
                    backgroundColor: Colors.purple[800],
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {


                     Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CalisanSecimi(
                          isletmebilgi: widget.isletmebilgi,
                          secilihizmetler: secilihizmetler,
                          hizmetDataGridSource: widget.hizmetDataGridSource,
                        ),
                      ),
                    );
                  },
                  child: Text('Sonraki'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  String getSelectedItemCount() {
    return secilihizmetler.isNotEmpty
        ? secilihizmetler.length.toString() + " tane hizmet seçildi"
        : "Hizmet Seçilmedi";
  }

  void doMultiSelection(Hizmet croplist) {
    if (isMultiSelectionEnabled) {
      if (secilihizmetler.contains(croplist)) {
        secilihizmetler.remove(croplist);
      } else {
        secilihizmetler.add(croplist);
      }
      setState(() {
        notSelectedHizmet = hizmet.where((hizmet) => !secilihizmetler.contains(hizmet)).toList();
      });
    } else {
      //Other logic create here
    }
  }

  InkWell getCropListItem(Hizmet croplist) {
    return InkWell(
      onTap: () {
        isMultiSelectionEnabled = true;
        doMultiSelection(croplist);
      },
      onLongPress: () {
        doMultiSelection(croplist);
      },
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 18.0,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 40.0),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 1.0),
                          child: Text(
                            croplist.hizmet_adi +
                                " (" +
                                croplist.hizmet_kategori["hizmet_kategorisi_adi"] +
                                ")",
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
              secilihizmetler.contains(croplist) ? Icons.check_box : Icons.check_box_outline_blank,
              size: 30,
              color: Colors.deepPurple,
            ),
          ),
        ],
      ),
    );
  }
}

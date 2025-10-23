
import 'package:flutter/material.dart';
import 'dart:collection';

import '../../../yeni/app_colors.dart';
import 'hizmetler.dart';

class HizmetCalisan extends StatefulWidget {
  const HizmetCalisan({Key? key}) : super(key: key);

  @override

  _HizmetCalisanState createState() => new _HizmetCalisanState();
}
class CropList {
  final String cropName;


  CropList(
      this.cropName,

      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is CropList &&
              runtimeType == other.runtimeType;


}

class _HizmetCalisanState extends State<HizmetCalisan> {
  List<CropList> cropList = [
    CropList("Saç Kesimi"),
    CropList("Manikür",),
    CropList("Pedikür",),
    CropList("Ağda",),
  ];

  HashSet<CropList> selectedItem = HashSet();
  bool isMultiSelectionEnabled = true;
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
      body: Container(
        color: AppColors.mainBg,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    //   searchString = value.toLowerCase();
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

            Expanded(
              child: ListView(
                children: cropList.map((CropList croplist) {
                  return Card(
                      elevation: 20,
                      margin:
                      const EdgeInsets.only(left: 10, right: 10, top: 5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5)),
                      child: Container(
                        margin: const EdgeInsets.only(
                            left: 10, right: 10, top: 2, bottom: 5),
                        height: 40.0,
                        child: getCropListItem(croplist),
                      ));
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
                        : "tane hizmet seçildi"),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: 150,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    textStyle:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    backgroundColor: Colors.purple[800], // background (button) color
                    foregroundColor: Colors.white,),
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                Hizmetler()));
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
                            style: TextStyle(
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
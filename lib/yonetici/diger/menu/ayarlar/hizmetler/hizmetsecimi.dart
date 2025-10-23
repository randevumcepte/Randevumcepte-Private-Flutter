import 'package:flutter/material.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'listedeolmayanhizmet.dart';

class HizmetSecimi extends StatefulWidget {
  final dynamic isletmebilgi;
  const HizmetSecimi({Key? key,required this.isletmebilgi}) : super(key: key);
  @override
  HizmetSecimiState createState() => HizmetSecimiState();
}

class HizmetSecimiState extends State<HizmetSecimi> {


  List<String> items = [
    'Ferdi Korkmaz',
    'Gülşah Korkmaz',
    'Elif Çetin',
    'Cevriye Efe',
    'Çağlar Filiz',
    'Anıl Orbey',
    'Esra Kip',
    'Baran Güneş',
    'Gamze Yalçın',
  ];

  List<String> selectedItems = [];

  void toggleItemSelection(String item) {
    if (selectedItems.contains(item)) {
      selectedItems.remove(item);
    } else {
      selectedItems.add(item);
    }
  }
  bool selectAll = false;
  TextEditingController searchController = TextEditingController();
  String buttonLabel = 'Hizmetlerin Ekleneceği Personelleri Seç ';
  void updateButtonLabel() {
    setState(() {
      if (selectedItems.isEmpty) {
        buttonLabel = 'Hizmetlerin Ekleneceği Personelleri Seç ';
      } else if (selectedItems.length <= items.length) {
        buttonLabel = '${selectedItems.length} tane personel ';
      }
      else {
        buttonLabel = '${selectedItems.length} tane personel ';
      }

    });
  }

  void showCheckboxPopup(BuildContext context) {
    showDialog(
      context: context,

      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              scrollable: true,

              title: Text('Hizmet Personel Seçimi'),
              content: SingleChildScrollView(
                child: Container(
                  height: 400,
                  width: double.infinity,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextField(
                        controller: searchController,
                        decoration: InputDecoration(labelText: 'Ara'),
                        onChanged: (value) {
                          setState(() {});
                        },
                      ),
                      SizedBox(height: 10),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 5.0),
                                  child: Text('Süre(dk)',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                                ),
                                SizedBox(height: 10,),
                                Container(
                                  height: 40,
                                  width: 110,
                                  child: TextField(

                                    keyboardType: TextInputType.text,



                                    decoration: InputDecoration(

                                      focusColor:Color(0xFF6A1B9A) ,
                                      hoverColor: Color(0xFF6A1B9A) ,
                                      hintStyle: TextStyle(color:  Color(0xFF6A1B9A)),
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
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 5.0),
                                  child: Text('Fiyat(₺)',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                                ),
                                SizedBox(height: 10,),
                                Container(
                                  height: 40,
                                  width: 110,
                                  child: TextField(

                                    keyboardType: TextInputType.text,



                                    decoration: InputDecoration(

                                      focusColor:Color(0xFF6A1B9A) ,
                                      hoverColor: Color(0xFF6A1B9A) ,
                                      hintStyle: TextStyle(color:  Color(0xFF6A1B9A)),
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
                              ],
                            ),
                          ),
                        ],
                      ),
                      Container(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              if (selectAll) {
                                selectedItems.clear();
                              } else {
                                selectedItems.addAll(items);
                              }
                              selectAll = !selectAll;
                              updateButtonLabel();// Toggle the "Select All" state
                            });
                          },
                          child: Text(selectAll ? 'Tümünü Seçme' : 'Tümünü Seç'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple[800],
                            minimumSize: Size(150, 30),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0)
                            ),
                            elevation: 5,

                          ),
                        ),
                      ),
                      Container(
                        height: 200,
                        width: 300,
                        child: ListView.builder(
                          itemCount: items.length,
                          shrinkWrap: true,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            if (searchController.text.isNotEmpty &&
                                !item.toLowerCase().contains(
                                    searchController.text.toLowerCase())) {
                              return Container();
                            }
                            return CheckboxListTile(
                              title: Text(item),

                              activeColor: Colors.purple[800],
                              value: selectedItems.contains(item),

                              onChanged: (bool? value) {
                                setState(() {
                                  toggleItemSelection(item);
                                  updateButtonLabel();
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Kapat',style: TextStyle(color: Colors.black),),
                ),
                TextButton(
                  onPressed: () {
                    // Handle selected items
                    print('Selected items: $selectedItems');
                    buttonLabel = '${selectedItems.length} tane personel';
                    Navigator.of(context).pop();
                  },
                  child: Text('Kaydet',style: TextStyle(color: Colors.purple[800]),),
                ),
              ],
            );
          },
        );
      },
    );
  }



  List<ChecklistItem> hizmetler = [
    ChecklistItem(' Cilt Bakımı', true),
    ChecklistItem('Kraliçe Bakım', false),
    ChecklistItem('Akne Protokolü', false),
    ChecklistItem(' Zayıflama', true),
    ChecklistItem('Lenf Drenaj', false),
    ChecklistItem('Pasif Jimnastik', false),
    ChecklistItem(' Kalıcı Makyaj', true),
    ChecklistItem('Babyliner', false),
    ChecklistItem('Pudralama', false),
  ];

  String filter = '';
  void toggleCheckbox(int index) {
    setState(() {
      if (!hizmetler[index].isCategory) {
        hizmetler[index].isChecked = !hizmetler[index].isChecked;
      }
    });
  }

  void hizmetselectAll() {
    setState(() {
      for (var item in hizmetler) {
        if (!item.isCategory) {
          item.isChecked = true;
        }
      }
    });
  }

  void hizmetdeselectAll() {
    setState(() {
      for (var item in hizmetler) {
        if (!item.isCategory) {
          item.isChecked = false;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Hizmet Seçimi',style: TextStyle(color:Colors.black),),
        actions: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: SizedBox(
              width: 100, // <-- Your width
              child: YukseltButonu(isletme_bilgi: null,)
            ),
          ),
          IconButton(
            icon: Icon(Icons.check,color: Colors.black,),
            onPressed: hizmetselectAll,
          ),
          IconButton(
            icon: Icon(Icons.close,color:Colors.black),
            onPressed: hizmetdeselectAll,
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  filter = value.toLowerCase();
                });
              },

              decoration: InputDecoration(
                labelText: 'Hizmet Ara',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Padding(padding: const EdgeInsets.all(8.0),
            child:  ElevatedButton(onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ListedeOlmayanHizmet(isletmebilgi: widget,)),
              );
            }, child:
            Container(
              width: 200,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add),
                  SizedBox(width: 5,),
                  Text('Listede olmayan hizmet'),
                ],
              ),
            ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple[800],
                elevation: 5,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.0)
                ),

              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: hizmetler.length,
              itemBuilder: (context, index) {
                final item = hizmetler[index];
                if (filter.isNotEmpty &&
                    !item.text.toLowerCase().contains(filter)) {
                  return Container();
                }
                return ListTile(
                  title: Container(
                      height: 30,
                      padding: EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        color: item.isCategory ? Colors.grey[300 ] : null,
                      ),

                      child: Text(item.text,  style: item.isCategory ? TextStyle(fontWeight: FontWeight.bold): null,)),

                  trailing: item.isCategory
                      ? null
                      : Checkbox(
                    value: item.isChecked,
                    onChanged: (value) => toggleCheckbox(index),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 20,),
          ElevatedButton(
            onPressed: () {
              showCheckboxPopup(context);
            },
            child: Text(buttonLabel),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              minimumSize: Size(300, 40),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0)
              ),
              elevation: 5,
            ),

          ),
        ],
      ),
    );
  }
}

class ChecklistItem {
  String text;
  bool isChecked;
  bool isCategory;

  ChecklistItem(this.text, this.isCategory, {this.isChecked = false});
}

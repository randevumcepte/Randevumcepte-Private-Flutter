  import 'dart:developer';

  import 'package:dropdown_button2/dropdown_button2.dart';
   import 'package:flutter/material.dart';
  import 'package:intl/intl.dart';
  import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';

  import '../../../../../Backend/backend.dart';
  import '../../../../../Models/isletmehizmetleri.dart';
  import '../../../../../Models/paket_hizmetleri.dart';


  class BirHizmetDaha extends StatefulWidget {
    final List<PaketHizmetleri> secilihizmetler;
    final PaketHizmetleri? duzenlenecek;
    final dynamic isletmebilgi;
    BirHizmetDaha({Key? key, required this.secilihizmetler, this.duzenlenecek,required this.isletmebilgi}) : super(key: key);
    @override
    _BirHizmetDahaState createState() => _BirHizmetDahaState();
  }
  class _BirHizmetDahaState extends State<BirHizmetDaha> {

    TextEditingController seans = TextEditingController();

    String? selectedhizmet='';
    TextEditingController hizmetController2 = TextEditingController();
    late List<IsletmeHizmet> isletmehizmetliste;
    IsletmeHizmet ?secilihizmet;
    bool _isloading=true;

    TextEditingController fiyat = TextEditingController();
    TextEditingController hizmet = TextEditingController();

    TextEditingController pakethizmetfiyat = TextEditingController();
    TextEditingController pakethizmetseans = TextEditingController();
    void initState() {

      super.initState();
      initialize();

    }

    Future<void> initialize() async
    {
      var seciliisletme = await secilisalonid();
      List<IsletmeHizmet> isletmehizmetleriliste = await isletmehizmetleri(seciliisletme!);
      setState(() {
        isletmehizmetliste = isletmehizmetleriliste;
        _isloading=false;
        if(widget.duzenlenecek?.hizmet!=null){

          secilihizmet = IsletmeHizmet(hizmet_id: widget.duzenlenecek?.hizmet_id ?? "",fiyat: widget.duzenlenecek?.fiyat ?? "",bolum: widget.duzenlenecek?.hizmet["bolum"], hizmet: widget.duzenlenecek?.hizmet,hizmet_kategorisi: widget.duzenlenecek?.hizmet["hizmet_kategori_id"],sure: "");
        }
      });
    }
    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title:  const Text('Pakete Yeni Hiznet',style: TextStyle(color: Colors.black),),

          leading: IconButton(
            icon: Icon(Icons.clear_rounded, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            if (widget.isletmebilgi["demo_hesabi"].toString() == "1")
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: SizedBox(
                width: 100, // <-- Your width
                child: YukseltButonu(isletme_bilgi: widget.isletmebilgi,),
              ),
            ),
          ],
          toolbarHeight: 60,

          backgroundColor: Colors.white,
        ),
        body:  _isloading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20,),
                Container(
                  padding: const EdgeInsets.only(left: 5.0),
                  child: Text('Hizmet',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                ),
                SizedBox(height: 10,),
                Container(
                  alignment: Alignment.center,
                  height: 40,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Color(0xFF6A1B9A)),
                    borderRadius: BorderRadius.circular(10),
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
                          .map((item) => DropdownMenuItem<IsletmeHizmet>(
                        value: item,
                        child: Text(
                          item.hizmet['hizmet_adi'],
                          style: const TextStyle(fontSize: 14),
                        ),
                      ))
                          .toList(),
                      value: secilihizmet,
                      onChanged: (value) {
                        setState(() {
                          secilihizmet = value;
                        });
                      },
                      buttonStyleData: const ButtonStyleData(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        height: 50,
                        width: 400,
                      ),
                      dropdownStyleData: const DropdownStyleData(maxHeight: 400),
                      menuItemStyleData: const MenuItemStyleData(height: 40),
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
                          return item.value!.hizmet["hizmet_adi"]
                              .toString()
                              .toLowerCase()
                              .contains(searchValue.toLowerCase());
                        },
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 20,),
                Padding(
                  padding: const EdgeInsets.only(left: 5.0),
                  child: Text('Seans',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                ),
                SizedBox(height: 10,),
                Container(
                  height: 40,
                  child: TextFormField(

                    keyboardType: TextInputType.phone,
                    controller: seans,
                    onSaved: (value){
                      seans.text=value!;
                    },




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
                SizedBox(height: 20,),
                Padding(
                  padding: const EdgeInsets.only(left: 5.0),
                  child: Text('Fiyat (₺)',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                ),
                SizedBox(height: 10,),
                Container(
                  height: 40,
                  child: TextFormField(

                    keyboardType: TextInputType.phone,

                    controller: fiyat,
                    onSaved: (value){
                      fiyat.text=value!;
                    },

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
                SizedBox(height: 20,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(onPressed: (){
                   setState(() {
                     final List<PaketHizmetleri> pakethizmetleri = [];
                     pakethizmetleri.add(PaketHizmetleri(seans: seans.text, fiyat: fiyat.text, hizmet: secilihizmet?.hizmet, hizmet_id: secilihizmet!.hizmet["id"].toString()));
                     Navigator.pop(context,pakethizmetleri);
                   });
                    },
                      child: Text('Kaydet'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                          backgroundColor: Colors.green,
                          minimumSize: Size(90, 40)
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      );
    }

  }
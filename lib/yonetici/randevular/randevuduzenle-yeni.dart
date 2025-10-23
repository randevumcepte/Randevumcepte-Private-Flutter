import 'dart:ui';

import 'package:dropdown_button2/dropdown_button2.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';

import '../../Backend/backend.dart';
import '../../Frontend/datetimeformatting.dart';
import '../../Frontend/popupdialogs.dart';

import '../../Models/cihazlar.dart';
import '../../Models/isletmehizmetleri.dart';
import '../../Models/musteri_danisanlar.dart';
import '../../Models/odalar.dart';
import '../../Models/personel.dart';
import '../../Models/randevuhizmetleri.dart';
import '../../Models/randevuhizmetyardimcipersonelleri.dart';

import '../../Models/randevular.dart';
import '../../Models/randevutekrarsikligi.dart';
import '../../yeni/app_colors.dart';
import 'hizmet_add.dart';
import 'package:randevu_sistem/yonetici/randevular/musteri.dart';


class RandevuDuzenle extends StatefulWidget {

  final Randevu randevu;
  final dynamic isletmebilgi;
  final String tarihsaat;
  final String personel_id;
  const RandevuDuzenle({Key? key,required this.randevu,required this.isletmebilgi,required this.tarihsaat, required this.personel_id}) : super(key: key);
  @override
  AppointmentEditorState createState() => AppointmentEditorState();
}

class AppointmentEditorState extends State<RandevuDuzenle> {

  late List<IsletmeHizmet> isletmehizmetliste;
  late List<Personel> personelliste;
  late List<Cihaz>cihazliste;
  late List<Oda>odaliste;
  late List<MusteriDanisan> musteridanisanlar;
  bool isloading = true;

  TextEditingController personel = TextEditingController();

  List<Personel?> secilipersonel = [];
  List<Oda?>  secilioda= [];
  List<Cihaz?>  secilicihaz= [];
  List<IsletmeHizmet?>  secilihizmet= [];
  List<List<Personel?>> seciliyardimcipersonel = [];
  MusteriDanisan? secilimusteridanisan;



  bool tekrarlayanrandevu = false;

  bool _isAllDay = false;
  DateTime secilitarih = DateTime.now();
  DateTime secilisaat = DateTime.now();
  List<Color> _colorCollection = <Color>[];
  RandevuTekrarSikligi? secilitekrarsikligi;
  String? secilimusteridanisanid;
  String? secilimusteridanisanadi;

  List<RandevuHizmetYardimciPersonelleri> randevuhizmetyardimcipersoneller = [];
  TextEditingController randevutarihi = TextEditingController(text: "");
  TextEditingController randevusaati = TextEditingController(text: '');
  TextEditingController tekrarsayisi = TextEditingController(text: '1');
  TextEditingController notlar = TextEditingController(text: '');
  List<TextEditingController> suredk = [];
  List<TextEditingController> fiyat = [];
  List<TextEditingController> oda = [];
  List<TextEditingController> cihaz = [];
  List<TextEditingController> hizmet = [];

  TextEditingController musteridanisan = TextEditingController();


  final TextEditingController textEditingController = TextEditingController();

  bool formisvalid = true;
  late String seciliisletme;
  List<RandevuHizmet> randevuhizmetleri = [RandevuHizmet(hizmetler: null, hizmet_id: '', personel_id: '', personeller: null, oda_id: '', oda: null, cihaz_id: '', cihaz: null, fiyat: '', sure_dk: '', saat: '', saat_bitis: '', yardimci_personel: '', birusttekiileaynisaat: '')];



  List<RandevuTekrarSikligi> tekrarsikliklari = [
    RandevuTekrarSikligi(siklik_str: "+1 day", tekrar_sikligi: "Her Gün"),
    RandevuTekrarSikligi(siklik_str: "+2 days", tekrar_sikligi: "2 Günde Bir"),
    RandevuTekrarSikligi(siklik_str: "+3 days", tekrar_sikligi: "3 Günde Bir"),
    RandevuTekrarSikligi(siklik_str: "+4 days", tekrar_sikligi: "4 Günde Bir"),
    RandevuTekrarSikligi(siklik_str: "+5 days", tekrar_sikligi: "5 Günde Bir"),
    RandevuTekrarSikligi(siklik_str: "+6 days", tekrar_sikligi: "6 Günde Bir"),
    RandevuTekrarSikligi(siklik_str: "+1 week", tekrar_sikligi: "Haftada Bir"),
    RandevuTekrarSikligi(
        siklik_str: "+2 weeks", tekrar_sikligi: "2 Haftada Bir"),
    RandevuTekrarSikligi(
        siklik_str: "+3 weeks", tekrar_sikligi: "3 Haftada Bir"),
    RandevuTekrarSikligi(
        siklik_str: "+4 weeks", tekrar_sikligi: "4 Haftada Bir"),
    RandevuTekrarSikligi(siklik_str: "+1 month", tekrar_sikligi: "Her Ay"),
    RandevuTekrarSikligi(
        siklik_str: "+45 days", tekrar_sikligi: "45 Günde Bir"),
    RandevuTekrarSikligi(siklik_str: "+2 months", tekrar_sikligi: "2 Ayda Bir"),
    RandevuTekrarSikligi(siklik_str: "+3 months", tekrar_sikligi: "3 Ayda Bir"),
    RandevuTekrarSikligi(siklik_str: "+6 months", tekrar_sikligi: "6 Ayda Bir"),
  ];

  void initState() {
    super.initState();
    initialize();
  }

  Future<void> initialize() async {
    seciliisletme = (await secilisalonid())!;
    final isletmeVerileri = await isletmeVerileriGetir(seciliisletme,false,'','','',0,0);
    List <MusteriDanisan> musteridanisanliste = isletmeVerileri['musteriler'];
    List<IsletmeHizmet> isletmehizmetleriliste =  isletmeVerileri['hizmetler'];
    List<Personel> isletmepersonellerliste =  isletmeVerileri['personeller'];
    List<Cihaz>isletmecihazliste =  isletmeVerileri['cihazlar'];
    List<Oda>isletmeodaliste =  isletmeVerileri['odalar'];

    setState(() {
      final List<dynamic> hizmetdata = widget.randevu.hizmetler;
      randevuhizmetleri = hizmetdata.map((e) => RandevuHizmet.fromJson(e)).toList();
      secilimusteridanisanid = widget.randevu.user_id;
      secilimusteridanisanadi = widget.randevu.musteri["name"];

      randevutarihi.text = widget.randevu.tarih.split(' ')[0];
      randevusaati.text = widget.randevu.tarih.split(' ')[1];




      suredk.add(TextEditingController());
      fiyat.add(TextEditingController());
      oda.add(TextEditingController());
      cihaz.add(TextEditingController());
      hizmet.add(TextEditingController());
      secilipersonel.add(null);
      seciliyardimcipersonel.add([null]);
      secilihizmet.add(null);

      secilioda.add(null);

      secilicihaz.add(null);



      musteridanisanlar = musteridanisanliste;
      isletmehizmetliste = isletmehizmetleriliste;
      personelliste = isletmepersonellerliste;
      odaliste= isletmeodaliste;
      cihazliste = isletmecihazliste;
      if(widget.tarihsaat != ""){
        randevutarihi.text =
            DateFormat('yyyy-MM-dd').format(DateTime.parse(widget.tarihsaat));
        randevusaati.text =
            DateFormat('HH:mm').format(DateTime.parse(widget.tarihsaat));
      }

      isloading = false;
    });

  }

  Future<void> tarihsec(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(1950),
        //DateTime.now() - not to allow to choose before today.
        lastDate: DateTime(2100));

    if (pickedDate != null) {
      print(pickedDate); //pickedDate output format => 2021-03-10 00:00:00.000
      String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
      print(
          formattedDate); //formatted date output using intl package =>  2021-03-16
      setState(() {
        randevutarihi.text =
            formattedDate; //set output date to TextField value.
      });
    } else {}
  }

  Future<void> saatsec(BuildContext context) async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(secilisaat ?? DateTime.now()),
    );

    if (pickedTime != null) {
      print(
          formattedDate); //formatted date output using intl package =>  2021-03-16
      setState(() {
        String dakika = '0';
        if (pickedTime.minute < 10)
          dakika = '0' + pickedTime.minute.toString();
        else
          dakika = pickedTime.minute.toString();
        randevusaati.text = pickedTime.hour.toString() + ':' + dakika;
      });
    } else {}
  }



  Widget _getAppointmentEditor(BuildContext context) {
    final double columnWidth = MediaQuery.of(context).size.width / 2 - 20;

    final screenHeight = MediaQuery.of(context).size.height;
    return
      isloading ?  Center(child: CircularProgressIndicator(),) :  GestureDetector(
          onTap: () {
            // Unfocus the current text field, dismissing the keyboard
            FocusScope.of(context).unfocus();
          },
          child: Container(
              height: screenHeight,
              color: Colors.white,
              child: ListView(
                padding: const EdgeInsets.all(0),
                children: <Widget>[
                  DropdownButtonHideUnderline(

                      child: DropdownButton2<MusteriDanisan>(

                        isExpanded: true,
                        hint: Text(
                          'Müşteri Seç',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).hintColor,

                          ),
                        ),
                        items: musteridanisanlar
                            .map((item) => DropdownMenuItem(
                          value: item,
                          child: Text(
                            item.name,
                            style: const TextStyle(
                              fontSize: 14,
                            ),
                          ),
                        ))
                            .toList(),
                        value: secilimusteridanisan,
                        onChanged: (value) async {
                          setState(() {
                            secilimusteridanisan = value!;
                            secilimusteridanisanid = value.id;
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
                          searchController: textEditingController,
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
                              controller: textEditingController,
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                hintText: 'Müşteri Ara..',
                                hintStyle: const TextStyle(fontSize: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          searchMatchFn: (item, searchValue) {
                            return  item.value!.name.toLowerCase().contains(searchValue.toLowerCase());
                          },
                        ),
                        //This to clear the search value when you close the menu
                        onMenuStateChange: (isOpen) {
                          if (!isOpen) {
                            textEditingController.clear();
                          }
                        },

                      )),
                  /*ListTile(
                  contentPadding: const EdgeInsets.fromLTRB(5, 0, 5, 5),
                  leading: const Icon(Icons.supervised_user_circle_sharp),
                  title: Text('Müşteri/Danışan'),
                  trailing: secilimusteridanisanadia != null
                      ? Text(secilimusteridanisanadi!)
                      : Icon(Icons.keyboard_arrow_right),
                  onTap: () => musteridanisansec(),
                ),
                const Divider(
                  height: 1.0,
                  thickness: 1,
                ),*/

                  Row(
                      children:[
                        Expanded(
                          child: ListTile(

                            contentPadding: const EdgeInsets.fromLTRB(5, 2, 5, 2),
                            leading: const Icon(Icons.calendar_today),
                            title: Text('Tarih'),
                            trailing: randevutarihi.text != ''
                                ? Text(randevutarihi.text)
                                : Icon(Icons.keyboard_arrow_right),
                            onTap: () => tarihsec(context),
                          ),
                        ),
                        SizedBox(width: 8), // Expandedlar arası boşluk
// Dikey çizgi
                        Container(
                          height: 40, // çizgi yüksekliği, ListTile yüksekliğine göre ayarla
                          width: 2, // çizgi kalınlığı
                          color: Colors.grey, // istediğin renk
                        ),
                        SizedBox(width: 8), // Expandedlar arası boşluk
                        Expanded(
                          child:ListTile(
                            contentPadding: const EdgeInsets.fromLTRB(5, 2, 5, 2),
                            leading: const Icon(Icons.watch_later_outlined),
                            title: Text('Saat'),
                            trailing: randevusaati.text != ''
                                ? Text(randevusaati.text)
                                : Icon(Icons.keyboard_arrow_right),
                            onTap: () => saatsec(context),
                          ),
                        )

                      ]
                  ),



                  const Divider(
                    height: 1.0,
                    thickness: 1,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 0.0), // dikey padding azaltıldı
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center, // dikey ortala
                      children: [
                        Text(
                          'Detaylar',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        TextButton(
                          onPressed: () {
                            setState(() {
                              suredk.add(TextEditingController());
                              fiyat.add(TextEditingController());

                              oda.add(TextEditingController());
                              cihaz.add(TextEditingController());
                              hizmet.add(TextEditingController());
                              secilipersonel.add(null);
                              seciliyardimcipersonel.add([null]);
                              secilihizmet.add(null);

                              secilioda.add(null);

                              secilicihaz.add(null);
                              randevuhizmetleri.add(RandevuHizmet(
                                hizmetler: null,
                                hizmet_id: '',
                                personel_id: '',
                                personeller: null,
                                oda_id: '',
                                oda: null,
                                cihaz_id: '',
                                cihaz: null,
                                fiyat: '',
                                sure_dk: '',
                                saat: '',
                                saat_bitis: '',
                                yardimci_personel: '',
                                birusttekiileaynisaat: '',
                              ));

                            });
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size(0, 30),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Hizmet Ekle",
                                style: TextStyle(fontSize: 12, color: Colors.green),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.add, size: 30, color: Colors.green),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  SizedBox(height: 5),
                  ...List.generate(randevuhizmetleri.length, (index) {
                    final set = randevuhizmetleri[index];
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 3),
                      child: Padding(
                        padding: const EdgeInsets.all(5),
                        child: Column(
                          children: [
                            widget.isletmebilgi["randevu_takvim_turu"] >= 0 ?
                            Row(
                              children: [
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children:[
                                          Text(
                                            'Personel',
                                            style: TextStyle( fontSize: 11),
                                          ),
                                          SizedBox(height:5),
                                          Container(
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
                                                  value: secilipersonel[index],
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
                                                      secilipersonel[index] = value!;
                                                      randevuhizmetleri[index].personel_id = value.id;

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

                                        ]
                                    )


                                ),
                                SizedBox(width: 10), // İki alan arası boşluk

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Yardımcı Personel(-ler)',
                                        style: TextStyle(fontSize: 11),
                                      ),
                                      SizedBox(height: 5),
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
                                          child: DropdownButton2<Personel>(
                                            isExpanded: true,
                                            customButton: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 16),
                                              alignment: Alignment.centerLeft,
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      seciliyardimcipersonel[index]
                                                          .whereType<Personel>()
                                                          .map((e) => e.personel_adi)
                                                          .join(', ')
                                                          .trim()
                                                          .isNotEmpty
                                                          ? seciliyardimcipersonel[index]
                                                          .whereType<Personel>()
                                                          .map((e) => e.personel_adi)
                                                          .join(', ')
                                                          : 'Yardımcı Personel(-ler)i Seç',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: seciliyardimcipersonel[index]
                                                            .whereType<Personel>()
                                                            .isEmpty
                                                            ? Theme.of(context).hintColor
                                                            : Colors.black,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                      maxLines: 1,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            value: null,
                                            onChanged: (_) {},
                                            items: personelliste.map((item) {
                                              return DropdownMenuItem<Personel>(
                                                value: item,
                                                child: StatefulBuilder(
                                                  builder: (context, menuSetState) {
                                                    final isSelected =
                                                    seciliyardimcipersonel[index].contains(item);
                                                    return InkWell(
                                                      onTap: () {
                                                        setState(() {
                                                          if (isSelected) {
                                                            seciliyardimcipersonel[index].remove(item);
                                                            randevuhizmetyardimcipersoneller.removeWhere((element){return element.index == index  && element.yardimcipersonel['id'].toString() == item.id.toString();});
                                                          } else {
                                                            seciliyardimcipersonel[index].add(item);
                                                            randevuhizmetyardimcipersoneller.add(new RandevuHizmetYardimciPersonelleri('',item.toJson(),index.toString()));

                                                          }
                                                        });
                                                        menuSetState(() {});
                                                      },
                                                      child: Container(
                                                        padding:
                                                        const EdgeInsets.symmetric(horizontal: 8.0),
                                                        child: Row(
                                                          children: [
                                                            Icon(
                                                              isSelected
                                                                  ? Icons.check_box
                                                                  : Icons.check_box_outline_blank,
                                                              color: isSelected ? Colors.blue : null,
                                                            ),
                                                            const SizedBox(width: 8),
                                                            Flexible(
                                                              child: Text(
                                                                item.personel_adi,
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
                                            buttonStyleData: const ButtonStyleData(
                                              height: 40,
                                              padding: EdgeInsets.symmetric(horizontal: 0),
                                            ),
                                            dropdownStyleData: const DropdownStyleData(
                                              maxHeight: 400,
                                              width: null,
                                            ),
                                            menuItemStyleData: const MenuItemStyleData(
                                              height: 40,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              ],
                            ) : SizedBox(),
                            SizedBox(height: 5),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                if (widget.isletmebilgi["randevu_takvim_turu"] == 2)
                                  SizedBox(
                                    width: columnWidth,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Cihaz', style: TextStyle(fontSize: 11)),
                                        SizedBox(height: 5),
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
                                            child: DropdownButton2<Cihaz>(
                                              isExpanded: true,
                                              hint: Text('Cihaz Seçin', style: TextStyle(fontSize: 14, color: Theme.of(context).hintColor)),
                                              items: cihazliste.map((item) => DropdownMenuItem(
                                                value: item,
                                                child: Text(item.cihaz_adi, style: TextStyle(fontSize: 14)),
                                              )).toList(),
                                              value: secilicihaz[index],
                                              onChanged: (value) {
                                                setState(() {
                                                  secilicihaz[index] = value!;
                                                  randevuhizmetleri[index].cihaz_id = value.id;

                                                });
                                              },

                                              buttonStyleData: ButtonStyleData(padding: EdgeInsets.symmetric(horizontal: 16), height: 50, width: 400),
                                              dropdownStyleData: DropdownStyleData(maxHeight: 400),
                                              menuItemStyleData: MenuItemStyleData(height: 40),
                                              dropdownSearchData: DropdownSearchData(
                                                searchController: cihaz[index],
                                                searchInnerWidgetHeight: 50,
                                                searchInnerWidget: Container(
                                                  height: 50,
                                                  padding: EdgeInsets.all(8),
                                                  child: TextFormField(
                                                    expands: true,
                                                    maxLines: null,
                                                    controller: cihaz[index],
                                                    decoration: InputDecoration(
                                                      isDense: true,
                                                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                      hintText: 'Cihaz Ara..',
                                                      hintStyle: TextStyle(fontSize: 12),
                                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                                    ),
                                                  ),
                                                ),
                                                searchMatchFn: (item, searchValue) => item.value!.cihaz_adi.toLowerCase().contains(searchValue.toLowerCase()),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                if (widget.isletmebilgi["randevu_takvim_turu"] == 3)
                                  SizedBox(
                                    width: columnWidth,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Oda', style: TextStyle(fontSize: 11)),
                                        SizedBox(height: 5),
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
                                            child: DropdownButton2<Oda>(
                                              isExpanded: true,
                                              hint: Text('Oda Seçin', style: TextStyle(fontSize: 14, color: Theme.of(context).hintColor)),
                                              items: odaliste.map((item) => DropdownMenuItem(
                                                value: item,
                                                child: Text(item.oda_adi, style: TextStyle(fontSize: 14)),
                                              )).toList(),
                                              value: secilioda?[index],
                                              onChanged: (value) {
                                                setState(() {
                                                  secilioda[index] = value!;
                                                  randevuhizmetleri[index].oda_id = value.id;

                                                });
                                              },
                                              buttonStyleData: ButtonStyleData(padding: EdgeInsets.symmetric(horizontal: 10), height: 50, width: 400),
                                              dropdownStyleData: DropdownStyleData(maxHeight: 400),
                                              menuItemStyleData: MenuItemStyleData(height: 40),
                                              dropdownSearchData: DropdownSearchData(
                                                searchController: oda[index],
                                                searchInnerWidgetHeight: 50,
                                                searchInnerWidget: Container(
                                                  height: 50,
                                                  padding: EdgeInsets.all(8),
                                                  child: TextFormField(
                                                    expands: true,
                                                    maxLines: null,
                                                    controller: oda[index],
                                                    decoration: InputDecoration(
                                                      isDense: true,
                                                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                      hintText: 'Oda Ara..',
                                                      hintStyle: TextStyle(fontSize: 12),
                                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                                    ),
                                                  ),
                                                ),
                                                searchMatchFn: (item, searchValue) => item.value!.oda_adi.toLowerCase().contains(searchValue.toLowerCase()),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                // Hizmet
                                SizedBox(
                                  width: columnWidth,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Hizmet', style: TextStyle(fontSize: 11)),
                                      SizedBox(height: 5),
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
                                            hint: Text('Hizmet Seç', style: TextStyle(fontSize: 14, color: Theme.of(context).hintColor)),
                                            items: isletmehizmetliste.map((item) => DropdownMenuItem(
                                              value: item,
                                              child: Text(item.hizmet['hizmet_adi'], style: TextStyle(fontSize: 14)),
                                            )).toList(),
                                            value: secilihizmet[index],
                                            onChanged: (value) {
                                              setState(() {
                                                secilihizmet[index] = value!;
                                                randevuhizmetleri[index].hizmet_id = value.hizmet_id;
                                                suredk[index].text = value!.sure;
                                                fiyat[index].text = value.fiyat;
                                                randevuhizmetleri[index].sure_dk = value.sure;
                                                randevuhizmetleri[index].fiyat = value.fiyat;
                                              });
                                            },
                                            buttonStyleData: ButtonStyleData(padding: EdgeInsets.symmetric(horizontal: 10), height: 50, width: 400),
                                            dropdownStyleData: DropdownStyleData(maxHeight: 400),
                                            menuItemStyleData: MenuItemStyleData(height: 40),
                                            dropdownSearchData: DropdownSearchData(
                                              searchController: hizmet[index],
                                              searchInnerWidgetHeight: 50,
                                              searchInnerWidget: Container(
                                                height: 50,
                                                padding: EdgeInsets.all(8),
                                                child: TextFormField(
                                                  expands: true,
                                                  maxLines: null,
                                                  controller: hizmet[index],
                                                  decoration: InputDecoration(
                                                    isDense: true,
                                                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                    hintText: 'Hizmet Ara..',
                                                    hintStyle: TextStyle(fontSize: 12),
                                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                                  ),
                                                ),
                                              ),
                                              searchMatchFn: (item, searchValue) => item.value!.hizmet["hizmet_adi"].toString().toLowerCase().contains(searchValue.toLowerCase()),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Süre
                                SizedBox(
                                  width: columnWidth,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Süre (dk)', style: TextStyle(fontSize: 11)),
                                      SizedBox(height: 5),
                                      Container(
                                        alignment: Alignment.center,
                                        height: 40,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          border: Border.all(color: Color(0xFF6A1B9A)),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: TextFormField(
                                          controller: suredk[index],
                                          keyboardType: TextInputType.phone,
                                          onSaved: (value) {
                                            suredk[index].text = value!;
                                            randevuhizmetleri[index].sure_dk = value;

                                          },
                                          decoration: InputDecoration(
                                            border: InputBorder.none, //
                                            contentPadding: EdgeInsets.all(15.0),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Fiyat
                                SizedBox(
                                  width: columnWidth,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Fiyat (₺)', style: TextStyle(fontSize: 11)),
                                      SizedBox(height: 5),
                                      Container(
                                        alignment: Alignment.center,
                                        height: 40,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          border: Border.all(color: Color(0xFF6A1B9A)),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: TextFormField(
                                          controller: fiyat[index],
                                          keyboardType: TextInputType.phone,
                                          onSaved: (value) {
                                            fiyat[index].text = value!;
                                            randevuhizmetleri[index].fiyat=value;

                                          },
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.all(15.0),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (randevuhizmetleri.length > 1)
                                  IconButton(
                                    icon: Icon(Icons.remove_circle, color: Colors.red),
                                    onPressed: () => setState(() => randevuhizmetleri.removeAt(index)),
                                  )
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  }),
                  /*OutlinedButton.icon(
                 onPressed: () {
                  setState(() {
                randevuhizmetleri.add(RandevuHizmet(hizmetler: null, hizmet_id: '', personel_id: '', personeller: null, oda_id: '', oda: null, cihaz_id: '', cihaz: null, fiyat: '', sure_dk: '', saat: '', saat_bitis: '', yardimci_personel: '', birusttekiileaynisaat: ''

                      ));
                    });
                  },
                  icon: Icon(Icons.add),
                  label: Text("Bir Hizmet Daha Ekle"),
                ),*/


                  const Divider(
                    height: 1.0,
                    thickness: 1,
                  ),


                  ListTile(
                      contentPadding: const EdgeInsets.fromLTRB(5, 2, 5, 2),
                      leading: const Icon(
                        Icons.cached_rounded,
                        color: Colors.black54,
                      ),
                      title: Row(children: <Widget>[
                        const Expanded(
                          child: Text('Tekrarlayan'),
                        ),
                        Expanded(
                            child: Align(
                                alignment: Alignment.centerRight,
                                child: Switch(
                                  value: tekrarlayanrandevu,
                                  activeColor: Colors.deepPurple,
                                  onChanged: (bool value) {
                                    setState(() {
                                      tekrarlayanrandevu = value;
                                    });
                                  },
                                ))),
                      ])),
                  const Divider(
                    height: 1.0,
                    thickness: 1,
                  ),
                  tekrarlayanrandevu
                      ? Row(
                    children: <Widget>[
                      // First Column
                      Expanded(
                        child: Column(
                          children: <Widget>[
                            Container(
                              height: 20,
                              margin: EdgeInsets.all(8.0),
                              child: Text(
                                'Tekrar Sıklığı',
                                style:
                                TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Container(
                              height: 50,
                              margin: EdgeInsets.all(8.0),
                              child: Container(
                                alignment: Alignment.center,
                                height: 40,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border:
                                  Border.all(color: Color(0xFF6A1B9A)),
                                  borderRadius: BorderRadius.circular(
                                      10), //border corner radius

                                  //you can set more BoxShadow() here
                                ),
                                child: DropdownButtonHideUnderline(
                                    child: DropdownButton2<
                                        RandevuTekrarSikligi>(
                                      isExpanded: true,
                                      hint: Text(
                                        'Tekrar Sıklığı Seç',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Theme.of(context).hintColor,
                                        ),
                                      ),
                                      value: secilitekrarsikligi,
                                      items: tekrarsikliklari
                                          .map((item) => DropdownMenuItem(
                                        value: item,
                                        child: Text(
                                          item.tekrar_sikligi,
                                          style: const TextStyle(
                                            fontSize: 14,
                                          ),
                                        ),
                                      ))
                                          .toList(),

                                      onChanged: (value) {
                                        setState(() {
                                          secilitekrarsikligi = value;
                                        });
                                      },
                                      buttonStyleData: const ButtonStyleData(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 16),
                                        height: 50,
                                        width: 400,
                                      ),

                                      dropdownStyleData:
                                      const DropdownStyleData(
                                        maxHeight: 400,
                                      ),
                                      menuItemStyleData:
                                      const MenuItemStyleData(
                                        height: 40,
                                      ),

                                      //This to clear the search value when you close the menu
                                      onMenuStateChange: (isOpen) {
                                        if (!isOpen) {}
                                      },
                                    )),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Second Column
                      Expanded(
                        child: Column(
                          children: <Widget>[
                            Container(
                              height: 20,
                              margin: EdgeInsets.all(8.0),
                              child: Text(
                                'Tekrar Sayısı',
                                style:
                                TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Container(
                                height: 50,
                                margin: EdgeInsets.all(8.0),
                                child: TextFormField(
                                  onSaved: (value) {
                                    tekrarsayisi.text = value!;
                                  },
                                  keyboardType: TextInputType.phone,
                                  controller: tekrarsayisi,
                                  decoration: InputDecoration(
                                    contentPadding: EdgeInsets.all(15.0),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: Color(0xFF6A1B9A)),
                                      borderRadius:
                                      BorderRadius.circular(10.0),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius:
                                      BorderRadius.circular(10.0),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Color(0xFF6A1B9A),
                                      ),
                                      borderRadius:
                                      BorderRadius.circular(10.0),
                                    ),
                                  ),
                                ))
                          ],
                        ),
                      ),
                    ],
                  )
                      : Padding(
                    padding: const EdgeInsets.all(0),
                  ),
                  tekrarlayanrandevu
                      ? const Divider(
                    height: 1.0,
                    thickness: 1,
                  )
                      : Padding(
                    padding: const EdgeInsets.all(0),
                  ),
                  const Divider(
                    height: 1.0,
                    thickness: 1,
                  ),
                  ListTile(
                    contentPadding: const EdgeInsets.all(5),
                    leading: const Icon(
                      Icons.subject,
                      color: Colors.black87,
                    ),
                    title: TextFormField(
                      controller: notlar,
                      onSaved: (value) {
                        notlar.text = value!;
                      },
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      style: const TextStyle(
                          fontSize: 18,
                          color: Colors.black87,
                          fontWeight: FontWeight.w400),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Notlar',
                      ),
                    ),
                  ),
                  const Divider(
                    height: 1.0,
                    thickness: 1,
                  ),
                ],
              )));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          bottomNavigationBar: Container(
            height: 65,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.mainBg,
            ),
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  formisvalid = true;
                  String uyari =
                      'Randevuyu oluşturmadan önce gerekli alanları eksiksiz doldurunuz.\n';

                  if (!isNumeric(secilimusteridanisanid.toString())) {
                    uyari += '\nLütfen müşteri/ danışan seçiniz.';
                    formisvalid = false;
                  }
                  if (randevutarihi.text == '') {
                    uyari += '\nLütfen randevu tarihini seçiniz.';
                    formisvalid = false;
                  }
                  if (randevusaati.text == '') {
                    uyari += '\nLütfen randevu saatini seçiniz.';
                    formisvalid = false;
                  }
                  if (tekrarlayanrandevu) {
                    if (secilitekrarsikligi == null) {
                      uyari += '\nLütfen randevu tekrar sıklığını seçiniz.';
                      formisvalid = false;
                    }
                    if (tekrarsayisi.text == '') {
                      uyari += '\nLütfen randevu tekrar sayısını giriniz.';
                      formisvalid = false;
                    }
                  }
                  bool himzetSeciliDegil = secilihizmet.any((element) => element == null);
                  bool personelSeciliDegil = secilipersonel.any((element) => element == null);
                  bool cihazSeciliDegil = secilicihaz.any((element) => element == null);
                  bool odaSeciliDegil = secilicihaz.any((element) => element == null);
                  if (widget.isletmebilgi["randevu_takvim_turu"] == 1)
                  {
                    if(personelSeciliDegil) {
                      formisvalid = false;
                      uyari += '\nLütfen personel seçiniz.';
                    }
                  }

                  if (widget.isletmebilgi["randevu_takvim_turu"] == 2)
                  {
                    if(cihazSeciliDegil){
                      formisvalid = false;
                      uyari += '\nLütfen cihaz seçiniz.';
                    }

                  }
                  if (widget.isletmebilgi["randevu_takvim_turu"] == 3)
                  {
                    if(odaSeciliDegil){
                      formisvalid = false;
                      uyari += '\nLütfen oda seçiniz.';
                    }
                  }
                  if(himzetSeciliDegil) {
                    formisvalid = false;
                    uyari += '\nLütfen hizmet seçiniz.';
                  }



                  if (formisvalid == false)
                    formWarningDialogs(context, 'UYARI', uyari);
                  else {
                    debugPrint('seçili danışan '+secilimusteridanisanid!);
                    debugPrint('tarih '+randevutarihi.text!);
                    debugPrint('saat '+randevusaati.text!);
                    randevuhizmetleri.forEach((element){
                      debugPrint('hizmet id : '+element.hizmet_id);
                      debugPrint('personel id : '+element.personel_id);
                      debugPrint('cihaz id : '+element.cihaz_id);
                      debugPrint('oda id : '+element.oda_id);
                    });
                    randevuhizmetyardimcipersoneller.forEach((element){
                      debugPrint('Yardımcı personel for index : '+element.index);
                      debugPrint('Yardımcı personel id : '+element.yardimcipersonel['id']);
                      debugPrint('Yardımcı personel hizmet : '+element.randevuhizmetid);
                    });
                    randevuEkleGuncelle(
                        '',
                        '',
                        '',
                        secilimusteridanisan!,
                        randevutarihi.text,
                        randevusaati.text,
                        randevuhizmetleri,
                        randevuhizmetyardimcipersoneller,
                        tekrarlayanrandevu,
                        tekrarsayisi.text,
                        secilitekrarsikligi?.siklik_str,
                        notlar.text,
                        seciliisletme.toString(),
                        context,
                      'salon',
                      '1',

                    );
                  }
                });
              },
              child: Text('RANDEVUYU OLUŞTUR'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.green,
                minimumSize: Size(90, 40),
              ),
            ),
          ),
          appBar: new AppBar(
            title: const Text(
              'Yeni Randevu',
              style: TextStyle(color: Colors.black),
            ),
            backgroundColor: Colors.white,
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
                      child: YukseltButonu(isletme_bilgi: widget.isletmebilgi,)),
                ),
            ],
            toolbarHeight: 60,
          ),
          body: Padding(
            padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
            child: Stack(
              children: <Widget>[_getAppointmentEditor(context)],
            ),
          ),
        ));
  }

  bool isNumeric(String str) {
    if (str == null) {
      return false;
    }
    return int.tryParse(str) != null || double.tryParse(str) != null;
  }

  String getTitle() {
    return 'Yeni Randevu';
  }

  String getYardimciPersonel(String hizmetid) {
    String yardimcipersoneller = '';
    int index = 0;
    randevuhizmetyardimcipersoneller.forEach((element) {
      ++index;
      if (element.randevuhizmetid == hizmetid)
        yardimcipersoneller += element.yardimcipersonel['personel_adi'];
      if (index != randevuhizmetyardimcipersoneller.length)
        yardimcipersoneller += ', ';
    });
    return yardimcipersoneller;
  }
}

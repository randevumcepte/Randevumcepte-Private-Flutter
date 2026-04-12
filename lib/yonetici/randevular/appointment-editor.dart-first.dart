import 'dart:ui';

import 'package:dropdown_button2/dropdown_button2.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';

import '../../Backend/backend.dart';
import '../../Frontend/datetimeformatting.dart';
import '../../Frontend/popupdialogs.dart';

import '../../Models/randevuhizmetleri.dart';
import '../../Models/randevuhizmetyardimcipersonelleri.dart';

import '../../Models/randevutekrarsikligi.dart';
import '../../yeni/app_colors.dart';
import 'hizmet_add.dart';
import 'package:randevu_sistem/yonetici/randevular/musteri.dart';

class AppointmentEditor extends StatefulWidget {
  final dynamic isletmebilgi;
  final String tarihsaat;
  final String personel_id;
  final int kullanicirolu;

  const AppointmentEditor(
      {super.key,
        required this.kullanicirolu,
      required this.isletmebilgi,
      required this.tarihsaat,
      required this.personel_id});

  @override
  AppointmentEditorState createState() => AppointmentEditorState();
}

class AppointmentEditorState extends State<AppointmentEditor> {
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

  bool formisvalid = true;
  late String seciliislemte;
  List<RandevuHizmet> randevuhizmetleri = [];
  RandevuHizmet? secilihizmet;
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
    seciliislemte = (await secilisalonid())!;
    if (widget.tarihsaat != "") {
      setState(() {
        randevutarihi.text =
            DateFormat('yyyy-MM-dd').format(DateTime.parse(widget.tarihsaat));
        randevusaati.text =
            DateFormat('HH:mm').format(DateTime.parse(widget.tarihsaat));
      });
    }
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

  void musteridanisansec() async {
    final selectedItem = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Musteri (kullanicirolu: widget.kullanicirolu, isletmebilgi: widget.isletmebilgi),
      ),
    );

    if (selectedItem != null) {
      setState(() {
        secilimusteridanisanid = selectedItem.id;
        secilimusteridanisanadi = selectedItem.name;
      });
    }
  }

  void hizmetsec(RandevuHizmet? editlenecek) async {
    final List<RandevuHizmet> selectedItems = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => HizmetAdd(
                  secilihizmetler: randevuhizmetleri,
                  personel_id: "",
                  duzenlenecek: editlenecek,
                )));
    if (selectedItems != null) {
      setState(() {
        selectedItems.forEach((element) {
          if (editlenecek != null)
            randevuhizmetleri.removeAt(randevuhizmetleri.indexOf(editlenecek));
          if (element.yardimci_personel != '1') {
            randevuhizmetleri.add(element);
            //randevuhizmetyardimcipersoneller?.add(Personel(cinsiyet: '',id: '',takvim_sirasi: '',cep_telefon: '',dahili_no: '',hizmet_prim_yuzde: '',maas: '',paket_prim_yuzde: '',personel_adi: '',profil_resmi: '',renk: '',salon_id: '',takvimde_gorunsun: '',unvan: '',urun_prim_yuzde: ''));
          } else
            randevuhizmetyardimcipersoneller.add(
                RandevuHizmetYardimciPersonelleri(
                    element.hizmet_id, element.personeller,''));
        });
      });
    }
  }

  Widget _getAppointmentEditor(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
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
                ListTile(
                  contentPadding: const EdgeInsets.fromLTRB(5, 0, 5, 5),
                  leading: const Icon(Icons.supervised_user_circle_sharp),
                  title: Text('Müşteri/Danışan'),
                  trailing: secilimusteridanisanadi != null
                      ? Text(secilimusteridanisanadi!)
                      : Icon(Icons.keyboard_arrow_right),
                  onTap: () => musteridanisansec(),
                ),
                const Divider(
                  height: 1.0,
                  thickness: 1,
                ),
                ListTile(
                  contentPadding: const EdgeInsets.fromLTRB(5, 2, 5, 2),
                  leading: const Icon(Icons.calendar_today),
                  title: Text('Tarih'),
                  trailing: randevutarihi.text != ''
                      ? Text(randevutarihi.text)
                      : Icon(Icons.keyboard_arrow_right),
                  onTap: () => tarihsec(context),
                ),
                const Divider(
                  height: 1.0,
                  thickness: 1,
                ),
                ListTile(
                  contentPadding: const EdgeInsets.fromLTRB(5, 2, 5, 2),
                  leading: const Icon(Icons.watch_later_outlined),
                  title: Text('Saat'),
                  trailing: randevusaati.text != ''
                      ? Text(randevusaati.text)
                      : Icon(Icons.keyboard_arrow_right),
                  onTap: () => saatsec(context),
                ),
                const Divider(
                  height: 1.0,
                  thickness: 1,
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Text(
                    'Hizmetler',
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 5),
                randevuhizmetleri.length == 0
                    ? Padding(
                        padding: const EdgeInsets.only(left: 20.0, bottom: 10),
                        child: Text(
                          'Hizmet seçilmedi',
                          style: TextStyle(
                              color: Colors.red[600],
                              fontWeight: FontWeight.bold),
                        ),
                      )
                    : ListView.builder(
                        scrollDirection: Axis.vertical,
                        shrinkWrap: true,
                        itemCount: randevuhizmetleri.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              hizmetsec(randevuhizmetleri[index]);
                            },
                            child: Dismissible(
                                dismissThresholds: {
                                  DismissDirection.startToEnd: 0.5,
                                  DismissDirection.endToStart: 0.5
                                },
                                direction: DismissDirection.endToStart,
                                key: Key(randevuhizmetleri[index]
                                    .hizmetler["hizmet_adi"]),
                                background: Container(
                                  color: Colors.green,
                                  alignment: Alignment.centerLeft,
                                  padding: EdgeInsets.only(left: 20),
                                  child: Icon(Icons.edit, color: Colors.white),
                                ),
                                secondaryBackground: Container(
                                  color: Colors.red,
                                  alignment: Alignment.centerRight,
                                  padding: EdgeInsets.only(right: 20),
                                  child:
                                      Icon(Icons.delete, color: Colors.white),
                                ),
                                onDismissed: (direction) {
                                  setState(() {
                                    // Perform action for swipe to left (e.g., delete)
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                '${randevuhizmetleri[index].hizmetler["hizmet_adi"]} kaldırıldı')));
                                    randevuhizmetleri.removeAt(index);
                                  });
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                          color: Colors.grey, width: 1.0),
                                    ),
                                  ),
                                  child: ListTile(
                                    title: Text(randevuhizmetleri[index]
                                            .hizmetler["hizmet_adi"] +
                                        " (" +
                                        randevuhizmetleri[index]
                                            .personeller["personel_adi"]
                                            .toString() +
                                        ")"),
                                    subtitle: Text(
                                        'Yardımcı Personel(-ler) : ' +
                                            (getYardimciPersonel(
                                                        randevuhizmetleri[index]
                                                            .hizmetler["id"]
                                                            .toString()) !=
                                                    ''
                                                ? getYardimciPersonel(
                                                    randevuhizmetleri[index]
                                                        .hizmetler["id"]
                                                        .toString())
                                                : 'Seçilmedi') +
                                            ' Cihaz : ' +
                                            (isNumeric(randevuhizmetleri[index]
                                                    .cihaz_id!)
                                                ? randevuhizmetleri[index]
                                                    .cihaz["cihaz_adi"]
                                                : 'Seçilmedi') +
                                            " Oda : " +
                                            (isNumeric(randevuhizmetleri[index]
                                                    .oda_id!)
                                                ? randevuhizmetleri[index]
                                                    .oda["oda_adi"]
                                                : 'Seçilmedi')),
                                    trailing: Text('Süre : ' +
                                        randevuhizmetleri[index]
                                            .sure_dk
                                            .toString() +
                                        " dk\nFiyat : " +
                                        randevuhizmetleri[index]
                                            .fiyat
                                            .toString() +
                                        " ₺"),
                                  ),
                                )),
                          );
                        }),
                const Divider(
                  height: 1.0,
                  thickness: 1,
                ),
                ListTile(
                  contentPadding: const EdgeInsets.fromLTRB(5, 0, 5, 5),
                  leading: const Icon(Icons.add_task_sharp),
                  title: Text('Hizmet Ekle'),
                  trailing: Icon(Icons.add),
                  onTap: () => hizmetsec(secilihizmet),
                ),
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
                  if (randevuhizmetleri.length == 0) {
                    uyari += '\nLütfen en az 1 hizmet seçiniz.';
                    formisvalid = false;
                  }
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

                    /*randevuEkleGuncelle(
                        '',
                        '',
                        '',
                        secilimusteridanisanid!,
                        randevutarihi.text,
                        randevusaati.text,
                        randevuhizmetleri,
                        randevuhizmetyardimcipersoneller,
                        tekrarlayanrandevu,
                        tekrarsayisi.text,
                        secilitekrarsikligi?.siklik_str,
                        notlar.text,
                        seciliislemte.toString(),
                        context);*/
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

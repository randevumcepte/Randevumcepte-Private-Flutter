import 'dart:convert';
import 'dart:developer';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:randevu_sistem/Models/takvimturu.dart';
import 'package:randevu_sistem/yonetici/diger/diger_page.dart';
import 'package:randevu_sistem/yonetici/randevular/randevu_page.dart';
import 'package:randevu_sistem/yonetici/randevular/randevuduzenle.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:syncfusion_localizations/syncfusion_localizations.dart';
import 'package:syncfusion_flutter_core/core.dart';
import 'package:randevu_sistem/Models/randevular.dart';

import '../../Backend/backend.dart';
import '../../Frontend/indexedstack.dart';

import '../../Frontend/popupdialogs.dart';
import '../../Frontend/sfdatatable.dart';
import '../../Models/ongorusmeler.dart';
import '../../Models/personel.dart';
import '../../Models/user.dart';
import '../../yukselt.dart';
import '../adisyonlar/satislar/tahsilat.dart';
import '../diger/menu/randvular/randevularmenu.dart';
import 'appointment-editor.dart';



class Takvim extends StatefulWidget {
  final int selectedTab;
  final dynamic isletmebilgi;
  final Kullanici kullanici;
  final int kullanicirolu;
  Takvim({Key? key, required this.kullanici, required this.selectedTab,required this.isletmebilgi, required this.kullanicirolu}) : super(key: key);

  @override
  TakvimState createState() => TakvimState();
}

class TakvimState extends State<Takvim> {
  DateTime _selectedDate = DateTime.now();
  final CalendarController _calendarController = CalendarController();
  DateTime seciliTarih = DateTime.now();
  late PersonelDataSource _personelDataGridSource;
  List<Randevu> randevuliste = [];
  List<Personel> personelliste = [];

  bool isloading = true;
  TakvimTuru? selectedTakvimTuru;
  TextEditingController takvimTuruText = TextEditingController();
  final List<TakvimTuru> takvimTuru = [
    TakvimTuru(id: '1', takvim_turu: 'Personele Göre'),
    TakvimTuru(id: '0', takvim_turu: 'Hizmete Göre'),
    TakvimTuru(id: '2', takvim_turu: 'Cihaza Göre'),
    TakvimTuru(id: '3', takvim_turu: 'Odaya Göre'),

  ];
  @override
  void initState() {
    super.initState();
    selectedTakvimTuru = takvimTuru.firstWhere((element)=> element.id == widget.isletmebilgi["randevu_takvim_turu"].toString());
    getUpdatedAppointments(DateFormat('yyyy-MM-dd').format(seciliTarih), DateFormat('yyyy-MM-dd').format(seciliTarih),false);


  }
  AppointmentDataSource _appointmentDataSource = AppointmentDataSource([], []);
  Future<void> getUpdatedAppointments(String tarih1, String tarih2,bool yukleniyor) async {

    String personelid = "";


    if(widget.kullanicirolu == 5)
    {
      widget.kullanici.yetkili_olunan_isletmeler.forEach((element) {
        log("salon id : "+widget.isletmebilgi["id"].toString());
        if(element["salon_id"].toString()==widget.isletmebilgi["id"].toString())
          personelid = element["id"].toString();
      });
    }
    log('randevular yükleniyor');
    final randevudata = await fetchRandevular( widget.isletmebilgi["id"].toString(),personelid,tarih1,tarih2,yukleniyor,context,selectedTakvimTuru?.id??"");
    log('veriler aktarılıyor');
    List<dynamic> randevular = randevudata["randevular"];
    List<dynamic> personeller = randevudata["personeller"];
    List<dynamic> takvimpersoneller = randevudata["resources"];

    List<dynamic> randevulisteleri = randevudata["randevular_liste"];

    List<Appointment> updatedAppointments =   randevular.map<Appointment>((item) {

      return Appointment(
        startTime: DateTime.parse(item['start']),
        endTime: DateTime.parse(item['end']),
        subject: item['title'] ?? "",
        id: item['id'],
        color: Color(int.parse(item['bgcolor'].toString().replaceFirst('0x', ''), radix: 16)),
        resourceIds: [item['resourceId']],
        notes: item["notes"],
        location: item["durum"].toString(),
        recurrenceId: item["ongorusmeid"].toString(),

      );
    }).toList();


    List<CalendarResource> resources = takvimpersoneller.map<CalendarResource>((item) {

      return CalendarResource(
        displayName: item['name'],
        id: item['id'],
        color: Color(int.parse(item['bgcolor'].toString().replaceFirst('0x', ''), radix: 16)),
        image: NetworkImage('https://app.randevumcepte.com.tr' +( item["avatar"]!=null ? item['avatar'] : '/public/isletmeyonetim_assets/img/avatar.png' )),
      );
    }).toList();

    log('veriler aktarıldı');

    setState(() {
      personelliste = personeller.map((json) => Personel.fromJson(json)).toList();
      randevuliste = randevulisteleri.map((json)=> Randevu.fromJson(json)).toList();
      // Update the state with the new list of appointments
      _appointmentDataSource.appointments = updatedAppointments;
      _appointmentDataSource.resources = resources;
      _appointmentDataSource = AppointmentDataSource(updatedAppointments, resources);

      _personelDataGridSource = PersonelDataSource(
        rowsPerPage: 10,
        salonid: widget.isletmebilgi["id"].toString(),
        context: context,
        baslik: "",
        isletmebilgi : widget.isletmebilgi,
        showYukleniyor: false,
      );
      _selectedDate = seciliTarih;
      isloading=false;
    });
  }

  void _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _calendarController.displayDate = picked;
      });
    }
  }

  void _changeDateByDays(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
      _calendarController.displayDate = _selectedDate;

      //getUpdatedAppointments(DateFormat('yyyy-MM-dd').format(_selectedDate), DateFormat('yyyy-MM-dd').format(_selectedDate));
    });
  }

  @override
  Widget build(BuildContext context) {
    double ekranGenisligi = MediaQuery.of(context).size.width;
    final String formattedDate = DateFormat('d MMMM EEEE', 'tr_TR').format(_selectedDate);
    return Scaffold(
      appBar: new AppBar(
        title: const Text(
          'Takvim',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        /* leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              setState(() {
                Provider.of<IndexedStackState>(context, listen: false).setSelectedIndex(0);
              });
            }),*/
        actions: [
          if (widget.isletmebilgi["demo_hesabi"].toString() == "1")
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: SizedBox(
                  width: 100, // <-- Your width
                  child: YukseltButonu(isletme_bilgi: widget.isletmebilgi,)
              ),
            ),
          IconButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => AppointmentEditor(
                  isletmebilgi: widget.isletmebilgi, tarihsaat: "", personel_id: "")))
                  .then((value) {

                getUpdatedAppointments(DateFormat('yyyy-MM-dd').format(seciliTarih), DateFormat('yyyy-MM-dd').format(seciliTarih),true);

              });
            },
            icon: Icon(
              Icons.add,
              color: Colors.black,
            ),
            iconSize: 26,
          ),
        ],
        toolbarHeight: 60,
      ),
      body:  isloading ? Center(child:CircularProgressIndicator()) :
      Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: widget.kullanicirolu == 5 ? 0 : ekranGenisligi*0.35,
                child: DropdownButtonHideUnderline(

                  child: DropdownButton2<TakvimTuru>(

                    isExpanded: true,
                    hint: Text(
                      'Takvim Türü..',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                    items: takvimTuru
                        .map((item) => DropdownMenuItem(
                      value: item,
                      child: Text(
                        item.takvim_turu,
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ))
                        .toList(),
                    value: selectedTakvimTuru,

                    onChanged: (value) {
                      setState(() {
                        log('tür değişti');
                        selectedTakvimTuru = value;
                        getUpdatedAppointments(DateFormat('yyyy-MM-dd').format(seciliTarih), DateFormat('yyyy-MM-dd').format(seciliTarih),true);

                      });
                    },
                    buttonStyleData: const ButtonStyleData(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      height: 50,
                      width: 400,
                    ),

                    dropdownStyleData: const DropdownStyleData(
                      maxHeight: 200,
                    ),
                    menuItemStyleData: const MenuItemStyleData(
                      height: 40,
                    ),

                    //This to clear the search value when you close the menu
                    onMenuStateChange: (isOpen) {
                      if (!isOpen) {
                        takvimTuruText.clear();
                      }
                    },

                  )),),
              SizedBox(
                width: widget.kullanicirolu == 5 ? ekranGenisligi : ekranGenisligi*0.65,
                  child:  Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 0),
                color: Colors.grey.shade200,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back),
                      onPressed: () => _changeDateByDays(-1),
                    ),
                    GestureDetector(
                      onTap: _pickDate,
                      child: Text(
                        formattedDate,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.arrow_forward),
                      onPressed: () => _changeDateByDays(1),
                    ),
                  ],
                ),
              ),),
            ],
          ),



          Expanded(
              child: SfCalendar(

                showNavigationArrow: true,
                controller: _calendarController,
                initialDisplayDate: DateTime.now(),

                view: CalendarView.timelineDay,
                viewHeaderHeight: 0,

                showDatePickerButton: true,
                headerHeight: 0,
                dataSource: _appointmentDataSource,
                allowAppointmentResize: true,

                timeZone: 'Europe/Istanbul', // veya cihazın local timezone'u
                timeSlotViewSettings: TimeSlotViewSettings(
                  timeFormat: 'HH:mm',
                  startHour: 8, // Takvimi 08:00'de başlat
                  endHour: 20,  // Takvimi 20:00'de bitir
                  timeInterval: Duration(minutes: 15),
                  timeIntervalWidth: 150,
                ),
                onTap: onCalendarTapped,
                onViewChanged: (ViewChangedDetails details) {

                  seciliTarih = details.visibleDates[0];

                  log('görünüm değişti');

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    getUpdatedAppointments(
                        DateFormat('yyyy-MM-dd').format(seciliTarih),
                        DateFormat('yyyy-MM-dd').format(seciliTarih),
                        true
                    );
                  });




                },
              )
          ),

        ],

      ),


    );
  }

  void onCalendarTapped(CalendarTapDetails calendarTapDetails) {
    if (calendarTapDetails.targetElement == CalendarElement.header) {
      showDatePicker(
        context: context,
        initialDate: calendarTapDetails.date ?? DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      ).then((pickedDate) {
        if (pickedDate != null) {
          _calendarController.displayDate = pickedDate; // controller'ı yukarıda tanımlamış olmalısın
        }
      });
      return; // Diğer kodlara girmesin
    }
    if (calendarTapDetails.targetElement != CalendarElement.calendarCell &&
        calendarTapDetails.targetElement != CalendarElement.appointment) {


      if(calendarTapDetails.resource != null){
        String str = calendarTapDetails.resource?.id.toString() ?? "";

        _personelDataGridSource.rows.forEach((element) {

        });
        //_personelDataGridSource.rows.firstWhere((element)  element.getCells()[1].value == calendarTapDetails.resource?.id);
        Personel personel = _personelDataGridSource.rows.firstWhere((element) => element.getCells()[1].value == calendarTapDetails.resource?.id).getCells()[0].value;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RandevularMenu(kullanicirolu: widget.kullanicirolu, isletmebilgi: widget.isletmebilgi,personelid: _personelDataGridSource.rows.firstWhere((element) => element.getCells()[1].value == calendarTapDetails.resource?.id).getCells()[1].value,cihazid: "",personel_adi: personel.personel_adi,cihaz_adi: "",),
          ),
        );
        //_personelDataGridSource.showDetailsDialog(context, _personelDataGridSource.rows.firstWhere((element) => element.getCells()[1].value == calendarTapDetails.resource?.id).getCells()[0].value) ;
        //_personelDataGridSource.showDetailsDialog(context, );
      }

      else{
        Navigator.push(context, MaterialPageRoute(builder: (context) => AppointmentEditor(
            isletmebilgi: widget.isletmebilgi, tarihsaat: "", personel_id: "")))
            .then((value) {

          getUpdatedAppointments(DateFormat('yyyy-MM-dd').format(seciliTarih), DateFormat('yyyy-MM-dd').format(seciliTarih),true);

        });
      }

    }
    else if(calendarTapDetails.appointments == null){
      String personel_id =calendarTapDetails.resource?.id.toString() ?? "";

      Navigator.push(context, MaterialPageRoute(builder: (context) => AppointmentEditor(
          isletmebilgi: widget.isletmebilgi, tarihsaat: calendarTapDetails.date.toString(), personel_id: personel_id)))
          .then((value) {
        String seciliTarih1 = DateFormat('yyyy-MM-dd').format(DateTime.parse(calendarTapDetails.date.toString()));
        String seciliTarih2 = DateFormat('yyyy-MM-dd').format(DateTime.parse(calendarTapDetails.date.toString()));
        getUpdatedAppointments(DateFormat('yyyy-MM-dd').format(seciliTarih), DateFormat('yyyy-MM-dd').format(seciliTarih),true);

      });

    }

    else
    {
      Appointment tappedAppointment = calendarTapDetails.appointments![0];

      RandevuDetayGoster(context, tappedAppointment);
    }

  }
  void RandevuDetayGoster(BuildContext context, Appointment randevudetay) {
    final _formKey = GlobalKey<FormState>();
    List<String> randevutitle = randevudetay.subject.split('\n');
    List<String>? randevudurum = randevudetay.location?.split('-');
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          insetPadding: EdgeInsets.zero,

          content: Container(

            width: MediaQuery.of(context).size.width * 0.75,
            child: SingleChildScrollView(
              child: Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  Positioned(
                    right: -40,
                    top: -40,
                    child: InkResponse(
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                      child: const CircleAvatar(
                        backgroundColor: Colors.red,
                        child: Icon(Icons.close),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        SizedBox(height: 20,),
                        Text(
                          randevutitle[0] + " Randevu Detayları",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Divider(color: Colors.black, height: 10,),
                        Row(
                          children: [

                            Expanded(child: Text(randevudetay.notes ?? ""))
                          ],
                        ),

                        randevudurum![0] == "0" || randevudurum![0] == "1" ? Divider(color: Colors.black,
                          height: 30,): SizedBox.shrink(),
                        randevudurum![0] == "0" || randevudurum![0] == "1" ? Row(
                          children: [
                            ElevatedButton(onPressed: () {
                              Navigator.of(context,rootNavigator: true).pop();


                              Navigator.push(context, new MaterialPageRoute(builder: (context) => RandevuDuzenle(isletmebilgi: widget.isletmebilgi, randevu: randevuliste.firstWhere((element) => element.id.toString()==randevudetay.id.toString()),))).then((value) {
                                getUpdatedAppointments(DateFormat('yyyy-MM-dd').format(seciliTarih), DateFormat('yyyy-MM-dd').format(seciliTarih),true);

                              });

                            }, child:
                            Text('Düzenle'),
                              style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor:  Color(0xFF5E35B1),

                                  elevation: 5,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5.0)
                                  ),
                                  minimumSize: Size(275, 30)
                              ),
                            )
                          ],
                        ) : SizedBox.shrink(),
                        randevudurum![0] == "0" || randevudurum![0] == "1" ? Row(

                          children: [
                            randevudurum![0] == "0" ?
                            ElevatedButton(onPressed: () {}, child:
                            Text('Onayla'),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  elevation: 5,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5.0)
                                  ),
                                  minimumSize: Size(130, 30)
                              ),
                            ):SizedBox.shrink(),
                            randevudurum![0] != "0" ?
                            ElevatedButton(onPressed: () async{
                              await randevugelmediisaretle(randevudetay.id.toString(), context);
                              Navigator.of(context).pop();
                              getUpdatedAppointments(DateFormat('yyyy-MM-dd').format(seciliTarih), DateFormat('yyyy-MM-dd').format(seciliTarih),false);

                            }, child:
                            Text('Gelmedi'),
                              style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: Colors.red[600],
                                  elevation: 5,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5.0)
                                  ),
                                  minimumSize: Size(130, 30)
                              ),
                            ):SizedBox.shrink(),
                            SizedBox(width: 15,),
                            randevudurum![0] != "0" ?
                            ElevatedButton(onPressed: () async {
                              await randevugeldiisaretle(randevudetay.id.toString(),'', context);
                              Navigator.of(context).pop();
                              getUpdatedAppointments(DateFormat('yyyy-MM-dd').format(seciliTarih), DateFormat('yyyy-MM-dd').format(seciliTarih),false);
                            }, child:
                            Text('Geldi'),
                              style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: Colors.green,
                                  elevation: 5,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5.0)
                                  ),
                                  minimumSize: Size(130, 30)
                              ),
                            ):SizedBox.shrink(),

                          ],
                        ):SizedBox.shrink(),
                        (randevudurum![0] == "0" || randevudurum![0] == "1") && !randevutitle[0].contains("ÖN GÖRÜŞME")   ? Row(
                          children: [
                            randevudurum![0] != "0" && !randevutitle[0].contains("PAKET") ?
                            ElevatedButton(onPressed: () async{
                              dynamic randevutahsilatsonuc = await randevudantahsilatagit(context,randevudetay.id.toString());
                              if(randevutahsilatsonuc==true){
                                Navigator.of(context).pop();
                                Navigator.push(context, new MaterialPageRoute(builder: (context) => TahsilatEkrani(isletmebilgi: widget.isletmebilgi, musteridanisanid: randevuliste.firstWhere((element) => element.id==randevudetay.id.toString()).user_id.toString())));

                              }
                              else{
                                final response = randevutahsilatsonuc;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Tahsilat ekranı açılırken bir hata oluştu. Hata kodu : '+response.statusCode.toString()),
                                  ),
                                );
                              }

                            }, child:
                            Text('Tahsilat'),
                              style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: Color(0xFF5E35B1),
                                  elevation: 5,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5.0)
                                  ),
                                  minimumSize: Size(130, 30)
                              ),
                            )
                                : SizedBox.shrink(),

                            randevudurum![0] != "0" && !randevutitle[0].contains("PAKET")?
                            SizedBox(width: 15,) : SizedBox.shrink(),

                            ElevatedButton(onPressed: () {
                              showDialog<bool>(
                                context: context,
                                builder: (dialogContex) {
                                  return AlertDialog(
                                    title: Text('EMİN MİSİNİZ?'),
                                    content: Text("Randevu iptal etme işlemi geri alınamaz?"),
                                    actions: <Widget>[
                                      TextButton(
                                        child: Text('VAZGEÇ'),
                                        onPressed: () {
                                          Navigator.of(dialogContex).pop();
                                        },
                                      ),
                                      TextButton(
                                        child: Text('İPTAL ET'),
                                        onPressed: () async {
                                          SharedPreferences prefs = await SharedPreferences.getInstance();
                                          var usertype = prefs.getString('user_type');
                                          await randevuiptalet(randevudetay.id.toString(), context,usertype.toString());
                                          Navigator.of(dialogContex).pop(); // close the confirmation dialog

                                          getUpdatedAppointments(DateFormat('yyyy-MM-dd').format(seciliTarih), DateFormat('yyyy-MM-dd').format(seciliTarih),false);
                                          Navigator.of(context).pop(); // close the details popup
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );




                            }, child:
                            Text('İptal Et'),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  foregroundColor: Colors.white,
                                  elevation: 5,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5.0)
                                  ),
                                  minimumSize: Size(130, 30)
                              ),
                            )

                          ],
                        ) : SizedBox.shrink(),
                        (randevudurum![0] == "0" || randevudurum![0] == "1") && randevutitle[0].contains("ÖN GÖRÜŞME") && (randevudetay.notes ?? "").contains("Beklemede")  ? Row(
                          children: [

                            ElevatedButton(onPressed: () async{
                              OnGorusme selectedItem = await ongorsumebilgi(randevudetay.recurrenceId.toString());
                              if (selectedItem.paket_id != null && selectedItem.paket_id != "null") {
                                paketsatispopup(context, randevudetay.recurrenceId.toString());
                              } else if (selectedItem.urun_id != null && selectedItem.urun_id != "null") {
                                urunsatispopup(context, randevudetay.recurrenceId.toString());
                              }

                            }, child:
                            Text('Satış Yapıldı'),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  elevation: 5,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5.0)
                                  ),
                                  minimumSize: Size(130, 30)
                              ),
                            )
                            ,
                            SizedBox(width: 15,),

                            ElevatedButton(onPressed: () {

                              showSatisYapilmamaNedeniDialog(context, randevudetay.recurrenceId.toString(),"1","",(value)=>getUpdatedAppointments(DateFormat('yyyy-MM-dd').format(seciliTarih), DateFormat('yyyy-MM-dd').format(seciliTarih),false));

                              ;

                              // close the confirmation dialog



                              //satisyapilmadi(context,  "",String aciklama,String currentPage,String aramaterimi,bool showprogress)
                            }, child:
                            Text('Satış Yapılmadı'),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red[600],
                                  elevation: 5,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5.0)
                                  ),
                                  minimumSize: Size(130, 30)
                              ),
                            )

                          ],
                        ) : SizedBox.shrink(),

                      ],
                    ),
                  ),
                ],
              ),
            ),

          ),
        );
      },
    );
  }
  void paketsatispopup(BuildContext context, String ongorusmeid) {
    TextEditingController ongorusmetarihi = TextEditingController();
    TextEditingController seansaralik = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          scrollable: true,
          title: Text(
            'Paket satışına devam etmek için lütfen aşağıdan başlangıç tarihi seçip seans gün aralığını belirleyin!',
            style: TextStyle(fontSize: 14),
          ),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Session date input
              Padding(
                padding: const EdgeInsets.only(left: 0.0),
                child: Text(
                  'Seans Başlangıç Tarihi',
                  style: TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 10),
              Container(
                height: 40,
                padding: EdgeInsets.only(left: 0, right: 20),
                child: TextFormField(
                  controller: ongorusmetarihi,
                  decoration: InputDecoration(
                    focusColor: Color(0xFF6A1B9A),
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
                  readOnly: true, // User cannot directly enter text
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1950),
                      lastDate: DateTime(2100),
                    );

                    // Update the TextFormField with the selected date
                    if (pickedDate != null) {
                      // Format the date as needed (e.g., yyyy-MM-dd)
                      String formattedDate =  DateFormat('yyyy-MM-dd').format(pickedDate);
                      ongorusmetarihi.text = formattedDate;
                    }
                  },
                ),
              ),
              SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 0.0),
                child: Text(
                  'Seans Aralığı (Gün)',
                  style: TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 10),
              Container(
                height: 40,
                padding: EdgeInsets.only(left: 0, right: 20),
                child: TextField(
                  controller: seansaralik,
                  keyboardType: TextInputType.number,
                  maxLines: 1,
                  decoration: InputDecoration(
                    focusColor: Color(0xFF6A1B9A),
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
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Kapat', style: TextStyle(color: Colors.black)),
            ),
            TextButton(
              onPressed: () {
                satisyapildi(context, ongorusmeid, '', ongorusmetarihi.text, seansaralik.text);
                getUpdatedAppointments(DateFormat('yyyy-MM-dd').format(seciliTarih), DateFormat('yyyy-MM-dd').format(seciliTarih),false);
              },
              child: Text('Kaydet', style: TextStyle(color: Colors.purple[800])),
            ),
          ],
        );
      },
    );
  }

  void urunsatispopup(BuildContext context, String  ongorusmeid) {
    TextEditingController quantityController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          scrollable: true,
          title: Text('Ürün satışına devam etmek için lütfen ürün adedini belirleyiniz!',style:TextStyle(fontSize:16)),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 0.0),
                child: Text('Adet', style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),),
              ),
              SizedBox(height: 10,),
              Container(
                height: 50,
                child: TextField(
                  controller: quantityController,  // Set the controller
                  keyboardType: TextInputType.number,
                  maxLines: 1,
                  decoration: InputDecoration(
                    focusColor: Color(0xFF6A1B9A),
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
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Kapat', style: TextStyle(color: Colors.black)),
            ),
            TextButton(
              onPressed: () {
                satisyapildi(context, ongorusmeid, quantityController.text,'','');
                getUpdatedAppointments(DateFormat('yyyy-MM-dd').format(seciliTarih), DateFormat('yyyy-MM-dd').format(seciliTarih),false);
              },
              child: Text('Kaydet', style: TextStyle(color: Colors.purple[800])),
            ),
          ],
        );
      },
    );
  }

}

class AppointmentDataSource extends CalendarDataSource {
  AppointmentDataSource(List<Appointment> appointments, List<CalendarResource> resources) {
    this.appointments = appointments;
    this.resources = resources;
  }
}


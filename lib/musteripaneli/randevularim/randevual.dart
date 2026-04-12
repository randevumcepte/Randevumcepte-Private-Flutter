/*import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
 import 'package:flutter_localizations/flutter_localizations.dart';




class RandevuAl extends StatefulWidget {
  const RandevuAl({Key? key}) : super(key: key);

  @override
  State<RandevuAl> createState() => _RandevuAlState();
}

class _RandevuAlState extends State<RandevuAl> {
  final now = DateTime.now();
  //late BookingService mockBookingService;

  @override
  void initState() {
    super.initState();
    // DateTime.now().startOfDay
    // DateTime.now().endOfDay
    /*mockBookingService = BookingService(
        serviceName: 'Mock Service',
        serviceDuration: 30,
        bookingEnd: DateTime(now.year, now.month, now.day, 20, 0),
        bookingStart: DateTime(now.year, now.month, now.day, 8, 0));*/
  }
  final List<String> personel = [
    'Cevriye',
    'Beyzanur Sarılı',
    'Anıl Orbey',
    'Çağlar Filiz',
    'Ferdi Korkmaz',
    'Elif Çetin',

  ];
  final List<String> hizmet = [
    'Saç Kesimi',
    'Saç Bakımı',
    'Fön',
    'Ağda',
    'Hareketli Kesim',
    'Sakal Tıraşı',

  ];
  String? selectedpersonel;
  TextEditingController personelController = TextEditingController();
  String? selectedhizmet;
  TextEditingController hizmetController = TextEditingController();

  Stream<dynamic>? getBookingStreamMock(
      {required DateTime end, required DateTime start}) {
    return Stream.value([]);
  }

  /*Future<dynamic> uploadBookingMock(
      {required BookingService newBooking}) async {
    await Future.delayed(const Duration(seconds: 1));
    converted.add(DateTimeRange(
        start: newBooking.bookingStart, end: newBooking.bookingEnd));
    print('${newBooking.toJson()} Güncellendi');



  }*/

  List<DateTimeRange> converted = [];

  List<DateTimeRange> convertStreamResultMock({required dynamic streamResult}) {
    ///here you can parse the streamresult and convert to [List<DateTimeRange>]
    ///take care this is only mock, so if you add today as disabledDays it will still be visible on the first load
    ///disabledDays will properly work with real data
    DateTime first = now;
    DateTime tomorrow = now.add(Duration(days: 1));
    DateTime second = now.add(const Duration(minutes: 55));
    DateTime third = now.subtract(const Duration(minutes: 240));
    DateTime fourth = now.subtract(const Duration(minutes: 500));
    converted.add(
        DateTimeRange(start: first, end: now.add(const Duration(minutes: 30))));
    converted.add(DateTimeRange(
        start: second, end: second.add(const Duration(minutes: 23))));
    converted.add(DateTimeRange(
        start: third, end: third.add(const Duration(minutes: 15))));
    converted.add(DateTimeRange(
        start: fourth, end: fourth.add(const Duration(minutes: 50))));

    //book whole day example
    converted.add(DateTimeRange(
        start: DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 5, 0),
        end: DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 23, 0)));
    return converted;
  }

  List<DateTimeRange> generatePauseSlots() {
    return [
      DateTimeRange(
          start: DateTime(now.year, now.month, now.day, 12, 0),
          end: DateTime(now.year, now.month, now.day, 13, 0))
    ];
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [
          Locale('en', ''), // English, no country code
          Locale('tr', ''), // Spanish, no country code
        ],
        debugShowCheckedModeBanner: false,
        title: 'Randevu Al',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
            backgroundColor: Colors.white,
            toolbarHeight: 60,
            title: const Text('Randevu Al',style: TextStyle(color: Colors.black),),


          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 10,),
              Padding(
                padding: const EdgeInsets.only(left: 20.0),
                child: Text('Personel',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
              ),
              SizedBox(height: 10,),
              Container(
                alignment: Alignment.center,
                margin: EdgeInsets.only(left:20,right: 20),
                height: 40,
                width:double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Color(0xFF6A1B9A)),
                  borderRadius: BorderRadius.circular(10), //border corner radius

                  //you can set more BoxShadow() here

                ),
                child: DropdownButtonHideUnderline(

                    child: DropdownButton2<String>(

                      isExpanded: true,
                      hint: Text(
                        'Personel Seç',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                      items: personel
                          .map((item) => DropdownMenuItem(
                        value: item,
                        child: Text(
                          item,
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      ))
                          .toList(),
                      value: selectedpersonel,

                      onChanged: (value) {
                        setState(() {
                          selectedpersonel = value;
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
                      dropdownSearchData: DropdownSearchData(
                        searchController: personelController,
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
                            controller: personelController,
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
                          return item.value.toString().contains(searchValue);
                        },
                      ),
                      //This to clear the search value when you close the menu
                      onMenuStateChange: (isOpen) {
                        if (!isOpen) {
                          personelController.clear();
                        }
                      },

                    )),
              ),
              SizedBox(height: 10,),
              Padding(
                padding: const EdgeInsets.only(left: 20.0),
                child: Text('Hizmet',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
              ),
              SizedBox(height: 10,),
              Container(
                alignment: Alignment.center,
                margin: EdgeInsets.only(left:20,right: 20),
                height: 40,
                width:double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Color(0xFF6A1B9A)),
                  borderRadius: BorderRadius.circular(10), //border corner radius

                  //you can set more BoxShadow() here

                ),
                child: DropdownButtonHideUnderline(

                    child: DropdownButton2<String>(
                      isExpanded: true,
                      hint: Text(
                        'Hizmet Seç',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                      items: hizmet
                          .map((item) => DropdownMenuItem(

                        value: item,
                        child: Text(
                          item,
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      ))
                          .toList(),
                      value: selectedhizmet,
                      onChanged: (value) {
                        setState(() {
                          selectedhizmet = value;
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
                      dropdownSearchData: DropdownSearchData(
                        searchController: hizmetController,
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
                            controller: hizmetController,
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
                          return item.value.toString().contains(searchValue);
                        },
                      ),
                      //This to clear the search value when you close the menu
                      onMenuStateChange: (isOpen) {
                        if (!isOpen) {
                          hizmetController.clear();
                        }
                      },

                    )),
              ),
              Expanded(
                child: Center(
                  /*child: BookingCalendar(
                    bookingService: mockBookingService,
                    convertStreamResultToDateTimeRanges: convertStreamResultMock,
                    getBookingStream: getBookingStreamMock,
                    uploadBooking: uploadBookingMock,
                    uploadingWidget: const CircularProgressIndicator(),
                    wholeDayIsBookedWidget:
                    const Text('Üzgünüz, tüm gün dolu'),
                    availableSlotText: "Boş",
                    selectedSlotText: "Seç",
                    bookedSlotText: "Dolu",
                    bookingButtonText: "Rezervasyon Talebini Oluştur",


                    //disabledDates: [DateTime(2023, 1, 20)],
                    //disabledDays: [6, 7],
                  ),*/
                ),
              ),
            ],
          ),
        ));
  }
}*/
import 'dart:developer';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:randevu_sistem/Frontend/tl_input_formatter.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';

import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Models/adisyonhizmetler.dart';
import 'package:randevu_sistem/Models/isletmehizmetleri.dart';
import 'package:randevu_sistem/Models/personel.dart';


class HizmetSatisiDuzenleme extends StatefulWidget {
  final String musteriid;
  final AdisyonHizmet mevcuthizmet;
  final bool senetlisatis;
  final dynamic isletmebilgi;
  final String adisyonId;
  HizmetSatisiDuzenleme({Key? key, required this.adisyonId, required this.musteriid,required this.mevcuthizmet,required this.senetlisatis,required this.isletmebilgi}) : super(key: key);
  @override
  _HizmetSatisiState createState() => _HizmetSatisiState();
}
class _HizmetSatisiState extends State<HizmetSatisiDuzenleme> {
  bool isloading = true;
  late List<Personel> personel;
  late List<IsletmeHizmet> hizmet;


  Personel? selectedpersonel;
  String? seciliisletme;
  TextEditingController secilipersonel = TextEditingController();
  IsletmeHizmet? selectedhizmet;

  TextEditingController secilihizmet = TextEditingController();
  TextEditingController islem_tarihi = TextEditingController();

  TimeOfDay _selectedTime = TimeOfDay.now();
  TextEditingController islem_saati = TextEditingController();


  TextEditingController fiyat = TextEditingController();
  TextEditingController sure_dk = TextEditingController();
  TextEditingController seans_sayisi = TextEditingController();

  void initState() {
    super.initState();
    initialize();

  }
  Future<void> initialize() async{
    seciliisletme = (await secilisalonid())!;
    List <Personel> personelliste = await personellistegetir(seciliisletme!);
    List <IsletmeHizmet> hizmetliste = await isletmehizmetleri(seciliisletme!);
    setState(() {
      log('adisyon id '+widget.mevcuthizmet.adisyon_id);
      personel = personelliste;
      hizmet  = hizmetliste;
      islem_saati.text = widget.mevcuthizmet.islem_saati;
      islem_tarihi.text = widget.mevcuthizmet.islem_tarihi;
      selectedpersonel = personel.firstWhere((element) => element.id.toString() == widget.mevcuthizmet.personel_id.toString());
      sure_dk.text = widget.mevcuthizmet.sure;
      fiyat.text = backendToTl(widget.mevcuthizmet.fiyat);
      // Seans sayisi: 1 ise tekil hizmet demek, kullaniciya bos gostermek daha net
      final int _seansIlk = int.tryParse(widget.mevcuthizmet.seans_sayisi) ?? 1;
      seans_sayisi.text = _seansIlk <= 1 ? '' : _seansIlk.toString();
      selectedhizmet = hizmet.firstWhere((element) => element.hizmet_id == widget.mevcuthizmet.hizmet_id);

      isloading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Hizmet Düzenle',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.grey.shade700),
          onPressed: () => Navigator.of(context).pop(),
        ),
        toolbarHeight: 70,
        actions: [
          if (widget.isletmebilgi["demo_hesabi"].toString() == "1")
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: YukseltButonu(isletme_bilgi: widget.isletmebilgi),
            ),
        ],
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.05),
      ),
      body: isloading
          ? Center(
              child: CircularProgressIndicator(
                color: Colors.purple.shade700,
              ),
            )
          : GestureDetector(
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Başlık Kartı
                    Container(
                      margin: EdgeInsets.only(bottom: 16),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.purple.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.edit_outlined,
                              color: Colors.purple.shade700,
                              size: 20,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hizmet Düzenle',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                                Text(
                                  'Mevcut hizmet kaydını güncelleyin',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Tarih ve Saat Satırı
                    Row(
                      children: [
                        Expanded(
                          child: _buildInputCard(
                            icon: Icons.calendar_today_outlined,
                            title: 'İşlem Tarihi',
                            child: TextFormField(
                              controller: islem_tarihi,
                              readOnly: true,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade800,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                hintText: 'Tarih seç',
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade500,
                                ),
                              ),
                              onTap: () async {
                                DateTime? pickedDate = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime(1950),
                                    lastDate: DateTime(2100),
                                    builder: (context, child) {
                                      return Theme(
                                        data: ThemeData.light().copyWith(
                                          colorScheme: ColorScheme.light(
                                            primary: Colors.purple.shade700,
                                            onPrimary: Colors.white,
                                          ),
                                        ),
                                        child: child!,
                                      );
                                    });

                                if (pickedDate != null) {
                                  String formattedDate =
                                      DateFormat('yyyy-MM-dd').format(pickedDate);
                                  setState(() {
                                    islem_tarihi.text = formattedDate;
                                  });
                                } else {}
                              },
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildInputCard(
                            icon: Icons.access_time_outlined,
                            title: 'İşlem Saati',
                            child: TextFormField(
                              controller: islem_saati,
                              readOnly: true,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade800,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                hintText: 'Saat seç',
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade500,
                                ),
                                suffixIcon: Icon(
                                  Icons.access_time,
                                  color: Colors.purple.shade700,
                                  size: 20,
                                ),
                              ),
                              onTap: () async {
                                TimeOfDay? pickedTime = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                  builder: (BuildContext context, Widget? child) {
                                    return MediaQuery(
                                      data: MediaQuery.of(context)
                                          .copyWith(alwaysUse24HourFormat: true),
                                      child: child!,
                                    );
                                  },
                                );

                                if (pickedTime != null && pickedTime != _selectedTime) {
                                  setState(() {
                                    _selectedTime = pickedTime;
                                    islem_saati.text = DateFormat.Hm().format(
                                      DateTime(
                                        2023,
                                        1,
                                        1,
                                        pickedTime.hour,
                                        pickedTime.minute,
                                      ),
                                    );
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 16),

                    // Personel Seçimi
                    _buildInputCard(
                      icon: Icons.person_outline,
                      title: 'Personel',
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton2<Personel>(
                          isExpanded: true,
                          hint: Text(
                            'Personel seçin',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          items: personel
                              .map((item) => DropdownMenuItem(
                                    value: item,
                                    child: Text(
                                      item.personel_adi,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade800,
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
                          buttonStyleData: ButtonStyleData(
                            padding: EdgeInsets.symmetric(horizontal: 0),
                            height: 40,
                          ),
                          dropdownStyleData: DropdownStyleData(
                            maxHeight: 200,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.white,
                            ),
                          ),
                          menuItemStyleData: MenuItemStyleData(height: 40),
                          dropdownSearchData: DropdownSearchData(
                            searchController: secilipersonel,
                            searchInnerWidgetHeight: 50,
                            searchInnerWidget: Container(
                              height: 50,
                              padding: EdgeInsets.all(8),
                              child: TextFormField(
                                controller: secilipersonel,
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 8),
                                  hintText: 'Personel ara...',
                                  hintStyle: TextStyle(fontSize: 12),
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
                          onMenuStateChange: (isOpen) {
                            if (!isOpen) {
                              secilipersonel.clear();
                            }
                          },
                        ),
                      ),
                    ),

                    SizedBox(height: 16),

                    // Hizmet Seçimi
                    _buildInputCard(
                      icon: Icons.spa_outlined,
                      title: 'Hizmet',
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton2<IsletmeHizmet>(
                          isExpanded: true,
                          hint: Text(
                            'Hizmet seçin',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          items: hizmet
                              .map((item) => DropdownMenuItem(
                                    value: item,
                                    child: Text(
                                      item.hizmet["hizmet_adi"] ?? "",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade800,
                                      ),
                                    ),
                                  ))
                              .toList(),
                          value: selectedhizmet,
                          onChanged: (value) {
                            setState(() {
                              selectedhizmet = value;
                              sure_dk.text = selectedhizmet?.sure ?? "";
                              fiyat.text = backendToTl(selectedhizmet?.fiyat ?? "");
                            });
                          },
                          buttonStyleData: ButtonStyleData(
                            padding: EdgeInsets.symmetric(horizontal: 0),
                            height: 40,
                          ),
                          dropdownStyleData: DropdownStyleData(
                            maxHeight: 200,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.white,
                            ),
                          ),
                          menuItemStyleData: MenuItemStyleData(height: 40),
                          dropdownSearchData: DropdownSearchData(
                            searchController: secilihizmet,
                            searchInnerWidgetHeight: 50,
                            searchInnerWidget: Container(
                              height: 50,
                              padding: EdgeInsets.all(8),
                              child: TextFormField(
                                controller: secilihizmet,
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 8),
                                  hintText: 'Hizmet ara...',
                                  hintStyle: TextStyle(fontSize: 12),
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
                          onMenuStateChange: (isOpen) {
                            if (!isOpen) {
                              secilihizmet.clear();
                            }
                          },
                        ),
                      ),
                    ),

                    SizedBox(height: 16),

                    // Süre ve Fiyat Satırı
                    Row(
                      children: [
                        Expanded(
                          child: _buildInputCard(
                            icon: Icons.timer_outlined,
                            title: 'Süre (dk)',
                            child: TextFormField(
                              controller: sure_dk,
                              keyboardType: TextInputType.phone,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade800,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: '0',
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildInputCard(
                            icon: Icons.currency_lira,
                            title: 'Fiyat (₺)',
                            child: TextFormField(
                              controller: fiyat,
                              keyboardType:
                                  TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [TurkishLiraInputFormatter()],
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade800,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: '0,00',
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 16),

                    _buildInputCard(
                      icon: Icons.repeat_rounded,
                      title: 'Seans Sayısı',
                      child: TextFormField(
                        controller: seans_sayisi,
                        keyboardType: TextInputType.number,
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                        ),
                      ),
                    ),

                    SizedBox(height: 32),

                    // Kaydet Butonu
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 16),
                      child: ElevatedButton(
                        onPressed: () async {
                          final String fiyatBackend = tlToBackend(fiyat.text);
                          final double fiyatDouble = double.tryParse(fiyatBackend) ?? 0;
                          final String fiyatGonderim =
                              fiyatDouble.toStringAsFixed(2).replaceAll('.', ',');
                          // Bos ya da <=1 -> backend NULL kaydeder (tekil hizmet)
                          final String _seansTrim = seans_sayisi.text.trim();
                          final String _seansGonder = (_seansTrim.isEmpty ||
                                  (int.tryParse(_seansTrim) ?? 0) <= 1)
                              ? ''
                              : _seansTrim;
                          final AdisyonHizmet adisyonhizmet = AdisyonHizmet(
                              id: widget.mevcuthizmet.id,
                              adisyon_id: widget.mevcuthizmet.adisyon_id,
                              hizmet_id: selectedhizmet?.hizmet_id ?? "",
                              islem_tarihi: islem_tarihi.text,
                              islem_saati: islem_saati.text,
                              sure: sure_dk.text,
                              fiyat: fiyatGonderim,
                              geldi: "1",
                              personel_id: selectedpersonel?.id ?? "",
                              cihaz_id: "",
                              oda_id: "",
                              dogrulama_kodu: "",
                              taksitli_tahsilat_id: "",
                              senet_id: "",
                              indirim_tutari: "",
                              hediye: "",
                              hizmet: selectedhizmet?.hizmet ?? "",
                              personel: selectedpersonel ?? "",
                              seans_sayisi: _seansGonder);
                          // Duzenleme daima mevcut bir hizmet satiri uzerinde yapilir.
                          // adisyonhizmetekle ucu adisyon_hizmet_id ile satiri gunceller;
                          // bu cagri yapilmazsa yeni fiyat DB'ye yazilmaz (tahsilet/taksit
                          // uclari fiyati satira geri yazmaz, sadece okur).
                          AdisyonHizmet eklenenhizmet = await adisyonhizmetekle(
                              adisyonhizmet, widget.musteriid, context, seciliisletme!);
                          Navigator.pop(context, eklenenhizmet);
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'KAYDET',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple.shade700,
                          foregroundColor: Colors.white,
                          minimumSize: Size(double.infinity, 54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                          shadowColor: Colors.transparent,
                        ),
                      ),
                    ),

                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInputCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 16, top: 12, right: 16),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: Colors.grey.shade600,
                ),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: child,
          ),
        ],
      ),
    );
  }
}
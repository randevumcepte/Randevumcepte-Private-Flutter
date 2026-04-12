import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/material.dart';
import 'package:spelling_number/spelling_number.dart';

import '../../../../Frontend/datetimeformatting.dart';
import '../../../../Models/senetler.dart';


class PdfPreviewPage extends StatefulWidget {
  final Senet senet;
  PdfPreviewPage( {Key? key,required this.senet}) : super(key: key);
  @override
  _PdfPreviewPageState createState() => _PdfPreviewPageState();
}

class _PdfPreviewPageState extends State<PdfPreviewPage> {
  String lira = '';
  String kurus = '';
  late List<String> tarihparts = widget.senet.tarih.toString().split(' ');
  var format = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

    @override
    Widget build(BuildContext context) {
        return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
                fontFamily: "AbhayaLibre-Medium",

            ),
            home: Scaffold(
                appBar: AppBar(
                    backgroundColor: Colors.white,
                    leading: IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.black),
                        onPressed: () => Navigator.of(context).pop(),
                    ),

                    title: Text( widget.senet.musteri['name'] +' #'+widget.senet.id +' nolu Senedi ve Vadeleri',style: TextStyle(color: Colors.black,fontSize: 20),),
                    toolbarHeight: 60,
                ),

                body: PdfPreview(

                    build: (context) => makePdf(widget.senet.vadeler),
                )

            ),
        );
    }
    Future<Uint8List> makePdf(List<dynamic> vadeler) async {
        final font = await rootBundle.load("assets/AbhayaLibre-Medium.ttf");

        final ttf = pw.Font.ttf(font);
        final pdf = pw.Document();
        int vadeindex= 0;
        vadeler.forEach((element) {
          ++vadeindex;
          if(element['tutar'].toString().contains('.'))
            {
              List<String> parts = element['tutar'].toString().split('.');

              lira = parts[0];
              kurus = parts[1];
            }
          else
            {
              lira = element['tutar'].toString();
              kurus = '00';
            }

          pdf.addPage(
              pw.Page(
                  margin: const pw.EdgeInsets.all(30),
                  pageFormat: PdfPageFormat.a4,
                  build: (context) {
                    return pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [

                          pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                              children: [

                                pw.Text("Ödeme Günü\n"+formattedDate(element['vade_tarih']),style: pw.TextStyle(font:ttf )),
                                pw.Text( "Türk Lirası\n#"+lira+'#',style: pw.TextStyle(font:ttf )),
                                pw.Text( "Kuruş\n#"+kurus+'#', style: pw.TextStyle(font:ttf )),
                                pw.Text( "No\n"+ vadeindex.toString(),style: pw.TextStyle(font:ttf )),

                              ]
                          ),
                          pw.SizedBox(
                            height: 50,
                          ),
                          pw.Text( "İş bu emre yazılı senedimin mukabilinde "+fullFormatDate(element['vade_tarih'])+
                              " tarihinde Sayın "+ widget.senet.musteri['name'] +" veya emruhavalesine. "
                              "Yukarıda yazılı yalnız "+ SpellingNumber(lang: 'tr').convert(int.parse(lira)) +" Türk Lirası"
                              " "+ SpellingNumber(lang: 'tr').convert(int.parse(kurus))+" Kuruş kayıtsız şartsız ödeyeceğim bedeli "
                              "ahzolunmuştur. İş bu emre yazılı senet vadesinde ödenmediği takdirde müteakip bonolarında"
                              "müacceliyet kesbedeceğini,avukat ücreti dahil mahkeme masraflarını ödeyeceğimi, "
                              "ihtilaf vukuunda İZMİR Mahkemelerinin selahiyetini şimdiden "
                              "kabul eylerim.",style: pw.TextStyle(font:ttf )
                          ),
                          pw.SizedBox(
                            height: 40,
                          ),
                          pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                              children: [

                                pw.Column(
                                    crossAxisAlignment: pw.CrossAxisAlignment.start,

                                    children: [

                                      pw.Text("Ad-Soyad/Unvan: "+widget.senet.musteri['name'],style: pw.TextStyle(font:ttf )),

                                      pw.Text("Adres: "+widget.senet.musteri['adres'],style: pw.TextStyle(font:ttf )),

                                      pw.Text("V.No/T.C No: "+widget.senet.musteri['tc_kimlik_no'].toString(),style: pw.TextStyle(font:ttf )),

                                      pw.Text("Kefil (Ad-Soyad):"+widget.senet.kefil_adi,style: pw.TextStyle(font:ttf )),

                                      pw.Text("Adres: "+widget.senet.kefil_adres,style: pw.TextStyle(font:ttf )),


                                      pw.Text("Kefil T.C No: "+widget.senet.kefil_tc_vergi_no.toString(),style: pw.TextStyle(font:ttf )),

                                    ]
                                ),
                                pw.Spacer(),
                                pw.Column(
                                    children: [
                                      pw.SizedBox(
                                        height: 10,
                                      ),
                                      pw.Text("Düzenleme Tarihi: "+formattedDate(tarihparts[0]),style: pw.TextStyle(font:ttf )),
                                      pw.SizedBox(
                                        height: 10,
                                      ),
                                      
                                      pw.Row(
                                          children: [
                                            pw.Text("İmza",style: pw.TextStyle(font:ttf )),
                                            pw.SizedBox(width: 50),
                                            pw.Text("İmza",style: pw.TextStyle(font:ttf )),
                                          ]
                                      )

                                    ]
                                ),

                              ]
                          )
                        ]
                    );
                  }
              ));
        });

        return pdf.save();
    }


}
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:randevu_sistem/yonetici/dashboard/bildirimler/bildirimler_class.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer';



void main() {

  runApp(OkunmusPage());
}

class OkunmusPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      home: BildirimPage(),
    );
  }
}

class BildirimPage extends StatefulWidget {

  @override
  _BildirimPageState createState() => _BildirimPageState();

}

class _BildirimPageState extends State<BildirimPage> {

  late Future<List<SistemBildirimleri>> items;

  @override
  void initState() {
    super.initState();
    items = fetchData();
  }

  Future<List<SistemBildirimleri>> fetchData() async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    var user = jsonDecode(localStorage.getString('user')!);
    var personelid;
    log('userinfo : '+user['yetkili_olunan_isletmeler'].toString());
    var yetkiliolunanisletmeler = jsonDecode(jsonEncode(user['yetkili_olunan_isletmeler']));
    yetkiliolunanisletmeler.forEach((item) {
      if(item['salon_id']==114)
        personelid=item['id'];

    });

    final response = await http.get(Uri.parse('https://app.randevumcepte.com.tr/api/v1/bildirimgetir/114/1/'+personelid.toString()));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      if(data.isNotEmpty)
        return data.map((item) => SistemBildirimleri.fromJson(item)).toList();
      else
        throw Exception("Bildiriminiz bulunmamaktadır");

    } else {

      throw Exception('Failed to load data');
    }
  }
  final _formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: FutureBuilder<List<SistemBildirimleri>>(
        future : items,
        builder:(context,snapshot){
          if(snapshot.connectionState == ConnectionState.waiting)
            return Text("Yükleniyor");
          else if(snapshot.hasError){
            return Text("Veri yüklenirken bir hata oluştu. "+ snapshot.error.toString());
          }
          else
          {
            if(snapshot.hasData){
              final List<SistemBildirimleri> bildirimListe = snapshot.data!;

              return ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: bildirimListe.length,
                itemBuilder: (BuildContext context, int index) {

                  final bildirimData = bildirimListe[index];
                  return Card(
                    elevation: 3.0,
                    margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    child: ListTile(
                      leading: Image.network(
                        width: 30, // Set width as needed
                        height: 30,
                        'https://app.randevumcepte.com.tr${bildirimData.avatar}',
                        loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                          if (loadingProgress == null) {
                            return child;
                          } else {
                            return CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                  : null,
                            );
                          }
                        },
                        errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                          return Image.asset(
                            'images/randevumcepteicon.png', // Replace with your image path
                            width: 30, // Adjust width as needed
                            height: 30, // Adjust height as needed
                          );
                        },
                      ),

                      subtitle: Text("${bildirimData.aciklama}"),
                      trailing: Icon(Icons.chevron_right),

                      onTap: () async {
                        await showDialog<void>(
                          context: context,
                          builder: (context) => AlertDialog(
                            insetPadding: EdgeInsets.zero,
                            content: Container(

                              height: 240,
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
                                      ),
                                    ),
                                  ),

                                  Form(
                                    key: _formKey,
                                    child: Column(

                                      children: <Widget>[

                                        Text('Anıl Orbey Randevu Detayı',style: TextStyle(fontWeight: FontWeight.bold),),
                                        Divider(color: Colors.black,
                                          height: 10,),
                                        Row(
                                          children: [
                                            Text('Telefon'),SizedBox(width: 22,),
                                            Text(':'),
                                            Text(' 5316237563')
                                          ],
                                        ),

                                        Row(
                                          children: [
                                            Text('Hizmet'),
                                            SizedBox(width: 25,),
                                            Text(': '),
                                            Text('Saç Kesimi (Cevriye)')
                                          ],

                                        ),
                                        Row(
                                          children: [
                                            Text('Zaman'),SizedBox(width: 26,),
                                            Text(':'),
                                            Text(' 07.09.2023 17:45')
                                          ],

                                        ),
                                        Row(
                                          children: [
                                            Text('Oluşturan'),SizedBox(width: 7.5,),
                                            Text(':'),
                                            Text(' Web')
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Text('Geldi mi?'),SizedBox(width: 10,),
                                            Text(':'),
                                            Text(' Belirtilmemiş')
                                          ],

                                        ),
                                        Divider(color: Colors.black,
                                          height: 10,),
                                        Row(
                                          children: [
                                            ElevatedButton(onPressed: (){}, child:
                                            Text('Düzenle'),
                                              style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.purple[800],
                                                  elevation: 5,
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(5.0)
                                                  ),
                                                  minimumSize: Size(130,30)
                                              ),
                                            ),
                                            SizedBox(width: 15,),
                                            ElevatedButton(onPressed: (){}, child:
                                            Text('İptal Et'),
                                              style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.black,
                                                  elevation: 5,
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(5.0)
                                                  ),
                                                  minimumSize: Size(130,30)
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            ElevatedButton(onPressed: (){}, child:
                                            Text('Gelmedi'),
                                              style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red,
                                                  elevation: 5,
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(5.0)
                                                  ),
                                                  minimumSize: Size(130,30)
                                              ),
                                            ),
                                            SizedBox(width: 15,),
                                            ElevatedButton(onPressed: (){}, child:
                                            Text('Geldi & Tahsilat'),
                                              style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.green,
                                                  elevation: 5,
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(5.0)
                                                  ),
                                                  minimumSize: Size(20,30)
                                              ),
                                            ),


                                          ],
                                        ),

                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        );
                      },

                    ),

                  );

                },
              );
            }
            else{
              return Text("Bildiriminiz bulunmamaktadır");
            }
          }
        },

      ),
    );
  }
}
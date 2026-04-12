import 'package:flutter/material.dart';


class MusteriOkunmusPage extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: ListView.builder(
        itemCount: 10, // Replace with the number of notifications you have
        itemBuilder: (context, index) {
          return Card(
            elevation: 3.0,
            margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: ListTile(
              leading: Icon(Icons.person_pin_sharp),
              title: Text('Notification Title $index'),
              subtitle: Text('Notification Description $index'),
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
      ),
    );
  }
}

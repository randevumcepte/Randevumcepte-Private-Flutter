
import 'package:flutter/material.dart';

class SatisYapilmadiNot extends StatefulWidget {
    const SatisYapilmadiNot({Key? key}) : super(key: key);

    @override
    _SatisYapilmadiNotState createState() => _SatisYapilmadiNotState();
}

class _SatisYapilmadiNotState extends State<SatisYapilmadiNot> {

    final formKey = GlobalKey<FormState>();
    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                backgroundColor: Colors.white,
                toolbarHeight: 60,

                leading: IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.of(context).pop(),
                ),
                title: Text("Satış Yapılmadı",style: TextStyle(color: Colors.black),),

            ),
            body: Padding( padding: EdgeInsets.all(8),
                child: Form(
                    key: formKey,
                    child: ListView(

                        children: [
                            SizedBox(height: 10,),
                            Padding(
                                padding: const EdgeInsets.only(left: 5.0),
                                child: Text('Satış Yapılma',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                            ),
                            SizedBox(height: 10,),
                            Container(
                                height: 40,
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


                            SizedBox(height: 20,),
                            ElevatedButton(onPressed: (){},
                                child: Text('Kaydet'),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    minimumSize: Size(90, 40)
                                ),
                            ),
                        ],
                    ),

                ),
            ),

        );
    }





}
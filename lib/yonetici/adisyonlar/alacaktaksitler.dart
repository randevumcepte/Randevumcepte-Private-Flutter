import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AlacakTaksitler extends StatefulWidget {
  @override
  _AlacakTaksitlerState createState() => _AlacakTaksitlerState();
}

class _AlacakTaksitlerState extends State<AlacakTaksitler> {
  List<bool> _checkBoxValues = List.generate(10, (index) => false);


  TextEditingController dateInput = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _checkBoxValues.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Row(
            children: [
              Checkbox(
                value: _checkBoxValues[index],
                onChanged: (newValue) {
                  setState(() {
                    _checkBoxValues[index] = newValue!;
                  });
                },
              ),
              Expanded(child: Text('Vade ${index + 1} : 2.450 ₺')),
              ElevatedButton(
                onPressed: () {
                  _showPopupDialog(context, index);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple[800],
                  minimumSize: Size(100, 30),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                ),
                child: Text('05.04.2024'),
              ),
            ],
          ),


        );
      },
    );
  }

  void _showPopupDialog(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Taksit Güncelleme'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Container(
                padding: const EdgeInsets.only(left: 20.0),
                child: Text('Ödeme Tarihi',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
              ),
              SizedBox(height: 10,),
              Container(
                height: 40,
                padding: EdgeInsets.only(left:20,right: 20),
                child: TextField(
                  controller: dateInput,
                  //editing controller of this TextField
                  decoration: InputDecoration(

                    focusColor:Color(0xFF6A1B9A) ,
                    hoverColor: Color(0xFF6A1B9A) ,
                    hintStyle: TextStyle(color:  Color(0xFF6A1B9A)),
                    contentPadding:  EdgeInsets.all(0.0),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(
                        color: Color(0xFF6A1B9A)),borderRadius: BorderRadius.circular(10.0),),
                    border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10.0),),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF6A1B9A),), borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  readOnly: true,
                  //set it true, so that user will not able to edit text

                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(1950),
                        //DateTime.now() - not to allow to choose before today.
                        lastDate: DateTime(2100));

                    if (pickedDate != null) {
                      print(
                          pickedDate); //pickedDate output format => 2021-03-10 00:00:00.000
                      String formattedDate =
                      DateFormat('yyyy-MM-dd').format(pickedDate);
                      print(
                          formattedDate); //formatted date output using intl package =>  2021-03-16
                      setState(() {
                        dateInput.text =
                            formattedDate; //set output date to TextField value.
                      });
                    } else {}
                  },
                ),
              ),
              SizedBox(height: 10,),
              Container(
                padding: const EdgeInsets.only(left: 20.0),
                child: Text('Not',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
              ),
              SizedBox(height: 10,),
              Container(
                height: 40,

                padding: EdgeInsets.only(left:20,right: 20),
                child: TextField(

                  keyboardType: TextInputType.text,



                  decoration: InputDecoration(

                    focusColor:Color(0xFF6A1B9A) ,

                    hoverColor: Color(0xFF6A1B9A) ,
                    filled: true,
                    fillColor: Colors.white,
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
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[800],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
                minimumSize: Size(50, 30)
              ),
              child: Text('İptal Et'),
            ),
            ElevatedButton(
              onPressed: () {
                // Perform save operation
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple[800],
                shape:RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
                  minimumSize: Size(80, 30)
              ),
              child: Text('Vadeyi Güncelle'),
            ),
          ],
        );
      },
    );
  }
}

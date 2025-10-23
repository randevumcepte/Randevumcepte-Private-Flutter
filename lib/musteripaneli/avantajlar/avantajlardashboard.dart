import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:random_string/random_string.dart';


import '../anasayfa/anasayfa.dart';


class CardListDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        floatingActionButton: WhatsAppFAB(),
        appBar: AppBar(
          title: Text('Avantajlarım',style: TextStyle(color: Colors.black),),
          toolbarHeight: 60,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
          backgroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          child: Column(// You can use Column instead of ListView if you have a small number of cards and they fit on the screen without scrolling
            children: <Widget>[
              CardWidget("Uygulamaya Özel İndirim","Uygulamayı ilk defa indirenlere lazer paketinde 300 TL indirim", Icons.campaign, Color(0xFF6A1B9A), 36.0),
              CardWidget("Uygulamaya Özel İndirim","Uygulamayı ilk defa indirenlere lazer paketinde 300 TL indirim",Icons.campaign,  Color(0xFF6A1B9A), 36.0),
              CardWidget("Uygulamaya Özel İndirim","Uygulamayı ilk defa indirenlere lazer paketinde 300 TL indirim",Icons.campaign,  Color(0xFF6A1B9A), 36.0),
              // Add more CardWidget campaign as needed
            ],
          ),
        ),
      ),
    );
  }
}

class CardWidget extends StatelessWidget {
  String phoneNumber = "5383792106"; // Replace with the recipient's phone number


  void sendSMS(String phoneNumber, String confirmationCode) {

  }

  String generateRandomCode() {
    return randomAlphaNumeric(6); // Generates a 6-character alphanumeric code
  }

  final String cardTitle;
  final String cardaciklama;
  final IconData icon;
  final Color iconColor;
  final double iconSize;

  CardWidget(this.cardTitle,this.cardaciklama, this.icon, this.iconColor, this.iconSize);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
      child: Card(
        margin: EdgeInsets.all(16.0),

        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: <Widget>[
                    Icon(
                      icon,
                      size: iconSize,
                      color: iconColor,
                    ),
                    SizedBox(width: 16.0), // Spacing between the icon and text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cardTitle,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                            style: TextStyle(fontSize: 16.0,fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 10,),
                          Expanded(
                            child: Container(
                              width: 300,
                              child: Text(cardaciklama,
                                maxLines: 10,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 14,),
                              ),
                            ),
                          ),

                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              color: Color(0xFF6A1B9A),
              height: 50,
              width: double.infinity,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text("Kodunuzu şimdi alın,faydayı kaçırmayın.",style: TextStyle(color: Colors.white,fontSize: 12),maxLines: 5,overflow: TextOverflow.ellipsis,),
                  ElevatedButton(onPressed: (){
                    String confirmationCode = generateRandomCode();
                    sendSMS(phoneNumber, confirmationCode);
                    // Optionally, display a confirmation message.
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('SMS sent with confirmation code: $confirmationCode'),
                      ),
                    );

                  }, child: Text('Kodu Al',style: TextStyle(color: Colors.purple[800]),),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                  )

                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
class WhatsAppFAB extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 65.0,
      height: 65.0,
      child: FloatingActionButton(
        onPressed: () {
          // Handle the FAB press
          WhatsAppOpener.openWhatsApp('+902323130028', '');
        },
        backgroundColor: Color(0xFF25D366), // WhatsApp green color
        child: SvgPicture.asset(
          'images/wp5.svg', // Replace with the actual path to your WhatsApp SVG icon
          width: 30,
          height: 40,
          color: Colors.white,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

void main() {
  runApp(MaterialApp(
    home: VotingCommentPage(),
  ));
}

class VotingCommentPage extends StatefulWidget {
  @override
  _VotingCommentPageState createState() => _VotingCommentPageState();
}

class _VotingCommentPageState extends State<VotingCommentPage> {
  double rating = 1.0;
  TextEditingController commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Puanla ve Yorumla',style: TextStyle(color: Colors.black,fontSize: 18),),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.white,

        toolbarHeight: 60,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(height: 10,),
            Text('Puanlama',style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold),),
            SizedBox(height: 10,),
            RatingBar.builder(
              initialRating: rating,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemSize: 40.0,
              itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
              itemBuilder: (context, _) => Icon(
                Icons.star,
                color: Colors.amber,
              ),
              onRatingUpdate: (newRating) {
                setState(() {
                  rating = newRating;
                });
              },
            ),
            SizedBox(height: 20),
            Text('Yorum',style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold),),
            SizedBox(height: 10),
            TextFormField(
              controller: commentController,
              maxLines: 6,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Yorumunuzu Yazın',
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Handle the submission of the rating and comment here
                    print('Rating: $rating');
                    print('Comment: ${commentController.text}');
                  },
                  child: Text('Gönder',style: TextStyle(fontWeight: FontWeight.bold,fontSize: 18),),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.purple[800],minimumSize: Size(150, 40)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

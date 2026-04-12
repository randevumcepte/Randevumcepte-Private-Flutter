import 'package:flutter/material.dart';
import 'package:randevu_sistem/musteripaneli/anasayfa/anasayfa.dart';
import 'package:video_player/video_player.dart';



class VideoBackgroundHomePage extends StatefulWidget {
  @override
  _VideoBackgroundHomePageState createState() => _VideoBackgroundHomePageState();
}

class _VideoBackgroundHomePageState extends State<VideoBackgroundHomePage> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('images/video3.mp4')
      ..initialize().then((_) {
        // Ensure the first frame is shown before setting state
        setState(() {});
        _controller.setVolume(0.0); // Mute the video
        _controller.play();
      });
    _controller.setLooping(true); // Loop the video
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: <Widget>[
          // Video background
          _controller.value.isInitialized
              ? SizedBox(
            height: screenHeight, // Set the video height to the screen height
            width: screenHeight * _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          )
              : Container(),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: double.infinity, // Adjust the height of the transparently opaque bottom as needed
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(1.0), // Adjust opacity as needed


                  ],
                ),
              ),
            ),
          ),
          // Other widgets on top of the video
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 16.0,left: 16),
                child: Text(
                  'RandevumCepte',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 33.0,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0,left: 16),
                child: Text(
                  'Zaman Şimdi Kontrolünüzde',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.0,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0,left: 16),
                child: Text(
                  'Yeni Nesil. Kolay. Güvenilir.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 27.0,
                    fontWeight: FontWeight.bold
                  ),
                ),
              ),
              SizedBox(height: 10,),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        // Handle button tap
                      },
                      child: Text('Başla',style: TextStyle(fontSize: 20),),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple[800],
                        elevation: 10,
                        minimumSize: Size(180, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12), // <-- Radius
                        ),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () {},
                      child: Text('Detaylı Bilgi',style: TextStyle(color: Colors.white,fontSize: 20),),
                      style: OutlinedButton.styleFrom(
                      side: BorderSide(width: 2.0,color: Colors.white),
    minimumSize: Size(150, 50),
                        elevation: 20,
                        shape: RoundedRectangleBorder(

                          borderRadius: BorderRadius.circular(12),

                        ),
                      ),
                    )
                  ],
                ),
              ),
              SizedBox(height: 25,),

            ],
          ),


        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose(); // Dispose of the video player controller
  }
}

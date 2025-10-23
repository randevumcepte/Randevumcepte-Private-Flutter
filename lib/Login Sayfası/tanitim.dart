import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Login%20Sayfas%C4%B1/checklogin.dart';
import 'package:randevu_sistem/musteripaneli/anasayfa/anasayfa.dart';
import 'package:video_player/video_player.dart';


import '../randevualma/randevual.dart';
import 'login_page.dart';



class OnBoardingPage extends StatefulWidget {
  @override
  _VideoBackgroundHomePageState createState() => _VideoBackgroundHomePageState();
}

class _VideoBackgroundHomePageState extends State<OnBoardingPage> {
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

    return PopScope(
        canPop: false, // direkt çıkışı engelle
        onPopInvokedWithResult: (didPop, result) async {
          if (!didPop) {
            bool? confirmExit = await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Uygulamadan çık'),
                content: Text('Çıkmak istediğinize emin misiniz?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text('Hayır'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text('Evet'),
                  ),
                ],
              ),
            );

            if (confirmExit == true) {
              SystemNavigator.pop(); // uygulamayı kapat
              // veya exit(0); // (zorla kapatma)
            }
          }
        },
      child:  Scaffold(
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
                    'Aron Güzellik',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 33.0,
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(top: 8.0,left: 16),
                  child: Text(
                    'Randevularınızı, satışlarınızı ve borçlarınızı kolaylıkla takip edin. Kampanyalarımızdan haberdar olun. Randevularınız ve borçlarınız hatırlatılsın.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.0,

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
                          // Navigate to LoginPage when the button is pressed
                          _pauseVideo();
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => CheckAuth()),
                          ).then((_) {
                            // Geri dönüldüğünde video tekrar başlasın
                            _resumeVideo();
                          });
                        },
                        child: Text(
                          'Kullanıcı Girişi',
                          style: TextStyle(fontSize: 20),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple[800],
                          foregroundColor: Colors.white,
                          elevation: 10,
                          minimumSize: Size(180, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12), // <-- Radius
                          ),
                        ),
                      ),

                      OutlinedButton(
                        onPressed: () {
                          _pauseVideo();
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => RandevuAl()),
                          ).then((_) {
                            // Geri dönüldüğünde video tekrar başlasın
                            _resumeVideo();
                          });
                        },
                        child: Text('Randevu Al',style: TextStyle(color: Colors.white,fontSize: 20),),
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
      )
    );

  }
  void _pauseVideo() {
    _controller.pause();
    //_controller.dispose();
  }

  void _resumeVideo() {
    _controller = VideoPlayerController.asset('images/video3.mp4')
      ..initialize().then((_) {
        setState(() {});
        _controller.setVolume(0.0);
        _controller.play();
        _controller.setLooping(true);
      });
  }
  @override
  void dispose() {
    _controller.dispose(); // Dispose of the video player controller
    super.dispose();

  }
}

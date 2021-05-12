import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app2/game.dart';

import 'ads.dart';

class Menu extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _MenuState();
}

class _MenuState extends State<Menu> {
  var duration = Duration(milliseconds: 600);
  bool inMenu = true;
  // var game;
  var sigma = 4.0;


  @override
  void initState() {
    super.initState();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp
    ]);


   // game = Game();

    Future.delayed(Duration(seconds: 1), () {

    });
  }

  @override
  Widget build(BuildContext context) {
    if (!inMenu) {
      if (myBanner != null) {
        print('dispose');
        myBanner.dispose();
        myBanner = null;
      }
    } else {
      if (myBanner != null) {
        myBanner.dispose();
        print('dispose 2');
      }
      print('new banner');
/*      myBanner = BannerAd(
        adUnitId: BannerAd.testAdUnitId,
        size: AdSize.smartBanner,
        targetingInfo: targetingInfo,
        listener: (MobileAdEvent event) {
          print("BannerAd event is $event");
        },
      );*/

/*      myBanner
        ..load()
        ..show(
          anchorOffset: 0.0,
          horizontalCenterOffset: 0.0,
          anchorType: AnchorType.bottom,
        );*/
    }

    return WillPopScope(
      onWillPop: () {
        if (inMenu) {
          Navigator.of(context).pop();
        } else {
          setState(() {
            inMenu = true;
          });
        }
      },
      child: Scaffold(
          body: Stack(
        children: [
          // game,
          Center(
            child: AnimatedSwitcher(
              child: inMenu ? Stack(
                children: [
                  BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
                      child: Container(
                        color: Colors.white.withOpacity(0.2),
                      )),
                  Container(
                      padding: EdgeInsets.all(16),
                      alignment: Alignment.center,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Align(
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                MaterialButton(
                                  onPressed: () => setState(() {
                                    Navigator.of(context).push(MaterialPageRoute(builder: (context) => Game.load()));
                                    inMenu = false;
                                  }),
                                  color: Colors.greenAccent[400],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16.0),
                                    side: BorderSide(color: Colors.white),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.play_circle_outline,
                                          color: Colors.white,
                                          size: 80,
                                        ),
                                        Text(
                                          'Continue',
                                          style: TextStyle(
                                              color: Colors.white, fontSize: 20),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 120,
                                        child: MaterialButton(
                                          onPressed: () => setState(() {
                                            inMenu = false;
                                          }),
                                          color: Colors.greenAccent[400],
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                            BorderRadius.all(Radius.circular(12)),
                                            side: BorderSide(color: Colors.white),
                                          ),
                                          child: Padding(
                                            padding: EdgeInsets.all(8),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.info_outline,
                                                  color: Colors.white,
                                                  size: 40,
                                                ),
                                                Text(
                                                  'Info',
                                                  style: TextStyle(
                                                      color: Colors.white, fontSize: 16),
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width: 120,
                                        child: MaterialButton(
                                          onPressed: () {
                                            setState(() {
                                              Navigator.of(context).push(MaterialPageRoute(builder: (context) => Game()));
                                              // game = Game();
                                              inMenu = false;
                                            });
                                          },
                                          color: Colors.greenAccent[400],
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                            BorderRadius.all(Radius.circular(12)),
                                            side: BorderSide(color: Colors.white),
                                          ),
                                          child: Padding(
                                            padding: EdgeInsets.all(8),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.refresh,
                                                  color: Colors.white,
                                                  size: 40,
                                                ),
                                                Text(
                                                  'Restart',
                                                  style: TextStyle(
                                                      color: Colors.white, fontSize: 16),
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Align(
                            alignment: Alignment(0, 0.7),
                            child: SizedBox(
                              height: 140,
                              child: ListView(
                                shrinkWrap: true,
                                scrollDirection: Axis.horizontal,
                                children: [
                                  getDLC('DLC 1', Colors.lightBlue),
                                  getDLC('DLC 2', Colors.redAccent[200]),
                                  getDLC('DLC 3', Colors.purpleAccent[400]),
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                ],
              ) : Container(),
              duration: duration,
            ),
          )
        ],
      )),
    );
  }

  Widget getDLC(text, color) {
    return AspectRatio(
      aspectRatio: 3/4,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GestureDetector(
          onTap:() {
            Navigator.of(context).push(
              new PageRouteBuilder(
                opaque: false,
                transitionDuration: Duration(milliseconds: 600),
                fullscreenDialog: true,
                barrierDismissible: true,
                pageBuilder: (context, animation, secondaryAnimation) {
                  return StatefulBuilder(
                    builder: (context, setState)
                    {
                      return AlertDialog(
                        elevation: 0,
                        backgroundColor: Colors.transparent,
                        contentPadding: EdgeInsets.only(top: 8),
                        content: Hero(
                          tag: text,
                          child: LimitedBox(
                            maxWidth: MediaQuery.of(context).size.width/1.5,
                            child: Material(
                              elevation: 20,
                              color: Colors.transparent,
                              child: ClipRRect(
                                borderRadius: BorderRadius.all(Radius.circular(16)),
                                child: Container(
                                  color: color,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: Column(
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            crossAxisAlignment: CrossAxisAlignment.stretch,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              AspectRatio(
                                                aspectRatio: 1,
                                                child: ClipRRect(
                                                  clipBehavior: Clip.antiAlias,
                                                  child: Align(
                                                    alignment: Alignment.center,
                                                    child: LimitedBox(
                                                        maxHeight: 300, maxWidth: 300, child: Text('some text')),
                                                  ),
                                                ),
                                              ),
                                              AspectRatio(
                                                aspectRatio: 1/0.5,
                                                child: ClipRRect(
                                                  clipBehavior: Clip.antiAlias,
                                                  child: Padding(
                                                    padding: const EdgeInsets.only(top: 12.0),
                                                    child: InkWell(
                                                      onTap: () {
                                                        Navigator.of(context, rootNavigator: true).pop();
                                                      },
                                                      child: Container(
                                                          padding: EdgeInsets.only(top: 32.0, bottom: 32.0),
                                                          decoration: BoxDecoration(
                                                            color: darken(color, 0.1),
                                                            borderRadius: BorderRadius.only(
                                                                bottomLeft: Radius.circular(16.0),
                                                                bottomRight: Radius.circular(16.0)),
                                                          ),
//                              child: Icon(Icons.check_circle_outline, color: Colors.amberAccent, size: 56,),
                                                          child: Icon(Icons.check_circle, color: darken(color, -0.3))),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ]),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );},
                  );
                },),
            );
          },
          child: Hero(
            tag: text,
            child: Material(
                elevation: 20,
                color: Colors.transparent,
                child: ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                  child: Container(
                    color: color,
                    child: FittedBox(
                      alignment: Alignment.center,
                      fit: BoxFit.scaleDown,
                      child: Text(text, style: TextStyle(
                        color: Colors.white,
                      ),),
                    ),
                  ),)
            ),
          ),
        ),
      ),
    );
  }

  Color darken(Color color, [double amount = .1]) {
  /*  assert(amount >= 0 && amount <= 1);*/

    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));

    return hslDark.toColor();
  }

}

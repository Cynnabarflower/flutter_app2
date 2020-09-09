import 'package:firebase_admob/firebase_admob.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app2/routes.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Flame.images.load('Goblin/Idle.png');
//  await Flame.images.load('water1.png');
  await Flame.images.load('coin.png');
  runApp(App());
  SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
}

class App extends StatefulWidget {

  @override
  State<StatefulWidget> createState() => _AppState();

}

class _AppState extends State<App> {



  @override
  Widget build(BuildContext context) {
    print("build main");
    return MaterialApp(
      title: 'App',
      initialRoute: '/',
      routes: routes,
    );
  }

  @override
  void initState() {
    super.initState();
    FirebaseAdMob.instance.initialize(appId: 'ca-app-pub-8562826557471441~7861153543');
  }
}


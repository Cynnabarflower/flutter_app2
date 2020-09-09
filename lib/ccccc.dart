import 'package:flutter/material.dart';

import 'enemies.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  @override
  void initState() {
    super.initState();
  }



  @override
  Widget build(BuildContext context) {

/*
    if (_animation == null || !_animation.loaded()) {
      Future.delayed(Duration(milliseconds: 500),() => setState((){}));
      return Container();
    }
*/

    return Scaffold(
      body: EnemyCard('Goblin/Idle.png'),
    );
  }
}
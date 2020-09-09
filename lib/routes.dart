import 'package:flutter/cupertino.dart';

import 'game.dart';
import 'menu.dart';

final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
  "/Game": (BuildContext context) => Game(),
  "/": (BuildContext context) => Menu(),
};
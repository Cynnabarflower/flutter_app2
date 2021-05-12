import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'cells.dart';
import 'game.dart';


extension GlobalKeyExtension on GlobalKey {
  Rect get globalPaintBounds {
    final renderObject = currentContext?.findRenderObject();
    var translation = renderObject?.getTransformTo(null)?.getTranslation();
    if (translation != null && renderObject.paintBounds != null) {
      return renderObject.paintBounds
          .shift(Offset(translation.x, translation.y));
    } else {
      return null;
    }
  }
}

class TopLayer extends StatefulWidget {

  List<Widget> flyingObjects = [];
  StreamController flyingStreamController = StreamController.broadcast();

  TopLayer() : super(key: GlobalKey()) {

  }

  Future wallAttack(GameCell gameCell, {Function callback}) async {
    var bounds = (gameCell.key as GlobalKey).globalPaintBounds;
    var boundsWall = ((game.town.map.firstWhere((e) => e is WallCell)).key as GlobalKey).globalPaintBounds;
    var arrowSide = game.battlefield.cellSide/2;

    var offset = Offset(boundsWall.left + game.town.cellSide/2, boundsWall.top + game.town.cellSide/2);
    var movingTo = bounds.center.translate(-arrowSide/2, -arrowSide/2);
    var len = (offset.dx - movingTo.dx) * (offset.dx - movingTo.dx) + (offset.dy - movingTo.dy) * (offset.dy - movingTo.dy);
    var duration = Duration(milliseconds: (sqrt(len) / (gameCell.getCellSide()) * 100).floor());


    Widget arrow = SizedBox(
      width: arrowSide,
      height: arrowSide,
      child: Transform.rotate(
        angle: atan2(movingTo.dy - offset.dy, movingTo.dx - offset.dx) + pi/2,
        child: Image(
          image: AssetImage("assets/images/arrow.gif"),
          fit: BoxFit.fill,
        ),
      ),
    );
    Widget tweenWidget;

    tweenWidget = TweenAnimationBuilder(
      key: GlobalKey(),
      duration: duration,
      tween: Tween<
          double>(
          begin: 0,
          end: 1),
      builder: (context,
          value, child) {
        return Positioned(
            top: offset.dy + (movingTo.dy - offset.dy) * value,
            left: offset.dx + (movingTo.dx - offset.dx) * value,
            child: child);
      },
      child: arrow,
      onEnd: () {
        flyingObjects.remove(tweenWidget);
        flyingStreamController.add(tweenWidget);
        callback?.call();
        (this.key as GlobalKey).currentState?.setState(() { });
        // print('end $cell / $selectedCells');
        // movedStreamController.add(cell);
      },
    );
    flyingObjects.add(tweenWidget);
    Future f = flyingStreamController.stream.firstWhere((element) => element == tweenWidget).timeout(Duration(seconds: 3));
    (this.key as GlobalKey).currentState?.setState(() { });
    return f;
  }

  @override
  State createState() => _TopLayerState();
}

class _TopLayerState extends State<TopLayer> {

  @override
  Widget build(BuildContext context) {
    print('build topLayer ${widget.flyingObjects}');
    return Stack(
      fit: StackFit.expand,
      children: widget.flyingObjects,
    );
  }
}
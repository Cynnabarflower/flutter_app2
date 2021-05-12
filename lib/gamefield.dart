import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'cells.dart';
import 'game.dart';

abstract class Gamefield extends StatefulWidget {

  List<GameCell> map = [];
  var h = 0;
  var w = 0;
  double cellSide;
  List<GameCard> queue = [];
  var movingSpeed = 1.0;
  var dragItem;
  List<GameCell> selectedCells = [];
  List<GameCell> movingCells = [];
  StreamController<GameCell> selectedStreamController = StreamController.broadcast();
  StreamController<GameCell> movedStreamController = StreamController.broadcast();

  bool selecting = false;
  Function stateStep;
  var gameConstrains;

  void init();
  void generateCard();

  Gamefield({this.h, this.w, key}) : super(key: key) {

    movedStreamController.stream.listen((event) {
      if (!movingCells.contains(event)){
        if (event.offset == event.movingTo) {
          print('Move already there $event');
          movingCells.add(event);
          movedStreamController.add(event);
          return;
        } else {
          print('Move new $event');
          event.builderKey = GlobalKey();
          movingCells.add(event);
        }
      } else if (event.offset == event.movingTo) {
        print('Move complete $event');
        movingCells.remove(event);
      }
        (key as GlobalKey).currentState?.setState(() {});
    });
    init();
  }

  Future step() async {
    stateStep?.call();
    return Future.value();
  }

  @override
  State createState() => _GameFieldState();

  Duration getMoveDuration(GameCell cell) {
    return Duration(
        milliseconds: (cell.movingTo -
            cell.offset)
            .distance <
            cellSide/2
            ? 100
            : 600);
  }

  Future<List<GameCell>> selectCells(int quan, {willUpdateState = true, willClearAfter = true, showMessage = false}) async {
    game.selecting = true;

    if (showMessage) {
      game.chooserKey.currentState.showMessage(
          FittedBox(
            fit: BoxFit.fitWidth,
            child: Text("Choose $quan cells to swap", style: TextStyle(
                fontSize: 120,
                color: Colors.white
            ),),
          ));
    }

    selectedStreamController = StreamController.broadcast();
    return selectedStreamController.stream.listen((event) {
      if (selectedCells.contains(event)) {
        selectedCells.remove(event);
        event.resetOffset();
        if (willUpdateState)
          (key as GlobalKey).currentState?.setState(() {});
      } else {
        if (event != null) {
          selectedCells.add(event);
          event.markSelected();
        }
        if (willUpdateState)
          (key as GlobalKey).currentState?.setState(() {});
        if (selectedCells.length == quan || event == null) {
          selectedStreamController.close();
          game.selecting = false;
          print('sc $selectedCells');
        }
      }

    }).asFuture().then((value) {
      if (showMessage) {
        game.chooserKey.currentState.hideMessage();
      }

      var t = List.of(selectedCells);
      if (willClearAfter) {
        selectedCells.clear();
        if (willUpdateState)
          (key as GlobalKey).currentState?.setState(() {});
      }
      return t;
    });
  }

  void setCell(GameCell cell, {i, j, isDragTarget}) {
    print('setCell $cell');
    i = i ?? cell.i;
    j = j ?? cell.j;
    var candidate = map.where((element) => element.i == i && element.j == j);
    if (candidate.isEmpty) {
      map.add(cell
        // ..isDragTarget = isDragTarget ?? cell.isDragTarget
        ..setCoordinates(i, j));
      // throw Exception('wtf1 setCell');
    } else if (candidate.length == 1) {
      map[map.indexOf(candidate.first)] = cell
        // ..isDragTarget = isDragTarget ?? cell.isDragTarget
        ..setCoordinates(i, j);
    }
    else {
      throw Exception('wtf2 setCell');
    }
  }

  bool isDragTarget(GameCell cell, data) {
    return cell != null && cell.i != null && cell.j != null;
  }

  void resetCellPositions() {
    for (var i = 0; i < map.length; i++) {
      map[i].resetOffset();
      (map[i].key as GlobalKey).currentState?.setState(() {});
    }
  }

  Widget buildBackground() {
    return Container();
  }

  Widget unmarkAll() {
    selectedCells.clear();
    selecting = false;
    // movedStreamController.add(null);
    // selectedStreamController.add(null);
    map.forEach((element) {element.setSelected();});
  }

  Widget buildArea() {
    return Stack(
      // alignment: Alignment.center,
      fit: StackFit.expand,
      children: [
        buildBackground(),
        LayoutBuilder(builder: (context, constraints) {
          if (gameConstrains != constraints) {
            gameConstrains = constraints;
            print('const: $constraints');
            cellSide = constraints.maxWidth / (w * 1.1);
            resetCellPositions();
            movingSpeed = cellSide / 1000;
          }
          cellSide = constraints.maxWidth / (w * 1.1);

          loadComplete = true;
          return Stack(
            children: [
              Container(
                alignment: Alignment.center,
                child: SizedBox(
                  width: cellSide * w,
                  height: cellSide * (h),
                  child: Stack(
                      clipBehavior: Clip.none,
                      children: []
                        ..addAll(List
                            .generate(
                          map.length,
                              (i) {
                            return Positioned(
                                top: map[i]
                                    .offset
                                    .dy,
                                left: map[i]
                                    .offset
                                    .dx,
                                child:
                                map[i]);
                          },
                        )..removeWhere((element) =>
                        selectedCells.contains((element
                        as Positioned)
                            .child) || movingCells.contains((element
                        as Positioned)
                            .child)))
                        ..add(Stack(
                            children: List.generate(
                                selectedCells.length,
                                    (index) =>
                                    Builder(builder: (context) {
                                      var cell = selectedCells[index];

                                      return TweenAnimationBuilder(
                                        key: cell.builderKey,
                                        duration: getMoveDuration(cell),
                                        tween: Tween<
                                            double>(
                                            begin: 0,
                                            end: 1),
                                        builder: (context,
                                            value, child) {
                                          var c = child as GameCell;
                                          return Positioned(
                                              top: c.offset
                                                  .dy + (c
                                                  .movingTo
                                                  .dy -
                                                  c.offset
                                                      .dy) *
                                                  value,
                                              left: c.offset
                                                  .dx + (c
                                                  .movingTo
                                                  .dx -
                                                  c.offset
                                                      .dx) *
                                                  value,
                                              child: Container(
                                                  decoration: BoxDecoration(
                                                      boxShadow: [
                                                        BoxShadow(
                                                            offset: c
                                                                .image !=
                                                                null
                                                                ? Offset(
                                                                cellSide /
                                                                    40,
                                                                cellSide /
                                                                    40)
                                                                : Offset(
                                                                0,
                                                                0),
                                                            color: Colors
                                                                .black
                                                                .withOpacity(
                                                                0.3),
                                                            blurRadius: c
                                                                .image !=
                                                                null
                                                                ? cellSide /
                                                                60
                                                                : 0,
                                                            spreadRadius: 0)
                                                      ]),
                                                  child: child));
                                        },
                                        child: cell,
                                        onEnd: () {
                                          cell.offset = cell.movingTo;
                                          // print('end $cell / $selectedCells');
                                          movedStreamController.add(cell);
                                        },
                                      );
                                    })
                            ).reversed.toList()
                          /*..sort((a, b) {
                                    var d =
                                        ((a as TweenAnimationBuilder).child as GameCell).offset - ((b as TweenAnimationBuilder).child as GameCell).offset;
                                    var r = d.dy.abs() > cellSide / 2
                                        ? d.dy
                                        : d.dx;
                                    return r
                                        .floor();
                                  })*/))
                        ..add(Stack(
                            children: List.generate(
                                movingCells.length,
                                    (index) =>
                                (Builder(builder: (context) {
                                  var cell = movingCells[index];

                                  return TweenAnimationBuilder(
                                    key: cell.builderKey,
                                    duration: getMoveDuration(cell),
                                    tween: Tween<
                                        double>(
                                        begin: 0,
                                        end: 1),
                                    builder: (context,
                                        value, child) {
                                      var c = child as GameCell;
                                      return Positioned(
                                          top: c.offset
                                              .dy + (c
                                              .movingTo
                                              .dy -
                                              c.offset
                                                  .dy) *
                                              value,
                                          left: c.offset
                                              .dx + (c
                                              .movingTo
                                              .dx -
                                              c.offset
                                                  .dx) *
                                              value,
                                          child: Container(
                                              decoration: BoxDecoration(
                                                  boxShadow: [
                                                    BoxShadow(
                                                        offset: c
                                                            .image !=
                                                            null
                                                            ? Offset(
                                                            cellSide /
                                                                40,
                                                            cellSide /
                                                                40)
                                                            : Offset(
                                                            0,
                                                            0),
                                                        color: Colors
                                                            .black
                                                            .withOpacity(
                                                            0.3),
                                                        blurRadius: c
                                                            .image !=
                                                            null
                                                            ? cellSide /
                                                            60
                                                            : 0,
                                                        spreadRadius: 0)
                                                  ]),
                                              child: child));
                                    },
                                    child: cell,
                                    onEnd: () {
                                      cell.offset = cell.movingTo;
                                      // print('end $cell / $selectedCells');
                                      movedStreamController.add(cell);
                                    },
                                  );
                                }) as Widget)
                            ).reversed.toList()

                          /*..sort((a, b) {
                                    var d =
                                        ((a as TweenAnimationBuilder).child as GameCell).offset - ((b as TweenAnimationBuilder).child as GameCell).offset;
                                    var r = d.dy.abs() > cellSide / 2
                                        ? d.dy
                                        : d.dx;
                                    return r
                                        .floor();
                                  })*/))
                  ),
                ),
              ),
              Visibility(
                visible: dragItem is EventCard,
                child:
                Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: cellSide * w + cellSide/10,
                    height: cellSide * (h) + cellSide/10,
                    child: DragTarget(
                        onAccept: (EventCard data) {
                          unmarkAll();
                          dragItem = null;
                          game.chooserKey.currentState.remove(data);
                          data.activate();
                        },
                        builder: (context, candidateData, rejectedData) {
                          return Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.4),
                                borderRadius: BorderRadius.all(Radius.circular(4))),
                          );
                        }),
                  ),
                ),
              )
            ],
          );
        }),
      ],
    );
  }

}


class _GameFieldState extends State<Gamefield> {
  int w;
  int h;

  @override
  Widget build(BuildContext context) {
    return widget.buildArea();
  }

  void step() {
    widget.selectedCells.clear();
    widget.map.forEach((element) {element.step();});
    // while (widget.queue.length < 4) widget.generateCard();
    setState(() {});
  }

  @override
  void initState() {
    widget.stateStep = step;
    w = widget.w;
    h = widget.h;
    widget.resetCellPositions();
    super.initState();
  }


}
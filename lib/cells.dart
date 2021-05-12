import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app2/creatureCells.dart';
import 'package:flutter_app2/gamefield.dart';
import 'package:flutter_app2/slide_fade_transition.dart';

import 'game.dart';

class GameCellLevel {
  // for 1 pers/turn
  int income;

  // till turn
  int rent;

  // max pers
  int capacity;

  //cards to next lvl
  int steps;

  List<MapEntry<Type, int>> entertainments = [];

  GameCellLevel(this.steps, this.rent, this.income, this.capacity,
      {this.entertainments});

  @override
  String toString() {
    return 'inc: $income, rent: $rent, cap: $capacity, steps: $steps';
  }
}

class GameCell extends StatefulWidget {
  @override
  State createState() => _GameCellState();
  var i = null;
  var j = null;
  Widget child;
  Widget selectedChild = Container(alignment: Alignment.center, color: Colors.transparent);

  Widget setSelected({Color color, child}) {
    assert(color == null || child == null);
    selectedChild = child ?? Container(alignment: Alignment.center, color: color ?? Colors.transparent);
  }

  void markSelected() {
    if (image != null)
      movingTo = offset + Offset(-getCellSide() / 20, -getCellSide() / 20);
  }

  void placed() {
    print('Placed $this');
    game.step();
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return '${super.toString()} $i $j offset: $offset ${movingTo == offset ? '': 'movingto: $movingTo'}';
  }

  List<GameCellLevel> levels = [
    GameCellLevel(0, 0, 0, 0),
  ];

  var level = 0;
  var price = 0;
  var currentStep = 0;
  int fill = 0;
  var happiness = 0.0;
  bool isLiving = false;
  AssetImage image;
  bool draggable = false;
  int freezeTimer = 0;
  Offset offset = Offset(0, 0);
  Offset movingTo = Offset(0, 0);
  GlobalKey builderKey = GlobalKey();
  var entertainments = [];
  Gamefield gamefield;
  Widget descriptionWidget = Container();

  GameCell({this.i, this.j, @required this.gamefield, this.child}) : super(key: GlobalKey()) {
    assert(gamefield != null);
    // i = i ?? -1;
    // j = j ?? -1;
    // isDragTarget = isDragTarget ?? ([_]) => true;
    level = 0;
    happiness = game.happiness;
    image = null;
  }

/*  GameCell.from(GameCell c, {i, j}) : super(key: GlobalKey()) {
    this.i = c.i;
    this.j = c.j;
    levels = []..addAll(c.levels);
    image = c.image;
    isDragTarget = c.isDragTarget;
    freezeTimer = c.freezeTimer;
    offset = c.offset;
    movingTo = c.movingTo;
    gamefield = c.gamefield;
  }

  GameCell clone() {
    return GameCell.from(this);
  }*/

  bool canBePlacedIn(GameCell cell) {
    return true;
  }

  void step() {
    if (freezeTimer > 0) {
      freezeTimer--;
      (key as GlobalKey).currentState.setState(() {});
    } else {
      // game.money += (levels[level].income * fill) - levels[level].rent;
    }
  }

  void calculateHappiness() {
    happiness = game.happiness;
  }

  void calculateFill() {
    fill = (levels[level].capacity * min(game.happiness / 100, 1)).round();
  }

  void fillEntertainment() {
    var n = getNeighbors();
    var ne = n.where(
            (element) => !element.isLiving && element.runtimeType != GameCell);
    var entertainments = gamefield.map.where((e) => !e.isLiving);
    var entClasses = entertainments.map((e) => e.runtimeType).toSet().toList();
    var people = fill;
    if (entClasses.contains(Restaurant)) {
      for (var cell in n) {
        if (cell is Restaurant) {
          var filled = min(fill, cell.levels[cell.level].capacity - cell.fill);
          people -= filled;
          cell.fill += filled;
          if (people == 0) break;
        }
      }
    }
    if (people > 0) {
      happiness -= (5 * people / fill).round();
      for (var cell in entertainments)
        if (cell is Restaurant) {
          var filled = min(fill, cell.levels[cell.level].capacity - cell.fill);
          people -= filled;
          cell.fill += filled;
          if (people == 0) break;
        }
    }
    if (people > 0) {
      happiness -= (5 * people / fill).round();
    }

    var entertainmentCounter = 3;
    var r = Random();

    var hasFreeEntertainments = true;
    people = fill;
    while (entertainmentCounter > 0 && hasFreeEntertainments) {
      if (people > 0) {
        for (var e in ne)
          if (e.levels[e.level].capacity - e.fill > 0) {
            var chunk = r.nextInt(people + 1);
            var filled = min(chunk, e.levels[e.level].capacity - e.fill);
            people -= filled;
            e.fill += filled;
            if (people == 0) break;
          }
      }
      if (people == 0) {
        people = fill;
        entertainmentCounter--;
        continue;
      } else {
        happiness -= (5 * (people / fill).round());
      }

      while (people > 0 && hasFreeEntertainments) {
        hasFreeEntertainments = false;
        for (var e in entertainments)
          if (e.levels[e.level].capacity - e.fill > 0) {
            hasFreeEntertainments = true;
            var chunk = r.nextInt(people + 1);
            var filled = min(chunk, e.levels[e.level].capacity - e.fill);
            people -= filled;

            e.fill += filled;
            if (people == 0) break;
          }
      }
      if (people == 0) {
        people = fill;
        entertainmentCounter--;
      } else {
        happiness -= (5 * (people / fill).round());
      }
    }
  }

  void setCoordinates(i, j) {
    this.i = i;
    this.j = j;
    resetOffset();
  }

  void resetOffset() {
    offset = mapOffset();
    movingTo = offset;
  }
  
  double getCellSide() {
    return gamefield.cellSide ?? 20;
  }

  Offset mapOffset() {
    return Offset(getCellSide() * j, getCellSide() * i);
  }

  Widget informationData() {
    if (image == null)
      return null;
    return Column(
      children: [
        Flexible(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image(
                  image: image
              ),
            )
        ),
        Flexible(
          flex: 2,
          child: Container(
            alignment: Alignment.topCenter,
            color: Colors.white54,
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 4.0, right: 4.0, bottom: 4.0),
              child: SingleChildScrollView(child: descriptionWidget),
            ),
          ),
        ),
      ],
    );
  }

  void upgrade() {
    if (levels.isNotEmpty) {
      if (levels[level].steps > 0) {
        currentStep++;
        if (currentStep == levels[level].steps) {
          level++;
          currentStep = 0;
          upgradeComplete();
        }
      }
    }
  }

  void upgradeComplete() {}

  num happinessBonus() {
    return 0;
  }

  List<GameCell> getNeighbors({eight = true, active = true}) {
    List<GameCell> neighbors = [];
    if (true) {
      gamefield.map.forEach((e) {
        if ((e.i - i).abs() <= 1 &&  (e.j - j).abs() <= 1 && (!active || e.freezeTimer <= 0) && e != this) {
          neighbors.add(e);
        }
      });
    } else {
      if (i > 0)
        neighbors.add(gamefield.map.firstWhere((e) => e.i == i - 1 && e.j == j, orElse: null));
      if (i < gamefield.h - 1)
        neighbors.add(gamefield.map.firstWhere((e) => e.i == i + 1 && e.j == j));
      if (j > 0)
        neighbors.add(gamefield.map.firstWhere((e) => e.i == i && e.j == j - 1));
      if (j < gamefield.w - 1)
        neighbors.add(gamefield.map.firstWhere((e) => e.i == i && e.j == j + 1));
      if (!eight) {
        if (active) neighbors.removeWhere((element) => element.freezeTimer > 0);
        return neighbors;
      }
      if (i > 0) {
        if (j > 0)
          neighbors.add(gamefield.map.firstWhere((e) => e.i == i - 1 && e.j == j - 1));
        if (j < gamefield.w - 1)
          neighbors.add(gamefield.map.firstWhere((e) => e.i == i - 1 && e.j == j + 1));
      }
      if (i < gamefield.h - 1) {
        if (j > 0)
          neighbors.add(gamefield.map.firstWhere((e) => e.i == i + 1 && e.j == j - 1));
        if (j < gamefield.w - 1)
          neighbors.add(gamefield.map.firstWhere((e) => e.i == i + 1 && e.j == j + 1));
      }
      if (active) neighbors.removeWhere((element) => element.freezeTimer > 0);
    }
    return neighbors;
  }

  Future<void> moveCellTo({GameCell cell, deleteTarget = true, createReplacement = true, i, j, mapOffset, ghost = false}) async {
    assert(((i != null && j != null) && cell == null) || (cell != null && i == null && j == null));
    var replacement;
    if (createReplacement) {
      replacement = GameCell(gamefield: gamefield, i: this.i, j: this.j);
    }
    if (i != null) {
      mapOffset ??= Offset(getCellSide() * j, getCellSide() * i);
      cell = gamefield.map.firstWhere((e) => e.i == i && e.j == j, orElse: () => null);
      this.movingTo = mapOffset;
      if (!ghost) {
        this.i = i;
        this.j = j;
      }
    } else {
      if (!ghost) {
        this.i = cell.i;
        this.j = cell.j;
      }
      this.movingTo = cell.mapOffset();
    }

    if (deleteTarget && cell != null) {
      gamefield.map.remove(cell);
    }
    if (createReplacement) {
      gamefield.setCell(replacement);
    }
    gamefield.movedStreamController.add(this);
    return gamefield.movedStreamController.stream
        .firstWhere((e) => (e == this && this.offset == movingTo))
        .timeout(Duration(seconds: 2),onTimeout: () => throw TimeoutException('$this  to  $cell $i $j'),);
  }

  List<GameCard> getCards() {
    return [];
  }

}

class _GameCellState extends State<GameCell> {
  var cls = [Colors.green[400], Colors.amber, Colors.purpleAccent, Colors.pink];
  bool draggable = false;


  void tapped() {
    print('tapped $widget ${widget.selectedChild}');
    game.setState(() {
      // if (widget.gamefield.selectedCells.contains(widget)) {
      //   widget.gamefield.selectedCells.remove(widget);
      //   widget.resetOffset();
      // } else {
      //   widget.gamefield.selectedCells.add(widget);
      //   if (widget.image != null)
      //     widget.movingTo =
      //         widget.offset + Offset(-widget.getCellSide() / 20, -widget.getCellSide() / 20);
      // }
      widget.gamefield.selectedStreamController.add(widget);
    });
  }

  bool willAcceptDrag(data) {
    // print('will accept ${data is CellCard && !(data.cell is WallCell)} ${widget.isDragTarget()}');
    if ((data.cell as GameCell).canBePlacedIn(widget) && widget.gamefield.isDragTarget(widget, data)) {
      if (widget.runtimeType == data.cell.runtimeType)
        return widget.level < widget.levels.length - 1;
      return true;
    }
    return false;
  }


  @override
  Widget build(BuildContext context) {

    draggable = widget.draggable && !widget.gamefield.selectedCells.contains(widget);

    return SizedBox(
      width: widget.getCellSide(),
      height: widget.getCellSide(),
      child: DragTarget<dynamic>(
          onWillAccept: willAcceptDrag,
          onAccept: (data) {
            print('accept');
            widget.gamefield.unmarkAll();
            game.chooserKey.currentState.remove(data);
            game.money -= data.price;
            if (widget.runtimeType == data.cell.runtimeType &&
                (widget.level < widget.levels.length)) {
              widget.freezeTimer += data.cell.freezeTimer;
              widget.upgrade();
              // data.activate();
              setState(() {});
            } else {
              widget.gamefield.setCell(data.cell, i: widget.i, j: widget.j);
              // data.activate();
            }
            data.activate();
          },
          builder: (context, candidateData, rejectedData) {
            var cellBody = Container(
//                    color: Colors.greenAccent[700],
                alignment: Alignment.center,
                padding: EdgeInsets.all(widget.getCellSide() * 0.025),
                child: Stack(children: [
                  widget.selectedChild,
                  widget.image == null ?
                  Container(
                    width: widget.getCellSide(),
                    height: widget.getCellSide(),
                    color: Colors.black.withOpacity(0.1),
                  ) : Container(
                    color: Colors.black.withOpacity(0.1),
                    child: Image(
                        alignment: Alignment.center,
                        fit: BoxFit.fill,
                        image: widget.image,
                        width: widget.getCellSide(),
                        height: widget.getCellSide()),
                  ),
                  widget.levels.isNotEmpty
                      ? Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: EdgeInsets.only(
                          left: widget.getCellSide() / 20,
                          right: widget.getCellSide() / 20,
                          bottom: widget.getCellSide() / 50),
                      child: Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: List.generate(
                            widget.levels[widget.level].steps,
                                (index) => Container(
                              width: (widget.getCellSide() * 0.8) /
                                  widget.levels[widget.level]
                                      .steps,
                              height: widget.getCellSide() / 20,
                              color: (index + 1 <=
                                  widget.currentStep)
                                  ? Colors.white
                                  : Colors.white
                                  .withOpacity(0.4),
                            )),
                      ),
                    ),
                  )
                      : Container(),
                  Visibility(
                    visible: widget.freezeTimer > 0,
                    child: Container(
                        alignment: Alignment.center,
                        color: Colors.grey.withOpacity(0.7),
                        child: FittedBox(
                          alignment: Alignment.center,
                          fit: BoxFit.cover,
                          child: Text(
                            widget.freezeTimer.toString(),
                            style: TextStyle(
                                color: Colors.white, fontSize: 140),
                          ),
                        )),
                  ),
                  Container(
                      color: Colors.white
                          .withOpacity(candidateData.isEmpty ? 0 : 0.5)),
                  widget.child ?? Container()
                ]));
            return GestureDetector(
                behavior: HitTestBehavior.deferToChild,
                onLongPress: () {
                  var infoData = widget.informationData();
                  if (infoData != null)
                  showDialog(
                    context: context,
                    builder: (context) => game.information(infoData),
                  );
                },
                onTap: () {
                  if (game.selecting)
                    tapped();
                  else {
                    var infoData = widget.informationData();
                    if (infoData != null)
                      showDialog(
                        context: context,
                        builder: (context) => game.information(infoData),
                      );
                  }
                },
                child: Draggable(
                  maxSimultaneousDrags: draggable ? 1 : 0,
                  feedback: Container(
                    child: cellBody,
                  ),
                  childWhenDragging: Container(
                    width: widget.getCellSide(),
                    height: widget.getCellSide(),
                  ),
                  onDragStarted: () {
                    setState(() {
                    });
                  },
                  onDragCompleted: () {},
                  onDragEnd: (drag) {},
                  data: widget,
                  child: cellBody,
                ));
          }),
    );
  }

  Widget information1() {
    return StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        backgroundColor: Colors.lightBlue,
        contentPadding: EdgeInsets.only(top: 8),
        content: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                    top: 12.0, left: 24.0, right: 24.0, bottom: 12.0),
                child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                        text: "lvl = ${widget.levels[widget.level]}"
                            "\nhap = ${widget.happiness}\n"
                            "fill = ${widget.fill}")),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: InkWell(
                  onTap: () {
                    Navigator.of(context, rootNavigator: true).pop();
                  },
                  child: Container(
                      padding: EdgeInsets.only(top: 32.0, bottom: 32.0),
                      decoration: BoxDecoration(
                        color: Colors.lightBlue[400],
                        borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(16.0),
                            bottomRight: Radius.circular(16.0)),
                      ),
//                              child: Icon(Icons.check_circle_outline, color: Colors.amberAccent, size: 56,),
                      child: Icon(Icons.check_circle)),
                ),
              ),
            ]),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }


//   @override
//   Widget information() {
//     return StatefulBuilder(
//       builder: (context, setState) {
//         return AlertDialog(
//           elevation: 0,
//           backgroundColor: Colors.transparent,
//           contentPadding: EdgeInsets.only(top: 8),
//           content: LimitedBox(
//             maxWidth: MediaQuery.of(context).size.width / 1.5,
//             child: Material(
//               elevation: 20,
//               color: Colors.transparent,
//               child: ClipRRect(
//                 borderRadius: BorderRadius.all(Radius.circular(16)),
//                 child: Container(
//                   color: Colors.greenAccent[400],
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Flexible(
//                         child: Column(
//                             mainAxisAlignment: MainAxisAlignment.start,
//                             crossAxisAlignment: CrossAxisAlignment.stretch,
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               AspectRatio(
//                                 aspectRatio: 1,
//                                 child: ClipRRect(
//                                   clipBehavior: Clip.antiAlias,
//                                   child: Align(
//                                     alignment: Alignment.center,
//                                     child: LimitedBox(
//                                         maxHeight: 300,
//                                         child: widget.informationData()),
//                                   ),
//                                 ),
//                               ),
//                               AspectRatio(
//                                 aspectRatio: 1 / 0.5,
//                                 child: ClipRRect(
//                                   clipBehavior: Clip.antiAlias,
//                                   child: Padding(
//                                     padding: const EdgeInsets.only(top: 12.0),
//                                     child: InkWell(
//                                       onTap: () {
//                                         Navigator.of(context,
//                                             rootNavigator: true)
//                                             .pop();
//                                       },
//                                       child: Container(
//                                           padding: EdgeInsets.only(
//                                               top: 32.0, bottom: 32.0),
//                                           decoration: BoxDecoration(
//                                             color: Colors.greenAccent[700],
//                                             borderRadius: BorderRadius.only(
//                                                 bottomLeft:
//                                                 Radius.circular(16.0),
//                                                 bottomRight:
//                                                 Radius.circular(16.0)),
//                                           ),
// //                              child: Icon(Icons.check_circle_outline, color: Colors.amberAccent, size: 56,),
//                                           child: Icon(Icons.check_circle)),
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ]),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         );
//       },
//     );
//
//   }
}

class WallCell extends GameCell {

  @override
  State createState() => _WallCellState();

  @override
  Offset mapOffset() {
    return Offset(getCellSide() * j, getCellSide() * (i));
  }

  WallCell({i,j, gamefield}) : super(i: i, j: j, gamefield: gamefield) {
    image = AssetImage('assets/images/wall.png');
  }

  @override
  List<GameCard> getCards() {
    return [CellCard(cell: WallCell(gamefield: gamefield,),)];
  }
}

class _WallCellState extends _GameCellState {

  @override
  Widget build(BuildContext context) {

    draggable = widget.draggable && !widget.gamefield.selectedCells.contains(widget);

    return SizedBox(
      width: widget.getCellSide() * 5,
      height: widget.getCellSide() * 1,
      child: Container(
        // color: Colors.grey,
        child: DragTarget<dynamic>(
            onWillAccept: willAcceptDrag,
            onAccept: (data) {
              widget.gamefield.unmarkAll();
              game.chooserKey.currentState.remove(data);
              game.money -= data.price;
              if (widget.runtimeType == data.cell.runtimeType &&
                  (widget.level < widget.levels.length)) {
                widget.freezeTimer += data.cell.freezeTimer;
                widget.upgrade();
                // data.activate();
                setState(() {});
              } else {
                widget.gamefield.setCell(data.cell, i: widget.i, j: widget.j);
               // data.activate();
              }
              data.activate();
            },
            builder: (context, candidateData, rejectedData) {
              var cellBody = Container(
//                    color: Colors.greenAccent[700],
                  alignment: Alignment.center,
                  padding: EdgeInsets.all(widget.getCellSide() * 0.025),
                  child: Stack(children: [
                    widget.image == null ?
                    Container(
                      width: widget.getCellSide() * 5,
                      height: widget.getCellSide(),
                      color: Colors.black.withOpacity(0.1),
                    ) : Container(
                      color: Colors.black.withOpacity(0.1),
                      child: Image(
                          alignment: Alignment.center,
                          fit: BoxFit.fill,
                          image: widget.image,
                          width: widget.getCellSide() * 5,
                          height: widget.getCellSide()),
                    ),
                    widget.levels.isNotEmpty
                        ? Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: EdgeInsets.only(
                            left: widget.getCellSide() / 20,
                            right: widget.getCellSide() / 20,
                            bottom: widget.getCellSide() / 50),
                        child: Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: List.generate(
                              widget.levels[widget.level].steps,
                                  (index) => Container(
                                width: (widget.getCellSide() * 0.8) /
                                    widget.levels[widget.level]
                                        .steps,
                                height: widget.getCellSide() / 20,
                                color: (index + 1 <=
                                    widget.currentStep)
                                    ? Colors.white
                                    : Colors.white
                                    .withOpacity(0.4),
                              )),
                        ),
                      ),
                    )
                        : Container(),
                    Visibility(
                      visible: widget.freezeTimer > 0,
                      child: Container(
                          alignment: Alignment.center,
                          color: Colors.grey.withOpacity(0.7),
                          child: FittedBox(
                            alignment: Alignment.center,
                            fit: BoxFit.cover,
                            child: Text(
                              widget.freezeTimer.toString(),
                              style: TextStyle(
                                  color: Colors.white, fontSize: 140),
                            ),
                          )),
                    ),
                    Container(
                        color: Colors.white
                            .withOpacity(candidateData.isEmpty ? 0 : 0.5)),
                  ]));
              return GestureDetector(
                  behavior: HitTestBehavior.deferToChild,
                  onLongPress: () {
                    var infoData = widget.informationData();
                    if (infoData != null)
                      showDialog(
                        context: context,
                        builder: (context) => game.information(infoData),
                      );
                  },
                  onTap: () {
                    if (game.selecting)
                      tapped();
                    else {
                      var infoData = widget.informationData();
                      if (infoData != null)
                        showDialog(
                          context: context,
                          builder: (context) => game.information(infoData),
                        );
                    }
                  },
                  child: Draggable(
                    maxSimultaneousDrags: draggable ? 1 : 0,
                    feedback: Container(
                      child: cellBody,
                    ),
                    childWhenDragging: Container(
                      width: widget.getCellSide() * 5,
                      height: widget.getCellSide(),
                    ),
                    onDragStarted: () {
                      setState(() {
                      });
                    },
                    onDragCompleted: () {},
                    onDragEnd: (drag) {},
                    data: widget,
                    child: cellBody,
                  ));
            }),
      ),
    );
  }

  @override
  bool willAcceptDrag(data) {
    return data is CellCard && data.cell is WallCell;
  }

  void tapped() {}

}

class Castle extends GameCell{

  Castle({i, j, gamefield}) : super(i: i, j: j, gamefield: gamefield) {
    image = AssetImage('assets/images/castle.png');
    price = 100;
    isLiving = true;
    descriptionWidget = Text('''Замок каждый ход приносит деньги, а при атаке предоставляет бесплатный отряд рыцарей
    ''');
  }

  @override
  List<GameCard> getCards() {
    List<GameCard> possibleCards = [];
    possibleCards.add(CellCard(cell: Knight(gamefield: gamefield)));
    if (gamefield.map.where((e) => e.image != null).length > level * 3)
      possibleCards.addAll([CellCard(cell: Castle(gamefield: gamefield,),)]);
    return possibleCards;
  }


  @override
  bool canBePlacedIn(GameCell cell) {
    return (cell is Castle || gamefield.map.every((element) => !(element is Castle)));
  }

  @override
  void upgradeComplete() {
    if (level == 0)
      image = AssetImage('assets/images/h1.png');
    else if (level == 1)
      image = AssetImage('assets/images/h1_2.png');
    else if (level == 2)
      image = AssetImage('assets/images/h1_3.png');
  }

  @override
  List<GameCellLevel> levels = [
    GameCellLevel(2, 10, 1, 40),
    GameCellLevel(3, 20, 1, 60),
    GameCellLevel(0, 30, 1, 80),
  ];


  @override
  void calculateHappiness() {

  }

  @override
  void calculateFill() {}
}

class Farm extends GameCell{

  int bonus = 0;
  int income = 0;
  int incomeCountdown = 0;

  Farm({i, j, gamefield}) : super(i: i, j: j, gamefield: gamefield) {
    price = 200;
    income = 120;
    image = AssetImage('assets/images/farm.png');
    incomeCountdown = 2;
  }


  @override
  List<GameCellLevel> levels = [
    GameCellLevel(2, 10, 3, 16),
    GameCellLevel(4, 20, 1, 60),
    GameCellLevel(0, 30, 1, 80),
  ];

  @override
  num happinessBonus() {

  }

  @override
  void upgradeComplete() {
  }

  @override
  void step() {
    bonus =  getNeighbors().where((element) => element is Farm).length;
    var currentIncome = (income * (1 + bonus / 4)).round();
    game.money += currentIncome;

    child = Container(
      key: GlobalKey(),
      alignment: Alignment.center,
      child: SlideFadeTransition(child: Text('$currentIncome', style: TextStyle(
        color: Colors.yellow,
        shadows: [Shadow(blurRadius: 1)],
        fontWeight: FontWeight.bold
      ),),
        onFinish: () {
        child = null;
        // (key as GlobalKey).currentState?.setState(() {});
        },
      ),
    );
  }
}

class Sport extends GameCell{
  Sport({i, j, gamefield}) : super(i: i, j: j, gamefield: gamefield) {
    image = AssetImage('assets/images/sport.png');
  }

  @override
  List<GameCellLevel> levels = [
    GameCellLevel(2, 10, 3, 16),
    GameCellLevel(4, 20, 1, 60),
    GameCellLevel(0, 30, 1, 80),
  ];


}


class Parking extends GameCell{
  Parking({i, j, gamefield}) : super(i: i, j: j, gamefield: gamefield) {
    image = AssetImage('assets/images/parking.png');
  }

  @override
  List<GameCellLevel> levels = [
    GameCellLevel(2, 10, 3, 16),
    GameCellLevel(4, 20, 1, 60),
    GameCellLevel(0, 30, 1, 80),
  ];

  @override
  void calculateHappiness() {
    happiness = game.happiness;
  }

  @override
  void calculateFill() {
    fill = ( min( happiness/100, 1) * levels[level].capacity).floor();
  }

}


class Restaurant extends GameCell{
  Restaurant({i, j, gamefield}) : super(i: i, j: j, gamefield: gamefield) {
    image = AssetImage('assets/images/restaurant.png');
  }

  @override
  List<GameCellLevel> levels = [
    GameCellLevel(2, 10, 3, 16),
    GameCellLevel(4, 20, 1, 60),
    GameCellLevel(0, 30, 1, 80),
  ];


}

class Arrow extends GameCell {
  Arrow({i, j, gamefield}) : super(i: i, j: j, gamefield: gamefield) {
    image = AssetImage('assets/images/tree.png');
  }
}
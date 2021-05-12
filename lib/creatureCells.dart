import 'dart:async';

import 'package:flutter/material.dart';

import 'cells.dart';
import 'game.dart';
import 'slide_fade_transition.dart';

class CreatureCell extends GameCell {



  int hp = 0;
  int maxHP = 3;
  int atc = 1;
  int def = 1;
  int speed = 2;
  int range = 1;
  int team = 1;

  CreatureCell({i, j, @required gamefield}) : super(i: i, j: j, gamefield: gamefield) {
    hp = maxHP;
    // isDragTarget = ([_]) {
    //   return (gamefield.dragItem.runtimeType == this.runtimeType && i == gamefield.h-1);
    // };
  }

  @override
  State createState() => _CreatureCellState();

  CreatureCell attackCreature(CreatureCell creatureCell) {
    return creatureCell.attacked(atc);
  }

  CreatureCell attacked(int atc) {
    child = Container(
      key: GlobalKey(),
      alignment: Alignment.lerp(Alignment.center, Alignment.topCenter, 0.5),
      child: SlideFadeTransition(child: Text('$atc',
        style: TextStyle(
          color: Colors.red,
          shadows: [Shadow(color: Colors.black, blurRadius: 2)],
          fontWeight: FontWeight.bold,
      ),),
        onFinish: () {
          child = null;
          // (key as GlobalKey).currentState?.setState(() {});
        },
        offset: 5,
        animationDuration: Duration(milliseconds: 1000),
      ),
    );
    hp -= atc;
    print('attacked $hp');
    if (hp == 0) {
      die();
    }
    return this;
  }

  List<List<GameCell>> getActionCells({range, onlyAllies = false, onlyEnemies = false, team, List<int> lengths}) {
    assert(!onlyAllies || !onlyEnemies);
    range = range ?? speed;
    team = team ?? this.team;
    Set<GameCell> passable = Set();
    Set<GameCell> creatures = Set();
    if (lengths == null)
      lengths = List<int>.filled(gamefield.w * gamefield.h, 999);
    else
      lengths.addAll(List<int>.filled(gamefield.w * gamefield.h, 999));
    lengths[(j + i * gamefield.w).floor()] = 0;
    List<GameCell> stack = [this];
    int len = 1;
    while (stack.isNotEmpty) {
      len = lengths[(stack.last.j + stack.last.i * gamefield.w).floor()] + 1;
      var neighbors = stack.last.getNeighbors();
      stack.removeLast();
      for (var n in neighbors) {
        if (n.image == null) {
          if (lengths[(n.j + n.i * gamefield.w).floor()] > len) {
            lengths[(n.j + n.i * gamefield.w).floor()] = len;
            if (len <= range) {
              passable.add(n);
              stack.add(n);
            }
          }
        } else if (n is CreatureCell && len <= range) {
          if (onlyAllies) {
            if (n.team == team)
              creatures.add(n);
          } else if (onlyEnemies) {
            if (n.team != team)
              creatures.add(n);
          } else
            creatures.add(n);
        }
      }
    }
    return [passable.toList(), creatures.toList()
      ..sort((a, b) => lengths[(a.j + a.i * gamefield.w).floor()].compareTo(lengths[(b.j + b.i * gamefield.w).floor()]))];
  }

  void die() {
    gamefield.setCell(GameCell(gamefield: gamefield, i: i, j: j));
  }

  List<List<GameCell>> markActionCells({mark = false, unmark = false, onlyAllies = false, onlyEnemies = false}) {
    assert(!mark || !unmark);
    assert(!onlyAllies || !onlyEnemies);
    var actionCells = getActionCells(onlyAllies: onlyAllies, onlyEnemies: onlyEnemies, team: team);
    var moveCells = actionCells[0];
    if (mark || unmark)
      moveCells.forEach((element) {
      element.setSelected(color: mark ?  Colors.green.withOpacity(0.4) : null);
      (element.key as GlobalKey).currentState?.setState(() {});
    });
    var attackCells = actionCells[1];
    if (!mark || !unmark)
      attackCells.forEach((element) {
        element.setSelected(color: mark ?  Colors.red.withOpacity(0.4) : null);
        (element.key as GlobalKey).currentState?.setState(() {});
      });
    return [moveCells, attackCells];
  }

  Widget informationData() {
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
            alignment: Alignment.center,
            color: Colors.white54,
            child: Column(
              children: [
                Text("Attack: $atc"),
                Text("Defence: $def"),
                Text("HP: $hp/$maxHP"),
                Text("Speed: $speed"),
                Text("Range: $range"),
              ],
            ),
          ),
        ),
      ],
    );
  }


  @override
  void markSelected() {

  }

  void tapped() async {
    // print('tapped creature ${gamefield.selectedCells}');
    if (gamefield.selectedCells.isEmpty) {
      var actionCells = markActionCells(mark: true, onlyEnemies: true);
      (gamefield.key as GlobalKey).currentState?.setState(() {});
      while (true) {
        var cellsFuture = gamefield.selectCells(2, willClearAfter: true, willUpdateState: true);
        gamefield.selectedStreamController.add(this);
        var cells = await cellsFuture;
        if (cells.length < 2) {
          cells.forEach((element) {element.resetOffset();});
          markActionCells(unmark: true, onlyEnemies: true);
          break;
        }
        if (actionCells[0].contains(cells.last)) {
          markActionCells(unmark: true, onlyEnemies: true);
          await moveCellTo(cell: cells.last, deleteTarget: true, createReplacement: true);
          game.step();
          break;
        } else if (actionCells[1].contains(cells.last)) {
          markActionCells(unmark: true, onlyEnemies: true);
          await attackCell(cells.last);
          game.step();
          break;
        } else {
          print('wrong cell');
        }
      }
    } else if (gamefield.selectedCells.first == this) {
      gamefield.selectedStreamController.add(null);
    } else {
      gamefield.selectedStreamController.add(this);
    }

    // //cancel tap
    // if (gamefield.selectedCells.first == this) {
    //   gamefield.selectedCells.remove(this);
    //   resetOffset();
    //   markActionCells(unmark: true, onlyEnemies: true);
    //   game.selecting = false;
    //   game.chooserKey.currentState?.setAvailable(gamefield.selectedCells.isEmpty);
    //   (gamefield.key as GlobalKey).currentState.setState(() {});
    //   // choose creature to act
    // } else if (gamefield.selectedCells.isEmpty) {
    //   gamefield.selectedCells.add(this);
    //   game.selecting = true;
    //   var actionCells = markActionCells(mark: true, onlyEnemies: true);
    //
    //   (gamefield.key as GlobalKey).currentState.setState(() {});
    //   // game.setState(() {});
    //
    //   StreamSubscription subscription;
    //   subscription = gamefield.selectedStreamController.stream.listen((event) {
    //     if (gamefield.selectedCells.length >= 2) {
    //       if (actionCells.first.contains(gamefield.selectedCells.last)
    //           || actionCells.last.contains(gamefield.selectedCells.last)
    //       ) {
    //         print('sub canceled');
    //         game.selecting = false;
    //         subscription.cancel();
    //         if (gamefield.selectedCells.last is CreatureCell) {
    //           attackCreature(gamefield.selectedCells.last);
    //         } else {
    //           var moveToCell = gamefield.selectedCells.last;
    //           gamefield.selectedCells.clear();
    //           moveTo(moveToCell);
    //         }
    //
    //         actionCells[0].forEach((element) {element.setSelected();});
    //         actionCells[1].forEach((element) {element.setSelected();});
    //
    //       } else {
    //         gamefield.selectedCells.removeLast();
    //       }
    //     } else if (gamefield.selectedCells.isEmpty) {
    //       game.selecting = false;
    //       subscription.cancel();
    //     }
    //     game.chooserKey.currentState?.setAvailable(gamefield.selectedCells.isEmpty);
    //   });
    //   // add creature as target
    // } else {
    //   gamefield.selectedCells.add(this);
    // }
    //
    // gamefield.selectedStreamController.add(this);
  }

  Future attackCell(CreatureCell cell) async {
    int i = this.i;
    int j = this.j;
    await moveCellTo(cell: cell, deleteTarget: false, createReplacement: false, ghost: true);
    if (attackCreature(cell).hp <= 0) {
      gamefield.setCell(GameCell(gamefield: gamefield, i: i, j: j));
      gamefield.setCell(this, i: cell.i, j: cell.j);
      // await moveCellTo(i: cell.i, j: cell.j, deleteTarget: true, createReplacement: true);
    } else {
      await moveCellTo(i: i, j: j, deleteTarget: false, createReplacement: false, ghost: true);
    }
  }



}

class _CreatureCellState extends State<CreatureCell> {
  var cls = [Colors.green[400], Colors.amber, Colors.purpleAccent, Colors.pink];
  bool draggable = false;

  bool willAcceptDrag(data) {
    if (data is CellCard && !(data.cell is WallCell) && data.cell.canBePlacedIn(widget) &&  widget.gamefield.isDragTarget(widget, data)) {
      if (widget.runtimeType == data.cell.runtimeType)
        return widget.level < widget.levels.length - 1;
      return true;
    }
    return false;
  }



  @override
  Widget build(BuildContext context) {

    // draggable = widget.draggable && !widget.gamefield.selectedCells.contains(widget);

    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
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

                setState(() {});
              } else {
                widget.gamefield.setCell(data.cell, i: widget.i, j: widget.j);
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
                          fit: BoxFit.contain,
                          image: widget.image,
                          width: widget.getCellSide(),
                          height: widget.getCellSide()),
                    ),
                    Align(
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
                              widget.maxHP,
                                  (index) => Container(
                                width: (widget.getCellSide() * 0.8) /
                                    widget.maxHP,
                                height: widget.getCellSide() / 20,
                                color: index < widget.hp ? Colors.white.withOpacity(0.8) : Colors.transparent,
                              )),
                        ),
                      ),
                    ),
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
                      widget.tapped();
                  },
                  onLongPressEnd: (details) {
                    var infoData = widget.informationData();
                    if (infoData != null)
                      showDialog(
                        context: context,
                        builder: (context) => game.information(infoData),
                      );
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
      ),
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
}


class Knight extends CreatureCell{
  int maxHP = 3;
  int atc = 1;
  int def = 1;
  int speed = 1;
  int range = 1;
  int team = 0;

  Knight({i, j, gamefield}) : super(i: i, j: j, gamefield: gamefield) {
    image = AssetImage('assets/images/knight.png');
    draggable = true;
    price = 100;
  }

  @override
  List<GameCellLevel> levels = [
    GameCellLevel(2, 10, 3, 16),
    GameCellLevel(4, 20, 1, 60),
    GameCellLevel(0, 30, 1, 80),
  ];

}

class Orc extends CreatureCell{
  int maxHP = 4;
  int atc = 1;
  int def = 0;
  int speed = 1;
  int range = 1;
  int team = 1;

Orc({i, j, gamefield}) : super(i: i, j: j, gamefield: gamefield) {
    image = AssetImage('assets/images/orc2.png');
    draggable = true;

  }

  @override
  List<GameCellLevel> levels = [
    GameCellLevel(2, 10, 3, 16),
    GameCellLevel(4, 20, 1, 60),
    GameCellLevel(0, 30, 1, 80),
  ];

}

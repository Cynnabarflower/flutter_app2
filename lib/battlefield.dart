import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'cards.dart';
import 'cells.dart';
import 'creatureCells.dart';
import 'game.dart';
import 'gamefield.dart';

class Battlefield extends Gamefield {

  Battlefield() : super(key: GlobalKey(), w: 6, h: 8);

  @override
  void init() {
    map = [];
    for (var i = 0; i < w * h; i++) {
      var gc = GameCell(gamefield: this, i: (i / w).floor(), j: i - ((i / w).floor() * w));
      // gc.isDragTarget = (_) {
      //   print('dragtarget ${!(gc.gamefield.dragItem is CellCard && (gc.gamefield.dragItem as CellCard).cell is CreatureCell) || (gc.i == h-1)} ${gc} ');
      //   return !(gc.gamefield.dragItem is CellCard && (gc.gamefield.dragItem as CellCard).cell is CreatureCell) || (gc.i == h-1);
      // };
      map.add(gc);
      setCell(gc);
    }
    // map.add(WallCell(gamefield: this, i: 0, j : 0));

    queue = [];
    var castle = game.town.map.firstWhere((element) => element is Castle, orElse: () => null);
    // print(castle);
    if (castle != null) {
      var knight = castle.getCards().firstWhere((element) => element is CellCard && element.cell is CreatureCell, orElse: () => null);
      // print(knight);
      if (knight != null) {
        knight.price = 0;
        (knight as CellCard).cell.gamefield = this;
        queue.add(knight);
      }
    }
    // while (queue.length < 4) generateCard();
  }


  @override
  bool isDragTarget(GameCell cell, data) {
    return !(data is CellCard) || (cell.i == h-1);
  }

  void generateCard() {
    List<GameCard> possibleCards = [CellCard(cell: Knight(gamefield: this,),)];
    for (var c in map) {
      possibleCards.addAll(c.getCards()
          .where((element) => !(element is CellCard)
          || (element is CellCard && (element.cell is CreatureCell)))
          ..forEach((e) {
            if (e is CellCard) {
              e.cell.gamefield = this;
            }
          })
      );
    }
    int r = Random().nextInt(possibleCards.length);
    queue.add(possibleCards[r]);
  }

  @override
  Duration getMoveDuration(GameCell cell) {
    if (cell is Arrow) {
      return Duration(
          milliseconds: ((cell.movingTo -
              cell.offset)
              .distance / cellSide * 80).floor());
    }
    return Duration(
        milliseconds: ((cell.movingTo -
            cell.offset)
            .distance / cellSide * 200).floor());
  }

  void battleBegin() {
    init();
    int n = Random().nextInt(3)+1;
    while (n-- > 0) {
      setCell(Orc(i: 0, j: n, gamefield: this));
    }
    (key as GlobalKey).currentState?.setState(() {});
  }

  Future<void> finishBattle(aliveEnemies, aliveAllies) {
    queue.clear();
    if (aliveAllies.isEmpty) {
      return game.changeView(i: 1).then((value) {
        aliveEnemies.forEach((element) {
          setCell(GameCell(gamefield: this), i: element.i, j: element.j);
        });
        (key as GlobalKey).currentState?.setState(() {});
      });
    }
    if (aliveEnemies.isEmpty) {
      return game.changeView(i: 1).then((value) {
        aliveAllies.forEach((element) {
          setCell(GameCell(gamefield: this), i: element.i, j: element.j);
        });
        (key as GlobalKey).currentState?.setState(() {});
      });
    }
    return null;
  }

  @override
  Future step() async {
    var aliveCreatures = map.where((element) => element is CreatureCell);
    var aliveEnemies = aliveCreatures.where((element) => (element as CreatureCell).team == 1);
    var aliveAllies = aliveCreatures.where((element) => (element as CreatureCell).team == 0);
    print(aliveCreatures);
    print(map);
    print('${aliveAllies} ${aliveEnemies}');

    if (/*aliveAllies.isEmpty || */aliveEnemies.isEmpty) {
      await finishBattle(aliveEnemies, aliveAllies);
    } else {
        var e = aliveEnemies.first as CreatureCell;
        await game.topLayer.wallAttack(e);
        e.attacked(1);
        (e.key as GlobalKey).currentState?.setState(() {});
        aliveEnemies = aliveCreatures.where((element) => (element as CreatureCell).team == 1);
        if (aliveEnemies.isEmpty)
          await finishBattle(aliveEnemies, aliveAllies);
        else
          await game.battleAI.step();
    }
    return super.step();
  }

  void killEveryone() {

  }
}
import 'package:flutter/cupertino.dart';
import 'package:flutter_app2/battlefield.dart';
import 'package:flutter_app2/creatureCells.dart';

class BattleAI {
  Battlefield battlefield;
  int team;

  BattleAI(this.battlefield, this.team);
  List<CreatureCell> allies = [];
  List<CreatureCell> enemies = [];

  void scan() {
    var creatures = battlefield.map.where((element) => element is CreatureCell);
    enemies = creatures.where((element) => (element as CreatureCell).team != team).map((e) => e as CreatureCell).toList();
    allies = creatures.where((element) => (element as CreatureCell).team == team).map((e) => e as CreatureCell).toList();
  }

  Future step() async {
    scan();
    if (allies.isEmpty) return;
    allies.shuffle();
    var e = allies.first;
    var actionCells = e.getActionCells(onlyEnemies: true);
    if (actionCells[1].isNotEmpty) {
      await e.attackCell(actionCells[1].first);
    } else {
      enemies.shuffle();
      List<int> lengths = [];
      e.getActionCells(onlyEnemies: true, range: 20, lengths: lengths)[1].first;
      print(lengths);
      await e.moveCellTo(cell: actionCells[0].first);
    }
  }

}
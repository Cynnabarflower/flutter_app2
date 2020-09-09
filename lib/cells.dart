import 'dart:math';

import 'package:flutter/cupertino.dart';

import 'game.dart';

class Castle extends GameCell{

  Castle({i, j}) : super(i: i, j: j) {
    image = AssetImage('assets/images/castle.png');
    price = 100;
    isLiving = true;
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

  Farm({i, j}) : super(i: i,j: j) {
    price = 200;
    image = AssetImage('assets/images/farm.png');
    isLiving = true;
  }

  @override
  List<GameCellLevel> levels = [
    GameCellLevel(2, 10, 3, 16),
    GameCellLevel(4, 20, 1, 60),
    GameCellLevel(0, 30, 1, 80),
  ];

  @override
  num happinessBonus() {
    happiness = game.happiness;
    if (getNeighbors().any((e) => e is Knight ))
      happiness += 10;
    if (getNeighbors().any((e) => e is Restaurant))
      happiness += 10;
    if (getNeighbors().any((e) => e is Farm))
      happiness += 2;
  }

  @override
  void upgradeComplete() {
  }

}

class Knight extends GameCell{

  Knight({i, j}) : super(i: i,j: j) {
    image = AssetImage('assets/images/knight.png');
    draggable = true;
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
    if (fill > levels[level].capacity)
      happiness = (happiness / (levels[level].capacity/fill) / (levels[level].capacity/fill)).floor() as double;
  }

  @override
  void calculateFill() {
    fill = (happiness/100 * levels[level].capacity).floor();
  }


}

class Sport extends GameCell{
  Sport({i, j}) : super(i: i,j: j) {
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
  Parking({i, j}) : super(i: i,j: j) {
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
  Restaurant({i, j}) : super(i: i,j: j) {
    image = AssetImage('assets/images/restaurant.png');
  }

  @override
  List<GameCellLevel> levels = [
    GameCellLevel(2, 10, 3, 16),
    GameCellLevel(4, 20, 1, 60),
    GameCellLevel(0, 30, 1, 80),
  ];


}
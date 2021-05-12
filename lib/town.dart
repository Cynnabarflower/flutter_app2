import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'cards.dart';
import 'cells.dart';
import 'creatureCells.dart';
import 'game.dart';
import 'gamefield.dart';

class Town extends Gamefield {

  int attackCountdown = -1;

  Town() : super(key: GlobalKey(), w: 5, h: 7);

  @override
  void init() {
    map = [];
    for (var i = w; i < w * h; i++) {
      map.add(GameCell(gamefield: this, i: (i / w).floor(), j: i - ((i / w).floor() * w) ));
    }
    map.add(WallCell(gamefield: this, i: 0, j : 0));

    queue = [];
    queue.add(CellCard(cell: Castle(gamefield: this,)));
  }


  @override
  Future step() async {
    attackCountdown--;
    print('attack countdown: $attackCountdown');
    if (attackCountdown < 0) {
      attackCountdown = (Random().nextInt(-attackCountdown) > 3) ? (Random().nextInt(3)+1) : attackCountdown;
    } else if (attackCountdown == 0) {
      game.battlefield.battleBegin();
      game.changeView(i: 0);
    }
    super.step();
  }


  @override
  bool isDragTarget(GameCell cell, data) {
    return (cell != null && cell.i != null && cell.j != null)
      && ( !(data is CellCard) || !(data.cell is WallCell) || cell is WallCell);
  }

  void generateCard() {
    print('gen');
    List<GameCard> possibleCards = [];
    for (var c in map) {
      possibleCards.addAll(c.getCards()
          .where((element) => !(element is CellCard)
          || (element is CellCard && !(element.cell is CreatureCell)))
      );
    }
    double farmKoeff = map.where((element) => element is Farm).length / (w * h);
    if (farmKoeff < 0.1) {
      possibleCards.addAll([
        CellCard(cell: Farm(gamefield: this,),),
        CellCard(cell: Farm(gamefield: this,),)
      ]);
    } else {
      possibleCards.add(CellCard(cell: Farm(gamefield: this,),));
    }
    print('$possibleCards');
    int r = Random().nextInt(possibleCards.length);
    queue.add(possibleCards[r]);

    // int r = Random().nextInt(100);
    // if (r < 10)
    //   queue.add(CellCard(cell: Castle(gamefield: this)..freezeTimer = Random().nextInt(3)));
    // else if (r < 50)
    //   queue.add(CellCard(cell: Farm(gamefield: this)));
    // // else if (r < 30)
    // //   queue.add(CellCard(cell: Knight(gamefield: this)));
    // else if (r < 40)
    //   queue.add(CellCard(cell: Sport(gamefield: this)));
    // else if (r < 50)
    //   queue.add(DiscountCard(gamefield: this,));
    // else if (r < -60)
    //   queue.add(ResetRandomCardsCard(gamefield: this));
    // else if (r < 70)
    //   queue.add(SwapGameCellsCard(cardsQuan: Random().nextInt(2) + 2, gamefield: this));
    // else if (r < 80)
    //   queue.add(MoneyCard(gamefield: this));
    // else if (r < 90)
    //   queue.add(LoanCard(gamefield: this));
    // else if (r < 100)
    //   queue.add(TimerBlockerCard(
    //       gamefield: this,
    //     timer: Random().nextInt(2) + 2,
    //     basePrice: (Random().nextInt(3) + 1) * 50,
    //   ));
    // else if (r < 110)
    //   queue.add(CellCard(cell: WallCell(gamefield: this,)));
    // else
    //   queue.add(ResetRandomCardsCard(gamefield: this));
  }

  @override
  Widget buildBackground() {
    return Image(
        image: AssetImage('assets/images/grassBig2.png'),
        fit: BoxFit.fill
    );
  }
}
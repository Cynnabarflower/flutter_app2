import 'dart:async';
import 'dart:math';

import 'package:firebase_admob/firebase_admob.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app2/game.dart';

import 'ads.dart';

class ResetCardsCard extends EventCard {
  @override
  Future activate() {
    for (int i = 0; i < 3; i++)
      game.chooserKey.currentState.removeNice(
          game.chooserKey.currentState.data[0],
          begin: const Offset(0.0, 2.0),
          end: const Offset(0.0, 0.0));
    game.setState(() {});
    // gamefield.generateCard();
    // gamefield.generateCard();
    // gamefield.generateCard();
    game.step();
  }

  ResetCardsCard({@required gamefield}) : super(gamefield: gamefield) {
    this.child = Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        mainAxisSize: MainAxisSize.max,
        children: [
          Flexible(flex: 1, child: Icon(Icons.refresh, color: Colors.white)),
          Flexible(
              flex: 1,
              child: FittedBox(
                fit: BoxFit.cover,
                child: Icon(
                  Icons.remove,
                  color: Colors.white,
                ),
              ))
        ]);
  }
}

class ResetRandomCardsCard extends EventCard {
  @override
  Future activate() {
    int removeQuan = Random().nextInt(2) + 1;
    print('removing $removeQuan cards');
    for (int i = 0; i < removeQuan; i++) {
      int removeIndex =
          Random().nextInt(game.chooserKey.currentState.data.length);
      print(removeIndex);
      game.chooserKey.currentState.removeNice(
          game.chooserKey.currentState.data[removeIndex],
          begin: const Offset(0.0, 2.0),
          end: const Offset(0.0, 0.0));
    }
    game.setState(() {});
    Future.delayed(
        Duration(milliseconds: 200),
        () => game.setState(() {
              while (removeQuan-- > 0) {
                // gamefield.generateCard();
              }
              game.step();
            }));
  }

  ResetRandomCardsCard({@required gamefield}) : super(gamefield: gamefield)  {
    this.child = Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          Flexible(flex: 1, child: Icon(Icons.refresh, color: Colors.white)),
          Flexible(
              flex: 2,
              child: FittedBox(
                fit: BoxFit.cover,
                child: Text(
                  "?",
                  style: TextStyle(color: Colors.white),
                ),
              ))
        ]);
  }
}

class SwapGameCellsCard extends EventCard {
  int cardsQuan;

  @override
  Future activate() async {
    var selectedCells = await gamefield.selectCells(cardsQuan, showMessage: true);
    selectedCells.shuffle();
    var firstI = selectedCells.first.i;
    var firstJ = selectedCells.first.j;

    List<Future> futures = [];

    for (int i = 0; i < selectedCells.length-1; i++) {
      futures.add(selectedCells[i].moveCellTo(cell: selectedCells[i+1], createReplacement: false, deleteTarget: false));
    }
    futures.add(selectedCells.last.moveCellTo(i: firstI, j: firstJ, createReplacement: false, deleteTarget: false));

    await Future.wait(futures);
    game.step();
  }

  SwapGameCellsCard({@required gamefield, this.cardsQuan = 2}) : super(gamefield: gamefield)  {
    cardsQuan = cardsQuan ?? 2;
    this.child = Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          Flexible(
              flex: 2,
              child: FittedBox(
                  fit: BoxFit.fill,
                  alignment: Alignment.center,
                  child: Text(
                    cardsQuan.toString(),
                    style: TextStyle(color: Colors.white, fontSize: 140),
                  ))),
          Flexible(
              flex: 1,
              child: FittedBox(
                fit: BoxFit.cover,
                child: Text(
                  "Swap",
                  style: TextStyle(color: Colors.white),
                ),
              ))
        ]);
  }
}


//rewrite
class SwapGameCellsRandomCard extends EventCard {
  int cardsQuan;

  @override
  Future activate() async {
    game.chooserKey.currentState.setAvailable(false);

    var cells = Set();
    while (cells.length < cardsQuan) {
      var a = Random().nextInt(45);
      if (!cells.contains(a)) {
        cells.add(a);
        await Future.delayed(Duration(milliseconds: cardsQuan * 80));
      }
    }

    var selectedCells = cells.toList()..shuffle();

    var firstI = selectedCells.first.i;
    var firstJ = selectedCells.first.j;

    List<Future> futures = [];

    for (int i = 0; i < selectedCells.length-1; i++) {
      futures.add(selectedCells[i].moveCellTo(cell: selectedCells[i+1], createReplacement: false, deleteTarget: false));
    }
    futures.add(selectedCells.last.moveCellTo(i: firstI, j: firstJ, createReplacement: false, deleteTarget: false));

    await Future.wait(futures);
    game.step();
  }

  SwapGameCellsRandomCard({@required gamefield, this.cardsQuan = 2}) : super(gamefield: gamefield) {
    cardsQuan = cardsQuan ?? 2;
    this.child = Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          Flexible(
              flex: 2,
              child: FittedBox(
                  fit: BoxFit.fill,
                  child: Text(
                    cardsQuan.toString(),
                    style: TextStyle(color: Colors.white, fontSize: 140),
                  ))),
          Flexible(
              flex: 1,
              child: FittedBox(
                fit: BoxFit.fill,
                child: Text(
                  "Swap random",
                  style: TextStyle(color: Colors.white),
                ),
              ))
        ]);
  }
}

class TimerBlockerCard extends EventCard {
  int timer = 0;
  int basePrice = 100;

  @override
  void step() async {
    timer--;
    var t = TimerBlockerCard(timer: timer, basePrice: basePrice,gamefield: gamefield);
    game.chooserKey.currentState.setState(() {
      var i =  game.chooserKey.currentState.data.indexOf(this);
      game.chooserKey.currentState.data.removeAt(i);
      game.chooserKey.currentState.data.insert(i, t);
    });

    if (timer <= 0) {
      // gamefield.generateCard();
      game.chooserKey.currentState.removeNice(
          game.chooserKey.currentState
              .data[game.chooserKey.currentState.data.indexOf(t)],
          begin: const Offset(0.0, 2.0),
          end: const Offset(0.0, 0.0));
/*      Future.delayed(Duration(milliseconds: 200), () {
        game.chooserKey.currentState.removeNice(
            game.chooserKey.currentState
                .data[game.chooserKey.currentState.data.indexOf(t)],
            begin: const Offset(0.0, 2.0),
            end: const Offset(0.0, 0.0));
        game.setState(() {
        });
      });*/
    }
  }

  TimerBlockerCard({this.timer = 2, this.basePrice = 100, @required gamefield}) : super(gamefield: gamefield) {
    this.price = basePrice * timer;
    this.child = Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        mainAxisSize: MainAxisSize.max,
        children: [
          Flexible(
              flex: 2,
              child: FittedBox(
                  fit: BoxFit.fill,
                  child: Text(
                    timer.toString(),
                    style: TextStyle(color: Colors.white, fontSize: 140),
                  ))),
          Flexible(
              flex: 1,
              child: FittedBox(
                fit: BoxFit.cover,
                child: Text(
                  "Blocker",
                  style: TextStyle(color: Colors.white),
                ),
              ))
        ]);
  }
}

class MoneyCard extends EventCard {
  int money = 0;

  @override
  Future activate() {
    game.money += this.money;
    game.step();
  }

  MoneyCard({this.money, @required gamefield}) : super(gamefield: gamefield) {
    this.price = 0;
    this.money = this.money ?? (Random().nextInt(4) + 1) * 100;
    this.child = Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          Flexible(
              flex: 2,
              child: FittedBox(
                  fit: BoxFit.fill,
                  child: Icon(Icons.monetization_on, color: Colors.white,))),
          Flexible(
              flex: 1,
              child: FittedBox(
                fit: BoxFit.fill,
                child: Text(
                  "Money card",
                  style: TextStyle(color: Colors.white),
                ),
              ))
        ]);
  }
}


class LoanCard extends EventCard {
  int money = 0;
  int interestPerStep = 0;
  int interestPercent = 0;
  int steps = 0;
  bool activated = false;

  @override
  Future activate() {
    activated = true;
    game.money += this.money;
    price = steps;
    game.bonuses.add(this);
    (game.bonusListKey.currentState as dynamic).insertItem(game.bonuses.length-1);
    game.step();
  }

  @override
  void step() {
    if (activated) {
      if (--steps > 0) {
        game.money -= interestPerStep;
      } else {

        game.bonusListKey.currentState.removeItem(game.bonuses.indexOf(this),
                (context, animation) => FadeTransition(
                  opacity: animation,
                  child: this,
                ),
              duration: Duration(milliseconds: 200)
        );
        game.bonuses.remove(this);
      }
      price = steps;
      (key as GlobalKey).currentState.setState(() {});
    }
  }

  LoanCard({this.money, this.interestPerStep, this.steps, @required gamefield}) : super(gamefield: gamefield) {
    this.price = 0;
    this.money = this.money ?? (Random().nextInt(4) + 1) * 100;
    this.interestPercent  = Random().nextInt(8) + 10;
    this.interestPerStep = this.interestPerStep ?? (money / 10).round();
    this.steps = this.steps ?? ((interestPercent/100+1) * money/interestPerStep).floor();
    this.child = Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          Flexible(
              flex: 1,
              child: FittedBox(
                  fit: BoxFit.fill,
                  alignment: Alignment.center,
                  child: Icon(Icons.monetization_on, color: Colors.white,))),
          Flexible(
              flex: 2,
              child: FittedBox(
                fit: BoxFit.fill,
                child: Text(
                  "$money\n${((interestPercent/100+1)*money).floor()}\n$steps steps",
                  style: TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ))
        ]);
  }

}


class AdMoneyCard extends EventCard {
  int money = 0;
  bool adLoading = false;

  @override
  Future activate() {

    showDialog(context: (key as GlobalKey).currentContext,
      builder: (context) =>

          AlertDialog(
            elevation: 0,
            backgroundColor: Colors.transparent,
            contentPadding: EdgeInsets.only(top: 8),
            content: StatefulBuilder(
              builder: (context, setState) =>
              LimitedBox(
                maxWidth: MediaQuery.of(context).size.width/1.5,
                child: Material(
                  elevation: 20,
                  color: Colors.transparent,
                  child: ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                    child: Container(
                      color: Colors.redAccent,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AspectRatio(
                                    aspectRatio: 1,
                                    child: ClipRRect(
                                      clipBehavior: Clip.antiAlias,
                                      child: FittedBox(
                                        fit: BoxFit.fitWidth,
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: adLoading ?
                                          CircularProgressIndicator(
                                            valueColor: AlwaysStoppedAnimation(Colors.white),
                                          ) :
                                          Text(
                                            'Watch a video for $money?',
                                            style: TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  ClipRRect(
                                    clipBehavior: Clip.antiAlias,
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 12.0),
                                      child: Align(
                                        alignment: Alignment.bottomCenter,
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: <Widget>[
                                            Expanded(
                                              child: InkWell(
                                                onTap: () {
                                                  Navigator.of(context, rootNavigator: true).pop();},
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                    BorderRadius.only(bottomLeft: Radius.circular(16)),
                                                    color: Colors.redAccent[400],
                                                  ),
                                                  child: Center(
                                                    child: Padding(
                                                      padding: const EdgeInsets.symmetric(vertical: 32),
                                                      child: FittedBox(
                                                        fit: BoxFit.fitWidth,
                                                        child: Text(
                                                          'No',
                                                          style: TextStyle(color: Colors.white, fontSize: 30),
                                                          textAlign: TextAlign.center,

                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: InkWell(
                                                onTap: () {
                                                  setState(() {
                                                    adLoading = true;
                                                  });
                                                  RewardedVideoAd.instance.listener =
                                                      (RewardedVideoAdEvent event, {String rewardType, int rewardAmount}) {
                                                    if (event == RewardedVideoAdEvent.rewarded) {
                                                      game.setState(() {
                                                        game.money += this.money;
                                                      });
                                                    } else if (event == RewardedVideoAdEvent.loaded) {
                                                      if (adLoading) {
                                                        adLoading = false;
                                                        RewardedVideoAd.instance
                                                            .show();
                                                      } else {
                                                      }
                                                    } else if (event == RewardedVideoAdEvent.closed) {
                                                      Navigator.of(context, rootNavigator: true).pop();
                                                    } else if (event == RewardedVideoAdEvent.failedToLoad) {
                                                      print('failed to load');
                                                    }
                                                  };
                                                  RewardedVideoAd.instance.load(adUnitId: RewardedVideoAd.testAdUnitId, targetingInfo: targetingInfo)
                                                  ..then((value) {
                                                    if (value && adLoading) {
                                                      try {
                                                        RewardedVideoAd.instance
                                                            .show();
                                                      } on PlatformException catch (_){};
                                                    }
                                                  });
                                                },
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                    BorderRadius.only(bottomRight: Radius.circular(16)),
                                                    color: Colors.redAccent[400],
                                                  ),
                                                  child: Center(
                                                    child: Padding(
                                                      padding: const EdgeInsets.symmetric(vertical: 32.0),
                                                      child: FittedBox(
                                                        fit: BoxFit.fitWidth,
                                                        child: Text(
                                                          'Yes',
                                                          style: TextStyle(color: Colors.white, fontSize: 30),
                                                          textAlign: TextAlign.center,

                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
                                      )
                                    ),
                                  ),
                                ]),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          )).then((value) {
            adLoading = false;
            game.step();});
  }

  AdMoneyCard({this.money, @required gamefield}) : super(gamefield: gamefield) {
    this.price = 0;
    this.money = this.money ?? (Random().nextInt(3) + 1) * 500;
    this.child = Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children:
        available ?
        [
          Flexible(
              flex: 2,
              child: FittedBox(
                  fit: BoxFit.fill,
                  child: Row(
                    children: [
                      Icon(Icons.monetization_on, color: Colors.white,),
                      Icon(Icons.ondemand_video, color: Colors.white,),
                    ],
                  ))),
          Flexible(
              flex: 1,
              child: FittedBox(
                fit: BoxFit.fill,
                alignment: Alignment.center,
                child: Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    Text(
                      "AdMoney cards",
                      style: TextStyle(color: Colors.white),
                    ),
                    Text(
                      " ${money} ",
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ))
        ] : [
          Center(child: Text('loading...', style: TextStyle(color: Colors.white)))
        ]);
  }
}



class DiscountCard extends EventCard {
  int discountPercent = 0;
  bool activated = false;

  @override
  Future activate() {
    activated = true;
    game.bonuses.add(this);
    (game.bonusListKey.currentState as dynamic).insertItem(game.bonuses.length-1);
    game.step();
  }


  @override
  void step() {
    if (activated) {
      game.chooserKey.currentState.data.forEach((element) {
        element.price = (element.price * (1 - discountPercent / 100.0)).round();
      });
      game.bonusListKey.currentState.removeItem(game.bonuses.indexOf(this),
              (context, animation) => FadeTransition(
            opacity: animation,
            child: this,
          ),
          duration: Duration(milliseconds: 200)
      );
      game.bonuses.remove(this);
    }
  }

  DiscountCard({this.discountPercent, @required gamefield}) : super(gamefield: gamefield) {
    this.price = 0;
    this.discountPercent = this.discountPercent ?? (Random().nextInt(4) + 2) * 10;
    this.child = Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children:

        [
          Flexible(
              flex: 2,
              child: FittedBox(
                  fit: BoxFit.fill,
                  child: Row(
                    children: [
                      Text('Discount')
                    ],
                  ))),
          Flexible(
              flex: 1,
              child: FittedBox(
                fit: BoxFit.fill,
                alignment: Alignment.center,
                child: Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    Text(
                  "${discountPercent}%",
                      style: TextStyle(color: Colors.white),
                    ),
                    Text(
                      " ${discountPercent} ",
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ))
        ]);
  }
}
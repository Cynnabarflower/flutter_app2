import 'dart:async';
import 'dart:math';

import 'package:firebase_admob/firebase_admob.dart';
import 'package:flame/widgets/animation_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app2/cards.dart';
import 'package:flutter_app2/enemies.dart';
import 'package:flame/animation.dart' as flameAnimation;

import 'cells.dart';

const GREEN = Color.fromARGB(255, 0, 176, 80);
var cellWidth = 0.0;
var gameConstrains;
var loadComplete = false;
_GameState game;
BannerAd myBanner;
InterstitialAd myInterstitial;
MobileAdTargetingInfo targetingInfo = MobileAdTargetingInfo(
  keywords: <String>['flutterio', 'beautiful apps'],
  contentUrl: 'https://flutter.io',
  childDirected: false,
  testDevices: <String>[], // Android emulators are considered test devices
);

class Game extends StatefulWidget {

  @override
  State createState() {
    game = _GameState();
    print('new game state');
    return game;
  }

  Game() : super(key: GlobalKey()) {}
}

class _GameState extends State<Game> {
  List<GameCell> map;
  List<GameCell> livingBuilding;
  List<GameCell> attractions;
  bool showSea = false;
  var h = 5;
  var w = 5;
  List<GameCard> queue;
  var top = 0.0;
  var left = 0.0;
  var movingSpeed = 1.0;
  int money = 6000;
  int people = 0;
  var happiness = 50.0;
  GlobalKey<_ChooserState> chooserKey = GlobalKey();
  var dragItem;
  List<GameCell> selectedCells = [];
  bool selecting = false;
  List<GameCard> bonuses = [];
  GlobalKey<AnimatedListState> bonusListKey = GlobalKey();
  List<EnemyCard> enemies = [];
  Widget enemyPositionTemplate;
  List<Widget> enemyPositions = [];
  var _coinAnimation;
  bool showSeaDone = true;


  @override
  void initState() {

    _coinAnimation = flameAnimation.Animation.sequenced('coin.png', 4, textureWidth: 10, textureHeight: 16, stepTime: 1.0);
/*    _coinAnimation = SpriteSheet(
      imageName: 'coin.png',
      columns: 4,
      rows: 1,
      textureWidth: 16,
      textureHeight: 16,
    ).createAnimation(0, stepTime: 0.25);*/

    SystemChrome.setEnabledSystemUIOverlays([]);

    myInterstitial = InterstitialAd(
      // Replace the testAdUnitId with an ad unit id from the AdMob dash.
      // https://developers.google.com/admob/android/test-ads
      // https://developers.google.com/admob/ios/test-ads
      adUnitId: InterstitialAd.testAdUnitId,
      targetingInfo: targetingInfo,
      listener: (MobileAdEvent event) {
        print("InterstitialAd event is $event");
      },
    );

    super.initState();

    gameConstrains = null;

    map = List<GameCell>(w * h);
    for (var i = 0; i < w * h; i++) {
      map[i] = GameCell(i: (i / w).floor(), j: i - ((i / w).floor() * w));
    }
    queue = [];
    resetCellPositions();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        while (queue.length < 4) generateCard();
      });
      Future.delayed(Duration(seconds: 4), () {
/*              myBanner
                ..load()
                ..show(
                  anchorOffset: 0.0,
                  horizontalCenterOffset: 0.0,
                  anchorType: AnchorType.bottom,
                );*/

/*              myInterstitial
                ..load()
                ..show(
                  anchorType: AnchorType.bottom,
                  anchorOffset: 0.0,
                  horizontalCenterOffset: 0.0,
                );*/
      });
    });
  }

  void resetCellPositions() {
    for (var i = 0; i < map.length; i++) {
      map[i].resetOffset();
      if ((map[i].key as GlobalKey).currentState != null)
        (map[i].key as GlobalKey).currentState.setState(() {});
    }
  }

  Widget build(BuildContext context) {
    var flexTop = 5;
//    var flexBot = (1.5 / (h + 1.5 + 2.5) * 95).toInt();
    var flexMid = (h / (h + 2.5) * 95).toInt();
    var flexMidEnemies = (2.5 / (h + 2.5) * 95).toInt();

    var flexBonus = 7;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            LayoutBuilder(builder: (context, constrains) {
              if (gameConstrains != constrains) {
                gameConstrains = constrains;
                cellWidth = min(constrains.maxWidth / (w * 1.1),
                constrains.maxHeight * flexMid / 100 / (h + 0.1));
                resetCellPositions();
                movingSpeed = cellWidth / 1000;
                loadComplete = true;
              } else {
                loadComplete = true;
              }

              var screenH = MediaQuery.of(context).size.height;
              var chooser = Visibility(
                visible: true,
                child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 4, 16, 4),
                    child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Chooser(key: chooserKey))),
              );

              return Stack(
                children: [
                  Container(
                    alignment: Alignment.topCenter,
                    child: Image(
                      image: AssetImage('assets/images/grassBig2.png'),
                      fit: BoxFit.fill,
                      width: MediaQuery.of(context).size.width,
                      height: screenH,
                      alignment: Alignment.center,
                      repeat: ImageRepeat.repeat,
                    ),
                  ),
                  Stack(
                    overflow: Overflow.visible,
                      children: [
                    TweenAnimationBuilder(
                      duration: Duration(milliseconds: 2000),
                      tween: Tween(begin: showSeaDone ? 1.0 : 0.0, end: 1.0),
                      key: GlobalKey(),
                      builder: (context, value, child) {

                        var mapHeight = cellWidth * h + cellWidth / 8;
                        var minBottom = cellWidth * 2;
                        var minEnemies = cellWidth * 0.5;
                        print((screenH - mapHeight)/cellWidth);
                        if (screenH - mapHeight > 6 * cellWidth) {
                          mapHeight += cellWidth;
                        }

                        var currCellWidth = cellWidth * (game.w - 0.5) / 3;
                        enemyPositionTemplate = SizedBox(
                          width: currCellWidth,
                          height: currCellWidth * 1.4,
                          child: ClipRRect(
                            borderRadius: BorderRadius.all(Radius.circular(currCellWidth/11)),
                            child: Container(
                                height: cellWidth*2,
                                width: currCellWidth,
                                child: Image(
                                    width: currCellWidth,
                                    height: cellWidth * 2,
                                    fit: BoxFit.scaleDown,
                                    image: AssetImage('assets/images/cardSlot.png'))
                            ),
                          ),
                        );
                        var enemiesContainer = Padding(
                          padding: EdgeInsets.only(
                          left: cellWidth / 4,
                          right: cellWidth / 4,
                          top: cellWidth / 2 * (showSea ? value : (1 - value)),
                          bottom: cellWidth / 8),
                          child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Stack(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(3, (index) => enemyPositionTemplate.createElement().widget),
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [EnemyCard(),
                                EnemyCard(),
                                EnemyCard()],
                            ),
                          ],
                        ),
                          ),
                        );
                        var bottomContainer = Stack(
                          children: [
                            Container(
                              alignment: Alignment.center,
                              color: Colors.blue[800],
                            ),
                            Positioned(
                              top: -7,
                              child: Image(
                                height: 48,
                                image: AssetImage('assets/images/watertop.png'),
                                repeat: ImageRepeat.repeatX,
                                width: cellWidth * 6,
                                alignment: Alignment.topCenter,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(cellWidth/4, 12.0, cellWidth/4, (showSea ? value : (1 - value)) * cellWidth * 1.7),
                              child: Container(
                                alignment: Alignment.center,
                                width: MediaQuery.of(context).size.width,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [EnemyCard(), EnemyCard(), EnemyCard()],
                                ),
                              ),
                            )

                          ],
                          overflow: Overflow.visible,
                        );

                        return Column(
                        children: [
                          //enemies
//                        AnimatedCrossFade(firstChild: Container(height: cellWidth * 0.5), secondChild: enemiesContainer, crossFadeState: showSea ? CrossFadeState.showFirst : CrossFadeState.showSecond, duration: Duration(milliseconds: 1000))
                          Flexible(
                              flex: (( minEnemies + (showSea ? (1 - value) : value) * (screenH - mapHeight - minBottom)) * 100).toInt(),
                              child: enemiesContainer),
//                        Animated
//                          showSea ? Container(height: cellWidth * 0.4) : enemiesContainer,
                            //map
                          Container(
                            height: mapHeight,
                            child: Stack(
                              overflow: Overflow.visible,
                              children: [
                                Align(
                                  alignment: Alignment.center,
                                  child: Container(
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(

                                        borderRadius:
                                            BorderRadius.all(Radius.circular(10))),
                                    child: SizedBox(
                                      width: cellWidth * w,
                                      height: cellWidth * h,
                                      child: Stack(
                                          overflow: Overflow.visible,
                                          children: [
                                            Container(
//                                              color: Colors.brown[800],
                                            )
                                          ]
                                            ..addAll(List.generate(
                                              w * h,
                                              (i) {
                                                return Positioned(
                                                    top: map[i].offset.dy,
                                                    left: map[i].offset.dx,
                                                    child: map[i]);
                                              },
                                            )..removeWhere((element) =>
                                                selectedCells.contains(
                                                    (element as Positioned).child)))
                                            ..add(Stack(
                                                children: List.generate(
                                                    selectedCells.length,
                                                    (index) =>
                                                        TweenAnimationBuilder(
                                                          key: selectedCells[index]
                                                              .builderKey,
                                                          duration: Duration(
                                                              milliseconds: (selectedCells[index]
                                                                                  .movingTo -
                                                                              selectedCells[index]
                                                                                  .offset)
                                                                          .distance <
                                                                      cellWidth
                                                                  ? 100
                                                                  : 600),
                                                          tween: Tween<double>(
                                                              begin: 0, end: 1),
                                                          builder: (context, value,
                                                              child) {
                                                            var c =
                                                                child as GameCell;
                                                            return Positioned(
                                                                top: c.offset.dy +
                                                                    (c.movingTo.dy -
                                                                            c.offset
                                                                                .dy) *
                                                                        value,
                                                                left: c.offset.dx +
                                                                    (c.movingTo.dx -
                                                                            c.offset
                                                                                .dx) *
                                                                        value,
                                                                child: Container(
                                                                    decoration:
                                                                        BoxDecoration(
                                                                            boxShadow: [
                                                                          BoxShadow(
                                                                              offset: c.image != null ? Offset(
                                                                                  cellWidth /
                                                                                      40,
                                                                                  cellWidth /
                                                                                      40) : Offset(0,0),
                                                                              color: Colors.black.withOpacity(
                                                                                  0.4),
                                                                              blurRadius: c.image != null ? cellWidth / 60 : 0,
                                                                              spreadRadius: 0)
                                                                        ]
                                                                        ),
                                                                    child: child));
                                                          },
                                                          child:
                                                              selectedCells[index],
                                                          onEnd: () {
                                                            selectedCells[index]
                                                                    .offset =
                                                                selectedCells[index]
                                                                    .movingTo;
                                                          },
                                                        ))
                                                  ..sort((a, b) {
                                                    var d = ((a as TweenAnimationBuilder)
                                                                .child as GameCell)
                                                            .offset -
                                                        ((b as TweenAnimationBuilder)
                                                                .child as GameCell)
                                                            .offset;
                                                    var r =
                                                        d.dy.abs() > cellWidth / 2
                                                            ? d.dy
                                                            : d.dx;
                                                    return r.floor();
                                                  })))
                                            ..add(
                                                //enemy stack
                                                Stack(
                                              children: enemies,
                                            ))
                                      ),
                                    ),
                                  ),
                                ),
                                Visibility(
                                  visible: dragItem is EventCard,
                                  child: Align(
                                    alignment: Alignment.center,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: DragTarget(
                                          onAccept: (data) {
                                        game.chooserKey.currentState.remove(data);
                                        data.activate();
                                      }, builder:
                                          (context, candidateData, rejectedData) {
                                        return Container(
                                          width: cellWidth * 5.25,
                                          decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.4),
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(16))),
                                        );
                                      }),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                          //card chooser
                          Flexible(
                              flex: ((minBottom + (showSea ? value : (1 - value)) * (screenH - mapHeight - minEnemies)) * 100).toInt(),
                              child: bottomContainer),
                        ],
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      );},
                      onEnd: () {
                        showSeaDone = true;
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0, top: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Flexible(
                            flex: 70,
                            child: Padding(
                              padding: EdgeInsets.only(right: cellWidth / 5),
                              child: Column(children: [
                                Flexible(
                                  flex: flexBonus,
                                  child: Container(
                                    alignment: Alignment.topLeft,
                                    child: AnimatedList(
                                      key: bonusListKey,
                                      itemBuilder: (context, index, animation) =>
                                          LimitedBox(
                                        maxWidth: cellWidth * 0.8,
                                        child: Padding(
                                          padding:
                                              EdgeInsets.symmetric(horizontal: 4),
                                          child: bonuses[index],
                                        ),
                                      ),
                                      initialItemCount: bonuses.length,
                                      scrollDirection: Axis.horizontal,
                                      shrinkWrap: true,
                                    ),
                                  ),
                                ),
                                Flexible(
                                  flex: 100 - flexBonus,
                                  child: Container(),
                                )
                              ]),
                            ),
                          ),
                          Flexible(
                            flex: 30,
                            child: Container(
                              padding: EdgeInsets.only(top: 4, right: 4),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: cellWidth / 10),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.start,
                                  children: [
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Container(
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            !_coinAnimation.loaded() ?
                                            Icon(
                                              Icons.monetization_on,
                                              size: cellWidth / 3,
                                            ) : Container(
                                              width: cellWidth/3 * 10/16,
                                              height: cellWidth/3,
                                              child: AnimationWidget(
                                                animation: _coinAnimation,
                                              ),
                                            ),
                                            FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Padding(
                                                padding: EdgeInsets.only(
                                                    left: cellWidth / 10,
                                                    right: cellWidth / 20),
                                                child: Text(
                                                  money.toString(),
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: cellWidth / 3),
                                                ),
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                        chooser
                  ]),
                ],
              );
            }),
            IgnorePointer(
              child: AnimatedContainer(
                duration: Duration(milliseconds: 1500),
                alignment: Alignment.center,
                color: loadComplete ? Colors.transparent : Colors.green,
                padding: const EdgeInsets.all(8.0),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  void setState(VoidCallback fn) {
    print('setState');
    super.setState(fn);
  }

  void step() async {
    print('step');

    showSea = !showSea;
    showSeaDone = false;

     game.happiness = 50.0;

    map.forEach((e) {
      e.fill = 0;
    });

    var bLen = bonuses.length;
    for (int i = 0; i < bonuses.length; i++) {
      bonuses[i].step();
      if (bonuses.length < bLen) {
        i--;
        bLen = bonuses.length;
      }
    }
    map.forEach((element) {
      element.step();
    });

    game.chooserKey.currentState.step();
    generateCard();
    game.chooserKey.currentState.setAvailable(true);
    chooserKey.currentState.update();
    selectedCells.clear();

    setState(() {});
  }

  void setCell(GameCell cell, {i, j}) {
    i = i == null ? cell.i : i;
    j = j == null ? cell.j : j;
    var candidate = map.where((element) => element.i == i && element.j == j);
    if (candidate.isEmpty) {
      map.add(cell
        ..dragTarget = true
        ..setCoordinates(i, j));
      throw Exception('wtf1 setCell');
    } else if (candidate.length == 1) {
      map[map.indexOf(candidate.first)] = cell
        ..dragTarget = true
        ..setCoordinates(i, j);
    } else {
      throw Exception('wtf2 setCell');
    }
  }

  void generateCard() {
    int r = Random().nextInt(100);
    if (r < 10)
      queue.add(CellCard(cell: Castle()..freezeTimer = Random().nextInt(3)));
    else if (r < 20)
      queue.add(CellCard(cell: Farm()));
    else if (r < 30)
      queue.add(CellCard(cell: Knight()));
    else if (r < 40)
      queue.add(CellCard(cell: Sport()));
    else if (r < 50)
      queue.add(DiscountCard());
    else if (r < -60)
      queue.add(ResetRandomCardsCard());
    else if (r < 70)
      queue.add(SwapGameCellsCard(cardsQuan: Random().nextInt(2) + 2));
    else if (r < 80)
      queue.add(MoneyCard());
    else if (r < 90)
      queue.add(LoanCard());
    else if (r < 100)
      queue.add(TimerBlockerCard(
        timer: Random().nextInt(2) + 2,
        basePrice: (Random().nextInt(3) + 1) * 50,
      ));
    else
      queue.add(ResetRandomCardsCard());
  }
}

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
  var i = -1;
  var j = -1;

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
  bool dragTarget = true;
  bool draggable = false;
  int freezeTimer = 0;
  Offset offset = Offset(0, 0);
  Offset movingTo = Offset(0, 0);
  GlobalKey builderKey = GlobalKey();
  var entertainments = [];

  GameCell({this.i, this.j, this.dragTarget}) : super(key: GlobalKey()) {
    i = i ?? -1;
    j = j ?? -1;
    dragTarget = dragTarget ?? true;
    level = 0;
    happiness = game.happiness;
    image = null;
  }

  GameCell.from(GameCell c, {i, j}) : super(key: GlobalKey()) {
    this.i = i ?? c.i;
    this.j = j ?? c.j;
    levels = []..addAll(c.levels);
    image = c.image;
    dragTarget = c.dragTarget;
    freezeTimer = c.freezeTimer;
    offset = c.offset;
    movingTo = c.movingTo;
  }

  GameCell clone() {
    return GameCell.from(this);
  }

  void step() {
    if (freezeTimer > 0) {
      freezeTimer--;
      (key as GlobalKey).currentState.setState(() {});
    } else {
      game.money += (levels[level].income * fill) - levels[level].rent;
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
    var entertainments = game.map.where((e) => !e.isLiving);
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

  Offset mapOffset() {
    return Offset(cellWidth * j, cellWidth * i);
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
    if (i > 0)
      neighbors.add(game.map.firstWhere((e) => e.i == i - 1 && e.j == j));
    if (i < game.h - 1)
      neighbors.add(game.map.firstWhere((e) => e.i == i + 1 && e.j == j));
    if (j > 0)
      neighbors.add(game.map.firstWhere((e) => e.i == i && e.j == j - 1));
    if (j < game.w - 1)
      neighbors.add(game.map.firstWhere((e) => e.i == i && e.j == j + 1));
    if (!eight) {
      if (active) neighbors.removeWhere((element) => element.freezeTimer > 0);
      return neighbors;
    }
    if (i > 0) {
      if (j > 0)
        neighbors.add(game.map.firstWhere((e) => e.i == i - 1 && e.j == j - 1));
      if (j < game.w - 1)
        neighbors.add(game.map.firstWhere((e) => e.i == i - 1 && e.j == j + 1));
    }
    if (i < game.h - 1) {
      if (j > 0)
        neighbors.add(game.map.firstWhere((e) => e.i == i + 1 && e.j == j - 1));
      if (j < game.w - 1)
        neighbors.add(game.map.firstWhere((e) => e.i == i + 1 && e.j == j + 1));
    }
    if (active) neighbors.removeWhere((element) => element.freezeTimer > 0);
    return neighbors;
  }
}

class _GameCellState extends State<GameCell> {
  var cls = [Colors.green[400], Colors.amber, Colors.purpleAccent, Colors.pink];
  bool draggable = false;

  void tapped() {
    game.setState(() {
      if (game.selectedCells.contains(widget)) {
        game.selectedCells.remove(widget);
        widget.resetOffset();
      } else {
        game.selectedCells.add(widget);
        if (widget.image != null)
        widget.movingTo =
            widget.offset + Offset(-cellWidth / 20, -cellWidth / 20);
      }
    });
  }

  bool willAcceptDrag(data) {
    if (data is CellCard && widget.dragTarget) {
      if (widget.runtimeType == data.cell.runtimeType)
        return widget.level < widget.levels.length - 1;
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {

    draggable = widget.draggable && !game.selectedCells.contains(widget);

    return SizedBox(
      child: SizedBox(
        width: cellWidth,
        height: cellWidth,
        child: DragTarget<dynamic>(
            onWillAccept: willAcceptDrag,
            onAccept: (data) {
              game.chooserKey.currentState.remove(data);
              data.activate();
              game.money -= data.price;
              if (widget.runtimeType == data.cell.runtimeType &&
                  (widget.level < widget.levels.length)) {
                widget.freezeTimer += data.cell.freezeTimer;
                widget.upgrade();
                setState(() {});
              } else {
                game.setCell(data.cell, i: widget.i, j: widget.j);
              }
            },
            builder: (context, candidateData, rejectedData) {
              var cellBody = Container(
//                    color: Colors.greenAccent[700],
                  alignment: Alignment.center,
                  padding: EdgeInsets.all(cellWidth * 0.025),
                  child: Stack(children: [
                    widget.image == null ?
                    Container(
                      width: cellWidth,
                      height: cellWidth,
                      color: Colors.black.withOpacity(0.1),
                    ) : Container(
                      color: Colors.black.withOpacity(0.1),
                      child: Image(
                          alignment: Alignment.center,
                          fit: BoxFit.fill,
                          image: widget.image,
                          width: cellWidth,
                          height: cellWidth),
                    ),
                    widget.levels.isNotEmpty
                        ? Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: EdgeInsets.only(
                            left: cellWidth / 20,
                            right: cellWidth / 20,
                            bottom: cellWidth / 50),
                        child: Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: List.generate(
                              widget.levels[widget.level].steps,
                                  (index) => Container(
                                width: (cellWidth * 0.8) /
                                    widget.levels[widget.level]
                                        .steps,
                                height: cellWidth / 20,
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
                    showDialog(
                      context: context,
                      builder: (context) => information(),
                    );
                  },
                  onTap: () {
                    if (game.selecting)
                      tapped();
                    else
                      showDialog(
                        context: context,
                        builder: (context) => information(),
                      );
                  },
                  child: Draggable(
                    maxSimultaneousDrags: draggable ? 1 : 0,
                    feedback: Container(
                      child: cellBody,
                    ),
                    childWhenDragging: Container(
                      width: cellWidth,
                      height: cellWidth,
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

  Widget information() {
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

class Chooser extends StatefulWidget {
  @override
  State createState() => _ChooserState();

  Chooser({key}) : super(key: key);
}

class _ChooserState extends State<Chooser> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey();
  List<GameCard> data = [];
  var top = 0.0;
  var left = 0.0;
  bool available = true;
  Widget message;

  void showMessage(Widget message) {
    this.message = message;
    setState(() {});
  }

  void hideMessage() {
    this.message = null;
    setState(() {});
  }

  void setAvailable(a) {
    setState(() {
      available = a;
    });
  }

  step() async {
    int dLen = data.length;
    for (int i = 0; i < data.length; i++) {
      data[i].step();
      if (data.length < dLen) {
        i--;
        dLen = data.length;
      }
    }
//    await Future.delayed(Duration(milliseconds: 200));
  }

  update() {
    while (data.length < 4 && game.queue.isNotEmpty) this._addAnItem();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => update());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        height: cellWidth * 1.7,
        alignment: Alignment.center,
        padding: EdgeInsets.all(cellWidth / 11),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(cellWidth / 6)),
          color: Colors.white.withOpacity(0.1)
        ),
        child: SizedBox(
            width: cellWidth * 1.2 * 4 + cellWidth / 2,
            child: Stack(
              fit: StackFit.expand,
              overflow: Overflow.visible,
              alignment: Alignment.center,
              children: [
                AnimatedSwitcher(
                  duration: Duration(milliseconds: 300),
                  child: message == null ? Container() : message,
                ),
                AnimatedPositioned(
                  top: message == null ? 0 : cellWidth * 1.5,
                  duration: Duration(milliseconds: 300),
                  child: AbsorbPointer(
                    absorbing: !available,
                    child: SizedBox(
                      height: cellWidth * 1.4,
                      width: cellWidth * 1.2 * 4 + cellWidth / 2,
                      child: AnimatedList(
                        physics: NeverScrollableScrollPhysics(),
                        scrollDirection: Axis.horizontal,
                        padding:
                            EdgeInsets.symmetric(horizontal: cellWidth / 4),
                        key: _listKey,
                        initialItemCount: data.length,
                        itemBuilder: (context, index, animation) =>
                            _buildItem(context, data[index], animation),
                      ),
                    ),
                  ),
                ),
              ],
            )));
  }

  Widget _buildItem(
      BuildContext context, dynamic item, Animation<double> animation) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: cellWidth / 10),
      child: SlideTransition(
        position: animation
            .drive(Tween(begin: Offset(4, 0.0), end: Offset(0.0, 0.0))),
        child: Draggable(
            data: item,
            maxSimultaneousDrags:
                item.available && (item.price <= 0 || item.price <= game.money)
                    ? 1
                    : 0,
            feedback: Container(
              child: item,
            ),
            childWhenDragging: Container(
                child: Container(
                  width: cellWidth * 0.9,
                  height: cellWidth,
                )),
            onDragStarted: () {
              game.setState(() {
                game.dragItem = item;
              });
            },
            onDragCompleted: () {},
            onDragEnd: (drag) {
              game.dragItem = null;
              game.setState(() {});
            },
            child: Stack(
              children: [
                item,
                Container(
                  color: Colors.white.withOpacity(available ? 0 : 0.5),
                  alignment: Alignment.center,
                )
              ],
            )),
      ),
    );
  }

  _removeItem(context, animation) {
    return Container();
  }

  _removeItemNice(context, item, animation,
      {begin: const Offset(-4.0, 0.0), end: const Offset(0.0, 0.0)}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: cellWidth / 10),
      child: SlideTransition(
          position: animation
              .drive(Tween(begin: begin as Offset, end: end as Offset)),
          child: item),
    );
  }

  void remove(item) {
    _listKey.currentState.removeItem(data.indexOf(item),
        (context, animation) => _removeItem(context, animation));
    data.remove(item);
  }

  void removeNice(item,
      {begin: const Offset(-4.0, 0.0),
      end: const Offset(0.0, 0.0),
      duration: const Duration(milliseconds: 400)}) {
    _listKey.currentState.removeItem(
        data.indexOf(item),
        (context, animation) =>
            _removeItemNice(context, item, animation, begin: begin, end: end),
        duration: duration);
    data.remove(item);
  }

  void _addAnItem() {
    data.add(game.queue.first);
    game.queue.removeAt(0);
    _listKey.currentState.insertItem(data.length - 1);
  }

  void insert(item, position) {
    data.insert(position, item);
    _listKey.currentState.insertItem(position);
  }
}
/*

class EnemiesContainer extends StatefulWidget {
  @override
  State createState() => _EnemiesContainerState();

  EnemiesContainer({key}) : super(key: key);
}

class _EnemiesContainerState extends State<EnemiesContainer> with SingleTickerProviderStateMixin {
  List<EnemyCard> enemies = [null, null, null];
  List<EnemyCard> adding = [null, null, null];
  List<EnemyCard> removing = [null, null, null];
  var isNew = [false, false, false];
  var requiresRemoval = [false, false, false];
  Animation<double> _animation;
  Tween<double> _tween;
  AnimationController _animationController;

  var top = 0.0;
  var left = 0.0;
  bool available = true;
  Widget message;
  var currCellWidth;

  Future<bool> loaded() {
    Future<bool> check() async {
      if (true) {
        return Future.delayed(Duration(milliseconds: 50), () => true);
      }
      return Future.delayed(Duration(milliseconds: 50), () => check());
    }

    return check();
  }

  void showMessage(Widget message) {
    this.message = message;
    setState(() {});
  }

  void hideMessage() {
    this.message = null;
    setState(() {});
  }

  void setAvailable(a) {
    setState(() {
      available = a;
    });
  }

  step() async {
  }

  @override
  void initState() {
    _animationController =
        AnimationController(duration: Duration(seconds: 2), vsync: this);
    _tween = Tween(begin: -3.0, end: 0.0);
    _animation = _tween.animate(_animationController)
      ..addListener(() {
      });
    super.initState();
  }

  Widget space() {
    return Container(width: currCellWidth);
  }

  @override
  Widget build(BuildContext context) {

    currCellWidth = cellWidth * (game.w - 0.5) / 3;

    return LayoutBuilder(builder: (context, constraints) {
      return Container(
        color: Colors.red.withOpacity(0.0),
          child: Stack(
            alignment: Alignment.center,
              overflow: Overflow.visible,
              children: [
                buildRemoving(),
                buildEnemies(),
                buildAdding()
              ]));
    });
  }

  Widget buildRemoving() {

    if (removing.every((element) => element == null))
      return Container(width: 0, height: 0,);

    return Stack(
        alignment: Alignment.center,
        overflow: Overflow.visible,
        children: List.generate(3, (index) {
          if (removing[index] == null)
            return Container();

          if (index == 0) {
            return Align(
              alignment: index == 0 ? Alignment.centerLeft : index == 1 ? Alignment.center : Alignment.centerRight,
              child: SizedBox(
                width: currCellWidth,
                child: Stack(
                  overflow: Overflow.visible,
                  children: [
                    Positioned(
                      top: _animation.value * cellWidth,
                      child: removing[index] ?? Container(width: 0),
                    ),
                  ],
                ),
              ),
            );
          }

          return TweenAnimationBuilder(
          key: GlobalKey(),
          duration: Duration(milliseconds: 800),
          tween: Tween(begin: 0.0, end: -3.0),
          builder: (context, value, child) => Align(
            alignment: index == 0 ? Alignment.centerLeft : index == 1 ? Alignment.center : Alignment.centerRight,
            child: SizedBox(
              width: currCellWidth,
              child: Stack(
                overflow: Overflow.visible,
                children: [
                  Positioned(
                    top: value * cellWidth,
                    child: removing[index] ?? Container(width: 0),
                  ),
                ],
              ),
            ),
          ),
          onEnd: () {
            removing[index] = null;
            setState((){});
          },
        );}));
  }

  Widget buildEnemies() {

    if (enemies.every((element) => element == null))
      return Container(width: 0, height: 0,);

    return Stack(
        alignment: Alignment.center,
        overflow: Overflow.visible,
        children: List.generate(3, (index) {
          if (enemies[index] == null)
            return Container();
          return Align(
              alignment: index == 0 ? Alignment.centerLeft : index == 1 ? Alignment.center : Alignment.centerRight,
              child: enemies[index],
            );}));
  }

  Widget buildAdding() {

    if (adding.every((element) => element == null))
      return Container(width: 0, height: 0,);

    return Stack(
        alignment: Alignment.center,
        overflow: Overflow.visible,
        children: List.generate(3, (index) {
          if (adding[index] == null)
            return Container();
          return TweenAnimationBuilder(
            key: GlobalKey(),
            duration: Duration(milliseconds: 3000),
            tween: Tween(begin: -3.0, end: 0.0),
            builder: (context, value, child) =>
                Align(
              alignment: index == 0 ? Alignment.centerLeft : index == 1 ? Alignment.center : Alignment.centerRight,
              child: SizedBox(
                width: currCellWidth,
                child: Stack(
                  overflow: Overflow.visible,
                  children: [
                    Positioned(
                      top: _animation.value * cellWidth,
                      child: removing[index] ?? Container(width: 0),
                    ),
                  ],
                ),
              ),
            ),
            onEnd: () {
              enemies[index] = adding[index];
              setState(() {
                adding[index] = null;
              });
            },
          );}));
  }

  void remove(index) {
    removing[index] = enemies[index];
    enemies[index] = null;
    if (index == 0) {
      _animationController.reset();
      _animationController.forward();
      setState((){});
    }
  }

  void set(EnemyCard card, int position) {
    adding[position] = card;
    if (enemies[position] != null) {
      remove(position);
    }
  }
}

*/
abstract class GameCard extends StatefulWidget {
  int price = 0;
  bool available = true;

  void activate();

  void step();

  Widget information(tag);

  GameCard({key}) : super(key: key);
}

class CellCard extends GameCard {
  GameCell cell;

  CellCard({this.cell}) {
    this.price = cell.price;
    if (cell == null)
      cell = GameCell(dragTarget: false);
    else
      cell.dragTarget = false;
  }

  @override
  State createState() => _CellCardState();

  @override
  void activate() {
    game.step();
  }

  @override
  Widget information(tag1) {
    var tag = (tag1 as _CellCardState);
    return StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          elevation: 0,
          backgroundColor: Colors.transparent,
          contentPadding: EdgeInsets.only(top: 8),
          content: Hero(
            tag: tag,
            child: LimitedBox(
              maxWidth: MediaQuery.of(context).size.width / 1.5,
              child: Material(
                elevation: 20,
                color: Colors.transparent,
                child: ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                  child: Container(
                    color: Colors.greenAccent[400],
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AspectRatio(
                                  aspectRatio: 1,
                                  child: ClipRRect(
                                    clipBehavior: Clip.antiAlias,
                                    child: Align(
                                      alignment: Alignment.center,
                                      child: LimitedBox(
                                          maxHeight: 300,
                                          maxWidth: 300,
                                          child: tag.widget.cell),
                                    ),
                                  ),
                                ),
                                AspectRatio(
                                  aspectRatio: 1 / 0.5,
                                  child: ClipRRect(
                                    clipBehavior: Clip.antiAlias,
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 12.0),
                                      child: InkWell(
                                        onTap: () {
                                          Navigator.of(context,
                                                  rootNavigator: true)
                                              .pop();
                                        },
                                        child: Container(
                                            padding: EdgeInsets.only(
                                                top: 32.0, bottom: 32.0),
                                            decoration: BoxDecoration(
                                              color: Colors.greenAccent[700],
                                              borderRadius: BorderRadius.only(
                                                  bottomLeft:
                                                      Radius.circular(16.0),
                                                  bottomRight:
                                                      Radius.circular(16.0)),
                                            ),
//                              child: Icon(Icons.check_circle_outline, color: Colors.amberAccent, size: 56,),
                                            child: Icon(Icons.check_circle)),
                                      ),
                                    ),
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
        );
      },
    );
  }

  @override
  void step() {
    // TODO: implement step
  }
}

class _CellCardState extends State<CellCard> {
  _CellCardState();

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: this,
      child: SizedBox(
        width: cellWidth,
        height: cellWidth * 1.4,
        child: GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              new PageRouteBuilder(
                opaque: false,
                transitionDuration: Duration(milliseconds: 1000),
                fullscreenDialog: true,
                barrierDismissible: true,
                pageBuilder: (context, animation, secondaryAnimation) {
                  return widget.information(this);
                },
              ),
            );
          },
          child: AbsorbPointer(
            child: Material(
              elevation: cellWidth / 25,
              color: Colors.transparent,
              child: ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(cellWidth / 11)),
                child: Container(
                  color: Colors.greenAccent[700],
                  child: Column(
                    children: [
                      SizedBox(height: cellWidth, child: widget.cell),
                      SizedBox(
                        height: cellWidth * 0.4,
                        child: FittedBox(
                          fit: BoxFit.fitWidth,
                          child: Container(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: EdgeInsets.all(cellWidth / 16),
                              child: Text(
                                widget.price.toString(),
                                style: TextStyle(
                                    fontSize: cellWidth, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class EventCard extends GameCard {
  Widget child;

  EventCard({this.child}) : super(key: GlobalKey());

  @override
  State createState() => _EventCardState();

  @override
  Future activate() {
    game.step();
  }

  @override
  Widget information(tag1) {
    var tag = (tag1 as _EventCardState);
    return StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          elevation: 0,
          backgroundColor: Colors.transparent,
          contentPadding: EdgeInsets.only(top: 8),
          content: Hero(
            tag: tag,
            child: LimitedBox(
              maxWidth: MediaQuery.of(context).size.width / 1.5,
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
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AspectRatio(
                                  aspectRatio: 1,
                                  child: ClipRRect(
                                    clipBehavior: Clip.antiAlias,
                                    child: LimitedBox(
                                        maxHeight: 300,
                                        maxWidth: 300,
                                        child: tag.widget.child),
                                  ),
                                ),
                                AspectRatio(
                                  aspectRatio: 1 / 0.5,
                                  child: ClipRRect(
                                    clipBehavior: Clip.antiAlias,
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 12.0),
                                      child: InkWell(
                                        onTap: () {
                                          Navigator.of(context,
                                                  rootNavigator: true)
                                              .pop();
                                        },
                                        child: Container(
                                            padding: EdgeInsets.only(
                                                top: 32.0, bottom: 32.0),
                                            decoration: BoxDecoration(
                                              color: Colors.redAccent[400],
                                              borderRadius: BorderRadius.only(
                                                  bottomLeft:
                                                      Radius.circular(16.0),
                                                  bottomRight:
                                                      Radius.circular(16.0)),
                                            ),
//                              child: Icon(Icons.check_circle_outline, color: Colors.amberAccent, size: 56,),
                                            child: Icon(Icons.check_circle)),
                                      ),
                                    ),
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
        );
      },
    );
  }

  @override
  void step() async {
    // TODO: implement step
  }
}

class _EventCardState extends State<EventCard> {
  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: this,
      child: LayoutBuilder(
        builder: (context, constraints) {
          var currCellWidth =
              min(constraints.maxWidth, constraints.maxHeight / 1.4);
          if (currCellWidth.isInfinite) currCellWidth = cellWidth;
          return SizedBox(
            width: currCellWidth,
            height: currCellWidth * 1.4,
            child: GestureDetector(
              behavior: HitTestBehavior.deferToChild,
              onTap: () {
                Navigator.of(context).push(
                  new PageRouteBuilder(
                    opaque: false,
                    transitionDuration: Duration(milliseconds: 1000),
                    fullscreenDialog: true,
                    barrierDismissible: true,
                    pageBuilder: (context, animation, secondaryAnimation) {
                      return widget.information(this);
                    },
                  ),
                );
              },
              child: Material(
                elevation: currCellWidth / 25,
                color: Colors.transparent,
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.all(Radius.circular(currCellWidth / 11)),
                  child: Container(
                    height: cellWidth * 2,
                    color: Colors.redAccent[400],
                    child: Column(
                      children: [
                        SizedBox(
                          height: currCellWidth,
                          child: Container(
                            alignment: Alignment.center,
                            color: Colors.redAccent,
                            child: widget.child,
                          ),
                        ),
                        SizedBox(
                          height: currCellWidth * 0.4,
                          child: Container(
                            alignment: Alignment.center,
                            child: FittedBox(
                              fit: BoxFit.fitWidth,
                              child: Padding(
                                padding: EdgeInsets.all(currCellWidth / 16),
                                child: Text(
                                  widget.price.toString(),
                                  style: TextStyle(
                                      fontSize: currCellWidth,
                                      color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

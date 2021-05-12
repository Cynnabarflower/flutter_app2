import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flame/widgets/animation_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app2/battle_ai.dart';
import 'package:flutter_app2/battlefield.dart';
import 'package:flutter_app2/creatureCells.dart';
import 'package:flutter_app2/enemies.dart';
import 'package:flame/animation.dart' as flameAnimation;
import 'package:flutter_app2/gamefield.dart';
import 'package:flutter_app2/town.dart';

import 'ads.dart';
import 'cells.dart';
import 'topLayer.dart';


const GREEN = Color.fromARGB(255, 0, 176, 80);
var cellWidth = 0.0;
double GAME_WIDTH = 512;
double GAME_HEIGHT = 512 * 16 / 9;
double ASPECT_RATIO = 5/7;
var loadComplete = false;
_GameState game;
Ads ads;
int viewNumber = 0; //0 - top, 1 - build, 2 - sea

class Game extends StatefulWidget {
  @override
  State createState() {
    game = _GameState();
    print('new game state');
    return game;
  }

  Game() : super(key: GlobalKey()) {}

  Game.load() : super(key: GlobalKey()) {

  }
}

class _GameState extends State<Game> with TickerProviderStateMixin {

  bool showSea = false;
  GlobalKey<_ChooserState> chooserKey = GlobalKey();
  int money = 6000;
  var happiness = 50.0;
  List<GameCard> bonuses = [];
  GlobalKey<AnimatedListState> bonusListKey = GlobalKey();
  List<EnemyCard> topEnemies = [EnemyCard(), EnemyCard(), EnemyCard()];
  List<EnemyCard> bottomEnemies = [EnemyCard(), EnemyCard(), EnemyCard()];
  Widget enemyPositionTemplate;
  var _coinAnimation;
  bool showMoneyReport = false;
  // AnimationController seaAnimationController;
  // Animation<double> seaAnimation;
  bool longDisplay = false;
  ScrollController _mainScrollController = ScrollController();
  Size _deviceSize;

  bool selecting = false;
  Town town;
  Battlefield battlefield;
  BattleAI battleAI;
  int attackCountdown = -1;

  double arrowTop = 10;
  double arrowLeft = 10;
  List<Widget> flyingObjects = [];
  TopLayer topLayer;

  bool waitingForStep = false;

  @override
  void initState() {
    // for (int i = 0; i < 3; i++) {
    //   topEnemies[i].index = i;
    //   bottomEnemies[i].index = i;
    // }

    town = Town();
    battlefield = Battlefield();
    battleAI = BattleAI(battlefield, 1);
    topLayer = TopLayer();

   /* seaAnimationController =
        AnimationController(duration: const Duration(seconds: 2), vsync: this);
    seaAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(seaAnimationController)
          ..addListener(() {
            if (seaAnimationController.isCompleted) {
            } else if (seaAnimationController.isDismissed) {}
          });*/
    _coinAnimation = flameAnimation.Animation.sequenced('coin.png', 4,
        textureWidth: 10, textureHeight: 16, stepTime: 1.0);

    SystemChrome.setEnabledSystemUIOverlays([]);

    ads = Ads();


    super.initState();


    WidgetsBinding.instance.addPostFrameCallback((_) {
      /*  Future.delayed(Duration(seconds: 4), () {
        ads.showBanner();
      });*/
    });
    // changeView(i: 1);
  }


  @override
  Widget information(Widget informationData, {tag = 0}) {
    return StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          elevation: 0,
          backgroundColor: Colors.transparent,
          contentPadding: EdgeInsets.only(top: 8),
          content: Hero(
            tag: tag,
            child: SizedBox(
              width: MediaQuery.of(context).size.width / 1.5,
              height: MediaQuery.of(context).size.width / 1.5 * 1.5,
              child: Material(
                elevation: 20,
                color: Colors.transparent,
                child: ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                  child: Container(
                    color: Colors.greenAccent[400],
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: ClipRRect(
                              clipBehavior: Clip.antiAlias,
                              child: Align(
                                alignment: Alignment.center,
                                child: informationData,
                              ),
                            ),
                          ),
                          AspectRatio(
                            aspectRatio: 4 / 1,
                            child: ClipRRect(
                              clipBehavior: Clip.antiAlias,
                              child: Container(
                                child: InkWell(
                                  onTap: () {
                                    Navigator.of(context,
                                        rootNavigator: true)
                                        .pop();
                                  },
                                  child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.greenAccent[700],
                                        borderRadius: BorderRadius.only(
                                            bottomLeft:
                                            Radius.circular(16.0),
                                            bottomRight:
                                            Radius.circular(16.0)),
                                      ),
//                              child: Icon(Icons.check_circle_outline, color: Colors.amberAccent, size: 56,),
                                      child: Icon(Icons.check_circle, color: Colors.white54,)),
                                ),
                              ),
                            ),
                          ),
                        ]),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

  }

  Widget build(BuildContext context) {

    (town.key as GlobalKey).currentState?.setState(() {});

    if (_deviceSize != MediaQuery.of(context).size && _mainScrollController.positions.isNotEmpty) {
      _deviceSize = MediaQuery.of(context).size;

      changeView(i: viewNumber, animate: false);
    }

    Widget chooser;
    if (town.cellSide != null) {
      print('new chooser $viewNumber');
      cellWidth = town.cellSide;
      chooser = Padding(
          padding: EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Align(
              alignment: Alignment.bottomCenter,
              child: Chooser(
                  viewNumber == 0 ? battlefield : town, key: chooserKey)));
    } else {
      Future.delayed(Duration(milliseconds: 500), () => setState((){}));
    }

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
            builder: (context, constraints) {
              print(constraints.maxHeight/constraints.maxWidth);

                //background
                return Stack(
                  children: [
                    SingleChildScrollView(
                      controller: _mainScrollController,
                      physics: NeverScrollableScrollPhysics(),
                      child: AbsorbPointer(
                        absorbing: waitingForStep,
                        child: Stack(
                          alignment: Alignment.topCenter,
                          //loading game stack
                          children: [
                          /*  Image(
                              image: AssetImage('assets/images/grassBig9.png'),
                              fit: BoxFit.cover,
                              height: constraints.maxHeight * 20/7,
                              // repeat: ImageRepeat.repeat,
                            ),*/

                            Container(
                              // height: constraints.maxHeight * 20/7,
                              child: Column(
                                children: [
                                  AspectRatio(
                                    aspectRatio: 5/7,
                                    child: Container(
                                      decoration: BoxDecoration(
                                          image: DecorationImage(
                                              image: AssetImage('assets/images/grassTop.png'),
                                              fit: BoxFit.fill
                                          )
                                      ),
                                      alignment: Alignment.center,
                                      child: battlefield,
                                    ),
                                  ),
                                  AspectRatio(
                                    aspectRatio: 5/7,
                                    child: town
                                  ),
                                  AspectRatio(
                                    aspectRatio: 5/7,
                                    child: Container(
                                        decoration: BoxDecoration(
                                            image: DecorationImage(
                                                image: AssetImage('assets/images/water.png'),
                                                fit: BoxFit.fill
                                            )
                                        ),
                                        alignment: Alignment.center,
                                    ),
                                  )
                                ],
                              ),
                            ),
                            IgnorePointer(
                              child: AnimatedContainer(
                                duration: Duration(milliseconds: 1500),
                                alignment: Alignment.center,
                                color: loadComplete
                                    ? Colors.transparent
                                    : Colors.green,
                                padding: const EdgeInsets.all(8.0),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                    topLayer,
                    // bonuses and money
                    bonusesAndMoney(),
                    chooser ?? Container()
                  ],
                );}),
      ),
    );
  }

  Widget bonusesAndMoney() {

    double h = min(MediaQuery.of(context).size.width * 0.15, MediaQuery.of(context).size.height * 0.1);

    return Padding(padding: const EdgeInsets.only(top: 2, left: 2, right: 2),
      child: SizedBox(
        height: h,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.max,
          children: [
            AnimatedList(
              key: bonusListKey,
              itemBuilder:
                  (context, index, animation) =>
                  SizedBox(
                    width: h*2/3 + 8,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 4),
                      child: bonuses[index],
                    ),
                  ),
              initialItemCount: bonuses.length,
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
            ),
            moneyWidget(h/2)
            ],
        ),
      ),
    );

  }

  Widget moneyWidget(h) {

    return GestureDetector(
      onTap: () {
        setState(() {
          changeView();
        });
      },
      child: Container(
        alignment: Alignment.topCenter,
        color: Colors.transparent,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Visibility(
              visible: false,
              child: Row(
                children: [
                  IconButton(icon: Icon(Icons.fiber_manual_record_sharp), onPressed: () async {
                    int r = Random().nextInt(battlefield.map.length);
                    topLayer.wallAttack(battlefield.map[r]);
                  }),
                  IconButton(icon: Icon(Icons.arrow_forward), onPressed: () async {
                    battlefield.selectCells(2).then((value) {
                      value.first.moveCellTo(cell: value.last).then((value) {
                        print('move complete or failed');
                      });
                    });
                  },),
                  IconButton(icon: Icon(Icons.select_all), onPressed: () async {
                    battlefield.selectCells(3).then((value) {
                      print(value);
                    });
                  },),
                  IconButton(icon: Icon(Icons.map), onPressed: () async {
                    if (viewNumber == 0) {
                      print('battlefield map: ${battlefield.w}x${battlefield.h} ${battlefield.map.length}');
                      print(battlefield.map..sort(
                          (a,b) => a.j.compareTo(b.j) + 1000* a.i.compareTo(b.i)
                      ));
                      print('selected: ${battlefield.selectedCells}');
                    } else {
                      print('town map: ${town.w}x${town.h} ${town.map.length}');
                      print(town.map..sort(
                              (a,b) => a.j.compareTo(b.j) + 1000* a.i.compareTo(b.i)
                      ));
                      print('selected: ${town.selectedCells}');
                    }
                  },),
                  IconButton(icon: Icon(Icons.error), onPressed: () async {
                    battlefield.battleBegin();
                    game.changeView(i: 0);
                  },),
                  IconButton(icon: Icon(Icons.update), onPressed: () async {
                    game.setState(() { });
                    (town.key as GlobalKey).currentState.setState(() {});
                  },),
                ],
              ),
            ),
            Container(
              // color: Colors.redAccent.withOpacity(0.3),
              height: h,
              child: !_coinAnimation.loaded() ? Icon(
                  Icons.monetization_on
              ) : Container(
                width: h*2/3,
                child: AnimationWidget(
                  animation:
                  _coinAnimation,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                  left: 8,
                  right: 4),
              child: Container(
                height: h,
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: Text(
                      money.toString().padRight(6),
                      style: TextStyle(
                          color: Colors.white),
                    ),
                  )
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

  Future changeView({i, animate = true}) async {
    viewNumber = i ?? ((viewNumber + 1) % 2);
    print(viewNumber);
    if (viewNumber == 0) {
      chooserKey.currentState?.changeGamefield(battlefield);
      // (battlefield.key as GlobalKey).currentState?.setState(() {});
      if (animate)
        return _mainScrollController.animateTo(0, duration: Duration(seconds: 1), curve: Curves.ease);
      else {
        _mainScrollController.jumpTo(0);
        return Future.value();
      }
    } else if (viewNumber == 1) {
      chooserKey.currentState?.changeGamefield(town);
      // (town.key as GlobalKey).currentState?.setState(() {});
      if (animate)
        return _mainScrollController.animateTo(MediaQuery.of(context).size.width * 7/5, duration: Duration(seconds: 1), curve: Curves.ease);
      else {
        _mainScrollController.jumpTo(MediaQuery.of(context).size.width * 7/5);
        return Future.value();
      }
    } else {
      if (animate)
        return _mainScrollController.animateTo(MediaQuery.of(context).size.width * (7/5+7/5), duration: Duration(seconds: 1), curve: Curves.ease);
      else {
        _mainScrollController.jumpTo(MediaQuery.of(context).size.width * (7/5+7/5));
        return Future.value();
      }
    }
   /* if (showSea) {
      _mainScrollController.animateTo(0, duration: Duration(seconds: 1), curve: Curves.ease);
      seaAnimationController.forward();
    } else {
      _mainScrollController.animateTo(MediaQuery.of(context).size.height * 20/7 * 6/20, duration: Duration(seconds: 1), curve: Curves.ease);
      seaAnimationController.reverse();
    }*/
  }

  Future step() async {
    print('++++++ step');
    game.happiness = 50.0;
    setState(() { waitingForStep = true; });
    var bLen = bonuses.length;
    for (int i = 0; i < bonuses.length; i++) {
      bonuses[i].step();
      if (bonuses.length < bLen) {
        i--;
        bLen = bonuses.length;
      }
    }
    if (viewNumber == 0) {
      await battlefield.step();
      print('Battle queue: ${battlefield.queue}');
    }
    else {
      await town.step();
      print('Town queue: ${town.queue}');
    }
    await game.chooserKey.currentState.step();
    game.chooserKey.currentState.setAvailable(true);
    chooserKey.currentState.update();

    setState(() { waitingForStep = false; });
    print('------ step end');
  }
}

class Chooser extends StatefulWidget {

  Gamefield gamefield;

  @override
  State createState() => _ChooserState();

  Chooser(this.gamefield, {key}) : super(key: key);
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

  void update() {
    while (data.length < 4) {
      if (widget.gamefield.queue.isEmpty) {
        widget.gamefield.generateCard();
      }
      this._addAnItem();
    }
    setState(() {});
  }

  void changeGamefield(Gamefield gamefield) {
    data.reversed.forEach((element) {
      widget.gamefield.queue.insert(0, element);
    });
    while (data.isNotEmpty) {
      removeNice(data.first,
          begin: const Offset(0.0, 2.0),
          end: const Offset(0.0, 0.0));
    }
    widget.gamefield = gamefield;
    update();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => update());
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      height: cellWidth * 1.7,
      alignment: Alignment.center,
      duration: Duration(milliseconds: 500),
      child: Container(
          padding: EdgeInsets.all(cellWidth / 11),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(cellWidth / 6)),
              color: Colors.white.withOpacity(0.1)),
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
              ))),
    );
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
                (widget.gamefield.key as GlobalKey).currentState.setState(() {});
                widget.gamefield.dragItem = item;
              });
            },
            onDragCompleted: () {},
            onDragEnd: (drag) {
              widget.gamefield.dragItem = null;
              (widget.gamefield.key as GlobalKey).currentState.setState(() {});
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
    data.add(widget.gamefield.queue.first);
    widget.gamefield.queue.removeAt(0);
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
  var cellWidth;

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
    return Container(width: cellWidth);
  }

  @override
  Widget build(BuildContext context) {

    cellWidth = cellWidth * (game.w - 0.5) / 3;

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
                width: cellWidth,
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
              width: cellWidth,
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
                width: cellWidth,
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
    this.cell ??= GameCell();

  }


  @override
  State createState() => _CellCardState();

  @override
  void activate() {
    cell.placed();
  }

  @override
  Widget information(tag1) {
    var tag = (tag1 as _CellCardState);
    Widget infoData = tag.widget.cell.informationData();
    return infoData == null ? null : game.information(infoData, tag: tag);
  }

  @override
  void step() {
  }
}

class _CellCardState extends State<CellCard> {
  _CellCardState();

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: this,
      child: GestureDetector(
        onTap: () {
          Widget info = widget.information(this);
          if (info != null) {
          Navigator.of(context).push(
            new PageRouteBuilder(
              opaque: false,
              transitionDuration: Duration(milliseconds: 300),
              fullscreenDialog: true,
              barrierDismissible: true,
              pageBuilder: (context, animation, secondaryAnimation) {
                return info;
              },
            ),
          );}
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            var cellWidth = min(constraints.maxWidth, constraints.maxHeight / 1.4);
            if (cellWidth.isInfinite) cellWidth = MediaQuery.of(context).size.width / 5 / 1.1;
            return SizedBox(
              width: cellWidth,
              height: cellWidth * 1.4,
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
            );
          }
        ),
      ),
    );
  }
}

class EventCard extends GameCard {
  Widget child;
  Gamefield gamefield;

  EventCard({@required this.gamefield, this.child}) : super(key: GlobalKey()) {
    assert(this.gamefield != null);
  }

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
            child: SizedBox(
              width: MediaQuery.of(context).size.width / 1.5,
              child: Material(
                elevation: 20,
                color: Colors.transparent,
                child: ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                  child: Container(
                    color: Colors.redAccent,
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
          var cellWidth = min(constraints.maxWidth, constraints.maxHeight / 1.4);
          if (cellWidth.isInfinite) cellWidth = MediaQuery.of(context).size.width / 5 / 1.1;
          return SizedBox(
            width: cellWidth,
            height: cellWidth * 1.4,
            child: GestureDetector(
              behavior: HitTestBehavior.deferToChild,
              onTap: () {
                Widget info = widget.information(this);
                if (info != null) {
                Navigator.of(context).push(
                  new PageRouteBuilder(
                    opaque: false,
                    transitionDuration: Duration(milliseconds: 500),
                    fullscreenDialog: true,
                    barrierDismissible: true,
                    pageBuilder: (context, animation, secondaryAnimation) {
                      return info;
                    },
                  ),
                );
                }
              },
              child: Material(
                elevation: max(cellWidth / 25,1),
                color: Colors.transparent,
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.all(Radius.circular(cellWidth / 11)),
                  child: Container(
                    height: cellWidth * 2,
                    color: Colors.redAccent[400],
                    child: Column(
                      children: [
                        SizedBox(
                          height: cellWidth,
                          child: Container(
                            alignment: Alignment.center,
                            color: Colors.redAccent,
                            child: widget.child,
                          ),
                        ),
                        SizedBox(
                          height: cellWidth * 0.4,
                          child: Container(
                            alignment: Alignment.center,
                            child: FittedBox(
                              fit: BoxFit.fitWidth,
                              child: Padding(
                                padding: EdgeInsets.all(cellWidth / 16),
                                child: Text(
                                  widget.price.toString(),
                                  style: TextStyle(
                                      fontSize: cellWidth,
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


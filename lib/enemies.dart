
import 'dart:math';

import 'package:flame/animation.dart' as flameAnimation;
import 'package:flame/flame.dart';
import 'package:flame/spritesheet.dart';
import 'package:flame/widgets/animation_widget.dart';
import 'package:flutter/material.dart';

import 'game.dart';

class EnemyCard extends GameCard {
  String assetName;
  flameAnimation.Animation _animation;
  String name = ' ';
  int lives = 0;

  EnemyCard({this.assetName = '', this.name = ' ', this.lives = 0}) : super(key: GlobalKey()) {
    this.assetName  = 'Goblin/Idle.png';
    this.name = 'Goblins';
    this.lives = 3;
    loadAnimation(assetName);
  }

  bool loaded() {
    return _animation == null || _animation.loaded();
  }

  void loadAnimation(assetName) {

    if (assetName == null || assetName.isEmpty) {
      return;
    }

    _animation = SpriteSheet(
      imageName: assetName,
      columns: 4,
      rows: 1,
      textureWidth: 150,
      textureHeight: 150,
    ).createAnimation(
      0,
      stepTime: 0.25,
      to: 3,
    );
  }

  @override
  State createState() => _EnemyCardState();

  @override
  Future activate() {
//    game.step();
  }

  @override
  Widget information(tag1) {

    var tag = (tag1 as _EnemyCardState);

    return StatefulBuilder(
      builder: (context, setState)
      {
        return AlertDialog(
          elevation: 0,
          backgroundColor: Colors.transparent,
          contentPadding: EdgeInsets.only(top: 8),
          content: Hero(
            tag: tag,
            child: LimitedBox(
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
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AspectRatio(
                                  aspectRatio: 1,
                                  child: ClipRRect(
                                    clipBehavior: Clip.antiAlias,
                                    child: LimitedBox(
                                        maxHeight: 300, maxWidth: 300, child:
                                    Container(
                                      child: _animation.loaded() ? AnimationWidget(
                                        animation: _animation,
                                      ) : Container(),
                                    )),
                                  ),
                                ),
                                AspectRatio(
                                  aspectRatio: 1/0.5,
                                  child: ClipRRect(
                                    clipBehavior: Clip.antiAlias,
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 12.0),
                                      child: InkWell(
                                        onTap: () {
                                          Navigator.of(context, rootNavigator: true).pop();
                                        },
                                        child: Container(
                                            padding: EdgeInsets.only(top: 32.0, bottom: 32.0),
                                            decoration: BoxDecoration(
                                              color: Colors.redAccent[400],
                                              borderRadius: BorderRadius.only(
                                                  bottomLeft: Radius.circular(16.0),
                                                  bottomRight: Radius.circular(16.0)),
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
        );},
    );
  }

  @override
  void step() async {
    // TODO: implement step
  }
}

class _EnemyCardState extends State<EnemyCard> {


  @override
  Widget build(BuildContext context) {


    if (widget._animation != null) {
      if (!widget._animation.loaded()) {
        Future<bool> check() async {
          if (widget._animation.loaded()) {
            if (this.mounted)
            setState(() {});
          }
          else
            Future.delayed(Duration(milliseconds: 100), () => check());
        }
        check();
      }
    }
    var currCellWidth = cellWidth * (game.w - 0.5) / 3;

    return Hero(
      tag: this,
      child: SizedBox(
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
                },),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(currCellWidth/11)),
            child: DragTarget<GameCell>(
              onAccept: (data) {
                print('done: $data');
                game.step();
              },
              onWillAccept: (data) {
                print('will: $data');
                try {
                  return (data as GameCell).draggable;
                } catch (_) {
                  return false;
                }
              },
              builder: (context, candidateData, rejectedData) => Container(
                height: cellWidth*2,
                width: currCellWidth,
                color: Colors.black.withOpacity(0.0),
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        width: currCellWidth,
                        height: currCellWidth,
                        child: (widget._animation != null && widget._animation.loaded()) ? AnimationWidget(
                          animation: widget._animation,
                        ) : Container(),
                      ),
                    ),
                    Positioned(
                      bottom: currCellWidth/16,
                      child: Container(
                        width: currCellWidth,
                        padding: EdgeInsets.symmetric(horizontal: currCellWidth/10),
                        color: Colors.redAccent[100].withOpacity(0),
                        child: Column(
                          children: [
                            Padding(
                              padding: EdgeInsets.only(bottom: currCellWidth/16),
                              child: widget.lives > 0 ? Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: List.generate(widget.lives, (index) {
                                  return Icon(Icons.star, color: Colors.red[600],);
                                }),
                              ) : Container(),
                            ),
                            FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(widget.name, textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: currCellWidth/6),)),
                          ],
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
    );
  }

  @override
  void initState() {
    super.initState();
  }
}





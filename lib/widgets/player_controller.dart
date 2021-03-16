
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gitissues/gitissues.dart';
import 'package:kuma_player/kuma_player.dart';
import 'package:kumav/utils/github_account.dart';
import 'package:kumav/widgets/danmaku_layer.dart';
import 'package:kumav/widgets/danmaku_widget.dart';
import 'package:kumav/widgets/player_slider.dart';
import 'package:kumav/widgets/send_widget.dart';
import 'dart:math';

import 'package:video_player/video_player.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'full_kuma_player.dart';
import 'overlay_alert.dart';
import 'tap_detector.dart';
import 'transition_widget.dart';
import 'utils.dart';
import '../localizations/localizations.dart';

enum KumaScaleType {
  NoScale,
  Fit,
  Full,
  Cover
}

class TimerText extends StatefulWidget {

  final Duration time;
  final bool display;

  TimerText({this.time, this.display = false});

  @override
  State<StatefulWidget> createState() => TimerTextState();
}

class TimerTextState extends State<TimerText> with TickerProviderStateMixin {
  AnimationController _controller;

  Duration oldTime = Duration();
  Duration targetTime = Duration();
  Duration currentTime = Duration();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Text(_getTime(), style: Theme.of(context).textTheme.bodyText2.copyWith(color: Colors.white, fontSize: 10),);
        }
    );
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300)
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(TimerText oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.time != widget.time) {
      if (!oldWidget.display && widget.display) {
        _setTo(widget.time??Duration.zero);
      } else if (oldWidget.display && widget.display) {
        _checkForward(widget.time??Duration.zero);
      }
    }
  }

  String _getTime() {
    currentTime = (targetTime - oldTime) * _controller.value + oldTime;
    if (currentTime.isNegative) {
      return "-${currentTime.inSeconds.abs()}s";
    } else {
      return "+${currentTime.inSeconds}s";
    }
  }

  void _checkForward(Duration target) {
    oldTime = currentTime;
    targetTime = target;

    _controller.forward(from: 0);
  }

  void _setTo(Duration target) {
    oldTime = currentTime;
    targetTime = target;
    _controller.value = 1;
  }
}

class AccelerateButton extends StatefulWidget {

  final bool left;
  final bool appear;
  final Duration time;
  AccelerateButton({
    this.left = false,
    this.appear = false,
    this.time
  });

  @override
  State<StatefulWidget> createState() => AccelerateButtonState();
}

class AccelerateButtonState extends State<AccelerateButton> with TickerProviderStateMixin {

  AnimationController _controller;

  double _sin(double d) => (sin(d) + 1) / 2;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: widget.appear ? 1 : 0,
      duration: Duration(milliseconds: 300),
      child: Padding(
        padding: EdgeInsets.only(
          top: 24
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (content, child) {
                return Transform.rotate(
                  angle: widget.left ? pi : 0,
                  child: Stack(
                    children: [
                      Transform.translate(
                        offset: Offset(-9, 0),
                        child:  Opacity(
                          opacity: _sin(_controller.value * 2 * pi - pi / 2 + pi * 1 / 3),
                          child: Icon(Icons.play_arrow, color: Colors.white,),
                        ),
                      ),
                      Opacity(
                        opacity: _sin(_controller.value * 2 * pi - pi / 2),
                        child: Icon(Icons.play_arrow, color: Colors.white,),
                      ),
                      Transform.translate(
                        offset: Offset(9, 0),
                        child: Opacity(
                          opacity: _sin(_controller.value * 2 * pi - pi / 2 - pi * 1 / 3),
                          child: Icon(Icons.play_arrow, color: Colors.white,),
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
            TimerText(time: widget.time, display: widget.appear,)
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1200)
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AccelerateButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.appear != widget.appear) _updateAnimate();
  }

  void _updateAnimate() {
    if (widget.appear) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      if (_controller.isAnimating) _controller.stop();
    }
  }
}

enum PauseButtonType {
  Playing,
  Pause,
  Loading
}

class PauseButton extends StatelessWidget {

  final VoidCallback onPressed;
  final PauseButtonType type;
  final KumaPlayerController controller;

  PauseButton({
    @required this.onPressed,
    this.type = PauseButtonType.Pause,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    if (PauseButtonType.Loading == type) {
      return SpinKitRing(
        size: 56,
        color: Colors.white,
      );
    } else {
      return Container(
        decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 3),
            shape: BoxShape.circle
        ),
        padding: EdgeInsets.all(0),
        child: _icon(),
      );
    }
  }

  Widget _icon() {
    switch (type) {
      case PauseButtonType.Playing:
        return IconButton(
          onPressed: onPressed,
          icon: Icon(
            Icons.play_arrow,
            color: Colors.white,
          ),
          iconSize: 56,
        );
      case PauseButtonType.Pause:
        return IconButton(
          onPressed: onPressed,
          icon: Icon(
            Icons.pause,
            color: Colors.white,
          ),
          iconSize: 56,
        );
      default: break;
    }
    return null;
  }
}

enum TouchState {
  Start,
  Move,
  End
}

class PlayerController extends StatefulWidget {

  final KumaPlayerController controller;
  final VoidCallback onFullscreen;
  final KumaState state;
  final void Function(TouchState state, Offset offset) onDrag;
  final VoidCallback onTapWhenMini;
  final Widget topBar;
  final String error;
  final VoidCallback onReload;
  final String videoKey;
  final VoidCallback onTurnMini;
  final GitIssueDanmakuController danmakuController;

  PlayerController({
    @required this.controller,
    this.onFullscreen,
    this.state,
    this.onDrag,
    this.onTapWhenMini,
    this.topBar,
    this.error,
    this.onReload,
    this.onTurnMini,
    @required this.videoKey,
    this.danmakuController,
  });

  @override
  State<StatefulWidget> createState() => PlayerControllerState();
}

class PlayerControllerState extends State<PlayerController> with SingleTickerProviderStateMixin {
  bool appeared = true;
  Timer _timer;
  Duration _dragDuration;
  bool backward = false;
  bool forward = false;

  AnimationController controller;
  GlobalKey<SendWidgetState> sendKey = GlobalKey();

  bool isControllerDisplay() {
    return widget.state != KumaState.Mini && widget.state != KumaState.Close;
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    // var issue = widget.videoKey == null ? null : GithubAccount().get(widget.videoKey);
    // UserInfo userInfo = GithubAccount().userInfo;
    return AnimatedOpacity(
      opacity: appeared ? 1 : 0,
      duration: Duration(milliseconds: 300),
      child: Stack(
        children: [
          TapDetector(
            onTap: _onSingleTap,
            onDoubleTap: widget.state == KumaState.Mini ? null : (_doubleTapSeekTimer == null ? _onDoubleTap : null),
            onPanStart: _onPanStart,
            onPanMove: _onPanMove,
            onPanEnd: _onPanEnd,
            child: TransitionWidget<Color>(
              builder: (context, child, value) {
                return Container(
                  color: value,
                );
              },
              lerp: Color.lerp,
              value: (isControllerDisplay() && appeared) ? Colors.black26 : Colors.transparent
            ),
          ),
          Visibility(
            visible: isControllerDisplay() && widget.error != null,
            child: Container(
              color: Colors.black87,
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(kt("play_failed"), style: theme.textTheme.headline5.copyWith(color: Colors.orange),),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(widget.error ?? "", style: theme.textTheme.bodyText2.copyWith(color: Colors.orange),),
                    )
                  ),
                  MaterialButton(
                    color: Colors.orange,
                    child: Text(kt("retry"), style: theme.textTheme.bodyText2.copyWith(color: Colors.black87), textAlign: TextAlign.center,),
                    onPressed: () {
                      setState(() {
                        widget.onReload?.call();
                      });
                    },
                  ),
                  Padding(padding: EdgeInsets.only(top: 36))
                ],
              ),
            )
          ),
          Visibility(
            visible: isControllerDisplay() && widget.error == null,
            child: IgnorePointer(
              ignoring: !appeared,
              child: OverflowBox(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Expanded(
                      child: Center(
                        child: AccelerateButton(
                          left: true,
                          appear: backward,
                          time: backward ? _doubleTapSeekDuration : null,
                        ),
                      ),
                    ),
                    PauseButton(
                      onPressed: widget.controller == null ? null : () async {
                        if (widget.controller.value != null) {
                          if (widget.controller.value.isPlaying) {
                            await widget.controller.pause();
                          } else {
                            await widget.controller.play();
                          }
                          setState(() { });
                        }
                      },
                      type: _buttonType(),
                    ),
                    Expanded(
                      child: Center(
                        child: AccelerateButton(
                          appear: forward,
                          time: forward ? _doubleTapSeekDuration : null,
                        ),
                      )
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Visibility(
          //   visible: isControllerDisplay() && widget.error == null,
          //   child: AnimatedBuilder(
          //     animation: controller,
          //     builder: (context, child) {
          //       return Positioned(
          //         right: -100 * controller.value,
          //         top: 60,
          //         child: child
          //       );
          //     },
          //     child: MaterialButton(
          //         child: Container(
          //           decoration: BoxDecoration(
          //               border: Border.all(
          //                   color: Colors.white,
          //                   width: 2
          //               ),
          //               borderRadius: BorderRadius.all(Radius.circular(4))
          //           ),
          //           padding: EdgeInsets.only(left: 5, right: 5, top: 2, bottom: 2),
          //           child: Icon(
          //             Icons.comment_outlined,
          //             color: Colors.white,
          //           ),
          //         ),
          //         minWidth: 20,
          //         padding: EdgeInsets.zero,
          //         onPressed: () async {
          //           if (userInfo == null) {
          //             bool isPlaying = widget.controller.value?.isPlaying;
          //             widget.controller.pause();
          //             OverlayDialog<bool> dialog;
          //             dialog = OverlayDialog<bool>(
          //               builder: (context) {
          //                 return AlertDialog(
          //                   title: Text(kt("confirm")),
          //                   content: Text(kt("login_to_comment")),
          //                   actions: [
          //                     TextButton(
          //                         onPressed: () {
          //                           dialog.dismiss(false);
          //                         },
          //                         child: Text(kt("no"))
          //                     ),
          //                     TextButton(
          //                         onPressed: () {
          //                           dialog.dismiss(true);
          //                         },
          //                         child: Text(kt("yes"))
          //                     )
          //                   ],
          //                 );
          //               }
          //             );
          //             bool ret = await dialog.show(context);
          //             if (ret == true) {
          //               widget.onTurnMini?.call();
          //               GithubAccount().login(context);
          //             } else {
          //               if (isPlaying == true) widget.controller.play();
          //             }
          //           } else {
          //             _cancelCounter();
          //             await controller.forward();
          //             sendKey.currentState?.focusNode?.requestFocus();
          //           }
          //         }
          //     ),
          //   ),
          // ),
          // Visibility(
          //   visible: isControllerDisplay() && widget.error == null,
          //   child: AnimatedBuilder(
          //     animation: controller,
          //     builder: (context, child) {
          //       return Positioned(
          //         right: -360 * (1-controller.value),
          //         top: 60,
          //         child: child
          //       );
          //     },
          //     child: SendWidget(
          //       key: sendKey,
          //       onFocus: (bool focus) {
          //         if (focus) {
          //           _cancelCounter();
          //         } else {
          //           _countDisappear();
          //         }
          //       },
          //       onClose: ()=>controller.reverse(),
          //       issue: issue,
          //       onComment: (comment) async {
          //         widget.danmakuController?.insertComment(comment);
          //       },
          //       controller: widget.controller,
          //     ),
          //   ),
          // ),
          Visibility(
            visible: isControllerDisplay(),
            child: Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 40,
              child: IgnorePointer(
                ignoring: !appeared,
                child: widget.topBar,
              )
            )
          ),
          Visibility(
            visible: widget.state != KumaState.Mini && widget.error == null,
            child: Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                height: 40,
                child:
                IgnorePointer(
                  ignoring: !appeared,
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Text(calculateTime(widget.controller?.value?.position), style: Theme.of(context).textTheme.caption.copyWith(color: Colors.white),),
                      Expanded(
                        child: PlayerSlider(
                          controller: widget.controller,
                          onStartDrag: () {
                            setState(() {
                              appeared = true;
                            });
                            _cancelCounter();
                          },
                          onEndDrag: () {
                            _cancelCounter();
                            _countDisappear();
                          },
                        )
                      ),
                      Text(calculateTime(widget.controller?.value?.duration), style: Theme.of(context).textTheme.caption.copyWith(color: Colors.white),),
                      IconButton(
                        icon: Icon(widget.state == KumaState.Fullscreen ? Icons.fullscreen_exit : Icons.fullscreen, color: Colors.white,),
                        onPressed: widget.onFullscreen,
                      )
                    ],
                  ),
                )
            ),
          ),
        ],
      ),
    );
  }

  PauseButtonType _buttonType() {
    if (_doubleTapSeekTimer != null) return PauseButtonType.Pause;
    var value = widget.controller?.value;
    if (value?.isInitialized == true) {
      if (value.isBuffering) {
        return PauseButtonType.Loading;
      } else if (value.isPlaying) {
        return PauseButtonType.Pause;
      } else {
        return PauseButtonType.Playing;
      }
    } else {
      return PauseButtonType.Loading;
    }
  }

  void _onSingleTap(TapEvent event) {
    if (widget.state == KumaState.Mini) {
      widget.onTapWhenMini?.call();
    } else {
      _touchContainer(event.localPosition);
    }
  }

  void _onDoubleTap(TapEvent event) {
    _doubleTap(event.localPosition);
  }

  Offset dragPosition;
  void _onPanStart(TapEvent event) {
    dragPosition = event.position;
    widget.onDrag?.call(TouchState.Start, Offset.zero);
  }

  void _onPanMove(TapEvent event) {
    var pos = event.position;
    widget.onDrag?.call(TouchState.Move, pos - dragPosition);
    dragPosition = pos;
  }

  void _onPanEnd(TapEvent event) {
    var pos = event.position;
    widget.onDrag?.call(TouchState.End, pos - dragPosition);
    dragPosition = pos;
  }

  void _touchContainer(Offset pos) {
    if (appeared) {
      if (backward) {
        var renderBox = context.findRenderObject() as RenderBox;
        if (renderBox != null) {
          if (pos.dx < renderBox.size.width / 2) {
            _doubleTapSeek(Duration(seconds: -10));
          }
        }
      } else if (forward) {
        var renderBox = context.findRenderObject() as RenderBox;
        if (renderBox != null) {
          if (pos.dx > renderBox.size.width / 2) {
            _doubleTapSeek(Duration(seconds: 10));
          }
        }
      } else {
        _cancelCounter();
        if (_isPlaying && sendKey.currentState?.focusNode?.hasFocus != true) {
          setState(() {
            appeared = false;
          });
        }
      }
    } else {
      setState(() {
        appeared = true;
      });
    }
    _cancelCounter();
    _countDisappear();
  }

  Duration _doubleTapSeekDuration = Duration();
  Timer _doubleTapSeekTimer;

  void _doubleTap(Offset pos) {
    if (!backward && !forward && widget.controller?.value?.isInitialized == true) {
      var renderBox = context.findRenderObject() as RenderBox;
      if (renderBox != null) {
        _doubleTapSeekDuration = Duration();
        if (pos.dx < renderBox.size.width / 2) {
          setState(() {
            backward = true;
            appeared = true;
          });
          _doubleTapSeek(Duration(seconds: -10));
        } else if (pos.dx > renderBox.size.width / 2) {
          setState(() {
            forward = true;
            appeared = true;
          });
          _doubleTapSeek(Duration(seconds: 10));
        }
      }
    }

    _cancelCounter();
    _countDisappear();
  }

  void _doubleTapSeek(Duration d) async {
    if (widget.controller == null) return;
    _doubleTapSeekDuration += d;
    Duration duration = (await widget.controller.position) + _doubleTapSeekDuration;
    setState(() {
      _dragDuration = duration.isNegative ? Duration.zero : duration;
    });
    if (widget.controller.value.isPlaying) {
      widget.controller.pause();
    }
    _doubleTapSeekTimer?.cancel();
    _doubleTapSeekTimer = Timer(Duration(milliseconds: 400), () async {
      await widget.controller.seekTo(_dragDuration);
      widget.controller.play();
      _doubleTapSeekTimer = null;
      setState(() {
        backward = false;
        forward = false;
      });
    });
  }

  bool _oldPlaying = false;
  void _onPlayerEvent() {
    bool isPlaying = _isPlaying;
    if (_oldPlaying != isPlaying) {
      _oldPlaying = isPlaying;
      setState(() {
        if (_oldPlaying) {
          _countDisappear();
        } else {
          appeared = true;
        }
      });
    }
  }

  void _countDisappear() {
    _timer = Timer(Duration(seconds: 5), () {
      _timer = null;
      if (_isPlaying && sendKey.currentState?.focusNode?.hasFocus != true) {
        setState(() {
          appeared = false;
        });
      }
    });
  }

  bool get _isPlaying {
    return widget.controller?.value?.isPlaying == true && widget.controller?.value?.isBuffering != true;
  }

  void _cancelCounter() {
    _timer?.cancel();
    _timer = null;
  }

  bool oldFocus = false;

  @override
  void initState() {
    super.initState();

    appeared = true;
    if (widget.controller != null) {
      widget.controller.addListener(_onPlayerEvent);
      widget.controller.prepared().then((value) {
        _cancelCounter();
        _countDisappear();
      });
    }
    controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
    _cancelCounter();
    widget.controller?.removeListener(_onPlayerEvent);
  }

  @override
  void didUpdateWidget(PlayerController oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      if (oldWidget.controller?.disposed != true)
        oldWidget.controller?.removeListener(_onPlayerEvent);
      widget.controller?.addListener(_onPlayerEvent);

      setState(() {
        appeared = true;
      });
      widget.controller?.prepared()?.then((value) {
        _cancelCounter();
        _countDisappear();
      });
    }
  }
}
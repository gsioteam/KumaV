
import 'dart:async';
import 'dart:ffi';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kuma_player/kuma_player.dart';
import 'package:kumav/utils/github_account.dart';
import 'package:kumav/widgets/danmaku_widget.dart';
import 'danmaku_layer.dart';
import 'player_controller.dart';

enum KumaState {
  Fullscreen,
  Normal,
  Mini,
  Close
}

class FullKumaPlayer extends StatefulWidget {
  final BoxFit fit;
  final KumaPlayerController controller;
  final KumaState state;
  final void Function(TouchState state, Offset offset) onDrag;
  final VoidCallback onTapWhenMini;
  final Widget topBar;
  final VoidCallback onToggleFullscreen;
  final VoidCallback onError;
  final String otherError;
  final ShowAlertListener showAlert;
  final VoidCallback onReload;
  final VoidCallback onTurnMini;
  final String videoKey;
  final GitIssueDanmakuController danmakuController;

  FullKumaPlayer({
    Key key,
    this.fit = BoxFit.contain,
    @required this.controller,
    this.state = KumaState.Normal,
    this.onDrag,
    this.onTapWhenMini,
    this.topBar,
    this.onToggleFullscreen,
    this.onError,
    this.otherError,
    this.showAlert,
    this.onReload,
    @required this.videoKey,
    this.onTurnMini,
    this.danmakuController,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => FullKumaPlayerState();
}

class FullKumaPlayerState extends State<FullKumaPlayer> {
  OverlayEntry fullscreenOverlayEntry;
  Completer<void> fullscreenCompleter;
  bool oldError = false;

  @override
  Widget build(BuildContext context) {
    double width = widget.controller?.value?.size?.width;
    double height = widget.controller?.value?.size?.height;
    bool hasError = widget.controller?.value?.hasError == true;
    if (oldError != hasError && hasError) {
      widget.onError?.call();
    }
    oldError = hasError;

    String error;
    if (hasError) {
      error = widget.controller.value.errorDescription;
      print("$error");
    }
    if (!hasError && widget.otherError != null) {
      hasError = true;
      error = widget.otherError;
    }

    List<Widget> stackList;
    if (hasError) {
      stackList = [
        Container(),
      ];
    } else {
      stackList = [
        Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black,
          child: Hero(
              tag: widget.controller ?? "null",
              child: FittedBox(
                fit: widget.fit,
                alignment: Alignment.center,
                child: SizedBox(
                  width: width ?? 320,
                  height: height ?? 320,
                  child: widget.controller == null ? Container() : KumaPlayer(
                    controller: widget.controller,
                    overlay: widget.showAlert != null,
                    showAlert: widget.showAlert,
                  ),
                ),
              )
          ),
        ),
      ];
      if (widget.danmakuController != null) {
        stackList.add(
          DanmakuWidget(
            controller: widget.danmakuController,
          )
        );
      }
    }
    stackList.add(
      PlayerController(
        controller: widget.controller,
        state: widget.state,
        onDrag: widget.onDrag,
        onTapWhenMini: widget.onTapWhenMini,
        topBar: widget.topBar,
        onFullscreen: widget.onToggleFullscreen,
        error: error,
        onReload: widget.onReload,
        onTurnMini: widget.onTurnMini,
        videoKey: widget.videoKey,
        danmakuController: widget.danmakuController,
      )
    );
    return Stack(
      children: stackList,
    );
  }

  @override
  void initState() {
    super.initState();

    if (widget.controller != null) {
      if (widget.controller.ready) {
        widget.controller.prepared()?.then((value) => setState((){}))?.catchError((e) {
          print("Player error : $e");
        });
      }
    }
  }

  @override
  void didUpdateWidget(FullKumaPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.controller != oldWidget.controller) {
      if (widget.controller != null) {
        widget.controller.prepared().then((value) {
          widget.controller.play();
          setState(() {});
        }).catchError((e) {
          print("Player error : $e");
        });
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
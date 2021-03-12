
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gitissues/gitissues.dart';
import 'package:kuma_player/kuma_player.dart';
import 'package:kumav/widgets/danmaku_layer.dart';
import 'package:kumav/widgets/danmaku_widget.dart';
import 'package:kumav/widgets/spin_itim.dart';
import '../localizations/localizations.dart';

class SendWidget extends StatefulWidget {

  final void Function(bool focus) onFocus;
  final VoidCallback onClose;
  final void Function(Comment) onComment;
  final GitIssue issue;
  final KumaPlayerController controller;

  SendWidget({
    Key key,
    this.onFocus,
    this.onClose,
    this.onComment,
    @required this.issue,
    this.controller,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => SendWidgetState();
}

class SendWidgetState extends State<SendWidget> with SingleTickerProviderStateMixin {

  AnimationController controller;
  FocusNode focusNode;
  bool _oldFocus = false;
  TextEditingController textController;
  bool sending = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Container(
          margin: EdgeInsets.only(right: 6),
          decoration: BoxDecoration(
              border: Border.all(
                  color: Colors.white,
                  width: 2
              ),
              borderRadius: BorderRadius.all(Radius.circular(4)),
              color: Colors.grey.withOpacity(controller.value * 0.8)
          ),
          child: child,
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          MaterialButton(
            onPressed: () {
              focusNode.unfocus();
              widget.onClose?.call();
            },
            minWidth: 20,
            child: Icon(Icons.close, color: Colors.white,),
            padding: EdgeInsets.all(0),
          ),
          Container(
            width: 220,
            child: TextField(
              decoration: InputDecoration(
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.all(0),
              ),
              controller: textController,
              focusNode: focusNode,
              enabled: !sending,
              style: TextStyle(
                  color: Colors.white
              ),
            ),
          ),
          sendButton(),
        ],
      )
    );
  }

  Widget sendButton() {
    if (sending) {
      return Padding(
        padding: EdgeInsets.only(right: 12, left: 12),
        child: SpinKitRing(
          size: 24,
          color: Colors.white,
          lineWidth: 3,
        ),
      );
    } else {
      return MaterialButton(
        onPressed: () async {
          String text = textController.text.trim();
          if (text.length > 0) {
            try {
              setState(() => sending = true);
              DanmakuItem item = DanmakuItem.empty();
              item.label = text;
              item.time = await widget.controller.position;
              Comment comment = await widget.issue.post(item.toString());
              setState(() => sending = false);
              textController.text = "";
              widget.onComment?.call(comment);
              widget.onClose?.call();
            } catch (e) {
              Fluttertoast.showToast(msg: kt("send_failed"));
            }
          }
        },
        minWidth: 20,
        child: Icon(Icons.send, color: Colors.white,),
        padding: EdgeInsets.all(0),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    focusNode = FocusNode();
    focusNode.addListener(_focusUpdate);
    textController = TextEditingController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
    focusNode.dispose();
    textController.dispose();
  }

  void _focusUpdate() {
    if (_oldFocus != focusNode.hasFocus) {
      _oldFocus = focusNode.hasFocus;
      if (_oldFocus) {
        controller.forward();
      } else {
        controller.reverse();
      }
      widget.onFocus?.call(_oldFocus);
    }
  }
}
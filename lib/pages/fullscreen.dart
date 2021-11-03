
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kumav/widgets/video_inner.dart';
import 'package:neo_video_player/neo_video_player.dart' as neo;

class Fullscreen extends StatefulWidget {

  final neo.VideoPlayerController controller;

  Fullscreen({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _FullscreenState();
}

class _FullscreenState extends State<Fullscreen> {
  @override
  Widget build(BuildContext context) {
    var padding = MediaQuery.of(context).padding;

    return Scaffold(
      body: Stack(
        children: [
          VideoInner(
            controller: widget.controller,
          ),
          Positioned(
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              child: DefaultTextStyle(
                style: TextStyle(
                  color: Colors.white
                ),
                child: IconTheme(
                  data: IconThemeData(
                    color: Colors.white,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        icon: Icon(Icons.arrow_back_ios),
                      ),
                      Expanded(
                        child: Text("title"),
                      ),
                      IconButton(
                          onPressed: () {

                          },
                          icon: Icon(Icons.more_vert)
                      ),
                    ],
                  )
                ),
              ),
            ),
            top: padding.top,
            left: 0,
            right: 0,
            height: 56,
          ),
        ],
      ),
      backgroundColor: Colors.black,
    );
  }
}
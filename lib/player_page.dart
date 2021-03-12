
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kuma_player/kuma_player.dart';

import 'widgets/full_kuma_player.dart';

class PlayerPage extends StatefulWidget {
  final String url;

  PlayerPage(this.url);

  @override
  State<StatefulWidget> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  KumaPlayerController _playerController;

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: Text("player"),
      ),
      body: Center(
        child: Container(
          width: size.width,
          height: 360,
          child:  FullKumaPlayer(
            controller: _playerController,
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    _playerController = KumaPlayerController.network(widget.url);
  }

  @override
  void dispose() {
    super.dispose();
    _playerController.dispose();
  }
}
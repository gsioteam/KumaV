
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dapp/widgets/dimage.dart';
import 'package:flutter_dapp/widgets/drefresh.dart';
import 'package:glib/utils/git_repository.dart';
import 'package:kumav/utils/manager.dart';
import 'package:kumav/utils/plugin.dart';
import 'package:kumav/utils/plugins.dart';
import 'package:kumav/widgets/hint_point.dart';
import 'package:kumav/widgets/progress_dialog.dart';
import 'package:kumav/widgets/progress_items.dart';
import '../localizations/localizations.dart';
import '../utils/image_providers.dart';

const LibURL = "https://api.github.com/repos/gsioteam/kumav_env/issues/1/comments?per_page={1}&page={0}";
const _PublicKey = "ANQqTHBeT2ODNcIyykThqm-6uxcYRjStcp17i6bVOe5A";

class PluginCell extends StatefulWidget {
  final PluginInfo info;

  PluginCell({
    Key? key,
    required this.info,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _PluginCellState();

}

class _PluginCellState extends State<PluginCell> {

  bool _disposed = false;
  Plugin? plugin;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    var plugin = this.plugin;
    if (plugin == null) {
      return ListTile(
        leading: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: widget.info.icon == null ? buildIdenticon(
            widget.info.src,
            width: 48,
            height: 48,
          ) : DImage(
            src: widget.info.icon!,
            width: 48,
            height: 48,
          ),
        ),
        title: Text(widget.info.title),
      );
    } else if (plugin.isValidate) {
      String? icon = plugin.information!.icon ?? widget.info.icon;
      GitRepository repo = plugin.getRepository(widget.info.branch ?? "master")!;

      bool hasNew = repo.localID() != repo.highID();
      bool isCurrent = plugin.id == Manager.instance.plugins.current?.id;
      return ListTile(
        leading: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              icon == null ? buildIdenticon(
                widget.info.src,
                width: 48,
                height: 48,
              ) : pluginImage(
                plugin,
                width: 48,
                height: 48,
              ),
              if (hasNew) Positioned(
                right: -4,
                top: -2,
                child: HintPoint(
                  size: 12,
                )
              ),
            ],
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCurrent) Icon(Icons.arrow_right, color: Theme.of(context).primaryColor,),
            Text(widget.info.title),
          ],
        ),
        subtitle: Text("Ver.${repo.localID()}"),
        trailing: IconButton(
          onPressed: _upgrade,
          icon: Icon(Icons.refresh),
          color: Theme.of(context).primaryColor,
        ),
        onTap: _setPlugin,
      );
    } else {
      String? icon = widget.info.icon;
      return ListTile(
        leading: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: icon == null ? buildIdenticon(
            widget.info.src,
            width: 48,
            height: 48,
          ) : DImage(
            src: icon,
            width: 48,
            height: 48,
          ),
        ),
        title: Text(widget.info.title),
        subtitle: Text(loc("not_installed")),
        onTap: _install,
      );
    }
  }

  @override
  void initState() {
    super.initState();

    _setup();
  }

  @override
  void dispose() {
    super.dispose();
    _disposed = true;
  }

  Future<void> _setup() async {
    var manager = Manager.instance.plugins;
    String id = widget.info.id;
    plugin = manager[id];
    if (plugin == null) {
      var plg = await manager.loadPlugin(id);
      if (_disposed) return;
      setState(() {
        plugin = plg;
      });
    }
  }

  Future<void> _install() async {
    var ret = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(loc('confirm')),
          content: Text(loc('install_confirm', arguments: {
            'url': widget.info.src
          })),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text(loc('no'))
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text(loc('yes'))
            ),
          ],
        );
      }
    );
    if (ret == true) {
      plugin = await Manager.instance.plugins.loadPlugin(widget.info.id);

      var ret = await showDialog<ProgressResult>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return ProgressDialog(
            item: GitItem(() {
              return plugin!.clone(widget.info.src, widget.info.branch ?? "master");
            }, loc("loading")),
          );
        }
      );
      if (ret == ProgressResult.Success) {
        plugin = await Manager.instance.plugins.loadPlugin(widget.info.id);
        setState(() {});
        await _setPlugin();
      }
    }
  }

  void _upgrade() async {
    await showDialog<ProgressResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return ProgressDialog(
          item: GitItem(() {
            return plugin!.clone(widget.info.src, widget.info.branch ?? "master");
          }, loc("fetch")),
        );
      }
    );
    setState(() {});
  }

  Future<void> _setPlugin() async {
    var ret = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(loc("confirm")),
            content: Text(loc("select_main_project")),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
                child: Text(loc("no")),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                child: Text(loc("yes")),
              ),
            ],
          );
        }
    );
    if (ret == true) {
      Manager.instance.plugins.current = plugin;
    }
  }
}

class PluginsWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _PluginsState();
}

class _PluginsState extends State<PluginsWidget> {
  List<PluginInfo> data = [];
  bool _disposed = false;
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(loc('plugins')),
        actions: [
          IconButton(
            onPressed: _addNew,
            icon: Icon(Icons.add)
          ),
        ],
      ),
      body: DRefresh(
        loading: loading,
        child: ListView.builder(
          itemBuilder: (context, index) {
            var plugin = data[index];
            return Dismissible(
              key: ValueKey(plugin.id),
              child: PluginCell(
                info: plugin,
              ),
              confirmDismiss: (_) {
                return showDialog<bool>(
                  context: context, 
                  builder: (context) {
                    return AlertDialog(
                      title: Text(loc("confirm")),
                      content: Text(loc("would_remove_project", arguments: {
                        0: plugin.title,
                      })),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(false);
                          },
                          child: Text(loc("no"))
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(true);
                          },
                          child: Text(loc("yes"))
                        ),
                      ],
                    );
                  }
                );
              },
              onDismissed: (_) {
                _removePlugin(plugin);
              },
            );
          },
          itemCount: data.length,
        ),
        onRefresh: _onRefresh,
      ),
    );
  }

  @override
  void setState(VoidCallback fn) {
    if (_disposed) return;
    super.setState(fn);
  }

  @override
  void initState() {
    super.initState();

    _initialize();
    Manager.instance.plugins.addListener(_update);
  }

  @override
  void dispose() {
    super.dispose();
    _disposed = true;

    Manager.instance.plugins.removeListener(_update);
  }

  void _initialize() async {
    var list = await Manager.instance.plugins.all().toList();
    setState(() {
      data = list;
    });

    DateTime updateTime = await Manager.instance.plugins.lastUpdateTime();
    if (DateTime.now().difference(updateTime).inSeconds > 3600) {
      _reload();
    }
  }

  void _update() {
    setState(() {});
  }

  Future<dynamic> loadPlugins() async {
    Dio dio = Dio();
    var uri = Uri.parse(LibURL.replaceFirst("{0}", "0").replaceFirst("{1}", "99"));
    var res = await dio.requestUri(uri, options: Options(
      responseType: ResponseType.json
    ));
    return res.data;
  }

  Future<void> _reload() async {
    setState(() => loading = true);
    try {
      var data = await loadPlugins();

      await Manager.instance.plugins.updateData(_PublicKey, data);

      var list = await Manager.instance.plugins.all().toList();
      setState(() {
        this.data = list;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = true);
    }
  }

  void _addNew() async {
    TextEditingController urlController = TextEditingController();
    TextEditingController branchController = TextEditingController();
    var ret = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(loc("new_project")),
          content: Padding(
            padding: EdgeInsets.only(
              top: 10,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: InputDecoration(
                    labelText: loc("new_project_hint"),
                  ),
                  controller: urlController,
                ),
                TextField(
                  decoration: InputDecoration(
                      labelText: loc("new_project_branch")
                  ),
                  controller: branchController,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text(loc("no")),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text(loc("yes")),
            )
          ],
        );
      },
    );

    if (ret == true) {
      PluginInfo pluginInfo = PluginInfo(
        title: '',
        src: urlController.text,
        branch: branchController.text.isEmpty ? "master" : branchController.text,
      );
      await Manager.instance.plugins.add(pluginInfo);

      var list = await Manager.instance.plugins.all().toList();
      setState(() {
        this.data = list;
      });
    }
    Future.delayed(Duration(seconds: 1)).then((value) {
      urlController.dispose();
      branchController.dispose();
    });
  }

  void _onRefresh() {
    _reload();
  }

  void _removePlugin(PluginInfo pluginInfo) async {
    await Manager.instance.plugins.remove(pluginInfo);
    setState(() {
      data.remove(pluginInfo);
    });
  }
}
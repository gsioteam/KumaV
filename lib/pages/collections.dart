
import 'package:decorated_icon/decorated_icon.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dapp/flutter_dapp.dart';
import 'package:kumav/extensions/js_utils.dart';
import 'package:kumav/pages/plugins.dart';
import 'package:kumav/pages/ext_page.dart';
import 'package:kumav/pages/video.dart';
import 'package:kumav/utils/image_providers.dart';
import 'package:kumav/utils/manager.dart';
import 'package:kumav/utils/plugin.dart';
import 'package:kumav/utils/search_page_route.dart';
import 'package:kumav/widgets/no_data.dart';

import '../localizations/localizations.dart';

class Collections extends StatefulWidget {

  Collections({
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _CollectionsState();
}

const double _LogoSize = 32;

class _CollectionsState extends State<Collections> {

  Plugin? plugin;

  List<GlobalKey> _keys = [];

  @override
  Widget build(BuildContext context) {

    List<Widget> actions = [];
    var extensions = plugin?.information?.extensions;

    if (extensions != null) {
      for (int i = 0, t = extensions.length; i < t; ++i) {
        var extension = extensions[i];
        if (_keys.length <= i) {
          _keys.add(GlobalKey());
        }
        GlobalKey key = _keys[i];
        actions.add(IconButton(
          key: key,
          icon: Icon(extension.getIconData()),
          onPressed: () {
            RenderObject? object = key.currentContext?.findRenderObject();
            var translation = object?.getTransformTo(null).getTranslation();
            var size = object?.semanticBounds.size;
            Offset center;
            if (translation != null) {
              double x = translation.x, y = translation.y;
              if (size != null) {
                x += size.width / 2;
                y += size.height / 2;
              }
              center = Offset(x, y);
            } else {
              center = Offset(0, 0);
            }

            Navigator.of(context).push(SearchPageRoute(
                center: center,
                builder: (context) {
                  return ExtPage(
                    plugin: plugin!,
                    entry: extension.index,
                  );
                }
            ));
          },
        ));
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: _buildLogo(context),
        elevation: plugin?.information?.appBarElevation,
        actions: actions,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (plugin == null) {
      return Stack(
        children: [
          Positioned.fill(child: NoData()),
          Positioned(
              left: 18,
              top: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: DecoratedIcon(
                        Icons.arrow_upward,
                        color: Theme.of(context).disabledColor,
                        size: 16,
                        shadows: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.surface,
                            offset: Offset(1, 1)
                          ),
                        ]
                    ),
                  ),
                  Text(
                    loc('click_to_select'),
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).disabledColor,
                        shadows: [
                          Shadow(
                              color: Theme.of(context).colorScheme.surface,
                              offset: Offset(1, 1)
                          ),
                        ]
                    ),
                  )
                ],
              )
          ),
        ],
      );
    } else {
      String index = plugin!.information!.index;
      if (index[0] != '/') {
        index = '/' + index;
      }
      return DApp(
        entry: index,
        fileSystems: [plugin!.fileSystem],
        onInitialize: (script) {
          setupJS(script, plugin!);

          script.global['openVideo'] = script.function((argv) {
            OpenVideoNotification(
              key: argv[0],
              data: jsValueToDart(argv[1]),
              plugin: plugin!
            ).dispatch(context);
          });
        },
      );
    }
  }

  Widget _buildLogo(BuildContext context) {
    return InkWell(
      highlightColor: Theme.of(context).primaryColor,
      child: Container(
        height: 36,
        child: Row(
          children: [
            CircleAvatar(
              radius: _LogoSize / 2,
              backgroundColor: Theme.of(context).colorScheme.background,
              child: ClipOval(
                child: plugin == null ?
                Icon(
                  Icons.extension,
                  size: _LogoSize * 0.66,
                  color: Theme.of(context).colorScheme.onBackground,
                ) : pluginImage(
                  plugin,
                  width: _LogoSize,
                  height: _LogoSize,
                  fit: BoxFit.contain,
                  errorBuilder: (context, e, stack) {
                    return Container(
                      width: _LogoSize,
                      height: _LogoSize,
                      child: Center(
                        child: Icon(
                          Icons.broken_image,
                          color: Theme.of(context).colorScheme.onBackground,
                          size: 16,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 12,
                ),
                child: Text(plugin?.information?.name ?? loc('select_project')),
              ),
            ),
          ],
        ),
      ),
      onTap: () async {
        await Navigator.of(context).push(MaterialPageRoute(builder: (context) {
          return PluginsWidget();
        }));
      },
    );
  }

  @override
  void initState() {
    super.initState();

    plugin = Manager.instance.plugins.current;
    Manager.instance.plugins.addListener(_update);
  }

  @override
  void dispose() {
    super.dispose();
    Manager.instance.plugins.removeListener(_update);
  }

  void _update() {
    setState(() {
      plugin = Manager.instance.plugins.current;
    });
  }
}
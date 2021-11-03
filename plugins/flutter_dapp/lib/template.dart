
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/foundation/diagnostics.dart';
import 'package:flutter_dapp/dwidget.dart';
import 'package:flutter_dapp/utils/node_item.dart';
import 'package:flutter_dapp/widgets/dimage.dart';
import 'package:flutter_dapp/widgets/dlistview.dart';
import 'package:flutter_dapp/widgets/drefresh.dart';
import 'package:flutter_dapp/widgets/input.dart';
import 'package:flutter_dapp/widgets/view.dart';
import 'package:js_script/js_script.dart';
import 'package:xml_layout/register.dart';
import 'package:xml_layout/xml_layout.dart';
import 'package:xml_layout/types/colors.dart' as colors;
import 'package:xml_layout/types/icons.dart' as icons;
import 'package:path/path.dart' as path;

import 'widgets/dappbar.dart';
import 'widgets/dbutton.dart';
import 'widgets/tab_container.dart';

Register register = Register(() {
  colors.register();
  icons.register();
  XmlLayout.register("scaffold", (node, key) {
    return Scaffold(
      key: key,
      appBar: node.s<PreferredSizeWidget>("appBar"),
      body: node.s<Widget>("body"),
      floatingActionButton: node.s<Widget>("floatingActionButton"),
      drawer: node.s<Widget>("drawer"),
      endDrawer: node.s<Widget>("endDrawer"),
      bottomNavigationBar: node.s<Widget>("bottomNavigationBar"),
      bottomSheet: node.s<Widget>("bottomSheet"),
      backgroundColor: node.s<Color>("background"),
      resizeToAvoidBottomInset: node.s<bool>("resizeToAvoidBottomInset"),
    );
  });
  XmlLayout.registerEnum(MainAxisAlignment.values);
  XmlLayout.registerEnum(MainAxisSize.values);
  XmlLayout.registerEnum(CrossAxisAlignment.values);
  XmlLayout.registerEnum(VerticalDirection.values);
  XmlLayout.registerEnum(TextDirection.values);
  XmlLayout.registerEnum(TextBaseline.values);
  XmlLayout.registerEnum(BoxFit.values);
  XmlLayout.register("row", (node, key) {
    return Row(
      key: key,
      mainAxisAlignment: node.s<MainAxisAlignment>("mainAxisAlignment",
          MainAxisAlignment.start)!,
      mainAxisSize: node.s<MainAxisSize>("mainAxisSize", MainAxisSize.max)!,
      crossAxisAlignment: node.s<CrossAxisAlignment>("crossAxisAlignment",
          CrossAxisAlignment.center)!,
      verticalDirection: node.s<VerticalDirection>("verticalDirection",
          VerticalDirection.down)!,
      textDirection: node.s<TextDirection>("textDirection"),
      textBaseline: node.s<TextBaseline>("textBaseline"),
      children: node.children<Widget>(),
    );
  });
  XmlLayout.register("column", (node, key) {
    return Column(
      key: key,
      mainAxisAlignment: node.s<MainAxisAlignment>("mainAxisAlignment",
          MainAxisAlignment.start)!,
      mainAxisSize: node.s<MainAxisSize>("mainAxisSize", MainAxisSize.max)!,
      crossAxisAlignment: node.s<CrossAxisAlignment>("crossAxisAlignment",
          CrossAxisAlignment.center)!,
      verticalDirection: node.s<VerticalDirection>("verticalDirection",
          VerticalDirection.down)!,
      textDirection: node.s<TextDirection>("textDirection"),
      textBaseline: node.s<TextBaseline>("textBaseline"),
      children: node.children<Widget>(),
    );
  });
  XmlLayout.register("center", (node, key) {
    return Center(
      key: key,
      widthFactor: node.s<double>("widthFactor"),
      heightFactor: node.s<double>("heightFactor"),
      child: node.child<Widget>(),
    );
  });
  XmlLayout.registerEnum(DButtonType.values);
  XmlLayout.register("button", (node, key) {
    return DButton(
      key: key,
      child: node.child<Widget>()!,
      onPressed: node.s<VoidCallback>("onPressed"),
      onLongPress: node.s<VoidCallback>("onLongPress"),
      type: node.s<DButtonType>("type", DButtonType.elevated)!,
    );
  });
  XmlLayout.register("text", (node, key) {
    return Text(
      node.text,
      style: TextStyle(
        color: node.s<Color>("color")
      ),
    );
  });
  XmlLayout.register("widget", (node, key) {
    var data = DWidget.of(node.context)!;
    String file = node.s<String>("src")!;
    if (file[0] != '/') {
      file = path.join(data.file, '..', file);
    }
    return DWidget(
      script: data.controller.script,
      file: path.normalize(file),
      controllerBuilder: data.controllerBuilder,
      initializeData: node.s("data"),
    );
  });
  XmlLayout.registerInline(Color, "hex", false, (node, method) {
    var val = method[0];
    if (val is String) {
      if (val[0] == '#') {
        if (val.length == 4) {
          String r = val[1], g = val[2], b = val[3];
          return Color(int.parse("0xff$r$r$g$g$b$b"));
        } else if (val.length == 5) {
          String r = val[1], g = val[2], b = val[3], a = val[4];
          return Color(int.parse("0x$a$a$r$r$g$g$b$b"));
        } else if (val.length == 7) {
          return Color(int.parse("0xff${val.substring(1)}"));
        } else if (val.length == 9) {
          return Color(int.parse("0x${val.substring(7, 9)}${val.substring(1, 7)}"));
        } else {
          return Color(int.parse(val.replaceFirst('#', '0x')));
        }
      }
      return Color(int.parse(val));
    } else if (val is int) {
      return Color(val);
    }
    return null;
  });
  XmlLayout.register("AppBar", (node, key) {
    return DAppBar(
      key: key,
      child: node.child<Widget>(),
      leading: node.s<Widget>("leading"),
      actions: node.array<Widget>("actions"),
      bottom: node.s<PreferredSizeWidget>("bottom"),
      brightness: node.s<Brightness>("brightness"),
      background: node.s<Color>("background"),
      color: node.s<Color>("color"),
      height: node.s<double>("height", 56)!,
    );
  });
  XmlLayout.registerEnum(Brightness.values);
  XmlLayout.registerEnum(DragStartBehavior.values);
  XmlLayout.register("list-view", (node, key) {
    String? item = node.s<String>('item');
    if (item != null) {
      var data = DWidget.of(node.context)!;
      String file = node.s<String>("src")!;
      if (file[0] != '/') {
        file = path.join(data.file, '..', file);
      }
      return DListView(
        builder: (context, index) {
          return DWidget(
            script: data.controller.script,
            file: file,
            controllerBuilder: data.controllerBuilder,
          );
        },
        itemCount: node.s<int>('itemCount', 0)!,
        padding: node.s<EdgeInsets>('padding', EdgeInsets.zero)!,
      );
    } else {
      return DListView(
        builder: node.s<IndexedWidgetBuilder>('builder')!,
        itemCount: node.s<int>('itemCount', 0)!,
        padding: node.s<EdgeInsets>('padding', EdgeInsets.zero)!,
      );
    }
  });
  XmlLayout.register("list-item", (node, key) {
    return ListTile(
      leading: node.s<Widget>("leading"),
      title: node.s<Widget>("title"),
      subtitle: node.s<Widget>("subtitle"),
      trailing: node.s<Widget>("trailing"),
      onTap: node.s<VoidCallback>("onTap"),
      dense: node.s<bool>("dense",),
      contentPadding: node.s<EdgeInsets>("padding"),
      tileColor: node.s<Color>("color"),
    );
  });
  var imgBuilder = (node, key) {
    return DImage(
      src: node.s<String>("src")!,
      width: node.s<double>("width", 48.0),
      height: node.s<double>("height", 48.0),
      fit: node.s<BoxFit>("fit", BoxFit.contain)!,
    );
  };
  XmlLayout.register("img", imgBuilder);
  XmlLayout.register("image", imgBuilder);
  XmlLayout.register("callback", (node, key) {
    return ([a0, a1, a2, a3, a4]) {
      var data = DWidget.of(node.context);
      data!.controller.invoke(node.s<String>("function")!, node.s<List>("args", [a0, a1, a2, a3, a4])!);
    };
  });
  XmlLayout.registerInlineMethod("length", (method, status) {
    var obj = method[0];
    if (obj == null) return 0;
    else if (obj is JsValue) {
      return obj["length"];
    } else {
      return obj.length;
    }
  });
  XmlLayout.registerInlineMethod("array", (method, status) {
    List arr = [];
    for (int i = 0, t = method.length; i < t; ++i) {
      arr.add(method[i]);
    }
    return arr;
  });
  XmlLayout.register("refresh", (node, key) {
    return DRefresh(
      child: node.child<Widget>()!,
      loading: node.s<bool>("loading", false)!,
      onRefresh: node.s<VoidCallback>("onRefresh"),
      onLoadMore: node.s<VoidCallback>("onLoadMore"),
      refreshInset: node.s<double>("refreshInset", 36)!,
    );
  });
  XmlLayout.registerInline(EdgeInsets, "zero", true, (node, method) => EdgeInsets.zero);
  XmlLayout.registerInline(EdgeInsets, "ltrb", false, (node, method) =>
      EdgeInsets.fromLTRB(
          (method[0] as num).toDouble(),
          (method[1] as num).toDouble(),
          (method[2] as num).toDouble(),
          (method[3] as num).toDouble())
  );
  XmlLayout.registerInline(EdgeInsets, "symmetric", false, (node, method) =>
      EdgeInsets.symmetric(
        horizontal: (method[0] as num).toDouble(),
        vertical: (method[1] as num).toDouble(),
      )
  );
  XmlLayout.register('tabs', (node, key) {
    var items = node.children<TabItem>();
    List<Widget> tabs = [];
    List<Widget> children = [];
    for (var item in items) {
      tabs.add(Tab(
        text: item.title,
        icon: item.icon,
      ));
      children.add(item.child);
    }

    return DefaultTabController(
      length: children.length,
      child: Scaffold(
        appBar: TabContainer(
          tabs: tabs,
          isScrollable: node.s<bool>("scrollable", false)!,
          elevation: node.s<double>("elevation", 0)!,
        ),
        body: TabBarView(
          children: children,
        ),
        backgroundColor: node.s<Color>("background"),
      ),
    );
  });
  XmlLayout.register('tab', (node, key) {
    return TabItem(
      title: node.s<String>('title'),
      icon: node.s<Widget>('icon'),
      child: node.child<Widget>()!,
    );
  });
  XmlLayout.register('item', (node, key) {
    return NodeItem(node);
  });
  XmlLayout.register("input", (node, key) {
    return Input(
      key: key,
      placeholder: node.s<String>("placeholder"),
      text: node.s<String>("text", "")!,
      autofocus: node.s<bool>("autofocus", false)!,
      onChange: node.s<InputChangedCallback>("onChange"),
      onSubmit: node.s<InputSubmitCallback>("onSubmit"),
      onFocus: node.s<VoidCallback>("onFocus"),
      onBlur: node.s<VoidCallback>("onBlur"),
      style: node.s<TextStyle>("style"),
    );
  });
  XmlLayout.register("icon", (node, key) {
    return Icon(
      node.child<IconData>(),
      key: key,
      size: node.s<double>("size"),
      color: node.s<Color>("color"),
    );
  });
  XmlLayout.register("textstyle", (node, key) {
    return TextStyle(
      color: node.s<Color>("color"),
      backgroundColor: node.s<Color>("background"),
      fontSize: node.s<double>("size"),
    );
  });
  XmlLayout.register("stack", (node, key) {
    return Stack(
      key: key,
      alignment: node.s<Alignment>("alignment", Alignment.topLeft)!,
      children: node.children<Widget>(),
      textDirection: node.s<TextDirection>("textDirection"),
      fit: node.s<StackFit>("fit", StackFit.loose)!,
      clipBehavior: node.s<Clip>("clip", Clip.hardEdge)!,
    );
  });
  XmlLayout.registerInline(Alignment, "topLeft", true, (node, method) => Alignment.topLeft);
  XmlLayout.registerInline(Alignment, "topCenter", true, (node, method) => Alignment.topCenter);
  XmlLayout.registerInline(Alignment, "topRight", true, (node, method) => Alignment.topRight);
  XmlLayout.registerInline(Alignment, "centerLeft", true, (node, method) => Alignment.centerLeft);
  XmlLayout.registerInline(Alignment, "center", true, (node, method) => Alignment.center);
  XmlLayout.registerInline(Alignment, "centerRight", true, (node, method) => Alignment.centerRight);
  XmlLayout.registerInline(Alignment, "bottomLeft", true, (node, method) => Alignment.bottomLeft);
  XmlLayout.registerInline(Alignment, "bottomCenter", true, (node, method) => Alignment.bottomCenter);
  XmlLayout.registerInline(Alignment, "bottomRight", true, (node, method) => Alignment.bottomRight);
  XmlLayout.registerEnum(StackFit.values);
  XmlLayout.registerEnum(Clip.values);
  XmlLayout.register("view", (node, key) {
    return View(
      key: key,
      width: node.s<double>("width"),
      height: node.s<double>("height"),
      color: node.s<Color>("color"),
      child: node.child<Widget>(),
    );
  });
  XmlLayout.registerInlineMethod("isNull", (method, status) {
    return method[0] == null;
  });
  XmlLayout.registerInlineMethod("isNotNull", (method, status) {
    return method[0] != null;
  });
  XmlLayout.registerInlineMethod("switch", (method, status) {
    if (method[0] == true) {
      return method[1];
    } else {
      return method[2];
    }
  });
});
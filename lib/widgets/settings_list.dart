
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_picker/flutter_picker.dart';

enum SettingItemType {
  Header,
  Switch,
  Input,
  Options,
  Customer,
  Label,
  Button,
}

typedef ValueChangedCallback = void Function(dynamic);

class OptionItem {
  String text;
  dynamic value;

  OptionItem(this.text, this.value);
}

class SettingItem {
  SettingItemType type;
  String title;
  String subtitle;
  dynamic value;
  dynamic data;
  ValueChangedCallback onChange;

  SettingItem(this.type, this.title, {this.subtitle, this.value, this.data, this.onChange});
}

class SettingsList extends StatefulWidget {
  final List<SettingItem> items;

  SettingsList({Key key, this.items}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _SettingsListState();

}

class _SettingsListState extends State<SettingsList> {

  String findOptionsName(SettingItem item, dynamic value) {
    List<OptionItem> data = item.data;
    for (OptionItem it in data) {
      if (it.value == value) {
        return it.text;
      }
    }
    return null;
  }

  int findOptionsIndex(SettingItem item, dynamic value) {
    List<OptionItem> data = item.data;
    for (int i = 0, t = data.length; i < t; ++i) {
      if (data[i].value == value) {
        return i;
      }
    }
    return 0;
  }

  Widget buildStyleTrailing1(SettingItem item) {
    switch (item.type) {
      case SettingItemType.Options:
      case SettingItemType.Input:
        {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(findOptionsName(item, item.value)),
            Icon(Icons.chevron_right)
          ],
        );
      }
      case SettingItemType.Switch: {
        return Switch(
          value: item.value == true,
          onChanged: (value) {
            item.onChange?.call(value);
          }
        );
      }
      case SettingItemType.Label: {
        return Text(item.value);
      }
      case SettingItemType.Button: {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(item.value),
            Icon(Icons.chevron_right)
          ],
        );
      }
      default: return null;
    }
  }

  Widget buildStyle1(SettingItem item, [GestureTapCallback onTap]) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          title: Text(item.title),
          subtitle: item.subtitle == null ? null : Text(item.subtitle),
          trailing: buildStyleTrailing1(item),
          onTap: onTap,
        ),
        Divider(height: 1,)
      ],
    );
  }

  Future<T> pickerValue<T>(List<PickerItem<T>> data, int index) {
    Completer<T> completer = Completer();
    Picker picker = new Picker(
      adapter: PickerDataAdapter<T>(
        data: data,
      ),
      selecteds: [index],
      onConfirm: (picker, selects) {
        completer.complete(data[selects[0]].value);
      }
    );
    picker.showModal(context);
    return completer.future;
  }

  Widget buildItem(SettingItem item) {
    switch (item.type) {
      case SettingItemType.Header: {
        return Container(
          padding: EdgeInsets.only(left: 15, right: 15, top: 5, bottom: 5),
          color: Colors.blueGrey[50],
          child: Text(item.title, style: Theme.of(context).textTheme.bodyText1.copyWith(fontWeight: FontWeight.bold),),
        );
      }
      case SettingItemType.Options: {
        return buildStyle1(item, () async {
          dynamic newValue = await pickerValue((item.data as Iterable<OptionItem>).map<PickerItem<dynamic>>((e) {
            return PickerItem<dynamic>(
                text: Text(e.text),
                value: e.value
            );
          }).toList(), findOptionsIndex(item, item.value));
          item.onChange?.call(newValue);
        });
      }
      case SettingItemType.Switch: {
        return buildStyle1(item);
      }
      case SettingItemType.Input: {
        return buildStyle1(item, () async {
//          showDialog(
//              context: context
//          );
        });
      }
      case SettingItemType.Customer: {
        return item.data;
      }
      case SettingItemType.Label: {
        return buildStyle1(item);
      }
      case SettingItemType.Button: {
        return buildStyle1(item, item.data);
      }
      default: return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: ClampingScrollPhysics(),
      itemBuilder: (context, index) {
        SettingItem item = widget.items[index];
        return buildItem(item);
      },
      itemCount: widget.items.length
    );
  }

}
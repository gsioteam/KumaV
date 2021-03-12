
import 'package:flutter/material.dart';
import 'package:glib/main/context.dart';
import 'package:glib/main/project.dart';

import 'widgets/item_list.dart';

class CollectionPage extends StatelessWidget {

  final String title;
  final Project project;
  final Context context;

  CollectionPage({this.title, this.project, this.context});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: ItemListPage(project, this.context),
    );
  }
}

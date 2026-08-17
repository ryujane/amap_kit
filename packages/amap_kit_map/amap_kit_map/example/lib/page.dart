import 'package:flutter/material.dart';

abstract class MapExampleAppPage extends StatelessWidget {
  const MapExampleAppPage(this.leading, this.title, {super.key});

  final Widget leading;
  final String title;
}

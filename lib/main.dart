import 'package:flutter/material.dart';

import 'game.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  static const MAIN_TITLE = 'Game of life';
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: MAIN_TITLE,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const Game(title: MAIN_TITLE),
    );
  }
}

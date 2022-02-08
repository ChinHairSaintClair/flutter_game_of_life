import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Game of life',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Game of life'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late StreamSubscription _periodicSub;

  bool _running = false;
  List<List<bool>> _tracker = _generateList();

  static const int _milliseconds = 250;
  static const int _gridSize = 50; //20;

  @override
  void initState() {
    //_periodicSub = Stream.periodic(const Duration(milliseconds: 500))
    _periodicSub = Stream.periodic(const Duration(milliseconds: _milliseconds))
        //.take(10)
        //.listen((_) => print('tick'));
        .listen((_) => _running ? _buildNextIteration() : print('empty tick'));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildContent(),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  _buildAppBar() {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.help),
        tooltip: "Wikipedia - Conway's game of life",
        onPressed: () => _openWikiLink(),
      ),
      title: Text(widget.title),
      centerTitle: true,
      actions: [
        InkWell(
          child: CircleAvatar(
            child: _running
                ? const Icon(Icons.stop)
                : const Icon(Icons.play_arrow),
          ),
          onTap: () => _running ? _stopGame() : _runGame(),
        ),
      ],
    );
  }

  _buildContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        const Center(
            child: Text(
          'Feel free to customize the list, by clicking on the items, before running the the game.',
          textAlign: TextAlign.center,
        )),
        AspectRatio(
          aspectRatio: 1,
          child: Row(
            children: [
              ..._tracker
                  .asMap()
                  .map((outerIndex, outer) {
                    return MapEntry(
                      outerIndex,
                      Expanded(
                        child: Column(
                          children: [
                            ...outer
                                .asMap()
                                .map((innerIndex, inner) {
                                  return MapEntry(
                                    innerIndex,
                                    Expanded(
                                      child: InkWell(
                                        child: Center(
                                          //child: Text(inner ? "x" : 'o'),
                                          child: Container(
                                            color: inner
                                                ? Colors.black
                                                : Colors.white,
                                          ),
                                        ),
                                        onTap: () => !_running
                                            ? _manuallyToggleBlockState(
                                                outerIndex,
                                                innerIndex,
                                              )
                                            : null,
                                      ),
                                    ),
                                  );
                                })
                                .values
                                .toList(),
                          ],
                        ),
                      ),
                    );
                  })
                  .values
                  .toList(),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Generation interval:'),
                OutlinedButton(
                  child: const Text('${_milliseconds/1000} seconds'),
                  onPressed: () {
                    // TODO:
                  },
                ),
              ],
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Grid size:'),
                OutlinedButton(
                  child: const Text('$_gridSize x $_gridSize blocks'),
                  onPressed: () {
                    // TODO:
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  _buildFloatingActionButton() {
    return !_running
        ? FloatingActionButton(
            onPressed: _reset,
            tooltip: 'reset',
            child: const Icon(Icons.threesixty),
          )
        : null;
  }

  _openWikiLink() async {
    const url = "https://en.wikipedia.org/wiki/Conway%27s_Game_of_Life";
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Could not launch $url")));
    }
  }

  static List<List<bool>> _generateList() {
    //return List.generate(10, (index) => List.generate(10, (i) => index % 2 == 0 && i % 2 == 0));
    //return List.generate(10, (index) => List.generate(10, (i) => Random().nextBool()));
    return List.generate(_gridSize,
        (index) => List.generate(_gridSize, (i) => Random().nextBool()));
  }

  _manuallyToggleBlockState(int x, y) {
    setState(() {
      _tracker[x][y] = !_tracker[x][y];
    });
  }

  _runGame() async {
    if (_running) {
      return;
    }

    setState(() {
      _running = true;
    });
  }

  _buildNextIteration() {
    print('playing tick');

    // Create empty list
    var _nextGeneration = List.generate(_tracker.length,
        (index) => List.generate(_tracker[index].length, (_) => false));

    //for (int x = 0; x < _tracker.length; x++) {
    for (int x = 1; x < _tracker.length - 1; x++) {
      //for (int y = 0; y < _tracker[x].length; y++) {
      for (int y = 1; y < _tracker[x].length - 1; y++) {
        bool isAlive = _tracker[x][y];

        bool newState;
        if (isAlive && _willSurvive(x, y)) {
          newState = true;
        } else if (!isAlive && _canBeResurrected(x, y)) {
          newState = true;
        }
        // All other live cells die in the next generation. Similarly, all other dead cells stay dead.
        else {
          newState = false;
        }

        _nextGeneration[x][y] = newState;
      }
    }

    setState(() {
      //_tracker = _generateList();
      _tracker = _nextGeneration;
    });
  }

  _willSurvive(int x, int y) {
    // Any live cell with two or three live neighbours survives.
    var count = _determineAliveNeighbourCount(x, y);
    return count == 2 || count == 3;
  }

  _canBeResurrected(int x, int y) {
    // Any dead cell with three live neighbours becomes a live cell.
    return _determineAliveNeighbourCount(x, y) == 3;
  }

  _determineAliveNeighbourCount(int x, int y) {
    int aliveCount = 0;

    print('The coord of neighbours checked: $x ; $y');

    // Because the the end pointer is not included in the result
    //var taken = [..._tracker.getRange(x - 1, x + 2)];
    List<List<bool?>> taken = [..._tracker.getRange(x - 1, x + 2)];
    for (var element in taken) {
      taken[taken.indexOf(element)] = element.getRange(y - 1, y + 2).toList();
    }

    // Ignore the middle item - the current position
    //taken[1][1] = null; // <- for some reason does not work
    //taken[1].removeAt(1);
    //taken[1].insert(1, null);

    for (int i = 0; i < taken.length; i++) {
      for (int j = 0; j < taken[i].length; j++) {
        if (i == 1 && j == 1) {
          continue; // Ignore your current position
        }

        if (taken[i][j] ?? false) {
          aliveCount++;
        }
      }
    }

    /*for (var element in taken) {
      for (var element in element) {
        if (element??false) {
          aliveCount++;
        }
      }
    }*/

    print('Calculated alive count: $aliveCount');

    return aliveCount;
  }

  _stopGame() async {
    if (!_running) {
      return;
    }

    setState(() {
      _running = false;
    });
  }

  void _reset() {
    setState(() {
      _running = false;
      _tracker = _generateList();
    });
  }

  @override
  void dispose() {
    _periodicSub.cancel();
    super.dispose();
  }
}

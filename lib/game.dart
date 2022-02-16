import 'dart:math';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:game_of_life/value_slider_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

import 'game_constants.dart';

class Game extends StatefulWidget {
  const Game({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<Game> createState() => _GameState();
}

class _GameState extends State<Game> {
  bool _isRunning = false;
  List<List<bool>> _tracker = _generateList();

  static int _milliseconds = DEFAULT_TICK_INTERVAL;
  static int _gridSize = DEFAULT_GRID_SIZE;

  Stream _stream = _createStream();
  late StreamSubscription _periodicSub;

  @override
  void initState() {
    _periodicSub = _createStreamSubscription();
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
        tooltip: WIKI_LINK_TOOLTIP,
        onPressed: () => _openWikiLink(),
      ),
      title: Text(widget.title),
      centerTitle: true,
      actions: [
        InkWell(
          child: CircleAvatar(
            child: _isRunning
                ? const Icon(Icons.pause)
                : const Icon(Icons.play_arrow),
          ),
          onTap: () => _isRunning ? _pauseGame() : _runGame(),
        ),
      ],
    );
  }

  _buildContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: _buildDescription(),
        ),
        _buildGameGrid(),
        Expanded(child: _buildControls()),
      ],
    );
  }

  Center _buildDescription() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Text(
            GAME_INSTRUCTION_HEADER,
            style: TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          Text(GAME_INSTRUCTION_SUB_HEADER),
          Text(GAME_INSTRUCTION_1),
          Text(GAME_INSTRUCTION_2),
        ],
      ),
    );
  }

  AspectRatio _buildGameGrid() {
    return AspectRatio(
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
                                _buildGridItem(inner, outerIndex, innerIndex),
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
    );
  }

  Expanded _buildGridItem(bool isAlive, int rowIndex, int columnIndex) {
    return Expanded(
      child: InkWell(
        child: Center(
          child: Container(
            color: isAlive ? Colors.black : Colors.white,
          ),
        ),
        onTap: () => !_isRunning
            ? _manuallyToggleBlockState(
                rowIndex,
                columnIndex,
              )
            : null,
      ),
    );
  }

  Row _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(TICK_DESCRIPTION_HEADER),
            OutlinedButton(
              child: Text('${_milliseconds / 1000} $TICK_MEASUREMENT'),
              onPressed: _isRunning ? null : () => _setGenerationInterval(),
            ),
          ],
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(GRID_SIZE_DESCRIPTION_HEADER),
            OutlinedButton(
              child: Text('$_gridSize x $_gridSize $GRID_MEASUREMENT'),
              onPressed: _isRunning ? null : () => _setGridSize(),
            ),
          ],
        ),
      ],
    );
  }

  _buildFloatingActionButton() {
    return !_isRunning
        ? FloatingActionButton(
            onPressed: _reset,
            tooltip: RESET,
            child: const Icon(Icons.threesixty),
          )
        : null;
  }

  _openWikiLink() async {
    try{
      var _url = GAME_OF_LIFE_URL;
      if (!await launch(_url)) throw '$UNABLE_TO_LAUNCH_URL $_url';
    }
    catch(e){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString())));
    }
  }

  static List<List<bool>> _generateList() {
    return List.generate(_gridSize,
        (index) => List.generate(_gridSize, (i) => Random().nextBool()));
  }

  static Stream _createStream() {
    return Stream.periodic(Duration(milliseconds: _milliseconds));
  }

  StreamSubscription _createStreamSubscription() {
    return _stream.listen(
        (_) => _isRunning ? _buildNextIteration() : print('empty tick'));
  }

  _manuallyToggleBlockState(int x, y) {
    setState(() {
      _tracker[x][y] = !_tracker[x][y];
    });
  }

  _runGame() async {
    if (_isRunning) {
      return;
    }

    setState(() {
      _isRunning = true;
    });
  }

  _buildNextIteration() {
    var _nextGeneration = List.generate(_tracker.length,
        (index) => List.generate(_tracker[index].length, (_) => false));

    for (int x = 1; x < _tracker.length - 1; x++) {
      for (int y = 1; y < _tracker[x].length - 1; y++) {
        bool isAlive = _tracker[x][y];

        bool newState;
        if (isAlive && _willSurvive(x, y)) {
          newState = true;
        } else if (!isAlive && _canBeResurrected(x, y)) {
          newState = true;
        } else {
          // All other live cells die in the next generation. Similarly, all other dead cells stay dead.
          newState = false;
        }

        _nextGeneration[x][y] = newState;
      }
    }

    setState(() {
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
    // End pointer is not included in the result
    List<List<bool?>> taken = [..._tracker.getRange(x - 1, x + 2)];
    for (var element in taken) {
      taken[taken.indexOf(element)] = element.getRange(y - 1, y + 2).toList();
    }

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

    return aliveCount;
  }

  _pauseGame() async {
    if (!_isRunning) {
      return;
    }

    setState(() {
      _isRunning = false;
    });
  }

  void _reset() {
    setState(() {
      _isRunning = false;
      _tracker = _generateList();
    });
  }

  _setGenerationInterval() async {
    var data = await showDialog(
      context: context,
      builder: (ctx) => ValueSliderDialog(
        title: TICK_DESCRIPTION_HEADER,
        minValue: MIN_TICK_INTERVAL,
        startValue: _milliseconds,
        maxValue: MAX_TICK_INTERVAL,
        cancelText: CANCEL,
        acceptText: ACCEPT,
      ),
    );

    if (data == null) {
      return;
    }

    setState(() {
      _milliseconds = data;
      _periodicSub.cancel();
      _stream = _createStream();
      _periodicSub = _createStreamSubscription();
    });
  }

  _setGridSize() async {
    var data = await showDialog(
      context: context,
      builder: (ctx) => ValueSliderDialog(
        title: GRID_SIZE_DESCRIPTION_HEADER,
        minValue: MIN_GRID_SIZE,
        startValue: _gridSize,
        maxValue: MAX_GRID_SIZE,
        cancelText: CANCEL,
        acceptText: ACCEPT,
      ),
    );

    if (data == null) {
      return;
    }

    setState(() {
      _gridSize = data;
      _tracker = _generateList();
    });
  }

  @override
  void dispose() {
    _periodicSub.cancel();
    super.dispose();
  }
}

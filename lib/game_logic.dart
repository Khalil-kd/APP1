import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'tile.dart';

class GameLogic extends ChangeNotifier {
  static const int size = 4;
  static const int winningValue = 2048;
  static const String _bestScoreKey = 'best_score';

  final Random _random = Random();

  List<Tile> _tiles = <Tile>[];
  int _nextTileId = 1;
  int _score = 0;
  int _bestScore = 0;
  bool _hasWon = false;
  bool _isGameOver = false;

  List<Tile> get tiles => List<Tile>.unmodifiable(_tiles);
  int get score => _score;
  int get bestScore => _bestScore;
  bool get hasWon => _hasWon;
  bool get isGameOver => _isGameOver;

  List<List<int>> get board {
    final values = List.generate(size, (_) => List.filled(size, 0));
    for (final tile in _tiles) {
      values[tile.row][tile.col] = tile.value;
    }
    return values;
  }

  Future<void> loadBestScore() async {
    final prefs = await SharedPreferences.getInstance();
    _bestScore = prefs.getInt(_bestScoreKey) ?? 0;
  }

  Future<void> _saveBestScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_bestScoreKey, _bestScore);
  }

  void startNewGame() {
    _tiles = <Tile>[];
    _nextTileId = 1;
    _score = 0;
    _hasWon = false;
    _isGameOver = false;

    _addRandomTile();
    _addRandomTile();
    notifyListeners();
  }

  void move(MoveDirection direction) {
    if (_isGameOver) {
      return;
    }

    final result = _moveTiles(direction);
    if (!result.changed) {
      return;
    }

    _tiles = result.tiles;
    _score += result.points;
    if (_score > _bestScore) {
      _bestScore = _score;
      _saveBestScore();
    }

    _hasWon = _hasWon || _tiles.any((tile) => tile.value >= winningValue);
    _addRandomTile();
    _isGameOver = !_canMove();
    notifyListeners();
  }

  _MoveResult _moveTiles(MoveDirection direction) {
    final before = _positionSignature(_tiles);
    final movedTiles = <Tile>[];
    var gainedPoints = 0;

    // Each row or column is read in movement order, collapsed, then written
    // back to board coordinates while preserving tile ids for animations.
    for (var lineIndex = 0; lineIndex < size; lineIndex++) {
      final line = _readTileLine(lineIndex, direction);
      final collapsed = _collapseTileLine(line);
      gainedPoints += collapsed.points;

      for (var cellIndex = 0; cellIndex < collapsed.tiles.length; cellIndex++) {
        final tile = collapsed.tiles[cellIndex];
        if (tile == null) {
          continue;
        }

        final position = _positionForLineIndex(lineIndex, cellIndex, direction);
        movedTiles.add(tile.copyWith(row: position.x, col: position.y));
      }
    }

    final after = _positionSignature(movedTiles);
    return _MoveResult(
      changed: before != after,
      points: gainedPoints,
      tiles: movedTiles,
    );
  }

  _CollapsedTileLine _collapseTileLine(List<Tile?> line) {
    final compacted = line.whereType<Tile>().toList();
    final result = <Tile?>[];
    var points = 0;

    // A tile can merge only once per move, matching the original 2048 rules.
    for (var i = 0; i < compacted.length; i++) {
      final current = compacted[i];
      if (i + 1 < compacted.length && current.value == compacted[i + 1].value) {
        final mergedValue = current.value * 2;
        result.add(current.copyWith(
          value: mergedValue,
          isNew: false,
          didMerge: true,
        ));
        points += mergedValue;
        i++;
      } else {
        result.add(current.copyWith(isNew: false, didMerge: false));
      }
    }

    while (result.length < size) {
      result.add(null);
    }

    return _CollapsedTileLine(tiles: result, points: points);
  }

  List<Tile?> _readTileLine(int index, MoveDirection direction) {
    final grid = _tileGrid();
    return switch (direction) {
      MoveDirection.left => List<Tile?>.from(grid[index]),
      MoveDirection.right => List<Tile?>.from(grid[index].reversed),
      MoveDirection.up => List<Tile?>.generate(size, (row) => grid[row][index]),
      MoveDirection.down => List<Tile?>.generate(
          size,
          (row) => grid[size - 1 - row][index],
        ),
    };
  }

  List<List<Tile?>> _tileGrid() {
    final grid = List.generate(size, (_) => List<Tile?>.filled(size, null));
    for (final tile in _tiles) {
      grid[tile.row][tile.col] = tile;
    }
    return grid;
  }

  Point<int> _positionForLineIndex(
    int lineIndex,
    int cellIndex,
    MoveDirection direction,
  ) {
    return switch (direction) {
      MoveDirection.left => Point<int>(lineIndex, cellIndex),
      MoveDirection.right => Point<int>(lineIndex, size - 1 - cellIndex),
      MoveDirection.up => Point<int>(cellIndex, lineIndex),
      MoveDirection.down => Point<int>(size - 1 - cellIndex, lineIndex),
    };
  }

  void _addRandomTile() {
    final occupied = {
      for (final tile in _tiles) '${tile.row}:${tile.col}',
    };
    final emptyCells = <Point<int>>[];

    for (var row = 0; row < size; row++) {
      for (var col = 0; col < size; col++) {
        if (!occupied.contains('$row:$col')) {
          emptyCells.add(Point<int>(row, col));
        }
      }
    }

    if (emptyCells.isEmpty) {
      return;
    }

    final cell = emptyCells[_random.nextInt(emptyCells.length)];
    _tiles = [
      ..._tiles,
      Tile(
        id: _nextTileId++,
        value: _random.nextDouble() < 0.9 ? 2 : 4,
        row: cell.x,
        col: cell.y,
        isNew: true,
      ),
    ];
  }

  bool _canMove() {
    final values = board;
    for (var row = 0; row < size; row++) {
      for (var col = 0; col < size; col++) {
        if (values[row][col] == 0) {
          return true;
        }
        if (row + 1 < size && values[row][col] == values[row + 1][col]) {
          return true;
        }
        if (col + 1 < size && values[row][col] == values[row][col + 1]) {
          return true;
        }
      }
    }
    return false;
  }

  String _positionSignature(List<Tile> tiles) {
    final sorted = List<Tile>.from(tiles)
      ..sort((a, b) => a.id.compareTo(b.id));
    return sorted
        .map((tile) => '${tile.id}:${tile.value}:${tile.row}:${tile.col}')
        .join('|');
  }
}

class _MoveResult {
  const _MoveResult({
    required this.changed,
    required this.points,
    required this.tiles,
  });

  final bool changed;
  final int points;
  final List<Tile> tiles;
}

class _CollapsedTileLine {
  const _CollapsedTileLine({
    required this.tiles,
    required this.points,
  });

  final List<Tile?> tiles;
  final int points;
}

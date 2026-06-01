import 'package:flutter/foundation.dart';

@immutable
class Tile {
  const Tile({
    required this.id,
    required this.value,
    required this.row,
    required this.col,
    this.isNew = false,
    this.didMerge = false,
  });

  final int id;
  final int value;
  final int row;
  final int col;
  final bool isNew;
  final bool didMerge;

  Tile copyWith({
    int? id,
    int? value,
    int? row,
    int? col,
    bool? isNew,
    bool? didMerge,
  }) {
    return Tile(
      id: id ?? this.id,
      value: value ?? this.value,
      row: row ?? this.row,
      col: col ?? this.col,
      isNew: isNew ?? this.isNew,
      didMerge: didMerge ?? this.didMerge,
    );
  }
}

enum MoveDirection { up, down, left, right }

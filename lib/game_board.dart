import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game_logic.dart';
import 'tile.dart';

class GameBoard extends StatefulWidget {
  const GameBoard({super.key, required this.game});

  final GameLogic game;

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.game.addListener(_onGameChanged);
  }

  @override
  void dispose() {
    widget.game.removeListener(_onGameChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onGameChanged() {
    setState(() {});
  }

  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) {
      return;
    }

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.keyW) {
      widget.game.move(MoveDirection.up);
    } else if (key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.keyS) {
      widget.game.move(MoveDirection.down);
    } else if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.keyA) {
      widget.game.move(MoveDirection.left);
    } else if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.keyD) {
      widget.game.move(MoveDirection.right);
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKey,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Header(game: widget.game),
                    const SizedBox(height: 18),
                    _InstructionBar(onRestart: widget.game.startNewGame),
                    const SizedBox(height: 18),
                    _BoardSurface(game: widget.game),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.game});

  final GameLogic game;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Expanded(
          child: Text(
            '2048',
            style: TextStyle(
              color: Color(0xff776e65),
              fontSize: 64,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
        _ScoreBox(label: 'SCORE', value: game.score),
        const SizedBox(width: 8),
        _ScoreBox(label: 'BEST', value: game.bestScore),
      ],
    );
  }
}

class _ScoreBox extends StatelessWidget {
  const _ScoreBox({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 88),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xffbbada0),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xffeee4da),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          Text(
            '$value',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _InstructionBar extends StatelessWidget {
  const _InstructionBar({required this.onRestart});

  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Combine les tuiles et atteins 2048.',
            style: TextStyle(
              color: Color(0xff776e65),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        FilledButton(
          onPressed: onRestart,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xff8f7a66),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          ),
          child: const Text(
            'Nouvelle partie',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _BoardSurface extends StatelessWidget {
  const _BoardSurface({required this.game});

  final GameLogic game;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boardSize = constraints.maxWidth.clamp(280.0, 520.0).toDouble();
        final gap = boardSize * 0.025;
        final tileSize = (boardSize - gap * 5) / GameLogic.size;

        return GestureDetector(
          onHorizontalDragEnd: (details) {
            final velocity = details.primaryVelocity ?? 0;
            if (velocity.abs() < 80) {
              return;
            }
            game.move(velocity > 0 ? MoveDirection.right : MoveDirection.left);
          },
          onVerticalDragEnd: (details) {
            final velocity = details.primaryVelocity ?? 0;
            if (velocity.abs() < 80) {
              return;
            }
            game.move(velocity > 0 ? MoveDirection.down : MoveDirection.up);
          },
          child: SizedBox.square(
            dimension: boardSize,
            child: Stack(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xffbbada0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(gap),
                    child: _BoardGrid(gap: gap),
                  ),
                ),
                for (final tile in game.tiles)
                  AnimatedPositioned(
                    key: ValueKey(tile.id),
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeOutCubic,
                    left: gap + tile.col * (tileSize + gap),
                    top: gap + tile.row * (tileSize + gap),
                    width: tileSize,
                    height: tileSize,
                    child: _TileView(tile: tile),
                  ),
                if (game.hasWon || game.isGameOver)
                  _GameOverlay(
                    isWin: game.hasWon,
                    onRestart: game.startNewGame,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BoardGrid extends StatelessWidget {
  const _BoardGrid({required this.gap});

  final double gap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: GameLogic.size * GameLogic.size,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: GameLogic.size,
        mainAxisSpacing: gap,
        crossAxisSpacing: gap,
      ),
      itemBuilder: (context, index) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xffcdc1b4),
            borderRadius: BorderRadius.circular(6),
          ),
        );
      },
    );
  }
}

class _TileView extends StatelessWidget {
  const _TileView({required this.tile});

  final Tile tile;

  @override
  Widget build(BuildContext context) {
    final value = tile.value;
    final textColor = value <= 4 ? const Color(0xff776e65) : Colors.white;

    return TweenAnimationBuilder<double>(
      key: ValueKey('${tile.id}-${tile.value}-${tile.didMerge}-${tile.isNew}'),
      tween: Tween<double>(
        begin: tile.isNew || tile.didMerge ? 0.72 : 1,
        end: 1,
      ),
      duration: Duration(milliseconds: tile.didMerge ? 180 : 130),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _tileColor(value),
          borderRadius: BorderRadius.circular(6),
          boxShadow: value >= 128
              ? [
                  BoxShadow(
                    color: _tileColor(value).withOpacity(0.35),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '$value',
                style: TextStyle(
                  color: textColor,
                  fontSize: value < 100 ? 40 : 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _tileColor(int value) {
    return switch (value) {
      2 => const Color(0xffeee4da),
      4 => const Color(0xffede0c8),
      8 => const Color(0xfff2b179),
      16 => const Color(0xfff59563),
      32 => const Color(0xfff67c5f),
      64 => const Color(0xfff65e3b),
      128 => const Color(0xffedcf72),
      256 => const Color(0xffedcc61),
      512 => const Color(0xffedc850),
      1024 => const Color(0xffedc53f),
      2048 => const Color(0xffedc22e),
      _ => const Color(0xff3c3a32),
    };
  }
}

class _GameOverlay extends StatelessWidget {
  const _GameOverlay({required this.isWin, required this.onRestart});

  final bool isWin;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AnimatedOpacity(
        opacity: 1,
        duration: const Duration(milliseconds: 180),
        child: Container(
          decoration: BoxDecoration(
            color: (isWin ? const Color(0xffedc22e) : const Color(0xffeee4da))
                .withOpacity(0.78),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isWin ? 'Victoire !' : 'Partie terminee',
                style: TextStyle(
                  color: isWin ? Colors.white : const Color(0xff776e65),
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: onRestart,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xff8f7a66),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Text('Rejouer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

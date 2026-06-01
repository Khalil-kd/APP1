import 'package:flutter/material.dart';

import 'game_board.dart';
import 'game_logic.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final game = GameLogic();
  await game.loadBestScore();
  game.startNewGame();

  runApp(Game2048App(game: game));
}

class Game2048App extends StatelessWidget {
  const Game2048App({super.key, required this.game});

  final GameLogic game;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '2048',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff8f7a66),
          brightness: Brightness.light,
        ),
        fontFamily: 'Arial',
        scaffoldBackgroundColor: const Color(0xfffaf8ef),
        useMaterial3: true,
      ),
      home: GameBoard(game: game),
    );
  }
}

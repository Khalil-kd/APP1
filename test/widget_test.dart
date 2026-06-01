import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_2048/game_logic.dart';
import 'package:flutter_2048/main.dart';

void main() {
  testWidgets('renders the 2048 board', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    final game = GameLogic();
    await game.loadBestScore();
    game.startNewGame();

    await tester.pumpWidget(Game2048App(game: game));

    expect(find.text('2048'), findsOneWidget);
    expect(find.text('SCORE'), findsOneWidget);
    expect(find.text('BEST'), findsOneWidget);
    expect(find.text('Nouvelle partie'), findsOneWidget);
  });
}

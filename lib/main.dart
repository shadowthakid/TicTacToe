import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TicTacToeApp());
}

class TicTacToeApp extends StatelessWidget {
  const TicTacToeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tic Tac Toe',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF6750A4),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(fontWeight: FontWeight.w700),
          titleMedium: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      home: const GamePage(),
    );
  }
}

enum Difficulty { easy, impossible }

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with TickerProviderStateMixin {
  List<String> board = List.filled(9, '');
  String player = 'X'; // Human is X
  String ai = 'O';
  bool gameOver = false;
  String statusText = "Your turn (X)";
  Difficulty difficulty = Difficulty.impossible;

  // Stats
  int wins = 0, losses = 0, draws = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      wins = prefs.getInt('wins') ?? 0;
      losses = prefs.getInt('losses') ?? 0;
      draws = prefs.getInt('draws') ?? 0;
    });
  }

  Future<void> _saveStats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('wins', wins);
    await prefs.setInt('losses', losses);
    await prefs.setInt('draws', draws);
  }

  void _resetBoard() {
    setState(() {
      board = List.filled(9, '');
      gameOver = false;
      statusText = "Your turn (X)";
    });
  }

  Future<void> _showResult(String title, String subtitle) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title),
        content: Text(subtitle),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetBoard();
            },
            child: const Text('Play Again'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _handleTap(int index) {
    if (gameOver || board[index].isNotEmpty) return;
    setState(() {
      board[index] = player;
    });

    final result = _checkWinner(board);
    if (result != null) {
      _endGame(result);
      return;
    }

    // AI move
    Future.delayed(const Duration(milliseconds: 250), () {
      if (gameOver) return;
      final move = (difficulty == Difficulty.easy)
          ? _randomMove(board)
          : _bestMove(board, ai, player);
      if (move != -1) {
        setState(() {
          board[move] = ai;
        });
      }
      final result2 = _checkWinner(board);
      if (result2 != null) {
        _endGame(result2);
      } else {
        setState(() {
          statusText = "Your turn (X)";
        });
      }
    });

    setState(() {
      statusText = "AI thinking…";
    });
  }

  void _endGame(String result) {
    gameOver = true;
    String title;
    String subtitle;
    if (result == player) {
      title = "You Won 🎉";
      subtitle = "Great job!";
      wins++;
    } else if (result == ai) {
      title = "You Lost 😅";
      subtitle = "Try again!";
      losses++;
    } else {
      title = "It's a Draw 🤝";
      subtitle = "Nice defense.";
      draws++;
    }
    _saveStats();
    _showResult(title, subtitle);
  }

  // ----- Game helpers -----

  String? _checkWinner(List<String> b) {
    const lines = [
      [0, 1, 2],
      [3, 4, 5],
      [6, 7, 8],
      [0, 3, 6],
      [1, 4, 7],
      [2, 5, 8],
      [0, 4, 8],
      [2, 4, 6],
    ];
    for (final line in lines) {
      final a = b[line[0]], m = b[line[1]], n = b[line[2]];
      if (a.isNotEmpty && a == m && m == n) return a; // 'X' or 'O'
    }
    if (!b.contains('')) return 'draw';
    return null;
  }

  int _randomMove(List<String> b) {
    final empty = <int>[];
    for (int i = 0; i < b.length; i++) {
      if (b[i].isEmpty) empty.add(i);
    }
    if (empty.isEmpty) return -1;
    return empty[Random().nextInt(empty.length)];
  }

  int _bestMove(List<String> b, String aiPlayer, String humanPlayer) {
    int bestScore = -1000;
    int move = -1;
    for (int i = 0; i < 9; i++) {
      if (b[i].isEmpty) {
        b[i] = aiPlayer;
        final score = _minimax(b, 0, false, aiPlayer, humanPlayer);
        b[i] = '';
        if (score > bestScore) {
          bestScore = score;
          move = i;
        }
      }
    }
    return move;
  }

  int _minimax(
    List<String> b,
    int depth,
    bool isMax,
    String aiPlayer,
    String humanPlayer,
  ) {
    final result = _checkWinner(b);
    if (result != null) {
      if (result == aiPlayer) return 10 - depth;
      if (result == humanPlayer) return depth - 10;
      return 0; // draw
    }

    if (isMax) {
      int best = -1000;
      for (int i = 0; i < 9; i++) {
        if (b[i].isEmpty) {
          b[i] = aiPlayer;
          best = max(
            best,
            _minimax(b, depth + 1, false, aiPlayer, humanPlayer),
          );
          b[i] = '';
        }
      }
      return best;
    } else {
      int best = 1000;
      for (int i = 0; i < 9; i++) {
        if (b[i].isEmpty) {
          b[i] = humanPlayer;
          best = min(best, _minimax(b, depth + 1, true, aiPlayer, humanPlayer));
          b[i] = '';
        }
      }
      return best;
    }
  }

  // ----- UI -----

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tic Tac Toe'),
        actions: [
          IconButton(
            tooltip: "Stats",
            icon: const Icon(Icons.bar_chart_rounded),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StatsPage(
                    wins: wins,
                    losses: losses,
                    draws: draws,
                    onClear: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.remove('wins');
                      await prefs.remove('losses');
                      await prefs.remove('draws');
                      setState(() {
                        wins = 0;
                        losses = 0;
                        draws = 0;
                      });
                    },
                  ),
                ),
              );
              _loadStats();
            },
          ),
          PopupMenuButton<Difficulty>(
            tooltip: "Difficulty",
            initialValue: difficulty,
            onSelected: (d) {
              setState(() => difficulty = d);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    d == Difficulty.easy
                        ? "Difficulty: Easy"
                        : "Difficulty: Impossible",
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: Difficulty.easy, child: Text('Easy')),
              const PopupMenuItem(
                value: Difficulty.impossible,
                child: Text('Impossible'),
              ),
            ],
            icon: const Icon(Icons.tune_rounded),
          ),
          IconButton(
            tooltip: "New Game",
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _resetBoard,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [cs.surface, cs.surfaceContainerHighest],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ScoreStrip(wins: wins, losses: losses, draws: draws),
                const SizedBox(height: 16),
                AspectRatio(
                  aspectRatio: 1,
                  child: _Board(board: board, onTap: _handleTap),
                ),
                const SizedBox(height: 16),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    statusText,
                    key: ValueKey(statusText),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _resetBoard,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text("New Game"),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Board extends StatelessWidget {
  final List<String> board;
  final void Function(int) onTap;

  const _Board({required this.board, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: 9,
      itemBuilder: (context, i) {
        final value = board[i];
        return Material(
          color: cs.primaryContainer,
          borderRadius: BorderRadius.circular(24),
          elevation: 1,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => onTap(i),
            child: Center(
              child: AnimatedScale(
                duration: const Duration(milliseconds: 150),
                scale: value.isEmpty ? 0.9 : 1.0,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 42,
                    height: 1,
                    fontWeight: FontWeight.bold,
                    color: value == 'X' ? cs.primary : cs.tertiary,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ScoreStrip extends StatelessWidget {
  final int wins, losses, draws;

  const _ScoreStrip({
    required this.wins,
    required this.losses,
    required this.draws,
  });

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelLarge;

    Widget card(String label, int value, IconData icon) {
      return Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 6),
              Text("$label: $value", style: labelStyle),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        card("Wins", wins, Icons.check_circle_rounded),
        card("Draws", draws, Icons.remove_circle_rounded),
        card("Losses", losses, Icons.cancel_rounded),
      ],
    );
  }
}

class StatsPage extends StatelessWidget {
  final int wins, losses, draws;
  final Future<void> Function() onClear;

  const StatsPage({
    super.key,
    required this.wins,
    required this.losses,
    required this.draws,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final total = wins + losses + draws;
    String rate(int a) {
      if (total == 0) return "0%";
      return "${((a / total) * 100).toStringAsFixed(0)}%";
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance'),
        actions: [
          IconButton(
            tooltip: "Clear Stats",
            icon: const Icon(Icons.delete_sweep_rounded),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Reset stats?"),
                  content: const Text(
                    "This will clear wins, losses and draws.",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Cancel"),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Reset"),
                    ),
                  ],
                ),
              );
              if (ok == true) {
                await onClear();
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _StatCard(
                  title: "Wins",
                  value: wins,
                  percent: rate(wins),
                  icon: Icons.check_circle_rounded,
                ),
                const SizedBox(height: 12),
                _StatCard(
                  title: "Draws",
                  value: draws,
                  percent: rate(draws),
                  icon: Icons.remove_circle_rounded,
                ),
                const SizedBox(height: 12),
                _StatCard(
                  title: "Losses",
                  value: losses,
                  percent: rate(losses),
                  icon: Icons.cancel_rounded,
                ),
                const Spacer(),
                Text(
                  "Total games: $total",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final int value;
  final String percent;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.percent,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Icon(icon, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "$title: $value",
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(percent, style: Theme.of(context).textTheme.labelLarge),
          ),
        ],
      ),
    );
  }
}

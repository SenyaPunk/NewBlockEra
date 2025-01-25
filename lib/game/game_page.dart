import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/src/services/predictive_back_event.dart';
import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'constants.dart';
import 'models/player.dart';
import 'models/enemy.dart';
import 'models/heart.dart';
import 'models/weapon.dart';
import 'models/bullet.dart';
import 'models/star.dart';
import 'models/coin_animation.dart';
import 'models/shop_data.dart';
import 'painters/game_painter.dart';

typedef GameEndCallback = void Function(int score, int coins);

class GamePage extends StatefulWidget {
  final int currentHighScore;
  final int currentCoins;
  final GameEndCallback onGameEnd;

  GamePage({
    required this.currentHighScore,
    required this.currentCoins,
    required this.onGameEnd,
  });

  @override
  _GamePageState createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with TickerProviderStateMixin implements WidgetsBindingObserver {
  late double screenWidth;
  late double screenHeight;
  late Player player;
  List<Enemy> enemies = [];
  List<Heart> hearts = [];
  List<Weapon> weapons = [];
  List<Bullet> bullets = [];
  List<Star> stars = [];
  List<CoinAnimation> coinAnimations = [];
  int score = 0;
  int coins = 0;
  int enemySpawnTimer = 0;
  int heartSpawnTimer = 0;
  int weaponSpawnTimer = 0;
  int enemySpawnDelay = INITIAL_SPAWN_DELAY;
  double currentEnemySpeed = 0;
  bool isGameOver = false;
  bool isPaused = false;
  Timer? gameTimer;
  Random random = Random();
  bool isMovingLeft = false;
  bool isMovingRight = false;
  double? lastPlayerX;
  double? lastPlayerY;
  int? lastLives;

  @override
  void initState() {
    super.initState();
    coins = widget.currentCoins;
    WidgetsBinding.instance.addObserver(this);
    _loadPlayerData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initializeStars();
      startGame();
    });
  }

  Future<void> _loadPlayerData() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final playerFile = File('${directory.path}/player_data.json');
      
      if (await playerFile.exists()) {
        final data = json.decode(await playerFile.readAsString());
        setState(() {
          player.skinType = data['skinType'] ?? 'color';
          player.color = Color(data['playerColor']);
          player.imagePath = data['imagePath'] ?? '';
        });
      }
    } catch (e) {
      print('Error loading player data: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    gameTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      lastPlayerX = player.x;
      lastPlayerY = player.y;
      lastLives = player.lives;
      isPaused = true;
    } else if (state == AppLifecycleState.resumed) {
      if (lastPlayerX != null && lastPlayerY != null && lastLives != null) {
        setState(() {
          player.x = lastPlayerX!;
          player.y = lastPlayerY!;
          player.lives = lastLives!;
        });
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    if (!mounted) return;
    player = Player(screenWidth, screenHeight);
    currentEnemySpeed = screenHeight * INITIAL_ENEMY_SPEED_FACTOR;
  }

  void initializeStars() {
    stars.clear();
    for (var i = 0; i < 50; i++) {
      stars.add(Star(
        x: random.nextDouble() * screenWidth,
        y: random.nextDouble() * screenHeight,
        size: random.nextDouble() * 2 + 1,
      ));
    }
  }

  void updateStars() {
    for (var star in stars) {
      star.y += currentEnemySpeed * 0.5;
      if (star.y > screenHeight) {
        star.y = -star.size;
        star.x = random.nextDouble() * screenWidth;
      }
    }
  }

  void showPauseMenu() {
    if (!mounted) return;
    lastPlayerX = player.x;
    lastPlayerY = player.y;
    lastLives = player.lives;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1a1a2e),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Text(
          'Пауза',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                if (lastPlayerX != null && lastPlayerY != null && lastLives != null) {
                  player.x = lastPlayerX!;
                  player.y = lastPlayerY!;
                  player.lives = lastLives!;
                }
                isPaused = false;
              });
            },
            child: Text(
              'Продолжить',
              style: TextStyle(
                color: Colors.blue,
                fontSize: 18,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: Text(
              'Выход в меню',
              style: TextStyle(
                color: Colors.red,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void startGame() {
    if (gameTimer != null) {
      gameTimer!.cancel();
    }
    gameTimer = Timer.periodic(Duration(milliseconds: 16), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (!isGameOver && !isPaused) {
        updateGame();
        if (isMovingLeft) player.move('left', screenWidth);
        if (isMovingRight) player.move('right', screenWidth);
      }
    });
  }

  void shoot() {
    if (!mounted || isGameOver || isPaused) return;
    if (player.hasWeapon) {
      setState(() {
        bullets.add(Bullet(player.x, player.y, screenWidth, screenHeight));
      });
    }
  }

  void updateGame() {
    if (!mounted || isPaused) return;
    setState(() {
      updateStars();
      _updateEnemies();
      _updateHearts();
      _updateWeapons();
      _updateBullets();
      _checkWeaponTimer();
    });
  }

  void _updateEnemies() {
    enemySpawnTimer++;
    if (enemySpawnTimer >= enemySpawnDelay) {
      enemies.add(Enemy(screenWidth, screenHeight, currentEnemySpeed));
      enemySpawnTimer = 0;
    }
    for (var enemy in enemies.toList()) {
      enemy.move();
      if (enemy.y > screenHeight) {
        enemies.remove(enemy);
        score++;
        if (score % 10 == 0) {
          currentEnemySpeed += screenHeight * SPEED_INCREASE_FACTOR;
          enemySpawnDelay = max(MIN_SPAWN_DELAY, 
                              (enemySpawnDelay * 0.95).toInt());
        }
      } else if (enemy.collidesWith(player)) {
        enemies.remove(enemy);
        player.lives--;
        if (player.lives <= 0) {
          gameOver();
        }
      }
    }
  }

  void _updateHearts() {
    heartSpawnTimer++;
    if (heartSpawnTimer >= 300) {
      if (random.nextDouble() < 0.3) {
        hearts.add(Heart(screenWidth, screenHeight));
      }
      heartSpawnTimer = 0;
    }
    for (var heart in hearts.toList()) {
      heart.speed = currentEnemySpeed * 0.8;
      heart.move();
      if (heart.y > screenHeight) {
        hearts.remove(heart);
      } else if (heart.collidesWith(player)) {
        hearts.remove(heart);
        player.lives = min(player.lives + 1, 3);
      }
    }
  }

  void _updateWeapons() {
    weaponSpawnTimer++;
    if (weaponSpawnTimer >= 180) {
      if (random.nextDouble() < 0.4 && !player.hasWeapon) {
        weapons.add(Weapon(screenWidth, screenHeight));
      }
      weaponSpawnTimer = 0;
    }
    for (var weapon in weapons.toList()) {
      weapon.speed = currentEnemySpeed * 0.8;
      weapon.move();
      if (weapon.y > screenHeight) {
        weapons.remove(weapon);
      } else if (weapon.collidesWith(player)) {
        weapons.remove(weapon);
        player.hasWeapon = true;
        player.weaponTime = DateTime.now();
      }
    }
  }

  void _updateBullets() {
    for (var bullet in bullets.toList()) {
      bullet.move();
      if (bullet.y < -bullet.height) {
        bullets.remove(bullet);
      } else {
        for (var enemy in enemies.toList()) {
          if (bullet.collidesWith(enemy)) {
            coinAnimations.add(CoinAnimation(
              x: enemy.x + enemy.width / 2,
              y: enemy.y + enemy.height / 2,
            ));
            enemies.remove(enemy);
            bullets.remove(bullet);
            setState(() {
              coins++;
            });
            break;
          }
        }
      }
    }

    for (var coin in coinAnimations.toList()) {
      coin.update();
      if (!coin.isActive) {
        coinAnimations.remove(coin);
      }
    }
  }

  void _checkWeaponTimer() {
    if (player.hasWeapon) {
      var now = DateTime.now();
      if (now.difference(player.weaponTime).inSeconds >= player.weaponDuration) {
        player.hasWeapon = false;
      }
    }
  }

  void gameOver() {
    if (!mounted) return;
    setState(() {
      isGameOver = true;
      gameTimer?.cancel();
    });
    
    // Only add the newly earned coins, not the total
    widget.onGameEnd(score, coins);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1a1a2e),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Text(
          score > widget.currentHighScore ? 'Новый рекорд!' : 'Игра окончена!',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Счет: $score',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Монеты: +$coins',
              style: TextStyle(
                color: Colors.amber,
                fontSize: 20,
              ),
            ),
            if (score > widget.currentHighScore)
              Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text(
                  'Предыдущий рекорд: ${widget.currentHighScore}',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              restartGame();
            },
            child: Text(
              'Новая игра',
              style: TextStyle(
                color: Colors.blue,
                fontSize: 18,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: Text(
              'Выход',
              style: TextStyle(
                color: Colors.red,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Update the restartGame method
  void restartGame() {
    if (!mounted) return;
    setState(() {
      player = Player(screenWidth, screenHeight);
      enemies.clear();
      hearts.clear();
      weapons.clear();
      bullets.clear();
      score = 0;
      coins = 0; // Reset coins to 0 instead of currentCoins
      enemySpawnTimer = 0;
      heartSpawnTimer = 0;
      weaponSpawnTimer = 0;
      enemySpawnDelay = INITIAL_SPAWN_DELAY;
      currentEnemySpeed = screenHeight * INITIAL_ENEMY_SPEED_FACTOR;
      isGameOver = false;
      isPaused = false;
      initializeStars();
    });
    startGame();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.black,
            ),
            child: CustomPaint(
              painter: GamePainter(
                player: player,
                enemies: enemies,
                hearts: hearts,
                weapons: weapons,
                bullets: bullets,
                score: score,
                coins: coins,
                screenWidth: screenWidth,
                screenHeight: screenHeight,
                stars: stars,
                coinAnimations: coinAnimations,
              ),
              size: Size(screenWidth, screenHeight),
            ),
          ),
          Positioned(
            top: 50,
            left: 20,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  isPaused = true;
                  showPauseMenu();
                });
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.pause, color: Colors.white),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Container(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTapDown: (_) => isMovingLeft = true,
                        onTapUp: (_) => isMovingLeft = false,
                        onTapCancel: () => isMovingLeft = false,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.arrow_left, color: Colors.white, size: 30),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Container(
                      alignment: Alignment.center,
                      child: player.hasWeapon ? GestureDetector(
                        onTap: shoot,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.flash_on, color: Colors.white, size: 25),
                        ),
                      ) : SizedBox(width: 50),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Container(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTapDown: (_) => isMovingRight = true,
                        onTapUp: (_) => isMovingRight = false,
                        onTapCancel: () => isMovingRight = false,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.arrow_right, color: Colors.white, size: 30),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void didChangeAccessibilityFeatures() {
  }
  @override
  void didChangeLocales(List<Locale>? locales) {
  }
  @override
  void didChangeMetrics() {
  }
  @override
  void didChangePlatformBrightness() {
  }
  @override
  void didChangeTextScaleFactor() {
  }
  @override
  void didChangeViewFocus(ViewFocusEvent event) {
  }
  @override
  void didHaveMemoryPressure() {
  }
  @override
  Future<bool> didPopRoute() {
    throw UnimplementedError();
  }
  @override
  Future<bool> didPushRoute(String route) {
    throw UnimplementedError();
  }
  @override
  Future<bool> didPushRouteInformation(RouteInformation routeInformation) {
    throw UnimplementedError();
  }
  @override
  Future<AppExitResponse> didRequestAppExit() {
    throw UnimplementedError();
  }
  @override
  void handleCancelBackGesture() {
  }
  @override
  void handleCommitBackGesture() {
  }
  @override
  bool handleStartBackGesture(PredictiveBackEvent backEvent) {
    throw UnimplementedError();
  }
  @override
  void handleUpdateBackGestureProgress(PredictiveBackEvent backEvent) {
  }
}
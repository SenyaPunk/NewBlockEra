import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'constants.dart';
import 'models/player.dart';
import 'models/enemy.dart';
import 'models/heart.dart';
import 'models/weapon.dart';
import 'models/bullet.dart';
import 'models/star.dart';
import 'painters/game_painter.dart';

class GamePage extends StatefulWidget {
  @override
  _GamePageState createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with TickerProviderStateMixin {
  late double screenWidth;
  late double screenHeight;
  late Player player;
  List<Enemy> enemies = [];
  List<Heart> hearts = [];
  List<Weapon> weapons = [];
  List<Bullet> bullets = [];
  List<Star> stars = [];
  int score = 0;
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initializeStars();
      startGame();
    });
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
            enemies.remove(enemy);
            bullets.remove(bullet);
            break;
          }
        }
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1a1a2e),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Text(
          'Лошара!',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Счет: $score',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
          ),
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

  void restartGame() {
    if (!mounted) return;
    setState(() {
      player = Player(screenWidth, screenHeight);
      enemies.clear();
      hearts.clear();
      weapons.clear();
      bullets.clear();
      score = 0;
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
  void dispose() {
    gameTimer?.cancel();
    super.dispose();
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
                screenWidth: screenWidth,
                screenHeight: screenHeight,
                stars: stars,
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
                  // Левая кнопка
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
                  // Кнопка стрельбы (всегда в центре)
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
                      ) : SizedBox(width: 50), // Пустое пространство, когда нет оружия
                    ),
                  ),
                  // Правая кнопка
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
}
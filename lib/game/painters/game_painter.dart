import 'package:flutter/material.dart';
import '../models/player.dart';
import '../models/enemy.dart';
import '../models/heart.dart';
import '../models/weapon.dart';
import '../models/bullet.dart';
import '../models/star.dart';

class GamePainter extends CustomPainter {
  final Player player;
  final List<Enemy> enemies;
  final List<Heart> hearts;
  final List<Weapon> weapons;
  final List<Bullet> bullets;
  final List<Star> stars;
  final int score;
  final double screenWidth;
  final double screenHeight;

  GamePainter({
    required this.player,
    required this.enemies,
    required this.hearts,
    required this.weapons,
    required this.bullets,
    required this.score,
    required this.screenWidth,
    required this.screenHeight,
    required this.stars,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawStars(canvas);
    _drawPlayer(canvas);
    _drawEnemies(canvas);
    _drawHearts(canvas);
    _drawWeapons(canvas);
    _drawBullets(canvas);
    _drawScore(canvas);
    _drawLives(canvas);
  }

  void _drawStars(Canvas canvas) {
    final starPaint = Paint()..color = Colors.white.withOpacity(0.5);
    for (var star in stars) {
      canvas.drawCircle(
        Offset(star.x, star.y),
        star.size,
        starPaint,
      );
    }
  }

  void _drawPlayer(Canvas canvas) {
    final playerPaint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.blue, Colors.lightBlueAccent],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(player.x, player.y, player.width, player.height));
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(player.x, player.y, player.width, player.height),
        Radius.circular(10),
      ),
      playerPaint,
    );

    if (player.hasWeapon) {
      _drawWeaponTimer(canvas);
    }
  }

  void _drawWeaponTimer(Canvas canvas) {
    final now = DateTime.now();
    final remaining = player.weaponDuration -
        now.difference(player.weaponTime).inSeconds;
    if (remaining > 0) {
      final timerWidth = (remaining / player.weaponDuration) * player.width;
      final timerPaint = Paint()
        ..shader = LinearGradient(
          colors: [Colors.yellow, Colors.orange],
        ).createShader(Rect.fromLTWH(player.x, player.y - 10, timerWidth, 5));
      canvas.drawRect(
        Rect.fromLTWH(player.x, player.y - 10, timerWidth, 5),
        timerPaint,
      );
    }
  }

  void _drawEnemies(Canvas canvas) {
    final enemyPaint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.red, Colors.redAccent],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, 40, 40));

    for (var enemy in enemies) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(enemy.x, enemy.y, enemy.width, enemy.height),
          Radius.circular(8),
        ),
        enemyPaint,
      );
    }
  }

  void _drawHearts(Canvas canvas) {
    for (var heart in hearts) {
      final heartCubePaint = Paint()
        ..shader = LinearGradient(
          colors: [Colors.red, Colors.redAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Rect.fromLTWH(heart.x, heart.y, heart.width, heart.height));

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(heart.x, heart.y, heart.width, heart.height),
          Radius.circular(8),
        ),
        heartCubePaint,
      );
      
      TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(Icons.favorite.codePoint),
          style: TextStyle(
            fontSize: heart.width * 0.6,
            fontFamily: Icons.favorite.fontFamily,
            color: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          heart.x + (heart.width - textPainter.width) / 2,
          heart.y + (heart.height - textPainter.height) / 2,
        ),
      );
    }
  }

  void _drawWeapons(Canvas canvas) {
    final weaponPaint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.yellow, Colors.orange],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, 30, 30));

    for (var weapon in weapons) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(weapon.x, weapon.y, weapon.width, weapon.height),
          Radius.circular(5),
        ),
        weaponPaint,
      );
    }
  }

  void _drawBullets(Canvas canvas) {
    final bulletPaint = Paint()..color = Colors.greenAccent;
    for (var bullet in bullets) {
      canvas.drawRect(
        Rect.fromLTWH(bullet.x, bullet.y, bullet.width, bullet.height),
        bulletPaint,
      );
    }
  }

  void _drawScore(Canvas canvas) {
    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: 24,
      shadows: [
        Shadow(
          blurRadius: 3,
          color: Colors.black,
          offset: Offset(2, 2),
        ),
      ],
    );
    final textPainter = TextPainter(
      text: TextSpan(text: 'Счет: $score', style: textStyle),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(screenWidth - textPainter.width - 10, 50));
  }

  void _drawLives(Canvas canvas) {
    final heartSize = screenWidth * 0.07;
    final spacing = heartSize * 1.2;

    for (var i = 0; i < player.lives; i++) {
      final heartCubePaint = Paint()
        ..shader = LinearGradient(
          colors: [Colors.red, Colors.redAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Rect.fromLTWH(
          screenWidth - (i + 1) * spacing - 10,
          90,
          heartSize,
          heartSize
        ));

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            screenWidth - (i + 1) * spacing - 10,
            90,
            heartSize,
            heartSize
          ),
          Radius.circular(8),
        ),
        heartCubePaint,
      );

      TextPainter heartIconPainter = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(Icons.favorite.codePoint),
          style: TextStyle(
            fontSize: heartSize * 0.7,
            fontFamily: Icons.favorite.fontFamily,
            color: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      heartIconPainter.layout();
      heartIconPainter.paint(
        canvas,
        Offset(
          screenWidth - (i + 1) * spacing - 10 + (heartSize - heartIconPainter.width) / 2,
          90 + (heartSize - heartIconPainter.height) / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(GamePainter oldDelegate) => true;
}
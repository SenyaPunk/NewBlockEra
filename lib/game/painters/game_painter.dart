import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../models/player.dart';
import '../models/enemy.dart';
import '../models/heart.dart';
import '../models/weapon.dart';
import '../models/bullet.dart';
import '../models/star.dart';
import '../models/coin_animation.dart';

class GamePainter extends CustomPainter {
  final Player player;
  final List<Enemy> enemies;
  final List<Heart> hearts;
  final List<Weapon> weapons;
  final List<Bullet> bullets;
  final List<Star> stars;
  final List<CoinAnimation> coinAnimations;
  final int score;
  final double screenWidth;
  final double screenHeight;
  final int coins;
  ui.Image? playerImage;

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
    required this.coins,
    required this.coinAnimations,
  }) {
    if (player.skinType == 'image' && player.imagePath.isNotEmpty) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    try {
      final imageProvider = AssetImage(player.imagePath);
      final ImageStream stream = imageProvider.resolve(ImageConfiguration());
      stream.addListener(ImageStreamListener((info, _) {
        playerImage = info.image;
      }));
    } catch (e) {
      print('Error loading player image: $e');
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    _drawStars(canvas);
    _drawPlayer(canvas);
    _drawEnemies(canvas);
    _drawHearts(canvas);
    _drawWeapons(canvas);
    _drawBullets(canvas);
    _drawScoreAndCoins(canvas);
    _drawLives(canvas);
    _drawCoinAnimations(canvas);
  }

  void _drawPlayer(Canvas canvas) {
    if (player.skinType == 'image' && player.imagePath.isNotEmpty) {
      if (playerImage != null) {
        // Draw the image
        final srcRect = Rect.fromLTWH(0, 0, playerImage!.width.toDouble(), playerImage!.height.toDouble());
        final dstRect = Rect.fromLTWH(player.x, player.y, player.width, player.height);
        
        // Draw background for transparency
        final bgPaint = Paint()..color = Colors.white;
        canvas.drawRRect(
          RRect.fromRectAndRadius(dstRect, Radius.circular(10)),
          bgPaint,
        );
        
        // Draw the image
        canvas.drawImageRect(
          playerImage!,
          srcRect,
          dstRect,
          Paint(),
        );
        
        // Draw border
        final borderPaint = Paint()
          ..color = Colors.blue
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        
        canvas.drawRRect(
          RRect.fromRectAndRadius(dstRect, Radius.circular(10)),
          borderPaint,
        );
      } else {
        // Fallback if image is not loaded
        final fallbackPaint = Paint()..color = Colors.grey;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(player.x, player.y, player.width, player.height),
            Radius.circular(10),
          ),
          fallbackPaint,
        );
      }
    } else {
      // Draw player with color skin
      final playerPaint = Paint()
        ..shader = LinearGradient(
          colors: [player.color, player.color.withOpacity(0.7)],
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
    }

    if (player.hasWeapon) {
      _drawWeaponTimer(canvas);
    }
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

  void _drawScoreAndCoins(Canvas canvas) {
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

    final coinStyle = TextStyle(
      color: Colors.amber,
      fontSize: 24,
      shadows: [
        Shadow(
          blurRadius: 3,
          color: Colors.black,
          offset: Offset(2, 2),
        ),
      ],
    );

    final scorePainter = TextPainter(
      text: TextSpan(text: 'Счет: $score', style: textStyle),
      textDirection: TextDirection.ltr,
    );
    scorePainter.layout();
    
    final coinIconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.monetization_on.codePoint),
        style: TextStyle(
          fontFamily: Icons.monetization_on.fontFamily,
          fontSize: 24,
          color: Colors.amber,
          shadows: [
            Shadow(
              blurRadius: 3,
              color: Colors.black,
              offset: Offset(2, 2),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    final coinTextPainter = TextPainter(
      text: TextSpan(
        text: '$coins',
        style: coinStyle,
      ),
      textDirection: TextDirection.ltr,
    );

    scorePainter.layout();
    coinIconPainter.layout();
    coinTextPainter.layout();

    scorePainter.paint(canvas, Offset(screenWidth - scorePainter.width - 10, 50));
    
    double coinsX = screenWidth - scorePainter.width - coinIconPainter.width - coinTextPainter.width - 40;
    coinIconPainter.paint(canvas, Offset(coinsX, 50));
    coinTextPainter.paint(canvas, Offset(coinsX + coinIconPainter.width + 5, 50));
  }

  void _drawCoinAnimations(Canvas canvas) {
    for (var coin in coinAnimations) {
      final iconPainter = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(Icons.monetization_on.codePoint),
          style: TextStyle(
            fontFamily: Icons.monetization_on.fontFamily,
            fontSize: 24 * coin.scale,
            color: Colors.amber.withOpacity(coin.opacity),
            shadows: [
              Shadow(
                blurRadius: 3,
                color: Colors.black.withOpacity(coin.opacity),
                offset: Offset(2, 2),
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      iconPainter.layout();
      iconPainter.paint(
        canvas,
        Offset(
          coin.x - iconPainter.width / 2,
          coin.y - iconPainter.height / 2,
        ),
      );
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
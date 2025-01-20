import 'dart:math';
import 'game_object.dart';
import '../constants.dart';

class Enemy extends GameObject {
  Enemy(double screenWidth, double screenHeight, double speed)
      : super(
          x: Random().nextDouble() * (screenWidth - screenWidth * ENEMY_SIZE_FACTOR),
          y: -screenWidth * ENEMY_SIZE_FACTOR,
          width: screenWidth * ENEMY_SIZE_FACTOR,
          height: screenWidth * ENEMY_SIZE_FACTOR,
          speed: speed,
        );

  void move() {
    y += speed;
  }
}
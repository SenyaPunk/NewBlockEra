import 'dart:math';
import 'game_object.dart';
import '../constants.dart';

class Weapon extends GameObject {
  Weapon(double screenWidth, double screenHeight)
      : super(
          x: Random().nextDouble() * (screenWidth - screenWidth * WEAPON_SIZE_FACTOR),
          y: -screenWidth * WEAPON_SIZE_FACTOR,
          width: screenWidth * WEAPON_SIZE_FACTOR,
          height: screenWidth * WEAPON_SIZE_FACTOR,
          speed: screenHeight * 0.005,
        );

  void move() {
    y += speed;
  }
}
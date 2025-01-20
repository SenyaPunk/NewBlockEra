import 'package:flutter/material.dart';
import 'game_object.dart';
import '../constants.dart';

class Player extends GameObject {
  int lives = 3;
  bool hasWeapon = false;
  DateTime weaponTime = DateTime.now();
  int weaponDuration = 10;

  Player(double screenWidth, double screenHeight)
      : super(
          x: screenWidth / 2 - screenWidth * PLAYER_SIZE_FACTOR / 2,
          y: screenHeight - screenHeight * PLAYER_SIZE_FACTOR - 20,
          width: screenWidth * PLAYER_SIZE_FACTOR,
          height: screenWidth * PLAYER_SIZE_FACTOR,
          speed: screenWidth * PLAYER_SPEED_FACTOR,
        );

  void move(String direction, double screenWidth) {
    if (direction == 'left' && x > 0) {
      x -= speed;
    }
    if (direction == 'right' && x < screenWidth - width) {
      x += speed;
    }
  }
}
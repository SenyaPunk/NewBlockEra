import 'dart:math';
import 'game_object.dart';
import '../constants.dart';

class Heart extends GameObject {
  Heart(double screenWidth, double screenHeight)
      : super(
          x: Random().nextDouble() * (screenWidth - screenWidth * HEART_SIZE_FACTOR),
          y: -screenWidth * HEART_SIZE_FACTOR,
          width: screenWidth * HEART_SIZE_FACTOR,
          height: screenWidth * HEART_SIZE_FACTOR,
          speed: screenHeight * 0.005,
        );

  void move() {
    y += speed;
  }
}
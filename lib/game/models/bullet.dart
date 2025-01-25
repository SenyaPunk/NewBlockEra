import 'game_object.dart';
import '../constants.dart';

class Bullet extends GameObject {
  Bullet(double playerX, double playerY, double screenWidth, double screenHeight)
      : super(
          x: playerX + screenWidth * PLAYER_SIZE_FACTOR / 2 - screenWidth * BULLET_SIZE_FACTOR / 2,
          y: playerY,
          width: screenWidth * BULLET_SIZE_FACTOR,
          height: screenWidth * BULLET_SIZE_FACTOR,
          speed: screenHeight * BULLET_SPEED_FACTOR,
        );

  void move() {
    y -= speed;
  }
}
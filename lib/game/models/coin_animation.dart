import 'dart:math';

class CoinAnimation {
  double x;
  double y;
  double opacity;
  double scale;
  double velocityY;
  double velocityX;
  bool isActive;

  CoinAnimation({
    required this.x,
    required this.y,
  }) : opacity = 1.0,
       scale = 1.0,
       velocityY = -5.0,
       velocityX = Random().nextDouble() * 4 - 2, // Random horizontal velocity between -2 and 2
       isActive = true;

  void update() {
    if (!isActive) return;
    
    y += velocityY;
    x += velocityX;
    velocityY += 0.3; // Гравитация
    velocityX *= 0.95; // Затухание горизонтального движения
    opacity -= 0.02; // Постепенное исчезновение
    scale += 0.02; // Небольшое увеличение размера

    if (opacity <= 0) {
      isActive = false;
    }
  }
}
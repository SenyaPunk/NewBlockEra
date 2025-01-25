
class GameObject {
  double x;
  double y;
  double width;
  double height;
  double speed;

  GameObject({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.speed,
  });

  bool collidesWith(GameObject other) {
    return (x < other.x + other.width &&
        x + width > other.x &&
        y < other.y + other.height &&
        y + height > other.y);
  }
}
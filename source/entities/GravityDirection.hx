package entities;

enum GravityDirection {
  Down;
  Right;
  Up;
  Left;
}

class GravityDirectionTools {
  private function new() {}

  public static inline function counterClockwise(gravity:GravityDirection) {
    return switch(gravity) {
      case Down: Left;
      case Left: Up;
      case Up: Right;
      case Right: Down;
    };
  }

  public static inline function next(gravity:GravityDirection) {
    return counterClockwise(gravity);
  }

  public static inline function clockwise(gravity:GravityDirection) {
    return switch(gravity) {
      case Down: Right;
      case Right: Up;
      case Up: Left;
      case Left: Down;
    };
  }

  public static inline function previous(gravity:GravityDirection) {
    return clockwise(gravity);
  }

  public static inline var Count = 4;
}
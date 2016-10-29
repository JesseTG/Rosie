package entities;

@:enum
abstract GravityDirection(Float) {
  var Down = 0;
  var Right = 90;
  var Up = 180;
  var Left = 270;

  public static inline function counterClockwise(gravity:GravityDirection) {
    return switch(gravity) {
      case Down: Right;
      case Right: Up;
      case Up: Left;
      case Left: Down;
    };
  }
}

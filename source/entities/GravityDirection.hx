package entities;

@:enum
@:notNull
abstract GravityDirection(Float) {
  var Down = 0;
  var Right = 270;
  var Up = 180;
  var Left = 90;

  public static inline function counterClockwise(gravity:GravityDirection) {
    return switch(gravity) {
      case Down: Left;
      case Left: Up;
      case Up: Right;
      case Right: Down;
    };
  }
}

package entities;

@:enum
abstract GravityDirection(Float) {
  var Down = 0;
  var Right = 90;
  var Up = 180;
  var Left = 270;

  public static inline var G : Float = 72;
  // This is the magnitude of gravity
}

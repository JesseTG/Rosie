package entities;

@:enum
@:notNull
abstract GravityDirection(Float) {
  var Down = 0;
  var Right = 270;
  var Up = 180;
  var Left = 90;
  public static inline var Count = 4;

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

  public static inline function createByName(gravity:String) {
    return switch(gravity) {
      case "Down": Down;
      case "Right": Right;
      case "Up": Up;
      case "Left": Left;
      case _: {
        trace('Warning: Invalid gravity direction ${gravity} given');
        null;
      }
    };
  }

  public static inline function getIndex(gravity:GravityDirection) {
    return switch(gravity) {
      case Down: 0;
      case Right: 1;
      case Up: 2;
      case Left: 3;
    };
  }
}

package entities;

import flixel.math.FlxPoint;
import flixel.FlxObject;

class GravityDirection {
  public static var Up = new GravityDirection(FlxObject.UP, new FlxPoint(0, -G), 180, FlxObject.UP | FlxObject.DOWN, Orientation.Vertical);
  public static var Down = new GravityDirection(FlxObject.DOWN, new FlxPoint(0, G), 0, FlxObject.UP | FlxObject.DOWN, Orientation.Vertical);
  public static var Left = new GravityDirection(FlxObject.LEFT, new FlxPoint(-G, 0), 90, FlxObject.LEFT | FlxObject.RIGHT, Orientation.Horizontal);
  public static var Right = new GravityDirection(FlxObject.RIGHT, new FlxPoint(G, 0), 270, FlxObject.LEFT | FlxObject.RIGHT, Orientation.Horizontal);

  public static inline var G : Float = 72;
  // This is the magnitude of gravity

  public var Direction(default, null) : Int;
  public var Gravity(default, null) : FlxPoint;
  public var Degrees(default, null) : Float;
  public var CollisionSides(default, null) : Int;
  public var Orientation(default, null) : Orientation;

  private function new(Direction:Int, Gravity:FlxPoint, Degrees:Float, CollisionSides:Int, Orientation:Orientation) {
    this.Direction = Direction;
    this.Gravity = Gravity;
    this.Degrees = Degrees;
    this.CollisionSides = CollisionSides;
    this.Orientation = Orientation;
  }
}

enum Orientation {
  Horizontal;
  Vertical;
}
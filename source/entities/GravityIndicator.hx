package entities;

import flixel.FlxSprite;
import flixel.graphics.frames.FlxFramesCollection;

class GravityIndicator extends FlxSprite {
  public var state : State;
  public var direction(default, null) : GravityDirection;

  public function new(x:Float = 0, y:Float = 0, sprites:FlxFramesCollection, direction:GravityDirection) {
    super(x, y);
    this.frames = sprites;
    this.frame = sprites.getByName("gravity-indicator-00.png");
    this.direction = direction;
    this.angle = cast(direction);
    this.resetSizeFromFrame();
    this.updateHitbox();
    this.origin.set(0, 0);
  }
}

enum State {
  INACTIVE;
  WAITING;
  ACTIVE;
}
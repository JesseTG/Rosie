package entities;

import flixel.FlxBasic.FlxType;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxFramesCollection;

class Block extends FlxSprite {
  public var blockColor(default, null) : BlockColor;

  public var gravity(default, set) : GravityDirection;

  public function new(x:Float = 0, y:Float = 0, sprites:FlxFramesCollection, blockColor:BlockColor) {
    super(x, y);
    this.frame = sprites.getByName(cast(blockColor));
    this.blockColor = blockColor;
    this.flixelType = FlxType.OBJECT;
    this.updateHitbox();
    this.resetSizeFromFrame();
    // TODO: Adjust the hitbox whenever gravity changes
  }

  public function set_gravity(gravity:GravityDirection) {
    this.gravity = gravity;
    this.velocity.x = this.gravity.Gravity.x;
    this.velocity.y = this.gravity.Gravity.y;
    // I could assign velocity directly, but I don't know if that would be
    // copy assignment or reference assignment; better play it safe

    this.allowCollisions = this.gravity.CollisionSides;

    return this.gravity;
  }

  }
}
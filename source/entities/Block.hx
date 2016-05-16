package entities;

import flixel.math.FlxMath;
import flixel.FlxObject;
import flixel.FlxBasic.FlxType;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.FlxG;

class Block extends FlxSprite {
  public var blockColor(default, null) : BlockColor;
  // TODO: Make a setter that also sets the image

  public var gravity(default, set) : GravityDirection;

  public function new(x:Float = 0, y:Float = 0, sprites:FlxFramesCollection, blockColor:BlockColor) {
    super(x, y);
    this.frame = sprites.getByName(cast(blockColor));
    this.moves = false;
    this.blockColor = blockColor;
    this.flixelType = FlxType.OBJECT;
    //this.allowCollisions = FlxObject.UP | FlxObject.DOWN;
    this.pixelPerfectPosition = true;
    //this.pixelPerfectRender = true;
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

  public override function update(elapsed:Float) {
    if (this.moves && this.isTouching(this.gravity.Direction)) {
      this.x = Math.round(this.x / this.frameWidth) * this.frameWidth;
      this.y = Math.round(this.y / this.frameHeight) * this.frameHeight;
      this.velocity.set(0, 0);
      //this.moves = false;
    }

    super.update(elapsed);
  }

  public override function toString() : String {
    return cast(blockColor);
  }
}
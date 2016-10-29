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

  public function new(x:Float = 0, y:Float = 0, sprites:FlxFramesCollection, blockColor:BlockColor) {
    super(x, y);
    this.frame = sprites.getByName(cast(blockColor));
    this.blockColor = blockColor;
    this.flixelType = FlxType.OBJECT;
    this.updateHitbox();
    this.resetSizeFromFrame();
  }

  public function snapToGrid() {
    this.x = Math.round(this.x / this.frameWidth) * this.frameWidth;
    this.y = Math.round(this.y / this.frameHeight) * this.frameHeight;
  }

  public override function update(elapsed:Float) {


    super.update(elapsed);


    if (FlxG.debugger.visible && !this.moves) {
      this.color = 0xFF0000;
    }
    else {
      this.color = 0xFFFFFF;
    }
  }

  public override function toString() : String {
    return Std.string(blockColor).charAt(5).toUpperCase(); // HACK
  }
}
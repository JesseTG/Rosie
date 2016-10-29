package entities;

import flixel.FlxSprite;
import flixel.graphics.frames.FlxFramesCollection;

class Block extends FlxSprite {
  public var blockColor(default, null) : BlockColor;

  public function new(x:Float = 0, y:Float = 0, sprites:FlxFramesCollection, blockColor:BlockColor) {
    super(x, y);
    this.frame = sprites.getByName(cast(blockColor));
    this.blockColor = blockColor;
    this.updateHitbox();
    this.resetSizeFromFrame();
  }

  public override function toString() : String {
    return Std.string(blockColor).charAt(5).toUpperCase(); // HACK
  }
}
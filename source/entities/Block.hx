package entities;

import flixel.FlxSprite;
import flixel.graphics.frames.FlxFramesCollection;

class Block extends FlxSprite {
  private var sprites:FlxFramesCollection;
  public var blockColor(default, set) : BlockColor;

  public function new(x:Float = 0, y:Float = 0, sprites:FlxFramesCollection, blockColor:BlockColor) {
    super(x, y);
    this.sprites = sprites;
    this.frame = sprites.getByName(cast(blockColor));
    this.blockColor = blockColor;
    this.updateHitbox();
    this.resetSizeFromFrame();
  }

  public function set_blockColor(blockColor:BlockColor) {
    this.blockColor = blockColor;
    this.frame = sprites.getByName(cast(blockColor));

    return blockColor;
  }

  public override function toString() : String {
    return Std.string(blockColor).charAt(5).toUpperCase(); // HACK
  }
}
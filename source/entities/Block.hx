package entities;

import flixel.FlxSprite;
import flixel.graphics.frames.FlxFramesCollection;

class Block extends FlxSprite {
  public var blockColor(default, set) : BlockColor;

  public function new(x:Float = 0, y:Float = 0, sprites:FlxFramesCollection, blockColor:BlockColor) {
    super(x, y);
    this.frames = sprites;
    this.frame = sprites.getByName(cast(blockColor));
    this.blockColor = blockColor;
    this.updateHitbox();
    this.resetSizeFromFrame();
  }

  public function set_blockColor(blockColor:BlockColor) {
    this.blockColor = blockColor;
    this.frame = this.frames.getByName(cast(blockColor));
    // TODO: Figure out if this is a runtime cast or a compile-time cast

    return blockColor;
  }

  public override function toString() : String {
    var letter = Std.string(blockColor).charAt(5).toUpperCase(); // HACK
    return '${letter}-${this.ID}';
    // TODO: Come up with a better string representation that doesn't rely on filename
  }
}
package entities;

import flixel.FlxBasic.FlxType;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxFramesCollection;

class Block extends FlxSprite {
  public var blockColor(default, null) : BlockColor;

  public function new(x:Float = 0, y:Float = 0, sprites:FlxFramesCollection, blockColor:BlockColor) {
    super(x, y);
    this.frame = sprites.getByName(cast(blockColor));
    this.blockColor = blockColor;
    this.flixelType = FlxType.OBJECT;
    this.updateHitbox();
    this.resetSizeFromFrame();


  }
}
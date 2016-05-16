package entities;

import flixel.addons.display.FlxExtendedSprite;
import flixel.FlxBasic.FlxType;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxFramesCollection;

class Block extends FlxExtendedSprite {
  public var blockColor(default, null) : BlockColor;

  public function new(x:Float = 0, y:Float = 0, sprites:FlxFramesCollection, blockColor:BlockColor) {
    super(x, y);
    this.enableMouseClicks(true);
    this.enableMouseDrag(true); // Dunno why I have to enable mouseClicks AND mouseDrag
    this.frame = sprites.getByName(cast(blockColor));
    this.blockColor = blockColor;
    this.flixelType = FlxType.OBJECT;
    this.setGravity(0, 1);
    this.updateHitbox();
    this.resetSizeFromFrame();


    this.mousePressedCallback = function(object:FlxExtendedSprite, x:Int, y:Int) {
      this.kill(); // Pooling in action; the Block doesn't go away, but the user's none the wiser
      trace(this);
    };
  }
}
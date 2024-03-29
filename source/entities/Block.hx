package entities;

import flixel.FlxSprite;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.input.mouse.FlxMouseEventManager;

import de.polygonal.Printf;

class Block extends FlxSprite {

  private static var BLOCK_APPEAR_FRAME_NAMES =
    [for (i in 0...13) Printf.format("block-appear-%02d.png", [i])];

  private static var BLOCK_VANISH_FRAME_NAMES =
    [for (i in 0...5) Printf.format("block-vanish-%02d.png", [i])];

  public var blockColor(default, set) : BlockColor;

  public function new(x:Float = 0, y:Float = 0, sprites:FlxFramesCollection, blockColor:BlockColor) {
    super(x, y);
    this.frames = sprites;
    this.frame = sprites.getByName(cast(blockColor));
    this.blockColor = blockColor;
    this.updateHitbox();
    this.resetSizeFromFrame();

    this.animation.addByNames(
      cast BlockAnimation.Appear,
      BLOCK_APPEAR_FRAME_NAMES,
      60,
      false
    );

    this.animation.addByNames(
      cast BlockAnimation.Vanish,
      BLOCK_VANISH_FRAME_NAMES,
      15,
      false
    );

    this.animation.finishCallback = this._handleAnimationFinish;
    this.immovable = true;
    this.solid = false;
  }

  public override function destroy() {
    super.destroy();

    FlxMouseEventManager.remove(this);
  }

  private inline function set_blockColor(blockColor:BlockColor) {
    this.blockColor = blockColor;
    this.frame = this.frames.getByName(cast(blockColor));
    // TODO: Figure out if this is a runtime cast or a compile-time cast

    return blockColor;
  }

  private function _handleAnimationFinish(name:String) {
    switch (cast name) {
      case Appear:
        FlxMouseEventManager.setObjectMouseEnabled(this, true);
        this.frame = this.frames.getByName(cast this.blockColor);
      case Vanish:
        this.kill();
      default: //nop
    }
  }
  public override inline function toString() : String {
    var letter = Std.string(blockColor).charAt(5).toUpperCase(); // HACK
    return '${letter}-${this.ID}';
    // TODO: Come up with a better string representation that doesn't rely on filename
  }
}

@:enum
@:notNull
abstract BlockAnimation(String) {
  var None = "none";
  var Appear = "appear";
  var Vanish = "vanish";
}
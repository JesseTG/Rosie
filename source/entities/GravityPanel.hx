package entities;

import flixel.animation.FlxAnimation;
import flixel.animation.FlxAnimationController;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxFramesCollection;

using ObjectInit;

// TODO: Can I just make this an abstract to avoid runtime overhead?
// TODO: Recycle these
class GravityPanel extends FlxSprite {
  public function new(x:Float = 0, y:Float = 0, sprites:FlxFramesCollection) {
    super(x, y - 16); // TODO: Stop hardcoding
    this.frames = sprites;
    this.frame = sprites.getByName("gravity-panel-00.png");

    this.resetSizeFromFrame();
    this.updateHitbox();
    this.origin.set(0, 0);
  }
}

@:enum
@:notNull
abstract GravityPanelState(Bool) {
  var On = true;
  var Off = false;
}
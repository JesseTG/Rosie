package entities;

import flixel.animation.FlxAnimation;
import flixel.animation.FlxAnimationController;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxFramesCollection;

using ObjectInit;

// TODO: Recycle these
abstract GravityPanel(FlxSprite) to FlxSprite {
  public inline function new(x:Float = 0, y:Float = 0, sprites:FlxFramesCollection) {
    this = new FlxSprite(x, y - 16).init(
      frames = sprites,
      frame = sprites.getByName("gravity-panel-00.png")
    ); // TODO: Stop hardcoding this

    this.resetSizeFromFrame();
    this.updateHitbox();
    this.origin.set(0, 0);
  }
}
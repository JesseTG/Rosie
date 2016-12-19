package entities;

import flixel.animation.FlxAnimation;
import flixel.animation.FlxAnimationController;
import flixel.FlxSprite;
import flixel.addons.display.FlxTiledSprite;
import flixel.graphics.frames.FlxFramesCollection;

using ObjectInit;


@:forward
abstract GravityPanel(FlxTiledSprite) to FlxTiledSprite {
  public inline function new(x:Float = 0, y:Float = 0, width:Float, height:Float, sprites:FlxFramesCollection) {
    this = new FlxTiledSprite(width, height, true, true).init(
      x = x,
      y = y
    ); // TODO: Stop hardcoding this

    this.immovable = true;
    this.solid = false;
    this.moves = false;
    this.loadFrame(sprites.getByName("gravity-panel-00.png"));
  }
}
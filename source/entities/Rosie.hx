package entities;

import de.polygonal.Printf;
import flixel.animation.FlxAnimation;
import flixel.animation.FlxAnimationController;
import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.graphics.frames.FlxFramesCollection;

class Rosie extends FlxSprite {
  private static inline var IDLE_FPS = 6;
  private static inline var WALK_FPS = 6;
  public function new(x:Int, y:Int, sprites:FlxFramesCollection) {
    super(x, y);

    this.frames = sprites;
    this.resetSizeFromFrame();
    this.updateHitbox();
    this.setFacingFlip(FlxObject.LEFT, true, false);
    this.setFacingFlip(FlxObject.RIGHT, false, false);

    var idleFrames = [for (i in 1...62) Printf.format("cat/idle/rosie-idle-%02d.png", [i])];
    var runFrames = [for (i in 1...7) Printf.format("cat/run/rosie-run-%02d.png", [i])];

    this.animation.addByNames(
      "idle",
      idleFrames,
      IDLE_FPS,
      true
    );
    this.animation.addByNames(
      "walk",
      runFrames,
      WALK_FPS,
      true
    );
    this.animation.addByNames(
      "run",
      runFrames,
      WALK_FPS * 2,
      true
    );

    this.animation.play("idle");
  }
}
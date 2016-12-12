package entities;

import de.polygonal.Printf;
import flixel.animation.FlxAnimation;
import flixel.animation.FlxAnimationController;
import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.addons.util.FlxFSM;
import flixel.addons.util.FlxFSM.FlxFSMState;
import flixel.addons.util.FlxFSM.FlxFSMTransitionTable;
import flixel.FlxG;
import flixel.addons.display.FlxNestedSprite;
import flixel.math.FlxMath;

class RosieEmote extends FlxNestedSprite {

  public function new(x:Float, y:Float, sprites:FlxFramesCollection) {
    super(x, y);

    this.frames = sprites;
    this.frame = sprites.getByName("emotes/happyEmote.png");
    pixelPerfectRender = true;
    pixelPerfectPosition = true;
    this.resetSizeFromFrame();
    this.updateHitbox();
  }

}

enum EmoteState {
  Happy;
  Bored;
}
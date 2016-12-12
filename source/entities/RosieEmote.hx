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
  public var state(default, set) : EmoteState;

  public function new(x:Float, y:Float, sprites:FlxFramesCollection) {
    super(x, y);

    this.frames = sprites;
    this.frame = sprites.getByName("emotes/happy-00.png");
    this.pixelPerfectRender = true;
    this.pixelPerfectPosition = true;
    this.resetSizeFromFrame();
    this.updateHitbox();

    this.animation.addByNames(cast Happy, [for (i in 0...4) "emotes/happy-00.png"], 1, false);
    this.animation.addByNames(cast Neutral, [for (i in 0...4) "emotes/neutral-00.png"], 1, false);
    this.animation.addByStringIndices(
      cast Bored,
      "emotes/bored-",
      ["00", "01", "00", "01", "00", "00"],
      ".png",
      1,
      false
    );

    this.animation.addByStringIndices(
      cast Confused,
      "emotes/confused-",
      ["00", "01", "00", "01", "00", "00"],
      ".png",
      1,
      false
    );

    this.animation.addByStringIndices(
      cast Doh,
      "emotes/doh-",
      ["00", "01", "00", "01", "00", "00"],
      ".png",
      1,
      false
    );

    this.animation.addByStringIndices(
      cast Angry,
      "emotes/angry-",
      ["00", "01", "00", "01", "00", "00"],
      ".png",
      1,
      false
    );

    this.animation.addByStringIndices(
      cast VeryHappy,
      "emotes/very-happy-",
      ["00", "01", "00", "01", "00", "00"],
      ".png",
      2,
      false
    );
    this.animation.finishCallback = function(_) {
      this.state = None;
    };
    this.state = None;
  }

  private inline function set_state(s:EmoteState) {
    this.state = s;
    this.visible = (this.state != None);
    if (s != None) {
      this.animation.play(cast this.state);
    }
    return this.state;
  }

}

@:enum
@:notNull
abstract EmoteState(String) {
  var None = "none";
  var Happy = "happy";
  var Bored = "bored";
  var VeryHappy = "very-happy";
  var Confused = "confused";
  var Doh = "doh";
  var Angry = "angry";
  var Neutral = "neutral";
}
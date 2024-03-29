package entities;

import flixel.FlxG;
import flixel.addons.display.FlxNestedSprite;
import flixel.graphics.frames.FlxFramesCollection;

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
    this.animation.addByNames(cast Worried, [for (i in 0...4) "emotes/worried-00.png"], 1, false);
    this.animation.addByNames(cast Huh, [for (i in 0...4) "emotes/huh.png"], 1, false);
    this.animation.addByNames(cast Sad, [for (i in 0...4) "emotes/sad-00.png"], 1, false);
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
      ["00", "01", "00", "01",  "00", "01",  "00", "01", "00", "00", "00", "00"],
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
      ["00", "01", "00", "01",  "00", "01",  "00", "01", "00", "00", "00", "00"],
      ".png",
      2,
      false
    );
    this.animation.finishCallback = function(_) {
      this.state = None;
    };
    this.state = None;
    this.solid = false;
    this.immovable = true;
  }

  private inline function set_state(s:EmoteState) {
    if (this.state != s) {
      this.animation.stop();
    }

    this.state = s;
    this.visible = (this.state != None);
    if (s != None) {
      if (FlxG.random.bool(50)) {
        FlxG.sound.play(AssetPaths.meow__wav, 1, false, false);
      }
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
  var Worried = "worried";
  var Huh = "huh";
  var Sad = "sad";
}
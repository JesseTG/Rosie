package entities;

import flixel.FlxSprite;
import flixel.graphics.frames.FlxFramesCollection;

using ObjectInit;

@:forward
abstract GravityIndicator(FlxSprite) to FlxSprite {
  public var state(get, set) : GravityIndicatorState;

  public function new(x:Float = 0, y:Float = 0, sprites:FlxFramesCollection) {
    this = new FlxSprite(x, y).init(
      frames = sprites,
      frame = sprites.getByName("gravity-indicator-h-00.png")
    );

    this.animation.addByStringIndices(
      cast GravityIndicatorState.Horizontal,
      "gravity-indicator-h-",
      ["00", "01", "02", "02", "02", "02", "01", "00", "00", "00"],
      ".png",
      4
    );
    this.animation.addByStringIndices(
      cast GravityIndicatorState.Vertical,
      "gravity-indicator-v-",
      ["00", "01", "02", "02", "02", "02", "01", "00", "00", "00"],
      ".png",
      4
    );
  }

  private inline function get_state() {
    return cast this.animation.name;
  }

  private inline function set_state(state:GravityIndicatorState) {
    this.animation.play(cast state, true);
    return state;
  }
}

@:enum
@:notNull
abstract GravityIndicatorState(String) {
  var Horizontal = "horizontal";
  var Vertical = "vertical";
}
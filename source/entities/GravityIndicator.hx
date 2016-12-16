package entities;

import flixel.animation.FlxAnimation;
import flixel.animation.FlxAnimationController;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxFramesCollection;

using ObjectInit;

class GravityIndicator extends FlxSprite {
  public var state(get, set) : GravityIndicatorState;
  public var direction(default, null) : GravityDirection;

  public function new(x:Float = 0, y:Float = 0, sprites:FlxFramesCollection, direction:GravityDirection) {
    super(x, y);
    this.frames = sprites;
    this.frame = sprites.getByName("gravity-indicator-00.png");
    this.direction = direction;
    this.angle = cast(direction);
    this.resetSizeFromFrame();
    this.updateHitbox();
    this.origin.set(0, 0);

    this.animation.addByNames(cast GravityIndicatorState.Off, ["gravity-indicator-04.png"]);
    this.animation.addByStringIndices(
      cast GravityIndicatorState.On,
      "gravity-indicator-",
      ["00", "01", "02", "02", "02", "02", "01", "00", "00", "00"],
      ".png",
      4
    );

    this.immovable = true;
    this.solid = false;
    this.moves = false;
    this.state = GravityIndicatorState.Off;
  }

  private function get_state() {
    return cast this.animation.name;
  }

  private function set_state(state:GravityIndicatorState) {
    this.animation.name = cast state;
    return state;
  }
}

@:enum
@:notNull
abstract GravityIndicatorState(String) {
  var On = "on";
  var Off = "off";
  var Next = "next";
}
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

using ObjectInit;

class Rosie extends FlxNestedSprite {
  public static inline var RUN_SPEED = 32.0;
  public static inline var IDLE_FPS = 6;
  public static inline var RUN_FPS = 12;
  public static var IDLE_FRAMES = [for (i in 1...62) Printf.format("cat/idle/rosie-idle-%02d.png", [i])];
  public static var RUN_FRAMES = [for (i in 1...7) Printf.format("cat/run/rosie-run-%02d.png", [i])];

  public var fsm : FlxFSM<Rosie>;

  // TODO: Make this private and figure out how the @:access macro works
  public var tilemap: FlxObject;

  public var emote : RosieEmote;

  public function new(x:Int, y:Int, sprites:FlxFramesCollection, tilemap:FlxObject) {
    super(x, y);

    this.tilemap = tilemap;
    this.frames = sprites;
    this.setFacingFlip(FlxObject.LEFT, true, false);
    this.setFacingFlip(FlxObject.RIGHT, false, false);
    this.facing = FlxObject.RIGHT;

    this.animation.addByNames(
      cast AnimationState.Idle,
      IDLE_FRAMES,
      IDLE_FPS,
      true
    );
    this.animation.addByNames(
      cast AnimationState.Run,
      RUN_FRAMES,
      RUN_FPS,
      true
    );

    this.frame = sprites.getByName(IDLE_FRAMES[0]);
    this.fsm = new FlxFSM<Rosie>(this);
    this.fsm.transitions
      .add(RosieIdleState, RosieRunState, _switchBetweenIdleAndRun)
      .add(RosieRunState, RosieIdleState, _switchBetweenIdleAndRun)
      .add(RosieIdleState, RosieJumpState, function(rosie) {
        return false;
      })
      .add(RosieJumpState, RosieIdleState, function(rosie) {
        return false;
      })
      .add(RosieRunState, RosieJumpState, function(rosie) {
        return false;
      })
      .add(RosieJumpState, RosieRunState, function(rosie) {
        return false;
      })
      .start(RosieIdleState);

    this.elasticity = 0.5;
    this.resetSizeFromFrame();
    this.updateHitbox();

    this.emote = new RosieEmote(x, y, this.frames).init(
      relativeX = 5,
      relativeY = -this.height / 2
    );

    this.add(this.emote);
  }

  private static function _switchBetweenIdleAndRun(rosie:Rosie) {
    var frame = rosie.animation.curAnim.curFrame;
    return (rosie.fsm.age >= 1.0 && Math.round(frame) == 4) ? Math.random() < 0.1 : false;
  }

  public override function update(elapsed:Float) {
    this.fsm.update(elapsed);
    super.update(elapsed);
  }

  public override function destroy() {
    this.fsm.destroy();
    this.fsm = null;
    this.removeAll();
    this.emote.destroy();
    this.emote = null;
    super.destroy();
  }
}

@:enum
@:notNull
abstract AnimationState(String) {
  var Run = "run";
  var Idle = "idle";
}

private class RosieIdleState extends FlxFSMState<Rosie> {
  public override function enter(owner:Rosie, fsm:FlxFSM<Rosie>) {
    owner.animation.play(cast AnimationState.Idle);
    owner.velocity.x = 0;
  }

  public override function update(elapsed:Float, owner:Rosie, fsm:FlxFSM<Rosie>) {
  }
}

private class RosieRunState extends FlxFSMState<Rosie> {
  public override function enter(owner:Rosie, fsm:FlxFSM<Rosie>) {
    owner.animation.play("run");
    owner.velocity.x = ((owner.facing & FlxObject.RIGHT != 0) ? 1 : -1) * Rosie.RUN_SPEED;
  }

  public override function update(elapsed:Float, owner:Rosie, fsm:FlxFSM<Rosie>) {
    if (owner.x <= 0 || FlxObject.separateX(owner, owner.tilemap)) {
      owner.velocity.x = (owner.touching & FlxObject.RIGHT != 0) ? -Rosie.RUN_SPEED : Rosie.RUN_SPEED;
      owner.facing = (owner.velocity.x > 0) ? FlxObject.RIGHT : FlxObject.LEFT;
    }
  }
}

private class RosieJumpState extends FlxFSMState<Rosie> {
  public override function enter(owner:Rosie, fsm:FlxFSM<Rosie>) {
  }

  public override function update(elapsed:Float, owner:Rosie, fsm:FlxFSM<Rosie>) {
  }
}
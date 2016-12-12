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

class Rosie extends FlxSprite {
  private static inline var IDLE_FPS = 6;
  private static inline var RUN_FPS = 12;

  public var fsm : FlxFSM<Rosie>;

  public function new(x:Int, y:Int, sprites:FlxFramesCollection) {
    super(x, y);

    this.frames = sprites;
    this.resetSizeFromFrame();
    this.updateHitbox();
    this.setFacingFlip(FlxObject.LEFT, true, false);
    this.setFacingFlip(FlxObject.RIGHT, false, false);
    this.facing = FlxObject.RIGHT;

    var idleFrames = [for (i in 1...62) Printf.format("cat/idle/rosie-idle-%02d.png", [i])];
    var runFrames = [for (i in 1...7) Printf.format("cat/run/rosie-run-%02d.png", [i])];

    this.animation.addByNames(
      "idle",
      idleFrames,
      IDLE_FPS,
      true
    );
    this.animation.addByNames(
      "run",
      runFrames,
      RUN_FPS,
      true
    );

    this.frame = sprites.getByName(idleFrames[0]);
    this.fsm = new FlxFSM<Rosie>(this);
    this.fsm.transitions
      .add(RosieIdleState, RosieRunState, function(rosie) {
        return Math.random() < 0.004;
      })
      .add(RosieRunState, RosieIdleState, function(rosie) {
        return (rosie.fsm.age >= 1.0) ? Math.random() < 0.4 : false;
      })
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
  }

  public override function update(elapsed:Float) {
    this.fsm.update(elapsed);
    super.update(elapsed);
  }

  public override function destroy() {
    this.fsm.destroy();
    this.fsm = null;
    super.destroy();
  }
}

private class RosieIdleState extends FlxFSMState<Rosie> {
  public override function enter(owner:Rosie, fsm:FlxFSM<Rosie>) {
    owner.animation.play("idle");
  }

  public override function update(elapsed:Float, owner:Rosie, fsm:FlxFSM<Rosie>) {
  }
}

private class RosieRunState extends FlxFSMState<Rosie> {
  public override function enter(owner:Rosie, fsm:FlxFSM<Rosie>) {
    owner.animation.play("run");
  }

  public override function update(elapsed:Float, owner:Rosie, fsm:FlxFSM<Rosie>) {
  }
}

private class RosieJumpState extends FlxFSMState<Rosie> {
  public override function enter(owner:Rosie, fsm:FlxFSM<Rosie>) {
  }

  public override function update(elapsed:Float, owner:Rosie, fsm:FlxFSM<Rosie>) {
  }
}
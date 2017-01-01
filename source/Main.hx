package;

import openfl.display.Sprite;

import flixel.FlxG;
import flixel.FlxGame;

#if cpp
import cpp.vm.Gc;
#elseif neko
import neko.vm.Gc;
#end

import states.SplashScreenState;

class Main extends Sprite
{
  public static inline var GAME_NAME = "Rosie";

  public function new()
  {
    super();

#if debug
    FlxG.signals.focusGained.add(function() trace("focusGained"));
    FlxG.signals.focusLost.add(function() trace("focusLost"));
    FlxG.signals.stateSwitched.add(function() trace("stateSwitched"));
#end

#if (cpp || neko)
    FlxG.signals.stateSwitched.add(function() Gc.run(true));
#end

    FlxG.signals.gameStarted.add(function() {
      FlxG.fixedTimestep = false;
      FlxG.cameras.useBufferLocking = true;
      FlxG.camera.pixelPerfectRender = true;
      FlxG.camera.filtersEnabled = false;
      FlxG.game.filtersEnabled = false;
      trace('Render Mode: ${FlxG.renderMethod}');
      trace('Mobile Device: ${FlxG.onMobile}');

#if FLX_RENDER_TRIANGLE
      trace("FLX_RENDER_TRIANGLE enabled");
#end
    });

    addChild(new FlxGame(320, 240, SplashScreenState, 2.0, 60, 60, true));

    // TODO: Make exceptions bring the player to an error screen gracefully
    // TODO: Make a proper package hierarchy
    // TODO: Re-add the mouse control plugin, turns out that was the cursor
  }
}
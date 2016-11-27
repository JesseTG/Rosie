package;

import flixel.FlxGame;
import flixel.FlxG;
import openfl.display.Sprite;
import flixel.system.scaleModes.PixelPerfectScaleMode;

#if cpp
import cpp.vm.Gc;
#elseif neko
import neko.vm.Gc;
#end

import states.MenuState;

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

    FlxG.fixedTimestep = false;
    FlxG.signals.gameStarted.add(function() {
      FlxG.camera.pixelPerfectRender = true;
    });

    addChild(new FlxGame(320, 240, MenuState, 2.0));

    // TODO: Make exceptions bring the player to an error screen gracefully
    // TODO: Make a proper package hierarchy
    // TODO: Re-add the mouse control plugin, turns out that was the cursor
  }
}
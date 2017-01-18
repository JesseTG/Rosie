package;

import openfl.display.Sprite;

#if (!html5) // No transitions on HTML5 target https://github.com/HaxeFlixel/flixel-addons/issues/285
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData.TransitionType;
import flixel.addons.transition.TransitionData;
import flixel.addons.transition.TransitionTiles;
#end

import flixel.math.FlxPoint;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.graphics.FlxGraphic;

#if cpp
import cpp.vm.Gc;
#elseif neko
import neko.vm.Gc;
#end

import states.SplashScreenState;

using ObjectInit;

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
    FlxG.signals.gameStarted.add(function() trace("gameStarted"));
    #end

    #if (cpp || neko)
    FlxG.signals.stateSwitched.add(function() Gc.run(true));
    #end

    FlxG.signals.stateSwitched.add(function() {
      if (FlxG.save.data.antialiasing != null) {
        FlxG.camera.antialiasing = FlxG.save.data.antialiasing;
      }
    });

    FlxG.signals.gameStarted.add(function() {
      if (FlxG.save.data.fullscreen != null) {
        FlxG.fullscreen = FlxG.save.data.fullscreen;
      }

      FlxG.fixedTimestep = false;
      FlxGraphic.defaultPersist = true;
      FlxG.cameras.useBufferLocking = true;
      FlxG.camera.pixelPerfectRender = true;
      FlxG.camera.filtersEnabled = false;
      FlxG.game.filtersEnabled = false;

      #if (!html5)
      FlxTransitionableState.defaultTransIn = new TransitionData().init(
        color = 0xFFFFFFFF,
        type = TransitionType.TILES,
        direction = FlxPoint.get(1, 1),
        duration = 0.25
      );

      FlxTransitionableState.defaultTransOut = FlxTransitionableState.defaultTransIn;
      #end

      trace('Render Mode: ${FlxG.renderMethod}');
      trace('Mobile Device: ${FlxG.onMobile}');

      #if FLX_RENDER_TRIANGLE
      trace("FLX_RENDER_TRIANGLE enabled");
      #end
    });

    addChild(new FlxGame(512, 288, SplashScreenState, 2.0, 60, 60, true));

    // TODO: Make exceptions bring the player to an error screen gracefully
    // TODO: Make a proper package hierarchy
    // TODO: Re-add the mouse control plugin, turns out that was the cursor
  }
}
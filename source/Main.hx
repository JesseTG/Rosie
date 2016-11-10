package;

import flixel.FlxGame;
import flixel.FlxG;
import openfl.display.Sprite;

#if cpp
import cpp.vm.Gc;
#elseif neko
import neko.vm.Gc;
#end

class Main extends Sprite
{
  public function new()
  {
    super();

#if debug
    FlxG.signals.focusGained.add(function() trace("focusGained"));
    FlxG.signals.focusLost.add(function() trace("focusLost"));
    FlxG.signals.stateSwitched.add(function() trace("stateSwitched"));
#end

#if cpp || neko
    FlxG.signals.stateSwitched.add(function() Gc.run(true));
#end

    FlxG.fixedTimestep = false;
    addChild(new FlxGame(320, 240, MenuState, 2.0));
    // TODO: Make a base State class that holds the background and make
    // everything else a SubState

    // TODO: Run the garbage collector between state transitions

    // TODO: Make a proper package hierarchy
  }
}
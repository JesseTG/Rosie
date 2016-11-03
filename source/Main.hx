package;

import flixel.FlxGame;
import openfl.display.Sprite;

class Main extends Sprite
{
  public function new()
  {
    super();
    addChild(new FlxGame(320, 240, MenuState, 2.0));
    // TODO: Make a base State class that holds the background and make
    // everything else a SubState

    // TODO: Run the garbage collector between state transitions

    // TODO: Make a proper package hierarchy
  }
}
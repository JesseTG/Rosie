package;

import flixel.FlxGame;
import openfl.display.Sprite;

class Main extends Sprite
{
  public function new()
  {
    super();
    addChild(new FlxGame(320, 240, PlayState, 2.0));
    // TODO: Trigger a state change with the PlayState's OnGameOver signal
  }
}
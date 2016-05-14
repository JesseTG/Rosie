package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.math.FlxMath;
import flixel.util.FlxColor;

import entities.Block;

class PlayState extends FlxState
{

  override public function create():Void
  {
    super.create();
    var b : Block = new Block(0, 0);
    b.makeGraphic(16, 16, FlxColor.RED);
    this.add(b);
  }

  override public function update(elapsed:Float):Void
  {
    super.update(elapsed);
  }
}

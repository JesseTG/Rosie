package states;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxBitmapFont;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.input.mouse.FlxMouseEventManager;
import flixel.text.FlxText;
import flixel.text.FlxBitmapText;
import flixel.math.FlxPoint;
import flixel.tile.FlxBaseTilemap.FlxTilemapAutoTiling;
import flixel.tile.FlxTilemap;
import flixel.util.FlxSignal.FlxTypedSignal;
import flixel.util.FlxColor;
import flixel.ui.FlxButton;
import flixel.util.FlxAxes;

using Lambda;

class MenuState extends CommonState
{
  private var _start : FlxButton;
  private var _titleLetters : FlxTypedSpriteGroup<FlxBitmapText>;


  override public function create():Void
  {
    super.create();

    _start = new FlxButton(160, 180, "Start", function() {
      FlxG.switchState(new PlayState());
    });
    _start.screenCenter(FlxAxes.X);
    _titleLetters = new FlxTypedSpriteGroup<FlxBitmapText>(5);


    this._titleLetters.setPosition(160 - (18.0 * "Rosie".length) / 2.0, 32);
    for (i in 0..."Rosie".length) {
      var text = new FlxBitmapText(this.font);
      text.text = "Rosie".charAt(i);
      text.setPosition(18*i, 0);

      var currentPoint = new FlxPoint(_titleLetters.x + text.x, _titleLetters.y + text.y);
      FlxTween.linearPath(
        text,
        [
          currentPoint,
          new FlxPoint(_titleLetters.x + text.x, _titleLetters.y + text.y - 8),
          currentPoint,
          new FlxPoint(_titleLetters.x + text.x, _titleLetters.y + text.y + 8),
          currentPoint
        ],
        0.75,
        true,
        {
          startDelay: i * 0.1,
          loopDelay: 1,
          type: FlxTween.LOOPING
        }
      );
      this._titleLetters.add(text);
    }
    this._titleLetters.screenCenter(FlxAxes.X);

    this.add(_start);
    this.add(this._titleLetters);
  }
}

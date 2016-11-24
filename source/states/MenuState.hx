package states;

import flixel.addons.editors.tiled.TiledObject;
import flixel.addons.editors.tiled.TiledObjectLayer;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxBitmapFont;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.input.mouse.FlxMouseEventManager;
import flixel.math.FlxPoint;
import flixel.text.FlxBitmapText;
import flixel.text.FlxText;
import flixel.tile.FlxBaseTilemap.FlxTilemapAutoTiling;
import flixel.tile.FlxTilemap;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxButton;
import flixel.util.FlxAxes;
import flixel.util.FlxColor;
import flixel.util.FlxSignal.FlxTypedSignal;

using Lambda;
using ObjectInit;

class MenuState extends CommonState
{
  private var menuGuiLayer : TiledObjectLayer;
  private var _start : FlxButton;
  private var _titleLetters : FlxTypedSpriteGroup<FlxBitmapText>;


  override public function create():Void
  {
    super.create();

    this.menuGuiLayer = cast(this.map.getLayer("MenuState GUI"));

    this.menuGuiLayer.objects.iter(function(object) {
      switch (object.name) {
        case "Play Button":
          this._start = new FlxButton(function() {
              FlxG.switchState(new PlayState());
          }).init(
            x = object.x,
            y = object.y - object.height,
            width = object.width,
            height = object.height,
            text = object.properties.text
          );
        default:
          // nop
      }
    });

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

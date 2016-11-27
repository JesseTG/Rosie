package states;

import flixel.addons.editors.tiled.TiledObject;
import flixel.addons.editors.tiled.TiledObjectLayer;
import flixel.addons.editors.tiled.TiledTileLayer;
import flixel.addons.editors.tiled.TiledTileSet;
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
import flixel.ui.FlxBitmapTextButton;
import flixel.util.FlxAxes;
import flixel.util.FlxColor;
import flixel.util.FlxSignal.FlxTypedSignal;

using Lambda;
using ObjectInit;

class MenuState extends CommonState
{
  private var menuGuiLayer : TiledObjectLayer;
  private var _start : FlxBitmapTextButton;
  private var _titleLetters : FlxTypedSpriteGroup<FlxBitmapText>;
  private var gate : FlxTilemap;
  private var gateLayer : TiledTileLayer;

  override public function create():Void
  {
    super.create();

    _titleLetters = new FlxTypedSpriteGroup<FlxBitmapText>(Main.GAME_NAME.length);

    this.menuGuiLayer = cast(this.map.getLayer("MenuState GUI"));
    this.gateLayer = cast(this.map.getLayer("Gate"));
    this.gate = cast new FlxTilemap().loadMapFromArray(
      gateLayer.tileArray,
      gateLayer.width,
      gateLayer.height,
      'assets/${tileSet.imageSource}',
      tileSet.tileWidth,
      tileSet.tileHeight,
      1 // Tiled uses 0-indexing, but I think FlxTilemap uses 1-indexing
    );
    this.gate.useScaleHack = false;

    this.menuGuiLayer.objects.iter(function(object) {
      switch (object.name) {
        case "Title":
          this._titleLetters.setPosition(object.x, object.y - object.height);
          for (i in 0...Main.GAME_NAME.length) {
            var text = new FlxBitmapText(this.font);
            text.text = Main.GAME_NAME.charAt(i);
            text.setPosition(16*i, 0);

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

        case "Play Button":
          // TODO: Clean up this part
          var source = spriteSet.getImageSourceByGid(object.gid).source;
          var index = source.lastIndexOf('/');
          var frameName = source.substr(index + 1);

          this._start = new FlxBitmapTextButton(object.properties.text, function() {
              FlxG.switchState(new PlayState());
          }).init(
            x = object.x,
            y = object.y - object.height,
            frames = this.sprites,
            frame = this.sprites.getByName(frameName)
          );

          _start.label.font = this.textFont;
          _start.label.letterSpacing = -3;
          _start.label.alignment = FlxTextAlign.CENTER;
          _start.label.color = FlxColor.WHITE;
          _start.label.autoSize = false;
          _start.label.fieldWidth = object.width;

          var normalAnim = _start.animation.getByName("normal");
          normalAnim.frames = [sprites.getIndexByName(frameName)];

          var pressedAnim = _start.animation.getByName("pressed");
          pressedAnim.frames = [sprites.getIndexByName("button-01.png")];

          var highlightAnim = _start.animation.getByName("highlight");
          highlightAnim.frames = [sprites.getIndexByName("button-02.png")];

          var point = new FlxPoint(0, _start.label.height);
          _start.labelAlphas = [1.0, 1.0, 1.0];
          _start.labelOffsets = [
            point,
            point,
            FlxPoint.get(0, _start.label.height + 2)
          ];
          _start.updateHitbox();

        default:
          // nop
      }
    });

    this.add(gate);
    this.add(_start);
    this.add(this._titleLetters);
    FlxG.console.registerObject("playButton", _start);
  }
}

package states;

import flixel.addons.editors.tiled.TiledObjectLayer;
import flixel.addons.editors.tiled.TiledTileLayer;
import flixel.addons.transition.FlxTransitionableState;
import flixel.FlxG;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.math.FlxPoint;
import flixel.text.FlxBitmapText;
import flixel.text.FlxText.FlxTextAlign;
import flixel.tile.FlxTilemap;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBitmapTextButton;
import flixel.util.FlxColor;

using Lambda;
using ObjectInit;

class MenuState extends CommonState
{
  private var menuGuiLayer : TiledObjectLayer;
  private var _start : FlxBitmapTextButton;
  private var _about : FlxBitmapTextButton;
  private var _titleLetters : FlxTypedSpriteGroup<FlxBitmapText>;
  private var gate : FlxTilemap;
  private var gateLayer : TiledTileLayer;

  override public function create():Void
  {
    super.create();

    _titleLetters = new FlxTypedSpriteGroup<FlxBitmapText>(Main.GAME_NAME.length);

    this.menuGuiLayer = cast(Assets.MainTilemap.getLayer("MenuState GUI"));
    this.gateLayer = cast(Assets.MainTilemap.getLayer("Gate"));
    this.gate = cast new FlxTilemap().loadMapFromArray(
      gateLayer.tileArray,
      gateLayer.width,
      gateLayer.height,
      'assets/${Assets.TileSet.imageSource}',
      Assets.TileSet.tileWidth,
      Assets.TileSet.tileHeight,
      1 // Tiled uses 0-indexing, but I think FlxTilemap uses 1-indexing
    );
    this.gate.useScaleHack = false;

    for (object in this.menuGuiLayer.objects) {
      switch (object.name) {
        case "Title":
          this._titleLetters.setPosition(object.x, object.y);
          this._titleLetters.solid = false;
          this._titleLetters.immovable = true;
          for (i in 0...Main.GAME_NAME.length) {
            var text = new FlxBitmapText(Assets.TitleFont);
            text.text = Main.GAME_NAME.charAt(i);
            text.setPosition(16*i, 0);
            text.solid = false;
            text.immovable = true;

            var currentPoint = FlxPoint.weak(_titleLetters.x + text.x, _titleLetters.y + text.y);
            FlxTween.linearPath(
              text,
              [
                currentPoint,
                FlxPoint.weak(_titleLetters.x + text.x, _titleLetters.y + text.y - 8),
                currentPoint,
                FlxPoint.weak(_titleLetters.x + text.x, _titleLetters.y + text.y + 8),
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
          var source = Assets.SpriteSet.getImageSourceByGid(object.gid).source;
          var index = source.lastIndexOf('/');
          var frameName = source.substr(index + 1);

          this._start = new FlxBitmapTextButton(0, 0, object.properties.text, function() {
            FlxTransitionableState.skipNextTransIn = true;
            FlxTransitionableState.skipNextTransOut = true;
            FlxG.switchState(new PlayState());
          }).init(
            x = object.x,
            y = object.y - object.height,
            frames = Assets.TextureAtlas,
            frame = Assets.TextureAtlas.getByName(frameName),
            solid = false,
            immovable = true
          );

          _start.label.font = Assets.TextFont;
          _start.label.letterSpacing = -3;
          _start.label.alignment = FlxTextAlign.CENTER;
          _start.label.color = FlxColor.WHITE;
          _start.label.autoSize = false;
          _start.label.fieldWidth = object.width;
          _start.label.solid = false;
          _start.label.immovable = true;

          var normalAnim = _start.animation.getByName("normal");
          normalAnim.frames = [Assets.TextureAtlas.getIndexByName(frameName)];

          var pressedAnim = _start.animation.getByName("pressed");
          pressedAnim.frames = [Assets.TextureAtlas.getIndexByName("button-01.png")];

          var highlightAnim = _start.animation.getByName("highlight");
          highlightAnim.frames = [Assets.TextureAtlas.getIndexByName("button-02.png")];

          var point = FlxPoint.weak(0, _start.label.height);
          _start.labelAlphas = [1.0, 1.0, 1.0];
          _start.labelOffsets = [
            point,
            point,
            FlxPoint.weak(0, _start.label.height + 2)
          ];
          _start.updateHitbox();

        case "About Button":
          // TODO: Clean up this part
          var source = Assets.SpriteSet.getImageSourceByGid(object.gid).source;
          var index = source.lastIndexOf('/');
          var frameName = source.substr(index + 1);

          this._about = new FlxBitmapTextButton(0, 0, object.properties.text, function() {
              FlxG.switchState(new AboutState());
          }).init(
            x = object.x,
            y = object.y - object.height,
            frames = Assets.TextureAtlas,
            frame = Assets.TextureAtlas.getByName(frameName),
            solid = false,
            immovable = true
          );

          _about.label.font = Assets.TextFont;
          _about.label.letterSpacing = -3;
          _about.label.alignment = FlxTextAlign.CENTER;
          _about.label.color = FlxColor.WHITE;
          _about.label.autoSize = false;
          _about.label.fieldWidth = object.width;
          _about.label.solid = false;
          _about.label.immovable = true;

          var normalAnim = _about.animation.getByName("normal");
          normalAnim.frames = [Assets.TextureAtlas.getIndexByName(frameName)];

          var pressedAnim = _about.animation.getByName("pressed");
          pressedAnim.frames = [Assets.TextureAtlas.getIndexByName("button-01.png")];

          var highlightAnim = _about.animation.getByName("highlight");
          highlightAnim.frames = [Assets.TextureAtlas.getIndexByName("button-02.png")];

          var point = FlxPoint.weak(0, _about.label.height);
          _about.labelAlphas = [1.0, 1.0, 1.0];
          _about.labelOffsets = [
            point,
            point,
            FlxPoint.weak(0, _about.label.height + 2)
          ];
          _about.updateHitbox();
        default:
          // nop
      }
    }

    this.add(gate);
    this.add(_start);
    this.add(_about);
    this.add(this._titleLetters);
    FlxG.console.registerObject("playButton", _start);
  }
}

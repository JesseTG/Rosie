package;

import flixel.addons.display.FlxBackdrop;
import flixel.addons.editors.tiled.TiledImageLayer;
import flixel.addons.editors.tiled.TiledMap;
import flixel.addons.editors.tiled.TiledObject;
import flixel.addons.editors.tiled.TiledObjectLayer;
import flixel.addons.editors.tiled.TiledPropertySet;
import flixel.addons.editors.tiled.TiledTileLayer;
import flixel.addons.editors.tiled.TiledTileSet;
import flixel.addons.plugin.FlxMouseControl;
import flixel.addons.util.FlxScene;
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

class MenuState extends FlxState
{
  private var _map : TiledMap;
  private var _background : FlxTilemap;
  private var _sprites : FlxAtlasFrames;
  private var _scene : FlxScene;
  private var _mouseControl : FlxMouseControl;
  private var _font : FlxBitmapFont;
  private var _start : FlxButton;
  private var _titleLetters : FlxTypedSpriteGroup<FlxBitmapText>;


  override public function create():Void
  {
    super.create();

    // TODO: Handle a missing tileset (or invalid data, e.g. unsupported format)
    _map = new TiledMap(AssetPaths.world__tmx);
    _background = new FlxTilemap();
    var bgImage = new FlxBackdrop(AssetPaths.bg__png, 0, 0, false, false);

    _start = new FlxButton(160, 180, "Start", function() {
      FlxG.switchState(new PlayState());
    });
    _start.screenCenter(FlxAxes.X);

    _sprites = FlxAtlasFrames.fromTexturePackerJson(AssetPaths.gfx__png, AssetPaths.gfx__json);
    _scene = new FlxScene(AssetPaths.main_menu__xml);
    // TODO: Abandon FlxScene, it's crap

    // TODO: Stop creating new FlxPoint's, I think there's a factory
    _font = FlxBitmapFont.fromMonospace(
      _sprites.getByName("block-font.png"),
      FlxBitmapFont.DEFAULT_CHARS,
      new FlxPoint(16, 32),
      null,
      new FlxPoint(2, 0)
    );

    _titleLetters = new FlxTypedSpriteGroup<FlxBitmapText>(5);

    // TODO: Store the tiled map on the texture atlas and load from there, instead of a separate image
    // TODO: Handle the layers/tilesets not being named in the way I want them to be
    var tiles : TiledTileLayer = cast(_map.getLayer("Ground"), TiledTileLayer);
    var bg : TiledImageLayer = cast(_map.getLayer("Background"), TiledImageLayer);
    var objects : TiledObjectLayer = cast(_map.getLayer("Objects"), TiledObjectLayer);

    var tileSet : TiledTileSet = _map.getTileSet("Overworld");

    _background.loadMapFromArray(
      tiles.tileArray,
      tiles.width,
      tiles.height,
      AssetPaths.tile_environment__png,
      tileSet.tileWidth,
      tileSet.tileHeight,
      1 // Tiled uses 0-indexing, but I think FlxTilemap uses 1-indexing
    );

    bgImage.loadGraphic(AssetPaths.bg__png);

    this._mouseControl = new FlxMouseControl();

    FlxG.plugins.add(_mouseControl);
    this.add(bgImage);
    this.add(_mouseControl);
    this.add(_background);
    this.add(_start);


    this._titleLetters.setPosition(160 - (18.0 * "Rosie".length) / 2.0, 32);
    for (i in 0..."Rosie".length) {
      var text = new FlxBitmapText(_font);
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

    this.add(this._titleLetters);


    FlxG.console.registerObject("font", _font);
  }
}

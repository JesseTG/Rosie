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
import flixel.input.mouse.FlxMouseEventManager;
import flixel.text.FlxText;
import flixel.text.FlxBitmapText;
import flixel.math.FlxPoint;
import flixel.tile.FlxBaseTilemap.FlxTilemapAutoTiling;
import flixel.tile.FlxTilemap;
import flixel.util.FlxSignal.FlxTypedSignal;
import flixel.util.FlxColor;

using Lambda;

class MenuState extends FlxState
{
  private var _map : TiledMap;
  private var _background : FlxTilemap;
  private var _sprites : FlxAtlasFrames;
  private var _scene : FlxScene;
  private var _mouseControl : FlxMouseControl;
  private var _font : FlxBitmapFont;


  override public function create():Void
  {
    super.create();

    // TODO: Handle a missing tileset (or invalid data, e.g. unsupported format)
    _map = new TiledMap(AssetPaths.world__tmx);
    _background = new FlxTilemap();
    var bgImage = new FlxBackdrop(AssetPaths.bg__png, 0, 0, false, false);

    _sprites = FlxAtlasFrames.fromTexturePackerJson(AssetPaths.gfx__png, AssetPaths.gfx__json);
    _scene = new FlxScene(AssetPaths.main_menu__xml);
    _font = FlxBitmapFont.fromMonospace(
      AssetPaths.block_font__png,
      FlxBitmapFont.DEFAULT_CHARS,
      new FlxPoint(17, 28),
      null,
      new FlxPoint(1, 0)
    );
//    _font.minOffsetX = 1;
    //_font.spaceWidth = 0;//1;
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

    for (i in 0...tileSet.numTiles) {
      var props = tileSet.tileProps[i];
      var gid = tileSet.toGid(i);
      if (props != null) {
        // If this tile defines any custom properties...
        if (props.contains("collidable") && props.get("collidable") == "true") {
          //_background.setTileProperties(gid, FlxObject.ANY, Block);
        }
        else {
          _background.setTileProperties(gid, FlxObject.NONE);
        }
      }
      else {
        _background.setTileProperties(gid, FlxObject.NONE);
      }
    }

    bgImage.loadGraphic(AssetPaths.bg__png);

    var gridObject : TiledObject = objects.objects.find(function(object:TiledObject) {
      return object.name == "Grid";
    });
    // TODO: Handle the case where this is null

    var size = Std.parseInt(gridObject.properties.get("Size"));
    this._mouseControl = new FlxMouseControl();

    FlxG.plugins.add(_mouseControl);
    this.add(bgImage);
    this.add(_mouseControl);
    this.add(_background);

    var text = new FlxBitmapText(_font);
    text.text = "Rosie";
    text.setPosition(16, 16);
    this.add(text);


    FlxG.console.registerObject("font", _font);
    FlxG.console.registerObject("text", text);
  }
}

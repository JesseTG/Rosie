package;

import flixel.addons.editors.tiled.TiledImageLayer;
import flixel.addons.editors.tiled.TiledMap;
import flixel.addons.editors.tiled.TiledTileLayer;
import flixel.addons.editors.tiled.TiledTileSet;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tile.FlxBaseTilemap.FlxTilemapAutoTiling;
import flixel.tile.FlxTilemap;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;

import entities.Block;

class PlayState extends FlxState
{
  private var _map : TiledMap;
  private var _background : FlxTilemap;

  override public function create():Void
  {
    super.create();
    var b : Block = new Block(0, 0);
    b.makeGraphic(16, 16, FlxColor.RED);
    this.add(b);

    // TODO: Handle a missing tileset (or invalid data, e.g. unsupported format)
    _map = new TiledMap(AssetPaths.world__tmx);
    _background = new FlxTilemap();
    var bgImage = new FlxSprite();

    // TODO: Store the tiled map on the texture atlas and load from there, instead of a separate image
    // TODO: Handle the layers/tilesets not being named in the way I want them to be
    var tiles : TiledTileLayer = cast(_map.getLayer("Ground"), TiledTileLayer);
    var bg : TiledImageLayer = cast(_map.getLayer("Background"), TiledImageLayer);
    var tileSet : TiledTileSet = _map.getTileSet("Overworld");

    FlxG.console.registerObject("tiles", tiles);
    FlxG.console.registerObject("tileSet", tileSet);

    _background.loadMapFromArray(
      tiles.tileArray,
      tiles.width,
      tiles.height,
      AssetPaths.tile_environment__png,
      tileSet.tileWidth,
      tileSet.tileHeight,
      1 // Tiled uses 0-indexing, but I think FlxTilemap uses 0-indexing
    );

    bgImage.loadGraphic(AssetPaths.bg__png);


    this.add(bgImage);
    this.add(_background);
  }

  override public function update(elapsed:Float):Void
  {
    super.update(elapsed);
  }
}

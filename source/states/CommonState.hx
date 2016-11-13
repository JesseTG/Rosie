package states;

import flixel.addons.display.FlxBackdrop;
import flixel.addons.editors.tiled.TiledImageLayer;
import flixel.addons.editors.tiled.TiledMap;
import flixel.addons.editors.tiled.TiledObject;
import flixel.addons.editors.tiled.TiledObjectLayer;
import flixel.addons.editors.tiled.TiledPropertySet;
import flixel.addons.editors.tiled.TiledTileLayer;
import flixel.addons.editors.tiled.TiledTileSet;
import flixel.addons.util.FlxScene;
import flixel.FlxG;
import flixel.FlxState;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxBitmapFont;
import flixel.math.FlxPoint;
import flixel.tile.FlxTilemap;

class CommonState extends FlxState {
  private static var BLOCK_FONT_SIZE = new FlxPoint(16, 32);
  private static var BLOCK_FONT_SPACING = new FlxPoint(2, 0);

  private var map : TiledMap;
  private var tilemap : FlxTilemap;
  private var bgImage : FlxBackdrop;
  private var sprites : FlxAtlasFrames;
  private var scene : FlxScene;
  private var font : FlxBitmapFont;
  private var tiles : TiledTileLayer;
  private var bgLayer : TiledImageLayer;
  private var objectLayer : TiledObjectLayer;
  private var tileSet : TiledTileSet;

  override public function create():Void {
    super.create();

    this.sprites = FlxAtlasFrames.fromTexturePackerJson(AssetPaths.gfx__png, AssetPaths.gfx__json);
    this.font = FlxBitmapFont.fromMonospace(
      this.sprites.getByName("block-font.png"),
      FlxBitmapFont.DEFAULT_CHARS,
      BLOCK_FONT_SIZE,
      null,
      BLOCK_FONT_SPACING
    );

    // TODO: Handle a missing tileset (or invalid data, e.g. unsupported format)
    this.map = new TiledMap(AssetPaths.world__tmx);
    this.tilemap = new FlxTilemap();
    this.bgImage = new FlxBackdrop(AssetPaths.bg__png, 0, 0, false, false);
    this.scene = new FlxScene(AssetPaths.game__xml);


    // TODO: Store the tiled map on the texture atlas and load from there, instead of a separate image
    // TODO: Handle the layers/tilesets not being named in the way I want them to be
    this.tiles = cast(map.getLayer("Ground"), TiledTileLayer);
    this.bgLayer = cast(map.getLayer("Background"), TiledImageLayer);
    this.objectLayer = cast(map.getLayer("Objects"), TiledObjectLayer);
    this.tileSet = map.getTileSet("Overworld");

    tilemap.loadMapFromArray(
      tiles.tileArray,
      tiles.width,
      tiles.height,
      AssetPaths.tile_environment__png,
      tileSet.tileWidth,
      tileSet.tileHeight,
      1 // Tiled uses 0-indexing, but I think FlxTilemap uses 1-indexing
    );

    this.bgImage.loadGraphic(AssetPaths.bg__png);
    this.add(bgImage);
    this.add(tilemap);
  }

  override public function destroy() {
    super.destroy();

  }
}
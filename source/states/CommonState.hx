package states;

import flixel.addons.display.FlxBackdrop;
import flixel.addons.editors.tiled.TiledImageLayer;
import flixel.addons.editors.tiled.TiledMap;
import flixel.addons.editors.tiled.TiledObject;
import flixel.addons.editors.tiled.TiledObjectLayer;
import flixel.addons.editors.tiled.TiledPropertySet;
import flixel.addons.editors.tiled.TiledTileLayer;
import flixel.addons.editors.tiled.TiledTileSet;
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
  private var font : FlxBitmapFont;
  private var groundLayer : TiledTileLayer;
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

    // TODO: Store the tiled map on the texture atlas and load from there, instead of a separate image
    // TODO: Handle the layers/tilesets not being named in the way I want them to be
    this.groundLayer = cast(map.getLayer("Ground"), TiledTileLayer);
    this.bgLayer = cast(map.getLayer("Background"), TiledImageLayer);
    this.objectLayer = cast(map.getLayer("Objects"), TiledObjectLayer);
    this.tileSet = map.getTileSet("Overworld");
    this.tilemap = cast new FlxTilemap().loadMapFromArray(
      groundLayer.tileArray,
      groundLayer.width,
      groundLayer.height,
      'assets/${tileSet.imageSource}',
      tileSet.tileWidth,
      tileSet.tileHeight,
      1 // Tiled uses 0-indexing, but I think FlxTilemap uses 1-indexing
    );

    this.bgImage = new FlxBackdrop('assets/${bgLayer.imagePath}', 0, 0, false, false);
    this.bgImage.useScaleHack = false;
    this.tilemap.useScaleHack = false;
    // Game looks like ass with this scale hack on

    this.add(bgImage);
    this.add(tilemap);
  }

  override public function destroy() {
    super.destroy();
  }
}
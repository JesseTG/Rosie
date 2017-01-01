package;

import flixel.addons.editors.tiled.TiledImageLayer;
import flixel.addons.editors.tiled.TiledMap;
import flixel.addons.editors.tiled.TiledObject;
import flixel.addons.editors.tiled.TiledObjectLayer;
import flixel.addons.editors.tiled.TiledPropertySet;
import flixel.addons.editors.tiled.TiledTileLayer;
import flixel.addons.editors.tiled.TiledTileSet;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxBitmapFont;
import flixel.math.FlxPoint;

import de.polygonal.ds.tools.Assert.assert;

@:final
class Assets {
  public static var initialized(default, null) = false;

  public static var TitleFont : FlxBitmapFont;
  public static var TextFont : FlxBitmapFont;
  public static var TextureAtlas : FlxAtlasFrames;
  public static var MainTilemap : TiledMap;
  public static var MainGroundLayer : TiledTileLayer;
  public static var MainBackgroundLayer : TiledImageLayer;
  public static var MainObjectLayer : TiledObjectLayer;
  public static var MainGuiLayer : TiledObjectLayer;
  public static var TileSet : TiledTileSet;
  public static var SpriteSet : TiledTileSet;

  public static var BLOCK_FONT_SIZE = FlxPoint.get(16, 32);
  public static var BLOCK_FONT_SPACING = FlxPoint.get(2, 0);

  public static var TEXT_FONT_SIZE = FlxPoint.get(10, 9);
  public static var TEXT_FONT_SPACING = FlxPoint.get(0, 0);

  private function new() {}

  public static function init() {
    if (!initialized) {
      TextureAtlas = FlxAtlasFrames.fromTexturePackerJson(AssetPaths.gfx__png, AssetPaths.gfx__json);
      assert(TextureAtlas != null);

      TitleFont = FlxBitmapFont.fromMonospace(
        TextureAtlas.getByName("block-font.png"),
        FlxBitmapFont.DEFAULT_CHARS,
        BLOCK_FONT_SIZE,
        null,
        BLOCK_FONT_SPACING
      );
      assert(TitleFont != null);

      TextFont = FlxBitmapFont.fromMonospace(
        TextureAtlas.getByName("text-font.png"),
        '${FlxBitmapFont.DEFAULT_CHARS}⌚⇦',
        TEXT_FONT_SIZE,
        null,
        TEXT_FONT_SPACING
      );
      assert(TextFont != null);

      MainTilemap = new TiledMap(AssetPaths.world__tmx);
      MainGroundLayer = cast(MainTilemap.getLayer("Ground"), TiledTileLayer);
      MainBackgroundLayer = cast(MainTilemap.getLayer("Background"), TiledImageLayer);
      MainObjectLayer = cast(MainTilemap.getLayer("Objects"), TiledObjectLayer);
      MainGuiLayer = cast(MainTilemap.getLayer("GUI"), TiledObjectLayer);


      assert(MainTilemap != null);
      assert(MainGroundLayer != null);
      assert(MainBackgroundLayer != null);
      assert(MainObjectLayer != null);
      assert(MainGuiLayer != null);

      TileSet = MainTilemap.getTileSet("Overworld");
      SpriteSet = MainTilemap.getTileSet("Sprites");
      assert(TileSet != null);
      assert(SpriteSet != null);

      trace("Assets initialized");
      initialized = true;
    }
  }
}
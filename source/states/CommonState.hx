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
import flixel.text.FlxBitmapText;
import flixel.text.FlxText.FlxTextAlign;
import flixel.tile.FlxTilemap;

using Lambda;
using ObjectInit;

class CommonState extends FlxState {
  private static var BLOCK_FONT_SIZE = new FlxPoint(16, 32);
  private static var BLOCK_FONT_SPACING = new FlxPoint(2, 0);

  private static var TEXT_FONT_SIZE = new FlxPoint(10, 9);
  private static var TEXT_FONT_SPACING = new FlxPoint(0, 0);

  private var map : TiledMap;
  private var tilemap : FlxTilemap;
  private var bgImage : FlxBackdrop;
  private var sprites : FlxAtlasFrames;
  private var font : FlxBitmapFont;
  private var textFont : FlxBitmapFont;
  private var highScoreLabel : FlxBitmapText;
  private var groundLayer : TiledTileLayer;
  private var bgLayer : TiledImageLayer;
  private var objectLayer : TiledObjectLayer;
  private var guiLayer : TiledObjectLayer;
  private var tileSet : TiledTileSet;
  private var spriteSet : TiledTileSet;

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

    this.textFont = FlxBitmapFont.fromMonospace(
      this.sprites.getByName("text-font.png"),
      '${FlxBitmapFont.DEFAULT_CHARS}⌚⇦',
      TEXT_FONT_SIZE,
      null,
      TEXT_FONT_SPACING
    );

    // TODO: Handle a missing tileset (or invalid data, e.g. unsupported format)
    this.map = new TiledMap(AssetPaths.world__tmx);

    // TODO: Store the tiled map on the texture atlas and load from there, instead of a separate image
    // TODO: Handle the layers/tilesets not being named in the way I want them to be
    this.groundLayer = cast(map.getLayer("Ground"), TiledTileLayer);
    this.bgLayer = cast(map.getLayer("Background"), TiledImageLayer);
    this.objectLayer = cast(map.getLayer("Objects"), TiledObjectLayer);
    this.guiLayer = cast(map.getLayer("GUI"), TiledObjectLayer);

    this.tileSet = map.getTileSet("Overworld");
    this.spriteSet = map.getTileSet("Sprites");
    this.tilemap = cast new FlxTilemap().loadMapFromArray(
      groundLayer.tileArray,
      groundLayer.width,
      groundLayer.height,
      'assets/${tileSet.imageSource}',
      tileSet.tileWidth,
      tileSet.tileHeight,
      1, // Tiled uses 0-indexing, but I think FlxTilemap uses 1-indexing
      1,
      27
    );

    this.bgImage = new FlxBackdrop('assets/${bgLayer.imagePath}', 0, 0, false, false).init(
      useScaleHack = false
    );
    this.tilemap.useScaleHack = false;
    // Game looks like ass with this scale hack on

    var highScore = 0;
    if (FlxG.save.data.highScore != null) {
      highScore = cast(FlxG.save.data.highScore, Int);
    }

    this.guiLayer.objects.iter(function(object:TiledObject) {
      switch (object.name) {
        case "High Score Display":
          this.highScoreLabel = new FlxBitmapText(this.textFont).init(
            x = object.x,
            y = object.y,
            alignment = FlxTextAlign.LEFT,
            letterSpacing = Std.parseInt(object.properties.letterSpacing),
            text = 'TOP ${highScore}'
          );
        default:
          // nop
      }
    });

    this.add(bgImage);
    this.add(tilemap);
    this.add(highScoreLabel);
  }

  override public function destroy() {
    super.destroy();
  }
}
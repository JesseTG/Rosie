package;

using Lambda;

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
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tile.FlxBaseTilemap.FlxTilemapAutoTiling;
import flixel.tile.FlxTilemap;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;

import entities.Block;
import entities.BlockColor;
import entities.BlockGrid;

class PlayState extends FlxState
{
  private var _map : TiledMap;
  private var _background : FlxTilemap;
  private var _sprites : FlxAtlasFrames;
  private var _blockGrid : BlockGrid;
  private var _scene : FlxScene;
  private var _mouseControl : FlxMouseControl;

  private var _hud : FlxGroup;

  override public function create():Void
  {
    super.create();

    FlxG.worldDivisions = 4;
    FlxObject.SEPARATE_BIAS = 12;
    // TODO: Handle a missing tileset (or invalid data, e.g. unsupported format)
    _map = new TiledMap(AssetPaths.world__tmx);
    _background = new FlxTilemap();
    var bgImage = new FlxBackdrop(AssetPaths.bg__png, 0, 0, false, false);

    _sprites = FlxAtlasFrames.fromTexturePackerJson(AssetPaths.gfx__png, AssetPaths.gfx__json);

    _scene = new FlxScene(AssetPaths.game__xml);

    _hud = new FlxGroup();
    _scene.spawn(_hud, "hud");

    // TODO: Store the tiled map on the texture atlas and load from there, instead of a separate image
    // TODO: Handle the layers/tilesets not being named in the way I want them to be
    var tiles : TiledTileLayer = cast(_map.getLayer("Ground"), TiledTileLayer);
    var bg : TiledImageLayer = cast(_map.getLayer("Background"), TiledImageLayer);
    var objects : TiledObjectLayer = cast(_map.getLayer("Objects"), TiledObjectLayer);

    var tileSet : TiledTileSet = _map.getTileSet("Overworld");

    FlxG.console.registerObject("tiles", tiles);
    FlxG.console.registerObject("tileSet", tileSet);
    FlxG.console.registerObject("sprites", _sprites);
    FlxG.console.registerObject("log", FlxG.log);
    FlxG.console.registerObject("tilemap", _background);

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
          _background.setTileProperties(gid, FlxObject.ANY, Block);
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

    _blockGrid = new BlockGrid(gridObject.x, gridObject.y, size, _sprites);

    FlxG.console.registerObject("blockGrid", _blockGrid);



    this.add(bgImage);
    this.add(_background);
    this.add(_blockGrid);
    this.add(_hud);
    this.add(_mouseControl);
  }

  override public function update(elapsed:Float):Void
  {
    super.update(elapsed);

    FlxG.collide(_blockGrid, _background, function(block:Block, b:FlxObject) {
      if (block.isTouching(block.gravity.Direction)) {
        block.moves = false;
        block.velocity.set(0, 0);
        block.snapToGrid();

        // The block that touches the walls is marked as non-moving, and then
        // any block that tocuhes *that* will be too, and then, and then, etc.
        // Induction!
      }
    });


    FlxG.overlap(_blockGrid, _blockGrid,
      function(a:Block, b:Block) {
        if (a.moves != b.moves) {
          // If a moving block is colliding with another that isn't...
          a.moves = false;
          b.moves = false;

          a.snapToGrid();
          b.snapToGrid();
        }
      },

      function(a:Block, b:Block) : Bool {
        // This ensures blocks in different rows or columns won't brush up against
        // each other when the gravity won't allow it

        if (this._blockGrid.gravity.Orientation == Horizontal) {
          return FlxObject.separateX(a, b);
        }
        else if (this._blockGrid.gravity.Orientation == Vertical) {
          return FlxObject.separateY(a, b);
        }

        return false;
      }
    );
  }
}

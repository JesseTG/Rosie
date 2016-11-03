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
import flixel.group.FlxGroup;
import flixel.input.mouse.FlxMouseEventManager;
import flixel.text.FlxText;
import flixel.math.FlxPoint;
import flixel.tile.FlxBaseTilemap.FlxTilemapAutoTiling;
import flixel.tile.FlxTilemap;
import flixel.util.FlxSignal.FlxTypedSignal;
import flixel.util.FlxColor;

import de.polygonal.Printf;

import entities.Block;
import entities.BlockColor;
import entities.BlockGrid;

using Lambda;

class PlayState extends FlxState
{
  private var _map : TiledMap;
  private var _background : FlxTilemap;
  private var _sprites : FlxAtlasFrames;
  private var _blockGrid : BlockGrid;
  private var _scene : FlxScene;
  private var _mouseControl : FlxMouseControl;

  private var _hud : FlxGroup;
  private var _score : Int;
  private var _time : Float;
  private var _timeDisplay : FlxText;
  private var _scoreDisplay : FlxText;
  private var _timeChangeDisplay : FlxText;

  private var _arrow : FlxSprite;

  public var OnGameOver : FlxTypedSignal<Void->Void>;

  /**
   * Called when the score is computed.  The parameter is the score.
   */
  public var OnScore(default, null) : FlxTypedSignal<Int->Void>;

  public var round(default, null) : Int;
  public var gameRunning(default, null) : Bool;


  override public function create():Void
  {
    super.create();

    this.OnGameOver = new FlxTypedSignal<Void->Void>();
    this.OnScore = new FlxTypedSignal<Int->Void>();

    // TODO: Handle a missing tileset (or invalid data, e.g. unsupported format)
    _map = new TiledMap(AssetPaths.world__tmx);
    _background = new FlxTilemap();
    var bgImage = new FlxBackdrop(AssetPaths.bg__png, 0, 0, false, false);

    _sprites = FlxAtlasFrames.fromTexturePackerJson(AssetPaths.gfx__png, AssetPaths.gfx__json);
    _scene = new FlxScene(AssetPaths.game__xml);
    _score = 0;

    _hud = new FlxGroup();
    _scene.spawn(_hud, "hud");
    _timeDisplay = _scene.object("time");

    _arrow = new FlxSprite(16, 16);
    _arrow.frame =  _sprites.getByName("arrow.png");
    _arrow.resetSizeFromFrame();

    _timeChangeDisplay = new FlxText(_timeDisplay.x, _timeDisplay.y);
    _timeChangeDisplay.alignment = FlxTextAlign.RIGHT;
    _timeChangeDisplay.size = 10;
    _timeChangeDisplay.borderColor = FlxColor.BLACK;
    _timeChangeDisplay.borderStyle = FlxTextBorderStyle.OUTLINE_FAST;

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

    _time = _scene.const("starting-time");

    FlxG.plugins.add(_mouseControl);


    _scoreDisplay = _scene.object("score");

    _blockGrid = new BlockGrid(gridObject.x, gridObject.y, size, _sprites);

    this._initCallbacks();


    _arrow.angle = cast(_blockGrid.gravity);
    _arrow.centerOrigin();

    FlxG.console.registerObject("blockGrid", _blockGrid);
    FlxG.console.registerObject("arrow", _arrow);
    FlxG.console.registerObject("tiles", tiles);
    FlxG.console.registerObject("tileSet", tileSet);
    FlxG.console.registerObject("sprites", _sprites);
    FlxG.console.registerObject("log", FlxG.log);
    FlxG.console.registerObject("tilemap", _background);
    FlxG.console.registerFunction("sceneObject", _scene.object);
    FlxG.watch.add(_blockGrid, "_blocksMoving", "Blocks Moving");
    FlxG.watch.addExpression("blockGrid.countLiving()", "# Blocks Alive");
    FlxG.watch.addExpression("blockGrid.countDead()", "# Blocks Dead");
    FlxG.watch.addExpression("blockGrid.length", "# Blocks");
    FlxG.watch.add(_blockGrid, "numColors", "# Colors");
    FlxG.watch.add(this, "round", "Round");
    FlxG.watch.add(this, "_score", "Score");

    this.add(bgImage);
    this.add(_background);
    this.add(_blockGrid);
    this.add(_hud);
    this.add(_arrow);
    this.add(_mouseControl);
    this.add(_timeChangeDisplay);

    this.gameRunning = true;
    this.round = 1;

    FlxG.sound.playMusic(AssetPaths.music__ogg, 1, true);
  }

  override public function update(elapsed:Float):Void
  {
    super.update(elapsed);

    if (this._blockGrid.canClick && this.gameRunning) {
      _time -= elapsed;
      _timeDisplay.text = Printf.format("%.1f", [Math.max(0, _time)]);
    }


    if (_time <= 0 && this.gameRunning) {
      this.gameRunning = false;
      FlxMouseEventManager.removeAll();
      this.OnGameOver.dispatch();
    }
  }

  private inline function _initCallbacks() {
    _blockGrid.OnStopMoving.add(function() {
      _arrow.angle = cast(_blockGrid.gravity);
    });

    this.OnScore.add(function(score:Int) {
      this._score += score;
      _scoreDisplay.text = Std.string(this._score);
    });
    // TODO: Tween the score counter with FlxNumTween

    _blockGrid.OnSuccessfulClick.add(function(blocks:Array<Block>) {
      FlxG.sound.play(AssetPaths.clear_blocks__wav);

      if (blocks.length > 3) {
        // If we cleared MORE than three blocks... (3 will clear but not score)
        this.OnScore.dispatch((blocks.length - 2) * (blocks.length - 2));
      }
    });

    this._blockGrid.OnBeforeBlocksGenerated.add(function() {
      this.round++;

      this._blockGrid.numColors = switch (this.round) {
        case 1 | 2: 4;
        case 3 | 4: 5;
        default: 6;
      };
    });

    this._blockGrid.OnBlocksGenerated.add(this._addBonusTime);

    this._blockGrid.OnBadClick.add(this._subtractTime);
    this._blockGrid.OnBadClick.add(function(_) {
      FlxG.sound.play(AssetPaths.not_allowed__wav);
    });

    this.OnGameOver.addOnce(function() {
      if (FlxG.sound.music != null) {
        // If there's music playing...
        FlxG.sound.music.stop();
      }
    });
  }

  private function _addBonusTime(blocksCreated:Int) {
    var bonus = blocksCreated * 0.05;

    _time = Math.min(_time + bonus, _scene.const("starting-time"));
    _timeChangeDisplay.color = FlxColor.GREEN;
    _timeChangeDisplay.text = Printf.format("+%.1f", [bonus]);
    FlxTween.linearMotion(
      _timeChangeDisplay,
      _timeDisplay.x,
      _timeDisplay.y,
      _timeDisplay.x,
      _timeDisplay.y - 8,
      0.5,
      true
    );

    FlxTween.color(
      _timeChangeDisplay,
      0.5,
      FlxColor.GREEN,
      FlxColor.fromRGB(0, 255, 0, 0),
      {
        startDelay: 0.1
      }
    );
  }

  private function _subtractTime(blocks:Array<Block>) {
    _time -= 1.0;

    for (block in blocks) {
      FlxTween.linearPath(
        block,
        [
          block.getPosition(),
          new FlxPoint(block.x + block.width / 4, block.y),
          block.getPosition(),
          new FlxPoint(block.x - block.width / 4, block.y),
          block.getPosition()
        ],
        0.25,
        true,
        {
          type: FlxTween.ONESHOT
        }
      );
    }
    _timeChangeDisplay.color = FlxColor.RED;
    _timeChangeDisplay.text = Printf.format("-%.1f", [1.0]);
    FlxTween.linearMotion(
      _timeChangeDisplay,
      _timeDisplay.x,
      _timeDisplay.y,
      _timeDisplay.x,
      _timeDisplay.y + 8,
      0.5,
      true
    );

    FlxTween.color(
      _timeChangeDisplay,
      0.5,
      FlxColor.RED,
      FlxColor.fromRGB(255, 0, 0, 0),
      {
        startDelay: 0.1
      }
    );
  }
}

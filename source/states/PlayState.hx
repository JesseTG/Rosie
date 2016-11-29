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
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxBitmapFont;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.input.mouse.FlxMouseEventManager;
import flixel.text.FlxText;
import flixel.text.FlxBitmapText;
import flixel.math.FlxPoint;
import flixel.tile.FlxBaseTilemap.FlxTilemapAutoTiling;
import flixel.tile.FlxTilemap;
import flixel.util.FlxSignal.FlxTypedSignal;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.util.FlxAxes;

import de.polygonal.Printf;
import de.polygonal.core.util.Assert.D;
import de.polygonal.ds.Array2;

import entities.Block;
import entities.BlockColor;
import entities.GravityIndicator;
import entities.BlockGrid;
import entities.GravityIndicator.GravityIndicatorState;
import entities.GravityPanel;
import entities.GravityDirection;
import util.ReverseIterator;
import util.FlxAsyncIteratorLoop;
import haxe.ds.ObjectMap;

using Lambda;
using ObjectInit;
using entities.GravityDirection;

class PlayState extends CommonState
{

  private var _blockGrid : BlockGrid;
  private var _playGui : TiledObjectLayer;
  private var _gate: Array2<FlxSprite>;
  private var _gateGroup : FlxSpriteGroup;
  private var _gridSize : Int;


  private var _score : Int;
  private var _time : Float;
  private var _timeDisplay : FlxBitmapText;
  private var _scoreDisplay : FlxBitmapText;
  private var _timeChangeDisplay : FlxBitmapText;
  private var _hints : FlxSpriteGroup;
  private var _gravityIndicators : Array<GravityIndicator>;
  private var _gravityPanels : Array<FlxTypedGroup<GravityPanel>>;
  // TODO: Organize this crap

  public var OnGameStartAnimationStart(default, null) : FlxTypedSignal<Void->Void>;

  public var OnGameStart(default, null) : FlxTypedSignal<Void->Void>;

  public var OnGameStartAnimationFinish(default, null) : FlxTypedSignal<Void->Void>;

  public var OnGameOver(default, null) : FlxTypedSignal<Void->Void>;

  /**
   * Called when the score is computed.  The parameter is the score.
   */
  public var OnScore(default, null) : FlxTypedSignal<Int->Void>;

  public var OnGameOverAnimationFinish(default, null) : FlxTypedSignal<Void->Void>;

  public var round(default, null) : Int;

  // TODO: Clarify the semantics
  public var gameRunning(default, null) : Bool;


  override public function create():Void
  {
    super.create();

    this.OnGameOver = new FlxTypedSignal<Void->Void>();
    this.OnScore = new FlxTypedSignal<Int->Void>();
    this.OnGameStartAnimationStart = new FlxTypedSignal<Void->Void>();
    this.OnGameOverAnimationFinish = new FlxTypedSignal<Void->Void>();
    this.OnGameStart = new FlxTypedSignal<Void->Void>();
    this.OnGameStartAnimationFinish = new FlxTypedSignal<Void->Void>();

#if debug
    this.OnGameOver.add(function() trace("OnGameOver"));
    this.OnScore.add(function(score) trace('OnScore(${score})'));
    this.OnGameStartAnimationStart.add(function() trace("OnGameStartAnimationStart"));
    this.OnGameOverAnimationFinish.add(function() trace("OnGameOverAnimationFinish"));
    this.OnGameStart.add(function() trace("OnGameStart"));
    this.OnGameStartAnimationFinish.add(function() trace("OnGameStartAnimationFinish"));
#end

    this._playGui = cast(this.map.getLayer("PlayState GUI"));
    this._gravityIndicators = [for (i in 0...GravityDirection.Count) null];
    this._gravityPanels = [for (i in 0...GravityDirection.Count) {
      new FlxTypedGroup<GravityPanel>().init(
        visible = false
      );
    }];


    this.objectLayer.objects.iter(function(object) {
      switch (object.name) {
        case "Gravity Indicator":
          var direction = GravityDirection.createByName(object.type);
          var index = GravityDirection.getIndex(direction);
          this._gravityIndicators[index] = new GravityIndicator(object.x, object.y, sprites, direction).init(
            angle = object.angle,
            flipX = object.flippedHorizontally,
            flipY = object.flippedVertically
          );
        case "Gravity Panel":
          var direction = GravityDirection.createByName(object.type);
          var index = GravityDirection.getIndex(direction);
          var panel = new GravityPanel(object.x, object.y - object.height, sprites);
          this._gravityPanels[index].add(panel);
        case "Grid":
          // TODO: Come up with a better way to render the grid
          _gridSize = Std.parseInt(object.properties.size);
          this._gateGroup = new FlxSpriteGroup(object.x, object.y - tileSet.tileHeight);
          this._gate = new Array2<FlxSprite>(_gridSize, _gridSize);
          this._gate.forEach(function(_,xIndex,yIndex) {
            var sprite = new FlxSprite().init(
              x = xIndex * tileSet.tileWidth,
              y = yIndex * tileSet.tileHeight,
              frames = sprites,
              frame = sprites.getByName("gate.png")
            );
            _gateGroup.add(sprite);
            return sprite;
          });

          _blockGrid = new BlockGrid(
            object.x,
            object.y - 16,
            _gridSize,
            sprites
          );
        default:
          // nop
      }
    });
    D.assert(!this._gravityIndicators.has(null));

    _playGui.objects.iter(function(object:TiledObject) {
      switch (object.name) {
        case "Score Display":
          _scoreDisplay = new FlxBitmapText(this.font).init(
            text = "0",
            x = object.x,
            y = object.y - tileSet.tileHeight,
            letterSpacing = Std.parseInt(object.properties.letterSpacing),
            autoSize = object.properties.autoSize == "true",
            alignment = FlxTextAlign.RIGHT
          );
        case "Time Remaining":
          _timeDisplay = new FlxBitmapText(this.textFont).init(
            text = "0",
            x = object.x,
            y = object.y,
            alignment = FlxTextAlign.RIGHT,
            letterSpacing = Std.parseInt(object.properties.letterSpacing)
          );

          _timeChangeDisplay = new FlxBitmapText(this.textFont).init(
            x = _timeDisplay.x,
            y = _timeDisplay.y,
            alignment = _timeDisplay.alignment,
            letterSpacing = _timeDisplay.letterSpacing
          );
        case "Hint Hand":          // default image load
          var source = spriteSet.getImageSourceByGid(object.gid).source;
          var index = source.lastIndexOf('/');

          var hand = new FlxSprite().init(
            x = object.x,
            y = object.y - object.height,
            frames = this.sprites,
            frame = this.sprites.getByName(source.substr(index + 1)),
            pixelPerfectPosition = true,
            pixelPerfectRender = true
          );
          this.add(hand);
          FlxTween.linearMotion(
            hand,
            hand.x,
            hand.y,
            hand.x - 4,
            hand.y,
            0.5,
            true,
            {
              type: FlxTween.PINGPONG,
              ease: FlxEase.circInOut
            }
          );
        default:
          // default image load
          var source = spriteSet.getImageSourceByGid(object.gid).source;
          var index = source.lastIndexOf('/');

          this.add(new FlxSprite().init(
            x = object.x,
            y = object.y - object.height,
            frames = this.sprites,
            frame = this.sprites.getByName(source.substr(index + 1))
          ));
      };
    });



    _score = 0;
    _time = 60;

    this._initCallbacks();

    FlxG.console.registerObject("blockGrid", _blockGrid);
    FlxG.console.registerObject("tileSet", tileSet);
    FlxG.console.registerObject("sprites", sprites);
    FlxG.console.registerObject("log", FlxG.log);
    FlxG.watch.add(_blockGrid, "_blocksMoving", "Blocks Moving");
    FlxG.watch.addExpression("blockGrid.countLiving()", "# Blocks Alive");
    FlxG.watch.addExpression("blockGrid.countDead()", "# Blocks Dead");
    FlxG.watch.addExpression("blockGrid.length", "# Blocks");
    FlxG.watch.add(_blockGrid, "numColors", "# Colors");
    FlxG.watch.add(this, "round", "Round");
    FlxG.watch.add(this, "_score", "Score");

    for (p in _gravityPanels) {
      this.add(p);
    }
    for (g in _gravityIndicators) {
      this.add(g);
    }
    this.add(_blockGrid);
    this.add(_gateGroup);
    this.add(_timeDisplay);
    this.add(_timeChangeDisplay);
    this.add(_scoreDisplay);

    this.round = 1;
    this.OnGameStartAnimationStart.dispatch();
  }

  override public function update(elapsed:Float):Void
  {
    super.update(elapsed);

    if (this._blockGrid.readyForInput && this.gameRunning) {
      _time -= elapsed;
      _timeDisplay.text = Printf.format("⌚   %.1f", [Math.max(0, _time)]);
      if (_time <= 11 && Math.abs(_time - Math.fround(_time)) < 0.000001) {
        // If we have under 10 seconds to go, and exactly one second has passed...
        FlxG.sound.play(AssetPaths.time_running_out__wav);
      }
    }

    if (_time <= 0 && this.gameRunning) {
      this.gameRunning = false;
      FlxMouseEventManager.removeAll();
      this.OnGameOver.dispatch();
    }
    else if (!this.gameRunning && _time <= 0) {
      if (FlxG.mouse.justPressed) {
        FlxG.switchState(new MenuState());
      }
    }
  }

  override public function destroy() {
    super.destroy();

    FlxG.watch.remove(_blockGrid, "_blocksMoving");
    FlxG.watch.removeExpression("blockGrid.countLiving()");
    FlxG.watch.removeExpression("blockGrid.countDead()");
    FlxG.watch.removeExpression("blockGrid.length");
    FlxG.watch.remove(_blockGrid, "numColors");
    FlxG.watch.remove(this, "round");
    FlxG.watch.remove(this, "_score");

    this._blockGrid = null;
    this._playGui = null;
    this._gate = null;
    this._gateGroup = null;
    this._timeDisplay = null;
    this._scoreDisplay = null;
    this._timeChangeDisplay = null;
    this._hints = null;
    this._gravityIndicators = null;
    this._gravityPanels = null;
  }

  // TODO: Unregister everything in the console, somehow

  private inline function _initCallbacks() {
    this.OnGameStartAnimationStart.addOnce(function() {

      var _gameStartGate : FlxAsyncIteratorLoop<Int> = null;
      _gameStartGate = new FlxAsyncIteratorLoop<Int>(
        new ReverseIterator(_gridSize - 1, 0),
        function(row) {
          for (i in 0..._gridSize) {
            var sprite = _gate.get(i, row);
            sprite.kill();
          }

          FlxG.sound.play(AssetPaths.gate_move__wav);
        },
        null,
        function() {
          this.remove(_gameStartGate);
          new FlxTimer().start(1, function(_) this.OnGameStartAnimationFinish.dispatch());
        },
        8
      );

      this.add(_gameStartGate);
      _gameStartGate.start();
    });

    this.OnGameStartAnimationFinish.addOnce(function() {
      this.OnGameStart.dispatch();
    });

    this.OnGameStart.add(function() {
      this.gameRunning = true;
      // TODO: Init the block event handlers in here

      FlxG.sound.playMusic(AssetPaths.music__ogg, 1, true);
    });

    this.OnGameStart.add(function() {
      var indicator = _gravityIndicators[_blockGrid.gravity.getIndex()];
      indicator.state = GravityIndicatorState.On;
      indicator.visible = true;
    });

    this.OnScore.add(function(score:Int) {
      this._score += score;
      _scoreDisplay.text = Std.string(this._score);
    });
    // TODO: Tween the score counter with FlxNumTween

    _blockGrid.OnSuccessfulClick.add(function(blocks:Array<Block>) {
      FlxG.sound.play(AssetPaths.clear_blocks__wav);

      if (blocks.length >= 3) {
        // If we cleared at least 3 blocks...
        this.OnScore.dispatch((blocks.length - 2) * (blocks.length - 2));
      }

      if (blocks.length >= 6) {
        this._addBonusTime(Std.int(blocks.length * 0.25));
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

    this._blockGrid.OnStopMoving.add(function() {
      var prevIndex = this._blockGrid.gravity.previous().getIndex();
      var index = _blockGrid.gravity.getIndex();

      this._gravityIndicators[prevIndex].state = GravityIndicatorState.Off;
      this._gravityIndicators[index].state = GravityIndicatorState.On;

      this._gravityPanels[prevIndex].visible = false;
      this._gravityPanels[index].visible = true;
    });

    // TODO: Handle the case where the grid is full and no groups exist
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

      var _gameEndGate = new FlxAsyncIteratorLoop<Int>(
        0..._gridSize,
        function(row) {
          for (i in 0..._gridSize) {
            var sprite = _gate.get(i, row);
            sprite.revive();
          }

          FlxG.sound.play(AssetPaths.gate_move__wav);
        },
        null,
        function() {
          new FlxTimer().start(0.5, function(_) this.OnGameOverAnimationFinish.dispatch());
        },
        8
      );

      this.add(_gameEndGate);
      _gameEndGate.start();
    });

    this.OnGameOverAnimationFinish.addOnce(function() {


      _displayGameOver();

      var highScore = 0;
      if (FlxG.save.data.highScore != null) {
        highScore = cast(FlxG.save.data.highScore, Int);
      }

      if (this._score > highScore) {
        FlxG.save.data.highScore = this._score;
        FlxG.save.flush(function(_) {
          trace('Saved high score of ${this._score}');
        });
        FlxG.sound.play(AssetPaths.high_score__wav);
      }
    });
  }

  public override function onFocusLost() {
    FlxG.camera.fill(FlxColor.BLACK, false);
  }

  private function _displayGameOver() {
    var gameOver = new FlxBitmapText(font);
    gameOver.text = "Game Over";
    gameOver.screenCenter();

    this.add(gameOver);
  }

  private function _addBonusTime(blocksCreated:Int) {
    var bonus = blocksCreated * 0.05;

    _time = Math.min(_time + bonus, 60);
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

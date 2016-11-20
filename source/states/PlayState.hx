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

import entities.Block;
import entities.BlockColor;
import entities.GravityIndicator;
import entities.BlockGrid;
import entities.GravityIndicator.GravityIndicatorState;
import entities.GravityPanel;
import entities.GravityPanel.GravityPanelState;
import entities.GravityDirection;
import haxe.ds.ObjectMap;

using Lambda;
using ObjectInit;
using entities.GravityDirection;

class PlayState extends CommonState
{

  private var _blockGrid : BlockGrid;

  private var _score : Int;
  private var _time : Float;
  private var _timeDisplay : FlxBitmapText;
  private var _scoreDisplay : FlxBitmapText;
  private var _timeChangeDisplay : FlxBitmapText;
  private var _hints : FlxSpriteGroup;
  private var _arrow : FlxSprite;
  private var _gravityIndicators : Array<GravityIndicator>;
  private var _gravityPanels : Array<FlxTypedGroup<GravityPanel>>;
  // TODO: Organize this crap

  public var OnGameOver(default, null) : FlxTypedSignal<Void->Void>;

  /**
   * Called when the score is computed.  The parameter is the score.
   */
  public var OnScore(default, null) : FlxTypedSignal<Int->Void>;

  public var round(default, null) : Int;

  // TODO: Clarify the semantics
  public var gameRunning(default, null) : Bool;


  override public function create():Void
  {
    super.create();

    this.OnGameOver = new FlxTypedSignal<Void->Void>();
    this.OnScore = new FlxTypedSignal<Int->Void>();


    var gridObject : TiledObject = this.objectLayer.objects.find(function(object:TiledObject) {
      return object.name == "Grid";
    });
    // TODO: Handle the case where this is null
    var size = Std.parseInt(gridObject.properties.get("Size"));

    this._gravityIndicators = [for (i in 0...4) null];
    this.objectLayer.objects.iter(function(object:TiledObject) {
      if (object.name == "Gravity Indicator") {
        var direction = GravityDirection.createByName(object.type);
        var index = GravityDirection.getIndex(direction);
        this._gravityIndicators[index] = new GravityIndicator(object.x, object.y, sprites, direction).init(
          angle = object.angle,
          flipX = object.flippedHorizontally,
          flipY = object.flippedVertically
        );
      }
    });
    D.assert(!this._gravityIndicators.has(null));

    this._gravityPanels = [for (i in 0...this._gravityIndicators.length) {
      new FlxTypedGroup<GravityPanel>().init(
        visible = false
      );
    }];
    this.objectLayer.objects.iter(function(object:TiledObject) {
      if (object.name == "Gravity Panel") {
        var direction = GravityDirection.createByName(object.type);
        var index = GravityDirection.getIndex(direction);
        this._gravityPanels[index].add(new GravityPanel(object.x, object.y, sprites));
      }
    });

    _blockGrid = new BlockGrid(gridObject.x, gridObject.y, size, sprites);

    this._gravityIndicators[_blockGrid.gravity.getIndex()].state = GravityIndicatorState.On;
    this._gravityIndicators[_blockGrid.gravity.getIndex()].visible = true;

    _timeDisplay = new FlxBitmapText(this.textFont).init(
      x = 260,
      y = 8,
      alignment = FlxTextAlign.RIGHT,
      letterSpacing = -3
    );

    _timeChangeDisplay = new FlxBitmapText(this.textFont).init(
      x = _timeDisplay.x,
      y = _timeDisplay.y,
      alignment = _timeDisplay.alignment,
      letterSpacing = _timeDisplay.letterSpacing
    );

    _arrow = new FlxSprite(16, 16).init(
      frame = this.sprites.getByName("arrow.png"),
      angle = cast(_blockGrid.gravity)
    );
    _arrow.resetSizeFromFrame();
    _arrow.centerOrigin();

    _score = 0;
    _time = 60;

    _scoreDisplay = new FlxBitmapText(this.font).init(
      text = "0",
      y = 8,
      letterSpacing = 2
    );
    _scoreDisplay.screenCenter(FlxAxes.X);

    this._initHints();
    this._initCallbacks();

    FlxG.console.registerObject("blockGrid", _blockGrid);
    FlxG.console.registerObject("arrow", _arrow);
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
    this.add(_blockGrid);
    for (g in _gravityIndicators) {
      this.add(g);
    }
    this.add(_timeDisplay);
    this.add(_hints);
    this.add(_arrow);
    this.add(_timeChangeDisplay);
    this.add(_scoreDisplay);

    this.gameRunning = true;
    this.round = 1;

    FlxG.sound.playMusic(AssetPaths.music__ogg, 1, true);
  }

  override public function update(elapsed:Float):Void
  {
    super.update(elapsed);

    if (this._blockGrid.readyForInput && this.gameRunning) {
      _time -= elapsed;
      _timeDisplay.text = Printf.format("%.1f", [Math.max(0, _time)]);
      // TODO: Come up with a better placement for the text
    }


    if (_time <= 0 && this.gameRunning) {
      this.gameRunning = false;
      FlxMouseEventManager.removeAll();
      this.OnGameOver.dispatch();
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
  }

  // TODO: Unregister everything in the console, somehow

  private inline function _initCallbacks() {
    _blockGrid.OnStopMoving.add(function() {
      _arrow.angle = cast(_blockGrid.gravity);
    });

    this.OnScore.add(function(score:Int) {
      this._score += score;
      _scoreDisplay.text = Std.string(this._score);
      _scoreDisplay.screenCenter(FlxAxes.X);
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

      _displayGameOver();

      // TODO: Wait for use input
      new FlxTimer().start(3.0, function(_) {
        FlxG.switchState(new MenuState());
      }, 1);
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

  private inline function _initHints() {
    this._hints = new FlxSpriteGroup();

    _hints.setPosition(8, 96);
    var hint_yes = new FlxSprite(16, 0).init(
      frame = sprites.getByName("icon-clear-yes.png")
    );
    _hints.add(hint_yes);

    var hand1 = new FlxSprite(0, 0).init(
      frame = sprites.getByName("hand.png")
    );
    _hints.add(hand1);

    var yes = new FlxSprite(36, 0).init(
      frame = sprites.getByName("ok.png")
    );
    _hints.add(yes);

    var hint_no = new FlxSprite(16, 24).init(
      frame = sprites.getByName("icon-clear-no.png")
    );
    _hints.add(hint_no);

    var hand2 = new FlxSprite(0, 24).init(
      frame = sprites.getByName("hand.png")
    );
    _hints.add(hand2);

    var no = new FlxSprite(36, 24).init(
      frame = sprites.getByName("no.png")
    );
    _hints.add(no);
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

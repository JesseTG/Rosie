package states;

import haxe.ds.Vector;

#if (!html5)
import flixel.addons.transition.FlxTransitionableState;
#end
import flixel.addons.display.FlxTiledSprite;
import flixel.addons.editors.tiled.TiledObjectLayer;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.input.mouse.FlxMouseEventManager;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.text.FlxBitmapText;
import flixel.text.FlxText.FlxTextAlign;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxPool;
import flixel.util.FlxSignal.FlxTypedSignal;
import flixel.util.FlxTimer;

import de.polygonal.ds.List;
import de.polygonal.ds.tools.Assert.assert;
import de.polygonal.Printf;

import entities.Block;
import entities.BlockGrid;
import entities.GravityDirection;
import entities.GravityIndicator.GravityIndicatorState;
import entities.GravityIndicator;
import entities.GravityPanel;
import entities.Rosie;
import entities.RosieEmote.EmoteState;
import util.FlxAsyncIteratorLoop;

using Lambda;
using ObjectInit;
using entities.GravityDirection;

class PlayState extends CommonState
{
  private var _formatArray : Array<Float>;
  // for some reason, Printf.eformat or .format without an array doesn't work
  // it might be bugs in Printf

  private var _blockGrid : BlockGrid;
  private var _playGui : TiledObjectLayer;
  private var _hintGui : TiledObjectLayer;
  private var _gate : FlxTiledSprite;
  private var _gridSize : Int;
  private var _gameOverText : FlxBitmapText;
  private var _readyToLeaveState : Bool;

  private var _score : Int;
  private var _time : Float;
  private var _timeDisplay : FlxBitmapText;
  private var _scoreDisplay : FlxBitmapText;
  private var _timeChangeDisplay : FlxBitmapText;
  private var _hints : FlxSpriteGroup;

  private var _gravityIndicator : GravityIndicator;
  private var _gravityIndicatorCoordinates : Vector<FlxPoint>;

  private var _gravityPanel : GravityPanel;
  private var _gravityPanelCoordinates : Vector<FlxRect>;
  private var _rosie : Rosie;
  private var _timeSinceLastGoodClick : Float;
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

    _formatArray = [0.0];
    _score = 0;
    _time = 60;
    _readyToLeaveState = false;

    this._playGui = cast(Assets.MainTilemap.getLayer("PlayState GUI"));
    this._hintGui = cast(Assets.MainTilemap.getLayer("Hints"));

    this._gravityIndicator = new GravityIndicator(0, 0, Assets.TextureAtlas);
    this._gravityIndicator.exists = false;
    this._gravityIndicatorCoordinates = new Vector<FlxPoint>(GravityDirectionTools.Count);
    this._gravityPanel = new GravityPanel(0, 0, 0, 0, Assets.TextureAtlas);
    this._gravityPanel.exists = false;
    this._gravityPanelCoordinates = new Vector<FlxRect>(GravityDirectionTools.Count);

    this._hints = new FlxSpriteGroup();
    for (object in _hintGui.objects) {
      switch (object.name) {
        case "Hint Hand":
          var source = Assets.SpriteSet.getImageSourceByGid(object.gid).source;
          var index = source.lastIndexOf('/');

          var hand = new FlxSprite().init(
            x = object.x,
            y = object.y - object.height,
            frames = Assets.TextureAtlas,
            frame = Assets.TextureAtlas.getByName(source.substr(index + 1)),
            pixelPerfectPosition = true,
            pixelPerfectRender = true,
            solid = false,
            immovable = true
          );
          this._hints.add(hand);
          FlxTween.linearMotion(
            hand,
            hand.x,
            hand.y,
            hand.x,
            hand.y + 4,
            0.5,
            true,
            _handTweenOptions
          );
        case "Hint Text":
          var text = new FlxBitmapText(Assets.TextFont).init(
            x = object.x,
            y = object.y,
            pixelPerfectPosition = true,
            pixelPerfectRender = true,
            text = object.properties.text,
            alignment = FlxTextAlign.LEFT,
            width = object.width,
            letterSpacing = Std.parseInt(object.properties.letterSpacing),
            autoSize = object.properties.autoSize == "true",
            solid = false,
            moves = false,
            immovable = true
          );

          this._hints.add(text);
        default:
          // default image load
          var source = Assets.SpriteSet.getImageSourceByGid(object.gid).source;
          var index = source.lastIndexOf('/');

          this._hints.add(new FlxSprite().init(
            x = object.x,
            y = object.y - object.height,
            frames = Assets.TextureAtlas,
            frame = Assets.TextureAtlas.getByName(source.substr(index + 1)),
            moves = false,
            immovable = true,
            solid = false
          ));
      }
    }
    this.add(_hints);

    for (object in Assets.MainObjectLayer.objects) {
      switch (object.name) {
        case "Gravity Indicator":
          var coords = FlxPoint.get(object.x, object.y);
          var direction = GravityDirection.createByName(object.type);
          var index = direction.getIndex();
          this._gravityIndicatorCoordinates[index] = coords;
        case "Gravity Panel":
          var coords = FlxRect.get(object.x, object.y, object.width, object.height);
          var direction = GravityDirection.createByName(object.type);
          var index = direction.getIndex();
          this._gravityPanelCoordinates[index] = coords;
        case "Grid":
          // TODO: Come up with a better way to render the grid
          _gridSize = Std.parseInt(object.properties.size);
          this._gate = new FlxTiledSprite(
            Assets.TextureAtlas.parent,
            _gridSize * Assets.TileSet.tileWidth,
            _gridSize * Assets.TileSet.tileHeight,
            true,
            true
          )
          .init(
            x = object.x,
            y = object.y,
            pixelPerfectRender = true,
            pixelPerfectPosition = true,
            moves = false,
            immovable = true,
            solid = false
          );
          this._gate.loadFrame(Assets.TextureAtlas.getByName("gate.png"));

          _blockGrid = new BlockGrid(object.x, object.y, _gridSize, Assets.TextureAtlas);
        case "Rosie":
          _rosie = new Rosie(object.x, object.y - object.height, Assets.TextureAtlas, tilemap).init(
            pixelPerfectPosition = true,
            pixelPerfectRender = true
          );
        default:
          // nop
      }
    }

#if debug
    for (i in 0...GravityDirectionTools.Count) {
      assert(this._gravityIndicatorCoordinates.get(i) != null);
      assert(this._gravityPanelCoordinates.get(i) != null);
    }
#end

    for (object in _playGui.objects) {
      switch (object.name) {
        case "Score Display":
          _scoreDisplay = new FlxBitmapText(Assets.TitleFont).init(
            text = "0",
            x = object.x,
            y = object.y,
            letterSpacing = Std.parseInt(object.properties.letterSpacing),
            autoSize = object.properties.autoSize == "true",
            alignment = FlxTextAlign.RIGHT,
            moves = false,
            immovable = true,
            solid = false
          );
        case "Time Remaining":
          _formatArray[0] = Math.max(0, _time);
          _timeDisplay = new FlxBitmapText(Assets.TextFont).init(
            text = Printf.format("⌚   %.1f", _formatArray),
            x = object.x,
            y = object.y,
            alignment = FlxTextAlign.RIGHT,
            letterSpacing = Std.parseInt(object.properties.letterSpacing),
            moves = false,
            immovable = true,
            solid = false,
            useTextColor = true
          );

          _timeChangeDisplay = new FlxBitmapText(Assets.TextFont).init(
            x = _timeDisplay.x,
            y = _timeDisplay.y,
            alignment = _timeDisplay.alignment,
            letterSpacing = _timeDisplay.letterSpacing,
            moves = false,
            immovable = true,
            solid = false
          );
        case "Game Over":
          _gameOverText = new FlxBitmapText(Assets.TitleFont).init(
            text = object.properties.text,
            x = object.x,
            y = object.y,
            alignment = FlxTextAlign.CENTER,
            letterSpacing = Std.parseInt(object.properties.letterSpacing),
            moves = false,
            immovable = true,
            solid = false
          );
      };
    }


    this._initCallbacks();

    FlxG.console.registerObject("blockGrid", _blockGrid);
    FlxG.console.registerObject("tileSet", Assets.TileSet);
    FlxG.console.registerObject("sprites", Assets.TextureAtlas);
    FlxG.console.registerObject("log", FlxG.log);
    FlxG.console.registerObject("gate", _gate);
    FlxG.console.registerObject("rosie", _rosie);
    FlxG.watch.add(_blockGrid, "_blocksMoving", "Blocks Moving");
    FlxG.watch.addExpression("blockGrid.countLiving()", "# Blocks Alive");
    FlxG.watch.addExpression("blockGrid.countDead()", "# Blocks Dead");
    FlxG.watch.addExpression("blockGrid.length", "# Blocks");
    FlxG.watch.add(_blockGrid, "numColors", "# Colors");
    FlxG.watch.add(this, "round", "Round");
    FlxG.watch.add(this, "_score", "Score");
    FlxG.watch.add(this, "_time", "Time");
    FlxG.watch.add(this._rosie.fsm, "age", "Rosie's State Age");
    FlxG.watch.add(this, "_timeSinceLastGoodClick", "Time Since Last Good Click");
    FlxG.watch.add(FlxPoint.pool, "length", "# Pooled FlxPoints");
    FlxG.watch.add(FlxRect.pool, "length", "# Pooled FlxRects");

    this.add(_gravityPanel);
    this.add(_gravityIndicator);
    this.add(_blockGrid);
    this.add(_rosie);
    this.add(_gate);
    this.add(_timeDisplay);
    this.add(_timeChangeDisplay);
    this.add(_scoreDisplay);

    this._timeSinceLastGoodClick = 0;
    this.round = 1;
    this.OnGameStartAnimationStart.dispatch();
  }

  private static var _handTweenOptions = {
    type: FlxTween.PINGPONG,
    ease: FlxEase.quadOut
  };

  override public function update(elapsed:Float):Void
  {
    super.update(elapsed);

    if (this._blockGrid.readyForInput && this.gameRunning) {
      _time -= elapsed;
      _timeSinceLastGoodClick += elapsed;
      _formatArray[0] = Math.max(0, _time);
      _timeDisplay.text = Printf.format("⌚   %.1f", _formatArray);
      _timeDisplay.textColor = (_time >= 10) ? FlxColor.WHITE : FlxColor.RED;
      if (_timeSinceLastGoodClick >= 10 && _rosie.emote.state == EmoteState.None && FlxG.random.bool(1)) {
        _rosie.emote.state = FlxG.random.getObject([
          EmoteState.Bored,
          EmoteState.Confused,
          EmoteState.Huh
        ]);
      }

      if (_time >= 1 && _time <= 10 && Math.abs(_time - Math.fround(_time)) < elapsed) {
        // If we have under 10 seconds to go, and exactly one second has passed...
        FlxG.sound.play(AssetPaths.time_running_out__wav, 1, false, false);
      }
    }

    if (_time <= 0 && this.gameRunning) {
      this.gameRunning = false;
      this.OnGameOver.dispatch();
    }
    else if (!this.gameRunning && _time <= 0) {
      if (_readyToLeaveState && FlxG.mouse.justPressed) {
        #if (!html5)
        FlxTransitionableState.skipNextTransIn = true;
        FlxTransitionableState.skipNextTransOut = true;
        #end
        FlxG.switchState(new MenuState());
      }
    }
  }

  override public function destroy() {
    super.destroy();

    if (FlxG.sound.music != null) {
      FlxG.sound.music.stop();
    }

    FlxG.watch.remove(_blockGrid, "_blocksMoving");
    FlxG.watch.removeExpression("blockGrid.countLiving()");
    FlxG.watch.removeExpression("blockGrid.countDead()");
    FlxG.watch.removeExpression("blockGrid.length");
    FlxG.watch.remove(_blockGrid, "numColors");
    FlxG.watch.remove(this, "round");
    FlxG.watch.remove(this, "_score");
    FlxG.watch.remove(this, "_time");
    FlxG.watch.remove(this._rosie.fsm, "age");
    FlxG.watch.remove(this, "_timeSinceLastGoodClick");
    FlxG.watch.remove(FlxPoint.pool, "length");
    FlxG.watch.remove(FlxRect.pool, "length");

    for (rect in this._gravityPanelCoordinates) {
      (cast (FlxRect.pool, FlxPool<FlxRect>)).put(rect);
    }

    for (point in this._gravityIndicatorCoordinates) {
      (cast (FlxPoint.pool, FlxPool<FlxPoint>)).put(point);
    }

    this._blockGrid.destroy();
    this._gravityIndicator.destroy();
    this._gravityPanel.destroy();

    this._blockGrid = null;
    this._playGui = null;
    this._gate = null;
    this._timeDisplay = null;
    this._scoreDisplay = null;
    this._timeChangeDisplay = null;
    this._hints = null;
    this._gravityIndicatorCoordinates = null;
    this._gravityPanel = null;
    this._gravityIndicator = null;
    this._gravityPanelCoordinates = null;
  }

  // TODO: Unregister everything in the console, somehow
  private inline function _initCallbacks() {
    this.OnGameStartAnimationStart.addOnce(function() {
      for (block in _blockGrid) {
        FlxMouseEventManager.setObjectMouseEnabled(block, false);
      }

      var _gameStartGate : FlxAsyncIteratorLoop<Int> = null;
      _gameStartGate = new FlxAsyncIteratorLoop<Int>(
        0..._gridSize,
        function(row) {
          _gate.height -= Assets.TileSet.tileHeight;
          // NOTE: Can't set a sprite's height to 0, so we just remove it when
          // it's only one row deep (see the callback below)
          FlxG.sound.play(AssetPaths.gate_move__wav, 1, false, false);
        },
        null,
        function() {
          this.remove(_gameStartGate);
          this.remove(_gate);
          _gate.kill();
          new FlxTimer().start(1, function(_) this.OnGameStartAnimationFinish.dispatch());
        },
        8
      );

      this.add(_gameStartGate);
      _gameStartGate.start();
    });

    this.OnGameStartAnimationFinish.addOnce(function() {
      _blockGrid.forEach(function(b) {
        FlxMouseEventManager.setObjectMouseEnabled(b, true);
      });

      this.OnGameStart.dispatch();
    });

    this.OnGameStart.add(function() {
      this.gameRunning = true;
      // TODO: Init the block event handlers in here

      this._gravityIndicator.exists = true;
      this._gravityPanel.exists = true;
      FlxG.sound.playMusic(AssetPaths.music__ogg, 1, true);
    });

    this.OnScore.add(_increaseScore);

    _blockGrid.OnSuccessfulClick.add(_getReadyToComputeScore);
    _blockGrid.OnSuccessfulClick.add(_setRosieEmote);

    _blockGrid.OnBadClick.add(_subtractTime);
    _blockGrid.OnBadClick.add(_playNotAllowed);
    _blockGrid.OnBadClick.add(_rosieEmoteBadClick);

    this._blockGrid.OnBeforeBlocksGenerated.add(function() {
      this.round++;

      this._blockGrid.numColors = switch (this.round) {
        case 1 | 2: 4;
        case 3 | 4: 5;
        default: 6;
      };
    });

    this._blockGrid.OnStopMoving.add(function() {
      var index = _blockGrid.gravity.getIndex();

      var indicatorCoords = this._gravityIndicatorCoordinates.get(index);
      this._gravityIndicator.setPosition(indicatorCoords.x, indicatorCoords.y);

      switch (GravityDirection.createByIndex(index)) {
        case GravityDirection.Up | GravityDirection.Down:
          this._gravityIndicator.animation.play(cast GravityIndicatorState.Horizontal);
        case GravityDirection.Left | GravityDirection.Right:
          this._gravityIndicator.animation.play(cast GravityIndicatorState.Vertical);
      }
      this._gravityIndicator.resetSizeFromFrame();

      var panelCoords = this._gravityPanelCoordinates.get(index);
      this._gravityPanel.setPosition(panelCoords.x, panelCoords.y);
      this._gravityPanel.setSize(panelCoords.width, panelCoords.height);
    });

    // TODO: Handle the case where the grid is full and no groups exist
    this._blockGrid.OnBlocksGenerated.add(this._addBonusTime);
    this._blockGrid.OnBlocksGenerated.add(function(blocks) {
      FlxG.sound.play(AssetPaths.blocks_appear__wav, 1, false, false);
      for (block in blocks) {
        block.animation.play(cast BlockAnimation.Appear);
      }
    });



    this.OnGameOver.addOnce(function() {
      if (FlxG.sound.music != null) {
        // If there's music playing...
        FlxG.sound.music.stop();
      }

      FlxG.sound.play(AssetPaths.time_out__wav, 1, false, false);
      this._gravityIndicator.exists = false;
      this._gravityPanel.exists = false;

      this._rosie.emote.state = EmoteState.Doh;
      FlxMouseEventManager.removeAll();

      var _gameEndGate = new FlxAsyncIteratorLoop<Int>(
        0..._gridSize - 1,
        function(row) {
          _gate.height += Assets.TileSet.tileHeight;

          FlxG.sound.play(AssetPaths.gate_move__wav, 1, false, false);
        },
        function() {
          // NOTE: When this animation starts, the gate will be of height 16,
          // because you can't set a sprite's size to be 0.  So the OnStart
          // callback will add the sprite to the screen.  (This is also why we
          // run the animation for one LESS than the grid height)

          FlxG.sound.play(AssetPaths.gate_move__wav, 1, false, false);
          _gate.revive();
          this.add(_gate);
        },
        function() {
          new FlxTimer().start(0.5, function(_) this.OnGameOverAnimationFinish.dispatch());
        },
        8
      );

      this.add(_gameEndGate);
      _gameEndGate.start();
    });

    this.OnGameOverAnimationFinish.addOnce(function() {
      this.add(_gameOverText);
      this.remove(_blockGrid);
      this.remove(_gravityIndicator);
      this.remove(_gravityPanel);

      var highScore = 0;
      if (FlxG.save.data.highScore != null) {
        highScore = cast(FlxG.save.data.highScore, Int);
      }

      var soundToPlay : String;
      if (this._score > highScore) {
        // If we got a high score...
        soundToPlay = AssetPaths.high_score__wav;
        this.highScoreLabel.text = 'TOP ${this._score}';

        FlxG.save.data.highScore = this._score;
        FlxG.save.flush(1, function(success) {
          // Save the high score, THEN let the player exit
          this._readyToLeaveState = true;
          if (success) {
            // If the high score was successfully written...
            trace('Saved high score of ${this._score}');
          }
          else {
            trace('Failed to save high score of ${this._score}');
          }
        });
        FlxG.sound.play(AssetPaths.high_score__wav, 1);
      }
      else {
        // If we got no high score, just let the player exit
        soundToPlay = AssetPaths.game_over__ogg;
        this._readyToLeaveState = true;
      }

      FlxG.sound.play(soundToPlay, 1, false, true, function() {
        new FlxTimer().start(1, function(_) {
          FlxG.sound.playMusic(AssetPaths.game_over_loop__ogg);
        });
      });
    });
  }

  public override function onFocusLost() {
    FlxG.camera.fill(FlxColor.BLACK, false);
  }

  // OnSuccessfulClick callbacks ///////////////////////////////////////////////
  private function _getReadyToComputeScore(blocks:List<Block>) {
    this._timeSinceLastGoodClick = 0;
    FlxG.sound.play(AssetPaths.clear_blocks__wav, 1, false, false);

    this.OnScore.dispatch((blocks.size - 2) * (blocks.size - 2));
    // We'll always have cleared at least 3 blocks here.
  }

  private function _setRosieEmote(blocks:List<Block>) {
    if (blocks.size == 3 && _rosie.emote.state == EmoteState.None && FlxG.random.bool(60)) {
      // If we cleared exactly 3 blocks, Rosie's not emoting, and then with 60% probability...
      _rosie.emote.state = EmoteState.Neutral; // Rosie is not impressed
    }
    else if (blocks.size >= 10) {
      _rosie.emote.state = EmoteState.VeryHappy;
    }
    else if (blocks.size >= 7 && _rosie.emote.state != EmoteState.VeryHappy) {
      _rosie.emote.state = EmoteState.Happy;
    }
  }
  // End OnSuccessfulClick callbacks ///////////////////////////////////////////

  // OnScore callbacks
  private function _increaseScore(score:Int) {
    this._score += score;
    _scoreDisplay.text = Std.string(this._score);
    // TODO: Tween the score counter with FlxNumTween
  }
  // End OnScore callbacks

  // OnBadClick Callbacks //////////////////////////////////////////////////////

  private function _subtractTime(blocks) {
    _time -= 1.0;

    _timeChangeDisplay.color = FlxColor.RED;
    _formatArray[0] = 1.0;
    _timeChangeDisplay.text = Printf.format("-%.1f", _formatArray);
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

  private function _playNotAllowed(_) {
    FlxG.sound.play(AssetPaths.not_allowed__wav, 1, false, false);
  }

  private static var BadClickEmotes = [EmoteState.Sad, EmoteState.Confused, EmoteState.Angry];
  private static var BadClickEmoteWeights = [3.0, 2.0, 1.0];
  private function _rosieEmoteBadClick(_) {
    if (_rosie.emote.state == EmoteState.None && FlxG.random.bool(30)) {
      _rosie.emote.state = FlxG.random.getObject(BadClickEmotes, BadClickEmoteWeights);
    }
  }
  // End OnBadClick Callbacks //////////////////////////////////////////////////

  private function _addBonusTime(blocks:List<Block>) {
    var blocksCreated = blocks.size;
    var bonus = blocksCreated * 0.05;

    _time = Math.min(_time + bonus, 60);
    _formatArray[0] = bonus;
    _timeChangeDisplay.color = FlxColor.GREEN;
    _timeChangeDisplay.text = Printf.format("+%.1f", _formatArray);
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

}

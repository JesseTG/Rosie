package entities;

using Lambda;

import haxe.EnumTools;

import flixel.math.FlxMath;
import flixel.FlxObject;
import flixel.addons.display.FlxExtendedSprite;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.input.mouse.FlxMouseEventManager;
import de.polygonal.ds.Array2;

class BlockGrid extends FlxTypedSpriteGroup<Block> {
  // 
  private var _blockGrid : Array2<Block>;

  public var gridSize(default, null) : Int;
  public var gravity(default, null) : GravityDirection;
  private var _canClick : Bool;

  // TODO: Don't hard-code the block size in this class
  public function new(x:Int, y:Int, size:Int, sprites:FlxFramesCollection) {
    super(x, y - 16, size * size + Std.int(0.5 * size));

    this._canClick = true;
    FlxMouseEventManager.add(this, function(grid:BlockGrid) {
      //trace(this);
    }, false, true, false);

    this._blockGrid = new Array2<Block>(size, size);
    this.gravity = GravityDirection.Right;
    this.gridSize = size;

    _blockGrid.forEach(function(block:Block, gridX:Int, gridY:Int) {
      var b = this.recycle(Block, function() {
        trace("New block created");
        var blockColor = BlockColor.All[Std.random(BlockColor.All.length - 2)];
        return new Block(gridX * 16, gridY * 16, sprites, blockColor);
      });

      FlxMouseEventManager.add(b, function(block:Block) {
        if (this._canClick) {
          // If this block is NOT moving...
          block.kill();
          this._canClick = false;
          this._startMovingBlocks(block);
        }
      }, false, true, false);

      b.gravity = this.gravity;
      b.velocity.set(0, 0);
      this.add(b);
      return b;
    });
  }

  public override function update(elapsed:Float) {
    if (!this._canClick && !_anyMoving()) {
      // If all blocks have stopped moving...
      this._stopMovingBlocks();
    }

    super.update(elapsed);
  }

  private function _updateGrid() {
    this._blockGrid.forEach(function(b:Block, x:Int, y:Int) {
      return null;
    });
    // TODO: Not sure why I can't use Array2.clear() here (Doing so crashes)

    this.forEachExists(function(block:Block) {
      var x = Math.round(block.x / block.frameWidth) * block.frameWidth;
      var y = Math.round(block.y / block.frameHeight) * block.frameHeight;

      x -= Std.int(this.x);
      y -= Std.int(this.y);

      x = Math.round(x / block.frameWidth);
      y = Math.round(y / block.frameHeight);

      _blockGrid.set(x, y, block);
    });

    trace(this._blockGrid);
  }

  private function _anyMoving() : Bool {
    return this.members.exists(function(block:Block) {
      // For each Block on-screen...
      return block.alive && block.exists && (!FlxMath.equal(block.velocity.x, 0) || !FlxMath.equal(block.velocity.y, 0));
      // Return true if it's moving horizontally OR vertically
    });
  }

  private function _rotateGravity() {
    // TODO: I'm sure Haxe provides a nicer way to write the following code
    if (this.gravity == GravityDirection.Down) {
      this.gravity = GravityDirection.Left;
    }
    else if (this.gravity == GravityDirection.Left) {
      this.gravity = GravityDirection.Up;
    }
    else if (this.gravity == GravityDirection.Up) {
      this.gravity = GravityDirection.Right;
    }
    else if (this.gravity == GravityDirection.Right) {
      this.gravity = GravityDirection.Down;
    }

    this.forEachExists(function(block:Block) {
      block.gravity = this.gravity;
    });
    // TODO: What if, for some reason, this.gravity isn't one of these?
  }

  private function _startMovingBlocks(clicked:Block) {
    var clickedX = Math.floor(clicked.x / clicked.frameWidth) * clicked.frameWidth;
    var clickedY = Math.floor(clicked.y / clicked.frameHeight) * clicked.frameHeight;

    this._rotateGravity();

    this.forEachExists(function(block:Block) {
      var x = Math.floor(block.x / block.frameWidth) * block.frameWidth;
      var y = Math.floor(block.y / block.frameHeight) * block.frameHeight;

      if (!block.isTouching(this.gravity.Direction)) {
        block.moves = true;
      }

    });
  }

  private function _stopMovingBlocks() {
      trace("All blocks have stopped moving");
      this._updateGrid();
      this._canClick = true;
  }

  public override function destroy() {
    super.destroy();

    FlxMouseEventManager.remove(this);
    this._blockGrid.clear();
    this._blockGrid = null;
  }

  private inline function getIndex(x:Int, y:Int) : Int {
    return y * gridSize + x;
  }
}
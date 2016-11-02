package entities;

import haxe.EnumTools;

import flixel.FlxG;
import flixel.math.FlxPoint;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.input.mouse.FlxMouseEventManager;
import flixel.util.FlxSignal.FlxTypedSignal;
import de.polygonal.ds.Array2;
import de.polygonal.ds.ArrayedQueue;
import de.polygonal.core.util.Assert;

import util.ReverseIterator;

using Lambda;

class BlockGrid extends FlxTypedSpriteGroup<Block> {
  //
  private var _blockGrid : Array2<Block>;
  private var _blocksMoving : Int;
  private var _blocksCreated : Int;
  private var _frames:FlxFramesCollection;

  public var gridSize(default, null) : Int;
  public var gravity(default, null) : GravityDirection;
  public var canClick(default, null) : Bool;

  /**
   * Called when an allowed group of blocks is clicked.  Parameter is the array
   * of blocks in the group, in no particular order.
   */
  public var OnSuccessfulClick(default, null) : FlxTypedSignal<Array<Block>->Void>;

  /**
   * Called when the player clicks on a block but it's not enough to make a group.
   */
  public var OnBadClick(default, null) : FlxTypedSignal<Array<Block>->Void>;

  /**
   * Called when the first block starts moving.
   */
  public var OnStartMoving(default, null) : FlxTypedSignal<Void->Void>;

  /**
   * Called when the last block stops moving.
   */
  public var OnStopMoving(default, null) : FlxTypedSignal<Void->Void>;

  /**
   * Called when no more moves can be made.
   */
  public var OnNoMoreMoves(default, null) : FlxTypedSignal<Void->Void>;

  /**
   * Called when blocks are generated, except for the first time (i.e. when the
   * game starts).
   */
  public var OnBlocksGenerated(default, null) : FlxTypedSignal<Int->Void>;

  // TODO: Enforce a max size with this.maxSize
  // TODO: Don't hard-code the block size in this class
  public function new(x:Int, y:Int, size:Int, sprites:FlxFramesCollection) {
    super(x, y - 16, 0);

    this.OnSuccessfulClick = new FlxTypedSignal<Array<Block>->Void>();
    this.OnBadClick = new FlxTypedSignal<Array<Block>->Void>();
    this.OnStartMoving = new FlxTypedSignal<Void->Void>();
    this.OnStopMoving = new FlxTypedSignal<Void->Void>();
    this.OnNoMoreMoves = new FlxTypedSignal<Void->Void>();
    this.OnBlocksGenerated = new FlxTypedSignal<Int->Void>();

    this._frames = sprites;
    this.canClick = true;
    this._blockGrid = new Array2<Block>(size, size);
    this.gravity = GravityDirection.Down;
    this.gridSize = size;
    this._blocksMoving = 0;
    this._blocksCreated = 0;
    this.immovable = true;

    this.OnStopMoving.add(this._blocksDoneMoving);
    this.OnNoMoreMoves.add(this._noMoreMoves);

    this._generateBlocks();
  }

  public override function update(elapsed:Float) {
    if (!this.canClick && _blocksMoving == 0) {
      // If all blocks have stopped moving...
      this.OnStopMoving.dispatch();
    }

    super.update(elapsed);
  }

  /**
   * Given a block, which cell is it in
   */
  private function _getGridIndex(block:Block) : FlxPoint {
    var x = Math.round(block.x / block.frameWidth) * block.frameWidth;
    var y = Math.round(block.y / block.frameHeight) * block.frameHeight;

    x -= Std.int(this.x);
    y -= Std.int(this.y);

    x = Math.round(x / block.frameWidth);
    y = Math.round(y / block.frameHeight);

    return new FlxPoint(x, y);
  }

  /**
   * Given absolute cell coordinates, convert it to absolute world coordinates.
   */
  private inline function cellToPoint(x:Int, y:Int) : FlxPoint {
    return new FlxPoint(this.x + x * 16, this.y + y * 16);
    // TODO: Stop hardcoding block size
  }

  private function _rotateGravity() {
    this.gravity = GravityDirection.counterClockwise(this.gravity);
  }

  private function _anyGroupsRemaining() : Bool {
    var blocks = new Array<Block>();
    forEachAlive(function(b:Block) { return blocks.push(b); });

    while (blocks.length > 0) {
      var group = _getBlockGroup(blocks.pop());
      if (group.length >= 3) return true;
      for (b in group) {
        var removed = blocks.remove(b);
      }
    }

    return false;
  }

  /**
   * Given a block, return its flood-filled group of the same color.
   * Resulting array is not in any particular order.
   */
  private function _getBlockGroup(clicked:Block) : Array<Block> {
    var blocks = new Array<Block>();
    if (clicked == null) return blocks;

    var queue = new ArrayedQueue<Block>();
    queue.enqueue(clicked);

    while (!queue.isEmpty()) {
      var current = queue.dequeue();

      if (current.blockColor == clicked.blockColor) {
        blocks.push(current);

        var indices = _getGridIndex(current);
        var x = Std.int(indices.x);
        var y = Std.int(indices.y);

        var west = _blockGrid.inRange(x - 1, y) ? _blockGrid.get(x - 1, y) : null;
        var east = _blockGrid.inRange(x + 1, y) ? _blockGrid.get(x + 1, y) : null;
        var north = _blockGrid.inRange(x, y - 1) ? _blockGrid.get(x, y - 1) : null;
        var south = _blockGrid.inRange(x, y + 1) ? _blockGrid.get(x, y + 1) : null;

        if (west != null && !blocks.has(west)) queue.enqueue(west);
        if (east != null && !blocks.has(east)) queue.enqueue(east);
        if (north != null && !blocks.has(north)) queue.enqueue(north);
        if (south != null && !blocks.has(south)) queue.enqueue(south);
      }

    }

    return blocks;
  }

  private function _startMovingBlocks() {
    var newGrid = new Array2<Block>(this.gridSize, this.gridSize);

    // rotate gravity in old grid
    // for each localColumn in old grid:
    //   set freeCell = localBottom cell
    //   for each block in localColumn from bottom-up:
    //     if block is not null:
    //       set gridNew[row][col] = block
    //       freeCell -= 1
    //       set block's tween target to new cell

    // Last resort: Code each direction individually
    // Then merge them together later when I notice a pattern

    var tweenIt = function(block:Block, targetPoint:FlxPoint) {
      FlxTween.linearMotion(
        block,
        block.x,
        block.y,
        targetPoint.x,
        targetPoint.y,
        0.5,
        true,
        {
          ease: FlxEase.quadIn,
          type: FlxTween.ONESHOT,
          onComplete: function(_) {
            this._blocksMoving--;
            D.assert(this._blocksMoving >= 0);
            D.assert(this._blocksMoving <= this.group.length);
          }
        }
      );
      this._blocksMoving++;
    };

    switch (this.gravity) {
      case GravityDirection.Down: {
        for (c in 0...this.gridSize) {
          var bottom = this.gridSize - 1;

          for (r in new ReverseIterator(this.gridSize - 1, 0)) {
            var block = this._blockGrid.get(c, r);

            if (block != null) {
              newGrid.set(c, bottom, block);
              tweenIt(block, this.cellToPoint(c, bottom));
              bottom--;
            }
          }
        }
      }
      case GravityDirection.Right: {
        for (r in new ReverseIterator(this.gridSize - 1, 0)) {
          var right = this.gridSize - 1;

          for (c in new ReverseIterator(this.gridSize - 1, 0)) {
            var block = this._blockGrid.get(c, r);

            if (block != null) {
              newGrid.set(right, r, block);
              tweenIt(block, this.cellToPoint(right, r));
              right--;
            }
          }
        }
      }
      case GravityDirection.Up: {
        for (c in new ReverseIterator(this.gridSize - 1, 0)) {
          var top = 0;

          for (r in 0...gridSize) {
            var block = this._blockGrid.get(c, r);

            if (block != null) {
              newGrid.set(c, top, block);
              tweenIt(block, this.cellToPoint(c, top));
              top++;
            }
          }
        }
      }
      case GravityDirection.Left: {
        for (r in 0...gridSize) {
          var left = 0;

          for (c in 0...gridSize) {
            var block = this._blockGrid.get(c, r);

            if (block != null) {
              newGrid.set(left, r, block);
              tweenIt(block, this.cellToPoint(left, r));
              left++;
            }
          }
        }
      }
    }

    this._blockGrid = newGrid;
    this.OnStartMoving.dispatch();
  }

  private function _blocksDoneMoving() {
      trace("All blocks have stopped moving");

      if (!this._anyGroupsRemaining()) {
        this.OnNoMoreMoves.dispatch();
      }

      this.canClick = true;
  }

  private function _noMoreMoves() {
    // If the player can't make a move...
    var blockCount = 0;
    this.forEachExists(function(block:Block) {
      blockCount++;
    });

    this.OnBlocksGenerated.dispatch(this._generateBlocks());
  }

  /**
   * Fills all null spaces in the grid with blocks and puts them on-screen.
   * Returns the number of blocks that were created
   */
  private function _generateBlocks() : Int {
    // TODO: Assign a sequential ID for each block created
    var created = 0;

    _blockGrid.forEach(function(block:Block, gridX:Int, gridY:Int) {
      if (block == null) {
        // If there's no block at this grid cell..

        created++;
        var b = this.recycle(Block, function() {
          var blockColor = BlockColor.All[Std.random(BlockColor.All.length - 2)];
          var bb = new Block(gridX * 16, gridY * 16, this._frames, blockColor);
          bb.ID = this._blocksCreated++;

          trace('New block $bb created');
          return bb;
        });

        b.blockColor = BlockColor.All[Std.random(BlockColor.All.length - 2)];
        b.setPosition(gridX * 16, gridY * 16);

        FlxMouseEventManager.add(b, function(block:Block) {
          if (this.canClick) {
            // If no blocks are moving...
            var blocks = this._getBlockGroup(block);

            if (blocks.length >= 3) {
              // If the selected block group has at least 3 blocks...
              blocks.iter(function(toKill:Block) {
                FlxMouseEventManager.remove(toKill);
                _blockGrid.remove(toKill);
                toKill.kill();
              });

              this.canClick = false;
              this.OnSuccessfulClick.dispatch(blocks);
              this._startMovingBlocks();
              this._rotateGravity();
            }
            else {

              this.OnBadClick.dispatch(blocks);
            }
          }
        }, false, true, false);

        this.add(b);
        return b;
      }
      else {
        return block;
      }
    });

    return created;
  }

  public override function destroy() {
    super.destroy();

    FlxMouseEventManager.remove(this);
    this._blockGrid.clear();
    this._blockGrid = null;
  }
}
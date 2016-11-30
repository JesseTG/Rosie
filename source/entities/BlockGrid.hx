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
import de.polygonal.ds.Array2.Array2Cell;
import de.polygonal.ds.ArrayedQueue;
import de.polygonal.core.util.Assert;

import util.ReverseIterator;

using Lambda;

class BlockGrid extends FlxTypedSpriteGroup<Block> {
  private var _blockGrid : Array2<Block>;
  private var _blocksMoving : Int;
  private var _blocksCreated : Int;
  private var _frames: FlxFramesCollection;

  public var gridSize(default, null) : Int;
  public var gravity(default, null) : GravityDirection;
  public var readyForInput(default, null) : Bool;
  public var numColors(default, set) : Int;

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
   * Called just before the blocks are generated.
   */
  public var OnBeforeBlocksGenerated(default, null) : FlxTypedSignal<Void->Void>;

  /**
   * Called when blocks are generated, except for the first time (i.e. when the
   * game starts).
   */
  public var OnBlocksGenerated(default, null) : FlxTypedSignal<Int->Void>;

  // TODO: Enforce a max size with this.maxSize
  // TODO: Don't hard-code the block size in this class
  public function new(x:Int, y:Int, size:Int, sprites:FlxFramesCollection) {
    super(x, y, 0);

    this.OnSuccessfulClick = new FlxTypedSignal<Array<Block>->Void>();
    this.OnBadClick = new FlxTypedSignal<Array<Block>->Void>();
    this.OnStartMoving = new FlxTypedSignal<Void->Void>();
    this.OnStopMoving = new FlxTypedSignal<Void->Void>();
    this.OnNoMoreMoves = new FlxTypedSignal<Void->Void>();
    this.OnBeforeBlocksGenerated = new FlxTypedSignal<Void->Void>();
    this.OnBlocksGenerated = new FlxTypedSignal<Int->Void>();

#if debug
    this.OnSuccessfulClick.add(function(_) trace("OnSuccessfulClick"));
    this.OnBadClick.add(function(_) trace("OnBadClick"));
    this.OnStartMoving.add(function() trace("OnStartMoving"));
    this.OnStopMoving.add(function() trace("OnStopMoving"));
    this.OnNoMoreMoves.add(function() trace("OnNoMoreMoves"));
    this.OnBeforeBlocksGenerated.add(function() trace("OnBeforeBlocksGenerated"));
    this.OnBlocksGenerated.add(function(blocks) trace('OnBlocksGenerated(${blocks})'));
#end

    this._frames = sprites;
    // TODO: Why doesn't this.frames (note the lack of _) work?  Is it overridden?

    this.readyForInput = true;
    // TODO: Come up with a better name and clarify semantics

    this._blockGrid = new Array2<Block>(size, size);
    this.gravity = GravityDirection.Down;
    this.gridSize = size;
    this._blocksMoving = 0;
    this._blocksCreated = 0;
    this.immovable = true;
    this.numColors = 4;
    // TODO: Look at how Array2 does cleanup
    // TODO: See what Flx properties I can set to take advantage of BlockGrid's nature

    this.OnStopMoving.add(this._blocksDoneMoving);
    this.OnNoMoreMoves.add(this.OnBeforeBlocksGenerated.dispatch);
    this.OnNoMoreMoves.add(this._noMoreMoves);
    this.OnBadClick.add(this._shakeBlocks);
    this.OnSuccessfulClick.add(function(blocks) {
      this.readyForInput = false;
      blocks.iter(function(block:Block) {
        FlxMouseEventManager.setObjectMouseEnabled(block, false);
        _blockGrid.remove(block);
        block.kill();
        // TODO: Avoid a linear lookup whenever removing a block
      });

      this._startMovingBlocks();
      this._rotateGravity();
    });


    this._generateBlocks();
    // TODO: This doesn't feel right; mull it over
  }

  public override function update(elapsed:Float) {
    if (!this.readyForInput && _blocksMoving == 0) {
      // If all blocks have stopped moving...
      this.OnStopMoving.dispatch();
    }

    super.update(elapsed);
  }

  private function set_numColors(numColors:Int) {
    this.numColors = switch (numColors) {
      case n if (n > BlockColor.All.length): BlockColor.All.length;
      case n if (n <= 0): 1;
      case n: n;
    };

    return this.numColors;
  }

  /**
   * Given a block, which cell is it in
   */
  private function _getGridIndex(block:Block) : Array2Cell {
    var x = Math.round(block.x / block.frameWidth) * block.frameWidth;
    var y = Math.round(block.y / block.frameHeight) * block.frameHeight;

    x -= Std.int(this.x);
    y -= Std.int(this.y);

    x = Math.round(x / block.frameWidth);
    y = Math.round(y / block.frameHeight);

    return new Array2Cell(x, y);
  }

  /**
   * Given absolute cell coordinates, convert it to absolute world coordinates.
   */
  private inline function cellToPoint(x:Int, y:Int) : FlxPoint {
    return new FlxPoint(this.x + x * 16, this.y + y * 16);
    // TODO: Stop hardcoding block size
  }

  private inline function _rotateGravity() {
    // TODO: Do I even need this function?
    this.gravity = GravityDirection.counterClockwise(this.gravity);
  }

  private function _anyGroupsRemaining() : Bool {
    var blocks = new Array<Block>();
    forEachAlive(function(b:Block) { return blocks.push(b); });
    // TODO: Can I pre-allocate memory?

    // TODO: Document this loop
    while (blocks.length > 0) {
      var group = getBlockGroup(blocks.pop());
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
  public function getBlockGroup(clicked:Block) : Array<Block> {
    var blocks = new Array<Block>();
    if (clicked == null || !clicked.alive || !clicked.exists) return blocks;

    var queue = new ArrayedQueue<Block>();
    queue.enqueue(clicked);

    // TODO: Better document this loop
    while (!queue.isEmpty()) {
      var current = queue.dequeue();

      if (current.blockColor == clicked.blockColor) {
        blocks.push(current);

        var indices = _getGridIndex(current);
        var x = indices.x;
        var y = indices.y;

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

  public function handleBlockGroup(blocks:Array<Block>) {
    if (blocks != null && blocks.length >= 3) {
      // If the selected block group has at least 3 blocks...

      this.OnSuccessfulClick.dispatch(blocks);
    }
    else {
      this.OnBadClick.dispatch(blocks);
    }
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
      if (!block.getPosition().equals(targetPoint)) {
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
      }
    };

    // TODO: Ask on #haxe if this part can be made better
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
    // TODO: Think about doing this in-place so I don't need to allocate memory
    this.OnStartMoving.dispatch();
  }

  private function _blocksDoneMoving() {
      if (!this._anyGroupsRemaining()) {
        this.OnNoMoreMoves.dispatch();
      }

      this.readyForInput = true;
  }

  private function _noMoreMoves() {
    // If the player can't make a move...
    var blockCount = 0;
    this.forEachExists(function(block:Block) {
      blockCount++;
    });
    // TODO: Keep a block count instead of doing linear iteration like this

    this.OnBlocksGenerated.dispatch(this._generateBlocks());
  }

  /**
   * Fills all null spaces in the grid with blocks and puts them on-screen.
   * Returns the number of blocks that were created
   */
  private function _generateBlocks() : Int {
    var created = 0;

    // TODO: Simplify this function
    _blockGrid.forEach(function(block:Block, gridX:Int, gridY:Int) {
      if (block == null) {
        // If there's no block at this grid cell..

        created++;
        var b = this.recycle(Block, function() {
          var blockColor = BlockColor.All[Std.random(this.numColors)];
          var bb = new Block(gridX * 16, gridY * 16, this._frames, blockColor);
          bb.ID = this._blocksCreated++;
          FlxMouseEventManager.add(bb, function(bbb:Block) {
            if (this.readyForInput) {
              // If we're ready for the player to make a move...

              this.handleBlockGroup(this.getBlockGroup(bbb));
            }
          }, false, true, false);

          trace('New block $bb created');
          return bb;
        });

        b.blockColor = BlockColor.All[Std.random(this.numColors)];
        // TODO: Don't do Std.random twice, just do it out here

        b.setPosition(gridX * 16, gridY * 16);

        FlxMouseEventManager.setObjectMouseEnabled(b, true);

        this.add(b);
        // TODO: Ensure I'm not adding the same block twice

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
    // TODO: Revisit the semantics of this function and see if I can move parts
    // of it to another file

    this._blockGrid = null;
  }

  private function _shakeBlocks(blocks:Array<Block>) {
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
          type: FlxTween.ONESHOT,
          onComplete: function(_) {
            this._blocksMoving--;
            this.readyForInput = true;
          },
          onStart: function(_) {
            this._blocksMoving++;
            this.readyForInput = false;
          }
        }
      );
    }
  }
}
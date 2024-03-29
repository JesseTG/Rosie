package entities;

using haxe.EnumTools.EnumValueTools;

import flixel.graphics.frames.FlxFramesCollection;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.input.mouse.FlxMouseEventManager;
import flixel.math.FlxPoint;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxSignal.FlxTypedSignal;

import de.polygonal.ds.Array2.Array2Cell;
import de.polygonal.ds.Array2;
import de.polygonal.ds.ArrayedQueue;
import de.polygonal.ds.ArrayList;
import de.polygonal.ds.List;
import de.polygonal.ds.tools.Assert.assert;

import entities.Block.BlockAnimation;
import entities.GravityDirection.GravityDirectionTools;
import util.ReverseIterator;

using util.ArrayTools;
using entities.GravityDirection.GravityDirectionTools;
using Lambda;

class BlockGrid extends FlxTypedSpriteGroup<Block> {
  private var _blockGrid : Array2<Block>;
  private var _blockArray : ArrayList<Block>;
  private var _blockArray2 : ArrayList<Block>;
  private var _blockQueue : ArrayedQueue<Block>;
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
  public var OnSuccessfulClick(default, null) : FlxTypedSignal<List<Block>->Void>;

  /**
   * Called when the player clicks on a block but it's not enough to make a group.
   */
  public var OnBadClick(default, null) : FlxTypedSignal<List<Block>->Void>;

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
  public var OnBlocksGenerated(default, null) : FlxTypedSignal<List<Block>->Void>;

  // TODO: Enforce a max size with this.maxSize
  // TODO: Don't hard-code the block size in this class
  public function new(x:Int, y:Int, size:Int, sprites:FlxFramesCollection) {
    super(x, y, 0);

    this.OnSuccessfulClick = new FlxTypedSignal();
    this.OnBadClick = new FlxTypedSignal();
    this.OnStartMoving = new FlxTypedSignal();
    this.OnStopMoving = new FlxTypedSignal();
    this.OnNoMoreMoves = new FlxTypedSignal();
    this.OnBeforeBlocksGenerated = new FlxTypedSignal();
    this.OnBlocksGenerated = new FlxTypedSignal();

#if debug
    this.OnSuccessfulClick.add(function(blocks) trace('OnSuccessfulClick(${blocks})'));
    this.OnBadClick.add(function(blocks) trace('OnBadClick(${blocks})'));
    this.OnStartMoving.add(function() trace("OnStartMoving"));
    this.OnStopMoving.add(function() trace("OnStopMoving"));
    this.OnNoMoreMoves.add(function() trace("OnNoMoreMoves"));
    this.OnBeforeBlocksGenerated.add(function() trace("OnBeforeBlocksGenerated"));
    this.OnBlocksGenerated.add(function(blocks) trace('OnBlocksGenerated(${blocks})'));
#end

    this._frames = sprites;
    // the "frames" field is not supported in FlxTypedSpriteGroup, so we use our own

    this.readyForInput = false;
    // TODO: Come up with a better name and clarify semantics

    this._blockGrid = new Array2(size, size);
    this._blockGrid.reuseIterator = true;

    this._blockArray = new ArrayList(size * size, null, true);
    this._blockArray.reuseIterator = true;

    this._blockArray2 = new ArrayList(size * size, null, true);
    this._blockArray.reuseIterator = true;

    this._blockQueue = new ArrayedQueue(size * size, null, true);
    this._blockQueue.reuseIterator = true;

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
    this.OnSuccessfulClick.add(this._handleSuccessfulClick);


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

  private function _handleSuccessfulClick(blocks:List<Block>) {
    this.readyForInput = false;
    for (block in blocks) {
      FlxMouseEventManager.setObjectMouseEnabled(block, false);
      block.alive = false;
      // alive == ready to be used.  The vanish effect is like the corpse

      _blockGrid.remove(block);
      // The block is still on-screen but not in our grid data structure (so
      // it won't be moved by the tweens in startMovingBlocks)
      // TODO: Avoid a linear lookup whenever removing a block

      block.animation.play(cast BlockAnimation.Vanish);
    }

    this._startMovingBlocks();
    this._rotateGravity();
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
  private inline function _getGridIndex(block:Block, cell:Array2Cell) : Array2Cell {
    var x = Math.round(block.x / block.frameWidth) * block.frameWidth;
    var y = Math.round(block.y / block.frameHeight) * block.frameHeight;

    x -= Std.int(this.x);
    y -= Std.int(this.y);

    x = Math.round(x / block.frameWidth);
    y = Math.round(y / block.frameHeight);

    cell.x = x;
    cell.y = y;
    return cell;
  }

  /**
   * Given absolute cell coordinates, convert it to absolute world coordinates.
   */
  private inline function cellToPoint(x:Int, y:Int) : FlxPoint {
    return FlxPoint.weak(this.x + x * 16, this.y + y * 16);
    // TODO: Stop hardcoding block size
  }

  private inline function _rotateGravity() {
    // TODO: Do I even need this function?
    this.gravity = this.gravity.counterClockwise();
  }

  private function _anyGroupsRemaining() : Bool {
    _blockArray2.clear();

    for (block in this.members) {
      if (block != null && block.alive) {
        _blockArray2.pushBack(block);
      }
    }
    // Didn't use forEachAlive because anonymous functions make the GC cry

    // TODO: Document this loop
    while (_blockArray2.size > 0) {
      var group = getBlockGroup(_blockArray2.popBack());
      if (group.size >= 3) return true;
      for (b in group) {
        _blockArray2.remove(b);
      }
    }

    return false;
  }

  /**
   * Given a block, return its flood-filled group of the same color.
   * Resulting array is not in any particular order.
   */
  public function getBlockGroup(clicked:Block) {
    this._blockArray.clear();
    if (clicked == null || !clicked.alive || !clicked.exists) return _blockArray;

    var cell = new Array2Cell(); // Appease the garbage collector
    _blockQueue.clear();
    _blockQueue.enqueue(clicked);

    while (!_blockQueue.isEmpty()) {
      // Until we we've run out of blocks to search...

      var current = _blockQueue.dequeue();
      // The block we're expanding out from right now

      if (current.blockColor == clicked.blockColor) {
        // If the block we're expanding out from is the color we want...
        if (!_blockArray.contains(current)) {
          // TODO: See if there's a constant-time way to answer this
          _blockArray.pushBack(current);
          // TODO: Will unsafePushBack be adequate?
        }

        var indices = _getGridIndex(current, cell);
        var x = indices.x;
        var y = indices.y;

        var west = _blockGrid.inRange(x - 1, y) ? _blockGrid.get(x - 1, y) : null;
        var east = _blockGrid.inRange(x + 1, y) ? _blockGrid.get(x + 1, y) : null;
        var north = _blockGrid.inRange(x, y - 1) ? _blockGrid.get(x, y - 1) : null;
        var south = _blockGrid.inRange(x, y + 1) ? _blockGrid.get(x, y + 1) : null;

        if (west != null && !_blockArray.contains(west)) _blockQueue.enqueue(west);
        if (east != null && !_blockArray.contains(east)) _blockQueue.enqueue(east);
        if (north != null && !_blockArray.contains(north)) _blockQueue.enqueue(north);
        if (south != null && !_blockArray.contains(south)) _blockQueue.enqueue(south);
      }

    }

    return _blockArray;
  }

  public function handleBlockGroup(blocks:List<Block>) {
    if (blocks != null) {
      // If we actually got a blocks array...

      for (i in 0...blocks.size) {
        // For each block in the group...
        this.members.swap(this.members.length - i - 1, this.members.indexOf(blocks.get(i)));
        // ...Swap it so it's one of the last members so it'll render above the others
      }

      if (blocks.size >= 3) {
        // If the selected block group has at least 3 blocks...

        this.OnSuccessfulClick.dispatch(blocks);
      }
      else {
        this.OnBadClick.dispatch(blocks);
      }
    }
  }

  private inline function _stopMovingBlock(_) {
    this._blocksMoving--;
    assert(this._blocksMoving >= 0);
    assert(this._blocksMoving <= this.group.length);
  }

  private inline function tweenIt(block:Block, targetPoint:FlxPoint) {
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
          onComplete: _stopMovingBlock
        }
      );
      this._blocksMoving++;
    }
  }

  private function _startMovingBlocks() {
    var newGrid = new Array2<Block>(this.gridSize, this.gridSize);
    newGrid.reuseIterator = true;

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
    for (block in this.members) {
      if (block != null && block.exists) {
        blockCount++;
      }
    }
    // Didn't use forEachExists because anonymous function overhead in JS
    // TODO: Keep a block count instead of doing linear iteration like this

    this.OnBlocksGenerated.dispatch(this._generateBlocks());
  }

  private function _handleClickedBlock(block:Block) {
    if (this.readyForInput) {
      // If we're ready for the player to make a move...

      this.handleBlockGroup(this.getBlockGroup(block));
    }
  }

  private function _createBlock() {
    var block = new Block(0, 0, this._frames, BlockColor.Red);
    block.ID = this._blocksCreated++;

    FlxMouseEventManager.add(block, _handleClickedBlock, false, true, false);
    trace('New Block $block created');

    return block;
  }

  /**
   * Fills all null spaces in the grid with blocks and puts them on-screen.
   * Returns the number of blocks that were created
   */
  private function _generateBlocks() {
    this._blockArray.clear();
    this.readyForInput = false;

    _blockGrid.forEach(function(blockInGrid:Block, gridX:Int, gridY:Int) {
      // This anonymous function is okay; on JavaScript it's inlined

      if (blockInGrid == null) {
        // If there's no block at this grid cell..

        var block = this.recycle(Block, _createBlock);

        _blockArray.pushBack(block);
        block.blockColor = BlockColor.All[Std.random(this.numColors)];
        block.setPosition(gridX * block.frameWidth, gridY * block.frameHeight);

        this.add(block);
        // TODO: Ensure I'm not adding the same block twice
        // TODO: Is this a linear lookup for space?  Can I just make it constant
        // by adding all blocks at once?

        return block;
      }
      else {
        return blockInGrid;
      }
    });

    return _blockArray;
  }

  public override function destroy() {
    super.destroy();

    // TODO: Revisit the semantics of this function and see if I can move parts
    // of it to another file

    this.OnBadClick.removeAll();
    this.OnBlocksGenerated.removeAll();
    this.OnStartMoving.removeAll();
    this.OnStopMoving.removeAll();
    this.OnSuccessfulClick.removeAll();
    this.OnBeforeBlocksGenerated.removeAll();
    this.OnNoMoreMoves.removeAll();

    this._blockArray2 = null;
    this._blockArray = null;
    this._blockGrid = null;
    this._frames = null;
    this.OnBadClick = null;
    this.OnBlocksGenerated = null;
    this.OnStartMoving = null;
    this.OnStopMoving = null;
    this.OnSuccessfulClick = null;
    this.OnBeforeBlocksGenerated = null;
    this.OnNoMoreMoves = null;
  }

  private function _shakeBlocks_onComplete(_) {
    this._blocksMoving--;
    this.readyForInput = true;
  }

  private function _shakeBlocks_onStart(_) {
    this._blocksMoving++;
    this.readyForInput = false;
  }

  private function _shakeBlocks(blocks:List<Block>) {
    var tweenOptions = {
      type: FlxTween.ONESHOT,
      onComplete: _shakeBlocks_onComplete,
      onStart: _shakeBlocks_onStart,
    };

    for (block in blocks) {
      var point = block.getPosition(); // uses FlxPoint.get() internally
      FlxTween.linearPath(
        block,
        [
          point,
          FlxPoint.weak(block.x + block.width / 4, block.y),
          point,
          FlxPoint.weak(block.x - block.width / 4, block.y),
          point,
        ],
        0.25,
        true,
        tweenOptions
      );
    }
  }
}
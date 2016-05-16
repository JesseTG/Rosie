package entities;

import haxe.EnumTools;

import flixel.graphics.frames.FlxFramesCollection;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.input.mouse.FlxMouseEventManager;
import de.polygonal.ds.Array2;

class BlockGrid extends FlxTypedSpriteGroup<Block> {
  // 
  private var _blockGrid : Array2<Block>;

  public var gridSize(default, null) : Int;
  public var gravity(default, null) : GravityDirection;

  // TODO: Don't hard-code the block size in this class
  public function new(x:Int, y:Int, size:Int, sprites:FlxFramesCollection) {
    super(x, y - 16, size * size + Std.int(0.5 * size));

    FlxMouseEventManager.add(this, function(grid:BlockGrid) {
      trace(this);
    }, false, true, false);

    this._blockGrid = new Array2<Block>(size, size);
    this.gravity = GravityDirection.Down;
    this.gridSize = size;

    _blockGrid.forEach(function(block:Block, gridX:Int, gridY:Int) {
      var blockColor = BlockColor.All[Std.random(BlockColor.All.length - 2)];
      var b = this.recycle(Block, function() {
        return new Block(gridX * 16, gridY * 16, sprites, blockColor);
      });
      this.add(b);
      return b;
    });
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
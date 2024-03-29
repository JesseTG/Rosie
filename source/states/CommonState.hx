package states;

#if (!html5)
import flixel.addons.transition.FlxTransitionableState;
#end

import flixel.addons.display.FlxBackdrop;
import flixel.addons.editors.tiled.TiledObject;
import flixel.FlxG;
import flixel.FlxState;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.text.FlxBitmapText;
import flixel.text.FlxText.FlxTextAlign;
import flixel.tile.FlxTilemap;
import flixel.ui.FlxBitmapTextButton;
import flixel.util.FlxColor;

import de.polygonal.ds.tools.Assert.assert;

using Lambda;
using ObjectInit;

class CommonState extends #if html5 FlxState #else FlxTransitionableState #end  {

  private var tilemap : FlxTilemap;
  private var bgImage : FlxBackdrop;
  private var highScoreLabel : FlxBitmapText;

  override public function create():Void {
    super.create();

    assert(Assets.initialized);

    // TODO: Store the tiled map on the texture atlas and load from there, instead of a separate image
    // TODO: Handle the layers/tilesets not being named in the way I want them to be

    this.tilemap = cast new FlxTilemap().loadMapFromArray(
      Assets.MainGroundLayer.tileArray,
      Assets.MainGroundLayer.width,
      Assets.MainGroundLayer.height,
      'assets/${Assets.TileSet.imageSource}',
      Assets.TileSet.tileWidth,
      Assets.TileSet.tileHeight,
      1, // Tiled uses 0-indexing, but I think FlxTilemap uses 1-indexing
      1,
      27
    );
    this.tilemap.immovable = true;
    this.tilemap.moves = false;
    this.tilemap.useScaleHack = false;
    // Game looks like ass with this scale hack on

    this.bgImage = new FlxBackdrop('assets/${Assets.MainBackgroundLayer.imagePath}', 0, 0, false, false).init(
      useScaleHack = false,
      solid = false,
      immovable = true,
      moves = false
    );

    var highScore = 0;
    if (FlxG.save.data.highScore != null) {
      highScore = cast(FlxG.save.data.highScore, Int);
    }

    for (object in Assets.MainGuiLayer.objects) {
      switch (object.name) {
        case "High Score Display":
          this.highScoreLabel = new FlxBitmapText(Assets.TextFont).init(
            x = object.x,
            y = object.y,
            alignment = FlxTextAlign.LEFT,
            letterSpacing = Std.parseInt(object.properties.letterSpacing),
            text = 'TOP ${highScore}',
            moves = false,
            immovable = true,
            solid = false
          );
        default:
          // nop
      }
    }

    this.add(bgImage);
    this.add(tilemap);
    this.add(highScoreLabel);

    FlxG.watch.add(FlxPoint.pool, "length", "# Pooled FlxPoints");
    FlxG.watch.add(FlxRect.pool, "length", "# Pooled FlxRects");

  }

  override public function destroy() {
    super.destroy();

    FlxG.watch.remove(FlxPoint.pool, "length");
    FlxG.watch.remove(FlxRect.pool, "length");

    this.tilemap = null;
    this.bgImage = null;
    this.highScoreLabel = null;
  }

  // TODO: Make this public static, maybe in a utility class or something
  private function makeButton(object:TiledObject, stateFunction) {
    var source = Assets.SpriteSet.getImageSourceByGid(object.gid).source;
    var index = source.lastIndexOf('/');
    var frameName = source.substr(index + 1);

    var button = new FlxBitmapTextButton(0, 0, object.properties.text, stateFunction).init(
      x = object.x,
      y = object.y - object.height,
      frames = Assets.TextureAtlas,
      frame = Assets.TextureAtlas.getByName(frameName),
      solid = false,
      immovable = true
    );

    button.label.font = Assets.TextFont;
    button.label.letterSpacing = -3;
    button.label.alignment = FlxTextAlign.CENTER;
    button.label.color = FlxColor.WHITE;
    button.label.autoSize = false;
    button.label.fieldWidth = object.width;
    button.label.solid = false;
    button.label.immovable = true;

    var normalAnim = button.animation.getByName("normal");
    normalAnim.frames = [Assets.TextureAtlas.getIndexByName(frameName)];

    var pressedAnim = button.animation.getByName("pressed");
    pressedAnim.frames = PRESSED_ANIM_FRAMES;

    var highlightAnim = button.animation.getByName("highlight");
    highlightAnim.frames = HIGHLIGHT_ANIM_FRAMES;

    var point = FlxPoint.weak(0, button.label.height);
    button.labelAlphas = BUTTON_LABEL_ALPHAS;
    button.labelOffsets = [
      point,
      point,
      FlxPoint.weak(0, button.label.height + 2)
    ];
    button.updateHitbox();

    return button;
  }

  private var PRESSED_ANIM_FRAMES = [Assets.TextureAtlas.getIndexByName("button-01.png")];
  private var HIGHLIGHT_ANIM_FRAMES = [Assets.TextureAtlas.getIndexByName("button-02.png")];
  private static var BUTTON_LABEL_ALPHAS = [1.0, 1.0, 1.0];
}
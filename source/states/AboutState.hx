package states;

import de.polygonal.Printf;
import flixel.addons.editors.tiled.TiledImageLayer;
import flixel.addons.editors.tiled.TiledMap;
import flixel.addons.editors.tiled.TiledObject;
import flixel.addons.editors.tiled.TiledObjectLayer;
import flixel.addons.editors.tiled.TiledPropertySet;
import flixel.addons.editors.tiled.TiledTileLayer;
import flixel.addons.editors.tiled.TiledTileSet;
import flixel.text.FlxText.FlxTextAlign;
import flixel.text.FlxText.FlxTextBorderStyle;
import flixel.tile.FlxTilemap;
import flixel.group.FlxSpriteGroup;
import flixel.ui.FlxBitmapTextButton;
import flixel.text.FlxBitmapText;
import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.util.FlxColor;
import flixel.graphics.frames.FlxBitmapFont;
import flixel.addons.effects.chainable.FlxEffectSprite;
import flixel.addons.display.FlxStarField.FlxStarField2D;
import flixel.addons.display.FlxStarField.FlxStarField3D;
import flixel.addons.effects.chainable.FlxOutlineEffect;
import flixel.addons.effects.chainable.FlxOutlineEffect.FlxOutlineMode;

using ObjectInit;
using Lambda;

class AboutState extends FlxState {
  private static var BLOCK_FONT_SIZE = new FlxPoint(16, 32);
  private static var BLOCK_FONT_SPACING = new FlxPoint(2, 0);
  private static var TEXT_FONT_SIZE = new FlxPoint(10, 9);
  private static var TEXT_FONT_SPACING = new FlxPoint(0, 0);
  private static inline var NUM_STARS = 100;
  private static inline var IDLE_FPS = 6;

  private var _starfield : FlxStarField2D;
  private var rosie : FlxSprite;
  private var returnButton : FlxBitmapTextButton;
  private var sprites : FlxAtlasFrames;
  private var font : FlxBitmapFont;
  private var textFont : FlxBitmapFont;
  private var map : TiledMap;
  private var tilemap : FlxTilemap;

  public override function create() {
    super.create();

    this.map = new TiledMap(AssetPaths.credits__tmx);
    var spriteSet = map.getTileSet("Sprites");
    var tileSet = map.getTileSet("Overworld");
    this.sprites = FlxAtlasFrames.fromTexturePackerJson(AssetPaths.gfx__png, AssetPaths.gfx__json);
    this.font = FlxBitmapFont.fromMonospace(
      this.sprites.getByName("block-font.png"),
      FlxBitmapFont.DEFAULT_CHARS,
      BLOCK_FONT_SIZE,
      null,
      BLOCK_FONT_SPACING
    );


    this.textFont = FlxBitmapFont.fromMonospace(
      this.sprites.getByName("text-font.png"),
      '${FlxBitmapFont.DEFAULT_CHARS}⌚⇦',
      TEXT_FONT_SIZE,
      null,
      TEXT_FONT_SPACING
    );

    var ground : TiledTileLayer = cast map.getLayer("Ground");
    this.tilemap = cast new FlxTilemap().loadMapFromArray(
      ground.tileArray,
      ground.width,
      ground.height,
      'assets/${tileSet.imageSource}',
      tileSet.tileWidth,
      tileSet.tileHeight,
      3
    );
    this.tilemap.useScaleHack = false;

    var gui : TiledObjectLayer = cast map.getLayer("GUI");
    gui.objects.iter(function(object) {
      switch (object.name) {
        case "Rosie":
          var idleFrames = [for (i in 1...62) Printf.format("cat/idle/rosie-idle-%02d.png", [i])];
          var effect = new FlxOutlineEffect(FlxOutlineMode.PIXEL_BY_PIXEL, 0xffEEEEEE, 2);
          rosie = new FlxSprite(object.x, object.y - object.height).init(
            frames = sprites,
            frame = sprites.getByName(idleFrames[0]),
            pixelPerfectRender = true,
            flipX = object.flippedHorizontally
          );
          rosie.animation.addByNames(
            "idle",
            idleFrames,
            IDLE_FPS,
            true
          );
          rosie.animation.callback = function(_, _, _) {
            effect.dirty = true;
          }
          rosie.animation.play("idle");
          rosie.resetSizeFromFrame();
          rosie.updateHitbox();
        case "Return Button":
          var source = spriteSet.getImageSourceByGid(object.gid).source;
          var index = source.lastIndexOf('/');
          var frameName = source.substr(index + 1);

          returnButton = new FlxBitmapTextButton(object.properties.text, function() {
              if (FlxG.sound.music != null) {
                FlxG.sound.music.stop();
              }
              FlxG.switchState(new MenuState());
          }).init(
            x = object.x,
            y = object.y - object.height,
            frames = this.sprites,
            frame = this.sprites.getByName(frameName)
          );

          returnButton.label.font = this.textFont;
          returnButton.label.letterSpacing = -3;
          returnButton.label.alignment = FlxTextAlign.CENTER;
          returnButton.label.color = FlxColor.WHITE;
          returnButton.label.autoSize = false;
          returnButton.label.fieldWidth = object.width;

          var normalAnim = returnButton.animation.getByName("normal");
          normalAnim.frames = [sprites.getIndexByName(frameName)];

          var pressedAnim = returnButton.animation.getByName("pressed");
          pressedAnim.frames = [sprites.getIndexByName("button-01.png")];

          var highlightAnim = returnButton.animation.getByName("highlight");
          highlightAnim.frames = [sprites.getIndexByName("button-02.png")];

          var point = new FlxPoint(0, returnButton.label.height);
          returnButton.labelAlphas = [1.0, 1.0, 1.0];
          returnButton.labelOffsets = [
            point,
            point,
            FlxPoint.get(0, returnButton.label.height + 2)
          ];
          returnButton.updateHitbox();
      }
    });


    var credits = new FlxSpriteGroup();
    var creditsLayer : TiledObjectLayer = cast map.getLayer("Credits");
    for (object in creditsLayer.objects) {
      switch (object.type) {
        case "Title":
          var title = new FlxBitmapText(this.font).init(
            x = object.x,
            y = object.y,
            text = object.properties.text,
            alignment = FlxTextAlign.CENTER,
            pixelPerfectPosition = true,
            pixelPerfectRender = true,
            letterSpacing = Std.parseInt(object.properties.letterSpacing)
          );
          credits.add(title);
        case "Text":
          var text = new FlxBitmapText(this.textFont).init(
            x = object.x,
            y = object.y,
            autoSize = false,
            width = object.width,
            fieldWidth = object.width,
            text = object.properties.text,
            alignment = FlxTextAlign.CENTER,
            pixelPerfectPosition = true,
            pixelPerfectRender = true,
            letterSpacing = Std.parseInt(object.properties.letterSpacing)
          );

          credits.add(text);
        case "Image":
      }
    }

    credits.velocity.y = -Std.parseFloat(creditsLayer.properties.scrollSpeed);
    this._starfield = new FlxStarField2D(0, 0, FlxG.width, FlxG.height, Std.parseInt(map.properties.numStars));
    this._starfield.bgColor = map.backgroundColor;

    FlxG.console.registerObject("starfield", this._starfield);

    this.add(_starfield);
    this.add(tilemap);
    this.add(rosie);
    this.add(returnButton);
    this.add(credits);

    FlxG.sound.playMusic(AssetPaths.game_over_loop__ogg);
  }

  public override function update(elapsed:Float) {
    super.update(elapsed);

  }

  public override function destroy() {
    super.destroy();

    this._starfield = null;
  }
}
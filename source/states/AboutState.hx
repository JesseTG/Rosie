package states;

#if (!html5)
import flixel.addons.transition.FlxTransitionableState;
#end

import flixel.addons.display.FlxStarField.FlxStarField2D;
import flixel.addons.editors.tiled.TiledMap;
import flixel.addons.editors.tiled.TiledObjectLayer;
import flixel.addons.editors.tiled.TiledTileLayer;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxSpriteGroup;
import flixel.input.mouse.FlxMouseEventManager;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.text.FlxBitmapText;
import flixel.text.FlxText.FlxTextAlign;
import flixel.tile.FlxTilemap;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBitmapTextButton;
import flixel.util.FlxColor;

import entities.Rosie;
import entities.Rosie.AnimationState;

using ObjectInit;
using Lambda;

class AboutState extends #if html5 FlxState #else FlxTransitionableState #end {
  private static inline var NUM_STARS = 100;

  private var _starfield : FlxStarField2D;
  private var rosie : FlxSprite;
  private var returnButton : FlxBitmapTextButton;
  private var map : TiledMap;
  private var tilemap : FlxTilemap;

  public override function create() {
    super.create();

    this.map = new TiledMap(AssetPaths.credits__tmx);
    var spriteSet = map.getTileSet("Sprites");
    var tileSet = map.getTileSet("Overworld");

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
    this.tilemap.moves = false;
    this.tilemap.immovable = true;
    this.tilemap.solid = false;

    var gui : TiledObjectLayer = cast map.getLayer("GUI");
    for (object in gui.objects) {
      switch (object.name) {
        case "Rosie":
          rosie = new FlxSprite(object.x, object.y - object.height).init(
            frames = Assets.TextureAtlas,
            frame = Assets.TextureAtlas.getByName(Rosie.IDLE_FRAMES[0]),
            pixelPerfectRender = true,
            pixelPerfectPosition = true,
            moves = false,
            immovable = true,
            solid = false,
            flipX = object.flippedHorizontally
          );
          rosie.animation.addByNames(
            cast AnimationState.Idle,
            Rosie.IDLE_FRAMES,
            Rosie.IDLE_FPS,
            true
          );
          rosie.animation.play(cast AnimationState.Idle);
          rosie.resetSizeFromFrame();
          rosie.updateHitbox();
        case "Return Button":
          var source = spriteSet.getImageSourceByGid(object.gid).source;
          var index = source.lastIndexOf('/');
          var frameName = source.substr(index + 1);

          returnButton = new FlxBitmapTextButton(0, 0, object.properties.text, function() {
              if (FlxG.sound.music != null) {
                FlxG.sound.music.stop();
              }
              FlxG.switchState(new MenuState());
          }).init(
            x = object.x,
            y = object.y - object.height,
            frames = Assets.TextureAtlas,
            frame = Assets.TextureAtlas.getByName(frameName),
            immovable = true,
            solid = false
          );

          returnButton.label.font = Assets.TextFont;
          returnButton.label.letterSpacing = -3;
          returnButton.label.alignment = FlxTextAlign.CENTER;
          returnButton.label.color = FlxColor.WHITE;
          returnButton.label.autoSize = false;
          returnButton.label.fieldWidth = object.width;

          var normalAnim = returnButton.animation.getByName("normal");
          normalAnim.frames = [Assets.TextureAtlas.getIndexByName(frameName)];

          var pressedAnim = returnButton.animation.getByName("pressed");
          pressedAnim.frames = [Assets.TextureAtlas.getIndexByName("button-01.png")];

          var highlightAnim = returnButton.animation.getByName("highlight");
          highlightAnim.frames = [Assets.TextureAtlas.getIndexByName("button-02.png")];

          var point = FlxPoint.weak(0, returnButton.label.height);
          returnButton.labelAlphas = [1.0, 1.0, 1.0];
          returnButton.labelOffsets = [
            point,
            point,
            FlxPoint.weak(0, returnButton.label.height + 2)
          ];
          returnButton.updateHitbox();
      }
    }


    var credits = new FlxSpriteGroup();
    var creditsLayer : TiledObjectLayer = cast map.getLayer("Credits");
    for (object in creditsLayer.objects) {
      switch (object.type) {
        case "Title":
          var title = new FlxBitmapText(Assets.TitleFont).init(
            x = object.x,
            y = object.y,
            autoSize = false,
            width = object.width,
            fieldWidth = object.width,
            text = object.properties.text,
            alignment = FlxTextAlign.CENTER,
            pixelPerfectPosition = false,
            pixelPerfectRender = false,
            letterSpacing = Std.parseInt(object.properties.letterSpacing),
            solid = false,
            immovable = true
          );
          credits.add(title);
        case "Text":
          var textColor = (object.properties.textColor == null) ? FlxColor.WHITE : FlxColor.fromString(object.properties.textColor);
          var text = new FlxBitmapText(Assets.TextFont).init(
            x = object.x,
            y = object.y,
            autoSize = false,
            width = object.width,
            fieldWidth = object.width,
            text = object.properties.text,
            alignment = FlxTextAlign.CENTER,
            pixelPerfectPosition = false,
            pixelPerfectRender = false,
            letterSpacing = Std.parseInt(object.properties.letterSpacing),
            useTextColor = (object.properties.textColor != null),
            textColor = textColor,
            immovable = true,
            solid = false
          );

          if (object.properties.url != null) {
            text.useTextColor = true;
            // TODO: This doesn't cause a leak, does it?
            FlxMouseEventManager.add(
              text,
              function(t) {
                FlxG.openURL(object.properties.url);
              },
              null, // No OnMouseUp
              function(t) {
                t.textColor = FlxColor.BLUE;
              },
              function(t) {
                t.textColor = textColor;
              },
              true,
              true,
              false
            );
          }

          credits.add(text);
        case "Image":
          var image = new FlxSprite(object.x, object.y, 'assets/images/${object.properties.image}').init(
            pixelPerfectPosition = false,
            pixelPerfectRender = false,
            immovable = true,
            solid = false
          );

          credits.add(image);
      }
    }

    this._starfield = new FlxStarField2D(0, 0, FlxG.width, FlxG.height, Std.parseInt(map.properties.numStars)).init(
      bgColor = map.backgroundColor,
      immovable = true,
      solid = false,
      moves = false
    );

    FlxG.console.registerObject("starfield", this._starfield);
    FlxG.console.registerObject("credits", credits);

    FlxG.watch.add(FlxPoint.pool, "length", "# Pooled FlxPoints");
    FlxG.watch.add(FlxRect.pool, "length", "# Pooled FlxRects");

    this.add(_starfield);
    this.add(tilemap);
    this.add(rosie);
    this.add(returnButton);
    this.add(credits);

    FlxTween.linearMotion(
      credits,
      credits.x,
      credits.y,
      credits.x,
      credits.y - credits.height - FlxG.height,
      Std.parseFloat(creditsLayer.properties.scrollSpeed),
      creditsLayer.properties.useDuration == "true",
      {
        startDelay: Std.parseFloat(creditsLayer.properties.startDelay),
        type: FlxTween.LOOPING,
        loopDelay: Std.parseFloat(creditsLayer.properties.loopDelay),
      }

    );

    FlxG.sound.playMusic(AssetPaths.game_over_loop__ogg);
  }

  public override function update(elapsed:Float) {
    super.update(elapsed);

  }

  public override function destroy() {
    super.destroy();

    this._starfield = null;
    this.rosie = null;
    this.returnButton = null;
    this.tilemap = null;
    this.map = null;

    FlxG.watch.remove(FlxPoint.pool, "length");
    FlxG.watch.remove(FlxRect.pool, "length");
  }
}
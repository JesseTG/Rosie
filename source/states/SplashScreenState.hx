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
import flixel.math.FlxRect;
import flixel.group.FlxSpriteGroup;
import flixel.ui.FlxBitmapTextButton;
import flixel.text.FlxBitmapText;
import flixel.FlxG;
import flixel.util.FlxSignal;
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
import flixel.tweens.FlxEase;
import flixel.input.mouse.FlxMouseEventManager;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;

import entities.Rosie;
import entities.Rosie.AnimationState;

using ObjectInit;
using Lambda;

class SplashScreenState extends FlxState {

  private var logo : FlxSprite;
  private var rosie : FlxSprite;
  private var animationDone : Bool;
  private var timer : FlxTimer;
  private var OnAnimationDone : FlxSignal;

  public override function create() {
    super.create();

    this.OnAnimationDone = new FlxSignal();

#if debug
    this.OnAnimationDone.add(function() trace("OnAnimationDone"));
#end

    this.animationDone = false;
    this.bgColor = 0xff070707;

    var map = new TiledMap(AssetPaths.splash__tmx);
    var sprites = FlxAtlasFrames.fromTexturePackerJson(AssetPaths.gfx__png, AssetPaths.gfx__json);
    var objects : TiledObjectLayer = cast map.getLayer("Splash Screen");
    for (object in objects.objects) {
      switch (object.type) {
        case "Rosie":
          rosie = new FlxSprite(object.x, object.y - object.height).init(
            frames = sprites,
            frame = sprites.getByName(Rosie.IDLE_FRAMES[0]),
            solid = false,
            immovable = true
          );
          rosie.animation.addByNames(
            cast AnimationState.Idle,
            Rosie.IDLE_FRAMES,
            Rosie.IDLE_FPS,
            true
          );
          rosie.animation.addByNames(
            cast AnimationState.Run,
            Rosie.RUN_FRAMES,
            Rosie.RUN_FPS,
            true
          );

          rosie.animation.play(cast AnimationState.Run);
          rosie.resetSizeFromFrame();
          rosie.updateHitbox();

          FlxTween.linearMotion(
            rosie,
            rosie.x,
            rosie.y,
            Std.parseFloat(object.properties.endX),
            rosie.y,
            64,
            false,
            {
              type: FlxTween.PERSIST,
              onComplete: function(_) {
                rosie.animation.play(cast AnimationState.Idle);
                this.OnAnimationDone.dispatch();
              },
              onUpdate: function(_) {
                if (rosie.x >= logo.x) {
                  var rect = logo.clipRect;
                  rect.width = Math.min(rosie.x - logo.x, logo.width);
                  logo.clipRect = rect;
                }
              }
            }
          );
          this.add(rosie);
        case "Logo":
          this.logo = new FlxSprite(object.x, object.y, 'assets/images/${object.properties.image}').init(
            clipRect = FlxRect.weak(0, 0, 0, object.height),
            solid = false,
            immovable = true
          );
          this.add(logo);
      }
    }

    this.OnAnimationDone.addOnce(function() {
      this.animationDone = true;
      this.timer = new FlxTimer();
      timer.start(5, function(_) { FlxG.switchState(new MenuState()); });
    });

    FlxG.watch.add(FlxPoint.pool, "length", "# Pooled FlxPoints");
    FlxG.watch.add(FlxRect.pool, "length", "# Pooled FlxRects");
    FlxG.console.registerObject("rosie", this.rosie);
  }

  public override function update(elapsed:Float) {
    if (FlxG.mouse.justPressed) {
      if (this.animationDone) {
        this.timer.cancel();
        FlxG.switchState(new MenuState());
      }
      else {
        FlxTween.globalManager.clear();
        rosie.x = 256; // TODO: Don't hard-code
        rosie.animation.play(cast AnimationState.Idle);

        var rect = logo.clipRect;
        rect.width = logo.width;
        logo.clipRect = rect;

        this.OnAnimationDone.dispatch();
      }
    }

    super.update(elapsed);
  }

  public override function destroy() {
    super.destroy();
    FlxG.watch.remove(FlxPoint.pool, "length");
    FlxG.watch.remove(FlxRect.pool, "length");

    this.OnAnimationDone.removeAll();

    this.rosie = null;
    this.logo = null;
    this.timer = null;
    this.OnAnimationDone = null;
  }
}
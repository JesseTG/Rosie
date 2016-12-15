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

using ObjectInit;
using Lambda;

class SplashScreenState extends FlxState {
  private static inline var IDLE_FPS = 6;
  private static inline var RUN_FPS = 12;

  private var logo : FlxSprite;
  private var logoExpanding : Bool;

  public override function create() {
    super.create();

    this.bgColor = 0xff070707;

    this.logoExpanding = false;
    var map = new TiledMap(AssetPaths.splash__tmx);
    var sprites = FlxAtlasFrames.fromTexturePackerJson(AssetPaths.gfx__png, AssetPaths.gfx__json);
    var idleFrames = [for (i in 1...62) Printf.format("cat/idle/rosie-idle-%02d.png", [i])];
    var runFrames = [for (i in 1...7) Printf.format("cat/run/rosie-run-%02d.png", [i])];

    var objects : TiledObjectLayer = cast map.getLayer("Splash Screen");
    for (object in objects.objects) {
      switch (object.type) {
        case "Rosie":
          var rosie = new FlxSprite(object.x, object.y - object.height);
          rosie.frames = sprites;
          rosie.animation.addByNames(
            "idle",
            idleFrames,
            IDLE_FPS,
            true
          );
          rosie.animation.addByNames(
            "run",
            runFrames,
            RUN_FPS,
            true
          );

          rosie.animation.play("run");
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
                rosie.animation.play("idle");
                new FlxTimer().start(5, function(_) { FlxG.switchState(new MenuState()); });
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
            clipRect = new FlxRect(0, 0, 0, object.height)
          );
          this.add(logo);
      }
    }

  }

  public override function destroy() {
    super.destroy();
  }
}